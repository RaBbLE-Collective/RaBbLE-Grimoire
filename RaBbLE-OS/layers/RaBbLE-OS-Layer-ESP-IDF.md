# RaBbLE-OS Layer — ESP-IDF

> Ansible layer tag: `esp-idf` (also responds to `layer`)
> layerctl: `bash RaBbLE-OS-layerctl.sh apply esp-idf`
> Opt-in var: `rabble_enable_esp_idf` (default `false` — see `ansible/roles/layer/esp-idf/defaults/main.yml`)
> Role: `ansible/roles/layer/esp-idf/`

Installs Espressif's ESP-IDF embedded toolchain(s) for RaBbLE-Pocket firmware development (Waveshare ESP32-S3-Touch-AMOLED-1.75), provisioned via Espressif's own **EIM CLI**. ADRs: `RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-over-arduino.md` (ESP-IDF vs Arduino) · `2026-08-07-esp-idf-multiversion-and-eim.md` (per-project pinning + EIM as a secondary tool) · `2026-08-08-eim-cli-provisioning.md` (EIM CLI became the actual installer, not just a standalone extra). Toolchain rundown: `../RaBbLE-Pocket/RaBbLE-Pocket-Architecture.md`.

**Provisioning goes through `eim install`, not a hand-rolled git-clone + install.sh loop.** EIM (`espressif/idf-im-ui`) is Espressif's own documented, non-interactive-capable multi-version installer + registry (`eim list` reads a real `eim_idf.json`, default `~/.espressif/tools/`) — a better fit than reinventing that mechanism. `eim`'s own prerequisites still need to be present via dnf first (its `--install-all-prerequisites` auto-install flag is Windows-only per `eim install --help`).

**Multiple versions install side by side**, one `--version-name` subdirectory each under a shared `--path` (`esp_idf_eim_path`, `~/esp/esp-idf-eim`) — `esp_idf_versions` list in `vars/main.yml`, currently just `["v5.5.4"]`. Which version a given *project* uses is resolved at the project level, not here — EIM has no concept of a project pin — see `RaBbLE-Pocket/ops/esp-idf-select.sh`.

Third reference implementation of the `layer/*` optional-feature-group pattern (see `RaBbLE-OS-Layer-Bottles.md` and `RaBbLE-OS-Layer-Containers.md`). Neither `apply all` nor `upgrade` installs this layer — only an explicit `apply esp-idf`.

**Live-verified 2026-08-08:** `eim install --path ~/esp/esp-idf-eim --version-name <v>` puts the actual ESP-IDF checkout one level deeper than that path — `~/esp/esp-idf-eim/<v>/esp-idf/`, not `~/esp/esp-idf-eim/<v>/` directly. More importantly, eim does **not** use the plain upstream `esp-idf/export.sh` layout for its Python venv — it manages its own venv/toolchain paths and writes a dedicated activation script per version at `~/.espressif/tools/activate_idf_<v>.sh` (source of truth: `eim list` and `~/.espressif/tools/eim_idf.json`). Sourcing the plain `export.sh` fails with `ESP-IDF Python virtual environment ... not found` — it's looking in the wrong place. `esp-idf-select.sh` was written assuming the plain-`export.sh` layout and needed a fix; it's now correct. If you're activating by hand, use eim's own script, not `export.sh` (see "Manual flow" below).

---

## What the layer installs

