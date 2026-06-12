# Theming.md — RaBbLE Visual System

```
transcribe ~ grimoire >> palette and component guide // %THEME_LOCKED%
```

> **Canonical palette reference:** `RaBbLE-Palette.md`
> **Palette Ansible variables:** `ansible/inventory/group_vars/all.yml` → `rabble_palette`
> **Architecture propagation map:** `Architecture.md` → Theme System

---

## The Aesthetic

RaBbLE-OS is heavily inspired by **synthwave outrun**. Every component should feel like a neon-lit grid stretching into a dark horizon. The rules:

- Backgrounds: void-dark (`#0a0010`), never grey
- Neons: saturated and bright, perceived as lit from within
- Text: bright off-white (`#e8e6f0`), glowing against the void
- No pastels. No earth tones. No grey-on-grey.

The "glow" effect is achieved through high contrast + layer effects, not by softening the palette.

---

## Palette Quick Reference

See `RaBbLE-Palette.md` for the full table, design philosophy, Ansible variable block, and component mapping. Quick reference:

| Role | Hex |
|---|---|
| Hot Magenta (primary) | `#ff2d78` |
| Electric Cyan (secondary) | `#00f5ff` |
| Soft Violet (tertiary) | `#bf5fff` |
| Outrun Pink (grid/horizon) | `#ff79c6` |
| Deep Void (background) | `#0a0010` |
| Surface | `#12132a` |
| Raised | `#1a1b2e` |
| Border (inactive) | `#2a2840` |
| Primary Text | `#e8e6f0` |
| Muted Text | `#6b6880` |
| Error | `#e05c6f` |
| Success | `#50fa7b` |
| Warning | `#f1fa8c` |

---

## Component Locations

| Component | Source | Deployed to | Reload |
|---|---|---|---|
| GRUB2 theme | `themes/grub2/rabble/` | `/boot/grub2/themes/rabble/` | `grub2-mkconfig -o /boot/grub2/grub.cfg` |
| Plymouth theme | `themes/plymouth/rabble/` | `/usr/share/plymouth/themes/rabble/` | `dracut -f --regenerate-all` |
| SDDM theme | `themes/sddm/rabble/` | `/usr/share/sddm/themes/rabble/` | `sddm-greeter-qt6 --test-mode ...` then restart |
| Hyprland look | `dotfiles/hyprland/conf.d/look.conf` | `~/.config/hypr/conf.d/look.conf` (symlink) | `hyprctl reload` |
| Quickshell | `dotfiles/quickshell/` | `~/.config/quickshell/` (symlinks) | `pkill quickshell && quickshell &` |
| Zsh prompt (p10k) | `dotfiles/shell/zsh/p10k.zsh` | `~/.config/zsh/p10k.zsh` (symlink) | `exec zsh` |
| Starship prompt | `dotfiles/shell/starship.toml` | `~/.config/starship.toml` (symlink) | `exec zsh` |
| Foot terminal | `dotfiles/shell/foot.ini` | `~/.config/foot/foot.ini` (symlink) | reopen foot |
| Mako notifications | `dotfiles/shell/mako.conf` | `~/.config/mako/config` (symlink) | `makoctl reload` |

---

## Changing the GRUB2 Theme

GRUB renders before the compositor — its palette is baked into compiled assets.

```bash
# 1. Edit theme.txt
$EDITOR themes/grub2/rabble/theme.txt

# 2. Regenerate assets if palette changed
bash themes/grub2/rabble/generate-assets.sh

# 3. Deploy
sudo ansible-playbook -i ansible/inventory/hosts.yml ansible/deploy-boot.yml --tags grub -K
# or: ./bootstrap.sh → Boot Layer → GRUB2
```

**Palette targets in theme.txt:**
- `item_color`: `#ff2d78` (hot magenta — selected entry)
- `selected_item_color`: `#00f5ff` (cyan — active highlight)
- `menu_color_normal`: `#6b6880` (muted — unselected entries)
- Background: `#0a0010` (deep void)

---

## Changing the Plymouth Theme

```bash
# 1. Edit animation script
$EDITOR themes/plymouth/rabble/rabble.script

# 2. Regenerate PNG frames if needed
bash themes/plymouth/rabble/generate-assets.sh

# 3. Replace logo (256×256+ PNG)
cp my-logo.png themes/plymouth/rabble/assets/logo.png

# 4. Deploy (triggers dracut — ~30-60s)
sudo ansible-playbook -i ansible/inventory/hosts.yml ansible/deploy-boot.yml --tags plymouth -K
```

**Palette targets in rabble.script:**
- Background: `#0a0010`
- RaBbLE text: `#ff2d78`
- Tagline: `#bf5fff`
- Spinner: `#00f5ff` → `#ff2d78` gradient sweep

---

## Changing the SDDM Theme

