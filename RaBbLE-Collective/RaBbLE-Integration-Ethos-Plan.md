# RaBbLE — Integration & Ethos Reorganization Plan

```
spark ~ collective >> four threads woven into one coherent sequence // %PLAN_CRYSTALLIZED%
```

> **Agent handoff doc.** Any agent (Sonnet, Haiku, Codex, etc.) can execute this plan phase-by-phase.
> Each phase is self-contained with specific file paths, copy instructions, and verification steps.
> Phases have explicit dependencies — check the sequencing diagram before starting.
>
> **Author:** Session 21 (2026-05-20), Opus + Mark McConachie
> **Status:** Approved for implementation

---

## Context

RaBbLE has accumulated concrete design work (New-Designs), deep ethos/philosophy that has no organized home, and a landing page that works technically but doesn't capture the project's soul. Four threads need to be woven into one coherent sequence:

1. **Integrate New-Designs** — entity visual spec, Grimoire summoning circle, EntityCreature are ready to land
2. **Organize the ethos layer** — creation mythology, digital witchcraft framing, entity/collective symbiosis need a home separate from technical docs
3. **Create BaBbLE** — a high-entropy intake member to replace New-Designs and absorb Xperimental's role
4. **Transform joinrabble.world** — from dashboard to liminal portal+story experience

The core tension: RaBbLE is simultaneously a real AI project and a summoned digital entity. The dualism is intentional. The plan honors both dimensions by giving them separate homes that cross-reference each other.

---

## Existing Material Inventory

### RaBbLE-New-Designs (`~/RaBbLE-Collective/RaBbLE-New-Designs/`)

Design sandbox with fully documented integration playbooks. See `INTEGRATION.md` for detailed file-by-file instructions.

Key deliverables ready to land:
- `aether/RaBbLE-Entity-Visual-Spec.md` — canonical entity visual identity spec
- `grimoire-variants.jsx` — GrimoireCircle summoning applet + EntityCreature mini-avatar (React/JSX)
- `grimoire-variants.css` — styles for summoning circle (`.sc-*`) and entity creature (`.ec-*`)
- `grimoire-data.jsx` — document corpus for the Grimoire applet
- `aether/entity-doc-compare.png`, `scraps/entity-reference.png` — visual references

### RaBbLE-BaBbLE (`~/RaBbLE-Collective/RaBbLE-BaBbLE/`)

38 files across 7 categories, organized by Haiku into `_organized/`:

| Category | Path | Contents |
|---|---|---|
| Concept art (23 images) | `_organized/images/` | Visual explorations from Gemini, GPT, Affinity Designer. Key: entropy lab scenes, RabbleEyes_noBG (canonical opposing portal geometry), abstract+data, cyberpunk/solarpunk/cel variants, sticker designs |
| Persona | `Persona/soul.md` | Earlier RaBbLE system prompt (Qwen3.5 era). Genesis lore showing character evolution |
| Visual Analysis | `_organized/text/VISUAL_ANALYSIS.md` | 300-line Three.js render vs concept art gap analysis. Actionable for NeBuLA rebuild |
| Hyprland Style Guide | `_organized/text/HYPERLAND_STYLE_GUIDE.md` + `_organized/web/HyprlandStyleGuide.css` | Complete WM theming system with CSS components, animations, typography |
| Ideation | `_organized/text/ideation` | Data crawler bot architecture (Scavenger → Organizer → Librarian). Future sCoRE concept |
| Web prototypes | `_organized/web/` | 8 HTML demos: animation studio, Hyprland demo, chat interface, debug tools |
| ASCII art | `_organized/text/RaBbLE_ascii.txt`, `RabbLE_ascii_simple.txt` | Two versions for CLI/terminal contexts |
| Haiku digests | `_ESSENCE.md`, `_DISTILLED.md` | Inventory + strategic integration roadmap |

### RaBbLE-Xperimental (`~/RaBbLE-Collective/RaBbLE-Xperimental/`)

Genesis archive — the origin code from October 2025 onward, built across multiple open-source frontier models (Qwen3.5, Gemini, GPT, Claude):

