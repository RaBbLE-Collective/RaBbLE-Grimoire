# HANDOFF-S271 · Pocket: Claude via the laptop node (P0/P1), SDK S1, orbs done

> Written 2026-10-23 at the end of S271 for a cold start. `HANDOFF-S270-Pocket-W6-Respec.md` stays current for W6.
> Read first: this file, `RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Pocket-Beam.md` (v0.3, §12 decisions, §13 plan, §14 review), `RaBbLE-Pocket/RaBbLE-Pocket-SDK-Plan.md` (v0.2).

## Where things are

| Repo | State |
|---|---|
| RaBbLE-Pocket `new-horizons` | `7fc004f` SDK S0, `a9f0799` + `e741ac4` orb fixes (hand-checked by Mark). **Flashed:** an export of `e741ac4` (firmware matches HEAD; version string has no git hash). Beam URL on the device: cloud `wss://rabble-score-x7qq.onrender.com/api/v1/beam`, connected. Not pushed |
| RaBbLE-Pocket working tree | **SDK S1 by a Sonnet agent, uncommitted, unverified by S271** (`sdk/rabble_core`, `sdk/rabble_lvgl_port`, CMake, `ops/sdk-layers.py --symbols`, host-test path helper). Check its report items before committing: build, `ops/sdk-layers.py --enforce core --symbols` exit 0, host tests same counts as before, then flash + hand check (boot, face 60 fps, Orbit, voice turn) |
| RaBbLE-sCoRE working tree | P0 + P1 (`node.py`, `node_client.py`, auth guard, sandboxed Claude argv) + **review fixes by a Sonnet agent, uncommitted**. Last verified suite: 42 passed / 1 skipped before the fixes. Do not deploy until §14 items 1-4 are verified and Mark has run `RUN_CLAUDE_SMOKE=1` once |
| Laptop | S269 `:8000` sCoRE stopped. **firewalld `8000/tcp` in the public zone may still be open**: `sudo firewall-cmd --permanent --zone=public --remove-port=8000/tcp && sudo firewall-cmd --reload` (Mark) |

## Next, in order

1. Read both agents' results (working trees), run tests/builds, fix anything left, commit each repo separately.
2. Mark: firewall rule; Render env `DEMO_MODE_PUBLIC=true`, `SCORE_NODE_SECRET` (≥ 32 chars), plus register/CORS vars the fix agent lists; then deploy sCoRE; create `~/.local/share/rabble/beam-context` (gists only, not in a git tree); run `python -m node_client`; talk to the Pocket.
3. Mark's decisions D1-D7 (beam spec §12) and SDK Q1-Q4 (plan §7).
4. SDK S2 onward (plan §5), W6 re-spec in parallel (HANDOFF-S270).

## Gotchas (new in S271)

- Opening `/dev/ttyACM0` resets the Pocket even with DTR/RTS low; console commands need the `>` prefix.
- When an agent is mid-refactor in the Pocket tree, build from an export: `git archive HEAD firmware | tar -x -C <scratch>`, copy `managed_components/`, `ops/build-flash.sh`, `ops/esp-idf-select.sh`, then `ops/build-flash.sh firmware` there.
- Commit single files with `git commit --only <path>` so an agent's staged `git mv`s stay out.
- Headless Claude: `--allowedTools` does not remove Read; `--tools` does (verified 2.1.309).
- The Orbit turns in 15° notches while the face turns with every tilt: anything placed across the two frames must convert through both turns (the S271 orb bug).
