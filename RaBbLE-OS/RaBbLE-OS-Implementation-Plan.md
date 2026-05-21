# RaBbLE-OS Implementation Plan — KS + Full DE State Coverage

```
spark ~ grimoire >> installer architecture and DE coverage plan // %PLAN_ACTIVE%
```

> **Session:** S33 · **Author:** Mark + Opus  
> **Goal:** Bare metal → fully reproducible RaBbLE-OS desktop via one boot.  
> **Status:** Plan approved. Work ordered for delegation.  
> **Canonical roadmap:** `RaBbLE-OS-Roadmap.md` — Episode 1, Plots A/B/C + phased stub debt.  
> This file is the **detail supplement** — KS templates, live ISO specs, acceptance criteria.
> The Roadmap owns the phase order and done-when criteria.

---

## Installer Architecture — Three Tiers

The install path has three tiers of ambition. Each tier is a valid stopping point.
Build them in order — each tier subsumes the one before it.

### Tier 1 — Partially Interactive KS (Pragmatic, build first)

Use Fedora Everything netinstall ISO. Boot with a Kickstart that automates
everything **except** disk partitioning. The user gets Anaconda's standard
partition editor — full control over disk layout, no assumptions.

**How it works:**
- Omit all `clearpart`, `part`, `btrfs` directives from the KS file
- Anaconda shows its normal "Installation Destination" screen
- User chooses disk, creates partitions however they want
- KS automates: locale, user, packages, %post (clone repo + bootstrap)
- After reboot: Ansible finishes the job

**KS file structure:**
```kickstart
# RaBbLE-OS.ks — Tier 1: Interactive Partitioning
# Boot: Fedora Everything netinstall → append inst.ks=<url>

# ── Automate everything except disk ──────────────────────────
keyboard --xlayouts='us'
lang en_US.UTF-8
timezone America/Los_Angeles --utc
rootpw --lock
selinux --enforcing
firewall --enabled --service=ssh
services --enabled=NetworkManager,sshd
firstboot --disable
reboot --eject

# ── User ─────────────────────────────────────────────────────
user --name=rabble --groups=wheel --gecos="RaBbLE" --shell=/bin/bash

# ── NO PARTITIONING DIRECTIVES ───────────────────────────────
# Anaconda presents its interactive partition editor.
# User creates whatever layout they want:
#   - EFI + /boot ext4 + BTRFS root with subvolumes (recommended)
#   - Single ext4 root (works, no snapshots)
#   - LVM, LUKS, whatever
# RaBbLE-OS is filesystem-agnostic. BTRFS recommended for snapper.

# ── Packages (from manifest.yml ks:true entries) ─────────────
%packages --ignoremissing
@core
git
ansible
python3
curl
NetworkManager
NetworkManager-wifi
polkit
%end

# ── Post-install ─────────────────────────────────────────────
%post --log=/root/ks-post.log
#!/bin/bash
RABBLE_USER="rabble"
RABBLE_HOME="/home/${RABBLE_USER}"

# Clone repo
cd "${RABBLE_HOME}"
git clone https://github.com/markm1206/RaBbLE-OS.git
chown -R "${RABBLE_USER}:${RABBLE_USER}" RaBbLE-OS

# Install Ansible Galaxy deps
su - "${RABBLE_USER}" -c "ansible-galaxy collection install -r ~/RaBbLE-OS/ansible/requirements.yml"

# Run bootstrap (unattended mode — no interactive menus)
su - "${RABBLE_USER}" -c "cd ~/RaBbLE-OS && bash RaBbLE-OS-Bootstrap.sh --unattended"
%end
```

**Serving the KS:**
- Host on GitHub raw: `inst.ks=https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS.ks`
- Or local HTTP: `inst.ks=http://192.168.x.x:8000/RaBbLE-OS.ks`
- Or USB: put KS on the boot USB alongside the ISO

**What the user does:**
1. Boot Fedora Everything netinstall ISO
2. At GRUB, edit boot entry to append `inst.ks=<url>`
3. Anaconda opens — only the "Installation Destination" screen needs input
4. Pick disk, partition, click "Begin Installation"
5. Walk away. Reboot into RaBbLE-OS.

