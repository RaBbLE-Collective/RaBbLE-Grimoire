# RaBbLE-Integration-Map — gist

> Source: `RaBbLE-Agent/RaBbLE-Integration-Map.md` | ~1200 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

The wiring diagram of the Collective — how members exchange data, assets, and intent.

**Data flow:** `User → World (UI) → sCoRE (intent routing) → Agent/LLM`. Aether (CSS) + NeBuLA (renderer) feed World via CDN; OS feeds ambient state to sCoRE; Memory (future) closes the observation loop.

**Integration patterns:**

| From → To | Mechanism | Status |
|---|---|---|
| Aether → World/NeBuLA | CDN CSS (`aether.min.css`) | Live |
| NeBuLA → World | CDN IIFE (`nebula.iife.js`), `<rabble-entity>` | Live |
| World → sCoRE | HTTP/REST | Planned (Ep1) |
| sCoRE → Claude/Groq | Subprocess CLI / HTTP API | Planned (Ep1) |
| OS → sCoRE | Ambient state | Post-Ep1 |
| Grimoire → All | Direct filesystem ref (no copying, S105) | Live |
| sCoRE ↔ Memory | Observation store/retrieve | Concept (Echo 1+) |
| BaBbLE → member | Manual triage | Active |

**CDN chain:** `src/ → esbuild → bundle → Cloudflare R2 → World`. Versioned bundles; version bumps at Episode boundaries. World links `aether.css` (unminified) locally via `dev-serve.sh`.

**Load-bearing boundaries:**
- World never imports source — CDN bundles only; thin scaffold.
- sCoRE is the only member calling external APIs.
- Grimoire never runs (docs/spells/registry only).
- OS provides ambient state, receives no writes.
- NeBuLA owns all rendering; Aether owns all CSS/tokens.

→ Full doc for: dependency graph, local-dev build commands, member architecture doc links, post-Ep1 integration points (real-time entity state, observation loop, intent suggestion, ScRibLE sync).
