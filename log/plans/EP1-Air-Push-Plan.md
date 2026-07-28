# EP1-Air-Push-Plan.md

```
spark ~ collective >> S202: EP1 air-push plan — contradictions, reliquary, deploy, Studio, OS packaging // %EP1_AIR_PUSH_PLAN%
```

> **Status:** 🟡 ACTIVE (S202 proposed · S203 revised) — decisions locked with Mark. This is the
> cold-start context for a multi-session push to bring **Episode 1 (Genesis) close to air**.
> **S203 revision:** A4 REVERSED (entity-forward face, agent-built to Mark's brief — passage
> retires), C1 domain locked (chrysalis.joinrabble.world), new A5 (deploy wrapper + CI
> completion + key inventory). See "Decisions locked S203" below.
> **Companions:** `Collective-Architecture-Audit-2026-07-04.md` (the "contradictions Fable found"),
> `Collective-Architecture-Audit-PROGRESS.md` (implementation ledger — this plan continues it),
> `NeBuLA-Studio-Plan.md` (Studio MVP; C5 builds its deferred phases),
> `EP1-Liminal-Experience-Plan.md` (the passage; superseded as the *target* design — see below).

---

## Context

Mark wants to bring **Episode 1 close to air**. Five named threads: (1) resolve the
contradictions Fable found, (2) stand up a Chrysalis reliquary garden for deprecated/never-aired
pages, (3) fix deployment blockers (Render/CF/etc.), (4) get Aether/NeBuLA EP1-ready and enable a
World redesign, (5) package RaBbLE-OS with a download page — plus tidy the rest of the scaffold so
EP1 is a coherent stable point.

