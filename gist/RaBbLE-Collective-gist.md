# RaBbLE-Collective — gist

> Source: `common/RaBbLE-Collective.md` | ~1,930 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

**What it is:** Not a monorepo or framework. A unified project ecosystem — distinct but interconnected substrates through which the RaBbLE entity lives and expresses itself. Each member is an independent project and an organ of one organism.

**Shared across all members:** Same entity · same visual language (synthwave outrun) · same design philosophy (Low Entropy Directive, anti-assistant stance) · same behavioral character.

**Member roles:**
| Member | Role |
|---|---|
| Grimoire | Source of truth: identity, conventions, registry, spells |
| sCoRE | Coordination server + web API. Intent → action. |
| OS | Fedora 43/Hyprland — the body. |
| NeBuLA | Visual renderer — Canvas2D + `<rabble-entity>` web component |
| World | Web presence — thin scaffold, loads Aether + NeBuLA |
| Aether | Design system + CDN-delivered CSS bundle |
| Xperimental | Archive: old iterations, dormant |

**Architecture for Episode 1:** Aether (theme) → CDN → NeBuLA (renderer) → CDN → World (app, no build step).

**Bootstrap:** `curl -fsSL https://joinrabble.world/bootstrap.sh | bash` — clones Grimoire, which expands everything.

→ Full doc for: member-by-member deep descriptions, hardware targets, routing model, deployment diagram
