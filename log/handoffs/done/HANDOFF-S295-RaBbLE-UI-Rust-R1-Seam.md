> **Status (S320, 2026-11-09): SUPERSEDED by HANDOFF-S295-RaBbLE-UI-Rust-Phase2-Parallel. R1 seam gate MET.** Kept for reference, not deleted.

# HANDOFF-S295 · RaBbLE-UI Rust: R1, the engine seam (the next split)

> Written 2026-10-29 end of S295 (this session's number was claimed late: first drafts said S293). R0 is done and committed; this is the next unit of work. Read in this order: this file, `../plans/sCoRE-RaBbLE-UI-Rust-Plan.md` (Architecture + Parity strategy), `HANDOFF-S295-RaBbLE-UI-Rust-R0-Cargo.md` (cargo setup, gotchas).
> Claim your own session number first: `bash spells/session-number.sh claim <topic>` (S294 was taken by a concurrent session while this one ran).

> **Superseded for next steps by `HANDOFF-S295-RaBbLE-UI-Rust-Phase2-Parallel.md`** (written after an Opus review of this protocol: it found 2 blockers, late-attach replay and owner-only settings, now scheduled there as Lane P).

## R1 STATUS (updated end of S295): the seam gate is MET; the rest of the split is open
**Built and committed (sCoRE `65fd3a1`, `da4dcbc`):**
- `orchestra/serve.py` (Lane A1): session-multiplexed multi-client engine server. NDJSON over a 0600 Unix socket; principal from `SO_PEERCRED` (never from a message); `SessionManager`; owner/participant/observer ACL with `grant`; first-answer-wins permission asks (`PermissionResolved`); attach replays caps/started/entropy/usage/open asks; sessions outlive clients; pluggable `Listener`; SIGTERM cleans the socket. `python -m orchestra.serve [--socket PATH] [--replay FILE]`. 9 socket tests (two clients, ACL, reattach, bad input, real `UnixListener`).
- New events `UserSaid` (so a second client sees what the first typed) and `PermissionResolved`; 20 event kinds total.
- `tui/rabble-proto` (Lane A2): typed `Down` (events + server replies) and `Up` (commands) enums, `Frame` with its session, tolerant of unknown types and fields (`Down::Unknown`), contract tests over every fixture. Strict round trip on `tests/fixtures/orchestra/all-events.jsonl` (generated from the Python `SAMPLES`; a pytest fails if it drifts), parse-only for older recordings.
- `tui/rabble-tui` (Lane B start): `rabble-tui replay FILE` and `rabble-tui connect [--socket P] [--attach ID | --new [--cwd D --model M]] [--say TEXT]`, plus the plain-text `Printer`. No args = the 1:1 scroll spike.
- **Verified live:** the Rust client created a session on a running Python engine, sent a message and printed the turn (replay fixture), and the same through the real `ClaudeCodeBackend` on a tiny haiku turn ($0.0024). A second client listed the session still alive after the first left. The live turn also showed `Capabilities` working: 69 commands, 30 skills, 6 MCP servers, two reporting `needs-auth` (`plan`, `claude.ai Google Drive`).

**Not done (next session starts here):**
- A3 schema: the generated JSON Schema from the dataclasses (`orchestra/schema.py`) was replaced for now by the fixture drift test; fine until a non-Rust client needs a schema.
- More fixtures: only `organ-turn`, `tool-turn` and `all-events` exist; record a permission ask, an error, a park and an MCP-failure turn with `python -m orchestra.probe`.
- Lane B proper: the shell (widgets, composer, transcript with Markdown and tool cards, header, divider, permission modal, pickers) on top of `Client`; the Client is blocking and single-threaded, so the shell needs its own reader thread handing frames over a channel. Keep the 1:1 input path.
- Lane C (face) and Lane D (CPU/RSS bench, narration events `ThinkingText`/`Narration`, templates in `orchestra/narrate.py`): untouched.
- Hardening: multi-client has no backpressure limit (a stalled client's queue grows); `claude_factory` builds the real backend from the `create_session` params (cwd, model, mode, crew, trust, resume, continue) but `provider` is carried and not yet used; no `ThinkingText` yet, so `thinking_display: "summarized"` data is requested but dropped by `sdk_map.py`.
- The Opus review of the plan and of this protocol is still owed.

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
- **Handshake:** client sends `{"type":"hello","version":1,"client":"rabble-tui","user":"<id>"}`; server answers `{"type":"hello","version":1,"engine":"<sdk+cli versions>","user":"<id>"}` or an `Error` and closes. A stale client refuses cleanly. `user` is reserved from day one (see Multi-everything); on the local socket it is the OS user.
- **Everything is addressed by `session` (decided by Mark: multi-client, multi-agent, multi-session, multi-user).** Every event down and every command up carries a `session` id (the session's `session_id`; `""` for engine-level messages). One connection can hold many sessions, and one session can have many attached clients. Engine-level commands: `list_sessions`, `create_session{cwd,resume,continue,model,mode,crew,trust,provider}`, `attach{session}`, `detach{session}`, `close_session{session}`. Per-session commands (one per `Backend` method, `orchestra/backend.py`): `send{text}`, `interrupt`, `answer{ask_id,reply}`, `set_model`, `set_permission_mode`, `set_trust`, `stop_task{task_id}`. Unknown command: reply `Error`, keep the connection.
- **Fan-out and who may answer:** every attached client sees every event for the session. A `PermissionAsk` goes to all attached clients; the first `answer` wins and the rest receive a resolved notice (add a `PermissionResolved` event). Input from two clients interleaves in arrival order; show the sender (`client` on the echoed user line).
- **Sidecar lifecycle:** sessions outlive clients, and the engine outlives them all. On `attach` the server replays cheap session state (`Capabilities`, `SessionStarted`/`SessionResumed`, current `EntropyChanged`, `Usage`, any open `PermissionAsk`) and then live events. This replaces `/reload` and fixes "UI crash loses the session". Idle sessions can be parked by the engine (`park.py`) and resumed on attach.
- **Backwards shape:** build `serve.py` around a `SessionManager` (id to `Backend` + attached clients), even though R1 only ever creates one session in tests. It is cheap now and a rewrite later.
- **Forward compatibility:** Rust deserialises unknown event types into an `Unknown` variant and ignores unknown fields (Python's `from_dict` already drops unknown keys).

## Multi-everything and the engine as orchestrator (Mark's end goal)
> "Multi-agent, multi-client, multi-session. One engine handles multiple users' sessions and agents. The end goal is to not have to think about sessions and resource planning, just a capability provider and a conversation with RaBbLE. RaBbLE + sCoRE handle orchestration and session management."

Reading of that, to confirm with Mark:
- **R1 scope (build now):** the session-multiplexed, multi-client protocol above on the local socket, one OS user, many sessions/clients/agents (agents already exist as Crew organs inside a session).
- **Reserved, not built:** `user` on hello and on sessions; per-user session lists; auth. A second human user means a different transport than a 0600 Unix socket. The natural home is the existing sCoRE server (`RaBbLE-sCoRE/server/`, auth tiers in memory `project_auth_tiers_web_local`: Web = demo, Local = BYOK/login). The engine should not hard-code the OS user as the only identity.
- **The orchestration layer (a later phase, call it E1, after R1 and R2):** the user picks a **capability provider** (which model/provider/tier, BYOK, local models via the existing fcc proxy) and just talks. The engine decides the rest: which session a message belongs to, when to spawn a Crew organ vs answer solo, which model per task, concurrency and budgets, parking and resuming, routing around rate limits. Inputs already in the engine: `entropy.py` (trust signal), `capabilities.py` (per-model capability by category), `park.py`, `usage.py` (provider windows), `trust.py`, and the Crew roster tiers. E1 is the session/resource planner on top of `SessionManager`; it needs a design doc and Mark's sign-off before code ("low entropy": do not scaffold what is not decided).
- **Principle to hold in review:** clients stay thin. Sessions, resource decisions and routing live in the engine, so the Rust TUI, a future GUI, the Pocket gadget and a web face are all the same kind of client.

## Identity, hosting and pairing model (Mark, S295): keep it flexible
> sCoRE must also become a **hosted service** for non-local users. The local version is one logged-in user with many sessions and tons of agents. sCoRE treats **web and local both as users**. A **Pocket device may or may not register as its own user.** A different user's Pocket can **use a RaBbLE-OS machine to compute without being that machine's user.**

That means four things must never be fused in the protocol or the engine, or each combination above becomes a rewrite:

| Concept | Meaning | Examples |
|---|---|---|
| **Principal** | who is acting and accountable | a local login, a hosted web account, a Pocket registered as its own user, a service |
| **Client / device** | the thing talking to the engine, on some transport | rabble-tui, a GUI, the web face, a Pocket over beam |
| **Session** | a conversation + its agents; has an **owner** and a **participant list** | one user's work; a shared session |
| **Compute provider** | whose resources run the model/tools | the user's own RaBbLE-OS box, sCoRE hosted, a paired machine, BYOK provider keys |

Design constraints for R1 (cheap now, expensive to retrofit):
1. **Identity comes from the transport, never from the message.** `hello.user` in the sketch above is a *claim only on trusted local transports*; the server derives the principal from the connection (Unix socket peer credentials locally, a bearer token over WebSocket/HTTPS, a device key for a Pocket). Messages never carry a self-asserted identity that the server believes.
2. **Transport is pluggable.** `serve.py` takes a `Listener` abstraction; R1 ships the Unix socket. The same NDJSON frames must run over a WebSocket later (hosted web and remote clients) and over the Pocket beam path (`/api/v1/beam`, voice-in/text-out, already live on the sCoRE server) with no change to events or commands.
3. **Sessions have an owner and an ACL**, not "the connected user". Actions are checked against the principal's role on that session (owner, participant, observer). Attach on a session you do not own is denied unless granted. This is what lets a second Pocket or a GUI join, and lets a stranger be refused.
4. **Pairing / delegation (undecided; placeholder).** If a Pocket may use another user's RaBbLE-OS machine, it should be a scoped, revocable grant from the machine's owner (what it may run, a cap, an expiry), not an account merge. The Pocket's user is the session owner and bills/limits against their own identity; the machine only supplies compute. Do not make "Pocket" a special user type; a Pocket is a device that holds a principal's credential or a lease. A Pocket with no account may use the default anonymous/guest principal at the demo tier (see memory `project_auth_tiers_web_local`: Web = demo tier, Local = BYOK/login).
5. **Compute provider is a session property, and it is how we know cost and capability** (Mark). `provider` on `create_session` names a provider profile; the engine reads two things from it: a **cost model** (price per token/call, plan windows, BYOK vs hosted vs local-free; `usage.py` already reads provider windows) and a **capability model** (per-model capability by category, `capabilities.py`/`entropy.py`). The orchestrator (E1) chooses a provider by weighing both against what the session needs. Sessions on a host machine are isolated from each other: separate working directories, permission scope and trust profile; a guest session never inherits the host's `trusted` level or files.
6. **Local-first stays the default (Collective rule).** The laptop offline runs the full loop with a local principal; hosted is deliberate, not required. The same engine binary serves local and hosted; only the listener and the auth provider differ.
7. **Usage and entropy are tracked per session first (Mark), and aggregated per principal.** The session is the unit that has a provider, a cost, a capability profile and an entropy score (already how `Entropy` works: one per session, carried across engine restarts). Principal-level totals and limits are sums over that principal's sessions, so a hosted service can enforce budgets without a second accounting system. Events like `Usage` and `EntropyChanged` are session-addressed.
8. **Privacy: no data retained by default.** The engine does not persist transcripts or content for hosted users beyond what the session needs to run, and deletion must be real. The actual guarantee depends on the **provider**, so it is a property of the provider profile (retention, training use, regions, deletion), recorded per provider and shown to the user. These guarantees are **not yet known** and need researching per provider (Anthropic API/plan terms, OpenRouter and the models behind it, Groq, local models via the fcc proxy, BYOK) before any hosted promise is made; treat "private, nothing retained" as a goal and a checklist item, never as a claim until each provider is verified in writing.

What R1 builds from this: the `Listener` abstraction, a `Principal` object on every connection (local peer credentials only for now), the owner/participant fields on `SessionManager` sessions with an enforced check, and room in the envelope for `session` + the server-assigned `principal` on events the clients see (who said this). Not built in R1, and **not yet decided** (Mark): accounts and identity ownership, pairing between devices and machines, the shape of any lease/delegation, tokens, the hosted listener. Each needs its own design doc and sign-off; the sketch under constraint 4 is a placeholder for how they could fit, not a design.

**Provider profiles to ship first (Mark, S295):** the free/demo tier runs on **Groq** with **gpt-oss-120B** and **Llama 3 70B** (memory `project_llm_provider_constraints`: sCoRE prod currently uses Mark's personal Groq key, temporary; Groq has request/token caps and blocks some email domains). These are the first two entries in the provider register, each with cost model, capability model and (unverified) privacy facts. The privacy research is **deferred as a blocker until real accounts exist** (ledger: `hosting-gate`, `deferred`); nothing may be promised as private before it is done.

Open questions for that design (not blocking R1): who owns identity and where principals live when hosted (the sCoRE server's current auth vs a separate store, against the Collective's own-accounts model in `RaBbLE-Secrets-and-Identity.md`); how devices and machines pair; whether a machine owner can share compute with a guest at all and on what terms (caps only vs credit/charge: undecided); and the **per-provider privacy and retention guarantees**, which need researching and writing down in a provider register before hosting anything.

## Lanes (disjoint files; builders `sonnet`, pin `model: "sonnet"` on every fan-out; an `opus` reviewer who did not write the lane)
| Lane | Owns | Work | Gate |
|---|---|---|---|
| **A1 server** (Python) | `orchestra/serve.py` (`SessionManager`), `orchestra/__main__.py` entry, `tests/test_orchestra_serve.py` | asyncio Unix-socket server over a `SessionManager` of `Backend`s (real `ClaudeCodeBackend` or `ReplayBackend` for tests); session-addressed protocol, handshake, command dispatch, multi-client fan-out, first-answer-wins asks, attach replay, engine config via `EngineConfig.load`; `python -m orchestra.serve [--replay FILE]` | pytest drives two socket clients through hello, create/attach, a replayed turn seen by both, one answering a permission ask, a detach and reattach |
| **A2 types** (Rust) | `tui/rabble-proto/` | serde `Event` enum for every class in `events.py` (including `Capabilities`), a `session` field on envelopes, `Command` enum (engine-level and per-session), `Hello`, `Unknown` fallback; contract test reading `tests/fixtures/orchestra/*.jsonl` | every fixture line parses and re-serialises to equal JSON |
| **A3 fixtures + schema** (Python) | `tests/fixtures/orchestra/`, `orchestra/schema.py`, generated `tui/rabble-proto/schema/events.schema.json` | record more turns with `python -m orchestra.probe` (only `organ-turn` and `tool-turn` exist): a permission ask, an error, a park, usage + entropy, a `Capabilities` init, an MCP failure; a generator that emits JSON Schema from the dataclasses so a drift test fails when `events.py` changes without the schema/Rust types | schema drift test in pytest; Rust test loads the schema |
| **B shell kickoff** (Rust) | `tui/rabble-tui/` | add `--replay FILE` (print events as plain text) then `--connect` (socket, `create_session`/`attach`); keep the R0 spike's scroll core (1:1 instant, `glide.rs` stays for keyboard paging/A-B) | prints a replayed turn; connects to `serve.py`; survives `serve.py` staying up while the client restarts |
| **C face** (Rust + Python) | `tui/rabble-face/`, golden dumper in `tests/` | independent of the seam, can start now: `Face.frame()`/`compose()` golden `(ch, fg, bg)` dumps over the matrix in the plan; Rust `eyes.rs`/`face.rs` against them. The face is the long pole and the real reason for the move | golden tests within tolerance |
| **D bench + narration design** | `tui/bench/`, plan | add CPU and RSS to the bench; **design the plain-English narration events** (Mark's ask, below) | design note for Mark |

A2 can start the moment the event list is frozen (it is: read `orchestra/events.py`). A1 and A3 can run in parallel with A2. B needs A2 for types and A1 for `--connect` (it can start with `--replay`). C and D share nothing with the rest.

## Crates (Fedora offline source; `tui/.cargo/config.toml` is already set up)
Each new crate needs its `rust-<crate>-devel` name in **both** `RaBbLE-OS/ansible/packages/manifest.yml` and the dnf list at the end of `RaBbLE-OS/ansible/roles/ai-harnesses/tasks/claude-code.yml`, then Mark runs `layerctl apply claude-code` (never a live `sudo dnf` from the agent). Checked available: `rust-tokio`, `rust-arc-swap`, `rust-rayon`, `rust-schemars0.8`. **Prefer `std::os::unix::net` + threads for R1**; the seam needs no async runtime. Check `dnf repoquery 'rust-<crate>*-devel'` for the version before pinning it in `Cargo.toml`, and keep every crate MIT/Apache/BSD.

## Mark's open asks for this track
1. **Plain-English narration while the model works. Decided (Mark): templated first.** Findings (checked live in S295): what Claude Code does is mostly templated too: tool cards show the tool name plus a one-line argument summary, a spinner verb shows activity, subagents carry a model-written short `description` and the SDK's `TaskProgressMessage` adds `last_tool_name`, and thinking text is only sent if you ask. **Thinking is empty by default** (verified with haiku: signature only, 0 characters, 2 deltas); with `thinking: {"type":"adaptive","display":"summarized"}` real summarized text streams as `thinking_delta` events (16 deltas, 128 characters, then one `ThinkingBlock`). rabble currently drops that text: `sdk_map.py` turns the lead's stream into a `Thinking` pulse and ignores the content. Plan:
   - **Done (S295):** `thinking_display: "summarized"` in `engine.json` (`orchestra/config.py`); one line in `~/.config/rabble/engine.json` turns it on today. Make it the default once a couple of providers are checked (models routed through the fcc proxy may not honour it).
   - **Events (Lane D design, before A2 freezes the Rust enum):** `ThinkingText(organ, text)` for streamed summary deltas, and `Narration(organ, text, kind)` for templated sentences ("Reading `orchestra/events.py`", "Running the tests", "Asking the gobble organ to map the beam reconnect", "Waiting for your answer on a permission"). Templates live in one table in `orchestra/narrate.py` keyed by tool name with argument extractors, so both UIs render the same words; unknown tools fall back to "Using <tool>".
   - **Later option, not now:** a cheap Haiku summariser over long thinking, only if templated plus summarized thinking is not enough.
2. **Claude Code parity, remaining tiers:** session control (`/compact`, `/rewind` via file checkpointing, fork-session, `/cost`, todo/plan display) and skills/plugins as first-class `/commands`. Config surface and `Capabilities` are done.
3. Still open from the plan: pixel-scroll spike (R5b), keep `rabble --py` one release (recommended), and the **Opus review of the plan, owed since S292** (do it before this split fans out). It should also review the multi-session protocol above.
4. **Confirm the multi-user reading** (local sessions/clients/agents in R1; `user` reserved; remote multi-user via the sCoRE server later) and when to write the E1 orchestration design.

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
