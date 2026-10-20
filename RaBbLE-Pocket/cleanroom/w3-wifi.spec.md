# W3 spec: rabble_wifi (Wi-Fi station: saved-network joining, reconnect, scans, power)

> Clean-room spec, wave W3. Author role: S (Sonnet 5.5 sub-agent, S259). Firewall: S259 parent (Opus 5.5), approved after rewriting the start-up call sequence and the pass step list as requirements, removing the radio teardown retry mechanics and a working-buffer size, freeing the radio-layer log tags, and dropping the unused merge facility. Files to be replaced: `apache/rabble_wifi.c/.h` and `apache/rabble_wifi_mgr.c/.h`. New files go under `accord/` with the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else. Only `rabble_wifi.h` is a contract; how the implementer splits the radio driving from the keeper logic is theirs. The saved-network store is `w3-wifi-store.spec.md` (header `rabble_wifi_known.h`, section 2.1 there lists how this module calls it; the two specs agree). Golden vectors: `w3-wifi-vectors/` (sections 14 and 15).

Treatment: clean room. Everything below is a requirement. Numbers are behaviour values.

---

## 1. Purpose

The device's single Wi-Fi station. It remembers up to 8 networks (through the store), joins one while Wi-Fi is switched on in settings, reconnects after losses with a backoff, looks for saved networks less often when none are around, runs scans for the settings screen, offers three power levels and a nap, and reports a status the UI polls. Nothing here talks to the beam: the beam polls `rabble_wifi_connected()` and reacts to it going false or true on its own.

## 2. Public interface (complete and frozen)

Header `rabble_wifi.h`, `#pragma once`. It must include `<stdbool.h>`, `<stdint.h>`, `"esp_err.h"`, `"rabble_settings.h"` (for `RABBLE_SSID_MAX` = 32). `extern "C"` guards allowed.

| Name | Kind | Contract |
|---|---|---|
| `rabble_wifi_state_t` | enum, in this order (values 0..5) | `RABBLE_WIFI_OFF`, `RABBLE_WIFI_NO_NETWORK`, `RABBLE_WIFI_CONNECTING`, `RABBLE_WIFI_CONNECTED`, `RABBLE_WIFI_FAILED`, `RABBLE_WIFI_NOT_NEARBY`. Callers index a six-entry table by value, so the order is binding. |
| `rabble_wifi_status_t` | struct, in this order | `rabble_wifi_state_t state;` `char ssid[RABBLE_SSID_MAX + 1];` `char ip[16];` `int rssi;` `char detail[40];` |
| `rabble_wifi_ap_t` | struct, in this order | `char ssid[RABBLE_SSID_MAX + 1];` `int8_t rssi;` `bool secure;` |
| `RABBLE_WIFI_SAVED_MAX` | macro | `8` |
| `rabble_wifi_saved_t` | struct, in this order | `char ssid[RABBLE_SSID_MAX + 1];` `bool hidden;` |
| `rabble_wifi_power_t` | enum, in this order | `RABBLE_WIFI_FULL`, `RABBLE_WIFI_DOZE`, `RABBLE_WIFI_REST` |
| `esp_err_t rabble_wifi_start(void)` | function | Section 4. |
| `void rabble_wifi_apply(void)` | function | Section 6. |
| `void rabble_wifi_join(const char *ssid, const char *pass)` | function | Section 8. |
| `void rabble_wifi_status(rabble_wifi_status_t *out)` | function | Section 9. |
| `bool rabble_wifi_connected(void)` | function | True while the station is associated and holds an IP address. |
| `void rabble_wifi_power(rabble_wifi_power_t level)` | function | Section 12. |
| `void rabble_wifi_nap(bool nap)` | function | Section 11. |
| `esp_err_t rabble_wifi_scan(void)` | function | Section 10. |
| `bool rabble_wifi_scanning(void)` | function | True from a successful `rabble_wifi_scan()` until its results are published (or it gave up). |
| `int rabble_wifi_scan_results(rabble_wifi_ap_t *out, int max, uint32_t *gen)` | function | Section 10. |
| `int rabble_wifi_saved(rabble_wifi_saved_t *out, int max)` | function | Copies up to `max` saved networks, most recently joined first, ssid and hidden flag only; returns the count copied. The list is a snapshot refreshed by the station at its start and after each change it makes to the store (so it can lag a call by the time the station takes to react). |
| `void rabble_wifi_forget(const char *ssid)` | function | Section 8. |

