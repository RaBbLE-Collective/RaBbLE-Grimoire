# Foundling: the Pocket app on the open SDK (Apache-2.0 later)

> Status: DRAFT v0.2, 2026-11-03 (S308). Mark's direction: an open app on the SDK, the Apache-2.0 counterpart of RaBbLE. **Rulings (Mark, S308):** the app is **Foundling** (internal name; a lore word, not cleared as a public name, see `Pocket-Release-Entities-Companion-Plan.md`, so D3 stays open); **hold off on licensing: everything stays Sovereign Accord (SA) for now, the Apache split comes later**; SDK files are SA but marked as transitioning so we know which will flip (convention below). Licence rulings elsewhere remain working assumptions until the lawyer reads them (`Pocket-Open-SDK-App-Separation-Plan.md`). Nothing here is published.
> Code: RaBbLE-Pocket branch `open-entity-default`, commit `10df613` (branched from `tap-to-talk`; not pushed).

## What exists (S308)

`firmware/sdk/open_entity_default/` (SA headers with an Open-transition marker; no RaBbLE names beyond the copyright and licence lines):
- `open_entity_core.[ch]`: pure C. Two white true ellipses, analytic anti-aliased fill, one uniform outline colour from six named pastels (mint, sky, lavender, peach, rose, lemon), blink every 2.5-6 s, moods idle/listen/think/speak/warn/error/off/waking (pose differs by eye position and size only), amber/red fixed for warn/error.
- `open_entity_default.[ch]`: LVGL glue (one RGB565 PSRAM canvas, redraws only the changed box) and a plain-LVGL settings panel (outline colour dots saved to NVS namespace `open_entity`, brightness and volume sliders through an ops struct, Done).
- `test/open_entity_host.c`: host render to PPM plus checks (all pass).
- `Kconfig`: `OPEN_ENTITY_DEFAULT` (off by default), `OPEN_ENTITY_PASTEL`.

Wiring today is a hack: `app/RaBbLE/rabble_ui.c` (Sovereign Accord) switches to it behind `CONFIG_OPEN_ENTITY_DEFAULT`, skips `rabble_entity_init`, drops the wordmark, and a face tap opens the panel. So the "Open build" is the RaBbLE app with the entity off. It is not yet a separate app.

## Done and verified

| Item | Evidence |
|---|---|
| Face renders to spec on the host | PNG sheet of six moods read by eye; `open_entity_host` ok |
| Full firmware build with the option on | 2.0 MB image in a 3.5 MB slot; `open_entity` symbols present in the map |
| Flashed to the 1.75-B | hash verified; Mark saw the face; backup of the previous `ota_0` + NVS in `~/RaBbLE-backups/pocket-pre-open-*` |
| Committed | `10df613` |

## Built but NOT verified on the device

- The settings panel (layout on the round panel, touch on dots and sliders, outline colour surviving a reboot, brightness preview and commit, volume). Mark reported seeing only the face on the build before the panel existed; the panel build is flashed, unchecked.
- Sleep and wake, blink cadence, tearing, with the Open face.
- Listen/think/speak moods: need a voice turn (BOOT is broken hardware).

## Not done (roadmap input)

**A. Separate the app (the Foundling ask)**
1. `app/Foundling/` tree and a CMake selector (like `RABBLE_BOARD`): own `foundling_app_run`, own `main` entry. Boot order to cover (from `rabble_app.c`, 121 lines): settings init, board init, state and battery, UI start, input task, voice start, motion start, Wi-Fi start. Depends on SDK components only.
2. Remove the `#if CONFIG_OPEN_ENTITY_DEFAULT` hooks from `rabble_ui.c`; it goes back to SA-only.
3. Generic screens the app needs, as SDK `ui_kit` (plan P2 step 7): clock screen (and 12:00 rule), settings (Wi-Fi, sleep, brightness, volume, clock set), level screen, Pomodoro. Today these are `app/RaBbLE/*` SA files: SA for now, so Foundling may reuse generic app screens as they are; mark them for transition and never copy Meta-influenced parts into the flip set.
4. Input without the Orbit: the settings panel is the stand-in. Tap-to-talk (merged into `new-horizons` S308, device-checked by Mark, now a setting) is an app feature, not entity-bound; its mic icon target needs an LVGL home.
5. Voice backend for a free open tier (B-25): persona from the entity config; sCoRE protocol stays app-side SA (D5), so Foundling needs a generic transport with a configurable protocol id.
6. Entity hook (P2 step 1) so Foundling's face and RaBbLE's entity are the same plug-in point; the `#if` goes away.
7. Entity-transplant (`.rble`) loader and the notes-store location (Entity-Format spec).

