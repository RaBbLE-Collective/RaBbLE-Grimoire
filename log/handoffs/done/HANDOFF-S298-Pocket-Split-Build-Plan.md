> **Status (S320, 2026-11-09): SUPERSEDED by log/plans/Pocket-Core-Apps-Reorg-Plan.md (S311). P-series never closed out.** Kept for reference, not deleted.

# HANDOFF-S298b: Pocket clean split, build plan (v0.3)

> Cold start for a fresh agent. Written 2026-11-02 (S298, continued). Supersedes the "Next steps" of `HANDOFF-S298-Pocket-Open-SDK-Split.md`; read that one for the audit headline and the uncommitted-file list. Nothing here is committed. Mark's rulings are working assumptions until the lawyer reads them.

## Goal (Mark)

Publish an **open SDK** and the **RaBbLE app** under two licences, with the ESP32 devices usable and flashable by other users. A fresh clone builds and flashes from the README alone.

## Rulings (Mark, 2026-11-02)

- **Licences:** SDK and generic (non-RaBbLE) UI = Apache-2.0. RaBbLE app = Sovereign Accord. `nebula_lite` ships as **SA middleware** (third tree) so NeBuLA is not tainted with Apache. The SDK never depends on SA code.
- **Meta lines (D6 = no):** clean-room output carries no Meta copyright line. Meta lines only on files that remain `derived`. Influence is recorded in NOTICE/PROVENANCE only. Apache §4 requires keeping Meta's notice on genuinely derived files, so the fix for a derived file is to clean-room it, not to relabel it.
- **Clean room reaches the SDK too:** the SDK should be mainly Mark's own with Meta as influence/reference.
- **Licensor:** The RaBbLE Collective is not a registered entity; it is Mark's DBA/public GitHub identity. Wording and trade-name/LLC question go to the lawyer. "RABBLE" was filed by others in class 9 (memory): raise with the lawyer for D3.
- **Default (SDK) face:** two white **true ellipses** (not rounded rects), no portals, rounder and less tall than RaBbLE's eyes, one uniform outline colour. Outline = user-picked from a **short list of named pastels** (Kconfig default plus runtime setting). Blinks. Poses differ by eye position and size only. Colour changes only for warning/error (fixed amber/red constants). Plain LVGL, written fresh from this spec, not lifted from the `rabble_ui.c` canvas face. Draw: analytic anti-aliased canvas fill, or non-uniform scaled circle if CrumBbLE measures it cheaper on device.

## Findings that shape the build

- `rabble_ui.c` has **no avatar code** (9 generic hits vs the Jollybot files). Its real influence is the ~40-line sleep/brightness/cover/touch-wake block (~lines 509-568, matching `muse_ui.*`).
- The SDK has **no pcf85063 or qmi8658 driver**. pcf85063 predates the SDK (2026-08-08). Only axp2101 has a Meta counterpart (`muse_pmu.c`) and it was clean-roomed (W2, `97312a3`). Check qmi8658's header at `42ae6d9` before the manifest records it.
- Overlap % cannot separate influenced from original files: files from Aug 8 score 13-15%; `rabble_ui.c` is 12.3%, `rabble_beam_score.c` 15.4%. Classify from transcripts and clean-room records, not the number.
- `nebula_lite` is the whole 60 fps face (eyes, portals, mesh, strands, ring, glass text, Orbit). It lives in `sdk/rabble_render` today; only `app/RaBbLE` and `panel_bench` call it. Coupling to the SDK is the board vtable (`direct_rows`, `ui_texture` in `rabble_board.h`).
- Publication blockers (from the QuiBbLE review): the Grimoire repo is **PUBLIC**; the Provenance Record and `cleanroom/audit-2026-11-02/` are untracked there, and deliberately NOT committed (also held back: `Open-Layer-and-Positioning-Notes-2026-11-02.md` and their lines in `INDEX.md` / `log/plans/CONTEXT.md`; re-add those index lines when Mark rules on where they live). `firmware/NOTICE` (committed) says everything is RaBbLE's own: false for any `derived` file. gitleaks scanned 126 commits; 137 across all refs: rescan with `--log-opts="--all"`. No signing key is configured for the signed `pre-split` tag. Build config (`sdkconfig.defaults`, Kconfig, CMake) was written after reading the SDK's and was never measured. Golden vectors live in the public Grimoire and must be vendored into the SDK test tree with a licence. `git subtree` cannot export this layout with history; exports are `filter-repo` rewrites with new SHAs, so the monorepo is the evidence repo.

## Target layout

