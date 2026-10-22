# W4 spec: rabble_audio (mono mic and speaker over the shared codec bus, level metering, chirp, bench tests)

> Clean-room spec, wave W4. Author role: S (Sonnet 5.5 sub-agent, S264). Firewall: S264 parent (Opus 5.5): power transitions stated as an outcome (no bus error text) instead of a log-level mechanism; loopback measurement loosened to its observable results; open questions answered as integrator decisions; the speaker gating made concrete from the public `esp_codec_dev` ES8311 driver. File to be replaced: `apache/rabble_audio.c/.h`. New files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Interface names are frozen. Companion specs: `w0-seam.spec.md` (board vtable), `w3-settings.spec.md` (volume, speaker, mic gain), `w4-voice.spec.md` (the only heavy caller; written in parallel, only its public functions are referenced here).

Treatment: clean room. Everything below is a requirement. Where a number is given it is a behaviour value; how you structure code, name helpers and split functions is yours. Section 6.5 (speaker output gating) deliberately differs from the file being replaced: it is the required behaviour.

---

## 1. Purpose

Hide the board's two codecs (ES8311 speaker, ES7210 mic ADC on one duplex I2S bus at 16 kHz, 16-bit, 2 slots) behind mono, blocking, 20 ms-chunked buffers. Provide: captured audio high-passed and mixed to mono; paced mono playback with a speaker-off mode; RMS metering for the voice pipeline and the face; a short UI chirp; two bench tests that log measurements. Persistent data: none. Everything reaches hardware through the board vtable and the managed `esp_codec_dev` handles.

## 2. Public interface (complete and frozen)

Header `rabble_audio.h`, `#pragma once`. Must include `<stdbool.h>`, `<stddef.h>`, `<stdint.h>`, `"esp_err.h"`. `extern "C"` guards allowed.

| Name | Kind | Contract |
|---|---|---|
| `RABBLE_AUDIO_RATE` | macro, `16000` | Sample rate of both directions. |
| `RABBLE_AUDIO_CHUNK` | macro, `320` | Mono frames in 20 ms. Callers size buffers by it. |
| `esp_err_t rabble_audio_init(int volume, int mic_gain_db)` | function | 6.1. Called once by the voice start, before anything else here. |
| `void rabble_audio_power(bool on)` | function | 6.2. Off closes the codecs; on reopens them with the saved volume and mic gain (from settings). Reads and writes need it on. |
| `void rabble_audio_set_volume(int volume)` | function | 0..100. 6.3. |
| `void rabble_audio_set_mic_gain(int db)` | function | 0..`RABBLE_MIC_GAIN_MAX` (36, defined by `rabble_settings.h`). 6.3. |
| `void rabble_audio_selftest(void)` | function | Measures real capture and playback rates and per-mic levels; logs the result. 6.9. |
| `void rabble_audio_loopback_test(int volume)` | function | Plays tones while recording, across mic gains; logs levels. For tuning. 6.10. |
| `esp_err_t rabble_audio_read(int16_t *mono, size_t frames)` | function | Blocking read of `frames` mono samples (mic pair mixed down, high-passed). 6.4. |
| `esp_err_t rabble_audio_write(const int16_t *mono, size_t frames)` | function | Blocking write of `frames` mono samples to the speaker. 6.5. |
| `float rabble_audio_dbfs(const int16_t *mono, size_t frames)` | function | RMS of a buffer in dBFS (-100 for silence). 6.7. |
| `float rabble_audio_level(const int16_t *mono, size_t frames)` | function | RMS mapped to a 0..1 perceptual level. 6.7. |
| `void rabble_audio_chirp(int rising)` | function | Short UI chirp: rising for "go", falling for "done". 6.8. |

No other symbol is exported. The header comments (first block: shared duplex bus, one format, mono buffers, high-passed capture) are free text.

### 2.1 Callers (grep over `firmware/components` and `firmware/main`)

| Caller | Uses |
|---|---|
| `apache/rabble_voice.c` (W4 replaces it) | init (from its start), power (rest on/off), read, write, dbfs, level, chirp (turn end, bench `c`), selftest (once, as its task starts), loopback_test (bench request), `RABBLE_AUDIO_RATE`, `RABBLE_AUDIO_CHUNK` (every buffer is one chunk). |
| `accord/rabble_app.c` | `rabble_audio_set_volume(rabble_settings_volume())` and `rabble_audio_set_mic_gain(rabble_settings_mic_gain())` from the settings listener (see `w0-seam.spec.md`). |
| `apache/rabble_settings_ui.c` | `rabble_audio_set_volume(v)` live while the volume slider moves; `rabble_audio_set_mic_gain(db)` after storing the new gain. |

