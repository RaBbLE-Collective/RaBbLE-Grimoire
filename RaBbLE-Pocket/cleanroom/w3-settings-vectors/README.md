# W3 settings golden vectors

Behaviour data for the settings store, produced by running the original store on a host against an in-memory fake of the non-volatile key/value store. Spec: `../w3-settings.spec.md`, section 12.

**Integrator only:** `~/RaBbLE-Cleanroom/gen/w3-settings/` (private, outside every repo) holds the generator and fakes and contains original code. Never copy it into the implementer's workspace; ship only the five `.tsv` files and this README. Rebuild: `cc -O1 -Ifake -I<apache dir> -o /tmp/claude-1000/setgen driver.c <apache dir>/rabble_settings.c && python3 make_vectors.py` (from that directory).

Build configuration the vectors assume: default volume 70, default power-off 45 s, default beam URL `wss://rabble-score-x7qq.onrender.com/api/v1/beam`.

## Files

| File | What it pins | Data rows |
|---|---|---|
| `defaults.tsv` | the boot (`init`) result for a prepared stored content: first boot (nothing stored), every key alone at in-range, boundary and out-of-range values, wrong stored types, oversize and empty strings, everything set | 46 |
| `init-errors.tsv` | init under injected failures (flash init asks for erase, flash init fails, namespace open fails) | 4 |
| `setters.tsv` | each setter given one input on a fresh boot: stored entry, getter result, listener events, number of writes and commits | 80 |
| `sequences.tsv` | repeated identical sets, reboot persistence (a fresh boot on the same store), default-URL restore, write and commit failures | 45 |
| `token.tsv` | beam token replace and append sequences including limit, overflow and null (two scenarios start from a stored token; see the file header) | 32 |

## Format

Plain TSV. Lines starting with `#` are comments (each file states its columns). Compare every column as a string, exactly.

Input notation: `rep:<c>:<n>` is the character `c` repeated `n` times; `<empty>` is the empty string; `<null>` is a null pointer; any other text is literal. A stored-content entry `key type value` uses the same notation for its value.

Fake store semantics the test seam must reproduce: values are typed (`u8`, `u16`, `str`); reading a key that is absent or stored with a different type fails and leaves the caller's variable untouched; reading a string into a buffer that is too small fails (including when the stored string plus its terminator does not fit) and leaves the buffer untouched; every value write counts as one write, every commit as one commit.

| Column word | Meaning |
|---|---|
| `getters` | all getters after the call as `name=value;...` in this order: volume, speaker, voice, mic_gain, brightness, sleep, power_off, wifi, raise, url, token, token_len. `speaker`, `wifi`, `raise` are 0/1. `<empty>` stands for an empty string. `sleep` and `power_off` are the seconds getters. |
| `nvs_entry` / `nvs_after` | stored content as `key:type=value`, `;`-joined for several, `-` for nothing. Keys are the spec's stored key names. |
| `listener` | notification names fired during the call, `|`-joined in order, `-` for none. Names: volume, speaker, voice, mic_gain, brightness, sleep, power_off, raise, wifi, beam. |
| `return` | `ESP_OK` or `ESP_ERR_INVALID_SIZE`. Only the token setter returns a code; for every other setter the column is `ESP_OK` and carries no meaning. |
| `setter` | volume, speaker, mic_gain, brightness, sleep, power_off, wifi, raise, voice, beam_url, token (replace), token+ (append). Integer inputs are passed as plain integers; for the boolean setters any nonzero integer means true. |

Reboot rows in `sequences.tsv` are `init` rows tagged `reboot`: the RAM state is back at build defaults, then init runs on the stored content as it stood.
