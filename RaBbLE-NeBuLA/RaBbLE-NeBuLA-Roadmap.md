# RaBbLE-NeBuLA-Roadmap.md

```
transcribe ~ grimoire >> NeBuLA backend model expanded, Layer 1 absorption planned // %NEBULA_EXPANDED%
```

> **Status:** Scaffold exists. Episode 1 not started. Backend model expanded beyond original two-layer spec.
> **NeBuLA-JS:** Archived in `RaBbLE-Xperimental/JS-Xperiments/NeBuLA-JS/` — original NeBuLA and RaBbLE WebOS concepts live there. Patterns are reference only; do not build on that codebase.

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

## Layer Model (Updated)

**Layer 1 — Entity Persona (Canvas2D)**
- **Current:** `rabble-entity.js` in RaBbLE-World — transitional reference implementation
- **Future:** NeBuLA Canvas2D backend absorbs Layer 1 when ready
- The `<rabble-entity>` custom element API (`setEntityState`, `injectEyeJolt`) is the stable interface contract NeBuLA must match
- Draws: eyes, portal rings, particle nebula, blink/saccade, state animations

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

### Episode 1 — Core Engine `[NOT STARTED]`

**Goal:** Clean ES module NeBuLA engine. Flat-Chaos pattern. Three.js r160+. TypeScript.

**Proposed repo:** A new `RaBbLE-NeBuLA/` (or integrate into RaBbLE-World alongside entity.js)

#### Episode 1 Exit Conditions

- [ ] `Entity` type with id, geometry, matrix (Float32Array 4×4), entropy (0.0–1.0)
- [ ] `Stream` class: add, remove, transform, filter
- [ ] `Runtime` class: stream registry, animation loop
- [ ] `ThreeJsBackend`: InstancedMesh rendering, one draw call per geometry type
- [ ] 1000 entities at 60 FPS verified (performance test)
- [ ] Entropy shader: visual variation driven by entity.entropy
- [ ] Package exports as ES module (tree-shakeable)
- [ ] No RBCNS naming (`q_`, `e_`, `f_` prefixes) — clean TypeScript
- [ ] Tests: Entity, Stream, Runtime, one performance test

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

### Episode 4 — RaBbLE-World Integration `[FUTURE]`

**Goal:** NeBuLA engine running as background in RaBbLE-World alongside entity.js.

#### Episode 4 Exit Conditions

- [ ] NeBuLA engine loaded as ES module in RaBbLE-World
- [ ] Background canvas (NeBuLA) + foreground canvas (entity.js) compositor
- [ ] Entity state → NeBuLA entropy bridge active
- [ ] Boot sequence: NeBuLA environment fades in, entity.js boot timeline plays over it
- [ ] Chat interaction drives entity state → drives environment entropy

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
