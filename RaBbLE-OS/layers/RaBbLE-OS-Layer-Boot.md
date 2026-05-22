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
| `boot/plymouth` | ✗ stub | ✗ stub | %DORMANT% — Phase 1 blocker |
| `boot/session_manager` (SDDM) | ✗ stub | ✗ stub | %DORMANT% — Phase 1 blocker |

## Phase 1 (boot into a DE)

- `core/packages` → fonts must install first
- `boot/plymouth/packages` → DNF install `plymouth`, `plymouth-plugin-script`
- `boot/session_manager/packages` → DNF install `sddm`
- Done when: SDDM greeter appears on fresh Fedora Everything install

## Phase 2 (themed boot chain)

- `boot/plymouth/config` → RaBbLE theme + `plymouth-set-default-theme` + dracut rebuild
- `boot/session_manager/config` → RaBbLE QML theme + Wayland conf + hyprland.desktop
- `boot/grub2` fixes → 4K font (`grub2-mkfont`), remove bg image, `fbcon=font:TER16x32`

→ `desktop/RaBbLE-OS-Desktop-BootFlow.md` — per-stage config detail (GRUB conf, Plymouth script, SDDM QML)
→ `fix/RaBbLE-OS-Fix-BootChain.md` — active blockers
→ `fix/RaBbLE-OS-KnownIssues.md` — Plymouth black flash, SDDM Qt6 validation
→ `hardware/RaBbLE-OS-Hardware-ProArtP16.md` — NVIDIA defer requirement
