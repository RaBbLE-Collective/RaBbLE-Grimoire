# RaBbLE-OS-Reference.md — Deep Reference

```
transcribe ~ substrate >> reference doc created from Architecture + Roadmap split // %S34%
```

> Deep reference material extracted from Architecture.md and Roadmap.md.
> Read when you need specifics — not required for general orientation.
> Orientation → `AgentGuide.md`. Layer model → `Architecture.md`.

---

## Config Symlink Map

All user configs live in `config/` and are symlinked by Ansible into `~/.config/`.

| Repo path | Deployed to |
|---|---|
| `config/hyprland/hyprland.conf` | `~/.config/hypr/hyprland.conf` |
| `config/hyprland/conf.d/` | `~/.config/hypr/conf.d/` |
| `config/hyprland/scripts/` | `~/.config/hypr/scripts/` |
| `config/shell/zsh/aliases.zsh` | `~/.config/zsh/aliases.zsh` |
| `config/shell/zsh/functions.zsh` | `~/.config/zsh/functions.zsh` |
| `config/shell/starship.toml` | `~/.config/starship.toml` |
| `config/shell/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `config/shell/mako.conf` | `~/.config/mako/config` |
| `config/waybar/config.jsonc` | `~/.config/waybar/config.jsonc` |
| `config/waybar/style.css` | `~/.config/waybar/style.css` |
| `config/fuzzel/fuzzel.ini` | `~/.config/fuzzel/fuzzel.ini` |
| `config/hypridle/hypridle.conf` | `~/.config/hypr/hypridle.conf` |
| `config/hyprlock/hyprlock.conf` | `~/.config/hypr/hyprlock.conf` |

**Machine-local, Ansible-templated (not symlinked):**

| Generated path | Source template |
|---|---|
| `~/.config/hypr/machine.conf` | `roles/ui_ux/hyprland/templates/hyprland-machine.conf.j2` |
| `~/.config/environment.d/rabble.conf` | `roles/core/templates/xdg-environment.conf.j2` |
| `/etc/default/grub` | `roles/boot/grub2/templates/grub.j2` |
| `/etc/vconsole.conf` | `roles/boot/grub2/templates/vconsole.conf.j2` |
| `/etc/sddm.conf.d/rabble.conf` | `roles/boot/session_manager/templates/sddm.conf.j2` |
| `/etc/sddm.conf.d/hidpi.conf` | `roles/boot/session_manager/templates/sddm-hidpi.conf.j2` |
| `/etc/supergfxd.conf` | `roles/hardware/x64/asus_proart_p16/templates/supergfxd.conf.j2` |
| `/etc/modprobe.d/rabble-nvidia-defer.conf` | `roles/hardware/x64/asus_proart_p16/templates/nvidia-defer.conf.j2` |

---

## HiDPI Variable Flow

All HiDPI values defined once in `ansible/inventory/group_vars/asus_proart_p16.yml`:

```
group_vars/asus_proart_p16.yml
  rabble_hidpi_scale: 2
  rabble_gfx_mode: "3840x2400x32,auto"
  rabble_console_font: "ter-v32b"
  rabble_hypr_monitor: "eDP-1,3840x2400@60,0x0,2"
        │
        ├── grub.j2                  → GRUB_GFXMODE=3840x2400x32,auto
        ├── vconsole.conf.j2         → FONT=ter-v32b
        ├── sddm-hidpi.conf.j2       → QT_SCREEN_SCALE_FACTORS=2
        ├── xdg-environment.conf.j2  → GDK_SCALE=2, XCURSOR_SIZE=48
        └── hyprland-machine.conf.j2 → monitor=eDP-1,3840x2400@60,0x0,2
                                       XCURSOR_SIZE=48
                                       xwayland.force_zero_scaling=true
```

---

## GPU Architecture (Optimus/PRIME)

```
AMD Radeon 890M (iGPU)                  NVIDIA RTX 4060 Mobile (dGPU)
        │                                           │
  Drives Wayland display                   PRIME offload only
  Compositor: Hyprland                    (DRI_PRIME=pci-0000_64_00_0 <cmd>)
  AQ_DRM_DEVICES=                          CUDA available always
    pci-0000:65:00.0-card                  No direct display output in Hybrid mode
        │                                  Loads at graphical.target — not initramfs
  [eDP-1: 3840×2400 @60Hz, scale 2×]
