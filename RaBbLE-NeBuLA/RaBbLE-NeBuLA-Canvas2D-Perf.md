# NeBuLA Canvas2D Performance Reference

> Session S55c · 2026-06-08 · Mark McConachie + Claude
> Measured on: Fedora 43 / Hyprland, mid-range desktop GPU, Chromium headless + Firefox

---

## Guiding Principle

**All visual effects must run on the GPU compositor thread. Never burn JS/CPU on blur, blend, or filter operations.**

The browser's compositor composites canvas layers and DOM CSS filters on the GPU without touching JS or Skia. JS-triggered draw ops (shadowBlur, ctx.filter, destination-in composites on large canvases) run on the main thread through Skia — they block the RAF loop and kill frame rate.

Rule: **draw calls and geometry compute only; never `shadowBlur`, never `ctx.filter`, never `ctx.drawImage` on large textures to create blur.**

---

## Canvas2D System Cost Breakdown

Measured at 1280×720, DPR 1×, 150 particles, idle entity state:

| System | Per-frame cost | Notes |
|---|---|---|
| `ctx.shadowBlur` per call | **4–6 ms** | Skia software Gaussian — the primary killer |
| Eye system (4× shadowBlur) | **16–24 ms** | Was the #1 perf issue, disguised as "particle lag" |
| Portal system (2× shadowBlur) | **8–12 ms** | |
| 150-particle flat draw (no blur) | ~1–2 ms | 150× `arc + fill`, squared falloff, early exit |
| 150-particle glow draw (~18 glow particles, every 3-4 frames) | ~0.2 ms | Draws to glowCanvas; CSS blur is free |
| AmbientField background (half-rate, 100 particles, no connections) | ~0.5–1 ms | 30fps hold; grid baked offscreen |
| CSS `filter:blur()` on DOM canvas | **0 ms JS** | Compositor thread, GPU, never touches JS loop |
| Radial/linear gradient fill | ~0.1–0.3 ms | Cheap — GPU path fill |
| `ctx.clearRect` (entity canvas, ~600×800 px at 1× DPR) | ~0.1 ms | |

**Before S55c (shadowBlur in eyes+portals):** ~25 ms/frame → ~40 FPS
**After S55c (all blur via CSS compositor):** ~3–5 ms/frame → stable 60 FPS

---

## Three-Canvas Stack

```
z:0  fieldCanvas    flat particles, physics-heavy — can be skipped/throttled
z:1  glowCanvas     all glow shapes (oversized); CSS filter:blur(8px) on DOM element
z:2  entityCanvas   crisp eyes, portals, rings — always drawn first, every frame
```

The browser GPU compositor blends all three canvases. **The entity layer (z:2) is always drawn before the field layer even gets a chance to run.** A slow particle frame can delay or skip the field canvas without ever corrupting or delaying the eyes.

---

## The shadowBlur Trap

`ctx.shadowBlur = N` on a Canvas2D context:
1. Renders the current draw operation into a temporary Skia surface
2. Applies a full Gaussian blur to that surface in **software on the main JS thread**
3. Composites the result back onto the canvas

Cost scales with: `blur_radius² × canvas_area_affected`. At blur=22px on a 600×110px orb, that's ~(22² × 66,000) = ~32M operations per call. With 4 calls per frame, that's ~128M operations per frame just for eye glow.

### Replacement pattern

Instead of:
```js
ctx.shadowColor = col; ctx.shadowBlur = 22; ctx.fill(); ctx.shadowBlur = 0;
```

Do:
```js
// Crisp shape on entity canvas (no blur)
ctx.fill();

// Oversized glow shape on glowCanvas (CSS filter:blur on DOM element)
glowCtx.beginPath(); glowCtx.ellipse(x, y, r + 8, r + 14, ...);
glowCtx.fillStyle = 'rgba(220,235,255,0.5)'; glowCtx.fill();
```

The glow canvas has `style="filter:blur(8px)"` on the DOM element. The blur runs on the compositor thread at GPU speed. Shape size is increased to compensate for the fixed 8px blur radius spreading the paint.

---

## Connection System Cost

The connection system (O(N²) link checks + thin-line draws) was measured at:

| Config | Cost |
|---|---|
| N=100, all pairs checked | ~8–12 ms (O(N²) = 4,950 iterations) |
| N=150, all pairs checked | ~18–27 ms |
| Removed entirely | 0 ms |

At 0.07 opacity, connections were effectively invisible. **They were removed from AmbientField entirely in S54.** ConnectionSystem is still in the NeBuLA codebase but not wired into the render loop.

If connections return for Three.js: use instanced line rendering, one draw call for all segments.

---

## Effect Budget for Episode 1

Target: **60 FPS (16.7ms/frame)** across landing page + boot page.

| Budget allocation | Target |
|---|---|
| Eye system (glow via CSS) | ≤ 1 ms |
| Portal system (glow via CSS) | ≤ 0.5 ms |
| Entity particles (150 count, flat draw) | ≤ 2 ms |
| AmbientField background (half-rate) | ≤ 1 ms per draw-frame |
| State/physics updates | ≤ 1 ms |
| RAF loop overhead + clearRect + transforms | ≤ 0.5 ms |
| **Total** | **≤ 6 ms** — leaves 10ms headroom for DOM, sCoRE, layout |

---

## Rules Derived from This Session

1. **No `shadowBlur` ever.** Use CSS `filter:blur()` on a DOM canvas element instead.
2. **No `ctx.filter`.** Same problem — Skia main-thread blur.
3. **No `drawImage` from a large canvas to create blur.** Copying a full-screen texture costs more than the original draw calls it replaces.
4. **All blur is CSS.** Glow shapes go to `glowCanvas` which has `filter:blur(Npx)` in its `style`.
5. **Half-rate background.** AmbientField renders at 30fps, holds the GPU texture on skip frames.
6. **No O(N²) connections** unless the renderer is Three.js with instanced geometry.
7. **Particle glow pass at 1/3–1/4 rate** — only ~12% of particles glow; redraw every 3-4 frames.
8. **CSS stacking beats canvas compositing.** Three separate canvases composited by the browser GPU is faster than one canvas with manual composite operations (`destination-in`, `source-over` with large alpha masks).

---

## Three.js Migration Notes

When moving to Three.js (Episode 1 target):
- All of the above is irrelevant — Three.js renders to WebGL, Gaussian blur is a GPU post-process pass.
- Use `THREE.UnrealBloomPass` (EffectComposer) for all glow.
- Connections → `THREE.LineSegments` with `InstancedBufferGeometry`, one draw call for N² links.
- Particles → instanced `THREE.Points`, one draw call for all 1000+ particles.

The Canvas2D layer remains for the entity eyes only (Layer 1 in the architecture). Eyes stay in Canvas2D even post-Three.js because they need crisp pixel-perfect control and the blink FSM is tied to a 2D coordinate system.

---

*Updated: S55c · Next session: confirm 60fps on landing page, then move to Phase 2C or OS bootstrap*
