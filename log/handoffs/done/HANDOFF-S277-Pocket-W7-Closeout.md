# HANDOFF-S277 · Pocket: W6 done and merged; W7 close-out next, then the RaBbLE-SDK

> Written 2026-10-24 at the end of S277 for a cold start. Supersedes `HANDOFF-S270-Pocket-W6-Respec.md` (moved to `done/`). The W7 list is in `done/HANDOFF-S267-Pocket-CleanRoom-Final-SDK.md` section 2 (several items now done, see below); the SDK plan is `RaBbLE-Pocket/RaBbLE-Pocket-SDK-Plan.md` + `HANDOFF-S271-Pocket-Beam-SDK.md` (still current).
> Session number: this session's Pocket and Grimoire commits are tagged `%S276_W6R2%` (S276 was taken by the concurrent EP1 face session); the docs say S277.

## Where things are

| Repo | Branch | State |
|---|---|---|
| RaBbLE-Pocket | `new-horizons` `3b2c358` | W6 rev 2 merged (`2965c39` + `6c3b78b`). **Flashed: `6c3b78b`.** Not pushed (66+ ahead of origin) |
| RaBbLE-Pocket | `w6-integration-wip` `a3b436e` | parked rev 1, now obsolete; delete when Mark says |
| Clean workspace | `~/RaBbLE-Cleanroom/pocket-w6r2` | base `4a98aa5`, implementer `f180f13`, overlap rework `2f65075` |
| Transcripts | `~/RaBbLE-Cleanroom/transcripts/w6r2/` | `firewall.jsonl`, `implementer.jsonl`; on disk only (Mark: no repo) |
| Grimoire | | spec `RaBbLE-Pocket/cleanroom/w6-board.spec.md` rev 2; `PROVENANCE.md` W6 section |

## Done in S277

1. **Spec rev 2** of 6.3/6.4 from rev 1's gadget failures: nothing but `begin()` before the frame's TE edge, which edge belongs to a frame (incl. steady-30 and timeout), frames never overlap, no direct-to-task notifications / FromISR discipline / no task deletion, RAM budget with high-water marks, edge-to-band-0 timing in `>perf`. Opus firewall: approved with changes (its blocker: the notify assert isn't caused by notifying a blocked task; rule rewritten). All applied.
2. **One fresh Opus implementer round** (Sonnet failed five times on rev 1): new `bsp_bands.c` + `bsp_frame.c/.h` (frame logic behind hooks, so `firmware/test/cleanroom/w6/band_test/run.sh` runs the real code under ASan/UBSan). Overlap first run 11.4% with the original's private names for the send-task call objects and the PMU flag: sent back, reworked; now 10.5% overall, 7.0% band engine, every hit forced. Accepted.
3. **On the gadget:** display up 403 ms, ready 3.2 s (old 4.3 s), 594-600 frames / 10 s idle, steady 30 under voice load with helper rescues and no freeze, free internal heap 13,207 vs 13,315 old (3 boots each), no crash through voice turns, a voice note and sleep/wake. Mark: "feels great". Merged on his call.
4. **W7 items already done:** `bsp/LICENSE-APACHE` deleted; `firmware/NOTICE` lists no derived code; `third_party/muse-gadget-sdk` deleted (Mark), noted in `third_party/README.md` and `.gitignore`.

## Next, in order

1. **Watch items on W6** (merged ahead of them): the full 18a soak (10 min turning, Orbits, three voice turns, five sleep/wake) and the Orbit-slide side-by-side against the old layer (flash `6d26a76` for the A/B). Any tearing, top-edge dots or reboot: decode, then one-change diagnostic builds, failures to an implementer as behaviour only.
2. **W7 close-out**, from `done/HANDOFF-S267...` section 2, minus item 4 above: header sweep of every tracked file (17 C/H files plus CMakeLists, Kconfigs, `ops/*.sh`, `sim/*.sh`, `firmware/test/cleanroom/`, `hardware/cad/scripts/*.py`), reword the Apache/Muse mentions (`bsp/CMakeLists.txt` and `bsp/idf_component.yml` are already clean; check `firmware/CONTEXT.md` ("QSPI band flusher"), `firmware/README.md:3`, `components/rabble_gadget/idf_component.yml`), fix the six test scripts that still point at `components/rabble_gadget/apache` and rerun them, retire or rewrite `ops/cleanroom-overlap.py` (its SDK is gone), Grimoire doc updates (Gadget-Port, Muse-SDK-Map, clean-room plan status + `Done when` grep, PROVENANCE close-out + "RaBbLE's own from the start" table, roadmap). Gate: the "Meta Platforms" grep over tracked files is empty.
3. **Open W6 integrator items:** config trims (spec 8.3) and the console path (USB Serial/JTAG primary, UART0 off) need Mark's ok; the implementer's notes: TE interrupt is now off on the LVGL path (revert if anything misbehaves); if the direct path stays on while the panel sleeps, frames time out at 40 ms (render on a dark panel; spec says nothing).
4. Then the **RaBbLE-SDK** (S2 onward, `HANDOFF-S271`), and Mark's **Pomodoro hand check** whenever (swipe right, hold centre, `>pomo=skip`, back by swipe and chip).

## Gotchas (new in S277)

- **No serial logger survives sessions.** Write one into the scratchpad: one reader, a `.cmd` file for input, `!reset` toggling RTS to reboot (the USB port re-enumerates; boot logs still arrive). Opening the port did **not** reset the board this time. `pkill -f "serlog.p[y]"` in its own call; stop it before flashing.
- Heap A/B: compare the `rabble: ready: free heap N internal` boot line, same base, three boots each.
- Free internal heap after boot is now ~13.2 KB; the stacks keep 4,980 B (send) and 1,724 B (helper) unused (`>perf=on` prints them).
- `sed` across `MEMORY.md` or shared docs to renumber a session also hits other sessions' rows: scope it by line.
