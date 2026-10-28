# HANDOFF-S287 · RaBbLE-UI: capability model, park, fine eyes. Built and unit-tested; now try it in a fresh `rabble`

> Written 2026-10-28 at the end of S287. Supersedes the "test" half of `HANDOFF-S285-RaBbLE-UI-Live-Test-2.md`
> (its kitty checklist still stands; the scroll and approve-modal items are reworked below).
> Everything here passes the unit suite (161 passed, 1 skipped). **Nothing has been tried by Mark in a live kitty session.**
> Start `rabble` from the Collective root (`~/RaBbLE-Collective`). The cold-start agent's job is to watch Mark test, fix what breaks, and log it. Do not start face phase 2 or the v0.5 work until Mark says so.

## What S287 built (RaBbLE-sCoRE, branch `new-horizons`, local, not pushed)
| Commit | What |
|---|---|
| `98f3bc5` | Permission modal fits short tiled panes (compact buttons under 26 rows, titles dropped under 12, body shrinks). Transcript scroll: reader-driven `_following`, re-pin on content growth, a jump to the top while blurred or within 2s of refocus is re-pinned; `RABBLE_SCROLL_DEBUG=1` writes `/tmp/rabble-scroll.log` |
| `b2a1721` | Glitch curve anchored per model (opus clean, sonnet faint, haiku 0.30) |
| `3d33e99` | **Park**: at 80% context the warm lead writes a handoff + session-log entry (commit only at a good commit point, never push), the engine checks the file, a fresh session starts from it. `/park now|continue|auto|ask|off|continue on|off|status` |
| `7cb9f5d` | **Fine eyes** (`ui/eyes.py`): anti-aliased octant-resolution eyes and portals, per `RaBbLE-NeBuLA/specs/rig/entity-rig.svg`. Mini 5.9 ms, full 28.7 ms per frame live average |
| `ecea75f` | **Capability model** (Entropy Tracker v0.4): `orchestra/capabilities.json` by category (general/coding/tools/recall), entropy = capability lost, transient decay, partial re-grounding credit, `Bloat`, header shows tier + capability |
| `38d5d3f` | `RABBLE_PARK_AT=15 rabble` moves the park point so the flow can be tried in a small session |
RaBbLE-OS `f144406`: `smart-movewindow.sh` and `split-dir-daemon.sh` fixes (Hyprland tiling; Mark confirmed fixed).

## Try these (Mark drives; the agent watches and fixes)
1. **Header and `/status`**: line 2 reads `<model> · mode default · trusted 85 · crew off` (opus 85, sonnet 70, fable 95, haiku `strict 35`, local qwen `strict local 25`). Line 4: `ctx N% · ◆ stable code 88`. `/status` shows capability, coding/tools/recall and the bloat summary (tokens, token-reads, turns to park). A fresh launch before the model reports shows `standard 50` (the `default` entry), then corrects.
2. **`/model sonnet|opus|haiku`**: opus entity clean, sonnet a faint flicker, haiku clearly glitched but readable; a switch bump (-5) must not show as sonnet-level tearing. Judge the curve by eye; anchors are `SIGNAL_CURVE` in `ui/face.py`.
3. **`/face` and the mini mark**: smooth ovals, thin rim, flat dark portals. Check CPU in `top` (should be low). Previews: `RaBbLE-BaBbLE/tmp/face/new-*.png` (gitignored).
4. **Park, early**: `RABBLE_PARK_AT=15 rabble`, chat until context passes 5% (warning) and 15% (park). Expect: notice, the lead writes `RaBbLE-Grimoire/log/handoffs/HANDOFF-parked-<stamp>-<sid>.md` and a session-log entry, a fresh session starts and waits (3 lines on where things stand). Check: the handoff alone is enough to continue; nothing was committed unless it was a clean commit point; nothing was pushed; the permission prompts for those writes make sense. Then `/park continue` (carries on once) and `/park continue on`.
5. **Park, manual**: `/park status`, `/park ask` (notice only), `/park off`, `/park now`.
6. **Bloat/eta**: header shows `ctx 38% (park in ~5)` once the fill rate is known; a big jump should park early ("one more could pass 95%").
7. **Re-grounding**: after `/compact` (structural damage, -20 capability) read a file or run `pytest`; capability should rise by a point or two and never past half of the loss.
8. **Scroll**: scroll up, switch window, let Rabble stream, come back: must not jump to the top. If it does, run with `RABBLE_SCROLL_DEBUG=1` and read `/tmp/rabble-scroll.log` (call stack per jump).
9. **Approve modal in a short pane** (tile Rabble beside another window, trigger `rm`/`git push`): buttons visible and clickable; `1/2/3` and `n` then a reason work.
10. Still open from S285: `/crew on` live, `--continue`/`/resume` header model, slash completion, mouse selection, tmux, SSH. Inline-code "lsshows" did not reproduce in Textual 8.2.8; confirm by eye.

