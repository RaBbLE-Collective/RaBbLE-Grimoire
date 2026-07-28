# Episode 1 Deployment Runbook

> Complete guide to deploying World, NeBuLA, and Aether to Cloudflare on episode tag.
> When you `git tag v0.0.0.1 && git push --tags`, everything deploys automatically.

---

> **SUPERSEDED — the unified `cdn.joinrabble.world` + R2 deployment path described in this document was cancelled.** Per-member subdomains (`aether.joinrabble.world`, `nebula.joinrabble.world`) are the permanent canonical CDN hosts, already live. There is no shared `cdn.` domain, no R2 bucket upload step, and no path-based (`/aether/*`, `/nebula/*`) cache purge on a combined zone — each member deploys straight to its own subdomain Worker (see `RaBbLE-Deployment-Architecture.md` § Subdomain Map and `spells/cloudflare-ctl.sh`). This document is retained for historical reference only and needs a fuller rewrite (follow-up).

---

## What This Does

| Repo | Trigger | Deploy Target | Result |
|---|---|---|---|
| RaBbLE-World | Tag `v0.0.0.1` | Cloudflare Workers | https://joinrabble.world/ |
| RaBbLE-NeBuLA | Tag `v0.0.0.1` | R2 CDN | https://cdn.joinrabble.world/nebula/v0.0.0.1/ |
| RaBbLE-Aether | Tag `v0.0.0.1` | R2 CDN | https://cdn.joinrabble.world/aether/v0.0.0.1/ |

Each repo has its own GitHub Actions workflow. When you tag, that workflow runs independently.

---

## Prerequisites

### 1. Cloudflare Account Setup

**Already done if:**
- You own `joinrabble.world` domain
- Domain nameservers point to Cloudflare

**If not, set up now:**
- Go to https://dash.cloudflare.com
- Add site → enter `joinrabble.world`
- Follow instructions to update domain nameservers at registrar

---

### 2. Create Cloudflare API Token

This allows GitHub Actions to upload files to R2 and deploy Workers.

**Steps:**

1. Go to **Cloudflare Dashboard** → **My Profile** (top right) → **API Tokens**
2. Click **Create Token**
3. Choose template: **Edit Cloudflare Workers**
   - Or customize with these permissions:
     - R2 → Edit (to upload NeBuLA/Aether bundles)
     - Cloudflare Workers → Edit (to deploy World)
     - Zone → Edit (cache purge, if needed)
