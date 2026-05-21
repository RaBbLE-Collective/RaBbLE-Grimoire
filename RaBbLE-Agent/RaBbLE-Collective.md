# RaBbLE-Collective.md — The Unified Ecosystem

```
transcribe ~ grimoire >> mapping the collective substrate // %COLLECTIVE_LOCKED%
```

> **One-line overview:** The RaBbLE Collective is the unified ecosystem of projects through which the RaBbLE entity inhabits diverse hardware, software, and creative substrates — all sharing a single identity, palette, and purpose.

> See `RaBbLE-Agent/RaBbLE-Identity.md` for entity identity and ethos.
> See `RaBbLE-Agent/RaBbLE-Palette.md` for the canonical color reference.
> See `RaBbLE-Versioning.md` for the Five Es versioning model.

---

## What the Collective Is

The RaBbLE Collective is not a monorepo, a framework, or a product suite.
It is a **unified project ecosystem** — a family of distinct but deeply interconnected substrates through which the RaBbLE entity lives, expresses itself, and becomes useful.

Each member of the Collective is an independent project. Each is also an organ of a single organism. They share:

- The same **entity** — RaBbLE is embedded throughout, not bolted on
- The same **visual language** — synthwave outrun palette, typography, and motion principles
- The same **design philosophy** — Low Entropy Directive, Anti-Assistant stance, Collective routing model
- The same **behavioral character** — RaBbLE-lang, BaBbLE, curiosity, directness, anti-sycophancy
- **Hardware and backend agnosticism** — the Collective is designed to exist across diverse platforms

---

## Collective Members

| Member | Role | Status |
|---|---|---|
| **RaBbLE-Grimoire** | Source of truth: identity, ethos, lore, conventions, registry, spells | Active |
| **RaBbLE-sCoRE** | Coordination server + web API (FastAPI). Intent → action engine, Railway-deployable. | Epoch 0 active |
| **RaBbLE-OS** | Fedora 43 → Hyprland WM. The substrate everything runs on. | Live, daily-driven |
| **RaBbLE-NeBuLA** | Frontend renderer / visual entity (Canvas2D + Flat-Chaos Runtime). | Active — Canvas2D complete |
| **RaBbLE-World** | Web presence + entity chat surface. joinrabble.world. | Active |
| **RaBbLE-Aether** | Visual design system and canonical asset library. CDN delivery. | Active — CSS bundle live |
| **RaBbLE-BaBbLE** | High-entropy intake workspace — concept art, prototypes, ideation, sketches. | Active — present intake |
| **RaBbLE-Xperimental** | Genesis archive — origin code from October 2025. Past, not present. | Genesis-archive |
| **RaBbLE-ScRibLE** | Mobile notes PWA (iPhone/iPad). | Defined — not started |
| **Memory member (TBD)** | Observation store, pattern extraction, retrieval. | Concept — Epoch 1 blocker |

---

### RaBbLE-OS
**The body. The substrate. The environment.**

An Ansible-driven Linux operating system built for a single purpose: to be the physical and digital environment through which RaBbLE inhabits a machine. Every layer — boot sequence, desktop compositor, shell, terminal palette — is an expression of the entity.

- Primary target: ASUS ProArt P16 H7606WV (x64)
- Future targets: diverse x64, aarch64, and SBC hardware
- Layer model: Base → Hardware → Boot Chain → Desktop → Apps → Entity
- See `RaBbLE-OS/RaBbLE-OS-Architecture.md`, `RaBbLE-OS/RaBbLE-OS-GettingStarted.md`, `RaBbLE-OS/RaBbLE-OS-Hardware.md`

---

### RaBbLE-sCoRE
**The nervous system. The agentic backbone.**

A web server that handles agentic workflows, routing intelligence between inference endpoints. It is the infrastructure layer that makes the Collective's intelligence accessible across all members — regardless of where they run or what model powers them.

**Capabilities:**
- Agentic workflow orchestration (multi-step, multi-agent tasks)
- Inference endpoint routing — local or remote, right model for right task
- Local endpoints: Ollama, llama.cpp, vLLM, FastFlowLM (NPU via XRT)
- Remote endpoints: Anthropic (Claude), Groq, OpenAI-compatible APIs
- OpenAI-compatible API surface for downstream consumers
- Model selection heuristic: cost, latency, capability, privacy requirements

**Design principle:** The web server is endpoint-agnostic. It does not care whether the model is running on an RTX 4060 in a local machine or a remote frontier API. The Collective routes transparently.

---

### RaBbLE-NeBuLA (Animated/Rendered Frontend)
**The face. The expression. The stage.**

The visual and interactive surface through which the RaBbLE entity expresses itself and users engage with the Collective. Not a standard chat interface or dashboard — a theatrical, animated environment, an extension of the entity's character into rendered space.

**Capabilities:**
- Direct interaction with RaBbLE agents and the entity's voice
- Access to Collective endpoints through a unified, characterful interface
- Animated and rendered — motion and visual expression are first-class
- Consistent with the synthwave outrun palette throughout
- Supports creative endeavors alongside technical ones

**Design principle:** The frontend is not a skin on a generic interface. It is an organ of RaBbLE. Its aesthetic is inseparable from its function.

---

## Cross-Cutting Principles

These apply to every Collective member without exception.

### The Palette Is Shared

