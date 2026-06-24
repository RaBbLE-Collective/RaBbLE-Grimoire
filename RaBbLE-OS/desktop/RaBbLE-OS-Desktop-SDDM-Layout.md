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

## SDDM — `session_manager/files/sddm-theme/Main.qml`

SDDM uses QML with `parent.height`-relative anchors. All values are percentages of
the live screen height — they adapt to any resolution automatically.

### Entity frame content bounds

Entity sprites are **512×512 RGBA**; visible glow spans y=148–373 (225 px, ~center-aligned).
At render size 520 px, a 50 %-centered entity has its glow at **screen 40 %–61 %**.

### Key values

| What | Property | Line | Current | Notes |
|---|---|---|---|---|
| Clock vertical | `anchors.topMargin` | ~166 | `parent.height * 0.10` | distance from topBar bottom |
| Clock size | `font.pixelSize` | ~180 | `Math.min(root.width * 0.095, 104)` | scale + cap |
| Entity size | `width` / `height` | ~190–202 | `520` | frame px; glow scales with it |
| Entity vertical | `anchors.verticalCenterOffset` | ~194 | `0` | 0 = screen center (50 %) |
| Form top | `anchors.topMargin` | ~246 | `parent.height * 0.57` | username top position |
| Username size | `font.pixelSize` | ~261 | `54` | increase pushes PW box down |
| PW box height | `height` | ~279 | `48` | `radius` must stay `height/2` |

### Layout math

```
form bottom ≈ topMargin + (usernameSize + spacing(10) + spacer(6) + passBox(48)) / screenHeight
# At 1080p, username=54: 0.57 + (54+64)/1080 ≈ 0.68 → PW box bottom right on floor ✓

entity verticalOffset ranges:
  -0.04 → glow top at 36 % (clips into ceiling grid — avoid)
   0    → glow 40 %–61 %  (sits in void — current)
  +0.04 → glow 44 %–65 %  (near floor — use for dramatic drop effect)
```

### Screenshot spell (no deploy needed)

```bash
# From RaBbLE-Collective root — uses source theme directly
STAMP=$(date +%Y%m%d-%H%M%S)
OUT="RaBbLE-BaBbLE/captures/_inbox/sddm-tweak-$STAMP.png"
QT_QPA_PLATFORM=wayland sddm-greeter-qt6 --test-mode \
  --theme RaBbLE-OS/ansible/roles/boot/session_manager/files/sddm-theme &
GPID=$!; sleep 2
grim -o "$(hyprctl monitors -j | python3 -c \
  "import sys,json; print([m['name'] for m in json.load(sys.stdin) if m.get('focused')][0])")" "$OUT"
kill $GPID && echo "→ $OUT"
```

```bash
# Offscreen parse-check only (no window — exit 124 = QML OK, other = error):
QT_QPA_PLATFORM=offscreen timeout 6 sddm-greeter-qt6 --test-mode \
  --theme RaBbLE-OS/ansible/roles/boot/session_manager/files/sddm-theme; echo "exit $?"
```

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

*Sources: `rabble-aether.script`, `Main.qml`, `theme.txt`, `measure-void-zone.py`*
*Void zone measured S167 via PIL scan of `assets/bg.png` (1920×1200).*
*→ `RaBbLE-OS/desktop/RaBbLE-OS-Desktop-BootFlow.md` — full boot chain config context*
