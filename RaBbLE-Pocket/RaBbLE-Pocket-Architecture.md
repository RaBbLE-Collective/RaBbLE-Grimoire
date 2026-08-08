# RaBbLE-Pocket-Architecture.md

Firmware and comms architecture for the pendant. Hardware inventory: `RaBbLE-Pocket-Hardware.md`. Source: Mark's project rundown, 2026-08-07.

## Firmware Architecture

**Pattern:** BSP (Board Support Package) abstraction, modeled on Espressif's own `esp-bsp` framework.

- **HAL/BSP layer** — one file per board (`bsp_waveshare_175b.c`, `bsp_waveshare_175c.c`, etc.) implementing a shared interface (`rabble_hal.h`)
- **Shared driver layer** — wake-word engine, BLE GATT services, WiFi provisioning/handoff, LVGL rendering — hardware-agnostic, calls only the HAL
- **Application layer** — state machine (idle/listening/thinking/speaking), pixel-art UI logic
- Board selection via Kconfig/CMake target flag at build time
- Waveshare boards aren't in Espressif's official BSP list — custom BSPs required, following the same pattern

**Wake word:** Leaning on Mark's prior hands-on experience with NXP VIT and VoiceSeeker (used as WWE on i.MX 8ULP). ESP32-S3 path will likely use Espressif's ESP-SR toolkit; VIT knowledge carries forward more directly if/when the project moves to NXP RT700 silicon.

### Toolchain: ESP-IDF, not Arduino (decided S207-ish)

**Decision: ESP-IDF.** Formal ADR: `RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-over-arduino.md`. Reasons:

- **Arduino's single-loop model is a real pain point for this project's actual concurrency needs** — wake word, BLE GATT, WiFi provisioning, LVGL rendering, and audio I/O all need to run as independent, properly scheduled tasks, not cooperative slices of one `loop()`. Arduino-ESP32 is itself built on ESP-IDF/FreeRTOS but hides that under the single-loop illusion; ESP-IDF exposes the FreeRTOS task/queue/semaphore primitives directly.
- **Fits the "no IDE" constraint exactly.** ESP-IDF's `install.sh` sets up a self-contained Python venv + toolchain; `. export.sh` activates it in any shell; `idf.py build/flash/monitor` drives everything from a plain terminal. No GUI application required — VSCode is just an editor here (the Espressif VSCode extension is optional QoL, not needed). Arduino's CLI path (`arduino-cli`) exists too, but the ecosystem centers on the GUI Arduino IDE and its getting-started docs assume it.
- **Matches the BSP/HAL architecture above.** The `rabble_hal.h` + per-board BSP pattern needs low-level control over peripherals (QSPI AMOLED, I2C bus arbitration, IMU/RTC/PMIC drivers). Arduino-ESP32's abstraction layer works against that — it's built on top of ESP-IDF and hides the register/driver-level access custom BSPs need.
- **ESP-SR (wake word) is ESP-IDF native** — no equivalent maturity on Arduino.
- **Matches the vendor repo's own primary path.** Waveshare's Brookesia reference firmware (the fullest-featured example — 13 apps, ES7210 mic capture, ES8311 playback, QMI8658, AXP2101) is validated against **ESP-IDF v5.5.4** specifically (v6.0.2 also supported for the plain examples). `firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/docs/getting-started.md` has the exact `idf.py -C examples/esp-idf/<name> -B build/<name> set-target esp32s3 build` invocation — pin to v5.5.4 to match Brookesia and avoid version-skew surprises when reading their example code.

