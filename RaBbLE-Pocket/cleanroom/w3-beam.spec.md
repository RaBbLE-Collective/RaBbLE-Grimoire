# W3 spec: rabble_beam (beam status: the state model behind the sCoRE indicator)

> Clean-room spec, wave W3. Author role: S (Sonnet 5.5 sub-agent, S259). Firewall: S259 parent (Opus 5.5), approved after removing the original's synchronisation primitive and copy idiom; the status table stays, because for a module this small the decision table is the behaviour. Files to be replaced: `apache/rabble_beam.c`, `rabble_beam.h`, `rabble_beam_priv.h`. The new `rabble_beam.c` goes under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else; so do the two new headers. Interface names are frozen. The session task (`accord/rabble_beam_score.c`) and the console and caption helpers (`accord/rabble_beam_text.c`, `rabble_beam_text.h`) already exist, are RaBbLE's own, and stay unchanged. Golden vectors: `w3-beam-vectors/` (section 10). Companion specs: `w1-text.spec.md` (console line format, caption paging, unescape: implemented by the existing helpers, not by this module).

Treatment: clean room. Everything below is a requirement. How you structure code is yours.

---

## 1. Purpose

The beam is the device's link to sCoRE. This module is its **status side**: it keeps the last result the session task reported, combines it with the settings (is a sCoRE URL set?) and the Wi-Fi state, and answers "what is the beam doing?" for the settings page, the home page, the status bar, the entity's indicator, the voice pipeline and the serial setup JSON. It also offers the "test connection" and "settings changed" entry points, which only forward requests to the session task, and the human-readable state names.

It does not open sockets, buffer audio, or talk protocol. It holds no persistent data and owns no task.

## 2. Public interface (complete and frozen)

Two headers. The implementer writes both fresh from this section. Both use `#pragma once` and `extern "C"` guards (`#ifdef __cplusplus` / `extern "C" {` ... `}` / `#endif`) around all declarations.

### 2.1 `rabble_beam.h`

Includes: `<stdbool.h>`, `<stddef.h>`, `<stdint.h>`.

| Item | Exact declaration |
|---|---|
| state enum | `typedef enum { RABBLE_BEAM_NOT_SET, RABBLE_BEAM_OFFLINE, RABBLE_BEAM_UNTESTED, RABBLE_BEAM_TESTING, RABBLE_BEAM_REACHABLE, RABBLE_BEAM_UNREACHABLE } rabble_beam_state_t;` Order is fixed (values 0 to 5 in that order). |
| status struct | `typedef struct { rabble_beam_state_t state; char detail[48]; } rabble_beam_status_t;` The field order and the 48-byte `detail` are fixed (callers size buffers from it). |
| event enum | `typedef enum { RABBLE_BEAM_EV_NONE, RABBLE_BEAM_EV_HEARD, RABBLE_BEAM_EV_REPLY, RABBLE_BEAM_EV_DONE, RABBLE_BEAM_EV_ERROR, RABBLE_BEAM_EV_SENT } rabble_beam_ev_t;` Order fixed (0 to 5). Declared after the turn prototypes below; its position in the file is free as long as `rabble_beam_turn_event` is declared after it. |
| `void rabble_beam_start(void);` | |
| `void rabble_beam_status(rabble_beam_status_t *out);` | |
| `void rabble_beam_test(void);` | |
| `void rabble_beam_config_changed(void);` | |
| `const char *rabble_beam_state_name(rabble_beam_state_t state);` | |
| `void rabble_beam_set_resting(bool resting);` | |
| `bool rabble_beam_ready(void);` | |
| `void rabble_beam_turn_begin(void);` | |
| `void rabble_beam_turn_audio(const int16_t *pcm, size_t frames);` | |
| `void rabble_beam_turn_end(void);` | |
| `void rabble_beam_turn_cancel(void);` | |
| `rabble_beam_ev_t rabble_beam_turn_event(char *text, size_t cap);` | |
| `bool rabble_beam_turn_caption(size_t played, char *out, size_t cap);` | |
| `size_t rabble_beam_turn_read(int16_t *pcm, size_t frames, int wait_ms);` | |
| `size_t rabble_beam_turn_audio_wait(const int16_t *pcm, size_t frames, int wait_ms);` | |
| `void rabble_beam_text_turn(char *text);` | |
| `void rabble_beam_text_cancel(void);` | |
| `void rabble_beam_console(const char *type, const char *text, const char *fields, ...) __attribute__((format(printf, 3, 4)));` | The format attribute is required: callers pass printf-style fields and the build treats format mismatches as errors. |
| `size_t rabble_beam_unescape(char *s);` | |

