# W10 spec: hardware seam (replaces the single board table)

> Status: DRAFT 2 (S305), revised per QuiBbLE's REVISE verdict and Mark's rulings of 2026-11-03. Spec author: RaBbLE (has read Pocket's own tree through scout reports only; has NOT read Meta's SDK, the old `rabble_board.h`, or `apache/` history).
> Implementer rule: a fresh agent that has not read the Meta Muse SDK, `apache/` history, the old `rabble_board.h`, or `~/RaBbLE-Cleanroom`. New files carry `Copyright (c) 2026 The RaBbLE Collective.` and `SPDX-License-Identifier: Apache-2.0`. No Meta line.
> The implementer chooses ALL names (types, functions, fields, files). This spec gives none. The implementer works only from this document, the file allow-list (section 9) and the host-test shim already in the tree.

## 0. Rulings this spec rests on (Mark)

- The seam is whatever design is best and keeps the work separate from Meta-derived code. Registration-only is a preference, not a provenance requirement.
- Boards live inside the SDK tree. The SDK is Apache-2.0; the RaBbLE app is Sovereign Accord. The SDK never includes app code.
- Shape: **one constant description of a board, built from small per-capability parts**. A board hands the SDK that description once. Any part a board lacks is simply absent.
- Buttons are a source of press and release events, merged by the input task with events from anywhere else. A future trigger needs no change to the button part.
- Display power is one state, not two independent switches.
- The clock part feeds the time service only. Nothing else reads the chip.
- The Waveshare reference adapter is written by the integrator, not the implementer.
- The 12:00-while-unsynced display rule is NOT in this wave (section 7).
- BOOT stays the default talk trigger. Tap-to-talk (branch `tap-to-talk`) is a separate trigger source and is untouched here.

## 1. Outcomes required

Each line is a testable outcome. How it is achieved is the implementer's design.

1. One constant value describes the whole board. Reading any board property after start-up needs no lock and no allocation.
2. Absent capability is a normal state. For every capability the SDK can answer, cheaply and before using it, whether it is present. A caller that needs a capability the board lacks is stopped at start-up with one clear log line naming it, never later by a null dereference.
3. A board that omits a capability its own claims require (for example claims a mic but gives no way to open it) is rejected when the description is installed, with a log line naming the gap. Installing twice, or after the application has started, is rejected.
4. Display geometry is one value. Every consumer that needs width, height or the renderer band height reads that single value. The band height exists in exactly one header (called the strip height elsewhere in this spec).
5. The hot paths are unchanged in cost: per-band rendering, the texture snapshot, and the 10 ms input poll must not gain an extra indirection layer, lock, allocation or copy compared with today. The integrator measures this (section 8).
6. No behaviour change for existing users of the seam: same timings, same units, same core and task rules, same observable boot result on the Waveshare 1.75-B.
7. Every outcome here has a host test that can fail. A board with only display and buttons starts. A board missing a required part is rejected. Presence queries match what was supplied.
8. No dead fields. Nothing is carried that no code reads.

## 2. Start-up constraints (not a recipe)

- Settings must be readable by board bring-up.
- Hardware bring-up is a single step the application triggers. It succeeds even when an optional chip is absent, and presence reports reflect what actually came up. Presence queries made before bring-up report "not yet known" rather than absent.
- **Bring-up and display creation run on the UI-core task, never on the main task.** Running them elsewhere has hung the panel before. The design must make calling from the wrong task impossible or loudly reported.
- Anything holding the display lock must release it before the frame timer exists; the lock supports an unbounded wait.
- Memory-heavy radio start-up stays last, as today. The seam must not change the order in which heap is claimed.

## 3. Capabilities (required behaviour only)

Listed by dependency: services the others lean on first, presentation last.

### 3.1 Power
- A battery reading gives percent (the caller starts with -1 meaning unknown), millivolts, charging, USB present, and an error when no controller is there.
- Software power-off is present or absent. When present it returns only on failure. Callers check presence.

### 3.2 Clock
- A board may supply a calendar clock: local calendar fields can be read and written (weekday is not written), and the clock says whether its stored time can be trusted.
- Only the time service consumes it. The face and everything else go through the time service.
- Absent clock: the time service behaves as it does today on a board with no chip.

### 3.3 Input: buttons and trigger events
- A board names its talk key and, optionally, a second key. Each has a word to show and a screen position for its hint. No second key means none appears anywhere.
- The board reports press and release events for both keys accumulated since the previous check, without blocking. The input task checks every 10 ms awake and every 50 ms while the display is paused. A board may additionally offer sleeping until an event or a timeout (1000 ms paused, 10000 ms napping); this is optional.
- The talk key is debounced on every check. The power-controller key is read on every second check; that cadence is written down in code and tested, not an unnamed counter.
- **Events from any other source enter the same stream.** The input task merges board events with injected ones into one ordered stream. Injection is safe to call from any task and costs nothing when unused. Nothing in the key handling changes when a new source is added.
- A shared helper for debounced pins (active level, debounce count, waking light sleep on an edge) stays available to boards. It is a helper, not part of this capability.

### 3.4 Motion
- Acceleration is reported in **g** (not m/s²): three values on the screen's axes. An error is returned when the sensor is absent.
- Rotation rate is optional: three values in radians per second on the screen's axes, read only while awake. The sensor may decline while it warms up.
- A low-power mode is optional. It is set only when the state changes, from the motion task, and is on while the device sleeps.
- Acceleration presence is probed once when motion starts. Failure turns motion off without an error shown to the user.

