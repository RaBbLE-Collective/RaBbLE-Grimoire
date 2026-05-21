# RaBbLE-NeBuLA Implementation Plan

```
transcribe ~ grimoire >> agent-ready implementation plan, Haiku-level specificity // %NEBULA_PLAN_LOCKED%
```

> **This document is the authoritative step-by-step implementation plan for NeBuLA Episodes 1 and 4.**
> Written for execution by any agent, including lower-capability models. Read it top to bottom. Do not skip steps.
> Cross-reference: `RaBbLE-NeBuLA-Roadmap.md` for exit conditions, `RaBbLE-NeBuLA-Architecture.md` for the layer model.

---

## Before You Start

**Read these files first, in order:**
1. `RaBbLE-NeBuLA/CONTEXT.md` — current branch and episode status
2. `RaBbLE-NeBuLA/src/index.js` — what is already exported
3. `RaBbLE-NeBuLA/src/core/runtime.js` — Runtime class (the animation loop)
4. `RaBbLE-NeBuLA/src/backends/renderer.js` — Renderer base class (what backends must implement)
5. `RaBbLE-Xperimental/JS-Xperiments/NeBuLA-JS/NeBuLA/threejs/q_instanced_bridge.js` — Three.js reference
6. `RaBbLE-Xperimental/JS-Xperiments/NeBuLA-JS/NeBuLA/shaders/vertex/q_instanced_vertex.glsl` — vertex shader reference
7. `RaBbLE-Xperimental/JS-Xperiments/NeBuLA-JS/NeBuLA/shaders/fragment/q_emissive_fragment.glsl` — fragment shader reference
8. `RaBbLE-World/world/js/RaBbLE-NeBuLA.js` — the monolith being replaced (Layer 1 reference)
9. `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md` — canonical color values

**Working directory:** `RaBbLE-NeBuLA/` for all NeBuLA work. `RaBbLE-World/` for World integration.

**Branch rule:** Create a branch named `episode-1` in `RaBbLE-NeBuLA/` before any code changes. Create `nebula-integration` in `RaBbLE-World/` before World changes.

---

## Phase 1 — Build System

**Goal:** `npm run build` produces two files: `dist/nebula.iife.js` and `dist/nebula.esm.js`.
Three.js is NOT bundled. The IIFE build sets `window.NeBuLA`.

### Step 1.1 — Add esbuild

In `RaBbLE-NeBuLA/`:

```bash
npm install --save-dev esbuild
```

### Step 1.2 — Add build scripts to package.json

Edit `RaBbLE-NeBuLA/package.json`. Replace the `"scripts"` section with:

```json
"scripts": {
  "build": "npm run build:iife && npm run build:esm",
  "build:iife": "npx esbuild src/index.js --bundle --format=iife --global-name=NeBuLA --external:three --outfile=dist/nebula.iife.js --minify",
  "build:esm": "npx esbuild src/index.js --bundle --format=esm --external:three --outfile=dist/nebula.esm.js --minify",
  "build:dev": "npx esbuild src/index.js --bundle --format=iife --global-name=NeBuLA --external:three --outfile=dist/nebula.iife.js --sourcemap",
  "typecheck": "npx tsc --allowJs --checkJs --noEmit --strict src/index.js"
}
```

### Step 1.3 — Create dist directory

```bash
mkdir -p RaBbLE-NeBuLA/dist
echo "# built output — do not edit" > RaBbLE-NeBuLA/dist/.gitkeep
```

Add to `RaBbLE-NeBuLA/.gitignore` (create if missing):
```
dist/*.js
dist/*.js.map
node_modules/
```

### Step 1.4 — Run the build

```bash
cd RaBbLE-NeBuLA && npm run build
```

**Done when:** `dist/nebula.iife.js` and `dist/nebula.esm.js` exist and are non-empty. The build may warn about unimplemented stubs throwing errors — that is expected until Phase 3 and 4 are complete.

---

## Phase 2 — Palette Constants

**Goal:** A single `src/puppet/palette.js` that reads from Aether CSS variables when available, falls back to `RaBbLE-Palette.md` hex constants. No raw hex anywhere else in NeBuLA.

### Step 2.1 — Create src/puppet/ directory

```bash
mkdir -p RaBbLE-NeBuLA/src/puppet
```

### Step 2.2 — Create palette.js

Create `RaBbLE-NeBuLA/src/puppet/palette.js` with this exact content:

```js
// Palette constants — mirrors RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md
// Reads from Aether CSS variables when available (Aether is the canonical theme layer).
// Falls back to hardcoded hex when running outside a page with Aether loaded.
// IMPORTANT: if RaBbLE-Palette.md changes, update the fallback hex values here to match.

function cssVar(name, fallback) {
  if (typeof document === 'undefined') return fallback;
  const val = getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  return val || fallback;
}

export const PALETTE = {
  magenta: () => cssVar('--rabble-magenta', '#ff2d78'),
  cyan:    () => cssVar('--rabble-cyan',    '#00f5ff'),
  violet:  () => cssVar('--rabble-violet',  '#bf5fff'),
  pink:    () => cssVar('--rabble-pink',    '#ff79c6'),
  bg:      () => cssVar('--rabble-bg',      '#0a0010'),
  surface: () => cssVar('--rabble-surface', '#12132a'),
  text:    () => cssVar('--rabble-text',    '#e8e6f0'),
};

// Resolved once at init time — call resolvePalette() at startup, cache the result.
export function resolvePalette() {
  return {
    magenta: PALETTE.magenta(),
    cyan:    PALETTE.cyan(),
    violet:  PALETTE.violet(),
    pink:    PALETTE.pink(),
    bg:      PALETTE.bg(),
    surface: PALETTE.surface(),
    text:    PALETTE.text(),
  };
}
```

**Done when:** File exists. No other file in `src/` contains a raw hex string like `#ff2d78`.

---

## Phase 3 — Canvas2D Backend

**Goal:** `Canvas2dBackend.render(streams)` draws entities on a 2D canvas without throwing.
This is the mobile-safe fallback and the first working render path.

### Step 3.1 — Replace the stub

Replace the entire contents of `RaBbLE-NeBuLA/src/backends/canvas2d-backend.js` with:

```js
import { Renderer } from './renderer.js';
import { resolvePalette } from '../puppet/palette.js';

export class Canvas2dBackend extends Renderer {
  /**
   * @param {HTMLCanvasElement} canvas
   */
  constructor(canvas) {
    super();
    this._canvas = canvas;
    this._ctx = canvas.getContext('2d');
    this._palette = resolvePalette();
    this._frameCount = 0;
    this._fps = 0;
    this._lastFpsTime = performance.now();
    this._drawCalls = 0;
  }

  /**
   * @param {import('../core/stream.js').Stream[]} streams
   */
  render(streams) {
    const ctx = this._ctx;
    const w = this._canvas.width;
    const h = this._canvas.height;
    const cx = w / 2;
    const cy = h / 2;
    const now = performance.now();

    ctx.clearRect(0, 0, w, h);
    this._drawCalls = 0;

    for (const stream of streams) {
      for (const entity of stream.getAll()) {
        if (!entity.active) continue;

        const x = cx + (entity.position[0] ?? 0) * 100;
        const y = cy + (entity.position[1] ?? 0) * 100;
        const scale = (entity.scale?.[0] ?? 1);
        const entropy = entity.entropy ?? 0;
        const opacity = (entity.opacity ?? 1) * (0.6 + entropy * 0.4);
        const blur = entropy * 18;
        const color = entity.color
          ? `rgba(${Math.round(entity.color[0]*255)},${Math.round(entity.color[1]*255)},${Math.round(entity.color[2]*255)},${opacity})`
          : this._defaultColor(entity.geometry);

        ctx.save();
        ctx.globalAlpha = opacity;
        if (blur > 0) {
          ctx.shadowColor = color;
          ctx.shadowBlur = blur;
        }
        ctx.fillStyle = color;
        ctx.strokeStyle = color;

        this._drawGeometry(ctx, entity.geometry, x, y, scale);
        this._drawCalls++;
        ctx.restore();
      }
    }

    // FPS tracking
    this._frameCount++;
    if (now - this._lastFpsTime >= 1000) {
      this._fps = this._frameCount;
      this._frameCount = 0;
      this._lastFpsTime = now;
    }
  }

  /**
   * @param {CanvasRenderingContext2D} ctx
   * @param {string} geometry
   * @param {number} x
   * @param {number} y
   * @param {number} scale
   */
  _drawGeometry(ctx, geometry, x, y, scale) {
    const s = Math.max(2, scale * 8);
    switch (geometry) {
      case 'sphere':
        ctx.beginPath();
        ctx.arc(x, y, s, 0, Math.PI * 2);
        ctx.fill();
        break;
      case 'box':
        ctx.fillRect(x - s, y - s, s * 2, s * 2);
        break;
      case 'tetrahedron': {
        const h = s * 1.732;
        ctx.beginPath();
        ctx.moveTo(x, y - h * 0.667);
        ctx.lineTo(x + s, y + h * 0.333);
        ctx.lineTo(x - s, y + h * 0.333);
        ctx.closePath();
        ctx.fill();
        break;
      }
      case 'ellipse':
        ctx.beginPath();
        ctx.ellipse(x, y, s * 1.5, s, 0, 0, Math.PI * 2);
        ctx.fill();
        break;
      case 'ring':
        ctx.beginPath();
        ctx.arc(x, y, s, 0, Math.PI * 2);
        ctx.arc(x, y, s * 0.6, 0, Math.PI * 2, true);
        ctx.fill();
        break;
      case 'line':
        ctx.beginPath();
        ctx.moveTo(x - s, y);
        ctx.lineTo(x + s, y);
        ctx.lineWidth = 2;
        ctx.stroke();
        break;
      default:
        ctx.beginPath();
        ctx.arc(x, y, s, 0, Math.PI * 2);
        ctx.fill();
    }
  }

  /** @param {string} geometry @returns {string} */
  _defaultColor(geometry) {
    switch (geometry) {
      case 'sphere':  return this._palette.cyan;
      case 'box':     return this._palette.magenta;
      default:        return this._palette.violet;
    }
  }

  resize() {
    // caller must update canvas.width/height before calling
  }

  dispose() {
    this._ctx = null;
  }

  getPerformanceMetrics() {
    return { fps: this._fps, frameTime: this._fps > 0 ? 1000 / this._fps : 0, drawCalls: this._drawCalls, triangles: 0 };
  }
}
```

