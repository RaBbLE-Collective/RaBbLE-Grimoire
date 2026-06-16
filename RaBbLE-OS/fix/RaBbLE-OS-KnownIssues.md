# KnownIssues.md — Active Bugs & Drift Events

```
harmonize ~ grimoire >> surfacing the static // %DRIFT_TRACKING%
```

> This is the live tracker of known bugs, workarounds, and `%SYSTEM_DRIFT%` events.
> Items here are actionable. Resolved items are marked and dated, not deleted.
> Vague ideas and feature wishes live in `RaBbLE-Roadmap.md`, not here.

---

## Active Issues `[OPEN]`

### System Recovery

**Emergency mode inaccessible — root locked (Fedora default)** `[EP1 PREVIEW FLOOR · F2]`
- Fedora installs with root locked by default (security posture: no default-credential/remote-root surface — this is *why* it's the default, and we keep it)
- Consequence: emergency/rescue runs `sulogin`, which refuses when root is locked → dead end. Any fstab failure (missing partition, wrong label, no `nofail`) drops here with no way in
- Mitigation in place: all optional mounts MUST use `nofail` in fstab (enforced by Ansible virtualization role)
- **Decided fix (S109) — NOT a root password (rejected as legacy):**
  1. `SYSTEMD_SULOGIN_FORCE=1` drop-in on `emergency.service` + `rescue.service` → spawns a root shell even with root locked (systemd's documented escape hatch). Keeps locked-root posture.
  2. Ship `rd.break` + live-USB recovery instructions in the "Known Rough Edges" sheet (initramfs root shell for fstab-bricked boots — no password needed).
  3. Document the trade-off honestly: console/physical access → root with no password. Acceptable for a single-user "enter at your own risk" preview; LUKS full-disk encryption is the real mitigation (deferred to EP2).
- Status: nofail mitigates; sulogin-force + recovery doc is the EP1 FLOOR target

---

### Boot Chain

> **Tackle-together work-package (Mark · EP2):** the 4K-font items below (GRUB font
> microscopic, TTY font shifts size) get fixed in one pass alongside **GRUB theming +
> "USB boot from GRUB"** — done coherently, not piecemeal (Mark has been down this
> rabbit hole before). The "USB boot from GRUB" piece also completes part of **F2
> recovery** (the live-USB recovery path) — one effort, don't duplicate. These are
> **display-specific (hi-DPI)**: not a generic_x64 FLOOR blocker, but a documented
> rough edge in the F5 "Known Rough Edges" sheet for anyone on a 4K panel.

**GRUB2 — background image bit depth mismatch**
- `GRUB_GFXMODE=3840x2400x32` requests 32bpp; GRUB's background renderer requires ≤24bpp
- Fix: remove background image from `theme.txt` entirely — use color-only theme (`bgcolor = "#0a0010"`)
- Pure neon-on-void is more on-brand than a texture; no image handoff needed
- Role: `boot/grub2` — `theme.txt` background entry to be removed

**GRUB2 — font microscopic at 4K**
- Default GRUB font renders at ~6px at 3840x2400; `grub2-mkfont` task not yet implemented in role
- Fix: compile `ter-v32b` via `grub2-mkfont -s 32 /usr/share/fonts/terminus/ter-v32b.pcf.gz -o /boot/grub2/fonts/ter-v32b.pf2`; set `GRUB_FONT=/boot/grub2/fonts/ter-v32b.pf2`
- Handler must run `grub2-mkfont` before `grub2-mkconfig`
- Role: `boot/grub2`

**TTY font — shifts size during boot**
- Initial kernel framebuffer uses built-in console font; `vconsole.conf` kicks in later after initramfs pivot
- Fix: add `fbcon=font:TER16x32` to `GRUB_CMDLINE_LINUX` to front-load a readable font before systemd
- Role: `boot/grub2` — cmdline addition

**Plymouth — DejaVu font / wrong palette colors**
- Plymouth `.script` file hardcodes `DejaVu` font; color values are stale pre-palette-lock
- Fix: update hex values to canonical palette (`#ff2d78`, `#bf5fff`, `#0a0010`); replace font reference
- Role: `boot/plymouth` — `rabble.script` requires edit

**Plymouth — black flash / NVIDIA DRM reset mid-boot**
- Root cause: NVIDIA akmod loads mid-boot, triggers DRM subsystem reset, Plymouth reinitializes — visible as black flash before SDDM
- Fix: defer NVIDIA modules from initramfs; load at `graphical.target` after SDDM starts
  1. Blacklist `nvidia`, `nvidia_drm`, `nvidia_modeset`, `nvidia_uvm` via `/etc/modprobe.d/rabble-nvidia-defer.conf`
  2. Rebuild initramfs: `dracut -f --regenerate-all`
  3. Add `rd.driver.blacklist=nvidia` to `GRUB_CMDLINE_LINUX`
  4. Enable `nvidia-load.service` ordered `After=sddm.service`
- Side effect: `nvidia-smi` unavailable before login — acceptable
- Roles: `hardware/x64/asus_proart_p16` — new subtask `nvidia_defer.yml`; `boot/grub2` — cmdline update

**Plymouth — void background continuity (verify)**
- Plymouth background `#0a0010` confirmed correct in script
- Must verify GRUB `bgcolor` in `theme.txt` and SDDM background QML also match `#0a0010`

**SDDM theme — Main.qml needs Qt6 API validation**
- Custom `themes/sddm/rabble/Main.qml` untested against Qt6 SDDM API; Breeze active as fallback
- Test path: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble`

---

### Desktop / Hyprland

**Hyprland windowrule config incomplete**
- `windowrules.conf` and `workspaces.conf` disabled due to v0.54 breaking change (`windowrulev2` removed)
- Migration is mechanical: `windowrulev2 = rule, class:^(app)$` → `windowrule = rule, class:^(app)$`
- Matcher syntax is identical — only the directive name changes
- Status: files need rewriting; desktop functionality reduced until restored

**No focus-retention windowrule available in current Hyprland build**
- `stayfocused` — invalid field type (does not exist in this build)
- `dimaround` — invalid field type (does not exist in this build)
- Note: all boolean windowrules require an explicit value (`true`) — bare rule names fail with "missing value"
- termfilechooser portal currently relies on `float + center` only; no focus-lock equivalent wired
- Revisit when Hyprland documents a focus-retention windowrule; track upstream issue

**Hyprland.conf GPU config can break login**
- GPU env vars must live in `machine.conf` (Ansible-templated), not in the main `hyprland.conf`
- If login breaks: drop to TTY, edit `~/.config/hypr/machine.conf`, retry

**Qt theme env vars not explicitly set**
- KDE removed but `QT_QPA_PLATFORMTHEME` and `QT_STYLE_OVERRIDE` not yet set explicitly
- Fix: set in `xdg-environment.conf.j2` — `adwaita-dark` as interim, `kvantum` as long-term target

**Hyprland wallpaper not managed by Ansible**
- `hyprpaper.conf` requires a machine-local wallpaper path; role does not create it
- Workaround: manually create `~/.config/hypr/hyprpaper.conf`

**hypridle — crashes or instability reported**
- hypridle has been unstable in some configurations
- Monitor: `journalctl -f -u hypridle`; workaround: manually invoke `hyprlock`

**Keyboard hotkeys (F1-F12) — partial function, no OSD**
- Some function keys work; no OSD overlay for volume/brightness
- Fix: wire ASUS key bindings in Hyprland config; install `swayosd` or `wob` for overlay
- Status: not yet addressed

**File managers — installed, need wiring + theme polish** `[EP1 PREVIEW · HARDEN]`
- Stale entry corrected (S109): Dolphin **and** Yazi are both installed — earlier "no FM selected" note was out of date (FM work happened but went unlogged; see multisession log-clobber pain below)
- Remaining: Yazi needs more wiring (keybinds/opener/preview integration); Dolphin has theme-polish issues + could be tied into the desktop better
- Tier: HARDEN, not FLOOR — a tiling-WM-literate user has working FMs; this is polish

---

### Shell & Terminal

**ZSH XRT prompt artifact**
- Stale XRT-related prompt prefix appears at top of new terminal sessions
- Fix: audit `~/.config/environment.d/` and zsh init files for XRT exports

**Kitty not themed**
- Kitty installed via lionheartp COPR but no RaBbLE theme applied
- No `kitty.conf` in `config/shell/kitty/` yet

**Waybar unthemed and limited functionality**
- Waybar running on default theme; not RaBbLE palette; limited to display-only
- Fix: create `config/waybar/config.jsonc` and `config/waybar/style.css`

**Quickshell — build from source fragile**
- Not packaged for Fedora; build from source is unstable
- Waybar active in the meantime; not prioritized until Phase 1.2

---

### Ansible / Infrastructure

**Bootstrap script — partially functional**
- Ansible install via pipx working; menu-driven deployment needs further review
- Direct Ansible invocation is the reliable path for now

**deploy-config — claimed success but did not symlink (intermittent)**
- Intermittent issue; likely `force: true` or idempotency problem in the `file` module
- Workaround: run the playbook twice; verify with `ls -la ~/.config/hypr/`

**asusd not starting on boot (intermittent)**
- Fix: `systemctl enable --now asusd`; check `/etc/asusd/` config syntax
- Monitor: `journalctl -u asusd --since "5 min ago"`

---

### Dev Flow

**Multisession log-clobber — concurrent agents overwrite shared logs** `[OPEN · DEV-FLOW]`
- Concurrent agent sessions clobber shared files (SESSION-LOG, ISSUES, KnownIssues) and the git index; work gets lost or has to be redone "treading carefully" (e.g. FM work that never got logged)
- EP1 discipline (until the post-EP1 ticketing rework): **append-only** capture, per-session dated blocks — never edit another session's region; commit with `--force-with-lease`; treat shared-region edits as tread-carefully
- Real fix: ticket tracking + per-entry files (no shared monolith to clobber) — post-EP1, possibly Collective-wide (see Roadmap → Episode 2 tightening initiative)

---

### Hardware / Power

**Suspend/resume stability — unverified**
- s2idle + NVIDIA suspend hook stack not fully verified in current state
- Re-verify after NVIDIA defer pattern lands
- Check: `journalctl -b -u systemd-suspend` after a suspend/resume cycle

**XDNA2 NPU — XRT packages availability for Fedora 43**
- AMD XRT packages may not be available on `repo.radeon.com` for Fedora 43
- ONNX Runtime VitisAI EP falls back to CPU if XRT unavailable
- Status: needs verification

---

### VM Partition / vmctl

**vmctl --raw-disk could destroy host RaBbLE-VM partition `[FIXED S41]`**
- `vmctl cast-ks --raw-disk /dev/nvme0n1pX` would pass the RaBbLE-VM BTRFS partition directly to virt-install
- The KS installer's `clearpart --all --initlabel` wiped the BTRFS filesystem and `RaBbLE-VM` label
- Because `/etc/fstab` mounted by label with `defaults` (no `nofail`), the daily driver dropped to emergency mode on next boot
- **Fix (S41):**
  1. vmctl now blocks `--raw-disk` when the target device is the RaBbLE-VM partition
  2. fstab entry uses `nofail,x-systemd.device-timeout=5s` — system boots regardless of partition state
  3. Ansible virtualization role checks and corrects fstab entries missing `nofail`
  4. `vmctl destroy` warns if the RaBbLE-VM label is missing post-cleanup
- **Rule:** VM tooling must NEVER create hard boot dependencies. The VM partition is optional infrastructure.

---

## Resolved Issues `[FIXED]`

| Date | Issue | Resolution |
|---|---|---|
| 2026-04-08 | Monitor resolution wrong (reported 1920x1200) | Set `monitor = eDP-1,3840x2400@60,0x0,2` in `machine.conf`; `AQ_DRM_DEVICES` by PCI path |
| 2026-04-08 | Sleep state incorrect (S3 instead of s2idle) | Set `mem_sleep_default=s2idle` in GRUB cmdline; NVIDIA sleep hooks deployed |
| 2026-04-08 | `site.yml` role name mismatch (`ai-stack` vs `AI-tools`) | Corrected role name in `site.yml` |
| 2026-04-08 | Arch Linux references in docs | All Arch references purged; Fedora 43 locked as base |
| 2026-04-08 | SDDM locale warning (`ANSI_X3.4-1968`) | `localectl set-locale LANG=en_US.UTF-8` — automated in core role |
| 2026-04-12 | greetd/tuigreet in docs and roadmap | Removed; SDDM is canonical session manager |
| 2026-04-13 | KDE packages present on system | Manually purged; `purge-kde/tasks/main.yml` written to codify |
| 2026-04-13 | KDE theming artifacts in Hyprland | Resolved by KDE removal; Qt env vars to be set explicitly (tracked above) |
| 2026-04-13 | Bootstrap Ansible install broken | Fixed: `pipx install --include-deps ansible` |
| 2026-04-13 | Hyprland black screen on update | v0.54 windowrule breaking change; clean reinstall; COPR switched to lionheartp |
| 2026-04-13 | Snapper active but non-functional | grub-btrfs not available on Fedora 43; bootable snapshots not achievable; deferred to post-v1 |
| 2026-05-23 | vmctl --raw-disk destroyed RaBbLE-VM partition + fstab lacked nofail → emergency mode | Blocked --raw-disk on VM partition; fstab nofail enforced; Ansible safety check added |

---

## GParted GUI — Segfault on Hyprland + Fedora 43 `[RESOLVED S33]`

Replaced with `gnome-disk-utility`. Root cause: glycin-svg bubblewrap sandbox incompatible
with polkit + Wayland. CLI fallback if needed:
```bash
sudo parted /dev/nvme0n1p6 print
sudo mkfs.btrfs -L label /dev/nvme0n1p6
# Or: ./RaBbLE-OS-vmctl.sh partition-setup /dev/nvme0n1p6
```

---

```
harmonize ~ grimoire >> issues surfaced, drift tracked // %DRIFT_TRACKING_LOCKED%
```

→ `fix/RaBbLE-OS-Fix-BootChain.md` — boot chain specific blockers
→ `fix/RaBbLE-OS-Fix-Nvidia.md` — NVIDIA Optimus blockers
→ `fix/RaBbLE-OS-Fix-Suspend.md` — suspend/resume blockers
