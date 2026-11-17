# Coherency audit: plans, handoffs, roadmaps, episode model
GoBbLE scout · read-only · 2026-11-06 · session context S317 (SESSION-LOG LATEST, line 8)
Scope: `RaBbLE-Grimoire/log/plans/`, `log/handoffs/`, roadmaps, `registry/epochs/current.epoch.yml`, `log/EP1-AIR-CHECKLIST.md`, `AGENT.md` Current State, `RaBbLE-Versioning.md`, `log/episodes/`. Nothing edited. Only `/tmp/rabble-crew/` written.

Method. Status per doc = its own header, then the session log (`log/SESSION-LOG.md`, read by grep/awk only, never whole), then git in the relevant member. Session "evidence" = the SESSION-LOG heading line that proves the claim. Where a doc's own header disagrees with the commit log, the commit wins and the header is flagged stale. Status key: DONE · SUPERSEDED (named by what) · LIVE · PARKED · UNKNOWN.

Helpers (kept outside the repo): `/tmp/rabble-crew/scout/trace.sh`, `sess.sh`, `refcheck.sh`, `index-missing.txt`.

---

## 1. PLAN TRIAGE

Counts: plans on disk 30 (LIVE 13 · PARKED 10 · SUPERSEDED 3 · UNKNOWN 3 · DONE 1). Plans in done/ 9 (DONE). Root handoffs 37 (LIVE 10 · SUPERSEDED 18 · PARKED 4 · UNKNOWN 2 · DONE 3). Handoffs in done/ 16 (DONE). Parked placeholders 15 (noise, origin UNKNOWN). Totals with CONTEXT.md excluded.

### 1a. `log/plans/` (not done/): 30 plans

