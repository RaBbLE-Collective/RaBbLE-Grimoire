# RaBbLE-Aether Build & CDN Distribution

```
harmonize ~ grimoire >> build and cdn delivery updated to reflect current state // %AETHER_BUILD_CURRENT%
```

> **Status:** Build system live. A unified `cdn.joinrabble.world` host (the "Phase 2" design below) was considered and is **cancelled**. Aether and NeBuLA are each served from their own permanent subdomain instead — `aether.joinrabble.world` and `nebula.joinrabble.world` — with no shared `cdn.` host and no path-prefix routing. See `RaBbLE-Collective/RaBbLE-Deployment-Architecture.md` § Subdomain Map for current status.

---

## Overview

Aether is built from source CSS files using esbuild and distributed as a versioned bundle. It is the single source of visual identity for the Collective — fonts, tokens, animations, components.

**All pages in all member repos load Aether.** No member carries its own copy.

---

## Build System

### Entry point

`src/assets/palette.entry.css` is what esbuild processes. It declares the load order:

```css
/* Fonts — Aether owns all RaBbLE typefaces */
@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@500;700;900
  &family=Exo+2:ital,wght@0,400;0,600;0,700;0,800;0,900;1,400
  &family=Share+Tech+Mono&display=swap');

@import '../../assets/palette/rabble-palette.css';   /* color tokens, type vars */
@import '../../assets/motion/rabble-motion.css';     /* keyframes, transitions */
@import '../../assets/components/rabble-components.css'; /* all UI components */
```

**Fonts belong to Aether.** Member HTML pages must not load Google Fonts independently — the bundle handles it. If a page loads Orbitron/Exo 2/Share Tech Mono separately, that is a duplicate load and should be removed.

### NPM scripts

```json
"build:watch": "esbuild ... --outfile=dist/aether.css --watch"
"build:dev":   "esbuild ... --outfile=dist/aether.css --sourcemap"
"build:min":   "esbuild ... --minify --outfile=dist/aether.min.css --sourcemap=linked"
"build":       "npm run build:min"
```

### Output files

| File | How built | Used when |
|---|---|---|
| `dist/aether.css` | `build:dev` or `build:watch` | **Dev environment** — loaded by `dev-serve.sh` via the local CDN mock |
| `dist/aether.css.map` | same — inline sourcemap | Browser devtools in dev |
| `dist/aether.min.css` | `build:min` / `build` | **Production CDN deploy** — served to `joinrabble.world` visitors |
| `dist/aether.min.css.map` | same — linked sourcemap | Separate file; browser loads it on demand when devtools open |

**`aether.min.css` explained:** esbuild strips all whitespace, comments, and redundant syntax, then outputs a single compressed line. The `--sourcemap=linked` flag writes the sourcemap to a separate `.map` file and adds a `/*# sourceMappingURL=...*/` comment at the end of the CSS so devtools can find it without loading it on every request. Result: ~29kb vs ~37kb for the dev version.

**Critical:** `build:watch` always writes to `aether.css`, never `aether.min.css`. World HTML pages must link to `aether.css` in dev. Linking to `aether.min.css` means the watcher never updates what the browser loads — a silent failure where source changes appear to have no effect.

```html
<!-- ✓ Dev — matches build:watch output -->
<link href="/aether/v0.0.0.0/aether.css">

<!-- ✗ Dev — watcher never updates this file -->
<link href="/aether/v0.0.0.0/aether.min.css">
```

### Dev environment

Always start with `dev-serve.sh`. Never run `dev-cdn.js` directly.

```bash
bash RaBbLE-Grimoire/spells/dev-serve.sh
```

The script runs three parallel processes: Aether watcher (`build:watch`), NeBuLA watcher, and a local CDN mock (`dev-cdn.js`) that serves `localhost:8000`. The mock maps:

```
/aether/v0.0.0.0/  →  RaBbLE-Aether/dist/
/nebula/v0.0.0.0/  →  RaBbLE-NeBuLA/dist/
/                  →  RaBbLE-World/
```

Running `dev-cdn.js` directly orphans a process on port 8000, causing `dev-serve.sh` to fail with `EADDRINUSE` on the next run. The orphaned server returns 200 OK so the failure is invisible — you just never see source changes reflected.

---

## Dist Files and Git

| Member | `dist/` tracked in git | Reason |
|---|---|---|
| **Aether** | **Yes** | CSS is small (~37kb), human-readable, reviewable in PRs. The dist is the deploy artifact — no build step at deploy time for Aether. |
| **NeBuLA** | **No** (gitignored) | JS bundles are binary-ish, large, and always rebuilt at deploy time. |

Aether's dist being in git means: `wrangler deploy` from World uses whatever is in `RaBbLE-Aether/dist/` at that moment. Run `npm run build:min` in Aether before deploying if source changed.

---

## Versioning

CDN paths follow the Five-Es scheme: `v{Epoch}.{Evolution}.{Echo}.{Episode}`.

**Current:** `v0.0.0.0` — Epoch 0, pre-Episode-1 across all members.

Paths only advance when the corresponding Five-Es milestone is met. Do not increment the version independently per member — all members share the same version clock until Echo 1 ships.

```
v0.0.0.0   →  pre-Episode-1 (now)
v0.0.0.1   →  Episode 1 complete
v0.0.1.0   →  Echo 1 (first big stable release, post several episodes)
```

---

## CDN Delivery — Phase 1 (current)

World's Cloudflare Worker serves Aether and NeBuLA bundles as root-relative paths from within the same deployment. The bundle loaders in World HTML use:

