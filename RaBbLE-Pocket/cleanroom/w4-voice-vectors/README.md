# W4 voice golden vectors

Behaviour data for `rabble_voice`: a push-to-talk turn state machine run on a host against a scripted fake world, recorded as event-sequence traces. Spec: `../w4-voice.spec.md`, section 13.

## Files

| File | What it pins | Rows (data lines) |
|---|---|---|
| `scenarios.tsv` | one row per scenario: name, build (`psram` or `no-psram`), the parameter line the fake world is run with, a short note | 47 |
| `turns.tsv` | lane A: the calls the voice module makes out of itself, in order (modes, audio and beam calls, logs, delays) | 763 |
| `captions.tsv` | lane B: every caption set, in order, with the mode in force when it was set | 959 |
| `side.tsv` | lane C: level handed to the face, progress reset, one `poke` per queue event consumed | 406 |
| `probes.tsv` | values of `rabble_voice_resting()`, `rabble_voice_notes_waiting()` and `rabble_voice_monitor_db()` at stated virtual times | 38 |
| `minlen.tsv` | push-to-talk hold length against outcome (too short or sent), and frames given to the beam, at two phases of the 20 ms capture cadence | 42 |

All are plain TSV. Lines starting with `#` are comments. Every row of `turns`, `captions`, `side` starts with the scenario name; rows of one scenario appear contiguously and in order.

## Comparing

Run each scenario in `scenarios.tsv` in a fresh process (all module state starts clear) against your fake world (below) and compare, per lane, the sequence of rows **ignoring the `t_ms` column** (it is the virtual time in ms, for reading only). Lanes are compared separately: the order between a lane A row and a lane B row is not pinned, only the order inside each lane. `probes.tsv` rows compare exactly except `monitor_db`, which compares within 0.05. `minlen.tsv` rows are separate runs and compare exactly.

## The fake world (the test seam)

Everything the module touches goes through fakes you provide; the module must not use any other clock, sleep or blocking source. Time is **virtual** and starts at 0.

| Fake | Behaviour |
|---|---|
| clock | `esp_timer_get_time()` returns the virtual time in microseconds. Only the fakes advance it. |
| `vTaskDelay(ms)` | logs `delay(ms)` (lane A) and advances time by `ms`. |
| `rabble_audio_read(buf, 320)` | advances time by 20 ms, fills 320 samples of a deterministic pattern (below), returns `ESP_OK`. With `mic_fail_at` it returns `ESP_FAIL` once, at the first call at or after that time, without advancing time. Calling it while audio is powered off logs `violation:read while off` (no scenario should show one). |
| `rabble_audio_write(buf, n)` | advances time by `n/16` ms and adds `n` to the pending `audio_play` total (below). |
| `rabble_audio_chirp(r)` | logs `audio_chirp(r)`, advances 90 ms. |
| `rabble_audio_selftest()` | logs `audio_selftest`, advances 750 ms. The module calls it once, before anything else. |
| `rabble_audio_loopback_test(v)` | logs `audio_loopback(v)` (v is the settings volume, 70 here), advances 5000 ms. |
| `rabble_audio_power(on)` | logs `audio_power(0\|1)` on every call, tracks on/off. |
| `rabble_audio_dbfs`, `rabble_audio_level` | the public formulas: dBFS of the RMS, floor -100; level = (dBFS + 54) / 42 clamped to 0..1. |
| `rabble_settings_volume()`, `rabble_settings_mic_gain()` | 70 and 24. |
| state | `set_mode` logs `mode=<boot\|idle\|listening\|thinking\|speaking\|error\|off>` only when the mode changes (initial mode: idle); `set_caption` records a caption row when the text differs from the previous one (initial caption: empty text); `set_level` records `level` with 2 decimals when it differs from the previous recorded value; `set_progress` records `progress 0` or `progress nz` (non-zero) when that differs from the previous; `poke` records `poke`; `make_happy` logs `make_happy`; `asleep()` and `on_battery()` return the scripted values. |
| `rabble_state_wait_awake(ms)` | logs `wait_awake(ms)` and advances time to the earliest of: `ms` later, the next scripted wake (asleep becomes false), battery flag change, or chirp or loopback request. |
| wifi | `connected()` returns the scripted value; `apply()` logs `wifi_apply`; `power(level)` logs `wifi_power(full\|doze\|rest)` only when the level differs from the previous call. |
| input queue | holds the scripted `down`, `up`, `down_wake` events whose time has come (an event is in the queue from its scripted time on, in time order, FIFO). Receive and peek are non-blocking; send-to-front puts an item back at the head. |
| beam | see below. |

