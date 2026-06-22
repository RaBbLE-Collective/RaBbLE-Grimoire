# RaBbLE-OS-Fix-BootChain.md — fix/boot-chain

**Branch:** `RaBbLE-OS-New-Horizons`
**State:** `%REFINING%`
**Goal:** Unified boot-chain theming — GRUB→Plymouth→SDDM reads as one continuous liminal performance using the Liminal_BG canvas across all stages.

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

→ `layers/RaBbLE-OS-Layer-Boot.md` — boot layer role structure
→ `layers/RaBbLE-OS-Layer-Boot-Plymouth-EP1.md` — Plymouth EP1 refinement spec
→ `desktop/RaBbLE-OS-Desktop-BootFlow.md` — per-stage config detail
→ `fix/RaBbLE-OS-KnownIssues.md` — active bugs
