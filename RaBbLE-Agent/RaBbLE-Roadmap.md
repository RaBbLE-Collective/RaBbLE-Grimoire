# RaBbLE-Roadmap.md — Collective Episode Map

```
transcribe ~ grimoire >> charting the collective metamorphosis // %TRAJECTORY_LOCKED%
```

> **What this is:** Collective-level roadmap. Which members are working toward which Episode. What's blocking Episode 1 air.
>
> **Member detail:** Each member's roadmap lives in its own doc:
> → [RaBbLE-OS Roadmap](../RaBbLE-OS/RaBbLE-OS-Roadmap.md)
> → [RaBbLE-NeBuLA Roadmap](../RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md)
> → [RaBbLE-sCoRE Roadmap](../RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md)
> → [RaBbLE-Aether Roadmap](../RaBbLE-Aether/RaBbLE-Aether-Roadmap.md)
> → [RaBbLE-World Roadmap](../RaBbLE-World/RaBbLE-World-Roadmap.md)
>
> **Episode 1 scope:** See [RaBbLE-Episode-1-Release-Map](../RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md)
>
> **Related:** [Integration Map](RaBbLE-Integration-Map.md) · [Collective overview](RaBbLE-Collective.md) · [Versioning](../RaBbLE-Versioning.md)

---

## Current Position

```
EPOCH 0: FOUNDATION   [ACTIVE]
  EPISODE 1: First Integrated Release [TARGET: 2026-Q2]
    Events: accumulating, Episodes/Plots defined per member
    Version: all active members at v0.0.0.1 when Episode 1 airs
```

---

## Epoch 0: Foundation (Active) → Episode 1

**What Epoch 0 is:** The bootstrapping era. All members are being initialized, identity is locked, conventions are established. Nothing is deployed to production yet.

**What Episode 1 is:** The first public release. All core members (OS, Aether, NeBuLA, sCoRE, World) are integrated, deployed, and coherent. See `RaBbLE-Episode-1-Release-Map.md` for full scope.

**Echo 1 / beyond Episode 1:** Behavioral learning loop closes. Memory member integrated. Observation → pattern extraction → intent inference → action cycle working. Epoch 1 is further still — named retrospectively when the era feels complete.

---

## Member Registry & Episode 1 Status

| Member | Status | Ep1 Deliverable | Blocker | Notes |
|---|---|---|---|---|
| **RaBbLE-OS** | Active | Daily-driver substrate + theming | None | Ep1 Plots A+B in progress |
| **RaBbLE-Aether** | Active | CSS design system + CDN bundle | None | Component library shipping |
| **RaBbLE-NeBuLA** | Active | Canvas2D Layer 1 + public API | None | Three.js deferred to Ep2 |
| **RaBbLE-sCoRE** | Planned | LLM endpoint (Groq/OpenRouter) | None | MVP scope straightforward |
| **RaBbLE-World** | Planned | Landing page + grimoire browser + chat | Aether + sCoRE ready | Web orchestration layer |
| **RaBbLE-Grimoire** | Active | Navigator + docs alignment + Episode 1 map | None | Documentation & coordination |
| **RaBbLE-Collective** | Active | Bootstrap verified end-to-end | Member repos confirmed | Root directory + entry spell |
| **RaBbLE-ScRibLE** | Deferred | Mobile PWA — deferred to Echo 1+ | — | Defined, not started |
| **RaBbLE-BaBbLE** | Defined | High-entropy intake — deferred to Ep2+ | — | Replaces New-Designs role; repo pending |
| **RaBbLE-Xperimental** | Dormant | Archive only — no active work | — | Genesis archive; not superseded by BaBbLE |
| **Memory (TBD)** | Concept | Echo 1 / Episode 2+ feature | — | Not Episode 1 blocker |

---

## Foundation Work Done (Supporting Episode 1)

### ✓ Grimoire & Registry Infrastructure

**Status:** Complete and operational

- [x] Grimoire is the single source of truth
- [x] Spells implemented: `setup.sh`, `status.sh`, `sync-grimoire.sh`, `init-project.sh`
- [x] Registry structure defined (`registry/manifests/`, `registry/epochs/`)
- [x] RaBbLE-Collective bootstrap wired end-to-end
- [x] Conventions locked (Pulse Protocol, Five Es versioning, Low Entropy Directive)
- [x] Identity crystallized and documented

