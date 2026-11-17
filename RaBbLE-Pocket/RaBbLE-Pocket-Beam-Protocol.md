# RaBbLE-Pocket-Beam-Protocol.md

The beam: how RaBbLE-Pocket talks to sCoRE. One WebSocket carries push-to-talk turns: speech up while the button is held, then the transcript, reply text and reply speech back down, speech playing as it arrives. **Status: v0, working end to end (2026-10-06).** Firmware: `RaBbLE-Pocket` `rabble_beam_score.c`. sCoRE: `RaBbLE-sCoRE/server/beam.py` (Groq Whisper STT, RaBbLE on Groq gpt-oss-20b, Groq Orpheus TTS; speech starts 1.5–2.2 s after release on the LAN). `RaBbLE-Pocket/ops/beam-echo.py` is a no-cloud stand-in that plays your speech back.

Firmware: `RaBbLE-Pocket/firmware/sdk/rabble_net/rabble_beam_score.c` (session) behind `sdk/rabble_net/rabble_beam.h` (the interface the voice loop calls; paths as of S280). Port record: [RaBbLE-Pocket-Gadget-Port](RaBbLE-Pocket-Gadget-Port.md).

## Endpoint

- `ws://` or `wss://` URL, set on the device (Settings > sCoRE, or console `>beam.url=`). Firmware dev default: `ws://rabble-os.local:8000/api/v1/beam` (`CONFIG_RABBLE_BEAM_DEFAULT_URL` in `sdkconfig.defaults`), so the path sCoRE should serve is `/api/v1/beam`.
- **Local-first routing:** when RaBbLE-OS is running on the home laptop, the Pocket connects to the local sCoRE instance at `rabble-os.local:8000` — backed by `claude_code` and the full local Grimoire — rather than the cloud service. Architecture and pairing: `RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Pocket-Beam.md`. Port choice (8000 vs 8083) is an open question tracked in that doc.
- Auth: `Authorization: Bearer <device token>` on the upgrade request when a token is set (console `>beam.token=`, chunked with `>beam.token+=`). sCoRE accepts `BEAM_DEVICE_TOKEN`, a member API key or a JWT, and refuses otherwise **even in DEMO_MODE** (the beam spends speech quota); `BEAM_ALLOW_GUEST=true` opens it for LAN bench testing only. Fits the Web=demo / Local=BYOK split.
- wss uses the ESP-IDF certificate bundle, so public CAs work; a self-signed LAN cert would need its CA added to the firmware.
- The device keeps the socket open while awake, pings every 15 s (gives up after 45 s without a pong), reconnects with backoff 5 s to 120 s, and closes it after 2 min of rest (screen off on battery) until the next wake or press.

## Frames

Text frames carry one JSON object each, with a `type`. Binary frames carry audio with a 4-byte header:

| Byte | Meaning |
|---|---|
| 0 | kind: `0x01` mic speech (device to sCoRE), `0x02` reply speech (sCoRE to device) |
| 1 | codec: `0x00` PCM, 16 kHz, mono, signed 16-bit little-endian. Nothing else in v0 |
| 2-3 | turn id, low 16 bits, little-endian |

Audio of any turn but the current one is dropped on both sides. Frames may be any length; the device sends 40 ms (1280 bytes of PCM). sCoRE should keep reply speech a little ahead of real time; the device buffers about 4 s and applies backpressure beyond that.

## Device to sCoRE