## 3. What the module calls

| Needs | For |
|---|---|
| `rabble_board->audio_init(&spk, &mic)` | Codec handles (not yet opened), 2-slot duplex I2S. Called by init. |
| `rabble_board->mic_slot` | Mixdown rule (6.4): `-1` average both slots, `0` or `1` use that slot. Read on every read call. |
| `rabble_board->set_mic_gain(mic, db)` (optional, may be NULL) | Board-specific gain mapping. When NULL use `esp_codec_dev_set_in_gain(mic, (float)db)`. The Waveshare board's hook snaps to the ES7210's 3 dB steps (33 becomes 34.5 dB); that is board code, not this module's job, which passes the integer `db` unchanged. |
| `esp_codec_dev` (managed component): open, close, set_out_vol, set_in_gain, read, write | The only hardware path. Open format for both codecs: `sample_rate` 16000, `channel` 2, `bits_per_sample` 16. |
| `rabble_settings_volume()`, `rabble_settings_mic_gain()`, `rabble_settings_speaker_on()` | Saved values on power-on and after bench tests; the speaker setting is read at every write. |
| `esp_timer_get_time()`, `esp_log_level_get/set`, `esp_log`, `heap_caps_malloc` with `RABBLE_BIG_CAPS` (`rabble_mem.h`) | Self-test timing; log quieting (6.2); logs; the loopback capture buffer. |

It must not call the voice, beam, state or UI modules.

## 4. Threading and real time

- Runs in the caller's task; this module owns no task that blocks anything, and nothing here ever runs in or waits on the LVGL task. Reads, writes, chirp, self-test, loopback and power are used from the voice task only (core `RABBLE_AUDIO_CORE`, priority 6, see `rabble_mem.h`). `rabble_audio_set_volume` and `rabble_audio_set_mic_gain` are callable from any task at any time, concurrently with reads and writes (LVGL, serial and settings-listener tasks use them); they never block for long or touch the audio sample buffers.
- `rabble_audio_read` and `rabble_audio_write` may be in flight at the same time (separate directions): they must not share scratch buffers.
- Blocking is by the hardware pace: a read of N frames takes about N/16000 s (the 20 ms read paces the voice idle loop); a write likewise (6.5). Neither may busy-wait. The face must keep 60 fps idle and not regress while listening or speaking: no long non-blocking CPU loops, scratch buffers in internal RAM (about 2.5 KB each way), nothing allocated per call (the one exception is the loopback test buffer, 6.10).
- Any deferred work this module needs (6.5 hold timer) must be cheap and must not run in the LVGL or Wi-Fi tasks.

## 5. State kept

Handles; whether the codecs are open ("audio on"); the high-pass filter memory; the speaker output state (6.5). Nothing else.

## 6. Behaviour

### 6.1 Init

`rabble_audio_init(volume, mic_gain_db)`:

1. Get the handles from the board. Fail with the board's error (or `ESP_FAIL` when it returned `ESP_OK` but either handle is NULL).
2. Open the mic codec with the format in section 3; fail with `ESP_FAIL` if it does not open. (The speaker is not opened here: 6.5.)
3. Apply `mic_gain_db` (6.3) and remember `volume` as the current volume (applied when the speaker output activates, 6.5).
4. Set up the 80 Hz high-pass (6.4) with the filter memory at zero.
5. Log at info level exactly: `audio ready: 16000 Hz, 2 ch, vol <volume>, mic gain <db> dB` (for example `audio ready: 16000 Hz, 2 ch, vol 70, mic gain 30 dB`). Return `ESP_OK`.

After a successful init the module is "on" and idle: mic live, speaker output at rest (6.5). Failure logs are free text.

### 6.2 Power

`rabble_audio_power(on)`:

- No-op before a successful init, and no-op when the state already equals `on`.
- Off: stop the whole audio path (mic ADC, speaker DAC and amplifier, I2S) and mark audio off. The speaker output state returns to rest immediately (no hold). Reads and writes while off return `ESP_FAIL` (do not crash).
- On: reopen the mic with the same format, then apply the current **settings** volume (as the value to use when the output next activates) and mic gain (`rabble_settings_volume()`, `rabble_settings_mic_gain()`), not whatever was last passed to a setter. The speaker output stays at rest until something plays. If the reopen fails, audio stays off (a later `power(true)` retries) and the settings are not applied.
- The shared bus driver can print an error from the `i2s_common` tag when the second direction of the duplex bus is stopped. No such error text may appear on the console during any power transition (on or off, speaker activation or deactivation); other log output is unaffected.
- On power-on the high-pass memory (6.4) starts again from zero.

### 6.3 Setters

- `set_volume(v)`: clamp to 0..100 and remember it. If the speaker output is active apply it to the codec at once; otherwise it takes effect at the next activation. No-op before init.
- `set_mic_gain(db)`: clamp to 0..`RABBLE_MIC_GAIN_MAX`, then apply at once through the board hook when present, else `esp_codec_dev_set_in_gain`, with the integer passed through (no snapping; the board hook may snap). No-op before init. The vectors (`lifecycle.tsv`, scenario `setters`) pin the values.

### 6.4 Read

`rabble_audio_read(mono, frames)` fills `frames` mono samples, blocking, in transfers of at most 320 frames (one codec read of `n * 2 * 2` bytes per piece: 1280 bytes for a full chunk, a smaller one for the remainder). `frames == 0` does nothing and returns `ESP_OK`. A failing codec read stops the call at once and returns `ESP_FAIL`; samples of earlier pieces are already stored, the rest of the buffer is untouched.

Per frame:

1. Mixdown. If `mic_slot` is `-1`: `x = 0.5 * (left + right)` as a float; else `x` is that slot's sample.
2. High-pass, one pole at 80 Hz, single precision: `a = RC / (RC + dt)` with `RC = 1 / (2 pi 80)` and `dt = 1 / 16000` (a is about 0.9695); `y = a * (y_prev + x - x_prev)`; then `x_prev = x`, `y_prev = y`. The filter memory persists across read calls (the output is the same however the frames are split into calls) and starts at zero at init and at every power-on (6.2).
3. Output sample: `y` truncated toward zero, saturated to -32768..32767.

Golden vectors: `read.tsv`. The mono output must match within +-1 LSB.

### 6.5 Write and speaker output gating

`rabble_audio_write(mono, frames)` plays `frames` mono samples (each sample sent to both slots), blocking, in pieces of at most 320 frames. `frames == 0` does nothing and returns `ESP_OK`. A failing codec write stops the call at once and returns `ESP_FAIL`.

**Pacing is part of the contract.** Every piece takes its real time (20 ms per 320 frames, 16 kHz, with the usual queue-depth slack of the hardware): a call returns only when its audio has been accepted at the real-time rate, whether or not anything is audible. The voice module times captions to this.

**Speaker off** (`rabble_settings_speaker_on()` false, read at every write call, so toggling takes effect on the next call): the audio sent is silence (all samples zero) at the same pace. Nothing audible happens and the output stage is not activated.

**Output gating (requirement).** The speaker path, including the ES8311 power amplifier, is powered **only while something is actually being played**:

1. **At rest** (after init, after power-on, and whenever nothing has played for the hold time): the DAC is muted or off and the power amplifier is off, and no I2S data (stale, repeated or zero) reaches the speaker codec. The speaker is completely silent: no hiss, no hum. The mic path is unaffected (it stays live at all times while audio is on, because the push-to-talk pre-roll needs it).

   Public facts to build on (managed `esp_codec_dev`, ES8311 driver): the power amplifier pin is driven only when the speaker codec device is opened (on) and closed (off); `esp_codec_dev_set_out_mute` mutes the DAC but leaves the amplifier on, so mute alone does not meet rule 1. Opening and closing the speaker device enables and disables only the output (TX) direction of the I2S data interface. Checked on the gadget (S264 bench): with the speaker device closed and the mic device open, mic reads keep running at the real 16 kHz rate with live data, and reopening the speaker device works, with no bus error text. So closing the speaker device at rest and opening it on activation meets rule 1.
