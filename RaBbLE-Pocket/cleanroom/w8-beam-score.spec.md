# W8 spec: the beam's sCoRE session layer (`rabble_beam_score.c`)

> Clean-room spec, wave W8. Author role: S (Sonnet 5.5 sub-agent, S297), revised after the firewall reviews of 2026-11-03 and 2026-11-05 (two rounds; all required edits applied). Firewall: re-review pending (F reads this against the current file and the Meta Muse Gadget SDK at `b139b45`; passages that carry expression go back to S). File to be replaced: `firmware/sdk/rabble_net/rabble_beam_score.c`; the 2026-11-02 provenance audit flags it at 15.4% verbatim overlap with the SDK. The new file keeps the same path and carries the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Interface names are frozen. Companions: `w3-beam.spec.md` (status side, `rabble_beam.c`; see the string ruling in section 14), `w1-text.spec.md` (console lines, caption paging, tail words; `rabble_beam_text.c`), `w4-voice.spec.md` (the consumer), `w3-settings.spec.md` (URL, token, voice, speaker). Wire format is forced by the public protocol: `RaBbLE-Pocket-Beam-Protocol.md`. Where that doc is exact, it wins over this spec.

Target tree: W8 runs now, before the R1 reorganisation, so every path and ownership statement here describes today's tree (settings in core, capture declaration in `rabble_capture.h`, file under `sdk/rabble_net/`). R1 is a pure move that carries the clean file with it.

Treatment: clean room. Everything below is a requirement about observable behaviour. Numbers and strings are behaviour values (section 14 says which are forced and which are tuning). How you split functions, name statics, order code, structure the task loop, track turn state, and choose queues, locks, atomics or any other primitive is yours. This spec deliberately does not say.

---

## 1. Purpose

The session layer is the only part of the device that speaks beam protocol v0 to sCoRE. It:

- keeps one WebSocket to sCoRE open when it is wanted, with backoff when it is not reachable, and closes it when the device has been resting and idle;
- turns calls from the voice task (speech in, turn control) into protocol messages and binary audio frames;
- turns what sCoRE sends (text messages, reply speech, notes) into events, captions, reply audio and saved notes for the rest of the firmware;
- runs voice turns, typed turns and capture turns (voice or typed) with timeouts and failure texts.

It does not draw anything, does not decide when to talk, does not own Wi-Fi, and does not format console lines or caption pages (it calls the existing helpers). It owns no persistent data except through `rabble_notes_put`.

## 2. Public interface (complete and frozen)

All of these are already declared; the implementer does not change any header. Declarations live in `rabble_beam.h` (including types `rabble_beam_state_t`, `rabble_beam_status_t`, `rabble_beam_ev_t`), `rabble_beam_priv.h` (`rabble_beam_configured`, `rabble_beam_report`, `rabble_beam_session_connect`, `rabble_beam_session_forget`) and `rabble_capture.h` (`rabble_beam_capture_text`). The implementer reads those headers as the contract and defines exactly these functions in the new file.

Interface the status module provides, as prose (so nothing else need be opened): `rabble_beam_configured()` returns true when a sCoRE URL is stored. `rabble_beam_report(state, detail)` takes a link state (one of untested, testing, reachable, unreachable, as named in `rabble_beam.h`) and a short detail string, and updates what the status line shows. Both are defined by the status module and only called here. `session_connect` and `session_forget` are defined here and called by the status module.

Blocking bound: unless the row says otherwise, a call returns promptly (bounded well under a quarter of a second) whatever the session is doing, and is safe from the task named in its row.

