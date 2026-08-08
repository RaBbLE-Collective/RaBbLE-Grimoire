# RaBbLE-Pocket-V1-Firmware-Plan.md

First custom firmware build for the Waveshare ESP32-S3-Touch-AMOLED-1.75-B. Planned 2026-08-08, status: **Slices 0-4 verified on real hardware** (scaffold boots, AXP2101 battery/charging + PCF85063 RTC read/validity confirmed, idle screen with eyes/portals/time/battery, settings screen with RTC write, boot animation). Slices 5-6 (two-tier sleep/wake) not yet built. Check `firmware/CONTEXT.md` for the current slice. Architecture background: `RaBbLE-Pocket-Architecture.md`. Board spec: `RaBbLE-Pocket-Hardware.md`. Toolchain: `RaBbLE-Pocket-Firmware-BuildFlash.md`.

**Real measurement vs. plan assumption**: reading directly off ESP-IDF's own boot-elapsed log timestamps (not a self-measured `esp_timer_get_time()` delta scoped inside `app_main()`, which undercounts by missing the bootloader phase), reset-to-idle-screen is **~2.95s**, not the ≤2s originally targeted — already ~2.27s before any boot animation, plus the animation's own ~700ms. The dominant cost is two hardcoded vendor delays (600ms + 600ms) in the CO5300 panel's own `lcd_init_cmds` table (`waveshare__esp32_s3_touch_amoled_1_75.c`), not app code. Brookesia (the vendor's own reference firmware) hits the same floor — it just hides it better (see below). Target not revisited/relaxed explicitly with Mark yet; flagged, not blocking.

