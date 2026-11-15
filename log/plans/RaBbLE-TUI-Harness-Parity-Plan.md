# RaBbLE TUI: harness parity plan (Claude Code replacement)

Status: S340 draft for Mark's sign-off. Code: `RaBbLE-sCoRE/tui/rabble-tui/`, engine `RaBbLE-sCoRE/orchestra/`.

## Built this session (uncommitted, tests green: 201 lib tests)
- `/close` (close session, keep screen) and `/open` (new session below, screen kept; refuses while a session is open).
- Divider shows a RaBbLE thinking word (`src/thinking_words.txt`, ~70 phrases, rotates every 8 s) + bloom spinner + clock + the lead's current narration, with a shimmer sweep, instead of `working`.
- `ThinkingText` events render as a dim italic `∴ thinking` block (last 6 lines collapsed, Ctrl-O expands).

## Claude Code features the TUI lacks (checked by grep, not by running)
Missing: todo list panel (TodoWrite), `!` shell mode, image paste/attach, Esc-Esc rewind + checkpoints, `/rewind`, `/diff`, `/memory` + `#` memory, `/init`, `/config`, `/permissions` rule editor, `/mcp` manager, `/agents` manager, `/hooks`, `/context`, `/cost`, `/export`, Ctrl-R history search, queued messages while busy, background tasks (Ctrl-B) panel, desktop notification/bell on done or approval, vim keys in composer, output styles, custom status line, `--continue` / `--print` flags on the TUI binary (`plain.rs` exists for replay only).
Present: `@` path completion, bracketed paste, slash-command passthrough to the SDK (`/compact` etc.), `/resume`, mode cycling, crew panel, permission modal, usage in header, `/park`, selection copy.

## Asked for, not yet built (need Observer decisions)
1. **Remote control from another device.** The engine already serves many clients per session (attach/replay/roles, `grant`/`revoke`), but only over a local Unix socket with local-principal policy. Needs: a network transport + pairing/auth. Options: (a) SSH-forwarded socket (works today, zero new code, `rabble-tui connect --socket` over `ssh -L`), (b) engine WebSocket/TLS listener behind sCoRE account identity (matches `project_sCoRE_engine_hosting_identity`: identity from transport, device pairing). Recommend (a) now, (b) with accounts.
2. **Team management.** Crew panel shows state only. Wanted: spawn/stop/retask an organ from the TUI (`StopTask` exists on the wire), per-organ model tier, pause/approve queue, view an organ's transcript (exists: `/crew view`). Needs a ruling on which controls are owner-only.
3. **Hermes Agent**: not installed here; needs a look at its docs before choosing what to take (candidates to check: skill auto-creation/memory, multi-platform gateway, scheduled jobs).

## S340 update: parity batch 2 (built, uncommitted, 206 lib tests)
- Todo checklist from TodoWrite (one block at the bottom, active item in the divider).
- Message queue while a turn runs (sends as turns finish; Esc drops it; `N queued` in divider).
- `!cmd` runs a shell command locally (30 s cap), shows output, prepends it to the next message.
- Bell + OSC 777 desktop notification when the window is unfocused and a turn ends or an organ asks.
- `/crew` roster and `/crew stop <name|all>` (uses the existing `stop_task` wire command).
- Deferred: `/rewind` / Esc-Esc needs engine checkpoint support (SDK file checkpointing + session fork); not a TUI-only job.
- Remote control: use `ssh -L` forwarding of the engine socket + `rabble-tui connect --socket` now; network listener waits on accounts.

## Hermes Agent (MIT, github.com/NousResearch/hermes-agent) - scout report /tmp/rabble-crew/hermes-investigation.md
Docs-only read, no code. Borrowable: SKILL.md progressive disclosure + approval queue; bounded MEMORY.md/USER.md + FTS5 session_search; cron jobs with fresh agents; session tree (/branch, /rewind, /queue, /btw); /compress with focus topic. Its subagents match our Crew already.
