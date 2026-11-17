# RaBbLE-OS — Boot Chain Layout Reference

> Manual tuning guide for SDDM, Plymouth, and GRUB theme positioning.
> All three share the same Liminal BG. Measure the void zone first — everything else follows.

---

## Shared Background Geometry

All three stages use the same source image: **`RaBbLE-BaBbLE/RaBbLE_boot_Liminal_BG.png`**
(1920×1200 RGBA). Each stage converts it:

| Stage | File | Size | Notes |
|---|---|---|---|
| GRUB | `grub2/files/theme/grub-bg.png` | 1920×1200 RGB | 24bpp, no alpha |
| Plymouth | `plymouth/files/rabble-aether/assets/bg-liminal.png` | 1920×1200 RGBA | compositing-ready |
| SDDM | `session_manager/files/sddm-theme/assets/bg.png` | 1920×1200 RGB | `PreserveAspectCrop` in QML |

### Void Zone (pixel-measured, S167)

The Liminal BG has a cyan ceiling grid (top), a pure-black void (middle), and a magenta
floor grid (bottom). **All content must sit in the void.**

| Boundary | Image % | Screen % (1080p, 60 px crop) | Screen % (1600p, no crop) |
|---|---|---|---|
| Ceiling grid ends | ~40 % | ~40 % | ~41 % |
| **Void start** | **41 %** | **40 %** | **41 %** |
| **Void end** | **66 %** | **68 %** | **66 %** |
| Floor grid starts | ~67 % | ~68 % | ~67 % |

**Rule of thumb:** target content between **42 %–65 %** for safe margins on any display.

### Remeasure after any bg.png change

```bash
# Plymouth — dedicated script already exists:
cd RaBbLE-OS/ansible/roles/boot/plymouth/files/rabble-aether
python3 measure-void-zone.py                        # uses assets/bg-liminal.png
python3 measure-void-zone.py /path/to/other-bg.png  # custom path

# SDDM — same logic, point at sddm assets/bg.png:
python3 measure-void-zone.py \
  ../../session_manager/files/sddm-theme/assets/bg.png
```

---

## SDDM — `session_manager/files/sddm-theme/`

SDDM uses QML with `parent.height`-relative anchors. All values are percentages of
the live screen height — they adapt to any resolution automatically.

### File structure

```
sddm-theme/
├── Main.qml          # root + palette + layout knobs + state + top-level assembly
├── EntityDisplay.qml # animated entity sprite + cyan glow (self-contained)
├── LoginForm.qml     # username display + passphrase field + error reaction
├── metadata.desktop  # theme registration
└── assets/           # bg.png, entity-idle-*.png, fonts/
```

**Main.qml** owns the layout. It sets all anchors and passes palette values down.
**EntityDisplay** and **LoginForm** know nothing about each other or screen geometry.

### Layout knobs

`Main.qml` has a `// ── Layout knobs ──` block near the top with four named properties.
**Edit only these four values** to reposition elements — don't touch the `anchors` further down.

```qml
// Safe content zone for Liminal BG: 0.42 – 0.65 (void between grids).
readonly property real  lClockTop:   0.10    // clock topMargin from topBar as fraction of screen h
readonly property int   lEntitySize: 520     // entity frame px (glow scales with it)
readonly property real  lEntityV:   -0.04    // entity vertical offset from center (negative = up)
readonly property real  lFormTop:    0.57    // login form top edge as fraction of screen h
```

| Knob | Meaning | Safe range |
|---|---|---|
| `lClockTop` | Clock distance below topBar | 0.06 – 0.14 |
| `lEntitySize` | Entity frame size in px | 400 – 600 |
| `lEntityV` | Entity center offset (neg=up) | −0.08 – +0.06 |
| `lFormTop` | Login form top (username starts here) | 0.50 – 0.65 |

#### Moving the password box upward

The password box sits ~110 px below `lFormTop` (username 54 px + 16 px gap + spacer). To shift
the whole form up, decrease `lFormTop`:

```qml
readonly property real  lFormTop:    0.54   // was 0.57 — moves form ~32 px up on 1080p
```

To move only the entity without touching the form, adjust `lEntityV`:

```qml
readonly property real  lEntityV:   -0.06   // entity ~22 px higher on 1080p
```

Each `0.01` step ≈ 11 px on 1080p, ≈ 16 px on 1600p (ProArt P16).

### Entity frame content bounds

Entity sprites are **512×512 RGBA**; visible glow spans y=148–373 (225 px, ~center-aligned).
At render size 520 px, a 50 %-centered entity has its glow at **screen 40 %–61 %**.

