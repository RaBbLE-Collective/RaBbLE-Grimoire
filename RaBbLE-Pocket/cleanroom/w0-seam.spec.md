# W0 seam spec: board vtable, memory/core macros, app start-up, LVGL allocator

> Spec author: S (W0 seam group). Targets, all under `firmware/components/rabble_gadget/apache/`: `rabble_board.h`, `rabble_mem.h`, `rabble_board.c`, `rabble_lv_mem.c`, `rabble_app.c`.
> Companion (written in parallel by another author): the spec for `rabble_state.c/.h`. This document treats `rabble_state.h` as an external dependency by public name only (list in section 9).
> Implementer rule: new files carry only `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.`
> Toolchain facts: ESP-IDF v6.0.1, LVGL 9.5.0, esp_lvgl_adapter 0.6.4, esp_codec_dev. Target chip ESP32-S3 with octal PSRAM.

Everything in `accord/`, `main/`, `bsp/`, and the other `apache/` modules compiles against these five files. A missing or mis-typed name is a build break, and a changed value (a core number, a priority) is a behaviour change. Names, field order and values in sections 2 to 5 are therefore binding. Comments, helper names and structure are the implementer's own.

---

## 1. Purpose of each file

| File | Purpose |
|---|---|
| `rabble_board.h` | The hardware seam. Defines the board description type `rabble_board_t` (identity, geometry, capability flags, and a table of hardware callbacks), the helper types it uses, the global pointer to the running board, the entry-point prototypes `rabble_app_run` and `rabble_board_get`, and the debounced GPIO button helper API. Every UI, voice, input, settings, Wi-Fi and beam module reaches hardware only through it. |
| `rabble_mem.h` | Build-time constants only: which heap capabilities "big buffers" use, a low-memory flag, and which CPU core and priority audio and the UI run on. |
| `rabble_board.c` | Implements the GPIO button helper API from `rabble_board.h` (debounce, edge reporting, light-sleep wake-on-button wait). Holds no board data. |
| `rabble_lv_mem.c` | Provides LVGL's custom memory back end so LVGL's objects, styles and draw buffers live in PSRAM. Selected by `CONFIG_LV_USE_CUSTOM_MALLOC=y`. |
| `rabble_app.c` | Defines the global `rabble_board` pointer and `rabble_app_run()`: the one-shot start-up sequence that brings every subsystem up in order, plus the settings-change dispatcher that applies stored settings to hardware. |

---

## 2. `rabble_mem.h`

Include set it must provide to its includers: `esp_heap_caps.h` (callers rely on `MALLOC_CAP_*` and `heap_caps_*` arriving through it) and `sdkconfig.h`. It has include guards (`#pragma once` is fine).

| Macro | Value | Meaning |
|---|---|---|
| `RABBLE_BIG_CAPS` | with `CONFIG_SPIRAM`: `(MALLOC_CAP_SPIRAM \| MALLOC_CAP_8BIT)`; without: `(MALLOC_CAP_INTERNAL \| MALLOC_CAP_8BIT)` | Caps for large, non-DMA buffers and for task stacks created with the caps variant of task creation. |
| `RABBLE_LOW_MEM` | `0` with `CONFIG_SPIRAM`, otherwise `1` | Used by `#if` in `rabble_voice.c` to shrink buffers on boards with no PSRAM. Must be a plain integer usable in the preprocessor. |
| `RABBLE_AUDIO_CORE` | `0` when `CONFIG_FREERTOS_UNICORE`, otherwise `1` | Core the voice task is pinned to. |
| `RABBLE_UI_CORE` | defined as `RABBLE_AUDIO_CORE` (so `1` on the S3) | Core for LVGL's task, the panel send task, and the boot task in `main/app_main.c`. Used as a compile-time integer, including in arithmetic (`1 - RABBLE_UI_CORE` is the helper-core in `bsp/rabble_lcd_bands.c`) and as an array index (`s_drender_us[RABBLE_UI_CORE]`). Must be a literal-valued constant expression. |
| `RABBLE_UI_PRIORITY` | `5` | FreeRTOS priority of LVGL's task as configured through the LVGL adapter. The panel send task runs at this plus 1, and the BSP moves it to this minus 1 or plus 1 depending on the direct-draw mode, so the value must stay 5 and be a plain integer. |

Rationale to preserve: the UI shares the audio core, one priority below the voice task (priority 6); the first core is left for Wi-Fi, the network stack and reply decoding. Do not leave LVGL's task unpinned.

Users of this header (for reference): `main/app_main.c`, `bsp/bsp_waveshare_175b.c`, `bsp/rabble_lcd_bands.c`, `accord/rabble_entity.c`, `accord/rabble_beam_score.c`, `apache/rabble_audio.c`, `apache/rabble_input.c`, `apache/rabble_voice.c`.

---

## 3. `rabble_board.h`: complete interface

The header must be C++-safe (`extern "C"` wrapper). It must include (callers get these transitively and several rely on it): `stdbool.h`, `stdint.h`, `time.h`, `driver/gpio.h`, `esp_codec_dev.h`, `esp_err.h`, `lvgl.h`, and `rabble_state.h` (for `rabble_power_t` and the state API; `rabble_board.c` calls `rabble_state_asleep()` through it).

### 3.1 Button edge flags

Returned (OR-ed) by `poll_buttons`. Exact values:

| Macro | Value |
|---|---|
| `RABBLE_BTN_TALK_PRESS` | `1u << 0` |
| `RABBLE_BTN_TALK_RELEASE` | `1u << 1` |
| `RABBLE_BTN_AUX_PRESS` | `1u << 2` |
| `RABBLE_BTN_AUX_RELEASE` | `1u << 3` |

### 3.2 `rabble_button_hint_t`

Struct, fields in this order: `lv_align_t align;` then `int16_t x, y;`. The board initialises it positionally in the form `{ LV_ALIGN_CENTER, 160, 106 }`, so the order is load-bearing. Meaning: where a button's on-screen icon sits, as an LVGL alignment plus offset, beside the physical button and inside the panel. Read by `accord/rabble_ui.c` and `accord/rabble_entity.c`.

### 3.3 `rabble_display_direct_t`

Struct, fields in this order (the entity initialises it with designated initialisers, but keep order anyway):

| Field | Type | Contract |
|---|---|---|
| `begin` | `void (*)(void)` | Called once per frame, paced by the panel, on the panel send task which runs on `RABBLE_UI_CORE`. Builds all per-frame state. |
| `window` | `void (*)(int y0, int rows, int *x0, int *x1)` | For a band starting at row `y0` with `rows` rows, reports the horizontal span `[*x0, *x1)` that will actually be rendered/sent. |
| `render` | `void (*)(uint16_t *dst, int y0, int rows, int x0, int x1)` | Renders one band into `dst` (RGB565). May run on either core, possibly two bands at once, so it may only read what `begin` built. |
| `same` | `int (*)(int y0)` | Optional (may be NULL). Returns non-zero if the band at `y0` would render exactly as in the previous frame, letting the board skip it. |
| `rows` | `int` | Band height in rows. The entity sets it to its band constant (16 on this board). |

### 3.4 Texture API

| Name | Kind | Value / shape |
|---|---|---|
| `RABBLE_UI_TEXTURE_BAND` | macro | `16`. Rows per `band_ver` entry. Used in `bsp/rabble_lcd_bands.c` for array sizing and loops. |
| `rabble_ui_texture_t` | struct | Fields in order: `const uint16_t *px;` (width x height RGB565, native byte order, tightly packed rows of `width` pixels), `const uint32_t *band_ver;` (one counter per `RABBLE_UI_TEXTURE_BAND` rows that changes whenever any row in that band changes), `int32_t tag;` (the value `ui_texture_tag()` was given during the LVGL refresh that produced this texture). |

### 3.5 `rabble_board_t`

One struct. **Field order matters only where a board initialises positionally; the existing board uses designated initialisers throughout, but keep exactly this order** so a future positional initialiser or an aggregate copy behaves identically. Types are exact.

Data members (order, type, name, semantics):

| # | Type | Name | Semantics and readers |
|---|---|---|---|
| 1 | `const char *` | `name` | Board display name. Logged at boot (`rabble_app.c`) and put in the `@status` serial line (`rabble_input.c`). Must be non-NULL. |
| 2 | `int` | `width` | Panel width in pixels. Read by `accord/rabble_ui.c` (touch mapping, log) and `rabble_settings_ui.c` (layout). |
| 3 | `int` | `height` | Panel height in pixels. Same readers. |
| 4 | `bool` | `round` | Circular panel. Layout keeps content within the circle (`rabble_settings_ui.c`). |
| 5 | `bool` | `touch` | Board has touch; `rabble_ui.c` only builds the settings tile if true. |
| 6 | `float` | `diagonal_in` | Screen diagonal in inches. `rabble_settings_ui.c` uses a bigger-key keypad when below 2.0. |
| 7 | `const char *` | `talk_button` | Short word naming where/what the talk button is (the existing board says `"boot"`). Passed as the wake reason text to the input module's sleep/wake logic. NULL not expected. |
| 8 | `const char *` | `aux_button` | Same for the aux (power) button (existing board: `"pwr"`). **NULL means the board has no aux button**: `rabble_ui.c`, `rabble_entity.c` and `rabble_settings_ui.c` test it for truth to decide whether to draw/describe the aux icon. |
| 9 | `rabble_button_hint_t` | `talk_hint` | Mic icon placement. |
| 10 | `rabble_button_hint_t` | `aux_hint` | Power icon placement. Left zero-initialised when there is no aux button. |
| 11 | `int` | `frame_ms` | LVGL face animation period; `rabble_ui.c` uses it as the period of its frame timer. |
| 12 | `float[2]` | `mic_deg` | Angular position of the two microphones around the panel in degrees clockwise from 3 o'clock. Copied into the entity's input by `rabble_entity.c`. |

Callback members (declared in this order; all `const`-struct members, set once at build time):

