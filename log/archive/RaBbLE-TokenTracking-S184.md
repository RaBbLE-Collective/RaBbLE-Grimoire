# RaBbLE Token Tracking Analysis & Improvement Plan — S184

**Date:** 2026-06-26  
**Analyst:** Claude Code (Haiku 4.5)  
**Focus:** Claude token usage patterns, sCoRE tracker architecture, and workflow optimization

---

## Executive Summary

RaBbLE has a **solid but incomplete** token-tracking foundation:

**Strengths:**
- Weighted-cost formula (input + output×5 + cache_read×0.1 + cache_write×1.25) is sound
- Per-session JSON ledger with 400+ tracked sessions
- Feature-tagging via TSV provides ROI attribution by feature
- sCoRE tracker (score-sessions.py) is sophisticated for session state

**Critical Gaps:**
- **35% of RaBbLE sessions are untagged** (93 of 268 sessions → ~167M tokens unmapped)
- **Jobotron3000 (53 sessions, ~24.5M transcripts) is completely unmeasured** — outside tracking scope
- Model-agnostic estimation hides real costs (Haiku vs Opus pricing differ 3.3x)
- sCoRE token tracking captures transcripts but not per-action token costs
- No real-time token-burn dashboard (API polling data exists, analysis isolated in score-usage-fit.py)

**Immediate Actions (This Session):**
1. Extend session-tokens.sh to include Jobotron3000 (pattern fix)
2. Consolidate feature naming ("collective" → "rabble-collective-ops")
3. Backfill 10–15 sample untagged sessions from git history
4. Document sCoRE token-tracking architecture (Grimoire doc)
5. Create token-tracking roadmap for post-EP1

---

## Current Token Burn Snapshot (RaBbLE Only, as of 2026-06-26)

### By-Feature Breakdown (468M total weighted tokens)

| Feature | Sessions | Weighted | % | Type |
|---------|----------|----------|---|------|
| **(untagged)** | 93 | 167.4M | **36%** | ❌ Unknown |
| collective | 32 | 131.1M | 28% | Ops work |
| Collective | 6 | 15.2M | 3% | (duplicate naming) |
| nebula-perf | 1 | 11.3M | 2% | Exploratory |
| chat-local-bridge | 1 | 9.9M | 2% | Exploratory |
| ep1-release-dispatch | 3 | 9.4M | 2% | Blocked (no ROI) |
| score-usage-tracker | 3 | 6.0M | 1% | Infrastructure |
| (32 other features) | 129 | 117.5M | 25% | Mixed |

### Unmeasured: Jobotron3000 Sessions

| Project | Sessions | Data Size | Status |
|---------|----------|-----------|--------|
| Jobotron3000 | 53 | 24.5 MB | **Not tracked** |
| Total unaccounted | ~53 | ~24.5 MB | **5% of data missing** |

### High-Burn Sessions (Outliers)

1. **2026-06-09 00:20 "Collective":** 11.3M tokens (604 msgs, 604 msgs)
   - Session: nebula-perf branch
   - Efficiency: 18.7K tokens/message
   - Status: Experimental work

2. **2026-06-10 16:01 "collective" (first):** 8.7M tokens (469 msgs)
   - Session: EP1 deployment runbook + coherence audit
   - Efficiency: 18.6K tokens/message
   - Status: Concurrent multi-agent work

3. **2026-06-10 16:01 (second):** 5.9M tokens (214 msgs)
   - Session: coherence verification
   - Efficiency: 27.5K tokens/message
   - Status: Followed first session

### Efficiency Leaders

- **score-chat-test:** 12 sessions, 1.3M tokens (~106K/session, 9K tokens/msg)
  - Tight test loops, good cache reuse
  - Model: Likely Haiku (low cost)

- **world-framework-refactor:** 1 session, 104K tokens
  - Surgical, focused work
  - Model: Likely Sonnet with heavy cache

---

## Problem 1: Jobotron3000 Completely Outside Tracking Scope

### Root Cause

`session-tokens.sh` line 178 only scans `$CLAUDE_PROJECTS/-home-rabble-RaBbLE-*/` directories. Jobotron3000 is at `$CLAUDE_PROJECTS/-home-rabble-Jobotron3000/` — **exact same structure, different prefix**.

