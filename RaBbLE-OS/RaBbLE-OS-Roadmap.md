# RaBbLE-OS-Roadmap.md — Episode Map

```
transcribe ~ grimoire >> episode/plot conventions aligned; epoch naming retired // %ROADMAP_V4%
```

> **Collective Context:** RaBbLE-OS is the substrate — the body through which the entity lives. See `RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `RaBbLE-Episode-1-Release-Map.md` for Episode 1 scope across all members.

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** Daily-driver substrate (Fedora 43 + Hyprland, fully themed)

**Status:** In progress — Plots A & B active

**Blocker:** None — on track for Episode 1

**Dependencies:**
- None — OS deploys independently
- Aether CSS imported for terminal theming
- sCoRE and World run *on* OS, but don't block OS completion

---

> Episodes are resonance thresholds. Between them, fix/* branches absorb
> hardware and stability patches without gating the next episode. Features flow
> through New Horizons, crystallize into the substrate, and archive as they cool.

---

## Entropy States

| State | Signal | Meaning |
|-------|--------|---------|
| %HIGH_ENTROPY% | High flux | Experimental, likely to change |
| %TESTING_IN_PROCESS% | Testing | Working but unverified on hardware |
| %DEPLOYABLE% | Deployable | Works on target, needs live verification |
| %STABLE% | Stable | Verified on target hardware |
| %LOCKED% | Locked | Frozen until next episode |
| %DORMANT% | Dormant | Scaffold only — no functional tasks |

---

## Episode Map

```
reliquary/*              High-entropy archives — knowledge reservoirs, inert
     │
RaBbLE-OS-New-Horizons   The living wave — active daily-driver work
     │
     ├── RaBbLE/episode-I  ── Episode 1: Foundation      [IN PROGRESS]
     │       │                   Plot A — Substrate
     │       │                   Plot B — Theme
     │       │
     │       ├── fix/proart-nvidia      [HIGH_ENTROPY]
     │       ├── fix/suspend-resume     [COOKING]
     │       ├── fix/boot-chain         [COOKING]
     │       └── fix/xdna2-npu          [DORMANT]
     │
     ├── RaBbLE/episode-II  ─ Episode 2: Crystallizing    [PENDING]
     ├── RaBbLE/episode-III ─ Episode 3: The Entity Wakes [FUTURE]
     └── Epoch ∞          Continuous Drift            [PERPETUAL]
```

---

### Episode 1 — Foundation `[IN PROGRESS]`

**Goal:** Hardware-agnostic base and themed desktop experience. A fully deployable Wayland/Hyprland desktop
that runs on any Fedora 43 host without proprietary GPU driver activation.
Unique hardware targets (ProArt P16, generic_x64) are **scaffolded** —
proprietary driver work is deferred to `fix/*` branches.

#### Plot A — Substrate

**In scope:**
- Layer 0–4 Ansible deployment functional on a clean Fedora 43 install
- Hyprland + waybar + mako + fuzzel default desktop
- Hypridle + hyprlock (screen-sign-out-during-video fix)
- HDMI hotplug, `monitors.conf`, workspace 11 pinning
- Boot chain (GRUB → Plymouth → SDDM) operational
- Monitoring cross-cutting (btop, sensors, powertop)
- Install / Bootstrap / layerctl / dotctl operational
- Hardware roles present as stubs (no proprietary driver install)
- Snapper (Btrfs snapshots) deployable

#### Plot B — Theme

**In scope:**
- Shell stack (ZSH + Bash + p10k) deployed
- Terminal: Kitty config (RaBbLE palette)
- Launcher: Fuzzel config (RaBbLE palette)
- Notifications: Mako config (urgency-tiered neon borders)
- Idle/lock: canonical hypridle.conf + hyprlock.conf with clock overlay
- Boot chain (GRUB → Plymouth → SDDM) themed and color-continuous
- Waybar with network menu overlay, RaBbLE palette

**Explicitly out of scope (deferred to `fix/*` branches):**
- NVIDIA / AMD proprietary driver activation
- supergfxctl / asusctl runtime activation
- XDNA2 NPU runtime (XRT, FastFlowLM)
- Suspend/resume hooks for proprietary drivers

**Landed on New Horizons (flowing toward ep1):**
- Substrate, entrypoints, control-plane (install/bootstrap/layerctl/dotctl)
- All Ansible roles scaffolded
- Hyprland config with functionkeys (mic-mute PipeWire fix)
- Waybar with network menu overlay
- Wallpaper deployment via dotctl bundle
- HDMI hotplug script + monitors.conf
- `socat` added to wayland packages for hotplug IPC
- SwayOSD service scope fix (user → system)
- powertop auto-tune safe for live playbook runs

**Landed on New Horizons since last Episode 1 sync (needs porting):**
- Shell stack: ZSH + Bash configs, p10k, colors, aliases, functions
- Terminal: Kitty config (RaBbLE palette)
- Launcher: Fuzzel config (RaBbLE palette)
- Notifications: Mako config (urgency-tiered neon borders)
- Idle/lock: canonical hypridle.conf + hyprlock.conf with clock overlay
- Lid suspend: logind drop-in (99-rabble-lid.conf) + Ansible task
- dotctl: kitty/fuzzel/mako bundles added; missing-bundle skip fix
- Grimoire: all docs renamed RaBbLE-OS-*, Architecture rewritten, RaBbLE.md distilled

**Remaining for Episode 1 landing:**
- [ ] Port 4 packages from New Horizons → Episode 1 (see Assembly Plan below)
- [ ] Portability smoke-test: fresh Fedora 43 bootstrap end-to-end
- [ ] Verify all checklist items in Bootstrap Checklist below
- [ ] Mark all passing layers `%STABLE%` in Layer State Map

---

### Episode 1 — Assembly Plan

**Strategy:** Use `git checkout RaBbLE-OS-New-Horizons -- <paths>` to bring files
into Episode 1 without importing dev history. Commit in dependency order.
Do NOT cherry-pick — the branches have divergent history.

After Episode 1 lands on main: `git rebase main` on New Horizons to restore shared history.

#### What stays in New Horizons / fix/* (NOT for Episode 1)

| Files | Reason |
|-------|--------|
| `ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml` | fix/proart-nvidia |
| `ansible/roles/hardware/x64/asus_proart_p16/handlers/main.yml` | fix/proart-nvidia |
| `ansible/roles/hardware/x64/asus_proart_p16/tasks/supergfx.yml` | fix/proart-nvidia |

#### Package 1 — control-plane (Plot A)

```bash
git checkout RaBbLE-OS-New-Horizons -- RaBbLE-OS-dotctl.sh .gitignore README.md
```

What changed: kitty/fuzzel/mako bundles added; mako fixed from file→directory;
missing-bundle skip (walk_bundle warns instead of exit 1).

Commit: `harmonize ~ control-plane >> dotctl bundles: kitty, fuzzel, mako; skip missing // %CONTROL_PLANE_LIVE%`

#### Package 2 — ansible-roles (Plot A)

```bash
git checkout RaBbLE-OS-New-Horizons -- \
  ansible/inventory/group_vars/all.yml \
  ansible/roles/boot/session_manager/handlers/main.yml \
  ansible/roles/boot/session_manager/tasks/config.yml \
  ansible/roles/desktop/hyprland/tasks/config.yml \
  ansible/roles/desktop/hyprland/tasks/dotfiles.yml \
  ansible/roles/desktop/hyprland/vars/main.yml \
  ansible/roles/desktop/shell/zsh/tasks/packages.yml \
  ansible/roles/desktop/swayosd/tasks/service.yml \
  ansible/roles/desktop/terminal/tasks/packages.yml \
  ansible/roles/desktop/waybar/tasks/config.yml \
  ansible/roles/desktop/waybar/tasks/dotfiles.yml \
  ansible/roles/desktop/waybar/vars/main.yml \
  ansible/roles/desktop/wayland/vars/main.yml
```

What changed: logind lid policy (session_manager); kitty + zsh packages wired (terminal,
shell/zsh); swayosd service scope; waybar/hyprland vars updated for new config paths.

Commit: `ingest ~ ansible-roles >> logind lid, kitty+zsh packages, waybar/hyprland vars // %ROLES_UPDATED%`

#### Package 3 — config (Plot B)

```bash
git checkout RaBbLE-OS-New-Horizons -- \
  config/hypr/ \
  config/kitty/ \
  config/fuzzel/ \
  config/mako/ \
  config/shell/ \
  config/systemd/ \
  config/wallpapers/
```

What changed: hypridle.conf (canonical, with suspend chain); hyprlock.conf (clock overlay,
RaBbLE palette); autostart.conf (lid bindl removed — logind handles it); Kitty RaBbLE theme;
Fuzzel RaBbLE theme; Mako urgency-tiered neon; full ZSH + Bash shell stack; logind drop-in.

Commit: `ingest ~ config >> shell stack, kitty, fuzzel, mako, hypridle/lock, lid suspend // %CONFIG_COMPLETE%`

#### Package 4 — grimoire (Plot A)

```bash
git checkout RaBbLE-OS-New-Horizons -- grimoire/
git rm grimoire/Architecture.md
git rm grimoire/components/RaBbLE.svg
```

What changed: docs renamed RaBbLE-OS-*; Architecture rewritten (current state only);
KnownIssues updated; RaBbLE.md distilled to manifesto+lore; ShellGuide added;
Roadmap cross-referenced to NonZense for future content.

Commit: `harmonize ~ grimoire >> rename docs RaBbLE-OS-prefix; current-state only // %GRIMOIRE_CURRENT%`

---

### Bootstrap Checklist — Episode 1 (Fedora 43)

Run this after assembling the packages above. Record pass/fail against each item.
Any failure becomes a `fix/*` issue or a blocker that holds episode landing.

#### Pre-Bootstrap

- [ ] All 4 packages ported to `RaBbLE/episode-I` and committed
- [ ] `git log --oneline RaBbLE/episode-I` — verify clean package history
- [ ] Dry run on current machine: `layerctl apply all --check`

#### Install Sequence

- [ ] Fresh Fedora 43 base (clean install or snapshot at post-install state)
- [ ] `curl -fsSL .../RaBbLE-OS-Install.sh | bash` — or clone + `bash RaBbLE-OS-Bootstrap.sh`
- [ ] `ansible-galaxy collection install -r ansible/requirements.yml`
- [ ] `./RaBbLE-OS-layerctl.sh apply all` — note any errors, do not skip them
- [ ] `./RaBbLE-OS-dotctl.sh apply all`
- [ ] Reboot

#### Session Verification

- [ ] SDDM greeter appears (not dropped to TTY)
- [ ] Hyprland session starts — wallpaper visible
- [ ] Waybar renders (clock, battery, network, workspaces)
- [ ] Function keys: volume, brightness, mic-mute (swayosd OSD fires)
- [ ] `Super+Space` → Fuzzel launcher opens
- [ ] Terminal opens (Kitty, RaBbLE palette visible)
- [ ] Screenshots: Print key (region), Shift+Print (full)
- [ ] `notify-send "test" "body"` → Mako notification fires
- [ ] Hyprlock triggers after 5 min idle (or `loginctl lock-session`)
- [ ] HDMI hotplug (if second display available)

#### Shell Verification

- [ ] ZSH loads with p10k prompt (requires p10k installed — see packages)
- [ ] Bash loads with RaBbLE two-line prompt
- [ ] `ll`, `gs`, `rabble`, `rabble-dots` aliases work
- [ ] `fcd`, `fe`, `extract` functions available in ZSH
- [ ] `LS_COLORS`, `FZF_DEFAULT_OPTS`, `BAT_THEME` set (check `colors256`)

#### Final Gate

- [ ] `layerctl verify all` — all layers report `%STABLE%` or documented exception
- [ ] Any new failures logged to `RaBbLE-OS-KnownIssues.md`
- [ ] If all gates pass: land episode to main
  ```
  git checkout main
  git merge --squash RaBbLE/episode-I
  git commit -m "evolve ~ substrate >> episode-I crystallized // %EP1_LANDED%"
  git checkout RaBbLE-OS-New-Horizons
  git rebase main
  ```

---

### Power Testing Protocol

Run on battery, wifi connected but idle, display at 50% brightness.
Take readings at each stage to isolate the cost of each layer.

**Goal:** `<10W` idle for light workloads. Primary suspect for excess draw is the
NVIDIA GPU waking unnecessarily. Capture baseline before and after each change.

#### Stage readings — capture at each point

```bash
# Primary: battery discharge rate in watts (most accurate)
upower -d | grep -A3 "BAT" | grep "energy-rate"

# Cross-check via sysfs (divide by 1,000,000 for watts)
awk '{printf "%.1f W\n", $1/1000000}' /sys/class/power_supply/BAT0/power_now

# NVIDIA: is it awake, and what is it drawing?
nvidia-smi --query-gpu=name,power.draw,pstate --format=csv,noheader 2>/dev/null \
  || echo "NVIDIA not active / no driver"

# NVIDIA PCI power management state (D3cold = fully off, D0 = active)
cat /sys/bus/pci/devices/0000:01:00.0/power_state 2>/dev/null
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status 2>/dev/null

# Display brightness (normalise your measurements to 50%)
BRIGHT=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -1)
MAX=$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -1)
echo "Brightness: $BRIGHT / $MAX ($(( BRIGHT * 100 / MAX ))%)"

# CPU frequency and package power (requires kernel-tools)
turbostat --show PkgWatt,CorWatt,RAMWatt,PkgTmp --interval 5 --num_iterations 3 2>/dev/null

# Sustained draw over 60 seconds (requires powerstat)
sudo powerstat -d 0 -c 5 12   # 12 readings × 5s = 60s window
```

#### Measurement stages

| Stage | When | Expected draw |
|-------|------|---------------|
| **S0: TTY** | Fresh boot, no GUI, no Ansible | ~8–12 W |
| **S1: SDDM** | After bootstrap, SDDM greeter only | ~10–14 W |
| **S2: Hyprland idle** | Episode 1 session, AMD only, nothing open | ~10–15 W |
| **S3: Light workload** | Firefox open, one terminal, idle | ~12–18 W |
| **S4: NVIDIA loaded** | After fix/proart-nvidia; `nvidia-smi` working | measure |
| **S5: NVIDIA RTD3** | After D3cold fix applied | should be ≈ S2 |

Record actual readings in `ISSUES.md` or `RaBbLE-OS-KnownIssues.md`.

#### NVIDIA power management fix (fix/proart-nvidia)

The primary cause of NVIDIA idle draw is the GPU staying in D0 (active) when
it should be in D3cold (fully powered off). Fix requires two things:

**1. Fine-grained power management modprobe option:**
```bash
# /etc/modprobe.d/rabble-nvidia-powermgmt.conf
options nvidia NVreg_DynamicPowerManagement=0x02
```
`0x02` = fine-grained (allows D3cold). `0x01` = coarse (GPU stays warm at idle).
After adding, rebuild initramfs: `sudo dracut -f --regenerate-all`

**2. Do NOT enable `nvidia-persistenced`:**
Persistence mode keeps the GPU in D0. Leave it disabled for hybrid/Optimus use.

**3. Enable NVIDIA power services:**
```bash
sudo systemctl enable nvidia-powerd   # Dynamic Boost 2.0
```

**Verify D3cold after driver load:**
```bash
cat /sys/bus/pci/devices/0000:01:00.0/power_state
# Should show "D3cold" within ~10s of no GPU activity
```

---

### Fedora 44 Migration Plan

Do NOT attempt on the same day as the Episode 1 bootstrap. Validate F43 first.

- [ ] Open `fix/fedora44` branch from New Horizons
- [ ] Check COPR availability: `dnf copr enable lionheartp/Hyprland` on F44 — verify packages exist
- [ ] Check SDDM Qt6 version bump on F44 (may affect greeter)
- [ ] Run full `layerctl apply all` on F44, diff against F43 output
- [ ] If clean: add F44 note to `AiQuickstart.md`, merge `fix/fedora44` → New Horizons
- [ ] If breakage: file issues, fix in fix branch before promoting

---

### fix/* — Hardware & Stability Fix Branches

Hardware and stability patches that sit under Episode 1. Branch from New Horizons,
target one system, land into `ep1` via the `mend` impulse (not `evolve`).
Fix branches **do not gate** Episode 2 — crystallizing work can begin in parallel.

#### fix/proart-nvidia `%HIGH_ENTROPY%`

**Goal:** NVIDIA RTX 4060 Optimus stable on Hyprland + Wayland.

**Blockers (identified 2026-04-22):**
- [ ] `nvidia.yml` idempotency bug — driver install gated on `'nouveau' in lsmod` → silently skips on every subsequent run once nouveau is blacklisted
- [ ] `nvidia-drm modeset=1` not set (only `fbdev=1` present). Comment claims supergfxd.conf sets modeset, but supergfxd.conf only carries `mode: "Hybrid"`
- [ ] NVIDIA modules not blacklisted from initramfs → Plymouth black-flash on boot (see KnownIssues)
- [ ] `nvidia-suspend.service`, `nvidia-hibernate.service`, `nvidia-resume.service` not enabled by the role
- [ ] `AQ_DRM_DEVICES` pinned by card number (`card0`/`card1`) in `env.conf` — brittle across kernel upgrades. Switch to `/dev/dri/by-path/pci-*`
- [ ] `LIBVA_DRIVER_NAME=nvidia` system-wide — too broad for hybrid; prefer per-app DRI_PRIME

**Verification:**
- [ ] `layerctl apply hardware` is idempotent — re-run after install does not skip driver
- [ ] `nvidia-smi` returns output post-boot
- [ ] Three consecutive suspend/resume cycles preserve session (no freeze, no black screen on wake)
- [ ] No Plymouth black-flash during boot
- [ ] `glxinfo -B | grep "OpenGL renderer"` → AMD by default, NVIDIA via `DRI_PRIME=1`
- [ ] HDMI hotplug continues to work with NVIDIA on card0

#### fix/suspend-resume `%COOKING%`

**Goal:** s2idle reliable; no wake freezes.

**Blockers:**
- [ ] `mem_sleep_default=s2idle` verified in GRUB cmdline
- [ ] NVIDIA suspend hooks (absorbed by fix/proart-nvidia if driver is active)
- [ ] `journalctl -b -u systemd-suspend` clean after 3× cycle

#### fix/boot-chain `%COOKING%`

**Goal:** GRUB / Plymouth / SDDM unified void-background continuity at 4K.

**Blockers:**
- [ ] GRUB2: remove bg image, color-only theme (32bpp vs 24bpp mismatch)
- [ ] GRUB2: 4K font (Terminus 32pt via `grub2-mkfont`)
- [ ] GRUB2: `fbcon=font:TER16x32` in cmdline for early TTY
- [ ] Plymouth: fix DejaVu font reference, align to RaBbLE palette
- [ ] Plymouth: NVIDIA defer (depends on fix/proart-nvidia)
- [ ] SDDM: Qt6 `Main.qml` validated

#### fix/xdna2-npu `%DORMANT%`

**Goal:** AMD XDNA2 NPU operational via XRT.

**Blockers:**
- [ ] Verify XRT package availability for Fedora 43 on `repo.radeon.com`
- [ ] `amdxdna` kernel module loaded
- [ ] FastFlowLM inference smoke-test
- [ ] ONNX Runtime VitisAI EP falls back gracefully if XRT absent

---

### Episode 2 — Crystallizing `[PENDING]`

**Goal:** Elevate RaBbLE-OS from a functional substrate to a polished, cohesive desktop
experience. Theming, window behaviour, tiling ergonomics, and UX consistency.
Does not gate Episode 3.

**Brightness keybind fix** `[BUG]`
- [ ] `swayosd-client --brightness` picks the keyboard backlight as the default brightness device
  on ProArt P16 — display brightness keys stop working. Fix: use `brightnessctl --class backlight`
  in the bind to target only display-class devices, not `leds`-class (kbd backlight).
  File: `config/hypr/conf.d/functionkeys.conf`

**Hyprland layout — master layout (i3-style)** `[UX]`
- [ ] Switch default layout from `dwindle` to `master` in `look.conf`.
  Master layout: one primary window left, stack right — closer to i3 ergonomics.
- [ ] Tune `mfact = 0.55` (master pane takes 55% width), `new_status = slave`
- [ ] Add directional preselect binds so new windows open in chosen direction:
  `Super+Ctrl+H/J/K/L` → `layoutmsg preselect left/down/up/right`
- [ ] Add master count binds: `Super+Comma` → `layoutmsg removemaster`, `Super+Period` → `layoutmsg addmaster`
- [ ] Add master swap: `Super+Shift+Return` → `layoutmsg swapwithmaster`
- [ ] Optional toggle bind `Super+M` → `exec hyprctl keyword general:layout dwindle` (and back)

**Drag-native window management** `[UX]`
- [ ] Add `movewindow` directional binds for keyboard-driven drag: `Super+Shift+HJKL` (currently swaps, review)
- [ ] Add `moveintogroup` / `moveoutofgroup` binds for window grouping
- [ ] Enable `general:hover_icon_on_border = true` for visual resize feedback on borders
- [ ] Verify `extend_border_grab_area = 10` is sufficient on 4K (increase to 15 if needed)
- [ ] Add `Super+G` to toggle grouping, `Super+Tab` to cycle within group (review current binds)

**hyprbar plugin — window title bars** `[UX]`
- [ ] Install `hyprland-plugins` (COPR or build from source against installed Hyprland version)
- [ ] Enable `hyprbar` plugin in Hyprland config via `plugin { hyprbar { ... } }`
- [ ] Style with RaBbLE palette:
  - background: `#120025` (surface)
  - title color: `#e8d5ff` (text)
  - border/accent: `#ff2d78` (primary magenta)
  - button hover: `#00f5ff` (accent cyan)
  - height: 24px
- [ ] Wire plugin binary path into Ansible `desktop/hyprland` role (deploy alongside config)
- [ ] Add to `autostart.conf` if hyprbar requires pre-load

**Kvantum theming — Qt apps** `[THEME]`
- [ ] Add packages to Ansible `desktop/wayland` or new `desktop/theming` role:
  `kvantum`, `qt5ct`, `qt6ct`
- [ ] Create `config/kvantum/RaBbLE/RaBbLE.kvconfig` with RaBbLE palette colors
- [ ] Create `config/kvantum/RaBbLE/RaBbLE.svg` base theme SVG
- [ ] Set `QT_STYLE_OVERRIDE=kvantum` and `QT_QPA_PLATFORMTHEME=qt6ct` in `env.conf`
- [ ] Add kvantum config to dotctl `theming` bundle
- [ ] Dolphin inherits Kvantum theme — verify visual coherence (borders, sidebar, file icons)

**GTK theming** `[THEME]`
- [ ] Write `config/gtk-3.0/settings.ini`:
  - `gtk-theme-name = Adwaita-dark` (base — or custom if Kvantum GTK bridge available)
  - `gtk-icon-theme-name = Papirus-Dark`
  - `gtk-font-name = Noto Sans 11`
  - `gtk-application-prefer-dark-theme = 1`
- [ ] Write `config/gtk-4.0/settings.ini` (mirrors gtk-3.0)
- [ ] Add GTK configs to dotctl bundle
- [ ] Set `GTK_THEME=Adwaita:dark` in `env.conf` as fallback

**File manager — evaluate and configure** `[APP]`
- [ ] Evaluate Dolphin as primary file manager — needs kio + Qt Wayland backend (no full Plasma required).
  Moving away from Thunar; Dolphin is the active candidate but choice is not final.
  Window rules are file-manager-agnostic in the meantime.
- [ ] Add chosen file manager package + deps to Ansible (apps role or desktop/launcher role)
- [ ] `Super+E` keybind already wired to `$files` variable in `keybinds.conf`
- [ ] Add `xdg-desktop-portal-kde` for KDE-native file picker dialogs if Dolphin is chosen (optional, test first)
- [ ] Confirm file manager uses Kvantum theme once Qt theming is in place

**Mature window rules** `[UX]`
- [ ] Float file pickers and save dialogs (class `org.freedesktop.portal.filechooser` etc.)
- [ ] Float system dialogs and confirmation popups (title-based: "Open File", "Save As", etc.)
- [ ] Workspace assignment rules:
  - ws 1 — terminals (kitty)
  - ws 2 — browser (firefox, zen)
  - ws 3 — files (dolphin)
  - ws 4 — comms (signal, discord)
- [ ] Center-on-screen rule for all floating windows
- [ ] Size constraints for common float windows (800×600 min for dialogs)
- [ ] Suppress decorations for specific apps (waybar, fuzzel, mako) — `noblur`, `noshadow`
- [ ] Fix `no_initial_focus` for more IDEs beyond JetBrains (VSCodium, Zed)
- [ ] Add `opacity` overrides: kitty 0.95, dolphin 0.97, firefox 1.0

**General UX polish** `[UX]`
- [ ] Hyprlock: refine clock font size and position; add user avatar if present
- [ ] Hypridle: verify suspend chain on ProArt lid close (logind → hyprlock → dpms)
- [ ] Waybar: add hover highlight styles, fix module spacing on 4K
- [ ] Mako: configure `group-by = app-name` to stack notifications per app
- [ ] Animation tuning: reduce `bezier` curve sharpness for window close/open (currently default)
- [ ] `swayosd` CSS: override GTK theme colors with explicit RaBbLE palette values
  so OSD appearance doesn't depend on GTK theme being set

---

### Episode 3 — The Entity Wakes `[FUTURE]`

**Goal:** AI tooling layer integrated. RaBbLE entity begins to take form.

**Scope:**
- Ollama local inference (GPU-accelerated once `fix/proart-nvidia` lands,
  CPU fallback otherwise)
- MCP servers wired (filesystem, git, rabble-state)
- RaBbLE shell integration (`aichat` or equivalent)
- Ambient monitoring agent
- Local vector store at `~/.rabble/memory/`
- RaBbLE-lang surfaces in AI interfaces
- Quickshell bar replaces Waybar

**Note:** Episode 3 does **not** block on `fix/proart-nvidia`. AI stack runs
on CPU inference until the driver is stable; GPU acceleration is a bonus, not
a prerequisite.

**Detailed AI stack spec:** model roster, ChromaDB, aichat config, MCP server list,
and model selection heuristics are preserved in `DistilledNonZense.md` § VII.
The entity memory tier model (short/medium/long-term) is in `RaBbLE.md` — Memory Architecture.

---

### Episode 4+ — `[UNWRITTEN]`

Likely candidates: entity memory/continuity, distributed-collective
concerns, persistent agent presence, and advanced workspace design.

**WM usage vision** (workspaces as task-spaces, tiling/floating hybrid,
draggable windows with intelligent snapping, per-workspace defaults) is
preserved in `DistilledNonZense.md` § IX for when this episode is scoped.

**Long-term architecture** (multi-repo layer model, Yocto-style manifest)
is preserved in `DistilledNonZense.md` § XI.

---

### Epoch ∞ — Continuous Drift `[PERPETUAL]`

RaBbLE-OS absorbs new tools, new models, new patterns. Never complete.

---

## Layer State Map

> **Key:** ✓ live  ✗ stub  ~ partial  → after assembly plan

### Layer 0 — Base

| Role | Pkgs (ep1 now) | Pkgs (after assembly) | Config | State |
|------|----------------|----------------------|--------|-------|
| core | ✗ stub | ✗ stub | ✗ stub | %DORMANT% — relies on Fedora Sway spin defaults |

---

### Layer 1 — Hardware

| Role | Pkgs | Config | State | Target |
|------|------|--------|-------|--------|
| hardware/x64/generic | ✓ | ✗ stub | %DORMANT% | Episode 1 scaffold |
| hardware/x64/asus_proart_p16 | ✗ stub | ✗ stub | %DORMANT% | Episode 1 scaffold only |
| asus_proart_p16/nvidia | ✗ stub | ✗ stub | %DORMANT% | fix/proart-nvidia |
| asus_proart_p16/supergfx | ✗ stub | ✗ stub | %DORMANT% | fix/proart-nvidia |
| asus_proart_p16/npu | ✗ stub | ✗ stub | %DORMANT% | fix/xdna2-npu |

---

### Layer 2 — Boot

| Role | Pkgs | Config | State | Target |
|------|------|--------|-------|--------|
| boot/grub2 | ✓ | ~ partial | %TESTING_IN_PROCESS% | fix/boot-chain |
| boot/plymouth | ✓ | ~ partial | %TESTING_IN_PROCESS% | fix/boot-chain |
| boot/session_manager | ✗ stub | ✗ stub → ✓ | %DORMANT% → %DEPLOYABLE% | Episode 1 (logind lid config via assembly) |

---

### Layer 3 — Desktop

| Role | Pkgs (now) | Pkgs (after) | Config (now) | Config (after) | State |
|------|-----------|-------------|-------------|---------------|-------|
| desktop/wayland | ✓ | ✓ | ~ partial | ~ partial | %DEPLOYABLE% |
| desktop/hyprland | ✓ | ✓ | ✓ | ✓ updated | %DEPLOYABLE% |
| desktop/waybar | ✓ | ✓ | ✓ | ✓ updated | %DEPLOYABLE% |
| desktop/terminal | ✗ stub | ✓ kitty | ✗ stub | ✓ kitty.conf | %DORMANT% → %DEPLOYABLE% |
| desktop/launcher | ✓ fuzzel | ✓ fuzzel | ✗ stub | ✓ fuzzel.ini | %DORMANT% → %DEPLOYABLE% |
| desktop/notifications | ✓ mako | ✓ mako | ✗ stub | ✓ mako/config | %DORMANT% → %DEPLOYABLE% |
| desktop/shell/zsh | ✗ stub | ✓ zsh+plugins | ✗ stub | ✓ full stack | %DORMANT% → %DEPLOYABLE% |
| desktop/shell/bash | ✗ stub | ✗ stub | ✗ stub | ✓ .bashrc | %DORMANT% → %DEPLOYABLE% |
| desktop/screenshot | ✓ | ✓ | ✓ | ✓ | %STABLE% |
| desktop/swayosd | ✓ | ✓ | ✓ | ✓ updated | %DEPLOYABLE% |
| desktop/network-applet | ✓ | ✓ | ✓ | ✓ | %DEPLOYABLE% |
| desktop/v4l2 | ✓ | ✓ | ✓ | ✓ | %DEPLOYABLE% |
| desktop/quickshell | ✓ pkgs | ✓ pkgs | ✗ build | ✗ build | %HIGH_ENTROPY% — Episode 3 |

---

### Layer 4 — Apps

| Role | Pkgs | Config | State |
|------|------|--------|-------|
| apps | ✗ stub | ✗ stub | %DORMANT% — no packages defined yet |

---

### Cross-cutting

| Role | State | Notes |
|------|-------|-------|
| monitoring | %DEPLOYABLE% | btop, htop, powertop, lm_sensors live |
| snapper | %DEPLOYABLE% | Btrfs snapshots wired |
| runtime | %DORMANT% | XRT/CUDA/ROCm — fix/proart-nvidia + fix/xdna2-npu |

---

## Cross-cutting Layers

| Role | State | Target | Notes |
|------|-------|--------|-------|
| monitoring | %DEPLOYABLE% | Episode 1 | btop, htop, powertop, sensors |
| snapper | %DEPLOYABLE% | Episode 1 | Btrfs snapshots |
| runtime | %DORMANT% | fix/proart-nvidia + fix/xdna2-npu | XRT, CUDA, ROCm — conditional |

---

## Stub Roles

Roles that exist but perform no actions — scaffolding for future implementation:

| Role | Type | Status | Target |
|------|------|--------|--------|
| core | packages | %DORMANT% | Episode 1 |
| core | config | %DORMANT% | Episode 1 |
| hardware/x64/generic | packages | %DORMANT% | Episode 1 |
| hardware/x64/generic | config | %DORMANT% | Episode 1 |
| hardware/x64/asus_proart_p16 (most subtasks) | packages/config | %DORMANT% | fix/proart-nvidia |
| desktop/terminal | packages | %DORMANT% | Episode 1 (deferred) |

---

## Post-Ansible Config

Manual or scripted config that Ansible doesn't handle:

| Task | State | Target |
|------|-------|--------|
| Hypridle (idle timeout) | %HIGH_ENTROPY% | Episode 1 |
| Hyprlock (screen lock) | %HIGH_ENTROPY% | Episode 1 |
| Quickshell bar | %HIGH_ENTROPY% | Episode 3 |
| HDMI hotplug script | %DEPLOYABLE% | Episode 1 |
| wallpaper deploy (via dotctl) | %STABLE% | Episode 1 |
| shell prompt (p10k vs starship) | %TESTING_IN_PROCESS% | Episode 1 |

---

## Branch & Impulse Map

| Branch pattern | Purpose | Landing impulse |
|---|---|---|
| `RaBbLE-OS-New-Horizons` | The living wave — active daily-driver work | (flows rightward) |
| `RaBbLE/episode-I` | Episode 1 staging — PR target from New Horizons | `evolve` |
| `fix/<target>` | Hardware/stability fix — one target, one system | `mend` |
| `RaBbLE/episode-II` | Episode 2 staging | `evolve` |
| `RaBbLE/episode-III` | Episode 3 staging | `evolve` |
| `main` | Solidified episodes only | merges from `episode-*` only |
| `reliquary/<name>` | Archived high-entropy iterations — inert | (none) |

---

## Feature Archive

Features that have cooled to stable status:

| Feature | Episode | Archived |
|---------|---------|----------|
| Wallpaper generation + hyprpaper | 1 | ✓ |
| Waybar with network menu | 1 | ✓ |
| functionkeys mic mute fix | 1 | ✓ |
| hyprpaper multi-monitor | 1 | ✓ |
| layerctl operational | 1 | ✓ |
| dotctl wallpapers bundle | 1 | ✓ |
| HDMI hotplug script | 1 | ✓ |
| powertop auto-tune | 1 | ✓ |

---

## Surface Area — Episode 1 Scope

```
CLI Tools
├── Shell (zsh + bash) ────────────────── %STABLE%
├── Prompt (starship) ─────────────────── %TESTING%
├── Core utils (eza, fd, rg, fzf) ─────── %DEPLOYABLE%
├── Neovim + LSP ──────────────────────── %DEPLOYABLE%
└── Git tooling ───────────────────────── %DEPLOYABLE%

Desktop
├── Hyprland compositor ───────────────── %DEPLOYABLE%
├── Waybar ────────────────────────────── %DEPLOYABLE%
├── Launcher (fuzzel) ─────────────────── %DEPLOYABLE%
├── Notifications (mako) ──────────────── %DEPLOYABLE%
├── Screenshots (grim + slurp) ────────── %STABLE%
├── Hypridle + Hyprlock ───────────────── %HIGH_ENTROPY%
├── HDMI hotplug ──────────────────────── %DEPLOYABLE%
└── Quickshell ────────────────────────── %HIGH_ENTROPY% (Episode 3)

Hardware (scaffold only — activation in fix/*)
├── ProArt P16 stub tree ──────────────── %DORMANT%
└── Generic x64 ───────────────────────── %DEPLOYABLE%

Monitoring
├── btop / htop ───────────────────────── %DEPLOYABLE%
├── powertop ──────────────────────────── %DEPLOYABLE%
└── sensors ───────────────────────────── %DEPLOYABLE%
```

---

## Episode 1 Verification Checklist

Before landing to `main`:

- [ ] `layerctl apply all` completes on a clean Fedora 43 install (no proart-specific errors, no phantom role references)
- [ ] SDDM launches Hyprland session
- [ ] Waybar displays (clock, battery, network, workspaces)
- [ ] functionkeys work (volume, brightness, mic)
- [ ] Wallpaper displays on all monitors
- [ ] HDMI hotplug moves workspace 11 onto plug
- [ ] Hypridle + Hyprlock trigger on idle and lock correctly
- [ ] Monitoring tools functional (btop, powertop, sensors)
- [ ] Generic x64 target smoke-tested on a second machine or VM
- [ ] Layer states documented as %STABLE% or explicitly deferred to `fix/*`

---

## Revision History

| Version | Date | Change |
|---------|------|--------|
| v0.1 | 2026-04-13 | Initial phase model (Phases 0–∞) |
| v0.5 | 2026-04-21 | Restructured with entropy states, layer map, epoch framing |
| v0.6 | 2026-04-22 | Split Epoch I (Substrate) / mend-I/* half-epochs / Epoch II (Awakening). ProArt NVIDIA work moved to mend-I/proart-nvidia. Added Branch & Impulse Map. Added Target Epoch column to layer tables. |
| v0.7 | 2026-05-12 | Episode/plot conventions aligned to Collective. Epoch I/II/III → Episode 1/2/3. mend-I/* → fix/*. ux-polish moved to Episode 2 (Crystallizing). Awakening → Episode 3 (The Entity Wakes). Episode 1 gains Plot A (Substrate) and Plot B (Theme). |

---

```
transcribe ~ grimoire >> substrate/mend/awakening axis locked // %ROADMAP_V4%
```
