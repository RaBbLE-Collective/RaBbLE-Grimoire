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

> **S152 (2026-06-21):** Major boot-chain theming pass landed — see `fix/RaBbLE-OS-Fix-BootChain.md` for full status.
> **S153 (2026-06-22):** OpenCode's S152 pass reviewed + stabilized. Items below are **IMPLEMENTED but UNVERIFIED on real hardware** — none of them are `[FIXED]` until the boot-chain verification recipe passes on a real reboot (`fix/RaBbLE-OS-Fix-BootChain.md` → Verification). They sit under Active Issues deliberately.
>
> **Unified liminal canvas:** `RaBbLE_boot_Liminal_BG.png` (BaBbLE) is now the shared background across GRUB (24bpp RGB), Plymouth (RGBA composited), and SDDM (RGB). The boot chain *should* read as one continuous performance — confirm visually.
>
> **Remaining rough edge:** TTY font `ter-v32b` in `vconsole.conf` may not apply on all TTYs after KMS handoff. `fbcon=font:TER16x32` in cmdline handles early TTY; `systemd-vconsole-setup` handles post-pivot. If TTYs still show small font, verify `setfont ter-v32b` works and fbcon is active.

**GRUB2 — background image bit depth mismatch** `[IMPLEMENTED S152 · NEEDS REBOOT VERIFY]`
- `grub-bg.png` generated at 24bpp RGB (no alpha) from Liminal_BG via `build-grub-bg.py`
- GRUB background renderer requires ≤24bpp which 24bpp RGB satisfies
- Theme uses `desktop-image: "grub-bg.png"` with `desktop-color: "#0a0010"` fallback

**GRUB2 — font microscopic at 4K** `[IMPLEMENTED S152 · NEEDS REBOOT VERIFY]`
- Noto Sans variants generated at 12/16/18/36pt and named "RaBbLE UI Regular"; theme uses `RaBbLE UI Regular 36` for titles
- NOTE: the S152 doc claimed a `ter-32.pf2 "RaBbLE UI Mono"` font — **no Ansible task generates it and no theme directive uses it** (corrected S153). Only Noto Sans is built.
- Handlers run in correct order: mkfont before mkconfig

**TTY font — shifts size during boot / stays tiny** `[ROOT-CAUSED + FIX IMPLEMENTED S207 · NEEDS REBOOT VERIFY]`
- `fbcon=font:TER16x32` added to `GRUB_CMDLINE_LINUX` for early framebuffer font
- `vconsole.conf` sets `FONT=ter-v32b` for post-initramfs font via systemd-vconsole-setup
- **S207 root cause (confirmed on real hardware, 2026-08-08):** two stacked failures, neither ever actually worked.
  1. `fbcon=font:TER16x32` is a dead no-op on this kernel — Fedora's kernel ships `CONFIG_FONT_8x16` only, no `CONFIG_FONT_TER16x32`. Confirmed via `dmesg | grep "Console: switching"` → `480x150` (= 3840/8 × 2400/16, the stock 8x16 font) on every boot checked; never the `240x75` a 16x32 font would give.
  2. `systemd-vconsole-setup` races Plymouth for console ownership and loses on every boot observed: `All allocated virtual consoles are busy, will not configure key mapping and font.` ter-v32b never lands, early or late.
