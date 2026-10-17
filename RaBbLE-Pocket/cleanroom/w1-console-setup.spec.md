# W1 spec: rabble_console and rabble_setup (serial port access and the key=value setup commands)

> Clean-room spec, wave W1. Author role: S. Files to be replaced: `apache/rabble_console.c/.h` and `apache/rabble_setup.c/.h`. New files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Interface names are frozen: every existing caller compiles and behaves unchanged. Two modules in one document; sections 1 to 4 are the console, 5 to 9 are setup, 10 and 11 are shared.

---

# Part A: rabble_console

## 1. Purpose

A thin access layer over the chip's built-in USB Serial/JTAG port, which is the bench and setup console of the gadget and also carries the log. It lets the input module's serial task install a receive buffer, read single bytes (blocking), write raw bytes, and ask whether a USB host is currently attached. It adds no framing, line editing, echo, or parsing; lines are assembled by the caller. It owns no task and no state of its own beyond what the underlying ESP-IDF driver keeps.

## 2. Public interface (complete and exact)

Header `rabble_console.h`, `#pragma once`. It must include `<stdbool.h>`, `<stddef.h>`, `<stdint.h>` and `"esp_err.h"` (callers get `esp_err_t`, `bool`, `size_t`, `uint8_t` through it). `extern "C"` guards are allowed. No types, no macros, no globals are exported.

