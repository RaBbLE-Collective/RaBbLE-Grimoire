# HANDOFF-S281 · Pocket: `>shot`, parity sim, gate fixes, then S8

> Written 2026-10-25 at the end of S281 for a cheaper cold start. All Pocket work is on `new-horizons`, local, not pushed. Read the spec `log/plans/Pocket-Parity-Sim-Spec.md` first.

## Mark's asks (S281)
1. NiBbLE re-review of the S280 gate fixes. **Done.** 2 medium + 3 low holes; fixes in progress (below).
2. A comprehensive sim before promo graphics. **Bar: visual parity with the device.** That means Time, sCoRE, every icon, and the device's fonts.
3. A firmware `>shot` command, also for Pocket Remote Control. **Built, not on hardware.**
4. Mark hand-authors Pocket content ("the AI ones are too generic"). **Open:** which content (the S278 press drafts, on-device text, or the promo shot list), and whether he wants templates. Ask him.
5. Then SDK S8.

## State by track

| Track | Commits | State | Next |
|---|---|---|---|
| `>shot` | `75ce308` `a14d129` `433eb58` `0c8e2e5` (`%S281_SHOT%`) | Built. `rabble_shot.c/.h` wraps `s_direct` and copies one frame to PSRAM. The console `shot` command and `ops/pocket-shot.py` are in. `CONFIG_RABBLE_SHOT`=y. Suite 29 passed + `render/sim_test` known failure; Xtensa `-Werror` clean; layer gate clean. Image 2,058,064 B (+2,832 B over 2,055,232). **Nothing flashed** | **CrumBbLE:** flash it, run `ops/pocket-shot.py`, check heap at ready (12,351 B) and fps haven't moved. Unverified: `psa_crypto_init` internal heap cost (SHA-256 goes through PSA in IDF v6), console throughput, and that `begin` never overlaps the previous frame's bands. Then NiBbLE reviews. Note CoBbLE-Shot edited `test/app/input_test/input_test.c` (a one-line stub), which was outside its file list |
| Parity sim | `7c792bd` (`%S281_SIM%`) | **Scaffold only; no shot renders.** `sim/pocket/`: `gen_lv_conf.py` (`sdkconfig` → `lv_conf.h`, 128 values), host LVGL 9.5.0 builds in ~4 s, a deterministic cooperative FreeRTOS, ESP shims, the real `app/RaBbLE` sources + the real `bsp_texture.c` in `sim.mk`. Compile currently stops on missing includes in the shim headers. See `sim/pocket/WIP.md` | Finish phase 1: fix shim includes, link, write the host `rabble_board_t` (`display_start`, `display_direct` band loop, touch), fakes (Wi-Fi, beam, audio, voice, console, CPU load), the scene runner and PNG output; three shots (entity idle + status row, clock synced from sCoRE, Orbit home); prove fonts with `nm`. Then phase 2 per the spec. Parity holes known: CPU-load fake (feeds entity mesh activity), fixed 60 Hz pacing. **`firmware/sdkconfig` is gitignored**, so the sim's `lv_conf.h` depends on the local file: decide whether to commit a canonical copy or generate from `sdkconfig.defaults` |
| Gate fixes | `01b515b` (`%S281_GATE%`, only `ops/sdk-layers.py`) | Findings **1** (component dirs the checker missed) and **3** (scan blind spots) fixed and proven. **2** (basename collisions) and **4** (a board including another board) coded but **not proven**: the planted cases were invalid. **5** (`render/sim_test` XFAIL hides every failure) **not started**. Real tree passes both modes, but `test/run.sh` was **not re-run** on the new checker. `--symbols` warns on stale archives (`bsp`, `nebula_lite`, `rabble_app`, `rabble_gadget`, `waveshare_175b`) in `build/esp-idf/`. Unresolved `EXTRA_COMPONENT_DIRS` variables are flagged, not resolved | Re-run the suite. Prove 2 and 4 with correct plants (`scene.h` must exist in two components; a board that includes another real board's header). Do 5 (only the 4 known assertions at `sim/orbit_scenes.c:354`, 95/256 px at rolls 0/90/180/270, may XFAIL). Then NiBbLE re-checks against `/tmp/nibble-s281-cases/` (may be gone) |

## NiBbLE findings (the source for the gate track)
1. Medium: `firmware/components/*` and new top-level dirs invisible to both modes (`ops/sdk-layers.py` `TOP_DIRS`, `libs()`, the `dst is None` skip).
2. Medium: layer table keyed by basename, first found wins, so `sdk/rabble_core/scene.c` inherits app's layer.
3. Low: `.cpp/.cc/.hpp`, `#include_next`, macro includes and symlinked dirs not scanned; header-only SDK component passes `--symbols`.
4. Low: boards may include other boards.
5. Low: the `sim_test` XFAIL absorbs any failure mode.
Held: gate on the real export, planted violations on known modules, `test/run.sh` stale-entry logic, voice_test, fixes 5-6 of S280. The suite also needed ESP-IDF v5.5.4 activated via `ops/esp-idf-select.sh` in NiBbLE's export, while the firmware pins v6.0.1 (`build/project_description.json` says v6.0.1): find out why the select script picks v5.5.4.

## Facts for S8 (GoBbLE map)
- "orbit.c" in the plan names two files: the app's `rabble_orbit.c` (704 lines; lines 98-515 are LVGL/A8 drawing) and `sdk/rabble_render/src/orbit.c`.
- The Orbit draws via `rabble_a8`, which is an S9 item, so **S8 needs a re-cut** (pull a8 forward or leave the draw half in the app). Have QuiBbLE (Opus) attack the S8 spec before anyone builds it.
- The engine half of `rabble_orbit_logic.c` names pages/items and calls `rabble_ui_*`, `rabble_pomo_*`, `rabble_input_request_power_off` about 25 times, so it needs an injection seam.
- Two include cycles: `rabble_orbit.c:29`↔`rabble_entity.c:33` and `rabble_orbit.c:33`↔`rabble_ui.c:33`. `rabble_ui` has no `COMP_LAYER` row yet.
- orbit_test runs 875 checks; paths are hard-coded in `orbit_test/run.sh:24`, `sim/*.sh` and `paths.sh:18`.
- The 4 sim failures compare against a reference computed at runtime (`sim/orbit_scenes.c:354`): investigate, don't re-golden.
- Stale docs: SDK-Plan line counts at :61-64; PROVENANCE :149 orbit_test path and count.

## Other open items
- **B-22** (saved voice note dropped on the TLS AES alloc): Mark picks the fix.
- Mark's open question on hand-authored content (ask 4).
- S280's NiBbLE re-review is closed by this session's re-review.
