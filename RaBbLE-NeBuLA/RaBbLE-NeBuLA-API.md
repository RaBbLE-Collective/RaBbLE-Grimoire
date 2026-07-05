# RaBbLE-NeBuLA API Reference

```
transcribe ~ nebula >> api doc rewritten against real source (createPuppet purged) // %NEBULA_API_SPEC%
```

> **Rewritten S193/S194 architecture audit.** The previous version of this
> document described a `window.NeBuLA.createPuppet()` factory function. That
> function has never existed in `src/` — zero matches for `createPuppet`
> anywhere in the NeBuLA source tree. The real public API is a set of custom
> elements (`<rabble-entity>`, `<rabble-floor>`, `<rabble-graph>`,
> `<rabble-doors>`) plus the `window.NeBuLA` namespace they populate. This
> rewrite documents what is actually in `src/` as of this pass — verify
> against source before relying on any signature below if more time has
> passed.

---

## Overview

NeBuLA ships as a single IIFE/ESM bundle (`dist/nebula.iife.js` /
`dist/nebula.esm.js`, built from `src/index.js`) that, on import, registers
four custom elements and exposes a `window.NeBuLA` namespace (IIFE build
only — the ESM build exposes the same surface as named exports).

| Element | What | Backend |
|---|---|---|
| `<rabble-entity>` | Entity persona — eyes, portal, particle nebula, blink/saccade | Canvas2D (default) or Three.js (opt-in `backend="threejs"`, falls back to Canvas2D silently) |
| `<rabble-floor>` | Cosmic Grimoire floor — entity eye, portal arcs, knowledge-graph edges, bilinear color field | Three.js (lazy-loaded from CDN) |
| `<rabble-graph>` | Cosmic Grimoire knowledge graph — entity eyes + portals + force-directed graph | Three.js (lazy-loaded from CDN) |
| `<rabble-doors>` | N threshold doors on elliptical orbits around a central core | DOM/CSS transforms, no canvas |

Source: `src/element.js`, `src/elements/floor.js`, `src/elements/graph.js`,
`src/elements/doors.js`. All four register via `customElements.define(...)`
as a side effect of importing `src/index.js`.

---

## Installation & Setup

### From CDN

```html
<!DOCTYPE html>
<html>
<head>
  <title>RaBbLE Page</title>
  <link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css">
</head>
<body>
  <!-- Three.js is only needed if you use backend="threejs", <rabble-floor>, or <rabble-graph> -->
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  <script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>

  <rabble-entity id="entity" mode="idle" particle-count="150"></rabble-entity>

  <script>
    const entity = document.getElementById('entity');
    entity.addEventListener('entity-ready', () => {
      entity.setEntityState('thinking');
    });
  </script>
</body>
</html>
```

Importing the bundle is enough to register the elements — there is no setup
call. `window.NeBuLA` becomes available immediately (IIFE build); its
runtime-instance fields (`_instance`, `activeBackend`, etc.) populate once a
`<rabble-entity>` connects (see "The window.NeBuLA namespace" below).

### From NPM (for bundlers)

```bash
npm install rabble-nebula three
```

```js
import 'rabble-nebula';   // side-effect import: registers all four elements

// Or, to use the internals directly without the custom elements:
import { Canvas2dBackend, ThreeJsBackend } from 'rabble-nebula';
```

`peerDependencies` requires `three >= 0.150.0` if you use the Three.js
backend, `<rabble-floor>`, or `<rabble-graph>`.

---

## `<rabble-entity>` — the entity persona element

Source: `src/element.js`. This is what `window.NeBuLA._instance` and
`activeBackend` describe once mounted; it is the primary way to embed the
RaBbLE entity in a page.

### Attributes

| Attribute | Values | Default | Notes |
|---|---|---|---|
| `backend` | `canvas2d` \| `threejs` | `canvas2d` | `threejs` silently falls back to Canvas2D if WebGL is unavailable or Three.js fails to load |
| `mode` | `idle` \| `boot` | `idle` | `boot` triggers the boot sequence on mount (Three.js backend) |
| `particle-count` | number | `150` | Capped centrally: 150 desktop / 100 mobile, regardless of what's requested |
| `overscan` | number | `2.35` | Canvas internal-size multiplier for glow bleed; auto-reduced on short viewports / small hosts |
| `interactive` | bool (`"false"`/`"0"` = off) | `true` | |
| `show-waveform` | bool | `false` | |
| `fallback-width` | number | `460` | Used only if the host element reports zero size |
| `fallback-height` | number | `320` | |

### Methods

```js
const entity = document.querySelector('rabble-entity');

entity.setEntityState(state);       // delegates to backend.setEntityState(s); falls back to
                                     // setAttribute('state', s) if no backend mounted yet
entity.injectEyeJolt(dx, dy);       // startle eyes; dx/dy roughly -1..1
entity.setEntropy(val);             // direct entropy value, bypasses named states
entity.triggerBoot();               // (re)run the boot sequence
entity.pause();
entity.resume();
entity.setEyeConfig(cfg);           // backend-specific eye config object
entity.setParticleConfig(cfg);      // backend-specific particle config object
entity.setPortalVisible(visible);   // bool
entity.getSnapshot();               // returns backend.getSnapshot(), or null if unmounted
```

