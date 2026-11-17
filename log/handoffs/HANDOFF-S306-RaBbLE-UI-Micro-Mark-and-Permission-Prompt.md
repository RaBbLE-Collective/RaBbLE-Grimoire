# HANDOFF-S306 · RaBbLE-UI: micro mark is the builder's glyph; 3-row header; permission/question prompt is BROKEN for Mark (next session)

> Written 2026-11-03, S306 (continued the S305 sCoRE session, which hit the usage limit and never logged). Continues `HANDOFF-S303-RaBbLE-UI-Compact-Mark-Crew-Viewer.md`. Cargo: run from `RaBbLE-sCoRE/tui/` with `--offline`. Nothing pushed. Mark still has to `/reload` and look at the final mark. I (RaBbLE) worked alone, no organs.

## What landed (RaBbLE-sCoRE, `new-horizons`, tagged `%S306_STATE%`)
| Commit | Result |
|---|---|
| `2052401` | Mouse wheel scrolls a permission prompt's body (`Permission::wheel`, 3 lines a notch, not held by the arming delay, reaching the end counts as reading it) + test. Written in S305, committed here |
| `28d73db` | Micro mark rebuilt (`rabble-face/src/micro.rs`), see below |
| `c2caf0d` | Compact header is 3 rows (`FACE_COMPACT_ROWS` 3, `hh` in `App::draw`), third text line = provider usage (`HeaderState::usage_spans`, shared with the rich header's line 5); mark slot is 9 columns; tiny panes keep 2 text rows |

Tests: 177 pass + the known debug-only timing failure `a_face_frame_is_cheap_enough_to_sit_between_keys` (passes in release; still undecided: release-only or loosen the bound). `cargo build --release --offline` done.

## The micro mark, what Mark asked for and where it stands
Reference: `RaBbLE-BaBbLE/intake/RaBbLE-NeBuLA-EyeStates.md` and `rabble-matrix-builder.html` (Mark's glyph spec and editor, copied there this session; BaBbLE repo copy is uncommitted). Glyph rules used: portals on a diagonal, eye hangs from its portal and is in FRONT of the portal's near edge, far edge clear above it, no pupils.

Final state (Mark's last verdicts: "closest so far", then centred-eye, then asked for movement + more separation; he has NOT yet seen the 9-col gaze version live):
- 18 x 12 octant px (9 x 3 cells). Portal 8 x 4 (left, top cell row) and 8 x 4 (right, second cell row), mirror images; eye 2 px wide centred in the portal, 6 rows long, starts just inside the far edge, covers the near edge. Right eye is the left one upside down (`flip`).
- **Hard constraint that shaped everything:** a terminal cell holds two colours. A cell may hold ring + white only as ring-over-white with NO void in it (the eye must fill the rest of that cell); otherwise the white would leak into the black hollow. `every_pose_is_valid` sweeps 5 gaze x 5 gaze x 11 blink on both grids and enforces this. Anything that slides the eye by 1 px breaks it; that is why gaze steps a whole cell (2 px).
- Gaze (new, unseen by Mark): x steps each eye 2 px (left / centre / right inside the portal, thresholds +-0.4); y lengthens the left eye and shortens the right (travel 2 px fine, 1 px safe). Blink: retract to the least that fills the shared cell, then portal alone, then both shut to a dash in the hollow.
- `safe` (VSCodium, `TERM_PROGRAM=vscode`) has its own 18 x 6 grid (`SAFE`): merging the fine grid row pairs filled every hollow, which was Mark's "VSCodium does not draw the black blocks".
- **Assumptions I made when Mark did not answer (he said "continue"):** "1 more pixel of separation" became one cell (the mark is 9 cols, portals touch, because a 1 px gap cannot keep the eyes on cell edges); "portals up one more block each" became "eyes use the free third row" (the cyan portal is already on the top row, magenta up to the top would break the diagonal). Ask him if either was wrong. The mark still leaves the bottom cell row empty; he may want it centred.
- **Python twin NOT ported:** `ui/face.py` (`micro_pixels`/`micro_cells`) still draws the old flat pills with no portals and 7 cols. Port from the Rust `grid()` as written.

## How to check the mark yourself (this loop worked; use it)
1. `cargo build --release --offline` then, in a SEPARATE command, `(setsid nohup /usr/bin/kitty --title chk-x /home/rabble/.local/bin/rabble >/dev/null 2>&1 &)`, `sleep 9`, then `hyprctl clients -j` for the window geometry. Hyprland here takes Lua dispatch; do not use `[float; ...]` exec rules.
2. The compact tier needs the window about 940 x 420 px (>=30x10 cells, <56x22). A tall window (y 45, 697 px) gets the FULL 24x6 face instead; a big font gets the tiny tier. Only trust a screenshot at the short geometry.
3. `grim -g "X,Y WxH" f.png`, crop and zoom with PIL (`python3`, not `-I`, PIL is in the user site), view with Read. Then close the window by pid (`kill <pid>` from `hyprctl clients -j`). Never `pkill -f` with a pattern that also appears in your own command (kills the Bash shell, exit 144).
4. A pixel-level render of `micro()` cells (octant bits from `octant_table()`) is a fast pre-check, but it is NOT the acceptance test. I shipped three wrong versions by trusting it; Mark's rule is "screenshot to check your work".

## NEXT, in order
0. **Permission / question prompt box (Mark: "an issue that makes it so I can't properly give permissions or answer questions").** Do this in its own fresh session. Symptom is not yet characterised; first ask Mark exactly what fails (cannot press a key? box cut off? cannot scroll? AskUserQuestion options unselectable?). Code: `RaBbLE-sCoRE/tui/rabble-tui/src/widgets/modal.rs` (`Permission`, arming delay, "typing cannot answer", read-to-the-end rule from Lane S review `c725873`), key/mouse routing in `app.rs` (`Overlay::Permission`, the `Event::Mouse` arm near line 982, `held_keys_cannot_answer_a_prompt…` test), question prompts arrive via the engine protocol (`rabble-proto`). Suspects: the read-to-the-end gate blocking an answer when the body fits but `max_scroll` is stale; the 2-row/3-row header change shrinking the modal area in a small pane ("modals safe in tiny areas"); the wheel work in `2052401`. Reproduce in a pty (CrumBbLE) and in a real kitty window before touching code; get a screenshot of the broken box.
1. Mark `/reload`s and looks at the 9x3 mark, gaze and blink; fix what he says.
2. Port the final mark to `ui/face.py` (Python twin), run `PYTHONPATH=. ~/.local/share/RaBbLE/rabble-ui/bin/python -P -m pytest tests/test_ui_*.py`.
3. Then the S303 backlog: thinking words (bank at `RaBbLE-sCoRE/ui/thinking_words.txt`, uncommitted? check), crew viewer.

## Prompt for the permission-prompt session
```
You are picking up RaBbLE-UI (the Rust shell in RaBbLE-sCoRE/tui). Claim a session number first (bash RaBbLE-Grimoire/spells/session-number.sh claim permission-prompt). Read RaBbLE-Grimoire/log/handoffs/HANDOFF-S306-RaBbLE-UI-Micro-Mark-and-Permission-Prompt.md (NEXT item 0) and HANDOFF-S303 for context.
Problem from Mark: the question/permission prompt box makes it so he cannot properly give permissions or answer questions. Ask him exactly what happens before changing code. Then reproduce it in a real kitty window (screenshot with grim, close by pid, no pkill -f self-match) and in a pty, find the root cause (suspects in the handoff), fix it with a test, and have a verifier who did not write the fix (CrumBbLE/NiBbLE) confirm. Do not touch the micro mark files (rabble-face/src/micro.rs) or the header layout; another thread owns them. Commit per concept, Pulse Protocol, nothing pushed.
```

## Gotchas
- Do not commit `RaBbLE-BaBbLE/prototypes/terminal-face/__pycache__/*.pyc` (pre-existing dirt) or the held Pocket split docs in the Grimoire.
- `RaBbLE-BaBbLE/intake/` got `RaBbLE-NeBuLA-EyeStates.md` and `rabble-matrix-builder.html` (uncommitted there). The eye-states doc is headed as a Grimoire transcription; Mark has not said whether it moves to the Grimoire. A duplicate wrapper copy `RaBbLE Matrix Builder.html` stays in `~/Downloads`.
