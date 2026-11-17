# RaBbLE-World-Roadmap.md

```
transcribe ~ grimoire >> web presence and entity interaction surface mapped // %WORLD_ROADMAP_LOCKED%
```

> **Collective Context:** RaBbLE-World is the public face and orchestration layer. See `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `log/EP1-AIR-CHECKLIST.md` for Episode 1 scope across all members.
> **Related:** [Collective Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) · [World Architecture](RaBbLE-World-Architecture.md) · [Aether Architecture](../RaBbLE-Aether/RaBbLE-Aether-Architecture.md) · [NeBuLA API](../RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md) · [sCoRE Architecture](../RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md)

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** the entity-forward face at `joinrabble.world`: a visitor meets RaBbLE and talks to it.

**Status (S248):** built and live on **dev.joinrabble.world**; prod updates at the air merge (prod deploys
only from `main`). Gate G10 awaits Mark's sign-off. Plan of record: `log/plans/EP1-Entity-Face-Plan.md` (W0–W2 done).

**What ships:**
- [x] Five-beat face: Arrive → Boot → Meet → Summon → Enter around `<rabble-entity backend="alive">` (S235); Arrive is the **"wake RaBbLE"** button, the entity answers "awake. hello." (Mark confirmed live on dev with the sCoRE connection, S248)
- [x] Boot holds on real steps (Aether applied, NeBuLA upgraded, sCoRE health) so a cold Render start reads as boot
- [x] Chat to sCoRE (guest SSE path, S153); typing/awaiting/streaming drive entity moods
- [x] Summon = portal-colour preview, nothing persisted ("claim it in Exodus")
- [x] iPhone pass: scrollable voice stack, 16px input, keyboard-aware dock (S241; keyboard/landscape still being tested)
- [x] `world/os.html` OS Developer Preview install guide; `/setup.sh` + `/RaBbLE-OS.ks` redirects (S234)
- [x] Aether rc.2 + NeBuLA rc.1 from CDN; deployed via Cloudflare Workers (dev auto-deploys from `new-horizons`)
- [ ] Mark sign-off on dev (G10): not yet, the face is the most polished version but needs more work (S249)
- [x] `/chrysalis/` removed (S249): dev router 301s to `chrysalis.joinrabble.world`; prod's stale folder goes at the air merge
- [ ] At air: repoint `_redirects` (`RaBbLE-OS.ks`, `/roadmap`) to `main`; pin bundles to `v0.0.0.1`

**Retired:** the "grimoire browser" deliverable (May plan) and the S190 liminal passage (frozen in Chrysalis).

**Deferred to Episode 2+:**
- User accounts (EP2 Accounts spec) — Summon becomes real
- `<rabble-entity-mini>` on every page; NeBuLA state machine driven by sCoRE streaming
- Grimoire graph view (see vision below)

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
