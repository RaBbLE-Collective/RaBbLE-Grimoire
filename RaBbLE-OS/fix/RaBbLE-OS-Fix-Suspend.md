# RaBbLE-OS-Fix-Suspend.md — fix/suspend-resume

**Branch:** `fix/suspend-resume`
**State:** `%COOKING%`
**Goal:** s2idle reliable; no wake freezes.

## Hardware Constraint

AMD Strix Point HX 370 does not support S3 deep sleep — `s2idle` is the only valid mode.

## Blockers

- [ ] `mem_sleep_default=s2idle` verified in GRUB cmdline
- [x] NVIDIA suspend hooks enabled — depends on `fix/proart-nvidia` — **implemented in `nvidia.yml` (Phase 3, S196+), pending reboot verification on hardware.** Requires `xorg-x11-drv-nvidia-power` (wired into the akmod-nvidia install task in `fix/proart-nvidia`).
  - `nvidia-suspend.service` — enabled
  - `nvidia-hibernate.service` — enabled
  - `nvidia-resume.service` — enabled
- [x] `NVreg_PreserveVideoMemoryAllocations=1` in `/etc/modprobe.d/` (survive suspend without VRAM corruption) — **implemented** in `/etc/modprobe.d/rabble-nvidia-powermgmt.conf` (Phase 3), alongside `NVreg_DynamicPowerManagement=0x02`; requires a reboot to take effect, pending verification on hardware.
- [ ] `journalctl -b -u systemd-suspend` clean after 3× cycle

## Verification

```bash
cat /sys/power/mem_sleep          # must show [s2idle]
journalctl -b -u systemd-suspend  # after suspend/resume cycle
systemctl status nvidia-resume    # NVIDIA service healthy
```

→ `fix/RaBbLE-OS-Fix-Nvidia.md` — NVIDIA defer pattern (prerequisite)
→ `hardware/RaBbLE-OS-Hardware-ProArtP16.md` — ProArt P16 sleep path