**Boot animation: switched from the planned GIF-export pipeline to native LVGL animation** (Mark's call, mid-build) — now that the idle screen's eye/portal objects were already built and hand-tuned on hardware, animating those same objects in from a hidden state keeps boot and idle visually consistent *by construction* (one shared module, `entity_face.h/.c`), with no export/encode/embed pipeline and no GIF palette-banding risk. v1 scope is deliberately minimal per Mark: just the two portal rings fading in (border-opacity 0→255, cyan then magenta staggered ~120ms), no eyes/particle field yet — those are a later pass. `screen_boot.c` implements this; `ops/export-boot-frames.sh`/`encode-boot-gif.sh` from the original plan were never built.

**Eye/portal final geometry** (in `entity_face.h`, ported from `RaBbLE-NeBuLA/src/backends/eye-behavior.js` + `canvas2d/{eye-system,portal-system}.js` then hand-tuned against a live Playwright render of `<rabble-entity mode="idle">` and further tuned on real hardware): eyes share one centerline (`ENTITY_EYE_BASE_Y`); each portal is an independent anchor above/below its own eye with slight overlap — **always asymmetric**, never both on the same side. Cyan sits above (offset 64), magenta below (offset 67) — which color sits where may change later, but the asymmetry itself always holds. A real LVGL bug surfaced and got fixed along the way: **transform pivot defaults to an object's top-left corner, not its center** (confirmed in `lv_obj_pos.c`) — squashing an axis via `transform_scale_x/y` without pinning `transform_pivot_x/y` to 50%/50% first shrinks the shape toward that corner instead of staying centered where `lv_obj_align` put it. `entity_face.c`'s `make_ellipse()` sets the pivot explicitly for this reason.

**Two more hardware-verified fixes worth keeping in mind for any future screen/boot work**:
1. *White flash on boot* — `bsp_display_start()` calls `bsp_display_brightness_init()` (→100%) internally, before app code regains control, and also starts the LVGL adapter task as its own last step — so by the time it returns, a frame has already rendered at full brightness. Fix (matches Brookesia's own "P4 reference startup sequence", literally commented as such in `firmware/brookesia/main/main.cpp`): replicate the lower-level init sequence manually (`esp_lv_adapter_init` → `bsp_display_new` → register display/touch → `bsp_display_brightness_init()` then immediately `bsp_display_backlight_off()` → *then* `esp_lv_adapter_start()`), so the adapter's first render passes happen while already dark. Implemented as `rabble_display_start_dark()` in `app_main.c`, replacing `bsp_display_start()` entirely.
2. *Partial-frame flash (bottom half stale/white)* — even with the above fix, turning the backlight back on immediately after unlocking raced the first frame's multi-strip QSPI DMA flush (`buffer_height=50`, ~10 transfers to cover 466 rows) — `bsp_display_unlock()` returning only means LVGL finished rendering into the draw buffer, not that the panel transfer completed. Fixed with a blunt but reliable 100ms settle delay between unlock and `bsp_display_backlight_on()`; could be tightened later with a real flush-complete callback.

## Context

RaBbLE-Pocket has hardware in hand, a verified toolchain (`ops/build-flash.sh`, ESP-IDF v5.5.4), and a verified vendor LVGL demo proving display/touch/PSRAM all work — but no custom firmware yet. This plan builds the first real firmware: an idle face (eyes + time + battery %), a boot animation, touch-driven time/date settings, and power-button sleep/wake — following the BSP/HAL architecture already specified in `RaBbLE-Pocket-Architecture.md` (`rabble_hal.h` + one `bsp_waveshare_175b.c` per board, board selection as a build flag never a runtime branch).

The LVGL drag-drop simulator and the NeBuLA/Aether→LVGL asset translator Mark also wants are explicitly **out of scope** here — logged as Roadmap follow-ons once this build clarifies what the firmware actually needs from them.

## Decisions Locked In (with Mark, S — 2026-08-08)

1. **Sleep = two-tier: light sleep first, PMIC power-gate on escalation.** Confirmed directly from vendor source (`firmware/brookesia/components/ButtonTest/ButtonTest.cpp`): PWR is read via `esp_io_expander_get_level()` on TCA9554 EXIO4 (I2C poll, ~100ms), not a raw ESP32 GPIO interrupt — only BOOT (`gpio_get_level`) is a true GPIO in that file. A ~50-100ms poll is imperceptibly different from an interrupt to a human, so this doesn't block a responsive feel. Design:
   - **Tier 0 → Tier 1 (click to sleep):** a click on PWR turns the display off (CO5300 sleep-in) and puts the ESP32 into light sleep, waking every ~50-100ms (`esp_sleep_enable_timer_wakeup`) to poll EXIO4. Light sleep preserves all RAM/PSRAM — LVGL state is untouched.
   - **Tier 1 → Tier 0 (click to wake, within 45s):** a click detected on a light-sleep wake poll resumes immediately — display back on, no reboot, no boot animation. This is the seamless/instant path.
   - **Tier 1 → Tier 2 (45s with no wake click):** `rabble_axp2101_shutdown()` — true PMIC rail cut (reg `0x10` bit 0), µA-range draw, PCF85063 RTC keeps time on its own backup supply. This is where real power is actually saved; Tier 1 alone is not low-power enough to sit in indefinitely.
   - **Tier 2 → Tier 0 (click to wake from full off):** AXP2101's PEKEY power-on press time is configurable (`setPowerKeyPressOnTime`, options 128ms/512ms/1s/2s — confirmed in `XPowersAXP2101.tpp`/`XPowersParams.hpp`). Configuring `XPOWERS_POWERON_128MS` at `rabble_hal_init()` means a normal single click reliably re-powers the rail — no hold required. The board's independent long-press-to-force-off hardware failsafe (`setPowerKeyPressOffTime`, default ~4s — what powered the board off during earlier hand-testing) stays as-is, unrelated to this path. A wake from Tier 2 is a real cold boot: bootloader + app init + boot animation, budgeted at **≤2s total** to first idle-screen frame — needs measuring real app-init overhead in Slice 0/1 before sizing the animation, not assumed.
   - Sleep entry is **click-triggered only** in v1, not inactivity-triggered — simpler, and matches the corrected spec directly. (`lv_display_get_inactive_time` is not used for anything in this design.)
2. **Boot animation = exported bitmap/GIF frame playback of the real `RaBbLE-Boot.html` sequence**, not hand-authored LVGL primitives. Math checked out: 466×466 frames with a mostly-black background compress via indexed+RLE/GIF to roughly 300 KB–1.5 MB for 60 frames — trivial against 16MB flash. LVGL v9 ships a built-in GIF decoder (`lv_gif`, no custom code needed), and GIF's transparency + LZW naturally exploit both "black compresses to nothing" and frame-to-frame redundancy. This gets real visual fidelity to the reference animation for an asset-export cost, not an animation-authoring cost.
3. **Tooling deferred.** LVGL simulator/editor and NeBuLA/Aether→LVGL translator get a Roadmap entry, not design work, in this pass.

## Confirmed Hardware Facts (source: `firmware/ESP32-S3-Touch-AMOLED-1.75/HARDWARE_REFERENCE.md`, vendor examples, datasheets — not re-derived)

- I2C bus: GPIO14 (SCL) / GPIO15 (SDA), shared by AXP2101 (`0x34`), TCA9554 (`0x20`), PCF85063 (`0x51`), touch, IMU.
- TCA9554 pin map: P3=`RTC_INT`, P4=`SYS_OUT` (PWR button, HIGH=pressed), P5=`AXP_IRQ`, P6=`QMI_INT1`. **No expander interrupt line reaches an ESP32 GPIO** — everything here is I2C-polled, not ISR-driven.
- Vendor `bsp/esp-bsp.h` already exposes `bsp_i2c_init()`, `bsp_i2c_get_handle()`, `bsp_io_expander_init()` — reused, not reimplemented. Vendor BSP stays out of power/button/RTC (`BSP_CAPS_BUTTONS 0`), so that's exactly this plan's custom-HAL scope.
- AXP2101 (from working `examples/esp-idf/01_AXP2101` reference, `XPowersLib`): `XPOWERS_AXP2101_COMMON_CONFIG` reg `0x10` bit 0 = software shutdown (cuts all rails except VRTC). `XPOWERS_AXP2101_BAT_PERCENT_DATA` reg `0xA4` = direct 0–100 fuel-gauge percent, no voltage-curve math needed. PEKEY press timing is separately configurable via `setPowerKeyPressOnTime()`/`setPowerKeyPressOffTime()` (both bitfields in `XPOWERS_AXP2101_IRQ_OFF_ON_LEVEL_CTRL`) — press-on options are `128MS/512MS/1S/2S` (`xpowers_press_on_time_t`), press-off (hardware force-off failsafe) options are `4S/6S/8S/10S` (`xpowers_press_off_time_t`). Both confirmed in `XPowersAXP2101.tpp`/`XPowersParams.hpp`, not guessed.
- PCF85063 (register addresses cross-checked against `examples/arduino/libraries/SensorLib` — Arduino reference, but register addresses are hardware facts): slave `0x51`, 7 contiguous BCD registers `SEC..YEAR` at `0x04..0x0A`, seconds register bit 7 = oscillator-integrity flag (0=good, 1=never set / interrupted) — drives a "set your clock" state on true first boot. No existing ESP-IDF PCF85063 component in this repo; small custom driver required.
- Palette: only `RaBbLE-Agent/RaBbLE-Palette.md` hex values (magenta `#ff2d78`, cyan `#00f5ff`, void bg `#0a0010`) — matches the idle-face reference image's pink/cyan pill eyes.

## Firmware Architecture

`firmware/` becomes the ESP-IDF project root (`ops/build-flash.sh firmware` needs `firmware/CMakeLists.txt`).

**Tasks** (kept minimal, per the BSP/HAL doc's own "keep it simple" framing):
1. LVGL render/tick task — already created by the vendor BSP's `bsp_display_start()`; all UI code wraps `lv_...` calls in `bsp_display_lock()`/`unlock()`, same as `02_lvgl_demo_v9`.
2. `app_main` — init only (NVS, `bsp_display_start()`, `rabble_hal_init()` incl. one-time `setPowerKeyPressOnTime(XPOWERS_POWERON_128MS)`, create app state machine, spawn the one task below), then returns.
3. **`rabble_power_task`** (the only new task, owns the whole Tier 0/1/2 state machine):
   - **Tier 0 (awake)**: polls TCA9554 P4 every ~100ms for a press edge. On press → `bsp_display_lock()`, panel sleep-in command, `bsp_display_unlock()`, enter Tier 1.
   - **Tier 1 (light sleep)**: loop of `esp_sleep_enable_timer_wakeup(POLL_INTERVAL_US)` + `esp_light_sleep_start()`, each wake checking (a) EXIO4 pressed → panel wake command, return to Tier 0 (instant resume, no reboot), or (b) elapsed time since Tier-1 entry ≥ `CONFIG_RABBLE_SLEEP_TIMEOUT_MS` (Kconfig, default 45000) → `rabble_hal_power_shutdown()` (Tier 2, does not return — AXP2101 cuts the rail and the ESP32 dies here).
   - Tier 2 → Tier 0 is not code this task runs — it's the AXP2101 re-powering the rail on the next qualifying PWR press (128ms config above), which cold-boots `app_main` fresh.
   - ESP-IDF v5.x I2C bus handles are thread-safe per-transaction, so no mutex needed against LVGL-timer-driven I2C reads elsewhere.
4. Clock (1Hz) and battery (30–60s) refresh ride on `lv_timer_create()` callbacks inside the existing LVGL task — no extra task/queue needed. These are naturally paused during Tier 1 (light sleep halts all tasks) and resume automatically on Tier 1→0 wake.

## `firmware/bsp/rabble_hal.h` — v1 Surface

Display/touch already covered by the vendor BSP — not rewrapped. This HAL covers only what it doesn't: power, button, RTC.

```c
esp_err_t rabble_hal_init(void);   // brings up TCA9554 dir config, AXP2101 (incl. 128ms
                                    // press-on-time config), PCF85063 on the shared I2C bus

esp_err_t rabble_hal_power_get_battery_percent(uint8_t *out_percent);
bool      rabble_hal_power_is_charging(void);
void      rabble_hal_power_shutdown(void);   // Tier 2: cuts 3V3 rail; does not return

void rabble_hal_display_sleep(void);         // Tier 1 entry: panel sleep-in command
void rabble_hal_display_wake(void);          // Tier 1 exit: panel wake command

bool rabble_hal_button_is_pressed(void);     // TCA9554 P4 / SYS_OUT

typedef struct {
    uint16_t year; uint8_t month, day, hour, minute, second, weekday;
} rabble_datetime_t;

esp_err_t rabble_hal_rtc_get_datetime(rabble_datetime_t *out);
esp_err_t rabble_hal_rtc_set_datetime(const rabble_datetime_t *in);
bool      rabble_hal_rtc_time_is_valid(void);   // false only on a never-set RTC
```

`bsp_waveshare_175b.c` is where the TCA9554 pin→meaning mapping lives (P3/P4/P5/P6) — the only place it's allowed to appear, per the HAL boundary rule. AXP2101 and PCF85063 register-level code live in their own reusable components (`firmware/components/rabble_axp2101/`, `firmware/components/rabble_pcf85063/`) since both chips are plausibly shared with the future 1.75C board (which drops the RTC and TF slot but not the PMIC) — mirrors how the vendor BSP composes TCA9554 as a sub-component rather than inlining it.

## App-Layer Screens

State machine: `APP_STATE_BOOT → APP_STATE_IDLE ⇄ APP_STATE_SETTINGS`. `LISTENING/THINKING/SPEAKING` named as placeholders for the future wake-word epoch, no screens built yet.

- **`screen_boot.c`**: an `lv_gif` object playing the embedded boot animation asset (see below), loop count 1. `LV_EVENT_READY` (gif finished) → transition to `APP_STATE_IDLE`.
- **`screen_idle.c`**: twin vertical pill eyes (rounded-rect `lv_obj`s, magenta `#ff2d78` left / cyan `#00f5ff` right, thin light ring border, subtle gradient), large centered time label (from `rabble_hal_rtc_get_datetime`, 1Hz refresh), battery-% label (30–60s refresh), "RaBbLE" wordmark. Dark void bg. Long-press (~800ms) on the time label opens Settings.
- **`screen_settings.c`**: `lv_roller`/`lv_spinbox` for year/month/day/hour/minute, Save (→ `rabble_hal_rtc_set_datetime`, back to Idle) / Cancel.
- **Sleep trigger** lives entirely in `rabble_power_task`, independent of app state — a click sleeps regardless of which screen is showing (no fade-out needed; the panel sleep-in command handles it, and Tier 2's rail cut is instant regardless).

## Boot Animation Asset Pipeline (per decision #2)

1. `ops/export-boot-frames.sh` — reuses the Collective's existing Playwright capture pattern to render `RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/RaBbLE-Boot.html` frame-by-frame at 466×466. **Time-compressed, not the reference's full ~7s** — the whole cold-boot path (bootloader + app init + animation) is budgeted at ≤2s to the idle screen. Measure real app-init overhead in Slice 0/1 first (NVS + I2C + display + LVGL bring-up on this MCU — not yet measured), then size the captured timeline/frame-count to whatever's left of the 2s ceiling; expect well under the original 60-frame/7s estimate, likely 20-40 frames playing at a compressed pace of the same visual beats (particle converge → eyes → wordmark), not a slowed-down or truncated version.
2. `ops/encode-boot-gif.sh` — `ffmpeg`/`gifsicle` pipeline: build an indexed, transparent-background GIF from the PNG sequence (black → transparent index, exploiting the mostly-black frames; global palette to keep size down). At this frame count the byte budget is even more comfortable than the original 60-frame estimate — report final size regardless.
3. Output committed as a generated asset: `firmware/main/assets/rabble_boot_gif.c` — raw GIF bytes as a `const uint8_t[]` (LVGL's `lv_gif` widget consumes raw GIF bytes directly via an `lv_image_dsc_t` with `LV_COLOR_FORMAT_RAW`, no LVGL image-converter step needed). Treated like the CAD `hardware/cad/out/*.stl` outputs — checked in, regenerated by re-running the two scripts above, not rebuilt on every firmware build.
4. Known limitation to note, not solve now: GIF's 256-color palette may band the gradient fill on the eye pills in the final frames — acceptable for v1, revisit if it looks bad on the real AMOLED.
5. Keeping this in internal flash (not the -B board's TF/SD slot) matters for board portability — the future 1.75C board has no TF slot.

## New Files Under `firmware/`

```
firmware/
  CMakeLists.txt  sdkconfig.defaults  partitions.csv
  main/
    CMakeLists.txt  idf_component.yml   # waveshare/esp32_s3_touch_amoled_1_75, lvgl/lvgl "9.4.*"
    Kconfig.projbuild                    # board-select choice; RABBLE_IDLE_TIMEOUT_MS default 45000
    app_main.c
    app/
      app_state.h/.c
      screen_boot.h/.c  screen_idle.h/.c  screen_settings.h/.c
      power_task.h/.c
      ui_theme.h                         # RaBbLE-Palette.md hex constants, single source in-firmware
    assets/
      rabble_boot_gif.c                  # generated, see pipeline above
      README.md                          # regen command
  bsp/
    CMakeLists.txt  rabble_hal.h  bsp_waveshare_175b.c
  components/
    rabble_axp2101/  (CMakeLists.txt, include/rabble_axp2101.h, rabble_axp2101.c)
    rabble_pcf85063/ (CMakeLists.txt, include/rabble_pcf85063.h, rabble_pcf85063.c)
ops/
  export-boot-frames.sh
  encode-boot-gif.sh
```

## PCF85063 Driver

`rabble_pcf85063_init(dev)` (just confirms ACK, chip free-runs from power-on) · `get_datetime`/`set_datetime` (7-byte BCD burst read/write at `0x04`, weekday recomputed from y/m/d rather than trusted from input) · `time_is_valid()` (seconds-register bit 7).

## Power-Gate Sleep — Resolved Sub-Questions

- **Tier 2 shutdown register sequence**: `rabble_axp2101_shutdown()` sets bit 0 of reg `0x10` (`XPOWERS_AXP2101_COMMON_CONFIG`), confirmed from the working `01_AXP2101` reference, not guessed from the datasheet alone.
- **Tier 1→2 45s timer**: plain elapsed-time check against `CONFIG_RABBLE_SLEEP_TIMEOUT_MS` inside `rabble_power_task`'s light-sleep poll loop (no LVGL inactivity API needed — Tier 1 entry is already click-triggered, not idle-triggered).
- **Tier 2→0 wake press duration**: resolved, not just flagged — `setPowerKeyPressOnTime(XPOWERS_POWERON_128MS)` configured once in `rabble_hal_init()` makes a normal single click sufficient (confirmed as a real configurable register, not assumed default behavior). **Remaining open risk**: whether this register setting itself survives a Tier 2 power-gate (AXP2101's shutdown leaves only its VRTC domain alive) or resets to a power-on default each time. Low-stakes either way since `rabble_hal_init()` reasserts it on every single boot regardless of whether it was needed — but worth confirming empirically in Slice 6/7 (does a click reliably wake it on the *first* Tier-2 wake attempt, before `rabble_hal_init()` has had a chance to "pre-configure" anything for that wake) rather than assumed from code reading.

## Verification — Incremental Slices

All via `ops/build-flash.sh firmware -m` (already verified working). Ordered low-risk-and-serial-debuggable first; power-gate last since a bug there can kill the USB-serial link along with the rail.

1. **Scaffold boots** — empty `app_main.c` + `bsp_display_start()` + blank screen + log line, timestamped from reset to first LVGL frame. Confirms the new CMake/component layout builds/flashes clean **and gives the real app-init latency number** the boot-animation frame budget depends on.
2. **Battery % + RTC read, serial-only** — bring up `rabble_axp2101`/`rabble_pcf85063`, log values, no UI. Smallest slice touching new I2C code.
3. **Idle screen UI** — static eyes/time/battery/wordmark shown directly at boot, no animation/settings yet. Validates palette/fonts/layout on the real round AMOLED.
4. **Boot animation pipeline** — using Slice 1's measured init latency, size the exported timeline to fit the ≤2s total ceiling; run `export-boot-frames.sh` + `encode-boot-gif.sh`, wire `screen_boot.c`'s `lv_gif`, confirm it plays then hands off to idle, and stopwatch the actual reset-to-idle-screen time against the 2s target.
5. **Settings + RTC write** — wire long-press, set a time, power-cycle over USB (unplug/replug, not sleep), confirm PCF85063 held it.
6. **Tier 1 light-sleep click-to-sleep/wake** — click sleeps (display off), a second click within 45s wakes instantly with no reboot and no boot-animation replay (this is the "seamless" requirement — confirm serial log continuity across the sleep/wake, unlike Tier 2). Time the resume latency.
7. **Tier 2 power-gate (last)** — let Tier 1 run the full 45s unclicked, confirm the rail actually cuts (serial connection drops — expected, not a bug), then click PWR and confirm a single click reliably produces a fresh cold boot with new serial output from power-on — this is also the empirical test for the 128ms-press-on-config persistence risk above.

## Doc Updates This Plan Triggers

- `RaBbLE-Pocket-Architecture.md`: add "Application State Machine (v1)" and "Power Management" subsections once the design is built and verified.
- New ADR `RaBbLE-Pocket/planning/decisions/2026-08-08-two-tier-sleep.md` (repo-local, not Grimoire): the two-tier light-sleep/PMIC-gate decision, the hardware reason PWR can't be a raw GPIO wake source, the 128ms PEKEY press-on config, the remaining register-persistence risk.
- `RaBbLE-Pocket-Roadmap.md`: tick the display/touch bring-up item; add wake-word screens and the deferred LVGL-simulator/NeBuLA-translator tooling as new open items.
- `firmware/CONTEXT.md` and repo-root `CONTEXT.md`: flip "not yet scaffolded" once this lands; tick the BSP-scaffold checklist item.

## Deferred (Roadmap, not this plan)

LVGL simulator/drag-drop editor · NeBuLA/Aether→LVGL asset translator · mic/IMU/BLE/WiFi/wake-word bring-up · AXP2101 IRQ-line handling (v1 polls only).
