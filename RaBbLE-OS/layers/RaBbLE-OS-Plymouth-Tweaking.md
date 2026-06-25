# RaBbLE-OS Plymouth — Tweaking & Debugging Guide

> How to adjust the boot splash layout, test changes without rebooting, and diagnose
> problems when something looks wrong. Assumes you are on the ProArt P16 running Fedora 43.
>
> **Source files** (edit these, not the live ones under `/usr/share/`):
> - Script: `RaBbLE-OS/ansible/roles/boot/plymouth/files/rabble-aether/rabble-aether.script`
> - Assets: `RaBbLE-OS/ansible/roles/boot/plymouth/files/rabble-aether/assets/`
> - Dracut conf: `RaBbLE-OS/ansible/roles/boot/plymouth/tasks/config.yml` (the `content:` block)

---

## 1. Coordinate system

Plymouth's coordinate origin is **top-left**. X increases rightward, Y increases downward.

```
(0,0) ──────────────────────────── (screen_w, 0)
  │                                      │
  │    screen_h = Window.GetHeight()     │
  │    screen_w = Window.GetWidth()      │
  │    e.g. 3840 × 2400 on ProArt P16   │
  │                                      │
(0, screen_h) ──────── (screen_w, screen_h)
```

The script expresses all positions as **fractions** of screen dimensions so the layout
scales from 720p to 4K without touching geometry code. `scale = screen_w / 1920.0` is
the pixel-density factor — assets are authored at 1920×1080 reference resolution.

### Screen zones

```
┌──────────────────────────────────────────────────────────────────┐
│  bg-liminal.png fills 100%                                       │
│  floor-grid.png fills 100% (z=3, above bg at z=1)               │
│                                                                  │
│  LEFT QUARTER (0..25% of width)        RIGHT SECTION (25..100%) │
│  ┌─────────────┐                      ┌──────────────────────┐  │
│  │   ENTITY    │ ENTITY_CX_FRAC=0.25  │  Wordmark (WM_Y)     │  │
│  │  sprite     │ ENTITY_CY_FRAC=0.50  │  Tagline             │  │
│  │  z=10       │                      │  Progress bar        │  │
│  └─────────────┘                      │  Pct label           │  │
│                                       │  Log conveyor        │  │
│                                       │  (LOG_BASELINE_FRAC) │  │
│                                       └──────────────────────┘  │
│  Scanlines overlay (z=500, topmost)                              │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. The LAYOUT CONSTANTS block — your main control panel

Everything you need to move things around is in one place at the top of the script
(after the palette section, before any code). Edit only this block for positional changes.

```
# ── LAYOUT CONSTANTS — tweak here, nowhere else ──────────────────────────────
# Entity
ENTITY_CX_FRAC  = 0.25;   # centre-X during boot (left quarter → slide)
ENTITY_CY_FRAC  = 0.50;   # centre-Y (vertical midpoint of screen)
ENTITY_CX_END   = 0.50;   # centre-X after slide at boot-complete
ENTITY_SLIDE_TICKS = 40;  # slide duration (~2.4 s at 60ms/tick)

# Wordmark (right section)
WM_Y_FRAC       = 0.42;   # wordmark top edge (0.35 is ceiling, 0.42 has 7% margin)
WM_TAGLINE_GAP  = 12;     # px gap: wordmark bottom → tagline top
WM_FADE_START   = 75;     # tick when wordmark begins fading in
WM_FADE_TICKS   = 125;    # fade duration (done at tick 200)

# Boot log
LOG_BASELINE_FRAC = 0.63; # Y of the newest log line (older scroll upward)
LOG_LINE_H        = 20;   # line height px at 1920-wide reference
LOG_LEFT_MARGIN   = 20;   # px indent from the right-section left edge

# Progress bar
BAR_W_FRAC      = 0.34;   # bar width as fraction of screen width
BAR_H_PX        = 6;      # bar height px (clamped to ≥ 3 at low res)
BAR_TAGLINE_GAP = 22;     # px: tagline bottom → bar top
BAR_PCT_GAP     = 8;      # px: bar bottom → percentage label
BAR_MSG_ABOVE   = 30;     # px: bar top → systemd message line (above bar)

