# RaBbLE-NeBuLA Rearchitecture Plan

```
transcribe ~ grimoire >> Canvas2D modular systems architecture planned // %REARCHITECTURE_PLANNED%
```

> **Episode 1 work.** This plan supersedes `RaBbLE-NeBuLA-Perf-Fix-Plan.md` (parameter tuning).
> Cross-reference: `RaBbLE-NeBuLA-Roadmap.md` for episode tracker, `RaBbLE-NeBuLA-Architecture.md` for layer model.

---

## Problem

Sessions 14–17 attempted to fix Canvas2D entity performance through parameter tuning (glow ratio, connection stride, distance thresholds). All failed or regressed. The problems are structural:

1. **Monolithic draw loop** — 674-line `canvas2d-backend.js` draws particles, connections, portals, eyes in one synchronous `_draw()`. If particles take 25ms, eyes stutter for 25ms.
2. **Two renderers fighting for GPU** — World's `RaBbLE-bg.js` (280 particles + O(n²) connections + shadowBlur) runs alongside NeBuLA's entity (480 particles + connections + shadowBlur). ~760 particles total, ~200 with Gaussian blur, two independent RAF loops.
3. **O(n²) connection check every frame** — even stride-4 sampling is 7,000+ distance checks per frame during boot convergence.
4. **No frame budget** — no priority separation, no graceful degradation under load.

The original standalone `rabble-entity.js` (World commit `891ac33`) ran at 60fps because it was the only canvas renderer on the page. NeBuLA must be architecturally smarter to share the GPU.

---

## Scope & Responsibility Split

NeBuLA is the Collective's **visual effects engine** — not just the entity renderer. Any particle system, ambient effect, or canvas animation belongs in NeBuLA. Aether owns look-and-feel. World is a thin consumer.

| Layer | Owns | Examples |
|---|---|---|
| **NeBuLA** | Particle systems, canvas animations, visual effects, entity rendering | Entity nebula, ambient particles, grid floor, cursor trail, click ripples |
| **Aether** | Design tokens, CSS, typography, palette, component styles | Colors, fonts, layout classes, responsive breakpoints |
| **World** | Page composition, content, user interaction, orchestration | HTML structure, Alpine.js logic, chat, boot flow, WM layout |

---

## Architecture: Modular Render Systems with Frame Budgeting

### System Interface

Every visual subsystem implements a common interface:

```js
class RenderSystem {
  update(t, bootState, entropy) {}  // physics/state — always runs, every frame (cheap)
  draw(ctx, t, bootState)       {}  // canvas drawing — can be skipped by frame budget
  resize(cx, cy)                {}  // reposition on viewport change
  dispose()                     {}  // cleanup
}
```

**Key contract:** `update()` always runs (spring integration, blink FSM, phase accumulation). `draw()` can be deferred by the frame budget. This is what makes eyes always responsive.

### Frame Budget

- **Target:** 14ms per frame (leaves 2ms for browser overhead at 60fps)
- **EMA-smoothed cost tracking** per system — predicts next frame's cost from history
- **Priority order:** eyes > portals > connections > particles > ambient effects
- Eyes and portals always draw (<1.5ms combined). Connections and particles are budgeted.
- **Minimum particle draw:** every 3 frames (20fps particle layer floor, 60fps eyes)

### Module Map

```
src/backends/canvas2d/
  index.js              — Orchestrator: boot state, RAF, frame budget (~120 lines)
  eye-system.js         — Saccade, blink FSM, spring physics, orb+halo drawing (~200 lines)
  particle-system.js    — Particle init, position update, draw with glow compositing (~150 lines)
  connection-system.js  — Spatial hash topology, batched stroke (~100 lines)
  portal-system.js      — Portal arc drawing (~80 lines)
  frame-budget.js       — Time-slice allocator with priority ordering (~50 lines)

src/effects/
  ambient-particles.js  — Full-screen ambient particle field (absorbs bg.js particles)
  perspective-grid.js   — Outrun perspective grid (absorbs bg.js grid)
  cursor-trail.js       — Neon cursor trail (absorbs bg.js cursor trail)
  click-ripples.js      — Click ripple effect (absorbs bg.js ripples)
```

---

## Implementation Phases

### Phase 1 — Module decomposition ✅ COMPLETE

Extract the monolithic `canvas2d-backend.js` into the system modules above. The orchestrator (`canvas2d/index.js`) delegates to systems. Pixel-for-pixel match with current rendering.

**Known-good baseline for comparison:**
- NeBuLA `dev` branch @ commit `34dee62`
- World `world` branch @ commit `aa66550` (42,676-byte bundle)

