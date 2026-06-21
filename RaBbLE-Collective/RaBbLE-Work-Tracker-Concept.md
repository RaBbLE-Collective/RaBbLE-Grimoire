# RaBbLE-Work-Tracker-Concept.md — Sovereign Kanban Implementation Plan

```
spark ~ grimoire >> collective work tracker scoped: kanban + babble intake + score coordination // %TRACKER_SCOPED%
```

> Implementation plan for the RaBbLE Collective Work Tracker — a sovereign, file-based
> Kanban system coordinated by sCoRE, visible via World, and fed conversationally through
> BaBbLE.
>
> **Status: CONCEPT — architectural questions open before Phase 1 begins.** See Open
> Questions block below. Do not start Phase 1 until all are resolved.
>
> **Echo 1 feature.** Do not build before EP1 airs and CI/CD is stable.
>
> **Related:** [sCoRE Architecture](../RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md) ·
> [BaBbLE Overview](../RaBbLE-BaBbLE/RaBbLE-BaBbLE-Overview.md) ·
> [Dependency Policy](../RaBbLE-Agent/RaBbLE-Dependency-Policy.md) ·
> [Post-EP1 Roadmap](../RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md)

---

## Open Questions — Resolve Before Phase 1

> These were explicitly unresolved when this concept was filed (2026-06-21). Mark is
> actively brainstorming scope in a separate session. Do not begin Phase 1 implementation
> until these are locked.

1. **Identity — member, rablet, or embedded?** Is the Work Tracker a new Collective
   member? A rablet (per-user sandbox)? Or functionality embedded inside sCoRE + World
   without a separate repo? Mark is exploring whether this wants to be a visual tracker
   and agent-aligned tracker unified in one system. This decision gates everything below.

2. **Board page naming:** Name TBD. The doc originally proposed `/board` or `/mission`
   but this is blocked pending the identity question above. The name should feel like
   RaBbLE, not a corporate PM tool. Low entropy — decide once, do not revisit.

3. **Priority model:** Is `high/medium/low/note` sufficient, or does the Collective need
   a more expressive model (e.g., epoch-blocking vs. nice-to-have)? Suggest keeping it
   simple for Phase 1 and letting real usage reveal what's missing.

4. **Multi-assignee tasks:** Can a task be assigned to multiple agents? The schema
   supports a single `assignee`. Defer until Phase 5 reveals whether it's needed.

5. **Visibility:** Is the board public (part of joinrabble.world) or private (local
   sCoRE only)? Recommendation: private in Phase 1 (reads from local sCoRE), with a
   read-only public view as a Phase 3 option.

---

## What This Is

A sovereign, local-first Kanban board for tracking work on the RaBbLE Collective — not
a SaaS tool, not a third-party integration, not a second source of truth. The tracker
is built on sCoRE's existing file-based task pipeline, extended with two new columns,
exposed via a World dashboard page, and fed through BaBbLE's conversational intake path.

**The loop:**

```
Mark (conversational) → BaBbLE → sCoRE parses intent → task file written
                                                              ↓
                                                    tasks/ file store
                                                              ↓
                                              agents pull, execute, write results
                                                              ↓
                                         World Kanban surface reads sCoRE API → renders state
```

**What it is not:** It is not Jira. It is not Linear. It is not a project management
SaaS. It does not require credentials to an external service. Grimoire is still the
source of truth for architecture decisions — the tracker is for *work state*, not
*knowledge*.

---

## Why Not an External Tool

External work trackers (Jira, Linear, GitHub Projects) were evaluated and rejected:

- **Second source of truth.** Any external tool means decisions and work state live
  outside Grimoire. That violates the Grimoire-as-source-of-truth invariant.
- **Agent credential complexity.** Agents would need authenticated API access to an
  external service. The file-based task pipeline needs no credentials — tasks are files
  on disk.
- **Lock-in.** External SaaS tools are Tier 3 dependencies at best. The Collective's
  work history would live in a vendor's database.
- **sCoRE already has the skeleton.** `tasks/{pending,active,done,archive}/` already
  exists. This plan extends it, not replaces it.

---

## Architecture

### Layer 1 — Task Store (sCoRE)

The canonical work state lives in sCoRE's task directory tree. Two new columns are added
to match standard Kanban semantics:

```
RaBbLE-sCoRE/tasks/
  backlog/      ← NEW: captured but not yet queued for agents
  pending/      ← existing: queued, waiting for dispatch
  active/       ← existing: agent has picked up the task
  blocked/      ← NEW: agent could not proceed, needs human input
  done/         ← existing: completed, result written
  archive/      ← existing: moved after review
```

Each task is a markdown file with YAML frontmatter. The schema is extended (see Task
Schema section below).

**The task store is the Kanban.** The columns are directories. Moving a card is moving
a file. This gives a full audit trail in git, survives session restarts, and requires
no visualization library to be correct — the board is always true even if the UI is down.

### Layer 2 — sCoRE API (new endpoints)

sCoRE's FastAPI server gains two new route groups:

