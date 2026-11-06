# W11 spec: the board seam, regrouped by capability (revision 4, panel/touch split adopted)

> Spec author: S (W11). **Implementer (I) writes only:** (1) `firmware/sdk/rabble_core/rabble_board.h` (rewrite), (2) `firmware/test/app/shot_test/stubs/rabble_board.h` (rewrite), (3) `firmware/test/power/screen_test/rabble_board.h` (rewrite), (4) the button-helper rename in `firmware/sdk/rabble_core/rabble_board.c` (section 7). **Everything else is the integrator's (G)**: every caller, BSP, driver, test and fixture edit lives in a separate integrator-only file that the implementer never receives. The implementer does not open or edit those files.
> **Paths are pre-R1** (`sdk/`, `app/`). The layer plan's R1 moves them to `core/` and `entities/`; if W11 runs after R1, translate paths, nothing else changes.
> Licence markers. The three headers (1)-(3) carry, in this order, `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and `Open-transition: Apache-2.0 (planned flip; see Pocket-Foundling-Open-App-Plan.md)` (the exact line the existing screen_test stub carries). `rabble_board.c` keeps its plain Sovereign Accord line and gains no marker. No Meta line, no "interim" notice. Toolchain: ESP-IDF v6.0.1, ESP32-S3. `rabble_` identifiers and file names stay.
> Basis: derived from what RaBbLE's own callers need. It deliberately does not follow the declaration order, grouping, member names, parameter names or wording of any earlier header.
> **Ruling (Mark, 2026-11-05): the panel/touch split in `log/plans/Pocket-Seam-Slot-LVGL-Design-Note.md` is adopted.** The board contract contains no LVGL at all. The implementer may start now.

## 1. Why a rewrite, and what is free to change

Callers only need: a name, a panel with a few fast paths, a touch stream, button labels and icon spots, an optional audio path, a power meter, a clock, a motion sensor. Nothing requires one flat struct. This spec groups them by capability and names them in RaBbLE's vocabulary.

Rules for everything in this spec:
- **Types and meanings are contract; parameter names and comments are the implementer's.** Signatures are given as types only. Name every parameter in your own words. Write every comment yourself, from the behaviour described here.
- **Order rule: alphabetical by new name**, at top level, in every group and in every helper struct or enum. `bring_up` sorts first at top level. Callers use designated initialisers, so order costs them nothing; positional initialisers follow this order and G updates them.

BINDING (callers or tests depend on the exact text):
- `RABBLE_KEY_TALK_DOWN = 1u<<0`, `RABBLE_KEY_TALK_UP = 1u<<1`, `RABBLE_KEY_AUX_DOWN = 1u<<2`, `RABBLE_KEY_AUX_UP = 1u<<3`. Mark (2026-11-04): renamed from `RABBLE_BTN_*`, values unchanged. After I delivers, G applies the rename to every remaining user and greps for `RABBLE_BTN_` to confirm none remain.
- `rabble_board_set`, `rabble_board_get`, global `rabble_board`, type name `rabble_board_t`, the group member names and type names in section 3.
- Header is C++-safe (`extern "C"`), `#pragma once`, and callers get these transitively: `esp_codec_dev.h`, `driver/gpio.h`, `esp_err.h`, `rabble_state.h` (for `rabble_power_t`, `rabble_state_asleep()`), `stdbool.h`, `stdint.h`, `time.h`. **The header includes nothing from LVGL and names no LVGL type.** Any caller that needs LVGL includes it itself.

## 2. Top-level shape

`rabble_board_t` is one `const` object per board, filled with designated initialisers, whose members are capability groups (nested structs held **by value**). A group a board lacks is left zero: every optional operation is NULL, every optional number is 0. The seam never takes ownership of the table; it must have static storage.

Members (alphabetical): `bring_up`, `clock`, `ident`, `keys`, `motion`, `panel`, `sound`, `supply`, `touch`. `bring_up` is `esp_err_t (*)(void)`, one-time hardware init, mandatory, at offset 0. Group types: `rabble_board_clock_t`, `rabble_board_ident_t`, `rabble_board_keys_t`, `rabble_board_motion_t`, `rabble_board_panel_t`, `rabble_board_sound_t`, `rabble_board_supply_t`, `rabble_board_touch_t`.

