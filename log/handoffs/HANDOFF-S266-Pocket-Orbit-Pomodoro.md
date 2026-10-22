# HANDOFF-S266 · Pocket: Orbit v2 landing, Pomodoro next, then the BSP

> Written 2026-10-22 at the end of S266 for a cold start. Supersedes `done/HANDOFF-S265-Pocket-Capture-T5.md` (its open items are carried below).
> Read first: this file, then `RaBbLE-Pocket/cleanroom/w5-orbit.spec.md` (sections 1 to 4 = the Orbit as built, **section 5 = Orbit v2**), then `RaBbLE-Pocket/RaBbLE-Pocket-Roadmap.md` (the Applets + Pomodoro entry).

## Where things are

| Repo | Branch | State |
|---|---|---|
| RaBbLE-Pocket | `new-horizons` `ba45af3` (Orbit v2 done: `16177a4` renderer, `cbdb0bc` controller, `ba45af3` sim fix) | **nothing pushed** (49+ ahead of origin). `cleanroom` = same commit, retired: work on `new-horizons` |
| RaBbLE-Grimoire | `new-horizons` | committed, not pushed |
| RaBbLE-Collective | `new-horizons` | current-state block updated, not pushed |
| RaBbLE-sCoRE | `new-horizons` `663bc10` | unchanged (live on Render) |

Flashed on the gadget: `47adbb9` (W5 Orbit v1 + gyro + drift fix). **Orbit v2 is built and tested on the host but NOT flashed yet.**

## Done in S266

