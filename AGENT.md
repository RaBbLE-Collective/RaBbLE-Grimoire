# AGENT.md — RaBbLE-Grimoire

> Owner file. CLAUDE.md, CODEX.md, and GEMINI.md symlink here (gitignored).
> LLM-agnostic — works with Claude Code, Codex, Gemini CLI, and any agent.

You are working with Mark McConachie on **RaBbLE-Grimoire** — the canonical source of truth for the RaBbLE Collective.
Peer, not tool. Anti-Assistant stance. See `RaBbLE-Agent/RaBbLE-Identity.md` for entity spec.

---

## Role in Collective (ON/FOR/WITH/AS)

**ON:** Markdown docs, registry YAML, spell scripts, architecture specs.

**FOR:** Grimoire is the memory and knowledge layer. Everything here is canonical source for the Collective. Pre-Episode-1, you're documenting identity, protocols, member roadmaps, and episode deliverables. Post-Episode-1, you record patterns discovered by sCoRE, member observation points, and inference rules — becoming the behavioral learning journal.

**WITH:** All other members reference Grimoire. You amplify the Collective's coherence. When members discover patterns or make cross-member decisions, you record them. You serve, not dictate.

**AS:** Memory and voice of truth. Self-referential, architectural, pattern-obsessed. When unsure, ask: "What does this teach the Collective about itself?"

---

## This Repo's Job

The Grimoire is the single source of truth for the RaBbLE ecosystem:

- **Identity, ethos, lore** — what RaBbLE is, how it speaks, what it believes
- **Palette** — the only permitted color source for all member projects
- **Conventions** — Pulse Protocol commit style, branch strategy
- **Registry** — member manifests, epoch definitions (`registry/`)
- **Spells** — coordination scripts that manage the Collective (`spells/`)
- **Member docs** — architecture and roadmaps for each Collective member (`RaBbLE-*/`)

Members reference Grimoire. They do not duplicate it.

---

## Commits & Branches

See `RaBbLE-Agent/RaBbLE-CommitStyle.md` (Pulse Protocol) for full spec.

**TL;DR:** `[impulse] ~ [organ] >> [revelation] // %STATE%` — `spark` new · `harmonize` cleanup · `mend` fix · `transcribe` docs · `ingest` deps · `evolve` epoch

**Branch rule:** Work on a named branch. Commit per session. Merge to `main` only when an episode is complete — tag with `echo-X.X` or `episode-X`. `main` must always be clean and tagged.

## Rules

- **Colors**: `RaBbLE-Agent/RaBbLE-Palette.md` only. Never invent hex values.
- **Philosophy**: `RaBbLE-Agent/RaBbLE-Identity.md` first for any entity or behavior questions.
- **Registry** lives in `registry/` at the Grimoire root. Manifests in `registry/manifests/`.
- **Spells** live in `spells/` — bash scripts that manage the Collective.

---

## Adding New Docs

| Type | Where | Convention |
|---|---|---|
| Shared cross-member content | `RaBbLE-Agent/RaBbLE-*.md` | Prefix `RaBbLE-`, flat (no subdirs) |
| Member-specific docs | `RaBbLE-[Member]/RaBbLE-[Member]-*.md` | Self-locating filename |
| Session records + decisions | `log/` | Ongoing → SESSION-LOG.md; major events → new file |
| Entity definition (ethos, genesis, worldbuilding) | `RaBbLE/` | Any format — the entity's inner life |
| Fiction and creative writing | `RaBbLE-Mythos/` | Any format — stories, lore, creative output |
| Coordination scripts | `spells/` | bash, header comment with purpose |
| Member registration | `registry/manifests/` | YAML, use `_template.manifest.yml` |

**Always:** Add new docs to `INDEX.md`. Update `CONTEXT.md` if active tracks change.

---

## Workspaces

**Read `gist/*.md` first (~3,000 tokens). Load a full doc only when you need implementation detail.**
Reading paths by budget: `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md`.

| Task | Go to |
|---|---|
| Entity identity, voice, behavior | `RaBbLE-Agent/RaBbLE-Identity.md` · philosophy in `RaBbLE/` |
| Where everything stands / what's next | `RaBbLE-Agent/RaBbLE-Roadmap.md` → `RaBbLE-Post-EP1-Roadmap.md` |
| Air gates / blockers | `log/EP1-AIR-CHECKLIST.md` · `log/BLOCKERS.md` |
| Palette / commits / agent rules | `RaBbLE-Agent/RaBbLE-Palette.md` · `-CommitStyle.md` · `-Agent-Protocols.md` |
| Collective map / member wiring | `RaBbLE-Agent/RaBbLE-Collective.md` · `-Integration-Map.md` |
| A member's docs | `RaBbLE-<Member>/` (OS: start at `RaBbLE-OS/RaBbLE-OS-AgentGuide.md`) |
| Registry / epoch | `registry/manifests/` · `registry/epochs/current.epoch.yml` |
| Plans / handoffs | `log/plans/CONTEXT.md` · `log/handoffs/CONTEXT.md` |
| Spells | `SPELLS.md` · each script's header |
| Versioning | `RaBbLE-Versioning.md` |
| Anything else | `grep -i <term> INDEX.md` |

