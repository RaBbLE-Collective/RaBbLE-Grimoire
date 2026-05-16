# RaBbLE Episode 1 — Release Map

```
transcribe ~ collective >> episode 1 scope crystallized, member commitments locked // %EPISODE_1_SCOPED%
```

> **What this is:** The canonical definition of Episode 1. Scope, deliverables, dependencies, blocker resolution.
>
> **For:** Members shipping Episode 1 · Agents coordinating work · Humans tracking progress

---

## Episode 1 Definition

**Episode 1 is:** The first public release of the RaBbLE Collective. All core members are functional, deployed, and coherent. The system demonstrates integrated aesthetics and foundation. No behavioral learning yet — that's Echo 1 / Episode 2+.

**Episode 1 air date:** TBD (target: 2026-Q2, decision by Mark)

**Episode 1 version tag:** `v0.0.0.1` — all active members tag simultaneously when Episode 1 airs

---

## Member Deliverables

| Member | Episode 1 Deliverable | Status | Owner | Blocker |
|---|---|---|---|---|
| **RaBbLE-OS** | Live daily-driver substrate (Fedora 43 + Hyprland). Ep1 Plot A (substrate) + Plot B (theming) complete. | Active — plots in progress | Mark | None — on track |
| **RaBbLE-Aether** | Design system CSS bundle. Palette locked, component library shipped via CDN. | In progress | Design (Mark) | None — on track |
| **RaBbLE-NeBuLA** | Visual entity renderer. Canvas2D Layer 1 functional. Three.js Layer 2 defined. Public API stable. | In progress (Phase 2-3) | Frontend (Mark) | Design decisions locked (Phase 4 can defer to Ep2) |
| **RaBbLE-sCoRE** | Simple LLM endpoint. Groq/OpenRouter integration. Basic dispatch working. Railway/Render deployment verified. | Planned (no active work yet) | Mark | None — straightforward MVP |
| **RaBbLE-World** | Landing page + public grimoire browser. Basic chat interface (calls sCoRE endpoint). Aether + NeBuLA integrated. | Planned | Frontend (Mark) | Aether + sCoRE endpoint ready |
| **RaBbLE-Grimoire** | Public documentation browser (embedded in World). All AGENT.md, CONTEXT.md, key docs readable via web. | Planned | Mark | World infrastructure ready |
| **RaBbLE-Collective** | Bootstrap working end-to-end. All members cloneable, spells verified. | Mostly done | Mark | Member repo URLs confirmed |

---

## Episode 1 Scope — What Ships, What Doesn't

### ✓ Ships in Episode 1

**Aesthetics & Foundation:**
- [ ] RaBbLE-OS is a daily-driver substrate (all theming, boot, shell, hardware integration complete)
- [ ] Aether design system CSS bundle published to CDN
- [ ] NeBuLA visual entity renderer (Canvas2D functional, Three.js defined)
- [ ] Palette locked and canonical across all layers
- [ ] Commits follow Pulse Protocol; branches are clean

**Product:**
- [ ] `joinrabble.world` landing page live (public entity introduction)
- [ ] Public grimoire browser embedded in World (read-only documentation)
- [ ] Basic chat interface on World (calls sCoRE endpoint)
- [ ] sCoRE exposes simple LLM endpoint (Groq/OpenRouter via Railway/Render)

**Infrastructure:**
- [ ] Collective bootstrap (`bootstrap.sh`) working end-to-end
- [ ] All member repos initialized and cloneable
- [ ] Spells verified (setup.sh, status.sh, deploy scripts)
- [ ] Deployment pipeline documented and tested
- [ ] CDN integration (Cloudflare R2, Aether + NeBuLA bundles versioned)

**Documentation:**
- [ ] All members have AGENT.md, CONTEXT.md, roadmaps
- [ ] Grimoire Navigator in place (onboarding path clear)
- [ ] Versioning aligned (all active members at v0.0.0.1)
- [ ] Public facing: what RaBbLE is, how to join, how it works

### ❌ Does NOT ship in Episode 1

**Behavioral Learning:**
- Memory member — deferred to Echo 1 / Episode 2+
- Observation loops — deferred
- Pattern extraction — deferred
- Intent inference — deferred
- Ambient suggestion — deferred

**Advanced sCoRE Features:**
- Multi-agent coordination — deferred
- Task pipeline (server → dispatch → agents) — deferred
- Behavioral models — deferred
- Context-aware routing — deferred

