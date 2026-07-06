# RaBbLE-OS Seamless Boot Chain Plan

> **Impulse:** mend ~ os/boot >> seamless GRUB→Plymouth→SDDM, amdgpu-only display
> **Authored:** S197, 2026-07-06
> **Goal:** Eliminate three visible seams in the boot chain through low-risk Phase 1 VM-verifiable fixes (feeds G7) and aggressive Phase 2 real-hardware root-cause polish (ProArt only).

---

## Context

The RaBbLE-OS boot chain (GRUB → Plymouth splash → SDDM greeter) has three visible seams on the ProArt P16, documented across `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-BootChain-Anatomy.md` and `RaBbLE-OS-Fix-BootChain.md`:

1. **GRUB → Plymouth** — a black box / flash after the menu, during kernel load (§3.1, `[OPEN]`).
2. **Mid-Plymouth ~1–2s black** — the intrinsic simpledrm → amdgpu framebuffer handoff. amdgpu takes ~2.5s to load firmware (DMUB/PSP/VBIOS) and only then modesets eDP-1; the CRTC blanks during that switch (`Console: switching to colour dummy device 80x25` at T+4.23). This is the headline defect (§3.3).
3. **Plymouth → SDDM** — a 200–400ms black at the greeter handoff, currently masked by a blind `ExecStartPre=/bin/sleep 0.3` in `plymouth-quit.service` (§3.5, mitigated not fixed).

**Hardware reality (already correct, will harden):** the laptop panel `eDP-1` hangs off the **AMD 890M iGPU** (`amdgpu`, PCI `0000:65:00.0`, currently `card1`). NVIDIA (`card0`) drives no internal display and is already deferred out of the initramfs via `rd.driver.blacklist=nvidia`, loading only after SDDM. So **boot display is already amdgpu + simpledrm only** — Mark's "just amdGPU, possibly simple DRM" goal is the current architecture; Phase 2 completes it by removing the second DRM device.

**Disproven theories — do NOT re-chase** (from the anatomy ledger §4, cost 5+ sessions):
- `amdgpu.seamless=1` is a **confirmed no-op** on DCN 3.5 / kernel 7.0.x (still logs the dummy switch).
- `plymouth.use-simpledrm=1` causes **permanent black**.
- The ternary-operator bug once blacked the whole theme.
- The `GFXPAYLOAD=3840x2400x32` native-payload fix (§3.2) is load-bearing — keep it.

**Decisions (Mark, this session):**
- GRUB: **keep the visible menu** (recovery entry stays reachable) and fix the black box another way.
- amdgpu seam: **two phases** — ship the safe VM-verifiable seam fixes first, then re-attempt eliminating simpledrm on real hardware, this time root-causing the S173 SDDM regression.

**Outcome:** GRUB → Plymouth → SDDM reads as one continuous liminal scene. Phase 1 is low-risk and VM-verifiable, and directly feeds **G7** (the generic-x86_64-VM Developer-Preview FLOOR boot gate, `RaBbLE-Grimoire/log/G7-G9-Verification-Guide.md`). Phase 2 is ProArt daily-driver polish.

---

## Phase 1 — Safe seam fixes (low risk, VM-verifiable, applies to ALL RaBbLE-OS)

VM caveat: the dev VM uses virtio-gpu, **not** amdgpu, so it **cannot** reproduce seam #2 (the amdgpu firmware handoff). It **can** verify GRUB rendering, systemd ordering, retain-splash behavior, and SDDM — everything in Phase 1. Verify Phase 1 via `spells/vm-boot-iterate.sh` (virsh screenshots the full GRUB→Plymouth→SDDM sequence).

### 1A. Plymouth → SDDM: replace the sleep hack with `--retain-splash` (the real fix)

**Root mechanism:** `sddm.service` is ordered `After=plymouth-quit.service`, and vendor `plymouth-quit` runs `plymouth quit` (no flags) which **explicitly hides** the splash on exit → black → *then* SDDM starts and paints. The 0.3s sleep only shifts when the black starts. Plymouth and the SDDM/sway greeter both need DRM master, so they can't paint simultaneously; the fix is to **leave the last splash frame on the framebuffer** while the greeter paints over it.

