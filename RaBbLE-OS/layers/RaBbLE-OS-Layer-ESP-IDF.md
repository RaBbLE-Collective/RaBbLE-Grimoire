# RaBbLE-OS Layer — ESP-IDF

> Ansible layer tag: `esp-idf` (also responds to `layer`)
> layerctl: `bash RaBbLE-OS-layerctl.sh apply esp-idf`
> Opt-in var: `rabble_enable_esp_idf` (default `false` — see `ansible/roles/layer/esp-idf/defaults/main.yml`)
> Role: `ansible/roles/layer/esp-idf/`

Installs Espressif's ESP-IDF embedded toolchain for RaBbLE-Pocket firmware development (Waveshare ESP32-S3-Touch-AMOLED-1.75). ADR for choosing ESP-IDF over Arduino: `RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-over-arduino.md`. Toolchain rundown: `../RaBbLE-Pocket/RaBbLE-Pocket-Architecture.md`.

ESP-IDF itself is **not a Fedora package** — Espressif ships it as a `git clone` + a self-contained `install.sh` that downloads its own cross-compiler toolchain and builds a private Python venv under `~/.espressif/`. This layer installs the dnf-packaged build *prerequisites* that `install.sh` needs already present on the system, then does the clone + install as the regular user (not root — `become: false` on those two tasks, overriding the play's default `become: true`).

Third reference implementation of the `layer/*` optional-feature-group pattern (see `RaBbLE-OS-Layer-Bottles.md` and `RaBbLE-OS-Layer-Containers.md`). Neither `apply all` nor `upgrade` installs this layer — only an explicit `apply esp-idf`.

---

## What the layer installs

| Step | What | Why |
|---|---|---|
| dnf prerequisites | `git wget flex bison gperf python3-pip cmake ninja-build ccache dfu-util libusbx openssl-devel libffi-devel` | Espressif's documented Linux/Fedora build prerequisites for `install.sh` |
| `dialout` group | `rabble_user` appended | The board enumerates as `/dev/ttyACM*`; `idf.py flash` (esptool.py) needs this to open the port without `sudo` — same rationale as `layer/bottles`' USB/serial task. **Requires a new login session to take effect.** |
| ESP-IDF clone | `git clone -b v5.5.4 --recursive https://github.com/espressif/esp-idf.git ~/esp/esp-idf` | Pinned to match Waveshare's Brookesia reference firmware validation for this board |
| `install.sh esp32s3` | run from `~/esp/esp-idf`, as the regular user | Downloads the xtensa-esp32s3 cross-compiler + builds the Python venv under `~/.espressif/` |

`esp_idf_version` (`v5.5.4`) and `esp_idf_target` (`esp32s3`) live in `ansible/roles/layer/esp-idf/vars/main.yml` if either ever needs to change (e.g. porting to the 1.75C board or a different chip).

---

## Using it day to day

Not sourced into every shell by default — this is opt-in project tooling, not a system-wide PATH addition. Activate per session:

```bash
. ~/esp/esp-idf/export.sh
idf.py -C ~/RaBbLE-Collective/RaBbLE-Pocket/firmware/<project> -B build/<project> set-target esp32s3 build
idf.py -C ~/RaBbLE-Collective/RaBbLE-Pocket/firmware/<project> -B build/<project> -p /dev/ttyACM0 flash monitor
```

Espressif's own convention is a shell alias (commonly named `get_idf`) that sources `export.sh` on demand — add one to your zsh config if you want it, not wired into dotctl by this layer (kept as an explicit per-session activation, matching "local-first, no always-on daemon" posture elsewhere in RaBbLE-OS).

For VSCode IntelliSense without any Espressif extension: `idf.py build` generates `build/compile_commands.json` — point `C_Cpp.default.compileCommands` at it.

---

## Verify

```bash
bash RaBbLE-OS-layerctl.sh verify esp-idf   # test -f ~/esp/esp-idf/export.sh && test -d ~/.espressif/python_env
. ~/esp/esp-idf/export.sh && idf.py --version
```

If `dialout` group membership doesn't seem to be working (permission denied opening `/dev/ttyACM0`), log out and back in — same gotcha as `layer/bottles`' USB/serial group.

→ `RaBbLE-OS-Layer-Bottles.md` — the `layer/*` pattern this follows
→ `RaBbLE-OS-Layer-Containers.md` — second reference implementation
→ `../../RaBbLE-OS/ansible/packages/manifest.yml` — package declarations (`layer.esp-idf` category)
→ `../RaBbLE-Pocket/RaBbLE-Pocket-Architecture.md` — full toolchain rationale + Arduino porting notes