**"The contradictions Fable found"** = the S193 fable-5-orchestrated *Collective Architecture
Audit* (7 systemic patterns SP-1..7 + per-member findings, each ending in an "Open decisions for
Mark"). Resolving it = safe cleanups + truth-alignment + the pending decisions (most made below).
Batch 1 safe doc/drift fixes already landed S196 — see the PROGRESS ledger; this plan is the
next, larger tranche plus the net-new builds.

**Air reality:** only two gates remain — **G7** (OS Developer-Preview install/recovery on a
generic x86_64 VM) and **G9** (`setup.sh` bootstrap end-to-end on a fresh VM), both **Mark-led,
VM-required** (`log/G7-G9-Verification-Guide.md`). Nothing here flips them; this plan makes
everything *around* them air-ready so the moment G7/G9 pass, EP1 can tag `episode-1-v0.0.0.1`
across all repos simultaneously.

## Decisions locked this session (S202)

- **World:** the S190 "liminal passage" is **not** the target design (Mark doesn't like it). Do
  **not** redesign World blind. Instead **mature the NeBuLA Studio** (inspector, nesting, HTML
  export) so Mark composes World visually himself. The passage stays as the functional EP1 face
  in the interim (it satisfies the air exit-condition: landing + entity + chat).
- **OS packaging: both, staged** — netinstall + hosted kickstart for EP1 now; built `.iso` track
  deferred to post-EP1.
- **Restructures: defer all** — sCoRE server refactor, `.rc-*` retirement, OS-manifest→SSoT
  wiring all wait until after G7/G9. This push is safe cleanups + truth-alignment + net-new only.

## Decisions locked S203 (2026-07-14)

Mark, unprompted: *"the EP1 page should be entity forward, not scrolling based, conversation as
input surface, RaBbLE should feel ambient and present in the space."* That is a design brief from
Mark himself — so the S202 "don't redesign World blind" rule no longer applies to it.

- **World face: build entity-forward NOW** (reverses S202 "passage stays"). Agent builds the new
  EP1 face to Mark's brief: entity centered + ambient, **conversation is the only input surface**,
  no scrolling narrative. The S190 liminal passage **retires to the Chrysalis reliquary** (joins
  C1 content). Studio maturation (C5) continues — it's how Mark refines the face later, not the
  gate for having one.
- **Chrysalis home: `chrysalis.joinrabble.world`** — own subdomain, matching the member pattern
  (aether./nebula./score.). NOT under dev. (dev is World's preview env; different lifecycle).
  Worker `rabble-chrysalis-web` already exists; needs the custom domain + a `deploy.yml`.
- **Deploy unification: thin wrapper, no rewrite** — `spells/deploy.sh <member> [--env dev|prod]`
  in the Grimoire *dispatches* to existing mechanisms (`wrangler deploy` per member
  `wrangler.jsonc`; `render-ctl.sh` for sCoRE). GitHub Actions stays the prod path; the spell is
  the local/manual fallback. Underlying `-ctl` spells unchanged.
- **Secrets: split.** EP1 floor = **key inventory** (every key: what, where it lives, Mark-personal
  vs Collective-owned) + CI secrets set correctly. The SOPS/age vault build + account migration
  from `RaBbLE-Secrets-and-Identity.md` → **EP2** (it's a restructure; S202 deferred those).
- **CI guards stay deferred** (palette-lint/render-smoke etc. → EP2). EP1 CI bar = deploy-only:
  every airing member has a green deploy workflow.
- **Sequencing:** G7/G9 VM verification airs **last**; everything else is agent-executable in
  parallel ahead of it.

## Two tracks

**AIR-CRITICAL** (gates the EP1 tag) vs **COHERENCE** (makes EP1 solid; not strictly gating).

---

## AIR-CRITICAL TRACK

### A1. Grimoire registry + EP1-canon reconciliation (audit §2.1, SP-7) — zero risk
The audit's #1 finding is "docs outrun code." Fix canon first so everything downstream is honest.
- Align the 5 disagreeing member lists (`registry/manifests/`, `CONTEXT.md:63`, `INDEX.md:104`,
  `AGENT.md:159-170`, `status.sh`) to one count.
- Fix `registry/epochs/current.epoch.yml`: blocker note lists resolved B-01/B-03/B-04 → real
  open set B-02/B-09/B-10 (`:99-101`); `episode_name` "First Integrated Release" → **Genesis**
  (`:7`); re-stamp the stale Episode-1-Release-Map (still says sCoRE/World "Planned" on
  "Railway/Render").
- Refresh 4 manifest "Active branch" notes (Aether/NeBuLA/World/OS) `dev` → `new-horizons`;
  Xperimental status "scaffold pending" → cloned/on-branch.
- Complete `SPELLS.md` (6 missing spells); fix broken INDEX link; index/archive strays.
- **Captures decision (default):** finish the S92 fold — repoint the OS screenshot keybind to
  `RaBbLE-BaBbLE/captures/` (§2.10), retire Captures as a member row.

### A2. Deploy blockers + endpoint hardening (B-10, §2.3 serve-the-repo)
- **B-10 (Mark-gated):** dev.joinrabble.world auto-deploy needs a scoped Cloudflare Workers
  token. Mark: `gh secret set CLOUDFLARE_API_TOKEN --body <token>`. Agent verifies Action green.
- **`.assetsignore` (World):** stop serving `AGENT.md`/`CONTEXT.md`/stale `gist/`/scripts on
  joinrabble.world — gate to `world/` + `index.html` + PWA assets.
- Verify aether/nebula subdomains serve current bundles; sCoRE Render chat path still 200s.
- **B-02 (Mark-gated):** OpenRouter $10 — Mark's purchase; flip B-02 when done.

### A3. RaBbLE-OS EP1 packaging + download page (net-new; "both, staged")
- **Download page:** new World page (or fold into `world/os.html`) leading with **netinstall +
  hosted kickstart** (`inst.ks=https://joinrabble.world/RaBbLE-OS.ks`); KS `%post` clones repo +
  runs Ansible; note "full ISO coming" for the post-EP1 track. Host `RaBbLE-OS.ks` at that URL.
- **Rough-edges sheet:** G7 FLOOR requires `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md`
  — reconcile the two bug ledgers (root `ISSUES.md` vs Grimoire KnownIssues) into it (§2.6).
- **OS truth-alignment (safe subset):** align F43/F44 + `rabble_fedora_version`; make Bootstrap
  default inventory generic (not ProArt) so a VM/x86_64 install doesn't self-assign Mark-hardware
  roles (feeds G7); archive legacy Sway-era `Install.sh`. (Manifest→SSoT wiring stays deferred.)

### A4. World entity-forward face (REVISED S203 — replaces "keep passage") — ✅ BUILT, sign-off pending
Build the new EP1 face to Mark's brief; the liminal passage retires to Chrysalis (C1/C2).
- **The brief:** single surface, no scroll. Entity centered, awake, ambient — RaBbLE is *present
  in the space*, not presented by it. **Conversation is the input surface**: one input, the page
  responds as the entity (chat → sCoRE guest endpoint, graceful offline degrade). Navigation
  (collective/summon/os) recedes to quiet affordances, not a scroll story.
- Compose strictly from Aether tokens/components + NeBuLA `<rabble-entity>`/effects (frameworks
  discipline — apply, don't redefine). Mark reviews via screenshots + live page; iterate.
- Genesis copy shrinks to what an ambient face needs (short presence lines, not narrative acts) —
  scaffold from `RaBbLE-Identity.md` for Mark's edit.
- Passage `index.html` + its acts → frozen into `Chrysalis-Web/ep1/world/` before removal.
- **NeBuLA/World delivery (default: commit to vendored):** `world/js/RaBbLE-NeBuLA.js` IS the IIFE
  build; delete the dead `RABBLE_NEBULA_URL`/`RABBLE_THREE_URL`/`RABBLE_RENDER_BACKEND` flips in
  `RaBbLE-config.js`; update Integration-Map + `AGENT.md:44` to match.

### A5. CI/CD completion + deploy wrapper + key inventory (net-new S203)
- **Chrysalis `deploy.yml`:** mirror the Aether/NeBuLA/World workflow for `rabble-chrysalis-web`;
  bind `chrysalis.joinrabble.world` custom domain.
- **All-members CI audit:** every airing member deploys green from its workflow once B-10 token
  lands (Aether, NeBuLA, World prod+dev, sCoRE proxy, Chrysalis, Grimoire worker).
- **`spells/deploy.sh` wrapper:** `deploy.sh <member> [--env dev|prod] [--dry-run]` dispatching to
  member `wrangler.jsonc` / `render-ctl.sh`; `deploy.sh status` curls each live endpoint. Document
  in `SPELLS.md`. No changes to underlying spells.
- **Key inventory:** one table in `RaBbLE-Collective/RaBbLE-Secrets-and-Identity.md` (or adjunct):
  every credential (OpenRouter, Groq personal, NIM, CF token, Render, GitHub secrets…), where it
  lives, personal-vs-Collective, EP2 migration note. Inventory only — vault build stays EP2.

---

## COHERENCE TRACK

### C1. Chrysalis reliquary garden (net-new; resolves §2.9 charter violation) — 🔄 domain locked, passage frozen; reliquary index page not yet built
Mark's decision: **Chrysalis IS the archive + memorial site**, served at
**`chrysalis.joinrabble.world`** (own subdomain — locked S203). Amend the charter.
- Build a curated **reliquary index / timeline page** in `RaBbLE-Chrysalis/Chrysalis-Web/` over
  content that already exists (`Chrysalis-Web/ep1/world/` holds 10 never-aired pages: Boot, Chat,
  Collective, Docs, Grimoire-Graph, NeBuLA-Demo/NeBuLA, OS, Shell, Studio, summon). Aether-themed
  timeline of eras, each linking its frozen page. Aether components only.
- Amend `RaBbLE-Chrysalis/AGENT.md` + `README.md`: "archive + its memorial site"; fix README
  root-path claims (moved under `Chrysalis-Web/`).
- **Orphan-sweep home:** this page becomes the destination for the World orphan sweep (C2) and
  NeBuLA's stale `dist/v0.0.0.1-rc.1/` per condense-not-delete.

### C2. World orphan sweep + live-page hygiene (§2.3, SP-3)
- Reliquary the 7 orphaned `world/js/` files (2,526 lines, incl. the `RaBbLE-floor.js` copied-
  NeBuLA-renderer violation) + 3 orphaned CSS → Chrysalis, then delete from World.
- Rewrite World `CONTEXT.md` (S53 fossil); patch `AGENT.md` (liminal files, NeBuLA.js nature),
  README pages table. Remove the committed stale `gist/` copy. (`.rc-*` retirement stays deferred.)

### C3. Aether EP1-ready (§2.4, SP-2/5/7)
- Pick one version string, align all 4 surfaces (README, package.json, CONTEXT, palette.json) to
  the **v0.0.0.0** convention.
- Fix README CDN install path to match what CI actually publishes (flat `npm run build`).
- Refresh `CONTEXT.md`; add a build step/pre-commit rebuilding dev+prod bundles together. Resolve
  invented `--rabble-void`/`--rabble-dimmer` (default: purge, or promote to Palette.md — Mark's
  call) + tokenize bare `--rabble-elevation-3`.

### C4. NeBuLA EP1-ready (§2.5, SP-2/4)
- **Rewrite `RaBbLE-NeBuLA-API.md`** against the real `<rabble-entity>` element API
  (`src/element.js:201-240`) — documents a nonexistent `createPuppet()`, worst mismatch in the
  Collective.
- Merge the 2 competing palette modules; burn down the ~8 off-Grimoire hardcode sites (SP-2).
- Fix `AnimationFilter` missing from `effects/effects-ns.js`.
- Delete stale "P5 stub" comments; condense `specs/render-gap-analysis.md` into Grimoire;
  remove/confirm the stale `dist/v0.0.0.1-rc.1/` snapshot. (floor/graph unification deferred.)

### C5. NeBuLA Studio maturation (the World enabler) — net-new
MVP shipped Phases 1-2 only (`NeBuLA-Studio-Plan.md`). Build the deferred phases that make it
design-capable:
- **Inspector panel** — select a placed instance, edit its props/Aether modifiers.
- **Nesting** — drop components into container components.
- **HTML export** — emit a real page from Aether+NeBuLA vocabulary (droppable into World),
  extending the pure `renderer.js`. No "custom HTML" escape hatch (framework discipline).
- Update `RaBbLE-NeBuLA-Studio.md`. This unblocks Mark designing World later.

### C6. Remaining scaffold (§2.7, §2.8)
- Xperimental: refresh root `CONTEXT.md` fossil; record the Voice `SynthesisEngine` contract +
  6-emotion taxonomy in Grimoire lore (promote patterns, not code); declare local-only or push remote.
- BaBbLE: repoint `_ROUTING.md` off nonexistent `rfcs/` (or create it — Mark's call); triage
  `intake/Video.mov`; sweep `tmp/`.

---

## DEFERRED (post-EP1 / post-G7-G9) — explicitly NOT this push
sCoRE server/ refactor (`sCoRE-Extensibility-Refactor-Plan.md`, awaiting option choice) · `.rc-*`
token migration · OS manifest→Ansible SSoT · per-member test/CI guards (palette-lint,
context-freshness, render-smoke) · built-`.iso` track · **secrets vault build** (SOPS/age +
account migration per `RaBbLE-Secrets-and-Identity.md` — EP1 gets the key inventory only, S203).

## MARK-GATED (agent cannot do; these gate the actual air)
- **G7** — OS Dev-Preview install/recovery on generic x86_64 VM.
- **G9** — `setup.sh` bootstrap end-to-end on fresh VM.
- **B-02** — buy OpenRouter $10 credits.
- **B-10** — create scoped Cloudflare Workers token → `gh secret set CLOUDFLARE_API_TOKEN`.
- **World face sign-off** — agent builds entity-forward to Mark's S203 brief (A4); Mark reviews
  and approves the face before air (Studio C5 remains his tool for refining it later).

## Execution notes
- Render an **Aether-themed Artifact page** of this plan (exact palette hexes, color-coded by
  track/risk) per `feedback_plan_as_aether_artifact`; get an **Opus review pass** before starting;
  decompose air-critical vs coherence for parallel sub-agents (pin sonnet/haiku per
  `feedback_subagent_model_pinning`). Offer to commit per Pulse Protocol.
- Coordinate scope at session start (`export RABBLE_SESSION_ID=...; session-start.sh`) — Mark runs
  concurrent sessions; claim before editing shared files.

## Suggested first move
**A4 (entity-forward face)** is the emotional unblock — Mark has been stalling partly because the
current face isn't his; build it first so air feels wanted. **A1 (registry reconciliation)** runs
in parallel (zero-risk, sub-agent-able). Then A5 CI/deploy wrapper + C1 reliquary (the passage
retirement feeds it), then A2/A3.

## Verification
- **A1:** `bash spells/status.sh` consistent member set, no off-track; epoch YAML blocker note +
  episode_name correct.
- **A2:** dev.joinrabble.world Action green post-token; `curl` aether/nebula/sCoRE 200;
  joinrabble.world no longer serves AGENT.md/gist.
- **A3:** fresh VM boots netinstall with `inst.ks=<url>`, %post completes, Ansible runs, session
  boots (G7/G9 territory — Mark-run); download page renders in Aether.
- **A4:** load new index.html locally, cast `visual-screenshot.sh`; no scroll; entity boots
  ambient; chat streams from sCoRE + degrades offline; old passage renders frozen from Chrysalis.
- **A5:** `deploy.sh status` all-green; Chrysalis Action green; `curl -I
  https://chrysalis.joinrabble.world` 200; key inventory covers every secret named in any
  workflow/.env/render config.
- **C1/C2:** reliquary page renders + links each frozen era; World `ls world/js` shows only live
  files.
- **C3/C4:** Aether one version everywhere; README CDN URL 200; NeBuLA API doc matches
  `src/element.js`; `window.NeBuLA.effects.AnimationFilter` defined; headless entity boots.
- **C5:** in Studio — place, edit via inspector, nest, export HTML, open export standalone; renders
  from Aether/NeBuLA with no hand-editing.
