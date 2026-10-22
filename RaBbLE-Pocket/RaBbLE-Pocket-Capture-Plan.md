# RaBbLE-Pocket-Capture-Plan.md

> **Status (S264, 2026-10-22): T0 freeze fixed (both fixes, 0 late frames over boot + 6 reconnects), T1 tilt built (Mark: "feel nice"), T2 sCoRE capture built (20 tests, uncommitted). Next: T3 notes store, T4 modes + swipe.**
> Mark's ask: give the Pocket two modes, **Converse** (today's push-to-talk conversation) and **Capture** (RaBbLE just listens, transcribes and builds notes files that are beamed back and kept on the device), switched by swiping up/down. Notes land in a **Pocket Grimoire** on the device and are offloaded or merged into a permanent home. Alongside: make the gravity tilt seamless, hold the last good angle when flat, and stop the face freezing.

Related: [Beam protocol](RaBbLE-Pocket-Beam-Protocol.md) (capture frames are specified there) · [Clean room plan](RaBbLE-Pocket-Clean-Room-Plan.md) (voice is W4, display is W6) · [Gadget port](RaBbLE-Pocket-Gadget-Port.md).

## Decisions (Mark, 2026-10-22)

| Question | Decision |
|---|---|
| Capture vs the clean room | **W4 voice first, Capture's voice side on top**, in `accord/`. Everything that doesn't touch `apache/` (sCoRE, storage, swipe UI, offload, tilt) goes ahead now, in parallel. |
| Internal store | **LittleFS** (MIT, managed component) on the flash `storage` partition; SD card first when one is in. Size still open (see Open questions). |
| Offload target | **USB to the host first**, merged into Personal-Grimoire `babble/pocket/`. Account sync through sCoRE comes later. |
| Capture with sCoRE out of reach | **Save the audio, transcribe later.** The recording goes to flash and is beamed once sCoRE is reachable; the note comes back and replaces it. |
| Freeze | **Both fixes**: TLS session resumption in the beam, and the panel never waiting on a stalled core. |
| Swipe | **Up = Capture, down = Converse** ("good for now"). |
| Capture gesture | **Both tap and hold supported, chosen in Settings.** |
| Branches | Commit on Pocket `new-horizons`, merged into `cleanroom` so the flashed firmware matches; the two become one branch when the clean room lands. |

## Tracks

Tracks with no arrow between them run in parallel. Integration into the Pocket stays one module per commit, flashed and checked each time.

| Track | What | Where | Depends on | State |
|---|---|---|---|---|
| **T0** freeze | F1 TLS resumption; F2 panel never held by a stalled core | `accord/rabble_beam_score.c`; `bsp/rabble_lcd_bands.c`; `nebula_lite/src/compose.c` | none | **done S264**, on the gadget |
| **T1** tilt | last-good angle when flat, faster up, jolt rejection, smooth rest | `accord/rabble_entity.c`, `accord/rabble_motion.c` | none | **done S264**, Mark's hand check passed |
| **T2** sCoRE capture | `capture` turns: STT, note shaping, `note` frames, retention | `RaBbLE-sCoRE/server/beam.py`, `server/capture.py`, `tests/test_capture.py` | protocol below | **built S264**, 20 tests pass, no live STT/LLM run yet |
| **T3** notes store | `rabble_notes`: SD or LittleFS, layout, index, quota | new `accord/rabble_notes.c/.h`, `partitions.csv` | partition decision | next |
| **T4** modes + swipe | Converse/Capture state, swipe up/down on the face, face and glass cues | `accord/rabble_state.c`, `accord/rabble_ui.c`, `accord/rabble_entity.c` | none (typed capture works before W4) | next |
| **T5** offload | serial `>notes` commands + host spell, merge into Personal-Grimoire | `accord/rabble_input.c` (or a new console file), `ops/pocket-notes.py` | T3 | after T3 |
| **T6** voice capture | long recordings, offline audio to flash, upload, ADPCM | `accord/` voice (after W4) | **W4**, T3 | after W4 |
| **W4** voice clean room | same behaviour first, existing pipeline | `apache/` to `accord/` | clean room W0-W3 | per clean room plan |

A typed capture (`>capture=...` on the serial console, `mode: "capture"` with `text`) exercises T2 to T5 end to end before W4 lands and spends no speech quota.

## T0 · The face freeze

**Root cause (S264, measured).** The face stalled ~1.47 s each time the beam connected (boot and every Wi-Fi nap wake), never otherwise. A stall watchdog snapshot during the stall showed `websocket_task`, created at priority 5 (also tried 3 and 1, both cores), **running at priority 18 or 23**, using ~1.3 s of CPU while `lcd_send` (4, core 1) and `lcd_help` (3, core 0) starved. The esp_websocket_client task holds its own client mutex across `esp_transport_connect`, so the whole TLS handshake. When `tcpip` (18) or `wifi` (23) briefly blocks on a lock the task holds, it inherits their priority, and FreeRTOS only returns an inherited priority when the holder has released **every** mutex it holds. So the handshake's crypto runs boosted to the end, on whichever core, above the panel. Task priority or core choices can't fix it.