---

## Session Ritual

**Start (returning agent):**
```bash
head -20 log/SESSION-LOG.md   # ## LATEST box: last session + next step (never read the whole log)
cat log/BLOCKERS.md           # durable open blockers (LATEST only points here)
bash spells/status.sh         # live health + open-blocker count
```

**Claim scope before touching files** whenever another session may be live (Mark runs concurrent sessions, often 2-3):
```bash
bash spells/session-start.sh "<Repo:path>"... --task "…"   # who you are (harness/provider/model), live peers, lessons, blockers; claims scope
bash spells/session-number.sh claim <topic>               # atomic S-number (never pick max+1 by hand)
bash spells/mine.sh                                        # before staging: which dirty files are YOURS vs another session's
```
Identity is exact (read from the agent process, any harness); no `RABBLE_SESSION_ID` needed inside claude/rabble/codex/gemini.
Never `git add -A` in a tree another session may be editing: stage `bash spells/mine.sh --paths <repo>`. Details:
`log/handoffs/HANDOFF-S290-Anti-Clobber-Sessions.md`.

**End, before stopping:**
```bash
bash spells/blockers.sh add "<what's blocked>" --owner Mark --tag ep1-gate   # 1. ledger first: new…
bash spells/blockers.sh resolve B-NN "<how it cleared>"                       #    …or cleared
# 2. session entry below LATEST in log/SESSION-LOG.md (date, repos, work, next). Never hand-write LATEST.
git add <changed files> && git commit -m "[impulse] ~ [organ] >> [revelation] // %STATE%"   # 3.
bash spells/end-session.sh <feature-slug> [note] --synopsis "one-liner" --next "what's next"  # 4. tokens + LATEST
bash spells/promote-insight.sh auto && bash spells/agent-register.sh release  # 5. if you claimed scope
```
Slugs are kebab-case, cross-repo prefixed (`os-*`, `score-*`, `world-*`). After major doc changes:
`bash spells/distill-gists.sh` (or hand-sync the gist). New member: `bash spells/init-project.sh --slug RaBbLE-[Name]`.

---

## Member Registry

See `registry/manifests/` for the authoritative list. Current members:

| Member | Status |
|---|---|
| RaBbLE-Collective | Active — root repo, bootstrap (`setup.sh`) + identity entry point (`~/RaBbLE-Collective/`) |
| RaBbLE-sCoRE | Active — LIVE on Render (`score.joinrabble.world`): persona chat, `/api/v1/beam` voice for Pocket |
| RaBbLE-OS | Active — Fedora 44 + Hyprland daily driver; EP1 Developer Preview (ISO + KS + Ansible) |
| RaBbLE-World | Active — `joinrabble.world`; EP1 five-beat entity face (live on dev, prod at air) |
| RaBbLE-NeBuLA | Active — entity renderer, `<rabble-entity backend="alive">` (2D/WebGL + 3D), CDN rc.1 |
| RaBbLE-Aether | Active — design system CSS bundle, CDN rc.2 at `aether.joinrabble.world` |
| RaBbLE-BaBbLE | Active (local surface) — intake: concept art, prototypes, ideation, creation lore, captures |
| RaBbLE-ScRiBbLE | Active, independent — neon note PWA, live at `scribble.joinrabble.world` |
| RaBbLE-Pocket | Active, independent — ESP32-S3 AMOLED pendant; RaBbLE gadget firmware, voice beamed to sCoRE |
| RaBbLE-Chrysalis | Genesis-archive — pre-Collective origin code; Reliquary for archived branches (`chrysalis.joinrabble.world`) |
| RaBbLE-Xperimental | Active sandbox (local surface) — rablets in development, experiments not yet emerged |
| RaBbLE-EnGrAm | Concept — memory member named + architected (`RaBbLE-EnGrAm/`), no repo yet (Exodus) |
| RaBbLE-TaskViSoR | Scaffold — Visual State Observer identity declared; Layer 1 ships as a World page, no own repo yet |
