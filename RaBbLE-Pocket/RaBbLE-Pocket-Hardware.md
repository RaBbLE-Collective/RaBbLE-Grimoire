# RaBbLE-Pocket-Hardware.md

AI companion pendant/wearable device, phone-tethered, wake-word driven. Source: Mark's project rundown, 2026-08-07.

## Current Status

Hardware is alive. Waveshare ESP32-S3-Touch-AMOLED-1.75-B is booted, running on battery power, charging circuit confirmed working (21% and climbing after fixing a reversed-polarity battery connector).

## v1 — In Hand

**Board:** Waveshare ESP32-S3-Touch-AMOLED-1.75-B ($33.99, protective case variant)
- ESP32-S3R8, Xtensa LX7 dual-core, 240MHz, 8MB PSRAM, 16MB flash
- 1.75" round AMOLED, 466×466, CO5300 driver, CST9217 capacitive touch (QSPI + I2C)
- Dual digital microphone array with ES7210 echo cancellation chip (mic capture) + ES8311 codec driving the speaker output via an NS4150B PA — confirmed from the schematic (`U8` = ES7210, `U6` = ES8311), two separate chips doing separate jobs, not a naming conflict
- QMI8658 6-axis IMU, PCF85063 RTC, AXP2101 PMIC
- TF card slot, MX1.25 2-pin battery header, 8Ω 2W external speaker (included, wired)
- WiFi 4 (802.11 b/g/n) + Bluetooth 5 (LE) — **no Bluetooth Classic, no LE Audio (BLE 5.0, not 5.2 ISO channels)**
- 2.54mm 8-pin header (3× GPIO, UART, reserved I2C + 3× expanded IO)

**Vendor resources:**
- [ESP32-S3-Touch-AMOLED-1.75 firmware repo](https://github.com/waveshareteam/ESP32-S3-Touch-AMOLED-1.75) — Apache-2.0 licensed (some bundled example deps carry their own permissive licenses)
- [Board docs](https://docs.waveshare.com/ESP32-S3-Touch-AMOLED-1.75)
- [Resources and Documents (schematics, datasheets, drivers)](https://docs.waveshare.com/ESP32-S3-Touch-AMOLED-1.75/Resources-And-Documents)
- Local copy (vendor firmware clone + all PDFs/schematics, gitignored): `RaBbLE-Pocket/firmware/vendor/` — see that dir's `README.md` for the resolved codec finding and full file list

**Battery:** EEMB 3.7V 320mAh LiPo, 402535 (25×35×4.3mm), JST/MX1.25 2-pin, built-in protection circuit (overcharge 4.28V / overdischarge 3.0V cutoff)
- Confirmed correct connector match to board header
- Had to correct reversed wire polarity inside connector housing (black/red swapped) — fixed by releasing and reseating pins

## v1.5 / Aluminum Pendant — Ordered, Longer Lead Time

**Board:** Waveshare ESP32-S3-Touch-AMOLED-1.75C — CNC aluminum "badge" case, integrated speaker, space for internal battery
- **Not identical hardware to the -B board:** 32MB flash (vs 16MB), **no RTC chip**, **no TF card slot**, GPIO exposed as solder pads instead of a pluggable header
- Ships with (or without, depending on SKU — watch for "-EN" suffix = no battery) an integrated 3.7V 400mAh battery (602525, fits inside case per Waveshare)
- Case depth 15.05mm vs -B's 12.10mm — more internal clearance
- Plan: get -B firmware working first, port to 1.75C once it arrives (same board family, different BSP needed due to peripheral differences)

## Explored and Deferred

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

## Custom Case Decision (Open)

Build around -B / bare 1.75 board (keeps RTC + TF slot + pluggable header) vs. 1.75C form factor. Not yet decided — tracked in Roadmap.
