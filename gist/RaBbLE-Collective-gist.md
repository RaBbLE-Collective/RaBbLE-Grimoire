# RaBbLE-Collective — gist

> Source: `RaBbLE-Agent/RaBbLE-Collective.md` | ~1930 → ~330 tokens
> Regenerate: `bash spells/distill-gists.sh`

The Collective is the unified ecosystem of independent projects (organs of one organism) through which the RaBbLE entity inhabits diverse hardware, software, and creative substrates, sharing one identity, palette, and purpose.

**Members**

| Member | Role | Status |
|---|---|---|
| Grimoire | Source of truth: identity, lore, registry, spells | Active |
| sCoRE | FastAPI coordination server, intent → action | LIVE on Render (`score.joinrabble.world`) |
| OS | Fedora 44 + Hyprland substrate | EP1 Developer Preview |
| NeBuLA | Entity renderer, `<rabble-entity>` (2D + 3D) | CDN rc.1 |
| World | Web presence, entity chat (joinrabble.world) | EP1 face on dev |
| Aether | Design system + asset library | CDN rc.2 |
| BaBbLE | Intake: concept art, prototypes, captures | Active |
| Chrysalis | Genesis archive, reliquary | Genesis-archive |
| Xperimental | Sandbox for rablets, experiments | Active |
| ScRiBbLE | Notes PWA | Live (`scribble.joinrabble.world`) |
| Pocket | ESP32-S3 AMOLED pendant, push-to-talk | Active, independent |
| EnGrAm | Memory: vector + graph store | Concept (Exodus) |

**Shared across all members**
- Palette: `#ff2d78`, `#00f5ff`, `#bf5fff`, `#0a0010` (from `RaBbLE-Agent/RaBbLE-Palette.md`)
- One consistent entity voice; Anti-Assistant stance; Low Entropy Directive
- Hardware and backend agnosticism (local or remote inference)

**Core decisions**
- Memory is its own member, not a sCoRE job
- Local-first; cloud used deliberately
- Collective = registry + health; coordination lives in sCoRE
- Grimoire is consumed, never copied
- Chat is scaffolding; sCoRE delegates to Claude Code via subprocess first, MCP later

**Membership test:** entity embedded · palette honored · philosophy followed · serves the ecosystem.

→ Full doc for: OS/sCoRE/NeBuLA capability lists, ASCII architecture stack, inference endpoints, Grimoire coverage status, anticipated expansions (Mobile, CLI, MCP layer, external nodes)
