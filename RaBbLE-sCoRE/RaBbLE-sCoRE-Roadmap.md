# RaBbLE-sCoRE-Roadmap.md

```
transcribe ~ grimoire >> sCoRE trajectory mapped // %TRAJECTORY_LOCKED%
```

> **Collective Context:** sCoRE is the nervous system. See `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `RaBbLE-Episode-1-Release-Map.md` for Episode 1 scope across all members.

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** Simple LLM endpoint (Groq/OpenRouter via Railway/Render)

**Blocker:** None — MVP scope is straightforward

**What ships:**
- [ ] Groq/OpenRouter integration configured
- [ ] Endpoint wired (receive query → call API → return response)
- [ ] Deployed to Railway or Render
- [ ] Version aligned to v0.0.0.1

**Deferred to Episode 2+:**
- Multi-agent coordination
- Task pipeline (server → dispatch → agents)
- Behavioral routing
- Memory member integration

**Dependencies:**
- None — sCoRE can deploy independently
- World will call this endpoint for chat interface

---

## Versioning Model

`Event → Episode → Echo → Evolution → Epoch`

- **Event** — a commit
- **Episode** — everyday development, a collection of events
- **Echo** — stable release state
- **Evolution** — significant architectural change
- **Epoch** — broadest era

---

## Epoch Map

```
Epoch 0: FOUNDATION     [ACTIVE]  — Scaffold, identity, dispatch loop wired
Epoch 1: FIRST LOOP     [FUTURE]  — sCoRE ↔ agent round-trip working end-to-end
Epoch 2: LEARNING       [FUTURE]  — Memory patterns inform delegation decisions
```

---

## Current Epoch — Epoch 0: Foundation

**Intent:** Get the substrate in place. Scaffold committed. Dispatch wired.
sCoRE can receive intent and write valid task files. One agent (execution) can receive
a task and return a result. The loop is manually verified.

**Exit Condition:**
- Repo initialized, scaffold committed to `main`
- `.claude/settings.json` constraints verified (Bash blocked in sCoRE session)
- `dispatch-watch.sh` wiring tested with a synthetic task file
- At least one real round-trip: sCoRE → task file → execution agent → result

---

## Episode Tracker

**Collective position:** `v0.0.0.0` — Episode 1 not yet aired.
Events below are pre-Episode-1 work accumulating toward first air.

---

### Pre-Episode-1 Events

#### Episode 1, Plot A — First Breath `[events complete]`

Events:
- [x] Repo initialized with scaffold
- [x] `.claude/settings.json` constraints in place (Bash/Web blocked at tool level)
- [x] `dispatch-watch.sh` round-trip verified — TASK-0001-search full lifecycle
- [x] Learned: dispatch must use `claude -p < prompt_file`, not interactive + send-keys
- [x] `start-rabble.sh` verified — dispatch + sCoRE session both launch correctly
- [x] CONTEXT.md handoff layer added to all work areas

#### Episode 1, Plot B — sCoRE Live Session `[events complete]`

Events:
- [x] `CLAUDE.md` — sCoRE identity injected via `@agents/score.md`
- [x] `.claude/settings.json` — `Agent(*)` added to deny list; sCoRE cannot spawn subagents
- [x] Dispatch fixed — agent sessions run from `mktemp -d`, bypassing project settings.json
- [x] Dispatch — startup queue drain added; pre-existing pending tasks processed on restart
- [x] `scripts/rabble-shell.sh` — RaBbLE interactive shell; loading phase, spinners, dispatch notifications
- [x] `scripts/status.sh` — system health check
- [x] Learned: project settings.json applies to ALL sessions from REPO_ROOT, not just sCoRE
- [x] Learned: Agent tool spawns subagents that inherit CLAUDE.md — must be blocked for sCoRE
- [x] Learned: shell entity is RaBbLE (not sCoRE); sCoRE is the internal engine
- [x] Learned: pre-warming during load phase absorbs cold start, first user turn is fast
- [x] `memory/patterns/agent-isolation.md` — isolation lesson documented

#### Episode 1, Plot C — Server Absorbed `[events complete]`

Events:
- [x] `server/` — FastAPI intelligence service moved from RaBbLE-Server
- [x] `harness/` — Railway deployment tooling moved from RaBbLE-Server
- [x] `scripts/start-rabble.sh --with-server` — optional server startup flag
- [x] `scripts/status.sh` — server health check block added
- [x] `scripts/stop-rabble.sh` — `rabble-server` session added to teardown list
- [x] `RaBbLE-Server` repo deprecated — points to sCoRE

---

### Episode 1 — First Air `[pending]`

**Version at air:** `v0.0.0.1`
**Goal:** sCoRE is runnable end-to-end. Server deploys to Railway. Harness verified. Tests pass. Versioning aligned to Collective.

Exit conditions:
- [ ] `harness/` path bug fixed — all scripts reference `server/` not `services/intelligence/`
- [ ] `server/main.py` version string aligned to Five Es scheme
- [ ] `server/api_test.py` (or `test_api.sh`) runs clean against local server
- [ ] `harness/local.sh` starts server successfully
- [ ] Railway deploy attempted — `harness/deploy.sh` or `harness/railway_ctl.sh` verified
- [ ] `RaBbLE-Grimoire/spells/deploy-score.sh` spell in place
- [ ] CONTEXT.md versioning header updated to `v0.0.0.1` on air
- [ ] Tagged `episode-1` on `main`

---

### Episode 2 and beyond `[future — after Collective Episode 1 airs]`

After Episode 1 airs across the Collective, sCoRE episodes may diverge
but should stay within ~1–2 episodes of the Collective Echo milestone.
Echo 0 requires ~12 episodes.

Candidate Episode 2 focus: wire `/api/v1/chat` through sCoRE task pipeline.
Candidate Episode 3 focus: memory agent reads patterns before sCoRE delegates.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-04-29 | Initial roadmap — Plot A scaffold |
| v0.2 | 2026-05-06 | Plot C — server absorbed from RaBbLE-Server |
| v0.3 | 2026-05-07 | Versioning realigned to Collective v0.0.0.0; Episode 1 defined |

---

```
transcribe ~ grimoire >> trajectory crystallized // %TRAJECTORY_LOCKED%
```
