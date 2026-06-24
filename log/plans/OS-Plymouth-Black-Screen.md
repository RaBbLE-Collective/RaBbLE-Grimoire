# Plan: Plymouth Boot Splash Black Screen

**Status:** UNRESOLVED — both simpledrm-pin states (on & off) verified BLACK on real hardware. Root cause not yet captured. `plymouth:debug` now armed; awaiting first instrumented reboot.
**Repo:** RaBbLE-OS `new-horizons` · **Last touched:** S166 (2026-06-24)
**Hardware:** ASUS ProArt P16 — dual-GPU. `card0`=NVIDIA RTX 4060 (blacklisted in initramfs), `card1`=AMD 890M. **Laptop panel `card1-eDP-1` is on the AMD GPU.**

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
