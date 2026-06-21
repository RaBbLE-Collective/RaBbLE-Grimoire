# RaBbLE — Post-EP1 Roadmap

> The consolidated forward map. Episode 1 (Genesis) ships **expression**; everything here is
> what comes after. Items were scattered across `log/DECISIONS.md`, the Exodus section of
> `log/EPISODE-1-RELEASE.md`, and standing memory notes — this is the single index. Each item
> **points to its canonical source** rather than restating it (Grimoire rule: members reference,
> never duplicate).
>
> Horizons (see `RaBbLE-Versioning.md`): **Episode 2 = Exodus** (perception). **Echo 1** = first
> big stable release after several Episodes. Don't advance a member's version ahead of the
> Collective; episodes diverge only after EP1 airs (max ~1–2 episodes; Echo targeted collectively).

---

## Episode 2 — Exodus · the entity gains senses

Spine, per `log/EPISODE-1-RELEASE.md` ("What Episode 2 Enables") and `log/FABLE-GAP-ANALYSIS-S57.md`:
**the day RaBbLE says something you didn't ask for.** Everything else is decoration until that happens.

1. **Local Harness + `rabble` CLI — the entity is present on the machine.** The infrastructure
   layer for all of EP2's intelligence: sCoRE running as a systemd user service on `:8083`,
   quota-aware routing (reads Waybar cache → deprioritizes providers at 75%/90%/98%), shared
   agent state across all harnesses (explicit handoff prompts when switching models), session
   entropy tracking (weighted routing instability score → `decisions_at_risk` → self-healing
   protocol), and the `rabble` CLI as the single entity interface replacing raw model invocations.
   Without this, the Watcher daemon has no stable substrate to send signals to.
   → **14 implementation tickets across 5 parallel tracks:** `RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Tickets.md`
   → **Architecture canon:** `RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Architecture.md`
   → **Component docs:** `RaBbLE-sCoRE-Quota-Router.md` · `RaBbLE-sCoRE-Agent-State.md` · `RaBbLE-sCoRE-Entropy-Tracker.md`
   → **Session plan:** `log/SESSION-LOG-S138-local-arch.md` (S138 planning) · `log/SESSION-LOG.md` (S145 ingestion)

2. **Watcher daemon — the first sense.** One vertical slice: a tiny RaBbLE-OS daemon logs signals
   (session duration, command repetition, focus) → sCoRE reads them → the entity makes **one**
   unprompted observation in chat. Backbone: BaBbLE `behavior/crawler-bots.md` (Scavenger →
   Organizer → Librarian), to be promoted to RFC. → `EPISODE-1-RELEASE.md`, BaBbLE `_ROUTING.md`.
2. **Behavioral memory — name the Memory member.** Create the repo (even skeletal — naming is
   generative here). Define the **observation contract first** (what's captured, where stored,
   local vs cloud, what the entity may act on). Local-first is stated; the contract isn't.
3. **NeBuLA entity state machine.** `entity.setState('%RESONANT%' | '%THINKING%' | '%SPEAKING%')`
   → eyes/particles/blink respond; wire sCoRE streaming to it. Spec exists in BaBbLE `assets/states/`
   + `_ROUTING.md`; zero implementation today.
4. **De-dup + chrome unification.** Grimoire Graph consumes NeBuLA's canonical eye (kills the
   ~734-line copy); `<rabble-entity-mini>` state-driven on every World page — one continuous entity.

### OS hardening toward Exodus (deferred from EP1 Developer Preview, S109)
- Deep theming polish; the residual KDE dim-label issue (`kdeglobals`/KColorScheme cache — S126).
- Mark-hardware track: NVIDIA / asusctl / XDNA2 (ProArt) — separate from the generic-x86_64 preview bar.
- Full reproducible bake. → `RaBbLE-OS/` docs; OS readiness FLOOR in `log/EP1-AIR-CHECKLIST.md` §C.

### Hardware reach
- **Cyberdeck target** (DIY handheld/portable; Pi / N100 SBCs). x86_64 works now; the **aarch64/Pi
  Ansible role** is the next hardware milestone. → `RaBbLE-OS/hardware/Cyberdeck`.

