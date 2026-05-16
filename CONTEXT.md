# CONTEXT.md — RaBbLE-Grimoire

```
transcribe ~ grimoire >> context established // %CONTEXT_LOCKED%
```

```
epoch: 0 | evolution: 0 | echo: 0 | episode: pending (ep1) | status: active
version: v0.0.0 — Epoch 0, accumulating events toward Episode 1
```

---

## What we are building

The RaBbLE-Grimoire is the canonical source for the RaBbLE ecosystem — a single source of truth for identity, ethos, lore, technical patterns, protocol contracts, versioning, and conventions across all member projects. Grimoire also includes spells (scripts) that generate LLM context files, manage the member registry, and synchronize conventions across repos.

Every design decision, character trait, protocol schema, and technical pattern lives here first; member repos reference it, never duplicate it.

## What good looks like

- Each `RaBbLE-*/` section has complete, accurate docs for its member project
- `common/` is flat — all files named `RaBbLE-*.md`, no subdirectories
- All docs prefixed with their section (`RaBbLE-OS-`, `RaBbLE-sCoRE-`, etc.) so they are self-locating without folder context
- `INDEX.md` is always current — every document is reachable from it
- Visual assets live in `RaBbLE-Aether/assets/`, not scattered across member sections
- A new contributor can orient fully by reading this file → `INDEX.md` → `RaBbLE-Versioning.md` → `common/RaBbLE-Identity.md`

## What to avoid

- Project-specific content in `common/` — move it to the correct `RaBbLE-*` section
- Duplicate docs across the Grimoire and member repos — the Grimoire publishes, members reference
- Stale paths in `INDEX.md` or `CONTEXT.md` after any rename or restructure
- Owning visual assets here — SVG, logos, and icons belong in `RaBbLE-Aether/assets/`
- Committing without reading `common/RaBbLE-CommitStyle.md` first
- Adding subdirectories to `common/` — use the `RaBbLE-` prefix to provide context instead

---

## Structure

| Path | What it holds |
|---|---|
| `common/RaBbLE-Identity.md` | Identity, manifesto, character, entity state machine |
| `common/RaBbLE-Palette.md` | Canonical synthwave outrun palette — single source of truth |
| `common/RaBbLE-CommitStyle.md` | The Pulse Protocol — commit message format |
| `common/RaBbLE-BranchStrategy.md` | Branch topology and flow |
| `common/RaBbLE-Collective.md` | Ecosystem map, all members, architecture diagram |
| `common/RaBbLE-Collective-KnownIssues.md` | Collective-level known issues |
| `registry/` | Member manifests, epoch definitions — ecosystem infrastructure |
| `registry/manifests/` | One YAML file per member repo |
| `registry/epochs/current.epoch.yml` | Active epoch definition and exit conditions |
| `registry/RaBbLE-Collective-Registry.md` | Registry reference documentation |
| `spells/` | Bash scripts: setup, status, sync, init-project, install-theme |
| `RaBbLE-Aether/assets/` | Visual assets: SVG, logos, icons |
| `RaBbLE-Versioning.md` | Five-tier versioning spec: Event→Episode→Echo→Evolution→Epoch |
| `lore/` | Narrative and creative lore — short stories, world-building |
| `INDEX.md` | Full index of all grimoire documents |

## Active Tracks

| Track | Status |
|---|---|
| Entity identity (`common/RaBbLE-Identity.md`) | Seeded — stable |
| Palette (`common/RaBbLE-Palette.md`) | Stable |
| Roadmap (`common/RaBbLE-Roadmap.md`) | Audited v0.0.0.1 — gaps surfaced, open questions recovered |
| Registry (`registry/`) | 6 manifests live; missing World, NeBuLA, Aether, ScRibLE |
| Spells (`spells/`) | 5 spells live; generate-llm-context and validate-links planned |
| Versioning spec (`RaBbLE-Versioning.md`) | Stable — Five Es locked |
| Episode tracking (`registry/epochs/current.epoch.yml`) | Episode 1 opened 2026-05-07 |
| Protocol contracts (`registry/protocol/`) | Not started — Epoch 0 exit criterion |
| RaBbLE-sCoRE docs | Architecture + Roadmap present. Legacy "ep3" versioning pre-dates Episode 1 alignment — re-versioning to v0.0.0.1 pending |
| RaBbLE-World | Active — Aether CDN fully integrated (Session 8). All 5 pages on `/aether/v0.0.0.0/aether.css`. |
| RaBbLE-Aether | Active — build system live, component library complete, CDN delivery working via dev-serve.sh. |
| RaBbLE-NeBuLA | Active — Canvas2dBackend + BootSequence complete. Bundle live on dev CDN. |
| RaBbLE-ScRibLE | Defined — mobile PWA. Repo not yet created. |
| RaBbLE-Xperimental | Indexed — manifest + Grimoire entry added 2026-05-07 |
| RaBbLE-OS versioning | Diverged from Five Es — deferred to future bootstrap session on new partition |

## Reading Order for a New Session

1. This file — you are here
2. `INDEX.md` — what's in the Grimoire
3. `RaBbLE-Versioning.md` — the versioning model before writing anything
4. `common/RaBbLE-Identity.md` — who RaBbLE is
5. `common/RaBbLE-Palette.md` — what RaBbLE looks like
6. `SPELLS.md` — how Grimoire distributes its authority to member repos
7. `common/RaBbLE-Roadmap.md` — what's being built (Collective-level scope)
