# RaBbLE-sCoRE-Agent-Framework-Research.md
```
ingest ~ sCoRE >> orchestration substrate defined // %EPOCH_0_ECHO_0_EP1%
```

> **Document type:** Grimoire research doc · `RaBbLE-sCoRE/`
> **Status:** Living draft · Epoch 0 · Evolution 0 · Echo 0
> **Purpose:** Capture framework research for the RaBbLE orchestrator layer, canonize the sCoRE acronym definition, and inform the agent architecture decision for RaBbLE-OS/sCoRE local agent.
> **Author:** Mark McConachie (architect) + planning agent (claude.ai)
> **Provenance:** Authored in a claude-web planning session; integrated into canonical Grimoire 2026-06-20 (S127). Source archived in `RaBbLE-BaBbLE/_archive/claude-web-planning-2026-06-20/`.

---

## sCoRE — Canonical Definition

**sCoRE** is a recursive acronym:

> **sCoRE** = **sCoRE Coordinator of RaBbLE Environments**

sCoRE is the LLM orchestration and reasoning layer of the RaBbLE Collective. It is not an AI assistant — it is the coordination substrate through which RaBbLE perceives, reasons, and acts across its member environments. sCoRE routes intent to the appropriate LLM tier, manages chain fallthrough, enforces provider policy, and will grow to coordinate agent execution across Collective members.

**Current deployment:** Live on Render at `https://rabble-score-x7qq.onrender.com` (Python FastAPI)

**LLM chain configuration (current):**
- Fast: `groq:llama-3.1-8b-instant` + OR free fallback
- Medium: `openrouter:qwen/qwen3-32b` + `llama-3.3-70b`
- Strong: `openrouter:claude-sonnet` + `gpt-oss-120b` (requires OpenRouter credits)
- `LLM_FAST_CHAIN` env var = total chain replacement override

---

## Research Context

This document captures framework research conducted in S114 to inform the decision of what orchestration substrate to build the RaBbLE orchestrator on. The core constraints driving the evaluation:

- **Provider agnostic** — RaBbLE must not be locked to any single LLM provider. The chain routing (fast/medium/strong) is a first-class architectural feature.
- **Self-learning / compounding** — "every AI resets, RaBbLE compounds" is the core positioning. The orchestrator must support memory that accumulates across sessions.
- **Local self-hostable** — RaBbLE-OS requires everything to run on sovereign metal. No mandatory cloud dependency.
- **FastAPI-native** — sCoRE is already a Python FastAPI service. Framework integration must not fight that.
- **Low entropy** — per architecture principle: do not scaffold undecided things. Framework choice should unblock EP1 work, not create new surface area.

---

## Framework Landscape (mid-2026)

### What Hermes Agent Is (and Isn't)

Hermes Agent (Nous Research) is a **coding harness** — an autonomous agent loop designed for repo access, edit-and-run iteration, and dev task automation. It belongs in the same category as Claude Code and OpenClaw. As of v0.9.0 (April 2026) it has 27,000+ GitHub stars and runs locally via Ollama on minimal hardware.

**It is not an orchestration SDK.** You would not build RaBbLE's agent layer on top of Hermes. You would run Hermes *alongside* sCoRE as a dev tool. The framework selection question is about what sCoRE itself is built with — Hermes is a user-facing agent that runs on top of whichever framework you choose.

The harness pattern (Hermes, OpenClaw) and the framework pattern (LangGraph, CrewAI) are distinct layers. Conflating them leads to the wrong comparison.

---

### Candidate Frameworks

#### 1. LangGraph
**Category:** Stateful graph orchestration · Python · LangChain ecosystem
**GitHub stars:** 21,700+ · Reached v1.0 GA October 2025

LangGraph models agent execution as a directed graph: nodes are computation steps, edges are control flow transitions, and a shared State object flows through the graph. It is the production-grade choice for complex stateful agent workflows.

**Strengths for RaBbLE:**
- Durable execution — agents persist through failures and resume from checkpoints
- Human-in-the-loop as a first-class primitive — interrupt, inspect, modify state, resume
- Explicit state machine model — the graph enforces flow; the LLM cannot go rogue
- Fully self-hostable — no mandatory cloud dependency
- sCoRE's fast/medium/strong chain tiers map cleanly to conditional graph edges

