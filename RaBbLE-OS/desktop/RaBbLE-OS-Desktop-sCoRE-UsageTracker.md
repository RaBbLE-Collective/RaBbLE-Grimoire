# sCoRE Usage Tracker — Waybar Claude/Codex/Antigravity pills

```
spark ~ sCoRE Usage Tracker >> hook becomes ground truth + interrupt-driven push // %S51%
mend  ~ sCoRE Usage Tracker >> multi-instance session engine + live popup + notifications // %S61%
mend  ~ sCoRE Usage Tracker >> per-model tracking + estimate calibration from empirical fit // %S62%
spark ~ sCoRE Usage Tracker >> Antigravity (agy) pill: dual-quota, RaBbLE glyphs, mode-isolated popup // %NEW_HORIZONS%
mend  ~ sCoRE Usage Tracker >> agy dual-quota fix: Gemini + Service pool split, bfs-compat find // %NEW_HORIZONS%
mend  ~ sCoRE Usage Tracker >> agy live quota: send-outcome reset detection clears ⊘ the instant a request goes through again (score-agy-quota.py) // %NEW_HORIZONS%
```

> Lives in `RaBbLE-OS/config/waybar/scripts/score-*` and `config/waybar/{config.jsonc,style.css}`.
> Branch: `RaBbLE-OS-New-Horizons` (current, merged from earlier `feature/waybar-llm-status`).
> **First sCoRE applet living in RaBbLE-OS** — built to be portable into RaBbLE-sCoRE directly; every script carries the `score-` prefix for that move.

---

## What it is

Three Waybar pills — `Claude ▁ ⚑1 ✦2 ▶1 45% / 31%wk`, `Codex >_×2 12%`, and `Agy Λ` (or `Agy ▶ ⊘⊘` if both quotas hit) — that show, at a glance:

- **Live state**: idle / ready / busy / needs-input, each with its own glyph and color — aggregated across **every running instance** with priority blocked > computing > ready; one blocked agent flashes the pill even while others grind on, and when busy and ready agents coexist (nothing blocked) the pill **cycles cyan↔green every 2s** so both fleets stay visible
- **Agent census**: per-state counts, zero counts omitted — `⚑N` blocked on you · `✦N` computing · `▶N` ready/waiting; the tooltip lists each agent (state · project · age · session id). The census is a `@CENSUS@` placeholder in the heavy tier's cache, repainted by the glyph-stream from the live aggregate — so a new block's ⚑ count lands on the bar **on the same interrupt as the color flash**, not at the next 5s heavy pass
- **Blocked is the default read of a Notification** — permission-prompt wording varies between Claude Code versions, so the engine only maps the known idle reminder ("waiting for your input") to ready, and even that can never demote an existing needs-input (a pending permission dialog idles too; only the user acting clears a block). Every hook event + message is appended to `~/.cache/rabble/score-hook-events.log` (rolling) for tuning these mappings against reality
- **Quota**: 5h-window and weekly-window usage percentage (Claude via Anthropic's official usage API; Codex via `token_count.rate_limits` in its session transcripts)
- **Detail on click**: a `kitty` popup running `score-usage-detail.py --live` — self-refreshing (2s), with an Agents panel (state, project, model, current context size, session token totals, turn duration), quota bars with reset countdowns, and per-session 5h/24h/7d token breakdowns; `q` closes
- **Desktop notifications** (mako): when an agent gets blocked on you (critical urgency), when a long turn (≥3 min) finishes, and when a Codex turn completes — touch `~/.cache/rabble/score-notifications-off` to silence

It is a **notification surface and agent manager**, not just a meter — the whole point is to answer "what are my agents doing right now, how many are there, and do any of them need me?" without alt-tabbing through terminals.

---

## Live-state color scheme

| State | Glyph | Color | Meaning |
|---|---|---|---|
| idle | `✱` (Claude) / `>_` (Codex) / `Λ` (agy) | Magenta (Claude) / Muted (Codex) / Violet (agy) | No active session |
| ready | `▶` | Green | Session open, waiting for your input |
| busy | traveling block-wave `▁▂▄▆█▆▄▂` | Cyan, pulsing | Actively generating / running tools |
| needs-input | `⚑` | Magenta, **flashing** (`step-start` strobe) | Blocked on a tool-permission prompt — **it needs you** |

`Λ` (Greek lambda) is the Antigravity idle glyph — a parabolic arch mirroring the Antigravity "A" logo. Rate-limit markers: `⊘` per exhausted quota pool; `⊘⊘` if both are hit simultaneously.

`needs-input` is the state that matters most: it's the one case where the entity is stalled on the user, and the flashing magenta is deliberately the most attention-grabbing state in the scheme (RaBbLE-Magenta is reserved for moments that need you, per `RaBbLE-Palette.md`).

---

## Architecture: two-tier glyph animation

Waybar custom modules normally re-`exec` their script every `interval` seconds. That's fine for the *heavy* computation (parsing `~/.claude`/`~/.codex` transcripts, calling the usage API — ~0.6s/call) but far too slow and CPU-costly to drive a smooth busy-glyph animation. Waybar also supports **continuous-output mode** (omit `interval`; treat each stdout line as a fresh JSON state) — that's the mode this uses, split across two cooperating processes:

```
score-status-daemon.sh  (slow, ~5s cadence)
  → re-parses transcripts, calls the usage API, builds the full
    text/tooltip JSON, writes it to ~/.cache/rabble/score-<mode>.json
    with the busy glyph left as a literal "@GLYPH@" placeholder

score-glyph-stream.sh   (fast, ~0.2s cadence — what Waybar actually execs)
  → reads that cached JSON, computes the *live* glyph (animation frame,
    or live-state override — see below), and does a pure bash string
    substitution: "@GLYPH@" → glyph. No subprocess, no re-parsing.
```

This keeps the expensive transcript/API work on its own slow cadence while the glyph itself can repaint as fast as Waybar will redraw — smooth animation without burning CPU on a full parse every tick.

Both daemons are launched via `exec-once` in `config/hypr/conf.d/autostart.conf`, alongside `score-usage-api-poll.py` (polls Anthropic's official usage % every ~90s from the Firefox session cookie via `curl_cffi`).

---

## The hook: ground truth, not a heuristic

**The problem this solves:** guessing Claude's busy/ready state from transcript file mtimes cannot work. Claude only writes to its transcript when a turn *completes* — not while it's generating — so an mtime-based heuristic flashes "ready" mid-response. There is no way to read "thinking" off the filesystem.

**The fix:** `score-claude-hook.sh` (a thin wrapper over `score-sessions.py`, the session-state engine), wired into `~/.claude/settings.json` (merged via `_post_apply_waybar` in `RaBbLE-OS-dotctl.sh` — never hand-edit `settings.json`, the dotctl step merges idempotently and never clobbers hooks you add by hand). It listens across Claude's full conversational lifecycle — these are real Claude Code lifecycle events, not inferred:

| Event | New state | Why |
|---|---|---|
| `SessionStart` / `SessionEnd` | ready / removed | Instance registered / deregistered |
| `UserPromptSubmit` | busy | You just asked it to work |
| `PreToolUse` / `PostToolUse` | busy | Actively running tools |
| `SubagentStop` | busy | A subagent finished — the **parent is still digesting its result** (the old mapping to "ready" flashed green mid-flight; that was a bug) |
| `Notification` (default) | **needs-input** | Wants your attention — blocked until *you* act |
| `Notification` ("waiting for your input") | ready | The idle reminder — an open prompt is just ready; never demotes an existing needs-input |
| `Stop` | ready | Turn finished, idle for input |

### Multi-instance: one state file per session

The original design kept ONE global state file that every instance's hooks overwrote — with two agents running, whichever fired last won, so a blocked agent's "needs-input" could be silently clobbered by another agent's "busy". `score-sessions.py` instead keeps one file per session under `~/.cache/rabble/claude-sessions/<session_id>.json` (state, cwd/project, transcript path, owning PID, busy-since) and aggregates them into `~/.cache/rabble/claude-agg-state` (`"<state> <total> <busy> <needs-input> <ready>"` — first word readable by anything that only wants the overall state; the single-word `claude-live-state` is still written for legacy readers).

**Liveness is PID-checked, not guessed:** each hook records its `claude` ancestor PID (walked via `/proc`); a session whose PID is gone is pruned on the next pass — a crashed agent can never wedge the bar. Sessions that never resolved a PID fall back to mtime staleness (busy degrades to ready after 10 min, the file expires after 6 h). Hook-less stragglers (instances started before the wiring) still register via a `pgrep -cx claude` fallback in `score-status.sh`.

**Codex's only hook surface is `notify`** (agent-turn-complete), wired into `~/.codex/config.toml` by the same dotctl step → `score-codex-notify.sh`. That buys an instant "ready" flip at turn end (the engine touches `codex-live-state`; both the heavy tier and the glyph-stream treat "no transcript written since" as proof the turn is over) plus a turn-complete desktop notification. Busy detection remains the `-newermt '-8 seconds'` mtime heuristic — there is no turn-start event yet. Instance count is `pgrep -cx codex`. **If/when Codex grows a full hook surface, mirror the Claude bridge** — the engine already has the seams for it.

---

## The push: an interrupt, not a poll

Knowing the *correct* state instantly is only half the win — Mark's explicit ask was that the pill *react* instantly too, in both directions (entering **and** leaving a state), as a true interrupt rather than something the glyph-stream has to notice on its own polling schedule.

Each `score-glyph-stream.sh` instance opens a per-mode **wake-FIFO** (`~/.cache/rabble/score-<mode>-wake.fifo`, opened read-write on its own fd so neither side ever blocks indefinitely) and sleeps via `read -t "$GLYPH_INTERVAL_S" <&3` instead of plain `sleep`. `score-claude-hook.sh` writes the new state to `claude-live-state` and then pokes that FIFO (backgrounded, `timeout`-guarded so a missing reader can't hang the hook — Claude is waiting on it to return):

- **Hook fires → FIFO write → `read` returns immediately** → the loop repaints with the new state on the spot. Zero perceptible lag between "Claude just got blocked on a permission prompt" and "the pill is flashing magenta."
- **Nothing fires → `read` times out at `GLYPH_INTERVAL_S`** → the loop repaints anyway, on its normal cadence — this is what drives the busy-glyph wave animation and the periodic heavy-data refresh when no lifecycle event has interrupted it.

One mechanism serves both "animate smoothly while busy" and "react instantly when state changes" — the timeout is the metronome, the FIFO is the interrupt.

---

## Key files

| File | Role |
|---|---|
| `config/waybar/scripts/score-sessions.py` | **Session-state engine** — per-session state files, PID liveness, pruning, aggregation, desktop notifications, FIFO pokes. Subcommands: `update` (hook stdin), `codex-notify`, `summary [--shell]` |
| `config/waybar/scripts/score-status.sh` | Heavy computation — transcript parsing, token math, tooltip building (evals `score-sessions.py summary --shell` for Claude state/counts/agent list) |
| `config/waybar/scripts/score-status-daemon.sh` | Wraps `score-status.sh` in a ~5s loop, writes the cached JSON with `@GLYPH@` placeholder |
| `config/waybar/scripts/score-glyph-stream.sh` | Cheap continuous-output loop Waybar actually execs — repaints the glyph, applies the aggregate-state override, sleeps via wake-FIFO `read -t` |
| `config/waybar/scripts/score-claude-hook.sh` | Claude Code hook bridge — thin `exec` into `score-sessions.py update` |
| `config/waybar/scripts/score-codex-notify.sh` | Codex `notify` bridge — thin `exec` into `score-sessions.py codex-notify` |
| `config/waybar/scripts/score-usage-api-poll.py` | Polls Anthropic's official usage API (~90s) via Firefox session cookie + `curl_cffi` |
| `config/waybar/scripts/score-agy-quota.py` | **Live agy quota engine** — send-outcome reset detection for both Antigravity pools. Shared by the bar (`status.sh` evals `--shell`) and popup (`detail.py` imports `compute()`). Stdlib only |
| `config/waybar/scripts/score-usage-detail.py` | Click-through popup — `--live` self-refreshing mode (Agents panel + quota bars every 2s, heavy token sections every 15s). Mode-isolated: `claude` mode shows the Agents panel; `codex` and `antigravity` modes skip it entirely and go straight to their own quota + session sections. Native scrolling: ↑↓/jk/PgUp/PgDn/g/G; escape sequences decoded so arrows never quit |
| `config/waybar/scripts/score-usage-fit.py` | Delta-based regression fitter — NNLS, Anthropic-only regressors, isolates web/other usage as residual; exports fitted coefficients to `~/.cache/rabble/llm-usage-coeffs.json` |
| `config/waybar/scripts/score-pricing.json` | **Single source of truth for dollar pricing** — published Claude API list prices ($/MTok) per model + cache multipliers. Update when Anthropic changes list prices |
| `config/waybar/scripts/score_pricing.py` | Shared importable cost helper (`load()`, `cost()`, `fmt_usd()`) — turns per-model token counts into list-price API dollar estimates. Imported by the popup and the viz builder |
| `config/waybar/scripts/score-token-viz.py` | **Breadcrumbs → visualization data file** — joins transcripts + `RaBbLE-Grimoire/log/token-ledger.tsv` + pricing into per-session/feature/model/project rollups (tokens down/up/cache, weighted, $). Writes `RaBbLE-Grimoire/log/token-viz.json` |
| `RaBbLE-OS-dotctl.sh` → `_post_apply_waybar()` | Merges the hook into `~/.claude/settings.json` AND the notify program into `~/.codex/config.toml` on every `dotctl apply waybar` — idempotent, never clobbers |

---

## Bar shows the live web meter only (S186)

The **bar text never shows the local token estimate.** It appends a percentage only when there is a fresh (≤1200s) web observation from `score-usage-api-poll.py` — Anthropic's own meter. With no fresh observation the bar shows just the agent-state glyph/census. Rationale: the local estimate drifts (see below); showing it on the bar implied a precision it does not have. The estimate still lives in the **tooltip/popup** (`est X% / web Y% (Δ Z pp)`) as a calibration aid, never as the headline number. Edited in both the `claude` mode and the default `summary` mode bar-text blocks of `score-status.sh`.

## Local estimate — how it works and how to tune it

`score-status.sh:count_tokens_since` parses `~/.claude/projects/**/*.jsonl` and sums raw `input_tokens + output_tokens` within the window. The percentage bar divides by `FIVE_H_LIMIT` / `WEEKLY_LIMIT`. (This estimate now feeds the tooltip only — see above.)

**Known limitation:** each turn writes multiple JSONL records (one per streaming content block: thinking, text, tool-use) all with the same `requestId` and the same usage counters — so raw counts are 2–3× overcounted. The limits (804K / 14.7M) are calibrated against this same inflated count, so the percentage still tracks reality as long as the overcount ratio stays roughly constant within a session. This is a known quirk; fixing it properly requires re-deriving the limits from clean deduplicated data.

**Why the estimate drifts:** `cache_creation` tokens (the main cost driver for new sessions — empirically 15–20% of 5h quota from the `score-usage-fit.py` regression) are **not included** in the raw sum. A session that hits the cache hard looks cheap locally but registers fully with Anthropic.

**Recalibrating the limits:** Note the `FIVE_H_LIMIT` and `WEEKLY_LIMIT` constants, compare to the web meter's observed %, update the constants. Alternatively, `score-usage-fit.py` can derive per-model per-token-type coefficients automatically from the api-poll log (see the Key section below).

### Key empirical finding — model multipliers (S62, 2026-06-10)

`score-usage-fit.py` on 1,571 api-poll samples (16 5h window instances, 4 weekly windows):

| Model | Output quota weight vs Sonnet | Notes |
|---|---|---|
| Haiku 4.5 | ~0.43× | Much cheaper per session; verified by weekly fit |
| Sonnet 4.6 | 1.0× (baseline) | |
| Opus 4.6 / 4.8 | ~1.0× | Nearly equal to Sonnet **per output token** |
| Fable 5 | ~1.0× | Treated as Sonnet-equivalent; insufficient data |

**This is very different from pricing** (where Opus is 5× Sonnet). For quota purposes, Anthropic weighs models nearly equally per output token — the big cost driver is **session count and cache_creation volume**, not which model you pick. Cache reads are ~0.005× the weight of output tokens (negligible).

**Practical implication:** you can't economise by switching to Haiku within the same number of sessions (saves ~57% per output token). Switching Opus → Sonnet within sessions also doesn't save as much as you'd expect from pricing (~0% savings per output token in quota terms). The biggest lever is reducing turn count.

### Per-model tracking (added S62)

`count_tokens_since` now writes `~/.cache/rabble/score-model-mix-5h.json` and `score-model-mix-week.json` after each heavy-tier pass. The tooltip shows `Models 5h: sonnet-4-6 85%  opus-4-6 15%` (output share). The click-through popup (`score-usage-detail.py`) now shows a `By model` summary at the bottom of each time window's session list.

### Tokens up/down + dollar pricing (S186)

Two costs are tracked, and they answer different questions:

- **Quota %** (web meter) — what the Pro/Max subscription meters. The headline.
- **Weighted cost** — model-agnostic input-equivalent tokens (`in + out·5 + cache_read·0.1 + cache_write·1.25`). Used by `spells/session-tokens.sh` and `score-token-viz.py` for relative ranking.
- **Dollar (list-price API) estimate** — what the same usage *would* cost on pay-as-you-go, per model. This is the only figure that reflects the real Haiku/Sonnet/Opus/Fable price spread.

**Tokens up = output; tokens down = input.** The popup already prints `↓in ↑out` per session; `score-usage-detail.py:parse_sessions` now also accumulates a full per-model breakdown (`model_io`: in/out/cache_read/cache_creation) so each window section prints `≈$N API` and a per-model cost in the `By model` line.

Pricing lives in **`score-pricing.json`** (the single source of truth — list prices $/MTok per model; `cache_read = 0.1×input`, `cache_write = 1.25×input` for the 5-min TTL Claude Code uses). The importable **`score_pricing.py`** helper (`load`/`cost`/`fmt_usd`) is shared by the popup and the viz builder; unknown models fall back to the configured Sonnet-tier `default`. These are *API list-price* estimates, distinct from the subscription quota %.

### Regression refinement — NNLS, Anthropic-only, exported coefficients (S186)

`score-usage-fit.py` was refined in two ways:

1. **Anthropic-only regressors.** sCoRE's OpenRouter providers (deepseek / llama / nvidia / mistral) appear in transcripts but spend **zero Claude quota** — including their token deltas as regressors produced absurd coefficients (e.g. `nvidia output ≈ 54.8 %/token`) and dragged the Claude coefficients negative. `_is_quota_model()` now filters features to `claude-`-prefixed models only.
2. **Non-negative least squares** (`scipy.optimize.nnls`, falls back to `lstsq`). Token costs can't be negative; NNLS pins collinear/weak features to 0 instead of fitting non-physical negatives.

Result on the current log (~7,700 api-poll obs, 2,490 usable 5h deltas): full rank 16/16, all coefficients ≥ 0, RMSE ~2.0 pp/interval (5h) and ~0.7 pp (week), and CC tokens now explain ~100% of observed Δ% (was leaking into junk features). The fit **exports** `~/.cache/rabble/llm-usage-coeffs.json` — `{windows: {5h|week: {coeffs: {model: {type: %-per-token}}, rmse_pp, n_deltas}}}` — so other tools can predict `pct = Σ coeff[model][type]·tokens` from empirical weights instead of the crude `FIVE_H_LIMIT` division. Run `score-usage-fit.py` to regenerate after the poller accumulates more samples.

### Breadcrumb visualization — `score-token-viz.py` (S186)

Joins three breadcrumb sources — transcripts (per-session, **per-model**), `RaBbLE-Grimoire/log/token-ledger.tsv` (session → feature → note), and `score-pricing.json` — into one chartable JSON at `RaBbLE-Grimoire/log/token-viz.json`. Schema: `totals`, `by_model`, `by_feature`, `by_project`, and a `sessions[]` array, each with tokens down/up/cache, weighted cost, and `$` API estimate, plus a per-model breakdown. Auto-discovers the Grimoire by walking up from the script dir / CWD; `--since N` limits to recent days, `--stdout` / `--out` / `--quiet` control output. Token sums match `spells/session-tokens.sh` (same no-dedup approach + weighting constants); the new thing it adds over that spell is the per-model split and dollar costing.

---

---

## Antigravity (agy) tracker

`agy` is the [Antigravity CLI](https://antigravity.sh) — a Google-backed coding agent. Its Waybar pill (`custom/llm-antigravity`) is a third tracker in the same two-tier architecture, on branch `new-horizons-antigravity-tracker`.

### agy data locations

| Path | What |
|---|---|
| `~/.gemini/antigravity-cli/log/cli-*.log` | Runtime logs — quota errors, model switches, auth events |
| `~/.gemini/antigravity-cli/conversations/*.db` | Conversation history (binary protobuf — not directly readable) |
| `~/.gemini/antigravity-cli/settings.json` | Active model and other user settings |
| `~/.gemini/antigravity-cli/brain/` | Per-conversation memory dirs (mtime = last activity) |

### agy dual quota pools

agy has **two independent quota pools** — neither shared with Claude Code:

| Pool | Trigger | Data source |
|---|---|---|
| **Gemini API quota** | `RESOURCE_EXHAUSTED` when a Gemini/Flash model was active | `cli-*.log` — matched by prior `model_config_manager.go:157` label |
| **Antigravity service quota** | `RESOURCE_EXHAUSTED` when a Claude/GPT model was active | Same log, different model-context |

Both pools show the same `RESOURCE_EXHAUSTED` error format ("Individual quota reached. Resets in Xh"). The tracker **distinguishes them by tracking the `model_config_manager.go:157` label in log order** — whichever model was active when the error fired determines which pool was hit.

The second pool (Sonnet/Opus/GPT models) is served by Antigravity's own cloud service (`daily-cloudcode-pa.googleapis.com`) — it is NOT Anthropic's Claude Code quota. Displaying it as "shared with Claude Code" is **incorrect**.

### Live reset detection — `score-agy-quota.py` (single source for bar + popup)

The earlier readers flagged a pool exhausted whenever *any* `RESOURCE_EXHAUSTED` line existed in the last 7 days, so the `⊘` stuck around for a full week — **a reset was invisible** (the original bug report). The popup tried to subtract elapsed time but anchored to the log **file's** mtime (last write, not the event) and never actually cleared the pool even when the countdown went negative.

`score-agy-quota.py` replaces both with one helper (`compute()` → JSON, `--shell` → bash env-assignments; stdlib only, run by the bar daemon every ~5s and imported by the popup). It reads the **outcome of the most recent request per pool** straight from the glog lines:

- A request is `server.go:1058] Sending user message to conversation`. Its pool is fixed by the last `model_config_manager.go:157` `label="…"` seen **before** it.
- A `RESOURCE_EXHAUSTED` after that send (before the next send) means it **failed**; otherwise it **succeeded**.
- **Watching the bare model-selection line does NOT work** — agy re-emits one *right after* an exhaustion (the quota-refresh loop re-propagates the model), so it is not proof the pool recovered. Only a *send with no error after it* is. This was a real false-clear: a startup Claude-model selection made a genuinely-exhausted service pool read as available.

A pool is reported exhausted **IFF** its most recent outcome was a failure (`last_exhausted >= last_success`) **AND** the reset epoch is still in the future. So the `⊘` clears the instant a request goes through again — even while the stale "Resets in" countdown still shows days.

Reset times are logged as e.g. `Resets in 52h31m43s` (the window varies — seen at ~52h and ~167h). The countdown is anchored to **each event's own glog timestamp** (`Emmdd HH:MM:SS`, year taken from the `cli-YYYYMMDD_HHMMSS.log` filename, bumped across a Dec→Jan rollover) plus the duration → an absolute reset epoch, then displayed as `reset_epoch − now`. The "Resets in" estimate is treated only as a secondary cap, never the primary signal — Google has reset a pool (Gemini, observed) well before its stated time, which is exactly why the send-outcome check, not the countdown, decides whether `⊘` shows.

### Glyph and click-action notes

- **Idle**: `Λ` (Greek lambda, RaBbLE-Violet) — parabolic arch mirroring the Antigravity "A"  
- **Rate-limit marker**: `⊘` per exhausted pool; `⊘⊘` if both Gemini + Service are hit  
- **Click**: opens `score-usage-detail.py antigravity --live` — agy-specific popup only (no Claude agents panel or Claude quota bars)  
- **Stale-cache safety**: if the daemon hasn't refreshed the cache in >30s (likely crashed), glyph-stream falls back to idle so a dead daemon can't lock the pill in "busy"

### agy popup contents (score-usage-detail.py antigravity)

1. Header: running count / not running, configured model, login status
2. **Gemini API quota** — bar at 100% + live "resets in" countdown when exhausted; `available` otherwise
3. **Service quota (Sonnet/Opus/GPT)** — same, labeled as Antigravity service; model that triggered it shown in parentheses
4. Sessions: list of recent conversations by DB mtime (up to 5), plus 7-day/today counts

### bfs compatibility gotcha

`RaBbLE-OS` ships `bfs` (Better Find) as the system `find`, which does NOT support `find -newermt '-24 hours'` (relative time strings). Use `-mmin -N` instead:

- `-newermt '-24 hours'` → `-mmin -1440`
- `-newermt '-7 days'` → `-mmin -10080`
- Short-window heuristics (`-newermt '-8 seconds'`) silently fail — they are secondary fallbacks, primary hook-based state is still accurate

---

## Open threads

- **Codex turn-start** — `notify` only covers turn-complete; busy detection stays heuristic until Codex grows real lifecycle hooks (then mirror the Claude bridge in `score-sessions.py`)
- **Close the coefficient loop** — `score-usage-fit.py` now has stable weekly-window coefficients (RMSE 0.446 pp). The next step is to save them to `~/.cache/rabble/score-usage-coeffs.json` and have `count_tokens_since` load that file instead of the hardcoded raw-sum formula. Until then, `score-usage-fit.py` is purely diagnostic.
- **Deduplication + limit recal** — fixing the ~2.57× streaming-record duplicate count would make the absolute token display accurate; requires re-deriving `FIVE_H_LIMIT` / `WEEKLY_LIMIT` from a clean calibration pass (read raw in+out from the api-poll log at a known %, not from the local JSONL parser).
- This is the **first sCoRE applet** — expect it to migrate wholesale into RaBbLE-sCoRE once that member is ready to own its own UI surfaces; the `score-` prefix and self-contained `~/.cache/rabble/` cache layout are deliberate preparation for that move
