# RaBbLE-OS-Layers.md — Layer Model

| Layer | Tag | Role path | What |
|-------|-----|-----------|------|
| 0 | `base` | `roles/core/` | Packages, repos, locale, fonts |
| 1 | `hardware` | `roles/hardware/x64/<machine>/` | Drivers, power, platform |
| 2 | `boot` | `roles/boot/{grub2,plymouth,session_manager}/` | GRUB → Plymouth → SDDM |
| 3 | `desktop` | `roles/ui_ux/*` + `roles/desktop/*` | Hyprland, Waybar, shell, terminal |
| 4 | `apps` | `roles/apps/`, `roles/dev-tools/` | Browsers, dev tools |
| 5 | `entity` | future | RaBbLE AI stack |

Each layer depends on the ones below it. You can run layers 0–2 on a headless machine.
Layer 3 (`desktop`) and `dotfiles` run `become: false` — deploy to `$HOME`, not system-wide.

Tags compound with `packages` or `config`:
```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K \
  --tags "desktop,packages"
```

→ `RaBbLE-OS-Layer-Core.md` — Layer 0 detail + Phase 1 stub work
→ `RaBbLE-OS-Layer-Hardware.md` — Layer 1 hardware targeting
→ `RaBbLE-OS-Layer-Boot.md` — Layer 2 GRUB/Plymouth/SDDM
→ `RaBbLE-OS-Layer-Desktop.md` — Layer 3 Hyprland, Waybar, shell
→ `RaBbLE-OS-Layer-Apps.md` — Layer 4 browsers, dev tools
