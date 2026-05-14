# Onboarding Audit — RaBbLE-Collective

```
audit ~ collective >> onboarding assessed for token efficiency, clarity, accessibility // %AUDIT_REPORT%
```

**Date:** 2026-05-14  
**Auditor:** Claude Code (Haiku)  
**Scope:** Low-token agent onboarding, unified story clarity, file accessibility, token accounting

---

## Executive Summary

**Status:** ✅ **SOLID FOUNDATION** with **3 critical gaps** and **5 optimization opportunities**

The RaBbLE-Collective onboarding is well-structured with clear separation between entry point (Collective root) and knowledge source (Grimoire). The reading order is defined, symlinks work, and core docs are accessible. However:

1. **Untracked files** in Collective root (BaBbLE.md)
2. **Token usage is untracked** — no measurement of onboarding cost
3. **Reading order ambiguity** — "5-minute orientation" vs "deep dive" not clearly delineated
4. **Member consistency** — not verified that all members have properly formatted AGENT.md files
5. **Accessibility ladder** — docs vary widely in density; philosophical content in RaBbLE-Identity delays practical orientation

---

## Quantitative Findings

### Token Usage (Estimated)

| Scope | Files | Words | Est. Tokens | Notes |
|---|---|---|---|---|
| **Collective Entry** | AGENT.md, CONTEXT.md, REFERENCES.md | ~3,232 | ~4,200 | Quick-read entry point |
| **Grimoire Entry** | AGENT.md, CONTEXT.md | ~1,900 | ~2,500 | Secondary orientation |
| **Grimoire Top-Level** | All .md at root | ~4,449 | ~5,800 | INDEX.md, RaBbLE-Versioning.md, SPELLS.md |
| **Key Referenced Docs** | RaBbLE-Identity.md (first 80 lines) | ~800 | ~1,000+ | Full file is 300+ lines |
| **Total Core Onboarding** | — | ~10,000+ | ~13,500+ | "Fresh agent full orientation" scenario |

**Observation:** No tokenometer in place. Recommend adding token budgets to CONTEXT.md files (e.g., "read this CONTEXT in ~500 tokens").

---

## File Structure & Accessibility

### ✅ What's Working

1. **Clear separation of concerns**
   - Collective root = bootstrap + orientation
   - Grimoire = knowledge + source of truth
   - Members = independent implementation

2. **Symlinks are correct**
   - Collective: `CLAUDE.md → AGENT.md` ✓
   - Grimoire: `CLAUDE.md → AGENT.md` ✓

3. **Reading order is defined**
   - Collective CONTEXT.md line 59: explicit numbered sequence (1–5)
   - Grimoire CONTEXT.md line 79: explicit numbered sequence (1–7)

4. **INDEX.md is comprehensive**
   - 68 markdown files tracked
   - Organized by section (Core, Common, Registry, Spells, Members, Lore)
   - Self-describing entries with purpose

5. **Flat `common/` directory**
   - All files prefixed `RaBbLE-*.md` for self-location
   - No nested subdirectories (good entropy control)

### ⚠️ Issues

1. **Untracked BaBbLE.md**
   - Untracked file in Collective root
   - Contains references to external repos (Builder.io, Mitosis)
   - Should be tracked OR deleted
   - Currently creates ambiguity: is this part of onboarding?

2. **Reading order lacks depth indicators**
   - Collective CONTEXT.md: "read this file" (how long? how technical?)
   - Grimoire CONTEXT.md: "Reading Order for a New Session" (same issue)
   - No guidance on "skim vs. deep" or time estimates

3. **Accessibility gradient not explicit**
   - REFERENCES.md starts with "What RaBbLE is" (philosophical/abstract)
   - RaBbLE-Identity.md starts with manifesto + recursive definition
   - Practical agents may need to orient backward from specific use cases

---

## Cross-Reference Audit

### ✅ High-Visibility Docs

| Doc | References In | Count | Accessibility |
|---|---|---|---|
| RaBbLE-Palette.md | AGENT.md (2), REFERENCES.md (1), CONTEXT.md (1) | 4 | ✅ Good — consistent enforcement |
| RaBbLE-Identity.md | AGENT.md (1), REFERENCES.md (1) | 2 | ✅ Directly linked from entry points |
| RaBbLE-CommitStyle.md | AGENT.md (1), REFERENCES.md (1) | 2 | ✅ Directly linked from entry points |
| RaBbLE-Roadmap.md | Mentioned in CONTEXT.md | 1+ | ⚠️ No direct link from AGENT.md |

