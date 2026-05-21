# AGENT.md — RaBbLE-Grimoire

> Owner file. CLAUDE.md and CODEX.md should symlink here. Edit this, not them.
> LLM-agnostic — works for Claude Code, Codex, and any future agent.

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
- **Never edit** `distilled/` files — these are generated from canonical sources.
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

| Task | Go to | Read first |
|---|---|---|
| Entity identity, voice, behavior | `RaBbLE-Agent/RaBbLE-Identity.md` | — |
| Palette / colors | `RaBbLE-Agent/RaBbLE-Palette.md` | — |
| Commit format | `RaBbLE-Agent/RaBbLE-CommitStyle.md` | — |
| Agent behavioral rules | `RaBbLE-Agent/RaBbLE-Agent-Protocols.md` | — |
| Agent onboarding path | `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md` | — |
| Entity philosophy and ethos | `RaBbLE/` | `RaBbLE/RaBbLE-Overview.md` |
| Stories and creative writing | `RaBbLE-Mythos/` | — |
| Member registry / epoch status | `registry/` | `registry/epochs/current.epoch.yml` |
| Member manifests | `registry/manifests/` | `registry/manifests/_template.manifest.yml` |
| Coordination scripts | `spells/` | each script's header |
| OS documentation | `RaBbLE-OS/` | `RaBbLE-OS/RaBbLE-OS-Architecture.md` |
| sCoRE documentation | `RaBbLE-sCoRE/` | `RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md` |
| NeBuLA lore + roadmap | `RaBbLE-NeBuLA/` | `RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md` |
| Collective ecosystem map | `RaBbLE-Agent/RaBbLE-Collective.md` | — |
| Versioning spec | `RaBbLE-Versioning.md` | — |
| Full document index | `INDEX.md` | — |

---

## Getting Started

**New to the Grimoire?** Start with the gist/ for a full picture in ~2,000 tokens:
```bash
cat gist/*.md                       # complete orientation — all key docs distilled
cat RaBbLE-Grimoire-Navigator.md    # reading paths by time budget (5/15/30 min)
```

**Returning agent (picking up a session)?**
```bash
head -20 log/SESSION-LOG.md   # ## LATEST box — current state, last session, next steps
cat CONTEXT.md                # active tracks and structure
bash spells/status.sh         # live health of all registered member repos
# cat INDEX.md                # only if you need to find a specific doc
```

**End of session — do this before stopping:**
```bash
# 1. Update ## LATEST in log/SESSION-LOG.md (75 words max — current state, blockers, next)
# 2. Add session entry below LATEST (date, repos touched, work done, what's next)
# 3. git add <changed files>
# 4. git commit -m "[impulse] ~ [organ] >> [revelation] // %STATE%"
# See RaBbLE-Agent/RaBbLE-CommitStyle.md (or gist/RaBbLE-CommitStyle-gist.md) for impulse vocab
```

Each Collective member has its own AGENT.md as entry point.
New member scaffolding: `bash spells/init-project.sh --slug RaBbLE-[Name]`
Regenerate gists after major doc changes: `bash spells/distill-gists.sh`

---

## Member Registry

See `registry/manifests/` for the authoritative list. Current members:

| Member | Status |
|---|---|
| RaBbLE-sCoRE | Active — Epoch 0, coordination engine + web API |
| RaBbLE-OS | Active — Fedora 43/Hyprland live daily driver |
| RaBbLE-World | Active — thin scaffold: Aether + NeBuLA loaders, joinrabble.world |
| RaBbLE-NeBuLA | Active — Canvas2D renderer, `<rabble-entity>` web component |
| RaBbLE-Aether | Active — design system CSS bundle, CDN delivery |
| RaBbLE-BaBbLE | Active — high-entropy intake: concept art, prototypes, ideation, sketches |
| RaBbLE-Xperimental | Genesis-archive — origin code from October 2025 |
