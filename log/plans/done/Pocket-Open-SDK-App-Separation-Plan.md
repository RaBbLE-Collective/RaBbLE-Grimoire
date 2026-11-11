> **Status (S322, 2026-11-10): SUPERSEDED by `Pocket-Core-Apps-Reorg-Plan.md` (S311), which replaces the sdk/app split.** Kept for reference, not deleted (S318 triage).

# Pocket Open SDK / RaBbLE App separation and release plan

> Status: DRAFT v0.2, 2026-11-02. **Independent Opus (QuiBbLE) review NOT yet done**: the first attempt hit the session limit (resets 11:50am ET); re-run it before P2 starts. Decisions marked **Mark**.
> Mark, 2026-11-02: `rabble_` identifiers, file names and prefixes may stay in the SDK. Only brand *values and assets* must leave it.
> Goal: every line with Meta ancestry or influence lives in the Apache-2.0 SDK, with attribution; `app/RaBbLE` is Meta-free and stays Sovereign Accord (SA). Then publish both.
> Evidence base: `RaBbLE-Pocket/RaBbLE-Pocket-Provenance-Record.md` and `RaBbLE-Pocket/cleanroom/audit-2026-11-02/`. Boundary groundwork: `RaBbLE-Pocket/RaBbLE-Pocket-Open-SDK-Inventory.md` (S288; its "source-available" premise is superseded by decision D1). Strategy: `log/plans/Open-Layer-and-Positioning-Notes-2026-11-02.md`. Entity format: `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Format.md`.

## End state

1. **SDK** (`firmware/drivers`, `boards`, `sdk`, `panel_bench`, `test`, build ops): Apache-2.0, `LICENSE` + `NOTICE` at its root, Meta attribution on every file with ancestry or influence, neutral default entity (Foundling, internal name), neutral palette, no brand values or assets (colours, wordmark, captions, URLs; `rabble_` identifiers are allowed), no sCoRE protocol.
2. **App** (`firmware/app/RaBbLE` and whatever of `main/` is app glue): SA, no Meta influence, depends on the SDK only through public headers.
3. **Gates in CI/ops**: SDK never includes app; every file carries an SPDX tag; overlap check shows no unattributed Meta influence in app; gitleaks clean; brand-value lint on SDK (hexes, wordmark, URLs; not identifiers).
4. **Record**: root `PROVENANCE.md` + `NOTICE`, dated public post, signed tags, history kept.

## Decisions (Mark)

| # | Decision | Recommendation |
|---|---|---|
| D1 | SDK licence: Apache-2.0 from day one (reverses S288 "source-available") | Yes; matches Meta's licence, removes the SA/Apache conflict on derived bits |
| D2 | One repo with two licensed trees, or SDK as its own repo and app as a consumer | Start as one repo with per-tree `LICENSE` + SPDX; split by `git subtree`/export when publishing the SDK (history preserved). The inventory already assumes a separate export |
| D3 | Public SDK name (not BLE, not Foundling until cleared) and whether "RaBbLE Pocket" stays the device brand | Keep internal names in code until chosen; name only touches `README`, Kconfig titles, device-name default |
| D4 | History: keep full history on publish | Keep (it is the provenance evidence; Apache notices are in those commits). Re-confirm with a lawyer |
| D5 | sCoRE protocol (`rabble-beam/0`) in the SDK as an optional documented backend, or app-only | App-only; the SDK ships a generic transport with a configurable protocol id |

## Rulings (Mark, 2026-11-02, S298 continued) — working assumptions, lawyer review still pending

