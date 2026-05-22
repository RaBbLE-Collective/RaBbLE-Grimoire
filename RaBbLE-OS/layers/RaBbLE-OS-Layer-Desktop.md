# RaBbLE-OS-Layer-Desktop.md — Layer 3: Desktop

**Roles:** `ansible/roles/ui_ux/*` + `ansible/roles/desktop/*`
**Tag:** `desktop`
**Note:** Runs `become: false` — deploys to `$HOME`, not system-wide.

## Components

| Component | Role | State |
|-----------|------|-------|
| Compositor | `ui_ux/hyprland` | %DEPLOYABLE% |
| Status bar | `desktop/waybar` | %DEPLOYABLE% |
| App launcher | `desktop/launcher` (fuzzel) | %DEPLOYABLE% |
| Notifications | `desktop/notifications` (mako) | %DEPLOYABLE% |
| Terminal | `desktop/terminal` (kitty) | %DEPLOYABLE% |
| Shell ZSH | `desktop/shell/zsh` | %DEPLOYABLE% |
| Shell Bash | `desktop/shell/bash` | partial |
| Screenshot | `desktop/screenshot` (grim+slurp) | %STABLE% |
| OSD overlay | `desktop/swayosd` | %DEPLOYABLE% |
| Network applet | `desktop/network-applet` | %DEPLOYABLE% |
| Fonts | missing — new role needed | Phase 1 blocker |
| Quickshell | `ui_ux/quickshell` | %HIGH_ENTROPY% — Episode 3 |

## Phase 1 Item

New `desktop/fonts` role — JetBrains Mono, Font Awesome, Noto Sans.
Must run before the compositor or Waybar renders will break.

## Hyprland Version

Current: **v0.54** via `lionheartp/Hyprland` COPR.
Breaking change v0.51→v0.54: `windowrulev2` → `windowrule` (matcher syntax unchanged, directive name only).

→ `desktop/RaBbLE-OS-Desktop-Hyprland.md` — keybinds, window rules, layout reference
→ `desktop/RaBbLE-OS-Desktop-Shell.md` — ZSH/Bash config reference
→ `desktop/RaBbLE-OS-Desktop-Theming.md` — palette application, Kvantum, GTK
→ `ops/RaBbLE-OS-Ops-Dotctl.md` — how desktop configs are deployed via dotctl
