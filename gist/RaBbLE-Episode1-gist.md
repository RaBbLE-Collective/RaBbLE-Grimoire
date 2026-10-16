# EP1 Air Checklist — gist

> Source: `log/EP1-AIR-CHECKLIST.md` | ~3143 → ~420 tokens
> Regenerate: `bash spells/distill-gists.sh`

Operational gate for airing Episode 1 (Genesis): live member-by-member state plus the tag procedure. The air gate is not pulled until every gate row is green. The air call is Mark's.

**Target:** tag `episode-1-v0.0.0.1` on all lockstep members at once (v0.0.0.0 → v0.0.0.1). Last reconciled 2026-10-13 (S248).

**Gates**

| Gate | State |
|---|---|
| G1 World loads in prod | ✅ |
| G2 sCoRE on Render | ✅ |
| G3 Aether + NeBuLA CDN | ✅ |
| G4 End-to-end chat on prod | ✅ |
| G5 Chat not capped by 429s | ✅ Groq chain override (B-16 non-gating) |
| G6 CORS | ✅ |
| G7 OS Developer-Preview FLOOR | 🟡 VM (S236) and bare metal (S238) passed; air-ISO confirmation run deferred by Mark (S248) |
| G8 Lockstep members on `new-horizons`, clean | ✅ |
| G9 `setup.sh` on a fresh machine | 🟡 unblocked S250 (members public, https manifests); needs the fresh-VM run |
| G10 Unified World prod | 🔄 five-beat face live on dev; not signed off (Mark, S249); no `/chrysalis` or `/xperimental` on prod |

**Lockstep tag set:** Grimoire, sCoRE, World, Aether, NeBuLA, OS, BaBbLE. Independent (not tagged): Chrysalis, Xperimental, ScRiBbLE, Pocket.

**OS FLOOR (Dev Preview):** generic x86_64 VM install; usable Hyprland; recovery path (F2 → `SYSTEMD_SULOGIN_FORCE`); known-rough-edges sheet.

**Air procedure:** (1) `bash spells/status.sh` and `bash spells/blockers.sh ls`; (2) `git tag backup/pre-ep1-<member>`; (3) finalize `log/episodes/EPISODE-1-RELEASE.md`; (4) tag via `spells/seal-episode.sh`; (5) merge `new-horizons` → `main`; (6) update `current.epoch.yml`, using the `evolve` impulse; (7) `bash spells/end-session.sh ep1-air "Episode 1 aired"`.

**Honest limits:** Genesis ships expression, not perception. Missing: Watcher, memory member, entity state machine, unified World chrome, Genesis lore. These are the Episode 2 (Exodus) arc.

→ Full doc for: per-member readiness table, gate evidence details, OS FLOOR deferrals, release-record steps, blocker IDs (B-NN)
