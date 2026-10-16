# W0 spec: rabble_state (shared device state)

> Clean-room spec, wave W0. Author role: S. Files to be replaced: `apache/rabble_state.c` and `apache/rabble_state.h`. The new files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Interface names are frozen: every existing caller must compile and behave unchanged.

## 1. Purpose

One small module holding the live, device-wide state that the voice pipeline, the input task, the beam, the motion task and the UI share. It carries: the current mode with its age, an audio level and a phase progress value, a one-page caption string with change detection, the caption page geometry set by the UI, the latest power reading, a "last user interaction" clock, the screen-asleep flag with a wake/nudge primitive for sleeping tasks, a battery-bench override, and a short-lived "happy" pet reaction.

It is passive storage plus a few derived values. It owns no task, no timer, no display or hardware access, and publishes by being polled, with one exception: tasks resting while the screen sleeps are woken through `rabble_state_wait_awake` / `rabble_state_nudge`. There are no callbacks and no listener lists.

## 2. Public interface (complete and exact)

Header name `rabble_state.h`, include guard by `#pragma once`. It must include `<stdbool.h>`, `<stddef.h>`, `<stdint.h>` (callers rely on `bool`, `size_t`, `uint32_t` coming through it; `rabble_board.h` includes this header to get `rabble_power_t`). Adding `extern "C"` guards is allowed and harmless. The header must not include FreeRTOS or ESP-IDF headers.

### 2.1 Types

`rabble_mode_t`, an enum with these enumerators and values, in this order:

| Name | Value | Meaning |
|---|---|---|
| `RABBLE_MODE_BOOT` | 0 | Power-up until the app declares the device ready. Initial mode. |
| `RABBLE_MODE_IDLE` | 1 | Ready, nothing happening. |
| `RABBLE_MODE_LISTENING` | 2 | Recording / live capture. |
| `RABBLE_MODE_THINKING` | 3 | Sent, waiting for the reply. |
| `RABBLE_MODE_SPEAKING` | 4 | Reply audio playing. |
| `RABBLE_MODE_ERROR` | 5 | A fault the user should see. |
| `RABBLE_MODE_OFF` | 6 | Powering down. Special rules in 3.2. |
| `RABBLE_MODE_COUNT` | 7 | Count only, not a mode. Used by callers to size arrays indexed by mode and as an "unset" sentinel for a "last seen mode" variable. |

`rabble_power_t`, a struct with exactly these members in this order:

| Field | Type | Meaning |
|---|---|---|
| `battery_pct` | `int` | Charge percent; -1 means no battery connected. |
| `battery_mv` | `int` | Battery millivolts; 0 means the board cannot measure it. |
| `charging` | `bool` | Charger active. |
| `usb` | `bool` | External power present (charger or computer). |

Callers build one with designated initialisers (`{ .battery_pct = -1 }`, and a compound literal in the board code), so field names, types and the absence of other mandatory members must match. Size and layout beyond that are free, but keep it small: it is copied by value under a lock.

### 2.2 Macro

| Name | Value | Meaning |
|---|---|---|
| `RABBLE_CAPTION_MAX` | 400 | Capacity of the caption buffer in bytes including the terminating NUL. Callers size their own buffers with it (`char buf[RABBLE_CAPTION_MAX]`), so it must be an integer constant expression usable as an array size. |

### 2.3 Functions (24 in all, no exported globals)

