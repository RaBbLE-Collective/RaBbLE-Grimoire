# RaBbLE-UI in Rust (R4): plan

> Status: **proposed, S292 (2026-10-29).** Mark chose Rust ("Python is not fast enough: snappy, native, fluid"). The shape in "Architecture" is RaBbLE's recommendation and needs Mark's sign-off before R1; the R0 spike is safe under any shape.
> Parent plan: `sCoRE-RaBbLE-UI-Plan.md` (roadmap items R1, R3, R4, R11). This plan **retires R3** (a face render server only existed to dodge the GIL; Rust threads do not have one).
> Cold start: `../handoffs/HANDOFF-S292-RaBbLE-UI-Rust-Rebuild.md`.

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
| T2 | Wheel scroll: **120 fps glide, zero dropped frames in a 1 s burst**, transcript frame <= 4 ms | 60 fps cap, notched |
| T3 | Face fullscreen (260x70): eyes **>= 30 fps (goal 60)**, background >= 15 fps, none of it on the input path | eyes 10 to 16/s |
| T4 | Idle with the face: **<= 5 % of one core**, RSS <= 60 MB | 20 to 42 %, 147 to 204 MB |
| T5 | Cold start to first paint <= 100 ms | not measured |
| T6 | Cell aspect read from the terminal, sphere round at any aspect | no correction (R11) |

Targets are measured by one bench harness (R0), run against the Python UI first so the comparison is real.

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

### Frame loop

- One thread owns the terminal and draws; it never waits on the engine or the face.
- Input thread (crossterm event stream, kitty keyboard protocol where available, SGR mouse), engine I/O on tokio, face workers on their own threads (background layer, eye layer; `rayon` row bands for the heavy eye raster).
- Face frames cross to the render thread by a lock-free latest-value slot (triple buffer or `ArcSwap`), so a slow eye paint costs a stale eye, never a late keystroke.
- **Synchronized output (CSI ?2026)** around every frame: no tearing, and the terminal can present on its own cadence.
- Draw on a dirty flag, capped at 120 Hz; only changed cells are written (ratatui's buffer diff, with the face writing straight into the buffer).
- Scroll: a float position with a spring/exponential glide (the S292 Python glide is the reference: `WHEEL_LINES 3`, rate 16/s, min speed 45 lines/s), driven by the frame clock.
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
| B: shell | `tui/rabble-tui/` widgets, loop, input, glide | A for types (can start on fakes) | sonnet |
| C: face | `tui/rabble-face/`, golden dumper in `tests/` | nothing (pure functions) | sonnet |
| D: bench | `tui/bench/`, Python baseline probes | nothing | haiku or sonnet |
| Review | per-lane diff review, license check, gate numbers | each lane | opus |

C and D can start in R0; A starts after Mark signs off the shape; B follows A. The face (C) is the long pole and the real reason for the move, so it is not deferred behind the shell if two lanes run at once.

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
