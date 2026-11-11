# RaBbLE-Pocket-Gadget-Port.md

> **Historical record (W7, 2026-10-25).** This page describes the S243 port, when the hardware layer was derived from the Apache-2.0 parts of Meta's gadget SDK. That code has since been replaced module by module through the clean room ([Clean-Room-Plan](RaBbLE-Pocket-Clean-Room-Plan.md), [PROVENANCE](cleanroom/PROVENANCE.md)). The firmware is RaBbLE's own, under the Sovereign Accord only: `apache/` and every `LICENSE-APACHE` are gone, `firmware/NOTICE` lists no derived code, and the reference SDK copy is deleted. The Layout table and the rules below are as of S243; the behaviour sections still describe the gadget.

RaBbLE-Pocket's firmware rebuilt as a **RaBbLE gadget** (S243, 2026-10-06): the board, audio, power, Wi-Fi, settings and push-to-talk voice loop ported from the Apache-2.0 parts of Meta's gadget SDK (studied in [RaBbLE-Pocket-Muse-SDK-Map](RaBbLE-Pocket-Muse-SDK-Map.md)), with its cloud backend replaced by **the beam** to sCoRE ([RaBbLE-Pocket-Beam-Protocol](RaBbLE-Pocket-Beam-Protocol.md)) and its avatar replaced by RaBbLE's own LVGL face. Supersedes the v1 screens of [RaBbLE-Pocket-V1-Firmware-Plan](RaBbLE-Pocket-V1-Firmware-Plan.md) (their geometry and two-tier sleep carried over).

## Rules Mark set for the port

- **Permissive third-party code only** (Apache, BSD, MIT, CC0; never copyleft), kept **isolated** so the Sovereign Accord's scope stays clean. RaBbLE's own code and its changes to ported code are under the Accord.
- **No upstream product names in code.** Nothing named muse, hatch, link, jollybot. Upstream authorship stays as low-key as the license allows: each derived file has a 4-line header, RaBbLE's copyright first, then Meta's copyright line verbatim (Apache §4(c) requires it), then `SPDX-License-Identifier: Apache-2.0` pointing at a `LICENSE-APACHE` shipped beside it. Provenance (upstream repo, commit `b139b45`) lives here in the Grimoire, not in the code.
- **His own LVGL face**, not the SDK's 64 px Jollybot avatar (which isn't Apache-licensed anyway).

## Layout (`RaBbLE-Pocket/firmware/`)

