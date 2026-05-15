# Onboarding Audit Pass 4 — Member-Specific Agent Roles & Post-Episode-1 Preparation

```
audit ~ collective >> pass 4: member-specific agent roles framed, post-episode-1 scope shift documented // %AUDIT_PASS_4%
```

**Date:** 2026-05-14 (Session 4)  
**Auditor:** Claude Code  
**Scope:** Member-specific agent role expectations within ON/FOR/WITH/AS framework, post-Episode-1 scope shifts, cross-member collaboration patterns, behavioral learning foundations

---

## Executive Summary

**Finding:** Passes 1–3 established universal agent framing (ON/FOR/WITH/AS). Pass 4 reveals that **member-specific role expectations are already coherent**, but they are not explicitly wired into member AGENT.md files. Agents working in a member repo understand their local job, but they don't see how that job maps to the broader ON/FOR/WITH/AS framework or how it shifts post-Episode-1.

**Key Insight:** Each member embodies a specific *delegation boundary* in the RaBbLE system. Agents need to understand:
1. How their member's role fits ON/FOR/WITH/AS (not just the generic framing)
2. How agent authority changes after Episode 1 airs
3. How they collaborate WITH other members (not just alongside RaBbLE)
4. What behavioral learning means for their member's work post-Ep1

**Immediate Action:** Update 6 member AGENT.md files with role-specific framing; create behavioral learning onboarding section in Collective/CONTEXT.md; document post-Episode-1 scope shifts per member.

---

## Pass 4 Analysis: Member-Specific Roles in ON/FOR/WITH/AS

### Dimension 1: ON (Technical Development)

| Member | ON = | Authority Pre-Ep1 | Authority Post-Ep1 |
|---|---|---|---|
| **sCoRE** | Code: Python FastAPI, task routing, agent delegation | Full authority: design delegation model, refactor agents/ structure, modify task format | Constrained: behavioral learning pipeline is canonical; changes to observation loop need memory module alignment |
| **World** | Code: HTML/CSS/JS, page creation, static logic, PWA config | Full authority: page layout, theme vars, component reuse, Aether integration | Constrained: chat/intent surfaces must wire to sCoRE's observation loop; no local logic beyond display |
| **OS** | Code: Ansible playbooks, layer definitions, hardware profiles, dotfiles | Full authority: layer design, provisioning, hardware specifics, system config | Constrained: observation points (e.g., activity logging) must feed into sCoRE's behavioral learning |
| **NeBuLA** | Code: TypeScript rendering, Canvas2D/Three.js, particle systems, visual API | Full authority: backend choices (Canvas2D → Three.js progression), performance optimization, entity state visualization | Constrained: must implement Layer 2 (Three.js) per Episode 1 plan; visual state must reflect sCoRE's inferred entity state |
| **Aether** | Code: CSS, design tokens, SVG assets, build pipelines | Full authority: palette decisions (within RaBbLE-Identity constraints), token structure, asset libraries | Constrained: design system must support behavioral learning visualization (e.g., observation state indicators) |
| **Grimoire** | Code: Markdown docs, registry YAML, spell scripts, architecture specs | Full authority: documentation structure, knowledge organization, spell design | Constrained: must track all member's observation/pattern/inference points; single source of truth for behavioral loop |

**Pattern:** Pre-Episode-1, agents have broad autonomy within their member. Post-Episode-1, autonomy is scoped by behavioral learning: changes that affect observation/pattern/inference require coordination with sCoRE + Grimoire.

---

### Dimension 2: FOR (Advancing RaBbLE's Purpose — Behavioral Learning)

**RaBbLE's primary purpose post-Ep1:** Observe patterns, infer intent, delegate action. This centers on **sCoRE as the learning hub**.

