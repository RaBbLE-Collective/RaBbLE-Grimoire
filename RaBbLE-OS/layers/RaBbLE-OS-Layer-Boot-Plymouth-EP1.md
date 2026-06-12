# RaBbLE-OS · Boot Layer — Plymouth EP1 Refinement

> Feature map and implementation record for the Episode 1 boot-chain polish pass.
> Built from: S89 session, phone-captured reboot video (IMG_8949.mov).
> See `RaBbLE-OS-Layer-Boot.md` for the full boot layer overview.

---

## What Was Wrong (pre-S89)

| Issue | Observed | Root Cause |
|---|---|---|
| **22-second black flash** | Frames 3–25 of boot video were near-total darkness | Plymouth started in `simpledrm`/VESA mode; `amdgpu` loaded mid-boot and forced a KMS mode-set, dropping the framebuffer |
| **Entity centered** | Entity at `screen_w/2`, not left quarter | Layout not yet ported from Boot.html spec |
| **Log wall** | All 14 lines appeared simultaneously at bottom-left | Static reveal at fixed positions; no conveyor motion |
| **No floor grid** | Web version has NeBuLA `AmbientField` outrun grid; Plymouth had none | Not yet ported |
| **JetBrains Mono wordmark** | Boot.html uses Orbitron (`--font-hero`); Plymouth used JetBrains Mono Bold 64 | Orbitron not available in initrd |

---

## Target Layout (mirrors Boot.html landscape mode)

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   [ENTITY]        RaBbLE                                     ║
║   left 25%        Orbitron Bold, color-cycling               ║
║   vert center     centered in right 75%                      ║
║                   behavioral learning engine (tagline)       ║
║                                                              ║
║   · · · · · · · · · · · · · · · · · · · · · · · · · · · ·   ║
║   ╲           ╱  ←— cyan/magenta perspective grid           ║
║    ╲         ╱       VP at (W/2, H*0.74)                    ║
║─────╲───────╱──── log conveyor (bottom-center, ~5 lines) ───║
║─────────────────── progress bar (88% height) ───────────────║
╚══════════════════════════════════════════════════════════════╝
```

---

## Changes Made (S89)

### 1 · GPU Black Flash — `add_drivers+=" amdgpu "`

**File:** `ansible/roles/boot/plymouth/tasks/config.yml` → dracut conf content block

Adding `amdgpu` to `add_drivers` forces the AMD iGPU driver into the initramfs. Plymouth starts in DRM/KMS mode from the first frame — no VESA→DRM handoff, no black period.

```
add_drivers+=" amdgpu "
```

Also added Orbitron font path to `install_items` in the same conf (see §3).

### 2 · Orbitron Bold Font

Orbitron is not in Fedora package repos. Bundled `Orbitron-Bold.ttf` (~45 KB) in the role:
```
ansible/roles/boot/plymouth/files/rabble-aether/fonts/Orbitron-Bold.ttf
```

Ansible installs it to `/usr/share/fonts/rabble-fonts/Orbitron-Bold.ttf`, runs `fc-cache -f`, and injects it into the initrd via the dracut conf.

Plymouth script: `font_wordmark = "Orbitron Bold 64";`

### 3 · Entity Layout — Left Quarter, Vertically Centered

```
entity_cx = Math.Int(screen_w * 0.25);    # was screen_w / 2
entity_cy = Math.Int(screen_h * 0.50);    # was screen_h * 0.36
```

Right-section center derived after entity block:
```
right_start = entity_cx + Math.Int(entity_size / 2);
right_w     = screen_w - right_start;
right_cx    = right_start + Math.Int(right_w / 2);
```

Wordmark and tagline centered in `right_cx`.

### 4 · Wordmark Repositioned (right 75%, vertically centered)

```
wm_x      = right_cx - Math.Int(wm_w / 2);
wm_y      = Math.Int(screen_h * 0.42);
tagline_x = right_cx - Math.Int(tagline_img.GetWidth() / 2);
tagline_y = wm_y + wm_h + 12;
```

Color cycle (magenta → violet → cyan → magenta, 48 steps, every 3 ticks) unchanged.

### 5 · Floor Grid — Cyan/Magenta Perspective (pre-rendered PNG)

**Geometry:** ported from `NeBuLA/src/effects/ambient-field.js → _bakeGrid()`.
- Vanishing point: `(W/2, H * 0.74)` — matches web version exactly
- 18 radial fan lines alternating **cyan** (#00f5ff, α=0.28) and **magenta** (#ff2d78, α=0.28) — upgraded from web's all-violet to interlaced cyan/magenta
- 11 horizontal power-curved lines (`pow(j/11, 1.65)`) alternating magenta/cyan, α=0.22, edge-fading to transparent
- Fully transparent background PNG → composited over void by Plymouth

**Build:** added to `build-assets.sh` step 4 — Playwright canvas capture (1920×1080, `omitBackground: true`) → `assets/floor-grid.png`.

**Plymouth script:**
```
grid_img    = Image("assets/floor-grid.png");
grid_img    = grid_img.Scale(screen_w, screen_h);
grid_sprite = Sprite(grid_img);
grid_sprite.SetPosition(0, 0, 3);   # z=3: above background, below entity
```
In `refresh_callback`: `grid_sprite.SetOpacity(0.85 * fade);`

### 6 · Boot Log Conveyor — Bottom Center, Scrolling

Each line now has centered X coordinates stored at setup (`log_lines[i].ts_x` / `.tag_x` / `.msg_x`). In `refresh_callback`:

```
# lines_after = 0 → newest line, higher = older (further up the conveyor)
lines_after = visible_count - (i + 1);
y = log_baseline_y - lines_after * line_h;   # log_baseline_y = screen_h * 0.80

# Fade envelope: in over 8 ticks (~160ms), out after scrolling > 5 positions up
enter_op = min(1, age / 8);
exit_op  = max(0, 1 - (lines_after - 5) * 0.33)  if lines_after > 5 else 1;
```

~5 lines visible at a time. Oldest fade out as new ones appear at baseline.

### 7 · Progress Bar — Moved to 88% Height

`bar_y = Math.Int(screen_h * 0.88);` (was 0.84) — clears the log conveyor.

---

## Asset Regeneration

Whenever `RaBbLE-Boot.html` or the grid design changes:
```bash
# Dev server must be running
bash RaBbLE-Grimoire/spells/dev-serve.sh --world

# Regenerates: frames/entity-*.png + assets/floor-grid.png
bash RaBbLE-OS/ansible/roles/boot/plymouth/files/rabble-aether/build-assets.sh

# Commit the new assets before applying
```

## Apply

```bash
cd RaBbLE-OS
bash RaBbLE-OS-layerctl.sh apply boot/plymouth
# Runs: font install → fc-cache → dracut rebuild (via Ansible handler)
sudo reboot
```

## QA Checklist

- [ ] No black flash — entity visible from first Plymouth frame
- [ ] Entity in left ~25% of screen, vertically centered, void background solid
- [ ] Cyan/magenta perspective grid fills lower screen, VP at ~74% height
- [ ] "RaBbLE" in Orbitron Bold, centered in right 75%, color-cycling gradient
- [ ] Boot log lines scroll upward from bottom-center; ~5 lines visible; fade in/out
- [ ] Progress bar at bottom, no overlap with log conveyor
- [ ] LUKS prompt centered and legible (dialog z-layer unchanged)
- [ ] Shutdown/reboot mode: quiet_mode=1, entity loop only (no logs, wm dimmed)
