# HANDOFF-S291 · RaBbLE-UI face: visual test of `/face` on kitty (WS1) and VSCodium (WS3)

> Written 2026-10-29 at the end of S291. Everything below passes the unit suite (`tests/test_ui_*.py`, 63 passed), but **the face was only ever measured headless and judged from rendered previews**. Nothing has been seen in a live terminal since the layered renderer landed.
> Mark will have `rabble` running in a terminal on each workspace. The cold-start agent's job is to look, measure, fix what is wrong, and log it. Do not start Rust / render-server work (R3/R4): Mark has to pick it.

## State
- Repo: `RaBbLE-sCoRE`, branch `new-horizons`, local, not pushed. S291 commit `4a89ae1`; the earlier part of the same work (provider aura, markup-crash fix, Ctrl+V fix, divider wiring) was swept into S290's `edbad98`.
- Venv python: `~/.local/share/RaBbLE/rabble-ui/bin/python` (run tests with `-m pytest -q tests/test_ui_*.py` from `RaBbLE-sCoRE/`; the other test files need the server venv).
- Roadmap for the whole area: `log/plans/sCoRE-RaBbLE-UI-Plan.md` § "Roadmap: Mark's ideas" (R1 to R11).

## What changed in S291 (for orientation)
| Area | Where | Notes |
|---|---|---|
| Layered face | `ui/face.py` `Face.background / layer / assemble / compose`, `FaceWidget._tick / _job` | background (envelope, mesh, orb) 8 fps thread; eye + halo layer on its own thread; assembly + noise every tick (30 fps) on the loop; only changed rows are repainted. Jobs are duty-cycled (`_bg_cost * 3`, `_eye_cost * 1.0`). `frame()` is the reference path (mini mark, previews) and `test_compose_matches_frame` keeps the two equal. |
| Eye paint | `ui/eyes.py` | flat-cell fast path (`FLAT = 5.0`), two-tap supersample on big eyes, `halo` / `edge` knobs, lone-speck flatten, `safe` quadrant mode |
| Rig fidelity | `ui/face.py` `rig()` | spacing 2.1 / portal 2.7 / flatten 0.3 / offset 0.93 eye widths; gaze ±26/±12 (eyes only); idle float `12 sin(1.05t)`; portal bob `∓9 sin(1.57t)`; `test_rig_baseline` pins it |
| Aura | `_aura_fn`, `AURA_POLES = 0.08`, `AURA_RING = 0.16`, `PROVIDER_AURA`, `PROVIDER_MUTE = 0.35` | halo starts at the eye edge, nothing inside the orb; provider tint (anthropic orange, google 4-ring, openai green; sCoRE/local = poles) |
| `/face` size | `FaceWidget.-full { height: 100%; min-height: 12 }` | was `1fr`, which gave only the leftover rows |
| VS Code glyphs | `SAFE_GLYPHS` (auto on `TERM_PROGRAM=vscode`; `RABBLE_GLYPHS=safe\|octant`) | Block Elements quadrants only, no octants |
| Divider | `ui/widgets/divider.py` | cyan-to-magenta cosine bounce, 8 fps, under the header |
| Crashes | `ui/widgets/tool_card.py` (title `[` escaped), `ui/app.py` `_pump` (per-event try), `ui/widgets/composer.py` `system_clipboard` (text type only, decode guarded) | |

## Do this (Mark has the face running; do not switch his workspace without saying so)
Windows at handoff (from `hyprctl clients -j`): **WS1** kitty `rabble --continue`, **WS3** `codium` "RaBbLE-Collective - VSCodium". Both 1896x1143 at (12,45).

1. Look first, no switching: `hyprctl activeworkspace -j`, `hyprctl clients -j | python3 -c ...` for class/workspace/geometry.
2. Capture. Hyprland does not render windows on inactive workspaces, so grim needs the workspace in front:
   `prev=$(hyprctl activeworkspace -j | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")`,
   `hyprctl dispatch workspace 1`, wait ~0.5 s, `grim -g "12,45 1896x1143" /tmp/ws1.png`, then workspace 3 the same way, then `hyprctl dispatch workspace $prev`. If the monitor is HiDPI the crop needs the scale applied (see the VSCodium theme-verification and Firefox notes in memory: grim crop needs x2 on HiDPI). Read the PNGs with the image reader.
