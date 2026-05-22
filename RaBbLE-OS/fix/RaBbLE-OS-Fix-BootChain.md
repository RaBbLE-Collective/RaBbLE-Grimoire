# RaBbLE-OS-Fix-BootChain.md — fix/boot-chain

**Branch:** `fix/boot-chain`
**State:** `%COOKING%`
**Goal:** GRUB/Plymouth/SDDM minimal RaBbLE-themed boot — palette-correct, void bg, no breaks at 4K.

## GRUB2 Blockers

- [ ] Remove background image from `theme.txt` — 32bpp/24bpp mismatch causes render failure; use `bgcolor = "#0a0010"` only
- [ ] 4K font: compile `ter-v32b` via `grub2-mkfont -s 32` → set `GRUB_FONT=/boot/grub2/fonts/ter-v32b.pf2`
- [ ] `fbcon=font:TER16x32` in `GRUB_CMDLINE_LINUX` for early TTY before systemd

## Plymouth Blockers

- [ ] `.script` file hardcodes DejaVu font — replace with Terminus or Noto
- [ ] Color values stale — update to `#ff2d78`, `#bf5fff`, `#0a0010`
- [ ] Rebuild initramfs after changes: `plymouth-set-default-theme -R rabble`
- [ ] NVIDIA defer (depends on `fix/proart-nvidia` landing first)

## SDDM Blockers

- [ ] `Main.qml` needs Qt6 API validation — test via `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble`
- [ ] Wayland session conf + `hyprland.desktop` entry

## Verification

- [ ] GRUB renders at 4K with readable font and void background
- [ ] Plymouth shows RaBbLE palette, no DejaVu font artifact
- [ ] No black flash between Plymouth and SDDM
- [ ] SDDM launches Hyprland session

→ `layers/RaBbLE-OS-Layer-Boot.md` — boot layer role structure
→ `desktop/RaBbLE-OS-Desktop-BootFlow.md` — per-stage config detail
→ `fix/RaBbLE-OS-KnownIssues.md` — Plymouth black flash issue detail