**Files:**
- Create: `src/backends/canvas2d/` directory + all 6 modules
- Modify: `src/backends/index.js` (re-export from new path)
- Keep: `canvas2d-backend.js` as re-export shim for backward compat
- Unchanged: `src/element.js`, `src/core/boot-sequence.js`

**Implementation notes (Session 14 audit):**
- All 6 modules exist and follow the system interface contract (`update`, `draw`, `resize`, `dispose`)
- Orchestrator (`index.js`) is 277 lines — over the 150-line target, but the overage is entirely public API methods (setEntityState, setEntropy, triggerBoot, injectEyeJolt, pause, resume, resize, dispose, getPerformanceMetrics). Extract to a separate API layer in a later cleanup pass if needed.
- `eye-system.js` is 295 lines (estimated 200) — includes full saccade, blink FSM, spring physics, and waveform drawing; coherent as a single module.
- `portal-system.js` and `particle-system.js` are within estimated line counts.
- `update()` stubs in PortalSystem and ConnectionSystem are correct — no per-frame physics needed.

### Phase 2 — Frame budgeting ✅ COMPLETE

Wire `FrameBudget` into orchestrator. Measure `performance.now()` around each system's `draw()`, feed to budget allocator. Eyes locked at 60fps, particles degrade gracefully.

**Verification:** Inflate particle count to 2000. Eyes must stay at 60fps.

**Implementation notes (Session 14 audit):**
- `beginFrame()` called at top of `_draw()` before any system draws — all skip/allow decisions are pre-computed from EMA history, not volatile per-frame remaining.
- Hysteresis on glow: off when `predictedParticles > remaining`, back on at `< 0.75 × remaining` — prevents oscillation at the boundary.
- Connections use a stable flat-particle estimate when glow is off (caps predicted particles at 4ms) — prevents glow oscillation from starving connections.
- Connections gate on `state.hasBooted` in orchestrator; skipped entirely before boot starts. During boot they draw through `connection-system.js`'s boot branch (spatial hash).
- EMA alpha = 0.15 (~7-frame window). Target = 14ms. Both match spec.
- `frame-budget.js` is 102 lines (estimated 50) — the extra lines are the hysteresis and generic canDraw path; justified.

### Phase 3 — Spatial hash for connections ✅ COMPLETE

Replace O(n²) connection loop with grid-based spatial hash:
- Cell size = 65px (slightly larger than max connDist)
- Rebuild hash every 4 frames (particles drift ~0.5px/frame)
- Check only neighboring cells: O(n × k) where k ≈ 9
- Cap at 200 connections per frame
- Connection timing matches original: `connDist = 62 + settleBlend × 20`, `connAlpha = settleBlend × 0.13`

**Implementation notes (Session 14 audit):**
- `HASH_CELL_SIZE = 100` (plan said 65px). Plan said "slightly larger than max connDist" — actual max boot connDist is 82px, so 100 is correct and consistent with the intent.
- `HASH_REBUILD_INTERVAL = 4` frames — matches plan.
- Boot path: spatial hash with growing radius `connDist = 35 + connProgress * 47` (range 35–82px). Connections appear only when `connProgress ≥ 0.05`.
- Post-boot path: pre-computed topology via `rebuild()`. `CONN_DIST_POST_BOOT = 95px` (plan estimated 82px based on 62+20). 95px accounts for ±30px sinusoidal drift on each particle — this is correct.
- Post-boot `connAlpha = 0.13 + entropy * 0.12` (plan said `settleBlend × 0.13`). Entropy-modulated alpha is an improvement — connections breathe with entity state.
- Boot `connAlpha = connProgress * 0.13` — matches the spirit of the original plan.
- `MAX_DRAWN_CONNECTIONS = MAX_PRECOMPUTED_LINKS = 200` — matches plan cap.
- `rebuild()` is O(n²) but runs only on init and resize, not per-frame — correct.

### Phase 4 — Glow layer compositing ✅ COMPLETE

Offscreen canvas for glow particles:
- Draw glow particles (shadowBlur) to offscreen canvas every 2 frames
- Composite onto main canvas with `drawImage()` every frame
- Non-glow particles draw directly (no shadowBlur)
- Under load, glow interval auto-increases to 3–4 frames
- Glow persistence between frames = smooth bloom effect

**Implementation notes (Session 53):**
- `particle-system.js` now draws in two passes: flat particles direct to the
  field context every frame, glow particles into an offscreen `_glowCanvas`
  redrawn every `glowInterval` frames (2 normal, 3/4 under load) and
  composited via `drawImage()` every frame. Interval ramps off the existing
  `adaptiveGlow` signal — no new load-detection plumbing needed.
