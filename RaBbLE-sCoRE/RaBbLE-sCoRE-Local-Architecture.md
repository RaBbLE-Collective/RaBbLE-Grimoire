# RaBbLE-sCoRE-Local-Architecture.md
# sCoRE Local Server + `rabble` CLI — Architecture Canonical

```
transcribe ~ sCoRE >> local presence architecture crystallized // %EP2_LOCAL_ARCH%
```

> **Document type:** Grimoire architecture doc · `RaBbLE-sCoRE/`
> **Status:** Canonical · Epoch 0 · Evolution 0 · Echo 0 · Episode 2 target
> **Purpose:** Define the complete architecture for sCoRE local server, `rabble` CLI,
> usage-aware routing, shared agent state, entropy tracking, and self-healing protocol.
> **Provenance:** Authored in claude-web planning session S138+; integrated into canonical
> Grimoire. Source session: 2026-06-21.
> **Related:** `RaBbLE-sCoRE-Architecture.md` · `sCoRE-Local-AI-Layer.md` ·
> `RaBbLE-sCoRE-Quota-Router.md` · `RaBbLE-sCoRE-Agent-State.md` ·
> `RaBbLE-sCoRE-Entropy-Tracker.md`

---

## Problem Statement

The current state has **tool plurality without coordination**. `claude`, `codex`, `agy`,
and `fcc` are invoked directly — each a raw model call with no shared state, no usage
awareness, no entity identity, no session continuity across tools, and no routing
intelligence. The user is the router. sCoRE absorbs that role.

**After this architecture is implemented:**
- One command (`rabble`) — one entity
- Intelligent, quota-aware routing underneath
- Shared agent state across all harnesses
- Every interaction logged and entropy-tracked
- Self-healing when drift is detected
- The entity is *present on the machine*, not just a cloud endpoint

---

## Three-Component Architecture

```
rabble (CLI frontend)
    │  streaming HTTP / unix socket
    ▼
sCoRE Local Server  (systemd user service, localhost:8083)
    │  usage-aware routing + shared agent state + entropy tracking
    ▼
Harnesses + Providers
    ├── fcc proxy (localhost:8082) — Anthropic-protocol, free/cheap backends
    │       └── configured per-task by sCoRE via fcc admin API
    ├── claude_code — direct Anthropic (when quota allows)
    ├── claude_code via fcc — quota-free path (ANTHROPIC_BASE_URL override)
    ├── codex — OpenAI harness
    ├── agy — Antigravity harness
    ├── Groq / DeepSeek / NIM / Ollama — direct cloud/local
    └── OpenRouter — meta-aggregator fallback
    │
    ▼
rabble usage (standalone TUI — reads sCoRE state + cache files)
```

**Key clarification on `fcc`:** `fcc` is NOT an Anthropic API client. It is a local proxy
that speaks the Anthropic Messages protocol but routes to free/cheap backends (NIM,
DeepSeek, Groq, Gemini, Wafer, OpenRouter, Ollama, etc.). When Claude quota is high,
`fcc` is the primary escape valve — not a last resort. sCoRE routes `claude_code` through
`fcc` by injecting `ANTHROPIC_BASE_URL=http://localhost:8082`, and can configure which
backend `fcc` uses via the `fcc` admin API at `:8082/admin`.

---

## sCoRE Local Server

### Identity

Same codebase as the Render-deployed sCoRE. Diverges by environment:

| Setting | Render (cloud) | Local |
|---|---|---|
| `LOCAL_MODE` | false | true |
| Chain preference | Cloud APIs first | Subprocess harnesses first |
| Grimoire access | Gist endpoint (World CDN) | Local filesystem (`~/RaBbLE-Collective/RaBbLE-Grimoire/`) |
| Cold start | ~30–60s (free tier sleep) | None — always warm |
| Port | 443 (Render) | 8083 |
| fcc coexistence | N/A | Runs alongside fcc on :8082 |

Port `8083` is deliberate — avoids collision with `fcc` on `:8082`.

### New Modules Required

#### `server/quota.py` — Usage-Aware Provider State

