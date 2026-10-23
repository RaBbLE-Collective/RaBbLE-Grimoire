# RaBbLE-Pocket — SDK Plan: from `rabble_gadget` to app / SDK / boards

```
spark ~ pocket/sdk >> the gadget firmware splits into an app, a board-agnostic SDK and one folder per board // %S271_SDK%
```

> **Document type:** Grimoire plan · `RaBbLE-Pocket/`
> **Status:** v0.2 (S271). Layering approved by Mark in S267; component plan Opus-reviewed at link level (S271, `nm` over every component archive) and amended: §3a lists what the review found. S0 done (`7fc004f`); S1 in progress.
> **Purpose:** The step-by-step plan to reorganise `RaBbLE-Pocket/firmware` into the RaBbLE-SDK on the Sovereign Accord, so that a new round ESP32-S3 board is just a new folder and RaBbLE is one app on it.
> **Sources:** `log/handoffs/done/HANDOFF-S267-Pocket-CleanRoom-Final-SDK.md` §3 (Mark's decisions, layering, first sketch), `HANDOFF-S270-Pocket-W6-Respec.md`, `RaBbLE-Pocket-Clean-Room-Plan.md`, the S271 include graph of `accord/` (below).

---

## 1. Decisions already made (S267, Mark)

1. **The SDK is RaBbLE-Pocket**: no new member. It targets round ESP32-S3 boards: Waveshare 1.75B now, 1.75C planned, other targets later.
2. **Licensing:** Sovereign Accord, or permissive code isolated in its own component with its LICENSE + NOTICE (RaBbLE copyright above the upstream notice, kept verbatim). Never copyleft.
3. **Three layers, each depending only downward:** `app/` → `sdk/` → `boards/<board>/`. RaBbLE-Pocket is a *class of gadget*; RaBbLE is the app on it.
4. **Clean-room note:** names come from our own include graph and this plan, never from the Muse gadget SDK's tree. `third_party/muse-gadget-sdk/` and the contents of `bsp/` stay out of every SDK session's reading (moving `bsp/` with `git mv` doesn't need reading it).

**Two placement tests:** (1) a new board is only a new `boards/<name>/` folder, no SDK edits; (2) a minimal second app (board bring-up test) builds on the SDK without editing SDK code.

---

## 2. Why the SDK can start before W6 lands

W6 replaces **only the board layer** (`firmware/bsp/`, tainted: Meta/Apache-derived) behind the seam `accord/rabble_board.h`. Everything in `accord/` is RaBbLE's own or already clean-roomed (W0–W5). So:

- SDK steps S0–S10 (below) touch `accord/`, `nebula_lite/` and `main/`, **not `bsp/` contents**. W6 can be re-spec'd and re-implemented in parallel.
- The seam header moves into `rabble_core` in S1 with **the same name and contents**, so the W6 spec is unaffected; its workspace recipe just names the new path.
- Only **W7** (deleting `third_party/muse-gadget-sdk/`, the Apache close-out) waits for W6's overlap gate.
- **S11** (moving `bsp/` to `boards/waveshare_175b/`) happens when W6's clean board layer lands, so the move carries clean code and the parked `w6-integration-wip` branch isn't rebased across a rename.

---

## 3. Today (S271 include graph, `components/rabble_gadget/accord/`, 69 files, 18,027 lines)

One component, `rabble_gadget`, holds everything. Module → RaBbLE modules it includes (`_priv` folded in):

| Module | Lines | Includes |
|---|---|---|
| `rabble_mem` `rabble_text` `rabble_settings` `rabble_console` `rabble_palette` `rabble_a8` `rabble_adpcm` `rabble_capture` `rabble_notes` `rabble_wifi_air` `rabble_wifi_known` `rabble_lv_assert` `rabble_lv_mem` | leaves | — |
| `rabble_state` | 353 | text |
| `rabble_board` (the seam) | 273 | state (+ `lvgl.h`, `esp_codec_dev.h`, `driver/gpio.h` publicly) |
| `rabble_time` | 300 | board |
| `rabble_battery` | 802 | mem, state |
| `rabble_audio` | 627 | board, mem, settings |
| `rabble_wifi` / `_radio` | 1,145 | settings, state, wifi_air, wifi_known |
| `rabble_beam` | 218 | settings, wifi |
| `rabble_beam_score` | 1,071 | audio, beam, mem, settings, state, time, wifi, **capture, notes, setup** |
| `rabble_beam_text` | 313 | state, text |
| `rabble_notes_console` | 223 | notes |
| `rabble_outbox` | 663 | adpcm, notes, time |
| `rabble_voice` | 979 | adpcm, audio, beam, mem, outbox, settings, state, wifi, **input** |
| `rabble_motion` | 661 | board, settings, state, **input, voice** |
| `rabble_pomo` | 357 | state, **input, voice** |
| `rabble_setup` | 387 | beam, settings, state, voice, wifi |
| `entity_face` `ui_theme` | 152 | palette |
| `rabble_clock_screen` | 301 | board, time, ui_theme |
| `rabble_level_screen` | 293 | motion, state, ui_theme |
| `rabble_entity` | 841 | a8, board, mem, palette, state, motion, **beam, capture, notes, orbit, pomo, wifi** |
| `rabble_orbit` | 745 | a8, mem, orbit_logic, palette, **entity, ui** |
| `rabble_orbit_logic` | 2,641 | palette, settings, state, **beam, input, pomo, ui, wifi** |
| `rabble_ui` | 969 | nearly everything (beam, board, capture, clock, entity, level, motion, notes, orbit, pomo, settings, state, time, wifi, …) |
| `rabble_input` | 840 | 18 modules: the app's router |
| `rabble_app` | 118 | 14 modules: assembly |

Elsewhere: `nebula_lite` (renderer **and** the entity scene `scene.c`), chip drivers `rabble_axp2101`, `rabble_qmi8658`, `rabble_pcf85063` (own components; only `bsp/` uses them), `bsp/` (board, includes only `rabble_board.h` and `rabble_mem.h` from accord), `main/app_main.c` (includes `rabble_board.h`, `rabble_mem.h`).

**Upward calls to cut** (bold above), measured S271. Most are one to five call sites:

| From → to | Call sites | Cut by |
|---|---|---|
| motion → input, voice | `rabble_input_wake` ×2, `rabble_voice_request_chirp` ×1 | motion **events** (`on_wake`, `on_chirp`) registered by the app |
| pomo → input, voice | same two calls | pomo is an applet (app), so this is fine once pomo is in `app/` |
| voice → input | no calls: a **type** — voice's queue carries `rabble_input_event_t` from the app's `rabble_input.h` | move the push-to-talk event type into `rabble_voice.h` (or core) |
| beam_score → setup | `setup_device_name` ×2 | device name moves to `rabble_settings` (core). (beam_score → notes/capture is *downward*: store ranks below net, so no sink is needed) |
| entity → beam, wifi, notes, capture, pomo, orbit | status reads (`wifi_status`, `notes_count`/`busy`, `capture_on`, `pomo_view`), orbit frame/roll | entity reads one **status snapshot** from `rabble_state` (beam/wifi/notes already publish there or can), pomo arc comes in as plain inputs; entity is app anyway |
| orbit ↔ ui ↔ entity (cycle) | `rabble_ui_dark`, `rabble_entity_ui_roll` from orbit; ui/entity call `orbit_frame/touch/tick/close/showing` | orbit **engine** takes `ui_roll` and "dark" as inputs per frame; the app (ui/entity) drives it. Cycle gone |
| orbit_logic → beam, wifi, pomo, input, ui | wifi scan/join, pomo view/minutes, ui preview brightness | split the **engine** (gestures, dial, value mode, hold, drawing data) from the **pages/items table**; pages are app and may call anything below |

**Found by the S271 Opus review (link level, not visible to includes):**
- **The seam global lives in the app.** `const rabble_board_t *rabble_board` is *defined* in `rabble_app.c` and used by core (`time`), SDK (`audio`, `motion`) and app modules; `rabble_app_run()` is declared in the seam header. S1 moves the definition into core and the `rabble_app_run` declaration into an app header.
- **net → app through duplicate prototypes.** `rabble_beam_score.c` calls `rabble_beam_tail_words`, `rabble_beam_caption_at`, `rabble_beam_console`, defined in `rabble_beam_text.c` (homed in app) and re-declared in net headers. `rabble_beam_text` is the beam's text/console protocol: it goes to **net** in S4, duplicate prototypes dropped.
- **`nebula_lite/src/scene.c` owns renderer storage** (`nl_prims`, `nl_n_prims`, `nl_spr`, `nl_push()`, `nl_roll`, `nl_grad`, `nl_clip`), used by compose/raster/orbit. S7 is a **split**, not a move: store + `nl_push` to `rabble_render`, only the entity scene builder to the app.
- **Why the build never complains:** ESP-IDF links with `--start-group`, and `WHOLE_ARCHIVE` hides more, so upward references link fine. The layer gate therefore needs a **symbol check** (`nm` the component archives), not only an include scan; `ops/sdk-layers.py --symbols` (S1).
- **Host tests hard-code `components/rabble_gadget/accord`** (26 scripts/sources, some `#include` `.c` files by relative path). S1 adds one shared path helper under `firmware/test/` so every later step only updates one file, and compile checks keep covering every RaBbLE source.
- **Kconfig and the LVGL port belong in the SDK:** `rabble_settings.c` uses `CONFIG_RABBLE_*` from `rabble_gadget/Kconfig`; the assert hook and `rabble_lv_mem.c` would otherwise become app-owned. S1 moves Kconfig into core and both LVGL pieces into a small `sdk/rabble_lvgl_port` (`WHOLE_ARCHIVE`), so core needs none.
- **Debt to keep in view:** core `rabble_settings` carries the app/net schema (beam URL/token, voice, Wi-Fi, raise-to-wake). Fine for now; a settings registry comes when a second app needs different keys.

**Hidden coupling:** `rabble_gadget/CMakeLists.txt` adds `accord/` as a PUBLIC include dir on LVGL's target (for `rabble_lv_assert.h`), so every component linking LVGL sees every accord header and missing `REQUIRES` stay invisible. S0 fixes this first.

---

## 4. Target layout

```
firmware/
  main/                         app_main.c: picks the app, starts it
  app/                          (ESP-IDF component dir, via EXTRA_COMPONENT_DIRS)
    rabble_app/                 RaBbLE: app.c, input (router), setup, beam_text, entity + entity_face,
                                the entity scene (from nebula_lite/scene.c), ui wiring, Orbit pages
                                and items, applets/pomo, console commands
  sdk/
    rabble_core/                board seam (rabble_board.h), mem, state, text, settings, console,
                                palette, time, lv_assert (own include dir), lv_mem (WHOLE_ARCHIVE)
    rabble_power/               battery
    rabble_motion/              motion (+ events)
    rabble_audio/               audio, adpcm
    rabble_net/                 wifi, wifi_air, wifi_known, wifi_radio, beam, beam_score (+ note sink)
    rabble_store/               notes, notes_console, capture
    rabble_voice/               voice turns, outbox (needs audio, net, store)
    rabble_render/              nebula_lite renderer: raster, compose, luts, simd, orbit drawing
    rabble_ui/                  ui texture plumbing, a8, ui_theme, clock + level screens,
                                the Orbit engine (orbit.c controller + orbit_logic engine half)
  boards/
    waveshare_175b/             today's bsp/ (after W6: the clean board layer)
    drivers/                    rabble_axp2101, rabble_qmi8658, rabble_pcf85063
  third_party/<name>/           only if ever needed, own LICENSE + NOTICE
```

Dependency rule (enforced by `ops/sdk-layers.py`, S0): `app → sdk → core`, `boards → core + drivers`; inside `sdk/`: core ← power, audio, store, motion ← net ← voice; render ← ui. Nothing in `sdk/` names a chip or includes an `app/` header.

**Portability debt (flag, don't fix yet):** 466 px is compiled in (`NL_W`/`NL_H`), Orbit coordinates are fixed (`ORBIT_C` 233, chip y 324, radii). When a second panel size exists, the board reports geometry through the seam and the SDK derives from it.

---

## 5. Steps (one component per commit; the gadget builds and flashes after every step)

| Step | Work | Gate |
|---|---|---|
| **S0** | `ops/sdk-layers.py`: a layer table (module → layer) + include scan that fails on any upward include; starts in **report mode** (prints today's violations) and switches to **enforce** per component as each is extracted. Move `rabble_lv_assert.h` to its own include dir and point LVGL's PUBLIC include there only. | firmware builds; checker prints the §3 violations; no behaviour change |
| **S1** | `sdk/rabble_core` (board seam, mem, state, text, settings, console, palette, time) + `sdk/rabble_lvgl_port` (assert hook, lv_mem, `WHOLE_ARCHIVE`). Seam global defined in core; `rabble_app_run` to an app header; Kconfig into core; core `idf_component.yml` with lvgl + esp_codec_dev public; `bsp/` and `main` REQUIRE `rabble_core`. Checker scans the whole tree + `--symbols`. Shared host-test path helper. | build; `sdk-layers.py --enforce core --symbols` exits 0; every host test as green as before (counts recorded); flash: boot, face 60 fps, Orbit, one voice turn |
| **S2** | `sdk/rabble_power` (battery) | same |
| **S3** | `sdk/rabble_audio` (audio, adpcm), `sdk/rabble_store` (notes, notes_console, capture) | same |
| **S4** | `sdk/rabble_net`: wifi\*, beam, beam_score, **beam_text**. Cut beam_score → setup (device name into settings); drop the duplicate beam_text prototypes. | same + Capture round trip and an outbox note delivered |
| **S5** | `sdk/rabble_motion` with events; cut → input/voice | same + wake on lift, spin face |
| **S6** | `sdk/rabble_voice` (voice, outbox); the PTT event type moves out of `rabble_input.h` | same + PTT turn, offline note → online |
| **S7** | `sdk/rabble_render`: nebula_lite renderer **plus the primitive/sprite store split out of `scene.c`** (`nl_prims`, `nl_spr`, `nl_push`, …); the entity scene builder moves to the app. `sim/` builds against both. | same + sim scenes byte-identical to before |
| **S8** | Orbit split: engine (orbit.c, gesture/dial/value/hold half of orbit_logic) → `sdk/rabble_ui`; pages/items table → app. Cut the orbit ↔ ui ↔ entity cycle. **Largest step: Opus implementer, spec first.** | same + the 875 orbit checks, Orbit hand check (pages, value mode, chip, back swipe, Applets) |
| **S9** | `sdk/rabble_ui` rest: a8, theme, clock/level screens, and the texture plumbing **split out of the app's `rabble_ui.c`** (a file split, not a move) | same |
| **S10** | What's left of `rabble_gadget` becomes `app/rabble_app`. Second app: `app/board_test` (panel, touch, IMU, PMU, audio loopback) builds with **no SDK edits**. | placement test (2) passes |
| **S11** | After W6 lands clean: `git mv bsp boards/waveshare_175b`, chip drivers to `boards/drivers/`, make the existing `RABBLE_BOARD` Kconfig choice (`main/Kconfig.projbuild`) select the board folder | placement test (1) shape ready for 1.75C |
| **W7** | Clean-room close-out (S267 handoff §2): delete Muse SDK, Apache files, header sweep of every tracked file | W7 gates |

S0–S2 are mechanical (one session, Sonnet is fine). S3–S7 are mechanical with small API cuts (Sonnet, one step each, sequential: they touch shared CMake). S8 gets its own written spec and an Opus implementer.

---

## 6. Rules for every step

- Behaviour identical; any change is a separate commit with its own reason.
- `REQUIRES` honest: no PUBLIC include of a whole source dir, no reach-through via LVGL.
- Every new/moved file keeps or gets line 1 `/* Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord. */`.
- Internal RAM: measure free internal heap after boot before/after each step (14.7 KB today); a step that loses more than 512 B explains why.
- `.bss` creep breaks beam task creation (S267): check beam connects after every flash.
- No reading `bsp/` contents or `third_party/muse-gadget-sdk/` in SDK sessions.
- Commit per step on `new-horizons`; Pulse Protocol `harmonize ~ pocket/sdk >> …`.

---

## 7. Open questions for Mark

| # | Question | Suggestion |
|---|---|---|
| Q1 | Directory names `app/ sdk/ boards/` under `firmware/`, or one flat `components/` with prefixes? | Three dirs: the layers are visible in the tree |
| Q2 | Is `rabble_palette.h` SDK (default theme) or app (RaBbLE's brand)? | SDK default theme, app may override: the Orbit engine needs colours |
| Q3 | Clock and level screens: SDK or app? | SDK (generic, a board-test app can use them) |
| Q4 | Pomodoro: app applet (as here) or an SDK "applets" service? | App for now; an applet API comes when a second applet exists |

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-10-23 | S271: first component plan from the S271 include graph; W6-parallel reasoning; steps S0–S11 with gates. |
| v0.2 | 2026-10-23 | S271 Opus review (link level): seam global in the app, beam_text → net, scene.c split, symbol-level gate, host-test path helper, Kconfig + LVGL port into the SDK, voice→input is a type; S1/S4/S6/S7/S9/S11 amended. |