**`--unattended` flag on Bootstrap:** Needs implementing. Skips the interactive
menu, runs `ansible-playbook -i inventory/hosts.yml site.yml -K` with
`--become-password-file` or expects passwordless sudo from KS %post context.

### Tier 2 — Custom Live ISO (The Real Goal)

Build a custom Fedora live image that boots directly into a minimal
RaBbLE-themed Hyprland session. The user partitions with a themed GUI tool,
opens a themed terminal, and runs the installer — all inside the entity's
visual language.

**What the user experiences:**
1. Boot the RaBbLE-OS ISO
2. Land in a minimal Hyprland desktop — void background, magenta accents
3. Open gnome-disk-utility (themed, on the desktop) → partition manually
4. Open Kitty terminal (themed, on the desktop) → run `rabble-install`
5. Optionally open Firefox to check docs or download drivers
6. Installer runs, reboots into the full RaBbLE-OS

**How to build it — `lorax` / `livemedia-creator`:**

Fedora spins (Sway, KDE, etc.) are built using `lorax` with a kickstart that
defines the live environment. The same toolchain works for custom images.

```bash
# Build host requirements
sudo dnf install lorax lorax-lmc-novirt anaconda-tui

# Build the live ISO
sudo livemedia-creator \
  --make-iso \
  --ks=RaBbLE-OS-LiveISO.ks \
  --project="RaBbLE-OS" \
  --releasever=43 \
  --iso-name=RaBbLE-OS-Live.iso \
  --iso-only \
  --nomacboot
```

**The live ISO kickstart (`RaBbLE-OS-LiveISO.ks`) defines the live environment:**

```kickstart
# Packages for the live session (NOT the installed system)
%packages
@core
hyprland                    # compositor
kitty                       # terminal
gnome-disk-utility          # partition tool
firefox                     # browser
waybar                      # status bar (minimal config)
fuzzel                      # launcher
mako                        # notifications
grim                        # screenshots
slurp
hyprpaper                   # wallpaper
pipewire                    # audio
wireplumber
NetworkManager
NetworkManager-wifi
jetbrains-mono-fonts-all    # fonts
fontawesome-6-free-fonts
google-noto-sans-fonts
anaconda                    # the actual installer (optional — or script-only)
%end

%post
# Deploy minimal RaBbLE Hyprland config for the live session
# Void background, magenta borders, fuzzel themed
# Desktop entries: "Partition Disk", "Install RaBbLE-OS", "Terminal", "Browser"
# This is a MINIMAL config — just enough for the installer experience
mkdir -p /etc/skel/.config/hypr
cat > /etc/skel/.config/hypr/hyprland.conf << 'HYPR'
monitor=,preferred,auto,auto
exec-once = waybar
exec-once = hyprpaper
exec-once = mako
general {
    border_size = 2
    col.active_border = rgba(ff2d78ff) rgba(bf5fffff) 45deg
    col.inactive_border = rgba(2a2840ff)
    gaps_in = 4
    gaps_out = 8
}
decoration {
    rounding = 8
}
input {
    kb_layout = us
}
bind = SUPER, Return, exec, kitty
bind = SUPER, Space, exec, fuzzel
bind = SUPER, Q, killactive
HYPR

# Auto-login to Hyprland (no SDDM in live session)
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << 'AUTO'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin liveuser --noclear %I $TERM
AUTO

# .bash_profile launches Hyprland on TTY1
cat >> /etc/skel/.bash_profile << 'PROF'
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
PROF

# Desktop launcher for the installer
mkdir -p /etc/skel/Desktop
cat > /etc/skel/Desktop/install-rabble.desktop << 'DESK'
[Desktop Entry]
Name=Install RaBbLE-OS
Exec=kitty -e bash -c "curl -fsSL https://raw.githubusercontent.com/markm1206/RaBbLE-OS/main/RaBbLE-OS-Install.sh | bash"
Icon=system-software-install
Type=Application
DESK
%end
```