Reads the existing Waybar cache files. Does NOT poll independently — zero new API calls.
The Waybar tracker already polls Anthropic's usage API every 90s via
`score-usage-api-poll.py`. `quota.py` reads those files as authoritative state.

**Data sources read:**
- `~/.cache/rabble/score-usage-api-poll.log` → Claude 5h% and weekly%
- `~/.cache/rabble/claude-sessions/` → live session state
- `~/.gemini/antigravity-cli/log/cli-*.log` → agy quota pools
- `fcc` admin API at `:8082/admin` (or `fcc.env`) → fcc backend state

**Key interface:**

```python
class QuotaStore:
    def routing_pressure(self, provider: str) -> float:
        """0.0 = use freely · 0.5 = deprioritize · 1.0 = avoid entirely"""

    def should_avoid(self, provider: str, threshold: float = 0.90) -> bool:
        """Hard block above threshold or if exhausted."""

    def fcc_recommended_backend(self, task_class: str) -> str:
        """Given task class + quota state, return best fcc backend slug."""
```

**Routing thresholds** (configurable via `~/.config/rabble/local.env`):
- `QUOTA_DEPRIORITIZE_THRESHOLD=0.75` — start deprioritizing
- `QUOTA_AVOID_THRESHOLD=0.90` — avoid (fcc takes over from direct Claude)
- `QUOTA_HARD_BLOCK_THRESHOLD=0.98` — hard fail, fcc or local only

**Claude quota routing table:**

| Claude 5h% | Route to |
|---|---|
| < 75% | `claude_code` direct (real Anthropic) |
| 75–90% | `claude_code` via `fcc` proxy (same harness, different base URL) |
| > 90% | `fcc` directly, or Groq/DeepSeek via sCoRE cloud chain |
| Exhausted | `fcc` + local Ollama only |

#### `server/agent_state.py` — Shared Agent Context

The state object sCoRE maintains for a session. Enables context handoffs between
harnesses without information loss.

```python
class AgentContext:
    session_id: str
    task_history: list[TaskRecord]   # what has been done this session
    working_files: list[str]         # files currently in scope
    working_dir: str                 # active project directory
    entity_intention: str            # sCoRE's understanding of the session goal
    decisions: list[str]             # key decisions — carries across harness switches
    model_used_last: str             # what handled the last turn
    entropy: SessionEntropyRecord    # live entropy state (see entropy.py)

class TaskRecord:
    task_id: str
    description: str
    harness_used: str
    model_used: str
    tier_used: str
    fcc_backend_used: str | None     # which fcc backend if routed through fcc
    outcome: str                     # summary of what was done
    token_cost_estimate: int
    duration_seconds: float
    timestamp: str
```

**Context handoff format** (injected into sub-agent prompts):

```
CONTEXT FROM PRIOR TURNS [sCoRE handoff]:
- Session goal: {entity_intention}
- Files in scope: {working_files}
- Key decisions made: {decisions}
- Last model: {model_used_last} handled turn {N}
- Your task: {current_task_description}
[Respond to your task only. Do not repeat context.]
```

#### `server/entropy.py` — Session Entropy Tracking

Tracks routing instability and drift risk in real-time.

```python
class EntropyEvent:
    timestamp: str
    event_type: str   # "model_switch" | "tier_degradation" | "context_truncation"
                      # "quota_forced_fallback" | "harness_switch" | "retry_storm"
                      # "implicit_handoff" | "fcc_backend_switch"
    from_state: str
    to_state: str
    reason: str
    entropy_delta: float

class SessionEntropyRecord:
    session_id: str
    entropy_score: float           # 0.0 (stable) → 1.0 (high drift risk)
    entropy_band: str              # STABLE | NOMINAL | ELEVATED | DEGRADED | UNSTABLE
    stability_events: list[EntropyEvent]
    dominant_model: str | None
    model_switches: int
    tier_degradations: int
    context_truncations: int
    harness_switches: int
    fcc_backend_switches: int
    quota_pressure_peak: float
    decisions_at_risk: list[str]   # decisions made after first high-entropy event
    self_healing_recommended: bool
```