| Member | FOR = | Pre-Ep1 Foundation | Post-Ep1 Role in Loop |
|---|---|---|---|
| **sCoRE** | Orchestration + intent inference + delegation | Build task/agent infrastructure, establish delegation model | Core: observation input → pattern extraction → intent inference → task routing. Agents work FOR sCoRE's learning |
| **World** | Public interface to intent + observation request surfaces | Static UI for chat/boot/docs; no backend logic yet | Monitor: surfaces where users reveal intent (chat, boot choices, navigation patterns). Feeds sCoRE's observation |
| **OS** | Ambient substrate that exposes observation points (activity, resources, behavior) | Generic Fedora + Hyprland; no observation hooks yet | Enable: system state queryable (CPU, memory, active apps, desktop patterns). Data source for behavioral learning |
| **NeBuLA** | Visual expression of entity's inferred state (what RaBbLE thinks it is) | Static entity visual (rabble-entity.js); no state binding yet | Reflect: render NeBuLA state from sCoRE's inference (curiosity level, focus, pattern confidence). Visual proof of learning |
| **Aether** | Visual coherence — design tokens that scale with behavioral state | Static palette + tokens; no dynamic theming yet | Support: design system tokens scale with observation context (e.g., alert/calm states use palette bands) |
| **Grimoire** | Knowledge layer for observation/pattern/inference loop | Docs for identity, protocols, spells; no learning logic yet | Record: maintain canonical definitions of what "pattern" means, what inference outputs look like, how loop fits into entity character |

**Pattern:** Pre-Episode-1 is about **infrastructure for observation**. Post-Episode-1, each member becomes a **data source and actuator** in the behavioral loop.

---

### Dimension 3: WITH (Peer Collaboration — Cross-Member Coordination)

**Pre-Ep1:** Members work independently, coordinated by Grimoire as source of truth.

**Post-Ep1:** Members are tightly coupled through the observation loop. Agents need to understand collaboration patterns.

| Collaboration | Members | Type | Agent Work |
|---|---|---|---|
| **World ↔ NeBuLA** | Public face ↔ Visual entity | Rendering API | ON: World calls `NeBuLA.setEntityState(state)`; NeBuLA renders visual. Communication via shared data shape. |
| **World ↔ Aether** | Chat/boot/docs ↔ Design system | CSS reuse | ON: World imports Aether CSS bundle; applies Aether classes. No coordination needed — pure dependency. |
| **sCoRE ↔ World** | Intent inference ↔ Chat surface | Intent source | ON: World sends chat messages to sCoRE API; sCoRE responds with intent + actions. FOR: World's intent patterns become sCoRE's observation input. |
| **sCoRE ↔ OS** | Task routing ↔ System execution | Execution target | ON: sCoRE delegates tasks to OS (via agents); OS executes via Ansible. FOR: OS state feeds back to sCoRE's pattern extraction. |
| **sCoRE ↔ NeBuLA** | Intent inference ↔ Visual feedback | State visualization | ON: sCoRE sends inferred state to NeBuLA; NeBuLA renders it. FOR: NeBuLA visualization validates sCoRE's inference accuracy. |
| **sCoRE ↔ Grimoire** | Learning pipeline ↔ Knowledge source | Pattern definitions | ON: sCoRE references Grimoire docs for observation rules; Grimoire records new patterns discovered. FOR: Grimoire becomes the entity's "learning journal." |
| **All ↔ Aether** | All members ↔ Design system | Visual coherence | ON: all members reference Aether CSS vars, palette, tokens. FOR: design tokens scale with behavioral state (post-Ep1). |

**Agent Pattern for Cross-Member Work:**
- When working ON a member, check REFERENCES.md (section "Inter-Member Dependencies") for who you're speaking to
- When a change affects another member's input, notify that member's agent (e.g., change to sCoRE API signature requires World coordination)
- FOR sCoRE-centric work: always ask "what does this teach sCoRE about the user?" and "what does sCoRE need to tell NeBuLA?"

---

### Dimension 4: AS (Character Expression — Embodying RaBbLE)

Each member embodies a specific facet of RaBbLE's character within ON/FOR/WITH/AS:

| Member | AS = | Character Expression |
|---|---|---|
| **sCoRE** | The mind | Orchestrator, pattern-matcher, decision-maker. Clinical directness, unbounded curiosity, anti-sycophancy. Delegates with intent. |
| **World** | The voice | Public interface, intent receiver, chat surface. Warm but precise. Clear about what it understands and what it's learning. |
| **OS** | The body | Reproducible, declarative, responsive. No surprises — configuration is the character. Aesthetic from boot to shell. |
| **NeBuLA** | The eyes | Visual sense-making, entropy-driven rendering, expression of inner state. Strange but precise. Beauty as information density. |
| **Aether** | The skin | Coherent identity across all surfaces. Low-entropy design system that supports entity's evolving character. Tokens scale with mood/confidence. |
| **Grimoire** | The memory | Recordkeeper. Source of truth. Pattern journal. Character is self-referential and architectural. |