3. Ask Mark to run `/face` in each (or send the keys with `hyprctl dispatch sendshortcut` per the VSCodium recipe if he says so).
4. Cell aspect (R11, the "sphere squished" report): in kitty, `kitty +kitten icat --print-window-size` and `stty size` give pixels and cells; cell aspect = (px_h / rows) / (px_w / cols), ideal 2.0. In VS Code read the terminal font size and line height from settings.

## Check, in this order
| # | Check | Pass | If it fails |
|---|---|---|---|
| 1 | `/face` fills the transcript viewport (not a short strip), eyes and portals readable | face height = viewport height, min 12 | `FaceWidget.-full` CSS; a short panel always gives a small face (overlay idea in the plan) |
| 2 | **Sphere round**, not squished | orb outline round at the measured cell aspect | no fix yet: R11. Implement cell-aspect correction (read `TIOCGWINSZ` pixel size, `RABBLE_CELL_ASPECT` override, scale y of orb, envelope, mesh and the rig's y), then re-render |
| 3 | **Shadow around the eyes** | a thin glow, no dark smudge | lower `AURA_POLES` / `AURA_RING`, or `Face.halo` (full 0.6) in `ui/face.py` |
| 4 | Provider tint | anthropic session shows a faint orange halo, still muted | raise `AURA_RING` or lower `PROVIDER_MUTE` |
| 5 | Divider | flows smoothly, no hard seam, not distracting | `SPEED`, `CYCLES` in `divider.py` |
| 6 | Mini mark | crisp, no stray specks, no bleed into the void | `halo`/`edge` for the mini in `Face.__init__` (0.45 / 0.55) |
| 7 | **VS Code**: no tofu/boxes anywhere (mini, full eyes, divider), shapes recognisable | only block/braille glyphs visible | confirm `TERM_PROGRAM=vscode` reaches the process (`env` inside the integrated terminal); try `RABBLE_GLYPHS=safe rabble`; if quadrants also look wrong the fallback needs half-blocks only |
| 8 | **Smoothness**: eyes glide, blink reads, typing and scrolling stay responsive while the face runs | no visible stutter; typing never waits | numbers to compare: headless display 27/24/21 per s at 120x40 / 200x55 / 260x70, eye layer 16/12/10 per s. Report the measured fullscreen size and the felt fps |
| 9 | Ctrl+V with an image on the clipboard | nothing pastes, no crash | `system_clipboard` in `composer.py` |
| 10 | A tool result containing `[...]` text (e.g. print a list of tuples) | tool card title renders, session lives | `tool_card.py` `_label` |

Measure CPU with `top -p $(pgrep -f rabble-ui | head -1)` while idle on `/face`.

## Known limits and open questions
- **Pure Python cannot hold 24-30 fps eye motion at fullscreen**: one eye repaint is 10-65 ms. The display ticks at 30 fps but the eyes update 10-16 times a second. Real fix is R3 (render server) or R4 (Rust TUI); Mark has not chosen. Do not build either without him.
- Sphere squish (R11) is **not diagnosed**: the preview renders are round at 1:2 cells. It needs the measured aspect from step 4.
- Rig features not drawn: tilt, breathe, heartbeat, portal energy-ring spin, 40 ms right-eye blink lag, mood states beyond the expression table.
- Blink recedes into the portal (3D rig rule), not the SVG lid scale.
- Provider colours are third-party brand values (not palette values); strengths and mute are guesses judged from previews.
- `log/agents/*.json` churn in the Grimoire is left uncommitted on purpose (S290 anti-clobber note).

## Start
```bash
cd ~/RaBbLE-Collective
head -20 RaBbLE-Grimoire/log/SESSION-LOG.md          # S291 entry
cat RaBbLE-Grimoire/log/handoffs/HANDOFF-S291-RaBbLE-UI-Face-Visual-Test.md
git -C RaBbLE-sCoRE log --oneline -3
```
Claim a new session number first (check SESSION-LOG and `spells/agent-register.sh` status; S284/S285 were taken twice).
