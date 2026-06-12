# RaBbLE-Grimoire — Index

```
transcribe ~ grimoire >> index crystallized // %INDEX_LOCKED%
```

> The soul of the Collective. One grimoire. All knowledge.
> Structure: `RaBbLE-Agent/` for shared knowledge, `RaBbLE-*/` for domain-specific.

---

## Gist — Low-Token Orientation

High-density distilled summaries. Full picture in ~2,000 tokens. Regenerate: `bash spells/distill-gists.sh`

| Gist | Source | Tokens |
|---|---|---|
| `gist/RaBbLE-Identity-gist.md` | Identity, character, voices, behavioral rules | ~250 |
| `gist/RaBbLE-Collective-gist.md` | Member roles, architecture, bootstrap | ~250 |
| `gist/RaBbLE-Roadmap-gist.md` | Episode 1 status, blockers, what's next | ~250 |
| `gist/RaBbLE-CommitStyle-gist.md` | Pulse Protocol, impulses, branch naming | ~150 |
| `gist/RaBbLE-Versioning-gist.md` | Five Es, version string, lockstep rule | ~200 |
| `gist/RaBbLE-Palette-gist.md` | All hex values, CSS variables | ~150 |
| `gist/RaBbLE-Collective-Overview-gist.md` | Three-layer architecture (Aether+NeBuLA+World) | ~200 |
| `gist/RaBbLE-Episode1-gist.md` | Exit conditions, blockers, deploy sequence | ~250 |
| `gist/RaBbLE-Integration-Map-gist.md` | Cross-member data flow, CDN chain, boundaries | ~300 |

---

## Core Documents

| Document | What it is |
|---|---|
| `AGENT.md` | Grimoire agent entry point — job, workspace map, rules, session start |
| `CONTEXT.md` | Grimoire status, structure, active tracks |
| `RaBbLE-Versioning.md` | **The Five Es** — Event→Episode→Echo→Evolution→Epoch, version string format |
| `INDEX.md` | This file |

---

## RaBbLE-Agent — Shared Across All Projects

- [RaBbLE-Identity](RaBbLE-Agent/RaBbLE-Identity.md) — manifesto, character, voices, state machine, system prompt
- [RaBbLE-Palette](RaBbLE-Agent/RaBbLE-Palette.md) — all hex values, Ansible block, component mapping
- [RaBbLE-CommitStyle](RaBbLE-Agent/RaBbLE-CommitStyle.md) — the Pulse Protocol
- [RaBbLE-BranchStrategy](RaBbLE-Agent/RaBbLE-BranchStrategy.md) — branch topology
- [RaBbLE-DocTemplates](RaBbLE-Agent/RaBbLE-DocTemplates.md) — canonical AGENT.md and CONTEXT.md templates for all member repos
- [RaBbLE-Roadmap](RaBbLE-Agent/RaBbLE-Roadmap.md) — unified ecosystem roadmap
- [RaBbLE-Collective](RaBbLE-Agent/RaBbLE-Collective.md) — ecosystem map, all members, architecture diagram
- [RaBbLE-Integration-Map](RaBbLE-Agent/RaBbLE-Integration-Map.md) — cross-member data flow, CDN chain, integration patterns, key boundaries
- [RaBbLE-Agent-Protocols](RaBbLE-Agent/RaBbLE-Agent-Protocols.md) — **agent behavioral rules** (doc management, repo conventions, member responsibilities, dev workflow, naming)
- [RaBbLE-Grimoire-Navigator](RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md) — reading order by time budget and task type
- [RaBbLE-Captures-System](RaBbLE-Agent/RaBbLE-Captures-System.md) — visual capture organization, spell integration (`visual-screenshot.sh`), naming conventions
- [RaBbLE-Collective-KnownIssues](RaBbLE-Agent/RaBbLE-Collective-KnownIssues.md)
- [RaBbLE-DistilledNonZense](RaBbLE-Agent/RaBbLE-DistilledNonZense.md) — full entropy archive from deprecated substrate
- [RaBbLE-Overview](RaBbLE-Agent/RaBbLE-Overview.md) — orientation map: ecosystem summary and quick-start pointers
- [RaBbLE-References](RaBbLE-Agent/RaBbLE-References.md) — external influences and reference repositories

---

## RaBbLE-Collective

