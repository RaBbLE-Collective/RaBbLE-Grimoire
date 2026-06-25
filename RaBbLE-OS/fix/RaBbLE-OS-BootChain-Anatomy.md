# RaBbLE-OS Boot Chain — Anatomy & Root-Cause Ledger

**Purpose:** the *understanding* layer for the boot effort. Where `RaBbLE-OS-Fix-BootChain.md`
is a chronological fix log, this is the durable mental model: how the boot pipeline actually
works on this hardware, what every visible artifact is *mechanically*, and which theories have
been **proven wrong** so no future session re-chases them.

**Hardware (this matters — most of the pain is hardware-specific):**
ASUS ProArt P16. APU **AMD Ryzen AI 9 HX 370** with **Radeon 890M** iGPU (RDNA 3.5, display
block **DCN 3.5**, `amdgpu` PCI `0000:65:00.0`). Discrete **NVIDIA RTX 4060** (`0000:64:00.0`).
NPU **XDNA2** (`amdxdna 0000:66:00.1`). Panel is **3840×2400 eDP**. Dual-GPU via
`vga_switcheroo` (ATPX Hybrid Graphics).

> ⚠ **The laptop panel `eDP-1` hangs off the AMD iGPU** (`card1`). NVIDIA (`card0`, exposes
> only external DP/HDMI) drives **no** internal display and is **deferred out of the initramfs**
> (`rd.driver.blacklist=nvidia`), loading only after SDDM. Every boot-visual problem is an
> **amdgpu + framebuffer-handoff** problem, not an NVIDIA problem.

**The North Star:** GRUB → Plymouth → SDDM should read as **one continuous liminal scene** —
the same `RaBbLE_boot_Liminal_BG.png` carried across all three stages, the entity centred, no
flashes, no black, no resolution churn. "Seamless and uniform."

---

## 1. The complete boot pipeline (with measured timings)

Timings are **monotonic seconds** from a clean S172 boot (`RaBbLE-BaBbLE/tmp/boot-grub-probe.txt`).
Use monotonic, **not** wall-clock: systemd corrects the RTC mid-boot, so `journalctl` wall-clock
timestamps **jump ~4 hours** partway through. That jump is a timezone correction, not a hang.

| Stage | ~T | What happens | What's on screen |
|---|---|---|---|
| **Firmware / UEFI** | pre-0 | POST; UEFI GOP sets a framebuffer; **BGRT** table = OEM ASUS logo | ASUS logo |
| **GRUB** | pre-0 | `gfxterm` at native 4K (`gfxmode=3840x2400x32`), theme + menu drawn | liminal GRUB menu |
| **GRUB → kernel** | 0 | GRUB sets `GFXPAYLOAD=3840x2400x32`, loads kernel+initrd, prints "Loading…" | **(GRUB box — §3.1)** |
| **Kernel early** | 0–1.7 | kernel unpacks, `quiet rhgb` suppresses text | GOP fb (static) |
| **simpledrm** | **1.705** | builtin `simpledrm` binds the EFI fb @ native 4K (`Console: switching to colour frame buffer device 480x150` = 3840×2400 ÷ 8×16 font) | fb live |
| **plymouth-start** | 2.29 → 3.34 | `plymouthd` launches, opens the DRM device (**simpledrm**), starts drawing | **Plymouth entity animates** |
| **switch-root** | 3.42–3.48 | initramfs → real rootfs; plymouth persists across it | Plymouth continues |
| **amdgpu probe** | **4.174** | `amdgpu` begins KMS modeset (`IP DISCOVERY … 0x150E`) | Plymouth (still simpledrm) |
| **dummy switch** | **4.233** | `Console: switching to colour dummy device 80x25` — **fbcon detaches; CRTC dropped** | **★ BLACK** |
| amdgpu firmware | 4.23–4.50 | DMUB / PSP / VBIOS / SMU load (~2.5 s of the delay above) | black |
| **DC up** | 4.506 | `Display Core v3.2.369 initialized on DCN 3.5`; eDP-1 PSR detected (4.567) | — |
| **amdgpu fb** | **4.583** | `amdgpudrmfb (fb0) is primary`; `Console: switching to colour frame buffer device 480x150` | amdgpu fb live |
| **Plymouth migrate** | 4.58→ | plymouthd must **drop simpledrm and re-open amdgpu**, rebuild its renderer | black → splash returns |
| **plymouth-quit / SDDM** | later | `plymouth-quit` (0.3 s pre-sleep) hands to SDDM greeter | SDDM |
| **nvidia-load** | 6.2–7.5 | dGPU loads *after* SDDM (`nvidia Cannot find any crtc` = expected, no panel) | — |

**The two facts that explain almost everything:**
1. **Two DRM devices come up in sequence** — `simpledrm` (instant, T+1.7) then `amdgpu`
   (T+4.2, slow). They are *different* devices (minor 0 vs minor 1).
