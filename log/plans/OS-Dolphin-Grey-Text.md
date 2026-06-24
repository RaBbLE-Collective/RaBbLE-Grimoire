# Plan: Dolphin Icon Labels Grey / Unreadable Text

**Status:** Partial fixes committed, not yet verified readable. KF6 KColorScheme read path unconfirmed.
**Repo:** RaBbLE-OS `new-horizons` · **Last touched:** S160 (2026-06-23)

---

## Architecture: Two Separate Text Color Paths

Dolphin has TWO rendering paths for text. They are independent.

| Path | Controls | Source |
|---|---|---|
| **Qt QPalette** (via qt6ct) | Toolbar text, window decorations, menus | `~/.config/qt6ct/qt6ct.conf` → `color_scheme_path` → `.conf` color scheme |
| **KColorScheme** | Icon view labels, sidebar item text | `~/.config/kdeglobals` `[Colors:View]` sections OR `.colors` file |

`QT_QPA_PLATFORMTHEME=qt6ct` (set in `~/.config/hypr/conf.d/env.conf`) means the KDE platform plugin never loads. This is correct for Hyprland. BUT it means:
- Qt QPalette comes entirely from qt6ct → must have a dark scheme set
- KColorScheme reads from kdeglobals `[Colors:*]` groups directly (KF6 behavior without plasma-integration)

## Fixes Already Committed

### Layer 1 — Qt QPalette (FIXED, confirmed working)
- Created `config/qt6ct/colors/CatppuccinMochaMauve.conf` and `config/qt5ct/` equivalent
- Set `color_scheme_path` in `config/qt6ct/qt6ct.conf` and `config/qt5ct/qt5ct.conf`
- Text = `#cdd6f4`, Base = `#1e1e2e`, Highlight = `#cba6f7`
- Committed: `d8f3314`

### Layer 2 — KColorScheme icon labels (COMMITTED, unverified)
- Added `[General] Name=Catppuccin Mocha Mauve` to `config/color-schemes/CatppuccinMochaMauve.colors`
  (was missing entirely → KF6 fell back to Breeze grey)
- Removed duplicate `[General]` at line 135 of `.colors` file that had `ColorScheme=CatppuccinMochaMauve`
  (KConfig last-value-wins would override the correct name)
- Fixed `config/kdeglobals/kdeglobals`: `ColorScheme=CatppuccinMochaMauve` → `ColorScheme=Catppuccin Mocha Mauve`
  (must match `Name=` exactly for KF6 lookup)
- Bumped `ForegroundInactive` → `205,214,244` (= ForegroundNormal) in all view sections
  (tiling WM: Dolphin is often in inactive state = labels used ForegroundInactive = grey)
- Committed: `f1ebf19`

## What's Still Unknown

**Key open question:** Does KF6 KColorScheme without `plasma-integration` read from `~/.config/kdeglobals [Colors:*]` directly, or from a different source?

Evidence so far:
- `kreadconfig5` correctly shows `ColorScheme=Catppuccin Mocha Mauve` and `ForegroundNormal=205,214,244`
- Red-test on `ForegroundNormal` had no visible effect on icon labels
- Red-test on qt6ct Text role had no visible effect on icon labels
- Inactive-window hypothesis: labels may use `ForegroundInactive`, not `ForegroundNormal`

## Plan for Next Session

### Step 1: Deploy and verify the ForegroundInactive fix first
```bash
bash RaBbLE-OS-dotctl.sh apply color-schemes kdeglobals
pkill -x dolphin; hyprctl dispatch exec dolphin
# CRITICAL: Take screenshot while terminal has focus (Dolphin = inactive state)
# ALSO: Take screenshot while Dolphin has focus (Dolphin = active state)
```

### Step 2: If still grey — add strace diagnostic
```bash
strace -e openat -f dolphin 2>&1 | grep -E "color|kde|config" | head -30
# Look for which .colors file KColorScheme actually opens
```

### Step 3: If KColorScheme ignores kdeglobals — try plasma-integration workaround
```bash
# Install plasma-integration package (if not installed)
# Set QT_QPA_PLATFORMTHEME=kde instead of qt6ct
# BUT: this may break qt6ct color scheme for non-label areas
# Investigate KColorSchemeManager::setTheme() programmatic approach
```

### Step 4: Nuclear option — patch QPalette at Hyprland startup
```bash
# In ~/.config/hypr/conf.d/env.conf, add:
# env = XCURSOR_THEME,Bibata-Modern-Classic
# env = QT_STYLE_OVERRIDE,breeze  ← forces breeze palette for labels
# This trades Kvantum frame styling for readable labels
```

## Key Files

| File | Purpose |
|---|---|
| `config/color-schemes/CatppuccinMochaMauve.colors` | KDE color scheme — must have unique `[General]` at top |
| `config/kdeglobals/kdeglobals` | `ColorScheme=` must match `Name=` in .colors file exactly |
| `config/qt6ct/qt6ct.conf` | `color_scheme_path=` → dark scheme for Qt palette |
| `config/qt6ct/colors/CatppuccinMochaMauve.conf` | Qt QPalette colors (21 roles) |
| `~/.config/hypr/conf.d/env.conf` | `QT_QPA_PLATFORMTHEME=qt6ct` — controls which path applies |
