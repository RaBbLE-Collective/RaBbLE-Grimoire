# HANDOFF-S236: RaBbLE-OS ISO, interactive VM run

> Cold start for the next agent. **Next up: boot `RaBbLE-OS/ISO/RaBbLE-OS-new-horizons.iso` itself in a
> fresh VM (UEFI, virtual CD, host GPU via egl-headless). Mark clicks through the 3 interactive screens;
> you watch `%post` and verify first boot.** Then retry the bare-metal desktop from the Ventoy stick.
> Background: `RaBbLE-OS/ops/RaBbLE-OS-Ops-Install.md` (install path, KS markers, chroot-safety rules).

## State at handoff (S236 close, 2026-09-27)

- **ISO:** rebuilt 21:42 by Mark after the last fixes. Embedded KS has `@hardware-support`,
  org URLs, the Aether clone and the dotctl step. sha256 prefix `fc320a2a`. It is **not yet on the
  Ventoy stick**: the stick has the 20:46 build (sha `975876d8`, no firmware group, no Hyprland/SDDM
  fixes). Copy it over before the bare-metal retry (`udisksctl mount -b /dev/sda1` →
  `LinuxISO/`, verify with `dd iflag=direct | sha256sum`, then `udisksctl power-off -b /dev/sda`).
- **All code pushed**, `new-horizons` in sync on OS, Aether, Grimoire and Collective. All four repos are
  **public** under `github.com/RaBbLE-Collective` (Aether was flipped public S236; the install clones
  anonymously, so it must stay public).
- **Unattended VM (`rabble-os-s236`) PASSED** on OS `184d78e`: in-installer Bootstrap 207 ok / 0 failed,
  `.setup-complete` written, dotfiles deployed, SELinux enforcing, themed SDDM showing RaBbLE, login
  works. That run predates the last five fixes (below), so it showed: first login lands in GNOME;
  Hyprland aborts (`CBackend::create() failed!`: ProArt GPU pin plus no 3D in the VM); GNOME background
  Fedora blue.
- **Bare-metal desktop FAILED** (20:46 ISO, Ventoy): after reboot, TTY instead of SDDM, no network, and
  `rabble-os-setup.service` waiting for network. **No logs captured**: Mark can't easily type on or
  remote into the desktop. Leading hypotheses, both addressed by `f65edff` (`@hardware-support`):
  (1) `@core` has no WiFi firmware, so WiFi works in the installer (which ships firmware) and dies after
  reboot; (2) no GPU firmware (`amd-/nvidia-/intel-gpu-firmware`), so the DRM driver never comes up and
  SDDM can't start. Unconfirmed: the in-installer Bootstrap may also have failed for its own reasons.
- **Fixes after the passing VM run (untested on a real install):**
  - OS `63caf40`: ProArt GPU pin + NVIDIA env moved out of `config/hypr/conf_d/env.lua` into
    `conf_d/machine.lua`, written only by the ProArt hardware role (`tasks/hypr-machine.yml`); env.lua
    does `pcall(require, "conf_d.machine")`. **Not yet proven:** that Hyprland's Lua allows
    `pcall(require, …)` of a missing module (a probe of Lua `io` in the VM returned nothing; unresolved).
  - OS `d887d49`: SUPER+SHIFT+←/→ → `smart-movewindow.sh l|r` (were bare tables, rejected).
  - OS `a58351e`: GNOME system wallpaper `/usr/share/backgrounds/rabble/RaBbLE_WP.png` + dconf
    background/screensaver keys; removed with the layer.
  - OS `72fa398`: SDDM session switch shows the session name via notify; fresh install (no lastUser)
    defaults to the session named exactly `Hyprland` (not the uwsm one).
  - OS `f65edff`: `@hardware-support` in KS `%packages` + `spells/generate-kickstart.py`.

## The run

```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
virt-install --connect qemu:///system --name rabble-os-iso \
  --ram 4096 --vcpus 4 --cpu host-passthrough --os-variant fedora43 \
  --disk path=/mnt/vms/rabble-os-iso.qcow2,size=20,format=qcow2,bus=virtio \
  --cdrom ISO/RaBbLE-OS-new-horizons.iso --boot uefi \
  --network network=default,model=virtio \
  --video virtio,accel3d=yes \
  --graphics spice --graphics egl-headless,rendernode=/dev/dri/renderD128 \
  --noautoconsole
setsid -f virt-viewer --connect qemu:///system rabble-os-iso   # Mark drives the installer here
```