- **Bonus — went further than the plan:** split rendering into two stacked,
  independently-composited `<canvas>` layers (`element.js` creates both):
  an **entity layer** (eyes + portals, drawn first, every frame, unconditionally)
  and a **field layer** (particles + connections, the offscreen-glow-composited,
  CPU-heavy half). The orchestrator (`canvas2d/index.js`) draws the entity
  layer to its own context before the field layer ever gets a chance to spend
  time, and the field layer is gated as a whole via `budget.canDraw('field', 2)`
  — it can be skipped for up to 2 consecutive frames and simply holds its
  last-painted content, since it's a separately-composited GPU layer rather
  than interleaved draw calls on a shared canvas. This directly satisfies the
  "eyes always responsive, particles/connections never block them" goal beyond
  what frame budgeting alone could guarantee on a single canvas.
- `_updateCanvasSize()` and `resize()` now size both canvases (and the glow
  buffer) identically; `element.js`'s `_resize()` sizes both host canvases.

### Phase 5 — Effects systems (absorb bg.js)

Migrate World's `RaBbLE-bg.js` visual effects into NeBuLA effect modules. Each effect uses the same system interface and shares the frame budget.

**New NeBuLA API:**
```js
const bg = NeBuLA.createAmbient(document.body, {
  particles: true,
  grid: true,
  cursorTrail: false,
  clickRipples: false,
});
// Or: <rabble-ambient particles grid></rabble-ambient>
```

Both `<rabble-entity>` and `<rabble-ambient>` share a frame budget coordinator (`window.NeBuLA._budget`). One RAF loop, one GPU pipeline.

**World changes:**
- Remove `<script src="js/RaBbLE-bg.js">` from all pages
- Replace with NeBuLA ambient API
- Archive `world/js/RaBbLE-bg.js`

### Phase 6 — World single-page app with WM applets

Consolidate separate pages (RaBbLE-Chat.html, RaBbLE-Docs.html, RaBbLE-OS.html) into WM applets within the landing page. The landing page becomes the single entry point and canonical template for new RaBbLE/NeBuLA embedded pages.

**Template pattern:**
```html
<head>
  <link rel="stylesheet" href="/css/RaBbLE-theme.css">
  <script src="/js/RaBbLE-NeBuLA.js"></script>
</head>
<body>
  <rabble-ambient particles grid></rabble-ambient>
  <rabble-entity mode="boot" particle-count="480" overscan="2.35"></rabble-entity>
  <!-- Applets load into WM slots -->
</body>
```

No bg.js. No separate pages. One shell, NeBuLA for all visual effects, Aether for all styling.

Boot.html stays as a Plymouth boot screen reference artifact for RaBbLE-OS.

This phase can proceed in parallel with NeBuLA decomposition (phases 1–5).

### Phase 7 — Three.js decomposition (parallel track)

Apply same system interface to `threejs-backend.js`:
- `threejs/eye-system.js`, `particle-system.js`, `connection-system.js`, `portal-system.js`
- Shared `BootSequence` and system interface across both backends
- Main benefit is code maintainability (Three.js already uses InstancedMesh)

---

## Exit Conditions

- [ ] Eyes render at 60fps regardless of particle load (eye draw < 1ms)
- [ ] Boot animation with connections at 50+ fps on desktop
- [ ] Post-boot idle at 58+ fps on desktop with ambient system active
- [ ] Mobile (iPhone 14) at 45+ fps with auto-reduced particles
- [ ] No visual regression: boot, connections, glow, eye behavior match original
- [ ] Orchestrator under 150 lines, each system independently modifiable
- [ ] bg.js eliminated — ambient particles are a NeBuLA effect system
- [ ] World landing page uses template pattern (NeBuLA elements, Aether CSS, no separate scripts)
- [ ] Bundle stays under 50KB minified

---

## Reference

| Document | Purpose |
|---|---|
| `RaBbLE-NeBuLA-Architecture.md` | Layer model, system interface, frame budget |
| `RaBbLE-NeBuLA-Roadmap.md` | Episode tracker, exit conditions |
| `RaBbLE-NeBuLA-Perf-Fix-Plan.md` | **Superseded** — parameter-level tuning (historical reference) |
| `RaBbLE-World/world/js/RaBbLE-bg.js` | Source for effects migration (ambient, grid, cursor, ripples) |
| Known-good baseline: NeBuLA `34dee62`, World `aa66550` | Performance and visual comparison target |
| Original entity renderer: World commit `891ac33` `world/js/RaBbLE-entity.js` | 60fps reference implementation |

---

```
transcribe ~ grimoire >> rearchitecture crystallized // %REARCHITECTURE_PLANNED%
```