All functions are safe from any task and never block on the radio or on flash: they record the request and return. `rabble_wifi_connected`, `status`, `saved`, `scan_results` and `scanning` are cheap enough to call from the UI task every frame. Before `rabble_wifi_start()` has run: `connected` is false, `saved` and `scan_results` return 0, `scanning` false, `scan` returns `ESP_ERR_INVALID_STATE`, `apply`, `join`, `forget`, `nap` and `power` have no effect (the nap and power requests made before start are dropped, not remembered), and `status` is not exercised by any caller.

## 3. Callers (contract each relies on)

| Caller | Calls | Relies on |
|---|---|---|
| `accord/rabble_app.c` | `start` (last of the bring-up, after voice, before the beam starts; fatal on error), `apply` on the Wi-Fi setting change | start is idempotent-safe and fast; apply re-reads settings |
| `accord/rabble_setup.c` | `join(ssid, pass)` (after turning the Wi-Fi setting on; pass may be empty), `forget(value)` (value may be empty meaning all), `status` for the JSON `wifi` object (state name, ssid, ip, rssi) | state names map one to one to the enum; ssid is the joined or first-saved network |
| `apache/rabble_settings_ui.c` | `scan`, `scanning`, `scan_results(…, MAX_APS, &gen)`, `saved`, `join`, `forget`, `apply`, `status` | gen 0 means never scanned (the UI then shows no "no networks" note); gen changes exactly when new results are published; after a scan lists a saved network while status is NOT_NEARBY the UI calls `apply` to join now |
| `accord/rabble_ui.c`, `accord/rabble_entity.c` | `status` | state colours: CONNECTED, CONNECTING, FAILED distinct; all others muted |
| `apache/rabble_settings_ui.c` home row | `status` | value text for the state; ssid when CONNECTED |
| `apache/rabble_voice.c` | `connected`, `apply` (on every press that finds Wi-Fi down: "retry now"), `power(FULL/DOZE/REST)` | apply is cheap to spam; it never blocks |
| `accord/rabble_input.c` | `connected`, `apply` (on wake with Wi-Fi down), `nap(true/false)` | nap(false) rejoins at once |
| `apache/rabble_beam.c`, `accord/rabble_beam_score.c` | `connected` | goes false when the station leaves the network for any reason, including nap |

The module makes no `rabble_beam_*` calls. It reads `rabble_state_asleep()` (only to choose retry delays, section 7.3) and `rabble_settings_wifi_on()` (section 5). It calls the store for everything saved (section 13).

## 4. Start-up

`rabble_wifi_start()`, called once after `nvs_flash_init()` has succeeded:

1. If already started, return `ESP_OK` and do nothing.
2. Prepare the store (`rabble_wifi_known_init()`).
3. Bring the radio up before the keeper starts. Any failure here is fatal (abort). Requirements on the result: the default event loop and a default station network interface exist (the interface is used for the IP in status); the driver keeps its configuration in RAM only and never persists credentials (the build also sets `CONFIG_ESP_WIFI_NVS_ENABLED=n`); station mode; regulatory country `US` with channels 1 to 13 and the manual country policy; on a target with 5 GHz support (`SOC_WIFI_SUPPORT_5G`) the band mode is automatic; power save off (`WIFI_PS_NONE`); the station receives every Wi-Fi event and the got-IP event. Log the station MAC once at info as `WIFI STA MAC: AA:BB:CC:DD:EE:FF` (upper-case hex), or a warning if it cannot be read.
4. Create the keeper task: name `rabble_wifi`, **stack 6144 bytes from internal RAM** (plain `xTaskCreate`; the task reads and writes NVS through the store, which must not run on a PSRAM stack), **priority 4**, **not pinned** (`xTaskCreate`, no core). Per the W0 seam rules the UI and voice run on `RABBLE_UI_CORE`/`RABBLE_AUDIO_CORE` at priorities 5 and 6; the station must stay below them and must not be pinned to that core. If the task cannot be created return `ESP_ERR_NO_MEM`.
5. The keeper keeps its working state off its own stack (heap). If it cannot get that memory: log error `no memory for the saved networks` (tag `rabble_wifi`) and end the task (Wi-Fi then never joins). Otherwise it loads the saved list (publishing the snapshot for `rabble_wifi_saved`) and enters its pass loop (section 7).

