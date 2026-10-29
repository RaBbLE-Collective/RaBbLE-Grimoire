# HANDOFF-S292 · RaBbLE-UI: rebuild in Rust (start at R0)

> Written 2026-10-29 at the end of S292. Mark decided to move the TUI to Rust: "Python is not fast enough for this, I want it snappy, native and fluid." The plan is `../plans/sCoRE-RaBbLE-UI-Rust-Plan.md`; read it first (it holds targets, architecture, phases, parity strategy, lanes, risks).
> **Do not start R1 until Mark signs off the shape** (Option A: Rust UI + Python engine sidecar). **R0 (spike + bench) is safe under any shape.** An Opus review of the plan is still owed (the Crew was off in S292).

## State at handoff
- Repo `RaBbLE-sCoRE`, branch `new-horizons`, local, not pushed. S292 work is committed as `b98d727` ( `ui/widgets/transcript.py` glide, `ui/face.py` style cache, `ui/__main__.py` `TEXTUAL_FPS`, `scripts/bench/`).
- `tests/test_ui_*.py`: **64 passed** (`~/.local/share/RaBbLE/rabble-ui/bin/python -m pytest -q tests/test_ui_*.py` from `RaBbLE-sCoRE/`).
- The Python UI stays Mark's daily driver until the R4 flip. **No new Python features** except fixes.
- Rust toolchain present: `cargo 1.98.1`, `rustc` (Fedora). No `tui/` directory exists yet.

## What S292 changed in Python (so you know what the baseline is)
| What | Where | Effect |
|---|---|---|
| Wheel glide: notches move a target, one timer closes a fraction of the gap per frame, minimum speed so the tail does not crawl | `ui/widgets/transcript.py` (`WHEEL_LINES 3`, `GLIDE_RATE 16`, `GLIDE_FPS 120`, `GLIDE_MIN_SPEED 45`), test `test_wheel_burst_accumulates_into_one_glide` | replaces the per-notch restarted ease (the ratchet) |
| Textual screen cap 60 to 120 fps | `ui/__main__.py` sets `TEXTUAL_FPS=120` before Textual imports | **takes a full `rabble` restart, `/reload` is not enough** |
| `Style` cache in `render_line` | `ui/face.py` `_style`, `_STYLE_CAP` | `render_line` 1.87 s to 0.59 s per 4 s; loop-lag p95 53 to ~23 ms at 200x55 |
| `PAUSE_GC_ON_SCROLL` | `ui/app.py` | no GC pause mid-glide |
| Baseline probes | `RaBbLE-sCoRE/scripts/bench/ui_*.py` | the numbers the Rust bench has to beat |

**Mark's last feedback (after the 60 fps glide):** "Scroll FPS is not high enough. Still has a notched feel but more flowing." The 120 fps + min-speed version was built **after** that and has **not been felt live** by Mark. Say so in R0 when comparing.

## Visual test results (the S291 handoff, partly done)
Captured with grim on WS1 (kitty, `/face` full). Old code (the running instances predate the S292 edits).
- Pass: `/face` fills the viewport; eyes and portals readable; VSCodium shows no tofu (mini mark, divider) and the divider flows.
- **Fail (check 3):** dark stair-stepped block around the eye pair and a black fill inside each portal ring: not a thin glow. Stray specks on the mini mark. Fix natively in R3 rather than tuning `AURA_*` in Python.
- **R11 number:** kitty cell is 19 x 44 px, **aspect 2.32** (196x50 cells, 3724x2200 px; read from `TIOCGWINSZ` on the pty). The face assumes 2.0. VSCodium reports a rough pixel size (117x39 cells, 975x780 px, aspect 2.40), so treat VS Code's value as approximate.
- Not checked: provider tint (4), felt smoothness (8), Ctrl+V image (9), tool result with `[...]` (10), full `/face` inside VSCodium (typing into Mark's session was not done without asking).

## Gotchas learnt this session
- **Hyprland here takes Lua dispatch.** `hyprctl dispatch workspace 1` errors (`')' expected`) and nothing switches. Use `hyprctl dispatch "hl.dsp.focus({workspace=N})"`. The S291 capture recipe is stale; grim on an unswitched workspace silently returns whatever is in front (two captures were all WS3 before this was noticed). Always `hyprctl activeworkspace -j` after switching, and return to the original workspace.
- Textual reads `TEXTUAL_FPS` at import, so it must be set in `ui/__main__.py` before `ui.app` imports.
- cProfile in a Textual `run_test` only profiles the loop thread; face-thread cost has to be read from the threads' own timings.

## Do this (R0)
1. Read the plan. Claim a session number first (`head -20 log/SESSION-LOG.md`, `spells/agent-register.sh status`; S284/S285 were taken twice). S292 is this one.
2. `RaBbLE-sCoRE/tui/` Cargo workspace (`rabble-proto`, `rabble-face`, `rabble-tui`, `bench`): empty crates that build. Check every dependency is permissive (MIT/Apache/BSD); no copyleft.
3. `rabble-tui` spike: ratatui + crossterm, **synchronized output (CSI ?2026)**, a synthetic 10k-line transcript, wheel glide as a float position driven by a 120 Hz frame clock (port the S292 constants), mouse via SGR. No engine, no face.
4. `bench/`: frame time (p50/p99), key-to-paint latency, CPU, RSS. Run the **Python baselines** (`scripts/bench/ui_loop_lag.py`, `ui_scroll_fps.py`, `ui_face_profile.py`) and write them into the plan's targets table next to the Rust numbers.
5. Gate: T2 (120 fps glide, no dropped frames in a 1 s burst) on kitty, measured and screenshotted. Show Mark the glide live before building more.
6. Parallel from R0 (they share nothing): **lane C** (face: `rabble-face` pure functions + a Python golden dumper in `tests/`) and **lane D** (bench). Pin `model: "sonnet"` on any sub-agent fan-out (it inherits the parent model otherwise). Opus reviews a lane's diff, never the builder.

## Open for Mark (also in the plan)
Shape A vs B; `tui/` inside sCoRE vs its own repo; whether to spike kitty-graphics pixel scrolling (R5b); keep `rabble --py` one release; the Opus plan review. Cell grids move in whole 44 px lines in kitty, so 120 fps line steps is the ceiling without the graphics protocol: tell him that plainly if he asks for "perfectly smooth".

## Start
```bash
cd ~/RaBbLE-Collective
head -20 RaBbLE-Grimoire/log/SESSION-LOG.md
cat RaBbLE-Grimoire/log/plans/sCoRE-RaBbLE-UI-Rust-Plan.md
cat RaBbLE-Grimoire/log/handoffs/HANDOFF-S292-RaBbLE-UI-Rust-Rebuild.md
git -C RaBbLE-sCoRE log --oneline -3
```