### Entity vertical offset — directional reference

`anchors.verticalCenterOffset` shifts the entity **relative to screen center**.
Two forms work — use whichever feels clearer:

```qml
// Percentage form (recommended — adapts to any resolution)
anchors.verticalCenterOffset: -parent.height * 0.05   // UP   5% of screen
anchors.verticalCenterOffset:  parent.height * 0.05   // DOWN 5% of screen

// Raw pixel form (fixed distance, resolution-dependent)
anchors.verticalCenterOffset: -54    // UP   54 px
anchors.verticalCenterOffset:  54    // DOWN 54 px
```

**Direction rule: negative = UP, positive = DOWN**

| offset | entity glow on screen (1080p) | notes |
|---|---|---|
| `-parent.height * 0.08` | glow ~34-55% | ceiling edge — risky |
| `-parent.height * 0.04` | glow ~36-57% | upper void |
| `-parent.height * 0.02` | glow ~38-59% | upper-mid void |
| `0` | glow ~40-61% | void center — baseline |
| `+parent.height * 0.02` | glow ~42-63% | lower-mid void |
| `+parent.height * 0.04` | glow ~44-65% | lower void / approaching floor |
| `+parent.height * 0.06` | glow ~46-67% | floor edge — risky |

Each `0.01` step = ~11 px on 1080p, ~16 px on 1600p (ProArt P16).

### Component interfaces

**`EntityDisplay.qml`** — self-contained animation. Anchors set on the instance in Main.qml.

| Property | Type | Default | What it does |
|---|---|---|---|
| `size` | `int` | 520 | Frame px; drives both width and height |
| `glowColor` | `color` | `#00f5ff` (cCyan) | Glow tint passed to MultiEffect colorization |

**`LoginForm.qml`** — username + passphrase field + error line. Width and anchors set on the
instance; palette values bound explicitly so the form is palette-agnostic.

| Interface | Kind | What it does |
|---|---|---|
| `currentUser` | property string | Drives the displayed username (auto-capitalises) |
| `displayFamily` / `monoFamily` | property string | Font families from Main.qml |
| `cText/cMuted/cMagenta/cCyan/cViolet/cRaised` | property color | Palette pass-through |
| `password` | readonly string | Current passInput text — read by `doLogin()` |
| `loginRequested()` | signal | Fired on Return/Enter; connect to `root.doLogin()` |
| `focusInput()` | function | Focus the passphrase field |
| `clearInput()` | function | Wipe the passphrase field |
| `shakeError()` | function | Flash "authentication failed" for 3 s |

**Tweaking username size or PW box height** — edit inside `LoginForm.qml`, not in Main.qml:

```qml
// Username size: font.pixelSize on usernameText (default 54)
//   Larger values push the PW box further down.
// PW box height: height on passField Rectangle (default 48)
//   Always keep radius = height / 2 to preserve the pill shape.
```

### Layout math

```
form bottom = topMargin + (usernameSize + spacing(10) + spacer(6) + passBox(48)) / screenHeight
# At 1080p, username=54: 0.57 + (54+64)/1080 = 0.68  PW box bottom right on floor
```

### Screenshot spell (no deploy needed)

```bash
# From RaBbLE-OS/ — clears QML cache, launches greeter, captures focused monitor
bash spells/sddm-screenshot.sh            # capture → RaBbLE-BaBbLE/captures/_inbox/
bash spells/sddm-screenshot.sh --open     # capture + open in imv immediately
bash spells/sddm-screenshot.sh --check    # parse-check only (no window, fast)
bash spells/sddm-screenshot.sh --delay 4  # wait longer if entity hasn't faded in yet
```

The spell always clears `~/.cache/sddm-greeter-qt6/qmlcache/` before launching — this is
required because SDDM's QML engine caches compiled bytecode and will silently serve stale
`.qmlc` files if the cache exists, ignoring your source edits.

### Deploy

```bash
sudo ./RaBbLE-OS-layerctl.sh apply boot
# Theme lands at next SDDM start — never restart sddm mid-session (kills Hyprland)
```

---

## Plymouth — `plymouth/files/rabble-aether/rabble-aether.script`

Plymouth runs before a GPU driver is fully up, so layout uses absolute pixel math with a
`scale` factor (`screen_w / 1920`). All positions are calculated at the top of the script.

### Key variables (~L32–L265)

