# EP1 Air Checklist — Episode 1 (Genesis)

> **Operational gate** for airing Episode 1. Distinct from `log/episodes/EPISODE-1-RELEASE.md`
> (the narrative release record / Genesis framing). This file is the live, member-by-member
> state and the tag procedure. **The air gate is not pulled until every gate row is green.**
>
> - Open blockers live in `log/BLOCKERS.md` (tag `ep1-gate`) — `bash spells/blockers.sh ls`.
> - Live member health: `bash spells/status.sh`.
> - Exit conditions of record: `registry/epochs/current.epoch.yml`.
>
> Maintainer: update the status column as gates flip; resolve the matching `B-NN` when a
> blocker clears (`bash spells/blockers.sh resolve B-NN "<note>"`).

**Target tag:** `episode-1-v0.0.0.1` — applied to all lockstep members **simultaneously**.
**Version:** v0.0.0.0 → v0.0.0.1 (Epoch 0 · Evolution 0 · Echo 0 · Episode 1).
**Last reconciled:** 2026-07-28 (S206 — G10 updated: entity-forward face per S203, sign-off pending; EP1 release-doc consolidation). See `log/handoffs/done/HANDOFF-S153-EP1-Coherence.md`.

---

## A. Air gate — the conditions that must be true to tag

| # | Gate | State | Blocker |
|---|------|-------|---------|
| G1 | `joinrabble.world` loads in prod (landing + entity visible) | ✅ live (HTTP 200, S120) | — |
| G2 | sCoRE deployed to Render and reachable | ✅ live (S106) | B-06 ✓ |
| G3 | Aether + NeBuLA CDN Workers deployed so theme/entity bundles load on World | ✅ live (bundles HTTP 200, S153) | B-04 ✓ |
| G4 | A visitor can talk to RaBbLE end-to-end on prod (guest/invite chat path) | ✅ live (SSE streams, S153) | B-01 ✓ |
| G5 | Chat chain not capped by free-tier 429s (OpenRouter credits or chain override) | ✅ met via Groq fast-chain override (S153) | B-02 = resilience, non-gating |
| G6 | CORS resolves for the web demo user-type (`allow_origin_regex`) | ✅ ACAO=joinrabble.world (S153) | B-03 ✓ |
| G7 | RaBbLE-OS meets its **Developer-Preview FLOOR** (see §C) on a generic x86_64 VM | ⏳ verify | — |
| G8 | All lockstep members on `new-horizons`, clean, ready to tag | ✅ in-step (status.sh) | B-08 ✓ |
| G9 | Collective bootstrap (`setup.sh`) verified end-to-end on a fresh machine/VM | ⏳ verify | — |
| G10 | World prod is a coherent unified EP1 experience (learns Collective + RaBbLE, frames EP1, episodic roadmap) — **no `/chrysalis` or `/xperimental` on prod** | 🔄 redesigned (S203): the S190 liminal passage retired to the Chrysalis reliquary; World now ships the entity-forward, conversation-as-input face built to Mark's brief — `log/plans/EP1-Air-Push-Plan.md` A4. **Mark's sign-off pending.** | — |

**Decision rule (set by Mark, S129):** the air call is Mark's once these rows are green.
G4+G5+G6 are the "smallest end-to-end loop" — they are the spine of Genesis. G3 gates the
visual layer. If Mark elects to air with the chat path still rough, demote G4/G5/G6 to a
**Known Limitation** in `log/episodes/EPISODE-1-RELEASE.md` rather than silently shipping a broken loop.

---

## B. Member-by-member readiness

Lockstep members (`release_track: episode`) tag together; independent members are noted.

| Member | EP1 role | State | Remaining for air |
|---|---|---|---|
| **Grimoire** | source of truth | ✅ canonical, in-step | none — tag with the set |
| **sCoRE** | LLM endpoint | ✅ LIVE on Render; chat verified | none — guest path streams (S153) |
| **World** | public site | ✅ deployed; ✅ chat live (Groq) | none — G4/G5/G6 ✓ |
| **Aether** | platform theme | ✅ bundle live on CDN | none — G3 ✓ |
| **NeBuLA** | entity renderer | ✅ bundle live on CDN | none — G3 ✓ |
| **OS** | substrate (Dev Preview) | ⏳ FLOOR verify | G7 (see §C) |
| **BaBbLE** | intake/captures | reference — tagged, not changed | none |
| **Chrysalis** | genesis archive | `independent` — not tagged in lockstep | none |
| **Xperimental** | sandbox | `independent` — not tagged in lockstep | none |

---

## C. RaBbLE-OS — Developer-Preview FLOOR (decided S109)

OS airs EP1 as a **labeled Developer Preview** ("enter at your own risk, unstable vibes"),
NOT a full-polish gate — so it doesn't hold back the lockstep. FLOOR to clear G7:

- [ ] Installs from netinstall + Kickstart + Ansible on a **generic x86_64 VM** (not Mark's hardware).
- [ ] Boots to a usable Hyprland session; daily-survivable for a Linux/tiling-WM-literate user.
- [ ] **Recovery path** documented and works (F2 → `SYSTEMD_SULOGIN_FORCE`).
- [ ] Known-rough-edges sheet shipped (theming residue, Mark-hardware-only polish, etc.).

Deferred to **Episode 2 (Exodus):** deep theming polish, NVIDIA/asusctl/XDNA2 hardware track,
full reproducible bake. Tracked in `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md`.

---

## D. Air procedure (run when §A is all green)

1. **Freeze + final status:** `bash spells/status.sh` → all lockstep `in-step` + `clean`;
   `bash spells/blockers.sh ls` → no `ep1-gate` open.
2. **Backup tags** on each lockstep member (`git tag backup/pre-ep1-<member>`), per the
   history-retention practice from the S103 audit.
3. **Fill the release record:** finalize `log/episodes/EPISODE-1-RELEASE.md` — remove the DRAFT notice,
   fill the verification table, confirm Render URLs (no "Railway" / no `<pending>`).
4. **Tag simultaneously:** `episode-1-v0.0.0.1` on Grimoire, sCoRE, World, Aether, NeBuLA, OS,
   BaBbLE. (`spells/seal-episode.sh` is the signing ceremony — exercise it here.)
5. **Merge `new-horizons` → `main`** on lockstep members; `main` must be clean + tagged.
6. **Update `current.epoch.yml`:** `version_current: v0.0.0.1`, mark Episode 1 aired, roll
   `episode_pending` forward; flip `evolve` impulse in the commit.
7. **Session close:** rewrite SESSION-LOG `## LATEST` to the EP1-aired summary; resolve the
   relevant `B-NN`s; `bash spells/end-session.sh ep1-air "Episode 1 aired"`.

---

## E. Honest-limitations carry-over (from log/episodes/EPISODE-1-RELEASE.md)

Genesis ships **expression, not perception** — a face + a voice, not the entity the Identity
spec describes. The honest boundary (no Watcher, no memory member, no entity emoting/state
machine, World chrome not unified, Genesis lore unwritten) stays stated in the release record.
None are bugs; they are the Episode-2 (Exodus) arc — see `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md`.