2. **amdgpu is slow on purpose** — ~2.5 s of it is firmware loading (DMUB/PSP/VBIOS/SMU).
   simpledrm always wins the early race because it does nothing but map the existing fb.

---

## 2. The framebuffer / DRM model (why a "handoff" exists at all)

- **GOP framebuffer (firmware):** a dumb linear buffer the UEFI GOP driver set up. GRUB and the
  early kernel scribble on it directly. It survives until a real DRM driver reprograms the display.
- **simpledrm:** a *builtin* kernel DRM driver that wraps the existing GOP fb so userspace gets a
  real `/dev/dri/card` early, before the GPU's own driver is ready. It cannot modeset, change
  resolution, or accelerate — it just presents the firmware buffer. **Builtin** = compiled into
  the kernel (in `modules.builtin`), so it can't be `modprobe`-blacklisted; only
  `initcall_blacklist=simpledrm_platform_driver_init` disables it.
- **amdgpu:** the real GPU driver. When it initialises it **takes the CRTC** (the display
  controller) and does a full modeset on eDP-1. At that instant the previous scanout source
  (simpledrm's view of the GOP buffer) is no longer being displayed.
- **fbcon vs DRM clients:** `fbcon` is the *text console* layered on a framebuffer. Plymouth is
  **not** fbcon — it's a DRM client drawing directly. When amdgpu appears, fbcon is moved from
  simpledrm → `dummy device 80x25` (no output) → amdgpudrmfb. That `dummy` step is a momentary
  console blank. Plymouth, independently, has to **migrate** its renderer from the simpledrm DRM
  node to the amdgpu DRM node. Both transitions land in the same ~350 ms window, but Plymouth's
  renderer rebuild + amdgpu's first panel modeset (PSR/backlight settle) stretch the *perceived*
  black to ~1–2 s.

This is the "handoff." It is intrinsic to having simpledrm + a slow real GPU. The only ways to
remove it are: (a) make the handoff truly seamless (amdgpu preserves the buffer — **doesn't work
here, §4.3**), or (b) **don't have two devices** — suppress simpledrm so amdgpu is the only one (§5).

---

## 3. The visual artifacts, mechanically

### 3.1 GRUB "black box after the menu disappears" — `[OPEN]`
Appears **before** the kernel, so nothing kernel-side (simpledrm, amdgpu, Plymouth) can cause or
cure it. Current knowns: GRUB menu **and** payload are both native 4K (`gfxmode` =
`GFXPAYLOAD` = `3840x2400x32`), so the old **mode-switch** cause (§3.2) is gone. Leading
hypotheses, not yet disambiguated (needs Mark's eyes — an agent shell can't see the GRUB phase):
- **(a) gfxterm load-message area:** after selection GRUB prints `Loading Linux… / Loading initial
  ramdisk…`. With `GRUB_COLOR_NORMAL="black/black"` the text is invisible, but gfxterm may clear
  its console region to `desktop-color` (#0a0010 ≈ black) over the liminal bg = a black rectangle.
- **(b) theme→console viewport clear:** GRUB tears down the themed `boot_menu` and the bg image
  is replaced by the void color for the load phase.
- **(c) GRUB→simpledrm gap:** the ~1.7 s where the kernel owns the GOP fb under `quiet rhgb`
  (no text) before simpledrm/Plymouth — could read as a black hold.
> **Diagnostic needed:** is it full-screen or a rectangle (bg still visible around it)? Any faint
> text? Full-screen→(b/c); rectangle→(a). **Important interaction:** once simpledrm is suppressed
> (§5), whatever GRUB leaves on screen is **held ~2.5 s** until amdgpu — so the GRUB-frame fix
> (make GRUB's final frame the liminal bg, not a black console) is the *complement* that completes
> the seamless chain.

### 3.2 simpledrm "black pane over 75% of the screen" — `[FIXED S153]`
With `GFXPAYLOAD=keep`, the kernel inherited GRUB's *menu* mode (1920×1200) instead of native 4K.
simpledrm came up at 1920×1200 and was painted 1:1 in the **top-left quarter** of the 3840×2400
panel (1920×1200 is exactly ¼ the area) — leaving 75 % black until amdgpu modeset to native.
**Fix:** pin `GFXPAYLOAD=3840x2400x32` so simpledrm fills the panel. Confirmed: console comes up
`480x150` = 3840×2400. Do not revert to `keep`.

### 3.3 Mid-Plymouth ~1–2 s black — `[FIX STAGED S172]`
The §2 handoff. Plymouth draws on simpledrm (T+1.7→4.2), amdgpu takes the CRTC (T+4.2), the
console drops to the dummy device (T+4.23), and Plymouth must migrate to amdgpu. **Fix:** §5.

### 3.4 "Accelerated / sped-up" animation after the black — `[FIX = §5 removes the freeze]`
The splash animation is **tick-based** (`refresh_callback` increments a counter ~50/s; wordmark
fade, log reveal, entity frame, and progress easing are all functions of that tick). During the
1–2 s migration freeze, **boot keeps progressing** but the splash is stalled. When it recovers,
`boot_progress` has jumped, so the eased progress bar races to catch up and the slide-to-centre
fires almost immediately — reads as "fast/jumpy." Removing the freeze (§5) removes the catch-up.
(There is no wall-clock time source in Plymouth's script language, so tick-based animation can't
be made freeze-proof directly — eliminating the freeze is the real fix.)

### 3.5 Plymouth → SDDM gap — `[MITIGATED]`
`plymouth-quit.service` has a 0.3 s `ExecStartPre=/bin/sleep` so SDDM paints its first QML frame
before Plymouth releases DRM. Without it there's a 200–400 ms black at the greeter handoff. Tune
with `boot-profile.sh`. SDDM uses the same liminal bg + centred entity, so a clean handoff is a
visual continuation.

---

## 4. Root-cause ledger — DISPROVEN theories (do not re-chase)

> Five-plus sessions were spent on the boot black. The recurring failure mode was **theorising
> from an agent shell instead of reading a real boot log**, and **promoting `[~]` (written) to
> `[x]` (verified) without a reboot**. Every entry here cost a cycle. Read before touching cmdline.

### 4.1 The ternary-operator compile bug — `[ROOT CAUSE of the total-black era, FIXED S166]`
`rabble-aether.script` had `t = (t_raw > 1.0) ? 1.0 : t_raw;`. **Plymouth's script language has no
`?:` operator.** Plymouth compiles the script as one unit, so this single line made the **entire
theme fail to load → nothing rendered → black**. This is why *every* prior DRM experiment "stayed
black" regardless of setting: Plymouth had no program to run. Fixed with an `if`. Lesson: when the
splash is *totally* black (not a handoff flash), suspect a **script compile error** first —
`plymouthd --debug` logs the parser error with a line number.

### 4.2 `plymouth.use-simpledrm=1` pin — `[DISPROVEN, REMOVED S165]`
Theory (S160): pin Plymouth to simpledrm so it wins the early race. Reality: it **locks** Plymouth
to the simpledrm buffer; when amdgpu modesets and takes the CRTC, simpledrm's scanout goes dark
while Plymouth keeps drawing to the now-invisible surface → **permanent black**. The opposite of
helpful. (The S160 "verified broken without it" conclusion was confounded by a **stale initramfs** —
the dracut `--force` handler wasn't firing until S162, so nothing it toggled actually took effect.)

### 4.3 `amdgpu.seamless=1` — `[DISPROVEN with direct evidence, REMOVED S172]`
Theory (S167): amdgpu's seamless-boot keeps the firmware framebuffer live during KMS so the
handoff is invisible. **Evidence it does nothing here** (S172 clean boot):
- `/sys/module/amdgpu/parameters/seamless == 1` (param *is* loaded), **yet**
- amdgpu logs **no** seamless-boot decision at all, **and**
- the `Console: switching to colour dummy device 80x25` blank **still happens** (T+4.233).

The S167 "confirmed working" note was a **false positive** (likely a boot where the change hadn't
actually rebuilt/landed). Seamless boot is **unimplemented or ineffective for DCN 3.5** (Ryzen AI 9
HX 370 / Radeon 890M) on kernel 7.0.x. **Do not re-add it.** Geometry already matches (simpledrm
and amdgpu are both native 4K), so a geometry mismatch is *not* the reason — the feature simply
no-ops on this silicon.

---

## 5. Current strategy (S172): eliminate the handoff, don't fix it

Since amdgpu can't make the two-device handoff seamless, **remove the second device.** simpledrm
is builtin, so:

```yaml
# group_vars/asus_proart_p16.yml → rabble_grub_extra_cmdline
initcall_blacklist=simpledrm_platform_driver_init
```

**Effect:** simpledrm never binds. amdgpu is the **only** DRM device. No second device → no
migration → no dummy-device blank → no animation catch-up. Plymouth waits for amdgpu (it polls
udev for DRM devices) and draws **once**, cleanly, all the way into SDDM.

**Trade-off:** Plymouth now starts ~2.5 s **later** (when amdgpu is ready, ~T+4.2) instead of
starting on simpledrm at T+1.7 and then blacking out. During that window the **GOP framebuffer —
GRUB's last 4K frame — holds statically**. Net: **no flash, no speed-jump**, but a longer *still
frame* up front. This is why §3.1 (the GRUB frame) now matters more: the still frame should be the
liminal bg, so the hold reads as intentional, not broken.

**Revert:** delete the `initcall_blacklist` token and `apply boot` + reboot — simpledrm returns.

**Risk:** with simpledrm gone, if amdgpu ever fails to load there is no early framebuffer for
recovery (the rescue BLS entry inherits the same cmdline). amdgpu is reliable here and is
force-loaded into the initramfs (`dracut: add_drivers+=amdgpu`), so the risk is low — but it is the
reason this is a deliberate, documented choice rather than a default.

---

## 6. Uniformity: one image across the chain

`build-assets.sh` derives **all three** backgrounds from a single source
`RaBbLE-BaBbLE/RaBbLE_boot_Liminal_BG.png`:
- **GRUB:** `grub-bg.png` (RGB, ≤24bpp per GRUB) → `theme.txt desktop-image`
- **Plymouth:** `bg-liminal.png` (RGBA) → drawn at z=1
- **SDDM:** `assets/bg.png` (RGB)

The liminal source **already contains a floor grid** (see `measure-void-zone.py`, which detects
its ceiling/floor extents to anchor the Plymouth log baseline). The Plymouth theme's old
*software-drawn* cyan/magenta perspective grid was therefore **redundant** (double grid) and was
**removed S172** — the scene now relies entirely on the shared image, which is what makes the chain
uniform.

---

## 7. Plymouth theme layout knobs (S172)

All in the `LAYOUT CONSTANTS` block at the top of `rabble-aether.script` (fractions of screen
W/H, so they scale 720p→4K):
- **`WM_CX_FRAC`** — centre-X of the whole right-hand text column (wordmark, tagline, bar, %,
  ready). `-1` = auto (≈0.69, right-of-centre). Lower = slide the column **left** toward the
  entity. Set **0.62** at S172. The boot **log stays left-aligned** (unaffected).
- **`LOG_WINDOW`** — max log lines kept fully visible before older ones fade out. Set **5**.
  Previously the fade only began past **12** lines, so ~13 lines stacked up and **climbed into the
  wordmark band** — the overlap bug. With 5, the log band stays well below the wordmark.

---

## 8. How to diagnose the boot (methodology)

- **You cannot see the boot from an agent shell.** Plymouth needs DRM master, which Hyprland holds.
  GRUB/early-kernel are pre-session. So: pull **logs**, and for anything visual, have Mark **reboot
  and report**, or run `spells/test-plymouth.sh` from a bare VT.
- **Read a real boot log, don't theorise.** The one-shot probe `RaBbLE-BaBbLE/tmp/boot-grub-probe.sh`
  (run with sudo) dumps `/etc/default/grub`, `grub.cfg`, BLS entries, deployed theme, full early-DRM
  `dmesg`, and any amdgpu seamless decision into a file an agent can read.
- **Use monotonic time** (`journalctl -k -b -o short-monotonic` / `dmesg`) — wall-clock jumps ~4 h
  mid-boot (RTC/UTC correction), which looks like a hang but isn't.
- **Key log signatures:**
  - `Console: switching to colour frame buffer device 480x150` → simpledrm/amdgpu fb up @ 4K
  - `Console: switching to colour dummy device 80x25` → **the blank** (CRTC dropped during modeset)
  - `amdgpudrmfb (fb0) is primary device` → amdgpu has the panel
  - `Display Core v3.2.369 initialized on DCN 3.5` → amdgpu DC ready
  - parser error w/ line number in `plymouthd --debug` → **script compile failure** (total black)
- **Confirm the heavy handlers actually ran** after `apply boot`: initramfs rebuild (`dracut -f`)
  and `grub2-mkconfig`. A change that didn't rebuild the initramfs is invisible at reboot — this
  burned multiple sessions (§4.2).

---

## 9. Open questions / next

1. **GRUB box (§3.1)** — needs Mark's phase-1 observation (full-screen vs rectangle vs faint text)
   to pick the fix. Likely candidates: keep gfxterm on the themed bg for load messages, or
   `GRUB_TIMEOUT_STYLE=hidden` to minimise GRUB's on-screen time (the repo's own post-EP1 note).
2. **Verify §5** — does suppressing simpledrm actually remove the black + jump on a real reboot,
   and is the up-front static hold acceptable / is it the liminal bg or a black frame?
3. **4K asset masters** — entity/wordmark PNGs are 1920-class; they upscale (soft) at 4K. Regenerate
   `build-assets.sh` captures at 4K for crisp sprites (separate visual-polish pass).
4. **plymouth-quit timing** — re-profile with `boot-profile.sh` after §5; the 0.3 s SDDM pre-sleep
   may be tunable down.

---

*Companion: `RaBbLE-OS-Fix-BootChain.md` (chronological fix log) · `RaBbLE-OS-KnownIssues.md` ·
`log/plans/OS-Plymouth-Black-Screen.md`. Cross-link, don't duplicate — this file is the model;
those are the work.*
