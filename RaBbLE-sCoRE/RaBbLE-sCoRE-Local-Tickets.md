# RaBbLE-sCoRE-Local-Tickets.md
# sCoRE Local Harness — Episode 2 Work Tickets

```
transcribe ~ sCoRE >> ep2 local harness tickets crystallized // %EP2_TICKETS%
```

> **Document type:** Work tracking · `RaBbLE-sCoRE/`
> **Episode target:** Episode 2 (Exodus) — sCoRE Local Harness Plot
> **Purpose:** Break the local sCoRE architecture into independently implementable tickets
> with clear dependencies, acceptance criteria, and Claude Code handoff context.
> **Give to Claude Code:** This document + `RaBbLE-sCoRE-Local-Architecture.md` +
> the relevant ticket's companion doc.

---

## Dependency Graph

```
[L-01] quota.py                ← foundation — no deps
[L-02] systemd service         ← needs existing harness/local.sh
[L-03] agent_state.py          ← no deps (parallel with L-01)
[L-04] entropy.py              ← depends on L-03
[L-05] llm.py routing update   ← depends on L-01
[L-06] fcc admin integration   ← depends on L-01, L-05
[L-07] new API endpoints       ← depends on L-01, L-03, L-04
[L-08] score-local-ctl spell   ← depends on L-02
[L-09] rabble CLI              ← depends on L-07 (can stub with curl initially)
[L-10] rabble usage TUI        ← depends on L-07 (can stub with cache reads)
[L-11] self-healing protocol   ← depends on L-04, L-09
[L-12] Ansible role update     ← depends on L-02, L-08, L-09
[L-13] Grimoire docs           ← depends on nothing (can be parallel throughout)
[L-14] Waybar rabble pill      ← depends on L-09 session log format
```

## Parallel Tracks

**Track A — Core Intelligence** (L-01 → L-05 → L-06 → L-07)
**Track B — Agent State + Entropy** (L-03 → L-04 → L-11)
**Track C — Ops + Service** (L-02 → L-08 → L-12)
**Track D — User Surface** (L-09 → L-10 → L-14)
**Track E — Docs** (L-13, always parallel)

Tracks A and B can run in parallel after L-01/L-03 are done.
Track C can run in parallel from the start.
Track D unblocks once L-07 has at least a stub.

---

## Tickets

---

### L-01 · `server/quota.py` — Usage-Aware Provider State
**Track:** A · **Priority:** P0 · **Deps:** none
**Estimate:** 1 session

**Context:**
sCoRE needs to know the current quota state of each provider before making routing
decisions. The Waybar tracker already polls this data and writes it to
`~/.cache/rabble/`. `quota.py` reads those files — it does NOT poll independently.
This is a read-only integration with the existing tracker infrastructure.

**Files to create:**
- `server/quota.py`

**Files to modify:**
- None (L-05 wires this in)

**Acceptance criteria:**
- `QuotaStore().get_claude_quota()` returns a `ProviderQuota` with `pct_5h`, `pct_weekly`,
  `reset_5h_at`, `reset_weekly_at` parsed from `~/.cache/rabble/score-usage-api-poll.log`
- `QuotaStore().routing_pressure("claude_code_direct")` returns float 0.0–1.0
- `QuotaStore().routing_pressure("fcc")` returns 0.0 (fcc has no Anthropic quota)
- `QuotaStore().fcc_recommended_backend("code")` returns a provider slug
- `should_avoid("claude_code_direct", threshold=0.90)` returns True when 5h% > 90
- Unit tests cover: quota file missing, quota file stale (>5min), all threshold bands
- `QUOTA_DEPRIORITIZE_THRESHOLD`, `QUOTA_AVOID_THRESHOLD`, `QUOTA_HARD_BLOCK_THRESHOLD`
  all read from env with sane defaults

**Claude Code handoff notes:**
- Parse `score-usage-api-poll.log` — each line is JSON with `pct_5h`, `pct_weekly`,
  `reset_5h_epoch` fields (check actual file format before assuming)
