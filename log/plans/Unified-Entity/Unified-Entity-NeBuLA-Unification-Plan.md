# Unified Entity and NeBuLA unification plan

```
status: design; U1 closed, U8 inventory merged, registry schema drafted (S353), awaiting Mark's sign-off · S352/S353 · 2026-11-18 · owner: Mark (direction), NeBuLA + Pocket + World members
```

Mark's goal (S352): the Pocket web surface, the Pocket hardware renderer (nebula_lite) and the entity render on the Portal are manifestations of **one spec with one set of render data**, each drawn by its **native rendering path**. Everything the Pocket web page added on top of the mock moves into NeBuLA. NeBuLA effects are portable to most surfaces, and where a surface cannot do an effect (nebula_lite will not reach full parity) the docs say so.

Builds on, does not replace: `Unified-Entity-Canon.md` (rules in force, section 10 registry proposal), `Unified-Entity-Puppet-Spec.md` (numbers), `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Format.md` (`.rbl`, stays native for the brand entity for now), `log/handoffs/HANDOFF-S350-Mapper-and-Unified-Render.md` section 2.

## Ruled (Mark, S352)

1. **Shared data is a registry JSON plus native renderers.** `registry/entity/rabble.entity.json` is the only place a number lives (genome, rig and move constants, timelines, poses, expression curves, palette, surface profiles). Generators emit JS tuning for web surfaces and a C header for the device. Each surface keeps its own draw code. The brand entity is **not** expressed as `.rbl` for now; revisit after the golden-frame gate shows what the four primitives cannot express.
2. **First slice is a Pocket-versus-rig occlusion comparison**, to settle Canon section 9.7 before the registry numbers freeze. Pocket's occlusion is the reference (S323 ruling 37).

## Ruled (Mark, S352, second batch)

3. **Pocket web page renders through NeBuLA's Canvas2D or Three.js backend.** The SVG mock path (`pocket-entity.js`, `build-entity.py`) retires. This answers the open Canvas2D-versus-SVG question.
4. **nebula_lite renders the same data spec as NeBuLA.** Either it is folded into NeBuLA as a backend (a C/native backend under the NeBuLA name) or it is held to the registry by golden frames. Both satisfy this; the registry route is the one planned (U2 to U4). The device never interprets JS, so "the same spec" means the same registry numbers, timelines and layer definitions, proven by tests.
5. **The 3D rig with the infinity portals is part of the unification.** It is the Puppet Spec's live rig (`Unified-Entity-Puppet-Spec`, `live/live.js`) and its descendants (the NeBuLA `specs/rig`, the Ball). It reads the same registry as every other surface.
6. **Every effect Pocket can render is ported into NeBuLA** as a named, registry-defined effect.
7. **Pocket stays at 60 fps.** Frame rate is a device constraint, not a tunable: effects that do not fit the 60 fps budget are `reduced` or `none` on the device (or pre-baked), never allowed to drop its frame rate. The web frame governor (60, 45, 30, 20) stays a web-only safety net. (My reading of "what the entity renders dynamically is FPS restricted": dynamic work is budgeted to 60 on the device. Correct me if you meant something else.)
8. **Effects are tweakable as layers.** The entity is an ordered stack of named layers (backdrop wash, hazes, stars, mesh, glow, body, bars, glass...). Each layer has an on/off, opacity and its own parameters in the registry, and a surface profile picks the defaults. Tweaking is done in NeBuLA Studio (Mark composes; agents do not redesign the entity blind, per the World-design-is-Studio-driven rule).
9. **One NeBuLA language for every rendered expression of the entity.** Pose, expression, move, effect and timeline names are the registry's vocabulary on every surface (web, 3D, device, terminal). No surface keeps private names.
10. **Classify every current expression and retire the drifters.** Each existing entity render gets a status: canonical, derived (generated from the registry), reference (kept as a spec or test fixture), or drifter. Drifters move to Chrysalis (or its reliquary). One canonical RaBbLE entity (the registry plus its spec) is declared.

