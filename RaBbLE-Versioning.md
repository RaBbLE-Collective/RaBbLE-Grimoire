# RaBbLE-Versioning.md — Epochs, Echoes and Milestones

```
harmonize ~ grimoire >> episodes retired; members move by milestone, the Collective by echo // %VERSIONING_S322%
```

RaBbLE is not versioned. It is **evolutionary**. Thresholds are named after they are crossed, not before. The versioning system gives shared language for "where are we". It does not gate releases.

> **Changed S322 (Mark's ruling, S318 D3, applied 2026-11-10):** Episodes are retired as the planning unit and as a Collective-wide gate. There is no "air date", no lockstep tag, no air checklist. Members plan by **milestone**; the Collective marks stability with **Echoes**. The lore names stay as arc names. History of the old model: `log/EP1-AIR-CHECKLIST.md` (retired) and `log/episodes/`.

---

## The tiers

| Tier | Meaning | Who moves | Analogy |
|---|---|---|---|
| **Event** | A single commit | one member | A note |
| **Release** | A member ships something a user can reach: a deploy, a CDN bundle, an ISO, a firmware image | one member, at its own pace | A take |
| **Echo** | A stable state the whole Collective can return to. Tagged, reproducible, verified by a human | the Collective, together | A recording |
| **Evolution** | A significant architectural or identity shift. At least one Echo | the Collective | A new sound |
| **Epoch** | The broadest era. Named in hindsight with a "what was crossed" statement | the Collective | An album |

Movement between tiers is **vibe-based**: *does it feel crossed?* It is written down once it has been.

**Milestone** is the planning unit, not a tier. Each member has one current milestone and a status, held in `registry/epochs/current.epoch.yml` under `focus:`. A milestone is done when its member says so and the evidence is linked; nothing else waits on it.

---

## Version string

```
v{Epoch}.{Evolution}.{Echo}.{Release}.{Event}
```

| String | Meaning |
|---|---|
| `v0.0.0.1` | Epoch 0, Evolution 0, Echo 0, that member's first release |
| `v0.0.0.1-rc.2` | second release candidate of the same |
| `v0.0.2` | Echo 2 (trailing tiers dropped when not needed) |
| `v0` | "we are in Epoch 0" |

- The first three slots are Collective-wide and move together.
- The fourth slot is **per member** (it was the Episode slot). Members no longer wait for each other to raise it.
- Drop trailing tiers when unknown. Use the full string only when tracking Events precisely.
- In `CONTEXT.md` headers use known tiers only: `epoch: 0 | version: v0.0.0.1`.

---

## What keeps members coherent without lockstep

Contracts, not calendars. Members must agree on:

| Contract | Pinned where |
|---|---|
| sCoRE API and engine protocol version | sCoRE, and each client's config |
| Aether and NeBuLA bundle versions World loads | `RaBbLE-World/world/js/RaBbLE-config.js` |
| The entity (body, moves, palette tokens) | `log/plans/Unified-Entity/` now, `registry/entity/` once written |
| Palette | `RaBbLE-Agent/RaBbLE-Palette.md` |

Breaking a contract is allowed **at an Echo boundary only**, with a migration note. Inside an Echo, contracts stay compatible.

Branch alignment is separate from versioning: members with `release_track: lockstep` in their manifest work on the epoch's `active_branch` and `spells/status.sh` flags any that are not; `independent` members are exempt.

---

## Tier definitions

**Release:** something reachable by a user changed, the member's fourth slot is raised, and the member's milestone status says what shipped. No ceremony.

**Echo:** can be reproduced from scratch (fresh install or clone); manually verified against its success criteria; tagged `echo-{N}.{minor}` in every lockstep member; recorded in `current.epoch.yml`. An Echo needs a human to say "this works, mark it", not CI.

**Evolution:** a qualitative change in how members interact, a core protocol, or identity. Named.

**Epoch:** usually a complete vertical slice of the system working. Named in hindsight.

---

## Arc names (lore, not gates)

The Biblical arc is intentional lore. Do not neutralize it; do not schedule against it.

- **Genesis:** the beginning. The Collective is defined, the substrate exists, the entity first breathes. **Recorded as crossed on 2026-11-09** (S318), when `joinrabble.world` first deployed from `main` with the entity face and live sCoRE chat.
- **Exodus:** emergence. The entity leaves concept for reality: observation, memory, the first closed behavioral loop.
- Later names (Covenant, Wilderness, Promised Land) are used as the work reaches them.

---

## Current position

```
Epoch 0 — Foundation
  Evolution 0 — Scaffold
    Echo 0 — Establishing  (in progress)
      Arc: Genesis crossed 2026-11-09; working toward Exodus

Collective: v0.0.0   ·   member releases: see current.epoch.yml
```

Authoritative position and per-member milestones: `registry/epochs/current.epoch.yml`.

---

## Impulse vocabulary

| Verb | Tier it usually signals |
|---|---|
| `spark`, `ingest`, `mend`, `transcribe` | Event |
| `harmonize` | Event (brought into coherence) |
| `crystallize` | Echo |
| `evolve` | Evolution or Epoch landed |