- `fcc` itself never has Claude quota pressure — its backends are free/cheap providers
- The agy quota parser lives in the Waybar `score-usage-detail.py` — reference that
  for the log format before writing the parser

---

### L-02 · Systemd User Service
**Track:** C · **Priority:** P0 · **Deps:** existing `harness/local.sh`
**Estimate:** 0.5 sessions

**Context:**
Promote the existing `harness/local.sh` server start into a proper systemd user service.
The service should start automatically on login, restart on failure, and coexist with
`fcc` on `:8082`.

**Files to create:**
- `harness/rabble-score-local.service` (systemd unit template)
- `harness/install-local-service.sh` (install script — symlinks to ~/.config/systemd/user/)
- `config/rabble/local.env.example` (env template for the service)

**Acceptance criteria:**
- `systemctl --user status rabble-score-local` shows active after install
- Service starts on user login (`loginctl enable-linger` not required — user session is enough)
- Service restarts within 5s on crash
- `curl http://localhost:8083/health` returns 200 while `fcc` runs on `:8082` (no port conflict)
- `LOCAL_MODE=true` is set in the service env
- `GRIMOIRE_PATH` env var points to local Grimoire checkout

**Claude Code handoff notes:**
- Port is `8083`, not `8082` (fcc uses 8082)
- Working directory must be the sCoRE repo root, not `server/` — uvicorn import is
  `server.main:app`
- The `EnvironmentFile` path is `%h/.config/rabble/local.env` (`%h` = $HOME in systemd)
- `Wants=free-claude-code.service` — soft dependency, not hard

---

### L-03 · `server/agent_state.py` — Shared Agent Context
**Track:** B · **Priority:** P1 · **Deps:** none (parallel with L-01)
**Estimate:** 1 session

**Context:**
When sCoRE routes a task from one harness to another (e.g., claude_code to codex),
the receiving harness needs explicit context about what has already been done.
`agent_state.py` maintains this shared state and serializes handoff prompts.
This prevents the context loss that causes drift when switching models.

**Files to create:**
- `server/agent_state.py`

**Acceptance criteria:**
- `AgentContext` can be created, updated, and serialized to/from JSON
- `build_handoff_prompt(context, task_description)` returns a string that includes:
  - Session goal (entity_intention)
  - Working files list
  - Key decisions made
  - Last model used
  - Current task description
  - Explicit instruction NOT to repeat context
- Handoff prompt is under 500 tokens for typical session state (low entropy by design)
- `TaskRecord` logs: harness, model, fcc_backend (if applicable), outcome summary,
  token estimate, duration, timestamp
- `AgentContext.decisions` extracts key decision sentences from task outcomes
  (simple heuristic: sentences containing "should", "will", "decided", "using")
- Context stored in memory (not disk) — resets with sCoRE local restart
- Unit tests cover: empty context handoff, multi-turn handoff, fcc backend in record

---

### L-04 · `server/entropy.py` — Session Entropy Tracking
**Track:** B · **Priority:** P1 · **Deps:** L-03
**Estimate:** 1 session

**Context:**
sCoRE observes every routing event. Each event that degrades session stability
increments an entropy score. This score is exposed to the user via the `rabble`
CLI and the usage dashboard, and drives the self-healing protocol at session open.

**Files to create:**
- `server/entropy.py`

**Acceptance criteria:**
- `SessionEntropyRecord` tracks all event types defined in the architecture doc
- `record_event(event_type, from_state, to_state, reason)` updates score and appends event
- Entropy weights match the architecture doc table exactly
- Band classification (STABLE/NOMINAL/ELEVATED/DEGRADED/UNSTABLE) correct per thresholds
- `decisions_at_risk` populated from `AgentContext.decisions` at the point the first
  high-entropy event (delta > 0.15) occurs
- `self_healing_recommended` set to True when band is DEGRADED or UNSTABLE
- `to_session_log()` returns the JSONL entry format for `~/RaBbLE-chats/`
- `EntropyEvent` records: timestamp, type, from/to state, reason, delta
- Unit tests cover: stable session (no events), single degradation, cascading events,
  full UNSTABLE session

