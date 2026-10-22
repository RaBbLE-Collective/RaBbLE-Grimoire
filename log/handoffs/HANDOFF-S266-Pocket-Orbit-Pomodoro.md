# HANDOFF-S266 · Pocket: Orbit v2 landing, Pomodoro next, then the BSP

> Written 2026-10-22 at the end of S266 for a cold start. Supersedes `done/HANDOFF-S265-Pocket-Capture-T5.md` (its open items are carried below).
> Read first: this file, then `RaBbLE-Pocket/cleanroom/w5-orbit.spec.md` (sections 1 to 4 = the Orbit as built, **section 5 = Orbit v2**), then `RaBbLE-Pocket/RaBbLE-Pocket-Roadmap.md` (the Applets + Pomodoro entry).

## Where things are

| Repo | Branch | State |
|---|---|---|
| RaBbLE-Pocket | `new-horizons` `80e4646` (+ Orbit v2 commits `%S266_ORBIT_V2%` if the sub-agent finished) | **nothing pushed** (49+ ahead of origin). `cleanroom` = same commit, retired: work on `new-horizons` |
| RaBbLE-Grimoire | `new-horizons` | committed, not pushed |
| RaBbLE-Collective | `new-horizons` | current-state block updated, not pushed |
| RaBbLE-sCoRE | `new-horizons` `663bc10` | unchanged (live on Render) |

Flashed on the gadget: `47adbb9` (W5 Orbit v1 + gyro + drift fix; `80e4646` only moved docs and scripts). Orbit v2 is not flashed yet.

## Done in S266

1. **Gyro on** (`rabble_qmi8658`, ours): 125 Hz, ±2048 dps; `rabble_board->imu_read_gyro`. "Up" is turned by the gyro every reading; gravity only pulls drift back. The face follows the spin (no lag, no jitter from 50 Hz steps), **holds its heading flat on a table** (spin it like a wheel: RaBbLE keeps facing where it was put down), shakes swing it on a **sideways spring**, spins lean the eyes and wind up dizziness by speed. Mark: "feels good", "fluid".
2. **Flat drift fixed**: this board's gyro sits **11 deg/s off on X** (0.203 / 0.079 / 0.026 rad/s). Stillness is judged from the accelerometer against its own short average (not 1 g: Z isn't levelled; not the gyro-turned up: its error skews that), the offset is learnt in ~3 s and kept in NVS (`rabble_motion/gbias`). Verified: 0.00 deg turned per 2 s flat.
3. **Colour ring in every view** (drawn over Settings/clock/level too): violet in Capture, yellow on low battery, red on error, dims while offline. **Mode icon** under the clock (speech bubble / record mark + note count; tap to switch). Mark: icons and ring "look good".
4. **W5, the Orbit** (clean-room redesign): Settings is a round dial drawn natively by nebula_lite. Spec written from Mark's calls, Opus-reviewed (7 blockers fixed), two fresh Sonnet implementers in `~/RaBbLE-Cleanroom/pocket-w5`, overlap 4.2%, audit clean, `apache/` deleted, PROVENANCE row written. 60 fps on Home idle and turning (~0.3 ms render).
5. **Merged** `cleanroom` into `new-horizons` (fast-forward). **third_party/** now holds all non-RaBbLE code (Waveshare demo repo, Meta SDK for the W6 overlap gate only, flash backups), gitignored but for its README.
6. Docs: W5 spec rev 1 to 3, Orbit plan page (Artifact `https://claude.ai/artifact/RJcigA73PkNWX4WYnyY8K9`), roadmap (Orbit, Applets + Pomodoro, SDK refactor), clean-room plan status, INDEX, PROVENANCE.

## Next, in order (Mark's order)

1. **Orbit v2 land** (in flight at handoff): a Sonnet sub-agent was building spec section 5 on `new-horizons` (flat quick ring, labels, next-step hints, an always-visible back chip, value mode that can't trap, touch glow + lit rim, **the NN mesh streams out and becomes the dial**). Check `git log --oneline -10` for `%S266_ORBIT_V2%` commits; if missing or partial, resume from the spec. Then: `sim/build.sh` (look at the PNGs), `firmware/test/cleanroom/w5/orbit_test/run.sh`, full build, flash, drive every page with `>orbit=` (open, turn:n, tap, hold, back, value:v, type:text, state), read the fps/late lines (gates: slide and drags ≥ 40 fps, rest 60), then Mark's hand check.
2. **Applets orbit + Pomodoro** (roadmap entry has the full design): swipe **right** from the face opens an Applets orbit (mirror of Settings, same renderer/gestures). Pomodoro: dial picks the length (25/5, long 15 after 4), hold the centre to start/pause, the colour ring drains as a violet (focus) / green (break) arc in every view, watchful face, chirp + happy at the end. Mark's watchdog picks: **fidget detection** (pick-up/shake/poke during focus: disapproving look + ring flicker, counts against the round) and **check-in nudges** (~10 min: chirp + glance, tap = "still on it", 30 s no tap = concerned).
3. **W6, the BSP, as Mark's walkthrough**: write `cleanroom/w6-*.spec.md` as a readable map of the board layer (`bsp_waveshare_175b.c`, `rabble_lcd_bands.c`), walk Mark through it and the other docs/specs, then a fresh implementer. Must keep "a frame is never held by a stalled helper core" (S264 freeze fix). Fold in: perf/stats logs opt-in (`>perf`; the 10 s stats line is a ~25 ms UART busy-wait from the panel task), steady 30 fps frame pacing when 60 can't hold, and delete `third_party/muse-gadget-sdk` once the gate passes.
4. **SDK refactor** (Mark, after W6): reorganise the Pocket firmware into clearer, more succinct components and modules (the gadget is one big `rabble_gadget/accord/` today: e.g. board, power, motion, audio/voice, net/beam, store, ui/face, orbit, console as their own components with small public headers). Plan it with Mark first.
5. Carried from S265: **T5** host offload spell `ops/pocket-notes.py pull [--prune]` (notes on the gadget wait), **T6** voice capture (tap/hold, offline ADPCM to `/pending/`), W4 hand checklist.
6. Later (Mark's list, not started): sCoRE voice persona (less ChatGPT, terse in Converse; the Converse prompt is the long chat persona + Grimoire gists + a tacked-on voice block on gpt-oss-20b), then agency slice 1 **"act on the Pocket"** (switch mode, start capture, timers by voice), then the robotic vocoder voice (Xperimental / BaBbLE v4) replacing Groq Orpheus.

## Gotchas you will hit

- **Serial**: one logger (scratchpad `serlog.py` pattern: append commands to `<log>.cmd`); `pkill -f "serlog.p[y]"` in its own call before flashing; opening the port resets the gadget; it re-enumerates ACM0/ACM1 and drops off USB when powered off.
- **zsh**: `grep` is a shell function in the Bash tool here: use `command grep`; unquoted `$var` doesn't word-split.
- **Frame rates**: read `rabble_entity`'s `fps`/`late frame` lines, not LVGL timers. Spin + dizzy is the heaviest scene (~31 fps floor); Mark's floor is 30 under load.
- **Taint**: S266 grep-read a few `bsp/` lines (IMU hookup, lcd_bands log lines): W6 spec author or integrator only, never implementer.
- **Gyro**: wakes take ~1.75 s to settle (gravity-only until then); stillness needs 0.5 s steady; the learnt offset is re-saved only when it moves > 0.005 rad/s (NVS writes from the motion task).
- **end-session.sh** drops older ledger rows sharing the breadcrumb id: back up `log/token-ledger.tsv`, run it, restore and append only the new row.
