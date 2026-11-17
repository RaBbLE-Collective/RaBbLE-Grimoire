# HANDOFF-S347: Pockets pair to accounts, captures and conversations in the portal, metering, flash spell

Date: 2026-11-17 · repos: sCoRE, World, Pocket, Grimoire, Collective (all `new-horizons`). Supersedes `HANDOFF-S346-Accounts-Live.md` for what to do next (its rules and gotchas still stand: read its "Rules and gotchas").
Mark's ruling this session: **v0.1.0 includes accounts.** Pockets belong to real accounts; guest Pockets are disposable test fixtures Mark makes himself.

> **Update, later in S347 (Mark approved the deploys):** the sCoRE merge `739ec37` is pushed on `release/0.1.0` and live on Render (`/api/v1/pocket/notes` answers 401, `/api/v1/usage` 403, `/health` ok, a warmup request ran so migrations 0006 and 0007 should have applied: NOT verified in Neon, the agent was denied direct database access). The Pocket Worker is deployed (version 766232c3; the page has the sign-in card; `ACCESS_SIGNING_KEY` was already set). Mark's 1.75b was reflashed with `keep` (hash verified, new prompt and ring lap on it) and has NO key. Still to do, by Mark in his terminal: (1) re-mint: `bash RaBbLE-Grimoire/spells/flash-pocket.sh --mode account --no-flash`; (2) `cd RaBbLE-sCoRE/server && set -a && . ../.env.local && set +a && ../.venv/bin/python tools/revoke_guests.py --dry-run` then without `--dry-run` (it needs a real terminal and asks him to type REVOKE); (3) check Neon has the 0006/0007 tables; (4) optionally unset `GUEST_ISSUE_SECRET` and `BEAM_DEVICE_TOKEN` on Render and delete the Worker's `GUEST_ISSUE_SECRET` secret to close guest minting entirely. The "What Mark does" order below is therefore partly done.

## Built this session (all tested against mocks only; nothing visual or on a real server yet)