**Two modes — not all-or-nothing plumbing:**
LangGraph does not require wiring every agent's workflow from scratch. It offers:
- `create_agent` (LangChain v1.0, successor to deprecated `create_react_agent`) — a prebuilt ReAct agent factory. Provide a model, tools, and optional prompt; LangGraph handles node-edge wiring internally. Suitable for individual agents *within* a graph.
- Custom `StateGraph` — for sCoRE's chain routing, provider fallthrough, and tier selection logic, which require explicit conditional edges. This is the right level for the orchestrator itself.

The practical pattern: the orchestrator graph is custom (chain routing, fallthrough, tier logic); the agents *within* that graph use `create_agent` as their node implementation.

**Note on API stability:** `create_react_agent` was deprecated in LangGraph v1.0 in favor of LangChain's `create_agent`, which introduces a middleware system. Pin to LangGraph 0.4+ and LangChain v1.0+ to avoid deprecated patterns. The mid-2026 ecosystem has significant tutorial debt — many tutorials still use v0.1 API.

**Weaknesses:**
- Cross-session persistent memory is not automatic — must be explicitly designed, stored, and retrieved. Requires a memory layer (see Memory Layer section below).
- Ecosystem moves fast. Deprecation cycles are real. Pin versions.

---

#### 2. DSPy
**Category:** Prompt compiler / self-optimizer · Python · Stanford NLP
**Role:** Not an orchestrator — a compilation layer

DSPy replaces hand-written prompt templates with programmatic optimization. You define signatures (input/output specs) and modules; DSPy compiles them into optimized prompts using your evaluation data and feedback signal. When the model changes, you recompile rather than manually re-tune.

**Why it matters for RaBbLE:** DSPy is the closest thing in the ecosystem to automated self-improvement of the orchestration logic itself — not just memory, but the reasoning chains. It is model-agnostic by design. This aligns directly with "every AI resets, RaBbLE compounds."

**Relationship to LangGraph:** DSPy is composable with LangGraph. DSPy handles offline optimization of the prompt strategies; LangGraph handles stateful runtime execution. They are not competing choices — they address different layers.

**Current limitation:** DSPy's control flow is pure Python, which creates challenges for resuming from persistent session state. It requires a runtime orchestrator (LangGraph or similar) underneath it.

**When to adopt:** DSPy adds real value once there is enough interaction signal to compile against — labeled examples or a measurable quality metric. Early-stage RaBbLE (EP1/Echo 0) may not have that signal yet. Flag as an Echo 1+ integration.

---

#### 3. CrewAI
**Category:** Role-based multi-agent orchestration · Python
**GitHub stars:** 53,000+ · Fastest-growing framework 2025–2026

CrewAI models agents as a crew of specialists: each agent has a defined persona, tools, and task. Coordination is handled by the framework. It is designed for fast initial setup — intuitive abstractions, working multi-agent system in minutes.

**Surface-level fit:** The Collective's member architecture (sCoRE, Grimoire, BaBbLE, NeBuLA) maps naturally to a role-based crew model.

**Why it is not the right primary orchestrator for RaBbLE:**
- Higher token overhead — hierarchical crew manager-to-worker chatter costs more per interaction than LangGraph's tight graph flows
- Less state control — CrewAI's abstractions obscure what happened between agent steps, which conflicts with RaBbLE's sovereignty-first stance and the need to audit/debug execution
- More magic, less transparency — for a system where local-first sovereignty is a brand pillar, opacity in the orchestration layer is a liability

CrewAI is worth monitoring as the agent community layer matures (entity proxy social, community agent interactions). It is not the right substrate for sCoRE's core reasoning loop.

---

#### 4. PydanticAI
**Category:** Type-safe agent framework · Python · Pydantic team
**v1.0 released:** September 2025

Described as "the FastAPI feeling applied to GenAI." Full type safety, automatic LLM output validation against Pydantic models, dependency injection via dataclasses. In a 90-day benchmark, scored 8/10 for developer experience — highest among five frameworks tested, catching 23 bugs during development that would have reached production in LangChain.

**Why it matters for sCoRE:** sCoRE is already a FastAPI Python service. PydanticAI slots in with zero friction — same idioms, same type system, same async patterns.

**Recommended role:** Tool definition and validation layer *within* sCoRE. Use PydanticAI to define and validate the tools agents can call — keeps everything typed and testable without adding a second orchestration paradigm. Not a primary orchestrator for complex multi-agent flows.