The specific shape of `state`, `cfg`, and the snapshot object are defined by
whichever backend is mounted (`src/backends/canvas2d-backend.js` or
`src/backends/threejs-backend.js`) — read the backend source for the
authoritative contract before depending on internal fields.

### Events

| Event | Where | Detail |
|---|---|---|
| `entity-ready` | dispatched on the `<rabble-entity>` element, bubbles | fires once the backend has mounted (Canvas2D immediately, Three.js after async load) |
| `rabble:entity-ready` | dispatched on `window` | same signal, for listeners that don't have a handle on the element |

### Example

```html
<rabble-entity id="entityHost" mode="boot" particle-count="150"></rabble-entity>

<script>
  const host = document.getElementById('entityHost');
  host.addEventListener('entity-ready', () => {
    host.setEntityState('thinking');
    host.injectEyeJolt(0.2, -0.1);
  });
</script>
```

---

## `<rabble-floor>` — Grimoire floor (Three.js)

Source: `src/elements/floor.js`.

**Attributes:** `zoom`, `pan-x`, `pan-y`

**Methods:**

```js
const floor = document.querySelector('rabble-floor');
floor.setData({ docs, kinds, seals, memberUV });
floor.focusOwner(ownerKey);
floor.traceOwner(ownerKey);
floor.narrateRandom(ownerKey);   // ownerKey optional
floor.ownerScreenPos(ownerKey);
floor.resetView();
floor.owners();
floor.centerScreenPos();
floor.onSelect(cb);              // cb(ownerKey) fires on node selection
```

**Events:** `rabble-floor-ready` (after the Three.js scene mounts),
`rabble-floor-select` (detail: `{ owner }`).

---

## `<rabble-graph>` — knowledge graph (Three.js)

Source: `src/elements/graph.js`. Self-contained — entity eyes + portals +
force-directed graph, no external DOM hooks required.

**Methods:**

```js
const graph = document.querySelector('rabble-graph');
graph.setData({ docs, kinds, seals, memberUV });
graph.zoomIn();
graph.zoomOut();
graph.resetView();
graph.focusOwner(ownerKey);
graph.narrateRandom(ownerKey);   // ownerKey optional
graph.owners();
```

**Events:** `rabble-graph-ready`, `rabble-graph-select` (detail: `{ doc, kind, seal, col }`),
`rabble-graph-deselect`.

`floor.js` and `graph.js` are near-duplicate implementations (same
eye/portal suite, independently maintained) — flagged in the architecture
audit as a unification candidate, not yet actioned.

---

## `<rabble-doors>` — threshold orbit engine

Source: `src/elements/doors.js`. N doors on elliptical paths around a
central core, passing behind/in front of it. Self-contained: builds its own
DOM doors, animates them, accents pull from Aether palette CSS vars
(never raw hex).

**Attributes:** `count` (default `6`, ignored once `setDoors()` supplies a
set), `speed` (default `1.0`)

**Methods:**

```js
const doors = document.querySelector('rabble-doors');
doors.setDoors([{ id, name, url, glyph, accent, organ }]);
doors.setSpeed(0.2);
doors.setEntityState('glitch');   // 'idle' | 'resonant' | 'glitch'
```

**Events:** `rabble-doors-enter` (detail: `{ id, name, url }`),
`rabble-doors-leave`, `rabble-doors-trace` (detail: `{ count }`, fires once
every door has been visited).

```html
<rabble-doors count="6" speed="1"></rabble-doors>
```

---

## The `window.NeBuLA` namespace

Populated by `src/index.js` (the IIFE build's `--global-name=NeBuLA`
target). ESM consumers get the same surface as named exports from
`rabble-nebula` instead of a global.

### Static exports

```js
window.NeBuLA.version    // '0.0.0.0'
window.NeBuLA.backend    // 'Canvas2D' — the default; NOT necessarily what's mounted
window.NeBuLA.backends   // ['Canvas2D', 'Three.js']
```

### Runtime fields (written by `<rabble-entity>` on connect)

```js
window.NeBuLA._instance      // the mounted backend instance (Canvas2dBackend | ThreeJsBackend)
window.NeBuLA.particleCount  // effective (capped) particle count
window.NeBuLA.glowScale      // 1.0 desktop, 0.35 mobile
window.NeBuLA.renderDpr      // capped device pixel ratio actually in use
window.NeBuLA.activeBackend  // 'Canvas2D' | 'Three.js' — what's actually mounted
```

These are set on every `<rabble-entity>` connect and cleared
(`_instance = null`) on disconnect. If multiple `<rabble-entity>` elements
are on the page, these fields reflect whichever connected most recently —
they are a convenience for the common single-entity case, not a registry.

### `window.NeBuLA.ui.*` — DOM/SVG factories

Source: `src/ui/index.js`.

