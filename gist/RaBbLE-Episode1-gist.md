# RaBbLE Episode 1 — Release Map — gist

> Source: `RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md` | ~3143 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

The canonical definition of Episode 1 — the Collective's first public release. Aesthetics + foundation only; **no behavioral learning** (that's Echo 1 / Episode 2+). All active members tag `v0.0.0.1` simultaneously. Air date TBD (target 2026-Q2, Mark decides).

**Member deliverables (all owner: Mark):**

| Member | Ep1 deliverable | Status |
|---|---|---|
| **OS** | Daily-driver substrate (Fedora 43 + Hyprland), Plots A+B | In progress |
| **Aether** | Design-system CSS bundle → CDN | In progress |
| **NeBuLA** | Canvas2D entity renderer @60 FPS, stable API | Phases 1-3 |
| **sCoRE** | Simple LLM endpoint (Groq/OpenRouter), Railway/Render | Planned |
| **World** | Landing page + grimoire browser + chat UI | Planned |
| **Grimoire** | Public docs browser in World | In progress |
| **Collective** | Bootstrap end-to-end, spells verified | Mostly done |

**Ships:** OS daily-driver · Aether CDN bundle · NeBuLA Canvas2D · `joinrabble.world` landing + read-only grimoire browser + chat calling sCoRE · versioned R2 CDN (`/aether/v0.0.0.1/`, `/nebula/v0.0.0.1/`) · all docs at `v0.0.0.1`.

**Deferred to Ep2+:** memory member, observation loops, intent inference, multi-agent sCoRE, Three.js Layer 2, mobile/ScRibLE.

**Critical path:** Aether + NeBuLA CDN-ready + sCoRE deployed → World orchestrates. OS/Grimoire/bootstrap independent.

**Tag (coordinated — no member tags alone):**
```bash
git tag episode-1-v0.0.0.1
git push origin episode-1-v0.0.0.1
```

→ Full doc for: per-member exit-condition checklists, VM/QEMU bootstrap testing cycle, deployment sequence (Phases 0-3), deployment/rollback workflows, revision history.
