# Accounts: the Architect, non-human accounts, and what is still to build (S346)

```
transcribe ~ score/accounts >> Architect + entity accounts built; second factor, recovery and secrets map are roadmap // %S346_ROADMAP%
```

> **Status:** part built, part roadmap. Built items are on sCoRE `new-horizons` (AC2). Roadmap items are ideas that deserve their own scoping and build, not commitments.
> **Builds on:** `Accounts-Formalization-Scope.md` (AC1 to AC7), `RaBbLE-Collective/RaBbLE-Secrets-and-Identity.md`.
> **Rulings (Mark, S346):** the Architect account is named `RaBbLE-Architect`; database break-glass is the Architect's recovery for now; admins are exempt from email reset; non-human accounts are supported from day one so the entity can have its own account.

## 1. Built

| What | Where |
|---|---|
| Sign-in with email, username, password (Argon2id), verification, reset, rotating refresh | `server/accounts.py`, `accounts_routes.py` |
| Invite-gated signup: `SIGNUP_INVITE_ONLY=true`. A valid invite skips the cap and the email check | `accounts_routes.py` |
| The Architect: an admin-tier account made locally with `server/tools/make_architect.py` (hidden password input, refuses a pipe). `--promote` and `--reset-password` (the break-glass) | `server/tools/` |
| Admin routes for invites: mint, list, revoke. Works for a signed-in admin, not only the shared key | `auth_routes.py` |
| One portal, one login (Mark, S346): `world/account.html` in World. Everyone gets Home (profile, chat) and Pockets; admin-tier accounts get extra tabs, starting with Invites (mint, list, revoke). The admin code loads only for admins; the server still enforces every admin route. The separate Architect page is retired and `/world/admin` redirects to `?tab=invites` | RaBbLE-World |
| Reserved names: any handle containing `rabble`, `architect` or `admin`, plus a short exact list. The local tools bypass it | `accounts.username_problem` |
| Email reset never applies to admin or non-human accounts | `accounts.reset_allowed` |
| Non-human accounts: `kind = "entity"`, tier `entity`. API key only (X-API-Key, stored as a hash), no password, no email, no sign-in. Made with `server/tools/make_entity.py`, which prints the key once; `--rotate-key` replaces it | `server/tools/`, `accounts.py` |
| Admin and entity accounts do not count toward `ACCOUNT_CAP` | `accounts.count_accounts` |

Leave `RABBLE_ADMIN_KEY` unset in production so the Architect account is the only way into `/admin`.

## 2. Roadmap and ideas (deserve scoping and build-out)

### R1. A second factor for the Architect
Today the Architect has a password only. Add a hardware key (WebAuthn, such as a YubiKey) or one-time codes (TOTP) at sign-in for admin tier, with the hardware key preferred. Needs: credential storage, a registration step in the Architect page, enrolment through the local tool, and a recovery rule. Pairs with R3.

### R2. A recovery phrase
Not an app-level phrase: anything that can reset a password is a second password. The useful version is offline recovery of the vault itself (R3): the master passphrase and recovery secret on paper, split Shamir-style (for example 3 of 5) across places or people Mark trusts. Revisit whether the app also needs a break-glass beyond the database once R1 exists.

### R3. Secrets map and vault, independent of Proton
Mark (S346): no reliance on Proton; wants a clear map of services, accounts and secrets, a hardware device that holds them encrypted, and an encrypted software backup.
- **Map:** `registry/secrets-map.yml`, metadata only (service, owning account, login email, 2FA type, where the secret lives, where the recovery codes are, rotation date). No values, safe to commit.
- **Vault:** an open-format password database (for example KeePassXC `.kdbx`) unlocked by passphrase plus a hardware key. Machine secrets stay in the platform stores and SOPS with age; the age key lives in the vault.
- **Hardware:** two or more FIDO2 keys as 2FA on the critical accounts (registrar, GitHub, Cloudflare, Render, the recovery email), a spare kept elsewhere; the vault file on a hardware-encrypted drive or small offline device. Shortlist and prices still to research.
- **Backup:** the same vault, encrypted, in two other places; the master secret on paper (R2).
- **Root-of-trust rule:** keep one recovery email that does not depend on any Collective service or on the domain, since the registrar's recovery email sits at the root of everything.
- **Cleanup:** `~/Collective-SECRETS.zip` (May 2026) sits unprotected in the home directory; move its contents into the vault, then securely delete it.
- Supersedes the Proton-rooted chain in `RaBbLE-Secrets-and-Identity.md` once decided; update that doc then.