**Install + version management, RaBbLE-OS-side:** `bash RaBbLE-OS-layerctl.sh apply esp-idf` — opt-in `layer/esp-idf`, installs prerequisites, Espressif's own **EIM CLI**, then provisions one or more ESP-IDF versions side by side via `eim install` (`~/esp/esp-idf-eim/<version>`, no collision — EIM's own registry + toolchain/venv caches are keyed by version), plus `picocom`/`usbutils`/`fzf`. EIM CLI over GUI: confirmed via `eim --help` on the extracted binary that it has full command parity (`install`/`list`/`select`/`run`/`wizard`/...) plus the `--non-interactive` scriptability the GUI lacks — and CLI is what the role actually drives now, not just a standalone extra (`eim-cli`/`eim-gui` can't both be installed — same binary path, confirmed different files by hash). Full layer doc: `RaBbLE-Grimoire/RaBbLE-OS/layers/RaBbLE-OS-Layer-ESP-IDF.md`.

**Which version a project actually uses is a project-level decision**, not a machine one — EIM has no concept of that. `firmware/.esp-idf-version` pins it (currently `v5.5.4`), and `ops/esp-idf-select.sh` (sourced, defines a `pocket-idf` shell function) resolves the pin or prompts interactively and activates it. ADRs: `RaBbLE-Pocket/planning/decisions/2026-08-07-esp-idf-multiversion-and-eim.md`, `RaBbLE-Pocket/planning/decisions/2026-08-08-eim-cli-provisioning.md`.

Practical day-to-day, Linux + VSCode, no IDE:
```sh
cd ~/RaBbLE-Collective/RaBbLE-Pocket
source ops/esp-idf-select.sh       # once per shell (or add to shell rc)
pocket-idf                         # activates whatever firmware/.esp-idf-version pins
idf.py -C firmware/<project> -B build/<project> set-target esp32s3 build
idf.py -C firmware/<project> -B build/<project> -p /dev/ttyACM0 flash monitor
```

Worked example (hello_world smoke test + vendor LVGL demo) with gotchas hit during verification: `RaBbLE-Pocket-Firmware-BuildFlash.md`.

### Application State Machine (v1)

`APP_STATE_BOOT → APP_STATE_IDLE ⇄ APP_STATE_SETTINGS`, driven by a simple pair of mutually-referencing callbacks in `app_main.c` (no formal state-machine struct yet — two screens don't need one). `LISTENING/THINKING/SPEAKING` are named as placeholders for the future wake-word epoch; no screens exist for them yet. Boot fades into idle via `lv_screen_load_anim(..., LV_SCREEN_LOAD_ANIM_FADE_IN, 250, 0, true)`; idle↔settings is a hard `lv_scr_load()` cut, triggered by an 800ms long-press on the idle screen's time label.

Full build history (boot-timing measurements, the GIF→native-LVGL boot animation pivot, eye/portal geometry tuning, the white-flash/backlight-timing fixes) lives in `RaBbLE-Pocket-V1-Firmware-Plan.md`, not duplicated here.

### Power Management

Two-tier sleep, verified end-to-end on real hardware 2026-08-08 (see the plan doc's "Slice 5-6 hardware verification" section for the live serial-log evidence). Owned entirely by `rabble_power_task` — one FreeRTOS task, independent of app/screen state, started once from `app_main()` after display bring-up.

- **Tier 0 (awake)** — the task polls the PWR button over I2C (TCA9554 `SYS_OUT`, ~100ms) for a press edge. No expander interrupt line reaches an ESP32 GPIO on this board (confirmed from vendor `ButtonTest.cpp`), so every transition here is I2C-polled, never ISR-driven.
- **Tier 0 → Tier 1 (click)** — panel `DISPOFF` (`esp_lcd_panel_disp_on_off(panel, false)`, real command now — not the earlier stub) + backlight off, then the ESP32 itself drops into `esp_light_sleep_start()`, waking every ~100ms to re-poll the button. Light sleep halts every task including LVGL's render/tick task, so the clock/battery `lv_timer`s pause automatically and resume on wake, no extra bookkeeping needed. RAM/PSRAM (and LVGL's full UI state) survive untouched.
- **Tier 1 → Tier 0 (click within 45s)** — instant resume: panel `DISPON` + backlight on, no reboot, no boot animation. This is the "seamless" wake path.
- **Tier 1 → Tier 2 (45s unclicked, `CONFIG_RABBLE_SLEEP_TIMEOUT_MS`)** — `rabble_hal_power_shutdown()` → AXP2101 software power-gate (`COMMON_CONFIG` reg `0x10` bit 0), cutting the main 3V3 rail. µA-range draw; PCF85063 RTC keeps time on its own backup supply, independent of the gated rail. This board's USB is the ESP32-S3's *native* USB-JTAG-serial peripheral, not an external bridge chip, so the rail cut drops the whole USB device from the host — confirmed live (`/dev/ttyACM0` disappearing at the 45s mark), expected behavior, not a bug.
- **Tier 2 → Tier 0 (click)** — not code `rabble_power_task` runs; it's the AXP2101 itself re-powering the rail on a qualifying PWR press (`XPOWERS_POWERON_128MS`, configured once in `rabble_hal_init()`), which cold-boots `app_main` fresh. Confirmed on real hardware: a single click reliably wakes it on the *first* Tier-2 attempt (~3s felt total to idle) — the open question of whether the 128ms press-on register setting itself survives the power-gate turned out to be moot, since `rabble_hal_init()` reasserts it on every cold boot regardless of what AXP2101 came back up with.
- **Residual-press guard** — the same physical click that cold-boots the board from Tier 2 may still be held down when `rabble_power_task` starts polling a couple seconds later. Left unguarded, that reads as a fresh Tier 0→1 click and immediately re-sleeps the device right after boot. Fixed by requiring one full button release before the task's main loop will treat any press as real (`wait_for_release()` at task start, and again after every detected edge).
- **Known non-fatal rough edge**: one `E (...) lcd_panel.io.i2c: panel_io_i2c_tx_buffer` transmit error observed right at a Tier 1 entry — likely the touch controller's IRQ-driven I2C poll (CST9217, wrapped via `esp_lcd_panel_io_i2c`) racing the light-sleep transition. Device recovered fine both times seen; not root-caused or fixed this pass.

`rabble_hal_display_sleep()`/`wake()` need the `esp_lcd_panel_handle_t` the vendor BSP creates internally but never exposes a getter for — `app_main.c`'s `rabble_display_start_dark()` (the white-flash fix, see plan doc) hands it to the HAL once via `rabble_hal_display_set_panel_handle()` right after `bsp_display_new()` returns.

## Comms Architecture

**Phone is the dispatch hub, not the device.**

- **BLE** — always-on link for control, short wake-word utterances (compressed via Opus/Speex, 8-16kbps), button/state events. Chosen because it's low-power and connects automatically without user setup.
- **WiFi** — spun up on demand for heavier payloads (explicit "record" sessions, longer audio). Provisioned via credentials passed over the existing BLE link rather than a persistent always-on hotspot.
- **Key constraint driving this split:** ESP32-S3 has no Bluetooth Classic and no BLE 5.2 isochronous channels, so standard continuous Bluetooth audio streaming (A2DP, LE Audio) isn't available — hence the two-tier BLE/WiFi approach instead of one continuous audio link.
- On-device processing target: local wake-word/VAD only; actual AI response generation intended to run primarily on the phone (Apple Intelligence / Gemini Nano where available) or via cloud through Mark's own RaBbLE-sCoRE orchestration server.

## Companion App (iOS)

- No Mac owned — building via cloud-based toolchain (Codemagic / EAS Build / GitHub Actions macOS runners), or considering a used M1 MacBook Air ($365-450 range) for local Xcode debugging of BLE/CoreBluetooth work
- Apple Developer Program ($99/year) required regardless of build method
- Ad hoc distribution (up to 100 registered devices via UDID) sufficient for personal/small-scale testing — no App Store submission needed yet
- Swift Playgrounds on iPad considered for prototyping only — not currently viable for production submission (SDK version lag vs. Apple's current requirements)

## Branding / Visual Identity (RaBbLE OS, cross-surface)

- Cyan/magenta twin-pill motif, established across desktop Plymouth boot sequence, SDDM login theme (functional, in daily use on Fedora/Sway system), and now the watch idle face design
- Wordmark: stylized "RaBbLE" with alternating case
- Idle watch face concept: time display + twin-pill indicator over a dark constellation/network background — AMOLED-friendly (mostly black), being considered as a live "listening state" indicator
- Open item: formalize shared design assets (SVGs/color tokens) so the same visual system ports cleanly into LVGL on-device rather than being redrawn per surface — should ultimately draw from `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md`, not a redefinition
