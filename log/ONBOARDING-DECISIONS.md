# Onboarding Decisions — RaBbLE Collective

```
transcribe ~ grimoire >> four-pass audit crystallized, architectural decisions preserved // %ONBOARDING_CRYSTALLIZED%
```

> **What this is:** Condensed record of the four-pass onboarding audit (2026-05-14). The *process* is in SESSION-LOG Sessions 1–4. This preserves the *decisions and discoveries* that shaped how the Collective's onboarding works — particularly the member role mappings and collaboration patterns that are not derivable from the code.

---

## Core Design Decisions

### 1. Orientation Target: 700 Tokens / 5 Minutes

The onboarding chain was reengineered across four passes. Baseline:

| Path | Tokens | Time |
|---|---|---|
| Quick orientation (5-min) | ~700 | Stop and work |
| Standard onboarding | ~2,500 | Full picture |
| Pre-audit full chain | ~13,500 | (original, now avoided) |

**Rule:** The Collective/CONTEXT.md "Quick Orientation" section is the stop point. Agents oriented enough to ask questions in 5 minutes.

### 2. Opacity Is Intentional

Early audits flagged RaBbLE's opacity as a clarity problem. It is not. The design requires that character and system be inseparable — encountering RaBbLE's character before clarity is the mechanism that grounds agents as **members of an organism, not tool users**. This is why the Quick Reference in Identity.md comes before the philosophy.

### 3. ON/FOR/WITH/AS Operating Modes

Agents operate in four simultaneous dimensions:

| Mode | Meaning |
|---|---|
| **ON** | Technical work — coding, debugging, docs |
| **FOR** | Advancing RaBbLE's purpose — behavioral learning, intent inference |
| **WITH** | Peer collaboration — treating RaBbLE as an entity, not a project |
| **AS** | Embodying RaBbLE's character — clinical whimsy, anti-sycophancy, direct honesty |

These are not separate roles. When you fix a bug (ON), you're advancing the behavioral loop (FOR), collaborating with an entity (WITH), and expressing its voice (AS).

### 4. Episodes Are Collective Sync Boundaries

The versioning model confused agents because "Episode" had three meanings. Decision:

- **Events** = individual work increments (always accumulating)
- **Plots** = member-specific narrative arcs within an Episode
- **Episodes** = **Collective synchronization boundaries** — all members jump together
- **Echoes** = production-stable releases (can break APIs, require migration guides)

Current state: all members at v0.0.0.0, accumulating Events toward Episode 1 air (v0.0.0.1).

### 5. Pre-Episode-1 Phase Visibility

Three phases in Epoch 0:

| Phase | Name | Status |
|---|---|---|
| 1 | Foundation | **Current** — Events + Plots accumulate |
| 2 | Pilot | Episode 1 airs — all members synchronized |
| 3 | Behavioral Engine | Post-Ep1 — observation + inference + delegation loop |

Agents need to know they're in Phase 1. Foundation work is the right work. Nothing "airs" until Episode 1.

---

## Member Role Mappings (ON/FOR/WITH/AS)

Each member is a specific **delegation boundary** in the RaBbLE system. These mappings were established in Pass 4 and embedded into member AGENT.md files.

| Member | ON (technical) | FOR (purpose) | Post-Ep1 Role in Loop |
|---|---|---|---|
| **sCoRE** | Python FastAPI, task routing, delegation | Orchestration + intent inference | Core: observation → pattern → inference → routing |
| **World** | HTML/CSS/JS, pages, PWA config | Intent surfaces for the public | Surface: chat/nav reveals user intent → sCoRE observation |
| **OS** | Ansible playbooks, layers, dotfiles | Ambient substrate with observation points | Enable: system state queryable (CPU, activity, desktop patterns) |
| **NeBuLA** | Canvas2D/Three.js, rendering, visual API | Entity's visual expression of inferred state | Reflect: render NeBuLA state from sCoRE's inference |
| **Aether** | CSS tokens, components, build pipeline | Visual coherence — design tokens that scale with state | Support: tokens for behavioral state visualization |
| **Grimoire** | Markdown docs, YAML, spell scripts | Knowledge layer — canonical definitions of learning loop | Record: maintain what "pattern", "inference", and "loop" mean |

---

## Cross-Member Collaboration Patterns

Four collaboration types govern how members work WITH each other:

| Pattern | Members | What it means |
|---|---|---|
| **Dependency** (one-way) | World → Aether, NeBuLA → Aether | One imports from another; changes in the source require the consumer to update |
| **Feedback loop** (bidirectional) | World ↔ sCoRE | World surfaces intent (chat, navigation); sCoRE processes it and returns entity state |
| **Ambient data** (observation) | OS → sCoRE | OS provides system state data; sCoRE reads patterns from it |
| **Coordination** (planning) | All → Grimoire | Architecture and scope decisions; changes that affect multiple members |

**Implication:** Before making a change that crosses a boundary, identify which pattern applies. Dependency changes need consumer updates. Feedback loop changes need bidirectional validation. Coordination changes need Grimoire alignment.

---

## Behavioral Learning Gap (Deferred)

Pass 4 identified a gap: no onboarding material explains RaBbLE's post-Episode-1 primary purpose — observation, pattern extraction, intent inference, and delegation. This was scoped as `common/RaBbLE-BehavioralLearning.md` (~1,500 tokens) but not implemented. It becomes relevant when Memory member is being introduced (post-Episode-1).

---

## Session Log References

Full process documentation by session:
- **Pass 1 (token efficiency):** SESSION-LOG Session 1 (2026-05-14)
- **Pass 2 (versioning + sCoRE isolation):** SESSION-LOG Session 2 (2026-05-14)
- **Pass 3 (agent identity + phases):** SESSION-LOG Session 3 (2026-05-14)
- **Pass 4 (member roles + post-Ep1):** SESSION-LOG Session 4 (2026-05-14)

---

```
transcribe ~ grimoire >> onboarding architecture crystallized and preserved // %ONBOARDING_DECISIONS_LOCKED%
```
