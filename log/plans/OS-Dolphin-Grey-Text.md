# Plan: Dolphin Icon Labels Grey / Unreadable Text

**Status:** Two fixes applied, user reports text STILL not fixed on live display. May need logout/login for Kvantum reload. Commits: kdeglobals `8d8561a`, kvantum re-synced (no source change).
**Repo:** RaBbLE-OS `new-horizons` · **Last touched:** S164 (2026-06-24)

---

## Architecture: What We Now Know

Dolphin has at least THREE text rendering paths. Previous assumption (KColorScheme for labels) was WRONG.

| Path | Controls | Source | Verified? |
|---|---|---|---|
| **Qt QPalette via Kvantum** | Icon view labels, item text | `~/.config/Kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig` `[ItemView] text.normal.color` | Partial (pixel analysis showed improvement) |
| **Qt QPalette via qt6ct** | Toolbar, window decorations, menus | `~/.config/qt6ct/colors/CatppuccinMochaMauve.conf` | FIXED (S160) |
| **KColorScheme** (from kdeglobals) | Unknown — NOT icon labels (red-test proved) | `~/.config/kdeglobals [Colors:*]` | Controls something, unclear what |
| **Unknown sidebar path** | Places Panel item text | Unknown — bypasses Kvantum [ItemView] | NOT FIXED |

`QT_QPA_PLATFORMTHEME=qt6ct` + `QT_STYLE_OVERRIDE=kvantum` (set in `~/.config/hypr/conf.d/env.conf`).
- qt6ct = platform theme (QPalette provider)
- Kvantum = style engine (drawing/rendering, can override palette colors via [GeneralColors])
- **KColorScheme red-test confirmed: changes to ForegroundNormal in kdeglobals have NO visible effect on icon labels.** KColorScheme is NOT the icon label color source.

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

## What Was Found (S161 — 2026-06-24)

### Root Cause 1: Kvantum kvconfig out of sync (PRIMARY)

The deployed `~/.config/Kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig` was stale — it was missing `text.normal.color` in `[ItemView]` and used old Catppuccin palette colors instead of Aether. The source file (`config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig`) already had `text.normal.color=#f8f4ff` in `[ItemView]`.

**Fix:** `dotctl apply kvantum` (source was already correct — deploy was just stale).

**Verification:** Icon view labels jumped from ~0 bright grey pixels to 69,223 pixels at brightness 150+, rendering at #f8f4ff (Aether text).

### Root Cause 2: kdeglobals ForegroundInactive override (SECONDARY)

