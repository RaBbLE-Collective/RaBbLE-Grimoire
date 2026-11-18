# RaBbLE Episode 2 — User Accounts & Encrypted Ingestion Spec

**Status:** Draft, open questions 1 and 3 ruled S333 (§0); trust line and Pocket key ruled S352 (§0a, rest proposed). Episode framing is retired (S322); this is the Accounts milestone's encryption design.
**Scope:** Episode 2 (post-EP1 tag). Public-facing but not scaled — target is single-digit real users (self + beta testers), architecture built to scale beyond that later.
**Owner:** Mark McConachie

---

## 0. S333 rulings (2026-11-13): these override the sections below where they disagree

Ruled by Mark; also in `log/DECISIONS.md` (S333).

- **Stores (replaces §6):** Neon Postgres (hosted) and SQLite (local, tests) hold small records only: users, sessions, invites, share grants, wrapped keys, the R2 usage ledger. **All user data lives in R2** as encrypted objects under a per-account prefix, reached only through sCoRE on the S3 API (`sCoRE-Storage-Gate-Plan.md`). DynamoDB and S3 are no longer the plan.
- **Keys (settles §8 Q3):** a per-user master key wraps a per-item key. Sharing or revoking one item never exposes the others.
- **Unlock factors (settles §8 Q1):** password-derived key, a **recovery key shown once** at sign-up, and an optional **passkey**. Each wraps the master key. Google sign-in users must hold the recovery key or a passkey. Lose every factor and the data is gone. No escrow.
- **Transcripts are client-sealed:** the client (web, terminal) encrypts each chat turn with an item key and uploads it. sCoRE and the model provider see plaintext only in flight while replying, never at rest. sCoRE's server-side `transcripts.py` write path retires for signed-in users. **Pocket** seals through a paired device key (AC7 pairing), design still owed.
- **Sharing publishes a copy:** the owner's device decrypts an item and writes a plaintext copy under a share namespace; sCoRE serves it to holders of a scoped, read-only, revocable share token. Revoke deletes the copy. First consumer: `mark.mcconachie.world`, a Pages site in a separate Cloudflare account that only holds a share token.
- **Still open:** §8 Q2 (encrypted embeddings vs search), Q4, Q5, Q6; Pocket device-key design; the refusal UX when the R2 budget is spent (`sCoRE-Storage-Gate-Plan.md` Q3).

---

## 0a. S352 (2026-11-18): encrypt everything, decrypt only on the device

Triggered by the ZNP badge research (`RaBbLE-Pocket/RaBbLE-Pocket-ZNP-Badge-Research.md`). Two points ruled by Mark; the rest is a **proposal awaiting his ruling**. Not built.

### Ruled (Mark, S352)

- **Trust line: never stored in plaintext, seen only in flight.** sCoRE and the model provider see audio and text while processing a turn (STT, LLM, note shaping), never at rest. The claim made publicly is exactly that, never "we cannot see it". A local-processing tier (phone or home box) is later work, not a promise.
- **Pocket key: write-only by default, optional read key.** A Pocket can seal new items but cannot read old ones. An optional per-device read key can be granted from the phone app and revoked there.

### Proposed (needs ruling)

**1. Keys (refines S333 "master key wraps item key").** The per-user master is an X25519 keypair, not a bare symmetric key.
- Public key: stored in Neon, readable by any paired device. Private key: wrapped by each unlock factor (password KDF, recovery key, passkey), as in S333.
- Each item gets a random item key. The item key is sealed to the user public key (sealed box or HPKE). So any device holding only the public key can create items; only a device that unlocked the private key can open them.
- Pocket and badge-driver devices get a **device keypair**, generated on the device (ESP32-S3 hardware RNG), private half in flash-encrypted NVS. The phone app pairs it: registers the device public key in Neon with a label. Revoke = delete that row; a revoked device can no longer write (sCoRE refuses its auth) and its optional read key is rotated out.
- Optional read key: the phone wraps the user private key (or a narrower per-collection key) to the device public key. Rotation on revoke re-wraps item keys for future items only; old items stay readable by whoever already held the key, so say that plainly.

**2. Capture flow (Pocket, no phone).**
1. Pocket streams PCM over the beam (TLS) to sCoRE. sCoRE transcribes and shapes the note in memory, returns the note file to the device (as today, `RaBbLE-Pocket-Beam-Protocol.md`), and drops the audio. No audio or transcript is written to disk or R2 by sCoRE.
2. The device seals the note (item key, AES-256-GCM, or XChaCha20-Poly1305), seals the item key to the user public key, and uploads the blob through sCoRE's S3 module (`PUT`, per-account prefix).
3. The device keeps its recent notes locally (LittleFS, flash-encrypted). That local cache is what "recent items" means; the Pocket never needs to read R2 to show them.
- **Raw audio is never stored**, sealed or not. If a future feature needs audio at rest, it is sealed on the device before upload like any other item.
- Server-side `transcripts.py` is retired for signed-in users (S333). Guests keep the current behavior until guests are retired or sealed too (open).

