# sCoRE Storage Gate Plan

```
status: 🔵 design only, nothing built · S327 · 2026-11-11 · owner: sCoRE (server) + Grimoire (spells)
```

## Mission

R2 object storage is reached only through sCoRE, and RaBbLE never makes a billable request.
User-facing data is proxied and counted by sCoRE. Public bundles stay cached and never reach R2.
Every layer refuses service before a free-tier limit becomes a bill.

## Facts this plan rests on

- **R2 pricing** (developers.cloudflare.com/r2/pricing, updated 2026-10-30). Free each month, Standard class only:
  10 GB-month storage, 1M Class A (writes, lists), 10M Class B (reads), egress free.
  After that: $0.015/GB-month, $4.50/M A, $0.36/M B. Deletes and aborted uploads are free.
  **Requests that fail authentication or authorization are not billed.**
- **No hard cap exists on R2.** Budget alerts (Billing > Billable Usage) only send an email. Threshold billing only invoices mid-cycle.
  The stop has to be ours.
- **WAF rate limiting, Free plan** (developers.cloudflare.com/waf/rate-limiting-rules): 1 rule, counts per IP only,
  10 s window, 10 s mitigation, path match only (no query string).
- **Portability:** R2 speaks the S3 API, and leaving it is cheap because egress is free (`rclone sync`).
  The lock-in to avoid is Workers bindings, the Cloudflare REST object API and `*.r2.dev` URLs.

## What exists today (checked S327)

| Thing | Where | State |
|---|---|---|
| Aether and NeBuLA CDN | `spells/publish-cdn.sh` → Cloudflare **Pages** (`aether.` and `nebula.joinrabble.world/<ver>/`) | Live. **Not R2.** Static asset requests are served from Pages, so no R2 ops are spent |
| sCoRE transcripts | `RaBbLE-sCoRE/server/transcripts.py` | Writes to R2 (`TRANSCRIPT_BACKEND=r2`) through the **Cloudflare REST API** with a bearer token, file fallback. Write-only, no counting |
| Pocket firmware | `RaBbLE-Pocket/companion-app/web/wrangler.jsonc` | Worker reads private bucket `rabble-pocket-firmware` through a **Workers binding** (`FIRMWARE`). Not deployed |
| Older memory `project_deployment_architecture` | memory only | Describes an R2 `cdn-rabble-prod` bucket. **Superseded** by the Pages path above |

## Locked decisions (Mark, S327)

1. **sCoRE is the main R2 user.** User-facing R2 data goes through a sCoRE proxy, never public.
2. **Proxy, not presigned URLs.** sCoRE streams the bytes and counts every R2 call itself.
3. **CDN is covered by cache.** Clients request the whole versioned bundle, query strings are ignored.
   The analytics kill switch is the backstop only.
4. **Rate limits so no single endpoint or client can hammer us.**

## Design

### Tier 1: the sCoRE gate (private data)

```
client ──auth──▶ sCoRE /store/* ──quota ok?──▶ local cache hit? ──no──▶ R2 (S3 API)
                     │                                  │
                     └── 429 / 503 on refusal ◀─────────┘
```

- **One storage module** in sCoRE (`server/storage.py`, name to confirm), the only code that talks to R2.
  It uses the **S3 API** (boto3 or aioboto3, endpoint `https://<account>.r2.cloudflarestorage.com`) so a move to B2 or MinIO is config only.
  `transcripts.py` moves onto it (drops the REST API path).
- **Keys:** one R2 token scoped to the sCoRE bucket(s), read+write, held by sCoRE only. No `r2.dev`, no custom domain on private buckets.
- **Ledger:** sCoRE counts every op it makes by class (A, B) and tracks stored bytes, per UTC month,
  in its own SQLite (local-first, no Cloudflare storage ops spent on counting).
  A daily reconcile against the GraphQL Analytics API corrects drift.
- **Budgets:** refuse at **80%** of each free limit (A 800k, B 8M, storage 8 GB).
  Writes refuse first (507 or 503), reads next (503 with `Retry-After` at month rollover).
  The ledger is checked **before** the R2 call, so the refusal costs nothing.
- **Cache:** content-addressed or versioned objects are cached on sCoRE's disk (size cap, LRU).
  A hit never touches R2 or the B budget.
- **Rate limits:** token bucket per principal (user id or API key, IP as fallback for anonymous),
  separate buckets per route class (`firmware` strict, `metadata` loose),
  plus one global bucket sized under the monthly B budget. Return `429` + `Retry-After`.
- sCoRE's public hostname sits behind Cloudflare (proxied) so DDoS mitigation and the one free WAF rule cover the server too.

### Tier 2: the CDN (public bundles)

- Stays on **Cloudflare Pages** as it is today. Pages costs no R2 ops, so the R2 budget does not apply here.
- Paths are versioned and immutable (`/v0.1.0/nebula.iife.js`). World requests the whole bundle with no query string.
- **One WAF rate-limit rule** on the CDN hostnames: N requests per 10 s per IP (N set from real page-load counts).
- **If the CDN ever moves to R2:** add a Cache Rule that ignores query strings in the cache key,
  and turn on the analytics kill switch (Tier 3) for that bucket.

