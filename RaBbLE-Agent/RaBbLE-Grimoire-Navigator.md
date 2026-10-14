# RaBbLE-Grimoire Navigator

> Reading order for agents and humans arriving cold. Cheapest first: stop as soon as you know enough.

---

## Reading Paths

### Orient (~3,000 tokens)
1. `gist/*.md` — every key doc distilled: identity, Collective, roadmap, EP1 gates, versioning, palette, commits, integration
2. `head -20 log/SESSION-LOG.md` — the `## LATEST` box (last session, next step)

You'll know: what RaBbLE is, where every member stands, what blocks Episode 1.

### Build something (+ ~5,000 tokens)
3. `CONTEXT.md` — active tracks, where each kind of work lives
4. `log/BLOCKERS.md` + `log/EP1-AIR-CHECKLIST.md` — open blockers, air gates
5. Your member's `AGENT.md` + `CONTEXT.md`, then `RaBbLE-<Member>/` here for architecture + roadmap
6. `log/plans/CONTEXT.md` — is there already a plan for this?

### Full onboarding
7. `RaBbLE-Agent/RaBbLE-Identity.md` · `RaBbLE-Versioning.md` · `RaBbLE-Agent/RaBbLE-CommitStyle.md`
8. `RaBbLE-Agent/RaBbLE-Agent-Protocols.md` — hard-won behavioral rules (long; read the section you need)
9. `RaBbLE-Agent/RaBbLE-Roadmap.md` → `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md`
10. `INDEX.md` — everything that exists

**Don't read whole:** `log/SESSION-LOG.md` (~85K words; `head` or `grep` it), `INDEX.md` (grep it),
`RaBbLE-Mythos/` transcripts, `log/plans/done/`. They are records, not orientation.

---

## Jump to Task

| Task | Read |
|---|---|
| RaBbLE's character, voice, behavior | `RaBbLE-Agent/RaBbLE-Identity.md` |
| Current state, blockers, air gates | `log/SESSION-LOG.md` LATEST · `log/BLOCKERS.md` · `log/EP1-AIR-CHECKLIST.md` |
| Where everything stands, what's next | `RaBbLE-Agent/RaBbLE-Roadmap.md` |
| Working on a specific member | That member's `AGENT.md` + `CONTEXT.md` · `RaBbLE-<Member>/` |
| How members connect | `RaBbLE-Agent/RaBbLE-Integration-Map.md` |
| Deployment and CDN | `RaBbLE-Collective/RaBbLE-Deployment-Architecture.md` + `RaBbLE-Collective/RaBbLE-Cloudflare-Integration.md` |
| Visual language and colors | `RaBbLE-Agent/RaBbLE-Palette.md` + `RaBbLE-Aether/RaBbLE-Aether-Architecture.md` |
| Setup and coordination scripts | `SPELLS.md` → `spells/` |
| Member registry, epoch status | `registry/manifests/` · `registry/epochs/current.epoch.yml` |
| Agent behavioral rules, do's/don'ts | `RaBbLE-Agent/RaBbLE-Agent-Protocols.md` |
| Past decisions and why | `log/DECISIONS.md` · `log/RaBbLE-Development-History.md` |
| Find any document | `grep -i <term> INDEX.md` |

---

## Grimoire Structure

```
RaBbLE-Grimoire/
├── gist/                  ← START HERE: distilled orientation (~3,000 tokens)
├── RaBbLE-Agent/          ← Cross-member canon (flat, RaBbLE-*.md): identity, palette, commit style,
│                            roadmap, protocols, integration map, Collective map
├── RaBbLE/                ← The entity's inner life: Ethos/, Genesis/, Worldbuilding/, PRD, vision arc
├── RaBbLE-Mythos/         ← Fiction and creative writing
├── RaBbLE-Collective/     ← Ecosystem-level plans: deployment, Cloudflare, membership, secrets, cosmos
├── RaBbLE-<Member>/       ← Per-member docs: RaBbLE-<Member>-Architecture.md, -Roadmap.md, ...
├── registry/              ← manifests/ (one YAML per member) · epochs/current.epoch.yml
├── spells/                ← Coordination bash scripts (catalogue: SPELLS.md)
├── log/                   ← SESSION-LOG, EP1-AIR-CHECKLIST, BLOCKERS, DECISIONS
│   ├── plans/             ← active plans (index: plans/CONTEXT.md), done/ for finished
│   └── handoffs/          ← cold-start handoffs (index: handoffs/CONTEXT.md), done/ for finished
├── AGENT.md               ← Grimoire entry point (CLAUDE.md/CODEX.md/GEMINI.md symlink here)
├── CONTEXT.md             ← Current state, active tracks
├── INDEX.md               ← Full document index
└── RaBbLE-Versioning.md   ← The Five Es
```

**Rule:** `RaBbLE-Agent/` is canonical for all members. Members reference it, never duplicate it.

---

Adding new docs? See **Adding New Docs** in `AGENT.md`.
