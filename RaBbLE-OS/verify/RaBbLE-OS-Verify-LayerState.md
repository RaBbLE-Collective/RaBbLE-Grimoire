# RaBbLE-OS-Verify-LayerState.md — Current Layer State

> Update this file each session when role states change.
> Key: ✓ live · ✗ stub · ~ partial

## Layer 0 — Core

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| core | ✗ stub | ✗ stub | %DORMANT% — Phase 1 blocker |

## Layer 1 — Hardware

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| hardware/x64/generic | ✓ | ✗ stub | %DORMANT% |
| asus_proart_p16 (base) | ✗ stub | ✗ stub | %DORMANT% |
| asus_proart_p16/nvidia | ✗ stub | ✗ stub | fix/proart-nvidia |
| asus_proart_p16/supergfx | ✓ (fixed S33) | ✗ stub | fix/proart-nvidia |
| asus_proart_p16/npu | ✗ stub | ✗ stub | fix/xdna2-npu |

## Layer 2 — Boot

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| boot/grub2 | ✓ | ~ partial | %TESTING_IN_PROCESS% |
| boot/plymouth | ✗ stub | ✗ stub | %DORMANT% — Phase 1 blocker |
| boot/session_manager | ✗ stub | ✗ stub | %DORMANT% — Phase 1 blocker |

## Layer 3 — Desktop

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| desktop/wayland | ✓ | ~ partial | %DEPLOYABLE% |
| desktop/hyprland | ✓ | ✓ | %DEPLOYABLE% |
| desktop/waybar | ✓ | ✓ | %DEPLOYABLE% |
| desktop/terminal (kitty) | ✓ | ✓ | %DEPLOYABLE% |
| desktop/launcher (fuzzel) | ✓ | ✓ | %DEPLOYABLE% |
| desktop/notifications (mako) | ✓ | ✓ | %DEPLOYABLE% |
| desktop/shell/zsh | ✓ | ✓ | %DEPLOYABLE% |
| desktop/shell/bash | ✗ stub | ✓ | partial |
| desktop/screenshot | ✓ | ✓ | %STABLE% |
| desktop/swayosd | ✓ | ✓ | %DEPLOYABLE% |
| desktop/fonts | ✗ missing | ✗ missing | Phase 1 blocker |

## Layer 4 — Apps

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| apps | ✗ stub | n/a | %DORMANT% |
| apps/browsers | ✗ stub | n/a | Phase 2 |

## Cross-cutting

| Role | State |
|------|-------|
| monitoring | %DEPLOYABLE% |
| snapper | %DEPLOYABLE% |
| runtime (XRT/CUDA) | %DORMANT% — fix/proart-nvidia + fix/xdna2-npu |

→ `layers/` — each layer's doc for what Phase 1/2 needs implementing
