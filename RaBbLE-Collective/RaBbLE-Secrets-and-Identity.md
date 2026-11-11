# Secrets & Identity — How the Collective Owns Itself

```
transcribe ~ collective >> secrets, accounts, identity model + episode signing ceremony documented // %SECRETS_IDENTITY%
```

> How the RaBbLE Collective holds its own accounts, API keys, and authentication
> separately from Mark's personal identity — and the procedure for sealing an
> episode to `main` under the Collective's own name.
>
> Established S60 (2026-06-09), pre-EP1, as Collective-owned service accounts
> (Cloudflare, GitHub org, Groq, OpenRouter, Render) come online. Companion to
> [RaBbLE-Deployment-Architecture.md](RaBbLE-Deployment-Architecture.md) and
> [RaBbLE-Cloudflare-Integration.md](RaBbLE-Cloudflare-Integration.md).

---

## The principle

**The Collective is an entity. It owns its own things.** As RaBbLE moves toward
Episode 1, service accounts stop belonging to Mark personally and start belonging
to the Collective, under a single root identity:

- **Root identity:** `RaBbLE-Collective@proton.me`
- Everything the Collective owns — Cloudflare, the GitHub org, Groq, OpenRouter,
  Render, the domain registrar — lives under this email.

This is identity-before-integration applied to operations: the entity holds its
own credentials before its limbs are wired together. Mark remains the
**administrator and breakglass owner**, never the *owner of record* for Collective
services.

---

## Separate two problems

Secrets management feels scary because two different concerns get bundled. Keep
them apart — they have different homes.

| Concern | Question | Home |
|---|---|---|
| **Identity / ownership** | *Who* owns the account? | The Collective (proton email), administered by Mark |
| **Secret storage** | *Where* do the keys live, how are they backed up? | Two tiers, below |

---

## Two tiers of secrets

### Tier 1 — Human / account credentials → password manager

Logins, TOTP seeds, **2FA recovery codes**, billing details. These are identity
credentials a human uses to log in.

- **Recommended:** **Proton Pass** — already inside the proton account, E2E
  encrypted, supports vaults. (Self-host purists: Bitwarden / Vaultwarden fits the
  local-first ethos.)
- Make one vault: **"RaBbLE Collective."** It holds: the proton login itself,
  Cloudflare, the GitHub org, Render, Groq, OpenRouter, the domain registrar —
  **each with its 2FA recovery codes.**
- This vault **is** the account backup. Enable export.

### Tier 2 — Machine / deployment secrets → platform store + encrypted-in-repo

API keys, `JWT_SECRET`, `GROQ_API_KEY`, `OPENROUTER_API_KEY`, `RABBLE_ADMIN_KEY`.
These are consumed by running code, never by a human directly.

- **Production source of truth = the platform's own store.** Render env groups,
  Cloudflare `wrangler secret`. sCoRE's `render.yaml` already declares its three
  secrets with `sync: false` — the value is set once in the Render dashboard and
  never touches git. This is correct; keep it.
- **Local-first + version-controlled + backupable = SOPS + age.** `age` is one
  tiny binary, one keypair, no infrastructure. Commit an encrypted
  `secrets.enc.yaml`; decrypt offline anytime. The **age private key is backed up
  in the Tier-1 vault.** This satisfies "the laptop offline still runs the loop"
  *and* "backed up": the encrypted blob lives in git, the one key that unlocks it
  lives in the vault.
- **Never commit plaintext `.env`.** sCoRE already gitignores `server/.env` (only
  `.env.example` is tracked) — the correct pattern.

> The API *key* is a Tier-2 machine secret. The *account that mints it* is a
> Tier-1 identity credential. Same service, two tiers.

---

## Root-of-trust chain (the mental model)

```
proton.me account + its 2FA          ← master identity (RaBbLE-Collective@proton.me)
   └─ password manager (Proton Pass)  ← account logins + the age private key
        └─ age key                     ← decrypts repo secrets (SOPS)
Render / Cloudflare native stores      ← hold the live production copies
```

