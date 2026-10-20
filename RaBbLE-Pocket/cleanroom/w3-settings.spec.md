# W3 spec: rabble_settings (persistent user settings)

> Clean-room spec, wave W3. Author role: S (Sonnet 5.5 sub-agent, S259). Firewall: S259 parent (Opus 5.5), approved after rewriting the init order and the token append as requirements, removing a suggested log line close to the original's and a locking design note. File to be replaced: `apache/rabble_settings.c/.h`. New files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Interface names are frozen. Companion specs: `w0-seam.spec.md`, `w1-console-setup.spec.md` (the `key=value` setup commands that call this module). Golden vectors: `w3-settings-vectors/` (section 12).

Treatment: clean room. Everything below is a requirement. Where a number is given it is a behaviour value; how you structure code, name helpers and split functions is yours.

---

## 1. Purpose

A small store of the user's device settings. It loads them from non-volatile storage at boot, serves them to every other module through getters, saves each change the moment it is made, and tells one registered listener what changed so the hardware side can react. It also brings up the device's non-volatile key/value storage (flash NVS) for the whole firmware.

It owns exactly eleven stored values (section 4). Saved Wi-Fi networks are not here: they live in another module's namespace and must never be touched by this one (but see 6.3).

## 2. Public interface (complete and frozen)

Header `rabble_settings.h`, `#pragma once`. It must include `<stdbool.h>`, `<stddef.h>`, `<stdint.h>`, `"esp_err.h"` (callers get `esp_err_t`, `bool`, `size_t` through it). `extern "C"` guards allowed. No other symbol is exported: 1 enum, 1 callback type, 6 macros, 29 functions.

### 2.1 Macros (values exact; other headers and modules depend on them)

| Macro | Value | Meaning and users |
|---|---|---|
| `RABBLE_SSID_MAX` | `32` | Longest Wi-Fi network name in characters. Used by the Wi-Fi module and setup module for buffer sizes (`RABBLE_SSID_MAX + 1`). Not used by this module's own logic. |
| `RABBLE_PASS_MAX` | `64` | Longest Wi-Fi password in characters. Same users. |
| `RABBLE_BEAM_URL_MAX` | `127` | Longest stored beam URL in characters. |
| `RABBLE_BEAM_TOKEN_MAX` | `255` | Longest stored beam token in characters. |
| `RABBLE_VOICE_MAX` | `15` | Longest stored voice name in characters. |
| `RABBLE_MIC_GAIN_MAX` | `36` | Microphone gain ceiling in dB (the codec amplifier works in 3 dB steps; stepping is applied by the audio module and the UI, not here). Used as the upper bound by the setup module's `mic_gain` range and the settings UI slider (`RABBLE_MIC_GAIN_MAX / 3`). |

Each is a plain integer literal (no cast, no suffix) so it can size arrays and appear in preprocessor-free constant expressions.

### 2.2 Types

```
typedef enum {
    RABBLE_SETTING_VOLUME,      /* value 0 */
    RABBLE_SETTING_SPEAKER,     /* 1 */
    RABBLE_SETTING_VOICE,       /* 2: which voice sCoRE speaks in */
    RABBLE_SETTING_MIC_GAIN,    /* 3 */
    RABBLE_SETTING_BRIGHTNESS,  /* 4 */
    RABBLE_SETTING_SLEEP,       /* 5 */
    RABBLE_SETTING_POWER_OFF,   /* 6 */
    RABBLE_SETTING_RAISE,       /* 7: raise to wake */
    RABBLE_SETTING_WIFI,        /* 8: on/off */
    RABBLE_SETTING_BEAM,        /* 9: sCoRE URL or token */
} rabble_setting_t;
typedef void (*rabble_setting_cb_t)(rabble_setting_t what);
```

The enum order is frozen (values 0 to 9 as listed; callers may switch on the names only, but keep the numbers). The type names `rabble_setting_t` and `rabble_setting_cb_t` are frozen.

### 2.3 Functions

Buffer-parameter prototypes use the array spelling shown (`char out[N + 1]`); callers pass buffers of exactly that size.

