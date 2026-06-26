# Source of Truth: Dolphin File Manager Theming — RaBbLE-OS

> **Consolidated 2026-06-25 (S175-prep).**
> All prior session drafts, handoff notes, and plan fragments integrated here.
> This is the single file a fresh agent reads to understand the full history of this issue
> and decide the next correct action — without repeating prior mistakes.

**Repo:** RaBbLE-OS `new-horizons`
**Implement as:** Sonnet (well-scoped, deterministic after palette dump step)

---

## Executive Summary

Dolphin icon-view labels and Places sidebar items render dim grey (≈`#656769`) regardless of
window focus. **Seven dedicated sessions across six weeks have not permanently fixed it.**
The correct fix is now well-scoped: dump the live `QApplication.palette()` via PyQt6 to
confirm which palette group/role Dolphin's `KItemListView` actually reads, then set that
group's color value in Kvantum `[GeneralColors]` (the confirmed live palette source).
DO NOT re-edit kdeglobals, qt6ct color files, or KColorScheme files — they are all inert
under the current `qt6ct custom_palette=false` configuration.

---

## The Stack — What Controls What

Understanding this is the entire game. Six sessions were lost editing inert layers.

```
Dolphin icon label rendering path (confirmed S167 via upstream sources):

  QApplication.palette()                  ← THE ACTUAL COLOR SOURCE
       │
       │  populated by
       ▼
  Kvantum [GeneralColors]                 ← LIVE — this is the only lever that matters
    text.color              = #f8f4ff     (Active group — Normal text)
    window.text.color       = #f8f4ff
    disabled.text.color     = #8860aa    (Disabled group — ⚠️ DIM, likely root cause)
    inactive.highlight.color = #8860aa
       │
       │  Dolphin KItemListView selects palette group:
       │   → Reads QPalette(Inactive, Text) or QPalette(Disabled, Text)
       │   → WHICH group is used by which widget is unknown until palette dump
       ▼
  Labels render at the color of that group's Text role

INERT LAYERS (editing these has zero visible effect with current qt6ct config):

  qt6ct color file           ← INERT: qt6ct.conf has custom_palette=false
  config/kdeglobals          ← INERT: KDE palettes are ignored by Qt when using Kvantum
  KColorScheme .colors file  ← INERT for icon labels (KColorScheme is a different system)
  kdeglobals [Colors:View]   ← INERT for Qt QPalette text roles (S126 green-test confirmed)
```

**Why kdeglobals + qt6ct are inert (confirmed S167 vs upstream):**
`qt6ct.conf` has `custom_palette=false` → `color_scheme_path` is NOT applied → the entire
Qt palette comes from Kvantum `[GeneralColors]` alone. Every prior session that edited
kdeglobals, CatppuccinMochaMauve.colors, or the qt6ct color conf was editing dead files.

**Sources:** Arch BBS "QT Apps completely ignore the theme"; hyprdots PR #2058;
catppuccin/nix #275; tsujan/Kvantum discussion #911.

---

## What Causes the Dimming (Current Understanding)

Two mechanisms may be in play — the palette dump will distinguish them:

**Mechanism A — Palette group selection:**
Dolphin's `KStandardItemListWidget` selects `QPalette::Inactive` when `!isActiveWindow()`.
Kvantum populates `Inactive` group dimmed (inherits from `Active` then dims).
A known **Wayland activeness-detection bug** (`tsujan/Kvantum#911`) causes Kvantum to
misidentify focus under Hyprland → windows stay stuck in `Inactive` even when actually focused.
`no_inactiveness=true` was designed to fix this by suppressing inactive rendering — but the
live test DISPROVED that this is the sole mechanism (labels were dim even while actively focused
on a freshly rebooted machine).

**Mechanism B — Disabled text color:**
`[GeneralColors] disabled.text.color=#8860aa` is set to a dim purple.
If Dolphin's `KItemListView` reads `QPalette(Disabled, Text)` for icon labels (possibly for
"not-selected" items), then `#8860aa` would produce the dim labels regardless of focus state.
This hypothesis was NOT properly tested: the S126 green-test that ruled out `disabled.text.color`
was run when the kvconfig was stale and not properly deployed — the test may be invalid.