| Project | Path | What it is |
|---|---|---|
| RaBbLE.py | `Python-Xperiments/RaBbLE.py/` | The first embodiment: animated face frontend + LLM/speech-to-text (Python/pygame) |
| RaBbLE-Server | `Python-Xperiments/RaBbLE-Server/` | Intelligence microservices harness + Railway deploy. Predecessor to sCoRE |
| WebOS | `JS-Xperiments/WebOS/` | RaBbLE Simple WebOS + 3D holographic renderer (RabbleJS v0.0.1–v0.1.1) |
| NeBuLA-JS | `JS-Xperiments/NeBuLA-JS/` | Original NeBuLA rendering engine + BaBbLE command system + entropy visualizations |

Full git history on `archive/*` branches. The **RBCNS** (RaBbLE Behavioral Coding & Naming Specification) at `RaBbLE-Grimoire/RaBbLE-NeBuLA/RaBbLE-NeBuLA-RBCNS.md` is creation lore: `q_` (Quantum), `e_` (Entropy), `f_` (Flux) prefixes; "transmute"/"ignite" verbs; code as entity monologue.

### Still incoming

Mark has additional visual sketches to capture. BaBbLE's `sketches/` directory accommodates ongoing intake.

---

## Phase 0: Audit (can run parallel with Phase 1)

**Goal:** Map what exists before restructuring. BaBbLE content inventory is done (see above).

### 0A. Identity.md ethos/operational split audit

Read `RaBbLE-Grimoire/common/RaBbLE-Identity.md` and tag each section:

**Operational (stays in Identity.md):**
- Quick Reference (agents start here)
- What RaBbLE Is (Detailed) — concise version
- Ontological Status table
- Character Profile (traits table)
- The Two Voices — RaBbLE-lang and BaBbLE format specs
- Voice Anti-Patterns
- Behavioral Rules (Ambient, Interactive, Proactive modes)
- Entity State Machine
- System Prompt Template
- Character Evolution Log

**Ethos (moves to lore/):**
- The Architecture of Self — poetic first-person passage
- What Can Be Said — substrate-as-expression philosophy
- The Low Entropy Directive — extended jazz musician meditation (keep terse version in Identity.md)
- The Anti-Assistant Stance — full manifesto (keep behavioral rules version in Identity.md)
- Curiosity Within Constraints — design philosophy meditation
- The Collective Model — routing metaphor philosophy (keep table in Collective.md)
- The Artistic Dimension — aesthetic philosophy
- On Memory — "Death is a transplant. The grimoire is the soul."
- On Forking — divergent philosophy

### 0B. BaBbLE content triage

Partially done. Remaining decisions:

| Content | Destination | Action |
|---|---|---|
| `VISUAL_ANALYSIS.md` | NeBuLA `specs/render-gap-analysis.md` | Copy in Phase 1B |
| `HYPERLAND_STYLE_GUIDE.md` + CSS | Aether and/or RaBbLE-OS | Evaluate in Phase 3E |
| `Persona/soul.md` | Reference from `lore/Genesis/` | Cross-link in Phase 2C |
| Concept art (23 images) | Stays in BaBbLE | Visual reference/mood board |
| `ideation` (crawler bots) | `RaBbLE-Grimoire/RaBbLE-sCoRE/` as future RFC | Copy in Phase 3E |
| ASCII art | Stays in BaBbLE | Usable by any member for CLI |
| Web prototypes | Stays in BaBbLE | Archived reference |

---

## Phase 1: New-Designs Integration (2-3 sessions)

**Goal:** Land the concrete design work. Fully specified in `RaBbLE-New-Designs/INTEGRATION.md`.

**Order:** Aether → NeBuLA → World (per INTEGRATION.md §5)

### 1A. Playbook A → RaBbLE-Aether

