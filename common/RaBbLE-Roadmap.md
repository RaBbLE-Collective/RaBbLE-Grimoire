# RaBbLE-Roadmap.md — Collective Phase Map

```
transcribe ~ grimoire >> charting the collective metamorphosis // %TRAJECTORY_LOCKED%
```

> This is the Collective view — project phases and epoch goals only.
> Detail lives in each project's own roadmap.
> → RaBbLE-OS/grimoire/RaBbLE-OS-Roadmap.md
> → RaBbLE-WEB/grimoire/RaBbLE-WEB-Roadmap.md
> → RaBbLE-Frontend/grimoire/RaBbLE-Frontend-Roadmap.md

---

## Collective Epoch Map

```
Epoch 0: FOUNDATION        [ACTIVE]      — Structure, grimoire, conventions, scaffold
```

---

## Current Epoch — Epoch 0: Foundation

**Intent:** Establish the Collective coordination layer. Define the structure,
conventions, and philosophy before building anything. Every project is a
registered scaffold. Nothing is wired yet.

**Exit Condition:**
- RaBbLE-Collective committed and bootstrappable from a fresh clone
- All project repos initialized and registered with real remote URLs
- setup.sh verified against live repos
- Each project has AGENT.md, workspace structure, and grimoire in place

---

## Project Status

| Project | Phase | Epoch | Status | Current Focus |
|---|---|---|---|---|
| RaBbLE-Collective | 0 | 0 | Active | Registry setup, remote tracking |
| RaBbLE-OS | 0 | 0 | Active | Bootstrap Fedora 43, Hyprland, Episode 1 baseline |
| RaBbLE-sCoRE | 0 | 0 | Planning | Unified coordinator, API/server integration |
| RaBbLE-NeBuLA | 0 | 0 | Analysis | Tech extraction, modern implementation roadmap |
| RaBbLE-Aether | 0 | 0 | Setup | Asset management, palette consolidation |
| RaBbLE-Chat | 0 | 0 | Scaffold | Chat surface into Behavioral Learning Engine |

---

## Epoch 0 Workstreams

### Workstream 1: Grimoire as Single Source of Truth

**Goal:** Grimoire generates all LLM helper files (CONTEXT.md, OVERVIEW.md, etc.) via spells

**Tasks:**
- [ ] Create `spells/generate-llm-context.py` — generates CONTEXT.md from Grimoire sections
- [ ] Create `spells/generate-overview.py` — generates OVERVIEW.md from roadmap + status
- [ ] Document spell system in `SPELLS.md`
- [ ] Integrate spell generation into CI/CD
- [ ] Mark CONTEXT.md and OVERVIEW.md in each repo as "generated from Grimoire — do not edit"

**Why:** LLM agents need fresh context without duplicating Grimoire content. Spells keep them synchronized.

**Status:** `[PLANNING]`

---

### Workstream 2: Collective Registry & Setup

**Goal:** Grimoire becomes the orchestration center; spells initialize member repos locally

**Tasks:**
- [ ] Merge old RaBbLE-Collective registry into Grimoire (`RaBbLE-Collective/` section)
- [ ] Create `spells/setup-collective.sh` — clones all registered member repos, configures remotes
- [ ] Create `spells/register-project.sh` — bootstraps new projects into Collective
- [ ] Version compatibility map system per project
- [ ] Document remote fetch/pull patterns

**Status:** `[ACTIVE]`

---

### Workstream 3: Core Projects Alignment

**Goal:** Each member project aligned to Grimoire conventions and bootstrap-ready

**Tasks:**

**RaBbLE-OS:**
- [x] Existing active codebase
- [x] Theming, palette system
- [ ] Complete Episode 1 baseline (Fedora 43, Hyprland, fresh bootstrap on hardware)
- [ ] Integrate AIQuickstart docs

**RaBbLE-sCoRE:**
- [ ] Merge RaBbLE-Server + RaBbLE-sCoRE into unified coordinator
- [ ] API/server component (FastAPI)
- [ ] Wraps different LLMs, delegates custom agents
- [ ] See `RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md` for detail

**RaBbLE-NeBuLA:**
- [ ] Tech analysis complete (see NeBuLA-JS EXTRACTION_ANALYSIS.md)
- [ ] Extract valuable lore into Grimoire (Flat-Chaos pattern, entropy-driven design)
- [ ] Create modern implementation roadmap (see MODERN_IMPLEMENTATION_ROADMAP.md)
- [ ] Archive NeBuLA-JS as reference; build clean RaBbLE-Render

**RaBbLE-Aether:**
- [ ] Move assets from Grimoire → Aether
- [ ] Move RaBbLE-OS bg generation scripts → Aether
- [ ] Consolidate ASCII art and visual assets

**Status:** `[ACTIVE]` for OS, `[PLANNING]` for others

---

## RaBbLE-OS

**Phase 0 — Foundation** `[ACTIVE]`

**Current Focus:**
- Bootstrap fresh Fedora 43 with Sway/Hyprland
- Complete Episode 1 baseline (Desktop Baseline, rough draft)
- Document hardware, boot flow, packages
- Integration with Grimoire versioning

See `RaBbLE-OS/RaBbLE-OS-Roadmap.md` for full detail.

---

## RaBbLE-sCoRE

**Phase 0 — Foundation** `[PLANNING]`

**Current Focus:**
- Merge RaBbLE-Server functionality into sCoRE
- Define unified API shape
- Integration with Claude Code delegation pattern

See `RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md` for full detail.

---

## RaBbLE-NeBuLA (Rendering System)

**Phase 0 — Echo v0.0.1 Rewrite** `[PLANNING]`

**Current Status:**
- v0.0.1 (Echo level) analysis complete: tech extraction, philosophy distillation
- RBCNS specification archived as lore (philosophically sound, implementation outdated)
- Modern implementation roadmap created (4-week plan)
- Grimoire entries prepared from v0.0.1 analysis

**Next Steps:**
1. Integrate lore/philosophy from v0.0.1 into Grimoire
2. Rewrite NeBuLA v0.0.2+ with clean, modern architecture per roadmap
3. Archive RaBbLE-NeBuLA-JS v0.0.1 as reference

See `/RaBbLE/RaBbLE-NeBuLA-JS/GRIMOIRE_CONTENT.md` and `MODERN_IMPLEMENTATION_ROADMAP.md` for detail.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-04-28 | Initial Collective roadmap — Collective-level scope only |
| v0.2 | 2026-04-28 | Reset to Epoch 0 — honest initial scaffold state |

---

```
transcribe ~ grimoire >> collective trajectory crystallized // %TRAJECTORY_LOCKED%
```