# "Ready" line and dialog
READY_Y_FRAC    = 0.58;   # Y of "◈ Boundless and becoming · ready when you are"
DIALOG_Y_FRAC   = 0.58;   # Y of the passphrase/question dialog panel
DIALOG_W_FRAC   = 0.30;   # dialog panel width as fraction of screen
DIALOG_H_PX     = 96;     # dialog panel height px at reference resolution
```

**Rule:** if a value you want to change is not in this block, add it here and reference
the constant in the code below. Never scatter new magic numbers into the geometry code.

---

## 3. Testing without a full reboot

A real reboot to test one tweak is painful. These methods let you iterate faster.

### Method A — plymouthd fake boot (fastest, no reboot)

Plymouth ships a `--mode=boot` preview. Run it as root in a VT:

```bash
# Switch to an unused VT first (e.g. Ctrl+Alt+F3 from the desktop)
sudo plymouthd --mode=boot --attach-to-session --pid-file=/tmp/p.pid &
sleep 0.5
sudo plymouth --ping
sudo plymouth update --status="updating"
sudo plymouth system-update --progress=0
sleep 1
sudo plymouth system-update --progress=50
sleep 2
sudo plymouth system-update --progress=100
sleep 2
sudo plymouth quit
```

This runs the splash on the current framebuffer. You'll see your changes live — no reboot
needed. Switch back to the desktop (Ctrl+Alt+F1 or F2) when done.

> **Limitation:** plymouthd in this mode runs on the compositor-owned framebuffer, not
> the bare DRM device. Rendering will be close but not pixel-identical to a real boot.

### Method B — deploy only the script, no initramfs rebuild

For script-only changes (no new assets), you can push the file directly and test on the
next reboot without a full `dracut` rebuild. This is much faster than `apply boot`:

```bash
# From RaBbLE-OS/
sudo cp ansible/roles/boot/plymouth/files/rabble-aether/rabble-aether.script \
        /usr/share/plymouth/themes/rabble-aether/rabble-aether.script
# Now reboot — Plymouth will read the updated script from /usr/share/,
# but note: this is overwritten on the NEXT `apply boot` run.
```

> **When you are happy** with the result, commit the script and do a proper `apply boot`
> to bake it into the initramfs (Plymouth reads from the initramfs during actual boot, not
> from /usr/share/).

### Method C — boot-diagnose.sh verification

After any real reboot, run:

```bash
sudo spells/boot-diagnose.sh
```

This checks: theme files in initramfs, plugin presence, whether the debug log is fresh,
and surfaces any errors. The verdict section tells you if something is structurally wrong
before you dig into individual log lines.

---

## 4. Full deploy cycle (apply boot)

When you've made changes that require rebuilding the initramfs (new assets, dracut conf
changes, new fonts, or you want the script baked into the initrd):

```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
sudo ./RaBbLE-OS-layerctl.sh apply boot
sudo reboot
```

`apply boot` runs the Ansible boot layer which:
1. Deploys the theme files to `/usr/share/plymouth/themes/rabble-aether/`
2. Updates `/etc/dracut.conf.d/90-rabble-plymouth-fonts.conf`
3. Updates `/etc/default/grub` and `/boot/grub2/themes/rabble/theme.txt`
4. Runs `dracut --force` → rebuilds the initramfs (this takes ~30s)
5. Runs `grub2-mkconfig` → updates the GRUB boot entries

**Always apply, then reboot.** Script changes written only to `/usr/share/` are not
picked up at boot time — Plymouth reads from the initramfs.

---

## 5. Enabling the debug log for a reboot

When you need the full Plymouth debug log for a real boot (not a preview), enable the
`plymouth:debug` kernel parameter:

```bash
# Enable — adds 'plymouth:debug' to the kernel cmdline via group_vars:
sudo spells/boot-debug-toggle.sh --on    # also runs apply boot

# Then reboot. After logging in:
sudo spells/boot-diagnose.sh             # reads /var/log/plymouth-debug.log

