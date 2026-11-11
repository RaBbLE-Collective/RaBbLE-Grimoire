# HANDOFF-S265 · Pocket: Capture live, offload next

> Written 2026-10-22 at the end of S265 for a cold start. Supersedes `done/HANDOFF-S264-Pocket-Capture-W4-Face.md`.
> Read first: this file, then `RaBbLE-Pocket/RaBbLE-Pocket-Capture-Plan.md` (T3 and T4 "Built S265" notes, T5 section). Wire contract: `RaBbLE-Pocket/RaBbLE-Pocket-Beam-Protocol.md#capture-turns`; serial notes commands: `firmware/components/rabble_gadget/accord/rabble_notes_console.h`.

## Where things are

| Repo | Branch | State |
|---|---|---|
| RaBbLE-Pocket | `cleanroom` `22a11be` (flashed; superset) and `new-horizons` `fa2b9d5` | clean, **nothing pushed** |
| RaBbLE-sCoRE | `new-horizons` `663bc10` | **pushed, live on Render** (capture turns) |
| RaBbLE-Grimoire / Collective | `new-horizons` | committed, not pushed |

Branch rule (Mark, S264) still holds: shared `accord/`, `nebula_lite/` changes on `new-horizons`, then `git merge new-horizons` into `cleanroom`; files that only exist in `cleanroom`'s `accord/` (`rabble_input.c`, `rabble_state.c`, W0 to W4 modules) and `firmware/test/cleanroom/` commit on `cleanroom` only. New Capture state lives in `accord/rabble_capture.c` (shared) for that reason.

Done in S265:

- **T3 notes store** on an OTA-ready layout (Mark): 2 × 3.5 MB app, 8.9 MB LittleFS `storage` at `/pocket`. Store work runs at priority 1 (flash busy-polls and stops the other core's cache: 30+ late frames per MB at priority 5, now 0 for real notes). Meshes run wild while the store works (Mark).
- **Serial offload commands** (T5 device side): `>notes`, `>notes.get=`, `>notes.done=`, `>notes.rm=` (offloaded only), `>notes.test=<kb>`.
- **T4 modes**: swipe up on the face = Capture, down = Converse; the portals flip ends (Mark's idea), `CAPTURE (n)` violet under the clock, `SAVED` green 3 s, and the mode name for 3 s where RaBbLE answers after a swipe (Mark). Voice turn in Capture = capture (15 s cap). `>capture=TEXT`, `>mode=capture|converse`.
- **Live**: a typed capture and Mark's first voice capture both came back shaped and saved (two notes on the gadget now, ids `20261022-0455-5eb8-1` and `-2`).
- Mark's ideas logged in `RaBbLE-Pocket-Roadmap.md`: shake swaps colours, settings swipe with resistance + snap, settings ≥ 40 fps, round-screen settings, boot with rotating portal edges.

## Next, in order

1. **T5 host spell** `ops/pocket-notes.py pull [--prune]` (Pocket repo): one serial session (the port resets the gadget when opened twice; it flips ACM0/ACM1), `>notes`, then `>notes.get=` each not-offloaded id, verify sha256, write `~/Personal-Grimoire/babble/pocket/YYYY/MM/<id>.md` (skip same hash, keep both if different), `git add` + commit in Personal-Grimoire, then `>notes.done=`. `--prune` sends `>notes.rm=` for offloaded notes after a hash check against the host copy. Mark decided: prune only with `--prune`. Gate: a second pull adds nothing. Two real notes are waiting on the gadget.
2. **T4 hand check (Mark)**: swipe in both orientations, Settings swipe unaffected, portal flip and the mode caption look right.
3. **T6 voice capture**: tap-to-start/stop or hold (a Settings choice, default tap), 10 min cap, elapsed time on the glass, offline audio to `/pending/` as ADPCM, upload on reconnect with codec `0x01`, and no 60 s reply wait for captures. Store writes must stay under the panel's priority (see the capture plan's "Flash cost").
4. **W4 hand checklist** (needs Mark, spends Groq quota), then the clean room's W5 (settings_ui + keypad, folds in Mark's round-screen and swipe-resistance ideas) and W6.
5. **Push** (Mark's call): Pocket both branches, Grimoire, Collective.

## Gotchas you will hit

- **Clean-room taint:** S265 never opened `bsp/`; it grep-matched two prototypes in `apache/` (`rabble_beam_console`, `rabble_beam_report`). Treat S265 as not an implementer for W5/W6. Earlier: S252, S254, S256, S258, S259, S264 read originals.
- **Measuring frames:** use `rabble_entity`'s own `N late frames, worst X ms` warning (and `lcd_bands: helper lifted`), not LVGL timer gaps; the LVGL timer stays smooth while the entity starves.
- **Serial:** use the S264/S265 scratchpad logger pattern (one open, commands appended to `<log>.cmd`). Stop it before flashing. From the Bash tool, `pkill -f "serlog.p[y]"` must be its own call: the pattern still matches if the same command line contains the plain script name (exit 144).
- **zsh:** an unquoted `$ids` does not word-split in a `for` loop; pipe into `while read`.
- **Builds:** `ops/build-flash.sh firmware -B -p /dev/null` with no board; new files under `accord/` need `touch firmware/components/rabble_gadget/CMakeLists.txt`. The W2 input host test (`firmware/test/cleanroom/w2/input_test/run.sh`) needs a stub for every new callee `rabble_input.c` gains; its `build/` outputs are tracked, so `git checkout` them after a run.
- **Idle 60 fps** still needs every input to repeat exactly at rest: `in.flip` and the store's mesh lift both snap to exact values.
- **`end-session.sh`** drops older ledger rows that share the breadcrumb id: back up `log/token-ledger.tsv`, run it, restore and append only the new row.
