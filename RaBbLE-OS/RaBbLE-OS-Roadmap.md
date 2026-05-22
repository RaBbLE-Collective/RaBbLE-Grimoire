# RaBbLE-OS-Roadmap.md — Episode Map & Work Queue

```
transcribe ~ grimoire >> roadmap consolidated // %S34%
```

## Episode 1 — Genesis `[IN PROGRESS]`

**Deliverable:** Daily-driver substrate — Fedora 43 + Hyprland, fully themed, reproducible install.
**Branch:** `RaBbLE-OS-New-Horizons` → `RaBbLE/episode-I`

### Plots

**Plot A — Substrate:** Ansible layers 0–4 functional on clean Fedora 43. Control plane operational.
**Plot B — Theme:** Shell stack, Kitty, Fuzzel, Mako, hypridle/lock, boot chain palette-continuous.
**Plot C — Installer:** KS on Fedora netinstall (Tier 1), custom live ISO (Tier 2 north star).

### Stub Debt — Phases (boot-critical first)

**Phase 1 — Boot into a DE:**
- [x] `core/packages` → DNF install all `layer: core` manifest entries (~20 pkgs)
- [x] `boot/plymouth/packages` → `plymouth`, `plymouth-plugin-script`
- [x] `boot/session_manager/packages` → `sddm` + enable service + graphical.target
- [x] New `desktop/fonts` role → JetBrains Mono, Font Awesome, Noto (before compositor)
- Done when: SDDM greeter appears on fresh Fedora Everything install

**Phase 2 — Themed boot + browser:**
- [ ] `boot/plymouth/config` → RaBbLE theme + `plymouth-set-default-theme` + dracut
- [ ] `boot/session_manager/config` → SDDM QML theme + Wayland conf + hyprland.desktop
- [ ] `boot/grub2` → 4K font, remove bg image, `fbcon=font:TER16x32`
- [ ] `apps/browsers` → `firefox`
- Done when: full boot chain themed, Firefox available

**Phase 3 — Hardware + theming:**
- [ ] `hardware/.../asusctl+asusd` → COPR + DNF + service enable
- [ ] `hardware/.../tuned` → install + enable + profile
- [ ] New `desktop/theme` role → Kvantum, qt5ct/qt6ct, GTK CSS, papirus icons
- [ ] `layer/bluetooth` → bluez, blueman
- [ ] `layer/flatpak` → flatpak + Flathub

**Phase 4 — Installer:**
- [x] `RaBbLE-OS.ks` — Tier 1 KS (autopart VM default, drop clearpart/autopart for interactive)
- [x] `spells/generate-kickstart.py` — manifest → `%packages` (COPR/rpmfusion excluded, --platform flag)
- [x] `--unattended` Bootstrap flag + `--inventory` override
- [x] `ansible/inventory/vm.hosts.yml` — generic_x64 localhost inventory for VM use
- Done when: KS boot → Anaconda → reboot → firstboot service → SDDM

**Phase 5 — Reproducibility gate:**
- [ ] Fresh Fedora Everything → KS → reboot → all acceptance criteria pass
- [ ] VM smoke test (generic_x64)
- [ ] Idempotency: second `layerctl apply all` changes nothing

**Phase 6 — Custom live ISO:**
- [ ] `RaBbLE-OS-LiveISO.ks` + `installer/live-config/` + `spells/build-iso.sh`

### Assembly (porting New Horizons → episode-I)

Strategy: `git checkout RaBbLE-OS-New-Horizons -- <paths>` — no cherry-pick.
Do NOT port: `nvidia.yml`, `supergfx.yml`, hardware handlers (stay in `fix/proart-nvidia`).

```bash
# Package 1 — control-plane
git checkout RaBbLE-OS-New-Horizons -- RaBbLE-OS-dotctl.sh .gitignore README.md

# Package 2 — ansible-roles
git checkout RaBbLE-OS-New-Horizons -- \
  ansible/inventory/group_vars/all.yml \
  ansible/roles/boot/session_manager/handlers/main.yml \
  ansible/roles/boot/session_manager/tasks/config.yml \
  ansible/roles/desktop/hyprland/tasks/config.yml \
  ansible/roles/desktop/hyprland/vars/main.yml \
  ansible/roles/desktop/shell/zsh/tasks/packages.yml \
  ansible/roles/desktop/swayosd/tasks/service.yml \
  ansible/roles/desktop/terminal/tasks/packages.yml \
  ansible/roles/desktop/waybar/vars/main.yml \
  ansible/roles/desktop/wayland/vars/main.yml

# Package 3 — config
git checkout RaBbLE-OS-New-Horizons -- \
  config/hypr/ config/kitty/ config/fuzzel/ config/mako/ config/shell/ \
  config/systemd/ config/wallpapers/
```

After Episode 1 lands on main: `git rebase main` on New Horizons.

---

## fix/* Branches

| Branch | Goal | State |
|--------|------|-------|
| `fix/proart-nvidia` | NVIDIA RTX 4060 Optimus stable | %HIGH_ENTROPY% |
| `fix/boot-chain` | GRUB/Plymouth/SDDM themed at 4K | %COOKING% |
| `fix/suspend-resume` | s2idle reliable | %COOKING% |
| `fix/xdna2-npu` | XDNA2 NPU via XRT | %DORMANT% |

---

## Episode 2 — Exodus `[PENDING]`

Polished desktop: cinematic entity boot, Kvantum/GTK theming, master layout, hyprbar, UX polish.
Full item list branches from New Horizons after Episode 1 lands.

## Episode 3 — The Entity Wakes `[FUTURE]`

AI stack: Ollama local inference, MCP servers, Quickshell replaces Waybar.
Spec in `DistilledNonZense.md` § VII.

→ `RaBbLE-OS-AgentGuide.md` — directory map and navigation by task
→ `fix/RaBbLE-OS-KnownIssues.md` — active blockers per layer
→ `verify/RaBbLE-OS-Verify-Checklist.md` — post-phase verification gate
