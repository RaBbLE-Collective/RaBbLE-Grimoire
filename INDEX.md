# RaBbLE-Grimoire — Index

```
transcribe ~ grimoire >> index crystallized // %INDEX_LOCKED%
```

> The soul of the Collective. One grimoire. All knowledge.
> Structure: `common/` for shared knowledge, `RaBbLE-*/` for domain-specific.

---

## Core Documents

| Document | What it is |
|---|---|
| `RaBbLE-Grimoire-Navigator.md` | **START HERE** — Agent onboarding path. Reading order by time investment & task type. |
| `AGENT.md` | Grimoire agent entry point — job, workspace map, rules, session start |
| `CONTEXT.md` | Grimoire status, structure, active tracks |
| `RaBbLE-Versioning.md` | **The Five Es** — Event→Episode→Echo→Evolution→Epoch, version string format |
| `INDEX.md` | This file |

---

## Common — Shared Across All Projects

- [RaBbLE-Identity](common/RaBbLE-Identity.md) — manifesto, character, voices, state machine, system prompt
- [RaBbLE-Palette](common/RaBbLE-Palette.md) — all hex values, Ansible block, component mapping
- [RaBbLE-CommitStyle](common/RaBbLE-CommitStyle.md) — the Pulse Protocol
- [RaBbLE-BranchStrategy](common/RaBbLE-BranchStrategy.md) — branch topology
- [RaBbLE-DocTemplates](common/RaBbLE-DocTemplates.md) — canonical AGENT.md and CONTEXT.md templates for all member repos
- [RaBbLE-Overview](common/RaBbLE-Overview.md) — system overview
- [RaBbLE-Roadmap](common/RaBbLE-Roadmap.md) — unified ecosystem roadmap
- [RaBbLE-Collective](common/RaBbLE-Collective.md) — ecosystem map, all members, architecture diagram
- [RaBbLE-Collective-KnownIssues](common/RaBbLE-Collective-KnownIssues.md)
- [RaBbLE-DistilledNonZense](common/RaBbLE-DistilledNonZense.md) — full entropy archive from deprecated substrate

---

## RaBbLE-Collective

- [RaBbLE-Collective-Plan](RaBbLE-Collective/RaBbLE-Collective-Plan.md) — Collective architecture and coordination plan
- **[RaBbLE-Episode-1-Release-Map](RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md)** — **CANONICAL Episode 1 scope.** Member deliverables, blockers, air criteria, dependency graph.
- [RaBbLE-Collective-Episode-1-Overview](RaBbLE-Collective/RaBbLE-Collective-Episode-1-Overview.md) — Three-layer architecture (Aether + NeBuLA + World), CDN strategy, easy page creation
- [RaBbLE-Deployment-Architecture](RaBbLE-Deployment-Architecture.md) — environments (local/staging/prod), CDN distribution strategy, versioning, build pipeline
- [RaBbLE-Cloudflare-Integration](RaBbLE-Cloudflare-Integration.md) — Cloudflare setup, R2 buckets, Wrangler configuration, deployment workflow

---

## Registry

