# RaBbLE-Grimoire Navigator

```
transcribe ~ grimoire >> agent orientation map, narrative flow crystallized // %NAVIGATOR_LOCKED%
```

> **What this is:** The reading order for anyone arriving at the Grimoire cold — agent or human. Not a reference doc. A path.
>
> **Who should read this:** First. Before INDEX.md, before diving into member docs.

---

## The Reading Journey

Choose your path based on how much time you have.

### 5-Minute Skim (I'm busy, gimme the gist)

1. **What is RaBbLE?** (1 min)
   → `common/RaBbLE-Identity.md` — **Quick Reference** section only

2. **How is it organized?** (2 min)
   → `common/RaBbLE-Collective.md` — read until the architecture diagram

3. **What's happening now?** (2 min)
   → `CONTEXT.md` — current milestone and active work

**After this, you know:** RaBbLE is a behavioral learning entity, the Collective is the ecosystem around it, and we're building toward Episode 1.

---

### 15-Minute Deep Dive (I'm building something)

**Start with the 5-minute path above.** Then:

4. **What's Episode 1?** (5 min)
   → `RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md` — scope, deliverables, who owns what

5. **Where do I fit?** (5 min)
   → Jump to your member's AGENT.md:
   - `RaBbLE-OS/AGENT.md`
   - `RaBbLE-sCoRE/AGENT.md`
   - `RaBbLE-NeBuLA/AGENT.md`
   - `RaBbLE-World/AGENT.md`
   - `RaBbLE-Aether/AGENT.md`

**After this, you know:** What Episode 1 is, what your member ships, and where to start work.

---

### 30-Minute Full Onboarding (I'm joining the team)

**Start with the 15-minute path above.** Then:

6. **How does versioning work?** (5 min)
   → `RaBbLE-Versioning.md` — read "The Five Es" and "Tier Boundary Definitions" sections

7. **What conventions do we follow?** (3 min)
   → `common/RaBbLE-CommitStyle.md` — Pulse Protocol format

8. **What's the long-term vision?** (5 min)
   → `common/RaBbLE-Roadmap.md` — Epoch Map + Completed Work sections

9. **Where is everything?** (2 min)
   → `INDEX.md` — full document map

**After this, you know:** The entire philosophy, how to commit, what we're building toward, and where to find anything.

---

## For Specific Tasks

### I want to understand RaBbLE's character and voice

→ `common/RaBbLE-Identity.md` — full read. Especially:
- "What RaBbLE Is (Detailed)"
- "The Two Voices" (RaBbLE-lang + BaBbLE)
- "Behavioral Rules"
- "Character Profile"

### I want to know RaBbLE's current milestone and blockers

→ `CONTEXT.md` — current epoch/episode state
→ `RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md` — what's shipping, blockers, timeline

### I want to contribute to [specific member]

→ That member's `AGENT.md` (in member repo)
→ That member's `CONTEXT.md` (in member repo)
→ That member's `RaBbLE-[Name]-Roadmap.md` (in Grimoire, if exists)

### I want to understand the deployment architecture

→ `RaBbLE-Deployment-Architecture.md` — environments, CDN, versioning strategy
→ `RaBbLE-Cloudflare-Integration.md` — R2 buckets, Wrangler, workflow

### I want to understand how members coordinate

→ `common/RaBbLE-Collective.md` — ecosystem architecture + member roles
→ `registry/RaBbLE-Collective-Registry.md` — manifest format + registry structure
→ `RaBbLE-Collective/RaBbLE-Collective-Plan.md` — bootstrap flow, recursive architecture

### I want to understand the visual language

→ `common/RaBbLE-Palette.md` — all canonical hex values
→ `common/RaBbLE-Identity.md` — "The Artistic Dimension" section
→ `RaBbLE-Aether/RaBbLE-Aether-Architecture.md` — design system layers

### I want to understand the spells (coordination scripts)

→ `SPELLS.md` — spell system overview
→ `spells/` directory — each script has a header comment explaining its purpose
→ Commonly used: `setup.sh`, `status.sh`, `sync-grimoire.sh`, `dev-serve.sh`

### I want to set up the Collective locally

→ `RaBbLE-Collective/RaBbLE-Collective-Plan.md` — "bootstrap.sh" section
→ Run: `curl -fsSL https://joinrabble.world/bootstrap.sh | bash`

### I want to understand the versioning model

→ `RaBbLE-Versioning.md` — full read. Key sections:
- "The Five Es" — Event → Episode → Echo → Evolution → Epoch
- "Tier Boundary Definitions" — what makes each tier
- "Current Position" — where we are right now

