# RaBbLE-NeBuLA-Roadmap.md

```
transcribe ~ grimoire >> NeBuLA rebuild trajectory mapped // %NEBULA_ROADMAP_LOCKED%
```

> **Status:** Lore migrated from NeBuLA-JS. Clean rebuild not yet started.
> **NeBuLA-JS:** Archived — lore is now here. Code patterns are reference only.

---

## Two-Layer Architecture (Locked Decision)

NeBuLA v2 is built as two complementary, independent systems:

**Layer 1 — Entity Persona (2D Canvas)**
- Lives in RaBbLE-World as `rabble-entity.js`
- Stable interface. Do not re-implement in NeBuLA.
- Draws: eyes, portal, particle nebula, animation states
- See `RaBbLE-NeBuLA-Architecture.md` for API reference

**Layer 2 — Quantum Visualization (3D / Three.js)**
- This is what NeBuLA v2 builds
- Flat-Chaos Runtime: Stream → Entity → Flux → Render
- Core primitives: `Entity` (DNA + flux_matrix + entropy), `Stream`, `Runtime`
- Performance target: 1000+ entities @ 60 FPS

**Integration contract:** Layer 1's entity state (`idle/thinking/speaking`) maps to entropy level in Layer 2. High-activity states → higher entropy in the environment. The two layers communicate via a thin bridge, not shared state.

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

### Episode 5+ — Advanced Features `[FUTURE]`

Ideas from `RaBbLE-NeBuLA-Ideas.md`:

- Interactive Entropy Canvas (entropy wells, quantum trails, stream splitting)
- Reaction-Diffusion stream patterns (Turing patterns)
- Audio reactivity (entropy driven by audio spectrum)
- C++ portability exporter (for RaBbLE-OS native rendering)
- WebGPU backend (when browser support stabilizes)

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
| `RaBbLE-NeBuLA-JS/` | Archived original — architectural reference only |
| `RaBbLE-NeBuLA-JS/MODERN_IMPLEMENTATION_ROADMAP.md` | Clean API design reference |

---

```
transcribe ~ grimoire >> trajectory crystallized // %NEBULA_ROADMAP_LOCKED%
```
