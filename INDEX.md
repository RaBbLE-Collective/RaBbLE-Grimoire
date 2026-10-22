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
- [RaBbLE-Palette-Candidates](RaBbLE-Agent/RaBbLE-Palette-Candidates.md) — consideration list (not canon): off-palette hexes found in real work, their canonical swaps, and promote notes (S234: alive entity + nebula ramp)
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
- **[EP1-AIR-CHECKLIST](log/EP1-AIR-CHECKLIST.md)** — **canonical EP1 scope + air state**: gate table, member readiness, OS FLOOR, tag procedure. (Older EP1 scope docs retired here S206; pointer stubs remain.)
- **[RaBbLE-Integration-Ethos-Plan](RaBbLE-Collective/RaBbLE-Integration-Ethos-Plan.md)** — **ACTIVE PLAN.** Four-phase integration: New-Designs → Ethos layer → BaBbLE member → Landing transformation. Agent handoff doc.
- [RaBbLE-Collective-Plan](RaBbLE-Collective/RaBbLE-Collective-Plan.md) — Collective bootstrap architecture and coordination plan
- [RaBbLE-Deployment-Architecture](RaBbLE-Collective/RaBbLE-Deployment-Architecture.md) — environments (local/staging/prod), CDN distribution, versioning, build pipeline
- [RaBbLE-Cloudflare-Integration](RaBbLE-Collective/RaBbLE-Cloudflare-Integration.md) — Cloudflare setup, R2 buckets, Wrangler configuration, deployment workflow
- **[RaBbLE-Grimoire-MCP](RaBbLE-Collective/RaBbLE-Grimoire-MCP.md)** — **concept**: read-first MCP server at `grimoire.joinrabble.world` exposing the Grimoire to any agent.
- **[RaBbLE-TaskViSoR-Identity](RaBbLE-Collective/RaBbLE-TaskViSoR-Identity.md)** — **Member declaration.** *Visual State Observer of RaBbLE.* 3-layer surface: `/visor` World page (Echo 1) → OS native app (Echo 1/2) → rablet (Echo 2+). Relationships to sCoRE, World, NeBuLA, BaBbLE.
- [RaBbLE-Plan-Surface](RaBbLE-Collective/RaBbLE-Plan-Surface.md) — **EP2 concept.** Plans/Grimoire docs rendered as living NeBuLA/Aether documents in World (`/plan/:slug`). Entity presence, animated diagrams, interactive checklists. RaBbLE renders its own knowledge.
- **[RaBbLE-Work-Tracker-Concept](RaBbLE-Collective/RaBbLE-Work-Tracker-Concept.md)** — TaskViSoR Layer 1 plan (Echo 1): sCoRE task store, `/api/v1/tasks` + `/board`, `/visor` page.
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
- **[RaBbLE-PRD](RaBbLE/RaBbLE-PRD.md)** — **vision-altitude product requirements**: positioning, personas, hosted/non-hosted duality, capability pillars.
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