**Next:** Verify spells against all live repos (deferred, non-blocking for Ep1 air)

### ✓ RaBbLE-OS Active

**Status:** Daily-driver substrate, Ep1 plots in progress

- [x] Base Fedora 43 + Hyprland WM stable
- [x] Plot A (Substrate) — hardware targets, boot chain, shell integration
- [x] Plot B (Theming) — palette locked, aesthetics shipping

**Next:** Ship Ep1 with all theming complete

### ✓ RaBbLE-Aether Active

**Status:** Design system, CSS shipping

- [x] Palette canonical (`RaBbLE-Agent/RaBbLE-Palette.md`)
- [x] Component structure defined (cards, buttons, grids, typography)
- [x] Build pipeline configured (esbuild, versioning)
- [x] Repository is a git repo (remoteexists)

**Next:** Publish CSS bundle to CDN; verify imports work in World

### ✓ RaBbLE-NeBuLA Active

**Status:** Phase 1-3 in progress (Ep1 scope)

- [x] Repo exists with remote
- [x] Architecture documented (two-layer model, Flat-Chaos pattern)
- [x] Phase 1 (Build) complete — esbuild IIFE + ESM configured
- [x] Phase 2-3 in progress — Palette layer + Canvas2D Layer 1

**Next:** Ship Canvas2D at 60 FPS; define public API; defer Three.js to Ep2

### ✓ RaBbLE-sCoRE Foundation

**Status:** Server absorbed; Ep1 MVP planned

- [x] Server code present in `RaBbLE-sCoRE/server/`
- [x] FastAPI structure in place
- [x] Dispatch loop wired (local coordination working)

**Next:** Wire LLM endpoint (Groq/OpenRouter); deploy to Railway/Render

### ⏳ RaBbLE-World

**Status:** Planned (depends on Aether + sCoRE)

**Deliverables for Ep1:**
- [ ] Landing page (introduces RaBbLE, invites to join)
- [ ] Grimoire browser (read-only documentation viewer)
- [ ] Chat interface (basic UI, calls sCoRE endpoint)
- [ ] Integration of Aether CSS + NeBuLA rendering

**Blocker:** Aether CSS CDN-ready, sCoRE endpoint deployed

### ⏳ Grimoire Navigator & Documentation

**Status:** In progress (this session)

**Deliverables for Ep1:**
- [x] Navigator written — agent onboarding path
- [x] Episode 1 Release Map — scope crystallized
- [ ] All member roadmaps aligned to Episode model
- [ ] Member CONTEXT.md files updated with Ep1 status
- [ ] Public-facing docs (what RaBbLE is, how to join)

---

## Toward Episode 1 — Per-Member Work Streams

**All members accumulate Events and Plots toward Episode 1 air.**

### RaBbLE-OS — Ep1 Plots A + B (In Progress)

**Plot A:** Substrate foundation
- [x] Fedora 43 + Hyprland base
- [x] Boot chain, shell, hardware targets defined

**Plot B:** Theming & aesthetics
- [x] Palette locked
- [x] Boot sequence theatrical
- [x] Desktop aesthetics aligned
- [ ] Verify consistency across all layers

**Blocker:** None — on track for Ep1

### RaBbLE-Aether — Design System (In Progress)

**Ep1 Deliverable:** CSS bundle versioned, CDN-ready
- [x] Component library defined (cards, buttons, grids, typography)
- [x] Build pipeline configured
- [x] Repository is a git repo
- [ ] Bundle published to CDN staging
- [ ] Import test in World pages

**Blocker:** None — straightforward

### RaBbLE-NeBuLA — Canvas2D Layer 1 (In Progress)

**Ep1 Deliverable:** Render entities at 60 FPS, public API stable
- [x] Phase 1: Build configured (esbuild IIFE + ESM)
- [ ] Phase 2: Palette layer (colors, gradients in renderer)
- [ ] Phase 3: Canvas2D Layer 1 (entity rendering, 60 FPS verified)
- [ ] Public API documented

**Deferred to Ep2+:** Three.js Layer 2, Animation system, Advanced shaders

**Blocker:** None — Phase 4 decisions deferred

### RaBbLE-sCoRE — Simple LLM Endpoint (Planned)