**3. Badge and phone-as-hub.** The ZNP badge holds no keys and is not a trust boundary: it is a BLE input and display surface. The companion app (phone) is the key holder and sealer. Badge audio goes badge to app (BLE) to sCoRE (TLS), and the note comes back and is sealed by the app. Loops and frames pushed to the badge are rendered by the app from entity data and carry no user content beyond what the owner chose to show.

**4. What is plaintext vs sealed.** Tightening §3 above. Sealed inside the item: transcript, summary, **title, tags, frontmatter**, embeddings. Plaintext to sCoRE and R2: account id, an opaque random item id, ciphertext size, `created` rounded to the day (needed for listing and pruning), device id. Item type and tags are **not** plaintext. Cost: server-side listing by tag is impossible; see 5.

**5. Search (settles direction for §8 Q2, still open until ruled).** v1 is **client-side only**: each client keeps a local index (titles, tags, summary, embeddings computed on the device or phone) built from items it decrypted, and syncs a sealed index blob so a second device does not rebuild from scratch. No server-side search over user data. Embeddings are generated where the plaintext already is (the device or phone), never by sCoRE at rest. A Pocket-only user searches only its local cache. Revisit encrypted search if a real need appears.

**6. What Neon and R2 hold.**

| Store | Holds | Never holds |
|---|---|---|
| Neon | users, sessions, invites, share grants, device public keys, wrapped private keys (one per factor), wrapped read keys, R2 ledger | any content, any unwrapped key |
| R2 (`score/u/<account>/items/<id>`) | one sealed blob per item: header (version, alg, sealed item key) + ciphertext | plaintext, titles, tags |
| sCoRE memory (in flight) | audio and text during a turn | anything after the turn ends |

**7. Threats this does and does not cover.**

| Threat | Covered? |
|---|---|
| R2 or Neon breach or a stolen backup | Yes: ciphertext and wrapped keys only |
| Curious operator (Mark, an admin) reading stored data | Yes at rest. Not covered: an operator who modifies sCoRE to log plaintext in flight. That is a code-trust problem; the mitigation is open source plus the outside review |
| Stolen Pocket | Mostly: write-only, flash-encrypted cache of recent items only. Remote kill by revoking the device |
| Lost passwords and keys | Data lost by design (S333), no escrow |
| Model provider retention | Not covered. Groq or others see turns in flight. Disclose it; local tier is the later answer |
| Traffic analysis (sizes, times) | Not covered beyond day-rounded timestamps |

**8. Slices (each lands behind the Storage Gate G-slices).**

| # | Slice | Done when |
|---|---|---|
| E1 | `sealed.py` / client lib: item seal and open, header format, test vectors | round-trips in Python (sCoRE tools), JS (web) and C (Pocket) with shared vectors |
| E2 | User keypair + unlock-factor wrapping (needs Accounts on Neon) | sign-up produces wrapped private key; password change re-wraps only |
| E3 | Web and terminal clients seal chat turns (S333) | a signed-in chat leaves only sealed objects in R2 |
| E4 | Device pairing and device keys; revoke | a Pocket registers a public key; revoked device is refused |
| E5 | Pocket capture sealing (flash-encrypted NVS, local recent cache) | a capture lands in R2 sealed; R2 listing shows no title or tag |
| E6 | Client-side index + sealed index blob | search works on a second device with no server-side plaintext |
| E7 | Outside review of the design and the code | written review before any public privacy claim |

**Hardware caution:** ESP32-S3 flash encryption and secure boot burn eFuses permanently. Prototype on a spare board first. The hardware gives AES/SHA acceleration and key storage in eFuses, not a secure enclave.

**Still open after this section:** the gesture PIN (deferred, weak without retry limits), guest transcripts, whether to ever offer the local-processing tier, the §8 Q4 to Q6 items, and the refusal UX when the R2 budget is spent.

---

## 1. Purpose & Framing

RaBbLE's broader goal is an ambient intake / long-running personal knowledge base — a "second brain" system that ingests voice-first fragments (thoughts, insights, notes) throughout a user's day, transcribes them, and stores them for later sorting, recall, and (eventually) semantic search.

This spec covers the first real user-facing slice of that: getting from "no accounts" to "a logged-in user can join RaBbLE, get an identity, and begin ingesting voice notes that are encrypted from day one."

Two goals sit side by side and are treated as compatible, not competing:
- Public-facing from the start (hosted at joinrabble.world, no invite gate) — but planned around ~5–8 real users initially, not fifty. Momentum and public reachability matter more than pre-optimizing for scale that isn't there yet.
- Trust and privacy as a *day-zero* property, not a bolt-on. Encryption is treated as core to RaBbLE's identity, not an add-on feature.