All visual surfaces derive from `RaBbLE-Agent/RaBbLE-Palette.md`. Hot magenta `#ff2d78`,
electric cyan `#00f5ff`, soft violet `#bf5fff`, deep void `#0a0010` — the same neons,
the same void, everywhere. A user moving between the OS shell, the web server UI, and
the frontend should feel a single continuous environment.

### The Entity Is Consistent

RaBbLE's voice, character, and behavioral rules (see `RaBbLE-Agent/RaBbLE-Identity.md`) apply in
every context where the entity is present — terminal, web interface, agent response,
notification. The Collective does not have different personalities per platform.

### Hardware Diversity Is First-Class

RaBbLE does not belong to a single machine. The Collective is designed to exist across:
- High-performance x64 workstations and laptops
- aarch64 SBCs and embedded systems
- Any platform capable of running local inference or routing to remote endpoints

The OS layer's hardware role structure (`hardware/x64/`, `hardware/aarch64/`) reflects this. The web server and frontend are designed to run wherever the infrastructure allows.

### Backend Agnosticism

No member of the Collective is coupled to a specific inference provider. Local, remote,
GPU, NPU, CPU — all are valid. The routing layer handles the decision. The entity's
behavior is consistent regardless of what model powers it at any given moment.

### Low Entropy By Default

Every Collective project follows the Low Entropy Directive: reduce noise, distill signal,
document intent. Undocumented decisions are stored entropy. The Grimoire is the compression
artifact that makes the Collective maintainable and reconstructable across time and hardware.

### Grimoire Is Consumed, Not Copied

Members reference the Grimoire as a dependency (submodule or published package).
They do not copy its documents into their own directories. When lore drifts in a member
repo, the Grimoire is authoritative.

---

## Collective Architecture (High Level)

```
┌─────────────────────────────────────────────────────────────────┐
│                      USER / CREATIVE INTENT                     │
├─────────────────────────────────────────────────────────────────┤
│              RABBLE-NEBULA (Animated / Rendered Frontend)        │
│     (Entity expression, agent interaction, creative surface)    │
├──────────────────────────────┬──────────────────────────────────┤
│        RABBLE-OS             │         RABBLE-sCoRE             │
│  (Substrate, environment,    │  (Intent → action, delegation,   │
│   entity embodiment, shell)  │   coordination engine)           │
├──────────────────────────────┼──────────────────────────────────┤
│    sCoRE/server/ (FastAPI)   │     Memory Member (TBD)          │
│  (HTTP API layer, LLM        │  (Observation, pattern,          │
│   routing, workflows)        │   retrieval, context)            │
├──────────────────────────────┴──────────────────────────────────┤
│                    INFERENCE LAYER                               │
│   Local: Ollama · llama.cpp · vLLM · FastFlowLM (NPU)          │
│   Remote: Anthropic · Groq · OpenAI-compatible                  │
├─────────────────────────────────────────────────────────────────┤
│                    HARDWARE SUBSTRATE                            │
│        x64 · aarch64 · SBC · diverse platforms                  │
└─────────────────────────────────────────────────────────────────┘
```

Each layer is independently deployable. The full stack is the Collective in complete expression.

---

## Core Decisions (Already Made)

- **Memory is its own member**, not a sCoRE responsibility.
- **Local-first.** Laptop is the dev substrate. Cloud is used deliberately, not by default.
- **Collective is registry + health, not coordinator.** Coordination lives in sCoRE.
- **Grimoire is consumed as a dependency** by other repos — not copy-pasted.
- **Chat is scaffolding.** Don't over-invest; it likely retires.
- **sCoRE delegates to Claude Code via subprocess first**, MCP later if friction warrants.

---

## Collective Membership Criteria

A project is a Collective member if:

1. **RaBbLE is embedded** — the entity's character, voice, or behavioral model is present
2. **The palette is honored** — visual surfaces derive from `RaBbLE-Agent/RaBbLE-Palette.md`
3. **The philosophy is followed** — Low Entropy Directive, Anti-Assistant stance
4. **It serves the ecosystem** — it makes the Collective more useful, expressive, or accessible

A project that uses RaBbLE's color palette but has no entity presence is a themed tool,
not a Collective member.

---

## Relationship to the Grimoire

The Grimoire is the Collective's memory layer — not just RaBbLE-OS documentation. As new Collective members mature, their architecture, decisions, and lore belong here.

**Current grimoire coverage:**
- RaBbLE-OS: fully documented
- RaBbLE Web Server: architecture pending (Phase 2)
- RaBbLE Frontend: architecture pending (Phase 2+)

As each member stabilizes, its own grimoire section (or linked sub-grimoire) should be established.

---

## Future Collective Shape

The Collective is designed to grow. Anticipated expansions:

- **RaBbLE Mobile** — entity presence on mobile hardware substrates
- **RaBbLE CLI** — a standalone shell-native Collective entry point
- **RaBbLE MCP Layer** — Model Context Protocol servers exposing Collective state to agents
- **External Collective nodes** — forks and divergents that extend the lineage (see `RaBbLE-Agent/RaBbLE-Identity.md` — On Forking)

The Collective is not closed. New members cohere when the conditions are right.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-04-28 | Initial Collective document — ecosystem mapped |

---

```
transcribe ~ grimoire >> collective crystallized, ecosystem mapped // %COLLECTIVE_LOCKED%
```
