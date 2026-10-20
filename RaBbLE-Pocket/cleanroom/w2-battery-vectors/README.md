# W2 battery golden vectors

Behaviour data for `rabble_battery`, produced by compiling the original `rabble_battery.c` unchanged on a host, with stub ESP-IDF headers and a scripted fake clock, and recording what it returns, prints and logs. Spec: `../w2-battery.spec.md`.

**Integrator only:** everything under `~/RaBbLE-Cleanroom/gen/w2-battery/` (private, outside every repo) includes or drives the original source (`harness.c`, `pure.c`, `run.sh`) or the stub headers written for it. Never export `~/RaBbLE-Cleanroom/gen/w2-battery/` (private, outside every repo) to an implementer. Everything outside `~/RaBbLE-Cleanroom/gen/w2-battery/` (private, outside every repo) is plain behaviour data and is safe to give to an implementer. (`gen/make-scripts.py` contains no original code, only the formatting of ESP-IDF's public `esp_pm_dump_locks()` text, but it stays in `~/RaBbLE-Cleanroom/gen/w2-battery/` (private, outside every repo) with the rest.)

Regenerate: `~/RaBbLE-Cleanroom/gen/w2-battery/run.sh <path to apache/rabble_battery.c>`. It compiles three binaries with host gcc, rewrites `scripts/`, both `expected-*` folders and the three TSV files. Fully deterministic (no random rows, fake clock).

## Pure-function TSVs (outside gen/, compare exactly)

Plain TSV, UTF-8, lines starting `#` skipped, single tab separators.

| File | Rows | Columns |
|---|---|---|
| `permille.tsv` | 244 | `part_us`, `whole_us`, `per_mille`: the share rule used for every per-mille figure (spec 4.3). Signed 64-bit inputs. |
| `drain.tsv` | 840 | `started` (0/1), `pct_start`, `pct_now`, `secs`, `result` (the function's boolean), `rate10`, `full_h` (`-` when result is 0): the `rabble_battery_drain` rule (spec 5), over a grid including the 599/600 second boundary, no drop, rises, negatives, unstarted. |
| `reset-names.tsv` | 16 | `esp_reset_reason_t` enumerator name, resulting `"boot"` string in the JSON (spec 6.2). |

## Scenario scripts and expectations

`scripts/NN-name.script` (26 files, 882 non-empty lines) are inputs. `expected-full/NN-name.expect` is what the original prints when built with the device's configuration (light-sleep callbacks on, power-management profiling on). `expected-noprof/NN-name.expect` is the same script with profiling off (the profiling fields disappear; spec 4.4). 447 steps per configuration.

### Script language

One op per line; `#` and blank lines ignored. Times are microseconds of the monotonic clock (`esp_timer_get_time`), which the test driver fakes and sets explicitly. A script starts with the clock at 0 and a power-on reset reason.

| Op | Meaning |
|---|---|
| `time <us>` | set the fake clock |
| `boot <reason>` | set the fake reset reason (`poweron sw panic int_wdt task_wdt wdt deepsleep brownout usb jtag ext unknown sdio efuse`) |
| `init` | call `rabble_battery_init` |
| `power <pct> <mv> <charging> <usb> <on_battery>` | call `rabble_battery_note_power` with that reading and flag |
| `state <screen_off> <resting>` | call `rabble_battery_note_state` |
| `wake <slept_us>` | simulate one automatic-light-sleep wake that slept that long (calls the registered exit callback) |
| `dump` followed by lines starting with `\|` | set the text the next `esp_pm_dump_locks` call writes (the lines with the leading `\| ` removed; a lone `\|` is an empty line). It stays in force until replaced. |
| `nodump` | `esp_pm_dump_locks` writes nothing |
| `read` | call `rabble_battery_read`, print one `READ` line |
| `drain` | call `rabble_battery_drain` on the struct from the last `read` |
| `jsoncap <n>` | buffer capacity used by later `json` ops (default 4096) |
| `json` | call `rabble_battery_json`, print `JSON<TAB>return value<TAB>text` |
| `saved` | print `SAVED<TAB>` the string from `rabble_battery_saved_json`, or `@null` |
| `rtc` | test-vehicle peek at the RTC record (valid and the stored JSON, or `none`). An implementation does not have to store its record in the same shape; see spec 10 for what is required. In your vehicle, implement it as "the record a warm reset would hand to the next boot, decoded, or none". |
| `reset` | call `rabble_battery_reset` |
| `reboot [corrupt] [badmagic]` | simulate a warm reset: all ordinary state is lost, the RTC record survives (with one stored byte flipped if `corrupt`, or its validity marker damaged if `badmagic`). Follow it with `init`. |

### Expected-file lines

`STEP<TAB>n<TAB>the script line` (echo, not compared); `LOG<TAB>I|W<TAB>text` (a log line, in order; compare the text); bare `@power.saved ...` lines (printed on standard output by `init`, compare); `READ`, `DRAIN`, `JSON`, `SAVED`, `RTC` as above. `READ` columns: `started running secs pct=start,now mv=start,now off_pm rest_pm slept_pm sleeps busy_pm awake=<text>`. Compare byte for byte. Order of standard-output and log lines is the order shown.

| Script | Subject |
|---|---|
| 01-cycle-nodump | plug/unplug cycle, accrual, frozen after stop, restart after replug, drain |
| 02-boot-on-battery, 02b-no-battery | first reading on battery; no battery (-1) readings |
| 03-accrual | screen-off and resting time accrual, flags carried across plug cycles, reset |
| 04-light-sleep | wake callback counting, ignored zero or negative sleeps, per-measurement baseline |
| 05-profile-basic | profiling: busy, modes, rejects, locks, awake text, JSON, truncation to 200 |
| 06, 06b | one-per-mille threshold for the awake text, "nothing", ties |
| 07, 07b | lock matching (same name twice, changed type, new lock, a lock whose total went down) |
| 08, 09, 09b, 09c | 24-lock cap; dump without a light-sleep section; start snapshot unreadable; oversized dump (observed edge, not required) |
| 10-reset | reset while on battery, while on USB, after stop |
| 11, 11b to 11g | RTC record: 30-minute save interval, save points, warm-reboot restore, corruption, nothing saved, restore twice, with profiling |
| 12, 12b | JSON capacity truncation and the return value; every reset-reason string |
| 13-drain-live | drain through the live meter, rounding |
| 14-power-unknowns | -1 percent and 0 mV mid-measurement |
