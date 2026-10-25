# log/plans/CONTEXT.md

```
workspace: log/plans | epoch: 0
```

## What happens here

Active implementation plans — plain markdown, one file per work thread. Read before starting
the work; these provide cold-start context for multi-session efforts. When work is done,
move to `done/`. Handoff docs (written mid-session for a fresh agent) live in `../handoffs/`.

## Active plans

Reconciled S248 against each plan's own status header and the session log. Status lives in the plan;
this table is a one-line pointer. 🟡 = in flight / awaiting Mark · 🔵 = design only, not started · 🎯 = awaiting verify.

| Plan | Status |
|---|---|
| `EP1-Staging-and-Grimoire-Audit.md` | 🟡 S248 — the path to air: gate truth, roadmap rewrite (done), de-bloat, public face, post-air user scaffold. Supersedes Entity-Face W3 |
| `EP1-Entity-Face-Plan.md` | 🟡 S234 — W0–W2 done + live on dev (five-beat face, "wake RaBbLE"); G10 sign-off pending; W3 → Staging plan; W4 (accounts direction) open |
| `EP1-Air-Push-Plan.md` | 🟡 S202/S203 — A4 superseded by Entity-Face; A5 (deploy wrapper, CI, key inventory) + C1 (reliquary garden) remain |
| `OS-Display-Manager-Plan.md` | 🟡 S246 — `rdisplay` V1 working; next: editor save → dotctl, Ansible role, KVM 144Hz test, GNOME/KDE backend |
| `OS-Settings-App-Plan.md` | 🔵 sketch — the display manager is its first piece |
| `OS-ProArt-Power-Stack-Plan.md` | 🟡 implemented S197, reworked S245 (asusd only, tuned masked); awaiting on-hardware verify |
| `OS-Boot-Chain-Seamless-Plan.md` | 🎯 Phase 1 VM-verified; S200 real-HW fix awaits Mark's reboot verify |
| `OS-Plymouth-Black-Screen.md` | 🎯 root cause found (S166 ternary); awaiting visual verify |
| `OS-VM-Dev-Flow.md` | 🟡 Part 1 done; cast VM + build-loop spell pending (S236 drove virt-install directly) |
| `OS-Theming-Variants-Plan.md` | 🔵 S204 design — variants + profiles + contrast QA; awaiting Mark's calls |
| `Aether-Theming-Convergence.md` | 🔵 S184 — tracks A1–A3 absorbed by OS-Theming-Variants Phase 2; remainder not started |
| `EP2-Accounts-Encryption-Spec.md` | 🔵 EP2 draft — the user scaffold: accounts/sessions first, then encrypted ingestion |
| `NeBuLA-Pocket-Puppet-Rendering-Pipeline.md` | 🔵 research — shared rig/animation pipeline for NeBuLA + Pocket |
| `sCoRE-Extensibility-Refactor-Plan.md` | 🔵 S193 — options A/B/C, awaiting Mark's choice; post-air |
| `sCoRE-RaBbLE-UI-Plan.md` | 🔵 S275: `rabble` as RaBbLE's own Textual TUI over headless Claude Code (Agent SDK); Crew as subagents → RaBbLE orchestration; U0 spike verified, awaiting deps + swap-timing calls |
| `Subdomain-Registry-and-Maintenance.md` | 🔵 S185 — subdomain registry spec + maintenance backlog |
| `Collective-ICM-Conformance-Audit.md` | 🟡 audit complete 2026-08-27; 3 open decisions for Mark |
| `Collective-Architecture-Audit-2026-07-04.md` | reference — S193 findings; open items tracked in the PROGRESS ledger below |
| `Collective-Architecture-Audit-PROGRESS.md` | 🟡 S196 ledger — Batch 1 landed; decisions + restructures deferred |

## Completed plans

Finished work in `done/` — kept for historical context on decisions made.

| Plan | Closed |
|---|---|
| `done/EP1-Liminal-Experience-Plan.md` | implemented S190, retired S203 (frozen in Chrysalis) |
| `done/NeBuLA-Studio-Plan.md` | built + Playwright-verified S198 |
| `done/OS-Dolphin-Grey-Text.md` | resolved S201 (KColorScheme) |
| `done/Collective-Architecture-Audit-Plan.md` | run S193 |
| `done/World-Framework-Refactor*.md`, `done/harvest-map*.md` | S182 |