- **D1/D2 leaning:** SDK and the non-RaBbLE (generic) UI are Apache-2.0; the RaBbLE app is Sovereign Accord. SDK never depends on SA code.
- **D6 = no:** clean-room output carries no Meta copyright line. Meta lines only on files that remain `derived`; influence is recorded in NOTICE/PROVENANCE only.
- **Clean room reaches the SDK too:** goal is an SDK that is mainly Mark's own with Meta as influence/reference, not a pile of attributed derivatives. Prioritise the `derived` set by overlap (drivers, board vtable/BSP, build config).
- **nebula_lite ships as middleware under SA**, a third tree between SDK and app, so NeBuLA is not tainted with Apache before Mark chooses. SDK reaches it only through an entity hook.
- **Licensor:** The RaBbLE Collective is not a registered entity; it is Mark's DBA/public GitHub identity. Copyright-holder wording and who grants Apache go to the lawyer.
- **SDK default face (Mark):** two white ellipses, no portals, rounder and less tall than RaBbLE's eyes, one uniform outline colour. True ellipses (not rounded rects), blinks, outline colour is user-defined from a pastel palette (Kconfig default plus runtime setting), colour changes only for warning/error, poses differ by eye position and size only. Plain LVGL, written fresh from this spec (not lifted from the `rabble_ui.c` canvas face). Nothing in the Apache tree should read as the RaBbLE entity.
- **Driver provenance:** the SDK has no pcf85063 or qmi8658 driver (pcf85063 predates the SDK; qmi8658 has no Meta counterpart); only axp2101 has one (`muse_pmu.c`), and it was clean-roomed in W2. Any Meta line on these at `42ae6d9` was a blanket stamp. Verify qmi8658's header at `42ae6d9` before the manifest says so.
- **Publication = tree export first** (D2 resolved): monorepo stays source of truth; `ops/export-sdk.sh` writes a lint-gated snapshot of the SDK tree per release; separate SDK repo only on promotion. Detail: HANDOFF-S298-Pocket-Split-Build-Plan.
- **D5 resolved:** sCoRE beam protocol documented in the sCoRE docs; implementation app-side (SA); needs W8 clean room.
- QuiBbLE review (S298) findings still to fold: hold Provenance Record out of the public Grimoire; P1 as a script join; Track L (clean room W8 beam, W9 face lifecycle, SDK derived set) before the licence sweep; vendor golden vectors; gitleaks `--all`; signing key; `firmware/NOTICE` is currently false.

## Workstreams

Phases are sequential unless marked parallel. Each phase ends in a gate; a failing gate goes back to the builder as behaviour, not code.

### P0: Freeze and baseline (small, do first)
- Pin the SDK reference: `~/RaBbLE-Cleanroom/provenance-audit-2026-11-02/sdk` at `b139b45`; scripts in `RaBbLE-Pocket/cleanroom/audit-2026-11-02/scripts/`. Record the baseline numbers (HEAD 8.0%).
- Branch `sdk-split` off `new-horizons`. Tag `pre-split` (signed).
- Gate: `git status` clean, baseline numbers saved.

### P1: Classify every file (read-only, parallel by directory)
- One table, `RaBbLE-Pocket/RaBbLE-Pocket-Split-Manifest.md`: per file, side (SDK/app), Meta status (none / influence / derived-attribute), licence tag, action.
- Inputs: the Open SDK inventory, overlap `out-HEAD.txt`, port-session table (`TRANSCRIPTS-port.md`), the board-vtable finding.
- Rule: **influence or ancestry means SDK side, with attribution**. Known cases: `rabble_beam_score.c`, `rabble_ui.c`, `rabble_board.h`, `rabble_axp2101.c`, `bsp_display.c`, `bsp_waveshare_175b.c`, `rabble_wifi_radio.c`, `rabble_shot.c`, `rabble_pomo.c`, `rabble_orbit_logic.h`, `rabble_setup/input/app` (ported, redone).
- Gate: every tracked source file has a row; Mark approves the manifest.

### P2: Make the boundary real in code (builder; sequential by component)
- **Neutral palette** (S288): SDK gets pastel role palette; brand palette moves to `app/RaBbLE/RaBbLE_palette.h`; `nl_list.h` and `luts.c` take colours from an app-supplied header.
- **Brand values out of SDK** (`rabble_` prefixes, file and symbol names stay; Mark 2026-11-02): device name default, Kconfig menu titles, UI wordmark, user captions (`rabble_voice.c:374`), protocol id (`rabble-beam/0`) and `rabble-os.local` default.
- **Beam split**: generic transport + offline outbox + capture in SDK (Apache, attributed); sCoRE protocol layer (framing, auth, session) in `app/`, SA.
- **UI split**: generic LVGL screens/widgets (clock, level, pomodoro, setup, settings/orbit logic) to SDK as `rabble_ui_kit` (attributed); entity, wordmark, brand theme stay in app.
- **Entity hook**: SDK defines the entity interface (mesh arrays, expression, scene) with a neutral default entity; `app/RaBbLE` provides the RaBbLE entity. Matches the Entity-Format spec.
- Gate: SDK builds and runs alone with the neutral entity; app builds against it; `ops/sdk-layers.py` extended to fail on any SDK→app include; host tests in `firmware/test` pass; sim renders both entities.