- **F1 · TLS session resumption** (`accord/rabble_beam_score.c`). The beam owns its SSL and websocket transports (`ext_transport`), keeps them across connections and offers the saved TLS 1.2 session (`CONFIG_ESP_TLS_CLIENT_SESSION_TICKETS=y`). Gotcha: the ticket SAVE operation frees the session the SSL config still points at, so USE runs straight after it, and if that fails the transports are rebuilt before the next connect. Result: resumed connects take ~200 ms instead of ~1.8 s, but Render's front end resumed only 3 of 5 (other edges, other ticket keys). The first connect after boot is always full.
- **F2 · panel never held by a stalled core** (`bsp/rabble_lcd_bands.c`). When the send task has waited 6 ms on a band the helper claimed, it lifts the helper to priority 23 (level with Wi-Fi, so they time-slice) until the frame is out, then puts it back at 3. The socket task is pinned to core 0, so a boosted handshake can only land on the helper's core, never the send task's. Result: 0 late frames over boot + 6 reconnects (3 full handshakes), the helper lifted for 1-2 frames each time, connect times unchanged. A first design that stole late bands back was dropped: a helper resuming during the next frame's `begin()` could read a torn primitive (union `kind`/`sprite`) and index `nl_spr[]` out of bounds. **The W6 display spec must carry "a frame is never held by a stalled helper" as a requirement** (behaviour, not code).
- Found on the way, fixed: `nl_render_band` used a `static` scratch row for the haze upscale while both cores render bands at once; it is now per call (helper stack 4096 to 5120).
- Clean-room note: F2 meant reading `bsp/`, so the S264 session is tainted from that point (spec author, firewall or integrator only, never implementer).

Diagnosis tool (not kept in the tree): a priority-22 watchdog task that snapshots `uxTaskGetSystemState` when no frame has started for 200 ms and prints each task's CPU time over the stall. It found the inherited priority in one run. Instrumentation kept: `rabble_entity` logs `N late frames, worst X ms (mode M)` for any frame later than 150 ms (at most every 2 s), and `upright at rest P% of frames` beside the fps line.

## T1 · Tilt

Built and running (S264). In `upright()`: the spring now chases the **last good down**. Its follow rate scales with how much gravity lies in the screen plane: full from sin(tilt) 0.35, nothing at 0.12 and below. Lying flat it keeps the angle it had as it was laid down instead of swinging back upright, with no jump through the transition. Spring 55 to 110 (ω ≈ 10.5 rad/s), damping 0.55 to 0.72. The rest hold no longer steps 0.6° at a time on slow tilts: the spring stops at rest and starts again from where it stopped. In `motion_task`: up smoothing 0.25 to 0.10 s, readings far from 1 g (hand jolts) move "up" less (`UP_TRUST_G`), a failed IMU read retries in 100 ms instead of 1 s and is logged.

Measured: idle 58-60.5 fps at rest, rest engaged 97-100% of frames. Mark's hand check (S264): "the rotation/IMU fixes feel nice".

Next performance target (separate from this plan): turning and busy run ~30-37 fps, wire-bound (~160 µs per band even on an idle wire). Mark: sub-30 feels laggy; 60 idle is right.

## T2 · sCoRE capture

