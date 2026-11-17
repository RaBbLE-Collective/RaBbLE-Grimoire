# RaBbLE-Versioning.md — Epochs, Echoes, Releases and Branches

```
harmonize ~ grimoire >> members carry semver, main carries stable tags, genesis is the origin // %VERSIONING_S323%
```

RaBbLE is **evolutionary**. Thresholds are named after they are crossed, not before. This doc gives shared language for "where are we" and one rule for "what code is running".

> **Changed S323 (Mark, 2026-11-11):** every member carries **semver**. `new-horizons` stays the working branch, `main` is stable and carries the release tags, and releases reach `main` through **release branches**. The current state of the Collective is to be released under the **Genesis** tag, which gives RaBbLE an origin. The five-slot version string is retired for members.
> **Changed S322:** Episodes are retired. Members plan by milestone. History: `log/EP1-AIR-CHECKLIST.md` (retired), `log/episodes/`.
> Lines marked **PROPOSED** are not ruled yet. Everything else is in force.

---

## 1. The ladder, smallest step first

| Step | What it is | Who moves | How it is named |
|---|---|---|---|
| **Event** | one commit | one member | the commit sha |
| **Release** | a member ships a version | one member, at its own pace | semver tag on `main`, `v0.3.1` |
| **Echo** | a set of member releases verified to work together | the Collective | `echo-N` (see section 5) |
| **Evolution** | a significant architectural or identity shift | the Collective | named |
| **Epoch** | the broadest era, named in hindsight | the Collective | named |

- The smallest step is an **Event** (a commit). The smallest step with a version number is a member **patch release**. An **Echo is the smallest step the whole Collective takes together**, not the smallest step overall.
- **Milestone** is the planning unit, not a step on this ladder. Each member has one, in `registry/epochs/current.epoch.yml` under `focus:`.
- Moving up the Collective tiers is still vibe-based: *does it feel crossed?* It is written down once it has been.

---

## 2. Member versions: semver

Every member has one version, `MAJOR.MINOR.PATCH`, exactly three numbers. npm and Cargo accept nothing else.

| Part | Raise it when |
|---|---|
| PATCH | a fix; nothing a client depends on changed |
| MINOR | something new, still compatible. While MAJOR is 0, a breaking change also raises MINOR |
| MAJOR | a contract break (section 6). Stays 0 through Epoch 0 |

Allowed extras, both standard semver:

- **Pre-release:** `0.2.0-rc.1`. Sorts before `0.2.0`.
- **Build metadata:** `0.2.0+4caa7d3`. Ignored when comparing versions; use it to stamp the commit into a build.

Rules:

1. **One source per member:** its native manifest (`package.json`, ESP-IDF `version.txt` or `PROJECT_VER`, OS `rabble_os_version`). A member with no native manifest, or with several (World, Grimoire, the Collective root, sCoRE), keeps a one-line `VERSION` file at its root, and its manifests follow that file. Nothing else states the version; other places read it.
2. **Every build can say what it is at runtime:** version plus commit sha. sCoRE on a version endpoint, NeBuLA and Aether in the bundle, Pocket in its firmware info, the OS in `os-release`. This is how "what code is running" gets answered.
3. **Git tags are `v` + the version** (`v0.2.0`). CDN paths use the same string.
4. The registry manifests (`registry/manifests/*.yml`) mirror the released version; they are not the source.

**Ruled (Mark, S323):** every member starts at `0.1.0` at Genesis. Tags from the old scheme (`v0.0.0.0.10`, `v0.0.0.0.1`, `echo-1.0` to `echo-3.0`, CDN `v0.0.0.1-rc.*`) stay as history and are not reused.

---

## 3. Branches and the release flow

| Branch | Role |
|---|---|
| `new-horizons` | The working branch in every member. All daily work lands here. |
| `release/X.Y.Z` | Cut from `new-horizons` to stabilise one release. Fixes only. |
| `main` | Stable. Only receives release branches, by pull request. Every commit on it is a tagged release. In RaBbLE-World a push to `main` deploys production. |
| `feature/*` | Optional and short-lived; rebased onto `new-horizons`. |

A release, step by step:

1. Cut `release/X.Y.Z` from `new-horizons`. Set the version in the member's manifest.
2. Stabilise on the release branch: fixes only, no new work.
3. Pull request `release/X.Y.Z` into `main`. Tag the merge `vX.Y.Z`.
4. Merge `main` back into `new-horizons`, so `main` never holds a commit the working branch lacks.
5. Delete the release branch. The tag is the record.

A fix to something already released: branch `release/X.Y.(Z+1)` from the tag on `main`, then steps 2 to 5.

RaBbLE-Chrysalis (the archive) works on `main` and has no releases.

---

## 4. Genesis: the origin

