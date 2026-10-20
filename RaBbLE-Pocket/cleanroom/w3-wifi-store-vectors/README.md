# W3 wifi store golden vectors

Behaviour data for the saved-Wi-Fi-networks store. Spec: `../w3-wifi-store.spec.md`, section 11.

**Integrator only:** `~/RaBbLE-Cleanroom/gen/w3-wifi-store/` (private, outside every repo) holds the original code driven against a fake NVS. It is tainted. Never copy it into the implementer's workspace; ship only the files in this directory. Rebuild with `python3 ~/RaBbLE-Cleanroom/gen/w3-wifi-store/make_vectors.py`.

## Files

| File | Rows | What |
|---|---|---|
| `scenarios.txt` | 134 scenarios | The inputs: for each scenario, the initial NVS contents and the operations to run, in order. |
| `store.tsv` | 239 | The expected result after every operation. |

## Escaping (everywhere in both files)

Strings are written as bytes in this form: a backslash is `\\`; a space, `|`, any control byte and any byte above 0x7e is `\xHH` (two lowercase hex digits); everything else is literal. The JSON stored under `wifi_others` therefore appears literally, except that every backslash inside it is doubled and spaces would be `\x20`. In operation arguments the token `@EMPTY` means the empty string and `@NULL` means a null pointer. A value that is empty in `nvs_after` or `load_after` is simply blank after the `=` or between the `|`.

## scenarios.txt

`scenario NAME` starts a scenario; indented lines follow. Every scenario starts with a fresh NVS in which the store's namespace does not exist yet.

| Line | Meaning |
|---|---|
| `seed KEY VALUE` | Before anything else (always listed first): store this string value under KEY (this creates the namespace). |
| `remember SSID PASSWORD HIDDEN` | Call remember. HIDDEN is the integer argument (-1, 0, 1, 2, -5 occur). |
| `forget SSID` | Call forget. |
| `forgetall` | Call forget-all. |
| `load` | Call load; the row reports its result. |
| `failset KEY` | From now on every string write to KEY fails (the NVS call returns a generic failure). |
| `failerase KEY` | From now on every erase of KEY fails. |
| `failopen` | From now on opening the namespace fails (reads and writes). |
| `heal` | Clears all of failset, failerase and failopen. |

Operations run in listed order against the same NVS. Failure injection lines apply to later operations only.

## store.tsv

Tab separated, `#` lines are comments. One row per `remember`/`forget`/`forgetall`/`load` (seed and failure lines produce no row). Columns:

| Column | Meaning |
|---|---|
| `scenario` | scenario name |
| `step` | 1-based row number inside the scenario |
| `op`, `arg1`, `arg2`, `arg3` | the operation and its arguments as written in `scenarios.txt` (`-` for none) |
| `ret` | return value: 1 or 0 for the three mutating calls (true/false); the count for `load` |
| `writes` | the changes the operation made to NVS, in the order made, space separated: `set:KEY=VALUE` for every string write (including a write of a value identical to the stored one, if an implementation made one) and `erase:KEY` for an erase that removed an existing key; `-` if none. Erasing a missing key is not listed and not required to be absent. A write or erase that failed because of injection is not listed. |
| `nvs_after` | complete namespace contents after the operation, `KEY=VALUE` pairs sorted by key (byte order), space separated; `-` if empty |
| `load_after` | what a `load` right after the operation returns: space separated `ssid\|password\|hidden` entries (hidden 0/1) in order; `-` if none. (For a `load` row this is its own result.) |
| `logs` | the warning-level messages written during the operation itself (a `load` row: during that load), `\|` separated, non-printable bytes as `\xHH`; `-` if none. Informational: compare only if the test captures logs. |

Compare `ret`, `writes`, `nvs_after` and `load_after` exactly. `writes` is compared as a sequence (order matters).
