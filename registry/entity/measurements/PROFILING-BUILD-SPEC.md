# Profiling firmware build: spec (U11 step 2)

Status: spec only. No firmware changed. Mark flashes; agents never do. Target: Pocket gadget firmware (`RaBbLE-Pocket/firmware`, `rabble_entity.c`, 1.75C/gadget board). Budget under test: schema section 7 (worst frame at or under 14.0 ms, 60 fps TE-locked).

## What the build does

1. A build flag `RABBLE_PROFILE_FIXTURES` (off by default, so normal builds are unchanged; the Pocket reorg decides where the flag lives). When set, `rabble_entity_tick` stops taking input from the board and drives `nl_inputs_t` from a fixture table, while `nl_simulate` and the band renderer run exactly as in a normal build.
2. Fixture cycle, 20 s each, so the 10 s log fires at least once per fixture after a 5 s settle. Order and inputs (matching `pocket_hw-host-2026-11-18.json`):

| id | inputs |
|---|---|
| idle | state IDLE, level 0, boot done |
| listen05 | LISTEN, level 0.5 held |
| listen10 | LISTEN, level 1.0 held |
| think | THINK |
| speak | SPEAK, level 0.5 |
| joy | happy 1 |
| flip05 | flip held at 0.5 |
| orbit | Orbit home page at slide 233 (the Orbit builder from the home page) |
| boot | restart boot every 4 s, log the first second |
| turn_idle, turn_listen10 | roll 0.8 rad/s over idle and listen10 |
| busy | speak with activity forced 1.0 |

   Each fixture with a switch repeats once per switch below (the effect-off pass).
3. Effect switches, from a compile-time bitmask or a UART/console command `fx <mask>`: mesh.edges, mesh.nodes, mesh.signals, strands.mic, strands.absorb, eyes, portal.back, portal.front, glass.badges, glass.clock, glass.status, glass.caption, ring, ring.drain_arc, ring.tint. These are the same switches as the host scratch `scene.c` (`NL_OFFMASK`); lift them from there.
4. Mic and motion inputs are replaced by the fixture, so no one has to speak or shake the device.
5. Wi-Fi and the sCoRE link stay as in the normal build (their cost is part of what is being measured); the report line notes it.

## What it logs

Per fixture and per effect mask, at the existing 10 s cadence, the existing `nl_prof` line plus a header line before and a footer after. The existing `ESP_LOGI(TAG, ...)` in `rabble_entity.c:327` already prints the second line; do not change its format.

```
PROF fixture=<id> mask=<decimal> t=<s since fixture start> fw=<git short sha> uart=<n>
rabble_entity: <fps> fps, render <ms> + <ms> ms, <prims> prims | per frame ms: fill <ms> ring <ms> ellipse <ms> line <ms> sprite <ms> swap <ms> sim <ms> ui <ms> | orbs <ms> filled <ms> hollow <ms>, draws <n> ellipse <n> line | act <a0> <a1>
PROF damaged=<mean bands drawn per frame of 30> late=<count of late frames> worst=<ms>
```

Example of one record:

```
PROF fixture=listen10 mask=0 t=15 fw=5c987a4 uart=1
rabble_entity: 33.4 fps, render 9.80 + 6.10 ms, 599 prims | per frame ms: fill 0.90 ring 0.40 ellipse 2.10 line 7.30 sprite 0.30 swap 1.10 sim 1.60 ui 0.00 | orbs 1.40 filled 0.50 hollow 0.20, draws 280 ellipse 300 line | act 0.31 0.62
PROF damaged=24.1 late=12 worst=41
```
(Illustrative numbers, not measured.)

The `damaged` line needs one new counter in the profiling build: the mean count of bands for which `nl_band_same` returned 0 per frame, and the existing late-frame warning (`rabble_entity.c:594`) summed over the 10 s window. Everything else is already logged.

## Paste back

Paste the whole serial log, unedited, into a message or save it as `RaBbLE-Grimoire/registry/entity/measurements/pocket_hw-<date>.log`. An agent parses it to JSON.

- Parser: a small script in `registry/entity/measurements/` (to be written with the build; same record layout as the host JSON): groups lines by `PROF fixture/mask`, drops the first window of each fixture (settle), takes the median of the remaining windows.
- Output: `registry/entity/measurements/pocket_hw-<date>.json`, same `fixtures`/`effects` structure and `delta` fields as `pocket_hw-host-2026-11-18.json` plus per-stage ms, with `"kind": "device"`, the board, the commit and clock settings (QSPI 80 MHz, 32-row bands).
- Then calibrate (schema 7 step 3): fit device ms = a * prims + b * damaged_bands + c per stage from the device JSON against the host JSON, record the fit and residuals in `measurements/`, and only then set `cost.device.{measured, ms_worst, prims_per_frame}` for each effect (`measured` pointing at the device file) and reconsider `support.pocket_hw`.

## Acceptance

The log covers every fixture with the full mask (about 5 min), then the single-effect-off pass for listen10, speak, turn_listen10 and idle only (the states S252 measured below 60, plus the idle baseline). At least two 10 s windows per cell after settle; fps, render ms and prims on every record.
