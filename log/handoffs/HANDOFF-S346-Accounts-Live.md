# HANDOFF-S346: accounts, the Architect, one portal and device pairing are live

Date: 2026-11-17 · repos: sCoRE, World, Pocket, Grimoire, Collective (all `new-horizons`; sCoRE `release/0.1.0` deployed).
Read first: this file, then `log/plans/Accounts-Architect-and-Entity-Roadmap.md` (what is built, roadmap R1-R7) and `log/plans/Pocket-Pairing-Plan.md` (Pocket side, 7 open questions for Mark). Supersedes `HANDOFF-S345-AC2-Built-Fixes-Pending.md`.

## What is live

| Piece | State |
|---|---|
| sCoRE `release/0.1.0` at `7f6dbbe` | Deployed on Render (auto-deploys from that branch). Neon migrations 0001-0005 applied. `/health` ok, version `0.1.1-dev` |
| Accounts | Email + username + password (Argon2id), verify, reset, rotating refresh, JWT revocation, rate limits. Two review rounds done. 579 tests (3.14), 383 (py3.12, what Render runs), Neon PG clean |
| Signup gate | `SIGNUP_INVITE_ONLY=true` on Render. A valid invite skips the cap and the email check. Public signup without an invite is refused (403, or 503 while no mailer) |
| The Architect | `RaBbLE-Architect`, tier `admin`, created on prod by Mark with `server/tools/make_architect.py` (hidden password; the password never went through Claude). Recovery = database break-glass (`--reset-password`). No email reset for admin or non-human accounts |
| Non-human accounts | `kind=entity` (`server/tools/make_entity.py`): API key only, no password. Account for RaBbLE the entity is NOT created yet; what it may do is roadmap R4 |
| Mail | `ResendMailer` is in the release but inactive (`MAIL_PROVIDER` unset; unset = nothing sent, nothing logged) |
| Device keys | `POST/GET/DELETE /api/v1/devices` (members only, limit 3, key `rbdv_…` shown once, stored as a hash). A device key resolves to its owner on `X-API-Key` and the beam bearer token; it can never reach `/admin` or mint devices |
| World (dev only) | `dev.joinrabble.world/world/account`: ONE portal, ONE login. Everyone: Home (profile, chat) and Pockets (add, see, revoke; key shown once). Admin accounts: an extra Invites tab. `/world/admin` redirects to `?tab=invites`. Not on prod `joinrabble.world` (that deploys from World `main`) |
| READMEs | Plain-language on all 7 release branches (Collective, Grimoire, OS, Pocket, sCoRE, ScRiBbLE, World) |

Neon (prod): 3 users = the 2 Pocket guests + the Architect; 1 account; 0 invites at last check.

## Next, in order

