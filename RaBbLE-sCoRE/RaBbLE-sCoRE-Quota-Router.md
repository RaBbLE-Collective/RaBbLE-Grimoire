# RaBbLE-sCoRE-Quota-Router.md
# sCoRE Quota-Aware Routing — Canonical Architecture

```
transcribe ~ sCoRE >> quota-aware routing architecture crystallized // %QUOTA_ROUTER%
```

> **Document type:** Grimoire architecture doc · `RaBbLE-sCoRE/`
> **Status:** Canonical · Episode 2 target
> **Implementation:** `server/quota.py` · modified `server/llm.py`
> **Related:** `RaBbLE-sCoRE-Local-Architecture.md` · `sCoRE-Local-AI-Layer.md`

---

## Canonical Definition

**Usage-aware routing** is the principle that sCoRE treats provider quota as a
first-class routing signal. Before dispatching any request, sCoRE reads current
quota state and adjusts provider priority accordingly. High-pressure providers
are deprioritized; exhausted providers are avoided. This happens automatically —
the user never changes configuration.

---

## The `fcc` Correction (Critical)

`fcc` (free-claude-code) is NOT an Anthropic API client. It is a local proxy that
speaks the Anthropic Messages protocol but routes to free/cheap backends:
NVIDIA NIM, DeepSeek, Groq, Gemini, Wafer, OpenRouter, Ollama, LM Studio, etc.

**Consequence:** `fcc` has no Anthropic quota. It is the primary escape valve
when Claude quota is high — not a last resort.

```
claude_code → ANTHROPIC_BASE_URL=https://api.anthropic.com  # burns Claude quota
claude_code → ANTHROPIC_BASE_URL=http://localhost:8082 (fcc) # zero Claude quota
```

sCoRE routes `claude_code` through `fcc` by injecting the `ANTHROPIC_BASE_URL`
env override before spawning the subprocess. The `claude_code_proxy` provider
in `llm.py` already implements this — quota routing makes it automatic.

---

## Data Sources

`quota.py` reads the existing Waybar tracker cache files. It does NOT poll
independently. Zero new API calls. Zero new daemons.

| Provider | Source file | Data |
|---|---|---|
| Claude | `~/.cache/rabble/score-usage-api-poll.log` | 5h%, weekly%, reset times |
| Claude (live session) | `~/.cache/rabble/claude-sessions/*.json` | active session state |
| Codex | Codex session transcripts | `token_count.rate_limits` |
| agy | `~/.gemini/antigravity-cli/log/cli-*.log` | RESOURCE_EXHAUSTED events |
| fcc | `http://localhost:8082/admin` API | backend state, current model routing |
| Groq/DeepSeek/NIM | No quota files — rate-limited only, no hard quota | N/A |

The Waybar tracker and sCoRE local share a single authoritative quota state.
If the Waybar tracker is not running (Waybar not active), `quota.py` returns
`None` for unknown fields and routes conservatively.

---

## Routing Pressure Model

`routing_pressure(provider)` returns a float 0.0–1.0:

```
0.0 = use freely (below DEPRIORITIZE_THRESHOLD)
0.5 = deprioritize (above DEPRIORITIZE_THRESHOLD)
0.8 = strongly avoid (above AVOID_THRESHOLD)
1.0 = hard block (above HARD_BLOCK_THRESHOLD or exhausted)
```

Pressure is the **maximum** of 5h pressure and weekly pressure:

```python
def routing_pressure(provider: str) -> float:
    quota = self.get_quota(provider)
    if quota is None:
        return 0.0  # unknown = assume fine
    if quota.exhausted:
        return 1.0
    p5h = _pressure(quota.pct_5h, T_DEPRIO, T_AVOID, T_HARD)
    pwk = _pressure(quota.pct_weekly, T_DEPRIO, T_AVOID, T_HARD)
    return max(p5h, pwk)
```

**Default thresholds:**

