# EP1 Staging + Grimoire Audit — S248

> **Status:** 🟡 ACTIVE (S248, 2026-10-13) — Phase 1 + most of Phase 2.1/2.3 **done S248**. Mark's answers: D6 = rewrite (done); D2 + D5 deferred; D1 open (NeBuLA visibility not decided); D3 = not signed off, face needs more work (S249); D4 = remove `/chrysalis/` (done + deployed S249).
> Supersedes the unexecuted W3 ("Grimoire truth-alignment") in `EP1-Entity-Face-Plan.md`.
> Air gate of record stays `log/EP1-AIR-CHECKLIST.md`; this plan is how we get it green and stay coherent after.

**Cold-start prompt for a fresh agent:** *"Read `log/plans/EP1-Staging-and-Grimoire-Audit.md`. Check the
Decisions table for Mark's answers, then execute the next unchecked phase. Phases 1–2 are doc-only and
safe; Phase 3 touches live infra and every step there is Mark-confirmed."*

---

## 1. Audit findings (evidence-first)

### 1a. Gate truth vs. the checklist

| Gate | Checklist says | Evidence found | Real state |
|---|---|---|---|
| G7 OS Dev-Preview FLOOR | ⏳ verify | S236 VM run #3 **PASSED** (207 ok / 0 failed, SDDM login works); S236 Hyprland VM abort fixed (`AQ_DRM_DEVICES` → ProArt-only `machine.lua`); S238 bare-metal end-to-end **succeeded** | **Substantively met** for install. Not yet recorded: recovery-path (F2) re-test on the current ISO, rough-edges sheet confirmed shipped, B-15 (ProArt role on non-ProArt HW) listed as a known edge. → **D2** |
| G9 `setup.sh` fresh machine | ⏳ verify | `joinrabble.world/setup.sh` **404 on prod** (redirect only live on dev). Every member manifest uses `git@github.com:` (SSH) → fresh machine with no keys fails every member clone. **NeBuLA + sCoRE are PRIVATE** → anonymous HTTPS fails too (verified `git ls-remote`, S248). | **Cannot pass.** → **D1** + Phase 3 |
| G10 World coherent EP1 | 🔄 sign-off pending | dev serves the S235 five-beat "alive" face; prod still serves the older "one living surface" build; **`/chrysalis/` resolves on both prod and dev** (a Cloudflare route, not a World file) — G10 text forbids it on prod | Mark's sign-off + route decision. → **D3, D4** |
| G1–G6, G8 | ✅ | live probes S248: World 200, sCoRE `/health` 200, Aether rc.2 + NeBuLA rc.1 bundles 200; `status.sh` all lockstep in-step | ✅ confirmed |

**Prod is stale by design**: World `deploy-prod` fires only on a `main` push/tag and `main` is a stub, so prod
updates at the air merge. Consequence until then: the public bootstrap one-liner in every AGENT.md
(`curl …joinrabble.world/setup.sh`) 404s, and prod serves `AGENT.md`/`CONTEXT.md` (dev correctly hides them via `.assetsignore`).

### 1b. Roadmap incoherence (the core drift)

- **`RaBbLE-Agent/RaBbLE-Roadmap.md` is frozen at 2026-05-14.** It still reads: EP1 target 2026-Q2; sCoRE + World
  "Planned"; NeBuLA "Canvas2D Layer 1, Three.js deferred to Ep2" (Three.js shipped S107); World deliverable
  "grimoire browser"; ScRiBbLE "deferred, not started" (live since S234); unchecked boxes for CDN publish,
  Render deploy, etc. — all done months ago. Pocket, ScRiBbLE, EnGrAm, TaskViSoR absent from the member table.
- `gist/RaBbLE-Roadmap-gist.md` distils that stale doc → **every new agent's first orientation is wrong**.
- `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md` is current-ish (Sep 26) and is effectively the real forward roadmap.
  Two docs claim "the roadmap"; neither knows about the other's era.