| File | Status | Evidence |
|---|---|---|
| Aether-Theming-Convergence.md | SUPERSEDED (by OS-Theming-Variants-Plan, itself PARKED) | `plans/CONTEXT.md:33` says A1-A3 absorbed by OS-Theming-Variants Phase 2; authored S184 (SESSION-LOG:2361) |
| Brand-Asset-Consolidation-PROPOSAL.md | LIVE | "proposal only, nothing moved", raised 2026-11-06 (line 7). UNTRACKED in git (`git status ??`). Not in plans/CONTEXT or INDEX |
| Collective-Architecture-Audit-2026-07-04.md | DONE (reference) | "Status: complete" (line 3); run S193 (SESSION-LOG:2192). Open items live in PROGRESS |
| Collective-Architecture-Audit-PROGRESS.md | PARKED | Header "Batch 1 in flight" since 2026-07-05 (line 4); only S196 mention (SESSION-LOG:2164); last commit 6c3073d 2026-07-05. Decisions "deferred" (line 4) |
| Collective-ICM-Conformance-Audit.md | PARKED | "AUDIT COMPLETE … No tree changes yet" (line 7); "3 open decisions for Mark" (`plans/CONTEXT.md:42`); last session S225 (SESSION-LOG:1611) |
| EP1-Air-Push-Plan.md | LIVE (stale) | "A5 … C1 remain" (`plans/CONTEXT.md:22`); last session mention S203 (SESSION-LOG:2074); no later session touches it |
| EP1-Entity-Face-Plan.md | LIVE | "G10 sign-off pending" (line 8); G10 still open (EP1-AIR-CHECKLIST.md:33); face V1 S276 (SESSION-LOG:502) |
| EP1-Staging-and-Grimoire-Audit.md | LIVE | Header S248, D1/D3 open (line 3); public face still open (RaBbLE-Roadmap.md:73). Only S248 names it (SESSION-LOG:984) |
| EP2-Accounts-Encryption-Spec.md | PARKED | "Status: Draft" (line 3); only mention S233 (SESSION-LOG:1501); no code (EP2 item, RaBbLE-Post-EP1-Roadmap.md:88) |
| NeBuLA-Pocket-Puppet-Rendering-Pipeline.md | PARKED | Research, no status line; only mention S233 (SESSION-LOG:1503); last commit c925e44 2026-09-26 |
| Open-Layer-and-Positioning-Notes-2026-11-02.md | LIVE (open decisions) | "decided / leaning / open" markers (line 3); committed d57c7bc 2026-11-04 but absent from plans/CONTEXT and INDEX |
| OS-Boot-Chain-Seamless-Plan.md | UNKNOWN | Index says "awaits reboot verify" (`plans/CONTEXT.md:28`); S226 boot log confirmed amdgpu fix (plan lines 5-7); S173 says "boot chain closed for EP1" (SESSION-LOG:2510). Sources conflict; no real-HW verify record found |
| OS-Display-Manager-Plan.md | LIVE (header stale) | Header says "uncommitted" (line 3), but RaBbLE-OS has commits a97df61, 500bfd9, c733278, 950fe7f, 0f40e83 (2026-10-13, S246). Still open: dotctl persistence, Ansible role (no rdisplay role under RaBbLE-OS/ansible), GNOME/KDE backends |
| OS-Install-Editions-Plan.md | LIVE (header stale) | Header "Not started … ready for W1" (line 3). W1 landed: RaBbLE-OS 532e704 (2026-10-29, `%S290_EDITIONS%`, `edition:` on manifest entries + edition-audit.sh). W2-W4 open (plan Part C, lines 142-154) |
| OS-Plymouth-Black-Screen.md | UNKNOWN | Header "AWAITING visual verify" (line 3); S226 note says root cause fixed S166 (line 5); S173 "boot chain closed" (SESSION-LOG:2510). No photo or boot log for the verify step found |
| OS-ProArt-Power-Stack-Plan.md | LIVE | "awaits Mark's on-hardware reboot verification" (line 3); reworked S245, commit 35b1953; PL values unmeasured (memory project_proart_power_stack_asusd_only) |
| OS-Settings-App-Plan.md | PARKED | "SKETCH — design only, not started" (line 3); display manager is its first piece (SESSION-LOG:1006, S246) |
| OS-Theming-Variants-Plan.md | PARKED | Design only, "awaiting Mark's calls" (plan header, S204, last commit 2b9d46b 2026-07-28); RaBbLE-OS-Roadmap.md:192 "needs a deterministic plan" |
| OS-VM-Dev-Flow.md | UNKNOWN | "PART 1 DONE … PARTS 2 & 3 PENDING" (line 3). No cast-vm spell in RaBbLE-OS or Grimoire spells/. RaBbLE-OS/spells/vm-boot-iterate.sh exists; relation to "build-loop spell" not verified |
| Pocket-Core-Apps-Reorg-Plan.md | LIVE (header stale) | Header "DRAFT v2 … Nothing is implemented" (line 3). RaBbLE-Pocket d814d3b (S314, "R1 pure move") and 2be2842 / 6cf1404 (S316 Foundling fold). Handoff S312 says W9 done |
| Pocket-Foundling-Open-App-Plan.md | LIVE | "DRAFT v0.2" (line 3); open_entity_default folded into Foundling, RaBbLE-Pocket 6cf1404 (S316); done/not-done ledger inside |
| Pocket-Open-SDK-App-Separation-Plan.md | SUPERSEDED (by Pocket-Core-Apps-Reorg-Plan, S311, and HANDOFF-S298-Pocket-Split-Build-Plan) | Reorg plan line 3: "Replaces the sdk/app split inside Pocket-Open-SDK-App-Separation-Plan.md"; `plans/CONTEXT.md:41` names the S298 build plan |
| Pocket-Parity-Sim-Spec.md | PARKED | S281 scaffold only, "no shot renders" (HANDOFF-S281); no session after S281 names parity (SESSION-LOG:421 only); last commit 34cfd8a 2026-10-25 |
| Pocket-Release-Entities-Companion-Plan.md | PARKED | v0.3, decided S286 (lines 7-9). No Tauri or companion code in RaBbLE-Pocket (grep empty). Pocket-Roadmap.md:40-46 EP1 items unchecked. Not indexed in plans/CONTEXT |
| Pocket-Seam-Slot-LVGL-Design-Note.md | LIVE (folded into W11) | "ADOPTED by Mark, 2026-11-05" (line 3); RaBbLE-Pocket 2f5ba44 (S314) "LVGL moved to an interim glue". Not indexed |
| sCoRE-Extensibility-Refactor-Plan.md | PARKED | "proposed, design only" (line 3); only S193 (SESSION-LOG:2193); CONTEXT.md:36 "post-air" |
| sCoRE-RaBbLE-UI-Plan.md | SUPERSEDED (by sCoRE-RaBbLE-UI-Rust-Plan, S292) | `plans/CONTEXT.md:37-38`; U1+U2 DONE (header line 3: engine fb80966, face a6a46be, S279) |
| sCoRE-RaBbLE-UI-Rust-Plan.md | LIVE (header stale) | Header "proposed, S292 … needs Mark's sign-off before R1" (line 3). R1 seam gate met in S295 (HANDOFF-S295-RaBbLE-UI-Rust-R1-Seam, status section; commit d8570e9); phase-2 lanes built S296 (HANDOFF-S296 header) |
| Sovereign-Accord-v2-Brand-and-Entity.md | PARKED | "rest deferred" (`plans/CONTEXT.md:40`); memory note "v2 parked S278". No session beyond S278 |
| Subdomain-Registry-and-Maintenance.md | LIVE (spec implemented) | `registry/subdomains.yml` exists (117 lines); only S185/S186 mentions (SESSION-LOG:2338). Maintenance backlog not verified |

### 1b. `log/plans/done/`: 9 plans, all DONE
World-Framework-Refactor.md, World-Framework-Refactor-API.md, World-Framework-Refactor-HANDOFF.md, harvest-map.md, harvest-map-effects.md (S182); NeBuLA-Studio-Plan.md (S198); OS-Dolphin-Grey-Text.md (S201); EP1-Liminal-Experience-Plan.md (retired S203, frozen in Chrysalis); Collective-Architecture-Audit-Plan.md (S193). `done/CONTEXT.md` lists them; the index in `plans/CONTEXT.md:50-56` agrees.

