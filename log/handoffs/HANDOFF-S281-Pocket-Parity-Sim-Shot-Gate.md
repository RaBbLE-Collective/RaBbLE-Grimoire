# HANDOFF-S281 · Pocket: parity sim, `>shot`, gate fixes, then S8

> Written 2026-10-25 in S281, mid-flight, before the orchestrator moved to Sonnet and compacted. Session transcript: `~/.claude/projects/-home-rabble/0ff303d7-*.jsonl`.

## Mark's asks (S281), in order
1. NiBbLE re-review of the S280 gate fixes. **Done:** 2 medium + 3 low holes, sent to CoBbLE-Gate.
2. Make the sim comprehensive before promo graphics. **Bar: visual parity with the device.** That means Time, sCoRE and every icon, with fonts matching the device. Spec: `log/plans/Pocket-Parity-Sim-Spec.md`.
3. **Mark approved** a firmware `>shot` command: "useful for Pocket Remote Control". Capture is separate from transport (console first, remote later).
4. Mark hand-authors Pocket content ("AI ones too generic"). **Still open:** which content (the S278 press drafts, on-device text, or the promo shot list), and whether he wants templates. Ask him.
5. Then SDK S8.

## Running organs (background agents of session 0ff303d7; reports come back to that session)

| Organ | Job | Owns | Done when |
|---|---|---|---|
| CoBbLE (sim) | Parity sim **phase 1 only**: host LVGL 9.5.0 with `lv_conf.h` generated from `sdkconfig`, a host `rabble_board_t`, the real `app/RaBbLE` sources. Three shots: idle + status row, clock synced from sCoRE, Orbit home. Then STOP for lead review | `sim/pocket/**`, `firmware/test/render/parity_test/**` | Reports. Then the lead reviews and sends phase 2: all screens, goldens, parity_test, determinism, contact sheet, the 4-assertion investigation |
| CoBbLE-Shot | `app/RaBbLE/rabble_shot.*`, which wraps `s_direct` render/same in `rabble_entity.c` and copies one frame to PSRAM (zero internal RAM, B-22); console `shot` in `rabble_input.c`; `CONFIG_RABBLE_SHOT`=y; `ops/pocket-shot.py`; `test/app/shot_test`. No flashing | those files | Reports. Then **CrumBbLE** flashes it, runs `ops/pocket-shot.py` and checks heap/fps are unchanged. Then NiBbLE reviews |
| CoBbLE-Gate | NiBbLE's 5 findings in `ops/sdk-layers.py`: undiscovered `components/` dirs, basename-keyed table, scan blind spots (.cpp, include_next, macro includes, symlinks, header-only under `--symbols`), boards including other boards, and the `sim_test` XFAIL hiding every failure | `ops/sdk-layers.py`, `test/render/sim_test/run.sh`, `KNOWN_FAILURES` | Reports. Then NiBbLE re-checks it against `/tmp/nibble-s281-cases/` |

Commit tags: `%S281_SIM%`, `%S281_SHOT%`, `%S281_GATE%`. Nothing is pushed.

## Facts for S8 (GoBbLE map, S281)
- The plan's S8 row is ambiguous. "orbit.c" names two files: the app's `rabble_orbit.c` (704 lines, of which lines 98-515 are LVGL/A8 drawing) and `sdk/rabble_render/src/orbit.c`.
- The Orbit draws via `rabble_a8`, which is an S9 item, so **S8 needs a re-cut** (pull a8 forward, or leave the draw half in the app).
- The engine half of `rabble_orbit_logic.c` names pages/items and calls `rabble_ui_*`, `rabble_pomo_*` and `rabble_input_request_power_off` about 25 times, so it needs an injection seam.
- There are two include cycles: `rabble_orbit.c:29`↔`rabble_entity.c:33` and `rabble_orbit.c:33`↔`rabble_ui.c:33`.
- `rabble_ui` has no `COMP_LAYER` row yet. orbit_test runs 875 checks, and the paths are hard-coded in `orbit_test/run.sh:24`, `sim/*.sh` and `paths.sh:18`.
- The 4 sim failures (`sim/orbit_scenes.c:354`) compare against a reference computed at runtime, not a golden file: investigate them, don't re-golden.
- SDK-Plan line counts at :61-64 and the PROVENANCE :149 orbit_test path are stale.

## Other open items
- B-22 (voice note dropped on the TLS AES alloc): Mark picks the fix.
- NiBbLE saw the test suite need ESP-IDF v5.5.4 via `ops/esp-idf-select.sh`, while the firmware pins v6.0.1 (CoBbLE-Gate reports which).
- The S281 close-out is still to do: session log entry, LATEST, ledger, INDEX line for this handoff and the spec, Grimoire commit.
