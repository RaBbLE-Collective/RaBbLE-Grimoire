# Accounts Formalization: scope (S322, 2026-11-10)

```
spark ~ score/accounts >> a visitor becomes a user: scope, slices, decisions // %S322_SCOPE%
```

> **Status:** scope only, nothing built. Asked by Mark (S322): "create and scope the account formalization work so I can attain users."
> **Builds on:** `EP2-Accounts-Encryption-Spec.md` Phase 1 (its Phase 2, ingestion and encryption, is out of scope here). Read from `RaBbLE-sCoRE/server/{auth.py, auth_routes.py, sessions.py, rate_limit.py}` on `new-horizons`, 2026-11-10.
> **Milestone owners:** sCoRE (accounts) and World (the door), per `registry/epochs/current.epoch.yml`.

## 1. Outcome

Someone who is not Mark opens `joinrabble.world` on a phone, signs in, completes the summoning, talks to RaBbLE, comes back the next day and finds their entity and their conversation still there.

Measure: **activated users** = signed in and returned on a second day. Target for this scope: 10.

## 2. What already exists (more than the docs say)

| Piece | State | Where |
|---|---|---|
| User record (`UserProfile`: id, handle, display name, email, tier, intention, API key) | built, **file-backed** | `server/users.py`, `server/data/users/` |
| API key to 8-hour JWT exchange | built | `POST /api/v1/auth/token` |
| `require_user`: Bearer JWT, `X-API-Key`, or demo guest | built | `server/auth.py` |
| Registration | built, **off** (`ALLOW_REGISTER`), returns an API key once | `POST /api/v1/auth/register` |
| Invite tokens, admin-created | built | `POST /api/v1/auth/invite` (admin key) |
| Summoning ceremony endpoint | built | `POST /api/v1/auth/summon` |
| Profile read and update, backend choice (hosted or bring-your-own key) | built | `/api/v1/profile` |
| Per-user sessions with history | built | `/api/v1/sessions` |
| Rate limiting | built, basic | `server/rate_limit.py` |
| bcrypt helpers | present, unused by any route | `server/auth.py` |

## 3. What is missing

| # | Gap | Why it blocks users |
|---|---|---|
| G1 | **Durable store.** Users, invites and sessions are files on the server's local disk. On the hosted service that disk does not survive a redeploy | every account is lost on the next deploy |
| G2 | **A way to sign in a person can use.** Today identity is an API key shown once. No email link, no OAuth, no password route, no recovery | nobody will keep a key; a lost key is a lost account |
| G3 | **Browser session.** No cookie or refresh; the JWT lasts 8 hours | the user is signed out daily |
| G4 | **The door.** World has no sign-in, no summon page, no signed-in home. The June build's `summon` and `account` pages were already broken and are archived | there is nowhere to click |
| G5 | **What an account is for.** Guest chat already works. A user needs something a guest does not get | no reason to sign up |
| G6 | **Per-user limits.** One personal Groq key behind everything (B-20) | one heavy user exhausts the service for all |
| G7 | **Leaving and trust.** No delete, no export, no privacy page; provider retention unverified (B-26) | cannot honestly invite strangers |
| G8 | **Devices.** The `rabble` terminal face and Pocket have no way to attach to an account (pairing was designed in S295, not built) | accounts stay web-only |

## 4. Slices, in order

Each slice ends in something Mark can try. Stop after any slice and the system still works.

| Slice | Delivers | Closes | Size |
|---|---|---|---|
| **AC1 Store** | `users`, `invites`, `sessions` behind the existing module interface, backed by a hosted database; file store stays as the local and test backend; one-way import of existing files | G1 | S |
| **AC2 Sign-in** | Email link sign-in (no password to store or leak), then Google as a second method. Issues the existing JWT plus a refresh in an `HttpOnly` cookie through the `score.joinrabble.world` proxy Worker. Invite code required while testing | G2, G3 | M |
| **AC3 Door** | On the World face: "Sign in", the summoning (handle, two portal colours from the palette, intention) calling the existing endpoint, and a signed-in home: your entity in your colours, your handle, usage today, sign out. Vanilla JS, Aether tokens only | G4 | M |
| **AC4 Reason** | Signed-in users get: conversation that persists across visits, RaBbLE addressing them by handle and intention, their own entity colours on the face, a higher daily allowance than a guest | G5 | S |
| **AC5 Limits** | Per-user daily budget (messages and tokens) stored on the user record, adjustable without a deploy; guest pool separated from user pool; clear "you have reached today's limit" reply in persona | G6 | S |
| **AC6 Trust** | Delete my account, export my data, a short privacy page that states only what is true today, admin list and disable | G7 | S |
| **AC7 Devices** | Pair a `rabble` terminal or a Pocket to an account with a short code shown on the signed-in home | G8 | M |

AC1 to AC3 are the first vertical slice: after them a stranger can sign in and land somewhere. AC4 and AC5 make it worth doing and safe to share. AC6 before inviting anyone Mark does not know personally. AC7 is its own thread and can wait.

## 5. Decisions for Mark

| # | Decision | Recommendation | Why |
|---|---|---|---|
| A1 | Where the user store lives | A hosted Postgres with a free tier, reached from sCoRE; keep the file backend for local | The spec names DynamoDB and S3, which adds a second cloud. Postgres is one dependency and portable. Cloudflare D1 is the alternative since the proxy is already there. Check current free-tier limits before choosing |
| A2 | Sign-in methods | Email link first, Google second, no passwords | Nothing to hash, nothing to reset; matches the spec's "OAuth or email" |
| A3 | Open or invite | Invite codes for the first 10 to 25, then open | The invite code path exists; it also caps cost while limits are tuned |
| A4 | Build or rent the auth | Build on what sCoRE has | The token, user record, invites and summon are already there; a hosted auth service would duplicate them and put identity outside the Collective |
| A5 | What a user is called and what they hold | A user is one half of "the Pair" (`RaBbLE-Collective/RaBbLE-Membership-Model.md`); the record is the principal from S295, separate from devices and sessions | Keeps the S295 identity model intact |
| A6 | Free allowance | Start low and adjustable (for example 50 messages a day), raise from real usage | One personal provider key carries everyone today |
| A7 | Email sender | Needed for A2: a transactional mail service on the `joinrabble.world` domain | SPF and DKIM records go in the existing Cloudflare zone |

## 6. Not in this scope

Encrypted ingestion and per-user knowledge (spec Phase 2), billing and paid tiers, Personal Cosmos, the social layer, bring-your-own-key UI polish, the open persona tier for Pocket (B-25), provider privacy register beyond what the privacy page must say (B-26).

## 7. Risks

- **Cold start:** the hosted engine sleeps on its free tier; a first-time visitor waits. The keep-warm cron helps; measure before inviting.
- **Provider cap:** B-16 and B-20 stand. AC5 is the mitigation, not a cure.
- **Scope pull:** the summoning ceremony invites lore and polish. Ship the three fields first.
- **Two stores:** file and database backends must pass the same tests, or local and hosted drift.

## 8. First session

1. Mark rules A1, A2, A3.
2. AC1 behind the existing `users` interface with tests against both backends.
3. Turn `ALLOW_REGISTER` off for good once AC2 lands; delete the legacy route after.
