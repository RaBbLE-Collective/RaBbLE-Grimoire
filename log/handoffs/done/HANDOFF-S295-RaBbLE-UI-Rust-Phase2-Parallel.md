> **Status (S320, 2026-11-09): SUPERSEDED as the start point by HANDOFF-S296-RaBbLE-UI-Rust-Phase2-Next. Lane definitions (F, O, B) are still the reference.** Kept for reference, not deleted.

# HANDOFF-S295 · RaBbLE-UI Rust phase 2: shell, face, engine hardening, narration, supervision, all in parallel

> Written 2026-10-29 end of S295 for the next session(s). **Everything below is parallel; Mark has said face and shell are both go.** Claim your own session number first (`bash spells/session-number.sh claim <topic>`). Read in this order: this file, `../plans/sCoRE-RaBbLE-UI-Rust-Plan.md`, `HANDOFF-S295-RaBbLE-UI-Rust-R1-Seam.md` (protocol, identity/hosting constraints, R1 STATUS). Cargo setup: `HANDOFF-S295-RaBbLE-UI-Rust-R0-Cargo.md`.
> Models: builders `sonnet` (pin `model: "sonnet"` on every fan-out, it inherits otherwise), one `opus` reviewer per lane who did not write it. An Opus review of the plan + seam was run this session; its findings are below and are **not** yet fixed unless marked.

## State at handoff (everything committed except `rabble-theme`; nothing pushed)
- **Engine (Python, `RaBbLE-sCoRE/orchestra/`):** `serve.py` multi-session multi-client server (R1, live-verified), `config.py` engine config, `Capabilities`/`UserSaid`/`PermissionResolved` events (20 kinds). Tests: `~/.local/share/RaBbLE/rabble-ui/bin/python -m pytest -q tests/test_orchestra_*.py tests/test_ui_*.py -p no:cacheprovider` (119 + 64; 1 skipped).
- **Rust (`RaBbLE-sCoRE/tui/`, run cargo from `tui/` so `.cargo/config.toml` is found; `--offline`):** `rabble-proto` (typed Down/Up), `rabble-tui` (1:1 scroll spike, `replay`, `connect`, plain printer), `rabble-theme` (NEW, palette loader + `mix`, 4 tests, **uncommitted**), `rabble-face` (empty), `bench`.
- Decisions by Mark (do not relitigate): Python engine server + Rust clients, inside sCoRE; multi-client/session/agent/user; usage + entropy per session then per principal; provider profile = cost + capability (+ unverified privacy); accounts, identity ownership, pairing UNDECIDED; scroll = 1:1 instant like Vim/cat; narration templated first; free tier = Groq gpt-oss-120B + llama3 70B; privacy register deferred (blocker `hosting-gate`).

## The Opus review (S295): findings and who fixes them
Severity from the reviewer. Lane letters are defined below.

