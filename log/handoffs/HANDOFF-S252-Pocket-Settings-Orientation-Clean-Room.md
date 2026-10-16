# HANDOFF S252: Pocket settings that turn with the device, then the clean room

Cold start for the next agent. Repo `RaBbLE-Pocket`, branch `new-horizons`, entity work at `074a07f` (not pushed).
Two tracks, decided by Mark in S252:

1. **Settings track** (this doc): finish the blank-face slide bug, and make the settings page and the swipe follow the device's orientation **continuously, like the entity** (not quarter-turn snapping).
2. **Clean room** (`RaBbLE-Pocket/RaBbLE-Pocket-Clean-Room-Plan.md`): replace every Meta-derived file with RaBbLE's own code, **two-team clean room**. Read that plan's Roles section before touching anything: the S252 session and anyone who has read `apache/` can never be an implementer.

Previous handoff (done): `done/HANDOFF-S251-Pocket-Entity-60fps.md`. Port plan with all results: `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Port-Plan.md`.

## Where it stands (S252)

The entity is at **60 fps idle, TE-locked**, with Wi-Fi and the beam connected. It runs at 30 to 41 fps listening and speaking, and about 30 fps in every state while turning. Internal heap after `ready` is 37.5 KB. Flashed on the gadget.

How (all in `074a07f`, details in the port plan's S252 section):

- **Both cores.** `bsp/rabble_lcd_bands.c` direct mode has a band ring of 4 internal DMA buffers. A helper task on core 0 (`lcd_help`, priority 3, below the beam) and `lcd_send` on core 1 claim bands by CAS; a claim only succeeds when its buffer's last transfer finished. `lcd_send` sends in order and renders whatever the helper hasn't reached.
- **Damage.** `nl_band_same()` (`nebula_lite/src/compose.c`) hashes each 16-row band's inputs: ring step, binned prims, sprites. `lcd_bands` builds a list of changed bands per frame and renders and sends only those. Entering direct mode forces one full frame.
- **Roll held at rest.** `rabble_entity.c` `upright()` freezes the turn while the spring is slow and within 0.6° (sensor noise used to dirty every band).
- **Sparse mesh**, with activity from FreeRTOS run-time stats (`CONFIG_FREERTOS_GENERATE_RUN_TIME_STATS=y`; tickless idle broke the old idle-hook count) less each core's render time.
- **Seam changes** (`rabble_board.h`): `rabble_display_direct_t.same` (optional damage hook); `direct_stats(frames, render_us[2])` per core; `render()` may run on either core.
- **Logs every 10 s:** `lcd_bands: direct ms/frame: begin, render, draw, wait | helper (bands of total) | draw on an idle wire, kpx/frame` and `rabble_entity: fps, render core1 + core0, ... act`.

### What the numbers taught (don't relearn these)

- **The wire is the ceiling once two cores render.** Each `esp_lcd_panel_draw_bitmap` makes five polling SPI transactions (CASET cmd and param, RASET cmd and param, RAMWR cmd), each first draining the queued transfer: about **160 µs per band even on an idle wire**, about 5 ms per full frame, plus about 9 ms of pixels at 80 MHz QSPI. Skipping unchanged bands was the step that reached 60.
- **Per-pixel loops, not setup, cost the time.** Moving line setup to push time saved only 8%. The integer line loop is about 44 cycles per pixel slot. Fewer pixels (sparse mesh, damage) is what pays.
- **Anything that changes every frame defeats damage.** Roll jitter did; a texture or animation that ticks constantly will too. Hash only what is drawn.
- **Driving the gadget from the host:** serial `d` / `u` is push-to-talk down/up (`rabble_input.c` `serial_task`). Read with `stty -F /dev/ttyACM0 115200 raw -echo; timeout N cat /dev/ttyACM0`. Each real turn spends Groq TTS quota (3.6K tokens/day cap); keep test turns few.
- **Turning tests without hands:** a temporary `in.roll = 0.6f * sinf(now * 0.9f)` after `upright()` in `frame_begin`; never commit it.

## Settings track

### The bug (unchanged since S251)

Swiping toward settings calls `set_entity_active(false)` (`accord/rabble_ui.c` `frame_tick`), so LVGL takes the panel back and shows its own face canvas, which was never drawn (`pose_entity` skips while direct; `frame_tick` returns early while sliding). Result: a blank face during the slide.

### Design (Mark: continuous orientation)

LVGL can't draw at arbitrary angles cheaply. So **LVGL becomes a texture producer and the direct renderer composites it.** The panel stays in direct mode whenever the main screen is awake. That fixes the bug at its root, because the entity never hands the panel back mid-slide, and it lets settings turn with the entity.

```
LVGL (upright frame, touch inverse-rotated)
   └─ queue_band: copy + byte-swap LVGL's band into the back UI texture (466x466 RGB565, PSRAM, x2)
        └─ on the last flush of an LVGL refresh: publish (swap, bump version, copy dirty rect forward)
direct frame (both cores)
   ├─ entity scene, translated along its own x by -slide
   ├─ NL_P_IMAGE: UI texture, turned by the held roll, clipped to x >= W - slide in the texture frame
   └─ damage: the image prim hashes texture version + slide + roll
```

### S1: LVGL as a texture, upright only (fixes the bug)

1. **Capture** (`bsp/rabble_lcd_bands.c`): when direct and a texture is attached, `queue_band` copies each LVGL band into the back texture with a byte swap (LVGL draws `RGB565_SWAPPED`; nebula_lite blends native and swaps last; export a swap helper from nebula_lite or do a plain 16-bit swap), records the dirty rows, then calls `lv_display_flush_ready`. On `lv_display_flush_is_last()`, publish: swap front and back, bump a version, copy the dirty area into the new back so both stay whole. Two textures of 434 KB each in PSRAM (5.4 MB free). LVGL only redraws what was invalidated, so when capture starts, invalidate the whole active screen once (`lv_obj_invalidate(lv_screen_active())`, plus `lv_layer_top()`) so the texture starts whole. Checked S252: the adapter's v9 bridge calls our `custom_draw_bitmap` once per flushed area, and `lv_display_flush_is_last` is valid there (the adapter's own `display_manager.c` uses it).
2. **Seam** (`rabble_board.h`): something like `const uint16_t *(*ui_texture)(uint32_t *version)` returning the published front texture (native byte order, stride 466) and its version. Keep it board-agnostic.
3. **nebula_lite:** a new input `nl_inputs_t.ui` (pixels, stride, version, slide px) and a primitive `NL_P_IMAGE` that copies texture rows into the band. Upright: a straight row copy over `[W - slide, W)`. Hash version and slide into the damage hash for every band the image covers. Translate the scene by `-slide` along the entity's x axis in `tx()`. The ring and the button badges are fixed to the hardware: they stay and the image covers them.
4. **UI** (`accord/rabble_ui.c`): keep direct mode on while sliding and on the settings tile. Hand the tileview's `lv_obj_get_scroll_x(s_tv)` to the entity glue every frame (for example `rabble_entity_set_slide(px)`). Drop the `sliding` early return. When fully on settings, skip the scene's face (the image covers it) to save CPU.
5. **Gate:** swipe to settings and back. The live entity slides out and settings slides in, no blank frame, no pop. Settings is fully usable while direct (taps, sub-pages, keypad, Wi-Fi list, scrolling). At least 30 fps through the slide; a static settings page redraws close to 0 bands per frame.

