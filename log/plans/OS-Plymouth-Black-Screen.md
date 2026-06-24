# Plan: Plymouth Boot Splash Black Screen

**Status:** 🎯 ROOT CAUSE FOUND (S166) — theme script had an unsupported ternary operator at L460, failing to compile → nothing rendered. Fix applied to source. **AWAITING visual verify** (deploy + reboot + see the splash) before marking DONE.
**Repo:** RaBbLE-OS `new-horizons` · **Last touched:** S166 (2026-06-24)
**Hardware:** ASUS ProArt P16 — dual-GPU. `card0`=NVIDIA RTX 4060 (blacklisted in initramfs), `card1`=AMD 890M. **Laptop panel `card1-eDP-1` is on the AMD GPU.**

---

## 🎯 ROOT CAUSE (S166, first real-boot debug log)

The first-ever boot with `plymouth:debug` set produced a fresh log naming the exact failure:

```
Parser error ".../rabble-aether.script" L:460 C:22 : Expected ';' after an expression
Parser error ".../rabble-aether.script" L:460 C:22 : Expected a '}' to terminate the operation block
Parser error ".../rabble-aether.script" L:460 C:22 : Unparsed characters at end of file
```

**Line 460 was:** `t = (t_raw > 1.0) ? 1.0 : t_raw;`

**Plymouth's script language has no ternary `?:` operator.** The parser reads `t = (t_raw > 1.0)`,
expects a `;`, hits `?`, errors, and — because plymouth compiles the script as a single unit —
**the entire script fails to load and nothing renders → black screen.** The cascade `}` errors are pure
fallout from the same line. (The `Could not initialize heads` DRM line is a *separate* second-order risk —
see the DRM handoff section below; it did not cause the black screen but may surface once the script compiles.)

**Why every prior session was black regardless of GPU config:** the script never compiled on ANY boot, so
the simpledrm pin (on or off), the initramfs contents, GFXPAYLOAD, etc. were all irrelevant — Plymouth had
no program to run. Five sessions of DRM theorizing chased a symptom; the bug was one unsupported operator.

**Fix (applied to source `rabble-aether.script`):**
```
t = t_raw;
if (t > 1.0) t = 1.0;
```
Verified: it was the ONLY `?` in the 492-line file; braces/parens balance (32/32, 305/305); all `i++`
are standard for-loop increments (supported). No other unsupported constructs.

### Deploy + verify (Mark)
```bash
cd ~/RaBbLE-OS && sudo ./RaBbLE-OS-layerctl.sh apply boot   # redeploy script + rebuild initramfs
sudo reboot                                                  # WATCH — splash should now animate
sudo bash spells/boot-diagnose.sh                            # confirm: no parser errors in the log
# once the splash is confirmed rendering:
sudo bash spells/boot-debug-toggle.sh --off && sudo ./RaBbLE-OS-layerctl.sh apply boot   # drop debug flag
```

**LESSON:** plymouth `.script` is NOT JavaScript — no ternary, no compound-assign. A syntax error anywhere
silently black-screens the whole splash. Add a parse-check to the theme build before shipping. Mirror to
the `add_drivers`/`force_drivers` note below only if a DRM issue surfaces AFTER the script compiles.

---

## DRM handoff — does amdgpu hold Plymouth the whole time? (S166 — open second-order risk)

**No, not in the current config.** With the simpledrm pin removed and amdgpu loaded via `add_drivers`
(present in initramfs but *probed late*), the boot still goes through a **simpledrm → amdgpu handoff**, and
the S166 debug log captured the handoff disrupting Plymouth's device. Wall-clock reconstruction (plymouthd
`00:00:00` ≈ 09:03:02):

| time | event |
|---|---|
| 09:03:03 | simpledrm registers from EFI GOP → `minor 0`, `fb0` |
| 09:03:04 | `plymouth-start.service` runs → plymouthd binds the only DRM device present = **simpledrm** |
| 09:03:05–06 | **amdgpu** finishes KMS modeset, takes over `fb0` |
| `00:00:05.787` (~09:03:07) | `Could not deallocate GEM object 1: No such device` ← simpledrm buffer invalidated by the takeover |
| `00:00:07.599` (~09:03:09) | `Could not initialize heads` → `could not find suitable rendering plugin` ← Plymouth tried to rebind post-handoff and **failed** |

So amdgpu only "holds" Plymouth from the moment it grabs `fb0` (~3s in) — **not from frame one.** simpledrm
always registers first (kernel-init EFI framebuffer, before any module), and `add_drivers` amdgpu is probed
~3s later by udev coldplug, so it displaces simpledrm mid-splash.

