# Architecture.md — RaBbLE-OS Layer Model

```
transcribe ~ grimoire >> structure made explicit // %ARCHITECTURE_LOCKED%
```

> See `RaBbLE-Agent/RaBbLE-Palette.md` for the canonical color reference.
> See `RaBbLE-OS-Hardware.md` for verified hardware specifications.
> Visual assets (SVG, logos, icons) live in `RaBbLE-Aether/assets/` — not in this repo.

---

## Overview

RaBbLE-OS is structured as a set of independent, composable layers. Each layer can theoretically stand alone or be combined with others. The long-term vision is a Yocto-style model where layers live in separate repositories pulled by a manifest — but for now, all layers live in this single repo.

The Ansible role structure directly mirrors the layer model.

---

## The Layers

```
Layer 0 — BASE          Any Linux system. Packages, locale, repos, core tools.
Layer 1 — HARDWARE      Machine-specific. GPU drivers, power management, platform quirks.
Layer 2 — BOOT CHAIN    GRUB → Plymouth → Session Manager. Visual continuity, fast boot.
Layer 3 — DESKTOP       Hyprland, config, Wayland stack, synthwave theme.
Layer 4 — APPS          Dev tools, AI stack, productivity tooling.
Layer 5 — ENTITY        RaBbLE AI layer. Inference, memory, ambient presence. (Future)
```

Each layer depends on the one below it. You can install Layers 0–2 on a headless server. You can install Layers 0–4 without the AI stack. The entity in Layer 5 requires all layers beneath it.

---

## Current Ansible Role Mapping

```
Layer 0 — core/
Layer 1 — hardware/x64/asus_proart_p16/
Layer 2 — boot/
            grub2/
            plymouth/
            session_manager/         (SDDM — themed, Wayland-native)
Layer 3 — ui_ux/
            hyprland/
            quickshell/
            terminal/
            shell/zsh/
            shell/bash/
Layer 4 — dev-tools/
            main/
            vscodium/
Infra    — purge-kde/               (run once on KDE spin base — removes Plasma)
```

---

## Ansible Role Dependency Graph

```
site.yml
│
├── core                          (all hosts, always first)
│   └── packages, repos, locale, fonts, user groups, fstrim
│
├── hardware/x64/asus_proart_p16  (conditional: asus_proart_p16 group)
│   ├── firmware       (fwupd)
│   ├── amd_gfx        (mesa, vulkan, VA-API, modprobe)
│   ├── supergfx       (supergfxctl + switcheroo-control)
│   ├── asusctl        (asusd daemon)
│   ├── npu            (XDNA kernel module check, ONNX runtime)
│   ├── power          (power-profiles-daemon)
│   ├── audio          (pipewire + wireplumber)
│   └── nvidia_defer   (blacklist NVIDIA from initramfs, load at graphical.target)
│
├── boot/grub2                    (packages, theme files, /etc/default/grub, vconsole)
│   handler: grub2-mkfont, grub2-mkconfig, dracut
│
├── boot/plymouth                 (packages, theme files, set-default-theme)
│   handler: dracut
│
├── boot/session_manager          (SDDM, QML theme, wayland-sessions/hyprland.desktop)
│   handler: systemctl restart sddm
│
├── purge-kde                     (remove Plasma packages — run once on KDE spin base)
│
└── ui_ux/
    ├── hyprland       (packages via lionheartp COPR, symlink config/hyprland → ~/.config/hypr,
    │                   template machine.conf)
    ├── quickshell     (build from source if needed, symlink config/quickshell)
    ├── terminal       (kitty, nerd fonts — kitty also provided by lionheartp COPR)
    ├── shell/zsh      (zinit, starship, ZDOTDIR, symlink config/shell/zsh)
    └── shell/bash     (starship, symlink config/shell/bash)
```

---

## Hardware Targeting

Hardware is isolated from the rest of the system. Machine-specific tasks live in dedicated roles under a consistent naming convention.

```
hardware/x64/asus_proart_p16/    ← ASUS ProArt P16 H7606WV (current primary target)
hardware/x64/<machine>/          ← future x64 targets
hardware/aarch64/<machine>/      ← future SBC/aarch64 targets
```

`group_vars/asus_proart_p16.yml` carries all machine-specific variables. `site.yml` dispatches to the correct hardware role via host group membership. Hardware roles self-verify using DMI data and warn if the target doesn't match the running machine.

See `AddingTargets.md` for the full process of adding a new machine.
See `Hardware.md` for the full hardware specification of the ProArt P16.

---

## Boot Chain

```
Power on
  └── GRUB2              ← boot/grub2      synthwave theme, HiDPI font, 3840x2400
        └── Kernel loads
              └── Plymouth ← boot/plymouth  void bg + magenta RaBbLE text + spinner
                            (NVIDIA not loaded — no DRM reset, no black flash)
                    └── SDDM ← boot/session_manager  QML theme, Wayland-native greeter
                          └── NVIDIA loads  ← nvidia_defer.service at graphical.target
                                └── Hyprland ← ui_ux/hyprland  config + machine.conf
                                      └── Waybar → Quickshell (Phase 1)
```

Each stage hands off visually — same palette, same font family, no jarring transitions.
See `BootFlow.md` for per-stage detail and troubleshooting.

**Performance target:** GRUB to Hyprland desktop in under 10 seconds on this hardware.

---

## Power Management Flow

```
asusd  ←→  power-profiles-daemon (PPD)
  │              │
  │         Quiet       → power-saver
  │         Balanced    → balanced
  │         Performance → performance
  │
supergfxd  →  GPU mode (Integrated / Hybrid / Dedicated / Compute)
```

GPU architecture (Optimus/PRIME detail) → `Reference.md`.

---

## Desktop Layer — Component Map

| Component | Tool | Role | Keybind |
|---|---|---|---|
| Compositor | Hyprland v0.54+ | Primary WM | — |
| Status bar | Waybar → Quickshell (Phase 1) | System HUD | — |
| App launcher | fuzzel | Application menu | `$mod+Space` |
| Notifications | mako | Wayland-native daemon | — |
| Lock screen | hyprlock | Screen lock | `$mod+Escape` |
| Idle daemon | hypridle | Auto-lock/suspend | — |
| Wallpaper | hyprpaper | Static/animated wallpaper | — |
| Screenshot | grim + slurp | Region/full capture | `Print` / `Shift+Print` |
| Clipboard | wl-clipboard + cliphist | Copy/paste + history | — |
| Auth agent | hyprpolkitagent | Privilege dialogs | — |
| Display profiles | kanshi | Auto monitor switching | — |

---

## Hyprland Version Notes

Current version: **v0.54** (lionheartp COPR, March 2026)

**Breaking change from v0.51 → v0.54:**
- `windowrulev2` directive removed — unified into `windowrule`
- Matcher syntax is identical; only the directive name changed
- `windowrules.conf` and `workspaces.conf` updated accordingly
- Old `windowrulev2 = rule, class:^(app)$` → `windowrule = rule, class:^(app)$`

**COPR:** `lionheartp/Hyprland` — replaces the previously used `solopasha/hyprland`

---

## Theme System

The palette is defined in `ansible/inventory/group_vars/all.yml` and propagates via Ansible variables.
Full palette → `RaBbLE-Agent/RaBbLE-Palette.md`. Per-component theming → `Theming.md`.
HiDPI variable flow, config symlink map, observability commands → `Reference.md`.

---

```
transcribe ~ grimoire >> architecture crystallized // %ARCHITECTURE_LOCKED%
```