## Ruled (Mark, S353)

11. **Registry base = the Puppet Spec rig numbers; Pocket proportions are a surface profile** (answers open question 1). Pocket's occlusion stays the reference for draw order (ruling 37).
12. **Ruling 7 confirmed as written:** the device never drops below 60 fps and effects yield. The web Pocket page also targets 60; the 60/45/30/20 governor is only a fallback.
13. **Device effects:** everything that can be ported within the 60 fps budget. Bokeh and haze are not required on the device. Every effect and layer must be dynamically renderable, so Mark or RaBbLE can use layers to express meaning or state. **The eyes define the entity; the mesh and the orb/Orbit are the other key expression.** All other layers are driven by input, state or expression, and depend on what the surface can do. (Mark's words: "Everything that can be ported in the FPS budget. The Bokeh/Haze is not required.")
14. **Alive backend:** merge or keep is decided from the inventory (below) and signed off with the U8 table.

## Ruled (Mark, S353, second batch)

15. **One NeBuLA web surface.** The Pocket web page, the alive backend and the Puppet Spec rig unify into one 2D web backend. It takes alive's aura, boot and expressions, the rig's mechanics (tilt, cut, swap, turn, colour volume, infinity) and the Pocket page's APIs and effects (mesh, strands, glass, gaze, audio, snapshot). Portal and Pocket web are profiles of it. The Three.js backend stays the 3D path (Ball, Web3D). The Portal keeps its `backend="alive"` attribute working during the move.
16. **Occlusion (closes U1-a): Pocket's dynamics, the rig's rest position.** Pocket's occlusion follows the proper rules. Its fault is the rest position: the portals sit too far onto the eyes (offsets 0.86 and 0.79 eye half-heights), so at idle the lower portal's near rim covers the eye. At rest the lower portal must not cover the eye. `cut.mode` = `opening_clip` (Pocket). Portal Y at rest = 1.00 (Canon default) on every profile, including Pocket; Pocket's `per_side_offset` is dropped.
17. **Eyes (closes C5):** pure white fill with a palette-coloured outline (the pole colour from the colour volume) and a slight fade toward the rim (as the device's orb gradient does, white core to pole edge). `colour.eye_fill` = `white`; a new `colour.eye_outline` = `pole`; the fade is a parameter of the `eyes` effect.
18. **All effects become NeBuLA effects** (closes D7). Every effect on any surface, including NeBuLA's standalone `src/effects/` modules, becomes a registry-defined NeBuLA effect with per-surface support, for range and to make the engine more robust.
19. **Vocabulary approved:** `thinking` is a state; `ponder` and `process` are its moods.

Still open: the U8 sign-off (Mark is reviewing the table) and the device turn (D6).

## Inventory of current entity renders (U8, merged S353 from the wave-1 census)

The census read seven members file by file (per-member tables, md5 twins, last commits, importers, URLs). The full reports were scratch output; their findings are folded in here, and the S352 first-pass table is superseded. **Every status is a proposal until Mark signs it off.**

| Render | Where | Finding (S353) | Proposed status |
|---|---|---|---|
| NeBuLA **alive** backend | `RaBbLE-NeBuLA/src/backends/alive-backend.js` (+ `alive-gl.js`, a GL shim for Canvas2D calls) | **This is what the Portal mounts** (`RaBbLE-World/index.html:35`, `account.html:72`: `backend="alive"`, CDN v0.1.0). It is a full independent renderer (1223 lines) with its own boot, expressions and roughly 15 aura layers. Its proportions match the rig baseline (pw 2.69). It has none of the rig mechanics (tilt, cut, turn, swap, colour volume, infinity). Origin: BaBbLE `reliquary/2026-09-26-entity-harness` | **canonical 2D web path, kept as a named backend**; first registry consumer; rig mechanics port into it |
| NeBuLA Canvas2D entity | `src/backends/canvas2d/` (eye-system, portal-system, particles), `eye-behavior.js`; `canvas2d-backend.js` is a 2-line re-export shim | Mounted only by World's Catalog page. `eye-behavior.js` carries a third proportion set (eye 38x110, portal 90x28) | **derived** from the registry, or retire into alive once alive is registry-driven |
| NeBuLA Three.js backend | `src/backends/threejs-backend.js` | Instanced body and aura; fixed `_time += 0.016` step; literal colours | **canonical 3D path** (registry-driven; gets the infinity portals) |
| NeBuLA standalone effects | `src/effects/` (starfield, deepfield, ambient-field, entropy-shader, attractor, animation-filter) | **Drawn by no backend** today | registry effects with support entries, or retire (Mark) |
| NeBuLA UI widgets | `src/ui/grimoire-eye.js`, `grimoire-ring.js`, `entity-mini.js` | Own geometry | **drifters** → derived from the registry |
| NeBuLA rig spec | `specs/rig/entity-rig.svg/.json`, `entity-rig-demo.html` | Differs from the BaBbLE reliquary originals only by the Deep Void palette swap; the demo is a newer engine than the intake/drop copies. `specs/visual-spec.md` is byte-identical to Aether's `RaBbLE-Entity-Visual-Spec.md` | **reference**; dedupe visual-spec (keep one) |
| Puppet Spec live rig | Grimoire `log/plans/Unified-Entity/live/live.js` (= the HTML's inline script) | **The only numeric source** for body, moves, camera, tilt, cut and colour | **canonical rig behaviour**; feeds the registry base |
| Pocket device renderer | `RaBbLE-Pocket/firmware/entities/RaBbLE/` (`src/scene.c`, `nebula_lite/`, `rabble_orbit*.c`, `rabble_entity.c`) | Draws far less than the mock: flat void, ring, mesh, strands, portals, eyes, glass. Haze code exists but is off. **No infinity flow.** Swap 0.7 s planar (Canon: 1.45 s with depth arc); portals touch mid-swap | **canonical device path**; held to the registry by golden frames |
| Pocket dead LVGL face | `entity_face.c/.h` | No caller. Carries a third set of proportions (portal 106x33, eye 44x128) | **drifter**; keep only the constants `rabble_ui.c` uses |
| Pocket sim | `sim/host_render.c`, `orbit_scenes.c`, `transition.c` | Tooling and golden-frame producers. `transition.c` duplicates the stepper maths in `rabble_orbit_logic.c` | **reference** (tooling) |
| Pocket mock | `planning/mock/rabble-pocket-entity.html` | Reference for the web page; colours off-Palette | **reference** until the registry replaces it |
| Pocket web SVG entity | `companion-app/web/build-entity.py` → `public/entity/pocket-entity.js` | `portal.js` and `orbit.js` use `mount`, `snapshot`, `look`, `audio`, `setQuality`, `backdrop`, `meshSide` | **retire** after NeBuLA gains those APIs (order: APIs, switch `portal.js`, delete) |
| Mock copies | BaBbLE `intake/rabble-pocket-entity.html` = Xperimental `drops/20261013-pocket-entity` (md5 identical; one line behind the mock) | Duplicates | **drifters**: source copy → Chrysalis; drop URL stays as a frozen snapshot |
| Rig page copies | BaBbLE `intake/rabble-entity-rig.html` = Xperimental `drops/20261013-entity-rig` | Older than NeBuLA's `entity-rig-demo.html` | **drifters**: same treatment |
| Terminal face | `RaBbLE-sCoRE/tui/rabble-face/src/face.rs` (+ `micro.rs`, `driver.rs`) | Full, Mini and micro mark; hardcoded names; TUI moods are private names | **canonical terminal path** |
| Python face | `RaBbLE-sCoRE/ui/face.py` | Live Textual face **and the oracle for the Rust golden tests** (`tests/golden_face.py`, `PARITY.md:74`) | **reference**, frozen; retires with the Python UI |
| BaBbLE terminal face | `prototypes/terminal-face/face.py` | Differs from sCoRE's (md5); its docstring says it no longer matches the rig. (The BaBbLE census called it reference; the sCoRE census, which diffed it, called it older) | **drifter** |
| World floor | `RaBbLE-World/world/js/RaBbLE-floor.js` | **Not scaffold**: a hand-rolled Three.js entity (pill eyes, portal arcs, blink), a fork of NeBuLA `elements/floor.js`, **no importer** (likewise `RaBbLE-stage.js` and the movements files) | **drifter** → Chrysalis |
| Ball | Xperimental `experiments/rabble-ball/RaBbLE-Ball.html` = `drops/20261020-rabble-ball` | Hand-rolled Three (no NeBuLA) | **canonical as the `ball` profile**: promote into NeBuLA; drop URL stays as a sandbox |
| Ball copies | BaBbLE `intake/RaBbLE Ball.html`, `RaBbLE_Ball.html`, `tmp/rabble-ball/` | Older near copies | **drifters** |
| Boot prototypes | BaBbLE `prototypes/boot/RaBbLE-Boot-v1.html`, `-v2.html` | Byte-identical to each other | keep one as **reference** (origin of the boot timeline); the other is a drifter |
| Other BaBbLE prototypes | `RaBbLE.html`, NeBuLA Studio prototype, Strata, Login, animation-studio; `tmp/alive/*.js` (untracked) | Superseded | **drifters** |
| Entity harness | BaBbLE `reliquary/2026-09-26-entity-harness` | Origin of alive-backend.js (cited at `alive-backend.js:5` and `alive-port/README.md`) | → Chrysalis reliquary; update both citations |
| Xperimental sandboxes | drops `rave`, `fourier-redraw`, `matrix-builder` | No duplication of a canonical render (BaBbLE holds identical or older copies) | **sandbox**, keep live |
| Foundling | `RaBbLE-Pocket/firmware/entities/Foundling`, `portal.js:308` fallback | A separate open entity | **out of scope** |

**Chrysalis landing (from its census):** `Chrysalis-Web/entity-renders/<group>/` with a provenance README table (origin path, sha, md5, session, replacement). The old place gets a `.MOVED.md` pointer, or a meta-refresh stub for a page with a published URL. Commit Chrysalis first, then the origin repo. New origins go into the `_headers` CSP. **Open for Mark:** a dated folder (`entity-renders-2026-11/`, matching `world-2026-06/`) or not, and whether the BaBbLE harness goes in as files or as a sealed `reliquary/babble/...` branch.

**Link safety:** hard references that a move must update are `nebula_lite/` (about 15 CMake, sim and test include paths), `scene.c` (sim scripts, the panel_bench CMake), the mock (`build-entity.py:9`), `pocket-entity.js` (web `index.html:11`), Pocket `orbit.js` (`portal.js:11`), NeBuLA `floor.js` (`src/index.js:3`), and the backends (`element.js` imports). Doc hits for the generic names (rave, ball, face.py) are noisy; judge them one by one before any move.

## Added slices

| # | Slice | Done when |
|---|---|---|
| U8 | Read each inventory row, fix the status column, Mark signs off | table final; the canonical entity named once |
| U9 | Layer model in the registry (ordered layers, per-layer on/off, opacity, params, surface profiles) and the Studio controls for it | a layer toggled in Studio changes Portal, Pocket web and (by regeneration) the device build identically |
| U10 | Port each Pocket effect into NeBuLA as a named effect with a cost tier and per-surface support | every effect Pocket draws exists in NeBuLA; the support table is generated and verified |
| U11 | 60 fps gate on the device: measure per-effect cost on hardware (nebula_lite already reports per-frame time on the host: `sim/host_render`) and set per-effect device support from it | no effect in the device profile drops below 60 fps |
| U12 | Move drifters to Chrysalis with pointers; update the Grimoire index | each drifter has a pointer; no duplicate canonical copies |

## Slice 1 progress (S352)

- Pocket host frame: `RaBbLE-Pocket/sim/build.sh <name> 0 6 0.5 0 0 0` writes `sim/out/<name>.png`.
- Rig frames: headless Playwright against `Unified-Entity-Puppet-Spec.html`. The page keeps `prop` (proportions) internal, so a copy with `prop='pocket'` substituted is needed until the registry feeds the rig.
- **Findings so far (not conclusions):** at the rig's 0 degree orthographic view the portals are edge-on lines, while Pocket draws shallow ellipses (about the rig's 15 to 17 degree perspective view), so compare at a **matched camera elevation**, never at 0. Pocket portal rings are about 2.0 eye widths, the rig baseline 2.69 (the page's own tables).
- ~~Still to do~~ **Done S353.** Evidence in `u1/`: `u1-sheet.png` (Pocket device frames beside the rig with `prop='pocket'` at 17 degrees: idle, half and full blink, swap at 0.25, 0.5 and 0.75, turn), `zoom-pocket.png` and `zoom-rig.png` (eye and rim crossings). Reproduce: `rig_capture.py` (headless Chromium on a stepped clock: `performance.now` and `requestAnimationFrame` are stubbed, so frames are deterministic) and `host_render_u1.c` (a copy of `sim/host_render.c` that takes `FLIP=` for mid-swap frames; build it like `sim/build.sh`). Blink frames match exactly: `blink_at` (scene.c:575) and `blinkAmt` (live.js:41) are the same function.

### U1 result (S353)

**Draw order agrees.** In idle, blink and swap, both put the upper-role eye in front of its portal's near rim, and draw the lower-role portal's near rim over its eye's base. That is the Canon 6 rule. Nothing in the rig's draw order needs correcting, and Canon 9.7 closes on draw order.

**Real differences (none are draw order):**

| # | Difference | Pocket | Rig | Action |
|---|---|---|---|---|
| a | Lower-role eye inside the opening | clipped to the half-plane plus the opening ellipse: the eye fills the well down to the near rim, which draws over it | dome dissolve at the portal plane: the eye ends at the well's centre, and the near rim never crosses it | **Mark rules** (ruling 37 points to Pocket; rulings 30b/36b describe the rig). The registry carries both as `cut.mode` |
| b | Swap path | 0.7 s, smoothstep, planar: the portals meet at the same height and touch at the midpoint (breaks Canon 2) | 1.45 s with a 75-unit depth arc; the portals pass in depth | the device adopts the Canon swap with the registry (U3 device side, gated on the reorg) |
| c | Swap squash curve | `withdraw = sin(pi*fl)`: at 25% progress the eye is still about half height | a smootherstep plateau with factor 1.6: at 25% the eye is nearly gone | registry timeline `portal_swap`; the device follows it |
| d | Turn | none (hardware roll only) | 1.4 s yaw half-turn | the device gains `turn`, or the registry marks it `none` on `pocket_hw` (Mark) |
| e | Glow and wells | flat black well, no glow | soft rim glow, gradient well | effect layers (`glow.*`, `portal.back` params), not occlusion |

## What the Pocket page added (to move into NeBuLA)

Source: `RaBbLE-Pocket/companion-app/web/build-entity.py` (patches the mock, emits `public/entity/pocket-entity.js`) and `public/orbit.js`.

| Pocket-page addition | Today | Goes to NeBuLA as |
|---|---|---|
| Quality profile: `lite` (no glow layer, no SVG blur filters, cheap backdrop kept) and `full` | regex stripping of the mock's SVG | a surface **profile** in the registry plus a per-effect `cost` tier; the renderer selects by profile, no string surgery |
| Frame governor (60, 45, 30, 20 fps, climbs back after calm) | inside `mount()` | NeBuLA `frame-budget` (exists in `backends/canvas2d/frame-budget.js`; extend, share) |
| Gaze (`look(x,y)`, eased, head tilt) | patched into the idle pose | a behaviour input on the entity (`eye-behavior.js`), data-driven travel from the registry |
| Mic-driven spectral bars (`audio(levels)`) | text-patched `barA`/bar height | an input channel (levels array) on the bars effect, any surface |
| Real local time on the glass layer | text-patched `4:20 pm` | glass-layer widget fed by a clock input |
| `meshSide(side)` live mesh nodes and edges | exported for `orbit.js` | mesh as a first-class NeBuLA structure (the Orbit transition consumes it; device has its own) |
| `backdrop(el)`, `snapshot(el, state)` | exported | backdrop and still-frame APIs on the NeBuLA backend |
| Per-mount id namespacing (SVG ids) | `uniq()` | disappears if the web Pocket surface moves off SVG to the Canvas2D backend; keep only if SVG stays a backend |
| Orbit drawer (Settings/Apps, mesh gather) | `public/orbit.js` | UI layer over NeBuLA mesh and transition data; transition timings live in the registry |
| Boot animation (not built) | spec in HANDOFF-S350 section 3 | a registry timeline (`boot`) every surface plays natively; device already has one in `scene.c` |

Settled (ruling 3): the Pocket web surface uses NeBuLA's Canvas2D or Three.js backend, per `RaBbLE-NeBuLA-Architecture.md` ("host pages never hand-roll their own entity renderer"). The SVG-only items in this table (id namespacing, regex-stripped lite) disappear with it.

## Effect portability

Rule: every NeBuLA effect declares, per surface, one of **full**, **reduced** (same idea, cheaper), or **none**. The registry carries it as `effects[name].surfaces`, a generator emits the table below into the docs, and a surface that is `none` skips the effect without error.

Surfaces: **Web** (Canvas2D backend: Portal, World, Pocket web), **Web3D** (Three.js backend), **Ball** (top-down Three), **Pocket HW** (nebula_lite, C, 466 px round AMOLED, no per-pixel shaders), **Terminal** (`rabble` face).

Proposed support (**to verify per effect before it is published; entries marked ? are guesses from names and the notes above**):

| Effect | Web | Web3D | Pocket HW | Notes |
|---|---|---|---|---|
| Entity body: eyes, portals, infinity flow | full | full | full (reference occlusion) | parity gated by golden frames |
| Mesh (hubs, layers, ring) | full | full | full | device has its own mesh and Orbit transition |
| Starfield / deep field (streaks, constellation, haze) | full | full | reduced (backdrop wash + stars, no haze layers?) | device keeps "nebula wash, two hazes, the ring" |
| Glow layer (soft strokes, bokeh) | full | full | reduced (half-res glow canvas, per Entity-Port-Plan) | web `lite` drops it |
| SVG/Canvas blur filters | full | n/a | none | cost, not portable to the device |
| Entropy shader, attractor, ambient field, animation filter | full | full ? | none ? | per-pixel or particle cost; confirm each |
| Mic-driven bars | full | ? | full (device mic levels) | input channel differs per surface |
| Gaze | full (pointer) | full | none ? (no pointer; tilt/IMU instead) | badge has no IMU either |
| Boot animation | full | full | full (own implementation) | one registry timeline |

**Corrections from the S353 effects census** (the table above is the S352 guess; the schema's effect list, `registry/entity/RaBbLE-Entity-Registry-Schema.md` section 5.3, replaces it once the registry exists):
- **Infinity flow is drawn only by the rig** (`live.js`). No NeBuLA file and no Pocket file draws it. It must be built in alive, Three.js and nebula_lite; until then, every surface but the rig is `none`.
- **Pocket HW has no wash, haze or stars today.** It draws a flat void and the ring; the haze code (`raster_soft.c`) exists but is off. Mark (S353): haze and bokeh are not required on the device.
- **Bars versus strands.** The device has no spectral bars; it has mic **strands** into the portals (plus absorption sparks). Split the effects: `body.bars` (web), `strands.mic` (device full; on web it is synthetic, not fed by the mic).
- **Gaze on HW is `reduced`, not `none`.** It has a touch glance (`TOUCH_GAZE`) and IMU sway and roll.
- **Web boot does not exist.** Boot runs on the device (`scene.c:626-637`) and in alive (BOOT table); Pocket web has none.
- **NeBuLA's `src/effects/` modules are drawn by no backend.** The effects on screen live inside the three backends.
- **The device already misses ruling 7.** S252 measured: idle 60 fps TE-locked, listening and speaking 31 to 41, turning about 30. U11 starts there.

Surface notes: Terminal supports the entity body and state only (glyph face, no effects); Ball renders top-down and is part of the entity, effects limited to what makes sense from above (? confirm). The ZNP badge (`RaBbLE-Pocket-ZNP-Badge-Research.md`) is **not a render surface**: it receives pre-rendered loops and images made by a driver, so it consumes exports, not effects.

## Slices

| # | Slice | Done when |
|---|---|---|
| U1 | Pocket vs rig comparison at matched camera (in progress) | side-by-side recorded, Canon 9.7 closed, rig corrected where it differs |
| U2 | `registry/entity/rabble.entity.json` + validator, numbers frozen from U1 | schema validates; stale Canon 10.1 sample retired |
| U3 | Generators: JS tuning for NeBuLA/Pocket web, C header for `scene.c` | both build from the registry; no hand-ported constants |
| U4 | Golden frames: `sim/host_render.c` PNGs vs web output, pixel diff with tolerance, in CI | a registry change that breaks parity fails the test |
| U5 | Move Pocket-page additions into NeBuLA (table above), Pocket page consumes NeBuLA (CDN or `dist/` via `dev-serve.sh`) | `build-entity.py` and `pocket-entity.js` deleted |
| U6 | Effect capability table verified and generated into the NeBuLA docs | each effect lists its per-surface support, checked on each surface |
| U7 | Boot animation as a registry timeline on web and device | plays on Pocket web and Portal; device unchanged until it adopts the timeline |

Rules in force: build NeBuLA `dist/` before testing (S324); dev via `dev-serve.sh` only; NeBuLA owns effects rendering, Aether owns CSS, World is scaffold only; no live-desktop testing; never flash hardware unless Mark asks that session; Pocket entity port waits for the core/apps reorg (S323), so U3's device side is gated on it.

## Open questions for Mark

S352's four questions were answered in S353 (rulings 11 to 14). Still open, and they block wave 2:

- **Sign off the U8 inventory** above, including: alive kept as the canonical 2D backend (Pocket web goes onto it; the old Canvas2D entity is derived or retires); `RaBbLE-floor.js` as a drifter; the Chrysalis layout (dated folder or not; the harness as files or a sealed branch).
- **Sign off the registry schema** (`registry/entity/RaBbLE-Entity-Registry-Schema.md` + `rabble.entity.schema.json`), including the vocabulary (`thinking` as a state, `ponder`/`process` as its moods, `withdraw` as a move, the eight Identity conditions).
- **U1-a:** the swallow-cut mode for the lower-role eye (`opening_clip`, Pocket, or `dome_dissolve`, rig).
- **C5:** the eye fill colour (`#f8faff` is off-Palette: `text`, `white`, or a new Palette entry).
- **Turn on the device:** build it, or `none` on `pocket_hw`.
- **NeBuLA standalone effects** (`src/effects/`, drawn by nothing): give them registry entries, or retire them.

Wave 2 briefs: `log/handoffs/HANDOFF-S353-Unified-Entity-Wave2.md`.
