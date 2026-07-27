# RaBbLE-OS — Debugging a Windows App That Won't Start Under Bottles

```
transcribe ~ grimoire >> a proprietary printer's installer taught the whole method // %BOTTLES_DEBUG_PLAYBOOK%
```

> **What this is:** a general troubleshooting playbook for "the Windows EXE installs but hangs / won't launch / silently fails" under Bottles (Wine), distilled from getting TierTime UP Studio (Cetus3D MK2 slicer) working — three real bugs found and fixed, one still open. Written so the *next* Windows app hitting a wall under Bottles (Affinity Suite is next in line) doesn't have to re-derive any of this.
>
> **Related:** [Layer-Bottles](RaBbLE-OS-Layer-Bottles.md) — the Ansible layer itself · [Hardware-Cetus3D-MK2](../hardware/RaBbLE-OS-Hardware-Cetus3D-MK2.md) — the worked example this was extracted from

---

## The core lesson: verify empirically, don't trust docs or memory

Three separate mistakes this session came from trusting an unverified source over checking the real system directly:

1. Assumed `bottles-cli run` had a `-a ARGS` flag (from a search-summarized doc page) — it doesn't. `bottles-cli run --help` (on the actual installed CLI) showed the real syntax in ten seconds.
2. Assumed a CUPS-printer-enumeration hang was the root cause of a startup freeze, based on a plausible-sounding correlation (an open IPP connection). It wasn't — the real cause (a drive-relative path bug) surfaced only after enabling Wine debug tracing and reading the actual log.
3. Assumed TierTime's KB article on "MSI silent installation" documented real `msiexec` flags. It didn't (the article just links an old MSI download) — the actual silent-install behavior was confirmed by inspecting the extracted binary's strings and testing `/quiet` directly.

**Rule of thumb:** every one of these got resolved faster by running one real command against the live system than by reasoning about what "should" be true. When in doubt, check `--help`, check `strings`, check the actual log file, check the actual running process — don't extrapolate from a doc summary or a plausible theory.

---

## Step 1: is it actually stuck, or just slow?

Process-level signals (CPU%, wait channel, whether the log is growing) **cannot distinguish** "hung forever" from "fully loaded and idling, waiting for you to click something" — both look identical to `ps`. The only real signal is what's rendered on screen.

```bash
# Find the window regardless of which workspace it's on
hyprctl clients | grep -E "^Window|class:|workspace:|title:"

# Switch to its workspace, screenshot, switch back (restores your view)
hyprctl dispatch workspace <N>
sleep 1
grim -o eDP-1 /tmp/check.png
hyprctl dispatch workspace <original>
```
Then actually read the screenshot. Compare two screenshots ~15s apart — pixel-identical means genuinely stuck; anything different means real progress.

**Gotcha:** `hyprctl`/`grim` may not be in a restricted shell's `PATH` even when `HYPRLAND_INSTANCE_SIGNATURE`/`WAYLAND_DISPLAY` are set correctly — use the full path (`/usr/bin/hyprctl`) if `command -v` comes up empty.

A window with an **empty title** that never changes is itself a signal — a healthy app usually sets a real title once its main UI is up.

---

## Step 2: get Wine debug output — but launch it correctly

`WINEDEBUG` set in your own shell **will not** reach the process if you launch via `flatpak run --command=bottles-cli ...` — `bottles-cli` does not forward arbitrary parent environment variables (confirmed: Bottles' bottle config has an explicit `Inherited_Environment_Variables` whitelist, and `WINEDEBUG` isn't on it).

**Fix: set it in the bottle's own config**, which Bottles reads fresh on every launch:
```yaml
# ~/.var/app/com.usebottles.bottles/data/bottles/bottles/<Bottle>/bottle.yml
Environment_Variables:
    WINEDEBUG: +loaddll,+seh,+process,+thread
```
Edit this directly (it's a supported Bottles feature, same as their GUI's environment-variables settings panel) — then launch normally through `bottles-cli run` and redirect its output to a file:
```bash
nohup flatpak run --command=bottles-cli com.usebottles.bottles run -b <Bottle> -p <Program> \
  > ~/.var/app/com.usebottles.bottles/data/bottles/bottles/<Bottle>/debug.log 2>&1 &
disown
```

