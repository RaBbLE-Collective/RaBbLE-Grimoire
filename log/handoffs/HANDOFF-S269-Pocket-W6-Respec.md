# HANDOFF-S269 · Pocket: W6 band engine re-spec (parked), then W7, then the RaBbLE-SDK

> Written 2026-10-23 in S269 for a cold start. Supersedes `HANDOFF-S268-Pocket-W6-Integrate.md` (move it to `done/`). The S267 handoff's **W7 list and RaBbLE-SDK plan are still current** (`done/HANDOFF-S267-Pocket-CleanRoom-Final-SDK.md`, sections 2 and 3).
> Read first: this file, `RaBbLE-Pocket/cleanroom/w6-board.spec.md` **section 13** (what five rounds taught), `RaBbLE-Pocket/RaBbLE-Pocket-Clean-Room-Plan.md` (Roles).

## Where things are

| Repo | Branch | State |
|---|---|---|
| RaBbLE-Pocket | `new-horizons` `4624c56` | stable: old board layer + S269 work. **Flashed: `c698884`** (same firmware; `4624c56` only adds the datasheets README). Not pushed |
| RaBbLE-Pocket | `w6-integration-wip` `a3b436e` | **parked** W6 integration at round 5 (crashes, tears). Not for `new-horizons` |
| Clean workspace | `~/RaBbLE-Cleanroom/pocket-w6` | rounds 1-5 in its git (`b98ad64` … `8558405`); `FAILURES-1..4.md` are what the implementer was told |
| Transcripts | `~/RaBbLE-Cleanroom/transcripts/w6/` | `implementer.jsonl` (round 1), `implementer-r2.jsonl` (rounds 2-5, one resumed agent); all audited, flags benign |

## Done in S269

1. **Pomodoro back chip** pointed the wrong way: Applets now reads `face >` (Pocket `c27a91d`). Mark's full Pomodoro hand check is still open.
2. **Offline voice notes on flash** (Pocket `c698884`): new `accord/rabble_outbox.c/.h` (own task, internal stack, priority 1; the voice task's PSRAM stack can't touch flash), IMA ADPCM under `/pocket/outbox`, queue rebuilt at boot, the reply still plays, and once sCoRE has heard it only the transcript stays (`type: pocket-note`, `kind: voice-note`). The beam keeps each turn's whole transcript (`rabble_beam_turn_heard`). `>outbox` lists them. Tests: `firmware/test/outbox_test/run.sh` (39 checks); W4 voice vectors unchanged. Hand-checked: offline → reboot → online. Note: a quiet (asleep) send waits past `sent` for `heard`, since sCoRE sends `heard` after `sent`. A saved note that keeps failing is still given up after 8 tries (audio deleted): Mark hasn't been asked whether flash notes should ever give up.
3. **W6 integration, 5 rounds, parked**: see spec section 13. The board table and display bring-up pass; the two-core band engine doesn't (tearing while turning, a notify assert that crashes it). `>perf` lives in `accord/rabble_input.c` with a hook set from `main/app_main.c` (on the parked branch).
4. Spec 6.3.2 clarified (every frame waits its edge); section 13 added.

## Next, in order

1. **Mark's open hand checks on the stable build:** Pomodoro (swipe right, hold the centre to start, `>pomo=skip`, back with a swipe left and with the chip).
2. **W6 revision** (Mark chose "park + re-spec"):
   - S: rewrite 6.3/6.4 from section 13 as outcomes (who reads `bsp/` is S/F/G, never I). Keep round 3's board table and display bring-up: in the new workspace, start from round 3's `bsp_waveshare_175b.c`, `bsp_display.c/.h`, `bsp_texture.c` and a band engine to be written.
   - F: fresh Opus firewall over the revision.
   - I: a fresh **Opus** implementer (not Sonnet: five Sonnet rounds regressed), new workspace, the failure history given as behaviour.
   - G: A/B against the old layer on the same gadget; diagnostic builds that change one thing, never committed. Gates: no tearing at any orientation (Orbit open, face), no crash over a soak (turning, Orbit open/close, three voice turns, sleep/wake cycles), 60 fps idle, ≥ 30 busy, Orbit slide ≥ 40, the mesh slide looking like the old layer.
3. Then the overlap gate, PROVENANCE row, config trims (8.3, Mark's ok) and the console path (USB Serial/JTAG primary, UART0 off; Mark's ok), then W7 and the SDK.

## Gotchas (new in S269)

- **The console needs a `>` prefix.** Bare letters are bench keys: `d`/`u` push-to-talk, `c` chirp, `z`/`w` sleep/wake. Typing `outbox` without `>` sent a PTT up.
- The serial logger resets the gadget when it opens the port; `pkill -f "serlog.p[y]"` in its own call (exit 144 is expected).
- **A `git commit` after `git rm` takes the staged deletions with it**, even if you only `git add` one file: check `git status` before every commit during an integration.
- An Orbit at rest is only "at rest" if nobody is holding the gadget: rolls re-render the Orbit.
- Internal RAM: 14.7 KB free after boot on the stable build (the outbox task took ~4.5 KB of the 20.5 KB).
- Grimoire: another session had `RaBbLE-Pocket-Beam-Protocol.md`, `RaBbLE-Pocket-Roadmap.md`, `SESSION-LOG.md` and a new sCoRE local-beam doc open in the tree; S269 didn't touch or stage them.
