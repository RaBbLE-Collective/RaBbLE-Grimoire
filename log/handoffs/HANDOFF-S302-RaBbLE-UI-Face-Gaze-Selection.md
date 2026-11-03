# HANDOFF-S302 · RaBbLE-UI Rust: face void/portals/aspect, gaze plumbing, selection review fixes

> Written 2026-11-02, S302, parked because the session was degraded (rate limits, a stash clobber scare). Continues `HANDOFF-S301-RaBbLE-UI-Rust-Select-Clear.md`. Cargo: run from `RaBbLE-sCoRE/tui/` with `--offline`. Crew used: CoBbLE x2 builds (twice), NiBbLE, CrumBbLE. Nothing pushed.

## What landed (RaBbLE-sCoRE, `new-horizons`, commits tagged `%S302_STATE%`)
| Commit | Result |
|---|---|
| `61e5332` `8f2605d` | Selection and copy fixes from NiBbLE on S301: copy/`/copy`/quit-hint notices no longer split a streaming reply (`Transcript::notice_quiet`); drag only acts if the press was in the transcript; code indent not copied; zero-width chars kept; selection dropped when lines above change; `/clear` refreshes the header trust label; Python `/clear` test now real |
| `7eade68` | Face: void cells are the terminal default bg in header mark and `/face`, AA is foreground-only blend (Mark's call), portals pure `#000000` (Mark's call), `/face` one uniform scale in a circle, no size floors in the full face, `Life::set_gaze` API; all 48 goldens regenerated |
| `5f46156` `c17947c` | Esc with any selection only clears it (it used to interrupt the turn on a blank selection); `guard_selection` keyed on the press entry, so upward drags across entries and upward edge scroll work |
| `86cf2c3` | Gaze plumbing in `app.rs` `mod gaze`: pointer steers both faces (no repaint, not typing, ~100 ms cadence, 1.8 s ttl); entity attention when pointer idle 2 s: modal, composer cursor, newest line after tool activity, end of streaming text, else seeded saccades; 500 ms re-pick with 1.5 s hysteresis |
| `6050ef2` | `/face` uses the terminal's real cell aspect (`window_size()` pixels, fallback 2:1, `RABBLE_CELL_ASPECT` override; Python twin via `TIOCGWINSZ`); non-finite gaze ignored in both twins; light-base void rule; 3 new goldens with an `aspect` key |
| `eb82008` | `FACE_MIN_ROWS` 12 -> 2 in `widgets/transcript.rs`, so `/face` fits short panes (the crop was the transcript floor, not the face) |

Tests at `eb82008`: 175 in rabble-tui, 14 behaviour + 12 golden in rabble-face, all green; `tests/test_ui_*.py` 69 green. Release binary built.

## Mark's feedback this session (already acted on)
Select/copy/paste and `/clear` work. Wants: eyes read the mouse when active, entity picks its own focus otherwise; void = terminal colour, fewer void blocks; portals pure black; `/face` sphere round and enveloping the eyes, eyes keep aspect when height is tight (header mark is fine). Rust FPS praised.

