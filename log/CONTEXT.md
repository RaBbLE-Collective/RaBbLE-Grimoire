# log/CONTEXT.md

```
workspace: log | epoch: 0
```

## What happens here

Machine-readable memory for every agent session. The operational files (SESSION-LOG, BLOCKERS,
DECISIONS, AUDITS) are human-curated; the subdirs (agents/, decisions/, lessons/) are structured
streams that compound knowledge across sessions and agents without merge conflicts.

## Contents

```
log/
  SESSION-LOG.md       Running session narrative — 75-word ## LATEST box at top
  BLOCKERS.md          Durable blocker ledger (spells/blockers.sh)
  DECISIONS.md         Human-curated architectural decisions
  AUDITS.md            Completed audits + open gaps
  EP1-AIR-CHECKLIST.md Live EP1 gate tracker (G7/G9 pending)
  G7-G9-Verification-Guide.md  Step-by-step for G7 + G9 verification
  RaBbLE-Development-History.md  5-minute narrative of Collective eras + pivots
  token-ledger.tsv     Session → feature breadcrumbs (feeds session-tokens.sh)

  agents/      One JSON per live agent — scope claims, heartbeat, liveness
  blockers/    blockers.jsonl — append-only open/resolve event log
  decisions/   One JSONL per session — decisions, insights, stumbles, scopes
  lessons/     One .md per promoted insight — durable compounded knowledge

  plans/       Active implementation plans (flat .md); done/ for completed
  handoffs/    Cold-start handoff docs for multi-session work; done/ for implemented
  episodes/    Per-episode milestone records + RC correspondence
  archive/     Superseded plans, old analyses, overflow session logs
  generated/   Auto-generated files (graph-grimoire.sh output)
```

## Three coordination spells

| Spell | Job |
|---|---|
| `spells/agent-register.sh` | Claim file-scope globs; detect overlaps; heartbeat liveness |
| `spells/decision-log.sh` | Per-agent JSONL stream of decisions, insights, stumbles |
| `spells/promote-insight.sh` | Scan JSONL logs; write durable `lessons/*.md` for future agents |
