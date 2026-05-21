# NeBuLA Canvas2D Performance Fix Plan

> Agent handoff doc. Work this from top to bottom. All work is in `RaBbLE-NeBuLA/dev` branch.
> After every source edit: `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`

---

## Problem Summary

The Canvas2D entity renderer (`src/backends/canvas2d-backend.js`) is performing poorly (fps well below 60) after a series of changes made during Session 15 triage. Two root causes remain unresolved:

### 1. Too many connection line segments per frame

The current connection rendering (`_drawConnections`) uses step=2 sampling (240 out of 480 particles) and connDist=82px. At rest, ~8,000 moveTo/lineTo segments are added to a single batched path each frame. Even as one `stroke()` call, building and stroking an 8,000-segment path is expensive.

The reference visual (joinrabble.world, pre-Codex) had a sparse neural web — roughly 50–150 visible connections. The current code draws far more.

### 2. shadowBlur on ~216 particles per frame

With 480 particles where ~45% glow (`Math.random() > 0.55`), approximately 216 particles set `ctx.shadowBlur` every frame. Canvas2D shadowBlur triggers a Gaussian blur per draw operation. This is the primary rendering bottleneck.

The current code already skips non-glow particles (Session 15 fix). The adaptive glow system reduces `_adaptiveGlow` under load, but the recovery cycle is slow.

---

## What's Already Fixed (Don't Revert)

- `p.rx` / `p.ry` fields store rendered positions (avoids drift recalculation in connections)
- Non-glow particles skip `ctx.shadowBlur` entirely
- Connection drawing is batched into ONE `stroke()` call (was 1 per connection)
- `_scheduleRebuild()` flag throttles `_rebuildLinks()` to once per frame
- Adaptive quality system reduces `_adaptiveGlow` before touching particle count
- Boot reveal: connections appear from frame 1 of boot (convProg * 1.54)

---

## Fix Plan

### Step 1 — Reduce connection count (most impactful)

**File:** `src/backends/canvas2d-backend.js`, `_drawConnections()` method.

Change the sampling step from 2 to **4**, and reduce `connDist` from 82px base to **55px** base:

```js
// BEFORE
const connDist  = (35 + connProgress * 47) * (1 + this._entropy * 0.4);
// ...
for (let i = 0; i < ps.length; i += 2) {
  // ...
  for (let j = i + 2; j < ps.length; j += 2) {
```

```js
// AFTER
const connDist  = (28 + connProgress * 27) * (1 + this._entropy * 0.3);
// max at full: 55 * 1.09 = 60px — gives sparse neural web matching joinrabble.world
// ...
const step = 4;
for (let i = 0; i < ps.length; i += step) {
  // ...
  for (let j = i + step; j < ps.length; j += step) {
```

Also add a hard cap: break after N total line segments have been added to the path (use a counter):

```js
let drawn = 0;
const MAX_DRAWN = 200; // visual target: sparse, not dense
ctx.beginPath();
outer: for (let i = 0; i < ps.length; i += step) {
  const pi = ps[i];
  for (let j = i + step; j < ps.length; j += step) {
    if (drawn >= MAX_DRAWN) break outer;
    const pj  = ps[j];
    const dx  = pi.rx - pj.rx;
    const dy  = pi.ry - pj.ry;
    if (dx * dx + dy * dy < connDist2) {
      ctx.moveTo(pi.rx, pi.ry);
      ctx.lineTo(pj.rx, pj.ry);
      drawn++;
    }
  }
}
ctx.stroke();
```

**Expected result:** 120 sampled particles × ~25 connections each / 2 ≈ ~1,500 checks, ≤200 drawn. Tiny path, fast stroke.

### Step 2 — Reduce glow particle ratio

**File:** `src/backends/canvas2d-backend.js`, `_makeParticle()` method.

```js
// BEFORE
glow:  Math.random() > 0.55,   // ~45% glow

// AFTER
glow:  Math.random() > 0.72,   // ~28% glow → ~134 blur ops instead of ~216
```

This alone reduces shadowBlur calls by ~38% with no visual regression (the remaining glow particles still produce the nebula glow).

### Step 3 — Add `connectionAlpha` opt to `_drawConnections`

The `opts.connectionAlpha` is currently used in the function. Verify the default is `0.13` (matching original) rather than `0.18`:

```js
// In constructor opts:
connectionAlpha: Number(opts.connectionAlpha) || 0.13,
```

