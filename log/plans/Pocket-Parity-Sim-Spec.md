# Pocket parity sim: spec v0.1 (S281)

> Mark (S281): "The renders must include Time and sCoRE and have all the icons, so the sim and device have visual parity. I also want the fonts to match the device's." This is needed before promo graphics, and it goes before SDK S8, where it serves as the full-UI pixel gate for the Orbit split.

## Parity means the same code, not a lookalike

Today `sim/` renders only the nebula_lite layer: the entity scene plus Orbit scenes drawn with a hand-made 5x7 font (`sim/orbit_scenes.c:5`). The device draws all text and icons with **LVGL 9.5.0**, using compressed Montserrat 14/16/18/20/22/24/26/32/48 and unscii-16, with Montserrat 20 as the default and `LV_SYMBOL_*` for the icons. It draws them in two places:
- LVGL screens: the status row in `rabble_ui.c:714` (Wi-Fi, sCoRE, battery), the clock screen ("Time from sCoRE"), the level screen and setup.
- Orbit labels and icons: LVGL glyphs rasterized into A8 sprites (`rabble_orbit.c:98-515`, `rabble_a8.c`) and composited by `sdk/rabble_render`.

The sim reaches parity by compiling the **real** sources against a **host board**:

| Layer | Source |
|---|---|
| LVGL | `firmware/managed_components/lvgl__lvgl` (9.5.0) built for the host. `lv_conf.h` is **generated from `firmware/sdkconfig`** (every `CONFIG_LV_*`), never hand-written, so fonts, compression, colour depth (16, RGB565) and draw settings can't drift |
| App + SDK | `app/RaBbLE/*.c`, `sdk/rabble_render`, and the `sdk/*` pieces the UI calls, unmodified |
| Board | a new host `rabble_board_t` (seam: `sdk/rabble_core/rabble_board.h:57-83`). `display_start` makes an LVGL display. `display_direct` keeps the app's `render(dst, y0, rows, x0, x1)` and calls it band by band (the device's `rows`) to assemble a 466x466 RGB565 frame. `ui_texture`/`ui_texture_tag` follow `boards/rabble_waveshare_175b/bsp_texture.c`: LVGL direct mode, two full-screen buffers, a front published on refresh complete. Read that file and keep its semantics |
| Everything the device gets from hardware or network | host fakes, set by the scene: wall-clock time + zone + "synced from sCoRE", Wi-Fi up/down/RSSI, beam/sCoRE connected/lost/token, battery %/mV/charging/USB, IMU roll/level, touch and buttons, saved notes count, mode (Converse/Capture) |
| FreeRTOS / esp_* | host shims. Reuse `firmware/test/app/orbit_test/stubs/` and the seam test's fakes where they fit (`firmware/test/core/seam_test`), and extend them, don't duplicate |

**No firmware source edits.** If host-building a file truly needs a seam change in `firmware/`, stop and report to the lead with the exact reason. Don't work around it by copying firmware code into `sim/`.

## Driving it: scenes

- A scene is a small text file (`sim/scenes/<name>.scene`) holding the fake state (key=value lines) and a timeline of actions. Each action is an **app console command** (the same `>…` commands the device takes, e.g. `rabble_orbit_command` / `orbit_logic_command`), a touch gesture, a button press or `wait <ms>`. It ends with `shot <name>` lines.
- Time advances at the device frame rate (`frame_ms`), deterministically. There is no wall clock and no randomness unless it is seeded.
- The same command scripts should later run on the device over serial for the parity diff (a `>shot` device command is still pending Mark's yes; don't add it).

## Coverage: every screen

Make a scene for every screen and state the device can show, and list any you can't reach with the reason. At minimum:
- **Entity:** idle, listen, think, speak, error, sleep/wake; the status row in every combination that changes pixels (Wi-Fi off/weak/strong, sCoRE connected/lost, battery high/low/charging/USB).
- **Orbit:** home, more, every page and item kind (value, choice, toggle, text entry, networks/join, signals, hold, applets), slide/peek/roll (0/90/180/270).
- **Clock:** time synced from sCoRE and not synced. **Level** screen. **Setup** screens.
- **Pomodoro:** all states. **Capture/Converse**, notes waiting/sending, power screens.

## Outputs and gate

- Build entry `sim/pocket/build.sh`, using `firmware/test/paths.sh` helpers (`ACC`, `RINC`, `rsrc`) for every firmware path, so S8/S9 moves don't break it. Render entry `sim/pocket/run.sh [scene…]` → `sim/pocket/out/<shot>.png` (466x466; RGB565 expanded the same way the panel shows it) plus a `contact_sheet.png` of all shots for Mark.
- Goldens: commit `sim/pocket/golden/<shot>.png` + `golden.sha256`. New test `firmware/test/render/parity_test/run.sh` builds, renders all scenes and compares bit-exact. It's listed in `firmware/test/run.sh`'s layer walk the same way `render/sim_test` is.
- Determinism: two full runs must be byte-identical, and the test proves it.
- Old `sim/` stays as is (`render/sim_test` still runs). The **4 failing Orbit sprite assertions** (`sim/orbit_scenes.c:354`, `test_orbit_sprite_e2e`: runtime reference `ref_rotate`/`ref_blend` vs the renderer, 95/256 px at each roll) are a separate item. Find out whether the reference or the renderer is wrong (check S274's Orbit transition commits) and report it; don't change the assertion or the renderer without the lead.

## Device `>shot` (Mark approved, S281)

"Add a shot command to the FW; this will also be useful for Pocket Remote Control." Capture is kept separate from transport, so Remote Control can reuse the capture as is:
- **Capture:** `app/RaBbLE/rabble_shot.*`. It wraps the entity direct-render callbacks (`rabble_entity.c` `s_direct`), so it works on any board. While armed, `same` returns 0 and one full frame is copied band by band into a PSRAM buffer allocated on demand. It costs zero internal RAM (B-22) and zero bytes when idle. The LVGL-only face isn't covered yet.
- **Transport 1:** the console. `>shot` replies `@shot {w,h,fmt,order,bytes,frame,sha256}`, then base64 lines, then `@shot.end`. `CONFIG_RABBLE_SHOT` defaults to y.
- **Host side:** `ops/pocket-shot.py` checks the sha256 and writes a PNG. Parity check: run the same scene commands on the device and in the sim, `>shot` each, and diff.
- **Transport 2 (later):** Pocket Remote Control, e.g. over the beam.

## Out of scope (later)

Promo exports (upscale, device mockup, GIF/MP4), the remote-control transport, S8.

## Done

- `sim/pocket/build.sh` and `run.sh` exit 0, and every scene renders.
- Fonts and icons come from LVGL. `grep` proves no hand-made font is in the parity path.
- `test/run.sh` is green with `render/parity_test` included.
- A determinism run is byte-identical.
- The contact sheet exists.
- There is a list of unreachable screens.
- Commits follow the Pulse Protocol on `new-horizons`, tagged `%S281_SIM%`, and nothing is pushed.