- `registry/epochs/current.epoch.yml`: World `episode_1_blocker: true` (makes `status.sh` print "Episode 1
  blockers: RaBbLE-World"), blocker_note still cites B-10 as open. Missing focus entries: Pocket.
- `log/EP1-AIR-CHECKLIST.md` last reconciled S206; §B member table missing ScRiBbLE/Pocket (independent).
- **B-02 is tagged `ep1-gate`** while G5 says "non-gating" → `status.sh` reports 1 ep1-gate blocker that isn't one.
- `log/episodes/EPISODE-1-RELEASE.md` dated 2026-06-09 with "fifty-seven sessions", Railway correction notes — the
  narrative needs a rewrite at air, not a patch.

### 1c. Bloat + drift inventory

| Item | Size | Finding | Action class |
|---|---|---|---|
| `log/SESSION-LOG.md` | 84k words · 636 KB · 284 entries back to 2026-05-06 | Largest doc in the Grimoire; agents only ever need the head | **Split by era** (Phase 2) |
| `RaBbLE-Mythos/Summoned/Summoned-Transcript.md` | 65k words | Lore, legitimately home in Mythos | Keep — exclude from any agent read path |
| `generated/grimoire-kb/` | 180k words | **gitignored** — local build artifact, not repo bloat | None |
| `log/plans/` top level | 23 files | ≥6 are finished but not in `done/`: Liminal-Experience (IMPLEMENTED), NeBuLA-Studio (BUILT), Dolphin-Grey-Text (RESOLVED), Collective-Architecture-Audit ×3 (complete/ledger), Air-Push (superseded by Entity-Face) | Move to `done/` |
| `log/plans/CONTEXT.md` index | — | Stale: Dolphin shown 🔴 (resolved S201); Entity-Face, Display-Manager, Settings-App, EP2-Accounts, Pocket-Puppet missing | Rewrite table |
| `log/handoffs/` | 6 files | B10-Cloudflare (resolved S206/S234), S234 Entity-Face (W0–W2 done) | Move to `done/` |
| `log/agents/*.json` | 49 tracked + 8 untracked | Session-claim registry; 56 claims, 1 stale since July | Prune stale claims; decide tracked vs ignored (D5) |
| `INDEX.md` | 4.2k words | Contradictory status lines (e.g. Aether-Theming-Convergence "ACTIVE PLAN" vs absorbed) | Status-strip pass (pointer + one-liner only) |
| `RaBbLE-ScRibLE/` | dir | Old spelling; repo is ScRiBbLE (W3 item never done) | `git mv` + repoint |
| Grimoire `AGENT.md` member table | — | Pocket "no firmware/repo yet" (gadget FW live S243); OS "Fedora 43" (F44); ScRiBbLE, EnGrAm missing | Refresh |
| `log/plans/EP2-Accounts-Encryption-Spec.md` | — | Body is escaped markdown (`\#`, `\*\*`) — renders as literal backslashes | Unescape |
| Symlinks | Pocket, ScRiBbLE | `status.sh` warns missing | `sync-symlinks.sh` |
| Broken links | 3 (README, Dependency-Policy, Chrysalis-Overview) | Low — link hygiene is good | Fix |
| Live-doc stale terms | "Railway" in CONTEXT/SPELLS/sCoRE docs; "Fedora 43" in AGENT/INDEX | Sweep (historical docs exempt) |

### 1d. Public face (what an outsider actually sees)

| Surface | Today | Problem |
|---|---|---|
| joinrabble.world (prod) | older build; `/chrysalis/` live; `setup.sh` 404; AGENT.md public | fixed by the air merge + D4 |
| GitHub org — default branch `main` | **stubs** on World ("main stub: readme + license"); Aether `main` has no README (404) | a visitor on GitHub sees an empty project until air |
| GitHub repo descriptions | NeBuLA blank; sCoRE "Web interface for RaBbLE platform" (wrong); Collective's reads well | one voice, one-line each |
| Member READMEs | 48–923 words, dated May–Sep, mixed tone; Aether says `rc.1` (rc.2 published) | refresh to one template |
| Org profile README | none (`.github` repo absent) | the natural front door on GitHub |

---

## 2. Decisions — Mark's calls (nothing in Phase 3 runs without these)

**Answers so far (S248):** D1 open (unsure NeBuLA goes public yet) · D2 **deferred** · D3 **not yet** (S249: "the most polished version but still needs work"; G10 stays 🔄) · D4 **remove** (S249: dev router → 301 to the subdomain; prod clears at air merge) · D5 **deferred** (no log archiving yet) · D6 **(a), done S248**.


| # | Decision | Options | Agent recommendation |
|---|---|---|---|
| **D1** | NeBuLA + sCoRE are private; `setup.sh` needs anonymous clone | (a) make both public at air under the Sovereign Accord · (b) keep private, `setup.sh` skips private members with a clear notice · (c) public NeBuLA, private sCoRE | **(c) or (a)** — NeBuLA has no secrets and World already serves its bundle publicly; sCoRE needs a secrets audit (`git log -p` for keys) before any flip. Either way, manifests switch to `https://` |
| **D2** | Is G7 met? | accept S236/S238 + record it, with B-15 + F2 retest as rough edges · require one more clean VM run on the final ISO | **one confirmation VM run** on the air ISO incl. F2 recovery, then record G7 ✅ — cheap, agent-drivable via virt-install |
| **D3** | G10 sign-off on dev.joinrabble.world face | sign off · list changes | Mark's eye only |
| **D4** | `/chrysalis/` on joinrabble.world | remove the route (chrysalis.joinrabble.world already exists) · keep | **remove** — G10 says so, and the subdomain is its home |
| **D5** | Session-log + agent-registry hygiene | split SESSION-LOG into `log/archive/SESSION-LOG-<era>.md` at the EP1 boundary · keep monolith | **split at air**: archive everything pre-S200 now, the rest as "Genesis era" at air; `log/agents/` stale claims pruned, JSON kept tracked (the merge-safety design depends on it) |
| **D6** | Roadmap shape | (a) rewrite `RaBbLE-Roadmap.md` as a short episode map (Genesis ✓ / Exodus / Covenant) that **points to** Post-EP1 + member roadmaps, history condensed into Development-History · (b) merge Post-EP1 into it | **(a)** — one map, one forward doc, no duplication |

---

## 3. Phased plan

### Phase 1 — Truth alignment (doc-only, zero risk, agent) · parallel-safe
- [x] **1.1 Roadmap rewrite** per D6: episode map, current member table (incl. Pocket, ScRiBbLE, EnGrAm, TaskViSoR as independent/scaffold), Genesis = what actually shipped; old body condensed into `log/RaBbLE-Development-History.md` (condense-not-delete).
- [x] **1.2 Epoch YAML**: World `episode_1_blocker: false`, blocker_note → G7/G9/G10, add Pocket focus entry, ScRiBbLE status → live.
- [x] **1.3 Air checklist**: reconcile to S248; G7 evidence rows; G9 real blocker (SSH + private repos); §B add independents; `Last reconciled` → S248.
- [x] **1.4 Blockers** (done as: B-02 resolved-as-reclassified → **B-16** `resilience`; G9 = **B-17**): retag B-02 → `resilience`; add **B-17** "G9: setup.sh can't clone on a fresh machine (SSH manifests + private NeBuLA/sCoRE)" `ep1-gate`; add a blocker for the `/chrysalis/` route on prod `ep1-gate` (if D4 = remove).
- [x] **1.5 Grimoire AGENT.md** member table + Collective AGENT.md "Current State".
- [x] **1.6** Roadmap, Episode1, Collective gists hand-distilled S248 (the spell shells out to the Claude CLI on the default model; hand-writing three was cheaper and exact).
- [x] **1.7** Stale-term sweep (remaining Railway mentions are correctly historical), 2 of 3 broken links fixed (README, Chrysalis-Overview); `NOTICES.md` link left: the Collective root has no NOTICES.md yet, which is itself a Dependency-Policy gap; EP2 Accounts spec unescaped.

### Phase 2 — De-bloat (condense, pointer, move — never bare `rm`) · parallel-safe with 1 except INDEX
- [x] **2.1** (S248: moved Liminal, NeBuLA-Studio, Dolphin-Grey-Text, Architecture-Audit-Plan, B10 handoff; Air-Push + Architecture-Audit findings/PROGRESS kept active, they still hold open items; OS-ProArt untouched, another session owns it) Move finished plans → `log/plans/done/`, finished handoffs → `log/handoffs/done/`; rewrite `log/plans/CONTEXT.md` table.
- [ ] **2.2** SESSION-LOG split per D5; head of file unchanged so `head -20` still works; `end-session.sh` untouched.
- [x] **2.3** (also: Pocket manifest status → active, repo kept TBD so setup.sh skips the private repo; ScRiBbLE README link repointed in its own repo) `git mv RaBbLE-ScRibLE RaBbLE-ScRiBbLE` + repoint refs; `sync-symlinks.sh`.
- [x] **2.4** INDEX.md status-strip: one line per doc, no status essays (status lives in the doc). *(S248: plans/handoffs/OS rows → one-liners, 4,235 → ~3,500 words; Grimoire AGENT.md 1,395 → ~1,080; Navigator + README gist-first; doctor skips gitignored `generated/`.)*
- [ ] **2.5** Prune stale `log/agents` claims (`agent-register.sh`), commit the 8 untracked ones or drop them.

### Phase 3 — Air staging (live infra — every step Mark-confirmed)
- [ ] **3.1 G9 fix**: manifests `git@github.com:` → `https://github.com/`; apply D1 (visibility flip or skip-private in `spells/setup.sh`); then **fresh-VM run** of `curl …dev.joinrabble.world/setup.sh | bash` (dev, since prod redirect lands at air) — agent-driven via virt-install, Mark watches.
- [ ] **3.2 G7 record** per D2 (confirmation run on final ISO incl. F2 recovery); confirm the rough-edges sheet (`world/os.html` + `RaBbLE-OS-KnownIssues.md`) lists B-15, B-13, Hyprland-0.56 Lua caveats, WiFi Installation-Source retry.
- [ ] **3.3 G10** Mark sign-off on dev (face still needs work, S249). `/chrysalis/` part **done S249**: it was never a zone route. Dev = `rabble-dev` router (`workers/dev/`), now a 301 to `chrysalis.joinrabble.world` (deployed + verified S249 with the saved `.cloudflare/config` token); prod = stale `chrysalis/` folder in the pre-233aeb9 World build, removed by the air merge.
- [ ] **3.4 Public face**: org profile README (`RaBbLE-Collective/.github`), one-line descriptions for every repo in one voice, member READMEs refreshed to one short template (what it is · live link · status · Sovereign Accord · Grimoire pointer), Aether README → rc.2. All land on `new-horizons` so they reach `main` at the air merge.
- [ ] **3.5 Air-merge prep**: `_redirects` repoint `RaBbLE-OS.ks` + `/roadmap` to `main` (comment already says so); `EPISODE-1-RELEASE.md` rewritten from the real Genesis (S234–S246 face, not the June draft); decide bundle versions (Aether `v0.0.0.1-rc.2` → `v0.0.0.1`, NeBuLA rc.1 → `v0.0.0.1`) and World `RaBbLE-config.js` pins.
- [ ] **3.6 Dry run** of checklist §D on one member (backup tag + merge on a scratch clone) so air day has no surprises.

### Phase 4 — Air (checklist §D, Mark pulls the trigger)
Tag `episode-1-v0.0.0.1` across the lockstep set, merge `new-horizons → main`, prod deploy fires, verify prod = dev, `seal-episode.sh`, epoch YAML → v0.0.0.1, SESSION-LOG Genesis era archived.

### Phase 5 — Post-air: user scaffold + keep rolling
- **Branch model after air:** decide whether `new-horizons` stays the integration branch (rename per episode, e.g. `exodus`) — set before Phase 4 so CI triggers are right.
- **User scaffold = EP2 Accounts Phase 1** (`EP2-Accounts-Encryption-Spec.md` §2): accounts/sessions first, unencrypted, nothing sensitive. Precondition the spec already names: a **persistent store** (Render `/tmp` is ephemeral, the existing `/api/v1/auth/*` + `/users/summon` surface is the invite-era scaffold to replace, not extend). Open calls: store (D1/R2/Postgres-on-Render vs DynamoDB in spec), OAuth provider, EnGrAm-vs-sCoRE memory boundary.
- The EP1 Summon preview's `portal-a`/`portal-b` config **is** the profile schema EP2 persists (Entity-Face W4).
- Exodus spine stays the Watcher (Post-EP1 item 2) — accounts are the doorway, not the destination.
- Episode cadence: Roadmap's "weekly episodes" is aspirational; recommend "Episode airs when a vertical slice closes", reviewed at Exodus.

---

## 4. Parallelization (sub-agents: pin `model: "sonnet"`)

| Track | Scope (claim via `session-start.sh`) | Depends on |
|---|---|---|
| A — Roadmap + gists (1.1, 1.6) | `RaBbLE-Agent/RaBbLE-Roadmap.md`, `gist/*`, `log/RaBbLE-Development-History.md` | D6 |
| B — Registry + gates (1.2–1.4) | `registry/epochs/*`, `log/EP1-AIR-CHECKLIST.md`, `log/blockers/*` | D1, D4 |
| C — Hygiene (1.7, 2.1, 2.3, 2.5) | `log/plans/**`, `log/handoffs/**`, `RaBbLE-ScRibLE/` | — |
| D — SESSION-LOG split (2.2) | `log/SESSION-LOG.md`, `log/archive/` | D5 |
| E — INDEX + AGENT.md (1.5, 2.4) | `INDEX.md`, `AGENT.md` | runs **last** (absorbs A–D renames) |
| F — Public face (3.4) | member READMEs, `.github` repo | D1 |

Phase 3.1/3.2/3.3/3.5 are serial and Mark-attended.

---

## 5. Sources
`log/EP1-AIR-CHECKLIST.md` · `registry/epochs/current.epoch.yml` · `log/BLOCKERS.md` · `log/SESSION-LOG.md` (S234–S246) ·
`RaBbLE-Agent/RaBbLE-Roadmap.md` · `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md` · `log/plans/EP1-Entity-Face-Plan.md` (W3/W4) ·
`log/plans/EP2-Accounts-Encryption-Spec.md` · RaBbLE-World `_redirects`, `.assetsignore`, `.github/workflows/deploy.yml` ·
`registry/manifests/*.yml` · `spells/setup.sh` · live `curl`/`git ls-remote` probes (S248).
