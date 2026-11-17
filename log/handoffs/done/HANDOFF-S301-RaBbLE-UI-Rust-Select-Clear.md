> **Status (S320, 2026-11-09): SUPERSEDED by HANDOFF-S302-RaBbLE-UI-Face-Gaze-Selection.** Kept for reference, not deleted.

# HANDOFF-S301 · RaBbLE-UI Rust: text selection + copy landed, /clear entropy fixed in both TUIs

> Written 2026-11-02, S301. Continues `HANDOFF-S297-RaBbLE-UI-Rust-Face.md` (items 4-6 there still stand) and S299's open list. Cargo: run from `RaBbLE-sCoRE/tui/` with `--offline`. Done directly, no organs; nothing pushed.

## What landed (RaBbLE-sCoRE, `new-horizons`)
| Commit | Result |
|---|---|
| `7591533` | Rust shell mouse selection in the transcript: drag, double-click word, triple-click line, edge auto-scroll, painted reversed. Ctrl-C copies the selection (OSC 52 + wl-copy/xclip) and does not count toward quit-twice; any other key drops it. Ctrl-V paste already worked (worker thread, `util::system_clipboard`). Selection also drops on resize, card toggle, clear. Wires up `widgets/select.rs`, which a session that died on the rate limit had left uncommitted; two of its test expectations were wrong and were fixed |
| `f56c401` | Rust `/clear` now also resets capability bars, stability, trust and the face's noise/breaking (`FaceHub::clear_signal`) |
| `449e721` | Python `/clear`: header entropy/stability cleared (`_sync_header` else branch), face `set_signal(100, 100)`, `_restart` ends with `_sync_header()` |

Tests: 159 Rust in rabble-tui green; `tests/test_ui_*.py` 69 green. Commits are tagged `%S300_STATE%` (S300 was taken by a concurrent session; this is S301).

## Pending, in order
1. **Mark tries it** in `rabble` (`cargo build --release --offline`, then `/reload`): drag-select, Ctrl-C, Ctrl-V into the input, double/triple click, drag past the edge; `/clear` after a degraded entropy report. Only unit-tested so far, never run in a real terminal.
2. **CrumBbLE pty run** of selection (mouse tracking on, flood of drag events, resize while selected, selection while a reply streams) plus the S297 item 3 list.
3. **NiBbLE review of `7591533..449e721`**, and still `79d2f5e..4793800` from S297. Worth targeting: `select_mouse` in `app.rs` (edge scroll, coordinates vs `tr_rect`), `Transcript::line_at` guarded on `stale`, selection index drift if lines above change while streaming.
4. **Decision for Mark:** should the face's eyes follow the mouse? Today gaze is only the seeded `Life` driver in both UIs. Doing it needs any-event mouse tracking (`?1003h`), a cell-to-gaze mapping as `Life`'s target with the random saccades as fallback, and rate-limited repaints so S299's face starvation does not return. Header mark, `/face`, or both?
5. **Known gaps:** copied text keeps the transcript's hard wraps; mouse selection inside the input box; Rust capability bars read `--` after `/clear` until the first entropy report (Python shows the model baseline from `Entropy(model)`; Rust has no copy of that table); `PARITY.md` not updated for selection or clear.
6. Open from before: S297 items 4-6 (native halo fixes, shell gaps, Lane O systemd/packaging, Lane B `check.sh`), naive reset times read as UTC.

## Gotchas
- Mouse events other than the wheel return early in `App::on_input` and do not call `note()` in `run.rs` (S299: motion must not starve the face tick). `select_mouse` runs before that early return and only sets `dirty` when the selection changed; drag events do set it.
- `Transcript` entry `start`s are only valid after `layout`; `line_at`/`pos_at` return `None` while `stale`.
- `pytest -k ui` over the whole suite hits 5 unrelated collection errors (e.g. `tests/test_security_hardening.py`); run `tests/test_ui_*.py` directly with `~/.local/share/RaBbLE/rabble-ui/bin/python -m pytest`.
- The Grimoire has other sessions' uncommitted files (Pocket provenance/split docs, blockers, old session jsonl); stage explicit paths only.
