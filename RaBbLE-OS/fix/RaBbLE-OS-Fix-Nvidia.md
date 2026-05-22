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

- [ ] `nvidia-drm modeset=1` not set (only `fbdev=1`); `supergfxd.conf` does not set it
- [ ] NVIDIA modules not blacklisted from initramfs → Plymouth black flash
- [ ] `nvidia-suspend/hibernate/resume.service` not enabled by role
- [ ] `AQ_DRM_DEVICES` pinned by card number — brittle across kernel upgrades (switch to by-path)
- [ ] `LIBVA_DRIVER_NAME=nvidia` system-wide — too broad for hybrid

## D3cold Fix (Idle Power)

Primary cause of high idle draw: GPU stuck in D0 (active).

```bash
# /etc/modprobe.d/rabble-nvidia-powermgmt.conf
options nvidia NVreg_DynamicPowerManagement=0x02  # fine-grained → D3cold
# Then: sudo dracut -f --regenerate-all
```

Do NOT enable `nvidia-persistenced` — keeps GPU in D0.
Enable `nvidia-powerd` for Dynamic Boost 2.0.

Verify:
```bash
cat /sys/bus/pci/devices/0000:01:00.0/power_state   # target: "D3cold"
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