```js
var AETHER_URL = '/aether/v0.0.0.0/aether.css';
var NEBULA_URL = '/nebula/v0.0.0.0/nebula.iife.js';
```

Root-relative means these resolve against `joinrabble.world` — no CORS setup needed, no separate worker, no DNS entry. The CDN content is just files sitting inside the World deploy.

### Preparing a deploy — `cast-cdn.sh`

Before running `wrangler deploy` from World, `cast-cdn.sh` builds both bundles and stages them into World's directory. Git integration in Cloudflare must be disconnected (dashboard only) — wrangler deploys the working directory, not the repo state.

```bash
bash RaBbLE-Grimoire/spells/cast-cdn.sh              # build + stage + deploy
bash RaBbLE-Grimoire/spells/cast-cdn.sh --dry-run    # show what would happen
bash RaBbLE-Grimoire/spells/cast-cdn.sh --skip-build # stage + deploy (dist already built)
bash RaBbLE-Grimoire/spells/cast-cdn.sh --stage-only # build + stage, skip deploy
```

What the spell does:

1. **Build Aether (if changed):** `cd RaBbLE-Aether && npm run build:min`
   - Output: `dist/aether.css`, `dist/aether.min.css`

2. **Build NeBuLA:** `cd RaBbLE-NeBuLA && npm run build`
   - Output: `dist/nebula.iife.js`, `dist/nebula.esm.js`

3. **Stage into World:**
   ```
   RaBbLE-World/
     aether/
       v0.0.0.0/
         aether.css        ← from RaBbLE-Aether/dist/
         aether.min.css    ← from RaBbLE-Aether/dist/
     nebula/
       v0.0.0.0/
         nebula.iife.js    ← from RaBbLE-NeBuLA/dist/
   ```

4. **Deploy:** `cd RaBbLE-World && wrangler deploy`

The `aether/` and `nebula/` directories inside World are **gitignored** — they are staging areas, not part of World's source. Each deploy regenerates them fresh.

Spell lives at `RaBbLE-Grimoire/spells/cast-cdn.sh`.

### World branch strategy

World currently has one branch (`world`) set as the production branch in Cloudflare. For now this is sufficient.

When staging is needed (pre-pilot or before a major release):

| Branch | Cloudflare deployment | Purpose |
|---|---|---|
| `world` | `joinrabble.world` (production) | Live, publicly visible |
| `world-dev` | `dev.joinrabble.world` or workers.dev URL | Staging — test changes before promoting |

Create `world-dev` when friction from deploying directly to production becomes real. Not before.

---

## CDN Delivery — Phase 2 (roadmap, post-Ep2) — SUPERSEDED

> **This unified `cdn.joinrabble.world` design was cancelled.** Per-member subdomains (`aether.joinrabble.world`, `nebula.joinrabble.world`) are the permanent canonical CDN hosts, and they are already live — not a future trigger-based migration. The mechanics below (shared host, path-prefix routing, `aether.cdn.`/`nebula.cdn.` fallback) are retained for historical reference only; they describe a design that was never built and will not be built. Needs a fuller rewrite (follow-up) to replace this section with the actual per-subdomain Worker setup.

A dedicated `cdn.joinrabble.world` Cloudflare Worker serves Aether and NeBuLA independently of World. Each member controls its own CDN deploy.

**What changes:**

1. Loader URLs become absolute:
   ```js
   var AETHER_URL = 'https://cdn.joinrabble.world/aether/v0.0.0.0/aether.css';
   var NEBULA_URL = 'https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.iife.js';
   ```

2. CDN workers add CORS headers:
   ```
   Access-Control-Allow-Origin: https://joinrabble.world
   ```

3. Cloudflare DNS:
   ```
   Type: CNAME
   Name: cdn
   Target: rabble-cdn.workers.dev
   Proxy: ON
   ```

4. Two workers behind `cdn.joinrabble.world`, routed by path prefix:
   - `/aether/*` → `rabble-cdn-aether` worker (static assets from `RaBbLE-Aether/dist/`)
   - `/nebula/*` → `rabble-cdn-nebula` worker (static assets from `RaBbLE-NeBuLA/dist/`)
   - Path-based routing to multiple workers on one subdomain requires **Workers Paid** (Cloudflare Routes). Alternative: use `aether.cdn.joinrabble.world` and `nebula.cdn.joinrabble.world` on the free tier.

**Trigger for Phase 2:** When NeBuLA and Aether have meaningfully different release cadences, or when deploying World and deploying the CDN become a source of friction. Until then, Phase 1 is correct.

---

## Consumer Pattern

Any member HTML page that loads Aether:

```html
<!-- 1. Aether loader — synchronous, no defer -->
<script src="[path/]js/RaBbLE-aether.js"></script>

<!-- 2. Theme alias bridge (World only) -->
<link rel="stylesheet" href="[path/]css/RaBbLE-theme.css">

<!-- 3. Page layout CSS — no visual rules, no hex values -->
<link rel="stylesheet" href="[path/]css/RaBbLE-[page].css">
```

**Do not add a Google Fonts `<link>` in member HTML** — the Aether bundle includes the font import. Adding one creates a duplicate request.

**Do not add Aether classes in page CSS** — if a visual style is missing, add it to `rabble-components.css` in Aether, rebuild, and re-deploy.

---

```
harmonize ~ aether >> build and cdn architecture current as of S12 // %AETHER_BUILD_CURRENT%
```
