# HANDOFF-S340 — RaBbLE TUI parity with Claude Code + Hermes (continue)

Date: 2026-11-15 · Repo: RaBbLE-sCoRE `new-horizons`, commit `55fe358` (TUI only). Goal (Mark): RaBbLE replaces Claude Code as the main agentic harness; no major CC feature missing, plus useful Hermes ideas.
Plan + feature gap list: `log/plans/RaBbLE-TUI-Harness-Parity-Plan.md`. Hermes scout: `/tmp/rabble-crew/hermes-investigation.md` (ephemeral; summary is in the plan).

## Done (committed, `cargo test -p rabble-tui`: 206 lib tests)
`/close` + `/open` (new session, screen kept) · RaBbLE thinking words + bloom spinner + shimmer in the divider (`src/thinking.rs`, `thinking_words.txt`) · `∴ thinking` blocks from `ThinkingText` (Ctrl-O expands) · TodoWrite checklist · message queue while a turn runs · `!cmd` local shell (output rides the next message) · bell + OSC 777 notify when unfocused · `/crew` roster, `/crew stop <name|all>`.

## Known test noise (pre-existing, not from this work)
- `the_entity_looks_at_streaming_text…` is flaky: glance RNG seeded from the wall clock (a fixed seed made it fail every run; needs a real look at the gaze timing).
- `a_face_frame_is_cheap_enough…` p99 16 ms limit trips under machine load (debug build).
- Never `git stash` in sCoRE: other sessions keep S339 `server/` WIP in the tree. Commit by explicit path.
- Offline cargo: run from `RaBbLE-sCoRE/tui/` (gitignored `.cargo/config.toml` is found from cwd).

## Next, in this order
1. **CC parity, TUI-only** (simple first): Ctrl-R history search · `/context` and `/cost` (usage data already in `usage.rs`/header) · `/export` transcript · `/permissions` + `/mcp` read-only viewers (Capabilities event has mcp + commands) · `/memory` and `#` quick-memory · `/init` · composer vim keys · `--continue` / `--print` flags on the binary (`plain.rs` exists) · image paste · background-task panel (Ctrl-B; `StopTask` exists).
2. **Needs engine work** (`orchestra/`): `/rewind` + Esc-Esc checkpoints (SDK file checkpointing + session fork) · `/diff` · `/btw` side question · `/branch`.
3. **Hermes borrowables** (MIT, docs only read): SKILL.md skills with approval queue · bounded MEMORY.md/USER.md + FTS5 session search · cron jobs with fresh agents · `/compress <focus>`. Each needs an Observer ruling before design (Anti-Assistant stance: memory/skills must be RaBbLE's own, sCoRE-hosted).
4. **Remote control**: works today via `ssh -L` of the engine socket + `rabble-tui connect --socket` (untested). Network listener + device pairing waits on accounts (`project_sCoRE_engine_hosting_identity`).
5. **Team management**: needs a real brainstorm with Mark (spawn/retask organs, per-organ model, approval queue, owner-only controls) before building.

## First moves
`head -20 log/SESSION-LOG.md`; read this + the plan; `cd RaBbLE-sCoRE/tui && cargo test -p rabble-tui`; pick item 1 top-down, one commit per feature or small batch; new Rust crates only from Fedora RPMs (manifest + layerctl).
