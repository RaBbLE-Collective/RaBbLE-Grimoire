# RaBbLE-OS-Ops-ConfigFlow.md — Config Symlink + Template Map

## Symlinked (dotctl manages)

| Repo path | Deployed to |
|-----------|-------------|
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

## Ansible-Templated (machine-local, not symlinked)

| Generated path | Template |
|----------------|----------|
| `~/.config/hypr/machine.conf` | `roles/ui_ux/hyprland/templates/hyprland-machine.conf.j2` |
| `~/.config/environment.d/rabble.conf` | `roles/core/templates/xdg-environment.conf.j2` |
| `/etc/default/grub` | `roles/boot/grub2/templates/grub.j2` |
| `/etc/vconsole.conf` | `roles/boot/grub2/templates/vconsole.conf.j2` |
| `/etc/sddm.conf.d/rabble.conf` | `roles/boot/session_manager/templates/sddm.conf.j2` |
| `/etc/sddm.conf.d/hidpi.conf` | `roles/boot/session_manager/templates/sddm-hidpi.conf.j2` |
| `/etc/supergfxd.conf` | `roles/hardware/x64/asus_proart_p16/templates/supergfxd.conf.j2` |
| `/etc/modprobe.d/rabble-nvidia-defer.conf` | `roles/hardware/x64/asus_proart_p16/templates/nvidia-defer.conf.j2` |

## HiDPI Variable Flow

Defined once in `ansible/inventory/group_vars/asus_proart_p16.yml`, propagates:

```
rabble_hidpi_scale: 2
rabble_hypr_monitor: "eDP-1,3840x2400@60,0x0,2"
  │
  ├── grub.j2           → GRUB_GFXMODE=3840x2400x32,auto
  ├── vconsole.conf.j2  → FONT=ter-v32b
  ├── sddm-hidpi.conf.j2 → QT_SCREEN_SCALE_FACTORS=2
  ├── xdg-environment.conf.j2 → GDK_SCALE=2, XCURSOR_SIZE=48
  └── hyprland-machine.conf.j2 → monitor=eDP-1,3840x2400@60,0x0,2
```

→ `ops/RaBbLE-OS-Ops-Dotctl.md` — dotctl bundle deploy
→ `hardware/RaBbLE-OS-Hardware-ProArtP16.md` — ProArt P16 group_vars specifics