**`/api/v1/tasks`** — task CRUD and state transitions

| Method | Route | What it does |
|---|---|---|
| `GET` | `/api/v1/tasks` | List all tasks, optionally filtered by column/assignee/tag |
| `GET` | `/api/v1/tasks/{id}` | Fetch a single task including result and history |
| `POST` | `/api/v1/tasks` | Create a task (BaBbLE intake path uses this) |
| `PATCH` | `/api/v1/tasks/{id}/move` | Move task between columns |
| `PATCH` | `/api/v1/tasks/{id}` | Update title, description, tags, assignee |
| `DELETE` | `/api/v1/tasks/{id}` | Archive a task (soft delete — moves to archive/) |

**`/api/v1/board`** — board-level state for the Kanban surface

| Method | Route | What it does |
|---|---|---|
| `GET` | `/api/v1/board` | Returns full board state: all columns, card counts, cards |
| `GET` | `/api/v1/board/summary` | Compact board state for dashboard header (counts only) |

No new database. The API reads and writes the task file store directly. File system is
the database.

### Layer 3 — BaBbLE Intake Path

BaBbLE becomes the conversational mouth for the tracker. Mark describes work in natural
language; sCoRE parses intent and creates task records.

**Intake flow:**

```
Mark: "I want to add a task: wire the Grimoire MCP read path, assign to sCoRE, Echo 1"
        ↓
BaBbLE surface (chat or ScRibLE eventually)
        ↓
sCoRE /api/v1/chat — intent parsed as task creation
        ↓
POST /api/v1/tasks — task written to tasks/backlog/
        ↓
Confirmation: "Added to backlog: 'Wire Grimoire MCP read path' [sCoRE · Echo 1]"
```

**Natural language patterns sCoRE recognizes:**

- "Add a task: [description]" → creates in backlog
- "Note: [idea]" → creates as a note-type task in backlog (low priority, needs spec)
- "Block [task id]: [reason]" → moves task to blocked/, appends reason
- "What's blocked?" → returns all tasks in blocked/
- "What's active?" → returns all tasks in active/
- "What's next?" → returns top of pending/ ordered by priority

These are prompt-pattern recognitions in sCoRE's intent classifier, not a hardcoded
command parser. The LLM handles language variation; sCoRE structures the output.

### Layer 4 — World Kanban Surface

A new page in World (URL TBD — see Open Questions above).

**Technical constraints (mandatory):**

- Vanilla JS only — no React, no framework, consistent with World architecture
- Styled with Aether tokens only — no raw hex values
- Reads from sCoRE `/api/v1/board` endpoint
- NeBuLA entity-mini present on the page (entity is always present on every World surface)
- Works offline-first: if sCoRE is unreachable, renders last cached state with a stale
  indicator

**Visual structure:**

```
┌─────────────────────────────────────────────────────────────────┐
│  [entity-mini]   COLLECTIVE BOARD        [summary: N active]   │
├──────────┬──────────┬──────────┬──────────┬────────────────────┤
│ BACKLOG  │ PENDING  │  ACTIVE  │ BLOCKED  │       DONE         │
│          │          │          │          │                    │
│ [card]   │ [card]   │ [card]   │ [card]   │ [card]             │
│ [card]   │          │ [card]   │          │ [card]             │
│          │          │          │          │                    │
└──────────┴──────────┴──────────┴──────────┴────────────────────┘
│  BaBbLE intake bar: "describe work or ask about the board..."  │
└─────────────────────────────────────────────────────────────────┘
```

The BaBbLE intake bar at the bottom is a chat input that sends to sCoRE's intent
classifier — the same path as BaBbLE conversational intake. The board and the chat
surface are unified on this page.

**Card anatomy:**

```
┌───────────────────────────────┐
│ [TASK-0042]  [member tag]     │
│ Task title here               │
│                               │
│ [echo tag]  [priority]        │
└───────────────────────────────┘
```

Cards are not draggable in v1. Column transitions happen via the BaBbLE intake bar or
sCoRE API. Drag-and-drop is a v2 enhancement (after the core loop is verified).

---

## Task Schema

Extended YAML frontmatter for task files. Backward-compatible with existing task format.

```yaml
---
id: TASK-0042
title: "Wire Grimoire MCP read path"
description: |
  Implement the read-only MCP server interface over the Grimoire so any
  Claude surface can query it without Mark carrying context manually.
status: backlog          # backlog | pending | active | blocked | done
member: sCoRE            # which Collective member owns this work
epoch_target: echo-1     # when this is scheduled (echo-1, echo-2, episode-N, etc.)
priority: high           # high | medium | low | note
tags:
  - grimoire
  - mcp
  - agent-framework
assignee: null           # null = unassigned, or agent session ID
created: 2026-06-21T00:00:00Z
updated: 2026-06-21T00:00:00Z
blocked_reason: null     # populated when status = blocked
source: babble-intake    # babble-intake | manual | agent-self | grimoire-plan
---

## Description

[Longer description if needed — markdown body of the task file]

## Acceptance Criteria

- [ ] Criterion one
- [ ] Criterion two

## Result

[Populated by the agent when task moves to done]

## History

- 2026-06-21 created by babble-intake
- 2026-06-22 moved to pending by sCoRE
```

