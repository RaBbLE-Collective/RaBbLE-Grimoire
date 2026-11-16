# HANDOFF-S343: Neon live, AC1 store built, accounts (AC2) and Pocket device pairing next

Date: 2026-11-16 · sCoRE `new-horizons` (AC1 committed `a670e6d`, nothing pushed), Grimoire.
Plan of record: `log/plans/Accounts-Formalization-Scope.md` (AC1 to AC7), `log/plans/EP2-Accounts-Encryption-Spec.md`. Rulings: `log/DECISIONS.md` S333 block (Neon, R2, portability).

## Done

- **Neon set up** under the RaBbLE-Dev GitHub: org `org-small-night-89294993`, project `little-smoke-00157786` (`RaBbLE-sCoRE_Accounts`), branch `production`, AWS US East 2 (Ohio), same region as Render (`ohio`, free plan; read from the Render API, it was not written down anywhere). Only Postgres is on; Object storage, Functions, AI gateway, Realtime and Better Auth stay off (portability ruling). Free plan: 1 GB, scale to zero, 10 branches.
- **CLI + MCP:** Neon CLI authorized (global `npm i -g` fails with EACCES, use `npx neon@latest`). `neon init` + `neon deploy` run in `RaBbLE-sCoRE`; `.env.local` (gitignored) holds `DATABASE_URL` (pooled), `DATABASE_URL_UNPOOLED`. Neon plugin `neon-postgres@neon` v3.0.8 enabled; MCP `plugin:neon:neon` shows Connected under `claude mcp list`.
- **AC1 store (sCoRE `a670e6d`):** `server/db.py` picks Postgres (psycopg 3) when `DATABASE_URL` is set, else SQLite as before; same portable migrations on both; autocommit connection, advisory lock around migrations, writes never retried, reads retried once on connection errors only, keepalives + `tcp_user_timeout`, connect errors redacted (no URL on the exception chain). Snapshot to R2 is skipped on Postgres. Built by CoBbLE; reviewed twice by NiBbLE; run by CrumBbLE (pooled path, idempotency, 3-process first boot). Tests: full suite 458 passed / 39 skipped with no DB env; 52 passed / 7 skipped for db, db_pg, guests on SQLite + real Neon; py3.12 db/guests/storage 61 passed.
- **Render:** `DATABASE_URL` (pooled) staged with `render-ctl.sh env-set`. NOT live: Render deploys `release/0.1.0`, which has no Postgres code. Setting it is harmless to the old code.
- **R2 snapshot read** (gen 27, 2026-11-16 00:17Z): 2 users, both Pocket auto-guests (`guest-410415`, `guest-932c01`), 0 invites, no real accounts. Decision (Mark): treat Neon as a fresh DB and open real sign-ups.
- **Pocket guests imported into Neon** (users, guest_turns, guest_turns_by_user, guest_issue, r2_usage, `ON CONFLICT DO NOTHING`), so the keys baked into those devices keep working after cutover.

## Open: Neon production schema holds test junk (do this first)

The first CrumBbLE/CoBbLE runs had `DATABASE_URL` exported and wrote test rows into the **production `public` schema**. Found after the import: 21 users instead of 2. Junk = 3 fixture users (`hu1`, `ha`, `mem`, tier `collective`) + 17 "Guest" accounts created 15:29 to 15:31 UTC on 2026-11-16, plus 2 invites, 1 extra `guest_issue`, 8 extra `guest_turns_by_user` rows, and `guest_turns` for 2026-11-16 at 10 (snapshot said 3). The two real guests are `guest-410415` and `guest-932c01` (ids `R0i890wp`, `fgKArV7M`). Live Render still ran on SQLite, so no real device wrote to Neon: everything outside those two is junk.
The cleanup script was written but the permission classifier denied it as destructive; it was NOT run. Mark must approve the delete (or run it) before cutover. Then: reset `guest_turns` 2026-11-16 to 3, delete all rows in `invites`. The leak is closed: `tests/conftest.py` now forces SQLite and removes `DATABASE_URL`, and the PG fixture needs an explicit direct `TEST_DATABASE_URL` and uses a throwaway schema.
`/tmp/rabble-snap/score.db` (hashed guest keys) is still on disk; delete it when done.

## Next (in order)