### 1c. `log/handoffs/` (root, non-parked): 37 handoffs

| File | Status | Evidence |
|---|---|---|
| HANDOFF-FCC-Free-Claude-Code.md | UNKNOWN | "Research only. No config changed yet" (line 2). Later FCC crash-loop fix in a session at SESSION-LOG:1198 (S240 per memory project_fcc_upstream_gotchas); tuning and backoff not evidenced |
| HANDOFF-S234-EP1-Entity-Face.md | SUPERSEDED (by HANDOFF-S276-EP1-Face-V1 for the face) | G10 sign-off still open (EP1-AIR-CHECKLIST.md:33) |
| HANDOFF-S236-OS-ISO-VM-Run.md | LIVE | Leftover "KS sudoers NOPASSWD never revoked" still present: RaBbLE-OS/RaBbLE-OS.ks:143 `NOPASSWD: ALL`. GRUB and %post leftovers not checked |
| HANDOFF-S271-Pocket-Beam-SDK.md | LIVE | HANDOFF-S278 line 40: "S2 onward: HANDOFF-S271-Pocket-Beam-SDK.md … still current" |
| HANDOFF-S273-Crew-Launcher.md | DONE (colour promotion item UNKNOWN) | Launcher built (commit 83280d0, 2026-10-24); first run S276 (memory project_rabble_crew_personas). "Colour promotion pending Mark" not verified |
| HANDOFF-S276-EP1-Face-V1.md | LIVE | B-19 (setup.sh 404) and B-20 (CF binding, Render env) open (BLOCKERS.md:17-18); World main stub noted SESSION-LOG:502 |
| HANDOFF-S278-Pocket-Press-Drafts-and-SDK.md | PARKED | "Mark reviews the parked Pocket press drafts"; memory project_pocket_press_drafts PARKED S278 |
| HANDOFF-S279-RaBbLE-UI-U3.md | SUPERSEDED (by HANDOFF-S284 → S285 → S287 → S292 Rust track) | S284 "Read first: HANDOFF-S279"; U3 not named done in any later doc |
| HANDOFF-S280-Pocket-Firmware-Test-Suite.md | UNKNOWN | SESSION-LOG:441 says `firmware/test/run.sh` is the suite entry point; SESSION-LOG:443 says "comprehensive test suite parked". Pocket restructured S314 (d814d3b), path needs check |
| HANDOFF-S281-Pocket-Parity-Sim-Shot-Gate.md | PARKED | "Scaffold only; no shot renders" (table row); no later session (SESSION-LOG:421 only) |
| HANDOFF-S284-RaBbLE-UI-Live-Test.md | SUPERSEDED (by HANDOFF-S285) | S285 header: "Supersedes the 'test' half of HANDOFF-S284" |
| HANDOFF-S285-RaBbLE-UI-Live-Test-2.md | SUPERSEDED (by HANDOFF-S287) | S287 header: "Supersedes the 'test' half of HANDOFF-S285" |
| HANDOFF-S286-Pocket-Internal-RAM.md | PARKED | "Owner: Mark (he said he will do the hunt)"; no measurement record. B-22 still open (BLOCKERS.md:20) |
| HANDOFF-S286-Pocket-Opus-Review-and-Open-SDK.md | SUPERSEDED (by HANDOFF-S298-Pocket-Open-SDK-Split / Split-Build-Plan) | Opus review done (Pocket-Release-Entities plan line 7, "Opus-reviewed twice"); the open-SDK job moved on in S298 |
| HANDOFF-S286-Pocket-Release-Entities.md | SUPERSEDED (by HANDOFF-S286-Pocket-Opus-Review-and-Open-SDK) | Own line 3: "Next two jobs, in order: HANDOFF-S286-Pocket-Opus-Review…" |
| HANDOFF-S287-RaBbLE-UI-Capability-Park-Face-Test.md | SUPERSEDED (by HANDOFF-S291 → S292 Rust track) | Python TUI replaced: `rabble` opens the Rust shell (AGENT.md:17; HANDOFF-S296) |
| HANDOFF-S290-Anti-Clobber-Sessions.md | LIVE | Mechanism installed; "needs live codex/gemini/2nd-session test" (memory project_anti_clobber_sessions) |
| HANDOFF-S291-RaBbLE-UI-Face-Visual-Test.md | SUPERSEDED (by HANDOFF-S292) | `plans/CONTEXT.md` handoff index line 30: "Mostly superseded by S292" |
| HANDOFF-S292-RaBbLE-UI-Rust-Rebuild.md | SUPERSEDED (by HANDOFF-S295-…-R0-Cargo / R1-Seam / Phase2-Parallel) | Own header: "Do not start R1 until Mark signs off"; R0 and R1 later done (see below) |
| HANDOFF-S295-RaBbLE-UI-Rust-Phase2-Parallel.md | SUPERSEDED for next steps (by HANDOFF-S296-…-Phase2-Next); lane definitions still referenced | HANDOFF-S296 header: "Supersedes … as the place to start" |
| HANDOFF-S295-RaBbLE-UI-Rust-R0-Cargo.md | DONE | HANDOFF-S295-R1-Seam header: "R0 is done and committed"; RaBbLE-sCoRE c99ef94 |
| HANDOFF-S295-RaBbLE-UI-Rust-R1-Seam.md | SUPERSEDED (by Phase2-Parallel for next steps); seam gate MET | Own header line 3: "Superseded for next steps by …Phase2-Parallel"; "R1 STATUS: the seam gate is MET" |
| HANDOFF-S296-RaBbLE-UI-Rust-Phase2-Next.md | LIVE | Open: shell gaps, Lane O, Lane B, RemoteBackend wiring (own item 1); face handed to S297 |
| HANDOFF-S297-RaBbLE-UI-Rust-Face.md | LIVE | "parked"; open: Mark's eye on the face, NiBbLE review, CrumBbLE real-terminal run; S301 "items 4-6 still stand" |
| HANDOFF-S298-Pocket-Open-SDK-Split.md | SUPERSEDED (by HANDOFF-S298-Pocket-Split-Build-Plan) | Build-plan header: "Supersedes the 'Next steps' of HANDOFF-S298-Pocket-Open-SDK-Split" |
| HANDOFF-S298-Pocket-Split-Build-Plan.md | SUPERSEDED (by Pocket-Core-Apps-Reorg-Plan, S311) | Reorg plan line 3 replaces the sdk/app split; S311 handoff names the W-series as the track. P-series never closed out |
| HANDOFF-S301-RaBbLE-UI-Rust-Select-Clear.md | SUPERSEDED (by HANDOFF-S302) | `plans/CONTEXT.md` handoff index line 21: "Superseded by S302" |
| HANDOFF-S302-RaBbLE-UI-Face-Gaze-Selection.md | SUPERSEDED (by HANDOFF-S303) | `handoffs/CONTEXT.md:20`: "Superseded by S303" |
| HANDOFF-S303-RaBbLE-UI-Compact-Mark-Crew-Viewer.md | SUPERSEDED (by HANDOFF-S306) | S306 header: "Continues HANDOFF-S303" |
| HANDOFF-S304-Pocket-W10-Seam-and-Tap-to-Talk.md | SUPERSEDED (by W11, S311/S312) | HANDOFF-S311 line: "W10 is superseded by W11" |
| HANDOFF-S306-RaBbLE-UI-Micro-Mark-and-Permission-Prompt.md | LIVE | "permission/question prompt is broken for Mark: next session, ask him the symptom first" (`handoffs/CONTEXT.md:17`) |
| HANDOFF-S307-RaBbLE-UI-Crew-Views-and-Picker.md | LIVE | Line 3: "Tests green, release built, never run live"; open questions for Mark |
| HANDOFF-S308-Pocket-Foundling-Open-App.md | SUPERSEDED (by Pocket-Foundling-Open-App-Plan) | Header: "Read `log/plans/Pocket-Foundling-Open-App-Plan.md` first: done / not-done ledger"; landed in 6cf1404 (S316) |
| HANDOFF-S309-RaBbLE-UI-Micro-Mark-Pills-and-Gaze.md | LIVE | Line 3: "never seen live"; open: up-gaze centre shift unanswered |
| HANDOFF-S311-Pocket-Entity-Layers-Review.md | DONE | HANDOFF-S312 line 3: "Replaces the review job in HANDOFF-S311 (done)" |
| HANDOFF-S312-Pocket-Clean-Room-W8-W11-Implement.md | LIVE (partly executed) | W8/W11 merged S314 (SESSION-LOG:49-52); S315/S316/S317 follow; open: gitleaks scan then commit hold-outs (its item 4) |
| RaBbLE-Voice-Phase2-HANDOFF.md | PARKED | Authored 2026-07-03 (SESSION-LOG:2298, S189 only); header says "check it before resuming" because vocoder v4 landed S244 (memory project_voice_vocoder_v4) |