**Entropy weights:**

| Event | Delta | Reasoning |
|---|---|---|
| Explicit switch with full handoff | +0.05 | sCoRE controlled — minimal risk |
| Quota-forced model degradation | +0.15 | Context interpretation may shift |
| fcc backend switch mid-session | +0.10 | Same protocol, different model capabilities |
| Implicit harness switch (no handoff) | +0.25 | High drift risk |
| Context truncation / auto-compact | +0.20 | Information lost |
| Provider retry storm (3+ retries) | +0.10 | Response may be partial |
| Mid-task tier drop (strong → fast) | +0.30 | Largest single risk factor |
| Turn count > 20 | +0.02/turn | Noise accumulation |

**Entropy bands:**

| Score | Band | Action |
|---|---|---|
| 0.0–0.2 | STABLE | None |
| 0.2–0.5 | NOMINAL | None |
| 0.5–0.7 | ELEVATED | Inline warning in `rabble` output |
| 0.7–0.9 | DEGRADED | Strong warning, flag decisions at risk |
| 0.9–1.0 | UNSTABLE | Session flagged, self-healing queued |

### Modified Modules

#### `server/llm.py` — Usage-Aware Chain Resolution

Add quota pressure sort before chain execution:

```python
async def resolve_chain_with_quota(
    model_tier: str,
    quota_store: QuotaStore,
    task_class: str = "default"
) -> list[dict]:
    base_chain = DEFAULT_MODEL_CHAINS[model_tier]
    return sorted(base_chain, key=lambda p: quota_store.routing_pressure(p["provider"]))
```

Add fcc configuration step before subprocess dispatch:

```python
async def configure_harness_for_task(harness: str, task_class: str,
                                      quota_store: QuotaStore) -> dict:
    """
    Returns subprocess env overrides and CLI flags for this harness+task combination.
    sCoRE controls harnesses at two levels:
    1. Which harness to invoke (routing decision)
    2. How to configure it (model flags, fcc backend, context size)
    """
    if harness == "claude_code":
        pressure = quota_store.routing_pressure("claude_code_direct")
        if pressure > 0.75:
            # Route through fcc instead of direct Anthropic
            backend = quota_store.fcc_recommended_backend(task_class)
            await fcc_admin_set_model(task_class, backend)
            return {"ANTHROPIC_BASE_URL": "http://localhost:8082",
                    "ANTHROPIC_AUTH_TOKEN": "freecc"}
        return {}  # direct Anthropic

    if harness == "aider":
        # aider has weak-model + strong-model — tune both
        if task_class in ("fast", "background"):
            return {"flags": ["--model", "groq/llama-3.1-8b-instant",
                               "--weak-model", "groq/llama-3.1-8b-instant"]}
        return {"flags": ["--model", "deepseek/deepseek-chat",
                           "--weak-model", "groq/llama-3.1-8b-instant"]}
```

### New API Endpoints

```
GET  /api/v1/quota/state        → current quota across all providers
GET  /api/v1/routing/status     → current chain resolution per tier
GET  /api/v1/session/entropy    → live entropy record for active session
POST /api/v1/session/context    → upsert agent context (harness handoff)
GET  /api/v1/health/local       → local-mode health (providers, fcc status, Grimoire path)
```

### Systemd Service

