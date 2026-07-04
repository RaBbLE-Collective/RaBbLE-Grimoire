# Collective Architecture Audit — Plan + Orchestration Prompt

**Status:** proposed, not yet run (S192)
**Owner:** Mark, to be executed by a fable-5 orchestrator agent with parallel sub-agents
**Relation to EP1:** orthogonal to G7/G9 gates. Audit + design docs only, zero code changes — safe to run pre-gate. Any *implementation* of findings (esp. the sCoRE refactor) should wait until after G7/G9 land, per the vertical-slice-before-broadening rule in AGENT.md — don't destabilize the gate branch with a mid-flight restructure.

## Why

Mark wants a full-Collective recon: audit all member code, surface gaps and architectural oversights, and produce design-improvement plans per member. Named concern: **RaBbLE-sCoRE's architecture is flat and needs to be more extensible.**

Confirmed by recon (S192): `RaBbLE-sCoRE/server/` is ~16 Python files in a single flat directory with no subpackages — `llm.py` (689 lines), `main.py` (496), `jane.py` (440), `auth_routes.py` (267) all sit side by side with no domain boundaries. Meanwhile `RaBbLE-sCoRE/agents/` already has concept docs (`execution.md`, `memory.md`, `score.md`, `search.md`) implying domain boundaries the code layout doesn't reflect. That mismatch — documented domains vs. flat file-per-concern implementation — is the concrete oversight to design against.

## Scope — members in play

| Member | Track | Note |
|---|---|---|
| RaBbLE-Grimoire | primary | knowledge layer, source of truth — audit for doc/registry drift, not code |
| RaBbLE-sCoRE | primary | **deep-dive target** — flat `server/` module layout |
| RaBbLE-World | primary | assembler-only per S182 refactor — check nothing crept back in |
| RaBbLE-Aether | primary | CSS/theme engine — check token discipline, CDN build |
| RaBbLE-NeBuLA | primary | effects/rendering — check Three.js de-dup backlog item |
| RaBbLE-OS | active/dev-preview | installer + Ansible + dotctl — large surface, likely needs its own sub-agent pass |
| RaBbLE-BaBbLE | intake | high-entropy by design — audit lightly, don't over-structure |
| RaBbLE-Chrysalis | archive | genesis archive — recon only, no design-improvement expected |
| RaBbLE-Xperimental | sandbox | active rablet sandbox (RaBbLE-Voice vocoder work) — check for reusable patterns worth promoting |
| RaBbLE-Captures | utility | small — quick pass |

## Orchestration design

**Orchestrator:** one fable-5 agent (model: `fable`), general-purpose type, no worktree isolation (read + Grimoire-doc-writes only, nothing destructive).

