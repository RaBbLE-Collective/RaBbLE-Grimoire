# HANDOFF-S353: unified entity, wave 2 (build) briefs

Date: 2026-11-18. From: S353 (Opus). For: the Opus session that launches wave 2, after Mark signs off the gate below. Branch `new-horizons` everywhere.

## State at hand-off
- **Wave 1 done.** The census (14 read-only agents) is in `log/plans/Unified-Entity/census-S353/` (constants with file:line, effects per surface, expression names, per-member inventories, code references). The doc references (`refs-docs`, 1.3 MB of noisy grep) were not kept; rerun them per file before a move.
- **U1 closed on draw order.** See `Unified-Entity-NeBuLA-Unification-Plan.md`, "U1 result", with evidence and scripts in `log/plans/Unified-Entity/u1/`.
- **U8 inventory merged** into the plan, with proposed statuses.
- **Schema drafted (U2, U9, vocabulary, U11 method, validator spec):** `registry/entity/RaBbLE-Entity-Registry-Schema.md` + `rabble.entity.schema.json` (it meta-validates under Draft 2020-12).
- Mark's S353 rulings 11 to 14 are in the plan.

## Gate status (S353, second batch)
Ruled: one web backend (15), occlusion and rest position (16), eyes (17), all effects as NeBuLA effects incl. `src/effects/` (18; W2-7 gains a cluster (f) for the standalone modules), vocabulary (19). **W2-1 can start.** Still gated: W2-10 (needs the U8 sign-off) and the turn's device support (D6; W2-1 marks `pocket_hw` support for `turn` as `none` until ruled).

## Gate (original)
The plan's "Open questions for Mark": the U8 table (incl. alive as the canonical 2D backend, the Chrysalis layout), the schema and vocabulary, U1-a (cut mode), C5 (eye fill), turn on the device, and NeBuLA's standalone effects. Record the answers in the plan and `log/DECISIONS.md`, then edit the schema doc's section 9 into rulings and set its status to `frozen`.

