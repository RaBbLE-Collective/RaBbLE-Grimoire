# RaBbLE-Pocket-Firmware-BuildFlash.md

Worked build+flash walkthrough for the Waveshare ESP32-S3-Touch-AMOLED-1.75-B, verified end to end 2026-08-08. Toolchain/architecture background: `RaBbLE-Pocket-Architecture.md`. Board spec: `RaBbLE-Pocket-Hardware.md`.

## Prerequisites

- RaBbLE-OS `layer/esp-idf` applied (`bash RaBbLE-OS-layerctl.sh apply esp-idf`) — installs EIM CLI + provisions ESP-IDF versions under `~/esp/esp-idf-eim/<version>/`.
- `firmware/.esp-idf-version` pins the version this project uses (currently `v5.5.4`).
- Board connected over USB-C. It enumerates as **native USB-Serial/JTAG** (`303a:1001` in `lsusb`), device node `/dev/ttyACM0`. No external UART adapter needed.

## Activating the toolchain

```sh
cd ~/RaBbLE-Collective/RaBbLE-Pocket
source ops/esp-idf-select.sh   # once per shell — defines the pocket-idf function
pocket-idf                     # resolves firmware/.esp-idf-version and activates it
```

**Gotcha (fixed 2026-08-08):** `esp-idf-select.sh` originally sourced `<version>/export.sh` directly, assuming a plain upstream ESP-IDF checkout layout. But EIM installs don't use that layout — EIM manages its own venv/toolchain paths (keyed differently from stock `export.sh`'s expectations) and writes its **own** activation script per version at `~/.espressif/tools/activate_idf_<version>.sh`. Sourcing the plain `export.sh` fails with `ESP-IDF Python virtual environment ... not found` because it looks for the venv at a path EIM never used. Fix: activate via `eim`'s own script (confirmed correct source of truth: `eim list` and `~/.espressif/tools/eim_idf.json` both point at `activate_idf_<version>.sh`). `esp-idf-select.sh` now sources that instead — verify `pocket-idf` again after any EIM version-management change.

**Gotcha (fixed 2026-08-08): never pipe an activating command.** `pocket-idf | tail` (or any pipe) forks the left-hand side into a subshell — the environment `pocket-idf` just activated dies with that subshell the instant the pipe finishes, so the calling shell never actually gets the toolchain. This isn't a bug to fix, it's inherent to how shell activation works (same reason `. script.sh | anything` is always wrong) — just don't pipe it. Redirection (`pocket-idf > log 2>&1`) is fine; only pipes fork a subshell.

**One-shot alternative:** `ops/build-flash.sh <project-dir>` wraps config+build+flash(+monitor) into one executed command — see below.

## One-shot: `ops/build-flash.sh`

```sh
ops/build-flash.sh firmware/<project>                 # build + flash, port auto-detected
ops/build-flash.sh firmware/<project> -m               # + read serial after (raw fallback if no TTY)
ops/build-flash.sh firmware/<project> -B               # build only
ops/build-flash.sh firmware/<project> -p /dev/ttyACM0 -t esp32s3
```

Collapses the manual config/build/flash/monitor sequence for repeat iteration. Verified end to end against `02_lvgl_demo_v9`: auto-detected `/dev/ttyACM0`, built, flashed, and read the boot log confirming PSRAM init, CO5300 panel bring-up, and CST9217 touch registration (`Resolution X: 466, Y: 466`).

**Gotcha found building it: eim's activation script misdetects sourced-vs-executed one level deep.** `pocket-idf` plain-sources `activate_idf_<v>.sh`, and that script self-checks whether it's actually being sourced (vs. run directly) by comparing `$0` against a list of known shell names (`bash`, `-bash`, `zsh`, etc. via `$ZSH_EVAL_CONTEXT`). That check is correct at the true top level of an interactive shell — but when `pocket-idf` itself is called from *inside another executed script* (like `build-flash.sh`), `$0` is that script's own path, not a recognized shell name, so eim wrongly concludes "not sourced" and refuses to run (`This script should be sourced, not executed.`). Separately, that same script references `$ZSH_VERSION`/`$BASH_VERSION` with no default, which is fine under normal shell semantics but fatal under `set -u` (`nounset`). Fix: `esp-idf-select.sh` now exposes a second function, `pocket_idf_activate_for_script`, which uses eim's documented `-e` flag (prints `KEY=VALUE` env vars, no sourced-detection at all) instead of plain-sourcing — used by `build-flash.sh`, safe under `set -u`. `pocket-idf` itself is unchanged and still the right choice for interactive shell use (keeps tab-completion registration + the friendly activation messages, neither of which the `-e` path provides). One more knock-on effect: `-e` mode doesn't define the `idf.py` shell function eim's main branch does — `build-flash.sh` calls it directly via `"$IDF_PYTHON_ENV_PATH/bin/python" "$IDF_PATH/tools/idf.py"` instead.

## Worked example 1 — pure toolchain smoke test (`hello_world`)

Confirms compiler/linker/flash/monitor pipeline with zero board-specific dependencies — good first check after any toolchain change.

```sh
cp -r "$IDF_PATH/examples/get-started/hello_world" /tmp/hello_world
cd /tmp/hello_world
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/ttyACM0 flash
```

Result: builds clean (~2 min), flashes in a few seconds. Confirmed chip identity on flash: **ESP32-S3 (QFN56) rev v0.2, WiFi+BLE, 8MB PSRAM (AP_3v3)** — matches the ESP32-S3R8 spec in `AGENT.md` and `RaBbLE-Pocket-Hardware.md`.

`hello_world` has **no LVGL/display output** — it only prints chip info and a restart countdown over serial console.