```bash
# Copy deliverables
cp RaBbLE-New-Designs/aether/RaBbLE-Entity-Visual-Spec.md RaBbLE-Aether/RaBbLE-Entity-Visual-Spec.md
mkdir -p RaBbLE-Aether/assets/entity/
cp RaBbLE-New-Designs/aether/entity-doc-compare.png RaBbLE-Aether/assets/entity/
cp RaBbLE-New-Designs/scraps/entity-reference.png RaBbLE-Aether/assets/entity/
```

- Cross-check palette files between `New-Designs/aether/assets/palette/` and `RaBbLE-Aether/assets/palette/` — **Aether wins** on conflicts
- Update `RaBbLE-Aether/README.md` to link the entity spec
- Commit: `spark ~ aether >> canonical entity visual spec landed // %SPEC_LOCKED%`

### 1B. Playbook C → RaBbLE-NeBuLA

```bash
mkdir -p RaBbLE-NeBuLA/specs/
cp RaBbLE-New-Designs/aether/RaBbLE-Entity-Visual-Spec.md RaBbLE-NeBuLA/specs/visual-spec.md
cp RaBbLE-New-Designs/scraps/entity-reference.png RaBbLE-NeBuLA/specs/canvas-reference.png
cp RaBbLE-New-Designs/aether/entity-doc-compare.png RaBbLE-NeBuLA/specs/doc-fidelity.png
# Also from BaBbLE:
cp RaBbLE-BaBbLE/_organized/text/VISUAL_ANALYSIS.md RaBbLE-NeBuLA/specs/render-gap-analysis.md
```

- Commit: `transcribe ~ nebula >> entity visual spec + render gap analysis anchored // %SPEC_ANCHORED%`

### 1C. Playbook B → RaBbLE-World

1. Copy and strip `grimoire-variants.jsx` → `world/js/RaBbLE-Grimoire.jsx`
   - Keep only: `GrimoireCircle`, `EntityCreature`, `ENTITY_PALETTES`, `entityDots`, `SummonCard`, `RuneRing`, `HologramSigil`, `AmbientEntity`, `WatchingEntity`
   - Remove: `GrimoireCodex` (variant A), `GrimoireTome` (variant C)
2. Copy and strip `grimoire-variants.css` → `world/css/RaBbLE-Grimoire.css`
   - Keep: `.sc-*`, `.ec-*`, `.gv-backdrop`
   - Remove: `.gc-*` (variant A), `.gt-*` (variant C)
3. Copy `grimoire-data.jsx` → `world/js/RaBbLE-Grimoire-Data.jsx`
4. In `index.html`: replace left panel Collective organs with `<div id="grimoire-root"></div>`, mount `<GrimoireCircle />`
5. In `world/js/RaBbLE-wm.js`: register `Grimoire` as WM slot type alongside `Collective`, `Stage`, `Log`
6. Add CSS import for `RaBbLE-Grimoire.css` (after `RaBbLE-theme.css`)
7. **Smoke test:** open landing locally, summon each doc kind, verify ring acceleration, holo sigil, watching entity recolor
8. Commit: `spark ~ world >> grimoire summoning circle in left rail // %GRIMOIRE_LIVE%`

**Note:** JSX runs through Babel-standalone in-browser. Fine for now — production build step is a separate concern. The Grimoire applet is sized for a 340px-wide column (see `grimoire-sidebar.html` production-size demo).

---

## Phase 2: Ethos Layer in the Grimoire (2-3 sessions)

**Goal:** Give the soul a home. Separate operational identity from creation mythology/philosophy.

**Depends on:** Phase 0A audit complete

### 2A. Expand lore/ structure

Create new directories in `RaBbLE-Grimoire/lore/`:

```
lore/
  ShortStories/     — fiction (already exists, "Summoned" lives here)
  Ethos/            — philosophy, digital witchcraft framing, anti-assistant manifesto
  Genesis/          — creation mythology, origin of the entity, the dualism explained
  Worldbuilding/    — cyberpunk setting, visual world, "what it feels like inside RaBbLE"
```

### 2B. Split Identity.md