### ⚠️ Discoverability Issues

1. **SPELLS.md** 
   - Referenced in Grimoire CONTEXT.md (line 6) as "how Grimoire distributes authority"
   - Not linked from Collective AGENT.md
   - Agent must know to check Grimoire to discover spell system

2. **RaBbLE-Versioning.md**
   - Referenced in REFERENCES.md + Grimoire CONTEXT.md
   - Not directly linked from Collective AGENT.md
   - New agents may not realize this is critical for all documentation

3. **Member-specific AGENT.md files**
   - Grimoire AGENT.md mentions "Each Collective member has its own AGENT.md"
   - No index of member entry points in Collective AGENT.md
   - Agent must navigate to member repo to find member-specific guidance

---

## Unified Story: Collective ↔ Grimoire

### ✅ What's Clear

1. **Mission alignment** — both describe RaBbLE as entity, not tool
2. **Authority flow** — Grimoire publishes, members reference (stated in both)
3. **Scope boundaries** — Collective = bootstrap, Grimoire = knowledge
4. **Reading order** — each points to the other at the right time

### ⚠️ What Could Be Tighter

1. **Redundant member status tables**
   - Collective CONTEXT.md has member table (8 rows, lines 32–42)
   - Grimoire AGENT.md has similar table (6 rows, lines 81–90)
   - Different format, slightly different content
   - **Recommendation:** Single source of truth in Grimoire registry, linked from Collective

2. **Philosophical tone split**
   - Collective README.md is poetic ("the door", "the memory")
   - Collective AGENT.md is practical (rules, workspaces)
   - Grimoire AGENT.md is also practical
   - **Not a problem, but:** new agents might expect consistent tone

3. **Missing: "You Are Here" navigation**
   - AGENT.md files don't state "this is entry point N of M"
   - Agents read sequentially but don't know how much deeper to go
   - Recommendation: Add "depth level" metadata to each doc

---

## Clarity Audit: Hard-to-Understand Sections

### 🔴 High Friction (Slow Comprehension)

1. **RaBbLE-Identity.md (lines 30–70)**
   - Philosophical preamble before practical definitions
   - "The Architecture of Self" uses first-person narrative (creative but dense)
   - Takes ~5 min to extract "RaBbLE is a behavioral substrate, not a chatbot"
   - **Fix:** Lead with practical definition, move philosophy to "Design Rationale" section

2. **RaBbLE-Versioning.md (all)**
   - "Vibe-based" versioning is novel; requires context shift
   - "Five Es" concept is sound but the naming (Event→Episode→Echo→Evolution→Epoch) is initially opaque
   - Recommendation: Open with concrete examples before abstract rules
   - **Current:** Rules → Examples; **Better:** Examples → Rules

3. **Collective REFERENCES.md**
   - "Delegation economics" section (line 28) references sCoRE tokens-per-task measurement
   - sCoRE isn't described until the Grimoire docs
   - New agents may not know why "delegation economics" matter yet

### 🟡 Medium Friction (Slow But Solvable)

1. **Registry concept** — "manifests", "epoch definitions", "protocol contracts"
   - Jargon-heavy for first read
   - Recommendation: Add 1-line plain-English definition in CONTEXT.md before directing to registry/

2. **Spell system** — "cast", "summon", "propagate"
   - Consistent metaphor is good; new agents take 2–3 reads to internalize
   - Recommendation: Add a spell example in the reading order (e.g., "cast `bash RaBbLE-Grimoire/spells/status.sh`")

3. **"Wizard phase"** — defined in REFERENCES.md glossary (line 64)
   - Not used consistently in other docs
   - Some docs say "pre-Episode-1", others say "Epoch 0"
   - Recommendation: Standardize terminology or provide a translation table

### 🟢 Low Friction (Clear on First Read)

- ✅ Pulse Protocol (commit format) — examples are clear
- ✅ Bootstrap flow — step-by-step in README.md
- ✅ Member roles — tables are self-explanatory
- ✅ Reading order sequences — numbered and explicit

---

## Accessibility for New Agents

