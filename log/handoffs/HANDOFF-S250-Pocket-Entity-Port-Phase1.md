# HANDOFF S250: Pocket entity port, Phase 0 done, Phase 1 on device next

Cold start for the next agent. Plan: `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Port-Plan.md` (7 phases, one gate each). Repo: `RaBbLE-Pocket` branch `new-horizons` (pushed).

## State

- **Phase 0 done.** Bench `RaBbLE-Pocket/firmware/panel_bench/` (standalone IDF v6.0.1 project, reuses `../managed_components/espressif__esp_lcd_co5300`). Run: `ops/build-flash.sh firmware/panel_bench`, then read `BENCH` lines from `/dev/ttyACM0` (`stty -F /dev/ttyACM0 115200 raw -echo; timeout 90 cat /dev/ttyACM0`). Results table in the plan, Phase 0 section.
- **The board currently runs the bench, not the gadget.** Reflash the gadget with `ops/build-flash.sh firmware` when done.
- **Decisions the numbers support:** panel clock **80 MHz** (40 cannot reach 60 fps; 60 MHz rounds to 40); TE (GPIO13, 60.0 Hz) paces frames; chord windows at **16 to 32 row** bands (8 rows loses to command overhead); reset pin GPIO39.
- **Phase 0 gate: one open visual item.** Mark saw the bench run fine at 80 MHz: one screen noisy, light tears only. Not yet attributed to the app or the display. Check: at 80 MHz, which mode was noisy; rerun the same mode at 40 MHz (known-good clock) and compare; try the tear in a TE-paced mode with a slower frame. If noise is 80 MHz only, try drive strength (`gpio_set_drive_capability` on CLK and D0..D3) before giving up the clock.
- **Phase 1 skeleton exists on PC.** `firmware/components/nebula_lite/` (board-agnostic C: soft layer bake, 2x bilinear upscale, chord mask, rotated ring) and `sim/build.sh [gravity_deg]` (host harness, writes `sim/out/frame.png`). Host render is about 1 to 2.6 ms per frame; that is not a device number.

## Next (Phase 1 gate: background plus upscale under about 5 ms per frame on the device)

1. Link `nebula_lite` into `panel_bench` and add a mode that renders each band with `nl_render_band` and sends it chord-clipped, TE-paced at 80 MHz. Log render ms per frame (soft bake, upscale, total) with `esp_timer`, and fps.
2. Soft layer in internal RAM (106 KB); band buffers 2 x 30 KB internal. Render on core 1, send from core 0 (the bench is single-task today).
3. Replace the placeholder per-pixel `sinf`/`sqrtf` in `compose.c` with LUTs where the on-device numbers demand it; keep float32 only.
4. Wrap the bands into the LVGL custom widget (`entity_widget`) and `panel_flush` behind the HAL only after the bench numbers hold. `firmware/bsp/rabble_lcd_bands.c` is the existing PSRAM-band LVGL flusher and the base for `panel_flush`.
5. Then Phase 2 primitives (AA line, stamps, rotated ellipse SDF, A8 mask blit), each micro-benchmarked in cycles per pixel on the device.

## Gotchas

- Opening the USB console resets the board; a host that opens the port and stops reading stalls it. Read with `timeout cat`.
- zsh aborts a whole `ls` on an unmatched glob (`/dev/ttyUSB*`): that once made the board look absent. Check `lsusb` for `303a:1001`.
- Never `git add` a firmware project directory wholesale: `build/` and `managed_components/` are huge (an S250 commit did this once and was rewritten). `panel_bench` entries are gitignored now.
- SDL2 is not installed (host harness is headless on purpose). The interactive simulator needs it added through the Ansible manifest, not a live `dnf`.
- Rules that must survive the port are in the plan: no pupils, color poles opposite, portal front rims over orbs, geometry rotated not pixels.
