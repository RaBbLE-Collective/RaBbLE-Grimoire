# HANDOFF-S278 · Pocket: W7 closed; press drafts parked for Mark's review; RaBbLE-SDK next

> Written 2026-10-25 at the end of S278 for a cold start. Supersedes `done/HANDOFF-S277-Pocket-W7-Closeout.md` (W7 and the W6 watch items are done). SDK plan: `RaBbLE-Pocket/RaBbLE-Pocket-SDK-Plan.md` + `HANDOFF-S271-Pocket-Beam-SDK.md` (still current).

## Where things are

| Thing | State |
|---|---|
| RaBbLE-Pocket `new-horizons` | W7 merged (`876f7d2` untrack w2 input_test/build, `300cf7e` W7: 154 headers, rewordings, test paths, seam reconfigure when `sdkconfig.defaults` is newer, `cleanroom-overlap.py` retired). The board runs the W7 build. Not pushed anywhere (66+ ahead of origin, private repo). Perf mode was left on. |
| Grimoire | `df15123` PROVENANCE W7 row + "RaBbLE's own from the start" table, clean-room plan W0-W7 done, SDK map + Gadget-Port marked history. `e8bcd04` Pocket Roadmap from the notes. `9c7e4fe` BaBbLE intake idea. `3e8e683` Accord v2 plan + parked drafts. |
| Parked press drafts | uncommitted on purpose, first-draft quality (below) |

## Done in S278

1. **Notes triage:** 15 notes pulled over serial (sha256 verified, one-shot pyserial), 9 into the Roadmap, 1 idea to BaBbLE intake, 5 test captures discarded; all 15 then deleted from the device (count 0). Converse/Capture mode persists across an RTS reset (NVS, `678e335`).
2. **W6 watch items closed by Mark:** "feels fast and fluid, no major regressions, only the occasional screen tear, not a problem".
3. **W7 closed** by the Crew: CoBbLE built; CrumBbLE verified (build `sdkconfig.h` identical to base `3b2c358`, same 2,055,136-byte app, boots clean at 60 fps, display 403 ms, ready 3.27 s); NiBbLE no blockers (stale cached seam sdkconfig was the real `wifi_test` failure; `panel_bench` row notes Waveshare CO5300 init values, Apache-2.0 functional data, same accepted overlap as W6; overlap script exits 2 when retired). Gate: "Meta Platforms" only in the `third_party/README.md` history row.
4. **Sovereign Accord v2** parked (plan below).

## Next, in order

### (a) Mark reviews the parked press drafts
Files (all uncommitted/untracked):
- Grimoire: `RaBbLE-Pocket/RaBbLE-Pocket-Getting-Started.md` (+ its `INDEX.md` line), fixes in `RaBbLE-Pocket-Firmware-BuildFlash.md` and the `RaBbLE-Pocket-Architecture.md` status note.
- Pocket `README.md` rewrite.
- Instagram kit `RaBbLE-Xperimental/prototypes/pocket-promo/`: 11 stills 1080x1350, 3 reels 1080x1920, posting plan with reminders + shot list for Mark, `render.sh` (`out/` 23 MB generated).
- Private site `RaBbLE-Xperimental/prototypes/pocket-site/` (dev-serve at `/xperimental/prototypes/pocket-site/index.html`).

**Order: fix the renders first (clock on the face; a real Applets view), then the copy.** Known gaps:
- Renders have no clock/time on the face (the real device shows it).
- The sim shows the Settings dial for Applets (Reel 1 and carousel slide 5 mislead).
- Pomodoro drain is crossfaded stills.
- `[handle]` unknown.
- RaBbLE-Pocket is PRIVATE: the guide's clone step works for invited builders only.
- The site links to a Grimoire page not yet pushed.
- Unverified copy claims: mic only while held, Capture UI details, long-press clock, wake word/BLE still planned.
- Doc contradictions open: Beam-Protocol dev URL vs the Render URL in `sdkconfig.defaults`; Roadmap `score.joinrabble.world` vs firmware Render URL; Pocket `AGENT.md` branch `epoch/0-pocket` vs `new-horizons`; Roadmap lists Pomodoro fidget/check-in as built (TODOs `rabble_pomo.c:130-131`); World teaser headed "Summon"; Architecture body and `Hardware.md` still describe wake word/BLE; the INDEX Architecture line advertises wake word/BLE.

### (b) RaBbLE-SDK
S2 onward: `HANDOFF-S271-Pocket-Beam-SDK.md`, `RaBbLE-Pocket-SDK-Plan.md`.

### (c) Roadmap quick wins from the notes
Re-level the Orbit on open first. Others in the Roadmap: spoken voice annoys (Austin), recording stirs the mesh, backplate v4.2 print run, come back where you were.

### (d) T5 host spell `ops/pocket-notes.py`
Not built; S278 used a one-shot pyserial script.

### (e) Accord v2, when Mark picks it up
Plan `log/plans/Sovereign-Accord-v2-Brand-and-Entity.md`; drafts `RaBbLE-Collective/RaBbLE-Sovereign-Accord-v2-DRAFT.md`, `RaBbLE-Brand-and-Entity-Policy-DRAFT.md`. Decided: The RaBbLE Collective holds TM + copyright (Mark McConachie d/b/a The RaBbLE Collective); PolyForm NC as reference; register entity face and colour brand; Ohio law; forks personal or contributed back; Entity under a limited-use licence; NeBuLA free to render your own effects; current Accord reserves enough for now (no LICENSE edits). Deferred: classes/timing, CLA, fan policy, Shop creator licence, fork-face preset, Aether tokens. Registration is not required before posting: register entity art with the US Copyright Office within 3 months of first post; name clearance soon after posting starts (RABBLE filed by others in class 9: Atreum 90042611, Rabble Digital 97739617, zuMedia Inc. IR classes 9/38; live US status unverified; blocker filed). File the face in black and white first; colour claims need acquired distinctiveness.

## Pre-existing, not W7
Free heap 12,367 internal (13.2 KB in S277; same on `6c3b78b`); two boot `gpio_install_isr_service already installed` E lines; 4 host test failures (seam/beam `run.sh`: `bsp_perf.h` include; w2 input `run.sh`: `nebula_lite.h` include; w2 battery `run.sh`: LeakSanitizer persist scenario); `rabble_outbox.c:30` `s_dir[64]` truncation under host test with a long `TMPDIR`.

## Gotchas
Scouts return reports as messages, not files (GoBbLE declined a file write); long reports truncate in idle notifications, so ask for SendMessage or a scratch file.