2. **Activation:** a write call with the speaker setting on and at least one non-zero sample in the data activates the output before its first sample is sent: bring the amplifier and DAC up, apply the current volume (6.3), and send. No audible truncation of the first 20 ms of the sound; a short lead of silence (up to 20 ms) for the amplifier to settle is allowed. The pop on the first sound after idle must not be louder than the one the device makes today.
3. **Playing:** while the output is active, every write (including all-zero data, such as the silence the voice module feeds between reply messages) is sent to the codec as normal, and every write with the speaker setting on restarts the hold, zeros included. So the amplifier stays on through a whole reply, gaps between sentences included.
4. **Deactivation:** the output returns to rest **500 ms after the end of the last write call made while it was active** with the speaker setting on. Deactivation is done in the caller's task, not on a timer or system task (closing the codec does I2C transfers on a bus shared with touch, the PMU and the IMU): the first `rabble_audio_read` or `rabble_audio_write` call that finds the hold expired closes the output before doing its own work. The voice module reads the mic every 20 ms while awake (so the output closes within about 20 ms of the hold running out) and powers audio off when it rests; it never has to ask for the deactivation. At rest, writes of only zeros never activate the output, and speaker-off writes never activate it or extend the hold; both are still paced.
5. **Power off** (6.2) and the end of the module's life deactivate immediately.
6. Chirps (6.8), reply speech, the cues the voice module writes, the self-test's playback phase and the loopback test all use this same path. The self-test's playback is silence, so it measures pacing without activating the output; the loopback test's tones are written regardless of the speaker setting (it is a tuning tool) and activate it.

The stereo stream contents and chunking while active are pinned by `write.tsv` (they say nothing about when the output stage is on).

### 6.6 Volume mapping

The volume setting (0..100) is passed to `esp_codec_dev_set_out_vol` unchanged. The mic gain setting in dB is passed as 6.3.

### 6.7 Metering

- `rabble_audio_dbfs(buf, frames)`: `frames == 0` gives -100. Otherwise the mean of squares, divided by 32768 squared, `+ 1e-10`, `10 * log10`, clamped below at -100. A full-scale constant -32768 gives 0.0; digital silence gives -100.
- `rabble_audio_level(buf, frames)`: `(dbfs + 54) / 42` clamped to 0..1 (so -54 dBFS and below is 0, -12 dBFS and above is 1). `frames == 0` gives 0.

Golden vectors: `metrics.tsv` (tolerance 0.01 dB and 0.001). The face reads this level (through `rabble_state_set_level`) at 20 ms granularity.

### 6.8 Chirp

`rabble_audio_chirp(rising)` plays a 90 ms sound (exactly 1440 frames) through the write path (so it follows the speaker setting, is paced, and gates the output like any sound), blocking until accepted. The waveform, for sample `i` of 1440 with `x = i / 1440`:

- frequency sweeps linearly: `f = f0 + (f1 - f0) * x`, with rising `f0 = 620`, `f1 = 1180` Hz and falling (any `rising == 0`) `f0 = 980`, `f1 = 560` Hz;
- phase accumulates `2 pi f / 16000` per sample, and is incremented **before** the sample is computed (sample 0 uses the phase after one step; its envelope is 0 so it is 0);
- envelope: `min(x / 0.1, 1) * (1 - x)^2`;
- sample: `trunc((sin(ph) + 0.3 * sin(3 ph)) * env * 7000)`.

It is independent of the volume setting except through the codec volume. Write errors are ignored. Golden vectors: `chirp.tsv` (within +-2 LSB; speaker off gives all zeros). It is not re-entrant (voice task only).

### 6.9 Self-test

Runs once per boot (called by the voice task as it starts, before the first turn); takes about 1.5 s; blocks. On a powered, initialised module:

1. Capture: discard 4160 frames (13 whole chunks), then read 8000 frames (25 chunks) raw from the mic codec, per slot, no high-pass, no mixdown, timing the 25 chunks with `esp_timer_get_time`.
2. Playback: write 4160 frames of silence (flush), then 8000 more frames of silence timed likewise, through the codec at the real rate (the gating of 6.5 keeps the speaker silent; the pacing must still be real so the playback rate measurement is meaningful).
3. For each slot over the 8000 measured frames: mean `m`, variance `v = mean of squares - m^2`, peak `max |sample|`; correlation of the two slots `(mean(l*r) - ml*mr) / (sqrt(vl*vr) + 1e-9)`. Level per slot: `10 * log10(v / 32768^2 + 1e-10)` dBFS (so DC does not count).
4. Log exactly two info lines (in this order):
   - `self-test @ <gain> dB: mic L <lvl> dBFS (peak <p>, dc <d>), R <lvl> dBFS (peak <p>, dc <d>), corr <c>` with `<gain>` the settings mic gain as an integer, levels `%.1f`, peak an integer, dc the mean truncated to an integer (toward zero), corr `%.2f`.
   - `self-test: capture <hz> Hz, playback <hz> Hz (expected 16000)` with each rate `8000 * 1e6 / elapsed_us`, printed with no decimals (`%.0f`).

