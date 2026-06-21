# versioning.md — gist

> Source: `RaBbLE-Versioning.md` | ~1471 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

RaBbLE is **evolutionary, not versioned** — thresholds are named *after* they're crossed (retrospective), not planned. Movement between tiers is vibe-based: *does it feel crossed?*

**The Five Es** (smallest → largest: Event < Episode < Echo < Evolution < Epoch):

| Tier | Meaning | Analogy |
|---|---|---|
| **Event** | A single commit | A note |
| **Episode** | Themed arc of Events; Collective-wide sync point | A jam session |
| **Echo** | Stable, reproducible, git-tagged state | A recording |
| **Evolution** | Architectural/identity shift; ≥1 Echo | A new sound |
| **Epoch** | Broadest era; named retrospectively | An album |

**Version string:** `v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}`
- `v0.0.0.1.23` = full · `v0.0.2` = Echo-level · `v0` = "in Epoch 0"
- Drop trailing tiers when unknown/unimportant.

**Lockstep model:** All members advance to the same Episode together. Within an Episode, protocols/schemas/APIs stay **compatible**. **Echoes can break** APIs (with migration guides). **Plots** = member-specific groupings within an Episode.

**Episode names follow a Biblical arc:** Genesis (Ep1, current) → Exodus (Ep2: memory + closed loop) → onward.

**Impulse → tier:** `spark`/`ingest`/`mend`/`transcribe` = Event · `harmonize` = Event/Episode · `evolve` = Evolution · `crystallize` = Echo.

**Current position:** Epoch 0 (Foundation) · Evolution 0 (Scaffold) · Echo 0 (Establishing, in progress) · Episode 1 (Genesis, pending — not yet aired). Version: **v0.0.0.0**. Authoritative state: `registry/epochs/current.epoch.yml`.

→ Full doc for: per-tier boundary definitions, short-form rules, CONTEXT.md header conventions, the post-Episode-1 weekly-cadence roadmap, and the example future timeline.