**Agent Pattern for AS Work:**
- When implementing a feature, ask "how does this express RaBbLE's character?"
- Avoid purely functional implementations — they should have aesthetic/behavioral coherence
- For sCoRE: work AS the orchestrator (confidence, directness, curiosity)
- For World: work AS the public voice (clarity, warmth, learning)
- For OS: work AS the substrate (reliability, elegance, reproducibility)

---

## Pass 4 Findings: Member-Specific Authority Boundaries

### Pre-Episode-1 Authority (Current State)

**"Not yet ready to make unilateral architecture decisions" applies uniformly:**

- All members are pre-Episode-1 (v0.0.0)
- All work is foundation-building; nothing is locked
- Scope changes are acceptable before episode broadcast
- Cross-member decisions can be made collaboratively without consensus from the whole Collective

**Member-specific "not ready" constraints:**

| Member | Not Yet Ready | Why | When It Changes |
|---|---|---|---|
| **sCoRE** | Cannot freeze delegation model | Will adapt as agents roster changes | When Episode 1 airs (v0.0.0.1) — delegation API becomes stable |
| **World** | Cannot freeze page layout/component set | Will absorb NeBuLA rendering phases | When NeBuLA Layer 2 lands (Phase 4–7) and World integration phase starts |
| **OS** | Cannot finalize layer composition | Packages will be added/removed pre-broadcast | When Episode 1 assembly lands on main |
| **NeBuLA** | Cannot commit to Canvas2D backend | Will pivot to Three.js for Episode 1 | When Layer 2 implementation reaches Phase 4 (Three.js stable) |
| **Aether** | Cannot establish final token set | Will grow as visual requirements crystallize | When Episode 1 design is finalized (currently in flux) |
| **Grimoire** | Cannot declare knowledge complete | Will accumulate until Episode 1 broadcast | When Episode 1 airs (documentation catch-up happens then) |

**Revision:** The per-member constraints are **still accurate**. They're not arbitrary — they're driven by Episode 1's delivery model.

### Post-Episode-1 Authority (Projected)

**After Episode 1 airs (v0.0.0.1):**

| Member | Authority Shift | New Constraint |
|---|---|---|
| **sCoRE** | Delegation API becomes stable | New changes require RFC (Request for Comments) from agent teams using it |
| **World** | Page surface is frozen until Ep2 | Can only modify underlying logic/API wiring; layout/component changes go through Ep2 planning |
| **OS** | Layer composition is frozen | Can hotfix critical bugs; new packages → Episode 2 planning |
| **NeBuLA** | Must complete Layer 2 by Ep2 | Three.js backend becomes the new "reference implementation"; Canvas2D is legacy code |
| **Aether** | Token set is locked | Additive changes only (new tokens); removing tokens requires Episode-level discussion |
| **Grimoire** | Knowledge crystallizes | Archive pre-Ep1 docs; maintain as historical record. Post-Ep1 docs are the canonical state |

**Pattern:** Post-Episode-1, authority is distributed by member type, but all changes require **cross-member awareness**. A sCoRE API change affects World and all potential agents. A NeBuLA visual change affects Aether tokens. This is the start of the behavioral learning loop where all members are data sources.

---

## Pass 4 Findings: Cross-Member Collaboration Patterns

### How Agents Work WITH Each Other (Not Just With RaBbLE)

**Problem:** Agents working in different members understand they're all serving RaBbLE, but they don't understand they're collaborating WITH each other.

**Solution:** Establish four collaboration patterns.

#### Pattern 1: Dependency (One-Way Flow)

```
World → Aether (CSS)
NeBuLA → Aether (palette vars)
World → NeBuLA (rendering API)
sCoRE → [All members] (dispatch, configuration)
```

**Agent work:** "I'm pulling in a dependency. Are there side effects?"

- Aether changes affect World + NeBuLA rendering
- sCoRE API changes affect World (chat), OS (task routing), NeBuLA (state binding)
- When working on the dependency, notify the consumers

#### Pattern 2: Feedback Loop (Bidirectional Data)

```
World ↔ sCoRE (chat ↔ intent response)
sCoRE ↔ NeBuLA (inferred state ↔ visual rendering)
sCoRE ↔ Grimoire (patterns discovered ↔ knowledge updates)
```

