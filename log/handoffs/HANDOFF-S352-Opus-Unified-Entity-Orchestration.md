# HANDOFF-S352 (Opus): orchestrate the unified entity and NeBuLA unification

Date: 2026-11-18. For: an Opus session that designs the core and fans out Sonnet and Haiku agents. Branch `new-horizons` everywhere. Nothing from S352 is committed yet (Grimoire has uncommitted docs; commit them first, see Preflight).

## Read first (in this order)
1. `log/plans/Unified-Entity/Unified-Entity-NeBuLA-Unification-Plan.md` (the plan: rulings 1 to 10, inventory, slices U1 to U12, open questions)
2. `log/plans/Unified-Entity/Unified-Entity-Canon.md` (rules in force; sections 6, 9, 10)
3. `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Format.md` (`.rbl`; the brand entity stays native for now)
4. `log/handoffs/HANDOFF-S350-Mapper-and-Unified-Render.md` section 2 and 3 (web vs device agreement, boot animation)
5. `RaBbLE-NeBuLA/RaBbLE-NeBuLA-Architecture.md` (single renderer, two backends) and member `AGENT.md` + `CONTEXT.md` before touching any member
6. Side track, not this handoff's job: `log/plans/EP2-Accounts-Encryption-Spec.md` section 0a (encryption proposal, slices E1 to E7)

## Mark's goal in one paragraph
One canonical RaBbLE entity: one spec, one registry of render data, one NeBuLA vocabulary (poses, expressions, moves, effects, timelines). Every surface draws it with its native path: Portal and Pocket web through NeBuLA's Canvas2D or Three.js backend, Pocket hardware through nebula_lite (C), the terminal face in Rust, the 3D rig with the infinity portals included. Effects are named layers Mark can tweak in Studio. Pocket holds 60 fps; effects yield, the frame rate does not. Drifter renders are classified and moved to Chrysalis.

## Ruled (do not re-litigate)
Registry JSON plus native renderers; the brand entity is not `.rbl` for now. Pocket web uses NeBuLA Canvas2D or Three. nebula_lite renders the same data spec (via the registry and golden frames). The 3D rig is in scope. All Pocket effects port into NeBuLA. Device stays 60 fps. Effects are tweakable layers (Studio). One NeBuLA language everywhere. Classify and retire drifters. Pocket occlusion is the reference (S323 ruling 37). Full list: the plan.

## Open (ask Mark before building on them)
- Is the Portal entity the NeBuLA Canvas2D/alive rig, and do the registry reference numbers come from the Puppet Spec rig with Pocket proportions as a surface profile?
- Sign-off on the inventory statuses (U8): alive backend (merge or keep), the Ball, which Xperimental drops are drifters.
- Ruling 7 reading: device never below 60 fps, effects yield; web governor is a fallback only.
- Which effects the device carries at all.

## What Opus does itself (do not delegate)
1. **Finish U1**: Pocket-versus-rig occlusion at a matched camera (about 17 degrees with perspective, never 0). Pocket frame: `cd RaBbLE-Pocket/sim && NO_ORBIT=1 ./build.sh <name> 0 6 0.5 0 0 0` then `sim/out/<name>.png`. Rig: Playwright against `Unified-Entity-Puppet-Spec.html`; the page keeps `prop` internal, so use a copy with `prop='pocket'` substituted; click `#ortho` off and set `#elev` through an `input` event. Poses: idle, blink, portal swap, turn. Record real draw-order differences; correct the rig where it differs.
2. **Design the registry schema (U2) and layer model (U9)**: `registry/entity/rabble.entity.json` (genome, rig and move constants, timelines, poses, expression curves, palette, ordered layers with on/off, opacity and params, surface profiles, per-effect cost tier and per-surface support). Write the schema and a validator spec before any agent generates from it. Retire the stale Canon 10.1 sample.
3. **Decide the NeBuLA vocabulary** (names for poses, expressions, moves, effects, timelines) and merge or keep the alive backend.
4. **Set the 60 fps method (U11)**: how per-effect device cost is measured (host harness `sim/host_render` prints per-frame time; real numbers need hardware, which Mark flashes himself) and the rule for demoting an effect.
5. **Review every agent's output** against the schema and the canon before it lands.

## Fan-out plan
Pin the model on every spawn (`model: "sonnet"` or `"haiku"`; the Agent tool inherits the parent otherwise, which is how the S193 fleet inherited Opus). Give each agent a self-contained brief (they start cold), the files to read, the output path, and "read-only unless stated". Use `effort: "lower"` for the mechanical ones. Independent agents go in one message.

