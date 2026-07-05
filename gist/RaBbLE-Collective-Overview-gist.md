# RaBbLE-Collective Episode 1 Overview — gist

> Source: `RaBbLE-Collective-Episode-1-Overview.md` | ~914 → ~260 tokens
> Regenerate: `bash spells/distill-gists.sh`

**Episode 1 delivers three CDN-backed layers for coordinated release:** design system (Aether) + rendering engine (NeBuLA) + frontend app (World).

**Aether (Design System)**
- CSS bundle: `https://aether.joinrabble.world/v0.0.0/aether.min.css`
- Canonical visual identity, reusable class library (`.rabble-card`, `.rabble-btn`, `.rabble-grid-3`, etc.)
- Status: build setup pending

**NeBuLA (Rendering Engine)**
- JavaScript (IIFE + ESM): `https://nebula.joinrabble.world/v0.0.0/nebula.iife.js`
- Entity visuals, Canvas2D, animations, interactive components
- Status: Phase 1 ✅ (build), Phase 2–3 🔄 (Palette + Canvas2D), Phase 4+ pending
- Public API: `window.NeBuLA.createPuppet({ canvas, ... })`

**RaBbLE-World (Frontend App)**
- Static HTML pages + CDN-loaded scripts/CSS; no build step
- Deploy via Cloudflare Workers (no backend until sCoRE API ready)
- Workflow: copy template → apply Aether classes → load NeBuLA if needed → wire logic
- Result: new pages ~70% HTML, ~30% logic; zero CSS/JS duplication

**Versioning:** `v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}` — v0.0.0.0 pre-Episode-1, v0.0.0.1 at air date. CDN paths use Echo (v0.0.0).

→ Full doc for: phase-by-phase implementation plan, Canvas2D rendering specs, World page template, NeBuLA public API reference, CDN deployment procedures