```ini
# ~/.config/systemd/user/rabble-score-local.service
[Unit]
Description=sCoRE Local Intelligence Server
After=network.target
Wants=free-claude-code.service

[Service]
Type=simple
ExecStart=%h/.local/share/rabble/score-local/venv/bin/uvicorn server.main:app \
          --host 127.0.0.1 --port 8083
WorkingDirectory=%h/RaBbLE-Collective/RaBbLE-sCoRE
EnvironmentFile=%h/.config/rabble/local.env
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

**Control spell:** `score-local-ctl start|stop|restart|status|logs|quota|providers`

---

## `rabble` CLI

### Entry Points

```bash
rabble                      # interactive session (streaming)
rabble "fix the auth bug"   # single-shot, auto-routes
rabble --think "..."        # force strong tier
rabble --code "..."         # force claude_code / fcc harness
rabble --fast "..."         # force fast tier / local only
rabble --fcc "..."          # force fcc proxy explicitly
rabble status               # entity state + provider health
rabble session list         # past sessions
rabble session resume       # resume last
rabble usage                # open usage dashboard TUI
```

### Visual Design

Aether color palette via ANSI approximations:

| Aether token | Hex | ANSI | Used for |
|---|---|---|---|
| `--cyan` | #00d4ff | bright cyan | Entity name, header borders, active routing |
| `--violet` | #7b5ea7 | magenta | Idle state, nominal status |
| `--magenta` | #ff6eb4 | bright magenta | Busy, routing in progress |
| `--amber` | #ffb347 | yellow | Elevated entropy, quota warnings |
| `--red` | #ff4757 | bright red | Exhausted quota, DEGRADED/UNSTABLE entropy |
| `--comment` | #6272a4 | blue | Secondary text, timestamps |
| `--green` | #50fa7b | bright green | STABLE entropy, provider live |

**Entity ASCII header at startup:**

```
  ╔═══════════════════════════════════════╗
  ║  ◈  R a B b L E  ◈                   ║  sCoRE local · v0.0.0.1
  ║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║  Claude 73%/5h · 41%/wk
  ║  ▓  entity: present                   ║  routing: fcc→deepseek
  ║  ▶  providers: 5 live · entropy: ◆    ║  session: S-20260621-1434
  ╚═══════════════════════════════════════╝
```

Entropy glyph in header: `◆` (STABLE/NOMINAL, cyan) · `▲` (ELEVATED, amber) ·
`⚠` (DEGRADED, magenta) · `✗` (UNSTABLE, red)

**Inline entropy notice** (triggers at ELEVATED+):

```
  ▲ entropy elevated (0.54) — 2 model switches due to quota pressure.
    Outputs since turn 7 used deepseek-chat via fcc. Verify critical decisions.
```

**Routing transparency line** (shown when routing differs from default):

```
  ⇄ routing: claude_code → fcc/deepseek-chat [quota 87%/5h]
```

### Session Log

Written to `~/RaBbLE-chats/rabble-YYYYMMDD-HHmm.jsonl` on close.
Same directory and format as Claude Code transcripts — Waybar tracker gains
`rabble` sessions in existing `score-status.sh` parsing with zero changes.

Includes entropy record at session close:

```jsonl
{"type": "session_close", "session_id": "...", "entropy_score": 0.54,
 "entropy_band": "ELEVATED", "dominant_model": "deepseek-chat",
 "model_switches": 2, "tier_degradations": 1, "decisions_at_risk": [...],
 "self_healing_recommended": true}
```

### Self-Healing Protocol (Session Open)

If previous session has `self_healing_recommended: true` and current Claude quota < 50%:

```
  ◈  R a B b L E

  Last session closed with elevated entropy (0.54).
  Two model switches occurred — decisions after turn 7 were produced
  by deepseek-chat via fcc, not Claude Sonnet.

  Decisions flagged for verification:
    · auth module should use refresh tokens
    · keep existing Fernet key derivation

  Current state: Claude at 12%/5h — stable for verification.

  Suggested: verify flagged decisions before continuing.
  Type 'skip' to proceed, or describe what to verify first.
