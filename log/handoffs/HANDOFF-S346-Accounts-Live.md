# HANDOFF-S346: accounts, Architect, one portal and device pairing are live; Resend setup, flasher tab, Genesis merge prep next

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
4. **Pocket pairing (R6), in progress:** devices API (sCoRE), My Pockets panel (World), Pocket web companion/flasher plus `log/plans/Pocket-Pairing-Plan.md`. Keep `BEAM_DEVICE_TOKEN` (the shared master Pocket key) and guest minting untouched until every Pocket is paired. Mark runs `server/tools/revoke_guests.py` to remove only the two existing guests. Dad's Pocket: pair it on his account. Per-user scoped permissions are R7.
5. Genesis merge prep (READMEs are plain and on every release branch; still: `registry/releases/genesis.yml`, VERSION files, PR checks, tags, `merge -s ours` joins). Ask before each squash-merge.
6. Secrets map and vault (R3); second factor for the Architect (R1).

## Gaps and notes

- `AUTH_IP_HEADER` is unset on Render: all callers share one rate-limit bucket (signup 5/h, login 20/5 min). Fine for a handful of users; verify what address Render sees behind the Worker, then set it.
- Refresh sessions have no absolute lifetime (R5).
- `~/Collective-SECRETS.zip` (May) sits in Mark's home: move into the vault, then delete.
- The Pocket repo has uncommitted `companion-app/web/public/portal.js` and its test (not from this session).

## Update (late S346): live state

- **sCoRE `release/0.1.0` 7f6dbbe is deployed** (Resend mailer, device keys, `revoke_guests.py`); Neon migrations 0001-0005 applied; 579/383 tests, Neon PG clean.
- **World `new-horizons` 271d93c is on dev.joinrabble.world:** ONE portal at `/world/account` (Home, Pockets, and an Invites tab for admins); `/world/admin` redirects to `?tab=invites`. The Architect exists on prod (Neon: 1 admin) and signs in there.
- **Pairing today:** a member mints a key on the Pockets tab, then pastes it into the companion or sends `>beam.token=KEY` over serial. Not yet: the flasher sign-in tab (needs `portal.js`, which has uncommitted work), the firmware "key not accepted" state, device-code pairing. See `log/plans/Pocket-Pairing-Plan.md` (7 questions for Mark).
- **Mark kept:** `BEAM_DEVICE_TOKEN` (the shared master Pocket key) and guest minting, untouched. Run `server/tools/revoke_guests.py` to remove the two minted guests when ready.
- **Resend:** code is live but inactive (`MAIL_PROVIDER` unset). Setup steps are in the S346 conversation summary: Resend account, DNS on Cloudflare (DNS-only), API key, Render env `MAIL_PROVIDER=resend`, `RESEND_API_KEY`, `MAIL_FROM`.
- Production pushes were done by the session after Mark said so (git push of `release/0.1.0`); the Render env changes were done by Mark with `spells/score-cutover.sh`.
