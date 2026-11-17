# Pocket pairing plan (AC7)

Status: v0.2, 2026-11-17 (S347). Built and tested with mocks: the companion is gated behind member sign-in and pairs on flash (section g). Not deployed, not run against real sCoRE or hardware. Device code (c) is design only. Guest keys and `BEAM_DEVICE_TOKEN` keep working server side (`/api/guest`, `/api/summon` untouched) but the page no longer offers them.

**S347 update (guest Pockets retired).** sCoRE `beam._authorize` now accepts only device keys (`rbdv_`), entity keys and member/admin JWTs; the shared `BEAM_DEVICE_TOKEN` and guest keys are refused unless `BEAM_ALLOW_GUEST_POCKETS=true` (testing only, default off), so any statements below that the beam accepts them describe the older behaviour. The Worker no longer has `/api/guest` or `/api/summon` or the `GUEST_ISSUE_SECRET`. A Pocket still holding a guest key or the shared token stops connecting at the sCoRE deploy until re-flashed with a device key. Admin accounts are exempt from `DEVICE_LIMIT`; metering and limits: `Accounts-Architect-and-Entity-Roadmap.md` R8.

Sources: `RaBbLE-Pocket/companion-app/web/{worker/index.js,public/portal.js,CONTEXT.md}`, `RaBbLE-Pocket/firmware/core/rabble_core/src/rabble_settings.c`, `firmware/entities/RaBbLE/{src/rabble_setup.c,rabble_beam/src/rabble_beam_score.c}`, `RaBbLE-sCoRE/server/beam.py`, `RaBbLE-Pocket-Beam-Protocol.md`.

## a. How a Pocket gets and stores a token today

- Storage: NVS string `beam_token` (max 255 chars, `RABBLE_BEAM_TOKEN_MAX`), loaded into RAM at boot (`rabble_settings.c`, `load_str("beam_token", ...)`; setter `rabble_settings_set_beam_token(token, append)`). The URL is the NVS string `beam_url`. A key survives updates (Automatic mode keeps NVS) and is lost by a Fresh flash (erase all).
- Setting it: serial console command `>beam.token=<value>` (and `>beam.token+=` to append in chunks), handled in `rabble_setup.c` (`strcmp(name, "beam.token")`, reply `REPLY_OK` or `REPLY_TOKEN` on a bad size). Values are masked in the log. `@status` reports only whether a token is set (`rabble_settings_beam_token_len() > 0`), never the value.
- Use: `dial()` in `rabble_beam_score.c` sends `Authorization: Bearer <token>` on the WebSocket upgrade to `beam_url`. Server side `beam.py:_authorize` accepts, in order, the shared `BEAM_DEVICE_TOKEN` (becomes user `pocket`, tier `pro`), then `auth_routes.verify_api_key` (an `rbbl_` account or guest key), then a JWT. R6 adds `rbdv_` device keys to `verify_api_key`, so no beam change is needed for them.
- Where it comes from in the companion: `portal.js` `autoGuestKey()` runs after a flash when `@status` reports no token; it calls `issueGuestKey()`, which POSTs `/api/guest` to the Worker; `guest()` in `worker/index.js` calls sCoRE `POST /api/v1/users/guest` with header `X-Guest-Secret` (secret `GUEST_ISSUE_SECRET`, never sent to the browser) and returns `{api_key, handle}`; the page then runs `c.set('beam.token', r.api_key)`. Other sources: invite redeem (`/api/summon`) and a pasted key (key tab), both ending in `c.set('beam.token', ...)`. A device that already reports a token is never given a new one.

## b. Mint-and-write (build now)

Flow on the companion, after the flash and the `@status` check, in the Setup form:

1. A third tab, "Sign in", beside "I have an invite" and "I have a key": username or email, password, optional label (default: board + date).
2. Send posts `{identifier, password, label}` to the Worker `/api/pair` (built, see below). The Worker signs in to sCoRE (`POST /api/v1/auth/login`), mints (`POST /api/v1/devices` with `Authorization: Bearer <token>`), and returns `{key, id, label}`. The password and the session token exist only inside `worker/pairing.js` `pair()`; they are not stored, logged or returned. This also avoids any CORS question on sCoRE.
3. The page runs `c.set('beam.token', key)` (the same call as the guest key), shows the key once in the existing key box with "Shown once. It is also saved on the Pocket.", and a success line: "Paired as <label>. This Pocket now counts against your account."
4. Errors, by `code` in the JSON reply:
   - `sign_in_failed`: "Sign-in failed. Check your username or email and your password." Nothing is minted, nothing is written.
   - `device_limit`: "Device limit reached. Remove a Pocket you no longer use in the portal (My Pockets), then try again." (Limit is `DEVICE_LIMIT`, default 3.)
   - `not_member` (guest account), `rate_limited`, `unreachable`, `upstream`: plain messages from `worker/pairing.js`. The device keeps whatever token it had; a failed pair never clears one.
5. A Pocket that already has a token is not paired silently: the Sign-in tab shows "This Pocket already has a key. Pairing replaces it." and requires a tick box (guards the 5-second-old guest key and the shared token, which Mark may want to keep working).

Built (Pocket commit `spark ~ pocket >> companion: pair a Pocket by minting a device key from a member sign-in`): `worker/pairing.js` (`pair`, typed `PairError`, `errorBody`, `cleanLabel`), the `/api/pair` route in `worker/index.js` (behind the early-access cookie, 10 per hour per IP+cookie best effort), `test/pairing_test.mjs` (8 checks with a fake sCoRE; run `node test/pairing_test.mjs` from `companion-app/web`), a line in `companion-app/web/CONTEXT.md`. The existing `test/portal_test.py` still passes (run unmodified against the working tree). Assumption to confirm with the sCoRE agent: the device-limit refusal is 400, 409 or 422 with "limit" in `detail`; `pair()` matches that, and any other non-2xx on mint becomes `upstream`.

Not built: the page UI. It needs edits to `public/portal.js`, which holds someone's uncommitted work (console reply parsing in `DeviceConsole.onLine` and `status()`), and `test/portal_test.py` (needs a pairing check). Both were left untouched.

### Proposed companion patch

Hand-written against the committed `portal.js` and `index.html`, not applied, not run; line offsets will move. The `index.html` part is new markup and could land on its own. The `portal_test.py` addition is a mocked `/api/pair` route plus one check that a good sign-in sends `>beam.token=rbdv_...` and a `device_limit` reply sends nothing.

```diff
--- a/companion-app/web/public/index.html
+++ b/companion-app/web/public/index.html
@@ tab row (id tabKey)
                 <button type="button" role="tab" class="pk-tab" id="tabKey" aria-selected="false">I have a key</button>
+                <button type="button" role="tab" class="pk-tab" id="tabPair" aria-selected="false">Sign in</button>
@@ after #paneKey
+              <div id="panePair" hidden>
+                <label class="rabble-label">Username or email
+                  <input class="rabble-input" id="pairId" autocomplete="username" spellcheck="false"></label>
+                <label class="rabble-label">Password
+                  <input class="rabble-input" id="pairPass" type="password" autocomplete="current-password"></label>
+                <label class="rabble-label">Name for this Pocket
+                  <input class="rabble-input" id="pairLabel" maxlength="40"></label>
+                <label class="pk-mode" id="pairReplaceRow" hidden><input type="checkbox" id="pairReplace">
+                  This Pocket already has a key. Replace it.</label>
+              </div>
--- a/companion-app/web/public/portal.js
+++ b/companion-app/web/public/portal.js
@@ the tab loop (['tabInvite','paneInvite','tabKey','paneKey'] ...): add a third tuple for tabPair/panePair, and hide panePair when the others are chosen.
@@ before autoGuestKey()
+// Sign in as a member; the Worker mints a device key. The password goes only to the Worker.
+async function pairWithAccount(c) {
+  const board = BOARD_INFO[state.board]?.short || state.board || 'Pocket';
+  const label = $('pairLabel').value.trim() || `${board} ${new Date().toISOString().slice(0, 10)}`;
+  say('setupMsg', 'Signing in…');
+  const r = await api('/api/pair', { identifier: $('pairId').value, password: $('pairPass').value, label });
+  $('pairPass').value = '';
+  if (state.console !== c) throw new Error('The console changed. Connect again.');
+  await c.set('beam.token', r.key);
+  $('keyText').textContent = r.key;
+  $('keyBox').hidden = false;
+  log(`Paired as "${r.label}"`);
+  return r;
+}
@@ in the setup submit handler, new branch before the invite and key branches
+    if ($('tabPair').getAttribute('aria-selected') === 'true') {
+      const had = state.lastStatus?.device?.beam?.token;
+      if (had && !$('pairReplace').checked) throw new Error('This Pocket already has a key. Tick "Replace it" to pair.');
+      const r = await pairWithAccount(c);
+      say('setupMsg', `Paired as ${r.label}. This Pocket now counts against your account.`, 'good');
+    }
```