**Ruled (Mark, S323):** the current state of every member is released to `main` under the Genesis tag. Before Genesis, `main` is stale in every member (7 to 872 commits behind at 2026-11-11). After it, `main` is the stable line and RaBbLE has an origin to measure from.

**Shape** (origin and `0.1.0` ruled S323; the work is in `log/handoffs/HANDOFF-S323-Genesis-Release.md`):

- Each releasing member goes through section 3 once and lands on `main` with two tags on the same commit: its semver (`v0.1.0`) and `genesis`.
- The set is written to `registry/releases/genesis.yml` (section 5).
- **Genesis is an origin, not an Echo** (ruled S323: after Genesis the work is toward Echo 1, the first stable Echo). An Echo must be reproducible from scratch, and two pieces of that evidence are still open (`setup.sh` on a fresh VM, an OS fresh install). Genesis records what exists; Echo 1 follows when the evidence passes.
- Before each merge, reconcile the commits `main` has that `new-horizons` lacks (Aether 1, NeBuLA 1, Pocket 1, sCoRE 2, ScRiBbLE 1).

The arc name Genesis was recorded as crossed on 2026-11-09 (S318, `joinrabble.world` first deployed from `main`). The Genesis tag is the release that makes that crossing reproducible by name.

---

## 5. Echoes and the release record

An **Echo** is a claim: "these member versions were run together and work". The **release record** is the file that writes the claim down, so it can be checked later. (Earlier notes called this an "echo lock".)

```yaml
# registry/releases/genesis.yml  (PROPOSED format)
name: genesis
date: 2026-11-XX
verified_by: Mark
members:
  RaBbLE-sCoRE:  { version: 0.1.0, commit: abc1234 }
  RaBbLE-World:  { version: 0.1.0, commit: def5678 }
  RaBbLE-Aether: { version: 0.1.0, commit: 9abcdef }
contracts:
  score_api: v1
  entity: draft-10b
  palette: "1.0"
```

What it gives you:

- **What is in use:** compare a running service's reported version and sha with the record.
- **A way back:** check out every member at the recorded commits and you have that state again.
- **A compatibility statement:** two versions listed in the same record are known to work together. Versions not in a record are untested together.

An Echo needs: the record file, the tag `echo-N` on the recorded commit in every listed member, and a human saying "this works, mark it". Not CI.

**PROPOSED:** the Collective's own position is `Epoch.Evolution.Echo` (three numbers, `0.0.0` now). It is a position, not a package version; nothing is built from it.

---

## 6. What keeps members coherent

Contracts, not calendars. Members must agree on:

| Contract | Pinned where |
|---|---|
| sCoRE API and engine protocol version | sCoRE, and each client's config |
| Aether and NeBuLA bundle versions World loads | `RaBbLE-World/world/js/RaBbLE-config.js` |
| The entity (body, moves, palette tokens) | `log/plans/Unified-Entity/` now, `registry/entity/` once written |
| Palette | `RaBbLE-Agent/RaBbLE-Palette.md` |

Breaking a contract is allowed **at an Echo boundary only**, with a migration note, and raises the breaking member's MINOR (MAJOR after Epoch 0). Inside an Echo, contracts stay compatible.

Branch alignment is separate from versioning: members with `release_track: lockstep` in their manifest work on the epoch's `active_branch` and `spells/status.sh` flags any that are not; `independent` members are exempt.

---

## 7. Tier definitions

**Release:** a member's version is raised, tagged on `main`, and its milestone status says what shipped.

**Echo:** see section 5. Reproducible from scratch, human-verified, recorded, tagged.

**Evolution:** a qualitative change in how members interact, a core protocol, or identity. Named.

**Epoch:** usually a complete vertical slice of the system working. Named in hindsight.

---

## 8. Arc names (lore, not gates)

The Biblical arc is intentional lore. Do not neutralize it; do not schedule against it.

- **Genesis:** the beginning. The Collective is defined, the substrate exists, the entity first breathes. Crossed 2026-11-09; released as the Genesis tag (section 4).
- **Exodus:** emergence. The entity leaves concept for reality: observation, memory, the first closed behavioral loop.
- Later names (Covenant, Wilderness, Promised Land) are used as the work reaches them.

---

## 9. Current position

```
Epoch 0: Foundation
  Evolution 0: Scaffold
    Echo 0: Establishing  (in progress)
      Arc: Genesis crossed 2026-11-09; Genesis release pending; working toward Exodus
```

Authoritative position and per-member milestones: `registry/epochs/current.epoch.yml`.

---

## 10. Impulse vocabulary

| Verb | Tier it usually signals |
|---|---|
| `spark`, `ingest`, `mend`, `transcribe` | Event |
| `harmonize` | Event (brought into coherence) |
| `crystallize` | Echo |
| `evolve` | Evolution or Epoch landed |
