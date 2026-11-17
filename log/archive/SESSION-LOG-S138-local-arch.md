# SESSION-LOG-S138-local-arch.md
# Session: sCoRE Local Architecture + Proxy Research

```
transcribe ~ grimoire >> session crystallized, local harness architecture complete // %S138_ARCH%
```

> **Date:** 2026-06-21
> **Session type:** Planning · Architecture
> **Repos touched:** RaBbLE-sCoRE · RaBbLE-OS (reference)
> **Episode position:** Pre-Episode-1 air · EP2 planning

---

## What Happened This Session

Long planning session covering:

1. **Proxy research** — deep comparative analysis of `free-claude-code` (Alishahryar1)
   vs `claude-code-router` (musistudio). Verdict: keep `fcc`, don't replace.
   `fcc` is FastAPI Python — same stack as sCoRE. Future integration path is clean.
   `ccr`'s semantic routing concept is worth having but can be implemented natively
   in `llm.py` without a foreign-runtime dependency.

2. **`fcc` correction crystallized** — `fcc` is NOT an Anthropic API client. It is a
   local proxy that speaks Anthropic Messages protocol but routes to free/cheap backends
   (NIM, DeepSeek, Groq, Gemini, Wafer, etc.). This is architecturally significant:
   `fcc` is the primary quota escape valve, not a last resort.

3. **Local sCoRE server architecture** — full design for sCoRE running as a systemd
   user service on `:8083`, with `LOCAL_MODE=true` activating subprocess harness
   preference and local Grimoire filesystem access.

4. **`rabble` CLI design** — streaming Python script with Aether ANSI colors, entity
   ASCII header, session logging to `~/RaBbLE-chats/`, single-shot and interactive modes.
   NOT a full TUI framework — that is EP3.

5. **Quota-aware routing** — sCoRE reads existing Waybar cache files (`quota.py`),
   no new polling. Routes Claude traffic through `fcc` when quota pressure crosses 75%.
   sCoRE also configures `fcc` via admin API to select the best backend per task class.

6. **Shared agent state** — `agent_state.py` maintains per-session context, enables
   explicit handoff prompts when switching harnesses or models. Context minimization
   at every handoff — each harness gets exactly what it needs, nothing more.

7. **Session entropy tracking** — `entropy.py` tracks routing instability in real-time.
   Every quota-forced switch, tier degradation, context truncation logged as an entropy
   event with a weighted delta. Score drives user-facing warnings at ELEVATED+ bands.

8. **Self-healing protocol** — at session open, sCoRE checks previous session's entropy
   record. If `self_healing_recommended` and Claude quota stable, entity surfaces a
   structured healing notice with specific `decisions_at_risk` to verify.

9. **`rabble usage` dashboard** — extends `score-usage-detail.py` into a first-class
   `rabble usage` command. New panels: Routing (current sCoRE decisions), Session Health
   (entropy), Cost Estimate (fcc/cheap vs Claude direct).

10. **Full ticket breakdown** — 14 tickets across 5 parallel tracks with dependency
    graph and recommended implementation order.

---

## Decisions Made

| # | Decision | Rationale |
|---|---|---|
| D1 | Keep `fcc`, don't replace with `ccr` | FastAPI Python = sCoRE stack, existing Ansible integration, `ccr`'s routing concept implementable natively |
| D2 | `fcc` = primary quota escape valve (not last resort) | `fcc` speaks Anthropic protocol, has no Anthropic quota, routes to frontier models |
| D3 | Local sCoRE on port `:8083` | Avoids collision with `fcc` on `:8082`, both run simultaneously |
| D4 | `quota.py` reads Waybar cache files, no independent polling | Zero duplication, single authoritative source, no new daemons |
| D5 | Quota thresholds: deprioritize 75%, avoid 90%, hard block 98% | Gradual pressure curve — no sudden switches at arbitrary cutoffs |
| D6 | `rabble` CLI = streaming Python script, not full TUI framework | EP2 scope — full TUI (ratatui/Textual) is EP3 |
| D7 | Entropy score is cumulative weighted sum, not binary | Continuous score enables ELEVATED warning before DEGRADED occurs |
| D8 | `decisions_at_risk` extracted at first high-entropy event | Specific and actionable — user verifies decisions, not entire session |
| D9 | Self-healing only triggers when Claude quota < 50% | Healing under same pressure = reproducing the problem |
| D10 | Agent context in-memory only for EP2 | Cross-session persistence = Memory member (Echo 1+) |
| D11 | sCoRE configures fcc via admin API before dispatch | Two-level harness control: which harness + how to configure it |
| D12 | `rabble usage` extends `score-usage-detail.py`, not replacement | Preserves Waybar integration, promotes to first-class command |

