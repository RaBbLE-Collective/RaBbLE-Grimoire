# RaBbLE Integration Map — gist

> Cross-member data flow. How the organs connect.
> Regenerate: `bash spells/distill-gists.sh`

## Data Flow

```
User → World (web UI) → sCoRE (intent routing) → Claude/LLM (delegation)
                ↑                    ↑
            Aether (CSS)        OS (system state)
            NeBuLA (renderer)   Memory (future — observation store)
```

## Integration Patterns

| Pattern | From → To | Mechanism | Status |
|---|---|---|---|
| **Visual theming** | Aether → World, NeBuLA | CDN CSS bundle (`aether.css`) | Live |
| **Entity rendering** | NeBuLA → World | CDN IIFE (`nebula.iife.js`), `<rabble-entity>` web component | Live |
| **Intent routing** | World → sCoRE | HTTP/REST (World chat UI calls sCoRE API) | Planned (Ep1) |
| **LLM delegation** | sCoRE → Claude/Groq | Subprocess (Claude Code) or API (Groq/OpenRouter) | Planned (Ep1) |
| **System observation** | OS → sCoRE | Ambient data — system state queryable | Post-Ep1 |
| **Knowledge** | Grimoire → All | Filesystem refs; `spells/sync-grimoire.sh` copies shared docs | Live |
| **Pattern store** | sCoRE ↔ Memory | Observation → storage → retrieval | Concept (Echo 1+) |

## CDN Delivery Chain

```
Aether src/ → esbuild → aether.min.css → Cloudflare R2 → World <link>
NeBuLA src/ → esbuild → nebula.iife.js → Cloudflare R2 → World <script>
```

Local dev: `dev-serve.sh` mocks CDN. Pages link `aether.css` (not `.min.css`).

## Key Boundaries

- **World never imports source** — only CDN bundles from Aether and NeBuLA
- **sCoRE is the only member that calls external APIs** (LLMs, future services)
- **Grimoire never runs** — it's docs, spells, and registry only
- **OS provides ambient state** — sCoRE reads it, nothing writes to OS programmatically

→ Full detail: `RaBbLE-Agent/RaBbLE-Collective.md`, member CONTEXT.md files