### 1d. `log/handoffs/done/`: 16 files, all DONE
Filed in done/ and indexed in `handoffs/CONTEXT.md` (lines 43-60). No gaps found.

### 1e. `HANDOFF-parked-*.md`: 15 files, placeholder noise
- All 15 are untracked (`git status ??`), none in git history, each exactly 400 bytes of the letter `x` (0 non-x bytes, checked with `tr -d x`).
- Named `HANDOFF-parked-<date>-<time>-session.md`, dated 2026-11-03 13:07 to 2026-11-04 03:44.
- No writer in the repo: `grep` of `spells/`, `hooks/`, `spells/hooks/`, `spells/install-hooks.sh` finds nothing. Writer UNKNOWN.
- The S312 handoff already calls them "`HANDOFF-parked-*` placeholders (400 bytes of `x`) safe to delete, ask" (HANDOFF-S312, item 4).
- Transcripts show them in `ls` output from 2026-11-04 01:53 (`~/.claude/projects/-home-rabble-RaBbLE-Collective/*.jsonl`). Not auto-generated by any script we could find, so they are noise, origin UNKNOWN.

### 1f. Index integrity

| Index | Problem | Where |
|---|---|---|
| `log/plans/CONTEXT.md` | Refs all exist. Five plans on disk not listed: Brand-Asset-Consolidation-PROPOSAL, Open-Layer-and-Positioning-Notes-2026-11-02, Pocket-Parity-Sim-Spec, Pocket-Release-Entities-Companion-Plan, Pocket-Seam-Slot-LVGL-Design-Note | `plans/CONTEXT.md` (no row) |
| `log/handoffs/CONTEXT.md` | Refs resolve except `serve.py` (:27), `ops/pocket-notes.py` (:35), and `HANDOFF-FOO.md` placeholder (:64). Locations of serve.py and pocket-notes.py not found under the Grimoire, probably other repos (not checked). 13 non-parked handoffs not listed (HANDOFF-S271, S280, S281, S284, S285, S286 ×3, S290, S307, S308, S309, S312) plus the 15 parked files (28 total) | `handoffs/CONTEXT.md` |
| `handoffs/CONTEXT.md` "Active" table | Lists handoffs its own rows mark superseded: S301 (line 21) and S302 (line 20) under "Active (pending implementation)"; also S291 (line 30) "Mostly superseded" | `handoffs/CONTEXT.md:14-40` |
| `plans/CONTEXT.md` | Row for OS-Install-Editions says "🔵 design, ready for W1" (line 31) while W1 landed (532e704) | `plans/CONTEXT.md:31` |
| Grimoire `INDEX.md` | Refs resolve except `log/handoffs/HANDOFF-S268-Pocket-W6-Integrate.md` (line 358). That file is in `handoffs/done/`, and the entry describes it as current ("next integrate") | `INDEX.md:358` |
| Grimoire `INDEX.md` | Not indexed: 6 plans (incl. Pocket-Core-Apps-Reorg-Plan, S311, the current Pocket plan; Pocket-Foundling-Open-App-Plan) and 26 handoffs incl. done/ (incl. S296-S312 live-track handoffs) | `INDEX.md:313-368` |
| Grimoire `INDEX.md` Genesis section | Lists 4 docs "to be authored — Phase 2C" (`RaBbLE-Origin.md`, `-Lineage.md`, `-Visual-Evolution.md`, `-Collaborators.md`, `-Symbiosis.md`). Flagged as planned, so not a broken link | `INDEX.md:412-419` |
| Grimoire `INDEX.md` | Other unresolved refs are spells/ paths (promote-insight.sh, mine.sh, graph-grimoire.sh, grimoire-doctor.sh exist in spells/). Not broken | `INDEX.md:14, 309-311, 345` |
| Stale internal paths | `RaBbLE-Post-EP1-Roadmap.md:5,17,30,117,119` point to `log/EPISODE-1-RELEASE.md` (now `log/episodes/`), `log/FABLE-GAP-ANALYSIS-S57.md` (now `log/archive/`), `log/SESSION-LOG-S138-local-arch.md` (now `log/archive/`), `log/HANDOFF-PreCommit-AntiClobber.md` (now `log/handoffs/done/`). `spells/hooks/pre-commit:50` also cites the old HANDOFF path | as cited |

