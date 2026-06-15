# NeBuLA Performance Handoff — Post-Phase-5

> Created: 2026-06-08 (S54)
> Status: Three targeted fixes. Primary bottleneck is `ctx.filter` blur path — not JS compute.

---

## Context

Phases 1–5 of the NeBuLA rearchitecture are complete:

- **Phase 4:** Two-canvas split, GPU-composite glow, k-NN connections, physics throttle — field layer cost −85%
- **Phase 5:** `AmbientField` absorbed `RaBbLE-bg.js`; outrun grid baked offscreen; landing page runs one RAF loop

**Hardware target:** Ryzen AI 9 with RDNA3 integrated graphics. At 100–260 particles doing simple sinusoidal drift, pure JS compute should be sub-millisecond on this chip. If the entity is still stuttering, the bottleneck is NOT the JS math — it is the blur composite path.

---

## Issue 1 (PRIMARY) — `ctx.filter = 'blur()'` is Skia/software, not GPU-compositor

### Symptom
Entity stutters, CPU usage is higher than expected for the particle count. On a Ryzen AI 9 the particle JS should be essentially free.

### Root cause
Both `particle-system.js` and `ambient-field.js` use:

```js
ctx.filter = 'blur(8px)';
ctx.drawImage(glowCanvas, 0, 0);
ctx.filter = 'none';
```

