# HANDOFF-S296 · RaBbLE-UI Rust phase 2: what landed, what Mark tests, what is left

> Written 2026-11-02 end of S296. Supersedes `HANDOFF-S295-RaBbLE-UI-Rust-Phase2-Parallel.md` as the place to start (that file still holds the lane definitions, the Opus review table and the protocol freeze; read it for Lane F, O and B). Claim a session number first: `bash spells/session-number.sh claim <topic>`. Cargo: run from `RaBbLE-sCoRE/tui/` with `--offline`. Models: builders `sonnet` (pin `model: "sonnet"` on every fan-out), one `opus` reviewer per lane who did not write it.

## What landed (all in RaBbLE-sCoRE on `new-horizons`, nothing pushed)
Every lane was built by a Sonnet agent and reviewed by Opus; each review's findings went back to the builder and the fix commit was re-verified by running both suites.

| Lane | Commits | Result |
|---|---|---|
| P protocol v1.1 + engine hardening | `8018033`, `a36f2fe` | seq + ring buffer + `attach{since_seq}` + gap, request `id` on replies/Error only (events keep their body `id`), owner-only settings, `policy()` hook, flock'd socket, byte-capped queues, random session ids, `hello.features`; `rabble-proto` forward compatible (`Unknown` variants, malformed frames kept) |
| N narration | `3743dd7`, `e6439d7` | `Narration` + `ThinkingText` events (22 kinds), `orchestra/narrate.py` templates with secret masking, thinking batched, `permissions.py` emits the wait line |
| R `RemoteBackend` | `f5588a9`, `3f6fccd` | `orchestra/remote.py`: Python UI's Backend over the socket; offline outbox, reconnect with `since_seq`, gap ask dedupe. **Not wired** to any flag |
| S Rust shell | `eb417b9`, `ff76f4d`, `c725873` | `rabble-tui`: threaded client, 1:1 event loop with CSI 2026, composer, Markdown transcript, permission modal, pickers, slash commands, prefs, park, auto-reconnect, `PARITY.md`, headless `bench`. Review blockers B1-B5 fixed (typing could answer a permission, asks hidden behind pickers, narrow-terminal panic, terminal left broken on panic/kill) |
| launcher | `7d4c01b` | `rabble` now opens the Rust shell: connects to the engine socket or starts the engine detached (`setsid nohup`, log in `~/.local/state/rabble/engine.log`). `--py` = Python UI, `--cc` = wrapper. Falls back if venv/binary missing |
| ansible warnings | RaBbLE-OS `cce5e69` | `ansible_facts[...]` for env/user_id/user_uid/product_name/processor_vcpus; empty `plans_server_disabled` group |

Tests at close: Python `tests/test_orchestra_*.py tests/test_ui_*.py` 237 passed, 1 skipped; Rust `cargo test --release --offline` 128 (`rabble-tui`) + 10 (`rabble-proto`) + 4 (`rabble-theme`). Measured (pty, release): key-to-paint p99 about 1.1 ms, wheel p99 about 1.0 to 1.6 ms; headless p99 0.2 ms.

## Mark tests the Rust shell (do this first)
`rabble` in any terminal. Check by hand: wheel feels 1:1; keep typing when a permission prompt appears (must not answer until about 400 ms after the last key; Esc denies); shrink the pane with a prompt open; `kill <pid>` leaves the terminal clean; stop and restart the engine (header `offline`, then reconnect); a second shell with `--attach <id>` or `/resume`. Findings go into the next session's first task.

## Open, in priority order
1. **Shell gaps:** narration lines not rendered by the Rust shell (`app.rs` has no `Narration` arm; Lane S's note that they show as Unknown is stale); organ colours are hashed, not the Crew persona colours; OS usage tracker (5h/week) missing from header and `/status`; after an engine restart session ids are gone (reattach gives an error notice; add fallback to a fresh session).
2. **Lane F, the face (`rabble-face`, empty):** blocked on Mark's go for the shared PRNG (SplitMix64/xorshift64* in `ui/prng.py` + `rabble-face/src/prng.rs`, known-answer test; Python mesh/dust shift slightly, Mark confirms by eye). Fallback: dump tables from Python. Slot reserved: `widgets::FACE_SLOT_WIDTH` (0).
3. **Lane O:** a `systemd --user` unit for the engine (today `rabble` starts it on demand, no restart policy), `cargo build --release` + link in ansible, packages: `rust-unicode-width-devel` and `rust-signal-hook-devel` may be needed on a clean machine (both build offline here from `/usr/share/cargo/registry`); Mark applies with `layerctl apply claude-code`, never a live `sudo dnf`. Uncommitted `RaBbLE-OS/ansible/packages/manifest.yml` and `roles/core/tasks/packages.yml` changes belonged to another session; check before touching.
4. **Lane B:** `tui/check.sh`, CPU/RSS/cold start (T5), idle-with-face (T4), Python baselines in one report. The `bench` subcommand in `rabble-tui` is the start.
5. **Wire `RemoteBackend`:** `--engine-socket` in `ui/__main__.py` around the `factory(resume, cont)` closure (about lines 55-66); `/reload` still creates a fresh session (needs attach to the existing id).
6. **Deferred review items:** Lane P finding 12 (deny answers from the CLI's own process tree, needs peer pid), idle session parking/reaping (`park.py`), park + MCP-failure fixtures (only `permission-turn.jsonl` and `narration-turn.jsonl` exist), `orchestra/schema.py`, `Error` replies lose their request id when decoded to an Event, total-reconnect cap in `RemoteBackend`, participant `allow_session` is a settings change by a non-owner (decide), `thinking_display: "summarized"` default (needs one tiny live haiku check against the fcc proxy models), organ `PermissionAsk` narration line never marked resolved.
7. **Opus re-check of the permission fixes (B1-B3)** in `c725873` was not run (rate limit nearly hit); the fixes were verified only by tests and the builder's pty checks. Worth one targeted review before the Rust shell becomes the daily driver.

## Gotchas learned this session
- zsh does not word-split an unquoted `$files`: use `xargs`. `grep --include=*.yml` needs quotes.
- Staging a whole directory (`git add ansible/roles`) swept in another session's file; stage explicit paths. Recovered with a soft reset of the unpushed commit.
- A Sonnet sub-agent's sandbox may refuse `/proc` scans to kill its own test engines: have it start engines under `timeout`.
- Concurrent lanes in one repo worked with explicit staging and per-lane commits; mid-edit builds fail transiently (`file not found for module`), re-run before believing a red result.
- A final Opus review died on the 5-hour limit and resumed cleanly with `SendMessage`; its work is saved.
- Decisions by Mark still stand (see the S295 handoff): Python engine server + Rust clients inside sCoRE; scroll 1:1 instant; narration templated first; privacy register deferred (blocker `hosting-gate`); accounts, identity ownership and pairing UNDECIDED, build none of them.
