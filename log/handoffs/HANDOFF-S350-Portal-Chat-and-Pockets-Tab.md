# HANDOFF-S350 (B): portal home chat with saved conversations, and the Pockets tab linking to the workbench

Date: 2026-11-18. Repos: RaBbLE-World (the portal), RaBbLE-sCoRE (server), RaBbLE-Pocket (the workbench Worker, read only unless noted). Branch `new-horizons`. Read `HANDOFF-S347-Pocket-Accounts-Metering.md` first.
This runs in parallel with the mapper session (HANDOFF-S350 A): do not edit `RaBbLE-Pocket/companion-app/web/public/*` or the firmware.

## What Mark asked for

1. The portal home shows the entity with the chat box visible, and chats are saved.
2. Chats and captures are not limited to the Pocket: a chat can be picked up on another surface, and the log records where a message or chat started: Pocket only, web only, or blended.
3. The Pockets tab lists the paired Pockets (name, firmware, last seen), can revoke, and has a button that opens the Pocket workbench with the session transferred cleanly.
4. All pages must require sign-in.
5. A local dev proxy so local World can use the real sCoRE without CORS changes (see below).

## State you inherit

- World `account.html` / `js/RaBbLE-account.js` already have a Pockets tab: list, revoke (two-click), add-a-Pocket with a one-time key and a "send to my Pocket over USB" button (`js/RaBbLE-pocket-serial.js`). With the workbench live, pairing now happens there. Replace the add-a-Pocket flow with a **"Set up or manage my Pockets"** button that opens the workbench with the session handed over; keep list and revoke. The portal list shows firmware (`d.fw`) already.
- **Handoff contract (built and deployed)**: open `https://pocket.joinrabble.world/#token=<sCoRE access token>&name=<username>`. The fragment never reaches a server; the workbench (`portal.js` `takeHandoff`) removes it from the URL at once and POSTs it to its Worker `/api/handoff`, which asks sCoRE to verify it is a member session (`GET /api/v1/devices`), then seals it in an HttpOnly session cookie (1 hour, `Worker/session.js`). Local workbench: `http://localhost:8799` (`cd RaBbLE-Pocket/companion-app/web && wrangler dev --port 8799 --local`, it talks to the REAL sCoRE). Add `RABBLE_POCKET_URL` to `world/js/RaBbLE-config.js` (prod `https://pocket.joinrabble.world`, local `http://localhost:8799`). The token lives in `RaBbLESession.token()` (sessionStorage). Check the access-token lifetime: the workbench cookie is 1 hour.
- sCoRE device routes (deployed): `GET /api/v1/devices` (rows now carry `fw`, `fw_seen`, `fp`), `DELETE /api/v1/devices/{id}` (deletes the row: revoked Pockets no longer exist), `POST .../report`, `PATCH .../{id}` (rename). Limit 3 active devices per member (admin exempt).
- sCoRE already keeps Pocket conversations and captures per member: tables `pocket_conversations`, `pocket_turns`, `pocket_notes` (migration 0006), routes `/api/v1/pocket/notes` and `/conversations` (list, get, delete). The portal has Captures and Conversations tabs (`js/RaBbLE-account-captures.js`). **Web chat is not persisted at all today**: `POST /api/v1/chat` (sCoRE `main.py`) streams and forgets. `pocket_store.py` keys conversations to a device (`device` column), `beam.py` writes turns for Pockets.

## Design to build (suggested)

- **Cross-surface conversations**: add migration 0010 (portable SQL, SQLite and Postgres; the last applied is 0009): `origin` on the conversation (`pocket`, `web`, `blended` is derived when turns come from more than one surface) and `surface` on each turn (`pocket`, `web`, later `tui`, `desktop`). Routes: `POST /api/v1/pocket/conversations` (create, web), `POST .../conversations/{id}/turns` (append), and let `/api/v1/chat` take a `conversation_id` and persist both sides for members. A Pocket picks up the latest open conversation (today `new_conversation` rotates per device); a "continue on this surface" action in the portal. Members only: `pocket_store.persists(user)` already excludes guests, entities and shared keys.
- **Portal home**: the entity (NeBuLA `<rabble-entity>`, as on the face page) and a visible chat box, signed in; saved conversations on the Conversations tab, with the origin shown. Keep the portal's CSP in mind (`world/_headers`: `connect-src 'self' https://score.joinrabble.world`).
- **Auth**: every portal page requires sign-in (no guest chat there).
- **Dev proxy**: local World at `localhost:8080` is pointed at a local sCoRE (`:8000`) by `RaBbLE-config.js`; prod sCoRE rejects the localhost origin (CORS). Preferred fix: make the dev server (`RaBbLE-Grimoire/spells/dev-cdn.js` / `dev-serve.sh --world`) proxy `/api/*` to `https://score.joinrabble.world` so local pages stay same-origin. Do NOT add localhost to prod `CORS_ORIGINS`. A throwaway local sCoRE for testing: `cd RaBbLE-sCoRE/server && DATA_DIR=<tmp> CORS_ORIGINS=http://localhost:8080 JWT_SECRET=dev ../.venv/bin/uvicorn main:app --port 8000` (never source `.env.local`: it holds prod secrets); seed a member with `accounts.create_account(...)` + `accounts.mark_verified(...)`.
- Longer term (Mark mentioned, not decided): one shared sign-in cookie on `.joinrabble.world` issued by the `score.joinrabble.world` proxy Worker, retiring the handoff and the sessionStorage token; bearer API stays for devices and the TUI. See the S348 discussion: CSRF headers, subdomain trust, localhost dev mode.

## Deploying

- sCoRE: merge `new-horizons` into `release/0.1.0` (VERSION on the release branch stays `0.1.1-dev`), run the suite under Python 3.12 (`uv venv --python 3.12`; the TUI test files fail to collect on both branches and are not run by Render), push `release/0.1.0` (Render auto-deploys), then check Neon read-only (project `little-smoke-00157786`) that a new migration applied. A deploy check that polls for `401` is wrong: unauthenticated calls return `403`.
- World: Cloudflare Pages/Worker from `main`/CI (`wrangler.jsonc` serves the repo root as static assets).
- Commit style: `[impulse] ~ [organ] >> [revelation] // %STATE%`, no AI trailers. Mark approves outward actions (push, deploy, publish) for each release.
