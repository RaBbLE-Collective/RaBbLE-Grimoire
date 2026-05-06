# RaBbLE-OS-Epoch-I-Diff.md

This document is a handoff map for agents helping finalize the `RaBbLE/epoch-I`
release.

## Branches Compared

- `RaBbLE/epoch-I`
  - Rebuilt clean branch for Epoch I release prep
- `backup/epoch-I-preclean`
  - Snapshot of the original local `RaBbLE/epoch-I` tip before history cleanup
- `RaBbLE-OS-New-Horizons`
  - Active development branch used as the source for portable Epoch I backports

## Current Rebuilt Epoch I History

Commits on `RaBbLE/epoch-I` after `main`:

```text
bbe6c5e harmonize ~ grimoire >> current-state docs renamed and epoch-I entrypoints aligned // %GRIMOIRE_CURRENT%
9664be4 ingest ~ config >> shell stack, kitty, fuzzel, mako, hypridle/lock, lid suspend // %CONFIG_COMPLETE%
7dbb0c8 ingest ~ roles+entrypoints >> portable desktop stack, os identity, dolphin baseline // %DEPLOYABLE%
2b109dc harmonize ~ control-plane >> dotctl bundles and substrate docs aligned // %CONTROL_PLANE_LIVE%
b388b10 ingest ~ substrate >> foundation laid; scaffolding and install baseline crystallized // %SUBSTRATE_LAID%
```

## Original Pre-Clean Epoch I History

Commits on `backup/epoch-I-preclean` after `main`:

```text
071566e mend ~ substrate >> gitignore .claude directory // %STABLE%
065b24a ingest ~ roles/hardware/asus_proart_p16 >> port scaffold from New Horizons; nvidia+supergfx stubbed for Epoch I // %PROART_SCAFFOLD_DORMANT%
dad0839 spark ~ substrate >> RaBbLE wallpaper, kitty terminal, hyprpaper wired; waybar + functionkeys + wallpapers integrated // %DESKTOP_COMPLETE%
bc31300 spark ~ roles/waybar >> config and dotfiles tasks live // %WAYBAR_DEPLOYABLE%
a2bd1d2 spark ~ roles/hyprland >> config and dotfiles tasks live // %HYPRLAND_DEPLOYABLE%
96f1e0c ingest ~ grimoire+assets >> lore and identity layer // %LORE_CRYSTALLIZED%
1b228ee ingest ~ roles/monitoring >> sensors live, powertop mended // %MONITORING_LIVE%
0ec1918 ingest ~ roles/snapper+runtime+apps >> dormant and conditional stubs // %DORMANT_SCAFFOLD%
fcc38dc ingest ~ roles/hardware/generic >> generic x64 hardware stub // %HARDWARE_SCAFFOLD%
c2cbb03 ingest ~ roles/desktop >> Wayland desktop layer // %DESKTOP_LAYER_LIVE%
1e7f7e8 ingest ~ roles/core+boot >> infrastructure layer stubs // %INFRA_SCAFFOLD%
9875663 ingest ~ control-plane >> layerctl and dotctl — operational substrate // %CONTROL_PLANE_LIVE%
6e55f84 ingest ~ entrypoints >> Install and Bootstrap — first-contact substrate // %ENTRYPOINTS_LIVE%
5212fb0 ingest ~ substrate >> ansible core, inventory, site.yml, .gitignore // %SUBSTRATE_LAID%
```

## Diff Summary: Rebuilt Epoch I vs Original Epoch I

Command:

```bash
git diff --stat backup/epoch-I-preclean..RaBbLE/epoch-I
```

Result:

- `61 files changed`
- `2698 insertions`
- `1038 deletions`

Key additions over the original Epoch I snapshot:

- Shell stack:
  - `config/shell/bash/.bash_profile`
  - `config/shell/bash/.bashrc`
  - `config/shell/bash/.zshenv`
  - `config/shell/zsh/.zshrc`
  - `config/shell/zsh/aliases.zsh`
  - `config/shell/zsh/colors.zsh`
  - `config/shell/zsh/functions.zsh`
  - `config/shell/zsh/p10k.zsh`
- Desktop UX:
  - `config/kitty/kitty.conf`
  - `config/fuzzel/fuzzel.ini`
  - `config/mako/config`
  - `config/hypr/hypridle.conf`
  - `config/hypr/conf.d/monitors.conf`
  - `config/hypr/scripts/hdmi-hotplug.sh`
  - `config/systemd/logind.conf.d/99-rabble-lid.conf`
- Core/identity:
  - `ansible/roles/core/handlers/main.yml`
  - `ansible/roles/core/templates/os-release.j2`
  - `ansible/roles/desktop/shell/zsh/vars/main.yml`
