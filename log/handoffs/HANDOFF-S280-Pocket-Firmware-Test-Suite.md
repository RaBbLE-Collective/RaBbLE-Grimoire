# HANDOFF-S280 · Pocket firmware: a comprehensive test suite for the SDK, app, drivers and board

> Written 2026-10-25 in S280 for a cold start. Mark asked for it in S280 ("we will need a comprehensive set of tests for the SDK, APP, Drivers, and Board") and parked it for its own session.
> Read first: this file, `RaBbLE-Pocket/RaBbLE-Pocket-SDK-Plan.md` (layers, dependency rule), `RaBbLE-Pocket/firmware/test/README.md` (the suite as S280 left it).
> Session numbering: the SDK S2-S11 commits are tagged `%S279_SDK%` because S279 was also taken by the concurrent RaBbLE-UI session. Everything after them is `%S280_SDK%`.

## Open from S280 (do these first)

S280 hit the usage limit before its close-out; the log entry, this section and the Grimoire commit were written afterwards from the transcript.

1. **B-22, saved voice notes get dropped.** CrumBbLE's device gate on `6889b52`: a 7.4 s note in the outbox failed every send (`esp-aes: Failed to allocate memory` → mbedtls write error `-0x0084` → `beam: LOST sCoRE`), then `giving up on a saved note after 8 tries` dropped it (`rabble_voice.c:548`, `note_drop_oldest()`). Heap at ready is 12,351 B, identical to `52f72b9` (whose gate had an empty outbox), so likely pre-existing from the W6/W7 internal-RAM drop; no A/B yet. Mark picks the fix: smaller websocket chunks, an mbedtls AES path that doesn't allocate internal RAM, or recovered internal RAM. Whatever the fix, a note is never dropped silently. The Capture hand check will fail on this build until it lands.
2. **NiBbLE's re-review of CoBbLE's gate fixes never finished** (`e2b5b06..fa6f3c6`: sdk-layers homing by directory, voice_test without vectors, run.sh stale KNOWN_FAILURES + `render/sim_test`, stale refs + `shim_app`, paths.sh). NiBbLE stopped at "now the new checker". Re-run it from a `git archive` export, trying to get past the new checker.
3. **Run gates under bash, not zsh:** an unquoted `--enforce $E` does not word-split in zsh, so some of CoBbLE's direct checks enforced nothing (redone under bash; the scripts themselves were always bash).

## Where it stands (end of S280)

| Thing | State |
|---|---|
| Layout | `firmware/app/RaBbLE/`, `firmware/sdk/rabble_{core,lvgl_port,power,audio,store,net,motion,voice,render}/`, `firmware/boards/rabble_waveshare_175b/`, `firmware/drivers/rabble_{axp2101,qmi8658,pcf85063}/`. `ui` is not extracted yet (S8/S9). **Check the paths against the tree first:** this handoff was written while the S280 clean-up was still landing |
| Layer gate | `ops/sdk-layers.py --enforce <every layer but ui> --symbols`. Boards may include {core, drivers} only; drivers may include other drivers only |
| Suite entry | `firmware/test/run.sh [layer…|layer/test…]`: PASS/FAIL table, `KNOWN_FAILURES` → XFAIL (an XPASS fails the run), logs in `firmware/test/.out/` |
| Tests today | ~18 host tests regrouped from the clean room (`test/cleanroom/wN/` → `test/<layer>/`): core (seam, state, settings), audio (adpcm, audio), power (battery), net (text, beam, wifi, wifi_store), voice (voice, outbox), app (console_setup, input, orbit, pomo), drivers (axp2101), boards (band). Plus `compile_check.sh` / `xtensa_check.sh` per test and `sim/` golden renders |
| No tests | motion, store, render, ui; drivers qmi8658 and pcf85063; board display/frame/texture; nothing at all on the device |
| Known failures | See `firmware/test/KNOWN_FAILURES`. S280 fixed the stale-include ones; battery LeakSanitizer 11b-11g was diagnosed in S280 (see the file) |
| `sim/build.sh` | exits 1 on 4 orbit sprite assertions ("95 of 256 pixels differ" at some rolls) before and after the SDK work: stale goldens or a real S274 Orbit transition drift. Not a regression from the SDK |
| Device gate | done by hand each time (CrumBbLE): boot log, display/ready ms, fps, free internal heap at ready (12,351 B at `52f72b9`), beam connect, console `>status` `>imu` `>notes` `>power` `>perf`. Opening `/dev/ttyACM0` resets the board; console commands need the `>` prefix; there is no `>mem` command |

