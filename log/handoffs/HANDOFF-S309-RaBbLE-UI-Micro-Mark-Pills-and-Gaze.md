# HANDOFF-S309: micro mark pills, glance, pointer-exit

**State:** all committed in RaBbLE-sCoRE `new-horizons` (`0c14687`..`098ae9c`, tagged %S308_STATE% by mistake), nothing pushed. 246 Rust tests pass; release built; never seen live.

**First, Mark:** `/reload` and look at: the 10-col mark (portals lower, one black row inside each far edge, five-row pills), gaze down/up (down: left out, right sinks; up: left sinks, right out; 1 px each way), the up-glance (idle every 12-37 s, and on a mood flash), the eyes following the pointer out to the right (4 s).

**Open:**
- Up-gaze centre shift: the mark never sees a target above it (gaze y = (row-1.5)/12, transcript is rows 4+). Proposal: shift the compact mark's centre to ~row 6, double the vertical range. Unanswered.
- More glance signals (organ finished, notice, usage change); only mood flash is wired.
- More vertical travel needs a fourth cell row (header 3 to 4 rows); declined for now.
- VSCodium grid: three-row pills, 1 px; not shortened.

**Then:** Python twin of the mark (`ui/face.py`, `micro_pixels`/`micro_cells`; still 7x2 pills; port `tui/rabble-face/src/micro.rs` as written). S307 leftovers: HANDOFF-S307.

**Files:** `tui/rabble-face/src/micro.rs` (geometry in `Geo`, `grid()`), `tui/rabble-tui/src/app.rs` (`gaze` mod, `steer_gaze`, `on_input` pointer-exit, `flash`), `tui/rabble-tui/src/widgets/face.rs`.