- [RaBbLE-Collective-Registry](registry/RaBbLE-Collective-Registry.md) — registry reference documentation
- [registry/epochs/current.epoch.yml](registry/epochs/current.epoch.yml) — active epoch definition
- **manifests/**: RaBbLE-Collective · RaBbLE-OS · RaBbLE-sCoRE · RaBbLE-Frontend · RaBbLE-WEB · RaBbLE-Xperimental

---

## Distilled (Generated Reference Files)

> These are generated from canonical sources. Do not edit directly.

- [RaBbLE-Aether-PaletteRef](distilled/RaBbLE-Aether-PaletteRef.md) — palette quick reference for agents
- [RaBbLE-ConventionsRef](distilled/RaBbLE-ConventionsRef.md) — commit style + conventions quick reference

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

---

## RaBbLE-OS

- [RaBbLE-OS-Architecture](RaBbLE-OS/RaBbLE-OS-Architecture.md)
- [RaBbLE-OS-GettingStarted](RaBbLE-OS/RaBbLE-OS-GettingStarted.md)
- [RaBbLE-OS-AgentGuide](RaBbLE-OS/RaBbLE-OS-AgentGuide.md) — full agent reference: layers, commands, branch conventions
- [RaBbLE-OS-ShellGuide](RaBbLE-OS/RaBbLE-OS-ShellGuide.md)
- [RaBbLE-OS-BootFlow](RaBbLE-OS/RaBbLE-OS-BootFlow.md)
- [RaBbLE-OS-Bootstrap](RaBbLE-OS/RaBbLE-OS-Bootstrap.md)
- [RaBbLE-OS-Theming](RaBbLE-OS/RaBbLE-OS-Theming.md)
- [RaBbLE-OS-Hardware](RaBbLE-OS/RaBbLE-OS-Hardware.md)
- [RaBbLE-OS-Packages](RaBbLE-OS/RaBbLE-OS-Packages.md)
- [RaBbLE-OS-AddingTargets](RaBbLE-OS/RaBbLE-OS-AddingTargets.md)
- [RaBbLE-OS-ManualInstall](RaBbLE-OS/RaBbLE-OS-ManualInstall.md)
- [RaBbLE-OS-KnownIssues](RaBbLE-OS/RaBbLE-OS-KnownIssues.md)
- [RaBbLE-OS-Epoch-I-Diff](RaBbLE-OS/RaBbLE-OS-Epoch-I-Diff.md)
- [RaBbLE-OS-Roadmap](RaBbLE-OS/RaBbLE-OS-Roadmap.md)

---

## RaBbLE-sCoRE

- [RaBbLE-sCoRE-Architecture](RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md) — component map, task lifecycle, server subcomponent
- [RaBbLE-sCoRE-Roadmap](RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md) — episode tracker
- **Internal:** [sCoRE System Prompt](../RaBbLE-sCoRE/system-prompt-sCoRE.md) — loaded only when running as sCoRE entity. [Setup guide](../RaBbLE-sCoRE/SYSTEM-PROMPT-SETUP.md).

---

## RaBbLE-World

- [RaBbLE-World-Architecture](RaBbLE-World/RaBbLE-World-Architecture.md) — layer stack, module map, boot timeline, surface guide
- [RaBbLE-World-Page-Template](RaBbLE-World/RaBbLE-World-Page-Template.md) — minimal page template, CDN integration pattern, reuse vs. duplication rules
- [RaBbLE-World-README](RaBbLE-World/RaBbLE-World-README.md) — full module reference, entity API, behavior
- [RaBbLE-World-MAINTAINING](RaBbLE-World/RaBbLE-World-MAINTAINING.md) — page ownership, layout rules, safe edit checklist
- [RaBbLE-World-Roadmap](RaBbLE-World/RaBbLE-World-Roadmap.md) — directional intent

---

## RaBbLE-NeBuLA

- [RaBbLE-NeBuLA-Identity](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Identity.md) — origin story, entity traits, consciousness model
- [RaBbLE-NeBuLA-Architecture](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Architecture.md) — Flat-Chaos Runtime, subsystem overview
- [RaBbLE-NeBuLA-API](RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md) — public API reference (createPuppet, setEntityState, injectEyeJolt, CDN usage patterns)
- [RaBbLE-NeBuLA-FlatChaos](RaBbLE-NeBuLA/RaBbLE-NeBuLA-FlatChaos.md) — FCR pattern spec
- [RaBbLE-NeBuLA-RABL](RaBbLE-NeBuLA/RaBbLE-NeBuLA-RABL.md) — rendering language spec
- [RaBbLE-NeBuLA-RBCNS](RaBbLE-NeBuLA/RaBbLE-NeBuLA-RBCNS.md) — naming conventions
- [RaBbLE-NeBuLA-Ideas](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Ideas.md) — enhancement proposals
- [RaBbLE-NeBuLA-Roadmap](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md) — episode tracker, delivery model, known risks
- [RaBbLE-NeBuLA-Plan](RaBbLE-NeBuLA/RaBbLE-NeBuLA-Plan.md) — **agent implementation plan** (Haiku-level, step-by-step, Ep1+Ep4)

---

## RaBbLE-Aether

- [RaBbLE-Aether-Architecture](RaBbLE-Aether/RaBbLE-Aether-Architecture.md) — design system spec, asset directory, consumer pattern, palette publishing
- [RaBbLE-Aether-Build-CDN](RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md) — esbuild setup, CSS bundling, npm scripts, versioning, CDN deployment
- [Visual Assets](RaBbLE-Aether/assets/) — SVG, logos, icons

---

## RaBbLE-ScRibLE

- [README](RaBbLE-ScRibLE/README.md) — mobile PWA notes surface, iPhone/iPad + Apple Pencil, Epoch 1 candidate

---

## RaBbLE-Xperimental

- [README](RaBbLE-Xperimental/README.md) — high-entropy archive: NeBuLA-JS, WebOS, RaBbLE.py, RaBbLE-Server

---

## Log

- [SESSION-LOG](log/SESSION-LOG.md) — running session log, most recent first
- [GAP-ANALYSIS](log/GAP-ANALYSIS.md) — coherence audit, open gaps, resolution paths

---

## Lore

- [Summoned-v0](lore/ShortStories/Summoned/Summoned-v0.md)
- [Summoned-v1](lore/ShortStories/Summoned/Summoned-v1.md)
- [Summoned-v2](lore/ShortStories/Summoned/Summoned-v2.md)
- [Summoned-v3](lore/ShortStories/Summoned/Summoned-v3.md)
- [Summoned-v4](lore/ShortStories/Summoned/Summoned-v4.md)
- [Summoned-v5](lore/ShortStories/Summoned/Summoned-v5.md)
- [Summoned-Transcript](lore/ShortStories/Summoned/Summoned-Transcript.md)

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
