# HANDOFF-S307: picker, crew views, crew rules

**State:** all committed in RaBbLE-sCoRE `new-horizons` (`885c271`, `a4eab6c`, `8d12cba`), nothing pushed (46 ahead). Grimoire `ab47fb7` holds the persona rule change. Tests green, release built, never run live.

**First, Mark:** `/reload`, then try: an AskUserQuestion (keys: Up/Down or 1-9, Space/Enter multi, "Other", Left back, Esc declines); Ctrl-G through hidden, panel, viewer (panel needs 96+ cols; viewer: Tab organ, `x` stop, `q` close); a permission ask while the viewer is open (should close it).

**Open questions for Mark:**
- Do `y`/`a` on a plain allow/deny prompt still stay dead until the body is scrolled to the end? S307 found no fault there and changed nothing.
- ~~Hard cap on organ spawns~~ RULED (Mark): prompt rules for now; engine/harness limit roadmapped under E1 in `log/plans/sCoRE-RaBbLE-UI-Rust-Plan.md`.
- Push sCoRE `new-horizons`?

**Then:** Python twin of the 9x3 micro mark (`ui/face.py`, `ui/gaze.py` exist); wire the thinking-words bank (`ui/thinking_words.txt`); micro-mark live check (HANDOFF-S306 context).

**Files:** `tui/rabble-tui/src/widgets/crew.rs`, modal picker in `tui/rabble-tui/src/` (see `885c271`), `crew/roster.py`.
