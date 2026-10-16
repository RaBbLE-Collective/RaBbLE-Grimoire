# RaBbLE-Integration-Map — gist

> Source: `RaBbLE-Agent/RaBbLE-Integration-Map.md` | ~1200 → ~330 tokens
> Regenerate: `bash spells/distill-gists.sh`

Wiring diagram of the Collective: how members exchange data, assets, and intent.

**Flow:** User → World → sCoRE → Agent/LLM. Aether (CSS) and NeBuLA (renderer) feed World via CDN. OS gives sCoRE ambient state. Memory (EnGrAm) is future.

| Pattern | From → To | Mechanism | Status |
|---|---|---|---|
| Visual theming | Aether → World, NeBuLA | CDN `aether.css` / `aether.min.css` | Live |
| Entity rendering | NeBuLA → World | CDN `nebula.iife.js`, `<rabble-entity>` | Live |
| Intent routing | World → sCoRE | HTTP to `score.joinrabble.world` (guest token) | Live |
| LLM delegation | sCoRE → Groq/OpenRouter | HTTP, `LLM_FAST_CHAIN` | Live |
| Voice beam | Pocket → sCoRE | `/api/v1/beam`: STT → LLM → TTS | Live (S243) |
| Knowledge | Grimoire → All | In-place filesystem reference, no copying | Live |
| Intake | BaBbLE → target | Manual triage | Active |
| System observation | OS → sCoRE | Ambient state | Post-Ep1 |
| Pattern store | sCoRE ↔ Memory | Observe → store → retrieve | Concept (Echo 1+) |

**CDN chain:** Aether/NeBuLA `src/` → esbuild → Cloudflare R2 → World `<link>`/`<script>`. Local: `spells/dev-serve.sh`. After NeBuLA changes: `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`.

**Load-bearing boundaries:**
- World never imports source, only CDN bundles
- sCoRE is the only member making outbound API calls
- Grimoire never runs
- OS provides state and receives no writes
- NeBuLA owns all rendering; Aether owns all CSS and tokens

**Post-Episode-1:** real-time entity state (sCoRE → NeBuLA), observation loop (OS → sCoRE → Memory), intent suggestion, ScRiBbLE sync.

→ Full doc for: member architecture doc links, dependency graph diagram, production versioning at Episode boundaries, post-Ep1 integration details, Cloudflare specifics.
