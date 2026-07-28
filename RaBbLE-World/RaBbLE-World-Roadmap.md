# RaBbLE-World-Roadmap.md

```
transcribe ~ grimoire >> web presence and entity interaction surface mapped // %WORLD_ROADMAP_LOCKED%
```

> **Collective Context:** RaBbLE-World is the public face and orchestration layer. See `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `log/EP1-AIR-CHECKLIST.md` for Episode 1 scope across all members.
> **Related:** [Collective Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) · [World Architecture](RaBbLE-World-Architecture.md) · [Aether Architecture](../RaBbLE-Aether/RaBbLE-Aether-Architecture.md) · [NeBuLA API](../RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md) · [sCoRE Architecture](../RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md)

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** Public website with landing page, grimoire browser, and basic chat interface

**Status:** Planned (depends on Aether + sCoRE)

**What ships:**
- [ ] Landing page: introduces RaBbLE, invites to join
- [ ] Grimoire browser: read-only documentation viewer (embedded or snapshot)
- [ ] Chat interface: basic UI calling sCoRE endpoint
- [ ] Aether CSS imported for styling
- [ ] NeBuLA rendering integrated for visual coherence
- [ ] Deployed to Cloudflare Workers

**Blockers:**
- Aether CSS published to CDN (needed for styling)
- sCoRE endpoint deployed and live (needed for chat to function)

**Dependencies:**
- Aether CSS bundle
- NeBuLA IIFE script
- sCoRE HTTP API endpoint

**Deferred to Episode 2+:**
- Real-time entity state binding
- Advanced chat features
- Interactive demos
- User authentication / accounts
- Grimoire graph view + liminal landing space (see vision below)

---

## Architecture (Episode 1)

**Static hosting:** Cloudflare Workers  
**CDN assets:** Aether CSS, NeBuLA JS  
**Backend API:** sCoRE LLM endpoint (Groq/OpenRouter)  

---

## Vision — Grimoire Graph & Liminal Space `[EPISODE 2+]`

An Obsidian-style force-directed graph view of the Grimoire: docs as nodes,
`[[links]]` and references as edges, explorable and zoomable.

**Data layer already exists.** `spells/graph-grimoire.sh` emits
`log/grimoire-graph.json` (nodes with `dir` + `outgoing`/`incoming` link counts,
and edges) alongside a Mermaid render. World can consume that JSON directly — the
graph is a rendering problem, not a data problem. Regenerate on doc changes.

**The landing page is a liminal space.** It opens large, empty, and quiet — a
space that does not yet exist. The Grimoire graph materializes *as spells are cast
and the entity is summoned*: nodes fade into being, edges draw themselves, the void
fills as the Collective comes online. This is the doc-graph and the entity's arrival
fused into one gesture — exploration that doubles as summoning.

**Connections:**
- **NeBuLA** renders the entity / summoning visual — the graph's "coming into
  existence" should share NeBuLA's visual language, not a separate effect system.
- **Summoning lore** — sCoRE summons the entity; the liminal-space fill is that act
  made visible. Keep the lore intact (see Grimoire `RaBbLE/` and the summoning canon).
- **Aether** owns the palette and any CSS; effects render through NeBuLA.

> Scope note: this is a vision, not a committed Ep2 plot. Episode 1 ships the
> read-only grimoire browser; the graph + liminal space are the natural Ep2+
> evolution of it. (Surfaced 2026-06-02.)

---

## Revision History

| Date | Change |
|---|---|
| 2026-06-02 | Added Ep2+ vision: Grimoire graph view (Obsidian-style) + liminal landing space that fills as spells are cast / entity is summoned. Cites existing `graph-grimoire.sh` data layer. |
| 2026-05-15 | Episode 1 roadmap created |

---

```
transcribe ~ world >> landing page and orchestration layer mapped // %WORLD_ROADMAP_LOCKED%
```