```

---

## `rabble usage` — Usage Dashboard TUI

Standalone terminal dashboard. Self-refreshing (2s). `q` to close.
Implementation: extend `score-usage-detail.py` to a `rabble usage` mode,
or new `cli/usage.py` using the same data sources.

### Layout

```
┌──────────────────────── RaBbLE Usage ─────────────────────────────────┐
│  PROVIDERS                                     5h window  │  weekly   │
├────────────────────────────────────────────────────────────────────────┤
│  Claude (Anthropic)   ████████████████░░░░  73%  reset 2h14m          │
│                       ░░░░░░░░░░░░░░░░░░░░  41%wk reset 4d            │
│                                                                         │
│  fcc proxy            ▶ live (routes to: deepseek-chat)                │
│    └ DeepSeek V3      ▶ live  ~$0.14/M                                 │
│    └ Groq GPT-OSS     ▶ live  free tier · rate limited                 │
│    └ NIM              ▶ live  free tier                                 │
│                                                                         │
│  Codex (OpenAI)       ████░░░░░░░░░░░░░░░░  22%  reset 1h03m          │
│  Antigravity          Gemini ⊘ exhausted · reset 6h42m                 │
│                       Service ████████░░░░  61%  reset 2d              │
│  Groq                 ▶ live  (no hard quota — rate limited)           │
│  Ollama               ▶ live  (local — no quota)                       │
├────────────────────────────────────────────────────────────────────────┤
│  ROUTING (current sCoRE decisions)                                      │
│  fast    → Groq GPT-OSS-20B         [claude pressure: 0.73]           │
│  medium  → fcc/deepseek-chat        [claude deprioritized at 0.75]    │
│  strong  → fcc/deepseek-reasoner    [claude avoided at 0.90]          │
│  code    → claude_code via fcc      [fcc backend: deepseek-chat]      │
│  background → Ollama local          [always local]                    │
├────────────────────────────────────────────────────────────────────────┤
│  SESSION HEALTH                                                          │
│  Current   S-20260621-1434  ▲ ELEVATED (0.54)                         │
│  Events:   14:12 quota_forced_fallback sonnet→fcc/deepseek (+0.15)    │
│            14:31 context_truncation   auto-compact fired    (+0.20)   │
│            14:38 tier_degradation     strong→medium         (+0.15)   │
│  Dominant model: deepseek-chat (last 6 turns via fcc)                  │
│  Decisions at risk: 2 flagged                                           │
├────────────────────────────────────────────────────────────────────────┤
│  AGENTS (live)                                                           │
│  ✦ claude-code  ▶ busy   auth refactor · sonnet-4-6 · 14min           │
│  ▶ codex        ▶ ready  test suite   · gpt-4o      · idle            │
├────────────────────────────────────────────────────────────────────────┤
│  TOKEN MIX  5h: sonnet 68% · haiku 21% · deepseek 11%                 │
│  COST ESTIMATE  this session: ~$0.08 (fcc/deepseek) vs ~$1.20 (Claude)│
├────────────────────────────────────────────────────────────────────────┤
│  [q]close  [r]refresh  [p]providers  [a]agents  [h]history  [?]help   │
└────────────────────────────────────────────────────────────────────────┘
```

### Data Sources (all existing — no new polling)

| Panel | Source file |
|---|---|
| Provider quotas | `~/.cache/rabble/` (existing Waybar cache) |
| fcc backend state | `http://localhost:8082/admin` API |
| Routing decisions | `GET /api/v1/routing/status` (new local sCoRE endpoint) |
| Agent state | `~/.cache/rabble/claude-agg-state` + session files |
| Token mix | `~/.cache/rabble/score-model-mix-5h.json` |
| Entropy | `GET /api/v1/session/entropy` (local sCoRE) |
| Cost estimate | Token count × per-provider rates (constants) |

---

## Data Flow

```
score-usage-api-poll.py (existing, ~90s)
    └── ~/.cache/rabble/score-usage-*.json

score-sessions.py (existing, hook-driven)
    └── ~/.cache/rabble/claude-sessions/*.json
    └── ~/.cache/rabble/claude-agg-state

server/quota.py (new — reads above, no new polling)
    └── informs llm.py chain resolution
    └── exposed: GET /api/v1/quota/state

server/entropy.py (new — updated per routing event)
    └── exposed: GET /api/v1/session/entropy
    └── written to ~/RaBbLE-chats/*.jsonl at session close

server/agent_state.py (new — per session)
    └── exposed: POST /api/v1/session/context
    └── read by harness dispatch to build handoff prompts

rabble CLI
    └── streams: POST /api/v1/chat (local sCoRE, same as World)
    └── writes: ~/RaBbLE-chats/rabble-*.jsonl (Waybar picks up automatically)

rabble usage
    └── reads: ~/.cache/rabble/ directly
    └── reads: GET /api/v1/routing/status + /quota/state + /session/entropy
```