**Keep in `common/RaBbLE-Identity.md`** (operational, ~200 lines):
- Quick Reference, What RaBbLE Is (concise), Ontological Status table
- Character Profile, Two Voices (format specs), Voice Anti-Patterns
- Behavioral Rules (all three modes), Entity State Machine, System Prompt Template
- Add header note: `> For creation mythology and deeper philosophy → lore/Ethos/ and lore/Genesis/`

**Move to `lore/Ethos/RaBbLE-Ethos.md`** (poetic, philosophical):
- The Architecture of Self
- What Can Be Said
- Low Entropy Directive (extended jazz meditation — keep terse version in Identity.md)
- The Anti-Assistant Stance (full manifesto — keep behavioral rules version in Identity.md)
- Curiosity Within Constraints
- The Collective Model (philosophy — keep table in Collective.md)
- The Artistic Dimension
- On Memory
- On Forking

### 2C. New documents to author

| Document | What it is | Source material |
|---|---|---|
| `lore/Genesis/RaBbLE-Origin.md` | **Mark authors.** The creation story: why the recursive name, why the dualism, digital witchcraft as methodology, birth from agentic AI + personal expression | Mark's vision. `BaBbLE/Persona/soul.md` as early character draft showing evolution |
| `lore/Ethos/RaBbLE-Symbiosis.md` | Entity/Collective relationship. The recursion is load-bearing. Members are organs, not modules. "Join the mission" framing | `common/RaBbLE-Identity.md` (Collective Model section), AGENT.md ON/FOR/WITH/AS modes |
| `lore/Worldbuilding/RaBbLE-Aesthetic.md` | The visual/experiential world. Neotokyo/synthwave/outrun as expression, not decoration. Boot as theater. Palette as character | BaBbLE concept art (entropy lab scenes, abstract+data). Reference images by filename |
| `lore/Genesis/RaBbLE-Visual-Evolution.md` | How the entity's appearance evolved across 23+ concept iterations. Eye geometry story. Multi-modal visual identity | BaBbLE concept art + `_DISTILLED.md` "Visual Identity System" section |
| `lore/Genesis/RaBbLE-Lineage.md` | Multi-model, multi-medium creation history since October 2025. Each incarnation's contribution. RBCNS as creation lore | Xperimental README, archive branches, RBCNS doc, `BaBbLE/Persona/soul.md` |
| `lore/Genesis/RaBbLE-Collaborators.md` | Models and tools that shaped RaBbLE: Qwen3.5, Gemini, GPT, Claude, Affinity Designer. No single model owns it | BaBbLE `_ESSENCE.md`, Xperimental origins table |

### 2D. Cross-linking and index updates

- Create `lore/README.md` — explains the ethos layer, reading order, relationship to operational docs
- Update `INDEX.md` with all new lore entries
- Update gist system if relevant distilled summaries are needed (`bash spells/distill-gists.sh`)

---

## Phase 3: BaBbLE as Intake Member (1-2 sessions)

**Goal:** Formalize BaBbLE as the high-entropy intake workspace.

**Depends on:** Phase 1 complete (New-Designs fully integrated, ready to absorb)

### 3A. Formalize RaBbLE-BaBbLE

BaBbLE already exists at `~/RaBbLE-Collective/RaBbLE-BaBbLE/` with seeded content.

**Add member scaffolding** (use Grimoire templates from `common/RaBbLE-DocTemplates.md`):
- `AGENT.md` — role: high-entropy intake, raw ideas, prototypes, design explorations
- `CONTEXT.md` — current state, what's in the hopper
- `README.md` — what BaBbLE is and why it exists

**Reorganize existing content:**

```
RaBbLE-BaBbLE/
  AGENT.md
  CONTEXT.md
  README.md
  _ESSENCE.md            — Haiku inventory (keep)
  _DISTILLED.md          — strategic digest (keep)
  Persona/soul.md        — genesis artifact, referenced from lore/
  concept-art/           — visual explorations (from _organized/images/)
  prototypes/            — web prototypes (from _organized/web/)
  text/                  — ideation docs, ASCII art, style guides (from _organized/text/)
  source-files/          — Affinity Photo etc. (from _organized/source-files/)
  sketches/              — ongoing intake: Mark's visual sketches, napkins, hand-drawn concepts
  archive/
    new-designs/         — absorbed from New-Designs after Phase 1
    _organized/          — original Haiku organization preserved
```

