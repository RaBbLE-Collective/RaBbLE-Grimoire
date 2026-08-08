# RaBbLE-OS Layer — ESP-IDF

> Ansible layer tag: `esp-idf` (also responds to `layer`)
> layerctl: `bash RaBbLE-OS-layerctl.sh apply esp-idf`
> Opt-in var: `rabble_enable_esp_idf` (default `false` — see `ansible/roles/layer/esp-idf/defaults/main.yml`)
> Role: `ansible/roles/layer/esp-idf/`

Installs Espressif's ESP-IDF embedded toolchain(s) for RaBbLE-Pocket firmware development (Waveshare ESP32-S3-Touch-AMOLED-1.75). ADR for choosing ESP-IDF over Arduino: `RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-over-arduino.md`. ADR for the multi-version + EIM setup below: `RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-multiversion-and-eim.md`. Toolchain rundown: `../RaBbLE-Pocket/RaBbLE-Pocket-Architecture.md`.

ESP-IDF itself is **not a Fedora package** — Espressif ships it as a `git clone` + a self-contained `install.sh` that downloads its own cross-compiler toolchain and builds a private Python venv under `~/.espressif/`. This layer installs the dnf-packaged build *prerequisites* that `install.sh` needs already present on the system, then does the clone + install as the regular user (not root — `become: false` on those tasks, overriding the play's default `become: true`).

**Multiple versions install side by side**, one directory per version (`esp_idf_versions` list in `vars/main.yml`, currently just `["v5.5.4"]`) — Espressif's own toolchain/venv caches under `~/.espressif/` are already keyed by version, so this never collides. Which version a given *project* uses is resolved at the project level, not here — see `RaBbLE-Pocket/ops/esp-idf-select.sh`.

Third reference implementation of the `layer/*` optional-feature-group pattern (see `RaBbLE-OS-Layer-Bottles.md` and `RaBbLE-OS-Layer-Containers.md`). Neither `apply all` nor `upgrade` installs this layer — only an explicit `apply esp-idf`.

---

## What the layer installs

| Step | What | Why |
|---|---|---|
| dnf prerequisites | `git wget flex bison gperf python3-pip cmake ninja-build ccache dfu-util libusbx openssl-devel libffi-devel` | Espressif's documented Linux/Fedora build prerequisites for `install.sh` |
| broader tools | `picocom` (serial terminal), `usbutils` (`lsusb`), `fzf` (nicer picker in `esp-idf-select.sh`, falls back to plain `select` without it) | Generally useful for USB/serial embedded work, not IDF-specific |
| `dialout` group | `rabble_user` appended | The board enumerates as `/dev/ttyACM*`; `idf.py flash` (esptool.py) needs this to open the port without `sudo` — same rationale as `layer/bottles`' USB/serial task. **Requires a new login session to take effect.** |
| ESP-IDF clone(s) | `git clone -b <version> --recursive https://github.com/espressif/esp-idf.git ~/esp/esp-idf-<version>` per entry in `esp_idf_versions` | One directory per version — no collision, see above |
| `install.sh esp32s3` | run from each `~/esp/esp-idf-<version>`, as the regular user | Downloads the xtensa-esp32s3 cross-compiler + builds the Python venv under `~/.espressif/`, per version |
| `~/esp/esp-idf-default` symlink | → `esp_idf_versions[0]` | Fallback for anything assuming one fixed path — `esp-idf-select.sh` doesn't rely on it directly (pin file first, interactive picker second) |
| EIM GUI | `eim-gui-linux-x64.rpm`, latest GitHub release, `disable_gpg_check: true` (unsigned third-party rpm) | Espressif's own multi-version manager — installed because Mark wants all generally-useful official ESP tools present, not because it's the primary workflow here |

**Why GUI only, not GUI+CLI:** `espressif/idf-im-ui` ships `eim-cli` and `eim-gui` as separate release packages that both install to `/usr/bin/eim`. Checked with `rpm -qp --dump` — genuinely different binaries (32MB vs 51MB, different SHA256), so dnf refuses to have both installed at once. Installing GUI since that's what was asked for; swap the release asset in `tasks/main.yml` to `eim-cli-linux-x64.rpm` if CLI-only is ever preferred.

`esp_idf_versions`, `esp_idf_target`, `esp_idf_prereq_packages`, `esp_idf_extra_packages` all live in `ansible/roles/layer/esp-idf/vars/main.yml`.

---

## Using it day to day

Not sourced into every shell by default — this is opt-in project tooling, not a system-wide PATH addition.

**Primary flow — project-aware, via RaBbLE-Pocket's own tooling:**

```bash
cd ~/RaBbLE-Collective/RaBbLE-Pocket
source ops/esp-idf-select.sh      # once per shell (or add to shell rc)
pocket-idf                        # resolves firmware/.esp-idf-version, activates it
idf.py -C firmware/<project> -B build/<project> set-target esp32s3 build
idf.py -C firmware/<project> -B build/<project> -p /dev/ttyACM0 flash monitor
```

`pocket-idf list` shows installed versions + the current pin; `pocket-idf v6.0.2` activates an explicit version; `pocket-idf pin v6.0.2` writes a pin without activating. Full detail: `RaBbLE-Pocket/ops/CONTEXT.md`.

**Manual flow — no project context, one version:**

```bash
. ~/esp/esp-idf-v5.5.4/export.sh
idf.py --version
```

**EIM GUI** — launch from the app grid (`.desktop` entry ships with the rpm) or `eim` from a terminal. Machine-wide version browsing/installing; doesn't know about a project's pin file.

For VSCode IntelliSense without any Espressif extension: `idf.py build` generates `build/compile_commands.json` — point `C_Cpp.default.compileCommands` at it.

---

## Verify

```bash
bash RaBbLE-OS-layerctl.sh verify esp-idf   # ~/esp/esp-idf-default symlink + ~/.espressif/python_env + `eim` on PATH
. ~/esp/esp-idf-v5.5.4/export.sh && idf.py --version
```

If `dialout` group membership doesn't seem to be working (permission denied opening `/dev/ttyACM0`), log out and back in — same gotcha as `layer/bottles`' USB/serial group.

→ `RaBbLE-OS-Layer-Bottles.md` — the `layer/*` pattern this follows
→ `RaBbLE-OS-Layer-Containers.md` — second reference implementation
→ `../../RaBbLE-OS/ansible/packages/manifest.yml` — package declarations (`layer.esp-idf` category)
→ `../RaBbLE-Pocket/RaBbLE-Pocket-Architecture.md` — full toolchain rationale + Arduino porting notes
