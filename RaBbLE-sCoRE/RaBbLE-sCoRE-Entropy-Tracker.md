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

A float `0.0–1.0` with three parts (v0.2, S285):

```
score = baseline(model) + damage + pressure
```

- **Baseline** is the model's own trust. Frontier models (fable, opus, sonnet, gpt) start at 0.05 (fable, opus, gpt) to 0.13 (sonnet)
  (STABLE, `trusted`, near-clean entity). A weak model (haiku) starts at 0.55 (ELEVATED, `strict`):
  a low-trust model *is* a high-entropy model. Unknown models start at 0.25.
- **Damage** is cumulative (v0.4: transient faults decay, structural loss is only partly recoverable; see Capability Model). It records where information or provenance was lost
  (the event table below). A model that has forgotten the start of a session is not trustworthy
  again because the window has space.
- **Pressure** is the live state of the session. It rises and falls, so a fresh session is clean and a
  nearly full one is not (table below).

The score drives three signals together: the trust profile (auto-approve level), the entity's glitch,
and the header band. They exist so the Observer can see how far to trust an answer and when to watch
the model's behaviour more closely.

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
| `provider_instability` | +0.10 | Unreliable response pattern |

### Pressure (live, recovers)

| Term | Contribution | Notes |
|---|---|---|
| Context fill | 0 up to 50% of the window, ramping linearly to +0.25 at 90% | Falls when the window frees. Compaction itself is `context_truncation` damage. |
| Rate limit `warning` | +0.05 while it lasts | `rejected` adds +0.10 while it lasts, plus the one-time `provider_instability` damage on entry |
| Long session | +0.01 per turn beyond 20, capped at +0.10 | Replaces the old per-turn damage |

A notice appears when pressure moves the score into a worse band ("context 85% full"). Constants
are guesses (`orchestra/entropy.py`: `CONTEXT_*`, `LONG_*`, `LIMIT_PRESSURE`), to be tuned from live use.
Context pressure alone caps a frontier model at about NOMINAL; reaching ELEVATED needs damage or a
weaker model. Raise `CONTEXT_MAX` (about 0.45) if a full window alone should read as ELEVATED.

### Trust and glitch

- **Trust profile** earned from the score: below 0.2 `trusted`, below 0.5 `standard`, else `strict`.
  The Observer can override with `/trust`.
- **Glitch** (`ui/face.py` `signal_level`): clean below 0.2, then linear to full signal loss at 1.0.
  Frontier models stay clean; haiku shows visible static; UNSTABLE tears rows and drops signal.

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

## Capability Model (v0.4, S287)

Entropy is how much of a model's capability a session has lost. v0.4 makes the capability itself a
number, so a session can say what it can still do, not only how worried to be.

```
capability(category) = base(model, category) - 100 * (damage(category) + pressure(category))      0..100
score (entropy)      = 1 - capability(general) / 100                                          0..1, as before
```

**Categories.** `general`, `coding`, `tools` (agentic tool use) and `recall` (fidelity over a long
context). A small model can be weak in `general` and strong in `coding`; a bloated session loses
`recall` and `coding` before it loses `general`. The registry is `orchestra/capabilities.json`
(override or extend at `~/.config/rabble/capabilities.json`); each entry carries a `source`
(`estimate` until measured) so the numbers can be replaced by evidence without touching code.

| Model | general | tier it earns | Notes |
|---|---|---|---|
| fable | 95 | trusted | |
| opus | 85 | trusted | |
| sonnet | 70 | trusted | |
| haiku | 35 | strict | placeholder, Mark to confirm |
| local (qwen, llama...) | 25 | strict, `local` | runs on this machine |
| unknown cloud API | 25 | strict | the safe default for anything not in the registry |

**Tier from capability.** `trusted` >= 60, `standard` >= 40, `strict` below. Tool gating (auto-approving
Bash and edits) reads `coding`, not `general`, so a coding-strong small model can earn trust for the
work it is good at. The header shows the tier with the numbers: `trusted - gen 70 - code 76`.

**Damage now has two kinds.**

| Kind | Events | Behaviour |
|---|---|---|
| Transient | `model_switch`, handoff, `quota_forced_fallback`, `fcc_backend_switch`, `provider_instability`, `retry_storm` | Decays 20% per clean turn (a turn with no failed request). A fault that has passed stops costing. |
| Structural | `context_truncation`, `implicit_handoff`, `tier_degradation` | Information was lost. Never decays with time. |

**Re-grounding earns structural damage back, partly.** After structural damage, reading a file the
session has not read since (+0.02 each) or a passing test run (+0.03) restores capability, capped at
half of the structural damage taken. The rest only a park recovers: a parked session starts fresh
from its handoff at the model's base plus the 0.05 handoff mark. So re-grounding keeps a session
useful, and parking stays the right move for a long or bloated one.

**Category weighting.** Damage and pressure are scaled per category (`CATEGORY_WEIGHT`): context
fill and compaction weigh 1.5x on `recall` and 1.2x on `coding`; provider faults weigh 1.3x on
`tools`; a tier drop weighs the same everywhere. These are guesses to be tuned from live use.

