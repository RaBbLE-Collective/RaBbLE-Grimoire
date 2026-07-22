# RaBbLE-OS Layer — Bottles

> Ansible layer tag: `bottles` (also responds to `layer`)
> layerctl: `bash RaBbLE-OS-layerctl.sh apply bottles`
> Opt-in var: `rabble_enable_wine_bottles` (default `false` — see `ansible/roles/layer/bottles/defaults/main.yml`)
> Role: `ansible/roles/layer/bottles/`

Bottles installs isolated per-app Wine prefixes for Windows-only software that has no Linux build. It is the reference implementation of the `layer/*` optional-feature-group pattern documented in `ansible/packages/manifest.yml` — every other `layer/*` entry there (`layer/bluetooth`, `layer/nightmode`, `layer/flatpak`, `layer/dev`) is declared as packages but not yet wired into a role, a `site.yml` play, or `layerctl.sh`. Follow this layer's shape when those get built out.

**Hitting a wall with a Windows app under this layer (installer hangs, app won't start, silent failure)?** → [Layer-Bottles-Debugging](RaBbLE-OS-Layer-Bottles-Debugging.md) — general troubleshooting playbook distilled from getting UP Studio working, written for the *next* app (Affinity Suite is next in line), not just this one.

---

## Why this exists

Two Windows-only tenants drove this:

1. **TierTime UP Studio** — the slicer/host client for the [Cetus3D MK2](../hardware/RaBbLE-OS-Hardware-Cetus3D-MK2.md) printer. Ships Windows and Mac builds only, no Linux build, no official Cura/PrusaSlicer profile for stock firmware.
2. **Affinity Suite** (Photo/Designer/Publisher) — planned, not yet set up. Same situation: Windows-only, no native Linux build.

Bottles was chosen over a bare system-wide Wine install or Lutris because each app gets its **own isolated prefix** (runner version, DXVK, .NET/mono, dependencies) — UP Studio and Affinity won't fight over a shared `~/.wine`. It's distributed via Flathub, which keeps it out of the DNF package graph and sandboxed via Flatpak portals.

---

## What the layer installs

| Step | What | Why |
|---|---|---|
| `flatpak` (dnf) | Flatpak runtime | Required even if `layer/flatpak` was never separately applied — this layer is self-contained |
| Flathub remote | `flatpak_remote`, system-wide | Bottles' distribution channel |
| `com.usebottles.bottles` | Bottles itself | The bottle manager |
| `dialout` group | `rabble_user` appended | USB/serial passthrough — printers, MCUs, anything talking over `/dev/ttyUSB*` |
| `/Tiertime/{Log,Temp,Cache,Config,Data,Db}` + Flatpak override | Host dirs + `flatpak override --filesystem=/Tiertime` | Works around a UP Studio drive-relative path bug — see below |
| UP Studio bottle | `tasks/upstudio.yml`, always included | Creates the `UPStudio` bottle and installs the app if the installer's been downloaded — see below |

All tasks are gated behind `rabble_enable_wine_bottles`, which defaults to `false`. **`apply all` / `upgrade` never installs this layer** — only an explicit `apply bottles` (or `--tags bottles` with the var forced true) does. `layerctl.sh` flips the var automatically via its `LAYER_EXTRA_VARS` map so you don't have to remember the flag.

---

## UP Studio bottle automation

`tasks/upstudio.yml` runs every time the layer applies (no separate opt-in — every step below self-skips once already done):

1. Creates the `UPStudio` bottle (`rabble_upstudio_bottle_name`) via `bottles-cli new --environment application --arch win64`, skipped if it already exists. (Bottles' first-run setup was originally assumed to need a manual GUI launch first — that turned out to be false: `bottles-cli` initializes its own data directory on demand, verified 2026-07-22 against a live run. No manual step here.)
2. Checks a marker file to see if UP Studio is already installed — if so, skips the rest entirely.
3. Downloads the installer archive from `rabble_upstudio_installer_url` (a first-party TierTime CDN link, `static.tiertime.com`, ~150MB — Mark confirmed it directly on 2026-07-21, no checkout/auth needed) into `rabble_upstudio_installer_cache_dir`, then extracts the `.exe` from the zip. Both steps are idempotent (`get_url` skips if already cached; skipped entirely once installed).
4. Runs the extracted installer via `bottles-cli run -b UPStudio -e <path> <rabble_upstudio_installer_args>` (trailing positional args, not a flag — see gotcha below).
5. Drops a marker file so future applies skip the install, then deletes the cached zip/exe.

**Gotcha: Bottles' Flatpak sandbox has no filesystem access outside its own app data dir.** `flatpak info --show-permissions com.usebottles.bottles` shows no `[filesystem]` grant at all — confirmed 2026-07-22 by hitting it directly: an installer placed at `~/.cache/rabble/upstudio/` was reported as "does not exist" by `bottles-cli` even though it plainly existed on the host. Every Flatpak app's own `~/.var/app/<id>/data` is always sandbox-visible with no override needed, so `rabble_upstudio_installer_cache_dir` lives there instead (`~/.var/app/com.usebottles.bottles/data/rabble-upstudio`). **This applies to anything you point a bottle at** — including a manually-downloaded Affinity installer later; if Bottles can't find a file you know exists, this is almost certainly why.

**`bottles-cli run` gotcha:** takes trailing positional args for the executable's own arguments, not a `-a` flag — an earlier version of this task guessed `-a` from a docs summary and it doesn't exist on the installed CLI (confirmed via `bottles-cli run --help`, 2026-07-22).

**Resolved 2026-07-22: install the interactive way, not `/quiet`.** The installer is Advanced Installer-wrapped MSI (`AI_UNINSTALLER = msiexec.exe`, confirmed by inspecting strings in the extracted exe). Its bootstrapper genuinely forwards standard `msiexec` switches — `/quiet` really is a working silent flag, confirmed no GUI popped — but `/quiet` alone **reliably fails and rolls back the whole install**: a custom action (`MsiInstallDrivers`, feature `WinusbFM`) tries to install a real Windows USB driver for direct WinUSB access to the printer, which is impossible under Wine (no real driver model) and fails with rc 1603 (very likely the exact issue TierTime's own KB article "UP Studio cannot be installed due to unsigned driver issues" describes). Excluding just that feature (`/quiet REMOVE=WinusbFM`) avoids the crash but also skips installing the app itself — nothing under `Program Files` either way.

**The full interactive wizard (`rabble_upstudio_installer_args` left empty, the default) DOES succeed** — confirmed end to end on Mark's machine: the automated task launched it, Mark clicked through the wizard once, and the complete app tree landed under `Program Files\UP Studio\`, including `UPStudio.exe` and the `WinusbFM` driver files. The captured install command line for the successful run included `ADDLOCAL=MainFeature,WinusbFM,WinusbFM_1` — i.e. the driver feature genuinely gets installed via the full wizard path, it just fails specifically when invoked through the fast `/quiet` shortcut. Root cause of that difference (the full bootstrapper flow vs. the direct `/quiet` invocation) wasn't pinned down further — not worth reverse-engineering more once a known-working path exists. **Leave `rabble_upstudio_installer_args` empty; this is the confirmed-working default, not a placeholder.**

**Launching UP Studio afterward: use `-p UPStudio`, not `-e <path>`.** This isn't just style — it's load-bearing, see the `/Tiertime` path bug below.
```bash
flatpak run --command=bottles-cli com.usebottles.bottles run -b UPStudio -p UPStudio
```
`-p` looks up a name from Bottles' internal registered-programs list (auto-populated by Bottles scanning `Program Files` — confirmed already present after install, no manual GUI scan needed for this app) and, critically, launches with the program's own folder as the process's working directory. `-e <path>` does not set a working directory at all. Confirmed working 2026-07-22 — launched with DXVK/Vulkan against the AMD Radeon 890M GPU, CEF renderer processes started normally.

**The `/Tiertime` drive-relative path bug (confirmed 2026-07-22).** UP Studio builds some of its own data paths as bare strings like `/Tiertime/Log` — no drive letter. Real Windows resolves a drive-relative path (leading slash, no drive letter) against the *current drive*. Wine's `Z:` drive maps to the real host filesystem root (`/`) — so if the process's working directory isn't on `C:`, the "current drive" is `Z:`, and `/Tiertime/Log` resolves to **the literal path `/Tiertime/Log` on your real Linux filesystem**, which a normal user can never create (root-owned, mode `dr-xr-xr-x`). Symptom: the app hangs forever on its startup splash, spamming `[!]error ===> [!]-3506[/Tiertime/Log] (GlobeVar::CreateDir)` (visible only via `WINEDEBUG=+seh` — the app's own crash/debug logger, not its normal log file) in a tight infinite retry loop. Two things fix it, and **both are needed together**:
1. **Launch via `-p`, not `-e`** (above) — gets the working directory onto `C:`, which is enough for the app's *normal* logger to write correctly to `%APPDATA%\Tiertime\...` (confirmed: real `UPStudio.log`, `printerconfig`, `DB/*.db` files appear there once this is right).
2. **Real host directories at `/Tiertime/{Log,Temp,Cache,Config,Data,Db}`, PLUS a Flatpak filesystem override** — `tasks/upstudio.yml` creates these host-side (`become: true`, owned by `rabble_user`) and runs `flatpak override --user com.usebottles.bottles --filesystem=/Tiertime`. The override is not optional: Bottles has **zero** filesystem access beyond its own app data dir by default (confirmed via `flatpak info --show-permissions com.usebottles.bottles` — no `[filesystem]` line at all), so the host directories are invisible to the sandboxed process without it, and the same `-3506` loop recurs even though the directories plainly exist on the host.

Both fixes are now automated — a fresh `apply bottles` sets this up without manual intervention.

**Still open: a deeper startup hang, past the `/Tiertime` fix.** Even with both fixes above, UP Studio's *own* log shows it getting further (past printer-config reads, a `GetVendorMatVersion` check, temp-file cleanup, ending with `Thread_BEGIN_UpdateOtherStatus`) but then stalls on the splash screen indefinitely — reproduced consistently across multiple clean launches, log stops at the identical point every time. **Ruled out, with evidence:**
- The Cetus3D MK2 being disconnected — tested with it plugged in from launch, no change (it does enumerate fine at the USB level: `lsusb` shows `ID 4745:277f Tiertime Cetus S7N`).
- A hanging network call — `WSALookupServiceBeginW` fails fast with an error, doesn't block.
- The CUPS/IPP connection — stays open but idle, not the blocker post-`/Tiertime`-fix.
- `fixme:hid:handle_IRP_MN_QUERY_ID` in the Wine trace — looked promising (this app's core function is USB/HID printer access) but is ordinary Wine-boot input-device enumeration, only in the first ~200 lines of trace, nowhere near the actual stall.
- **Missing VC++ 2015-22 runtime** — Bottles' own binary analyzer ("Eagle", GUI feature) correctly identified UP Studio as CEF/Electron-based needing `VC++ 2015-22`; installed it via `flatpak run --command=winetricks com.usebottles.bottles` with `WINEPREFIX` pointed at the bottle (confirmed `vcruntime140.dll`/`msvcp140.dll` landed in `system32`) — **no change**, identical stall.
- **Wine sync mode / GameMode / GPU selection** — Eagle also suggested Esync + GameMode + discrete GPU as bottle overrides (`Parameters.sync`, `.gamemode`, `.discrete_gpu` in `bottle.yml`, editable directly like the `WINEDEBUG` trick above). Tried all three (confirmed via a live screenshot on Mark's own screen, not just log inspection) — **no change**, identical stall. `discrete_gpu: true` did successfully route the app to the NVIDIA dGPU (`gpu-vendor-id=0x10de` vs `0x1002` for the AMD iGPU) confirming the override works, but isn't relevant to the hang and was reverted to `false` — dGPU isn't a good default for this app's kind of workload anyway. Esync + GameMode were left enabled (harmless, may help once past the hang).

**Gotcha discovered along the way:** `bottles-cli shell -i "winetricks ..."` does **not** run the command on the host — it executes it *inside* the Windows/Wine environment (tries to find `winetricks.exe`, fails: `ShellExecuteEx failed: File not found.`). To actually run the host-side `winetricks` script against a specific bottle, invoke it directly: `flatpak run --command=winetricks com.usebottles.bottles` with `WINEPREFIX` (and ideally `PATH` including the bottle's runner `bin/`) exported first.

No further lead was found without a debugger attach (winedbg/gdb) for a real stack trace of the blocked thread — bigger time investment, not attempted yet. Pick this up here if revisited.

**Desktop launcher entry** (so you don't have to run the command above by hand): `tasks/upstudio.yml`'s last tasks check `rabble_upstudio_exe_path` exists and, if so, write `~/.local/share/applications/rabble-upstudio.desktop` with `Exec=... run -b UPStudio -p UPStudio` (the same `-p` form, for the same working-directory reason) — shows up in fuzzel (Super+Space) as "UP Studio (Cetus3D MK2)". `become: false` (user-level XDG dir), idempotent (`ansible.builtin.copy`, only rewrites on change). Icon is a generic freedesktop name (`printer`, resolves via Papirus) — not extracted from the exe; a real icon extraction (`icoutils`: `wrestool` + `icotool`) was deliberately left out as a cosmetic nicety, not the actual ask. Validated with `desktop-file-validate` 2026-07-22.

---

## "It launched once, then never again" — stale process lock after force-quit

Confirmed 2026-07-22: force-quitting UP Studio (or any CEF/Chromium-based Wine app — it spawns separate main/gpu-process/renderer processes) can leave orphaned child processes behind that still hold the app's single-instance lock. Every subsequent launch attempt then silently blocks on that lock instead of opening a window — looks like the launcher (or the desktop entry) has just stopped working, but the process list shows a new attempt actually starting and then going nowhere (no gpu-process/renderer children spawn, unlike a healthy launch).

**Fix:** kill the leftover process tree, then relaunch:
```bash
ps aux | grep -i "UP Studio\|UPStudio.exe\|wineserver" | grep -v grep   # find the stale PIDs
kill <pids>              # SIGTERM first
kill -9 <stubborn pids>   # if any don't die
```
A lone `<defunct>` zombie entry is harmless (no live process behind it, gets reaped automatically) — the real signal is a main `UPStudio.exe` process from an *old* launch still running alongside a new one that never spawns its gpu-process/renderer children.

**Prevention:** close the app normally (File → Exit / window close) rather than force-quitting when possible, so it can tear down its own process tree.

---

## USB/serial caveat (read before troubleshooting a "can't see the printer" issue)

Flatpak sandboxing and host `udev` permissions are two separate gates, and **both** have to pass:

- Bottles' Flathub manifest ships broad device access (`--device=all`) by default, so the sandbox itself isn't usually the blocker.
- The **host user** still needs `dialout` group membership (or whatever group the vendor's udev rule assigns) to open `/dev/ttyUSB0` — Flatpak's sandbox runs as the same host UID, it doesn't bypass kernel-level file permissions. This layer adds `rabble_user` to `dialout`, but **group membership requires a new login session** to take effect — log out/in (or reboot) after first `apply bottles`.
- If a specific bottle still can't see the device, check permissions with Flatseal (`flatpak install flathub com.github.tchx84.Flatseal`) before assuming it's a Wine-side problem.

---

## Quick Reference

```bash
# Apply (installs Bottles + dialout group membership)
bash RaBbLE-OS-layerctl.sh apply bottles

# Dry-run first
bash RaBbLE-OS-layerctl.sh apply bottles --check

# Health check
bash RaBbLE-OS-layerctl.sh verify bottles

# What `apply bottles` actually runs under the hood:
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml \
  --tags bottles --extra-vars rabble_enable_wine_bottles=true -K
```

No teardown task exists yet (`remove bottles` will no-op — no other layer in this repo has a `remove`-tagged task path implemented either).

---

→ [Layer-Bottles-Debugging](RaBbLE-OS-Layer-Bottles-Debugging.md) — general "Windows app won't start under Bottles" troubleshooting playbook
→ [Hardware-Cetus3D-MK2](../hardware/RaBbLE-OS-Hardware-Cetus3D-MK2.md) — the printer that motivated this layer, setup steps for UP Studio inside a bottle
→ [Layers overview](RaBbLE-OS-Layers.md)
→ `ansible/packages/manifest.yml` — `layer/bottles` section, package source-of-truth