**Useful channel set:** `+loaddll,+seh,+process,+thread` — catches DLL load sequence, the app's own `OutputDebugString`-based logging (routed through Wine's SEH machinery), and process/thread churn, without the overwhelming volume of full `+relay` (every single Win32 call). Add `+relay=<dllname>` to scope relay logging to one DLL if you need call-level detail on something specific.

**Don't bypass `bottles-cli` to invoke `wine64` directly** to get around the env var problem — it skips environment/DLL-override setup Bottles normally configures, and in testing this produced a process that ran but **never painted a window at all** (different, worse failure mode than the one being diagnosed). Fix the env var through `bottle.yml` instead, not by working around the launcher.

**Don't mistake `OutputDebugString`-driven noise for a crash.** `trace:seh:dispatch_exception code=4001000a` / `code=40010006` are `DBG_PRINTEXCEPTION_WIDE_C`/`DBG_PRINTEXCEPTION_C` — this is how `OutputDebugStringW`/`A` are implemented (a first-chance SEH exception carrying the debug string, always caught and handled). Seeing hundreds of these is normal Wine/app logging, not evidence of a crash loop by itself. What matters is the **actual string being logged** (in the `warn:seh:OutputDebugStringW L"..."` lines) and whether the **same one repeats forever** — that's the real signal of a stuck retry loop.

---

## Step 2b: use Bottles' own binary analyzer ("Eagle") before guessing dependencies

Bottles ships a GUI-only feature (right-click a program → "Analyze with Eagle") that inspects the actual installed EXE and reports: detected framework (Electron/CEF/Qt/etc.), required runtimes (VC++ version, .NET), installer technology, and suggested overrides (Esync/GameMode/discrete GPU/Virtual Desktop). It's not exposed via `bottles-cli` — ask whoever has GUI access to run it and paste the report — but it's a genuinely reliable way to identify what a binary actually needs instead of guessing.

**Installing a missing runtime it flags (e.g. VC++ 2015-22) via CLI:** Bottles' own "Dependencies" installer panel is also GUI-only. Use `winetricks` directly instead — but **not** through `bottles-cli shell`:
```bash
# WRONG — bottles-cli shell -i runs the string INSIDE the Windows/Wine environment,
# not on the host. It'll look for a Windows winetricks.exe and fail:
#   "ShellExecuteEx failed: File not found."
flatpak run --command=bottles-cli com.usebottles.bottles shell -b <Bottle> -i "winetricks vcrun2015"   # don't do this

# RIGHT — invoke the real host-side winetricks script, pointed at the bottle's prefix:
flatpak run --command=bash com.usebottles.bottles -c \
  "export WINEPREFIX='$HOME/.var/app/com.usebottles.bottles/data/bottles/bottles/<Bottle>'; \
   export PATH='$HOME/.var/app/com.usebottles.bottles/data/bottles/runners/<runner>/bin:'\$PATH; \
   winetricks -q vcrun2015"
```
Verify it actually landed: `find <bottle>/drive_c/windows/system32 -iname "vcruntime140.dll"`.

**Toggling the overrides Eagle suggests** (Esync/GameMode/discrete GPU) doesn't need the GUI either — they're plain fields under `Parameters:` in `bottle.yml`, same file/technique as the `WINEDEBUG` trick above (`sync: wine|esync|fsync`, `gamemode: true|false`, `discrete_gpu: true|false`). Kill the bottle's wineserver before retesting a `sync` change — an old wineserver started under a different sync mode will throw `err:esync:esync_init Failed to open esync shared memory file` for any new process until it's gone.

