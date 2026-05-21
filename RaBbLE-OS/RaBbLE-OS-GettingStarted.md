# RaBbLE-OS-GettingStarted.md

```
transcribe ~ substrate >> getting started condensed to pointer // %S34%
```

> **Install path changed (S30+):** Fedora Everything netinstall + Kickstart, not KDE spin.
> The KDE spin + purge-kde workflow is historical — see `ManualInstall.md` (marked HISTORICAL).

---

## Current Install Path

**Tier 1 — KS on Fedora Everything netinstall (build first):**

1. Boot Fedora Everything netinstall ISO
2. At GRUB, append `inst.ks=https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS.ks`
3. Anaconda shows partition screen only — choose your disk layout
4. Walk away. Reboot into RaBbLE-OS.

KS file: `RaBbLE-OS/RaBbLE-OS.ks` (not yet written — Phase 4 blocker, see Roadmap.md)

**On an already-cloned repo:**
```bash
bash RaBbLE-OS-Bootstrap.sh
ansible-galaxy collection install -r ansible/requirements.yml
./RaBbLE-OS-layerctl.sh apply all
./RaBbLE-OS-dotctl.sh apply all
```

For full bootstrap detail → `Bootstrap.md`.
For VM testing workflow → `VM-Guide.md`.