**Breakglass.** The proton email is the single point of failure — lose it and
everything downstream cascades. Mitigate:

- Store the **Proton recovery phrase + password-manager recovery offline**
  (printed, or USB in a drawer).
- Keep **Mark's personal GitHub account as a co-owner of the org**, so a lost
  proton email never orphans the code.

---

## GitHub: the Collective org

**A GitHub organization is not a login.** It is a first-class identity (its own
name, URL, billing email, repos) *administered by* personal user accounts. You
never "log in as" the org — you log in as yourself and act as its owner.

### Creating it

1. Logged in as Mark's personal account: **+** → **New organization** → **Free**.
2. Org name: **`RaBbLE-Collective`** → `github.com/RaBbLE-Collective`.
3. Contact email: `RaBbLE-Collective@proton.me`.
4. "Belongs to" → personal vs. business is only a **Terms-of-Service
   acknowledgment**; it changes nothing functional and there's no toggle to undo
   it. Either is fine.
5. After creation: **Settings → Billing** → billing email = proton too. Optionally
   require org-wide 2FA.

### The dedicated `RaBbLE-Collective` role account (optional, recommended)

GitHub permits **role/machine accounts** as long as each has its own email (proton
satisfies this). A `RaBbLE-Collective` user account under the proton email makes the
identity uniform with Cloudflare/Groq/OpenRouter, and supports future handoff.

**Two conditions, non-negotiable:**

1. **Always two owners** — the Collective account *and* Mark's personal account. A
   rarely-used role account has fragile recovery; never make it the sole owner.
2. **Treat it as high-value** — unique strong password + 2FA, both in the vault,
   recovery codes offline.

It does **not** buy you deployment (Render uses a GitHub App, see below) and Mark
keeps committing **as himself**. Create it for identity and handoff, not because
the pipeline needs it. Optional for EP1.

### Transferring repos into the org

The transfer happens **on GitHub**, not locally. Start with EP1 repos only
(`RaBbLE-sCoRE`, `RaBbLE-World`); leave the rest in personal until there's a reason.

- **Web UI:** repo → **Settings → Danger Zone → Transfer** → new owner
  `RaBbLE-Collective`.
- **CLI:** `gh api -X POST repos/markm1206/<repo>/transfer -f new_owner=RaBbLE-Collective`

GitHub preserves issues, PRs, releases, stars, and **a redirect from the old URL**.
Commit authorship is unchanged.

**Fix-up afterward (the part people forget):**

1. **Update each local clone's remote** (don't depend on the redirect):
   `git -C <repo> remote set-url origin git@github.com:RaBbLE-Collective/<repo>.git`
2. **Reconnect Render** — a service tied to `markm1206/<repo>` won't follow the
   transfer. Install the **Render GitHub App on the org**, grant the specific repos.
3. **Grep for hardcoded `github.com/markm1206/...`** — `setup.sh`, READMEs, docs, CI.

**Sequence:** transfer the two EP1 repos → verify Render deploys against the org →
*then* transfer the rest. One vertical slice first.

---

## The Commit Identity Model (three tiers)

Git commit authorship is just a name+email pair, independent of who pushes. The
Collective uses that to make *who signed what* legible in the history. Three commit
identities, escalating in formality (model finalized S62):

| Identity | Author | Used for | Tags |
|---|---|---|---|
| **Mark** | `markm1206` (personal) | Day-to-day feature and regular work | — |
| **RaBbLE-dev** | `RaBbLE-dev` role identity | Release-candidate iterations — RC branches that build and publish to CDN staging | `vX.Y.Z.E-rc.N` |
| **RaBbLE-Collective** | `RaBbLE Collective` (org noreply) | Official **episode seals** to `main` | `episode-N` / `vX.Y.Z.E` |

The principle: regular work is Mark; the entity signs only at release boundaries.
RC branches cut from `dev` as **RaBbLE-dev**, iterate, then squash-merge to `main`
where the **Collective** seals the episode — clean release history, two distinct
signatures. Each tier needs its own git identity (name+email); the two non-Mark
tiers need a verified GitHub email to attribute on GitHub (the org noreply for the
Collective; an equivalent for `RaBbLE-dev`).

