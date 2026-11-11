# log/handoffs/CONTEXT.md

```
workspace: log/handoffs | epoch: 0
```

## What happens here

Cold-start handoff docs — written mid-session when work must pause and be resumed by a
fresh agent. One file per work thread. When the work is done, move to `done/`.

## Active (pending implementation)

Re-triaged S320 from the S318 audit (`log/plans/Collective-Coherency-Audit-S318/audit-plans-roadmap.md` 1c). Superseded and finished handoffs moved to `done/` with a status banner on line 1; none deleted.

- `HANDOFF-S323-Genesis-Release.md`: every member to `0.1.0` on `main` under the `genesis` tag. Phase 1 local preparation in progress (2026-11-11); phase 2 needs Mark.

| File | Status | Scope |
|---|---|---|
| `HANDOFF-S318-Collective-Coherency.md` | LIVE | **Start here** for the Collective cleanup: D3 Episodes retirement, roadmap, Ansible fixes, plans archive, log split, brand spec (D6 ruled S320) |
| `HANDOFF-S312-Pocket-Clean-Room-W8-W11-Implement.md` | LIVE | **Start here** for Pocket: layers plan confirmed, W8/W11 merged S314; open: gitleaks scan then commit the hold-outs (item 4) |
| `HANDOFF-S309-RaBbLE-UI-Micro-Mark-Pills-and-Gaze.md` | LIVE | **Start here** for the Rust shell look: micro mark pills, glance, pointer-exit; never seen live; up-gaze centre shift unanswered |
| `HANDOFF-S307-RaBbLE-UI-Crew-Views-and-Picker.md` | LIVE | Rust shell picker, crew views, crew rules; tests green, never run live; questions for Mark |
| `HANDOFF-S306-RaBbLE-UI-Micro-Mark-and-Permission-Prompt.md` | LIVE | Micro mark as builder's glyph, 3-row header; **permission/question prompt broken for Mark: ask him the symptom first** |
| `HANDOFF-S297-RaBbLE-UI-Rust-Face.md` | LIVE | Rust face crate, golden parity; pending Mark's eye, NiBbLE review, CrumBbLE real-terminal run |
| `HANDOFF-S296-RaBbLE-UI-Rust-Phase2-Next.md` | LIVE | Rust TUI phase 2: open shell gaps, Lane O (supervision), Lane B (bench), `RemoteBackend` wiring. Lane definitions: `done/HANDOFF-S295-RaBbLE-UI-Rust-Phase2-Parallel.md` |
| `HANDOFF-S290-Anti-Clobber-Sessions.md` | LIVE | Anti-clobber mechanism installed + sandbox-tested; needs a second live session and a real codex/gemini run |
| `HANDOFF-S276-EP1-Face-V1.md` | LIVE | Web face V1, now prod (S318); B-20 leftovers (Render env, live guest chat reply) |
| `HANDOFF-S271-Pocket-Beam-SDK.md` | LIVE | Pocket beam via laptop node, SDK S2 onward still current per HANDOFF-S278 |
| `HANDOFF-S236-OS-ISO-VM-Run.md` | LIVE | OS ISO leftovers: KS sudoers NOPASSWD revoke (still at `RaBbLE-OS.ks:143`), GRUB secure-boot line, silent `%post`, Live ISO plan |
| `HANDOFF-S286-Pocket-Internal-RAM.md` | PARKED | Internal-RAM recovery (M1); owner Mark; B-22 |
| `HANDOFF-S281-Pocket-Parity-Sim-Shot-Gate.md` | PARKED | `>shot`, parity sim scaffold only, no shot renders |
| `HANDOFF-S278-Pocket-Press-Drafts-and-SDK.md` | PARKED | Mark reviews the parked press drafts, then SDK, Orbit re-level, Accord v2 |
| `RaBbLE-Voice-Phase2-HANDOFF.md` | PARKED | Voice Phase 2 (2026-07-03); vocoder rebuilt as v4 in S244, check before resuming |
| `HANDOFF-S280-Pocket-Firmware-Test-Suite.md` | STALE? | Comprehensive firmware test suite, parked S280; paths predate the S314 Pocket restructure |
| `HANDOFF-FCC-Free-Claude-Code.md` | STALE? | FCC proxy tuning; research only, crash-loop fixed S240, tuning never evidenced |

