# log/plans/CONTEXT.md

```
workspace: log/plans | epoch: 0
```

## What happens here

Active implementation plans — plain markdown, one file per work thread. Read before starting
the work; these provide cold-start context for multi-session efforts. When work is done,
move to `done/`. Handoff docs (written mid-session for a fresh agent) live in `../handoffs/`.

## Active plans

| Plan | Status |
|---|---|
| `Collective-Architecture-Audit-2026-07-04.md` | 🟢 S193 RUN (findings). S196 — Batch 1 safe doc/drift fixes landed; decisions + restructures deferred. Live status → `Collective-Architecture-Audit-PROGRESS.md` |
| `Collective-Architecture-Audit-PROGRESS.md` | 🟢 S196 — implementation ledger: what's done vs deferred across all audit findings |
| `sCoRE-Extensibility-Refactor-Plan.md` | 🟡 S193 — 3 options (A/B/C) + preconditions; awaiting Mark's option choice, then post-G7/G9 |
| `OS-ProArt-Power-Stack-Plan.md` | 🟡 S189 — Hyprland GPU load, NVIDIA D3cold, tuned+asusd 3-mode waybar, settings-app sketch; Opus-reviewed + corrected, ready to implement |
| `OS-Boot-Chain-Seamless-Plan.md` | 🟢 S197 — GRUB→Plymouth→SDDM seam fixes; Phase 1 (retain-splash 1A, GRUB canvas 1B, cmdline hygiene 1C) VM-verifiable + feeds G7; Phase 2 (amdgpu sole DRM, by-path repin) real-HW. 1C+2A landed; 1A/1B in flight |
| `Subdomain-Registry-and-Maintenance.md` | 🟡 S185 — subdomain registry spec + Collective maintenance backlog |
| `Aether-Theming-Convergence.md` | 🟡 Not started — palette sovereignty across web/editor/desktop/browser |
| `OS-VM-Dev-Flow.md` | 🟡 VM install unblocked; cast VM + boot-theme loop pending |
| `OS-Plymouth-Black-Screen.md` | 🎯 Root cause found (S166 ternary); awaiting visual verify |
| `OS-Dolphin-Grey-Text.md` | 🔴 Dim labels; stack confirmed; fix path A/B pending |

## Completed plans

Finished work in `done/` — kept for historical context on decisions made.
