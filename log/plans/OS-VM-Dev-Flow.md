# Plan: VM Install Unblock + Boot-Theme Dev Flow

**Status:** 🟡 PART 1 DONE (branch parameterized, verified) — PARTS 2 & 3 PENDING (cast VM, build loop spell). Stopped at handoff by request.
**Repo:** RaBbLE-OS `new-horizons` · **Last touched:** 2026-06-25
**Goal:** Boot a VM, install RaBbLE-OS from `new-horizons`, then use the VM as a tight Plymouth/GRUB theme-dev loop. VM testing has been a standing blocker.

---

## 🎯 ROOT CAUSE — why VM install silently failed "for a while"

`RaBbLE-OS.ks` hard-coded git branches that **do not exist on any remote**:

- `COLLECTIVE_BRANCH="dev"`, `GRIMOIRE_BRANCH="dev"` — neither remote has a `dev` branch
  (Collective: `chrysalis/main/new-horizons`; Grimoire: `main/new-horizons`).
- `OS_BRANCH="RaBbLE-OS-New-Horizons"` — OS remote has no such branch (it is `new-horizons`).

Each clone in `%post` was guarded by `|| { echo WARNING; exit 0 }`. A failed `git clone -b dev`
therefore made **`%post` exit 0 — the install "succeeded"** with no repos cloned. The firstboot
`rabble-os-setup.service` has `ConditionPathExists=…/RaBbLE-OS-Bootstrap.sh`, never met, so nothing
bootstrapped. Result: a **bare Fedora text login, no error, no RaBbLE-OS**. That was the blocker —
five sessions of theme work happening on the daily driver because the VM never produced a usable OS.

---

## ✅ PART 1 — DONE: branch parameterized (single source of truth)

Branch is now one value, templated into the KS at cast time exactly like the password hash,
defaulting to the OS repo's current checkout. Override with `--branch <name>`.

Changes made and verified (`bash -n` clean; dry-run sed → all three lines `new-horizons`):

- **`RaBbLE-OS/RaBbLE-OS.ks`** — the three branch literals → `__RABBLE_BRANCH__` placeholder,
  plus a self-contained fallback (`[[ "$X" == __RABBLE_BRANCH__ ]] && X="new-horizons"`) so the KS
  is still correct if ever run without vmctl templating.
- **`RaBbLE-OS/RaBbLE-OS-vmctl.sh`**:
  - Added `REPO_DIR` (realpath of the script) and `RABBLE_BRANCH` config var.
  - `cmd_cast_ks()` parses `--branch <name>`; if unset, resolves `git -C "$REPO_DIR" rev-parse
    --abbrev-ref HEAD` (falls back to `new-horizons` for detached HEAD).
  - The cast-time `sed` now injects both `__RABBLE_PASSWORD_HASH__` and `__RABBLE_BRANCH__`.
  - Resolved branch is echoed in the pre-cast summary. `recast` inherits this (it forwards `$@`).
- **`RaBbLE-OS/spells/vmctl-completions.sh`** — `--branch` added to cast/cast-ks/recast; `--branch`
  completes from local git branches.

> Out of scope (flagged): `RaBbLE-OS-Install.sh` (curl|bash path) still defaults to `main`
> (lines 8, 305). The VM path is `cast-ks`/`recast`, not Install.sh — fix later if that path is used.

---

## ⏳ PART 2 — PENDING: cast the VM (qcow2 on the RaBbLE-VM partition)

**Storage constraint (Mark): qcow2 only, never raw; store on the RaBbLE-VM partition; never reformat it.**

- Partition already exists & mounted: `nvme0n1p6`, 32 GB btrfs, label `RaBbLE-VM`, at `/mnt/vms`
  (safe `nofail` fstab entry). `vmctl` auto-detects it → `VM_DISK_DIR=/mnt/vms` for qcow2 mode
  (`RaBbLE-OS-vmctl.sh:106`). The qcow2 lands there automatically, **no flags needed**.
- **Never pass `--raw-disk`** (hands the partition to the installer → destroys its BTRFS label) and
  **never run `partition-setup`** (reformats). Plain qcow2 mode is non-destructive to the partition.
- A **stale `rabble-os-dev.qcow2` (dated May 28, pre-S150)** already sits on `/mnt/vms` →
  use **`recast`** to destroy+replace it in place.

Run from `~/RaBbLE-Collective/RaBbLE-OS`:

```bash
./RaBbLE-OS-vmctl.sh setup        # start libvirtd (inactive), default NAT net, ISO ACLs (sudo, one-time)
./RaBbLE-OS-vmctl.sh status       # sanity: disk path should be under /mnt/vms
./RaBbLE-OS-vmctl.sh recast --branch new-horizons ISO/Fedora-Everything-netinst-x86_64-44-1.7.iso
# monitor:
./RaBbLE-OS-vmctl.sh console                 # serial; Ctrl+] to exit
./RaBbLE-OS-vmctl.sh ssh                      # once networked
./RaBbLE-OS-vmctl.sh logs rabble-os-setup     # firstboot Bootstrap (base+boot+desktop)
# at the SDDM greeter:
./RaBbLE-OS-vmctl.sh snapshot boot-clean
```

VM defaults: `rabble-os-dev`, 4 GB RAM, 4 vCPU, 20 GB sparse qcow2. ~15–30 min unattended.

**Host readiness (verified 2026-06-25):** KVM/AMD-V present, `/dev/kvm` ok; `qemu-system-x86_64`,
`virt-install`, `virsh`, `virt-manager`, `qemu-img` installed; both Fedora 44 ISOs in `RaBbLE-OS/ISO/`;
138 GB free on `/`, 20 GB free RAM; user in `kvm`+`libvirt` groups; libvirtd currently **inactive**
(→ `vmctl setup` first). `mkksiso`/`lorax` absent but **not needed** — install is netinst+KS, not a custom ISO build.

---

## ⏳ PART 3 — PENDING: tight boot-theme loop (`spells/vm-boot-iterate.sh`, new)

**Why a VM:** host boot spells (`spells/test-plymouth.sh`, `spells/sddm-screenshot.sh`) need DRM
master / a bare VT and only render on a *real* boot — unusable from inside Hyprland on the daily
driver; Plymouth has no live preview. `virsh screenshot` (confirmed available) grabs the guest's
**actual** GRUB/Plymouth/SDDM framebuffer from outside — no VT switching, no DRM dance.

New host-side spell, one command per iteration:

1. **rsync** working-tree `ansible/roles/boot/` → guest `~/RaBbLE/RaBbLE-OS/ansible/roles/boot/`
   over SSH (reuse vmctl's `vm_ip` / ssh opts). No commit/push needed — this is the working-tree → VM bridge.
2. **apply**: `vmctl ssh sudo ./RaBbLE-OS-layerctl.sh apply boot` (runs grub2-mkconfig + `dracut --force`
   in the guest — the steps that ship the theme into the boot image).
3. **reboot**: `vmctl ssh sudo reboot`.
4. **capture**: `virsh screenshot rabble-os-dev --file <out>` on a ~0.5 s loop for ~12 s to catch
   GRUB → Plymouth → SDDM. Save to `RaBbLE-BaBbLE/captures/Boot/vm-<timestamp>/`.
5. Print capture dir + one-line summary.

Flags: `--no-reboot` (sync+apply only), `--capture-only` (screenshot a boot, no sync),
`--restore` (roll back to `boot-clean` snapshot before applying — fast clean-state iteration).

In-guest `boot-debug-toggle.sh` / `boot-diagnose.sh` already work via `vmctl ssh` for the
black-screen decision tree — no change needed.

**Bonus:** S170 left a Plymouth fix awaiting a verify-reboot (see `OS-Plymouth-Black-Screen.md`).
First run of this loop doubles as that verify — confirm the rabble-aether splash renders in the VM
screenshot without rebooting Mark's laptop.

---

## Verification (full set, for when Parts 2–3 run)

1. **Templating (no VM):** `grep -n 'BRANCH=' /tmp/RaBbLE-OS.ks` after a cast → all `new-horizons`. ✅ proven via dry-run.
2. **Install end-to-end:** `vmctl console` shows `%post` cloning all three repos (no "clone failed"),
   reboot, `vmctl logs rabble-os-setup` shows Ansible base→boot→desktop, lands on SDDM. (Proof blocker is gone.)
3. **Boot chain renders:** `virsh screenshot` shows GRUB (native/4K, doubled fonts), rabble-aether
   Plymouth splash (entity+wordmark, not black), SDDM.
4. **Loop works:** trivial GRUB tweak (color in `grub2/templates/theme.j2`) → `vm-boot-iterate.sh` →
   change appears in the post-reboot screenshot, no commit.
5. **Snapshot/restore:** `vmctl restore boot-clean` returns clean.

## End-of-session (when resumed and complete)

- `bash spells/blockers.sh resolve <id> "VM install unblocked: KS branch refs parameterized"` if a
  matching blocker exists.
- Update `log/SESSION-LOG.md` LATEST + add the root cause (stale KS branches).
- Commit (Pulse Protocol): `mend ~ os/install >> KS branch refs parameterized, VM install unblocked // %STATE%`.
- `bash spells/end-session.sh vm-bootdev "<note>"`.