## The proposal Mark saw (S280), to turn into a plan

| Tier | Proves | Runs on |
|---|---|---|
| 1. Host unit | pure logic per module (text, adpcm, settings, beam protocol, battery curves, motion maths, orbit gestures) | laptop, gcc + ASan/UBSan, seam stubs |
| 2. Host contract | each SDK component through its public header only, with a fake board behind the seam; catches API drift between layers | laptop |
| 3. Cross-compile | every source at xtensa -O2 -Werror | laptop (`xtensa_check.sh`) |
| 4. Golden render | renderer + app scenes pixel-stable | laptop (`sim/`) |
| 5. On-device | drivers + board on silicon (PMU, IMU, RTC, panel, touch, codec loopback, Wi-Fi/beam, heap/fps budgets) and scripted app flows (Orbit, PTT, Capture) | Pocket: an ESP-IDF test app + a pytest harness over the `>` console |

Per layer: **SDK** tiers 1-4 · **App** tiers 1, 4 + scripted device flows · **Drivers** tier 1 against a fake I2C bus (register-level vectors) + tier 5 · **Board** tier 5 (doubles as the 1.75C bring-up check).
Tie-in: SDK plan **S10**'s second app `app/board_test` should *be* the tier-5 test app, so the placement test and the hardware tests are one thing. CrumBbLE's manual gate becomes a script.

## Next, in order

1. **Inventory (GoBbLE, read-only):** every module's public functions × whether any test touches them; what each existing test really covers (some only compile); which tests are host-only stubs vs real logic. Output: a coverage table per layer.
2. **Plan (lead) → `log/plans/Pocket-Firmware-Test-Suite-Plan.md`:** tiers, per-layer targets, fakes needed (fake board seam, fake I2C, fake NVS/LittleFS, fake websocket), the on-device harness shape (ESP-IDF Unity test app vs console-driven pytest; check what `pytest-embedded` gives on IDF v6.0.1), build order, and gates (proposed: a layer can't be enforced or extracted without tier-1 tests; `test/run.sh` exits 0 before every SDK step commit). Decide whether `sim/build.sh`'s 4 failing assertions get re-goldened or investigated.
3. **QuiBbLE attacks the plan; Mark signs off.** Also render it as an Aether Artifact page for him (memory: plans are hard to read in the CLI).
4. **Build:** parallel CoBbLE jobs split by layer (they don't share files; `test/run.sh` and `KNOWN_FAILURES` stay with one owner). CrumBbLE runs the tier-5 harness on the board; NiBbLE reviews.

## Open questions for Mark

| # | Question | Suggestion |
|---|---|---|
| T1 | Coverage target: every public function, or behaviour per module? | Behaviour per module, every public header exercised at least once |
| T2 | On-device tests: a separate test app, or test commands built into the real firmware behind Kconfig? | Separate `app/board_test` (S10), real firmware stays lean |
| T3 | CI: local only (`test/run.sh` before commits, a git hook) or a hosted runner later? | Local + git pre-commit hook for tiers 1-3 (agent-agnostic); hardware stays manual-triggered |
| T4 | Do S8/S9 wait for ui tests? | Yes: write orbit-engine tier-1 tests before the S8 split, so the split is checked |

## Gotchas
- ESP-IDF links with `--start-group` and `WHOLE_ARCHIVE`: upward references link silently. Use the symbol gate, not just includes.
- Host tests share `firmware/test/paths.sh` (`ACC`, `RINC`, `RALL_C`, `rsrc`): never hard-code a module path.
- Ignored `idfproj/build` dirs under seam/battery tests can go stale (a double picolibc `-specs=`): delete them and they regenerate.
- When an agent is mid-refactor in the tree, run tests from `git archive <rev> firmware ops | tar -x -C <scratch>`.
