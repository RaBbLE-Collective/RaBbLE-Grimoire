# W6 spec: the board layer (Waveshare ESP32-S3-Touch-AMOLED-1.75-B): board table, panel bring-up, band renderer

> Clean-room spec, wave W6. Author role: S (S268, Opus 5.5; read `firmware/bsp/` at Pocket `ac2e9f9`). Firewall: S268 F (Opus 5.5 sub-agent): rephrased passages that echoed the original's comments and log strings, rewrote the band-path, direct-frame and texture rules as outcomes rather than a walk of today's code, corrected the TE-missing and DMA-size facts, and added missing behaviour (LVGL-only slice size, texture hold window, sync-area reset, error pass-through). Files to be replaced: `firmware/bsp/bsp_waveshare_175b.c`, `firmware/bsp/rabble_lcd_bands.c`, `firmware/bsp/rabble_lcd_bands.h` (the last Meta-derived code in the firmware). New files go under `firmware/bsp/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Companion specs: `w0-seam.spec.md` (the board vtable, cores, priorities), `w2-axp2101.spec.md` (PMU driver), `w4-audio.spec.md` (the only caller of the codec handles).

> **Revision 2** (S276, author S, Opus 5.5; read the old `firmware/bsp/rabble_lcd_bands.c` direct-frame path at Pocket `new-horizons` `6d26a76`): sections 6.3 and 6.4 rewritten from the gadget results of revision 1 (section 13); 10.1 item 18a and the revision-2 note in 11 added; 13 rewritten as behaviour. Firewall: S276 F (Opus 5.5 sub-agent): approved with changes, all applied; implemented in one Opus round, Pocket `w6r2-integration` (6.4.8 corrected: the notify assert is not explained by notifying a blocked task; steady-30 edge counting; no-TE resting floor; edge-to-band-0 timing in `>perf`; 6.6 on the direct path; RAM measurement). The seam headers now live in `firmware/sdk/rabble_core/` (SDK step S1); where this spec says `accord/rabble_board.h`, `rabble_mem.h` or `rabble_console.h`, read that folder.

Treatment: clean room, **leaner** (hybrid strategy). The public interface is the `rabble_board_t` seam and nothing else. How the band renderer is organised inside, its file split, internal names and internal API are yours. Where a number is given it is a behaviour value. Section 8 lists the **deliberate behaviour changes**; everything else is "same as today".

---

## 0. A map of the board, for Mark

This section is plain words, for reading before anything else. The contract starts at section 1.

### 0.1 What is on the board

The Pocket is one ESP32-S3 (two cores, 240 MHz, 8 MB PSRAM, 16 MB flash) with six chips around it. Two buses carry almost everything:

| Chip | What it does | How the S3 reaches it | Notes |
|---|---|---|---|
| **CO5300** (CHIPONE) | drives the 466 x 466 round AMOLED | **QSPI** (four data lines, GPIO 4-7, clock 38, CS 12), reset GPIO 39, **TE** (tearing effect) out on GPIO 13 | the only fast bus on the board. AMOLED: black pixels are off, so brightness is a panel command, not a backlight |
| **CST9217** (Hynitron) | capacitive touch | **I2C** (SDA 15, SCL 14), reset GPIO 40, interrupt GPIO 11 | no public datasheet; the managed Waveshare driver is the reference |
| **AXP2101** (X-Powers) | power: battery charger, fuel gauge, the rails, the PWR key | I2C | PWR reaches only this chip; the S3 learns about presses by asking it over I2C |
| **PCF85063** | real-time clock (keeps time while off) | I2C | |
| **QMI8658** | IMU: accelerometer + gyro | I2C | mounted turned relative to the screen (5.12) |
| **ES8311** + **ES7210** | speaker codec + two-mic ADC | I2C for control, **I2S** for sound (MCLK 42, BCLK 9, LRCK 45, out 8, in 10), amplifier enable GPIO 46 | one shared duplex I2S bus at 16 kHz |
| TCA9554 | 8-bit I/O expander | I2C | carries the IMU's INT1; nothing of ours uses it today |

BOOT is GPIO 0 (lower side button: talk). PWR (upper side button) goes only to the AXP2101. The TF card slot uses GPIO 1-3.

So: **one QSPI bus for pixels, one I2C bus for every control chip, one I2S bus for sound.** The I2C bus is shared by touch, PMU, RTC, IMU and both codecs, which is why "who talks on I2C when" matters (audio closes its codec in its own task, touch is read by LVGL, the PMU is polled by input).

### 0.2 What happens at power-on, in order

1. **ROM and bootloader** (about 0.45 s to "Loaded app"): checks and loads the image from flash.
2. **App start** (to about 0.97 s): PSRAM is found and, today, **tested** (about 0.22 s), code and read-only data are copied into PSRAM, the heap is set up, `app_main` runs.
3. **Board `init`**: I2C up, then the PMU (turn off the rails nothing uses, arm the PWR key), the RTC, the IMU. About 30 ms.
4. **`display_start`**: LVGL's adapter, then the panel: QSPI bus, reset pulse, the CO5300's init commands, display on, brightness to zero. Then the band renderer, then touch, then LVGL starts.
5. **The UI's first frames** are drawn with the panel dark; after three of them the UI turns the brightness up. That is "panel lit".

Measured S268 (reset boot, `ac2e9f9`): app_main 966 ms, init done 1020 ms, **panel init 1208 → 2411 ms**, touch 2496 ms, LVGL started 2527 ms, **lit 2809 ms**. The 1.2 s in the middle is two 600 ms waits in the vendor's init sequence (after the row window command and after Sleep Out). The CO5300 datasheet asks for 5 ms after Sleep Out before the next command and says the booster is up 120 ms after it. Most of that 1.2 s is slack: section 7 makes it a target.

Why this order: the PMU first, because it owns the power the codecs need; the panel before touch, because they share a reset story (0.4); LVGL last, because it needs a display and an input device to exist.

### 0.3 How a frame travels to the glass

Two paths, never both at once.

**The LVGL path** (settings screens, clock, level, anything made of widgets). LVGL draws the screen into PSRAM in a few tall bands, about four per screen. LVGL's cost per band is a pass over its widgets, so a handful of tall bands is far cheaper than dozens of short ones, and that cost is what decides whether a swipe tracks the finger. Pixels then have to reach the panel from internal RAM, because DMA straight out of PSRAM is too slow when both cores are working. So the band data is moved into small internal buffers and sent from there, with copying and sending overlapped. LVGL renders already in the panel's byte order, so no per-frame byte swap is needed.

**The direct path** (the entity face, the Orbit, everything `nebula_lite` draws). LVGL's bands are dropped. Once per panel refresh (the TE pulse) the scene prepares a frame, and the screen is drawn as 16-row bands. Both cores render bands straight into internal DMA buffers, and the bands go on the wire top to bottom. Bands that did not change since the last frame are skipped. While the direct path runs, LVGL still runs (touch, its screens), but it draws into two full-screen PSRAM pictures (the **UI texture**) that the scene can sample. That is how the face shows an LVGL screen sliding in.

The S264 freeze lives here: when the second core is busy with higher-priority work (the measured case was a TLS handshake running at Wi-Fi's priority for more than a second), a band it was rendering must not hold the frame indefinitely (rule 6.4.7).

### 0.4 Sleep, wake and power-off

- **Screen off** (`display_pause(true)`): LVGL stops and the touch chip is put into its deep sleep. **Panel sleep** is a plain Sleep In command. The CO5300's "deep standby" is not used: leaving it requires a panel reset pulse, and this design keeps every reset out of the wake path except the touch chip's own.
- **Wake**: a reset pulse brings touch out of deep sleep (nothing else does), LVGL resumes, the panel gets Sleep Out.
- **Power-off**: the AXP2101 cuts the power. A short PWR click turns it on again, and that is a full boot (0.2). The Pocket powers off after 45 s asleep on battery (`CONFIG_RABBLE_POWER_OFF_S`, Orbit "Off when asleep"), so most wakes from the pocket are full boots. A wake from plain sleep draws in about 0.13 s.

### 0.5 Where the docs are

The seam: `w0-seam.spec.md`. How the waves fit: `RaBbLE-Pocket-Clean-Room-Plan.md`. Who wrote what: `PROVENANCE.md`. Datasheets: Pocket `firmware/datasheets/` (CO5300 and ES7210 added S268; no public CST9217 datasheet exists). The managed Waveshare package (`waveshare__esp32_s3_touch_amoled_1_75`) holds the pin map, the vendor's panel init sequence, and touch, I2C and codec bring-up.

---

## 1. Purpose and scope

Provide this board's `rabble_board_t` (the only file that knows the wiring) and the display engine behind it: panel bring-up at 80 MHz QSPI, the LVGL band path, the direct band path with two-core rendering and TE pacing, the UI texture, and the "run on the send task" rule for any panel command. Lean on managed components for everything they already do: pins, I2C, touch, codecs (Waveshare package), the CO5300 command layer (`espressif__esp_lcd_co5300`), LVGL integration (`espressif__esp_lvgl_adapter`). Our files keep the board table, the glue and the band engine.

Out of scope: the chip drivers `rabble_axp2101`, `rabble_pcf85063`, `rabble_qmi8658` (RaBbLE's own; call their public headers), the seam itself (`accord/rabble_board.h`), and anything above the seam.

## 2. Public interface (complete and frozen)

The one exported function:

| Name | Contract |
|---|---|
| `const rabble_board_t *rabble_board_get(void)` | Returns a pointer to a single static, constant table. Called once, from `main/app_main.c`, before anything else. |

Nothing else is exported to `accord/` or `main/`. Internal headers between your own `bsp/` files are yours; no `accord/` file may need to include them.

### 2.1 The table's values

| Field | Value |
|---|---|
| `name` | `"Waveshare ESP32-S3-Touch-AMOLED-1.75-B"` |
| `width`, `height` | 466, 466 |
| `round`, `touch` | true, true |
| `diagonal_in` | 1.75 |
| `talk_button`, `aux_button` | `"boot"`, `"pwr"` |
| `talk_hint` | `{ LV_ALIGN_CENTER, 160, 106 }` (beside BOOT, about 33 degrees below 3 o'clock) |
| `aux_hint` | `{ LV_ALIGN_CENTER, 160, -106 }` (beside PWR, about 33 degrees above) |
| `mic_deg` | `{ 211, 145 }` (MIC1 upper left, MIC2 lower left; the USB-C port at 9 o'clock sits between them; angles clockwise from 3 o'clock) |
| `frame_ms` | 40 |
| `direct_rows` | 16 |
| `mic_slot` | -1 (average both mics) |
| `wait_buttons` | NULL (input polls) |
| all function members of the seam | provided (sections 5 and 6). None is NULL except `wait_buttons`. |

### 2.2 Callers

| Caller | Uses |
|---|---|
| `main/app_main.c` | `rabble_board_get()`, then `rabble_app_run(board)`. |
| `accord/rabble_app.c` | `init` first, then the rest in its bring-up order (`w0-seam.spec.md`). |
| `accord/rabble_ui.c` | `display_start` (from the UI bring-up task, pinned to `RABBLE_UI_CORE`), `display_lock`/`unlock`, `set_brightness`, `panel_sleep`, `display_pause`. |
| `accord/rabble_entity.c`, Orbit | `display_direct`, `direct_stats`, `ui_texture`, `ui_texture_tag`, `direct_rows`. |
| `accord/rabble_audio.c` | `audio_init`, `set_mic_gain`, `mic_slot`. |
| `accord/rabble_input.c`, `rabble_battery.c`, `rabble_time.c`, `rabble_motion.c` | `poll_buttons`, `read_power`, `power_off`, `rtc_*`, `imu_*`. |

Confirm the exact list with a grep of `accord/` and `main/` in your workspace.

## 3. What the board layer may call

| Source | For |
|---|---|
| Waveshare package (`bsp/esp-bsp.h`, `bsp/display.h`, `bsp/touch.h`) | pin macros (`BSP_LCD_*`, `BSP_I2C_*`, ...), `bsp_i2c_init`, `bsp_i2c_get_handle`, `bsp_touch_new`, `bsp_audio_codec_speaker_init`, `bsp_audio_codec_microphone_init`, `BSP_LCD_SPI_NUM`, `CONFIG_BSP_LCD_TRANS_QUEUE_DEPTH`. Do **not** use `bsp_display_new`/`bsp_display_start`: they fix the pixel clock at 40 MHz and allocate PSRAM draw buffers (5.3). |
| `espressif__esp_lcd_co5300` | the panel object over QSPI with a custom init sequence (its vendor config), its bus/IO config macros. |
| `esp_lcd_panel_io` / `_ops` | bitmap draws, parameter commands, the colour-transfer-done callback. |
| `espressif__esp_lvgl_adapter` | LVGL task, lock, display registration with a custom draw-bitmap hook, touch registration, pause/resume. |
| LVGL public API, plus its display internals where the texture path needs them (buffers, render mode, flush callback, sync areas) | 5.5. If you reach into LVGL private headers, say so in a comment and keep it to the texture switch. |
| `rabble_axp2101.h`, `rabble_pcf85063.h`, `rabble_qmi8658.h` | the three chip drivers. |
| `rabble_board.h`, `rabble_mem.h` | seam types, `rabble_gpio_button_*`, core and priority constants. |
| ESP-IDF: FreeRTOS, `gpio`, `spi_master`, `esp_heap_caps`, `esp_timer`, `esp_log`, `esp_check` | |

Not allowed: any `accord/` header beyond `rabble_board.h`, `rabble_mem.h` and `rabble_state.h` (pulled in by the seam); settings, UI, voice, beam.

## 4. Threading, cores and priorities

Constants from `rabble_mem.h`: `RABBLE_UI_CORE`, `RABBLE_UI_PRIORITY` (5). Facts about priorities above and below: voice 6, beam 5, Wi-Fi 23 (ESP-IDF default), and a TLS handshake inherits Wi-Fi's priority through priority inheritance while it holds the websocket client's lock.

1. **LVGL's task** runs on `RABBLE_UI_CORE` at `RABBLE_UI_PRIORITY`.
2. **One send task** owns the panel. It is pinned to `RABBLE_UI_CORE`. Every panel command or pixel transfer after registration goes through it (6.6), whatever core asks.
3. **The panel's SPI bus must be set up from a task pinned to `RABBLE_UI_CORE`.** ESP-IDF routes an interrupt to the core that installed it, and the send task runs on `RABBLE_UI_CORE`. Required, not tidy: with the transfer-done interrupt on the other core, a race in ESP-IDF's SPI bus lock has been observed to leave the send task blocked for good, with a partly drawn frame on the glass. `display_start` is called from such a task. If it finds itself on the other core, log an error.
4. **Send task priority:** `RABBLE_UI_PRIORITY + 1` while on the LVGL path (LVGL's bands must not queue behind LVGL itself); `RABBLE_UI_PRIORITY - 1` while on the direct path (drawing the scene must not starve LVGL, which still handles touch, gestures and its screens). Voice, at 6, is above the send task on either path.
5. **The helper task** renders direct bands on the other core at priority 3, under the beam and Wi-Fi, so it only uses time nothing else wants; rescue rule 6.4.7 applies.
6. Touch is read by LVGL's task (through the adapter). PMU key polling happens in the input task that calls `poll_buttons` every 10 ms.
7. Draw areas and band windows on the CO5300 must start on an even row and column and end on an odd one (even width and height).

## 5. Behaviour: board

### 5.1 `init`

1. I2C bus up (Waveshare package). Failure: return the error (the only fatal case in `init`).
2. BOOT button on GPIO 0 via `rabble_gpio_button_init` (active low, pull-up). Failure: return the error.
3. **PMU** (`rabble_axp2101_init` with PWR-key latching on and the 128 ms power-on press time, so a short click powers the board on again after a power-off). If it fails: log a warning that battery status is off, and carry on. If it succeeds: keep only DCDC1 (3.3 V system) and ALDO1 (3.3 V for the codecs) on; turn every other DC-DC and LDO off (the schematic leaves them unconnected). If that fails, warn and carry on.
4. **RTC** init. On failure warn and remember "no RTC".
5. **IMU** init at the default address. On failure warn and remember "no IMU".
6. Return `ESP_OK`.

The board must boot and run its UI with any of PMU, RTC or IMU missing or broken.

### 5.2 `display_start(&touch)`

Called once from the UI bring-up task on `RABBLE_UI_CORE`. Returns the LVGL display and fills `*touch` with the touch input device, or returns NULL if any step fails (the caller then runs without a screen).

1. LVGL adapter initialised with its task on `RABBLE_UI_CORE` at `RABBLE_UI_PRIORITY`.
2. Panel: QSPI bus (max transfer large enough for one direct band buffer and one LVGL slice, 5.3), panel IO at **80 MHz** pixel clock (the vendor's 40 MHz can't reach 60 fps; 80 MHz holds it), CO5300 panel object with the vendor's init sequence from the Waveshare package, **with its waits trimmed to the datasheet** (7.1), column gap 6 (the visible window starts at column 6), reset, init, display on.
3. **Brightness 0 before any pixel is drawn** (it can be sent directly, since the send task does not exist yet). Better: make the init sequence itself end dark. Either way: no visible flash, white or otherwise, before the UI's first frame.
4. Band engine registered (section 6), with the TE GPIO (13) and direct band buffers sized for 16-row bands.
5. Invalidated areas rounded out to even bounds (rule 4.7) on LVGL's display.
6. Touch: `bsp_touch_new` with X and Y both mirrored, registered with the adapter on that display.
7. Start the adapter. Return the display.

### 5.3 Memory rules for the display

- **No panel transfer may be issued straight from a PSRAM buffer.** The SPI driver would allocate a transient internal DMA buffer as large as the transfer (tens of KB for an LVGL band), and after Wi-Fi starts that allocation fails. So every buffer handed to the panel IO is **internal DMA memory**, allocated once in `display_start` (before Wi-Fi exists) and kept for the life of the firmware. LVGL's own band buffers are PSRAM (double-buffered, tall); their contents reach the panel only via the internal buffers.
- Internal DMA used by the band engine, all buffers together: at most about 61 KB (today four direct buffers, each one full-width 16-row band, 14,912 bytes, plus a little slack; the LVGL path reuses them). Watch internal RAM headroom: a failing `xTaskCreate` (beam's websocket task first) is the symptom of running out (S267).
- If the direct buffers cannot be had, the LVGL path still needs its internal buffers: at least two, each holding 8 full-width rows (7,456 bytes).
- The two UI textures (466 x 466 RGB565 each, about 434 KB together) are PSRAM.
- **No PSRAM texture copies** on any per-frame path (S264/S265 lesson: copying PSRAM to PSRAM per frame kills the frame rate). The scene samples the texture in place.
- Degrade, don't fail: no room for the direct buffers → LVGL-only (direct mode refuses, warning); no room for the helper or its extra buffers → one core draws (warning); no room for the textures → direct mode runs but `ui_texture` reports none (warning saying LVGL screens will not appear over the face). Wording of all warnings is yours.

### 5.4 Brightness, panel sleep, pause

- `set_brightness(pct)`: 0..100 mapped to the CO5300 "write display brightness" (0x51) as `pct * 255 / 100`, sent **through the send task** (6.6). Before the send task exists, sent directly.
- `panel_sleep(sleep)`: Sleep In (0x10) or Sleep Out (0x11) as a plain command through the send task, then wait 120 ms before returning (the datasheet's settle). **Never deep standby** (0x4F); never the CO5300 driver's own sleep call if it enters deep standby.
- `display_pause(true)`: pause LVGL through the adapter (no timeout), then put the CST9217 into deep sleep: over the touch panel IO (8-bit command), send command byte `0xD1` with one parameter byte `0x05` (the same command-mode family as the managed driver's `0xD101`). After that the chip ignores I2C until its reset line is pulsed.
- `display_pause(false)`: touch reset low for 10 ms, then high, then 50 ms before anything talks to touch (matching the settle the managed driver allows after its own reset), then resume LVGL. Touch is not re-initialised.
- `display_lock(ms)` / `display_unlock()`: the adapter's lock; lock returns true when taken.

### 5.5 Audio and mic gain

- `audio_init(&spk, &mic)`: the Waveshare package's speaker and microphone codec handles. `ESP_OK` only if both are non-NULL.
- `set_mic_gain(mic, db)`: the ES7210's PGA works in 3 dB steps. Snap `db` down to a multiple of 3 so the UI shows what is applied. Then apply with `esp_codec_dev_set_in_gain`, except **33 dB**: `esp_codec_dev` rounds 33 down to 30, so pass 34.5 (the next real step up) for 33. (ES7210 datasheet in `firmware/datasheets/`.)

### 5.6 Buttons

`poll_buttons()` is called every 10 ms by input and returns OR-ed edge flags:
- BOOT: debounced through `rabble_gpio_button_poll`, which already returns `RABBLE_BTN_TALK_PRESS`/`_RELEASE`.
- PWR: the PMU's key latch, read **every second call** (every 20 ms) with `rabble_axp2101_poll_key`; a latched press becomes `RABBLE_BTN_AUX_PRESS`, a latched release `RABBLE_BTN_AUX_RELEASE`. Without a PMU, no aux edges.

### 5.7 Power

- `read_power(out)`: the PMU's battery percent, millivolts, charging and USB-present, copied into `rabble_power_t`. Errors pass through.
- `power_off`: `rabble_axp2101_power_off`.

### 5.8 RTC

- `rtc_get(tm)`: fails with `ESP_ERR_INVALID_STATE` without an RTC; a chip read error passes through. Else read the PCF85063 and convert: year minus 1900, month minus 1, day, hour, minute, second, weekday, `tm_isdst = -1`.
- `rtc_set(tm)`: same failure without an RTC; else the reverse conversion (weekday not written).
- `rtc_valid()`: an RTC exists and it reports its time as valid.

### 5.9 IMU

Mounting (verified on the gadget with `>imu`): chip +X points to the top of the screen, chip +Y to the screen's right, chip +Z away from the viewer. Seam axes are screen axes: **seam x = chip y, seam y = chip x, seam z = minus chip z**. Apply the identical mapping to gyro rates (the mapping is a rotation, determinant +1). Interrupt wiring, for reference: INT1 goes to the TCA9554 expander, INT2 to GPIO 21; neither is used.
- `imu_read(accel)`: `ESP_ERR_INVALID_STATE` without an IMU; else the chip's acceleration in g, remapped; a chip read error passes through.
- `imu_read_gyro(rate)`: same, rad/s; the chip driver's error passes through (it fails while settling), and `rate` is untouched on error.
- `imu_low_power(low)`: passes through when there is an IMU, else nothing.

## 6. Behaviour: the band engine

### 6.1 LVGL path

1. LVGL draws in RGB565 in the **panel's byte order** (byte-swapped), into two PSRAM band buffers of 118 rows each (four bands cover the screen). Panel IO calls for a band happen on the send task, never in LVGL's context; LVGL's draw-bitmap hook only hands the band over.
2. A band reaches the panel as one or more transfers, each from an internal DMA buffer (5.3), each covering whole rows with an even row count (rule 4.7), each no larger than one internal buffer. Copying the next part of a band must overlap the transfer of the previous one (two internal buffers in use on this path), so the wire is not idle while the CPU copies.
3. LVGL is told the band is done (the adapter's ISR-safe colour-transfer-done notify) only after every part of it has left the wire, and then exactly once. A part that fails to send counts as sent (LVGL must never hang on a failed transfer).
4. The engine takes over the panel IO's colour-done callback and disables the adapter's own callback registration.

### 6.2 Switching paths: `display_direct(d)`

Called from LVGL's context. `d` non-NULL starts the direct path with that scene; NULL stops it. Returns once the send task has switched.
1. No-op if `d` is already the current scene. If `d` is non-NULL and the direct buffers could not be allocated, refuse silently (stay on LVGL).
2. Starting: point LVGL at the UI textures (6.5) first, then switch the send task. Stopping: switch the send task first, then restore LVGL's own band buffers, render mode, colour format and flush exactly as they were. On both switches, LVGL's double-buffer bookkeeping of areas still to be synced (left over from the other configuration) is discarded. If the textures do not exist, LVGL keeps its band buffers on the direct path (rule 6 below covers its bands).
3. The switch takes effect on the send task, only once nothing is on the wire. After a switch back to the LVGL path, no internal buffer is considered busy.
4. The first direct frame after a switch draws **every** band (the panel holds something else).
5. Send task priority changes with the path (4.4).
6. While direct, any band LVGL still offers to the panel is reported done immediately and discarded, never queued: LVGL runs above the send task on this path and would otherwise spin waiting for it.

### 6.3 One direct frame (revision 2, S276)

The scene (`rabble_display_direct_t`, the seam header `rabble_board.h`) gives `begin`, `window`, `render`, optional `same`, and `rows` (16). Revision 1 of this section let work for a frame start before the frame's TE edge; on the gadget that tore moving content while the gadget turned (see 13). Revision 2 fixes **what may happen before the edge**, and **which edge belongs to a frame**.

1. **`begin()` first.** `begin()` runs on the send task before the frame waits for its edge, so the scene's own preparation overlaps the wait.
2. **The frame's edge.** A frame's edge is the first rising edge of TE (GPIO 13) that arrives **after `begin()` is called**. An edge that arrives while `begin()` is still running counts; an edge that arrived before the call does not (it belongs to an earlier frame and must be forgotten before the call). The frame waits at most 40 ms; on timeout it carries on as if the edge had arrived. The 40 ms limit runs from the end of `begin()`. In the steady-30 mode (8.2) the frame's edge is the **second edge after the previous frame's edge**, counted whether or not anything was waiting; if `begin()` is called after that edge, it is the first edge after `begin()` is called. After a frame whose wait timed out, the timeout moment stands in for the previous edge.
3. **Nothing else before the edge.** Until the frame's edge has arrived (or the wait has timed out), neither core calls `same`, `window` or `render` for that frame, and the other core is not released to work on it. Rendering ahead during the wait is not allowed, even into free buffers.
4. **Every frame waits for its edge**, including a frame with no band to draw (revision 1 skipped the wait when `same` left nothing to send: a resting Orbit spun at about 4,000 frames/s and starved the UI core's idle task). Without TE (no TE GPIO configured, or its interrupt could not be installed), frames don't wait and run unpaced; a failed interrupt install warns once at setup. But without TE, a frame with no band to draw blocks for at least `frame_ms` (40 ms, 7.2) before the next `begin()`, so a resting scene can't spin.
5. **Bands to draw**, decided after the edge: band `n` covers rows `16n` to `16n + 15` (the last band is clipped at row 465). A band is drawn unless `same` exists and returns non-zero for the band's first row. When the panel holds something else (first frame after a switch, or a band failed to send in the previous frame), every band is drawn and `same` is not consulted.
6. **Each band to draw is rendered exactly once per frame**, on either core: `window(y, rows, &x0, &x1)`, then `render(buf, y, rows, x0, x1)` into an internal DMA buffer, after widening `[x0, x1)` to even bounds (4.7). A buffer is never rendered into while its previous transfer is still pending. Work is shared so that the UI core never sits idle waiting for the other core while a band nobody has started is available.
7. **Bands are sent top to bottom**, each as the window `[x0, x1) x [y, y + rows)` from its buffer, all from the send task. A failed draw makes the next frame a full frame.
8. **Frames don't overlap.** A band rendered for one frame is never sent in another, and no work for the next frame (not even `begin()`) starts before every band of this frame has been handed to the panel driver.
9. **The first band of a frame** goes to the panel only after it has been rendered after the edge (rules 3 and 6); nothing prepared earlier may be sent in its place. Revision 1 also showed small dots at the **top edge** while turning, which the old layer never shows. Their cause was not settled. The implementer reports what in their engine decides when band 0 starts on the wire relative to the edge; the integrator measures the TE high time (the panel's vertical porch, CO5300 datasheet 5.3, mode `35h` = 00) on the gadget if the dots remain.

### 6.4 Rules the direct path must keep

1. Four direct band buffers when the other core helps (rendering may run ahead of the wire **within** a frame, after its edge, never further than the buffers allow: a buffer whose transfer is pending is not reused, 6.3.6); two when one core draws.
2. `render` and `window` may run on either core, concurrently for different bands. `begin` runs only on the send task and never concurrently with any `render`, `window` or `same` call.
3. `direct_stats(&frames, us[2])`: frames drawn on the direct path since boot; `us[RABBLE_UI_CORE]` = the last frame's CPU time on the UI core (`begin`, its own renders, the time spent in draw calls; waits excluded), `us[other]` = the helper's render time for the last frame it finished.
4. The entity gates still hold: **60 fps idle** on the face, **at least 30 fps** busy and turning, Orbit slide with meshes **at least 40 fps**. Holding bands back to dodge the panel's scan (a revision-1 experiment) kept the tearing and cost the idle gate (52 fps): no scheme may hold a rendered band back to avoid the scan.
5. Flash work (NVS, LittleFS, OTA writes) runs under panel priority (S264/S265): nothing in the engine may hold a lock that flash work needs while waiting for TE or a band.
6. If the helper core is not available (no room, 5.3), the send task renders every band itself.
7. **A frame is never held by a stalled helper core** (S264 freeze fix). Higher-priority work on the helper's core can stall a band the helper has started (measured: a TLS handshake at priority 23, through priority inheritance, for more than a second). Once the send task has spent **6 ms** waiting on one such band, the helper runs at `configMAX_PRIORITIES - 2` (above Wi-Fi) until the end of that frame, then returns to 3. At most one lift per frame. Count frames that needed one (logged, 8.1).
8. **How the engine's tasks block (revision 1 crashed here).** Revision 1 rebooted every few seconds while turning with a FreeRTOS assert in the notify path (`xTaskGenericNotify` / `vTaskGenericNotifyGiveFromISR`, `tasks.c`). FreeRTOS raises it when a task it believed was waiting for a notification is also queued on another object; correct API use can't produce that, so it points to corrupted task state (a stack overflow), a stale task handle, or a FreeRTOS call from the wrong context. The cause was not pinned down. Rules:
   - (a) The engine's tasks use **no direct-to-task notifications** (no `xTaskNotify*`, `vTaskNotifyGive*`, `ulTaskNotifyTake`, `xTaskNotifyWait` on them); every hand-over between the engine's tasks and interrupts goes through a semaphore, queue or event group the waiting task blocks on.
   - (b) Interrupt handlers (TE, colour-transfer-done) use only `FromISR` calls, and task code never does.
   - (c) The engine's task handles stay valid for the life of the firmware (no engine task is deleted or re-created).
   - (d) Stack canaries stay on, and 6.4.9's high-water gate is part of 10.1 item 18a.
   - (e) No engine task busy-waits. A task waiting for a band, a free buffer or an edge is woken by the event it waits for; a timeout is only a backstop and must not set the pace in normal running.

   The integrator decodes any assert's backtrace (which task, notifying whom) before sending it back as behaviour.
9. **Memory budget.** Internal RAM is tight (a beam task that can't be created is the first symptom, S267). The send task's and helper's stacks live in internal RAM and together use **no more than 11 KB**; each keeps **at least 512 bytes unused** (high-water mark) through the 18a soak; the engine's internal DMA stays at 7.2's figure; any other internal `.bss` the board layer adds stays under 1 KB (UI-only state goes to PSRAM). Gate: free internal heap after boot within **1 KB** of the old layer's on the same build base (revision 1 lost 2.6 KB), measured as `heap_caps_get_free_size(MALLOC_CAP_INTERNAL)` 5 s after boot, same commit, old layer vs new, three boots each. While `>perf` is on, report both stacks' high-water marks (once when turned on is enough).
10. **The Orbit slide looks as it does on the old layer** (Mark's eyes): the face's mesh keeps streaming into the dial during the slide, at 60 fps where the old layer holds 60. Revision 1 looked different. The gate is a side-by-side A/B on the gadget.

### 6.5 The UI texture (`ui_texture`, `ui_texture_tag`)

While the direct path runs, LVGL renders into two full-screen PSRAM RGB565 buffers (native byte order, not the panel's) using LVGL's own direct render mode with two buffers, which already keeps both buffers current. Each finished LVGL refresh **publishes** its buffer as the front.
1. `ui_texture(NULL)` returns whether the textures exist.
2. `ui_texture(&out)` returns false until a whole screen has been drawn into the textures since the direct path started (every row covered by full-width draws at least once). After that it returns true and fills: `px` = the front buffer, `band_ver` = one counter per 16-row band (`RABBLE_UI_TEXTURE_BAND`) that changes whenever any row of that band was drawn in a refresh, `tag` = the value `ui_texture_tag` had when that refresh was published. `px`, `band_ver` and `tag` are mutually consistent (all from the same publish) and stay valid and unchanged until the caller's next `ui_texture` call; a publish racing the call must not tear them.
3. A buffer returned by `ui_texture(&out)` is **held** from that call until the next `ui_texture` call. LVGL must not start drawing into a held buffer: when a refresh is about to write one, it waits for the direct side to call again (and so move to the new front), but never longer than about 100 ms in total.
4. On every path switch the textures start over: nothing is published, and every band counter changes. The board layer may rely on its caller (`accord/rabble_ui.c` invalidates the whole active screen whenever the entity path toggles) for the full redraw that makes the next publish possible.
5. While on the textures, LVGL's flush reports each area done at once (nothing goes to the panel) and records which rows it covered.

### 6.6 Running work on the send task

An internal "run this on the send task" call: the function runs on the send task **between bands** (never mid-band), and the call returns only after it has run. Concurrent callers are served one at a time. Before the send task exists it runs the function directly. Brightness, panel sleep and any other panel command use it. Works on both paths: on the direct path it runs only after a frame's last band has been handed over and before the next `begin()`, never mid-frame.

## 7. Timings and limits

### 7.1 Boot targets (behaviour)

Measured S268 on `ac2e9f9`, reset boot, today's `sdkconfig.defaults`:

| Point | Today | Target |
|---|---|---|
| panel init (reset done → init sequence done) | 1,203 ms | **≤ 150 ms** (datasheet: 5 ms after Sleep Out before the next command, booster up 120 ms after it; display on no earlier than that) |
| panel reset | 163 ms | the CO5300 needs 5 ms after reset release; the managed driver's own reset timing is acceptable |
| `display_start` total | 1,503 ms | **≤ 350 ms** |
| panel lit (UI's brightness-up) | 2,809 ms | **≤ 1,700 ms** with today's config; ≤ 1,450 ms with the config trims of 8.3 |

Keep the panel dark until the UI lights it (5.2.3): trimming the waits must not bring back a boot flash.

### 7.2 Limits

| Item | Value |
|---|---|
| Pixel clock | 80 MHz QSPI |
| LVGL bands | 118 rows, two PSRAM buffers, panel byte order |
| Direct bands | 16 rows; 30 bands per full frame (466 = 29 x 16 + 2, so the last band is 2 rows tall) |
| TE wait | at most 40 ms per frame |
| Helper | other core, priority 3; rescue after a 6 ms wait to one below the FreeRTOS maximum |
| Internal DMA for the engine | about 61 KB, allocated once in `display_start` |
| UI textures | 2 x 466 x 466 x 2 bytes, PSRAM |
| Panel sleep settle | 120 ms |
| Touch wake | 10 ms reset low, 50 ms after |
| PMU key poll | every 20 ms |
| Frame time hint (`frame_ms`) | 40 |

## 8. Deliberate behaviour changes (W6 is otherwise not a redesign)

### 8.1 Perf logs are opt-in

Today the direct path logs a timing line every 10 s whatever happens. New: **silent by default**. A console command `>perf` toggles it (`>perf=on`, `>perf=off`, bare `>perf` toggles; one reply line stating the new state). While on, every 10 s, one info line with the averages per frame over the window: time in `begin`, time rendering on the UI core, time in draw calls, time waiting for the helper, the helper's render time, helper bands of all bands, kilopixels sent per frame, and (6.3.9) the average and maximum time from the frame's edge to band 0 being handed to the driver, and from the end of `begin()` to that edge; plus a warning line with the rescue count if any rescue happened. The format is yours; keep it one line. The console command is registered through the existing console module's public interface (`rabble_console.h`): if that needs the board layer to include an `accord/` header beyond section 3's list, the integrator decides where the command lives (likely `accord/` calling a small board hook). Raise it, don't work around it.

### 8.2 Steady 30 fps when 60 can't hold

New: when the direct path cannot hold 60 fps (frames running past one TE period), pace to **every second TE edge** (a steady 30 fps) instead of an uneven mix of 60 and 30. Go back to 60 once frames fit again, with hysteresis so the rate does not flap (for example: drop to 30 after most of the last 8 frames ran late; return to 60 after 30 frames that would all have fit). Idle face and Orbit slide gates (6.4.4) still hold.

### 8.3 Boot config trims (apply only with Mark's ok)

In `firmware/sdkconfig.defaults` (none of these is set today): the console path (S268 finding: the primary console is UART0 at 115200, which nothing reads but every log byte busy-waits; preferred fix is USB Serial/JTAG as the primary console, fallback 921600; see `../RaBbLE-Pocket-Responsiveness.md` path 2), `CONFIG_SPIRAM_MEMTEST=n` (~0.22 s, measured), `CONFIG_BOOTLOADER_LOG_LEVEL_WARN`, and `CONFIG_BOOTLOADER_SKIP_VALIDATE_ON_POWER_ON=y` (trade-off: no image check on cold power-on). These are the integrator's call with Mark, not the implementer's. The serial tools (`serlog.py`, `build-flash.sh` monitor) must follow any console change.

### 8.4 Panel init waits

7.1's panel init target is a change from the vendor's sequence timing (the commands themselves stay as the vendor's).

### 8.5 No TE wait without TE

Today, if the TE interrupt cannot be installed, each direct frame still waits out the full 40 ms timeout (about 25 fps), and a board configured with no TE GPIO runs unpaced without a warning. New (6.3.2): either way frames run unpaced; only the failed-install case warns.

## 9. Error cases

| Case | Behaviour |
|---|---|
| I2C or BOOT button init fails | `init` returns the error. |
| PMU missing | warning; no battery status, no aux edges, `power_off` fails as the driver does. |
| Rail trim fails | warning; carry on. |
| RTC or IMU missing | warning; their calls return `ESP_ERR_INVALID_STATE` (`rtc_valid` false, `imu_low_power` nothing). |
| Any `display_start` step fails | NULL. |
| Direct buffers can't be allocated | warning; LVGL only; `display_direct(d)` refuses. |
| Helper task or its buffers can't be had | warning; one core draws. |
| Textures can't be allocated | warning; `ui_texture` false. |
| TE interrupt can't be set up | warning; unpaced frames. |
| A transfer fails | LVGL path: the slice counts as done; direct path: next frame is full. |
| `display_start` called off `RABBLE_UI_CORE` | error log (4.3); continue. |

## 10. Gadget checklist (integrator)

### 10.1 Same as today

1. Unused PMU rails are off after init (read back with the PMU's registers or the board's current draw at idle vs. today).
2. PWR: press and release edges arrive (Orbit and sleep react); a long hold powers off; after power-off a short click powers back on (full boot).
3. Board degrades without PMU, RTC or IMU: simulate by forcing each init to fail in a test build; the face still comes up with a warning.
4. No visible flash at boot (white or otherwise) before the UI's first frame; same at wake.
5. Brightness slider changes brightness live; brightness changes never tear a frame or race a band.
6. Screen off and on (`z`, `w`, PWR tap, touch, BOOT): panel sleeps and wakes, touch works after every wake, everywhere including the rim.
7. Panel never uses deep standby (no reset pulse on panel wake; touch keeps working).
8. Mic gain: each 3 dB step applies; 33 dB records louder than 30 (`>status` and a recording).
9. IMU: `>imu` shows gravity along screen axes as today (tilt up/right/face-down); spin face and heading hold behave; gyro offset learning still converges.
10. Button hints, mic angles and `frame_ms` unchanged (visual check of the hint icons).
11. No panel transfers from PSRAM (5.3): Orbit and LVGL screens draw after Wi-Fi connects, with no allocation-failure warnings, through a beam turn.
12. Band-send task and its SPI interrupt on `RABBLE_UI_CORE` (no stuck half-frames across 10 minutes of mixed LVGL and direct use).
13. With TE disabled (test build with GPIO -1): frames unpaced, nothing hangs (8.5: no warning in this case), and the task watchdog stays quiet for 1 minute on a resting Orbit (6.3.4).
14. Entity gates: 60 fps idle (the entity's `fps` lines), ≥ 30 busy/turning, Orbit slide with meshes ≥ 40.
15. **S264 freeze repro:** flash work during a turn (notes store write, capture save) and a TLS reconnect while the face animates: the face never freezes; rescue count appears with `>perf` on.
16. UI texture: Orbit opening/closing and LVGL screens sliding over the face show whole, current pictures (no stale band, no tearing).
17. Audio: a full voice turn works (codec handles fine).

18a. **Revision 2 gates:** no torn bands and no dots (top edge included) at any orientation, Orbit open or on the face; a soak with no crash or reboot (10 minutes of turning, Orbit open/close, three voice turns, five sleep/wake cycles); the Orbit slide A/B'd against the old layer (6.4.10); free internal heap within 1 KB of the old layer (6.4.9).

### 10.2 Deliberate changes

18. Boot: one reset boot and one cold boot (PWR power-on after power-off) logged; panel lit within 7.1's targets; no flash.
19. `>perf` toggles; silent by default.
20. Load the face until it can't hold 60 (a busy turn): the rate settles at a steady 30 rather than flapping, and returns to 60 when idle.

## 11. Test vehicle

**Revision 2:** the workspace starts with revision 1's board table, display bring-up, UI texture and `>perf` hook files under `bsp/` (they passed on the gadget; keep them unless the band engine needs a change in their internal interface, and say so). The band engine (both paths, 6.1-6.4 and 6.6) is written fresh.

The **whole firmware** builds in the clean workspace: the integrator writes a fresh `bsp/` skeleton there first (a `CMakeLists.txt` with the REQUIRES list, an `idf_component.yml` with the Waveshare `^3.0.1` dependency, interface level only). The test vehicle is that build plus a flash to the gadget by the integrator. The implementer delivers the new `bsp/` sources, a clean build, and, where the band engine's ordering rules can be tested off-target (band list, each band rendered once and sent in order, buffer reuse, rescue timing with a fake clock), a small host test under `firmware/test/cleanroom/w6/`.

## 12. Integrator decisions and questions for Mark

1. Config trims (8.3): Mark's ok before applying.
2. Where `>perf` is registered (8.1): integrator decides with the console module's interface in view.
3. 30 fps hysteresis numbers (8.2) are a starting point; Mark may tune.
4. The CST9217 deep-sleep write (5.4) is a chip fact without a public datasheet; it is kept as today's measured behaviour.

## 13. Revision 1 on the gadget: what passed, what failed (behaviour)

Revision 1 (S268) went through five implementer rounds (S268-S270), each run on the gadget and A/B'd against the old layer. Revision 2 (S276) rewrites 6.3 and 6.4 from the results below; everything else in this spec is unchanged.

**Passed (keep as built):** board table (2, 5.1, 5.5-5.9), display bring-up (5.2: display up in 404 ms, panel init 294 ms, against 1,203 ms of panel init before), dark boot (no flash, reset and cold), brightness live, panel sleep/wake and touch everywhere after wake, PWR edges, long-hold power-off and click power-on, IMU tilt and spin, `>perf` (8.1), steady 30 fps on heavy frames (8.2). The PMU "chip not answering" at boot also shows on the old layer: not a W6 issue.

**Failed:**
1. A frame with nothing to draw skipped its TE wait: a resting Orbit spun at ~4,000 frames/s and the task watchdog fired. Now 6.3.4.
2. Torn bands and edge dots on moving content while turning (Orbit rim items, the face's ring). On the device: turning the helper off changed nothing; drawing every band every frame made it smaller; rendering nothing until the frame's edge made the torn bands go. Now 6.3.2-6.3.3 and 6.3.8.
3. Small dots at the top edge remained even with rendering after the edge. Unresolved; 6.3.9.
4. Holding bands back while the panel's scan crosses them kept the tearing and cost the idle gate (52 fps). Now 6.4.4.
5. A notify assert rebooted the board every few seconds while turning. Now 6.4.8.
6. The Orbit slide's mesh streaming into the dial looked different from the old layer (Mark). Now 6.4.10.
7. Free internal heap after boot was 2.6 KB lower than the old layer's on the same base. Now 6.4.9.
