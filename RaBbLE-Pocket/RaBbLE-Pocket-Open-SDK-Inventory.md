# RaBbLE-Pocket: neutral Open SDK inventory

Mechanical, read-only classification of `RaBbLE-Pocket/` (2026-10-28). Nothing in the Pocket repo was edited. The neutral SDK is source-available, never "open source".

Classes: **open** (ships in the neutral Open SDK), **brand** (reserved, excluded), **split** (needs a neutral half and a brand half), **n/a** (not shipped: generated, third-party, local-only, or tooling for the Collective).

## Repo root

| Path | Class | Reason |
|---|---|---|
| `LICENSE` | split | Sovereign Accord text is the licence for brand and Collective material; the Open SDK needs its own neutral licence file, with the Accord kept for reserved parts |
| `README.md` | split | Contains the trademark line (README.md:36); neutral README needed, brand README stays |
| `AGENT.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `CONTEXT.md`, `REFERENCES.md` | n/a | Collective agent orientation (CLAUDE/CODEX/GEMINI are symlinks); not SDK content |
| `.gitignore`, `.git` | n/a | Repo plumbing |
| `companion-app/` (CONTEXT.md only) | n/a | Stub; no code yet. Revisit when the Open companion exists |
| `third_party/` | n/a | Gitignored, someone else's code (Waveshare demo repo, Meta Muse SDK record, flash backups); never redistributed |

## firmware/ (build/ and managed_components/ excluded)

| Path | Class | Reason |
|---|---|---|
| `firmware/NOTICE` | split | Names RaBbLE Collective copyright and Accord; neutral NOTICE needs upstream notices verbatim (Apache-2.0, MIT, BSD-3, zlib, libpng, FTL) with a RaBbLE copyright line above |
| `firmware/CMakeLists.txt`, `dependencies.lock`, `.esp-idf-version`, `partitions.csv`, `sdkconfig`, `sdkconfig.defaults` | open | Build plumbing; check `sdkconfig*` for brand device-name or URL defaults before release |
| `firmware/README.md`, `firmware/CONTEXT.md` | split | Docs mention brand; neutral variants needed |
| `firmware/main/` (app_main.c, Kconfig.projbuild) | split | Boot glue is generic but Kconfig menu is titled "RaBbLE-Pocket Configuration" (Kconfig.projbuild:2) and the app launched is the brand app |
| `firmware/datasheets/` | n/a | Vendor PDFs (Espressif, Waveshare, Everest, X-Powers, QST, NXP); redistribution rights not ours, link instead |
| `firmware/panel_bench/` | open | Standalone display bring-up project (panel_bench.c); `build/` there is generated (n/a) |
| `firmware/test/` (core, audio, power, net, voice, boards, drivers, render, run.sh, paths.sh, KNOWN_FAILURES, README) | open | Host test suite for SDK layers. Exceptions: `test/app/orbit_test` is split (see Orbit), `test/render/sim_test` is split if it asserts brand colours or scene |
| `firmware/test/.out/` | n/a | Generated logs |
| `firmware/drivers/rabble_axp2101`, `rabble_qmi8658`, `rabble_pcf85063` | open | Clean-room chip drivers (NOTICE states last derived files replaced in W6). Rename prefix optional |
| `firmware/boards/rabble_waveshare_175b/` | open | Board layer (BSP, display, frame, bands, texture), clean-room (W6). Waveshare board is public hardware |
| `firmware/sdk/rabble_core/` | split | Everything open except `rabble_palette.h` (brand colours, neutralise) and `rabble_device.c:31` (default name `RaBbLE-Pocket-%02X%02X`); `Kconfig` menu title "RaBbLE gadget" (line 2) |
| `firmware/sdk/rabble_core/rabble_palette.h` | split | DECIDED (Mark, S288): the SDK bakes in a neutral pastel palette of standard colors (semantic roles: bg, surface, border, text, muted, accent1..3, error, ok, warn). The brand palette moves UP into the RaBbLE app as `app/RaBbLE/RaBbLE_palette.h` (Palette.md hexes), overriding the SDK defaults at build time. The Open build ships only the neutral one |
| `firmware/sdk/rabble_render/` (nebula_lite.h, compose, raster, simd, luts, store, orbit) | split | Renderer engine is open. `include/nl_list.h:25-31` hard-codes NL_BG/CYAN/MAGENTA/VIOLET/TEXT/BORDER/WHITE (brand, neutralise via a palette header the app supplies). `src/luts.c` also uses brand colour macros. `src/orbit.c` open but uses brand colour macros and reads `nl_mesh_*` |
| `firmware/sdk/rabble_render/src/orbit.c` mesh coupling | split | `nl_mesh_xy/side/n/edge` (nl_list.h:188-193) are filled by the brand entity; orbit.c:210-213 already falls back when `nl_mesh_n == 0`, so neutral build defines the arrays empty |
| `firmware/sdk/rabble_audio/` (ADPCM, audio) | open | Generic codec/audio path |
| `firmware/sdk/rabble_power/` (battery) | open | Generic |
| `firmware/sdk/rabble_motion/` | open | IMU motion, generic |
| `firmware/sdk/rabble_store/` (notes, capture) | open | Generic LittleFS store; notes console. Check capture strings |
| `firmware/sdk/rabble_lvgl_port/` | open | LVGL memory hook and assert header; thin, own code |
| `firmware/sdk/rabble_net/` (wifi, beam) | split | Wi-Fi stack open. Beam is the sCoRE wire client: `PROTO "rabble-beam/0"` (rabble_beam_score.c:54) and default host `rabble-os.local` are brand/service-bound; neutral SDK ships the transport with a configurable protocol id and an empty URL (Kconfig already defaults empty) |
| `firmware/sdk/rabble_voice/` (voice, outbox) | split | Push-to-talk capture and outbox open; user caption at rabble_voice.c:374 is brand copy |
| `firmware/app/RaBbLE/scene.c`, `nl_scene.h` | brand | Procedural RaBbLE entity scene builder (820 lines); the entity is the reserved brand asset |
| `firmware/app/RaBbLE/rabble_entity.c/.h` | brand | Entity state, expression and mesh orbs (809 lines); feeds `nl_mesh_xy` |
| `firmware/app/RaBbLE/entity_face.c/.h` | brand | Face/orb constants (ENTITY_ORB_WHITE referenced from nl_list.h:31) |
| `firmware/app/RaBbLE/ui_theme.h` | split | Theme values from Palette.md; neutral token header (roles) plus brand value overlay |
| `firmware/app/RaBbLE/rabble_orbit.c/.h`, `rabble_orbit_logic.c/.h` | split | Orbit UI engine, pages and gesture logic are generic and open; uses brand palette macros and the entity mesh. Page text carries no brand strings (checked) |
| `firmware/app/RaBbLE/rabble_ui.c/.h` | split | LVGL screens; wordmark label "RaBbLE" at rabble_ui.c:736 and brand colours |
| `firmware/app/RaBbLE/rabble_app.c/.h`, `rabble_a8.c/.h`, `rabble_setup.c/.h`, `rabble_clock_screen.c/.h`, `rabble_level_screen.c/.h`, `rabble_pomo.c/.h`, `rabble_input.c/.h`, `rabble_shot.c/.h` | split | App shell and applets are functionally generic (clock, level, pomodoro, input, screenshot, setup) but sit in the brand app folder wired to the entity and palette. Plan: move into a neutral `app/` reference app, brand app composes them. rabble_a8 is unknown purpose: confirm |
| `firmware/app/RaBbLE/CMakeLists.txt`, `idf_component.yml` | split | Component named for the brand app |

## ops/

| Path | Class | Reason |
|---|---|---|
| `ops/sdk-layers.py` | open | Layer dependency checker, useful to SDK users |
| `ops/build-flash.sh`, `ops/esp-idf-select.sh` | open | Build/flash helpers; esp-idf-select.sh:84 message points at `RaBbLE-OS-layerctl.sh` (Collective-internal, trim) |
| `ops/arduino-flash.sh` | n/a | Builds Waveshare Arduino examples from `third_party/`; line 98 refers to RaBbLE-OS layerctl |
| `ops/beam-echo.py` | split | Bench stand-in for the sCoRE beam endpoint; protocol-bound (rabble-os.local default, line 14) |
| `ops/pocket-shot.py` | open | Screenshot tool over serial; error string at line 43 mentions RaBbLE (user-visible, see below) |
| `ops/CONTEXT.md` | split | Docs |

## sim/

| Path | Class | Reason |
|---|---|---|
| `sim/host_render.c`, `sim/build.sh`, `sim/xtensa_check.sh` | split | Host render harness; builds `app/RaBbLE/scene.c` (build.sh:10), so it needs a neutral scene to be useful without the brand entity |
| `sim/orbit_scenes.c` | split | Orbit scene renders; sample label "WI-FI RABBLE" (line 137) and entity mesh |
| `sim/transition.c`, `sim/transition.sh` | split | Orbit transition sim, same entity dependency |
| `sim/pocket/` (host shims, lvgl.mk, sim.mk, gen_lv_conf.py, WIP.md) | open | ESP-IDF shim layer and LVGL host build; `sim/pocket/out/` generated (n/a) |
| `sim/out/` | brand | Rendered frames of the entity and brand palette (PNG/PPM/GIF, binaries host_render, orbit_scenes); also generated. Exclude |
| `sim/.gitignore` | open | Plumbing |

## hardware/

| Path | Class | Reason |
|---|---|---|
| `hardware/cad/` (scripts, out, sandbox, RaBbLE-Pocket-*.FCStd, README) | brand | Case, backplate and battery mount CAD (Backplate v4.2 etc.) reserved per your brief. `sandbox/` (Containerfile, cad-sandbox.sh) is generic but only useful with the CAD, leave out |
| `hardware/cad/ref/` | n/a | Waveshare 3D/DWG/DXF reference models, not ours to redistribute; link to Waveshare |
| `hardware/schematics/` | n/a | Waveshare schematic PDF, third-party; link instead |

## tools/

Empty directory. n/a.

## planning/

| Path | Class | Reason |
|---|---|---|
| `planning/decisions/*.md` (7 ADRs: ESP-IDF over Arduino, multiversion/EIM, EIM CLI, backplate battery mount, two-tier sleep, emote rendering stack, IDF v6 gadget stack) | n/a | Collective working records. The ESP-IDF ones could be republished as neutral docs; backplate and emote ones are brand |
| `planning/mock/rabble-pocket-entity.html` | brand | Entity mock with embedded fonts (Chakra, JBM; confirm font licences) |
| `planning/CONTEXT.md` | n/a | Orientation |

Press drafts (Getting Started, IG kit, private site) live in the Grimoire per memory, not under this repo: reserved, not inventoried here.

## Third-party and Muse-derived material

- **Muse-derived code in tree: none found.** `firmware/NOTICE` states the last derived files were replaced in clean-room wave W6; a grep for `muse`, `derived from`, `adapted from`, `SPDX`, `Apache` across app/sdk/boards/drivers/main/test/sim/ops found no Muse attribution headers.
- `third_party/README.md` records `muse-gadget-sdk/` (Meta, Apache-2.0) as deleted S277 and kept as a record only. The directory is not on disk.
- `third_party/ESP32-S3-Touch-AMOLED-1.75/` (Waveshare, Apache-2.0) and `third_party/flash-backups/` (full flash image, contains device data: never ship). Gitignored.
- Managed components fetched at build (not redistributed): ESP-IDF components, Waveshare BSP, esp_websocket_client (Apache-2.0); LVGL, cJSON, joltwallet/littlefs (MIT); bundled littlefs (BSD-3); zlib, libpng, FreeType (FTL), Espressif MIT (per NOTICE).
- Vendor material kept in-repo: `firmware/datasheets/*.pdf`, `hardware/cad/ref/*`, `hardware/schematics/*.pdf`.
- `planning/mock/rabble-pocket-entity.html` embeds base64 fonts "Chakra" and "JBM" (JetBrains Mono presumed): licence not recorded.
- `sim/pocket/host/shim` re-implements ESP-IDF headers (esp_err.h, esp_lcd_*.h, etc.): own code, names only.

## User-visible `RaBbLE|rabble|RABBLE` strings

Code identifiers, TAGs, task names and NVS namespace (`"rabble"`, `rabble_settings.c:17`) are excluded; they may stay.

| file:line | String | Where it shows | Action |
|---|---|---|---|
| `firmware/sdk/rabble_core/rabble_device.c:31` | `"RaBbLE-Pocket-%02X%02X"` | default device/Wi-Fi/mDNS name | make a Kconfig prefix, neutral default |
| `firmware/app/RaBbLE/rabble_ui.c:736` | `"RaBbLE"` | wordmark label on the face screen | brand overlay only |
| `firmware/sdk/rabble_voice/rabble_voice.c:374` | `"NOTE SENT - RaBbLE IS THINKING"` | on-screen caption | neutral caption, brand string in overlay |
| `firmware/sdk/rabble_core/Kconfig:2` | `menu "RaBbLE gadget"` | menuconfig | neutral title |
| `firmware/main/Kconfig.projbuild:2` | `menu "RaBbLE-Pocket Configuration"` | menuconfig | neutral title |
| `firmware/sdk/rabble_net/rabble_beam_score.c:54` | `"rabble-beam/0"` | wire protocol id (visible on the network, not UI) | configurable id; keep brand default out of neutral |
| `firmware/app/RaBbLE/rabble_shot.c:39` | `"...compiled out (CONFIG_RABBLE_SHOT)"` | serial console reply | config symbol name; may keep or rename |
| `ops/pocket-shot.py:43` | `"...not running RaBbLE?"` | CLI error | neutral wording |
| `ops/beam-echo.py:14` | `ws://rabble-os.local:8000/api/v1/beam` (docstring) | tool help | placeholder host |
| `ops/esp-idf-select.sh:84`, `ops/arduino-flash.sh:98` | `bash RaBbLE-OS-layerctl.sh apply ...` | script error hints | drop or generalise |
| `sim/orbit_scenes.c:137` | `"WI-FI RABBLE"` | sim sample label | change sample |

Checked with no brand string: Orbit page text in `rabble_orbit_logic.c` (e.g. line 799 "Wi-Fi ..."), console `@mode` / `@shot` replies other than the one above, boot task in `main/app_main.c`. Mode and enum names such as `RABBLE_MODE_*` are identifiers. The `>beam.url` console help in Kconfig is neutral. Not checked: strings built from macros or defined in `sdkconfig*`, and any header-only string tables (grep covered .c/.h literals containing the words).

## Summary of counts

Counted by table rows (a row may cover a directory).

- open: 17 (build plumbing, panel_bench, host tests, three chip drivers, board layer, audio, power, motion, store, lvgl_port, sdk-layers.py, build-flash.sh, esp-idf-select.sh, pocket-shot.py, sim/pocket shim)
- split: 26 (LICENSE, README, NOTICE, firmware docs, main, rabble_core, palette, render, orbit mesh coupling, net, voice, ui_theme, Orbit UI, rabble_ui, app shell/applets, app CMake, beam-echo, ops docs, sim harness x3, test/app/orbit_test, test/render/sim_test)
- brand: 6 (scene.c, rabble_entity, entity_face, hardware/cad, sim/out, planning/mock entity)
- n/a: 14 (agent docs, companion-app stub, third_party, datasheets, generated outputs, arduino-flash.sh, cad ref, schematics, tools/, ADRs, planning CONTEXT, build dirs)

## Open questions

1. What is `rabble_a8.c/.h`? Name gives no hint; classify after reading.
2. Do `test/app/orbit_test` and `test/render/sim_test` assert brand colours or the entity scene? Not inspected.
3. RESOLVED (Mark, S288): neutral pastel palette of standard colors baked into the SDK; brand palette lives in `app/RaBbLE/RaBbLE_palette.h` above the SDK. Clock, level and pomodoro are neutral and ship in the Open app. Still to do: pick the exact standard-color set and role names (propose in the S10a/Open-app step, for Mark's glance)
4. Beam: does the Open SDK ship the sCoRE-protocol client at all, or only a generic WebSocket voice transport?
5. Licence for the neutral SDK (permissive vs source-available under a separate file) and who holds copyright lines above upstream notices.
6. Font licences for the planning mock; whether any ADRs are republished neutrally.
7. `sdkconfig` / `sdkconfig.defaults` may carry brand defaults (not grepped in detail).
8. Is the `RABBLE_*` / `rabble_` identifier prefix acceptable in the neutral SDK given the RABBLE name filed by others in class 9 (per memory)? Identifiers are allowed by your brief, but a rename pass may be wanted before publication.
