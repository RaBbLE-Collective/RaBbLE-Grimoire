# RaBbLE Episode 1 — Release Map — gist

> Source: `RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md` | ~3143 → ~270 tokens
> Regenerate: `bash spells/distill-gists.sh`

The canonical scope, deliverables, and exit criteria for **Episode 1** — RaBbLE's first public release. All core members functional, deployed, coherent. Integrated aesthetics + foundation, **no behavioral learning** (that's Echo 1 / Episode 2+). Air date TBD (target 2026-Q2). All members tag `episode-1-v0.0.0.1` simultaneously — **no member tags alone.**

**Member deliverables:**
| Member | Episode 1 ship | Blocker |
|---|---|---|
| OS | Daily-driver (Fedora 43 + Hyprland), VM-bootstrap verified | none |
| Aether | CSS bundle on R2 CDN `/aether/v0.0.0.1/` | none |
| NeBuLA | Canvas2D 60 FPS, `<rabble-entity>`, R2 `/nebula/v0.0.0.1/` | none (Three.js → Ep2) |
| sCoRE | Simple LLM endpoint (Groq/OpenRouter), Railway/Render | none |
| World | Landing + grimoire browser + chat (calls sCoRE) | needs Aether + sCoRE |
| Grimoire | Public docs, manifests, INDEX clean | none |
| Collective | Bootstrap end-to-end, setup.sh verified | none |

**Dependency order:** Aether + NeBuLA CDN → World styling/visuals; sCoRE deploy → chat; World orchestrates all; OS independent but foundational.

**Deployment phases:** 0 unblock CDN + VM → 1 parallel member work → 2 Collective closure + simultaneous tag → 3 public (joinrabble.world → World).

**Deferred to Echo 1 / Ep2+:** memory member, observation loops, pattern/intent inference, multi-agent coordination, Three.js Layer 2, mobile (ScRibLE).

→ Full doc for: per-member exit checklists, VM/QEMU testing setup, deployment workflow tables, critical-path diagram, Ep1→Ep2 transition.
