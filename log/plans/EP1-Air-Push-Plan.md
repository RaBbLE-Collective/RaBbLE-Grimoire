# EP1-Air-Push-Plan.md

```
spark ~ collective >> S202: EP1 air-push plan — contradictions, reliquary, deploy, Studio, OS packaging // %EP1_AIR_PUSH_PLAN%
```

> **Status:** 🟡 PROPOSED (S202) — decisions locked with Mark, not started. Mark picks this up
> next session. This is the cold-start context for a multi-session push to bring **Episode 1
> (Genesis) close to air**.
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

### A4. World for-air (keep passage functional; no redesign)
- Author the placeholder `GENESIS-COPY` blocks in `index.html` (Mark's voice, or scaffold from
  `RaBbLE-Identity.md` for his edit) so the face reads finished.
- Verify Act IV live chat + graceful degrade against the sCoRE guest endpoint.
- **NeBuLA/World delivery (default: commit to vendored):** `world/js/RaBbLE-NeBuLA.js` IS the IIFE
  build; delete the dead `RABBLE_NEBULA_URL`/`RABBLE_THREE_URL`/`RABBLE_RENDER_BACKEND` flips in
  `RaBbLE-config.js`; update Integration-Map + `AGENT.md:44` to match.

---

## COHERENCE TRACK

### C1. Chrysalis reliquary garden (net-new; resolves §2.9 charter violation)
Mark's decision: **Chrysalis IS the archive + memorial site.** Amend the charter.
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
context-freshness, render-smoke) · built-`.iso` track.

## MARK-GATED (agent cannot do; these gate the actual air)
- **G7** — OS Dev-Preview install/recovery on generic x86_64 VM.
- **G9** — `setup.sh` bootstrap end-to-end on fresh VM.
- **B-02** — buy OpenRouter $10 credits.
- **B-10** — create scoped Cloudflare Workers token → `gh secret set CLOUDFLARE_API_TOKEN`.
- **World design vision** — Mark composes via the matured Studio (C5); agent then wires the
  export into World.

## Execution notes
- Render an **Aether-themed Artifact page** of this plan (exact palette hexes, color-coded by
  track/risk) per `feedback_plan_as_aether_artifact`; get an **Opus review pass** before starting;
  decompose air-critical vs coherence for parallel sub-agents (pin sonnet/haiku per
  `feedback_subagent_model_pinning`). Offer to commit per Pulse Protocol.
- Coordinate scope at session start (`export RABBLE_SESSION_ID=...; session-start.sh`) — Mark runs
  concurrent sessions; claim before editing shared files.

## Suggested first move
Land **A1 (registry reconciliation)** — zero-risk, makes all canon honest, prerequisites others
cite. Then A2 endpoint hardening + A3 OS download page in parallel.

## Verification
- **A1:** `bash spells/status.sh` consistent member set, no off-track; epoch YAML blocker note +
  episode_name correct.
- **A2:** dev.joinrabble.world Action green post-token; `curl` aether/nebula/sCoRE 200;
  joinrabble.world no longer serves AGENT.md/gist.
- **A3:** fresh VM boots netinstall with `inst.ks=<url>`, %post completes, Ansible runs, session
  boots (G7/G9 territory — Mark-run); download page renders in Aether.
- **A4:** load index.html locally, cast `visual-screenshot.sh`; Act IV chat streams from sCoRE +
  degrades offline.
- **C1/C2:** reliquary page renders + links each frozen era; World `ls world/js` shows only live
  files.
- **C3/C4:** Aether one version everywhere; README CDN URL 200; NeBuLA API doc matches
  `src/element.js`; `window.NeBuLA.effects.AnimationFilter` defined; headless entity boots.
- **C5:** in Studio — place, edit via inspector, nest, export HTML, open export standalone; renders
  from Aether/NeBuLA with no hand-editing.