| Variable | Line | Current value | What it controls |
|---|---|---|---|
| `screen_w` / `screen_h` | 32–33 | runtime | live resolution |
| `scale` | 46 | `screen_w / 1920` | scales all authored-at-1920 assets |
| `entity_cx` | 101 | `screen_w * 0.25` | entity X center (left section) |
| `entity_cy` | 102 | `screen_h * 0.50` | entity Y center (vertical) |
| `entity_cx_center` | 108 | `screen_w * 0.50` | X target when entity converges to center |
| `wm_y` | 140 | `screen_h * 0.42` | wordmark top (right section) |
| `log_baseline_y` | 179 | `screen_h * 0.63` | boot log text baseline |
| `ready_sprite` Y | 245 | `screen_h * 0.58` | "ready" overlay position |
| `panel_y` | 263 | `screen_h * 0.58` | FDE password prompt panel top |

### Layout rules

- **Entity** starts at `(0.25, 0.50)` and converges to `(0.50, 0.50)` — it stays vertically
  centered throughout. Adjust `entity_cy` to shift the glow up or down.
- **Wordmark** (`wm_y = 0.42`) sits 7 % below the ceiling grid end (~35 %). Moving it above
  `0.38` risks clipping into the ceiling grid.
- **Log text** (`log_baseline_y = 0.63`) scrolls upward from this Y. Keep it below `0.45`
  to stay clear of the wordmark; keep it above `0.67` to stay above the floor grid.
- **FDE panel** (`panel_y = 0.58`) must stay above `0.66` to avoid the floor.
- Run `measure-void-zone.py` after any bg change — it prints recommended values directly.

### No live preview

Plymouth has no `--test-mode`. Visual QA requires a reboot or VM:

```bash
# VM test (RaBbLE-OS-vmctl.sh manages a QEMU VM for this):
bash RaBbLE-OS-vmctl.sh start
# Then apply: sudo ./RaBbLE-OS-layerctl.sh apply boot
# Reboot the VM to see Plymouth

# Or check parse only (no visual):
# Plymouth's script language is custom — syntax errors are silent at runtime.
# The one known gotcha: NO ternary operator (?:) — use if/else blocks.
```

---

## GRUB — `grub2/files/theme/theme.txt`

GRUB themes use simple percentage-based layout in `theme.txt`. Values are `top = X%`,
`left = X%`, `width = X%`, `height = X%` — all relative to screen size.

### Key elements and current positions

| Element | Property | Current | Notes |
|---|---|---|---|
| Title "RaBbLE-OS" | `top` | `12%` | font size 36 |
| Subtitle "Episode 1 — Genesis" | `top` | `22%` | font size 18 |
| Separator line | `top` | `30%` | decorative dash row |
| **Boot menu** | `top` / `height` | `33%` / `52%` | spans 33–85 % of screen |
| Key hint | `top` | `89%` | help text row |
| Countdown bar | `top` | `94%` | progress_bar `__timeout__` |

### Boot menu sizing

```
# theme.txt — boot_menu block
top    = 33%     ← move down to give header more breathing room
left   = 22%     ← 22% margin each side = 56% wide menu
width  = 56%
height = 52%     ← decrease if you want more footer space
item_height  = 32   ← row height in px (not %)
item_padding = 10
item_spacing = 6
```

### Font note

GRUB fonts are generated at deploy time by the Ansible role:
```
grub2-mkfont -s SIZE -n "RaBbLE UI Regular" NotoSans-Regular.ttf
```
Available sizes: 12, 16, 18, 36. To add a size, edit
`ansible/roles/boot/grub2/tasks/main.yml` and add to the font-generation loop.

### No live preview

Changes require `grub2-mkconfig` + reboot (or VM). GRUB has no headless render mode.
Use the VM workflow or accept reboot QA.

---

## Cross-Stage Tips

- **Shared void zone**: measure once, apply to all three. `measure-void-zone.py` outputs
  recommended values for Plymouth constants directly.
- **SDDM iterates fastest**: QML test-mode + `grim` = sub-5-second feedback loop. Prove
  positioning there, then translate percentages to Plymouth and GRUB.
- **GRUB bg**: if you change `RaBbLE_boot_Liminal_BG.png`, run `build-assets.sh` to
  regenerate all three background images in one pass.
- **Plymouth syntax**: no ternary `?:` — always use `if`/`else` blocks (S166 root cause).

---

*Sources: `Main.qml`, `EntityDisplay.qml`, `LoginForm.qml`, `rabble-aether.script`, `theme.txt`, `measure-void-zone.py`*
*Void zone measured S167 via PIL scan of `assets/bg.png` (1920×1200). Component split S168.*
*→ `RaBbLE-OS/desktop/RaBbLE-OS-Desktop-BootFlow.md` — full boot chain config context*
