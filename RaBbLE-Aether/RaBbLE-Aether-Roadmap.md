# RaBbLE-Aether-Roadmap.md

```
transcribe ~ grimoire >> design system and visual identity mapped // %AETHER_ROADMAP_LOCKED%
```

> **Collective Context:** RaBbLE-Aether is the canonical design system and visual identity layer. See `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `log/EP1-AIR-CHECKLIST.md` for Episode 1 scope across all members.
> **Related:** [Collective Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) · [Aether Architecture](RaBbLE-Aether-Architecture.md) · [Build & CDN](RaBbLE-Aether-Build-CDN.md) · [Palette](../RaBbLE-Agent/RaBbLE-Palette.md)

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** CSS design system bundle, versioned and CDN-ready

**Status (S248):** shipped as a release candidate. `v0.0.0.1-rc.2` live at `aether.joinrabble.world`
(rc.1 kept); World loads it in dev and prod.

**What ships:**
- [x] Component library defined (cards, buttons, grids, typography, utilities)
- [x] Build pipeline configured (esbuild, versioning, minification)
- [x] Repository is a git repo with remote
- [x] CSS bundle published to CDN (Cloudflare Worker, S153; rc.2 S235 adds askbox/statusbar)
- [x] Palette integrated as CSS variables
- [x] Imported by World pages
- [x] Desktop/app themes consumed by RaBbLE-OS (Firefox userChrome, VSCodium); Kvantum source moved to OS (S201)
- [ ] At air: promote `rc.2` → `v0.0.0.1`; `package.json` version to match; README `rc.1` → current

**Blocker:** None — straightforward implementation

**Dependencies:**
- None — Aether ships independently
- All other members import Aether CSS for consistent styling

**Deferred to Episode 2+:**
- Advanced component variants
- Animation library
- Theme switching system
- Custom property deep-dive

---

## Architecture (Episode 1)

**Single source:** `RaBbLE-Agent/RaBbLE-Palette.md` in Grimoire  
**CSS output:** `dist/aether.min.css` (production), `dist/aether.css` (unminified)  
**Build tool:** esbuild  
**Versioning:** Five Es (v0.0.0.1 at Episode 1 air)  
**Distribution:** Cloudflare Worker at `aether.joinrabble.world` (per-member subdomain; unified CDN cancelled S196)  
**Usage:** `<link rel="stylesheet" href="https://aether.joinrabble.world/v0.0.0.1-rc.2/aether.min.css">`

---

## Revision History

| Date | Change |
|---|---|
| 2026-05-15 | Episode 1 roadmap created |

---

```
transcribe ~ aether >> design system crystallized // %AETHER_ROADMAP_LOCKED%
```