`api()` already throws `data.error`, and the Worker's `error` strings are the user-facing messages above, so no extra mapping is needed in the page.

### g. Built S347: sign-in gate (supersedes the Sign in tab patch above)

Mark's rulings: the flasher is gated behind login; a flashed Pocket gets a freshly minted device key for the signed-in account automatically; no pasted keys, no anonymous guest key.

- Worker: `POST /api/login` (sCoRE `/api/v1/auth/login`; guest and entity accounts refused with `not_member`; 10 per hour per IP) sets cookie `pocket_session` (HttpOnly, Secure, SameSite=Strict, 1 hour, AES-GCM encrypted under a key derived from `ACCESS_SIGNING_KEY`, so the sCoRE token is neither readable by page JS nor in plain text). `GET /api/me` returns `{username}` or 401 `session_expired`; `POST /api/logout` clears it; `/api/lock` clears it too. `POST /api/pair {label}` mints from the cookie (no password) and returns `{key,id,label}`; a 401 from sCoRE clears the cookie and answers `session_expired`. Behind the early-access cookie, which is unchanged. Files: `worker/index.js`, `worker/pairing.js` (`login`, `mint`, `pair`), `worker/session.js`.
- Page: a sign-in card; the flasher is hidden (not destroyed) until signed in, so an ended session mid-flow returns to sign-in and, after signing in again, finishes pairing with no second flash. After a flash and the `@status` check it pairs: Fresh flash or no key reported mints and runs `c.set('beam.token', key)`, shows the key once and "Paired as <label>"; an Automatic update that reports a token says "Already paired" and mints nothing. Send adds Wi-Fi and pairs only if the device still has no key. A failed pair never clears an existing token. Sign out closes the console and re-gates.
- Errors in plain words: `sign_in_failed`, `not_member`, `device_limit` (points to the Pockets tab at dev.joinrabble.world/world/account), `rate_limited`, `unreachable`, `upstream`, `session_expired`.
- Tests: `node test/pairing_test.mjs` (17 checks, fake sCoRE, Worker routes) and `test/portal_test.py` (Playwright, mocked Worker and serial).
- Unverified: the real sCoRE login response shape (the code reads `user.handle`/`username` and refuses `kind`/`account_type`/`role` of guest or entity, and `is_guest`/`is_entity`; if sCoRE names these differently only the mint 403 catches guests), the token lifetime (cookie is 1 hour regardless), the device-limit status code, Secure cookie behaviour on the deployed host, behaviour on hardware.

## c. Device code flow (later)

An unpaired Pocket shows a short code; the member types it in the portal; the Pocket polls and receives its key. No cable, no companion, works for a Pocket already in someone's hands.

- Firmware (about 4 to 6 days, hardest part is the screen and recovery states): an "unpaired" state when `beam_token` is empty and Wi-Fi is up; `POST /api/v1/devices/code` over HTTPS (not the WebSocket, which needs a token) returning `{code, poll_secret, expires_in}`; show the code (8 chars from an unambiguous alphabet, grouped 4-4) and a countdown on the Pocket screen; poll `POST /api/v1/devices/code/poll` with `poll_secret` every 3 s with backoff; on success store the key with `rabble_settings_set_beam_token`, show "Paired", wipe the secret; on expiry show a new code. New states in the beam client (`rabble_beam_score.c`) and one new screen in the entity; host tests for the poll state machine in the existing fixtures style.
- sCoRE (about 1 to 2 days): table `device_codes(code_hash, poll_secret_hash, user_id null, label, expires_at, claimed_key_once)`; `POST /api/v1/devices/code` (unauthenticated, strict per-IP rate limit); `POST /api/v1/devices/code/claim {code, label}` (member, enforces `DEVICE_LIMIT`, mints the key); `POST .../poll` returns `pending`, `expired` or the key once, then deletes it. Codes live 10 minutes, are single use, and attempts are limited per code and per member to stop guessing.
- Portal (about 1 day): an "Add by code" field in My Pockets.
- Security notes: the unauthenticated code endpoint is a spam surface (cap it); the poll secret stops someone who only saw the code from taking the key; the key is released once and never stored in clear on the server.
- Prerequisite: Wi-Fi must already be set, so first setup still needs the companion (or a captive-portal step, out of scope here).