**Resolution:** Only a live palette dump (PyQt6) will confirm which group/role Dolphin reads.
This is the required first step. DO NOT skip it.

---

## Session Investigation Log

Chronological record of every session that touched Dolphin theming.

### S85 (2026-06-11) — Initial Kvantum + GTK theming

**What was done:**
- Created `RaBbLE-Aether` kvconfig from scratch + simplified SVG
- Set `qt5ct.conf` / `qt6ct.conf` to `style=kvantum`
- Added `QT_QPA_PLATFORMTHEME=qt6ct` + `QT_STYLE_OVERRIDE=kvantum` to env.conf
- Added Kvantum packages to manifest.yml

**Outcome:** System was unstable (system lag); session incomplete. Theming foundation laid.
**Lesson:** Qt env vars + Kvantum are the right stack. SQLite base wasn't wrong, just incomplete.

---

### S116 (2026-06-15 to 2026-06-19) — First dedicated theming pass

**What was done:**
- Rebuilt Kvantum theme from MIT Catppuccin/kvantum base (replaced KvArcDark)
- Recolored palette: void bg, `#f8f4ff` text, magenta+cyan accents
- Dolphin text set → near-white `#f8f4ff` in `[GeneralColors]` + `[ItemView]`
- Several `text.normal.color=#8860aa` instances brightened to `#f8f4ff`:
  `[HeaderSection]`, `[TitleBar]`, `[Tab]`
- 6 new dotctl bundles: `kvantum qt5ct qt6ct gtk3 gtk4 themes`
- Focus gradient border added (wired to `common-focused-left` rect)

**Outcome:** User reported text STILL grey at session end.
**Why it failed:** Two causes identified in handoff:
  (a) Kvantum has no hot-reload — must fully restart Qt apps (user likely saw stale Dolphin)
  (b) Several roles still used muted `#8860aa` (HeaderSection/TitleBar/Tab)
  (c) The gradient border was never visually confirmed (Dolphin kept exiting — must use
      `hyprctl dispatch exec dolphin`, not `dolphin &` which dies with the shell)
**Commit:** `a4e2b38` (Aether), RaBbLE-OS `new-horizons`

---

### S126 (2026-06-19) — Root cause discovery: kdeglobals + green-tests

**What was done:**
- Identified: KDE apps (Dolphin, Kate) take text color from `~/.config/kdeglobals`,
  NOT Kvantum — Kvantum only styles widget *frames*, not KDE palette text.
- No kdeglobals present → KDE forces Breeze grey (`#959595`) over whole view.
- Created `config/kdeglobals/kdeglobals` + dotctl bundle. Built from Aether palette.
- Confirmed with grim pixel sampling: `#959595 → themed` post-deploy.
- Brightened chrome: Tab/HeaderSection/TitleBar `#8860aa → #f8f4ff`

**Green-tests (decisive):**
1. Set kdeglobals `[Colors:View] ForegroundNormal = #00ff00` → **no label turned green**
2. Set Kvantum `[GeneralColors] disabled.text.color = #00ff00` → **no dim label turned green**

**Outcome:** Most labels improved. A subset of dim-purple `~#8860aa` labels remained
(non-hidden folders with bright/custom icons: RaBbLE-Collective, Downloads, Jobotron3000,
Dropbox, FreelanceWebDev, GCS). Hidden dotfiles read bright.
**Hypothesis:** Cached KColorScheme palette — needs logout/login to flush.
**Commit:** `b3cd052`

**⚠️ Green-test caveat (discovered S167):** At S126, the kvconfig deployed to `~/.config/`
may have been STALE (pre-S116 deploy issues). The `disabled.text.color` green-test result
may be invalid because Kvantum wasn't reading the correct file. This is unresolved.

---