**layers/** [Layers](RaBbLE-OS/layers/RaBbLE-OS-Layers.md) · [Layer-Core](RaBbLE-OS/layers/RaBbLE-OS-Layer-Core.md) · [Layer-Hardware](RaBbLE-OS/layers/RaBbLE-OS-Layer-Hardware.md) · [Layer-Boot](RaBbLE-OS/layers/RaBbLE-OS-Layer-Boot.md) · [Layer-Boot-Plymouth-EP1](RaBbLE-OS/layers/RaBbLE-OS-Layer-Boot-Plymouth-EP1.md) · [Plymouth-Tweaking](RaBbLE-OS/layers/RaBbLE-OS-Plymouth-Tweaking.md) · [Layer-Desktop](RaBbLE-OS/layers/RaBbLE-OS-Layer-Desktop.md) · [Layer-Apps](RaBbLE-OS/layers/RaBbLE-OS-Layer-Apps.md) · [Layer-AI-Harnesses](RaBbLE-OS/layers/RaBbLE-OS-Layer-AI-Harnesses.md) · [Layer-Bottles](RaBbLE-OS/layers/RaBbLE-OS-Layer-Bottles.md) · [Layer-Bottles-Debugging](RaBbLE-OS/layers/RaBbLE-OS-Layer-Bottles-Debugging.md) · [Layer-Containers](RaBbLE-OS/layers/RaBbLE-OS-Layer-Containers.md) · [Layer-ESP-IDF](RaBbLE-OS/layers/RaBbLE-OS-Layer-ESP-IDF.md) · [Layer-Arduino-CLI](RaBbLE-OS/layers/RaBbLE-OS-Layer-Arduino-CLI.md)
**hardware/** [Hardware-ProArtP16](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-ProArtP16.md) · [Hardware-GenericX64](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-GenericX64.md) · [Hardware-AddingTargets](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-AddingTargets.md) · [Hardware-Partitions](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Partitions.md) · [Hardware-Cyberdeck](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Cyberdeck.md) · [Hardware-NPU-XDNA2](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-NPU-XDNA2.md) · [Hardware-Cetus3D-MK2](RaBbLE-OS/hardware/RaBbLE-OS-Hardware-Cetus3D-MK2.md)
**ops/** [Ops-Layerctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Layerctl.md) · [Ops-Dotctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Dotctl.md) · [Ops-Bootstrap](RaBbLE-OS/ops/RaBbLE-OS-Ops-Bootstrap.md) · [Ops-Vmctl](RaBbLE-OS/ops/RaBbLE-OS-Ops-Vmctl.md) · [Ops-ConfigFlow](RaBbLE-OS/ops/RaBbLE-OS-Ops-ConfigFlow.md) · [Ops-Install](RaBbLE-OS/ops/RaBbLE-OS-Ops-Install.md) · [Fedora44-Upgrade](RaBbLE-OS/ops/RaBbLE-OS-Fedora44-Upgrade.md)
**fix/** [KnownIssues](RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md) · [BootChain-Anatomy](RaBbLE-OS/fix/RaBbLE-OS-BootChain-Anatomy.md) · [Fix-Nvidia](RaBbLE-OS/fix/RaBbLE-OS-Fix-Nvidia.md) · [Fix-BootChain](RaBbLE-OS/fix/RaBbLE-OS-Fix-BootChain.md) · [Fix-Suspend](RaBbLE-OS/fix/RaBbLE-OS-Fix-Suspend.md) · [Fix-FastFlowLM](RaBbLE-OS/fix/RaBbLE-OS-Fix-FastFlowLM.md) · [Fix-LlamaCpp](RaBbLE-OS/fix/RaBbLE-OS-Fix-LlamaCpp.md)
**reference/** [Hyprland-0.55-Reference](RaBbLE-OS/Hyprland-0.55-Reference.md) — Hyprland 0.55 config reference for RaBbLE-OS
**verify/** [Verify-PreviewFloor](RaBbLE-OS/verify/RaBbLE-OS-Verify-PreviewFloor.md) · [Verify-Checklist](RaBbLE-OS/verify/RaBbLE-OS-Verify-Checklist.md) · [Verify-PowerTesting](RaBbLE-OS/verify/RaBbLE-OS-Verify-PowerTesting.md) · [Verify-LayerState](RaBbLE-OS/verify/RaBbLE-OS-Verify-LayerState.md)
**desktop/** [Desktop-Hyprland](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Hyprland.md) · [Desktop-Shell](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Shell.md) · [Desktop-Theming](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Theming.md) · [Desktop-BootFlow](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-BootFlow.md) · [Desktop-SDDM-Layout](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-SDDM-Layout.md) · [Desktop-sCoRE-UsageTracker](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-sCoRE-UsageTracker.md) · [Desktop-Fastfetch](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Fastfetch.md) · [Desktop-Gnome](RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Gnome.md)
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
- [RaBbLE-World-RC1-Emergence-Plan](RaBbLE-World/RaBbLE-World-RC1-Emergence-Plan.md) — Superseded (prior canon) — S190's liminal passage (`log/plans/done/EP1-Liminal-Experience-Plan.md`) is the ACTIVE build; this plan's chrysalis-archive/RC1 approach was carried forward there.
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
- [Aether-Theming-Convergence](log/plans/Aether-Theming-Convergence.md) — plan: VSCodium theme into Aether, remaining Chrysalis effects, `.rc-*` cleanup (A1–A3 absorbed by OS-Theming-Variants)
- [DEBUG-SESSION-2026-05-15](RaBbLE-Aether/DEBUG-SESSION-2026-05-15.md) — session debug log (ephemeral reference)
- [Visual Assets](RaBbLE-Aether/assets/) — SVG, logos, icons

---

## RaBbLE-ScRiBbLE

- [README](RaBbLE-ScRiBbLE/RaBbLE-ScRiBbLE-Overview.md) — mobile PWA notes surface, iPhone/iPad + Apple Pencil; v1 live at scribble.joinrabble.world (S234)

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
- [RaBbLE-Pocket-Firmware-BuildFlash](RaBbLE-Pocket/RaBbLE-Pocket-Firmware-BuildFlash.md) — verified config/build/flash walkthrough (hello_world smoke test + vendor LVGL demo), eim activation-script gotcha + fix, USB re-enumeration + headless-monitor gotchas
- [RaBbLE-Pocket-Roadmap](RaBbLE-Pocket/RaBbLE-Pocket-Roadmap.md) — open questions and next steps; `release_track: independent`, not part of the EP1 lockstep
- [RaBbLE-Pocket-Backplate-CAD](RaBbLE-Pocket/RaBbLE-Pocket-Backplate-CAD.md) — custom battery-bay backplate (v1) + reference assembly, built parametric in FreeCAD (headless via Flatpak); mount holes/board orientation sourced from vendor STEP + drawing cross-check
- [RaBbLE-Pocket-Muse-SDK-Map](RaBbLE-Pocket/RaBbLE-Pocket-Muse-SDK-Map.md): Muse Gadget SDK bring-up record, why it's a bridge not a companion, file-level port map, gotchas
- [RaBbLE-Pocket-Clean-Room-Plan](RaBbLE-Pocket/RaBbLE-Pocket-Clean-Room-Plan.md): two-team clean-room replacement of every Meta-derived (Apache) file, module by module in waves W0 to W7: inventory with upstream overlap, roles and firewall, clean workspace recipe, provenance and overlap gates
- [Pocket clean room: specs + provenance](RaBbLE-Pocket/cleanroom/PROVENANCE.md): per-module clean-room specs (`cleanroom/w0-*` to `w4-*.spec.md`, with golden vectors; spec author + firewall reviewed; `w5-orbit.spec.md` is the Settings redesign, the Orbit dial) and the provenance ledger (who saw what, overlap result, Pocket commit); W0-W4 done S256-S264, W5 in build S266
- [RaBbLE-Pocket-Gadget-Port](RaBbLE-Pocket/RaBbLE-Pocket-Gadget-Port.md): S243 firmware rebuilt as a RaBbLE gadget on IDF v6.0.1: Apache-derived SDK parts isolated in `apache/`, own code in `accord/`, canvas-drawn face, push-to-talk beamed to sCoRE; layout, behaviour, what's verified, next
- [RaBbLE-Pocket-Beam-Protocol](RaBbLE-Pocket/RaBbLE-Pocket-Beam-Protocol.md): v0 draft WebSocket contract between Pocket and sCoRE (`/api/v1/beam`): PCM up/down with a 4-byte header, JSON turn events, capture turns returning note files (S264); what the sCoRE endpoint must do; `ops/beam-echo.py` reference
- [RaBbLE-Pocket-Capture-Plan](RaBbLE-Pocket/RaBbLE-Pocket-Capture-Plan.md): Converse/Capture modes (swipe up/down), notes beamed back from sCoRE into an on-device Pocket Grimoire (LittleFS or SD), USB offload into Personal-Grimoire; plus the S264 face-freeze root cause and fixes and the tilt rework
- [RaBbLE-Pocket-Entity-Port-Plan](RaBbLE-Pocket/RaBbLE-Pocket-Entity-Port-Plan.md): 60 fps procedural entity renderer ("NeBuLA-lite") for the CO5300 panel: band rendering + chord flush + TE pacing, half-res soft glow layer, gravity lock, 7 phases each with a gate; mock in Pocket `planning/mock/`
- [RaBbLE-Pocket-V1-Firmware-Plan](RaBbLE-Pocket/RaBbLE-Pocket-V1-Firmware-Plan.md) — first custom firmware: idle face (eyes/time/battery %), GIF-frame boot animation, touch settings, two-tier PMIC-gated sleep/wake; BSP/HAL file layout + 7-slice incremental verification plan

---

## RaBbLE-EnGrAm

- **[RaBbLE-EnGrAm-Architecture](RaBbLE-EnGrAm/RaBbLE-EnGrAm-Architecture.md)** — **the memory member**: unified item schema, hybrid vector+graph store, self-hosted PWA. Architecture only, no repo yet.

---

## Log

- [log/CONTEXT.md](log/CONTEXT.md) — log workspace: directory map, coordination spells overview
- [SESSION-LOG](log/SESSION-LOG.md) — running session log, most recent first (`head -20` for ## LATEST box)
- [BLOCKERS](log/BLOCKERS.md) — **durable blocker ledger** (generated by `spells/blockers.sh`); the ## LATEST box only points here so blockers survive the per-session rewrite
- [Development History](log/RaBbLE-Development-History.md) — 5-minute narrative of the Collective's eras, pivots, and corrected-canon notes (distilled from SESSION-LOG + memory)
- [DECISIONS](log/DECISIONS.md) — architectural decisions: member roles, versioning, onboarding, gist system
- [AUDITS](log/AUDITS.md) — completed audits + open gaps: registry, onboarding, token reduction, Episode 1 blockers
- [EP1-AIR-CHECKLIST](log/EP1-AIR-CHECKLIST.md) — live EP1 air gate (see Core Documents)
- [G7-G9-Verification-Guide](log/G7-G9-Verification-Guide.md) — step-by-step guide for EP1 gates G7 (OS VM) and G9 (bootstrap fresh machine)
- **lessons/** — durable lessons crystallized by `promote-insight.sh` (e.g. agent-register liveness, background sub-agent write limits, Hyprland 0.55 workspacerule)
- [grimoire-graph.json](log/generated/grimoire-graph.json) — documentation link graph (generated by `graph-grimoire.sh`)
- [grimoire-graph.md](log/generated/grimoire-graph.md) — Mermaid diagram of doc connections

### Plans (active)

Status lives in each plan; the one-line status table is [log/plans/CONTEXT.md](log/plans/CONTEXT.md).

- [EP1-Staging-and-Grimoire-Audit](log/plans/EP1-Staging-and-Grimoire-Audit.md) — path to air: gate truth, roadmap rewrite, de-bloat, public face, post-air user scaffold
- [EP1-Entity-Face-Plan](log/plans/EP1-Entity-Face-Plan.md) — the five-beat "alive" World face + NeBuLA entity (W0–W4)
- [EP1-Air-Push-Plan](log/plans/EP1-Air-Push-Plan.md) — S202 air push: deploy wrapper, CI, key inventory, reliquary garden
- [EP2-Accounts-Encryption-Spec](log/plans/EP2-Accounts-Encryption-Spec.md) — the user scaffold: accounts/sessions, then encrypted ingestion
- [Collective-ICM-Conformance-Audit](log/plans/Collective-ICM-Conformance-Audit.md) — Collective vs the ICM/MWP paper: stage contracts, handoff split
- [Collective-Architecture-Audit-2026-07-04](log/plans/Collective-Architecture-Audit-2026-07-04.md) — S193 cross-repo audit findings, per-member plans
- [Collective-Architecture-Audit-PROGRESS](log/plans/Collective-Architecture-Audit-PROGRESS.md) — ledger of which S193 findings landed
- [sCoRE-Extensibility-Refactor-Plan](log/plans/sCoRE-Extensibility-Refactor-Plan.md) — sCoRE `server/` restructure, options A/B/C
- [Subdomain-Registry-and-Maintenance](log/plans/Subdomain-Registry-and-Maintenance.md) — subdomain registry spec + maintenance backlog
- [Aether-Theming-Convergence](log/plans/Aether-Theming-Convergence.md) — palette sovereignty across web/editor/desktop/browser
- [NeBuLA-Pocket-Puppet-Rendering-Pipeline](log/plans/NeBuLA-Pocket-Puppet-Rendering-Pipeline.md) — shared puppet rig/animation pipeline for NeBuLA + Pocket
- [OS-Display-Manager-Plan](log/plans/OS-Display-Manager-Plan.md) — `rdisplay`: display layout manager (CLI, GTK4 editor, overlay, daemon)
- [OS-Settings-App-Plan](log/plans/OS-Settings-App-Plan.md) — first-party settings app sketch
- [OS-ProArt-Power-Stack-Plan](log/plans/OS-ProArt-Power-Stack-Plan.md) — ProArt power: asusd modes, waybar, GPU/D3cold
- [OS-Boot-Chain-Seamless-Plan](log/plans/OS-Boot-Chain-Seamless-Plan.md) — GRUB→Plymouth→SDDM seamless handoff
- [OS-Plymouth-Black-Screen](log/plans/OS-Plymouth-Black-Screen.md) — Plymouth black-screen root cause
- [OS-VM-Dev-Flow](log/plans/OS-VM-Dev-Flow.md) — VM dev loop on the RaBbLE-VM partition
- [OS-Theming-Variants-Plan](log/plans/OS-Theming-Variants-Plan.md) — theme variants + profiles + contrast QA

### Handoffs (pending)

Status: [log/handoffs/CONTEXT.md](log/handoffs/CONTEXT.md).

- [HANDOFF-S234-EP1-Entity-Face](log/handoffs/HANDOFF-S234-EP1-Entity-Face.md) — EP1 face build (pairs with the Entity-Face plan)
- [HANDOFF-S266-Pocket-Orbit-Pomodoro](log/handoffs/HANDOFF-S266-Pocket-Orbit-Pomodoro.md): Pocket after S266 (gyro face with heading hold and spin reactions, ring in every view, W5 Orbit settings, merged onto new-horizons, third_party/); next Orbit v2, Applets + Pomodoro, W6 BSP walkthrough, SDK refactor
- [HANDOFF-S264-Pocket-Capture-W4-Face](log/handoffs/done/HANDOFF-S264-Pocket-Capture-W4-Face.md) (done S265; S265 handoff done S266)
- [HANDOFF-S252-Pocket-Settings-Orientation-Clean-Room](log/handoffs/done/HANDOFF-S252-Pocket-Settings-Orientation-Clean-Room.md) (done S254/S264): settings composited; clean room continues in HANDOFF-S264
- [HANDOFF-S251-Pocket-Entity-60fps](log/handoffs/done/HANDOFF-S251-Pocket-Entity-60fps.md) (done S252): Pocket entity from ~20 to 60 fps idle
- [HANDOFF-S250-Pocket-Entity-Port-Phase1](log/handoffs/done/HANDOFF-S250-Pocket-Entity-Port-Phase1.md) — done S251: Phase 0 bench, Phase 1 renderer on device
- [HANDOFF-S236-OS-ISO-VM-Run](log/handoffs/HANDOFF-S236-OS-ISO-VM-Run.md) — branded ISO VM run recipe + leftover items
- [HANDOFF-FCC-Free-Claude-Code](log/handoffs/HANDOFF-FCC-Free-Claude-Code.md) — FCC LiteLLM proxy tuning
- [RaBbLE-Voice-Phase2-HANDOFF](log/handoffs/RaBbLE-Voice-Phase2-HANDOFF.md) — voice phase 2 (pre-vocoder-v4; check before resuming)

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
- [EP1-Liminal-Experience-Plan](log/plans/done/EP1-Liminal-Experience-Plan.md) — S190 Genesis passage (retired S203, frozen in Chrysalis)
- [NeBuLA-Studio-Plan](log/plans/done/NeBuLA-Studio-Plan.md) — S198 WYSIWYG page builder (built)
- [OS-Dolphin-Grey-Text](log/plans/done/OS-Dolphin-Grey-Text.md) — KDE grey text (resolved S201)
- [Collective-Architecture-Audit-Plan](log/plans/done/Collective-Architecture-Audit-Plan.md) — S192 plan for the S193 audit
- [HANDOFF-S203-B10-Cloudflare-Token](log/handoffs/done/HANDOFF-S203-B10-Cloudflare-Token.md) — CF token mint (B-10 resolved S206)
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
- [RaBbLE-Personality](RaBbLE/Ethos/RaBbLE-Personality.md) — core character traits and how they show in behavior, speech, design
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
