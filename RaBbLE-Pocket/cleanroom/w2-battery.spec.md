# W2 spec: rabble_battery (the on-battery power measurement meter)

> Clean-room spec, wave W2. Author role: S (Sonnet 5.5 sub-agent, S258). Firewall: S258 parent (Opus 5.5), approved after rewriting buffer layout, accounting bookkeeping, locking primitives and dump-buffer mechanics as requirements, and removing a note about the original. Vectors `09c` (cut dump) are informational only. File to be replaced: `apache/rabble_battery.c/.h`. The new implementation goes under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else; the old pair is deleted in the same commit. Interface names are frozen: every existing caller compiles and behaves unchanged. Golden vectors: `w2-battery-vectors/` (README there explains the files). The vectors check the implementation; the rules below are the specification.

---

## 0. Read this first: what this module is, and is not

The brief for this wave described "charge curve and power-off behaviour". **This module has neither.** Reading the original and every caller shows that `rabble_battery` is a *bench meter for power work*: it watches the battery readings that someone else takes, and reports how a stretch of time on battery went (duration, percent and millivolt change, how much of that time the screen was off, how much of it the CPU was allowed to sleep, how much it really slept, how busy the cores were, which power locks kept the chip awake), plus a one-line JSON dump of the same that survives a warm reset. Where the rest of the battery story lives:

| Behaviour | Where it actually lives (not in this module) |
|---|---|
| Voltage to percent mapping, charging detection, "no battery" (-1), millivolt reading | `rabble_axp2101` (read-power function), reached through `rabble_board->read_power`. Also being rewritten in W2; separate spec. |
| "On battery" decision (no USB and a battery present, or the `>nap` bench override) | `rabble_state_on_battery()` in `accord/rabble_state.c` (already clean). |
| Low-battery, critical-battery and power-off rules | There are **no** low or critical thresholds anywhere in this module. Power-off happens elsewhere: the long-press power key and the idle power-off timer (a setting) in `apache/rabble_input.c`, via `rabble_board->power_off`. See the input spec. |
| Showing battery state on screen | `apache/rabble_settings_ui.c` battery page (redesign track). It only calls this module's read and drain functions. |

`rabble_battery` does **not** use `rabble_axp2101` directly (no include, no call). Its only link to the power chip is the `rabble_power_t` record (battery percent, millivolts, charging flag, USB flag) that the input task passes in. So the W2 axp2101 rewrite cannot break this module as long as `rabble_power_t` keeps its meaning: percent `-1` = no battery, millivolts `0` = not measurable. Of the four fields, only percent and millivolts are used; `charging` and `usb` are stored and never reported.

Because there is no curve or threshold logic, "kept exactly" here means: the measurement rules, the formulas, the JSON text, the log lines, the 30-minute save rule and the warm-reset survival below.

## 1. Purpose

Provide, to the rest of the gadget:

1. A **measurement** that begins when the board goes onto battery (or at boot on battery) and ends when USB power returns. Its numbers stay readable after it ends, until the next one begins.
2. A **live read** of that measurement for the settings screen (once a second) and a **drain estimate** (percent per hour and hours per full charge).
3. A **JSON line** with every number, including per-power-lock use, for bench work over the serial console.
4. A **record that survives a warm reset** (software restart, watchdog, crash, port-open reset on some boards; not power loss), reported at the next boot, so a run is not lost when the board resets as the cable is plugged back in.
5. The count and duration of automatic light sleeps, gathered through ESP-IDF's light-sleep exit callback.

It owns no task and no timer. All its work happens inside calls made by other tasks, plus one callback from the idle task.

## 2. Public interface (complete and exact)

Header `rabble_battery.h`, `#pragma once`. It must include `<stdbool.h>`, `<stddef.h>`, `<stdint.h>` and `"rabble_state.h"` (callers get `rabble_power_t` through it). `extern "C"` guards are allowed. Exported symbols: one type and eight functions, listed below; no macros, no globals.

### 2.1 The type

`rabble_battery_t` (a typedef of an anonymous struct), fields in this order with these types:

| Field | Type | Meaning |
|---|---|---|
| `started` | `bool` | false until the board has been on battery since boot or since the last reset of the meter |
| `running` | `bool` | on battery right now; false once USB came back |
| `secs` | `int64_t` | whole seconds on battery (see 4.3) |
| `pct_start`, `pct_now` | `int` | battery percent at the start and the latest reading; `-1` unknown |
| `mv_start`, `mv_now` | `int` | millivolts at the start and latest reading; `0` unknown |
| `screen_off_pm` | `int` | per mille (tenths of a percent) of the time on battery with the screen off |
| `resting_pm` | `int` | per mille of the time with the display stopped and the CPU allowed to sleep |
| `slept_pm` | `int` | per mille of the time actually in light sleep; `-1` unknown |
| `sleeps` | `uint32_t` | number of light sleeps during the measurement (each ended by a wake) |
| `busy_pm` | `int` | per mille of the time a core was running a task; `-1` unknown |
| `awake` | `char[48]` | text naming the power locks that kept the chip awake longest, e.g. `wifi 4.0%, bt 1.0%`; empty when unknown |

### 2.2 The functions

| Prototype | Summary |
|---|---|
| `void rabble_battery_init(void);` | Once, at boot, before the input task starts. Sets up the module, checks for a record left by the previous boot (4.8), registers for light-sleep exit notification. |
| `void rabble_battery_note_power(const rabble_power_t *p, bool on_battery);` | A new battery reading, plus the caller's judgment of whether the board is on battery. Starts, updates or stops the measurement (4.1). |
| `void rabble_battery_note_state(bool screen_off, bool resting);` | The current screen and CPU state. Cheap when nothing changed. |
| `void rabble_battery_reset(void);` | Start over (4.7). |
| `void rabble_battery_read(rabble_battery_t *out);` | Fill `out` with the current figures (4.3). |
| `bool rabble_battery_drain(const rabble_battery_t *b, int *rate10, int *full_h);` | Pure estimate from a previously read struct (5). |
| `int rabble_battery_json(char *buf, size_t cap);` | Write the JSON line (6) into `buf`, bounded by `cap` including the terminating NUL; returns the number of characters stored (not counting the NUL). The text is truncated to fit; the return value is then the truncated length, not the length it would have had. `cap` is at least 1 in every call (zero is not supported). |
| `const char *rabble_battery_saved_json(void);` | The JSON saved by the previous boot, or NULL (4.8). The pointer stays valid until `rabble_battery_reset` is called. |

That is eight functions and one type, 0 macros, 0 globals.

### 2.3 Who uses what (grep over `firmware/components` and `firmware/main`)

| Symbol | Caller | Task / when |
|---|---|---|
| `init` | `accord/rabble_app.c` (startup, after `rabble_state_init`, before the UI and input are started) | main task, once |
| `note_power` | `apache/rabble_input.c`, input task loop | input task (priority 6). Every 2 s when awake, every 10 s while the display is paused for low power, only when the board's read-power call succeeded, immediately after the shared state was updated with the same reading. The `on_battery` argument is `rabble_state_on_battery()`. |
| `note_state` | `rabble_input.c`, input task loop | every loop pass (10 ms awake, 50 ms resting, up to 1 s or 10 s when waiting on buttons): screen-off is `rabble_state_asleep()`, resting is "display stopped and CPU allowed to sleep". Must be a near-free call when the pair is unchanged. |
| `reset` | `rabble_input.c` serial console command `>power.reset`; `apache/rabble_settings_ui.c` "reset" button on the battery page | serial task (priority 5), LVGL/UI task |
| `read` | `rabble_settings_ui.c` battery page refresh | UI task, at most once per second while the page is shown |
| `drain` | `rabble_settings_ui.c` (same refresh) | UI task |
| `json` | `rabble_input.c`, `>power` and `>power.reset` console commands | serial task, with a 2048-byte buffer, printed as `@power <json>` |
| `saved_json` | `rabble_input.c`, same console commands | serial task; printed as `@power.saved <json>` before `@power ...` when not NULL |

No other file in `firmware/components`, `firmware/main` or `firmware/bsp` references any of these names. (Settings UI text built from the struct is in section 8.)

## 3. Threading and task model (as requirements)