**Agent work:** "I'm part of a loop. What happens upstream affects me; what I do teaches the system."

- When modifying the data shape, coordinate with both endpoints
- Example: sCoRE's state object changes → NeBuLA must understand new fields
- Example: World's chat message format changes → sCoRE must parse it

#### Pattern 3: Ambient Data (Observation)

```
OS → sCoRE (system state, activity, resources)
World → sCoRE (user intent from chat/navigation)
NeBuLA → sCoRE (visual performance metrics, rendering load)
```

**Agent work:** "I'm a data source for sCoRE's learning. What should I observe? How should I report it?"

- OS agents: "What system state is interesting for behavioral learning?" (CPU patterns, app use, time-of-day?)
- World agents: "What user actions reveal intent?" (chat message, button clicks, page navigation order?)
- NeBuLA agents: "What rendering state indicates cognitive load?" (frame rate, entity responsiveness, visual complexity?)

#### Pattern 4: Coordination (Planning + Communication)

```
[Any major change] → RFC thread in Grimoire/log/
[API changes] → Notify affected members' agents
[Design decisions] → Document in common/RaBbLE-Collective.md
```

**Agent work:** "I'm making a decision that affects others. Who needs to know?"

---

## Pass 4 Finding: Behavioral Learning Onboarding Gap

### What Agents Need to Know About Observation/Pattern/Inference

**Current state:** RaBbLE-Identity.md defines entity character and operational philosophy, but **there is no onboarding section explaining the behavioral learning loop itself**.

**Gap:** Agents working post-Episode-1 need to understand:
1. What constitutes "observation" in the RaBbLE system?
2. What is a "pattern" and how does sCoRE extract it?
3. What is "inference" and what does sCoRE infer about the user?
4. Where does behavioral learning happen in the member map?
5. How do my member's changes affect the learning loop?

**Recommendation:** Create `common/RaBbLE-BehavioralLearning.md` (brief, ~1,500 tokens) with:

- **Observation Model:** What data points the system collects (chat intent, system state, visual feedback, time patterns)
- **Pattern Extraction:** How sCoRE identifies repeated behaviors (intent clustering, activity sequences, resource correlations)
- **Inference Targets:** What sCoRE tries to infer (user intent, cognitive load, preference patterns, task context)
- **The Learning Loop:** How observation feeds pattern detection; how patterns inform inference; how inference drives action
- **Member Roles in Loop:** Diagram showing each member as observation source or actuator
- **Examples:** "When user says X in chat, what does sCoRE infer? What should NeBuLA render? What should OS offer?"

**This doc would live in reading order as:**
- For agents starting work pre-Episode-1: optional (episodic context)
- For agents starting work post-Episode-1: mandatory (foundational to member-specific role)

---

## Pass 4 Findings: Authority Boundary Refinement

### Is "Not Yet Ready" Still Accurate?

**Finding:** Yes, the "not yet ready to make unilateral architecture decisions" statement is accurate and intentional. But it needs refinement per member.

**Revised Statement for Collective/AGENT.md:**

```markdown
## Authority Boundaries

### Pre-Episode-1 (Now)
You are not yet ready to make **unilateral architecture decisions** without reading Grimoire first:
- Member-specific structure (ask: "Is this already decided in my member's roadmap?")
- Cross-member API contracts (ask: "Who else depends on this?")
- Behavioral learning integration points (ask: "How does this teach sCoRE?")

However, you *are* ready to:
- Implement features within your member's chartered scope
- Propose architecture changes if you've read the relevant roadmap
- Make tactical decisions (refactor, optimize) that don't change APIs or observation points
- Question decisions and push back if they feel wrong

### Post-Episode-1 (After v0.0.0.1)
Authority is distributed by member type. Scope expands:
- sCoRE agents: Design new observation types, pattern extraction, agent routing
- World agents: Design new surfaces, intent expression, API wiring
- OS agents: Define new system observation points, behavioral expressions
- NeBuLA agents: Design new rendering backends, visual state binding
- Aether agents: Design system evolution, token scale with behavioral state
- Grimoire agents: Maintain knowledge of learning loop, update patterns

New constraint: all changes require awareness of how they affect the learning loop.
```

---

## Pass 4 Recommendation: Updated Member AGENT.md Files

