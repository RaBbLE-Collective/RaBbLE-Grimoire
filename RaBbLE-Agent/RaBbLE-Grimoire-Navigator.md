# RaBbLE-Grimoire Navigator

> Reading order for agents and humans arriving cold. Start here before `INDEX.md`.

---

## Reading Paths

### 5-Minute Skim
1. `RaBbLE-Agent/RaBbLE-Identity.md` — **Quick Reference** section only (what RaBbLE is)
2. `CONTEXT.md` — current milestone and active tracks

You'll know: RaBbLE is a behavioral learning entity, the Collective scaffolds its emergence, Episode 1 is the target.

### 15-Minute Deep Dive (building something)
Above, then:
3. `log/EP1-AIR-CHECKLIST.md` — what ships, live gate table, blockers
4. Your member's `AGENT.md` — `RaBbLE-OS/`, `RaBbLE-sCoRE/`, `RaBbLE-NeBuLA/`, `RaBbLE-World/`, `RaBbLE-Aether/`

You'll know: Episode 1 scope and your member's exit conditions.

### 30-Minute Full Onboarding (joining the team)
Above, then:
5. `RaBbLE-Versioning.md` — Five Es (Event→Episode→Echo→Evolution→Epoch), lockstep model
6. `RaBbLE-Agent/RaBbLE-CommitStyle.md` — Pulse Protocol commit format
7. `RaBbLE-Agent/RaBbLE-Agent-Protocols.md` — hard-won behavioral rules (doc management, dev workflow, member responsibilities, naming)
8. `RaBbLE-Agent/RaBbLE-Roadmap.md` — long-term vision, open gaps
9. `INDEX.md` — everything that exists in the Grimoire

---

## Jump to Task

| Task | Read |
|---|---|
| RaBbLE's character, voice, behavior | `RaBbLE-Agent/RaBbLE-Identity.md` |
| Current blockers and milestone | `CONTEXT.md` + `log/EP1-AIR-CHECKLIST.md` |
| Working on a specific member | That member's `AGENT.md` + `CONTEXT.md` |
| Deployment and CDN | `RaBbLE-Deployment-Architecture.md` + `RaBbLE-Cloudflare-Integration.md` |
| Visual language and colors | `RaBbLE-Agent/RaBbLE-Palette.md` + `RaBbLE-Aether/RaBbLE-Aether-Architecture.md` |
| Setup and coordination scripts | `SPELLS.md` → `spells/` |
| Member coordination model | `RaBbLE-Agent/RaBbLE-Collective.md` + `registry/RaBbLE-Collective-Registry.md` |
| Agent behavioral rules, do's/don'ts | `RaBbLE-Agent/RaBbLE-Agent-Protocols.md` |
| Versioning in depth | `RaBbLE-Versioning.md` |
| Find any document | `INDEX.md` |

---

## Grimoire Structure

```
RaBbLE-Grimoire/
├── RaBbLE-Agent/                          ← Shared across all members
│   ├── RaBbLE-Identity.md           ← WHO RaBbLE IS (philosophy, voice, character)
│   ├── RaBbLE-Collective.md         ← WHAT THE COLLECTIVE IS (members, architecture)
│   ├── RaBbLE-Palette.md            ← THE ONLY COLOR SOURCE (never invent hex values)
│   ├── RaBbLE-CommitStyle.md        ← HOW TO COMMIT (Pulse Protocol)
│   └── RaBbLE-Roadmap.md            ← LONG-TERM VISION (epochs, open gaps)
│
├── RaBbLE-Collective/               ← Collective-level coordination
│   └── RaBbLE-Collective-Plan.md    ← HOW THE BOOTSTRAP WORKS
│
├── log/EP1-AIR-CHECKLIST.md         ← EPISODE 1 SCOPE, LIVE GATE TABLE & EXIT CONDITIONS
│
├── RaBbLE-[Member]/                 ← Member-specific docs (one dir per active member)
│   └── RaBbLE-[Name]-Architecture.md, RaBbLE-[Name]-Roadmap.md, ...
│
├── registry/manifests/              ← Member YAML files (one per member)
├── registry/epochs/current.epoch.yml ← Active epoch definition + episode status
├── spells/                          ← Coordination bash scripts
├── log/                             ← SESSION-LOG.md, GAP-ANALYSIS.md, decisions
├── RaBbLE/                            ← Creative and narrative content
│
├── AGENT.md                         ← Grimoire entry point (auto-injected as CLAUDE.md)
├── CONTEXT.md                       ← Current milestone, active tracks
├── INDEX.md                         ← Full document index
└── RaBbLE-Versioning.md             ← VERSIONING MODEL (Five Es)
```

**Rule:** `RaBbLE-Agent/` is canonical for all members. Members reference it, never duplicate it.

---

Adding new docs? See **Adding New Docs** in `AGENT.md`.