```bash
# 1. Edit the QML theme
$EDITOR themes/sddm/rabble/Main.qml

# 2. Test without rebooting
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble

# 3. Deploy when satisfied
sudo ansible-playbook -i ansible/inventory/hosts.yml ansible/deploy-boot.yml --tags sddm -K
```

**Palette targets in Main.qml:**
- Background fill: `#0a0010`
- Input field background: `#12132a`
- Input field border (focus): `#ff2d78` with `DropShadow { color: "#ff2d78"; radius: 12 }`
- Button: `#ff2d78` background, `#e8e6f0` text
- User text: `#e8e6f0`, label text: `#6b6880`

---

## Changing Hyprland Look

All visual settings are in `dotfiles/hyprland/conf.d/look.conf`:

```bash
$EDITOR dotfiles/hyprland/conf.d/look.conf
hyprctl reload    # live — no logout needed
```

**Key variables and their palette targets:**

```ini
# Active border — magenta → violet gradient
col.active_border = rgba(ff2d78ff) rgba(bf5fffff) 45deg

# Inactive border
col.inactive_border = rgba(2a2840ff)

# Background (when no wallpaper)
col.background = rgba(0a0010ff)

# Rounding, gaps, blur
rounding = 8
gaps_in = 4
gaps_out = 8
blur.size = 6
blur.passes = 3
```

---

## Changing the Bar

**Waybar (current active bar)** — edit CSS for theming:
```bash
$EDITOR dotfiles/shell/waybar/style.css   # palette targets: bg=#0a0010, accent=#ff2d78
pkill waybar && waybar &
```

**Quickshell (Phase 1 replacement):**
```bash
$EDITOR dotfiles/quickshell/bar/RaBbLEBar.qml
pkill quickshell && sleep 0.3 && quickshell &
```

Quickshell QML theming targets — glow effect via `layer`:
```qml
color: "#ff2d78"
layer.enabled: true
layer.effect: Glow { color: "#ff2d78"; radius: 8; spread: 0.1 }
```

---

## Terminal Theming (Foot / Kitty)

**Foot (`dotfiles/shell/foot.ini`):**

```ini
[colors]
background=0a0010
foreground=e8e6f0

# Normals
regular0=0a0010   # black
regular1=e05c6f   # red
regular2=50fa7b   # green
regular3=f1fa8c   # yellow
regular4=bf5fff   # blue → violet
regular5=ff2d78   # magenta
regular6=00f5ff   # cyan
regular7=e8e6f0   # white

# Brights (neon versions)
bright0=2a2840
bright1=e05c6f
bright2=50fa7b
bright3=f1fa8c
bright4=bf5fff
bright5=ff2d78
bright6=00f5ff
bright7=ffffff
```

---

## Shell Prompt (Starship)

Key palette targets in `dotfiles/shell/starship.toml`:

```toml
[character]
success_symbol = "[❯](bold #ff2d78)"
error_symbol = "[❯](bold #e05c6f)"

[git_branch]
style = "bold #bf5fff"

[git_status]
style = "bold #ff79c6"

[directory]
style = "bold #00f5ff"

[cmd_duration]
style = "bold #f1fa8c"
```

---

## Running p10k Configure

```bash
p10k configure
# After running, copy back to repo:
cp ~/.config/zsh/p10k.zsh ~/RaBbLE-OS/dotfiles/shell/zsh/p10k.zsh
```

---

## GTK and Qt Desktop Theming — Unified Aether

The compositor, bar, and terminal are already palette-aligned. The remaining surface area is
GTK apps (pavucontrol, nm-connection-editor, Firefox chrome, gnome-disk-utility) and Qt/KDE
apps (Dolphin). These need a unified Aether theme so all apps feel like one system.

### The Problem: Three Rendering Toolkits

| Toolkit | Apps | Theming System |
|---|---|---|
| GTK3 | pavucontrol, nm-applet, celluloid | `~/.local/share/themes/<name>/gtk-3.0/gtk.css` |
| GTK4 + libadwaita | gnome-disk-utility, newer GNOME apps | `~/.config/gtk-4.0/gtk.css` (partial — libadwaita resists) |
| Qt5/Qt6 | Dolphin, qt apps | Kvantum SVG engine via qt5ct/qt6ct |

### The Solution Stack

**Qt — Kvantum + qt5ct/qt6ct**
Kvantum is an SVG-based Qt theme engine giving full visual control over Qt5 and Qt6 apps,
including Dolphin and all KDE frameworks applications.

Required packages: `kvantum`, `qt5ct`, `qt6ct`

Required env vars in `config/hypr/conf.d/env.conf`:
```ini
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_STYLE_OVERRIDE,kvantum
```

Theme files deployed by Ansible:
```
~/.config/Kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig
~/.config/Kvantum/RaBbLE-Aether/RaBbLE-Aether.svg
~/.config/qt5ct/qt5ct.conf
~/.config/qt6ct/qt6ct.conf
```

