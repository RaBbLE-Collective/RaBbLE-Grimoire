# RaBbLE-Pocket vs Muse Gadget SDK: provenance audit

Run date: 2026-11-02 (CrumBbLE). Verdict on the measurement itself: %HOLDS% (reproducible; scripts + exports kept in this dir).

- SDK: https://github.com/facebookincubator/muse-gadget-sdk.git
  - Measured against **b139b45064b4dcecf7bfe97e75bc7f99c10c28b6**, 2026-10-05 16:27:40 -0700, 51 commits reachable (`git log --oneline | wc -l`).
  - Upstream HEAD at clone: **1b894f551e64416e2844452ec6056ec56d6a10f1**, 2026-10-30 11:33:06 -0700, 168 commits.
  - Port base: Gadget-Port.md:10 and Muse-SDK-Map.md:23 both record `b139b45` (2026-10-05) as the upstream commit. Pocket's port commit is 42ae6d9 (2026-10-06 "RaBbLE gadget: SDK hardware layer ported"); b139b45 is the newest SDK commit before it (parent 6c33c12, 2026-10-03). Upstream had no record besides the Grimoire docs; the code carries no SHA by design.
- Pocket: HEAD 0d3d438a6c8339b4d4fad0e6e01149e73e0481cd (2026-10-29). Historical: 42ae6d9 (apache/ first added, 2026-10-06); 2965c394f23edd67e4fa212b5a8d2cf39eae8a38 (= 6c3b78b^, 2026-10-24, just before W6 rev 2).
- Metric: UNCHANGED. `scripts/cleanroom-overlap.py` is the verbatim copy of `984c554^:ops/cleanroom-overlap.py`; `measure.py` and the others `importlib` its `substantive()` and `sdk_lines()` (substantive = whitespace-normalised, >12 chars, not `#include`, not comment/brace-only; comments stripped; match = line occurs verbatim in any .c/.h/.cc/.cpp/.hpp under SDK `esp32/`, excluding build*, avatar, managed_components). Only change: SDK path passed as an argument. SDK ref set = whole esp32/ tree (252 C/C++ files).
- Scope of HEAD export: `git archive HEAD firmware`; skipped test/ (incl. test/cleanroom), datasheets, managed_components, build. The board layer is now `firmware/boards/rabble_waveshare_175b` (was `bsp/`), plus `firmware/drivers/*`, `firmware/sdk/*`, `firmware/app/RaBbLE`; `components/` no longer exists at HEAD.

## Headline numbers

| tree | scope | substantive | matched | % |
|---|---|---|---|---|
| HEAD | whole firmware | 13,609 | 1,089 | **8.0** (9.0 vs upstream-HEAD SDK) |
| HEAD | boards/ (was bsp/) | 984 | 103 | 10.5 (equals the W6 figure in the log) |
| HEAD | drivers/ | 303 | 67 | 22.1 (axp2101 22.9, pcf85063 15.9, qmi8658 26.5) |
| HEAD | sdk/ | 6,846 | 667 | 9.7 (rabble_net 13.7, power 11.8, store 11.7, motion 11.7, core 10.8, audio 9.5, voice 9.4, render 1.4) |
| HEAD | app/RaBbLE | 5,300 | 246 | 4.6 |
| HEAD | panel_bench | 170 | 5 | 2.9 |
| 42ae6d9 | whole firmware (OG-derived) | 5,669 | 3,367 | **59.4** (58.6 vs upstream HEAD) |
| 42ae6d9 | components/rabble_gadget (apache/ + accord/) | 5,235 | 3,094 | 59.1 |
| 42ae6d9 | bsp/ | 230 | 164 | 71.3 |
| 42ae6d9 | rabble_axp2101 | 130 | 97 | 74.6 |
| 6c3b78b^ | whole firmware | 13,418 | 1,071 | 8.0 (bsp 11.4, components 7.4) |