- **Fix:** new `rabble-console-font.service` (`boot/grub2/files/`), `After=plymouth-quit-wait.service`, calls `setfont -C <vt>` directly (bypasses vconsole-setup's self-defeating busy-check) on tty1-6 once Plymouth has actually released the consoles, before any getty shows a prompt. Deploy: `./RaBbLE-OS-layerctl.sh apply boot --config`.
- Still open after that command runs: confirm on a real reboot that tty1-6 all show the large font, and that `ter-v32b` (32pt) is the size Mark actually wants now that it's finally rendering — group_vars can be repointed to `ter-v28b`/`ter-v24b` if 32pt reads as too large in practice.

**Plymouth — DejaVu font / wrong palette colors** `[IMPLEMENTED S87–S152 · NEEDS REBOOT VERIFY]`
- JetBrains Mono for boot logs, Orbitron for wordmark (pre-rendered PNGs, no font discovery in initrd)
- Palette locked to canonical hex values: `#ff2d78`, `#bf5fff`, `#0a0010`, `#00f5ff`, `#e8e6f0`, `#6b6880`

**SDDM greeter fails to appear after reboot (DRM race with Plymouth)** `[ROOT-CAUSED + FIX IMPLEMENTED S207 · NEEDS REBOOT VERIFY]`
- **Symptom (Mark, 2026-08-08):** after a `dnf update` reboot, SDDM never showed a login screen; had to drop to a TTY and run `start-hyprland` manually.
- **Root cause (confirmed via boot journal):** `sddm.service` is vendor-ordered `After=plymouth-quit.service`, which only *fires* the Plymouth quit signal — it does not wait for plymouthd to actually release DRM master. `plymouth-quit-wait.service` is the unit that blocks until Plymouth is really gone, and nothing ordered `sddm.service` after it. The greeter's sway compositor (pinned to the AMD card, `nvidia.yml` Step 1c) does a single non-retrying DRM `open()` and dies instantly if it loses the race:
  ```
  sway: [ERROR] Failed to open device: '/dev/dri/rabble-amdgpu-card': Device or resource busy
  sway: [ERROR] Unable to open /dev/dri/rabble-amdgpu-card as KMS device
  ```
  The greeter session then closes ~1s later — no login screen, no retry.
- Most boots the timing happens to work out (including the one right after this, boot 0) — it is an intermittent race, not a hard failure every time, which is why it wasn't caught by the S197/S200 udev-alias fix (a real but different bug in the same area).
- **Fix:** new drop-in `sddm.service.d/plymouth-handoff.conf` (`boot/session_manager/files/`), `After=plymouth-quit-wait.service`. Independent of the S197 `plymouth-quit-sddm.conf` retain-splash drop-in (that one controls *what* Plymouth leaves on screen; this one controls *when* it's safe for the greeter to grab DRM) — both are needed together. Deploy: `./RaBbLE-OS-layerctl.sh apply boot --config`.

**Plymouth — black flash / NVIDIA DRM reset mid-boot** `[IMPLEMENTED S152–S153 · NEEDS REBOOT VERIFY]`
- `plymouth.use-simpledrm=1` removed from GRUB cmdline (was the simpledrm→KMS handoff flash)
- `rd.driver.blacklist=nvidia` added to cmdline — NVIDIA modules deferred from initramfs
- `add_drivers+=" amdgpu "` in dracut conf ensures AMD iGPU KMS is available from frame one
- **S153: `nvidia-load.service` now implemented** (`roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml`) — loads `nvidia_drm`/`nvidia_uvm` after `sddm.service`, off the boot critical path, so the deferred dGPU is ready for PRIME offload/CUDA.
- RISK: this is a real kernel-cmdline change. If the splash still flashes black OR if `nvidia-smi`/`DRI_PRIME=1` fails after login, this is the prime suspect — see verification recipe.

**Plymouth — void background continuity** `[IMPLEMENTED S152 · NEEDS REBOOT VERIFY]`
- Unified liminal background (`bg-liminal.png`) across GRUB, Plymouth, SDDM — all derive from `RaBbLE_boot_Liminal_BG.png`

**SDDM theme — Main.qml Qt6 API validation**
- `Main.qml` uses Qt6 API (Theme-API=2.0, QtVersion=6)
- Test path: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble-aether`
- Username case transformation, gradient border implemented
- Entity idle loop is currently **ping-pong (forward→back→forward)** — a STOPGAP. Mark finds the direction reversal too obvious; a genuinely seamless loop is a **planned future pass** (see `fix/RaBbLE-OS-Fix-BootChain.md` → "Future: clean entity loop").

**Boot asset masters are 1920-class — regenerate at 4K+** `[OPEN · S153]`
- Plymouth script is now resolution-independent (`scale = screen_w/1920` scales entity/wordmark/dot/text; bg/grid/scanlines already fit). One asset set spans 720p→4K; new masters drop in with no script change.
- Current masters upscale on the 4K panel (`scale≈2.0`) → entity + wordmark slightly soft until regenerated. Full table + `build-assets.sh` knobs in `fix/RaBbLE-OS-Fix-BootChain.md` → "Boot asset masters". 720p/1080p already correct.

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
