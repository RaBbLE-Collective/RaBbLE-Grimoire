# RaBbLE Pocket — Project Rundown

*AI companion pendant/wearable device, phone-tethered, wake-word driven*

---

## Current Status

**Hardware is alive.** Waveshare ESP32-S3-Touch-AMOLED-1.75-B is booted, running on battery power, charging circuit confirmed working (21% and climbing after fixing a reversed-polarity battery connector).

---

## Hardware — v1 (in hand)

**Board:** Waveshare ESP32-S3-Touch-AMOLED-1.75-B ($33.99, protective case variant)
- ESP32-S3R8, Xtensa LX7 dual-core, 240MHz, 8MB PSRAM, 16MB flash
- 1.75" round AMOLED, 466×466, CO5300 driver, CST9217 capacitive touch (QSPI + I2C)
- Dual digital microphone array with ES7210 echo cancellation chip
- QMI8658 6-axis IMU, PCF85063 RTC, AXP2101 PMIC
- TF card slot, MX1.25 2-pin battery header, 8Ω 2W external speaker (included, wired)
- WiFi 4 (802.11 b/g/n) + Bluetooth 5 (LE) — **no Bluetooth Classic, no LE Audio (BLE 5.0, not 5.2 ISO channels)**
- 2.54mm 8-pin header (3× GPIO, UART, reserved I2C + 3× expanded IO)

**Battery:** EEMB 3.7V 320mAh LiPo, 402535 (25×35×4.3mm), JST/MX1.25 2-pin, built-in protection circuit (overcharge 4.28V / overdischarge 3.0V cutoff)
- Confirmed correct connector match to board header
- Had to correct reversed wire polarity inside connector housing (black/red swapped) — fixed by releasing and reseating pins

---

## Hardware — v1.5 / Aluminum Pendant (ordered, longer lead time)

**Board:** Waveshare ESP32-S3-Touch-AMOLED-1.75C — CNC aluminum "badge" case, integrated speaker, space for internal battery
- **Not identical hardware to the -B board:** 32MB flash (vs 16MB), **no RTC chip**, **no TF card slot**, GPIO exposed as solder pads instead of a pluggable header
- Ships with (or without, depending on SKU — watch for "-EN" suffix = no battery) an integrated 3.7V 400mAh battery (602525, fits inside case per Waveshare)
- Case depth 15.05mm vs -B's 12.10mm — more internal clearance
- Plan: get -B firmware working first, port to 1.75C once it arrives (same board family, different BSP needed due to peripheral differences)

---

## Hardware — Explored and Deferred

| Option | Verdict |
|---|---|
| Used/hacked smartwatch (Pebble, Bangle.js, PineTime, AsteroidOS devices) | Abandoned in favor of purpose-built ESP32 dev boards |
| Seeed XIAO ESP32S3 + round panel | Superseded by all-in-one Waveshare boards |
| RP2350 / Pico 2 W | No wake-word SDK equivalent to ESP-SR; bolt-on radio; deprioritized |
| Tuya T5-E1 | Faster chip (Cortex-M33 @480MHz, WiFi6/BLE5.4) but different toolchain (TuyaOpen/TuyaOS), cloud-centric ecosystem — bigger fork than a peer swap |
| NXP i.MX RT700 | Strong long-term fit (eIQ Neutron NPU, dual DSP, NXP VIT wake-word — Mark has prior hands-on VIT/VoiceSeeker experience from i.MX 8ULP work) but no integrated wireless, requires full custom PCB/display/wireless design. **Plan: get MIMXRT700-EVK, wire up AMOLED panel to validate voice pipeline before committing to custom silicon — treated as v2/v3.** |
| Garmin Venu 2 Plus (teardown/reuse) | Not hackable — proprietary firmware, Connect IQ sandbox only, no mic API exposed, no documented display pinout |
| USB Host radio module port | Technically possible on ESP32-S3 (native USB PHY) but requires a dedicated second USB port design + VBUS power delivery — deferred, treated as its own PCB revision later |
| Flipper Zero-style "anything tool" (sub-GHz, NFC, IR) | Feasible as add-on chips (CC1101, PN532) but real space/power tradeoffs against pendant form factor; deferred to later expansion module |