```

> **Optimus:** The RTX 4060 does not drive the display in Hybrid mode.
> Available for compute, LLM inference, CUDA workloads via PRIME offload only.

**Sleep path:** `systemctl suspend` → systemd-sleep hooks → NVIDIA VRAM preserved → `s2idle` (S0ix)

---

## Observability & Debugging

```bash
# Sleep / suspend
cat /sys/power/mem_sleep                    # must show [s2idle]
journalctl -b -u systemd-suspend           # last suspend logs
systemctl status nvidia-suspend
cat /proc/acpi/wakeup                      # ACPI wakeup sources

# GPU / display
hyprctl monitors
hyprctl devices
DRI_PRIME=pci-0000_64_00_0 glxinfo | grep renderer   # NVIDIA PRIME test

# ASUS platform
asusctl profile -l
supergfxctl --status
cat /sys/class/power_supply/BAT*/capacity  # battery %

# SDDM theme testing (without reboot)
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble

# Hyprland version
hyprctl version                            # confirm v0.54+
```

---

## Layer State Map

> **Key:** ✓ live  ✗ stub  ~ partial

### Layer 0 — Base

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| core | ✗ stub | ✗ stub | %DORMANT% — Phase 1 blocker |

### Layer 1 — Hardware

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| hardware/x64/generic | ✓ | ✗ stub | %DORMANT% |
| hardware/x64/asus_proart_p16 | ✗ stub | ✗ stub | %DORMANT% |
| asus_proart_p16/nvidia | ✗ stub | ✗ stub | fix/proart-nvidia |
| asus_proart_p16/supergfx | ✓ (fixed S33) | ✗ stub | fix/proart-nvidia |
| asus_proart_p16/npu | ✗ stub | ✗ stub | fix/xdna2-npu |

### Layer 2 — Boot

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| boot/grub2 | ✓ | ~ partial | %TESTING_IN_PROCESS% |
| boot/plymouth | ✗ stub | ✗ stub | %DORMANT% — Phase 1 blocker |
| boot/session_manager (SDDM) | ✗ stub | ✗ stub | %DORMANT% — Phase 1 blocker |

### Layer 3 — Desktop

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| desktop/wayland | ✓ | ~ partial | %DEPLOYABLE% |
| desktop/hyprland | ✓ | ✓ | %DEPLOYABLE% |
| desktop/waybar | ✓ | ✓ | %DEPLOYABLE% |
| desktop/terminal (kitty) | ✓ | ✓ | %DEPLOYABLE% |
| desktop/launcher (fuzzel) | ✓ | ✓ | %DEPLOYABLE% |
| desktop/notifications (mako) | ✓ | ✓ | %DEPLOYABLE% |
| desktop/shell/zsh | ✓ | ✓ | %DEPLOYABLE% |
| desktop/shell/bash | ✗ stub | ✓ | %DORMANT% |
| desktop/screenshot | ✓ | ✓ | %STABLE% |
| desktop/swayosd | ✓ | ✓ | %DEPLOYABLE% |
| desktop/fonts | ✗ missing | ✗ missing | Phase 1 blocker |

### Layer 4 — Apps

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| apps | ✗ stub | ✗ stub | %DORMANT% |
| apps/browsers | ✗ stub | n/a | Phase 2 |

### Cross-cutting

| Role | State | Notes |
|------|-------|-------|
| monitoring | %DEPLOYABLE% | btop, htop, powertop, sensors |
| snapper | %DEPLOYABLE% | Btrfs snapshots |
| runtime | %DORMANT% | XRT/CUDA/ROCm — fix/proart-nvidia + fix/xdna2-npu |

---

## NVIDIA Power Management Fix (fix/proart-nvidia)

Primary cause of NVIDIA idle draw: GPU staying in D0 (active) when it should be D3cold.

**1. Fine-grained power management:**
```bash
# /etc/modprobe.d/rabble-nvidia-powermgmt.conf
options nvidia NVreg_DynamicPowerManagement=0x02
# Then: sudo dracut -f --regenerate-all
```

**2. Do NOT enable `nvidia-persistenced`** — keeps GPU in D0.

**3. Enable power services:**
```bash
sudo systemctl enable nvidia-powerd
```

**Verify D3cold:**
```bash
cat /sys/bus/pci/devices/0000:01:00.0/power_state   # should show "D3cold"
```
