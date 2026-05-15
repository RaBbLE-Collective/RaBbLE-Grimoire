# RaBbLE-NeBuLA-Roadmap.md

```
transcribe ~ grimoire >> delivery model added, Visual Puppet concept formalized, pre-mortem integrated // %NEBULA_PLAN_LOCKED%
```

> **Collective Context:** NeBuLA is the rendering engine — the entity's visual expression. See `RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `RaBbLE-Episode-1-Release-Map.md` for Episode 1 scope across all members.

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** Canvas2D Layer 1 functional (entity renders at 60 FPS, public API stable)

**Status:** Phases 1-3 in progress

**What ships:**
- [x] Phase 1: Build configured (esbuild IIFE + ESM)
- [ ] Phase 2: Palette layer (colors, gradients in renderer)
- [ ] Phase 3: Canvas2D Layer 1 (entity rendering, 60 FPS verified)
- [ ] Public API documented (`window.NeBuLA.createPuppet(...)`)

**Blocker:** None — design decisions deferred to Episode 2

**Deferred to Episode 2+:**
- Phase 4: Three.js Layer 2 rebuild
- Animation system
- Advanced shaders, WebGPU

**Dependencies:**
- Aether CSS for palette at runtime
- World loads NeBuLA script + calls public API

---

> **Status:** Core data layer (Entity, Stream, Runtime) implemented. Backends and puppet layer being built.
> **NeBuLA-JS:** Archived in `RaBbLE-Xperimental/JS-Xperiments/NeBuLA-JS/` — reference only, do not build on that codebase.
> **Implementation plan:** `RaBbLE-NeBuLA-Plan.md` — detailed step-by-step agent plan.

---

## Rendering Architecture — Backend Progression

NeBuLA is the Collective's unified rendering engine. It does not target a single backend — it provides a backend-agnostic entity rendering surface that advances through generations:

| Backend | Target | Status | Notes |
|---|---|---|---|
| **Canvas2D** | Web (2D entity persona) | Ep1 target | Replaces `rabble-entity.js` in World |
| **Three.js / WebGL** | Web (3D Flat-Chaos env) | Ep1 target | Quantum visualization layer |
| **WebGPU** | Web (advanced shading) | Ep5+ | When browser support stabilises |
| **C++ / OpenGL** | Native desktop | Future | Enables Qt/QML portability |
| **Qt / QML** | Desktop app surface | Long-term | RaBbLE-OS native entity renderer |

The Canvas2D and Three.js backends run together: Canvas2D draws the entity persona (eyes, portal, nebula) while Three.js renders the surrounding environment. Together they form the complete entity surface.

---

## Delivery Model

NeBuLA must be consumable in RaBbLE-World as a simple script addition — a CDN tag or local file, no build step required on the consumer side.