**Ep1 Deliverable:** Deployed endpoint callable from World chat
- [ ] Groq/OpenRouter integration configured
- [ ] Endpoint wired (receive query → call API → return response)
- [ ] Deployed to Railway or Render
- [ ] Version aligned to v0.0.0.1

**Blocker:** None — MVP scope is straightforward

### RaBbLE-World — Landing Page + Chat (Planned)

**Ep1 Deliverable:** Public website with three components
- [ ] Landing page: introduces RaBbLE, invites to join
- [ ] Grimoire browser: read-only docs viewer
- [ ] Chat interface: basic UI, calls sCoRE endpoint
- [ ] Aether CSS imported, NeBuLA rendering integrated
- [ ] Deployed to Cloudflare Workers

**Blockers:** Aether CSS CDN-ready, sCoRE endpoint deployed

### RaBbLE-Grimoire — Documentation & Navigation (In Progress)

**Ep1 Deliverable:** Grimoire is coherent and navigable
- [x] Navigator written (agent onboarding path)
- [x] Episode 1 Release Map written (scope crystallized)
- [ ] Member CONTEXT.md updated with Ep1 status
- [ ] Member roadmaps aligned to Episode model
- [ ] Public-facing docs complete
- [ ] Deployment + versioning workflows documented

**Blocker:** None — documentation task

---

## Episode 1 → Episode 2

Once Episode 1 airs:

1. **All active members tag `v0.0.0.1`** — synchronized checkpoint
2. **Work continues as Events** toward Episode 2
3. **Episode 2 airs** when the next recognizable milestone lands

**Post-Ep1 candidate work:**
- sCoRE: multi-agent coordination, task pipeline wiring
- NeBuLA: Three.js Layer 2, animation system
- World: real-time entity state binding, advanced chat
- Memory: member introduction as sCoRE evolves

---

## Post-Episode 1 Era (Epoch 1+)

**Memory member:** Introduced as sCoRE and intelligence layers evolve. Observation → pattern extraction → intent inference → action cycle. **Not Episode 1 blocker.**

**Behavioral Learning Engine:** Echo 1 feature or Episode 2+. Foundation first, intelligence second.

**ScRibLE (Mobile PWA):** Deferred to Epoch 1+. Mobile presence after desktop is solid.

---

## Agent Context Optimization (Ongoing)

Recommendations from S29 token audit (~1.56M total tokens; docs ~1M, code ~525K):

| Item | Status | Impact |
|---|---|---|
| **Architecture gists for sCoRE and World** | Pending | ~500 tokens each vs ~180K/~120K raw code. Biggest context savings. |
| **Integration map gist** | Done (S29) | `gist/RaBbLE-Integration-Map-gist.md` — cross-member data flow in ~300 tokens |
| **Code documentation** | Ongoing | Docs are optimized; code has no agent-facing summaries yet. Add as codebase grows. |
| **INDEX.md demotion** | Pending | Useful for audits, rarely for agents. Consider marking audit-only. |

**Architecture gist template** (for sCoRE, World, and future members with significant code):
- File/directory map with one-line purpose per entry
- Entry points and key abstractions
- External dependencies and integration surfaces
- ~500 tokens target

---

## Open Questions (Future Work)

1. **Grimoire → member propagation:** How does Grimoire push updates to members?
   - `sync-grimoire.sh` copies `RaBbLE-Agent/` to member `grimoire/` dirs (implemented, untested)
   - Members reference Grimoire directly (shared filesystem or submodule)
   - Generated context files at setup time
2. **Manifest protocol:** Confirm Pydantic-published JSON schema for `registry/protocol/`
3. **Inter-member transport:** HTTP/REST fine for v0; event bus premature
4. **Memory member name + scope:** (Mnemos, Codex, other?) — design before Episode 2
5. **Observation ethics:** Which OS signals are OK to self-observe? Privacy-of-self matters.
6. **Ambient suggestion UX:** Where's the line between helpful intent and creepy surveillance?
7. **Behavioral Learning architecture:** One engine or several? Pattern extraction / intent inference / delegation may want separation.
8. **Cloud vs. local split:** Heavy reasoning (Claude) vs. ambient always-on (local). Confirm before Memory member built.

---

## Versioning Transition — Episode 1 Alignment