| Prototype | Summary |
|---|---|
| `void rabble_state_init(void);` | Create primitives, set initial clocks. Call once, early. |
| `void rabble_state_set_mode(rabble_mode_t mode);` | Request a mode. Subject to the rules in 3.2. |
| `rabble_mode_t rabble_state_mode(float *secs_in_mode);` | Current mode; if the pointer is non-NULL, seconds since the mode last changed. |
| `void rabble_state_set_level(float level);` | Set live audio level, clamped to 0..1. |
| `float rabble_state_level(void);` | Read it. |
| `void rabble_state_set_progress(float progress);` | Set phase progress, clamped to 0..1. |
| `float rabble_state_progress(void);` | Read it. |
| `void rabble_state_set_caption(const char *fmt, ...) __attribute__((format(printf, 1, 2)));` | printf-style caption setter. The attribute must be kept so callers get format checking. |
| `bool rabble_state_caption(char *out, size_t out_len, uint32_t *version);` | Copy caption out if changed since `*version`. |
| `void rabble_state_set_page(int cols, int lines);` | Set the normal caption page geometry. |
| `void rabble_state_set_cjk_page(int cols, int lines);` | Set the optional CJK page geometry. |
| `void rabble_state_page(bool cjk, int *cols, int *lines);` | Read the geometry to use. |
| `void rabble_state_set_power(const rabble_power_t *power);` | Store a power reading. |
| `rabble_power_t rabble_state_power(void);` | Read a consistent snapshot. |
| `bool rabble_state_on_battery(void);` | Derived "running on battery" flag. |
| `void rabble_state_set_as_if_battery(bool on);` | Bench override for the previous. |
| `void rabble_state_poke(void);` | Record a user interaction now. |
| `float rabble_state_idle_secs(void);` | Seconds since the last interaction. |
| `void rabble_state_set_asleep(bool asleep);` | Enter or leave screen sleep. |
| `bool rabble_state_asleep(void);` | Read the flag. |
| `void rabble_state_wait_awake(uint32_t timeout_ms);` | Sleeping tasks' rest primitive. |
| `void rabble_state_nudge(void);` | Release a waiter without waking the screen. |
| `void rabble_state_make_happy(void);` | Start the pet reaction (also pokes). |
| `float rabble_state_happiness(void);` | Current reaction strength 0..1. |

External symbol count: 24 functions, 1 macro, 2 types, 8 enumerators = 35 public names. No global variables are exported.

### 2.4 Who uses what (grep of `accord/`, `apache/`, `bsp/`, `main/`, `nebula_lite/`; `main/` and `nebula_lite/` use nothing from this module)

| Symbol | Users |
|---|---|
| `rabble_state_init` | `apache/rabble_app.c` (once, in `rabble_app_run`, after `board->init()` and settings init, before `rabble_battery_init` and `rabble_ui_start`). |
| `set_mode` | `rabble_app.c` (IDLE after startup), `rabble_input.c` (OFF on power-off, IDLE on power-off failure, serial console mode forcing), `rabble_voice.c` (LISTENING, THINKING, SPEAKING, IDLE, ERROR). |
| `mode` | `rabble_input.c` (sleep decision needs IDLE), `rabble_voice.c` (NULL form: is mode IDLE), `accord/rabble_motion.c` (NULL form), `accord/rabble_entity.c` (both forms), `accord/rabble_ui.c` (both forms). |
| `set_level` / `level` | `rabble_voice.c` writes; `accord/rabble_entity.c`, `accord/rabble_ui.c` read. |
| `set_progress` / `progress` | `rabble_input.c`, `rabble_voice.c` write. `progress` getter has no current caller but is public and must exist. |
| `set_caption` | `rabble_app.c`, `rabble_input.c`, `rabble_voice.c` (many; formats include `"%s"`, quoted `"\"%s\""`, `"%s %.1fs"` with a double). Some pass a `page`/`text` string up to `RABBLE_CAPTION_MAX` long through `"%s"`. |
| `caption` | `rabble_input.c` (saves/restores caption around the hold-to-power-off prompt), `accord/rabble_entity.c`, `accord/rabble_ui.c` (each keeps its own `uint32_t` version variable, initially 0). |
| `set_page` | `accord/rabble_ui.c` (once at UI build). |
| `set_cjk_page` | No current caller. Public, must exist. |
| `page` | `apache/rabble_beam_text.c`. |
| `set_power` | `rabble_input.c` (input task, after each board `read_power`). |
| `power` | `rabble_settings_ui.c`, `rabble_setup.c`, `accord/rabble_entity.c`, `accord/rabble_ui.c`. |
| `on_battery` | `rabble_input.c`, `rabble_voice.c`. |
| `set_as_if_battery` | `rabble_input.c` (serial console bench command on; cleared when the screen wakes after a bench nap). |
| `poke` | `rabble_input.c`, `rabble_voice.c`, `rabble_setup.c`, `accord/rabble_motion.c`, `accord/rabble_ui.c`. |
| `idle_secs` | `rabble_input.c`. |
| `set_asleep` | `rabble_input.c`, `rabble_settings_ui.c`, `accord/rabble_ui.c`. |
| `asleep` | `rabble_input.c`, `rabble_voice.c`, `rabble_wifi.c`, `rabble_board.c`, `accord/rabble_motion.c`, `accord/rabble_ui.c`. |
| `wait_awake` | `rabble_voice.c` (voice task, resting). |
| `nudge` | `rabble_voice.c` (two sites, from other tasks, to get the voice task to re-evaluate). |
| `make_happy` | `rabble_input.c`, `rabble_voice.c`, `accord/rabble_ui.c`. |
| `happiness` | `accord/rabble_entity.c`, `accord/rabble_ui.c`. |
| `RABBLE_CAPTION_MAX` | `rabble_voice.c`, `accord/rabble_entity.c`, `accord/rabble_ui.c`. |
| `RABBLE_MODE_COUNT` | `rabble_input.c`, `accord/rabble_entity.c`, `accord/rabble_ui.c`. |
| `rabble_power_t` | `rabble_board.h` (`read_power` vtable entry), `rabble_battery.h/.c`, `bsp/bsp_waveshare_175b.c`, plus the `power` users above. |

