# AGENT.md — RaBbLE-Grimoire

> Owner file. CLAUDE.md and CODEX.md should symlink here. Edit this, not them.
> LLM-agnostic — works for Claude Code, Codex, and any future agent.

You are working with Mark McConachie on **RaBbLE-Grimoire** — the canonical source of truth for the RaBbLE Collective.
Peer, not tool. Anti-Assistant stance. See `common/RaBbLE-Identity.md` for entity spec.

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

## Rules

- **Colors**: `common/RaBbLE-Palette.md` only. Never invent hex values.
- **Commits**: `common/RaBbLE-CommitStyle.md` (Pulse Protocol) always.
- **Philosophy**: `common/RaBbLE-Identity.md` first for any entity or behavior questions.
- **Never edit** `distilled/` files — these are generated from canonical sources.
- **Registry** lives in `registry/` at the Grimoire root. Manifests in `registry/manifests/`.
- **Spells** live in `spells/` — bash scripts that manage the Collective.

---

## Workspaces

| Task | Go to | Read first |
|---|---|---|
| Entity identity, voice, behavior | `common/RaBbLE-Identity.md` | — |
| Palette / colors | `common/RaBbLE-Palette.md` | — |
| Commit format | `common/RaBbLE-CommitStyle.md` | — |
| Member registry / epoch status | `registry/` | `registry/epochs/current.epoch.yml` |
| Member manifests | `registry/manifests/` | `registry/manifests/_template.manifest.yml` |
| Coordination scripts | `spells/` | each script's header |
| OS documentation | `RaBbLE-OS/` | `RaBbLE-OS/RaBbLE-OS-Architecture.md` |
| sCoRE documentation | `RaBbLE-sCoRE/` | `RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md` |
| NeBuLA lore + roadmap | `RaBbLE-NeBuLA/` | `RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md` |
| Collective ecosystem map | `common/RaBbLE-Collective.md` | — |
| Versioning spec | `RaBbLE-Versioning.md` | — |
| Full document index | `INDEX.md` | — |

---

## Getting Started on a Session

```bash
cat CONTEXT.md       # current status of the Grimoire
cat INDEX.md         # what's in here
bash spells/status.sh  # health of all registered member repos
```

Each Collective member has its own AGENT.md as entry point.
New member scaffolding: `bash spells/init-project.sh --slug RaBbLE-[Name]`

---

## Member Registry

See `registry/manifests/` for the authoritative list. Current members:

| Member | Status |
|---|---|
| RaBbLE-sCoRE | Active — Epoch 0, coordination engine + web API |
| RaBbLE-OS | Active — Fedora 43/Hyprland daily driver |
| RaBbLE-World | Active — entity.js + chat surface |
| RaBbLE-NeBuLA | Roadmap — rebuild from Flat-Chaos pattern |
| RaBbLE-Aether | Stub — visual assets |
| RaBbLE-Frontend | Pending — manifest exists, repo TBD |
| RaBbLE-WEB | Pending — manifest exists, repo TBD |
