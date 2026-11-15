# HANDOFF-S339b: About page in the Pocket Settings Orbit, plus where S339 was left

Date: 2026-11-15 · Pocket `new-horizons` (`90e07c5`), sCoRE `release/0.1.0` (`63a2811`, live as `0.1.1-dev`), Grimoire.
Supersedes `HANDOFF-S339-Pocket-v0.1.1-sCoRE-Persistence.md` (moved to `done/`).

## Next job: an About item buried in More

Mark's ask: the device shows no firmware version or info anywhere in Settings. Add an About item, tucked into the More page.

Facts found (S339, read-only):
- Settings is the Orbit, `firmware/entities/RaBbLE/src/rabble_orbit_logic.c`. Items are `idef_t k_items[]` (kind, glyph, font, target page, glyph text, name); pages are `k_home` (9 items), `k_more` (5: Voice, Mic gain, Tap to talk, Raise to wake, Off when asleep), `k_wifi`, `k_score` (Test, Reset URL), `k_pomo`. Page sizes are hard-coded in `k_pages[]` (`k_more, 5`), so adding an item means updating that count.
- The version already exists in firmware: `esp_app_get_description()->version` (used in `rabble_setup.c:277` for `@status` and `rabble_beam_score.c:356` for the beam hello). `firmware/version.txt` is the one source (`0.1.1-dev`); IDF 6.0.1 reads it as PROJECT_VER, but build dirs configured before it existed need `touch firmware/CMakeLists.txt` to reconfigure.
- Board comes from the `@status` path (`board` field); device id/name appear in the beam hello (`RaBbLE-Pocket-5EB8`).
- Drawing is native (`nebula_lite`, `nl_orbit_t`, `nebula_lite/src/orbit.c`); there is no existing text-only info page, so the new page type is the real work. Pages with `ids == NULL` (Networks, Saved) are the existing pattern for custom content: read how `PG_NETWORKS` is rendered first.

Shape proposed: `I_ABOUT` (K_PAGE, text glyph "i", name "About") added to `k_more`, target `PG_ABOUT`; the page lists read-only rows: Firmware (version), Board, Device id, sCoRE state (key set / reachable), Wi-Fi SSID, free storage, build date. Foundling needs nothing unless its settings panel (`foundling_canvas_settings_init`) should show the version too: ask Mark.

Done = host test in `firmware/test/` for the row builder (no hardware), a screenshot with `ops/pocket-shot.py` of the About page (entity face only is capturable, check the Orbit is), build both boards, version shown reads `0.1.1-dev`. Do not flash Mark's board without asking.

## Where S339 ended (state, all verified this session)

- sCoRE prod: `0.1.1-dev` on Render (`release/0.1.0`, one squashed commit `06e0294` plus the py3.12 fix `63a2811`). R2 persistence on: bucket `rabble-score`, first boot ran with `R2_ALLOW_FRESH_START=1` (blocker B-31 tracks clearing it). First snapshot object had not appeared yet at last check (bucket empty: it is written after the first tracked write); confirm it after the flash test. Doc: `RaBbLE-sCoRE/RaBbLE-sCoRE-Persistence.md` (needs a refresh: pass-5 behaviours, `TRANSCRIPT_STOP_TIMEOUT_S`, real-R2 conditional PUT now verified, stale `env.defaults` snapshot naming and `render.reference.yaml`).
- Render runs Python 3.12, local is 3.14: test under `uv venv --python 3.12 /tmp/venv312` before pushing `release/0.1.0` (memory `score-render-python-312`).
- Pocket firmware `0.1.1-dev`: 4 builds staged and uploaded to the `rabble-pocket-firmware` bucket, manifest lists `0.1.1-dev` then `0.1.0`. Guest and Translate strings confirmed in both RaBbLE images (string check only; never run on a board).
- Worker + page deployed to `pocket.joinrabble.world` (new layout; sCoRE invite/key fields hidden, Send issues the guest key). Email is NOT connected: the deploy used a copy of `wrangler.jsonc` without the `send_email` block.

## Mark's open actions

1. **Flash test**: page, early-access code, flash `0.1.1-dev`, Send. Then check Render logs (`render-ctl.sh logs`) for the guest and `beam hello fw=0.1.1-dev`, and R2 for the first snapshot. Translate: tap the mode icon on the face (Converse, Capture, Translate, round again) or `>mode=translate` over serial; language `>translate.lang=<Name>` (default English).
2. **Email**: Email Routing on joinrabble.world, verify RaBbLE-Collective@proton.me, then restore the `send_email` block (it is in the tracked `wrangler.jsonc`, so a plain `wrangler deploy` from `companion-app/web` does it).
3. After the first snapshot: `bash spells/render-set-r2.sh --clear-fresh-start`, redeploy.
4. Delete the unused `cfat_` Cloudflare token (the S3 key pair was rolled; the old values were scrubbed from the local transcript only).
5. Rulings still open: TTS for non-English translate (Groq speaks English and Saudi Arabic only; proposal: speak those, caption the rest); layout of the Set up column on tall monitors is acceptable not perfect.

## Other leftovers (from the S339 handoff, still true)

Unlogged capture defects (silence hallucinations, 1969 date, duplicate outbox/shaped notes, `offloaded` never set, late sends); log them as blockers or fix; B-29 Pomodoro timer on sleep; firmware comment pass, NeBuLA Lite page, Pocket getting-started docs, README voice (all after v0.1.1); fix `score-pricing.json` for 5.x models; layerctl vscode; sCoRE LOW findings not fixed (per-row merge granularity, one invite consumable on each instance during overlap, transcript spill file on ephemeral disk).

## Cold start

```bash
cd ~/RaBbLE-Collective/RaBbLE-Pocket/firmware && sed -n 70,135p entities/RaBbLE/src/rabble_orbit_logic.c
grep -n "PG_NETWORKS\|PG_SAVED" entities/RaBbLE/src/*.c | head
```
