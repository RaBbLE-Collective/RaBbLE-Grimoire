# RaBbLE-OS-Layer-Boot.md — Layer 2: Boot Chain

**Roles:** `ansible/roles/boot/{grub2,plymouth,session_manager}/`
**Tag:** `boot`

## Chain

```
GRUB2  →  Plymouth  →  SDDM  →  Hyprland
```

Each stage uses the same palette: void bg `#0a0010`, magenta `#ff2d78`, cyan `#00f5ff`.
No visual breaks — the boot reads as one continuous performance.

## Role State

| Role | Packages | Config | State |
|------|----------|--------|-------|
| `boot/grub2` | ✓ | ~ partial | %TESTING_IN_PROCESS% |
| `boot/plymouth` | ✓ | ✓ rabble-aether | %BOOT_AETHER% — built S87, not yet applied |
| `boot/session_manager` (SDDM) | ✓ | ✓ rabble-aether | %BOOT_AETHER% — built S87, not yet applied |

## Phase 1 (boot into a DE)

- `core/packages` → fonts must install first
- `boot/plymouth/packages` → DNF install `plymouth`, `plymouth-plugin-script`
- `boot/session_manager/packages` → DNF install `sddm`
- Done when: SDDM greeter appears on fresh Fedora Everything install

## Phase 2 (themed boot chain)

- ✓ `boot/plymouth/config` → rabble-aether theme + `plymouth-set-default-theme` + dracut rebuild handler (S87)
- ✓ `boot/session_manager/config` → rabble-aether QML greeter + `/etc/sddm.conf.d/99-rabble-theme.conf` (S87)
- `boot/grub2` fixes → 4K font (`grub2-mkfont`), remove bg image, `fbcon=font:TER16x32`

## rabble-aether themes (S87)

**Plymouth** (`ansible/roles/boot/plymouth/files/rabble-aether/`) is a *frame player*,
not a hand-coded animation: 96 PNG frames (512², 12fps, 5.6 MB) are pre-captured from
the canonical `RaBbLE-World/world/RaBbLE-Boot.html` NeBuLA animation via Playwright
video + ffmpeg crop (`build-assets.sh` — rerun it when the boot animation changes;
Ansible only deploys committed frames). `rabble-aether.script` plays the convergence
once, ping-pongs the eye-pulse loop (frames 78–96), and draws live: fake boot log
(adapted from `RaBbLE-boot.js`), color-cycling wordmark, real progress bar, systemd
messages, LUKS password dialog. `Image.Text` needs `plymouth-plugin-label` (pinned in
manifest); JetBrains Mono enters the initrd via `/etc/dracut.conf.d/90-rabble-plymouth-fonts.conf`.

**SDDM** (`ansible/roles/boot/session_manager/files/sddm-theme/`) is pure QML (Qt6,
MultiEffect glows from qt6-qtdeclarative — zero extra packages, zero image assets):
radial void breath, pulsing ◈ sigil, cycling wordmark, raised fields (violet focus /
cyan typing), magenta→violet AUTHENTICATE gradient. QA recipe:
`sddm-greeter-qt6 --test-mode --theme <dir>` with `QT_QPA_PLATFORM=offscreen` for a
parse check, then `QT_QPA_PLATFORM=wayland` + `grim` for a visual. Apply never
restarts SDDM (would kill the session) — theme lands at next greeter start.

→ `desktop/RaBbLE-OS-Desktop-BootFlow.md` — per-stage config detail (GRUB conf, Plymouth script, SDDM QML)
→ `fix/RaBbLE-OS-Fix-BootChain.md` — active blockers
→ `fix/RaBbLE-OS-KnownIssues.md` — Plymouth black flash, SDDM Qt6 validation
→ `hardware/RaBbLE-OS-Hardware-ProArtP16.md` — NVIDIA defer requirement
