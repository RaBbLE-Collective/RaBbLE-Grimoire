# S333 handoff: R2, flasher 0.1.0, accounts store, hardening, mark.mcconachie.world

Cold-start brief for the next session. Rulings live in `log/DECISIONS.md` (section "S333 rulings"),
the storage and no-bill plan in `log/plans/sCoRE-Storage-Gate-Plan.md` (N1-N10), the encryption
rulings in `log/plans/EP2-Accounts-Encryption-Spec.md` §0. Read those; this file is only state + order.

## Done (committed, NOT pushed, NOT deployed)

| Repo | Commit | What |
|---|---|---|
| sCoRE | 5c00efa | `require_member` (guests 403 on sessions/workflows), API map off (`API_DOCS=false`), session id regex; `tests/test_guest_isolation.py` 4/4 |
| sCoRE | 65855ad | proxy cron `*/14` |
| World | 1c50f20 | `wrangler.dev.jsonc` (rabble-world-dev, static, dev.joinrabble.world) |
| World | 803aeba | `_headers`; inline scripts moved to `world/js/RaBbLE-os-page.js`, `RaBbLE-catalog-page.js` |
| ScRiBbLE | 51b6955 | `_headers`; SW register moved to `src/js/RaBbLE-sw-register.js`, cache v3 |
| Grimoire | c6eaf82 | `gist/_headers` (+ a998d82..ef081ca: rulings, plans, router retired) |
| Pocket | 233183b | `companion-app/web/public/_headers` (`serial=(self)`) |
| Xperimental | c892f14 | `_headers` (frame-ancestors self: index frames its drops) |
| Chrysalis | d651d23 (main) | `_headers` (`unsafe-eval` for the Alpine ep1 pages) |

CSP verified with `/tmp/rabble-s333/csp_check.py` (Playwright, local files under real hostnames).
Errors left are pre-existing, not CSP: Chrysalis `world-2026-06` missing css/js files, NeBuLA
examples never load Three, Xperimental sandboxed preview touches `navigator.serviceWorker`,
entity-rig drop `trim` on null.

## Next, in order

1. **Mark runs** `/tmp/rabble-s333/cutover.sh` (dev domain to rabble-world-dev, proxy cron), then
   `wrangler delete --name rabble-dev`. (/tmp is volatile: if gone, the steps are in this session's
   transcript; rebuild from `wrangler.dev.jsonc` + sCoRE `wrangler.jsonc`.)
2. **Flasher 0.1.0 (R2 now enabled, "R2 Paid" = pay-as-you-go with the free tier included).**
   From `RaBbLE-Pocket/companion-app/web`: `wrangler r2 bucket create rabble-pocket-firmware`;
   secrets `EARLY_ACCESS_CODES` (MARK_CODE,DAD_CODE) and `ACCESS_SIGNING_KEY` piped from
   `~/.config/rabble/pocket-companion.secrets` (never echo); `python3 ops/release-firmware.py 0.1.0
   --no-build --upload remote` (16/16 parts in `.release/pocket/v0.1.0/` match manifest sha256);
   `wrangler deploy`; comment the FIRMWARE binding in `wrangler.jsonc` as the temporary exception
   (target = firmware via sCoRE on S3, Q1). Verify 401 without cookie, then Mark flashes his 1.75-B.
   Live deploys were classifier-blocked last session: hand Mark a script if so.
3. **Push** the commits above; cherry-pick sCoRE 5c00efa onto `release/0.1.0` (Render tracks it).
   Redeploy Chrysalis (it serves `wrangler.jsonc` despite `.assetsignore`) and the static sites so
   `_headers` go live.
4. **WAF (dashboard, free plan):** custom rule block when path contains `/.env`, `/.git`, ends
   `.php`, or starts `/wp-`; one rate-limit rule (path contains `/firmware/` or `/api/`, 30 req/10 s
   per IP, block 10 s). Spend limits do not list R2: no R2 cap exists; the protection is the private
   bucket, the gate refusing before R2, Workers Free, and this rule.
5. **Store:** Mark creates Neon project (no card), puts `DATABASE_URL` in `RaBbLE-sCoRE/server/.env`.
   Build AC1 (plain SQL migrations, SQLite local / Postgres Neon) and G1 (`storage.py` over the S3
   API; move `transcripts.py` off the CF REST API). Then create Mark's account.
6. **Share tokens + mark.mcconachie.world:** public photo portfolio = static Worker assets in Dad's
   account; private shares = sCoRE share token (plaintext copy, scoped). No R2/RaBbLE keys there.
7. **Pocket public prep:** licence + third_party audit, NOTICE, README (quickstart voice), gitleaks
   incl. tags, D1-D5 laid out for Mark to rule. Pocket `main` release waits for the public flip.
