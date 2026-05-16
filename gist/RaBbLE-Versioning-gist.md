# RaBbLE-Versioning — gist

> Source: `RaBbLE-Versioning.md` | ~1,471 → ~200 tokens
> Regenerate: `bash spells/distill-gists.sh`

**Philosophy:** RaBbLE is not versioned — it is evolutionary. Thresholds are named *after* they are crossed, not before. Versioning provides shared language for "where are we," not release gates.

**The Five Es** (smallest → largest):
| Tier | Name | Meaning |
|---|---|---|
| Event | Atomic unit | One commit |
| Episode | Narrative arc | Themed collection of Events — has a recognizable end |
| Echo | Stable state | Tagged, reproducible point — first broad stable release goal |
| Evolution | Shift | Architectural change — several Echoes cohere |
| Epoch | Era | Broadest threshold — named retrospectively, far future |

**Version string:** `v{Epoch}.{Evolution}.{Echo}.{Episode}`
- Current: `v0.0.0.0` (Epoch 0 · Evolution 0 · Echo 0 · Episode 1 pilot in progress)
- After Episode 1 airs: `v0.0.0.1` — all members simultaneously
- After Echo 1 (bigger goal release): `v0.0.1`

**Lockstep rule:** Episodes are Collective sync boundaries. All members tag at the same time. No member advances its version until the Collective broadcasts together.

**Boundary definition:** Movement between tiers is vibe-based — "does it feel crossed?" Not formula-driven.

→ Full doc for: tier boundary definitions, CDN path conventions, short-form rules, Event tracking