1. **Clean the Neon junk** (above) and verify `select count(*) from users` is 2.
2. **Release AC1 and cut over:** squash/merge to `release/0.1.0`, py3.12 test first (`uv venv --python 3.12`), `render-ctl.sh deploy --wait`, check `/health`, then confirm the Pocket guests still authenticate. B-31 (`R2_ALLOW_FRESH_START`) and B-34 (guest fix) ride this same deploy. Decide on `package.json` / `package-lock.json` in sCoRE (untracked Neon CLI scaffolding; `neon.ts` is committed).
3. **Email service (Resend) investigation.** Mark's A7 call; recommendation was Resend (free: 100 emails/day, 3,000/month, one custom domain, per third-party 2026 guides; confirm on resend.com/pricing). Fallback Brevo (300/day free, shared with marketing mail). Cloudflare Email Service rejected (needs Workers Paid, beta, provider-only binding breaks the portability rule). To do: confirm current terms on the vendor pages, create the account under RaBbLE-Dev, add `joinrabble.world` and put its SPF + DKIM (+ DMARC) records in the Cloudflare zone, send a test from `no-reply@joinrabble.world`, check deliverability to Gmail/Proton, decide SMTP vs HTTPS API (SMTP keeps it swappable). Write the finding into the Grimoire (A7 ruling).
4. **AC2 sign-in** (next session). Email + username + password (Argon2id via `argon2-cffi`, per-hash salt, rehash on login; bcrypt verify only for legacy; never log or store plain text), verified email, reset by emailed single-use token stored hashed with short expiry and all sessions revoked on use, same reply whether or not the email exists; Google OAuth with PKCE (needs a Google OAuth client from Mark, callback on `score.joinrabble.world`); JWT + `HttpOnly` refresh cookie through the Worker; 100-account cap as a server number. Mark's own account is the first native account (migrate nothing; link Google to it later by verified email). Use a console-log mail sender locally. Build with CoBbLE, review with NiBbLE before any deploy.
5. **Pocket device to real account flow** (Mark wants this better than a bare guest key; this is AC7 pulled forward, needs a ruling before building). Today a Pocket holds an auto-minted guest key (`/api/guest`, S341 flasher). Proposal for Mark to rule on: the device asks sCoRE to start pairing with its guest key and shows a short one-time code on screen; the signed-in home takes the code and the server re-parents the device (and its guest history) to the account principal, keeping the device key valid, then the guest user row is retired or merged; a device can be unpaired from the signed-in home; terminals (`rabble`) use the same code path. Open questions: what happens to a paired device's turns and per-day limits (account allowance replaces guest cap, AC5), whether one device can belong to two accounts (no, per S295 "separate principal/device/session"), and what the Pocket shows if the code expires. Read first: `RaBbLE-Collective/RaBbLE-Membership-Model.md`, `RaBbLE-sCoRE/RaBbLE-sCoRE-Membership-API.md`, S295 identity model in `RaBbLE-sCoRE-Persistence.md`/`RaBbLE-Secrets-and-Identity.md`.
6. **Encrypted R2 sandboxes** (the goal: Mark and dad each get a private, encrypted notes/captures/conversations area). After AC2/AC3: spec Phase 2 (`EP2-Accounts-Encryption-Spec.md` section 0): per-account R2 prefix via the S3 API, master key wrapped by a password-derived key + recovery key shown once (+ optional passkey), client-side sealing. Google-only users need the recovery key or a passkey (spec says unresolved). Send the plan through QuiBbLE before building; silent key loss is the risk.

## Known gaps in AC1 (not blockers at 2 to 3 users)

- A reachable but frozen Postgres can still block all threads (db calls are sync inside async routes, M2; keepalives only cover a dead network path).
- `_translate` rejects `$word$` inside a string literal; the 30s `lock_timeout` also bounds the advisory-lock wait (a second instance booting during a >30s migration fails to boot); a failed guest-count decrement costs one turn (`guests.py:81-82`).
- `/admin/inventory` reports the size of a `score.db` that does not exist on Postgres.
- Production behaviour on the pooled URL under real multi-instance load is unverified.

## Parallel session

RaBbLE UI `/mcp` wrap: scoped in `log/plans/RaBbLE-TUI-MCP-Scope.md`. It touches `tui/` and `orchestra/` only (not `server/`), so it can run beside AC2 work.

## Notes

- Commits carry no `Co-Authored-By` trailer. Secrets scan with gitleaks before any push.
- Do not put `DATABASE_URL` or R2 keys in output, logs or briefs; load from `.env.local` and `~/.config/rabble/pocket-companion.secrets` inside commands only.