| Prototype | Contract |
|---|---|
| `esp_err_t rabble_settings_init(void)` | Bring up flash NVS, open the settings namespace, load all values (section 6). Returns `ESP_OK` or the failing code. Called once, first thing in the app (before the board's `init`, before the Wi-Fi module starts). |
| `void rabble_settings_set_listener(rabble_setting_cb_t cb)` | Register the one change listener (replaces any previous; NULL removes). Called once after init. |
| `int rabble_settings_volume(void)` | Speaker volume, 0 to 100. |
| `bool rabble_settings_speaker_on(void)` | False: replies are shown, not played. |
| `void rabble_settings_voice(char out[RABBLE_VOICE_MAX + 1])` | Copies the voice name (empty string: sCoRE's default). |
| `int rabble_settings_mic_gain(void)` | dB, 0 to `RABBLE_MIC_GAIN_MAX`. |
| `int rabble_settings_brightness(void)` | 10 to 100. |
| `int rabble_settings_sleep_s(void)` | Screen auto-sleep seconds; 0 = never. |
| `int rabble_settings_power_off_s(void)` | Seconds asleep on battery before the PMU cuts power; 0 = never. |
| `bool rabble_settings_wifi_on(void)` | Wi-Fi switched on. |
| `bool rabble_settings_raise_wake(void)` | Lifting the device wakes the screen. |
| `void rabble_settings_beam_url(char out[RABBLE_BEAM_URL_MAX + 1])` | Copies the beam URL. |
| `void rabble_settings_beam_token(char out[RABBLE_BEAM_TOKEN_MAX + 1])` | Copies the beam token. |
| `size_t rabble_settings_beam_token_len(void)` | Current token length in characters (0 = none). |
| `void rabble_settings_set_volume(int pct)` | 7.1 |
| `void rabble_settings_set_speaker_on(bool on)` | 7.1 |
| `void rabble_settings_set_voice(const char *voice)` | 7.2 |
| `void rabble_settings_set_mic_gain(int db)` | 7.1 |
| `void rabble_settings_set_brightness(int pct)` | 7.1 |
| `void rabble_settings_set_sleep_s(int secs)` | 7.1 |
| `void rabble_settings_set_power_off_s(int secs)` | 7.1 |
| `void rabble_settings_set_wifi_on(bool on)` | 7.1 |
| `void rabble_settings_set_raise_wake(bool on)` | 7.1 |
| `void rabble_settings_set_beam_url(const char *url)` | 7.3 |
| `esp_err_t rabble_settings_set_beam_token(const char *token, bool append)` | 7.4 |

Getter output buffers always receive a terminated string, truncated to the macro length if somehow longer. Getters never fail and never block for long.

### 2.4 Callers (grep over `firmware/components` and `firmware/main`)

| Caller | Uses |
|---|---|
| `accord/rabble_app.c` | `rabble_settings_init()` under a fatal-on-error check, before board init; `rabble_settings_set_listener(...)` after board init. Its listener runs on the caller's task and reacts to: VOLUME (push volume to the audio module), MIC_GAIN (push gain), WIFI (ask the Wi-Fi manager to apply now), BEAM (tell the beam client its config changed); all other names ignored. |
| `accord/rabble_setup.c` (serial task) | all integer/boolean setters (`volume`, `speaker`, `mic_gain`, `brightness`, `sleep`, `power_off`, `raise_wake`, `wifi.on`; ranges are checked there first), `set_wifi_on(true)` before a join, `set_beam_url`, `set_beam_token(value, append)` (maps `ESP_OK` to reply `ok`, anything else to `error: token too long`), `set_voice`; getters for the status JSON (`wifi_on`, `beam_url`, `beam_token_len() > 0`, `voice`, `volume`, `speaker_on`, `mic_gain`, `brightness`, `sleep_s`, `power_off_s`). |
| `apache/rabble_settings_ui.c` (LVGL task) | every setter: wifi switch, speaker switch, volume/mic/brightness sliders, voice cycling, sleep and power-off choices, raise switch, `set_beam_url`, `set_beam_token(text, false)` (only when text is non-empty); getters to fill widgets. |
| `accord/rabble_input.c` | `power_off_s()`, `sleep_s()` on every sleep check (so changes apply live). |
| `accord/rabble_motion.c` | `raise_wake()` while asleep. |
| `accord/rabble_ui.c` | `brightness()` when fading the panel. |
| `apache/rabble_audio.c`, `rabble_voice.c` | `volume()`, `mic_gain()`, `speaker_on()`. |
| `apache/rabble_wifi.c` | `wifi_on()`. |
| `apache/rabble_beam.c`, `accord/rabble_beam_score.c` | `beam_url()`, `beam_token()`, `speaker_on()`, `voice()`. |

Callers rely on getters being callable from any task at any time after init, including from inside the listener.

## 3. Defaults (used when nothing is stored for a value)

| Value | Default |
|---|---|
| volume | `CONFIG_RABBLE_DEFAULT_VOLUME` (Kconfig int 0..100, default 70; shipped build: 70) |
| speaker on | true |
| voice | empty string |
| mic gain | 30 dB |
| brightness | 100 |
| sleep (seconds) | 120 |
| power off (seconds) | `CONFIG_RABBLE_POWER_OFF_S` (Kconfig int 0..3600, default 45; shipped: 45) |
| Wi-Fi on | true |
| raise to wake | true |
| beam URL | `CONFIG_RABBLE_BEAM_DEFAULT_URL` (Kconfig string, Kconfig default empty; shipped build, from `sdkconfig.defaults`: `wss://rabble-score-x7qq.onrender.com/api/v1/beam`) |
| beam token | empty string |

The Kconfig symbols are interface (the build sets them) and live in `components/rabble_gadget/Kconfig`; do not change their names, ranges or help text. A default URL longer than 127 characters is truncated to 127.

## 4. Stored data (devices in the field already hold these; they must keep loading)

Namespace: `rabble`, in the default NVS partition, opened read-write. All keys are in that namespace and each has exactly this type.

| Key | NVS type | Encoding | Value domain written by the setters |
|---|---|---|---|
| `volume` | u8 | the percentage | 0..100 |
| `speaker` | u8 | 0 or 1 | 0, 1 |
| `voice` | string | the voice name, may be empty | 0..15 characters |
| `mic_gain` | u8 | dB | 0..36 |
| `bright` | u8 | percentage | 10..100 |
| `sleep_s` | u16 | seconds | 0..3600 |
| `off_s` | u16 | seconds | 0..3600 |
| `wifi_on` | u8 | 0 or 1 | 0, 1 |
| `raise` | u8 | 0 or 1 | 0, 1 |
| `beam_url` | string | the URL | 1..127 characters (never written empty by the setter) |
| `beam_token` | string | the token | 0..255 characters |

Note the key names `bright`, `sleep_s`, `off_s`, `wifi_on`, `raise` differ from the setting names. No key is ever erased; no other key is written in this namespace. Strings are stored as plain NUL-terminated NVS strings (the stored length includes the terminator), not as blobs.

## 5. Thread safety

1. Setters and getters may be called from any task at any time after init: the serial task, the UI task, the input task, the motion task, the beam task, the Wi-Fi task. The module is thread-safe from any task.
2. Getters for numbers and booleans return a whole value (never a torn one). The string getters and string setters (voice, URL, token) are mutually serialized: a getter never sees a half-written string, two setters never interleave their changes, and a token append (7.4) is atomic: concurrent appends never lose a chunk, never interleave, and never let the token pass its limit.
3. The listener is called after the change is stored and saved, on the **calling task** (the task that invoked the setter), synchronously, before the setter returns. It is not called while any internal serialization is held, so the listener may call any getter and any setter (a setter inside the listener re-enters normally).
4. Two tasks changing different values at once must not lose either change. Two tasks changing the same value: either order is acceptable; this is not pinned by vectors.
5. A blocking wait inside a setter is allowed for the NVS write (flash writes take milliseconds); a setter may therefore not be called from an interrupt context.

## 6. Initialisation

### 6.1 Order

Requirements on `rabble_settings_init`:

- It brings up the default flash NVS partition for the whole firmware. When ESP-IDF reports that the partition has no free pages, or that a newer layout version was found, the partition is unusable as is: log the warning `NVS layout changed, erasing`, erase the whole partition and bring it up again. If that erase fails, the device cannot continue (abort/restart is acceptable). Any other bring-up failure makes init return that code.
- It then needs the `rabble` namespace open read-write; if that fails, init returns the code.
- On any failure return, every value stays at its default (section 3) and nothing has been written. The app treats a non-OK result as fatal.
- On success every value has been loaded (6.2), one summary line has been logged, and init returns `ESP_OK`. Setters and string getters must be safe to use from the moment init returns.

Init is called once. Calling it twice is not supported. The listener starts out unset and survives nothing across boots.

### 6.2 Loading rules

Each value is read independently; a read that fails for any reason leaves that value at its default. Reasons that count as failure: key absent, key stored with another type, string too long for the value's capacity (see below). Nothing is written during init, so first boot (an empty store) writes nothing and every value is at its default.

| Value | Load rule |
|---|---|
| volume | u8 read, then clamped to 0..100. |
| speaker | u8 read; any nonzero value means true. |
| voice | string read; accepted only if the stored string (without terminator) is at most 15 characters. A longer stored string is ignored: the voice stays empty (default). A stored empty string is accepted (voice empty). |
| mic gain | u8 read, then clamped to 0..36. |
| brightness | u8 read, then clamped to 10..100. |
| sleep, power off | u16 read, **not clamped**: a stored 3601 or 65535 is kept and returned as is by the getter. |
| Wi-Fi on, raise | u8 read; any nonzero value means true. |
| beam URL | string read; accepted only if at most 127 characters. A stored empty string is accepted and **replaces the default**: the URL is then empty and the build default is not substituted. A stored string longer than 127 is ignored (default stays). |
| beam token | string read; accepted only if at most 255 characters; a longer one is ignored (token empty). |

A value stored with the wrong type is treated as absent; the module does not repair, delete or overwrite it at init.

Log line at init (info level), one line: volume, speaker off marker, mic gain, brightness, sleep, off, Wi-Fi, beam URL (or `not set`) and whether a token is set. The token itself and its length are never logged. The wording and order are free.

## 7. Setters

Every setter does the same three things in this order, with no exception: (a) update the in-memory value (so the getter returns it at once), (b) save it to the store and commit, (c) call the listener with that setting's name. Rules shared by all setters:

1. **Always save, always notify.** A setter does not compare with the previous value. Setting the value it already has still writes, commits and notifies (one write and one commit, one listener call each time). Vectors pin this (`sequences.tsv`, `same_value_twice`).
2. **Persist failure is silent.** If the store write or commit fails for any reason, the setter ignores it: no return code (the setters are void), no log requirement, the in-memory value is already updated and the listener is still called. After a reboot the old stored value returns. Vectors pin this.
3. The stored value is the value after clamping or truncation, not the caller's raw input.
4. One listener call per setter call, with exactly one name from the table below. No other setter's name is raised.
5. Calling any setter before `rabble_settings_init` has returned, or after it failed, is a caller bug; it must not crash the firmware (it may skip saving), but is otherwise unspecified.

### 7.1 Numeric and boolean setters

| Setter | Stored value | Key written | Listener name |
|---|---|---|---|
| `set_volume(pct)` | `pct` clamped into 0..100 | `volume` (u8) | `RABBLE_SETTING_VOLUME` |
| `set_speaker_on(on)` | 1 if true else 0 | `speaker` (u8) | `RABBLE_SETTING_SPEAKER` |
| `set_mic_gain(db)` | `db` clamped into 0..36 (no rounding to 3 dB steps) | `mic_gain` (u8) | `RABBLE_SETTING_MIC_GAIN` |
| `set_brightness(pct)` | `pct` clamped into **10**..100 (0 becomes 10) | `bright` (u8) | `RABBLE_SETTING_BRIGHTNESS` |
| `set_sleep_s(secs)` | `secs` clamped into 0..3600 | `sleep_s` (u16) | `RABBLE_SETTING_SLEEP` |
| `set_power_off_s(secs)` | `secs` clamped into 0..3600 | `off_s` (u16) | `RABBLE_SETTING_POWER_OFF` |
| `set_wifi_on(on)` | 1 if true else 0 | `wifi_on` (u8) | `RABBLE_SETTING_WIFI` |
| `set_raise_wake(on)` | 1 if true else 0 | `raise` (u8) | `RABBLE_SETTING_RAISE` |

The inputs are full-range `int`: negative values, `INT_MIN` and `INT_MAX` clamp to the nearest bound (never wrap through the narrower storage type; for example 256 gives 100 for volume, not 0, and 65536 gives 3600 for sleep). Clamping happens on the integer before it is narrowed. The vectors pin these.

### 7.2 `set_voice(voice)`

Stores the text truncated to 15 characters (no error, no trimming, no case change, any characters allowed). A NULL pointer and an empty string both store the empty string. Always writes `voice` (string, possibly empty), always notifies `RABBLE_SETTING_VOICE`. Empty means sCoRE's default voice. Safe against concurrent string getters (5.2).

### 7.3 `set_beam_url(url)`

1. A NULL pointer or empty string **restores the build's default URL** (`CONFIG_RABBLE_BEAM_DEFAULT_URL`): the default text is stored (key `beam_url` holds the default text, not an empty string), the getter then returns the default, and the listener is notified. If the build default is itself empty, the stored and returned URL is empty.
2. Otherwise the text is stored truncated to 127 characters (silently). No syntax check: any text, including one that is not a URL, is accepted.
3. Always writes `beam_url`, always notifies `RABBLE_SETTING_BEAM`.

### 7.4 `esp_err_t set_beam_token(token, append)`

| Case | Result |
|---|---|
| `append` false | The stored token becomes exactly `token` (NULL counts as empty; an empty token clears it). |
| `append` true | The text of `token` is added to the end of the current stored token (NULL or empty adds nothing). Used for sending a token in several console writes. |
| the resulting length (current length when appending, else 0, plus the length of `token`) is at most 255 | success: the token is stored, saved to `beam_token` (string), the function returns `ESP_OK`, the listener is notified with `RABBLE_SETTING_BEAM`. |
| the resulting length would exceed 255 | **nothing changes**: the old token stays (also when replacing), nothing is written or committed, no listener call, the function returns `ESP_ERR_INVALID_SIZE`. |

A token of exactly 255 characters is valid. Appending an empty string to any token succeeds and still writes and notifies (even when the token is already 255 long). Replacing a full token with a shorter one works. The returned code is the only token-related error: `ESP_ERR_INVALID_SIZE` for oversize, otherwise `ESP_OK`; the console layer prints `error: token too long` for any non-OK. The module never logs the token or part of it. Token characters are arbitrary (no trimming, no escaping, no validation). The chunk-by-chunk behaviour is observable: after each accepted append the saved value and getter equal the whole token so far, so a power loss between chunks leaves the partial token stored.

## 8. Behaviour on errors and bad stored data (collected)

| Situation | Behaviour |
|---|---|
| First boot, no stored data | defaults of section 3, nothing written. |
| NVS partition needs erasing (no free pages, new version) | warn, erase the whole partition, init again; all stored data gone, including other modules' namespaces (the Wi-Fi module's saved networks live in the same partition under `rabble_wifi`: they are lost too). |
| Flash NVS init fails otherwise | `rabble_settings_init` returns the code; values at defaults; the app treats this as fatal. |
| Namespace open fails | `rabble_settings_init` returns the code; same. |
| A key has another type than listed | that value takes its default; the stored entry is left alone. |
| A stored string is longer than the value's capacity (voice 15, URL 127, token 255) | ignored, default used; later setters overwrite it. |
| A stored volume, mic gain or brightness out of range | clamped on load (not rewritten). |
| A stored sleep or power-off beyond 3600 | kept as is (not clamped), reported by the getter as is. |
| A stored boolean other than 0/1 | nonzero means true. |
| A stored URL that is empty | URL is empty; the default is not substituted. |
| Write or commit fails while setting | ignored; in-memory value and listener as normal; old value returns after reboot. |
| Setter given out-of-range input | clamped (7.1), never an error. |
| Token too long | `ESP_ERR_INVALID_SIZE`, no change (7.4). |

## 9. What the module calls and what it must not do

| Callee | Use |
|---|---|
| ESP-IDF NVS (`nvs_flash`, `nvs`) | flash init and erase, open the `rabble` namespace, typed get/set (u8, u16, string), commit. A commit follows every value write. |
| ESP-IDF log | one init line and the erase warning. |
| FreeRTOS | whatever serialization is needed for section 5. |
| `sdkconfig.h` | the three `CONFIG_RABBLE_*` symbols of section 3. |

It must not call any other RaBbLE module (it is a leaf: state, board, wifi, beam, audio, UI are all above it), must not start tasks, and must not hold any serialization while calling the listener. After concurrent string setters finish, the stored string and the in-memory string must agree. It must keep its own namespace separate from the Wi-Fi module's (`rabble_wifi`).

## 10. Limits (collected)

| Item | Value |
|---|---|
| Voice | 15 characters (buffer 16) |
| Beam URL | 127 characters (buffer 128) |
| Beam token | 255 characters (buffer 256) |
| Wi-Fi SSID / password (macros only) | 32 / 64 characters |
| Volume | 0..100; mic gain 0..36; brightness 10..100; sleep and power-off 0..3600 s |
| Store | namespace `rabble`, 11 keys, one commit per write |
| Listener | one, same-task, synchronous, no lock held |

## 11. Device behaviour checklist (integrator)

All of these are serial-only unless noted; use `>key=value` console lines (W1 setup) and `>status`.

1. First boot after an erase (`idf.py erase-flash`, then flash): `>status` shows volume 70, speaker true, mic gain 30, brightness 100, sleep 120, power-off 45, Wi-Fi on, the build's default beam URL, voice empty, no token.
2. Persistence: set `volume=35`, `mic_gain=12`, `brightness=40`, `sleep=30`, `power_off=0`, `speaker=0`, `voice=daniel`, `raise_wake=0`, `beam.url=ws://h/p`; reboot; `>status` shows all of them. Then `beam.token=abc`, reboot, `>status` shows a token present (never its text).
3. Existing devices: after flashing the new build over a unit configured with the old build, all of the above survive (no re-erase, no change of values; the check that NVS wasn't erased: saved Wi-Fi networks still join).
4. Clamping (via the UI sliders and the setup ranges): the setup layer rejects out-of-range numbers before they reach this module; reaching the clamp needs the host test (vectors). On the device the brightness slider cannot go under 10, and an out-of-range console number is refused by the setup layer.
5. `>beam.url=` (empty) then `>status` shows the build default URL; reboot keeps it.
6. Token chunks: `>beam.token=` followed by `>beam.token+=<~100 chars>` three times (total over 255): the third append replies `error: token too long`, `>status` token still present, the earlier chunks remain; replacing with `>beam.token=<255 chars>` replies `ok`; `>beam.token=<256 chars>` replies `error: token too long` (needs a console line of up to 1023 characters).
7. Listener effects (hands/audio): `volume=` changes the output loudness at once; `mic_gain=` changes the capture level at once; `wifi.on=0` takes Wi-Fi down, `wifi.on=1` brings it back promptly; `beam.url=` makes the beam client reconnect to the new endpoint (visible in `>status` beam state).
8. Settings UI (hands): toggling Speaker, Raise to wake, Wi-Fi; sliders for volume, mic gain, brightness; sleep and power-off choice lists; sCoRE URL and token text entry; voice cycling. Each survives a reboot.
9. Boot log has no lines from this module other than the single info summary (and nothing on a normal boot at warning level).

## 12. Test vehicle and golden vectors

All of the logic is host-testable. The implementer's test vehicle must run the store against an **in-memory fake of the NVS API** with these semantics: typed entries (u8, u16, string) per namespace; reading an absent key or a key of another type fails and leaves the destination unmodified; reading a string into a buffer too small for the stored text plus its terminator fails and leaves the destination unmodified; each value write counts, each commit counts; failure injection for flash init (no-free-pages, new-version, other), namespace open, value write and commit; erase clears everything. Settings sizes and Kconfig values come from a fixed test `sdkconfig` (volume 70, power-off 45, default URL `wss://rabble-score-x7qq.onrender.com/api/v1/beam`). The test registers a listener that records the setting names, and each scenario starts in a fresh process or after a state reset so RAM state is at build defaults.

Vectors in `w3-settings-vectors/` (README there describes columns and the input notation):

| File | Replay |
|---|---|
| `defaults.tsv` | prepare the stored content named by the scenario, run init, compare all getters and the final stored content. |
| `init-errors.tsv` | same, under injected flash-init and open failures. |
| `setters.tsv` | fresh boot on an empty store, call one setter with one input, compare return, listener, write/commit counts, the stored entry and all getters. |
| `sequences.tsv` | op sequences with reboots, repeated sets and write failures. |
| `token.tsv` | token replace/append sequences. |

All five must pass byte for byte. The `reboot` op means: reset RAM state to build defaults and run init again on the same fake store.

## 13. Ambiguities and decisions for the integrator

1. **Sleep and power-off not clamped on load.** A stored value above 3600 is kept (vectors pin it). Only a pre-existing bad value can cause it; the setters never write one. Left as is.
2. **Always save, always notify, even unchanged.** Wears flash a little (each console or UI change commits) and fires the listener (for example the Wi-Fi manager reconnects when `wifi.on=1` is repeated). Kept, since callers (setup `wifi.connect`) rely on the notify. Whether to skip unchanged writes is Mark's call.
3. **Persist failures are silent.** There is no way to tell the user a setting did not stick. Left as is.
4. **Stored empty URL beats the default.** Only reachable from a hand-edited store; kept.
5. **Mic gain is not rounded to 3 dB here.** The audio layer applies the 3 dB steps; the getter can return a non-multiple of 3 (for example from `>mic_gain=7`).
6. **Erase on layout change** also wipes the Wi-Fi module's saved networks (same partition). Intended in the sense of a corrupt partition; noted because it surprises users.
7. **Setter before init.** Unspecified but must not crash; the original ordering (init first in the app) makes it unreachable.
8. **Log text.** Only `NVS layout changed, erasing` is quoted; the init summary wording is free (the checklist does not grep it).
