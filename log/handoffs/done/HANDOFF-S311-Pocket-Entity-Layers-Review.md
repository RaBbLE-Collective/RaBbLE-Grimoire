> **Status (S320, 2026-11-09): COMPLETE: review done; implementation continues in HANDOFF-S312-Pocket-Clean-Room-W8-W11-Implement.** Kept for reference, not deleted.

# HANDOFF-S311: Pocket entity layers, review and confirm with Mark before any implementation

> Cold start. Written 2026-11-04 (S311). **First job of the next session is a review with Mark, not code.** Read the plan, run the checklist in its section 11 with Mark, record his answers in the plan, then (only on his sign-off) start phase R1.

## Read first
1. `log/plans/Pocket-Core-Apps-Reorg-Plan.md` (the whole plan; 12 sections; section 11 is the review checklist, section 9 the roadmap R0-R10, section 8 the clean-room status).
2. `/tmp/rabble-crew/review-reorg-plan.md` if it still exists: an independent QuiBbLE (Opus) coherence review of the plan against the code. If it is gone, the verdict is folded into the plan (section 10, risk R10).
3. Memory: `project_pocket_core_apps_reorg.md`.

## What happened in S311
- The old crew session died with Mark's battery; three QuiBbLE firewall reviews (W8, W9, W11/W10) hit the usage limit. Only W9's review had been written. W9 was finished solo: 13 review edits applied, one clean-room implementer plus one rework, overlap 2.8%, integrated into `rabble_ui.c`, host suite 33 pass + 1 known XFAIL, RaBbLE app builds. Pocket `9b95e30`, `6abe8c9` (branch new-horizons, not pushed); Grimoire `cd3f27d`, `d68b8a3`.
- **W9 is not flashed.** Spec section 8 (device checklist: boot light, double-tap wake, pocket contact does nothing, button wakes, brightness preview, idle poke) is for Mark's hands.
- Mark then redesigned the firmware shape in conversation; every ruling is in the plan's section 12 and the plan is the single record. Nothing was moved or renamed in the code.

## State of the working trees (do not clobber)
- Pocket: `README.md` modified by another session (the Foundling provenance section); untracked `firmware/hw_test/{build,managed_components,dependencies.lock,sdkconfig}`. The Foundling session (S310, `4c992f9`) edits `firmware/CMakeLists.txt`, `main/`, `app/Foundling`. **Check it is idle** and run `bash spells/mine.sh` before R1.
- Grimoire: held on purpose, never `git add -A`: `RaBbLE-Pocket/RaBbLE-Pocket-Provenance-Record.md`, `...-Split-Manifest*.md`, `cleanroom/audit-2026-11-02/`, specs `w8`, `w10`, `w11` (untracked), `w0-state`, `w2-input`, `w3-settings` (modified, uncommitted edits from the dead session), the `HANDOFF-parked-*` placeholder files (400 bytes of `x`, no content; safe to delete, ask Mark).
- The device (1.75-B) runs **Foundling**, not RaBbLE, since S310. Restore RaBbLE with the esptool write of `~/RaBbLE-backups/pocket-pre-foundling-20261104-0911/ota_0.bin` at `0x20000`, or flash a fresh RaBbLE build to check W9.

## Where the clean room sits (summary; details in plan section 8)
W0-W7 done. W9 done (not flashed). **W8 and W11 firewall reviews are lost and must be redone** (fresh QuiBbLE, Opus) before their implementers run; W10 is superseded by W11 (its six open questions in HANDOFF-S304 are presumed settled by W11, unconfirmed). Reference SDK for the overlap gate is at `~/RaBbLE-Cleanroom/muse-ref` (b139b45); the overlap script is recoverable with `git show 984c554^:ops/cleanroom-overlap.py`. Implementer workspaces: `~/RaBbLE-Cleanroom/pocket-w9` (done), `pocket-w10`; transcripts archived in `~/RaBbLE-Cleanroom/transcripts/<wave>/` (w9 added). **The open core is not clean until W11 and W8 land.**

## Review session: how to run it
- Walk the plan's section 11 with Mark, one question at a time, each with a recommendation. Record answers in the plan.
- Suggested recommendations: `core/` as the name; beam client kept in `entities/RaBbLE` until W8 is done, with core defining a voice-backend interface; voice stays in `entities/RaBbLE` until the backend interface exists (R5) so R1 stays a pure move; `rabble_input`'s power ladder becomes a board-owned core service (swaps and two creatures cannot share one entity's timer); settings scope designed before the rename.
- If the plan changes materially, get one more QuiBbLE pass, then mark the plan "v2, confirmed" and write per-phase briefs for the Opus implementation sessions.

## Next
1. Review and confirm with Mark (R0).
2. Redo the W8 and W11 firewall reviews (can run in the same session, one QuiBbLE each, in parallel).
3. R1 pure move on Mark's go.

## Review result (QuiBbLE, Opus, S311)
COHERENT-WITH-EDITS. The layer model is satisfiable (no sdk to app/main edges today, checked by grep, `ops/sdk-layers.py --symbols` and nm); the v1 roadmap was not. Eight edits folded into plan v2: R1 only moves code that already respects the layers (render, beam, voice go to `entities/RaBbLE`, `rabble_net` split, `open_entity_default` stays in core until R4, lint ported in R1 and enforced in R2); R3 re-scoped (the Orbit logic is already an instance, the singleton is `s_L` in `rabble_orbit.c`, the logic calls beam/input/pomo so tables plus an ops table go in at init, and the pomo page hook is the first slice of the app interface); `rabble_input` is three modules; main/ holds more than `app_main.c`; collision and hard-wired path lists extended; licence-flip gate hardened. The plan is v2 and **has not been re-reviewed**; one more QuiBbLE pass is cheap after Mark's changes.