### Step 4 — Build and deploy

After each change:
```bash
npm run build:iife
cp dist/nebula.iife.js /path/to/RaBbLE-World/world/js/RaBbLE-NeBuLA.js
```

Open `localhost:PORT/world/RaBbLE-NeBuLA.html` → click Summon → watch fps counter. Target: 55–60fps steady.

### Step 5 — Visual QA

Compare connections against the reference at `joinrabble.world`:
- Sparse, organic, ~50–150 connections visible at idle
- Connections reveal from boot start (not just after summon completes)
- No "fan out from single point" pattern
- Glow particles produce soft blue/violet haze

### Step 6 — Commit both repos

NeBuLA:
```bash
git add src/backends/canvas2d-backend.js src/element.js dist/nebula.iife.js
git commit -m "mend ~ nebula >> perf: sparse connections, reduced glow ratio // %PERF_60FPS%"
```

World:
```bash
git add world/js/RaBbLE-NeBuLA.js
git commit -m "mend ~ world >> NeBuLA bundle: performance fixes // %PERF_60FPS%"
```

---

## Connection API (for Studio tuning sliders)

These methods already exist on `Canvas2dBackend`:
- `setConnectionDist(px)` — changes connection radius, schedules rebuild
- `setConnectionAlpha(val)` — changes opacity (0–1)
- `setParticleCount(n)` — changes density, schedules rebuild
- `setAdaptive(bool)` — enable/disable auto quality
- `getPerformanceMetrics()` — returns fps, particles, targetParticles, adaptiveGlow, etc.

The NeBuLA Studio page (`world/RaBbLE-NeBuLA.html`) already has sliders wired to these. The `connectionDist` slider range (20–200px) should be enough to verify the fix visually.

---

## Known Issues After This Fix

- Three.js backend is also slow but not part of this plan
- The NeBuLA Studio `Conn Alpha` slider uses `connectionAlpha` which defaults to 0.18 — change to 0.13 in both backend and Studio Alpine data after Step 3
- `_links` / `_rebuildLinks` / `_scheduleRebuild` infrastructure exists but is unused by the main render path (the dynamic approach doesn't use it). It can be removed for cleanup, or left for future use.

---

## S17 Root Cause Findings (Session 17 Debugging)

> Additional root causes surfaced during S17 triage. Not fully resolved. Record these before attempting further perf work.

### Post-boot particle drift breaks connDist assumptions

After boot, `settleBlend = 1` → spring force term = 0. Particles accumulate sinusoidal velocity (~30px oscillation amplitude). Their **effective spread** is `targetX ± 30px`, not just `NEBULA_RADIUS = 130px`. This means:

- Reducing `connDist` from 106px → 53px caused **zero** visible connections
- Even 85px showed zero connections
- Correct range to tune: **85–100px** to account for this idle drift

**Fix approach:** `connDist` for connection eligibility should be calibrated to the effective particle spread post-boot, not to the visual radius.

### shadowBlur GPU cliff at boot-end

Enabling `ctx.shadowBlur` on all 45% glow particles simultaneously at boot completion causes an instant fps cliff (can drop to ~1fps). The adaptive glow system recovers, but slowly.

**Fix approach:** Stagger glow enable — gradually increase the glow probability over the first N frames post-boot rather than switching all at once.

### Individual `ctx.stroke()` per connection is catastrophically expensive

Original code (before S15 fix) called `stroke()` per connection. Even the pre-codex production build had this — it only worked because connection count was very low at small `connDist`. Any increase in particle density or `connDist` restores the catastrophic cost.

**Status:** Fixed in S15 (batched into one `stroke()` per frame). Do not revert.

### Architectural direction for next perf pass

Split into **two canvases**:
- **Bottom canvas:** particles + connections (can render at reduced frame rate under load)
- **Top canvas:** eye layer only (separate RAF — always runs at 60fps)

This isolates the eye's interactive responsiveness from particle/connection rendering load. The eye canvas is lightweight and should never drop below 60fps.

### Known-good baseline commits

If you need to roll back to a state that was visually correct before triage:
- **World `world` branch:** commit `aa66550` (NeBuLA bundle = 42,676 bytes, starts with `var W=...`)
- **NeBuLA `dev` branch:** commit `34dee62` (pre-S15 perf triage)
- **Optimization branch:** `feat/nebula-perf` in both repos (World `d3e246a`, NeBuLA `56908e1`)