### S2: Orientation (continuous)

1. **One roll source.** Expose the held roll from `rabble_entity.c` (`rabble_entity_roll()`). `rabble_ui.c` has its own `upright_roll()` for the old LVGL face; the texture path and touch must use the entity's held value so taps and pixels agree.
2. **Touch:** in `rabble_ui.c`, wrap the touch indev's read callback (`lv_indev_get_read_cb` / `lv_indev_set_read_cb`, LVGL 9.5.0). After the original read, rotate the point by minus the roll about (233, 233) into the upright frame. LVGL then thinks the screen is upright, so the tileview swipe follows the device by itself: "toward the entity's right" is a swipe in whatever direction that is on the glass. Touch comes from `bsp_waveshare_175b.c` (`esp_lv_adapter_register_touch`, mirror x/y already set). Checked S252: the adapter sets the read callback once at registration (`esp_lv_adapter_input_touch.c:271`) and keeps its context in the indev's driver data, so a wrapper that saves the original callback and calls it with the same indev is safe.
3. **Turned image:** `NL_P_IMAGE` inverse-maps each pixel through the roll, like the turned sprite path in `raster.c` (`nl_draw_sprite`). Bilinear on RGB565 uses the spread trick (`0x07E0F81F`) for the four taps. A straight copy only when the held roll is exactly 0; at a resting tilt the image is drawn turned once and then damage-skipped.
4. **Clip** in the texture's own frame (`x >= W - slide`), so the slide boundary turns with everything else.
5. **Gate:** device held at 0°, 45°, 90° and 180°. Settings reads upright, swipes go toward the entity's right, and taps land on the control under the finger (tap every settings row at every angle). 60 fps at rest (damage) on the settings tile, at least 30 fps while turning, and text legible when turned.