Total: 2 enums, 1 struct, 19 functions (including the variadic `rabble_beam_console`).

Header comment text is yours. The contracts of the session and text functions are in their own code and in `RaBbLE-Pocket-Beam-Protocol.md`; this spec only freezes the declarations.

### 2.2 `rabble_beam_priv.h`

Includes: `<stddef.h>`, `<stdint.h>`, `<string.h>` and `"rabble_beam.h"` (in that spirit: the existing session and text sources rely on getting the `string.h` functions and `bool` through this header). `extern "C"` guards required.

| Item | Exact declaration |
|---|---|
| `bool rabble_beam_configured(void);` | |
| `void rabble_beam_report(rabble_beam_state_t state, const char *detail);` | |
| `void rabble_beam_session_connect(void);` | |
| `void rabble_beam_session_forget(void);` | |
| `void rabble_beam_tail_words(const char *src, char *out, size_t cap);` | |
| `bool rabble_beam_caption_at(const char *text, size_t at, char *out, size_t cap);` | |

Total: 6 functions, no types. The existing `accord/rabble_beam_text.h` repeats four prototypes (`tail_words`, `caption_at`, `console`, `unescape`) with the same signatures; the new headers must keep them identical (C permits the repetition), including the `format(printf, 3, 4)` attribute on `console`.

### 2.3 Who implements what

The implementer writes only the **new `rabble_beam.c`** column; everything else already exists and links as is.

| Prototype | Header | Implemented in |
|---|---|---|
| `rabble_beam_status` | public | **new `rabble_beam.c`** |
| `rabble_beam_test` | public | **new `rabble_beam.c`** |
| `rabble_beam_config_changed` | public | **new `rabble_beam.c`** |
| `rabble_beam_state_name` | public | **new `rabble_beam.c`** |
| `rabble_beam_configured` | priv | **new `rabble_beam.c`** |
| `rabble_beam_report` | priv | **new `rabble_beam.c`** |
| `rabble_beam_start` | public | `accord/rabble_beam_score.c` |
| `rabble_beam_set_resting` | public | `accord/rabble_beam_score.c` |
| `rabble_beam_ready` | public | `accord/rabble_beam_score.c` |
| `rabble_beam_turn_begin`, `_turn_audio`, `_turn_end`, `_turn_cancel`, `_turn_event`, `_turn_caption`, `_turn_read`, `_turn_audio_wait` | public | `accord/rabble_beam_score.c` |
| `rabble_beam_text_turn`, `rabble_beam_text_cancel` | public | `accord/rabble_beam_score.c` |
| `rabble_beam_session_connect`, `rabble_beam_session_forget` | priv | `accord/rabble_beam_score.c` |
| `rabble_beam_console`, `rabble_beam_unescape` | public | `accord/rabble_beam_text.c` |
| `rabble_beam_tail_words`, `rabble_beam_caption_at` | priv | `accord/rabble_beam_text.c` |

So `rabble_beam.c` provides exactly six functions: `status`, `test`, `config_changed`, `state_name`, `configured`, `report`. It must not define any of the other prototypes (duplicate symbols), and it must not define any extra non-static symbol that starts with `rabble_beam_`.

### 2.4 Callers (grep over `firmware/components` and `firmware/main`)