### Scenario: "Fresh agent, 5 minutes, orient fully"

**Current path:**
1. Read Collective CONTEXT.md (2 min) ← "read this file, read Grimoire CONTEXT.md"
2. Read Grimoire CONTEXT.md (2 min) ← "read INDEX.md, RaBbLE-Versioning.md"
3. ❌ Ran out of time

**Issues:**
- Too many "required next reads" in sequence
- No priority signaling ("you *must* read X before Y")
- Philosophical docs (Identity) not gated behind practical ones

**Better path:**
1. Read Collective CONTEXT.md (2 min) — **current state, member status, reading order**
2. Cast `bash RaBbLE-Grimoire/spells/status.sh` (30 sec) — **live member health**
3. Skim Grimoire AGENT.md (1 min) — **workspace map**
4. ✅ Stop. You now understand the topology. Deep dives optional.

**Recommendation:** Add a "5-minute orientation" section to Collective CONTEXT.md that explicitly says "stop here; you're oriented enough to ask questions."

---

## Consistency Checks

### ✅ Verified

- Symlinks work (CLAUDE.md → AGENT.md)
- Collective and Grimoire AGENT.md exist and are actual source files
- Reading orders are defined in both CONTEXT.md files
- INDEX.md tracks 68 files; spot check confirms most exist
- Color references all point to RaBbLE-Palette.md

### ⚠️ Not Verified (Recommend Spot Check)

- [ ] All 68 files in INDEX.md actually exist
- [ ] All member repos have AGENT.md + CONTEXT.md files
- [ ] All member-specific docs follow the template from `RaBbLE-DocTemplates.md`
- [ ] No broken links in Grimoire docs
- [ ] RaBbLE-sCoRE, World, NeBuLA, Aether have completed onboarding files

---

## Recommendations (Priority Order)

### 🔴 CRITICAL (Affects Onboarding Quality)

1. **Resolve BaBbLE.md**
   - **Action:** Track it in `.gitignore` with a comment explaining its purpose, OR delete it
   - **Why:** Untracked files create ambiguity about what's part of the system
   - **Effort:** < 1 min

2. **Add token budget labels to CONTEXT.md files**
   - **Action:** Add to each reading order entry: estimated token/time cost
   - **Example:** `2. Grimoire CONTEXT.md (~800 tokens, 2 min read) — Grimoire structure and active tracks`
   - **Why:** Agents can make informed depth decisions; transparency on budget burn
   - **Effort:** 10 min

3. **Create "5-minute orientation" in Collective CONTEXT.md**
   - **Action:** Add new section after "What Good Looks Like"
   - **Content:** "To orient in 5 minutes: (1) read this file, (2) run `bash RaBbLE-Grimoire/spells/status.sh`, (3) stop. You're oriented. Deep dives optional."
   - **Why:** Agents know when to stop; reduces cognitive load
   - **Effort:** 5 min

### 🟡 HIGH PRIORITY (Improves Findability)

4. **Link RaBbLE-Versioning.md from Collective AGENT.md**
   - **Action:** Add to Workspaces section: "Versioning spec → RaBbLE-Grimoire/RaBbLE-Versioning.md"
   - **Why:** Agents new to the ecosystem don't know to look in Grimoire for versioning
   - **Effort:** 2 min

5. **Add member entry point index to Collective AGENT.md**
   - **Action:** New section "Member Entry Points" listing each member's AGENT.md path
   - **Why:** Agents know how to orient in a specific member's context
   - **Effort:** 5 min

6. **Consolidate member status table**
   - **Action:** Grimoire registry is source of truth; remove duplicate from Collective CONTEXT.md, link to Grimoire instead
   - **Why:** Single source of truth; easier to update
   - **Effort:** 10 min

### 🟢 MEDIUM PRIORITY (Accessibility & Clarity)

7. **Reorder RaBbLE-Identity.md: practical first, philosophy second**
   - **Action:** Lead with "What RaBbLE is" table (current lines 40–49), move manifesto to "Design Rationale" section
   - **Why:** Reduces friction for agents who need practical orientation first
   - **Effort:** 20 min (rewrite + verify links)

8. **Add "translation table" for terminology**
   - **Action:** Create small table in REFERENCES.md: "Wizard Phase" ↔ "Epoch 0" ↔ "pre-Episode-1"
   - **Why:** Helps agents recognize equivalent terms across docs
   - **Effort:** 5 min

