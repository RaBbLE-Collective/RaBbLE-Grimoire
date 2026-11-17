# Collective-ICM-Conformance-Audit.md

```
transcribe ~ collective >> ICM/MWP conformance audit — Collective already ~70% there, formalize the gaps // %ICM_AUDIT%
```

> **Status:** 🟢 AUDIT COMPLETE (2026-08-27) — findings + phased plan. No tree changes yet; this
> is the cold-start context for adopting the *substance* of ICM where it actually fits.
> **Source paper:** Van Clief & McDermott, *Interpretable Context Methodology: Folder Structure
> as Agentic Architecture*, arXiv 2603.16021v2 (17–18 Mar 2026). Presents the **Model Workspace
> Protocol (MWP)** — filesystem structure replaces framework orchestration.
> **Companions:** `Collective-Architecture-Audit-2026-07-04.md` (the S193 systemic audit — ICM is
> a lens on the same coherence problem), `EP1-Air-Push-Plan.md` (the active EP1 push).

---

## TL;DR

The Collective has **independently reinvented ~70% of ICM's substance** — the five-layer context
hierarchy — and documents the context-scoping half *better* than the paper does. The gaps are
narrow and specific.

The single most important finding: **ICM/MWP is designed for linear content-production pipelines.
The Collective is a branching multi-repo ecosystem. Do not cargo-cult `01_/02_/03_` numbered
stage folders onto the repo layout.** The paper itself names "high-concurrency" and "complex
branching mid-pipeline" as anti-patterns (§5.2) — which describes most of the ecosystem.

ICM pays off *inside* the ecosystem, on the genuinely linear, gated, repeatable workflows — which
happen to be exactly where the recurring pain (ledger clobbers, uuid misattribution, cold-start
handoffs, concurrent-session collisions) already lives.

---

## What ICM/MWP actually is

A single agent walks **numbered stage folders** (`01_research → 02_script → 03_production`). Each
stage has a `CONTEXT.md` **contract** (Inputs / Process / Outputs). Between stages, a **human
review gate**: the human inspects and edits the plain-text output before the next stage runs. The
filesystem is the state machine; markdown/JSON is the only interface. Setup once (the "factory"),
run repeatedly (the "product").

**Five-layer context hierarchy:**

| Layer | Question | Holds | ~Tokens |
|---|---|---|---|
| L0 | "Where am I?" | Global workspace identity | ~800 |
| L1 | "Where do I go?" | Task→stage routing | ~300 |
| L2 | "What do I do?" | Stage contract (Inputs/Process/Outputs) | 200–500 |
| L3 | "What rules apply?" | Reference material, stable across runs | 500–2,000 |
| L4 | "What am I working with?" | Working artifacts, per-run | varies |

Core principle the paper stresses: **L3 is internalized as constraints** ("write like this, use
these colors"); **L4 is processed as input** ("here is the previous stage's output"). Keeping them
separate is what keeps a stage's context small (2k–8k tokens, not 30k–50k where Liu et al. found
degradation).

---

## Scorecard — the five layers

| Layer | ICM wants | RaBbLE today | Grade |
|---|---|---|---|
| **L0** global identity | One identity file (~800 tok) | `AGENT.md` at root + per-member + per-Grimoire-folder, symlinked to CLAUDE/CODEX/GEMINI. The paper's own example file is literally named `CLAUDE.md`. | ✅ A |
| **L1** routing | Task→stage routing (~300 tok) | Root `CONTEXT.md`: Member Map, Entry Points, Workspace Reference table, Reading Order with token budgets. A near-perfect L1 router. | ✅ A |
| **L2** stage contracts | Per-folder `CONTEXT.md` with Inputs/Process/Outputs | Folder `CONTEXT.md`s exist (`log/plans/`, `log/handoffs/`, `registry/`) with a `workspace:` header block — but they are *descriptive readmes*, not I/P/O **contracts**. Most workflow folders have none. | 🟡 C+ |
| **L3** reference/factory | Stable-across-runs rules | The Grimoire *is* L3, executed almost perfectly. "Grimoire publishes, members reference" = ICM's "internalize L3 as constraints." Palette, Identity, Voice, CommitStyle all canonical here. | ✅ A+ |
| **L4** working artifacts | Per-run outputs in dedicated `output/` dirs, separated from reference | Plans/handoffs/session-log/ledger are plain markdown — but per-run L4 is **mixed into the same `log/` tree as L3 reference**, with no clean `output/` handoff boundary. | 🟡 C |

## Scorecard — the five design principles (§3.1)