Plan and handoff totals (1a-1d, excl. parked noise): 30 plans + 9 done plans; 37 root handoffs + 16 done handoffs; 15 parked placeholders.

---

## 2. ROADMAP CONTRADICTIONS

Docs compared: `RaBbLE-Agent/RaBbLE-Roadmap.md` (Roadmap), `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md` (Post-EP1), `gist/RaBbLE-Roadmap-gist.md`, `log/EP1-AIR-CHECKLIST.md` (Checklist), `registry/epochs/current.epoch.yml` (Epoch), member roadmaps, and AGENT.md Current State.

### 2a. The three worst
1. **G9 and B-17 are open in some docs and closed in others.** Roadmap.md:27 "G9 blocked" and :70 "visibility is an open decision (B-17)". Gist:8 and :21 repeat it. Checklist:32 says "🟡 unblocked S250". Epoch:66 says "B-17 resolved: S250". BLOCKERS.md:41 says "B-17 — resolved: S250". The Roadmap position block is dated 2026-10-13 (S248, line 22), so it predates the fix and nobody updated it.
2. **The S276 air-scope decision was never applied.** SESSION-LOG:502 records "EP1 airs web-only; G7 and G9 move to a later Event … the epoch exit text (current.epoch.yml ~:49-54) still lists G7/G9; not edited." Checklist:30 and :32 still gate on G7 and G9, and Checklist:16 "Last reconciled 2026-10-13 (S248)" predates S276. Epoch:52-58 still requires the OS Developer Preview and `bootstrap.sh` verification. Roadmap.md:64-72 describes the same unapplied scope.
3. **Episode numbers mean different things in different docs.** Post-EP1:15 and Roadmap.md:78: Ep2 = Exodus, the entity gains senses. OS-Roadmap.md:204-208: Ep2 = Exodus, a polished desktop. Roadmap.md:92: Ep3 = Covenant. OS-Roadmap.md:220: Ep3 = "The Entity Wakes" (AI stack). NeBuLA-Roadmap.md:138: member "Episode 1 — Core Engine", with its own Ep0-Ep7 ladder. sCoRE-Roadmap.md:59-60: "Epoch 1: FIRST LOOP", "Epoch 2: LEARNING". The Collective's Epoch 0 is the only epoch in use.

