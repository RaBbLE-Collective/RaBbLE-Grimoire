# RaBbLE-OS-Hardware-Cetus3D-MK2.md — Cetus3D MK2 Printer Peripheral

```
transcribe ~ grimoire >> a proprietary printer meets the entity's substrate // %CETUS3D_PROFILE%
```

> **What this is:** how RaBbLE-OS enables a TierTime Cetus3D MK2 3D printer — a USB peripheral, not a hardware *target* (the printer doesn't run RaBbLE-OS; the desktop does). Covers why it needs Wine, and the setup path.
>
> **Related:** [Layer-Bottles](../layers/RaBbLE-OS-Layer-Bottles.md) · [Hardware-AddingTargets](RaBbLE-OS-Hardware-AddingTargets.md)

---

## The firmware problem

Stock Cetus3D MK2 units run TierTime's proprietary firmware and CPU board — they do **not** consume standard GCode the way most FDM printers do. Slicing and print control go through TierTime's own client, **UP Studio**, which ships **Windows and Mac builds only** — there is no official Linux client and no official Cura/PrusaSlicer profile for stock firmware. Community Cura/PrusaSlicer profiles exist on GitHub/Thingiverse, but they target printers that have had their CPU board swapped for an open-firmware replacement (Smoothieware/Marlin) — a hardware mod, not a software one.

**Confirmed 2026-07-21** (do not re-derive without checking — TierTime's Linux support could change):
- [UP Studio Win 64-bit](https://www.cetus3d.com/product/up-studio-3-2-5-for-win64bit/) / [UP Studio Mac (M1 compatible)](https://www.cetus3d.com/product/up-studio-3-2-7-mac/) / [software page](https://www.cetus3d.com/software/) — no Linux build listed
- [Cetus3D MK2 Cura profile (community gist)](https://gist.github.com/NeoTech/8f046b3fd65d2ec7e3550db88fc78d20), [Prusa Slic3r config for Cetus mkII](https://www.thingiverse.com/thing:3045287) — both target modded firmware
- [Marlin full-gcode-support forum thread](https://forum.tiertime.com/t/cetus-and-marlin-firmware-full-g-code-support/1133), [e1e0.net Cetus mods](https://e1e0.net/free-cetus.html) — the open-firmware mod path, not pursued here
- [`maarten-pennings/Cetus3D`](https://github.com/maarten-pennings/Cetus3D) — a status-monitoring library talking to the printer's native protocol; no slicing, noted here in case it's useful later

## Decision

Rather than mod the printer's firmware, run **UP Studio inside a Bottles bottle** (Wine, isolated per-app prefix). This is the same infrastructure intended for Affinity Suite later — see [Layer-Bottles](../layers/RaBbLE-OS-Layer-Bottles.md) for what the Ansible layer actually installs (Bottles itself, Flathub remote, `dialout` group membership for USB/serial).

Ansible automates the whole software chain (`tasks/upstudio.yml`, see [Layer-Bottles](../layers/RaBbLE-OS-Layer-Bottles.md)): create the bottle, download the installer archive from TierTime's own CDN (`static.tiertime.com` — first-party, no checkout, Mark confirmed the link directly on 2026-07-21), extract it, run it, and remember it ran. **Confirmed working end to end on 2026-07-22**, including a real install: the download link is pinned to the specific build Mark found (TierTime gates "latest" behind a WooCommerce checkout with no stable link), and a silent (`/quiet`) install was tried and confirmed to reliably fail — the MSI's `WinusbFM` custom action (installs a Windows USB driver) can't complete under Wine and rolls the whole transaction back. The full interactive wizard **does** succeed, though — confirmed by actually running it: Mark clicked through the installer once, and the complete app landed under `Program Files\UP Studio\`, driver files included. That's the confirmed default now, not a placeholder.

## Setup path

1. `bash RaBbLE-OS-layerctl.sh apply bottles` — installs Bottles, adds `rabble_user` to `dialout`, creates the `/Tiertime/*` host directories, and grants the Flatpak sandbox access to them (see [Layer-Bottles](../layers/RaBbLE-OS-Layer-Bottles.md) for why UP Studio needs that). **Log out/in** for the `dialout` group change to take effect. (Bottles' own first-run setup needs no manual step — `bottles-cli` initializes its data directory on demand.)
2. `bash RaBbLE-OS-layerctl.sh apply bottles` again — this creates the `UPStudio` bottle, downloads + extracts the installer automatically, and launches it. Click through the wizard once; the play blocks until you close it.
3. Launch UP Studio going forward with `-p`, **not** `-e` — this matters, not just style, see Layer-Bottles for why:
   ```bash
   flatpak run --command=bottles-cli com.usebottles.bottles run -b UPStudio -p UPStudio
   ```
4. Plug in the Cetus3D MK2 over USB. Verify it enumerates: `lsusb` (confirmed 2026-07-22: shows up as `ID 4745:277f Tiertime Cetus S7N`, no `/dev/ttyUSB*`/`ttyACM*` node — it uses a custom USB interface, not a virtual serial port, consistent with the WinUSB approach).
5. Inside UP Studio, point it at the device. If it can't see the printer, check Flatseal (`com.usebottles.bottles` → Filesystem/Devices) before assuming it's a Wine problem — see the USB/serial caveat in the Layer-Bottles doc.

## Status

| Item | Status |
|---|---|
| Bottles layer (Ansible) | **Built** — `layer/bottles`, opt-in, `layerctl apply bottles` |
| UP Studio download + bottle + install, end to end | **Built and verified** — `tasks/upstudio.yml`, downloads from TierTime's CDN, launches the installer, idempotent across re-applies |
| UP Studio actually installed | **Done** — confirmed 2026-07-22, full app tree present |
| `/Tiertime` drive-relative path bug | **Fixed and automated** — host dirs + Flatpak override, see Layer-Bottles |
| UP Studio actually starts up and shows its main window | **Not done — open issue.** Reproducibly hangs on the startup splash past the `/Tiertime` fix, even with the printer connected from launch. Also ruled out: missing VC++ 2015-22 runtime, Wine sync mode/GameMode/GPU selection, and (2026-07-26) a live network call — no outbound connection exists at the time of the stall, and a native-gdb backtrace confirms every thread of the process tree is a genuine blocking wait (0% CPU, all resolving into libc's poll/futex code), not a spin or crash loop. A proper Windows-level stack trace (`winedbg --gdb`) is blocked by what looks like an SELinux denial inside the Flatpak sandbox, needing root to confirm — see "Debugger attach" in Layer-Bottles-Debugging for the full writeup and the exact next command if picked back up |
| USB/serial verified end-to-end | **Blocked on the above** — printer enumerates fine at the USB level (`lsusb` confirms it), but UP Studio itself never reaches a state where it could talk to it |
| **UP Studio 3** (fresh, separate bottle) | **Works — launches and shows its main window, unlike UP Studio 2.** Confirmed 2026-07-27. Mark supplied the direct download link (`tiertime.s3.us-west-1.amazonaws.com/downloads/UP_Studio3_3.3.4_3 setup.zip`, build 3.3.4.3 — the WooCommerce checkout gate from the product page still applies, this was a manual hand-off, not something automated this session found). New bottle `UPStudio3`, full interactive wizard (same pattern as UP Studio 2: `/quiet` untested here, wizard confirmed working), installs to `Program Files\UP Studio3\`. **Ad hoc, not in Ansible** — `ansible/roles/layer/bottles` only automates UP Studio 2 (`tasks/upstudio.yml`, bottle name `UPStudio`); UP Studio 3's bottle/install was set up by hand this session, no `upstudio3.yml` task exists yet. Launches 2-3 windows: the main app (title `UP Studio3 3.3.4`), a bundled companion `Wand.exe` ("Wand 3D Printer Manager" — TierTime's separate WiFi/BT print-controller utility, launched automatically alongside the main app, not something the user asked for or expected), and a small untitled utility window (160×20). No `/Tiertime` drive-relative-path bug hit (that was a UP Studio 2 issue, doesn't reproduce in v3). |
| USB driver install, UP Studio 3 | **Confirmed broken, same root cause as UP Studio 2.** 2026-07-27: v3 ships the USB driver as its own standalone installer, `Program Files\UP Studio3\TiertimeDriver x64.exe` (not an inline MSI action like v2) — but it's itself an MSI wrapper, and running it hits the identical `MsiInstallDrivers` (`WinusbFM` feature) failure, error 1603, full rollback. This is a structural Wine limitation (no real Windows Driver Store/PnP manager to install a vendor USB driver into) — not fixable by retrying, silent-install flags, or a different installer. UP Studio 3's own UI confirms the consequence: its startup toast reads `Printer:-1` (no printer recognized at all). |
| USB connect path via Wand | **Dead end, confirmed 2026-07-27.** Wand's own "Connect" UI is wireless-only — no USB/local device option exists in it at all, on either UP Studio version. Even if the vendor driver somehow installed, there's no UI path to hand USB to Wand. |
| Printer WiFi — root cause + path forward | **Diagnosed 2026-07-27, not yet executed** — tracked as `B-11` in BLOCKERS.md. WiFi setup requires a one-time USB handshake (set SSID/password via UP Studio, then the cable can be unplugged) — confirmed via Tiertime's own KB + forum: `support.tiertime.com` "How to set up the printer connect wifi?" (Settings → Printer → click the circle on the printer icon → pick WLAN from dropdown → Confirm). Since that one-time step needs a working USB driver install and Wine can't provide one, the plan is to do it on the machine's Windows 11 dual-boot instead (real Windows installs `WinusbFM` natively) — once the printer has joined the WLAN, RaBbLE-OS only needs Wand's already-working wireless connect UI, no USB/Wine driver involved going forward. A forum thread also claims Cetus MK2 WiFi needs a separate legacy "Cetus3D" desktop app rather than UP Studio — moot for this plan (not investigated further), but noted in case the Windows-side attempt needs a fallback: `cetus3d.com/software/` no longer lists a standalone Windows "Cetus3D" client, only UP Studio; the App Store listing is Mac-only. |
| Affinity Suite in a separate bottle | **Planned, not started** |

---

```
transcribe ~ grimoire >> Cetus3D path documented, Bottles is the bridge // %CETUS3D_PROFILE%
```