`config/kdeglobals/kdeglobals` had explicit `ForegroundInactive=147,153,178` in [Colors:Button/Tooltip/View/Window]. This OVERRIDES the value in the .colors file (#f8f4ff). KConfig cascade: kdeglobals inline values take precedence over .colors file values.

**Fix:** Changed `ForegroundInactive=147,153,178` → `205,214,244` in all 4 sections. Commit `8d8561a`.

### KColorScheme vs Qt QPalette

Icon view labels use **Qt QPalette via Kvantum** — NOT KColorScheme. This is why the previous "red-test on ForegroundNormal had no visible effect." KColorScheme (from kdeglobals) controls something, but NOT icon view labels under `QT_QPA_PLATFORMTHEME=qt6ct`.

## Remaining Issue: Sidebar Item Text

Dolphin Places Panel sidebar item labels ("Home", "Desktop", etc.) are still dim/invisible. Section headers ("Places", "Remote", "Recent", "Devices") render in #747679. The selected item shows the #ff2d78 highlight correctly.

Sidebar item text is not picking up `[ItemView] text.normal.color=#f8f4ff` from Kvantum. Likely the Places Panel uses a different delegate rendering path that bypasses the Kvantum ItemView styling. Candidates:
- KColorScheme::Link or KColorScheme::NormalText (still from kdeglobals)
- A QPalette role that Kvantum doesn't intercept for custom delegates

### Next Steps for Sidebar

1. Red-test: Change `disabled.text.color` in Kvantum kvconfig to #00ff00, deploy, restart Dolphin → if sidebar items turn green, disabled.text.color IS the culprit
2. Try `no_inactiveness=true` in Kvantum `[%General]` → disables inactive-state dimming effects
3. Check if `QT_QPA_PLATFORMTHEME=kde` (with plasma-integration) fixes the sidebar (but may break other things)

## Key Files

| File | Purpose |
|---|---|
| `RaBbLE-OS/config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig` | **PRIMARY** — Kvantum style engine; `[ItemView] text.normal.color` controls icon labels |
| `RaBbLE-OS/config/kvantum/RaBbLE-Aether/RaBbLE-Aether.svg` | Kvantum SVG assets (frames, backgrounds) |
| `RaBbLE-OS/config/kdeglobals/kdeglobals` | KDE global config; `ForegroundInactive` fixed (8d8561a) |
| `RaBbLE-OS/config/color-schemes/CatppuccinMochaMauve.colors` | KDE color scheme — controls KColorScheme (unknown what this affects) |
| `RaBbLE-OS/config/qt6ct/colors/CatppuccinMochaMauve.conf` | Qt QPalette 21-role dark scheme (toolbar, decorations) |
| `~/.config/hypr/conf.d/env.conf` | `QT_QPA_PLATFORMTHEME=qt6ct`, `QT_STYLE_OVERRIDE=kvantum` |

---

## Cold-Start Handoff (next agent picks up here)

**Problem:** Dolphin icon labels and sidebar item text ("Home", "Desktop", etc.) appear grey/unreadable on the dark Aether void background. After S164 fixes, user confirms text is STILL not fixed on live display.

**What was already tried and committed:**
- `dotctl apply kvantum` — re-synced deployed Kvantum kvconfig to source (source had `text.normal.color=#f8f4ff` in `[ItemView]`). Pixel analysis showed 69k bright pixels post-fix (icon view area). But Kvantum style reloads may require **logout/login** to take full effect.
- kdeglobals `ForegroundInactive` bumped to `205,214,244` in all `[Colors:*]` sections (commit `8d8561a`).

**Step 0 — FIRST: logout/login to flush Kvantum style cache**
Kvantum loads the style engine at session start. `pkill dolphin && dolphin` restarts the app but the Kvantum style engine may be cached in the running Qt session. A full Hyprland logout/login forces reload.
```bash
# After login: open fresh Dolphin and screenshot
hyprctl dispatch exec dolphin
sleep 3
# Take fresh screenshot and inspect
```

**Step 1 — If icon labels still grey after logout: Kvantum `[ItemView]` red-test**
```bash
# Edit source file: add text.normal.color=#ff0000 to [ItemView]
vim RaBbLE-OS/config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig
# In [ItemView] section, set:
# text.normal.color=#ff0000
bash RaBbLE-OS-dotctl.sh apply kvantum
pkill -x dolphin; hyprctl dispatch exec dolphin
# Screenshot: if icon labels turn red → Kvantum [ItemView] IS the control path
# If nothing turns red → Kvantum [ItemView] is not the path; move to Step 3
```

**Step 2 — If icon labels ARE red: restore and tune Kvantum**
The text.normal.color is working but something else is overriding in normal use.
```bash
# Check [GeneralColors] disabled.text.color=#8860aa — might be applied to non-focused items
# Try: no_inactiveness=true in [%General] to disable inactive-state dimming
# Then set disabled.text.color=#f8f4ff (or #cdd6f4 for Catppuccin) as safety net
```

**Step 3 — If icon labels NOT red (Kvantum [ItemView] bypassed): identify actual path**
```bash
sudo dnf install strace -y
strace -e openat -f dolphin 2>&1 | grep -E "\.colors|kdeglobals|kvantum|qt6ct" | head -40
# Look for what config files Dolphin reads at startup
# Also check: QT_DEBUG_PLUGINS=1 dolphin 2>&1 | head -40
```

**Step 4 — Sidebar item text (separate from icon labels):**
The Places Panel sidebar uses a custom delegate. Even if icon labels are fixed, sidebar items may still use:
- `QPalette::WindowText` from the inactive color group
- Or KDE's `KColorScheme::Link` role (places items are bookmarks/links)
```bash
# Red-test: change disabled.text.color and link.color to #00ff00 in Kvantum kvconfig
# If sidebar items turn green → that's the path
# Also try: in kdeglobals [Colors:View] set ForegroundLink=0,255,0 → if green → KColorScheme controls sidebar
```

**Environment constants to keep in mind:**
- Display: 3840×2400 physical (1920×1200 logical), scale=2
- grim full-screen gives 3840×2400; Dolphin at logical (510,327) 900×580 → physical crop (1020,654) 1800×1160
- Kvantum: `~/.config/Kvantum/RaBbLE-Aether/`
- dotctl: `cd RaBbLE-OS && bash RaBbLE-OS-dotctl.sh apply kvantum`
- Screenshot workflow: `grim /tmp/fs.png` → python PIL crop → inspect with PIL pixel sampling