**Two build targets (produced by NeBuLA's own build):**

| File | Format | Use |
|---|---|---|
| `dist/nebula.esm.js` | ES module | `<script type="module">` or importmap |
| `dist/nebula.iife.js` | IIFE (`window.NeBuLA`) | `<script src="...">` — simplest drop-in |

**Three.js is always external (not bundled).** Consumers load it separately. This keeps NeBuLA under 50KB minified. The `ThreeJsBackend` accepts `THREE` as a constructor argument rather than importing it — this is what makes external-Three.js work in IIFE context.

**Two-tag script pattern (simplest):**
```html
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<script src="https://[cdn]/nebula.iife.js"></script>
```

**Aether palette integration:** NeBuLA reads palette values from Aether CSS variables at runtime (Aether is the canonical theme layer for all RaBbLE web projects). NeBuLA falls back to hardcoded constants when running outside a page that has Aether loaded. This happens in `src/puppet/palette.js` — the only file with hardcoded hex values, mirroring `RaBbLE-Palette.md`.

**Hosting options:**
- Cloudflare Workers static asset (alongside World's existing wrangler.jsonc deployment)
- Local copy in World's `world/js/nebula/` directory
- Either path, the `<script>` tag interface is identical

---

## Layer Model (Updated)

**Layer 1 — Entity Persona / Visual Puppet (Canvas2D)**
- **Current:** `world/js/RaBbLE-NeBuLA.js` in RaBbLE-World — monolithic 663-line Canvas2D renderer; the entity visual puppet lives here transitionally
- **Future:** NeBuLA `src/puppet/` absorbs Layer 1 when the Canvas2D backend is proven; World becomes a thin adapter
- The `<rabble-entity>` custom element API (`setEntityState`, `injectEyeJolt`) is the stable interface contract NeBuLA must match — do not change this API shape
- Draws: eyes, portal rings, particle nebula, blink/saccade, boot sequence, state animations
- **Visual Puppet concept:** The puppet is a first-class NeBuLA concept — not just a renderer but the entity's visual body. It owns the boot timeline, saccade state machine, and entropy mapping.

**Layer 2 — Quantum Visualization (Three.js / WebGL)**
- NeBuLA's primary build target — this repo
- Flat-Chaos Runtime: Stream → Entity → Flux → Render
- Core primitives: `Entity` (DNA + flux_matrix + entropy), `Stream`, `Runtime`
- Performance target: 1000+ entities @ 60 FPS

**Integration contract:** Layer 1 entity state (`idle/thinking/speaking`) maps to entropy level in Layer 2. The two layers communicate via a thin bridge, not shared state. This contract survives the transition from `rabble-entity.js` to the NeBuLA Canvas2D backend.

---

## Episode Tracker

### Episode 0 — NeBuLA-JS (Legacy) `[ARCHIVED]`

Original JS implementation in `RaBbLE-NeBuLA-JS/`. Established:
- Flat-Chaos Runtime pattern (documented in `RaBbLE-NeBuLA-FlatChaos.md`)
- Stream/Entity/Flux primitives
- BaBbLE command pipeline (Source → Filter → Transmute → Sink)
- RBCNS naming conventions (historical — `q_`, `e_`, `f_` prefixes)
- Entity pattern concept (incomplete — superseded by `rabble-entity.js` in RaBbLE-World)

**Do not build on NeBuLA-JS code.** Use it as architectural reference only.

---

### Episode 1 — Core Engine `[SCAFFOLD EXISTS — backends and puppet pending]`

**Goal:** Distributable NeBuLA engine with working Canvas2D and Three.js backends, bundled for script-tag delivery.

**Repo:** `RaBbLE-NeBuLA/` (standalone, independent git tree)

**What already exists in the scaffold:**
- `Entity` type, `createEntity`, `cloneEntity` — complete
- `Stream` class with full operation set — complete
- `Runtime` class with RAF loop, stream registry, event system — complete
- `PatternGenerator` — organic, lattice, swarm, galaxy — complete
- Math utilities — complete
- `Canvas2dBackend`, `ThreeJsBackend`, `EntropyShader` — stubs only (throw on call)

#### Episode 1 Exit Conditions

**Build system:**
- [ ] esbuild added as dev dependency
- [ ] `npm run build` outputs `dist/nebula.iife.js` and `dist/nebula.esm.js`
- [ ] Three.js is external in both builds; `ThreeJsBackend` accepts `THREE` as constructor arg
- [ ] `dist/nebula.iife.js` sets `window.NeBuLA` with full API

**Canvas2D backend:**
- [ ] `Canvas2dBackend.render(streams, ctx)` draws entities by geometry type (sphere→arc, box→fillRect, tetrahedron→polygon)
- [ ] Entropy maps to `shadowBlur` and opacity per entity
- [ ] 480 entities render without throw; pixel data is non-zero

**Three.js backend:**
- [ ] `ThreeJsBackend` accepts `(canvas, THREE)` — THREE is the global, not an import
- [ ] InstancedMesh per geometry type: sphere, box, tetrahedron
- [ ] Two `ShaderMaterial` variants: flat and emissive (additive blending)
- [ ] Entropy shader: sinusoidal vertex displacement + emissive hue oscillation per frame
- [ ] `instanceMatrix.needsUpdate = true` every frame
- [ ] 1000 entities render without throw; verified visually in a browser

**Animation system:**
- [ ] `AnimationMixer` class in `src/core/animation.js`
- [ ] `transition(stream, toState, durationMs)` lerps entity entropy toward state target
- [ ] State targets: idle→0.3, thinking→0.6, speaking→0.8
- [ ] `update(deltaMs)` called by Runtime each frame

**Palette:**
- [ ] `src/puppet/palette.js` reads from Aether CSS variables; falls back to `RaBbLE-Palette.md` hex values
- [ ] No raw hex in any other NeBuLA file

**Package:**
- [ ] Exports as ES module (tree-shakeable)
- [ ] No RBCNS naming (`q_`, `e_`, `f_` prefixes) — clean JS/JSDoc
- [ ] `examples/basic-scene.html` loads via importmap, renders without errors

#### Key Implementation Notes

**Avoid from NeBuLA-JS:**
- RBCNS naming conventions (q_, e_, f_ prefixes)
- Theatrical comments and magic identifiers
- Mixing BaBbLE command layer with rendering core

**Carry forward from NeBuLA-JS:**
- Flat array over hierarchy (the core insight)
- Instanced rendering for scale
- Entropy as a scalar visual parameter
- Source → Filter → Transmute → Sink pipeline shape

**Core API target:**
```typescript
const runtime = new Runtime(canvasElement);
const stream = runtime.createStream('particles');
stream.add({ id: 'p1', geometry: 'sphere', matrix: identity4x4(), entropy: 0.5 });
runtime.start();
```

---

### Episode 2 — Pattern Library `[FUTURE]`

**Goal:** Built-in stream patterns. BaBbLE command layer (optional, shell-facing).

#### Episode 2 Exit Conditions

- [ ] `organic` pattern (golden-angle Fibonacci growth)
- [ ] `lattice` pattern (geometric grid)
- [ ] `swarm` pattern (particle cloud with drift)
- [ ] `galaxy` pattern (spiral arms)
- [ ] Pattern generator accepts entropy parameter (0.0 = ordered, 1.0 = full chaos)
- [ ] BaBbLE command pipeline over NeBuLA engine (`dream`, `stream`, `collapse`, `chaos`, `status`)

---

### Episode 3 — Layer Integration `[FUTURE]`

**Goal:** Wire Layer 1 (rabble-entity.js) to Layer 2 (NeBuLA engine).

#### Episode 3 Exit Conditions

- [ ] Entity state bridge: `entity.setEntityState()` triggers NeBuLA entropy shift
- [ ] `idle` → entropy 0.3 (calm environment)
- [ ] `thinking` → entropy 0.6 (stirring)
- [ ] `speaking` → entropy 0.8 (active)
- [ ] Integration works without coupling the two renderers
- [ ] Demo: entity.js face + NeBuLA environment side-by-side on canvas

---

### Episode 4 — RaBbLE-World Integration + Visual Puppet + Studio `[FUTURE]`

**Goal:** NeBuLA is the primary graphics engine in World. Visual Puppet extracted from World into NeBuLA. Studio authoring tool ships.

#### Episode 4 Exit Conditions

**Visual Puppet extraction:**
- [ ] `src/puppet/index.js` exports `createPuppet({ canvas, particleCount, overscan, THREE })`
- [ ] Eyes, blink state machine, saccade system extracted from World's `RaBbLE-NeBuLA.js` into `src/puppet/eye-controller.js`
- [ ] Boot sequence timeline extracted into `src/puppet/boot-sequence.js`
- [ ] `createPuppet` returns `{ setEntityState, injectEyeJolt, resize, destroy }` — same API as current World
- [ ] Three.js path renders particle sphere with purple→cyan gradient (matching Aether `--rabble-violet` → `--rabble-cyan`) + emissive glow

**World wiring:**
- [ ] World's `world/js/RaBbLE-NeBuLA.js` becomes thin adapter (~40 lines) that calls `createPuppet`
- [ ] `index.html` adds Three.js CDN tag + NeBuLA script tag (or local file)
- [ ] `window.NeBuLA.backend` reflects actual backend in use (`'Canvas2D'` or `'Three.js'`)
- [ ] Status bar in World shows correct backend and particle count
- [ ] Mobile: Canvas2D backend auto-selected (no WebGL check needed if device pixel ratio < 2 and screen width < 900)

**NeBuLA Studio:**
- [ ] `world/RaBbLE-Studio.html` — standalone developer tool using Tiling WM layout (3 applets)
- [ ] State switcher: idle / thinking / speaking buttons trigger live transitions
- [ ] Entropy slider: 0.0–1.0, overrides stream entropy in real time
- [ ] Pattern selector: organic / lattice / swarm / galaxy
- [ ] Backend toggle: Canvas2D ↔ Three.js live switch
- [ ] Performance overlay: FPS, entity count, average entropy
- [ ] Expression editor: name + export JSON for Grimoire storage

---

### Episode 5 — WebGPU Backend `[FUTURE]`

**Goal:** High-throughput web rendering. Replaces Three.js for the quantum visualization layer when WebGPU is stable across Safari/Chrome/Firefox.

#### Episode 5 Exit Conditions

- [ ] WebGPU backend renders identical scene output to Three.js backend
- [ ] Compute shaders handle Flat-Chaos entropy field calculation
- [ ] Performance target: 10,000+ entities @ 60 FPS (10× Ep1 baseline)
- [ ] Three.js backend retained as fallback for non-WebGPU environments

---

### Episode 6 — C++ / OpenGL Backend `[FUTURE]`

**Goal:** Native portable rendering. Enable the entity on desktop surfaces without a browser.

#### Episode 6 Exit Conditions

- [ ] C++ rendering core that can run the entity persona (Canvas2D equiv.) natively
- [ ] OpenGL ES compatibility (matches WebGL surface parity)
- [ ] CMake build target, no Node/npm dependency
- [ ] Plymouth integration: entity boots on RaBbLE-OS startup screen (replaces static Plymouth theme)
- [ ] Qt/QML wrapper: `<RaBbLEEntity />` QML component using OpenGL surface

**Note:** The boot sequence animation in `RaBbLE-World/world/RaBbLE-Boot.html` is the reference design for the Plymouth boot screen. It demonstrates the particle convergence → portal arcs → eye emergence timeline that should be reproduced natively for RaBbLE-OS startup.

---

### Episode 7+ — Advanced Features `[FUTURE]`

Ideas from `RaBbLE-NeBuLA-Ideas.md`:

- Interactive Entropy Canvas (entropy wells, quantum trails, stream splitting)
- Reaction-Diffusion stream patterns (Turing patterns)
- Audio reactivity (entropy driven by audio spectrum)

---

## Known Risks (Pre-Mortem)

| Risk | Mitigation |
|---|---|
| **Bundle size** — bundling Three.js makes the CDN tag ~700KB | Three.js is always external; accept `THREE` as constructor arg in `ThreeJsBackend`; two-tag delivery pattern |
| **No build system yet** — NeBuLA has no `build` script | Add esbuild as first step of Ep1; don't proceed to backends until `npm run build` produces valid output |
| **Layer 1 extraction breaking live World** | Keep World's monolith running until replacement is verified pixel-for-pixel; never delete the monolith before the puppet passes visual review |
| **Canvas layering** — two stacked canvases (entity + environment) need correct z-index and pointer-events | Document explicit DOM structure requirement in Architecture.md; set `pointer-events: none` on Layer 2 canvas in plan |
| **Palette drift** — JS constants diverge from Aether CSS variables | `palette.js` reads Aether CSS vars first, falls back to constants; single comment in that file pointing to Palette.md |
| **Performance unverifiable in CI** — no GPU in test runner | Accept manual browser verification for 1000-entity perf test; log FPS in the example page; Studio overlay shows live FPS |
| **Cloudflare delivery untested** — wrangler.jsonc not validated for binary static asset serving | Test locally first; host on Cloudflare Pages or R2 as alternative to Workers static assets |
| **Studio scope eating engine** — authoring tool is complex | Studio is Ep4, not Ep1; do not start it until World integration is live and stable |
| **Mobile perf cliff** — Three.js on iPhone will miss 60fps | Canvas2D is default for mobile; Three.js opted in explicitly or detected via WebGL capability check |
| **API surface instability** — World breaks silently when NeBuLA internals change | Lock public API contract before rewiring World; document it in Architecture.md; treat it as a breaking-change boundary |

---

## Reference Files

| File | Purpose |
|---|---|
| `RaBbLE-NeBuLA-Architecture.md` | Two-layer model, Layer 1 API, Layer 2 primitives |
| `RaBbLE-NeBuLA-FlatChaos.md` | Flat-Chaos pattern spec — carry this forward |
| `RaBbLE-NeBuLA-RABL.md` | RABL serialization format for scene export |
| `RaBbLE-NeBuLA-RBCNS.md` | Historical naming conventions (do not follow — reference only) |
| `RaBbLE-NeBuLA-Ideas.md` | Enhancement proposals for Episodes 3+ |
| `RaBbLE-NeBuLA-Identity.md` | Entity lore, origin, philosophy |
| `RaBbLE-World/rabble-entity.js` | Layer 1 reference implementation (do not duplicate) |
| `RaBbLE-Xperimental/` | Archived original NeBuLA-JS code — architectural reference only |

---

```
transcribe ~ grimoire >> trajectory crystallized // %NEBULA_ROADMAP_LOCKED%
```
