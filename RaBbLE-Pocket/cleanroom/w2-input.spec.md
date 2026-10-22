# W2 spec: rabble_input (push-to-talk, aux button, sleep and power states, serial bench console)

> Clean-room spec, wave W2. Author role: S (Sonnet 5.5 sub-agent, S258). Firewall: S258 parent (Opus 5.5), approved after rewriting the edge-ordering step lists and the aux state variables as behaviour, removing a note about the original's internals and a verbatim call expression. File to be replaced: `apache/rabble_input.c/.h`. New files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Interface names are frozen. Companion specs this one leans on: `w0-seam.spec.md` (board vtable, button debounce), `w0-state.spec.md` (state module), `w1-console-setup.spec.md` (console read/write and the `key=value` setup commands), `w1-text.spec.md` (beam console line format, unescape). Golden vectors: `w2-input-vectors/` (section 12).

Treatment: clean room. Everything below is a requirement. Where a number is given it is a behaviour value; how you structure code, name helpers and split functions is yours.

---

## 1. Purpose

One module with two tasks. The **input task** polls the board's two buttons, turns them into push-to-talk events for the voice pipeline, owns the screen-asleep flag's lifecycle (aux button, idle timeout, wake sources), runs the power-saving ladder (display pause, CPU slow-down, Wi-Fi nap, power off), refreshes the battery reading, and performs the shutdown sequence. The **serial task** reads the USB console: single-letter bench keys that stand in for buttons and sleep, and `>` lines that carry console commands and setup commands.

Everything reaches hardware only through the board vtable. The module keeps no persistent data of its own.

## 2. Public interface (complete and frozen)

Header `rabble_input.h`, `#pragma once`. It must include `<stdbool.h>`, `"esp_err.h"`, `"freertos/FreeRTOS.h"`, `"freertos/queue.h"` (callers get `QueueHandle_t`, `esp_err_t` and `bool` through it). `extern "C"` guards allowed.

| Name | Kind | Contract |
|---|---|---|
| `RABBLE_PTT_DOWN`, `RABBLE_PTT_UP` | enum `rabble_ptt_t`, in this order (values 0, 1) | The two push-to-talk event kinds. |
| `rabble_input_event_t` | struct: `rabble_ptt_t type;` then `bool wake;` | One queue item. `wake` is true only on a DOWN that woke the screen (talk button pressed while asleep). Items are copied by value into the queue (`sizeof(rabble_input_event_t)`). |
| `esp_err_t rabble_input_start(QueueHandle_t queue)` | function | Remember `queue`, create the input task (fatal if it cannot be created: return `ESP_FAIL`), then create the serial task (failure ignored; the input still works). Returns `ESP_OK`. Called once, from `rabble_app_run`, after the UI and battery are up and before the voice pipeline starts. Must not block. |
| `void rabble_input_wake(const char *why)` | function | Wake the screen from any task. Same effect as any other wake (section 7.1), logged with `why`. A no-op when already awake. `why` is non-NULL. |
| `void rabble_input_request_power_off(void)` | function | Ask the input task to run the shutdown sequence (7.4). Returns immediately. Callable from any task; it only records the request, which the input task acts on within one input-loop pass. |

No other symbol is exported. Combined: 3 functions, 1 enum, 1 struct.

### 2.1 Callers (grep over `firmware/components` and `firmware/main`)

| Caller | Uses |
|---|---|
| `accord/rabble_app.c` | creates the queue (16 items of `rabble_input_event_t`) then `rabble_input_start(queue)`; passes the same queue to `rabble_voice_start`. |
| `apache/rabble_voice.c` (consumer; W4 replaces it) | reads `rabble_input_event_t` from the queue: `type` DOWN/UP and `wake`. The contract on events is section 5.4. |
| `accord/rabble_motion.c` | `rabble_input_wake("shake")` and `rabble_input_wake("raise")`, from the motion task (while asleep). |
| `apache/rabble_settings_ui.c` | `rabble_input_request_power_off()` from the LVGL task, when the user confirms Power off on the settings page (the page first returns to the face). |

`main/` does not call this module directly.

## 3. Tasks owned (requirements)

