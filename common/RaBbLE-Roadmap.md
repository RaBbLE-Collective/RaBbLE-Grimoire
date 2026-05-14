# RaBbLE-Roadmap.md — Collective Phase Map

```
transcribe ~ grimoire >> charting the collective metamorphosis // %TRAJECTORY_LOCKED%
```

> Collective-level view only — phases, epoch goals, and open gaps.
> Member-specific detail lives in the Grimoire member sections:
> → `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-Roadmap.md`
> → `RaBbLE-Grimoire/RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md`
> → `RaBbLE-Grimoire/RaBbLE-sCoRE/RaBbLE-sCoRE-Roadmap.md`

---

## Epoch Map

```
Epoch 0: FOUNDATION   [ACTIVE]   — Structure, Grimoire, conventions, scaffold
Epoch 1: CLOSED LOOP  [FUTURE]   — First round-trip: intent → coordination → output → memory
```

---

## Epoch 0: Foundation `[ACTIVE]`

**Intent:** Establish the Collective coordination layer. Define structure,
conventions, and philosophy before building anything. Grimoire is the source of
truth. All members are registered scaffolds. Nothing is wired for production yet.

**Exit Conditions** (from `registry/epochs/current.epoch.yml`):
- [x] RaBbLE-Collective repo committed and pushed to GitHub
- [x] All project repos initialized, registered in manifests, and cloneable
- [x] `setup.sh` clones and wires members from Grimoire
- [ ] `setup.sh` verified against all live repos (World, NeBuLA, Aether remotes needed)
- [ ] Each active project has `AGENT.md`, `CONTEXT.md`, `REFERENCES.md`, and workspace structure
- [ ] Protocol contracts written (`registry/protocol/` dir — manifest schema, health-ping format)

**Epoch 1 blocker:** Memory member — no name, no repo, no architecture doc. Defines first closed loop.

---

## Member Registry

| Member | Status | Epoch | Manifest | Notes |
|---|---|---|---|---|
| RaBbLE-Collective | Active | 0 | ✓ | Bootstrap + identity layer. Door to ecosystem. |
| RaBbLE-Grimoire | Active | 0 | — | Source of truth. Not a member-clone target. |
| RaBbLE-sCoRE | Active | 0 | ✓ | Coordination server + web API. sCoRE ep3 complete. |
| RaBbLE-OS | Active | 0 | ✓ | Fedora 43 + Hyprland daily driver. Episode 1 in progress. |
| RaBbLE-World | Active | 0 | ✗ missing | Web presence + entity chat surface. `joinrabble.world`. Includes RaBbLE-Chat. |
| RaBbLE-NeBuLA | Scaffold | 0 | ✗ missing | Visual renderer. Lore migrated. Rebuild not started. |
| RaBbLE-Aether | Stub | 0 | ✗ missing | Visual assets. Not a git repo yet. |
| RaBbLE-ScRibLE | Defined | 0 | ✗ missing | Mobile PWA — iPhone/iPad notes + Apple Pencil. Deferred to Epoch 1+. |
| RaBbLE-Xperimental | Dormant | 0 | ✓ | High-entropy archive. Old server, NeBuLA-JS, WebOS, RaBbLE.py. |
| Memory (TBD) | Concept | 0→1 | — | Epoch 1 blocker. No name, no repo, no architecture yet. |

> `RaBbLE-Chat` was a working title. It is now part of `RaBbLE-World`.

---

## Completed Work — Epoch 0

### ✓ Phase 1: sCoRE + Server Merge `[COMPLETE — 2026-05-06]`

`RaBbLE-Server` absorbed into `RaBbLE-sCoRE`. sCoRE runs as both a local
coordination shell and a web API endpoint (FastAPI on `:8000`).

- [x] Server files present in `RaBbLE-sCoRE/server/`
- [x] Harness files present in `RaBbLE-sCoRE/harness/`
- [x] `start-rabble.sh` has `--with-server` flag
- [x] `stop-rabble.sh` includes `rabble-server`
- [x] `status.sh` has server health block
- [x] Grimoire sCoRE docs updated with Episode 3 server architecture
- [x] `RaBbLE-Server` deprecated