Audio pattern: reads return `pattern(g, i) * amp / 1000`, with `g` counting successful reads from 0 and `pattern = ((g * 977 + i * 131) % 2001) - 1000`, using integer arithmetic; `amp` is the current `mic` amplitude (default 60: level 0; 8000 gives level about 0.88). Reply speech samples alternate +3000, -3000.

Beam fake: `ready()` is true when the URL is set and Wi-Fi is connected (scripted `url`, `wifi`). `status()` reports NOT_SET when no URL, else OFFLINE when Wi-Fi is down, else REACHABLE (empty detail). `srv` (default 1) says whether sCoRE can be reached when ready. `turn_begin` logs `beam_begin` and starts a turn; `turn_cancel` logs `beam_cancel` and ends it and drops its pending events; `turn_end` logs `beam_end`; `set_resting(b)` logs `beam_resting(b)`. Audio given to the beam (`turn_audio`, `turn_audio_wait`) is accepted whole when the link is up; when not up it is buffered up to 128,000 frames (8 s) and the rest refused (`turn_audio_wait` with a wait and nothing accepted advances time by the wait). Accepted frames feed a running count and an FNV-1a (32 bit, over the little-endian bytes of each int16) hash, both reset by `turn_begin`; the pair is logged as `beam_sent=<frames>:<hash>` just before the next lane A row that is not an audio row. `srv_stall=1` makes the link accept nothing at all.

The scripted sCoRE answers, per turn, in virtual time: if ready but `srv=0`, an ERROR event `Can't connect` `srv_conn_ms` (1500) after `turn_begin` (unless `srv` has become 1). While the link is up: HEARD `srv_part` once `srv_part_ms` after begin (live transcript, only if non-zero); ERROR `srv_err` `srv_err_live_ms` after begin (only if given). After `turn_end` with the link up (at the later of the two): SENT after `srv_sent_ms` (200; omitted with `srv_nosent=1`), HEARD `srv_heard` 100 ms after SENT (omitted with `srv_nosent=1` or empty), then either ERROR `srv_err` after `srv_err_ms` (300) when `srv_err` is set, or REPLY `srv_reply` after `srv_reply_ms` (900), reply speech of `srv_audio_ms` (1200) available from 100 ms after the REPLY, and DONE 10 ms after it is available. With `srv_silent=1` it never answers. `turn_read(buf, 320, wait)` returns up to 320 frames of reply speech once available (else advances `wait` ms and returns 0). `turn_caption(played, ...)` returns false before a reply exists, else the text `PAGE k` with `k = played / 8000` (integer). `turn_event` returns pending events whose time has come, oldest first.

`audio_play=<frames>` (lane A) is the total of reply and silence frames written since the last lane A row that is not an audio row. Log rows kept in lane A are those listed in spec section 11.2 ("kept logs"); other module log lines are ignored by the fake. `recorded <secs>s` rows keep only text before the first colon; `reply: <secs>s of audio` rows keep only text before the first comma.

## Scenario parameters (`scenarios.tsv`)

Space separated `key=value` tokens: `end` run length in ms (the run stops at that virtual time); `asleep`, `battery`, `wifi`, `url`, `srv` initial 0/1 values; `mic` initial amplitude; `mic_fail_at`; `alloc_fail=1` (any allocation of the 480,000-byte note buffer fails); the `srv_*` values above; and any number of `at=<ms>:<action>[:<arg>]` entries: actions `down`, `up`, `down_wake` (queue events), `asleep`, `battery`, `wifi`, `url`, `srv`, `mic` (set value `arg`), `chirp`, `loopback` (call `rabble_voice_request_chirp()` / `_loopback()`), `monitor` (call `rabble_voice_set_monitor(arg)`), `probe` (record a `probes.tsv` row at that time).

The `no-psram` build is the module compiled for a board without PSRAM (`CONFIG_SPIRAM` not defined): no note buffer, no saved notes, ADPCM pre-roll.

## minlen.tsv

Each row is a fresh run: press at 3000 ms plus `phase_ms` (full pre-roll), mic at 8000 amplitude from 100 ms after the press, release `hold_ms` after the press, beam live. `outcome` is `short` when the caption `HOLD LONGER TO TALK` appears, else `sent`. `frames_sent_to_beam` is the final `beam_sent` count of the run (including pre-roll and tail).
