# HANDOFF-S303 · RaBbLE-UI: gaze fix, Python gaze parity, compact/micro header mark, wordmark flow; crew viewer + thinking animation NEXT

> Written 2026-11-02, S303, parked near the usage limit. Continues `HANDOFF-S302-RaBbLE-UI-Face-Gaze-Selection.md`. Cargo: run from `RaBbLE-sCoRE/tui/` with `--offline`. Python: `PYTHONPATH=. ~/.local/share/RaBbLE/rabble-ui/bin/python -P -m pytest tests/test_ui_*.py`. Nothing pushed. Crew used: CoBbLE x6, CrumBbLE x1.

## What landed (RaBbLE-sCoRE, `new-horizons`, tagged `%S303_STATE%`)
| Commit | Result |
|---|---|
| `45315fa` | Gaze no longer goes dark while text streams: `gz.newest` cached after layout (S302 NiBbLE MEDIUM). `cell_aspect()` cached until `Event::Resize`; tests pin the aspect via `show_face()`; Python `-full` min-height 12 -> 2. CrumBbLE pty run: regressions hold, stream-gaze not demonstrable in a pty (unit test is the proof) |
| `a77b71a` | Python TUI gets the Rust gaze: `ui/gaze.py` (port of `mod gaze`), 10 Hz `_gaze_tick`, `_measure_newest` cached-newest, strict `RABBLE_CELL_ASPECT` parse, `tests/test_ui_gaze.py` (23). PARITY.md "Gaze (S303)" |
| `76d601e` | Rust header tiers: full (>=56x22, 24x6 mark), compact (>=30x10, 2-row header), plain below. Wordmark = shared `wordmark(th, phase)`, animated magenta/cyan flow (`th.flow`), same phase as the divider, all tiers |
| `99c97f5` | Python twin of the tiers + flowing wordmark (`tier_for`, `Header.set_tier`, `FaceWidget.fit`, divider `follow` callbacks; also fixed `/reload` leaving a second divider). `tests/test_ui_header.py` (16) |
| `a486fe5` | Rust micro mark: 8x2 downscaled face was an unreadable smear on Mark's screen, so now two drawn eye pills at 14x8 octant px, 7 cols x 2 rows (`rabble-face/src/micro.rs`, `FaceView.set_micro`), cyan left / magenta right, void = terminal bg, gaze + 4-step blink. Slot 7, gaze centre (3.5, 1.0) |
| `2def318` | Python micro-mark port (`micro_pixels`/`micro_cells`/`MicroMark`, `compact_mark()` hook), slot 7, reflow width-8; 111 Python UI tests green. Ports the OLD flat-pill design, to be redone with whites + visible portals |

Tests at `a486fe5`: rabble-tui 176 pass + 1 known fail, rabble-face 13, proto 10, theme 4, goldens untouched; Python 108 pass before the micro port. The one failure `a_face_frame_is_cheap_enough_to_sit_between_keys` is a debug-only p99 timing test (11-22 ms vs 8 ms; release 3.5-4.8 ms). Mark is undecided: make it release-only or loosen the debug bound. Not touched.

