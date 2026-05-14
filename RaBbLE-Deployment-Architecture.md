# RaBbLE Deployment Architecture

```
transcribe ~ collective >> deployment strategy, CDN distribution, local dev environment documented // %DEPLOYMENT_ARCHITECTURE%
```

> Aether and NeBuLA are CDN-distributed bundles. World loads them from CDN (local mock in dev, real CDN in prod). This document defines the environments, versioning, and deployment pipeline.

---

## Three Environments

### Local (Dev + Staging)

**Purpose:** Development, testing, integration  
**Aether serving:** http://localhost:8000/aether/v0.0.0.0/  
**NeBuLA serving:** http://localhost:8000/nebula/v0.0.0.0/  
**World:** http://localhost:8000/  

**Setup:**
1. Aether and NeBuLA auto-rebuild on file changes (`npm run build:watch`)
2. Local CDN mock server maps versioned paths to `dist/` directories
3. World HTML (in RaBbLE-World/) loaded directly from filesystem
4. All three run together via `spells/dev-serve.sh`

**Configuration:**
- No auth, no analytics, unminified code with sourcemaps
- CORS open for local testing
- Fast rebuild cycles

**When to use:**
- Feature development in any member
- Integration testing across layers
- Debugging with sourcemaps

---

### Production (Public CDN)

**Purpose:** Live deployment to joinrabble.world  
**Aether distribution:** https://cdn.joinrabble.world/aether/v0.0.0.0/aether.min.css  
**NeBuLA distribution:** https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.iife.js  
**World:** https://joinrabble.world/  

**Assets:**
- Aether: minified CSS bundle (`aether.min.css`) + sourcemap + individual palette files
- NeBuLA: minified JS bundles (IIFE + ESM) + sourcemaps
- World: static HTML, served via Cloudflare Workers

**Deployment pipeline:**
1. Commit changes to Aether / NeBuLA on their respective branches
2. Tag git commit with Five-Es version (e.g., `v0.0.0.0`)
3. Run `npm run build` → produces minified `dist/aether.min.css` or `dist/nebula.iife.js`
4. Run `spells/cast-aether.sh` (for Aether) or equivalent → publishes to CDN
5. CDN routes requests to R2 bucket (or KV storage) based on path + version
6. Cloudflare cache invalidation (if needed)
7. Tag deployment in Grimoire log

**Configuration:**
- Minified, sourcemaps linked (not inlined)
- Analytics enabled, error tracking
- Aggressive cache headers (immutable, 1 year TTL for versioned paths)

**When to use:**
- Ready for public use
- All testing complete
- Episode air ready

**Versioning:**
- Pre-Episode-1: `v0.0.0.0` (Epoch 0, Evolution 0, Echo 0, Episode 0)
- Post-Episode-1 air: `v0.0.0.1` (all three members tagged simultaneously)
- New releases increment Episode or Event level only
- See `RaBbLE-Versioning.md` for full Five-Es spec

---

## CDN Distribution Strategy

### Aether CSS

**Files published to CDN:**
- `aether.min.css` — minified bundle (palette + motion + components)
- `aether.css` — unminified (dev, with sourcemap)
- `rabble-palette.json` — color tokens in JSON
- `rabble-palette.scss` — SCSS variables (for future consumers)
- `rabble-motion.css` — motion keyframes (standalone)
- `rabble-components.css` — component classes (standalone)
- `rabble-portal-glyphs.svg` — logo and glyph assets

**CDN paths:**
```
https://cdn.joinrabble.world/aether/v0.0.0.0/aether.min.css
https://cdn.joinrabble.world/aether/v0.0.0.0/rabble-palette.json
https://cdn.joinrabble.world/aether/v0.0.0.0/rabble-portal-glyphs.svg
...
```

**Consumption:**
```html
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0.0/aether.min.css">
```

### NeBuLA JavaScript

**Files published to CDN:**
- `nebula.iife.js` — minified IIFE bundle (browser global: `window.NeBuLA`)
- `nebula.iife.js.map` — sourcemap
- `nebula.esm.js` — ES module format (for bundlers)
- `nebula.esm.js.map` — sourcemap

**CDN paths:**
```
https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.iife.js
https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.esm.js
```

**Consumption (IIFE):**
```html
<script src="https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.iife.js"></script>
<script>
  const puppet = window.NeBuLA.createPuppet({ canvas, ... });
</script>
```

**Consumption (ESM, in bundler):**
```javascript
import { createPuppet } from 'https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.esm.js';
```

### World HTML

**Files:**
- `index.html` — landing page
- `world/RaBbLE-Boot.html` — boot sequence
- `world/RaBbLE-Chat.html` — chat surface
- `world/RaBbLE-OS.html` — OS documentation
- All CSS and JS (no external build)

