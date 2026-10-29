# HANDOFF-S295 · RaBbLE-UI Rust: R1, the engine seam (the next split)

> Written 2026-10-29 end of S295 (this session's number was claimed late: first drafts said S293). R0 is done and committed; this is the next unit of work. Read in this order: this file, `../plans/sCoRE-RaBbLE-UI-Rust-Plan.md` (Architecture + Parity strategy), `HANDOFF-S295-RaBbLE-UI-Rust-R0-Cargo.md` (cargo setup, gotchas).
> Claim your own session number first: `bash spells/session-number.sh claim <topic>` (S294 was taken by a concurrent session while this one ran).

## Where things stand
- **Shape settled (Mark):** Python engine stays as a non-user-facing server shared by every client; TUI, GUI and other native apps are Rust and talk to it; port only when needed; all of it inside `RaBbLE-sCoRE/`.
- **R0 done.** `RaBbLE-sCoRE/tui/` builds offline (`cargo test --release --offline`) from Fedora's packaged crates. **Scroll feel decided by Mark: 1:1 like Vim / cat** (instant whole-line steps, no easing); measured input-to-paint p99 0.74 ms. Live gate passed ("feels good").
- **Engine work landed this session:** the SDK `asdict` crash fix, `orchestra/config.py` (engine config surface), and the `Capabilities` event. The contract in `orchestra/events.py` is the thing R1 freezes into a wire protocol.
- Python UI (`rabble`, Textual) stays the daily driver until the R4 flip. Engine-side work is allowed; no new Textual features.

## R1 goal and gate
Put the engine on a socket and prove a Rust client speaks it. Gate (from the plan): **Rust parses every recorded event; Python round-trips every command; contract tests green on both sides**; plus a Rust `--replay FILE` mode that prints a replayed turn as plain text, and a live connect to a running engine that survives the client restarting.

## The wire protocol (decide in Lane A, record in the plan)
Proposed, for Mark to veto:
- **Transport:** Unix socket, mode 0600, at `$XDG_RUNTIME_DIR/rabble/engine.sock` (fallback `~/.local/state/rabble/engine.sock`). No TCP in R1.
- **Framing:** NDJSON, one object per line, UTF-8. Events down reuse `Event.to_json()` as is (`{"type": "<ClassName>", ...}`), so the recorded fixtures are already valid wire data.
- **Handshake:** client sends `{"type":"hello","version":1,"client":"rabble-tui"}`; server answers `{"type":"hello","version":1,"engine":"<sdk+cli versions>"}` or an `Error` and closes. A stale client refuses cleanly.
- **Commands up** (one per `Backend` method, `orchestra/backend.py`): `start{cwd,resume,continue,model,mode,crew,trust}`, `send{text}`, `interrupt`, `answer{ask_id,reply}`, `set_model`, `set_permission_mode`, `set_trust`, `stop_task{task_id}`, `close`. Unknown command: reply `Error`, keep the connection.
- **Sidecar lifecycle:** the engine outlives the client. On reconnect the server replays the cheap session state (`Capabilities`, `SessionStarted`/`SessionResumed`, current `EntropyChanged`, `Usage`, any open `PermissionAsk`) and then live events. This replaces `/reload` and fixes "UI crash loses the session".
- **Clients:** single client in R1; design the server loop so multi-client (a GUI beside the TUI) is an extension, not a rewrite. Ask Mark whether multi-client should be in scope now.
- **Forward compatibility:** Rust deserialises unknown event types into an `Unknown` variant and ignores unknown fields (Python's `from_dict` already drops unknown keys).

## Lanes (disjoint files; builders `sonnet`, pin `model: "sonnet"` on every fan-out; an `opus` reviewer who did not write the lane)
| Lane | Owns | Work | Gate |
|---|---|---|---|
| **A1 server** (Python) | `orchestra/serve.py`, `orchestra/__main__.py` entry, `tests/test_orchestra_serve.py` | asyncio Unix-socket server wrapping a `Backend` (real `ClaudeCodeBackend` or `ReplayBackend` for tests); handshake, command dispatch, reconnect replay, engine config via `EngineConfig.load`; `python -m orchestra.serve [--replay FILE]` | pytest drives a socket client through hello, a replayed turn, a reconnect |
| **A2 types** (Rust) | `tui/rabble-proto/` | serde `Event` enum for every class in `events.py` (including `Capabilities`), `Command` enum, `Hello`, `Unknown` fallback; contract test reading `tests/fixtures/orchestra/*.jsonl` | every fixture line parses and re-serialises to equal JSON |
| **A3 fixtures + schema** (Python) | `tests/fixtures/orchestra/`, `orchestra/schema.py`, generated `tui/rabble-proto/schema/events.schema.json` | record more turns with `python -m orchestra.probe` (only `organ-turn` and `tool-turn` exist): a permission ask, an error, a park, usage + entropy, a `Capabilities` init, an MCP failure; a generator that emits JSON Schema from the dataclasses so a drift test fails when `events.py` changes without the schema/Rust types | schema drift test in pytest; Rust test loads the schema |
| **B shell kickoff** (Rust) | `tui/rabble-tui/` | add `--replay FILE` (print events as plain text) then `--connect` (socket); keep the R0 spike's scroll core (1:1 instant, `glide.rs` stays for keyboard paging/A-B) | prints a replayed turn; connects to `serve.py`; survives `serve.py` staying up while the client restarts |
| **C face** (Rust + Python) | `tui/rabble-face/`, golden dumper in `tests/` | independent of the seam, can start now: `Face.frame()`/`compose()` golden `(ch, fg, bg)` dumps over the matrix in the plan; Rust `eyes.rs`/`face.rs` against them. The face is the long pole and the real reason for the move | golden tests within tolerance |
| **D bench + narration design** | `tui/bench/`, plan | add CPU and RSS to the bench; **design the plain-English narration events** (Mark's ask, below) | design note for Mark |

A2 can start the moment the event list is frozen (it is: read `orchestra/events.py`). A1 and A3 can run in parallel with A2. B needs A2 for types and A1 for `--connect` (it can start with `--replay`). C and D share nothing with the rest.

## Crates (Fedora offline source; `tui/.cargo/config.toml` is already set up)
Each new crate needs its `rust-<crate>-devel` name in **both** `RaBbLE-OS/ansible/packages/manifest.yml` and the dnf list at the end of `RaBbLE-OS/ansible/roles/ai-harnesses/tasks/claude-code.yml`, then Mark runs `layerctl apply claude-code` (never a live `sudo dnf` from the agent). Checked available: `rust-tokio`, `rust-arc-swap`, `rust-rayon`, `rust-schemars0.8`. **Prefer `std::os::unix::net` + threads for R1**; the seam needs no async runtime. Check `dnf repoquery 'rust-<crate>*-devel'` for the version before pinning it in `Cargo.toml`, and keep every crate MIT/Apache/BSD.

## Mark's open asks for this track
1. **Plain-English narration while the model works.** Today `Thinking(organ)` is a bare marker and tool cards show raw tool names. Mark wants the app to say what is happening in plain English and show more of the thinking. It belongs in the engine so every client shares it: a `Narration`/`Status` event from `sdk_map.py`. **Decide with Mark:** templated sentences from tool calls (free, instant, predictable) vs a cheap Haiku summariser over the thinking text (richer, costs tokens and latency). Recommended: templated first, summariser later as an option. Adding the event is a contract change: do it before A2 freezes the Rust enum, or add it as a follow-up with the schema drift test catching it.
2. **Claude Code parity, remaining tiers:** session control (`/compact`, `/rewind` via file checkpointing, fork-session, `/cost`, todo/plan display) and skills/plugins as first-class `/commands`. Config surface and `Capabilities` are done.
3. Still open from the plan: pixel-scroll spike (R5b), keep `rabble --py` one release (recommended), and the **Opus review of the plan, owed since S292** (do it before this split fans out).

## Quick start
```bash
cd ~/RaBbLE-Collective
head -20 RaBbLE-Grimoire/log/SESSION-LOG.md
bash RaBbLE-Grimoire/spells/session-number.sh claim <topic>
cd RaBbLE-sCoRE && git log --oneline -6
PY=~/.local/share/RaBbLE/rabble-ui/bin/python
$PY -m pytest -q tests/test_orchestra_*.py tests/test_ui_*.py     # 170 tests, ~1 min
cd tui && cargo test --release --offline && cargo run --release --offline -q -p bench
python3 bench/drive_latency.py /tmp/lat.csv                        # input->paint probe
```
`$PY orchestra/probe.py`-style commands and the fixture format: `python -m orchestra.probe` prints events as JSON lines (the same lines the wire carries).

## Gotchas
- Keep the R0 feel: wheel = instant whole lines, queued input drained before one paint, no timer on the input path (`rabble-tui/src/main.rs`). A render or engine call that blocks the loop breaks it; engine I/O goes on its own thread and hands events over a channel.
- SDK 0.2.174 runs `asdict()` on `agents` values and wants `AgentDefinition` objects (fixed in `ClaudeCodeBackend.options()`); a new SDK pin can change more, so run the engine tests after any bump.
- `ReplayBackend` splits turns at `SessionStarted`/`SessionResumed`/`TurnDone`; `Capabilities` is emitted just before `SessionStarted` so the grouping still holds.
- Textual reads `TEXTUAL_FPS` at import (full restart); Hyprland dispatch is Lua; zsh treats a bare `=====` as a command; ledger clobber `94d4f7e8` can recur in `end-session.sh` (diff the ledger and LATEST before committing).