## Rules block (paste into every brief)
```
Workspace: /home/rabble/RaBbLE-Collective (members are subdirectories; docs live in RaBbLE-Grimoire). Branch new-horizons.
Read first: RaBbLE-Grimoire/registry/entity/RaBbLE-Entity-Registry-Schema.md, the member's AGENT.md + CONTEXT.md.
- Commits: Pulse Protocol `[impulse] ~ [organ] >> [revelation] // %S###_STATE%`; no Co-Authored-By trailers; stage named files only (never git add -A); run gitleaks before each commit. Commit only if the brief says so.
- Run `bash RaBbLE-Grimoire/spells/mine.sh` before staging; do not touch files another session has dirty; do not mutate shared files to scope a commit.
- Python: `uv venv .venv && uv pip install ...`, run `.venv/bin/python`; never bare pip or python.
- Colours: palette names from RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md only; no hex in the registry; never invent values.
- Never flash hardware; never pkill -f; no live-desktop testing (no waybar, wtype, hyprctl dispatch). Use headless Playwright, the VM, or sim/host_render.
- NeBuLA: rebuild dist/ after src/ edits; dev only via dev-serve.sh. NeBuLA owns effects rendering, Aether owns CSS, World is scaffold only.
- Permissive third-party only (Apache/BSD/MIT/CC0), isolated with LICENSE+NOTICE.
- Docs go to the Grimoire; members hold code. Avoid em dashes in web copy.
- Report: files changed, tests run with their output, anything skipped and why.
```

## Briefs (pin `model` on every spawn; independent ones in one message)

| # | Agent | Model | Depends on | Brief |
|---|---|---|---|---|
| W2-1 | Registry + validator | sonnet | gate | Write `registry/entity/rabble.entity.json` from `census-S353/constants-web.md` (base = live.js numbers) and `constants-device.md` (the `pocket_hw`/`pocket_web` profiles), poses from `registry-spike/poses.role.json`, names from section 3 of the schema doc, effects and layers seeded from section 5.3 and `census-S353/effects-*.md` (support from the corrected table in the plan). Write `registry/entity/validate.py` implementing V1 to V12 and `registry/entity/tests/` (one passing fixture, one failing fixture per check). Port the no-touch check from `registry-spike/notouch.py`/`notouch3d.py`. Expected: V5 passes for base forms and fails for today's planar device swap if a profile uses it. Commit in the Grimoire. |
| W2-2 | Generator: web | sonnet | W2-1 | `registry/entity/gen/js.py` emits `RaBbLE-NeBuLA/src/registry/entity.generated.js` (ES module: frozen object, version stamp, palette resolved from Palette.md). No hand-ported constants: alive-backend.js, threejs-backend.js and eye-behavior.js import from it, one constant group at a time, each step with a headless screenshot before and after (they must match except where the registry deliberately changes a value; list those). Rebuild dist. Commit in NeBuLA. |
| W2-3 | Generator: device | sonnet | W2-1 | `registry/entity/gen/c.py` emits `nl_entity_generated.h` (`#define`s and `static const` tables, floats with `f`). **Gated on the Pocket core/apps reorg (S323):** generate onto a branch `registry-header` in RaBbLE-Pocket and do not wire it into `scene.c` until Mark clears it. Show the diff of every constant `scene.c` would change. |
| W2-4 | Golden frames | sonnet | W2-1 | Fixtures (idle, blink, swap 0.25/0.5/0.75, turn) from `sim/host_render` (`u1/host_render_u1.c` adds `FLIP=`) and from the web rig (`u1/rig_capture.py`: stepped clock, Playwright). A pixel-diff tool with tolerance and masks (glass, mesh), runnable in CI, in `registry/entity/golden/`. First run documents today's known diffs (U1 table a to e) as expected failures, not passes. |
| W2-5 | **Unified web backend, part 1: rig mechanics** (ruling 15) | sonnet | W2-2 | One 2D web backend grows out of alive-backend.js (the Portal's `backend="alive"` keeps working). Port from live.js, reading the registry: colour volume, portal tilt (EPS0/EPSK), `opening_clip` cut with rest portal Y 1.00 (ruling 16: the lower rim must not cover the eye at idle), white eyes with pole outline and rim fade (ruling 17), portal swap 1.45 s with depth arc, turn, forms, infinity flow. Keep alive's aura, boot and expressions as NeBuLA effects. Verify with W2-4 fixtures and headless screenshots of World `index.html` through `dev-serve.sh`. |
| W2-6 | **Unified web backend, part 2: Pocket web** | sonnet | W2-5 | Port the Pocket page's effects and APIs into the same backend as the `pocket_web` profile: `mount`, `snapshot`, `look`, `audio(levels)`, `setQuality` → profile, `backdrop`, `meshSide`, clock input for the glass. Switch `companion-app/web/portal.js` to it; then delete `build-entity.py` and `public/entity/pocket-entity.js`. The web governor stays as a fallback behind the yield ladder (schema section 7). Afterwards the old Canvas2D entity (eye-system, portal-system, eye-behavior numbers) folds in or retires, and the Catalog page mounts the unified backend. |
| W2-7a..e | Effects port | sonnet each | W2-1, W2-5 | One cluster per agent: (a) backdrop + ring, (b) mesh + Orbit handoff, (c) listening strands + absorb + bars, (d) glass, (e) lens body + speak waves + insight burst. Each effect gets a registry definition (params, priority, cost tier, per-surface support, provenance) and a NeBuLA implementation with drives, and lands with a visual test. Haze and bokeh: web only (S353). |
| W2-8 | U11 host proxies | sonnet | W2-1 | For each device-supported effect, run the fixture set with the effect on and off in `sim/host_render` (no hardware): delta prims, host ms, damaged bands. Write `registry/entity/measurements/pocket_hw-host-<date>.json` and a profiling-build spec for Mark to flash (cycle fixtures, log `nl_prof`). Start with the known misses: listening, speaking, mid-swap. |
| W2-9 | Capability table | haiku, effort lower | W2-1 | Generate the per-effect, per-surface support table from the registry into the Grimoire NeBuLA docs (`RaBbLE-NeBuLA/RaBbLE-NeBuLA-Effects-Support.md`); add the index line. |
| W2-10 | Drifters to Chrysalis | sonnet | gate (U8 signed) | Move only rows Mark signed as drifters, using the Chrysalis layout he picked: provenance README, then `.MOVED.md` pointer or meta-refresh stub, Chrysalis commit first, then the origin repo. Update the hard references (plan, "Link safety") and the `alive-backend.js:5` + `alive-port/README.md` citations. Never touch a published Xperimental drop without per-drop sign-off. |
| W2-11 | Docs upkeep | haiku, effort lower | after each landing | `bash spells/distill-gists.sh`; add `gist/RaBbLE-Entity-gist.md` (Canon 10: no gist describes the body); index lines; cross-links. |

## Opus's own work in wave 2
Review every agent's output against the schema and the canon before it lands (the handoff's item 5). Merge nothing that adds a private name, a hex value or a hand-ported constant.

## Exit
Registry v0.1.0 validated in CI; web generator wired into alive and Three; golden frames running; the device header on a branch; Pocket web on NeBuLA; drifters moved; the support table generated.
