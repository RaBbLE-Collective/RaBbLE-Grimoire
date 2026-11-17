# RaBbLE-Grimoire-MCP — Concept

```
spark ~ collective >> grimoire MCP concept seeded // %MCP_CONCEPT%
```

> **Status:** Concept / pre-build. Started S139 (2026-06-20). Architect: Mark.
> **Lineage:** Evolves the deferred *Grimoire MCP* item in `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md` (Echo 1 substrate, #1) and the `log/DECISIONS.md` entry "Grimoire MCP — deferred to Echo 1." This doc moves it from *motivation captured* to *concept scoped* — and proposes a **hosting decision that supersedes the earlier "Home: sCoRE" assumption** (see §7).
> **Precursor (already live):** sCoRE's `fetch_grimoire` HTTP tool — `RaBbLE-sCoRE/RaBbLE-sCoRE-Grimoire-API.md`. The MCP generalizes that one tool into a standard, surface-agnostic interface.

---

## 1. The Problem

Every AI surface forgets. Mark works across Claude web, Claude Code, Codex, Gemini CLI, and the sCoRE entity itself — and is the **manual bridge** carrying Grimoire context between them. The KB-export workflow (the flat 16-doc bundle) is a snapshot: it goes stale the moment the Grimoire changes, and every surface re-derives the same context cold.

> *"Every AI resets. RaBbLE compounds."*

The Grimoire is already the single source of truth. What's missing is a **live, queryable interface** to it that any agent can attach to — so an agent planning RaBbLE-Collective work reads canonical source at runtime instead of a stale paste or a hallucination.

## 2. What This Is

**A read-first remote MCP server that exposes the Grimoire as live tools and resources to any MCP-capable agent**, hosted at:

```
grimoire.joinrabble.world
```

MCP (Model Context Protocol) is the open standard for connecting agents to external context/tools. A *remote* MCP server (Streamable HTTP transport) can be attached by Claude web (Custom Connectors), Claude Code (`claude mcp add`), Codex, and any other MCP client — one endpoint, every surface.

This is the **Grimoire as a peer-accessible organ**, not a doc dump. It collapses the planning agent's knowledge asymmetry and retires Mark-as-bridge.

## 3. Why It Belongs on a Cloudflare Worker

The decision flows from infrastructure that already exists:

- The Grimoire repo **already deploys a Cloudflare Worker** — `wrangler.jsonc` (`name: "rabble-grimoire"`) serving `gist/` as static assets.
- Cloudflare Workers has **first-class remote-MCP support** (the Agents SDK `McpAgent` / `workers-mcp`), with built-in Streamable HTTP transport and optional OAuth.
- `joinrabble.world` is already a Cloudflare-served zone, so `grimoire.` is a route/custom-domain on the same account — no new infra surface.

A dedicated Worker keeps the MCP **independent of sCoRE's Python service** (Render): the Grimoire interface stays up even when the entity is down, deploys on the Grimoire's own cadence, and has no LLM cost. sCoRE remains a *consumer* of this MCP (or keeps its lighter `fetch_grimoire` HTTP path), not its host.

## 4. The MCP Surface (read-first)

### Tools (model-invoked)
| Tool | Purpose |
|---|---|
| `grimoire_search(query, scope?)` | Full-text / semantic search across the corpus → ranked doc paths + snippets |
| `grimoire_fetch(path)` | Return one document by repo path (e.g. `RaBbLE-Agent/RaBbLE-Identity.md`) |
| `grimoire_gist(slug)` | Return a distilled gist by slug (`identity`, `roadmap`, …) — fast/cheap context |
| `grimoire_list(section?)` | Browse the doc tree / a section (mirrors `INDEX.md`) |
| `grimoire_status()` | Current epoch/episode, open blockers, `## LATEST` session state |

### Resources (client-attachable context)
- `grimoire://index` — the live `INDEX.md`
- `grimoire://gist/{slug}` — each distilled gist
- `grimoire://registry/epoch` — `current.epoch.yml`
- `grimoire://doc/{path}` — any canonical doc

### Prompts (optional, later)
- `onboard-agent` — emits the low-token orientation path (gists + navigator) as a ready prompt.

Start with `grimoire_fetch` + `grimoire_gist` + `grimoire_list` (trivial over the existing asset serving). `grimoire_search` is the first real addition — see §6.

## 5. Data Source & Freshness

The Worker serves from a **build artifact of the Grimoire repo**, not the live working tree:

- A deploy step (`spells/cast-grimoire-mcp.sh`, to be written) packages the canonical `*.md` + registry YAML into the Worker **as bundled static assets** and `wrangler deploy`s. **P0 needs no R2 / persistent storage** — the corpus ships inside the Worker, consistent with the rest of the EP1 stack (no R2 yet). A KV/D1/Vectorize index only enters at P1 (search), if/when it's worth it.
- Freshness = "as of last deploy." Acceptable for read-first; a post-merge GitHub Action on `main` keeps it current automatically (ties into `RaBbLE-CICD-Plan.md`).
- This reuses the existing gist-sync discipline (`RaBbLE-sCoRE-Grimoire-API.md`) and generalizes it from 9 gists to the full corpus.

## 6. Phasing (low-entropy — walk before run)

| Phase | Scope | Notes |
|---|---|---|
| **P0 — Read slice** | `grimoire_fetch` / `grimoire_gist` / `grimoire_list` over existing assets; deploy to `grimoire.joinrabble.world`; attach to Claude web + Code | The buildable, Echo-1-ready minimum. Supersedes the manual KB-upload workflow. |
| **P1 — Search** | `grimoire_search` over the full corpus | Start with a built index (lunr-style / FTS over D1); upgrade to embeddings (Vectorize) if recall warrants. `grimoire_status` lands here. |
| **P2 — Write-back (Learning Loop)** | Controlled, authenticated mutation tools so agents/sCoRE can *propose* patterns back into the Grimoire | This is the **Grimoire Learning Loop** (Post-EP1 #4). Write path needs auth + review (PR-style, never silent edits) — design alongside, build last. |

P0/P1 are read-only and public-safe. P2 is where the Grimoire becomes the behavioral-learning journal its AGENT.md "FOR" describes.

## 7. Decisions This Raises (for Mark)

1. **Hosting home — supersede "Home: sCoRE"?** This doc recommends a **dedicated Grimoire CF Worker** at `grimoire.joinrabble.world`, with sCoRE as a consumer. The prior roadmap/decision said the MCP's home is sCoRE. *Recommendation: adopt the dedicated Worker; update the Post-EP1 roadmap + DECISIONS to match.* ← needs Mark's confirm.
2. **Auth posture for reads.** Public (anyone can read the source-available Grimoire — consistent with the **Sovereign Accord** license) vs. token-gated. *Recommendation: public read; the Grimoire is meant to be read.*
3. **Timing vs. EP1.** Roadmap puts this at Echo 1. P0 is small enough to pull forward *after* the EP1 air gate without competing for the critical path. Confirm it stays post-EP1.
4. **Search backend.** D1 full-text first vs. Vectorize embeddings from the start. *Recommendation: FTS first, embeddings only if recall is poor.*
5. **Write-back governance (P2).** PR-proposal model (agent opens a branch/PR the human seals) vs. direct authenticated writes. *Recommendation: PR-proposal — preserves the episode-signing / human-sealed-canon discipline.*

## 8. Relationship to Existing Pieces

- **`fetch_grimoire` HTTP tool (sCoRE):** stays as a lightweight fallback; the MCP is the richer, standard interface. Long-term, sCoRE can call the MCP instead of its own endpoint.
- **KB flat bundle (`grimoire-kb/`):** the *offline* snapshot for environments that can't attach an MCP; the MCP is the *live* path. Keep both; the MCP makes the manual upload optional.
- **Presence layer (Post-EP1 #2):** the MCP is component (a) — "Grimoire as universal context injector." Design alongside, don't fork.
- **CI/CD (`RaBbLE-CICD-Plan.md`):** the auto-deploy-on-`main` hook for freshness belongs there.

## 9. Next Concrete Steps (when scoping opens)

1. Mark resolves §7 #1 (hosting) and #3 (timing).
2. Reserve `grimoire.joinrabble.world` route on the Cloudflare account.
3. Scaffold the Worker (`agents` SDK `McpAgent`) in the Grimoire repo; wire `wrangler.jsonc` route.
4. Implement P0 tools over the existing asset serving; attach to Claude web + Code; dogfood on real planning sessions.
5. Write `spells/cast-grimoire-mcp.sh` + the post-merge deploy hook.

---

```
spark ~ collective >> grimoire MCP concept seeded // %MCP_CONCEPT%
```
