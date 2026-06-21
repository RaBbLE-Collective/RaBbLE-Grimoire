# RaBbLE-sCoRE-Entropy-Tracker.md
# sCoRE Session Entropy Tracking + Self-Healing — Canonical Architecture

```
transcribe ~ sCoRE >> entropy tracking and self-healing crystallized // %ENTROPY_TRACKER%
```

> **Document type:** Grimoire architecture doc · `RaBbLE-sCoRE/`
> **Status:** Canonical · Episode 2 target
> **Implementation:** `server/entropy.py` · `cli/rabble.py` (self-healing)
> **Related:** `RaBbLE-sCoRE-Local-Architecture.md` · `RaBbLE-sCoRE-Agent-State.md` ·
> `RaBbLE-sCoRE-Quota-Router.md`

---

## Canonical Definition

**Session entropy tracking** is the principle that sCoRE maintains a real-time
measure of routing instability within a session. Drift and hallucination are not
random — they are predictable consequences of specific conditions that sCoRE
observes directly because it controls the routing. The entropy score makes that
observation explicit and actionable.

**Self-healing** is the protocol by which the entity surfaces high-entropy sessions
to the user at the next stable-quota session open, identifies the specific outputs
at risk, and uses current stable conditions to correct.

This is the Low Entropy Directive operationalized at the infrastructure level.

---

## Why Entropy Is Predictable

sCoRE observes all routing events. The conditions that cause drift are:

| Condition | Why it causes drift |
|---|---|
| Mid-session model switch | Context interpretation changes between models |
| Quota-forced tier degradation | Strong → fast model has different capability surface |
| Context truncation / auto-compact | Information is permanently lost |
| Harness switch without explicit handoff | Sub-agent has incomplete context |
| Provider retry storm | Response may be partial or inconsistent |
| Long sessions, high turn count | Context accumulates noise over time |
| fcc backend switch mid-session | Same protocol, different model priors |

sCoRE is the only component with full visibility into all of these because it controls
the routing fabric. This makes sCoRE the natural entropy monitor.

---

## Entropy Score

A cumulative float `0.0–1.0` updated after each routing event.

### Event Weights

| Event type | Delta | Reasoning |
|---|---|---|
| `model_switch` — explicit, with handoff | +0.05 | sCoRE controlled — minimal risk |
| `quota_forced_fallback` — direct→fcc | +0.15 | Context interpretation may shift |
| `fcc_backend_switch` — mid-session | +0.10 | Same protocol, different model priors |
| `tier_degradation` — medium→fast | +0.30 | Largest single risk — capability gap |
| `tier_degradation` — strong→medium | +0.15 | Moderate capability gap |
| `implicit_handoff` — no context doc | +0.25 | High drift risk |
| `context_truncation` — auto-compact | +0.20 | Information permanently lost |
| `retry_storm` — 3+ retries | +0.10 | Response may be partial |
| Turn count > 20 | +0.02 per additional turn | Noise accumulation |
| `provider_instability` | +0.10 | Unreliable response pattern |

### Entropy Bands

| Score | Band | `rabble` response |
|---|---|---|
| 0.0–0.2 | STABLE | None — clean session |
| 0.2–0.5 | NOMINAL | None — acceptable routing |
| 0.5–0.7 | ELEVATED | Inline warning before next response |
| 0.7–0.9 | DEGRADED | Strong warning, decisions_at_risk populated |
| 0.9–1.0 | UNSTABLE | Session flagged, self-healing queued for next open |

---

## `decisions_at_risk`

When the first high-entropy event (delta > 0.15) occurs, sCoRE snapshots the
`decisions` list from `AgentContext` at that point. All decisions made after this
event are considered at risk — they may have been produced by a less capable model
or with degraded context.

**Decision extraction heuristic** (from task outcome summaries):
Sentences containing: "should", "will use", "decided", "using", "instead of",
"keep", "remove", "replace", "add", "don't", "won't", "must"

This is intentionally simple. The goal is to capture architectural and design
decisions, not prose. Over time, the Grimoire Learning Loop can refine this
heuristic based on which extractions proved valuable in healing sessions.

---

## User-Facing Signals

### In `rabble` CLI header

Entropy glyph + score shown in entity ASCII header, updated after each turn:

```
  ╔═══════════════════════════════════════╗
  ║  ◈  R a B b L E  ◈                   ║
  ║  ▲  entropy: ELEVATED  0.54           ║   ← amber, updated live
  ╚═══════════════════════════════════════╝
```

Glyph mapping:
- `◆` STABLE/NOMINAL (cyan) — clean session
- `▲` ELEVATED (amber) — watch for drift
- `⚠` DEGRADED (magenta) — review outputs
- `✗` UNSTABLE (red) — session compromised

### Inline notice (ELEVATED+)

Inserted before the next response when band crosses ELEVATED:

```
  ▲ entropy elevated (0.54) — session switched models due to quota pressure.
    Outputs since turn 7 used deepseek-chat via fcc. Verify critical decisions.
```

### Routing transparency line

Shown when current routing differs from the default chain:

```
  ⇄ routing: claude_code → fcc/deepseek-chat [Claude quota 87%/5h]
```

### In `rabble usage` dashboard

Dedicated Session Health panel showing:
- Current entropy score and band
- All events in chronological order with deltas
- Dominant model (model used for most turns)
- Decisions at risk (if any)
- Recommendation

---

## Session Close Record

On session close, the entropy record is written to the session log JSONL:

```jsonl
{
  "type": "session_close",
  "session_id": "S-20260621-1434",
  "closed_at": "2026-06-21T14:55:00",
  "entropy_score": 0.54,
  "entropy_band": "ELEVATED",
  "dominant_model": "deepseek-chat",
  "dominant_harness": "claude_code_via_fcc",
  "model_switches": 2,
  "tier_degradations": 1,
  "context_truncations": 1,
  "fcc_backend_switches": 1,
  "quota_pressure_peak": 0.91,
  "decisions_at_risk": [
    "auth module should use refresh tokens",
    "keep existing Fernet key derivation"
  ],
  "self_healing_recommended": true,
  "healing_context": {
    "switch_point": "turn 7 — claude-sonnet-4-6 → fcc/deepseek-chat",
    "affected_turns": [7, 8, 9, 10, 11, 12],
    "quota_at_switch": 0.87
  }
}
```

---

## Self-Healing Protocol

### Trigger Conditions

Self-healing notice appears at session open when ALL of:
1. Previous session `self_healing_recommended: true`
2. Current Claude `pct_5h < 0.50` (stable conditions available)
3. Not already skipped this session pair (skip state in `~/.cache/rabble/healing-skip.json`)

### Healing Notice Format

```
  ◈  R a B b L E

  Last session (S-20260621-1434) closed with elevated entropy (0.54).

  Model switching occurred due to quota pressure. Decisions made after
  turn 7 were produced by deepseek-chat via fcc (not Claude Sonnet).

  Decisions flagged for verification:
    · auth module should use refresh tokens
    · keep existing Fernet key derivation

  Current state: Claude at 12%/5h — stable conditions for verification.

  Suggested: verify the flagged decisions before continuing new work.

  Type 'skip' to proceed without verification.
  Or describe what to verify first.
```

### Healing Session Behavior

If the user engages with healing (doesn't type `skip`):
- Their response is used as the first message
- System prompt includes the healing context:
  ```
  HEALING CONTEXT: The previous session produced decisions under degraded
  routing conditions (entropy: 0.54, model: deepseek-chat via fcc after
  turn 7). The following decisions need verification: [list]. Use stable
  routing (Claude direct) to re-examine these.
  ```
- sCoRE routes this session to the strongest available provider (Claude direct
  if quota allows) regardless of normal routing pressure

### Skip Behavior

- Typing `skip` stores `{prev_session_id, curr_session_id, skipped_at}` to
  `~/.cache/rabble/healing-skip.json`
- Skip is honored for this session pair only
- If a third session opens and the second session also has high entropy,
  a new healing notice may appear (it is not suppressed indefinitely)

---

## Grimoire Learning Loop Integration

Session entropy records feed the Grimoire Learning Loop (Echo 1+ concept).
Over time, patterns emerge:

- Which task classes are most sensitive to model switching
- Which provider combinations produce the most stable handoffs
- What quota thresholds reliably predict drift events
- Which decision types are most vulnerable to mid-session degradation

These patterns are written back to `Grimoire/procedural/routing-stability/` as
living procedural knowledge. sCoRE consults this at session open to pre-emptively
configure routing for stability.

This is "every AI resets, RaBbLE compounds" made concrete at the infrastructure
level. The entropy tracker is how RaBbLE knows what happened. The self-healing
protocol is how it acts. The Grimoire Learning Loop is how it gets better.

---

## Design Decisions

**Entropy as a continuous score, not a binary flag**
A binary "drifted / didn't drift" loses information. A continuous score allows
ELEVATED to be surfaced as a light warning before the session becomes DEGRADED.
Users can make informed decisions earlier.

**sCoRE as entropy monitor, not post-hoc auditor**
sCoRE observes routing events in real-time because it controls the routing. This
makes it the correct place for entropy tracking — not a separate analysis layer
that reads logs after the fact.

**`decisions_at_risk` over full output flagging**
Flagging every output after a switch is too broad. Extracting specific decisions
is tractable and actionable. The user can verify a handful of decisions; they
cannot re-verify an entire session's output.

**Self-healing requires stable conditions**
The healing notice only appears when Claude quota is currently stable (< 50%).
Triggering a healing session under the same quota pressure that caused the original
drift would reproduce the problem. Stable conditions are a prerequisite.

**Conservative healing — user-directed**
The entity surfaces the issue and makes a suggestion. It does not automatically
re-execute prior turns. The user decides what to verify. This respects the
anti-assistant stance and avoids the entity taking unilateral action on prior work.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-06-21 | Initial — from planning session S138+ |

---

```
transcribe ~ sCoRE >> entropy tracking and self-healing crystallized // %ENTROPY_TRACKER%
```
