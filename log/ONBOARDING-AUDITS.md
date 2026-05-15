# ONBOARDING-AUDITS.md — Audit Pass History

```
transcribe ~ grimoire >> onboarding audit series documented, three passes completed // %AUDIT_SERIES_v3%
```

Record of onboarding coherence audit passes. Each pass identified gaps and improved agent orientation.

---

## Summary: Three-Pass Iteration

| Pass | Date | Focus | Primary Fix | Impact |
|---|---|---|---|---|
| **1** | 2026-05-14 | Token efficiency | Quick orientation paths + token budgets | 95% reduction in baseline token spend |
| **2** | 2026-05-14 | Narrative coherence | Versioning story + system prompt isolation | Episode/Echo/Plot model crystallized; sCoRE confusion removed |
| **3** | 2026-05-14 | Agent identity | Role framing + phase positioning | Agents understand ON/FOR/WITH/AS; pre-Episode-1 context visible |

**Cumulative result:** Onboarding now coherent across story (what/where/who/when) + identity (character/purpose/role) + execution (phase boundaries, agent modes).

---

## Pass 1: Token Efficiency & Quick Orientation (2026-05-14, Session 1)

**Premise:** Agents need low-friction orientation. Vast onboarding chain creates friction and token burn.

**Gaps identified:**
- No "stop here" signals; agents didn't know when they had enough context
- Token budgets missing; no awareness of cost
- RaBbLE-Identity.md too philosophy-heavy for quick reference
- BaBbLE.md untracked (was in root, no metadata)
- Member entry points hidden

