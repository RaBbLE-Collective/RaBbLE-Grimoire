# RaBbLE-Integration-Map.md — Cross-Member Data Flow

```
spark ~ grimoire >> mapping how the organs connect // %INTEGRATION_MAP%
```

> How members exchange data, assets, and intent. The wiring diagram of the Collective.
> For member roles and descriptions: `RaBbLE-Agent/RaBbLE-Collective.md`
> For deployment details: `RaBbLE-Collective/RaBbLE-Deployment-Architecture.md`

---

## System Data Flow

```
User → World (web UI) → sCoRE (intent routing) → Claude/LLM (delegation)
                ↑                    ↑
            Aether (CSS)        OS (system state)
            NeBuLA (renderer)   Memory (future — observation store)
```

**Read this as:** The user interacts through World. World routes intent to sCoRE. sCoRE delegates to LLMs or other members. Aether and NeBuLA feed visual assets into World via CDN. OS provides ambient system state to sCoRE. Memory (future) will close the observation loop.

---

## Integration Patterns

Each pattern describes how one member's output becomes another member's input.

| Pattern | From → To | Mechanism | Status |
|---|---|---|---|
| **Visual theming** | Aether → World, NeBuLA | CDN CSS bundle (`aether.css` / `aether.min.css`) | Live |
| **Entity rendering** | NeBuLA → World | CDN IIFE bundle (`nebula.iife.js`), `<rabble-entity>` web component | Live |
| **Intent routing** | World → sCoRE | HTTP/REST — World chat UI calls sCoRE API endpoint | Planned (Ep1) |
| **LLM delegation** | sCoRE → Claude/Groq | Subprocess (Claude Code CLI) or HTTP API (Groq/OpenRouter) | Planned (Ep1) |
| **System observation** | OS → sCoRE | Ambient data — system state queryable by sCoRE | Post-Ep1 |
| **Knowledge distribution** | Grimoire → All | Filesystem refs; `spells/sync-grimoire.sh` copies `RaBbLE-Agent/` to member `grimoire/` dirs | Live |
| **Pattern store** | sCoRE ↔ Memory | Observation → storage → retrieval — the behavioral learning loop | Concept (Echo 1+) |
| **High-entropy intake** | BaBbLE → target member | Manual triage — prototypes mature and migrate to their target member | Active |

---

## CDN Delivery Chain

Aether and NeBuLA ship as CDN-distributed bundles. World consumes them — it never imports source.

```
Aether src/ → esbuild → aether.min.css → Cloudflare R2 → World <link>
NeBuLA src/ → esbuild → nebula.iife.js → Cloudflare R2 → World <script>
```

**Local development:** `dev-serve.sh` mocks CDN paths locally. HTML pages link `aether.css` (unminified), not `aether.min.css`. After NeBuLA source changes: `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`.

**Production:** Versioned bundles on Cloudflare R2. Version bumps happen at Episode boundaries — all members consume the same tagged version.

---

## Key Boundaries

These boundaries are load-bearing architectural decisions, not suggestions.

- **World never imports source** — only CDN-distributed bundles from Aether and NeBuLA. World is a thin scaffold: state management and assembly, not rendering or styling.
- **sCoRE is the only member that calls external APIs** — LLMs (Groq, OpenRouter, Claude), future external services. No other member makes outbound API calls.
- **Grimoire never runs** — it produces docs, spells, and registry data. It is not a service, does not start processes, and has no runtime dependencies.
- **OS provides ambient state, receives no writes** — sCoRE reads system state from OS observation points. Nothing writes to OS programmatically. OS is the substrate, not a managed service.
- **NeBuLA owns all visual rendering** — entity animation, Canvas2D/Three.js, Flat-Chaos runtime. World assembles NeBuLA output but never renders directly.
- **Aether owns all CSS** — palette, typography, components, layout. Members consume Aether's bundle; they never define their own design tokens.

---

## Dependency Graph

```
                    Grimoire (knowledge)
                   ╱    |    ╲
                  ╱     |     ╲
    Aether (CSS) ──→ World ←── NeBuLA (renderer)
                       ↕
                    sCoRE (intent routing)
                       ↕
                    Claude/LLM
                       ↕
                    OS (substrate)
                       ↕
                    Memory (future)
```

**Arrows = data flow direction.** Grimoire feeds knowledge to all. Aether and NeBuLA feed assets to World. World exchanges intent with sCoRE. sCoRE delegates to LLMs and reads from OS. Memory will close the loop between sCoRE and long-term observation.

---

## Post-Episode-1 Integration Points

These integrations don't exist yet but are architecturally planned:

| Integration | Members | What It Enables |
|---|---|---|
| **Real-time entity state** | sCoRE → NeBuLA (via World) | Entity visual state reflects sCoRE's inference — mood, attention, activity |
| **Observation loop** | OS → sCoRE → Memory | System signals (active window, typing cadence, idle state) become patterns |
| **Intent suggestion** | Memory → sCoRE → World | Past patterns surface as suggested actions without being asked |
| **ScRibLE sync** | ScRibLE → sCoRE | Mobile input (handwritten notes, sketches) becomes intent data |

---

```
spark ~ grimoire >> the wiring diagram is the nervous system // %INTEGRATION_MAP%
```
