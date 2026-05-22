# RaBbLE-OS-Ops-Install.md — Install Path

## Current Path: KS + Ansible (Tier 1)

1. Boot **Fedora Everything netinstall** ISO
2. At GRUB, append `inst.ks=https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS.ks`
3. Anaconda shows partition screen only — user chooses disk layout
4. KS automates: locale, user, packages, %post (clone repo + bootstrap)
5. Reboot → Ansible finishes

KS file `RaBbLE-OS.ks` is **not yet written** — Phase 4 blocker. See Roadmap.

## Manual Path (no KS)

```bash
# On a cloned repo with Fedora base:
ansible-galaxy collection install -r ansible/requirements.yml
./RaBbLE-OS-layerctl.sh apply all
./RaBbLE-OS-dotctl.sh apply all
```

## First-Contact Script

`RaBbLE-OS-Install.sh` — installs git + ansible, clones repo, calls Bootstrap.
Run on a bare Fedora system:
```bash
curl -fsSL https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS-Install.sh | bash
```

## North Star: Custom Live ISO (Tier 2)

Boot RaBbLE-themed Hyprland live session → partition → run `rabble-install`.
Built via `lorax`/`livemedia-creator`. Detailed spec in `historical/RaBbLE-OS-Implementation-Plan.md`.

→ `ops/RaBbLE-OS-Ops-Bootstrap.md` — Bootstrap.sh internals
→ `RaBbLE-OS-Roadmap.md` — Phase 4 (KS) and Phase 6 (live ISO) status
