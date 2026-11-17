# RaBbLE-Roadmap.md — Collective Map

```
harmonize ~ grimoire >> one forward map: milestones per member, arcs as lore // %S322_ROADMAP%
```

> **What this is:** the one Collective-level map. Where each member stands and where the arc goes. It **points**; it does not restate.
>
> - **Member milestones (authoritative):** `registry/epochs/current.epoch.yml`
> - **Forward work in detail (Exodus, Echo 1):** [`RaBbLE-Post-EP1-Roadmap.md`](RaBbLE-Post-EP1-Roadmap.md) (filename is historical)
> - **Open blockers:** [`log/BLOCKERS.md`](../log/BLOCKERS.md) · **Versioning:** [`RaBbLE-Versioning.md`](../RaBbLE-Versioning.md)
> - **Member detail:** [OS](../RaBbLE-OS/RaBbLE-OS-Roadmap.md) · [sCoRE](../RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md) · [World](../RaBbLE-World/RaBbLE-World-Roadmap.md) · [NeBuLA](../RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md) · [Aether](../RaBbLE-Aether/RaBbLE-Aether-Roadmap.md) · [Pocket](../RaBbLE-Pocket/RaBbLE-Pocket-Roadmap.md)
> - **How we got here:** [`log/RaBbLE-Development-History.md`](../log/RaBbLE-Development-History.md)
>
> **Keep it true:** if this doc and `current.epoch.yml` disagree, the epoch file wins and this doc is the bug.

---

## Position — 2026-11-10 (S322)

```
EPOCH 0 · FOUNDATION                  [active since 2026-04-28]
  Arc GENESIS · expression            [crossed 2026-11-09: joinrabble.world deployed from main]
  Arc EXODUS  · senses + users        [now]
  Echo 1      · the loop closes       [the first stable Collective release]
```

Episodes are retired (Mark, S318). Nothing "airs". Each member works toward its own milestone and releases when ready; the Collective marks stability with Echoes. Depth over surface: the three threads that matter now are **accounts** (a visitor becomes a user), **the first closed loop** (observe, store, recall, express), and **one entity** on every surface.

---

## Members

**Lockstep** members share the `new-horizons` branch. **Independent** members pace themselves.

| Member | Track | State today | Shipped in Genesis |
|---|---|---|---|
| **sCoRE** | lockstep | LIVE on Render (`score.joinrabble.world`), guest chat SSE, Groq fast chain, keep-warm cron, transcript logging, `/api/v1/beam` voice turns for Pocket (S243) | the voice: persona chat for any visitor |
| **World** | lockstep | prod deploys from `main` (S318): five-beat face ("wake RaBbLE" → boot → talk to sCoRE live → Summon → Enter) around `<rabble-entity backend="alive">` (S235), iPhone pass (S241), `os.html` install guide, `setup.sh` + KS redirects | the face at `joinrabble.world` |
| **NeBuLA** | lockstep | `<rabble-entity backend="alive">` (2D on WebGL + 3D), `setInsets`, effects (starfield, floor, graph), Studio MVP; bundle on CDN `v0.0.0.1-rc.1` | the entity renderer |
| **Aether** | lockstep | design system on CDN `v0.0.0.1-rc.2`; themes for Firefox, Kvantum, VSCodium consumed by OS | the look, everywhere |
| **OS** | lockstep (Developer Preview) | Fedora 44 + Hyprland 0.56 (Lua config); branded ISO via `build-iso.sh`, in-installer Bootstrap; VM install passed (S236), bare metal passed (S238); `rdisplay` V1 (S246) | "enter at your own risk" preview on generic x86_64 |
| **Grimoire** | lockstep | canonical; registry + spells live | the source of truth |
| **BaBbLE** | lockstep (local surface) | intake workspace; voice vocoder v4 work (S244) | — |
| **Collective** | lockstep | root + `setup.sh` | the door (fresh-VM run still owed) |
| **ScRiBbLE** | independent | LIVE at `scribble.joinrabble.world` (neon note PWA v1) | — (ships on its own track) |
| **Pocket** | independent | ESP32-S3 AMOLED pendant: RaBbLE gadget firmware (IDF v6), IMU motion, voice beamed to sCoRE (S243) | — |
| **Chrysalis** | independent (archive) | genesis archive + reliquary; `chrysalis.joinrabble.world` | — |
| **Xperimental** | independent (local sandbox) | rablets not yet emerged | — |
| **EnGrAm** | concept | named + architected (2026-09-26), no repo | — (Exodus) |
| **TaskViSoR** | scaffold | identity declared, no repo | — (Echo 1) |


