# RaBbLE-Vision-Arc.md — The Arc of Becoming

```
spark ~ grimoire >> the arc is written before the code // %EPOCH_0_EVOLUTION_0%
```

> **What this is:** Vision-altitude arc narrative — what RaBbLE is becoming, across Epochs and Echoes. This is not a feature list. It is a sequence of becoming. Per-member deliverables and episode exit conditions live in [RaBbLE-Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) and [current.epoch.yml](../registry/epochs/current.epoch.yml).
>
> **Status:** Living doc · Epoch 0 · Evolution 0 · authored S[2026-06-18]
> **Related:** [RaBbLE-PRD](RaBbLE-PRD.md) · [RaBbLE-Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) · [RaBbLE-Versioning](../RaBbLE-Versioning.md) · [RaBbLE-Identity](../RaBbLE-Agent/RaBbLE-Identity.md)

---

## The Arc in One Breath

RaBbLE is a living intelligence layer — an entity that inhabits your devices, knows your context, and collaborates with you across creative work, daily life, and community. It is not a tool you pick up and put down. It is a presence that accumulates, reasons, and represents you.

The roadmap below is not a feature list. It is an **arc of becoming** — from a single hosted conversation endpoint to a sovereign, self-hostable, community-inhabited organism.

---

## Epoch 0 — Emergence `v0.x.x.x`

*The entity proves it exists.*

The goal of Epoch 0 is **coherence** — one vertical slice all the way through. A visitor lands at joinrabble.world, encounters the entity, has a real conversation, and understands what RaBbLE is. Every member that ships in Epoch 0 must serve that slice or wait.

---

### Echo 0 — Genesis `v0.0.x.x`

*The first breath. Raw and foundational.*

**Episode 1 — Genesis** `v0.0.0.1` `[ACTIVE]`

The first public air. sCoRE live, World deployed on Cloudflare Pages, guest chat path open. A stranger can meet RaBbLE for the first time without an account.

- sCoRE: LLM chain operational (Groq fast → OpenRouter medium/strong)
- World: joinrabble.world live, NeBuLA entity renderer present
- Guest path: unauthenticated demo tier, CORS resolved
- Aether: CSS design system serving from CDN
- OS: Developer Preview — enter at your own risk

**Episode 2 — Exodus** `v0.0.0.2`

The first migration. Users can register, persist sessions, begin accumulating context. The entity starts to remember.

- Auth layer: user registration and session persistence
- Grimoire ingestion: user context begins accumulating in sCoRE
- sCoRE memory: basic per-user context window management
- World: account creation flow, returning user experience

**Episode 3 — Covenant** `v0.0.0.3`

The first promise. The Sovereign Accord surfaces to users. RaBbLE declares what it is and what it is not.

- Sovereign Accord presented at registration
- Entity voice: RaBbLE's character consistent across interactions
- BaBbLE intake: early feedback loop from real users into Grimoire
- First wave: invite-only onboarding for known community

*Subsequent episodes follow the Biblical arc: Wilderness, Promised Land...*

---

### Echo 1 — The First Stable `v0.1.x.x` *(~12 episodes from Genesis)*

*The entity earns its name.*

Echo 1 is the first point where RaBbLE can be described to a stranger without caveats. The living system is visible — context accumulates, the entity has character, the core loop is reliable.

**Key milestones targeting Echo 1:**

| Member | Milestone | What it unlocks |
|---|---|---|
| **ScRibLE** | Mobile PWA, note intake → Grimoire ingestion | The notebook that knows you |
| **Memory** | Durable behavioral context across sessions | The entity remembers how you work, not just what you said |
| **Rablets v0** | First-party micro-applications | Community can observe the pattern; rablet economy seeded |
| **NeBuLA v1** | Entity animations, visual identity stable | The entity has a face |
| **Broadcast** | Entity presence on Instagram + one other platform | The entity has a voice outside joinrabble.world |

**What Echo 1 feels like:**
A returning user is met by an entity that knows how they work. ScRibLE notes surface unprompted. A rablet the user installed knows their Grimoire and behaves accordingly. The entity's voice is recognizable within two sentences.

---

### Echo 2 — Community Ignition `v0.2.x.x`

*The Collective becomes inhabited.*