| Item | Requirement |
|---|---|
| Tasks / timers | The module creates no task, no timer and no event group. Nothing runs by itself. |
| Core / priority | No affinity or priority of its own. Calls arrive from the input task (priority 6), the serial task (5), the UI task and the main task; they may be on either core. |
| Serialisation | The API calls are mutually exclusive: each sees and leaves a consistent meter, whichever tasks call. Waiting for another call to finish is acceptable (a few milliseconds at most); giving up on a timeout is not. Calls before `init` are not supported. |
| `note_state` cost | It runs on every input-loop pass (10 ms), so a call whose two flags equal the last ones given must be close to free. Only the input task calls it. |
| Idle-task callback | A function registered with ESP-IDF's automatic-light-sleep exit notification (`esp_pm_light_sleep_register_cbs`, exit callback) runs in the idle task, possibly in a context where flash access is not allowed: it must be placed in IRAM and touch only IRAM-safe, interrupt-safe things. Its job: count each light sleep whose reported duration is greater than 0 microseconds, and total those durations, in a way that readers on other cores always see a consistent pair. A zero or negative duration is ignored. Registration failure is logged as a warning (`light-sleep callback: <esp_err_to_name>`) and is otherwise ignored; sleep figures then read as zero sleeps. The totals count from boot; the measurement uses differences (4.3). |
| Time source | `esp_timer_get_time()` (microseconds since boot) for everything except the power-lock figures (4.4). |
| Memory | Whatever working memory the module needs is obtained at `init` (external RAM is fine and preferred); the module does not allocate after `init`, apart from releasing the saved-record copy on reset. Failure to get it at `init` may be fatal. The serial task has a 3.5 KB stack: `json`, `read` and `reset` must not put more than a few hundred bytes on the stack. |
| Cost | `read` and `json` while a measurement is running ask the chip for fresh counters (including one dump of the power-lock table, a few milliseconds at most); they are called at about 1 Hz and must not wake the chip by themselves otherwise. `note_power` never wakes anything (it runs because the input task is already running). |

## 4. Behaviour

### 4.1 Measurement state machine

States: **idle** (nothing measured yet since boot or reset), **running**, **stopped** (a finished measurement is held).

| Event | From | To | Effects |
|---|---|---|---|
| `note_power(p, true)` | idle or stopped | running | Take the start snapshot (4.4). `pct_start = pct_now = p.battery_pct`, `mv_start = mv_now = p.battery_mv`. Zero the screen-off and resting totals. Set started and running. Log line (A). Save the record (4.8). |
| `note_power(p, true)` | running | running | `pct_now = p.battery_pct`, `mv_now = p.battery_mv`. If at least 30 minutes of the monotonic clock have passed since the record was last saved, save it (4.8). |
| `note_power(p, false)` | running | stopped | Take the end snapshot; the totals (4.2) are counted up to this instant; clear running. Log line (B). Save the record. The figures are frozen: later reads return the same numbers (apart from `running` false) until the next start. |
| `note_power(p, false)` | idle or stopped | same | Nothing, except that the reading is remembered as "latest". |
| `reset()` | running | running | Forget the saved record (4.8). Start again exactly as in the first row, using the *latest reading* handed to `note_power` (so line (A) is logged again and a fresh record saved). |
| `reset()` | idle or stopped | idle | Forget the saved record; `started` becomes false; nothing is logged. |

The latest reading is stored on every `note_power` call regardless of the flag, and before the start row runs, so a measurement that starts on a call uses that call's percent and millivolts as its start values.

Log lines, at info level, text exactly:

* (A) `on battery at <pct>% (<mv> mV): measuring` with the start percent and start millivolts as plain integers.
* (B) `USB back after <S> s on battery: <pct_start>% -> <pct_now>% (<mv_start> -> <mv_now> mV)` where `<S>` is the whole seconds between the start counters' time and the end counters' time (integer division by 1,000,000, so a fraction is dropped).

No other logging apart from the light-sleep registration warning.

### 4.2 Screen-off and resting time

The module always knows the latest screen-off and resting values given to `note_state`, **whether or not a measurement is running**; both start false. The screen-off time (and, separately, the resting time) of a measurement is the total time, between the measurement's start and its end or now, during which that value was true. A value is taken to hold from the `note_state` call that set it until the call that changed it; time before the measurement's start never counts.

* At start both totals are zero. Because the flags persist across measurements, a measurement that starts while the flags are already true begins accruing from its first instant (vector `01-cycle-nodump`, steps 33 to 37, shows 1000 per mille).
* A `note_state` call with unchanged values changes nothing.
* `reset()` while running restarts both totals at zero from the restart instant.

### 4.3 What `read` returns