**Advanced NeBuLA Features:**
- Full Three.js rebuild — deferred to Ep2+
- Animation system — deferred
- Real-time entity state binding — deferred
- Particle effects, advanced shaders — deferred

**Mobile / Extended Platforms:**
- RaBbLE-ScRibLE (mobile notes PWA) — deferred
- Non-x64 hardware targets — deferred

---

## Public Deployment & Workflows

Episode 1 includes operational infrastructure:

| Component | Delivery | Deployment |
|---|---|---|
| Landing page | Static HTML + Aether CSS | Cloudflare Workers |
| Grimoire browser | Dynamic docs render (web or static snapshots) | Cloudflare Workers or static |
| Chat interface | HTML + NeBuLA + sCoRE client | Cloudflare Workers |
| sCoRE endpoint | FastAPI server | Railway or Render |
| Aether CSS | Bundled, versioned | Cloudflare R2 CDN |
| NeBuLA JS | Bundled IIFE + ESM, versioned | Cloudflare R2 CDN |

**Deployment workflows documented:**
- [ ] Local dev setup (`spells/dev-serve.sh` — watchers, mock CDN)
- [ ] Staging deployment (test CDN, test sCoRE endpoint)
- [ ] Production deployment (Railway/Render for sCoRE, Cloudflare Workers for static, R2 for bundles)
- [ ] Rollback procedure (versioned bundles allow quick rollback)

---

## Exit Criteria (Episode 1 Air Conditions)

Episode 1 airs when **all** of these are true:

### Foundation Solid
- [ ] RaBbLE-OS is a daily-driver (boots, desktop works, shell stable)
- [ ] Aether is published to CDN and imported cleanly in pages
- [ ] NeBuLA Canvas2D layer renders entities at 60 FPS
- [ ] All members have manifests and are cloneable
- [ ] Spells verified against live repos (setup.sh, status.sh, deploy)

### Product Works
- [ ] Landing page loads and represents RaBbLE's character
- [ ] Grimoire browser renders docs readably
- [ ] Chat interface connects to sCoRE endpoint and returns responses
- [ ] sCoRE endpoint is deployed and live (Railway or Render)
- [ ] Aether + NeBuLA assets load from CDN without errors

### Documentation Complete
- [ ] All members have AGENT.md + CONTEXT.md + roadmap
- [ ] Grimoire Navigator is live and clear
- [ ] Public docs explain: what RaBbLE is, how to join, how to use
- [ ] Deployment workflows are documented and tested
- [ ] All members at v0.0.0.1 tag, main branches clean

### Versioning Aligned
- [ ] All active members tag `v0.0.0.1` simultaneously
- [ ] git history is clean (one coherent narrative)
- [ ] Release notes written (what ships, what's deferred, what's next)

---

## Member Roadmaps (Episode 1 Focus)

### RaBbLE-OS

**Ep1 Plots:**
- Plot A: Substrate (Fedora 43 + Hyprland base, hardware targets)
- Plot B: Theming (boot sequence, palette, desktop aesthetics)

**Status:** In progress  
**Deliverable:** Daily-driver is complete; all plots shipped  
**Blocker:** None — on track  
**Ep2+ work:** Hardware expansion, advanced theming, additional targets

### RaBbLE-Aether

**Ep1 Scope:**
- Design system architecture (CSS layers, component structure)
- Component library (cards, buttons, grids, typography)
- Build pipeline (esbuild, versioning, CDN publishing)
- Palette integration (all canonical colors mapped to CSS variables)

**Status:** In progress  
**Deliverable:** CSS bundle versioned and CDN-ready  
**Blocker:** None — straightforward  
**Ep2+ work:** Advanced components, animation library, theme variants

### RaBbLE-NeBuLA

**Ep1 Scope:**
- Phase 1: Build setup ✓ (esbuild IIFE + ESM)
- Phase 2: Palette layer (colors, gradients, palette-driven rendering)
- Phase 3: Canvas2D Layer 1 (entity rendering, 60 FPS baseline)
- Phase 4+: Defer to Episode 2

**Status:** Phases 1-3 in progress  
**Deliverable:** Canvas2D layer stable, public API defined, ESM + IIFE exports  
**Blocker:** None — design decisions (Three.js version, etc.) deferred to Ep2  
**Ep2+ work:** Three.js Layer 2, animation, advanced shaders

### RaBbLE-sCoRE

**Ep1 Scope:**
- Simple endpoint wrapper (Groq/OpenRouter)
- Basic dispatch loop (receive query → call LLM → return response)
- Deployment tested (Railway or Render)
- Version aligned to Collective (v0.0.0.1)