| # | Prototype | Name | May be NULL | Called by / on which task | Required behaviour |
|---|---|---|---|---|---|
| 13 | `esp_err_t (*)(void)` | `init` | No | `rabble_app_run`, on the boot task (pinned to `RABBLE_UI_CORE`), once, first board call | Power rails, buses, expanders, button GPIOs. Runs after NVS settings are ready (the board may read settings). Non-`ESP_OK` is fatal (abort). |
| 14 | `lv_display_t *(*)(lv_indev_t **touch)` | `display_start` | No | `rabble_ui_start`, boot task, once | Brings up the panel, LVGL and LVGL's task (priority `RABBLE_UI_PRIORITY` on `RABBLE_UI_CORE`). `*touch` may be left NULL. Returns NULL on failure. |
| 15 | `bool (*)(int timeout_ms)` | `display_lock` | No | any task that touches LVGL | Takes LVGL's recursive lock; `-1` waits forever; false on timeout. |
| 16 | `void (*)(void)` | `display_unlock` | No | same | Releases it. The existing board points this directly at the adapter's unlock, so the signature must be exactly `void(void)`. |
| 17 | `void (*)(int pct)` | `set_brightness` | No | `rabble_ui.c` | 0 to 100; 0 is off. |
| 18 | `void (*)(bool sleep)` | `panel_sleep` | Yes (then backlight only) | `rabble_ui.c` on sleep/wake | Screen off/on at the panel. |
| 19 | `void (*)(bool pause)` | `display_pause` | Yes (then LVGL keeps running) | input task, only when on battery and asleep | `true`: stop LVGL's task, its tick, and touch so the chip can light-sleep; buttons must still wake it. `false`: resume. |
| 20 | `void (*)(const rabble_display_direct_t *d)` | `display_direct` | Yes | `rabble_entity.c` | Non-NULL: switch the panel to direct band drawing with `d`; NULL: hand the panel back to LVGL. Returns once the switch is complete. |
| 21 | `void (*)(uint32_t *frames, uint32_t render_us[2])` | `direct_stats` | Only if `display_direct` is NULL | `rabble_entity.c` (calls it unconditionally when direct mode is up) | Frame counter and the last frame's CPU time in microseconds per core (index = core id). |
| 22 | `int` | `direct_rows` | n/a (data) | `rabble_entity.c` | Band height the board accepts; 0 if the board cannot draw directly. The entity enables direct mode only when this equals its own band constant. **Declared between `direct_stats` and `ui_texture`** (see order; this is a data member among callbacks). |
| 23 | `bool (*)(rabble_ui_texture_t *out)` | `ui_texture` | Yes (no texture) | the direct renderer's `begin()` (UI core); also `rabble_ui.c` with `out == NULL` | With `out`: fills the texture; the pointers stay valid until the next `begin()`. Returns false until a whole screen has been drawn since direct mode started. With `out == NULL`: from any task, reports only whether the board has the texture facility at all. |
| 24 | `void (*)(int32_t tag)` | `ui_texture_tag` | Yes | `rabble_ui.c`, in LVGL's context during a refresh | Labels the texture published by that refresh (`rabble_ui.c` passes panel width when a non-main screen is active, else the tile view scroll x). |
| 25 | `esp_err_t (*)(esp_codec_dev_handle_t *spk, esp_codec_dev_handle_t *mic)` | `audio_init` | Yes (display-only board) | `rabble_audio` init, via the voice start | Returns codec handles for one full-duplex, 2-slot I2S bus, not yet opened. |
| 26 | `int` | `mic_slot` | n/a | `rabble_audio.c` | `0` or `1`: that I2S slot carries the mic; `-1`: average both slots. |
| 27 | `void (*)(esp_codec_dev_handle_t mic, int db)` | `set_mic_gain` | Yes (then caller uses `esp_codec_dev_set_in_gain`) | `rabble_audio.c` | Board-specific gain mapping. |
| 28 | `unsigned (*)(void)` | `poll_buttons` | No | the input task | Called every 10 ms awake. While the display is paused it is called every 50 ms unless `wait_buttons` exists. Returns OR-ed `RABBLE_BTN_*`. |
| 29 | `void (*)(int timeout_ms)` | `wait_buttons` | Yes (then polled) | the input task, display paused | Returns when a button changes (waking the chip from light sleep), the calling task is notified, or `timeout_ms` passes. |
| 30 | `esp_err_t (*)(rabble_power_t *out)` | `read_power` | Yes (the caller tests it) | input task | Fills battery, charging and USB status. |
| 31 | `esp_err_t (*)(void)` | `power_off` | No | input task | Turns the board off; returns only on failure (caller then handles the error). |
| 32 | `esp_err_t (*)(struct tm *out)` | `rtc_get` | Yes (no RTC) | `rabble_ui.c`, `rabble_time.c`, `rabble_entity.c`, `rabble_settings_ui.c` | Reads the battery-backed clock as local time. |
| 33 | `esp_err_t (*)(const struct tm *in)` | `rtc_set` | Yes | `rabble_time.c` (NULL treated as `ESP_ERR_NOT_SUPPORTED`) | Writes it. |
| 34 | `bool (*)(void)` | `rtc_valid` | Yes (callers then trust `rtc_get`) | `rabble_time.c` | False if the clock was never set or lost backup power. |
| 35 | `esp_err_t (*)(float accel[3])` | `imu_read` | Yes (no IMU; `rabble_motion_start` fails and motion features turn off) | `rabble_motion.c`, serial console in `rabble_input.c` | Acceleration in g, screen axes: x right, y toward the top of the face, z out of the screen; at rest it reads the up direction. |
| 36 | `void (*)(bool low)` | `imu_low_power` | Yes | `rabble_motion.c` | `true` when asleep: slower duty-cycled rate. |

Positional note: the unnamed ordering above is the declaration order. Mixed data and callback members are interleaved exactly as numbered (`direct_rows` after `direct_stats`; `mic_slot` after `audio_init`; `mic_deg` after `aux_hint`/`frame_ms`).

Callers' NULL discipline: callers test before calling these members: `panel_sleep`, `display_pause`, `display_direct`, `ui_texture`, `ui_texture_tag` (the UI treats texture overlay as on only if `ui_texture` and `ui_texture_tag` are both present and `ui_texture(NULL)` returns true), `set_mic_gain`, `wait_buttons`, `read_power`, `rtc_get`, `rtc_set`, `rtc_valid`, `imu_read`, `imu_low_power`, `audio_init`, `aux_button`. Callers call without testing: `init`, `display_start`, `display_lock`, `display_unlock`, `set_brightness`, `poll_buttons`, `power_off`, `direct_stats` (only after direct mode is established).