### 3.5 Audio
- Opening audio yields a speaker handle and a mic handle, or fails if either is missing. It happens when the voice path starts, not at install.
- Which channel feeds the mic path (left, right, or a blend of both) is fixed in the board description for the life of the build and read per audio chunk. It is not changed at runtime.
- A board may supply its own rule turning a requested gain in dB into the gain applied (this board rounds down to 3 dB steps and caps at 34.5 dB). With none, the requested gain is applied as given.
- Audio being absent is how the application knows it is on a display-only board: no outbox, no voice.

### 3.6 Direct draw and texture
- A board may supply a strip renderer called once per frame. The seam accepts or refuses installing one: refused if the send task is not running, if the strip height differs from the single shared constant, or if any required piece is missing. The first accepted install moves LVGL into textures; removal does not move it back.
- Rendering may happen on both cores. Frame count and per-core render time are readable while active.
- A whole-panel pixel copy (16-bit RGB565, packed), a change counter for each horizontal strip, and the current marker can be fetched without blocking. A copy held by a caller is released by that caller's next request. Asking with no destination is an existence check only.
- The UI sets the marker the renderer sees on the next fetch.
- All of this is one capability. Its absence means the LVGL-only face runs and the Orbit and overlay are off.

### 3.7 Display
- The board builds the LVGL display (and the touch input device when touch exists) once, and reports failure rather than half-succeeding.
- LVGL access is serialised by a lock the application takes with a timeout or waits on forever. The console path gives up after one second and reports the display as busy.
- Brightness takes 0 to 100, clamped, and takes effect without blocking the LVGL task.
- **Power state is one value** the application sets: awake, panel asleep, or rendering paused. The seam reports which states the board supports so the power policy knows what is possible. A board that supports only awake is valid.

### 3.8 Identity and geometry
- Where the microphone sits on the bezel: two angles in degrees, each measured from the +x axis turning clockwise, so the face can turn toward it.
- A human-readable board name, read-only, safe to print (consumers escape it).
- Panel width and height in pixels; whether touch exists; the UI frame period.
- The marker protocol that signals "a UI screen covers the whole panel" versus "the face is showing" is kept, or replaced by something clearer, with both ends changed together in the integrator step.

## 4. Required vs optional

Required parts are those a capability cannot work without; they are checked at install (outcome 3). Optional parts report "not supported" through a defined result, never through a bare null the caller has to remember to test.

## 5. Coupling rules that must survive

1. Strip height: one constant, equal in the direct-draw part, the renderer and the panel code.
2. Direct draw present (3.6) means the entity renderer is on. The Orbit additionally needs touch. The overlay additionally needs the pixel copy, the marker and an existence check.
3. Pixel copy and marker are one part.
4. Mic handle, channel choice and gain rule are one part.
5. Audio presence gates outbox, voice and display-only mode.
6. Motion: angular rate only while awake; low power only on change.
7. Poll cadence: see 3.3.

## 6. Deliverables from the implementer

1. New headers and sources for the board description, the per-capability parts, installation and presence queries, and the event stream with injection.
2. Host fakes and host tests for each outcome in section 1 and each behaviour line in sections 3 to 5, including: display-plus-buttons-only board starts; a board missing a required part is rejected; double install and late install are rejected; injected events merge in order with polled ones; wrong-task bring-up is reported.
3. A short design note with the implementer's own reasoning for the shape chosen. It is part of the provenance record.
4. NOT a Waveshare adapter. The integrator writes it (section 8).

## 7. Out of scope

- The 12:00-while-invalid-and-unsynced clock display rule. It is a separate UI change after W10 that belongs to the time service and the face, using sCoRE time or a companion device to correct itself, with no RTC chip showing 12:00. W10 only guarantees the clock part feeds the time service alone, which makes that change small.
- Wake word, tap-to-talk and any other new trigger, apart from the injection point (3.3).
- Any change to hardware drivers, the LVGL adapter, panel bring-up code or timings.
- The entity renderer's internals.

## 8. After the implementer (not part of this spec)

Integrator (CoBbLE, one capability per commit, a shim keeps the old table alive until the last lands): write the Waveshare 1.75-B adapter against the new interfaces without changing the hardware code behind them; migrate callers; replace host fakes; run host tests; build; flash; 18a soak (60 fps idle, at least 30 fps busy); A/B free heap against the old layer (3 boots each); measure the hot paths (outcome 5); overlap gate on the new files. CrumBbLE verifies on device. NiBbLE reviews. The old header and its static-assert test are deleted last.

## 9. Implementer file allow-list

Under `firmware/`:
- May create: new files in `sdk/rabble_core/` (new names only) and new tests under `test/core/` in a new directory.
- May edit: `sdk/rabble_core/CMakeLists.txt` and `sdk/rabble_core/Kconfig` to add its own files and options.
- Must not read or edit: `sdk/rabble_core/rabble_board.h`, `sdk/rabble_core/rabble_board.c`, `test/core/seam_test/` (including `board_table.c`), anything under `boards/`, `drivers/`, `app/`, any file that references `rabble_board->`, the W0 and W6 specs, `cleanroom/`, `~/RaBbLE-Cleanroom`, and any directory named `apache`.
- Host-test infrastructure it may use: the stubs already present under `test/*/*/host_stubs` and the `compile_check.sh` approach, copied by value into its own test directory.

## 10. Rulings log (Mark)

- 2026-11-02: option A (capability groups) if no regression; trigger injection point included; boards are SDK, not app; BOOT stays default; wake word later, CPU budget is the hurdle; mic icon is the on-screen trigger.
- 2026-11-03: QuiBbLE's simpler path (single constant description, buttons as event sink, display power as one state, clock feeds the time service only) because registration-only was a preference; integrator writes the adapter; SDK is Apache-2.0 with boards inside, app is Sovereign Accord, write W10 assuming the split lands; 12:00 rule is a separate later commit. No lawyer review is planned; provenance rests on the clean-room records.