### 2b. Open items that shipped (or are stale-open)
- OS F1 install: OS-Roadmap.md:25 "[ ] F1 … firstboot currently unverified" vs Checklist:30 "VM install PASSED S236 (207 ok / 0 failed, SDDM login)".
- NeBuLA engine: NeBuLA-Roadmap.md:150 "Canvas2dBackend, ThreeJsBackend, EntropyShader — stubs only (throw on call)". Code: `RaBbLE-NeBuLA/src/backends/canvas2d/index.js` is 339 lines, class at :12; `src/backends/threejs-backend.js` is 873 lines. The `throw` hits are argument checks. Epoch:90 milestone "Canvas2D entity renderer at 60 FPS".
- Pocket Roadmap.md:53 "Genesis ships —" for Pocket, but Pocket-Roadmap.md:40 "EP1 — Pocket ships (Mark, S280)" with unchecked items.
- Rust track: `sCoRE-RaBbLE-UI-Rust-Plan.md:3` "proposed, needs Mark's sign-off before R1", but R1 seam gate met S295 and phase-2 built S296.
- sCoRE: `RaBbLE-sCoRE/CONTEXT.md:130` "server/main.py version aligned to v0.0.0.0 | Done" vs `RaBbLE-sCoRE-Roadmap.md:136` "[ ] server/main.py version string aligned to Five Es scheme".
- Post-EP1-Roadmap.md:20-26 lists the local harness and `rabble` CLI as EP2 future work. The `rabble` launcher and Rust shell are live (AGENT.md:17; HANDOFF-S279, HANDOFF-S296). Partly shipped, still listed as future.

### 2c. Done items that did not ship / unverified
- Checklist:33 "G10 … Mark confirmed live, S248" vs EP1-Entity-Face-Plan.md:8 "G10 sign-off pending". Consistent, but Roadmap.md:45-72 and World-Roadmap.md:16 call the face "live on dev", which is true for dev only. Prod still older build (Checklist:50).
- Checklist:26-29 marks G3, G4, G6 "✅ live (S153)". Not re-verified here (not checked).

### 2d. Dates and staleness
- RaBbLE-Roadmap.md:22 "Position — 2026-10-13 (S248)"; gist:8 "2026-10-13, S248"; Checklist:16 "Last reconciled 2026-10-13". Today is 2026-11-06 (S317, SESSION-LOG:8).
- AGENT.md:14 "Current State — 2026-11-02", "Recent: S296" (line 17). Log LATEST is S317 (SESSION-LOG:8, 2026-11-06). Four sessions and four days stale.
- AGENT.md:16 "dev works as EP2 (labels don't gate)". Epoch:9-13 says EP1 is not aired; World-Roadmap.md:16 says dev = the EP1 face awaiting G10. The phrase conflicts with the two other docs.
- EPISODE-1-RELEASE.md:7 "Date: 2026-06-09" and `log/episodes/` draft header (:12). The record is a dated narrative for a day that passed 150 days ago without air.
- RaBbLE-Roadmap.md:109 "episodes air when a vertical slice closes, not on a calendar" vs RaBbLE-Versioning.md:111 "typically quarterly".
- Post-EP1 horizons: Post-EP1:9-11 vs Versioning:136 "Episode 2 … Aired: 2026-Q2 (next week)" in the example timeline.

### 2e. Places two docs disagree
- Bootstrap name: Epoch:58 "Collective bootstrap (bootstrap.sh) verified end-to-end" vs Checklist:32 "setup.sh". Only `setup.sh` exists at the Collective root.
- Branch name: OS-Roadmap.md:20 "Branch: RaBbLE-OS-New-Horizons → RaBbLE/episode-I". No branch named `episode-I` or `*episode*` in RaBbLE-OS, sCoRE, World or Grimoire (`git branch -a`). Epoch:23 says `active_branch: new-horizons`.
- Tag format: Versioning:72 "Is tagged in git (`echo-{N}.{minor}`)" vs Checklist:14 and :86 `episode-1-v0.0.0.1` vs seal-episode.sh:20. Actual tags in members (see section 3c) match neither.
- Member list: 13 manifests in `registry/manifests/` (7 `release_track: episode`, 6 `independent`). Checklist §B (`EP1-AIR-CHECKLIST.md:46-60`) lists 12, missing TaskViSoR and SiGiL. Roadmap.md:42-57 lists TaskViSoR and EnGrAm but not SiGiL. SiGiL manifest: `registry/manifests/RaBbLE-SiGiL.manifest.yml:21 release_track: independent`.
- Moved files still cited: see section 1f (Post-EP1 paths).
- Gist: `gist/RaBbLE-Roadmap-gist.md` is derived and repeats the stale G9 and G7 status. Its own note says the checklist wins.

