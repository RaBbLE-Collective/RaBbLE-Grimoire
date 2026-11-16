# HANDOFF-S345: AC2 built, NiBbLE review found 6 mediums, fixes not yet applied

Date: 2026-11-16 · sCoRE `new-horizons` (HEAD `a670e6d`, AC2 UNCOMMITTED in the working tree), Grimoire.
Plan of record: `log/plans/Accounts-Formalization-Scope.md` (AC2), previous handoff `HANDOFF-S343-Neon-AC1-Accounts-Next.md`.

## Done this session

- **Neon cleaned** (Mark approved): `users` 2 (`guest-410415`, `guest-932c01`), `invites` 0, `guest_issue` 2, `guest_turns` 2026-11-16 = 3, `guest_turns_by_user` 2 rows. No leftover `test_*` schemas, no account tables in `public`. `/tmp/rabble-snap` already gone. Deleted as test junk: `guest-cf5a87` "Mark's pocket" (Mark never named a device; created inside the test burst).
- **Mark's rulings:** Neon rows are likely his dad's; Mark's own Pocket holds a pre-dated sCoRE token probably not in the DB, so it will be rejected after cutover until he has a real account (AC2 resolves this). AC2 first, Resend later (console mailer only for now). Google OAuth and Pocket pairing (AC7 pull-forward) deferred; Mark unsure, my recommendation was leave both out of AC2.
- **AC2 built by CoBbLE** (uncommitted): `server/accounts.py` (Argon2id, hashed single-use tokens, refresh rotation, env-var doc block at top), `accounts_routes.py` (signup, login by `identifier`, verify-email, resend-verification, forgot/reset-password, refresh, logout), `mailer.py`, `migrations/0004_accounts.sql`, `auth.py` (`acct` JWT claim revocation), `rate_limit.py`, `db.py` (export/restore), `env.defaults`, `requirements.txt`, tests `test_accounts_signin.py` (33) and `test_accounts_store.py` (2). `tests/test_db_pg.py` migration count fixed by RaBbLE (now counts files; passes on real Neon).
- **CrumBbLE:** full suite 493 passed / 39 skipped; py3.12 44 passed; Neon PG throwaway-schema run passes after the count fix; SQLite smoke (signup, verify, login, refresh rotation + replay 401, forgot/reset, old password dead) all pass. Not checked: rate limits, cap waitlist, logout route, real mailer.
- **NiBbLE review** (`/tmp/rabble-crew/nibble-ac2.md`, probes `/tmp/nibble-ac2-probe/`; /tmp may be gone, findings below are the record): no auth bypass; deploy HELD on:
  - M1 refresh race beats reuse detection (`accounts.py:276-289`): revoke happens before child row exists.
  - M2 reuse/logout leave the 8h access JWT alive (`sessions_valid_after` not bumped).
  - M3 restore merge leaves orphan `users` rows on email/username collision (`db.py:375-385`).
  - M4 `decode_token` sync DB query under `db._lock` in async path (`auth.py:84-88`, `beam.py:140`): cache `sessions_valid_after` briefly.
  - M5 ConsoleMailer is silent default and logs live reset links (`mailer.py:31-54`): make it explicit-only (`MAIL_SENDER=console`), NullMailer otherwise, no token logging.
  - M6 signup 409 reveals registered emails: return same 201, send "already registered" notice, same Argon2 work.
  - Lows: per-account limit keyed (account, ip); one budget for username+email attempts; purge unverified accounts older than 7 days and exclude from cap; prune `rate_limit._windows`; stale "never cookies" comment `main.py:100`.

## Next (in order)

1. **Apply the fixes.** CoBbLE (`ad7ea00f7c0fcf7cc`, resumable by SendMessage once the rate limit resets, 2:40pm ET) was sent the full fix brief and died on a 429 before editing anything; if the agent is gone, spawn a fresh `cobble` with the list above. Each fix needs a regression test; probes from NiBbLE show how to reproduce M1/M3.
2. **Re-run**: full suite (`.venv/bin/python -m pytest -q`), py3.12 (`uv venv --python 3.12`), Neon PG with `TEST_DATABASE_URL=$DATABASE_URL_UNPOOLED` (never `DATABASE_URL`), then one short NiBbLE re-review of the fixes only. Check Neon `public` and `test_*` schemas afterwards.
3. **Commit AC2** (`spark ~ score >> accounts: email+username+password sign-in ...`), no Co-Authored-By; gitleaks before any push. Leave `package.json`/`package-lock.json` untracked or decide separately.
4. **Release and cut over** (HANDOFF-S343 step 2): `release/0.1.0`, py3.12 test, `render-ctl.sh deploy --wait`, `/health`, confirm the two Pocket guests still authenticate. Set `AUTH_IP_HEADER`, `ACCOUNT_CAP`, `REQUIRE_VERIFIED_EMAIL` on Render. B-31, B-34 ride this deploy.
5. **Resend** (HANDOFF-S343 step 3) before real sign-ups are opened: without a real mailer nobody can verify email or reset. Until then do not set `MAIL_SENDER=console` on Render. Mark's own account is the first native account.
6. Then AC3 (door in World), Pocket pairing ruling (AC7), Google OAuth, encrypted R2 sandboxes (QuiBbLE first).

## Known gaps / decisions open

- Spend posture: AC2 accounts get tier `free` on `hosted_groq`, outside the guest pool and Groq cutoff. Asked Mark; unanswered; default keep separate.
- Not built: A3 invite-past-cap; waitlist is reply text only; cap check can overshoot slightly; two tabs refreshing at once trip reuse detection; `AUTH_IP_HEADER` last-entry rule may still return the Worker's egress IP (unverified); cookie path assumes the same-origin Worker proxy.
- AC1 gaps from S343 still apply.

## Notes

- Do not put `DATABASE_URL` or R2 keys in output or briefs. Organs worked in `/tmp/rabble-crew/`.