## d. Revoked key: what the Pocket does, and how to recover

Today the firmware does not tell a rejected token from any other connection failure. The WebSocket upgrade is refused by sCoRE (`_authorize` returns None), `dial()` ends in `dial_failed()` or `on_lost()`, which report "Dial failed" or "Connection lost" (`RABBLE_BEAM_UNREACHABLE`), show `TXT_NO_LINK` or `TXT_LOST`, and retry with backoff from 5 s to 120 s (`BACKOFF_MIN_S`, `BACKOFF_MAX_S`). So a revoked Pocket looks like a Pocket with no network, and retries forever. Nothing is damaged.

Recommended (small firmware change, about 1 day): read the HTTP status of the failed upgrade (esp_websocket_client's error event carries it, to confirm) and, on 401, report a distinct state `RABBLE_BEAM_UNAUTHORIZED` with the text "Key not accepted. Pair again." Back off to the 120 s cap instead of retrying every 5 s. Recovery is re-pairing: the member reconnects the Pocket to the companion and signs in again (the replace tick box covers the existing token), or uses the device code flow when it exists.

Companion: `@status` carries `beam.token` as set/unset only, so the companion cannot see a bad key. Its explanation of a 401 comes from the `beam.test` result it already runs after Wi-Fi connects: if the test fails with the unreachable state and Wi-Fi is up, say "The Pocket is online but sCoRE did not accept its key. If you removed this Pocket in the portal, pair it again with Sign in." Once the firmware reports the unauthorized state in `@status`, show that text exactly instead of inferring.

## e. Migration

- (S347: the page no longer offers the guest key, invite or pasted key; the points below describe the server side, which is unchanged.) Nothing changes for existing keys. Guest keys (`GUEST_ISSUE_SECRET`, `/api/guest`) and the shared `BEAM_DEVICE_TOKEN` stay accepted. The companion's auto guest key after a flash stays as the default until the Sign in tab ships and Mark rules otherwise; the Sign in tab is an addition, not a replacement.
- A Pocket already in someone's hands (for example Dad's): it holds a guest key or the shared token in NVS. Pairing writes `beam.token` over serial, so they need the cable once: open the companion, Connect to the device (no reflash needed, settings are kept), Sign in, tick Replace. The old key is not revoked by this; revoking old guests is a Mark step (`server/tools/revoke_guests.py`). Until the device code flow exists, a Pocket that cannot be reached by cable stays on its old key.
- Order of retirement (R6, later and deliberate): pair every Pocket Mark cares about; then rotate `BEAM_DEVICE_TOKEN` and `GUEST_ISSUE_SECRET` and revoke guests. Before that, make the Worker stop minting guests only by a separate ruling.
- Deploy order for mint-and-write: sCoRE devices API live, then Worker deploy (`wrangler deploy`, Mark), then the page UI.

## f. Open questions for Mark

1. Should the Sign in tab become the default for new flashes, with the guest key kept only as a fallback ("Skip, use a guest key")? Or keep the guest key as default for now?
2. The password passes through the Pocket Worker (Cloudflare, never stored or logged). Acceptable, or must sign-in happen in the browser straight to sCoRE (needs sCoRE CORS for `pocket.joinrabble.world` and the token held in page memory)? The portal could also hand the page a one-time pairing token instead, so the companion never sees a password.
3. Device limit of 3 per member: enough for Mark (Pocket, Cyberdeck, spares)? Should the Architect be exempt?
4. Approve the firmware change for a distinct "Key not accepted" state (d), and when: now, or with the device code work?
5. Is device code worth building before the first non-Mark Pocket ships, or is cable pairing enough for Genesis?
6. Should a Fresh flash revoke the device's previous key when the same member re-pairs (one Pocket, one key), or leave old keys until removed in the portal?
7. Pairing replaces a key on the device. Do you want a confirmation that names the old key's owner, or is the tick box enough?
