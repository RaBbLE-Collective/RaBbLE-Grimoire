# Code references to entity-render files (READ-ONLY survey)

Scope: RaBbLE-NeBuLA, RaBbLE-Pocket, RaBbLE-World, RaBbLE-sCoRE. Grep: `grep -rn --exclude-dir={node_modules,.git,dist,build,managed_components,target,.venv} <basename>`, plus a second pass for the `nebula_lite` directory. Pattern is unescaped, so `.` matches any char (see false positives noted). Not searched: RaBbLE-Grimoire (holds live.js and Unified-Entity-Puppet-Spec.html), RaBbLE-Xperimental (holds RaBbLE-Ball.html), RaBbLE-BaBbLE, RaBbLE-Chrysalis.

Kinds: import, link, doc, route, build. "doc" covers comments, markdown and specs.

Generated noise, not edited by hand: `RaBbLE-Pocket/firmware/build-rabble_waveshare_175c-RaBbLE/` (build.ninja, compile_commands.json, .ninja_log, project_description.json, log/*, CMakeFiles/*). About 90 hits across the scene.c and nebula_lite names. Regenerated on each idf build; no ref to fix there, but a moved path will break the next build.

---

## alive-backend.js
Target: `RaBbLE-NeBuLA/src/backends/alive-backend.js`

- RaBbLE-NeBuLA/src/element.js:32  import  `import { createAlive } from './backends/alive-backend.js';`
- RaBbLE-NeBuLA/src/element.js:5  doc  ` * the alive entity (2D+3D, host-driven boot, moods; see backends/alive-backend.js`
- RaBbLE-NeBuLA/src/backends/alive-backend.js:2  doc  self header comment, `<rabble-entity backend="alive">`
- RaBbLE-sCoRE/ui/face.py:8  doc  `RaBbLE-NeBuLA/src/backends/alive-backend.js so both bodies share one creature.`
- RaBbLE-sCoRE/ui/face.py:34  doc  `# ── face rig (alive-backend.js, face units) ───`
- RaBbLE-sCoRE/tui/rabble-face/src/face.rs:10  doc  `// face rig (alive-backend.js, face units)`

Note: the sCoRE refs are the Python and Rust faces porting this rig, so a move breaks the parity comments, not the build.

## alive-gl.js
Target: `RaBbLE-NeBuLA/src/backends/alive-gl.js`

- RaBbLE-NeBuLA/src/backends/alive-backend.js:23  import  `import { createGLContext2D } from './alive-gl.js';`
- RaBbLE-NeBuLA/src/backends/alive-backend.js:161  doc  `// 2D scene on WebGL by default (alive-gl.js): ...`
- RaBbLE-NeBuLA/src/backends/alive-gl.js:2  doc  self header comment

## canvas2d-backend.js
Target: `RaBbLE-NeBuLA/src/backends/canvas2d-backend.js`

- RaBbLE-NeBuLA/src/backends/index.js:3  import  `export { Canvas2dBackend } from './canvas2d-backend.js';`
- RaBbLE-NeBuLA/src/element.js:29  import  `import { Canvas2dBackend } from './backends/canvas2d-backend.js';`
- RaBbLE-NeBuLA/CONTEXT.md:24  doc  `Phase 3: Canvas2D backend (src/backends/canvas2d-backend.js)`
- RaBbLE-NeBuLA/CONTEXT.md:39  doc  `Layer 1 ... lives in src/element.js + src/backends/canvas2d-backend.js`
- RaBbLE-NeBuLA/CONTEXT.md:92  doc  `extract canvas2d-backend.js into 6 system files | Done`
- RaBbLE-NeBuLA/specs/rig/README.md:16  doc  `into src/backends/canvas2d-backend.js or src/backends/eye-behavior.js`
- RaBbLE-NeBuLA/specs/visual-spec.md:345  doc  `src/backends/canvas2d-backend.js + eye-behavior.js is real`

## threejs-backend.js
Target: `RaBbLE-NeBuLA/src/backends/threejs-backend.js`

- RaBbLE-NeBuLA/src/backends/index.js:2  import  `export { ThreeJsBackend } from './threejs-backend.js';`
- RaBbLE-NeBuLA/src/element.js:30  import  `import { ThreeJsBackend } from './backends/threejs-backend.js';`
- RaBbLE-NeBuLA/CONTEXT.md:25  doc  `Phase 4: Three.js backend (src/backends/threejs-backend.js)`
- RaBbLE-NeBuLA/CONTEXT.md:44  doc  `consumed by BOTH canvas2d/eye-system.js and threejs-backen...`
- RaBbLE-NeBuLA/specs/render-gap-analysis.md:9  doc  `The current Three.js entity is src/backends/threejs-backend.js`
- RaBbLE-World/world/js/RaBbLE-floor.js:120  doc  `// Source: RaBbLE-NeBuLA/src/backends/threejs-backend.js eyeConfig x 100`

## entity-rig.svg
Target: `RaBbLE-NeBuLA/specs/rig/entity-rig.svg`

- RaBbLE-NeBuLA/specs/visual-spec.md:362  doc  `- entity-rig.svg, every moving part is a named group ...`
- RaBbLE-NeBuLA/specs/visual-spec.md:481  doc  `(entity-rig.svg, entity-rig.json, entity-rig-demo.html) see ...`
- RaBbLE-NeBuLA/specs/visual-spec.md:490  doc  `2026-09-26 Integrated the entity animation rig (entity-rig.svg / ...`
- RaBbLE-NeBuLA/specs/rig/README.md:6  doc  `entity-rig.svg, the rig: 450 named/pivoted groups`
- RaBbLE-sCoRE/ui/eyes.py:5  doc  `(RaBbLE-NeBuLA/specs/rig/entity-rig.svg). The half-block drawing this replaces ...`

No hits in RaBbLE-Pocket, RaBbLE-World, or any routes/build file. Note: entity-rig.json is referenced by visual-spec.md but was not in the input list. Check it with the rig.

## entity-rig-demo.html
Target: `RaBbLE-NeBuLA/specs/rig/entity-rig-demo.html`

- RaBbLE-NeBuLA/specs/rig/README.md:10  doc  `entity-rig-demo.html, a complete, self-contained reference render`
- RaBbLE-NeBuLA/specs/visual-spec.md:369  doc  `entity-rig-demo.html, a complete, working reference render`
- RaBbLE-NeBuLA/specs/visual-spec.md:481  doc  `(entity-rig.svg, entity-rig.json, entity-rig-demo.html)`

## live.js (Grimoire log/plans/Unified-Entity/live/)
Not searched: the target sits in RaBbLE-Grimoire, which is outside the four-repo scope. No hits in the four repos for the basename `live.js`. Grep for it in Grimoire before moving.

## Unified-Entity-Puppet-Spec.html (Grimoire)
Not searched: target is in RaBbLE-Grimoire. No hits in the four repos. Grep Grimoire before moving.

## scene.c
Target: `RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c`

Build refs:
- RaBbLE-Pocket/firmware/tools/panel_bench/main/CMakeLists.txt:2  build  `idf_component_register(SRCS "panel_bench.c" "${...}/../../../entities/RaBbLE/src/scene.c" ...`
- RaBbLE-Pocket/sim/build.sh:10  build  `SCENE=../firmware/entities/RaBbLE/src/scene.c   # the entity scene builder`
- RaBbLE-Pocket/sim/transition.sh:9  build  `SCENE=../firmware/entities/RaBbLE/src/scene.c`
- RaBbLE-Pocket/sim/xtensa_check.sh:22  build  `for f in "$SRC"/*.c "$FW/entities/RaBbLE/src/scene.c"; do`
- RaBbLE-Pocket/sim/pocket/... : none for scene.c

Doc refs:
- RaBbLE-Pocket/firmware/CONTEXT.md:14  doc  `entities/RaBbLE/ ... the entity (rabble_entity.c, scene.c)`
- RaBbLE-Pocket/firmware/CONTEXT.md:15  doc  `the entity scene builder is entities/RaBbLE/src/scene.c`
- RaBbLE-Pocket/firmware/entities/RaBbLE/include/nl_scene.h:11  doc  `The entity scene builder (scene.c), the app's half of nebula_lite`
- RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c:3  doc  self header
- RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c:4  doc  `Ported from the Pocket mock (planning/mock/rabble-pocket-entity.html)`
- RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/include/nl_list.h:156  doc  `/* ---- scene -> list (scene.c) ---- */`
- RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/include/nl_list.h:183  doc  `scene.c: this frame's mesh on screen while an Orbit slides`
- RaBbLE-Pocket/firmware/entities/RaBbLE/src/rabble_new_convo.c:62  doc  `eyes' withdraw in scene.c`
- RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/src/orbit.c:153  doc  `The dial materialises ... (scene.c)`
- RaBbLE-Pocket/companion-app/web/build-entity.py:19  doc  `nl_scene_init ... (scene.c nl_scene_init ...)`
- RaBbLE-Pocket/companion-app/web/build-entity.py:3  doc  docstring: `the renderer firmware/.../scene.c was ported from`
- RaBbLE-Pocket/companion-app/web/public/portal.js:288  doc  `the Pocket's own entity (..., built from the Pocket mock that scene.c was ...)`

Build-artifact hits (generated): see the noise note at the top.

False positives excluded: `RaBbLE-NeBuLA/src/backends/alive-backend.js:1050`, `src/elements/graph.js:470`, `src/elements/floor.js:584` (`renderer.render(scene,cam3)`, regex `.` matched `,`). `RaBbLE-Pocket/sim/orbit_scenes.c:232` is a local `static void scene()`, not this file.

## nebula_lite (directory, Pocket)
Target: `RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/`

Build refs (these break on a move):
- RaBbLE-Pocket/firmware/entities/RaBbLE/CMakeLists.txt:10  build  `PRIV_REQUIRES ... esp_pm nebula_lite`
- RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/CMakeLists.txt:3  build  own CMake header
- RaBbLE-Pocket/firmware/CMakeLists.txt:19  build  `component of its own, and so is every folder inside it that has a CMakeLists.txt (nebula_lite, ...)`
- RaBbLE-Pocket/firmware/tools/panel_bench/CMakeLists.txt:5  build  `"${CMAKE_CURRENT_LIST_DIR}/../../entities/RaBbLE/nebula_lite")`
- RaBbLE-Pocket/firmware/tools/panel_bench/main/CMakeLists.txt:3  build  `PRIV_REQUIRES ... nebula_lite ...`
- RaBbLE-Pocket/firmware/tools/panel_bench/main/panel_bench.c:26  build  `#include "nebula_lite.h"`
- RaBbLE-Pocket/firmware/entities/RaBbLE/src/rabble_entity.c:26  import  `#include "nebula_lite.h"`
- RaBbLE-Pocket/firmware/entities/RaBbLE/src/rabble_orbit.h:6  import  `#include "nebula_lite.h"`
- RaBbLE-Pocket/firmware/entities/RaBbLE/include/nl_scene.h:4  import  `#include "nebula_lite.h"`
- RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/include/nl_list.h:3  import  `#include "nebula_lite.h"`
- RaBbLE-Pocket/sim/host_render.c:10  import  `#include "nebula_lite.h"`
- RaBbLE-Pocket/sim/build.sh:9  build  `SRC=../firmware/entities/RaBbLE/nebula_lite`
- RaBbLE-Pocket/sim/transition.sh:8  build  `SRC=../firmware/entities/RaBbLE/nebula_lite`
- RaBbLE-Pocket/sim/xtensa_check.sh:10  build  `SRC="$FW/entities/RaBbLE/nebula_lite/src"`
- RaBbLE-Pocket/sim/xtensa_check.sh:23  build  `-I"$FW/entities/RaBbLE/nebula_lite/include"`
- RaBbLE-Pocket/sim/pocket/sim.mk:12  build  `$(FW)/entities/RaBbLE/nebula_lite/src/*.c`
- RaBbLE-Pocket/sim/pocket/sim.mk:17  build  `-I$(FW)/entities/RaBbLE/nebula_lite/include`
- RaBbLE-Pocket/sim/pocket/WIP.md:10  doc  `sim.mk: compiles ... nebula_lite`
- RaBbLE-Pocket/ops/sdk-layers.py:44,50  build  `"nebula_lite": "render"` (layer map)
- RaBbLE-Pocket/firmware/test/render/sim_test/run.sh:3  build  `sim/build.sh builds nebula_lite ...` (comment)
- RaBbLE-Pocket/firmware/test/paths.sh:4,30  build  `entities/RaBbLE/nebula_lite`; `"$ACCD"/rabble_*/src/*.c` glob skips nebula_lite
- RaBbLE-Pocket/firmware/test/app/input_test/run.sh:16,19  build  `-I"$FW/entities/RaBbLE/nebula_lite/include"`
- RaBbLE-Pocket/firmware/test/app/input_test/compile_check.sh:24  build  `-I"$FW/entities/RaBbLE/nebula_lite/include"`
- RaBbLE-Pocket/firmware/test/app/orbit_test/compile_check.sh:4,25  build  `entities/RaBbLE/nebula_lite/include`
- RaBbLE-Pocket/firmware/test/app/shot_test/compile_check.sh:4,25  build  `entities/RaBbLE/nebula_lite/include`
- RaBbLE-Pocket/firmware/test/net/beam_test/run.sh:65  build  `-I"$FW/entities/RaBbLE/nebula_lite/include"`
- RaBbLE-Pocket/firmware/test/net/wifi_test/compile_check.sh:23  build  `-I"$FW/entities/RaBbLE/nebula_lite/include"`
- RaBbLE-Pocket/firmware/test/audio/audio_test/compile_check.sh:25  build  `-I"$W0/stubs" -I"$FW/entities/RaBbLE/nebula_lite/include"`
- RaBbLE-Pocket/firmware/test/core/seam_test/compile_check.sh:22  build  `-I"$FW/entities/RaBbLE/nebula_lite/include"`
- RaBbLE-Pocket/firmware/CONTEXT.md:11,15  doc  component layout / `entities/RaBbLE/nebula_lite/`
- RaBbLE-Pocket/firmware/README.md:8  doc  component layout (`nebula_lite`, `rabble_beam`, `rabble_voice`)
- RaBbLE-Pocket/companion-app/web/build-entity.py:36,19  doc  quality profile comment (`nebula_lite does on the device`)

Note: rabble_entity.h:9 and rabble_entity.c:4 also describe nebula_lite in comments.

## rabble-pocket-entity.html
Target: `RaBbLE-Pocket/planning/mock/rabble-pocket-entity.html`

- RaBbLE-Pocket/companion-app/web/build-entity.py:9  build  `SRC = os.path.join(HERE, '..', '..', 'planning', 'mock', 'rabble-pocket-entity.html')`
- RaBbLE-Pocket/companion-app/web/build-entity.py:133  build  `// Generated by build-entity.py from planning/mock/rabble-pocket-entity.html. Do not edit here.`
- RaBbLE-Pocket/companion-app/web/public/entity/pocket-entity.js:1  doc  generated header, same line
- RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c:4  doc  `Ported from the Pocket mock (...rabble-pocket-entity.html)`

Breaks: `build-entity.py` reads this path, so moving the mock fails the regen of pocket-entity.js.

## pocket-entity.js
Target: `RaBbLE-Pocket/companion-app/web/public/entity/pocket-entity.js` (generated)

- RaBbLE-Pocket/companion-app/web/public/index.html:11  link  `<script src="entity/pocket-entity.js" defer></script>`
- RaBbLE-Pocket/companion-app/web/public/portal.js:288  doc  `(entity/pocket-entity.js, built from the Pocket mock ...)`
- RaBbLE-Pocket/companion-app/web/build-entity.py:3,132  build  writes `OUT/pocket-entity.js` (docstring + write call)
- RaBbLE-Pocket/companion-app/web/build-entity.py:133  build  generated-file header

Note: the plan proposes retiring this file. index.html:11 is the live script tag, so it must change first.

## build-entity.py
Target: `RaBbLE-Pocket/companion-app/web/build-entity.py`

- RaBbLE-Pocket/companion-app/web/build-entity.py:6  doc  usage: `python3 build-entity.py`
- RaBbLE-Pocket/companion-app/web/public/entity/pocket-entity.js:1  doc  generated-by header
- No CI workflow, package.json or script refers to it in the four repos. The usage line is the only caller.

## orbit.js
Target: `RaBbLE-Pocket/companion-app/web/public/orbit.js`

- RaBbLE-Pocket/companion-app/web/public/portal.js:11  import  `import { Orbit } from './orbit.js';`
- RaBbLE-Pocket/companion-app/web/public/portal.js:1009  doc  `Drawn like the hardware's own (orbit.js): Settings on the right ...`
- RaBbLE-Pocket/companion-app/web/public/index.html:95  doc  `The Orbit: the Pocket's settings, drawn like the hardware (orbit.js).`
- RaBbLE-Pocket/companion-app/web/public/portal.css:609  doc  `The Orbit as the Pocket draws it (orbit.js)`

Breaks: portal.js:11 is a hard import. Moving orbit.js fails the web companion load.

## face.rs
Target: `RaBbLE-sCoRE/tui/rabble-face/src/face.rs`

- RaBbLE-sCoRE/tui/rabble-tui/PARITY.md:111  doc  `Rust: mod gaze in src/app.rs ..., widgets/face.rs (cell_aspect)`
  (the `widgets/face.rs` here is a different file, not this target)
- RaBbLE-sCoRE/tui/rabble-tui/PARITY.md:74  doc  `The Rust face is a cell-for-cell port`
- RaBbLE-sCoRE/tui/rabble-face/src/lib.rs:1  doc  `parity-tested against Python goldens (ui/face.py, ui/eyes.py)`
- RaBbLE-sCoRE/tui/rabble-face/src/face.rs:1  doc  self header `The entity (ui/face.py Face)`
- RaBbLE-sCoRE/tui/rabble-face/src/driver.rs:1  doc  `Behaviour over time (ui/face.py Life, MOODS ...)`
- RaBbLE-sCoRE/tui/rabble-face/src/degrade.rs:1  doc  `(ui/face.py degrade, curves, eye_block)`
- RaBbLE-sCoRE/tui/rabble-face/src/canvas.rs:1  doc  `(ui/face.py Canvas)`
- RaBbLE-sCoRE/tui/rabble-face/tests/golden.rs:1,2,17  doc/test  `Cell-for-cell parity with ui/face.py ... fixtures/face/golden.json` (replays golden fixtures)
- RaBbLE-sCoRE/tui/rabble-face/tests/behaviour.rs:1  doc  `Python tests/test_ui_face.py equivalents`
- RaBbLE-sCoRE/tui/rabble-theme/src/lib.rs:28  doc  `ui/face.py mix ...`
- RaBbLE-sCoRE/tui/rabble-tui/PARITY.md:110,119  doc  gaze/cell aspect parity rows (`face.cell_aspect`)

No Cargo.toml path ref to face.rs was found; crate builds from src/ by default. Note: `face.rs` is a crate source file in `rabble-face`, so grep also matches the Python twin's comments.

## face.py
Target: `RaBbLE-sCoRE/ui/face.py`

- RaBbLE-sCoRE/tests/test_ui_theme.py:31  test  `for name in ("theme.py", "face.py"):` (reads file by name; check this path)
- RaBbLE-sCoRE/tests/golden_face.py:3,5,7  doc/build  `python tests/golden_face.py ...`; "it needs textual, which ui/face.py imports"; "Regenerate whenever ui/face.py or ui/eyes.py changes drawing"
- RaBbLE-sCoRE/ui/prng.py:6  doc  `tests/test_ui_face.py and the Rust ...`
- RaBbLE-sCoRE/orchestra/entropy.py:28  doc  `(ui/face.py)`
- RaBbLE-sCoRE/tui/rabble-face/src/driver.rs:1, degrade.rs:1, golden.rs:115, lib.rs:1, canvas.rs:1, face.rs:1 (see face.rs section)
- RaBbLE-sCoRE/tui/rabble-face/tests/golden.rs:17  test  reads `tests/fixtures/face/golden.json` produced by `tests/golden_face.py`
- RaBbLE-sCoRE/tui/rabble-tui/PARITY.md:74,110  doc

Not hits: RaBbLE-Pocket third_party XPowersLib `I2CInterface.py` matched "face.py" (regex noise, unrelated).

## RaBbLE-floor.js
Target: `RaBbLE-World/world/js/RaBbLE-floor.js`

- RaBbLE-World/AGENT.md:50  doc  `world/js/RaBbLE-floor.js | Grimoire floor renderer ... requires RaBbLE-Grimoire-Data.js first`
- RaBbLE-World/CONTEXT.md:72  doc  `world/js/RaBbLE-dock.js, RaBbLE-floor.js, RaBbLE-Grimoire-Data.js, RaBbLE-movements.js ...`
- RaBbLE-World/world/js/RaBbLE-stage.js:45  doc  `floor: null, // set by RaBbLE-floor.js when floor is mounted`
- RaBbLE-World/world/css/RaBbLE-floor.css:22  doc  `Label overlay layer, injected by RaBbLE-floor.js above the canvas`
- RaBbLE-World/world/js/RaBbLE-floor.js:1  doc  self header
- RaBbLE-World/world/js/RaBbLE-floor.js:120  doc  `Source: RaBbLE-NeBuLA/src/backends/threejs-backend.js eyeConfig x 100`

No script src, import or route for RaBbLE-floor.js was found in the World HTML or wrangler/_redirects/_headers. Loading is a runtime or script-tag path that the grep did not catch. Check `world/*.html` and the stage loader before moving. Also check RaBbLE-World `*.html` with a `script src` grep, since the basename match is weak.

## floor.js
Target: `RaBbLE-NeBuLA/src/elements/floor.js`

- RaBbLE-NeBuLA/src/index.js:3  import  `import './elements/floor.js';    // <rabble-floor> (Three.js Grimoire floor)`
- RaBbLE-NeBuLA/src/utils/three-loader.js:7  doc  `Before this existed, floor.js and graph.js each carried ...`
- RaBbLE-NeBuLA/src/element.js:9  doc  `the degradation pattern in elements/floor.js and elements/graph.js`
- RaBbLE-NeBuLA/src/elements/floor.js:2  doc  self header `elements/floor.js <rabble-floor>`
- RaBbLE-NeBuLA/src/backends/threejs-backend.js:475  doc  `(floor.js portal treatment)`
- RaBbLE-World/AGENT.md:50, CONTEXT.md:72, world css/js (RaBbLE-floor.js section) match on the name `RaBbLE-floor.js` only, not this file.

False positive excluded: `RaBbLE-NeBuLA/src/elements/floor.js:584` (`renderer.render(scene,camera)`).

Note: `src/index.js:3` is the registration for `<rabble-floor>` in the NeBuLA IIFE bundle. Removing or moving it breaks the element, and the NeBuLA build (`dist/`) would need a rebuild.

## RaBbLE-Ball.html
Not searched in the four repos: no hits. The target lives in RaBbLE-Xperimental, which is out of scope. Grep Xperimental before moving.

---

## Summary of breaking refs (hard refs, not just comments)

- `scene.c`: sim/build.sh, sim/transition.sh, sim/xtensa_check.sh, panel_bench CMakeLists, plus generated ninja files
- `nebula_lite/`: entities/RaBbLE/CMakeLists.txt, nebula_lite/CMakeLists.txt, panel_bench CMake, sim/* scripts, sim/pocket/sim.mk, firmware/test/* scripts (about 15 `-I` paths)
- `rabble-pocket-entity.html`: build-entity.py:9 reads it
- `pocket-entity.js`: index.html:11 script src
- `orbit.js` (Pocket web): portal.js:11 import
- `alive-backend.js`, `alive-gl.js`, `threejs-backend.js`, `canvas2d-backend.js`: NeBuLA element.js and backends/index.js imports
- `floor.js` (NeBuLA): src/index.js:3 import
- `RaBbLE-floor.js` (World): no hard ref found, runtime load path unverified

Rows the plan does not list but found: `entity-rig.json` (visual-spec.md refs), and the sCoRE `tests/test_ui_theme.py` name check for face.py.