**B. Open the SDK properly (separation plan P1-P5)**
- Manifest approval (469 rows drafted, held untracked), SPDX lint (`ops/spdx-lint.py`, not written), SDK-to-SA include lint extension, brand-value lint, neutral palette split (SDK pastel vs `app/RaBbLE/RaBbLE_palette.h`), brand values out of the SDK (device name, Kconfig titles, protocol id, `rabble-os.local`).
- All of `sdk/` and `boards/` is SA-headed, and stays so for now. Only the new component carries the Open-transition marker; marking the rest waits on the manifest (below).
- Clean rooms: W8 `rabble_beam_score.c` session layer; W9 `rabble_ui.c` lifecycle block; W10 board seam (spec draft 1 got QuiBbLE **REVISE**, six questions waiting in HANDOFF-S304); build config; `derived` set by overlap.
- `firmware/NOTICE` still claims everything is RaBbLE's own: false for any derived file. Root `PROVENANCE.md`, README provenance wording.
- P0: signing key, `sdk-split` branch, signed `pre-split` tag (not made; this work is on `open-entity-default`).
- `nebula_lite` as SA middleware (third tree).

**C. Release hygiene and people**
- Lawyer: Apache grant by an unregistered "Collective" (Mark's DBA), Meta lines, header-compaction history, trademarks (RABBLE filed by others in class 9; "Open" must not be in a product name; Foundling uncleared).
- gitleaks `--all` on every public repo and tags; firmware/OTA signing keys; CONTRIBUTING (DCO vs CLA); CI (build, host tests, layer lint, SPDX lint, gitleaks); dry-run private mirror; fresh clone builds from README alone.
- Hold-outs in the public Grimoire: Provenance Record, Split Manifest, `cleanroom/audit-2026-11-02/`, W10 spec, Open-Layer notes stay untracked until Mark rules where they live.

**D. Hardware and known faults**
- BOOT switch broken (GPIO0 never low); resolder, or rely on touch plus tap-to-talk once it has a home.
- Tap-to-talk is merged and works on the RaBbLE build; the Open build has no mic icon (needs an LVGL home).
- 1.75-C may be ordered (WillowClone for dad; uses Waveshare code until clean-roomed).
- Stale `firmware/sdkconfig` gotcha: the project CMake overrides `SDKCONFIG_DEFAULTS`, and an existing sdkconfig wins over defaults. Build the Open variant with `-DSDKCONFIG=/tmp/x` and set `CONFIG_OPEN_ENTITY_DEFAULT=y` in that file (S308 flashed the plain RaBbLE build once because of this). A `RABBLE_APP` selector (A1) removes the trick.

## Suggested order (Mark to rule)

1. Device check of the current build (panel, colour persistence, sleep). Small, gates everything after.
2. A1+A2: `app/Foundling/` skeleton that boots to the face and settings panel with only SDK deps; `rabble_ui.c` clean. This is the demo.
3. A3: clock and Wi-Fi/sleep settings in the panel, so a user can set the device up with no console.
4. A4/A5: tap-to-talk home and a free-tier voice backend, so it speaks. Needs B-25 and the BOOT fix or a mic icon.
5. B: manifest, SPDX lint, include lint, palette and brand split, then W8/W9/W10 as Mark rules.
6. C last, with the lawyer; D in parallel when hands are free.

## Licence marker convention (S308)

Everything is SA now. A file that will flip to Apache-2.0 carries a second header line directly under the copyright line:

`/* Open-transition: Apache-2.0 (planned flip; see Pocket-Foundling-Open-App-Plan.md) */` (`#` comment in CMake/Kconfig/scripts).

- **Grep to list the flip set:** `grep -rl "Open-transition:" firmware/`. Today: `sdk/open_entity_default/` only.
- **No marker = stays SA** (RaBbLE app, `nebula_lite` middleware, anything not yet classified).
- **Do not mark Meta-derived files** (`influence` / `derived` rows in the Split Manifest) until they are clean-roomed: marking is a promise to flip. Marking the rest of `sdk/` and `boards/` is one mechanical pass after Mark approves the manifest.
- Flip day: one commit replaces the SA line and the marker with `SPDX-License-Identifier: Apache-2.0`, adds the SDK `LICENSE` and `NOTICE`, and `ops/spdx-lint.py` (not written yet) enforces that no marked file is still SA and no unmarked file is Apache.

## Decisions

Resolved (Mark, S308): name = Foundling (internal); licensing deferred, all SA; SDK marked, not flipped; reusing generic app screens is fine while everything is SA.

Still open for Mark:
1. Does the demo need voice, or is face + settings + clock enough to show?
2. Which of `sdk/` and `boards/` gets the marker, once the manifest is approved?
3. Public name (D3) and the lawyer's view on Foundling/RABBLE.
