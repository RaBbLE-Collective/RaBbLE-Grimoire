# Plan: ProArt P16 — Hyprland GPU Load, Real Power Stack, Profiling, Settings App

**Status:** 🟡 PLANNED — Opus-reviewed and corrected, not yet implemented
**Repo:** RaBbLE-OS `new-horizons` · **Last touched:** 2026-07-04
**Goal:** Stand up a repeatable power-profiling spell, cut Hyprland/AMD-iGPU compositor GPU load, land the NVIDIA D3cold idle-power fix, and turn the dormant `tuned`+`asusd` power-stack scaffold into a real 3-mode waybar control (quiet+low-power / quiet+balanced / unbounded-AC-only). A settings-app design sketch is included but deliberately deferred to its own follow-up plan.

---

## Context

Mark reports Hyprland eating a lot of GPU on the ProArt P16, and wants four things:
1. GPU/power profiling set up
2. The NVIDIA dGPU properly suspended (idle draw)
3. A waybar power-profile control with three real modes: quiet+low-power, quiet+balanced, and unbounded (AC-only, no fan/noise restriction)
4. A RaBbLE-OS settings app for tweaking waybar/Hyprland/other RaBbLE-OS features

Investigation shows this isn't a from-scratch build — it's **finishing dormant, already-designed scaffolding**. The Ansible role for the ASUS hardware profile already declares the intended architecture (`power_stack_profile`, `asusctl.yml`, `asusd.yml`, `tuned.yml`, `arbitration.yml` all exist) but every power-stack task file is a literal `%DORMANT%` no-op stub. `supergfx.yml` (GPU mode switching) is the one sibling task that's already real/implemented — don't touch it. The canonical power-stack decision is already recorded in `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-AgentGuide.md:64-66`:

> `tuned`+`tuned-ppd` is the canonical power stack — never install `power-profiles-daemon` (conflicts; `tuned-ppd` exposes the same D-Bus API `asusctl` needs).

