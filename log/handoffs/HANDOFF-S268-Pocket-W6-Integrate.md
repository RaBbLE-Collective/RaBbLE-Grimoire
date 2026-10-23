# HANDOFF-S268 · Pocket: W6 integrate (implementer running), then W7, then the RaBbLE-SDK

> Written 2026-10-22 in S268 for a cold start. Supersedes `done/HANDOFF-S267-Pocket-CleanRoom-Final-SDK.md`, whose **W7 list (section 2) and RaBbLE-SDK plan (section 3) are still current**: read them there, this file only adds what changed.
> Read first: this file, `RaBbLE-Pocket/cleanroom/w6-board.spec.md` (the contract; section 10 is your checklist), `RaBbLE-Pocket/RaBbLE-Pocket-Clean-Room-Plan.md` (Roles, Contract), `RaBbLE-Pocket/RaBbLE-Pocket-Responsiveness.md`.

## Where things are

| Repo | Branch | State |
|---|---|---|
| RaBbLE-Pocket | `new-horizons` `ac2e9f9` | unchanged code; only `firmware/datasheets/README.md` modified (2 rows + CST9217 note). Flashed: `ac2e9f9` (clean, after one instrumented boot). Nothing pushed (54 ahead) |
| RaBbLE-Grimoire | `new-horizons` `dab19c0` + this handoff | W6 spec, responsiveness log, INDEX row; not pushed |
| Clean workspace | `~/RaBbLE-Cleanroom/pocket-w6` base `c04367d` | export of Pocket `ac2e9f9` minus `firmware/bsp`, `ops/cleanroom-overlap.py`, `ops/cleanroom-audit.py`; plus datasheets, managed components, a fresh interface-only `bsp/` skeleton (`CMakeLists.txt` with `SRC_DIRS "."` + the REQUIRES list, `idf_component.yml` with the Waveshare `^3.0.1` dependency), `SPEC.md` (W6 spec at `dab19c0`), `SEAM-SPEC.md`, `BRIEF.md` (implementer rules) |

## Done in S268

1. **Datasheets:** CO5300 and ES7210 into `firmware/datasheets/` (Waveshare hosted). **No public CST9217 datasheet exists** (Waveshare, Espressif registry, vendor searched): the managed `waveshare__esp_lcd_touch_cst9217` driver is the reference.
2. **Boot measured** (one instrumented flash, reverted, reflashed clean): reset boot lights the panel at **2,809 ms**; panel init alone 1,203 ms = the vendor init table's two 600 ms waits (datasheet needs 5 ms after Sleep Out, booster up at 120 ms). Full table in the responsiveness doc.
3. **W6 spec** `cleanroom/w6-board.spec.md`, written by S268 (S role: read `bsp/`). Section 0 is the "map for Mark". Deliberate changes: 8.1 `>perf` opt-in logs, 8.2 steady 30 fps, 8.3 config trims (Mark's ok needed), 8.4 panel init waits, 8.5 no TE wait without TE (added by F).
4. **Firewall (F):** independent Opus 5.5 sub-agent, approved after edits (16 changes: comment echoes rephrased, step walks turned into guarantees, rescue priority exact as `configMAX_PRIORITIES - 2`). Findings: today a failed TE ISR install still waits 40 ms per frame (now 8.5); the original's "panel reset shared with touch" is false (GPIO 39 vs 40), deep standby is still avoided but its rationale is open for Mark.
5. **Console finding** (Mark asked if the baud change matters): the **primary console is UART0 (GPIO 43/44) at 115200, which nothing reads**; USB Serial/JTAG (what tools read) is only the secondary. Every log byte busy-waits UART0: ~0.57 s of wire time before the panel lights, plus runtime stalls on any task that logs. Preferred fix: USB Serial/JTAG as primary, UART0 off; needs one measurement build (host connected but not reading). Logged with 13 other paths, ranked, in `RaBbLE-Pocket/RaBbLE-Pocket-Responsiveness.md` (Mark: "I want the device to feel snappy and alive").
6. **Mark's decisions:** W7 copyright header sweep covers **every tracked file** (recorded in the S267 handoff's W7 item). Mark skipped the spec walkthrough for now ("let's handoff and start W6"); offer it again when he wants the map.
8. **Pomodoro slice started** (Mark, S268: "quickly implement the pomodoro"): a Sonnet sub-agent on Pocket `new-horizons`, `w5-orbit.spec.md` 6.1 to 6.4, 6.6 and only the focus look from 6.5 (fidgets and check-in nudges deferred, TODOs in code); builds and commits (`%S268_POMO%`), does not flash. If the session ended first: check `git log` for that tag, else redo the slice. Then flash and hand-check with Mark.
7. **Implementer started:** fresh Sonnet 5.5 sub-agent (`general-purpose`, `model: sonnet`), told only to read `BRIEF.md`; it writes new `bsp/` sources in the workspace, builds, commits in the workspace git, does not flash.

## Next, in order

1. **When the implementer reports:** read its report; in the workspace, `git log`/`git diff c04367d` to review (G may read both sides). Archive its transcript to `~/RaBbLE-Cleanroom/transcripts/w6/` (the sub-agent JSONL from the S268 session's tasks dir; if this is a new session, the parent session's `tasks/*.output` file for that agent) and run `ops/cleanroom-audit.py` on it.
2. **Integrate (G)** on Pocket `new-horizons`: copy the new `bsp/` sources over, delete `bsp_waveshare_175b.c`, `rabble_lcd_bands.c/.h` **in the same commit**, keep `bsp/LICENSE-APACHE` and the NOTICE section until W7. Wire `>perf` where the implementer's report says (8.1). Build, flash, run the spec's section 10 checklist (needs Mark's hands for PWR, touch everywhere, brightness feel, IMU tilt; S264 freeze repro: flash work during a turn plus a TLS reconnect). Behaviour failures go back to the implementer **as behaviour** (SendMessage to the same agent if still reachable, else a fresh Sonnet with the same brief plus the failure list), never as code.
3. **Overlap gate:** `ops/cleanroom-overlap.py` on the new files, < 5% with every hit reviewed. PROVENANCE row for W6 (spec S268, F S268 Opus sub-agent, I Sonnet sub-agent, inputs, overlap, commit).
4. **Config trims (8.3) and the console path:** ask Mark; then one measurement build per the responsiveness doc's "How to measure" (reset and cold boot).
5. **W7 close-out**, then the **RaBbLE-SDK**: as in `done/HANDOFF-S267-...` sections 2 and 3 (W7 after the W6 overlap gate passes; SDK layout planned with Mark first).

## Gotchas

- This session (S268) read `bsp/`: it is S/F/G, never I. The implementer must not see this handoff, the S267 handoff, PROVENANCE or the responsiveness doc's mentions of `s_lit_at` (all quote or name the original).
- Serial and flashing: one logger (`serlog.py`; a copy is in the S268 scratchpad), `pkill -f "serlog.p[y]"` in its own call before flashing (exit 144 from the logger's background task is expected); opening the port resets the gadget, so a "cold boot" needs a PWR power-on.
- zsh: `command grep`, quote globs.
- end-session.sh ledger clobber: back up `log/token-ledger.tsv` first.
- Other sessions' `log/agents/*.json` changes show in `git status`: never stage them.