| Tree | Licence | Contents |
|---|---|---|
| `sdk` (drivers, boards, sdk/*, test, ops, panel_bench stub) | Apache-2.0 | hardware, core, audio, net transport, store, motion, power, LVGL port, entity hook, default face, generic screens, vendored vectors |
| `middleware/nebula_lite` | SA | the 60 fps entity renderer; registers against the entity hook |
| `app/RaBbLE` | SA | face semantics, sCoRE protocol (D5 pending), wordmark, brand palette, Orbit |

Lints (CI gates): no SA file or include under the SDK tree; every file has an SPDX tag; no brand values in the SDK (hexes, wordmark, URLs; `rabble_` identifiers allowed); no `Meta` string under the SA trees; gitleaks clean.

## Build plan

Rule: **the builder never verifies; fixes go back to the builder as behaviour.** Any clean-room implementer is a fresh agent that has not read the SDK, `apache/` history, or the influenced file.

**P-1 Hold publication (now).** Stage nothing from the Provenance Record or audit into the public Grimoire. Mark decides where they live until the lawyer reads them. Flag `firmware/NOTICE` and the public Clean-Room Plan wording as stale.

**P0 Baseline (small).** Pin the SDK clone at `b139b45`; save baseline numbers (8.0%). gitleaks `--all`. Decide signing key (GPG or SSH; personal or Collective). Branch `sdk-split` off `new-horizons`; signed tag `pre-split`. Freeze Pocket feature work, or merge each component back to `new-horizons` as it lands.

**P1 Manifest (script join, not fan-out).** Script joins `out-HEAD.txt`, the `TRANSCRIPTS-port.md` table, W-wave records and `git log` first-add dates into `RaBbLE-Pocket/RaBbLE-Pocket-Split-Manifest.md`. Columns: path, side (`sdk`/`middleware`/`app`), Meta status (`original` / `clean-roomed W#` / `influence` / `derived` / `non-Apache-Meta-read`), licence, action. Include build config, `sim/`, `ops/`, `companion-app/`, `planning/`. CoBbLE assembles; Mark approves. Gate: every tracked source file has a row.

**P2 Track L: clean room (parallel with P3 prep).** Specs are written by an agent that has not read the SDK, from public specs.
- W8: `rabble_beam_score.c` session layer from `RaBbLE-Pocket-Beam-Protocol.md` and `ops/beam-echo.py` vectors.
- W9: the `rabble_ui.c` sleep/brightness/cover/touch-wake block.
- SDK `derived` set, by overlap: board vtable `rabble_board.h`, build config, then any file the manifest still marks `derived` or `influence`.
- Gate per wave: implementer transcript archived; firewall record; overlap windows metric; CrumBbLE device or host test.

**P3 Track P: product boundary (CoBbLE, one component per commit, disjoint files, each with a mini device gate).**
1. Entity hook in the SDK (`direct_rows`/`ui_texture` plug-in point; entity-active logic out of `rabble_ui.c`).
2. Move `sdk/rabble_render` to `middleware/nebula_lite`; `panel_bench` gets a stub or moves with it.
3. Default face (spec above) plus the short pastel list and runtime setting.
4. Neutral palette in the SDK; brand palette to `app/RaBbLE/RaBbLE_palette.h`; `nl_list.h`/`luts.c` take colours from an app header.
5. Brand values out of the SDK (device name default, Kconfig titles, wordmark, captions, protocol id, `rabble-os.local`).
6. Beam split per D5 (app-only needs W8 first; SDK optional backend needs none).
7. Generic screens to the SDK as `rabble_ui_kit`.
8. Extend `ops/sdk-layers.py` to fail on SDK-to-SA includes.

**P4 Licence sweep (once, after P2 and the manifest settle).** Apache `LICENSE` and `NOTICE` at the SDK root; Accord `LICENSE` on the SA trees; SPDX on every file; Meta copyright lines only on `derived` rows; fix `firmware/NOTICE`; `PROVENANCE.md`; README provenance section (no "nothing derived remains"). Gate: new `ops/spdx-lint.py` plus the lints above.

**P5 Meta-free proof.** CrumBbLE re-runs overlap on the SA trees and the SDK with the Aug-8 control set as calibration; NiBbLE reviews. Use the windows metric and transcript facts, not the 5% line. Gate: SA trees have zero influence-classified files; report in `cleanroom/audit-<date>/`.

**P6 Release hygiene.** Vendor golden vectors into SDK tests; gitleaks on every public repo, all branches and tags; hosting URLs are not secrets (already public), focus on tokens/auth/spend caps; firmware/OTA signing keys; CONTRIBUTING (DCO vs CLA: Mark); CI (build, host tests, layer lint, SPDX lint, gitleaks); dry-run publish to a private mirror; fresh clone builds and flashes from README alone.

**P7 Hardware gates (Mark's hands).** 1.75-B: 60 fps idle, >=30 fps busy/turning, voice turn with beam live, NVS compatibility, Orbit gestures, sleep/power-off; default face on a build without `nebula_lite`.

**P8 Publish.** Lawyer review (NOTICE, PROVENANCE, header-compaction history, Meta-line wording, licensor, trademark); dated post; signed tags; export SDK (`filter-repo`, new SHAs, README links the `pre-split` evidence tag).

## Crew

| Phase | Organ |
|---|---|
| P0, P1 | CoBbLE (script + manifest); GoBbLE only for read-only lookups |
| P2 | fresh clean-room implementers (CoBbLE-type, never SDK-tainted); spec author is separate; CrumBbLE verifies |
| P3 | CoBbLE, one component per commit; QuiBbLE reviews the entity hook design first |
| P4 | CoBbLE (mechanical) |
| P5 | CrumBbLE measures, NiBbLE reviews |
| P6 | CoBbLE + Mark; Archivist logs |
| P7 | Mark |

## Progress since the first commit (S298, later)

- **D5 ruled:** the sCoRE beam *protocol* is documented in the sCoRE docs (not the SDK docs); its implementation stays app-side (SA). The SDK keeps a generic transport. W8 (clean-room `rabble_beam_score.c`) is therefore required before it can sit under a clean SA header.
- **P0 partly done:** `gitleaks git --log-opts="--all"` on Pocket: 126 commits scanned (137 refs-wide count = 10 merges + 1), no leaks, no tags. Still open: signing key, `sdk-split` branch, `pre-split` tag (Pocket has an uncommitted `README.md` change; branch after Mark decides).
- **P1 draft generated** (held, untracked with the other provenance docs): `RaBbLE-Pocket/RaBbLE-Pocket-Split-Manifest.md` via `RaBbLE-Pocket/cleanroom/audit-2026-11-02/scripts/manifest.py`. 469 rows: 70 clean-roomed (W0-W6), 347 original, 15 `influence`, 17 `influence?` (CMakeLists added after the SDK date), 8 `original?` (>=15% overlap, review). The substantive influenced set is small: `rabble_ui.c` (lifecycle block), `rabble_beam_score.c`, `rabble_board.h` (+ test stub), and build config (`sdkconfig.defaults`, `Kconfig`, `idf_component.yml`, `partitions.csv`). Files still to eyeball: `rabble_device.h` (66.7%), `rabble_beam*.{c,h}` (15-33%), `rabble_notes.c`, `nl_scene.h`, `rabble_shot.h`.
- **Extra third party:** motion/QMI8658 were modelled on Waveshare's Apache qmi8658 component and the CO5300 init data comes from Waveshare's board package: NOTICE rows (not Meta).
- Next: Mark approves the manifest, then decide whether W8/W9/board-vtable/build-config clean rooms go ahead.

## Repo shape (Mark, 2026-11-02)

**RaBbLE-Pocket stays the monorepo** supporting the gadget layer (SDK, middleware, app, sim, ops, companion app). The public SDK is an export of its SDK tree (D2 hybrid: monorepo = evidence repo with full history; export = `filter-repo` rewrite with new SHAs). Do not split the monorepo. Mark: the public SDK **may later become its own repo**, tracked separately; until then it lives in the monorepo. Keep the SDK tree self-contained so that move is mechanical: its own `LICENSE`, `NOTICE`, `README`, CI and vendored test vectors, no includes or paths pointing out of it, and a repeatable export script (`ops/export-sdk.sh`, to write in P6) that produces the same tree each run.

## SDK publication: export first (Mark, 2026-11-02)

Decision: start with a **tree export** from the monorepo; promote to a separate repo only if outside contribution justifies it.

- **Source of truth:** RaBbLE-Pocket monorepo (full history, evidence repo, signed `pre-split` tag). Develop there; the public SDK repo is a published copy.
- **`ops/export-sdk.sh` (write in P6):** takes the SDK tree list (drivers, boards, sdk/*, test, ops subset, panel_bench stub, SDK `LICENSE`/`NOTICE`/`README`/CI), runs lints (SPDX, no SA files or includes, no brand values, gitleaks), and writes a clean tree to a target dir. Idempotent: same input commit gives the same tree. Output is a snapshot commit tagged `sdk-<version>`; its message records the monorepo commit SHA it came from.
- **History in the export:** default = one snapshot commit per release (no rewritten history, so no Apache-notice or header-compaction history is exposed or mangled). A `filter-repo` history export is an option only if Mark wants SDK history public (D4); it yields new SHAs and loses tag signatures.
- **README provenance link:** the public SDK README and `PROVENANCE.md` point at the monorepo `pre-split` tag as the evidence record.
- **Contributions:** until the SDK is promoted to its own repo, PRs to the public repo are applied back to the monorepo by hand (or issues only). State this in CONTRIBUTING. Decide DCO vs CLA before accepting any PR.
- **Promotion trigger (later):** outside PRs become routine, or the app and SDK diverge in release cadence. Then the SDK repo becomes primary, Pocket consumes it as a pinned dependency, and the export script is retired.
- **Gate (P6):** a fresh clone of the exported tree builds and flashes from its README alone and passes host tests with vendored vectors; two consecutive exports of the same commit are byte-identical.

## Bug to debug in the same effort: BOOT button does not start recording

Mark: pressing the BOOT button does not trigger the firmware to record; unknown whether hardware or software. Do this early (it also gates every P7 hardware check), and before the split moves code around so the baseline is known.

Facts from the code (firmware at `new-horizons`, checked 2026-11-02):
- BOOT is GPIO0 (`BOOT_GPIO`, `boards/rabble_waveshare_175b/bsp_waveshare_175b.c:25`), initialised with `rabble_gpio_button_init(&s_boot, BOOT_GPIO)` (line 36); board vtable `.talk_button = "boot"`, `.aux_button = "pwr"` (lines 242-243).
- The talk handler is in `app/RaBbLE/rabble_input.c` (`change_asleep(false, rabble_board->talk_button)` near line 191 wakes on it). `rabble_input.c` and the whole board layer were rebuilt in clean-room waves W2/W6 and moved in the SDK steps S10a/S11 (2026-10-25/28), so a software regression is plausible.
- GPIO0 is an ESP32-S3 strapping pin: fine at runtime, but anything that drives it or a pull config change can mask presses.

Suspects, cheapest first:
1. **Is it the press or the path?** Add or use a console command / log line that prints the raw GPIO0 level and the debounced button event. Hold BOOT and watch serial (keep the serial reader reading; see `project_pocket_gadget_port` memory). If the level never changes: hardware (switch, solder, strap resistor) or pin config. If the level changes but no event: the button driver. If the event fires but no recording: the input/voice/beam path.
2. **Does PWR work?** The aux button shares the same code path; if PWR gives events and BOOT does not, it is GPIO0-specific (pull-up, strap, or init order).
3. **Sleep/wake state:** `rabble_input.c` treats a talk press as wake first; check that a press while awake reaches `rabble_voice` (state machine in `rabble_state`), and that recording is not gated on beam/Wi-Fi/token state (a missing sCoRE token may silently refuse to start).
4. **Bisect:** the voice path worked on the S243-S264 builds. Build and flash `42ae6d9`, `6c3b78b^` (just before W6 rev 2), `300cf7e` (W7) and `HEAD`; the first bad commit names the cause. Use `ops/build-flash.sh`; flash work must run under panel prio (see the S264 note).
5. **Host test first:** `firmware/test` has input tests; add a case for BOOT press -> record start with the board vtable stubbed. A host test that passes while the device fails points at hardware or board init.
6. **Hardware check:** continuity of BOOT to GPIO0 and GND with the case open; compare with a second 1.75-B if one exists. Holding BOOT through reset should still enter the ROM download mode (proves the switch and the strap).

Acceptance: a recorded voice turn started by BOOT on the device, plus a host test that fails without the fix. CoBbLE fixes, CrumBbLE reproduces on the device (Mark's hands for the physical checks), NiBbLE reviews.

## Pending decisions (Mark)

D1 Apache from day one (leaning yes); D2 one repo vs split (monorepo stays the evidence repo; SDK export is a rewrite); D3 SDK name and trademark policy for `rabble_` identifiers in an Apache SDK; D4 history: keep, or keep private as escrow plus a published hash commitment; D5 sCoRE protocol app-only vs SDK optional backend; signing key; DCO vs CLA; where the Provenance Record lives meanwhile.

## First actions for the next agent

1. Re-run QuiBbLE on this v0.3 build plan (Opus), especially the entity hook and the `nebula_lite` move.
2. P-1 and P0 (hold publication, gitleaks `--all`, branch, baseline).
3. P1 manifest script. Show Mark the `derived` list before any clean room is scheduled.
4. Claim the next S-number with `bash spells/session-number.sh claim <topic>` and stage explicit paths only (`mine.sh`); other sessions have unrelated dirty files.

## Gotchas

- `layerctl` layer is `base`, not `core`.
- Overlap numbers depend on the SDK commit: pin `b139b45`.
- Missing transcripts: spec authors for W2, W5, W6 (rev 1 and 2) and the parent-session firewall turns.
- This session (S298) read the SDK and the influenced files: it must not implement or specify clean-room work.
