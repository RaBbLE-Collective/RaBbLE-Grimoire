# HANDOFF-S267 · Pocket: finish the clean room (W6 + W7), then the RaBbLE-SDK on the Sovereign Accord

> Written 2026-10-22 at the end of S267 for a cold start. Supersedes `done/HANDOFF-S266-Pocket-Orbit-Pomodoro.md` (its open items are carried below).
> Mark's order (S267): **finish the clean room, then finish the RaBbLE-SDK on the Sovereign Accord.** Pomodoro, faster wake and the rest wait until after.
> Read first: this file, then `RaBbLE-Pocket/RaBbLE-Pocket-Clean-Room-Plan.md` (Roles, Clean workspace, Contract, the W6 and W7 rows, Done when), then `RaBbLE-Pocket/cleanroom/PROVENANCE.md`.

## Where things are

| Repo | Branch | State |
|---|---|---|
| RaBbLE-Pocket | `new-horizons` `ac2e9f9` | **nothing pushed** (54 ahead of origin). Flashed: `ac2e9f9` |
| RaBbLE-Grimoire | `new-horizons` | this handoff + docs committed at S267 end, not pushed |
| RaBbLE-Collective | `new-horizons` | current-state block updated, not pushed |
| RaBbLE-sCoRE | `new-horizons` `663bc10` | unchanged (live on Render) |

Clean room status: **W0 to W5 done**, `apache/` is gone. The only Meta-derived code left is **`firmware/bsp/`** (3 files, 1,171 lines):

| File | Lines | What it is |
|---|---|---|
| `bsp/bsp_waveshare_175b.c` | 401 | the board table: panel, touch, PMU, RTC, IMU, codec bring-up behind `rabble_board_t` |
| `bsp/rabble_lcd_bands.c` | 689 | band renderer flush: the panel task, the helper core, PSRAM textures, damage skipping (mostly RaBbLE's own perf work since S251, but the file began as Meta's) |
| `bsp/rabble_lcd_bands.h` | 81 | its internal interface (nothing in `accord/` includes it) |

`grep -rln "Meta Platforms"` over the repo (minus `managed_components/`, `third_party/`, `build/`, `.git`) lists those three plus `firmware/NOTICE`. That grep returning nothing is the finish line.

## Done in S267

