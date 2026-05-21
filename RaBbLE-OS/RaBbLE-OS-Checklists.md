# RaBbLE-OS-Checklists.md — Bootstrap, Testing, Assembly

```
transcribe ~ substrate >> checklists extracted from Roadmap // %S34%
```

> Operational checklists extracted from Roadmap.md.
> For episode scope and what's next → `Roadmap.md`.
> For layer state → `Reference.md`.

---

## Episode 1 Assembly Plan

**Strategy:** Use `git checkout RaBbLE-OS-New-Horizons -- <paths>` to bring files
into Episode 1 without importing dev history. Commit in dependency order.
Do NOT cherry-pick — branches have divergent history.

After Episode 1 lands on main: `git rebase main` on New Horizons to restore shared history.

### What stays in New Horizons / fix/* (NOT for Episode 1)

| Files | Reason |
|-------|--------|
| `ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml` | fix/proart-nvidia |
| `ansible/roles/hardware/x64/asus_proart_p16/handlers/main.yml` | fix/proart-nvidia |
| `ansible/roles/hardware/x64/asus_proart_p16/tasks/supergfx.yml` | fix/proart-nvidia |

### Package 1 — control-plane (Plot A)

```bash
git checkout RaBbLE-OS-New-Horizons -- RaBbLE-OS-dotctl.sh .gitignore README.md
```

Commit: `harmonize ~ control-plane >> dotctl bundles: kitty, fuzzel, mako; skip missing // %CONTROL_PLANE_LIVE%`

### Package 2 — ansible-roles (Plot A)

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

Commit: `ingest ~ ansible-roles >> logind lid, kitty+zsh packages, waybar/hyprland vars // %ROLES_UPDATED%`

### Package 3 — config (Plot B)

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

Commit: `ingest ~ config >> shell stack, kitty, fuzzel, mako, hypridle/lock, lid suspend // %CONFIG_COMPLETE%`

### Package 4 — grimoire (Plot A)

```bash
git checkout RaBbLE-OS-New-Horizons -- grimoire/
git rm grimoire/Architecture.md
git rm grimoire/components/RaBbLE.svg
```

Commit: `harmonize ~ grimoire >> rename docs RaBbLE-OS-prefix; current-state only // %GRIMOIRE_CURRENT%`

---

## Bootstrap Checklist — Episode 1 (Fedora 43)

### Pre-Bootstrap

- [ ] All 4 packages ported to `RaBbLE/episode-I` and committed
- [ ] `git log --oneline RaBbLE/episode-I` — verify clean package history
- [ ] Dry run on current machine: `layerctl apply all --check`

### Install Sequence

- [ ] Fresh Fedora 43 base (clean install or snapshot at post-install state)
- [ ] `curl -fsSL .../RaBbLE-OS-Install.sh | bash` — or clone + `bash RaBbLE-OS-Bootstrap.sh`
- [ ] `ansible-galaxy collection install -r ansible/requirements.yml`
- [ ] `./RaBbLE-OS-layerctl.sh apply all` — note any errors, do not skip them
- [ ] `./RaBbLE-OS-dotctl.sh apply all`
- [ ] Reboot

### Session Verification

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

### Shell Verification

- [ ] ZSH loads with p10k prompt
- [ ] Bash loads with RaBbLE two-line prompt
- [ ] `ll`, `gs`, `rabble`, `rabble-dots` aliases work
- [ ] `fcd`, `fe`, `extract` functions available in ZSH
- [ ] `LS_COLORS`, `FZF_DEFAULT_OPTS`, `BAT_THEME` set (check `colors256`)

### Final Gate

- [ ] `layerctl verify all` — all layers report `%STABLE%` or documented exception
- [ ] Any new failures logged to `KnownIssues.md`
- [ ] If all gates pass: land episode to main
  ```bash
  git checkout main
  git merge --squash RaBbLE/episode-I
  git commit -m "evolve ~ substrate >> episode-I crystallized // %EP1_LANDED%"
  git checkout RaBbLE-OS-New-Horizons
  git rebase main
  ```

---

## Episode 1 Verification Checklist

Before landing to `main`:

- [ ] `layerctl apply all` completes on a clean Fedora 43 install (no proart-specific errors)
- [ ] SDDM launches Hyprland session
- [ ] Waybar displays (clock, battery, network, workspaces)
- [ ] Function keys work (volume, brightness, mic)
- [ ] Wallpaper displays on all monitors
- [ ] HDMI hotplug moves workspace 11 onto plug
- [ ] Hypridle + Hyprlock trigger correctly
- [ ] Monitoring tools functional (btop, powertop, sensors)
- [ ] Generic x64 target smoke-tested on a VM
- [ ] Layer states documented as %STABLE% or explicitly deferred to `fix/*`

---

## Power Testing Protocol

Run on battery, wifi connected but idle, display at 50% brightness.
**Goal:** `<10W` idle. Primary suspect: NVIDIA GPU waking unnecessarily.

### Measurement commands

```bash
# Battery discharge rate (most accurate)
upower -d | grep -A3 "BAT" | grep "energy-rate"

# Sysfs cross-check
awk '{printf "%.1f W\n", $1/1000000}' /sys/class/power_supply/BAT0/power_now

# NVIDIA state
nvidia-smi --query-gpu=name,power.draw,pstate --format=csv,noheader 2>/dev/null
cat /sys/bus/pci/devices/0000:01:00.0/power_state

# CPU package power
turbostat --show PkgWatt,CorWatt,RAMWatt,PkgTmp --interval 5 --num_iterations 3
```

### Measurement stages

| Stage | When | Expected |
|-------|------|----------|
| **S0: TTY** | Fresh boot, no GUI | ~8–12 W |
| **S1: SDDM** | After bootstrap, SDDM only | ~10–14 W |
| **S2: Hyprland idle** | AMD only, nothing open | ~10–15 W |
| **S3: Light workload** | Firefox + terminal, idle | ~12–18 W |
| **S4: NVIDIA loaded** | After fix/proart-nvidia | measure |
| **S5: NVIDIA RTD3** | After D3cold fix | should be ≈ S2 |

Record readings in `KnownIssues.md`.
