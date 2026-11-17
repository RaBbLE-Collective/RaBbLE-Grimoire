# HANDOFF-S348: the claude.ai export is integrated; review flags and promotions remain

Date: 2026-11-17 · repos: Grimoire (`new-horizons`), Personal-Grimoire, Incenergy, GCS, Jobotron3000 and its Seeker repo.
Read first: `log/archive/chat-export-2026-11-17/README.md`, then `transcript-mining.md` and `uncataloged-rabble-threads.md` in the same folder.

## Where everything is

| Material | Home |
|---|---|
| Raw export (zips, JSON, extracted Frames), generator scripts | `~/Personal-Grimoire/archive/claude-export-2026-11-17/` (gitignored; contains pasted credentials, never commit) |
| RaBbLE chat digests, artifact inventory, design docs | `log/archive/chat-export-2026-11-17/` |
| OG RaBbLE-OS chats and 17 April project docs | `RaBbLE-OS/historical/RaBbLE-OS-Origins-2026.md`, `project-docs-2026-04/` |
| Six recovered docs | `RaBbLE-NeBuLA-VJ-Persona-Notes`, `RaBbLE-Pocket-Muse-Bringup`, `RaBbLE-Pocket-Boot-Latency-and-Power-Session`, `RaBbLE-Distilled-Nonzens-Mythos`, `RaBbLE-Society-of-Agents-Architecture`, `RaBbLE-EnGrAm-Photo-Notes-Storage-Origins` |
| 16 recovered decisions | `log/DECISIONS.md`, section "Decisions recovered from chat history" |
| Personal material | `~/Personal-Grimoire/babble/claude-export-2026-11/` and 5 new folios |
| Incenergy | `~/Incenergy/docs/claude-export-2026-11-17/`, `docs/STAT_SPEC.md`, `log/artifacts/` |
| Career | `~/Jobotron3000/Sessions/2026-11-17-chat-export-career-intake.md`; interview prep in `Seeker/mark-mcconachie/jobs/` |
| PhysioAI (GCS, prototype) | `~/GCS/docs/physioai-spec-2026-04/` |

## Open, in order

1. **Mark: review the folios.** Every `[REVIEW]` rune in the new Personal Grimoire folios (pokedex, pokeball, bobs-burgers, consultancy, school and summer camp, `job-search`, `incenergy`) is Claude's second-hand reading. Confirm status and dates.
2. **Mark: framework stance.** `RaBbLE-World/RaBbLE-World-Architecture.md` line 382 says "No React, no JSX, no frameworks, vanilla JS only". His intent is mainly framework-agnostic, React unused so far, adoption deliberate. Reword or leave.
3. **Encryption.** He wants everything stored encrypted; client versus server decryption of Pocket captures needs more work. The 2026-10-22 server-side idea is a stopgap; S333 (client-sealed) stands in `log/DECISIONS.md` until he rules.
4. **Verify two recovered decisions** against current rulings: multi-display Hyprland/GNOME (S328 compositor trial) and the spatial-structure member idea.
5. **Promote or drop the 8 uncataloged threads** listed in `uncataloged-rabble-threads.md` (training-member naming, Meta Charm competitive landscape, VJ persona, scene IR, brik.space entity prompt, Needle 2 and microWakeWord voice pipeline, agent sandboxing design, Grok persona). Nothing there is canon.
6. **Naming.** The personal `archive/` and `babble/` folders and the Incenergy folder still have "claude-export" in the name (the Grimoire ones were renamed).

## Limits

69 of 218 chats are empty in the export; the 771 file references are names only. Decision rows are from Claude's summaries.
Generator scripts (`tools/` in the raw archive) hold absolute paths and expect the extracted export under a scratch directory; read them before rerunning.
