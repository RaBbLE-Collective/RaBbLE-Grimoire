# Pocket device baseline, firmware v0.1.3 (2026-11-18, S353)

Real device numbers, read passively over USB serial from Mark's 1.75b running the **shipped v0.1.3** (built Nov 18 09:54; no NeBuLA lite changes from the unification are on it). No flash. Opening the port resets the board (USB Serial/JTAG), so each capture begins with a boot. Logs: `pocket_hw-device-2026-11-18-pocket-idle.log`, `-pocket-states.log` (Wi-Fi name and MAC redacted). Parse: `parse_prof.py <log>`. The source line is `rabble_entity.c:327`, logged every 10 s.

`render A + B` is the per-frame render time on the two cores; A (the busy core) sets the frame rate. The panel is TE-locked at 60 Hz: above 16.7 ms on A the rate halves to 30, with no 45 step.

| Window (uptime) | What Mark did | fps | render A + B ms | prims | ellipse | line | ring | sprite | sim |
|---|---|---|---|---|---|---|---|---|---|
| 21.9 s, 32.0 s | idle | 60.1, 60.2 | 13.7 to 14.2 + 9.8 to 10.7 | 149 to 168 | 7.1 | 2.9 to 3.1 | 1.3 | 0.13 | 1.5 |
| 42.2 s | push-to-talk 36.7 to 41.5 s (listening), then the reply path | 30.6 | **27.4** + 20.4 | 566 | 7.8 | **7.4** | 2.6 | 4.0 | 3.7 |
| 52.4 s | after the turn, activity high | 30.2 | 23.4 + 19.8 | 307 | 7.5 | 8.5 | 2.7 | 5.1 | 2.4 |
| 62.6 s | Orbit drawer | 30.4 | 19.7 + 15.5 | 172 | 7.0 | 3.6 | 0.8 | 4.7 | 1.1 (swap 2.35) |
| 72.7 s | capture toggles 64.6 to 67.7 s (portal flip) | 31.0 | 19.7 + 15.1 | 200 | 7.0 | 5.4 | 1.8 | 3.5 | 2.0 |
| 82.9 to 113.3 s | rolling the device, then idle | 30.1 to 30.2 | 18.9 to 19.3 + 15.1 to 15.8 | 159 to 178 | 7.3 to 7.5 | 2.7 to 4.4 | **2.7** | **3.4** | 1.5 to 1.7 |

## Findings

1. **Idle sits at the budget line.** The busy core runs 13.7 to 14.2 ms at idle. Ellipses dominate at 7.1 ms (orbs 2.3, filled 2.5, hollow 2.3), then mesh lines (3 ms), sim (1.5 ms) and the ring (1.3 ms). There is about 2.5 ms of headroom.
2. **The device never returns to 60 after the first voice turn.** From 42 s to the end, even with idle prims (159 to 178) and activity near 0, it holds 30 fps. Sprites stay at 3.4 ms (from 0.13 ms) and the ring at 2.7 ms (from 1.3 ms), which together put about 4.7 ms on the busy core (19 ms, over 16.7). Suspects: the glass text sprites changed after the turn (the "saved note, 1 waiting" or offline status caption, re-rasterised or re-uploaded every frame), and a ring tint or drain-arc mode that stays on. **This is the first fix for ruling 12** (device never below 60): it is a stuck cost, not an effect that is too heavy.
3. **Listening is the heaviest state:** 566 prims, 27.4 ms. Lines (mic strands) reach 7.4 ms and sim 3.7 ms, which matches the host ranking (`pocket_hw-host-2026-11-18.md`: strands.mic first, then mesh.edges).
4. **Rolling could not be measured separately** because finding 2 already held the device at 30. Measure it again after that fix.
5. **No speaking or thinking data.** Wi-Fi never connected during the run (reason 201, network not found, signal -128), so the turn saved as an offline note and no reply played.
6. The capture stopped at 113 s of uptime, consistent with the 120 s screen-sleep setting.

## Next
- Find which sprite and ring state stay on after a voice turn (`rabble_entity.c` glass sprites, `nl_ring_tint`/`ring_arc` inputs), and fix it so the device returns to 60. Verify with the same passive capture after Mark flashes.
- Then cut listening below 16.7 ms: strands budget (fewer Catmull-Rom steps or one route, by registry `reduced` overrides) and mesh edges while listening.
- Calibrate host proxies against these numbers (`PROFILING-BUILD-SPEC.md`).