No power-rail, regulator or pin-level capability exists in the seam and none is added. Rails, touch-controller resets and bus setup are the board package's private business inside `bring_up`.

**Boundary (outside this spec).** A graphics driver (an LVGL port, `drivers/lvgl_port` in the layer plan) consumes `panel` and `touch` and is the only place an LVGL display, input device, lock or alignment exists. That driver, its lock and its mapping of `rabble_anchor_t` to LVGL alignments are not written by this wave. An entity that wants LVGL links the driver; the board contract does not know it exists. W11 must not introduce an LVGL symbol anywhere in the three headers or in `rabble_board.c`.

## 3. Capability contracts

Notation: **Pre** = precondition, **Thr** = which task may call, **Own** = who owns memory/handles. "Optional" = may be NULL and the caller checks.

### 3.1 `bring_up`
- Called once by the running entity's entry point (`rabble_app_run`, or the Foundling equivalent), after the settings store is up (the board may read settings), before UI, input and voice. Brings up every chip the table exposes, including the panel and touch controller. Returns `ESP_OK` or a hard failure (the entity aborts on non-OK). Thr: the boot task, which runs on `RABBLE_UI_CORE` (from `rabble_mem.h`); the panel interrupt lands on that task's core, so a board that installs it must do so here and not hop tasks. Called from any other core, the board logs an error; it may return a failure code.
- A missing optional chip (motion, clock, power) is not a failure: leave that group's operations returning an error code.

### 3.2 `ident`
| Member | Type | Contract |
|---|---|---|
| `name` | `const char *` | Non-NULL. Printed in the boot log and the `@status` console line verbatim. |
| `ui_period_ms` | `int` | Period of the main UI's refresh timer, > 0. |

### 3.3 `keys` (buttons)
| Member | Contract |
|---|---|
| `aux_label` | `const char *`. NULL means no second button: callers then print the word "aux" where they need a word and hide the aux glyph. |
| `aux_spot` | `rabble_icon_spot_t`. Where the on-screen glyph of the second button is drawn. Read only if `aux_label` is non-NULL. |
| `park` | Optional. `void (*)(int)`, argument is a timeout in milliseconds. Used only while the display is suspended: waits for a button level change or the timeout, whichever is first, letting the CPU light-sleep. Also returns early if the calling task receives a direct-to-task notification (the input task is notified when sleep or wake state changes and on the console `nap` command); the pending notification is consumed. If NULL the caller sleeps and calls `sample` itself. |
| `sample` | Mandatory. `unsigned (*)(void)`. Returns the OR of button edge flags (section 1) seen since its previous call; zero for none. Thr: the input task only, about every 10 ms while awake. Must not block. |
| `talk_label` | `const char *`, non-NULL. Short word naming the main button in on-screen captions. |
| `talk_spot` | `rabble_icon_spot_t`. Where the on-screen glyph of the main button is drawn; also the centre of the tap-to-talk target. |

`rabble_icon_spot_t`: three fields, each declared separately, in this order (alphabetical, and forced because tables initialise it positionally as `{ RABBLE_ANCHOR_CENTER, 160, 106 }`): `anchor` (`rabble_anchor_t`), `dx` (`int16_t`), `dy` (`int16_t`). Meaning: anchor plus offset from it, in pixels.
`rabble_anchor_t` is a plain C enum, no relation to any graphics library's values. Enumerators, alphabetical: `RABBLE_ANCHOR_BOTTOM_LEFT`, `RABBLE_ANCHOR_BOTTOM_MID`, `RABBLE_ANCHOR_BOTTOM_RIGHT`, `RABBLE_ANCHOR_CENTER`, `RABBLE_ANCHOR_LEFT_MID`, `RABBLE_ANCHOR_RIGHT_MID`, `RABBLE_ANCHOR_TOP_LEFT`, `RABBLE_ANCHOR_TOP_MID`, `RABBLE_ANCHOR_TOP_RIGHT`. **BINDING** names; the values are the implementer's.