### P3: Licence sweep (builder, single pass)
- `LICENSE` (Apache text) at SDK root; `LICENSE` (Accord) at app root; SPDX line on every first-party file (`Apache-2.0` or `LicenseRef-RaBbLE-Sovereign-Accord`), replacing the current Accord-only header.
- Restore the Meta copyright line plus "modified by The RaBbLE Collective" on the attributed list from P1 (not on rewritten files).
- `NOTICE` (SDK): Muse Gadget SDK `b139b45`, Apache-2.0, Copyright Meta Platforms; Waveshare board package (Apache) for CO5300 init data; managed-components paragraph.
- Root `PROVENANCE.md` from the Grimoire record; README provenance section updated (no "nothing derived remains" claim).
- Gate: SPDX lint (`ops/spdx-lint.py`, new) passes: no file untagged, no `app/` file tagged Apache, no `sdk/` file tagged SA, no `Meta` string in `app/`.

### P4: Meta-free proof for the app (CrumBbLE runs, NiBbLE reviews)
- Re-run the overlap tools on `app/RaBbLE` only; each file over 5% classified by hand (idiom, datasheet-forced, or influence). Influence means move to SDK or clean-room (CoBbLE, fresh implementer, per the clean-room plan, not the builder who saw the SDK).
- Gate: app has zero influence-classified files; report committed to `cleanroom/audit-<date>/`.

### P5: Release hygiene (parallel with P2-P4 except where noted)
- gitleaks (installed S296) on every repo going public, all branches and tags; custom rule for the beam-token format; rotate anything found; scan again after P2 moves.
- Hosting detail out of public tree: sCoRE URLs/IDs, Render/Cloudflare names; provider code behind adapters.
- Signing: generate RaBbLE firmware/OTA signing keys (never upstream's dev key); sign tags; document verification.
- Names: trademark clearance for the public SDK name and device brand (lawyer); check "Muse Pocket" collision.
- Waveshare: review their open agent programme before pitching; web flasher plan for the 1.75C.
- Public repo hygiene: README split (neutral SDK README; brand README), CONTRIBUTING (Apache, DCO or CLA decision), SECURITY, issue templates, CI (build, host tests, layer lint, SPDX lint, gitleaks).
- Gate: dry-run publish to a private mirror; fresh clone builds from README alone.

### P6: Hardware gates (Mark's hands)
- Flash the split build to the 1.75-B: 60 fps idle, >=30 fps busy and turning (entity gates), voice turn with the beam live, Wi-Fi + NVS compatibility (saved networks and token survive), Orbit gestures, sleep/power-off.
- Gate: checklist signed by Mark.

### P7: Publish
- Lawyer review of NOTICE/PROVENANCE/Accord boundary and the header-compaction history.
- Dated post; signed tags; export SDK (D2); announce. Hosted services and Collective pairing remain RaBbLE-layer.

## Crew assignment

| Phase | Organ | Notes |
|---|---|---|
| P0, P1 | GoBbLE (haiku) fan-out by directory, CoBbLE assembles manifest | Read-only classification; Mark approves |
| P2 | CoBbLE, one component per commit; QuiBbLE reviews design before P2 starts | Files disjoint per component; the beam and UI splits are the risky ones |
| P3 | CoBbLE | Mechanical; one commit per tree |
| P4 | CrumBbLE measures, NiBbLE reviews; implementer for any clean-room is a fresh agent that has not read the SDK | The builder is never the verifier |
| P5 | Mark + CoBbLE for CI; Archivist logs | Lawyer and trademark are Mark's |
| P6 | Mark | Needs the device |

## Risks

- **Influence is a judgment, not a number.** Overlap % cannot prove a file is Meta-free; classification in P1/P4 needs a human call. Mitigation: bias to attribute on the SDK side.
- **Moving files changes provenance.** Splits must be done as moves with history (`git mv`) so blame survives.
- **Bit-rot of the clean-room claim.** The SDK reference clone lives outside the Collective; back it up (and `~/RaBbLE-Cleanroom/transcripts`) before cleaning disk.
- **Regressions on device.** Beam, voice and UI splits touch hot paths; each P2 component needs the P6 checklist before merge.
- **Licence-boundary drift.** Without the lint in P3 the boundary erodes; make the lints CI gates, not conventions.
- **Public name risk.** Foundling is uncleared; keep it internal until the lawyer reports.
- **Agent taint.** Sessions that read the SDK or the original files cannot implement P4 clean-room work (see clean-room plan roles).

## Done when

SDK and app build separately and together; lints green; P4 report shows a Meta-free app; NOTICE/PROVENANCE/README match the code; gitleaks clean on every public repo; Mark has signed P6; lawyer comments folded in.
