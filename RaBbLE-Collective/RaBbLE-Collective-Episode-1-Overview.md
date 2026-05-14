# RaBbLE-Collective Episode 1 Overview

```
transcribe ~ collective >> episode 1 architecture, api, and build strategy documented // %EPISODE_1_DOCUMENTED%
```

> **This document ties together Aether, NeBuLA, and World for Episode 1 delivery.** All implementation docs live in the Grimoire. Members reference these docs but don't duplicate them.

---

## Three-Layer Architecture

### Layer: Aether (Design System)

**Role:** Theme + look/feel — canonical visual identity  
**Delivery:** CSS bundle via CDN  
**Version:** v0.0.0 (pre-Episode-1)

| What | Where |
|---|---|
| Architecture | `RaBbLE-Grimoire/RaBbLE-Aether/RaBbLE-Aether-Architecture.md` |
| Build + CDN | `RaBbLE-Grimoire/RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md` |
| Implementation | `RaBbLE-Aether/` repo — build only |
| Usage | Import Aether classes in HTML; no local CSS per page |

**In Development:**
- `npm install --save-dev esbuild`
- `npm run build` → `dist/aether.min.css`
- Five-Es tagged for CDN: `cdn/aether/v0.0.0/aether.min.css`

---

### Layer: NeBuLA (Rendering Engine)

**Role:** Flare + animations + embedded visuals — entity interaction  
**Delivery:** JavaScript (IIFE + ESM) via CDN  
**Version:** v0.0.0.0 (pre-Episode-1)

| What | Where |
|---|---|
| Architecture | `RaBbLE-Grimoire/RaBbLE-NeBuLA/RaBbLE-NeBuLA-Architecture.md` |
| Public API | `RaBbLE-Grimoire/RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md` |
| Implementation Plan | `RaBbLE-Grimoire/RaBbLE-NeBuLA/RaBbLE-NeBuLA-Plan.md` (8 phases) |
| Implementation | `RaBbLE-NeBuLA/` repo — code + build |
| Usage | `window.NeBuLA.createPuppet({ canvas, ... })` |

**Status:**
- Phase 1 (Build) ✅ Complete — esbuild IIFE + ESM configured
- Phase 2–3 (Palette + Canvas2D) 🔄 In progress
- Phase 4+ (Three.js, Animation, Integration) Pending

---

### Layer: RaBbLE-World (Frontend App)

**Role:** Orchestration — pulls Aether + NeBuLA together into deployable pages  
**Delivery:** Static HTML + loaded scripts/CSS from CDN  
**Version:** Follows Collective (v0.0.0 pre-Episode-1)

| What | Where |
|---|---|
| Page Template | `RaBbLE-Grimoire/RaBbLE-World/RaBbLE-World-Page-Template.md` |
| Architecture | `RaBbLE-Grimoire/RaBbLE-World/RaBbLE-World-Architecture.md` |
| Implementation | `RaBbLE-World/` repo — HTML pages + page-specific logic |
| Build | None — static files. Deployment: Cloudflare Workers |

**Pattern:**
```html
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css">
<script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>
<!-- Use Aether classes + window.NeBuLA API -->
```

---

## Workflow: Easy Page Creation

**Goal:** Adding new pages to World should require only HTML + glue logic, reusing Aether + NeBuLA.

**Step by step:**

1. Copy template from `RaBbLE-Grimoire/RaBbLE-World/RaBbLE-World-Page-Template.md`
2. Load Aether CSS from CDN
3. Build layout using Aether classes (`.rabble-card`, `.rabble-btn`, `.rabble-grid-3`, etc.)
4. Load NeBuLA if you need entity visuals
5. Wire page logic (Alpine.js or vanilla JS)
6. Zero CSS duplication, zero JS duplication

**Result:** New pages are 70% HTML, 30% logic. No build step needed.

---

## Five-Es Versioning

All artifacts versioned per Grimoire spec: `v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}`

**Current:** `v0.0.0.0` (Epoch 0, Evolution 0, Echo 0, Episode 0)  
**Next:** `v0.0.0.1` (Episode 1 airs across Collective simultaneously)

**CDN paths use Echo level:**
- Pre-Episode-1: `v0.0.0`
- Post-Episode-1: `v0.0.0.1`

When Episode 1 airs, all three (Aether, NeBuLA, World) are tagged v0.0.0.1 in git.

---

## CDN Deployment (Before API Integration)

All static assets served from CDN:
- Aether CSS: `https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css`
- NeBuLA JS: `https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js`
- World HTML: Cloudflare Workers (static host)

No backend calls until sCoRE API is ready. Pages use:
- Mock JSON data (static files or localStorage)
- Alpine.js for interactivity
- NeBuLA for animations

When sCoRE integration happens:
- Pages wire entity state to API responses
- Same Aether + NeBuLA layers, just bound to live data

---

## Implementation Priority

| Task | Owner | Status | Blocking |
|---|---|---|---|
| Aether build setup | Aether repo | Pending | World easy-add |
| NeBuLA Phase 2–3 | NeBuLA repo | In progress | Phases 4–7 |
| World page template | Grimoire | Done ✅ | New pages |
| NeBuLA Phase 4+ | NeBuLA repo | Pending | World integration |
| World integration (Phase 7) | Both repos | Pending | Smoke test |

---

## Grimoire Documentation Index

**For implementers:**
- `RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md` — how to build and ship Aether
- `RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md` — public API for using NeBuLA
- `RaBbLE-NeBuLA/RaBbLE-NeBuLA-Plan.md` — step-by-step implementation (8 phases)
- `RaBbLE-World/RaBbLE-World-Page-Template.md` — template for new pages

**For maintainers:**
- Member CONTEXT.md files track phase progress
- Versioning and release coordination in RaBbLE-Versioning.md
- Collective roadmap in common/RaBbLE-Collective.md

---

```
transcribe ~ collective >> episode 1 documented and ready for build // %EPISODE_1_DOCUMENTED%
```