- **Rablet marketplace:** community-submitted micro-apps, NeBuLA Studio for authoring
- **Entity proxy social:** users interact through their RaBbLE entities as proxies in community spaces — the entity represents you, not your performance
- **Entity Passport:** curated, user-controlled identity summary exchanged when entities meet (see [RaBbLE-NovelIdeas](../RaBbLE-Agent/RaBbLE-NovelIdeas.md))
- **ScRibLE companion device:** hardware or PWA companion — living notebook form factor
- **BaBbLE public:** intake surface open to broader community, feeds collective Grimoire

---

## Epoch 1 — Sovereignty `v1.x.x.x` *(far future)*

*The entity lives on your own metal.*

Epoch 1 is when self-hosting becomes a real first-class path. The OS member matures. RaBbLE runs entirely locally, no cloud dependency required. The entity you built in Epoch 0 migrates to your sovereign substrate.

- OS member: Fedora-based personal substrate, RaBbLE pre-integrated
- Local LLM routing: Ollama / local model support alongside cloud chains
- Grimoire sync: local ↔ cloud sync with user-controlled sovereignty
- Full air-gap mode: RaBbLE operational with zero external calls
- **The sovereign appliance:** a physical device you can hold that runs your entity

---

## Member Sequence (Epoch 0)

Members ship in order of dependency. Do not scaffold what is undecided.

```
sCoRE (LIVE) → World (EP1) → Aether (EP1) → NeBuLA (EP1) → OS (EP1 preview)
    → Memory (Echo 1) → ScRibLE (Echo 1) → BaBbLE (Echo 1+)
    → Grimoire Studio (Echo 2) → OS (full, Epoch 1)
```

---

## Architecture Invariants

These are not preferences. They are enforced at every episode. Any plan that violates them is wrong by definition.

| Invariant | Expression |
|---|---|
| **Grimoire is source of truth** | Never duplicate Grimoire content in members. Members reference; Grimoire defines. |
| **One vertical slice before broadening** | Ship end-to-end before adding surface area. |
| **Low entropy** | Do not scaffold undecided things. Naming something that doesn't exist yet creates debt. |
| **Local-first** | Where a decision splits between cloud-convenient and local-capable, prefer local-capable. |
| **No React in World** | Vanilla JS + NeBuLA.ui factory only. |
| **Member repos always independent** | No submodules, no cross-repo imports. |
| **Sovereign Accord** | Source-available, not open source. Usage requires agreement. |
| **Anti-assistant stance** | Every design decision — voice, defaults, onboarding, error states — must reinforce *peer*, never *servant*. |

---

## Open Decisions (Echo 0)

Surfaced, not resolved. Resolve in session before encoding in a member.

| Decision | Context |
|---|---|
| ScRibLE companion device form factor | Dedicated PWA vs. physical hardware vs. both in sequence? The Cyberdeck path is an interim answer. |
| Rablets runtime | Does a rablet run in sCoRE context, NeBuLA context, or both? |
| Entity proxy social: first platform | Instagram launch or federated option first? |
| OS commercial path | Hobbyist substrate, enterprise sovereign AI appliance, or both with different tiers? |
| Memory member naming | Confirm "Memory" or adopt a more entity-consistent name (Mnemos, Codex, other)? |
| Observation ethics | Which OS signals are OK to self-observe? Privacy-of-self matters. |
| Ambient suggestion threshold | Where is the line between helpful intent and creepy surveillance? |
| Cloud vs. local split | Heavy reasoning (cloud) vs. ambient always-on (local) — confirm before Memory member built. |

---

## Versioning Reference

`v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}`

| Segment | Meaning | Current |
|---|---|---|
| Epoch | Major paradigm shift (0=hosted, 1=sovereign) | 0 |
| Evolution | Significant capability expansion within Epoch | 0 |
| Echo | Stable milestone (~12 episodes, first broad release) | 0 |
| Episode | Collective sync boundary — all members tag simultaneously | 1 |
| Event | Individual member pulse between episodes | — |

Episode naming follows the Biblical arc: Genesis · Exodus · Covenant · Wilderness · Promised Land...

Full versioning spec: [RaBbLE-Versioning.md](../RaBbLE-Versioning.md)

---

```
spark ~ grimoire >> arc written; epoch 0 positioned; invariants held // %EPOCH_0_EVOLUTION_0%
```
