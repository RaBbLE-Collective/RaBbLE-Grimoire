# RaBbLE-Roadmap.md — Collective Episode Map

```
transcribe ~ grimoire >> the map redrawn to match the territory // %S248_ROADMAP_TRUTH%
```

> **What this is:** the one Collective-level map. Where each member stands, what Episode 1 (Genesis)
> actually ships, and the arc after it. It **points**; it does not restate.
>
> - **Air gate (live, gate by gate):** [`log/EP1-AIR-CHECKLIST.md`](../log/EP1-AIR-CHECKLIST.md)
> - **Forward work after air (Exodus, Echo 1):** [`RaBbLE-Post-EP1-Roadmap.md`](RaBbLE-Post-EP1-Roadmap.md)
> - **Staging plan to air:** [`log/plans/EP1-Staging-and-Grimoire-Audit.md`](../log/plans/EP1-Staging-and-Grimoire-Audit.md)
> - **Open blockers:** [`log/BLOCKERS.md`](../log/BLOCKERS.md) · **Exit conditions of record:** `registry/epochs/current.epoch.yml`
> - **Member detail:** [OS](../RaBbLE-OS/RaBbLE-OS-Roadmap.md) · [sCoRE](../RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md) · [World](../RaBbLE-World/RaBbLE-World-Roadmap.md) · [NeBuLA](../RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md) · [Aether](../RaBbLE-Aether/RaBbLE-Aether-Roadmap.md) · [Pocket](../RaBbLE-Pocket/RaBbLE-Pocket-Roadmap.md)
> - **How we got here:** [`log/RaBbLE-Development-History.md`](../log/RaBbLE-Development-History.md)
>
> **Keep it true:** update the Position block and the member table when a gate flips or a member
> changes state. If this doc and the checklist disagree, the checklist wins and this doc is the bug.

---

## Position — 2026-10-13 (S248)

```
EPOCH 0 · FOUNDATION                         [active since 2026-04-28]
  EPISODE 1 · GENESIS                        [staging — not yet aired, no date set]
    Air gate: G1–G6, G8 green · G7 met, not yet recorded · G9 blocked · G10 awaits Mark's sign-off
    Version: v0.0.0.0 → v0.0.0.1 at air (all lockstep members tagged together)
  EPISODE 2 · EXODUS                         [next — the entity gains senses + users get a door]
```

Air is Mark's call once every checklist row is green. There is no target date; Genesis airs when it
is coherent (see `RaBbLE-Versioning.md`: episodes air retroactively at a felt stable point).

---

## Members — where each one actually is

**Lockstep** members tag `episode-1-v0.0.0.1` together. **Independent** members pace themselves
(Echo coherence policy, `current.epoch.yml`).

| Member | Track | State today | Genesis ships |
|---|---|---|---|
| **sCoRE** | lockstep | LIVE on Render (`score.joinrabble.world`), guest chat SSE, Groq fast chain, keep-warm cron, transcript logging, `/api/v1/beam` voice turns for Pocket (S243) | the voice: persona chat for any visitor |
| **World** | lockstep | prod = older build (deploys from `main` at air); dev = five-beat face ("wake RaBbLE" → boot → talk to sCoRE live → Summon → Enter) around `<rabble-entity backend="alive">` (S235), iPhone pass (S241), `os.html` install guide, `setup.sh` + KS redirects | the face at `joinrabble.world` |
| **NeBuLA** | lockstep | `<rabble-entity backend="alive">` (2D on WebGL + 3D), `setInsets`, effects (starfield, floor, graph), Studio MVP; bundle on CDN `v0.0.0.1-rc.1` | the entity renderer |
| **Aether** | lockstep | design system on CDN `v0.0.0.1-rc.2`; themes for Firefox, Kvantum, VSCodium consumed by OS | the look, everywhere |
| **OS** | lockstep (Developer Preview) | Fedora 44 + Hyprland 0.56 (Lua config); branded ISO via `build-iso.sh`, in-installer Bootstrap; VM install passed (S236), bare metal passed (S238); `rdisplay` V1 (S246) | "enter at your own risk" preview on generic x86_64 |
| **Grimoire** | lockstep | canonical; registry + spells live | the source of truth, tagged with the set |
| **BaBbLE** | lockstep (local surface) | intake workspace; voice vocoder v4 work (S244) | tagged, unchanged |
| **Collective** | lockstep | root + `setup.sh` | the door (G9 is its gate) |
| **ScRiBbLE** | independent | LIVE at `scribble.joinrabble.world` (neon note PWA v1) | — (ships on its own track) |
| **Pocket** | independent | ESP32-S3 AMOLED pendant: RaBbLE gadget firmware (IDF v6), IMU motion, voice beamed to sCoRE (S243) | — |
| **Chrysalis** | independent (archive) | genesis archive + reliquary; `chrysalis.joinrabble.world` | — |
| **Xperimental** | independent (local sandbox) | rablets not yet emerged | — |
| **EnGrAm** | concept | named + architected (2026-09-26), no repo | — (Exodus) |
| **TaskViSoR** | scaffold | identity declared, no repo | — (Echo 1) |