- `renderD128` is the host **AMD** GPU (`renderD129` = NVIDIA). vmctl turns GL off because SPICE-GL
  can't reach Mark's Wayland socket from system libvirt; egl-headless sidesteps that. **Unverified**: if
  the domain refuses to start, drop `accel3d` + egl-headless (Hyprland will then abort for lack of
  GPU, a VM limitation, but the rest of the test still counts).
- **Expect at boot:** hostname `rabble-os` preset; only Installation Destination, User Creation (tick
  admin) and Network left. Everything else asked = KS not loaded (stop; that's the ISO boot path).
- The bare-metal ISO has **no serial console** (`console=ttyS0` is VM-only via `#@VM@`), so watch via
  the display: `virsh send-key rabble-os-iso KEY_LEFTCTRL KEY_LEFTALT KEY_F2` for the installer's root
  shell, type with `virsh send-key` (one key per call; map chars to KEY_* names), then
  `virsh screenshot rabble-os-iso /path.ppm` and read it. Log: `/mnt/sysroot/var/log/rabble-os-install.log`
  (`grep -c '^TASK'`: a full run is ~210; `grep '^fatal'`).
- `--noautoconsole` installs **power the domain off** at the final reboot: `virsh start` it again.
- After first boot there's no serial console either, so check through the GUI (Mark) or a TTY via
  `virsh send-key`. Checks: `/var/lib/rabble-os/.setup-complete` exists;
  `grep -A1 'PLAY RECAP' /var/log/rabble-os-install.log` shows `failed=0`; `~/.config/hypr` present.

## Success criteria

1. KS loads from the ISO (only the 3 interactive screens).
2. `%post` Bootstrap `failed=0`, marker written, no first-boot retry.
3. SDDM themed, shows the created user, default session **Hyprland**; the ⊞ session button flashes the
   session name.
4. Hyprland session starts (with 3D). If it aborts, get its output with `journalctl --user -b -u
   'wayland-wm@*'` or the plain session's `~/.local/share/hyprland/` log; check `machine.lua` isn't present.
5. GNOME session shows the RaBbLE wallpaper, not blue.

Then: copy the 21:42 ISO to Ventoy, retry the desktop. If bare metal still fails without logs, have Mark
copy `/var/log/rabble-os-*.log` + `journalctl -b -u rabble-os-setup -u NetworkManager` to the Ventoy
stick (exFAT, `sudo mount /dev/sdX1 /mnt`).

## Gotchas learned S236 (don't repeat)

- **Never `virsh undefine --remove-all-storage`**: it deleted the attached Fedora netinstall ISO (restored
  from dl.fedoraproject.org + gpg-verified CHECKSUM). Teardown: `destroy` → `undefine --nvram` → delete
  only the named qcow2; check `virsh domblklist` first. vmctl's own teardown is safe.
- `spells/build-iso.sh` needs sudo (mkksiso rebuilds efiboot.img; `--skip-mkefiboot` would drop inst.ks from
  the UEFI ESP grub.cfg), so it's Mark's step. `vmctl cast-ks` also sudos (setfacl), so drive `virt-install`
  directly as rabble (libvirt group) when Mark isn't at the keyboard.
- The install clones **GitHub**, not the working tree: push before any test.
- On the installed system the RaBbLE zsh config has autocorrect: over serial it hijacks commands
  (`correct 'lspci' to 'lscpu' [nyae]?`). Run checks under `exec bash --norc --noprofile`.
- `lspci` isn't installed on the `@core` target (`pciutils` absent).

## Open (not blocking the run)

- GRUB prints `shim_lock_verifier_init: prohibited by secure boot policy` on first boot (likely a theme
  `insmod`); boot continues.
- os-release / welcome text says "Fedora 43" on Fedora 44 (hardcoded branding version).
- `%post` shows nothing on the installer screen for ~10+ min; consider teeing Ansible task names to the
  installer console.
- KS setup sudoers NOPASSWD grant is never revoked.
- Fallback if the ISO path keeps failing on hardware: Fedora 44 Workstation + clone + Bootstrap. Needs
  `systemctl disable gdm` before the SDDM role (enabling SDDM collides with GDM's display-manager.service
  alias); nothing in the repo does that yet.
- World serves `joinrabble.world/RaBbLE-OS.ks` (S234 `_redirects`): check it points at the
  `new-horizons` template, and note it's the raw template (bare variant, branch placeholder).
- Full Live ISO (Mark deferred it to its own plan), and Ventoy's `auto_install` plugin (stock ISO +
  rendered ks.cfg) as an alternative delivery.
