# RaBbLE-NeBuLA-Architecture.md

## Lessons & Gotchas (distilled from S14–S46)

- **Build before testing — every time.** Editing `src/` has zero visible effect until
  you rebuild and copy: `npm run build:iife && cp dist/nebula.iife.js
  ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`. A whole multi-session triage was lost to
  "fixes that appeared not to work" before this was made canon.
- **On a broken perf baseline, roll back — don't iterate.** The Codex
  `feature-nebula-animation-optimization` branch caused 1fps cliffs and broken visuals;
  several rounds of tuning on top of it failed or were unverifiable. The fix was to
  reset to known-good (World `aa66550`, NeBuLA `34dee62`), preserve the experiment on
  `feat/nebula-perf`, and rebuild forward from there. Don't trust anything on that
  branch as canonical.
- **Pre-computed connection links are wrong *during* boot.** Scattered particles
  produce long, expensive stroke paths even at near-zero alpha — use small-radius
  dynamic distance checks during boot, switch to pre-computed links once settled.
- **Post-boot particles drift ~±30px sinusoidally** because `settleBlend=1` zeroes the
  spring force — `connDist` has to account for this drift (try 85–100px), not just the
  nominal radius, or connection density will look wrong.
- **`shadowBlur` is the #1 GPU cost** (it's applied to ~45% of particles); flipping it
  on en masse at boot-end caused the 1fps cliff. Batch all connection strokes into one
  `beginPath`+`stroke` per frame — per-connection `ctx.stroke()` calls are catastrophic.
- **Two-canvas split is the standing architecture decision:** a particle/connection
  layer that's allowed to drop frames, plus a dedicated eye layer that always runs its
  own RAF at 60fps. See `RaBbLE-NeBuLA-Rearchitecture.md` (verified through Phase 3).
- **Always verify visually.** `visual-screenshot.sh` (build → capture → compare) is
  mandatory before claiming any rendering fix works — fps numbers alone have been wrong
  before.
- **RBCNS naming (`q_`/`e_`/`f_` prefixes) is archived lore only** — do not revive it;
  it was philosophically self-contradictory (claimed low-entropy while being rigid).
- **Long-range vision (Mark, S46):** NeBuLA should grow into a visualization/animation
  *studio* with a WYSIWYG keyframe editor, not stay just a renderer — design new
  per-layer parameter interfaces (size/position/timing/easing) as future editor
  binding surfaces from the start.

---

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

**Single renderer, both layers:** NeBuLA is the one engine that renders the entity on every surface. Both backends ship in the IIFE bundle — `window.NeBuLA.Canvas2dBackend` (Layer 1) and `window.NeBuLA.ThreeJsBackend` (Layer 2). Host pages choose a backend; they never hand-roll their own entity renderer. (S107: the NeBuLA Demo's Layer 2 panel was rewired from a throwaway inline particle cloud to `ThreeJsBackend`.)

**Constraint — Three.js is an external peer dependency (CDN).** `ThreeJsBackend` reads `window.THREE`; it is `--external:three` in the build, so the host page must load Three.js itself (currently `https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js`, matching the Grimoire-Graph page). This is an **accepted constraint for now** — Layer 2 requires network at runtime and will not render offline. Canvas2D (Layer 1) has no such dependency and remains the local-first default. Future: vendor Three.js locally / serve via the Aether-NeBuLA CDN subdomain when bundle hosting lands, to honor the Collective's local-first rule for the 3D surface too.

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