| Path | License | What |
|---|---|---|
| `components/rabble_gadget/apache/` | Apache-2.0 + Accord changes (`LICENSE-APACHE`) | board seam (`rabble_board.h`), audio, battery meter, console, input (buttons, auto-sleep, Tier 2), keypad, LVGL PSRAM allocator, settings (NVS), settings UI, setup commands, state, text, voice loop, Wi-Fi (`rabble_wifi*`), beam seam + caption paging (`rabble_beam*.c/h`), app orchestrator |
| `components/rabble_gadget/accord/` | Accord only | face UI (`rabble_ui.c`: canvas-rendered entity), sCoRE session (`rabble_beam_score.c`), palette (`rabble_palette.h`), clock screen, entity geometry, LVGL assert hook |
| `components/rabble_axp2101/` | Apache-2.0 + Accord | AXP2101: SDK key latch, rails, voltage + Mark's 128 ms PEKEY power-on and battery detect |
| `components/rabble_pcf85063/` | Accord | RTC (unchanged) |
| `bsp/` | Apache-2.0 + Accord | `bsp_waveshare_175b.c` (the only file that knows the board's wiring), `rabble_lcd_bands.c` (QSPI band flusher) |
| `main/app_main.c` | Accord | starts the gadget on the UI core |
| `ops/beam-echo.py` (repo root `ops/`) | Accord | dev stand-in for sCoRE's beam endpoint |

Dropped from the SDK: Home Link (pairing, Noise sessions, tunnel, OTA), the Muse cloud client, BLE phone setup, the button menu for non-touch boards, other boards, MP3 decode. Retired from v1: `rabble_hal.h`, `screen_idle/boot`, `power_task.c`.

Toolchain: **ESP-IDF v6.0.1** (`firmware/.esp-idf-version`; ADR `planning/decisions/2026-10-06-idf-v6-gadget-stack.md`), LVGL 9.5.0, esp_lvgl_adapter 0.6.4, esp_codec_dev 1.5, esp_websocket_client 1.8, cJSON 1.7, Waveshare BSP 3.x. Every managed component is permissive (Apache-2.0, MIT, zlib, libpng, FreeType under its FTL option, Espressif MIT).

## How it behaves

- **Buttons:** BOOT (lower) = hold to talk. PWR (upper, read from the PMU's key latch) = click to sleep the screen, hold 1.5 s to power off; either button wakes. The PMU's own 10 s hold is the hardware cut.
- **Tier 2 kept:** asleep on battery for `power_off` seconds (default 45, Settings > Sleep or `>power_off=N`, 0 = never), the AXP2101 cuts power; one PWR click cold-boots (128 ms PEKEY).
- **Sleep:** screen auto-sleeps after `sleep` s idle (default 120). Dark on battery, LVGL and touch pause, the CPU light-sleeps, codecs power down, Wi-Fi dozes; after 2 min it leaves Wi-Fi entirely (nap) until woken.
- **Voice turn:** press, and speech (with 320 ms pre-roll) streams to sCoRE; release, and the reply streams back and plays as it arrives, captions paging with it. Out of reach, the note is kept in PSRAM and sent later.
- **Face:** eyes and portals drawn into one 260x200 canvas by an anti-aliased ellipse rasterizer. Idle breathes and blinks; listening widens and the portals glow with the mic; thinking drifts with alternating portal pulses; speaking pulses with the reply; error squints; a pet (tap) or a finished turn hops. Boot: portals fade in (cyan, then magenta), then the eyes open through them and the rest fades in, timed from the first lit frame.
- **Screens:** face tile (status row: Wi-Fi, sCoRE, battery; clock, long-press to set the RTC; captions; button hints; wordmark), settings one swipe left (Wi-Fi, sCoRE, Sound, Sleep, Battery meter, Power).
- **Console** (USB serial; opening the port resets the board): `d`/`u` talk down/up, `c` chirp, `z`/`w` sleep/wake, `>status`, `>power`, `>nap`, `>face=thinking`, `>chat=hello` (typed turn over the beam), and setup lines: `>wifi.ssid=` `>wifi.pass=` `>wifi.connect`, `>wifi.forget[=ssid]`, `>beam.url=`, `>beam.token=`, `>beam.test`, `>volume=` `>speaker=` `>mic_gain=` `>brightness=` `>sleep=` `>power_off=`, `>test.loopback`.

## Verified (2026-10-06, on the -B)

- Builds clean on IDF v6.0.1: zero warnings, 1.76 MB app (79% of the 8 MB slot free).
- Flashed; boots to the face. PMU, rails, RTC, panel, touch, ES8311 + ES7210 all come up; audio self-test on both mics at the expected levels (-46 dBFS room, L/R corr 0.99), capture/playback clocks within 1% of 16 kHz; Wi-Fi station starts; 216 KB internal + 5.7 MB PSRAM free at ready.
- `beam-echo.py` round-trips a voice turn and a typed turn with a scripted client (loopback).
- **End to end on the device (Mark):** Wi-Fi joined from the settings keypad and rejoins by itself after reset (~2.5 s from scan to IP); the beam connects to `rabble-os.local:8000` by mDNS name; four push-to-talk turns (2.2 to 4.5 s) went up, came back through `beam-echo.py` and played on the speaker with captions. Firewall needed `8000/tcp` opened on rabble-os.

## Added later in S243

- **Motion (QMI8658 accelerometer, own driver `components/rabble_qmi8658`):** the entity counter-rotates on a slightly underdamped spring to stay upright (eases home when flat); a shake (4 spikes past 1 g in 1 s) makes it dizzy (eyes orbit, portals flicker, wobble), chirps when idle and wakes it when asleep; **raise to wake** (screen tipped up towards the face by 0.35 of "up" in 1.5 s, then held still), on by default, Settings > Sleep or `>raise_wake=`. Axes: screen x = chip Y, screen up = chip X, screen out = -chip Z (vendor gravity demo; z verified with `>imu`). IMU INT2 is GPIO21: a future light-sleep wake without polling.
- **Clock:** Settings > Clock opens the date/time screen (as does a long-press on the face's time).
- **Voice:** Settings > Sound > Voice cycles sCoRE's Daniel / Austin / Troy (`>voice=`), sent per turn.
- **sCoRE beam live** (`RaBbLE-sCoRE/server/beam.py`), replacing beam-echo for real conversation, and **deployed on Render**: firmware default `wss://rabble-score-x7qq.onrender.com/api/v1/beam`, device token set over the console (`>beam.token=`; the value lives in Render and `RaBbLE-sCoRE/server/.env`). The Pocket works away from the laptop on any known Wi-Fi. Render's free plan sleeps after ~15 min idle; the `rabble-score` Cloudflare Worker's 10-minute cron (`RaBbLE-sCoRE/cf-proxy.js`) keeps it warm, so a press shouldn't wait out a cold start.
- **TLS gotcha:** Render (Google Trust Services) sends GTS Root R4 cross-signed by the retired GlobalSign Root CA, which ESP-IDF's bundle dropped: handshake failed (mbedTLS -0x3000) until `CONFIG_MBEDTLS_CERTIFICATE_BUNDLE_CROSS_SIGNED_VERIFY=y`.

## Open

- **Upright direction and raise-to-wake feel:** unverified on the device (x/y mapping from the vendor demo).
- **Console stall:** a host that opens /dev/ttyACM0 but stops reading blocks the firmware's log writes. Bench tools must keep reading.
- **Possible reboot mid-turn:** seen twice now (turn ids reset 1, 2, 1, 2 in the sCoRE log during real conversation). Next: enable core dumps to flash to catch it.
- **Old note:** in the echo log, turn 2 began and never ended, and 26 s later the device reconnected with its turn counter back at 1. Either Mark held PWR, or something restarted the board during a turn. Unconfirmed: capture the device log (`>`-less read of /dev/ttyACM0 resets the board, so log over a long session) during a long turn to see a panic.

## Not verified yet

1. Face look, boot animation, swipe smoothness after the canvas rewrite (the first build used LVGL transforms and lagged on the swipe to settings).
2. Auto-sleep, Tier 2 power-off on battery, PWR cold boot.
3. Port 8000 is open on rabble-os for the session only; make it permanent through RaBbLE-OS's firewall role if the LAN beam stays.

## Next

1. **Catch the mid-turn reboot** (core dump to flash, then read it after it happens).
2. **Rebuild text and keyboard input** on the Pocket (Mark: the current keypad entry isn't usable enough).
3. A voice that is RaBbLE's own (Mark dislikes the stock ones): DSP in sCoRE to make it less human, or a self-hosted model (Kokoro, Apache-2.0).
4. The checks under "Not verified yet".
3. SNTP to set the RTC when Wi-Fi is up (needs a timezone setting).
4. BLE provisioning for Wi-Fi + beam settings (feeds `rabble_setup_command`).
5. Wake word (ESP-SR) and a `wake` turn mode; the puppet schema driving the face from sCoRE.
6. 1.75C board file when it arrives (PWR on GPIO3, no SD/RTC).
