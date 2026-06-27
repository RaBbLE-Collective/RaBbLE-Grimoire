# RaBbLE-sCoRE Token Tracking Architecture

**Date:** 2026-06-26  
**Author:** Claude Code  
**Status:** Architecture (current state) + Roadmap (improvements)

> sCoRE is RaBbLE's coordination engine. It handles chat, workflow execution, and session persistence. This document maps where token usage is observed and where it's hidden, then outlines how to surface costs for billing and optimization.

---

## Current State: What's Tracked

### Layer 1: Session Persistence (transcripts.py)

**Purpose:** Save conversation history for recovery and audit.

**Location:** `RaBbLE-sCoRE/server/transcripts.py`

**What it captures:**
```python
{
    "ts": "2026-06-26T14:32:51Z",
    "session_id": "abc123...",
    "tier": "fast",
    "workflow_type": "chat",
    "message_count": 47,
    "messages": [...]  # Full conversation history
}
```

**What it DOESN'T capture:**
- Token counts (input/output/cache_read/cache_write)
- Per-message token costs
- Model used (stored only in sCoRE's ephemeral state)
- Actual max_tokens returned vs declared

**Problem:** No way to answer:
- "How much did this session cost in tokens?"
- "Which workflow type (brainstorm/reflect/create) is most expensive?"
- "What's the token distribution across sessions this week?"

---

### Layer 2: Action Audit Logging (audit.py)

**Purpose:** Track what actions the entity took (for observability and debugging).

**Location:** `RaBbLE-sCoRE/server/audit.py`

**What it captures:**
```python
{
    "ts": "...",
    "session_id": "...",
    "action": "chat_message",         # chat | workflow_create | inference_result
    "tier": "fast",
    "input_type": "user_text",
    "status": "success"
}
```

**Token tracking in audit:**
- ❌ No input/output token counts
- ❌ No model identifier
- ❌ No cache hit data
- ❌ No duration / latency

**Problem:** Audit trail is action-shaped, not cost-shaped. Can't budget per action.

---

### Layer 3: Real-Time API Usage Polling (score-usage-log.sh)

**Purpose:** Monitor quota consumption against OpenRouter API limits.

**Location:** `RaBbLE-OS/config/waybar/scripts/score-usage-log.sh` (cronjob ~5-min interval)

**What it captures:**
```json
{
    "timestamp": "2026-06-26T14:32:00Z",
    "model": "claude-sonnet-4-6",
    "usage_percent": {
        "5h": 34.5,
        "weekly": 23.8
    },
    "tokens_in_period": {
        "input": 4234123,
        "output": 23412341,
        "cache_read": 123412123,
        "cache_write": 5123123
    }
}
```

**Store:** `~/.cache/rabble/llm-usage-log.jsonl` (rolling log, ~500 entries ≈ 4-5 days at 5-min polling)

**Note:** This is **aggregate API telemetry**, not per-session. Doesn't know which sCoRE session caused the token burn.

---

### Layer 4: Empirical Token→Quota Fitting (score-usage-fit.py)

**Purpose:** Correlate token counts to observed quota consumption (for accuracy/calibration).

**Location:** `RaBbLE-OS/config/waybar/scripts/score-usage-fit.py`

**What it does:**
1. Load `llm-usage-log.jsonl` (aggregate API polling data)
2. For each time window (5h rolling, weekly rolling)
3. Fit a regression: `tokens_spent → quota_percent_change`
4. Per-model coefficients reveal cache-hit benefits + actual burn

**Example output (internal, not exported):**
```python
{
    "model": "claude-sonnet-4-6",
    "window": "5h",
    "coefficients": {
        "input": 0.0000047,      # 1M tokens → 4.7% quota
        "output": 0.000024,      # 1M tokens → 2.4% quota (5x input)
        "cache_read": 0.00000047,
        "cache_write": 0.0000059
    },
    "r_squared": 0.89  # Fit quality
}
```

**Data goldmine:** This is the **most accurate** token→cost mapping in the system. But it's:
- Isolated in score-usage-fit.py
- Not exported to public ledger
- Not used by session-tokens.sh or token-ledger.tsv
- Only visible when score-usage-fit.py is run manually

---

## Missing Links: Where Token Costs Hide

### Problem 1: transcripts.py Doesn't Extract Token Usage

**Current flow:**
```
sCoRE API call
  → LLM response (includes usage object)
  → Save to R2/file via transcripts.py
  ✗ Usage object is DROPPED
  → Only messages are persisted
```

**Why it matters:**
- Can't reconstruct cost of saved sessions
- Audit.py logs action types but not their token cost
- No way to bill features or workflow types post-EP1

**Fix:** Extend transcripts.py to capture and persist token usage.

---

### Problem 2: LLM Configuration Has No Token Tracking

**Location:** `RaBbLE-sCoRE/server/llm.py`

**Current state:**
```python
response = client.messages.create(
    model=model,
    max_tokens=1024,  # ← Hardcoded output ceiling
    messages=...,
    # ...
)
# response.usage contains: input_tokens, output_tokens, cache_read_input_tokens, cache_creation_input_tokens
# But usage is NOT extracted or logged.
```

**Problem:**
- No record of actual tokens used
- max_tokens=1024 is a blind guess (may be underutilizing context or capping valuable output)
- No per-call cost tracking

---

### Problem 3: Session Metadata Missing Model Info

**What gets saved:**
- Session ID, timestamp, message count, workflow type, tier
- **NOT:** Which model? What max_tokens was set? Did we hit the ceiling?

**Why it matters:**
- Can't distinguish Haiku (cheap) from Opus (expensive) cost
- Can't debug "why did this session cost 20M tokens?" without model info

---

### Problem 4: No Per-Action Cost Attribution

**Current audit table structure:**
```
ts | session_id | action | status | ...
├─ 14:32:01 | abc123 | chat_message | success
├─ 14:32:02 | abc123 | inference_result | success
└─ 14:32:03 | abc123 | chat_message | success
```

**Missing:**
- Token cost per action
- Model used per action
- Latency per action
- Cache-hit ratio per action

**Result:** Can't answer "which actions are expensive?" or "brainstorm workflows cost 2x create workflows?"

---

## Roadmap: How to Fix It

### Short-term (This Session)

**Action 1: Extend transcripts.py to capture token usage**

```python
def save_transcript(
    session_id: str,
    messages: list,
    tier: str,
    workflow_type: str,
    model: str,
    token_usage: TokenUsage,  # NEW: input, output, cache_read, cache_write
    max_tokens_set: int       # NEW: what was the ceiling?
):
    record = {
        "ts": iso_now(),
        "session_id": session_id,
        "tier": tier,
        "workflow_type": workflow_type,
        "model": model,
        "message_count": len(messages),
        "max_tokens": max_tokens_set,
        "tokens": {
            "input": token_usage.input_tokens,
            "output": token_usage.output_tokens,
            "cache_read": token_usage.cache_read_input_tokens,
            "cache_write": token_usage.cache_creation_input_tokens
        },
        "messages": messages
    }
    save_to_r2(record)
```

**Effort:** 1.5 hours (propagate token_usage through API endpoints → llm.py → transcripts.py)

**Gain:** Retroactive cost analysis of all saved sessions.

---

### Medium-term (S186–S190)

**Action 2: Add `/api/v1/analytics` endpoint**

```bash
GET /api/v1/analytics?since=<ISO>&until=<ISO>&tier=<fast|medium|strong>&workflow=<type>
```

Returns:
```json
{
    "period": "2026-06-19 to 2026-06-26",
    "total_sessions": 427,
    "tokens": {
        "input": 44123421,
        "output": 321412341,
        "cache_read": 2123412341,
        "cache_write": 123412341
    },
    "by_workflow": {
        "chat": { "sessions": 200, "tokens": 8234123, "avg_per_session": 41170 },
        "brainstorm": { "sessions": 100, "tokens": 2341234, "avg_per_session": 23412 },
        "create": { "sessions": 127, "tokens": 9234123, "avg_per_session": 72678 }
    },
    "by_tier": {
        "fast": { "sessions": 150, "tokens": 3121234 },
        "medium": { "sessions": 200, "tokens": 6123412 },
        "strong": { "sessions": 77, "tokens": 9234123 }
    },
    "by_model": {
        "claude-sonnet-4-6": { "sessions": 300, "tokens": 12341234 },
        "claude-opus-4-8": { "sessions": 100, "tokens": 8123412 },
        "claude-haiku-4-5": { "sessions": 27, "tokens": 2341234 }
    }
}
```

**Effort:** 2 hours (query transcripts, aggregate by dimension)

**Gain:** Real-time cost dashboard; enables billing per workflow type or tier.

---

**Action 3: Export score-usage-fit.py coefficients**

Create `RaBbLE-Grimoire/log/model-cost-coefficients.json`:

```json
{
    "generated_at": "2026-06-26T14:32:00Z",
    "baseline_model": "claude-sonnet-4-6",
    "note": "Empirical token→quota coefficients from score-usage-fit.py",
    "windows": {
        "5h": {
            "claude-opus-4-8": {
                "input": 1.33,
                "output": 1.33,
                "cache_read": 1.25,
                "cache_write": 1.25
            },
            "claude-sonnet-4-6": {
                "input": 1.0,
                "output": 1.0,
                "cache_read": 1.0,
                "cache_write": 1.0
            },
            "claude-haiku-4-5": {
                "input": 0.21,
                "output": 0.63,
                "cache_read": 0.21,
                "cache_write": 0.63
            }
        },
        "weekly": {
            "claude-opus-4-8": { ... },
            "claude-sonnet-4-6": { ... },
            "claude-haiku-4-5": { ... }
        }
    }
}
```

Export schedule: Post-fit in score-usage-fit.py, write to Grimoire log/ (weekly).

**Effort:** 1 hour

**Gain:** Centralized cost coefficients; enables accurate budgeting per model.

---

**Action 4: Extend session-tokens.sh to detect and normalize per-model**

Add `--per-model` flag:

```bash
bash spells/session-tokens.sh --per-model --recent 10
```

Output: per-session weighted cost normalized to Sonnet baseline:

```json
{
    "session_id": "abc123",
    "date": "2026-06-26 14:32",
    "project": "RaBbLE-sCoRE",
    "messages": 47,
    "model": "claude-haiku-4-5",
    "weighted_raw": 1000000,
    "weighted_sonnet_equivalent": 210000,
    "cost_estimate_sonnet": "$0.63",
    "cost_estimate_opus": "$1.20",
    "cost_estimate_haiku": "$0.17"
}
```

**Effort:** 2 hours (read .claude/settings.json per session, apply coefficients)

**Gain:** Accurate per-model cost visibility; reveals Haiku savings.

---

### Long-term (S191+)

**Action 5: Real-time token-burn monitoring (score-token-monitor.py)**

Implement waybar widget + alerting:

```python
def monitor(window="5h"):
    """Current quota % + burn rate."""
    log = load_log("~/.cache/rabble/llm-usage-log.jsonl")
    current_pct = log.latest_quota_pct(window)
    burn_rate_per_hour = log.burn_rate_last_hour()
    headroom_hours = (100 - current_pct) / burn_rate_per_hour
    
    return {
        "quota_pct": current_pct,
        "burn_rate": burn_rate_per_hour,
        "headroom": headroom_hours,
        "alert": "critical" if headroom_hours < 2 else None
    }
```

Show in waybar:
- `📊 45% 5h · 34K/h · 48h headroom` (normal)
- `🔴 78% 5h · 125K/h · 4h headroom` (warning)
- `⚠️ CRITICAL: 95% weekly, abort work`

**Effort:** 3 hours

**Gain:** Prevents token overruns (ep1-release-dispatch's 9.4M would've triggered abort at 7M).

---

## Files to Modify (Implementation Checklist)

### Immediate (S184–S185)

- [ ] `RaBbLE-sCoRE/server/transcripts.py` — add token_usage + model to save_transcript()
- [ ] `RaBbLE-sCoRE/server/llm.py` — propagate token_usage from client.messages.create()
- [ ] `RaBbLE-sCoRE/server/audit.py` — add token cost fields to action records
- [ ] `RaBbLE-Grimoire/log/model-cost-coefficients.json` (NEW) — export coefficients

### Medium-term (S186–S190)

- [ ] `RaBbLE-sCoRE/server/app.py` — add `/api/v1/analytics` endpoint
- [ ] `RaBbLE-Grimoire/spells/session-tokens.sh` — add `--per-model` flag
- [ ] `RaBbLE-Grimoire/spells/score-usage-fit.py` — export coefficients to JSON

### Long-term (S191+)

- [ ] `RaBbLE-OS/config/waybar/scripts/score-token-monitor.py` (NEW)
- [ ] Waybar config — add token-burn widget

---

## Why This Matters

### For Development (Now)

- **Budget per feature:** "World framework refactor cost 2.3M tokens; that's 3x expected."
- **Model efficiency:** "Haiku sessions are 10x cheaper; use it for cheap tasks."
- **Detect waste:** "ep1-release-dispatch was blocked 72h; burned 9.4M tokens for zero ROI."

### For Post-EP1 (Commercialization)

- **Per-user billing:** "User X used 50M tokens this month @ Sonnet rates = $150."
- **Feature ROI:** "Brainstorm workflow costs 45K tokens; refactor to 25K."
- **Quota management:** "You have 2 days of headroom at current burn rate; pause non-critical work."

---

## Summary: Token Tracking Maturity Levels

| Level | Current State | What's Missing |
|-------|---------------|-----------------|
| **0: Raw API polling** | ✅ score-usage-log.sh (5-min intervals) | — |
| **1: Session-level costs** | ❌ Transcripts saved but token usage dropped | Extract usage in transcripts.py |
| **2: Per-action attribution** | ❌ Audit logs actions, not costs | Add token cost to each action |
| **3: Feature-level ROI** | ⚠️ Token-ledger.tsv exists but only 35% tagged | Auto-register + backfill |
| **4: Real-time monitoring** | ❌ Polling data isolated in score-usage-fit.py | Build score-token-monitor.py |
| **5: Billing-ready** | ❌ No per-user/per-tier cost tracking | Add `/api/v1/analytics` endpoint |

We are at **Level 2.5** (session-level structure exists, token usage captured at LLM boundary but lost at persistence).

**Target for S186:** **Level 3.5** (per-action + real-time monitoring + export coefficients).

**Target for EP2:** **Level 5** (billing-ready analytics).

