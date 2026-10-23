# HANDOFF-S271 · Pocket: Claude via the laptop node (P0/P1), SDK S1, orbs done

> Written 2026-10-23 at the end of S271 for a cold start. `HANDOFF-S270-Pocket-W6-Respec.md` stays current for W6.
> Read first: this file, `RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Pocket-Beam.md` (v0.3, §12 decisions, §13 plan, §14 review), `RaBbLE-Pocket/RaBbLE-Pocket-SDK-Plan.md` (v0.2).

## Where things are

| Repo | State |
|---|---|
| RaBbLE-Pocket `new-horizons` | `7fc004f` SDK S0, `a9f0799` + `e741ac4` orb fixes (hand-checked by Mark). **Flashed:** an export of `e741ac4` (firmware matches HEAD; version string has no git hash). Beam URL on the device: cloud `wss://rabble-score-x7qq.onrender.com/api/v1/beam`, connected. Not pushed |
| RaBbLE-Pocket `28da7fa` | **SDK S1 committed** (Sonnet agent): `sdk/rabble_core`, `sdk/rabble_lvgl_port`, `ops/sdk-layers.py --symbols` (core enforced clean), `firmware/test/paths.sh`. Builds, internal RAM -16 B, host tests identical before/after (6 scripts fail identically before and after: missing `esp_littlefs.h`/session-ticket decls in host builds, LeakSanitizer in battery 11b-d, `nebula_lite.h` path in input_test). **Not flashed yet:** flash + hand check (boot, face 60 fps, Orbit, voice turn) is the open S1 gate |
| RaBbLE-sCoRE `e56808a` | P0 + P1 + all §14 review fixes **committed, not deployed** (86 passed / 1 skipped: Mark runs `RUN_CLAUDE_SMOKE=1` once). Owner = sub `pocket`: Mark's own JWT/API key reaches CLI providers only via `CLI_ALLOWED_SUBS`. `server/test_api.sh` register calls 404 unless `ALLOW_REGISTER=true` |
| Laptop | S269 `:8000` sCoRE stopped. **firewalld `8000/tcp` in the public zone may still be open**: `sudo firewall-cmd --permanent --zone=public --remove-port=8000/tcp && sudo firewall-cmd --reload` (Mark) |

## Next, in order

0. **[DONE S272, `e6c287b`: mesh now anchored to its edge and stretches, no dial morph; Mark confirmed]** Mesh render bug on swipe-out (Mark, end of S271): the NN mesh misrenders when swiping back out of Pomodoro or Settings. Not yet seen by an agent: get a clip/photo first, then check whether it predates `a9f0799`/`e741ac4` (A/B flash `ac2e9f9`..`c698884` vs HEAD). Suspects in today's `scene.c` mesh_layer change: the leash (`MESH_HUG`, tightening over slide 0.6..0.85) and the Orbit-frame landing (`nl_orb_c/s` vs the entity turn while `ui_notch` blends back on the way out). **Still TODO (0b):** add a `>mem` console command (per-task stack high-water marks, internal/PSRAM free, largest block): internal RAM is 14.7 KB free after boot and Mark reports stack pressure.
1. Flash `28da7fa` and run the S1 device gate.
2. Mark: smoke test; firewall rule; Render env `DEMO_MODE_PUBLIC=true`, `SCORE_NODE_SECRET` (≥ 32 chars), leave `ALLOW_REGISTER`/`CLI_ALLOWED_SUBS` unset (World doesn't use register; without `DEMO_MODE_PUBLIC` cloud CORS closes and World breaks); then deploy sCoRE; create `~/.local/share/rabble/beam-context` (gists only, not in a git tree); run `python -m node_client`; talk to the Pocket.
3. Mark's decisions D1-D7 (beam spec §12) and SDK Q1-Q4 (plan §7).
4. SDK S2 onward (plan §5), W6 re-spec in parallel (HANDOFF-S270).

## Gotchas (new in S271)

- Opening `/dev/ttyACM0` resets the Pocket even with DTR/RTS low; console commands need the `>` prefix.
- When an agent is mid-refactor in the Pocket tree, build from an export: `git archive HEAD firmware | tar -x -C <scratch>`, copy `managed_components/`, `ops/build-flash.sh`, `ops/esp-idf-select.sh`, then `ops/build-flash.sh firmware` there.
- Commit single files with `git commit --only <path>` so an agent's staged `git mv`s stay out.
- Headless Claude: `--allowedTools` does not remove Read; `--tools` does (verified 2.1.309).
- The Orbit turns in 15° notches while the face turns with every tilt: anything placed across the two frames must convert through both turns (the S271 orb bug).
