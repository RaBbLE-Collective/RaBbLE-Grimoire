# RaBbLE-OS-Layer-Hardware.md — Layer 1: Hardware

**Role:** `ansible/roles/hardware/x64/<machine>/`
**Tag:** `hardware`
**State:** scaffold only — most subtasks are stubs

## Hardware Targeting

Machine selection is via inventory host group in `ansible/inventory/hosts.yml`.
Place `localhost` under the correct group:

```yaml
# hosts.yml
asus_proart_p16:
  hosts:
    localhost:
# or:
generic_x64:
  hosts:
    localhost:
```

`site.yml` dispatches to the correct hardware role based on group membership.
Hardware roles self-verify using DMI data and warn if the target doesn't match.

## Current Profiles

| Profile | Path | State |
|---------|------|-------|
| `asus_proart_p16` | `hardware/x64/asus_proart_p16/` | scaffold |
| `generic_x64` | `hardware/x64/generic/` | minimal stub |

Override at runtime: `RABBLE_HARDWARE=generic_x64 ./RaBbLE-OS-layerctl.sh apply hardware`

## group_vars

Machine-specific variables in `ansible/inventory/group_vars/asus_proart_p16.yml`:
- HiDPI scale, monitor resolution, console font, GPU device path
- Propagate via Ansible templates to GRUB, SDDM, Hyprland machine.conf

→ `hardware/RaBbLE-OS-Hardware-ProArtP16.md` — ProArt P16 specs, GPU, ASUS platform
→ `hardware/RaBbLE-OS-Hardware-GenericX64.md` — generic/VM profile
→ `hardware/RaBbLE-OS-Hardware-AddingTargets.md` — how to add a new machine
→ `ops/RaBbLE-OS-Ops-ConfigFlow.md` — HiDPI template flow detail