```js
window.NeBuLA.ui.createEntityMini(...)
window.NeBuLA.ui.ENTITY_PALETTES
window.NeBuLA.ui.createGrimoireEye(...)
window.NeBuLA.ui.createAmbientEye(...)
window.NeBuLA.ui.createGrimoireRing(...)
```

### `window.NeBuLA.effects.*` — parameterized rendering effects

Source: `src/effects/effects-ns.js` (re-exports from `src/effects/index.js`
under canonical camelCase names).

**Factory effects** — `(target, opts) -> { start(), stop(), setParams(opts) }`:

```js
window.NeBuLA.effects.starfield(target, opts)       // seeded depth-layered starfield, cursor parallax
window.NeBuLA.effects.streaks(target, opts)         // rare passing signal-streak lines
window.NeBuLA.effects.constellation(target, opts)   // lines from cursor to nearby seeded points
window.NeBuLA.effects.haze(target, opts)            // slow-drifting radial nebula blobs, low-res + upscaled
```

`target` is any `HTMLElement`; each factory appends its own canvas into it
and resolves palette from Aether CSS vars at runtime (no raw hex in the
effect logic itself).

**Class effects** — instantiated with `new`:

```js
new window.NeBuLA.effects.entropy(config)        // EntropyShader — GLSL vertex/fragment shader pair
new window.NeBuLA.effects.attractor(opts)        // EntropyAttractor — entropy-based repel/attract on a Stream
new window.NeBuLA.effects.ambientField(opts)     // AmbientField — background grid + particle nebula (drop-in
                                                  // replacement for the old rabble-bg.js)
new window.NeBuLA.effects.AnimationFilter(type, opts)
  // type: 'blink' | 'dart' | 'pulse' | 'orbit' | 'wave'
  // procedural per-entity animation, apply(stream, dt)
```

> `AnimationFilter` was exported from `src/effects/index.js` but missing
> from `effects-ns.js` prior to this pass — it never reached
> `window.NeBuLA.effects` in the built bundle. Fixed alongside this doc
> rewrite; requires a `npm run build:iife` + re-vendor into World to take
> effect in any page that already loads the bundle.

### Core / pattern / backend exports

Re-exported flat onto `window.NeBuLA` (not namespaced) via
`export * from './core/index.js'` etc. in `src/index.js`:

```js
// core (src/core/index.js)
window.NeBuLA.createEntity(...)
window.NeBuLA.cloneEntity(...)
window.NeBuLA.Stream            // class
window.NeBuLA.Runtime           // class
window.NeBuLA.AnimationMixer    // class
window.NeBuLA.BootSequence      // class

// patterns (src/patterns/index.js)
window.NeBuLA.PatternGenerator  // class

// backends (src/backends/index.js)
window.NeBuLA.Renderer          // class
window.NeBuLA.ThreeJsBackend    // class
window.NeBuLA.Canvas2dBackend   // class
```

These are lower-level primitives — most page authors want the custom
elements above, not these directly. They exist for consumers building a
custom mount (as `<rabble-entity>` itself does internally).

---

## Entity State (`setEntityState`)

Named states accepted by the Canvas2D and Three.js backends via
`entity.setEntityState(state)`:

| State | Meaning |
|---|---|
| `idle` | Waiting, listening — dim glow, calm particles |
| `thinking` | Processing, reasoning — medium glow, faster shimmer |
| `speaking` | Active output — bright glow, intense shimmer |

Exact entropy values and transition timing are internal to each backend —
read `src/backends/canvas2d-backend.js` / `src/backends/threejs-backend.js`
for current numbers before depending on them; they are tuning constants, not
part of the frozen contract.

---

## Performance

Explicit contract (per NeBuLA's `AGENT.md`): **1000+ entities at 60 FPS.**
There is currently no automated test enforcing this — `test/` holds only a
`.gitkeep` (flagged in the architecture audit, SP-6).

`<rabble-entity>` itself caps `particle-count` centrally to 150
desktop / 100 mobile regardless of what a page requests — the Three.js
backend (instanced rendering, one draw call) is the intended path for
higher counts, not raising the Canvas2D cap.

---

## Five-Es Versioning

- **Pre-Episode-1:** `v0.0.0.0` → CDN path `nebula/v0.0.0/`
- **After Episode-1 airs:** `v0.0.0.1` → CDN path `nebula/v0.0.0.1/`

Always pin to a specific version in production.

```html
<!-- Production -->
<script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>

<!-- Not recommended — floats to latest -->
<script src="https://cdn.joinrabble.world/nebula/latest/nebula.iife.js"></script>
```

Note (architecture audit, S193): World currently vendors
`dist/nebula.iife.js` directly into `world/js/RaBbLE-NeBuLA.js` rather than
loading it from CDN at runtime — the `RABBLE_NEBULA_URL` config flip exists
but has zero consumers. Treat the CDN path above as the documented target,
not necessarily what World does today; that delivery-story decision is open
for Mark (see `Collective-Architecture-Audit-2026-07-04.md` §2.3).

---

```
transcribe ~ nebula >> real element/namespace api documented, createPuppet purged // %NEBULA_API_SPEC%
```
