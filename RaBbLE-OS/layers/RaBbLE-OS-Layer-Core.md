# RaBbLE-OS-Layer-Core.md — Layer 0: Base

**Role:** `ansible/roles/core/`
**Tag:** `base`
**State:** `%DORMANT%` — stub, Phase 1 blocker

## What It Covers

- DNF package installation (all `layer: core` entries from manifest)
- RPM Fusion Free + Non-Free repos
- COPR repos: `lionheartp/Hyprland`, `erikreider/swayosd`
- Locale (`en_US.UTF-8`), timezone, keyboard
- User groups (wheel, video, audio, libvirt)
- fstrim timer (SSD health)

## Current State

Both `packages` and `config` tasks are empty stubs. The system currently relies on
Fedora's base install having the packages. This breaks on a clean Fedora Everything
netinstall — there is nothing.

## Phase 1 Work

Implement `core/tasks/packages.yml` to DNF install all manifest entries with `layer: core`:
```bash
# Preview what needs installing:
grep -A3 'layer: core' ansible/packages/manifest.yml
```

Roughly 20 packages: git, curl, ansible, python3, NetworkManager, polkit, zsh, eza, fd, bat, fzf, ripgrep, neovim, htop, wget, rsync, unzip, p7zip, tar, openssh.

Done when: `layerctl apply base` on a fresh Fedora Everything install produces a functional base.

## Package Source

`ansible/packages/manifest.yml` — canonical package list, `reason:` field per entry.

→ `layers/RaBbLE-OS-Layers.md` — layer ordering
→ `ops/RaBbLE-OS-Ops-Layerctl.md` — how to apply/check
→ `verify/RaBbLE-OS-Verify-LayerState.md` — current ✓/✗ state
