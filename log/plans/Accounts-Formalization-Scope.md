# Accounts Formalization: scope (S322, 2026-11-10)

```
spark ~ score/accounts >> a visitor becomes a user: scope, slices, decisions // %S322_SCOPE%
```

> **Status:** scope only, nothing built. Asked by Mark (S322): "create and scope the account formalization work so I can attain users."
> **Builds on:** `EP2-Accounts-Encryption-Spec.md` Phase 1 (its Phase 2, ingestion and encryption, is out of scope here). Read from `RaBbLE-sCoRE/server/{auth.py, auth_routes.py, sessions.py, rate_limit.py}` on `new-horizons`, 2026-11-10.
> **Milestone owners:** sCoRE (accounts) and World (the door), per `registry/epochs/current.epoch.yml`.

## 1. Outcome

Someone who is not Mark opens `joinrabble.world` on a phone, signs in, completes the summoning, talks to RaBbLE, comes back the next day and finds their entity and their conversation still there.

Measure: **activated users** = signed in and returned on a second day. Target for this scope: 10. Sign-up is open and capped at 100 accounts (A3).

**Ship bar (Mark, S322):** only ship a working MVP that feels semi-ready and polished. A slice is not released to users because it functions; it is released when the whole path a user walks (sign in, summon, home, talk, return) works on a phone and looks finished.

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
| **AC2 Sign-in** | Google and email + password (verified email, reset), Apple later (A2). Issues the existing JWT plus a refresh in an `HttpOnly` cookie through the `score.joinrabble.world` proxy Worker. Open sign-up with a 100-account cap | G2, G3 | M |
| **AC3 Door** | On the World face: "Sign in", the summoning (handle, two portal colours from the palette, intention) calling the existing endpoint, and a signed-in home: your entity in your colours, your handle, usage today, sign out. Vanilla JS, Aether tokens only | G4 | M |
| **AC4 Reason** | Signed-in users get: conversation that persists across visits, RaBbLE addressing them by handle and intention, their own entity colours on the face, a higher daily allowance than a guest | G5 | S |
| **AC5 Limits** | Per-user daily budget (messages and tokens) stored on the user record, adjustable without a deploy; guest pool separated from user pool; clear "you have reached today's limit" reply in persona | G6 | S |
| **AC6 Trust** | Delete my account, export my data, a short privacy page that states only what is true today, admin list and disable | G7 | S |
| **AC7 Devices** | Pair a `rabble` terminal or a Pocket to an account with a short code shown on the signed-in home | G8 | M |

AC1 to AC3 are the first vertical slice: after them a stranger can sign in and land somewhere. AC4 and AC5 make it worth doing and safe to share. AC6 before inviting anyone Mark does not know personally. AC7 is its own thread and can wait.

## 5. Decisions for Mark

| # | Decision | Recommendation | Why |
|---|---|---|---|
| A1 | Where the user store lives | **Host RULED (Mark, S333): Neon Postgres free; user data itself goes to R2, encrypted per account (`EP2-Accounts-Encryption-Spec.md` §0).** **RULED as direction (Mark, S322): SQLite locally, Postgres when hosted, and stay movable** (Render today, likely AWS later). One storage interface with two backends; see section 5.1 | Mark wants flexibility over any one host. Postgres runs on every cloud, including AWS (RDS or Aurora), so the host can change without touching the code |
| A2 | Sign-in methods | **RULED (Mark, S323, 2026-11-11): v1 is Google + a username, and/or email + username + password.** Every account has a username. Email accounts need a verified email and reset by email (Argon2 or bcrypt). Apple and phone are out of v1 | A username alone has no recovery path, so it always sits on a Google identity or a verified email. Phone needs a paid SMS sender and adds nothing a verified email does not |
| A3 | Open or invite | **RULED (Mark, S322): open sign-up, capped at 100 users to start.** The cap is a number on the server, adjustable without a deploy; past it, sign-up shows a waitlist line in persona | Invite codes stay available for raising someone past the cap |
| A4 | Build or rent the auth | Build on what sCoRE has | The token, user record, invites and summon are already there; a hosted auth service would duplicate them and put identity outside the Collective |
| A5 | What a user is called and what they hold | A user is one half of "the Pair" (`RaBbLE-Collective/RaBbLE-Membership-Model.md`); the record is the principal from S295, separate from devices and sessions | Keeps the S295 identity model intact |
| A6 | Free allowance | Start low and adjustable (for example 50 messages a day), raise from real usage | One personal provider key carries everyone today |
| A7 | Email sender | Needed for A2 (verification and password reset): a transactional mail service on the `joinrabble.world` domain | SPF and DKIM records go in the existing Cloudflare zone |

### 5.1 Store design: SQLite local, Postgres hosted (A1)

- **One interface, two backends.** The existing `users` module keeps its function signatures; behind it sits a small repository layer with a SQLite backend (local, tests, offline) and a Postgres backend (hosted). The current file store is imported once and retired.
- **One schema, written to the common subset.** Schema changes go through a migration tool that targets both engines. The same test suite runs against both backends on every change; that is what keeps the later move cheap.
- **Rules that keep SQLite and Postgres interchangeable:** explicit column types (SQLite does not enforce them, Postgres does); text primary keys generated in code, never an engine's auto-increment; timestamps stored as UTC ISO-8601 text or a real timestamp type through the abstraction, never engine date functions; booleans as booleans; JSON kept to simple read-whole, write-whole fields; no engine-specific SQL in route code.
- **Differences that cannot be abstracted away:** SQLite allows one writer at a time (fine locally, the reason it is not the hosted store) and needs a persistent disk, which the current hosted free tier does not have.
- **Host is a connection string.** Start on a managed Postgres with a free or low tier; move to AWS RDS for PostgreSQL later with a dump and restore. At 100 users that is minutes of data. The host is not chosen yet: compare current pricing, pause-on-idle behaviour and region before picking.
- **Local-first holds:** the laptop runs the whole account path on SQLite with no network.

## 6. Not in this scope

Encrypted ingestion and per-user knowledge (spec Phase 2), billing and paid tiers, Personal Cosmos, the social layer, bring-your-own-key UI polish, the open persona tier for Pocket (B-25), provider privacy register beyond what the privacy page must say (B-26).

## 7. Risks

- **Cold start:** the hosted engine sleeps on its free tier; a first-time visitor waits. The keep-warm cron helps; measure before inviting.
- **Provider cap:** B-16 and B-20 stand. AC5 is the mitigation, not a cure.
- **Scope pull:** the summoning ceremony invites lore and polish. Ship the three fields first.
- **Two stores:** file and database backends must pass the same tests, or local and hosted drift.

## 8. First session

1. A1 direction and A3 are ruled. Mark picks the Postgres host and confirms A2.
2. AC1 behind the existing `users` interface with tests against both backends.
3. Turn `ALLOW_REGISTER` off for good once AC2 lands; delete the legacy route after.