**Status:** Planned (MVP scope — no active work yet)  
**Deliverable:** Deployed endpoint callable from World  
**Blocker:** None — MVP is straightforward  
**Ep2+ work:** Memory member integration, behavioral routing, multi-agent coordination

### RaBbLE-World

**Ep1 Scope:**
- Landing page (introduces RaBbLE, invites to join)
- Grimoire browser (read-only documentation viewer)
- Chat interface (basic UI, calls sCoRE endpoint)
- Aether + NeBuLA integration (visual coherence)
- Deployment (Cloudflare Workers)

**Status:** Planned  
**Deliverable:** Public site live with all three components  
**Blocker:** Aether + sCoRE ready  
**Ep2+ work:** Advanced chat, real-time entity state binding, interactive demos

### RaBbLE-Grimoire

**Ep1 Scope:**
- Navigator live (onboarding path clear)
- Episode 1 Release Map (this doc — scope transparent)
- All member roadmaps aligned to Episode model
- Public docs clean and canonical
- Deployment + versioning workflows documented

**Status:** In progress (this document)  
**Deliverable:** Grimoire is the single source of truth  
**Blocker:** None — documentation task  
**Ep2+ work:** Memory member docs, behavioral learning patterns, observation channels

---

## Critical Path & Dependencies

```
RaBbLE-OS (daily driver)     ──┐
                               ├─→ Episode 1 Air
RaBbLE-Aether (CSS)          ──┤
  ↓ (imported by)               │
RaBbLE-NeBuLA (Canvas2D)     ──┤
  ↓ (rendered by)               │
RaBbLE-World (landing page)  ──┤
  ↓ (calls)                     │
RaBbLE-sCoRE (endpoint)      ──┘
```

**Dependency order:**
1. **Aether** must be CDN-ready (blocks World styling)
2. **NeBuLA** must render cleanly (blocks World visuals)
3. **sCoRE** must be deployable (blocks chat functionality)
4. **World** orchestrates all three above
5. **OS** runs independently but must be stable (foundational)

**No dependency:** OS, Grimoire docs, Collective bootstrap

**Blockers for Episode 1 air:**
- Aether: none (design system straightforward)
- NeBuLA: none (Canvas2D is scoped, Three.js deferred)
- sCoRE: none (MVP endpoint is simple)
- World: depends on Aether + sCoRE being ready
- Grimoire: documentation, non-blocking

---

## Detailed Exit Conditions Per Member

### RaBbLE-sCoRE

- [ ] `server/` path verified in all harness scripts (old `services/intelligence/` references removed)
- [ ] `server/main.py` version string aligned to Five Es scheme (`v0.0.0.1`)
- [ ] `server/api_test.py` passes against local server
- [ ] `harness/local.sh` starts server cleanly
- [ ] Railway deploy working — `harness/deploy.sh` or `harness/railway_ctl.sh` verified
- [ ] `RaBbLE-Grimoire/spells/deploy-score.sh` functional
- [ ] Tagged `episode-1-v0.0.0.1` on `main`

### RaBbLE-OS (VM Testing Required)

Verify OS bootstrap on a **fresh VM** — not just the host machine. This isolates host-specific state and makes the bootstrap reproducible.

**VM Infrastructure (QEMU/KVM):**
```
# Packages needed on host
@virtualization    # qemu-kvm, libvirt, virt-install, virt-manager
edk2-ovmf         # UEFI firmware for VM guests

# Services
libvirtd.service, virtqemud.service — enable + start

# User groups
libvirt, kvm — add ansible_user
```

**VM Bootstrap Testing Cycle:**
```
1. Provision Fedora 43 VM (QCOW2, 40 GB, 4 GB RAM, UEFI)
2. Snapshot: "post-install-baseline"
3. SSH in → clone RaBbLE-OS → run bootstrap
4. If failure: restore snapshot → iterate
5. If success: snapshot "episode-1-verified" → document
```

**Exit conditions:**
- [ ] Episode 1 packages (1–4) ported to `RaBbLE/episode-I` branch and committed
- [ ] VM provisioned — fresh Fedora 43 image
- [ ] Full bootstrap run inside VM — no fatal errors
- [ ] Boot chain themed end-to-end: GRUB → Plymouth → SDDM (hardware-agnostic, no NVIDIA dependency)
- [ ] `layerctl verify all` reports `%STABLE%` or documented exception per layer
- [ ] Known failures logged to `RaBbLE-OS-KnownIssues.md`
- [ ] Tagged `episode-1-v0.0.0.1` on `main` via squash merge