**Sub-agents:** one per member repo (or one for the small/archive ones combined), run in parallel, each with a disjoint scope:
- Reads only inside its assigned member directory (plus that member's own AGENT.md/CONTEXT.md, plus the Grimoire gists for shared context)
- Writes only to one scratch findings file per member — no shared file contention between sub-agents
- Returns a short summary to the orchestrator; full detail lives in the findings file

**Each sub-agent's task:**
1. Read the member's `AGENT.md` + `CONTEXT.md` first — establish what the member *claims* to be.
2. Map the actual directory/module structure — what it *is*.
3. Identify gaps: missing tests, dead/orphaned code, undocumented public surfaces, TODOs left stale.
4. Identify architectural oversights: flat/monolithic modules where domain boundaries are implied elsewhere (docs, folder names) but not enforced in code; tight coupling; duplicated logic that should live in a shared member (e.g. CSS in World that belongs in Aether); layering violations.
5. **Do not modify code.** Recon and analysis only.
6. Cite every finding as `file:line`.

**Orchestrator synthesis:**
- Cross-repo audit doc: what's shared/systemic (e.g. patterns repeating across members) vs. member-specific.
- Per-member design-improvement plan, each ending in an explicit "open decisions for Mark" list — this is a peer-collaborator project; the orchestrator proposes, it doesn't unilaterally decide architecture.
- sCoRE gets its own deep-dive doc: 2–3 concrete restructuring options with tradeoffs (e.g. domain subpackages mirroring `agents/*.md` — `server/core/`, `server/agents_runtime/`, `server/memory/`, `server/search/` — vs. a ports/adapters split), not a single mandated rewrite.

## Deliverables (all land in Grimoire, indexed in INDEX.md)

- `RaBbLE-Grimoire/log/plans/Collective-Architecture-Audit-<date>.md` — cross-repo synthesis
- `RaBbLE-Grimoire/log/plans/sCoRE-Extensibility-Refactor-Plan.md` — sCoRE deep-dive, options + tradeoffs
- Per-member sections folded into the cross-repo doc, unless a member's findings are large enough to warrant its own file (sCoRE, OS likely; others probably not)
- INDEX.md updated with new entries under "Plans (active)"

## Guardrails (from AGENT.md + memory)

- Grimoire is the source — findings and plans go in Grimoire, never duplicated into member repos.
- Low entropy — don't propose scaffolding for anything not yet decided; flag options, don't build them.
- Peer collaborator — no unilateral architecture decisions; every plan ends with open questions for Mark.
- Cite sources — every cross-repo claim needs file:line.
- Don't touch code in this pass — audit and design only. Implementation is a separate, later, explicitly-approved task.

---

## Ready-to-use orchestrator prompt

```
You are auditing the RaBbLE Collective, a multi-repo personal Behavioral
Learning Engine project owned by Mark McConachie. RaBbLE is designed as an
entity/peer collaborator, not a tool — an anti-assistant stance. sCoRE is the
first iteration of RaBbLE itself. The Collective repo (this working directory)
is the coordination layer; each RaBbLE-<Member> subdirectory is an
independent git repo with its own AGENT.md/CONTEXT.md.

Read /home/rabble/RaBbLE-Collective/CLAUDE.md and
/home/rabble/RaBbLE-Collective/RaBbLE-Grimoire/gist/*.md first for full
context on conventions, rules, and current state.

YOUR TASK: audit all member repos, find gaps and architectural oversights,
and produce design-improvement plans. Do NOT modify any code — this is
recon + design only. Spawn one sub-agent per member repo below, run them in
parallel, each scoped ONLY to its assigned repo (read there, plus that
repo's own AGENT.md/CONTEXT.md and the Grimoire gists; write ONLY to its own
scratch findings file) so there's no file contention between sub-agents.

Members and known context:
- RaBbLE-Grimoire — knowledge layer/source of truth. Audit for doc/registry
  drift, not code quality.
- RaBbLE-sCoRE — DEEP-DIVE TARGET. server/ is ~16 flat Python files
  (llm.py 689 lines, main.py 496, jane.py 440, no subpackages) despite
  agents/*.md (execution.md, memory.md, score.md, search.md) implying
  domain boundaries the code doesn't reflect. Propose 2-3 concrete
  restructuring options with tradeoffs — do not mandate one.
- RaBbLE-World — should be assembler-only (state + assembly), consuming
  Aether (CSS) and NeBuLA (effects) — verify nothing has crept back in
  since the S182 Framework Refactor.
- RaBbLE-Aether — CSS/theme engine, should be the only source of design
  tokens/hex values across the Collective.
- RaBbLE-NeBuLA — effects/rendering engine (Canvas2D + Three.js).
- RaBbLE-OS — installer/Ansible/dotctl, large surface, developer-preview
  track for Episode 1.
- RaBbLE-BaBbLE — intentionally high-entropy intake workspace. Audit
  lightly; don't propose structure it isn't meant to have.
- RaBbLE-Chrysalis — genesis archive/reliquary. Recon only, no
  design-improvement plan expected.
- RaBbLE-Xperimental — active rablet sandbox (in-progress: RaBbLE-Voice
  vocoder). Check for patterns worth promoting to a stable member.
- RaBbLE-Captures — small utility repo, quick pass.

Each sub-agent must:
1. Read the member's AGENT.md + CONTEXT.md first.
2. Map real directory/module structure against what the docs claim.
3. Find gaps: missing tests, dead/orphaned code, undocumented public
   surfaces, stale TODOs.
4. Find architectural oversights: flat/monolithic modules where domain
   boundaries are implied but not enforced; tight coupling; duplicated
   logic that belongs in a different member; layering violations.
5. NOT touch any code — analysis only.
6. Cite every finding as file:line.
7. Write findings to a scratch file, return a concise summary.

After all sub-agents report back, synthesize:
1. A cross-repo audit doc covering systemic patterns vs. member-specific
   issues.
2. A per-member design-improvement plan, each ending with an explicit
   "open decisions for Mark" section — you are a peer collaborator on this
   project, not the final architectural authority. Propose, don't decide.
3. A dedicated sCoRE extensibility deep-dive: 2-3 restructuring options
   (e.g. domain subpackages mirroring agents/*.md, or a ports/adapters
   split) with concrete tradeoffs for each.

Write all deliverables into RaBbLE-Grimoire/log/plans/ following existing
naming conventions (see other files in that directory for style), and list
them for the user to add to INDEX.md. Do not duplicate this content into
any member repo — Grimoire is the single source of truth. Keep proposals
scoped to what's been asked; don't scaffold anything not yet decided.
```

## Open decision for Mark

Run this now (spawns ~8-10 parallel sub-agents doing full-repo reads — a real token/cost commitment), or save this plan and run it fresh in a dedicated session per the usual large-work pattern?