---

## Episode 1 — Genesis · expression

**What it is, honestly:** a face and a voice. A visitor reaches `joinrabble.world`, the entity boots,
they talk, sCoRE answers in persona, and the entity reacts while it happens. Plus a Developer Preview OS
and a bootstrap that clones the Collective. RaBbLE does not yet observe, remember, or speak unprompted.
That boundary is stated in `log/episodes/EPISODE-1-RELEASE.md`, not hidden.

**What is left before air** (detail + owners in the staging plan):
1. **G9:** `setup.sh` must clone on a fresh machine. Manifests use SSH URLs, and NeBuLA + sCoRE are
   private; visibility is an open decision (B-17).
2. **G7:** record the OS preview floor (evidence exists; confirmation run deferred by Mark, S248).
3. **G10:** Mark signs off the dev face; decide the `/chrysalis/` path on the main domain.
4. **Public face:** repo descriptions, member READMEs, org profile; Genesis release record rewritten from what shipped.
5. **Air procedure:** checklist §D (tag, merge `new-horizons → main`, prod deploys, seal).

---

## Episode 2 — Exodus · senses + a door for users

The spine: **the day RaBbLE says something you didn't ask for.** Detail, sources, and tickets live in
[`RaBbLE-Post-EP1-Roadmap.md`](RaBbLE-Post-EP1-Roadmap.md); the headline items:

- **Local harness + `rabble` CLI:** sCoRE as a user service on the machine.
- **Watcher daemon:** the first sense, one vertical slice to one unprompted observation.
- **Memory:** EnGrAm (personal content) and the observation contract.
- **NeBuLA state machine** driven by sCoRE streaming.
- **User scaffold:** accounts + sessions first, then encrypted ingestion
  (`log/plans/EP2-Accounts-Encryption-Spec.md`). Needs a persistent store; the EP1 Summon preview's
  portal config is the profile schema.
- **OS hardening** toward a full reproducible bake; Mark-hardware track (ProArt, B-15).

## Episode 3 — Covenant · and beyond

Named, not scoped: the Sovereign Accord surfaces, entity voice stable. (The original "invite-only
onboarding" framing predates the EP2 accounts spec's "no invite gate" direction; settle it when Covenant
is scoped.) Episode 4+ are named as they approach (Wilderness → Promised Land). The Biblical arc is
intentional lore; do not neutralize it.

## Echo 1 — the first stable release

After several episodes: the learning loop closes (observe → pattern → intent → act), Grimoire MCP,
presence layer, agent-framework adoption, TaskViSoR Layer 1. See Post-EP1 Roadmap § Echo 1.
Breaking changes are reserved for Echo boundaries.

---

## Cadence after air

Episodes air **when a vertical slice closes**, not on a calendar. ("Weekly episodes" in
`RaBbLE-Versioning.md` is the aspiration; revisit at Exodus once real rhythm exists.) After Genesis,
members may diverge by about 1–2 episodes; the Grimoire flags drift; Echo is reached together.

**Before air, decide** the post-air integration branch (keep `new-horizons`, or one per episode) so the
CI triggers on World/Aether/NeBuLA/sCoRE stay correct.

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
| 2026-10-13 | **S248 rewrite to match reality.** The May body (per-member Ep1 checklists, versioning transition table, S29 context-optimization notes) had frozen while the work shipped; replaced with a live position block, a true member table (adds ScRiBbLE, Pocket, EnGrAm, TaskViSoR), Genesis remaining-work, and pointers to Post-EP1. Prior body is in git history; see Development History "Canon corrections". |
| 2026-05-14 | Roadmap consolidated around Episode 1 work streams; Phases language retired. |
| 2026-05-07 | Full audit; devPlan/GAPS/TODO integrated. |
| 2026-04-28 | Initial Collective roadmap. |