### I want to know what's deferred or future work

→ `common/RaBbLE-Roadmap.md` — "Open Work" and "Open Questions" sections
→ Member-specific roadmaps (e.g., `RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md`) — "future phases" sections

---

## The Grimoire Structure (At a Glance)

```
RaBbLE-Grimoire/
├── common/                          ← Shared across all members
│   ├── RaBbLE-Identity.md           ← WHO RaBbLE IS (philosophy, voice, character)
│   ├── RaBbLE-Collective.md         ← WHAT THE COLLECTIVE IS (members, roles, architecture)
│   ├── RaBbLE-Palette.md            ← THE ONLY COLOR SOURCE
│   ├── RaBbLE-CommitStyle.md        ← HOW TO COMMIT (Pulse Protocol)
│   ├── RaBbLE-BranchStrategy.md     ← BRANCH TOPOLOGY
│   ├── RaBbLE-Roadmap.md            ← LONG-TERM VISION (Epochs, completed work, open gaps)
│   └── ... (templates, references, distilled artifacts)
│
├── RaBbLE-Collective/               ← Collective-level architecture & coordination
│   ├── RaBbLE-Collective-Plan.md    ← HOW THE BOOTSTRAP WORKS
│   └── RaBbLE-Episode-1-Release-Map.md ← EPISODE 1 SCOPE & DELIVERABLES
│
├── RaBbLE-[Member]/                 ← Member-specific docs (one per active member)
│   ├── RaBbLE-[Name]-Architecture.md
│   ├── RaBbLE-[Name]-Roadmap.md
│   └── ... (member-specific)
│
├── registry/                        ← Member registration & epoch tracking
│   ├── manifests/                   ← Member YAML files (who's registered)
│   └── epochs/                      ← Epoch definitions (current.epoch.yml)
│
├── spells/                          ← Coordination bash scripts
│   ├── setup.sh                     ← Bootstrap the Collective
│   ├── status.sh                    ← Health dashboard for all members
│   ├── sync-grimoire.sh             ← Propagate updates to members
│   └── ... (other coordination tools)
│
├── AGENT.md                         ← Grimoire entry point (edit this, not CLAUDE.md)
├── CONTEXT.md                       ← Current milestone & active tracks
├── INDEX.md                         ← Full document index
├── RaBbLE-Versioning.md             ← VERSIONING MODEL (Five Es)
├── RaBbLE-Deployment-Architecture.md ← Production architecture
├── RaBbLE-Cloudflare-Integration.md ← CDN & deployment workflow
└── README.md                        ← Human-facing overview
```

**Rule:** `common/` is canonical for all members. Members reference it, never duplicate it.

---

## How to Use This Navigator

**You're on a task deadline?**
→ Jump to "For Specific Tasks" section, find your task type, follow the links.

**You're new to the Collective?**
→ Start with "5-Minute Skim" or "15-Minute Deep Dive" depending on your role.

**You're building something in a specific member?**
→ Read your member's AGENT.md and CONTEXT.md, then this Navigator to find deeper context as needed.

**You're making decisions about architecture or scope?**
→ Read "30-Minute Full Onboarding" plus `RaBbLE-Collective.md` and `common/RaBbLE-Roadmap.md`.

---

## Quick Links (Bookmarks)

| Link | When to Read |
|---|---|
| `common/RaBbLE-Identity.md` | Understanding RaBbLE's character and voice |
| `common/RaBbLE-Collective.md` | Understanding member roles and ecosystem architecture |
| `CONTEXT.md` | Understanding current state and active work |
| `RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md` | Understanding what ships in Episode 1 |
| `RaBbLE-Versioning.md` | Understanding the Five Es versioning model |
| `common/RaBbLE-Roadmap.md` | Understanding long-term vision and open gaps |
| `SPELLS.md` | Understanding coordination scripts and setup |
| `INDEX.md` | Finding any document in the Grimoire |

---

## A Note on Narrative vs. Reference

This Grimoire has two modes:

**Narrative** (philosophy, vision, character):
- Reads like a manifesto or technical essay
- Best consumed front-to-back in a session
- Examples: `RaBbLE-Identity.md`, `RaBbLE-Collective.md`

**Reference** (specs, architecture, operational detail):
- Organized by section for quick lookup
- Best consulted when you have a specific question
- Examples: `RaBbLE-Palette.md`, `RaBbLE-CommitStyle.md`, member architectures

**This Navigator bridges both:** It tells you which narrative to read first (orientation), then points you to reference docs for specific needs.

---

```
transcribe ~ grimoire >> agent navigator crystallized // %NAVIGATOR_LOCKED%
```