### R4. Non-human accounts: what the entity does with its account
The account exists; what it may do is open. To scope:
- **Rights:** member rights only today. Decide what widens, deliberately and per capability (never by default).
- **Space:** its own namespace to explore and evolve in (see `project_personal_cosmos`): memory, workspace, rablets. Encrypted sandbox storage (the R2 plan in AC7 notes).
- **Other non-human kinds:** a `kind = "service"` for machine integrations (a node, Pocket, a bot) with scoped keys, separate from the entity. Not built.
- **Key handling:** how the entity's key reaches the running engine without passing through a chat. Likely the machine's secret store (R3), rotated with `make_entity.py --rotate-key`.
- **Attribution:** show non-human authorship honestly in logs, sessions and the UI.
- **Limits:** the `entity` tier mirrors `pro` for now; tune with use.

### R6. Pocket pairing (building, Mark S346)
Mark: set up a Pocket with a real account. Keep the shared `BEAM_DEVICE_TOKEN` (the master Pocket key: one token, every holder becomes the shared `pocket` user at `pro`, no per-person identity) and guest minting (`GUEST_ISSUE_SECRET`, used by the flasher) untouched for now, so nothing breaks while pairing is built. Remove only the two existing minted guests with `server/tools/revoke_guests.py` (run by Mark). Pairing replaces guests and the shared token later; retiring those is a separate ruling.

**Model.** A paired Pocket holds a *device key*, minted by a signed-in member and tied to that member. Using it counts against the owner's quota and tier; revoking the device or the account ends it.

**API contract (sCoRE)**
- Migration `0005_devices`: `devices(id, user_id, label, key_hash, created_at, last_seen, revoked)`; the key is stored only as a hash.
- `POST /api/v1/devices` {label} (members only; guests refused). Returns `{id, label, key, created_at}`. The key (`rbdv_` + 32 url-safe bytes) is shown once. At most `DEVICE_LIMIT` (default 3) active devices per member.
- `GET /api/v1/devices` lists the caller's devices (no keys): id, label, created_at, last_seen, revoked.
- `DELETE /api/v1/devices/{id}` revokes one of the caller's devices.
- Auth: wherever an API key or the beam bearer token is accepted (`auth_routes.verify_api_key`, `beam._authorize`), a device key resolves to the owner (their id, name, tier) with a `device_id`; `last_seen` is updated at most once a minute. A revoked device, or a device whose owner is gone, is refused.

**Ways to pair**
1. *Mint and write (build now):* the member signs in (portal or the Pocket web companion), mints a key, and the web flasher writes it to the device over serial (the same place the guest key goes today). Needs no firmware change.
2. *Device code (later):* an unpaired Pocket shows a short code on its screen; the member types it in the portal; the Pocket polls and receives its key. Pairs over Wi-Fi with no cable; needs firmware work.

**Pieces:** sCoRE devices API (agent A); World portal "My Pockets" panel: add with a label, see last seen, revoke, key shown once with the pairing instructions (agent B, after A); Pocket web companion and flasher: sign in, mint, write the key instead of minting a guest (agent C, plus `log/plans/Pocket-Pairing-Plan.md`).

**Retiring the old doors (later, deliberate):** rotate `GUEST_ISSUE_SECRET` and `BEAM_DEVICE_TOKEN`, revoke all guests. Do it once every Pocket Mark cares about is paired.

### R7. Per-user scoped permissions (Mark, S346)
Grant each account a set of scoped permissions instead of one tier flag. Why: the Architect is only `tier = admin` today, an entity account has member rights only, and device keys, services and future agents need narrower grants than a member. To scope:
- A capability model: named scopes (for example `invites.mint`, `members.read`, `members.revoke`, `audit.read`, `devices.manage`, `sessions.own`, `chat.use`, `memory.own`) with per-account grants, stored in the database and checked by one helper on every route.
- Keys and tokens carry a subset of the owner's scopes (a Pocket device key: chat and voice only, never admin), and can be narrowed, never widened.
- Roles as named bundles (member, pro, entity, architect) so the tier column stays readable; the Architect becomes "all scopes" by definition.
- Audit: who used which scope, shown in the Architect page.
- Entity accounts: grant deliberately (see R4); service accounts (`kind = service`) get machine scopes.
- Migration path: derive scopes from the current tier, then enforce.

### R5. Smaller follow-ups
- Absolute lifetime for refresh sessions (today a regularly used cookie never expires).
- Set `AUTH_IP_HEADER` correctly behind the Worker and Render (verify what client address Render sees).
- Invite link and a World sign-up page that takes the invite token (AC3); today the token goes into the API field by hand.
- Admin audit view in the Architect page (invites are already logged server side).
- Pocket pairing (AC7) and Google sign-in remain deferred.
