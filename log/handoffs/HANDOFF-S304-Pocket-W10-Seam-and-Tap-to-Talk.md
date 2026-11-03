# HANDOFF-S304: Pocket hardware-seam redesign (W10) and tap-to-talk

> Cold start. Written 2026-11-03 (S304; the tap-to-talk commit is tagged %S303_TAPTALK% from before the number was claimed). Continues HANDOFF-S298-Pocket-Split-Build-Plan.md. Mark: "park with questions asked on next SDK work session".

## State

- **Tap-to-talk built, unverified on device:** RaBbLE-Pocket branch `tap-to-talk`, commit `dfcb1d9` (not merged, not pushed). Mic-icon target claims touch before the Orbit: hold (300 ms) = push-to-talk, double tap = hands-free turn that stops on silence, tap = cancel. New: `rabble_tap_talk.c/.h`, `rabble_endpoint.c/.h`, PTT cancel event, Kconfig hangover/margin/no-speech. BOOT unchanged. CoBbLE reports host tests green (tap_talk 59, endpoint 19, handsfree 22, old voice vectors 47/47) and a clean build; **not re-run by anyone else, never flashed**. Why: Mark broke the BOOT switch (needs resoldering); a 1.75-C may be ordered.
- **W10 spec draft 1** (`RaBbLE-Pocket/cleanroom/w10-hardware-groups.spec.md`, uncommitted, held with the other split docs): replaces the single board table with capability groups, boards and example adapter in the Apache SDK tree. QuiBbLE verdict **REVISE**: the draft restates the old table's operations, order and comments (shape survives), the adapter deliverable cannot be built blind, accel unit is **g** not m/s², the "mic slot changes at runtime" clause is invented (delete), bring-up/display start must run on the UI-core task (S264 hang), presence timing and direct-draw install contract incomplete, 12:00 rule has no owner. GoBbLE's call-site map (37 members, 8 groups, 9 unchecked callers) was in-session only; regenerate with a scout if needed.
- **Mark's rulings so far:** option A (capability groups) if no regression; clock shows 12:00 while invalid and unsynced, self-corrects via sCoRE or a companion; trigger injection point included; boards are SDK not app layer; BOOT stays default; wake word later, CPU budget is the hurdle; mic icon is the on-screen trigger.

## Questions for Mark (ask first next session)

1. Is "no aggregate struct, registration only" a provenance requirement or just a preference? If preference, QuiBbLE's simpler path: one const descriptor with per-group pointers, buttons as an event sink (injection falls out), display power as one state, clock as a source for `rabble_time` only (face goes through `rabble_time`, 12:00 rule becomes a small UI change), hot paths unchanged.
2. Who writes the Waveshare reference adapter: the implementer (needs the engine re-typed first) or the integrator? Recommended: integrator.
3. 12:00 rule: separate commit after W10 (recommended) or inside it? With no RTC chip: 12:00 or "--:--"?
4. Licence placement: every `sdk/` and `boards/` file is Sovereign Accord today; an Apache board layer would call Accord engine files and reuse `rabble_power_t`. Re-license SDK tree first, or write W10 assuming the split lands?
5. Device check of tap-to-talk: OK to flash `tap-to-talk` over RaBbLE (back up ota_0 first, as in S300)?
6. Standing from S300: rewrite vs move the S298 commits in the PUBLIC Grimoire (30 commits ahead of origin, do not push); Apache-side derived files (clean room vs notice, leave for last); signing key (parked).

## Next steps

1. Rule on the questions above.
2. Revise W10: outcome-based wording (no operation lists, no old ordering or phrasing), implementer file allow-list (exclude W0/W6 specs, `boards/`, `static_asserts.c`, anything with `rabble_board->`), fix the errors above, run the overlap gate on the spec text vs the old header, then a fresh **Opus** implementer in `~/RaBbLE-Cleanroom`.
3. In parallel: NiBbLE review of `dfcb1d9`, CrumBbLE independent host re-run, then device run (hold, double tap, cancel, drag vs Orbit, tilt, wake-from-sleep touch, real mic floor; -70 dBFS clamp and 6 dB margin are guesses). Possible fix: hit-test uses the raw panel frame; if the icon moves with roll on device, unrotate the point (one line).
4. Stale `firmware/sdkconfig` (expects `firmware/partitions.csv`, moved by S10a) breaks `ops/build-flash.sh`; it also needs `-p` even with `-B`. Fix separately.
5. Wake word: start by having CrumBbLE profile per-core load at idle and during a turn; the hands-free endpointer is reusable.

## Gotchas

- Do not stage `RaBbLE-Pocket/README.md` (false provenance wording) or `firmware/hw_test/` build output.
- `ops/build-flash.sh -B` works only with `-p`; CoBbLE built via `idf.py -B /tmp/tt_bld` with `SDKCONFIG=/tmp/tt_sdkconfig`.
- The BOOT button is broken hardware; GPIO0 never goes low (S300). Switch repair pending.
- Held, untracked in the public Grimoire: Provenance Record, Split Manifest, `cleanroom/audit-2026-11-02/`, Open-Layer notes, W10 spec.