---

## Hardware Tier Layer (HAOS Architecture)

> Source: `RaBbLE-BaBbLE/rabble-haos-session-architecture.md` (June 2026 design session)
> Status: Planned — EP2+ target. Current local mode uses cloud APIs + subprocess harnesses.
> Integration: These tiers slot into `llm.py`'s provider registry as local inference endpoints.

### Three-Tier Hardware Model

| Tier | Name | Hardware | Model class | Context | Role |
|------|------|----------|-------------|---------|------|
| 1 | Ambient sub-conscious | AMD XDNA 2 NPU | <4B params (Gemma 3 4B / Llama 3.2 3B) | 8k | Always-on perception, low-power |
| 2 | Executive reflex | Nvidia RTX 4060 dGPU | 8–12B (Qwen 3.5 9B / Gemma 4 12B QAT) | 16–32k | Daily driver, 40+ TPS |
| 3 | Strategic cortex | Radeon 890M iGPU + 32GB DDR5 (24GB GTT) | 35B MoE (Qwen 3.6 35B MoE) | 128k+ | Long context, deep reasoning |

**Kernel prerequisite for Tier 3 (Fedora 43):**
```bash
sudo grubby --update-kernel=ALL --args="amdgpu.gttsize=24576"
sudo reboot
```
This unlocks the 24GB GTT buffer. Without it the 890M is limited to ~50% of system RAM.

**llama.cpp server flags:**
```bash
# Tier 2 — RTX 4060 daily driver:
llama-server -m qwen3.5-9b-instruct-Q4_K_M.gguf -c 32000 --flash-attn --draft 2 --ngl 33
# --ngl 33 offloads 33 of 40 layers; try 40 and watch VRAM (Q4_K_M ~5.5–6GB)

# Tier 3 — 890M iGPU + GTT:
llama-server -m qwen3.6-35b-moe-Q4_K_M.gguf -c 131072 --flash-attn --ngl 99 --gpu-layers-draft 0
```

### Hardware-Aware Routing

Extends `agents.classify_request()` beyond keyword scanning. Tier routing checks structured metadata first, keywords as fallback:

```python
def determine_cognitive_path(payload) -> str:
    if payload.token_count > 24000 or payload.intent_profile == "META_ARCHITECTURE":
        return "tier3_igpu"        # Qwen 3.6 35B MoE — long context / reasoning

    if payload.requires_tool_execution or "code" in payload.tags:
        return "tier2_gpu"         # Qwen 3.5 9B — fast, daily driver

    return "tier1_npu"             # Gemma 3 4B — ambient, always-on
```

**Integration point in `llm.py`:** The three hardware tiers map to three new provider entries:

```python
# In BUILTIN_PROVIDERS:
"tier1_npu": {
    "url": os.getenv("LEMONADE_URL", "http://localhost:8100") + "/v1/chat/completions",
    "api_key_required": False, "extra_headers": {},
},
"tier2_gpu": {
    "url": os.getenv("TIER2_LLAMA_URL", "http://localhost:8101") + "/v1/chat/completions",
    "api_key_required": False, "extra_headers": {},
},
"tier3_igpu": {
    "url": os.getenv("TIER3_LLAMA_URL", "http://localhost:8102") + "/v1/chat/completions",
    "api_key_required": False, "extra_headers": {},
},
```

