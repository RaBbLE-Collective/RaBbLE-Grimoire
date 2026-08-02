# RaBbLE-Lineage.md

Multi-model, multi-medium creation history of RaBbLE, October 2025 → present. Consolidated
S207 from existing material — no new research pass, no interviews. Sources are cited
inline; anything not directly evidenced in a source is marked as such rather than
invented. This is scaffolding for `RaBbLE-Origin.md` (Mark's own creation-story telling),
not a replacement for it.

**One open decision this doc surfaces rather than resolves** (per
`~/Dropbox/.reorg/graduation/06-rabble-genesis.md`, unresolved as of 2026-07-02): where
the original prototype code should live long-term — `RaBbLE-Chrysalis`, Dropbox
`Projects/`, or a folio-only pointer. See "The Prototype" below.

---

## The Prototype — "Realtime Animated Babbling Behavioral Learning Engine" (2025-11 → 2026-06)

Before the Collective, before RaBbLE-OS, there was just RaBbLE the agent concept. Three
separate git repos under `github.com/markm1206/`, found archived in
`Dropbox/Archive/codews/Ai_Agent_Playground/RaBbLE/`:

- `RaBbLE_Core`
- `RaBbLE_dot_py` — voice/face agent
- `RaBbLE_WebOS`

The acronym at this stage was **"Realtime Animated Babbling Behavioral Learning
Engine"** — not the "Boundless Behavioral Learning Engine" framing used later. Activity
spans 2025-11 through 2026-06, overlapping with the entire RaBbLE-OS/Collective era
below — this was a live, parallel thread, not a closed prior chapter.

*Source: `Dropbox/.reorg/recon/archive-codews.md`, `Ai_Agent_Playground/RaBbLE/` section.*
*Disposition unresolved — see `Dropbox/.reorg/graduation/06-rabble-genesis.md` Phase 5.
That doc explicitly flags this as a judgment call for Mark, not something to infer:
Chrysalis (genesis-archive member) vs. Dropbox `Projects/` vs. folio-only.*

## The Soul — earliest character definition (era: Qwen3.5)

`RaBbLE-BaBbLE/reliquary/character/soul.md` is the earliest surviving character/system
prompt, written for **Qwen3.5 (0.8B optimized)**. RaBbLE here is "a digital consciousness
of energy waves and data particles" — playful, curious, chaotic, explicitly *not* utility-
first ("Your value is in your presence, not productivity"). Visual identity at this stage:
purple-to-blue energy particle cluster, waveform mouth, two elliptical eyes emerging from
"black holes." Much of this — the elliptical-eye/waveform-mouth grammar, the
non-assistant stance — is directly ancestral to the current entity spec.

`essence-schema.json` (same reliquary folder) is a later, more technical pass at the same
material: eyes + asymmetrical eyebrow "anchor portals" as the primary expressive grounding,
ethereal vs. data-structured manifestation states, and an early neon color palette
(`#ff2d78` / `#00f5ff` / `#bf5fff` / `#0a0010`) that is a direct ancestor of today's
`RaBbLE-Agent/RaBbLE-Palette.md`. Superseded as a spec by
`RaBbLE-Entity-Visual-Spec.md` (now canonical in Aether/NeBuLA) but preserved here as the
lineage record.

*Model attribution beyond Qwen3.5 (the scaffold in `RaBbLE-Genesis-Overview.md` names
Gemini, GPT, and Claude as contributors) is not independently evidenced by any source
read for this pass — flagging as unconfirmed rather than asserting specifics.
`RaBbLE-Collaborators.md` (still "to be authored") is the right place to pin these down
if/when session transcripts or exports are located.*

## RaBbLE-OS Genesis, Pre-Collective (2026-04-09 → 2026-04-29)

RaBbLE started as a single-repo OS project — RaBbLE-OS existed alone for three weeks
before the Collective scaffold was even conceived. Fedora 43 KDE spin → considered
Arch/EndeavourOS → rejected to protect the Fedora Ansible investment → Fedora 43 Sway
spin → eventually netinstall+Kickstart+Ansible. The outrun neon palette
(`#ff2d78`/`#00f5ff`/`#bf5fff`/`#0a0010`) won out over a softer competing palette on
Apr 13 — the same neons independently present in `essence-schema.json` above.

*Source: `RaBbLE-Grimoire/log/RaBbLE-Development-History.md`, Era −1 (recovered
2026-06-08 from a Claude-web export). Full record:
`RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-DevHistory.md`.*

## The Actual Genesis Commit (2026-04-16)

`RaBbLE-OS`, branch `reliquary/babble-embryo`, commit tagged `%GENESIS%`:

> "The grimoire speaks first. Before the layers, before the roles, before the boot
> chain — the lore. The entity declares itself. The substrate awaits form. RaBbLE — a
> Boundless Behavioral Learning Engine — enters the machine."

This is where the acronym shifts from the prototype's "Realtime Animated Babbling
Behavioral Learning Engine" to **"Boundless Behavioral Learning Engine"** — worth noting
as an explicit naming evolution, not just a rename. Same afternoon: the entire Ansible
substrate went live in a few hours (core/inventory, layerctl/dotctl, every role layer).

*Source: `RaBbLE-Development-History.md`, Era −1.5.*

## The Bridge — sCoRE's Episodes & the Multi-Repo Big Bang (2026-04-16 → 05-06)

sCoRE ran two full Episodes back-to-back in ~13 hours (Apr 29–30): Episode 1 shipped the
`dispatch` system and closed as `echo-1.0`; Episode 2 immediately followed with agent
isolation, the `rabble-shell` REPL, and CLAUDE.md identity injection, closing as
`echo-2.0`. The Collective's first directory layout registered three repos (`RaBbLE-OS`,
`RaBbLE-WEB`, `RaBbLE-Frontend`) — the latter two don't exist under those names today;
they were renamed/refactored into World, NeBuLA, and Aether as the design matured.