### Tier 3: the watchdog (backstop for anything sCoRE does not see)

- `spells/r2-guard.sh` (cron or systemd timer, any agent can run it): queries GraphQL Analytics
  (`r2OperationsAdaptiveGroups`, `r2StorageAdaptiveGroups`) for the account each 5 min.
- At 80% of any limit it alerts. At 90% it trips the kill switch:
  disables public access on any public bucket and sets a flag sCoRE reads to refuse all R2 calls.
- Analytics lag several minutes. That is why sCoRE's own ledger is the real gate and this is a backstop.
- Plus a Cloudflare **budget alert at $0.01** in case both the spell and sCoRE fail.

## No-bill posture (Mark, S333): check every change against this

Cloudflare has no spending cap, so "never a bill" holds only by construction: every path to a billable resource
must deny service inside the free tier. Limits checked 2026-11-13 (developers.cloudflare.com/workers/platform/limits,
/workers/static-assets/billing-and-limitations).

| # | Rule | Why |
|---|---|---|
| N1 | **Stay on Workers Free. Never buy Workers Paid.** | Free caps Worker invocations at 100k/day **per account** (error 1027 / 429, no bill). Paid removes the cap and bills per request |
| N2 | Static files are served as assets; Worker code runs only on `run_worker_first` paths (`/api/*`, `/firmware/*`) | Asset requests are free and unlimited and don't use the 100k |
| N3 | **Refuse before R2.** Every Worker or sCoRE route checks auth (and, in sCoRE, the ledger) before any R2 call | Failed-auth requests are not billed; a refused request costs nothing |
| N4 | **No public R2:** no public bucket access, no `r2.dev`, no custom domain on a bucket | Each is an uncounted, unauthenticated path to Class B reads |
| N5 | **No S3 keys before G2** (ledger + 80% refusal). Keys are bucket-scoped, held by sCoRE only, rotated on any doubt | A leaked S3 key is the one uncapped path |
| N6 | Today's only R2 reader is the companion Worker: N1 bounds it at about 3M Class B a month (free: 10M) | Arithmetic: 100k/day x 30 |
| N7 | One WAF rate-limit rule on the `joinrabble.world` zone: URI path contains `/firmware/` or `/api/`, 30 req / 10 s per IP, block 10 s | A hammerer is stopped at the edge before the shared 100k pool drains |
| N8 | Budget alert at $0.01 (Billing > Billable Usage); `r2-guard.sh` (G5) at 80% alert, 90% kill switch | Backstops, not the gate |
| N9 | Enable no other paid products (Images, Stream, Argo, Load Balancing, Logpush, Durable Objects beyond free) | With a card on file these are the remaining ways to bill |
| N10 | Neon and Render stay on free tiers with **no card on file** | Without a card they suspend at their limits instead of billing |

## Open questions for Mark

- **Q1 Pocket firmware:** move the companion's firmware reads behind sCoRE (one gate, one ledger), or keep the companion Worker
  as its own small gate (Workers binding, Workers Free plan has its own daily request limit)? Recommendation: behind sCoRE once sCoRE is durably hosted (Accounts A1).
  **RULED (Mark, S333): behind sCoRE on the S3 API.** The Worker's `FIRMWARE` binding is a temporary exception so the flasher ships on 2026-11-13; G6 retires it.
  The gate cookie check moves to sCoRE (or the Worker becomes a thin static host that calls sCoRE).
- **Q2 Hosting:** sCoRE runs on Render free (ephemeral disk). The ledger and cache need durable disk,
  or the ledger must reconcile from analytics on boot. Decide with the Accounts A1 hosting choice.
- **Q3 Refusal UX:** what users see when the month's budget is spent (message, Retry-After at rollover).

## Slices (smallest loop first)

| # | Slice | Done when |
|---|---|---|
| G1 | `storage.py` on the S3 API, `transcripts.py` moved to it | transcripts land in R2 by S3 API, tests pass |
| G2 | Op ledger + 80% refusal | a test with tiny budgets refuses before the R2 call |
| G3 | Read proxy route + disk cache | GET through sCoRE, second GET is a cache hit with no ledger tick |
| G4 | Rate limits (per principal + global) | burst test returns 429 with Retry-After |
| G5 | `r2-guard.sh` + budget alert + WAF rule on CDN hosts | spell prints usage, trips the flag in a dry run |
| G6 | Firmware through sCoRE (Q1 ruled S333) | the flasher pulls `pocket/*` through sCoRE's S3 module; the Worker's R2 binding is removed |

## Cold-start handoff

- Branch: `new-horizons` in sCoRE and Grimoire. Nothing built yet.
- Read first: this file, `RaBbLE-sCoRE/AGENT.md` + `CONTEXT.md`, `server/transcripts.py`, `server/main.py` (import of transcripts),
  `spells/publish-cdn.sh`, `spells/setup-cloudflare-r2.sh`, `RaBbLE-Pocket/companion-app/web/wrangler.jsonc`,
  `log/plans/Accounts-Formalization-Scope.md` (hosting and identity).
- Secrets go through the two-tier model (memory `project_secrets_identity_model`), never in the repo.
- Re-check the pricing page before setting budgets. The numbers above are from 2026-10-30.