# Disable — removes 'plymouth:debug':
sudo spells/boot-debug-toggle.sh --off   # also runs apply boot
```

`plymouth:debug` is temporary diagnostic scaffolding. **Remove it once you're done** —
it redirects `plymouthd` output to `/dev/tty1`, which puts debug text on screen over
the splash (this is why you see raw text during Plymouth in an unclean boot).

The debug log path is `/var/log/plymouth-debug.log`. It is overwritten each boot.

---

## 6. Reading the debug log

```bash
cat /var/log/plymouth-debug.log
```

Key things to look for:

| Log line pattern | What it means | Fix |
|---|---|---|
| `Could not load module .../label-pango.so` | Pango font renderer not in initramfs | Ensure `install_items+=" /usr/lib64/plymouth/label-pango.so "` in dracut conf, then `apply boot` |
| `sh: /usr/bin/fc-match: No such file or directory` (many times) | fontconfig binary not in initramfs | Add `install_items+=" /usr/bin/fc-match "` to dracut conf |
| `Failed to open key file /run/plymouth/plymouthd.defaults` | Normal on first boot — Plymouth hasn't written the file yet | Harmless, ignore |
| `Unloading renderer backend plugin` | Plymouth is quitting | Normal at the end |
| No lines after `check_verbosity` at ~T=2s | Plymouth quit immediately — script crash | Look for errors just before; check script syntax |
| `quitting program` at T=9s | Normal Plymouth exit | Healthy |

**Timestamp format:** `HH:MM:SS.mmm` relative to Plymouth start, not kernel boot. Plymouth
itself starts at roughly T+2s from kernel start (after initramfs init).

---

## 7. Diagnosing a black screen

If the boot splash is all black:

1. **Is the theme in the initramfs?**
   ```bash
   sudo spells/boot-diagnose.sh   # check "theme files in initramfs" count
   ```
   Should be ~160+ files. If it shows 0 or a small number, the initramfs wasn't rebuilt
   after the theme was deployed. Run `apply boot`.

2. **Is the theme set as default?**
   ```bash
   plymouth-set-default-theme    # should print: rabble-aether
   ```
   If not: `sudo plymouth-set-default-theme rabble-aether && sudo dracut --force`

3. **Is amdgpu in the initramfs?**
   ```bash
   lsinitrd /boot/initramfs-$(uname -r).img | grep amdgpu
   ```
   Should find `amdgpu.ko.xz`. If missing, the GPU driver isn't in the initramfs —
   Plymouth will fall back to framebuffer-only and may show black until amdgpu loads.
   Ensure `add_drivers+=" amdgpu "` is in the dracut conf.

4. **Enable the debug log** (§5) and reboot. Look for script errors in the log.

5. **amdgpu + simpledrm conflict?** See `RaBbLE-OS-Fix-BootChain.md`. The fix is
   `amdgpu.seamless=1` in the kernel cmdline (already set for ProArt P16).

---

## 8. Plymouth script language basics

The script language is a minimal C-like scripting engine. Key primitives:

```
# Variables — no type declaration, just assign
x = 42;
name = "hello";

# Math
y = Math.Int(x / 3);       # integer division (no native int division)
z = Math.Int(x * 0.5);     # multiply then truncate

# Sprites — a sprite is a positioned image on screen
img = Image("assets/foo.png");
sprite = Sprite(img);
sprite.SetPosition(x, y, z_depth);   # z: higher = in front
sprite.SetOpacity(0.0 to 1.0);
sprite.SetImage(new_img);             # swap the image without recreating the sprite

# Text rendering (requires label-pango.so in initramfs)
txt = Image.Text("Hello", r, g, b, opacity, "FontName Size");
# r/g/b are 0.0–1.0 floats

# Scale an image
scaled = img.Scale(new_w, new_h);

# Callbacks — called by Plymouth on events
fun refresh_callback() { ... }
fun progress_callback(duration, progress) { ... }
fun message_callback(msg) { ... }
Plymouth.SetRefreshFunction(refresh_callback);

# Conditions — no 'else if', use nested ifs or intermediate vars
if (x > 0) { ... }