**Served via:** Cloudflare Workers  
**CDN path:** https://joinrabble.world/

**Each page loads Aether + NeBuLA from versioned CDN paths:**
```html
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0.0/aether.min.css">
<script src="https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.iife.js"></script>
```

---

## Cloudflare Configuration

### Workers + R2 (Recommended)

**R2 buckets:**
- `cdn.joinrabble.world/aether/` — Aether CSS and assets
- `cdn.joinrabble.world/nebula/` — NeBuLA JS bundles
- `joinrabble.world/` — World HTML and static assets

**Worker route:** `cdn.joinrabble.world/*` → R2 bucket `cdn.joinrabble.world`  
**Worker route:** `joinrabble.world/*` → R2 bucket `joinrabble.world` (or Workers KV)

**Cache configuration:**
```
/aether/v*/*         → 1 year (immutable, versioned)
/nebula/v*/*         → 1 year (immutable, versioned)
/                     → 1 hour (html, changes often)
```

### wrangler.toml Configuration

See `wrangler.jsonc` template below for example environment-specific setup.

```jsonc
{
  "name": "rabble-collective",
  "compatibility_date": "2026-05-06",
  "compatibility_flags": ["nodejs_compat"],
  
  "env": {
    "production": {
      "name": "rabble-collective",
      "route": "joinrabble.world/*",
      "zone_id": "{{ CLOUDFLARE_ZONE_ID }}"
    },
    "local": {
      "name": "rabble-collective-dev",
      "route": "http://localhost:8000/*"
    }
  },
  
  "r2_buckets": [
    { "binding": "CDN_AETHER", "bucket_name": "cdn.joinrabble.world", "preview_bucket_name": "cdn-dev" },
    { "binding": "CDN_NEBULA", "bucket_name": "cdn.joinrabble.world", "preview_bucket_name": "cdn-dev" },
    { "binding": "WORLD_STATIC", "bucket_name": "joinrabble.world", "preview_bucket_name": "world-dev" }
  ],
  
  "observability": {
    "enabled": true
  }
}
```

### Deployment Steps

1. **Build locally:**
   ```bash
   cd RaBbLE-Aether && npm run build
   cd ../RaBbLE-NeBuLA && npm run build
   ```

2. **Publish to R2 (via cast-aether or equivalent):**
   ```bash
   spells/cast-aether.sh        # Aether → CDN
   # (NeBuLA has similar deploy script when created)
   ```

3. **Deploy World via Wrangler:**
   ```bash
   cd RaBbLE-World
   wrangler deploy --env production
   ```

4. **Tag release in git:**
   ```bash
   git tag -a v0.0.0.0 -m "Episode 1 pre-air release"
   git push origin v0.0.0.0
   ```

5. **Log deployment in Grimoire:**
   ```
   echo "v0.0.0.0 deployed to production" >> RaBbLE-Grimoire/log/DEPLOYMENT-LOG.md
   ```

---

## Local Development Workflow

### Quick Start

```bash
cd ~/RaBbLE && spells/dev-serve.sh
```

This launches:
1. Aether watcher (`npm run build:watch`)
2. NeBuLA watcher (`npm run build:dev` — or equivalent if no watch target)
3. Local CDN mock server on http://localhost:8000
4. Opens browser to http://localhost:8000

### Manual Setup (if you prefer separate terminals)

**Terminal 1 — Aether:**
```bash
cd RaBbLE-Aether && npm run build:watch
```

**Terminal 2 — NeBuLA:**
```bash
cd RaBbLE-NeBuLA && npm run build:watch  # if available, else: npm run build:dev
```

**Terminal 3 — Local server:**
```bash
cd RaBbLE-Collective && python3 -m http.server 8000 --directory .
# or: node spells/dev-cdn.js
```

Then open http://localhost:8000/index.html and navigate to pages.

**Note:** World pages must reference local CDN paths during dev:
```html
<!-- In dev, use local CDN mock -->
<link rel="stylesheet" href="http://localhost:8000/aether/v0.0.0.0/aether.min.css">
<script src="http://localhost:8000/nebula/v0.0.0.0/nebula.iife.js"></script>

<!-- In prod, use public CDN -->
<!-- <link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0.0/aether.min.css"> -->
```

Or use a simple templating approach: environment variable injected at build time.

---

## Future: RaBbLE-DeploymentWrangler

When deployment complexity grows (multi-environment, secrets, workflow automation), create a dedicated member:
- `RaBbLE-DeploymentWrangler/` — Wrangler configs, deploy scripts, CI/CD pipeline
- Spells in Grimoire remain simple coordination helpers
- Wrangler repo handles credential rotation, environment promotion, rollback

---

```
transcribe ~ collective >> deployment architecture complete, ready for implementation // %DEPLOYMENT_READY%
```
