# RaBbLE-Collective-Overview — gist

> Source: `RaBbLE-Collective/RaBbLE-Collective-Episode-1-Overview.md` | ~914 → ~200 tokens
> Regenerate: `bash spells/distill-gists.sh`

**Three-layer architecture for Episode 1:**

**Layer 1 — Aether (theme):** CSS design system via CDN. World loads it. No local CSS per page. Dev: `npm run build` → `dist/aether.css`. CDN path: `/aether/v0.0.0.0/aether.css` (dev), `aether.min.css` (prod). Always use `dev-serve.sh`, never run `dev-cdn.js` directly.

**Layer 2 — NeBuLA (renderer):** JS entity renderer (IIFE + ESM) via CDN. Exposes `window.NeBuLA` API. `<rabble-entity>` web component. Canvas2D complete for Ep1; Three.js deferred to Episode 2.

**Layer 3 — World (app):** Static HTML. No build step. Loads Aether CSS + NeBuLA JS from CDN, adds page logic. New pages = ~70% HTML + Aether classes, ~30% logic. Zero CSS/JS duplication.

**Easy page pattern:**
```html
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css">
<script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>
<!-- Use Aether classes + window.NeBuLA API -->
```

**Versioning:** All three tag `v0.0.0.1` simultaneously when Episode 1 airs.

**Pre-sCoRE:** Pages use mock JSON/localStorage. When sCoRE ready: wire entity state to API.

→ Full doc for: implementation priority table, CDN deployment workflow, per-layer doc index