- File: `ansible/roles/boot/session_manager/files/plymouth-quit-sddm.conf`
  Change the drop-in to **override ExecStart** (reset then set) instead of adding a pre-sleep:
  ```ini
  [Service]
  ExecStart=
  ExecStart=-/usr/bin/plymouth quit --retain-splash
  ```
  `--retain-splash` (confirmed supported: `plymouth quit --retain-splash`) keeps the frozen final splash frame visible after Plymouth releases DRM, so the greeter's paint-up shows the splash, not black. The existing SDDM `Main.qml` 500ms entity opacity fade-in (from S155) then cross-fades on top — a true dissolve. Drop the blind `sleep 0.3` (keep a tiny `ExecStartPre` sleep of 0.1s only if the VM capture still shows a gap).
- Rename the deployed drop-in filename/comment from `sddm-first-frame.conf` to reflect retain-splash; update the `copy:` task in `ansible/roles/boot/session_manager/tasks/config.yml` accordingly.

### 1B. GRUB → Plymouth: diagnose the black box, then targeted keep-menu fix

The anatomy doc (§3.1) explicitly says this artifact must be **classified before fixing** (full-screen vs rectangle vs faint text) and needs eyes on the GRUB phase. The VM gives us those eyes without a real reboot:

1. **Diagnose:** run `spells/vm-boot-iterate.sh` and inspect the captured GRUB→Plymouth frames (virsh screenshots land in `RaBbLE-BaBbLE/captures/Boot/vm-<ts>/`). Classify: is the black full-screen (theme/console teardown, candidate b/c) or a rectangle with liminal bg around it (gfxterm load-message region, candidate a)?
2. **Fix (candidate, keep-menu):** the "Loading Linux / Loading initial ramdisk" phase activates gfxterm's opaque console region over the themed bg. With the menu retained, the targeted levers in `ansible/roles/boot/grub2/templates/grub.j2` + `theme.j2` are:
   - style the gfxterm message region so its background is the liminal void, not `#000`, via the theme's terminal/message properties (so the load text region blends into the bg); and/or
   - ensure the theme's `desktop-image` (liminal bg) remains the last-drawn surface through the load phase rather than being cleared to `desktop-color`.
   Exact lever is picked from the step-1 classification — do not guess blind (the doc's explicit warning). `GRUB_COLOR_NORMAL="black/black"` already hides the *text*; the remaining work is the *canvas* fill.

### 1C. Kernel cmdline hygiene (evidence-based only)

- Reconcile a **doc↔reality drift**: `BootChain-Anatomy.md` §4.3 says `amdgpu.seamless=1` was REMOVED S172 as a proven no-op, but it is **still present** in both the live cmdline and `ansible/inventory/group_vars/asus_proart_p16.yml`. Since it demonstrably does nothing, remove it to stop it masquerading as an active fix (it is ProArt-specific, so this is a group_vars edit). Leave a one-line comment pointing at the ledger entry so it isn't re-added.
- Keep everything else on the cmdline as-is (all evidence-backed): `rhgb quiet loglevel=3`, `fbcon=nodefer`, `vt.global_cursor_default=0`, `rd.driver.blacklist=nvidia`, `rd.udev.log_level=3`, `GFXPAYLOAD=3840x2400x32`. No speculative token additions.

---

## Phase 2 — amdgpu as the sole DRM device (real-HW only, ProArt-specific)

**Goal:** eliminate seam #2 by removing the second DRM device so there is no simpledrm→amdgpu migration, no dummy-device blank, no animation catch-up (anatomy §5). The GOP framebuffer (GRUB's last frame) then holds statically until amdgpu+Plymouth start — no flash, just a longer still frame up front (which is why 1B matters: that still frame should be the liminal bg).

This was attempted (S172) and **reverted (S173) because it broke SDDM**. We re-attempt it *with the regression root-caused first.*

### 2A. Root-cause the S173 SDDM breakage (strong hypothesis)

The SDDM/sway greeter compositor is pinned to a **hard card number**: `ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml` deploys `/etc/sddm.conf.d/rabble-gpu.conf` with `CompositorCommand=env WLR_DRM_DEVICES=/dev/dri/card1 …`. With simpledrm present, AMD enumerates as `card1`. **Remove simpledrm and the numbering very likely shifts** (AMD may become `card0`) → the pin points at the wrong/nonexistent node → greeter fails → SDDM never loads. That matches the S173 symptom exactly.

- **Fix:** repin the greeter to the stable by-path node that survives renumbering: `WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:65:00.0-card` (verified present on the live machine; always resolves to the AMD 890M regardless of `cardN`). Edit `nvidia.yml`.

### 2B. Re-add the simpledrm suppression

- `ansible/inventory/group_vars/asus_proart_p16.yml` → append to `rabble_grub_extra_cmdline`: `initcall_blacklist=simpledrm_platform_driver_init` (simpledrm is builtin, so this is the only way to disable it). amdgpu is already force-loaded into the initramfs (`add_drivers+=" amdgpu "`), so it remains the recovery framebuffer path.
- If step-2C diagnosis shows the greeter still races amdgpu, add a systemd ordering guard so SDDM waits for the amdgpu DRM node (e.g. `After=` a udev-settle / dev-dri device unit) — decide from the real-boot evidence, not preemptively.

### 2C. Real-hardware verification (mandatory before promoting `[~]` → `[x]`)

Real HW only — the amdgpu handoff is not reproducible in the VM. **Have a recovery USB ready** (anatomy §5 flags the risk: no simpledrm = no early fb if amdgpu ever fails).

```bash
sudo bash spells/boot-debug-toggle.sh --on      # plymouth:debug + apply boot
sudo reboot                                      # Mark watches the handoff
sudo bash spells/boot-diagnose.sh                # theme-in-initramfs, amdgpu present, log errors
bash spells/boot-profile.sh                      # timing; expect the dummy-switch black gone
# confirm the dummy switch is gone:
journalctl -k -b -o short-monotonic | grep -E "dummy device|frame buffer device|amdgpudrmfb"
sudo bash spells/boot-debug-toggle.sh --off      # remove the debug flag (no permanent drift)
```
Success = no `Console: switching to colour dummy device 80x25`, amdgpu fb comes up once, SDDM loads (the S173 failure does **not** recur), no animation speed-jump. If SDDM still fails, revert 2B (delete the token, `apply boot`, reboot — simpledrm returns) and re-diagnose 2A.

---

## Verification summary

| Phase | Where | How |
|---|---|---|
| 1A/1B/1C | Dev VM (generic x86_64) | `spells/vm-boot-iterate.sh` full loop → inspect virsh frames in `RaBbLE-BaBbLE/captures/Boot/vm-<ts>/`; `boot-profile.sh` for timing. **This is the G7 boot evidence.** |
| 1A alt | Live session | `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/rabble-aether` for the greeter render; plymouth preview per `Plymouth-Tweaking.md` §3A |
| 2 | Real ProArt reboot | `boot-debug-toggle --on` → reboot (Mark's eyes) → `boot-diagnose.sh` + `boot-profile.sh` + journal grep → `--off`. Recovery USB ready. |

Apply cycle for all changes: `cd ~/RaBbLE-Collective/RaBbLE-OS && sudo ./RaBbLE-OS-layerctl.sh apply boot` (deploys theme/grub/sddm, runs `dracut --force` + `grub2-mkconfig` via handlers), then reboot. Phase 2 also needs `apply hardware` (nvidia.yml greeter repin).

## Files touched

- `ansible/roles/boot/session_manager/files/plymouth-quit-sddm.conf` — retain-splash override (1A)
- `ansible/roles/boot/session_manager/tasks/config.yml` — deploy task rename/comment (1A)
- `ansible/roles/boot/grub2/templates/grub.j2` + `theme.j2` — gfxterm canvas fix, after VM diagnosis (1B)
- `ansible/inventory/group_vars/asus_proart_p16.yml` — drop `amdgpu.seamless=1` (1C); add `initcall_blacklist=simpledrm_platform_driver_init` (2B)
- `ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml` — greeter GPU pin → by-path (2A)

## Docs (Grimoire is the source — update, don't duplicate)

- `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-Fix-BootChain.md` — log the retain-splash fix, the amdgpu.seamless drift removal, and the Phase-2 re-attempt with the by-path root cause.
- `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-BootChain-Anatomy.md` — update §3.5 (retain-splash), §4.3 (seamless actually removed now), §5/§9 (S173 root cause = hard card pin; by-path fix).

## Out of scope (deferred)
- 4K asset masters (entity/wordmark upscale softness) — separate visual-polish pass
- Seamless entity idle loop (NeBuLA frame export) — noted future pass
- `NetworkManager-wait-online` boot-time win — already masked (S156); re-profile only
