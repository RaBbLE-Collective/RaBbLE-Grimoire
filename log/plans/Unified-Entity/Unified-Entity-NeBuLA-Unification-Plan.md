# Unified Entity and NeBuLA unification plan

```
status: design only, nothing built · S352 · 2026-11-18 · owner: Mark (direction), NeBuLA + Pocket + World members
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

## Inventory of current entity renders (first pass, S352)

From a file survey (names, sizes, paths), **not yet read in detail**. The status column is a proposal for Mark to sign off, not a ruling. Counts are files containing "portal" or "infinity", minus vendored code.

| Render | Where | Kind | Proposed status |
|---|---|---|---|
| NeBuLA Canvas2D backend (eyes, portals, particles, connections) | `RaBbLE-NeBuLA/src/backends/canvas2d/`, `canvas2d-backend.js` | web engine | **canonical web path** (becomes registry-driven) |
| NeBuLA Three.js backend | `backends/threejs-backend.js` | web 3D engine | **canonical 3D path** |
| NeBuLA alive backend / GL | `backends/alive-backend.js`, `alive-gl.js` | web engine (emotion layer) | decide: merge into the above or keep as a named backend |
| NeBuLA rig spec | `RaBbLE-NeBuLA/specs/rig/entity-rig.svg`, `entity-rig-demo.html` | spec fixture | **reference** (golden-frame source) |
| Puppet Spec live rig (3D, infinity portals) | Grimoire `log/plans/Unified-Entity/live/live.js` | spec page | **canonical rig behaviour**; feeds the registry |
| Pocket nebula_lite + scene builder | `RaBbLE-Pocket/firmware/entities/RaBbLE/` (`scene.c`, `nebula_lite/`) | device (C) | **canonical device path**; held to the registry by golden frames |
| Pocket mock | `RaBbLE-Pocket/planning/mock/rabble-pocket-entity.html` | design mock | **reference** until the registry replaces it; then archive |
| Pocket web SVG entity | `companion-app/web/public/entity/pocket-entity.js` (generated) | derived from the mock | **retire** (ruling 3) |
| `rabble-ui` Rust / terminal face | `RaBbLE-sCoRE/tui/rabble-face/src/face.rs`; `ui/face.py` | terminal | **canonical terminal path** (`face.rs`); `face.py` check, likely retire |
| World floor | `RaBbLE-World/world/js/RaBbLE-floor.js`, `RaBbLE-NeBuLA/src/elements/floor.js` | scene element | check: scaffold, not the entity |
| Ball | `RaBbLE-Xperimental/experiments/rabble-ball/RaBbLE-Ball.html` (+ drops) | experiment (top-down 3D) | **canonical as a Three.js surface profile**; move out of the experiment into NeBuLA |
| Copies of the same page in several places | `rabble-pocket-entity.html` (Pocket mock, BaBbLE intake, Xperimental drop), `rabble-entity-rig.html` (BaBbLE intake, Xperimental drop), Ball (BaBbLE `intake/`, `tmp/`, Xperimental x2) | duplicates | **drifters**: keep one canonical copy, rest to Chrysalis |
| BaBbLE prototypes (`RaBbLE.html`, `boot/RaBbLE-Boot-v1/v2.html`, `terminal-face/face.py`, `tmp/alive/body*.js`, NeBuLA Studio prototype) | `RaBbLE-BaBbLE/prototypes/`, `tmp/` | prototypes | **drifters** unless an item is the origin of a canonical path (boot is the source for the boot timeline: keep as reference) |
| Entity harness (`reliquary/2026-09-26-entity-harness`) | `RaBbLE-BaBbLE/reliquary/` | already a reliquary | move to Chrysalis reliquary |
| Xperimental drops (rave, fourier-redraw, matrix-builder, entity-rig, pocket-entity, ball) | `RaBbLE-Xperimental/Xperimental-Web/drops/` | published experiments | **keep live as sandbox** unless they duplicate a canonical render; moving a drop breaks its URL, so decide per drop |

Chrysalis today holds the genesis archive and OS reliquary branches (`RaBbLE-Chrysalis/AGENT.md`); "entity renders" would be a new kind there. Moving files is not done until Mark signs off the table above, and a move leaves a pointer in the old place (condense, not delete).

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
- **Still to do:** render both at about 17 degrees with Pocket proportions and offsets, the same poses (idle, blink, portal swap, turn), side by side; record which draw-order differences are real; correct the rig where they differ.

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

- Is the Portal's entity the NeBuLA Canvas2D/alive rig, and do the registry's reference numbers come from the Puppet Spec rig, with Pocket proportions as a surface profile?
- Sign-off on the inventory table (U8): especially the alive backend (merge or keep), the Ball, and which Xperimental drops are sandbox versus drifters.
- Ruling 7: does "60 fps" mean the device never drops below 60 (effects yield), as written? And should the web Pocket page also target 60 with the governor as a fallback only?
- Which effects do you want on the device at all (some may stay `none`)?
