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
| `EP1-Air-Push-Plan.md` | 🟢 S203 ACTIVE — A4 DONE: entity-forward face built + verified (Mark sign-off pending), passage retired to Chrysalis reliquary. B-10 mapped → `../handoffs/HANDOFF-S203-B10-Cloudflare-Token.md` (Mark-gated). Next: A5 (Chrysalis CI + deploy.sh wrapper + key inventory), C1 (reliquary garden), A1 |
| `Collective-Architecture-Audit-2026-07-04.md` | 🟢 S193 RUN (findings). S196 — Batch 1 safe doc/drift fixes landed; decisions + restructures deferred. Live status → `Collective-Architecture-Audit-PROGRESS.md` |
| `Collective-Architecture-Audit-PROGRESS.md` | 🟢 S196 — implementation ledger: what's done vs deferred across all audit findings |
| `sCoRE-Extensibility-Refactor-Plan.md` | 🟡 S193 — 3 options (A/B/C) + preconditions; awaiting Mark's option choice, then post-G7/G9 |
| `OS-ProArt-Power-Stack-Plan.md` | 🟡 S189 — Hyprland GPU load, NVIDIA D3cold, tuned+asusd 3-mode waybar, settings-app sketch; Opus-reviewed + corrected, ready to implement |
| `OS-Boot-Chain-Seamless-Plan.md` | 🟢 S197 — Phase 1 DONE + VM-verified: 1D terminus-fonts-console kills the vconsole TTY flash (headline win, commit 5ad3b16), 1A retain-splash + 1C seamless-drop (b3c0b21), 1B GRUB no-change. NEXT SESSION: update boot-chain docs, fix vm-boot-iterate.sh bugs, Phase 2 real-HW (Mark-driven) |
| `Subdomain-Registry-and-Maintenance.md` | 🟡 S185 — subdomain registry spec + Collective maintenance backlog |
| `OS-Theming-Variants-Plan.md` | 🟡 S204 designed — token canon + variants (void/dawn) + profiles (surge/drift/still), Firefox dropdown root cause, contrast QA gate; awaiting Mark's calls on defaults/naming/dawn hues |
| `Aether-Theming-Convergence.md` | 🟡 Not started — palette sovereignty across web/editor/desktop/browser. Tracks A1–A3 absorbed by `OS-Theming-Variants-Plan.md` Phase 2 |
| `OS-VM-Dev-Flow.md` | 🟡 VM install unblocked; cast VM + boot-theme loop pending |
| `OS-Plymouth-Black-Screen.md` | 🎯 Root cause found (S166 ternary); awaiting visual verify |
| `OS-Dolphin-Grey-Text.md` | 🔴 Dim labels; stack confirmed; fix path A/B pending |

## Completed plans

Finished work in `done/` — kept for historical context on decisions made.
