# W3 beam status golden vectors

Behaviour data for the beam status module (`rabble_beam.c`), produced by running the original status code on a host with fakes for the settings URL, the Wi-Fi connected flag and the session task. Spec: `../w3-beam.spec.md`, section 10.

**Integrator only:** `~/RaBbLE-Cleanroom/gen/w3-beam/` (private, outside every repo) holds the generator and is tainted. Never copy it into the implementer's workspace; ship only `status.tsv` and this README. Rebuild: `cd ~/RaBbLE-Cleanroom/gen/w3-beam && gcc -O1 -Istub -o gen driver.c orig_beam.c && python3 make_vectors.py`.

## File

`status.tsv`, 204 rows, plain TSV; lines starting with `#` are comments. Columns: `id`, `ops`, `trace`.

Each row starts from a fresh module (reported state UNTESTED with an empty detail, URL unset, Wi-Fi down), except that the row `init` is the first row and must run before anything else has touched the module.

`ops` is a `;`-joined script:

| Op | Meaning |
|---|---|
| `url=<text>` | the stored sCoRE URL becomes `<text>` (empty = unset) |
| `wifi=0` / `wifi=1` | `rabble_wifi_connected()` returns false / true |
| `report=<n>:<detail>` | the session task reports state number `n` (enum order) with that detail text (may be empty) |
| `cfg` | `rabble_beam_config_changed()` |
| `test` | `rabble_beam_test()` |
| `status` | call `rabble_beam_status()` and record the result |
| `name=<n>` | call `rabble_beam_state_name()` with enum value `n` (may be out of range) and record the result |

`trace` is the `|`-joined list of what was observed, in order: `S(<state number>|<detail>)` for a status result, `N(<name>)` for a state name, `session_connect` / `session_forget` when the module asked the session task to connect / drop the connection.

Compare `trace` exactly (string equality). State numbers are the enum order: 0 NOT_SET, 1 OFFLINE, 2 UNTESTED, 3 TESTING, 4 REACHABLE, 5 UNREACHABLE.

## Scenarios

| Id prefix | What |
|---|---|
| `init` | the very first status of a fresh module |
| `mat-` | URL set/unset x Wi-Fi up/down x every state x five detail texts, then status |
| `trunc-` | long detail texts (45 to 100 characters) reported, then status |
| `test-` | URL x Wi-Fi x every prior state: status, `test`, status |
| `cfg-` | URL x Wi-Fi x every prior state: `cfg`, status |
| `seq-` | longer sequences mixing Wi-Fi changes, tests, reports, config changes and URL changes |
| `name-` | state names for 0 to 5 and for out-of-range values |