- 68 of 106 HEAD files exceed 5%, but most are tiny (headers of 2 to 20 substantive lines). Files over 5% with at least 100 substantive lines: see table A.
- Generic-idiom discount: of the 1,089 matched HEAD lines, 611 also occur verbatim in ESP-IDF v6.0.1 components + the managed components (`scripts/generic.py`); residual 478 = 3.5% of HEAD substantive lines. Highest residual: rabble_battery.h 45%, rabble_console.c 36%, rabble_board.h 30%, rabble_lv_mem.c 26%.
- Distinctive tokens at HEAD (step 5): zero hits for `muse_`/`MUSE_`/`meta`/`Jollybot`/`coucou`/`hatch`/`muse` in firmware (outside managed_components/build/datasheets), test/ included. Sanity: 2,954 `muse_` hits in the SDK, so the grep works.
- Shared SDK-defined symbols at HEAD (ctags 6.2.1 over SDK esp32/: 4,938 symbols; 461 appear as identifiers in HEAD; 142 remain after subtracting identifiers in ESP-IDF v6.0.1/components and Pocket's managed_components). List in `shared-nonthird.txt`. Most are generic (`s_queue`, `POLL_MS`, `on_event`-style statics). The structural ones, SDK file noted:
  - Board vtable field names in `firmware/sdk/rabble_core/rabble_board.h`, used in `bsp_waveshare_175b.c`, `rabble_ui.c`, `rabble_input.c`: `audio_init`, `aux_button`, `talk_button`, `display_lock`, `display_unlock`, `display_start`, `display_pause`, `panel_sleep`, `poll_buttons`, `wait_buttons`, `read_power`, `power_off`, `set_mic_gain`/`mic_slot`; the same names are in SDK `components/muse/boards/board_*.c`.
  - `REG_STATUS1`, `REG_VBAT_H/L`, `REG_COMMON_CFG` in `rabble_axp2101.c` (SDK `muse_pmu.c`; register names, datasheet-derived data).
  - `load_str`, `load_u8` (rabble_settings.c; SDK `muse_settings.c`), `copy_str` (SDK `muse_account_api.c`), `text_append` (rabble_orbit_logic.c; SDK `muse_chat_link.c`), `wifi_state_name` (rabble_setup.c; SDK `muse_ble.c`), `update_power` (rabble_input.c; SDK `muse_input.c`/`muse_ui.c`), `on_any_press` (rabble_ui.c; SDK `muse_ui.c`), `clampf` (SDK `avatar/muse_pixel.c`), `update_sleep`/`apply_brightness`/`s_preview_brightness`/`s_dark` (rabble_ui.c).
  - `psram_alloc`, `json_alloc` (rabble_beam_score.c): both defined in SDK `components/muse/muse_chat_session.cpp` (a .cpp; my first grep covered .c/.h only). The same file's `static void *psram_alloc(size_t n)` line is among the matches.

## Own-from-the-start modules (step 3c), flags above 5% at first-add or HEAD

First-add measured with `git show <first-add>:<path>`; first-add path derived with `git log --all --reverse --diff-filter=A --name-only` (table C below). Flagged (>5% at either point):

| module | first-add % | HEAD % | note |
|---|---|---|---|
| rabble_beam_score.c | 19.4 (89/458) at 42ae6d9 | 15.4 (94/610) | sample matches: `#define EV_TEXT 72`, `psram_alloc`, `strlcpy(ev.text,...)`, cJSON_Delete, `if (!grown) {` |
| rabble_ui.c | 17.7 (70/396) at 42ae6d9 | 12.3 (66/538) | Grimoire PROVENANCE records 13.9/12.3 accepted baseline; sample: `static lv_obj_t *s_face;`, `s_preview_brightness`, `update_sleep`, `apply_brightness` |
| rabble_notes.c | 15.5 | 15.4 | `static SemaphoreHandle_t s_lock;`, ESP_OK/ESP_ERR returns, `if (!grown) {` |
| rabble_outbox.c | 14.2 | 14.2 | |
| rabble_time.c | 13.9 | 13.6 | |
| rabble_motion.c | 12.3 | 12.0 | .h 0 -> 7.7 |
| rabble_qmi8658.c/.h | 31.6 / 33.3 | 26.2 / 28.6 | 38-line file at first-add; mostly `i2c_device_config_t cfg = {`, ESP_RETURN_ON_ERROR add_device, `return ESP_OK;` |
| rabble_pcf85063.c/.h | 14.8 / 20.0 | 14.8 / 20.0 | unchanged since 12f7799 (2026-08-08, two months before the SDK study) |
| main/app_main.c | 13.4 (13/97) at 12f7799 | 16.7 (1/6) | HEAD file is 6 substantive lines; 1 match |
| entity_face.h | 15.8 | 14.3 | 3 lines; .c is 0% |
| rabble_clock_screen.h | 40.0 | 40.0 | 5 substantive lines, 2 match; .c 3.1% (42ae6d9, via rename from screen_settings.c 12f7799) / 2.8% HEAD |
| rabble_capture.c | 16.7 | 14.3 | 4 of 24/28 lines |
| rabble_pomo.c/.h | 7.8 / 8.8 | 7.8 / 8.8 | |
| rabble_notes_console.c | 4.4 | 5.6 | crossed 5% since first add |
| rabble_outbox.h | 5.3 | 5.3 | 1 of 19 |
| nebula_lite.h | 10.5 (2/19) | 7.2 (7/97) | .c files all <=1% |
| rabble_entity.c | 5.0 (13/259) | 3.2 | borderline at first add |
| rabble_level_screen.c | 4.4 | 4.4 | below |
| panel_bench.c | 3.0 | 2.9 | below (CO5300 init values per PROVENANCE) |

Early copy-then-rewrite: none found for these modules by this metric. rabble_ui.c, rabble_beam_score.c, rabble_motion.c, rabble_qmi8658.c were already 12 to 32% at their FIRST commit and have not dropped below 5% since; i.e. they never had a rewrite pass, and their overlap is flat or slightly lower. Only rabble_ui.c and rabble_beam_score.c fell noticeably (about 5 points) through growth of new code. The window check (step 4) is the second signal.

## Surprises

1. Whole-firmware overlap at HEAD (8.0%) is identical at 6c3b78b^ (8.0%): the W6 rev 2 commit moved bsp only; nothing else changed that figure.
2. Against the newer upstream-HEAD SDK, HEAD scores 9.0% (+1.0 point): more SDK code means more coincidental verbatim lines; pin the SDK SHA when comparing.
3. Board-ops struct field names (`rabble_board.h`, 43.5% of 69 lines) are the most structural overlap that survives: the vtable shape of the original port is still the vtable. 30 lines matched, 9 of them also generic.
4. The "RaBbLE's own from the start" set is not near zero: several were 12 to 20% when first added. Their matches are dominated by idioms (cJSON/NVS/FreeRTOS/i2c boilerplate, `ESP_OK` returns) per sampled lines, but that is a sample (about 9 lines per file), not a classification of all matches.
5. `main/app_main.c` was 97 substantive lines at 12f7799 (13.4%), HEAD it is a 6-line file.
6. `sdk/rabble_lvgl_port/rabble_lv_mem.c` 57.9% (11/19), `rabble_lv_assert`-style LVGL hook glue; 6 of 11 also in third-party code.

## Caveats of the metric

- Verbatim, whitespace-normalised single lines; lines >12 chars. Duplicates count each time they occur in Pocket; the SDK side is a set. Common lines (`return ESP_OK;`, `if (err != ESP_OK) {`, `static void *`) are counted. 611 of 1,089 HEAD matches also appear in ESP-IDF/managed code (generic discount computed above; ESP-IDF v6.0.1 and managed_components are the ones at ~/esp/esp-idf-eim and ~/RaBbLE-Cleanroom/pocket, versions could differ from the SDK's IDF).
- Whole-tree SDK reference includes other boards (Cardputer, SenseCap, M5Stick) and tests, and linux/ is excluded (esp32/ only).
- Renamed identifiers evade the exact metric. Step 4 windows: 5 consecutive substantive lines, every non-keyword identifier -> `ID` (keywords and stdint types kept; numbers kept, but hex like `0x0a0010` collapses to `0ID`, an artefact that makes colour tables and `#define X 0x..` lines look alike: rabble_palette.h 100%). It over-matches generic declarations: header files with stereotyped signatures (`ID ID ( ID ) ;`). Total 2.3% (300/13,196 windows). Files over 5% in table 4: mostly headers; .c files: rabble_app.c 17.8, rabble_axp2101.c 16.7, bsp_waveshare_175b.c 14.9, rabble_beam.c 12.7, rabble_qmi8658.c 8.8, bsp_display.c 5.1. A lower window total than line total means most line matches are single scattered lines, not copied blocks.
- Tree layout moved (components/ -> sdk, drivers, boards, app); first-add comparison maps by basename, so a moved file keeps its identity (renames detected by `git log --diff-filter=A` only where git sees them; rabble_clock_screen.c was found via `--follow`).
- Datasheet-derived data (register maps, CO5300 init tables, I2C addresses) match by necessity; not discounted.
- Not examined: companion-app, sim, ops, hardware, binaries/assets; test/cleanroom excluded as instructed; SDK linux/ tree.

## Reproduce

```
D=~/RaBbLE-Cleanroom/provenance-audit-2026-11-02; P=~/RaBbLE-Collective/RaBbLE-Pocket
git clone https://github.com/facebookincubator/muse-gadget-sdk.git $D/sdk && git -C $D/sdk checkout b139b45
git -C $P show 984c554^:ops/cleanroom-overlap.py > $D/scripts/cleanroom-overlap.py
for c in HEAD 42ae6d9 2965c394f23edd67e4fa212b5a8d2cf39eae8a38; do mkdir -p $D/trees/${c:0:7}; git -C $P archive $c firmware | tar -x -C $D/trees/${c:0:7}; done
python3 -I $D/scripts/measure.py $D/sdk/esp32 $D/trees/HEAD/firmware show > out-HEAD.txt   # also 42ae6d9, 2965c39
python3 -I $D/scripts/firstadd.py $D/sdk/esp32 $P $D/trees/HEAD/firmware > own-modules.tsv
python3 -I $D/scripts/one.py $D/sdk/esp32 $P 42ae6d9:firmware/components/rabble_gadget/accord/rabble_clock_screen.c
python3 -I $D/scripts/windows.py $D/sdk/esp32 $D/trees/HEAD/firmware > windows.txt
python3 -I $D/scripts/generic.py $D/sdk/esp32 $D/trees/HEAD/firmware ~/esp/esp-idf-eim/v6.0.1/esp-idf/components ~/RaBbLE-Cleanroom/pocket/firmware/managed_components
ctags -R -x --c-kinds=fdgstuvpe --languages=C,C++ -f - $D/sdk/esp32 | awk '{print $1}' | sort -u > sdk-symbols.txt  # then comm vs identifiers
```
Files here: out-*.txt (per-file + matched lines for files >5%), own-modules.tsv, windows.txt, sdk-symbols.txt, shared-all.txt, shared-nonthird.txt, tables.md.

---
## Full tables
### A. HEAD (0d3d438, 2026-10-29): per-file, over 5%  (file | lines | substantive | matched | %)

| file | lines | subst | matched | % |
|---|---|---|---|---|
| boards/rabble_waveshare_175b/bsp_perf.h | 19 | 3 | 2 | 66.7 |
| sdk/rabble_core/rabble_device.h | 13 | 3 | 2 | 66.7 |
| sdk/rabble_audio/rabble_adpcm.h | 28 | 8 | 5 | 62.5 |
| sdk/rabble_power/rabble_battery.h | 60 | 22 | 13 | 59.1 |
| sdk/rabble_lvgl_port/rabble_lv_mem.c | 77 | 19 | 11 | 57.9 |
| sdk/rabble_core/rabble_console.c | 31 | 11 | 6 | 54.5 |
| app/RaBbLE/nl_scene.h | 20 | 4 | 2 | 50.0 |
| app/RaBbLE/rabble_setup.h | 24 | 4 | 2 | 50.0 |
| sdk/rabble_core/rabble_board.h | 126 | 69 | 30 | 43.5 |
| sdk/rabble_net/rabble_beam_text.h | 20 | 7 | 3 | 42.9 |
| app/RaBbLE/rabble_clock_screen.h | 23 | 5 | 2 | 40.0 |
| app/RaBbLE/rabble_input.h | 38 | 6 | 2 | 33.3 |
| sdk/rabble_core/rabble_console.h | 29 | 6 | 2 | 33.3 |
| sdk/rabble_net/rabble_beam_priv.h | 27 | 6 | 2 | 33.3 |
| drivers/rabble_axp2101/include/rabble_axp2101.h | 63 | 24 | 7 | 29.2 |
| drivers/rabble_qmi8658/include/rabble_qmi8658.h | 37 | 7 | 2 | 28.6 |
| drivers/rabble_qmi8658/rabble_qmi8658.c | 93 | 61 | 16 | 26.2 |
| app/RaBbLE/rabble_shot.h | 55 | 16 | 4 | 25.0 |
| sdk/rabble_core/rabble_text.h | 43 | 12 | 3 | 25.0 |
| sdk/rabble_net/rabble_wifi_air.h | 116 | 64 | 16 | 25.0 |
| sdk/rabble_voice/rabble_voice.h | 50 | 16 | 4 | 25.0 |
| boards/rabble_waveshare_175b/bsp_display.c | 274 | 141 | 32 | 22.7 |
| sdk/rabble_net/rabble_wifi_known.h | 58 | 18 | 4 | 22.2 |
| drivers/rabble_axp2101/rabble_axp2101.c | 264 | 142 | 31 | 21.8 |
| drivers/rabble_pcf85063/include/rabble_pcf85063.h | 41 | 15 | 3 | 20.0 |
| sdk/rabble_net/rabble_wifi.h | 100 | 40 | 8 | 20.0 |
| app/RaBbLE/rabble_app.c | 121 | 49 | 9 | 18.4 |
| app/RaBbLE/rabble_orbit.h | 53 | 11 | 2 | 18.2 |
| sdk/rabble_net/rabble_wifi_radio.c | 335 | 176 | 32 | 18.2 |
| main/app_main.c | 27 | 6 | 1 | 16.7 |
| sdk/rabble_core/rabble_state.h | 76 | 42 | 7 | 16.7 |
| boards/rabble_waveshare_175b/bsp_waveshare_175b.c | 279 | 145 | 24 | 16.6 |
| sdk/rabble_net/rabble_beam_score.c | 1070 | 610 | 94 | 15.4 |
| sdk/rabble_store/rabble_notes.c | 493 | 259 | 40 | 15.4 |
| sdk/rabble_net/rabble_beam.c | 113 | 59 | 9 | 15.3 |
| sdk/rabble_net/rabble_beam.h | 71 | 40 | 6 | 15.0 |
| drivers/rabble_pcf85063/rabble_pcf85063.c | 101 | 54 | 8 | 14.8 |
| app/RaBbLE/entity_face.h | 59 | 21 | 3 | 14.3 |
| sdk/rabble_store/rabble_capture.c | 60 | 28 | 4 | 14.3 |
| sdk/rabble_voice/rabble_outbox.c | 611 | 338 | 48 | 14.2 |
| sdk/rabble_net/rabble_wifi_known.c | 433 | 217 | 30 | 13.8 |
| sdk/rabble_core/rabble_time.c | 260 | 140 | 19 | 13.6 |
| sdk/rabble_net/rabble_beam_text.c | 293 | 134 | 18 | 13.4 |
| sdk/rabble_audio/rabble_audio.h | 51 | 15 | 2 | 13.3 |
| app/RaBbLE/rabble_ui.c | 933 | 538 | 66 | 12.3 |
| app/RaBbLE/rabble_shot.c | 265 | 156 | 19 | 12.2 |
| sdk/rabble_motion/rabble_motion.c | 604 | 375 | 45 | 12.0 |
| boards/rabble_waveshare_175b/bsp_texture.c | 242 | 124 | 14 | 11.3 |
| sdk/rabble_core/rabble_state.c | 277 | 141 | 15 | 10.6 |
| boards/rabble_waveshare_175b/bsp_display.h | 60 | 29 | 3 | 10.3 |
| sdk/rabble_core/rabble_settings.c | 345 | 171 | 17 | 9.9 |
| sdk/rabble_power/rabble_battery.c | 742 | 401 | 37 | 9.2 |
| app/RaBbLE/rabble_pomo.h | 76 | 34 | 3 | 8.8 |
| sdk/rabble_audio/rabble_audio.c | 576 | 318 | 28 | 8.8 |
| app/RaBbLE/rabble_pomo.c | 281 | 154 | 12 | 7.8 |
| sdk/rabble_motion/rabble_motion.h | 66 | 26 | 2 | 7.7 |
| boards/rabble_waveshare_175b/bsp_frame.h | 96 | 53 | 4 | 7.5 |
| sdk/rabble_render/include/nebula_lite.h | 177 | 97 | 7 | 7.2 |
| boards/rabble_waveshare_175b/bsp_bands.c | 564 | 298 | 21 | 7.0 |
| sdk/rabble_net/rabble_wifi.c | 667 | 337 | 23 | 6.8 |
| sdk/rabble_core/rabble_settings.h | 77 | 46 | 3 | 6.5 |
| sdk/rabble_net/rabble_wifi_priv.h | 43 | 16 | 1 | 6.2 |
| sdk/rabble_voice/rabble_voice.c | 939 | 554 | 34 | 6.1 |
| app/RaBbLE/rabble_orbit_logic.h | 286 | 184 | 11 | 6.0 |
| sdk/rabble_core/rabble_device.c | 40 | 18 | 1 | 5.6 |
| sdk/rabble_store/rabble_notes_console.c | 201 | 126 | 7 | 5.6 |
| sdk/rabble_voice/rabble_outbox.h | 52 | 19 | 1 | 5.3 |
| app/RaBbLE/rabble_a8.c | 99 | 59 | 3 | 5.1 |

### Directory roll-up, HEAD

| dir | files | subst | matched | % |
|---|---|---|---|---|
| TOTAL | 106files | 13609 | 1089 | 8.0 |
| app | 29files | 5300 | 246 | 4.6 |
| app/RaBbLE | 29files | 5300 | 246 | 4.6 |
| boards | 8files | 984 | 103 | 10.5 |
| boards/rabble_waveshare_175b | 8files | 984 | 103 | 10.5 |
| drivers | 6files | 303 | 67 | 22.1 |
| drivers/rabble_axp2101 | 2files | 166 | 38 | 22.9 |
| drivers/rabble_pcf85063 | 2files | 69 | 11 | 15.9 |
| drivers/rabble_qmi8658 | 2files | 68 | 18 | 26.5 |
| main | 1files | 6 | 1 | 16.7 |
| panel_bench | 1files | 170 | 5 | 2.9 |
| panel_bench/main | 1files | 170 | 5 | 2.9 |
| sdk | 61files | 6846 | 667 | 9.7 |
| sdk/rabble_audio | 4files | 389 | 37 | 9.5 |
| sdk/rabble_core | 16files | 1072 | 116 | 10.8 |
| sdk/rabble_lvgl_port | 2files | 21 | 11 | 52.4 |
| sdk/rabble_motion | 2files | 401 | 47 | 11.7 |
| sdk/rabble_net | 14files | 1815 | 248 | 13.7 |
| sdk/rabble_power | 2files | 423 | 50 | 11.8 |
| sdk/rabble_render | 11files | 1355 | 19 | 1.4 |
| sdk/rabble_store | 6files | 443 | 52 | 11.7 |
| sdk/rabble_voice | 4files | 927 | 87 | 9.4 |

### Directory roll-up, 42ae6d9 (first appearance of apache/, 2026-10-06)

| dir | files | subst | matched | % |
|---|---|---|---|---|
| TOTAL | 57files | 5669 | 3367 | 59.4 |
| bsp | 3files | 230 | 164 | 71.3 |
| components | 53files | 5434 | 3202 | 58.9 |
| components/rabble_axp2101 | 2files | 130 | 97 | 74.6 |
| components/rabble_gadget | 49files | 5235 | 3094 | 59.1 |
| components/rabble_pcf85063 | 2files | 69 | 11 | 15.9 |
| main | 1files | 5 | 1 | 20.0 |

### Directory roll-up, 2965c39 (6c3b78b^, 2026-10-24)

| dir | files | subst | matched | % |
|---|---|---|---|---|
| TOTAL | 100files | 13418 | 1071 | 8.0 |
| bsp | 8files | 982 | 112 | 11.4 |
| components | 74files | 11188 | 829 | 7.4 |
| components/nebula_lite | 11files | 1913 | 21 | 1.1 |
| components/rabble_axp2101 | 2files | 166 | 38 | 22.9 |
| components/rabble_gadget | 57files | 8972 | 741 | 8.3 |
| components/rabble_pcf85063 | 2files | 69 | 11 | 15.9 |
| components/rabble_qmi8658 | 2files | 68 | 18 | 26.5 |
| main | 1files | 6 | 1 | 16.7 |
| panel_bench | 1files | 170 | 5 | 2.9 |
| panel_bench/main | 1files | 170 | 5 | 2.9 |
| sdk | 16files | 1072 | 124 | 11.6 |
| sdk/rabble_core | 14files | 1051 | 113 | 10.8 |
| sdk/rabble_lvgl_port | 2files | 21 | 11 | 52.4 |

### 42ae6d9 files (the OG-derived state), per file

| file | lines | subst | matched | % |
|---|---|---|---|---|
| components/rabble_gadget/apache/rabble_lv_mem.c | 65 | 20 | 20 | 100.0 |
| components/rabble_gadget/apache/rabble_battery.c | 522 | 294 | 282 | 95.9 |
| components/rabble_gadget/apache/rabble_keypad.c | 312 | 165 | 158 | 95.8 |
| components/rabble_gadget/apache/rabble_wifi_mgr.c | 599 | 363 | 344 | 94.8 |
| components/rabble_gadget/apache/rabble_text.c | 254 | 168 | 158 | 94.0 |
| bsp/rabble_lcd_bands.c | 157 | 79 | 74 | 93.7 |
| components/rabble_gadget/apache/rabble_adpcm.c | 78 | 39 | 35 | 89.7 |
| components/rabble_gadget/apache/rabble_beam_text.c | 218 | 101 | 90 | 89.1 |
| components/rabble_axp2101/rabble_axp2101.c | 176 | 107 | 90 | 84.1 |
| components/rabble_gadget/apache/rabble_board.c | 112 | 53 | 43 | 81.1 |
| components/rabble_gadget/apache/rabble_wifi_known.c | 327 | 193 | 152 | 78.8 |
| components/rabble_gadget/apache/rabble_settings_ui.c | 1250 | 751 | 581 | 77.4 |
| components/rabble_gadget/apache/rabble_audio.c | 318 | 176 | 123 | 69.9 |
| components/rabble_gadget/apache/rabble_state.c | 238 | 121 | 84 | 69.4 |
| components/rabble_gadget/apache/rabble_input.c | 572 | 303 | 201 | 66.3 |
| components/rabble_gadget/apache/rabble_voice.c | 913 | 483 | 308 | 63.8 |
| bsp/bsp_waveshare_175b.c | 300 | 149 | 90 | 60.4 |
| components/rabble_gadget/apache/rabble_board.h | 121 | 50 | 30 | 60.0 |
| components/rabble_gadget/apache/rabble_console.c | 34 | 10 | 6 | 60.0 |
| components/rabble_gadget/apache/rabble_battery.h | 62 | 20 | 11 | 55.0 |
| components/rabble_gadget/apache/rabble_settings.c | 238 | 129 | 70 | 54.3 |
| components/rabble_gadget/apache/rabble_adpcm.h | 25 | 6 | 3 | 50.0 |
| components/rabble_gadget/apache/rabble_wifi.c | 450 | 275 | 128 | 46.5 |
| components/rabble_gadget/apache/rabble_setup.c | 163 | 96 | 40 | 41.7 |
| components/rabble_gadget/accord/rabble_clock_screen.h | 22 | 5 | 2 | 40.0 |
| components/rabble_gadget/apache/rabble_beam.c | 81 | 40 | 13 | 32.5 |
| components/rabble_axp2101/include/rabble_axp2101.h | 69 | 23 | 7 | 30.4 |
| components/rabble_gadget/apache/rabble_app.c | 83 | 39 | 11 | 28.2 |
| components/rabble_gadget/apache/rabble_wifi_mgr.h | 69 | 18 | 5 | 27.8 |
| components/rabble_gadget/apache/rabble_beam_priv.h | 39 | 8 | 2 | 25.0 |
| components/rabble_gadget/apache/rabble_text.h | 51 | 12 | 3 | 25.0 |
| components/rabble_gadget/apache/rabble_input.h | 39 | 9 | 2 | 22.2 |
| components/rabble_gadget/apache/rabble_mem.h | 38 | 10 | 2 | 20.0 |
| components/rabble_pcf85063/include/rabble_pcf85063.h | 40 | 15 | 3 | 20.0 |
| main/app_main.c | 25 | 5 | 1 | 20.0 |
| components/rabble_gadget/accord/rabble_beam_score.c | 818 | 458 | 89 | 19.4 |
| components/rabble_gadget/accord/rabble_ui.c | 681 | 396 | 70 | 17.7 |
| components/rabble_gadget/apache/rabble_beam.h | 124 | 42 | 7 | 16.7 |
| components/rabble_gadget/apache/rabble_wifi.h | 80 | 37 | 6 | 16.2 |
| components/rabble_pcf85063/rabble_pcf85063.c | 100 | 54 | 8 | 14.8 |
| components/rabble_gadget/accord/entity_face.h | 58 | 21 | 3 | 14.3 |
| components/rabble_gadget/apache/rabble_state.h | 87 | 40 | 5 | 12.5 |
| components/rabble_gadget/apache/rabble_wifi_known.h | 55 | 16 | 2 | 12.5 |
| components/rabble_gadget/accord/rabble_clock_screen.c | 207 | 130 | 4 | 3.1 |
| components/rabble_gadget/apache/rabble_settings.h | 67 | 37 | 1 | 2.7 |
| bsp/rabble_lcd_bands.h | 48 | 2 | 0 | 0.0 |
| components/rabble_gadget/accord/entity_face.c | 73 | 39 | 0 | 0.0 |
| components/rabble_gadget/accord/rabble_lv_assert.h | 15 | 2 | 0 | 0.0 |
| components/rabble_gadget/accord/rabble_palette.h | 25 | 14 | 0 | 0.0 |
| components/rabble_gadget/accord/rabble_ui.h | 29 | 5 | 0 | 0.0 |
| components/rabble_gadget/accord/ui_theme.h | 21 | 9 | 0 | 0.0 |
| components/rabble_gadget/apache/rabble_audio.h | 52 | 13 | 0 | 0.0 |
| components/rabble_gadget/apache/rabble_console.h | 26 | 4 | 0 | 0.0 |
| components/rabble_gadget/apache/rabble_keypad.h | 27 | 2 | 0 | 0.0 |
| components/rabble_gadget/apache/rabble_settings_ui.h | 25 | 3 | 0 | 0.0 |
| components/rabble_gadget/apache/rabble_setup.h | 30 | 3 | 0 | 0.0 |
| components/rabble_gadget/apache/rabble_voice.h | 40 | 7 | 0 | 0.0 |

### C. Own-from-the-start modules: first-add vs HEAD

| path (at first-add) | first commit | date | subst | match | % | HEAD subst | HEAD match | HEAD % |
|---|---|---|---|---|---|---|---|---|
| firmware/components/nebula_lite/include/nebula_lite.h | 5f775ae | 2026-10-15 | 19 | 2 | 10.5 | 97 | 7 | 7.2 FLAG |
| firmware/components/nebula_lite/src/compose.c | 5f775ae | 2026-10-15 | 48 | 0 | 0.0 | 356 | 2 | 0.6 |
| firmware/components/nebula_lite/src/luts.c | 5f775ae | 2026-10-15 | 9 | 0 | 0.0 | 30 | 0 | 0.0 |
| firmware/components/nebula_lite/src/nl_internal.h | 5f775ae | 2026-10-15 | 15 | 1 | 6.7 | - | - | 0.0 FLAG |
| firmware/components/nebula_lite/src/nl_simd.h | 9fbdee2 | 2026-10-15 | 5 | 0 | 0.0 | 5 | 0 | 0.0 |
| firmware/components/nebula_lite/src/orbit.c | 47adbb9 | 2026-10-22 | 105 | 1 | 1.0 | 260 | 1 | 0.4 |
| firmware/components/nebula_lite/src/raster.c | f4156ae | 2026-10-15 | 262 | 1 | 0.4 | 366 | 3 | 0.8 |
| firmware/components/nebula_lite/src/raster_soft.c | 5f775ae | 2026-10-15 | 25 | 0 | 0.0 | 61 | 0 | 0.0 |
| firmware/components/nebula_lite/src/scene.c | 5f775ae | 2026-10-15 | 17 | 0 | 0.0 | 560 | 2 | 0.4 |
| firmware/components/nebula_lite/src/simd_c.c | 9fbdee2 | 2026-10-15 | 17 | 0 | 0.0 | 17 | 0 | 0.0 |
| firmware/components/nebula_lite/src/simd_pie_glue.c | 9fbdee2 | 2026-10-15 | 12 | 0 | 0.0 | 12 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/rabble_beam_score.c | 42ae6d9 | 2026-10-06 | 458 | 89 | 19.4 | 610 | 94 | 15.4 FLAG |
| firmware/components/rabble_gadget/accord/rabble_capture.c | 678e335 | 2026-10-22 | 24 | 4 | 16.7 | 28 | 4 | 14.3 FLAG |
| firmware/components/rabble_gadget/accord/rabble_capture.h | 678e335 | 2026-10-22 | 6 | 0 | 0.0 | 7 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/rabble_clock_screen.h | 42ae6d9 | 2026-10-06 | 5 | 2 | 40.0 | 5 | 2 | 40.0 FLAG |
| firmware/components/rabble_gadget/accord/rabble_entity.c | f4156ae | 2026-10-15 | 259 | 13 | 5.0 | 501 | 16 | 3.2 FLAG |
| firmware/components/rabble_gadget/accord/rabble_entity.h | f4156ae | 2026-10-15 | 5 | 0 | 0.0 | 9 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/rabble_level_screen.c | 51c110a | 2026-10-22 | 158 | 7 | 4.4 | 158 | 7 | 4.4 |
| firmware/components/rabble_gadget/accord/rabble_level_screen.h | 51c110a | 2026-10-22 | 3 | 0 | 0.0 | 3 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/rabble_lv_assert.h | 42ae6d9 | 2026-10-06 | 2 | 0 | 0.0 | 2 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/rabble_motion.c | 21eb8c8 | 2026-10-06 | 106 | 13 | 12.3 | 375 | 45 | 12.0 FLAG |
| firmware/components/rabble_gadget/accord/rabble_motion.h | 21eb8c8 | 2026-10-06 | 3 | 0 | 0.0 | 26 | 2 | 7.7 FLAG |
| firmware/components/rabble_gadget/accord/rabble_notes.c | 4529039 | 2026-10-22 | 245 | 38 | 15.5 | 259 | 40 | 15.4 FLAG |
| firmware/components/rabble_gadget/accord/rabble_notes.h | 4529039 | 2026-10-22 | 21 | 1 | 4.8 | 22 | 1 | 4.5 |
| firmware/components/rabble_gadget/accord/rabble_notes_console.c | 60e1c9a | 2026-10-22 | 113 | 5 | 4.4 | 126 | 7 | 5.6 FLAG |
| firmware/components/rabble_gadget/accord/rabble_notes_console.h | 60e1c9a | 2026-10-22 | 1 | 0 | 0.0 | 1 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/rabble_outbox.c | c698884 | 2026-10-23 | 338 | 48 | 14.2 | 338 | 48 | 14.2 FLAG |
| firmware/components/rabble_gadget/accord/rabble_outbox.h | c698884 | 2026-10-23 | 19 | 1 | 5.3 | 19 | 1 | 5.3 FLAG |
| firmware/components/rabble_gadget/accord/rabble_palette.h | 42ae6d9 | 2026-10-06 | 14 | 0 | 0.0 | 14 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/rabble_pomo.c | 6fcd739 | 2026-10-22 | 154 | 12 | 7.8 | 154 | 12 | 7.8 FLAG |
| firmware/components/rabble_gadget/accord/rabble_pomo.h | 6fcd739 | 2026-10-22 | 34 | 3 | 8.8 | 34 | 3 | 8.8 FLAG |
| firmware/components/rabble_gadget/accord/rabble_time.c | 90e8926 | 2026-10-16 | 137 | 19 | 13.9 | 140 | 19 | 13.6 FLAG |
| firmware/components/rabble_gadget/accord/rabble_time.h | 90e8926 | 2026-10-16 | 11 | 0 | 0.0 | 12 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/rabble_ui.c | 42ae6d9 | 2026-10-06 | 396 | 70 | 17.7 | 538 | 66 | 12.3 FLAG |
| firmware/components/rabble_gadget/accord/rabble_ui.h | 42ae6d9 | 2026-10-06 | 5 | 0 | 0.0 | 7 | 0 | 0.0 |
| firmware/components/rabble_gadget/accord/ui_theme.h | 42ae6d9 | 2026-10-06 | 9 | 0 | 0.0 | 9 | 0 | 0.0 |
| firmware/components/rabble_pcf85063/include/rabble_pcf85063.h | 12f7799 | 2026-08-08 | 15 | 3 | 20.0 | 15 | 3 | 20.0 FLAG |
| firmware/components/rabble_pcf85063/rabble_pcf85063.c | 12f7799 | 2026-08-08 | 54 | 8 | 14.8 | 54 | 8 | 14.8 FLAG |
| firmware/components/rabble_qmi8658/include/rabble_qmi8658.h | 21eb8c8 | 2026-10-06 | 6 | 2 | 33.3 | 7 | 2 | 28.6 FLAG |
| firmware/components/rabble_qmi8658/rabble_qmi8658.c | 21eb8c8 | 2026-10-06 | 38 | 12 | 31.6 | 61 | 16 | 26.2 FLAG |
| firmware/main/app/entity_face.c | 12f7799 | 2026-08-08 | 39 | 0 | 0.0 | 39 | 0 | 0.0 |
| firmware/main/app/entity_face.h | 12f7799 | 2026-08-08 | 19 | 3 | 15.8 | 21 | 3 | 14.3 FLAG |
| firmware/main/app/ui_theme.h | 12f7799 | 2026-08-08 | 9 | 0 | 0.0 | 9 | 0 | 0.0 |
| firmware/main/app_main.c | 12f7799 | 2026-08-08 | 97 | 13 | 13.4 | 6 | 1 | 16.7 FLAG |
| firmware/panel_bench/main/panel_bench.c | a77437a | 2026-10-15 | 133 | 4 | 3.0 | 170 | 5 | 2.9 |

### 4. 5-line identifier-normalised windows, HEAD, files over 5%

| % | hit/windows | file |
|---|---|---|
| 100.0 | 10/10 | sdk/rabble_core/rabble_palette.h |
| 88.9 | 16/18 | sdk/rabble_power/rabble_battery.h |
| 85.7 | 12/14 | sdk/rabble_net/rabble_wifi_known.h |
| 66.7 | 24/36 | sdk/rabble_net/rabble_wifi.h |
| 58.3 | 21/36 | sdk/rabble_net/rabble_beam.h |
| 57.9 | 22/38 | sdk/rabble_core/rabble_state.h |
| 50.0 | 2/4 | sdk/rabble_audio/rabble_adpcm.h |
| 50.0 | 1/2 | sdk/rabble_net/rabble_beam_priv.h |
| 40.5 | 17/42 | sdk/rabble_core/rabble_settings.h |
| 37.5 | 3/8 | sdk/rabble_core/rabble_text.h |
| 36.4 | 4/11 | sdk/rabble_audio/rabble_audio.h |
| 30.8 | 20/65 | sdk/rabble_core/rabble_board.h |
| 17.8 | 8/45 | app/RaBbLE/rabble_app.c |
| 16.7 | 23/138 | drivers/rabble_axp2101/rabble_axp2101.c |
| 16.7 | 2/12 | sdk/rabble_voice/rabble_voice.h |
| 14.9 | 21/141 | boards/rabble_waveshare_175b/bsp_waveshare_175b.c |
| 12.7 | 7/55 | sdk/rabble_net/rabble_beam.c |
| 10.0 | 2/20 | drivers/rabble_axp2101/include/rabble_axp2101.h |
| 9.1 | 2/22 | sdk/rabble_motion/rabble_motion.h |
| 8.8 | 5/57 | drivers/rabble_qmi8658/rabble_qmi8658.c |
| 5.1 | 7/137 | boards/rabble_waveshare_175b/bsp_display.c |

Total: 2.3% (300/13196)