---

## Firmware Architecture

**Pattern:** BSP (Board Support Package) abstraction, modeled on Espressif's own `esp-bsp` framework
- **HAL/BSP layer** — one file per board (`bsp_waveshare_175b.c`, `bsp_waveshare_175c.c`, etc.) implementing a shared interface (`rabble_hal.h`)
- **Shared driver layer** — wake-word engine, BLE GATT services, WiFi provisioning/handoff, LVGL rendering — hardware-agnostic, calls only the HAL
- **Application layer** — state machine (idle/listening/thinking/speaking), pixel-art UI logic
- Board selection via Kconfig/CMake target flag at build time
- Waveshare boards aren't in Espressif's official BSP list — custom BSPs required, following the same pattern

**Wake word:** Leaning on Mark's prior hands-on experience with NXP VIT and VoiceSeeker (used as WWE on i.MX 8ULP). ESP32-S3 path will likely use Espressif's ESP-SR toolkit; VIT knowledge carries forward more directly if/when the project moves to NXP RT700 silicon.

---

## Comms Architecture

**Phone is the dispatch hub, not the device.**

- **BLE** — always-on link for control, short wake-word utterances (compressed via Opus/Speex, 8-16kbps), button/state events. Chosen because it's low-power and connects automatically without user setup.
- **WiFi** — spun up on demand for heavier payloads (explicit "record" sessions, longer audio). Provisioned via credentials passed over the existing BLE link rather than a persistent always-on hotspot.
- **Key constraint driving this split:** ESP32-S3 has no Bluetooth Classic and no BLE 5.2 isochronous channels, so standard continuous Bluetooth audio streaming (A2DP, LE Audio) isn't available — hence the two-tier BLE/WiFi approach instead of one continuous audio link.
- On-device processing target: local wake-word/VAD only; actual AI response generation intended to run primarily on the phone (Apple Intelligence / Gemini Nano where available) or via cloud through Mark's own RaBbLE-sCoRE orchestration server.

---

## Companion App (iOS)

- No Mac owned — building via cloud-based toolchain (Codemagic / EAS Build / GitHub Actions macOS runners), or considering a used M1 MacBook Air ($365-450 range) for local Xcode debugging of BLE/CoreBluetooth work
- Apple Developer Program ($99/year) required regardless of build method
- Ad hoc distribution (up to 100 registered devices via UDID) sufficient for personal/small-scale testing — no App Store submission needed yet
- Swift Playgrounds on iPad considered for prototyping only — not currently viable for production submission (SDK version lag vs. Apple's current requirements)

---

## Branding / Visual Identity (RaBbLE OS, cross-surface)

- Cyan/magenta twin-pill motif, established across desktop Plymouth boot sequence, SDDM login theme (functional, in daily use on Fedora/Sway system), and now the watch idle face design
- Wordmark: stylized "RaBbLE" with alternating case
- Idle watch face concept: time display + twin-pill indicator over a dark constellation/network background — AMOLED-friendly (mostly black), being considered as a live "listening state" indicator
- Open item: formalize shared design assets (SVGs/color tokens) so the same visual system ports cleanly into LVGL on-device rather than being redrawn per surface

---

## Open Questions / Next Steps

- [ ] Confirm which wake-word engine ships in v1 firmware (ESP-SR vs. porting VIT concepts)
- [ ] Decide BLE audio codec and chunking protocol for wake-word utterance transport
- [ ] Build out BSP for -B board; validate mic, display, IMU, touch via Waveshare demo firmware first
- [ ] Order/receive 1.75C aluminum board; port firmware once -B is stable
- [ ] Finalize idle-state animation (static vs. reactive pulse pre-wake-word)
- [ ] Address AMOLED burn-in mitigation for static idle elements (time digits, pill icons)
- [ ] Investigate RT700 EVK for future voice-pipeline validation (v2/v3 target)
- [ ] Custom case design decision — build around -B/bare 1.75 board (keeps RTC + TF slot + pluggable header) vs. 1.75C form factor