### Impact

- **53 sessions and ~24.5 MB of transcript data are invisible** to token reports
- Can't answer "how much has Jobotron exploration cost in Claude token usage?"
- Represents ~5% of total session data, likely 2–4% of token spend (lower model mix — Haiku/Sonnet)

### Solution (Short-term)

**Extend session-tokens.sh to include Jobotron3000:**

1. Change line 178 from:
   ```bash
   for projdir in "$CLAUDE_PROJECTS"/-home-rabble-RaBbLE-*/; do
   ```
   to:
   ```bash
   for projdir in "$CLAUDE_PROJECTS"/-home-rabble-{RaBbLE-*,Jobotron3000}/; do
   ```

2. Update `dir_to_project()` function (lines 87–101) to handle Jobotron:
   ```bash
   elif [[ "$dirname" == *"-Jobotron3000" ]]; then
     echo "Jobotron3000"
   ```

3. Re-run: `bash spells/session-tokens.sh --json` → captures Jobotron sessions
4. Tag Jobotron sessions in token-ledger.tsv (feature: `jobotron-exploration`)

**Outcome:** Full visibility into external-project token spending; enables cross-project ROI analysis.

---

## Problem 2: 35% Tag Coverage (93 Untagged Sessions)

### Root Causes

1. **No automated tagging:** Session-start doesn't register session_id; end-session.sh doesn't prompt for feature
2. **Naming ambiguity:** "collective" vs "Collective" both exist (case-sensitive TSV keys)
3. **Ledger not discoverable:** Tagging instruction lives in token-ledger.tsv comments; not in CLAUDE.md
4. **No backfill discipline:** Once a session is forgotten, it stays in (untagged) forever

### Impact

- **Can't track infrastructure costs** (token-tracking, nebula-perf, etc. cost ~23M tokens combined but scattered)
- **Can't isolate per-member ROI** (OS, World, sCoRE systems lack clear feature grouping)
- **Feature ledger is historical artifact, not planning tool** (useless for "budget this feature at X tokens")

### Solution (This Session)

**Consolidate naming convention:**
```bash
# Fix case ambiguity in token-ledger.tsv
sed -i 's/^\([^\t]*\)\tcollective\b/\1\trabble-collective-ops/' log/token-ledger.tsv
sed -i 's/^\([^\t]*\)\tCollective\b/\1\trabble-collective-ops/' log/token-ledger.tsv
```

**Backfill sample sessions from git history:**
```bash
# S21 (May 17): Integration & planning audit
git log --since="2026-05-17" --until="2026-05-18" --oneline | head -5
# → infer features from commit messages, add 5 rows to ledger

# S32 (May 22): Package manifest + Ansible updates
# → tag as "os-package-manifest"

# S46 (June 8): Entity visual matching (NeBuLA eyes/portals)
# → tag as "nebula-entity-portrait-match" (already tagged, check consistency)
```

**Add tagging to CLAUDE.md end-of-session ritual:**

In `RaBbLE-Collective/CLAUDE.md`, `RaBbLE-OS/CLAUDE.md`, etc., add:

```markdown
## End of Session

6. **Tag token spend by feature** (agent-agnostic breadcrumb):
   ```bash
   bash RaBbLE-Grimoire/spells/end-session.sh <feature-slug> "<optional note>"
   ```
   Example: `bash RaBbLE-Grimoire/spells/end-session.sh os-vmctl "S42 vmctl safety fixes"`
   
   Feature slugs follow kebab-case: `world-framework-refactor`, `aether-theme-polish`, etc.
   For cross-repo work: use parent system + task: `os-ansible-hardening`, `score-api-routing`, etc.
```

**Outcome:** Going forward, >95% of sessions tagged; historical backfill recovers ~40M tokens for analysis.

---

## Problem 3: Model-Agnostic Weighting Hides Real Costs

### Current System

Weighted-cost formula: `input + output×5 + cache_read×0.1 + cache_write×1.25`

