# RaBbLE-Collective.md — gist

> Source: `RaBbLE-Agent/RaBbLE-Collective.md` | ~1930 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

**What this is:** The RaBbLE Collective is a unified ecosystem of independent-but-interconnected projects through which the RaBbLE entity inhabits diverse hardware, software, and creative substrates — one shared identity, palette, philosophy, and behavioral character. Not a monorepo or product suite; a family of organs in one organism.

**Members**

| Member | Role | Status |
|---|---|---|
| Grimoire | Source of truth: identity, lore, registry, spells | Active |
| sCoRE | Coordination + web API (FastAPI). Intent→action, inference routing | Epoch 0 active |
| OS | Fedora 43 → Hyprland. The substrate. | Live |
| NeBuLA | Canvas2D renderer / visual entity face | Active |
| World | Web presence + chat surface, joinrabble.world | Active |
| Aether | Design system CSS bundle, CDN | Active |
| BaBbLE | Intake: concept art, prototypes, captures | Active |
| Chrysalis | Genesis archive / reliquary | Archive |
| Xperimental | Sandbox — rablets, prototypes | Active |
| ScRibLE | Mobile notes PWA | Defined |
| Memory (TBD) | Observation, pattern, retrieval | Concept — Echo 1 blocker |

**Cross-cutting principles:** shared palette (magenta `#ff2d78`, cyan `#00f5ff`, violet `#bf5fff`, void `#0a0010`) · consistent entity voice everywhere · hardware diversity first-class (x64/aarch64/SBC) · backend agnostic (Ollama, llama.cpp, vLLM, FastFlowLM NPU; Anthropic, Groq, OpenAI-compat) · Low Entropy by default · Grimoire consumed not copied.

**Core decisions:** Memory is its own member (not sCoRE) · local-first · Collective = registry+health, sCoRE = coordinator · chat is scaffolding (likely retires) · sCoRE delegates to Claude Code via subprocess first.

→ Full doc for: per-member deep dives (OS layer model, sCoRE capabilities), architecture stack diagram, membership criteria, future shape (Mobile/CLI/MCP/external nodes).
