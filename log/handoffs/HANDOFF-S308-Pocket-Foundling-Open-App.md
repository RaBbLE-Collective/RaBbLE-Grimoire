# HANDOFF-S308: Pocket open entity default and the Foundling app

> Cold start. Written 2026-11-03 (S308). Read `log/plans/Pocket-Foundling-Open-App-Plan.md` first: it has the done / not-done ledger and the roadmap.

## State
- **Tap-to-talk merged (S308, after Mark's device check "seems to work"):** `new-horizons` fast-forwarded to `f416059` (tap-to-talk `dfcb1d9`..`e131c18` + build-flash fix + the new **Tap to talk** setting: Orbit More > Tap to talk, console `tap_talk=0|1`, NVS key `tap_talk`, default on, gates the mic icon). Host tests `app` + `core` green; flashed and checked on the 1.75-B. Not pushed. Not independently re-run by a second agent, no NiBbLE review of the setting. `open-entity-default` was rebased onto it (`efa9793`, `04f4355`). The device currently runs the plain RaBbLE build; the Open build needs `-DSDKCONFIG` as below.
- RaBbLE-Pocket branch `open-entity-default` (from `tap-to-talk`), commit `10df613`, not pushed. New `firmware/sdk/open_entity_default/` plus a small `#if CONFIG_OPEN_ENTITY_DEFAULT` hook in `app/RaBbLE/rabble_ui.c`.
- The device (1.75-B on `/dev/ttyACM0`) runs that build in `ota_0`. Mark saw the face; the settings panel was flashed later and is unchecked. Previous firmware: `~/RaBbLE-backups/pocket-pre-open-*/ota_0.bin` (the oldest folder is the real RaBbLE image; later ones may be Open builds). Restore: esptool `write-flash 0x20000 ota_0.bin`.
- Mark's rulings (S308): app = **Foundling**; licensing on hold, everything stays SA, Apache split later; SDK files are SA but carry an `Open-transition:` header line where they will flip (`grep -rl "Open-transition:" firmware/`). Commit after `10df613` switches the component's headers to that. Next ask: a real `app/Foundling/` (SDK deps only). Not started.

## Build recipe (the Open variant)
`/tmp` scripts are gone after a reboot. Recreate: source `ops/esp-idf-select.sh`, `pocket_idf_activate_for_script`, run `idf.py -B /tmp/open_bld -DSDKCONFIG=/tmp/open_sdkconfig build` from `firmware/`, with `CONFIG_OPEN_ENTITY_DEFAULT=y` set in `/tmp/open_sdkconfig` after its first generation (the project CMake overrides `SDKCONFIG_DEFAULTS`). Flash with esptool to 0x20000 only (back up `ota_0` + NVS first). Check the map for `open_entity_settings` before flashing.

## Gotchas
- A first Open flash was the plain RaBbLE build (existing sdkconfig won over defaults). Verify the symbol, not the exit code.
- Do not stage `RaBbLE-Pocket/README.md` or `firmware/hw_test/` build output. Held, untracked in the public Grimoire: Provenance Record, Split Manifest, `cleanroom/audit-2026-11-02/`, W10 spec, Open-Layer notes. The S298 commits in the public Grimoire are still unpushed: do not push.
- The six questions in HANDOFF-S304 are still open and still gate W10.

## Next
1. Mark checks the settings panel on the device (colour persists across reboot, sliders, sleep).
2. Rule on the open decisions at the end of the plan; then start A1+A2 (the `app/Foundling/` skeleton).