### 3.6 Global symbols and entry prototypes

| Symbol | Declaration | Defined in | Notes |
|---|---|---|---|
| `rabble_board` | `extern const rabble_board_t *rabble_board;` | `rabble_app.c` | Set first thing by `rabble_app_run`. Read by ~12 files. Not valid before that call. |
| `rabble_app_run` | `void rabble_app_run(const rabble_board_t *board);` | `rabble_app.c` | Called by `main/app_main.c`'s boot task. Starts everything and returns. |
| `rabble_board_get` | `const rabble_board_t *rabble_board_get(void);` | `bsp/bsp_waveshare_175b.c` (not in this group) | Declared here only. |

### 3.7 Button helper type and API

Type `rabble_gpio_button_t`, fields in this order: `gpio_num_t gpio;` `bool active_high;` `bool pressed;` `uint8_t stable;`. Boards declare these as zero-initialised statics and pass a pointer to the init functions. `pressed` is the debounced state; `stable` counts consecutive samples that disagree with it.

| Prototype | Behaviour |
|---|---|
| `esp_err_t rabble_gpio_button_init(rabble_gpio_button_t *b, gpio_num_t gpio);` | Active-low button; internal pull-up enabled when the pad supports output (input-only pads have none and the board must supply a pull-up). |
| `esp_err_t rabble_gpio_button_init_high(rabble_gpio_button_t *b, gpio_num_t gpio);` | Active-high button, driven both ways externally, no internal pull. |
| `unsigned rabble_gpio_button_poll(rabble_gpio_button_t *b);` | Debounce and edge report. Returns `RABBLE_BTN_TALK_PRESS`, `RABBLE_BTN_TALK_RELEASE`, or 0. The board shifts or remaps to aux if it needs. |
| `void rabble_gpio_buttons_wait(rabble_gpio_button_t *const *b, int n, int timeout_ms);` | Light-sleep-friendly wait on `n` buttons. |

Used today by `bsp_waveshare_175b.c` (init on GPIO 0 active low; poll in `poll_buttons`). `wait_buttons` is not set by the existing board.

---

## 4. `rabble_board.c`: behaviour rules

Numbered rules; the implementer chooses structure and names.

### 4.1 Init (both init variants)

1. After init the record describes a released button with no change pending, for the given pin and polarity, whatever it held before.
2. Configure the pad as a plain input. Pull-up on only when the button is active low AND the pad can also be an output (`GPIO_IS_VALID_OUTPUT_GPIO`). Pull-down is never enabled. No interrupt type is set at this point via `gpio_config`.
3. The GPIO ISR service must be installed (default allocation flags) before any per-pin handler is added, without logging an error when several buttons are initialised. Treat `ESP_ERR_INVALID_STATE` (already installed by someone else, e.g. the panel code) as success. Any other error is returned.
4. The pad gets an interrupt handler of its own, but its interrupt must be left **disabled** at the end of init: the line must not interrupt until a wait arms it.
5. Any failing step returns its `esp_err_t` and logs a short message carrying the pin number (tag string `"rabble_board"` is conventional; free to choose).
6. Safe to call for several buttons: ISR service is installed once, each button adds its own handler.

### 4.2 Raw level

A button is "raw pressed" when `gpio_get_level(pin)` equals `active_high` (read as bool). This is used both by poll and wait.

### 4.3 Poll (debounce)

State table (inputs: raw vs. debounced `pressed`):

| Condition | Action | Return |
|---|---|---|
| raw equals `pressed` | `stable = 0` | 0 |
| raw differs, and fewer than 3 consecutive differing samples seen (this one included), and NOT (raw is pressed AND `rabble_state_asleep()` is true) | `stable` counts up | 0 |
| raw differs and the sample is the 3rd consecutive one | `stable = 0`; `pressed = raw` | `RABBLE_BTN_TALK_PRESS` if raw is now pressed, else `RABBLE_BTN_TALK_RELEASE` |
| raw differs, raw is pressed, and the screen is asleep | accepted at the **first** sample (no debounce): `stable = 0`; `pressed = raw` | `RABBLE_BTN_TALK_PRESS` |

- The debounce depth is 3 samples. At the awake poll period of 10 ms this is 30 ms, which is the documented debounce time. The first sample counts as sample 1.
- The asleep bypass exists because a press is what woke the input task from light sleep, and waiting for two more samples at the slow sleeping poll rate would lose the press. It applies to presses only; releases are always debounced.
- A bounce back to the old level resets `stable` to 0 (that is the first row).

### 4.4 Wait (`rabble_gpio_buttons_wait`)

Requirements, in your own design:

1. If any of the `n` buttons is mid-change (its raw level already differs from its debounced state), do not arm anything: return after about one awake poll period (10 ms), so the caller keeps debouncing at the awake rate.
2. Otherwise block the calling task until one of: any button's pad reaches the level it would change to (its active level if released, its inactive level if pressed), the calling task receives a direct-to-task notification (`xTaskNotifyGive`, used by `rabble_input.c` to break the wait), or `timeout_ms` passes.
3. The pad level change must also wake the chip from automatic light sleep (GPIO wakeup), and must be detected even if the level changed between the mid-change check and the moment the wait began (level, not edge, semantics).
4. A notification left over from an earlier wait may make this wait return early. That is acceptable; a lost button change is not.
5. When the wait ends, no button pad is left interrupting or armed as a wake source. Interrupts must not storm while the pad is held at the armed level.
6. Only one waiting task at a time is supported (the input task).