**Deferred, explicitly:**
- Whether/how RaBbLE trains on user data (opt-in only, likely gated by the encryption model — see §5).
- Personal Grimoire structure for per-user knowledge (deferred until real notes are flowing in and access patterns are visible — matches the "don't scaffold undecided things" principle).
- Free-tier storage caps as a hard number — should be a per-user adjustable field, not hardcoded, and may become proportional to total user count as the platform grows.
- Native app / Pocket on-device wake word (both deferred — see §7).

---

## 2. Build Phasing

Two phases, deliberately decoupled so session auth isn't blocked on the harder encryption design.

### Phase 1 — Accounts & Sessions (unencrypted, no sensitive payload yet)
No ingestion happens in this phase, so there's nothing sensitive to encrypt yet. Standard session auth is sufficient.

Scope:
- User registration: Google OAuth **or** email + hashed password (bcrypt or Argon2 — never plaintext, never reversible hashing like unsalted SHA).
- Standard session authentication (session tokens / JWT — implementation detail for build time).
- "Summoning ceremony" — onboarding flow where a new user:
  - Picks two default wearable portal colors
  - Gets an Entity OID assigned
  - Lands on an intro/dashboard view (logged-in home base)
- Per-user storage record scaffolded (isolation boundary in DynamoDB/S3), but ingestion pipeline itself not yet wired in.
- Per-user storage limit field: present, adjustable, **not hardcoded** — a number you can change per-user or globally without a code change.

Exit criteria for Phase 1: a new user (including Mark, as first user) can register, authenticate, go through the summoning ceremony, and land on a logged-in home view. No transcript data exists yet.

### Phase 2 — Ingestion + Encryption (built together, not sequentially)
Ingestion is intentionally *not* built ahead of encryption — the two ship together so no unencrypted transcript data ever lands in storage, even transiently.

Interim placeholder while the encrypted pipeline is being built: ingestion can point at a "void" (no-op / discard or clearly-marked test-only unencrypted store) rather than real persistent storage, so the pipeline can be exercised end-to-end before the encrypted path is ready.