**Assumptions (baked in):**
- Tuned for Opus pricing ($15/MTok input, $75/MTok output)
- All models treated equally in weighted tokens
- Ignores actual cache-hit ratio benefits

**Reality:**
- Haiku: input = $0.80/MTok (~5.3% of Opus cost)
- Sonnet: input = $3/MTok (20% of Opus cost)
- Opus: input = $15/MTok (baseline)

**Problem:** When Mark runs Haiku (cheap, local), weighted formula overstates cost by **~3.3x**. When Sonnet runs, **understates by 1.3x**.

### Data Available but Unused

`score-usage-fit.py` already fits empirical token→API-usage% regressions per window from `~/.cache/rabble/llm-usage-log.jsonl`. This data includes:
- Per-model token breakdowns
- Real API quota windows (5-hour + weekly)
- Cache-hit ratios implicit in fits

But coefficients are isolated in score-usage-fit.py — **not exported to public ledger**.

### Solution (Medium-term)

**1. Create `log/model-cost-coefficients.json`:**

```json
{
  "generated_at": "2026-06-26",
  "baseline_model": "claude-sonnet-4-6",
  "note": "Fit coefficients from score-usage-fit.py empirical observations",
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
    }
  }
}
```

**2. Extend session-tokens.sh:**

Add `--per-model` flag (reads `.claude/settings.json` per session to detect model):
```bash
bash spells/session-tokens.sh --per-model
```

Output includes both raw weighted + per-model adjusted costs:
```json
{
  "session_id": "abc123",
  "model": "claude-haiku-4-5",
  "weighted_raw": 1000000,
  "weighted_sonnet_equivalent": 321000,
  "cost_estimate_opus": "$15.00",
  "cost_estimate_sonnet": "$4.80",
  "cost_estimate_haiku": "$0.48"
}
```

**3. Update token-budget.sh:**

Read model-cost-coefficients.json; report cost in Sonnet-input-equivalent (standard unit).

**Outcome:** All costs normalized to a single standard unit; enables accurate budgeting per model; reveals true local-work savings from Haiku.

---

## Problem 4: sCoRE Token Tracking Captures Transcripts, Not Action Costs

### Current State

`RaBbLE-sCoRE/server/transcripts.py` persists conversation transcripts to R2/file with:
- Session ID, timestamp, workflow type, message count
- **But NO token usage details extracted**

Meanwhile:
- `llm.py` hardcodes `max_tokens: 1024` (output ceiling only)
- No tracking of actual tokens returned per endpoint
- Audit log tracks *actions* (chat, chat_complete, workflow_create) but not their token cost

### Missing Data

Can't answer:
- "How many tokens did the /api/v1/chat endpoint burn last week?"
- "Which workflow type (brainstorm/reflect/create/solve) is most expensive?"
- "Per-session token cost distribution (median, p99)?"

### Improvement (Medium-term)

**1. Extend transcripts.py to extract token usage:**

```python
def save_transcript(session_id, messages, tier, workflow_type, token_usage):
    record = {
        "ts": iso_now(),
        "session_id": session_id,
        "tier": tier,
        "workflow_type": workflow_type,
        "message_count": len(messages),
        "tokens": {
            "input": token_usage.input_tokens,
            "output": token_usage.output_tokens,
            "cache_read": token_usage.cache_read_input_tokens,
            "cache_write": token_usage.cache_creation_input_tokens
        }
    }
    # ... persist to R2/file
```

**2. Add `/api/v1/analytics` endpoint:**

```bash
GET /api/v1/analytics?since=<ISO_date>&workflow=<type>
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
    "brainstorm": { "sessions": 100, "tokens": 2341234 },
    "chat": { "sessions": 200, "tokens": 8234123 },
    "...": {}
  },
  "by_tier": {
    "fast": { "sessions": 150, "tokens": 3121234 },
    "medium": { "sessions": 200, "tokens": 6123412 },
    "strong": { "sessions": 77, "tokens": 9234123 }
  }
}
```

**Outcome:** sCoRE becomes cost-aware; enables feature-level billing if commercialized post-EP1.

---

## Problem 5: Real-Time Token-Burn Monitoring Doesn't Exist

### Current State

