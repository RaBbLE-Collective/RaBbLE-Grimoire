# HANDOFF-S297 · RaBbLE-UI Rust: the face landed, review and Mark's eye pending

> Written 2026-11-02, S297 (parked). Supersedes `HANDOFF-S296-RaBbLE-UI-Rust-Phase2-Next.md` for Lane F; that file still holds the other open items (shell gaps, Lane O, Lane B, RemoteBackend wiring). Cargo: run from `RaBbLE-sCoRE/tui/` with `--offline`. Pin `model: "sonnet"` on builders, one `opus` reviewer who did not write it.

## What landed (RaBbLE-sCoRE, `new-horizons`, nothing pushed, built by CoBbLE)
| Commit | Result |
|---|---|
| `79d2f5e` | `ui/prng.py` (SplitMix64) replaces `random.Random` in `ui/face.py` (mesh, orb dust, glitch, blink/gaze `Life`, `_lattice`); `tests/test_ui_prng.py` |
| `e08f786` | `rabble-face` crate: canvas, rig/EXPR/blend, eyes/portals, mesh/orb/aura, compose, `Life`, degrade/noise, mini mark, `provider_of`; `tests/golden_face.py` + `tests/fixtures/face/golden.json` |
| `4793800` | Shell wiring: `widgets/face.rs` (`FaceView`, `FaceHub`), 24x6 mark in a 6-row header (only in panes >= 56x22), `/face` full face as a transcript item, PARITY.md |

Verified by me at close: `cargo test --release --offline` = 178 passed (face 3+7+11, proto 10, theme 4, tui 143), no failures. Reported by CoBbLE, not re-run by me: Python `pytest tests/test_orchestra_*.py tests/test_ui_*.py` 240 passed, 1 skipped; golden parity exact on 48 frames (glyph and both colours); eyes 0.65 ms/frame and background 0.57 ms at 260x70; idle CPU 3.6% of a core in a pty (one run, loaded machine; T4 target 5%).

## Pending, in order
1. **Mark's eye (the gate).** The shared PRNG changes the **Python** face too: mesh layout, orb dust, glitch and blink/gaze sequences differ from before. Confirm both faces look right (`rabble --py` and `rabble`, then `/face`). If Mark objects, the fallback is dumping the tables from Python (S295 handoff, Lane F).
2. **NiBbLE review of `79d2f5e..4793800`** was NOT run (rate limit earlier in the session). Skipped stage of the build loop. Worth targeting: event-loop change in `run.rs` (face ticks only on iterations with no key/wheel input), `Item::Face` in the transcript (reserved rows, drop on submit and `/clear`), `theme.rs` `rgb()`.
3. **CrumBbLE run** in a real terminal >= 56x22: mark and `/face`; mood changes (typing, streaming, tool call, denial, error); `kill <pid>` leaves the terminal clean; resize storm; `NO_COLOR`; `TERM_PROGRAM=vscode` safe glyphs. CoBbLE only drove the binary through a pty for about 12 s. Key-to-paint and wheel p99 were not re-measured with the face on (Lane B).
4. **Native fixes deferred on purpose:** dark stair-stepped halo, black portal fill, specks on the mini mark (S291 check 3). The goldens pin Python's pixels, so a fix means deliberate regeneration with Mark looking: `~/.local/share/RaBbLE/rabble-ui/bin/python tests/golden_face.py`.
5. **Smaller gaps:** T6 (cell aspect from the terminal; Python assumes square too); header lacks Python's five info lines (capability bars, usage windows); frames are computed inline on the loop (needs a thread if the face grows past about 260x70 at 30 fps); `ui.prng` missing from `RELOAD_MODULES` in `ui/app.py` (works via `ui.face` re-import); `safe_glyphs()` env read untested; no Python-vs-Rust fps comparison.
6. Everything else from HANDOFF-S296 "Open" stays open: Narration arm in `app.rs`, Crew persona colours, OS usage tracker, session fallback after engine restart, Lane O (systemd unit, packaging), Lane B (`tui/check.sh`), `--engine-socket` wiring, deferred review items, B1-B3 permission re-check.

## Gotchas
- A Sonnet builder hit the 5-hour limit within minutes of starting; `SendMessage` resumed it cleanly with work saved.
- Stage explicit paths only. The Grimoire has other sessions' uncommitted files (Pocket notes, session transcripts); leave them.
- Temp files left by CoBbLE outside the repo: `/tmp/ptyrun.py`, `/tmp/e297.*`.
