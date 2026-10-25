# log/handoffs/CONTEXT.md

```
workspace: log/handoffs | epoch: 0
```

## What happens here

Cold-start handoff docs — written mid-session when work must pause and be resumed by a
fresh agent. One file per work thread. When the work is done, move to `done/`.

## Active (pending implementation)

| File | Scope |
|---|---|
| `HANDOFF-FCC-Free-Claude-Code.md` | FCC LiteLLM proxy tuning — research done, implementation pending |
| `HANDOFF-S236-OS-ISO-VM-Run.md` | RaBbLE-OS ISO: VM run passed S236, bare-metal retry passed S238; leftover open items inside (KS sudoers NOPASSWD revoke, GRUB secure-boot line, silent `%post`, Live ISO plan) |
| `HANDOFF-S234-EP1-Entity-Face.md` | EP1 face: W0–W2 done + live on dev; G10 sign-off pending; W4 accounts direction open |
| `HANDOFF-S268-Pocket-W6-Integrate.md` | Pocket W6: spec + firewall done, fresh Sonnet implementer running in `~/RaBbLE-Cleanroom/pocket-w6`; next integrate + checklist + overlap gate, config trims (Mark), then W7 and the RaBbLE-SDK (details still in done/HANDOFF-S267) |
| `HANDOFF-S275-RaBbLE-UI.md` | RaBbLE-UI plan written + SDK spike verified; next: Mark's deps/swap calls, then `orchestra/events.py` and parallel lanes |
| `HANDOFF-S273-Crew-Launcher.md` | RaBbLE Crew + `rabble` launcher built and unit-tested; first interactive team run, `layerctl apply claude-code`, colour promotion pending Mark |
| `RaBbLE-Voice-Phase2-HANDOFF.md` | Voice Phase 2 (authored 2026-07-03); the vocoder was rebuilt as v4 in S244, so check it before resuming |

## Done (reference only)

| File | Implemented |
|---|---|
| `done/HANDOFF-PreCommit-AntiClobber.md` | S185 |
| `done/HANDOFF-S116-Theme-and-Logging.md` | S116 era |
| `done/HANDOFF-S153-EP1-Coherence.md` | Production — B-01/03/04 resolved |
| `done/HANDOFF-S176-G10-World-EP1-FLOOR.md` | S177 — G10 closed (reopened S203 by the face redesign) |
| `done/HANDOFF-S203-B10-Cloudflare-Token.md` | B-10 resolved S206, B-12 S234 |
| `done/HANDOFF-S267-Pocket-CleanRoom-Final-SDK.md` | S268: W6 spec/firewall/implementer started; superseded by HANDOFF-S268 (its W7 list and SDK plan still current) |
| `done/HANDOFF-S266-Pocket-Orbit-Pomodoro.md` | S267: Orbit v2 landed; superseded by HANDOFF-S267 |
| `done/HANDOFF-S265-Pocket-Capture-T5.md` | S266: superseded (T5/T6 carried into HANDOFF-S266) |
| `done/HANDOFF-S264-Pocket-Capture-W4-Face.md` | S265: T3 store, T4 modes, sCoRE pushed (continues in HANDOFF-S265) |
| `done/HANDOFF-S252-Pocket-Settings-Orientation-Clean-Room.md` | S254 settings composited; clean room W0-W4 by S264 (continues in HANDOFF-S264) |
| `done/HANDOFF-S251-Pocket-Entity-60fps.md` | S252: 60 fps idle (both cores, damage-skipped bands, sparse mesh); settings slide carried into the S252 handoff |
| `done/HANDOFF-S250-Pocket-Entity-Port-Phase1.md` | S251 (Phase 1 renderer on device; superseded by S251 handoff) |

## Convention

`git mv log/handoffs/HANDOFF-FOO.md log/handoffs/done/HANDOFF-FOO.md` when work is complete.
Update `INDEX.md` and note the session it was implemented in.
