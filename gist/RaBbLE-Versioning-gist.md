# RaBbLE-Versioning — gist

> Source: `RaBbLE-Versioning.md` | ~1471 → ~420 tokens
> Regenerate: `bash spells/distill-gists.sh`

RaBbLE versioning is evolutionary, not semantic: thresholds are named retrospectively after they're crossed, as shared language for "where are we," not as release gates.

**The Five Es (smallest → largest)**

| Tier | Meaning | Analogy |
|---|---|---|
| Event | A single commit | A note |
| Episode | Narrative arc with a dominant theme, ≥2 Events, written summary in CONTEXT.md | A jam session |
| Echo | Stable, reproducible, manually verified, tagged `echo-{N}.{minor}` | A recording |
| Evolution | Significant architectural or identity shift, ≥1 Echo | A new sound |
| Epoch | Broadest era, named retrospectively | An album |

- Movement between tiers is vibe-based: *does it feel crossed?*
- Version string: `v{Epoch}.{Evolution}.{Echo}.{Episode}.{Event}`, for example `v0.0.0.1.23`
- Drop trailing tiers when they are unknown (`v0.0.2`, `v0`)

**Lockstep model**

- Events and Plots are member-specific.
- Episodes are Collective-wide: all members air together, and protocols and schemas stay stable within an Episode.
- Echoes may introduce breaking changes, with migration notes in the next Episode's entry.
- Before Episode 1, no member advances past v0.0.0.0. When it airs, all members jump together (Mark decides when; the air gate is `log/EP1-AIR-CHECKLIST.md`).
- Episode names follow a Biblical arc: Genesis (Episode 1), Exodus (Episode 2: memory and the first observation loop), and so on.

**Current position:** Epoch 0 Foundation · Evolution 0 Scaffold · Echo 0 Establishing · Episode 1 Genesis (pending) = `v0.0.0.0`

**Impulses → tier**

| Verb | Tier |
|---|---|
| `spark`, `ingest`, `mend`, `transcribe` | Event |
| `harmonize` | Event/Episode |
| `evolve` | Evolution |
| `crystallize` | Echo |

→ Full doc for: tier boundary definitions in full, the example future timeline, weekly-Episode cadence option, short-form rules for CONTEXT.md headers, `registry/epochs/current.epoch.yml` pointer.
