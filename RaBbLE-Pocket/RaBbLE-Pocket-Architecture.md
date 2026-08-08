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

**Decision: ESP-IDF.** Reasons:

- **Fits the "no IDE" constraint exactly.** ESP-IDF's `install.sh` sets up a self-contained Python venv + toolchain; `. export.sh` activates it in any shell; `idf.py build/flash/monitor` drives everything from a plain terminal. No GUI application required — VSCode is just an editor here (the Espressif VSCode extension is optional QoL, not needed). Arduino's CLI path (`arduino-cli`) exists too, but the ecosystem centers on the GUI Arduino IDE and its getting-started docs assume it.
- **Matches the BSP/HAL architecture above.** The `rabble_hal.h` + per-board BSP pattern needs low-level control over peripherals (QSPI AMOLED, I2C bus arbitration, IMU/RTC/PMIC drivers). Arduino-ESP32's abstraction layer works against that — it's built on top of ESP-IDF and hides the register/driver-level access custom BSPs need.
- **ESP-SR (wake word) is ESP-IDF native** — no equivalent maturity on Arduino.
- **Matches the vendor repo's own primary path.** Waveshare's Brookesia reference firmware (the fullest-featured example — 13 apps, ES7210 mic capture, ES8311 playback, QMI8658, AXP2101) is validated against **ESP-IDF v5.5.4** specifically (v6.0.2 also supported for the plain examples). `firmware/vendor/ESP32-S3-Touch-AMOLED-1.75/docs/getting-started.md` has the exact `idf.py -C examples/esp-idf/<name> -B build/<name> set-target esp32s3 build` invocation — pin to v5.5.4 to match Brookesia and avoid version-skew surprises when reading their example code.

Practical setup, Linux + VSCode, no IDE:
```sh
git clone -b v5.5.4 --recursive https://github.com/espressif/esp-idf.git ~/esp/esp-idf
cd ~/esp/esp-idf && ./install.sh esp32s3
. ~/esp/esp-idf/export.sh          # run this once per shell/session before idf.py
idf.py -C firmware/<project> -B build/<project> set-target esp32s3 build
idf.py -C firmware/<project> -B build/<project> -p /dev/ttyACM0 flash monitor
```

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
