# RaBbLE-OS-Verify-PreviewFloor.md — EP1 Developer Preview FLOOR Gate

```
transcribe ~ substrate >> the gate before we say "preview-ready" // %OS_EP1_PREVIEW%
```

> **Purpose:** prove the EP1 Developer Preview FLOOR on a **clean `generic_x64` VM** —
> the universal bar, NOT the maintainer's ProArt. Run this before any "OS is EP1-ready"
> claim. FLOOR all-green = the preview can ship.
>
> Preview Bar definition lives in `RaBbLE-OS-Roadmap.md`. This file is the runbook that
> verifies the VM-gated items (F1, F2, F4). F3 is a static audit. F5 is a doc (done).

## Prerequisites

- Host VM tooling prepared: `./RaBbLE-OS-vmctl.sh setup` (one-time)
- Fedora netinstall ISO present: `ISO/Fedora-Everything-netinst.iso`
- On branch `new-horizons`; `RaBbLE-OS.ks` present in repo root
- Run all `vmctl` commands from the **RaBbLE-OS repo root**

> VM caveat: a headless VM has no real GPU/audio. Surfaces that need hardware (swayOSD
> volume levels, brightness keys, HDMI hotplug) verify on metal, not here — note them as
> "metal-only" rather than failing the gate.

---

## F1 — Install works (generic x86_64)

Clean install end-to-end: KS → Anaconda → reboot → **firstboot → SDDM**.

```bash
./RaBbLE-OS-vmctl.sh recast ISO/Fedora-Everything-netinst.iso   # destroy + cast-ks
./RaBbLE-OS-vmctl.sh status                                     # watch state/IP
./RaBbLE-OS-vmctl.sh console                                    # observe Anaconda → reboot
```

After the post-install reboot, the firstboot service runs Bootstrap (`base,boot` tags).

**PASS criteria:**
- [ ] KS install completes, VM reboots on its own (no manual `reboot`)
- [ ] Firstboot service runs and **succeeds** — verify in the VM:
      `systemctl status firstboot* ; journalctl -u firstboot* -b`
- [ ] **SDDM greeter appears** (graphical.target reached) — NOT dropped to TTY
- [ ] (`This is the single biggest unverified FLOOR item — Phase 4 left it "pending".`)

**If it fails:** capture `journalctl -b` from the VM; firstboot package-download failures
point at the Phase 4B "KS owns packages" refactor (move installs into `%packages`).

---

## F2 — Recovery without a dead-end

Recovery shell must open **without a root password** (root stays locked).

```bash
# In the VM, confirm the drop-ins shipped:
cat /etc/systemd/system/emergency.service.d/rabble-sulogin-force.conf
cat /etc/systemd/system/rescue.service.d/rabble-sulogin-force.conf   # expect SYSTEMD_SULOGIN_FORCE=1

# Force emergency mode and confirm a shell opens with no password prompt:
sudo systemctl emergency
```

**PASS criteria:**
- [ ] Both drop-in files present with `Environment=SYSTEMD_SULOGIN_FORCE=1`
- [ ] `systemctl emergency` lands on a **root shell with no password prompt**
- [ ] `rd.break` path works: at GRUB add `rd.break`, reach initramfs, `mount -o remount,rw
      /sysroot && chroot /sysroot` succeeds (matches the F5 sheet instructions)
- [ ] `systemctl default` / `exit` resumes normal boot

**Implemented S109:** `core/tasks/recovery.yml` (commit `aaf87b9`). This pass *verifies* it.

---

## F3 — No hard boot dependency can brick (static audit)

```bash
# In the VM (or inspect the role): every optional mount must carry nofail.
findmnt --fstab
grep -vE '^\s*#' /etc/fstab    # confirm optional/data mounts have nofail
```

**PASS criteria:**
- [ ] fstab-safety enforcement present (`ansible/roles/virtualization/tasks/fstab-safety.yml`)
- [ ] No optional mount lacks `nofail`
- [ ] No service in the boot path hard-fails the machine if absent (spot-check enabled units)

---

## F4 — Boots to graphical, core surfaces live

Log into the Hyprland session in the VM, then run the **Session** block of
`RaBbLE-OS-Verify-Checklist.md`. Hardware-dependent rows are metal-only (see caveat).

**PASS criteria (VM-checkable):**
- [ ] Hyprland session starts, wallpaper visible
- [ ] Waybar renders (clock, workspaces, tray)
- [ ] `Super+Space` → Fuzzel opens
- [ ] Kitty opens with RaBbLE palette
- [ ] `notify-send "test" "body"` → Mako notification fires
- [ ] Hyprlock triggers via `loginctl lock-session`
- [ ] *(metal-only: swayOSD volume/brightness, Fn keys, HDMI hotplug)*

---

## Results

Record each run below; promote any failure into `fix/RaBbLE-OS-KnownIssues.md`.

| Date | Item | Result | Notes |
|---|---|---|---|
| — | F1 | ⬜ unrun | firstboot→SDDM never verified |
| — | F2 | ⬜ unrun | mechanism committed `aaf87b9` |
| — | F3 | ⬜ unrun | fstab-safety exists |
| — | F4 | ⬜ unrun | swayOSD landed S108 |

**Gate:** F1–F4 all PASS (VM rows) + F5 sheet shipped = Preview FLOOR met → OS is
"EP1 Developer Preview ready."

→ `verify/RaBbLE-OS-Verify-Checklist.md` — full session/shell checklist (this references its Session block)
→ `RaBbLE-OS-Roadmap.md` — the Preview Bar (FLOOR / HARDEN / DEFER) this gate enforces
→ `../RaBbLE-OS-KnownRoughEdges.md` — the F5 sheet that ships with the preview
```
