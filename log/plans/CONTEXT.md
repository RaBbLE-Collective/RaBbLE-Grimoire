# log/plans/CONTEXT.md

```
workspace: log/plans | epoch: 0
```

## What happens here

Active implementation plans — plain markdown, one file per work thread. Read before starting
the work; these provide cold-start context for multi-session efforts. When work is done,
move to `done/`. Handoff docs (written mid-session for a fresh agent) live in `../handoffs/`.

## Active plans

Reconciled S322 (S318 triage applied; before that S248) against each plan's own status header and the session log. Status lives in the plan;
this table is a one-line pointer. 🟡 = in flight / awaiting Mark · 🔵 = design only, not started · 🎯 = awaiting verify.

| Plan | Status |
|---|---|
| `Unified-Entity/` | 🟡 S321 (2026-11-10): one puppet and render schema for every surface. Spec `Unified-Entity-Puppet-Spec.md` (draft 10b, 38 rulings; S323: Pocket's occlusion is canonical, emotion states are to exist); **read `Unified-Entity-Canon.md` first** (the rules in force, one page); live 3D rig in `live/`, rebuild with `./build.sh`. Rig baseline accepted; expression layer, spec consolidation and registry are next |
| `EP1-Staging-and-Grimoire-Audit.md` | 🟡 S248 — the path to air: gate truth, roadmap rewrite (done), de-bloat, public face, post-air user scaffold. Supersedes Entity-Face W3 |
| `EP1-Entity-Face-Plan.md` | 🟡 S234 — W0–W2 done + live on dev (five-beat face, "wake RaBbLE"); G10 sign-off pending; W3 → Staging plan; W4 (accounts direction) open |
| `EP1-Air-Push-Plan.md` | 🟡 S202/S203 — A4 superseded by Entity-Face; A5 (deploy wrapper, CI, key inventory) + C1 (reliquary garden) remain |
| `OS-Display-Manager-Plan.md` | 🟡 S246 — `rdisplay` V1 working; next: editor save → dotctl, Ansible role, KVM 144Hz test, GNOME/KDE backend |
| `Pocket-Core-Apps-Reorg-Plan.md` | 🟡 S311 DRAFT v1 — Pocket entity layers plan and roadmap R0-R10 (core / entities / apps, licence by directory, Orbit as an object, `entity_` prefix, slot and swaps); nothing implemented; next session reviews and confirms with Mark (handoff HANDOFF-S311) |
| `Pocket-Foundling-Open-App-Plan.md` | 🟡 S308 — open entity default built + flashed (panel unverified); Foundling app (SDK only; SA for now, Apache flip later) next; done/not-done ledger and roadmap inside |
| `Pocket-Release-Entities-Companion-Plan.md` | 🟡 v0.3 (S288), Opus-reviewed twice: releasable firmware, Entity-transplant, desktop companion, dad's WillowClone first. Gated by B-24/B-25/B-27 |
| `Pocket-Web-Flasher-Plan.md` | 🟡 S325 v0.2: 1.75C board + web companion (`RaBbLE-Pocket/companion-app/web`, pocket.joinrabble.world, early-access gate, firmware in private R2) built and tested locally; not deployed, not on hardware yet; durable sCoRE accounts still wait on Accounts A1 |
| `Pocket-Seam-Slot-LVGL-Design-Note.md` | 🔵 2026-11-05: panel/touch split adopted by Mark (LVGL types leave the board contract); companion to the Reorg plan; nothing implemented |
| `Pocket-Parity-Sim-Spec.md` | 🔵 S281 v0.1: sim must run the device's own LVGL code (time, sCoRE, icons, fonts) before promo renders |
| `OS-Settings-App-Plan.md` | 🔵 sketch — the display manager is its first piece |
| `OS-ProArt-Power-Stack-Plan.md` | 🟡 implemented S197, reworked S245 (asusd only, tuned masked); awaiting on-hardware verify |
| `OS-Boot-Chain-Seamless-Plan.md` | 🎯 Phase 1 VM-verified; S200 real-HW fix awaits Mark's reboot verify |
| `OS-Plymouth-Black-Screen.md` | 🎯 root cause found (S166 ternary); awaiting visual verify |
| `OS-VM-Dev-Flow.md` | 🟡 Part 1 done; cast VM + build-loop spell pending (S236 drove virt-install directly) |
| `OS-Installer-Scope-Genesis-to-Echo1.md` | 🔵 S323 scope: Genesis `0.1.0` = bootstrap and Kickstart paths documented and tested (G1 to G5); Echo 1 = an actual installer (I1 to I8); decisions D1 to D4 |
| `OS-Install-Editions-Plan.md` | 🔵 S283 design — core/user/dev/creative/full editions, manifest `edition:` field, installer `--edition`, plus disk reclaim + backup actions; D1 to D5 decided, D6 deferred, ready for W1 |
| `OS-Theming-Variants-Plan.md` | 🔵 S204 design — variants + profiles + contrast QA; awaiting Mark's calls |
| `Accounts-Formalization-Scope.md` | 🔵 S322 scope: a visitor becomes a user. What sCoRE already has (user record, tokens, invites, summon), gaps G1-G8, slices AC1-AC7, decisions A1-A7 for Mark. Nothing built |
| `EP2-Accounts-Encryption-Spec.md` | 🔵 EP2 draft — the user scaffold: accounts/sessions first, then encrypted ingestion |
| `NeBuLA-Pocket-Puppet-Rendering-Pipeline.md` | 🔵 research — shared rig/animation pipeline for NeBuLA + Pocket |
| `sCoRE-Extensibility-Refactor-Plan.md` | 🔵 S193 — options A/B/C, awaiting Mark's choice; post-air |
| `sCoRE-RaBbLE-UI-Rust-Plan.md` | 🟡 S292 — RaBbLE-UI rebuilt in Rust (R4; Mark chose it for snappy/fluid): Rust TUI + Python engine sidecar proposed, targets T1-T6, phases R0-R5, parity by golden dumps; awaiting Mark's shape sign-off + Opus review; R0 spike is safe |
| `Subdomain-Registry-and-Maintenance.md` | 🔵 S185 — subdomain registry spec + maintenance backlog |
| `Sovereign-Accord-v2-Brand-and-Entity.md` | 🔵 S278: Accord v2: owner, scratch text (PolyForm ref), Ohio law decided; drafts in RaBbLE-Collective/; name clearance gates promo; rest deferred |
| `Brand-Asset-Consolidation-PROPOSAL.md` | 🔵 2026-11-06 proposal, nothing moved: brand-mark inventory and one-source plan; waits on D5 (vector master) and Mark's Q1-Q3 |
| `Open-Layer-and-Positioning-Notes-2026-11-02.md` | reference: session notes on Muse SDK changes, provenance, positioning and where the open line sits (decided / leaning / open marked inline) |
| `Collective-ICM-Conformance-Audit.md` | 🟡 audit complete 2026-08-27; 3 open decisions for Mark |
| `Collective-Coherency-Audit-S318/` | 🟡 audit 2026-11-06; D1/D4/D6 done, D2 deferred, D3 ruled (replacement owed), D5 open. Evidence: `audit-plans-roadmap.md`, `audit-web-brand.md`, `audit-ansible.md`. Follow-on: `Collective-Context-Diet-S322.md` |
| `Collective-Architecture-Audit-2026-07-04.md` | reference — S193 findings; open items tracked in the PROGRESS ledger below |
| `Collective-Architecture-Audit-PROGRESS.md` | 🟡 S196 ledger — Batch 1 landed; decisions + restructures deferred |
| `Collective-Context-Diet-S322.md` | 🟡 S322: context-cost audit and fixes (log rotation, lean door, hub indexing), entity-definition drift map, D3 proposal, ambient-loop proposals. Decisions for Mark listed at the top |

## Completed plans

Finished work in `done/` — kept for historical context on decisions made.

| Plan | Closed |
|---|---|
| `done/sCoRE-RaBbLE-UI-Plan.md` | superseded by the Rust plan (S292); archived S322 |
| `done/Pocket-Open-SDK-App-Separation-Plan.md` | superseded by Pocket-Core-Apps-Reorg (S311); archived S322 |
| `done/Aether-Theming-Convergence.md` | absorbed by OS-Theming-Variants; archived S322 |
| `done/EP1-Liminal-Experience-Plan.md` | implemented S190, retired S203 (frozen in Chrysalis) |
| `done/NeBuLA-Studio-Plan.md` | built + Playwright-verified S198 |
| `done/OS-Dolphin-Grey-Text.md` | resolved S201 (KColorScheme) |
| `done/Collective-Architecture-Audit-Plan.md` | run S193 |
| `done/World-Framework-Refactor*.md`, `done/harvest-map*.md` | S182 |
