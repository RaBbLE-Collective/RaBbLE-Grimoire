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
