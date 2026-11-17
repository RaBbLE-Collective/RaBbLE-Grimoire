> Recovered from the 2026-11-17 chat export: written during the chat "Local hardware requirements for Sonnet-level open models" (2026-08-15). Verbatim, not reconciled with current canon. Predecessor thinking to RaBbLE-EnGrAm-Architecture.md; the doc calls the store 'Grimoire', which now means something else.

# RaBbLE Grimoire: Personal Knowledge, Photo & Notes Storage

*Companion doc to `rabble-collective-society-architecture.md`. Working notes, Aug 2026 — not a finalized spec.*

## Concept

A self-hosted, privacy-first alternative to locked-down cloud photo/notes services (Google Photos, iCloud) that's queryable and reasoned over via the RaBbLE Collective's cluster architecture, rather than just stored. Staged build path: **personal use → family/friend sharing → RaBbLE Collective as a digital service.** Architecture decisions below are chosen so early stages don't force a rewrite for later ones.

## Core Design Principles

1. **Multi-tenancy from day one, even with one tenant.** Every record carries a `user_id`/`tenant_id` field from the start. Retrofitting tenant isolation into a single-user schema later is a painful migration; an unused column now is nearly free.
2. **Object storage abstraction, not raw filesystem.** Self-host MinIO (S3-compatible API) on existing EC2 infra. Same interface as real S3/Backblaze if scale ever demands it — also solves the provider lock-in frustration that motivated this project in the first place.
3. **Pipeline stages are pluggable from v1**, even if most stages are no-ops initially: `upload → extract metadata → [processing stages] → store → index`. This is what lets CSAM scanning (see Legal section) or any future processing step slot in without a redesign.
4. **One unified item schema for photos and notes**, not parallel systems linked afterward. A photo and a journal entry about that photo are sibling records, not different tables joined as an afterthought. This directly targets the "captured but a mess" problem — inconsistent linking, not lack of storage, was the identified pain point.
5. **Hybrid vector + graph storage**, not vector-only. Embeddings (already used in sCoRE) give fuzzy "find things like this" retrieval; explicit graph relations give structured traversal and synthesis queries ("everything linked to this habit this quarter"). The mess problem is fundamentally a missing-relations problem — items exist, they're just not consistently linked.

## Unified Item Schema (draft shape)

```
Item {
  id
  tenant_id
  type: photo | note | insight | habit_entry | achievement | synthesis_digest
  blob_ref: nullable  // object storage pointer, null for text-only
  metadata: { timestamp, location?, source, exif? }
  tags: [tag_id...]
  embedding: vector
  relations: [{ item_id, relation_type }]
  created_at, updated_at
}
```

Synthesis digests (periodic pattern summaries) are written back as first-class Items themselves — not just displayed and discarded — so the Grimoire stays recursively queryable rather than accumulating one-off reports outside the graph.

## Pipeline Stages

1. **Ingest** — accept upload (photo, note, or structured habit/achievement entry)
2. **Extract metadata** — EXIF, timestamp, source
3. **Tag/caption** — local vision-language inference (Muse Glimmer's perception encoder, or a dedicated small VLM) for photos; text classification against canonical taxonomy for notes. This is the actual privacy pitch vs. cloud incumbents: no image leaves your infrastructure to get tagged.
4. **Link** — propose relations to existing graph nodes (narrow, well-scoped task — good fit for a small model per the cluster-tier reasoning in the companion architecture doc)
5. **Store** — object storage (blob) + item record (graph/vector DB)
6. **Index** — update embedding + graph indices

Synthesis (pattern digests, "what emerged this month") runs as a separate, scheduled, top-tier job — not part of per-item ingestion — consistent with the orchestrator-capacity principle from the main architecture doc: synthesis needs real reasoning capacity, tagging/linking doesn't.

## Legal / Compliance Note (applies once this leaves personal-only use)

Any service storing or serving user-uploaded photos for people other than yourself is generally subject to CSAM detection and reporting obligations (NCMEC reporting in the US, comparable frameworks elsewhere) — not a hypothetical edge case, a baseline requirement once "family/friend sharing" or "Collective service" stages are reached. Because the pipeline is staged (§Pipeline Stages), this slots in as one more processing stage rather than a redesign — but it needs to be planned for before stage 2 (sharing) goes live, not after.

## Backing Store Decision (open)

Still unresolved — worth deciding before building the schema for real:

- **Option A**: Obsidian stays source of truth; Grimoire wraps it with a graph/embedding layer, treating Obsidian's existing backlink structure as a manual graph to formalize.
- **Option B**: Grimoire becomes its own backing store (object storage + graph/vector DB); Obsidian becomes one view/client into it, alongside photos and other item types it was never designed to hold.

Given the unified-schema goal and photo-storage requirement, Option B is probably necessary long-term (Obsidian has no native answer for photo blobs or multi-tenant data), but Option A may be the pragmatic v1 for the notes half specifically while photo infrastructure gets built separately and merged later.

## Staged Build Order (per current plan)

1. **Architecture/planning** (this doc) — schema, pipeline stages, storage decision
2. **Unified notes+photos ingestion** — get the pipeline and schema working end-to-end for personal use
3. **Photo search/tagging on existing library** — apply the tagging/linking stages retroactively to your current photo backlog (this is also where the embedding-based "clean up drifted tags" pass from the earlier Grimoire discussion applies)
4. **Family/friend sharing** — requires tenant isolation to actually matter, and triggers the CSAM compliance requirement
5. **RaBbLE Collective as a digital service** — the multi-tenant SaaS/PaaS stage; revisit cost model, auth, and abuse-handling requirements at this point, not before

## Open Questions

1. Backing store decision (Option A vs B above) — blocks schema finalization
2. What's the canonical tag vocabulary/taxonomy, and who/what maintains it as it evolves?
3. Sharing scope for stage 4: full items, or per-tenant visibility rules on individual relations/tags too?
4. Does the Collective-service stage (5) need its own pricing/resource-metering model, given the local-hardware compute constraints already discussed for the broader Collective architecture?
5. Backup/redundancy strategy for the object storage layer — single EC2 instance is a single point of failure for what's meant to replace "locked-down but reliable" cloud services.
