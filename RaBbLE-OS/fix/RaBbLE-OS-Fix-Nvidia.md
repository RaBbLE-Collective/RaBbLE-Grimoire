# RaBbLE-OS-Fix-Nvidia.md — fix/proart-nvidia

**Branch:** `fix/proart-nvidia`
**State:** `%HIGH_ENTROPY%`
**Goal:** NVIDIA RTX 4060 Optimus stable on Hyprland + Wayland.

## GPU Architecture

```
AMD Radeon 890M (iGPU)              NVIDIA RTX 4060 Mobile (dGPU)
  Drives Wayland display              PRIME offload only
  Compositor: Hyprland                DRI_PRIME=pci-0000_64_00_0 <cmd>
  AQ_DRM_DEVICES=                     CUDA available always
    pci-0000:65:00.0-card             No direct display in Hybrid mode
  [eDP-1: 3840×2400 @60Hz, 2×]       Loads at graphical.target — not initramfs
```

## Open Blockers

- [x] `nvidia-drm modeset=1` not set (only `fbdev=1`); `supergfxd.conf` does not set it — **implemented in `nvidia.yml` (Phase 3, S196+), pending reboot verification on hardware.** Now set explicitly alongside `fbdev=1` in `rabble-nvidia-wayland.conf`.
- [ ] NVIDIA modules not blacklisted from initramfs → Plymouth black flash
- [x] `nvidia-suspend/hibernate/resume.service` not enabled by role — **implemented in `nvidia.yml` (Phase 3), pending reboot verification on hardware.** Requires `xorg-x11-drv-nvidia-power` (added to `manifest.yml` + wired into the akmod-nvidia install task); also enables `nvidia-powerd.service` per the documented stack (Dynamic Boost 2.0, not an idle-power fix).
- [ ] `AQ_DRM_DEVICES` pinned by card number — brittle across kernel upgrades (switch to by-path)
- [ ] `LIBVA_DRIVER_NAME=nvidia` system-wide — too broad for hybrid

## D3cold Fix (Idle Power)

Primary cause of high idle draw: GPU stuck in D0 (active).

**Status: implemented in `nvidia.yml` (Phase 3, S196+), pending reboot verification on hardware — not yet confirmed against real power-draw numbers.**

```bash
# /etc/modprobe.d/rabble-nvidia-powermgmt.conf
options nvidia NVreg_DynamicPowerManagement=0x02  # fine-grained → D3cold
options nvidia NVreg_PreserveVideoMemoryAllocations=1
# notify: regenerate initramfs (task handler) — then REBOOT before this takes effect.
```

Do NOT enable `nvidia-persistenced` — keeps GPU in D0. (Confirmed not enabled by the role.)
`nvidia-powerd.service` is now enabled — Dynamic Boost 2.0 (perf/clock arbitration), **not** an idle-power reducer; included for stack completeness only.

Verify (after reboot — real numbers TBD, owned by `verify/RaBbLE-OS-Verify-PowerTesting.md`):
```bash
NV_PCI=$(lspci -d 10de: -D | awk '{print $1}')
cat /sys/bus/pci/devices/$NV_PCI/power_state   # target: "D3cold"
```

## Verification

- [ ] `layerctl apply hardware` is idempotent — second run changes nothing
- [ ] `nvidia-smi` returns output post-boot
- [ ] 3 consecutive suspend/resume cycles preserve session
- [ ] No Plymouth black flash
- [ ] `glxinfo -B` → AMD default, NVIDIA via `DRI_PRIME=1`

→ `fix/RaBbLE-OS-Fix-Suspend.md` — suspend/resume hooks (depends on this fix)
→ `layers/RaBbLE-OS-Layer-Hardware.md` — hardware layer overview
→ `verify/RaBbLE-OS-Verify-PowerTesting.md` — power measurement protocol
