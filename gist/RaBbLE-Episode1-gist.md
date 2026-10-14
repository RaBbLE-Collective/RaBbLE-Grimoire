# EP1 Air Checklist — gist

> Source: `log/EP1-AIR-CHECKLIST.md` | ~1800 → ~230 tokens
> Regenerate: `bash spells/distill-gists.sh` (hand-synced S248)

Operational gate for airing Episode 1 (Genesis) — the live, member-by-member state and the tag
procedure. **The air gate is not pulled until every row is green.** Target tag:
`episode-1-v0.0.0.1`, applied to all lockstep members simultaneously (v0.0.0.0 → v0.0.0.1).

**Gate state (S248):** G1–G6 + G8 ✅ (chat spine, CDN, CORS, lockstep). Remaining:

| Gate | What | State |
|---|---|---|
| **G7** | RaBbLE-OS Developer-Preview FLOOR on generic x86_64 | 🟡 VM passed S236, bare metal S238; record + confirmation run deferred |
| **G9** | `setup.sh` bootstrap end-to-end on a fresh machine | 🔴 B-17: SSH manifests + private NeBuLA/sCoRE |
| **G10** | World face coherent, no `/chrysalis` on prod | 🔄 five-beat face live on dev; Mark's sign-off pending; `/chrysalis/` route open |

Path to air: `log/plans/EP1-Staging-and-Grimoire-Audit.md`. Open blockers: `log/BLOCKERS.md`
(`ep1-gate` = B-17 only; B-16 OpenRouter credits = resilience, not gating).

**Tag procedure once §A is green:** freeze + status.sh/blockers.sh clean → backup tags per
member → finalize `log/episodes/EPISODE-1-RELEASE.md` (drop DRAFT) → tag all lockstep repos
simultaneously (`spells/seal-episode.sh`) → merge `new-horizons`→`main` → update
`current.epoch.yml` → SESSION-LOG LATEST + `end-session.sh ep1-air`.

Genesis ships **expression, not perception** — honest limitations (no Watcher, no memory
member, no entity state machine) carry into the release record; Episode 2 (Exodus) is the
perception arc.

→ Full doc for: member-by-member readiness table, OS Dev-Preview FLOOR detail (§C), full air
procedure steps (§D), honest-limitations carry-over (§E).
