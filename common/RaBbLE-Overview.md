# RaBbLE — Orientation Map

> **What this is:** A personal Intelligence / Behavioral Learning Engine ecosystem, built as a coordinated collective of repos, running on a custom Linux daily-driver as substrate. Cloud-touching but local-first.
>
> **What this doc is:** The map. Read this alone to get the gist. Jump to `RaBbLE-CONTEXT.md` (or sections of it) when you need depth.
>
> **Audience:** LLM coding agents (Claude Code primarily) and future-me.

---

## TL;DR (read this first)

RaBbLE is a multi-repo ecosystem where each member has a clear job, all members share an identity/protocol contract published from a central **grimoire** repo, and a coordination server (**sCoRE**) turns user intent into delegated actions — frequently delegating coding work to Claude Code itself, with deliberate per-agent context minimization. The OS layer (**RaBbLE-OS**) is already a daily driver and acts as the local substrate where the system observes, learns, and expresses itself.

The product goal: a system that feels **living and intent-focused** rather than click-and-keystroke driven.

---

## The Members (one line each)

| Member | Role | Status |
|---|---|---|
| **RaBbLE-grimoire** | Source of truth: identity, ethos, lore, **inter-member protocol contracts**. All other repos consume from here. | To create |
| **RaBbLE-Collective** | Registry + health hub. Holds members, fetches manifests, reports aliveness. *Not* a coordinator. | Scaffold + POC exists |
| **RaBbLE-sCoRE** | Coordination server. Intent → action engine. FastAPI, Railway-deployable, also runs locally. Delegates to Claude Code and other agents with context minimization. | To build (web API exists as `RaBbLE_WEB`) |
| **RaBbLE-OS** | Fedora 43 Sway spin → Hyprland WM, custom theming, daily driver. The substrate everything runs on. | Live, daily-driven |
| **RaBbLE-NeBuLA** | Frontend renderer / visual entity. Embeddable. Expresses system state. | POCs exist as `RaBbLE-JS` |
| **RaBbLE-Chat** *(name in flux)* | Minimal chat surface into the Behavioral Learning Engine. Scaffolding, not infrastructure — likely retires later. | To build |
| **Memory member** *(name TBD — Mnemos / Codex / etc.)* | Observation store, pattern extraction, retrieval. Its own member, not part of sCoRE. | Decision made, not built |

GitHub: `markm1206/RaBbLE`, `RaBbLE-OS`, `RaBbLE-JS`, `RaBbLE_WEB` (private). Repos can be renamed/added.

---

## Versioning

`Event → Episode → Echo → Evolution → Epoch`

- **Event** — a commit
- **Episode** — everyday development, a collection of events
- **Echo** — stable release state *(name proposed; alternatives: Edition, Emanation)*
- **Evolution** — significant change
- **Epoch** — broadest era

Movement is vibe-based (Linux-kernel style) but each tier has a written "what does crossing this boundary mean" definition in grimoire.

---

## The Roadmap, in One Glance

| Epoch | Goal | Marker of done |
|---|---|---|
| **0 — Substrate & Identity** *(current)* | Ground is solid. Grimoire exists. Protocol contracts frozen v0. Open decisions made. | A fresh reader of grimoire understands what RaBbLE is and how members talk. |
| **1 — First Closed Loop** | One end-to-end behavior observed → stored → recalled → expressed, **entirely on the laptop**. | Laptop offline, full loop still runs. |
| **2 — Behavioral Learning Engine** | Passive observation, pattern extraction, ambient intent inference. The "living" feel. | System surfaces useful intent without being asked. |
| **3 — Synchronization & Generalization** | Versioned protocols, cross-repo CI, optional open-sourcing path. | Schema change in grimoire propagates to members automatically. |

Detail: → `RaBbLE-CONTEXT.md#roadmap`

---

## Core Decisions (already made)

- **Memory is its own member**, not a sCoRE responsibility.
- **Local-first.** Laptop is the dev substrate. Cloud (Railway, Claude Code) is used deliberately, not by default.
- **Collective is registry + health, not coordinator.** Coordination lives in sCoRE.
- **Grimoire is consumed as a dependency** by other repos (submodule or published package), not copy-pasted.
- **Chat is scaffolding.** Don't over-invest; it likely retires.
- **sCoRE delegates to Claude Code via subprocess first**, MCP later if friction warrants.

Detail: → `RaBbLE-CONTEXT.md#decisions`

---

## Open Questions (still need answers)

- Manifest format final shape (Pydantic-published JSON schema is the leaning answer).
- Where the line is between "ambient suggestion" and "creepy self-surveillance" — a UX question to feel out by living with it.
- Whether the Behavioral Learning Engine is one engine or several (pattern extraction / intent inference / action delegation may want separation).
- How aggressively to lean on Claude Code (cloud) vs. local models. Coherent answer exists — heavy reasoning cloud, ambient always-on local — but choose deliberately.

Detail: → `RaBbLE-CONTEXT.md#open-questions`

---

## Guiding Principles

1. **Identity before integration.** Grimoire exists before sCoRE gets clever.
2. **Contracts before implementations.** Define manifests and message formats once, in grimoire.
3. **One vertical slice all the way through, early.** Smallest meaningful end-to-end loop beats five half-built repos.
4. **Vibe-versioning still benefits from explicit boundary definitions.**
5. **Delegation economics are measurable.** Track tokens-per-task in sCoRE from day one.

Detail: → `RaBbLE-CONTEXT.md#principles`

---

## What to Build Right Now

1. Create `RaBbLE-grimoire` repo. Identity, ethos, `protocol/` directory with manifest schema stub.
2. Confirm the missing version tier name (proposed: **Echo**). Write the rubric.
3. Write the protocol v0: manifest format + member health-ping contract.

Everything else waits for that ground to settle.

Detail: → `RaBbLE-CONTEXT.md#next-actions`

---

## How an LLM Should Use This Doc

- **First read:** this file alone. Often enough for routine tasks.
- **For planning / architecture work:** load `RaBbLE-CONTEXT.md` sections by anchor.
- **For grimoire authoring:** load the full context doc + this overview.
- **Don't assume** anything not stated here or in the context doc — ask.