**`discrete_gpu: true` is not free on a hybrid-GPU laptop.** It changes which GPU renders the app (visible in the launched process's own args, e.g. `--gpu-vendor-id=0x10de` for NVIDIA vs `0x1002` for AMD) — confirm the change took by checking that, not just by assuming the YAML edit worked. On a laptop where the discrete GPU has no direct display path, this can also change *which workspace/output the window ends up on* — don't conclude "no window rendered" from one workspace screenshot after changing this; check `hyprctl clients` for where the window actually landed before assuming a regression.

---

## Step 3: know these two structural Bottles/Wine gotchas — they show up in almost any app

### A. Bottles' Flatpak sandbox has zero filesystem access beyond its own app data by default

```bash
flatpak info --show-permissions com.usebottles.bottles
# [Context] block — if there's no "filesystems=" line at all, nothing outside
# ~/.var/app/com.usebottles.bottles/ is visible to the sandboxed process.
```
Consequences:
- An installer or file staged anywhere else (`~/Downloads`, `~/.cache`, a custom host directory) is reported as **"does not exist"** by `bottles-cli`/Wine even though it plainly exists on the host. Stage files under `~/.var/app/com.usebottles.bottles/data/...` instead, or explicitly grant access:
  ```bash
  flatpak override --user com.usebottles.bottles --filesystem=/some/host/path
  ```
- This is not optional/cosmetic — creating a directory on the real host does **nothing** for the sandboxed app until the override is also applied. (Confirmed the hard way: created `/Tiertime/Log` on the host, `chown`'d it correctly, and the app still couldn't see it until the `--filesystem=/Tiertime` override was added.)

### B. Wine's `Z:` drive is your real host filesystem root — drive-relative paths can silently target it

Real Windows resolves a path starting with a single `\` or `/` (no drive letter) against the **current drive** of the process. Under Wine, if a process's working directory isn't on `C:`, its current drive is `Z:` — which Wine maps straight to the real host `/`. So an app that builds a path like `/Foo/Bar` (common in cross-platform-ported C++ code that assumes POSIX semantics, or just sloppy string concatenation) can end up trying to create/read/write **`/Foo/Bar` on your actual Linux filesystem**, which a normal user can never write to at the root (`dr-xr-xr-x`, root-owned).

Symptom: an infinite retry loop hammering the same failing path, usually visible via `WINEDEBUG=+seh` as a repeating `OutputDebugString`, NOT in the app's own log file (different logging subsystem).

Two independent fixes, both usually needed together:
1. **Get the process's working directory onto `C:`.** For `bottles-cli`, this means launching with `-p <ProgramName>` (registered program — uses that program's own folder as cwd), **not** `-e <path>` (raw executable path — sets no working directory at all). Check `bottles-cli programs -b <Bottle>` for the registered name Bottles auto-detected (usually the exe's own internal product name, which may differ from the filename — e.g. `UPStudio`, not `UPStudio.exe`).
2. **Belt-and-suspenders: create the literal path(s) on the real host too, plus the Flatpak override from (A).** Even with the working directory fixed, not every code path in a given app necessarily benefits (multi-process apps, background threads, or code that computes an absolute path a different way may still hit it). If you see the same bad path in the trace, just create it: `sudo mkdir -p /TheBadPath && sudo chown $USER:$USER /TheBadPath`, then grant the Flatpak override.

---

## Step 4: other things that bite when scripting this from an agent/harness shell

- **`pkill -f`/`pgrep -f` self-match.** If the pattern string you're searching for (e.g. `"UPStudio.exe"`) appears anywhere in your *own* invoking command line (which it will, since you just typed it), `pgrep -f`/`pkill -f` can match your own shell process. Killing that silently terminates your own session — you'll see the rest of the command batch produce **no output at all** and an unexplained exit code. Fix: get PIDs with `pgrep -f "..."` in one call, then `kill <numeric-pids>` in a **separate** call that doesn't contain the pattern string.
- **Stale process trees after force-quit.** CEF/Chromium-based Windows apps (common for modern cross-platform GUI apps, UP Studio included) spawn a multi-process tree: main process + `--type=gpu-process` + one or more `--type=renderer`. Force-killing just the window can leave orphaned children behind holding the app's single-instance lock — every subsequent launch attempt then silently blocks on that lock (a new process starts per `ps`, but never spawns its own gpu-process/renderer children, and no window appears). Fix: find and kill the **entire** stale tree (`ps aux | grep <exe>`), not just the most recent PID, before relaunching. Prefer closing the app normally (File → Exit) over force-quitting when possible.
- **Verify installer type before guessing silent-install flags.** `strings <extracted.exe> | grep -i "advanced installer\|inno setup\|nullsoft"` identifies the packaging framework in seconds. Advanced Installer bootstrappers (identifiable via `AI_UNINSTALLER=msiexec.exe` and similar `AI_*` property strings) genuinely forward standard `msiexec` switches like `/quiet` — but a working silent flag doesn't guarantee a working *install*: a bundled custom action (e.g. installing a real Windows driver) can still fail every time under Wine regardless of UI mode, rolling back the whole transaction. If `/quiet` produces a clean rollback with nothing installed, don't keep guessing MSI properties blindly — try the full interactive wizard once. It may simply work where the silent path doesn't (confirmed: UP Studio's `WinusbFM` driver custom action fails under `/quiet` every time, but installs fine via the full wizard — root cause of that specific difference wasn't chased further once a working path existed).

---

## Step 5: debugger attach — the escalation of last resort, and its own gotchas

Confirmed 2026-07-26 (getting UP Studio 2's still-open splash-screen hang). Two independent debuggers, two different failure modes:

**`winedbg --gdb <pid>` (the "correct" tool — knows Wine's PE-level symbols) has to run *inside* the same Flatpak sandbox instance as the target, which is its own trap:**
- Every fresh `flatpak run --command=... <app-id> ...` opens a **brand-new sandbox instance with its own PID namespace**. It cannot see processes started by an *earlier* `flatpak run` — `ps`/`pgrep` from a second invocation will come up empty even though the app is plainly still running.
- Fix: `flatpak ps` to find the running instance's numeric ID, then `flatpak enter <instance-id> bash` to get a shell **inside that same live sandbox**. Only then do in-sandbox PIDs resolve to the right process — and note in-sandbox PIDs are their own numbering, different from the host's `ps` view of the same process (a process that's PID 72146 on the host can be PID 44 inside its own sandbox — cross-reference via `cmdline`, not the number).
- Even after correctly entering the sandbox and targeting the right in-sandbox PID, the attach itself can still fail: `Can't attach process <hex-pid>: error 87`. Ruled out: Flatpak permissions (`flatpak info --show-permissions` showed `features=devel` already granted — that's the flag that's supposed to allow this) and YAMA (`ptrace_scope` read `0` both on the host and inside the sandbox). **Leading unconfirmed suspect: SELinux** (Fedora runs Enforcing by default) — confirming needs `sudo ausearch -m avc -ts recent | grep denied` right after reproducing the failure, which needs an interactive root password no automated session has. If you hit this, that's the next command to run, by hand.

**Native host-side `gdb -p <host-pid>` is the fallback that actually works**, no sandbox-entering required — attach it directly from a normal host shell against the PID as seen in plain `ps aux` (yes, this is the *host* PID, different from the in-sandbox one above; Bottles doesn't seem to isolate the actual Wine app processes into as deep a namespace as the `flatpak run` wrapper itself, or at least the host can still see and ptrace into them — gdb prints a `different PID namespaces` warning but the attach and backtrace both still work regardless). The tradeoff: gdb has no idea how to read Wine's internal PE debug info, so every frame in `thread apply all bt` prints as `?? ()` — the only way to get anything useful out of it is `info proc mappings` to identify which `.so`/binary each raw return address actually falls inside. That tells you *which module* (Wine's ntdll unix-side, libc, the app's own code) each thread is stuck in, not the Windows-level function/symbol name — genuinely useful for ruling a busy-loop/crash-loop in or out (check CPU%: 0% across every thread + everything resolving into libc's `poll`/`futex` implementation = a real, well-behaved blocking wait, not a spin), but it won't tell you *which Windows object* the wait is on. That last piece needs the winedbg attach above to actually work.

## Quick reference: escalation order

1. Screenshot it (workspace switch + `grim`). Don't trust process metrics alone.
2. Check `flatpak info --show-permissions <app-id>` for missing filesystem access.
3. Enable `WINEDEBUG` via `bottle.yml`'s `Environment_Variables`, launch through the normal `bottles-cli` path, read the log.
4. Look for a repeating `OutputDebugString` message — that's usually the app telling you exactly what's wrong, just not through its own log file.
5. Check whether the process's working directory is on `C:` (`-p` vs `-e`) if you see bare `/path` style failures.
6. If none of that surfaces a lead: a debugger attach for a real stack trace of the blocked thread is the next real step (see Step 5 above for the two tools and their respective traps) — bigger time investment, not something to reach for first, and the winedbg path may need a human with a root password to get past an SELinux wall.

---

```
transcribe ~ grimoire >> playbook written so the next EXE doesn't start from zero // %BOTTLES_DEBUG_PLAYBOOK%
```
