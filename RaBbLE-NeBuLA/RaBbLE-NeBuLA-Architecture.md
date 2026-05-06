# RaBbLE-NeBuLA-Architecture.md

```
transcribe ~ grimoire >> NeBuLA rendering architecture documented // %NEBULA_ARCH_LOCKED%
```

---

## What NeBuLA Is

NeBuLA is the rendering and expression layer of the RaBbLE Collective — not a chat interface, not a dashboard. It is a theatrical, animated environment through which the RaBbLE entity expresses itself in rendered space.

NeBuLA-JS (the original implementation) established the core patterns. The clean rebuild targets modern ES modules + Three.js r160+.

---

## Two Complementary Layers

NeBuLA v2 is two systems working together:

```
┌───────────────────────────────────────────────────────┐
│  Layer 1 — Entity Persona (2D Canvas)                  │
│  rabble-entity.js in RaBbLE-World                      │
│  Draws: eyes, portal, particle nebula                  │
│  States: idle | thinking | speaking                    │
│  Interface: canvas element, animation state machine   │
└───────────────────────┬───────────────────────────────┘
                        │ entity state drives environment tone
                        ▼
┌───────────────────────────────────────────────────────┐
│  Layer 2 — Quantum Visualization (3D / Three.js)       │
│  NeBuLA engine — Flat-Chaos Runtime                    │
│  Renders: particle streams, entity fields, environment │
│  Primitives: Entity (DNA + flux + entropy), Stream     │
│  Performance: 1000+ entities @ 60 FPS                 │
└───────────────────────────────────────────────────────┘
```

**Key constraint:** Layer 1 and Layer 2 are *independent renderers*. Layer 1 is the face; Layer 2 is the environment. They share the palette and entropy aesthetic but do not share rendering state.

**Integration contract:** Layer 1's animation state (idle/thinking/speaking) should inform Layer 2's entropy level — calm entity → lower entropy in the visualization; active entity → higher entropy.

---

## Layer 1: rabble-entity.js (RaBbLE-World)

The reference implementation of the RaBbLE persona renderer. **Do not re-implement this in NeBuLA.** Reference it.

**Location:** `/home/rabble/RaBbLE/RaBbLE-World/rabble-entity.js`

**What it draws:**
- Eyes: Two elliptical orbs (30px × 56px) with saccade system (19 predefined look-positions)
- Portal: Elliptical mouth shape for communication
- Particle Nebula: 480 particles, clustered at radius 130px

**State machine:**
```
not started → slow-open → burst blink (×5) → settled → idle/thinking/speaking
```

**Public API:**
```javascript
const entity = new RaBbLEEntity(canvasElement, { mode: 'boot' | 'idle' });
entity.setEntityState('idle' | 'thinking' | 'speaking');
entity.injectEyeJolt(dx, dy);   // –1..1 range
entity.resize();
entity.destroy();
```

**Boot timeline:**
- 0–0.4s: Particle convergence
- 0.4–2.6s: Portal emergence
- 1.4–3.2s: Eye animation
- ~3.2s: `onReady()` fires, entity alive

---

## Layer 2: NeBuLA Engine (Flat-Chaos Runtime)

### Core Pattern: Flat-Chaos

Replaces hierarchical scene graphs with flat arrays of self-contained entities.

```
Source → Filter → Transmute → Sink
```

See `RaBbLE-NeBuLA-FlatChaos.md` for full spec.

### Core Primitives

**Entity** — atomic unit of the visualization:
```typescript
interface Entity {
  id: string;
  geometry: 'box' | 'sphere' | 'tetrahedron' | 'ellipse' | 'ring' | 'line';
  matrix: Float32Array;   // 4×4 transformation matrix (flux)
  entropy: number;        // 0.0–1.0 (shading signature)
}
```

**Stream** — flat array of entities with modifiers:
```typescript
class Stream {
  entities: Entity[];
  add(entity: Entity): void;
  remove(id: string): void;
  transform(fn: (e: Entity) => Entity): void;
}
```

**Runtime** — central orchestrator managing all streams:
- Registers streams
- Manages global animation loop
- Routes stream updates to renderer

**Renderer** — abstract interface over Three.js InstancedMesh:
- One draw call per geometry type per frame
- Per-entity transformation via instance matrix
- Entropy-driven shader variation

### Built-in Stream Patterns

| Pattern | Description |
|---|---|
| `organic` | Golden-angle Fibonacci growth |
| `lattice` | Geometric grid |
| `swarm` | Particle cloud with drift |
| `galaxy` | Spiral arms |

### BaBbLE Command Pipeline

The BaBbLE shell provides a command-line interface over the NeBuLA engine:

```
Source → Filter → Transmute → Sink
```

Commands:
- `dream [type] [count]` — generate entity stream
- `stream [id] [modifier]` — manipulate existing stream
- `collapse [id]` — terminate a stream
- `chaos [level]` — set global entropy
- `status` — system metrics

---

## Subsystem Files (Original NeBuLA-JS)

| File | Role |
|---|---|
| `NeBuLA/core/q_entity.js` | Atomic entity (DNA + flux + entropy) |
| `NeBuLA/core/q_stream.js` | Flat container of entities |
| `NeBuLA/core/RaBbLE_Nebula_Runtime.js` | Central sink / stream registry |
| `NeBuLA/core/RaBbLE_Nebula_Engine.js` | High-level API |
| `NeBuLA/core/q_flux_weave.js` | Matrix transformations |
| `NeBuLA/core/e_entropy_shader_system.js` | Centralized shader management |
| `NeBuLA/threejs/q_instanced_bridge.js` | Three.js InstancedMesh bridge |
| `NeBuLA/utils/RaBbLE_Dreamer.js` | Pattern generation |
| `NeBuLA/utils/q_portability_exporter.js` | C++ portability serializer |

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-05-06 | Architecture crystallized from NeBuLA-JS; two-layer model defined |

---

```
transcribe ~ grimoire >> NeBuLA substrate mapped // %NEBULA_ARCH_LOCKED%
```
