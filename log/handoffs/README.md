# log/handoffs — Cold-Start Handoff Docs

Handoffs are plain-markdown docs written mid-session to enable a fresh agent to pick up
in-flight work without re-deriving context. One file per work thread.

## Status conventions

| Prefix/location | Meaning |
|---|---|
| `handoffs/HANDOFF-*.md` | Pending — implementation not yet done; read this before starting the work |
| `handoffs/done/HANDOFF-*.md` | Implemented — work is done; kept for historical reference |

When you complete a handoff, move it: `git mv log/handoffs/HANDOFF-FOO.md log/handoffs/done/HANDOFF-FOO.md`
and update `INDEX.md`.

## Active (pending)

| File | Scope | Status |
|---|---|---|
| [HANDOFF-FCC-Free-Claude-Code.md](HANDOFF-FCC-Free-Claude-Code.md) | Dev tooling — FCC LiteLLM proxy tuning | Research done, implementation pending |

## Done (reference only)

| File | Implemented |
|---|---|
| [done/HANDOFF-PreCommit-AntiClobber.md](done/HANDOFF-PreCommit-AntiClobber.md) | S185 |
| [done/HANDOFF-S116-Theme-and-Logging.md](done/HANDOFF-S116-Theme-and-Logging.md) | S116 era |
| [done/HANDOFF-S153-EP1-Coherence.md](done/HANDOFF-S153-EP1-Coherence.md) | Production — B-01/03/04 resolved |
| [done/HANDOFF-S176-G10-World-EP1-FLOOR.md](done/HANDOFF-S176-G10-World-EP1-FLOOR.md) | S177 — G10 closed |
