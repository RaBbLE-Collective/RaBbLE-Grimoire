# RaBbLE-sCoRE-Architecture.md

```
transcribe ~ grimoire >> sCoRE architecture crystallized // %EPOCH_0_ARCH%
```

## System Role

sCoRE is the coordination server of the RaBbLE Collective.
It is the single point where human intent enters the system and is decomposed into
delegated actions. It has no execution surface of its own — delegation is its only output.

---

## Component Map

```
┌─────────────────────────────────────────────────────────┐
│            HUMAN INTENT — two entry modes               │
│  (a) direct session: rabble-shell.sh                   │
│  (b) HTTP: server/ FastAPI on :8000                    │
└──────────┬──────────────────────┬───────────────────────┘
           │                      │
           ▼ (a)                  ▼ (b)
┌──────────────────┐   ┌──────────────────────────────────┐
│  RaBbLE-sCoRE    │   │  server/ (FastAPI)                │
│  Claude Code     │   │  Groq + OpenRouter direct routing │
│  score.md id     │   │  Chat · Workflows · Auth          │
│  No Bash/Web     │   │  Local or Railway-deployed        │
└────────┬─────────┘   └──────────────────────────────────┘
         │ writes TASK-{ID}-{agent}.md
         ▼
┌─────────────────────────────────────────────────────────┐
│                  rabble-dispatch                        │
│  inotifywait on tasks/pending/                         │
│  Routes task files → agent tmux sessions               │
│  Moves: pending/ → active/ on pickup                   │
└──────────┬──────────────┬──────────────┬───────────────┘
           │              │              │
           ▼              ▼              ▼
    rabble-memory  rabble-search  rabble-execution
    (patterns,     (web search,   (bash, system
     context)       fetch)         commands)
           │              │              │
           └──────────────┴──────────────┘
                          │
                          ▼ writes TASK-{ID}-{agent}-result.md
                    tasks/done/
                          │
                          ▼
                    sCoRE reads → reasons → next task or done
```

**Note:** server/ routes do not currently pass through the task pipeline.
Wiring HTTP requests into sCoRE's file-based dispatch is a future episode.

---

## Task Lifecycle

```
1. sCoRE writes   → tasks/pending/TASK-{ID}-{agent}.md
2. dispatch picks → moves to tasks/active/, routes to agent session
3. Agent executes → writes result to tasks/done/
4. dispatch moves → tasks/active/ → tasks/archive/
5. sCoRE reads    → tasks/done/ result → continues reasoning
```

---

## Key Design Decisions

**File-based delegation over API calls**
Every task delegation is a file write. This gives a full audit trail, survives session
restarts, and makes the system debuggable without instrumentation.

**inotify over polling**
Kernel-level interrupt for zero CPU overhead on idle. No sleep loops. No missed events.

**Agent isolation via CLAUDE.md constraints**
Each agent session runs Claude Code with its own identity file. sCoRE's settings.json
blocks Bash/Web at the tool level — not just by instruction.

**Context minimization at every handoff**
Task files include only what the agent needs (via context_refs). Agents have no implicit
memory of prior tasks — they get exactly what sCoRE provides, nothing more.

---

## Session Architecture (tmux)

| Session | Identity | Constraints |
|---|---|---|
| `rabble-score` | `agents/score.md` | No Bash, No Web |
| `rabble-dispatch` | shell script | No Claude — pure bash |
| `rabble-memory` | `agents/memory.md` | Read/write workspace only |
| `rabble-search` | `agents/search.md` | Web access permitted |
| `rabble-execution` | `agents/execution.md` | Full Bash access |
| `rabble-server` | uvicorn (FastAPI) | Optional — `--with-server` flag |

## Server Subcomponent (server/)

The `server/` directory contains the FastAPI intelligence service absorbed from RaBbLE-Server.
It provides HTTP transport so sCoRE can be consumed by frontends (RaBbLE-World, NeBuLA) or
called remotely.

| File | Role |
|---|---|
| `main.py` | All routes — health, chat, workflows, auth |
| `llm.py` | Multi-provider routing (Groq → OpenRouter fallback) |
| `agents.py` | RaBbLE persona definitions + workflow classifier |
| `workflows.py` | In-memory workflow state (4-hour TTL) |
| `auth.py` | JWT + API key authentication |
| `rate_limit.py` | Sliding-window rate limiter |

Deployment: `harness/local.sh` (local) · `harness/deploy.sh` (Railway)

---

## Server / Coordinator Split Decision

**Decision: keep coupled in the same repo.**

The server (`server/`) is sCoRE's HTTP transport face. The long-term goal is for
`/api/v1/chat` to route through sCoRE's task pipeline (Episode 2+). Splitting into
a separate repo before that wiring exists adds cross-repo coordination overhead
with no benefit.

The sCoRE-as-daemon concept — running the coordinator as a standalone process
independent of Claude Code CLI — is Evolution 1 territory. When that happens, the
coordinator and server may naturally separate. Not now.

Railway deploys from `server/` as Root Directory. The harness controls that path.
The coordinator runs locally via tmux. They share one repo, two modes.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-04-29 | Initial architecture document — Phase A scaffold |
| v0.2 | 2026-05-07 | Server/coordinator split decision documented; versioning aligned to v0.0.0.0 |

---

```
transcribe ~ grimoire >> architecture mapped // %EPOCH_0_EPISODE_1%
```