Not started: every field is zero, false or empty, except `slept_pm`, `busy_pm`, `pct_start` and `pct_now`, which are `-1`.

If started: bring a running measurement up to date (fresh counters and 4.2 accounting); a stopped one uses its frozen end set. Let *span* be the monotonic time from the start set to the end/current set in microseconds. Then:

| Field | Value |
|---|---|
| `started` / `running` | true / current running flag |
| `secs` | span divided by 1,000,000, integer division |
| `pct_start`, `pct_now`, `mv_start`, `mv_now` | as stored |
| `screen_off_pm`, `resting_pm` | per-mille (rule below) of the screen-off and resting totals (4.2) over span |
| `slept_pm` | per-mille of the light-sleep time gathered by the callback during the measurement (total now minus total at start) over span. With the callback available this is 0 or more. Without light-sleep callbacks in the build: stays `-1`. |
| `sleeps` | callback count now minus count at start (0 without the callback) |
| `busy_pm`, `awake` | only when profiling data is usable (4.4); otherwise `busy_pm` stays `-1` and `awake` stays empty |

Per-mille rule (used everywhere in this module): the result is 0 unless both the part and the whole are greater than zero; otherwise it is the part multiplied by 1000 and divided by the whole with integer division (truncation, no rounding), computed in 64 bits. Vectors: `permille.tsv`.

### 4.4 Power-management counters (profiling builds)

The device builds with ESP-IDF power-management profiling enabled (`CONFIG_PM_PROFILING=y`) and the light-sleep callbacks enabled (`CONFIG_PM_LIGHT_SLEEP_CALLBACKS=y`). With profiling off, everything in this subsection is absent: `busy_pm` stays `-1`, `awake` stays empty, and the JSON has no `modes`, `sleep_rejects` or `locks` members (vectors `expected-noprof/`).

ESP-IDF does not expose the profiling counters except as text, through `esp_pm_dump_locks(FILE *)` (a memory stream such as `fmemopen` works). The figures compare two snapshots, one at the measurement's start and one at its end or now; each snapshot covers the monotonic time, the light-sleep totals and the dump's figures. Room for at least 3 KB of dump text is needed (a typical device dump is well under that). If the dump cannot be obtained, that snapshot has no profiling figures (all zero). A dump too long for the room given may be cut; matching the original's cut exactly is **not** required (vector `09c` is informational), but it must not crash or overrun.

The dump text is ESP-IDF's public format. Parse it by lines (split on newline; within a line split on spaces and carriage returns). Rules:

1. A line starting `Time since boot up:` carries the chip's uptime in microseconds right after the colon. Store it as the set's "profile time". It is the denominator for every profiling per-mille figure (not the monotonic-clock span of 4.3; the two differ slightly).
2. A line exactly `Lock stats:` starts the lock section. A line exactly `Mode stats:` starts the mode section. (Sections end only by the next section line.)
3. A line starting `light_sleep_counts:` contains, later in the same line, `reject_counts:` followed by an integer: that is the number of automatic light sleeps the chip refused because a wake-up was already pending. Store it; if the marker is missing store 0. If the dump has no such line (light sleep disabled), the count is 0.
4. In the lock section, a line with at least 7 words whose first word is not `Name` is one lock: word 1 is the name, word 2 the type, word 5 the "total count" (number of times taken), word 6 the held time in microseconds. (Word 8, the percent column, may be split into two words such as `5` and `%`; that is why 7 or more is accepted.) Names and types are kept to 15 characters each. At most 24 locks are kept per set, in the order listed; any more are ignored.
5. In the mode section, a line with at least 3 words is a mode row if its first word is one of `SLEEP`, `APB_MIN`, `APB_MAX`, `CPU_MAX` (other first words are ignored). The time in microseconds is the third word when the second word (the CPU frequency) ends with the letter `M` (e.g. `240M`), and the fourth word when it does not (the frequency printed as `40 M` splits into two words). Rows may be missing (SLEEP is absent when light sleep is off); missing rows read as 0.
6. Anything else is ignored.

Usable profiling data: both the start set and the end/current set must have a profile time greater than 0, and their difference (the *profile span*) must be positive. If not, `busy_pm` stays -1, `awake` stays empty, and the JSON omits the profiling members (vectors `09b`).

When usable:

* `busy_pm` = per-mille of the profile span for the increase of the `CPU_MAX` mode time between the sets.
* Per-lock figures ("lock use since the start"): for each lock in the end/current list, in list order, find the **first not-yet-used** lock of the start list with the same name **and** the same type; if found, mark it used. When found and the end held time is not smaller than the start held time, the lock's held time and taken count are the end values minus the start values; when found but the end held time is smaller (the lock was recreated under the old name), or not found at all, the end values are used whole. Same-named locks therefore pair off one to one in list order (vector `07`).
* `awake` text: from those locks, ignore every lock whose name starts with `rtos` (the CPUs' own locks, one per core) and every lock whose held per-mille (over the profile span) is 0. Of the rest, pick the one with the largest held time, and the next largest; ties are decided in favour of the lock earlier in the list. Write them as `<name> <p>.<q>%` joined by `, ` where `p.q` is the lock's held per-mille over the profile span divided by ten with one decimal digit (so 40 per mille shows `4.0%`, 1 shows `0.1%`). Only one entry when only one qualifies. If none qualifies: the word `nothing`. The text fits 47 characters plus NUL; with 15-character names it cannot overflow, but never write past the 48-byte field.

### 4.5 Light-sleep totals

Cumulative since boot, never reset by `reset()`. A measurement's `slept_pm` and `sleeps` are the difference between the sets taken at its start and at its end or now (4.3). Counters read with the same critical section the callback writes with.

### 4.6 Concurrency detail

`read` and `json` are consistent snapshots: they may hold off other calls while they take fresh figures and parse the dump, so the input task's `note_power` may wait a few milliseconds behind a UI read. That is acceptable.

### 4.7 Reset

See the table in 4.1. Additionally `reset()` always frees the copy of the previous boot's record and invalidates the stored record so that no later boot reports it; when running, the new start immediately stores a fresh record. The serial `>power.reset` command calls `reset()` first and then prints the (new) JSON; the settings button calls `reset()` and then forces its own display refresh.

### 4.8 The record that survives a warm reset

* **What is stored:** the same text `json` would produce (section 6) at the moment of saving, with a validity marker and an integrity check so that garbage in memory after a cold power-up is never reported. Use memory that survives software resets and watchdog/panic resets but not power loss (ESP-IDF "RTC no-init" attribute). Capacity: 2048 bytes of text in profiling builds (the JSON with two dozen locks fits), 384 in non-profiling builds; longer text is cut to fit. The integrity check must catch a flipped bit and a write interrupted by a reset (write the text and length first, set the marker and check value last, in place, in a way that a reset partway leaves the record invalid); use at least a 32-bit check. The in-memory layout and checksum are free choices; they are not observable.
* **When saved:** (a) when a measurement starts (including by `reset()` while running); (b) when it stops; (c) while running, from `note_power`, when at least 30 minutes of the monotonic clock have passed since the last save (checked on each call, so in practice the next reading after the 30 minutes; 1,800,000,000 µs, with the comparison "greater than or equal"). The 30-minute clock starts at the first save and is restarted by every save. Saving never happens from a timer or from `read`/`json` calls, and it must not wake the chip. A save with profiling builds takes fresh counters (dump parse).
* **At boot (`init`):** if the record is valid, keep a private copy and print one line on standard output, `@power.saved <json>` followed by a newline, immediately and unasked (a board whose USB is a UART bridge takes no commands, so the host sees it anyway). If invalid or absent, print nothing. The record is **not** cleared by being reported: it stays valid in memory until a newer one overwrites it (the first save of this boot) or `reset()` invalidates it. The copy returned by `saved_json` is the one made at `init`; it does not change when a newer record is saved, and is NULL after `reset()` and when nothing valid was found. Vectors `11` to `11g`.
* A record from an earlier boot is reported even if the earlier measurement never stopped (crash on battery); its `"running"` is then true.

## 5. `rabble_battery_drain`

Pure function of the struct `b` (as returned by `read`). Let `used = pct_start - pct_now`.

* Returns false, writing nothing, when the struct is not started, or `used` is not greater than 0, or `secs` is less than 600.
* Otherwise returns true with `*rate10` = used × 36000 ÷ secs (tenths of a percent per hour, 64-bit arithmetic, integer truncation) and `*full_h` = secs ÷ (used × 36) (hours for a full 100 percent at that rate, 64-bit, truncation). Example: 1 percent in 600 s gives 60 (6.0 percent per hour) and 16 hours.

Vectors: `drain.tsv` (840 rows over started/unstarted, drops, rises, negatives, the 599/600 s boundary).

## 6. The JSON line

### 6.1 Format

One JSON object, no whitespace, no newline, members in exactly this order. Numbers in "per-mille shown as percent" form are `<pm / 10>.<pm % 10>` (one decimal digit, non-negative values only), and the value `null` when the underlying figure is -1.

| Member | Value |
|---|---|
| `boot` | how this boot began: a string from the reset reason (6.2) |
| `uptime` | whole seconds since boot (monotonic clock / 1,000,000, truncated) |
| `started`, `running` | `true` / `false` |
| `secs` | integer, as 4.3 |
| `battery_pct` | `[start,now]` integers (-1 unknown) |
| `battery_mv` | `[start,now]` integers (0 unknown) |
| `screen_off` | screen-off per mille as percent (e.g. `66.6`) |
| `resting` | resting per mille as percent |
| `slept` | slept per mille as percent, or `null` when unknown (-1) |
| `sleeps` | integer count |
| `busy` | busy per mille as percent, or `null` |
| `modes` | **only when profiling data is usable (4.4)**: object with members `SLEEP`, `APB_MIN`, `APB_MAX`, `CPU_MAX` in this order, each the per-mille (over the profile span) of the increase in that mode's time, shown as percent |
| `sleep_rejects` | (same condition) integer: increase of the refused-light-sleep count between the sets |
| `locks` | (same condition) array of objects `{"name":"..","type":"..","held":<percent>,"taken":<int>}` in the end list's order, up to 24, using the per-lock figures of 4.4 (held shown as percent over the profile span, taken as the count difference where one applies) |

The names are written as they came from the dump, without escaping (the chip's lock names contain no quotes). The object ends `}`. Values come from the same data as `read`, produced under one consistent set of counters. A not-started meter yields the same members with the defaults of 4.3 (`started` false, `slept` null, and so on). Every member of the table appears in every output except the three profiling-only ones.

Typical length without profiling: 175 to 190 characters. With profiling and five locks: about 590. The caller's buffer is 2048 bytes. If `cap` is too small, the text is cut after `cap - 1` characters, a NUL is written, and the returned length is the cut length (vector `12-json-caps`).

### 6.2 `boot` strings

| Reset reason (ESP-IDF `esp_reset_reason_t`) | Text |
|---|---|
| `ESP_RST_POWERON` | `power on` |
| `ESP_RST_SW` | `restart` |
| `ESP_RST_PANIC` | `panic` |
| `ESP_RST_INT_WDT`, `ESP_RST_TASK_WDT`, `ESP_RST_WDT` | `watchdog` |
| `ESP_RST_DEEPSLEEP` | `deep sleep` |
| `ESP_RST_BROWNOUT` | `brownout` |
| `ESP_RST_USB` | `usb` |
| `ESP_RST_JTAG` | `jtag` |
| anything else | `other` |

Exactly as `reset-names.tsv`. The reason is read from `esp_reset_reason()` each time the JSON is produced; the string in a saved record is the reason of the boot that saved it.

## 7. Thresholds, filters, hysteresis and timings the user can observe (summary)

There are no thresholds on percent or voltage in this module, no filter and no hysteresis on readings (the latest reading wins), and no power-off or low-battery action. Everything observable is:

| What | Value |
|---|---|
| Measurement begins | the first `note_power` call with `on_battery` true while not running |
| Measurement ends | the first `note_power` call with `on_battery` false while running |
| Reading cadence feeding it | every 2 s awake, 10 s with the display paused (input task) |
| Drain estimate available after | at least 600 s on battery and at least 1 percent used |
| Record save interval | 30 min on battery (plus start and stop) |
| Awake-lock text | the 2 largest non-`rtos` locks with at least 0.1 percent of the time |
| Lock table capacity | 24 locks |
| Dump buffer | 3072 bytes |
| Reset-surviving record capacity | 2048 bytes (profiling) |
| Settings page refresh | at most 1 Hz (in the settings UI, not here) |

## 8. What the settings screen does with the figures (context, not part of this module)

The settings battery page (`apache/rabble_settings_ui.c`, redesign track) builds its text from `read`, `drain` and the live `rabble_power_t`. It is listed so the integrator knows what to look at on the device: "Unplug USB to start measuring." (not started and a battery is present) or "No battery" (percent -1); "On battery for H h M min" while running, "Last run: ... on battery" after; level text with a charge symbol when charging, percent and volts to two decimals; drain text `<used>%, <rate>%/h` with "lasts ~N h" once `drain` returns true, else `<used>% so far` and "measuring"; screen-off, slept and busy as percentages; wakes per second as `sleeps*10/secs` shown to one decimal when `slept_pm` is known; and `Also kept awake by: <awake>` when `awake` is non-empty. The new module must therefore keep returning `awake` as bare text without the prefix, and `slept_pm == -1` only when light-sleep figures are truly unavailable.

## 9. Edge cases summary

| Case | Required behaviour |
|---|---|
| Board has no battery (percent -1) and is on USB | `on_battery` is false; nothing ever starts; reads stay not started |
| `>nap` on USB (state override makes `on_battery` true) | A measurement starts at once with the USB reading's percent and millivolts; it stops when the override is dropped or the board wakes |
| Start with percent -1 or millivolts 0 | Accepted; `drain` then returns false |
| Percent rises during a measurement | `pct_now` follows; `drain` returns false (used not positive) |
| Reading arrives while stopped | Ignored apart from being remembered |
| `read` or `json` before any measurement | The default not-started figures; `json` still reports `boot` and `uptime` |
| Dump unreadable at start, readable later (or the reverse) | Profiling members omitted, `busy_pm` -1, `awake` empty (vector `09b`) |
| Same lock name twice / type changes / lock created mid-run / lock recreated (held total drops) | 4.4 matching rules (vectors `07`, `07b`) |
| More than 24 locks | First 24 only |
| Profiling off in the build | No profiling members; `busy_pm` -1; `awake` empty |
| Light-sleep callbacks off in the build | `slept_pm` -1, `sleeps` 0, JSON `slept` null |
| Callback registration fails | Warning logged; carry on |
| Record corrupt, or marker bad, or never written | Nothing printed, `saved_json` NULL (vectors `11c`, `11d`, `11e`) |
| `json` with a tiny buffer | 6.1; no overflow; a 1-byte buffer returns 0 |
| Clock | Never goes backwards; no handling for wrap is needed |

## 10. May call / may not call

May call: FreeRTOS (mutex, critical sections), ESP-IDF `esp_timer`, `esp_pm` (dump locks, light-sleep callbacks), `esp_system` (reset reason), `esp_heap_caps`, `esp_log`, standard C (`snprintf`, `fmemopen`, `printf`). It may include `rabble_state.h` for `rabble_power_t` only. It must not call `rabble_state_*`, `rabble_board`, `rabble_axp2101` or any other `rabble_*` function: the callers hand it everything.

## 11. Device behaviour checklist for the integrator

Marks: **[bench]** no hands needed; **[HANDS]** needs Mark to plug or unplug USB or run on battery.

1. **[bench]** Build with the sdkconfig as shipped (power management, profiling, light-sleep callbacks on); no `rabble_battery` symbol collision between old and new files (delete the old pair in the same commit).
2. **[bench]** Boot on USB. Serial `>power` returns `@power {...}` with `"started":false,"running":false`, `battery_pct:[-1,-1]` and `"boot"` matching how the board was started. No `@power.saved` line on a first cold boot.
3. **[bench]** Serial `>nap` on USB: log shows `on battery at ...% (... mV): measuring`; `>power` shows `"running":true`, screen_off climbing; `w` (wake) ends it with `USB back after ...`. (The override is the input module's; this checks the start and stop hooks.)
4. **[bench]** Serial `>power.reset` while running restarts at 0 s with the same log line; while stopped yields `"started":false` and no further `@power.saved` after the next boot.
5. **[bench]** Call `>power` 1,000 times (script it): free heap and stack high-water mark of the serial task unchanged, no watchdog, light sleep still entered when the screen is off.
6. **[HANDS]** Unplug USB with the screen on: within 2 s a `measuring` log line with the true percent and millivolts. Keep the screen on 1 minute, then let it sleep: the settings battery page (or `@power` via the UART bridge board if used) shows `screen_off` and `resting` rising only while asleep; `slept` rises only when the board is truly dark and the console host is detached (a USB host attached blocks the low-power state, so on battery without a cable `resting` is the proof).
7. **[HANDS]** Run on battery for at least 11 minutes, then check the settings page: drain figure appears (`<n>%, <r>%/h` and `lasts ~N h`) only after the percent dropped by at least one point and at least 600 s passed; before that "measuring" with `<n>% so far`.
8. **[HANDS]** Plug USB back in. Log line `USB back after <S> s on battery: ... -> ...`; the page says "Last run: ..." with frozen numbers. If the board resets as the port opens, the next boot prints `@power.saved {...}` at once (running false when the save at USB-return happened, running true if the board reset before it) and `>power` repeats it first.
9. **[HANDS]** Leave on battery over 35 minutes with the screen dark, then press the board's reset button while still on battery (a warm reset). The next boot's `@power.saved` shows `secs` of at least about 1800 and `running` true, proving the 30-minute save. (Removing all power instead, correctly, reports nothing.)
10. **[HANDS]** Pull and reinsert the battery (cold start): no `@power.saved` line is printed and none is stale from an earlier run.
11. **[bench]** Wi-Fi connected on battery with the screen dark: `awake` / the page's "Also kept awake by" line names `wifi` (or whichever lock really holds); stays "nothing" when only the CPUs' own locks are active.
12. **[bench]** With the original binary and the new binary flashed in turn on the same board and the same script (three plug cycles, the same screen pattern), the `>power` figures agree within the natural variation of time; compare the formats character for character.
13. **[bench]** Run the vector scripts through a host test vehicle (section 12) and compare all `expected-full` and `expected-noprof` files byte for byte.

## 12. Host test vehicle

The implementer builds a host program (gcc, no device) that compiles the new module against small stand-ins for the ESP-IDF pieces it calls, and runs the scripts in `w2-battery-vectors/scripts/` using the language in that README. Stand-ins needed: a settable clock for `esp_timer_get_time`, a settable reset reason, `esp_pm_dump_locks` writing the text set by the script's `dump` block, a registered light-sleep callback that the `wake` op invokes, `esp_pm_light_sleep_register_cbs`, heap allocation, log lines printed as `LOG<TAB>I|W<TAB>text`, plain `printf` to standard output, and a way to expose the RTC record: either keep it in a variable that the `reboot` op preserves while zeroing everything else (build the stand-in so that `RTC no-init` memory is a plain global the test never clears), or give the module a test-only accessor. The `rtc` op output in the expected files is what a decoded record would be; if the new design stores the text directly the vehicle can print it as is.

The pure tables (`permille.tsv`, `drain.tsv`, `reset-names.tsv`) can be checked directly against the functions of 4.3, 5 and 6.2. The expected files have no random content and the clock is fake, so a correct implementation matches all of them exactly, including all log and standard-output lines and their order.

## 13. Ambiguities, doubts and decisions for the reviewer

1. **The brief's premise.** Section 0: no percent curve, charge detection or power-off lives here. If Mark wants "charge-curve and power-off behaviour kept exactly" it is specified (or must be, as an addition) for `rabble_axp2101` (percent, charging) and `rabble_input` (power-off). Flagged to the caller.
2. **`charging` and `usb` unused.** They are stored but never reported. A redesign could add them to the JSON; the current JSON does not have them. Not required.
3. **Profile span vs clock span.** Profiling per-mille figures divide by the chip's own uptime difference, the main figures by the monotonic clock difference. They are almost equal. Keep both as specified (the vectors use different values for the two so a mixup shows).
4. **Dump buffer overflow** (vector `09c`) shows a cut dump yields zero mode figures and a partial lock list. Reproduction not required; do not crash and do not write beyond the buffer.
5. **Lock name/type truncation to 15 characters.** The chip itself prints at most 15-character names; the 15-character type field is large enough for ESP-IDF's three lock types. Longer text would be cut.
6. **Standard-output flush.** Flushing after the `@power.saved` line at `init` is optional and harmless.
7. **Order of the two `rabble_battery_json` consumers at boot** is not defined; both are console-only.
8. **`rabble_battery_json` with `cap` 0** is undefined and never happens.
9. **`note_state` cost.** How the cheap unchanged-values path is made safe against concurrent readers is the implementer's choice.
10. **Wake-per-second on the page** divides `sleeps` by `secs`, so it reads 0.0 until the first whole second. Settings-UI behaviour, not this module's.