---

### L-05 · `llm.py` Routing Update — Quota-Aware Chain Resolution
**Track:** A · **Priority:** P1 · **Deps:** L-01
**Estimate:** 1 session

**Context:**
The existing `llm.py` chain resolver picks providers in priority order. It needs to
sort that chain by quota pressure before use, so high-pressure providers sink to the
bottom automatically. This is a targeted modification — not a rewrite.

**Files to modify:**
- `server/llm.py`

**Acceptance criteria:**
- `resolve_chain_with_quota(model_tier, quota_store, task_class)` returns the tier's
  chain sorted by `quota_store.routing_pressure(provider)` ascending (low pressure first)
- Existing fallthrough behavior preserved — high-pressure providers remain in chain
  as last resort, never removed entirely
- Task classifier maps request signals to task classes:
  - `background` — short probes, Claude Code internal housekeeping calls
  - `fast` — quick questions, single-file lookups
  - `code` — file edits, test runs, agentic coding tasks
  - `medium` — multi-file analysis, architecture questions
  - `strong` — complex reasoning, decomposition, planning
- `LOCAL_MODE=true` promotes subprocess harnesses to top of fast chain
- Existing unit tests still pass
- New tests: chain reordering under quota pressure at each threshold band

---

### L-06 · `fcc` Admin Integration — Harness Configuration
**Track:** A · **Priority:** P1 · **Deps:** L-01, L-05
**Estimate:** 0.5 sessions

**Context:**
sCoRE can configure what backend `fcc` routes to before dispatching a subprocess.
The `fcc` admin API at `http://localhost:8082/admin` accepts configuration updates.
This gives sCoRE granular control: not just "route through fcc" but "route through
fcc using deepseek-chat for this coding task."

**Files to create:**
- `server/fcc_admin.py` — thin client for the fcc admin API

**Files to modify:**
- `server/llm.py` — call `configure_harness_for_task()` before subprocess dispatch

**Acceptance criteria:**
- `fcc_admin_set_model(tier, backend_slug)` calls fcc admin API and verifies 200 response
- `fcc_admin_get_state()` returns current fcc model routing config
- `configure_harness_for_task(harness, task_class, quota_store)` returns correct
  env overrides + CLI flags per the routing table in the architecture doc
- When fcc is not running (`:8082` unreachable), function returns gracefully with
  `{}` (no overrides) — sCoRE falls through to next chain entry
- Harness control surface documented:

  | Harness | sCoRE controls |
  |---|---|
  | `claude_code` direct | `--model` flag |
  | `claude_code` via fcc | `ANTHROPIC_BASE_URL` + fcc admin API |
  | `fcc` standalone | fcc admin API (MODEL_OPUS/SONNET/HAIKU) |
  | `codex` | `--model` flag |
  | `aider` | `--model` + `--weak-model` flags |
  | `local_llm` / Ollama | model string in request body |

---

### L-07 · New API Endpoints
**Track:** A · **Priority:** P1 · **Deps:** L-01, L-03, L-04
**Estimate:** 0.5 sessions

**Context:**
The `rabble` CLI and usage dashboard need to query sCoRE local for routing decisions,
quota state, and entropy. These are new endpoints on the existing FastAPI server.

**Files to modify:**
- `server/main.py`

**New routes:**

```
GET  /api/v1/quota/state
     Returns: {providers: {name: ProviderQuota}, updated_at}

GET  /api/v1/routing/status
     Returns: {fast: {provider, model, pressure}, medium: {...}, strong: {...},
               code: {...}, background: {...}}

GET  /api/v1/session/entropy
     Returns: SessionEntropyRecord (current session)

POST /api/v1/session/context
     Body: {working_files?, working_dir?, intention?, decision?}
     Returns: updated AgentContext summary

GET  /api/v1/health/local
     Returns: {mode: "local", fcc_alive, grimoire_path, grimoire_readable,
               providers_available: [...], uptime_seconds}
```