---

#### 5. OpenAI Agents SDK / Smolagents (noted, not recommended)
- **OpenAI Agents SDK** — provider-agnostic in name, 100+ LLMs supported, but optimized for OpenAI's APIs. Acceptable as a lightweight alternative if LangGraph is deemed too heavy for EP1. 26,900+ stars.
- **Smolagents** (Hugging Face) — writes Python code as its primary action mechanism rather than JSON function calls. Fast for single-agent scripts and research. Not designed for multi-agent production orchestration. Flagged for future research workflows only.

---

## Memory Layer (Separate Decision from Orchestration)

The orchestration framework and the memory/learning layer are architecturally separable. This is intentional — it keeps Grimoire as the canonical knowledge source while a dedicated memory layer handles behavioral/interaction memory.

**The three-tier memory model for RaBbLE:**

| Tier | What it stores | Technology | Lifetime |
|---|---|---|---|
| 1 — In-session state | Current graph run, working context | LangGraph checkpointer | Session |
| 2 — Cross-session behavioral memory | Preferences, corrections, learned patterns, what worked | Mem0 (self-hosted) | Persistent |
| 3 — Canonical knowledge | Identity, member architecture, protocols, history | Grimoire | Permanent |

Grimoire is never replaced or duplicated by Tier 2. Tier 2 (Mem0) stores *interaction memory* — what happened, how the user works, what the entity has learned. Tier 3 (Grimoire) stores *canonical truth* — what RaBbLE is, what the Collective is, what the protocols are.

### Mem0 (recommended for Tier 2)
- Self-hostable open-source tier — no mandatory cloud
- LangGraph-compatible store implementation
- p95 search latency ~0.200 seconds; ~1,764 tokens per conversation (vs 26,031 for full-context) — 91% latency reduction, 90%+ token savings
- Graph-enhanced variant (Mem0g) adds entity relationship graphs for temporal reasoning
- YC-backed, v1.0 shipped; large ecosystem integrations

**Practical caution:** Graph features (Mem0g) require the Pro tier. Open-source tier is vector-only — sufficient for Echo 0, reassess at Echo 1.