### RaBbLE-World

- [ ] Landing page live — entity idle, organ panel, log, CTA buttons functional
- [ ] `world/RaBbLE-Chat.html` wired to deployed sCoRE API (`RABBLE_API_URL` set on host)
- [ ] `world/RaBbLE-OS.html` references current bootstrap instructions
- [ ] World manifest confirmed in `RaBbLE-Grimoire/registry/manifests/`
- [ ] Tagged `episode-1-v0.0.0.1` on `main`

### RaBbLE-Aether

- [ ] CSS bundle (`dist/aether.css`) built and verified clean
- [ ] CDN deploy tested — Cloudflare R2, versioned path `/aether/v0.0.0.1/`
- [ ] World pages importing from versioned CDN URL (not local)
- [ ] Tagged `episode-1-v0.0.0.1` on `main`

### RaBbLE-NeBuLA

- [ ] Canvas2dBackend renders entity at 60 FPS (measured, not estimated)
- [ ] `<rabble-entity>` web component registers correctly on World pages
- [ ] CDN deploy tested — Cloudflare R2, versioned path `/nebula/v0.0.0.1/`
- [ ] Public API documented in `RaBbLE-NeBuLA-API.md`
- [ ] Tagged `episode-1-v0.0.0.1` on `main`

### RaBbLE-Grimoire

- [ ] All Ep1 member manifests present and accurate
- [ ] `INDEX.md` current — no broken links
- [ ] `CONTEXT.md` reflects Ep1 member statuses
- [ ] `spells/deploy-score.sh` written and functional
- [ ] Tagged `episode-1-v0.0.0.1` on `main`

### RaBbLE-Collective

- [ ] `spells/setup.sh` verified against all Ep1 member repos
- [ ] `bootstrap.sh` at `joinrabble.world/bootstrap.sh` resolves and runs
- [ ] `CONTEXT.md` updated to Ep1 member statuses
- [ ] Epoch 0 exit conditions met (see `registry/epochs/current.epoch.yml`)
- [ ] Tagged `episode-1-v0.0.0.1` simultaneously with all other members

---

## Deployment Sequence

Work is roughly parallel across members, but dependencies gate some steps:

```
Phase 0 — Unblock infrastructure
  └── Aether: CDN versioned path live (Cloudflare R2)
  └── NeBuLA: CDN versioned path live (Cloudflare R2)
  └── RaBbLE-OS: VM provisioned for bootstrap testing

Phase 1 — Member Episode 1 work (parallel)
  ├── sCoRE: harness fix → local test → Railway deploy
  ├── OS: packages 1–4 assembled → VM bootstrap test → checklist
  └── World: sCoRE URL set; pages verified on CDN Aether + NeBuLA

Phase 2 — Collective closure
  ├── Grimoire: all Ep1 manifests present, docs updated, INDEX clean
  ├── Collective: setup.sh verified, CONTEXT.md updated
  └── All members tagged episode-1-v0.0.0.1 simultaneously

Phase 3 — Public
  └── joinrabble.world pointed at World; sCoRE Railway URL confirmed live
```

---

## Tag Convention

All Ep1 members tag simultaneously when the episode is felt to be stable:

```bash
git tag episode-1-v0.0.0.1
git push origin episode-1-v0.0.0.1
```

Collective coordinates the tag moment. **No member tags alone.**

---

## Episode 1 → Episode 2 Transition

Once Episode 1 airs:

**All active members tag `v0.0.0.1`** — marks a synchronized checkpoint.

**Work continues accumulating as Events** toward Episode 2:
- sCoRE: multi-agent coordination, task pipeline
- NeBuLA: Three.js rebuild (Phase 4+)
- World: advanced chat, entity state binding
- Memory: member introduction (as sCoRE evolves to accept patterns)

**Episode 2 airs** when the Collective feels a recognizable threshold — likely when Memory member is integrated and first closed loop works.

---

## Revision History

| Date | Change |
|---|---|
| 2026-05-15 | Absorbed VM infrastructure, detailed per-member exit conditions, deployment sequence, and tag convention from `RaBbLE-Episode-I-Release.md`. Single canonical release doc. |
| 2026-05-14 | Episode 1 scope crystallized — consolidated from scattered docs. Deliverables per member clear. Blockers resolved. |

---

```
transcribe ~ collective >> episode 1 release map locked // %EPISODE_1_SCOPED%
```