**How episodes work:** Events accumulate continuously. An episode is not declared open —
it airs retroactively when a stable-ish coherent point is felt across the ecosystem.
Current work creates events that will become Episode 1 when it airs. Until then, all
version strings stay at `v0.0.0`.

**Target:** All active members tag `v0.0.0.1` simultaneously when Episode 1 airs.

| Member | Current Versioning | Transition Plan |
|---|---|---|
| RaBbLE-Collective | v0.0.0.1 ✓ | Aligned this session |
| RaBbLE-Grimoire | v0.0.0.1 ✓ | Aligned this session |
| RaBbLE-sCoRE | Legacy "ep3" (own counter) | Re-version to v0.0.0.1 — current state becomes events within Episode 1; prior ep1–ep3 work becomes pre-episode archive |
| RaBbLE-World | v0.0.0.0.10 (own counter) | Align to v0.0.0.1.x when manifest is added |
| RaBbLE-OS | v0.0.0.0 ✓ | Aligned this session — episode/plot conventions adopted. Ep1 Plot A (Substrate) + Plot B (Theme) in progress. |
| RaBbLE-NeBuLA | No versioning yet | Will start at v0.0.0.1 when repo is created |
| RaBbLE-Aether | No versioning yet | Will start at v0.0.0.1 when git repo is initialized |
| RaBbLE-ScRibLE | No versioning yet | Will start at v0.0.0.1 when repo is created |
| RaBbLE-Xperimental | Archive — no active versioning | Dormant; archive branches preserve original history |

**Echo 1** is the target stable state: all active members bootstrappable, manifests complete,
Epoch 0 exit conditions met. Tagged `echo-1` across aligned repos simultaneously.

---

## Post-Episode-1: Cadence & Release Model

Once Episode 1 airs, the Collective transitions from pre-episode accumulation to a repeating rhythm.

### Weekly Episode Model (Target)

- **Episode cadence:** Weekly (tentative — may adjust based on work rhythm)
- **Lockstep:** All members advance to Episode N together on the same date
- **Compatibility within Episode:** Parts of the Collective in the same Episode are guaranteed compatible
- **Breaking changes:** Reserved for Echo boundaries (releases/production versions)

Example:
```
Episode 1 airs 2026-Q2: All members jump to v0.0.0.1
  Work continues: Event accumulation toward Episode 2
  
Episode 2 airs 2026-Q2+1w: All members jump to v0.0.0.2
  (Example: Memory member fully integrated, observation loop closed)
  
Episode 3 airs 2026-Q2+2w: All members jump to v0.0.0.3
  (Example: NeBuLA v2 rebuild complete, new visual language deployed)
```

### Echo as Release (Production Model)

Echoes mark production-ready, long-term stable states. **Echoes can introduce breaking changes** — schema migrations, protocol bumps, API redesigns — all documented in the next Episode's entry notes.

Example echo timeline:
```
Episode 1: v0.0.0.1 (rapid Episodes, low-friction features)
Episode 2: v0.0.0.2
Echo 1.0: v0.0.1 (stable production release)
  Can introduce breaking changes; requires migration guide for Ep2→Ep3

Episode 3: v0.0.1.3 (Episodes continue; Echo 1.0 is the last stable ship point)
Episode 4: v0.0.1.4
Echo 2.0: v0.0.2 (next major release)
  Can break; requires migration guide
```

### Episode Criteria (Post-Ep1)

- All active members have Events that reflect the week's work
- Plots organize member-specific arcs
- Episode airs when Mark signals "ready to lock this together"
- No waiting for perfect stability — stability checkpoints happen at Echoes

---

## Revision History

| Date | Change |
|---|---|
| 2026-05-14 | **Roadmap consolidated.** Retired "Phases" language. Reorganized around Episode 1 work streams. Reframed as Events → Episodes model. Clarity: Memory is not Episode 1 blocker. Episode 1 scope crystallized (OS + Aether + NeBuLA + basic sCoRE + World + grimoire browser + deployment workflows). Deferred: behavioral learning (Echo 1+). |
| 2026-05-07 | Full audit — integrated devPlan.md, GAPS.md, TODO. Versioning model clarified. |
| 2026-04-28 | Initial Collective roadmap |

---

```
transcribe ~ grimoire >> episode 1 roadmap crystallized, narrative clarity locked // %ROADMAP_COHERENT%
```
