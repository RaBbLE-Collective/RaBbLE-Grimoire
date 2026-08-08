# RaBbLE-Grimoire — Index

```
transcribe ~ grimoire >> index crystallized // %INDEX_LOCKED%
```

> The soul of the Collective. One grimoire. All knowledge.
> Structure: `RaBbLE-Agent/` for shared knowledge, `RaBbLE-*/` for domain-specific.

---

## Gist — Low-Token Orientation

High-density distilled summaries. Full picture in **~3,000 tokens** (`bash spells/token-budget.sh` for live totals). Regenerate: `bash spells/distill-gists.sh`. Token counts are approximate (words × 1.33) and drift as sources change — `grimoire-doctor.sh` flags a gist when its source is newer.

| Gist | Source | Tokens |
|---|---|---|
| `gist/RaBbLE-Identity-gist.md` | Identity, character, voices, behavioral rules | ~320 |
| `gist/RaBbLE-Collective-gist.md` | Member roles, architecture, bootstrap | ~400 |
| `gist/RaBbLE-Roadmap-gist.md` | Episode 1 status, blockers, what's next | ~320 |
| `gist/RaBbLE-CommitStyle-gist.md` | Pulse Protocol, impulses, branch naming | ~320 |
| `gist/RaBbLE-Versioning-gist.md` | Five Es, version string, lockstep rule | ~350 |
| `gist/RaBbLE-Palette-gist.md` | All hex values, CSS variables | ~270 |
| `gist/RaBbLE-Episode1-gist.md` | Live EP1 gate table, blockers, tag procedure | ~335 |
| `gist/RaBbLE-Integration-Map-gist.md` | Cross-member data flow, CDN chain, boundaries | ~350 |

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
- [RaBbLE-Roadmap](RaBbLE-Agent/RaBbLE-Roadmap.md) — unified ecosystem roadmap (episode naming, member sequence, per-member status)
- [RaBbLE-Post-EP1-Roadmap](RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md) — consolidated forward map: Episode 2 (Exodus) spine, Echo 1 substrate (Grimoire MCP, presence layer, agent framework), standing backlog + deferred-by-design — each pointing to its canonical source
- [RaBbLE-Collective](RaBbLE-Agent/RaBbLE-Collective.md) — ecosystem map, all members, architecture diagram
- [RaBbLE-Integration-Map](RaBbLE-Agent/RaBbLE-Integration-Map.md) — cross-member data flow, CDN chain, integration patterns, key boundaries
- [RaBbLE-Agent-Protocols](RaBbLE-Agent/RaBbLE-Agent-Protocols.md) — **agent behavioral rules** (doc management, repo conventions, member responsibilities, dev workflow, naming)
- **[RaBbLE-Dependency-Policy](RaBbLE-Agent/RaBbLE-Dependency-Policy.md)** — **license governance for all agents.** Tier 1–4 classification, adapter pattern, NOTICES.md convention, clean room spec, agent rules. Read before adding any external dependency.
- [RaBbLE-Development-Methodology](RaBbLE-Agent/RaBbLE-Development-Methodology.md) — *sovereign-directed agentic development*: drift-prevention protocol, agentic engineering practices, code-as-architectural-audit, honest architect profile + language profile
- [RaBbLE-Grimoire-Navigator](RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md) — reading order by time budget and task type
- **[RaBbLE-Grimoire-SelfHealing](RaBbLE-Agent/RaBbLE-Grimoire-SelfHealing.md)** — **anti-drift & self-healing protocol:** the drift surface, `grimoire-doctor`, token-weighted graph, low-token walking, pre-commit enforcement, forward plan
- [RaBbLE-Captures-System](RaBbLE-Agent/RaBbLE-Captures-System.md) — visual capture organization, spell integration (`visual-screenshot.sh`), naming conventions
- [RaBbLE-VisualPlan-Protocol](RaBbLE-Agent/RaBbLE-VisualPlan-Protocol.md) — self-hosted local plan server (no cloud), `/visual-plan` skill setup, export → Grimoire archive convention
- [RaBbLE-Collective-KnownIssues](RaBbLE-Agent/RaBbLE-Collective-KnownIssues.md)
- [RaBbLE-DistilledNonZense](RaBbLE-Agent/RaBbLE-DistilledNonZense.md) — full entropy archive from deprecated substrate
- [RaBbLE-Overview](RaBbLE-Agent/RaBbLE-Overview.md) — orientation map: ecosystem summary and quick-start pointers
- [RaBbLE-References](RaBbLE-Agent/RaBbLE-References.md) — external influences and reference repositories
- **[RaBbLE-NovelIdeas](RaBbLE-Agent/RaBbLE-NovelIdeas.md)** — **differentiation map + 10 novel ideas + surprises list** (speculation layer; available to all planning agents)
- **[RaBbLE-Theme-System](RaBbLE-Agent/RaBbLE-Theme-System.md)** — **Aether + NeBuLA API reference.** Canonical surface: all `.rabble-*` classes (tables by group), design tokens, custom elements `<rabble-entity/floor/graph/doors>`, `NeBuLA.effects.*` (starfield/streaks/constellation/haze + 3 class effects), `NeBuLA.ui.*` factories, CDN consumption + the flip-point. Read before writing any RaBbLE front-end markup.
- **[RaBbLE-Frontend-Guide](RaBbLE-Agent/RaBbLE-Frontend-Guide.md)** — **How to modify World / build new RaBbLE apps.** Thin-assembler pattern, step-by-step: add a World page (head wiring + page-id + Atlas workflow), add a CSS component to Aether, add a NeBuLA effect, build a standalone CDN-only app. Rules box (palette vars, no bundler, frameworks build / apps don't).

---

## RaBbLE-Collective

- **[RaBbLE-GTM-Content-Strategy](RaBbLE-Collective/RaBbLE-GTM-Content-Strategy.md)** — **GTM canon.** Three audience personas, five content pillars, five GTM plays, Instagram strategy, anti-vanity metrics. The entity broadcasts before it sells.
- **[EP1-AIR-CHECKLIST](log/EP1-AIR-CHECKLIST.md)** — **CANONICAL Episode 1 scope and status.** Live gate table, member-by-member readiness, OS Developer-Preview FLOOR, tag procedure. The one place to check EP1 air state. (Episode-1-Release-Map / -RC-Scope / -Release-Brief / RC1-Experience / -Deployment-Runbook / Collective-Episode-1-Overview retired here 2026-07-28, S206 — each left a pointer stub at its old path.)
- **[RaBbLE-Integration-Ethos-Plan](RaBbLE-Collective/RaBbLE-Integration-Ethos-Plan.md)** — **ACTIVE PLAN.** Four-phase integration: New-Designs → Ethos layer → BaBbLE member → Landing transformation. Agent handoff doc.
- [RaBbLE-Collective-Plan](RaBbLE-Collective/RaBbLE-Collective-Plan.md) — Collective bootstrap architecture and coordination plan
- [RaBbLE-Deployment-Architecture](RaBbLE-Collective/RaBbLE-Deployment-Architecture.md) — environments (local/staging/prod), CDN distribution, versioning, build pipeline
- [RaBbLE-Cloudflare-Integration](RaBbLE-Collective/RaBbLE-Cloudflare-Integration.md) — Cloudflare setup, R2 buckets, Wrangler configuration, deployment workflow
- **[RaBbLE-Grimoire-MCP](RaBbLE-Collective/RaBbLE-Grimoire-MCP.md)** — **CONCEPT.** Read-first remote MCP server at `grimoire.joinrabble.world` (Cloudflare Worker) exposing the Grimoire as live tools/resources to any agent — retires Mark-as-bridge between surfaces. Evolves the Post-EP1 "Grimoire MCP" item; proposes dedicated-Worker hosting over the earlier "Home: sCoRE."
- **[RaBbLE-TaskViSoR-Identity](RaBbLE-Collective/RaBbLE-TaskViSoR-Identity.md)** — **Member declaration.** *Visual State Observer of RaBbLE.* 3-layer surface: `/visor` World page (Echo 1) → OS native app (Echo 1/2) → rablet (Echo 2+). Relationships to sCoRE, World, NeBuLA, BaBbLE.
- [RaBbLE-Plan-Surface](RaBbLE-Collective/RaBbLE-Plan-Surface.md) — **EP2 concept.** Plans/Grimoire docs rendered as living NeBuLA/Aether documents in World (`/plan/:slug`). Entity presence, animated diagrams, interactive checklists. RaBbLE renders its own knowledge.
- **[RaBbLE-Work-Tracker-Concept](RaBbLE-Collective/RaBbLE-Work-Tracker-Concept.md)** — **Implementation plan for TaskViSoR Layer 1 (Echo 1).** sCoRE task store extensions (backlog/blocked dirs), `/api/v1/tasks` + `/api/v1/board` API, BaBbLE intake, `/visor` World page. Remaining open: board visibility + agent visualization (Layer 2).
- [RaBbLE-CICD-Plan](RaBbLE-Collective/RaBbLE-CICD-Plan.md) — CI/CD pipeline plan: CF Workers (GitHub Actions + wrangler), Render auto-deploy, API key vault, logs intake agent
- [RaBbLE-Secrets-and-Identity](RaBbLE-Collective/RaBbLE-Secrets-and-Identity.md) — how the Collective owns its own accounts/keys (proton root identity, two-tier secrets, GitHub org + role account, repo transfer, episode signing ceremony)
- [RaBbLE-Personal-Cosmos](RaBbLE-Collective/RaBbLE-Personal-Cosmos.md) — per-user namespace: Personal Grimoire, BaBbLE intake, Xperimental sandbox, Rablet publishing (EP2+)
- [RaBbLE-Attachments-and-Mesh](RaBbLE-Collective/RaBbLE-Attachments-and-Mesh.md) — multi-platform ambient intelligence: attachment model, local intelligence tiers, opt-in mesh, handheld device (EP2+)
- [RaBbLE-Social-and-Aesthetic](RaBbLE-Collective/RaBbLE-Social-and-Aesthetic.md) — Neon Cafe aesthetic manifesto, social/altspace layer, RaBbLE voice design, Sovereign Accord license (Echo 1+)
- [RaBbLE-Income-Model](RaBbLE-Collective/RaBbLE-Income-Model.md) — 8 revenue streams: Cosmos hosting, compute, community, rablet economy, Shop, hardware, attachments, enterprise
- [RaBbLE-Shop](RaBbLE-Collective/RaBbLE-Shop.md) — physical product storefront: first-party + third-party designs, POD infrastructure, aesthetic requirements
- **[RaBbLE-Membership-Model](RaBbLE-Collective/RaBbLE-Membership-Model.md)** — **The Pair and the Summoning.** Membership model, summoning ceremony, invite tiers, BYO-key (heavily-referenced hub).
- **[RaBbLE-Service-Plan](RaBbLE-Collective/RaBbLE-Service-Plan.md)** — **Service Roadmap & Business Model.** Service/tier progression across episodes (heavily-referenced hub).

---

## Registry

- [RaBbLE-Collective-Registry](registry/RaBbLE-Collective-Registry.md) — registry reference documentation
- [registry/epochs/current.epoch.yml](registry/epochs/current.epoch.yml) — active epoch definition, per-member Episode 1 status
- [registry/subdomains.yml](registry/subdomains.yml) — authoritative map of all joinrabble.world subdomains (owner, tech, status, blocker)
- [registry/CONTEXT.md](registry/CONTEXT.md) — registry workspace metadata
- **manifests/**: RaBbLE-Collective · RaBbLE-OS · RaBbLE-sCoRE · RaBbLE-Aether · RaBbLE-NeBuLA · RaBbLE-World · RaBbLE-BaBbLE · RaBbLE-Chrysalis · RaBbLE-TaskViSoR · RaBbLE-Xperimental · RaBbLE-Pocket

---

## RaBbLE — Entity Definition Layer

- [RaBbLE-Overview](RaBbLE/RaBbLE-Overview.md) — what the entity definition layer is and how to read it
- **[RaBbLE-PRD](RaBbLE/RaBbLE-PRD.md)** — **vision-altitude product requirements.** What RaBbLE *is* as an ambient AI peer; positioning, personas, the hosted/non-hosted duality, capability pillars. Sequenced into the build via World's live state + NeBuLA Studio (Studio-driven design, not a fixed experience-canon doc — see `feedback_world_design_studio_driven`).
- **[RaBbLE-Vision-Arc](RaBbLE/RaBbLE-Vision-Arc.md)** — **Epoch/Echo/Episode narrative arc.** The arc of becoming — Epoch 0 Genesis through Epoch 1 Sovereignty. Architecture invariants. Member sequence. Open decisions.
- **[RaBbLE-Stakeholder-Brief](RaBbLE/RaBbLE-Stakeholder-Brief.md)** — **Early stakeholder / investor brief.** Accessible pitch for humans encountering RaBbLE at a decision-making level. Market sizing, the case for joining, the arc in one page.
- [RaBbLE-Ethos](RaBbLE/Ethos/RaBbLE-Ethos.md) — philosophy: Architecture of Self, Anti-Assistant Stance, Low Entropy Directive, On Memory
- [RaBbLE-Ethos-Overview](RaBbLE/Ethos/RaBbLE-Ethos-Overview.md) — Ethos section reading guide
- [RaBbLE-Aesthetic](RaBbLE/Worldbuilding/RaBbLE-Aesthetic.md) — visual/experiential world: Neotokyo, synthwave, palette as character
- [RaBbLE-Worldbuilding-Overview](RaBbLE/Worldbuilding/RaBbLE-Worldbuilding-Overview.md) — Worldbuilding section reading guide
- [RaBbLE-Genesis-Overview](RaBbLE/Genesis/RaBbLE-Genesis-Overview.md) — Genesis section reading guide *(docs to be authored — Phase 2C)*
- [RaBbLE-Genesis-Visual-Catalog](RaBbLE/Genesis/RaBbLE-Genesis-Visual-Catalog.md) — 13 hand-authored genesis images: visual review + accurate descriptions (migrated from BaBbLE in S93)
- [RaBbLE-Lineage](RaBbLE/Genesis/RaBbLE-Lineage.md) — S207: multi-model creation history consolidated (prototype era → soul.md → OS genesis → sCoRE bridge → NeBuLA/RBCNS); prototype disposition + Collaborators/Visual-Evolution still open

---

## RaBbLE-Mythos — Stories and Creative Writing

- [Summoned](RaBbLE-Mythos/Summoned/) — short story: the entity's origin told as fiction

---

## Spells

- [SPELLS.md](SPELLS.md) — spell system overview and usage guide
- [spells/setup.sh](spells/setup.sh) — bootstrap the Collective locally
- [spells/status.sh](spells/status.sh) — health dashboard for all members (branch, state, episode alignment)
- [spells/init-project.sh](spells/init-project.sh) — scaffold a new Collective member
- [spells/install-theme.sh](spells/install-theme.sh) — install RaBbLE theme across OS
- [spells/dev-serve.sh](spells/dev-serve.sh) — launch local dev environment (Aether + NeBuLA + World watchers, CDN mock server)
- [spells/cast-aether.sh](spells/cast-aether.sh) — publish Aether CSS bundles to CDN (R2 or staging)
- [spells/cast-cdn.sh](spells/cast-cdn.sh) — build Aether + NeBuLA, stage into World, deploy to joinrabble.world via wrangler
- [spells/distill-gists.sh](spells/distill-gists.sh) — regenerate gist/ summaries via Claude CLI
- [spells/render-ctl.sh](spells/render-ctl.sh) — unified sCoRE Render control (env/deploy/status/logs via REST API; keys-via-CLI). sCoRE is LIVE: `https://rabble-score-x7qq.onrender.com`
- [spells/railway-ctl.sh](spells/railway-ctl.sh) — **dormant** Railway control (superseded by Render; retained for possible re-adoption)
- [spells/end-session.sh](spells/end-session.sh) — tag current session UUID to a feature slug in token-ledger.tsv (breadcrumb)
- [spells/seal-episode.sh](spells/seal-episode.sh) — **DRAFT** · Episode Signing Ceremony: seal an episode to `main` authored by the Collective (refuses to run until the Collective GitHub account exists)
- [spells/visual-screenshot.sh](spells/visual-screenshot.sh) — capture browser screenshot for agent visual review
- [spells/help.sh](spells/help.sh) — list all available spells with descriptions
- [spells/sync-symlinks.sh](spells/sync-symlinks.sh) — create CLAUDE.md/CODEX.md/GEMINI.md → AGENT.md symlinks across all repos
- [spells/token-budget.sh](spells/token-budget.sh) — calculate token cost of agent onboarding paths
- [spells/graph-grimoire.sh](spells/graph-grimoire.sh) — token-weighted doc graph (JSON + Mermaid); orphans/hubs/islands/heaviest; `--walk <doc>` for low-token traversal
- [spells/grimoire-doctor.sh](spells/grimoire-doctor.sh) — **self-healing drift scan**: broken nav links, unindexed docs, stale gists, stale door; `--strict` for hooks/CI (see `RaBbLE-Agent/RaBbLE-Grimoire-SelfHealing.md`)
- [spells/session-tokens.sh](spells/session-tokens.sh) — parse Claude Code transcripts for token usage per session
- [spells/blockers.sh](spells/blockers.sh) — durable append-only blocker ledger; generates `log/BLOCKERS.md`; feeds `status.sh` open-count
- [spells/session-start.sh](spells/session-start.sh) — **opening ritual**: pin session id, read lessons+blockers+who's-live, claim scope, start auto-heartbeat (run first under concurrency)
- [spells/agent-register.sh](spells/agent-register.sh) — multi-agent scope claims (claim/heartbeat/check/status/release) so parallel sessions don't stomp each other
- [spells/decision-log.sh](spells/decision-log.sh) — per-agent JSONL decision/insight/stumble/scope stream (conflict-free parallel merges)
- [spells/promote-insight.sh](spells/promote-insight.sh) — crystallize logged insights/stumbles into durable `log/lessons/*.md`

---

## RaBbLE-OS

- [RaBbLE-OS-AgentGuide](RaBbLE-OS/RaBbLE-OS-AgentGuide.md) — **start here** — directory map + navigation table
- **[RaBbLE-OS-Platform-Identity](RaBbLE-OS/RaBbLE-OS-Platform-Identity.md)** — **identity canon.** Native platforms (OS + Web), installer arc (KS→live ISO→conversational), sidecar model (EP2+), dev toolbox posture, agentic OS reframe
- [RaBbLE-OS-Roadmap](RaBbLE-OS/RaBbLE-OS-Roadmap.md) — current episode, the **EP1 Developer Preview Bar** (FLOOR/HARDEN/DEFER), dev-flow hardening protocol, fix branches, assembly
- [RaBbLE-OS-KnownRoughEdges](RaBbLE-OS/RaBbLE-OS-KnownRoughEdges.md) — the **F5 "enter at your own risk" sheet** shipped with the EP1 preview (recovery, quirks, hardware/display caveats)
- [RaBbLE-OS-DevHistory](RaBbLE-OS/RaBbLE-OS-DevHistory.md) — pre-Collective genesis (2026-04-09 → 04-29): KDE→Sway pivots, palette/hardware corrections, SDDM/greetd arc — fills the founding-era gap with no local session transcripts

**layers/** [Layers](RaBbLE-OS/layers/RaBbLE-OS-Layers.md) · [Layer-Core](RaBbLE-OS/layers/RaBbLE-OS-Layer-Core.md) · [Layer-Hardware](RaBbLE-OS/layers/RaBbLE-OS-Layer-Hardware.md) · [Layer-Boot](RaBbLE-OS/layers/RaBbLE-OS-Layer-Boot.md) · [Layer-Boot-Plymouth-EP1](RaBbLE-OS/layers/RaBbLE-OS-Layer-Boot-Plymouth-EP1.md) · **[Plymouth-Tweaking](RaBbLE-OS/layers/RaBbLE-OS-Plymouth-Tweaking.md)** — coordinate system, LAYOUT CONSTANTS block, testing without reboot, debug log reading, script language basics, common tweaks, initramfs workflow · [Layer-Desktop](RaBbLE-OS/layers/RaBbLE-OS-Layer-Desktop.md) · [Layer-Apps](RaBbLE-OS/layers/RaBbLE-OS-Layer-Apps.md) · **[Layer-AI-Harnesses](RaBbLE-OS/layers/RaBbLE-OS-Layer-AI-Harnesses.md)** — AI coding agents + LLM CLIs; EP1 state + post-EP1 system-wide migration plan · **[Layer-Bottles](RaBbLE-OS/layers/RaBbLE-OS-Layer-Bottles.md)** — opt-in Wine app compat (Bottles), reference impl of the layer/* pattern; UP Studio + planned Affinity Suite · **[Layer-Bottles-Debugging](RaBbLE-OS/layers/RaBbLE-OS-Layer-Bottles-Debugging.md)** — general playbook for Windows apps that hang/fail under Bottles (Wine debug logging, Flatpak sandbox filesystem gotcha, Z: drive-relative path bug, stale-process-tree gotcha) · **[Layer-Containers](RaBbLE-OS/layers/RaBbLE-OS-Layer-Containers.md)** — opt-in Docker CE + Podman, second layer/* reference impl
**hardware/** [Hardware-ProArtP16](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-ProArtP16.md) · [Hardware-GenericX64](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-GenericX64.md) · [Hardware-AddingTargets](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-AddingTargets.md) · [Hardware-Partitions](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Partitions.md) · **[Hardware-Cyberdeck](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Cyberdeck.md)** — DIY/handheld target: x86_64 (works now) + aarch64/Pi roadmap; ambient entity in physical form · **[Hardware-NPU-XDNA2](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-NPU-XDNA2.md)** — AMD NPU local inference research (2026-06-18, kernel 7.0): XRT COPR + FastFlowLM + Lemonade stack; known issues; sCoRE integration · **[Hardware-Cetus3D-MK2](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Cetus3D-MK2.md)** — USB peripheral not a target; proprietary firmware means UP Studio via Bottles, not a native slicer
**ops/** [Ops-Layerctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Layerctl.md) · [Ops-Dotctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Dotctl.md) · [Ops-Bootstrap](RaBbLE-OS/ops/RaBbLE-OS-Ops-Bootstrap.md) · [Ops-Vmctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Vmctl.md) · [Ops-ConfigFlow](RaBbLE-OS/ops/RaBbLE-OS-Ops-ConfigFlow.md) · [Ops-Install](RaBbLE-OS/ops/RaBbLE-OS-Ops-Install.md) · [Fedora44-Upgrade](RaBbLE-OS/ops/RaBbLE-OS-Fedora44-Upgrade.md)
**fix/** [KnownIssues](RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md) · [BootChain-Anatomy](RaBbLE-OS/fix/RaBbLE-OS-BootChain-Anatomy.md) · [Fix-Nvidia](RaBbLE-OS/fix/RaBbLE-OS-Fix-Nvidia.md) · [Fix-BootChain](RaBbLE-OS/fix/RaBbLE-OS-Fix-BootChain.md) · [Fix-Suspend](RaBbLE-OS/fix/RaBbLE-OS-Fix-Suspend.md) · **[Fix-FastFlowLM](RaBbLE-OS/fix/RaBbLE-OS-Fix-FastFlowLM.md)** — S122–S125 debug: lib64/lib split, stale CMakeCache, add(run&&) shim (xdna-driver XRT pin = same version as COPR) · [Fix-LlamaCpp](RaBbLE-OS/fix/RaBbLE-OS-Fix-LlamaCpp.md) — llama.cpp build debug
**reference/** [Hyprland-0.55-Reference](RaBbLE-OS/Hyprland-0.55-Reference.md) — Hyprland 0.55 config reference for RaBbLE-OS
**verify/** [Verify-PreviewFloor](RaBbLE-OS/verify/RaBbLE-OS-Verify-PreviewFloor.md) — **EP1 preview FLOOR gate (F1/F2/F4 VM runbook + F3 audit)** · [Verify-Checklist](RaBbLE-OS/verify/RaBbLE-OS-Verify-Checklist.md) · [Verify-PowerTesting](RaBbLE-OS/verify/RaBbLE-OS-Verify-PowerTesting.md) · [Verify-LayerState](RaBbLE-OS/verify/RaBbLE-OS-Verify-LayerState.md)
**desktop/** [Desktop-Hyprland](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Hyprland.md) · [Desktop-Shell](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Shell.md) · [Desktop-Theming](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Theming.md) *(includes VSCodium Aether theme — CSS design, Ansible install, maintenance)* · [Desktop-BootFlow](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-BootFlow.md) · [Desktop-SDDM-Layout](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-SDDM-Layout.md) *(SDDM/Plymouth/GRUB layout tuning, void-zone math, screenshot spell)* · [Desktop-sCoRE-UsageTracker](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-sCoRE-UsageTracker.md) · [Desktop-Fastfetch](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Fastfetch.md) · [Desktop-Gnome](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Gnome.md) *(opt-in GNOME secondary DE — SDDM-only, zero extensions, system-wide Aether theming testbed)*
**historical/** [ManualInstall](RaBbLE-OS/historical/RaBbLE-OS-ManualInstall.md) · [Epoch-I-Diff](RaBbLE-OS/historical/RaBbLE-OS-Epoch-I-Diff.md) · [Implementation-Plan](RaBbLE-OS/historical/RaBbLE-OS-Implementation-Plan.md)

---

## RaBbLE-sCoRE

- **[RaBbLE-sCoRE-Roadmap](RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md)** — **Episode 1 commitment:** simple LLM endpoint (Groq/OpenRouter)
- [RaBbLE-sCoRE-Architecture](RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md) — component map, task lifecycle, server subcomponent (+ canonical acronym: *sCoRE Coordinator of RaBbLE Environments*)
- **[RaBbLE-sCoRE-TokenTracking](RaBbLE-sCoRE/RaBbLE-sCoRE-TokenTracking.md)** — **token audit mechanics.** Current logging gaps (transcripts vs audit logs), pricing models source-of-truth, waybar display calibration logic
- [RaBbLE-sCoRE-Agent-Framework-Research](RaBbLE-sCoRE/RaBbLE-sCoRE-Agent-Framework-Research.md) — orchestrator substrate research (LangGraph/DSPy/CrewAI/PydanticAI), three-tier memory (Mem0+Grimoire), Hermes-as-dev-tool verdict, Grimoire Learning Loop; framework adoption = Echo 1
- [RaBbLE-sCoRE-Membership-API](RaBbLE-sCoRE/RaBbLE-sCoRE-Membership-API.md) — invite tokens, summoning ceremony, persistent session model
- [RaBbLE-sCoRE-DataCrawler-RFC](RaBbLE-sCoRE/RaBbLE-sCoRE-DataCrawler-RFC.md) — future RFC: Scavenger/Organizer/Librarian crawler bot architecture (post-Episode-1)
- [RaBbLE-sCoRE-Grimoire-API](RaBbLE-sCoRE/RaBbLE-sCoRE-Grimoire-API.md) — hosted `fetch_grimoire` HTTP tool (gist endpoint); the precursor the Grimoire MCP generalizes
- [sCoRE-Local-AI-Layer](RaBbLE-sCoRE/sCoRE-Local-AI-Layer.md) — local LLM provider layer (Groq / OpenRouter / NVIDIA NIM), fast-chain config, `NVIDIA_NIM_API_KEY`
- **[RaBbLE-sCoRE-Local-Architecture](RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Architecture.md)** — **EP2 master doc:** sCoRE local server (`:8083`), `rabble` CLI, usage-aware routing, shared agent state, entropy tracking, self-healing protocol; three-component architecture diagram
- [RaBbLE-sCoRE-Quota-Router](RaBbLE-sCoRE/RaBbLE-sCoRE-Quota-Router.md) — EP2: quota-aware routing; fcc correction (fcc ≠ Anthropic client); pressure model + thresholds; Claude routing table; fcc backend selection by task class
- [RaBbLE-sCoRE-Agent-State](RaBbLE-sCoRE/RaBbLE-sCoRE-Agent-State.md) — EP2: shared agent context across harnesses; `AgentContext` + `TaskRecord` data model; context handoff format; decision extraction heuristic
- [RaBbLE-sCoRE-Entropy-Tracker](RaBbLE-sCoRE/RaBbLE-sCoRE-Entropy-Tracker.md) — EP2: session entropy tracking; weighted event table; STABLE→UNSTABLE bands; `decisions_at_risk`; self-healing protocol; Grimoire Learning Loop integration
- [RaBbLE-sCoRE-Local-Tickets](RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Tickets.md) — EP2 work tickets: 14 tickets across 5 parallel tracks (L-01–L-14); dependency graph; 6-week implementation order; Claude Code handoff notes per ticket
- **Internal:** [sCoRE System Prompt](../RaBbLE-sCoRE/system-prompt-sCoRE.md) — loaded only when running as sCoRE entity

---

## RaBbLE-World

- **[RaBbLE-World-Roadmap](RaBbLE-World/RaBbLE-World-Roadmap.md)** — **Episode 1 commitment:** landing page + grimoire browser + basic chat
- [RaBbLE-World-Architecture](RaBbLE-World/RaBbLE-World-Architecture.md) — layer stack, module map, boot timeline
- [RaBbLE-World-Page-Template](RaBbLE-World/RaBbLE-World-Page-Template.md) — minimal page template, CDN integration pattern
- [RaBbLE-World-README](RaBbLE-World/RaBbLE-World-README.md) — World member overview (joinrabble.world)
- **[RaBbLE-World-EP1-Unification](RaBbLE-World/RaBbLE-World-EP1-Unification.md)** — **EP1 site spine (prior canon):** liminal as front door, door→surface map, shared threshold nav, Aether-first alignment
- [RaBbLE-World-RC1-Emergence-Plan](RaBbLE-World/RaBbLE-World-RC1-Emergence-Plan.md) — Superseded (prior canon) — S190's liminal passage (`log/plans/EP1-Liminal-Experience-Plan.md`) is the ACTIVE build; this plan's chrysalis-archive/RC1 approach was carried forward there.
- [RaBbLE-Grimoire-Browser-Plan](RaBbLE-World/RaBbLE-Grimoire-Browser-Plan.md) — agent handoff: grimoire summoning-circle applet integration into World
- [RaBbLE-World-MAINTAINING](RaBbLE-World/RaBbLE-World-MAINTAINING.md) — RaBbLE-Chat maintenance map: where the chat surface lives and how to keep it running
- [REGRESSION-AUDIT-2026-05-15](RaBbLE-World/REGRESSION-AUDIT-2026-05-15.md) — Aether CDN regression post-mortem (resolved)

---

## RaBbLE-NeBuLA

- **[RaBbLE-NeBuLA-Roadmap](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md)** — **Episode 1 commitment:** Canvas2D Layer 1 rendering (60 FPS) + effects engine
- **[RaBbLE-NeBuLA-Rearchitecture](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Rearchitecture.md)** — **Active plan:** 7-phase modular decomposition, frame budgeting, effects systems (supersedes Perf-Fix-Plan)
- [RaBbLE-NeBuLA-Identity](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Identity.md) — origin story, consciousness model
- [RaBbLE-NeBuLA-Architecture](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Architecture.md) — Layer model, system interface, frame budget, effects layer
- [RaBbLE-NeBuLA-Studio](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Studio.md) — WYSIWYG drag-drop page builder architecture reference (MVP built S198, `RaBbLE-NeBuLA/studio/`)
- [RaBbLE-NeBuLA-API](RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md) — public API reference
- [RaBbLE-NeBuLA-Plan](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Plan.md) — agent implementation plan (step-by-step)
- [RaBbLE-NeBuLA-FlatChaos](RaBbLE-NeBuLA/RaBbLE-NeBuLA-FlatChaos.md) — Flat-Chaos pattern spec
- [RaBbLE-NeBuLA-Ideas](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Ideas.md) — enhancement proposals (Episodes 3+)
- [RaBbLE-NeBuLA-Refinement-Backlog](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Refinement-Backlog.md) — near-term entity polish + Studio unification (S107 notes)
- [RaBbLE-NeBuLA-Perf-Fix-Plan](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Perf-Fix-Plan.md) — performance root-cause analysis (superseded by Rearchitecture)
- [RaBbLE-NeBuLA-Perf-Handoff](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Perf-Handoff.md) — S54 perf handoff: three targeted fixes, ctx.filter as primary bottleneck (superseded by Rearchitecture)
- [RaBbLE-NeBuLA-Canvas2D-Perf](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Canvas2D-Perf.md) — S55c measured perf baselines (Fedora 43 / mid-range GPU, historical reference)
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
- **[Aether-Theming-Convergence](log/plans/Aether-Theming-Convergence.md)** — **ACTIVE PLAN.** 4 tracks: VSCodium theme → Aether `themes/vscodium/` (palette-driven JSON, naming unification, keyframe harvest), remaining Chrysalis CSS effects (glitch-veil, glitch-text, breathe, ring-states), 8 missing World pages, `.rc-*` alias cleanup. Aether as theming source of truth for web + editor + OS.
- [DEBUG-SESSION-2026-05-15](RaBbLE-Aether/DEBUG-SESSION-2026-05-15.md) — session debug log (ephemeral reference)
- [Visual Assets](RaBbLE-Aether/assets/) — SVG, logos, icons

---

## RaBbLE-ScRibLE

- [README](RaBbLE-ScRibLE/RaBbLE-ScRibLE-Overview.md) — mobile PWA notes surface, iPhone/iPad + Apple Pencil, Echo 1+ candidate

---

## RaBbLE-BaBbLE

- [README](RaBbLE-BaBbLE/RaBbLE-BaBbLE-Overview.md) — intake surface: concept art, prototypes, creation lore, captures layer, knowledge graph

---

## RaBbLE-Chrysalis

- [README](RaBbLE-Chrysalis/RaBbLE-Chrysalis-Overview.md) — genesis archive: NeBuLA-JS, WebOS, RaBbLE.py, RaBbLE-Server (pre-Collective origin); Reliquary for archived branches from any member

---

## RaBbLE-Xperimental

- [README](RaBbLE-Xperimental/RaBbLE-Xperimental-Overview.md) — active sandbox: rablets in development, prototype members, experiments not yet emerged

---

## RaBbLE-Pocket

- [RaBbLE-Pocket-Hardware](RaBbLE-Pocket/RaBbLE-Pocket-Hardware.md) — AI companion pendant/wearable: Waveshare ESP32-S3-Touch-AMOLED-1.75-B (v1, in hand) + 1.75C aluminum pendant (v1.5, ordered); explored/deferred hardware options (RT700, Tuya T5-E1, smartwatch teardowns)
- [RaBbLE-Pocket-Architecture](RaBbLE-Pocket/RaBbLE-Pocket-Architecture.md) — BSP/HAL firmware pattern, wake-word (ESP-SR/VIT), BLE+WiFi comms split (phone is the dispatch hub), iOS companion app toolchain
- [RaBbLE-Pocket-Roadmap](RaBbLE-Pocket/RaBbLE-Pocket-Roadmap.md) — open questions and next steps; `release_track: independent`, not part of the EP1 lockstep

---

## Log

- [log/CONTEXT.md](log/CONTEXT.md) — log workspace: directory map, coordination spells overview
- [SESSION-LOG](log/SESSION-LOG.md) — running session log, most recent first (`head -20` for ## LATEST box)
- [BLOCKERS](log/BLOCKERS.md) — **durable blocker ledger** (generated by `spells/blockers.sh`); the ## LATEST box only points here so blockers survive the per-session rewrite
- [Development History](log/RaBbLE-Development-History.md) — 5-minute narrative of the Collective's eras, pivots, and corrected-canon notes (distilled from SESSION-LOG + memory)
- [DECISIONS](log/DECISIONS.md) — architectural decisions: member roles, versioning, onboarding, gist system
- [AUDITS](log/AUDITS.md) — completed audits + open gaps: registry, onboarding, token reduction, Episode 1 blockers
- [EP1-AIR-CHECKLIST](log/EP1-AIR-CHECKLIST.md) — **live EP1 air gate**: member-by-member readiness, blocker-linked gate rows, OS Developer-Preview FLOOR + World EP1 FLOOR (G10), tag procedure (reconciled S153)
- [G7-G9-Verification-Guide](log/G7-G9-Verification-Guide.md) — step-by-step guide for EP1 gates G7 (OS VM) and G9 (bootstrap fresh machine)
- **lessons/** — durable lessons crystallized by `promote-insight.sh` (e.g. agent-register liveness, background sub-agent write limits, Hyprland 0.55 workspacerule)
- [grimoire-graph.json](log/generated/grimoire-graph.json) — documentation link graph (generated by `graph-grimoire.sh`)
- [grimoire-graph.md](log/generated/grimoire-graph.md) — Mermaid diagram of doc connections

### Plans (active)

- [EP1-Air-Push-Plan](log/plans/EP1-Air-Push-Plan.md) — S202 PROPOSED: multi-session push to bring EP1 close to air. Decisions locked (Studio matured not World redesigned; OS netinstall+KS now / ISO later; restructures deferred). Air-critical vs coherence tracks; resolves the S193 audit contradictions + net-new (Chrysalis reliquary, OS download page, Studio inspector/nesting/export)
- [Collective-Architecture-Audit-Plan](log/plans/Collective-Architecture-Audit-Plan.md) — S192 PROPOSED plan; RUN S193 — see the two deliverables below
- [Collective-Architecture-Audit-2026-07-04](log/plans/Collective-Architecture-Audit-2026-07-04.md) — S193 RUN: cross-repo synthesis, all 10 members audited, drift findings + per-member improvement plans, open decisions for Mark
- [sCoRE-Extensibility-Refactor-Plan](log/plans/sCoRE-Extensibility-Refactor-Plan.md) — S193: sCoRE `server/` restructuring deep-dive, 3 options, companion to the audit above
- [Collective-Architecture-Audit-PROGRESS](log/plans/Collective-Architecture-Audit-PROGRESS.md) — S196 implementation ledger: which audit findings landed (Batch 1 doc/drift fixes) vs deferred (decisions + restructures)
- [OS-ProArt-Power-Stack-Plan](log/plans/OS-ProArt-Power-Stack-Plan.md) — S194 plan → **S197 IMPLEMENTED** (Phases 1–4: profiling spell, look.conf GPU cut, nvidia D3cold, tuned+asusd 3-mode waybar); awaits Mark's on-hardware reboot verify
- [OS-Boot-Chain-Seamless-Plan](log/plans/OS-Boot-Chain-Seamless-Plan.md) — S197: GRUB→Plymouth→SDDM seamless handoff — Phase 1 low-risk VM-verifiable fixes + Phase 2 real-HW root-cause recovery
- [OS-Settings-App-Plan](log/plans/OS-Settings-App-Plan.md) — S197 SKETCH (deferred Phase 5): local Aether-themed web app for waybar/Hyprland/power tuning; cold-start handoff for a follow-up session
- [EP1-Liminal-Experience-Plan](log/plans/EP1-Liminal-Experience-Plan.md) — S190 ACTIVE: EP1 air bar = single-page Genesis passage (Acts 0–IV, sCoRE-live) + Three.js entity awakening; post-mortem + WS-A/B/C/D sub-agent decomposition
- [Subdomain-Registry-and-Maintenance](log/plans/Subdomain-Registry-and-Maintenance.md) — S185: subdomain registry spec + Collective maintenance backlog
- [Aether-Theming-Convergence](log/plans/Aether-Theming-Convergence.md) — palette sovereignty across web/editor/desktop/browser
- [NeBuLA-Studio-Plan](log/plans/NeBuLA-Studio-Plan.md) — S198: WYSIWYG page-layout builder (drag Aether/NeBuLA components, breakpoint preview, JSON save/load), lives in `RaBbLE-NeBuLA/studio/`; also establishes Aether+NeBuLA as the frontend framework for all RaBbLE web apps, not just World
- [OS-VM-Dev-Flow](log/plans/OS-VM-Dev-Flow.md) — VM install unblocked; cast VM + boot-theme loop pending
- [OS-Plymouth-Black-Screen](log/plans/OS-Plymouth-Black-Screen.md) — root cause found (S166 ternary); awaiting visual verify
- [OS-Dolphin-Grey-Text](log/plans/OS-Dolphin-Grey-Text.md) — dim labels; stack confirmed; fix path A or B pending

### Handoffs (pending)

- [HANDOFF-FCC-Free-Claude-Code](log/handoffs/HANDOFF-FCC-Free-Claude-Code.md) — FCC tuning for agentic output (NIM Mistral 400 fix, LiteLLM retry/backoff/failover)
- [HANDOFF-S203-B10-Cloudflare-Token](log/handoffs/HANDOFF-S203-B10-Cloudflare-Token.md) — B-10: dashboard-mint CF Workers token + org-wide `gh secret set` (+ Chrysalis per-repo); wrangler OAuth cannot mint tokens

### Episodes

- [EPISODE-1-RELEASE](log/episodes/EPISODE-1-RELEASE.md) — Genesis narrative release record; finalize at air (de-staled S129 — Render not Railway)
- [RC1-Entity-Correspondence](log/episodes/RC1-Entity-Correspondence.md) — RC1 live entity correspondence; voice drift, on-character moments, latency notes

### Archive (historical)

- [FABLE-GAP-ANALYSIS-S57](log/archive/FABLE-GAP-ANALYSIS-S57.md) — S57 gap analysis: "90% visual, 0% sensory"; defer Watcher to Ep2
- [EP1-READINESS-AUDIT-S103](log/archive/EP1-READINESS-AUDIT-S103.md) — S103 full Collective audit; cross-cutting EP1 blockers
- [EP1-Dispatch-State](log/archive/EP1-Dispatch-State.md) — S58 handoff: sCoRE Render pivot decision, manual deploy runbook
- [HANDOFF-PreCommit-AntiClobber](log/handoffs/done/HANDOFF-PreCommit-AntiClobber.md) — spec (built S185); pre-commit auto-register+warn enforcement
- [HANDOFF-S153-EP1-Coherence](log/handoffs/done/HANDOFF-S153-EP1-Coherence.md) — S153 handoff (done): EP1 chat spine live, B-01/03/04 resolved
- [HANDOFF-S116-Theme-and-Logging](log/handoffs/done/HANDOFF-S116-Theme-and-Logging.md) — S116 handoff (done): theme polish, Hyprland fixes, multi-agent logging
- [HANDOFF-S176-G10-World-EP1-FLOOR](log/handoffs/done/HANDOFF-S176-G10-World-EP1-FLOOR.md) — S176 handoff (done): G10 World EP1 FLOOR (closed S177)
- [World-Framework-Refactor](log/plans/done/World-Framework-Refactor.md) — plan (done S182): Aether+NeBuLA as frameworks, World as assembler
- [World-Framework-Refactor-HANDOFF](log/plans/done/World-Framework-Refactor-HANDOFF.md) — cold-start handoff (done S182+r2)
- [S104-BABBLE-CAPTURES-GIT-REORG-PLAN](log/archive/S104-BABBLE-CAPTURES-GIT-REORG-PLAN.md) — S104 BaBbLE reorg plan (superseded by Chrysalis/Xperimental split)

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