**Crucial caveat:** every one of those DRM errors fired *after* the script had already failed to compile, so
Plymouth wasn't holding the device the way a live splash would. We genuinely don't know yet whether a WORKING
splash survives the handoff. The verify reboot decides:
- **Splash animates cleanly start→finish** → handoff is graceful, Plymouth rebinds amdgpu fine. DONE.
- **Splash plays ~3s then goes black** (at the amdgpu takeover) → the handoff is a real second bug.

**Remedy if outcome #2:** eliminate the handoff by force-loading amdgpu in the initqueue so its KMS is up
before `plymouth-start` — change `add_drivers+=" amdgpu "` → **`force_drivers+=" amdgpu "`** in
`/etc/dracut.conf.d/90-rabble-plymouth-fonts.conf` (sourced from `roles/boot/plymouth/tasks/config.yml`).
Then amdgpu owns the panel from frame one and Plymouth never touches simpledrm. (Do NOT re-add the simpledrm
pin — that's the opposite approach and is already disproven for this hardware.)

### "Can we defer the amdgpu handoff to the SDDM transition to hide it?" (Mark, S166)

Goal is right (the only visible switch should be the Plymouth→SDDM transition), but you get there by moving
amdgpu **earlier**, not later — amdgpu **cannot** be deferred to SDDM:

- **amdgpu IS the display GPU** (`card1-eDP-1` panel). SDDM's greeter + Hyprland both need a rendering GPU.
  Defer amdgpu's modeset to the SDDM transition and SDDM must come up on simpledrm/llvmpipe (software), and
  amdgpu still has to modeset before Hyprland → you relocate the flash to SDDM→Hyprland, not hide it.
- The **nvidia** deferred-load trick (`nvidia-load.service` after SDDM, see `roles/hardware/.../nvidia.yml`)
  works only because nvidia drives **no display** (offload/compute). amdgpu is the opposite — it's the panel.
- amdgpu modesets **when it initializes**, not when Plymouth quits; you can't decouple modeset from load
  without deferring the load (which breaks SDDM). Decoupling is what the disproven `use-simpledrm` pin faked.

**Three levers that actually deliver "no noticeable switch" — only the Plymouth→SDDM transition is seen:**
1. **amdgpu first** — `force_drivers+=" amdgpu "`: KMS live before `plymouth-start`; no simpledrm→amdgpu switch during the splash.
2. **Identical mode end-to-end** — `GFXPAYLOAD=3840x2400x32` (already set) makes GRUB/simpledrm/amdgpu all native 4K, so the firmware→amdgpu modeset is a visual no-op. Biggest single factor.
3. **Plymouth→SDDM already seamless** — `roles/boot/session_manager/files/plymouth-quit-sddm.conf` (`sddm-first-frame.conf`) holds the DRM framebuffer 300ms until SDDM paints its first frame.

**Sequencing:** verify the *script fix* first. If the splash already animates cleanly, the handoff is graceful
— do NOT add `force_drivers` (don't optimize a flash that isn't there). Apply lever 1 only if the verify
reboot shows a black at ~3s. Levers 2+3 are already in place.

---

---

## ⚠ THE HARD RULE (kill the "pending" pattern)

This splash has been "fixed" across **seven** sessions (S149, S153, S155, S156, S160, S162, S165), each
diagnosing a *different* root cause, each committed, each marked **"reboot-verify pending"** — all still
black. **The disease is methodology, not config: blind fixes verified by nobody who can see the screen.**

> **No Plymouth change is marked `[x]` DONE without a pasted real-boot debug log OR a photo of the splash.**
> Offscreen / agent-shell tests are `[~]` partial only. No exceptions.

---

## What is DISPROVEN (evidence, not theory)

| Hypothesis | Sessions | Verdict |
|---|---|---|
| Theme/assets missing from initramfs | S149–S156 | Ruled out — `boot-diagnose.sh` confirms 160 theme files, `script.so`, amdgpu all present in initramfs. |
| Stale initramfs (dracut --force never fired) | S162 | Real bug, fixed S162. Initramfs now rebuilds. But splash STILL black after → another layer. |
| `plymouth.use-simpledrm=1` REQUIRED (pin Plymouth to EFI fb) | S160→S164 | **Black WITH the pin.** (S160 conclusion was confounded — ran on stale initramfs.) |
| `plymouth.use-simpledrm=1` is the CAUSE — drop it, bind amdgpu native | S165 | **Black WITHOUT the pin too** (verified S166, Mark rebooted). |

**Conclusion (S166): the simpledrm pin is NOT the determining variable.** Neither state renders. The real
cause is elsewhere and has never been captured because **no boot has ever run with `plymouth:debug` set** —
including S165's "verify" reboot. (S165 built `boot-debug-toggle.sh` but never ran `--on` before the reboot,
which is exactly why today's `boot-diagnose.sh` found only a 2-day-stale log. S166 armed the flag.)

---

## Live ground truth (S166 boot-diagnose, current config = pin OFF)

- cmdline: `... rhgb quiet rd.plymouth=1 plymouth.enable=1 loglevel=3 ... fbcon=nodefer fbcon=font:TER16x32 vt.global_cursor_default=0 rd.driver.blacklist=nvidia rd.udev.log_level=3` — **no `plymouth:debug`, no simpledrm pin.**
- Theme set + present: `plymouth-set-default-theme` → `rabble-aether`; 160 files + `script.so` + amdgpu in initramfs.
- `/etc/plymouth/plymouthd.conf` → `[Daemon] Theme=rabble-aether` ✓.
- `default.plymouth` symlink **absent** — only matters on the text-fallback path, not the configured theme.
- `journalctl -b 0 -t plymouthd` → **empty** (plymouthd writes nothing without `plymouth:debug`). This is WHY logs read "stale."
- DRM timing (from stale-log boot): **simpledrm at t+0 (minor 0), amdgpu modeset at t+3s** → a ~3s simpledrm→amdgpu handoff window exists.
- Stale debug log (2 days old) showed: DRM renderer `Could not initialize heads` → frame-buffer renderer also failed → `could not find suitable rendering plugin` → text-splash fallback. **Do NOT trust this is the current failure** — it predates the pin removal.

---

## NEXT ACTION — the conclusive reboot (do this first)

`plymouth:debug` is already added to `group_vars` (S166, via `boot-debug-toggle.sh --on --no-apply`).
Land it and reboot:

```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
sudo ./RaBbLE-OS-layerctl.sh apply boot     # writes cmdline → GRUB, rebuilds initramfs
sudo reboot                                  # WATCH the screen through the splash
# after login:
sudo bash spells/boot-diagnose.sh            # now captures a FRESH /var/log/plymouth-debug.log
sudo bash spells/boot-debug-toggle.sh --off  # revert the diagnostic flag once cause is known
```

Both outcomes advance us:
1. Splash plays → done (revert debug flag, log it, mark `[x]` with the evidence).
2. Still black → the fresh log names the exact failure (DRM bind / mode / script error / asset).

---

## Decision tree on the fresh evidence

- **Log shows a script/`Image()` error** → theme-script bug; fix the named line in `rabble-aether.script`, redeploy.
- **Log shows Plymouth bound a DRM device but nothing rendered** → display/mode issue. Probe: temporarily
  `plymouth-set-default-theme spinner` + reboot. Spinner ALSO black → pure DRM/cmdline problem; spinner works → rabble-theme/asset problem.
- **Log shows `Could not initialize heads` again (DRM renderer can't bind)** → the amdgpu CRTC isn't ready when
  plymouth-start runs. **Leading untested fix (S166):** amdgpu is `add_drivers` (in initramfs, probed *late* —
  the 3s gap) not `force_drivers` (force-loaded at frame one). Try `force_drivers+=" amdgpu "` in
  `/etc/dracut.conf.d/90-rabble-plymouth-fonts.conf` so amdgpu KMS is up before simpledrm hands off — eliminates the window.
- **No fresh debug log AND kernel text visible** → plymouth-start isn't displaying at all; inspect
  `journalctl -b 0 -u plymouth-start`.

---

## Untested levers (for after the debug log narrows it)

1. **`force_drivers+=" amdgpu "`** (vs current `add_drivers`) — force early amdgpu KMS, kill the simpledrm window. **← leading candidate.**
2. Drop `rhgb quiet` for one diagnostic boot — if the failure is deeper than Plymouth (KMS hang), kernel text shows instead of pure black.
3. Stock `spinner` theme probe — partitions theme-bug vs DRM-bug.
4. Create the `default.plymouth` symlink — low-probability, only the text-fallback path.

## Reusable spells (created S165, committed S166)
- `spells/boot-diagnose.sh` — evidence capture + PASS/FAIL heuristics from the boot that just happened.
- `spells/boot-debug-toggle.sh` — `--on`/`--off`/`--status` for the `plymouth:debug` cmdline flag (`--no-apply` for non-root edit).

## Deliberately NOT touching
Layout / void-zone / scaling / wordmark sizing — cosmetic, irrelevant while the screen is black. Make it render first.