Golden vectors: `expected/selftest_*.log` (levels within 0.1 dB, rates within 1 Hz, `corr` within 0.01).

### 6.10 Loopback test

On a powered module: allocate a capture buffer of 3200 stereo frames in `RABBLE_BIG_CAPS` memory (return silently, logging nothing, if it cannot); apply the given volume; log `loopback: speaker vol <volume>, tone -12 dBFS; values = mic L/R tone level dBFS`. For each mic gain in 0, 6, 12, 18, 24, 30, 33, 36 dB (applied through 6.3):

- measure the noise floor per mic slot with the speaker silent, then for each of 200, 400, 700, 1000, 2000, 3000, 4000, 6000 Hz play a continuous sine at -12 dBFS (amplitude 8191.75, same on both slots) for about 400 ms while recording, and measure from the settled second half of the recording the level of that frequency per slot (the amplitude of the single-frequency component, as `20 * log10(amp / 32768 + 1e-7)` dBFS), plus the peak sample over both slots across the tones of this gain. Floor levels are mean-square (`10 * log10(ms / 32768^2 + 1e-10)`).
- Log one line per gain, exactly: `gain <g%2d>: floor <L%.0f>/<R%.0f> | <f>:<L%.0f>/<R%.0f> <f>:... | peak <p%.1f> dBFS`, where the peak is `20 * log10((peak + 1) / 32768)` and the eight tone entries are separated by single spaces (see the vectors for the exact result).
- At the end restore the settings mic gain and volume (6.3) and free the buffer.

Tones are written straight to the codec (not subject to the speaker-off mute). `expected/loopback_*.log` is advisory: the line formats must match exactly, the values within 1 dB.

## 7. Limits (collected)

| Item | Value |
|---|---|
| Format | 16 kHz, 16-bit, 2 slots on the bus; mono to callers |
| Chunk | 320 frames (20 ms); codec transfers at most 1280 bytes |
| High-pass | one pole at 80 Hz, a about 0.9695, float |
| Level mapping | -54 dBFS = 0, -12 dBFS = 1, clamp |
| dBFS floor | -100 |
| Chirp | 1440 frames (90 ms), amplitude 7000 before volume, rising 620 to 1180 Hz, falling 980 to 560 Hz |
| Speaker hold after last write while active | 500 ms |
| Self-test | 4160 frames flush plus 8000 measured, both directions; once per boot |
| Loopback | 8 gains x 9 passes x 20 chunks; tone -12 dBFS |
| Scratch | about 2.5 KB per direction, internal RAM |

## 8. Error cases

| Case | Behaviour |
|---|---|
| Board `audio_init` fails or returns a NULL handle | init returns the error (or `ESP_FAIL`); nothing is open. |
| Mic open fails at init | `ESP_FAIL`. |
| Read or write while off or before init | `ESP_FAIL`; no crash. |
| Codec read/write error mid-call | stop, `ESP_FAIL`, earlier pieces kept. |
| Power-on reopen fails | audio stays off; next `power(true)` retries. |
| Setters before init | silently ignored. |
| Chirp write error | ignored. |
| Loopback buffer allocation fails | returns without logging. |

## 9. Gadget checklist (integrator)

Serial keys: `d`/`u` push-to-talk from the host (each spends speech quota; keep the count small), `c` chirp (audible via voice, here the chirp path).

### 9.1 Serial-only