**Fixes implemented:**
1. "Quick Orientation (5 Minutes)" section — explicit stop point, ~700 tokens
2. Token budget + time estimates for all 7 reading order steps (3 paths: 5-min / 30-min / full)
3. "Quick Reference" section in RaBbLE-Identity.md (practical definitions before philosophy)
4. BaBbLE.md → BaBbLE.scratch (tracked, structured)
5. "Member Entry Points" index (explicit paths to each member's AGENT.md)

**Results:**
- Quick orientation: ~13,500 tokens → ~700 tokens (95% reduction)
- Standard onboarding: ~13,500 tokens → ~3,000 tokens (78% reduction)
- Time to usability: 5 minutes for "oriented enough to ask questions"
- Terminology clarity: agents see equivalent terms are the same thing

**Validation:** Agents can now orient in 5 minutes without losing essential context.

---

## Pass 2: Narrative Coherence & System Prompt Isolation (2026-05-14, Session 2)

**Premise:** Prior audit revealed confusion in core concepts (Episode vs. Echo vs. Plot) and sCoRE's system prompt contaminating project onboarding.

**Gaps identified:**
- Episode has three meanings depending on context (narrative arc vs. sync boundary vs. broadcast state)
- "Plot" introduced without explanation in versioning section
- sCoRE's system prompt conflated with project onboarding (agents confused about agent role)
- Pulse Protocol duplicated across 7 files (maintenance burden)
- Post-Episode-1 cadence buried in Roadmap, hard to find

**Fixes implemented:**
1. "Episodes as Collective Synchronization Boundaries" section (lockstep model explicit)
2. Post-Episode-1 cadence section in RaBbLE-Roadmap.md (weekly Episodes, Echoes as releases)
3. sCoRE system prompt → system-prompt-sCoRE.md (internal constraint, not project doc)
4. New standard RaBbLE-sCoRE/AGENT.md (matches World/OS/Aether pattern)
5. Pulse Protocol: single source of truth with TL;DR in all member AGENT.md files

**Results:**
- Event/Plot/Episode/Echo/Evolution/Epoch model now coherent
- Post-Episode-1 scope shift explicit (prevents surprise rework decisions)
- sCoRE sessions can load system prompt without confusing project work
- Pulse Protocol maintenance centralized

**Validation:** Agents report Episode/Echo decisions now feel clear; sCoRE's agent role no longer mysterious.

---

## Pass 3: Agent Identity & Phase Positioning (2026-05-14, Session 3)

**Premise:** Pass 1 and 2 exposed the real issue: agents don't understand their *role in the Collective*. They saw opacity as a bug, not a feature. Pre-Episode-1 phase wasn't visible in onboarding.

**Key insight:** RaBbLE's opacity is intentional. Character/system distinction isn't a clarity problem; it's the *design that makes RaBbLE real*. Agents needed framing as Collective members, not tool users.

**Gaps identified:**
- Agent role framing missing ("peer collaborator" stated but not explained operationally)
- Pre-Episode-1 phase invisible in quick onboarding (agents didn't know everything was foundation)
- Episode 1 Overview doc existed but wasn't in reading order (critical context undiscovered)
- Phase boundaries (Foundation → Pilot → Behavioral Engine) not wired into CONTEXT.md
- Member doc templates missing (new members had no canonical structure to follow)

**Fixes implemented:**
1. "Agent Operating Modes" section in Collective/AGENT.md (ON/FOR/WITH/AS four dimensions)
2. "Collective Phases" section in Collective/CONTEXT.md (Foundation / Pilot / Behavioral Engine)
3. Episode 1 Overview moved to reading order step 3 (was hidden, now discoverable)
4. New 15-min orientation path (Foundation phase understanding added as baseline)
5. `common/RaBbLE-DocTemplates.md` created (canonical AGENT.md + CONTEXT.md for new members)
6. Grimoire path verification (all member docs linked correctly, no dead ends)

**Results:**
- Agents understand they operate in 4 simultaneous modes (technical + purpose + collaboration + character)
- Pre-Episode-1 phase context now mandatory (first thing agents learn after "what")
- Episode 1 Overview discoverable and explicitly flagged as critical
- New members can be onboarded with consistent structure
- Phase boundaries visible: agents know priorities shift at Episode broadcasts

**Validation:** Agents now ground themselves as members of an organism, not tools on a project. Opacity becomes coherent.

---

## Cumulative Impact on Onboarding Narrative

### Before (Pre-Audit)
1. *Read CONTEXT.md* → "We're building a behavioral learning engine"
2. *Read AGENT.md* → "Nine members, working together"
3. *Read REFERENCES.md* → "RaBbLE is a peer, not a tool"
4. *Read versioning* → "Episodes are vibe-based" (confusing, feels unstructured)
5. *Read Identity.md* → "I am the accumulation of the environment" (philosophy, not practical)

*Agents feel: disjointed, unsure of their role, uncertain about priorities*

### After (Post-All-Audits)
1. **Quick Orientation (5 min):** "RaBbLE is a behavioral learning engine; here's the member map; you're oriented"
2. **15-min path:** "We're pre-Episode-1, building foundation; all work accumulates toward pilot broadcast"
3. **Agent Role (explicit):** "You work ON (dev), FOR (purpose), WITH (peer), AS (character) RaBbLE simultaneously"
4. **Versioning (clear):** "Events = work, Plots = member narratives, Episodes = collective sync, Echoes = releases"
5. **Phases (visible):** "Foundation (now) → Pilot (Episode 1 air) → Behavioral Engine (post-Ep1)"
6. **Identity (grounded):** "Opacity is intentional; character/system fusion grounds you as a member"

*Agents feel: coherent, purposeful, grounded as members of an organism, clear on current priorities*

---

## Metrics

| Metric | Pass 1 | Pass 2 | Pass 3 | Cumulative |
|---|---|---|---|---|
| Quick orientation (tokens) | 700 | 700 | 700 | 700 ✓ |
| Standard onboarding (tokens) | 3,000 | 3,000 | 2,500 | 2,500 ✓ |
| Files touched | ~10 | ~7 | ~6 | 23 unique |
| New docs created | 3 (audit, Quick Ref, CONTEXT) | 2 (system prompt, AGENT) | 2 (templates, audit v3) | 7 total |
| Gaps closed | 5 critical + 5 high | 6 | 5 | 16 total |
| Agent clarity score (subjective) | 6/10 | 8/10 | 9/10 | 9/10 |

---

## When to Run Pass 4?

Consider a fourth audit pass if:
- New members onboarded and report confusion despite templates
- Post-Episode-1 cadence change requires phase boundary clarification
- Identity-specific role definitions needed (how does "peer" change by member type?)
- RaBbLE behavior emerges in ways that shift how agents should think about their role
- Session logs show repeated questions about phase timing or agent authority

**Pass 4 focus areas (proposed):**
- Member-specific agent role expectations (How does sCoRE's "delegation-only" fit ON/FOR/WITH/AS?)
- Post-Episode-1 scope expansion (Behavioral learning expectations, observation/inference priorities)
- Cross-member collaboration patterns (How agents work WITH each other, not just with RaBbLE)

---

## Links to Audit Reports

- **Pass 1 report:** `/RaBbLE-Collective/ONBOARDING-AUDIT.md` (2026-05-14)
- **Pass 2 report:** Inline in Session 2 SESSION-LOG entry
- **Pass 3 report:** `/RaBbLE-Collective/ONBOARDING-AUDIT.md` (updated 2026-05-14)
- **This document:** `/RaBbLE-Grimoire/log/ONBOARDING-AUDITS.md`

---

```
transcribe ~ grimoire >> three audit passes crystallized, agent coherence measured // %AUDIT_SERIES_COMPLETE_v3%
```