# No ternary operator (?:) — use if blocks for conditionals
```

**Global scope in functions:** variables declared at the top level of the script are
global, but to read or write them from inside a function you must prefix `global.`:
```
tick = 0;
fun refresh_callback() {
  global.tick = global.tick + 1;
}
```

---

## 9. Common tweaks with concrete examples

### Move the entity lower on screen

Change `ENTITY_CY_FRAC = 0.50` → e.g. `0.55` (5% lower):

```
ENTITY_CY_FRAC  = 0.55;
```

### Move the wordmark up

Change `WM_Y_FRAC = 0.42` → e.g. `0.38`. Don't go below `0.35` — the floor grid
ceiling is at ~35% and you'll put the wordmark inside it.

### Show the boot log higher on screen

Change `LOG_BASELINE_FRAC = 0.63` → e.g. `0.58`. The log scrolls upward from this
baseline, so moving it up (lower fraction) compresses it toward the wordmark.

### Widen the progress bar

Change `BAR_W_FRAC = 0.34` → `0.45` to make the bar span 45% of screen width.

### Slow down or speed up the entity slide at boot-complete

Change `ENTITY_SLIDE_TICKS = 40` (each tick ≈ 60ms at 60fps Plymouth refresh):
- `20` = fast (~1.2s)
- `40` = default (~2.4s)
- `80` = slow (~4.8s)

### Make the wordmark appear later / fade in slower

- `WM_FADE_START = 75` → `150` to delay start to tick 150 (~9s into boot)
- `WM_FADE_TICKS = 125` → `250` for a slower fade

### Change entity position to center for the whole boot (no slide)

Set `ENTITY_CX_FRAC = 0.50` AND `ENTITY_CX_END = 0.50`. The slide still runs but
start == end, so it's a no-op. You'll also want to update `right_start` logic in the
script — left-quarter centering currently defines where the right section begins.

---

## 10. Adding or replacing assets

Assets live in:
```
ansible/roles/boot/plymouth/files/rabble-aether/assets/
ansible/roles/boot/plymouth/files/rabble-aether/frames/      # entity animation frames
```

After adding a new PNG:
1. Commit it to the repo
2. Run `apply boot` — dracut recursively includes the entire theme directory
3. Reference it in the script: `img = Image("assets/new-file.png");`

### Regenerating the entity frames or wordmark

The frames are pre-captured from `RaBbLE-Boot.html` via `build-assets.sh`:

```bash
# From the theme directory:
cd ansible/roles/boot/plymouth/files/rabble-aether/
bash build-assets.sh   # requires Playwright + ffmpeg; see script header
```

This regenerates:
- `frames/entity-0001.png` through `frames/entity-0096.png` — the entity animation
- `assets/wm-step-000.png` through `assets/wm-step-047.png` — Orbitron color-cycle wordmark

After regenerating, run `apply boot` to bake them into the initramfs.

---

## 11. The initramfs and why it matters

Plymouth runs from the **initramfs** — a small RAM disk the kernel extracts before the
root filesystem mounts. This means changes to files on disk under `/usr/share/plymouth/`
are **not seen at boot time** until `dracut --force` bakes them in.

What goes into the initramfs is controlled by `/etc/dracut.conf.d/90-rabble-plymouth-fonts.conf`:

```
install_items+=" <fonts> "
install_items+=" /usr/share/plymouth/themes/rabble-aether/ "  # the whole theme, recursively
install_items+=" /usr/lib64/plymouth/label-pango.so "          # text rendering
install_items+=" /usr/bin/fc-match "                           # font discovery
add_drivers+=" amdgpu "                                        # GPU driver
```

dracut auto-resolves shared library dependencies when you install a binary or `.so`,
so you don't need to manually add `libpango.so.*`, `libfontconfig.so.*`, etc.

To verify what's currently in the running initramfs:
```bash
lsinitrd /boot/initramfs-$(uname -r).img | grep -E "rabble-aether|label-pango|fc-match"
```

---

## 12. Quick reference — decision tree

```
Something looks wrong →

  Is it a positioning issue?
  → Edit LAYOUT CONSTANTS block in rabble-aether.script
  → Test with plymouthd fake boot (§3A) or deploy-only (§3B)
  → Reboot to confirm, then apply boot

  Is it a black screen?
  → Run boot-diagnose.sh (§7)
  → Check theme files count, amdgpu presence, default theme

  Are there errors in the Plymouth log?
  → Enable debug log (§5), reboot, read /var/log/plymouth-debug.log (§6)
  → Common fixes: label-pango.so and fc-match in dracut conf (§6 table)

  Did assets change (new frames, new PNGs)?
  → Commit → apply boot (§4)

  Script crash / nothing renders?
  → Enable debug log, look for errors just after T=2s
  → Check global. prefix on all variables modified inside functions
  → Check Math.Int() wrapping on any division
```

---

*Last updated: S170 · 2026-06-24*
*References: `RaBbLE-OS-Layer-Boot-Plymouth-EP1.md` · `RaBbLE-OS-Fix-BootChain.md` · `RaBbLE-OS-Verify-Checklist.md`*
