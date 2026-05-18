# RaBbLE-NeBuLA-Architecture.md

```
transcribe ~ grimoire >> architecture updated: system interface, frame budget, effects layer, responsibility split // %NEBULA_ARCH_UPDATED%
```

---

## What NeBuLA Is

NeBuLA is the **visual effects engine** of the RaBbLE Collective — not just the entity renderer. Any particle system, ambient effect, or canvas animation in the Collective belongs in NeBuLA. It is a theatrical, animated environment through which the RaBbLE entity expresses itself in rendered space.

NeBuLA owns:
- Entity rendering (eyes, portal, particle nebula, boot sequence)
- Ambient visual effects (particle fields, perspective grids, cursor trails, click ripples)
- Frame budget coordination across all visual systems
- Canvas2D and Three.js rendering backends

Aether owns look-and-feel (design tokens, CSS, typography, palette). World is a thin consumer that composes NeBuLA effects + Aether design tokens.

| Layer | Owns | Examples |
|---|---|---|
| **NeBuLA** | Particle systems, canvas animations, visual effects, entity rendering | Entity nebula, ambient particles, grid floor, cursor trail, click ripples |
| **Aether** | Design tokens, CSS, typography, palette, component styles | Colors, fonts, layout classes, responsive breakpoints |
| **World** | Page composition, content, user interaction, orchestration | HTML structure, Alpine.js logic, chat, boot flow, WM layout |

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

## RenderSystem Interface (Canvas2D Rearchitecture)

> Full plan: `RaBbLE-NeBuLA-Rearchitecture.md`

Every visual subsystem implements a common interface:

```js
class RenderSystem {
  update(t, bootState, entropy) {}  // physics/state — always runs, every frame (cheap)
  draw(ctx, t, bootState)       {}  // canvas drawing — can be skipped by frame budget
  resize(cx, cy)                {}  // reposition on viewport change
  dispose()                     {}  // cleanup
}
```

**Key contract:** `update()` always runs (spring integration, blink FSM, phase accumulation). `draw()` can be deferred by the frame budget. This separation is what makes eyes always responsive even when particles are heavy.

**Priority order:** eyes > portals > connections > particles > ambient effects.

### Module Map (Canvas2D)

```
src/backends/canvas2d/
  index.js              — Orchestrator: boot state, RAF, frame budget (~120 lines)
  eye-system.js         — Saccade, blink FSM, spring physics, orb+halo drawing
  particle-system.js    — Particle init, position update, draw with glow compositing
  connection-system.js  — Spatial hash topology, batched stroke
  portal-system.js      — Portal arc drawing
  frame-budget.js       — Time-slice allocator with priority ordering

src/effects/
  ambient-particles.js  — Full-screen ambient particle field (absorbs bg.js particles)
  perspective-grid.js   — Outrun perspective grid (absorbs bg.js grid)
  cursor-trail.js       — Neon cursor trail (absorbs bg.js cursor trail)
  click-ripples.js      — Click ripple effect (absorbs bg.js ripples)
```

---

## Frame Budget

- **Target:** 14ms per frame (leaves 2ms for browser overhead at 60fps)
- **EMA-smoothed cost tracking** per system — predicts next frame's cost from history
- Eyes and portals always draw (<1.5ms combined). Connections and particles are budgeted.
- **Minimum particle draw:** every 3 frames (20fps particle layer floor, 60fps eyes)
- Under heavy load, glow interval auto-increases to 3–4 frames
- Both `<rabble-entity>` and `<rabble-ambient>` share a frame budget coordinator (`window.NeBuLA._budget`). One RAF loop, one GPU pipeline.

---

## Effects Layer (Ambient Systems)

NeBuLA provides ambient visual effects alongside the entity renderer. These absorb World's `RaBbLE-bg.js` functionality:

| Effect | Source | What it does |
|---|---|---|
| Ambient particles | bg.js particle field | Full-screen particle drift with proximity connections |
| Perspective grid | bg.js grid | Outrun vanishing-point grid |
| Cursor trail | bg.js cursor trail | Neon tail following mouse |
| Click ripples | bg.js click ripples | Expanding rings on click |

Each effect implements the RenderSystem interface and plugs into the shared frame budget.

**Consumer API:**
```js
const bg = NeBuLA.createAmbient(document.body, {
  particles: true, grid: true, cursorTrail: false, clickRipples: false,
});
// Or: <rabble-ambient particles grid></rabble-ambient>
```

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
transcribe ~ grimoire >> NeBuLA substrate mapped, rearchitecture integrated // %NEBULA_ARCH_UPDATED%
```