### S3: Edges

- **Clock screen** (`accord/rabble_clock_screen.c`, a separate LVGL screen). Capture works for any LVGL screen, so composite it too and it turns as well. Then LVGL draws the panel natively only before the entity starts or on a board without direct mode.
- **Sleep and wake, long-press, the settings keypad** at a tilt.
- `set_direct` blocks LVGL for about one frame; with direct mode mostly always on it becomes rare. Confirm.
- **The old LVGL face** (canvas, `pose_entity`, `draw_entity`, about 400 lines of `rabble_ui.c`): keep it as the fallback for boards without direct mode, or remove it. Ask Mark.

### File ownership

| Files | Settings track | Clean room |
|---|---|---|
| `accord/rabble_ui.c`, `accord/rabble_entity.c/.h`, `components/nebula_lite/*` | S1 to S3 | readable by implementers; don't edit during S1 to S3 |
| `rabble_board.h` (seam; Meta-derived) | S1 adds the texture hook | W0 specs it **after S1 merges** |
| `bsp/rabble_lcd_bands.c/.h`, `bsp/bsp_waveshare_175b.c` (Meta-derived) | S1 capture | W6, last, its spec includes capture |
| `apache/*` except `rabble_board.h` and `rabble_settings_ui.c` | not touched | W1 to W4, any time after W0 |
| `apache/rabble_settings_ui.c` | not touched (orientation lives below it) | W5 |

Order: **S1 first** (one session), then S2 and S3 alongside clean room W0 and W1. The clean room's spec authors can start reading for W1 right away; nothing in W1 touches the settings track.

## Carry-overs from S251/S252 (lower priority)

- **Late bands:** not yet checked whether any band is sent after the panel's scan has passed it (tearing). Log each band's send time against its scan slot (TE period 16.7 ms, 466 rows) and look at the gadget while turning.
- **Idle headroom** is about 2.6 ms on core 1. Next costs: the turned glass sprites (3 to 7 ms while turning), small circles (about 7 ms of ellipses: a merged node primitive or pre-baked stamps), and the ~5 ms of driver overhead per full frame (a custom queued SPI path in W6 removes it: queue CASET/RASET/RAMWR as DMA transactions instead of polling).
- **Fonts** (Aether's are OFL): still deferred, Mark to decide.
- **Push:** `new-horizons` has S251 and S252 commits unpushed.

## Gotchas

- Keep `lcd_send` below LVGL in direct mode, and complete LVGL's flush in `queue_band` (now: after copying into the texture). Otherwise LVGL spins in `wait_for_flushing` and trips the watchdog.
- `lcd_send` has 6 KB of stack because the scene runs there; `lcd_help` has 4 KB and only renders bands.
- Between frames the claim counter is closed (`s_next = INT32_MAX`); a new frame sets the list, count and base before reopening it. Any new shared per-frame state (the texture pointer, slide) must be set before `s_next = 0`.
- The texture is read by both cores during a frame. Publish only between direct frames, or double-buffer as above; never write the front texture.
- The damage hash must include everything a band's pixels depend on. If the screen ever shows stale pieces, suspect a missing input in `band_hashes()` (`compose.c`) first.
