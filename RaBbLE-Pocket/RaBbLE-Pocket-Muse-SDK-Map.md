# RaBbLE-Pocket-Muse-SDK-Map.md

Study notes from flashing Meta's open-source Muse Gadget SDK onto the Pocket v1 board (Waveshare ESP32-S3-Touch-AMOLED-1.75-B), 2026-10-06. Two goals: prove the hardware on drivers someone else already debugged, and map which parts of the SDK are worth porting into RaBbLE's own Pocket firmware. Both are met. Read-only study: nothing from the SDK has been copied into `RaBbLE-Pocket` yet.

Source plan: `RaBbLE-BaBbLE/intake/rabble-pocket-muse-bringup.md`. Board spec: [RaBbLE-Pocket-Hardware](RaBbLE-Pocket-Hardware.md). Our own firmware: [RaBbLE-Pocket-V1-Firmware-Plan](RaBbLE-Pocket-V1-Firmware-Plan.md).

## Verdict

**The Muse gadget is a smart-home bridge first, a companion second.** The SDK's own `esp32/AGENTS.md` calls it the firmware "powering Muse Home Link": it pairs with a phone, joins Wi-Fi, holds an encrypted Noise session to a Muse VM and optionally tunnels into the home network so Muse can reach local devices (the SDK's `skills/` folder is Lutron, Shelly, Sonos, Kasa). The avatar, push-to-talk and captions are a layer added on boards with a screen.