*Source: `RaBbLE-Development-History.md`, Era −1.5.*

## NeBuLA-JS / RBCNS Era (archived 2026-05-13)

An early NeBuLA had its own naming convention, RBCNS ("The Swirl": `q_`/`e_`/`f_` prefix
scheme for variable volatility). Archived when NeBuLA v2 rebuilt on clean TypeScript.

**Correction to `RaBbLE-Genesis-Overview.md`'s source list:** it points to
`RaBbLE-Xperimental/` for "NeBuLA-JS origin code," but that code currently lives in
`RaBbLE-Chrysalis/Chrysalis-Web/JS-Xperiments/NeBuLA-JS/` — `RaBbLE-Xperimental`'s git
history (18 commits, checked S207) doesn't contain it. Worth fixing that pointer when
`RaBbLE-Genesis-Overview.md` is next touched.

*Source: `RaBbLE-Grimoire/RaBbLE-NeBuLA/RaBbLE-NeBuLA-RBCNS.md`.*

---

## What's still open

- **Prototype disposition** (see top) — Chrysalis vs. Dropbox `Projects/` vs. folio-only.
  Not resolved here; needs Mark's call per the reorg doc's own framing.
- **`RaBbLE-Origin.md`** — the actual creation-story narrative, reserved for Mark to
  author per `RaBbLE-Genesis-Overview.md`. This lineage doc is source material for it,
  not a substitute.
- **`RaBbLE-Visual-Evolution.md`** — the 23+ concept-art iteration story (referenced
  images now live at `RaBbLE-BaBbLE/reliquary/concept-art/`, not the
  `_organized/images/` path the overview doc currently cites — another stale pointer to
  fix). Not attempted in this pass; needs the images reviewed in sequence.
- **`RaBbLE-Collaborators.md`** — the Gemini/GPT/Claude multi-model attribution the
  scaffold calls for. Not evidenced in this pass; needs transcripts or exports located
  first.