- **[RaBbLE-Episode-1-Release-Map](RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md)** — **CANONICAL Episode 1 scope.** Member deliverables, blockers, exit criteria, VM testing, deployment sequence, tag convention.
- **[RaBbLE-Episode-1-RC-Scope](RaBbLE-Collective/RaBbLE-Episode-1-RC-Scope.md)** — **EP1 RC checklist.** 3 public pages, World repolish tasks, deferred list, sign-off gate.
- **[RaBbLE-Integration-Ethos-Plan](RaBbLE-Collective/RaBbLE-Integration-Ethos-Plan.md)** — **ACTIVE PLAN.** Four-phase integration: New-Designs → Ethos layer → BaBbLE member → Landing transformation. Agent handoff doc.
- [RaBbLE-Collective-Plan](RaBbLE-Collective/RaBbLE-Collective-Plan.md) — Collective bootstrap architecture and coordination plan
- [RaBbLE-Collective-Episode-1-Overview](RaBbLE-Collective/RaBbLE-Collective-Episode-1-Overview.md) — Three-layer architecture (Aether + NeBuLA + World), CDN strategy
- [RaBbLE-Deployment-Architecture](RaBbLE-Collective/RaBbLE-Deployment-Architecture.md) — environments (local/staging/prod), CDN distribution, versioning, build pipeline
- [RaBbLE-Cloudflare-Integration](RaBbLE-Collective/RaBbLE-Cloudflare-Integration.md) — Cloudflare setup, R2 buckets, Wrangler configuration, deployment workflow
- [RaBbLE-Secrets-and-Identity](RaBbLE-Collective/RaBbLE-Secrets-and-Identity.md) — how the Collective owns its own accounts/keys (proton root identity, two-tier secrets, GitHub org + role account, repo transfer, episode signing ceremony)
- [RaBbLE-Personal-Cosmos](RaBbLE-Collective/RaBbLE-Personal-Cosmos.md) — per-user namespace: Personal Grimoire, BaBbLE intake, Xperimental sandbox, Rablet publishing (EP2+)
- [RaBbLE-Attachments-and-Mesh](RaBbLE-Collective/RaBbLE-Attachments-and-Mesh.md) — multi-platform ambient intelligence: attachment model, local intelligence tiers, opt-in mesh, handheld device (EP2+)
- [RaBbLE-Social-and-Aesthetic](RaBbLE-Collective/RaBbLE-Social-and-Aesthetic.md) — Neon Cafe aesthetic manifesto, social/altspace layer, RaBbLE voice design, Sovereign Accord license (Echo 1+)
- [RaBbLE-Income-Model](RaBbLE-Collective/RaBbLE-Income-Model.md) — 8 revenue streams: Cosmos hosting, compute, community, rablet economy, Shop, hardware, attachments, enterprise
- [RaBbLE-Shop](RaBbLE-Collective/RaBbLE-Shop.md) — physical product storefront: first-party + third-party designs, POD infrastructure, aesthetic requirements

---

## Registry

