# HANDOFF-S346: accounts are live on Render; Architect, portal, mailer and Pocket pairing next

Date: 2026-11-17 · sCoRE `new-horizons` (1cd965c, pushed) and `release/0.1.0` (243825f, deployed), World (admin page committed, NOT pushed), Grimoire.
Plan of record: `log/plans/Accounts-Architect-and-Entity-Roadmap.md` (built items, roadmap R1-R6), `Accounts-Formalization-Scope.md`. Previous: `HANDOFF-S345-AC2-Built-Fixes-Pending.md` (superseded).

## Done

- **AC2 fixed, reviewed twice, deployed.** NiBbLE's 6 mediums fixed; a second /code-review found more (signup email oracle, squatting, refresh grace, token state across restore, mail-off refusal, fail-closed flags); all fixed with tests. Suite 552 passed / 40 skipped; py3.12 356 passed; Neon PG passes; gitleaks clean.
- **New in AC2:** invite-gated signup (`SIGNUP_INVITE_ONLY`, a valid invite skips cap and email check), the Architect (`server/tools/make_architect.py`, hidden password, refuses a pipe, default name `RaBbLE-Architect`), admin invite list/revoke, reserved names (rabble/architect/admin anywhere in a handle), no email reset for admin or non-human accounts, non-human `kind=entity` accounts (`make_entity.py`, API key only), `revoke_guests.py`.
- **Live:** `release/0.1.0` 243825f deployed by Mark with `spells/score-cutover.sh`; Render env `SIGNUP_INVITE_ONLY=true`, `CORS_ORIGINS`, R2 fresh-start cleared; migration `0004_accounts` applied on Neon (it runs on the first real request, not at boot). Neon: 2 users (both Pocket guests), 0 accounts, 0 invites. B-31, B-34, B-35, B-36 resolved.
- **Release branch:** `release/0.1.0` was merged from `new-horizons` with `-X theirs` (the branches carried the same work under different commits); server/ is byte-identical to new-horizons at the merge. `new-horizons` has since gained `revoke_guests.py` (not on release; it is a local tool).
- **Review fixes to the process:** `RABBLE_ROOT` in Mark's shell points at ~/RaBbLE-OS; scripts must not trust it.

## Next (in order)

1. **Mark: create the Architect.** `bash RaBbLE-Grimoire/spells/score-cutover.sh --architect-only` (hidden password; nothing passes through Claude). Then publish the Architect page: push RaBbLE-World `new-horizons` (deploys dev.joinrabble.world; `world/admin.html`), sign in, mint an invite for Mark's personal email, sign up with it. Then remove `RABBLE_ADMIN_KEY` from Render (it IS set today) and redeploy.
2. **ResendMailer: BUILT** (sCoRE `28237f4`, not pushed; 8 tests; httpx; raises if `RESEND_API_KEY` or `MAIL_FROM` is missing). Mark still creates the Resend account, adds DNS records on Cloudflare, sets the API key on Render. Until then signup without an invite returns 503 by design.
3. **User portal: BUILT** (World `c123fee`, `world/account.html`, browser-tested at 375px, not pushed; idle timeout and the 503/409/422 sign-up messages were not exercised). Original brief: sign-up (with invite token), sign-in, signed-in home (profile, chat with RaBbLE, sign out). Token in sessionStorage for 8 h (the refresh cookie cannot cross sites until the API is same-origin).
4. **Pocket pairing (R6)** is now the critical path: Mark ruled to orphan every Pocket (`spells/pockets-orphan.sh`, built, NOT run). After it runs no Pocket can connect until pairing exists (devices table, member-minted keys, My Pockets panel, flasher writes the key). Dad's Pocket: re-flash on his account.
5. Genesis merge prep (READMEs are plain and on every release branch; still: `registry/releases/genesis.yml`, VERSION files, PR checks, tags, `merge -s ours` joins). Ask before each squash-merge.
6. Secrets map and vault (R3); second factor for the Architect (R1).

## Gaps and notes

- `AUTH_IP_HEADER` is unset on Render: all callers share one rate-limit bucket (signup 5/h, login 20/5 min). Fine for a handful of users; verify what address Render sees behind the Worker, then set it.
- Refresh sessions have no absolute lifetime (R5).
- `~/Collective-SECRETS.zip` (May) sits in Mark's home: move into the vault, then delete.
- The Pocket repo has uncommitted `companion-app/web/public/portal.js` and its test (not from this session).