### Wave 1: read-only, parallel (start immediately, after Preflight)
| Agent | Model | Brief | Output |
|---|---|---|---|
| Inventory per member: NeBuLA, Pocket, World, sCoRE (tui + ui), BaBbLE, Xperimental, Chrysalis | sonnet x7 | Read each entity-render file the plan lists (and find any it missed). Per file: what it draws, which spec it follows, last commit date, who imports or links it, whether it is a copy of another file (diff it), is it published (Xperimental drops have URLs). Verify or correct the proposed status | one table per member in `scratchpad/inventory-<member>.md` |
| Effects census | sonnet x2 (NeBuLA `src/effects` + backends; Pocket `nebula_lite` + `scene.c` + mock + `pocket-entity.js`) | List every distinct effect each draws, its parameters, cost notes, and which surface draws it today | `scratchpad/effects-nebula.md`, `effects-pocket.md` |
| Constant extraction | sonnet x2 (web rig numbers: `live.js`, `alive-backend.js`; device numbers: `scene.c`, `nl_scene.h`) | Extract every numeric constant that defines the entity (proportions, durations, easings, colours via the Palette only, camera, tilt) with file:line | `scratchpad/constants-web.md`, `constants-device.md` |
| Link check | haiku x2 | For each file in the inventory, grep the repos and Grimoire for references (imports, links, docs, URLs, wrangler routes) so a move cannot orphan anything | `scratchpad/refs.md` |
| Expression catalogue | haiku x1 | List every named pose, expression, state and move across the Canon, spec, `FACE`/`EXPR` tables, `scene.c` states and the terminal face, with where each is defined | `scratchpad/expressions.md` |

Opus then merges these into U8's final table, the effect list for U10, and the diff of web versus device constants that feeds U2.

### Wave 2: build, after Opus freezes the schema (each agent gets the schema and validator spec)
| Agent | Model | Scope |
|---|---|---|
| Registry + validator | sonnet | `registry/entity/rabble.entity.json` from the extracted constants, plus the validator and tests |
| Generators | sonnet x2 | JS tuning for NeBuLA/Pocket web; C header for `scene.c`/`nl_scene.h`. The device side is gated on the Pocket core/apps reorg (S323): generate to a branch and do not wire it in until Mark clears it |
| Golden frames | sonnet | `sim/host_render.c` PNGs vs web output, pixel diff with tolerance, runnable in CI; fixtures for idle, blink, swap, turn |
| Pocket web onto NeBuLA | sonnet | replace `build-entity.py` and `pocket-entity.js` with NeBuLA Canvas2D/Three; keep gaze, mic bars, real clock, mesh API, backdrop, snapshot as NeBuLA inputs; the web governor stays; build NeBuLA `dist/` first (S324), dev only through `dev-serve.sh` |
| Effects port | sonnet per effect cluster | one NeBuLA effect per Pocket effect, with cost tier and per-surface support; each lands with a visual test |
| Capability table generator | haiku | emit the per-effect, per-surface support table into the NeBuLA docs from the registry |
| Drifters to Chrysalis | sonnet | only after Mark signs off the inventory; move with a pointer left behind (condense, not delete); update `INDEX.md` and member docs; never touch published Xperimental drops without per-drop sign-off |
| Docs and index upkeep | haiku | gist regeneration (`bash spells/distill-gists.sh`), index lines, cross-links |

## Rules for every agent (put these in each brief)
- No Co-Authored-By trailers. Pulse commits: `[impulse] ~ [organ] >> [revelation] // %STATE%`. gitleaks before each commit.
- Python: `uv venv .venv`, `uv pip install`, run `.venv/bin/python`; never bare pip.
- Colours come from `RaBbLE-Agent/RaBbLE-Palette.md` only; no invented hex values.
- Never flash Mark's hardware; never `pkill -f`; no live-desktop testing (no waybar, wtype, dispatch); use headless Playwright, the VM or the host harness.
- Dev workflow is `dev-serve.sh` only; rebuild NeBuLA `dist/` after `src/` edits.
- Docs live in the Grimoire; members hold code only. Avoid em dashes in web copy.
- Do not use `git add -A`; stage named files. Check live sessions (`ListAgents`) before touching a dirty tree.
- NeBuLA owns effects rendering, Aether owns CSS, World is scaffold only.
- Permissive third-party only; no copyleft code in the entity path.
- Do not mutate shared files to scope a commit.

## Preflight (Opus, before fan-out)
1. Commit the S352 docs: `git add INDEX.md log/plans/EP2-Accounts-Encryption-Spec.md log/plans/Unified-Entity/Unified-Entity-NeBuLA-Unification-Plan.md RaBbLE-Pocket/RaBbLE-Pocket-ZNP-Badge-Research.md log/handoffs/HANDOFF-S352-*.md` (leave `log/sessions/*` alone), gitleaks first. INDEX lacks lines for the two handoffs.
2. Claim the next session number first (concurrent sessions have collided before).
3. Read `bash RaBbLE-Grimoire/spells/status.sh` and `ListAgents`; do not sweep a dirty tree.
4. Ask Mark the four open questions above; wave 1 does not need the answers, wave 2 does.

## Exit criteria for this handoff
Wave 1 reports merged into a signed-off inventory table; registry schema and validator spec written and agreed; U1 closed with a recorded side-by-side; wave 2 scoped per agent with briefs ready or running. Then update `log/DECISIONS.md` (S352 rulings: encryption and unification), the CLAUDE.md/AGENT.md "Current State" block, and add the session entry with `spells/end-session.sh`.
