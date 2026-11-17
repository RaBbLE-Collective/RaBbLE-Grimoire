# RaBbLE-sCoRE: Data Crawler Architecture — RFC

```
transcribe ~ sCoRE >> data crawler bot architecture preserved as RFC // %RFC_INTAKE%
```

> **Source:** BaBbLE ideation corpus (`text/ideation`). Captured from design explorations.
> **Status:** Concept RFC — not scheduled. Future sCoRE capability, post-Episode-1.

---

## Overview

A three-tier autonomous data crawler to populate sCoRE's knowledge base — parallel scavenger bots feeding an organizer layer feeding a librarian interface.

---

## Architecture

### Knowledge Base

Central store for all scavenged, processed, and indexed content.

### Tier 1: Scavenger Bots

- Runs in parallel — multiple bots targeting different sources simultaneously
- Distributable across machines if needed
- **Flow:** Select Target → Scavenge raw data → Save artifacts (simple filtering only)
- Does not interpret — only collects and light-filters
- Tools include: `Scavenge` (target acquisition + extraction)

**Targets:** List of entities to scavenge data from (URLs, feeds, APIs, etc.)

### Tier 2: Organizer Bot

- Processes Scavenger artifacts into structured knowledge
- **Flow:** Process artifacts → Distill connections → Create embedded sources (images, docs) → Build knowledge graphs
- Produces embeddings and graph structures, not just raw docs

### Tier 3: Librarian Reference Bot

- User-facing intelligence layer
- **Flow:** Get user intent → Traverse knowledge graph → Present information
- The only tier that talks to the user

---

## Relationship to sCoRE

This architecture is a natural extension of sCoRE's intent → action engine. sCoRE today handles direct delegation. The crawler adds *ambient information gathering* — background observation that feeds sCoRE's context without requiring explicit user requests.

Aligns with RaBbLE's behavioral learning loop:
- **Scavenger** = passive observation
- **Organizer** = pattern extraction  
- **Librarian** = intent-aware retrieval

---

## Notes

- The distributed/parallel scavenger design maps well to async Python (FastAPI/celery or equivalent)
- Knowledge graph could use a local graph DB (Neo4j, or lighter: networkx + SQLite)
- "Embedded sources" suggests multimodal indexing — images + docs in the same retrieval space
- Long-term: Librarian behavior could be learned from user interactions (behavioral signal)

---

*Source material preserved in `RaBbLE-BaBbLE/text/ideation`. BaBbLE retains the original.*