> ⚑ Roadmap previously showed sCoRE status as "Planning". Corrected to Active/complete.

---

### ✓ Phase 2: Collective → Grimoire Integration `[COMPLETE — 2026-05-06]`

Registry and coordination scripts moved from `RaBbLE-Collective-PORT-To-Grimoire`
into Grimoire as canonical spells. Grimoire is now the orchestration center.

- [x] `spells/setup.sh` — clone, pull, wire all members
- [x] `spells/status.sh` — ecosystem health dashboard
- [x] `spells/init-project.sh` — scaffold new member repos
- [x] `spells/sync-grimoire.sh` — propagate common/ docs
- [x] `spells/install-theme.sh` — Claude Code theme
- [x] `registry/manifests/` — Collective, OS, sCoRE, Frontend, WEB manifests present
- [x] `registry/epochs/current.epoch.yml` — Epoch 0 defined
- [x] Grimoire `INDEX.md` has Spells and Registry sections
- [x] `RaBbLE-Collective-PORT-To-Grimoire` deprecated
- [x] `SPELLS.md` documents all spells

> ⚑ Roadmap Workstream 2 tasks ("Merge old registry", "Create setup-collective.sh")
> are fully complete. Workstream status has been updated accordingly.

Remaining deferred items:
- [ ] Test `setup.sh` against all live repos (World, NeBuLA, Aether repos needed first)
- [ ] Test `sync-grimoire.sh` (needs member `grimoire/` directories in place)
- [ ] `RaBbLE-WEB` and `RaBbLE-Frontend` repos created with real remotes (currently TBD in manifests)

---

### ✓ Phase 3: NeBuLA Lore → Grimoire `[COMPLETE — 2026-05-06]`

NeBuLA-JS lore migrated into Grimoire. `RaBbLE-NeBuLA-JS` archived.
Clean rebuild roadmap written in `RaBbLE-Grimoire/RaBbLE-NeBuLA/`.

- [x] `RaBbLE-NeBuLA-Identity.md` — lore, Quantum Emergence
- [x] `RaBbLE-NeBuLA-Architecture.md` — two-layer model
- [x] `RaBbLE-NeBuLA-FlatChaos.md` — Flat-Chaos pattern
- [x] `RaBbLE-NeBuLA-RABL.md` — RABL language spec
- [x] `RaBbLE-NeBuLA-RBCNS.md` — archived spec (lore only)
- [x] `RaBbLE-NeBuLA-Ideas.md`
- [x] `RaBbLE-NeBuLA-Roadmap.md` — rebuild roadmap (Layer 1 + Layer 2 + episode tracker)
- [x] `RaBbLE-NeBuLA-JS` deprecated

> ⚑ Roadmap previously showed NeBuLA status as "Analysis". Corrected to Scaffold/lore-complete.
> References to `NeBuLA-JS/GRIMOIRE_CONTENT.md` and `MODERN_IMPLEMENTATION_ROADMAP.md` as
> action items are complete and removed.

---

### ✓ Phase 5a: Bootstrap Wired `[COMPLETE — 2026-05-07]`

`bootstrap.sh` corrected and Grimoire-aware. Grimoire remote verified on every run.

- [x] `COLLECTIVE_REPO` URL fixed (`RaBbLE.git` → `RaBbLE-Collective.git`)
- [x] `RaBbLE-Collective.manifest.yml` URL fixed to match
- [x] Grimoire staleness check: fetch + ahead/behind + local-change detection
- [x] Wizard Entry printed at bootstrap end: key reads + available spells

---

## Open Work — Epoch 0

### Phase 4: NeBuLA v2 Rebuild `[NOT STARTED]`

Build the clean NeBuLA engine. TypeScript + Three.js r160+. No RBCNS naming.
**Prerequisites:** Phase 3 complete ✓

