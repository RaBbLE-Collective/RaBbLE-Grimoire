# EP1 Air Checklist — gist

> Source: `log/EP1-AIR-CHECKLIST.md` | ~1800 → ~230 tokens
> Regenerate: `bash spells/distill-gists.sh`

Operational gate for airing Episode 1 (Genesis) — the live, member-by-member state and the tag
procedure. **The air gate is not pulled until every row is green.** Target tag:
`episode-1-v0.0.0.1`, applied to all lockstep members simultaneously (v0.0.0.0 → v0.0.0.1).

**Gate state (S206):** G1–G6, G8, G10 ✅ (chat spine, CDN, CORS, lockstep, entity-forward
World face built S203 — Mark's sign-off pending). **Only two gates remain, both Mark-led,
VM-required:**

| Gate | What | State |
|---|---|---|
| **G7** | RaBbLE-OS Developer-Preview FLOOR on generic x86_64 VM | ⏳ verify |
| **G9** | `setup.sh` bootstrap end-to-end on fresh VM | ⏳ verify |

Runbook for both: `log/G7-G9-Verification-Guide.md`. Open blockers: `log/BLOCKERS.md` (tag
`ep1-gate`) — currently B-02/B-09/B-10 open, none block air (B-02 = resilience not gating;
B-09/B-10 untagged `ep1-gate`).

**Tag procedure once §A is green:** freeze + status.sh/blockers.sh clean → backup tags per
member → finalize `log/episodes/EPISODE-1-RELEASE.md` (drop DRAFT) → tag all lockstep repos
simultaneously (`spells/seal-episode.sh`) → merge `new-horizons`→`main` → update
`current.epoch.yml` → SESSION-LOG LATEST + `end-session.sh ep1-air`.

Genesis ships **expression, not perception** — honest limitations (no Watcher, no memory
member, no entity state machine) carry into the release record; Episode 2 (Exodus) is the
perception arc.

→ Full doc for: member-by-member readiness table, OS Dev-Preview FLOOR detail (§C), full air
procedure steps (§D), honest-limitations carry-over (§E).