4. Account resources: **All accounts**
5. Zone resources: **All zones** (or just joinrabble.world)
6. Copy the token → **Save it somewhere safe** (you'll need it in a moment)

**Your token looks like:** `v1.0c3fbc24...` (long string)

---

### 3. Create R2 Buckets

R2 is Cloudflare's object storage. NeBuLA and Aether bundles live here.

**Option A: Via Cloudflare Dashboard (easiest for first time)**

1. Go to **R2** in dashboard
2. Click **Create Bucket**
3. Name: `rabble-cdn-prod`
   - Region: auto-select
   - Public access: **OFF** (Cloudflare will serve via Workers)
4. Create second bucket: `rabble-world-prod`
   - Same settings

**Option B: Via Wrangler CLI (faster)**

```bash
wrangler r2 bucket create rabble-cdn-prod
wrangler r2 bucket create rabble-world-prod
```

---

### 4. Create Cloudflare Worker (for World)

World is deployed via Workers. If you already deployed World to Cloudflare, this exists. If not:

```bash
cd RaBbLE-World
wrangler init
# Answer prompts:
#   name: rabble-world
#   type: "Hello World" script
#   git: yes (optional)
```

Then update `wrangler.toml`:

```toml
name = "rabble-world"
type = "javascript"
account_id = "YOUR_CLOUDFLARE_ACCOUNT_ID"  # from https://dash.cloudflare.com/
workers_dev = false
route = "joinrabble.world/*"
zone_id = "YOUR_ZONE_ID"  # domain zone, from https://dash.cloudflare.com/

[env.production]
vars = { ENVIRONMENT = "production" }
```

Get your IDs:
- **account_id**: Dashboard → Settings → copy "Account ID"
- **zone_id**: Dashboard → select joinrabble.world → Overview → copy "Zone ID"

Deploy once manually to ensure it works:
```bash
wrangler deploy
```

---

## GitHub Actions Setup

Each repo needs a deployment workflow. These trigger on git tags matching `v*` (e.g., `v0.0.0.1`).

### Add to Each Repo:

Create `.github/workflows/deploy.yml` in each repo.

---

## 1. RaBbLE-World Deploy Workflow

**File:** `RaBbLE-World/.github/workflows/deploy.yml`

```yaml
name: Deploy to Cloudflare Workers

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Deploy to Cloudflare Workers
        run: npx wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

---

## 2. RaBbLE-NeBuLA Deploy Workflow

**File:** `RaBbLE-NeBuLA/.github/workflows/deploy.yml`

```yaml
name: Deploy to Cloudflare R2

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Get version from tag
        id: tag
        run: echo "version=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
      
      - name: Upload to R2
        run: |
          npm install -g wrangler
          
          wrangler r2 object upload \
            --bucket=rabble-cdn-prod \
            dist/nebula.iife.js \
            nebula/${{ steps.tag.outputs.version }}/nebula.iife.js
          
          wrangler r2 object upload \
            --bucket=rabble-cdn-prod \
            dist/nebula.iife.js.map \
            nebula/${{ steps.tag.outputs.version }}/nebula.iife.js.map
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
      
      - name: Purge Cloudflare cache
        run: |
          curl -X POST "https://api.cloudflare.com/client/v4/zones/${{ secrets.CLOUDFLARE_ZONE_ID }}/purge_cache" \
            -H "Authorization: Bearer ${{ secrets.CLOUDFLARE_API_TOKEN }}" \
            -H "Content-Type: application/json" \
            --data '{"files":["https://cdn.joinrabble.world/nebula/*"]}'
```

---

## 3. RaBbLE-Aether Deploy Workflow

**File:** `RaBbLE-Aether/.github/workflows/deploy.yml`

```yaml
name: Deploy to Cloudflare R2

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Get version from tag
        id: tag
        run: echo "version=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
      
      - name: Upload to R2
        run: |
          npm install -g wrangler
          
          for file in dist/*; do
            filename=$(basename "$file")
            wrangler r2 object upload \
              --bucket=rabble-cdn-prod \
              "$file" \
              "aether/${{ steps.tag.outputs.version }}/$filename"
          done
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
      
      - name: Purge Cloudflare cache
        run: |
          curl -X POST "https://api.cloudflare.com/client/v4/zones/${{ secrets.CLOUDFLARE_ZONE_ID }}/purge_cache" \
            -H "Authorization: Bearer ${{ secrets.CLOUDFLARE_API_TOKEN }}" \
            -H "Content-Type: application/json" \
            --data '{"files":["https://cdn.joinrabble.world/aether/*"]}'
```

---

## Add Secrets to GitHub

For each repo, add these secrets so workflows can authenticate to Cloudflare.

**Steps (do this for all 3 repos):**

1. Go to repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these secrets:

| Name | Value | Where to find |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Your API token from step 1 | Cloudflare Dashboard → API Tokens |
| `CLOUDFLARE_ACCOUNT_ID` | Your account ID | Cloudflare Dashboard → Settings → Account ID |
| `CLOUDFLARE_ZONE_ID` | Zone ID for joinrabble.world | Cloudflare Dashboard → joinrabble.world → Overview → Zone ID |

---

## Testing the Pipeline

### Manual Test (before tagging)

**Test NeBuLA workflow locally:**
```bash
cd RaBbLE-NeBuLA
npm install
npm run build
# Check dist/ has your bundles
```

**Test Aether workflow locally:**
```bash
cd RaBbLE-Aether
npm install
npm run build
# Check dist/ has your CSS
```

**Test World locally:**
```bash
cd RaBbLE-World
npm install
npm run build
wrangler deploy --dry-run
```

### Trigger Deployment

Once workflows are in place and secrets are added:

```bash
# In RaBbLE-NeBuLA repo
git tag v0.0.0.1
git push origin v0.0.0.1

# Check GitHub Actions → Deploy workflow running
# Tail logs to see upload progress
```

After a few seconds, your bundle will be at:
- https://cdn.joinrabble.world/nebula/v0.0.0.1/nebula.iife.js

---

## Cloudflare Workers Route Configuration

Once deployed, point the route to the Worker:

1. Cloudflare Dashboard → joinrabble.world → Workers
2. Click your worker → **Routes**
3. Add route: `joinrabble.world/*` → Worker: `rabble-world`
4. Repeat for `www.joinrabble.world/*`

---

## What's at Each URL

After deployment:

```
https://joinrabble.world/
  ↓ (served by Cloudflare Workers)
  Your World HTML (from RaBbLE-World)

https://cdn.joinrabble.world/nebula/v0.0.0.1/nebula.iife.js
  ↓ (served from R2 bucket)
  NeBuLA JavaScript bundle

https://cdn.joinrabble.world/aether/v0.0.0.1/aether.min.css
  ↓ (served from R2 bucket)
  Aether CSS bundle
```

World HTML references them:
```html
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0.1/aether.min.css">
<script src="https://cdn.joinrabble.world/nebula/v0.0.0.1/nebula.iife.js"></script>
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Workflow fails with "API token invalid" | Check `CLOUDFLARE_API_TOKEN` secret is correct (copy fresh from dashboard) |
| R2 upload fails | Ensure `rabble-cdn-prod` bucket exists; check bucket name in workflow |
| Workers deploy fails | Verify `wrangler.toml` has correct `account_id` and `zone_id` |
| Bundle not at URL | Check R2 bucket has the files; may take a few seconds to propagate |

---

## Summary

When you tag a commit:
```bash
git tag v0.0.0.1
git push --tags
```

GitHub Actions automatically:
1. Pulls the code
2. Builds the project
3. Uploads to Cloudflare (R2 or Workers)
4. Clears Cloudflare cache
5. Bundles are live at versioned URLs forever

No manual steps. No build server. Just `git tag` and deploy.