1. Boot log shows `audio ready: 16000 Hz, 2 ch, vol <v>, mic gain <g> dB` and, about 1.5 s later, two `self-test` lines in the format of 6.9: capture and playback both within a few Hz of 16000; L and R levels sane (not -100); `corr` printed.
2. `c` produces the chirp; the log shows nothing new from this module. Repeated `c` (3 times, spaced 0.1 s) does not log errors.
3. Sleep and wake (`z`, then `w`) on battery with the voice resting: the console shows no `i2s_common` error text; after wake the mic path works (a `d`/`u` turn records, the pre-roll is audible in the transcript).
4. A `volume=` setting while idle changes nothing audible and nothing is logged; the next sound uses the new volume. A `mic_gain=` setting takes effect on the next recording (`>status` shows it; a `self-test` rerun is not available over serial).
5. Loopback (voice's bench request, if wired to a key): the log shows the header line and eight `gain ..` lines in the 6.10 format; settings volume and gain are back to their stored values afterwards.
6. fps gates: the face stays at 60 fps idle, and while listening and speaking shows no regression against the 60 fps idle baseline (the face reads `rabble_state_level()`).

### 9.2 Needs Mark's hands / ears

1. A full voice turn with the beam live: hold talk, speak, release; the reply is heard; the pre-roll (words spoken a moment before the press) is audible in the transcript.
2. **Idle silence:** ear against the speaker while the device is idle on the face, on the settings page, and after sleep then wake (screen woken by touch, BOOT tap, raise or shake): silent every time, no hiss, hum or crackle, for at least 30 s each. Also silent a second after a sound has ended.
3. **First-sound pop:** the first chirp or reply after idle has no pop louder than the device makes today (A/B with the pre-W4 build if in doubt), and the start of the sound is not clipped.
4. Several sounds in a row (a reply followed by the end chirp, bench `c` pressed repeatedly) play with no extra clicks between them.
5. Speaker off in settings: a turn shows captions at normal pace and nothing is heard; the speaker stays silent.
6. Barge-in during a reply and cancel by tap: sound stops promptly (within the hold the amplifier is still on but silent).
7. Volume slider: the sound level follows while the slider moves (the slider may play a cue; the level changes at once); mic gain slider: recording level changes on the next turn.
8. A turn while sCoRE is unreachable is kept and sent later: the recording is made and the chirp plays at the end as usual.
9. Sleep and wake mid-idle: after wake the mic still records and the speaker plays.

## 10. Test vehicle and golden vectors

The module compiles on a host with fakes: an `esp_codec_dev` double (open/close/set volume/set gain with a trace; read returns frames from a file or a synthetic echo and can be made to fail after N calls; write appends to a buffer and can fail after N calls); a board double (`audio_init`, `mic_slot`, optional `set_mic_gain`); settings doubles; a clock that advances per transfer; a log sink; `heap_caps_malloc` as `malloc`. The vectors in `w4-audio-vectors/` (`README.md` explains each file and the compare rules) are:

| File | Pins |
|---|---|
| `metrics.tsv` + `inputs/*.pcm` (18 rows) | dBFS and level. |
| `read.tsv` + `inputs/*.s16`, `expected/read_*.pcm` (14 rows) | mixdown, high-pass continuity across calls, saturation, partial-buffer behaviour on failure, codec transfer sizes. |
| `write.tsv`, `expected/write_*.s16` (5 rows) | duplication to both slots, speaker-off silence, chunking, failure. |
| `chirp.tsv`, `expected/chirp_*.s16` (4 rows) | the chirp waveform and speaker-off silence. |
| `lifecycle.tsv` (79 rows, 10 scenarios) | init, power, setter call sequences (speaker timing rows are superseded by 6.5, see its README note). |
| `expected/selftest_*.log`, `expected/loopback_*.log` | the logged lines of the two bench tests. |

The gating (6.5) and threading are not host-testable by vectors; test them on the device (section 9) or with a clock-driven double: a write of non-zero data activates the output stage double; any further write while active (zeros included) extends it; 500 ms after the last one it deactivates; at rest an all-zero write or a speaker-off write never activates it.

## 11. Integrator decisions (S264)

1. The speaker output is gated (6.5); this is the fix for an audible idle hiss. The hold is 500 ms; Mark may tune it.
2. The voice module feeds silence between reply messages, which keeps the amplifier on through a reply (6.5 rule 3). The first sound after idle must start within 40 ms of the call (cue, chirp) and lose none of the first 20 ms chunk of a reply (`w4-voice.spec.md` section 14).
3. The high-pass memory restarts at power-on (6.2, 6.4).
4. Setters clamp (6.3).
5. If the mic fails to reopen at power-on, the module stays off and nothing is left half open; the next `power(true)` retries.
6. The loopback test ignores the speaker setting; the self-test's playback is silence. Both are tools.
7. The chirp ignores write errors and is silent with the speaker off.
8. The self-test runs once per boot.
9. The 33 to 34.5 dB snap is the board hook's business.
