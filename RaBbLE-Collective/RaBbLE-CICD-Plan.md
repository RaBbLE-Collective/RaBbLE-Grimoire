# RaBbLE CI/CD Plan

```
spark ~ collective >> CI/CD pipelines, API key vault, logs intake // %CICD_PLAN%
```

> Automated deploy pipeline for all Collective members. EP1 scope: push-to-main + tag-triggered deploys. EP2 scope: staging environment, two-step tag promotion.

---

## EP1 Scope (current)

| Member | Platform | Trigger | Status |
|---|---|---|---|
| RaBbLE-World | Cloudflare Workers (`wrangler deploy`) | push to main + v* tags | workflow created |
| RaBbLE-Aether | Cloudflare Workers (`wrangler deploy`) | push to main + v* tags | workflow updated (was R2) |
| RaBbLE-NeBuLA | Cloudflare Workers (`wrangler deploy`) | push to main + v* tags | workflow created |
| RaBbLE-sCoRE CF Proxy | Cloudflare Workers (`wrangler deploy`) | push to main + v* tags | workflow created |
| RaBbLE-sCoRE Render | Render native auto-deploy | push to main | **manual: enable in Render dashboard** |

---

## GitHub Secrets Required (per CF member repo)

Set once per repo via `cloudflare-ctl.sh secrets-setup <member>` or manually in repo Settings → Secrets:

| Secret | Value source |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token with Workers:Edit permission |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID |

> `CLOUDFLARE_ZONE_ID` was previously needed for R2 cache purge. No longer required — Workers deployments invalidate automatically.

---

## Render Auto-Deploy (one-time dashboard step)

Render natively auto-deploys from GitHub when connected. The `render.yaml` is already correct. Steps:

1. Open [dashboard.render.com](https://dashboard.render.com) → `RaBbLE-sCoRE` service
2. Settings → **Auto-Deploy** → set to **Yes**
3. Confirm the tracked branch is `main`

After this, every push to `main` in `RaBbLE-sCoRE` triggers a Render deploy. No workflow file needed — Render handles it.

---

## Workflow Pattern (CF Workers)

All four CF workflows share the same shape:

```yaml
on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # [build step for Aether/NeBuLA only]
      - run: npx wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

Members with a build step (Aether, NeBuLA) run `npm ci && npm run build` before `wrangler deploy`. Members without (World, sCoRE proxy) deploy directly.

---

## API Key Management (EP1)

**Current flow:**
1. Keys stored in `RaBbLE-sCoRE/server/.env` (gitignored, local machine)
2. Push to Render: `bash spells/render-ctl.sh env-sync`
3. Push to GitHub secrets: `bash spells/cloudflare-ctl.sh secrets-setup <member>`

**Gap:** keys are plaintext in `.env`. SOPS/age vault is the EP2 upgrade path.

**EP1 discipline until vault is built:**
- Never commit `.env` (already gitignored)
- Use `render-ctl.sh env-set <KEY> <val>` to set individual keys without touching `.env`
- Use `render-ctl.sh env-show` to audit what's live on Render

---

## sCoRE Logs + Insight Intake (EP1)

**Existing:** `bash spells/render-ctl.sh logs [N]` — fetches last N lines from Render.

**Missing:** scheduled intake agent that extracts conversation insights and promotes them.

Planned spell: `spells/logs-intake.sh`

```
bash spells/logs-intake.sh          # pull last 500 lines, extract insights, print summary
bash spells/logs-intake.sh --promote # also call promote-insight.sh for each flagged insight
```

Intake logic:
1. Pull Render logs via `render-ctl.sh logs 500`
2. Filter for lines containing `user_message` / `assistant_message` / `intent`
3. Extract conversation turns into a temp file
4. Summarize via sCoRE or local LLM
5. Flagged insights → `promote-insight.sh`

Scheduling options:
- **Local cron (RaBbLE-OS):** `crontab -e` → run every 6h, results to `~/RaBbLE-Captures/logs-intake/`
- **Cloudflare Worker cron trigger (EP2):** schedule a Worker that calls Render API and writes to R2

---

## EP2 Goals (not in scope now)

- **Staging environment:** World preview deploys on PR open; Aether/NeBuLA staged at `v*-rc.*` tags
- **Two-step promotion:** push to main → staging; v* tag → prod (currently both go to prod)
- **SOPS/age vault:** `secrets-ctl.sh set/sync` wraps age encryption; `.secrets/` dir in Grimoire
- **Secrets rotation:** automated via `render-ctl.sh env-set` + key expiry tracking
- **Cloudflare Worker cron** for logs intake (replaces local cron)
