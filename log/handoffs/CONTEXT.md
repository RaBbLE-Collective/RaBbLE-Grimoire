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
| `RaBbLE-Voice-Phase2-HANDOFF.md` | Voice Phase 2 (authored 2026-07-03); the vocoder was rebuilt as v4 in S244, so check it before resuming |

## Done (reference only)

| File | Implemented |
|---|---|
| `done/HANDOFF-PreCommit-AntiClobber.md` | S185 |
| `done/HANDOFF-S116-Theme-and-Logging.md` | S116 era |
| `done/HANDOFF-S153-EP1-Coherence.md` | Production — B-01/03/04 resolved |
| `done/HANDOFF-S176-G10-World-EP1-FLOOR.md` | S177 — G10 closed (reopened S203 by the face redesign) |
| `done/HANDOFF-S203-B10-Cloudflare-Token.md` | B-10 resolved S206, B-12 S234 |

## Convention

`git mv log/handoffs/HANDOFF-FOO.md log/handoffs/done/HANDOFF-FOO.md` when work is complete.
Update `INDEX.md` and note the session it was implemented in.