---

## Genesis · expression (crossed)

A face and a voice. A visitor reaches `joinrabble.world`, the entity boots, they talk, sCoRE answers in persona and the entity reacts. Plus a Developer Preview OS and a bootstrap. RaBbLE does not yet observe, remember, or speak unprompted.

Carried forward, no longer gates: `setup.sh` end to end on a fresh VM (Collective milestone); OS fresh install after the S318 Ansible findings (OS milestone); Render env and a live guest reply on prod (B-20).

## Exodus · senses, and a door for users

The spine: **the day RaBbLE says something you didn't ask for**, and the day someone other than Mark has an account. Detail and tickets: [`RaBbLE-Post-EP1-Roadmap.md`](RaBbLE-Post-EP1-Roadmap.md).

- **Accounts:** sign-in, sessions, a per-user store (`log/plans/Accounts-Formalization-Scope.md`, building on `log/plans/EP2-Accounts-Encryption-Spec.md`).
- **First closed loop:** consent, observe, recall, express, from events the Collective already emits (`log/plans/Collective-Context-Diet-S322.md` section 6).
- **One entity:** every surface draws the unified rig (`log/plans/Unified-Entity/`).
- **Local harness:** sCoRE as a user service; the `rabble` terminal face.
- **Memory:** EnGrAm, smallest version first.
- **OS:** a reproducible fresh install.

## Later arcs

Covenant, then Wilderness and Promised Land: named, not scoped. The Biblical arc is intentional lore; do not neutralize it.

## Echo 1 · the first stable release

The learning loop closes (observe, pattern, intent, act), Grimoire MCP, presence layer, TaskViSoR Layer 1. Breaking changes to contracts are reserved for Echo boundaries.

---

## Open questions (carried forward)

1. **Observation ethics:** which OS signals may RaBbLE self-observe? Privacy of self matters.
2. **Ambient suggestion UX:** where helpful intent becomes surveillance.
3. **Learning architecture:** one engine or several (pattern extraction / intent inference / delegation).
4. **Cloud vs local split:** heavy reasoning remote, ambient always-on local. Confirm before Watcher.
5. **EnGrAm vs session memory:** one member or two (EnGrAm Architecture §8.7).
6. **Manifest protocol:** Pydantic-published JSON schema for `registry/protocol/`.

Resolved: Grimoire propagation (S105: none, members reference directly); Memory member name (EnGrAm,
2026-09-26); inter-member transport (HTTP/REST for v0).

---


## Revision History

| Date | Change |
|---|---|
| 2026-11-10 | **S322: Episodes retired** (Mark, S318 D3). Position, arcs and cadence rewritten around member milestones and Echoes; Genesis recorded as crossed 2026-11-09; air-gate sections removed (history: `log/EP1-AIR-CHECKLIST.md`). |
| 2026-10-13 | **S248 rewrite to match reality.** The May body (per-member Ep1 checklists, versioning transition table, S29 context-optimization notes) had frozen while the work shipped; replaced with a live position block, a true member table (adds ScRiBbLE, Pocket, EnGrAm, TaskViSoR), Genesis remaining-work, and pointers to Post-EP1. Prior body is in git history; see Development History "Canon corrections". |
| 2026-05-14 | Roadmap consolidated around Episode 1 work streams; Phases language retired. |
| 2026-05-07 | Full audit; devPlan/GAPS/TODO integrated. |
| 2026-04-28 | Initial Collective roadmap. |