**Decisions needed before starting:**
- [ ] Repo home: new `RaBbLE-NeBuLA/` repo, or integrate into `RaBbLE-World/`?
- [ ] Language: TypeScript + Vite/Rollup, or vanilla ES modules?
- [ ] Three.js version: r160+ (WebGPU path) or latest stable?
- [ ] Entity state bridge: how does `entity.js` state flow into NeBuLA entropy?

**Episode 1 exit conditions** (once decisions above are made):
- [ ] `Entity` type: id, geometry, Float32Array matrix, entropy
- [ ] `Stream` class: add, remove, transform, filter
- [ ] `Runtime` class: stream registry, rAF loop
- [ ] `ThreeJsBackend`: InstancedMesh, one draw call per geometry type
- [ ] 1000 entities @ 60 FPS verified
- [ ] Entropy shader working
- [ ] ES module export
- [ ] No RBCNS naming in codebase

---

### Phase 5b: Spell Verification + Registry Completion `[NOT STARTED]`

Verify all coordination spells against live GitHub repos. Close out Epoch 0 exit checklist.
**Prerequisites:** World, NeBuLA, Aether remotes created.

- [ ] Create GitHub repos for `RaBbLE-WEB` and `RaBbLE-Frontend` — update manifests
- [ ] Create GitHub repo for `RaBbLE-World` — add manifest
- [ ] Create GitHub repo for `RaBbLE-NeBuLA` — add manifest
- [ ] `RaBbLE-Aether`: `git init` + create remote + add manifest
- [ ] Add manifests for: World, NeBuLA, Aether, ScRibLE (or decide ScRibLE's fate)
- [ ] `spells/setup.sh` verified against all registered live repos
- [ ] `spells/sync-grimoire.sh` tested (members need `grimoire/` dirs)
- [ ] Protocol contracts written — `registry/protocol/` dir: manifest schema, health-ping format
- [ ] All Epoch 0 exit conditions in `registry/epochs/current.epoch.yml` met

---

### Phase 6: Server → Task Pipeline `[FUTURE — Epoch 1 candidate]`

Wire `server/` HTTP routes through sCoRE's file-based task delegation pipeline.
Currently server routes call LLM providers directly. This phase makes HTTP
requests first-class inputs to the sCoRE coordination loop.

**Intended design:**
```
POST /api/v1/chat
  → server writes TASK-{ID} to sCoRE/tasks/pending/
  → dispatch routes to rabble-execution or rabble-search
  → agent writes result to tasks/done/
  → server SSE-streams result back to client
```

**Challenge:** SSE streaming requires async polling on `tasks/done/` — significant
architecture change from current stateless server. Defer until Epoch 1 is scoped.

---

## Open Gaps

### Priority 1 — Blocking Epoch 0 Exit

| Gap | Status | Notes |
|---|---|---|
| Missing manifests: World, NeBuLA, Aether, ScRibLE | Open | Blocks full `setup.sh` verification. Xperimental manifest added ✓ |
| Protocol contracts (`registry/protocol/`) | Open | Epoch 0 exit criterion — manifest schema + health-ping format |
| `RaBbLE-Aether` is not a git repo | Open | Needs `git init` + remote before trackable |
| Memory member: no name, no repo, no architecture | Open | Blocks Epoch 1 scoping |

### Priority 2 — Coherence

| Gap | Status | Notes |
|---|---|---|
| NeBuLA naming: `RaBbLE-NeBuLA-JS` vs `RaBbLE-NeBuLA` | Open | JS repo is archived; new repo not yet created |
| ScRibLE defined but unbuilt | Open | Mobile PWA defined in Grimoire — repo and manifest still needed |
| `RaBbLE-World` has no CONTEXT.md | Open | Active project with no session entry point |
| Context/Overview generation spells | Open | `spells/generate-llm-context.py` etc. — planned in SPELLS.md, not yet implemented |

### Priority 3 — Quality of Life

| Gap | Status | Notes |
|---|---|---|
| Link validation spell (`spells/validate-links.sh`) | Open | Catch broken paths before they accumulate |
| Session log ceremony | Open | Currently relies on discipline; should be prompted or automated |
| Aether assets: not moved from Grimoire | Open | SVG, ascii, bg gen scripts still scattered |

---

## Deprecated / Archived

| Repo | Reason | Notes |
|---|---|---|
| `RaBbLE-Server` | Absorbed into `RaBbLE-sCoRE/server/` — Phase 1 | Keep as archived reference or delete |
| `RaBbLE-Collective-PORT-To-Grimoire` | Migrated to Grimoire — Phase 2 | Keep as archived reference or delete |
| `RaBbLE-NeBuLA-JS` | Lore migrated to Grimoire — Phase 3 | Keep as archived reference |
| `devPlan.md` (Collective root) | Integrated here | Safe to remove from root |
| `GAPS.md` (Collective root) | Integrated here | Safe to remove from root |
| `TODO` (Collective root) | Integrated here | Safe to remove from root |
| `RaBbLE-CONTEXT.md` (Collective root) | Predates AGENT.md/CONTEXT.md standard | Evaluate: migrate unique content → Grimoire, then archive |
| `RaBbLE-OVERVIEW.md` (Collective root) | Predates AGENT.md/CONTEXT.md standard | Evaluate: migrate unique content → Grimoire, then archive |

---

## Open Questions

1. **NeBuLA repo home:** New `RaBbLE-NeBuLA/` repo or integrate into `RaBbLE-World/`?
2. **Memory member:** Name (candidates: Mnemos, Codex), scope, and architecture — when does this become Episode 1?
3. **`RaBbLE-Server` + `RaBbLE-Collective-PORT-To-Grimoire`:** Delete or keep as archived reference?
4. **Grimoire → member propagation:** How does the Grimoire push updates to members? Current options:
   - `sync-grimoire.sh` copies `common/` docs to member `grimoire/` directories (implemented, untested)
   - Members reference Grimoire directly (no copy — requires shared filesystem or submodule)
   - Generated context files composed by spell at setup time (context spells not yet implemented)
   - TBD — mechanism needs to be decided before `sync-grimoire.sh` is finalized
5. **AIQuickstart docs:** What format and scope? All members should have these per the original TODO.
6. **Manifest format:** Pydantic-published JSON schema is the leaning answer — confirm and write the `registry/protocol/` spec.
7. **Inter-member transport:** HTTP/REST locally fine for v0. Event bus is tempting but premature — confirm v0 boundary.
8. **Observation channels:** Which OS signals are ethical to self-observe? Privacy-of-self matters even with one user. Decide deliberately before building the Memory member.
9. **Ambient suggestion vs. surveillance:** Where is the UX line between helpful intent surfacing and creepy self-monitoring? Feel out by living with it — but decide before Epoch 2.
10. **Behavioral Learning Engine — one or several members:** Pattern extraction, intent inference, and action delegation may want separate members eventually. Decide before Epoch 2 scope.
11. **Cloud vs. local model split:** Heavy reasoning → Claude Code (cloud). Ambient always-on observation/inference → local model. Confirm this boundary and pick the local model story before Memory member is built.

---

## Versioning Transition — Episode 1 Alignment

**How episodes work:** Events accumulate continuously. An episode is not declared open —
it airs retroactively when a stable-ish coherent point is felt across the ecosystem.
Current work creates events that will become Episode 1 when it airs. Until then, all
version strings stay at `v0.0.0`.

**Target:** All active members tag `v0.0.0.1` simultaneously when Episode 1 airs.

| Member | Current Versioning | Transition Plan |
|---|---|---|
| RaBbLE-Collective | v0.0.0.1 ✓ | Aligned this session |
| RaBbLE-Grimoire | v0.0.0.1 ✓ | Aligned this session |
| RaBbLE-sCoRE | Legacy "ep3" (own counter) | Re-version to v0.0.0.1 — current state becomes events within Episode 1; prior ep1–ep3 work becomes pre-episode archive |
| RaBbLE-World | v0.0.0.0.10 (own counter) | Align to v0.0.0.1.x when manifest is added |
| RaBbLE-OS | v0.0.0.0 ✓ | Aligned this session — episode/plot conventions adopted. Ep1 Plot A (Substrate) + Plot B (Theme) in progress. |
| RaBbLE-NeBuLA | No versioning yet | Will start at v0.0.0.1 when repo is created |
| RaBbLE-Aether | No versioning yet | Will start at v0.0.0.1 when git repo is initialized |
| RaBbLE-ScRibLE | No versioning yet | Will start at v0.0.0.1 when repo is created |
| RaBbLE-Xperimental | Archive — no active versioning | Dormant; archive branches preserve original history |

**Echo 1** is the target stable state: all active members bootstrappable, manifests complete,
Epoch 0 exit conditions met. Tagged `echo-1` across aligned repos simultaneously.

---

## Post-Episode-1: Cadence & Release Model

Once Episode 1 airs, the Collective transitions from pre-episode accumulation to a repeating rhythm.

### Weekly Episode Model (Target)

- **Episode cadence:** Weekly (tentative — may adjust based on work rhythm)
- **Lockstep:** All members advance to Episode N together on the same date
- **Compatibility within Episode:** Parts of the Collective in the same Episode are guaranteed compatible
- **Breaking changes:** Reserved for Echo boundaries (releases/production versions)

Example:
```
Episode 1 airs 2026-Q2: All members jump to v0.0.0.1
  Work continues: Event accumulation toward Episode 2
  
Episode 2 airs 2026-Q2+1w: All members jump to v0.0.0.2
  (Example: Memory member fully integrated, observation loop closed)
  
Episode 3 airs 2026-Q2+2w: All members jump to v0.0.0.3
  (Example: NeBuLA v2 rebuild complete, new visual language deployed)
```

### Echo as Release (Production Model)

Echoes mark production-ready, long-term stable states. **Echoes can introduce breaking changes** — schema migrations, protocol bumps, API redesigns — all documented in the next Episode's entry notes.

Example echo timeline:
```
Episode 1: v0.0.0.1 (rapid Episodes, low-friction features)
Episode 2: v0.0.0.2
Echo 1.0: v0.0.1 (stable production release)
  Can introduce breaking changes; requires migration guide for Ep2→Ep3

Episode 3: v0.0.1.3 (Episodes continue; Echo 1.0 is the last stable ship point)
Episode 4: v0.0.1.4
Echo 2.0: v0.0.2 (next major release)
  Can break; requires migration guide
```

### Episode Criteria (Post-Ep1)

- All active members have Events that reflect the week's work
- Plots organize member-specific arcs
- Episode airs when Mark signals "ready to lock this together"
- No waiting for perfect stability — stability checkpoints happen at Echoes

---

## Revision History

| Ecosystem State | Date | Change |
|---|---|---|
| v0.0.0 | 2026-04-28 | Initial Collective roadmap — Foundation scaffolding events |
| v0.0.0 | 2026-04-28 | Reset to Epoch 0 — honest initial scaffold state |
| v0.0.0 | 2026-05-07 | Full audit — integrated devPlan.md, GAPS.md, TODO. Phases 1–3 marked complete. Phase 5a (bootstrap) added. Superseded items flagged. |
| v0.0.0 | 2026-05-07 | Xperimental indexed, ScRibLE defined. RaBbLE-Chat → World clarified. Propagation open question added. |
| v0.0.0 | 2026-05-07 | Six open questions recovered (manifest format, transport, observation channels, surveillance UX, BLE architecture, cloud/local split). |
| v0.0.0 | 2026-05-07 | Versioning model clarified — episodes air retroactively. Version stays v0.0.0 until Episode 1 tagged. |

---

```
transcribe ~ grimoire >> collective trajectory audited, gaps surfaced // %ROADMAP_AUDITED%
```