KDE color accents (Dolphin folder color, dialog palette):
```
~/.local/share/color-schemes/RaBbLE-Aether.colors
```

**GTK3 — Custom CSS theme**
```
~/.local/share/themes/RaBbLE-Aether/gtk-3.0/gtk.css
~/.local/share/themes/RaBbLE-Aether/index.theme
```
Set via env: `env = GTK_THEME,RaBbLE-Aether`
Or via gsettings: `gsettings set org.gnome.desktop.interface gtk-theme 'RaBbLE-Aether'`

**GTK4 / libadwaita — Partial override**
libadwaita controls its own accent colors and resists full external theming by design.
`~/.config/gtk-4.0/gtk.css` injects palette overrides for background, surfaces, and borders.
Full palette fidelity is not achievable in GTK4 without patching libadwaita itself.
Accept partial theming; unify visually through the icon theme instead.

**Icons — papirus-icon-theme + papirus-folders**
papirus-dark provides a clean, consistent icon language across GTK and Qt apps.
`papirus-folders` tints folder icons to any color — use Aether magenta (`#ff2d78`).

Required packages: `papirus-icon-theme`, `papirus-folders`

```bash
# After install — tint folders to Aether primary
papirus-folders --color magenta --theme Papirus-Dark
```

**GTK settings tool for Wayland — nwg-look**
Standard `lxappearance` uses X11 and does not apply correctly under Hyprland.
`nwg-look` is the wlroots-native equivalent.

Required package: `nwg-look`

### Aether as Theme Generator

The palette is canonical in `RaBbLE-Agent/RaBbLE-Palette.md` and deployed as Ansible vars
in `ansible/inventory/group_vars/all.yml`. GTK and Kvantum theme files should be Ansible
**templates** (`.j2`) driven by those vars, not static files. Palette change in one place
propagates to all toolkit themes on next `ansible-playbook` run.

Planned role: `ansible/roles/desktop/theme/` — not yet created.

### Theming Priority per Component

| Component | Coverage | Method |
|---|---|---|
| Hyprland borders/blur | Full | `look.conf` |
| Waybar | Full | `style.css` (already done) |
| Kitty terminal | Full | `kitty.conf` palette block |
| Qt5/Qt6 (Dolphin, etc.) | Full | Kvantum + qt6ct |
| GTK3 apps | Full | Custom Aether gtk.css theme |
| GTK4 / libadwaita apps | Partial | `~/.config/gtk-4.0/gtk.css` injection |
| SDDM greeter | Full | Custom QML theme |
| Plymouth boot | Full | Script theme with palette palette |
| GRUB2 boot | Full | theme.txt + generated assets |
| Icons | Full | papirus-dark + magenta folder tint |
| Cursor | Full | Bibata-Modern-Classic via hyprcursor |

---

## Adding a New Dotfile

1. Create the file in the appropriate `dotfiles/` subdirectory
2. Add a symlink task to `ansible/deploy-dotfiles.yml`
3. Run: `./bootstrap.sh → UI/UX Layer → Re-link dotfiles`

Example — adding `~/.config/fuzzel/fuzzel.ini`:

```yaml
- name: Ensure fuzzel config dir
  ansible.builtin.file:
    path: "{{ cfg }}/fuzzel"
    state: directory
    mode: "0755"

- name: Link fuzzel config
  ansible.builtin.file:
    src:   "{{ df }}/shell/fuzzel.ini"
    dest:  "{{ cfg }}/fuzzel/fuzzel.ini"
    state: link
    force: true
```

Fuzzel palette targets:
```ini
[colors]
background=0a0010ff
text=e8e6f0ff
match=ff2d78ff
selection=ff2d78ff
selection-text=0a0010ff
border=2a2840ff
```

---

```
transcribe ~ grimoire >> theming guide crystallized // %THEME_LOCKED%
```

→ `layers/RaBbLE-OS-Layer-Desktop.md` — desktop layer role state and theming tasks
→ `desktop/RaBbLE-OS-Desktop-Hyprland.md` — Hyprland border and gap config
→ `fix/RaBbLE-OS-KnownIssues.md` — Qt theme env vars not set, Kitty not themed
→ `../RaBbLE-Agent/RaBbLE-Palette.md` — canonical palette source (never invent hex values)

---

## VSCodium — RaBbLE Aether Theme

### What it is

A full Aether visual injection for VSCodium. Two layers:

1. **Color theme extension** (`RaBbLE-Aether`) — JSON workbench colors covering editor, sidebar, tabs, terminal, status bar, and all UI chrome. Palette-compliant: void `#0a0010`, raised `#1a1b2e`, magenta `#ff2d78`, cyan `#00f5ff`, violet `#bf5fff`.

