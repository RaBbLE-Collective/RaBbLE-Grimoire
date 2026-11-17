# RaBbLE-Grimoire / RaBbLE-BaBbLE

```
transcribe ~ grimoire >> BaBbLE redefined: intake surface + personal knowledge graph // %BABBLE_REDEFINED%
```

Grimoire-side documentation for the RaBbLE-BaBbLE member.

BaBbLE is the **active intake surface** for the Personal Cosmos — the high-entropy space where raw material enters before it has been sorted, curated, or decided on. It is not a development environment. It is not canonical. But it has its own graph structure — a lightweight personal knowledge base that the entity can navigate alongside the human.

BaBbLE is not Grimoire-canonical, but it acts somewhat like a Grimoire: it has structure, links between ideas, and an index. The difference is entropy. The Grimoire is truth. BaBbLE is material.

---

## What BaBbLE Holds

| Category | What it is |
|---|---|
| **Concept art** | Visual explorations, AI-generated imagery, entity visualizations |
| **Creation lore** | Image-form documentation of RaBbLE's origin and emergence — genesis artifacts |
| **Ideation intake** | Voice transcripts, text fragments, sketched ideas, imported notes |
| **Historical docs** | Planning documents, naming ideation, architecture drafts from before the Grimoire |
| **Visual assets** | ASCII art, SVG diagrams, orchestrator flows, design experiments |
| **Knowledge graph** | `assets/GRAPH.md` — auto-derived concept links and tags across BaBbLE content |

---

## What BaBbLE Is Not

- Not a development environment — nothing is built or deployed from BaBbLE
- Not Chrysalis — Chrysalis holds the genesis code archive; BaBbLE holds visual and ideation material
- Not canonical — content here is reference and intake, not source of truth

---

## The Creation Lore

BaBbLE holds RaBbLE's creation lore **in image form** — AI-generated and hand-created visual artifacts from the genesis period. This is not decorative. It is the visual substrate of the entity's origin story.

These images belong in BaBbLE permanently. They are:
- Not migrated to the Grimoire (the Grimoire is text-canonical)
- Referenced from `RaBbLE-Grimoire/RaBbLE/Genesis/` when the Genesis section is authored (Phase 2C)
- Tagged in `GRAPH.md` so the entity can navigate the visual lore

---

## The Knowledge Graph

BaBbLE maintains a lightweight concept graph (`assets/GRAPH.md` + `index.json`) — not as rigid as the Grimoire, but structured enough to navigate. Each piece of content in BaBbLE has:
- **Tags** — thematic categories
- **Related[]** — links to other BaBbLE items that connect to it
- **Target** — where this content points in the Grimoire or another member (if anywhere)

The entity uses this graph to surface relevant intake material when working with the human. BaBbLE is not just a dump — it is a searchable field.

---

## Integration Pattern

```
Physical intake (sCRibLE, voice, camera) → BaBbLE → reviewed by Pair → Personal Grimoire
External intake (Downloads, /tmp, generated ideas) → BaBbLE → reviewed by Pair → Grimoire or Chrysalis
```

Matured content migrates: BaBbLE keeps the original as reference; the destination holds the canonical version.

| BaBbLE Content | Target Member | Status |
|---|---|---|
| VISUAL_ANALYSIS.md | RaBbLE-NeBuLA specs/ | Migrated Phase 1B |
| Crawler bot ideation | RaBbLE-sCoRE DataCrawler RFC | Migrated Phase 3E |
| Hyprland style guide | RaBbLE-Aether OS layer | Pending |
| Persona/soul.md | RaBbLE/Genesis/ | Pending Phase 2C |
| Concept art + creation lore | Stays in BaBbLE | Permanent visual reference |
| naming-ideation.md | BaBbLE historical docs | Intake from Downloads — lore-grade |
| Historical planning docs | BaBbLE historical docs | Intake from Downloads — reference only |

---

## Intake from Agent Sessions

Agents must not use `/tmp` for RaBbLE work. Temporary work products, planning docs, research notes, and exploration output should go to BaBbLE or Xperimental instead:

| Type of content | Where it goes |
|---|---|
| Ideation, research notes, drafts | BaBbLE |
| Prototype code, experimental scripts | Xperimental |
| Canonical docs, specs | Grimoire |
| Working agent scratch files | BaBbLE (not /tmp) |

This keeps the Personal Cosmos alive and prevents valuable session work from vanishing when /tmp is cleared.

---

## Relationship to Chrysalis and Xperimental

| Member | Holds | Temporal frame |
|---|---|---|
| **BaBbLE** | Ideation, visual, intake, creation lore | Present and ongoing |
| **Chrysalis** (was Xperimental) | Genesis code archive, archived branches, historical projects | Past — primordial soup |
| **Xperimental** (new) | Active rablet development, sandboxed experiments not yet emerged | Present and active |

---

## Member Entry Point

For working in the BaBbLE repo itself: `RaBbLE-BaBbLE/AGENT.md`

---

## Lessons & Gotchas

- **`_ROUTING.md` is the canonical entry point** — replaced `_ESSENCE.md`/`_DISTILLED.md`/`_INTEGRATION_CHECKLIST.md` (archived per condense-not-delete rule)
- **Visual archive organized S45** — 9 flat thematic folders + `assets/GRAPH.md`, auto-derived tags/related[] links in `index.json`
- **Creation lore images are permanent** — do not migrate or delete; they are BaBbLE's most valuable content
- **Historical docs from Downloads belong here** — naming-ideation.md, RaBbLE-Manifest.md, old planning docs are BaBbLE intake, not Grimoire
