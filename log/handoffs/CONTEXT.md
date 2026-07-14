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
| `HANDOFF-S203-B10-Cloudflare-Token.md` | B-10: mint CF Workers token (dashboard-only) + org/Chrysalis `gh secret set` — Mark-gated, unblocks all CI deploys |

## Done (reference only)

| File | Implemented |
|---|---|
| `done/HANDOFF-PreCommit-AntiClobber.md` | S185 |
| `done/HANDOFF-S116-Theme-and-Logging.md` | S116 era |
| `done/HANDOFF-S153-EP1-Coherence.md` | Production — B-01/03/04 resolved |
| `done/HANDOFF-S176-G10-World-EP1-FLOOR.md` | S177 — G10 closed |

## Convention

`git mv log/handoffs/HANDOFF-FOO.md log/handoffs/done/HANDOFF-FOO.md` when work is complete.
Update `INDEX.md` and note the session it was implemented in.