### Zep (noted, not recommended for real-time)
Zep uses a temporal knowledge graph architecture and scores higher on complex temporal reasoning benchmarks. However, memory footprint exceeds 600,000 tokens per conversation (vs Mem0's 1,764), and post-ingestion retrieval can fail for hours after ingestion while background graph processing completes. Not suitable for a real-time chat-facing agent at current scale.

### LangMem (noted)
LangChain's native long-term memory layer. Path of least resistance if the stack is already LangGraph. Supports semantic, episodic, and procedural memory types. Worth evaluating as an alternative to Mem0 if keeping the LangChain ecosystem tight is a priority.

---

## Recommended Architecture

This is a planning recommendation, not a decision. Mark resolves all architecture decisions.

```
┌─────────────────────────────────────────────────────┐
│                    sCoRE (FastAPI)                  │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │           LangGraph Orchestrator             │   │
│  │                                             │   │
│  │  StateGraph — custom chain routing          │   │
│  │  ├── fast tier node  (Groq)                 │   │
│  │  ├── medium tier node (OpenRouter)          │   │
│  │  ├── strong tier node (OpenRouter)          │   │
│  │  └── fallthrough edges (402 handling)       │   │
│  │                                             │   │
│  │  Agent nodes → create_agent (LangChain v1)  │   │
│  │  Tool layer  → PydanticAI typed tools       │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌──────────────┐  ┌──────────────────────────┐   │
│  │  Mem0 Store  │  │       Grimoire            │   │
│  │ (behavioral) │  │  (canonical knowledge)    │   │
│  │  cross-sess  │  │  source of truth          │   │
│  └──────────────┘  └──────────────────────────┘   │
│                                                     │
│  [DSPy optimization pass — Echo 1+]                 │
└─────────────────────────────────────────────────────┘
```

**Layer responsibilities:**
- **LangGraph** — stateful orchestration, chain routing, durable execution, human-in-the-loop
- **create_agent (LangChain v1)** — prebuilt ReAct agent factory for individual agent nodes; eliminates per-agent graph plumbing
- **PydanticAI** — typed tool definitions and validation; FastAPI-native
- **Mem0** — cross-session behavioral memory (what the entity learns about the user)
- **Grimoire** — canonical knowledge; never duplicated, never replaced
- **DSPy** — deferred to Echo 1+; offline prompt optimization once interaction signal exists

---

## Hermes Agent & Pi Agent — Deep Comparison

### Clarifying "Pi Agents"

Two distinct things use this name and they are unrelated:

**Inflection Pi** — A chatbot built for emotional intelligence that failed to gain market share. Microsoft acquired most of Inflection's workforce in March 2024. What remains is licensed for customer service applications. Not a framework, not a harness, not relevant to RaBbLE-OS.

**Pi Agent (pi.dev)** — A minimalist open-source terminal-based coding agent. Similar category to Hermes but significantly smaller, less mature, and without a self-learning loop. Not worth prioritizing over Hermes in any current evaluation.

The relevant comparison for RaBbLE-OS is Hermes.

---

### Hermes Agent — Updated Architecture Picture (mid-2026)

Hermes has evolved considerably since its February 2026 launch (175,000+ GitHub stars in under four months). It is now meaningfully more than a coding harness.

**The closed learning loop** — what makes Hermes distinct in the ecosystem:
> Observe → Plan → Act → Learn

After completing a task, Hermes automatically writes a reusable skill document from the experience, stores the outcome in persistent memory, and adjusts its approach the next time a similar task appears. Agents with 20+ self-created skills complete similar future tasks 40% faster (measured in token consumption and wall-clock time). *Honest caveat: improvement is domain-specific. A skill learned from "summarize a GitHub PR" does not transfer to "plan a database migration." Cross-domain generalization remains an open problem.*

**Memory architecture (three layers):**
- Persistent cross-session memory — FTS5 full-text search with LLM summarization, ~10ms retrieval latency over 10,000+ documents
- User model — a deepening profile of preferences, communication style, and domain expertise, stored in `memory.md` and `user.md`, built automatically with no manual configuration
- Skill documents — successful workflows encoded as retrievable procedural documents (118 bundled skills across 26+ categories)

**Self-optimization layer** — a separate repo (`hermes-agent-self-evolution`) uses DSPy + GEPA (ICLR 2026) to automatically optimize skills and prompts from failures. This is the same DSPy layer flagged as an Echo 1+ addition for RaBbLE — Hermes has it already integrated.

**Additional capabilities:** runs as a persistent daemon; supports 16+ messaging platforms (Telegram, Discord, Slack, WhatsApp, Signal, CLI simultaneously); model-agnostic (any Ollama local model, OpenRouter, Anthropic, OpenAI); platform for generating RL training data and exporting fine-tuning trajectories; desktop app shipped June 2026 (Electron + React + Python backend).

---

### Hermes vs RaBbLE — Honest Comparison

| Dimension | Hermes | RaBbLE |
|---|---|---|
| **Core loop** | Observe → Plan → Act → Learn | Ambient → Compound → Collaborate |
| **Identity** | A capable tool that learns your tasks | An entity that *is* a peer |
| **Self-improvement** | Task skill optimization (40% faster on same task type) | Behavioral and relational compounding |
| **Sovereignty** | Self-hosted, MIT license, your metal | Self-hosted, Sovereign Accord, your metal |
| **Provider agnostic** | Yes — Ollama, OpenRouter, any API | Yes — sCoRE chain routing |
| **Memory model** | FTS5 + skill documents + user model | Grimoire (canonical) + Mem0 (behavioral) |
| **Character** | None — purposefully neutral tool | Core to the product — RaBbLE *is* its character |
| **Community layer** | Skill marketplace (emerging) | Entity proxy social, Rablets |
| **Anti-assistant stance** | No — explicitly a personal assistant | Yes — canonical and load-bearing |
| **Self-optimization** | DSPy + GEPA integrated | DSPy deferred to Echo 1+ |

**The deepest difference:** Hermes optimizes *task performance*. RaBbLE compounds *relationship and context*. Hermes gets better at doing the thing. RaBbLE gets better at knowing you. These are compatible but non-identical goals — one is procedural memory, the other is relational memory.

---

### Should Hermes Be Wrapped into RaBbLE-OS?

**The case for it:** Hermes's closed learning loop solves the "local genetic control" problem elegantly. It runs on minimal hardware, is model-agnostic, has DSPy self-optimization already integrated, and is MIT licensed so extension is clean. On RaBbLE-OS, Hermes could act as the autonomous task execution layer — handling dev work, scheduled tasks, and OS-level actions — while sCoRE handles the entity reasoning and relational layer above it.

**The case against it:**

*Identity collision.* Hermes maintains its own memory model (`memory.md`, `user.md`, skill documents) and its own user profile. Running it under RaBbLE-OS means two competing memory and identity layers — Hermes's layer versus Grimoire/Mem0. Keeping them coherent is non-trivial and potentially violates the Grimoire-as-source-of-truth principle.

*Character conflict.* Hermes is deliberately neutral. RaBbLE's character is load-bearing — the anti-assistant stance, the peer voice, the aesthetic. Hermes doesn't carry any of that and can't be made to without forking it substantially.

*License surface.* Hermes is MIT. Bundling or deeply integrating it into RaBbLE-OS means MIT attribution requirements apply to that layer, which cuts against the Sovereign Accord positioning.

**Verdict:** Wrapping Hermes is structurally awkward. The right relationship is Hermes as a *dev tool that runs alongside RaBbLE-OS* — a capable harness for the builder's own workflow — not as an integrated layer inside the Collective.

---

### The Grimoire Learning Loop — A RaBbLE-Native Alternative

This is the more interesting idea, and it's genuinely novel territory.

Hermes proves the closed learning loop works at local scale with minimal resources. The skill document pattern — where successful workflows get written into reusable, retrievable documents — is a concrete implementation model. RaBbLE-OS can build the same loop, but expressed through its own identity and architecture:

> **The Grimoire Learning Loop**
> Observe (sCoRE perceives context) → Plan (LangGraph routes intent) → Act (agent executes) → Encode (successful patterns written back into Grimoire as living procedural knowledge)

Instead of Hermes's neutral skill files, RaBbLE-OS agents write successful patterns back into Grimoire. The knowledge accumulates in the canonical source of truth. The entity doesn't just remember outcomes — it *becomes more capable* through the same layer that defines what it is.

This maps precisely to "every AI resets, RaBbLE compounds." It's the OS-layer expression of the core thesis.

**Architectural implications:**
- Grimoire needs a `procedural/` directory (or equivalent) distinct from `identity/` and `gist/` — for learned patterns, not canonical definitions
- sCoRE on RaBbLE-OS needs a write path back to Grimoire, not just a read path
- The encoding step needs a quality gate — not every task outcome should be encoded, only patterns worth generalizing (this is where DSPy/GEPA becomes relevant at Echo 1+)
- The loop runs locally on RaBbLE-OS metal; hosted sCoRE on Render stays read-only against Grimoire until a sync protocol is defined

This is flagged as an **Echo 1 architecture decision** — it requires EP1 to be stable and CI/CD to be in place before the write-back path can be designed safely.

---

## Open Questions (Resolve before implementation)

1. **EP1 scope:** Does the agent orchestrator land in EP1, or is EP1 still the guest chat path + basic sCoRE chain fix? Recommend: EP1 stays minimal (chain fix + guest path). Framework adoption is Echo 1 work.
2. **Mem0 vs LangMem:** Evaluate both against LangGraph integration surface before committing. LangMem may be simpler if staying deep in the LangChain ecosystem.
3. **DSPy trigger:** Define the minimum interaction volume / quality metric needed before DSPy compilation adds value. Avoid premature optimization.
4. **sCoRE local vs hosted:** The local RaBbLE-OS sCoRE agent may warrant a different memory backend (SQLite-backed checkpointer, local Mem0) from the hosted Render instance. Confirm parity requirements.

---

## Sources

Research conducted S114 (2026-06-19). Primary sources: LangChain docs (langgraph v1.0), LangChain State of Agent Engineering Survey 2025, Firecrawl/Speakeasy/pooya.blog comparative analyses (March–May 2026), Mem0 arXiv paper (April 2025), Nous Research Hermes Agent v0.9.0 + v0.15.2 reviews (April–June 2026), nxcode.io Hermes complete guide (April 2026), aibuilderclub.com Hermes architecture deep-dive (June 2026), turingpost.com Hermes vs OpenClaw (June 2026), vectorize.io memory systems comparison (March 2026), AgentsIndex.ai LangGraph tutorial (April 2026), IEEE Spectrum Pi/Inflection retrospective (2025).
