# HANDOFF-S308: Pocket open entity default and the Foundling app

> Cold start. Written 2026-11-03 (S308). Read `log/plans/Pocket-Foundling-Open-App-Plan.md` first: it has the done / not-done ledger and the roadmap.

## State
- **Tap-to-talk merged (S308, after Mark's device check "seems to work"):** `new-horizons` fast-forwarded to `f416059` (tap-to-talk `dfcb1d9`..`e131c18` + build-flash fix + the new **Tap to talk** setting: Orbit More > Tap to talk, console `tap_talk=0|1`, NVS key `tap_talk`, default on, gates the mic icon). Host tests `app` + `core` green on `new-horizons` at the merge; flashed and checked on the 1.75-B (the flashed build predates the merge commit only by the fast-forward; same code). Not pushed. No second agent re-ran the tests, no NiBbLE review of the setting. `open-entity-default` was rebased onto it (`efa9793`, `04f4355`), then `c8b1696` fixed `core/seam_test` (its Kconfig shim `test/core/seam_test/idfproj/shim_app/Kconfig` must list every new sdk component option; the cached `idfproj/build/config/sdkconfig.h` must be deleted to regenerate). Full suite on `open-entity-default`: 32 pass, 0 fail, 1 known XFAIL. The device currently runs the plain RaBbLE build; the Open build needs `-DSDKCONFIG` as below.
- RaBbLE-Pocket branch `open-entity-default` (from `tap-to-talk`), commit `10df613`, not pushed. New `firmware/sdk/open_entity_default/` plus a small `#if CONFIG_OPEN_ENTITY_DEFAULT` hook in `app/RaBbLE/rabble_ui.c`.
- The device (1.75-B on `/dev/ttyACM0`) runs that build in `ota_0`. Mark saw the face; the settings panel was flashed later and is unchecked. Previous firmware: `~/RaBbLE-backups/pocket-pre-open-*/ota_0.bin` (the oldest folder is the real RaBbLE image; later ones may be Open builds). Restore: esptool `write-flash 0x20000 ota_0.bin`.
- Mark's rulings (S308): app = **Foundling**; licensing on hold, everything stays SA, Apache split later; SDK files are SA but carry an `Open-transition:` header line where they will flip (`grep -rl "Open-transition:" firmware/`). Commit after `10df613` switches the component's headers to that. Next ask: a real `app/Foundling/` (SDK deps only). Not started.

## Build recipe (the Open variant)
`/tmp` scripts are gone after a reboot. Recreate: source `ops/esp-idf-select.sh`, `pocket_idf_activate_for_script`, run `idf.py -B /tmp/open_bld -DSDKCONFIG=/tmp/open_sdkconfig build` from `firmware/`, with `CONFIG_OPEN_ENTITY_DEFAULT=y` set in `/tmp/open_sdkconfig` after its first generation (the project CMake overrides `SDKCONFIG_DEFAULTS`). Flash with esptool to 0x20000 only (back up `ota_0` + NVS first). Check the map for `open_entity_settings` before flashing.

## Gotchas
- A first Open flash was the plain RaBbLE build (existing sdkconfig won over defaults). Verify the symbol, not the exit code.
- Do not stage `RaBbLE-Pocket/README.md` or `firmware/hw_test/` build output. Held, untracked in the public Grimoire: Provenance Record, Split Manifest, `cleanroom/audit-2026-11-02/`, W10 spec, Open-Layer notes. The S298 commits in the public Grimoire are still unpushed: do not push.
- The six questions in HANDOFF-S304 are still open and still gate W10.

## Branches (RaBbLE-Pocket, nothing pushed)
- `new-horizons` = `f416059` (tap-to-talk + setting merged). `open-entity-default` = `c8b1696`, 3 commits on top (component, SA headers with `Open-transition:` marker, seam-test shim). `tap-to-talk` = `f416059` (same as new-horizons; can be deleted). `README.md` is modified and unstaged on purpose (false provenance wording).
- Grimoire: S308 commits `2bb45d0`, `f25ae6f`, `d384024`, this handoff update. Held docs still untracked (Provenance Record, Split Manifest, `cleanroom/audit-2026-11-02/`, W10 spec, Open-Layer notes).

## Not done / not checked
- Open settings panel never checked on the device; Open build has no Orbit and no mic icon.
- Merged `new-horizons` not reflashed after the merge; full suite not run on it separately.
- `end-session` LATEST/token ledger depend on whether the closing script ran (see SESSION-LOG).
- Mark's mid-session note, not touched: in the RaBbLE-UI micro mark (sCoRE repo), going into and out of the portals the eyes look like they grow but do not move. Separate thread (S306/S307 handoffs).
- Foundling app (`app/Foundling/`), W8/W9/W10, SPDX/include lints, manifest approval: see the plan's ledger.

## Next
1. Mark checks the settings panel on the device (colour persists across reboot, sliders, sleep).
2. Rule on the open decisions at the end of the plan; then start A1+A2 (the `app/Foundling/` skeleton).