### Step 3.2 — Verify Canvas2D renders

Update `RaBbLE-NeBuLA/examples/basic-scene.html` to use Canvas2D:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>NeBuLA — Basic Scene</title>
  <style>
    body { background: #0a0010; margin: 0; display: flex; justify-content: center; align-items: center; height: 100vh; }
    canvas { border: 1px solid #2a2840; }
  </style>
</head>
<body>
  <canvas id="stage" width="600" height="600"></canvas>
  <script type="module">
    import { Runtime, Canvas2dBackend, createEntity } from '../src/index.js';

    const canvas = document.getElementById('stage');
    const runtime = new Runtime(canvas);
    runtime.backend = new Canvas2dBackend(canvas);

    const stream = runtime.createStream('demo');
    for (let i = 0; i < 100; i++) {
      stream.add(createEntity(
        ['sphere', 'box', 'tetrahedron'][i % 3],
        [(Math.random() - 0.5) * 4, (Math.random() - 0.5) * 4, 0],
        Math.random()
      ));
    }

    runtime.start();
    console.log('Canvas2D backend running', runtime.getStats());
  </script>
</body>
</html>
```

Open `examples/basic-scene.html` in a browser (file:// or local server). You should see colored geometric shapes on a dark background with glow effects. No console errors.

**Done when:** 100 entities render, console shows stats, no errors.

---

## Phase 4 — Three.js Backend and Entropy Shaders

**Goal:** `ThreeJsBackend` renders entities as InstancedMesh with entropy-driven shader effects.
THREE is passed as a constructor argument — never imported. This is what makes the IIFE bundle work.

### Step 4.1 — Write the entropy shaders

Create `RaBbLE-NeBuLA/src/effects/entropy-shader.js` (replace the stub):

```js
// Entropy shader — maps entity.entropy to vertex displacement and color variance.
// These shader strings are injected into THREE.ShaderMaterial.
// Ported from RaBbLE-Xperimental/JS-Xperiments/NeBuLA-JS/NeBuLA/shaders/ (cleaned, no RBCNS names).

export const VERTEX_SHADER = /* glsl */`
  attribute float instanceEntropy;
  attribute float instanceSize;
  attribute float instanceOpacity;
  attribute float instanceEmissive;
  attribute vec3  instanceColor;

  uniform float u_time;

  varying float v_opacity;
  varying float v_emissive;
  varying vec3  v_color;
  varying vec3  v_position;

  void main() {
    v_opacity  = instanceOpacity;
    v_emissive = instanceEmissive;
    v_color    = instanceColor;
    v_position = position;

    float noise = sin(position.x * 2.0 + u_time) * cos(position.y * 2.0 + u_time * 1.5);
    float displacement = noise * instanceEntropy * 0.1;

    vec3 displaced = position * instanceSize + normal * displacement;
    gl_Position = projectionMatrix * modelViewMatrix * instanceMatrix * vec4(displaced, 1.0);
  }
`;

export const FRAGMENT_SHADER_EMISSIVE = /* glsl */`
  precision highp float;

  uniform float u_time;
  uniform float u_entropy;

  varying float v_opacity;
  varying float v_emissive;
  varying vec3  v_color;
  varying vec3  v_position;

  void main() {
    vec3 color = v_color;

    // Entropy-driven hue oscillation
    vec3 shift = vec3(
      sin(v_position.x * 2.0 + u_time) * 0.5 + 0.5,
      cos(v_position.y * 2.0 + u_time * 1.5) * 0.5 + 0.5,
      sin(v_position.z * 2.0 + u_time * 0.8) * 0.5 + 0.5
    );
    color = mix(color, shift, u_entropy * 0.15);

    // Emissive glow: particle burns with its own light
    color += color * v_emissive * 2.0;

    gl_FragColor = vec4(color, v_opacity);
  }
`;

export const FRAGMENT_SHADER_FLAT = /* glsl */`
  precision highp float;

  varying float v_opacity;
  varying vec3  v_color;

  void main() {
    gl_FragColor = vec4(v_color, v_opacity);
  }
`;

export class EntropyShader {
  constructor(config = {}) {
    this.displacementScale = config.displacementScale ?? 0.3;
    this.colorVariance     = config.colorVariance     ?? 0.2;
    this.animationSpeed    = config.animationSpeed    ?? 1.0;
  }

  vertexShader()   { return VERTEX_SHADER; }
  fragmentShader() { return FRAGMENT_SHADER_EMISSIVE; }
}
```

### Step 4.2 — Write the Three.js backend

Replace the entire contents of `RaBbLE-NeBuLA/src/backends/threejs-backend.js` with:

```js
import { Renderer } from './renderer.js';
import { VERTEX_SHADER, FRAGMENT_SHADER_EMISSIVE, FRAGMENT_SHADER_FLAT } from '../effects/entropy-shader.js';
import { resolvePalette } from '../puppet/palette.js';

const GEOMETRY_TYPES = ['sphere', 'box', 'tetrahedron'];
const MAX_INSTANCES = 2000;

export class ThreeJsBackend extends Renderer {
  /**
   * @param {HTMLCanvasElement} canvas
   * @param {object} THREE - the Three.js global (window.THREE or imported namespace)
   */
  constructor(canvas, THREE) {
    super();
    if (!THREE) throw new Error('ThreeJsBackend requires THREE as second argument');
    this._THREE = THREE;
    this._canvas = canvas;
    this._palette = resolvePalette();
    this._fps = 0;
    this._frameCount = 0;
    this._lastFpsTime = performance.now();
    this._drawCalls = 0;
    this._startTime = performance.now();

    this._init();
  }

  _init() {
    const T = this._THREE;

    this._renderer = new T.WebGLRenderer({
      canvas: this._canvas,
      antialias: true,
      alpha: true,
    });
    this._renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this._renderer.setSize(this._canvas.clientWidth, this._canvas.clientHeight, false);
    this._renderer.setClearColor(0x000000, 0);

    this._scene = new T.Scene();

    this._camera = new T.PerspectiveCamera(75, this._canvas.clientWidth / this._canvas.clientHeight, 0.1, 1000);
    this._camera.position.set(0, 0, 6);
    this._camera.lookAt(0, 0, 0);

    // Shader uniforms — updated every frame
    this._uniforms = {
      u_time:    { value: 0 },
      u_entropy: { value: 0.5 },
    };

    // Emissive material: additive blending, glow effect
    this._matEmissive = new T.ShaderMaterial({
      uniforms:       this._uniforms,
      vertexShader:   VERTEX_SHADER,
      fragmentShader: FRAGMENT_SHADER_EMISSIVE,
      transparent:    true,
      blending:       T.AdditiveBlending,
      depthWrite:     false,
    });

    // Flat material: opaque, no glow
    this._matFlat = new T.ShaderMaterial({
      uniforms:       this._uniforms,
      vertexShader:   VERTEX_SHADER,
      fragmentShader: FRAGMENT_SHADER_FLAT,
      transparent:    true,
      depthWrite:     true,
    });

    this._meshes = new Map();
    this._instanceData = new Map();
    this._buildGeometries();
  }

  _buildGeometries() {
    const T = this._THREE;
    const geomMap = {
      sphere:      new T.SphereGeometry(0.5, 8, 6),
      box:         new T.BoxGeometry(0.8, 0.8, 0.8),
      tetrahedron: new T.TetrahedronGeometry(0.6),
    };

    for (const [name, geom] of Object.entries(geomMap)) {
      // Per-instance attributes
      const entropy  = new Float32Array(MAX_INSTANCES);
      const size     = new Float32Array(MAX_INSTANCES).fill(1);
      const opacity  = new Float32Array(MAX_INSTANCES).fill(1);
      const emissive = new Float32Array(MAX_INSTANCES).fill(0.5);
      const color    = new Float32Array(MAX_INSTANCES * 3);

      // Set default color from palette
      const [r, g, b] = this._hexToRgb(this._defaultColor(name));
      for (let i = 0; i < MAX_INSTANCES; i++) {
        color[i * 3]     = r;
        color[i * 3 + 1] = g;
        color[i * 3 + 2] = b;
      }

      geom.setAttribute('instanceEntropy', new this._THREE.InstancedBufferAttribute(entropy,  1));
      geom.setAttribute('instanceSize',    new this._THREE.InstancedBufferAttribute(size,     1));
      geom.setAttribute('instanceOpacity', new this._THREE.InstancedBufferAttribute(opacity,  1));
      geom.setAttribute('instanceEmissive',new this._THREE.InstancedBufferAttribute(emissive, 1));
      geom.setAttribute('instanceColor',   new this._THREE.InstancedBufferAttribute(color,    3));

      const mesh = new this._THREE.InstancedMesh(geom, this._matEmissive, MAX_INSTANCES);
      mesh.count = 0;
      mesh.frustumCulled = false;
      this._scene.add(mesh);
      this._meshes.set(name, mesh);
      this._instanceData.set(name, { entropy, size, opacity, emissive, color });
    }
  }

  /**
   * @param {import('../core/stream.js').Stream[]} streams
   */
  render(streams) {
    const T = this._THREE;
    const now = (performance.now() - this._startTime) / 1000;
    this._uniforms.u_time.value = now;

    // Reset instance counts
    for (const [, mesh] of this._meshes) mesh.count = 0;

    // Reset per-geometry counters
    const counters = new Map(GEOMETRY_TYPES.map(g => [g, 0]));

    // Collect average entropy for u_entropy uniform
    let totalEntropy = 0;
    let entityCount = 0;

    const mat4 = new T.Matrix4();

    for (const stream of streams) {
      for (const entity of stream.getAll()) {
        if (!entity.active) continue;

        const geomKey = GEOMETRY_TYPES.includes(entity.geometry) ? entity.geometry : 'sphere';
        const mesh = this._meshes.get(geomKey);
        const data = this._instanceData.get(geomKey);
        const idx  = counters.get(geomKey);
        if (idx >= MAX_INSTANCES) continue;

        // Build transform matrix from position/rotation/scale
        const [px, py, pz] = entity.position ?? [0, 0, 0];
        const [rx, ry, rz] = entity.rotation ?? [0, 0, 0];
        const [sx, sy, sz] = entity.scale    ?? [1, 1, 1];

        mat4.makeRotationFromEuler(new T.Euler(rx, ry, rz));
        mat4.setPosition(px, py, pz);
        // Apply scale manually
        mat4.elements[0] *= sx; mat4.elements[1] *= sx; mat4.elements[2] *= sx;
        mat4.elements[4] *= sy; mat4.elements[5] *= sy; mat4.elements[6] *= sy;
        mat4.elements[8] *= sz; mat4.elements[9] *= sz; mat4.elements[10] *= sz;

        mesh.setMatrixAt(idx, mat4);

        data.entropy[idx]  = entity.entropy ?? 0.5;
        data.size[idx]     = entity.properties?.size ?? 1;
        data.opacity[idx]  = entity.opacity ?? 1;
        data.emissive[idx] = entity.properties?.emissive ?? 0.5;

        if (entity.color) {
          data.color[idx * 3]     = entity.color[0];
          data.color[idx * 3 + 1] = entity.color[1];
          data.color[idx * 3 + 2] = entity.color[2];
        }

        counters.set(geomKey, idx + 1);
        mesh.count = idx + 1;

        totalEntropy += entity.entropy ?? 0.5;
        entityCount++;
      }
    }

    this._uniforms.u_entropy.value = entityCount > 0 ? totalEntropy / entityCount : 0.5;

    // Mark instance attributes dirty
    for (const [, mesh] of this._meshes) {
      mesh.instanceMatrix.needsUpdate = true;
      const geom = mesh.geometry;
      for (const attr of ['instanceEntropy','instanceSize','instanceOpacity','instanceEmissive','instanceColor']) {
        if (geom.attributes[attr]) geom.attributes[attr].needsUpdate = true;
      }
    }

    this._renderer.render(this._scene, this._camera);
    this._drawCalls = this._meshes.size;

    // FPS
    this._frameCount++;
    const elapsed = performance.now() - this._lastFpsTime;
    if (elapsed >= 1000) {
      this._fps = Math.round(this._frameCount * 1000 / elapsed);
      this._frameCount = 0;
      this._lastFpsTime = performance.now();
    }
  }

  resize() {
    const w = this._canvas.clientWidth;
    const h = this._canvas.clientHeight;
    this._camera.aspect = w / h;
    this._camera.updateProjectionMatrix();
    this._renderer.setSize(w, h, false);
  }

  dispose() {
    this._renderer.dispose();
    for (const [, mesh] of this._meshes) {
      mesh.geometry.dispose();
    }
    this._matEmissive.dispose();
    this._matFlat.dispose();
  }

  getPerformanceMetrics() {
    return { fps: this._fps, frameTime: this._fps > 0 ? 1000 / this._fps : 0, drawCalls: this._drawCalls, triangles: 0 };
  }

  /** @param {string} geomName @returns {string} css color */
  _defaultColor(geomName) {
    const p = this._palette;
    return geomName === 'sphere' ? p.cyan : geomName === 'box' ? p.magenta : p.violet;
  }

  /** @param {string} hex @returns {[number,number,number]} 0-1 range */
  _hexToRgb(hex) {
    const n = parseInt(hex.replace('#',''), 16);
    return [(n >> 16 & 255) / 255, (n >> 8 & 255) / 255, (n & 255) / 255];
  }
}
```

### Step 4.3 — Update the main exports

Edit `RaBbLE-NeBuLA/src/effects/index.js` to export the new shader constants:

```js
export * from './entropy-shader.js';
export { VERTEX_SHADER, FRAGMENT_SHADER_EMISSIVE, FRAGMENT_SHADER_FLAT } from './entropy-shader.js';
```

### Step 4.4 — Verify Three.js backend in a browser

Add a Three.js test page at `RaBbLE-NeBuLA/examples/threejs-scene.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>NeBuLA — Three.js Scene</title>
  <style>
    body { background: #0a0010; margin: 0; }
    canvas { display: block; width: 100vw; height: 100vh; }
    #stats { position: fixed; top: 8px; left: 8px; color: #00f5ff; font-family: monospace; font-size: 12px; }
  </style>
</head>
<body>
  <canvas id="stage"></canvas>
  <div id="stats">loading...</div>
  <!-- Load Three.js first (peer dep) -->
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  <script type="module">
    import { Runtime, ThreeJsBackend, createEntity } from '../src/index.js';

    const canvas = document.getElementById('stage');
    canvas.width  = window.innerWidth;
    canvas.height = window.innerHeight;

    // Pass window.THREE — not imported
    const runtime = new Runtime(canvas);
    runtime.backend = new ThreeJsBackend(canvas, window.THREE);

    const stream = runtime.createStream('particles');

    // 1000 sphere entities in a spherical distribution (galaxy-like)
    for (let i = 0; i < 1000; i++) {
      const r     = Math.random() * 3;
      const theta = Math.random() * Math.PI * 2;
      const phi   = Math.acos(2 * Math.random() - 1);
      stream.add(createEntity('sphere',
        [r * Math.sin(phi) * Math.cos(theta), r * Math.sin(phi) * Math.sin(theta), r * Math.cos(phi)],
        Math.random()
      ));
    }

    runtime.on('frame', () => {
      const s = runtime.getStats();
      document.getElementById('stats').textContent =
        `fps: ${s.fps.toFixed(0)} | entities: ${s.totalEntities} | entropy: ${s.averageEntropy.toFixed(2)}`;
    });

    runtime.start();
  </script>
</body>
</html>
```

Open in a browser. You should see 1000 glowing sphere particles in a spherical cloud, `fps` at or near 60, no console errors.

**Done when:** 1000 entities render, FPS ≥ 55, emissive glow visible, shader entropy jitter visible as particles shimmer.

---

## Phase 5 — Animation System

**Goal:** `AnimationMixer` transitions entity entropy between named states smoothly.

### Step 5.1 — Create animation.js

Create `RaBbLE-NeBuLA/src/core/animation.js`:

```js
const STATE_ENTROPY = { idle: 0.3, thinking: 0.6, speaking: 0.8 };

export class AnimationMixer {
  constructor() {
    /** @type {Map<string, {stream: import('./stream.js').Stream, target: number, duration: number, elapsed: number, startValues: number[]}>} */
    this._transitions = new Map();
  }

  /**
   * Start a smooth entropy transition for all entities in a stream.
   * @param {import('./stream.js').Stream} stream
   * @param {'idle'|'thinking'|'speaking'|number} toState - named state or direct entropy 0.0-1.0
   * @param {number} durationMs
   */
  transition(stream, toState, durationMs = 800) {
    const target = typeof toState === 'number' ? toState : (STATE_ENTROPY[toState] ?? 0.3);
    const entities = stream.getAll();
    this._transitions.set(stream, {
      stream,
      target,
      duration: durationMs,
      elapsed: 0,
      startValues: entities.map(e => e.entropy),
    });
  }

  /**
   * Call this every frame from Runtime's 'frame' event.
   * @param {number} deltaMs - milliseconds since last frame
   */
  update(deltaMs) {
    for (const [stream, tx] of this._transitions) {
      tx.elapsed += deltaMs;
      const t = Math.min(tx.elapsed / tx.duration, 1);
      const eased = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t; // ease-in-out quad

      const entities = stream.getAll();
      for (let i = 0; i < entities.length; i++) {
        const start = tx.startValues[i] ?? 0.5;
        entities[i].entropy = start + (tx.target - start) * eased;
      }

      if (t >= 1) this._transitions.delete(stream);
    }
  }
}
```

### Step 5.2 — Wire AnimationMixer into Runtime

Edit `RaBbLE-NeBuLA/src/core/runtime.js`. Add the `AnimationMixer` import at the top:

```js
import { AnimationMixer } from './animation.js';
```

In the `constructor`, add after `this._handlers = new Map();`:

```js
this.animator = new AnimationMixer();
```

In the `_loop` method, add before `this._emit('frame', timestamp)`:

```js
this.animator.update(this._frameTime);
```

### Step 5.3 — Export AnimationMixer from core index

Edit `RaBbLE-NeBuLA/src/core/index.js` and add:

```js
export { AnimationMixer } from './animation.js';
```

**Done when:** You can call `runtime.animator.transition(stream, 'speaking', 1000)` and watch entity glow intensify over one second.

---

## Phase 6 — Visual Puppet Layer

**Goal:** Extract the entity visual puppet (eyes, particles, boot, saccade) from World's monolith into NeBuLA. World's monolith stays running until Phase 7 replaces it.

> **Critical rule:** Do NOT delete or disable `RaBbLE-World/world/js/RaBbLE-NeBuLA.js` during this phase. The extraction happens in NeBuLA first; World integration happens in Phase 7.

### Step 6.1 — Read the World monolith first

Before writing anything, read `RaBbLE-World/world/js/RaBbLE-NeBuLA.js` fully. Identify:
- The `RaBbLEEntityRenderer` class and its constructor options
- The boot sequence timeline constants (T_EYES_START, T_PORTALS_START, etc.)
- The saccade table (20 predefined look positions)
- The blink state machine (states 0–3)
- Particle physics (target positions, convergence easing)
- How `setEntityState` changes behavior
- How `injectEyeJolt` affects the saccade

### Step 6.2 — Create the puppet directory structure

```
RaBbLE-NeBuLA/src/puppet/
  palette.js         ← already created in Phase 2
  index.js           ← main export (createPuppet factory)
  eye-controller.js  ← saccade + blink logic
  boot-sequence.js   ← boot timeline state machine
  state-mapper.js    ← entity state → entropy mapping + AnimationMixer calls
```

### Step 6.3 — Write eye-controller.js

Create `RaBbLE-NeBuLA/src/puppet/eye-controller.js`. Port the saccade table, blink state machine, mouse tracking, and `injectJolt` from World's monolith. The key behaviors to preserve:

- 20 saccade target positions with hardness levels (hard/med/soft)
- Two-frequency drift superposition: X (2.6Hz + 1.1Hz), Y (1.8Hz + 0.9Hz)
- Mouse tracking within 600px
- Distraction: random gaze breaks every 120–300 frames
- Blink: state 0→1 (slow-open) → state 2 (burst, 5 blinks with 8-frame gaps) → state 3 (settled idle)
- `injectJolt(dx, dy)` temporarily overrides the saccade target

Export: `class EyeController { constructor(options); update(deltaMs, mouseX, mouseY); getEyeState(); injectJolt(dx, dy); }`

### Step 6.4 — Write boot-sequence.js

Create `RaBbLE-NeBuLA/src/puppet/boot-sequence.js`. Port the boot timeline from the monolith:

```js
// Timeline constants — match RaBbLE-World monolith exactly
const T_CONVERGE_END   = 2800;  // ms: particles reach cluster
const T_PORTALS_START  =  400;  // ms
const T_PORTALS_END    = 2600;  // ms
const T_EYES_START     = 1400;  // ms
const T_EYES_OPEN      = 2600;  // ms
const T_EYES_FULL      = 3200;  // ms — onReady fires here

export class BootSequence {
  constructor(onReady) { /* ... */ }
  update(elapsedMs) { /* return { particleAlpha, eyeAlpha, portalAlpha, done } */ }
}
```

### Step 6.5 — Write state-mapper.js

Create `RaBbLE-NeBuLA/src/puppet/state-mapper.js`:

```js
import { AnimationMixer } from '../core/animation.js';

const STATE_MAP = { idle: 0.3, thinking: 0.6, speaking: 0.8 };

export class StateMapper {
  constructor(stream, animator) {
    this._stream   = stream;
    this._animator = animator;
    this._state    = 'idle';
  }

  setState(state) {
    if (state === this._state) return;
    this._state = state;
    this._animator.transition(this._stream, STATE_MAP[state] ?? 0.3, 800);
  }

  getState() { return this._state; }
}
```

### Step 6.6 — Write puppet/index.js

Create `RaBbLE-NeBuLA/src/puppet/index.js`:

```js
import { Runtime } from '../core/runtime.js';
import { Canvas2dBackend } from '../backends/canvas2d-backend.js';
import { createEntity } from '../core/entity.js';
import { EyeController } from './eye-controller.js';
import { BootSequence } from './boot-sequence.js';
import { StateMapper } from './state-mapper.js';
import { resolvePalette } from './palette.js';

/**
 * Create the RaBbLE Visual Puppet on a canvas element.
 *
 * @param {{ canvas: HTMLCanvasElement, particleCount?: number, overscan?: number, THREE?: object, backend?: 'auto'|'canvas2d'|'threejs', onReady?: Function }} options
 * @returns {{ setEntityState, injectEyeJolt, resize, destroy }}
 */
export function createPuppet(options = {}) {
  const {
    canvas,
    particleCount = 480,
    overscan      = 2.55,
    THREE         = null,
    backend       = 'auto',
    onReady       = () => {},
  } = options;

  const palette = resolvePalette();
  const runtime = new Runtime(canvas);

  // Backend selection: Three.js if available and requested, else Canvas2D
  const useThree = backend === 'threejs' || (backend === 'auto' && THREE && window.devicePixelRatio >= 1);
  if (useThree && THREE) {
    const { ThreeJsBackend } = await import('../backends/threejs-backend.js'); // dynamic to keep Canvas2D path light
    runtime.backend = new ThreeJsBackend(canvas, THREE);
  } else {
    runtime.backend = new Canvas2dBackend(canvas);
  }

  // Create particle stream
  const stream = runtime.createStream('nebula');
  _seedParticles(stream, particleCount, palette);

  const stateMapper = new StateMapper(stream, runtime.animator);
  const eyeCtrl     = new EyeController({ palette });
  const boot        = new BootSequence(() => onReady());

  let mouseX = 0, mouseY = 0;
  const _onMouseMove = (e) => { mouseX = e.clientX; mouseY = e.clientY; };
  document.addEventListener('mousemove', _onMouseMove);

  runtime.on('frame', (timestamp) => {
    const delta = runtime._frameTime;
    boot.update(timestamp);
    eyeCtrl.update(delta, mouseX, mouseY);
    // Eye and particle state drawn by backend via stream
  });

  runtime.start();

  return {
    setEntityState(state) { stateMapper.setState(state); },
    injectEyeJolt(dx, dy) { eyeCtrl.injectJolt(dx, dy); },
    resize() { runtime.backend?.resize(); },
    destroy() {
      runtime.stop();
      document.removeEventListener('mousemove', _onMouseMove);
      runtime.backend?.dispose();
    },
  };
}

/** Seed the nebula stream with particles in a spherical distribution */
function _seedParticles(stream, count, palette) {
  for (let i = 0; i < count; i++) {
    const r     = (Math.random() * 0.7 + 0.3) * 1.3;
    const theta = Math.random() * Math.PI * 2;
    const phi   = Math.acos(2 * Math.random() - 1);
    stream.add(createEntity(
      'sphere',
      [r * Math.sin(phi) * Math.cos(theta), r * Math.sin(phi) * Math.sin(theta), r * Math.cos(phi)],
      Math.random() * 0.4 + 0.1
    ));
  }
}
```

> **Note:** The dynamic import for ThreeJsBackend inside createPuppet uses `await`, which means `createPuppet` must be `async` OR the dynamic import must be hoisted. Simplest fix: make `createPuppet` return a Promise and have callers `await` it. OR pre-import both backends and select at runtime. Choose whichever matches the monolith's current behavior.

### Step 6.7 — Export puppet from main index

Add to `RaBbLE-NeBuLA/src/index.js`:

```js
export { createPuppet } from './puppet/index.js';
```

**Done when:** You can call `createPuppet({ canvas, particleCount: 480 })` and see a particle cloud on the canvas, no errors.

---

## Phase 7 — World Integration

**Goal:** World loads NeBuLA as a script tag. The `<rabble-entity>` custom element delegates to `createPuppet`. The monolith is replaced. Visual output must be pixel-identical to before.

> **Safety rule:** Before touching World's files, do a `git add -A && git commit` in `RaBbLE-World/` to snapshot the working state. Label it `pre-nebula-integration`. This is your rollback point.

### Step 7.1 — Build NeBuLA

In `RaBbLE-NeBuLA/`:

```bash
npm run build
```

Copy the output to World:

```bash
cp dist/nebula.iife.js ../RaBbLE-World/world/js/nebula.iife.js
cp dist/nebula.esm.js  ../RaBbLE-World/world/js/nebula.esm.js
```

Or symlink during development:
```bash
ln -sf ../../../RaBbLE-NeBuLA/dist/nebula.iife.js RaBbLE-World/world/js/nebula.iife.js
```

### Step 7.2 — Update World's HTML to load Three.js + NeBuLA

In `RaBbLE-World/index.html`, before the closing `</body>` tag, add:

```html
<!-- Three.js (NeBuLA peer dep) -->
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<!-- NeBuLA rendering engine — sets window.NeBuLA -->
<script src="/world/js/nebula.iife.js"></script>
```

Do the same in `world/RaBbLE-Chat.html` and `world/RaBbLE-Boot.html`.

### Step 7.3 — Replace the monolith

The current `world/js/RaBbLE-NeBuLA.js` (663 lines) becomes a ~50-line adapter.

**First:** Rename the monolith to `world/js/RaBbLE-NeBuLA.legacy.js` as a backup.

**Then:** Create a new `world/js/RaBbLE-NeBuLA.js` with only this content:

```js
// NeBuLA adapter — delegates to the NeBuLA engine loaded via script tag (window.NeBuLA)
// The <rabble-entity> custom element API is unchanged.

class RaBbLEEntityElement extends HTMLElement {
  connectedCallback() {
    const particleCount = parseInt(this.getAttribute('particle-count') || '480');
    const overscan      = parseFloat(this.getAttribute('overscan') || '2.55');
    const mode          = this.getAttribute('mode') || 'idle';

    // Internal canvas — sized with overscan for glow bleed
    const canvas = document.createElement('canvas');
    const w = this.offsetWidth  || 300;
    const h = this.offsetHeight || 300;
    canvas.width  = Math.round(w * overscan);
    canvas.height = Math.round(h * overscan);
    canvas.style.cssText = `position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);`;
    this.style.position = 'relative';
    this.style.overflow = 'hidden';
    this.appendChild(canvas);

    const engine = window.NeBuLA;
    if (!engine || !engine.createPuppet) {
      console.error('NeBuLA not loaded — ensure nebula.iife.js is included before this element');
      return;
    }

    this._puppet = engine.createPuppet({
      canvas,
      particleCount,
      overscan,
      THREE: window.THREE || null,
      backend: 'auto',
      onReady: () => {
        this.dispatchEvent(new CustomEvent('rabble:entity-ready', { bubbles: true }));
        if (window.NeBuLA) {
          window.NeBuLA._instance  = this._puppet;
          window.NeBuLA.backend    = this._puppet.getBackendName?.() || 'Canvas2D';
          window.NeBuLA.particleCount = particleCount;
        }
      },
    });

    if (mode !== 'boot') this._puppet.setEntityState(mode);
  }

  setEntityState(state)     { this._puppet?.setEntityState(state); }
  injectEyeJolt(dx, dy)     { this._puppet?.injectEyeJolt(dx, dy); }

  disconnectedCallback()    { this._puppet?.destroy(); }
}

customElements.define('rabble-entity', RaBbLEEntityElement);
```

### Step 7.4 — Smoke test

Open World in a browser. Verify:
- [ ] Entity boots: particles converge, portal arcs appear, eyes emerge
- [ ] Status bar shows backend name and particle count
- [ ] `setEntityState('thinking')` changes glow intensity
- [ ] Mouse move makes eyes track
- [ ] No console errors
- [ ] Mobile: Canvas2D backend selected (no WebGL fallback needed on old phones)

If any step fails, roll back to `RaBbLE-NeBuLA.legacy.js` via the pre-integration commit and debug NeBuLA in isolation.

**Done when:** All smoke test items pass. Delete `.legacy.js` file after two stable sessions.

---

## Phase 8 — NeBuLA Studio

**Goal:** A developer tool at `/world/RaBbLE-Studio.html` for authoring entity expressions and testing rendering backends.

> Do not start Phase 8 until Phase 7 is live and stable in production.

### Step 8.1 — Create Studio HTML

Create `RaBbLE-World/world/RaBbLE-Studio.html`. Use the Tiling WM with three applets:
- **Left:** Expression library + state controls
- **Center:** Live entity preview (full `<rabble-entity>`)
- **Right:** Sliders and performance overlay

Use the same Aether CSS (`/aether/rabble.css`), theme bridge (`world/css/RaBbLE-theme.css`), and WM CSS (`world/css/RaBbLE-wm.css`) as the landing page.

### Step 8.2 — Studio features checklist

Implement these in `world/js/RaBbLE-Studio.js`:

- [ ] Three state buttons: idle / thinking / speaking — each calls `entity.setEntityState()`
- [ ] Entropy range input (0.0–1.0) — directly sets `stream.transform(e => { e.entropy = value; return e; })`
- [ ] Pattern selector (organic / lattice / swarm / galaxy) — recreates the nebula stream using `PatternGenerator`
- [ ] Backend toggle (Canvas2D / Three.js) — destroys and recreates the puppet with the other backend
- [ ] FPS/entity/entropy overlay — reads from `NeBuLA._instance?.getStats()` every 500ms
- [ ] Expression JSON editor: textarea + "Export" button that copies `JSON.stringify({ state, entropy, label })` to clipboard

### Step 8.3 — Wire Studio into World navigation

In `index.html`, add a Studio link in the nav/waybar area. Studio should not be in the main WM flow — it's a developer tool accessed from the status bar or a keyboard shortcut.

---

## Build and Release Checklist

After all phases complete, before tagging `episode-1` on `RaBbLE-NeBuLA/main`:

- [ ] `npm run build` completes without errors
- [ ] `dist/nebula.iife.js` is under 100KB minified (without Three.js)
- [ ] `dist/nebula.esm.js` exists and tree-shakes correctly (import only `Canvas2dBackend` → Three.js code is excluded)
- [ ] `examples/basic-scene.html` works (Canvas2D)
- [ ] `examples/threejs-scene.html` works (Three.js, 1000 entities ≥ 55 FPS)
- [ ] No raw hex strings outside `src/puppet/palette.js`
- [ ] No RBCNS naming (`q_`, `e_`, `f_` prefixes) anywhere in `src/`
- [ ] `RaBbLE-World` landing page entity boots correctly using the new adapter
- [ ] Commit Grimoire updates to `RaBbLE-Grimoire/` with episode status updated to `Ep1 complete`

---

## Commit Style Reference

All commits follow the Pulse Protocol: `[impulse] ~ [organ] >> [revelation] // %SYSTEM_STATE%`

Example commits for this work:
```
spark ~ nebula >> build system added, iife and esm targets // %BUILD_WIRED%
spark ~ nebula >> canvas2d backend implemented, entities render // %CANVAS_LIVE%
spark ~ nebula >> threejs backend and entropy shaders // %THREE_LIVE%
spark ~ nebula >> animation mixer, state transitions smooth // %ANIMATOR_LIVE%
spark ~ nebula >> visual puppet layer, boot sequence extracted // %PUPPET_LIVE%
harmonize ~ world >> nebula adapter replaces monolith // %WORLD_NEBULA_WIRED%
spark ~ world >> nebula studio, expression authoring // %STUDIO_LIVE%
```

---

## Phase 9 — Aether CSS Integration and Theme Bridge

**Goal:** NeBuLA reads all visual properties from Aether CSS variables. Aether provides the canonical theme layer; NeBuLA and World both consume it. No hardcoded colors anywhere.

### Step 9.1 — Create theme bridge stylesheet

Create `RaBbLE-NeBuLA/src/styles/aether-bridge.css`. This file is **not included in the bundle** — it's injected by pages that load both Aether and NeBuLA:

```css
/* Aether → NeBuLA Theme Bridge
 * These custom properties map Aether's design system to NeBuLA shader variables
 * Pages load this stylesheet BEFORE NeBuLA to establish CSS variables
 * Fallbacks only apply if Aether is not available
 */

:root {
  /* Palette — primary spectrum (from RaBbLE-Palette.md) */
  --rabble-magenta: #ff2d78;
  --rabble-cyan:    #00f5ff;
  --rabble-violet:  #bf5fff;
  --rabble-pink:    #ff79c6;
  
  /* Surfaces — UI background, layers */
  --rabble-bg:      #0a0010;
  --rabble-surface: #12132a;
  --rabble-text:    #e8e6f0;
  
  /* Opacity — entropy mapping (Canvas2D fallback) */
  --rabble-entropy-idle:     0.3;
  --rabble-entropy-thinking: 0.6;
  --rabble-entropy-speaking: 0.8;
  
  /* Animation — timings used by AnimationMixer and boot sequence */
  --rabble-transition-fast:  200ms;
  --rabble-transition-normal: 800ms;
  --rabble-transition-slow:  3200ms;
  
  /* NeBuLA-specific: glow intensity and blur curves */
  --rabble-glow-intensity: 1.0;
  --rabble-blur-entropy-scale: 18;
}
```

Save this as a reference. Pages will load Aether's equivalent, which Aether owns. NeBuLA's fallback hex values in `src/puppet/palette.js` match these.

### Step 9.2 — Update palette.js to support responsive scaling

Edit `RaBbLE-NeBuLA/src/puppet/palette.js` to add a responsive function:

```js
// ... existing palette code ...

/** Get a color multiplied by responsive scale factor (for glows on mobile) */
export function getScaledColor(name, scale = 1.0) {
  const color = PALETTE[name]();
  // Aether can set --rabble-glow-scale as a multiplier
  const glowScale = parseFloat(
    getComputedStyle(document.documentElement).getPropertyValue('--rabble-glow-scale') || '1.0'
  );
  // Return the color as-is; caller applies scale via opacity or filter
  return { hex: color, glowScale: glowScale * scale };
}

/** Responsive size curve: small screens get smaller particles */
export function getResponsiveSize(baseSize = 1.0) {
  const vmin = Math.min(window.innerWidth, window.innerHeight);
  // Scale particle size from 0.6x (mobile) to 1.0x (desktop)
  const factor = Math.max(0.6, Math.min(1.0, vmin / 500));
  return baseSize * factor;
}
```

### Step 9.3 — Aether provides component class names

Aether (in RaBbLE-Aether/) exports a CSS bundle with utility classes for sizing and spacing. NeBuLA-hosting pages use these classes:

```html
<!-- In RaBbLE-World/index.html or RaBbLE-Boot.html -->
<link rel="stylesheet" href="/aether/rabble.css">
<link rel="stylesheet" href="/world/css/theme-bridge.css">

<!-- rabble-entity uses the 'entity-viewport' utility for responsive sizing -->
<rabble-entity class="entity-viewport entity-hd" particle-count="480"></rabble-entity>
```

Aether provides classes:
- `.entity-viewport` — constrains canvas to responsive box
- `.entity-hd` / `.entity-sd` — high-def (threejs) vs standard-def (canvas2d)
- `.entity-portrait` / `.entity-landscape` — responsive orientation

### Step 9.4 — Create responsive canvas sizing

Update `RaBbLE-NeBuLA/src/puppet/index.js` `createPuppet` function to handle responsive sizing:

Replace the canvas sizing logic with:

```js
export function createPuppet(options = {}) {
  const {
    canvas,
    particleCount = 480,
    overscan      = 2.55,
    THREE         = null,
    backend       = 'auto',
    onReady       = () => {},
  } = options;

  // Detect if canvas is in a responsive container (check parent's data attribute or class)
  const isResponsive = canvas.parentElement?.classList.contains('entity-viewport') ?? false;
  
  // Handle responsive sizing
  if (isResponsive) {
    const updateCanvasSize = () => {
      const rect = canvas.parentElement.getBoundingClientRect();
      const w = rect.width || 300;
      const h = rect.height || 300;
      canvas.width  = Math.round(w * overscan);
      canvas.height = Math.round(h * overscan);
      runtime.backend?.resize?.();
    };
    
    updateCanvasSize();
    window.addEventListener('resize', updateCanvasSize);
    
    // cleanup in destroy
    const originalDestroy = destroyFn;
    destroyFn = () => {
      window.removeEventListener('resize', updateCanvasSize);
      originalDestroy();
    };
  } else {
    // Static sizing for fixed-size containers
    const w = canvas.width  || 300;
    const h = canvas.height || 300;
    canvas.width  = Math.round(w * overscan);
    canvas.height = Math.round(h * overscan);
  }
  
  // ... rest of createPuppet ...
}
```

**Done when:** Canvas resizes on window resize. No flickering. Particle count adjusts particle density (fewer particles on small screens if desired via particleCount prop).

---

## Phase 10 — Responsive Rendering & Mobile Optimization

**Goal:** NeBuLA renders efficiently on all screen sizes. Canvas2D on mobile. Three.js on desktop. Particle count adapts intelligently.

### Step 10.1 — Smart backend selection based on device

Update backend auto-selection in `createPuppet`:

```js
function selectBackend(options) {
  const { THREE, backend, canvas } = options;
  
  if (backend !== 'auto') return backend; // explicit choice
  
  // Device capability detection
  const isMobile = /android|iphone|ipad|mobile/i.test(navigator.userAgent);
  const isLowPower = navigator.deviceMemory ? navigator.deviceMemory <= 4 : false;
  const canWebGL = !!canvas.getContext('webgl2');
  
  // Mobile or low-power → Canvas2D
  if (isMobile || isLowPower || !canWebGL) return 'canvas2d';
  
  // Desktop with Three.js available → Three.js
  if (THREE && window.devicePixelRatio >= 1.5) return 'threejs';
  
  // Default fallback
  return 'canvas2d';
}
```

### Step 10.2 — Adaptive particle count

In `createPuppet`, detect screen size and adjust particle density:

```js
function getAdaptiveParticleCount(baseCount, canvas) {
  const pixelRatio = window.devicePixelRatio || 1;
  const screenArea = window.innerWidth * window.innerHeight;
  
  // Mobile (< 1M pixels) → 30% of particles
  if (screenArea < 1_000_000) return Math.floor(baseCount * 0.3);
  
  // Tablet (< 3M pixels) → 60% of particles
  if (screenArea < 3_000_000) return Math.floor(baseCount * 0.6);
  
  // Desktop → 100% of particles
  return baseCount;
}
```

### Step 10.3 — Test on mobile breakpoints

Create `RaBbLE-World/world/RaBbLE-Boot.html` test page with viewport meta and responsive checks:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <title>RaBbLE Boot — Responsive Test</title>
  <link rel="stylesheet" href="/aether/rabble.css">
  <style>
    body { margin: 0; background: var(--rabble-bg); display: flex; align-items: center; justify-content: center; height: 100vh; }
    .entity-viewport { width: 80vw; max-width: 600px; aspect-ratio: 1; position: relative; }
  </style>
</head>
<body>
  <rabble-entity class="entity-viewport entity-hd"></rabble-entity>
  
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  <script src="/world/js/nebula.iife.js"></script>
  <script src="/world/js/RaBbLE-NeBuLA.js"></script>
</body>
</html>
```

Test on:
- [ ] iPhone SE (375px) — Canvas2D, 100 particles
- [ ] iPad (768px) — Canvas2D or Three.js, 200 particles
- [ ] Desktop 1920px — Three.js, 480 particles

**Done when:** No errors on any device. Consistent visual appearance. Particle count/quality scales smoothly.

---

## Phase 11 — Aether CDN Distribution and Asset Versioning

**Goal:** Aether CSS is versioned and served from CDN. NeBuLA includes versioned asset references. Members import with version pinning.

### Step 11.1 — Aether build output structure

In `RaBbLE-Aether/`, the build produces:

```
dist/
  v0.0.0/
    rabble.css              ← main design system (components + utilities)
    theme-bridge.css        ← CSS variable overrides for specific contexts
    fonts/
      rabble-*.woff2        ← all web fonts
  latest/                   ← symlink to v0.0.0 during dev
  versions.json             ← metadata: { "latest": "v0.0.0", "stable": "v0.0.0" }
```

### Step 11.2 — Create asset registry in NeBuLA

Add `RaBbLE-NeBuLA/src/config/asset-registry.js`:

```js
/**
 * Asset registry — versioned references to CDN assets
 * Updated by CI/CD when Aether publishes a new version
 */

export const ASSETS = {
  // Aether CSS — theme layer
  aether: {
    version: '0.0.0',
    cdn: 'https://cdn.joinrabble.world/aether',
    css: '/rabble.css',
    themeBridge: '/theme-bridge.css',
  },
  
  // NeBuLA distribution
  nebula: {
    version: '0.0.0',
    cdn: 'https://cdn.joinrabble.world/nebula',
    iife: '/nebula.iife.js',
    esm: '/nebula.esm.js',
  },
  
  // Three.js peer dependency
  threejs: {
    version: '0.160.0',
    cdn: 'https://cdn.jsdelivr.net/npm/three@0.160.0',
    build: '/build/three.min.js',
  },
};

export function getCdnUrl(asset, file) {
  const entry = ASSETS[asset];
  return `${entry.cdn}/${entry.version}${entry[file]}`;
}
```

### Step 11.3 — HTML generation helper

Pages import Aether + NeBuLA like this:

```html
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/rabble.css">
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/theme-bridge.css">
<script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
<script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>
```

Create a template helper in `RaBbLE-World/spells/generate-html-head.sh`:

```bash
#!/bin/bash
# Generate <head> snippet with versioned asset links
# Usage: bash generate-html-head.sh > _head-snippet.html

AETHER_VERSION="0.0.0"
NEBULA_VERSION="0.0.0"
THREEJS_VERSION="0.160.0"

CDN_HOST="https://cdn.joinrabble.world"

cat <<EOF
<!-- Theme system (Aether CSS) -->
<link rel="stylesheet" href="$CDN_HOST/aether/v$AETHER_VERSION/rabble.css">
<link rel="stylesheet" href="$CDN_HOST/aether/v$AETHER_VERSION/theme-bridge.css">

<!-- 3D rendering engine dependencies -->
<script src="https://cdn.jsdelivr.net/npm/three@$THREEJS_VERSION/build/three.min.js"></script>

<!-- NeBuLA visual entity engine -->
<script src="$CDN_HOST/nebula/v$NEBULA_VERSION/nebula.iife.js"></script>
EOF
```

**Done when:** Versions are locked in both `rabble.css` and `nebula.iife.js`. CDN URLs don't have version in path (version is in CI/CD layer). Zero drift between local dev and CDN.

---

## Phase 12 — World Page Composition Using Aether + NeBuLA

**Goal:** World pages are composed from Aether components (form) + World CSS (function) + NeBuLA (animation). Pages are easy to create and maintain.

### Step 12.1 — Page layout patterns

All World pages follow this structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title</title>
  
  <!-- Aether CSS: design system + theme variables -->
  <link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/rabble.css">
  
  <!-- World CSS: functional overrides for this page -->
  <link rel="stylesheet" href="/world/css/page-name.css">
</head>
<body>
  <!-- Aether component classes + responsive utility classes -->
  <div class="page">
    <header class="navbar navbar-dark">
      <h1 class="title title-lg">RaBbLE</h1>
    </header>
    
    <main class="content">
      <!-- NeBuLA entity: renders using Canvas2D or Three.js -->
      <rabble-entity class="entity-viewport entity-hd" particle-count="480"></rabble-entity>
      
      <!-- Aether buttons, inputs, etc. for control -->
      <div class="button-group">
        <button class="btn btn-primary">Primary</button>
        <button class="btn btn-secondary">Secondary</button>
      </div>
    </main>
  </div>
  
  <!-- NeBuLA rendering engine -->
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  <script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>
  
  <!-- World-specific script (functional) -->
  <script src="/world/js/page-name.js" type="module"></script>
</body>
</html>
```

### Step 12.2 — Aether component library mapping

Aether exports utility classes. World pages use them directly:

| Component | Aether Class | Form (Aether) | Function (World CSS) |
|---|---|---|---|
| Button | `.btn .btn-primary` | Color, padding, rounded corners | Hover state, click animation |
| Input | `.input .input-text` | Border, font size, padding | Focus state, validation styles |
| Card | `.card .card-flat` | Background, shadow, spacing | Grid layout, overflow behavior |
| Navbar | `.navbar .navbar-dark` | Colors, height, flex layout | Sticky behavior, z-index stacking |
| Entity Viewport | `.entity-viewport .entity-hd` | Aspect ratio, responsive sizing | Canvas width/height, overlay positioning |

### Step 12.3 — World CSS layer structure

Create `RaBbLE-World/world/css/` with:

```
css/
  _reset.css           ← normalize + baseline (Aether provides, World may override)
  _utilities.css       ← Aether utilities: spacing, sizing, alignment
  theme-bridge.css     ← CSS variables (injected by Aether, customized per page)
  
  page-index.css       ← functional overrides for / (landing)
  page-boot.css        ← functional overrides for /boot
  page-chat.css        ← functional overrides for /chat
  
  components.css       ← World-specific components (status bar, timeline, etc.)
  responsive.css       ← media queries (mobile-first, then tablet, desktop)
```

In each page CSS, import and override:

```css
/* page-index.css */
@import url('/aether/v0.0.0/rabble.css');
@import url('/world/css/_utilities.css');

/* World-specific functional styles */
.entity-viewport {
  /* Aether set: aspect-ratio, responsive sizing, border */
  /* World adds: grid positioning, animation timing, event handlers */
  position: relative;
  grid-column: 1 / 3;
}

.navbar {
  /* Aether: colors, flex layout, height */
  /* World: position: sticky, z-index, shadow transitions */
  position: sticky;
  top: 0;
  z-index: 100;
  transition: box-shadow 300ms ease;
}
```

### Step 12.4 — Responsive breakpoints (mobile-first)

Add to `RaBbLE-World/world/css/responsive.css`:

```css
/* Mobile baseline: 320px–767px */
.page { display: grid; grid-template-columns: 1fr; gap: 1rem; }
.entity-viewport { width: 100%; max-width: 90vw; }
.navbar { position: sticky; }

/* Tablet: 768px–1023px */
@media (min-width: 768px) {
  .page { grid-template-columns: 1fr 1fr; }
  .entity-viewport { grid-column: 1; }
}

/* Desktop: 1024px+ */
@media (min-width: 1024px) {
  .page { grid-template-columns: 1fr 2fr; }
  .entity-viewport { grid-column: 1 / 2; grid-row: 1 / 3; }
}
```

### Step 12.5 — Verify full stack integration

Create `RaBbLE-World/world/RaBbLE-Integrated.html` test page:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RaBbLE — Full Stack Test</title>
  <link rel="stylesheet" href="/aether/rabble.css">
  <style>
    body { margin: 0; background: var(--rabble-bg); color: var(--rabble-text); font-family: system-ui; }
    .container { display: grid; grid-template-columns: 1fr; gap: 2rem; padding: 2rem; }
    @media (min-width: 768px) { .container { grid-template-columns: 1fr 1fr; } }
    .entity-box { aspect-ratio: 1; position: relative; background: var(--rabble-surface); border-radius: 8px; }
    .button-group { display: flex; gap: 1rem; justify-content: center; margin-top: 2rem; }
    .btn { padding: 0.75rem 1.5rem; border: 1px solid var(--rabble-cyan); background: transparent; color: var(--rabble-cyan); border-radius: 4px; cursor: pointer; transition: all 200ms; }
    .btn:hover { background: var(--rabble-cyan); color: var(--rabble-bg); }
    h1 { text-align: center; color: var(--rabble-magenta); }
  </style>
</head>
<body>
  <h1>RaBbLE — Aether + NeBuLA + World</h1>
  
  <div class="container">
    <div class="entity-box">
      <rabble-entity particle-count="480"></rabble-entity>
    </div>
    
    <div class="controls">
      <p>Entity State:</p>
      <div class="button-group">
        <button class="btn" onclick="entity.setEntityState('idle')">Idle</button>
        <button class="btn" onclick="entity.setEntityState('thinking')">Thinking</button>
        <button class="btn" onclick="entity.setEntityState('speaking')">Speaking</button>
      </div>
      
      <p style="margin-top: 2rem;">Canvas Stats:</p>
      <pre id="stats" style="color: var(--rabble-cyan); font-size: 12px;"></pre>
    </div>
  </div>
  
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  <script src="/world/js/nebula.iife.js"></script>
  <script src="/world/js/RaBbLE-NeBuLA.js"></script>
  
  <script>
    const entity = document.querySelector('rabble-entity');
    const statsElem = document.getElementById('stats');
    
    setInterval(() => {
      const stats = window.NeBuLA?._instance?.getStats?.();
      if (stats) {
        statsElem.textContent = JSON.stringify(stats, null, 2);
      }
    }, 500);
  </script>
</body>
</html>
```

**Done when:**
- [ ] Page loads without console errors
- [ ] Entity renders and responds to state changes
- [ ] Buttons use Aether colors (no hardcoded hex)
- [ ] Responsive on mobile (320px) and desktop (1920px)
- [ ] Stats display updates every 500ms

---

## Phase 13 — Documentation: Aether + World Composition Guide

**Goal:** Future members understand how to create new World pages using Aether + NeBuLA without duplicating components or styles.

### Step 13.1 — Create composition guide

Write `RaBbLE-World/COMPOSITION.md`:

```markdown
# RaBbLE-World Page Composition Guide

## Three-Layer Stack

| Layer | Owner | Responsibility | Example |
|---|---|---|---|
| **Form** | Aether | Visual appearance, colors, typography, spacing | `.btn` button styles, colors from CSS variables |
| **Function** | World CSS | Interaction states, layout behaviors, animations | Button hover, navbar sticky positioning |
| **Animation** | NeBuLA | Entity rendering, particle dynamics, entropy states | `<rabble-entity>`, saccade, boot sequence |

## Creating a New Page

1. **Create HTML** in `/world/page-*.html` with semantic structure
2. **Import Aether CSS** in `<head>` with version pin
3. **Create World CSS** in `/world/css/page-*.css` for functional overrides
4. **Add `<rabble-entity>`** where animation is needed
5. **Test on mobile** (320px), tablet (768px), desktop (1920px)

## No Duplication Rule

- **Never copy Aether classes into World CSS** — import Aether's bundle
- **Never hardcode colors** — use Aether CSS variables (--rabble-magenta, etc.)
- **Never redefine components** — if Aether provides it, extend it, don't recreate
- **Never add animations to Aether** — Aether is form; NeBuLA is animation
```

### Step 13.2 — Update RaBbLE-World AGENT.md

Ensure `RaBbLE-World/AGENT.md` references the composition guide and Aether conventions.

**Done when:** A new contributor can read the guide and build a functioning page without asking questions.

---

## Phase 14 — Performance & Metrics Baseline

**Goal:** Establish performance metrics for NeBuLA across backends and devices. Establish targets for Episode 1.

### Step 14.1 — Create metrics collection script

In `RaBbLE-NeBuLA/spells/measure-perf.sh`:

```bash
#!/bin/bash
# Measure NeBuLA performance across backends and devices

echo "NeBuLA Performance Baseline — $(date)"
echo "Device: $(uname -m) | OS: $(uname -s) | Browser: $BROWSER_ENV"
echo ""

# Open examples in browser, measure FPS over 30 seconds
echo "Canvas2D (mobile baseline):"
# Point to examples/basic-scene.html
echo "- Load basic-scene.html"
echo "- Record average FPS over 30s"
echo "- Note: Should be 50+ FPS on mobile"
echo ""

echo "Three.js (desktop target):"
echo "- Load threejs-scene.html"
echo "- Record average FPS over 30s (1000 entities)"
echo "- Note: Should be 55+ FPS on desktop"
echo ""

echo "World landing page (production):"
echo "- Open https://joinrabble.world/"
echo "- Run: window.NeBuLA._instance?.getStats?.()"
echo "- Record backend, FPS, entity count"
```

### Step 14.2 — Establish targets

Document in `RaBbLE-NeBuLA/TARGETS.md`:

```markdown
# NeBuLA Performance Targets (Episode 1)

| Metric | Target | Platform | Notes |
|---|---|---|---|
| Canvas2D FPS | ≥50 | iOS/Android | 100 entities, 60Hz refresh |
| Three.js FPS | ≥55 | Desktop | 1000 entities, 60Hz refresh |
| Particle count | 480 | Desktop | Adjusts down on mobile |
| Shader entropy jitter | Visible | All | Particles shimmer smoothly |
| Boot sequence time | 3.2s | All | T_EYES_FULL = 3200ms |
| Entity state transition | 800ms | All | Smooth entropy easing |
| Bundle size | <100KB | All | minified, without Three.js |
| Time to interactive | <500ms | All | From page load to first render |
```

**Done when:** Baseline metrics are recorded. Targets are locked. Performance optimizations (if needed) are tracked as follow-up tasks.

---

## Build and Release Checklist — Updated

Before tagging Episode 1 on `RaBbLE-NeBuLA/main`:

- [ ] All phases 1–14 complete
- [ ] `npm run build` produces `dist/nebula.iife.js` (<100KB)
- [ ] `examples/basic-scene.html` works (Canvas2D, 50+ FPS)
- [ ] `examples/threejs-scene.html` works (Three.js, 1000 entities, 55+ FPS)
- [ ] Aether CSS variables are read dynamically (no hardcoded hex in NeBuLA code)
- [ ] World pages load Aether from CDN with version pins
- [ ] Responsive canvas sizing works on mobile (320px) and desktop (1920px)
- [ ] `RaBbLE-World/COMPOSITION.md` is written and verified
- [ ] Performance baselines recorded in `TARGETS.md`
- [ ] NeBuLA adapter (`world/js/RaBbLE-NeBuLA.js`) is <50 lines
- [ ] No raw hex strings outside `src/puppet/palette.js`
- [ ] No duplicate Aether classes in World CSS
- [ ] Commit Grimoire updates: member manifests, registry entries

---

## Commit Style Reference — Updated

Example commits for continued phases:

```
spark ~ aether >> css variables, theme bridge established // %THEME_WIRED%
spark ~ nebula >> responsive canvas sizing, mobile-first // %RESPONSIVE_LIVE%
spark ~ aether >> cdn distribution, asset registry // %CDN_VERSIONED%
harmonize ~ world >> page composition guide, three-layer stack // %COMPOSITION_LOCKED%
transcribe ~ nebula >> performance targets baseline // %TARGETS_LOCKED%
```

---

```
transcribe ~ grimoire >> NeBuLA plan expanded: Aether CDN + responsive + World composition (phases 9–14) // %NEBULA_PLAN_EXPANDED%
```
