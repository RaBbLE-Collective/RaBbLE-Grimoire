# HANDOFF — B-10: Cloudflare API token for CI deploys

```
written: S203 (2026-07-14) | blocker: B-10 (log/BLOCKERS.md) | owner: Mark (token mint is dashboard-only)
```

**Goal:** every member repo's GitHub Actions deploy job can run `wrangler deploy` — which
requires a `CLOUDFLARE_API_TOKEN` secret. Once set, B-10 closes and dev.joinrabble.world
auto-deploy (plus the A5 Chrysalis pipeline) unblocks.

## State of play (verified S203)

- **No API token exists anywhere on the local system.** Checked: `~/.config/.wrangler/config/default.toml`,
  shell rc files, live env, every `.env` in the Collective (only sCoRE has one; no CF entries).
- **Local wrangler works via OAuth, not a key** — `oauth_token` + `refresh_token` pair in
  `~/.config/.wrangler/config/default.toml` from the browser login as rabblecollective@proton.me.
  Access token auto-refreshes hourly. Useless for CI: short-lived, interactive-session-bound, and its
  scopes (`account:read, user:read, workers:*`) exclude `API Tokens: Edit` — so a proper token
  **cannot be minted from the CLI**. Dashboard is the only path.
- **A June token exists but may be lost.** `CLOUDFLARE_API_TOKEN` was set on the RaBbLE-Aether repo
  2026-06-11. GitHub secrets are write-only — it cannot be read back. If it's in Mark's password
  manager, reuse it; if not, it's unrecoverable (mint fresh, revoke the June one).
- **Account:** `0391968396156c874398a9696e0b3598` (rabblecollective@proton.me).
- **Org:** GitHub org `RaBbLE-Collective` holds World/Aether/NeBuLA/sCoRE/Grimoire.
  **RaBbLE-Chrysalis is still under `markm1206`** (transfer pending) — org secrets won't reach it.

## Steps (Mark)

1. **Mint (or retrieve) the token.**
   Dashboard: dash.cloudflare.com → My Profile → API Tokens → Create Token →
   template **"Edit Cloudflare Workers"** → scope to account `0391...3598` → create.
   Save it in the password manager immediately (it displays once).
2. **Set it org-wide** (prompts for the value — keeps it out of shell history):
   ```bash
   gh secret set CLOUDFLARE_API_TOKEN --org RaBbLE-Collective --visibility all
   ```
3. **Chrysalis (outside the org)** — per-repo until transferred:
   ```bash
   gh secret set CLOUDFLARE_API_TOKEN -R markm1206/RaBbLE-Chrysalis
   ```
4. **Hygiene:** re-set the same token on Aether (repo-level secret shadows nothing, but one live
   token beats two); revoke the June token in the dashboard if it can't be found.

## Verify

```bash
gh secret list --org RaBbLE-Collective            # CLOUDFLARE_API_TOKEN listed
gh workflow run deploy.yml -R RaBbLE-Collective/RaBbLE-World   # or push to the deploy branch
gh run watch -R RaBbLE-Collective/RaBbLE-World    # deploy-dev job green
curl -sI https://dev.joinrabble.world | head -1   # 200
```

## Then

- Mark B-10 resolved in `log/BLOCKERS.md`.
- Unblocked follow-on (agent work, plan A5 in `log/plans/EP1-Air-Push-Plan.md`): Chrysalis
  `deploy.yml` + chrysalis.joinrabble.world binding, all-members CI audit, `spells/deploy.sh` wrapper,
  key inventory alongside `RaBbLE-Secrets-and-Identity.md`.
- Move this file to `log/handoffs/done/` and update `INDEX.md` + `log/handoffs/CONTEXT.md`.