- [RaBbLE-Collective-Registry](registry/RaBbLE-Collective-Registry.md) — registry reference documentation
- [registry/epochs/current.epoch.yml](registry/epochs/current.epoch.yml) — active epoch definition, per-member Episode 1 status
- **manifests/**: RaBbLE-Collective · RaBbLE-OS · RaBbLE-sCoRE · RaBbLE-Aether · RaBbLE-NeBuLA · RaBbLE-World · RaBbLE-BaBbLE · RaBbLE-Chrysalis · RaBbLE-Xperimental (new)

---

## RaBbLE — Entity Definition Layer

- [RaBbLE-Overview](RaBbLE/RaBbLE-Overview.md) — what the entity definition layer is and how to read it
- [RaBbLE-Ethos](RaBbLE/Ethos/RaBbLE-Ethos.md) — philosophy: Architecture of Self, Anti-Assistant Stance, Low Entropy Directive, On Memory
- [RaBbLE-Ethos-Overview](RaBbLE/Ethos/RaBbLE-Ethos-Overview.md) — Ethos section reading guide
- [RaBbLE-Aesthetic](RaBbLE/Worldbuilding/RaBbLE-Aesthetic.md) — visual/experiential world: Neotokyo, synthwave, palette as character
- [RaBbLE-Worldbuilding-Overview](RaBbLE/Worldbuilding/RaBbLE-Worldbuilding-Overview.md) — Worldbuilding section reading guide
- [RaBbLE-Genesis-Overview](RaBbLE/Genesis/RaBbLE-Genesis-Overview.md) — Genesis section reading guide *(docs to be authored — Phase 2C)*

---

## RaBbLE-Mythos — Stories and Creative Writing

- [Summoned](RaBbLE-Mythos/Summoned/) — short story: the entity's origin told as fiction

---

## Spells

- [SPELLS.md](SPELLS.md) — spell system overview and usage guide
- [spells/setup.sh](spells/setup.sh) — bootstrap the Collective locally
- [spells/status.sh](spells/status.sh) — health dashboard for all members
- [spells/sync-grimoire.sh](spells/sync-grimoire.sh) — propagate Grimoire updates to members
- [spells/init-project.sh](spells/init-project.sh) — scaffold a new Collective member
- [spells/install-theme.sh](spells/install-theme.sh) — install RaBbLE theme across OS
- [spells/dev-serve.sh](spells/dev-serve.sh) — launch local dev environment (Aether + NeBuLA + World watchers, CDN mock server)
- [spells/cast-aether.sh](spells/cast-aether.sh) — publish Aether CSS bundles to CDN (R2 or staging)
- [spells/cast-cdn.sh](spells/cast-cdn.sh) — build Aether + NeBuLA, stage into World, deploy to joinrabble.world via wrangler
- [spells/distill-gists.sh](spells/distill-gists.sh) — regenerate gist/ summaries via Claude CLI
- [spells/deploy-score.sh](spells/deploy-score.sh) — deploy sCoRE to Railway
- [spells/seal-episode.sh](spells/seal-episode.sh) — **DRAFT** · Episode Signing Ceremony: seal an episode to `main` authored by the Collective (refuses to run until the Collective GitHub account exists)
- [spells/visual-screenshot.sh](spells/visual-screenshot.sh) — capture browser screenshot for agent visual review
- [spells/help.sh](spells/help.sh) — list all available spells with descriptions
- [spells/sync-symlinks.sh](spells/sync-symlinks.sh) — create CLAUDE.md/CODEX.md/GEMINI.md → AGENT.md symlinks across all repos
- [spells/token-budget.sh](spells/token-budget.sh) — calculate token cost of agent onboarding paths
- [spells/graph-grimoire.sh](spells/graph-grimoire.sh) — build documentation link graph (JSON + Mermaid), report orphans and hubs
- [spells/session-tokens.sh](spells/session-tokens.sh) — parse Claude Code transcripts for token usage per session

---

## RaBbLE-OS

- [RaBbLE-OS-AgentGuide](RaBbLE-OS/RaBbLE-OS-AgentGuide.md) — **start here** — directory map + navigation table
- [RaBbLE-OS-Roadmap](RaBbLE-OS/RaBbLE-OS-Roadmap.md) — current episode, stub phases, fix branches, assembly
- [RaBbLE-OS-DevHistory](RaBbLE-OS/RaBbLE-OS-DevHistory.md) — pre-Collective genesis (2026-04-09 → 04-29): KDE→Sway pivots, palette/hardware corrections, SDDM/greetd arc — fills the founding-era gap with no local session transcripts

**layers/** [Layers](RaBbLE-OS/layers/RaBbLE-OS-Layers.md) · [Layer-Core](RaBbLE-OS/layers/RaBbLE-OS-Layer-Core.md) · [Layer-Hardware](RaBbLE-OS/layers/RaBbLE-OS-Layer-Hardware.md) · [Layer-Boot](RaBbLE-OS/layers/RaBbLE-OS-Layer-Boot.md) · [Layer-Desktop](RaBbLE-OS/layers/RaBbLE-OS-Layer-Desktop.md) · [Layer-Apps](RaBbLE-OS/layers/RaBbLE-OS-Layer-Apps.md)
**hardware/** [Hardware-ProArtP16](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-ProArtP16.md) · [Hardware-GenericX64](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-GenericX64.md) · [Hardware-AddingTargets](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-AddingTargets.md) · [Hardware-Partitions](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Partitions.md)
**ops/** [Ops-Layerctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Layerctl.md) · [Ops-Dotctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Dotctl.md) · [Ops-Bootstrap](RaBbLE-OS/ops/RaBbLE-OS-Ops-Bootstrap.md) · [Ops-Vmctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Vmctl.md) · [Ops-ConfigFlow](RaBbLE-OS/ops/RaBbLE-OS-Ops-ConfigFlow.md) · [Ops-Install](RaBbLE-OS/ops/RaBbLE-OS-Ops-Install.md)
**fix/** [KnownIssues](RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md) · [Fix-Nvidia](RaBbLE-OS/fix/RaBbLE-OS-Fix-Nvidia.md) · [Fix-BootChain](RaBbLE-OS/fix/RaBbLE-OS-Fix-BootChain.md) · [Fix-Suspend](RaBbLE-OS/fix/RaBbLE-OS-Fix-Suspend.md)
**verify/** [Verify-Checklist](RaBbLE-OS/verify/RaBbLE-OS-Verify-Checklist.md) · [Verify-PowerTesting](RaBbLE-OS/verify/RaBbLE-OS-Verify-PowerTesting.md) · [Verify-LayerState](RaBbLE-OS/verify/RaBbLE-OS-Verify-LayerState.md)
**desktop/** [Desktop-Hyprland](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Hyprland.md) · [Desktop-Shell](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Shell.md) · [Desktop-Theming](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Theming.md) *(includes VSCodium Aether theme — CSS design, Ansible install, maintenance)* · [Desktop-BootFlow](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-BootFlow.md) · [Desktop-sCoRE-UsageTracker](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-sCoRE-UsageTracker.md) · [Desktop-Fastfetch](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Fastfetch.md)
**historical/** [ManualInstall](RaBbLE-OS/historical/RaBbLE-OS-ManualInstall.md) · [Epoch-I-Diff](RaBbLE-OS/historical/RaBbLE-OS-Epoch-I-Diff.md) · [Implementation-Plan](RaBbLE-OS/historical/RaBbLE-OS-Implementation-Plan.md)

---

## RaBbLE-sCoRE

- **[RaBbLE-sCoRE-Roadmap](RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md)** — **Episode 1 commitment:** simple LLM endpoint (Groq/OpenRouter)
- [RaBbLE-sCoRE-Architecture](RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md) — component map, task lifecycle, server subcomponent
- [RaBbLE-sCoRE-DataCrawler-RFC](RaBbLE-sCoRE/RaBbLE-sCoRE-DataCrawler-RFC.md) — future RFC: Scavenger/Organizer/Librarian crawler bot architecture (post-Episode-1)
- **Internal:** [sCoRE System Prompt](../RaBbLE-sCoRE/system-prompt-sCoRE.md) — loaded only when running as sCoRE entity

---

## RaBbLE-World

- **[RaBbLE-World-Roadmap](RaBbLE-World/RaBbLE-World-Roadmap.md)** — **Episode 1 commitment:** landing page + grimoire browser + basic chat
- [RaBbLE-World-Architecture](RaBbLE-World/RaBbLE-World-Architecture.md) — layer stack, module map, boot timeline
- [RaBbLE-World-Page-Template](RaBbLE-World/RaBbLE-World-Page-Template.md) — minimal page template, CDN integration pattern
- [Visual Assets](RaBbLE-World/assets/) — images, icons

---

## RaBbLE-NeBuLA

- **[RaBbLE-NeBuLA-Roadmap](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md)** — **Episode 1 commitment:** Canvas2D Layer 1 rendering (60 FPS) + effects engine
- **[RaBbLE-NeBuLA-Rearchitecture](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Rearchitecture.md)** — **Active plan:** 7-phase modular decomposition, frame budgeting, effects systems (supersedes Perf-Fix-Plan)
- [RaBbLE-NeBuLA-Identity](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Identity.md) — origin story, consciousness model
- [RaBbLE-NeBuLA-Architecture](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Architecture.md) — Layer model, system interface, frame budget, effects layer
- [RaBbLE-NeBuLA-API](RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md) — public API reference
- [RaBbLE-NeBuLA-Plan](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Plan.md) — agent implementation plan (step-by-step)
- [RaBbLE-NeBuLA-FlatChaos](RaBbLE-NeBuLA/RaBbLE-NeBuLA-FlatChaos.md) — Flat-Chaos pattern spec
- [RaBbLE-NeBuLA-Ideas](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Ideas.md) — enhancement proposals (Episodes 3+)
- [RaBbLE-NeBuLA-Perf-Fix-Plan](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Perf-Fix-Plan.md) — performance root-cause analysis (superseded by Rearchitecture)
- [RaBbLE-NeBuLA-RABL](RaBbLE-NeBuLA/RaBbLE-NeBuLA-RABL.md) — scene serialization format (legacy reference)
- [RaBbLE-NeBuLA-RBCNS](RaBbLE-NeBuLA/RaBbLE-NeBuLA-RBCNS.md) — historical naming spec (**archived, do not follow**)

---

## RaBbLE-Aether

- **[RaBbLE-Aether-Roadmap](RaBbLE-Aether/RaBbLE-Aether-Roadmap.md)** — **Episode 1 commitment:** CSS design system bundle (CDN-ready)
- [RaBbLE-Aether-Architecture](RaBbLE-Aether/RaBbLE-Aether-Architecture.md) — design system spec, palette publishing
- [RaBbLE-Aether-Build-CDN](RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md) — esbuild setup, dev workflow, CDN versioning, common pitfalls
- [RaBbLE-Aether-Design-Guide](RaBbLE-Aether/RaBbLE-Aether-Design-Guide.md) — palette, component prompts, and animation vocabulary for any AI design/image tool
- [SYSTEM-PROMPT](RaBbLE-Aether/SYSTEM-PROMPT.md) — three-tier system prompt for pasting into Claude Design (quick card / short / full)
- [RaBbLE-Aether-Effects-Bank](RaBbLE-Aether/RaBbLE-Aether-Effects-Bank.md) — saved CSS effects discovered accidentally, pending integration (cotton candy swirl, etc.)
- [DEBUG-SESSION-2026-05-15](RaBbLE-Aether/DEBUG-SESSION-2026-05-15.md) — session debug log (ephemeral reference)
- [Visual Assets](RaBbLE-Aether/assets/) — SVG, logos, icons

---

## RaBbLE-ScRibLE

- [README](RaBbLE-ScRibLE/RaBbLE-ScRibLE-Overview.md) — mobile PWA notes surface, iPhone/iPad + Apple Pencil, Echo 1+ candidate

---

## RaBbLE-BaBbLE

- [README](RaBbLE-BaBbLE/RaBbLE-BaBbLE-Overview.md) — intake workspace overview, integration pattern, relationship to Xperimental

---

## RaBbLE-Xperimental

- [README](RaBbLE-Xperimental/RaBbLE-Xperimental-Overview.md) — genesis archive: NeBuLA-JS, WebOS, RaBbLE.py, RaBbLE-Server (October 2025 origin code)

---

## Log

- [SESSION-LOG](log/SESSION-LOG.md) — running session log, most recent first (`head -20` for ## LATEST box)
- [Development History](log/RaBbLE-Development-History.md) — 5-minute narrative of the Collective's eras, pivots, and corrected-canon notes (distilled from SESSION-LOG + memory)
- [DECISIONS](log/DECISIONS.md) — architectural decisions: member roles, versioning, onboarding, gist system
- [AUDITS](log/AUDITS.md) — completed audits + open gaps: registry, onboarding, token reduction, Episode 1 blockers
- [grimoire-graph.json](log/grimoire-graph.json) — documentation link graph (generated by `graph-grimoire.sh`)
- [grimoire-graph.md](log/grimoire-graph.md) — Mermaid diagram of doc connections

---

## Lore

> See [RaBbLE/RaBbLE-Overview.md](RaBbLE/RaBbLE-Overview.md) for reading order and layer explanation.

### ShortStories

- [Summoned-v0](RaBbLE-Mythos/Summoned/Summoned-v0.md)
- [Summoned-v1](RaBbLE-Mythos/Summoned/Summoned-v1.md)
- [Summoned-v2](RaBbLE-Mythos/Summoned/Summoned-v2.md)
- [Summoned-v3](RaBbLE-Mythos/Summoned/Summoned-v3.md)
- [Summoned-v4](RaBbLE-Mythos/Summoned/Summoned-v4.md)
- [Summoned-v5](RaBbLE-Mythos/Summoned/Summoned-v5.md)
- [Summoned-Transcript](RaBbLE-Mythos/Summoned/Summoned-Transcript.md)

### Ethos

- [RaBbLE-Ethos](RaBbLE/Ethos/RaBbLE-Ethos.md) — philosophy + manifesto: anti-assistant stance, low entropy, curiosity, collective model, on memory, on forking
- `RaBbLE-Symbiosis.md` — entity/collective relationship *(to be authored — Phase 2C)*

### Genesis

- `RaBbLE-Origin.md` — creation story *(Mark authors — Phase 2C)*
- `RaBbLE-Lineage.md` — multi-model history *(to be authored — Phase 2C)*
- `RaBbLE-Visual-Evolution.md` — entity appearance evolution *(to be authored — Phase 2C)*
- `RaBbLE-Collaborators.md` — models + tools that shaped RaBbLE *(to be authored — Phase 2C)*

### Worldbuilding

- [RaBbLE-Aesthetic](RaBbLE/Worldbuilding/RaBbLE-Aesthetic.md) — synthwave world, boot as theater, palette as character, visual reference sources

---

## What Belongs Here vs. In Member Repos

| Lives in Grimoire | Lives in member repo |
|---|---|
| Entity identity, character, voice | Member-specific architecture |
| Canonical palette | Member-specific Ansible vars (derived from palette) |
| Versioning spec | Member's current version / episode tracker |
| Collective overview | Member's own CONTEXT.md |
| Cross-project roadmap | Member-specific sprint / issue tracker |
| Lore and short stories | Member-specific READMEs |

---

```
transcribe ~ grimoire >> index complete // %INDEX_LOCKED%
```
