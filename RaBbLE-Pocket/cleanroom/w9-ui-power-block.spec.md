# W9 spec: rabble_screen (screen sleep, brightness, black cover, touch-wake)

> Clean-room spec, wave W9, revision 4 (revision 3 plus Mark's 2026-11-04 ruling that a drag is never a tap). Author role: S (Sonnet 5.5 sub-agent, 2026-11-03). Revision 3 folds in Mark's 2026-11-04 changes (SDK location, double-tap wake, preview ignored while dark, no automatic preview clearing) and the firewall pass of 2026-11-04 (QuiBbLE as F, approve-with-edits, all applied; report `/tmp/rabble-crew/firewall-w9.md`). G = the integrator. The module replaces the screen sleep / brightness / touch-wake part of the UI file `firmware/app/RaBbLE/rabble_ui.c`; what the integrator removes from the implementer's workspace copy is in section 10. The new module is generic SDK code (Mark, 2026-11-04: lifecycle half of the UI split goes to the SDK). It lives in its own SDK component `firmware/sdk/rabble_screen/` (own CMakeLists) as `rabble_screen.c/.h`. The component requires `rabble_core` (board, state, settings and memory headers) and LVGL via the LVGL-port component; it may depend on `rabble_power` later, and `rabble_power` never depends on it. Every file starts with exactly these two lines and nothing else: `/* Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord. */` then `/* Open-transition: Apache-2.0 (planned flip; see Pocket-Foundling-Open-App-Plan.md) */` (the open core is in transition to Apache-2.0; Mark, 2026-11-04). Interface names are frozen. Companion specs (copied into the workspace by the integrator): `w0-seam.spec.md` (board vtable), `w0-state.spec.md` (state module), `w2-input.spec.md` (idle timer and power ladder), `w3-settings.spec.md` (brightness setting). Where those say the screen "fades" to black, read "goes black at once": this module has no fade.

Treatment: clean room. Everything below is a requirement. Numbers are behaviour values; naming, structure, helper split and comments are yours.

---

## 1. Purpose

Make the physical screen follow one fact: the shared **asleep** flag (state module). While asleep the screen is black and the panel is in its low-power state; while awake it shows the UI at the user's brightness. A full-screen black **cover** sits above every LVGL screen while dark so a touch cannot reach anything underneath, and a touch on the cover wakes the device. The module also lets the settings UI preview a brightness without saving it, and tells other modules whether the screen is dark.

It does **not** decide when to sleep. The idle timeout, button and motion wakes, the power ladder (display pause, CPU slow-down, Wi-Fi nap, power off) and the idle clock belong to `rabble_input` and the state module. There is no dimming stage and no brightness ramp today; none is added (section 6).

## 2. Public interface (frozen)

Header `rabble_screen.h`, `#pragma once`, includes `<stdbool.h>` and `"lvgl.h"`. `extern "C"` guards allowed.

| Name | Contract |
|---|---|
| `void rabble_screen_init(void)` | Create the cover (3.1). Once, on the LVGL task with the display lock held, after all screens exist and before the first frame. Does not touch any input device. |
| `void rabble_screen_attach_touch(lv_indev_t *indev)` | The only place a touch device is hooked. `indev` may be NULL (nothing happens; 3.5 is then lost). Registers a press listener that calls `rabble_state_poke()` (3.5). Called after `init`. |
| `bool rabble_screen_step(bool lit_ok)` | Per-frame step, LVGL task only, once per UI frame before rendering. `lit_ok` is the UI's statement that enough frames have been drawn for the panel to be lit (the UI owns that counter; it currently waits 3 frames after boot). Applies pending sleep/wake transitions (section 3) and the brightness target (section 5). Returns `true` while dark; the caller then skips rendering for the frame. |
| `bool rabble_screen_dark(void)` | Any task. See invariant D1. |
| `bool rabble_screen_cover_visible(void)` | LVGL task. True while the cover is shown: dark, or a waking touch still down. |
| `void rabble_screen_preview_brightness(int pct)` | LVGL task. While awake, applies `pct` now and holds it as the target until ended; ignored while dark (5.3). `pct` is applied as given (callers pass 10..100). |
| `void rabble_screen_preview_brightness_end(void)` | LVGL task. Always clears any recorded preview; if awake, the saved setting is applied at once; while dark, no board call (the saved setting applies on wake by 5.1). |

`rabble_ui_dark()`, `rabble_ui_preview_brightness()` and `rabble_ui_preview_brightness_end()` stay in `rabble_ui.h` as one-line wrappers over the three functions above (the integrator writes them; section 10). Preview callers today: the Orbit's settings logic and the optional open-entity settings, through the UI's ops table; they run on the LVGL task.

## 3. Behaviour

### 3.1 The cover

One object, the size of the screen (100% by 100%), plain black, no border, no padding, not scrollable, clickable, on LVGL's topmost layer so it covers every screen including the Orbit, clock and levelling screens. Created hidden. While shown it receives all pointer events (press, release, press-lost).

### 3.2 Transition to dark

When `step` first sees asleep true while the screen is not dark, it must reach a state satisfying these rules. Only these orderings are required; anything not listed is free.

- **D1.** `rabble_screen_dark()` never reads true until the panel has been set to brightness 0 and, if the board has `panel_sleep`, `panel_sleep(true)` has been called. Reason: the power ladder pauses the display refresh once it sees dark, and pausing a lit panel freezes a lit image.
- **D2.** Brightness 0 is applied at or before `panel_sleep(true)`. Reason: boards with no `panel_sleep` rely on brightness alone, and a lit panel must not be left on during panel sleep-in.
- **D3.** The cover is shown by the time `step` returns. It is not drawn on this frame (the caller skips rendering), so what matters is that the next touch hits it.
- **D4.** `step` returns true on the transition frame itself. It must not return false to "draw the cover first": the caller does work on any true return (closes the Orbit, deactivates the entity) which must happen on this frame.

### 3.3 Transition to awake

When `step` first sees asleep false while dark:

- **W1.** `panel_sleep(false)` (if present) is called before any non-zero brightness is applied.
- **W2.** `rabble_screen_dark()` reads false from the end of this step at the latest.
- **W3.** The cover is hidden at the end of this step **unless a finger is down on it** (it is in the pressed state); then it stays shown and hides on release (3.4). Reason: the waking touch must not land on a control underneath.
- **W4.** Waking does not light the panel by itself. Brightness comes back through 5.1, so if `lit_ok` is false on the wake step, no brightness is applied in that step.

### 3.4 Cover events

- **Wake gesture: an intentional double tap** (Mark, 2026-11-04: a single touch, a drag or a hold must not wake, so pocket contact does nothing). While dark, a **tap** is a press that is released on the cover within `TAP_MAX_MS` of its press and never moved more than `TAP_SLOP_PX` from its press point. A tap is counted at its release. A press that is held longer, moves farther, or ends in press-lost (a drag, a hold, a brush) is **not** a tap, and it also clears the count: only two clean taps in a row wake. The second tap counts when its press arrives within `WAKE_TAP_WINDOW_MS` of the first tap's release and within `WAKE_TAP_RADIUS_PX` of the first tap's press point; otherwise it becomes the new first tap. On the second tap's release call `rabble_state_set_asleep(false)` (which also pokes the idle clock) and reset the count. Wake effects happen on the next `step`. Distance is straight-line; time is any monotonic millisecond clock the host test can control. Tuning values, defaults, refined by the hardware test: tap count 2 (allowed 1..2; 1 means a single clean tap wakes, still never a drag or hold), `TAP_MAX_MS` 300 (range 100..1000), `TAP_SLOP_PX` 20 (range 5..100), window 500 ms (range 100..2000), radius 60 px (range 10..233). They are five int Kconfig options in a new `Kconfig` in the component directory (symbol names yours, `CONFIG_RABBLE_` prefix).
- A lone tap, a drag, a hold or a press-lost on the cover while dark does nothing to the device: no wake, no poke of the idle clock (a stray touch must not hold off the power ladder), no board call.
- Release or press-lost on the cover while **not** dark: hide the cover.
- Anything else (release while dark, press while not dark): ignore.

### 3.5 Touch pokes the idle clock

Every press while not dark pokes the idle clock. Presses while dark poke only through a completed wake (3.4). Release and drag do not.

## 4. Edge cases

1. Asleep set and cleared again between two steps: no transition happens, nothing flickers.
2. Wake by button while a finger already rests on the cover: it hides on that finger's release.
3. Wake by double tap: the wake is requested at the second tap's release, so by the next step the finger is already up and the cover hides at once; the first interactive touch is the next press.
4. Board lacks `panel_sleep` (NULL): skip those calls; everything else holds. `set_brightness` is always present.
5. While dark, `step` does no LVGL object work after the transition frame.

## 5. Brightness

1. **Target while awake.** When `lit_ok` is true and the screen is not dark, the target is the saved setting (`rabble_settings_brightness()`, 10 to 100, pinned by the settings module) unless a preview is active. While `lit_ok` is false, `step` applies nothing.
2. **Applying.** The board's `set_brightness(pct)` is called only when the requested value differs from the last value this module applied; the very first request always goes through. Never the same value twice in a row.
3. **Preview.** `preview(pct)` applies `pct` immediately and makes it the target; this holds even if `lit_ok` is false (a preview before the first lit frame is not a case that arises in practice; if it does, it applies at once; test 10 does not pin it). `preview_end` always clears any recorded preview and applies the saved setting at once when awake; while dark it makes no board call. **No setting is reachable while dark (invariant).** `preview(pct)` while dark is ignored: no board call, brightness stays 0 and the preview is not recorded. The cover is what enforces this for users; the ignore rule makes it hold for any caller, including the open-entity panel's slider. On wake the saved setting applies by 5.1. There is no automatic clearing of a preview: only `preview_end` ends it.
4. Brightness changes are instantaneous steps. No fade, no easing.

## 6. Not in scope

- No dim-before-sleep stage and no fade-in/out. A dim stage would be a new feature and would need a "dim now" signal from the idle timer, which does not exist.
- No lid or hall-sensor sensing: "cover" is a software overlay.
- No motion or button handling (they arrive only through the asleep flag).
- `display_pause` (the power ladder's refresh pause) belongs to `rabble_input`, keyed on `rabble_screen_dark()`. This module never calls it.

## 7. Interaction with the rest of the system

| Counterpart | Direction | Notes |
|---|---|---|
| `rabble_state_asleep()` | read each step | The one source of truth. |
| `rabble_state_set_asleep(false)` | write, on a completed double tap on the cover | |
| `rabble_state_poke()` | write, on every touch press except those on the dark cover | |
| `rabble_settings_brightness()` | read each awake lit step | Applies live. |
| Board `set_brightness`, `panel_sleep` | write | LVGL task only. |
| `rabble_input` | reads `rabble_ui_dark()` | While dark it may pause the display and slow the CPU; D1 is what makes that safe. On wake, dark goes false before the input task lifts the pause, so the first lit frame may lag by one frame. |
| UI gestures, tap-talk, Orbit hit-tests | read `dark()` and `cover_visible()` | Ignore input while dark or the cover is shown. |

### 7.1 Threading and priority

No task and no timer is created. `init`, `attach_touch`, `step`, `cover_visible`, `preview_*` and the cover/touch callbacks run on the LVGL task (`RABBLE_UI_CORE`, `RABBLE_UI_PRIORITY`, see `rabble_mem.h`) with the display lock held. `dark()` is callable from any task and must never be torn. The module takes no mutex and never blocks.

### 7.2 Internal RAM

No stack, no buffer, no per-frame allocation, no growth after `init`. Total static data under 64 bytes plus one LVGL object. Representation is yours.

## 8. Behaviour checklist (integrator, on the gadget)

1. Boot: the panel lights after the first few frames at the saved brightness; no flash or garbage.
2. Idle timeout: screen goes black and the panel sleeps. Double tap wakes it (a single touch, a drag or a hold, as in a pocket, does nothing); the face is shown, the waking touch did not open the Orbit, tap-talk or any control; release hides the cover; the next touch interacts.
3. Talk or aux button while asleep: wakes, cover gone at once.
4. Shake or raise while asleep: wakes.
5. Settings brightness: dragging changes live; leaving without confirming restores the old value; confirming keeps the new one.
6. Touching a lit screen restarts the sleep countdown.
7. A counting test board shows one `set_brightness` per real change.
8. Ten minutes asleep on battery and on USB: current draw as before the swap.

## 9. Test plan (host)

Vehicle: `cleanroom/w9-screen/test_host/`, compiling `rabble_screen.c` with stubs; a small fake LVGL exposing object create, hidden flag add/remove, pressed-state query, add-event-callback and event injection, the active input's press point, a settable tick, the top layer, and no-op style/size/flag setters (its flag storage must be safe to read from a second thread for test 13).

Stubs: board with counters, a global call log, and last values for `set_brightness` and `panel_sleep` (plus a variant with `panel_sleep` NULL); state (`asleep`, `set_asleep`, `poke`) with counters; settings brightness settable.

1. Boot, `lit_ok` false for N steps: no `set_brightness`; first `lit_ok` step: one call with the setting; later steps none.
2. Setting changes while awake: one call per change, none on unchanged steps.
3. Asleep set, then `step`: in the call log, `set_brightness(0)` precedes `panel_sleep(true)` (when present); both precede any observation of `dark()==true` (sample `dark()` from a callback inside each stub); `cover_visible()` is true when `step` returns; `step` returned true on this very call. Later steps: no more board calls.
4. Double tap on the cover while dark (two clean taps inside the window and radius): `set_asleep(false)` once, at the second release; no call and no poke on the first tap or at either press. Next step: `dark()` false; `panel_sleep(false)` precedes the first non-zero `set_brightness` in the log; cover hidden if not pressed.
5. Same with the cover reported pressed: cover stays visible after the wake step; a release hides it; press-lost hides it.
6. While dark: a lone tap does nothing (no `set_asleep`, no poke). A press held past `TAP_MAX_MS`, a press that moves past `TAP_SLOP_PX` (a drag), and a press-lost are not taps and clear the count: tap, drag, tap does not wake; tap, hold, tap does not wake; two drags do not wake. Two taps outside the window, or farther apart than the radius: no wake; the second becomes the new first tap, and a third clean tap inside the window then wakes. Release while dark with no press: ignored.
7. Asleep set then cleared before any step: zero board calls.
8. `lit_ok` false on the wake step: `panel_sleep(false)` is called, no `set_brightness`; the next step with `lit_ok` true applies the setting.
9. `cover_visible()`: false at boot; true after the dark step; false after wake (finger up); true after wake with finger down; false after that finger's release.
10. Preview: `preview(80)` applies 80 now; steps keep 80 while the setting is 40; `preview_end` applies 40 once; a second `preview_end` with nothing changed does not repeat the call unless the value differs.
11. Same value twice never produces two consecutive `set_brightness` calls (including preview 80 then 80).
12. `panel_sleep` NULL: tests 3 and 4 complete.
13. `dark()` sampled from a second thread during transitions: never true before `set_brightness(0)` has been issued.
14. Touch device attached: each press pokes once while awake; release and drag do not; `attach_touch(NULL)` is harmless.
15. `preview(80)` while dark: no `set_brightness` call, and after waking the saved setting is applied, not 80. `preview_end` while dark: no call.
16. `WAKE_TAP_COUNT` 1: a single clean tap wakes; a drag or hold still does not. The tap count resets on wake and on going dark.
17. `preview(80)` while awake, go dark, `preview_end`, wake: the saved value applies, not 80.

## 10. Workspace preparation (integrator) and reading lists

The integrator hands the implementer a copy of the UI file and header in which all of the following are removed or rewritten. This is a requirement on the workspace, so that it still compiles without the original block (line numbers are in the current `rabble_ui.c` / `rabble_ui.h`):

| Where | Becomes |
|---|---|
| the original sleep, brightness and touch-wake code and its state, in `rabble_ui.c` (lines 80, 89-91, 528-593) | deleted; `bool rabble_ui_dark(void){ return rabble_screen_dark(); }` added by G |
| `rabble_ui.c` 813-816 (cover creation) | `rabble_screen_init();` |
| `rabble_ui.c` 820 (press listener on the touch device) | `rabble_screen_attach_touch(s_indev);` (lines 819 and 821 stay) |
| `rabble_ui.c` 865 and 895 (dark and cover conditions) | `!rabble_screen_dark() && !rabble_screen_cover_visible()` |
| `rabble_ui.c` 934 and 937 (sleep-step comment and call) | comment reworded by G; call becomes `if (rabble_screen_step(s_frames >= REVEAL_FRAMES))` (the frame counter, `s_lit_at` and the code after stay) |
| `rabble_ui.c` 1010-1021 (preview bodies) | one-line calls to `rabble_screen_preview_brightness` / `_end` |
| `rabble_ui.h` 12, 17, 20, 30 (comments naming screen sleep and brightness) | rewritten by G in its own words: the UI draws; `rabble_screen` owns screen sleep and brightness |
| `rabble_ui.c` includes | G adds `#include "rabble_screen.h"` |

**May read:** this spec; the four companion specs (copied into the workspace); the workspace's `accord/`, `nebula_lite/`, `main/`, `app/RaBbLE/` (with the table above applied); the seam headers regenerated by W0 (integrator confirms they are the regenerated ones, not the originals); managed components; the CO5300 datasheet for panel sleep and brightness; LVGL and ESP-IDF documentation.

**Must not read:** the Meta Muse Gadget SDK in any form; `apache/` and its history; `rabble_axp2101/`, `bsp/`, `muse-gadget-sdk/`, `firmware/backups/`; the Pocket repo's git history and its live working tree (the unredacted `rabble_ui.c` and everything outside the implementer's workspace); anything under the Grimoire `RaBbLE-Pocket/cleanroom/` directory other than the four companion specs and this spec, explicitly including `audit-2026-11-02/` (and `OVERLAP-REPORT.md` in it), `PROVENANCE.md`, `TRANSCRIPTS-*.md` and the other wave specs; anything under `RaBbLE-Grimoire/log/`; agent memory directories (`~/.claude`); `~/RaBbLE-Cleanroom/` other than the implementer's own workspace; the Grimoire's `RaBbLE-Pocket/` documents (`RaBbLE-Pocket-Provenance-Record.md`, `RaBbLE-Pocket-Muse-SDK-Map.md`, the Open SDK inventory). Rule of thumb: nothing outside the workspace except LVGL, ESP-IDF and CO5300 documentation. The list is followable without opening any of those: the implementer's workspace contains only the permitted items.

## 11. Decisions closed

- Module location: own SDK component `firmware/sdk/rabble_screen/` (reverses the rev-2 choice of `app/RaBbLE/`; separate from `rabble_power`, Mark 2026-11-04). Licence: SA header with the Open-transition marker, not Apache yet.
- The any-touch idle poke stays in this module.
- Original behaviour kept, except: wake is by intentional double tap (Mark, 2026-11-04); preview while dark is ignored so no setting is reachable while dark (Mark); no automatic preview clearing (`preview_end` ends it); presses while dark no longer poke the idle clock (follows from the double-tap decision).
- Notes for the other specs' authors (not done here): `w2-input` and `w3-settings` still say "fade"; `w0-state` lists `accord/rabble_ui.c`.