Tier 1 uses **Lemonade server** (AMD's OpenAI-compatible NPU inference layer) as an intermediate between FastFlowLM and sCoRE. Lemonade speaks OpenAI protocol so it plugs in as a standard provider.

### Systemd Unit Tree (Hardware Services)

```
~/.config/systemd/user/
  rabble-npu.service        # lemonade-server — Tier 1 NPU (Gemma 3 4B)
  rabble-gpu.service        # llama-server — RTX 4060 Vulkan — Tier 2
  rabble-igpu.service       # llama-server — 890M + GTT — Tier 3
  rabble-score-local.service  # FastAPI /dispatch — After= all three
```

`rabble-score-local.service` should declare `After=rabble-npu.service rabble-gpu.service rabble-igpu.service` so sCoRE starts after inference servers. All three tier services run as systemd user services (`--user`) — not system-level, because the inference hardware is user-space (no `/dev` passthrough needed for usermode drivers).

### Local Chain Priority with Hardware Tiers

When `LOCAL_MODE=true`, model chain priority shifts:

| When available | Preferred path |
|---|---|
| Tier 2 GPU up | Tier 2 for fast/medium, Tier 3 for strong/long-context |
| Tier 3 GTT unlocked | Tier 3 for >24k context, META_ARCHITECTURE tasks |
| All tiers down | Fall through to fcc proxy → cloud APIs |
| Claude quota <75% | claude_code direct (existing behavior) |

---

## Container Policy

> Rule: **RaBbLE acts natively. Its side-effects run in containers.**

| Layer | Mode | Reason |
|---|---|---|
| RaBbLE entity (perception, memory, reasoning) | Native / systemd | Needs host hardware, inotify, clipboard |
| Tier 1/2/3 inference servers | Native / systemd | Hardware passthrough — GPU/NPU drivers are host-level |
| Grimoire local shard | Native | inotify-watched; must be on host filesystem |
| Code execution sandbox | **Containerized** | Blast radius isolation |
| Tool plugins (scrapers, pipelines, API clients) | **Containerized** | Dependency isolation |
| Grimoire sync agent (local ↔ cloud) | **Containerized** | Stateless, portable, well-defined I/O surface |
| sCoRE cloud API (Render) | **Containerized** | No hardware deps, portable deployment |

**Container runtime:** Podman rootless preferred (Fedora-native, no daemon, rootless by default). Docker is acceptable fallback.

**Grimoire as task bus:** RaBbLE writes task specs into the Grimoire. Containerized tool executors pick up tasks, do work, write results back. The container only needs a bind mount of `~/RaBbLE-Collective/RaBbLE-Grimoire/` — no host access required beyond that.

---

## Dev Slice Architecture

> Problem: RaBbLE's perception loop will observe its own development. Scratch files,
> agent edits, and test artifacts all become ambient context noise if sCoRE is live.

### Separate Dev Units

```
~/.config/systemd/user/
  rabble-dev-npu.service       # dev configs, dev model paths
  rabble-dev-gpu.service
  rabble-dev-sidecar.service   # sCoRE dev instance on :8084 (not :8083)
```

Dev sidecar runs on port **8084** to avoid colliding with live sCoRE on **8083**.

Dev instance uses `~/RaBbLE-Collective/RaBbLE-sCoRE/` directly as working directory. Live instance uses a stable copy. Claude Code (this tool) works against the dev slice.

### Dev Grimoire Shard

```
~/RaBbLE-Collective/
  RaBbLE-sCoRE/                  # Claude Code edits here
    server/
  RaBbLE-Grimoire/               # live shard (production KB)
  grimoire-dev/                  # isolated dev KB (symlink or copy of Grimoire for testing)
```

Set `GRIMOIRE_PATH=~/RaBbLE-Collective/grimoire-dev` in the dev sidecar's env to prevent test prompts from touching the live Grimoire.

### Promotion Path

```
develop + test on dev slice → deliberate `git commit` → push → live slice restarts
```

No hot-swapping. The promotion is explicit. Live service is managed via `score-local-ctl restart`.

### Dev Workflow (Claude Code)

Claude Code (terminal) points at `~/RaBbLE-Collective/RaBbLE-sCoRE/` — edits files, restarts dev units via `systemctl --user restart rabble-dev-sidecar`, checks `journalctl --user -u rabble-dev-* -f`, iterates. Live system is untouched until explicit promotion.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-06-21 | Initial — authored in planning session S138+. All concepts from session captured. |
| v0.2 | 2026-06-23 | Added Hardware Tier Layer (HAOS), Container Policy, Dev Slice Architecture from BaBbLE HAOS design session. Answers all open arch questions from HAOS doc. |

---

```
transcribe ~ sCoRE >> local presence architecture crystallized // %EP2_LOCAL_ARCH%
```