### S140 (approximate) — Roadmap note

**What was done:** Session notes captured: *"Dolphin needs a deterministic kdeglobals plan,
not trial-and-error"*. Bucketed into Roadmap → Backlog Triage.
**Key quote from Roadmap:** "Current loop is too trial-and-error (major token spend, little
success). NEXT STEP: write a deterministic kdeglobals-driven theming plan."
**Nothing changed in configs.**

---

### S159 (2026-06-23) — Color-scheme bundle fix

**What was done:**
- Discovered: `color-schemes` dotctl bundle had NEVER been pushed → `~/.local/share/color-schemes/`
  was empty. KDE was reading stale `/usr/share/color-schemes/RaBbLE-Aether.colors` from an
  old Ansible run, causing palette drift.
- Created `config/color-schemes/CatppuccinMochaMauve.colors` (MIT upstream)
- Updated kdeglobals to point at it; deployed both via `dotctl apply color-schemes kdeglobals`
- **Commit:** `444b44d`

**Outcome:** Next step was Mark relog → verify. No confirmation that labels became readable.
**Lesson:** Even if the color-schemes bundle is now deployed, this layer is inert for Qt
icon-label colors (see S167 research). The fix was correct for KDE system-level theming,
but it doesn't reach Qt QPalette text rendered by Kvantum.

---

### S160 (2026-06-23) — Two-layer diagnosis

**What was done:**
- Identified two separate problem layers:

  **Layer 1 (qt6ct QPalette):** `QT_QPA_PLATFORMTHEME=qt6ct` with empty `color_scheme_path`
  was causing Qt to use a light palette. Fix: created `config/qt6ct/colors/CatppuccinMochaMauve.conf`
  + `config/qt5ct/` equivalents, set `color_scheme_path` in qt6ct.conf/qt5ct.conf.

  **Layer 2 (KColorScheme icon labels):** `.colors` file was missing `[General]` section entirely
  → KF6 KColorScheme fell back to Breeze grey. Also: duplicate `[General]` at line 135
  (kdeglobals contamination) with KConfig last-value-wins. Fixed both in
  `config/color-schemes/CatppuccinMochaMauve.colors`. Bumped `ForegroundInactive → 205,214,244`
  (matches ForegroundNormal) so labels readable when Dolphin unfocused (no Plasma = always inactive).
  Fixed: `ColorScheme=CatppuccinMochaMauve` → `ColorScheme=Catppuccin Mocha Mauve` (with spaces).

- **Commits:** `d8f3314` (Plymouth + qt6ct baseline), `f1ebf19` (.colors cleanup + ForegroundInactive)

**Still unverified at session end:** Whether KF6 KColorScheme without plasma-integration reads
from kdeglobals `[Colors:*]` directly. Red-test on ForegroundNormal showed no effect.
**Outcome:** Both fixes committed, neither verified live on Dolphin.
**Lesson (S167 update):** Layer 1 fix (qt6ct color file) is inert because `custom_palette=false`
still ignores the color_scheme_path. The entire Qt palette comes from Kvantum, not qt6ct.

---

### S164 (2026-06-24) — Deep investigation with pixel sampling

**What was done:**
- Pixel-sampled grim screenshots at 2× HiDPI scale (physical = logical × 2)
- Red-test: Changed `ForegroundNormal` in KColorScheme to red → **NO visible effect on icon labels**
  → Confirmed: icon labels use Qt QPalette via Kvantum, NOT KColorScheme
- **Fix 1 (Kvantum sync):** Deployed kvconfig was STALE vs source file — missing
  `text.normal.color=#f8f4ff` in `[ItemView]` and had old Catppuccin palette.
  `dotctl apply kvantum` re-synced. Pixel analysis showed 69k bright pixels post-fix (icon view area).
- **Fix 2 (kdeglobals):** `[Colors:View/Button/Tooltip/Window] ForegroundInactive=147,153,178`
  was overriding .colors file value via KConfig cascade. Changed → `205,214,244`. Commit `8d8561a`