**Bloat.** The session tracks context tokens and fill per turn (`orchestra/park.py: Bloat`): growth
per turn, an estimate of turns until the park point, and cumulative token-reads (each turn re-reads
the context, so the sum is what resuming the session cold would cost). Park triggers on context
>= 80%, or earlier when the growth rate would pass 95% before the next check. See `/park`.

## Direction (v0.5, planned, not built) (S287)

Mark's direction after the v0.4 build. Two corrections to what v0.4 does.

**1. Entropy and stability are different things.** v0.4 folds both into one number, so the entity
glitches the same way for "a weak model" and for "a degraded session". They are linked, not equal:
a low-entropy model can be unstable (a frontier model with a bloated, compacted session), and a
high-entropy model can be stable (a small local model, fresh and clean).

| | Entropy | Stability |
|---|---|---|
| Is | How much the model can do: `100 - capability(model)` | How healthy this session is: damage, pressure, bloat |
| Changes | Only when the model changes | Every turn; recovers (decay, re-grounding) and resets on a park |
| The entity shows it as | **Static**: a steady grain, constant while the model is the same | **Glitch and breaking**: tears, channel splits, dropped rows; worse as stability falls and as bloat rises |
| Trust reads | the model's capability | the session's capability after loss (today's `capability(category)`) |

So an opus session is clean-grained at the start and starts to tear as it bloats; a local qwen
session carries static from the first frame but does not break until the session itself degrades.
Today `signal_level(score)` in `ui/face.py` is one curve over both; it becomes two inputs: a static
level from model entropy and a break level from stability (including bloat as its own term, so a
filling window breaks the entity before it costs trust).

**2. Capability numbers come from benchmarks, and scale as models improve.** The v0.4 registry is
estimates (`source: estimate`). The plan:

- Each registry entry carries raw benchmark results per category, with the benchmark name, version,
  date and source, and the category score is derived from them, never typed in. Candidate sources
  by category (to be chosen and confirmed, none are recorded yet): `general` (broad knowledge and
  reasoning suites, human-preference ratings), `coding` (SWE-style repo tasks, competitive and live
  coding sets), `tools` (agentic tool-use and terminal suites), `recall` (long-context retrieval
  and multi-needle sets).
- A normalisation step maps raw scores to 0-100 per category against a reference that can move.
  **Decision for Mark:** an absolute scale (numbers stay put, the frontier saturates near 100 and
  thresholds like trusted >= 60 eventually mean less) or a frontier-relative scale (the reference is
  the best known model at a registry revision; a new frontier rescales everyone, and thresholds
  stay meaningful but old numbers shift, so entries record the reference version they were scaled
  against). Recommendation: frontier-relative with the reference version stored, and a
  `capabilities.lock` of the last published scale so a session does not change mid-flight.
- An ingest spell (`spells/`) reads a curated benchmark file (JSON or CSV committed to the Grimoire)
  and rewrites the registry. No scraping: a person (or a reviewed agent run) enters results with their
  source, so every number can be traced.
- A new model needs only its benchmark rows to get a tier. Local models are measured the same way,
  on this machine's quantisation, since a local model's score depends on how it is run.
- Measured-in-use signals (tool-call failure rate, test pass rate after edits) may later adjust a
  session's capability, labelled as observed, never overwriting the benchmark.

Open: which benchmarks per category; absolute vs frontier-relative (above); whether `recall` is
benchmarked or measured in use; whether stability gets its own 0-100 number in the header next to
the capability tier.

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-06-21 | Initial — from planning session S138+ |
| v0.2 | 2026-10-28 | Score split into baseline + cumulative damage + live pressure (context fill, rate limit, long session); frontier models incl. sonnet are low entropy; trust and glitch derived from the score. Implemented in `RaBbLE-sCoRE/orchestra/entropy.py` (S284/S285) |
| v0.3 | 2026-10-28 | Glitch level is a piecewise curve on the score (`SIGNAL_CURVE` in `ui/face.py`): opus 0, sonnet 0.12, haiku 0.30, tuned by eye. Sonnet baseline 0.10 to 0.13 so a `/model` switch bump (+0.05) cannot make opus look like sonnet; still STABLE and trusted. (S287) |
| v0.4 | 2026-10-28 | Capability model: per-model capability by category (general, coding, tools, recall) in an editable registry; entropy = 1 - capability/100; transient damage decays, structural damage earns partial credit from re-grounding, parking resets; bloat tracking drives the park point; trust tier read from capability (trusted >= 60, standard >= 40). (S287) |
| v0.5 (planned) | 2026-10-28 | Direction only, nothing built: entropy (model capability, shown as static) split from stability (session health and bloat, shown as glitch and breaking); capability derived from benchmarks and rescalable as models evolve. (S287) |

---

```
transcribe ~ sCoRE >> entropy tracking and self-healing crystallized // %ENTROPY_TRACKER%
```