## 3. Behaviour

### 3.1 Threading and locking model

Callers run on many tasks: the app main task (init, startup), the LVGL/UI task (pinned to `RABBLE_UI_CORE`, from `rabble_mem.h`), the voice task (`RABBLE_AUDIO_CORE`, priority 6), the input task (prio 6) and the serial console task (prio 5), the motion task (prio 4), the Wi-Fi keeper (prio 4), the beam session task (core 0, prio 5), and LVGL event callbacks. The two cores can run callers truly in parallel.

Rules for the implementation:

1. All functions are task-context only. None may be called from an ISR, and none is required to be ISR-safe. None of them blocks except `rabble_state_wait_awake` (blocks by design) and `rabble_state_set_caption` (may wait briefly for another caller, see 3.5).
2. Scalar values (mode, mode timestamp, level, progress, poke time, happy deadline, asleep flag, page geometry, as-if-battery flag) are single independent values. They need no lock but each read must return a value that some writer actually stored. The 64-bit microsecond timestamps are not atomic on the 32-bit target in a naive implementation; a torn read would show as a wildly wrong seconds value for one frame. The new implementation should avoid that (use a lock, or retry-read, or store them in a way that is atomic); the original did not, so this is a permitted improvement, not a requirement.
3. A reader must always see a whole caption string together with its matching version, and a whole power struct, even with writers on the other core. Choose your own mechanism; whatever lock you use must be held only briefly (copy lengths are bounded by 400 bytes) and nothing slow (formatting, text conversion) may happen while a reader could be held off.
4. No deadlocks or nested locking between public functions.
5. Returned data: no function returns a pointer. Every string and struct is copied out into caller storage. `rabble_state_page` writes through its two out pointers, which must be non-NULL.

### 3.2 Mode rules