1. **Gyro on** (`rabble_qmi8658`, ours): 125 Hz, ±2048 dps; `rabble_board->imu_read_gyro`. "Up" is turned by the gyro every reading; gravity only pulls drift back. The face follows the spin (no lag, no jitter from 50 Hz steps), **holds its heading flat on a table** (spin it like a wheel: RaBbLE keeps facing where it was put down), shakes swing it on a **sideways spring**, spins lean the eyes and wind up dizziness by speed. Mark: "feels good", "fluid".
2. **Flat drift fixed**: this board's gyro sits **11 deg/s off on X** (0.203 / 0.079 / 0.026 rad/s). Stillness is judged from the accelerometer against its own short average (not 1 g: Z isn't levelled; not the gyro-turned up: its error skews that), the offset is learnt in ~3 s and kept in NVS (`rabble_motion/gbias`). Verified: 0.00 deg turned per 2 s flat.
3. **Colour ring in every view** (drawn over Settings/clock/level too): violet in Capture, yellow on low battery, red on error, dims while offline. **Mode icon** under the clock (speech bubble / record mark + note count; tap to switch). Mark: icons and ring "look good".
4. **W5, the Orbit** (clean-room redesign): Settings is a round dial drawn natively by nebula_lite. Spec written from Mark's calls, Opus-reviewed (7 blockers fixed), two fresh Sonnet implementers in `~/RaBbLE-Cleanroom/pocket-w5`, overlap 4.2%, audit clean, `apache/` deleted, PROVENANCE row written. 60 fps on Home idle and turning (~0.3 ms render).
5. **Merged** `cleanroom` into `new-horizons` (fast-forward). **third_party/** now holds all non-RaBbLE code (Waveshare demo repo, Meta SDK for the W6 overlap gate only, flash backups), gitignored but for its README.
6. Docs: W5 spec rev 1 to 3, Orbit plan page (Artifact `https://claude.ai/artifact/RJcigA73PkNWX4WYnyY8K9`), roadmap (Orbit, Applets + Pomodoro, SDK refactor), clean-room plan status, INDEX, PROVENANCE.

## Next, in order (Mark's order)

1. **Flash and verify Orbit v2** (committed, host-tested: 719 logic checks, sim tests, full build). Contract grew (additive): item `label`, `label_r`, back-chip fields (`chip_*`), per-frame `glow_*`, `rim_lit`, `flick`. On the gadget: drive pages with `>orbit=` (open, turn:n, tap, hold, back, value:v, type:text, state), read fps/late lines (slide **with meshes** ≥ 40 fps is the open risk), then Mark's hands. Check specifically: label widths at 3/9 o'clock against the centre text and the back chip vs the hint line (the sim's wide font made Home look crowded), `LV_SYMBOL_LEFT` on the chip, the 2 s value-mode auto-exit, swipe-back from the rim's left half, the mesh-to-dial morph look (nodes fade while the dial fades in: may need tuning). Implementer decisions are in the v2 commits' messages.
2. **Faster wake from power-off** (Mark asked: "wake from power off or deep sleep" = a full boot). Measured: panel lit at **~2.7 s**, then the boot animation ~0.9 s. Biggest piece: a **1.2 s gap** between the CO5300 init (1250 ms) and touch (2450 ms) in `bsp/bsp_waveshare_175b.c` `display_start()`: candidates `esp_lv_adapter_init`, `panel_new` (reset/init, Espressif's managed CO5300 driver), `rabble_lcd_bands_register` (PSRAM textures), `bsp_touch_new` (CST9217 reset). Next step: temporary `BOOTTIME` timestamps after each of those steps (S266 wrote and reverted them unflashed), one boot, fix if ours, else note for W6. Config trims agreed in principle (apply with Mark's ok): `CONFIG_ESP_CONSOLE_UART_BAUDRATE` 115200 → 921600 (logs busy-wait the UART: also kills the ~25 ms stats hitch), `CONFIG_SPIRAM_MEMTEST=n` (~0.2 s), `CONFIG_BOOTLOADER_LOG_LEVEL_WARN`, `CONFIG_BOOTLOADER_SKIP_VALIDATE_ON_POWER_ON=y` (trade-off: no image check on cold power-on). Optional: boot animation 0.9 → ~0.5 s (ask Mark). Also tell Mark: auto power-off after 45 s asleep on battery (`CONFIG_RABBLE_POWER_OFF_S`, Settings "Off when asleep") is why wakes are full boots; sleep wake is ~0.13 s to drawing.
3. **Applets orbit + Pomodoro**: fully specified in `w5-orbit.spec.md` **section 6** (Grimoire `7fb0db3`): swipe right, Pomodoro page (25/5/15, holds), `rabble_pomo.c` timer on esp_timer, ring as a draining violet/green arc in every view (`ring_arc` inputs), watchful `focus` look, fidget detection and 10-min check-in nudges, `>pomo=` console with `skip`, host test.
4. **W6, the BSP, as Mark's walkthrough**: write `cleanroom/w6-*.spec.md` as a readable map of the board layer, walk Mark through it and the other docs/specs, then a fresh implementer. Keep "a frame is never held by a stalled helper core" (S264). Fold in: opt-in perf logs (`>perf`), steady 30 fps pacing when 60 can't hold, the boot-time findings from step 2, delete `third_party/muse-gadget-sdk` once the gate passes.
5. **SDK refactor** (Mark, after W6): split `rabble_gadget/accord/` into clear components (board, power, motion, audio/voice, net/beam, store, ui/face, orbit, console) with small public headers. Plan with Mark first.
6. Carried from S265: **T5** `ops/pocket-notes.py pull [--prune]`, **T6** voice capture, W4 hand checklist.
7. Later: sCoRE voice persona (terse, less ChatGPT), agency slice 1 "act on the Pocket", the vocoder voice.

## Gotchas you will hit

- **Serial**: one logger (scratchpad `serlog.py` pattern: append commands to `<log>.cmd`); `pkill -f "serlog.p[y]"` in its own call before flashing; opening the port resets the gadget; it re-enumerates ACM0/ACM1 and drops off USB when powered off.
- **zsh**: `grep` is a shell function in the Bash tool here: use `command grep`; unquoted `$var` doesn't word-split.
- **Frame rates**: read `rabble_entity`'s `fps`/`late frame` lines, not LVGL timers. Spin + dizzy is the heaviest scene (~31 fps floor); Mark's floor is 30 under load.
- **Taint**: S266 grep-read a few `bsp/` lines (IMU hookup, lcd_bands log lines): W6 spec author or integrator only, never implementer.
- **Gyro**: wakes take ~1.75 s to settle (gravity-only until then); stillness needs 0.5 s steady; the learnt offset is re-saved only when it moves > 0.005 rad/s (NVS writes from the motion task).
- **end-session.sh** drops older ledger rows sharing the breadcrumb id: back up `log/token-ledger.tsv`, run it, restore and append only the new row.