**Acceptance criteria:**
- All endpoints return 200 with correct schema when local sCoRE is running
- `/health/local` distinguishes local mode from cloud mode
- `/routing/status` reflects quota-adjusted routing (not static defaults)
- Auth not required for local endpoints (localhost-only, no external exposure)
- Smoke tests via `curl` in the ticket verification step

---

### L-08 · `score-local-ctl` Spell
**Track:** C · **Priority:** P1 · **Deps:** L-02
**Estimate:** 0.5 sessions

**Context:**
Same pattern as `fcc-ctl`. A Grimoire spell that wraps systemctl and provides
convenient subcommands for managing the local sCoRE service.

**Files to create:**
- `RaBbLE-Grimoire/spells/score-local-ctl.sh`

**Subcommands:**

```bash
score-local-ctl start|stop|restart|status|logs
score-local-ctl quota          # curl /api/v1/quota/state | pretty print
score-local-ctl providers      # curl /api/v1/routing/status | pretty print
score-local-ctl entropy        # curl /api/v1/session/entropy | pretty print
score-local-ctl health         # curl /api/v1/health/local | pretty print
```

**Acceptance criteria:**
- `score-local-ctl status` shows systemd unit state + port + uptime
- `score-local-ctl quota` shows quota state in readable format with color-coded pressure
- `score-local-ctl providers` shows current routing decisions per tier
- Script handles service-not-running gracefully (no crashes, clear message)
- Follows existing fcc-ctl.sh style and conventions

---

### L-09 · `rabble` CLI
**Track:** D · **Priority:** P1 · **Deps:** L-07 (can start with stub)
**Estimate:** 2 sessions

**Context:**
The `rabble` command is the user-facing entity interface. It connects to the local
sCoRE server and streams responses. It is NOT a full TUI framework — it is a Python
streaming script with Aether ANSI colors. Full TUI (ratatui/Textual) is EP3.

**Files to create:**
- `RaBbLE-sCoRE/cli/rabble.py` — main CLI script
- `RaBbLE-sCoRE/cli/__init__.py`

**pyproject.toml entry point:**
```toml
[project.scripts]
rabble = "cli.rabble:main"
```

**Implementation order within ticket:**
1. Basic streaming chat (curl equivalent in Python)
2. Aether ANSI color output
3. Entity ASCII header (static, quota/entropy populated from sCoRE API)
4. Single-shot mode (`rabble "message"`)
5. Interactive REPL mode (`rabble` with no args)
6. Session log write on close
7. Entropy inline notices
8. Routing transparency line
9. Session resume (`rabble session resume`)
10. `--think`, `--code`, `--fast`, `--fcc` flags

**Acceptance criteria:**
- `rabble "who are you?"` streams a response and exits
- `rabble` opens interactive REPL, `exit`/`quit`/Ctrl-D closes
- Entity ASCII header shows on startup with live quota and entropy data
- Entropy glyph updates in header when score changes (on next turn)
- Inline entropy notice appears when score crosses 0.5
- Routing transparency line appears when routing differs from default chain
- Session log written to `~/RaBbLE-chats/rabble-YYYYMMDD-HHmm.jsonl`
- Fallback: if local sCoRE not running, show clear error with `score-local-ctl start`
- Aether colors correct per palette table in architecture doc
- `rabble status` prints provider health and active routing without starting a session