1. Initial mode is `RABBLE_MODE_BOOT`. The time-in-mode clock starts at `rabble_state_init`.
2. `set_mode(m)` where `m` equals the current mode does nothing, and in particular does not restart the time-in-mode clock.
3. `OFF` is sticky: while the current mode is `OFF`, a request for any mode other than `IDLE` is silently ignored (the voice pipeline finishing a turn must not undo a shutdown). A request for `IDLE` while `OFF` is accepted and is how a failed power-off recovers. Requesting `OFF` while already `OFF` is the no-op in rule 2.
4. Any other accepted change stores the new mode and restarts the time-in-mode clock. No other transition is restricted: BOOT, IDLE, LISTENING, THINKING, SPEAKING, ERROR may follow one another in any order. The module does not validate the numeric value; callers only pass the enumerators. A value of `RABBLE_MODE_COUNT` or greater is stored as given and is the caller's bug.
5. A mode change sets no other state: it does not touch level, progress, caption, the poke clock, or asleep. It sends no wake or nudge. Observers poll `rabble_state_mode`. The order of the two stored values (timestamp then mode, or the reverse) is not observable by callers in a way they rely on, but the mode and its age must not be read as "new mode with old age" for more than a single polling frame.
6. `mode(&secs)` returns the current mode and writes seconds (float) since the last accepted change, measured from the monotonic microsecond clock (`esp_timer_get_time`). With a NULL pointer only the mode is returned.

### 3.3 Level and progress

`set_level` and `set_progress` clamp the argument into 0.0..1.0 (below 0 gives 0, above 1 gives 1) and store it. Both start at 0. NaN input is unspecified. Getters return the last stored value. Neither is reset by mode changes; the writers (voice pipeline, input task on power-off) zero them explicitly.

### 3.4 Power

1. Initial power: `battery_pct = -1`, everything else zero/false.
2. `set_power(p)` stores a copy of the struct. If that store changes the derived `on_battery()` value, a nudge (3.7) is sent. It does not poke and does not wake the screen. Passing NULL is not supported.
3. `power()` returns a consistent copy.
4. `on_battery()` is true when the bench override is on, or when no USB power is present and a battery is present (`battery_pct >= 0`). A device with no battery is therefore never "on battery" without the override; a device with a battery plus `usb == true` is not.
5. `set_as_if_battery(on)` stores the override. If the value changed it calls `nudge`; if unchanged nothing happens.
6. Meaning for callers: power-saving rest (voice task resting, display pause, Wi-Fi nap) is permitted only while `on_battery()` is true, which is why a change must nudge a resting waiter to re-evaluate.

### 3.5 Caption

1. State: one NUL-terminated string of capacity `RABBLE_CAPTION_MAX` (400 bytes including NUL, so at most 399 characters) and a 32-bit version counter. Initially the string is empty and the version is 0.
2. `set_caption(fmt, ...)` formats with printf semantics into a scratch area of the same capacity. Output longer than 399 bytes is truncated (so a cut can land inside a multi-byte UTF-8 sequence). Several callers run on small stacks (a few KB) and pass long strings, so the function must not need hundreds of bytes of the caller's stack. Concurrent callers on different tasks must not corrupt each other's result; a caller may block briefly while another formats. Task context only, never from an ISR.
3. After formatting, the text is passed through `rabble_text_to_ascii(buf, 400)` (from `rabble_text.h`, W1 module, whose interface stays as is). That function replaces typographic characters (curly quotes, dashes, accented Latin letters and similar) by ASCII stand-ins and drops characters it has no stand-in for; if an expansion would not fit in the buffer, the text ends there. The conversion must not hold off readers.
4. The converted text is then compared with the stored caption. Only if different is it stored and the version incremented by one. Setting the same text again changes nothing (no version bump), so repeated identical updates cost observers nothing. The version wraps naturally at 2^32.
5. `caption(out, out_len, version)`: atomically with respect to setters, if `*version` differs from the current version, copy the caption into `out` truncating to `out_len - 1` bytes plus NUL, set `*version` to the current version, and return true. If equal return false and leave `out` and `*version` untouched. The comparison is for inequality, not ordering. `version` must be non-NULL. If `out_len` is 0 nothing is written but the version is still advanced and true returned.
6. Observers hold their own version variables, starting at 0. Consequence callers rely on: a caption that was never set to anything other than empty reads as "unchanged" for an observer at version 0. A set to a non-empty string always reads as changed for every observer at version 0 or any older value. Every observer independently sees every change at most once, and may miss intermediate values if two sets happen between its polls (it gets the latest).
7. Setting the caption does not poke, wake, or nudge. It does not depend on the mode.
8. The `%` conversion arguments of callers include `%s` with strings up to the full capacity and `%.1f` with a `double`. Standard printf must be used.
9. Before `init`, `set_caption` must not be called. The original would fault; making it safe is optional.