Edge cases: `n == 0` is not used; behave sanely (just a notify/timeout wait). `timeout_ms <= 0` is not used by callers; do not hang on it beyond a zero-tick wait.

---

## 5. `rabble_lv_mem.c`: LVGL allocator hook contract

Build context: `CONFIG_LV_USE_CUSTOM_MALLOC=y` makes LVGL call these externally defined functions. Because the component is registered with `WHOLE_ARCHIVE`, the linker keeps this object even though nothing in RaBbLE references its symbols. The component's `CMakeLists.txt` must keep that flag. Include `lvgl.h` and LVGL's `src/stdlib/lv_mem.h` for the types.

Symbols to define, with the LVGL 9.5.0 prototypes exactly:

| Prototype | Required behaviour |
|---|---|
| `void lv_mem_init(void)` | Does nothing. |
| `void lv_mem_deinit(void)` | Does nothing. |
| `lv_mem_pool_t lv_mem_add_pool(void *mem, size_t bytes)` | Unsupported: ignores arguments, returns NULL. |
| `void lv_mem_remove_pool(lv_mem_pool_t pool)` | Unsupported: no-op. |
| `void *lv_malloc_core(size_t size)` | Try the ESP heap with capabilities `MALLOC_CAP_SPIRAM \| MALLOC_CAP_8BIT`. If that returns NULL, fall back to the C library `malloc` (which can serve from internal RAM). Return whatever results (possibly NULL). |
| `void *lv_realloc_core(void *p, size_t new_size)` | Same rule: `heap_caps_realloc` with the PSRAM caps first; on NULL, fall back to C `realloc(p, new_size)`. |
| `void lv_free_core(void *p)` | `heap_caps_free(p)`. This works for both PSRAM and internal blocks, so it frees either origin. |
| `void lv_mem_monitor_core(lv_mem_monitor_t *mon_p)` | Stub: leaves the structure as LVGL prepared it. Must not fault. |
| `lv_result_t lv_mem_test_core(void)` | Returns `LV_RESULT_OK` always. |

Rules:

1. PSRAM-first is the point. ESP-IDF's default C malloc places any allocation below the small-allocation threshold (configured at 16 KB) in internal RAM; a few hundred settings widgets would then starve Wi-Fi and the display's DMA bounce buffers. All LVGL allocations therefore request PSRAM explicitly.
2. The fallback to internal RAM exists so LVGL does not fail when PSRAM is temporarily exhausted. It must not be removed.
3. Allocation size 0 and `p == NULL` follow the underlying heap API semantics; no special handling.
4. No locking of its own: both ESP heap and libc heap are thread-safe. LVGL's own lock (`display_lock`) governs LVGL object access.
5. The functions must have external linkage with exactly these names; they are not declared in any RaBbLE header.
6. These do not use `RABBLE_BIG_CAPS`; the PSRAM requirement is unconditional here (this firmware only builds with PSRAM; on a no-PSRAM build the first attempt returns NULL and the fallback serves everything).

---

## 6. `rabble_app.c`: start-up sequence and setting dispatch

### 6.1 Definitions

Defines `const rabble_board_t *rabble_board;` (the global declared in the header) and `void rabble_app_run(const rabble_board_t *board)`. Log tag string `"rabble"`.

### 6.2 Calling context

`main/app_main.c` creates a task named `rabble_boot`, stack 8192 bytes, priority 5, pinned to `RABBLE_UI_CORE`, which calls `rabble_app_run(rabble_board_get())` then deletes itself. This is deliberate: the panel's SPI interrupt is allocated on the core of the task that sets the bus up, and must be the core of the panel send task. `rabble_app_run` therefore must run **all** of its board and UI bring-up on its calling task, never hand the work to another task or core, and it **returns** when done (the boot task then exits). It is called once; calling twice is unsupported.

### 6.3 Ordered steps

Each step runs only after the previous one returned. "Fatal" means `ESP_ERROR_CHECK` semantics: the device logs and aborts, then reboots.

| # | Action | On failure |
|---|---|---|
| 1 | Store the board pointer in the global `rabble_board`. | n/a |
| 2 | Log at info level `board: <name>`. | n/a |
| 3 | `rabble_settings_init()` (NVS and stored values). Must precede the board's `init`, because the board may read settings. | Fatal |
| 4 | `board->init()`. | Fatal |
| 5 | Register the setting-change dispatcher (section 6.4) with `rabble_settings_set_listener`. After the board init and before anything that could change settings. | n/a |
| 6 | `rabble_state_init()`. | n/a (void) |
| 7 | `rabble_battery_init()`. | n/a (void) |
| 8 | `rabble_state_set_caption("WAKING UP...")` (text exactly this; a printf-style call whose format is this literal). | n/a |
| 9 | `rabble_ui_start()`; this calls `display_start`, builds LVGL screens and starts the entity. | Fatal |
| 10 | Log at info: `UI built: free internal <N>` where N is `heap_caps_get_free_size(MALLOC_CAP_INTERNAL)` printed as unsigned decimal. | n/a |
| 11 | Create the input event queue: length 16, item size `sizeof(rabble_input_event_t)`. | A NULL queue is not specially handled (original does not check); an implementer should treat a creation failure as fatal. |
| 12 | `rabble_input_start(queue)` (starts the input task, 4096-byte stack, priority 6, plus the serial console task, 3584 bytes, priority 5; owned by the input module). | Fatal |
| 13 | Delay 1400 ms (`vTaskDelay`) so the boot animation (portals opening, eyes emerging) finishes. | n/a |
| 14 | Voice stage, three-way choice, below. | see below |
| 15 | `rabble_motion_start()`; on non-OK log a warning `no motion: raise to wake and the upright face are off`. | Warning only |
| 16 | `rabble_wifi_start()`. | Fatal |
| 17 | `rabble_beam_start()` (void). | n/a |
| 18 | Log at info: `ready: free heap <A> internal, <B> psram` (A: internal-RAM free bytes, B: SPIRAM free bytes, both unsigned decimal). | n/a |