| Prototype | Summary |
|---|---|
| `esp_err_t rabble_console_install(size_t rx_buf);` | Install the driver with a receive buffer of `rx_buf` bytes. Bytes that do not fit while the reader is slow are dropped (the driver's behaviour; the module adds no overflow handling). Returns `ESP_OK` on success, otherwise the driver's error code unchanged (a second install returns the driver's "invalid state" error; the module does not guard against it). |
| `bool rabble_console_getc(uint8_t *c);` | Block, with no timeout, until one byte arrives and store it in `*c`. Returns true if a byte was read. Returns false only when the driver reports an error or is not installed (the caller then loops and retries). `c` must be non-NULL. |
| `void rabble_console_write(const void *buf, size_t n);` | Queue `n` raw bytes for the host, waiting as long as needed for room. No return value, no newline translation. Currently has no caller; it is public and must exist. |
| `bool rabble_console_host(void);` | True when a USB host is actively reading the port (as the driver's connection query reports). A UART bridge cannot be detected, so it reports false. Must be safe to call before `rabble_console_install` and from any task. |

External symbol count for this module: 4 functions, 0 macros, 0 types, 0 globals.

### 2.1 Who uses what

| Symbol | Users |
|---|---|
| `rabble_console_install` | `apache/rabble_input.c`, serial task start, once, with a 1024-byte buffer (sized so that one console line, up to 1023 characters plus newline, fits while the task is busy). If it returns anything other than `ESP_OK` the serial task deletes itself and the rest of input keeps working. |
| `rabble_console_getc` | `rabble_input.c`: the serial task's main loop (each byte) and the line reader that follows a `>` byte (up to a `\n`). Non-blocking behaviour is never needed. |
| `rabble_console_host` | `rabble_input.c`, the power-update path, from the input task: decides whether the CPU may be slowed and the display paused while asleep on battery (a connected host forbids slowing, so the console stays responsive). Called very often; it must be cheap and must not block. |
| `rabble_console_write` | none today. |

## 3. Behaviour

1. The implementation uses ESP-IDF's USB Serial/JTAG driver (`driver/usb_serial_jtag.h`) and nothing else. It starts from the driver's default configuration and changes only the receive buffer size, so the transmit buffer and other defaults stay at the driver's defaults.
2. Installing the driver must not break existing log and `printf` output: after install the log lines and the `@...` reply lines that other modules print with `printf` still reach the host exactly as before (this is what the device does today).
3. `getc` yields one byte per call and never fabricates one. Two bytes arriving close together are returned by two successive calls in order.
4. `write` hands over exactly the bytes given, in order, to be sent to the host. With no host attached the call must not corrupt anything; whether it eventually drops the bytes or waits is the driver's behaviour and is acceptable (the device never calls it today, see ambiguity 1).
5. `host` reports the connection state as of the call; it does not latch.
6. No locking of its own; the driver handles concurrent access. The serial task is the only reader.

## 4. Threading, limits, may-call

| Item | Value |
|---|---|
| Caller task | `rabble_serial` (priority 5, 3584-byte stack): install, getc. The input task (priority 6) calls `host`. |
| Blocking | `getc` blocks indefinitely by design. `write` may block. `install` and `host` do not block. |
| Receive buffer | whatever the caller passes (1024 in practice) |
| May call | only the USB Serial/JTAG driver functions: install, read-bytes, write-bytes, is-connected. No other `rabble_*` module. |
| Stack | each function adds a negligible frame; they are called with a 3.5 KB task stack. |

---

# Part B: rabble_setup

## 5. Purpose

Executes device setup commands written as one line of `key=value` text, independent of the transport that delivered them (the USB serial console today; a Bluetooth provisioning feeder could call the same entry point later). It changes Wi-Fi, the sCoRE beam endpoint and token, and the user settings, triggers two bench actions, and reports every result as one line on the console. It also builds a JSON snapshot of device state for the `status` console command, and computes the device's advertised name.

It holds the command history of exactly one thing (the text of the last result) and a small pending-credentials area for the two-step Wi-Fi flow. It never stores the settings itself: persistence, clamping and notifying listeners are done by `rabble_settings`, `rabble_wifi`, and the other modules it calls.

## 6. Public interface (complete and exact)

Header `rabble_setup.h`, `#pragma once`, must include `<stddef.h>` (for `size_t`). Nothing else is required of it (callers that need `bool` or `esp_err_t` include their own). `extern "C"` guards allowed. No types, macros or globals.

| Prototype | Summary |
|---|---|
| `void rabble_setup_command(char *line);` | Run one setup command. `line` is a NUL-terminated, writable string without the leading `>` and without a newline or carriage return. The function may modify the buffer in place. |
| `int rabble_setup_status_json(char *out, size_t len);` | Write one JSON object (format in 8.2) into `out`, bounded by `len` bytes including the NUL, and return the length the full text would have, as `snprintf` does. A return value of `len` or more means the output was cut. |
| `const char *rabble_setup_device_name(void);` | Return a pointer to a NUL-terminated string `RaBbLE-Pocket-XXXX` (see 8.3). The pointer is valid for the life of the program and the content never changes. |

External symbol count for this module: 3 functions, 0 macros, 0 types, 0 globals. Combined with the console: 7 public names.

### 6.1 Who uses what

| Symbol | Users |
|---|---|
| `rabble_setup_command` | `apache/rabble_input.c`, the serial task: when a byte `>` arrives it reads the rest of the line (carriage returns skipped, up to 1023 characters, anything longer is dropped, so a too-long line arrives cut at 1023 characters), hands it to a console-only command check, and only if that check does not claim the line passes it here. The console-only commands claimed first are `status`, `power`, `power.reset`, `nap`, anything starting `face=` and anything starting `chat=`; they never reach setup. If memory for the line buffer cannot be had, the line is read and dropped and setup is not called. |
| `rabble_setup_status_json` | `rabble_input.c`, the `status` console command: passes a 1024-byte heap buffer and wraps the result as `@status {"board":"<name>","chat":true,"device":<json>}`. The wrapper is the caller's; this module only produces the object. |
| `rabble_setup_device_name` | `accord/rabble_beam_score.c`, in the beam task, when it builds the hello message; and internally by the status JSON. The stub header used by the W0 seam test (`test/cleanroom/w0/seam_test/stubs/rabble_setup.h`) declares only this function. |

### 6.2 What it may call

Only these (all public interfaces):

| Area | Used for |
|---|---|
| `rabble_settings.h` | the setters and getters in the table of section 7.1; the length macros `RABBLE_SSID_MAX` (32), `RABBLE_PASS_MAX` (64), `RABBLE_BEAM_URL_MAX` (127), `RABBLE_VOICE_MAX` (15), `RABBLE_MIC_GAIN_MAX` (36) |
| `rabble_wifi.h` | `rabble_wifi_join`, `rabble_wifi_forget`, `rabble_wifi_status` and the status type, the state enum |
| `rabble_beam.h` | `rabble_beam_test`, `rabble_beam_status`, `rabble_beam_state_name` |
| `rabble_voice.h` | `rabble_voice_request_loopback` |
| `rabble_state.h` | `rabble_state_power` (status) and `rabble_state_poke` (after each command) |
| ESP-IDF | `esp_log.h` (logging), `esp_mac.h` (read the Wi-Fi station MAC), `esp_app_desc.h` (`esp_app_get_description()->version`), the C library (`printf`, `fflush`, `snprintf`, `strtol`) |

It must not touch NVS, the radio, audio or the display directly, and must not call `rabble_wifi_apply` or `rabble_beam_config_changed` (the settings listener reacts to a changed setting by itself).

## 7. Command behaviour

### 7.1 Parsing rules

1. The line is split at the first `=` character. Everything before it is the command name; everything after is the value. If there is no `=`, the value is the empty string. Later `=` characters belong to the value (tokens and URLs may contain them).
2. Matching of the name is exact and case sensitive. No whitespace is trimmed from the name or the value; a value keeps trailing spaces. An empty line, or a name that matches nothing, gets the unknown-command reply.
3. Integer values must be a plain base-10 integer (an optional sign is tolerated as the C library does), non-empty, with nothing after the digits, and inside the command's inclusive range. Out-of-range, empty, hex, decimal fractions and words such as `on` or `true` are all rejected; they are never clamped. A rejected value produces the same reply as an unknown name (the single text in 7.3), and no setting changes.
4. A command whose name is right but whose integer value is rejected falls through to the unknown reply; this is intended and must be preserved.
5. A command whose handler is reached produces the success reply `ok` unless the table below says otherwise.

### 7.2 The command table

"Persists" means the called module saves it to flash and notifies its change listener; this module does not persist anything itself.

| Command | Accepted argument | Effect | Reply | Persistence |
|---|---|---|---|---|
| `wifi.ssid=<text>` | any text; kept to 32 characters (longer is cut) | Stores it as the pending network name AND clears the pending password. Nothing is joined yet. | `ok` | none (RAM only; lost on reboot) |
| `wifi.pass=<text>` | any text, including empty; kept to 64 characters | Stores it as the pending password. | `ok` | none (RAM only) |
| `wifi.connect` | (value ignored) | If no pending name exists (never set, or set empty): reply error, nothing else happens. Otherwise: turn Wi-Fi on in settings (`rabble_settings_set_wifi_on(true)`), then call `rabble_wifi_join(name, password)`, then erase the pending password (the name stays). Order matters: Wi-Fi on first, then join. | `ok` or `error: send wifi.ssid first` | Wi-Fi on flag and the saved network list (by those modules) |
| `wifi.forget` or `wifi.forget=<ssid>` | optional text | `rabble_wifi_forget(value)` with the value as given; an empty value means every saved network | `ok`, always (even if that name was not saved) | saved network list |
| `wifi.on=<0\|1>` | integer 0 to 1 | `rabble_settings_set_wifi_on`. Not listed in the header comment but supported and must be kept. | `ok` | settings |
| `beam.url=<text>` | any text; empty restores the build default (the settings module does that) | `rabble_settings_set_beam_url` | `ok` | settings |
| `beam.token=<text>` | any text | Replace the stored token (`rabble_settings_set_beam_token(value, append=false)`). If the settings module refuses (token would exceed 255 characters), the reply is the error and the old token is unchanged. | `ok` or `error: token too long` | settings |
| `beam.token+=<text>` | any text | Same but appends to the stored token (for sending a long token in chunks). Total over 255 characters: error, nothing changes. The command name here is `beam.token+`, then `=`. | `ok` or `error: token too long` | settings |
| `beam.test` | (ignored) | `rabble_beam_test()`: reconnect to sCoRE now; the outcome is visible later in the status. The reply does not wait for the result. | `ok` | none |
| `test.loopback` | (ignored) | `rabble_voice_request_loopback()`: asks the voice task to run the speaker-to-mic bench test at the current volume when idle; results go to the log. | `ok` | none |
| `volume=<n>` | 0 to 100 | `rabble_settings_set_volume` | `ok` | settings |
| `voice=<name>` | any text, including empty; the settings module keeps up to 15 characters; there is no validation here (sCoRE ignores names it does not offer; known names are `daniel`, `austin`, `troy`; empty means sCoRE's default) | `rabble_settings_set_voice` | `ok` | settings |
| `speaker=<0\|1>` | 0 to 1 | `rabble_settings_set_speaker_on` (0 = replies shown, not played) | `ok` | settings |
| `mic_gain=<n>` | 0 to 36 (`RABBLE_MIC_GAIN_MAX`) | `rabble_settings_set_mic_gain` | `ok` | settings |
| `brightness=<n>` | 10 to 100 | `rabble_settings_set_brightness` | `ok` | settings |
| `sleep=<n>` | 0 to 3600 seconds (0 = never) | `rabble_settings_set_sleep_s` | `ok` | settings |
| `raise_wake=<0\|1>` | 0 to 1 | `rabble_settings_set_raise_wake` | `ok` | settings |
| `power_off=<n>` | 0 to 3600 seconds (0 = never) | `rabble_settings_set_power_off_s` | `ok` | settings |

Argument forms of note:

1. The names `status`, `power`, `power.reset`, `nap`, `face=` and `chat=` are NOT setup commands; if they reach this function by any route they get the unknown reply.
2. `wifi.ssid`, `wifi.pass`, `wifi.connect`, `wifi.forget`, `beam.url`, `beam.token`, `beam.token+`, `beam.test`, `test.loopback`, and `voice` accept a missing `=` (empty value) and still run. Only the integer commands reject empty.
3. Because `wifi.connect` erases only the password, a second `wifi.connect` without a new `wifi.pass` joins the same name with an empty password (this is the device's current behaviour and is to be kept; see ambiguity 3).

### 7.3 Replies, results and logging (exact user-visible text)

After every command, whether it succeeded or not, in this order:

1. The result text is remembered as the "last result": the command name, a colon, a space, then the reply. Example: `volume: ok`, `wifi.connect: error: send wifi.ssid first`, `foo: error: unknown command or bad value`. The remembered text is capped at 63 characters (longer is cut; this only happens with very long unknown names). The value is never part of it. For a line with no name (`>` alone or `>=x`) the text is `: error: unknown command or bad value`.
2. One log line at info level, tag `rabble_setup`, with the message `cmd <name>=<value> -> <reply>` (for a plain case), or `cmd <name> -> <reply>` for secrets: when the name is `wifi.pass` or begins with `beam.token` (this includes `beam.token+` and any longer name that starts that way, even unknown ones) the `=` and the value are omitted from the log. Other values, including the Wi-Fi name and the beam URL, are logged. A command with no `=` still logs `cmd <name>=` followed by an empty value (the original prints the equals sign whenever the name is not a secret).
3. One console line printed to standard output and flushed: `@setup <last result>` followed by a newline. Example: `@setup volume: ok`. This is the line host tools wait for. It is printed exactly once per command.
4. The interaction clock is poked (`rabble_state_poke()`) so the screen wakes and the idle timers restart. This happens for every command, including errors and unknown names.

Reply texts (all exact):

| Situation | Reply |
|---|---|
| success | `ok` |
| `wifi.connect` before any usable `wifi.ssid` | `error: send wifi.ssid first` |
| token would exceed 255 characters | `error: token too long` |
| unknown name, rejected integer, or empty line | `error: unknown command or bad value` |

Secrets are never echoed anywhere: not in the reply, not in the log, not in the remembered result, not in the status JSON (only a presence flag for the token; the Wi-Fi password is never reported).

### 7.4 State kept

| State | Initial | Changed by |
|---|---|---|
| last result text (cap 63 characters + NUL) | `ready` | every command |
| pending Wi-Fi name (up to 32 characters) | empty | `wifi.ssid`; stays after connect |
| pending Wi-Fi password (up to 64 characters) | empty | cleared by `wifi.ssid`; set by `wifi.pass`; erased after `wifi.connect` joins |

The pending credentials survive only until reboot. They are not mirrored to flash by this module.

### 7.5 Edge cases

1. A line of 1023 characters from a cut-off long line is processed as given; there is no "too long" reply from this module.
2. A Wi-Fi name of exactly 32 characters is accepted whole; 33 or more are cut at 32 without an error. Password cut at 64, same.
3. `wifi.connect` with a pending name that is the empty string (`wifi.ssid=` then connect) gives the `send wifi.ssid first` error.
4. `wifi.ssid` after `wifi.pass` wipes the pending password, so the sequence for an open network is `wifi.ssid=...`, `wifi.connect`; for a secured network it is `wifi.ssid`, `wifi.pass`, `wifi.connect` in that order.
5. `beam.token=` with an empty value is valid and clears the token (reply `ok`).
6. The text of the line is damaged by processing (split at `=`); callers must not reuse it.
7. The module does not rate-limit or queue; each call runs to completion synchronously.

## 8. Status snapshot and device name

### 8.1 Data sources

Wi-Fi status (state, name, address, signal), beam status (state), power (battery percent, USB present, charging), and from settings: the beam URL and voice, whether Wi-Fi is on, whether a beam token exists (token length above zero), volume, speaker flag, mic gain, brightness, sleep seconds, power-off seconds; plus the app version string, the device name and the last result text.

### 8.2 Output format

One JSON object on a single line, no whitespace outside strings, keys in exactly this order (parsers and humans depend on it):

| Order | Key | Type | Value |
|---|---|---|---|
| 1 | `name` | string | device name (8.3) |
| 2 | `fw` | string | the firmware version string from the app description |
| 3 | `battery` | number | battery percent, -1 meaning no battery |
| 4 | `usb` | boolean | external power present |
| 5 | `charging` | boolean | charger active |
| 6 | `wifi` | object | members in order: `on` (boolean, Wi-Fi switched on in settings), `state` (string, see below), `ssid` (string, current network name, empty if none), `ip` (string, dotted address as reported, empty if none), `rssi` (number, as reported) |
| 7 | `beam` | object | members in order: `url` (string), `token` (boolean, true if any token is stored; the token itself never appears), `state` (string, the beam module's display name for its state: `Not set up`, `Offline`, `Saved`, `Connecting`, `Connected`, `Can't connect`) |
| 8 | `voice` | string | stored voice name, empty for default |
| 9 | `volume` | number | percent |
| 10 | `speaker` | boolean | |
| 11 | `mic_gain` | number | dB |
| 12 | `brightness` | number | percent |
| 13 | `sleep` | number | seconds, 0 never |
| 14 | `power_off` | number | seconds, 0 never |
| 15 | `last` | string | the last result text (7.3 rule 1; `ready` before any command) |

The Wi-Fi `state` strings, by the Wi-Fi module's states in enum order (off, no network, connecting, connected, failed, not nearby): `off`, `no_network`, `connecting`, `connected`, `failed`, `not_nearby`; any value outside that range gives `unknown`.

String escaping applies to `ssid`, `url` and `last` only: a double quote or backslash is preceded by a backslash; any character below 0x20 is replaced by `?`; bytes at 0x80 and above pass through unchanged; the other strings (`name`, `fw`, `ip`, `voice`, `state` texts) are inserted as is (the beam state `Can't connect` contains an apostrophe, which is legal in JSON). Escaped fields are cut so the result stays bounded: ssid at no more than 62 output characters, url at no more than 252, last at no more than 125 (a 32-character ssid made entirely of quotes escapes to 64 characters and loses its tail; exact cut points are not relied on, only that the object stays valid JSON and within bounds).

Booleans are written `true` or `false`. The return value and truncation follow `snprintf`. With the worst case of all fields long, the text stays under 1024 bytes, which is the buffer the console command supplies; if `len` is smaller, the output is cut and NUL terminated as `snprintf` does, and the full length is returned.

### 8.3 Device name

`RaBbLE-Pocket-` followed by four uppercase hexadecimal digits made of the fifth and sixth bytes (indices 4 and 5) of the Wi-Fi station MAC address, each as two digits. Example: a MAC ending `...:9A:0F` gives `RaBbLE-Pocket-9A0F`. It is read from the station MAC (`esp_read_mac`, station kind), is at most 23 characters, stays fixed after first use, and is computed on first call. It is called from the beam task and may be called from any task including before Wi-Fi starts (reading the MAC does not require Wi-Fi); concurrent first calls must all end up returning the same content.

## 9. Threading, limits, timing

| Item | Rule |
|---|---|
| Caller of `rabble_setup_command` and `rabble_setup_status_json` | the `rabble_serial` task only (priority 5, 3584-byte stack, no core pinning). The two functions are not required to be reentrant against each other; the pending credentials and last result need no lock because there is one caller task. If a second feeder (Bluetooth) is added later it must serialize its calls; not required now. |
| Caller of `rabble_setup_device_name` | beam task, serial task, any task; must be safe from several tasks at once. |
| Stack budget | the serial task has 3584 bytes, shared with `printf` and logging. Keep this module's own frame use for `rabble_setup_command` under about 300 bytes and for `rabble_setup_status_json` under about 900 bytes (the status path assembles bounded string copies for ssid, url, last, a Wi-Fi status and a beam status). Large buffers go on the heap or in static storage only if internal RAM allows (the device runs without PSRAM in some builds; do not add large static arrays). |
| Blocking | A command may block as long as the settings save or the Wi-Fi/beam call takes (flash write, tens of milliseconds). No waiting for the network result. |
| Output | the `@setup` line is printed and flushed before the function returns. |
| Time | each command completes in well under a second; none loops or waits on network events. |
| Limits | line up to 1023 characters; name matching exact; last result 63 characters; status under 1024 bytes. |

## 10. Device behaviour checklist (integrator)

Use a serial terminal on the gadget's USB port. Every console line starts with `>`; every command must answer with a single `@setup ...` line and be visible in the log as `rabble_setup: cmd ...`.

| # | Type | Expect |
|---|---|---|
| 1 | `>volume=40` | `@setup volume: ok`; the volume slider in settings reads 40; survives a reboot |
| 2 | `>volume=101`, `>volume=`, `>volume=abc`, `>volume=40x`, `>volume` | each prints `@setup volume: error: unknown command or bad value`; volume unchanged |
| 3 | `>nonsense` and `>` alone | `@setup nonsense: error: unknown command or bad value` and `@setup : error: unknown command or bad value` |
| 4 | `>wifi.connect` straight after boot (before any ssid) | `@setup wifi.connect: error: send wifi.ssid first` |
| 5 | `>wifi.ssid=<your network>` then `>wifi.pass=<password>` then `>wifi.connect` | three `ok` lines; the log shows `cmd wifi.ssid=<name> -> ok`, `cmd wifi.pass -> ok` (password absent), `cmd wifi.connect= -> ok`; Wi-Fi comes on and joins; the network appears first in the saved list |
| 6 | `>wifi.ssid=<open network>` then `>wifi.connect` (no pass) | joins with an empty password; no leftover password from step 5 is used |
| 7 | `>wifi.connect` a second time with no new pass | joins the same name again with an empty password (documented quirk; secured networks will fail with the wrong-password state) |
| 8 | `>wifi.forget=<name>`, then `>wifi.forget` | `ok` each; first removes one saved network, second removes all; `ok` even for an unsaved name |
| 9 | `>wifi.on=0`, `>wifi.on=1`, `>wifi.on=2` | the first two `ok` and Wi-Fi goes off/on; the third is the error reply |
| 10 | `>beam.url=ws://192.168.1.20:8000/api/v1/beam`, `>beam.test` | `ok` each; status `beam.state` goes to `Connecting` then `Connected` or `Can't connect`; `>beam.url=` restores the build default |
| 11 | `>beam.token=abc`, then `>beam.token+=def`, then `status` | `ok`, `ok`; status shows `"token":true`; the token string is never printed anywhere; log lines read `cmd beam.token -> ok` and `cmd beam.token+ -> ok` |
| 12 | `>beam.token=` then `status` | `ok`; `"token":false` |
| 13 | send a 256-character token, and an append that would pass 255 | `@setup beam.token: error: token too long` and the `beam.token+` form; the earlier token is intact |
| 14 | `>voice=troy`, `>voice=` | `ok`; status `voice` shows `troy` then empty |
| 15 | `>speaker=0`, `>mic_gain=36`, `>mic_gain=37`, `>brightness=9`, `>brightness=10`, `>sleep=3600`, `>sleep=3601`, `>power_off=0`, `>raise_wake=1` | `ok` for the in-range values, error for 37, 9 and 3601; screen brightness and sleep timer follow |
| 16 | `>test.loopback` while idle | `ok`; the speaker plays and the log shows the loopback result |
| 17 | any command while the screen is dark | the screen wakes (the poke); the idle counter restarts |
| 18 | `status` | `@status {"board":"...","chat":true,"device":{...}}` with the device object in exactly the key order of 8.2, valid JSON; `name` matches `RaBbLE-Pocket-XXXX` for the last two MAC bytes; `fw` equals the build version; `last` shows the previous command result; `rssi`, `ip` and `ssid` match the Wi-Fi settings page |
| 19 | `>wifi.ssid=a"b\c` then `status` | `last` shows `wifi.ssid: ok`; the status JSON still parses with a standard parser (the pending name is not part of status; if a network with a quote in its name is available, join it and confirm the escaped `ssid`) |
| 20 | `>face=happy`, `>chat=hi`, `>nap` | handled by the input module, not this one; confirm none prints an `@setup` line |
| 21 | a 1100-character junk line | one `@setup ` line whose text is the unknown-name result cut at 63 characters (so it shows only the start of the junk name); the device stays responsive |
| 22 | beam hello (connect the beam to sCoRE and inspect its hello) | the `device` field equals the status `name` |
| 23 | console with the log: press the talk button and watch | the log text and the `@setup` replies interleave without corruption; the receive path loses no bytes while typing a 1000-character line at normal paste speed |
| 24 | power-saving: asleep on battery with a USB host attached | the CPU is not slowed down (console host reports true); unplug USB then the device may slow; typing `z` and `w` still work after |

## 11. Test vehicle

Host harness with plain gcc, one executable per module, no ESP-IDF, under `cleanroom/console_setup/test/`. Run with `-Wall -Wextra -Werror`.

### 11.1 Console

Stub header `driver/usb_serial_jtag.h` supplying the four driver functions that the module uses (install taking a config struct with a receive-buffer-size field and a transmit-buffer-size field, read bytes, write bytes, is-connected), a default-config macro, `esp_err.h`, and `freertos` constants for the wait-forever value. Recording stubs log arguments.

Cases:

1. `install(1024)` hands the driver a config whose receive size is 1024 and whose other fields equal the default; return value passes through (test with `ESP_OK` and with an error code).
2. `getc` returns true and sets `*c` when the stub driver reports one byte read; returns false when the stub reports zero or an error; the stub records that the wait was unbounded.
3. Two successive bytes come out in order.
4. `write(buf, n)` forwards the same pointer contents and length to the driver, and the wait is unbounded; `write(buf, 0)` does not crash.
5. `host()` mirrors the stub's connection flag both ways, with no install call made first.

### 11.2 Setup

Stubs: `rabble_settings.h` (recording setters with the real `RABBLE_*_MAX` values, getters returning scripted values, a settable token that refuses when over 255 characters, an append flag), `rabble_wifi.h` (records `join` and `forget` arguments, scripted `status`), `rabble_beam.h` (records `test`, scripted status, real display names for the state), `rabble_voice.h` (counts loopback requests), `rabble_state.h` (scripted power, counts pokes), `esp_log.h` (captures the formatted log line and tag), `esp_mac.h` (returns a scripted MAC), `esp_app_desc.h` (a version string). Capture standard output.

Cases:

1. `volume=40`: setter called with 40, output exactly `@setup volume: ok\n`, one poke, one log line `cmd volume=40 -> ok`.
2. Boundaries for every integer command: lowest and highest accepted values pass, one beyond each side gives `error: unknown command or bad value` and no setter call. Include `volume` (0, 100), `mic_gain` (0, 36), `brightness` (10, 100), `sleep` (0, 3600), `power_off` (0, 3600), `speaker`, `raise_wake`, `wifi.on` (0, 1; 2 rejected).
3. Malformed integers: empty, `abc`, `12x`, ` 5` handled as the C library parses, `0x10`, `1.5`, `+7` accepted, `-1` rejected for all.
4. Name and split: `foo=bar=baz` gives name `foo`, value `bar=baz`; `voice=a=b` passes `a=b` to the setter; line without `=` runs `wifi.forget` as the all-networks form (forget called with empty string).
5. Wi-Fi flow: `wifi.connect` first gives `error: send wifi.ssid first` and no join. Then `wifi.ssid=Home`, `wifi.pass=pw`, `wifi.connect`: Wi-Fi-on setter called with true before join, join called with (`Home`, `pw`), password then erased; a second `wifi.connect` joins (`Home`, ``). `wifi.ssid=X` after `wifi.pass=pw` gives pending password empty. A 40-character ssid is cut to 32; 80-character password to 64. `wifi.ssid=` then connect gives the error.
6. Token: `beam.token=abc` calls the setter with append false; `beam.token+=def` with append true; setter refusal gives `error: token too long`; reply text exact. `beam.token+` as a distinct name from `beam.token`; `beam.tokenx` is unknown and its value is also absent from the log.
7. Secrets: log lines for `wifi.pass=hunter2` and `beam.token=SECRET` contain neither `hunter2` nor `SECRET` nor `=`; `@setup` line and the status JSON contain neither.
8. Unknown and empty: `""`, `"="`, `"status"`, `"face=idle"` each print the unknown error with correct name part (`@setup : error...`, `@setup status: error...`).
9. Last-result memory: after each command the status `last` field shows the `name: reply` text; before any command it is `ready`; a 100-character unknown name is cut to 63 characters in `last`.
10. Dispatch: `beam.test` calls the beam test once; `test.loopback` calls the loopback request once; `voice=` calls the setter with the empty string; no command calls anything it should not (assert call counts of all other stubs are zero).
11. Poke: every command above, including errors, pokes exactly once.
12. Status JSON: fill every stub with known values and compare the output byte for byte with an expected string in the order of 8.2; parse it with a small JSON checker (or `python3 -m json.tool` in the test script); repeat for each Wi-Fi state including an out-of-range one (`unknown`) and each of the six beam display names; token presence true and false; battery -1; booleans.
13. Status escaping: an SSID with `"` and `\` is escaped; one with a control character shows `?`; one of 32 quotes does not overflow and parses; a very long beam URL (127 characters of quotes) stays within bounds and parses.
14. Status bounds: `len` of 0 (return value is the full length, nothing written), 1, 100 (output cut with NUL, return value over 100) and 1024 (fits, no cut for worst-case inputs).
15. Device name: MAC bytes 4 and 5 `0x9A 0x0F` give `RaBbLE-Pocket-9A0F`; bytes `0x00 0x05` give `RaBbLE-Pocket-0005`; two calls return the same pointer content; called from eight threads at once (run once under ThreadSanitizer) every thread sees the same string.
16. Output discipline: standard output contains exactly one `@setup ` line per command, ending in a newline, flushed; nothing else is printed by this module.
17. Stack: compile with `-fstack-usage` (or measure with a guard in the harness) and check that `rabble_setup_command` and `rabble_setup_status_json` frames are within the budget of section 9.

## 12. Ambiguities and decisions for the integrator

1. `rabble_console_write` has no caller; its behaviour with no host attached (drop versus wait) is the ESP-IDF driver's. Any correct choice that never wedges the system is fine.
2. The header's comment lists `wifi.forget[=ssid]` and does not list `wifi.on`; the device accepts both forms and `wifi.on`. The spec keeps both.
3. A second `wifi.connect` without a new password joins with an empty password. This looks accidental but is current behaviour; keep it unless Mark rules otherwise. A cleaner design (keep the password until the next `wifi.ssid`) would change the outcome for secured networks.
4. The Wi-Fi password and beam token values are cut or accepted by the lower modules; this module does not report truncation (a 40-character name is accepted and cut silently).
5. The unknown-name reply doubles as the bad-value reply, so a user cannot tell the two apart. Kept for compatibility with any host tool that parses it.
6. The `@setup` and `@status` prefixes are parsed by host tools outside this repository (none found in the tree); treat the exact text as a contract.
7. Escaping in status is minimal by design (only `"` and `\` escaped, control characters replaced with `?`); do not replace this with a full JSON escaper, because the length bounds in 8.2 assume it.
8. The device name is cached on first use from the MAC; if a future board changes the MAC source the name changes at the next reboot only.