| Principle | Grade | Note |
|---|---|---|
| One stage, one job | 🟡 | `end-session.sh` conflates ledger + LATEST synopsis + token tag — the documented clobber/misattribution source. |
| Plain text as interface | ✅ A+ | Markdown + YAML everywhere; no binary handoffs. |
| Layered context loading | ✅ A+ | Reading-Order table with explicit token budgets (~1,700 → ~15,000) is *more* rigorous than the paper's example. |
| Every output is an edit surface | ✅ A | Plans/handoffs/manifests all human-editable; commit is the gate. |
| Configure the factory, not the product | 🟡 | `setup.sh` + spells are the factory, but repeatable *runs* (a session, a plan execution) are not modeled as factory runs with a clean config/output split. |

**Net:** A on context architecture, C+ on stage-contract formalization, plus three genuinely-linear
workflows that *are* textbook ICM but are not yet structured as ICM.

---

## Where ICM genuinely helps (and where the pain already is)

Linear, gated, repeatable workflows hiding inside the ecosystem. Each is a real pipeline; each
already breaks in the ways the session log records:

1. **Session lifecycle** — `session-start → work → end-session`. Ledger clobbers, uuid
   misattribution, LATEST-header stomping. Classic "one monolithic stage doing several jobs."
2. **Plan → handoff → execute → seal** — multi-session efforts with human gates. *The* ICM use
   case, currently ad-hoc.
3. **Member onboarding** — `init-project → manifest → register → wire`. Linear, repeatable.
4. **Distill / publish** — `docs → distill-gists → sync-to-world → publish-cdn`.

---

## The plan

### Phase 0 — Decide NOT to restructure the ecosystem
Record a decision-log entry: the Collective stays branching; ICM applies to *workflows within it*,
not to the repo layout. This closes the door on the tempting-but-wrong "number every folder" move
and cites §5.2 (branching/concurrency anti-patterns) as the reason.
**Deliverable:** `log/decisions/` entry. **Risk:** none. **Owner:** Mark to ratify.

### Phase 1 — Promote L2 contracts (the core win)
Upgrade the three existing folder `CONTEXT.md`s (`log/plans/`, `log/handoffs/`, `registry/`) from
readmes to real **Inputs / Process / Outputs** contracts, and add one to each workflow folder that
lacks it (`log/decisions/`, `log/lessons/`, `gist/`, `templates/`). Ship a
`templates/CONTEXT-stage.template.md` so new folders inherit the shape.
**Deliverable:** template + converted contracts. **Risk:** low (docs only). **Parallelizable:**
one sub-agent per folder, sonnet-pinned.

### Phase 2 — Split L3 / L4 at the handoff boundary
Introduce a clean per-run `output/` convention so working artifacts stop mixing with stable
reference. Concretely: plans and handoffs keep their reference framing, but their *per-run
products* (a given session's generated ledger row, synopsis, promoted lessons) land in a named
output surface the next stage reads. This is the structural fix under the clobber symptoms.
**Deliverable:** convention doc + one migrated example. **Risk:** medium (touches spells). **Owner:**
agent proposes, Mark ratifies.

### Phase 3 — Model the session lifecycle as ICM stages
Decompose `end-session.sh`'s conflated jobs into single-purpose steps with explicit gates
(blockers → session-entry → commit → synopsis/ledger → insight-promotion → release). Each step
reads a scoped contract; each writes one plain-text output the next step consumes. Directly targets
the misattribution/clobber bugs in memory.
**Deliverable:** staged lifecycle spec + refactored spell(s). **Risk:** medium-high (behavioral).
**Precondition:** Phases 1–2 landed.

### Phase 4 — Conformance lint
Extend `grimoire-doctor.sh`: every workflow folder has a stage contract; no L3/L4 mixing; contracts
name their Inputs by path. Turns ICM conformance into something the doctor enforces, not a
one-time audit.
**Deliverable:** doctor check. **Risk:** low.

---

## Sequencing & decomposition

- **Phase 0** first, solo — it is the guardrail everything else respects.
- **Phase 1** fans out cleanly: one sonnet sub-agent per folder, each producing an I/P/O contract
  from the folder's current readme + a scan of what actually lands there.
- **Phase 2–3** are sequential and spell-touching — single-agent, Opus-reviewed, Mark-gated
  because they change session behavior.
- **Phase 4** last, once the target shape is stable enough to lint against.

## What this explicitly is NOT

- Not a rename of member repos or the `RaBbLE-*` folders.
- Not numbered stage folders in the Collective root or the Grimoire.
- Not a framework. ICM's whole thesis is *less* orchestration code, not more.

---

## Open decisions for Mark

1. **Phase 0 ratification** — agree the ecosystem layout is out of scope, workflows are in.
2. **Phase 2 output surface** — where per-run artifacts live (a `run/` sibling? a dated subdir?).
   Agent will propose; Mark picks.
3. **Phase 3 appetite** — refactor `end-session.sh` now, or freeze the spec and defer until after
   the EP1 gates (G7/G9)? The clobber pain argues for sooner; EP1 focus argues for later.

---

```
transcribe ~ collective >> ICM lens applied, gaps named, ecosystem layout protected // %ICM_AUDIT%
```
