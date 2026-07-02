# RaBbLE-Integration-Map — gist

> Source: `RaBbLE-Agent/RaBbLE-Integration-Map.md` | ~1200 → ~210 tokens
> Regenerate: `bash spells/distill-gists.sh`

**The wiring diagram of the RaBbLE Collective—how members exchange data, assets, and intent.**

**System data flow:** User → World (web UI) → sCoRE (intent routing) → Agent/LLM (delegation), with Aether (CSS) and NeBuLA (renderer) feeding visual assets, and OS providing system state.

**Integration patterns:**

| From → To | Mechanism | Status |
|---|---|---|
| Aether → World, NeBuLA | CDN CSS bundle | Live |
| NeBuLA → World | CDN `<rabble-entity>` web component | Live |
| World → sCoRE | HTTP/REST API | Planned (Ep1) |
| sCoRE → Claude/Groq | Subprocess or HTTP API | Planned (Ep1) |
| OS → sCoRE | Ambient system state queries | Post-Ep1 |
| Grimoire → All | Filesystem reference (no copying) | Live |
| sCoRE ↔ Memory | Observation loop (behavioral learning) | Concept (Echo 1+) |

**Key boundaries (load-bearing):**
- World consumes only CDN bundles, never source
- sCoRE is the only API caller
- Grimoire runs no processes
- OS is read-only substrate
- NeBuLA owns all visual rendering
- Aether owns all CSS/design tokens

**Dependency graph:** Grimoire feeds all. Aether + NeBuLA → World. World ↔ sCoRE ↔ Agent/LLM ↔ OS. Memory (future) closes the observation loop.

→ Full doc for: member architecture details, local dev mocking, production versioning, post-Ep1 integration roadmap, Cloudflare R2 bundle specifics
