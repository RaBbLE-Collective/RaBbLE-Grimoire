# HANDOFF-S286: Pocket release, Entity-transplant, Open SDK/companion

> Session S286 (pocket-release), 2026-10-28. Cold start for the next agent. Owner of decisions: Mark. All design lives in the Grimoire, nothing was built in the Pocket repo this session.

## What this is

Mark wants Pocket firmware releasable, installable on Windows/macOS/Linux through a companion app, with entity customisation, and an **Open** (neutral-branded, source-available) SDK and companion beside the reserved RaBbLE entity/brand. First user: Mark's dad, who has a Waveshare 1.75C and wants **WillowClone** (a dog-faced agent). Dad is the 1.75C tester; Mark gets his own board later.

## Read in this order

1. `log/plans/Pocket-Release-Entities-Companion-Plan.md` v0.2+ (the authority: architecture, licence tiers, tracks, risks, open questions, all decisions). Opus-reviewed once.
2. `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Format.md` v0.1 (E0 spec, ~510 lines; **not yet Opus-reviewed**, that review is its gate). Its §10 lists 9 corrections to the plan.
3. `log/handoffs/HANDOFF-S286-Pocket-Internal-RAM.md` (task M1).
4. `RaBbLE-Pocket/RaBbLE-Pocket-SDK-Plan.md` (S8-S10 still open) and `log/plans/Sovereign-Accord-v2-Brand-and-Entity.md`.

## Decisions made this session (Mark)

- Companion app: **Tauri**, Windows + macOS + Linux; an **Open build** too (neutral UI/strings/app id; code identifiers may say `rabble`).
- Entities are **declarative data** (no code on device). Vocabulary: **Entity-transplant**, entity types; "pack" retired. Files: **`.rbl`** general container, **`.rble`** entity-only.
- Backend per profile in the companion. sCoRE gets a **free open tier**: default GPT with **no persona**, persona supplied in the entity config. Muse stays a possible host-side bridge, not firmware.
- **Open SDK**: separate from the RaBbLE Pocket SDK, ships the neutral Open Entity and **no backend configured**, updated alongside it; dad builds WillowClone on it. Recommended: one source tree, an export spell with a CI leak check (not a hand-kept fork); Mark has not chosen branch vs repo.
- 1.75C: build from **Waveshare's code now** (licence must be permissive and isolated; check first), clean-room later when Mark has the board.
- SDK entity class is **neutral** (no `rabble_` prefix); the Open build runs a documented **lean profile** until internal RAM improves.
- **Entities live in the existing notes storage**; the store becomes a general disk (SD when present). No new partition, no reformat. `format_if_mount_failed` must stop being a silent wipe.
- Product vocabulary **Familiar** (a user's own entity) and **Foundling** (a Familiar that joined the Collective) are lore words, not the brand. Open product needs a **coined name** (N1); "Open" in a name conflicts with the source-available rule.
- Grimoire git was repaired by another entity; this session did not touch it.

> **Next two jobs, in order:** `HANDOFF-S286-Pocket-Opus-Review-and-Open-SDK.md` (Opus review of the E0 spec, then the start of the Open SDK).

## Open items for the next session

| Item | Owner | Notes |
|---|---|---|
| Opus review of the E0 spec, then fold its 9 corrections into the plan | agent | sprites unusable for entities (C2), gradients are two shared LUTs (C3), SDK class rename (done in plan), sCoRE ignores `proto` (C7) |
| sCoRE persona change (K1) | agent + Mark | blocks any WillowClone voice: `server/beam.py:328-331,407` hard-codes the RaBbLE prompt; needs a versioned `hello.entity` field and an explicit `ready.persona` acknowledgement |
| Open product name (N1) | Mark | coined; first-pass search found Familiar crowded (Familiar Machines & Magic, DeskFamiliar, familiar-agent) and Foundling empty; real clearance is a TSDR hand check |
| S10a board-select CMake variable + per-board sdkconfig/partitions + rollback enabled | agent | **not blocked**: the only claims on the SDK plan are DEAD (2435f319, commit-bf9cc15); see `HANDOFF-S286-Pocket-Opus-Review-and-Open-SDK.md`. Rollback (`BOOTLOADER_APP_ROLLBACK_ENABLE`) must be in dad's first image |
| Waveshare 1.75C licence check, then B1 board layer | agent | stop and tell Mark if no licence or copyleft |
| Open SDK export spell (O1), disk layer, E1/E1b, C1 flasher + diagnostic report | agents | see plan §3 tracks |
| Copyright: register the entity art | Mark / lawyer | automatic copyright; 3-month rule after first *publication*; check what is truly public; keep dated proof |
| M1 internal RAM | Mark | `HANDOFF-S286-Pocket-Internal-RAM.md` |
| Better session tracking | Mark | S284 and S285 numbers were each reused by two sessions; wishlist: atomic S-number reservation, auto-claim on first write under shared dirs, commit hook refusing other sessions' claimed files |

## State at close

- New, uncommitted-by-others files committed by this session: the plan, the E0 spec, this handoff and the M1 handoff.
- **Not done:** no firmware, no companion code, no sCoRE change, no INDEX.md / `log/plans/CONTEXT.md` / `log/handoffs/CONTEXT.md` rows (those files carry other sessions' uncommitted edits; add the rows when they are committed whole), no Aether artifact page of the plan (Mark's standing preference; build it next time).
- Labelled S286 because S284 and S285 were already taken by the `rabble` sessions (this session first used S284, then S285, and renumbered).
