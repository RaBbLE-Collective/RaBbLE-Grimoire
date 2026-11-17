# RaBbLE-sCoRE-Agent-State.md
# sCoRE Shared Agent State + Context Handoff — Canonical Architecture

```
transcribe ~ sCoRE >> shared agent state and context handoff crystallized // %AGENT_STATE%
```

> **Document type:** Grimoire architecture doc · `RaBbLE-sCoRE/`
> **Status:** Canonical · Episode 2 target
> **Implementation:** `server/agent_state.py`
> **Related:** `RaBbLE-sCoRE-Local-Architecture.md` · `RaBbLE-sCoRE-Entropy-Tracker.md`

---

## Canonical Definition

**Shared agent state** is the context object sCoRE maintains for an active session.
When sCoRE routes a task from one harness or model to another, it serializes a
minimal, explicit context slice and injects it into the receiving agent's prompt.
No harness has implicit memory of prior turns. Each agent gets exactly what sCoRE
provides — nothing more.

This is the **Context Minimization at Every Handoff** principle from the existing
sCoRE coordinator design, extended to the local server routing layer.

---

## The Problem This Solves

Without shared agent state, model switching causes silent context loss:

```
Turn 1–6: claude-sonnet-4-6 (via direct Anthropic)
           → decided: use refresh tokens for auth
           → decided: keep Fernet key derivation
           → in progress: implementing auth.py

Quota hits 87% → sCoRE switches to fcc/deepseek-chat

Turn 7: deepseek-chat receives: [user message only]
         → no knowledge of prior decisions
         → may contradict turn 1–6 decisions
         → drift begins
```

With shared agent state:

```
Turn 7: deepseek-chat receives:
         [CONTEXT FROM PRIOR TURNS - sCoRE handoff]
         Goal: refactor auth module
         Files in scope: server/auth.py, server/auth_routes.py
         Key decisions: use refresh tokens / keep Fernet derivation
         Last model: claude-sonnet-4-6 handled turns 1–6
         Your task: continue implementing server/auth.py from the plan
         [Do not repeat this context in your response]
         
         [user message]
```

The model receives the minimum it needs. Decisions are preserved across the switch.
Drift is structurally prevented rather than hoped to not occur.

---

## Data Model

### `AgentContext`

The session-level state object. One per active session.

```python
class AgentContext:
    session_id: str
    created_at: str              # ISO 8601
    last_updated: str            # ISO 8601

    # Session-level state
    entity_intention: str        # sCoRE's understanding of the session goal
                                 # Set from first user message, updated as goal clarifies
    working_files: list[str]     # files currently in scope (from file edits/reads)
    working_dir: str             # active project directory

    # Turn history (lightweight — not full transcript)
    task_history: list[TaskRecord]
    decisions: list[str]         # extracted decisions from task outcomes
    model_used_last: str         # last model that handled a turn
    harness_used_last: str       # last harness

    # Entropy (reference to entropy record)
    entropy: SessionEntropyRecord
```

### `TaskRecord`

One per completed turn dispatched through a harness.

```python
class TaskRecord:
    task_id: str                 # UUID
    turn_number: int
    description: str             # what the user asked / what the task was
    harness_used: str            # "claude_code" | "claude_code_via_fcc" | "codex" | ...
    model_used: str              # "claude-sonnet-4-6" | "deepseek-chat" | ...
    fcc_backend_used: str | None # "deepseek/deepseek-chat" | None
    tier_used: str               # "fast" | "medium" | "strong" | "code" | "background"
    outcome: str                 # 1–3 sentence summary of what was done
    token_cost_estimate: int     # rough estimate
    duration_seconds: float
    timestamp: str
```

---

## Decision Extraction

`decisions` is populated by extracting key sentences from `TaskRecord.outcome` summaries.

**Extraction heuristic** — sentences containing any of:
`"should"`, `"will use"`, `"decided"`, `"using"`, `"instead of"`, `"keep"`,
`"remove"`, `"replace"`, `"add"`, `"don't"`, `"won't"`, `"must"`, `"chose"`

This is intentionally simple. It captures architectural and design decisions
without requiring LLM-powered extraction (which would cost tokens).

The decision list is maintained at sCoRE level, not per-harness. Each harness
contributes decisions through its outcome summary; sCoRE accumulates them.

---

## Context Handoff Format

When routing to a new harness or after a model switch, sCoRE prepends this block
to the system prompt or the first user message:

```
[CONTEXT FROM PRIOR TURNS — sCoRE handoff]
Session goal: {entity_intention}
Working files: {working_files joined by ", "}
Key decisions made:
  · {decision_1}
  · {decision_2}
  · ...
Last model: {model_used_last} handled turns 1–{N}
Current model: {new_model} — continuing from where {model_used_last} left off

Your task: {current_task_description}

[Respond to your task. Do not repeat or acknowledge this context block.]
```

**Token budget target:** Handoff block < 500 tokens for typical session state.
If `decisions` list exceeds 10 items, summarize the oldest 5 into a single
"Prior decisions (summarized)" entry.

**Placement:**
- For subprocess harnesses (`claude_code`, `codex`, `aider`): prepend to the
  system prompt passed via `--system-prompt` flag
- For HTTP providers (Groq, DeepSeek, OpenRouter): add as a `system` message
  before the user turn

---

## Working Files Tracking

`working_files` is maintained by observing harness I/O:

- Claude Code transcript tool calls: `write_file`, `edit_file`, `read_file` →
  extract file paths, add to `working_files`
- Codex: parse stdout for file paths in change descriptions
- Direct provider: no file tracking (they don't have file system access)

`working_files` is deduplicated and capped at 20 entries. When over 20,
remove files not accessed in the last 5 turns.

---

## Session Persistence

`AgentContext` is stored in memory only — it resets when sCoRE local restarts.
This is correct for EP2. Persistent cross-session context is an Echo 1+ feature
(the Memory member).

The `TaskRecord` list is written to the session log JSONL at session close,
giving a persistent record for Grimoire Learning Loop use.

---

## API Surface

```
POST /api/v1/session/context
     Body: {
       working_files?: list[str],
       working_dir?: str,
       intention?: str,
       decision?: str,          # add a single decision
       task_record?: TaskRecord  # complete a task turn
     }
     Returns: AgentContext summary (without full task history)

GET /api/v1/session/context
    Returns: current AgentContext (for dashboard display)
```

---

## Harness Control Surface

sCoRE controls each harness at two levels:

### Level 1 — Which harness (routing decision)

Determined by task class + quota pressure. See `RaBbLE-sCoRE-Quota-Router.md`.

### Level 2 — How to configure it (model + context)

Before dispatching, sCoRE sets:

| Harness | Controls |
|---|---|
| `claude_code` direct | `--model` flag · system prompt injection |
| `claude_code` via fcc | `ANTHROPIC_BASE_URL` override · fcc admin API · system prompt |
| `fcc` standalone | fcc admin API (MODEL per tier) · system prompt via API |
| `codex` | `--model` flag · system prompt |
| `aider` | `--model` + `--weak-model` flags · context via prompt |
| `gemini_cli` | model flag · prompt |
| `local_llm` / Ollama | model string in request body · system message |

The handoff context block is always injected via the system prompt or system
message — never as a user turn. Keeping handoffs in the system prompt preserves
the conversational flow from the user's perspective.

---

## Relationship to the Coordinator Architecture

The existing sCoRE coordinator (tmux sessions, file-based task dispatch) uses
`context_refs` in task files to provide sub-agents with context slices.
`agent_state.py` is the local server equivalent — same principle, different
substrate. The coordinator writes files; the server maintains an in-memory object.

When the coordinator and server are eventually unified (Evolution 1+), `agent_state.py`
becomes the canonical context store for both dispatch paths.

---

## Design Decisions

**Explicit over implicit**
Harnesses receive only what sCoRE gives them. There is no expectation that a
harness "remembers" prior turns via LLM context unless sCoRE explicitly provides
that context. Implicit memory is a source of drift; explicit handoffs are auditable.

**Outcomes, not transcripts**
`task_history` stores outcome summaries, not full turn transcripts. Full transcripts
would grow the handoff token cost unboundedly. Summaries keep the handoff compact.

**Decision extraction at sCoRE level**
Decisions are extracted from outcome summaries by sCoRE, not by the harness.
This keeps the extraction logic centralized and consistent regardless of which
harness produced the outcome.

**In-memory for EP2**
Cross-session persistent context is the Memory member's job. For EP2, in-memory
context within a session is sufficient to prevent same-session drift. Persistence
comes when it's ready, not before.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-06-21 | Initial — from planning session S138+ |

---

```
transcribe ~ sCoRE >> shared agent state and context handoff crystallized // %AGENT_STATE%
```