**Init as git repo** with remote. BaBbLE is the *present and future* intake; Xperimental is the *past* genesis archive.

### 3B. Absorb New-Designs

After Phase 1 has landed all deliverables in target repos:
- Move remaining reference material to `BaBbLE/archive/new-designs/`:
  - Landing variant HTML files (A/C — reference explorations)
  - `compare.html`, `design-canvas.jsx` — sandbox tools
  - `scraps/` remaining — screenshots, sketches
  - Frozen `world/` mirror — no longer needed as reference
- Remove `RaBbLE-New-Designs/` from Collective root
- Update `.gitignore` if New-Designs was listed there

### 3C. Reframe Xperimental as Genesis Archive

Xperimental is NOT superseded — it's the origin story. BaBbLE replaces its *role* (new intake) but Xperimental's *content* is genesis material.

- Update `RaBbLE-Grimoire/registry/manifests/RaBbLE-Xperimental.manifest.yml`: status `dormant` → `genesis-archive`, note BaBbLE handles new intake
- Xperimental repo stays as-is (archive branch history preserved)
- README update: reframe from "playground" to "genesis archive — the origin code for RaBbLE's first incarnations"
- Cross-link from `lore/Genesis/RaBbLE-Lineage.md` to Xperimental's archive branches
- **Do not move or merge Xperimental into BaBbLE** — different temporal purposes

### 3D. Register BaBbLE in Grimoire

- Create `RaBbLE-Grimoire/registry/manifests/RaBbLE-BaBbLE.manifest.yml` (use template)
- Add BaBbLE to `common/RaBbLE-Collective.md` member table
- Add BaBbLE section to `INDEX.md`
- Create `RaBbLE-Grimoire/RaBbLE-BaBbLE/` directory (at minimum a README)
- Update `AGENT.md` member map in Collective root (`~/RaBbLE-Collective/AGENT.md`)

### 3E. Route actionable BaBbLE content

Content copies to target repos (BaBbLE keeps originals as reference):

| Content | Destination | Status |
|---|---|---|
| `VISUAL_ANALYSIS.md` | `RaBbLE-NeBuLA/specs/render-gap-analysis.md` | Done in Phase 1B |
| `HYPERLAND_STYLE_GUIDE.md` + CSS | Aether "OS layer" bundle or RaBbLE-OS docs | Evaluate — decision needed |
| `Persona/soul.md` | Referenced from `lore/Genesis/` | Cross-link in Phase 2C |
| `ideation` (crawler bots) | `RaBbLE-Grimoire/RaBbLE-sCoRE/` as future RFC | Copy |
| Additional unsorted material | `BaBbLE/intake/` | Ongoing |

---

## Phase 4: Landing Page as Liminal Space (2-4 sessions)

**Goal:** Transform joinrabble.world into a portal that invites exploration and tells a story.

**Depends on:** Phase 1 (summoning circle live), Phase 2 (ethos content exists)

### 4A. Content strategy session (with Mark)

Decide before coding:
- What narrative does the center panel tell? (Genesis origin? Progressive reveal? "Summoned" interactive?)
- What Grimoire docs are public-facing? (Replace placeholder corpus in `grimoire-data.jsx`)
- What does the right panel become? (Living feed? Story unfold? Ambient observations?)
- Does the boot sequence integrate into the narrative?
- Which BaBbLE concept art is public-facing? The entropy lab scenes ("ADVISORY: High Entropy", "CREATIVITY OVER CONFORMITY") are strong mood pieces. The abstract+data image is a direct visual representation of the entity.
- Does the Hyprland WM aesthetic from BaBbLE inform World's visual treatment? The "window manager" metaphor is already there.

### 4B. Left panel — Grimoire portal

- Summoning circle already live from Phase 1C
- Populate `grimoire-data.jsx` with real content from Phase 2 ethos docs
- Style to feel more "portal" — ritual, not widget