1. **Orbit v2 flashed and hand-checked** (Mark: "looks good"). Fixes from his check:
   - **`c6c6e47`** beam could not connect at all on v2: `websocket_client: Error create websocket task` every 500 ms. The v2 controller state and text cache grew internal-RAM `.bss` until the 6 KB websocket task stack no longer fit. `s_L` (6 KB) and `s_cache` (5 KB) in `accord/rabble_orbit.c` are UI-task bookkeeping, now `EXT_RAM_BSS_ATTR` (PSRAM). Beam connects in ~1.8 s. **Lesson: watch internal RAM headroom; a failed `xTaskCreate` is the symptom.**
   - **`ac2e9f9`** (a) the back chip's tap zone was a 40 px circle checked before the centre, covering the centre's lower third: low "tap to change" taps went back to the face. Now the pill only (±44 × ±17). (b) Ring labels only near the top: new contract field `nl_orbit_t.label_full` (radians; full within it of 12 o'clock, gone by 1.5×, faded by angle every frame), and the controller builds labels for the chosen item ±2 on every page (`LABEL_REACH`), so the Wi-Fi Networks/Saved lists show their neighbours' names (before: only the chosen one past 9 items). (c) Hint up to y 284, chip down to y 324 (233 + 91; the spec said + 78) so they no longer touch. 732 logic checks, sim scenes `orbit_12/13`.
2. Answered Mark twice: the clean room is **not** finished until W6 + W7.

## Next, in order

### 1. W6: the board layer through the clean room (also Mark's BSP walkthrough)

Mark wants W6 to double as his map of the board layer: the spec is written to be read by him, then walked through with him, then handed to a fresh implementer.

**Roles.** Whoever writes the spec reads `bsp/` (S). The implementer is a **fresh** session that never saw `bsp/`, `third_party/muse-gadget-sdk/`, `third_party/` flash backups or this repo's history. S267 did not open `bsp/` and is clean; S266, S264 and earlier Pocket sessions are tainted (see `PROVENANCE.md`).

**Steps.**

1. **Datasheets first** (the plan flagged them as missing; still missing): CO5300 (panel driver IC), CST9217 (touch) and ES7210 (mic ADC: mic gain is in W6's scope). Source the public vendor PDFs into `firmware/datasheets/` (+ `README.md` row). Without them the implementer works from the managed `espressif__esp_lcd_co5300` and the Waveshare board package only, which may be enough: decide after reading them.
2. **Boot-time numbers** (carried from S266 step 2, folds in here): before writing the spec, the integrator adds temporary `BOOTTIME` timestamps after each step of `display_start()` in `bsp_waveshare_175b.c` (`esp_lv_adapter_init`, `panel_new`, `rabble_lcd_bands_register`, `bsp_touch_new`), flashes once, reads one cold boot, reverts. S266 measured panel lit at ~2.7 s and a **1.2 s gap** between CO5300 init (1250 ms) and touch (2450 ms). The numbers become **timing targets** in the spec (behaviour, not code). Config trims Mark agreed in principle (apply with his ok, any time, in `firmware/sdkconfig.defaults`, which sets none of them today: `SPIRAM_MEMTEST` is on and the bootloader logs at INFO): UART console 115200 → 921600 (logs busy-wait the UART; also kills the ~25 ms stats hitch), `CONFIG_SPIRAM_MEMTEST=n` (~0.2 s), `CONFIG_BOOTLOADER_LOG_LEVEL_WARN`, `CONFIG_BOOTLOADER_SKIP_VALIDATE_ON_POWER_ON=y` (trade-off: no image check on cold power-on). Tell Mark: wakes are full boots because of auto power-off after 45 s asleep on battery (`CONFIG_RABBLE_POWER_OFF_S`, Orbit "Off when asleep"); sleep wake is ~0.13 s to drawing.
3. **Write `RaBbLE-Pocket/cleanroom/w6-board.spec.md`** (S, may be a Sonnet sub-agent with `model: "sonnet"`, or the session itself). Shape it like `w0-seam.spec.md` / `w4-audio.spec.md`, plus a **"map for Mark"** opening section in plain words: what each chip on the board is (panel CO5300 over QSPI, touch CST9217, PMU AXP2101, RTC PCF85063, IMU QMI8658, audio codec ES8311 + mic path), which bus and pins, what powers up in which order and why, and how a frame travels from `nebula_lite` bands to glass. Then the normal contract: the public interface is **only the `rabble_board_t` fields in `accord/rabble_board.h`** (direct mode, stats, UI texture, `run`, and the rest of the vtable). Do **not** hand `rabble_lcd_bands.h` to the implementer: nothing in `accord/` includes it, it is Meta-derived and comment-heavy, and the band layer's internal API should be the implementer's own. Behaviour rules, timings (the boot targets from step 2), error cases, behaviour checklist, test vehicle. Required rules carried from earlier sessions:
   - **A frame is never held by a stalled helper core** (S264 freeze fix; capture plan T0).
   - Flash work runs under panel priority; **no PSRAM texture copies** (S264/S265).
   - The entity gates still hold: 60 fps idle, ≥ 30 busy/turning, Orbit slide with meshes ≥ 40.
   - "Leaner" per the hybrid strategy: lean on the managed Waveshare board package and `espressif__esp_lcd_co5300` for bring-up; our file keeps the board table and glue.

   **Deliberate behaviour changes** (mark them as such in the spec, apart from the "same as today" checklist, since W6 is otherwise not a redesign): opt-in perf logs (`>perf` on the console; no such command exists yet, and the bands file logs timing every 10 s unconditionally today), and steady 30 fps pacing when 60 can't hold (new).

   **Checklist seed** for the spec author (behaviour level, from the review; the spec author confirms each against `bsp/` and words it in their own terms): unused PMU rails off at init; PWR read by PMU polling, short click powers back on after power-off; the board degrades gracefully without PMU, RTC or IMU (feature off + warning); draw areas aligned to even pixels; panel dark until the UI's first frame (no white flash); brightness through the panel, via the send task; panel sleep is plain sleep, not deep standby (panel and touch share reset); touch deep-sleeps with the screen off and is reset on wake; mic gain in 3 dB steps including the 33 dB quirk; IMU axes mapped to screen axes, gyro included; button-hint positions, mic angles and the 40 ms frame time unchanged; no PSRAM draw buffers once Wi-Fi is up; the band-send task and its SPI interrupt on the UI core (deadlock rule); warning + unpaced frames when the TE line is missing.
4. **Firewall review** (F): an independent Opus agent reads the spec against `bsp/` for carried expression (identifiers, constant tables, comment phrasing, structure mirroring). W6 is **not** a redesign, so F is required (W5 skipped it legitimately; W6 can't).
5. **Walk Mark through it** (his ask): the W6 spec's map section, then the seam (`w0-seam.spec.md`), how the waves fit (`Clean-Room-Plan.md`), and where the docs live. Fold his questions back into the spec before the implementer starts.
6. **Implement** (I): fresh Sonnet session in a plain export, per the plan's "Clean workspace" recipe **adjusted to today's tree**: `apache/` no longer exists; **do not** exclude `rabble_axp2101` any more (clean since W2, and the board file needs it, with pcf85063 and qmi8658); exclude `firmware/bsp` and `ops/cleanroom-overlap.py`; don't export `third_party/`. Excluding `bsp/` alone breaks configure (`firmware/CMakeLists.txt` lists it in `EXTRA_COMPONENT_DIRS`, `main/CMakeLists.txt` has `PRIV_REQUIRES bsp`, and the Waveshare package `^3.0.1`, which brings the CO5300 driver, is declared only in `bsp/idf_component.yml`). So the integrator first writes a **fresh `bsp/` skeleton** in the workspace: a `CMakeLists.txt` with the REQUIRES list and an `idf_component.yml` with the Waveshare dependency (interface-level only, no code). With that, the **whole firmware builds in the export**, and that build plus a flash is the test vehicle (the plan's "the full firmware can't build there" is out of date). The implementer writes new files under `bsp/` (the plan's Roles row says `accord/`: for W6 read `bsp/`). Workspace `~/RaBbLE-Cleanroom/pocket-w6`. If you split into two implementers (board table vs. band renderer), put their shared contract in the workspace yourself first, as W5 did.
7. **Integrate** (G): swap in, build, flash, run the behaviour checklist on the gadget (boot, wake from sleep, wake from power-off, touch everywhere incl. the rim, IMU, audio turn, 60 fps idle, Orbit slide fps, the S264 freeze repro: flash work during a turn), `ops/cleanroom-overlap.py` < 5% with every hit reviewed, `ops/cleanroom-audit.py` on the archived transcripts (`~/RaBbLE-Cleanroom/transcripts/w6/`), delete the old files **in the same commit**, PROVENANCE row.

### 2. W7: close-out (small, mechanical)

W7 comes **after W6's overlap gate passes**: deleting the SDK retires the gate (`ops/cleanroom-overlap.py:16` hard-codes `third_party/muse-gadget-sdk`). From the plan's W7 row, updated to today's tree:
- Delete `firmware/bsp/LICENSE-APACHE` and the Apache section of `firmware/NOTICE` (keep the managed-components paragraph).
- Reword the Apache mentions in `bsp/CMakeLists.txt` (header comment), `bsp/idf_component.yml` ("(Apache-2.0)"), `firmware/CONTEXT.md`, `components/rabble_gadget/idf_component.yml`; leave `planning/decisions/` ADRs as history. `firmware/README.md:3` and `.gitignore:2` name the Meta/Muse SDK (not Apache): reword them once the SDK is deleted.
- **Stale test paths:** six test scripts still point at the deleted `components/rabble_gadget/apache`: `test/cleanroom/w1/console_setup_test/gen_ifc.sh:5` (its default: that test is probably broken today), `w2/input_test/compile_check.sh:11` and `run.sh:9`, `w3/beam_test/run.sh:10,16`, `w3/wifi_test/compile_check.sh:27`. Fix and rerun them.
- Delete `third_party/muse-gadget-sdk/` and note it in `third_party/README.md`; retire or rewrite `ops/cleanroom-overlap.py`.
- Update Grimoire `RaBbLE-Pocket-Gadget-Port.md`, `RaBbLE-Pocket-Muse-SDK-Map.md`, the clean-room plan status line and its `Done when` grep (it still excludes `muse-gadget-sdk`/`backups`: exclude `third_party` instead), `PROVENANCE.md` (close-out row), roadmap.
- **Header sweep (new in S267):** 17 RaBbLE-own C/header files have no copyright line at all. Add `/* Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord. */` as line 1: `accord/entity_face.c/.h`, `accord/ui_theme.h`, `accord/rabble_clock_screen.c/.h`, `components/rabble_pcf85063/rabble_pcf85063.c` + `include/rabble_pcf85063.h`, `nebula_lite/src/{nl_simd.h, simd_c.c, simd_pie_glue.c, raster_soft.c, compose.c, luts.c, nl_internal.h, raster.c, scene.c}`, `sim/host_render.c`. **Ask Mark** whether the sweep is C sources only or every tracked file: also header-less are all CMakeLists except axp2101's, `rabble_gadget/Kconfig`, `main/Kconfig.projbuild`, `ops/*.sh`, `sim/*.sh`, ~90 files under `firmware/test/cleanroom/`, `hardware/cad/scripts/*.py`.
- **Gate (Done when):** the "Meta Platforms" grep is empty; NOTICE lists no redistributed third party; every **formerly derived** module has a PROVENANCE row (code that was RaBbLE's from the start, such as entity, motion, notes, capture, time, ui, the screens, nebula_lite, qmi8658, pcf85063, has none: add a short "RaBbLE's own from the start" table to PROVENANCE so the gate can pass); entity gates hold.
- Git history still holds the Apache-derived files. That is lawful (Apache permits it) and the plan never asked to rewrite history: **don't**, unless Mark asks.

### 3. The RaBbLE-SDK on the Sovereign Accord

Mark (S266, restated S267): once the clean room is done, reorganise the firmware into clear components with small public headers, all Sovereign Accord. **Plan the layout with Mark first**; the sketch below is a starting point for that conversation, not a decision.

**Decisions to settle with Mark before any move:**
1. **Name and home:** "RaBbLE-SDK" as components inside `RaBbLE-Pocket/firmware/components/` (simplest), or its own repo/member that the Pocket (and later boards: the 1.75C, a Cyberdeck) consume as an ESP-IDF component dependency? A new member needs a registry manifest and Grimoire docs (`spells/init-project.sh`).
2. **Board scope:** stays one board (-B) for now, with the BSP file-per-board rule kept (`bsp_waveshare_175b.c`, later `_175c.c`).
3. **What counts as SDK vs. app:** is the Orbit / face / Pomodoro "the app" on top of an SDK, or part of it?

**Sketch** (from the S267 include graph of `accord/`, 68 files, 16,668 lines; Opus-reviewed):

| Component | Files today | Notes |
|---|---|---|
| `rabble_core` | `rabble_board.*` (the seam), `rabble_mem.h`, `rabble_state.*`, `rabble_settings.*`, `rabble_text.*`, `rabble_console.*`, `rabble_palette.h`, `rabble_time.*` | not a light leaf: `rabble_board.h` pulls in `lvgl.h`, `esp_codec_dev.h`, `driver/gpio.h`, so core REQUIRES those publicly. Time lives here (the clock screen needs it, and it only needs board + NVS). The 3 Kconfig symbols are used only by `rabble_settings.c`: they move with it |
| board layer (`bsp/` + chip drivers) | `bsp_*`, `rabble_axp2101`, `rabble_qmi8658`, `rabble_pcf85063` | `accord/` never includes the chip drivers; only `bsp/` does. Keep them with the board so portable code never depends on a chip. `bsp/` then REQUIRES `rabble_core`, not `rabble_gadget`. `rabble_board_get` is called only from `main/app_main.c:18`: no link cycle. Wire up the unused `RABBLE_BOARD` choice in `main/Kconfig.projbuild` before a 1.75C board file arrives |
| `rabble_power` | `rabble_battery.*` | |
| `rabble_motion` | `rabble_motion.*` | today includes `rabble_input` and `rabble_voice`: an upward dependency to cut |
| `rabble_audio` | `rabble_audio.*`, `rabble_adpcm.*`, `rabble_voice.*` | `voice` includes `beam` and `input`: cut |
| `rabble_net` | `rabble_wifi*.*`, `rabble_beam*.*` (not `beam_text`) | `beam_score.c` (1,051 lines) reaches into capture, notes, audio, setup |
| `rabble_store` | `rabble_notes.*`, `rabble_notes_console.*`, `rabble_capture.*` | `notes_console` needs mbedtls/psa |
| `rabble_ui` | `rabble_ui.*`, `rabble_entity.*`, `entity_face.*`, `rabble_a8.*`, `rabble_clock_screen.*`, `rabble_level_screen.*`, `ui_theme.h`, `rabble_lv_mem.c`, `rabble_lv_assert.h` | `rabble_ui.c` (not only entity) includes beam, capture, notes, time, wifi, motion. `rabble_lv_mem.c` relies on LVGL internals and `CONFIG_LV_USE_CUSTOM_MALLOC=y`. `nebula_lite` stays its own component |
| `rabble_orbit` | `rabble_orbit.*`, `rabble_orbit_logic.*` | **cycle with ui**: `rabble_orbit.c` includes `rabble_entity.h` + `rabble_ui.h` while `rabble_entity.c` + `rabble_ui.c` include `rabble_orbit.h`; `orbit_logic.c` reaches into input, beam, wifi. Merge into ui or invert through callbacks |
| app (`main/` or `rabble_app`) | `rabble_app.c`, `rabble_input.*`, `rabble_setup.*`, `rabble_beam_text.*` | `input` is today's hub (includes 17 RaBbLE headers): it's the app router, not a driver |

The real work is **cutting the upward includes** (motion → input/voice, voice → beam/input, entity and ui → beam/wifi/notes/capture, beam_score → capture/notes/audio, the orbit ↔ ui cycle) through the state hub or registered callbacks, so each component's `REQUIRES` is honest. **Hidden coupling that will mask missing REQUIRES:** the gadget CMakeLists adds `accord/` as a **PUBLIC** include dir on LVGL's target (for the assert hook), so every component that links LVGL sees every accord header. Point that hook at the new home of `rabble_lv_assert.h` only, early in the refactor. Do it in steps that keep the gadget building and flashing between each (one component per commit, the orbit and W0-W5 host tests green). Keep `WHOLE_ARCHIVE` on whichever component carries `rabble_lv_mem.c`. Get an Opus review of the final layout plan against the code before moving files. Write the plan to `RaBbLE-Grimoire/RaBbLE-Pocket/RaBbLE-Pocket-SDK-Plan.md` (index it) once Mark has picked.

### 4. Carried (after the SDK, in Mark's earlier order)

- **Applets orbit + Pomodoro**: fully specified in `w5-orbit.spec.md` section 6.
- **Faster wake** beyond what W6 fixes (boot animation 0.9 → ~0.5 s: ask Mark).
- **Wi-Fi labels**: offered Mark a lock/signal suffix on network labels (`Cafe 🔒`); no answer yet.
- **W5 spec rev 4 note**: section 5 should record S267's deltas (chip y 324, chip hit = pill, `label_full`, `LABEL_REACH`). Written at S267 end (see the spec).
- From S265: **T5** `ops/pocket-notes.py pull [--prune]`, **T6** voice capture, W4 hand checklist.
- Later: sCoRE voice persona (terse), agency slice 1 "act on the Pocket", the vocoder voice.
- **Push**: nothing is pushed in Pocket or Grimoire; push only when Mark says.

## Gotchas you will hit

- **Internal RAM** is tight: before adding static state, check `.bss` in `build/rabble_pocket.map`; UI-only state goes `EXT_RAM_BSS_ATTR`. The symptom of running out is a failing `xTaskCreate` (beam's websocket task first).
- **Serial**: one logger (`serlog.py` pattern from any recent scratchpad: append commands to `<log>.cmd`); `pkill -f "serlog.p[y]"` in its own call before flashing; opening the port resets the gadget; it re-enumerates ACM0/ACM1 and drops off USB when powered off. Waiting: `timeout N tail -f /dev/null` (foreground `sleep` is blocked).
- **zsh**: `grep` is a shell function in the Bash tool: use `command grep`; `--include=*.c` globs fail unquoted.
- **Orbit console**: `>orbit=open|close|back|state|turn:n|tap|hold|value:v|type:text`; each prints one `@orbit {...}` line. If replies move without your commands, Mark has it in hand: stop driving.
- **Frame rates**: read `rabble_entity`'s `fps`/`late frame` lines, not LVGL timers.
- **Taint**: the implementer must never see `bsp/`, `third_party/`, git history or this file's predecessors that quote `bsp/` (S266 handoff mentions `display_start()` step names: that's interface-level, but keep handoffs out of the clean workspace anyway).
- **end-session.sh** drops older ledger rows sharing the breadcrumb id: back up `log/token-ledger.tsv`, run it, restore and append only the new row; diff LATEST after.
