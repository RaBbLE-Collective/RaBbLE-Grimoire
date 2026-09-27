# RaBbLE-EnGrAm-Architecture.md

```
ingest ~ collective >> EnGrAm named and crystallized: photo/notes intake, unified item schema, resolves Roadmap Q4 // %ENGRAM_DEFINED%
```

> **Document type:** Grimoire architecture doc · `RaBbLE-EnGrAm/`
> **Status:** Proposed canonical · name + backing-store decided, pending PWA/ScRibLE scope decision (§8.2a)
> **Purpose:** Define the architecture for **EnGrAm** — the Personal Cosmos's Memory member, resolving the previously-unnamed placeholder in `RaBbLE-Personal-Cosmos.md` and `RaBbLE-Agent-Roadmap.md` open question #4 ("Memory member name + scope").
> **Author:** Mark McConachie (architect) + planning agent (claude.ai)
> **Provenance:** Synthesized from two working-notes docs (Aug 2026) authored outside the canonical Grimoire; named and integrated here per session review.
> **Related:** [RaBbLE-Personal-Cosmos.md](../RaBbLE-Collective/RaBbLE-Personal-Cosmos.md) · [RaBbLE-ScRibLE-Overview.md](../RaBbLE-ScRibLE/RaBbLE-ScRibLE-Overview.md) · [RaBbLE-sCoRE-Agent-Framework-Research.md](../RaBbLE-sCoRE/RaBbLE-sCoRE-Agent-Framework-Research.md) (three-tier memory, Mem0+Grimoire — see Open Questions §7) · [RaBbLE-Agent-Roadmap.md](../RaBbLE-Agent/RaBbLE-Roadmap.md) (open question #4 — **resolved by this doc**)

---

## 0. Canonical Definition

**EnGrAm** is a recursive-ish acronym in the Collective naming tradition (sCoRE, NeBuLA):

> **EnGrAm** = **Entity's Networked Graph-Relational Archival Memory**

EnGrAm is the Personal Cosmos's long-term memory layer — the per-user, self-hosted store where photos, notes, and structured life-data become a single queryable, linked, reasoned-over corpus. It is not the canonical Grimoire (Collective-wide, never duplicated) and it is not the Personal Grimoire (the curated *view* `RaBbLE-Personal-Cosmos.md` already defines) — it's the backend that makes the full Personal Grimoire possible. Everywhere earlier working notes said "Grimoire" for personal photo/notes storage, that was EnGrAm.

Each stored unit is literally an *engram* — a discrete trace with its own embedding and explicit relations to other traces. The name is meant to be taken literally, not just decoratively.

---

## 1. Scope & Relationship to Existing Structure

| Existing concept | Relationship to EnGrAm |
|---|---|
| **Personal Grimoire** (`RaBbLE-Personal-Cosmos.md`) | The curated *view* — what EnGrAm exposes once BaBbLE intake is sorted and approved |
| **BaBbLE** (intake) | Upstream of EnGrAm — raw capture flows in; EnGrAm is where it becomes structured, queryable, linked |
| **ScRibLE** | Primary capture surface feeding EnGrAm; `RaBbLE-ScRibLE-Overview.md` already states ScRibLE outputs are "the primary feed into the Memory member's behavioral profile" — that's EnGrAm |
| **sCoRE** | Owns tagging/linking/synthesis compute tiers per the existing orchestrator-capacity principle (cheap models tag/link, top tier runs synthesis) |
| **Canonical Grimoire** | Not touched. EnGrAm is per-user data, not Collective-wide knowledge. |

**Concept:** A self-hosted, privacy-first alternative to locked-down cloud photo/notes services — queryable and reasoned over via the Collective's cluster architecture, not just stored. Staged path: **personal use → family/friend sharing → Collective digital service.** Decisions below are chosen so early stages don't force a rewrite later.

---

## 2. Core Design Principles

1. **Multi-tenancy from day one, even with one tenant.** Every record carries a `tenant_id` from the start. Retrofitting isolation later is a painful migration; an unused column now is nearly free.
2. **Object storage abstraction, not raw filesystem.** Self-hosted MinIO (S3-compatible) on existing EC2 infra — same interface as real S3/Backblaze if scale ever demands it, and sidesteps the provider-lock-in frustration that motivated this in the first place.
3. **Pipeline stages are pluggable from v1**, even where most stages are no-ops initially. This is what lets CSAM scanning (§5) or any future stage slot in without a redesign.
4. **One unified item schema for photos and notes**, not parallel systems linked afterward. A photo and a journal entry about it are sibling records, not different tables joined as an afterthought — this directly targets "captured but a mess": inconsistent linking, not lack of storage, is the actual pain point.
5. **Hybrid vector + graph storage**, not vector-only. Embeddings give fuzzy "find things like this" retrieval; explicit graph relations give structured traversal ("everything linked to this habit this quarter"). The mess problem is fundamentally a missing-relations problem.

---

## 3. Unified Item Schema (draft shape)

```
Item {
  id
  tenant_id
  type: photo | note | insight | habit_entry | achievement | synthesis_digest
  blob_ref: nullable        // object storage pointer, null for text-only
  metadata: { timestamp, location?, source, exif? }
  tags: [tag_id...]
  embedding: vector
  relations: [{ item_id, relation_type }]
  created_at, updated_at
}
```

Synthesis digests (periodic pattern summaries) are written back as first-class Items — not just displayed and discarded — so EnGrAm stays recursively queryable rather than accumulating one-off reports outside the graph.

---

## 4. Pipeline Stages

1. **Ingest** — accept upload (photo, note, structured habit/achievement entry) from BaBbLE/ScRibLE
2. **Extract metadata** — EXIF, timestamp, source
3. **Tag/caption** — local vision-language inference for photos (component TBD — see Open Questions §6); text classification against canonical taxonomy for notes. This is the actual privacy pitch vs. cloud incumbents: no image leaves the user's infrastructure to get tagged.
4. **Link** — propose relations to existing graph nodes (narrow, well-scoped — good fit for a small/cheap model per the orchestrator-capacity principle in `RaBbLE-sCoRE-Agent-Framework-Research.md`)
5. **Store** — object storage (blob) + item record (graph/vector DB)
6. **Index** — update embedding + graph indices

**Synthesis** (pattern digests, "what emerged this month") runs as a separate, scheduled, top-tier job — not part of per-item ingestion. Tagging/linking don't need real reasoning capacity; synthesis does.

---

## 5. Legal / Compliance Note

Applies once EnGrAm leaves personal-only use. Any service storing or serving user-uploaded photos for people other than the owner is generally subject to CSAM detection and reporting obligations (NCMEC reporting in the US, comparable frameworks elsewhere) — a baseline requirement once family/friend sharing or Collective-service stages are reached, not a hypothetical edge case. Because the pipeline is staged (§4), this slots in as one more processing stage rather than a redesign — but it needs to be planned for **before** the sharing stage goes live, not after.

---

## 6. Backing Store Decision — RESOLVED

~~Option A (Obsidian-wraps) vs. Option B (own store)~~ — **decided: roll EnGrAm's own store. No Obsidian.**

Rationale: the Grimoire already has a proven MD + JSON graph pattern (`spells/graph-grimoire.sh`, `log/grimoire-graph.json` — link parsing, orphan/hub/island detection, token-cost accounting). Obsidian's actual value-add over that existing pattern is the GUI, not the graph/link infrastructure — and the GUI comes at the cost of a closed-source dependency sitting inside a project whose premise is "no locked-down services." Extending tooling you already trust closes that gap for free.

**Concretely:**
- Backing store: EnGrAm-native — object storage (MinIO) + graph/vector DB, per the unified Item schema in §3. No Obsidian vault, no wrapper layer.
- Link/graph tooling: extend the Grimoire's existing MD+JSON graph pattern rather than adopting Obsidian's backlink model — same spell-script discipline, applied to EnGrAm's Item graph instead of Grimoire docs.
- Front end: **self-hosted PWA**, not a desktop-app-first design. This is the flow already in motion for `RaBbLE-ScRibLE` (mobile-native intake PWA) — EnGrAm's front end and ScRibLE's capture surface should likely be the same surface, or close cousins, rather than two separate PWAs. Worth confirming during build whether EnGrAm's browsing/query UI lives inside ScRibLE or as its own app that ScRibLE feeds into.

---

## 7. Staged Build Order

1. **Architecture/planning** (this doc) — schema, pipeline stages, storage decision
2. **Unified notes+photos ingestion** — pipeline + schema working end-to-end, personal use
3. **Photo search/tagging on existing library** — apply tagging/linking stages retroactively to existing photo backlog
4. **Family/friend sharing** — requires tenant isolation to matter, triggers CSAM compliance (§5)
5. **Collective digital service** — multi-tenant SaaS/PaaS stage; revisit cost model, auth, abuse-handling here, not before

---

## 8. Open Questions

1. ~~Naming~~ — **resolved: EnGrAm.**
2. ~~Backing store decision~~ — **resolved (§6): EnGrAm-native store, extend Grimoire's MD+JSON graph pattern, no Obsidian.**
2a. **PWA scope vs. ScRibLE** (new, from §6 resolution) — is EnGrAm's front end ScRibLE itself, a separate PWA ScRibLE feeds into, or a shared codebase with two entry points? Decide before front-end build starts, since ScRibLE is already the planned mobile PWA intake surface and duplicate build effort is exactly the kind of entropy the Collective avoids.
3. **Canonical tag vocabulary/taxonomy** — who/what maintains it as it evolves?
4. **Sharing scope for stage 4** — full items only, or per-tenant visibility rules on individual relations/tags too?
5. **Collective-service stage pricing/resource-metering model** — given local-hardware compute constraints already discussed elsewhere in the Collective architecture.
6. **Local VLM component for photo tagging** — needs a concrete pick (small dedicated VLM vs. existing sCoRE tier); no canonical component name exists yet, treat any prior reference to a specific named tagger as a placeholder, not a decision.
7. **Reconcile with `RaBbLE-sCoRE-Agent-Framework-Research.md`'s three-tier memory (Mem0+Grimoire).** That doc's memory layer is scoped to *session/agent* memory (cross-turn continuity for sCoRE's orchestration). EnGrAm is *personal content* memory (photos/notes/synthesis digests). Likely complementary, not overlapping — but the boundary should be stated explicitly somewhere canonical before Echo 1 framework adoption locks in.
8. **Backup/redundancy for the object storage layer** — single EC2 instance is a single point of failure for what's meant to replace "locked-down but reliable" cloud services.

---

```
transcribe ~ collective >> EnGrAm: own store, no Obsidian, self-hosted PWA front end — Roadmap Q4 + backing-store resolved, ScRibLE scope next // %ENGRAM_STORE_DECIDED%
```
