# versioning.md — gist

> Source: `RaBbLE-Versioning.md` | ~1471 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

RaBbLE is **evolutionary, not versioned** — thresholds are named retrospectively ("does it feel crossed?"), never planned. Versioning marks resonance thresholds and gives shared language for "where are we," not release gates.

**The Five Es** (smallest → largest: Event < Episode < Echo < Evolution < Epoch):

| Tier | Meaning | Analogy |
|---|---|---|
| **Event** | Single commit — smallest named thing | A note |
| **Episode** | Themed arc, ≥2 Events, recognizable end | A jam session |
| **Echo** | Stable, reproducible, git-tagged `echo-{N}.{minor}` | A recording |
| **Evolution** | Architectural/identity shift, ≥1 Echo | A new sound |
| **Epoch** | Broadest era, named retrospectively | An album |

**Version string:** `v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}` — drop trailing tiers when unknown (`v0.0.2`, `v0`). Echo-level id = `v{Epoch}.{Evolution}.{Echo}`.

**Lockstep model:** Episodes are Collective-wide sync points — all members air together, protocols/schemas/APIs guaranteed compatible *within* an Episode. **Echoes may break** (protocol bumps, migrations); they mark production-ready states. Plots = member-specific groupings within an Episode.

**Episode names follow a Biblical arc:** Episode 1 = **Genesis** (substrate + entity first breathes); Episode 2 = **Exodus** (memory + first closed behavioral loop).

**Current position:** `v0.0.0.0` — Epoch 0 (Foundation) · Evolution 0 (Scaffold) · Echo 0 (Establishing) · Episode 1 (Genesis, pending — not yet aired). Authoritative status: `registry/epochs/current.epoch.yml`.

→ Full doc for: per-tier boundary definitions, impulse→tier verb map (`spark`/`evolve`/`crystallize`), short-form/CONTEXT.md rules, post-Episode-1 weekly-cadence roadmap, full example timeline.
