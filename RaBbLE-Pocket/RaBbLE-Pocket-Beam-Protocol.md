# RaBbLE-Pocket-Beam-Protocol.md

The beam: how RaBbLE-Pocket talks to sCoRE. One WebSocket carries push-to-talk turns: speech up while the button is held, then the transcript, reply text and reply speech back down, speech playing as it arrives. **Status: v0, working end to end (2026-10-06).** Firmware: `RaBbLE-Pocket` `rabble_beam_score.c`. sCoRE: `RaBbLE-sCoRE/server/beam.py` (Groq Whisper STT, RaBbLE on Groq gpt-oss-20b, Groq Orpheus TTS; speech starts 1.5–2.2 s after release on the LAN). `RaBbLE-Pocket/ops/beam-echo.py` is a no-cloud stand-in that plays your speech back.

Firmware: `RaBbLE-Pocket/firmware/components/rabble_gadget/accord/rabble_beam_score.c` (session) behind `apache/rabble_beam.h` (the seam the voice loop calls). Port record: [RaBbLE-Pocket-Gadget-Port](RaBbLE-Pocket-Gadget-Port.md).

## Endpoint

- `ws://` or `wss://` URL, set on the device (Settings > sCoRE, or console `>beam.url=`). Firmware dev default: `ws://rabble-os.local:8000/api/v1/beam` (`CONFIG_RABBLE_BEAM_DEFAULT_URL` in `sdkconfig.defaults`), so the path sCoRE should serve is `/api/v1/beam`.
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
| `error` | `turn`, `text` | Caption shows `text` (keep it short, upper case reads best); a kept note is retried later |

The device fails a turn itself if the connection drops (`LOST sCoRE`) or nothing ends it within 60 s of `turn.end` (`sCoRE DIDN'T ANSWER`), and sends `turn.cancel`.

**Speaker off** (`speak: false`): sCoRE may skip TTS. Reply speech that still arrives is dropped, and the text stays up for reading.

## What sCoRE has to do for a voice turn

1. Collect the turn's PCM (or stream it into STT as it comes, sending `heard` partials).
2. On `turn.end`: send `sent`, then the final `heard`.
3. Run the turn through the entity (LLM, Grimoire context).
4. Stream `reply` text deltas, and TTS reply speech as binary `0x02` frames, starting on the first sentence: the point is to start speaking before the reply is finished (what the Muse gadget couldn't do).
5. `done`.

Local-first: STT and TTS on the home box (Whisper-class, Piper-class) by default, cloud only as a deliberate choice.

## Reserved for later versions

- Codecs (byte 1): ADPCM (4:1, the firmware already has an IMA ADPCM codec) or Opus for slow links.
- Face cues from sCoRE (`face` with a mood or mode), once the puppet schema is settled ([NeBuLA-Pocket-Puppet-Rendering-Pipeline](../log/plans/NeBuLA-Pocket-Puppet-Rendering-Pipeline.md)).
- Wake-word turns (`mode: "wake"`) with on-device VAD ending the turn instead of a release.
- Device commands from sCoRE (volume, sleep).