Step 14 detail:

| Condition | Action |
|---|---|
| `board->audio_init == NULL` | Log info `display-only board: no microphone or speaker`. Set mode `RABBLE_MODE_IDLE` and an empty caption. Voice is not started. |
| else `rabble_voice_start(queue) != ESP_OK` | Log error `voice pipeline unavailable`. Mode and caption are **left as they were** (mode stays boot, caption stays `WAKING UP...`). Start-up continues with steps 15 to 18. |
| else (ok) | Set mode `RABBLE_MODE_IDLE` and an empty caption (the button icons show how to talk). |

Clearing the caption means setting it to the empty string; build cleanly under `-Wformat-security`.

Order facts the rest of the system depends on:
- NVS settings are readable from the first board call onwards.
- State and battery are initialised before the UI and the input task, since both read them.
- The input task is running before the voice pipeline, so PTT events have a consumer path (the queue is shared; the voice task is the consumer).
- Wi-Fi and the beam start last, after voice, so the heavy memory users (audio buffers, voice task stack) are allocated first. Do not reorder step 16 before 14 without Mark's call; internal-heap headroom is the reason.
- Heap figures logged at steps 10 and 18 are the quickest regression signal for memory placement.

### 6.4 Setting dispatcher

A function registered as the listener (`rabble_setting_cb_t`, `void (*)(rabble_setting_t what)`). It runs in whichever task changed the setting (UI, console, beam), so each action it takes must be task-safe. It maps:

| `what` | Action |
|---|---|
| `RABBLE_SETTING_VOLUME` | `rabble_audio_set_volume(rabble_settings_volume())` |
| `RABBLE_SETTING_MIC_GAIN` | `rabble_audio_set_mic_gain(rabble_settings_mic_gain())` |
| `RABBLE_SETTING_WIFI` | `rabble_wifi_apply()` |
| `RABBLE_SETTING_BEAM` | `rabble_beam_config_changed()` |
| any other value (`SPEAKER`, `VOICE`, `BRIGHTNESS`, `SLEEP`, `POWER_OFF`, `RAISE`) | No action. These are read at point of use by the modules that care. |

The dispatcher is not called for the initial values at boot; each subsystem reads the stored values itself while starting.

---

## 7. Timings, limits, caps (collected)

| Item | Value |
|---|---|
| Boot task | name `rabble_boot`, 8192-byte stack, priority 5, core `RABBLE_UI_CORE` (in `main/`, fixed) |
| Boot animation wait | 1400 ms |
| Input queue | 16 items of `rabble_input_event_t` |
| `RABBLE_AUDIO_CORE` / `RABBLE_UI_CORE` | 1 / 1 on the S3 (0 / 0 if unicore) |
| `RABBLE_UI_PRIORITY` | 5 (voice task is 6; input task 6; panel send task `RABBLE_UI_PRIORITY + 1`) |
| Button debounce | 3 samples at 10 ms awake poll (30 ms); asleep press bypass: first sample |
| Wait in flight delay | 10 ms |
| LVGL memory | PSRAM first (SPIRAM+8BIT), libc malloc fallback |
| `RABBLE_UI_TEXTURE_BAND` | 16 |

---

## 8. What each file may call

| File | Allowed |
|---|---|
| `rabble_mem.h` | `sdkconfig.h` symbols, `esp_heap_caps.h` constants. Nothing else. |
| `rabble_board.h` | Types from ESP-IDF (`gpio_num_t`, `esp_err_t`, `esp_codec_dev_handle_t`), LVGL (`lv_align_t`, `lv_display_t`, `lv_indev_t`), `<time.h>`, and `rabble_state.h` (`rabble_power_t`). |
| `rabble_board.c` | ESP-IDF `driver/gpio.h` (config, level read, ISR service, handler add, per-pin intr enable/disable, `gpio_wakeup_enable/disable`), `esp_sleep_enable_gpio_wakeup`, `esp_check.h`, FreeRTOS task notification and delay APIs, and one RaBbLE name: `rabble_state_asleep()`. |
| `rabble_lv_mem.c` | `heap_caps_malloc/realloc/free`, libc `malloc/realloc`, LVGL types. No RaBbLE names. |
| `rabble_app.c` | Anything in section 9 (public names only), `esp_log`, `esp_heap_caps`, FreeRTOS queue and task APIs, and the board vtable it was handed. |

---

## 9. External symbols (used outside the defining file) and who uses them

Defined by this group:

| Symbol | Used by |
|---|---|
| `rabble_board` (global) | `accord/rabble_entity.c`, `accord/rabble_ui.c`, `accord/rabble_time.c`, `accord/rabble_motion.c`; `apache/rabble_audio.c`, `rabble_input.c`, `rabble_settings_ui.c` |
| `rabble_app_run` | `main/app_main.c` |
| `rabble_board_get` (declared only) | `main/app_main.c`; defined in `bsp/bsp_waveshare_175b.c` |
| `rabble_board_t` and all members | `bsp/bsp_waveshare_175b.c` (fills it), readers above |
| `rabble_button_hint_t` | `rabble_entity.c`, `rabble_ui.c`, `bsp_waveshare_175b.c` |
| `rabble_display_direct_t` | `rabble_entity.c`, `bsp/rabble_lcd_bands.h` (aliased as `rabble_lcd_direct_t`) |
| `rabble_ui_texture_t`, `RABBLE_UI_TEXTURE_BAND` | `rabble_entity.c`, `bsp/rabble_lcd_bands.c/.h` |
| `RABBLE_BTN_TALK_PRESS/RELEASE`, `RABBLE_BTN_AUX_PRESS/RELEASE` | `rabble_input.c`, `bsp_waveshare_175b.c`; the TALK pair also from `rabble_board.c` |
| `rabble_gpio_button_t`, `rabble_gpio_button_init`, `rabble_gpio_button_init_high`, `rabble_gpio_button_poll`, `rabble_gpio_buttons_wait` | `bsp_waveshare_175b.c` (init, poll) |
| `RABBLE_BIG_CAPS` | `rabble_audio.c`, `rabble_input.c`, `rabble_voice.c`, `accord/rabble_beam_score.c` |
| `RABBLE_LOW_MEM` | `rabble_voice.c` (`#if`) |
| `RABBLE_AUDIO_CORE` | `rabble_voice.c` |
| `RABBLE_UI_CORE` | `main/app_main.c`, `bsp_waveshare_175b.c`, `bsp/rabble_lcd_bands.c/.h` |
| `RABBLE_UI_PRIORITY` | `bsp_waveshare_175b.c`, `bsp/rabble_lcd_bands.c` |
| LVGL hooks listed in section 5 | LVGL itself only |

Count: 29 distinct externally visible names or groups (counting each macro, type, function and global once; the 36 `rabble_board_t` members are counted as one type but are individually binding).

Consumed by this group from elsewhere (public names; other specs own them):

- `rabble_state.h`: `rabble_power_t` (fields `battery_pct` int, `battery_mv` int, `charging` bool, `usb` bool; used in the `read_power` signature), `rabble_state_asleep()`, `rabble_state_init()`, `rabble_state_set_caption()`, `rabble_state_set_mode()`, `RABBLE_MODE_IDLE`.
- `rabble_settings.h`: `rabble_settings_init`, `rabble_settings_set_listener`, `rabble_settings_volume`, `rabble_settings_mic_gain`, `rabble_setting_t` and its enumerators `RABBLE_SETTING_VOLUME`, `_MIC_GAIN`, `_WIFI`, `_BEAM`, `rabble_setting_cb_t`.
- `rabble_audio.h`: `rabble_audio_set_volume(int)`, `rabble_audio_set_mic_gain(int)`.
- `rabble_wifi.h`: `rabble_wifi_start`, `rabble_wifi_apply`.
- `rabble_beam.h`: `rabble_beam_start`, `rabble_beam_config_changed`.
- `rabble_battery.h`: `rabble_battery_init`.
- `rabble_input.h`: `rabble_input_start(QueueHandle_t)`, `rabble_input_event_t`.
- `rabble_voice.h`: `rabble_voice_start(QueueHandle_t)`.
- `rabble_motion.h`: `rabble_motion_start`.
- `rabble_ui.h`: `rabble_ui_start`.

---

## 10. Errors and edge cases

1. `board->init` or settings init failing is fatal; the device reboot-loops visibly in the log. No degraded mode.
2. A board without `audio_init` still runs: no voice, mode set to idle, empty caption.
3. Voice failing leaves the screen on the boot mode and the "WAKING UP..." caption. This is existing behaviour; keep it (it tells the user something is wrong), and log the error line.
4. Motion failing (no IMU, or sensor error) is a warning only.
5. `display_unlock` must be callable on a task that holds the lock; unrelated to this group but note `rabble_ui_start` brackets its LVGL build with `display_lock(-1)` / `display_unlock()`.
6. ISR service double install is tolerated both ways: other code (panel band driver) installs it too and treats "already installed" as success.
7. Button wait: if the pad level changes between the level check and the arm step, level-triggered interrupts fire immediately, so the wait returns at once rather than losing the event.
8. LVGL allocation failing in both heaps returns NULL; LVGL asserts, and the project's assert handler aborts (`accord/rabble_lv_assert.h`).

---

## 11. Behaviour checklist (integrator, on the gadget)

Run after swapping each file in (these files are swapped together as one W0 commit with `rabble_state`).

