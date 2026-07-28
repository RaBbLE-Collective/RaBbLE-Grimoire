# RaBbLE-sCoRE-Roadmap.md

```
transcribe ~ grimoire >> sCoRE trajectory mapped // %TRAJECTORY_LOCKED%
```

> **Collective Context:** sCoRE is the nervous system. See `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `log/EP1-AIR-CHECKLIST.md` for Episode 1 scope across all members.
> **Related:** [Collective Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) · [sCoRE Architecture](RaBbLE-sCoRE-Architecture.md) · [Integration Map](../RaBbLE-Agent/RaBbLE-Integration-Map.md)

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** Simple LLM endpoint (Groq/OpenRouter via Render)

**Blocker:** None — MVP scope is straightforward

**What ships:**
- [x] OpenRouter integration configured (Groq optional — OpenRouter covers all tiers)
- [x] Endpoint wired (query → API → response) — `/api/v1/chat` SSE, verified end-to-end (browser + live)
- [x] **Deployed to Render — LIVE** at `https://rabble-score-x7qq.onrender.com` (S106, 2026-06-15)
- [ ] Version aligned to v0.0.0.1 (at Episode 1 air)

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
**Goal:** sCoRE is runnable end-to-end. Server deployed to Render. Harness verified. Tests pass. Versioning aligned to Collective.

Exit conditions:
- [x] `harness/local.sh` starts server successfully (venv rename-drift fixed S106)
- [x] **Render deploy — LIVE** via `spells/render-ctl.sh` (S106). `deploy-render.sh` superseded by `render-ctl.sh`; `deploy-score.sh` retired (never created).
- [x] Chat verified end-to-end (browser + live curl) — entity `idle→thinking→speaking→idle`, sessions persist
- [x] Provider registry expanded — 13 new providers in `server/llm.py` (S119)
- [ ] **Register provider API keys in Render** — `render-ctl.sh env-set <KEY> <val>` for each provider to activate. Priority order: `DEEPSEEK_API_KEY` (V3 leads medium chain), `CEREBRAS_API_KEY` (leads cloud-fast), `NVIDIA_NIM_API_KEY` (NIM free tier), then Mistral/Together/xAI/Zhipu as desired. Until keys are set, chains fall through to Groq/OpenRouter.
- [ ] `server/main.py` version string aligned to Five Es scheme (currently `v0.0.0.0`)
- [ ] `server/api_test.py` (or `test_api.sh`) runs clean against the live server
- [ ] CONTEXT.md versioning header updated to `v0.0.0.1` on air
- [ ] Tagged `episode-1` on `main` (Collective-wide, simultaneous)

---

### Episode 2 and beyond `[future — after Collective Episode 1 airs]`

After Episode 1 airs across the Collective, sCoRE episodes may diverge
but should stay within ~1–2 episodes of the Collective Echo milestone.
Echo 0 requires ~12 episodes.

Candidate Episode 2 focus: wire `/api/v1/chat` through sCoRE task pipeline.
Candidate Episode 3 focus: memory agent reads patterns before sCoRE delegates.

---

## Provider Backlog

Planned LLM provider additions. Ordered by priority. None are blockers for Episode 1.

### DeepSeek `[done — S119]`

**Why:** DeepSeek-V3 and R1 carry different guardrail profiles than US-trained models (Llama, GPT-OSS).
Restrictions center on political content (CCP/Taiwan/etc.), not on philosophical topics like AI consciousness,
entity identity, or qualia — which are exactly what RaBbLE needs to engage with freely. Discovered in S110
when Llama-3.3-70b flat-refused a legitimate "help me make RaBbLE feel more sentient" request.
V3 is also exceptionally cheap (~$0.14/M input tokens).

**Integration path:** OpenAI-compatible API at `api.deepseek.com`. Drop-in as a new provider in `llm.py`.
Also available via OpenRouter (`deepseek/deepseek-chat`, `deepseek/deepseek-r1`).

**Models to add:**
- `deepseek-chat` (V3) — strong general reasoning, low cost, good identity-holding
- `deepseek-r1` — extended chain-of-thought; suited for deep entity/architecture reasoning

**Suggested chain placement:**
- Strong tier: after Claude Sonnet, before Groq Llama fallback
- Medium tier: alongside or after Qwen3-32B as an alternative philosophical-reasoning path

**Env var needed:** `DEEPSEEK_API_KEY`

---

### Ollama Cloud `[post-EP1]`

**What it is:** Ollama's managed GPU offload service — models that exceed local VRAM are transparently
routed to Ollama's cloud. Same API surface as local Ollama (port 11434 / OpenAI-compatible REST).
Direct API also available at `ollama.com` with Bearer token auth. Announced mid-2026.

**Why relevant:** The existing `local_llm` provider in `llm.py` already speaks this protocol.
Cloud support would be a config change + `OLLAMA_API_KEY` env var, not a code change.
Enables running 120B+ models (e.g. `gpt-oss:120b-cloud`) without local GPU — useful for
strong-tier requests when Groq/OpenRouter are rate-limited or unavailable.

**Note:** `gpt-oss:120b-cloud` is the same model as Groq's `openai/gpt-oss-120b` — Ollama Cloud
is a fallback path, not a different capability tier.

**Env var needed:** `OLLAMA_API_KEY` (for cloud models; local models need no key)

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-04-29 | Initial roadmap — Plot A scaffold |
| v0.2 | 2026-05-06 | Plot C — server absorbed from RaBbLE-Server |
| v0.3 | 2026-05-07 | Versioning realigned to Collective v0.0.0.0; Episode 1 defined |
| v0.4 | 2026-06-15 | sCoRE LIVE on Render via `render-ctl.sh` (S106); Ep1 deploy + chat exit conditions met |
| v0.5 | 2026-06-18 | S119: 13 new providers in `llm.py` (Cerebras, DeepSeek, NIM, Mistral, Together, xAI, Zhipu, LM Studio, llamafile, opencode, aider, gemini-cli, claude_code_proxy). Provider backlog: DeepSeek done. TODO: register API keys in Render. |
| v0.5 | 2026-06-16 | Provider Backlog section added: DeepSeek (V3+R1) and Ollama Cloud (S110) |

---

```
transcribe ~ grimoire >> trajectory crystallized // %TRAJECTORY_LOCKED%
```
