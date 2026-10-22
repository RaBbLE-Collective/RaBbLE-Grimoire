# W4 spec: rabble_voice (push-to-talk turn loop, offline notes, sleep and wake of the audio path)

> Clean-room spec, wave W4. Author role: S (Sonnet 5.5 sub-agent, S264). Firewall: S264 parent (Opus 5.5): accepted the pass and press orders (observable and pinned by the vectors); section 14 settled against the audio spec (500 ms hold, silence inside a reply keeps the amplifier on); section 16 turned into integrator decisions; the task-creation call stated as a placement requirement. Files to be replaced: `apache/rabble_voice.c` and `apache/rabble_voice.h`. The new `rabble_voice.c` goes under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else; so does the new header. Interface names are frozen. Companion specs this one leans on: `w0-seam.spec.md` (board vtable, memory caps, task placement), `w0-state.spec.md` (state module), `w1-adpcm.spec.md` (pre-roll compression on boards without PSRAM), `w2-input.spec.md` (the producer of the push-to-talk events), `w3-beam.spec.md` (beam status), `w4-audio.spec.md` (written in parallel: the codec layer this module drives), and the public `RaBbLE-Pocket-Beam-Protocol.md`. Golden vectors: `w4-voice-vectors/` (section 13).

Treatment: clean room. Everything below is a requirement. Where a number is given it is a behaviour value; how you structure code, name helpers and split functions is yours. The Capture mode planned on top of voice (`RaBbLE-Pocket-Capture-Plan.md`) is **not** part of this spec and must not be built.

---

## 1. Purpose

The voice module is the device's push-to-talk loop. While idle it keeps the microphone running into a short ring ("pre-roll") so a recording can begin a little before the press. On a press it records speech, streams it live to sCoRE over the beam when it can, and on release ends the turn, plays a short cue, shows the transcript and reply text as captions, and plays the reply speech as it arrives. A new press during the reply interrupts it. When sCoRE is out of reach (Wi-Fi down, say) a note is kept in memory and sent as an ordinary turn once sCoRE is back, even while the screen is asleep. The module also decides when the audio path sleeps (codecs off, Wi-Fi resting), serves a mic level meter for the Sound settings page, and plays a chirp or a loopback test on request.

It owns the voice task and the states it drives in the shared state module (mode, level, progress, caption). It does not own the codecs (audio module), the socket or protocol (beam), the button logic (input), or the screen.

## 2. Public interface (complete and frozen)