- **Sidebar discovery:** Places Panel item text ("Home", "Desktop", etc.) renders invisible
  (near-background color). Section headers (`#747679`) and selected item (`#ff2d78`) visible.
  Sidebar delegate bypasses Kvantum `[ItemView]` styling → different fix path needed.
- **User confirmed:** Text still not fixed on live display. Kvantum may need logout/login.

**Lesson:** KColorScheme is entirely separate from Qt QPalette for icon labels.
**Lesson:** Kvantum kvconfig can silently drift from source — always verify deployed vs source.

---

### S167 (2026-06-24) — no_inactiveness hypothesis DISPROVEN live

**What was done:**
- **Research (confirmed vs upstream):**
  - `qt6ct custom_palette=false` → `color_scheme_path` NOT applied → qt6ct color file AND
    kdeglobals are **INERT** → Kvantum `[GeneralColors]` is the SOLE Qt palette source
  - Kvantum is the only Qt style that dims inactive windows (`no_inactiveness=false` by default)
  - Wayland activeness-detection bug: `tsujan/Kvantum#911`
  - Upstream `lxqt/pcmanfm-qt#560` matches the icon-label symptom exactly
- **Applied candidate fix:** `no_inactiveness=false → true`, `reduce_window_opacity=10 → 0`
  in `config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig`. Deployed via dotctl.

**DISPROVEN by live measurement:**
- Machine rebooted (fresh config load; deployed file confirmed `no_inactiveness=true`)
- Dolphin captured while **actively focused** (Hyprland active border present; `activewindow=dolphin`)
- Labels STILL dim, sampled ≈ **#656769 (101,103,105)** — a dim neutral grey
- Active window would be bright if inactive-dimming were the mechanism → focus state is NOT it

**Harness caveat that bit S167 twice:**
- Dolphin and VSCodium were floating/overlapping
- `alterzorder top` did NOT reliably raise Dolphin → several captures measured VSCodium, not Dolphin
- ONLY trustworthy capture: the actively-focused Dolphin one
- **Rule:** Use the TILED, NON-OVERLAPPING harness. Do not trust `alterzorder` on floating windows.

**State left:** `no_inactiveness=true` and `reduce_window_opacity=0` applied to source file and
deployed. Retained as sane tiling-WM defaults (Hyprland owns window dimming; Kvantum must not
double-dim). NOT committed as a "fix" — committed honestly. Plan doc updated with disproof.

**New leading hypothesis:**
`KItemListView` reads `QPalette(group, Text)` and `group` resolves to `Inactive` or `Disabled`
even when the window is focused (Wayland bug); Kvantum populates those groups dimmed;
`no_inactiveness` changes *rendering*, not the palette group *color values*.
→ Need: either set `disabled.text.color` bright, or enable `qt6ct custom_palette=true` with
bright inactive/disabled colors, or dump the palette to see exactly which group is used.

---

## Master: What Has Been Tried and Ruled Out

