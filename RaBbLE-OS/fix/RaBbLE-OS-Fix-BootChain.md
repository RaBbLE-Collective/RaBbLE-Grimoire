# RaBbLE-OS-Fix-BootChain.md — fix/boot-chain

**Branch:** `RaBbLE-OS-New-Horizons`
**State:** `%REFINING%`
**Goal:** Unified boot-chain theming — GRUB→Plymouth→SDDM reads as one continuous liminal performance using the Liminal_BG canvas across all stages.

> 🧠 **Understand the boot chain first:** `RaBbLE-OS-BootChain-Anatomy.md` — the durable mental
> model (stage-by-stage pipeline with measured timings, the framebuffer/DRM handoff explained,
> the symptom→cause table, and the **disproven-theory ledger**: ternary bug, `use-simpledrm` pin,
> `amdgpu.seamless=1` — all dead ends, with evidence, so we don't re-chase them). This file is the
> chronological work log; that file is the model.

> **Status legend** (S153 — do not conflate "written" with "working"):
> `[x]` verified on a real reboot · `[~]` implemented, **UNVERIFIED on hardware** · `[ ]` not done.
> Everything OpenCode landed in S152 is `[~]`, not `[x]`. The boot chain cannot be
> exercised from an agent shell — it only proves out on a real reboot. Run the
> **Verification** recipe below before promoting anything to `[x]`.

## GRUB2

- [~] **Background image**: 24bpp RGB PNG generated from `RaBbLE_boot_Liminal_BG.png` via `build-grub-bg.py`; composited entity + floor grid + wordmark. `theme.txt` + `grub-bg.png` deploy via explicit Ansible copies (S153: switched off whole-dir copy so the build script no longer lands in `/boot`).
- [~] **4K font**: Noto Sans generated at 12/16/18/36pt, all named `"RaBbLE UI Regular"`; theme uses `RaBbLE UI Regular 36` for titles.
  - **S153 correction:** the S152 note claimed a `ter-32.pf2 "RaBbLE UI Mono"` font. **No Ansible task generates it and no theme directive references it** — the line was removed from `theme.txt`. If a mono GRUB font is actually wanted, an `grub2-mkfont` task must be added first.
- [~] **Early TTY font**: `fbcon=font:TER16x32` added to `rabble_grub_extra_cmdline` (group_vars), flows into `GRUB_CMDLINE_LINUX` via `grub.j2`.
- [~] **NVIDIA defer**: `rd.driver.blacklist=nvidia` on cmdline; NVIDIA kept out of initramfs (black-flash fix). **Partner service now exists** — see Plymouth "No black flash" below.

## Plymouth

- [~] **Boot log — REVERTED to prebaked lore (S153)**: OpenCode's live-systemd ring buffer (`MAX_LOG=20` + `message_callback` injection) was **removed** — Mark's call: it read as messy noise in practice. The splash is a *performance*, so the log is now fully prebaked behavioral lore (16 lines, `[ts] [TAG] message`, color-coded tags INFO=cyan/OK=green/WARN=yellow/RaBbLE=violet) mirroring `RaBbLE-Boot.html`. Real systemd messages (fsck/device waits) still surface on the separate `message_sprite` line, not in the lore log.
- [~] **Liminal background**: `bg-liminal.png` (from `RaBbLE_boot_Liminal_BG.png`, 1920×1200) drawn at z=1 behind the floor grid — visual continuity with GRUB/SDDM.
- [~] **Text positioning (S153)**: Wordmark moved back **up** to `screen_h*0.20` (OpenCode had pushed it to 0.32); log conveyor baseline set to `screen_h*0.70` so the lore lines fill the reference's ~0.45–0.70 band below the progress bar. Confirm against a real capture (Boot.html or VT test).
- [~] **No black flash**: `plymouth.use-simpledrm=1` removed from cmdline; `add_drivers+=" amdgpu "` in `roles/boot/plymouth/tasks/config.yml` forces AMD KMS into the initramfs from frame one.
  - **S153: `nvidia-load.service` implemented** (`roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml`). Oneshot, `After=sddm.service`, `WantedBy=graphical.target`, `modprobe nvidia_drm` + `nvidia_uvm`. This is the documented partner to `rd.driver.blacklist=nvidia`: the dGPU is a PRIME-offload/compute device (AMD drives display), so it loads *after* the login surface, off the boot critical path.
- [~] **Palette**: JetBrains Mono (logs), Orbitron (wordmark) via pre-rendered PNGs — no font discovery in initrd.

## SDDM

- [~] **Entity idle loop**: forward-only `(idx+1)%48` → ping-pong `forward→backward→forward`. This removes the hard 47→0 cut but is a **STOPGAP** — see "Future: clean entity loop".
- [~] **Username case**: transforms `"rabble"` → `"RaBbLE"`; title-cases any other username.
- [~] **Background**: `bg.png` regenerated from `RaBbLE_boot_Liminal_BG.png` — matches GRUB + Plymouth.
- [~] **Mockup match (S153)** — toward `captures/Entity-UI/Boot` login mockup:
  - Entity enlarged 320→460px to dominate the upper-center; column widened to 460.
  - Clock re-anchored from `top 0.08h` to **just above the entity** (compact), `Font.Black`, ~0.085·w (max 92px), letter-spacing 6, opacity 0.95.
  - **Top "waybar" strip** added: Aether-styled translucent bar, left RaBbLE workspace pill, right caps-lock + session. ⚠ **Decorative only** — the greeter has no live battery/network; real widgets need a backend (follow-up).
  - Power-button contrast: resting color `cMuted`→`cText`, glyphs 22→26px, on a translucent `cVoid` backing pill with an Aether border.
  - **Validated:** loads clean in `QT_QPA_PLATFORM=offscreen sddm-greeter-qt6 --test-mode` (no QML errors, 5s).
- [ ] Qt6 API validation on real greeter (visual) — `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble-aether` in a window
- [ ] Wayland session conf + `hyprland.desktop` entry
- [ ] Follow-up: live waybar widgets (battery/network) in the greeter — needs a backend feeding QML

## Boot asset masters — regenerate at 4K+ `[OPEN · S153]`

**The Plymouth script is now resolution-independent** (S153): a `scale = screen_w / 1920`
factor scales the fixed sprites (entity, wordmark, dot), text point sizes, and inter-element
gaps; the full-screen layers (bg-liminal, floor-grid, scanlines) already `Scale()` to fit. So
**one** asset set renders at the same proportions from 720p to 4K, and new higher-res masters
**drop in with no script change** (sizing is fraction-of-screen, not tied to master pixels).

**BUT the current masters are 1920-class** and get *upscaled* on the 4K ProArt panel
(`scale ≈ 2.0`) → expect interpolation softness on the entity + wordmark until masters are
regenerated. TODO, owner Mark/NeBuLA:

| Asset | Current | Regenerate at | Source |
|---|---|---|---|
| `frames/entity-*.png` | 512² (from 1920×1080 capture, `CROP=640 OUT_SIZE=512`) | ≥1024² (bump `OUT_SIZE`/capture viewport in `build-assets.sh`) | NeBuLA canvas capture |
| `assets/wm-step-*.png` | 352×84 | ~2× (render Orbitron page at 2× device-scale) | Aether wordmark capture |
| `assets/floor-grid.png`, `scanlines.png` | 1920×1080 | 3840×2400 (native panel) | build-assets ffmpeg/node — bump `s=WxH` |
| `bg-liminal.png` + GRUB/SDDM bg | 1920×1200 (resized from `RaBbLE_boot_Liminal_BG.png`) | 3840×2400 | BaBbLE Liminal_BG master (already high-res) |

- `build-assets.sh` viewport/sizes are hardcoded `1920×1080` / `512` — bump those and re-run.
- Backgrounds downscale cleanly, so 4K masters are strictly better everywhere; no downside.
- Until regenerated: 720p/1080p look correct; 4K is correct-proportioned but slightly soft.

## Future: clean entity loop (NOT this pass — planned)

Mark's call (S153): **ping-pong reads as too obvious** — the eye catches the direction
reversal at both ends, so it doesn't feel like a true loop. Ping-pong stays as the
stopgap; a genuinely seamless loop is a **separate future pass**, scoped here so it isn't lost:

- The 48-frame `entity-idle-*.png` set is **not loop-closed** — frame 47 → frame 0 is a
  visible jump, which is *why* forward-only looked bad and ping-pong was reached for.
- The real fix is at the **source animation** (NeBuLA idle), not in the SDDM Timer:
  bake a sequence whose **last frame eases back into the first** (a closed cycle —
  e.g. a slow breathing/pulse orbit that returns to its start pose), then export 48
  (or N) frames. Forward-only `(idx+1)%N` then loops cleanly with no reversal artifact.
- Owner: NeBuLA (frame export) → OS (drop new PNGs into the SDDM + Plymouth asset sets).
- Until then: SDDM `Main.qml` keeps the ping-pong block (commented as STOPGAP).

## Visually debugging the boot (NOT VM-only)

You can iterate most of the chain without full reboots:

| Stage | How to see it live | Capture |
|---|---|---|
| **Design source** | Open `RaBbLE-Boot.html` in a browser — Plymouth is a frame-player *port* of it, so positioning/log layout is fastest to tune here first | screenshot / Playwright (build-assets.sh already does this) |
| **Plymouth** | `sudo bash spells/test-plymouth.sh` from a **bare VT** (Ctrl+Alt+F3 → login → run; Ctrl+Alt+F2 back). Real renderer on real HW. | photograph the screen (a VT framebuffer can't be `grim`'d) |
| **SDDM** | `sddm-greeter-qt6 --test-mode --theme <path>` in your live session — renders the greeter in a **window**, no reboot, fully visual | `grim`/screenshot the window |
| **Full chain + GRUB** | boot a VM via `RaBbLE-OS-vmctl.sh` — screenshot the framebuffer at any moment | scriptable, repeatable |

- `test-plymouth.sh` starts Plymouth *after* the GRUB→Plymouth handoff, so it **cannot reproduce the handoff transition itself** — for the "black pane covering 75% with BG still visible" glitch, the VM (or a photographed real boot) is the way to catch that exact moment.

### "Black pane over 75%" — ROOT CAUSE CONFIRMED (S153) + FIX

Diagnosed live via `dmesg`/DRM state on the P16 (not speculation):
- Panel native = **3840×2400** (`card1-eDP-1`).
- GRUB had `GFXMODE=1920x1200x32` + `GFXPAYLOAD_LINUX=keep`, so the kernel inherited the **1920×1200** mode. dmesg: `Console: switching to colour frame buffer device 240x75` = simpledrm @ 1920×1200, then `480x150` = amdgpu @ 3840×2400 ~3s later.
- **1920×1200 is exactly ¼ the area of 3840×2400.** simpledrm paints that buffer 1:1 in the top-LEFT quarter of the 4K panel → 75% black, bg-liminal visible in the quarter — until amdgpu KMS switches to native.

**Fix applied (UNVERIFIED — reboot-test):** decouple the kernel framebuffer from the GRUB menu mode — keep the menu at 1920×1200 (readable) but hand the kernel a **native** payload:
```yaml
# group_vars/asus_proart_p16.yml
rabble_gfx_mode: "1920x1200x32"        # GRUB menu — readable
rabble_grub_gfxpayload: "3840x2400x32" # kernel/simpledrm/Plymouth — native, fills the panel
```
This makes simpledrm fill the 4K panel AND removes the mid-boot resolution switch (simpledrm 4K → amdgpu 4K, no change → also kills any residual flash). Verify after reboot: `dmesg | grep "frame buffer device"` should show the FIRST fb at `480x150` (4K), not `240x75`.

- Side effect: Plymouth now renders at native 4K, so the entity/wordmark PNGs look small until their capture resolution is bumped in `build-assets.sh` (visual-polish follow-up — layout holds because it's ratio-based).
- Alternative if you'd rather not go 4K in boot: `video=eDP-1:1920x1200` to pin amdgpu to 1920 — but that does NOT fix the simpledrm-quarter window (GOP is still 1920), so the native-payload fix above is the correct one.

## Verification — RUN THIS ON A REAL REBOOT before promoting `[~]` → `[x]`

> The boot chain is **unverified**. These changes touch the kernel cmdline and initramfs;
> do not trust them until this passes. Keep a live-USB handy (recovery: `rd.break` +
> the locked-root escape hatch in KnownIssues → System Recovery).

**0. Apply + rebuild (initramfs + GRUB regenerate via handlers):**
```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
bash RaBbLE-OS-layerctl.sh apply boot         # plymouth/grub/session_manager roles
bash RaBbLE-OS-layerctl.sh apply hardware     # nvidia.yml — deploys + enables nvidia-load.service
# confirm the heavy handlers actually ran (initramfs rebuild + grub2-mkconfig)
```

**1. Pre-reboot static checks (no reboot needed):**
```bash
systemctl is-enabled nvidia-load.service                      # → enabled
systemd-analyze verify /etc/systemd/system/nvidia-load.service # → no errors
grep -o 'rd.driver.blacklist=nvidia\|fbcon=font:TER16x32' /etc/default/grub
lsinitrd | grep -E 'amdgpu|nvidia'                            # amdgpu present, nvidia ABSENT
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble-aether  # entity + RaBbLE username render
```

**2. Reboot and watch each stage (this is the only real test):**
- [ ] **GRUB** at 1920×1200: readable Noto title font + liminal background + entity watermark
- [ ] **GRUB→Plymouth handoff**: **no black flash** (the headline fix — was a ~10s black screen / DRM reset)
- [ ] **Plymouth**: liminal bg + entity (left) + wordmark (right, `~0.32` height) + live systemd logs scrolling up + floor grid
- [ ] **Plymouth→SDDM**: feels like a fade/render-in, not a hard cut (Mark's "seamless" goal)
- [ ] **SDDM**: liminal bg + entity idle (ping-pong, stopgap) + `RaBbLE` username + color-cycling wordmark
- [ ] **TTY** (Ctrl+Alt+F3): Terminus large font persists on the actual TTY (the OPEN bug — font seen applying pre-Plymouth but may revert)

**3. Post-login NVIDIA proof (the cmdline-change safety net):**
```bash
systemctl status nvidia-load.service     # active (exited), no failure
lsmod | grep nvidia                      # nvidia, nvidia_drm, nvidia_modeset, nvidia_uvm loaded
nvidia-smi                               # dGPU enumerated
DRI_PRIME=1 glxinfo | grep "OpenGL renderer"   # → NVIDIA (PRIME offload works)
```
If step 3 fails, the `rd.driver.blacklist=nvidia` defer is the cause — the service didn't
re-load the dGPU. Fall back: drop the blacklist + restore `nvidia-drm.modeset=1` in group_vars.

**4. Profile the boot to catch new hiccups** (see `spells/boot-profile.sh` in RaBbLE-OS):
```bash
bash spells/boot-profile.sh              # systemd-analyze time/blame/critical-chain + plymouth-quit timing
bash spells/boot-profile.sh --plot       # also write /tmp/rabble-boot-plot.svg timeline
```

## First profile — S153 findings (ProArt P16, daily driver)

`boot-profile.sh` baseline: **29.95s total** = 5.98s firmware + 4.62s loader + 1.87s
kernel + 2.62s initrd + **14.86s userspace**. `graphical.target` @9.03s (userspace);
`plymouth-quit-wait` / `sddm` landmarks @~13.5s monotonic.

Actionable (NOT yet applied — these are live-machine changes, do via Ansible + reboot-verify):

| Finding | Gating? | Recommended fix |
|---|---|---|
| `NetworkManager-wait-online.service` ~5.2s | On/near critical path (network.target → remote-fs.target showed an unexplained ~5s gap) | Disable it — a Hyprland desktop does not need `network-online.target` before login. `systemctl disable NetworkManager-wait-online.service` via the relevant Ansible role. Biggest single safe win. |
| `plymouth-quit-wait` holds splash to ~13.5s | Yes (held until sddm) | Expected to *shrink* once NM-wait-online is gone (the splash is held waiting on the same downstream chain). Re-profile after. |
| `powertop.service` ~5.8s | **No** (ran in parallel — not on critical chain) | Lower priority. If desired, convert to a post-boot `.timer` so it never competes during boot. Cosmetic to boot time. |
| `remote-fs.target` @8.85s vs `remote-fs-pre` @3.72s | Yes (~5s gap) | Investigate what orders into `remote-fs.target`; no NFS mounts exist (VM mount is local btrfs + `nofail`). Likely resolves with the NM-wait-online change. |

→ Re-run `boot-profile.sh` after each change; promote `[~]` items only once the
  Verification reboot is clean.

---

## S156 Boot-Chain Pass — Void Zone Corrections + Boot Speed

**State:** `[~]` — implemented, reboot required to verify.

### S156 Findings from first reboot (after S155)

**Plymouth animation not visible** — likely cause: `dracut --force` did not run before the S155
reboot, so the initramfs still had the old theme. Apply `layerctl apply boot` and reboot again.

**GRUB black box persisted** — Root cause revised: `GRUB_COLOR_NORMAL="black/black"` makes
text invisible BUT the gfxterm canvas itself is still opaque black (`#000000`) over the liminal
background. When GRUB loads the kernel, gfxterm fills the terminal area (potentially full-screen)
with solid black, which is visible as a sudden flash even though text is invisible. Mark confirmed
the grub-bg.png does have a void-black center — the flash is only visible in the ceiling/floor grid
areas where bright grid lines contrast against the sudden black.
**Real fix is `GRUB_TIMEOUT_STYLE=hidden` (post-EP1)** — this skips the menu entirely and GRUB
→ Plymouth with no gfxterm terminal activation. For EP1: the brief black flash during kernel
loading is accepted as-is (the background center is already void-matching).

**Boot slow (~4s in remote-fs.target)** — profiled via `boot-profile.sh`. Root cause confirmed:
`remote-fs.target After=iscsi.service`, and `iscsi.service After=network-online.target`. Even
though `iscsi.service` is conditioned out (ConditionResult=no), systemd waits for its full
`After=` chain before scheduling it. `NetworkManager-wait-online.service` provides
`network-online.target` and took 4.22s — holding `remote-fs.target` → `sddm` → `graphical.target`
the same amount of time. Fix: mask `NetworkManager-wait-online.service` + `var-lib-machines.mount`.
Both added to `roles/core/tasks/config.yml`.

**Void zone measured** — `measure-void-zone.py` run on `assets/bg-liminal.png` (1920×1200):
- Ceiling grid ends: y=438 → **35.8%** of screen height
- Floor grid starts: y=830–840 → **~68–70%** of screen height
- Void zone: **36% to 68%** — only 32% of screen height available
- Entity (460px = 42.6% at 1080p) is TALLER than the void zone — can't fully fit; glow bleeds
  into grid areas (acceptable, transparent). Key: entity FACE should be in void zone.

**SDDM entity position** — was centered at 42% (with -0.08 offset), entity frame spanning 19–65%.
Top 19–36% was in ceiling grid zone. Changed to -0.02 offset (center at 48%); entity now
spans 25–71%, face at ~39–55% — cleanly in the void zone.

**Plymouth wm_y** — was 0.28, which IS in the ceiling grid (ends at 35.8%). Changed to 0.42
(7% below ceiling). Dialog panel_y changed from 0.70 to 0.58 (floor starts at 68%).

### S156 Changes

- `roles/boot/session_manager/files/sddm-theme/Main.qml`: `verticalCenterOffset` -0.08 → -0.02
- `roles/boot/plymouth/files/rabble-aether/rabble-aether.script`: `wm_y` 0.28 → 0.42; dialog `panel_y` 0.70 → 0.58
- `roles/core/tasks/config.yml`: mask `NetworkManager-wait-online.service` + `var-lib-machines.mount`

### S156 Verification

```bash
# Apply changes:
cd ~/RaBbLE-Collective/RaBbLE-OS
bash RaBbLE-OS-layerctl.sh apply boot     # deploys SDDM/Plymouth, triggers dracut --force
bash RaBbLE-OS-layerctl.sh apply core     # masks NM-wait-online + var-lib-machines

# Pre-reboot SDDM test:
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble-aether
# → entity should be lower, face visibly in the dark void zone

# After reboot:
bash spells/boot-profile.sh              # expect remote-fs.target gap to collapse from ~4s to <0.5s
# → Plymouth animation should play (initramfs now rebuilt)
# → GRUB black flash brief but present (accepted for EP1; post-EP1 fix: GRUB_TIMEOUT_STYLE=hidden)
```

---

## S155 Boot-Chain Pass — Void Zone Layout + Entity Slide + GRUB Gfxterm Fix

**Visual plan:** `plan-96f8c3ef7a0e4f5e` (Agent-Native plan, approved)
**State:** `[~]` — partially verified (reboot confirmed system works; animation visibility TBD after S156 apply)

### Track A — GRUB gfxterm black box fix

The black box that occluded `grub-bg.png` during GRUB→Plymouth was caused by the `gfxterm`
module rendering a visible text window (default background = black) over the themed background
while executing the `linux`/`initrd`/`boot` commands.

**Changes in `ansible/roles/boot/grub2/templates/grub.j2`:**
- `GRUB_COLOR_NORMAL="black/black"` — terminal fg+bg both black: output invisible against void
- `GRUB_COLOR_HIGHLIGHT="light-magenta/black"` — selected entry highlight readable
- `GRUB_GFXMODE` default changed from `auto` to `1920x1080,1920x1200,1280x720,auto` — explicit
  fallback list prevents GOP auto-negotiation mismatch that causes transition flicker
- `GRUB_TIMEOUT_STYLE` now Jinja-templated: `{{ rabble_grub_timeout_style | default('menu') }}`
  — EP1 locks to `menu` (Recovery Mode without Shift); post-EP1 flip to `hidden` in
  `group_vars/asus_proart_p16.yml` for seamless GRUB→Plymouth (no template edit required)

**S156 note:** text invisible, but gfxterm canvas is still opaque black — the flash in grid areas
is unavoidable until `GRUB_TIMEOUT_STYLE=hidden` is set post-EP1.

### Track B — Plymouth void zone y-anchors + entity slide-to-center

**Changes in `ansible/roles/boot/plymouth/files/rabble-aether/rabble-aether.script`:**

| Constant | Was | Now | Reason |
|---|---|---|---|
| `wm_y` | `screen_h * 0.20` | `screen_h * 0.28` | wordmark was 2% inside the ceiling grid |
| `log_baseline_y` | `screen_h * 0.70` | `screen_h * 0.63` | log baseline was 4% above floor grid (tight) |
| `ready_sprite y` | `screen_h * 0.67` | `screen_h * 0.58` | ready message too close to floor grid |

> **Measure first:** `measure-void-zone.py` (new file, same directory) samples the actual
> `bg-liminal.png` pixel rows and outputs confirmed void-zone boundaries + recommended constants.
> The values above are estimates from the NeBuLA floor-grid VP at `H×0.74`. Run the script
> and adjust if the measured values differ by >3% from these estimates.

**Entity slide-to-center (committed):** When `boot_progress >= 0.97`, the entity slides from
its boot position (`screen_w×0.25`) to `screen_w×0.50` over 40 ticks (~2.4s) via a smooth-step
ease. The right section (wordmark, tagline, logs, bar, ready line) fades out in sync. Plymouth
holds the centered entity until `plymouth-quit.service` fires — SDDM takes over with the entity
already in the SDDM hand-off position. The handoff reads as a continuation, not a cut.

New files added:
- `ansible/roles/boot/plymouth/files/rabble-aether/measure-void-zone.py` — void zone measurement pre-step

### Track C — Plymouth→SDDM gap fix + SDDM layout

**Plymouth→SDDM gap:** Plymouth releases DRM when `plymouth-quit.service` fires; SDDM takes
~200–400ms to paint its first frame, causing a black flash.

**Two-pronged fix:**

1. **`ansible/roles/boot/session_manager/files/plymouth-quit-sddm.conf`** (new) — systemd drop-in
   for `plymouth-quit.service`. `ExecStartPre=/bin/sleep 0.3` gives SDDM time to render before
   Plymouth releases DRM. Tune with `boot-profile.sh` on real hardware; reduce to 0.1s if gap
   disappears, increase to 0.5s if still visible.
   Deployed to `/etc/systemd/system/plymouth-quit.service.d/sddm-first-frame.conf` via Ansible.

2. **`ansible/roles/boot/session_manager/files/sddm-theme/Main.qml`** — entity fade-in:
   `entityArea.opacity: 0` + `Behavior on opacity { NumberAnimation { duration: 500 } }` +
   `Component.onCompleted: entityArea.opacity = 1`. Entity fades in over 500ms, masking any
   residual gap between Plymouth and SDDM.

**SDDM column raised (form items too low):** The entity at 460px is confirmed in-bounds on live
hardware. The username text and password field were extending into the floor grid zone.

- `anchors.verticalCenterOffset` changed from `+parent.height * 0.03` to `-parent.height * 0.08`
  — raises the entire column 11% above center. At 1080p, passField bottom ≈ 69% screen height
  (3% margin above the floor grid at ~72%). Entity glow top reaches ~15% — transparent, blends.
- Entity size **unchanged** at 460×460px.

### Track D — Boot profiling (read-only, no changes)

Use `bash spells/boot-profile.sh` after the next reboot. Expected wins from this pass:
- GRUB→Plymouth: no black box (gfxterm fix)
- Plymouth→SDDM: 300ms pre-sleep + fade-in eliminates the black flash
- Boot timing: should be same or better; re-baseline `plymouth-quit-wait` after applying

Known bottleneck from S153: `NetworkManager-wait-online.service` (~5.2s, gating). Disable it
via Ansible — `systemctl disable NetworkManager-wait-online.service` in the relevant role.
This is the single largest safe boot-time win.

### Track E — BaBbLE boot captures

New script: `RaBbLE-BaBbLE/captures/Boot/capture-boot-sequence.sh`

Captures: GRUB theme PNG → Plymouth key frames + animated GIF → SDDM idle screenshot.
Run manually after boot changes to commit visual state to BaBbLE capture archive.
Output: `RaBbLE-BaBbLE/captures/Boot/YYYYMMDD/`

### Fork: RaBbLE Plans self-hosted server (aa474e4)

The Agent-Native Plans tool used to design this pass is now self-hosted in RaBbLE-OS.
Committed in parallel at `aa474e4` (`spark ~ os/apps >> RaBbLE Plans: self-hosted visual plan
server with Aether theme + /_rabble/mcp`). New Ansible role `ansible/roles/apps/plans/`:
- Scaffolds at `/opt/rabble/plans/` via `npx @agent-native/core@latest create . --standalone`
- Aether theme injected via `blockinfile` into `global.css`
- User systemd service on port 3001; nginx proxies at port 3000 with `/_rabble/` prefix
- MCP config injected into `~/.claude/claude_code_config.json` so Claude Code picks it up
- Tag: `ansible-playbook site.yml --tags plans`

### Verification additions for S155

Add to the Verification reboot checklist:

- [ ] **GRUB**: no black/white text box appears over `grub-bg.png` during menu countdown
- [ ] **GRUB→Plymouth**: screen dims cleanly (no text artifacts) → entity emergence begins
- [ ] **Plymouth y-anchors**: wordmark sits visibly below ceiling grid (no clipping); log lines and ready message sit above floor grid
- [ ] **Plymouth completion**: at ~97% progress, entity slides from left quarter to center; wordmark/logs/bar fade out in sync (~2.4s animation)
- [ ] **Plymouth→SDDM**: no black flash (or < 100ms if still barely visible); entity fades in smoothly
- [ ] **SDDM**: password field sits visibly above floor grid (clock + entity + username + passField all in void zone)
- [ ] Boot profile: run `bash spells/boot-profile.sh` and record `plymouth-quit-wait` time; compare to S153 baseline (13.5s monotonic)

→ `layers/RaBbLE-OS-Layer-Boot.md` — boot layer role structure
→ `layers/RaBbLE-OS-Layer-Boot-Plymouth-EP1.md` — Plymouth EP1 refinement spec
→ `desktop/RaBbLE-OS-Desktop-BootFlow.md` — per-stage config detail
→ `fix/RaBbLE-OS-KnownIssues.md` — active bugs
