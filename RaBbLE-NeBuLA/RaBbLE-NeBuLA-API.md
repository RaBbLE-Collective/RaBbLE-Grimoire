# RaBbLE-NeBuLA API Reference

```
transcribe ~ nebula >> api and usage patterns documented // %NEBULA_API_SPEC%
```

> **Phase 1 deliverable.** This document covers the public API that members use to embed NeBuLA visuals and animations in World and other surfaces.

---

## Overview

NeBuLA is a rendering engine that provides two layers:

| Layer | What | Input | Output |
|---|---|---|---|
| **Layer 1 — Visual Puppet** | Entity persona (eyes, portal, particles) | Canvas element | Canvas render, eye jolt, entity state |
| **Layer 2 — Quantum Visualization** | 3D Flat-Chaos particles and fields | Stream data | Three.js scene |

Both layers ship as a single bundle. Consumers choose which backend to use (Canvas2D for mobile, Three.js for desktop).

---

## Installation & Setup

### From CDN (recommended)

```html
<!DOCTYPE html>
<html>
<head>
  <title>RaBbLE Page</title>
  <!-- Design system -->
  <link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css">
</head>
<body>
  <!-- Container for entity -->
  <canvas id="entity-stage" width="460" height="320"></canvas>

  <!-- NeBuLA engine -->
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  <script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>
  
  <script>
    const canvas = document.getElementById('entity-stage');
    const puppet = window.NeBuLA.createPuppet({
      canvas,
      particleCount: 480,
      THREE: window.THREE,
      backend: 'auto',
      onReady: () => console.log('Entity ready')
    });
  </script>
</body>
</html>
```

### From NPM (for bundlers)

```bash
npm install rabble-nebula three
```

```js
import { createPuppet } from 'rabble-nebula';

const canvas = document.getElementById('stage');
const puppet = await createPuppet({
  canvas,
  particleCount: 480,
  THREE: window.THREE,
  backend: 'auto'
});
```

---

## Core API

### `window.NeBuLA.createPuppet(options)`

Creates the visual entity puppet. Returns a puppet object with animation controls.

**Options:**

```js
{
  canvas,              // HTMLCanvasElement (required)
  particleCount: 480,  // number of particles in nebula
  overscan: 2.55,      // canvas internal size multiplier (for glow bleed)
  THREE: null,         // Three.js global (required if backend='threejs' or 'auto' on desktop)
  backend: 'auto',     // 'auto' | 'canvas2d' | 'threejs'
  onReady: function    // callback when entity reaches full alpha
}
```

**Returns:**

```js
{
  setEntityState(state),  // 'idle' | 'thinking' | 'speaking'
  injectEyeJolt(dx, dy),  // startle eyes — dx/dy in range -1..1
  resize(),               // call after canvas is resized
  destroy()               // cleanup
}
```

**Example:**

```js
const puppet = window.NeBuLA.createPuppet({
  canvas: document.getElementById('entity'),
  particleCount: 480,
  THREE: window.THREE,
  backend: 'auto',
  onReady: () => {
    console.log('Entity emerged');
    puppet.setEntityState('thinking');
  }
});

// Later...
puppet.setEntityState('speaking');  // intensify glow
puppet.injectEyeJolt(0.5, -0.3);    // startle eyes
window.addEventListener('resize', () => puppet.resize());
```

---

## Entity State

### `setEntityState(state: 'idle' | 'thinking' | 'speaking')`

Transitions entity entropy smoothly to match the state. Used to reflect RaBbLE's internal processing.

| State | Entropy | Visual | Meaning |
|---|---|---|---|
| `idle` | 0.3 | Dim glow, calm particles | Waiting, listening |
| `thinking` | 0.6 | Medium glow, faster shimmer | Processing, reasoning |
| `speaking` | 0.8 | Bright glow, intense shimmer | Active output, high engagement |

**Behavior:**
- Transition is smooth over ~800ms
- All particles in the entity stream transition together
- Entropy drives shader color hue oscillation and displacement

**Example:**

```js
// React to user input
document.getElementById('ask-input').addEventListener('focus', () => {
  puppet.setEntityState('thinking');
});

// Respond to API events
fetch('/api/query', { method: 'POST' })
  .then(r => r.json())
  .then(data => {
    puppet.setEntityState('speaking');
    // ... handle response
  });
```

---

## Eye Interaction

### `injectEyeJolt(dx: -1..1, dy: -1..1)`

Temporarily override the entity's saccade target (where the eyes look). Creates a startle effect.