Run the suite: from `RaBbLE-sCoRE`, `~/.local/share/RaBbLE/rabble-ui/bin/python -m pytest -q tests/test_ui_*.py tests/test_orchestra_*.py tests/test_park.py` (about 75 s).

## Next, in order (each needs Mark's go)
1. **Entropy vs stability split + visuals** (Entropy Tracker v0.5, *Direction* section). Entropy = the model's capability, shown as steady **static**; stability = session health plus bloat, shown as **glitch and breaking**, worse as stability falls and bloat rises. Change `signal_level` into two inputs; bloat gets its own term so a filling window tears the entity before it costs trust.
2. **Benchmark-derived capabilities.** Registry entries hold raw benchmark rows (name, version, date, source); category scores are derived; an ingest spell rewrites the registry from a curated file; no scraping. **Mark decides:** absolute scale vs frontier-relative (recommended: relative, reference version stored, `capabilities.lock`) and which benchmarks per category.
3. **Face phase 2: alive.** React to mouse (gaze follows the pointer over the face), typing (lean in, listening), idle drift (slow wander, breathing, float), focus shifts (blur: eyes drift/close; focus: snap to attention); states: thinking, speaking (portal pulse in time with the stream), tool use, denied, error, glitch/break. Both sizes read well and share one renderer; the eye cell cache is keyed on the rig, so continuous motion needs the cache key coarsened or per-part caching to stay near 6 ms mini / 30 ms full.
4. Small: `/resume` picker marks parked sessions ("open the handoff instead"); auto-allow the lead's write to the handoff path; capability observed in use (tool failure rate, test pass rate) as a labelled adjustment.

## Open items
- **Placeholders to confirm:** haiku general 35 (strict), every coding/tools/recall number, the category weights (`CATEGORY_WEIGHT`), the credit amounts (`GROUND`), `DECAY` 0.8.
- `orchestra/trust.py` still needs a NiBbLE review before `trusted` is relied on broadly (needs `/crew on`).
- `can_use_tool` paths beyond `rm` (git push, `mcp__`, edits outside cwd, a CC deny rule) untested live.
- Uncommitted elsewhere: RaBbLE-OS `ansible/packages/manifest.yml` (`edition:` on all entries) and `spells/edition-audit.sh` (OS Editions W1, correct but unreviewed; keep or revert). Grimoire carries other sessions' uncommitted Pocket and Crew edits; commit only your own files.
- sCoRE commits are local on `new-horizons`; nothing is pushed.

## Read first
1. `RaBbLE-Grimoire/RaBbLE-sCoRE/RaBbLE-sCoRE-Entropy-Tracker.md`: *Capability Model (v0.4)* and *Direction (v0.5, planned)*.
2. `RaBbLE-sCoRE/orchestra/`: `capabilities.json`, `capabilities.py`, `entropy.py`, `park.py`; `ui/`: `app.py` (park flow: `_check_park`, `_begin_park`, `_finish_park`, `_park_command`), `eyes.py`, `face.py`, `widgets/transcript.py`, `widgets/permission.py`, `widgets/header.py`.
3. Tests: `tests/test_park.py`, `tests/test_orchestra_entropy.py`, `tests/test_ui_transcript_scroll.py`.

## Fixtures
`RaBbLE-BaBbLE/tmp/face/prev.py`: font-independent PNG preview of the face (`PYTHONPATH` not needed): from that folder, `~/.local/share/RaBbLE/rabble-ui/bin/python -P prev.py full 100 30 calm out.png` (also `mini 24 6`). Gitignored scratch.
