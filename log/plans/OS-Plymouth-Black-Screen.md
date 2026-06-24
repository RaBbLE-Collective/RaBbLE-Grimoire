# Plan: Plymouth Boot Splash Black Screen

**Status:** Root cause diagnosed S162. Ansible fix committed. Pending: `layerctl apply boot && reboot` to verify.
**Repo:** RaBbLE-OS `new-horizons` · **Last touched:** S162 (2026-06-23)

---

## Root Cause (CONFIRMED via boot journal)

1. `simpledrm` (DRM minor 0, EFI framebuffer) initializes at t+0s
2. Plymouth starts and attaches to simpledrm's device
3. `amdgpu` (DRM minor 1) initializes at t+2s and takes over `fb0`, displacing simpledrm
4. Plymouth's device goes dead → black screen for remainder of boot

`plymouth.use-simpledrm=1` forces Plymouth to stay on the EFI framebuffer throughout. This was removed from `asus_proart_p16.yml` in a previous session with an "UNVERIFIED" note claiming amdgpu-in-initrd would replace it. It doesn't — simpledrm ALWAYS wins the initialization race on this hardware.

## Fix Already Committed

`ansible/inventory/group_vars/asus_proart_p16.yml` — `rabble_grub_extra_cmdline` includes:
```
plymouth.use-simpledrm=1
rd.driver.blacklist=nvidia
```
Committed: `d8f3314`

## Applied — Still Black (S160)

`sudo layerctl apply boot && reboot` was run (S160, 2026-06-23). Plymouth still black.
`plymouth.use-simpledrm=1` alone is NOT sufficient — that was never the problem.

## True Root Cause (Diagnosed S162)

Live diagnostics confirmed two compounding bugs:

**Bug 1 — Initramfs never rebuilt after dracut conf deployed:**
The initramfs timestamp (22:03) predates the dracut conf write (22:54). The Ansible "rebuild initrd" handler is conditional — it only fires when a task reports `changed`. On idempotent re-runs (all files already present, theme already active), zero tasks report `changed`, so `dracut --force` never runs. The stale initramfs contains no fonts, no PNG frames, no amdgpu — confirmed via `lsinitrd`.

**Bug 2 — PNG frames not in `install_items`:**
The dracut conf source in `config.yml` listed fonts but not the theme directory (`/usr/share/plymouth/themes/rabble-aether/`). Plymouth's `95plymouth` dracut module does not reliably auto-include script-module themes with large PNG frame arrays.

## Fix Applied (S162) — Pending Verify

Two changes to `ansible/roles/boot/plymouth/tasks/config.yml`:

1. Added `install_items+=" /usr/share/plymouth/themes/rabble-aether/ "` to inline dracut conf content
2. Added unconditional `dracut --force` task at end of play (`changed_when: true`)

**Verify:** `sudo layerctl apply boot` → `lsinitrd ... | grep -E "entity|aether|amdgpu"` → reboot

## Key Files

| File | Purpose |
|---|---|
| `ansible/inventory/group_vars/asus_proart_p16.yml` | `rabble_grub_extra_cmdline` — cmdline including `plymouth.use-simpledrm=1` |
| `ansible/roles/boot/plymouth/tasks/` | Plymouth installation + theme activation Ansible |
| `ansible/roles/boot/plymouth/files/rabble-aether/rabble-aether.script` | 492-line frame-player script |
| `/etc/dracut.conf.d/90-rabble-plymouth-fonts.conf` | Font injection + `add_drivers+=" amdgpu "` |
| `/etc/plymouth/plymouthd.conf` (live) | Active theme name — verify points to `rabble-aether` |

## Bonus: GRUB Theme

`/boot/grub2/themes/rabble/` is currently absent on live system. `layerctl apply boot` deploys it from `ansible/roles/boot/grub2/files/theme/`. GRUB menu should show styled theme after apply.

## CPUID Warning (Not Fixable)

"RDSEED32 is broken on CPUID" between GRUB and Plymouth is an AMD hardware erratum (pr_warn level 4). It prints before the kernel loglevel takes effect. Cosmetic — not suppressable without losing useful messages. Once Plymouth starts immediately (simpledrm fix), this warning is less noticeable.