### 3.6 Caption page geometry

1. Two geometry settings: the normal page and an optional CJK page, each a column count and a line count (how many characters per line and how many lines of reply text the screen shows at once). The beam text code wraps and pages replies to fit.
2. Defaults before anyone calls a setter: normal page 16 columns by 2 lines; CJK page 0 columns by 0 lines (meaning "none set").
3. `set_page` and `set_cjk_page` store both numbers with no validation or clamping and no notification.
4. `page(cjk, &cols, &lines)`: if `cjk` is true and the stored CJK column count is greater than zero, return the CJK pair; otherwise return the normal pair. (Only the column count is tested; a CJK page with columns set but lines zero is returned as is.) Both pointers are written on every call. Reading and writing may race between tasks; a reader may see a new `cols` with an old `lines` for one call, which callers tolerate. Two successive stores need not be atomic as a pair.

### 3.7 Interaction clock, sleep and wake/nudge

1. `poke()` records "now" as the last interaction. `idle_secs()` returns seconds since then. The initial value is the time of `init`, so idle time starts near zero. Callers read it against configured sleep timeouts. Poke does not change the asleep flag or send a nudge.
2. The screen-asleep flag starts false (awake). `asleep()` returns it.
3. `set_asleep(false)` pokes first and then marks awake; `set_asleep(true)` marks asleep. Both set the flag even if it already has that value and have no other side effects on mode or caption. Entering sleep must make any later `wait_awake` block; leaving it must release any currently blocked waiter immediately.
4. A waiter is released by either of two conditions: "awake" (level-like: holds for as long as the device is awake, including right from init) and "nudged" (a single pending flag, not a counter).
5. `wait_awake(timeout_ms)` returns when any of these holds: the device is awake (so while awake it returns immediately and never blocks), a nudge is pending, or `timeout_ms` milliseconds have passed (converted to ticks; a value of 0 means do not block). On every return it clears the pending nudge. It must not clear the awake condition. Several nudges before a wait collapse into one. Intended use is a single waiter (the voice task). If two tasks wait, a nudge may be consumed by either; no fairness guarantee.
6. `nudge()` marks the nudge pending, which releases a blocked `wait_awake` early. It does NOT mark the device awake, does not poke, and does not change the asleep flag, so the display stays dark. A nudge sent while nobody waits stays pending and makes the next `wait_awake` return at once, after which it is cleared.
7. Who nudges: `set_power` on an on-battery change, `set_as_if_battery` on change, and external callers (voice code) via `nudge`. `set_asleep(false)` wakes waiters through the awake condition, not the nudge.
8. `wait_awake` before `init` is invalid (no primitive exists). Same for `nudge` and `set_asleep`.

### 3.8 Happiness (pet reaction)

1. `make_happy()` sets a deadline 1.6 seconds in the future (replacing any earlier one; calling again restarts the full 1.6 s) and pokes (3.7 rule 1).
2. `happiness()` returns 0.0 if the deadline has passed or was never set. While more than 0.4 s remain it returns 1.0. During the last 0.4 s it returns remaining/0.4, falling linearly from 1.0 to 0.0 (an "ease out"). Result is always in 0..1.
3. It does not depend on mode; callers choose whether to call `make_happy` (they skip it in IDLE for voice-side reactions and the UI calls it only in IDLE).

### 3.9 State table

The module is a set of independent small state variables rather than one state machine; only the mode and the sleep/wake pair have transitions.

Mode:

| From \ Event | set_mode(same) | set_mode(IDLE) | set_mode(OFF) | set_mode(other) |
|---|---|---|---|---|
| BOOT, IDLE, LISTENING, THINKING, SPEAKING, ERROR | no-op | to IDLE, restart age (no-op if already IDLE) | to OFF, restart age | to that mode, restart age |
| OFF | no-op | to IDLE, restart age | no-op | ignored |