Specified in the [beam protocol](RaBbLE-Pocket-Beam-Protocol.md#capture-turns). In short: `turn.begin` with `mode: "capture"` (voice or `text`), no TTS, no conversation. sCoRE transcribes, shapes the transcript into a markdown note with the fast LLM tier, and sends it back as `note` frames; the device answers `note.saved` and sCoRE drops its kept copy.

The note (one markdown file, YAML frontmatter):

```markdown
---
id: 20261022-0130-5eb8-7            # from the device: local start time, device suffix, turn
type: pocket-note
title: Backplate tolerance ideas
created: 2026-10-22T01:30:12-04:00
device: RaBbLE-Pocket-5EB8
source: voice                        # voice | text
duration_s: 94
tags: [pocket, cad]
---

## Summary
- ...

## Notes
...cleaned, structured, in the speaker's words where it matters...

## Transcript
...verbatim STT output, never edited...
```

The transcript is always kept verbatim: the shaped notes are a reading aid, the transcript is the record. Shaping failures still produce a note (title from the first words, transcript only).

Built S264 (`server/capture.py` pure functions + `run_capture` in `beam.py`; `tests/test_capture.py`, 20 tests, run from `server/` with `.venv/bin/python -m pytest ../tests`). Watch when it goes live: shaping uses `max_tokens=2000`, so very long captures may truncate the JSON and fall back to transcript-only; tune once real captures exist. STT runs sequentially in 5-min segments (120 s timeout each), so the device's 60 s "DIDN'T ANSWER" timer must be longer for captures (T6).

## T3 · Notes store (`rabble_notes`)

- **Where.** SD card first when one is mounted (FAT, -B board only; the 1.75C has no slot), else LittleFS on the `storage` partition (`joltwallet/littlefs`, MIT, as a managed component: nothing vendored). Board vtable gains an optional `sd_mount`; boards without a slot leave it NULL.
- **Layout.** `/notes/YYYY/MM/<id>.md` (the Pocket Grimoire); `/pending/<id>.pcm|.adpcm` + `<id>.json` (captures not yet transcribed); `/notes/index.jsonl` (id, title, created, bytes, offloaded flag).
- **Budget.** Keep 10% free; refuse a new capture with a clear glass message when full. Recording to flash streams in 4 KB writes from a PSRAM ring so the voice task never waits on flash; flash writes stall code fetch from flash/PSRAM briefly, so measure the frame-rate cost (gate: no late frames during a 60 s capture).
- **API.** `rabble_notes_init/put/list/read/remove/pending_*`, safe from any task, one mutex, no LVGL.

## T4 · Modes and swipe

- `rabble_state` gains `rabble_capture_mode()` / `set` (persisted in settings, default Converse).
- On the face tile, a vertical swipe toggles: **up = Capture, down = Converse** (Mark, S264). Settings stays one swipe left. The swipe is read in the upright frame (as taps already are), so it follows the turned face.
- Cues: Capture tints the entity and the glass shows `CAPTURE` plus a note count; a saved note gets a small hop and `SAVED`. Colours from the palette only.

## T5 · Offload to the Personal Grimoire

- Serial: `>notes` (list as JSON lines), `>notes.get=<id>` (base64 chunks with a length and sha256), `>notes.done=<id>` (mark offloaded), `>notes.rm=<id>`.
- Host: `ops/pocket-notes.py pull [--prune]` uses one serial logger (a second open of the port resets the board), writes into `~/Personal-Grimoire/babble/pocket/YYYY/MM/<id>.md`, skips ids already there with the same hash, keeps both if they differ, `git add` + commit in Personal-Grimoire, then marks them offloaded on the device. `--prune` deletes offloaded notes from the device after the hash check.
- Curation from `babble/pocket/` into folios is a later, separate step.
- Later: `notes.sync` over the beam to an account store in sCoRE (needs a persistent store; Render's disk is ephemeral).

## T6 · Voice capture (after W4)

- Capture gesture is a setting (Mark, S264): **tap to start, tap to stop** or **hold to record**, in Settings (persisted in NVS beside the other settings; default tap, since captures are long). Converse stays hold-to-talk. Cap 10 min, elapsed time on the glass.
- Live: speech streams up as today. Out of reach: speech goes to `/pending/` as ADPCM (4:1, ~480 KB/min), uploaded on reconnect with codec byte `0x01` (reserved in the protocol). Replaces the PSRAM 4×15 s queue for captures only.
- W4's spec stays "same behaviour"; T6 is a later accord change on top.

## Later · settings transition

Mark (S264): the settings pane feels more usable now; at some point make the slide into settings feel like RaBbLE rather than a generic panel. Design track, pairs with the W5 settings redesign; not scheduled.

## Open questions for Mark

1. **Partition size.** App slot 8 MB (app is 1.9 MB). Options: keep 7 MB storage; 4 MB app + ~11.9 MB storage; or OTA-ready 2 × 3.5 MB app + ~8.9 MB storage (recommended if over-the-air updates are ever wanted). Resizing reformats storage, so decide before T3 lands.
2. After offload: keep notes on the device until `--prune`, or prune automatically once merged?

## Checklist (gates)

- [x] T0: 0 late frames over boot + 6 nap/wake cycles (F2); reconnect ~200 ms resumed vs ~1.8 s full (F1)
- [x] T1: Mark's hand check
- [x] T2 (unit): typed capture over a test socket returns a well-formed note; retention and `note.saved` (tests)
- [ ] T2 (live): a typed capture against Render with real shaping; a voice capture from a WAV
- [ ] T3: note survives reboot; full store refuses cleanly; no late frames while writing
- [ ] T4: swipe toggles mode in both orientations; settings swipe unaffected
- [ ] T5: pull merges into Personal-Grimoire idempotently (second pull adds nothing)
- [ ] T6 (after W4): 5-min capture live, 2-min capture offline then uploaded
