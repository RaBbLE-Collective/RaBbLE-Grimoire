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

**Debugger attach, attempted 2026-07-26 — partial success, one real lead ruled out, one wall hit:**

- **`winedbg --gdb <pid>` from inside the Bottles sandbox fails: `Can't attach process 002c: error 87`** (002c = the target PID in hex — winedbg definitely found the right process, the OS-level attach itself is what fails). Confirmed NOT a Flatpak permission gap (`flatpak info --show-permissions` already shows `features=devel` granted) and NOT YAMA (`/proc/sys/kernel/yama/ptrace_scope` reads `0` both on the host and inside the sandbox via `flatpak enter`). Fedora runs SELinux **Enforcing** — an AVC denial is the leading suspect, but confirming it needs `ausearch -m avc` as root, which requires an interactive sudo password this session couldn't supply. **Next session, if picked back up: get Mark to run `sudo ausearch -m avc -ts recent | grep denied` right after reproducing the failed attach** — that either confirms/refutes SELinux in one command.
- **Two real gotchas hit getting even this far, worth keeping for next time:**
  1. **Each fresh `flatpak run --command=... com.usebottles.bottles ...` opens a brand-new sandbox instance with its own PID namespace** — it will NOT see processes started by an earlier `flatpak run` (e.g. the one running `bottles-cli run -b UPStudio -p UPStudio` in the background). `ps`/`pgrep` from a *second* `flatpak run` invocation simply won't find them. Fix: `flatpak ps` to find the running instance's PID, then `flatpak enter <instance-pid> bash` to get a shell *inside that same sandbox* — only then do in-sandbox PIDs (which also differ from the host's own PID numbers for the same process — host PID 72146 was PID 44 inside the sandbox) resolve correctly.
  2. **Native host-side `gdb -p <host-pid>` DOES successfully attach**, bypassing the Flatpak sandbox layer entirely (gdb warns `Target and debugger are in different PID namespaces` but the attach and backtrace still work) — useful as a fallback when winedbg's own attach is blocked, but it gets you native/libc-level frames only, not Wine's PE-level (Windows DLL/symbol) resolution, since gdb has no idea how to read Wine's internal PE debug info. Every frame prints as `?? ()`; the only way to learn anything is cross-referencing raw addresses against `info proc mappings` to identify which `.so`/binary each address falls inside.
- **What the native-gdb backtrace actually showed (all ~20 threads, main included):** every single thread — main UI thread, `wine_threadpool` workers, `wine_mmdevapi`, `wine_sechost` — is parked at one of two return-address pairs, both of which map into `/usr/lib/x86_64-linux-gnu/libc.so.6`'s executable segment (confirmed via `info proc mappings`), consistent with the `poll_schedule_timeout`/`futex_do_wait` wchans already seen per-thread via `/proc/<tid>/wchan`. **This is a meaningful negative result:** nothing is spinning, crashing, or burning CPU (confirmed 0% CPU across the tree) — every thread is a genuine, well-behaved blocking wait. That rules out a busy-loop or crash-retry-loop as the mechanism; whatever's wrong is a real synchronization wait that's never getting satisfied (a classic deadlock shape, or a wait on an external event Wine never delivers) — not visible without PE-level symbol resolution, which is exactly what the blocked winedbg attach would have given.
- **Socket check refines (doesn't overturn) the earlier CUPS finding:** the only open socket on the main process is `[::1]:<ephemeral> → [::1]:631` (CUPS) — but now observed in **`CLOSE-WAIT`**, not `ESTABLISHED` (the state the original investigation described as "stays open but idle"). `CLOSE-WAIT` means CUPS already sent its `FIN` — the peer closed its end — and the local process just hasn't called `closesocket()` on the now-dead handle. That's consistent with a leaked/unmanaged handle, but **not** a live blocking read (a `recv()` on an already-half-closed socket returns immediately with EOF, it doesn't hang) — so this still isn't the mechanism holding the app on the splash screen, just a loose end worth knowing about if a future full winedbg trace turns up CUPS-adjacent code. No live outbound HTTPS/network connection was found anywhere on the process tree at the time of the stall, which weakens a "hanging vendor-version-check network call" theory (tempting given the log's `GetVendorMatVersion ServerVer:1.6 CurVer:1.8` line right before the stall) — if that check were a live blocking network call, there would be a socket to show for it, and there wasn't.
- **Bottom line: the wall is SELinux-shaped, not Wine-shaped.** Get an in-sandbox `winedbg --gdb` attach working (root/AVC investigation needed) and the rest of this — a real Windows-level thread/object backtrace — should fall out in one session. Everything else about the stall (exact repro point, ruled-out causes) is unchanged above.

No further lead was found without a working debugger attach for a real Windows-level stack trace of the blocked thread. Pick this up here if revisited.