## Pending, in order
1. **Mark eyeballs** (`cargo build --release --offline`, `/reload`): is `/face` round and whole at short heights; does gaze feel right. If the sphere is still oval, try `RABBLE_CELL_ASPECT=2.3` to learn whether the terminal reports pixels (then fix the fallback). Tuning knobs: the `pub const`s in `mod gaze` (`app.rs`): `RANGE_COLS`/`RANGE_ROWS` (40/12), `POINTER_ACTIVE`, `POINTER_TTL`, `ATTN_HOLD`, `TYPING_HOLD`, `CARD_HOLD`; priority order in `choose()`.
2. **NiBbLE review of `7eade68..eb82008` DONE (arrived after park); nothing fixed yet. No clobber found** (tree builds, every hunk of 5f46156/c17947c intact, no duplicated blocks). Findings for CoBbLE, in order:
   - **MEDIUM, gaze goes dark while text streams:** `Transcript::newest_line()` returns `None` when `stale`; every `TextDelta` sets stale, and `run.rs` runs `tick_face` (-> `steer_gaze`/`gaze_scene`) before paint/layout, so after `ATTN_HOLD` (1.5 s, not refreshed while the same focus continues) the eyes drop to random saccades for the rest of the reply. `Card` focus has the same dependency. Fix: cache the last good `newest`, or build the scene after layout. The test `the_entity_looks_at_streaming_text_and_the_composer_then_lets_go` calls `screen()` before each tick so it never sees a stale page; make it follow the real loop order.
   - LOW: `cell_aspect()` opens `/dev/tty` + ioctl on every paint while `/face` shows (~30-40/s); cache until `Event::Resize`. Rust tests that build a full face depend on the dev's real terminal/`RABBLE_CELL_ASPECT`; pin with `set_cell_aspect`.
   - LOW, Python twin drift: `FaceWidget.-full { min-height: 12 }` at `ui/face.py:953` still floors Python while Rust floor is now 2 (and the `transcript.rs:20` comment is stale); Python reads aspect once at build, Rust per draw; env parsing differs (`" 2.3"`/`"2_3"` accepted by Python only); no light-palette golden.
   - LOW, selection: `notice_quiet` inserting at the press entry's index goes undetected by `guard_selection` (latent: today's callers clear the selection first); press anchor discarded if a layout runs before the first Drag.
   - LOW, gaze design: `RANGE_COLS/ROWS` fixed 40/12, not scaled to face size or cell aspect (saturates inside the sphere on a 200x50 `/face`); Modal still waits out `ATTN_HOLD`; `Card` looks at the newest line, not the card; any key (PageUp, Ctrl-O, Esc) counts as typing and pulls the eyes to the composer.
   - LOW, tests: `eyes_stay_isotropic_under_a_non_square_cell` is vacuous (passes with or without the aspect change); `attention_does_not_jitter_between_foci` never holds a focus past `ATTN_HOLD`; the "typing keeps its interest" assert is only `is_some()`.
3. **CrumBbLE pty run of `eb82008` NOT DONE** (same rate limit): upward edge-drag copy non-empty, Esc on blank selection must not send `interrupt`, `/face` whole at 100x12/160x8/60x20/100x40/220x60 with `RABBLE_CELL_ASPECT` 2.0 and 2.3, pointer motion without repaint storm, S301/S302 regressions. Harness in `/tmp/crumble-s301/` (may be gone); fake engine speaks `rabble-proto`.
4. Known gaps: hard-wrapped prose copies with a newline at each wrap; the provider aura halo leaves tinted fringe cells around the eyes (deliberate glow; cut it if Mark still sees blocks); mesh node spacing slightly anisotropic when aspect is not 2; Python face fit/NaN/light-base only checked by an ad hoc script (no committed `tests/test_ui_face.py` cases); dropdown geometry (L6); edge scroll only moves on drag events (no timer); `/clear` baseline: Rust bars read `--`, Python shows model baseline; `PARITY.md` not updated; eyes-follow-pointer for the Python TUI not built (Rust only); S297 items 4-6 and S299 open list still stand.

## Gotchas
- **Builders must not `git stash`/`checkout`/`reset` in the shared tree** (S302 incident). Told to use `git archive` to `/tmp` for baselines. Two organs still must not edit the same file.
- The face crate and `ui/face.py`/`ui/eyes.py` are twins pinned by `tests/fixtures/face/golden.json`, generated by `tests/golden_face.py` (Python), checked by Rust `tests/golden.rs`. Change both, regenerate deliberately.
- Non-wheel mouse events must not call `note()` or set `dirty` (S299); gaze is only read on the face tick.
- Full-workspace `cargo test` must be run from `tui/`; `cargo build --manifest-path` from the repo root fails offline.
- The Grimoire has other sessions' uncommitted files (Pocket provenance/split docs, session jsonl, ledger); stage explicit paths only.
- Open question still with Mark: should the Python TUI get the same pointer gaze?