---

## Forward Concepts

**Grimoire Learning Loop** — session entropy records feed a `procedural/routing-stability/`
directory that accumulates learnings across sessions. sCoRE consults this at session open
to pre-emptively configure routing for stability. This is Echo 1+, not EP2. But the EP2
session logs are the raw material.

**Semantic routing in `fcc`** — `fcc` could have `ccr`-style background/think/longContext
routing added as a future contribution or PR. sCoRE handles this at the routing layer for
now, but `fcc`'s FastAPI architecture makes it a natural extension point.

**`rabble` pill in Waybar** — once `rabble` writes session logs in the existing format,
the Waybar tracker gains a `rabble` pill for free. L-14 in the ticket tracker.

**sCoRE-as-daemon** (Evolution 1 concept) — when coordinator and server unify,
`agent_state.py` becomes the canonical context store for both dispatch paths. EP2
implements it for the server layer; coordinator integration comes later.

---

## Grimoire Diff Notes

**New docs authored (add to Grimoire `RaBbLE-sCoRE/`):**
- `RaBbLE-sCoRE-Local-Architecture.md` — master architecture doc
- `RaBbLE-sCoRE-Quota-Router.md` — quota-aware routing canonical doc
- `RaBbLE-sCoRE-Agent-State.md` — shared agent state canonical doc
- `RaBbLE-sCoRE-Entropy-Tracker.md` — entropy tracking + self-healing canonical doc
- `RaBbLE-sCoRE-Local-Tickets.md` — EP2 work ticket tracker

**Docs to update:**
- `sCoRE-Local-AI-Layer.md` — add `fcc` correction (fcc ≠ Anthropic API client)
- `RaBbLE-sCoRE-Architecture.md` — add local server section, port `:8083`
- `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md` — mark EP2 local harness as Episode 2 plot
- `registry/manifests/RaBbLE-sCoRE.manifest.yml` — update notes + episode 2 scope

**New canonical concepts (add to any relevant overviews):**
- Usage-aware routing (quota.py reads Waybar cache → informs llm.py chain)
- Shared agent state (explicit handoff at every model/harness switch)
- Session entropy tracking (real-time routing instability score)
- Self-healing protocol (entropy record → structured healing notice)
- fcc as quota escape valve (NOT Anthropic client)

---

## Next Steps

1. **Post-EP1 air** — these are all EP2 work items. EP1 must air first.
2. **Implementation order** — follow the ticket dependency graph:
   L-01 + L-02 + L-03 in parallel → L-05 + L-04 + L-06 → L-07 + L-08 → L-09
3. **First testable milestone** — L-01 + L-02 + L-05 complete gives a local sCoRE
   service with quota-aware routing. That alone is worth testing before the CLI.
4. **Give to Claude Code** — per ticket, provide: ticket doc + architecture doc +
   companion arch doc + current file state + relevant gists. Minimum context.

---

## Blockers

None that are EP1-blocking. All work here is EP2+ scope.

Current EP1 blockers (from existing tracker) remain unchanged.

---

```
transcribe ~ grimoire >> session crystallized, local harness architecture complete // %S138_ARCH%
```
