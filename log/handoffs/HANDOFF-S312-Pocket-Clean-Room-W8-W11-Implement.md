# HANDOFF-S312: layers plan confirmed; W8/W11 specs near implementer-ready

> Written 2026-11-05 (S312). Cold start. Replaces the review job in HANDOFF-S311 (done).

## Done
- **R0 review with Mark finished.** All answers in `log/plans/Pocket-Core-Apps-Reorg-Plan.md` section 13 plus the rulings paragraphs after it (core/ name, beam SA in entities/RaBbLE, input to core as mechanisms, LVGL as driver behind a seam, Apache-2.0 flip intended, no lawyer review, Foundling not trademarked, slot kept). Roadmap R1-R10 stands; **plan is v2 with answers, not re-reviewed by QuiBbLE** (cheap pass).
- `log/plans/Pocket-Seam-Slot-LVGL-Design-Note.md`: panel/touch split adopted, LVGL types leave the board contract, generic enum for the button hint. Header text still says "Not decided / provisional": tidy.
- Firewall reviews (QuiBbLE/Opus) done twice per wave. Reports in `/tmp/rabble-crew/` (may vanish; they quote Meta passages, never commit them).
- **W8 spec** (`RaBbLE-Pocket/cleanroom/w8-beam-score.spec.md` + `w8-integrator-notes.md`): revised twice. Final re-review (W8c): SEND BACK on one leftover string, which was deleted afterwards, so **W8 is approvable with no further round** (report `/tmp/rabble-crew/w8-firewall-review-3.md`). Nits left: :51 say begin/end/cancel exempt from the 16-request limit; :111 point to 5.2's 8 s bound; section 15 lists F-10 before F-9. **Mark should read the replacement UI strings once** (chosen by an agent, in `w8-integrator-notes.md`).
- **W11 spec** (`w11-board-vtable.spec.md`): rev 3 reviewed SEND BACK (small); **rev 4 written** (not yet re-reviewed): panel/touch split, LVGL-free contract, `rabble_anchor_t` enum, group `ctl` renamed `keys`, section 8 moved to `w11-integrator-notes.md`. CoBbLE INVENTED `panel.write(x0,y0,x1,y1,px,last)` and `rabble_touch_event_t` (polled `touch.next`): Mark to confirm/amend. Open: who writes the interim LVGL glue so the BSP behaves the same until the real driver exists (spec 12.9). Next: one narrow QuiBbLE re-review of rev 4.

## Next (on track: yes, W8 can implement soon)
1. Read `w8-firewall-review-3.md`; if APPROVE, update the old strings in `rabble_beam.c`, w3-beam/w4-voice/w1-text specs and tests (integrator, per `w8-integrator-notes.md`), then run the W8 clean-room implementer (fresh Opus/Sonnet in `~/RaBbLE-Cleanroom`, spec only; export excludes the notes file), overlap gate (`git show 984c554^:ops/cleanroom-overlap.py`, `--sdk ~/RaBbLE-Cleanroom/muse-ref/esp32`, gate 5%).
2. W11: finish rev 4, narrow re-review, implementer writes header + two stubs + helper rename only; integrator does renames.
3. Then R1 (pure move) on Mark's go. Check Foundling session idle and run `bash spells/mine.sh` first.
4. Remaining small items: gitleaks-scan then commit the hold-outs (Mark ruled public Grimoire); `HANDOFF-parked-*` placeholders (400 bytes of `x`) safe to delete, ask; old plans still mention a lawyer (Open-SDK-App-Separation, Foundling-Open-App, Sovereign-Accord-v2): add a superseded note; Q6 board-choice location (default project level).

## Held, not committed (on purpose)
`cleanroom/w8-*.md`, `w10`, `w11` specs (unreviewed final / in flight), Provenance Record, Split Manifests, `audit-2026-11-02/`. Never `git add -A`.

## S313 addendum: header-overlap scan, Meta notice decision (Mark to rule)

S313 scanned all 303 tracked Pocket files against Muse Gadget SDK `b139b45` and the Waveshare example repo (token shingles: identifier-exact 10, normalized 24; scanner and results were in `/tmp/rabble-crew/scan/`, may vanish). Result: `app/` and `drivers/` clean against both; no copied implementation runs outside ESP-IDF call sequences, the IMA step table and the CO5300 init table. Full summary is in the S313 session entry.

**Decision for the P4 licence sweep: for these 13 `firmware/sdk/` headers, either (a) clean the header (reword the declaration shape, as W8/W11 do), or (b) attach a single Meta copyright line (Apache, SDK tree).** They mirror `muse_X.h` structure (normalized similarity 40 to 89%), which is API shape and partly function-dictated:
`rabble_battery.h`, `rabble_beam_priv.h`, `rabble_wifi_known.h`, `rabble_state.h`, `rabble_audio.h`, `rabble_wifi.h`, `rabble_beam.h`, `rabble_beam_text.h`, `rabble_adpcm.h`, `rabble_text.h`, `rabble_console.h`, `rabble_board.h`, `rabble_settings.h`.
Recommendation: (b), since D6 says the fix for a `derived` file is to clean-room it or keep the line, and a header mirror is cheap to label but costly to rewrite (the API is the contract).

**It does touch three small `.c` files** (light, not copied expression): `rabble_adpcm.c` (31% id; one 180-token run, the IMA step table), `rabble_console.c` (28%), `rabble_lv_mem.c` (29%). Give them a PROVENANCE row (reference/influence); a Meta line only if Mark prefers the conservative route.

**Accord-only judged clean, record in PROVENANCE:** `app/RaBbLE/rabble_app.c` (41% normalized vs Muse, longest run 27 tokens), `drivers/rabble_axp2101/include/rabble_axp2101.h` (25%, header shape only).

**Waveshare (Apache-2.0, build-time registry dependency, not redistributed):** one item, the CO5300 init command table (149 to 242-token runs) in `boards/rabble_waveshare_175b/bsp_display.c`, `panel_bench/main/panel_bench.c`, `hw_test/main/hw_test.c`. Plan: Apache header plus Waveshare attribution on `bsp_display.c`; move `panel_bench` and `hw_test` under `boards/` or `tools/`; PROVENANCE row for the table. Add the two Waveshare components and their licence texts to the release licences page.

Target layout Mark stated: entity app clean/Accord; SDK/core Apache or inherited; board and driver code in `boards/` and `drivers/`, separate from inherited code. The scan supports it.