## Mark's asks this session (status)
1. **Header shows the entity even when small; small version for low-res.** DONE (Rust `a486fe5`; Python port in flight). Mark has NOT yet eyeballed the micro mark; he judged the 8x2 downscale unreadable from a screenshot, so ask him to `/reload` and look at the new one at 40x12 (grim screenshot works: `grim /tmp/x.png`, crop with PIL).
2. **Wordmark magenta<->cyan at all sizes, with motion.** DONE both UIs (note: he first said maroon, then magenta; code uses the theme magenta). Python direction copied from the divider, `Theme::flow` orientation not cross-checked.
3. **Python keeps as much parity as possible.** Standing ruling; gaze + header ported; PARITY.md updated.
4. **More animation when thinking + a RaBbLE-flavoured spinner-word bank (like Claude Code's).** NOT BUILT. Bank written, uncommitted: `RaBbLE-sCoRE/ui/thinking_words.txt` (50 phrases, no em dashes; Mark may edit). Plan: both UIs read the file (Rust `include_str!` or a shared path, Python reads it); rotate a phrase every ~3-4 s in the divider label (today Rust shows `working`, `busy_label()` app.rs ~1357; Python `ui/app.py:183` + `Thinking` widget in `ui/widgets/transcript.py:20` shows `thinking...`); small animated glyph in the wordmark flow colours; eyes busier while working (faster saccades, pulse; Python `face.py` already has `working` mood speed 2.5). Seeded/deterministic word choice so tests can pin it.
5. **Better subagent and crew viewers.** Mark said "go with recommendation": **live roster strip + `/crew` overlay**, **Rust first, then the Python twin**. NOT STARTED. Today subagent work is only inline `cobble: Bash ...` lines and `/crew` toggles organs (app.rs `/crew` ~1195, `ui/app.py:428`). Spec to hand a CoBbLE: a compact roster strip (one row per running organ: name, state, current tool, elapsed, tokens) plus a `/crew` overlay opening one organ's full transcript; inline lines collapse into one card per organ. First step is scouting what the engine protocol (v1.1, `rabble-proto`) already emits per subagent (names, parent ids, sidechain events); if the protocol lacks it, that is a protocol change and needs Mark's sign-off before building. GoBbLE scout then QuiBbLE before CoBbLE.

## Mark's verdict on the micro mark (a486fe5, after he saw it live): NOT DONE
"The micro mark needs whites in the eyes, and the portals can't be seen." The flat cyan/magenta pills have no sclera and the portals (pure `#000000` in the full face, S302) vanish against the terminal bg at 14x8 px. Redesign `rabble-face/src/micro.rs` (Rust first, then port to `compact_mark()` in `ui/face.py`): give each eye a white/near-white core (take the shade the full face uses for the lit eye, from the Palette via theme, no new hexes) and make the portal visible by drawing it as a coloured ring/arc (the full face shows cyan and magenta rings around the eyes, see `/tmp/s303-shot/full.png` and screen.png top pane) rather than black. Budget is 6 px wide x 8 px tall per eye slot, so likely: 1 px coloured ring outline + 2 px white core, keeping the 1-col gap; keep gaze/blink. Mark's `grim` screenshot loop is the acceptance test (crop and zoom as before). The Python port (`2def318`) copies the OLD flat-pill spec; redo it from the new Rust design.

## Next, in order
0. Micro mark redesign above (whites + visible portals), Rust then Python.
1. Run both suites; `cargo build --release --offline`.
2. Mark `/reload`s and eyeballs: micro mark reads at 40x12, drops to plain below 30x10; wordmark flows; `/face` round (`RABBLE_CELL_ASPECT=2.3` if oval); gaze while streaming; `rabble --py` gaze + header.
3. Crew viewer (item 5): GoBbLE protocol scout, QuiBbLE, then CoBbLE Rust, then Python twin.
4. Thinking words + animation (item 4).
5. Timing-test decision with Mark.
Do items 3 and 4 sequentially: both touch `app.rs` (divider/label and layout) and the Python twin files; two organs must never edit one file.

## Known gaps / lows still open
Selection lows from S302 NiBbLE (notice_quiet index, press anchor before first drag); gaze range constants fixed at 40/12, Modal waits out ATTN_HOLD, Card looks at newest line not the card, any key counts as typing; vacuous `eyes_stay_isotropic_under_a_non_square_cell` test; Python env-parse is now strict (Rust-matched); Python permission screen never counts as typing; the aspect cache reset is unverified in a real terminal (pexpect reports 0 px). Python plain tier lost its right-hand wrap margin; Python 2-row text uses rich styles, not Rust theme roles.

## Gotchas
- Builders must not `git stash`/`checkout`/`reset` in the shared tree (S302). Stage explicit paths only; Grimoire and sCoRE carry other sessions' dirty files (Pocket docs, ledger, session jsonl).
- Face crate and `ui/face.py`/`ui/eyes.py` are twins pinned by `tests/fixtures/face/golden.json`; the micro mark is pinned by unit tests in `rabble-face/src/micro.rs`, not goldens.
- Python constants are pinned to Rust `widgets/mod.rs` text by a test: change both together.
- Non-wheel mouse events must not call `note()` or set `dirty` (S299); the wordmark repaints on the existing flow tick only.
- Grimoire `rabble-face` micro glyphs need octant-capable fonts; `safe` mode falls back to quadrants.
- Claimed session number: S303 (`spells/session-number.sh claim`), matches the commit tags.