### 2f. Size and history
- Roadmap set total 103,730 bytes across 11 docs: central (Roadmap 8,868; Post-EP1 8,979; gist 1,974; Checklist 7,268; Epoch 7,950 = 35,039) and members (OS 20,736; sCoRE 9,926; NeBuLA 19,025; World 4,747; Aether 2,438; Pocket 11,819 = 68,691).
- Checkboxes in member roadmaps: 81 `[x]`, 149 `[ ]`. Checklist adds 4 open `[ ]` in §C. NeBuLA's 71 open are its own future engine episodes (NeBuLA-Roadmap.md:224-324).
- Completed-history sections measured: Roadmap Revision History 662 B; sCoRE "Pre-Episode-1 Events" 2,091 B; sCoRE "Provider Backlog" 2,161 B; OS "Backlog Triage S140 (landed)" 8,392 B; NeBuLA Ep0 archived 616 B. Roughly 14 KB of 104 KB is completed or archived history. The forward-looking bulk is the OS and NeBuLA roadmaps.

---

## 3. EPISODE MODEL FOOTPRINT (facts, no recommendation)

### 3a. Encoding sites
- **Grimoire docs:** 133 `.md` files outside SESSION-LOG, `log/sessions/`, `log/archive/` mention episode, epoch or Five Es. Hits: "episode" 616, "epoch" 376, "five-es" 31 (case-insensitive, same filter).
- **Spells and hooks:** 14 files reference episode/epoch: token-budget.sh, init-project.sh, distill-gists.sh, seal-episode.sh, railway-ctl.sh, build-kb.py, status.sh, publish-rc.sh, publish-cdn.sh, agent-register.sh, cast-cdn.sh, setup-cloudflare-r2.sh, end-session.sh, lib/session-id.sh.
- **Member code and config:** files matching episode|epoch|five-es|v0.0.0.[01]: sCoRE 24, OS 20, World 18, Pocket 11, NeBuLA 6, ScRiBbLE 6, Xperimental 6, Aether 5.
- **Version strings:** `RaBbLE-Aether/package.json` "0.0.0.0"; `RaBbLE-NeBuLA/package.json` "0.0.0.0" and `src/version.js:2`; `RaBbLE-sCoRE/server/main.py:38` and `:201` `"v0.0.0.0"`; `RaBbLE-World/world/os.html:129` "RaBbLE-OS · Episode 1 · Genesis · v0.0.0.1" (public page, before air); `RaBbLE-World/world/js/RaBbLE-movements-data.js:134-139` `headline: 'Genesis. v0.0.0.0 → v0.0.0.1.'` (public copy); `RaBbLE-World/world/js/RaBbLE-config.js:22` Aether CDN `v0.0.0.1-rc.2`.
- **Git tags (all members checked):** Grimoire `v0.0.0.0.1` (39bc9c7, 2026-05-05, "initial publication"); World `v0.0.0.0.10` (3be6d2f, 2026-05-05), plus `backup/*` branches; sCoRE `echo-1.0` (64ba332, 2026-04-29, msg tag `%EPISODE_1%`), `echo-2.0` (969fefa, 2026-04-30, msg "Episode 2 closed, echo-2.0 tagged"), `echo-3.0` (f1eae71, 2026-05-06). **No `episode-1-v0.0.0.1` tag exists in any member.** The Epoch file (:13) says it will be applied to all active repos at air.
- **Session phase label:** `spells/end-session.sh:138-145` builds `phase="Epoch N · Episode P"` from the epoch file, written into LATEST (:196, :220). SESSION-LOG has 7 entries with "Epoch 0 · Episode 1" literal (e.g. :10, :2456).
- **Session numbering:** 71 headers from S248 to S317, with duplicate numbers S250 (×2), S251 (×2), S258 (×2) and S314 (×2, one "continued"). S282, S293 and S305 have no header. Earlier double-claims noted in handoffs S284/S285/S286 and the S197 collision (SESSION-LOG:2121).

