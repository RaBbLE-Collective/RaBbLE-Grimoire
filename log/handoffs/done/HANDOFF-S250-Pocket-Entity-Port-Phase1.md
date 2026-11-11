# HANDOFF S250: Pocket entity port, Phase 0 done, Phase 1 on device in progress

> **S251 update:** the rewrite was measured and replaced. PIE SIMD upscale plus a quarter-res haze layer: render 2.83 ms, 59.6 fps TE-paced while rotating (commits 9fbdee2, ae1485e). Steps 1 and 2 under "Next" below are done; results and remaining options are in the plan's Phase 1 section. Still open: steps 3 to 5 (core split, the noise check, HAL widget, Phase 2). The board runs `panel_bench`, which now ends in a turning demo loop.

Cold start for the next agent. Plan: `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Port-Plan.md` (7 phases, one gate each). Repo: `RaBbLE-Pocket` branch `new-horizons` (pushed).

## State

- **Phase 0 done.** Bench `RaBbLE-Pocket/firmware/panel_bench/` (standalone IDF v6.0.1 project, reuses `../managed_components/espressif__esp_lcd_co5300`). Run: `ops/build-flash.sh firmware/panel_bench`, then read `BENCH` lines from `/dev/ttyACM0` (`stty -F /dev/ttyACM0 115200 raw -echo; timeout 90 cat /dev/ttyACM0`). Results table in the plan, Phase 0 section.
- **The board currently runs the bench, not the gadget.** Reflash the gadget with `ops/build-flash.sh firmware` when done.
- **Decisions the numbers support:** panel clock **80 MHz** (40 cannot reach 60 fps; 60 MHz rounds to 40); TE (GPIO13, 60.0 Hz) paces frames; chord windows at **16 to 32 row** bands (8 rows loses to command overhead); reset pin GPIO39.
- **Phase 0 gate: one open visual item.** Mark saw the bench run fine at 80 MHz: one screen noisy, light tears only. Not yet attributed to the app or the display. Check: at 80 MHz, which mode was noisy; rerun the same mode at 40 MHz (known-good clock) and compare; try the tear in a TE-paced mode with a slower frame. If noise is 80 MHz only, try drive strength (`gpio_set_drive_capability` on CLK and D0..D3) before giving up the clock.
- **Phase 1 skeleton** `firmware/components/nebula_lite/` and `sim/build.sh [gravity_deg]` (host harness, writes `sim/out/frame.png`). Device numbers below.

## Phase 1 on device: first numbers (S250, before the rewrite)

Bench modes `NL ...` render with `nebula_lite` and send chord-windowed bands (`nl_band_window` + `nl_render_band(dst,y0,rows,x0,x1)`, output byte-swapped for the panel via `NL_SWAP_BYTES`). First run at 40 MHz, single task, flash-XIP code:

- Render about **100 ms per frame** (budget about 4 + 4 ms) and soft bake **130 ms** when the angle moves. 25x over. Cause: per-pixel `sinf`/`sqrtf`/divides and 12 multiplies per bilinear pixel on the LX7. Host timing (1 ms) was misleading, as warned.
- Task-watchdog backtraces in the log are the bench task starving IDLE0, not a crash. `CONFIG_ESP_TASK_WDT_CHECK_IDLE_TASK_CPU0=n` is now in the bench `sdkconfig.defaults`.

## Where the code is (commit 1b45192, `new-horizons`)

The hot paths were rewritten right after those numbers, and **the rewrite has NOT been run on the device**:

- Ring color: 256-entry LUT by angle (`nl_ring_lut`), index from the polynomial `nl_atan2`; no `sinf` per pixel.
- Soft bake: integer and LUT falloff (`nl_haze_lut`, `nl_rim_lut`), no divides, no libm per pixel.
- 2x upscale: SWAR RGB565 average (`avg565`), vertical blend into a soft-width row, then two outputs per soft pixel.
- Host check: `sim/build.sh` still renders the same picture (0.9 ms host).

## Next (Phase 1 gate: background plus upscale under about 5 ms per frame on the device)

1. Delete `firmware/panel_bench/sdkconfig` if present (it is gitignored), `ops/build-flash.sh firmware/panel_bench`, read `BENCH` lines. Look at the `NL ...` rows: `render_ms` and `bake_ms`. Run at 80 MHz (the 40 MHz block is for comparison; edit `clocks[]` to `{80}` to save time).
2. If render is still over about 4 ms: profile ring (atan per pixel: try a coarser angle LUT or per-row incremental angle), then `upscale_row`; consider calling `nl_soft_bake` spread over several frames (4 row-chunks per frame) instead of all at once; try `IRAM_ATTR` on `upscale_row` and the ring loop, and check instruction-cache misses (the bench does not use `CONFIG_SPIRAM_FETCH_INSTRUCTIONS`).
3. Then split cores: render on core 1, send from core 0 (the bench is a single task today), and confirm 60 fps TE-paced with render in flight.
4. Resolve the open noise/tear question (see State above) before locking 80 MHz.
5. Then `entity_widget` + `panel_flush` behind the HAL, then Phase 2 primitives, each micro-benchmarked in cycles per pixel on the device.

## Gotchas

- Opening the USB console resets the board; a host that opens the port and stops reading stalls it. Read with `timeout cat`.
- zsh aborts a whole `ls` on an unmatched glob (`/dev/ttyUSB*`): that once made the board look absent. Check `lsusb` for `303a:1001`.
- Never `git add` a firmware project directory wholesale: `build/` and `managed_components/` are huge (an S250 commit did this once and was rewritten). `panel_bench` entries are gitignored now.
- SDL2 is not installed (host harness is headless on purpose). The interactive simulator needs it added through the Ansible manifest, not a live `dnf`.
- Rules that must survive the port are in the plan: no pupils, color poles opposite, portal front rims over orbs, geometry rotated not pixels.