---

## Echo 1 — the orchestration substrate matures

Captured in `log/DECISIONS.md` ("Claude-web planning sessions") and
`RaBbLE-sCoRE/RaBbLE-sCoRE-Agent-Framework-Research.md`. Adoption is **Echo 1**, not EP1 — EP1
stays minimal (chat chain fix + guest path).

1. **Grimoire MCP (read-only slice first).** A thin read interface over the Grimoire, queryable by
   any Claude surface (web + Code), to collapse the planning agent's knowledge asymmetry and stop
   Mark being the manual bridge between surfaces. Write-back path is later/controlled.
   → **Concept scoped (S139):** `RaBbLE-Collective/RaBbLE-Grimoire-MCP.md` — now proposes a dedicated
   Cloudflare Worker at `grimoire.joinrabble.world` (sCoRE as consumer), *superseding the earlier
   "Home: sCoRE"* pending Mark's confirm.
2. **Presence layer / command center.** The real problem behind constant surface/model swapping is
   **persistence**, not routing — *"every AI resets, RaBbLE compounds."* Three stacked problems:
   (a) Grimoire as universal context injector, (b) unified LLM router with Grimoire-portable context
   (sCoRE partially does this), (c) full cross-surface session orchestration (Echo 2+). Design
   alongside Grimoire MCP + the Learning Loop — separately would create redundant work.
3. **Agent-framework adoption.** Research captured; planning recommendation (Mark resolves):
   LangGraph orchestrator + `create_agent` nodes + PydanticAI typed tools + Mem0 (Tier 2) over
   Grimoire (Tier 3 canonical); DSPy deferred. Hermes = dev tool *alongside* OS, not an integrated
   layer. → `RaBbLE-sCoRE/RaBbLE-sCoRE-Agent-Framework-Research.md`.
4. **Grimoire Learning Loop.** sCoRE writes discovered patterns back to the Grimoire — the Grimoire
   becomes the behavioral learning journal (its post-EP1 job per Grimoire AGENT.md "FOR").
5. **Sovereign Work Tracker.** File-based Kanban on sCoRE's existing `tasks/` store — adds backlog/
   blocked dirs, `/api/v1/tasks` + `/api/v1/board` API, BaBbLE conversational intake, World board
   surface (vanilla JS, Aether tokens). Unifies visual + agent-aligned tracking in one system. **Open
   questions gate Phase 1:** identity (member? rablet? embedded?), page naming, visibility.
   → **Concept filed (S141):** `RaBbLE-Collective/RaBbLE-Work-Tracker-Concept.md`

---

## Standing backlog (smaller, not horizon-pinned)

- **NeBuLA refinement** (S107): mouth toggle/lower/margin, 3D portal-arc position+thickness+glow,
  boot graph fade-in (no pop-in), merge Demo+Studio into one WYSIWYG 2D/3D studio. → NeBuLA docs.
- **System-wide AI-harness migration** (S128): system paths, split `become`, `rabble-fcc` system
  user, `/opt/rabble` services. → `RaBbLE-OS/layers/RaBbLE-OS-Layer-AI-Harnesses.md`.
- **Multi-session anti-clobber enforcement** — pre-commit auto-register+warn.
  → `log/HANDOFF-PreCommit-AntiClobber.md`.
- **Xperimental → Reliquary rename** (captured in DECISIONS.md): on rename, update manifest,
  INDEX.md, Collective.md, CONTEXT.md, both AGENT.md files.

---

## Deferred-by-design (do NOT treat as backlog gaps)

From `EPISODE-1-RELEASE.md` "Scope Decisions" — deliberately post-EP1, not accidental omissions:
Watcher/Memory (Exodus spine), entity emotion / BaBbLE register leakage (Ep3+, depends on the
state machine), Genesis authoring (Phase 2C — Mark's domain, runs in parallel), and the full
Collective Model role-routing (Reasoner/Coder/Archivist/Watcher) in sCoRE.