| Threshold | Default | Env var |
|---|---|---|
| Deprioritize above | 75% | `QUOTA_DEPRIORITIZE_THRESHOLD` |
| Avoid above | 90% | `QUOTA_AVOID_THRESHOLD` |
| Hard block above | 98% | `QUOTA_HARD_BLOCK_THRESHOLD` |

---

## Claude Quota Routing Table

| Claude 5h% | Action |
|---|---|
| < 75% | `claude_code` direct (real Anthropic) — preferred |
| 75–90% | `claude_code` via `fcc` proxy — same UX, no quota burn |
| > 90% | `fcc` directly, or Groq/DeepSeek via sCoRE cloud chain |
| Exhausted | `fcc` + local Ollama only |

---

## fcc Backend Selection

When routing through `fcc`, sCoRE selects the backend based on task class and
quota state. sCoRE configures `fcc` via the admin API at `:8082/admin` before
dispatching the subprocess.

**Backend selection by task class:**

| Task class | Preferred fcc backend | Fallback |
|---|---|---|
| `code` | `deepseek/deepseek-chat` (strong coding) | `nvidia_nim/kimi-k2.5` |
| `strong` | `deepseek/deepseek-reasoner` | `openrouter/claude-sonnet-4-6` |
| `medium` | `deepseek/deepseek-chat` | `groq/qwen3-32b` |
| `fast` | `groq/openai/gpt-oss-20b` | `cerebras/llama-3.3-70b` |
| `background` | `groq/llama-3.1-8b-instant` | `ollama/local-model` |

sCoRE can tune fcc at two levels:
- **Tier level**: set `MODEL_SONNET`, `MODEL_HAIKU`, `MODEL_OPUS` in fcc admin
- **Task level**: select which Claude tier maps to which backend per task class

---

## Chain Resolution Under Pressure

The existing `DEFAULT_MODEL_CHAINS` in `llm.py` is reordered by quota pressure
before execution. High-pressure providers sink toward the end:

```python
sorted_chain = sorted(
    base_chain,
    key=lambda entry: quota_store.routing_pressure(entry["provider"])
)
```

This is a stable sort — within equal pressure bands, original priority order is
preserved. High-pressure providers remain as last-resort fallbacks; they are
never removed from the chain.

---

## Entropy Signal

Every quota-forced routing change is recorded as an `EntropyEvent` in
`server/entropy.py`. This creates an audit trail: not just what model was used,
but why the routing shifted and what the quota state was at that moment.

**Events emitted by quota routing:**

| Situation | Entropy event | Delta |
|---|---|---|
| Direct → fcc switch (75–90%) | `quota_forced_fallback` | +0.15 |
| fcc backend switch mid-session | `fcc_backend_switch` | +0.10 |
| Tier degradation (strong→medium) | `tier_degradation` | +0.15 |
| Tier degradation (medium→fast) | `tier_degradation` | +0.30 |
| Hard block (provider exhausted) | `quota_forced_fallback` | +0.20 |

---

## Design Decisions

**Read-only integration with existing tracker**
`quota.py` reads files written by the Waybar tracker. It does not poll Anthropic's
API independently, create new daemons, or duplicate polling logic. The Waybar tracker
is the authoritative quota source; sCoRE is a consumer.

**fcc as the primary quota escape valve**
`fcc` is positioned in the routing table as the first Claude-pressure escape, not the
last. This reflects `fcc`'s actual nature: same protocol, zero Anthropic quota, capable
of routing to frontier-quality models (DeepSeek V3, Kimi K2.5, Nemotron).

**Pressure, not binary cutoff**
Routing uses a continuous pressure score, not a binary "use / don't use". This allows
gradual deprioritization starting at 75% rather than a sudden switch at 90%, which
would introduce a large entropy event at an arbitrary threshold.

**Conservative on unknown state**
If quota files are missing or stale (> 5 minutes old), `routing_pressure` returns 0.0
(assume fine). The alternative — refusing to route — is worse. Stale data means the
tracker may not be running; conservative routing keeps the session alive.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-06-21 | Initial — from planning session S138+ |

---

```
transcribe ~ sCoRE >> quota-aware routing architecture crystallized // %QUOTA_ROUTER%
```