Header `rabble_voice.h`, `#pragma once`. It must include `<stdbool.h>`, `"esp_err.h"`, `"freertos/FreeRTOS.h"`, `"freertos/queue.h"` (callers get `QueueHandle_t`, `esp_err_t` and `bool` through it). `extern "C"` guards are allowed. The header must not include any other RaBbLE header (the input event type is the caller's business: the queue carries `rabble_input_event_t` items, see 2.3).

| Prototype | Contract |
|---|---|
| `esp_err_t rabble_voice_start(QueueHandle_t queue);` | Remember `queue` (items of `rabble_input_event_t`, copied by value, produced by the input module, W2 spec). Allocate the pre-roll ring (section 6.2) from `RABBLE_BIG_CAPS` memory and initialise the audio module with the settings' current volume and mic gain (`rabble_audio_init(rabble_settings_volume(), rabble_settings_mic_gain())`). If either fails: set mode ERROR, caption `AUDIO INIT FAILED`, return `ESP_FAIL` without creating the task. Otherwise create the voice task (section 3); if that cannot be created return `ESP_ERR_NO_MEM`; else return `ESP_OK`. Called once from `rabble_app_run` after the input module has started. Must not block beyond that initialisation. |
| `void rabble_voice_set_monitor(bool on);` | Turn the mic level meter (6.3) on or off. Any task. Turning it on or off first resets the meter value to -100 dBFS. |
| `float rabble_voice_monitor_db(void);` | The meter value: smoothed mic level in dBFS, -100.0 when nothing has been measured. Any task, cheap, no locking required (a torn float read is acceptable). |
| `void rabble_voice_request_chirp(void);` | Ask for a short rising chirp at the current volume, played when the module is next idle (6.4). Any task. Returns at once; also prods the state module's waiters (`rabble_state_nudge()`) so a resting voice task notices. |
| `void rabble_voice_request_loopback(void);` | Ask for the audio loopback test at the settings' volume (6.4), played when next idle; results go to the log by the audio module. Any task. Returns at once; also nudges. |
| `bool rabble_voice_resting(void);` | True while the audio path is asleep (6.5): codecs powered down. Any task. |
| `bool rabble_voice_notes_waiting(void);` | True while at least one saved note exists whose age is under 30 minutes (8.6). Any task. |

Total: 7 functions, no types, no macros. Without PSRAM (build flag `CONFIG_SPIRAM` undefined) notes are never saved, so `rabble_voice_notes_waiting()` stays false there.

### 2.1 Callers (grep over `firmware/components` and `firmware/main`)

| Caller | Uses |
|---|---|
| `accord/rabble_app.c` | creates the 16-item queue, starts input, then `rabble_voice_start(queue)`. On `ESP_FAIL` the app leaves mode and caption as the module set them (the screen shows the fault) and logs `voice pipeline unavailable`. On success it sets mode IDLE with an empty caption. A board without `audio_init` never calls voice. |
| `accord/rabble_motion.c` | `rabble_voice_request_chirp()` on a shake gesture, only while awake and mode IDLE. |
| `accord/rabble_input.c` | bench key `c` calls `rabble_voice_request_chirp()`; `rabble_voice_resting()` feeds the display-pause decision; `rabble_voice_notes_waiting()` blocks the Wi-Fi nap. |
| `apache/rabble_settings_ui.c` | `rabble_voice_set_monitor(true/false)` while the Sound page is visible; polls `rabble_voice_monitor_db()` for the meter; `rabble_voice_request_chirp()` when the volume slider is released (the user expects to hear the new volume at once). |
| `accord/rabble_setup.c` | console command `test.loopback` calls `rabble_voice_request_loopback()`. |

### 2.2 Consumed event type (from W2, restated for convenience)

`rabble_input_event_t` is `{ rabble_ptt_t type; bool wake; }` with `RABBLE_PTT_DOWN` = 0 and `RABBLE_PTT_UP` = 1. `wake` is true only on a DOWN that woke the screen. The producer guarantees ordering and nothing else; the voice module must tolerate stray UPs, duplicate DOWNs, UPs without DOWN and events arriving at any time.

## 3. Task, cores and real-time requirements

| Item | Requirement |
|---|---|
| Task | one task named `rabble_voice`, priority 6, stack 6144 bytes, pinned to `RABBLE_AUDIO_CORE` (`rabble_mem.h`). Its stack must live in `RABBLE_BIG_CAPS` memory (PSRAM when present), sparing internal RAM for Wi-Fi and BLE; that is allowed because the task never writes flash. |
| Relative to the UI | the UI task shares the voice core and sits one priority lower (`RABBLE_UI_PRIORITY` 5). The voice task is therefore the more urgent of the two on that core and must keep every pass short and bounded: no spin without a blocking read, no per-pass work beyond one 20 ms audio chunk handled. |
| Must never block | the panel, LVGL and the state module's readers. The voice task calls only the state module's setters (cheap, short critical sections) and never takes the display lock, never calls LVGL, never calls any `rabble_ui_*` function. Allowed blocking inside the voice task: the 20 ms audio read, audio writes (which pace playback), the beam's short bounded waits (20 ms or 100 ms), explicit delays listed in this spec, and the rest wait (6.5). |
| Frame-rate gates | the face reads `rabble_state_level()` and the mode. Idle must stay at 60 fps and listening or speaking must not regress it (no worse than 30 fps while busy, per the entity gates). Per-chunk work (level metering, statistics, copying 640 bytes) must therefore stay small; do no floating-point work per sample beyond what the metering needs, never allocate in the audio loops (the ring and the 15 s note buffer are allocated up front or once per press, never per chunk), and never log per chunk. |
| Mic continuity | the module must read a 20 ms chunk at least once per 20 ms while awake (idle or recording) so the mic DMA never overruns. The only voice-owned stalls are the explicit ones: the falling cue after release (about 90 ms, the audio module's chirp), the 2.5 s hold after a reply with no speech (the mic is not read then and that is fine), and the loopback test (about seconds, on request only). |
| Memory | the pre-roll ring 16 chunks (section 6.2). With PSRAM one 480,000-byte note buffer per press (15 s of 16-bit mono at 16 kHz) allocated at press time from PSRAM (`MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT`), shrunk to its length when saved, freed when the note is delivered or dropped; at most 4 saved notes. On allocation failure see 7.2. |

## 4. What the module calls (seam and modules) and what it expects

| Callee | Calls | Expectation |
|---|---|---|
| audio (W4 audio spec, `rabble_audio.h`) | `rabble_audio_init(volume, mic_gain)`, `rabble_audio_selftest()`, `rabble_audio_power(bool)`, `rabble_audio_read(int16_t*, 320)`, `rabble_audio_write(const int16_t*, n)`, `rabble_audio_chirp(int rising)`, `rabble_audio_loopback_test(volume)`, `rabble_audio_dbfs`, `rabble_audio_level`; constants `RABBLE_AUDIO_RATE` (16000), `RABBLE_AUDIO_CHUNK` (320) | Mono 16-bit at 16 kHz. `read` blocks for one chunk (20 ms) and returns `ESP_OK` or an error; `write` blocks until the samples are queued (so it paces playback in real time); `chirp(1)` rising "go", `chirp(0)` falling "done", about 90 ms, blocking; `power(false)` closes the codecs, `power(true)` reopens them with the current settings and reads and writes need them open; `dbfs` of a buffer (-100 for silence); `level` maps a buffer to 0..1 (about -54 to -12 dBFS). The module calls `selftest` exactly once, as the first thing the task does, before any pass. It never touches the codecs or the board's audio fields directly. |
| beam (W3 spec, `rabble_beam.h`) | `rabble_beam_ready()`, `rabble_beam_status(&st)`, `rabble_beam_set_resting(bool)`, `rabble_beam_turn_begin/audio/audio_wait/end/cancel`, `rabble_beam_turn_event(text, cap)`, `rabble_beam_turn_caption(played, out, cap)`, `rabble_beam_turn_read(pcm, frames, wait_ms)` | See 4.1. |
| state (W0 spec) | `set_mode`, `mode(NULL)`, `set_level`, `set_progress`, `set_caption`, `poke`, `asleep`, `on_battery`, `wait_awake(ms)`, `nudge`, `make_happy`; `RABBLE_CAPTION_MAX` | `set_caption` is printf-style; captions are one page (400 bytes including NUL). `wait_awake` returns when awake, nudged or after the timeout. |
| input (W2 spec) | the queue it was given; `rabble_input_event_t`, `RABBLE_PTT_DOWN/UP` | Non-blocking receive, peek and put-back-at-front on the queue. |
| settings | `rabble_settings_volume()`, `rabble_settings_mic_gain()` | Read at start and when passing the volume to the loopback test and the stats log. |
| wifi | `rabble_wifi_connected()`, `rabble_wifi_apply()`, `rabble_wifi_power(RABBLE_WIFI_FULL\|DOZE\|REST)` | `apply` = try to connect now, skip the backoff. |
| adpcm (W1) | `rabble_adpcm_encode_block`, `rabble_adpcm_decode_block`, type `rabble_adpcm_t` | Only when the build is low-memory (`RABBLE_LOW_MEM` 1): the pre-roll ring is stored 4:1 compressed (6.2). |
| mem | `RABBLE_BIG_CAPS`, `RABBLE_LOW_MEM`, `RABBLE_AUDIO_CORE` | |
| ESP-IDF | log, `esp_timer_get_time`, `vTaskDelay`, FreeRTOS queue and task calls, heap caps | |

### 4.1 The beam turn interface, as voice needs it

The beam's session task does the network work; voice drives one turn at a time through these calls (all callable from the voice task, none blocks longer than stated):

| Call | Voice's use |
|---|---|
| `rabble_beam_ready()` | Cheap: a sCoRE URL is set and Wi-Fi is connected. It does **not** mean a socket is up; a turn begun when ready connects on its own. |
| `rabble_beam_turn_begin()` | Start a voice turn: the beam buffers up to 8 s of speech (128,000 frames) until it is connected. Sends `turn.begin` with `mode: "voice"` and the speaker/voice settings; that is the beam's job. |
| `rabble_beam_turn_audio(pcm, n)` | Give speech without waiting; what does not fit the 8 s backlog is dropped (the beam logs it). Used on non-PSRAM builds where no note is kept. |
| `rabble_beam_turn_audio_wait(pcm, n, wait_ms)` | Give speech, waiting up to `wait_ms` for room; returns how many frames were taken (0 to n). Used when a kept note exists, so nothing is lost. |
| `rabble_beam_turn_end()` | All speech given. |
| `rabble_beam_turn_cancel()` | Abandon the turn (tap, barge-in, failure). Safe when no turn is active. |
| `rabble_beam_turn_event(text, cap)` | Next event of the current turn or `RABBLE_BEAM_EV_NONE`. HEARD carries the transcript tail, REPLY a reply text delta, SENT means sCoRE has the whole note, DONE means the reply is complete (speech may still be draining), ERROR carries a short upper-case reason. Events of cancelled turns never appear. |
| `rabble_beam_turn_caption(played, out, cap)` | The page of reply text to show given `played` frames of reply speech already played; false when there is no reply text yet. |
| `rabble_beam_turn_read(pcm, frames, wait_ms)` | Reply speech, up to `frames`, waiting up to `wait_ms` when none is ready; returns frames read (0 if none). |
| `rabble_beam_set_resting(bool)` | Tell the beam the device is resting (it closes the socket after 2 minutes of rest and idle) or awake again (it reconnects). |

The beam enforces its own limits (connection loss gives ERROR `LOST sCoRE`; 60 s after `turn_end` without an answer gives ERROR `sCoRE DIDN'T ANSWER`). The voice module has **no timeout of its own** while waiting for a reply and relies on those errors.

## 5. Constants and limits (all are behaviour values)

| Item | Value |
|---|---|
| Audio format | 16 kHz mono 16-bit; chunk 320 frames (20 ms) |
| Longest recording | 15 s = 240,000 frames, **counting the pre-roll frames** (so at most 14.68 s after a full pre-roll) |
| Release tail | recording continues 1,920 frames (120 ms, 6 chunks) after the release is noticed, but never past the 15 s total |
| Minimum hold | 4,800 frames (300 ms) counted as frames recorded **after** the pre-roll, tail included (so a hold of about 180 ms already passes; see `minlen.tsv`) |
| Pre-roll | 16 chunks (320 ms) |
| Settle after own sound | 10 chunks (200 ms) of capture ignored |
| Saved notes | at most 4, each at most 240,000 frames; after 8 failed sends a note is dropped |
| Retry backoff | 15 s, doubling per failure to a maximum of 120 s |
| Send stall limit | 30 s without the beam taking any of a note |
| Asleep delivery wait | 30 s for sCoRE to confirm a note |
| Waiting flag lifetime | oldest saved note younger than 30 minutes |
| Rest wake timeouts | 60,000 ms backstop; 5,000 ms while the waiting flag is set |
| No-speech hold | 2,500 ms after a reply that produced no speech |
| Hold on waking | a press that woke the screen is checked for 15 chunks (300 ms) |
| Captions during recording | updated every 5 chunks (100 ms) |

## 6. Idle behaviour

### 6.1 The idle pass

The task first runs the audio self-test once, then repeats idle **passes** forever. One awake pass consumes exactly one 20 ms mic read, which paces the loop. In order, a pass:

1. **Saved note due** (PSRAM builds, section 8): if a saved note should be sent now and no press is waiting at the head of the queue (leading UP events are discarded while looking), send it (8.3) and start the next pass. A press always goes first.
2. **Rest or not** (6.5): the audio path rests when the screen is asleep, the device is on battery (state's `on_battery`, which includes the bench override), and neither a chirp nor a loopback request is pending. Enter or leave rest only on a change.
3. **Wi-Fi power**: request `RABBLE_WIFI_REST` when resting, else `RABBLE_WIFI_DOZE` on battery, else `RABBLE_WIFI_FULL`. (A press raises it to FULL, 7.1.) Requesting every pass is fine; the wifi module ignores repeats.
4. **If resting**: wait in the state module's `wait_awake` (6.5) and start the next pass.
5. **Requests**: a pending chirp is played (`rabble_audio_chirp(1)`, rising) and cleared; a pending loopback runs `rabble_audio_loopback_test(rabble_settings_volume())` and is cleared. After either, empty the pre-roll (6.2: the device's own sound must not become pre-roll).
6. **Capture one chunk** into the pre-roll and meter (6.2, 6.3). If the read fails, delay 20 ms and start the next pass.
7. **Queue**: take one event without blocking. Poke the idle clock (`rabble_state_poke()`) for each event consumed. Anything but a DOWN is ignored. A DOWN starts a press (section 7) with its `wake` flag.

### 6.2 Pre-roll

While awake and idle the mic keeps running; each chunk goes into a ring of the 16 most recent chunks (oldest overwritten). On a normal build the chunks are stored as plain samples. On a low-memory build (`RABBLE_LOW_MEM` 1, no PSRAM) each chunk is stored ADPCM-compressed (W1 codec, 160 bytes per chunk, with the encoder state before that chunk saved beside it so a chunk decodes alone); the encoder state runs continuously across chunks while idle and is never reset. Either way, replaying the ring yields the chunks oldest first (lossy on the low-memory build).

The ring is **emptied** (fill 0) and the next 10 chunks read are discarded unrecorded ("settle", 200 ms) after: waking from rest, a chirp, a loopback test, the falling cue after a turn, any reply playback, and any press that did not record. This keeps RaBbLE's own sound out of the next recording. The one exception: a press that woke the screen (7.1) sets the settle to zero because nothing was played.

### 6.3 Mic level meter

While the meter is on (Sound settings page visible), every idle chunk's level in dBFS (`rabble_audio_dbfs`) updates the meter value: if the new level is higher than the value, the value becomes the new level at once (fast attack); otherwise value = 0.9 x value + 0.1 x level (slow release). The meter only runs on idle chunks (including the settle chunks, which are discarded from the ring but still measured), not during a recording or while resting. Turning the meter on or off resets the value to -100. See `probes.tsv` (`monitor_levels`).

### 6.4 Chirp and loopback requests

A request is a flag. It is honoured at the next pass in which the audio path is awake (a resting module wakes for it: a request prevents rest, then the next pass powers the codecs up, plays, and rests again within about 100 ms if the screen is still asleep on battery; see `rest_chirp_request`). A request made during a recording or reply is honoured after the turn finishes and the module is idle again. Repeated requests before service collapse into one. The chirp plays at the current volume and always the rising shape.

### 6.5 Rest (asleep on battery)

On entering rest: power the audio codecs down, tell the beam it is resting, discard queued input events that predate sleeping **except** that the first queued event with `wake` true, and everything queued behind it, stays (a press that woke the device must survive; stale presses before it are dropped; if there is no wake event the queue is emptied), and log `resting: codecs off, Wi-Fi modem sleep`. While resting the module does not read the mic or touch the beam, requests `RABBLE_WIFI_REST`, and blocks in `rabble_state_wait_awake`: for 5,000 ms when the waiting flag (8.6) is set, else 60,000 ms. (The timeout only exists so the CPU can sleep, to look for Wi-Fi to send saved notes, and as a backstop.) A nudge, a wake, or USB power arriving ends the wait early. On leaving rest (screen awake, or plugged in, or a request): power the codecs up, tell the beam it is awake (which reconnects), empty the pre-roll and start settle, and log `awake: codecs on`. The audio must be usable for the very next read in the same pass.

On USB power with the screen asleep, nothing changes: the module stays fully awake (codecs on, pre-roll running).

`rabble_voice_resting()` is true from entering rest until leaving it. A saved note that becomes due while resting is sent without waking the screen (8.4).

## 7. A press

### 7.1 Starting

A press begins on a DOWN taken from the queue in the idle pass (6.1 step 7), or on a press that interrupted a reply or a saved-note send and is already known ("pending", 7.6, 8.3). A pending press is a barge-in (7.3).

If the DOWN has `wake` true (it woke the screen), RaBbLE has been asleep and the user may just have tapped: for 15 chunks, check the queue before each chunk (consuming and poking per event; if any consumed event is an UP the press was a tap: stop, nothing else happens, go back to idle) while capturing into the pre-roll as idle chunks (settle zero), then check once more after the last chunk. Only if the button is still held does the press become a recording. The recording then contains those 300 ms in its pre-roll.

Then raise Wi-Fi power to FULL and apply 7.2. If that refuses, the press is dropped (no recording) and the caption explains.

### 7.2 Can this press record?

1. If Wi-Fi is not connected, call `rabble_wifi_apply()` (retry now, not after the backoff). Then read whether the beam is ready.
2. On PSRAM builds: if the beam status is NOT_SET, refuse with caption `SET UP sCoRE FIRST`. If (the beam is not ready, or notes are waiting) and 4 notes are already saved, refuse with `NOTES STILL WAITING TO SEND`. If the beam is ready and notes are waiting, make the saved ones due immediately (they go right after this turn). Then allocate the 480,000-byte note buffer; if that fails log at error level `no memory to keep a note` and carry on without one.
3. If the beam is not ready and there is no note buffer (non-PSRAM build, or allocation failed), refuse with a reason from the beam status: NOT_SET `SET UP sCoRE FIRST`; OFFLINE `NO WI-FI`; anything else `CAN'T REACH sCoRE`. (Unreachable in practice, kept for completeness.)

"Refuse with caption X" means: progress 0, mode IDLE, caption X, the press is discarded, the module returns to idle. A non-PSRAM build never allocates a buffer, so a press there needs sCoRE.

### 7.3 Recording

1. Set mode LISTENING and progress 0.
2. The recording is **live** (streams to sCoRE as it goes) when there is no note buffer, or the beam is ready and no saved notes are waiting; then begin a beam turn at once. Otherwise it is **kept** only: nothing is sent while recording. Caption `LISTENING...` when live, `RECORDING...` when not.
3. Source of the first frames: for a normal press, the pre-roll ring, oldest first, and they count toward the 15 s total and toward the hold lengths in 7.4 as pre-roll (not as held). For a barge-in (pending press) there is no pre-roll; instead 10 chunks (200 ms) are read and discarded first (the queued tail of the reply is still sounding).
4. Then read chunks until the total frames (pre-roll included) would exceed the limit or the stop point is reached. For each chunk: set the face level to `rabble_audio_level(chunk)` ; add the chunk to the recording (below); if live, drain the beam's events (below); advance the counters; every 5 chunks (each time the total, pre-roll included, is a multiple of 1,600 frames) do the tick (below); set progress to total/240,000; then check the queue for a release.
5. A read failure ends the recording at once as if the limit were reached (the log shows `(max)`).
6. **Adding a chunk**: with a note buffer, append it to the buffer and offer the beam whatever of the buffer it has not yet been given, without waiting (what the beam has no room for stays in the buffer for later). Without a buffer, hand the chunk to the beam without waiting (if live) and nothing else.
7. **Live events**: HEARD with non-empty text sets the caption to that text (the live transcript; no quotes) and remembers a transcript was shown. ERROR logs `beam: <text>`, cancels the beam turn and ends live streaming; with a note buffer the recording carries on, to be sent later; without one the recording is a failure: remember the reason text, show it as the caption, and continue to the end of the recording (the failure is acted on in 7.4).
8. **Tick (every 100 ms)**: (a) if there is a note buffer, the recording is not live, the beam did not fail this note, no saved notes are waiting, and the beam is now ready: log `sCoRE in reach: streaming the note so far`, begin a beam turn, and give it the buffer from its start (waiting as the beam allows, non-blocking), then continue live; (b) if no transcript has been shown and the recording has not failed, set the caption to `LISTENING 1.2s` or `RECORDING 1.2s` (the word follows live or not; the number is the total including pre-roll, in seconds with one decimal). Note: on a normal press the first tick shows a figure that already includes the pre-roll.
9. **Release**: when an UP is among the events consumed (each consumed event pokes the idle clock; every non-UP event consumed is dropped; DOWNs while recording are ignored) the recording stops `tail` later: at the total when noticed plus 1,920 frames, capped at 240,000. The user sees the capture continue for 6 more chunks.
10. After the loop: level 0. Log the end-of-recording line (11.2). The "held" length for 7.4 is total frames minus pre-roll frames (so it includes the tail).

### 7.4 After the recording

Evaluated in this order:

1. If held < 4,800 frames **and the press did not wake the screen**: cancel the beam turn, drop any note buffer, empty the pre-roll, caption `HOLD LONGER TO TALK`, mode IDLE. (A press that woke the screen is exempt: it already proved itself by being held through the 300 ms check.)
2. Else if the recording failed (no buffer and the beam gave an error): empty the pre-roll; caption is the reason text; mode IDLE.
3. Else finish the note (7.5). Then empty the pre-roll. If the reply was **not** interrupted by a new press and the mode is not already IDLE, call `rabble_state_make_happy()` then caption empty, mode IDLE, progress 0. If it was interrupted, the new press starts at once as a pending barge-in with no idle pass in between.

### 7.5 Finishing a note

With a note buffer:

- If live and the beam has already been given the whole buffer: end the beam turn **now**, before playing the cue (the cue takes about 90 ms; the beam gets its `turn.end` first).
- Play the falling cue: `rabble_audio_chirp(0)`. (No cue on press: anything played at the start would land on the first words.)
- If live but not everything was given: mode THINKING, caption `SENDING VOICE NOTE`, and give the rest with 100 ms waits until the beam has it all, then end the beam turn. Abort after 30 s in which the beam took nothing (log `sCoRE stopped taking the note`), or on a beam ERROR (log `beam: <text>`): cancel the beam turn; the note is not delivered.
- If the note went to the beam in full: handle the reply (7.6).
- If the reply handling reports the note **delivered** (a SENT, REPLY or DONE event arrived at any time, even if an ERROR followed) or the reply was interrupted by a new press: the buffer is dropped.
- Otherwise the note is saved (8.1), marked "tried" if a beam turn was ever begun for it (live at some point).

Without a note buffer (non-PSRAM build, or allocation failed): end the beam turn, play the falling cue, handle the reply. Nothing is saved.

### 7.6 The reply

Mode THINKING; caption `SENDING VOICE NOTE` until something better arrives. Then repeat, until done or interrupted:

- **Events** (drain all): HEARD, only if no speech has started and no reply text has arrived: caption `"<transcript>"` (the text in double quotes). SENT: the note counts as delivered; caption `NOTE SENT - RaBbLE IS THINKING` (same condition). REPLY: delivered; replied. If speech has not started, ask the beam for the page for the played frames (initially 0): if it has one show it, else show the REPLY event's text. DONE: delivered; done. ERROR: log `beam: <text>`, level 0, caption the error text, mode IDLE, progress 0, and return (reply over, not interrupted; "delivered" keeps whatever it already was).
- **Press**: consume the queue (poke per event); if any consumed event is a DOWN: log `reply interrupted`, cancel the beam turn, level 0, return interrupted (the DOWN becomes the next pending press; other consumed events are dropped).
- **Audio**: ask the beam for up to 320 frames of reply speech, waiting up to 20 ms, or not waiting at all once speech has started or the reply is done. When frames arrive: on the first, mode SPEAKING and log `reply audio after <secs>s`; set level to the level of what is played; write the frames to the audio module (which paces playback); add to `played`. When none arrive and the reply is done: leave the loop. When none arrive and speech has already started and the reply is not done: set level 0 and write 320 frames of silence to the audio module, so the speaker stays fed between messages and does not replay stale buffered sound.
- **Caption paging**: when speech has started or a REPLY has arrived, ask the beam for the page for `played` frames; if it has one, set the caption to it (so the caption scrolls with the speech).
- After the loop: level 0, log `reply: <secs>s of audio, <secs>s total` (wall time since the reply handling began). If no speech frames were played at all (no TTS, or the speaker setting is off, in which case the beam drops reply speech), delay 2,500 ms so the reply text stays on screen, then return.

The reply loop does not end by itself if sCoRE goes silent; the beam's errors (section 4.1) end it.

## 8. Offline notes (PSRAM builds only)

### 8.1 Saving

A recorded note that was not delivered is saved at the end of the queue (oldest first), with its recorded time, its length, and a try count of 1 if it was tried live, else 0. If 4 notes are already saved (not expected, 7.2 prevents it): drop it, caption `COULDN'T SAVE THE NOTE`. If it has no frames (empty): caption `HOLD LONGER TO TALK`. Otherwise shrink to length, log `saved a 1.4s note to send later (2 waiting)` (length with one decimal, count after saving), mode IDLE, progress 0, and caption `SAVED, WILL TRY AGAIN` if tried else `SAVED, SENDS WHEN ONLINE`. A tried note also starts the retry backoff (8.2). Notes live in RAM only and do not survive a reboot.

### 8.2 Retry timing

One shared timer decides when the oldest saved note is next sent. After a failure the next attempt is 15 s later; each further failure doubles the wait up to 120 s (so gaps 15, 30, 60, 120, 120, ...). When the beam becomes ready after having been not ready, the wait restarts: send at once, backoff back at 15 s. When a note is delivered, the next one is due at once and the backoff resets. When the queue empties, both reset. A note saved without having been tried does not start a backoff. A new press that finds the beam ready with notes waiting makes them due immediately after its own turn.

### 8.3 Sending the oldest note

A saved note is due when the beam is ready and the timer has passed. Log `sending a saved note: 1.4s, from 27s ago, try 2` (length, age in whole seconds, try number = tries so far + 1; with ` (asleep)` after `note` when sent asleep). Force full power (leave rest, Wi-Fi FULL) even if the screen is asleep. Awake: mode THINKING, caption `SENDING SAVED NOTE`. Begin a beam turn and give the whole note from the start with 100 ms waits, watching events as in 7.5; end the beam turn when all of it is taken.

- **A press arrives** while it goes up (checked between the waits; leading UP events are discarded, a DOWN is left in the queue): cancel the beam turn, awake caption empty with mode IDLE, the note stays saved with no try counted and no backoff; the press is then served as an ordinary press.
- **Awake, sent whole**: handle the reply exactly as 7.6 (captions, speech, barge-in). If the reply is interrupted by a press, the press is pending and the note counts delivered.
- **Asleep (quiet)**: no captions, mode and face untouched; wait up to 30 s for SENT, REPLY or DONE (polling events every 50 ms): that means delivered; an ERROR (log `beam: <text>`) or the timeout (log `no word that the note arrived`) means failed. Then cancel the beam turn: the reply stays with sCoRE for the user's next look. Mode and the face never change.
- **Delivered (or interrupted)**: drop the note; the next is due at once, backoff reset; asleep, set the caption `SAVED NOTE SENT`.
- **Failed**: count a try. At the 8th failed try: log `giving up on a saved note after 8 tries`, drop it, caption `COULDN'T SEND A SAVED NOTE`. Otherwise start the backoff and use caption `SAVED NOTE: WILL TRY AGAIN`. Awake, the caption is set together with mode IDLE and progress 0; asleep, the caption only.
- Afterwards (not pending a press): empty the pre-roll; if awake and the mode is not IDLE, `make_happy` and caption empty, mode IDLE.

### 8.4 While the screen is asleep

A due note is sent even in rest (8.3 quiet). In rest the due check runs once per wait timeout, 5,000 ms while the waiting flag is set, so a saved note goes within about 5 s of Wi-Fi returning (see `rest_note_sent_asleep`). After sending, the module rests again at once.

### 8.5 Interplay

A note recorded while a saved note exists is **not** streamed live (the saved ones go first): it is recorded, saved, and sent in order. While a press is being recorded, due notes wait. The input module keeps Wi-Fi awake while `rabble_voice_notes_waiting()` is true.

### 8.6 Waiting flag

`rabble_voice_notes_waiting()` is updated on each idle pass (every 5 s while resting) as: at least one saved note and the oldest one was recorded less than 30 minutes ago. With none saved it is false. (After 30 minutes the flag clears while the note stays and still sends when Wi-Fi next allows; the flag's purpose is to stop the Wi-Fi nap holding the radio forever.)

## 9. Captions (exact strings)

All captions are set through `rabble_state_set_caption`. Upper-case text is exact.

| Situation | Caption |
|---|---|
| idle after a turn | empty |
| recording live / not live | `LISTENING...` / `RECORDING...` |
| live transcript | the HEARD text (no quotes) |
| record tick, no transcript | `LISTENING 0.3s` / `RECORDING 0.3s` (one decimal) |
| waiting on the reply | `SENDING VOICE NOTE`, then `"transcript"` (with quotes), `NOTE SENT - RaBbLE IS THINKING`, then reply pages |
| tap too short | `HOLD LONGER TO TALK` |
| no sCoRE URL | `SET UP sCoRE FIRST` |
| Wi-Fi down, cannot keep a note | `NO WI-FI` |
| unreachable (see 7.2) | `CAN'T REACH sCoRE` |
| four notes saved | `NOTES STILL WAITING TO SEND` |
| note saved | `SAVED, SENDS WHEN ONLINE` / `SAVED, WILL TRY AGAIN` / `COULDN'T SAVE THE NOTE` |
| sending a saved note | `SENDING SAVED NOTE`, then as a reply |
| saved note result | `SAVED NOTE SENT` (asleep) / `SAVED NOTE: WILL TRY AGAIN` / `COULDN'T SEND A SAVED NOTE` |
| beam error | the beam's text, shown as given (for example `LOST sCoRE`, `Can't connect`, `sCoRE DIDN'T ANSWER`) |
| audio init failure | `AUDIO INIT FAILED` (mode ERROR, set by `rabble_voice_start`) |

## 10. Level, volume, gain, direction, speaker setting

- **Level to the face**: during a recording each captured chunk sets `rabble_state_level(audio_level(chunk))` (0..1 from about -54 to -12 dBFS); level is 0 when the recording ends. During reply playback each written speech chunk sets its level; silence written between messages sets 0; 0 at the end, on error and on interruption. Pre-roll chunks do not set levels.
- **Progress**: 0 at the start of a recording and on every return to idle; during a recording total/240,000 (the face may draw a ring); never set during a reply.
- **Volume and mic gain**: the module passes the settings' volume and mic gain to the audio module at start and the volume to the loopback test. Live changes while running are applied by the app's settings listener directly on the audio module; this module does nothing for them. Volume is 0 to 100 percent, mic gain 0 to 36 dB (`RABBLE_MIC_GAIN_MAX`); the mapping to codec registers belongs to the audio spec.
- **Speaker off** (settings): the voice module does not read the setting. The beam tells sCoRE not to send speech and drops any that arrives, so a reply produces text only: no SPEAKING mode, no audio written, and after DONE the 2,500 ms hold (7.6). The falling cue is still requested; the audio module silences it.
- **Mic direction**: this module does not use `rabble_board->mic_deg`; the entity code reads it for the face. Which of the two mic slots (or both averaged) feeds recording is the audio module's concern (`rabble_board->mic_slot`).
- **Barge-in discards audio**: samples read during the 200 ms drain at the start of a barge-in are never recorded.

## 11. Log lines

### 11.1 Free

Log tag, levels and other text are free. The statistics at the end of a recording beyond what 11.2 requires are free but recommended: last 0.5 s of per-chunk levels (`end levels:`), then `recorded 1.38s: rms -20.1 dBFS, peak -9.0 dBFS, floor -50.2 dBFS, 0 clipped, gain 24 dB`.

### 11.2 Required ("kept logs", the vectors and checklist grep these)

| Text | When |
|---|---|
| `resting: codecs off, Wi-Fi modem sleep` | entering rest |
| `awake: codecs on` | leaving rest |
| `recorded 1.38s` or `recorded 1.38s (max)` at the start of the line (two decimals; `(max)` when the stop was not a release), the rest of the line free | end of every recording |
| `reply audio after 1.02s` | first reply speech |
| `reply: 1.20s of audio` at the start of the line, the rest free | end of reply |
| `reply interrupted` | barge-in |
| `beam: <text>` (warning) | a beam ERROR event |
| `sCoRE in reach: streaming the note so far` | 7.3 tick (a) |
| `saved a 1.4s note to send later (1 waiting)` | 8.1 |
| `sending a saved note: 1.4s, from 27s ago, try 2` and the ` (asleep)` variant | 8.3 |
| `sCoRE stopped taking the note` | 30 s stall |
| `no word that the note arrived` | asleep delivery timeout |
| `giving up on a saved note after 8 tries` | 8.3 |
| `no memory to keep a note` (error level) | 7.2 |

## 12. Error and edge cases

- Mic read failure while idle: delay 20 ms, try again (no busy loop). While recording: ends the recording (7.3 step 5).
- Stray UP while idle: ignored (pokes once). Duplicate DOWN while recording or while a reply plays: a DOWN during a reply is a barge-in; during a recording it is ignored.
- Press while a saved note is being sent: the press first (8.3). Press while resting: the input module wakes the screen first and posts DOWN with `wake` true; see 6.5 for what survives.
- Wi-Fi drops mid-recording: a live recording gets a beam ERROR (the beam reports `LOST sCoRE` or a connect failure), the kept note is saved and retried (7.3 step 7).
- sCoRE unreachable while Wi-Fi is up: the beam is "ready", the recording is live, the beam reports `Can't connect` after about 1.5 s; with a kept note the recording continues and the note is saved `SAVED, WILL TRY AGAIN`; without one the recording fails with the beam's text.
- A hold shorter than 300 ms after the pre-roll is a tap (7.4) except for a press that woke the screen.
- A recording that hits 15 s stops there as if released.
- The other functions are never called before `rabble_voice_start` (callers do not), except possibly the meter and request calls from the UI, which only set flags and must be safe at any time.
- Never leave a beam turn begun without a matching end or cancel: every path out of a press either ends the turn (live and complete), cancels it (tap, error, barge-in, give-up), or never began one.
- No allocation inside the per-chunk loops; the note buffer is freed on every path (delivered, dropped, saved by shrinking, tap).

## 13. Test vehicle and golden vectors

The decision logic is a state machine driven by queue events, time and the beam. The vectors in `w4-voice-vectors/` (47 scenarios, README there) record what the module does against a scripted fake world on a virtual clock. The implementer builds a **host test vehicle**: compile the voice code on the host against fakes of the audio module, the beam, the state module, Wi-Fi, settings, the queue and the clock exactly as the vectors' README defines them, make the task body runnable on the test's own thread (the loop never returns by itself; the test ends it by aborting from a fake when virtual time reaches the scenario end, for example with a long jump), run each scenario in a fresh process (module state starts clear), and compare the lanes. How the test enters the loop is yours (the module's own test hook is fine). The module must reach the outside world only through the seams in section 4 and the clock, with no other time source or blocking call, so that the virtual clock fully determines behaviour. Two builds are tested: with PSRAM (scenarios marked `psram`) and without (`no-psram`, `CONFIG_SPIRAM` undefined, which switches off saved notes and turns on the compressed pre-roll).

`minlen.tsv` and `probes.tsv` are checked the same way. All files must match: lane rows exactly (ignoring the `t_ms` column), probe values exactly except the meter within 0.05.

## 14. Dependence on audio output timing

Voice depends on audio only through the public calls in section 4. The audio spec keeps the speaker amplifier **on only while something plays**, with a 500 ms hold after its last write, and silent otherwise; any write while it is on (the silence fed between reply messages included) keeps it on. Voice must not assume the speaker is open between sounds; it needs only this from the audio module, stated as latency:

| Voice need | Requirement on audio |
|---|---|
| Falling cue right after release | `rabble_audio_chirp(0)` begins making sound within 40 ms of the call (it is meant to land just after the tail, and the beam is already told the turn ended). |
| Rising chirp on request (volume slider release, shake, `c`) | audible start within 40 ms of the call from the idle pass. |
| First reply speech | the first `rabble_audio_write` of a reply must not lose its first 20 ms chunk. |
| Silence written between reply messages | keeps the amplifier on (audio 6.5 rule 3), so it does not close and reopen in the middle of a reply. |
| Mic after waking from rest | `rabble_audio_power(true)` returns with the mic capturing; the next `read` in the same pass returns real audio. Mic behaviour is unchanged by the amplifier gating. |
| Settle after own sound | the module discards 200 ms of capture after its own sounds (cues, chirps, replies). If closing the amplifier produces a click picked up by the mic after that window, the settle would have to be extended; see open question 8. |

## 15. Device behaviour checklist (integrator)

Serial keys `d`/`u` stand in for push-to-talk from the host (each spends sCoRE speech quota; keep the count small) and `c` plays a chirp. "Hands" checks need Mark. A reachable sCoRE and Wi-Fi are assumed unless said otherwise.

### 15.1 Serial plus beam

1. Boot log: `audio ready`, then the self-test lines, no `AUDIO INIT FAILED`; the face goes IDLE with an empty caption.
2. Full voice turn with the beam live (`d`, speak for a second or two, `u`): captions `LISTENING...`, transcript, then `SENDING VOICE NOTE`, `NOTE SENT - RaBbLE IS THINKING`, the quoted transcript, the reply paging with the speech; mode LISTENING, THINKING, SPEAKING, IDLE with a happy hop. The log shows `recorded ...s` (about 0.3 s longer than the hold: pre-roll and tail), `reply audio after`, `reply:`. **Pre-roll check:** begin speaking just before `d` (within about 250 ms) and confirm the first word is in the transcript sCoRE returns; repeat once after a chirp (`c`) within 0.3 s of `d` and confirm only post-settle audio is used.
3. Tap: `d` then `u` within 100 ms: `HOLD LONGER TO TALK`, nothing sent (check the beam shows a cancelled turn).
4. Barge-in: during the reply, `d`: log `reply interrupted`, speech stops, new recording starts; finish with `u`.
5. Cancel by tap while THINKING: `d` during THINKING then `u` quickly gives `HOLD LONGER TO TALK` and the reply is abandoned.
6. Speaker off (Settings > Sound): a turn gives text only, no speaker sound, mode never SPEAKING, the text stays for 2.5 s after the reply.
7. A turn while sCoRE is unreachable: turn Wi-Fi off (or set a bad URL port); `d`, speak, `u`: captions `RECORDING...`, log `saved a ...s note to send later (1 waiting)`, caption `SAVED, SENDS WHEN ONLINE`. Restore reachability: the note is sent without any press, with the full reply played. With sCoRE unreachable but Wi-Fi up the first try shows `Can't connect`-style behaviour and the caption `SAVED, WILL TRY AGAIN`, retried after 15 s.
8. Five presses with sCoRE unreachable: the fifth shows `NOTES STILL WAITING TO SEND`.
9. No URL set (`>beam.url=`): a press shows `SET UP sCoRE FIRST`.
10. `c` chirps (rising); `>test.loopback` runs the loopback test and logs the audio module's table; neither disturbs the next turn's pre-roll (no cue sound in the transcript).
11. Volume change (slider release) plays the chirp at the new volume; mic gain change takes effect on the next turn without a restart.
12. Sleep and wake mid-idle: `z` then `>nap` style sleeping on battery: log `resting: codecs off, Wi-Fi modem sleep`; `w` gives `awake: codecs on`, and a following `d`/`u` turn works with no lost first word beyond the tail of the wake.
13. Sound page open: the meter follows the mic with fast attack and slow release; leaving the page stops it.

### 15.2 Needs Mark's hands

1. BOOT tap awake: `HOLD LONGER TO TALK`. Hold: records, release plays the falling cue.
2. BOOT press while asleep on battery: wakes, a tap only wakes (no recording, no cue); holding through the wake records the note and the first words are in it; the log shows `awake: codecs on`.
3. A note recorded off Wi-Fi with the screen on is sent on its own when Wi-Fi returns; with the screen asleep on battery it is sent within about 5 s of Wi-Fi returning without waking the screen, the caption (seen after waking) `SAVED NOTE SENT`.
4. Speech held past 15 s stops at 15 s and sends.
5. Frame-rate gates (face): 60 fps idle, and listening and speaking do not drop below the entity gate; compare idle vs listening vs speaking on the on-screen fps if available.
6. Audio quality: reply speech with no hiss or clipped first syllable; no audible click between the cue and the reply (relevant to section 14).
7. Barge-in by physical press cuts the reply within about 100 ms.

## 16. Integrator decisions (S264)

All kept as specified unless stated. Items 2 and 7 are Mark's later calls (Capture mode will change 7).

1. **Recording limit counts the pre-roll.** The 15 s ceiling includes the pre-roll (14.7 s of live speech). Kept; the vectors pin it (`turn_max_length`). The beam protocol says 15 s per note.
2. **Minimum hold is measured after the pre-roll and includes the tail.** A hold of about 180 ms already passes; the nominal "0.3 s" is therefore not the user's hold. Kept as is (`minlen.tsv`). Whether to measure the physical hold is Mark's call.
3. **A read failure while recording looks like the 15 s limit** (`(max)` in the log) and the partial recording is then sent. Possibly unintended; kept.
4. **A delivered note followed by an ERROR is dropped.** Once SENT, REPLY or DONE has arrived the note is considered delivered even if sCoRE then errors (for example a language-model failure); the user sees the error but the note is not retried. Intended (sCoRE has the audio), recorded here because it looks like a bug (`reply_error_after_sent`).
5. **No timeout of its own while waiting for a reply.** The beam's 60 s timeout and connection-loss errors end it. A beam that never errors leaves the face THINKING; the user can barge in.
6. **`CAN'T REACH sCoRE` is effectively unreachable.** The caption exists for a race between the readiness check and the status read.
7. **Notes are lost on reboot** (RAM only), and a note not yet sent when power is off is gone. Capture mode will change this; not in scope.
8. **Settle after own sound.** 200 ms of capture is discarded after a cue or reply. With the amplifier gating of section 14, an amplifier-off click could land inside or after this window; the integrator should listen for it in the transcript test (checklist 15.1 item 10) and, if it shows, extend the settle (a behaviour change to record).
9. **Silence feeding between reply messages** exists to avoid replaying stale buffered audio; with the gated amplifier it also keeps the amplifier on across the gap (settled with the audio spec).
10. **Timing of the falling cue.** It is played after the tail (120 ms after release) and takes about 90 ms; `turn.end` is sent before it. If the amplifier's start-up adds latency, the cue lands later than today; harmless but audible as lag after release.
11. **Caption tick starts from the pre-roll length.** The first `LISTENING 0.3s` tick shows time including the pre-roll. Cosmetic; kept.
12. **Both-wake rule:** a press that woke the screen skips the minimum-hold test, so a tiny recording (just the 300 ms qualifying window) can be sent; deliberate.
13. **Sound cues on press:** none, by design (anything played at the start would land on the first words).
14. **Notes waiting flag after 30 minutes** clears while the note remains; the radio may then nap and the note waits until the next wake. Kept.
15. **Low-memory build lossy pre-roll.** On a non-PSRAM board the pre-roll audio is ADPCM-degraded; the live part is not.