### 3.4 `panel`
The display, with no graphics-library types. There are two ways pixels reach it: `write`, which a graphics driver pushes finished regions through, and `bands`, which is **pull**: the entity installs a band source and the board's send task pulls bands from it. The two are alternatives, never both at once. Mandatory: `lock`, `px_h`, `px_w`, `set_level`, `unlock`, `write`. All others optional.

| Member | Contract |
|---|---|
| `bands` | Group `rabble_panel_bands_t` (3.4.1). `band_rows == 0` means unsupported. |
| `circular` | `bool`. True if the visible area is a circle inscribed in the rectangle. |
| `doze` | `void (*)(bool)`. `true`: panel into its low-power state (the caller has already set level 0); `false`: wake it. Waking does not restore the level; the caller does. Thr: the drawing task (the graphics driver's task). |
| `lock` | `bool (*)(int)`, argument is a timeout in milliseconds. Takes the board's panel lock, which serialises every outside user of the panel pipeline against each other. A negative timeout means no limit (the UI start path passes -1); otherwise false on timeout (console paths pass 1000). Never nested by callers. Thr: any task except the one that calls `write`. A graphics driver layers its own lock on top of this one so that one acquire protects both; that lock is the driver's, not the board's. |
| `px_h` | `int`. Panel height in pixels, > 0 (declared on its own line). |
| `px_w` | `int`. Panel width in pixels, > 0 (declared on its own line). Both used for hit-testing, centring, screenshot size and the Orbit. |
| `set_level` | `void (*)(int)`, argument 0..100. Panel emission level; 0 is dark but the panel stays on. Idempotent (the caller already de-duplicates). Thr: the drawing task. |
| `size_inches` | `float`. Panel diagonal; informational. |
| `snapshot` | Group `rabble_panel_snapshot_t` (3.4.2). |
| `suspend` | `void (*)(bool)`. `true`: stop accepting writes, stop pulling bands and stop flush work, and put the touch controller into its deepest sleep, for the longest idle (the caller decides when); `false`: resume. Thr: the input task. Absence is reported to the power policy as "cannot suspend" (it tests `suspend != NULL`). |
| `unlock` | `void (*)(void)`. Pairs with a successful `lock`. |
| `write` | `void (*)(int, int, int, int, const uint16_t *, bool)`: `x0`, `y0`, `x1`, `y1` (half-open rectangle `[x0,x1) x [y0,y1)`), pixels (RGB565, native byte order, tightly packed at stride `x1 - x0`), then a flag that is true on the last region of a refresh. Pushes a finished region to the panel; returns once the pixels no longer need to stay valid. Thr: the drawing task only (the graphics driver's). The flag lets the board know when a full frame has been written (it is what completes a snapshot, 3.4.2). |

#### 3.4.1 `panel.bands`
The entity-driven fast path. **Pull model**: the board's send task asks the installed source for each band, in contrast to `write`, where the driver pushes.
| Member | Contract |
|---|---|
| `attach` | `void (*)(const rabble_band_source_t *)`. Installs the source and starts pulling bands from it; NULL detaches and returns the panel to the `write` path. Idempotent per pointer. Ignored (no effect, no failure) while the panel's send path is not yet running; callers attach only after the UI is up. A source whose `band_rows` differs from `panel.bands.band_rows`, or that lacks `frame_begin`, `paint` or `span`, is refused: previous state kept, no logging required. The board stores the pointer only; `*src` must stay valid until detached. Thr: any single task (the entity calls it from its activate/deactivate path; which task is not verified). |
| `band_rows` | `int`. Height in rows of the bands the board can pull. The entity's band height is 16 on the current board, equal to `RABBLE_SNAPSHOT_BAND`; the app refuses a source whose `band_rows` differs. 0: no direct path. |
| `stats` | `void (*)(uint32_t *, uint32_t *)`: first output is the **cumulative** count of frames sent since boot (wrap-safe unsigned); second is an array of two `uint32_t` receiving **microseconds spent on the most recent completed frame (the whole frame, not only painting)**, one slot per core (index = core id). The second is a last-frame duration, not a cumulative total and not a cycle count. The entity uses it as time per frame (milliseconds in its log; times frame rate for a CPU-busy figure). Thr: any. Must be non-NULL whenever `attach` is, because the entity calls it unconditionally while drawing. |

`rabble_band_source_t` members, alphabetical, and so the positional init order (**BINDING**; tests initialise it positionally and G updates them): `band_rows`, `frame_begin`, `paint`, `span`, `unchanged`.
| Member | Type | Contract |
|---|---|---|
| `band_rows` | `int` | Height of every band this source describes. |
| `frame_begin` | `void (*)(void)` | Once per frame, paced by the panel, on the panel send task (core `RABBLE_UI_CORE`). Builds all per-frame state. |
| `paint` | `void (*)(uint16_t *, int, int, int, int)`: destination, first row, row count, `x0`, `x1` | Paints that span into the destination, RGB565 native byte order, rows tightly packed at stride `x1 - x0`. May run on either core, possibly two bands at once: it may read only what `frame_begin` built. |
| `span` | `void (*)(int, int, int *, int *)`: first row, row count, then two outputs | For a band of the given rows, writes the horizontal span `[x0, x1)` that will be painted and sent. |
| `unchanged` | `int (*)(int)` | Optional (NULL ok). Argument is a band's first row. Non-zero if that band would paint exactly as in the previous frame; the board may then skip sending it. |

#### 3.4.2 `panel.snapshot`
Present only if the board keeps a copy of the last complete frame pushed through `write` (the entity overlays the UI's screens onto its own drawing with it). The snapshot depends only on `write`: a frame is complete when `write` is called with its last-region flag set. It knows nothing about whichever library produced the pixels.
| Member | Contract |
|---|---|
| `exists` | `bool (*)(void)`. True if the board keeps snapshots at all. Callers use it instead of probing `latest`. Thr: any. |
| `latest` | `bool (*)(rabble_snapshot_t *)`. Fills the output with a view of the newest completed snapshot; false if none yet. **Lifetime:** exactly one reader is supported. The view is pinned (the board must not overwrite its pixels) until the reader's **next call** to `latest`; each call releases the view from the previous call. The board's `write` may wait on that release, so a reader that has taken a view and then stops calling `latest` can stall the drawing task: the reader is the entity's frame path, which calls it once per frame while it draws. The reader never retains a view past its next call. **Detach:** `bands.attach(NULL)` releases and invalidates any pinned view at once, so a stopped reader cannot stall `write`. The board's wait on a pinned view is bounded (at most 100 ms, after which it overwrites and the view is invalid); a board must not wait forever. Thr: the entity's frame path (direct renderer). |
| `set_tag` | `void (*)(int32_t)`. The drawing task states, before it writes each frame, a number that the board stores and returns in the snapshot made from that frame (the UI passes the panel width while a full screen is up, 0 otherwise). |

`rabble_snapshot_t` (**BINDING** member names; the entity reads them), alphabetical: `const uint32_t *band_ver` (one counter per `RABBLE_SNAPSHOT_BAND` rows, changes when any row in the band changes); `const uint16_t *px` (panel-sized RGB565, native byte order, tightly packed); `int32_t tag`.
`#define RABBLE_SNAPSHOT_BAND 16` **BINDING**.

### 3.5 `sound` (optional group; absent means display-only board)
| Member | Contract |
|---|---|
| `mic_bearing_deg` | `float[2]`. Direction each of the two microphones faces, degrees clockwise from the 3 o'clock direction on the screen. Read once by the entity. Meaningful only if `open != NULL`. |
| `mic_channel` | `int`. Which slot of the interleaved stereo mic stream is used: 0 left, 1 right, -1 the mean of both. Constant (read on every audio read). |
| `mic_gain_db` | Optional. `void (*)(esp_codec_dev_handle_t, int)`: the codec handle returned by `open`, and an input gain in dB. The board rounds to what the hardware supports (the audio module displays what was applied). A NULL handle: do nothing. **NULL member:** the audio module applies the gain itself through the codec-device library's own input-gain call. Thr: any. |
| `open` | Non-NULL iff the board has microphone and speaker; the app tests this pointer to choose between the voice pipeline (with outbox) and the display-only path. `esp_err_t (*)(esp_codec_dev_handle_t *, esp_codec_dev_handle_t *)`: first output speaker handle, second microphone handle; both non-NULL on `ESP_OK`; both ready but with no stream started. Called by the audio module's init on the voice start task. The board keeps the handles for the life of the program; the audio module starts and stops streams on them and never frees them. Safe to call again after a failure. |

### 3.6 `supply`
| Member | Contract |
|---|---|
| `sample` | Optional. `esp_err_t (*)(rabble_power_t *)`. Fills every field of `rabble_power_t` (`battery_pct` is -1 if there is no battery, `battery_mv` is 0 if unmeasurable, plus `charging` and `usb`). On error leaves the output untouched. Thr: the input task, about once a second. NULL means the input task skips power sensing. |
| `shut_down` | Mandatory. `esp_err_t (*)(void)`. Removes power from the board. On success it does not return; a return means failure and the code says why (the caller logs it and carries on). A board that cannot power off returns `ESP_ERR_NOT_SUPPORTED`. Thr: the input task. |

### 3.7 `clock`
Optional group; each operation may be NULL independently and callers check each one. Times are broken-down wall time as stored (`struct tm`), no timezone applied by the board.
| Member | Contract |
|---|---|
| `read` | `esp_err_t (*)(struct tm *)`. Fills year, month, day of month, hour, minute, second, weekday, zeroes the rest, and sets `tm_isdst` to -1. Error if the chip is absent or unreadable. Thr: any (UI, time module, entity). |
| `trusted` | `bool (*)(void)`. True if the chip holds a time that was set and not lost to power failure. NULL: `read` is trusted whenever it succeeds. |
| `write` | `esp_err_t (*)(const struct tm *)`. Stores year to second; the board ignores `tm_wday` and `tm_yday`. Thr: any (time module after a network sync, the clock-edit screen). |

### 3.8 `motion`
Optional group; `accel == NULL` means no motion sensing and the motion module's start fails.
| Member | Contract |
|---|---|
| `accel` | `esp_err_t (*)(float *)` (three floats). Acceleration in **g**, in **screen axes**, element 0 = x pointing right, element 1 = y pointing up, element 2 = z pointing out of the screen toward the viewer. A board lying flat, screen up, reads about (0, 0, +1); held upright with the top of the screen up reads about (0, +1, 0). The board package owns the rotation from chip axes to screen axes. Error if the chip is absent. Thr: the motion task (every 20 to 500 ms) and the input task (console `imu` reply) may call concurrently; the board serialises its own bus. |
| `economy` | Optional. `void (*)(bool)`. `true`: lowest-power sampling (used while asleep); `false`: normal. Called by the motion task only on change. After `false`, `rotation` may fail for a short settle time. |
| `rotation` | Optional. `esp_err_t (*)(float *)` (three floats). Angular rate in rad/s about the same axes as `accel`. May error while the sensor settles after wake; callers then treat the reading as absent for that cycle. |

### 3.9 `touch`
Optional group; the board has no touch controller when `present` is false. A plain stream of contact states, no input-device object.
| Member | Contract |
|---|---|
| `next` | `bool (*)(rabble_touch_event_t *)`. Fills the output with the next pending contact event and returns true; false if none is pending. Does not block. Thr: the graphics driver's input task (one reader). Non-NULL whenever `present` is true. |
| `present` | `bool`. True if the board has a touch controller. Gates the Orbit gesture surface. |

`rabble_touch_event_t`, alphabetical: `down` (`bool`, true while the finger is in contact, false for the release event), `x` (`int16_t`), `y` (`int16_t`): panel pixels, same axes as `panel.px_w` and `px_h`, each declared separately.

## 4. Globals and entry points (BINDING)
- `extern const rabble_board_t *rabble_board;` set by `rabble_board_set(const rabble_board_t *)`, which the entity's entry point calls first thing; non-NULL afterwards. Defined in `rabble_board.c`.
- `const rabble_board_t *rabble_board_get(void);` supplied by the board package; returns its static table.
- `void rabble_app_run(const rabble_board_t *board);` stays in `rabble_app.h`, not here (likewise the Foundling entry point in `foundling_app.h`).

## 5. Threading summary
| Core / task | Calls |
|---|---|
| Boot task (core `RABBLE_UI_CORE`) | `bring_up` (must be this core), first `lock(-1)` and `unlock` |
| Drawing task (graphics driver) | `write`, `set_level`, `doze`, `snapshot.set_tag`, `clock.read` (UI clock) |
| Panel send task (`RABBLE_UI_CORE`) | `frame_begin`, `span`, `paint`, `unchanged` (paint also on the other core) |
| Entity / UI frame path | `bands.attach`, `bands.stats`, `snapshot.exists`, `snapshot.latest` |
| Input task | `keys.sample`, `keys.park`, `panel.suspend`, `supply.sample`, `supply.shut_down`, `motion.accel` (console reply), `lock(1000)` and `unlock` |
| Graphics driver input task (one reader, owned by the driver, not by the UI) | `touch.next` |
| Motion task | `motion.accel`, `rotation`, `economy` |
| Voice start task | `sound.open`; later any task: `mic_gain_db` |
| Any task | `clock.read`, `clock.write`, `clock.trusted` |

## 6. Ownership summary
The board owns: its table, the codec handles, the panel, the snapshot memory, the stored source pointer (not the object). The entity owns every `rabble_band_source_t` it attaches. No operation in the seam transfers heap ownership across it.

## 7. Button helper rename (implementer: `rabble_board.h` declarations and `rabble_board.c`)

Rename only; edit `rabble_board.c` in place; behaviour unchanged; the plain Sovereign Accord line stays and no marker is added to that file. The implementer writes the declarations and all comments. Members of the pad record, alphabetical: `down` (`bool`, current debounced state), `high_is_down` (`bool`), `pin` (`gpio_num_t`), `run` (`uint8_t`, debounce counter). Type name `rabble_pad_t`. (The board group for buttons is `keys`, so `rabble_pad_*` names only this helper.)

| New name | Arguments in order | Behaviour |
|---|---|---|
| `rabble_pad_edges` | pad pointer | Advances the debounce one step; returns `RABBLE_KEY_TALK_DOWN` or `RABBLE_KEY_TALK_UP` on a settled change, else 0. |
| `rabble_pad_open_high` | pad pointer, pin | Configures the pin as an input where pressed reads high, with no pull resistor; initialises the record. |
| `rabble_pad_open_low` | pad pointer, pin | Configures the pin as an input where pressed reads low, and turns on the chip's own pull-up resistor if this pin has one; initialises the record. |
| `rabble_pad_wait_any` | array of pad pointers, count, timeout in ms | Waits until any listed pad changes level, the timeout passes, or the calling task is notified (consuming the notification); light-sleep allowed. |

Old to new (sorted by old name): `active_high` to `high_is_down`; `gpio` to `pin`; `pressed` to `down`; `rabble_gpio_button_init` to `rabble_pad_open_low`; `rabble_gpio_button_init_high` to `rabble_pad_open_high`; `rabble_gpio_button_poll` to `rabble_pad_edges`; `rabble_gpio_button_t` to `rabble_pad_t`; `rabble_gpio_buttons_wait` to `rabble_pad_wait_any`; `stable` to `run`. The button flag macros `RABBLE_BTN_*` used inside `rabble_board.c` become `RABBLE_KEY_*`.

## 8. Everything else: integrator only
Caller, BSP, driver, test and fixture edits are described in `cleanroom/w11-integrator-notes.md`. That file is not part of the implementer's export and is not read by the implementer.

## 9. Evidence (S's, not the implementer's reading list)
S read the callers and the board package to write the contracts: `rabble_input.c`, `rabble_ui.c`, `rabble_entity.c`, `rabble_shot.c`, `rabble_time.c`, `rabble_audio.c`, `rabble_motion.c`, `rabble_motion.h:23` (axis convention), `rabble_qmi8658.h:28` (unit g), `rabble_app.c`, `rabble_screen.c`, `foundling_app.c`, `foundling_ui.c`, and the Waveshare package's axis rotation, stats and snapshot code. Verified: no caller reads a pin, a rail or a touch register through the seam; touch arrives only through the board's touch capability.

## 10. Test plan
### 10.1 Stub copies (implementer writes)
- `test/app/shot_test/stubs/rabble_board.h`: provides what `rabble_shot.c` and `shot_test.c` use: `rabble_band_source_t` (identical to 3.4.1, same member order), a reduced `rabble_board_t` containing only `panel` whose type `rabble_board_panel_t` has the two members `px_h` and `px_w`, **declared on separate lines**, and `extern const rabble_board_t *rabble_board;`. Includes only `<stdint.h>`. No IDF, no graphics library. The spelling `.panel.px_w` must compile against both headers.
- `test/power/screen_test/rabble_board.h`: provides what `rabble_screen.c` and `test_screen.c` use, including `<stdbool.h>`: a reduced `rabble_board_t` containing only `panel`, whose type `rabble_board_panel_t` has two members `doze` (`void (*)(bool)`) and `set_level` (`void (*)(int)`), declared in that alphabetical order on separate lines, and `extern const rabble_board_t *rabble_board;`.
- Self-check (implementer): a syntax-only compile (`-fsyntax-only`, `-Wall -Wextra -Werror`) of each of the three headers on its own, the real one against ESP-IDF include paths, so that G does not receive a broken drop. Nothing else is run.

### 10.2 Seam tests, overlap gate, device check
Owned by G; described in the integrator notes. The overlap gate (non-generic residual below 5% against the upstream board header) and Mark's device flash both still apply.

## 11. Implementer may read / must not read
The integrator exports the workspace as follows: the three interim headers (`sdk/rabble_core/rabble_board.h`, `test/app/shot_test/stubs/rabble_board.h`, `test/power/screen_test/rabble_board.h`) are **blanked** (emptied to a stub comment line) before the implementer starts; the `cleanroom/` directory (which contains `w11-integrator-notes.md`, `audit-2026-11-02/` and `OVERLAP-REPORT.md`) is excluded; `apache/` is excluded; `boards/` and `test/core/seam_test/` are excluded (they hold the old flat table, which the implementer never needs).

May read: this spec; `RaBbLE-Pocket-Clean-Room-Plan.md`; `rabble_board.c` (to rename the helper in place); `rabble_state.h`, `rabble_mem.h`; ESP-IDF and esp_codec_dev public headers. No callers.
Must not read: the Meta Muse Gadget SDK in any form; the provenance-audit clone; `apache/` and its git history; the interim headers or stubs in git history; `w0-seam.spec.md` and `w0-state.spec.md`; anything under the Grimoire `RaBbLE-Pocket/cleanroom/` other than this spec, including `w11-integrator-notes.md`, `audit-2026-11-02/`, `OVERLAP-REPORT.md` and `PROVENANCE.md`; `RaBbLE-Grimoire/log/` (including the seam design note: this spec states its outcome); agent memory directories (`~/.claude`); `~/RaBbLE-Cleanroom/` other than the implementer's own workspace. Do not diff your header against any earlier one; if a section's output matches the old text line for line, regroup it.

## 12. Open questions for Mark
1. Answered (2026-11-03): full regroup.
2. Answered (2026-11-03): `suspend` is display pause plus touch deep-sleep.
3. Which task calls `bands.attach` (`rabble_entity_set_active`) is unverified; marked "any single task".
4. Closed: accelerometer contract is stated (g, screen axes x right, y up, z toward viewer).
5. Closed (Mark, 2026-11-04): the button helper and the four flag names are renamed (section 7).
6. Closed: detach releases the pinned view (3.4.2).
7. Closed (Mark, 2026-11-05): caller edits are the integrator's; ordering is alphabetical; licence marker is SA plus Open-transition.
8. Closed (Mark, 2026-11-05): panel/touch split adopted, LVGL leaves the board contract, anchors are a plain enum.
9. Open: the graphics (LVGL) driver and the glue that keeps today's BSP behaving identically until it exists are a separate wave; see the integrator notes.

## Mark's rulings
- (2026-11-03) Full regroup into capability groups; device flash is a gate, in addition to the overlap gate.
- (2026-11-03) `suspend` is the contract: display pause plus touch deep-sleep.
- (2026-11-03) Board-shape facts (pins, bus addresses, panel geometry) are hardware-forced, not influence.
- (2026-11-05) Implementer writes only the new header, the two stubs and the helper rename; all mechanical edits are the integrator's. Alphabetical order everywhere.
- (2026-11-05) Panel/touch split adopted; LVGL types leave the board contract; the icon hint uses a plain enum.
