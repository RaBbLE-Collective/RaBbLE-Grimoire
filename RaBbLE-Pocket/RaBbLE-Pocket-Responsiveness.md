# RaBbLE-Pocket-Responsiveness.md

> Open paths to a Pocket that feels snappy and alive: boot, wake, frame pacing, time-to-talk. Started S268 (2026-10-22) from one instrumented boot of Pocket `ac2e9f9`.
> Mark (S268): "I want the device to feel snappy and alive." This file logs every path we know of, measured where we can, so they can be picked off in order. W6 (`cleanroom/w6-board.spec.md`) already carries the panel-side ones as requirements.
> Status: **nothing here is applied yet** except where a row says so.

## Why boot matters most

The Pocket powers off after 45 s asleep on battery (`CONFIG_RABBLE_POWER_OFF_S`, Orbit "Off when asleep"), so **most wakes from the pocket are full boots**. A wake from plain sleep draws in about 0.13 s; a full boot lights the panel at 2.8 s. Boot time *is* wake time.

## Where a boot goes today (S268, reset boot, `ac2e9f9`)

| t (ms) | Point | Cost |
|---|---|---|
| 24 → 441 | bootloader, image check and load | 417 (hashing the two mapped segments: rodata 94 ms, code 202 ms) |
| 441 → 966 | app start: PSRAM, copy rodata + code into PSRAM (~130 ms), **PSRAM memtest (218 ms)**, heap | 525 |
| 991 → 1020 | board init: I2C, PMU, RTC, IMU | 29 |
| 1045 → 1208 | panel reset | 163 |
| 1208 → 2411 | **panel init sequence** (two 600 ms vendor waits) | 1,203 |
| 2416 → 2527 | band engine, touch, LVGL start | 111 |
| 2527 → 2809 | first three UI frames, then brightness up | 282 |
| ~4060 | codecs up, audio ready (4135) | |
| 4247 | Wi-Fi init starts | |
| (+1.8 s) | beam connected | |

About **6.6 KB of log text** is printed before the panel lights (1.9 KB of it by the bootloader, 4.3 KB before `app_main`).

## The console finding (answers "is the baud rate important?")

The console's **primary** output is UART0 (GPIO 43/44) at 115200 baud; the USB Serial/JTAG port that Mark and the tools actually read (`303a:1001`, `/dev/ttyACM0`) is only the **secondary** (`CONFIG_ESP_CONSOLE_SECONDARY_USB_SERIAL_JTAG=y`). Nothing is plugged into UART0, but every log byte still goes out on it, and at 115200 a byte takes 87 us: the CPU busy-waits once the 128-byte FIFO is full.

So it is **not a few ms**: 6.6 KB before lit is about **0.57 s of UART wire time**, and the bootloader and early-start part (~4.3 KB, ~0.37 s) sits directly on the boot path. At runtime every log line on the UI or panel task stalls it (an 80-character line is ~7 ms once the FIFO is full; the 10 s perf line was the ~25 ms hitch).

Best fix is not a faster UART but **no UART**: make USB Serial/JTAG the primary console (`CONFIG_ESP_CONSOLE_USB_SERIAL_JTAG=y`, secondary none). Then logs cost almost nothing on battery and are fast on USB. Second best: 921600 baud (8x less wait; tooling must follow). Either way, **fewer boot logs** helps (bootloader at WARN, chatty tags at WARN until the UI is up). Open question to test: how the USB Serial/JTAG console behaves when a host is connected but not reading (a TX timeout could stall logging); measure before committing.

## Open paths, ranked by expected win