`ctx.filter` in Canvas2D goes through Skia (Chrome's 2D rendering library), running on the **main JS thread**. Even with Skia's GPU backend (Ganesh/Dawn), the filter compositing happens as part of the main-thread paint pass — it competes directly with JS execution. On a 1920×1080 canvas this is a non-trivial operation every frame the glow buffer is composited.

CSS `filter: blur()` on a DOM **element** is handled by the browser's **compositor thread** — completely separate from JS. It never competes with the RAF loop and has zero main-thread cost.

### Fix — Switch to CSS element filter on the glow canvas

**For `AmbientField` (`src/effects/ambient-field.js`):**

1. Apply CSS filter to the glow canvas element itself rather than through the context:
   ```js
   // In constructor, after creating glowCv:
   this._glowCv.style.cssText =
     'position:fixed;inset:0;pointer-events:none;z-index:0;filter:blur(8px);';
   document.body.insertBefore(this._glowCv, this._cv);  // insert BEFORE main cv
   ```

2. Remove `ctx.filter` + `ctx.drawImage(glowCv)` from `_frame()` — the glow canvas composites via CSS automatically.

3. The main canvas sits on top of the glow canvas (z-index ordering); browser GPU composites both. Glow canvas is updated every GLOW_EVERY frames; flat canvas every frame. No main-thread blur cost.

**For `ParticleSystem` (`src/backends/canvas2d/particle-system.js`):**

Same approach — the `_glowCanvas` element gets `style.filter = 'blur(Npx)'` set on it. But this canvas is not in the DOM (it's offscreen) — for element-filter to work, the canvas must be in the DOM layer stack.

The cleanest fix for the entity: split the field canvas into two DOM canvases:
- `_fieldCanvas` — flat particles + connections (z-index 0, no filter)
- `_glowCanvas` — glow particles only, CSS `filter: blur(8px)` on the element (z-index between field and entity)

The entity canvas (`_canvas`, z-index 1) sits on top. Three stacked canvases, browser GPU composites all three. JS never pays for the blur.

**Element stack (bottom to top):**
```
_fieldCanvas   z-index:0  (flat particles + connections)
_glowCanvas    z-index:1  CSS filter:blur(8px)  (glow particles only)
_entityCanvas  z-index:2  (eyes + portals, always responsive)
```

The `element.js` custom element already creates two canvases and passes `fieldCanvas` to the backend. Add a third `glowCanvas` created in `element.js` and passed via opts.

**Files to change:**
- `src/element.js` — create third canvas (`glowCanvas`), CSS filter on it, pass to backend
- `src/backends/canvas2d/index.js` — accept `opts.glowCanvas`
- `src/backends/canvas2d/particle-system.js` — draw glow particles into element-filtered canvas each GLOW_EVERY frames; remove `ctx.filter` drawImage
- `src/effects/ambient-field.js` — add `_glowCv` as DOM element with CSS filter; remove `ctx.filter` drawImage

---

## Issue 2 — Particle Flicker: alpha desynced between flat draw and glow buffer

### Symptom
Glow particles flicker — they pulse at a different rate from non-glow particles.

### Root cause
`particle-system.js → _visibility()` line 127:

```js
const pulse = 0.62 + 0.38 * Math.sin(p.phase * 2 + t * 0.015);
```

`t` is the global frame counter, incremented every RAF frame. Glow buffer redraws every 2–4 frames. Between redraws, `t` advances but `p.phase` may not (physics throttle). The flat draw uses the current `t`; the glow buffer used the old `t` from its last redraw. The alpha mismatch is the flicker.

### Fix — Phase-only pulse (one line)

```js
// Before:
const pulse = 0.62 + 0.38 * Math.sin(p.phase * 2 + t * 0.015);

// After:
const pulse = 0.62 + 0.38 * Math.sin(p.phase * 2);
```

Pulse now derives only from `p.phase`, which updates in the physics tick. Both flat and glow buffer use the same `p.phase` value — always in sync regardless of when the buffer was last redrawn. Visual effect is identical; flicker is eliminated.

**File:** `src/backends/canvas2d/particle-system.js:127`

---

## Issue 3 — Eye stutter: particle `update()` runs before the eye draw in the same JS tick

### Symptom
Eyes stutter despite the two-canvas split. The CSS layer isolation prevents field DRAW from blocking the entity DRAW, but particle physics runs before the eye draw in the same RAF callback.

### Root cause
`canvas2d/index.js → _start()`:

```js
this._eyeSystem.update(this._t, state);
this._particleSystem.update(this._t, state);  // ← 260 sin/cos calls, no gate
this._draw(state);
```

`_draw()` gates the field draw via `budget.canDraw('field', 2)` but `particleSystem.update()` runs unconditionally every frame. The sin/cos budget (even at 260 particles) is non-zero and lands before the eye draw. On frames where the field would have been skipped, the physics update runs anyway.

### Fix — Gate the update alongside the draw

In `FrameBudget`, add:
```js
shouldSkipFieldUpdate() { return (this._skips.field ?? 0) > 0; }
```

In `_start()`:
```js
if (!this._budget.shouldSkipFieldUpdate()) {
  this._particleSystem.update(this._t, state);
}
```

When the field draw is skipped, the update is also skipped. Particle positions freeze for that frame — imperceptible at these drift speeds. Entity layer gets the full tick budget.

---

## Recommended fix order

| # | Issue | File | Effort | Impact |
|---|---|---|---|---|
| 1 | Fix flicker — pulse formula | `particle-system.js:127` | 1 line | Flicker gone immediately |
| 2 | CSS element filter — AmbientField | `effects/ambient-field.js` | ~20 lines | Landing page blur goes off main thread |
| 3 | CSS element filter — entity (3-canvas) | `element.js`, `canvas2d/index.js`, `particle-system.js` | ~60 lines | Entity blur goes off main thread; main CPU bottleneck eliminated |
| 4 | Gate `update()` alongside `draw()` | `canvas2d/index.js`, `frame-budget.js` | ~10 lines | Physics never burns eye frames |
| 5 | Batch connection strokes | `canvas2d/connection-system.js` | ~15 lines | Eliminates N GPU flushes/frame (one per connection → one total) |

Fix 1 first (visual sanity check), then 2+3 together (the real perf fix). Fix 4 is a polish item after the blur path is corrected. Fix 5 is lower priority than the CSS filter fixes but is a clean win.

---

## Issue 5 — `connection-system.js` still issues one `ctx.stroke()` per connection

### Symptom

Under high connection density or when `connDist` is widened, CPU usage spikes non-linearly. Each connection adds a GPU flush.

### Root cause

`src/backends/canvas2d/connection-system.js` (both boot and post-boot paths) calls `ctx.beginPath()` / `ctx.stroke()` per connection — the same anti-pattern the old `RaBbLE-bg.js` had before it was fixed.

Post-boot path (currently):
```js
for (let a = 0; a < pts.length; a += STEP) {
  for (let b = a + STEP; b < pts.length; b += STEP) {
    if (d2 >= connDist2) continue;
    ctx.beginPath();           // ← per connection
    ctx.moveTo(...); ctx.lineTo(...);
    ctx.strokeStyle = pa.color;
    ctx.globalAlpha = baseAlpha * (1 - dist / connDist);
    ctx.stroke();              // ← per connection GPU flush
  }
}
```

### Fix — batch into one stroke per frame

Batching requires accepting a fixed color and alpha (per-particle color variation and distance-fade are lost). The visual difference is minimal at low alpha; the perf gain is proportional to connection count.

```js
ctx.beginPath();
ctx.strokeStyle = '#3366cc';   // fixed colour
ctx.globalAlpha = 0.05;        // fixed alpha — replace (1-d/dist)*baseAlpha
ctx.lineWidth = 0.4;
for (let a = 0; a < pts.length; a += STEP) {
  const pa = pts[a];
  for (let b = a + STEP; b < pts.length; b += STEP) {
    const pb = pts[b];
    const dx = pa.rx - pb.rx, dy = pa.ry - pb.ry;
    if (dx * dx + dy * dy < connDist2) {
      ctx.moveTo(pa.rx, pa.ry);
      ctx.lineTo(pb.rx, pb.ry);
    }
  }
}
ctx.stroke();
ctx.globalAlpha = 1;
```

**Tradeoff:** Loses per-particle colour variation and distance-fade alpha. Acceptable when connection density is the primary concern. If per-particle colour is important, group by colour and issue one `stroke()` per colour group.

**Archive reference:** The fix was prototyped in `feat/nebula-perf` (World `d3e246a`, 2026-05-17). That branch is archived at `archive/nebula-world-perf` in RaBbLE-Chrysalis.

---

## Key architectural principle going forward

**On a modern discrete/integrated GPU, JS compute at this particle count (~100–260) is not the bottleneck.**
The bottleneck is always: `ctx.filter` or `shadowBlur` calling Skia on the main thread.

Rule for all future visual effects in NeBuLA:
- `shadowBlur` → never. Zero exceptions.
- `ctx.filter` on a context → never. This is a Skia main-thread paint call.
- Bloom/glow → CSS `filter: blur()` on a DOM-resident canvas element. Compositor thread. Free.
- Particle count at or below 260 with simple drift → effectively free on any post-2020 hardware.

---

## Session files for orientation

```bash
cat RaBbLE-Grimoire/RaBbLE-NeBuLA/RaBbLE-NeBuLA-Rearchitecture.md   # full phase log
cat RaBbLE-NeBuLA/src/backends/canvas2d/index.js                     # main render loop
cat RaBbLE-NeBuLA/src/backends/canvas2d/particle-system.js           # draw() + update()
cat RaBbLE-NeBuLA/src/element.js                                      # canvas creation, 3rd canvas goes here
cat RaBbLE-NeBuLA/src/effects/ambient-field.js                        # landing page field
```

Build + deploy after any src/ change:
```bash
cd RaBbLE-NeBuLA && npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js
```

Screenshot to verify:
```bash
bash RaBbLE-Grimoire/spells/visual-screenshot.sh --url http://localhost:8000 --playwright --delay 5
```