It is built for a **stationary, mains-powered box that stays on the home network**: most supported boards are desk or wall devices (SenseCAP Indicator, reTerminal e-paper panels, ESP32-S3-BOX-3, Home Assistant Voice PE), it holds a long-lived session and tunnel, and voice is **push-to-talk only**. There is no wake word anywhere in the firmware, even on the HA Voice PE, whose XMOS chip could do one. You walk up and press it. A wearable that listens for its name (the Pocket's whole premise) is outside what it was designed for.

As a companion experience it falls flat: **replies are text only** (no speech), **turns are slow**, and the face is a status indicator rather than a presence. Those three gaps are the spec for what RaBbLE has to do differently (see below).

As a **BSP and plumbing reference it is excellent**, and Apache-2.0. The board layer, audio pipeline, power chip driver, battery meter, settings UI and BLE pairing flow all ran correctly on our board first time. Mark's read after testing: pairing flow was smooth, the settings page is reasonable, the rest is not compelling.

## Bring-up record (2026-10-06)

| Item | Value |
|---|---|
| SDK | `facebookincubator/muse-gadget-sdk` at `b139b45` (2026-10-05), cloned to `RaBbLE-Pocket/firmware/muse-gadget-sdk/` (gitignored, independent repo) |
| Profile | `s3n` = `waveshare-s3-175` (`devices/sdkconfig.muse;devices/sdkconfig.muse-waveshare-s3-175`) |
| Toolchain | ESP-IDF **v6.0.1** exactly (SDK requirement), added to `RaBbLE-OS` `layer/esp-idf` vars beside v5.5.4, installed via `layerctl apply esp-idf` |
| Chip | ESP32-S3 (QFN56) rev v0.2, 8 MB embedded PSRAM, 16 MB flash, MAC `28:84:85:55:5E:B8`, native USB `303a:1001` |
| Backup | `RaBbLE-Pocket/firmware/backups/pocket-175b-20261006-1730.bin`, 16,777,216 bytes, sha256 `0550642c47e86e6a4aa811840b5b50ee8745b2dfd0fdae38fd83a03f375e9954`. Restore: `esptool --chip esp32s3 -p /dev/ttyACM0 write_flash 0 <file>` |
| App size | 0x211000 of a 0x400000 slot (48% free) |
| eFuses | untouched: no Secure Boot, no flash encryption, no `HOMEHUB_PAIRING_EFUSE_AUTH` (verified in the generated `sdkconfig`) |
| Token | none. Built and **paired with the Muse app without an SDK token**; the firmware simply omits `sdk_token` from `pairing_confirmed` (`main/link_pairing.c:686,1052`). The build warns Muse "will stop pairing" tokenless gadgets later, so treat this as temporary |

**Is the -B a 1.75?** Yes, for firmware purposes. Evidence: the SDK's 1.75 build pulls the same Waveshare BSP component (`waveshare/esp32_s3_touch_amoled_1_75`) our firmware already runs on the -B; 16 MB flash (1.75C has 32 MB); TF slot and RTC present (1.75C has neither); boot log prints `muse: board: Waveshare ESP32-S3-Touch-AMOLED-1.75`.

### Smoke test

| Check | Result |
|---|---|
| Boot, board ID, AXP2101, rails | ✅ `link.main: Muse Gadget starting`, no panic or boot loop |
| Display (round layout), touch, settings screen | ✅ Mark confirmed on device |
| MP3 decode + speaker | ✅ 3.67 s clip decoded in ~180 ms, audible |
| Mic capture (ES7210, both channels) | ✅ noise floor tracks gain; L/R matched |
| Speaker-to-mic loopback (`>test.loopback`) | ✅ once the speaker lead was actually connected. Strongest 2 to 4 kHz, weak below 400 Hz (expected for the small 8 Ω speaker). First run read tones below the noise floor: that was the unplugged speaker, not firmware |
| Battery on PMU | ✅ 55% on battery after reseat. Note: the earlier `@power` reading of `battery_pct [-1,-1]` means the PMU saw **no battery** at that moment |
| Wi-Fi, BLE pairing to Muse app | ✅ |
| Talk turn | ✅ transcribed and answered, **as on-screen text only** |
| Not yet checked | screen sleep/wake on battery, idle current, boot-to-face time |

"Won't boot on battery" scare: Muse maps a **1.5 s PWR hold to power-off** (`muse_input.c:63`) and sets the AXP2101 hardware hold-off to 10 s. Once off, the PMU only comes back on a PWR press or on USB VBUS, so plugging in USB always "fixes" it. Not a firmware fault.

### Buttons on the 1.75 profile

- **BOOT (lower) = talk.** Hold to record; Select while the menu is open; wakes the screen; confirms a pending phone pairing.
- **PWR (upper) = aux.** Short press sleeps the screen; double press toggles BLE phone setup; 1.5 s hold powers off; 10 s is the PMU's hardware cut.

## Why it feels the way it does

- **No speech.** The gadget's whole Muse surface is three endpoints in `muse_chat_session.cpp`: `/v1/noise` (session), `/chat/stream` (send), `/chat/subscribe` (receive). Replies arrive as text events only. `start_tts` (`muse_chat_session.cpp:1504`) deliberately plays **silence** sized to the text so captions pace correctly; its comment and `esp32/README.md:227-238` say to bring your own TTS. The Muse phone app's voice is internal to the app and not exposed to gadgets.
- **Slow.** Record whole note, upload, cloud STT, LLM on a VM, stream text back, then the turn only settles "once every message is done and nothing has arrived for a few seconds" (`muse_chat_session.cpp:31-32`). No wake word, no streaming reply, nothing masking the wait.
- **Thin presence.** The avatar is a 64×64 pixel renderer scaled up (`muse_pixel.h`), driven by a five-field pose (mode, time, time-in-mode, audio level, happy). It reacts to state; it doesn't feel like anyone is there.

## Map of the SDK

Firmware root: `esp32/`. Entry `main/main.c`, most Home Link logic in `main/app.c` (~2.8k lines). The companion layer is `components/muse/` (~12.6k lines).

### Board layer (port this first)

- `components/muse/muse_board.h`: the `muse_board_t` vtable. Descriptor fields (`name`, `width/height`, `round`, `touch`, `keyboard`, button names for captions, `frame_ms`, `avatar_px`) plus hooks: `init`, `display_start`, `display_lock/unlock`, `set_brightness`, `panel_sleep`, `display_pause`, `audio_init` (returns speaker + mic `esp_codec_dev` handles), `mic_slot`, `set_mic_gain`, `poll_buttons`, `wait_buttons`, `read_power`, `power_off`.
- `components/muse/boards/board_waveshare_s3_175c.c` (288 lines): drives **both** the 1.75 and 1.75C. 1.75 differences per its header: panel/touch resets on GPIO 39/40, MCLK on 42, GPIO 1 to 3 go to the SD slot, so PWR is read from the **AXP2101 key latch** over I2C every 20 ms instead of GPIO3.
- Compared with our `firmware/bsp/rabble_hal.h` + `bsp_waveshare_175b.c`: Muse's vtable is a richer, already-proven superset (audio, mic gain, panel sleep, display pause). Ours reads PWR via the TCA9554 expander (pin 4); Muse reads it from the PMU. Worth reconciling, since both work.

### Power and battery

- `muse_pmu.c/.h`: minimal AXP2101 driver. Status, charging, battery %, voltage, key-latch IRQs, `keep_rails()` (turns off unused DCDC/LDO rails; on this board only DCDC1 VCC3V3 and ALDO1 codec rail are used), soft power-off.
- `muse_battery.c/.h` (532 lines): a battery **meter for power work**. Pairs the 1% fuel gauge with screen-off time, real light-sleep time and (with `CONFIG_PM_PROFILING`) core-busy time and wake-lock holders. Starts on USB unplug, stops on replug. Directly useful for Pocket battery-life tuning. Console: `>power`, `>power.reset`.
- Our V1 firmware already has a verified three-tier power state machine; Muse's meter is the missing measurement half.

### Audio

- `muse_audio.c/.h`: codec bring-up on `esp_codec_dev`, mono read/write, dBFS and perceptual level helpers, UI chirps, MP3 self-test, and `muse_audio_loopback_test()` (speaker tones across mic gains, logged per band). Keep the loopback test as a factory/bench tool.
- `muse_voice.c/.h` (944 lines): push-to-talk turn loop. Hold streams speech, release thinks then speaks; **offline voice notes queue in PSRAM** and send when the link returns.
- `muse_adpcm.c/.h`: IMA ADPCM for pre-roll in low RAM.
- `components/minimp3/` (CC0) + the decode path in `muse_chat_session.cpp`: the MP3 playback path a TTS reply would use. Proven working on our speaker.

### UI

- `muse_ui.c` (1.7k lines): LVGL face screen, captions, mic and speaker buttons, round-panel layout.
- `muse_settings_ui.c` (1.3k lines): the touch settings tile Mark liked (volume, speaker, mic gain with live meter, brightness, auto-sleep, Wi-Fi). Swipe to reach it.
- `muse_menu.c`: button-only menu for boards without touch.
- `muse_settings.c/.h`: settings in NVS; setters save immediately and notify a listener that applies them to hardware. Clean pattern to copy.
- `muse_state.c/.h`: voice pipeline writes, UI reads (level, progress, caption under a spinlock). Simple and correct decoupling.

### Avatar seam

- `muse_pixel.h`: `muse_pixel_render(const muse_pose_t *)` into a 64×64 canvas, `muse_pixel_accent(mode)`, `muse_pixel_set_size()`, `muse_pixel_scale()`.
- CMake picks `components/muse/avatar/muse_pixel.c` if present, else the default in `esp32/avatar/` (`components/muse/CMakeLists.txt:55-63`).
- RaBbLE's renderer is already headed elsewhere (`esp_emote_gfx`/ThorVG ADR, [NeBuLA-Pocket-Puppet-Rendering-Pipeline](../log/plans/NeBuLA-Pocket-Puppet-Rendering-Pipeline.md)). Borrow the **pose contract** idea (mode, time, audio level, mood), not the 64 px renderer.

### Backend seam (what RaBbLE replaces)

- `components/muse/muse_chat.h`: the `muse_hatch_*` API. `start`, `status`, `ready`, `turn_begin` / `turn_audio(pcm, frames)` / `turn_end` / `turn_cancel`, `turn_caption`, `text_turn` (typed), plus resting and config-changed hooks.
- Implemented by `muse_chat_session.cpp` (2.3k lines, Noise over WebSocket to the Muse VM) and `muse_chat_link.c`.
- This interface is the cut line. A RaBbLE backend implements the same calls against sCoRE or a home box and keeps everything above it (voice loop, UI, captions) unchanged.
- **TTS hook:** `start_tts` (`muse_chat_session.cpp:1504`). Its comment lists the exact fields to set and says to feed MP3 to `tts_data()`; `decode()` then plays it at the speaker volume with captions following. Lowest-effort way to give any backend a voice.

### Home Link plumbing in `main/` (RaBbLE would replace or drop)

`ble_server.c` + `link_pairing.c` + `pairing_*` (community pairing v5, P-256, button-confirmed), `noise_control.cpp` (2.5k lines, control session, `link.register` command list), `noise_tunnel.cpp` + `tunnel_netif.c` (home-network tunnel), `vm_api.c`, `wifi_mgr.c` + `wifi_known.c`, `ota.c`, `net_discovery.c`, `muse_glue.c` (registers Link operations for the Muse layer, see `muse_link.h`).

The **pairing UX** is worth studying as a pattern even though the protocol is Muse-specific: BLE advertise with the device name on screen, phone picks it, physical button confirm, encrypted session carries Wi-Fi + credentials, name disappears once paired.

### Bench console (copy the idea)

Over native USB serial (`muse_input.c:636-700`): `d`/`u` talk down/up, `m` MP3 test, `a`/`s` menu, `p` screenshot (bench builds), `z`/`w` sleep/wake, and `>key=value` lines (`>status`, `>power`, `>face=thinking`, `>volume=70`, `>test.loopback`, `>chat=...`). Lets an agent drive and verify the device headlessly. RaBbLE-Pocket should have the same.

## What RaBbLE must do differently

1. **Speak.** Every reply audible. First step is a TTS fill of `start_tts`; local-first means a home-box TTS (Piper-class) returning MP3, cloud as a deliberate opt-in.
2. **Feel fast.** Stream audio up while talking, stream the reply back and start speaking on the first sentence, drop the multi-second settle, and cover the remaining wait with the entity (listening, thinking states that read as attention, not a spinner). Wake word per the Architecture doc.
3. **Feel present.** A face that is someone, driven by RaBbLE's puppet schema, not a status light. Ambient behaviour when idle.

## Licensing

- SDK code: **Apache-2.0**. Any file reused in RaBbLE firmware keeps its license header; carry attribution in our NOTICE. (The SDK repo has no NOTICE file of its own at `b139b45`; the headers are the attribution.)
- **Jollybot avatar (`esp32/avatar/`) is excluded from Apache-2.0** (Meta copyright line only). Never copy it into RaBbLE.
- `minimp3.h` is CC0; `main/pixel_font.c` is BSD-2-Clause (Adafruit). Keep their own headers.
- Using the code needs no token. Only the Muse service does, and SDK tokens are personal, non-commercial use only (gadgets.muse.ai/sdk-terms). Nothing built on a Muse token ships to anyone else.

## Gotchas

- **SDK helper scripts vs EIM.** `tools/muse/board.sh` sources `$IDF_EXPORT` from inside itself; pointing that at EIM's `activate_idf_v6.0.1.sh` makes the activate script misdetect "not sourced" and call `exit 0`, so `board.sh` silently does nothing (same root cause as the gotcha in [RaBbLE-Pocket-Firmware-BuildFlash](RaBbLE-Pocket-Firmware-BuildFlash.md)). Also EIM defines `idf.py` as a shell **function**, which child scripts don't inherit. Working recipe from `esp32/`:
  ```sh
  bash -c '. ~/.espressif/tools/activate_idf_v6.0.1.sh >/dev/null 2>&1
           export PATH="$IDF_PATH/tools:$PATH"
           tools/muse/board.sh build s3n'          # or: flash s3n /dev/ttyACM0
  ```
- **Driving the console without resetting the board:** open the port with `HUPCL` cleared (recipe in the SDK's `esp32/AGENTS.md` "Monitor"); `tools/muse/monitor.py` resets first.
- **`board.sh` wipes `managed_components/` and `dependencies.lock`** before and after every build so board profiles don't clash.
- **Flash preserves NVS.** Pairing and Wi-Fi survive a reflash; `erase-flash` wipes them.
- **Partition table lives at `0x10000`,** not the IDF default `0x8000`. Don't move offsets.
- **NVS is plaintext** in this build (`link.config: NVS mode: plaintext`); the SDK recommends NVS encryption. Fine for a dev unit, revisit before anything carries real credentials.
- **`dev_signing_key.pem` is committed** in the SDK: app signing is a dev convenience, not security.
- **Community pairing has no manufacturer attestation** and doesn't stop an active MITM (logged at boot, stated in the SDK docs).
- The SDK token, if used, is compiled into the firmware: an identifier, not a secret.

## Next

- Decide whether to leave Muse on the board as a known-good hardware reference or restore our firmware from the backup.
- If porting: start with the board vtable + `muse_pmu` + `muse_audio` into `RaBbLE-Pocket/firmware/`, then the settings pattern and bench console, then a `muse_hatch_*`-shaped backend interface pointed at sCoRE.
- Optional quick win while Muse is on the board: fill `start_tts` with a local TTS server to hear the full loop.