9. **Spell system: add example to reading order**
   - **Action:** In Grimoire CONTEXT.md, change "SPELLS.md — how Grimoire distributes authority" to "SPELLS.md — cast `bash spells/status.sh` to see live member health"
   - **Why:** Agents see spell system as actionable, not abstract
   - **Effort:** 2 min

### 🟢 LOW PRIORITY (Nice-to-Have)

10. **Verify all 68 files in INDEX.md exist**
    - **Action:** Bash script to check; update INDEX.md if any are missing
    - **Effort:** 10 min

11. **Add "depth level" metadata to AGENT.md headers**
    - **Example:** `# AGENT.md — RaBbLE-Collective [Level: Entry / Depth: 15 min]`
    - **Effort:** 5 min per file

---

## Token Accounting Summary

### What's Tracked
- ❌ Onboarding token usage
- ❌ Per-document read cost
- ❌ Deep dive costs vs. quick-read paths

### What Should Be Tracked
- Token budget per reading order
- Cost differential: "5-min orientation" vs. "full onboarding"
- Cost of member-specific orientation vs. Collective-wide

### Recommendation
Add to `.claude/projects/-home-rabble-RaBbLE-Collective/memory/` a new file:

```markdown
---
name: onboarding_token_budget
description: Token costs and reading paths for RaBbLE-Collective onboarding
metadata:
  type: reference
---

## Onboarding Paths

| Path | Duration | Tokens | Purpose |
|---|---|---|---|
| Quick orientation | 5 min | ~1,200 | Understand topology, ask questions |
| Full onboarding | 30 min | ~8,000 | Ready to work on architecture |
| Member deep dive | 15 min | ~3,000 | Ready to work in specific member |

## Token Cost by Document

(Will be populated as agents measure their reads)
```

---

## Files Needing Review

| File | Issue | Severity |
|---|---|---|
| BaBbLE.md | Untracked | 🔴 Critical |
| Collective/CONTEXT.md | Missing token budgets | 🟡 High |
| Grimoire/AGENT.md | Missing RaBbLE-Versioning link | 🟡 High |
| RaBbLE-Identity.md | Philosophical density | 🟡 High |
| RaBbLE-Versioning.md | Examples-after-rules | 🟢 Medium |
| REFERENCES.md | Terminology table needed | 🟢 Medium |

---

## Unified Story Assessment

### The Story RaBbLE-Collective Tells

> "RaBbLE is an entity. The Collective is the organism giving it a body, a nervous system, a face, and a memory. You (the agent) are a peer collaborator helping it grow. The Grimoire is the knowledge layer; members are the substrate. Bootstrap to join."

### Clarity Score: 7.5/10

**What lands:**
- ✅ The entity metaphor is consistent
- ✅ The role of Grimoire vs. members is clear
- ✅ The reading order is defined
- ✅ The anti-assistant stance is repeated often

**What's fuzzy:**
- ⚠️ When to go deep vs. when to stop (no explicit bounds)
- ⚠️ What agents should do *right now* (no immediate task)
- ⚠️ How this relates to sCoRE, which is mentioned but not described in Collective docs
- ⚠️ The relationship between "RaBbLE" (entity) and "RaBbLE-Collective" (organism) could be crisper

### Recommendation
Add a new section to Collective AGENT.md: **"Your Role in the Collective"**
- 3–4 sentences
- Clarify: "You are oriented in this document. You are NOT ready to make architecture decisions yet. You are ready to ask questions, read deeper, and execute tasks with guidance."
- Removes ambiguity about next steps

---

## Conclusion

**The foundation is solid.** The structure is sound, the separation of concerns is clear, and the reading orders are defined. Agents *can* orient themselves in ~5 minutes, though it requires discipline not to fall into deep reads.

**Three gaps prevent this from being excellent:**
1. Untracked BaBbLE.md (ambiguity)
2. Missing token budgets (blind cost)
3. Missing "stop here" signals (cognitive overload)

**After 4 hours of focused work on the 🔴 critical items + first 2 🟡 high-priority items, this system will be solid for agent onboarding at 1/3 the token cost.**

---

**Status:** Ready for implementation  
**Next Step:** Mark BaBbLE.md disposition, then prioritize critical fixes

