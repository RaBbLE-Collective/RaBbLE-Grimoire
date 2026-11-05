# HANDOFF-S312: layers plan confirmed; W8/W11 specs near implementer-ready

> Written 2026-11-05 (S312). Cold start. Replaces the review job in HANDOFF-S311 (done).

## Done
- **R0 review with Mark finished.** All answers in `log/plans/Pocket-Core-Apps-Reorg-Plan.md` section 13 plus the rulings paragraphs after it (core/ name, beam SA in entities/RaBbLE, input to core as mechanisms, LVGL as driver behind a seam, Apache-2.0 flip intended, no lawyer review, Foundling not trademarked, slot kept). Roadmap R1-R10 stands; **plan is v2 with answers, not re-reviewed by QuiBbLE** (cheap pass).
- `log/plans/Pocket-Seam-Slot-LVGL-Design-Note.md`: panel/touch split adopted, LVGL types leave the board contract, generic enum for the button hint. Header text still says "Not decided / provisional": tidy.
- Firewall reviews (QuiBbLE/Opus) done twice per wave. Reports in `/tmp/rabble-crew/` (may vanish; they quote Meta passages, never commit them).
- **W8 spec** (`RaBbLE-Pocket/cleanroom/w8-beam-score.spec.md` + `w8-integrator-notes.md`): revised twice. Final narrow re-review (QuiBbLE-W8c) was launched; **verdict not seen**: `/tmp/rabble-crew/w8-firewall-review-3.md`.
- **W11 spec** (`w11-board-vtable.spec.md`): rev 3 reviewed SEND BACK (small); **rev 4 was being written when the session stopped** (adopt panel/touch split, section 8 moved to new `w11-integrator-notes.md`, marker string, screen.start loosened to "logs; may return NULL"). Check that it finished and that `w11-integrator-notes.md` exists, then run one narrow QuiBbLE re-review.

## Next (on track: yes, W8 can implement soon)
1. Read `w8-firewall-review-3.md`; if APPROVE, update the old strings in `rabble_beam.c`, w3-beam/w4-voice/w1-text specs and tests (integrator, per `w8-integrator-notes.md`), then run the W8 clean-room implementer (fresh Opus/Sonnet in `~/RaBbLE-Cleanroom`, spec only; export excludes the notes file), overlap gate (`git show 984c554^:ops/cleanroom-overlap.py`, `--sdk ~/RaBbLE-Cleanroom/muse-ref/esp32`, gate 5%).
2. W11: finish rev 4, narrow re-review, implementer writes header + two stubs + helper rename only; integrator does renames.
3. Then R1 (pure move) on Mark's go. Check Foundling session idle and run `bash spells/mine.sh` first.
4. Remaining small items: gitleaks-scan then commit the hold-outs (Mark ruled public Grimoire); `HANDOFF-parked-*` placeholders (400 bytes of `x`) safe to delete, ask; old plans still mention a lawyer (Open-SDK-App-Separation, Foundling-Open-App, Sovereign-Accord-v2): add a superseded note; Q6 board-choice location (default project level).

## Held, not committed (on purpose)
`cleanroom/w8-*.md`, `w10`, `w11` specs (unreviewed final / in flight), Provenance Record, Split Manifests, `audit-2026-11-02/`. Never `git add -A`.