| Caller | Uses |
|---|---|
| `accord/rabble_beam_score.c` (session task, own task) | `rabble_beam_report` from its own task: `REACHABLE` with the server's name (or `Connected`), `TESTING` `Connecting...`, `UNREACHABLE` with `Bad address`, `Can't connect`, `Connection lost`, `UNTESTED` `Connects when you talk`, `REACHABLE` `Connected`; `rabble_beam_configured` from its loop on every pass (about every 20 to 500 ms). |
| `accord/rabble_app.c` | `rabble_beam_start()` once at boot; `rabble_beam_config_changed()` from the settings change callback when the URL or token changed (`RABBLE_SETTING_BEAM`). That callback runs on whichever task made the change (settings page on the LVGL task, console `>beam.url=` on the serial task). |
| `accord/rabble_setup.c` | `rabble_beam_test()` for the `beam.test` command; `rabble_beam_status` and `rabble_beam_state_name` for the `state` member of the `beam` object in the status JSON (name string only; detail unused). Serial task. |
| `apache/rabble_settings_ui.c` | Test connection button calls `rabble_beam_test()` (LVGL task); the sCoRE page polls `rabble_beam_status` and shows `state_name`, a newline, then `detail`, coloured by REACHABLE / UNREACHABLE / other; the home page polls and shows `state_name` only. |
| `accord/rabble_ui.c`, `accord/rabble_entity.c` | poll `rabble_beam_status` from the LVGL task about every frame-ish tick (several times a second) and colour the sCoRE indicator: REACHABLE magenta, TESTING yellow, UNREACHABLE red, anything else muted. Only `state` is used. |
| `apache/rabble_voice.c` (W4 replaces it) | `rabble_beam_status` when a press cannot go to sCoRE: NOT_SET shows `SET UP sCoRE FIRST`, OFFLINE shows `NO WI-FI`, anything else `CAN'T REACH sCoRE`; and to refuse a press with NOT_SET. Plus the session API (`ready`, `turn_*`, `set_resting`), which are not this module's. |
| `accord/rabble_input.c` | `rabble_beam_console`, `rabble_beam_unescape`, `rabble_beam_text_turn`, `rabble_beam_text_cancel` (not this module's). |
| `accord/rabble_beam_text.c` | implements the helpers; includes `rabble_beam_text.h`. |

Because of these callers, `rabble_beam_status` is on hot polling paths. It must be cheap: no flash/NVS access, no logging, no blocking beyond a very short critical section, no allocation.

## 3. Dependencies of this module

| Callee | Calls | Expectation |
|---|---|---|
| settings (`rabble_settings.h`) | `rabble_settings_beam_url(char out[RABBLE_BEAM_URL_MAX + 1])`; `RABBLE_BEAM_URL_MAX` is 127 | Copies the stored URL, empty string when unset. Thread-safe, cheap (RAM copy). |
| wifi (`rabble_wifi.h`) | `rabble_wifi_connected()` | True when Wi-Fi has an IP. Thread-safe. |
| session task | `rabble_beam_session_connect()`, `rabble_beam_session_forget()` | Both only post a request to the session task and return; safe from any task; neither reports status itself synchronously. |
| FreeRTOS | whatever synchronisation you choose for the shared result (see 7) | Must be short and non-blocking; never held across a call into another module. |

## 4. Status model

### 4.1 The reported result

The module keeps one shared **result**: a state and a detail text, set by `rabble_beam_report` (session task, or this module itself). At boot it is state `RABBLE_BEAM_UNTESTED` with an empty detail. The detail is at most 47 characters plus the terminator (the `detail` field is 48 bytes): a longer text is cut to its first 47 bytes (a byte cut, no ellipsis, no attention to UTF-8). A NULL detail must be treated as empty. The state passed to `report` is stored as given (any of the six; callers use only TESTING, REACHABLE, UNREACHABLE and UNTESTED).

`rabble_beam_report` does no logging, does not notify anyone, and does not look at settings or Wi-Fi.

### 4.2 `rabble_beam_configured()`

True exactly when the stored sCoRE URL is non-empty (first character not NUL). The token is irrelevant (an empty token is allowed: a LAN sCoRE in dev mode). Reads settings every call; changes apply live.

### 4.3 `rabble_beam_status(out)`

Fills `out` (non-NULL; both fields always written, `detail` always NUL-terminated). The decision, in this order:

| # | Condition | Result state | Result detail |
|---|---|---|---|
| 1 | URL not set | `NOT_SET` | `Set the sCoRE URL` |
| 2 | URL set, Wi-Fi not connected, and the reported state is not `TESTING` | `OFFLINE` | `Waiting for Wi-Fi` |
| 3 | URL set, reported state `UNTESTED`, reported detail empty, and (Wi-Fi connected) | `UNTESTED` | `Connects when you talk` |
| 4 | otherwise | the reported state | the reported detail, as stored |

Notes that are requirements:

- Row 1 wins over everything, including a reported REACHABLE or TESTING: clearing the URL immediately reads NOT_SET even before the session task has reacted.
- Row 2 hides any reported state except TESTING while Wi-Fi is down, REACHABLE and UNREACHABLE included. A reported TESTING stays TESTING while Wi-Fi is down (it is not turned into OFFLINE).
- Row 3 supplies the default wording only when the reported detail is empty. An UNTESTED report that carries its own detail (the session task reports `Connects when you talk` itself when it lets an idle socket go) shows that detail unchanged.
- Row 4 passes UNTESTED with any non-empty detail, TESTING, REACHABLE and UNREACHABLE (Wi-Fi up) through unchanged, with empty details too (a REACHABLE with an empty detail shows an empty detail; no default is invented).
- The status is derived on every call; nothing is cached, so Wi-Fi coming and going and URL edits show on the next call.
- The state never becomes `NOT_SET` or `OFFLINE` in the stored result; those two are only ever derived.

## 5. `rabble_beam_state_name(state)`

Returns a pointer to a static, constant, NUL-terminated string (never NULL, never freed, valid forever, safe from any task):

| State | String (exact, including capitalisation and the apostrophe, which is the ASCII `'`) |
|---|---|
| `RABBLE_BEAM_NOT_SET` | `Not set up` |
| `RABBLE_BEAM_OFFLINE` | `Offline` |
| `RABBLE_BEAM_UNTESTED` | `Saved` |
| `RABBLE_BEAM_TESTING` | `Connecting` |
| `RABBLE_BEAM_REACHABLE` | `Connected` |
| `RABBLE_BEAM_UNREACHABLE` | `Can't connect` |
| any other value | the empty string `""` |

These strings show on the settings page, the home page and as the `state` field of the `beam` object in the serial status JSON (`@status`), so they are user-visible and scripted against.

## 6. `rabble_beam_test()`, `rabble_beam_config_changed()`

### 6.1 `rabble_beam_test()`

"Test connection". Callable from any task; returns immediately.

1. If no URL is set, or Wi-Fi is not connected: do nothing at all (no result change, no request to the session task). The status keeps showing `Set the sCoRE URL` or the Wi-Fi-derived state.
2. Otherwise: record the result as TESTING with detail `Connecting...` (see 4.1), then ask the session task to (re)connect now (`rabble_beam_session_connect`). In that order: the status read right after `test` returns already says TESTING / `Connecting...`.

The test's outcome arrives later as the session task's own reports (4.1).

### 6.2 `rabble_beam_config_changed()`

Called when the URL or token changed. Callable from any task; returns immediately.

1. Record the result as UNTESTED with an empty detail (forget the last result).
2. Ask the session task to drop the connection (`rabble_beam_session_forget`). Order: result first, then the request.

Always does both, regardless of whether a URL is set or Wi-Fi is up. After it, the status reads `Connects when you talk` (URL set, Wi-Fi up), `Waiting for Wi-Fi` (URL set, Wi-Fi down) or `Set the sCoRE URL` (no URL).

## 7. Thread safety

- `report`, `status`, `test`, `config_changed`, `configured` and `state_name` are callable from any task concurrently (session task, LVGL task, serial task, voice task, settings callbacks).
- A `status` call returns a consistent pair: the state and detail it returns come from one `report` call, never half of one and half of another.
- Not callable from an ISR.
- `report` and `status` hold their shared data only for the copy itself; neither may call into the settings module, Wi-Fi, or the session task while holding it.
- No call blocks on the network or on the session task.

## 8. Limits and edge cases (collected)

| Case | Required behaviour |
|---|---|
| Detail longer than 47 bytes | Truncated to 47 bytes. |
| Detail empty with state other than UNTESTED | Passed through empty. |
| URL cleared while REACHABLE | NOT_SET immediately. |
| URL set, Wi-Fi drops while REACHABLE | OFFLINE / `Waiting for Wi-Fi`; when Wi-Fi returns, REACHABLE with its stored detail again (until the session task reports otherwise). |
| `test` with Wi-Fi down | No effect (no TESTING). A TESTING already stored stays visible. |
| `test` with no URL | No effect. |
| `config_changed` with no URL | Result reset and forget request still happen. |
| `state_name` with out-of-range value | `""`. |
| Two `report` calls in a row | Last wins. |
| `status` before the first `report` ever | URL set and Wi-Fi up: UNTESTED / `Connects when you talk`. |

## 9. Device behaviour checklist (integrator)

Serial checks run over `/dev/ttyACM0`; `>status` prints `@status {...}` with `"beam":{"url":...,"token":...,"state":"<state name>"}`. "Page" checks need Mark's eyes (settings page, sCoRE sub-page; home page row `sCoRE`; the status-bar/entity `sCoRE` indicator colour).

1. **URL unset, Wi-Fi off or on:** `>beam.url=` (empty). Settings sCoRE page shows `Not set up` and `Set the sCoRE URL` (muted colour); home page shows `Not set up`; `@status` has `"state":"Not set up"`; the indicator is muted. A voice press shows `SET UP sCoRE FIRST`. Same with Wi-Fi off. `>beam.test` does nothing (no `Connecting` flash).
2. **URL set, Wi-Fi off:** set `>beam.url=ws://<host>:8000/api/v1/beam` with Wi-Fi off (setting `wifi=off` per the W1 setup commands): page shows `Offline` and `Waiting for Wi-Fi`; `@status` says `Offline`; a voice press shows `NO WI-FI`; Test connection does nothing.
3. **URL set, Wi-Fi on, sCoRE reachable:** after Wi-Fi joins, within a few seconds the page goes `Connecting` / `Connecting...` (yellow) then `Connected` with sCoRE's name (or `Connected`) (magenta indicator); `@status` says `Connected`. Test connection while connected: record what shows (see open question 1).
4. **sCoRE unreachable** (stop the server, or point at a closed port): Test connection shows `Connecting` / `Connecting...` then within about 8 s `Can't connect` with detail `Can't connect` (red indicator); `@status` says `Can't connect`. Garbage URL that cannot be parsed shows `Can't connect` / `Bad address`. A previously connected socket that drops shows `Connection lost`.
5. **Config change:** with the page on `Connected`, change the URL (`>beam.url=...` or the page): the status immediately drops to `Saved` / `Connects when you talk` (or `Connecting` once the session task retries), never keeps the old `Connected`. Changing only the token does the same.
6. **A voice turn:** with `Connected`, hold talk, release: status stays `Connected` through the turn; after 2 minutes asleep and resting the page reads `Saved` / `Connects when you talk` and returns to `Connected` on waking.
7. Wi-Fi drop mid-session (turn Wi-Fi off from the page): the page flips to `Offline` / `Waiting for Wi-Fi` at the next page refresh; turn it back on: `Connecting`, then `Connected`.
8. `@status` is one line and the `beam` object's `state` value is always one of the six strings of section 5.

## 10. Test vehicle and golden vectors

The logic is small but has enough branches (URL x Wi-Fi x reported state x detail, truncation, the test and config-change interplay) to pin. `w3-beam-vectors/status.tsv` (204 rows; README there gives the format) holds the exact status results.

**Test seam (behaviour level):** the implementer's host test builds `rabble_beam.c` on its own against fakes for: the stored URL (a string the test sets), the Wi-Fi-connected flag (a bool the test sets), whatever synchronisation primitive you use (fake it as a no-op), and the two session requests (`rabble_beam_session_connect`, `rabble_beam_session_forget`: each appends its name to a trace). It then drives the six public functions with the vectors' op vocabulary (`url=`, `wifi=`, `report=`, `cfg`, `test`, `status`, `name=`) and writes the trace in the README's format. All rows must match byte for byte. `rabble_beam.c` must therefore compile on the host with only `rabble_beam_priv.h`, `rabble_settings.h` (for `RABBLE_BEAM_URL_MAX` and the URL getter), `rabble_wifi.h` (for the connected flag) and whatever FreeRTOS header your synchronisation needs; if it uses other headers, the fakes must cover them.

## 11. Ambiguities and decisions for the integrator

1. **Test while already connected looks stuck.** `rabble_beam_test()` with a live connection sets the result to `Connecting...` and asks for a connect, but the existing session task does not send a fresh report when the socket is already up and already greeted, so the status can stay on `Connecting` / `Connecting...` until the next real event (a drop, resting close, config change). This is how the status side and session task interact today. The spec keeps the status side as specified (the vectors pin it). A fix belongs in `rabble_beam_score.c` (report `Connected` again when a connect request finds the link up) and is the integrator's call; do not work around it in `rabble_beam.c`.
2. **Detail wording of UNREACHABLE.** Details come from the session task (`Can't connect`, `Connection lost`, `Bad address`); this module shows them verbatim. If the session task is later changed, the checklist strings change with it.
3. **`rabble_beam_start` comment drift.** Its public contract (create the session task, connect once Wi-Fi is up) belongs to the session task and is out of scope here.
4. **Header comment text** is free; only declarations are frozen.