| Function | Caller | Contract |
|---|---|---|
| `void rabble_beam_start(void)` | boot (`app` start-up, once) | Brings the module up. Idempotent: a second call does nothing (one session task only). On memory shortage, log an error and leave the module inert: every other function below must then be safe to call (no crash, `ready` false, events none). Must not block. |
| `bool rabble_beam_ready(void)` | voice | True iff start succeeded, a sCoRE URL is stored, and Wi-Fi is connected. Says nothing about the socket. Any task. |
| `void rabble_beam_set_resting(bool)` | voice | Records whether the device is resting (screen off on battery and idle, voice's call). A change from resting to not resting makes the session want a connection (4.2). |
| `void rabble_beam_session_connect(void)` | settings UI via the status module (`rabble_beam_test`) | "Test connection": the session should keep a connection and try now, skipping any backoff wait. |
| `void rabble_beam_session_forget(void)` | status module (`rabble_beam_config_changed`) | Settings changed (URL, token): drop the connection, fail the current turn if any, reset backoff, try again at once if a connection is wanted. |
| `void rabble_beam_turn_begin(void)` | voice, on talk pressed | Starts a new turn (voice, or a capture if Capture mode is on when the session processes it). When the call returns, all of these hold: the turn number has advanced, no earlier-turn speech is waiting to go up, no earlier-turn reply speech is waiting to play, and the session has been asked to begin the turn. The voice task may start pushing speech immediately, before the socket exists. |
| `void rabble_beam_turn_audio(const int16_t *pcm, size_t frames)` | voice | Queue mic speech for sending, without blocking. When the 8 s backlog cannot take it all, drop the whole call and log a warning (nothing of it is kept). |
| `size_t rabble_beam_turn_audio_wait(const int16_t *pcm, size_t frames, int wait_ms)` | voice (offline-note replay) | Same, but waits up to `wait_ms` for room; returns the number of samples taken (may be fewer than offered). |
| `void rabble_beam_turn_end(void)` | voice, on release plus tail | Marks the current turn's speech complete (5.3). |
| `void rabble_beam_turn_cancel(void)` | voice, on tap/barge-in/giving up | Abandons the current turn: from the moment this returns, no event, transcript, caption or audio of the old turn is ever returned to the voice task; a cancel message goes to sCoRE if the turn had begun; reply speech not yet read is thrown away. Safe when there is no turn. |
| `rabble_beam_ev_t rabble_beam_turn_event(char *text, size_t cap)` | voice, polled | Non-blocking. Returns the oldest pending event that belongs to the current turn, copying its text (truncated, always NUL-terminated) into `text`; events of other turns are silently discarded on the way. `RABBLE_BEAM_EV_NONE` when nothing. |
| `bool rabble_beam_turn_heard(char *out, size_t cap)` | voice | The current turn's whole transcript as last sent by sCoRE (up to 1023 characters), false if sCoRE has not said anything for this turn or the text is empty. |
| `bool rabble_beam_turn_caption(size_t played, char *out, size_t cap)` | voice | The caption window for the reply text so far, given how many reply samples the speaker has played (7.4). False when no reply text exists. |
| `size_t rabble_beam_turn_read(int16_t *pcm, size_t frames, int wait_ms)` | voice playback | Takes up to `frames` reply samples, waiting up to `wait_ms` for the first ones. Returns samples read (0 on timeout). A partial take is allowed. |
| `void rabble_beam_text_turn(char *text)` | console (via input) | Takes ownership of `text` (malloc'd), runs a typed turn (section 8). The text is freed exactly once on every path: refused, superseded, cancelled, failed, settings changed, or sent. If the beam has no URL: console `error` "NO sCoRE ADDRESS SET", text freed. If the request cannot be accepted within 1 s: console `error` "QUEUE FULL", text freed. |
| `void rabble_beam_capture_text(char *text)` | console (via input) | Same, for a typed capture. Same two refusals. |
| `void rabble_beam_text_cancel(void)` | console | Cancels the current typed turn only; a voice turn is left alone. |
| `bool rabble_beam_configured(void)`, `void rabble_beam_report(...)` | defined by the status module | Called, not defined. `report(state, detail)` is how this layer tells the status module what happened; detail strings in 4.3. |

Capacity: at least 16 requests (any mix of the calls above that ask the session to do something, other than turn_begin, turn_end and turn_cancel, see below) may be outstanding at once without loss. The 17th may be refused; typed text refuses with "QUEUE FULL" as above.

Callers: the voice task (all `turn_*`, `ready`, `set_resting`), the console input module (`text_turn`, `text_cancel`, `capture_text`), the status module (`session_connect`, `session_forget`), and app start-up (`rabble_beam_start`). Test doubles of these live in `firmware/test/voice/voice_test/voice_test.c` and `firmware/test/app/input_test/input_test.c` (behavioural examples of how callers use the API).

Contract with voice, stated once: turn numbers are positive, strictly increasing, one per `turn_begin` or typed turn; "current turn" is the number allocated last. After `turn_cancel` the current turn number is advanced too, so the cancelled turn's late events cannot be mistaken for a new one.

Turn-number visibility: speech pushed after `turn_begin` returns is never sent under an older turn's number, even if the session was still busy with the old turn when `turn_begin` was called. Never refused: `turn_begin`, `turn_end` and `turn_cancel` are not subject to the request capacity. `turn_begin` always advances the turn number; `turn_end` and `turn_cancel` are marks on the turn they name (a later mark on the same turn replaces an earlier one), so they always take effect even when the 16-request backlog is full. Only typed text and typed capture text can be refused for capacity (section 2).

## 3. Collaborators the module calls

| Module | Used for |
|---|---|
| `rabble_settings` | `beam_url`, `beam_token`, `speaker_on`, `voice` (read each time they are needed, so changes apply live; any private copy of the token is wiped once the dial has completed or failed and the client no longer needs it, see 4.4) |
| `rabble_wifi` | `rabble_wifi_connected()` |
| `rabble_device` | `rabble_device_name()` (e.g. `RaBbLE-Pocket-5EB8`) |
| `rabble_time` | `rabble_time_from_server(utc, rtt_s)`, `rabble_time_zone_iana()` |
| `rabble_capture` | `rabble_capture_on()` (at the moment a voice turn is started by the session), `rabble_capture_saved()` |
| `rabble_notes` | `rabble_notes_put(id, title, md, len)`, error codes `ESP_ERR_NO_MEM`, `ESP_ERR_INVALID_ARG` |
| `rabble_beam_text` | `rabble_beam_tail_words`, `rabble_beam_caption_at`, `rabble_beam_console` |
| `rabble_audio` | `RABBLE_AUDIO_RATE` (16000) |
| `rabble_mem` | `RABBLE_BIG_CAPS` |
| ESP-IDF | `esp_websocket_client` (or the transport layer under it), esp-tls with the certificate bundle, FreeRTOS, cJSON, `esp_timer`, `esp_app_get_description` |

## 4. Connection behaviour

### 4.1 Link states

Three: **closed**, **dialling** (client started, upgrade not complete), **open** (client reported connected). Only the session task acts on link state; the client's own event callback may note "the socket went away" for the session task to act on.

### 4.2 When a connection is wanted

A connection is wanted when (a) the URL is set and Wi-Fi is connected, and (b) either something asked for one (Wi-Fi came up, a connect request, a wake from resting, settings changed) or a turn is active. A turn forces the dial and ignores any backoff wait. Wi-Fi going from down to up with a URL set counts as an ask.

Responsiveness (observable bounds, not a cadence to copy): queued speech leaves within about 25 ms; a request or client event arriving during a turn or a dial is acted on within about 25 ms; anything else (including a Wi-Fi edge while idle) within 500 ms. Wi-Fi lost while the socket is open does not by itself close it: the connection becomes unwanted, and it ends when the client reports the drop or the pong timeout fires.

### 4.3 Transitions and what is reported to the status module

| Event | Action | Report |
|---|---|---|
| Wanted, closed, backoff wait over (or turn active) | Start the client with the settings URL and token (4.4). | `TESTING`, "Dialing sCoRE..." |
| Client init fails (bad URL) | Stay closed. No backoff growth. Do not retry or re-report until the URL changes, a connect request arrives, or a turn starts (fix F-3, section 15). | `UNREACHABLE`, "Bad address" |
| Client start call fails | Tear down, stay closed. Counts as a dial failure: start backoff (4.5), fail the current turn with "NO LINK TO sCoRE". No redial sooner than the backoff allows (a turn start or connect request still bypasses it once). | `UNREACHABLE`, "Dial failed" |
| Dialing and client reports drop/error, or the 8 s dial limit passes | Tear down; start backoff (4.5); fail the current turn with "NO LINK TO sCoRE". | `UNREACHABLE`, "Dial failed" |
| Client reports connected | State open. Log the connect time in ms. | none yet |
| Socket opens | Reset backoff to 5 s; send `hello` (4.6) as the first message. | `REACHABLE`, "Linked" |
| `ready` message arrives | See 7.1. | `REACHABLE`, the name if non-empty else "Linked" |
| Open and client reports drop/close/error | Tear down; start backoff; fail the current turn with "LOST sCoRE". | `UNREACHABLE`, "Connection lost" |
| Resting, no active turn, and 2 minutes since the connection opened or the last frame (text or binary) was sent (whichever is later) | Close; stop wanting a connection until a wake/press/test/Wi-Fi edge. | `UNTESTED`, "Wakes when you talk" |
| `session_forget` | Tear down; fail current turn "sCoRE ADDRESS OR TOKEN EDITED"; backoff reset to 5 s; allow an immediate dial. | none |
| `session_connect` | While dialling: no effect. Otherwise want a connection; allow an immediate dial. If the socket is already open, report `REACHABLE`/"Linked" (ruled, Q1). | `TESTING` only if it actually dials |

### 4.4 Dialing

- URL and token come from settings at dial time. The token goes in an `Authorization: Bearer <token>` header on the upgrade request when non-empty (none when empty), nowhere else, never logged. If you keep a private copy of the token, it must stay valid until the client and transport no longer reference it (the upgrade is done or the dial failed), and be wiped after that.
- `ws://` and `wss://` both work. `wss://` verifies the server with the ESP-IDF certificate bundle (`esp_crt_bundle_attach`).
- **TLS session reuse for `wss://`** (behavioural requirement, forced by the freeze described in 9.1): a reconnect to the same server must offer the TLS session from the previous connection so the handshake is abbreviated, when the server provided a ticket; if it did not, fall back to a full handshake. Changing settings to a different URL must not offer the old session (fix F-4, section 15). How you obtain reuse from ESP-IDF is yours, subject to three facts about the public ESP-IDF components that RaBbLE established and that you cannot discover from the headers:
  1. `esp_websocket_client` only configures the path and headers on transports it creates itself. If you hand it your own transport (needed to keep a TLS session across connections), you must set the upgrade path and the `Authorization` header on that transport yourself, or a `wss://` dial goes out without the token and without the path. A custom transport must also set `propagate_control_frames` true; otherwise it swallows the pongs itself, the client never sees them, and the link drops at the 45 s pong timeout.
  2. Saving a TLS session releases the session object that the TLS configuration may still point at. Saving or reusing a session when the server sent no ticket returns an error and can leave the TLS configuration pointing at a freed session. Whatever you keep across connections, the TLS configuration must never be left pointing at a released session, and a failed save must leave no session offered next time.
  3. A transport you create yourself has no default port: for a `wss://` URL without an explicit port you must set the transport's default port to 443, or the dial goes to the wrong port.
- Client parameters: receive/transmit buffer 4096 bytes; the client's own task has a 6144-byte stack, priority 5, and runs on the network core, core 0, not the UI core (on a build where both are core 0 this is trivially met); the client's automatic reconnect is **off** (this layer does all reconnecting); ping every 15 s, give up after 45 s without a pong; network timeout 10 s; ping/pong/close control frames are not delivered to message handling; the client must still see pongs (see fact 1 for a custom transport).
- Sends have a 5 s timeout. A failed text send is not fatal by itself (for turn.begin see 5.2) (it is noticed by the failing turn or by the client reporting the drop); a failed audio send fails the turn "LOST sCoRE".

### 4.5 Backoff

Wait before the next unforced dial after a failure: first 5 s; each further failure doubles it, capped at 120 s (5, 10, 20, 40, 80, 120, 120, ...). A successful open resets it to 5 s when the connection opens and `hello` is sent. An explicit ask (connect request, Wi-Fi edge) zeroes the wait but does not reset the doubling; settings-changed zeroes the wait and resets the doubling. A wake from resting leaves the wait as it was. A turn bypasses the wait for its own dial.

### 4.6 `hello`

Sent once per open socket, as the first message. Text frame, one JSON object with exactly: `type:"hello"`, `proto:"rabble-beam/0"`, `device:<device name>`, `fw:<application version string>`, `audio:{rate:16000, format:"pcm16le", channels:1}`. Record the time it went out (for the round trip in 7.1).

## 5. Turn lifecycle (device side)

One turn at a time. A turn has a number and a kind (voice, capture-by-voice, typed, typed-capture). How you record its progress is yours; the rules below are what must hold.

### 5.1 Starting

| Trigger | Kind | Turn number | Notes |
|---|---|---|---|
| `turn_begin` | voice; or capture-by-voice when `rabble_capture_on()` is true at the moment the session processes the request | allocated in the caller's context | If a turn is already active and has been announced to sCoRE and the socket is open, `turn.cancel` goes out for it first. |
| `text_turn` | typed | allocated when the session processes the request | Refused with console `error` "VOICE TURN IN PROGRESS" when a voice (non-typed) turn is active; the text is freed. A typed turn replaces an active typed one (cancel sent as above). |
| `capture_text` | typed capture | as typed | Same refusal. |

Starting a turn clears the previous reply text, reply sample count and reply-complete mark, notes the UTC start time (`time(NULL)`), makes reply audio for this turn (and only this turn) acceptable, and makes the turn's messages acceptable.

### 5.2 `turn.begin`

Goes out as soon as the turn is active and the socket is open: the delay from the call is at most the dial time. If the send fails, it is retried no faster than every 100 ms for at most 8 s from the first attempt; if it still has not gone, the turn fails with "LOST sCoRE", as a failed audio send does (no turn hangs forever on this). Fields:

| Field | Value |
|---|---|
| `type`, `turn` | `"turn.begin"`, the full turn number (JSON number) |
| `mode` | `"voice"`, `"text"`, or `"capture"` |
| capture extras | `id` (note id, 5.5), `started` (UTC seconds, JSON number), `tz` (IANA zone from `rabble_time_zone_iana()`) |
| `speak` | true only for a voice turn (not text, not capture) with the speaker switched on; otherwise false |
| `voice` | only when the stored voice name is non-empty |
| `text` | only for a typed turn or typed capture: the typed text |

A typed turn or typed capture sends no audio and no `turn.end`: its `turn.begin` is the whole device side, and the answer clock (5.4) starts when that send succeeds. The held text is released then.

### 5.3 Sending speech and `turn.end`

Speech pushed after the turn has ended (after `turn.end` has gone) is dropped. Speech pushed by the voice task goes out only after `turn.begin` has gone, in order, as binary frames of at most 640 samples (1280 bytes of PCM, 40 ms), each with the 4-byte header from the protocol (kind `0x01`, codec `0x00`, turn number low 16 bits little-endian). A frame may carry fewer samples when that is all that was available.

`turn.end` goes out exactly once per voice or capture-by-voice turn: only after `turn_end` has been called and after the last queued sample has gone. The answer clock runs from the moment `turn.end` went out.

### 5.4 Endings

| Cause | Device does | Voice sees |
|---|---|---|
| `done` from sCoRE for the live turn | stops accepting reply audio for the turn, marks reply speech complete (7.4), turn is over | DONE event |
| `error` from sCoRE for the live turn | same, text kept (empty text becomes "sCoRE ERROR") | ERROR event with the text |
| Socket drop or dial failure with the turn active | turn failed with the text from the table in 4.3; a typed turn reports on the console instead (8) | ERROR event |
| Answer clock expires: 60 s for voice and typed turns, 600 s for any capture (voice or typed), measured as in 5.2/5.3, with nothing ending the turn | send `turn.cancel` if open; fail with "sCoRE DIDN'T ANSWER" | ERROR event |
| Audio send fails | fail with "LOST sCoRE" | ERROR event |
| `turn_cancel` / `text_cancel` for the active turn | if announced and open send `turn.cancel`; turn is over; reply audio no longer accepted | nothing |
| Superseded by a new turn | as `turn_cancel` for the old one | nothing |

Failing a turn is a no-op when no turn is active. Any ending means late messages for that turn are ignored. The capture answer clock is 600 s (Mark's ruling, Q2); it replaces the original's 60 s for captures, which cut long captures off.

### 5.5 Note id for captures

`YYYYMMDD-HHMM-<suffix>-<turn>` in lower case: local time of the turn's start (`localtime`), then the suffix, then the low 16 bits of the turn number in decimal. Suffix: take the part of the device name after its last `-` (the whole name if there is none), keep only ASCII letters and digits, lower-case them, at most 8 characters; if nothing is left use `p`. Always fits `RABBLE_NOTE_ID_MAX` (47).

## 6. Task and request handling

### 6.1 Task

One session task, `rabble_beam`, priority **5**, stack **6144 bytes in internal RAM** (it touches NVS and TLS), on the network core (core 0). Created by `rabble_beam_start`. It never exits.

### 6.2 Request handling

Every section-2 call that asks the session to act takes effect in call order, by that one task. A finished note (7.3) is stored in order with those requests. `end` and `cancel` act only if their turn number is still the active one. Which mechanism carries the request, and the shape of the session loop, are yours. Observable limits are in section 2 (blocking bound, capacity, "QUEUE FULL") and 4.2 (responsiveness).

## 7. What sCoRE sends

### 7.1 Text messages

A message is a UTF-8 JSON object. The client may deliver it in several pieces; reassemble. Throughout this spec, a "later piece" means any later delivery of the same message, whether a further chunk of one WebSocket frame or a continuation frame. Messages of 32 KiB or more are skipped whole with a log line. Unparsable JSON: log a warning, ignore. Unknown `type`: ignore. In the table below, "voice" means a voice turn or a capture-by-voice turn. A turn-scoped message (`heard`, `sent`, `reply`, `done`, `error`) is acted on only if its `turn` is a number equal to the live turn (non-zero); otherwise ignored. `ready` and `note` are not turn-scoped.

| `type` | Effect |
|---|---|
| `ready` | Report `REACHABLE` with `name` (or "Linked"). If `time` is a number, call `rabble_time_from_server(time, seconds since hello was sent)`. |
| `heard` | Store `text` as the turn's whole transcript (max 1023 chars), for every turn kind. For voice and capture-by-voice turns also emit a HEARD event whose text is the tail of the transcript, made by `rabble_beam_tail_words` into the event text (72 bytes). For typed turns no event: the transcript is stored only. |
| `sent` | Voice: SENT event. Typed: console `sent`. |
| `reply` | Typed: console `text` line with the delta. Voice: append the delta to the reply text (cap 4095 characters plus terminator; a delta that would not fit whole is dropped whole) and emit a REPLY event with the delta (truncated to the event text size). |
| `done` | Reply speech marked complete. Typed: console `done`. Voice: DONE event. Reply audio no longer accepted; turn over (5.4). |
| `error` | Log the text. Typed: console `error` with the text or "sCoRE ERROR". Voice: ERROR event, same default text. Reply audio no longer accepted; turn over. |
| `note` | 7.3. |

Event delivery guarantee: if the voice task polls `turn_event` at least every 50 ms, it never misses a DONE, an ERROR or a SENT event of the current turn. HEARD and REPLY events (the in-progress caption updates) may be dropped when the voice task falls behind; the stored transcript and reply text are unaffected by drops. The event backlog holds at least 16 events.

### 7.2 Binary frames (reply speech)

Header: 4 bytes. Accepted only if kind is `0x02`, codec is `0x00`, the turn's low 16 bits match the live turn, and the frame is at least 4 bytes. Anything else is ignored, including audio of an old turn, a second codec, or audio after `done`. Payload is PCM16 LE mono 16 kHz. Only the first piece of a message carries the header; later pieces are payload only.

- Whole samples only: a message (or a later piece of one) may end on an odd byte; carry that byte and join it to the next piece of the same message; drop a leftover odd byte when the message ends or a new message starts.
- If the speaker is switched off in settings, drop the payload (the text still shows).
- Push into a reply buffer of 4 s; when it is full, wait for room and retry: this is the intended backpressure on sCoRE. This is the one place the client callback may wait longer than the bound in 9.1. It stops waiting, abandoning the rest of the frame, when the turn is cancelled, superseded, ended by the answer clock, or by `session_forget` (all acted on by the session task, which can fire while the callback waits). A socket drop or `done` arrive through the same callback and are therefore noticed only after the wait ends; a stalled reader with a live turn can block until one of the listed exits. Individual waits should be short (about 1 s) so those exits are noticed promptly.
- Count samples accepted for the caption (7.4).

### 7.3 Notes from sCoRE (captures and re-sends)

Parts arrive as `note` messages with `id`, `title`, `seq`, `last`, `md`. Not tied to the live turn: sCoRE re-sends kept notes after `ready` with turn 0.

- `seq` 0 starts a note: discard any note in progress, remember `id` and `title` (truncated to the notes store's limits: id 47, title 95 bytes).
- A part is appended only if `seq` is the next expected and `id` equals the note's id; otherwise drop the whole note in progress and log a warning.
- Total size capped at 256 KiB; a part that would exceed it drops the note with a warning.
- On a part with `last` true, the whole note is stored by the session task, which calls `rabble_notes_put(id, title, md, len)`:
  - success: send `{"type":"note.saved","id":<id>}`, console `note` with the title and fields `"id":"<id>","bytes":<len>`, call `rabble_capture_saved()`;
  - failure: console `error` "NOTES FULL" for `ESP_ERR_NO_MEM`, otherwise "NOTE NOT SAVED", with field `"id":"<id>"`; **no** `note.saved` (sCoRE re-sends later).
- If the note cannot be handed to the session task promptly, it is discarded (sCoRE re-sends later).

### 7.4 Captions

`rabble_beam_turn_caption(played, ...)` shows where the speech is in the reply text. Let `len` be the reply text length and `n` the reply samples received so far. If `len` is 0, return false. The position handed to `rabble_beam_caption_at(text, position, out, cap)` (whose result is returned) behaves as follows: it is 0 when `played` is 0; it never decreases as `played` grows; it is proportional to `played` over the estimated total speech length; it is never past the last character; and once the reply is marked complete and `played` equals `n`, it is the last character. The estimated total is `n` once the reply is complete; before that it is the larger of `n` and a reading-pace estimate derived from `len` (pace is the implementer's choice within 12 to 16 characters per second). The caption must be computed from a consistent snapshot of the reply text (never a half-appended delta).

## 8. Typed turns and console output

A typed turn or typed capture reports on the serial console, not through events: `sent`, reply deltas (`text`), `done`, `error` all go through `rabble_beam_console(type, text, fields, ...)` as in the table of 7.1; failures of the turn use the same text strings as 4.3 and 5.4. Console writes happen on whichever task saw the message, so they must not block for long.

A typed capture sends `mode:"capture"` with the extras, `speak:false`, and the typed `text`; it sends no audio and no `turn.end`. Its note arrives via 7.3.

## 9. Constraints

### 9.1 Priorities, cores, blocking

- Session task: prio 5, network core (core 0), 6144 bytes internal. The client's task: prio 5, core 0, 6144 bytes. The voice task is 6 on core 1; the UI shares core 1 at 5 (see `rabble_mem.h`).
- Why core 0 and not the UI core: while the client's task holds its own client lock during a TLS handshake it inherits the priority of the Wi-Fi task, and a handshake is over a second of crypto; run on the UI core it starved the panel send task and the face froze (S264, "freeze = TLS prio inheritance"). This is the reason for the core pin and for the TLS session reuse in 4.4. **Do not** move either task to the UI core or raise either above 5. On a unicore build `RABBLE_UI_CORE` is 0 and the pin is moot.
- Thread safety: every public call may be made from the task named in its row in section 2 while the session task and the client's callback run concurrently. Data shared between them must be consistent (no torn reads, no lost ownership of `text`). How is yours. No call into another module, send, allocation or log may be made while holding anything that disables interrupts or the scheduler.
- What may wait in the client's callback: console writes, and short bounded hand-offs (event delivery under 7.1's guarantee, handing a finished note to the session task), each bounded to well under a quarter of a second; the one exception is reply-audio backpressure, bounded as 7.2 says. The callback never calls the socket send itself.
- No heap allocation on the hot audio paths other than reused receive and send buffers.

### 9.2 Memory budget (internal RAM is scarce; PSRAM builds only)

| Item | Size | Where |
|---|---|---|
| Session task stack | 6144 B | internal |
| Client task stack + buffer | 6144 B + 4096 B | internal (client-owned) |
| Speech backlog | 8 s x 16000 x 2 B = 256000 B | PSRAM (`RABBLE_BIG_CAPS`) |
| Reply buffer | 4 s x 16000 x 2 B = 128000 B | PSRAM |
| Incoming text reassembly | 32768 B | PSRAM |
| Reply text | 4096 B | PSRAM |
| Transcript | 1024 B | PSRAM or static; **not** the internal heap when PSRAM exists |
| Request and event backlogs | small; section 2 and 7.1 give the capacities | PSRAM when it holds the bulk of it, else your call |
| Note in progress | up to 256 KiB + header, grown as needed | PSRAM |
| cJSON | allocate through the same big-memory route, free matching | PSRAM |

Large buffers must come from `RABBLE_BIG_CAPS`; with PSRAM absent that falls back to internal RAM and the module must still run with the same sizes (sizing for that build is not a W8 concern). A failed big-memory allocation falls back to plain `malloc` before giving up (this is a fix, F-2, section 15).

## 10. Test plan

Three layers, matching the other waves.

### 10.1 Host test (`firmware/test/net/score_test/`, plain gcc, new)

Build the new file against fakes of: `esp_websocket_client` (programmable: start result, connected/data/drop events delivered from the test, records every sent text/binary frame with timestamp), `esp_timer_get_time` (fake clock), FreeRTOS shims, cJSON (real library from the IDF tree or a vendored copy), and the collaborator headers listed in section 3 (declarations only, the real headers are public). The existing `firmware/test/net/beam_test/fakes/freertos` contains only `FreeRTOS.h` and `task.h`; any queue, stream-buffer or other shim your design needs you write yourself in the new test directory. The test drives the session by whatever hook your design exposes for tests, or runs the task thread under a stub scheduler. Assertions use the fake clock so no sleeping is needed. The test process sets `TZ` itself (V28). A fake client cannot see transport-level header setup (4.4 fact 1); that is covered by live check 3.

Vectors (each a scenario, each must be asserted):

| # | Scenario | Expected |
|---|---|---|
| V1 | `start` twice | second call does nothing (one task) |
| V2 | URL unset, `turn_begin` | no dial; `ready` false |
| V3 | URL set, Wi-Fi down->up | dial within 500 ms of the Wi-Fi edge by fake clock; report `TESTING "Dialing sCoRE..."` |
| V4 | Client connects | first sent frame is text `hello` with the five keys of 4.6 (`type`, `proto`, `device`, `fw`, `audio`), `proto` exactly `rabble-beam/0`; report `REACHABLE "Linked"` |
| V5 | Dial never completes | after 8 s: client torn down, report `UNREACHABLE "Dial failed"`, next dial 5 s later; failures give waits 5, 10, 20, 40, 80, 120, 120 s |
| V6 | Success after two failures | wait resets to 5 s once a connection opens |
| V7 | Voice turn 7 begin, token "abc" | with a `ws://` URL the fake sees the upgrade request carry `Authorization: Bearer abc` (for `wss://` this is covered by live check 3); `turn.begin` JSON `{"type":"turn.begin","turn":7,"mode":"voice","speak":true}` (+`voice` only if set); order of keys is free; empty token: no `Authorization` header |
| V8 | Speech pushed before the socket is up (3 s of samples), then connect | after `turn.begin` all 3 s go out as frames of 1280 B (last may be smaller); frame header bytes for turn 7: `01 00 07 00`; for turn 0x12345: `01 00 45 23` |
| V9 | `turn_end` with samples still queued | `turn.end` only after the last frame, exactly once |
| V10 | `turn_cancel` before connect | no `turn.cancel` message ever; `turn_event` returns NONE even for events of the cancelled turn arriving later |
| V11 | `turn_cancel` after begin | exactly one `turn.cancel` with the old turn number |
| V12 | `heard` for turn 7, text of 200 characters | `turn_heard` returns all 200; the HEARD event text is the tail words of it, at most 71 characters plus NUL |
| V13 | `heard` for turn 6 while turn 7 is live | ignored |
| V14 | Reply audio for turn 7, one binary message in two pieces: first piece = `02 00 07 00` + 1281 bytes; second piece = 1 byte, no header | 641 samples readable via `turn_read` in total, none lost, no half sample ever returned |
| V14b | Same payload split as two separate messages (each with its own header) | 640 samples; the odd byte at the end of the first message is dropped |
| V15 | Reply audio with kind `01`, codec `01`, turn 8, or after `done` | dropped |
| V16 | Speaker off, reply audio arrives | dropped; `reply` text still appends; `turn.begin` carried `speak:false` |
| V17 | Reply text of 120 characters, 3200 samples received, not complete; then `done` | the position passed to a stub of `rabble_beam_caption_at` is 0 at `played == 0`, never decreases as `played` rises through 0..3200, never exceeds 119; after `done` with `played == 3200` it is 119 |
| V18 | `done` arrives | DONE event; later audio dropped |
| V19 | `error` with empty text | ERROR event text "sCoRE ERROR" |
| V20 | Nothing ends a voice turn after `turn.end` | no failure at 59 s; at 60 s `turn.cancel` sent and ERROR "sCoRE DIDN'T ANSWER" |
| V20b | Same for a voice capture (from `turn.end`) and a typed capture (from `turn.begin`) | no failure at 599 s; failure at 600 s |
| V21 | Socket drops mid-turn | ERROR "LOST sCoRE"; backoff started; report `UNREACHABLE "Connection lost"` |
| V22 | Dial fails with a turn active | ERROR "NO LINK TO sCoRE" |
| V23 | `session_forget` mid-turn | ERROR "sCoRE ADDRESS OR TOKEN EDITED"; client destroyed; redial immediately |
| V24 | Resting for 2 min with socket open and no turn | closed; report `UNTESTED "Wakes when you talk"`; resting->awake redials |
| V25 | Resting for 119 s, then a turn | no close |
| V26 | Typed turn "hi" | `turn.begin` with `mode:"text"`, `speak:false`, `text:"hi"`; no frames, no `turn.end`; replies come out as console lines; no HEARD event for a typed turn; refused with "VOICE TURN IN PROGRESS" while a voice turn is active |
| V27 | Typed turn, URL unset | console `error` "NO sCoRE ADDRESS SET"; text freed (check with a counting allocator) |
| V27b | Typed text, counting allocator, over each path: refused (voice turn active), refused (queue full), superseded by a new typed turn, cancelled before `turn.begin` went, cancelled after, settings changed, dial failed, sent | the text is freed exactly once on every path |
| V27c | Request backlog full (16 pending), then `turn_begin`, `turn_end`, `turn_cancel` | each still takes effect: the turn number advances on begin, end marks the turn complete, cancel suppresses all old-turn output and the cancel message goes out if the turn had begun |
| V27d | Client start call fails | failure reported "Dial failed", no second dial before the backoff has passed |
| V28 | Capture turn, device `RaBbLE-Pocket-5EB8`, started local 2026-11-03 14:07 with `TZ=America/New_York` set in the test, turn 7, zone "America/New_York" | `turn.begin` has `mode:"capture"`, `id:"20261103-1407-5eb8-7"`, `started` equal to the UTC seconds, `tz:"America/New_York"`, `speak:false` |
| V29 | Device name without a dash and with odd characters, `Pocket_#9`; and a name of `-` alone | suffix `pocket9`; suffix `p` |
| V30 | `note` parts seq 0,1,2 (`last` on 2), ids equal | one `rabble_notes_put` call with the concatenation; `note.saved` sent; console `note`; `rabble_capture_saved` called once |
| V31 | seq 0,2 | note dropped, no `put`, no `note.saved` |
| V32 | `rabble_notes_put` returns `ESP_ERR_NO_MEM` | console `error` "NOTES FULL", no `note.saved`; other error: "NOTE NOT SAVED" |
| V33 | Message of 40000 bytes | skipped, later messages still handled |
| V34 | `ready` with `time` 1792142822.691 sent 40 ms after `hello` | `rabble_time_from_server(1792142822.691, 0.040)` |
| V35 | Request capacity exhausted (16 pending) | `text_turn` returns within 1 s, console `error` "QUEUE FULL", text freed |
| V36 | Allocation failure in `start` | no crash on any later call (all of section 2) |
| V37 | `session_connect` while open and idle | report `REACHABLE "Linked"`, no dial |
| V38 | Bad URL; then fake time advancing with no change | one `UNREACHABLE "Bad address"` report, no repeat until URL change, connect request, or turn start |
| V39 | `turn_begin` while the previous turn's speech is still being sent; speech of the new turn pushed right after | no sample of the new turn is ever sent under the old turn's number |
| V40 | Event backlog flooded with HEARD/REPLY events while `done` arrives, voice polling every 50 ms | DONE is delivered |
| V41 | `turn_audio` with more than the 8 s backlog can take | whole call dropped, nothing of it sent; `turn_audio_wait` with room for part returns the count taken |
| V42 | Typed turn while a typed turn is active | `turn.cancel` for the old one, then the new `turn.begin`; `text_cancel` during a voice turn does nothing |
| V43 | `note` with parts totalling over 256 KiB | note dropped with a warning, no `put` |
| V44 | Note id of 60 characters, title of 200 | stored with id cut to 47 and title cut to 95 bytes |
| V45 | Reply text delta that would make the text exceed 4095 characters | delta dropped whole |

Sanitizers (address, undefined) on, as the other host tests.

### 10.2 Target compile check

`firmware/test/net/score_test/compile_check.sh` (new; model it on the compile-check script of the wifi test, `firmware/test/net/wifi_test/compile_check.sh`, listed in section 11): Xtensa `-O2 -Werror` compile of the new file against the real ESP-IDF headers. No warnings.

### 10.3 Live checks (integrator runs; implementer need not)

1. `uv run --with websockets RaBbLE-Pocket/ops/beam-echo.py --save /tmp/echo`: speaks protocol v0. Hold talk, release: expect a `ready`, caption "(N seconds of you)", your speech played back, DONE. Tap: expect `turn.cancel` in the echo log. Typed `>chat=hello` on the serial console: reply "You typed: hello" on the console.
2. Kill the echo server mid-turn: device shows "LOST sCoRE", retries at 5, 10, 20 s.
3. `wss://` against a real endpoint twice in a row: the second connect is faster and logs session reuse; the upgrade carries the token (server log).
4. UI responsiveness during a wss connect: the face must not stall (this is the S264 freeze).

## 11. Inputs the implementer may read

This section is the complete list. Read nothing else in the workspace, even if it is present. Anything not named here is out of bounds, in particular every other file under `sdk/`.

- This spec.
- `RaBbLE-Grimoire/RaBbLE-Pocket/RaBbLE-Pocket-Beam-Protocol.md` (the wire contract; do not follow its links to Capture-Plan or Gadget-Port).
- `RaBbLE-Pocket/ops/beam-echo.py` (a protocol-correct peer; read for frame layout and message shapes).
- Headers: `sdk/rabble_net/rabble_beam.h`, `rabble_beam_priv.h`, `rabble_beam_text.h`; `sdk/rabble_core/rabble_settings.h`, `rabble_device.h`, `rabble_time.h`, `rabble_mem.h`, `rabble_state.h`; `sdk/rabble_store/rabble_notes.h`, `rabble_capture.h`; `sdk/rabble_audio/rabble_audio.h`; `sdk/rabble_net/rabble_wifi.h`.
- Companion specs: `w1-text.spec.md`, `w3-beam.spec.md`, `w3-settings.spec.md`, `w4-voice.spec.md`.
- Caller-side tests as examples of use: `firmware/test/voice/voice_test/voice_test.c`, `firmware/test/app/input_test/input_test.c`, `firmware/test/net/beam_test/` (status side; its fakes are FreeRTOS.h and task.h only).
- ESP-IDF docs, public headers and sources (including `managed_components/` for `esp_websocket_client`): `esp_websocket_client`, `esp_transport_ssl`/`esp_transport_ws`, esp-tls, esp-mbedtls, FreeRTOS, `esp_timer`, `esp_app_format`, cJSON, `esp_crt_bundle`; the WebSocket RFC 6455; the TLS session ticket RFCs (5077, 8446 section 4.6.1).
- `RaBbLE-Pocket/firmware/test/README.md` and `firmware/test/net/wifi_test/compile_check.sh` (read for shape only; the latter names the file being replaced by path).
- `RaBbLE-Pocket/firmware/sdkconfig.defaults` and `firmware/test/paths.sh`/`run.sh` for test wiring.
- The sCoRE server side, `RaBbLE-sCoRE/server/beam.py` (RaBbLE's own code, public protocol peer).

## 12. Inputs the implementer must not read

In particular `sdk/rabble_net/rabble_beam.c`, `rabble_ui.c`, `rabble_app.c` and `rabble_motion.c`: they sit in the same tree, are not the contract, and must not be opened. The interface they provide is given as prose in section 2.

- The current `sdk/rabble_net/rabble_beam_score.c` (any revision), and its git history, including the former path `components/rabble_gadget/accord/rabble_beam_score.c` and `apache/`. The integrator exports without this file.
- `RaBbLE-Cleanroom/provenance-audit-2026-11-02/` (the SDK clone and the overlap report), `firmware/muse-gadget-sdk/`, `firmware/backups/`, `firmware/build/`, any copy or checkout of the Meta Muse Gadget SDK (`facebookincubator/muse-gadget-sdk`), in particular `muse_chat_session.cpp`, `noise_*` and `ClientSession.*`.
- The whole Grimoire `RaBbLE-Pocket/cleanroom/` directory except the specs named in section 11, including `audit-2026-11-02/`, `OVERLAP-REPORT.md`, `PROVENANCE.md`, `TRANSCRIPTS-*.md`, and every other open W8/W9/W11 spec.
- `RaBbLE-Pocket-Muse-SDK-Map.md`, `RaBbLE-Pocket-Gadget-Port.md`, `RaBbLE-Pocket-Capture-Plan.md` (it describes the current TLS code; the two facts needed from it are in 4.4).
- Any session log, handoff or transcript that quotes the file.

Integrator note (export filter for this wave): a plain `git archive` filters nothing under `sdk/`. Either export only the section-11 files, or exclude at least `sdk/rabble_net/rabble_beam_score.c`, `sdk/rabble_net/rabble_beam.c`, `rabble_ui.c`, `rabble_app.c`, `rabble_motion.c` and every file above 5% in the 2026-11-02 overlap report. Also: the Grimoire and `RaBbLE-sCoRE` paths named in section 11 lie outside the plan's `git archive` export; the integrator copies them in.

## 13. Rulings and open questions

Settled (Mark, 2026-11-03):

1. `session_connect` while open reports "Linked" (Q1). Fix F-1.
2. Capture answer clock 600 s (Q2). Fix F-5.
3. A turn with no way to dial (URL unset or Wi-Fi down after `turn_begin`) waits indefinitely, no failure (Q3). Voice gates on `ready`. The implementer records a TODO for a bound; not built.
4. Rest timer counts from connection open (Q4). This matches current behaviour, so it is not logged as a fix.

Still open: HTTP 401 on upgrade is indistinguishable from "can't connect" at this layer; a distinct text ("Token rejected") is a later enhancement, not specified.

## 14. Which numbers and strings are forced

- Forced by the public protocol or hardware (`RaBbLE-Pocket-Beam-Protocol.md`, S264): 15 s ping, 45 s pong timeout, 5 to 120 s backoff, 2 min rest, 8 s speech backlog, 40 ms / 640-sample frames, 4 s reply buffer, 60 s answer wait, core 0 and priority 5 for the network tasks, 16 kHz PCM16 mono.
- Tuning values (revisable with F's agreement): 8 s dial limit, 10 s network timeout, 5 s send timeout, 4096-byte client buffers, 6144-byte stacks, 32 KiB message cap, 256 KiB note cap, 4095-character reply text, 1023-character transcript, 72-byte event text (check `rabble_beam.h` first: if the header fixes it, follow the header), reading-pace estimate for captions (12 to 16 characters per second), 50 ms polling guarantee, 25 ms / 500 ms responsiveness, 16-request capacity, 1 s QUEUE FULL wait.
- User-visible strings (4.3, 5.4, 7.3, 8) are behaviour values kept as written. Ruling (Mark, 2026-11-05, recorded in `Pocket-Core-Apps-Reorg-Plan.md` section 13): UI strings coinciding with Meta's wording are reworded. `rabble_beam.c`, the `w3-beam`, `w4-voice` and `w1-text` specs and their tests still carry the old strings. The INTEGRATOR must update all of them to the new strings before the implementer runs. The old-to-new list is in `w8-integrator-notes.md`, which exists beside this spec and is excluded from the implementer export. "VOICE TURN IN PROGRESS", "LOST sCoRE" and "sCoRE DIDN'T ANSWER" are kept (protocol-forced or not coincident).

## 15. Fixes relative to the current behaviour (each goes in the implementer's change log)

- F-1: `session_connect` with the socket open re-reports "Linked" (Q1).
- F-2: a failed big-memory allocation falls back to plain `malloc` for the speech and reply buffers, stream/queue storage, and the growing note buffer (the allocator helper already falls back, the others did not); the module also runs without PSRAM.
- F-3: a bad URL reports once, not repeatedly (4.3, V38).
- F-4: a different URL does not offer the old TLS session (4.4).
- F-5: capture answer clock is 600 s (Q2).
- F-6: after a failed `start` the module is inert and every call is safe (V36).
- F-7: speech pushed after `turn_begin` is never sent under an older turn number (V39).
- F-8: HEARD events are not emitted for typed turns (7.1).
- F-9: `turn_begin`, `turn_end` and `turn_cancel` are never refused at capacity and `turn_begin` always advances the turn number (section 2); only typed text can be refused.
- F-10: a `turn.begin` that cannot be sent within 8 s fails the turn "LOST sCoRE" (5.2).
