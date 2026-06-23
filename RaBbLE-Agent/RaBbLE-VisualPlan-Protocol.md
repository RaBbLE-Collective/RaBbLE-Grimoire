# RaBbLE-VisualPlan-Protocol.md — Visual Planning for RaBbLE Agents

```
transcribe ~ grimoire >> visual plan protocol: RaBbLE-native direction // %VISUALPLAN_PROTOCOL%
```

> Plans are structured markdown in `log/plans/`. The visual render surface is
> RaBbLE's own — NeBuLA/Aether in World. No third-party plan server.
> See: `RaBbLE-Collective/RaBbLE-Plan-Surface.md` for the forward vision.

---

## What a Plan Is

A plan is a structured markdown file in `RaBbLE-Grimoire/log/plans/`.
Any agent can write one. Any agent can read and continue from one.
The Grimoire is the source of truth — no external service involved.

Use `/visual-plan` to generate plan structure and thinking. The output is
saved as markdown. The *visual render* of that markdown is RaBbLE's job —
NeBuLA/Aether in World (EP2 target, see below).

---

## When to Write a Plan

Write a plan when:
- The work spans multiple files or sessions and needs a review gate before code
- Direction needs alignment before implementation (UI layout, data shape, auth model)
- The task has hard-to-reverse decisions (wire format, public IDs, schema)
- A UI flow needs mockups or state diagrams to reason about

Skip it for: one-line fixes, single well-specified functions, anything whose
diff fits in one sentence.

---

## Plan Format — Structured Markdown

Plans live at `log/plans/<slug>.md`. One file per plan. Plain markdown with
structured sections — no special tooling required to read or continue from one.

```markdown
# Plan: <title>

> Status: draft | approved | in-progress | done
> Session: S<N> | Date: YYYY-MM-DD
> Repos: RaBbLE-OS, RaBbLE-NeBuLA, ...

## Goal
One sentence.

## Context
What informed this plan. Files read, patterns observed.

## Approach
The chosen direction with rationale. What's deferred and why.

## Steps
- [ ] Step 1 — file(s) touched
- [ ] Step 2 — file(s) touched

## Hard Decisions
Decisions that are expensive to reverse. State the choice and reason.

## Diagrams / Mockups
Mermaid diagrams, ASCII wireframes, or links to RaBbLE-Captures screenshots.

## Open Questions
Questions that would change the design if answered differently.
```

---

## Slug Naming

`<impulse>-<organ>-<topic>-S<session>`

```
spark-nebula-plan-surface-S157       ← new feature/concept
harmonize-world-rc1-polish-S142      ← cleanup plan
mend-score-auth-flow-S138            ← bug fix plan
```

---

## Workflow

```bash
# 1. Write the plan (agent or hand-written)
#    → log/plans/<slug>.md

# 2. Commit
git add log/plans/<slug>.md
git commit -m "transcribe ~ grimoire >> plan: <slug> // %PLAN_DRAFT%"

# 3. Log in SESSION-LOG.md
# Plan: log/plans/<slug>.md — <one-sentence description>

# 4. After approval, update status header → approved
# 5. During implementation, check off steps as done
# 6. On completion, update status → done
```

---

## The Visual Surface — EP2 Target

The plan markdown format is designed to be rendered by NeBuLA/Aether in World.
The vision: open a plan URL in World (`/plan/:slug`) and the document comes alive —
entity presence, animated diagrams, interactive mockup wireframes, live status.

This is an EP2 feature. The Grimoire doc for it:
`RaBbLE-Collective/RaBbLE-Plan-Surface.md`

Until then: plans are read in any markdown viewer or by any agent directly.
The structure is the feature, not the renderer.

---

## What Was Archived

A self-hosted Agent-Native plan server (agent-native/BuilderIO, MIT-licensed)
was built in S155 as an interim visual renderer. It was archived in S157 because:
- Vendor code running as a systemd service for a third-party planning UI
- The `/visual-plan` skill still instructed agents to reconnect to `plan.agent-native.com`
- Parallel drift — NeBuLA/World is the right renderer, not someone else's app
- Significant installation friction (three Ansible bugs, pnpm lockfile issues)

The Ansible role (`RaBbLE-OS/ansible/roles/apps/plans/`) is preserved as
reference but the play in `site.yml` is disabled. Remove post-EP2.