| type | Fields | When |
|---|---|---|
| `hello` | `proto: "rabble-beam/0"`, `device` (e.g. `RaBbLE-Pocket-5EB8`), `fw`, `audio: {rate, format, channels}` | Once per connection |
| `turn.begin` | `turn` (uint32, increasing), `mode: "voice" \| "text"`, `speak` (bool: speaker on, so send reply speech), `voice` (optional: `daniel`, `austin`, `troy`; unknown names get sCoRE's default), `text` (text turns only) | Talk pressed (voice), or a typed console turn |
| *(binary 0x01)* | speech | While the button is held, from up to 320 ms before the press (pre-roll) |
| `turn.end` | `turn` | All speech sent (button released, plus a 120 ms tail) |
| `turn.cancel` | `turn` | Tap, barge-in during the reply, or the device gave up |

**New conversation (S347).** A 1.2 s hold on the face (or `>newconvo`) calls `rabble_beam_new_convo()`: the device blanks its caption and what it kept of the thread, cancels a turn in flight, plays the fresh-start animation, and sends `new_convo`. With the link down it only sets a RAM flag (`pending_new_convo`, lost on reboot); at the next connect the device sends `new_convo` straight after `hello`, before any turn, then clears the flag. A send that fails keeps the flag. `convo_new` is informational: the device logs and drops it, and works if it never comes.

A voice turn can start before the socket is up: the device buffers up to 8 s of speech and sends it on connect. Out of reach entirely, it keeps the note in PSRAM (up to 4, 15 s each) and sends it as an ordinary turn once sCoRE is reachable, possibly while the screen is asleep. In that case it only waits for `sent` and cancels the rest, so **sCoRE should keep the reply** (for the user's next look) rather than tie it to the socket.

## Time

sCoRE is the time source for the Pocket and any app (S254). One function, `tools.server_time()` in sCoRE, serves:

- the beam: `ready` carries `time`, so the device sets its clock every time it connects;
- `GET /api/v1/time[?tz=<IANA zone>]` (public, IP rate limited): `{"time": 1792142822.691, "utc": "2026-10-16T09:27:02+00:00"}`, plus `tz`, `local`, `offset_s` and `abbr` with a zone; 400 for an unknown zone;
- the `get_time` LLM tool, so RaBbLE never guesses the date or time.

The device keeps its zone itself (Settings > Clock: a list of POSIX TZ rules with DST, `accord/rabble_time.c`) and its RTC holds local time. With no zone chosen yet, the first sync picks the zone whose offset the hand-set clock already shows.

## sCoRE to device

| type | Fields | Device does |
|---|---|---|
| `ready` | `name` (optional, shown in Settings > sCoRE), `time` (UTC seconds since the epoch, S254) | Marks the beam Connected; with "Time from sCoRE" on (default), sets its clock to `time` plus half the hello round trip, in its chosen zone |
| `heard` | `turn`, `text`, `final` | Caption: the transcript so far, quoted |
| `sent` | `turn` | sCoRE has the whole note: a saved note can be dropped |
| `reply` | `turn`, `text` (a delta, appended) | Caption pages through the reply text, timed against the speech |
| *(binary 0x02)* | reply speech | Plays at once, eyes and portals pulsing with its level |
| `done` | `turn` | Turn over once the speech drains; back to idle with a little hop |
| `error` | `turn`, `text` | Caption shows `text` (keep it short, upper case reads best); a kept note is retried later. **Terminal:** it ends the turn like `done` (the firmware handles both the same way); sCoRE never sends `done` after an `error` |

The device fails a turn itself if the connection drops (`LOST sCoRE`) or nothing ends it within 60 s of `turn.end` (`sCoRE DIDN'T ANSWER`), and sends `turn.cancel`.

**Speaker off** (`speak: false`): sCoRE may skip TTS. Reply speech that still arrives is dropped, and the text stays up for reading.

## What sCoRE has to do for a voice turn

1. Collect the turn's PCM (or stream it into STT as it comes, sending `heard` partials).
2. On `turn.end`: send `sent`, then the final `heard`.
3. Run the turn through the entity (LLM, Grimoire context).
4. Stream `reply` text deltas, and TTS reply speech as binary `0x02` frames, starting on the first sentence: the point is to start speaking before the reply is finished (what the Muse gadget couldn't do).
5. `done`.

Local-first: STT and TTS on the home box (Whisper-class, Piper-class) by default, cloud only as a deliberate choice.

## Capture turns

Added S264 for the Pocket's Capture mode ([capture plan](RaBbLE-Pocket-Capture-Plan.md)). Additive: `proto` stays `rabble-beam/0`. A device that never sends `mode: "capture"` sees no change.

A capture turn is a note, not a conversation: no entity reply, no speech back. sCoRE transcribes, shapes the transcript into a markdown note and sends the file back for the device to keep.

**Device to sCoRE**

| type | Fields | When |
|---|---|---|
| `turn.begin` | as voice/text, with `mode: "capture"`, `id` (the note id, made by the device: `YYYYMMDD-HHMM-<device suffix>-<turn>`, lower case), `started` (UTC seconds when recording began; older than now for a capture recorded offline), `tz` (optional IANA zone, for the note's local time), `text` (typed captures only) | Capture started, or a saved capture uploaded |
| *(binary 0x01)* | speech, as voice turns | Live or uploaded. Up to 10 min a turn (sCoRE: `BEAM_CAPTURE_MAX_S`, default 600) |
| `turn.end` | `turn` | Recording stopped (voice captures) |
| `note.saved` | `id` | The device has the whole note on its storage; sCoRE drops its kept copy |

`speak` and `voice` are ignored for captures.

**sCoRE to device**

| type | Fields | Device does |
|---|---|---|
| `sent` | `turn` | As voice: sCoRE has all the speech; a saved recording can be dropped once the note arrives |
| `heard` | `turn`, `text`, `final` | Caption, as voice (final transcript) |
| `note` | `turn`, `id`, `title`, `path` (suggested, `YYYY/MM/<id>.md`), `seq` (0, 1, ...), `last` (bool), `md` (this part of the file, UTF-8, at most 8 KB) | Appends the parts in `seq` order; on `last` writes the file, answers `note.saved` |
| `done` | `turn` | Capture finished |
| `error` | `turn`, `text` | As voice; a saved recording is kept and retried |

**What sCoRE does for a capture**

1. Collect speech (cap `BEAM_CAPTURE_MAX_S`); on `turn.end` send `sent`, transcribe (split into segments of at most 5 min for STT), send the final `heard`. Typed captures skip STT.
2. Shape: one fast-tier LLM call returns `title` (≤ 60 chars), `tags` (≤ 5, kebab-case), `summary` (bullets) and `notes` (cleaned, structured, the speaker's words kept where they matter, nothing invented). If it fails or times out, the note still goes out with a title from the first words and the transcript alone.
3. Assemble the file: YAML frontmatter (`id`, `type: pocket-note`, `title`, `created` (local ISO time with offset, from `started` and `tz`), `device`, `source: voice|text`, `duration_s` (voice), `tags`), then `## Summary`, `## Notes`, `## Transcript` (verbatim STT, never edited).
4. Send it as `note` parts, then `done`.
5. Keep the assembled note per user and device until `note.saved` arrives (in memory, newest 20, 24 h). After `ready` on a later connection, send any kept notes again (`turn` 0, no `done` after them).
6. A capture never touches the conversation history.

A long voice capture takes sCoRE well over a minute (STT in 5-min segments, then shaping), so the device's 60 s wait after `turn.end` doesn't apply to captures.

## Translate turns

Added S338 for the Pocket's Translate mode. Additive: `proto` stays `rabble-beam/0`. A device that never sends `mode: "translate"` sees no change.

Device to sCoRE: `turn.begin` with `mode: "translate"`, `lang` (the target language as an English name, e.g. `"French"`; missing, longer than 32 characters, or anything but letters, spaces, hyphens and apostrophes means `"English"`), and `speak` (bool, default `true`). Then mic frames and `turn.end` exactly as a voice turn, with `voice` honoured the same way.

sCoRE to device: the reply is identical on the wire to a voice turn: `sent`, `heard` (the source-language transcript), `reply` text deltas (the translation and nothing else), reply speech as `0x02` frames, then `done`. Errors and `speak: false` behave as for voice; if speech quota runs out mid-reply the text still arrives and the turn still ends with `done`.

sCoRE side: STT auto-detects the spoken language, one LLM call translates faithfully into `lang` (names and numbers kept; text already in `lang` is said back cleaned; the transcript is treated as data, never as instructions). A translate turn uses the plain model chain (no laptop node) and neither reads nor writes the conversation history.

Per-device guest accounts (`POST /api/v1/users/guest`, tier `guest`) use the beam like any member key. Over the shared daily guest allowance, sCoRE answers a turn with `error` text `GUEST LIMIT REACHED` (guests also pause while the shared Groq quota is busy). That `error` may carry an extra `reason` string; devices can ignore it.

## Reserved for later versions

- Codecs (byte 1): ADPCM (4:1, the firmware already has an IMA ADPCM codec) or Opus for slow links.
- Face cues from sCoRE (`face` with a mood or mode), once the puppet schema is settled ([NeBuLA-Pocket-Puppet-Rendering-Pipeline](../log/plans/NeBuLA-Pocket-Puppet-Rendering-Pipeline.md)).
- Wake-word turns (`mode: "wake"`) with on-device VAD ending the turn instead of a release.
- Device commands from sCoRE (volume, sleep).