**Desktop launcher entry** (so you don't have to run the command above by hand): `tasks/upstudio.yml`'s last tasks check `rabble_upstudio_exe_path` exists and, if so, write `~/.local/share/applications/rabble-upstudio.desktop` with `Exec=... run -b UPStudio -p UPStudio` (the same `-p` form, for the same working-directory reason) — shows up in fuzzel (Super+Space) as "UP Studio (Cetus3D MK2)". `become: false` (user-level XDG dir), idempotent (`ansible.builtin.copy`, only rewrites on change). Icon is a generic freedesktop name (`printer`, resolves via Papirus) — not extracted from the exe; a real icon extraction (`icoutils`: `wrestool` + `icotool`) was deliberately left out as a cosmetic nicety, not the actual ask. Validated with `desktop-file-validate` 2026-07-22.

---

## UP Studio 3 — a separate, working bottle (2026-07-27)

UP Studio 2's startup hang (above) is unresolved, but **UP Studio 3 (build 3.3.4.3) installs and actually launches its main window** in a fresh, independent bottle (`UPStudio3`) — same Ansible-free manual process as UP Studio 2's first bring-up (bottle create → interactive wizard install → `-p` launch), not yet wired into `tasks/upstudio.yml`. TierTime's product page still gates the real download behind a WooCommerce checkout with nothing scrapeable in the HTML (confirmed again 2026-07-26 chasing this exact link) — Mark supplied the direct CDN URL by hand after clicking through it himself: `https://tiertime.s3.us-west-1.amazonaws.com/downloads/UP_Studio3_3.3.4_3%20setup.zip`.

**It launches 3 windows, not 1** — worth knowing before assuming something's broken:
- `UP Studio3 3.3.4` — the main app.
- `Wand 3D Printer Manager` — TierTime's separate WiFi/BT print-controller utility (`Wand.exe`), installed alongside UP Studio 3 under the same `Program Files\UP Studio3\` and **launched automatically** by the main app, not something invoked separately. If you only expected one window, this is why there are more.
- A small (160×20) untitled utility window — origin not investigated, harmless, already floats on its own.

All three report Wine's generic `class: steam_proton` (a Bottles quirk applied to every Wine window regardless of the actual app — do not use it alone to target UP Studio in Hyprland window rules, it would also catch real Steam Proton games). See the Hyprland float rule below for the title-based matching pattern that works instead.

**Not yet done:** connecting to the actual Cetus3D MK2 printer through it — tried once, didn't connect, not chased further. Unknown whether UP Studio 3 hits the same `/Tiertime` drive-relative-path bug UP Studio 2 has (no evidence of it yet, but the printer connection was never reached to say for sure).

**Hyprland: float + dedicated workspace via windowrule; sizing/positioning via a launcher script.** Added to `RaBbLE-OS/config/hypr/conf.d/windowrules.conf` (deployed manually — `cp` of just this one file, not a full `dotctl apply hypr`, since that bundle had unrelated pre-existing drift in `env.conf`/`look.conf` from Mark's own live tweaks that a bundle-wide apply would have silently clobbered):
```
windowrule = float true,      match:title ^(UP Studio.*|Wand 3D Printer Manager.*)$
windowrule = workspace 6,     match:title ^(UP Studio.*|Wand 3D Printer Manager.*)$
```
Matches by **title**, not class, for the `steam_proton` reason above. `workspace 6` is a dedicated slot (first free after 1=term/2=browser/3=files/4=comms/5=VM) so the windows always land somewhere with nothing else already there, same pattern as virt-manager's ws5 assignment elsewhere in the same file — not silent, so Hyprland follows you there on launch.

**`size`/`move` windowrules do NOT stick for these two windows, confirmed 2026-07-27** — they parse with no errors and `float`/`workspace` (same file, same title match) apply correctly, but geometry silently reverts to the app's own default. Root cause: both are XWayland clients (`xwayland: 1` in `hyprctl clients`) that visibly resize/reposition **themselves** shortly after their window first appears (DPI-awareness handshake + CEF layout settling) — whatever windowrule-imposed geometry existed gets overwritten by the app's own later resize. Direct `hyprctl dispatch resizewindowpixel`/`movewindowpixel` by window address does work, but only if applied *after* that self-resize settles — applying it the instant the window is first detected loses the race just like the windowrule did.

**Fix: `RaBbLE-OS/config/hypr/scripts/upstudio3-launch.sh`**, wired into `~/.local/share/applications/rabble-upstudio3.desktop`'s `Exec=` in place of the raw `bottles-cli run` command. Launches the app, polls `hyprctl -j clients` (via `jq`) for each window by exact title, waits a 3s settle period, re-resolves the address (in case the app recreated its window during startup) and places it with `resizewindowpixel`/`movewindowpixel`, then re-checks and re-places once more 2s later as a safety net against a second late self-resize. Also clears fullscreen first if set (Wand entered `fullscreen: 1` unprompted at least once during testing — resize/move are no-ops on a fullscreen window). Confirmed working end-to-end 2026-07-27: main app dominant at 68% width, Wand secondary at 28% width, 2% margins/gap, both 92% height starting at 4% — side-by-side, no overlap, both on ws6 (computed from `hyprctl -j monitors`' focused-monitor resolution, not hardcoded to one panel). The third small (160×20) untitled utility window is still unmanaged (same empty-title-ambiguity reasoning as above) — cosmetic overlap only, not chased.

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