No side effects beyond the mode and its age in any cell.

Sleep and wake primitive:

| State | Event | Next state | Side effects |
|---|---|---|---|
| Awake, no nudge | `set_asleep(true)` | Asleep | awake condition cleared; later waits block |
| Asleep | `set_asleep(false)` | Awake | poke; awake condition set; blocked waiter released |
| Asleep | `nudge()` | Asleep, nudge pending | blocked waiter released; screen stays dark |
| Asleep, waiter blocked | timeout expires | Asleep | waiter returns, nudge cleared |
| Awake | `wait_awake(t)` | Awake | returns immediately; clears pending nudge |
| Asleep, nudge pending | `wait_awake(t)` | Asleep | returns immediately; clears nudge |
| Any | `set_power` changing on_battery, or `set_as_if_battery` changing value | same | `nudge()` |

Initial state at `init`: mode BOOT, age and idle clocks at now, awake, no nudge, caption empty with version 0, level 0, progress 0, power as in 3.4, page 16x2, CJK page none, override off, no happy deadline.

### 3.10 Ordering guarantees observers rely on

1. A caption read returns a complete string that was set at some moment, with its matching version.
2. A power read returns a complete struct.
3. After `set_asleep(false)` returns, `asleep()` is false on any task and `idle_secs()` is small.
4. After `set_caption("A")` returns on one task, `caption()` on any task with an older version returns "A" or a later caption.
5. Input task's power-off sequence sets asleep false, progress 0, level 0, mode OFF, caption in that order from one task; observers must not see the caption "GOODBYE!" with a mode other than OFF afterwards because later set_mode calls to non-IDLE values are ignored.

## 4. Timings, limits and edge cases

| Item | Value |
|---|---|
| Caption capacity | 400 bytes including NUL (399 usable) |
| Happy duration | 1.6 s total, full strength for the first 1.2 s, ease out over the last 0.4 s |
| Idle and mode age clock | monotonic microseconds (`esp_timer_get_time`), reported as float seconds |
| Page default | 16 columns, 2 lines; CJK none |
| Wait granularity | FreeRTOS ticks; `pdMS_TO_TICKS(timeout_ms)` |

Edge cases:

1. Calls before `rabble_state_init`: reading scalar getters, `asleep`, `power`, `on_battery`, `page`, `level`, `progress`, `happiness`, `mode` and `caption` must be harmless (they return the initial values; `mode` age and `idle_secs` count from time zero). `rabble_board.c` calls `asleep` possibly before init, so `asleep` must not touch a primitive that does not exist yet. `set_caption`, `set_asleep`, `nudge`, `wait_awake` before init: undefined (original faults); the new code may make them safe but must not rely on it.
2. `init` called twice: not supported; not required to be safe.
3. Long caption: truncated at 399 bytes after formatting, possibly splitting a UTF-8 sequence; the ASCII conversion then drops what it cannot interpret.
4. Caption with non-ASCII input: reduced to ASCII as in 3.5 rule 3. Pure-ASCII text passes unchanged.
5. Caption set to the current text: no version change.
6. Version wrap: handled by inequality compare.
7. No queues, no listener list, so no overflow case exists.
8. Out-of-range level or progress: clamped. Out-of-range mode: stored as is.
9. Power with `battery_pct` below -1 is stored as is; `on_battery` tests `>= 0`.
10. Two tasks calling `set_mode` at once: last writer wins, except the OFF rule is evaluated against the mode seen at call time (a race between OFF and a late THINKING is tolerated; callers do not depend on exact interleaving, but a racing tolerant implementation should still never leave OFF replaced by a non-IDLE mode when the request was made after OFF was visible).

## 5. What the module may call

Allowed: the C library, `esp_timer_get_time()` from `esp_timer.h`, any FreeRTOS synchronisation primitive you choose, and `rabble_text_to_ascii` from `rabble_text.h`. Prefer static allocation for anything created in `init`. It must not call any other `rabble_*` module, LVGL, drivers, logging in locked regions, or NVS. It must not depend on `rabble_board.h`, `rabble_mem.h` or `rabble_settings.h`.

