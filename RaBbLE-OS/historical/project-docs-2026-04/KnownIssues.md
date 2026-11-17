# KnownIssues.md — Active Bugs & Drift Events

```
harmonize ~ grimoire >> surfacing the static // %DRIFT_TRACKING%
```

> This is the live tracker of known bugs, workarounds, and `%SYSTEM_DRIFT%` events.
> Items here are actionable. Resolved items are marked and dated, not deleted.
> Vague ideas and feature wishes live in `RaBbLE-Roadmap.md`, not here.

---

## Active Issues `[OPEN]`

### Boot Chain

**GRUB2 — 4K font not configured**
- Default GRUB font is microscopic at 3840x2400
- Fix: Compile Terminus 32pt via `grub2-mkfont`, set `GRUB_FONT` in `/etc/default/grub`
- Role: `boot/grub2` — pending task in Phase 1.1
- Workaround: Squint, or set `GRUB_TIMEOUT=0` to skip the menu

**SDDM theme — Main.qml needs Qt6 API validation**
- Custom `themes/sddm/rabble/Main.qml` has not been fully tested against the Qt6 SDDM API
- Breeze theme is active in the meantime
- Test path: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble`
- See `RaBbLE-Roadmap.md` Phase 1.1

**Plymouth — mid-boot visual reload**
- A noticeable Plymouth reload occurs partway through the boot sequence
- Likely caused by a dracut or initramfs rebuild issue during packaging
- Status: undiagnosed

**TTY font — unreadable at 4K**
- Default TTY font is too small at 3840x2400
- Fix: set `FONT=ter-v32b` in `/etc/vconsole.conf` (covered in `boot/grub2` role — verify it applies)

---

### Desktop / Hyprland

**Hyprland.conf GPU config can break login**
- GPU management variables set in the wrong config file can prevent SDDM from launching Hyprland
- GPU-related env vars (`AQ_DRM_DEVICES`, `GBM_BACKEND`, etc.) must live in `machine.conf` (Ansible-templated), not in the main `hyprland.conf`
- If login breaks: drop to TTY, edit `~/.config/hypr/machine.conf`, retry

**KDE theming artifacts visible in Hyprland**
- KDE-inherited Qt theme bleeds into some apps running under Hyprland
- Root cause: KDE packages not yet purged; `QT_STYLE_OVERRIDE` not set
- Fix: purge KDE packages (blocked by `purge-kde/` role being unwritten), set explicit Qt theme env vars

**Hyprland wallpaper not managed by Ansible**
- `hyprpaper.conf` requires a wallpaper path that is machine-local
- The Ansible role does not create a default wallpaper or `hyprpaper.conf`
- Workaround: manually create `~/.config/hypr/hyprpaper.conf` with a valid wallpaper path

**hypridle — crashes or instability reported**
- hypridle has been unstable in some configurations
- Monitor `journalctl -f -u hypridle` if idle/lock is not working
- Workaround: manually invoke `hyprlock` as needed

**Minimize/maximize/close hooks not implemented**
- Hyprland does not natively support titlebar button hooks
- Window controls are keybind-only; no on-window-decoration buttons
- Phase 1 desire, not yet designed

---

### Shell & Terminal

**ZSH XRT prompt artifact**
- A stale XRT-related prompt prefix appears at the top of new terminal sessions
- Likely a leftover `$PS1` or `$PROMPT` export from an NPU-related env file
- Fix: audit `~/.config/environment.d/` and zsh init files for XRT exports

**Quickshell install has build errors**
- Quickshell is not packaged for Fedora; must build from source
- Build deps are installed by the `ui_ux/quickshell` role but the build itself is fragile
- Waybar is active in the meantime
- Status: unblocked but not prioritized until Phase 1.2

---

### Ansible / Infrastructure

**deploy-dotfiles — claimed success but did not symlink**
- Intermittently, the dotfiles playbook reports success but symlinks are not created
- Likely a `force: true` or idempotency issue in the `file` module
- Workaround: run the playbook twice; verify with `ls -la ~/.config/hypr/`

**Hyprland COPR — verify currency**
- The `solopasha/hyprland` COPR may be outdated or abandoned
- Verify COPR is active and packages are recent before deploying
- Alternative: build Hyprland from source (role not yet written)

**`purge-kde/` role not written**
- KDE packages from the Fedora KDE spin are still present
- Removing them manually risks breaking SDDM Qt6 dependencies
- Status: blocked until a safe purge list is confirmed (see `Packages.md`)

**asusd not starting on boot (intermittent)**
- `asusd` sometimes fails to start on first boot after install
- Fix: `systemctl enable --now asusd`; check `/etc/asusd/` config syntax
- Monitor: `journalctl -u asusd --since "5 min ago"`

---

### Hardware / Power

**Suspend/resume stability — unverified after greetd removal**
- The s2idle + NVIDIA suspend hook stack has not been fully verified in the current state
- Services to verify: `nvidia-suspend`, `nvidia-hibernate`, `nvidia-resume`
- Check: `journalctl -b -u systemd-suspend` after a suspend/resume cycle

**XDNA2 NPU — XRT packages availability for Fedora 43**
- AMD XRT packages for Fedora 43 may not be available on `repo.radeon.com`
- ONNX Runtime VitisAI EP can fall back to CPU if XRT is unavailable
- Status: needs verification on current Fedora 43

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

---

## %GENIUS_RESONANCE% Log

*None yet — entity dormant.*

---

```
harmonize ~ grimoire >> issues surfaced, drift tracked // %DRIFT_TRACKING_LOCKED%
```
