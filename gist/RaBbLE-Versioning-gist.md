# RaBbLE-Versioning — gist

> Source: `RaBbLE-Versioning.md` | ~1700 → ~330 tokens
> Hand-synced S323 (semver, release branches, Genesis). Regenerate: `bash spells/distill-gists.sh versioning`

Versioning is evolutionary: thresholds are named after they are crossed.

| Step (smallest first) | Meaning | Named by |
|---|---|---|
| Event | a commit | sha |
| Release | a member ships a version, at its own pace | semver tag on `main`, `v0.3.1` |
| Echo | member releases verified to work together, by a human | `echo-N` + a release record |
| Evolution | architectural or identity shift | name |
| Epoch | broadest era, named in hindsight | name |

- **Members carry semver** (`MAJOR.MINOR.PATCH`, three numbers; `-rc.1` and `+sha` allowed). One source per member: its native manifest, or a root `VERSION` file where there is none or several. Every build reports version and commit at runtime. The five-slot string is retired.
- **Branches:** work on `new-horizons`. Cut `release/X.Y.Z`, stabilise, pull request into `main`, tag `vX.Y.Z`, merge `main` back. `main` is stable and every commit on it is a tagged release.
- **Genesis** (ruled S323, pending): the current state of every member released to `main` under the `genesis` tag. Genesis is Echo 1 (ruled S324), `0.1.0` for every member; Echo 2 is `0.2.0`. Versions move at gates only; between gates the work is commits, and builds tracking `new-horizons` stamp `-dev+sha` (not built yet).
- **Release record:** `registry/releases/<name>.yml` lists each member's version and commit, so what is running can be checked and a state can be returned to.
- **Milestone** is the planning unit: one per member in `registry/epochs/current.epoch.yml`. Episodes are retired.
- **Coherence comes from contracts** (sCoRE API, pinned Aether and NeBuLA bundles, the entity, the palette). Break one only at an Echo boundary.
- **Arc names are lore, not gates:** Genesis (crossed 2026-11-09), Exodus (now), then Covenant.

**Current position:** Epoch 0 Foundation · Evolution 0 · Echo 0.

→ Full doc for: the release steps, the record format, what is ruled versus proposed
