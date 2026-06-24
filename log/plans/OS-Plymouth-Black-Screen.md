# Plan: Plymouth Boot Splash Black Screen

**Status:** `layerctl apply boot && reboot` run — Plymouth STILL BLACK. Deeper investigation needed.
**Repo:** RaBbLE-OS `new-horizons` · **Last touched:** S160 (2026-06-23)

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

## Applied — Still Black

`sudo layerctl apply boot && reboot` was run (S160, 2026-06-23). Plymouth still black.
`plymouth.use-simpledrm=1` alone is NOT sufficient on this hardware/kernel combination.

## Investigation for Next Session

Start here — compare what the running kernel actually got vs what was committed:

```bash
# 1. Verify cmdline was applied
cat /proc/cmdline | grep -o "plymouth[^ ]*"
# Expected: plymouth.use-simpledrm=1

# 2. Verify initrd was rebuilt after grub change
ls -la /boot/initramfs-$(uname -r).img
ls -la /boot/grub2/grub.cfg
# Check timestamps — initrd should be newer than grub.cfg

# 3. Check the live boot journal for DRM/Plymouth events
journalctl -b | grep -E "drm|plymouth|simpledrm|amdgpu|fb0|framebuffer" | head -50

# 4. Check if Plymouth is actually starting at all
journalctl -b | grep "plymouthd"

# 5. Check if the Plymouth theme frames exist in initrd
lsinitrd /boot/initramfs-$(uname -r).img | grep -E "rabble|png|aether" | head -20

# 6. Check Plymouth theme is installed
ls /usr/share/plymouth/themes/rabble-aether/
```

## Hypotheses for Next Session

**H1: Theme frames not in initrd** — Plymouth starts but shows black because frame PNGs aren't packed into initrd. dracut needs `install_items` for the PNG frames.

**H2: Plymouth crashes silently** — Check `journalctl -b | grep -i "plymouth"` for crash/error messages. If the script errors (missing image, font not found), it falls back to black.

**H3: simpledrm=1 not honored** — Kernel version change may affect behavior. Check if `plymouth.use-simpledrm=1` is in `/proc/cmdline` after reboot.

**H4: Wrong Plymouth theme active** — `/etc/plymouth/plymouthd.conf` might point to a different theme. `plymouth-set-default-theme` may need to be called.

**H5: amdgpu still in initrd and taking over anyway** — `plymouth.use-simpledrm=1` should prevent this but verify with DRM boot journal.

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
