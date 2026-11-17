# w3-wifi vectors

Behaviour data for `../w3-wifi.spec.md`. Two families. All files are tab separated, no header row, `\n` line ends.

## 1. Station scenarios (`<name>.script.tsv` -> `<name>.expect.tsv`), 20 scenarios

A script is replayed against a **fake world** (spec section 14) in virtual time; the test writes one line per observable event; the result must equal `<name>.expect.tsv` byte for byte (same lines, same order, same times).

Script line: `t_ms<TAB>op<TAB>args...`. Lines starting `#` are comments. Times never decrease. Before each op the world runs to `t_ms`; after the op it runs again at `t_ms` until the station has nothing more to do at that instant.

| op | args | effect |
|---|---|---|
| `preload` | ssid, pass, hidden(0/1) | appends to the store's list (setup, before `start`; same effect later but the station's view refreshes only on its next change) |
| `wifi_on` | 0/1 | the settings flag `rabble_settings_wifi_on()` (does not notify the station) |
| `asleep` | 0/1 | value of `rabble_state_asleep()` |
| `air` | `ssid:rssi:open\|secure,...` or `-` | what scans see, already collapsed and strongest first |
| `result` | ssid, `ok:ms\|fail:ms,...` | outcomes of successive connect attempts to that ssid (last repeats); the attempt takes `ms`. No entry: fail after 20000 |
| `scan_ms` | n | duration of the station's own pre-join scan (default 2000) |
| `scan_busy` | 0/1 | the radio refuses scans (they return "did not run") |
| `store_fail` | 0/1 | store `remember`/`forget` return false |
| `start` | | call `rabble_wifi_start()` |
| `apply`, `join ssid [pass]`, `forget ssid` (`-` = all), `nap 0/1`, `power full\|doze\|rest`, `scan` | | the public call |
| `drop` | | the link is lost silently (no call into the station) |
| `status`, `saved`, `scan_results`, `connected` | | read and log (below) |
| `end` | | run to this time, stop |

Expect line: `t_ms<TAB>kind<TAB>fields...`

| kind | fields |
|---|---|
| `task` | name, stack bytes, priority (task creation) |
| `radio.init` | radio brought up (once, at start) |
| `radio.connect` | ssid, password (blocking join begins) |
| `radio.connect_result` | ssid, `ok`/`fail` |
| `radio.scan_cache` | the station's own pre-join scan begins |
| `radio.scan` | the settings scan runs |
| `radio.disconnect` | station asks the radio to leave |
| `radio.ps` | `NONE`/`MIN`/`MAX` power-save call |
| `store.remember` | ssid, password, hidden argument (1, 0 or -1) |
| `store.forget` / `store.forget_all` | ssid |
| `log` | level (I/W/E), tag, message |
| `ret` | `start` or `scan`, numeric return (0 ok, 259 = invalid state) |
| `status` | state name, ssid, ip, rssi, detail |
| `saved` | count, `ssid:hidden,...` |
| `scan_results` | `gen=N`, count, `ssid:rssi:secure\|open,...` |
| `connected` | 0/1 |

Compare rules: all columns exactly, except `status` detail when state is `NO_NETWORK` (ignore it) and the pre-start moment (no vector reads status before `start`). Times of station-initiated events must match exactly (the keeper pass period is part of the contract, section 7.1).

Scenarios: boot-nearby, boot-second-only, boot-hidden-saved, boot-wifi-off, boot-no-network, wrong-password-awake, wrong-password-asleep, not-nearby-awake, not-nearby-asleep, not-nearby-then-appears, join-scanned-vs-typed, join-different-while-connected, forget-in-use, forget-other-and-all, nap-wake, nap-while-off, link-drop, power-levels, scan-settings, save-fails.

## 2. Radio tables (host-callable pure behaviour, spec section 15)

- `scan-collapse.tsv` (15 rows): `case, max, records, return, entries`. `records` = `ssid|bssid_byte|rssi|open/secure|channel` joined by `;` (input order is arbitrary; the fake driver hands them back strongest first, ties in input order). `entries` = `ssid|rssi|open/secure` joined by `;`. `return` = entry count (0 when no records; the first 40 records handed back are the only ones read).
- `scan-cache.tsv` (13 rows): `case, step, op(cache|merge), records, return, cache_count, cache_entries`. Cases are independent but share one cache that is reset between cases by one sentinel entry `Z|-99|open` (a `cache` replace); merge cases therefore show `Z` first. `return` is the count returned by the operation (0 = no fresh scan completed).
- `connect-config.tsv` (7 rows): `case, ssid, outcome, returned, driver_connect_calls, set_config_calls, bssid_set, bssid_byte, channel, scan method, sort method, listen interval, auth floor, rssi floor, pmf capable, config ssid, config password`. Cases run in file order sharing the scan memory (a failed pinned attempt in case 3 empties it for case 4). `outcome`: `ok` = driver reports an IP at once; `fail` = driver reports a disconnect every attempt; `timeout` = driver reports nothing.