2. **Custom CSS injection** — dynamic effects impossible in JSON alone: conic-gradient panel rings, flowing tab ribbon, animated glow. Injected directly into VSCodium's bundled `workbench.desktop.main.css` at the top of the file.

### File layout

```
RaBbLE-OS/config/vscodium/
  User/
    settings.json                          ← activates the theme + zoomLevel 1
  extensions/RaBbLE-Aether-theme/
    package.json                           ← extension manifest
    themes/RaBbLE-Aether-color-theme.json  ← JSON workbench colors
    assets/custom.css                      ← animated CSS effects (source of truth)
```

Deployed to `~/.vscode-oss/extensions/RaBbLE-Collective.rabble-aether-theme-0.0.1/` by Ansible.

### CSS design language

The injected CSS mirrors the Aether component vocabulary exactly:

| Effect | CSS technique | Aether analogue |
|---|---|---|
| Panel ring borders (activitybar, sidebar) | `::before` conic-gradient + `mask-composite: exclude` | `.rabble-border-harmony` |
| Tab strip top + panel top seam | `::before` linear-gradient `background-size: 200%` + scroll | `.rabble-harmony-line::after` |
| Floating overlays (palette, toasts, menus) | `::before` conic-gradient ring + `aether-glow-cycle` | `.rabble-border-harmony` |
| Cycling box-shadow glow | `@keyframes aether-glow-cycle` | `@keyframes harmony-glow` |

**Panel ring details:** `inset: 0; padding: 2px` keeps the ring within element bounds — immune to `overflow: hidden` on ancestor containers (critical in VSCodium's grid-view layout). The conic-gradient rotates from the element's center so all 4 corners connect seamlessly. Both activitybar and sidebar use the same `aether-harmony-spin 9s` timing so their adjacent edges stay color-matched.

**Tab ribbon:** Replaces the solid `tab.activeBorderTop` (set transparent in JSON) with a 2px `linear-gradient(90deg, cyan, violet, magenta, violet, cyan)` at `background-size: 200% 100%`, scrolled by `aether-flow-x`. One full gradient sweep visible at all times — no repeating barber-pole pattern.

### How Ansible installs it

Ansible role: `ansible/roles/apps/tasks/vscode.yml`, tags: `apps, vscode`.

Steps performed:
1. Create `~/.vscode-oss/extensions/RaBbLE-Collective.rabble-aether-theme-0.0.1/{assets,themes}/`
2. Copy `settings.json` → `~/.config/VSCodium/User/settings.json`
3. Copy extension files (package.json, color theme JSON, custom.css)
4. Find `workbench.desktop.main.css` at `/usr/share/codium/resources/app/out/vs/workbench/`
5. Remove any legacy `@import` injection (blocked by Electron's `vscode-file://` security policy)
6. Inject `custom.css` content inline using `blockinfile` with `/* BEGIN/END RABBLE-AETHER-INJECTION */` markers
7. Recompute the SHA-256 checksum in `product.json` (prevents "corrupt installation" banner)

The injection is idempotent — re-running updates the block and recomputes the checksum.

### How to apply / maintain

```bash
# Apply (requires sudo for the workbench CSS write):
bash RaBbLE-OS-layerctl.sh apply apps --tags vscode
# Prompts for BECOME password (sudo).

# After applying, hard-restart VSCodium (Reload Window does NOT bust the theme cache):
pkill -x codium && sleep 1 && hyprctl dispatch exec "codium <dir>"
```

**After every VSCodium package update**, re-run the Ansible task. The package update replaces `workbench.desktop.main.css` (and its checksum), wiping the injection. The task detects the change and re-injects.

**Editing the CSS:** Edit the source at `config/vscodium/extensions/RaBbLE-Aether-theme/assets/custom.css`, then re-run Ansible. Never edit the injected copy in `/usr/share/codium/` directly — it will be overwritten on the next Ansible run or package update.

### Known gotchas

- `@import url('file://...')` is blocked by Electron's cross-scheme security model (`vscode-file://` cannot import `file://` resources). CSS must be inlined, not linked.
- `overflow: hidden` on `.grid-view-container` ancestors clipped pseudo-elements that escaped element bounds with negative offsets. Fix: keep ribbons/rings inside element bounds using `inset: 0; padding: Npx` or `position: absolute; right/top: 0`.
- The "Your installation appears to be corrupt" banner fires when `workbench.desktop.main.css` doesn't match the SHA-256 in `product.json`. The Ansible task repairs this automatically.
- `Reload Window` (`Ctrl+Shift+P → Reload`) does NOT bust the theme cache. Only a hard process restart works: `pkill -x codium`.
- Never use `pkill -f codium` — `-f` matches the full command line and will kill the agent's own harness shell if "codium" appears anywhere in it. Use `pkill -x codium` (exact name match only).
