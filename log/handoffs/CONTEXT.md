# log/handoffs/CONTEXT.md

```
workspace: log/handoffs | epoch: 0
```

## What happens here

Cold-start handoff docs — written mid-session when work must pause and be resumed by a
fresh agent. One file per work thread. When the work is done, move to `done/`.

## Active (pending implementation)

| File | Scope |
|---|---|
| `HANDOFF-S311-Pocket-Entity-Layers-Review.md` | **Start here** for Pocket: the new core / entities / apps layers plan (`log/plans/Pocket-Core-Apps-Reorg-Plan.md`), review and confirm with Mark before any code; W9 `rabble_screen` done (not flashed); W8/W11 firewall reviews to redo; clean-room status. |
| `HANDOFF-S306-RaBbLE-UI-Micro-Mark-and-Permission-Prompt.md` | **Start here** for the Rust shell: micro mark rebuilt as the builder's glyph (9x3, gaze steps + blinks, own VSCodium grid) `28d73db`, 3-row header + usage line `c2caf0d`, wheel in permission prompt `2052401`; Mark must `/reload` and look; **permission/question prompt is broken for Mark: next session, ask him the symptom first**; Python twin not ported. |
| `HANDOFF-S304-Pocket-W10-Seam-and-Tap-to-Talk.md` | Pocket hardware-seam redesign (W10 spec REVISE), tap-to-talk `dfcb1d9` unverified on device; questions for Mark first. |
| `HANDOFF-S303-RaBbLE-UI-Compact-Mark-Crew-Viewer.md` | **Start here** for the Rust/Python shell: stream-gaze fix, Python gaze parity, compact tier + drawn micro mark, flowing wordmark (45315fa..2def318); NEXT: crew viewer (roster strip + /crew overlay, Rust first), thinking words + animation (`ui/thinking_words.txt` written, uncommitted); Mark says micro mark needs eye whites + visible portals (redesign first) |
| `HANDOFF-S302-RaBbLE-UI-Face-Gaze-Selection.md` | Superseded by S303 (read both) for the Rust shell: face void/portals/real cell aspect, gaze plumbing (pointer + entity attention), selection review fixes, commits 61e5332..eb82008; NiBbLE + CrumBbLE reviewed eb82008 (CrumBbLE holds; NiBbLE: gaze goes dark on streaming text, unfixed); Mark to eyeball /face and gaze |
| `HANDOFF-S301-RaBbLE-UI-Rust-Select-Clear.md` | Superseded by S302 (read both): mouse selection + Ctrl-C copy and `/clear` entropy reset committed (7591533..449e721, 159 Rust + 69 Python UI tests green); pending Mark trying it, CrumBbLE pty run, NiBbLE review, eyes-follow-mouse decision |
| `HANDOFF-S298-Pocket-Split-Build-Plan.md` | **Start here** for the Pocket split: build plan v0.3 (Mark's rulings, QuiBbLE-reviewed plan, P-1..P8, clean room reaches the SDK, nebula_lite as SA middleware, default pastel ellipse face); needs one more QuiBbLE pass, nothing committed |
| `HANDOFF-S298-Pocket-Open-SDK-Split.md` | Audit background for the above: provenance audit done (59.4% to 8.0% overlap vs Muse SDK), Apache SDK / Accord app split plan drafted but not Opus-reviewed, decisions D1-D5 pending Mark, gitleaks installed, nothing committed |
| `HANDOFF-S297-RaBbLE-UI-Rust-Face.md` | **Start here** for the Rust face: crate + shell wiring committed (79d2f5e..4793800), golden parity exact, 178 Rust tests green; pending Mark's eye (shared PRNG shifts the Python face), NiBbLE review, CrumBbLE real-terminal run. Other S296 items still open |
| `HANDOFF-S296-RaBbLE-UI-Rust-Phase2-Next.md` | **Start here** for the Rust TUI: lanes P/N/R/S built, Opus-reviewed and committed; `rabble` now opens the Rust shell (starts the engine on demand); Mark tests it; open: face (PRNG go), systemd + packaging, bench/CI, `RemoteBackend` wiring, shell gaps |
| `HANDOFF-S295-RaBbLE-UI-Rust-Phase2-Parallel.md` | Lane definitions for the face (F), supervision (O), bench (B) still apply; the rest is done (see S296). Original: Rust TUI: Opus review of plan + seam (2 blockers, 12 should-fix), protocol v1.1 freeze, parallel lanes (protocol hardening, shell, face, narration, supervision, bench, RemoteBackend) with file ownership and gates |
| `HANDOFF-S295-RaBbLE-UI-Rust-R1-Seam.md` | Start here for the Rust TUI: R1 engine seam (Unix socket NDJSON, `serve.py`, `rabble-proto`, fixtures/schema), lane table, wire protocol proposal, Mark's open asks (plain-English narration, CC parity) |
| `HANDOFF-S295-RaBbLE-UI-Rust-R0-Cargo.md` | Next steps for the Rust TUI: enable cargo (crates.io blocked on school network; Fedora rust-*-devel RPMs via ai-harnesses claude-code task), compile + gate R0, Option A confirmed, engine config surface + Capabilities event done, plain-English narration ask |
| `HANDOFF-S292-RaBbLE-UI-Rust-Rebuild.md` | RaBbLE-UI to Rust: start at R0 (cargo workspace, 120 fps glide spike, bench vs Python baselines); shape sign-off + Opus plan review owed; S291 visual-test results folded in |
| `HANDOFF-S291-RaBbLE-UI-Face-Visual-Test.md` | Mostly superseded by S292 (visual test run: halo fails, cell aspect 2.32); remaining unchecked items listed in HANDOFF-S292 |
| `HANDOFF-S287-RaBbLE-UI-Capability-Park-Face-Test.md` | RaBbLE-UI: capability model, park at 80%, fine eyes, scroll and modal fixes built and unit-tested; Mark tries them in a fresh `rabble`; next entropy-vs-stability split, benchmark-derived capabilities, face phase 2 |
| `HANDOFF-FCC-Free-Claude-Code.md` | FCC LiteLLM proxy tuning — research done, implementation pending |
| `HANDOFF-S236-OS-ISO-VM-Run.md` | RaBbLE-OS ISO: VM run passed S236, bare-metal retry passed S238; leftover open items inside (KS sudoers NOPASSWD revoke, GRUB secure-boot line, silent `%post`, Live ISO plan) |
| `HANDOFF-S234-EP1-Entity-Face.md` | EP1 face: W0–W2 done + live on dev; G10 sign-off pending; W4 accounts direction open |
| `HANDOFF-S278-Pocket-Press-Drafts-and-SDK.md` | Pocket W7 closed; next: Mark reviews parked press drafts (renders need the clock + real Applets view), then RaBbLE-SDK, Orbit re-level, `ops/pocket-notes.py`, Accord v2 |
| `HANDOFF-S276-EP1-Face-V1.md` | EP1 web face V1 live on dev (web-only EP1); next: Mark iPhone check, CF binding + Render env, first World main deploy |
| `HANDOFF-S279-RaBbLE-UI-U3.md` | RaBbLE-UI U1 engine + U2 face live, `rabble` flipped (`--cc` = wrapper); next: U2 review fixes, Mark daily-drives, U3 Crew as subagents |
| `HANDOFF-S273-Crew-Launcher.md` | RaBbLE Crew + `rabble` launcher built and unit-tested; first interactive team run, `layerctl apply claude-code`, colour promotion pending Mark |
| `RaBbLE-Voice-Phase2-HANDOFF.md` | Voice Phase 2 (authored 2026-07-03); the vocoder was rebuilt as v4 in S244, so check it before resuming |

## Done (reference only)

| File | Implemented |
|---|---|
| `done/HANDOFF-S275-RaBbLE-UI.md` | S279 (U1 + U2 built, superseded by HANDOFF-S279) |
| `done/HANDOFF-S277-Pocket-W7-Closeout.md` | S278 (W7 closed, W6 watch items closed by Mark) |
| `done/HANDOFF-S270-Pocket-W6-Respec.md` | S277 (W6 rev 2) |
| `done/HANDOFF-S268-Pocket-W6-Integrate.md` | S270 (parked), S277 |
| `done/HANDOFF-PreCommit-AntiClobber.md` | S185 |
| `done/HANDOFF-S116-Theme-and-Logging.md` | S116 era |
| `done/HANDOFF-S153-EP1-Coherence.md` | Production — B-01/03/04 resolved |
| `done/HANDOFF-S176-G10-World-EP1-FLOOR.md` | S177 — G10 closed (reopened S203 by the face redesign) |
| `done/HANDOFF-S203-B10-Cloudflare-Token.md` | B-10 resolved S206, B-12 S234 |
| `done/HANDOFF-S267-Pocket-CleanRoom-Final-SDK.md` | S268: W6 spec/firewall/implementer started; superseded by HANDOFF-S268 (its W7 list and SDK plan still current) |
| `done/HANDOFF-S266-Pocket-Orbit-Pomodoro.md` | S267: Orbit v2 landed; superseded by HANDOFF-S267 |
| `done/HANDOFF-S265-Pocket-Capture-T5.md` | S266: superseded (T5/T6 carried into HANDOFF-S266) |
| `done/HANDOFF-S264-Pocket-Capture-W4-Face.md` | S265: T3 store, T4 modes, sCoRE pushed (continues in HANDOFF-S265) |
| `done/HANDOFF-S252-Pocket-Settings-Orientation-Clean-Room.md` | S254 settings composited; clean room W0-W4 by S264 (continues in HANDOFF-S264) |
| `done/HANDOFF-S251-Pocket-Entity-60fps.md` | S252: 60 fps idle (both cores, damage-skipped bands, sparse mesh); settings slide carried into the S252 handoff |
| `done/HANDOFF-S250-Pocket-Entity-Port-Phase1.md` | S251 (Phase 1 renderer on device; superseded by S251 handoff) |

## Convention

`git mv log/handoffs/HANDOFF-FOO.md log/handoffs/done/HANDOFF-FOO.md` when work is complete.
Update `INDEX.md` and note the session it was implemented in.