1. **Mark: Resend.** Create the account, add `joinrabble.world` and the DNS records Resend gives in Cloudflare (set DNS-only, not proxied), create an API key, then on Render set `MAIL_PROVIDER=resend`, `RESEND_API_KEY`, `MAIL_FROM` (for example `RaBbLE <noreply@joinrabble.world>`). Render env changes are run by Mark (see Rules). Then redeploy.
2. **Mark: use it.** Sign in as the Architect, Invites tab, mint an invite for his personal email, sign up with it (works with no mail), try chat, add a Pocket in the Pockets tab.
3. **Mark: clean-ups.** Remove `RABBLE_ADMIN_KEY` from Render (it IS set; the Architect account makes it redundant). Run `server/tools/revoke_guests.py` when ready to remove only the two minted guests. Answer the 7 pairing questions in `Pocket-Pairing-Plan.md`.
4. **Pocket flasher sign-in tab.** Needs `RaBbLE-Pocket/companion-app/web/public/portal.js` and `test/portal_test.py`, which have UNCOMMITTED changes that are not from S346: ask Mark what they are before touching them. A patch is proposed in the plan; `worker/pairing.js` (`pair()`) and `/api/pair` are built and tested (Pocket `69bbcb9`). Until then a Pocket is paired by pasting the key or sending `>beam.token=KEY` over serial. Firmware shows "Dial failed" for a revoked key: a distinct "key not accepted, pair again" state is about a day (unconfirmed that the websocket error carries the HTTP status).
5. **Genesis merge prep** (the route to v0.1.0 on `main`). Open Genesis PRs: Collective, Grimoire, OS, Pocket, sCoRE, ScRiBbLE, World (#3). Aether and NeBuLA are already on `main` with the `genesis` tag. Still to do: `registry/releases/genesis.yml`, `VERSION` files (sCoRE's says `0.1.1-dev` on release; Genesis needs `0.1.0`), PR checks, squash-merge each (Mark approves each), tag `v0.1.0` + `genesis`, `git merge -s ours origin/main` joins on `new-horizons`, delete release branches. Mark's rulings: `new-horizons` keeps its name and builds as `0.1.1-dev+<sha>`; v0.1.0 may ship with rough docs; v0.1.1 is the patch + docs pass and Pocket's first user-ready release. NOTE the sCoRE release branch now carries the accounts work: decide whether Genesis `0.1.0` includes it (it is already live from that branch).
6. **Roadmap** (`Accounts-Architect-and-Entity-Roadmap.md`): R1 second factor for the Architect (WebAuthn or TOTP), R2 offline recovery of the vault (Shamir paper), R3 secrets map + vault off Proton (also: move `~/Collective-SECRETS.zip` into it and delete it), R4 what the entity does with its account, R5 small follow-ups (refresh-session absolute lifetime, `AUTH_IP_HEADER` behind the Worker, invite link in the sign-up page), R6 pairing (device code later), R7 per-user scoped permissions. Free tier makes no privacy promises (Mark); B-26 (provider privacy register) is still deferred.
7. **Parallel, separate:** the Anthropic data export session (Mark said it is exported; the path was never found: ask), and the Grimoire MCP (design first: tools = orient, search, canon checks; local stdio first), and automations so RaBbLE runs itself. None started.

## Rules and gotchas (learned the hard way)

- **No `Co-Authored-By` or AI trailer on any commit.** Pulse format: `[impulse] ~ [organ] >> [revelation] // %STATE%`. Run `gitleaks detect --source . --log-opts="origin/<branch>..HEAD" --no-banner --redact` before every push. Never print `DATABASE_URL`, R2 keys or any key; load `sCoRE/.env.local` inside a command only. Tests on Postgres use `TEST_DATABASE_URL=$DATABASE_URL_UNPOOLED`, never `DATABASE_URL`.
- **The permission classifier blocks this agent from changing Render env.** Mark runs `bash RaBbLE-Grimoire/spells/score-cutover.sh` (cutover: env, push, wait, Neon check, Architect; `--architect-only`, `--dry-run`). A plain `git push origin release/0.1.0` (which auto-deploys) worked once Mark said to push. `env-set` refuses empty values.
- **sCoRE migrates on its first real request after a deploy**, not at boot. Warm it with a request that touches the database (for example `POST /api/v1/auth/forgot-password` with `warmup@example.com`) before checking Neon.
- **Mark's shell sets `RABBLE_ROOT=~/RaBbLE-OS`.** Never trust that variable; derive paths from the script location.
- **Never `pkill -f` with a pattern that appears in your own command** (it kills your shell). Port 8000 on Mark's machine is owned by something else: use 8010 for test servers.
- **Never ask for, or handle, the Architect password or the entity key.** Tools that take secrets refuse a pipe and are run by Mark in his own terminal.
- `BEAM_DEVICE_TOKEN` (the shared master Pocket key: every holder becomes one shared `pocket` user at `pro`) and guest minting (`GUEST_ISSUE_SECRET`) STAY until every Pocket is paired (Mark, S346).
- `release/0.1.0` and `new-horizons` carried the same sCoRE work under different commits; the last merge used `-X theirs` and server/ was byte-identical to `new-horizons` afterwards. Before the next release merge, compare trees (`git diff new-horizons release/0.1.0 --stat`).
- Web copy: no em dashes, no marketing voice, Aether `--rabble-*` variables only, vanilla JS, CSP `script-src 'self'` (no inline scripts), text via `textContent`. Docs live in the Grimoire. Members never duplicate Grimoire content.
- Sub-agents (Agent tool) must be pinned to `sonnet`, given self-contained briefs, told not to push or deploy, and their hand-backs verified (git log, tests, gitleaks) before reporting. Mark asked for them to conserve tokens.
- Do not sweep the dirty Pocket files or the Grimoire `log/sessions/*.jsonl` into commits.

## Repo state at close

- Committed, NOT pushed: Collective (5), Grimoire (about 22), Pocket (4), OS (2), sCoRE `new-horizons` (2; the same code is already in the pushed release). World `new-horizons` is pushed (`271d93c`).
- Uncommitted and not ours: Pocket `companion-app/web/public/portal.js`, `companion-app/web/test/portal_test.py`; Grimoire session transcripts and ledger churn.

## First message for the new session

> Read `RaBbLE-Grimoire/log/handoffs/HANDOFF-S346-Accounts-Live.md` and `log/plans/Accounts-Architect-and-Entity-Roadmap.md`, claim a session number, then tell me where we are and start on "Next" item 4 or 5, whichever I name.