| Approach | Session | Result | Evidence |
|---|---|---|---|
| KvArcDark-based kvconfig (grey SVG) | S85 | Incomplete | Session abandoned |
| Edit `[ItemView] text.normal.color` in kvconfig | S116 | No visible effect | qt6ct `custom_palette=false` makes Kvantum the palette source, but the kvconfig was stale |
| Edit `[HeaderSection]`/`[TitleBar]`/`[Tab]` text color | S116 | Partial | Chrome text improved; icon labels not these sections |
| Add kdeglobals bundle (missing entirely) | S126 | Improved baseline | Most `#959595` Breeze grey fixed; subset still dim |
| kdeglobals `[Colors:View] ForegroundNormal = #00ff00` | S126 | **No label turned green** | kdeglobals `[Colors:View]` does NOT control icon-label text |
| Kvantum `[GeneralColors] disabled.text.color = #00ff00` | S126 | **No dim label turned green** | ⚠️ CAVEAT: kvconfig may have been stale at test time — result may be invalid |
| Deploy color-schemes bundle (was never deployed) | S159 | Fixes KDE system theme, not Qt labels | Bundle deployment was correct; doesn't reach Kvantum QPalette |
| qt6ct `color_scheme_path` + color conf file | S160 | Inert | `custom_palette=false` makes this a no-op |
| Fix `.colors [General]` section (was missing) | S160 | Fixes KColorScheme system; not Qt labels | KColorScheme and Qt QPalette are separate systems |
| Bump `.colors ForegroundInactive` → `205,214,244` | S160 | Unverified on icon labels | KColorScheme doesn't reach Qt QPalette under Kvantum |
| Fix `ColorScheme=CatppuccinMochaMauve` → with spaces | S160 | Fixed KDE recognizing scheme | Cosmetic/systemic fix; doesn't reach Qt QPalette |
| KColorScheme ForegroundNormal red-test | S164 | **No label turned red** | Confirmed: KColorScheme is inert for icon labels |
| Re-sync stale kvconfig to source | S164 | Partial improvement (69k bright pixels) | Deploying correct kvconfig helps, but labels still dim |
| kdeglobals `ForegroundInactive` `147→205,214,244` | S164 | Unverified effect on labels | kdeglobals is inert per S167 research |
| `no_inactiveness=true` (stop inactive dimming) | S167 | **DISPROVEN live** | Labels dim even when window actively focused |
| `reduce_window_opacity=0` (stop Kvantum window fade) | S167 | Retained as sane default | Not the fix; correctly hands window dimming to Hyprland |

---

## Current Config State (as of S167)

### `RaBbLE-OS/config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig`

Key values **deployed to live system** (verify with grep):
```ini
[%General]
no_inactiveness=true        # applied S167 — NOT the fix, but sane default (keep)
reduce_window_opacity=0     # applied S167 — sane default, lets Hyprland own window dimming

[GeneralColors]
text.color=#f8f4ff                  # Active group text
window.text.color=#f8f4ff
disabled.text.color=#8860aa         # ⚠️ Disabled group text — DIM PURPLE — likely root cause
inactive.highlight.color=#8860aa    # ⚠️ Inactive highlight — dim

[ItemView]
text.normal.color=#f8f4ff   # This is set correctly but QPalette group selection overrides it
```

### `RaBbLE-OS/config/kdeglobals/kdeglobals`

Catppuccin Mocha Mauve baseline. Currently **INERT for Qt QPalette** because `qt6ct
custom_palette=false`. KDE system theming reads it correctly; Kvantum/Dolphin does not.

```ini
[Colors:View]
ForegroundNormal=205,214,244    # Catppuccin off-white — not Aether but readable
ForegroundInactive=205,214,244  # Matches Normal (bumped S164)
```

### `RaBbLE-OS/config/qt6ct/qt6ct.conf`

```ini
[Appearance]
custom_palette=false        # ← This single flag makes color_scheme_path irrelevant
color_scheme_path=...       # INERT
style=kvantum
```

### `~/.local/share/color-schemes/CatppuccinMochaMauve.colors`

Deployed and readable by KDE system. **Not consulted by Qt for QPalette text colors.**

---

## Open Questions and Contradictions