Separately, `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-Fix-Nvidia.md` documents (but doesn't fully implement) the D3cold idle-power fix for the NVIDIA dGPU. And `RaBbLE-OS/config/hypr/conf.d/look.conf` has global blur + shadows + translucency enabled on every window at 3840×2400 on the AMD iGPU — the likely source of the reported GPU load.

Per Mark's decisions this session: the settings app will be a **local Aether-themed web app** (not GTK4 — libadwaita theming is a known limitation already hit by `qt-gtk-theme.yml` — and not a TUI, since a web app carries RaBbLE-OS's actual visual identity), and the power-profile work **will** implement real fan-curve control via `asusctl` working together with `tuned` (Fedora 43's actual default, per Mark and `AgentGuide.md`) — not `power-profiles-daemon` directly.

**This plan covers Phases 1–4.** Phase 5 (the settings app) is design-sketch only and gets its own dedicated Grimoire plan doc before a follow-up session implements it.

**Reviewed by Opus (2026-07-04)** — corrections from that review are folded into the phases below (see per-phase notes). Original review flagged: a Phase-B package gap that would make the NVIDIA fix silently no-op, a wrong assumption about how asusd fan curves couple to `tuned-ppd`, a mischaracterization of the current waybar wiring, and a profiling/fix ordering inconsistency (now fixed by renumbering profiling to Phase 1).

---

## Phase 1 — Profiling: a repeatable capture spell (build first, for baseline)

**New file:** `RaBbLE-OS/spells/power-profile-capture.sh` (mirrors the existing `spells/boot-profile.sh` pattern)

Wraps the manual protocol in `verify/RaBbLE-OS-Verify-PowerTesting.md` into one script: snapshots `upower`, `/sys/class/power_supply/BAT0/power_now`, `nvidia-smi`, NVIDIA `power_state` (derive the PCI address dynamically via `lspci -d 10de: -D | awk '{print $1}'` — don't hardcode `0000:01:00.0`; the ProArt's dGPU is at `64:00.0` per the hardware doc, and hardcoding breaks across kernel/BIOS PCI renumbering), `turbostat`, `sensors`, and current tuned/asusd profile. Writes a timestamped report **and** a machine-readable JSON snapshot alongside it — the JSON is what Phase 5's settings-app diagnostics tab will consume later, so build it stable now rather than reworking later.

**Why first:** run this before touching anything (Phase 2/3) to get a real baseline instead of guessing at before/after numbers.

---

## Phase 2 — Cut Hyprland/AMD-iGPU compositor load

**File:** `RaBbLE-OS/config/hypr/conf.d/look.conf`

Current `decoration.blur` (`enabled=true`, `size=8`, `passes=3`) applies to every normal window, not just layer surfaces — at 4K this is a likely GPU cost, but per Opus review it's **not the only lever**:
- Reduce blur cost: `passes 3→2`, `size 8→6` (cost scales with size×passes)
- `blur.xray = false → true` — cheap win: skips blurring what's behind a window rather than compositing full stacked blur; changes the look slightly (more "cutout" than "frosted"), worth testing
- `inactive_opacity = 0.93` (currently) forces translucent compositing + blur-bleed-through on **every inactive window**, which is likely a bigger cost than the blur passes themselves — consider `1.0` (opaque) for inactive windows, or accept the cost consciously if the look matters more than the GPU load
- Consider restricting full-window blur to floating/transparent windows via windowrule rather than the global `decoration.blur.enabled` toggle, since layer surfaces (fuzzel, notifications, swaync) already get blur explicitly via existing `layerrule = blur true, match:namespace ...` entries in `windowrules.conf`
- Leave `shadow` as-is (cheap already) and `vrr = 1` as-is — that's variable **refresh rate** (a power/tearing feature), not `misc:vfr` (variable frame rate) — don't conflate the two when reasoning about cost

**Verification:** run Phase 1's capture spell before/after; visually confirm animations/blur still read as intended; watch `gpu-usage.sh`'s waybar tile live.

---

## Phase 3 — NVIDIA D3cold idle power + suspend/resume

**File:** `RaBbLE-OS/ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml`

Implements (and completes) the fix outlined in `fix/RaBbLE-OS-Fix-Nvidia.md`. **Corrected per Opus review** — the original draft would have enabled services that don't exist on this system:

- Add package: **`xorg-x11-drv-nvidia-power`** — this is what actually ships `nvidia-suspend.service`, `nvidia-hibernate.service`, `nvidia-resume.service`, `nvidia-powerd.service`, and the `/usr/lib/systemd/system-sleep/` hooks. The current package list (`akmod-nvidia`, `xorg-x11-drv-nvidia`, `-cuda`, `-cuda-libs`, `libva-nvidia-driver`, `libva-utils`) does **not** include it — without this addition, the "just enable the service" step fails on missing units.
- Add `options nvidia-drm modeset=1` alongside the existing `fbdev=1` in the modeset modprobe.d file — this is `Fix-Nvidia.md`'s **first listed open blocker** and a real prerequisite for RTD3/D3cold on Wayland, not just a nice-to-have.
- Add `/etc/modprobe.d/rabble-nvidia-powermgmt.conf`:
  ```
  options nvidia NVreg_DynamicPowerManagement=0x02
  options nvidia NVreg_PreserveVideoMemoryAllocations=1
  ```
  (`notify: regenerate initramfs`, same handler pattern already used in this file — and note explicitly in the task: **this requires a reboot to take effect**, same as the existing nouveau-blacklist task warns for. Don't let verification assume it's live without a reboot.)
- Enable `nvidia-suspend.service`, `nvidia-hibernate.service`, `nvidia-resume.service` (now that the package providing them is installed) — closes the open blocker in `fix/RaBbLE-OS-Fix-Suspend.md`
- Enable `nvidia-powerd.service` too, but **be accurate about what it does**: it's Dynamic Boost 2.0 (performance/clock-boost arbitration), not an idle-power reducer. Include it because it's part of the documented stack, not as a claimed idle-draw fix.
- Do **not** enable `nvidia-persistenced` (keeps GPU in D0 — the anti-pattern already called out in the doc)

Update the two Grimoire checklists (`Fix-Nvidia.md`, `Fix-Suspend.md`) to tick these items once verified, and record actual power-draw numbers (via Phase 1's spell) in `verify/RaBbLE-OS-Verify-PowerTesting.md`'s stage table (S4/S5).

**Verification (after a reboot):**
```bash
NV_PCI=$(lspci -d 10de: -D | awk '{print $1}')
cat /sys/bus/pci/devices/$NV_PCI/power_state   # target: D3cold when idle
nvidia-smi --query-gpu=power.draw,pstate --format=csv,noheader
# 3x suspend/resume cycles, journalctl -b -u systemd-suspend clean
```

---

## Phase 4 — Real power stack + 3-mode waybar control

This turns on the dormant scaffold rather than inventing a new one. Task files already exist as stubs at `ansible/roles/hardware/x64/asus_proart_p16/tasks/{tuned,asusd,asusctl,arbitration}.yml`, wired into `main.yml` already — just need real content. **Corrected per Opus review** on both the fan-curve mechanism and the current waybar state (both were mischaracterized in the original draft).

**`tuned.yml`:** install `tuned` + `tuned-ppd` (add `tuned-ppd` to `ansible/packages/manifest.yml` — currently only `tuned`/`tuned-gtk` are listed), enable `tuned.service`, set a sane default active profile.

**`asusd.yml` / `asusctl.yml`:** install `asusd`+`asusctl` (already declared in manifest via `copr:lukenukem/asus-linux`, just never installed by the stub), enable `asusd.service`.

**`arbitration.yml` — corrected fan-curve model:** asusctl fan curves are defined **per platform-profile** (Quiet / Balanced / Performance each own their own curve in asusd's config), coupled to `tuned-ppd` via the kernel `platform_profile` sysfs interface — there is no generic "asusd auto-follow toggle" to disable. To get "CPU headroom of Balanced, but fans held quiet," the actual mechanism is: **edit the Balanced profile's own fan curve in asusd's config to be the quiet curve**, rather than trying to decouple two systems that don't couple the way a toggle would imply. This file's job: author the three fan-curve definitions (quiet / standard / unrestricted) and assign them to the Quiet/Balanced/Performance platform-profiles respectively (with Balanced getting the *quiet* curve, not its stock one) — plus a guard task confirming `power-profiles-daemon` is never installed (mask it if some dependency pulls it in). Exact `asusctl`/config-file syntax to be confirmed against the installed version at implementation time.

**Waybar composite modes** (`config/waybar/scripts/power-profile.sh` — **currently orphaned, not wired into `config.jsonc` at all**; and the stock `power-profiles-daemon` module is defined in `config.jsonc` but not present in the `modules-right` array, so nothing shows today):
| Mode | `powerprofilesctl` (via tuned-ppd) | asusd platform-profile (with quiet-curve override on Balanced) | AC gate |
|---|---|---|---|
| Quiet · Low Power | `power-saver` | Quiet | any |
| Quiet · Balanced | `balanced` | Balanced (quiet curve) | any |
| Unbounded | `performance` | Performance (unrestricted curve) | **AC only** |

- Rewrite `power-profile.sh` to drop its current implicit dependency on `power-profiles-daemon` proper (it must work against `tuned-ppd`'s compatible interface instead) and to set both the PPD-compatible profile and the asusd platform-profile together
- Selecting Unbounded on battery: block + `notify-send` warning, stay on current mode
- **AC-plug gate: use a udev rule** (`SUBSYSTEM=="power_supply", ATTR{online}=="0"`, triggering a fallback script) — not a systemd path-unit, which can't reliably watch sysfs attribute-value changes via inotify
- `config/waybar/config.jsonc`: remove the unused stock `"power-profiles-daemon"` module block, and **add** a new `custom/power-profile` module to `modules-right` wired to the rewritten script (there is no existing module to "relabel" — this is a net-new addition, not a swap)

**Verification:** `layerctl.sh apply hardware && layerctl.sh verify hardware`; cycle all 3 modes from waybar and confirm `tuned-adm active`, the asusd platform-profile, and the fan curve all change together as intended; confirm AC-unplug fallback fires via the udev rule.

---

## Phase 5 — Settings app (design sketch only — implement in a follow-up session)

Decided: **local Aether-themed web app**, not GTK4/TUI. Sketch to carry into its own Grimoire plan doc (`RaBbLE-Grimoire/RaBbLE-OS/plans/RaBbLE-OS-Settings-App-Plan.md`) before that follow-up session starts, per the existing convention of writing full plan + cold-start handoff to the Grimoire for large work:

- Frontend: vanilla HTML/CSS/JS consuming Aether tokens directly (same convention as World — no React, no separate theming pass needed)
- Backend: small local Python service (systemd user unit, localhost-only) that reads live state (waybar/hyprland config, Phase 1's capture-spell JSON) and writes changes; privileged actions (modprobe.d, systemd enable/disable, asusctl) go through a polkit policy, not raw sudo
- Surface: waybar config toggles, Hyprland tunables (blur/animation sliders that edit `look.conf`/`animations.conf` + `hyprctl reload`), the Phase 4 power-mode picker, a diagnostics tab fed directly by Phase 1's JSON output
- Packaging: new ansible role (e.g. `apps/settings-app`) installs the backend service + desktop entry; source lives in `RaBbLE-OS/settings-app/` (code stays in the member repo, design doc goes to Grimoire per the Collective's Grimoire-is-docs / members-hold-code rule)

Not implementing this now — flagging the shape so Phase 4's design (composite power modes) and Phase 1's spell (stable JSON output) are built in a way Phase 5 can call into directly instead of needing rework.

---

## Grimoire doc updates (part of this pass)

- `fix/RaBbLE-OS-Fix-Nvidia.md`, `fix/RaBbLE-OS-Fix-Suspend.md` — tick implemented checklist items, record verified numbers
- `hardware/RaBbLE-OS-Hardware-ProArtP16.md` — Power Management section: replace the aspirational PPD table with the real tuned+asusd 3-mode table
- `RaBbLE-OS-AgentGuide.md` / `RaBbLE-OS-DevHistory.md` — note power stack moved from `%DORMANT%` to implemented
- New: `log/plans/RaBbLE-OS-Settings-App-Plan.md` stub (Phase 5 sketch above) for the follow-up session to pick up cold

---

→ `RaBbLE-Grimoire/RaBbLE-OS/hardware/RaBbLE-OS-Hardware-ProArtP16.md` — hardware profile
→ `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-Fix-Nvidia.md` — NVIDIA Optimus + D3cold fix (prerequisite for Phase 3)
→ `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-Fix-Suspend.md` — suspend/resume hooks (depends on Phase 3)
→ `RaBbLE-Grimoire/RaBbLE-OS/verify/RaBbLE-OS-Verify-PowerTesting.md` — power measurement protocol (Phase 1 wraps this)
→ `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-AgentGuide.md` — canonical tuned+tuned-ppd power stack decision (line 64-66)
