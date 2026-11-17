# HANDOFF-S264 · Pocket: Capture mode next, clean room W5/W6, face feel

> Written 2026-10-22 at the end of S264 for a cold start. Supersedes `done/HANDOFF-S252-Pocket-Settings-Orientation-Clean-Room.md`.
> Read first: this file, then `RaBbLE-Pocket/RaBbLE-Pocket-Capture-Plan.md` (tracks T0 to T6) and `RaBbLE-Pocket/RaBbLE-Pocket-Clean-Room-Plan.md` (waves). Wire contract: `RaBbLE-Pocket/RaBbLE-Pocket-Beam-Protocol.md#capture-turns`.

## Where things are

| Repo | Branch | State |
|---|---|---|
| RaBbLE-Pocket | `cleanroom` (flashed on the gadget; superset) and `new-horizons` (ancestor of `cleanroom`; builds) | clean, **nothing pushed** |
| RaBbLE-sCoRE | `new-horizons` (`663bc10` capture turns, 20 tests) | clean, **not pushed: pushing deploys to Render** |
| RaBbLE-Grimoire / Collective | `new-horizons` | clean, not pushed |

Branch rule for Pocket (Mark, S264): shared `accord/`, `nebula_lite/`, `bsp/` changes commit on `new-horizons`, then `git merge new-horizons` into `cleanroom`. Files that differ between them (the clean-room modules: `accord/rabble_input.c`, `rabble_audio.*`, `rabble_voice.*`, W0 to W3) commit on `cleanroom` only. When the clean room finishes, fast-forward `new-horizons` to `cleanroom`: one branch again.

Done in S264 (details in `log/SESSION-LOG.md` S264 and the capture plan):

- **Face freeze fixed:** TLS handshake priority inheritance; TLS resumption + the panel lifting a late band helper. 0 late frames over 6 reconnects.
- **Clean room W4 voice + audio** (`94d7d0b`, round 2 `6eb79d9`): the speaker amp is gated (idle hiss gone), 150 ms settle lead-in. Left in `apache/`: keypad, settings_ui (W5); `bsp/` (W6).
- **Face feel:** tilt keeps the last good down, 15-degree settings notches, motion sway + touch (dent, gaze, lean), motion/touch raise mesh activity, shake counts time above 1 g, rim hints.
- **Levelling:** Settings > Level (3 flats, a full turn, a trim by eye); NVS `rabble_motion/bias,gain,trim`.
- **Capture:** plan written; sCoRE side built and unit-tested; nothing on the device yet.

## Next, in order

1. **Capture T3: notes store** (`accord/rabble_notes.c/.h`). LittleFS (`joltwallet/littlefs`, MIT, managed component) on the `storage` partition, SD first on the -B board. **Blocked on Mark: partition size** (keep 7 MB; 4 MB app + ~11.9 MB; or OTA-ready 2 x 3.5 MB + ~8.9 MB, recommended). Resizing reformats storage, so settle it first. Gate: a note survives reboot, full store refuses cleanly, no late frames while writing.
2. **Capture T4: modes + swipe.** Swipe up = Capture, down = Converse on the face tile; capture gesture tap or hold chosen in Settings (default tap). A typed capture over the console (`>capture=...`) exercises T2 to T5 before T6 and spends no speech quota.
3. **Capture T5: offload.** Serial `>notes` commands + `ops/pocket-notes.py pull [--prune]` into `~/Personal-Grimoire/babble/pocket/YYYY/MM/`. Open: prune after merge automatically or only with `--prune`.
4. **Capture T6: voice capture** on top of the clean W4 voice (W4 is done, so T6 can start): long recordings, offline audio to flash as ADPCM, upload with codec `0x01`; the device's 60 s reply wait must not apply to captures.
5. **W4 checklist still owed** (needs Mark, spends Groq speech quota): a full turn with the first word checked in the transcript (pre-roll), speaker off, a note recorded offline and sent later, the 15 s limit, fps while listening and speaking, the falling cue after release audible.
6. **Push** (Mark's call): Pocket both branches, sCoRE (deploys), Grimoire, Collective.

Later: W5 settings_ui + keypad redesign (Mark's layout first; it must carry the new "Level" row), W6 display (must keep "a frame is never held by a stalled helper"), W7 close-out. Rename `apache/` once Mark picks a name (AGENT.md says no upstream product names: a neutral name like `components/rabble_derived/` is recommended). Level applet polish and face-feel tuning are on the Pocket roadmap.

## Gotchas you will hit

- **Clean-room taint:** S252, S254, S256, S258, S259 and S264 read originals. A session that has read `apache/`, `bsp/`, `muse-gadget-sdk/` or backups may be spec author, firewall or integrator, never implementer. Implementers are fresh Sonnet sub-agents in a plain export (`~/RaBbLE-Cleanroom/pocket-wN`, recipe in the clean-room plan); briefs and generators stay private in `~/RaBbLE-Cleanroom/gen/`.
- **Serial:** opening the port a second time resets the gadget, and it flips between `/dev/ttyACM0` and `ACM1` after a power cycle. Use one logger that keeps reading and takes commands from a file (S264's scratchpad `serlog.py`: append to `<log>.cmd`). Stop it before flashing.
- **Builds:** `ops/build-flash.sh firmware -B` still demands a board; pass `-p /dev/null` when none is attached. New files under `accord/` need `touch firmware/components/rabble_gadget/CMakeLists.txt` (SRC_DIRS globbing).
- **Overlay:** the entity composites every LVGL screen (clock, level) and turns it; a screen that works in the panel's frame calls `rabble_entity_fix_ui(true)`.
- **Idle 60 fps** depends on every input repeating exactly at rest: anything new fed to `nl_simulate` must snap to exactly 0 when still (sway, touch, motion activity all do).
- **`end-session.sh`** drops older ledger rows that share the breadcrumb id: back up `log/token-ledger.tsv`, run it, restore and append only the new row.
- **Groq TTS** is capped at ~3,600 tokens a day: keep real voice turns few.