**Parameters:**
- `dx`: Horizontal jolt (-1 = far left, 0 = center, 1 = far right)
- `dy`: Vertical jolt (-1 = far up, 0 = center, 1 = far down)

**Behavior:**
- Eyes snap to the jolt target over ~100ms
- Resume normal saccade after ~300ms
- Does NOT affect particle position

**Example:**

```js
// Respond to user mouse movement
document.addEventListener('mousemove', (e) => {
  const rect = canvas.getBoundingClientRect();
  const x = (e.clientX - rect.left) / rect.width * 2 - 1;
  const y = (e.clientY - rect.top) / rect.height * 2 - 1;
  puppet.injectEyeJolt(x, y);
});

// Startle on notification
window.addEventListener('message', (e) => {
  if (e.data.type === 'notification') {
    puppet.injectEyeJolt(Math.random() * 2 - 1, Math.random() * 2 - 1);
  }
});
```

---

## Resize Handling

### `resize()`

Call this after the canvas container is resized. Recalculates internal rendering dimensions and camera aspect ratio.

**Example:**

```js
const resizeObserver = new ResizeObserver(() => {
  puppet.resize();
});
resizeObserver.observe(canvas.parentElement);
```

---

## Backend Selection

**Auto mode** (`backend: 'auto'`):
- Desktop (dpr ≥ 1.5, Three.js available): uses Three.js
- Mobile or fallback: uses Canvas2D
- No code change needed — NeBuLA picks the best option

**Explicit Canvas2D:**

```js
const puppet = window.NeBuLA.createPuppet({
  canvas,
  backend: 'canvas2d'  // Forces 2D rendering
});
```

**Explicit Three.js:**

```js
const puppet = window.NeBuLA.createPuppet({
  canvas,
  backend: 'threejs',
  THREE: window.THREE
});
```

---

## Performance

**Performance targets:**

| Backend | Entities | FPS | Device |
|---|---|---|---|
| Canvas2D | 100–480 | 55+ | Mobile, older browsers |
| Three.js | 1000+ | 60 | Desktop, modern browsers |

**Tips:**

- Use `particleCount: 100` on mobile, `480+` on desktop
- `overscan: 1.5` on low-end devices, `2.55` for high glow bleed effect
- Check `puppet.getStats()` (if exposed) for FPS and entity count

---

## Usage in World Pages

### Puppet in Boot Sequence

```html
<!-- world/RaBbLE-Boot.html -->
<rabble-entity id="entityHost" mode="boot" particle-count="480"></rabble-entity>

<!-- entityHost is a custom element wrapping NeBuLA.createPuppet() -->
<script>
  const host = document.getElementById('entityHost');
  host.setEntityState('thinking');
  host.injectEyeJolt(0.2, -0.1);
</script>
```

### Puppet in Landing Page

```html
<!-- world/RaBbLE-Landing.html -->
<div class="entity-wrap">
  <canvas id="entity-canvas"></canvas>
</div>

<script>
  const puppet = window.NeBuLA.createPuppet({
    canvas: document.getElementById('entity-canvas'),
    particleCount: 480,
    THREE: window.THREE,
    onReady: () => {
      // Start in idle, respond to user interaction
      puppet.setEntityState('idle');
    }
  });

  // Wire to landing interaction
  document.addEventListener('click', (e) => {
    if (e.target.closest('[role="button"]')) {
      puppet.setEntityState('thinking');
    }
  });
</script>
```

### Puppet in New Pages

```html
<!-- Template for new pages -->
<canvas id="entity" width="460" height="320"></canvas>

<script src="https://cdn.jsdelivr.net/npm/three@0.160/build/three.min.js"></script>
<script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>

<script>
  const puppet = window.NeBuLA.createPuppet({
    canvas: document.getElementById('entity'),
    particleCount: 480,
    THREE: window.THREE,
    backend: 'auto'
  });

  // Your page logic here — puppet is ready to use
  // puppet.setEntityState('speaking');
</script>
```

---

## Five-Es Versioning

NeBuLA ships in bundles tagged per Five-Es:

- **Pre-Episode-1:** `v0.0.0.0` → CDN path `nebula/v0.0.0/`
- **After Episode-1 airs:** `v0.0.0.1` → CDN path `nebula/v0.0.0.1/`

Always pin to a specific version in production. Update only when you're ready to test new features.

```html
<!-- Production -->
<script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>

<!-- Not recommended — floats to latest -->
<script src="https://cdn.joinrabble.world/nebula/latest/nebula.iife.js"></script>
```

---

```
transcribe ~ nebula >> public api documented, ready for integration // %NEBULA_API_SPEC%
```
