# RaBbLE-Integration-Map — gist

> Source: `RaBbLE-Agent/RaBbLE-Integration-Map.md` | ~1200 → ~210 tokens
> Regenerate: `bash spells/distill-gists.sh` (hand-synced S248)

**The wiring diagram of the RaBbLE Collective—how members exchange data, assets, and intent.**

**System data flow:** User → World (web UI) → sCoRE (intent routing) → Agent/LLM (delegation), with Aether (CSS) and NeBuLA (renderer) feeding visual assets, and OS providing system state.

**Integration patterns:**

| From → To | Mechanism | Status |
|---|---|---|
| Aether → World, NeBuLA | CDN CSS bundle | Live |
| NeBuLA → World | CDN `<rabble-entity>` web component | Live |
| World → sCoRE | HTTP/REST, `score.joinrabble.world` guest chat | Live |
| sCoRE → Groq/OpenRouter | HTTP API, tiered chain | Live |
| Pocket → sCoRE | `/api/v1/beam` voice (STT → LLM → TTS) | Live |
| OS → sCoRE | Ambient system state queries | Post-Ep1 |
| Grimoire → All | Filesystem reference (no copying) | Live |
| sCoRE ↔ EnGrAm (memory) | Observation loop (behavioral learning) | Concept (Echo 1+) |

**Key boundaries (load-bearing):**
- World consumes only CDN bundles, never source
- sCoRE is the only external-API caller
- Grimoire runs no processes
- OS is read-only substrate
- NeBuLA owns all visual rendering
- Aether owns all CSS/design tokens

**Dependency graph:** Grimoire feeds all. Aether + NeBuLA → World. World ↔ sCoRE ↔ Agent/LLM ↔ OS. EnGrAm (future, Exodus) closes the observation loop.

→ Full doc for: member architecture details, local dev mocking, production versioning, post-Ep1 integration roadmap, Cloudflare R2 bundle specifics