| Task | Name (visible in task lists) | Priority | Stack | Core | Period |
|---|---|---|---|---|---|
| input | `rabble_input` | 6 | 4096 bytes | unpinned (no core affinity) | one pass per 10 ms awake; 50 ms asleep with no wait-capable board; otherwise a button-interrupt wait (7.6). |
| serial | `rabble_serial` | 5 | 3584 bytes | unpinned | blocks on the console; no period. |

Created with the plain (non-caps) FreeRTOS creation call, so stacks live in internal RAM. The input task must be one priority above the serial task and equal to the voice task's; do not pin either to a core (the UI and voice own the pinned cores; see `rabble_mem.h`). If the console driver cannot be installed, the serial task deletes itself and nothing else changes.

Threading rules: only the input task reads buttons, runs the sleep ladder, and posts button-originated PTT events. The serial task posts bench PTT events and may change the asleep flag. Wake may come from any task. Requests that cross tasks (power off, bench nap) must be safe to raise from one task and observe from another.

## 4. What the module calls (seam and modules) and what it expects

| Callee | Calls | Expectation |
|---|---|---|
| board (`rabble_board`, `rabble_board_t`) | `poll_buttons()`, `wait_buttons(timeout_ms)` (may be NULL), `display_pause(bool)` (may be NULL), `read_power(rabble_power_t*)` (may be NULL), `power_off()`, `imu_read(float[3])` (may be NULL), fields `name`, `talk_button`, `aux_button` | `poll_buttons` returns edge flags `RABBLE_BTN_TALK_PRESS/RELEASE`, `AUX_PRESS/RELEASE` already debounced (talk) or latched (aux via the PMU); it can report press and release in the same call. `wait_buttons` returns early on a button change or a notification to the input task. `power_off` does not return on success. Button-name words (`talk_button`, `aux_button`) are used only as the reason text in logs. `aux_button` is NULL on boards with no aux button; this module must still work (aux handling idle). |
| state (`rabble_state_*`) | `asleep`, `set_asleep`, `mode`, `set_mode`, `set_progress`, `set_level`, `set_caption`, `caption`, `poke`, `idle_secs`, `on_battery`, `set_as_if_battery`, `set_power`, `make_happy` | `set_asleep(false)` pokes the idle clock itself; setting a mode other than IDLE after OFF is ignored (OFF is sticky). Setting asleep does not itself notify anything except waiters in the state module. |
| voice | `rabble_voice_request_chirp()`, `rabble_voice_resting()`, `rabble_voice_notes_waiting()` | `resting` is true when the voice task has put codecs and its own work to sleep; `notes_waiting` is true when an offline-recorded note awaits sending. |
| beam | `rabble_beam_text_turn(char *)` (takes ownership, frees), `rabble_beam_text_cancel()`, `rabble_beam_console(type, text, fields, ...)`, `rabble_beam_unescape(char *)` | See 9.4. `unescape` works in place and returns the new length. |
| settings | `rabble_settings_sleep_s()` (0 = never), `rabble_settings_power_off_s()` (0 = never) | Read on every sleep check (so changes apply live). |
| battery | `rabble_battery_note_power(const rabble_power_t*, bool on_battery)`, `rabble_battery_note_state(bool screen_off, bool resting)`, `rabble_battery_reset()`, `rabble_battery_saved_json()` (NULL if none), `rabble_battery_json(buf, cap)` | `note_state` is called every pass with the asleep flag and the "CPU slowed" flag. |
| setup | `rabble_setup_status_json(buf, cap)`, `rabble_setup_command(char *line)` | See W1 spec. |
| console | `rabble_console_install(rx)`, `rabble_console_getc(&c)`, `rabble_console_host()` | See W1 spec. |
| wifi | `rabble_wifi_connected()`, `rabble_wifi_apply()`, `rabble_wifi_nap(bool)` | `apply` means "try to connect now, skip the backoff"; `nap(true)` switches Wi-Fi off, `nap(false)` brings it back. |
| UI | `rabble_ui_dark()` | True when the screen has finished fading to black (nothing left to draw). |
| motion | `rabble_motion_up(float up[3])` | Fills `up` always; returns true when the vector is a smoothed live estimate. |
| mem | `RABBLE_BIG_CAPS` | Caps for the console line buffer and JSON buffers. |
| ESP-IDF | log, heap caps allocation, task notification (`xTaskNotifyGive`), `esp_pm_configure` when `CONFIG_PM_ENABLE` | Power management settings in 7.3. |