**Key decisions:**
- Live session uses auto-login to TTY1 → Hyprland starts automatically
- No SDDM in the live session — overhead for an installer
- gnome-disk-utility for partitioning (Wayland-compatible, polkit works)
- The actual install can be either Anaconda (GUI) or script-only (our installer)
- Theming is minimal but palette-correct — void bg, magenta borders, kitty themed

**Build infrastructure needed:**
- `RaBbLE-OS-LiveISO.ks` — live environment definition
- `spells/build-iso.sh` — wraps `livemedia-creator` with correct args
- `installer/live-config/` — minimal Hyprland/waybar/kitty configs for live session
- CI/CD: optional GitHub Actions workflow to build ISOs on tag

### Tier 3 — Calamares Custom Installer (Aspirational)

Replace Anaconda entirely with [Calamares](https://calamares.io/) — a framework
for building branded OS installers. Used by Manjaro, EndeavourOS, Garuda, etc.

**What this gives you:**
- Fully themed installer GUI — RaBbLE palette, custom branding, custom slides
- Step-by-step wizard: language → keyboard → partitioning → user → install
- Partition editor built-in (no need for gnome-disk-utility)
- Runs inside the live Hyprland session as a window
- Custom QML modules for RaBbLE-specific steps (entity greeting, etc.)

**Why defer this:**
- Calamares is not packaged for Fedora (build from source or Flatpak)
- Requires writing QML branding modules
- Significant effort for cosmetic gain over Tier 2
- Better ROI after the rest of the system is stable

**When to build:** After Episode 1 lands and the system is reproducible via
Tier 1 or Tier 2. Likely Episode 2 or 3 scope.

---

## `spells/generate-kickstart.py`

Reads manifest.yml, emits the `%packages` block for any KS file.

```python
#!/usr/bin/env python3
"""Read manifest.yml, emit KS %packages block for ks:true entries."""
import yaml, sys

manifest_path = sys.argv[1] if len(sys.argv) > 1 else "ansible/packages/manifest.yml"
with open(manifest_path) as f:
    data = yaml.safe_load(f)

print("%packages --ignoremissing")
print("@core")
for pkg in data["packages"]:
    if pkg.get("ks"):
        print(pkg["name"])
print("%end")
```

Run: `python3 spells/generate-kickstart.py > /tmp/packages.inc`

---

## Quick Wins — Ansible Bug Fixes ✓ DONE (S33)

All three landed in commit `4830953` on `RaBbLE-OS-New-Horizons`.

### QW-1: supergfxd.yml → supergfx.yml include fix

**File:** `ansible/roles/hardware/x64/asus_proart_p16/tasks/main.yml`

**Problem:** `main.yml` includes `supergfxd.yml` which is a stub (debug no-op).
The working implementation is in `supergfx.yml` — never called.

**Fix:**
```yaml
# Change this line:
- { ansible.builtin.include_tasks: supergfxd.yml, tags: [hardware, power, supergfxctl] }
# To:
- { ansible.builtin.include_tasks: supergfx.yml, tags: [hardware, power, supergfxctl] }
```
Then delete `supergfxd.yml`.

**Commit:** `mend ~ hardware >> fix supergfxd stub — include working supergfx.yml // %SUPERGFX_FIXED%`

### QW-2: NVIDIA idempotency — remove nouveau gate

**File:** `ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml`

**Problem:** The `akmod-nvidia` install task has `when: "'nouveau' in lsmod_check.stdout"`.
First run works (nouveau loaded → installs driver → blacklists nouveau).
Every subsequent run: nouveau is blacklisted → condition false → skips install silently.
If driver gets removed or breaks, re-running won't fix it.

**Fix:** Remove the `when` clause from the install task. `dnf state: present` is
already idempotent — it's a no-op when packages are installed, installs when missing.

```yaml
# Remove this line from the "Install akmod-nvidia" task:
  when: "'nouveau' in lsmod_check.stdout"
```

The nouveau blacklist + lsmod check + warning message above the install task
are fine — they handle the first-run case. Only the install gate is wrong.

**Commit:** `mend ~ hardware >> remove nouveau gate from nvidia install — dnf is already idempotent // %NVIDIA_IDEMPOTENT%`

### QW-3: gparted → gnome-disk-utility in apps role

**File:** `ansible/roles/apps/tasks/packages.yml`

**Problem:** Still installs `gparted` which has a known Wayland/bubblewrap segfault
on Fedora 43 + Hyprland. Manifest and KnownIssues already decided on `gnome-disk-utility`.

**Fix:** Replace `gparted` with `gnome-disk-utility` in the utility apps task.

**Commit:** `mend ~ apps >> replace gparted with gnome-disk-utility — Wayland segfault // %APPS_FIXED%`

---

## Stub Debt & Phases — see Roadmap

Canonical location: `RaBbLE-OS-Roadmap.md` → Episode 1 → "Remaining for Episode 1 — Stub Debt".
Six phases from boot-critical stubs through custom live ISO. All detail there.

---

## "Full DE State" — Acceptance Criteria

A successful RaBbLE-OS install means: **bare Fedora → one install path → reboot → identical daily-driver experience**. This checklist is the definition of done.

### System Foundation
- [ ] `/etc/os-release` shows `RaBbLE-OS`
- [ ] ZSH is default shell for `rabble` user
- [ ] All `core` packages from manifest installed
- [ ] RPM Fusion Free + Non-Free repos enabled
- [ ] COPR repos enabled: `lionheartp/Hyprland`, `erikreider/swayosd`

### Boot Chain
- [ ] GRUB: RaBbLE theme active, 4K font, void background
- [ ] Plymouth: RaBbLE theme, palette-correct, no black flash
- [ ] SDDM: Wayland greeter, RaBbLE QML theme, launches Hyprland

### Desktop
- [ ] Hyprland starts, wallpaper visible
- [ ] Waybar renders: clock, battery, network, workspaces, tray
- [ ] Function keys: volume, brightness, mic-mute (SwayOSD)
- [ ] Fuzzel opens (`Super+Space`), RaBbLE palette
- [ ] Mako notifications fire, urgency-tiered neon borders
- [ ] Kitty opens, RaBbLE palette, JetBrains Mono font
- [ ] Screenshots work (Print / Shift+Print)
- [ ] Clipboard history via cliphist
- [ ] Hyprlock triggers on idle / `Super+Escape`
- [ ] HDMI hotplug works
- [ ] hyprpolkitagent handles pkexec dialogs

### Shell
- [ ] ZSH loads with p10k prompt, aliases (`ll`, `gs`, `rabble`)
- [ ] Bash loads with RaBbLE two-line prompt
- [ ] `LS_COLORS`, `FZF_DEFAULT_OPTS`, `BAT_THEME` set
- [ ] Shell functions available (`fcd`, `fe`, `extract`)

### Apps
- [ ] Firefox launches (`Super+B`)
- [ ] Dolphin launches (`Super+E`) with thumbnails
- [ ] mpv plays video
- [ ] pavucontrol shows PipeWire devices
- [ ] gnome-disk-utility opens

### Audio
- [ ] PipeWire running, `wpctl status` shows devices
- [ ] Audio output works (speakers / headphones)

### Hardware (ProArt P16 only)
- [ ] `supergfxctl --status` returns GPU mode
- [ ] `asusctl profile -l` returns power profiles
- [ ] `tuned-adm active` shows balanced
- [ ] NVIDIA driver installed, `nvidia-smi` works post-login

### Theme (Phase 3)
- [ ] Qt apps use RaBbLE Kvantum theme
- [ ] GTK3 apps use RaBbLE-Aether theme
- [ ] GTK4 has palette overrides
- [ ] Papirus-Dark icons, magenta folder tint
- [ ] Cursor: Bibata-Modern-Classic

### Reproducibility Gate
- [ ] `layerctl apply all` is idempotent (second run changes nothing)
- [ ] `dotctl status all` — all bundles in sync
- [ ] Fresh install → KS → reboot → all above pass
- [ ] VM test (generic_x64) passes without hardware roles

---

## Grimoire RaBbLE-OS Docs — Restructure Plan

### Audit: Current State (17 files, ~4,900 lines)

| File | Lines | Current Job | Problem |
|---|---|---|---|
| AgentGuide | 183 | Agent orientation | Overlaps Architecture, GettingStarted, Bootstrap |
| Architecture | 334 | Layer model, roles, GPU, HiDPI, symlinks, theme | Bloated — mixes orientation with deep reference |
| Roadmap | 788 | Episodes, assembly, checklists, layer state, power testing | Does 5 jobs in one file |
| Packages | 285 | Human-readable package list | Redundant with manifest.yml (has `reason:` fields) |
| Theming | 391 | Palette + component theming | Good — keep as-is |
| KnownIssues | 170 | Active bugs | Good — keep as-is |
| BootFlow | 207 | Boot chain detail | Overlaps Architecture boot section |
| Hardware | 202 | ProArt P16 specs | Reference — fine |
| HyprlandGuide | 300 | Keybinds, layout, rules | User guide — fine |
| ShellGuide | 366 | Shell reference | User guide — fine |
| Bootstrap | 238 | Script internals | Fine |
| GettingStarted | 229 | Install walkthrough | **Stale** — says KDE spin |
| ManualInstall | 296 | Validated step-by-step | **Stale** — KDE spin era |
| VM-Guide | 353 | VM dev workflow | Fine |
| AddingTargets | 133 | Add hardware targets | Fine |
| PartitionLayout | 142 | Disk layout | Fine |
| Epoch-I-Diff | 288 | Branch diff handoff | **Temporal** — specific to a moment |

### Restructure: New File Map

**Tier 1 — Agent reads these first (< 3,000 tokens total)**

| File | Source(s) | Job | Target |
|---|---|---|---|
| `AgentGuide.md` | Rewrite | What is RaBbLE-OS, layer model (compact table), key commands, config flow, branch conventions | ~800 tok |
| `Architecture.md` | Slim current | Layers, role tree, hardware targeting, boot chain overview. Drop symlink map, HiDPI, GPU detail, theme to Tier 2 | ~1,200 tok |
| `Roadmap.md` | Extract episodes only | Episode map + status + what's next. No checklists, no layer state, no power testing | ~800 tok |

**Tier 2 — Read when working on a specific area**

| File | Change |
|---|---|
| `Theming.md` | Keep as-is |
| `KnownIssues.md` | Keep as-is |
| `BootFlow.md` | Keep, add pointer note |
| `Reference.md` | **New** — absorbs: symlink map, HiDPI flow, GPU architecture, config template map (from Architecture). Layer state table (from Roadmap). |
| `Checklists.md` | **New** — absorbs: bootstrap checklist, power testing protocol, Ep1 verification, assembly plan (from Roadmap). |

**Tier 3 — Deep reference / historical**

| File | Change |
|---|---|
| Hardware.md | Keep |
| HyprlandGuide.md | Keep |
| ShellGuide.md | Keep |
| VM-Guide.md | Keep |
| AddingTargets.md | Keep |
| PartitionLayout.md | Keep |
| Bootstrap.md | Keep |

**Files to condense**

| File | Action |
|---|---|
| `Packages.md` | Reduce to pointer: "Canonical source: `ansible/packages/manifest.yml`" (~15 lines) |
| `GettingStarted.md` | Reduce to pointer: note install path changed from KDE spin to netinstall/KS. Point to KS file + Bootstrap.md |
| `ManualInstall.md` | Add HISTORICAL banner — KDE spin era, 2026-04-13 |
| `Epoch-I-Diff.md` | Add HISTORICAL banner — branch-specific moment |

**New reading order (for AgentGuide.md):**

| # | File | ~Tokens | When |
|---|---|---|---|
| 1 | AgentGuide.md | 800 | Always first |
| 2 | Architecture.md | 1,200 | Always — layer model |
| 3 | Roadmap.md | 800 | Always — what's next |
| 4 | KnownIssues.md | 400 | Before implementation |
| 5 | Theming.md | 900 | When touching palette/theme |
| 6 | Reference.md | 800 | When you need symlink/HiDPI/GPU detail |
| 7 | Checklists.md | 600 | When testing or landing an episode |

Tier 1 total: ~2,800 tokens (down from ~5,000+).

---

```
spark ~ grimoire >> installer architecture planned — three tiers // %PLAN_ACTIVE%
```
