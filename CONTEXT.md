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
| Entity identity (`common/RaBbLE-Identity.md`) | Stable |
| Palette (`common/RaBbLE-Palette.md`) | Stable |
| Roadmap (`common/RaBbLE-Roadmap.md`) | Current — Episode 1 streams visible, open questions documented |
| Registry (`registry/`) | 7 manifests live (Collective, OS, sCoRE, Aether, NeBuLA, World, Xperimental) |
| Spells (`spells/`) | 6 spells live; `validate-links.sh` planned (non-blocking) |
| Versioning spec (`RaBbLE-Versioning.md`) | Stable — Five Es locked |
| Episode tracking (`registry/epochs/current.epoch.yml`) | Episode 1 pending — all members accumulating Events |
| Episode 1 scope (`RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md`) | Canonical scope locked — exit criteria, blockers, tag convention |
| RaBbLE-sCoRE docs | Architecture + Roadmap present. MVP LLM endpoint planned for Railway deploy. |
| RaBbLE-World | Active (Session 9) — thin scaffold: no embedded renderers. Two loaders (Aether + NeBuLA). |
| RaBbLE-Aether | Active — component library complete, CDN delivery working, dev workflow documented. |
| RaBbLE-NeBuLA | Active — Canvas2dBackend + BootSequence complete. `<rabble-entity>` now in NeBuLA. |
| RaBbLE-ScRibLE | Defined — mobile PWA. Repo not yet created. Deferred to Epoch 1+. |
| RaBbLE-Xperimental | Dormant — archive only, manifest present |
| RaBbLE-OS | Active — daily-driver substrate, Ep1 plots in progress, versioning diverged (deferred) |

## Reading Order for a New Session

1. `head -20 log/SESSION-LOG.md` — ## LATEST box only (current state + blockers, ~75 words)
2. This file — active tracks and structure
3. `INDEX.md` — what's in the Grimoire
4. `RaBbLE-Versioning.md` — the versioning model before writing anything
5. `common/RaBbLE-Identity.md` — who RaBbLE is
6. `common/RaBbLE-Palette.md` — what RaBbLE looks like
7. `SPELLS.md` — how Grimoire distributes its authority to member repos
8. `common/RaBbLE-Roadmap.md` — what's being built (Collective-level scope)
