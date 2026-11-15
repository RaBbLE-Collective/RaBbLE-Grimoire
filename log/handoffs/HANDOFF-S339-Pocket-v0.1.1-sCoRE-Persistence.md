# HANDOFF-S339 — Pocket v0.1.1 + sCoRE persistence/guests/translate (parked mid-review)

Date: 2026-11-15 · Branch: `new-horizons` in Pocket, sCoRE, Grimoire. Nothing is deployed. Nothing is flashed.
Goal (Mark): make the Pocket easy for his dad to test in early access.

## State in one paragraph

Code for guest tokens, Translate mode, R2-backed SQLite persistence and the new flash page is written and committed on `new-horizons`, but **sCoRE persistence is not safe to deploy**: NiBbLE's second review found a data-loss path in `server/snapshot.py` and fix pass 3 never finished (builder hit the API session limit). Do not cherry-pick to `release/0.1.0`, do not push Render, do not deploy the Worker until the items under "Left in the middle" 1-2 are closed. Mark's invariant: **nothing may ever wipe or silently lose data** (a 404 from R2 never means "start fresh").

## What is done (committed)

- **Flash page** (`RaBbLE-Pocket/companion-app/web/public/`): board Detect button, full-width device log row, guest key flow, "Send to Architect" (email via Worker `/api/report`), device pre-check before flash, Send gated until checked, board-mismatch stop. Headless test `companion-app/web/test/portal_test.py` (10 checks). Layout commit `83cfcee` is the only part previously committed; the rest is in this session's commits. **Not published**: `/tmp/pocket-deploy` is a snapshot for Mark's manual `wrangler deploy` (the classifier blocks agent deploys).
- **Worker** (`worker/index.js`, `wrangler.jsonc`): `/api/guest` (10/h per IP+cookie), `/api/report` (64 KB, 5/h, `send_email` binding `REPORT_MAIL` -> RaBbLE-Collective@proton.me, rbbl_ scrubbing).
- **Pocket firmware**: Translate mode (`>mode=translate`, `>translate.lang=`), Capture/Translate mutually exclusive, offline translate refused by the outbox, `@status` reports `board`; host tests in `firmware/test/` (capture_test, score_test, voice_test; fixtures moved to `firmware/test/fixtures/`, not called clean-room).
- **sCoRE** (`RaBbLE-sCoRE/server/`): `storage.py` (SigV4 over httpx, R2 request accounting + budgets), `db.py` + `migrations/`, `snapshot.py`, `guests.py` (per-device guest accounts, shared pool + per-guest caps, Groq rolling cutoff 50%), `groqmeter.py`, `translate.py`, transcripts to R2, admin inventory/export. Last full suite before pass 3: 409 passed, 15 skipped.
- **Docs/relocation**: six Pocket docs, `cleanroom/` and six handoffs moved to `~/RaBbLE-Cleanroom/collective-docs/` (see `MOVED.md` there); public stub `RaBbLE-Pocket-Provenance.md`; golden vectors now `firmware/test/fixtures/`; README/NOTICE keep Muse SDK Apache-2.0 attribution, narrative reworded to say RaBbLE is its own product. No git history purge (Mark's call).
- **B-29** logged: Pomodoro loses its timer on sleep, alarm sound unknown (note only).
- Pulled 27 notes from the connected board (read-only) to `~/.local/share/rabble/pocket-captures/28-84-85-55-5E-B8/` with `INSPECT.md`.

## Left in the middle

1. **sCoRE fix pass 3 (blocking).** From `/tmp/rabble-crew/nibble-review2.md` (ephemeral; summary here): HIGH H1 a fallback restore leaves uploads on, then prune deletes the newest good snapshot (reproduced; `tests/test_snapshot.py` ~81-99 locks that in, rewrite it); H2 no single-writer fencing (Render deploy overlap -> two lineages, last pointer wins); H3 count-only retention too thin. Mediums: `.restore-pending` ordering, counters triggering snapshots, 503 on credential-minting writes while restore unhealthy, transcript spool not durable, late-restore merge fields. Plan given to the builder: fallback = HOLD (uploads off until admin acks, retry pointer object first, never prune keys newer than the restore source, baseline = max(pointer counts, restored counts)); generation-named snapshots + conditional PUT; tiered retention; `SNAPSHOT_ACCEPT_FALLBACK=<key>`; document Render workers/deploy overlap. Builder agent `ac1cd1c6fcc6edb4c` died on the limit (resets 5:20am America/New_York); work-so-far is what is committed. Resume via SendMessage or spawn a fresh `cobble` with this paragraph and `snapshot.py`.
2. **Re-run NiBbLE** on `snapshot.py`, `db.py`, `groqmeter.py` after pass 3; plus a CrumBbLE e2e (probes in `/tmp/rabble-crew/crumble/` may be gone). Only then cherry-pick to `release/0.1.0`.
3. **CrumBbLE relocation verification** never reported (died on the limit): re-run full host test suite (builder claims 37/37), check cwd-independence, no Grimoire paths in tests, `MOVED.md` rows, `grimoire-doctor`, broken links, stub linked.
4. **Mark's actions**: create an R2 S3-API token scoped to bucket `rabble-score` (Object Read & Write; the June "Read&Write" token is a different thing, not verified usable) and add `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` to `~/.config/rabble/pocket-companion.secrets`; Email Routing on joinrabble.world + verify RaBbLE-Collective@proton.me; run the Worker deploy; consider rotating the "Cloudflare CI" token that was printed into the transcript (comment line in `RaBbLE-Grimoire/.cloudflare/config`); read the README/NOTICE provenance wording.
5. **Mark's decisions open**: TTS for non-English translate (Groq has only English + Saudi Arabic Orpheus; proposal: speak only those, caption otherwise, second provider behind `synthesize()` later); log capture defects as blockers or fix in v0.1.1; v0.1.1 version bump (version location in firmware not found yet; `ops/release-firmware.py` takes it as an argument).
6. **Deploy order once green**: commit/cherry-pick sCoRE to `release/0.1.0` -> push (Render deploys and **wipes ephemeral disk**; accounts are cheap to recreate, no export endpoint on prod yet) -> `render-ctl env-set` R2 vars, `R2_ALLOW_FRESH_START=1` (first boot only), `TRANSCRIPT_BACKEND=r2` -> deploy Worker -> real-board flash test -> Mark re-summons his Pocket; dad's resummons on new flash. Prod Render currently changed only by env vars `GUEST_ISSUE_SECRET`, `R2_BUCKET` (effective next deploy). `GUEST_ISSUE_SECRET` is also in `~/.config/rabble/pocket-companion.secrets` (backup `.bak-s338`).
7. **Unlogged capture defects** (from the board pull, see INSPECT.md): silence hallucinations, 1969 date, duplicate outbox/shaped notes, `offloaded` never set, late sends.
8. **After v0.1.1** (Mark ruled docs wait): firmware comment pass, NeBuLA Lite page, Pocket docs/getting-started, README quickstart voice, second pass on remaining clean-room text in `log/plans` and unmoved handoffs, Pocket probe to report board in `@status`, monofirmware plan after 1.75C pins are verified (opinion given: good direction, not now).
9. Carried over: layerctl vscode (sudo), verify niri focus, fix `score-pricing.json` for 5.x models, HANDOFF-S333 items.

## Cold start

```bash
cd ~/RaBbLE-Collective/RaBbLE-sCoRE && git log --oneline -5 && .venv/bin/python -m pytest -q   # .venv exists (uv)
sed -n 1,80p server/snapshot.py                                                                  # the file under repair
```
