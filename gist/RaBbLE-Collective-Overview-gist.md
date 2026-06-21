Here is the distilled gist:

# RaBbLE-Collective Episode 1 Overview — gist

> Source: `RaBbLE-Collective/RaBbLE-Collective-Episode-1-Overview.md` | ~914 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

Ties **Aether + NeBuLA + World** into one three-layer stack for the Episode 1 pilot delivery. Implementation docs live in the Grimoire; members reference, never duplicate.

**Three layers**

| Layer | Role | Delivery | API / usage |
|---|---|---|---|
| Aether | Theme, look/feel | CSS bundle via CDN | Import classes (`.rabble-card`, `.rabble-btn`, `.rabble-grid-3`) |
| NeBuLA | Flare, animation, entity visuals | JS (IIFE + ESM) via CDN | `window.NeBuLA.createPuppet({ canvas, ... })` |
| World | Orchestration / frontend | Static HTML, CDN-loaded assets | Cloudflare Workers host, no build step |

**Page pattern**
```html
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css">
<script src="https://cdn.joinrabble.world/nebula/v0.0.0/nebula.iife.js"></script>
```
New pages = ~70% HTML, 30% glue (Alpine.js/vanilla). Zero CSS/JS duplication.

**Versioning** — Five-Es `v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}`. Now `v0.0.0.0`; when Episode 1 airs, Aether/NeBuLA/World all tag `v0.0.0.1` simultaneously. CDN paths use Echo level (`v0.0.0` pre-air).

**CDN-first** — all assets static until sCoRE API ready; pages use mock JSON/localStorage, then bind live data on the same layers.

**Status** — Aether build pending · NeBuLA Phase 1 done, Phase 2–3 in progress, 4+ pending · World template done.

→ Full doc for: per-layer doc paths, NeBuLA's 8-phase plan, implementation-priority table, easy-page-creation steps, sCoRE integration detail.

---

Note: the Write tool was denied, so I've output the gist inline rather than saving it to `gist/RaBbLE-Collective-Episode-1-Overview-gist.md`. Let me know if you'd like me to write the file (grant permission) or hand it to `distill-gists.sh`.