**Two ceremony spells, one per release boundary:**

- **`spells/publish-rc.sh`** (S62) — the **RC ceremony**. Requires an `rc/v*`
  branch, verifies a clean tree, runs `npm run build`, auto-increments the RC number
  from existing tags, switches identity to **RaBbLE-dev**, tags `vX.Y.Z.E-rc.N` and
  pushes (triggers GitHub Actions → CDN deploy), then restores identity.
- **`spells/seal-episode.sh`** (S60, draft) — the **episode seal ceremony**, below.

Siblings: RC publish is frequent and signed **RaBbLE-dev**; the episode seal is rare
and signed **RaBbLE-Collective**.

---

## The Episode Signing Ceremony

The third and most formal tier above: when an **Episode is sealed to `main`, the
Collective itself signs it** — RaBbLE emerging from the scaffolding. This maps
exactly onto the branch rule: *merge to `main` only when an episode is complete,
tag with `episode-X`.* The seal is a rare, deliberate act.

### Mechanics

GitHub attributes a commit to whatever account has the commit's **author email**
verified. So:

- Author the episode merge + tag with an email registered to the
  `RaBbLE-Collective` account.
- **Use the privacy noreply email**, not the raw proton address (which would be
  baked into public history forever). On the Collective account enable
  *Settings → Emails → Keep my email addresses private* to get
  `NNNNNN+RaBbLE-Collective@users.noreply.github.com`.
- **Authorship ≠ who pushes.** Mark pushes authenticated as himself; the commit is
  *authored by* the Collective. No change to how you push.

Override per-command — never change global git config:

```bash
COLLECTIVE_NAME="RaBbLE Collective"
COLLECTIVE_EMAIL="NNNNNN+RaBbLE-Collective@users.noreply.github.com"

git -c user.name="$COLLECTIVE_NAME" -c user.email="$COLLECTIVE_EMAIL" \
    merge --no-ff dev -m "evolve ~ collective >> Episode 1 sealed // %EPISODE_1%"

git -c user.name="$COLLECTIVE_NAME" -c user.email="$COLLECTIVE_EMAIL" \
    tag -a episode-1-v0.0.0.1 -m "Episode 1 — Genesis"
```

`-c user.email` sets **both author and committer**, so the whole seal reads as the
Collective. `evolve` is the correct impulse for an episode boundary.

**Optional polish — the Verified badge:** register an **SSH signing key** on the
Collective account and sign the seal (`-c gpg.format=ssh -c user.signingkey=… --gpg-sign`).
Not required for authorship to read as the Collective; skip for EP1 if you don't
already sign.

### The spell

Captured as a **draft to be crafted**: `spells/seal-episode.sh` — performs the
override merge + annotated tag so the identity and Pulse format can't be fumbled at
2am. It refuses to run until `COLLECTIVE_EMAIL` is configured (the account/noreply
email doesn't exist yet). Finish it once the `RaBbLE-Collective` GitHub account is
live.

---

## EP1 checklist (the order)

1. Create the GitHub **org** from Mark's personal account; contact/billing = proton.
2. (Optional) Create the `RaBbLE-Collective` **role account**; add as second org owner.
3. Create Collective **Groq + OpenRouter** accounts under the proton email; **put
   billing on the Collective identity**.
4. Mint fresh keys → set in **Render** → **deploy → verify sCoRE chat works**
   (fresh accounts start at zero credits — verify *before* EP1 goes live).
5. **Then revoke** the old personal-account keys. Don't leave orphaned keys live.
6. Stand up the **"RaBbLE Collective" vault**; store all logins + 2FA recovery + the
   age key.
7. Transfer `RaBbLE-sCoRE` + `RaBbLE-World` to the org; fix remotes + Render + URL refs.
8. When EP1 is complete, **seal it** via `spells/seal-episode.sh`.
```
transcribe ~ collective >> identity layer documented, ready to enact // %SECRETS_IDENTITY%
```