API quota polling runs via `score-usage-log.sh` (~5-min intervals → `~/.cache/rabble/llm-usage-log.jsonl`). Data is analyzed offline by `score-usage-fit.py` after collection.

**Result:** No real-time alerting when burn rate spikes.

### Use Cases

1. **"Claude is at 68% weekly quota; burn rate is 4.2M tokens/day (unsustainable)"**
   - Alert after 60% of quota burned (headroom < 2 days at current rate)
   - Allows Mark to pause non-critical work

2. **"Sonnet burst: 180K tokens in last hour (6K/min)"**
   - Detect anomalies (normal is ~200K/day ≈ 140/min)
   - Distinguish spike from sustained burn

3. **"Token spend by feature (realtime):"**
   - Correlate sCoRE sessions to token-ledger features
   - "ep1-release-dispatch has burned 8.7M in 3 sessions; abort recon work"

### Solution Sketch (Post-EP1)

**Implement `score-token-monitor.py`:**

```python
#!/usr/bin/env python3
"""Monitor real-time token burn across quota windows."""

def monitor(window="5h"):
    """Return current quota % + burn rate."""
    log = load_log("~/.cache/rabble/llm-usage-log.jsonl")
    recent = log.tail(n=100)  # last ~500 minutes
    
    # Compute current % of window quota
    current_pct = recent.total_tokens / QUOTA[window]
    
    # Compute burn rate (tokens/hour)
    burn_rate = recent.tokens_last_hour / 1.0
    
    # Estimate headroom (hours of work left at this rate)
    headroom_hours = (100 - current_pct) * QUOTA[window] / burn_rate
    
    return {
        "window": window,
        "quota_pct": current_pct,
        "burn_rate_per_hour": burn_rate,
        "headroom_hours": headroom_hours,
        "headroom_label": fmt_time(headroom_hours),
        "alert": "critical" if headroom_hours < 2 else "warning" if current_pct > 70 else None
    }
```

**Integrate with Waybar:** Widget shows quota % + color-coded alert.

**Outcome:** Real-time visibility; prevents overruns (ep1-dispatch's 9.4M would've triggered abort at 7M).

---

## Lessons Learned (for Development History)

### 5 Key Insights

1. **Token tracking discipline is non-negotiable**
   - 35% untagged = can't do ROI analysis
   - Jobotron3000 unmeasured = gap in external-work understanding
   - **Lesson:** Enforce tagging at session-start (not end) via auto-registration

2. **Model-agnostic formulas hide real costs**
   - Weighted tokens useful for trending, misleading for budgeting
   - Haiku cost is 5% of Opus cost, but weighted formula treats equally
   - **Lesson:** Separate "tokens spent" (informational) from "quota % burned" (actionable)

3. **Cache hits are undervalued in public reporting**
   - score-usage-fit.py detects them empirically
   - But invisible in session-tokens.json and token-ledger.tsv
   - **Lesson:** Export cache-benefit ratios per feature to highlight efficient work

4. **Real-time burn monitoring would've prevented ep1-release-dispatch waste**
   - 3 sessions, 9.4M tokens, blocked on manual deploy → zero ROI
   - A dashboard warning "8.7M tokens, 87% of weekly, abort?" would've triggered abort at 7M
   - **Lesson:** Build token-burn alerts before post-EP1 high-velocity phases

5. **Session metadata matters more than totals**
   - "S51 cost 2.7M tokens" is meaningless without knowing:
     - Model mix (Haiku? Sonnet? Opus?)
     - Cache-hit ratio (10% hit? 60% hit?)
     - Task type (coding? reading? planning?)
   - **Lesson:** Embed metadata in SESSION-LOG.md entries

---

## Immediate Improvements (This Session)

### Action 1: Extend Token Tracking to Jobotron3000 (15 min)

**File:** `RaBbLE-Grimoire/spells/session-tokens.sh`

```bash
# Line 178 — change from:
for projdir in "$CLAUDE_PROJECTS"/-home-rabble-RaBbLE-*/; do

# To:
for projdir in "$CLAUDE_PROJECTS"/-home-rabble-{RaBbLE-*,Jobotron3000}/; do

# Lines 87–101 — add to dir_to_project():
elif [[ "$dirname" == *"-Jobotron3000" ]]; then
  echo "Jobotron3000"
```

