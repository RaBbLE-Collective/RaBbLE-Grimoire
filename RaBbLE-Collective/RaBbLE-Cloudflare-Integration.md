# Cloudflare Integration — CDN + Static Hosting

```
transcribe ~ collective >> cloudflare integration, cdn pipeline, deployment strategy documented // %CLOUDFLARE_INTEGRATION%
```

> This document describes how to configure Cloudflare to serve Aether CSS and NeBuLA JS bundles as a public CDN, while hosting World HTML pages via Cloudflare Workers.

---

> **SUPERSEDED — the unified `cdn.joinrabble.world` design described in this entire document was cancelled.** Per-member subdomains (`aether.joinrabble.world`, `nebula.joinrabble.world`) are the permanent canonical CDN hosts, and are already live — there is no shared `cdn.` domain, no `cdn-rabble-prod` / `cdn-rabble-staging` R2 bucket pair, and no path-prefix (`/aether/*`, `/nebula/*`) routing on a combined host. Each member deploys to its own subdomain Worker directly (see `RaBbLE-Deployment-Architecture.md` § Subdomain Map, and `spells/cloudflare-ctl.sh`'s `deploy`/`domain` commands for the actual live tooling). This document is retained for historical reference only and needs a fuller rewrite (follow-up) rather than a line-by-line fix.

---

## Overview

**Setup:**
- **Domain:** `joinrabble.world` (main site + API gateway)
- **CDN domain:** `cdn.joinrabble.world` (asset distribution)
- **Hosting:** Cloudflare Workers (static site generator for World)
- **Storage:** R2 buckets (backend for CDN assets and World pages)

**Architecture:**
```
                        ┌─────────────────────────┐
                        │  Aether (CSS Bundles)   │
                        │  NeBuLA (JS Bundles)    │
                        │  World (HTML Pages)     │
                        │      local repos        │
                        └────────────┬────────────┘
                                     │
                                  build ↓
                                     │
                    ┌────────────────┴───────────────┐
                    │                                │
        ┌───────────▼──────────────┐    ┌────────────▼─────────────┐
        │  R2 Bucket: cdn-prod     │    │  R2 Bucket: world-prod   │
        │  - aether/*.css          │    │  - index.html            │
        │  - nebula/*.js           │    │  - world/*.html          │
        │  - *.json, *.svg         │    │  - world/css/            │
        │  (versioned paths)       │    │  - world/js/             │
        └───────────┬──────────────┘    └────────────┬─────────────┘
                    │                                │
    ┌───────────────▼────────────────────────────────▼─────────────┐
    │                  Cloudflare Edge (Global)                     │
    │                                                               │
    │  Route: cdn.joinrabble.world/*    → R2: cdn-prod            │
    │  Route: joinrabble.world/*        → R2: world-prod          │
    │                                                               │
    │  Cache Policy:                                               │
    │    /aether/v*/* and /nebula/v*/   → 1 year (immutable)     │
    │    /index.html, /world/*          → 1 hour (dynamic)       │
    └───────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

1. **Cloudflare account** with domain `joinrabble.world` registered
2. **Domain nameservers** pointing to Cloudflare (already configured by registrar setup)
3. **Wrangler CLI** installed locally:
   ```bash
   npm install -g wrangler
   ```
4. **Cloudflare API token** with R2 and Workers permissions (create in Dashboard → Settings → API Tokens)

---

## Step 1: Create R2 Buckets

### In Cloudflare Dashboard

1. Go to **R2** → **Create bucket**
2. Create bucket: `cdn-rabble-prod`
   - Region: auto-select (or pick closest to you)
   - Public or private (typically private, serve via Workers)
3. Create bucket: `world-rabble-prod`
   - Same region
   - This holds World HTML pages

### Or via Wrangler CLI

```bash
wrangler r2 bucket create cdn-rabble-prod
wrangler r2 bucket create world-rabble-prod
```

---

## Step 2: Configure Wrangler Locally

In `RaBbLE-World/wrangler.jsonc`, add environment blocks:

```jsonc
{
  "name": "rabble-collective",
  "compatibility_date": "2026-05-06",
  "compatibility_flags": ["nodejs_compat"],

  "observability": { "enabled": true },

  "env": {
    "production": {
      "name": "rabble-prod",
      "routes": [
        {
          "pattern": "cdn.joinrabble.world/*",
          "zone_id": "{{ CLOUDFLARE_ZONE_ID }}"
        },
        {
          "pattern": "joinrabble.world/*",
          "zone_id": "{{ CLOUDFLARE_ZONE_ID }}"
        }
      ]
    }
  },

  "r2": {
    "buckets": [
      {
        "binding": "CDN",
        "bucket_name": "cdn-rabble-prod"
      },
      {
        "binding": "WORLD",
        "bucket_name": "world-rabble-prod"
      }
    ]
  }
}
```

Find your Cloudflare **Zone ID** in Dashboard → Sites → joinrabble.world → Overview (right sidebar).

---

## Step 3: Authenticate Wrangler

```bash
wrangler login
# Opens browser for OAuth authorization
# Returns: ✓ Successfully authenticated with Cloudflare!
```

This stores credentials in `~/.wrangler/config.toml` (local only).

---

## Step 4: Build and Deploy

### 4a. Build Aether CSS

```bash
cd RaBbLE-Aether
npm install  # if not already installed
npm run build
```

Output: `dist/aether.min.css` (minified) + sourcemap

### 4b. Build NeBuLA JS

```bash
cd RaBbLE-NeBuLA
npm install  # if not already installed
npm run build
```

Output: `dist/nebula.iife.js` and `dist/nebula.esm.js` (both minified + sourcemaps)

### 4c. Push CDN Assets to R2

Run the cast-aether spell from Grimoire root:

```bash
bash RaBbLE-Grimoire/spells/cast-aether.sh
```

This copies:
- Aether CSS bundles → `cdn-rabble-prod/aether/v0.0.0.0/`
- NeBuLA JS bundles → `cdn-rabble-prod/nebula/v0.0.0.0/`
- Supporting files (palette.json, SVG logos) → versioned paths

**Manual alternative** (if cast-aether not configured):
```bash
# Using wrangler R2 API
wrangler r2 object upload --bucket=cdn-rabble-prod RaBbLE-Aether/dist/aether.min.css aether/v0.0.0.0/aether.min.css

wrangler r2 object upload --bucket=cdn-rabble-prod RaBbLE-NeBuLA/dist/nebula.iife.js nebula/v0.0.0.0/nebula.iife.js
```

### 4d. Deploy World HTML Pages

```bash
cd RaBbLE-World
wrangler deploy --env production
```

This publishes the World pages from `RaBbLE-World/` to the Workers route.

---

## Step 5: Verify CDN Availability

```bash
# CSS bundle
curl -I https://cdn.joinrabble.world/aether/v0.0.0.0/aether.min.css

# JS bundle
curl -I https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.iife.js

# World landing
curl -I https://joinrabble.world/
```

All should return **HTTP 200** with appropriate `Content-Type` headers.

---

## Step 6: Update World Pages to Use Public CDN

In `RaBbLE-World/index.html` and other pages, change CDN URLs from local to production:

```html
<!-- BEFORE (local dev) -->
<link rel="stylesheet" href="http://localhost:8000/aether/v0.0.0.0/aether.min.css">
<script src="http://localhost:8000/nebula/v0.0.0.0/nebula.iife.js"></script>

<!-- AFTER (production) -->
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0.0/aether.min.css">
<script src="https://cdn.joinrabble.world/nebula/v0.0.0.0/nebula.iife.js"></script>
```

---

## Workflow: Updating Bundles

When you modify Aether or NeBuLA and want to push a new version:

1. **Increment version** in package.json (Five-Es):
   ```json
   "version": "0.0.0.1"  // Episode 1 air
   ```

2. **Build:**
   ```bash
   cd RaBbLE-Aether && npm run build
   cd RaBbLE-NeBuLA && npm run build
   ```

3. **Cast to CDN** (or manually upload):
   ```bash
   bash RaBbLE-Grimoire/spells/cast-aether.sh  # Aether
   # (equivalent for NeBuLA when script is created)
   ```

4. **Update World HTML** to reference new version:
   ```html
   <link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0.1/aether.min.css">
   <script src="https://cdn.joinrabble.world/nebula/v0.0.0.1/nebula.iife.js"></script>
   ```

5. **Redeploy World:**
   ```bash
   cd RaBbLE-World && wrangler deploy --env production
   ```

6. **Tag release** in git:
   ```bash
   git tag -a v0.0.0.1 -m "Episode 1 air release"
   git push origin v0.0.0.1
   ```

---

## Cache Configuration

Cloudflare automatically caches based on file type and path:

| Path | TTL | Cache Key |
|---|---|---|
| `/aether/v0.0.0.0/*.css` | 1 year | Full URL (immutable, version in path) |
| `/nebula/v0.0.0.0/*.js` | 1 year | Full URL (immutable, version in path) |
| `/index.html` | 1 hour | URL only |
| `/world/*.html` | 1 hour | URL only |

**To force cache invalidation** after deployment:
```bash
# Clear all cache for domain
wrangler cache purge https://joinrabble.world/*

# Or via Dashboard: Caching → Purge Cache
```

---

## Development: Local vs. Production URLs

Use environment variables to switch between local and production CDN:

**In `RaBbLE-World/world/js/config.js` (or equivalent):**
```javascript
const CDN_BASE = process.env.NODE_ENV === 'production'
  ? 'https://cdn.joinrabble.world'
  : 'http://localhost:8000';

const AETHER_URL = `${CDN_BASE}/aether/v0.0.0.0/aether.min.css`;
const NEBULA_URL = `${CDN_BASE}/nebula/v0.0.0.0/nebula.iife.js`;

export { AETHER_URL, NEBULA_URL };
```

Then in HTML pages:
```html
<link rel="stylesheet" id="aether-css">
<script src id="nebula-js"></script>

<script type="module">
  import { AETHER_URL, NEBULA_URL } from './config.js';
  document.getElementById('aether-css').href = AETHER_URL;
  document.getElementById('nebula-js').src = NEBULA_URL;
</script>
```

Or simpler: keep two versions of HTML (dev/prod) and deploy the right one.

---

## Troubleshooting

### "Could not authenticate with Cloudflare"
```bash
wrangler logout
wrangler login
```

### "Bucket not found"
```bash
# List existing buckets
wrangler r2 bucket list

# Create missing bucket
wrangler r2 bucket create cdn-rabble-prod
```

### "Zone ID invalid"
Find your zone ID in Cloudflare Dashboard:
- Sites → joinrabble.world → Overview
- Look for "Zone ID" on right sidebar
- Update `wrangler.jsonc` with correct ID

### Assets not updating
Clear Cloudflare cache:
```bash
wrangler cache purge https://cdn.joinrabble.world/*
```

Or wait for TTL to expire (check cache headers with `curl -I`).

---

## Staging Environment — dev.joinrabble.world

> Canonical staging subdomain is **`dev.joinrabble.world`** (not `staging.`). Full definition: `RaBbLE-Deployment-Architecture.md` → *Staging / Preview*.

When ready to test before production:

1. Add a `dev` (preview) environment block to the World `wrangler.jsonc` with route `dev.joinrabble.world/*`
2. (Optional) staging R2 prefix only if staging needs its own bundles — otherwise reuse versioned `cdn.joinrabble.world` paths (RCs are isolated by version)
3. Deploy to the staging route: `wrangler deploy --env dev`
4. Test at `https://dev.joinrabble.world/` (recommend Cloudflare Access gating + `noindex`)
5. Promote to production when validated

---

```
transcribe ~ collective >> cloudflare live, cdn active, world hosted // %CLOUDFLARE_LIVE%
```