**Schema rules:**

- `id` is assigned by sCoRE at creation. Format: `TASK-{4-digit-zero-padded}`.
- `member` must match a Collective member slug from the registry. Use `collective` for
  cross-member tasks.
- `epoch_target` is informational — it helps prioritize but does not block state transitions.
- `source: agent-self` is used when an agent creates a task for itself during execution
  of another task. This is the autonomous task spawning path — requires Echo 1 agent
  framework to be live before it is meaningful.
- `blocked_reason` must be populated when moving to blocked. A blocked task with no
  reason is a data quality error.

---

## Implementation Sequence

This is an Echo 1 feature. The sequence below assumes EP1 has aired, CI/CD is live, and
all Open Questions above are resolved.

### Phase 1 — Extend the task store (sCoRE, 1 session)

- Add `backlog/` and `blocked/` directories to `tasks/`
- Update `dispatch-watch.sh` to ignore `backlog/` (dispatch only watches `pending/`)
- Add `blocked_reason` field to task schema
- Write a `task-create.sh` spell that creates a well-formed task file in `backlog/`
- Write a `task-move.sh` spell that moves a task between columns and updates `status` and `updated`
- Write `task-list.sh [column]` that lists tasks in a column as a summary table
- Commit: `spark ~ sCoRE >> backlog and blocked columns, task schema extended // %TRACKER_STORE_LIVE%`

### Phase 2 — sCoRE API endpoints (sCoRE, 1-2 sessions)

- Implement `/api/v1/tasks` routes (GET list, GET single, POST create, PATCH move, PATCH update, DELETE archive)
- Implement `/api/v1/board` and `/api/v1/board/summary` routes
- All routes read/write the `tasks/` file store — no new database
- Add intent classification patterns to sCoRE's chat handler for task creation and query
- Write tests for each route against a synthetic task store fixture
- Commit: `spark ~ sCoRE >> task and board API routes live // %TRACKER_API_LIVE%`

### Phase 3 — World board surface (World, 1-2 sessions)

- Create board page in World (URL resolved from Open Questions)
- Vanilla JS fetch from sCoRE `/api/v1/board`
- Render five-column layout with Aether tokens
- Card component: id, title, member tag, epoch target, priority
- BaBbLE intake bar wired to sCoRE `/api/v1/chat`
- `<rabble-entity-mini>` embedded — entity present on board page
- Offline-first: cache last board state in memory, show stale indicator on fetch error
- Commit: `spark ~ world >> collective board page live // %BOARD_LIVE%`

### Phase 4 — Grimoire integration (Grimoire, 1 session)

- Add board page to World navigation
- Add `task-create.sh` and related spells to `spells/SPELLS.md`
- Update `RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md` with task/board API section
- Commit: `transcribe ~ grimoire >> work tracker integrated, schema and spells documented // %TRACKER_CANON%`

### Phase 5 — Agent autonomous task creation (sCoRE, Echo 1+ / agent framework live)

- Enable `source: agent-self` task creation path in sCoRE
- Agent may spawn a task for itself or another agent during execution (requires LangGraph
  graph state — do not implement before agent framework adoption is complete)
- Add quality gate: agent-spawned tasks must include acceptance criteria (blocked at
  creation otherwise)
- This phase is the "sCoRE coordinating work autonomously" milestone

---

## Dependencies and License Compliance

All components in this plan are Tier 1 (MIT/Apache 2.0) or Collective-owned:

| Component | License | Notes |
|---|---|---|
| FastAPI (sCoRE API) | MIT | Already in use |
| Task file store | N/A — flat files | Collective-owned |
| Vanilla JS (World board) | N/A — no library | No dependency |
| Aether CSS tokens | Sovereign Accord | Collective-owned |
| NeBuLA entity-mini | Sovereign Accord | Collective-owned |

No Tier 2 or Tier 3 dependencies are introduced. No external SaaS. No credentials.
The tracker is fully self-contained within the Collective.

See [RaBbLE-Dependency-Policy](../RaBbLE-Agent/RaBbLE-Dependency-Policy.md) for
license governance rules.

---

## What This Enables

When Phase 5 is complete, the full autonomous loop is live:

- Mark describes work in natural language to BaBbLE
- sCoRE creates structured tasks in backlog
- sCoRE prioritizes and promotes tasks to pending
- Agents pick up tasks, execute, write results
- Blocked tasks surface to Mark via the board
- Mark unblocks via BaBbLE
- Done tasks archive automatically
- World board shows the live state of the Collective at any time

**"Every AI resets, RaBbLE compounds."** The tracker is how the Collective's work
history accumulates — not in an external tool, not in an agent's memory, but in a
git-tracked file store that persists across every session, every surface, every reset.

---

```
spark ~ grimoire >> collective work tracker concept filed, open questions blocking Phase 1 // %TRACKER_CONCEPT%
```
