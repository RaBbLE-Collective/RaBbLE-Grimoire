# RaBbLE-OS Layer — Arduino CLI

> Ansible layer tag: `arduino-cli` (also responds to `layer`)
> layerctl: `bash RaBbLE-OS-layerctl.sh apply arduino-cli`
> Opt-in var: `rabble_enable_arduino_cli` (default `false` — see `ansible/roles/layer/arduino-cli/defaults/main.yml`)
> Role: `ansible/roles/layer/arduino-cli/`

Installs `arduino-cli` + the ESP32 Arduino core, scoped to one purpose: building the vendor's reference `.ino` examples (`RaBbLE-Pocket/firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/examples/arduino/`) for comparison against the ESP-IDF path. **RaBbLE-Pocket's actual firmware stays on ESP-IDF** — see the ADR that decided this: `RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-over-arduino.md`. This layer doesn't reopen that decision; it just makes the vendor's Arduino sketches buildable when useful as a reference.

Fourth reference implementation of the `layer/*` optional-feature-group pattern (see `RaBbLE-OS-Layer-Bottles.md`, `RaBbLE-OS-Layer-Containers.md`, `RaBbLE-OS-Layer-ESP-IDF.md`). Neither `apply all` nor `upgrade` installs this layer — only an explicit `apply arduino-cli`.

**Scaffolded, not yet live-verified (2026-08-08):** the tasks follow arduino-cli's documented config/core-install flow, but the exact ESP32 board-index URL (`arduino_esp32_board_index_url` in `vars/main.yml`) is Espressif's currently-documented one — arduino-esp32 has relocated it across major core versions before. Confirm with `arduino-cli core update-index` output after the first `apply arduino-cli`.

The core version itself (`esp32:esp32@3.3.10`) and the board FQBN config (`FlashSize=16M,PartitionScheme=app3M_fat9M_16MB`) **are** vendor-confirmed, not guessed — straight from `firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/docs/getting-started.md`'s own "Build with Arduino" section, which gives the exact `arduino-cli compile --fqbn ...` invocation Waveshare validated their examples against.

---

## What the layer installs

| Step | What | Why |
|---|---|---|
| `arduino-cli` binary | Latest GitHub release tarball, extracted to `~/.local/bin/arduino-cli` | No dnf package — same not-a-repo-package situation as EIM in `layer/esp-idf` |
| config init | `arduino-cli config init` | First-run config file, `~/.arduino15/arduino-cli.yaml` |
| ESP32 board index | `arduino-cli config add board_manager.additional_urls <espressif index>` + `core update-index` | Registers Espressif's board-manager index so `core install esp32:esp32` resolves |
| ESP32 core | `arduino-cli core install esp32:esp32` | The core the vendor's `examples/arduino/*.ino` sketches target |
| `dialout` group | `rabble_user` appended | Same board, same native USB-Serial/JTAG port as `layer/esp-idf` — redundant if that layer's already applied, but this layer must stand alone too |

`arduino_cli_version`, `arduino_cli_bin_dir`, `arduino_esp32_core`, `arduino_esp32_board_index_url` all live in `ansible/roles/layer/arduino-cli/vars/main.yml`.

**Deliberately not installed by this layer:** the bundled libraries the vendor examples depend on (`ESP32_IO_Expander`, `GFX_Library_for_Arduino`, `SensorLib`, `XPowersLib`, `esp-lib-utils`, `lvgl`+`lv_conf.h`) already ship inside the vendor repo at `firmware/vendor/.../examples/arduino/libraries/` — point `arduino-cli compile --libraries` at that directory rather than fetching them again through the Arduino Library Manager. Keeps this layer to just the toolchain, matching the machine-level/project-level split `layer/esp-idf` + `ops/esp-idf-select.sh` already use.

---

## Using it

One-shot wrapper (mirrors `ops/build-flash.sh`'s ESP-IDF flow — port auto-detect, `-B` build-only, `-m` monitor with a non-TTY fallback):

```bash
ops/arduino-flash.sh firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/examples/arduino/01_HelloWorld -m
```

Manual, equivalent to what the wrapper runs:

```bash
~/.local/bin/arduino-cli compile \
  --fqbn "esp32:esp32:esp32s3:FlashSize=16M,PartitionScheme=app3M_fat9M_16MB" \
  --libraries firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/examples/arduino/libraries \
  firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/examples/arduino/01_HelloWorld

~/.local/bin/arduino-cli upload \
  --fqbn "esp32:esp32:esp32s3:FlashSize=16M,PartitionScheme=app3M_fat9M_16MB" \
  -p /dev/ttyACM0 \
  firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/examples/arduino/01_HelloWorld
```

---

## Verify

```bash
bash RaBbLE-OS-layerctl.sh verify arduino-cli   # arduino-cli on PATH + esp32:esp32 core installed
~/.local/bin/arduino-cli core list
```

→ `RaBbLE-OS-Layer-ESP-IDF.md` — the sibling layer for RaBbLE-Pocket's actual firmware toolchain
→ `../../RaBbLE-OS/ansible/packages/manifest.yml` — package declaration (`layer.arduino-cli` category)
→ `../RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-over-arduino.md` — why the real firmware isn't built this way