`HANDOFF-parked-*.md` (15 files, 400 bytes of `x`, untracked): placeholder noise, awaiting Mark's yes before deletion.

## Done (reference only)

| File | Implemented |
|---|---|
| `done/HANDOFF-S311-Pocket-Entity-Layers-Review.md` | S312: review done (COMPLETE) |
| `done/HANDOFF-S308-Pocket-Foundling-Open-App.md` | Superseded by `log/plans/Pocket-Foundling-Open-App-Plan.md`; landed S316 |
| `done/HANDOFF-S304-Pocket-W10-Seam-and-Tap-to-Talk.md` | Superseded: W10 replaced by W11 (S311/S312) |
| `done/HANDOFF-S303-RaBbLE-UI-Compact-Mark-Crew-Viewer.md` | Superseded by S306 |
| `done/HANDOFF-S302-RaBbLE-UI-Face-Gaze-Selection.md` | Superseded by S303 |
| `done/HANDOFF-S301-RaBbLE-UI-Rust-Select-Clear.md` | Superseded by S302 |
| `done/HANDOFF-S298-Pocket-Split-Build-Plan.md` | Superseded by `log/plans/Pocket-Core-Apps-Reorg-Plan.md` (S311) |
| `done/HANDOFF-S298-Pocket-Open-SDK-Split.md` | Superseded by S298 Split-Build-Plan |
| `done/HANDOFF-S295-RaBbLE-UI-Rust-R1-Seam.md` | Superseded by S295 Phase2-Parallel; seam gate met |
| `done/HANDOFF-S295-RaBbLE-UI-Rust-R0-Cargo.md` | COMPLETE: R0 committed (sCoRE `c99ef94`) |
| `done/HANDOFF-S295-RaBbLE-UI-Rust-Phase2-Parallel.md` | Superseded by S296 as start point; lane definitions still referenced |
| `done/HANDOFF-S292-RaBbLE-UI-Rust-Rebuild.md` | Superseded by S295 R0/R1/Phase2 |
| `done/HANDOFF-S291-RaBbLE-UI-Face-Visual-Test.md` | Superseded by S292 |
| `done/HANDOFF-S287-RaBbLE-UI-Capability-Park-Face-Test.md` | Superseded by the S291/S292 Rust track |
| `done/HANDOFF-S286-Pocket-Release-Entities.md` | Superseded by S286 Opus-Review-and-Open-SDK |
| `done/HANDOFF-S286-Pocket-Opus-Review-and-Open-SDK.md` | Superseded by S298 Open-SDK-Split (review done) |
| `done/HANDOFF-S285-RaBbLE-UI-Live-Test-2.md` | Superseded by S287 |
| `done/HANDOFF-S284-RaBbLE-UI-Live-Test.md` | Superseded by S285 |
| `done/HANDOFF-S279-RaBbLE-UI-U3.md` | Superseded by the S284 to S292 track |
| `done/HANDOFF-S273-Crew-Launcher.md` | COMPLETE: built `83280d0`, first run S276; colour promotion was still pending Mark |
| `done/HANDOFF-S234-EP1-Entity-Face.md` | Superseded by S276 (face) |
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

`git mv log/handoffs/HANDOFF-FOO.md log/handoffs/done/HANDOFF-FOO.md` when work is complete or superseded.
Put a `> **Status (Snnn, date): COMPLETE / SUPERSEDED by ...**` banner on line 1 first. Never delete a handoff.
Update `INDEX.md` and note the session it was implemented in.
