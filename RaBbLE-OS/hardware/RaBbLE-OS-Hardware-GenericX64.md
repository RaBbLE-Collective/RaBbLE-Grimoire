# RaBbLE-OS-Hardware-GenericX64.md — Generic x64 Profile

**Inventory group:** `generic_x64`
**Role path:** `ansible/roles/hardware/x64/generic/`
**Primary use:** VM testing, non-ProArt machines

## What Differs from ProArt P16

- No NVIDIA role — single GPU assumed
- No ASUS platform tools (asusctl, supergfxctl)
- No NPU role
- Monitor config not assumed — no machine.conf template
- power-profiles-daemon without asusd binding

## VM Testing

This profile is used for validating the full `layerctl apply all` path in a QEMU/KVM VM
without triggering hardware-specific roles that would fail in a virtual environment.

After any major Ansible change, run the full bootstrap in a VM snapshot before bare metal.

→ `ops/RaBbLE-OS-Ops-Vmctl.md` — VM lifecycle: cast, start, snapshot, restore
→ `hardware/RaBbLE-OS-Hardware-ProArtP16.md` — ProArt P16 specific hardware
→ `hardware/RaBbLE-OS-Hardware-AddingTargets.md` — how to add a new machine profile