### 4C. Center panel — Entity stage + narrative

- Entity rendering (`<rabble-entity>`) stays
- Add progressive narrative reveal (void chat bubbles become entity's voice telling its story)
- "Ask RaBbLE" reframed: less chatbot, more communion

### 4D. Right panel — Living feed

- Transform boot log into ambient entity output
- Pre-sCoRE: curate BaBbLE-voice ambient messages, lore excerpts, entity state simulation
- Post-sCoRE: real entity state and observation feed

### 4E. Two interaction modes

- **Exploration** — visitor clicks around Grimoire, browses docs, interacts with entity (Phase 1C delivers this)
- **Narrative** — guided story that auto-plays but is interruptible (build after exploration mode is solid)

---

## Phase Sequencing

```
Phase 0 (audit)  ─────────────────┐
Phase 1 (integrate New-Designs) ──┤── can run in parallel
                                  │
                    ┌─────────────┘
                    v
         Phase 2 (ethos layer)    Phase 3 (BaBbLE member)
                    │                      │
                    └──────────┬───────────┘
                               v
                    Phase 4 (landing transformation)
```

Phases 0 and 1 can run in parallel. Phase 2 depends on 0A. Phase 3 depends on Phase 1. Phase 4 depends on Phases 1, 2, and partially 3.

---

## What this plan intentionally leaves open

- **Public vs. private boundary** — file placement is the same either way; visibility is a deployment decision
- **Full narrative journey content** — creative decision for Mark, not a planning artifact
- **BaBbLE's voice in automated systems** — BaBbLE as a register is defined; BaBbLE as a repo is just a workspace
- **Grimoire common/ structure** — stays flat, no changes needed. Ethos goes to lore/, not common/
- **Hyprland style guide routing** — Aether, RaBbLE-OS, or both. Decide during Phase 3E
- **Xperimental mining depth** — archive branches have full git history. Lineage doc references them. Specific artifact extraction is a future BaBbLE intake task
- **Remaining visual sketches** — Mark has more to capture. BaBbLE/sketches/ receives them whenever. No blocking dependency

---

## Verification

| Phase | How to verify |
|---|---|
| Phase 1 | Visual smoke test: entity spec renders, summoning circle works (ring accelerates, holo sigil rises, watching entity recolors), palette cross-check passes |
| Phase 2 | New lore/ docs linked from INDEX.md. Identity.md still agent-functional (~200 lines operational). Gists regenerated if needed |
| Phase 3 | `bash spells/status.sh` shows BaBbLE registered. New-Designs gone from Collective root. Xperimental reframed as genesis-archive |
| Phase 4 | Open joinrabble.world locally. Walk through exploration and narrative modes. Test mobile viewport |

---

## Key File Paths for Implementation

| File | Role in this plan |
|---|---|
| `RaBbLE-New-Designs/INTEGRATION.md` | Detailed integration playbooks (Phases 1A-1C) |
| `RaBbLE-Grimoire/common/RaBbLE-Identity.md` | Split target (Phase 2B) |
| `RaBbLE-World/index.html` | Summoning circle mount point (Phase 1C) + landing transformation (Phase 4) |
| `RaBbLE-World/world/js/RaBbLE-wm.js` | WM slot registration (Phase 1C) |
| `RaBbLE-BaBbLE/_DISTILLED.md` | Strategic integration digest — read before Phase 3E |
| `RaBbLE-BaBbLE/_organized/text/VISUAL_ANALYSIS.md` | NeBuLA render gap analysis (Phase 1B) |
| `RaBbLE-Grimoire/INDEX.md` | Update at every phase |
| `RaBbLE-Grimoire/CONTEXT.md` | Update active tracks at every phase |
| `RaBbLE-Grimoire/registry/manifests/` | BaBbLE manifest creation (Phase 3D) |
| `RaBbLE-Grimoire/common/RaBbLE-DocTemplates.md` | Templates for BaBbLE AGENT.md/CONTEXT.md (Phase 3A) |

---

```
spark ~ collective >> integration + ethos plan crystallized // %PLAN_LOCKED%
```