## Worked example 2 — board bring-up with LVGL (`02_lvgl_demo_v9`)

Vendor example at `firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/examples/esp-idf/02_lvgl_demo_v9`. This one actually drives the CO5300 AMOLED panel + CST9217 touch + renders LVGL — a real board bring-up test, not just a toolchain check.

```sh
cp -r firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/examples/esp-idf/02_lvgl_demo_v9 /tmp/lvgl_demo_v9
cd /tmp/lvgl_demo_v9
idf.py set-target esp32s3   # first run also fetches component-manager deps (network required)
idf.py build
idf.py -p /dev/ttyACM0 flash
```

`main/idf_component.yml` declares the dependencies pulled from the ESP Component Registry on first configure: `waveshare/esp32_s3_touch_amoled_1_75` (board BSP: CO5300 panel driver, CST9217 touch, TCA9554 IO expander, `esp_codec_dev` audio) and `lvgl/lvgl@9.4.*`. These land in `managed_components/`, resolved automatically — no manual vendoring needed.

`sdkconfig.defaults` sets `CONFIG_ESPTOOLPY_FLASHSIZE_16MB` + QIO mode — matches the board's actual 16MB external flash (confirmed against `HARDWARE_REFERENCE.md`: "8 MB PSRAM, external 16 MB flash"). Trust the vendor's `sdkconfig.defaults` for board-accurate flash/PSRAM settings rather than IDF's generic 2MB default (which `hello_world` above uses and which under-declares but doesn't break on this board — just don't carry that default forward into real firmware).

## Worked example 3 — Brookesia (two things share the name)

The vendor repo has **two** separate Brookesia builds — check which one you mean before flashing:

| | `examples/esp-idf/03_esp-brookesia` | `firmware/brookesia` |
|---|---|---|
| Scope | Brookesia framework demo (SquareLine demo app only) | Full 13-app factory suite — Calculator, Gallery, MusicPlayer, VideoPlayer, Recorder, Settings, AIChats (wake-word + Opus), Gravitysphere, Crosshair, Button Test |
| Relation to stock firmware | Unrelated demo | **This is the source the factory recovery image is built from** — README: "Brookesia source — Maintain or rebuild the application suite with ESP-IDF v5.5.4" |
| App size | ~2.6MB | ~6.4MB app + a `storage.bin` SPIFFS image (music/asset fallback) |
| Extra flashed images | bootloader + app + partition table | + `srmodels.bin` (ESP-SR wake-word models, for AIChats) + `storage.bin` |

Build/flash either with the one-shot wrapper (see below) — `idf.py flash` (which the wrapper calls) reads `flasher_args.json` and flashes every declared image automatically, srmodels/storage included, no special-casing needed:

```sh
ops/build-flash.sh firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/firmware/brookesia -m               # full app suite
ops/build-flash.sh firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/examples/esp-idf/03_esp-brookesia -m # framework demo only
```

If it's noticeably nicer than what the board shipped with, that's `firmware/brookesia` — a fresh build from source is the natural "upgrade the stock image" path.

## Gotchas hit during verification

- **`idf.py monitor` needs a real interactive TTY.** Fails with `Monitor requires standard input to be attached to TTY` in a non-interactive/headless shell (e.g. driven by an agent, CI, or piped). Fallback for reading live serial output without the interactive monitor:
  ```sh
  stty -F /dev/ttyACM0 115200 raw -echo
  timeout 10 cat /dev/ttyACM0 | strings
  ```
- **The board can drop off USB entirely between operations** — not just the `/dev/ttyACM0` node disappearing, but vanishing from `lsusb` altogether (native USB-Serial/JTAG re-enumeration quirk, possibly related to a raw-`cat` serial session not closing the port cleanly, or just a loose USB-C connection). Symptom: `esptool.py` fails with `Could not open /dev/ttyACM0, the port is busy or doesn't exist`. Fix: re-check `lsusb | grep -i esp` before flashing if the board has been idle since the last serial interaction; re-seat the cable if it's still missing.
- Build in a scratch dir (e.g. this session used the Claude Code scratchpad), not inside `firmware/vendor/...` directly — keeps `build/`/`managed_components/` out of the vendor reference clone even though that tree is already gitignored.
- **`esp-idf-select.sh` wasn't zsh-safe (fixed 2026-08-08).** Mark's shell is zsh, and the script is meant to be sourced into it directly — but it used `mapfile` (bash-4+ only, undefined in zsh) and `${versions[0]}` to grab a single-element array (zsh arrays are 1-indexed by default, bash's are 0-indexed, so a hardcoded index is wrong in one or the other). Both only surfaced when the interactive picker path ran (no `.esp-idf-version` pin above `$PWD` and no explicit version arg) — the common case, where the pin resolves without touching that code, masked it. Fixed: a portable `while read` loop instead of `mapfile`, and `${versions[*]}` (correct under both indexing schemes for a single element) instead of `${versions[0]}`.

## Related

- `RaBbLE-Pocket-Architecture.md` — day-to-day command template, ESP-IDF-over-Arduino decision
- `RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-multiversion-and-eim.md` — per-project version pinning design
- `RaBbLE-OS/layers/RaBbLE-OS-Layer-ESP-IDF.md` — machine-level layer that provisions EIM + ESP-IDF versions
- `RaBbLE-OS/layers/RaBbLE-OS-Layer-Arduino-CLI.md` — sibling opt-in layer for building the vendor's `.ino` examples only; RaBbLE-Pocket's own firmware stays on ESP-IDF. Its own one-shot wrapper: `ops/arduino-flash.sh <sketch-dir> [-m]` (untested as of writing — the layer isn't applied on this machine yet)