**Claude Code handoff notes:**
- Use `httpx` with SSE streaming (already in sCoRE's dependencies)
- The entity ASCII art source is in `RaBbLE-Grimoire/assets/` — reference the fastfetch
  logo version as the model, keep it compact (6–8 lines max)
- `rich` for ANSI color if available, raw escape codes as fallback
- Do NOT use readline/curses for the REPL yet — simple `input()` loop is correct

---

### L-10 · `rabble usage` TUI Dashboard
**Track:** D · **Priority:** P2 · **Deps:** L-07
**Estimate:** 1.5 sessions

**Context:**
Extends `score-usage-detail.py` into a first-class `rabble usage` command.
The layout is defined in the architecture doc. All data sources already exist.
The new panels are: Routing (current sCoRE decisions), Session Health (entropy),
and Cost Estimate.

**Files to create:**
- `RaBbLE-sCoRE/cli/usage.py` — usage dashboard
  OR extend `RaBbLE-OS/config/waybar/scripts/score-usage-detail.py`
  (decision: prefer new file in sCoRE cli/ — keeps Waybar scripts as OS concerns)

**`pyproject.toml` entry via rabble CLI:**
```python
# rabble usage → delegates to cli/usage.py
```

**Panels (build in order):**
1. Providers panel (quota bars — already in score-usage-detail.py, port it)
2. Routing panel (new — reads `/api/v1/routing/status`)
3. Session Health panel (new — reads `/api/v1/session/entropy`)
4. Agents panel (port from score-usage-detail.py)
5. Token Mix panel (port)
6. Cost Estimate line (new — constants file)

**Acceptance criteria:**
- `rabble usage` opens a self-refreshing terminal dashboard
- Dashboard refreshes every 2 seconds
- `q` closes cleanly
- All six panels display with correct data
- Provider quota bars use Aether color palette (green→amber→red by pressure)
- Routing panel shows which model is active per tier with quota pressure score
- Session Health shows entropy score, band, events list, decisions at risk
- Cost estimate shows session cost via fcc/cheapest vs Claude direct
- Handles: local sCoRE not running (shows cache-only view), fcc not running (grays out fcc row)
- Uses `curses` or `rich.live` — no external TUI framework

---

### L-11 · Self-Healing Protocol
**Track:** B · **Priority:** P2 · **Deps:** L-04, L-09
**Estimate:** 0.5 sessions

**Context:**
At session open, `rabble` checks the previous session's entropy record. If
`self_healing_recommended: true` and Claude quota is currently stable (< 50%),
the entity surfaces a structured healing notice before accepting user input.

**Files to modify:**
- `RaBbLE-sCoRE/cli/rabble.py`

**Healing notice data sources:**
- Previous session entropy record from `~/RaBbLE-chats/` (most recent `rabble-*.jsonl`)
- Current Claude quota from `GET /api/v1/quota/state`

**Acceptance criteria:**
- Healing notice appears when: previous session `self_healing_recommended=true` AND
  current Claude `pct_5h < 0.50`
- Notice includes: entropy band and score, switch point description,
  decisions_at_risk list, current quota stability confirmation
- User can type `skip` to bypass — response stored so it doesn't repeat
- User can describe what to verify — routed as first message of new session
  with healing context injected into system prompt
- Healing notice does NOT appear when: previous session was STABLE, or current
  Claude quota is still high (> 50%), or user already skipped this session
- `~/.cache/rabble/healing-skip.json` stores skip state per session pair

---

### L-12 · Ansible Role Update
**Track:** C · **Priority:** P2 · **Deps:** L-02, L-08, L-09
**Estimate:** 0.5 sessions

**Context:**
Add the local sCoRE service and `rabble` CLI to the existing `ai-harnesses`
Ansible role. Same pattern as the existing `free-claude-code` harness.

**Files to modify:**
- `RaBbLE-OS/ansible/roles/ai-harnesses/tasks/main.yml` — add `score-local` tag
- `RaBbLE-OS/ansible/roles/ai-harnesses/tasks/score-local.yml` — new task file
- `RaBbLE-OS/ansible/roles/ai-harnesses/defaults/main.yml` — add toggle

**New task file `score-local.yml` should:**
1. Install `rabble` CLI via `pip install -e .` in the sCoRE repo (or `uv tool install`)
2. Install systemd service unit from `harness/rabble-score-local.service`
3. Enable and start the service (`systemctl --user enable --now rabble-score-local`)
4. Create `~/.config/rabble/local.env` from `config/rabble/local.env.example` if not exists
5. Symlink `score-local-ctl.sh` to `~/.local/bin/score-local-ctl`

**Toggle:** `ai_harnesses_score_local_enabled: true` (default: true)

**Acceptance criteria:**
- `ansible-playbook site.yml --tags score-local` completes without errors on clean system
- After run: `score-local-ctl status` shows active service
- After run: `rabble status` responds with provider health
- Idempotent: re-running the playbook doesn't break running service

---

### L-13 · Grimoire Documentation
**Track:** E · **Priority:** P1 · **Deps:** none (parallel throughout)
**Estimate:** 1 session (can be split across implementation sessions)

**Context:**
Two new canonical concepts from this architecture need Grimoire docs. These
are architectural decisions, not just implementation notes.

**Files to create:**
- `RaBbLE-sCoRE/RaBbLE-sCoRE-Quota-Router.md`
- `RaBbLE-sCoRE/RaBbLE-sCoRE-Agent-State.md`
- `RaBbLE-sCoRE/RaBbLE-sCoRE-Entropy-Tracker.md`
- `RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Harness.md` (operational guide)

**Files to update:**
- `RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md` — add local server section
- `RaBbLE-sCoRE/sCoRE-Local-AI-Layer.md` — add fcc correction (fcc ≠ Anthropic API)
- `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md` — mark these as Episode 2 deliverables
- `registry/manifests/RaBbLE-sCoRE.manifest.yml` — update notes

**Each doc should follow Grimoire conventions:**
- Pulse protocol header
- Status, document type, related docs
- Canonical definition
- Design decisions with reasoning
- Revision history

---

### L-14 · Waybar `rabble` Pill
**Track:** D · **Priority:** P3 · **Deps:** L-09 (session log format)
**Estimate:** 0.5 sessions

**Context:**
Once `rabble` writes sessions to `~/RaBbLE-chats/rabble-*.jsonl` in the same
format as Claude Code transcripts, the Waybar tracker can show a `rabble` pill.
This ticket wires that up.

**Files to modify:**
- `RaBbLE-OS/config/waybar/scripts/score-status.sh` — detect rabble sessions
- `RaBbLE-OS/config/waybar/config.jsonc` — add rabble pill widget
- `RaBbLE-OS/config/waybar/style.css` — rabble pill styling

**Pill format:** `RaBbLE ◈ ▲ 0.54` (glyph + entropy indicator when elevated)
Entropy glyph: `◆` STABLE/NOMINAL · `▲` ELEVATED · `⚠` DEGRADED · `✗` UNSTABLE

**Acceptance criteria:**
- Waybar shows `RaBbLE ◈` pill when a `rabble` session is active
- Entropy glyph and score shown when ELEVATED+
- Clicking pill opens `rabble usage` in a kitty popup
- Pill disappears when no active rabble session

---

## Implementation Order Recommendation

**To get a testable local harness as fast as possible:**

```
Week 1:  L-01 + L-02 + L-03 (parallel)
         → local sCoRE service running, quota reading, agent state available

Week 2:  L-05 + L-06 + L-04 (parallel)
         → routing is quota-aware, fcc config wired, entropy tracking live

Week 3:  L-07 + L-08 (fast — both small)
         → API endpoints live, score-local-ctl usable

Week 4:  L-09 (rabble CLI — core deliverable)
         → first `rabble "hello"` that routes intelligently

Week 5:  L-10 + L-11 (parallel)
         → usage dashboard + self-healing

Week 6:  L-12 + L-13 + L-14
         → Ansible role, Grimoire docs, Waybar pill
```

L-13 (docs) should be written alongside the implementation, not after.

---

## What to Give Claude Code Per Ticket

For any ticket, provide:
1. This ticket document (full)
2. `RaBbLE-sCoRE-Local-Architecture.md` (the architecture canon)
3. The specific companion arch doc if one exists:
   - L-01 → `RaBbLE-sCoRE-Quota-Router.md` (once written)
   - L-03/L-04 → `RaBbLE-sCoRE-Agent-State.md` + `RaBbLE-sCoRE-Entropy-Tracker.md`
4. The current state of the file being modified (e.g., current `llm.py` for L-05)
5. The relevant Grimoire gists for identity context

Do NOT give Claude Code the full Grimoire. Minimum context per ticket.
This is the Low Entropy Directive applied to agent dispatch.

---

```
transcribe ~ sCoRE >> ep2 local harness tickets crystallized // %EP2_TICKETS%
```