### 3b. What actually gates on an episode value
| Mechanism | Keys off | Effect | Evidence |
|---|---|---|---|
| `spells/status.sh` alignment | `release_track: episode` members must be on epoch `active_branch` (`new-horizons`) | "in-step" or "off-track" marker | status.sh:76-77, :108, :160-164. Keys off the branch, not the episode number |
| `status.sh` blocker list | `episode_1_blocker: true` in epoch focus map | lists World and Collective as blockers | status.sh:170-173; epoch:65, :98 |
| `registry/manifests/` | `release_track` field | 7 episode, 6 independent | grep of 13 manifests |
| `spells/seal-episode.sh` | tag `episode-1-v0.0.0.1` | DRAFT, "refuses to run until the Collective GitHub account exists" | seal-episode.sh:3-8, :20. No call site found outside its own header |
| `spells/hooks/pre-commit` | none (AI symlink block, warn-only drift and anti-clobber) | no episode or impulse check | pre-commit:11-57; `spells/install-hooks.sh:27` installs only pre-commit and post-commit |
| `end-session.sh` | epoch and episode_pending | writes phase text into LATEST | end-session.sh:138-145, :196 (label only) |
| Version strings and public copy | nothing | label only | sections above |

Conclusion, facts only: the one mechanical gate on episode status is branch alignment (`status.sh`). The episode number itself gates nothing in the scripts read. No commit-message verb or Pulse format is validated by a hook.

### 3c. Evidence of friction
- **Days EP1 has been "next":** first named as the release target in SESSION-LOG:6316 (2026-05-15, S6). That is 175 days to 2026-11-06. The release record is dated 2026-06-09 (EPISODE-1-RELEASE.md:7), 150 days ago, from SESSION-LOG:4593 ("EP1 release brief", S57). The "→ episode-1-v0.0.0.1" next-step chain repeats across roughly a dozen sessions (SESSION-LOG:3787-3922).
- **Work out of episode order:** 71 session headers S248-S317: Pocket 38, sCoRE RaBbLE-UI 18, EP1-named 2 (S248 staging audit, S276 face V1), OS 2 (S283 editions, S287 hypr-tiling), Grimoire/Collective 2 (S290 cleanup, S294 anti-clobber), Atlas/domains/other 9. Pocket is `release_track: independent` in its manifest and in the Checklist (§B, :59). The episode-tagged members received 2 sessions in that window.
- **Unapplied decision:** SESSION-LOG:502 (S276) web-only air decision not written into Epoch:49-54 (pending Mark's OK) or Checklist:30-32.
- **Contradictory EP1 scope:** Epoch exit (OS Developer Preview and bootstrap verified, Epoch:49-58) vs S276 web-only (SESSION-LOG:502) vs Roadmap.md:61-66 (face and voice; "Plus a Developer Preview OS and a bootstrap", gist:18 repeats) vs EPISODE-1-RELEASE.md:42-54 (exit list incl. OS VM bootstrap "pending" and all repos tagged "pending") vs Pocket-Roadmap.md:40 (Pocket ships EP1).
- **Cadence contradiction:** Versioning:111 "typically quarterly or after major vertical slice" vs Roadmap.md:32 and :109 "no calendar". Versioning:117-135 example shows EP2 "Aired: 2026-Q2 (next week)".
- **Release record framed as aired:** EPISODE-1-RELEASE.md:3 "transcribe ~ grimoire >> Episode 1 airs: the entity first breathes", :1 title "Episode 1 Release — Genesis", :7 date 2026-06-09. Status line :12 says DRAFT. Its "Sources" line cites `EPISODE-1-RELEASE-BRIEF.md`, which is not present in the tree.
- **Epoch naming:** Epoch:2 "name: Foundation", `episode_pending: 1`, `status: active`. The file is named `current.epoch.yml` but its live fields are episode-grained. OS-Roadmap.md:213-217 says so in the member's own words ("registry reframe: epoch → episode/echo").
- **Member-level episode ladders** (NeBuLA Ep0-Ep7, OS Ep1-Ep3, sCoRE Ep1-Ep3 with Plots A-C, World/Aether episodes) do not share the Collective's numbers (section 2a).

---

## Not checked
- Did not run `spells/status.sh` or any spell (read-only brief; some spells write).
- Did not verify G3, G4, G6 "✅ live" claims against the live sites.
- Did not check whether `serve.py` (handoffs/CONTEXT.md:27) and `ops/pocket-notes.py` (:35) exist in sCoRE or Pocket.
- Did not confirm the sCoRE CONTEXT.md / roadmap pair for `.claude/settings.json`, `dispatch-watch.sh`, `RaBbLE-Server` (sCoRE-Roadmap.md:86-124), which may be pre-Epoch legacy.
- Did not read SESSION-LOG sections as full text; all session claims are heading-level or grep-level.
- Did not check the `RaBbLE-Voice` handoff's Phase 2 deliverables against `RaBbLE-BaBbLE` or any voice repo.
- Did not check handoff contents beyond their headers and their named "next" items, except where noted.
- Did not compare `log/DECISIONS.md` or `log/BLOCKERS.md` beyond the cited lines.
- Dirty trees (Grimoire 46 files, OS 14, sCoRE 11, BaBbLE 1057) were not inspected; some plan headers may describe uncommitted work.
- Memory notes (`~/.claude/projects/.../memory/*.md`) cited as corroboration only, not as repo evidence.
- Gist and index counts are one-pass grep counts, not deduplicated by file.

scout ~ gobble >> the map is honest where it is written down; the episode label is mostly a sentence // %GOBBLE_SCOUT%