| Step | What | Why |
|---|---|---|
| dnf prerequisites | `git wget flex bison gperf python3-pip cmake ninja-build ccache dfu-util libusbx openssl-devel libffi-devel` | `eim install` still needs these present on Linux |
| broader tools | `picocom` (serial terminal), `usbutils` (`lsusb`), `fzf` (nicer picker in `esp-idf-select.sh`, falls back to plain `select` without it) | Generally useful for USB/serial embedded work, not IDF-specific |
| `dialout` group | `rabble_user` appended | The board enumerates as `/dev/ttyACM*`; `idf.py flash` (esptool.py) needs this to open the port without `sudo` — same rationale as `layer/bottles`' USB/serial task. **Requires a new login session to take effect.** |
| EIM CLI | `eim-cli-linux-x64.rpm`, latest GitHub release, `disable_gpg_check: true` (unsigned third-party rpm) | The tool this role actually drives — see below for why CLI over GUI |
| ESP-IDF version(s) | `eim install --path ~/esp/esp-idf-eim --version-name <v> --idf-versions <v> --target esp32s3 --non-interactive true --do-not-track true`, once per `esp_idf_versions` entry, skipped if `eim list` already shows that version | Idempotent-by-registry-check provisioning |
| `~/esp/esp-idf-default` symlink | → `esp_idf_eim_path/<esp_idf_versions[0]>` | Fallback for anything assuming one fixed path — `esp-idf-select.sh` doesn't rely on it directly (pin file first, interactive picker second) |

**Why CLI, not GUI:** `espressif/idf-im-ui` ships `eim-cli` and `eim-gui` as separate release packages that both install to `/usr/bin/eim`. Checked with `rpm -qp --dump` — genuinely different binaries (32MB vs 51MB, different SHA256), so dnf refuses to have both installed at once; only one can ever be present. Started with GUI (that's what was asked for first), switched to CLI once it became clear `eim --help` shows full command parity (`install`/`list`/`select`/`run`/`remove`/`rename`/`wizard`/...) plus `--non-interactive` scriptability the GUI doesn't offer — and CLI is what this role's tasks actually need to call. Swap the release asset back to `eim-gui-linux-x64.rpm` if the GUI ever becomes preferred again (loses the automated provisioning path — would need reverting to the git-clone+install.sh mechanism, still in git history).

`esp_idf_versions`, `esp_idf_target`, `esp_idf_eim_path`, `esp_idf_prereq_packages`, `esp_idf_extra_packages` all live in `ansible/roles/layer/esp-idf/vars/main.yml`.

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

`pocket-idf list` shows installed versions + the current pin (plus `eim list`'s raw output for cross-reference — not parsed, just shown); `pocket-idf v6.0.2` activates an explicit version; `pocket-idf pin v6.0.2` writes a pin without activating. Full detail: `RaBbLE-Pocket/ops/CONTEXT.md`.

**One-shot, non-interactive:**

```bash
ops/build-flash.sh firmware/<project>   # config + build + flash, one command
```

**EIM directly** — Espressif's own commands, machine-wide, no project-pin awareness:

```bash
eim list                                    # what's installed, per EIM's registry
eim run "idf.py --version" v5.5.4           # run a command in a specific version's context, no global switch needed
eim wizard                                  # interactive terminal wizard for install/manage
```

**Manual flow — no project or EIM context, one version:**

```bash
. ~/.espressif/tools/activate_idf_v5.5.4.sh   # eim's own script, not esp-idf/export.sh (see note above)
idf.py --version
```

For VSCode IntelliSense without any Espressif extension: `idf.py build` generates `build/compile_commands.json` — point `C_Cpp.default.compileCommands` at it.

---

## Verify

```bash
bash RaBbLE-OS-layerctl.sh verify esp-idf   # `eim` on PATH + `eim list` succeeds + ~/esp/esp-idf-default symlink
. ~/.espressif/tools/activate_idf_v5.5.4.sh && idf.py --version
```

If `dialout` group membership doesn't seem to be working (permission denied opening `/dev/ttyACM0`), log out and back in — same gotcha as `layer/bottles`' USB/serial group.

→ `RaBbLE-OS-Layer-Bottles.md` — the `layer/*` pattern this follows
→ `RaBbLE-OS-Layer-Containers.md` — second reference implementation
→ `RaBbLE-OS-Layer-Arduino-CLI.md` — fourth reference implementation, sibling layer for the vendor's Arduino examples
→ `../../RaBbLE-OS/ansible/packages/manifest.yml` — package declarations (`layer.esp-idf` category)
→ `../RaBbLE-Pocket/RaBbLE-Pocket-Architecture.md` — full toolchain rationale + Arduino porting notes
→ `../RaBbLE-Pocket/RaBbLE-Pocket-Firmware-BuildFlash.md` — verified worked example + gotchas