The module must tolerate being the only one that knows the asleep flag changes: after any change it makes, it must kick the input task out of a button wait (task notification), so the new state takes effect immediately.

---

## 5. Talk button: push-to-talk

### 5.1 Input

Each input pass receives an edge mask from the board. The talk button contributes two independent bits (press, release); both may be set in one pass, and a release may arrive just before the next press. Debouncing (30 ms awake, none for a press while asleep) is the board's, not this module's.

### 5.2 Rules

1. The module tracks one flag: "talk is held" (as far as it has told the voice pipeline).
2. A release while held: post UP (wake false), clear held.
3. A press while not held: post DOWN, set held. If the screen is asleep at that moment, first wake it (7.1, reason word is the board's `talk_button`), then post DOWN with `wake` true.
4. When one pass carries both bits, the result depends on the starting state. The table is the complete rule (it is behaviour, how you reach it is yours):

| Held before | Press | Release | Posted (in order) | Held after |
|---|---|---|---|---|
| no | no | no | nothing | no |
| no | yes | no | DOWN | yes |
| no | no | yes | nothing | no |
| no | yes | yes | DOWN, UP | no |
| yes | no | no | nothing | yes |
| yes | yes | no | nothing (duplicate press ignored) | yes |
| yes | no | yes | UP | no |
| yes | yes | yes | UP, DOWN | yes |

With the screen asleep, a DOWN is posted with `wake` true and the wake happens first, in every row that posts a DOWN while not held.

5. A talk event pass is logged at info level in the form `talk key: press`, `talk key: release`, or `talk key: press release` (only passes that carry a talk bit).
6. Posting never blocks. If the queue is full, the event is dropped (the log line is still written). Each post logs `PTT down` or `PTT up`, with ` (waking)` appended when `wake` is true.
7. Talk presses do not poke the idle clock here (the voice pipeline pokes when it acts on them). Do not add one.

### 5.3 Bench keys `d` and `u`

The serial keys `d` and `u` pose as the talk button: first poke the idle clock, then post DOWN (`d`) or UP (`u`) with `wake` false. They do not read or change the held flag of 5.2, do not wake the screen themselves, and are not de-duplicated: sending `d` twice posts two DOWNs.

### 5.4 Contract with the consumer (voice)

DOWN with `wake` true means "this press woke the screen": the voice task treats it as a tap and records only if the button is still down after a short qualifying hold. DOWN with `wake` false starts a recording turn as usual. UP ends one. The producer guarantees ordering within the queue and nothing else; the consumer already tolerates unmatched UPs and duplicate DOWNs.

---

## 6. Aux button (sleep click and power-off hold)

Absent when the board has no aux button (its events never arrive).

### 6.1 Edge ordering

Each pass yields at most a press edge and a release edge, in the order the table gives, or, when neither applies, one **hold tick** (a pass in which the button merely stays as it was). The table is the complete rule:

| Held before | Press | Release | Edges handled (in order) | Held after |
|---|---|---|---|---|
| no | no | no | hold tick (no effect, not held) | no |
| no | yes | no | press | yes |
| no | no | yes | hold tick (no effect) | no |
| no | yes | yes | press, release | no |
| yes | no | no | hold tick (counts) | yes |
| yes | yes | no | hold tick (duplicate press ignored) | yes |
| yes | no | yes | release | no |
| yes | yes | yes | release, press | yes |

(The last row therefore does a click action and then a new press. When the click put the screen to sleep, the new press wakes it. This is recorded behaviour, see vectors.)

### 6.2 Machine

Rules per press. "Consumed" means the press has already had its effect and its remaining hold and release do nothing. "Hint showing" means the early power-off warning is on screen. The caption that was showing before the hint must be restorable (up to 63 characters).

| Event | Condition | Action |
|---|---|---|
| press edge | screen asleep | wake the screen (reason: the board's `aux_button` word). This press is consumed: its hold and release do nothing. |
| press edge | screen awake | start a new hold: pass 0, no hint showing, not consumed. |
| hold tick (held) | consumed | nothing |
| hold tick (held) | not consumed | this is the next pass of the hold. On pass 60: remember the caption showing now, show `HOLD TO POWER OFF`. On pass 150: the press is consumed, run the shutdown sequence (7.4). |
| release edge | consumed | nothing |
| release edge | not consumed, hint showing | show the remembered caption again; no sleep. |
| release edge | not consumed, no hint | put the screen to sleep (reason: `aux_button` word). |

Counts are input-loop passes, not wall-clock: with the awake loop at 10 ms, the hint appears about 0.6 s after the press and power-off starts about 1.5 s after the press. The press edge pass counts as pass 0. Exact boundaries (verified in vectors): a release on pass 60 after the press still counts as a click (sleep); on pass 61 it cancels the hint. A release on pass 150 cancels (restores); shutdown starts on pass 150 when no release arrives on it.

Edge cases: a click shorter than the hint threshold sleeps however short. After the shutdown sequence returns (power-off failed), the held press stays consumed until released; the release does nothing. The next press works normally. A caption longer than 63 characters is restored truncated to 63.

---

## 7. Sleep, wake and power states

### 7.1 Asleep flag and wake sources

"Asleep" is the screen-off flag in the state module; the UI task reads it to dim the screen and the voice task rests when it is set. This module changes it through one rule:

**Change rule.** Requested value equals the current flag: do nothing at all (no log, no notification, no Wi-Fi action). Otherwise log `sleeping (WHY)` or `waking (WHY)` at info level, set the flag, notify the input task (so a button wait ends), and, only on a wake with Wi-Fi not connected, call `rabble_wifi_apply()` once.

Sleep sources (reason word): aux click (`aux_button` word), `auto-sleep`, `serial` (keys `z`, `>nap`). Wake sources: talk press while asleep (`talk_button` word, 5.2), aux press while asleep (`aux_button` word), serial `w` (`serial`), `rabble_input_wake` from other tasks (motion: `shake`, `raise`), and the UI touch path (which wakes through the state module directly, not through this module). Waking via state `set_asleep(false)` pokes the idle clock, so auto-sleep restarts from zero.

### 7.2 Idle auto-sleep and asleep-on-battery power-off

Checked every 100 ms by the input loop (and once on the first pass). Two independent rules, evaluated in this order:

| Rule | Condition | Effect |
|---|---|---|
| Power off after sleeping on battery | the screen is asleep, **and** the device is on battery (state's `on_battery`, which includes the bench override), **and** talk is not held, **and** the settings value `power_off_s` is non-zero, **and** that combination has held continuously for at least `power_off_s` seconds | log `asleep on battery for N s: power off` (N = the setting), restart the timer, call board `power_off()` directly (no goodbye animation). If it returns (failure), log at error level `power-off failed (<esp error name>)` and skip the auto-sleep rule this pass. |
| Auto-sleep | `sleep_s` is non-zero, the screen is awake, the mode is exactly IDLE (not boot, listening, thinking, speaking, error or off) and `idle_secs` is **strictly greater** than `sleep_s` | put the screen to sleep, reason `auto-sleep`. |

The power-off timer restarts (to "now") on any pass where the screen is awake, or not on battery, or talk is held. The timer is checked against both its start and the live setting value, so lowering the setting applies at once. Vectors: `sleep.tsv`.

### 7.3 Display pause and CPU slow-down (the "rest" state)

Evaluated every pass. **Pause** is wanted when all of these hold: the board provides `display_pause`; the device is on battery; the screen is asleep; the UI reports dark; the voice task reports resting. **Slow CPU** is wanted when a pause is wanted and no USB host is attached (`rabble_console_host()` false).

Three stable outcomes (the "power mode"): full power; paused with CPU slowed ("low power"); paused with CPU at full speed ("USB host"). The module remembers the last outcome and acts only on a change of either component:

| Change | Order of actions |
|---|---|
| start pausing | call `display_pause(true)`, then adjust the CPU if it changed |
| stop pausing | adjust the CPU if it changed, then call `display_pause(false)` |
| CPU only (host attached/detached while paused) | adjust the CPU only |

After any change log one line: `low power: display paused`, or `display paused (USB host: CPU at full speed)`, or `full power`. The input pass returns "paused" for the later steps. All 192 transitions are in `power.tsv`.

CPU adjustment (only when `CONFIG_PM_ENABLE`; otherwise a no-op): maximum frequency = the build's default CPU frequency; minimum frequency = the crystal frequency when slowing, else the default; automatic light sleep enabled exactly when slowing. A failure logs a warning `power management: <esp error name>` and carries on. Rationale: with a host attached, slowing to crystal speed can stall a long USB serial burst, so the host keeps the CPU fast.

### 7.4 Shutdown sequence

Triggered by the aux hold (6.2), by `rabble_input_request_power_off()`, from the input task. Steps in this order:

1. Log `shutting down`.
2. Clear the asleep flag directly in state (no Wi-Fi reconnect, no input notification).
3. Re-evaluate the display pause (7.3) so the screen is un-paused before the animation.
4. Set progress 0, level 0, mode OFF, caption `GOODBYE!`.
5. Wait 1500 ms (the goodbye animation).
6. Call board `power_off()`.
7. Only if it returns: wait 500 ms, log error `power-off failed (<esp error name>)`, set mode IDLE (the only mode that leaves OFF), caption `COULDN'T POWER OFF`.

A request counts once: a request made while the sequence is already running (during step 5) is honoured again after a failure. Vectors: `btn.tsv`.

### 7.5 Wi-Fi nap

Evaluated every pass, after 7.3. **Nap** is wanted when the module is paused (7.3) **and** no offline voice note is waiting (`rabble_voice_notes_waiting()` false) **and** either the bench nap request is set, or the CPU has been slowed continuously for 2 minutes (120,000 ms; the timer restarts whenever the CPU is not slowed). On a change of the nap decision log `Wi-Fi napping` or `Wi-Fi waking` and call `rabble_wifi_nap(true|false)`. Also: if the screen is awake while the bench request is set, clear the request and clear the state's battery override. The pass returns "napping" for the loop wait. While napping nothing reaches the device over the network; wake (any source) brings Wi-Fi back through 7.1 and 7.3. Nap ends also when pause ends or a voice note becomes waiting. Vectors: `nap.tsv`.

### 7.6 Loop cadence and waits (one pass of the input task, in order)

1. Poll buttons: talk handling (5), aux handling (6).
2. If a power-off was requested: clear the request, run 7.4.
3. Every 100 ms (first pass included): the sleep checks of 7.2.
4. Battery refresh: every 2 s awake, every 10 s while paused (first pass included): call board `read_power` if present, on success store the reading in state and pass it to the battery module together with the current on-battery value. The reading starts with battery percent -1 (unknown) before the call.
5. Power mode (7.3), then Wi-Fi nap (7.5).
6. Tell the battery module the asleep flag and the CPU-slowed flag.
7. Wait: if paused and the board has `wait_buttons`: wait up to 10 s while napping, 1 s otherwise (a button, or a notification from a change of the asleep flag, ends the wait early); otherwise sleep 50 ms when paused, 10 ms when not.

The long waits are why every state change must notify the input task, and why a USB-power arrival while napping is noticed within 10 s.

---

## 8. Serial task and key protocol

The serial task installs the console with a 1024-byte receive buffer, then reads one byte at a time forever. Anything not listed is ignored silently, including `\n`, `\r`, space and unknown letters.

| Byte | Action |
|---|---|
| `d` | Poke the idle clock, post PTT DOWN (wake false). 5.3. |
| `u` | Poke the idle clock, post PTT UP (wake false). 5.3. |
| `c` | Ask the voice task to play a chirp (`rabble_voice_request_chirp`). Voice decides when (only when idle). No output from this module. |
| `z` | Put the screen to sleep, reason `serial` (7.1). Does not touch the battery override. On USB power the screen sleeps but display pause does not start (7.3 needs on-battery). |
| `w` | Wake the screen, reason `serial`. (This also ends a bench nap.) |
| `>` | Read the rest of the line as a command line (section 9). |

Bench keys act at once and are not echoed by this module.

---

## 9. Command lines (`>` lines)

### 9.1 Line reading

After the `>`, read bytes until `\n`. Skip every `\r`. Keep at most 1023 characters; further characters up to the newline are dropped and the line is marked "too long" (but still executed truncated, unless it is a chat line, 9.4). The line buffer is 1024 bytes taken from `RABBLE_BIG_CAPS` memory per line and freed after; if it cannot be allocated the line is still read to its newline and dropped, with no reply. Reading blocks until the newline arrives (a partial line holds the serial task).

### 9.2 Dispatch

The text is matched exactly (case-sensitive, no trimming) against the console-only commands below; a line that no console command claims goes to `rabble_setup_command(line)` unchanged (W1 spec). Claimed first, in this order: `status`, `power.reset`, `power`, `nap`, `imu`, anything starting `face=`, then the chat family. A line starting with `chat` that is not `chat.cancel`, `chat=...` or `chat+=...` (for example `chatty`) falls through to setup.

### 9.3 Console-only commands and their exact output

All replies go to standard output as single lines starting with `@`, followed by a newline, flushed.

| Line | Reply |
|---|---|
| `status` | `@status {"board":"<board name>","chat":true,"device":<json>}` where `<json>` is the object from `rabble_setup_status_json` (buffer 1024 bytes, enough for long SSID/URL escaped). If the buffer cannot be allocated, print nothing. |
| `power` | If the battery module has a saved record: first `@power.saved <json>`. Then always `@power <json>` from `rabble_battery_json` (buffer 2048 bytes). If that buffer cannot be allocated, only the saved line is printed. |
| `power.reset` | Calls `rabble_battery_reset()` first, then prints exactly as `power` (so the saved line, if any, reflects the reset). |
| `nap` | No reply. Sets the state's battery override on, puts the screen to sleep (reason `serial`), and sets the bench nap request (7.5). The device then follows the normal ladder: pause when dark and voice resting, then Wi-Fi nap at once. Undo: `w`. |
| `imu` | If the board has `imu_read` and it returns ok: `@imu {"accel":[x,y,z],"bias":[x,y],"up":[x,y,z],"smoothed":true\|false}` with `accel` and `bias` (`rabble_motion_bias`, added S264) at 3 decimals, `up` at 2 decimals (`up` from `rabble_motion_up`, `smoothed` its return value). Otherwise `@imu {"error":"no IMU"}`. |
| `face=NAME` | See below. |
| `chat...` | See 9.4. |

`face=NAME`: poke the idle clock; NAME is one of `boot idle listening thinking speaking error off happy`. For `happy`: treat as `idle` and then start the happy reaction. For any valid name: first set mode IDLE (so OFF can be left), then set the named mode, then (happy only) call `rabble_state_make_happy()`. No reply on success. The face stays until the voice path or another `face=` changes it. For an unknown name print `@face.error unknown face "<NAME>": boot idle listening thinking speaking error off happy` (NAME as typed after `face=`, quote characters included, but for `happy` aliasing the message is never reached). `face=` with an empty name is unknown.

### 9.4 Chat family (typed messages to sCoRE)

A typed message is assembled across lines in a 192 KiB (196,608-byte) buffer in PSRAM (`MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT`), created on the first chat line and freed on send, error or cancel.

| Line | Behaviour |
|---|---|
| `chat+=TEXT` | Unescape `TEXT` in place (`\n`, `\r`, `\t`, `\\` via `rabble_beam_unescape`), append it, reply with the ack. |
| `chat=TEXT` | Same as `chat+=` but, after the ack, hand the whole message to `rabble_beam_text_turn` (which takes ownership and frees it) and forget it. |
| `chat.cancel` | Free any partial message and call `rabble_beam_text_cancel()` (ends a typed turn). No reply from this module. |

The ack is printed through `rabble_beam_console` as type `ack` with no text and one extra field `bytes` (the total length so far): `@chat {"seq":N,"type":"ack","bytes":<total>}`; the exact line format and the sequence counter are the beam console's (W1 vectors `beam-console.tsv`). Errors go through `rabble_beam_console` as type `error` with the text below and no extra fields, which prints `@chat {"seq":N,"type":"error","text":"<text>"}`. In every error case the partial message is discarded and the next `chat+=` starts a new one. Error checks, in this order, the first that applies wins:

| Condition | `text` |
|---|---|
| the line was too long (9.1) | `LINE TOO LONG` |
| the 192 KiB buffer could not be allocated | `OUT OF MEMORY` |
| appending would reach or pass the buffer size (length so far + new length >= 196,608) | `TOO LONG` |

The unescape runs before these checks. Protocol note for hosts: the console driver drops what does not fit its receive buffer, so the host must wait for each ack before sending the next line; a line longer than 1023 characters is an error rather than being split.

---

## 10. Limits and edge cases (collected)

| Item | Value |
|---|---|
| PTT queue | owned by the app: 16 items; sends never block; drops when full |
| Input pass | 10 ms awake; 50 ms paused with no `wait_buttons`; waits 1 s paused, 10 s napping with `wait_buttons` |
| Sleep check period | 100 ms |
| Battery refresh | 2 s awake, 10 s paused |
| Aux hint / power-off | pass 60 / pass 150 after the press (about 0.6 s / 1.5 s) |
| Goodbye delay / failure delay | 1500 ms / 500 ms |
| Wi-Fi nap | after 120,000 ms of CPU slowed (bench: at once) |
| Console line | 1023 characters kept; buffer 1024 |
| Chat message | 196,608 bytes (192 KiB) |
| Saved caption | 63 characters |
| Task stack / priority | input 4096 B / 6; serial 3584 B / 5 |
| Tick arithmetic | all timers are unsigned tick differences; they survive the tick counter wrapping |

Edge cases to preserve: a board with no `display_pause` never pauses (and so never slows the CPU or naps by timer; the bench nap needs pause too); a board with no `read_power` never refreshes power; a board with no aux button needs no aux handling; the shutdown steps are reachable while paused (the request flag is read once per pass; while paused the pass may wait up to 10 s, but the settings page that requests shutdown wakes the screen first); keys `d`/`u` while a physical talk press is held are not merged; the module is safe when `rabble_wifi_*` shows Wi-Fi disconnected for any reason.

---

## 11. Device behaviour checklist (integrator)

Log text references are exact. "Serial" checks can be run by an agent over `/dev/ttyACM0` (115200 or any, USB CDC); "hands" checks need Mark. Run serial checks on USB power unless said otherwise.

### 11.1 Serial-only

1. Boot log contains no `rabble_input` error lines; `>status` returns `@status {"board":"Waveshare ESP32-S3-Touch-AMOLED-1.75-B","chat":true,"device":{...}}` on one line.
2. `>power` prints `@power {...}` (and `@power.saved` when a saved record exists); `>power.reset` then `>power` shows a reset meter.
3. `>imu` prints `@imu {"accel":[...],"up":[...],"smoothed":...}` with three and two decimals; with the IMU unplugged or failing, `@imu {"error":"no IMU"}`.
4. `>face=thinking`, `>face=off`, `>face=idle`, `>face=happy` each take effect on the screen (video or photo; screenshot optional) with no reply; `>face=bogus` prints `@face.error unknown face "bogus": boot idle listening thinking speaking error off happy`. `>face=listening` from `off` works (OFF is left via IDLE).
5. `d` then `u` (two bytes) produce log lines `PTT down` and `PTT up`, and the voice path starts and ends a recording (listening mode and a turn start). `d` twice logs two `PTT down`.
6. `c` makes the gadget chirp (audible, or `@`-less log from voice).
7. `z` logs `sleeping (serial)` and the screen goes dark; a second `z` logs nothing; `w` logs `waking (serial)` and lights it; if Wi-Fi was disconnected a reconnect is attempted immediately.
8. `>nap` (needs a battery present): logs `sleeping (serial)`, after a few seconds `low power: display paused` or, with the USB cable carrying the console, `display paused (USB host: CPU at full speed)`, then `Wi-Fi napping`; `w` logs `waking (serial)`, `full power`, `Wi-Fi waking`. After the wake `>power` shows the on-battery override cleared (no longer forced).
9. Chat: `>chat+=hello\n` returns `@chat {"seq":N,"type":"ack","bytes":6}` (the `\n` escape counts as one byte); `>chat=world` returns an ack with bytes 11 and starts a typed turn; with sCoRE reachable the reply streams as `@chat` lines. `>chat.cancel` aborts.
10. Chat errors: a `>chat+=` line of more than 1023 characters returns `LINE TOO LONG` and the next `chat+=` restarts from 0 bytes; sending `>chat+=` lines until the total reaches 196,608 bytes returns `TOO LONG`.
11. An unclaimed line goes to setup: `>chatty` and any `key=value` setup line behave as in the W1 checklist; unknown bytes (`x`, `\n`) produce no output.
12. `rabble_input_request_power_off` path: from the settings UI (hands) or, as a bench substitute, not available over serial (record that).
13. Leave the device idle on USB power, awake, with `sleep_s` set small (settings): the screen sleeps after `sleep_s` seconds of no activity and logs `sleeping (auto-sleep)`; it does not start `low power` (USB present).
14. Task list (if available) shows `rabble_input` and `rabble_serial`.

### 11.2 Needs Mark's hands

1. Talk button (BOOT): tap awake logs `talk key: press`, `PTT down`, then `talk key: release`, `PTT up`; hold records and releases ends it; a rapid tap causes at most one down/up pair.
2. Talk press while asleep: screen wakes, log shows `waking (boot)` and `PTT down (waking)`; a tap only wakes (no recording); holding through the wake records a note.
3. Aux (PWR) click awake: screen sleeps (`sleeping (pwr)`); press while asleep wakes (`waking (pwr)`) and its release does nothing.
4. Aux hold: at about 0.6 s the caption becomes `HOLD TO POWER OFF`; release before 1.5 s restores the previous caption and does not sleep; hold past 1.5 s: `shutting down`, goodbye animation, power off. Failure path (only if provoked): `power-off failed`, caption `COULDN'T POWER OFF`, mode idle.
5. Settings page Power off confirm: returns to the face, plays the goodbye, powers off.
6. On battery, no USB: auto-sleep after the configured idle time; after a further `power_off_s` seconds asleep the device powers off with no animation (setting 0 = never). Waking before that restarts the wait; holding talk (a recording) also restarts it.
7. On battery, asleep with the face dark and voice resting: `low power: display paused` appears; plugging in USB returns to `full power` (display resumes only if it was paused; it stays asleep until a wake). With the console connected from a computer the CPU is not slowed (`display paused (USB host...)`).
8. After 2 minutes in low power: `Wi-Fi napping`; wake by touch/button/raise/shake: `Wi-Fi waking` and Wi-Fi rejoins promptly. While an offline voice note waits to send, Wi-Fi does not nap.
9. Raise-to-wake and shake wake from sleep (log `waking (raise)` / `waking (shake)`).
10. Battery meter keeps updating while paused (slower), visible in `>power` after wake.
11. No input lost when waking from low power: the first press wakes and posts `PTT down (waking)`; the first aux press wakes.

---

## 12. Test vehicle and golden vectors

The logic worth pinning is pure and is in `w2-input-vectors/`: button handling over polled events (`btn.tsv`), the sleep and power-off timers (`sleep.tsv`), the display-pause and CPU-slow decision (`power.tsv`), and the Wi-Fi nap decision (`nap.tsv`). `README.md` there explains format, actions vocabulary and compare rules. The implementer builds a **host test vehicle** (compile the module's decision code against stub state and board in a plain C test, or expose the decision functions behind the module's own test hooks) that replays the vectors and logs the actions in the README vocabulary, then runs it. All four files must pass byte for byte. Serial parsing (9) and the line formats are not in the vectors; they are covered by the checklist and by reusing the beam console and unescape W1 test data (`w1-text-vectors`).

---

## 13. Ambiguities and decisions for the integrator

1. **Hold counted in passes, not milliseconds.** The hint/power-off thresholds count loop passes (about 10 ms each when awake), so a slow pass lengthens the hold. Kept as is; vectors pin passes. An implementer may count time if the two thresholds stay 0.6 s and 1.5 s within a pass of tolerance, but the boundary vectors would then not match; do not.
2. **`d`/`u` and the held flag.** The serial keys do not track the held flag and do not wake a sleeping screen. Left as is. Whether waking should be added is Mark's call.
3. **`z` on USB power.** The screen sleeps but there is no display pause or CPU slow-down. Intended.
4. **`>imu` before smoothing.** `up` prints whatever the motion module holds (zeros or its default) with `smoothed` false.
5. **Aux release then press in one pass** does click-sleep then immediate wake. Recorded behaviour; probably unintended but harmless.
6. **Board power-off in the asleep timer** has no goodbye and no state changes; the screen is already dark.
7. **A failed power-off retries** after another `power_off_s` seconds (timer restarted), not immediately.
8. **`status` JSON contents** are W1's (`rabble_setup_status_json`); this module only wraps it.
9. **Log text** other than the strings quoted in this spec (for example the log tag name `rabble_input`, which the log lines show as a prefix) is free to differ, but keep the quoted ones: the checklist greps them.