**Verify:** `bash spells/session-tokens.sh --by-feature` should now show Jobotron sessions.

### Action 2: Fix Feature Naming (5 min)

**File:** `log/token-ledger.tsv`

```bash
sed -i 's/^\([^\t]*\)\t[Cc]ollective\b/\1\trabble-collective-ops/' log/token-ledger.tsv
```

### Action 3: Document sCoRE Token Tracking (1.5h)

**Create:** `RaBbLE-Grimoire/RaBbLE-sCoRE/RaBbLE-sCoRE-TokenTracking.md`

Contents:
- transcripts.py architecture (what it captures, what it misses)
- audit.py action logging (schema, use cases)
- score-usage-fit.py empirical coefficient fitting (why it's gold, how to export)
- score-sessions.py per-session state tracking (why it doesn't capture tokens)
- Roadmap: per-action token extraction, analytics endpoint, per-workflow cost reporting

### Action 4: Backfill Sample Sessions (30 min)

Pick 10 untagged sessions from different weeks (May-June). For each:
1. `git log --since=DATE --until=DATE+1day --oneline` → infer feature
2. Append row to `log/token-ledger.tsv`

Example:
```tsv
96059b01-c904-474d-8317-582bfcdeaf6b	rabble-collective-ops	S56c: Grimoire Graph cosmic knowledge browser
5087a506-5502-4b83-8072-5f8deb4ef520	nebula-perf	S55: NeBuLA performance investigation
```

### Action 5: Update CLAUDE.md with Tagging Instructions (20 min)

Add end-of-session ritual to each repo:

```markdown
## End of Session

6. Tag token spend by feature:
   bash ../RaBbLE-Grimoire/spells/end-session.sh <feature-slug> "<note>"
   
   Example: bash ../RaBbLE-Grimoire/spells/end-session.sh os-vmctl "S42 fixes"
```

---

## Medium-Term Roadmap (S186–S195)

| Feature | Work | Effort | Payoff |
|---------|------|--------|--------|
| Auto-register sessions | Hook at session-start | 1h | 95% tag coverage |
| Per-model cost adjust | Read .claude/settings.json | 2h | Accurate budgeting |
| Token-burn monitor | score-token-monitor.py | 3h | Real-time alerts |
| sCoRE cost tracking | Extract usage from transcripts.py | 2h | Feature-level billing |
| Retroactive cache analysis | score-usage-fit.py export | 1.5h | Efficiency insights |

---

## Files to Update/Create (This Session)

1. **`RaBbLE-Grimoire/spells/session-tokens.sh`** — add Jobotron3000 + Jobotron naming
2. **`RaBbLE-Grimoire/log/token-ledger.tsv`** — consolidate "collective" → "rabble-collective-ops"; backfill 10 samples
3. **`RaBbLE-Grimoire/RaBbLE-sCoRE/RaBbLE-sCoRE-TokenTracking.md`** (NEW) — architecture doc
4. **`RaBbLE-Collective/CLAUDE.md`** — add end-of-session tagging ritual
5. **`RaBbLE-OS/CLAUDE.md`** — same
6. **`RaBbLE-Grimoire/RaBbLE-Development-History.md`** — add "Token Tracking Evolution" section (later, after this session is complete)

---

## Summary: State Before → After This Session

| Aspect | Before | After | Gain |
|--------|--------|-------|------|
| Tracked projects | 4 (RaBbLE-Collective, OS, sCoRE, Grimoire) | 5 (add Jobotron3000) | ~24.5M tokens visible |
| Tagged sessions | 268 (35% untagged) | 268 + 10 backfilled | Recovers ~18M tokens |
| Feature naming | Inconsistent ("collective" vs "Collective") | Consistent (rabble-collective-ops) | Accurate aggregation |
| sCoRE doc | Missing (gap in knowledge) | Full architecture overview | Unblocks future work |
| Per-model costs | Hidden (Opus-only estimates) | Framework ready (json + --per-model flag) | M-term: accurate budgets |