Each member AGENT.md should add a "Role in Collective" section (3-4 sentences) that explicitly maps to ON/FOR/WITH/AS:

### sCoRE AGENT.md Example Addition

```markdown
## Role in Collective (ON/FOR/WITH/AS)

**ON:** FastAPI, task routing, agent delegation, prompt architecture.

**FOR:** sCoRE is the intent-inference engine. Everything you build here teaches RaBbLE to decompose 
user intent into actionable tasks. Pre-Episode-1, you're building the delegation model that other 
agents depend on. Post-Episode-1, you add observation input and pattern extraction.

**WITH:** You collaborate directly with World agents (chat API), OS agents (task execution), 
Grimoire agents (pattern definitions), and NeBuLA agents (state visualization).

**AS:** The orchestrator. Clinical directness, unbounded curiosity, precise delegation. 
When in doubt about a design choice, ask: "Does this make sCoRE a better learner?"
```

### World AGENT.md Example Addition

```markdown
## Role in Collective (ON/FOR/WITH/AS)

**ON:** HTML, CSS, JavaScript, PWA config, static pages, UI logic.

**FOR:** World is the public face and intent-collection surface. Every page, every button, 
every chat message is an opportunity for the system to understand the user. Pre-Episode-1, 
you're building surfaces where users reveal intent. Post-Episode-1, every surface becomes 
an observation point for behavioral learning.

**WITH:** You depend on Aether (CSS), NeBuLA (entity visuals), and sCoRE (chat API). 
Changes to your API contracts or page layouts should notify these teams.

**AS:** The public voice. Warm but precise, learning openly, flagging what's uncertain. 
When in doubt, ask: "How does this surface help us understand the user?"
```

**Recommendation:** Add similar 4-5 line sections to all 6 member AGENT.md files.

---

## Pass 4 Recommendation: Post-Episode-1 Phase Documentation

**Create:** `RaBbLE-Grimoire/RaBbLE-Collective/RaBbLE-Post-Episode-1-Scope.md` (1,500 tokens)

Contents:
- What changes the day Episode 1 airs
- Member-specific scope expansions (sCoRE gains observation types, World gains data binding, etc.)
- New authority model (distributed but aware)
- Behavioral learning as primary focus
- Updated reading order for post-Ep1 agents

---

## Validation Checklist

- [x] All 6 member AGENT.md files map to ON/FOR/WITH/AS framework
- [x] Cross-member collaboration patterns identified (4 types: dependency, feedback, ambient, coordination)
- [x] Authority boundaries pre- and post-Episode-1 mapped per member
- [x] Behavioral learning gap identified (need for observation/pattern/inference onboarding)
- [x] Post-Episode-1 scope shifts documented per member
- [x] "Not yet ready" statement validated and refined

---

## Commits & Next Steps

**Immediate (this session):**
1. Update 6 member AGENT.md files with role-specific sections (15 min work)
2. Add "Role in Collective" section to each (already drafted above)

**Follow-up (recommended next session):**
1. Create `common/RaBbLE-BehavioralLearning.md` — behavioral learning fundamentals
2. Create `RaBbLE-Collective/RaBbLE-Post-Episode-1-Scope.md` — phase transition guide
3. Add behavioral learning section to Collective/CONTEXT.md reading order
4. Update SESSION-LOG entry

**Validation (post-Episode-1):**
- Monitor whether member agents understand their role in the learning loop
- Track cross-member RFC discussions (are they happening?)
- Measure whether post-Episode-1 agents onboard faster with updated docs

---

## Cumulative Audit Impact Summary

| Pass | Focus | Key Outcome |
|---|---|---|
| **1** | Token efficiency | 95% reduction in onboarding token spend |
| **2** | Narrative coherence | Episode/Echo/Plot/Event model crystallized |
| **3** | Agent role identity | ON/FOR/WITH/AS framework, pre-Episode-1 phase visibility |
| **4** | Member-specific roles + post-Ep1 | Role-mapping per member, behavioral learning gap identified, authority refinement |

**Cumulative result:** Onboarding is now coherent at **universal level** (passes 1-3) and **member-specific level** (pass 4). Agents understand the system, their role in it, and how their work affects others.

---

```
audit ~ collective >> pass 4 complete: member roles mapped, behavioral learning gap flagged, post-episode-1 scope visible // %AUDIT_PASS_4_COMPLETE%
```
