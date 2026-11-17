# W2 input golden vectors

Behaviour data for `rabble_input`, produced by compiling the original decision logic on a host (stubs for state, board and clock) and recording what it does. Spec: `../w2-input.spec.md`, section 12.

**Integrator only:** `~/RaBbLE-Cleanroom/gen/w2-input/` (private, outside every repo) contains the original code (adapted) and the scenario driver. It is tainted. Never copy `~/RaBbLE-Cleanroom/gen/w2-input/` (private, outside every repo) into the implementer's workspace; ship only the four `.tsv` files and this README. Rebuild with `cc -O1 -o /tmp/inputgen ~/RaBbLE-Cleanroom/gen/w2-input/inputgen.c && python3 ~/RaBbLE-Cleanroom/gen/w2-input/make_vectors.py`.

## Files

| File | What it pins | Rows |
|---|---|---|
| `btn.tsv` | talk and aux button handling over 10 ms polls: PTT events, wake, click-to-sleep, hold hint and power-off, ordering of release before press in one poll, requested power-off | 1,300+ (one row per poll) |
| `sleep.tsv` | the idle auto-sleep and asleep-on-battery power-off decision, checked every call | 40 |
| `power.tsv` | the display-pause and CPU-slow decision, all 64 input combinations from each of 3 prior states | 192 |
| `nap.tsv` | the Wi-Fi nap decision (two-minute timer, bench request, voice notes waiting) | 25 |

## Format

Plain TSV. Lines starting with `#` are comments (each file's header says its columns). Fields are tab separated. Compare action columns exactly (string equality). Actions inside one row are joined by `|` in call order; `-` means no action. Boolean columns are 0/1.

Action words are test vocabulary, not code names. The implementer's test vehicle maps its own observable effects onto them:

| Action | Meaning |
|---|---|
| `ptt_down`, `ptt_up`, `ptt_down_wake` | an event posted on the PTT queue (`wake` = true for the last) |
| `sleeping(x)` / `waking(x)` | the screen-asleep flag changed; x is the reason word given (`pwr` aux button, `boot` talk button, `serial`, `auto-sleep`) |
| `notify_input` | the input task was told to leave its button wait |
| `wifi_apply` | the Wi-Fi manager was told to reconnect now |
| `caption=T` | caption set to T |
| `shutdown`, `update_power`, `progress=0`, `level=0`, `mode=off`, `delay=N`, `board_power_off`, `mode=idle` | the power-off sequence steps in order (spec 7.4); `delay` is milliseconds |
| `display_pause(1\|0)`, `cpu_low(1\|0)`, `log:<text>` | power-state changes and the exact log text |
| `wifi_nap(1\|0)`, `as_if_battery(0)` | Wi-Fi nap switched, bench battery override cleared |

## btn.tsv rules

One scenario per fresh process (all state starts clear). `init` rows set a start condition (`asleep`, `wifi` connected, `poweroff` ok|fail, `caption`). Defaults: awake, Wi-Fi not connected, caption `READY`, board power-off returns (fails). Each other row is one input-loop poll: the events byte (hex, bit 0 talk press, 1 talk release, 2 aux press, 3 aux release) and an external action applied first (`wake` and `sleep` set the flag from outside, `reqoff` calls the power-off request). Run every listed poll, including those with events 0: they advance the hold counter. Button names in the reason words are the 175B board's: talk `boot`, aux `pwr`.

## sleep.tsv, power.tsv, nap.tsv rules

`sleep.tsv`: scenarios are consecutive calls in one process; timer state carries inside a scenario, resets between scenarios. `power.tsv`: each row is independent: first reach the named prior state (`none` = full power; `rest` = paused with CPU slowed, inputs 1,1,1,1,1,0; `host` = paused, CPU at full speed, inputs 1,1,1,1,1,1) by one call, then apply the row's inputs and compare the second call. `nap.tsv`: consecutive calls inside a scenario; `cpu_low` is an input here (in the device it comes from the power decision).