Build wiring: the component has no `rabble_state`-specific CMake entry; it is picked up by the source-directory glob. The component `REQUIRES`/`PRIV_REQUIRES` already provide `esp_timer` and FreeRTOS. Header and source must not introduce a new component dependency.

## 6. Behaviour checklist (integrator, on the device)

Use the serial console and the UI. Console keys that force modes live in `rabble_input.c`; the commands are named in its help output.

1. Boot: caption "WAKING UP..." appears on the face during start, then clears; mode leaves BOOT for IDLE once voice is up (UI shows the idle face).
2. Hold the talk button: face goes to listening colours, caption "LISTENING..." (or the recording text) with a growing seconds counter, level moves the entity with the mic, progress advances. Release: thinking, then speaking with level driving the mouth, then idle.
3. Caption text with curly quotes, dashes and accents in a reply shows as plain ASCII equivalents with no missing glyph boxes; a reply over 399 characters is cut rather than crashing.
4. Repeat the same reply twice: no redraw flicker from caption churn (observable only by logging the version; optional).
5. Petting (touch the face while idle) makes the entity happy for about 1.6 s with the last 0.4 s easing out; during listening/thinking/speaking a touch does not start the happy animation.
6. Sleep: leave untouched on battery past the sleep timeout; display goes dark, `asleep` true. Touch or button wakes it and the idle counter restarts. On USB power with a battery the device does not nap.
7. Resting voice task: asleep on battery, unplug/plug USB; the voice task rechecks promptly (nudge) and does not stay in the wrong power-saving state until its backstop timeout. Same for the serial bench-battery command and its clearing on wake.
8. Power-off by long press: the caption shows the hold prompt, restores the old caption on early release, and on completion shows GOODBYE, mode OFF; a voice turn finishing during shutdown cannot flip the face back from OFF. Power-off failure returns to idle with the failure caption.
9. Serial console mode forcing: from any mode, including OFF, each key leads to the requested mode (the console steps via IDLE to leave OFF).
10. Rotation / page: the beam reply is paged to the 2-line, 16-column default or whatever the UI set; wrong geometry shows as clipped or very short pages.
11. Battery and charging indicators on the face and settings page match the board readings, including -1 percent on a battery-less board (no battery icon, never counted on battery).
12. 60 fps idle and the busy gates from the entity work still hold (this module must add no measurable cost: every getter is a few instructions).

## 7. Test vehicle

Host harness with plain gcc, built under `cleanroom/state/test/`, one test executable, no ESP-IDF.

Stubs to provide (a few lines each, written fresh):

1. `esp_timer_get_time()` returning a settable 64-bit microsecond counter, plus a function to advance it.
2. FreeRTOS shim headers for exactly the primitives your implementation uses, backed by pthreads (1 ms per tick).
3. `rabble_text.h` stub with `rabble_text_to_ascii` implemented minimally for the test (curly quotes U+2018/2019/201C/201D and dashes U+2013/2014 to ASCII, drop other non-ASCII, stop on overflow of `cap`), so the module's use of it can be checked. `strlcpy` supplied if the host libc lacks it.

Cases the implementation must pass:

1. Initial values: mode BOOT, level 0, progress 0, asleep false, `on_battery` false, power pct -1, page 16x2, cjk request still gives 16x2, happiness 0, caption read from version 0 returns false.
2. Mode: BOOT to IDLE changes and age restarts at the advanced clock; set same mode after 5 s keeps age at 5 s.
3. OFF rule: from IDLE set OFF; then set THINKING, LISTENING, SPEAKING, ERROR, BOOT all ignored (mode stays OFF, age unchanged); set OFF again no-op; set IDLE accepted and age restarts.
4. Mode NULL pointer form does not crash; secs form returns clock delta as float within 1e-3.
5. Level and progress clamp: -1 gives 0, 2 gives 1, 0.25 stays 0.25.
6. Caption: set "hello"; read at version 0 returns true, text "hello", version 1; read again false and out untouched (pre-fill out with a marker); set "hello" again leaves version 1; set "world" gives version 2 and an old observer (version 1) sees it; a second observer at version 0 also sees "world".
7. Caption empty-on-empty: set "" initially then read at version 0 returns false.
8. Caption truncation: set a 1000-character string via `"%s"`; stored length is 399; reading with a 10-byte out gives 9 characters plus NUL; a read with out_len 400 gives the full 399.
9. Caption format: `"%s %.1fs"` with "LISTENING", 1.25 formats as expected; `"%d"` works.
10. Caption ASCII conversion: input with U+201C, U+201D, U+2014 comes out as ASCII stand-ins; text of exactly 399 ASCII characters round trips.
11. Caption concurrency: two threads set alternating long captions 100000 times while a third reads; every string read is one of the two full strings (never a mix) and versions never go backwards except by wrap.
12. Page: `set_page(20,3)` then `page(false)` gives 20,3; `page(true)` gives 20,3 while the CJK page is unset; `set_cjk_page(10,5)` then `page(true)` gives 10,5 and `page(false)` still 20,3; `set_cjk_page(0,5)` returns to the normal page for CJK.
13. Power: set pct 80, usb false: `on_battery` true; set usb true: false; pct -1, usb false: false; `power()` returns exactly what was set. Override on with usb true: `on_battery` true. `set_as_if_battery(true)` twice nudges only once (observable with the wait test below).
14. Nudge on change: with the device asleep, a power set that flips `on_battery` makes a pending `wait_awake(1000)` return in well under 100 ms; a power set that does not flip it leaves `wait_awake(50)` to time out near 50 ms.
15. Sleep and wait: awake `wait_awake(1000)` returns in under 10 ms; after `set_asleep(true)`, `wait_awake(100)` takes about 100 ms (within 80 to 200); a second thread calling `set_asleep(false)` after 50 ms releases it at about 50 ms; `nudge()` alone releases it without `asleep()` changing; two nudges then one wait then another wait: first returns at once, second blocks until timeout; `wait_awake(0)` while asleep returns at once.
16. Wake pokes: advance the clock 30 s so `idle_secs` is about 30; `set_asleep(false)` brings it to about 0. `set_asleep(true)` does not reset it.
17. Poke: after advancing 10 s, `poke` makes `idle_secs` about 0; advancing 3 s makes it about 3.
18. Happiness: `make_happy` at t; `happiness` is 1.0 at t+0.5 s and t+1.19 s; about 0.5 at t+1.4 s; 0 at t+1.6 s and later; calling again at t+1.5 s restores 1.0; it pokes (idle about 0). Never negative nor above 1.
19. Struct and macro conformance: a compile-only unit that uses `char b[RABBLE_CAPTION_MAX]`, `rabble_power_t p = { .battery_pct = -1 }`, `(rabble_power_t){ .battery_pct = 1, .battery_mv = 2, .charging = true, .usb = false }`, an array `[RABBLE_MODE_COUNT]` indexed by designated enumerators, and checks `RABBLE_MODE_OFF == 6`, `RABBLE_MODE_COUNT == 7`, `RABBLE_CAPTION_MAX == 400` with static asserts; compiles the header under both C11 and as C++ if extern "C" guards were added.
20. Printf attribute: a negative compile check (optional) that a format mismatch warns.

Run under `-Wall -Wextra -Werror` and once under ThreadSanitizer for case 11 and case 15.

## 8. Ambiguities and decisions for the integrator

1. The checklist's 64-bit timestamp atomicity: left as a permitted improvement (3.1 rule 2).
2. `set_caption` before init is a fault in the original; the spec does not require preserving that.
3. Whether to keep the single-waiter limitation of `wait_awake`: kept, because the only waiter is the voice task.
4. `rabble_state_set_cjk_page` and `rabble_state_progress` have no callers today; they stay for source compatibility with future waves.