| # | Path | Where | Expected win | Cost / trade-off | Status |
|---|---|---|---|---|---|
| 1 | Panel init waits to the datasheet (5 ms after Sleep Out, booster up at 120 ms) | W6 spec 7.1, 8.4 | **~1.05 s** every boot | none known; keep the panel dark until the UI lights it | in W6 spec |
| 2 | Console: USB Serial/JTAG primary, UART0 off (or 921600) | `sdkconfig.defaults` | **~0.3 to 0.5 s** boot, and no log hitches at runtime | tooling and ROM/bootloader output checks; test the host-not-reading case | needs one measurement build |
| 3 | Bootloader `SKIP_VALIDATE_ON_POWER_ON` | `sdkconfig.defaults` | **~0.3 s** on cold power-on (the hash pass over 1.9 MB) | no image check on power-on (a corrupt image is caught only on reset boots); OTA images are still checked when written | Mark's call |
| 4 | PSRAM memtest off | `sdkconfig.defaults` | **0.22 s** (measured) | no PSRAM self-check at boot | Mark agreed in principle |
| 5 | Fewer boot logs: bootloader at WARN, the partition table and segment lines gone, app tags quiet until UI is up | `sdkconfig.defaults`, log levels | tens of ms on their own; most of #2's win if #2 is not done | less boot diagnostics (raise levels for debugging) | |
| 6 | First frames to lit: 282 ms for three reveal frames (the first direct frame's `begin` took 19.5 ms) | `accord/rabble_ui.c`, entity, notes/time setup | **~0.2 s** | find what runs between LVGL start and the first frame (notes scan, time zone, entity build); defer non-visual work until after lit | investigate |
| 7 | Smaller image: 1.33 MB code + 575 KB rodata are hashed by the bootloader and copied to PSRAM at start | build, assets, fonts | ~0.1 s per MB saved (both passes) | find the big rodata (fonts, tables); `-Os` checks against the fps gates | investigate |
| 8 | Boot animation 0.9 s → ~0.5 s | `accord/` entity | 0.4 s to "awake" feel | design: Mark | carried from S266, ask Mark |
| 9 | Power-off policy: 45 s asleep → full boot | `CONFIG_RABBLE_POWER_OFF_S`, Orbit | turns most 2.8 s wakes into 0.13 s wakes | battery: measure sleep current first, then pick the timeout (or a longer default with "Off when asleep" as the battery saver) | needs a current measurement |
| 10 | Time-to-talk after boot: audio ready at 4.1 s, Wi-Fi starts at 4.2 s, beam +1.8 s | `accord/rabble_app.c`, wifi, beam | ~1 to 2 s to "can talk" | start Wi-Fi in parallel with the display on the other core; fast reconnect (saved channel and BSSID); start the beam handshake as soon as IP is up; let PTT record before beam is up (it already keeps turns for later) | investigate |
| 11 | Panel wake: `panel_sleep(false)` waits 120 ms before returning | W6 spec 5.4 | up to ~0.1 s per sleep wake | datasheet needs 5 ms before the next command; the 120 ms is booster-up, which can overlap drawing at brightness 0 | candidate W6 tweak (check with Mark) |
| 12 | Steady 30 fps when 60 can't hold | W6 spec 8.2 | smoother busy turns (no 60/30 judder) | | in W6 spec |
| 13 | Perf logs opt-in (`>perf`) | W6 spec 8.1 | removes the 10 s log hitch | | in W6 spec |
| 14 | No 40 ms TE wait when TE is missing | W6 spec 8.5 | robustness, not speed | | in W6 spec |

Rough total for a full boot to panel lit: 2.8 s today → **about 1.0 to 1.2 s** with 1 to 6, before the power-off policy (9) makes most wakes 0.13 s.

## How to measure

One instrumented flash, read one boot, revert (the S268 method): temporary `ESP_LOGW("BOOTTIME", ...)` stamps with `esp_log_timestamp()` after each step of `display_start()` and at the UI's brightness-up (`s_lit_at` in `rabble_ui.c`). Take both a reset boot (opening the serial port resets the gadget) and a cold boot (PWR on after power-off), since the bootloader's validate step differs. Log at WARN so the stamps survive quieter levels.
