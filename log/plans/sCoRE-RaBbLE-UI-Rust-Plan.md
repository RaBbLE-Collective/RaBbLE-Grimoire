# RaBbLE-UI in Rust (R4): plan

> Status: **proposed, S292 (2026-10-29).** Mark chose Rust ("Python is not fast enough: snappy, native, fluid"). The shape in "Architecture" is RaBbLE's recommendation and needs Mark's sign-off before R1; the R0 spike is safe under any shape.
> Parent plan: `sCoRE-RaBbLE-UI-Plan.md` (roadmap items R1, R3, R4, R11). This plan **retires R3** (a face render server only existed to dodge the GIL; Rust threads do not have one).
> Cold start: `../handoffs/done/HANDOFF-S295-RaBbLE-UI-Rust-Phase2-Parallel.md` (the parallel phase-2 plan; R0 cargo setup in `HANDOFF-S295-RaBbLE-UI-Rust-R0-Cargo.md`). **S295: Mark confirmed Option A (Python engine stays, a non-user-facing server shared by native clients) and `tui/` inside sCoRE; open questions 1 and 2 below are settled.**

## Why Python stopped being enough (measured S291 to S292)

| Measure | Value | Source |
|---|---|---|
| Eye layer at fullscreen | 10 to 16 repaints/s (one costs 10 to 65 ms) | S291 headless, 120x40 to 260x70 |
| Event-loop lag with the full face at 200x55 | p95 53 ms, max ~120 ms; **p95 23 ms after caching `Style` objects**, spikes to ~70-100 ms remain | `RaBbLE-sCoRE/scripts/bench/ui_loop_lag.py`, S292 |
| Where the loop time went | `render_line` 1.87 s of 3.9 s (per-run `Style`/`Color` construction); eye `sample`/`shade` on the thread compete for the GIL | `scripts/bench/ui_face_profile.py`, S292 |
| Running instances, idle on the face | 20 to 42 % of a core, 147 to 204 MB RSS | `ps`, 3 live `rabble` processes |
| Screen update ceiling | Textual caps at 60 fps (`TEXTUAL_FPS`, read at import) | S292, raised to 120 in `ui/__main__.py` |
| Terminal cell | kitty 19 x 44 px: **aspect 2.32, not the 2.0 the face assumes** (R11 numbers) | `TIOCGWINSZ` on the kitty ttys |

Shortening the thread switch interval improved the median lag but not the tail: the tail is the lock. No amount of Python tuning removes it.

## Targets (the gate numbers)

| # | Target | Python today |
|---|---|---|
| T1 | Keystroke to painted echo, p99 **<= 8 ms idle, <= 16 ms with the face running** | p95 ~23 ms lag before any paint |
| T2 | Wheel scroll is **1:1 like Vim / cat (Mark, S295)**: **wheel input-to-paint p99 <= 2 ms** (measured with `tui/bench/drive_latency.py`; S295 spike: p99 0.74 ms), whole-line steps, no easing, transcript frame <= 4 ms. (The 120 fps glide target is retired; the glide stays only for keyboard paging.) | 60 fps cap, notched, eased |
| T3 | Face fullscreen (260x70): eyes **>= 30 fps (goal 60)**, background >= 15 fps, none of it on the input path | eyes 10 to 16/s |
| T4 | Idle with the face: **<= 5 % of one core**, RSS <= 60 MB | 20 to 42 %, 147 to 204 MB |
| T5 | Cold start to first paint <= 100 ms | not measured |
| T6 | Cell aspect read from the terminal, sphere round at any aspect | no correction (R11) |

Targets are measured by one bench harness (R0), run against the Python UI first so the comparison is real.

