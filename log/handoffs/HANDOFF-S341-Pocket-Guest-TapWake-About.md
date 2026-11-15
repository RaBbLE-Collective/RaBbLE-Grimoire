# HANDOFF-S341: guest limit, tap-wake toggle, About page, automatic guest key, translate

Date: 2026-11-15 · Pocket `new-horizons`, sCoRE `new-horizons` (all uncommitted work now committed, nothing pushed), Grimoire.
Supersedes the "Next job" of `HANDOFF-S339-Pocket-Settings-About-Page.md` (About is built, below).

## Done (host-tested; nothing flashed to Mark's board)

- **Guest limit (sCoRE `server/groqmeter.py`)**: dad's guest was refused with `Groq chat tokens is 64% used (guest cutoff 50%)`: the per-minute token window, filled by one guest's own growing history. Per-minute `tokens` windows now use `GUEST_GROQ_MINUTE_CUTOFF` (default 0.9); daily windows keep 0.5. Test added. **Not deployed** (B-34).
- **Automatic guest key (flasher)**: after a successful flash the page reconnects and, if the device reports no sCoRE key, mints a guest key (`/api/guest`) and sends `beam.token`; no Wi-Fi needed, a device with a key (settings kept) is left alone, failure falls back to Send. `portal.js` `issueGuestKey()` and `autoGuestKey()`; portal test passes. **Worker and page deployed** to `pocket.joinrabble.world` (version `ba735912`) from a temp config without the `send_email` block (email still not connected).
- **Double tap to wake toggle**: `rabble_settings_tap_wake` (NVS `tap_wake`, default on), console `tap_wake=0|1`, Orbit More item "Double tap to wake", gate in `rabble_screen.c`. Host tests pass.
- **About page**: More now has 7 items; PG_ABOUT lists Firmware, Board, Device, sCoRE, Wi-Fi, Storage, Built (inert rows), pure row builder `orbit_about_rows()` + `rabble_about.c` reader. Both boards build, 175B image contains `0.1.1-dev`. **No screenshot, never seen on a device**; long values may overflow a row. After adding `rabble_about.c`, `touch firmware/CMakeLists.txt` before the first build.
- `./test/run.sh app core display`: 16 passed. These firmware changes are NOT in the staged `0.1.1-dev` builds on the flasher.

## Findings

- **Double tap cannot wake on battery (B-32)**: `rabble_input.c apply_power` pauses the display when asleep+dark+resting on battery; `rb_display_pause` sends the touch chip deep sleep (`0xD1 0x05`, ignores I2C until reset). Raise (IMU) and the button still wake. Works on USB. Fix needs a board. Foundling has no `rabble_screen`, so no tap wake there.
- **Transcripts do not reach R2 from the Pocket (B-33)**: `beam.py` never calls `transcripts.record`. R2 itself is healthy: `score/snapshots/*` since 23:10Z, so **B-31 can be cleared** (`bash spells/render-set-r2.sh --clear-fresh-start`, redeploy sCoRE).
- **Translate**: separate mode on `0.1.1-dev` (mode icon under the clock: Converse, Capture, Translate); language only via serial `>translate.lang=<Name>` (no Orbit or page control yet; persistence across reboot unverified). Mark got it showing ENG after reflashing. Mark's observation: plain RaBbLE chat translates well and is more malleable than the dedicated mode (Translate = one call, no history, "output only the translation").

## Note (not scoped, do not build yet)

Mark is tempted to make translation a system-prompt behaviour of RaBbLE chat, or an applet, for language-to-language only, instead of (or beside) the dedicated Translate mode. Revisit after real use; see `idea_translate_as_chat_prompt` in memory.

## Next (Mark's calls)

1. Commit done; **push `release/0.1.0` + deploy sCoRE** (guest fix B-34), test under py3.12 first (`uv venv --python 3.12 /tmp/venv312`), then clear `R2_ALLOW_FRESH_START` (B-31).
2. Rule on capturing beam turns as transcripts (B-33); skip silence hallucinations either way.
3. Translate language picker (Orbit More item cycling a short list, and a field on the flasher page); TTS for non-English still open.
4. Double-tap on battery: test lower touch power state + touch-INT wake on a board, or document as USB-only.
5. Stage a new firmware build (`0.1.1-dev2`) to the flasher to ship tap-wake toggle and About; screenshot About with `ops/pocket-shot.py` first.
6. Still open from S339: email routing (restore `send_email` via plain `wrangler deploy`), delete unused `cfat_` token.