Scope:
- Wake word ("hey RaBbLE") via browser-side JS wake word detection (see §7 — web-first, not native).
- Standard cloud transcription service (not optimizing for cost/efficiency yet — that's a later pass, possibly local/on-device transcription for cost deferral, noted as future consideration).
- Client-side (browser, Web Crypto API) encryption of transcript content *before* upload — plaintext should not transit to the server.
- Encrypted blob lands in per-user scoped storage (S3 for content, DynamoDB for metadata/index — per the multi-store pattern already in use for EnGrAm).
- Decryption only happens transiently, client-side, during an active logged-in session (e.g., for display or explicit "download my data" export). No standing server-side plaintext.

Exit criteria for Phase 2: a logged-in user can speak a note, see it transcribed, see a basic summary, and have it land in storage encrypted at rest — with no point in the pipeline where plaintext sits durably on the server.

---

## 3. What Gets Encrypted

Not "everything" indiscriminately — encryption scope is chosen to protect the sensitive payload without breaking DynamoDB's access-pattern-first query model.

| Data | Encrypted? | Rationale |
|---|---|---|
| Raw transcript text | Yes | Core sensitive payload |
| Summary / distilled insight | Yes | Derived from transcript, equally sensitive |
| Embedding vectors (semantic search) | Yes (or deferred until scoped) | Sensitive by association with content; exact handling TBD — encrypted vectors may complicate similarity search at query time and need a separate design pass |
| Timestamps, item IDs, entity OID, tags | No (plaintext) | Needed for query/index patterns; low sensitivity on their own |
| Portal color prefs, account metadata | No (plaintext) | Not sensitive, not part of the "trust" surface this spec protects |

Open question, explicitly unresolved: how encrypted embeddings interact with vector similarity search. Standard vector search assumes readable vectors; fully encrypted vectors may require either (a) decrypting server-side transiently for search (weakens the "server never sees plaintext" guarantee), (b) client-side search only (doesn't scale), or (c) emerging encrypted-search techniques (adds real complexity). **Needs its own design pass before Phase 2 embedding work begins.**

---

## 4. Key Management Design

**Core pattern: two-layer key structure (industry standard — used by Signal, most password managers).**

1. **Data Encryption Key (DEK):** A randomly generated symmetric key, unique per user (or possibly per-item — TBD), that actually encrypts the user's content (transcripts, summaries, embeddings).
2. **Key Encryption Key (KEK):** Derived from the user's password (via a proper KDF — e.g., PBKDF2, scrypt, or Argon2id — *not* the raw password or a simple hash). The KEK *wraps* (encrypts) the DEK. The KEK itself is never stored.

**Why this shape, specifically:** tying encryption directly to the password (i.e., password IS the encryption secret) was considered and rejected in this conversation — it creates brittle coupling where a password reset would mean the data becomes unrecoverable, since the key changes with the password. The two-layer approach decouples them:

- Password reset → re-derive KEK from new password → re-wrap the *same* DEK with the new KEK. The DEK, and therefore all encrypted content, never changes or needs re-encryption. Only the small wrapped-key blob is updated.
- The DEK is never stored in plaintext, never sent to the server unwrapped, and never logged.

**Session flow (sketch, to be refined at implementation time):**
1. User authenticates (password or OAuth) → server confirms identity, issues session token. This is the standard auth flow from Phase 1, unchanged.
2. Client derives the KEK from the password (client-side, via Web Crypto API — the raw password should not need to leave the client for this derivation, standard KDF approaches support this).
3. Client requests the wrapped DEK from the server (safe to transmit — it's encrypted, gobbledygook without the KEK).
4. Client unwraps the DEK locally, in-memory, for the duration of the session.
5. All encryption/decryption of transcript content happens client-side using the unwrapped DEK. Plaintext exists only in browser memory during an active session, never on the wire, never at rest server-side.

**OAuth path caveat (unresolved, flag for implementation):** the password-derived KEK approach assumes a password exists. For Google OAuth signups, there's no password to derive a KEK from — needs a parallel approach (e.g., a randomly generated recovery-style secret shown once at signup, or a passkey/WebAuthn-based key derivation). **Not resolved in this conversation — needs explicit design before OAuth signup ships in Phase 2.**

**Where plaintext does NOT exist, ever, by design:**
- On the server, at rest.
- On the server, in transit logs or request bodies (client encrypts before sending).
- In RaBbLE's own model access path, unless the user has explicitly opted in to something that requires decrypted access (e.g., a future training opt-in) — see §5.

---

## 5. Relationship to Model Training / Data Use

Explicitly deferred, but the shape is now clearer as a consequence of the encryption design (not something separately negotiated):

- Because content is encrypted client-side with a key the server never holds unwrapped, RaBbLE (the model/service) **cannot** read user content by default — not as a policy choice, but as an architectural consequence.
- Any future "opt in to help train RaBbLE" feature would require either (a) an explicit decrypt-with-consent flow at time of use, or (b) a separate, clearly-marked opt-in data path outside the encrypted default. Both are future design work, not in scope here.
- This may also inform a future "privacy as premium" or tiering idea floated in conversation — not decided, just noted as a possible direction.

---

## 6. Storage Architecture Recap (context, not new decisions)

For reference — carried over from prior architecture discussion, not re-litigated here:

- **DynamoDB**: metadata + index (timestamps, entity OID, item IDs, tags) — always-free tier (25GB storage / 25 WCU / 25 RCU), no 6-month credit expiry.
- **S3**: actual content blobs (encrypted transcript/summary/embedding payloads) — always-free tier (5GB storage), no 6-month credit expiry.
- Both chosen specifically over EC2/RDS because those are credit-metered on post–July 2025 AWS accounts and would reintroduce the same "free tier expires" problem this migration is meant to solve (moving off Render/Railway's ephemeral free tiers).
- Per-user storage limit: a configurable field per account, not a hardcoded constant — see §2, Phase 1.

---

## 7. Client / Device Scope (context, not new decisions)

- **v1 client is web-first**: browser-based, using the browser's mic API and a JS-side wake word library — *not* native iOS/Android (blocked on lacking Mac/Xcode infrastructure) and *not* on-device Pocket firmware yet.
- RaBbLE Pocket (ESP32-S3 wearable) remains the eventual first *hardware* client, but is intentionally sequenced *after* the web flow proves out the ingestion pattern — building for Pocket firmware simultaneously with figuring out what ambient note-taking should even feel like was judged to be the wrong order of operations.
- On-device wake word (for Pocket) and native app wake word are both deferred; the web JS wake word approach is expected to inform, but not directly port to, the eventual on-device implementation.

---

## 8. Open Questions Carried Forward

1. OAuth-path key derivation (no password to derive a KEK from) — see §4.
2. Encrypted embeddings vs. vector similarity search — see §3.
3. Per-item vs. per-user DEK granularity — not resolved; per-user assumed as the simpler v1 default but not confirmed.
4. Personal Grimoire / per-user knowledge base structure — explicitly deferred until real ingestion data exists.
5. Training opt-in mechanism and UX — deferred, shape only sketched in §5.
6. Free tier storage limit — exact number(s) not fixed; should launch as an adjustable field, informed by ongoing cost/runway modeling (rough modeling done in conversation: text+embedding notes run ~4KB each, so even modest per-user budgets like 10–25MB support months-to-years of runway per user at realistic ingestion rates).
