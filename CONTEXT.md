# CONTEXT.md — RaBbLE-Grimoire

```
transcribe ~ grimoire >> context established // %CONTEXT_LOCKED%
```

```
epoch: 0 | evolution: 0 | echo: 0 | episode: 1 (pilot — in progress) | status: active
version: v0.0.0.0 — Epoch 0, Evolution 0, Echo 0, Episode 1 pilot
```

---

## What we are building

The RaBbLE-Grimoire is the canonical source for the RaBbLE ecosystem — a single source of truth for identity, ethos, lore, technical patterns, protocol contracts, versioning, and conventions across all member projects. Grimoire also includes spells (scripts) that generate LLM context files, manage the member registry, and synchronize conventions across repos.

Every design decision, character trait, protocol schema, and technical pattern lives here first; member repos reference it, never duplicate it.

## What good looks like

- Each `RaBbLE-*/` section has complete, accurate docs for its member project
- `RaBbLE-Agent/` is flat — all files named `RaBbLE-*.md`, no subdirectories
- All docs prefixed with their section (`RaBbLE-OS-`, `RaBbLE-sCoRE-`, etc.) so they are self-locating without folder context
- `INDEX.md` is always current — every document is reachable from it
- Visual assets live in `RaBbLE-Aether/assets/`, not scattered across member sections
- A new contributor can orient fully by reading this file → `INDEX.md` → `RaBbLE-Versioning.md` → `RaBbLE-Agent/RaBbLE-Identity.md`

## What to avoid

- Project-specific content in `RaBbLE-Agent/` — move it to the correct `RaBbLE-*` section
- Duplicate docs across the Grimoire and member repos — the Grimoire publishes, members reference
- Stale paths in `INDEX.md` or `CONTEXT.md` after any rename or restructure
- Owning visual assets here — SVG, logos, and icons belong in `RaBbLE-Aether/assets/`
- Committing without reading `RaBbLE-Agent/RaBbLE-CommitStyle.md` first
- Adding subdirectories to `RaBbLE-Agent/` — use the `RaBbLE-` prefix to provide context instead

---

## Structure

| Path | What it holds |
|---|---|
| `RaBbLE-Agent/` | Agent-facing shared docs: identity, palette, commit style, protocols, roadmap, templates |
| `RaBbLE/` | Entity definition layer — Ethos/, Genesis/, Worldbuilding/ — philosophy, creation mythology, visual world |
| `RaBbLE-Mythos/` | Short stories and creative writing — fiction set in RaBbLE's world |
| `registry/` | Member manifests, epoch definitions — ecosystem infrastructure |
| `registry/manifests/` | One YAML file per member repo |
| `registry/epochs/current.epoch.yml` | Active epoch definition and exit conditions |
| `spells/` | Bash scripts: setup, status, sync, init-project, install-theme |
| `RaBbLE-Versioning.md` | Five-tier versioning spec: Event→Episode→Echo→Evolution→Epoch |
| `INDEX.md` | Full index of all grimoire documents |

## Active Tracks

| Track | Status |
|---|---|
| Entity identity (`RaBbLE-Agent/RaBbLE-Identity.md`) | Split — operational core ~330 lines; ethos extracted to `RaBbLE/` |
| Ethos layer (`RaBbLE/`) | **Active** — Ethos + Worldbuilding live; Genesis + Symbiosis to be authored (Phase 2C) |
| Integration & Ethos Plan (`RaBbLE-Collective/RaBbLE-Integration-Ethos-Plan.md`) | **Active** — Phase 1A✓ 1B✓ 1C✓ 0A✓ 2A✓ 2B✓ 2D✓ 3✓ · Phase 2C (Mark authors), 4 pending |
| Palette (`RaBbLE-Agent/RaBbLE-Palette.md`) | Stable |
| Roadmap (`RaBbLE-Agent/RaBbLE-Roadmap.md`) | Current — Episode 1 streams visible, open questions documented |
| Registry (`registry/`) | 9 manifests live (Collective, OS, sCoRE, Aether, NeBuLA, World, BaBbLE, Chrysalis, Xperimental) |
| Spells (`spells/`) | 6 spells live; `validate-links.sh` planned (non-blocking) |
| Versioning spec (`RaBbLE-Versioning.md`) | Stable — Five Es locked |
| Episode tracking (`registry/epochs/current.epoch.yml`) | Episode 1 pending — all members accumulating Events |
| Episode 1 scope (`RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md`) | Canonical scope locked — exit criteria, blockers, tag convention |
| RaBbLE-sCoRE docs | Architecture + Roadmap present. DataCrawler RFC added. MVP LLM endpoint planned for Railway deploy. |
| RaBbLE-World | **Active** — RC1 "Guided Realm" build in flight (threshold→realm→summon→shell, entity as curator). Loaders (Aether + NeBuLA) + liminal, shell, grimoire-graph surfaces live. |
| RC1 Experience (`RaBbLE-Collective/RaBbLE-RC1-Experience.md`) | **Active** — design canon for the single entity-guided realm; bridges the PRD into the EP1 public surface. PRD §13 partially resolved. |
| RaBbLE-Aether | Active — component library complete, CDN delivery working, dev workflow documented. |
| RaBbLE-NeBuLA | Active — Canvas2dBackend + BootSequence complete. `<rabble-entity>` now in NeBuLA. |
| RaBbLE-BaBbLE | **Active** — formalized as Collective member (Phase 3). AGENT.md/CONTEXT.md/README.md live. Manifest registered. |
| RaBbLE-ScRibLE | Defined — mobile PWA. Repo not yet created. Deferred to Epoch 1+. |
| RaBbLE-Chrysalis | Genesis-archive — origin code from pre-Collective era. Reliquary for archived branches. Renamed from Xperimental S92. |
| RaBbLE-Xperimental | Active sandbox — rablets in development, prototype members, experiments not yet emerged. New repo, created S92. |
| RaBbLE-OS | Active — daily-driver substrate, Ep1 plots in progress, versioning diverged (deferred) |

## Reading Order for a New Session

1. `head -20 log/SESSION-LOG.md` — ## LATEST box only (current state + blockers, ~75 words)
2. This file — active tracks and structure
3. `INDEX.md` — what's in the Grimoire
4. `RaBbLE-Versioning.md` — the versioning model before writing anything
5. `RaBbLE-Agent/RaBbLE-Identity.md` — who RaBbLE is
6. `RaBbLE-Agent/RaBbLE-Palette.md` — what RaBbLE looks like
7. `SPELLS.md` — how Grimoire distributes its authority to member repos
8. `RaBbLE-Agent/RaBbLE-Roadmap.md` — what's being built (Collective-level scope)
