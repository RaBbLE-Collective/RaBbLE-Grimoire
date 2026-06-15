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
│  No Bash/Web     │   │  Local or Render-deployed         │
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

Deployment: `harness/local.sh` (local) · `spells/render-ctl.sh` (Render — see Deployment section below)

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

Render deploys from `server/` as Root Directory. The coordinator runs locally via tmux.
They share one repo, two modes.

---

## Deployment (Live — Render)

sCoRE's web API is **live on Render** (free tier) as of S106 (2026-06-15).

| Field | Value |
|---|---|
| Service | `RaBbLE-sCoRE` (`srv-d8kdmam47okc739pqu90`) |
| URL | `https://rabble-score-x7qq.onrender.com` |
| Tracks branch | `new-horizons` (pre-episode convergence → `main` at Ep1 air) |
| Root dir / runtime | `server/` · Python 3.12 · autoDeploy on push |
| Plan | free — **no persistent disk**, ephemeral storage only |

**Managed entirely via `spells/render-ctl.sh`** (Render REST API — no dashboard):
`render-ctl.sh env-sync` (push provider keys from `server/.env`) · `deploy --wait` · `status` · `logs` · `env-set <k> <v>`. The only one-time manual step was minting the API key (stored in gitignored `RaBbLE-Grimoire/.render/`).

> The service is a plain **Web Service**, not a Blueprint — so `render.yaml` is **reference-only** (it's not synced). Env vars are set via the API (`render-ctl.sh` / bulk PUT), not from `render.yaml`.

**Environment:**

| Var | Value | Why |
|---|---|---|
| `DEMO_MODE` | `true` | anonymous guest access — gates **auth**, not the LLM |
| `OPENROUTER_API_KEY` | (secret) | live LLM provider; covers all tiers |
| `JWT_SECRET` | (generated) | token signing |
| `FRONTEND_URL` | `https://joinrabble.world` | CORS allow-origin (defaults to `*` if unset) |
| `DATA_DIR` | `/tmp/rabble-data` | ephemeral (free tier has no disk); server `mkdir`s it |
| `LLM_FAST_CHAIN` | `openrouter:google/gemma-4-26b-a4b-it:free` | skip claude_code/local_llm in cloud |
| `PYTHON_VERSION` | `3.12` | runtime |

**LLM tiers — OpenRouter alone is sufficient:** `fast`/`medium` → OpenRouter free Gemma; `strong` → Claude Sonnet (needs OpenRouter credits). Groq is optional, **not** an RC1 blocker.

**Free-tier caveats:** sleeps after ~15 min idle → ~30–60s cold start (then ~7s warm); `:free` models rate-limit under load; data resets on restart (client state lives in the browser via World's `localStorage`).

**World binding:** `RaBbLE-World/world/js/RaBbLE-config.js` (the flip point) auto-points production origins at this URL; a `localhost` origin uses local sCoRE (`harness/local.sh`).

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-04-29 | Initial architecture document — Phase A scaffold |
| v0.2 | 2026-05-07 | Server/coordinator split decision documented; versioning aligned to v0.0.0.0 |
| v0.3 | 2026-06-15 | Deployment (Live — Render) section added; sCoRE live on Render via `render-ctl.sh` (S106) |

---

## Lessons & Gotchas

- **The system-prompt persona is deliberately separated from project onboarding** —
  it lives in `system-prompt-sCoRE.md`, not AGENT.md, so that normal-work agents (doing
  ordinary engineering tasks in this repo) don't get confused by entity-persona
  constraints. AGENT.md follows the standard member-doc shape like every other repo.
- **sCoRE began life as a separate repo, `RaBbLE-Server`** (genesis-era memory,
  2026-04-26) — a working FastAPI/Railway backend with Groq-primary/OpenRouter-fallback
  LLM chains, JWT+API-key auth, and 6 workflow types (brainstorm/reflect/create/solve/
  learn/thrive), serving a separate frontend called **`RaBbLE-JS`**
  (`markm1206/RaBbLE-JS`) that bundled the early NeBuLA renderer and a "BaBbLE command
  shell." That lineage is `RaBbLE-JS` → `RaBbLE-Chat` → merged into `RaBbLE-World`.
  sCoRE absorbed `RaBbLE-Server` as an "Episode 3" subcomponent on 2026-05-06.
- **sCoRE is LIVE on Render** (pivoted from Railway at S58; deployed S106) — managed via
  `spells/render-ctl.sh` (Render REST API). See the **Deployment (Live — Render)** section
  above for the service, env model, and runbook. The `RaBbLE-Server` origin above was
  Railway-deployed; that lineage is historical only.
- **The live service is a plain Web Service, not a Blueprint** — so `render.yaml` is not
  synced (reference-only). It was created with zero env vars and `disk: null`; all env was
  set via the API. Lesson: free tier rejects persistent disks — `render.yaml` had a
  `plan: free` + `disk:` conflict (`render-ctl.sh preflight` catches it).
- **`server/.venv` carried a pre-rename shebang** (`~/RaBbLE/RaBbLE-Server/...`) → `pip`
  exit 126; rebuild the venv to fix (same rename-drift class as the S105 audit).
- The DataCrawler RFC (Scavenger/Organizer/Librarian bot architecture), originally
  ideated in BaBbLE, is preserved here as a future sCoRE RFC — see
  `RaBbLE-sCoRE-DataCrawler-RFC.md`.

---

```
transcribe ~ grimoire >> architecture mapped // %EPOCH_0_EPISODE_1%
```