The radio stays started and in station mode for the life of the process. It is never switched off by the Wi-Fi setting or nap; "off" means disassociated, not powered down.

## 5. On/off

The setting is read with `rabble_settings_wifi_on()` at the top of each keeper pass and in `status`. Switching it does not notify the station by itself; the app calls `rabble_wifi_apply()` on the setting-changed event (section 6), and the keeper also notices by itself within one pass period (1 s, section 7.1). When Wi-Fi is off, or when nothing is saved, the keeper leaves any current association (section 7.2) and attempts nothing.

## 6. apply()

`rabble_wifi_apply()` asks the keeper to re-evaluate right now: it wakes the keeper immediately, and the keeper resets the reconnect schedules (the next attempt may start at once, the failure backoff and the not-nearby backoff start over, sections 7.3 and 7.4). It does not disturb a connected link and does not clear the "chosen network" mark (8.3). If a join pass is already running, the reset applies when that pass ends (so a failed attempt is followed immediately by another).

## 7. The keeper loop

### 7.1 Pass structure and period

The keeper does one **pass** per wake-up. It sleeps until a request arrives (join, forget, apply, nap change) or 1000 ms have passed since the end of its previous pass, whichever is first; while napping (section 11) and nothing else is pending it sleeps without a timeout. The "due" time of a retry (below) is compared at the start of a pass, so an attempt starts at the first pass at or after its due time. Vectors replay this timing exactly; keep the 1000 ms period measured from the end of each pass (blocking joins and scans are inside a pass). Requests that arrive while a pass is running are acted on by the next pass, which starts immediately.

Rules for a pass:
- A pending join (8.1) and a pending forget (8.2) are both handled in the pass that sees them, the join before the forget, and both before the decision below.
- Any request (join, forget, apply, a nap change in either direction) resets the retry schedule: the next attempt is due now, the failure delay is back to 5 s and the not-nearby delay back to 30 s. A pass started by the plain 1 s timeout does not reset it.
- The pass then decides, in this precedence:
   a. Wi-Fi off, or nothing saved: if currently connected, log `wifi off; disconnecting` (when something is saved) or `wifi forgotten; disconnecting` (when nothing is saved), at info, tag `rabble_wifi`, and disconnect. Clear the not-nearby mark. Nothing else.
   b. Nap requested: if the station has not yet left for this nap, log info `screen off a while; left wifi`, disconnect (even if not connected), and remember it has left. Nothing else; the not-nearby mark and detail are left as they were.
   c. Connected: reset both delays to their minimums; clear the not-nearby mark.
   d. Not connected and the retry is due: run a join attempt (7.2).
   e. Otherwise nothing.
   If a nap request was cancelled (nap(false)) the "left for this nap" memory is cleared so a later nap logs and disconnects again.

### 7.2 Join attempt

While an attempt runs the station is "joining" (blocks `rabble_wifi_scan`, section 10). The attempt takes one of two forms:

- **Chosen network** (the user just joined something, 8.3): connect to the first saved network only, with no scan first. Log info `joining <ssid>`. Success is JOINED, failure is FAILED (no other network is tried).
- **Any saved network** (everything else: boot, reconnect after a drop, apply, nap end, after forget): run one scan of all channels (the station's own scan: collapsed per SSID, at most 25 entries, section 15.1) and keep its result as the "nearby" memory, replacing the previous memory when the scan found at least one network and **leaving the old memory untouched when it found none or did not run**. Then go through the saved list in saved order. A saved network is tried when it is flagged hidden **or** its SSID is in the nearby memory (stale entries count); others are skipped. For each one tried log info `joining saved network <ssid>` and connect; the first success ends the attempt as JOINED; failures go on to the next. If at least one was tried and none joined: FAILED. If none was tried: NOT_NEARBY.

Connect timeout is 20000 ms per network (the whole blocking join, including waiting for the radio). The radio-level behaviour of one connect is section 15.2.

After a JOINED attempt:
- Clear the failure detail and the not-nearby mark; reset both delays to minimum.
- If the joined network is not first in the saved list (found by the associated AP's SSID among entries 2 and up), call `rabble_wifi_known_remember(ssid, password, -1)` for it (moves it to the front, keeps flag and password) and refresh the snapshot. A network that is already first causes no store call.

After FAILED: detail becomes `Can't join; retrying`; not-nearby mark cleared; the next attempt is due `delay` after the attempt **ended**, where `delay` is the current failure delay when the screen is asleep (`rabble_state_asleep()` read when the attempt ends) and `min(failure delay, 15 s)` when awake; then the failure delay doubles, capped at 60 s. Failure delays start at 5 s: awake 5, 10, 15, 15, ...; asleep 5, 10, 20, 40, 60, 60, ...

After NOT_NEARBY: detail becomes `No saved network nearby`; not-nearby mark set; next attempt due `delay` after the attempt ended, where `delay` is the current not-nearby delay when asleep and `min(delay, 60 s)` when awake; then it doubles, capped at 600 s. Starts at 30 s: awake 30, 60, 60, ...; asleep 30, 60, 120, 240, 480, 600, 600, ... Log info `no saved wifi network nearby; looking again in <N> s` with N the delay used, in whole seconds.

The two delays are independent and each resets as stated (success, connected pass, apply, join, forget, nap change).

An unexpected loss of the link (the access point goes away, the router reboots) is just "not connected" to the keeper: the next pass (within 1 s) starts a join attempt in the "any saved network" form, and failures follow the schedule above. The implementation need not rely on, and must not run alongside, any radio-level automatic reconnect that would race the keeper (the radio manager must not restart associations on its own after the keeper has taken over).

### 7.3 Detail strings (exact)

The keeper's stored detail is one of: empty, `Can't join; retrying`, `No saved network nearby`. `status` adds `Joining...` (section 9). No other detail text is ever produced. There is no distinct "wrong password" text: a wrong password, a refused association and a timeout are all FAILED with `Can't join; retrying`.

### 7.4 FAILED conditions

FAILED is reported when a join attempt of any form ended without association and at least one network was tried (wrong password, auth refused, DHCP never answered, 20 s timeout, driver refused to start the connection), and no new attempt has begun. While the next attempt runs the status shows CONNECTING again; between attempts it shows FAILED. The station never gives up for good: FAILED always keeps retrying on the schedule above ("gave up" in the header comment means "this attempt").

## 8. Saved networks: join, forget, choice

### 8.1 join(ssid, pass)

`rabble_wifi_join` ignores an empty or NULL ssid. Otherwise it stores the request (ssid up to 32 bytes, pass up to 64, NULL pass = empty), clears the failure detail and the not-nearby mark immediately (so the very next `status` no longer shows the old failure), and wakes the keeper. There is one request slot: a second join before the keeper has taken the first replaces it.

Handling in the keeper:
1. Take the request and clear its password from the slot.
2. Decide the hidden flag: 0 if the ssid is in the **settings screen's latest scan results** (section 10) (it was picked from a list, so it broadcasts), else 1 (typed in).
3. Call `rabble_wifi_known_remember(ssid, pass, hidden)`. If it returns false log warn `couldn't save <ssid>`; processing continues anyway with whatever list the store now holds.
4. Wipe local password copies (`rabble_wifi_known_wipe`), reload the list and snapshot.
5. If connected and not to this ssid (compare with the associated AP's ssid): log info `joining a different network` and disconnect. If already connected to this ssid nothing else happens: the password is saved but the link is untouched.
6. Clear the failure detail; mark "chosen network" (8.3); treat as a request wake (reset schedules).

### 8.2 forget(ssid)

NULL or empty means all. One request slot, same overwrite rule. Handling: call `rabble_wifi_known_forget(ssid)` (or `..._forget_all()`); on false log warn `couldn't forget a wifi network`. If connected and (all, or the ssid equals the associated AP's ssid): log info `forgot the network in use; leaving it` and disconnect. Wipe, reload, refresh the snapshot, treat as a request wake. After forgetting the one in use with others saved, the next pass joins another saved network at once (form "any saved network"); with none left status becomes NO_NETWORK and nothing is attempted. Forgetting a network that is not saved changes nothing (the store call still happens).

### 8.3 Which saved network is chosen when

- Right after `join`: only the just-saved network (now first), no scan, no fallback: the "chosen" mark makes the next attempt use the chosen form once. The mark is cleared when that attempt runs (not before: if Wi-Fi is off at that moment it persists until an attempt happens). Forget does not clear it.
- Any other time: the first saved network in saved order that is hidden or seen in the nearby memory (7.2).
- Saved order is most-recently-joined first and is maintained by the store; after a successful join of a lower entry, that entry moves first (7.2).

## 9. status()

`rabble_wifi_status(out)` first zeroes `*out`, then fills it. `ssid` defaults to the first saved network's name (empty if none saved), `detail` defaults to the keeper's stored detail. State is the first matching row:

| # | Condition | state | ssid | ip, rssi | detail |
|---|---|---|---|---|---|
| 1 | Associated with an IP | CONNECTED | the associated AP's ssid (default if empty) | `ip` dotted decimal `a.b.c.d` (left empty if unavailable), `rssi` of the AP in dBm (0 if unavailable) | empty |
| 2 | Wi-Fi setting off | OFF | default | zero | empty |
| 3 | A blocking connect is in progress | CONNECTING | the network being connected | zero | `Joining...` |
| 4 | Nothing saved | NO_NETWORK | default (empty) | zero | not specified (callers ignore it; vectors ignore it) |
| 5 | Not-nearby mark set | NOT_NEARBY | default | zero | stored detail (`No saved network nearby`) |
| 6 | Stored detail non-empty and no attempt (including its pre-join scan) is running | FAILED | default | zero | stored detail |
| 7 | Anything else | CONNECTING | default | zero | `Joining...` |

Notes that follow from the table: row 1 beats row 2, so for up to one pass after switching Wi-Fi off a connected link still reports CONNECTED. During the pre-join scan of an attempt (before the blocking connect) the status is row 5, 6 or 7 depending on the previous outcome; a stale not-nearby mark shows NOT_NEARBY during that scan. While napping and disassociated the status follows rows 5 to 7 on what was stored before the nap (after a normal connection that is row 7: CONNECTING, `Joining...`). Status is a pure read: it triggers nothing.

## 10. Scans for the settings screen

`rabble_wifi_scan()` returns:
- `ESP_ERR_INVALID_STATE` if not started, or if a join attempt is in progress (including its pre-join scan). It does not matter whether Wi-Fi is on, off, connected or napping otherwise.
- `ESP_OK` without starting another if one is already running.
- `ESP_ERR_NO_MEM` if its task cannot be created.
- Otherwise `ESP_OK`, `rabble_wifi_scanning()` becomes true and a short-lived task (name `rabble_scan`, stack 4096, priority 4, internal RAM, may be unpinned) runs one active all-channel scan, collapsing per SSID and keeping at most **16** entries (rules in section 15.1; hidden and blank SSIDs dropped; strongest first).

When the scan completes (the radio reported a result, even an empty one): the published results are **replaced** by the new list, the generation counter increases by one, and an info log `scan found <N> networks` (tag `rabble_wifi`) is written. `secure` is true when the strongest-or-any record's auth mode is not open (the collapse rule in 15.1 already folds "any secured BSSID" into the entry). When the scan did not run (another scan or a connect had the radio): log info `no scan; the radio was busy`, results and counter unchanged. In both cases `scanning()` becomes false. The generation counter starts at 0 and is not reset. A connect always takes priority over a scan: a join attempt cancels a scan in progress, and a scan requested while a connect is pending is skipped (the "radio was busy" case).

`rabble_wifi_scan_results(out, max, gen)` copies `min(count, max)` entries, strongest first, and always sets `*gen`. The same published results define "seen in the last scan" for the hidden flag in 8.1. The station's own pre-join scan (7.2) does not change the published results or the counter.

The published results and the nearby memory are both replace-on-scan as above; nothing merges scans.

## 11. nap(bool)

`rabble_wifi_nap(true)` asks the station to leave Wi-Fi: the keeper (7.1 step 4b) disconnects, logs `screen off a while; left wifi`, and then sleeps without polling. `connected()` becomes false, so the beam drops its session on its own. Nothing is attempted while napping, even if the link was already down, and a retry due time passing has no effect. `rabble_wifi_nap(false)` wakes the keeper, resets the retry schedules, and the next pass rejoins at once in the "any saved network" form (scan, then connect), so waking costs the scan time plus the connect time. `apply` while napping changes nothing. Nap does nothing visible when Wi-Fi is off or nothing is saved (the 4a rule wins). Radio power-save settings are not changed by nap.

## 12. Power levels

`rabble_wifi_power(level)`:
- Ignored before start. A call equal to the level last applied does nothing (the initial applied level is FULL, so a first call with FULL does nothing).
- FULL maps to `WIFI_PS_NONE`; DOZE to `WIFI_PS_MIN_MODEM` (the radio wakes for every DTIM beacon: a few hundred ms extra latency); REST to `WIFI_PS_MAX_MODEM`.
- The listen interval used in every association is 10 beacons (about 1 s at the usual 102.4 ms interval) and takes effect in MAX_MODEM only; it is set in the connect configuration (15.2), not by the power call.
- The setting persists across disconnects, nap and rejoin; the station does not reapply it. Start-up sets `WIFI_PS_NONE`.

## 13. Store interface used (consistent with `w3-wifi-store.spec.md` 2.1)

`init` once at start; `load` at keeper start and after every change; `remember(ssid, pass, 1|0)` on join; `remember(ssid, pass, -1)` to move a joined lower entry first; `forget(ssid)` and `forget_all()`; `wipe(list)` after each use of a list holding passwords. NVS is touched only through the store and only from the keeper task. Saved networks therefore survive the module swap as long as the store keeps its key formats. The station neither reads nor writes the NVS key `wifi_channel`; only the store erases it, as legacy data. There is no channel hint of any kind: connection speed-ups come only from the scan-derived pinning in 15.2.

## 14. Test seam for the keeper (vectors: station scenarios)

The keeper logic must run on host in virtual time against: a fake store with the semantics of `w3-wifi-store.spec.md` (list, move-to-front, cap 8, hidden -1 keeps); a fake radio providing connect (scripted outcomes with durations, 20000 default failure), "own scan" (instant list from `air`, takes `scan_ms`, "did not run" when busy), the settings scan (instant), disconnect, associated-AP info (ssid, rssi -55, fake IP 192.168.1.50), power-save calls; a clock; a wait-for-request-or-timeout primitive; fake settings and sleep flags. The test replays `w3-wifi-vectors/*.script.tsv` (README there) and compares the event log. The implementer chooses how to inject these fakes (compile the keeper with stub headers, or put the radio behind an internal table).

## 15. The radio layer (requirements on behaviour)

### 15.1 Scan collapse (vectors `scan-collapse.tsv`)

Input: the per-BSSID records the driver returns, strongest first. Rules:
1. Read at most the first 40 records the driver reports (weaker ones are not read, even if unique SSIDs).
2. Records with an empty SSID are dropped.
3. One entry per SSID (exact, case-sensitive byte comparison). An entry takes the rssi of the first (strongest) record seen and its authmode; if that authmode is open and a later record of the same SSID is not, the entry becomes secure. A secure first record stays secure.
4. Output order is the order of first appearance, i.e. strongest first.
5. When the output already holds `max` entries, further new SSIDs are dropped, but later records of an SSID already in the output still apply rule 3.
6. Return the entry count; return 0 when the driver reported no records; return "did not run" (-1) when the scan was refused (another scan or a connect has the radio, or the driver refused to start); on allocation failure also -1.
7. A scan that names a target SSID probes for it by name and so also finds a network that hides its name; the answer is collapsed the same way.
8. Each scan updates a **BSSID memory** (up to 25 SSIDs): for each SSID placed in the output, the strongest record's BSSID, channel and rssi replace that SSID's entry or add one; entries for SSIDs not seen in this scan are kept (the BLE radio can make the receiver miss APs).

### 15.2 Connect (vectors `connect-config.tsv`)

Blocking, timeout 20000 ms. A connect cancels a scan in progress and waits for the radio to be free, within the timeout; failing that it returns false. Configuration handed to the driver: SSID and password copied up to 32 and 64 bytes without requiring a terminator (a 32-byte SSID and 64-char password fill the fields exactly); authmode threshold `WIFI_AUTH_OPEN` (accept any); PMF capable true (not required); listen interval 10; if the BSSID memory has the SSID: pin that BSSID and channel with `WIFI_FAST_SCAN`; otherwise `WIFI_ALL_CHANNEL_SCAN` sorted by signal. If the radio is still busy with an earlier association, leave it and wait until the driver accepts the new configuration, all within the 20 s timeout; if it never does, the connect fails. Success is the station getting an IP within the timeout (log info `got IP a.b.c.d`). A disconnect during the attempt is retried up to 3 times (4 driver connect calls in all) and then the attempt fails at once; a timeout with no event also fails. When a pinned attempt fails, the whole BSSID memory is emptied (so the next attempt for any SSID uses a full scan). The current join's SSID is exposed for status (row 3 of section 9) from before the config is applied until the attempt ends. Log at warn `station disconnected reason=<n> rssi=<n>` on every driver disconnect event (tag free).

### 15.3 Nearby memory (vectors `scan-cache.tsv`)

Nearby memory (7.2): the entries of the station's own scan, max 25, replaced as in 7.2 (the `cache` rows of `scan-cache.tsv`). There is no merge facility: do not build one, and skip the `merge` rows of that file.

## 16. Log lines a checklist relies on

Tag `rabble_wifi` unless noted, exact text:
`joining <ssid>`; `joining saved network <ssid>`; `joining a different network`; `forgot the network in use; leaving it`; `wifi off; disconnecting`; `wifi forgotten; disconnecting`; `screen off a while; left wifi`; `no saved wifi network nearby; looking again in <N> s`; `scan found <N> networks`; `no scan; the radio was busy`; warn `couldn't save <ssid>`; warn `couldn't forget a wifi network`; error `no memory for the saved networks`. Radio-layer lines, tag free: `WIFI STA MAC: ...`, `got IP a.b.c.d`, `station disconnected reason=<n> rssi=<n>`.

## 17. Concurrency requirements

Every public function is callable from any task. The status, saved list, scan results and counter are each read as a consistent copy (no torn strings). Requests (join, forget, nap, apply) are handed to the keeper without waiting for it. Only the keeper touches the store. The settings-screen scan runs on its own short task and never touches the store.

## 18. Gadget checklist (flash, serial console)

1. **Saved networks survive the swap.** Before flashing the new build note `>status` JSON wifi object and the saved networks list (settings page or `rabble_wifi_saved`). Flash new build over old. Boot log shows `WIFI STA MAC`, no `couldn't save`. The same networks, in the same order and with the same hidden marks, are listed; the first one joins by itself (log `joining saved network <name>`, then `got IP`).
2. **Join.** From the settings page pick a scanned secured network and enter the password: status goes CONNECTING `Joining...` then CONNECTED with ssid, IP and RSSI; it moves to the top of the saved list; log `joining <name>` (no scan first). Repeat with "Other network..." for a typed name: it joins and is marked Hidden in the list.
3. **Wrong password.** Join a known network with a wrong password: after the attempt status is FAILED with `Can't join; retrying`, retries visible in the log at about 5 s, 10 s, 15 s spacing with the screen on, `joining saved network` each time; fixing the password (join again) connects at once.
4. **Out of range.** Take the device out of range of every saved network (or power the AP off): after a pass or two status is NOT_NEARBY `No saved network nearby`, log `looking again in 30 s`, then 60 s awake. Bring the AP back and, from the settings page, scan: it joins at once; or wait for the next look.
5. **Forget in use.** Forget the connected network (two taps): log `forgot the network in use; leaving it`, the link drops, and if another saved network is in range it joins within the scan time; forgetting the last one gives NO_NETWORK (`Not set`). `>wifi.forget` (empty) forgets all.
6. **Scan.** Scan from the settings page: button shows `Scanning...`, the list appears strongest first, hidden/blank names absent, saved ones marked; a second scan while joining is refused (button does nothing); log `scan found N networks`.
7. **Nap/wake.** Put the device to sleep on battery (`>nap`): after a pause `Wi-Fi napping`, then log `screen off a while; left wifi`, `connected` false (status row shows Joining), the beam goes Offline. Wake with `w`: `Wi-Fi waking` and the network is rejoined after a scan with no backoff wait.
8. **Power levels.** On battery idle the voice loop calls DOZE then REST when asleep; use a current meter or compare idle draw: FULL (on USB) highest, DOZE lower with a few hundred ms extra ping latency, REST lowest with up to about 1 s. A press returns to FULL (no extra latency).
9. **Router reboot.** Power-cycle the AP while connected: within about a second the keeper starts a rejoin (log `joining saved network`), and the link returns within the AP's boot time plus one retry delay.
10. **Boot order.** Boot log shows the Wi-Fi start after voice start and before the beam, internal heap figure at `ready` within a few percent of the pre-swap run; task list shows `rabble_wifi` priority 4 unpinned.

## 19. Test vehicle and vectors

Two host tests. (a) Replay the 20 station scenarios (section 14) and compare logs exactly. (b) Radio tables (section 15): drive the radio layer against a fake driver that returns records strongest first and reports outcomes as in the README, and compare `scan-collapse.tsv`, `scan-cache.tsv` (`cache` rows only) and `connect-config.tsv`. Everything else (task priorities, stack, log wording in 16, real association) is checked on the gadget.