| # | Sev | Finding | Fix | Lane |
|---|---|---|---|---|
| 1 | BLOCKER | `set_permission_mode`, `set_trust`, `create_session{cwd,mode,trust,resume}` open to anyone with drive rights; a client-chosen cwd loads `.rabble/engine.json` (env, mcp_servers = arbitrary commands). Breaks "a guest never inherits trusted". Harmless while 1 OS user, fatal at first non-local listener. | Settings commands owner-only now; one `policy(principal, command, params) -> params|deny` hook on `create_session` (local stub allows all); never load a project `engine.json` for a non-owner. | P |
| 2 | BLOCKER | Late/restarted client gets no transcript (caps, started, entropy, usage, asks only): empty screen mid-turn. Claim "replaces /reload" is false. | `seq` on every session event, bounded ring buffer per session (events, by count and bytes), `attach{since_seq}`; `attached` carries `seq` + state snapshot. | P |
| 3 | SHOULD | Replayed `Usage` loses fields (`None` = unchanged overwritten). | Merge per field, not replace. | P |
| 4 | SHOULD | Ask list drifts: `interrupt` clears asks without `PermissionResolved`; any `TurnDone` (even a background organ's) clears all asks; `decision` not validated (a bad value broadcasts an event Rust cannot parse). | Treat `backend.permissions.pending` as truth, validate `decision`, broadcast resolved on interrupt, clear asks only when the pending set is empty. | P |
| 5 | SHOULD | Any engine exception kills the connection; `create` registers the session and starts the pump before `start()`, so a failed start leaves a zombie session forever. | Catch `Exception` per command, generic `Error` reply, log detail; register after `start()` succeeds. | P |
| 6 | SHOULD | No backpressure: a stopped client's queue grows (tool results up to 64 MB). | Byte-capped queue; on overflow send a notice and disconnect (client reattaches via `since_seq`). | P |
| 7 | SHOULD | Sessions never reaped; SIGTERM does not close backends (CLI children leak); ids `s{pid}-{n}` meaningless after restart; no mapping to the SDK id for resume. | Close all backends on shutdown; random ids; expose the SDK `session_id` in `attached`/`sessions`; document `create_session{resume}`; idle parking later via `park.py`. | P |
| 8 | SHOULD | Two engines starting together can both claim the socket; `close()` unlinks the other's; parent dir mode/owner not verified. | `flock` on `engine.lock` before checking/unlinking; verify dir is ours and 0700; unlink only our own inode. | P |
| 9 | SHOULD | Replies cannot be matched to commands; `UserSaid.sender` is the principal not the client; no "turn running / whose turn" state; `listing` shows creation-time model. | Optional `id` on every Up echoed on replies; `client` on `UserSaid`; `attached` snapshot: `busy`, `turn_owner`, `model`, `mode`, `trust`, running organs, `seq`. | P (+ proto) |
| 10 | SHOULD | Rust parsing is not forward-compatible inside a message: new value in `Decision`/`OrganStatus`/`LimitStatus`/`TurnOrigin`, non-string in `Capabilities.mcp`, or a new nullable makes the whole frame fail, silently dropped by `Client::next`. | `Unknown` variant on inner enums, `Map<String, Value>` for mcp entries, count + log unparseable lines. | P (rabble-proto) |
| 11 | SHOULD | Exact-match protocol version breaks every client on every bump, and Pocket firmware cannot upgrade with the engine. | Rule: additive changes never bump `version`; `hello` returns `features: [...]`; client refuses only below its minimum. | P |
| 12 | CONSIDER | The agent's own descendants are same-uid and can answer their own `PermissionAsk`. | Keep the peer pid; deny `answer`/settings from processes in a session CLI's process tree. | P (later) |
| 13 | CONSIDER | Smaller: "same answer exists vs denied" comment is false (`no such session` vs `not allowed`); no revoke; `LINE_LIMIT` 64 MB for commands (use ~1 MB up); stale `msg` read on the error path; `create` blocks the connection's other sessions; `connect --say --attach` stops on someone else's TurnDone. | Make the two error texts identical; add `revoke`; separate up/down limits; fix the stale variable; create in a task; match turn by request id. | P |
| 14 | CONSIDER | Plan contradicted decisions (T2 glide, frame loop); T2 had no number; engine SPOF + no supervisor; `serve.py` unused until R4. | **Fixed in the plan this session** (T2 restated as wheel input-to-paint p99 <= 2 ms; risks added). Supervisor and `RemoteBackend`: Lanes O and R. | docs done; O, R |

## The protocol freeze (Lane P delivers, everyone codes against this spec now)
All additive to v1 (so no version bump; `hello.features` advertises them):
- Per-session `seq` (int, starts at 1) on every message with a `session`; `attach{session, since_seq?}`; `attached{role, seq, snapshot}`. If `since_seq` is older than the ring buffer, the server replays a compacted state (as today's replay_to) and sets `gap: true`.
- Optional `id` (string) on every Up; replies and errors echo it. Events caused by a command carry no `id`.
- `UserSaid{sender, client, text}`, `snapshot{busy, turn_owner, model, mode, trust, organs[], sdk_session_id}`, `hello{version, engine, user, features}`.
- Rust: `Down` gains the new fields with `#[serde(default)]`, inner enums gain `Unknown`, `Up` gains `id`. Adding an event kind means all three of `orchestra/events.py`, `tui/rabble-proto/src/lib.rs` and `tests/fixtures/orchestra/all-events.jsonl` change together (the Rust test pins the kind count; the Python drift test pins the fixture). **Lane P owns those three files**; other lanes request additions from P or make the three-file change in one small commit and tell P.
- `Client` (Rust) splits into a reader thread and a writer handle (today one `&mut self` owns both halves), delivering frames on a channel. Lane S owns `client.rs`; P only specifies the wire.

## Lanes (disjoint ownership; all start now)
Workspace edits: each lane adds only its own crate/file lines; resolve `Cargo.toml` merges by keeping both.

### Lane P: protocol v1.1 + engine hardening (Python + `rabble-proto`) — sonnet, review opus
Owns: `orchestra/serve.py`, `orchestra/events.py`, `tests/test_orchestra_serve.py`, `tests/test_orchestra_events.py`, `tests/fixtures/orchestra/*`, `tui/rabble-proto/`. Do findings 1-13 above. More fixtures (record with `python -m orchestra.probe`): permission ask, error, park, MCP failure, organ turn with progress. A JSON-schema generator (`orchestra/schema.py`) is optional now. **Gate:** all review findings closed or explicitly deferred in the lane's commit message; new socket tests for: late attach mid-turn gets the transcript tail, ring overflow `gap`, stalled client disconnected and reattached, non-owner cannot change settings, failed start leaves no session, two engines racing the socket, bad `decision`.

### Lane S: the Rust shell (`rabble-tui`) — sonnet, review opus
Owns: `tui/rabble-tui/src/**` except `glide.rs`/`transcript.rs` spike code it replaces, `client.rs`, new `app/`/`widgets/`. Build on `rabble-proto`, `rabble-theme`, and the reader-thread `Client`. Start with what has no protocol dependency: event loop (1:1 input path, queued input drained, one paint, CSI ?2026), layout, composer (paste, history, multiline, slash completion from `Capabilities`), transcript (Markdown, tool cards with `[` in titles, user lines, notices, stuck-to-bottom follow with the 3-line slack and re-pin after blur/refocus), header, divider, permission modal (multi-client aware: dismiss on `PermissionResolved`), model and session pickers (`list_sessions`, `create_session`, `attach`), `/model /mode /trust /park /copy /face /clear /resume /status /help /quit`, theme from `rabble-theme` (no hex), `NO_COLOR`, `TERM_PROGRAM=vscode` safe glyphs, resize mid-frame, mouse capture (Shift+drag selects in kitty). Engine I/O never blocks the render thread. The Python UI tests (`tests/test_ui_app.py`, `test_ui_transcript_scroll.py`, `test_ui_permission.py`, `test_ui_prefs.py`, `test_ui_theme.py`) are the parity checklist: each behaviour gets a Rust test or an explicit "dropped, because". **Gate:** a full turn against the live engine (replay and a real haiku turn), T1 keystroke-to-paint p99 <= 8 ms idle, wheel p99 <= 2 ms on real content, parity checklist ticked.

### Lane F: the face (`rabble-face`) — sonnet, review opus (Mark's eye is the final gate)
Owns: `tui/rabble-face/`, `tests/golden_face.py` (dumper), `tests/fixtures/face/`. Pure functions, no terminal deps, input `rabble_theme::Palette`. Python reference: `ui/face.py` (1100 lines: `Canvas`, `Face.rig/frame/compose/layer/assemble`, `Life`, `degrade`, `EXPR`, `MOODS`, `provider_of`), `ui/eyes.py` (252). Order: `Canvas` + octant/safe/braille cells, then `rig` + `EXPR`/`blend_pose`, eyes/portals, mesh/orb/envelope/aura, layered compose, `Life`, `degrade`/noise, mini mark, then wiring a widget into the shell. Provider tint needs no new event: port `provider_of(model, local)`; the model arrives in `ModelUsed`/`SessionStarted` and `local` in `EntropyChanged`.
**Decision for Lane F with Mark's eye, recommended:** Python's decorative randomness (mesh layout, orb dust, glitch, blink/gaze `Life`) uses `random.Random` (Mersenne Twister), which Rust cannot reproduce without re-implementing Python's `random()/uniform/choice/sample`. Replace it in BOTH implementations with one small portable PRNG (SplitMix64 or xorshift64*, a ~15-line module `ui/prng.py` + `rabble-face/src/prng.rs`, with a shared known-answer test) so golden dumps match exactly. The mesh and dust patterns change slightly in Python; Mark confirms by eye. Alternative if Mark objects: dump the generated tables from Python and load them in Rust (loses the ability to vary the seed). Also: `mix` rounds half-to-even (done in `rabble-theme`); keep colour tolerance for float-order differences only.
Gate: golden tests (a fixed matrix of `(size, t, blink, gaze, pose, provider, noise, glyph mode)`, `test_rig_baseline` and `test_compose_matches_frame` carried over), T3 (eyes >= 30 fps at 260x70, background >= 15 fps, none of it on the input path), T4 (idle <= 5 % of a core with the face), T6 (cell aspect read from the terminal, kitty is 19x44 px = 2.32, sphere round), then Mark's eye. Also fix natively what Python could not: the dark stair-stepped halo and black portal fill (HANDOFF-S291 check 3), stray specks on the mini mark.

### Lane N: narration events (engine) — sonnet, review opus
Owns: `orchestra/narrate.py` (new), `orchestra/sdk_map.py`. Templated plain-English sentences keyed by tool name with argument extractors ("Reading `orchestra/events.py`", "Running the tests", "Asking the gobble organ to map the beam reconnect", "Waiting for your answer on a permission"; unknown tool falls back to "Using <tool>"). Stream `ThinkingText(organ, text)` from `thinking_delta` events (currently dropped: `sdk_map.py` only pulses `Thinking`), and make `thinking_display: "summarized"` the engine default once the fcc proxy models are checked (empty thinking is the default today, verified live). New event kinds go through Lane P's three-file rule. **Gate:** unit tests on the templates, a recorded fixture with thinking text, the Python UI shows narration lines (engine-side, minimal UI), Rust `plain.rs` prints them.

### Lane O: engine supervision and packaging (`RaBbLE-OS`) — sonnet, review opus
Owns: `RaBbLE-OS/ansible/roles/ai-harnesses/**`, `RaBbLE-OS/ansible/packages/manifest.yml`. A `systemd --user` unit for `python -m orchestra.serve` (`Restart=on-failure`, socket path under `$XDG_RUNTIME_DIR`), `cargo build --release` + link of `rabble-tui` into `~/.local/bin`, a `rabble --rs` switch (keep `rabble --py` one release). Any new crate needs its `rust-<crate>-devel` package in the manifest and the dnf list, **applied by Mark with `layerctl apply claude-code`** (never a live `sudo dnf`). **Gate:** `layerctl apply claude-code --check` clean, engine survives `systemctl --user restart`, clients reconnect and sessions resume via `create_session{resume}`.

### Lane B: bench and CI (`tui/bench`, `scripts/bench`) — sonnet or haiku, review opus
Owns: `tui/bench/**`, `scripts/bench/**`, a `tui/check.sh`. Add CPU %, RSS, cold start (T5 <= 100 ms), idle-with-face (T4), key-to-paint under load, the Python baselines side by side in one report; `check.sh` runs both suites (Python + `cargo test --release --offline`) so any lane can run one command. **Gate:** one command prints a table that fills the plan's targets row by row.

### Lane R (optional, recommended): `RemoteBackend` for the Python UI — sonnet, review opus
Owns: `orchestra/remote.py` (new, ~100 lines), `tests/test_orchestra_remote.py`. A `Backend` implementation that speaks the socket, so the existing Textual UI can run on `serve.py` now, exercising it daily and giving `/reload`-proof sessions before the Rust flip. Engine-side, fits the "no new Textual features" rule. Use it as the first real second client in the multi-client tests.

### Lane V: Opus review of each lane's diff before merge, never by the builder
Check the licence of every crate (MIT/Apache/BSD only), the 1:1 input path stays unblocked, no hex in code, and that nothing in the undecided list (accounts, tokens, pairing, hosted listener) is built.

## Cross-lane rules
- File ownership above is strict; if you need a change in another lane's file, ask (or make the smallest change and tell the owner in the commit message).
- `Cargo.lock` conflicts: regenerate with `cargo build --offline`.
- Before opening a PR-sized chunk: `tui/check.sh` (once Lane B lands it) or both suites by hand.
- Do not extend the ACL/grant code or add accounts/tokens/pairing until identity is designed (review finding 14; Mark's decision).
- No new Textual UI features; fixes and `RemoteBackend` only.

## Open for Mark (defaults taken unless he says otherwise)
1. Shared portable PRNG in Python and Rust for the face (recommended; mesh pattern shifts slightly).
2. `systemd --user` unit as the engine supervisor (recommended).
3. Lane R `RemoteBackend` now (recommended).
4. The provider privacy register stays deferred (blocker `hosting-gate`).

## Quick start
```bash
cd ~/RaBbLE-Collective
head -20 RaBbLE-Grimoire/log/SESSION-LOG.md && bash RaBbLE-Grimoire/spells/session-number.sh claim <topic>
bash RaBbLE-Grimoire/spells/mine.sh                      # which dirty files are yours (other sessions run concurrently)
cd RaBbLE-sCoRE && git log --oneline -8
~/.local/share/RaBbLE/rabble-ui/bin/python -m pytest -q tests/test_orchestra_*.py tests/test_ui_*.py -p no:cacheprovider
cd tui && cargo test --release --offline                  # run cargo from tui/
# engine + client by hand:
~/.local/share/RaBbLE/rabble-ui/bin/python -m orchestra.serve --socket /tmp/e.sock --replay ../tests/fixtures/orchestra/tool-turn.jsonl &
./target/release/rabble-tui connect --socket /tmp/e.sock --new --say "count the files"
```

## Gotchas
- Cargo finds `.cargo/config.toml` from the working directory, not `--manifest-path`: always `cd tui`. Crates come from Fedora RPMs; a missing crate means a manifest + `claude-code.yml` line and Mark's `layerctl apply claude-code`. crates.io is Securly-blocked on the school network: do not circumvent.
- `asyncio.Server.wait_closed()` waits for open connections on Python 3.12+: close client writers first in tests. The `Error` event's field is `text`, not `message`.
- Python `round` is half-to-even; Rust `f64::round_ties_even` matches (used in `rabble-theme::mix`).
- Real model turns cost tokens (a tiny haiku turn is about $0.002); tests use fixtures and `FakeBackend`. Run live checks sparingly.
- Concurrent sessions: stage with `bash RaBbLE-Grimoire/spells/mine.sh --paths <repo>`, never `git add -A`. `end-session.sh` ledger clobber (`94d4f7e8`) can recur: diff the ledger and LATEST before committing.