- Grimoire:
  - `grimoire/RaBbLE-OS-Architecture.md`
  - `grimoire/RaBbLE-OS-BranchStrategy.md`
  - `grimoire/RaBbLE-OS-CommitStyle.md`
  - `grimoire/RaBbLE-OS-KnownIssues.md`
  - `grimoire/RaBbLE-OS-ShellGuide.md`

Key removals or replacements relative to the original Epoch I snapshot:

- `config/hypr/conf.d/hypridle.conf`
  - Replaced by `config/hypr/hypridle.conf`
- `config/hypr/scripts/screenshot.sh`
  - Removed to align with the New Horizons layout
- `grimoire/Architecture.md`
  - Replaced by `grimoire/RaBbLE-OS-Architecture.md`
- `grimoire/BranchStrategy.md`
  - Replaced by `grimoire/RaBbLE-OS-BranchStrategy.md`
- `grimoire/CommitStyle.md`
  - Replaced by `grimoire/RaBbLE-OS-CommitStyle.md`
- `grimoire/KnownIssues.md`
  - Replaced by `grimoire/RaBbLE-OS-KnownIssues.md`
- `grimoire/components/RaBbLE.svg`
  - Removed; asset now lives under `assets/`

Full file-level diff:

```text
M .gitignore
M README.md
M RaBbLE-OS-Install.sh
M RaBbLE-OS-dotctl.sh
M ansible/inventory/group_vars/all.yml
M ansible/roles/apps/tasks/packages.yml
M ansible/roles/boot/session_manager/handlers/main.yml
M ansible/roles/boot/session_manager/tasks/config.yml
A ansible/roles/core/handlers/main.yml
M ansible/roles/core/tasks/config.yml
A ansible/roles/core/templates/os-release.j2
M ansible/roles/desktop/hyprland/tasks/config.yml
M ansible/roles/desktop/hyprland/tasks/dotfiles.yml
M ansible/roles/desktop/hyprland/vars/main.yml
M ansible/roles/desktop/shell/zsh/tasks/packages.yml
A ansible/roles/desktop/shell/zsh/vars/main.yml
M ansible/roles/desktop/swayosd/tasks/service.yml
M ansible/roles/desktop/terminal/tasks/packages.yml
M ansible/roles/desktop/waybar/tasks/config.yml
M ansible/roles/desktop/waybar/tasks/dotfiles.yml
M ansible/roles/desktop/waybar/vars/main.yml
M ansible/roles/desktop/wayland/vars/main.yml
M ansible/roles/monitoring/tasks/sensors.yml
A config/fuzzel/fuzzel.ini
M config/hypr/conf.d/autostart.conf
M config/hypr/conf.d/env.conf
M config/hypr/conf.d/functionkeys.conf
D config/hypr/conf.d/hypridle.conf
A config/hypr/conf.d/monitors.conf
M config/hypr/conf.d/windowrules.conf
M config/hypr/conf.d/workspaces.conf
A config/hypr/hypridle.conf
M config/hypr/hyprland.conf
M config/hypr/hyprlock.conf
M config/hypr/hyprpaper.conf
A config/hypr/scripts/hdmi-hotplug.sh
D config/hypr/scripts/screenshot.sh
A config/kitty/kitty.conf
A config/mako/config
A config/shell/bash/.bash_profile
A config/shell/bash/.bashrc
A config/shell/bash/.zshenv
A config/shell/zsh/.zshrc
A config/shell/zsh/aliases.zsh
A config/shell/zsh/colors.zsh
A config/shell/zsh/functions.zsh
A config/shell/zsh/p10k.zsh
A config/systemd/logind.conf.d/99-rabble-lid.conf
M config/waybar/config.jsonc.ref
M grimoire/AiQuickstart.md
D grimoire/Architecture.md
M grimoire/DistilledNonZense.md
A grimoire/RaBbLE-OS-Architecture.md
R100 grimoire/BranchStrategy.md grimoire/RaBbLE-OS-BranchStrategy.md
R100 grimoire/CommitStyle.md grimoire/RaBbLE-OS-CommitStyle.md
R081 grimoire/KnownIssues.md grimoire/RaBbLE-OS-KnownIssues.md
A grimoire/RaBbLE-OS-ShellGuide.md
M grimoire/RaBbLE-Palette.md
M grimoire/RaBbLE-Roadmap.md
M grimoire/RaBbLE.md
D grimoire/components/RaBbLE.svg
```

## Diff Summary: Rebuilt Epoch I vs New Horizons

Command:

```bash
git diff --name-status RaBbLE-OS-New-Horizons..RaBbLE/epoch-I
```

Only 7 files differ:

```text
M RaBbLE-OS-Install.sh
M ansible/roles/apps/tasks/packages.yml
M ansible/roles/hardware/x64/asus_proart_p16/handlers/main.yml
M ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml
M ansible/roles/hardware/x64/asus_proart_p16/tasks/supergfx.yml
M config/waybar/config.jsonc.ref
M grimoire/AiQuickstart.md
```

Meaning of those remaining differences:

- `RaBbLE-OS-Install.sh`
  - Epoch I intentionally defaults to cloning `RaBbLE/epoch-I` and the curl
    example points at the branch file, not `main`
- `ansible/roles/apps/tasks/packages.yml`
  - Epoch I intentionally installs a working file manager baseline:
    `dolphin`, `ark`, `ffmpegthumbs`, `kio-extras`
- `config/waybar/config.jsonc.ref`
  - Window title map changed from `thunar` to `dolphin`
- `grimoire/AiQuickstart.md`
  - Entry-point docs updated to the Epoch I curl/install path
- `ansible/roles/hardware/x64/asus_proart_p16/handlers/main.yml`
  - Rebuilt Epoch I keeps the older stub-oriented handler file and does not
    carry the temporary SDDM restart behavior from New Horizons
- `ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml`
  - Rebuilt Epoch I keeps the stub version
  - New Horizons contains active NVIDIA role logic
  - This is intentionally deferred to `mend-I/proart-nvidia`
- `ansible/roles/hardware/x64/asus_proart_p16/tasks/supergfx.yml`
  - Rebuilt Epoch I keeps the stub version
  - New Horizons contains active `supergfxctl` logic
  - This is intentionally deferred to `mend-I/proart-nvidia`

Exact diff highlights versus New Horizons:

- `RaBbLE-OS-Install.sh`
  - Added `RABBLE_OS_BRANCH="${RABBLE_OS_BRANCH:-RaBbLE/epoch-I}"`
  - Existing clone path now uses `git clone --branch "$RABBLE_OS_BRANCH" --single-branch`
  - Existing repo path now fetches/checks out/pulls the selected branch
- `ansible/roles/apps/tasks/packages.yml`
  - Replaced apps stub with real baseline file-manager install task
- `ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml`
  - Active NVIDIA driver logic intentionally replaced by a no-op stub
- `ansible/roles/hardware/x64/asus_proart_p16/tasks/supergfx.yml`
  - Active `supergfxctl` logic intentionally replaced by a no-op stub

## Release-Finalization Questions

These are the remaining decisions before calling Epoch I final:

1. Keep the Epoch I-specific installer behavior.
   - Current behavior is correct for the stated release goal:
     curl should bootstrap `RaBbLE/epoch-I`, not `main`

2. Keep `dolphin` as the Epoch I file manager baseline.
   - Current config and keybinds already assume `dolphin`
   - The apps role now installs it explicitly

3. Confirm the ProArt hardware files stay stubbed on Epoch I.
   - Recommended based on the roadmap
   - If changed, it should be a deliberate scope decision, not an accidental
     re-import from New Horizons

4. Run Fedora 43 bootstrap validation on the rebuilt branch.
   - Fresh install via curl
   - `layerctl apply all`
   - `RaBbLE-OS-dotctl.sh apply all`
   - Reboot and verify the full Epoch I checklist

## Useful Commands For Other Agents

```bash
# Show rebuilt Epoch I history
git log --oneline RaBbLE/epoch-I ^main

# Show original Epoch I history
git log --oneline backup/epoch-I-preclean ^main

# Show full file-level delta vs original Epoch I
git diff --name-status backup/epoch-I-preclean..RaBbLE/epoch-I

# Show full file-level delta vs New Horizons
git diff --name-status RaBbLE-OS-New-Horizons..RaBbLE/epoch-I

# Inspect only the intentionally remaining New Horizons differences
git diff RaBbLE-OS-New-Horizons..RaBbLE/epoch-I -- \
  RaBbLE-OS-Install.sh \
  ansible/roles/apps/tasks/packages.yml \
  ansible/roles/hardware/x64/asus_proart_p16/handlers/main.yml \
  ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml \
  ansible/roles/hardware/x64/asus_proart_p16/tasks/supergfx.yml \
  config/waybar/config.jsonc.ref \
  grimoire/AiQuickstart.md
```

## Current Status Note

After the history rebuild, local `RaBbLE/epoch-I` will appear rewritten relative
to `origin/RaBbLE/epoch-I`. Publishing it will require:

```bash
git push --force-with-lease origin RaBbLE/epoch-I
```