**Contradiction 1 — The S126 green-test invalidation:**
S126 ruled out `disabled.text.color` via green-test (no labels turned green).
S167 confirmed Kvantum `[GeneralColors]` is the SOLE Qt palette source.
If `disabled.text.color` is in `[GeneralColors]` AND Kvantum is the only palette source,
why didn't the green-test work? Possible explanations:
- The kvconfig deployed at S126 was STALE (missing S116's edits) → Kvantum read the wrong file
- The test was done without a full Dolphin restart (hot-reload doesn't exist)
- `disabled.text.color` controls something other than icon label text (different widget type)
**Resolution:** This exact question is why the palette dump is required.

**Contradiction 2 — `no_inactiveness` disproof vs group hypothesis:**
If labels are dim even when window is actively focused, and `no_inactiveness` doesn't fix it,
then the dim source is not "Kvantum dims the Inactive *rendering*" — it's "the Inactive/Disabled
*color values* themselves are dim." The `no_inactiveness=true` change correctly removes inactive
rendering but doesn't change the underlying palette color for those groups.
This points squarely to: set `disabled.text.color` and/or `inactive` palette group colors to bright.

**Contradiction 3 — Sidebar vs icon view:**
Icon view labels and Places sidebar items both dim, but the sidebar delegate "bypasses Kvantum
[ItemView] styling" (S164). If they both respond to the same fix (or don't), the fix is at the
QPalette group level (shared). If they require different fixes, the sidebar is a separate problem.
The palette dump will clarify because it shows ALL roles for ALL groups.

---

## Fix Paths (Ordered — Least Invasive First)

### Step 0 (REQUIRED FIRST): Palette dump to end all guessing

```bash
# Install PyQt6 (add to manifest first)
sudo dnf install python3-pyqt6

# Dump all palette groups × roles from a live Dolphin
python3 - << 'EOF'
import sys
from PyQt6.QtWidgets import QApplication
app = QApplication(sys.argv)
palette = app.palette()
groups = {
    'Active': 2,     # QPalette.ColorGroup.Active
    'Inactive': 1,   # QPalette.ColorGroup.Inactive
    'Disabled': 0,   # QPalette.ColorGroup.Disabled
}
roles = ['WindowText', 'Button', 'Light', 'Midlight', 'Dark', 'Mid', 'Text',
         'BrightText', 'ButtonText', 'Base', 'Window', 'Shadow', 'Highlight',
         'HighlightedText', 'Link', 'LinkVisited', 'AlternateBase', 'ToolTipBase', 'ToolTipText']
for gname, gval in groups.items():
    for rname in roles:
        role = getattr(palette.ColorRole, rname, None)
        if role is not None:
            color = palette.color(gval, role)
            print(f"{gname:10} {rname:20} #{color.red():02x}{color.green():02x}{color.blue():02x}")
EOF
```

**What to look for:** Find `Text` role in `Inactive` and `Disabled` groups.
If they show `#8860aa` or similar dim value → that's the exact lever to fix.
If they show `#f8f4ff` → the issue is rendering/compositing, not the palette value.

> Note: This runs against the system-level Qt app, not inside Dolphin. Run it with the same
> Kvantum theme active (same user session) for accurate results. The actual Dolphin palette
> would require running this code inside a Dolphin plugin — for now, system-level is close enough.

---

### Fix Path A — Brighten Kvantum disabled/inactive group colors (most likely fix)

**When to use:** Palette dump shows `Text` in `Inactive` or `Disabled` group is dim (`#8860aa` or similar).

**File:** `RaBbLE-OS/config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig`

```ini
[GeneralColors]
; Current (dim):
disabled.text.color=#8860aa
inactive.highlight.color=#8860aa

; Change to (bright, Aether-compliant):
disabled.text.color=#bf5fff    ; Soft Violet — readable, subdued vs active text
; OR for full brightness:
disabled.text.color=#f8f4ff

; If inactive group Text role is also dim, these [GeneralColors] keys control it:
; window.text.color, text.color are already #f8f4ff — if those feed Inactive group,
; they should be fine. But if Kvantum has a separate inactive text path, look for:
; inactive.text.color (if it exists in your Kvantum version)
```

**Deploy:**
```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
# Edit config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig
bash RaBbLE-OS-dotctl.sh apply kvantum
# Fully restart Dolphin (no hot-reload):
pkill -x dolphin
hyprctl dispatch exec dolphin
```

**Commit palette ref:** `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md` — only use values from there.
`#bf5fff` = Soft Violet (tertiary). `#f8f4ff` = Primary Text. Never invent hex.

---

### Fix Path B — qt6ct `custom_palette=true` (direct palette override)

**When to use:** If Fix Path A doesn't work, OR if the palette dump shows the dim color
is being injected somewhere Kvantum `[GeneralColors]` doesn't control.

**Mechanism:** Enabling `custom_palette=true` lets qt6ct's color file override specific
palette roles directly, bypassing Kvantum's palette population for those roles.

**File:** `RaBbLE-OS/config/qt6ct/qt6ct.conf`
```ini
[Appearance]
custom_palette=true     ; Changed from false
color_scheme_path=/home/rabble/.config/qt6ct/colors/CatppuccinMochaMauve.conf
```

**Then edit the color conf** to set `inactive_colors` and `disabled_colors` Text role to bright:
`RaBbLE-OS/config/qt6ct/colors/CatppuccinMochaMauve.conf`
```ini
; Find and set these roles in the [inactive_colors] and [disabled_colors] sections:
; WindowText = 248, 244, 255     ; #f8f4ff
; Text = 248, 244, 255
; BrightText = 248, 244, 255
```

**⚠️ Risk:** Enabling `custom_palette=true` gives qt6ct total control over the palette,
potentially overriding Kvantum's accent colors and backgrounds. Test all Qt surfaces after
applying (menus, dialogs, buttons) — not just Dolphin.

---

### Fix Path C — KDE color scheme aligned to Aether (deferred / secondary)

The kdeglobals and `.colors` files are currently Catppuccin-based (clean dark baseline, not
Aether). This is fine for now — these files are inert for Qt QPalette under the current stack.
BUT post-fix, when the Qt labels are readable, there's cleanup work:

**Deferred task:** Reconcile kdeglobals + color-scheme + qt6ct color file to Aether values
so there's a single source of truth. Today Kvantum uses Aether `#f8f4ff`/void while those
files carry leftover Catppuccin `#cdd6f4`/`#1e1e2e`. Not urgent (they're inert), but it's
technical debt. Log in RaBbLE-OS Roadmap / KnownIssues when the main fix lands.

---

## Verification Harness (Anti-False-Positive)

Prior failures happened because of contaminated captures. Use this exact procedure.

**Environment constants:** Display scale=2 (physical = logical×2). `grim` full = 3840×2400.
A Dolphin **restart reloads Kvantum** — NO logout needed (each process re-reads kvconfig at
launch). The "needs logout" belief from earlier sessions was a symptom of editing inert files.

**Tiled harness (DO NOT use floating/overlapping windows):**

1. Open ONE empty workspace. Launch Dolphin + a terminal tiled side-by-side.
   **No overlap. No z-order ambiguity.**
2. **Focus the terminal** → Dolphin is inactive but fully visible.
   Confirm with `hyprctl activewindow -j` (class must NOT be `dolphin`).
   Get Dolphin geometry: `hyprctl clients -j | python3 -c "import json,sys; [print(c['at'],c['size']) for c in json.load(sys.stdin) if 'dolphin' in c.get('class','').lower()]"`
3. `grim /tmp/dolphin-test.png` → crop to Dolphin region (logical coords × 2 = physical).
   Sample text-pixel luminance in the icon-label band and the sidebar column.
4. **Focus Dolphin** → repeat capture for the active-window state.
5. **Pass criteria (both states should pass):**
   - Icon-label text luminance ≈ `#f8f4ff` or at minimum visibly readable (~200+ on each channel)
   - Places sidebar items ("Home", "Desktop", etc.) readable (not near-background)
   - Section headers (`Places`, `Devices`) subdued-but-visible — `#6b6880` or brighter
   - Selected item shows `#ff2d78` magenta highlight
   - Hyprland's whole-window inactive fade still visible (compositor dimming preserved — this is correct)
6. **Save before/after crops.** Read them back visually — don't trust pixel counts alone.

**What to record:** Before sample (current dim): ≈`#656769`. After sample (target): ≈`#f8f4ff` or `#bf5fff`.

---

## Sidebar Specifics

The Places sidebar "Home", "Desktop", etc. text rendered invisible (near-background) at S164.
Section headers (`#747679`) and selected item (`#ff2d78`) were visible. Sidebar delegate
"bypasses Kvantum [ItemView] styling" — it uses a DIFFERENT rendering path.

**Hypothesis:** Sidebar items may be rendered via `QPalette(Active/Inactive, WindowText)` not
`Text`. The palette dump will show these values. If `WindowText` is bright in all groups, sidebar
items may auto-fix when icon labels are fixed. If not, a separate Kvantum key targets it:

```ini
[GeneralColors]
window.text.color=#f8f4ff   ; Already set bright in current config
```

If sidebar items remain invisible after the main fix, check `[GeneralColors] window.text.color`
is deployed correctly on the live system.

---

## Wrap-Up (When Fixed)

1. Update this doc: mark **RESOLVED**, record which Fix Path worked, record palette dump output.
2. **Commit (Pulse Protocol):**
   ```
   mend ~ os >> dolphin text legible: <fix description> // %DOLPHIN_TEXT_FIXED%
   ```
   Active branch: `RaBbLE-OS-New-Horizons`. Do NOT merge to main — episode-gated.
3. `bash ../RaBbLE-Grimoire/spells/end-session.sh dolphin-text "<note>"`
4. Update `fix/RaBbLE-OS-KnownIssues.md` — mark Dolphin theme-polish as RESOLVED
5. Log the palette dump output in `log/lessons/` via `promote-insight.sh`
6. Schedule deferred Aether palette reconciliation (Fix Path C) as a future Roadmap item

---

## Key Files Reference

| File | Role | Status |
|---|---|---|
| `RaBbLE-OS/config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig` | **THE LIVE PALETTE SOURCE** — `[GeneralColors]` controls all Qt text colors | Live on system; `no_inactiveness=true` applied S167 |
| `RaBbLE-OS/config/qt6ct/qt6ct.conf` | `custom_palette=false` — the reason kdeglobals/qt6ct colors are inert | Do not change unless pursuing Fix Path B |
| `RaBbLE-OS/config/kdeglobals/kdeglobals` | KDE system theming (Dolphin window title, etc.) — INERT for Qt QPalette | Catppuccin baseline; correct but not the fix lever |
| `RaBbLE-OS/config/color-schemes/CatppuccinMochaMauve.colors` | KColorScheme — INERT for Qt icon label text | Correctly deployed S159; not the fix lever |
| `~/.config/hypr/conf.d/look.conf` + `windowrules.conf` | Hyprland compositor inactive opacity — KEEP, owns window-level dimming | Correct; Dolphin gets `opacity 0.97 0.95` |
| `RaBbLE-OS-dotctl.sh apply kvantum` | How to deploy kvconfig changes | Always use this — never edit `~/.config` directly |
| `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md` | Canonical hex values | Required reading before changing any color value |

---

## Historical Approach Summary (For Posterity)

```
Sessions   Approach tried                    Why failed
─────────────────────────────────────────────────────────────────────────────
S85        Kvantum theme scaffolding         Session abandoned (system lag)
S116       Kvantum text colors, focus arc    Kvconfig stale; no Dolphin restart
S126       kdeglobals bundle                 Fixed #959595 baseline; subset still dim
S126       green-test: kdeglobals FgNormal   RULED OUT (no effect)
S126       green-test: disabled.text.color   POSSIBLY INVALID (stale kvconfig)
S140       Roadmap plan note                 No config change
S159       color-schemes bundle deploy       Layer is inert for Qt QPalette
S160       qt6ct color file + FgInactive     custom_palette=false makes both inert
S164       KColorScheme red-test             RULED OUT (no effect on labels)
S164       Kvantum kvconfig re-sync          Partial improvement (chrome improved)
S164       kdeglobals FgInactive bump        Inert layer
S167       no_inactiveness=true              DISPROVEN LIVE (labels dim even focused)
```

**The unifying cause of every failure:** Editing inert layers without first knowing which layer
Dolphin's `KItemListView` actually reads. The palette dump ends this. Do that first.