**R0 measurements (S295, headless, this laptop; Rust built offline from Fedora's packaged crates):**

| Measure | Python (Textual) | Rust (ratatui) | Target |
|---|---|---|---|
| Wheel glide, screen updates delivered in 1 s burst, 196x50 | 22/s at `TEXTUAL_FPS=60`, 33/s at 120 (`scripts/bench/ui_scroll_fps.py`) | 120 Hz clock, not yet measured live | T2: 120/s |
| Transcript frame cost (render + buffer diff), p99 | not isolated (a Textual frame also pays layout and compositing) | **0.12 ms at 120x40, 0.16 ms at 200x55, 0.11 ms at 260x70** render; diff 0.10 to 0.22 ms | <= 4 ms |

The headless Rust number is the cost of building a frame, not of the terminal presenting it. **Scroll feel decision (S295, Mark):** the glide passed but "still feels off"; he wants the **1:1 response of Vim, `cat` and other CLI programs**. Wheel scrolling is therefore **instant line steps, no easing, no timer**: an input event repaints on the same loop turn, queued input is drained first so a burst costs one paint. Glide stays in the spike as modes 2 and 3 (A/B keys) and may serve keyboard paging only. Measured (pty, 200 wheel events 8 ms apart plus 800 queued): **input to paint p50 0.41 ms, p99 0.74 ms, max 0.80 ms** (`tui/bench/drive_latency.py`); T1 asks <= 8 ms. Kitty presents on its own cadence after that, same as Vim.

**T2 live gate (S295): PASSED by feel.** Mark ran the spike on kitty: "feels good!!!" (no frame log captured, so no dropped-frame count; `--log` is there if a number is wanted). The earlier note, for reference: the live run on kitty (`cd tui && cargo run --release --offline -p rabble-tui -- --log /tmp/glide.csv`, scroll, q; then inspect frame gaps in the log) and Mark feeling the glide.

## Architecture (proposed)

```
RaBbLE-sCoRE/
  orchestra/            Python engine (unchanged logic) + NEW serve.py: NDJSON over a Unix socket
  ui/                   Textual UI: stays as `rabble --py` until the flip, then retired
  tui/                  NEW Cargo workspace
    rabble-proto/       event + command types, serde, contract tests against recorded fixtures
    rabble-face/        eyes + face raster (no terminal deps), parity-tested against Python
    rabble-tui/         the binary: render loop, widgets, input, theme
    bench/              frame-time and latency harness
```

**Option A (recommended): Rust UI + Python engine sidecar.** The engine (`orchestra/`, ~2.1k lines: backend, entropy, capabilities, park, trust, usage, sessions) is correct, tested and **not on any hot path**; the Claude Agent SDK is Python/TS. The seam already exists: `orchestra/events.py` is a normalized event contract and `Backend` is a 10-method protocol (`start, events, send, interrupt, answer, set_model, set_permission_mode, set_trust, stop_task, close`). `serve.py` puts that on a socket as NDJSON: events down (one JSON object per `events.py` dataclass, tagged by class name), commands up (one per Backend method, plus `hello{version}`). Side effects: the engine **survives a UI restart**, so a crash or rebuild of the UI no longer loses the session (replaces `/reload`).

**Option B (later, Mark's call): port the engine too**, speaking `claude --input-format stream-json --output-format stream-json --permission-prompt-tool stdio` directly (the protocol the SDK wraps; visible in `ps` today). Removes Python entirely, but means re-porting entropy/capability/park/trust and re-tracking CLI protocol changes. Not before the UI is flipped; revisit once R4 is done.

**Rejected: embedding Python via PyO3.** It reintroduces the GIL inside the process we are trying to free.

### Engine end state (Mark, S295)

Multi-client, multi-session, multi-agent, multi-user from the protocol up: one engine process, many sessions (each with many attached clients and its own Crew organs), every message addressed by `session`. The user picks a capability provider and converses with RaBbLE; RaBbLE + sCoRE own orchestration, session management and resource planning (model/provider choice per task, concurrency, budgets, parking, rate-limit routing) in the engine, so every client (Rust TUI, a GUI, Pocket, web) stays thin. R1 builds the session-multiplexed seam (`SessionManager`); the orchestration layer (E1) needs its own design and sign-off. **Roadmapped (Mark, S307):** a harness-level cap on Crew organ spawns (organs per wave, waves per job, concurrent organs) belongs to E1 and is enforced in the engine; until then the persona rules in `RaBbLE/Crew/rabble.md` are the only limit. Details: `../handoffs/done/HANDOFF-S295-RaBbLE-UI-Rust-R1-Seam.md`.

**Hosting and identity (Mark, S295):** the same engine must also run as a hosted sCoRE service for non-local users; web and local are both users; a Pocket may or may not be its own user; one user's Pocket can lease compute from another user's RaBbLE-OS machine without being that machine's user. So the protocol separates principal, client/device, session (owner + participants) and compute provider; identity comes from the transport, never from the message; transports are pluggable (Unix socket first, WebSocket and the Pocket beam path later). The compute provider is how cost and capability are known; usage and entropy are tracked per session and rolled up per principal; hosted data should not be retained, but the real guarantee is per provider and still has to be researched. Accounts/identity ownership and pairing are **undecided**. Constraints and open questions are in the R1 handoff.

### Frame loop

- One thread owns the terminal and draws; it never waits on the engine or the face.
- Input thread (crossterm event stream, kitty keyboard protocol where available, SGR mouse), engine I/O on tokio, face workers on their own threads (background layer, eye layer; `rayon` row bands for the heavy eye raster).
- Face frames cross to the render thread by a lock-free latest-value slot (triple buffer or `ArcSwap`), so a slow eye paint costs a stale eye, never a late keystroke.
- **Synchronized output (CSI ?2026)** around every frame: no tearing, and the terminal can present on its own cadence.
- Draw on a dirty flag, capped at 120 Hz; only changed cells are written (ratatui's buffer diff, with the face writing straight into the buffer).
- Scroll: **1:1 instant whole-line steps on the input event, no timer and no easing** (Mark's decision, S295; see the scroll-feel note under Targets). Queued input is drained before one paint. The float-position glide in `rabble-tui/src/glide.rs` (ported from S292) is kept for keyboard paging and A/B only.
- Cell aspect from `TIOCGWINSZ` pixel size (override `RABBLE_CELL_ASPECT`); the face scales y by it. Solves R11 at the source.
- Hard limit to say out loud: cells are 44 px tall in kitty, so the transcript moves in whole-line steps. Evenly timed line steps at 120 fps is as smooth as a cell grid gets. **Pixel-smooth scrolling needs the kitty graphics protocol (transcript rendered to a bitmap)**; that is a separate, optional spike (R5b), not assumed.

### Crates (all must be permissive; run a license check as a gate, no copyleft)

`ratatui`, `crossterm` (MIT) · `tokio`, `serde`, `serde_json` (MIT/Apache) · `pulldown-cmark` (MIT) for Markdown · `syntect` (MIT) for code highlight · `unicode-width`, `unicode-segmentation` · `rayon` · `arc-swap`. Clipboard via `wl-paste`/`wl-copy` subprocess (as today), not a crate.

## Phases (vertical slice first, per Collective rules)

| Phase | Work | Gate |
|---|---|---|
| **R0** Spike + bench | `tui/` workspace; blank ratatui app; synchronized output; 120 fps wheel glide over a 10k-line synthetic transcript on kitty; `bench/` measuring frame time, key-to-paint latency, CPU, RSS; the same probes run against the Python UI for baselines | T2 met on a synthetic transcript; baselines recorded in this doc |
| **R1** Seam | `orchestra/serve.py`; JSON schema generated from `events.py`; `rabble-proto`; record fixtures with `ReplayBackend` files; Rust prints a replayed turn as plain text | Rust parses every recorded event; Python round-trips every command; contract tests green on both sides |
| **R2** Shell without the face | transcript (Markdown, tool cards, user lines, notices), composer (paste, history, multiline, slash commands incl. `/model`, `/park`, `/copy`, `/face`), header, divider, permission modal, model + session pickers, theme from the palette | A full turn against a live engine; **parity checklist** (below) all ticked; T1, T2 on real content |
| **R3** Face | `rabble-face`: `eyes.rs`, `face.rs` (rig, aura, provider tint, glyph modes octant/safe, noise/degrade), mini mark; `Life` (blink/gaze); parity tests against Python golden dumps | Golden tests within tolerance; T3, T4, T6 met at 120x40, 200x55, 260x70 |
| **R4** Flip | `rabble` runs the Rust UI; `rabble --py` keeps Textual for one release; build + install via the RaBbLE-OS `ai-harnesses`/`claude-code` task (`cargo build --release`, Fedora ships cargo), applied by Mark with `layerctl` | Mark daily-drives a week; `rabble --py` removable |
| **R5** After | R2 (HTML/artifact cards), R10 (image paste), R5b (kitty-graphics pixel scroll), Option B engine port | each separately scoped by Mark |

### Parity strategy (how "same face" is proven, not eyeballed)

1. **Golden dumps from Python.** A script in `tests/` writes `(ch, fg, bg)` cell grids from `Face.frame()` / `compose()` for a fixed matrix of `(size, t, blink, gaze, pose, provider, noise, glyph mode)`. The Rust tests load them and assert cell equality (colour tolerance a few units where float order differs). Existing pins carry over as ground truth: `test_rig_baseline`, `test_compose_matches_frame`.
2. **Replay fixtures** for the shell: the same `ReplayBackend` recordings drive the Python UI today and the Rust UI later; screenshots/ANSI dumps compared by eye on the first pass, then snapshot-tested.
3. **The existing UI tests are the checklist**: `tests/test_ui_app.py`, `test_ui_transcript_scroll.py`, `test_ui_permission.py`, `test_ui_prefs.py`, `test_ui_theme.py`, `test_ui_face.py` (64 tests at S292). Each behaviour gets a Rust counterpart or an explicit "dropped, because" line.

### Parity checklist items that are easy to lose

Stuck-to-bottom follow with the 3-line slack and re-pin after blur/refocus (`Transcript.remember_view/restore_view`) · park-at-80%-context flow and `RABBLE_PARK_AT` · per-event pump survival (one bad event must not kill the UI) · tool-card titles with `[` · Ctrl+V with an image clipboard · `NO_COLOR` · `TERM_PROGRAM=vscode` safe glyphs and `RABBLE_GLYPHS` · mouse text selection/copy behaviour (check what Textual allowed today; mouse capture usually blocks terminal selection) · IME/wide characters · resize mid-frame · `/reload` is replaced by "restart the UI, the engine sidecar keeps the session".

## Parallel build split

Two lanes never edit the same file; builders are `sonnet` (pin the model on any fan-out), one `opus` reviewer per lane who did not write it.

| Lane | Owns | Needs | Model |
|---|---|---|---|
| A: seam | `orchestra/serve.py`, schema generator, `tui/rabble-proto/`, fixtures | R0 decision on shape | sonnet |
| B: shell | `tui/rabble-tui/` widgets, loop, input (1:1 scroll) | A for types (can start on fakes) | sonnet |
| C: face | `tui/rabble-face/`, golden dumper in `tests/` | nothing (pure functions) | sonnet |
| D: bench | `tui/bench/`, Python baseline probes | nothing | haiku or sonnet |
| Review | per-lane diff review, license check, gate numbers | each lane | opus |

C and D can start in R0; A starts after Mark signs off the shape; B follows A. The face (C) is the long pole and the real reason for the move, so it is not deferred behind the shell if two lanes run at once.

## Risks added by the S295 Opus review

- **The engine is now a single point of failure for every session and nothing supervises it.** Decide before R4 who launches it: recommended a `systemd --user` unit installed by the `ai-harnesses` Ansible role (socket-activated or `Restart=on-failure`), and `rabble` starting it on demand if absent. Sessions must survive an engine restart via `create_session{resume: <sdk session id>}`; the engine's own session ids are therefore random and carry the SDK id.
- **A late or restarted client sees no transcript** unless the protocol has `seq` + bounded replay (v1.1, Lane P).
- **`serve.py` gets no daily use until the R4 flip**, so bugs hide. A small `RemoteBackend` (a `Backend` that speaks the socket) would let the Textual UI run on it now: engine-side, fits the no-new-Textual-features rule (Lane R, optional).
- **Settings commands are privilege escalation** the moment a second principal exists (`set_permission_mode`, `set_trust`, `create_session` params including `cwd`/`resume` and a project `engine.json` that can inject `env`/`mcp_servers`). Owner-only now plus a single policy hook keyed on the principal (Lane P). The ACL/grant code is unreachable in production until identity is designed; do not extend it.
- **Decorative randomness cannot match between Python and Rust** (`random.Random` is Mersenne Twister with its own `choice`/`sample`/`uniform` semantics). See the face lane for the decision.

## Risks

- **Port drift:** two faces for a while. Mitigation: golden dumps, and **no new features in Python** during the port except fixes.
- **Markdown fidelity** vs Textual's renderer (tables, nested lists, code fences, links). Accept near-parity; list gaps.
- **Face is hand-tuned by eye** (aura strengths, provider mute, divider speed). Golden tests pin geometry, not taste; Mark's eye is still a gate in R3.
- **Hot reload loss** is replaced by the sidecar surviving UI restarts; verify session resume on reconnect (`SessionResumed`).
- **Engine protocol churn:** the Claude Agent SDK/CLI version is pinned in `ui/requirements.txt`; `serve.py` carries a protocol `version` in `hello` so a stale UI refuses cleanly.
- **Known Python-side defects not worth fixing before the port** (they get fixed natively in R3): dark stair-stepped halo around the eyes and black portal fill (check 3 of HANDOFF-S291, failed), stray specks on the mini mark, cell-aspect squish (R11).

## Open for Mark

1. **Shape:** Option A (Rust UI + Python engine sidecar) now, Option B (full port) only after the flip? Recommended: yes.
2. **Location:** `RaBbLE-sCoRE/tui/` (recommended: no new member, no registry change) vs its own repo.
3. **Pixel-smooth scroll spike (R5b)** via kitty graphics: worth a spike after R2, or accept line-step smoothness at 120 fps?
4. **Keep `rabble --py`** for one release after the flip (recommended) or cut at the flip?
5. **Opus review of this plan** is still owed (the Crew was off in S292); do it before R1 starts.

## Sources

`RaBbLE-sCoRE/orchestra/events.py`, `orchestra/backend.py` (Backend protocol, `ReplayBackend`), `ui/face.py`, `ui/eyes.py`, `ui/widgets/transcript.py` (scroll + glide), `ui/__main__.py` (TEXTUAL_FPS), `tests/test_ui_*.py` · `sCoRE-RaBbLE-UI-Plan.md` (R1, R3, R4, R11, parallel split) · `HANDOFF-S291-RaBbLE-UI-Face-Visual-Test.md` · S292 measurements above (probes kept in `RaBbLE-sCoRE/scripts/bench/`: `ui_loop_lag.py`, `ui_face_tick.py`, `ui_face_profile.py`, `ui_scroll_fps.py`).
