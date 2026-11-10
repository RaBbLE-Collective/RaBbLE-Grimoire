# RaBbLE-Versioning — gist

> Source: `RaBbLE-Versioning.md` | ~1100 → ~300 tokens
> Hand-synced S322 (Episodes retired). Regenerate: `bash spells/distill-gists.sh versioning`

Versioning is evolutionary: thresholds are named after they are crossed. It is shared language, not a release gate.

| Tier | Meaning | Who moves |
|---|---|---|
| Event | a commit | one member |
| Release | a member ships something a user can reach | one member, own pace |
| Echo | stable, reproducible, human-verified, tagged `echo-{N}.{minor}` | the Collective together |
| Evolution | architectural or identity shift | the Collective |
| Epoch | broadest era, named in hindsight | the Collective |

- **Episodes are retired** (S322): no air date, no lockstep tag, no air checklist.
- **Milestone** is the planning unit: one per member in `registry/epochs/current.epoch.yml`.
- **Version string:** `v{Epoch}.{Evolution}.{Echo}.{Release}.{Event}`. First three slots are Collective-wide; the fourth is per member (`v0.0.0.1-rc.2`). Drop trailing tiers when unknown.
- **Coherence comes from contracts:** sCoRE API and protocol version, the Aether and NeBuLA bundle versions World pins, the entity rig, the palette. Break a contract only at an Echo boundary, with a migration note.
- **Branches:** `lockstep` members work on `new-horizons`; `main` is release, by pull request only.
- **Arc names are lore, not gates:** Genesis (crossed 2026-11-09), Exodus (now), then Covenant.

**Current position:** Epoch 0 Foundation · Evolution 0 · Echo 0 = `v0.0.0`.

→ Full doc for: tier definitions, the contract table, impulse-to-tier mapping