| Piece | Where | State |
|---|---|---|
| Captures and conversations kept per member account; routes `/api/v1/pocket/notes` and `/conversations`; beam `new_convo` message | sCoRE `aa9215b` | pushed, NOT deployed (migration 0006) |
| Usage metering, per-account limits, durable account event log, admin usage/limits/events routes; beam accepts only `rbdv_` device keys, entity keys, member/admin JWTs; admin exempt from the 3-device limit | sCoRE `6a731fa` | committed, NOT pushed, NOT deployed (migration 0007) |
| `BEAM_ALLOW_GUEST_POCKETS` (default false): the shared `BEAM_DEVICE_TOKEN` and guest keys are refused on the beam unless true. Guest minting endpoint kept for testing | sCoRE `6a731fa` | same |
| Captures and Conversations tabs in the account portal; account control top right of the face; guest prompt after 2 turns; CDN pins moved to Aether/NeBuLA `v0.1.0` (rc.1 NeBuLA had no sized stage, which clipped the face off the top of dev) | World `b40de1e`, `7529c5f`, `3e51edc`, `29890e7` | pushed; dev redeploys from CI; prod (`main`) still the 2026-11-09 build until Genesis merges |
| Pocket flasher gated behind member sign-in (Worker session cookie, `/api/login /me /logout /pair`), mint-on-flash, guest and invite paths removed from the page, Worker `/api/guest` and `/api/summon` removed | Pocket `2715027`, `eeac38f`, `cb96d75`, `bd925d8` | `2715027`/`eeac38f`/`cb96d75` committed; check `git log origin/new-horizons..` for what is unpushed; Worker NOT deployed |
| Firmware: long press (1.2 s hold on the face) starts a new conversation, sends `new_convo` (pending flag when offline), eyes withdraw and return, a NEW CONVERSATION caption holds 1.2 s and the face ring does one cyan lap (reuses `ring_arc`) | Pocket `15ada1a`, `802ed2e` | committed; host tests pass, both boards build (175b and 175c); only `15ada1a` was flashed to Mark's 1.75b, so the prompt and ring need a `keep` reflash; nothing seen on a display |
| `spells/flash-pocket.sh`: `--mode keep` (DEFAULT: firmware only, writes nothing) / `account` (asks which account; password in Mark's terminal only; or `--key-file`) / `guest` / `none` | Grimoire `587b617`, `c11db01`, `30b99a1` | committed; decision table in `RaBbLE-Pocket-Firmware-BuildFlash.md` |

## What Mark does (secrets and deploys are his)

1. **Test the flash endpoints with accounts.** `pocket.joinrabble.world` today needs the early-access code only: the account gate is not deployed (the live page has no sign-in card).
2. **Deploy order matters (a refused Pocket is cut off until re-paired):** (a) flash and re-mint his Pocket: `bash RaBbLE-Grimoire/spells/flash-pocket.sh --mode account --no-flash` (his 1.75b lost its key; Wi-Fi was kept); (b) merge/deploy sCoRE (`release/0.1.0` auto-deploys to Render; compare trees first: `git diff new-horizons release/0.1.0 --stat`; the release branch only differs in `VERSION` and the TUI manifest); migrations 0006 and 0007 apply on the first request after deploy (warm it with `POST /api/v1/auth/forgot-password` for `warmup@example.com`, then check Neon); (c) `wrangler deploy` the Pocket Worker (needs the `ACCESS_SIGNING_KEY` secret; remove the now-unused `GUEST_ISSUE_SECRET`); (d) run `server/tools/revoke_guests.py` against prod when ready.
3. Leave `BEAM_ALLOW_GUEST_POCKETS` unset in production. Optional env: `USAGE_DEFAULTS` or `USAGE_<TIER>_<FIELD>` (defaults in `server/env.defaults`: free 100 turns/day, 2000/month; pro 500/10000; admin unlimited but metered).
4. Resend (B-38), removing `RABBLE_ADMIN_KEY` from Render, the 7 pairing questions: unchanged from the S346 handoff.

## Next, in order

1. Genesis merge prep (v0.1.0 includes accounts): `registry/releases/genesis.yml`, `VERSION` files (sCoRE's says `0.1.1-dev`; Genesis needs `0.1.0`), PR checks, squash-merge each Genesis PR (Mark approves each), tag `v0.1.0` + `genesis`, `git merge -s ours origin/main` joins back on `new-horizons`. World prod will pick up the face fix and the account control only when World's Genesis PR (#3) merges.
2. Verify against the REAL services once deployed (everything below was mocked): portal Captures/Conversations tabs against `/api/v1/pocket`, the flasher sign-in and mint on a deployed Worker (Secure cookie), `device_limit` status code (accepts 400/409/422 with "limit" in the detail), bearer attribution of web chat to the account, metering rows landing in Neon.
3. Firmware gaps: the device sees HTTP 403 for a refused key, so the "key not accepted" text only appears in logs (the beam would have to accept the socket and then close it); distinct "key not accepted, pair again" screen (about a day). A turn still in flight may set a caption just after the new-conversation clear (guarded in the follow-up; check on hardware).
4. Smaller: `usage_events` and `account_events` have no retention; a limit check races by a few turns under concurrency; the TUI test files fail to collect on Python 3.12 (textual, `super()` TypeError; Render does not run the TUI; not confirmed to predate S347); stale Grimoire line `RaBbLE-World-Roadmap.md:26` ("Aether rc.2 + NeBuLA rc.1"); sCoRE's own `CONTEXT.md` still describes guests; R/W notes in `Accounts-Architect-and-Entity-Roadmap.md` (new R8).
5. Open questions for Mark: encrypt the new per-account notes and conversations in Neon at the application level (today: Neon at-rest encryption only; the R2 transcripts are anonymised and encrypted at rest by Cloudflare with Cloudflare-managed keys); whether `rbbl_` legacy member keys and the shared admin key should stay refused on the beam (they are now).
6. Parallel items from S346 (Grimoire MCP, automations, the Anthropic export path) are untouched.

## Rules added this session

- Pockets belong to accounts. Guest Pockets are test fixtures Mark creates; revoking or deleting one has no consequence. See memory `project-s347-pocket-pairing-policy`.
- flash-pocket.sh: default to `--mode keep`; never handle the account password or the guest secret; do not flash Mark's hardware unless he asked this session. Mark's Pocket is the 1.75b (default board); his dad's is the 1.75c (`--board rabble_waveshare_175c`).
- Sub-agents: pin sonnet, self-contained briefs, verify every hand-back (commit, tests, gitleaks) before reporting; they must not push or deploy.
- Never `pkill -f` with a pattern in your own command; port 8000 is not ours (tests use 8010 and 8011).

## First message for the new session

> Read `RaBbLE-Grimoire/log/handoffs/HANDOFF-S347-Pocket-Accounts-Metering.md`, claim a session number, then tell me where we are and start on "Next" item 1 (Genesis merge prep) or whatever I name.