1. Clean build for the Waveshare 1.75B board with no warnings from these files; `bsp/`, `main/`, `accord/` compile with no source edits.
2. Boot log shows, in this order: `board: Waveshare ESP32-S3-Touch-AMOLED-1.75-B`, board init messages, `UI built: free internal N`, input task start lines, voice start lines, `ready: free heap A internal, B psram`.
3. Boot log heap figures match the pre-swap run within a few percent (record both runs: internal free after UI build and at ready, psram free at ready). A large internal drop means LVGL or a big buffer landed in internal RAM.
4. `heap_caps_get_allocated_size`-style check, or the serial `@status` output: LVGL objects live in PSRAM (e.g. allocating a settings page does not reduce internal free by more than a few KB).
5. The boot animation plays for about 1.4 s before the caption clears; face then shows idle with the button icons visible at the hint positions.
6. Caption "WAKING UP..." appears during boot and clears when voice is up; with voice disabled by force (temporarily fail audio init), the caption stays and `voice pipeline unavailable` is logged.
7. Core and priority facts: task list (`vTaskList` via the console, or the existing diagnostic) shows `rabble_voice` on core 1 prio 6, LVGL task on core 1 prio 5, panel send task on core 1 prio 6; `rabble_boot` ran on core 1 (the panel's SPI interrupt log in `rabble_lcd_bands` must not print `not pinned to core`).
8. Entity gates unchanged: 60 fps idle, at least 30 fps busy and turning (direct mode comes up; `direct_stats` reports).
9. BOOT button (talk): press logs `talk key: press` after ~30 ms, release logs `release`. A quick bounce does not produce a press. Press while the screen is asleep registers at once (wake works on the first press with no repeated taps).
10. PWR button: short press, long press power off, aux behaviour all unchanged (these exercise `poll_buttons` with the PMU key bits; unaffected by this group but a regression sign).
11. Display pause on battery asleep: current drops, BOOT press wakes the device; on USB the pause is not used. (`wait_buttons` is NULL on this board, so the helper's wait path is exercised only by a bench build; see test vehicle.)
12. Settings dispatch: changing volume in the settings tile audibly changes playback volume at once; changing mic gain changes the logged gain; toggling Wi-Fi off/on applies without reboot; editing the beam URL/token reconnects the beam; changing brightness, sleep, speaker, voice, power-off timeout, raise-to-wake changes nothing in the dispatcher (they take effect through their own readers).
13. A full voice turn works with the beam live (PTT, thinking, speaking, back to idle), with no internal-heap exhaustion warnings.
14. Overlap gate (integrator only): under 5% matching substantive lines, every hit judged unavoidable. Expected unavoidable hits: LVGL hook prototypes (fixed by LVGL's header), `ESP_ERROR_CHECK` lines, ESP-IDF call names.

---

## 12. Test vehicle

Implementer scope: vehicles 1 and a host-side unit test of the debounce rules in 4.3 (stubbed `gpio_get_level` and `rabble_state_asleep`) are required. The implementer has no device access; vehicles 2 to 4 are optional and, if written, are run on the gadget by the integrator.

The workspace lacks `rabble_state`, `rabble_settings`, `rabble_wifi` and the rest at W0 time. Suggested vehicles, cheapest first:

1. **Header compile check (host or IDF).** Create stub headers for `rabble_state.h`, `rabble_settings.h`, `rabble_audio.h`, `rabble_wifi.h`, `rabble_beam.h`, `rabble_battery.h`, `rabble_input.h`, `rabble_voice.h` declaring only the public names listed in section 9 (types: `rabble_power_t`, `rabble_mode_t` with the enumerator names, `rabble_setting_t` with the ten enumerators in the order `VOLUME, SPEAKER, VOICE, MIC_GAIN, BRIGHTNESS, SLEEP, POWER_OFF, RAISE, WIFI, BEAM`, `rabble_input_event_t` with `type` and `wake`). Then compile every `accord/*.c`, `nebula_lite` consumers that include board headers, `main/app_main.c`, and a copy of the board table initialiser style used in `bsp/bsp_waveshare_175b.c` (designated initialisers, plus the `{ LV_ALIGN_CENTER, 160, 106 }` positional hint). This proves names, types, order and macro values with no hardware. Add a `static_assert` file asserting the `RABBLE_BTN_*` values, `RABBLE_UI_TEXTURE_BAND == 16`, `RABBLE_UI_PRIORITY == 5`, and `RABBLE_UI_CORE == RABBLE_AUDIO_CORE`.
2. **Minimal ESP-IDF test app** (`cleanroom/w0/test_app/`, target esp32s3, LVGL 9.5.0 as a managed component, `CONFIG_LV_USE_CUSTOM_MALLOC=y`, PSRAM on): links `rabble_lv_mem.c` with `WHOLE_ARCHIVE`, creates a few hundred `lv_label`/`lv_btn` objects and prints internal vs. PSRAM free before and after (PSRAM must drop, internal must barely move); forces PSRAM exhaustion (or temporarily requests a huge block) to confirm the libc fallback path returns without crashing; frees from both origins.
3. **Button helper bench** in the same test app, with two jumper wires on spare pads (one active-low with internal pull-up, one active-high): drive them from a second pad or by hand; a stub `rabble_state_asleep()` returning a settable flag. Verify: 30 ms debounce (bounce injection by toggling quickly yields no event), asleep-press bypass (flag true: first-sample press), `rabble_gpio_buttons_wait` returns on a level change while the CPU is in light sleep (`esp_pm`/auto light-sleep enabled) within a few ms, returns on `xTaskNotifyGive`, returns on timeout, and that a second `init` on another pad logs no "isr service already installed" error.
4. **Start-up order test**: stub every subsystem start function to append its name to a log buffer; call `rabble_app_run` with a fake `rabble_board_t` whose `init` and `audio_init` record calls. Assert the order in section 6.3, the three step-14 branches (NULL `audio_init`, voice start failing, success) and the dispatcher mapping by invoking the listener with each enumerator. Needs ESP-IDF's FreeRTOS (run on target or QEMU for S3) because of queue and delay; running on target is simplest.
