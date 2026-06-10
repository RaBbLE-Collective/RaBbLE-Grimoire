# sCoRE Usage Tracker — Waybar Claude/Codex pills

```
spark ~ sCoRE Usage Tracker >> hook becomes ground truth + interrupt-driven push // %S51%
mend  ~ sCoRE Usage Tracker >> multi-instance session engine + live popup + notifications // %S61%
```

> Lives in `RaBbLE-OS/config/waybar/scripts/score-*` and `config/waybar/{config.jsonc,style.css}`.
> Branch: `RaBbLE-OS-New-Horizons` (merged from `feature/waybar-llm-status`).
> **First sCoRE applet living in RaBbLE-OS** — built to be portable into RaBbLE-sCoRE directly; every script carries the `score-` prefix for that move.

---

## What it is

Two Waybar pills — `Claude ▁ ⚑1 ✦2 ▶1 45% / 31%wk` and `Codex >_×2 12%` — that show, at a glance:

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
| idle | `✱` (Claude) / `>_` (Codex) | RaBbLE-Magenta (muted) | No active session |
| ready | `▶` | Green | Session open, waiting for your input |
| busy | traveling block-wave `▁▂▄▆█▆▄▂` | Cyan, pulsing | Actively generating / running tools |
| needs-input | `⚑` | Magenta, **flashing** (`step-start` strobe) | Blocked on a tool-permission prompt — **it needs you** |

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
| `config/waybar/scripts/score-usage-detail.py` | Click-through popup — `--live` self-refreshing mode (Agents panel + quota bars every 2s, heavy token sections every 15s, incremental transcript tailing between repaints) with native scrolling (↑↓/jk/PgUp/PgDn/g/G; escape sequences decoded so arrows never quit — the `less` Esc failure mode is gone) |
| `config/waybar/scripts/score-usage-fit.py` | Delta-based regression fitter — isolates web/other usage as residual against local estimates |
| `RaBbLE-OS-dotctl.sh` → `_post_apply_waybar()` | Merges the hook into `~/.claude/settings.json` AND the notify program into `~/.codex/config.toml` on every `dotctl apply waybar` — idempotent, never clobbers |

---

## Open threads

- **Codex turn-start** — `notify` only covers turn-complete; busy detection stays heuristic until Codex grows real lifecycle hooks (then mirror the Claude bridge in `score-sessions.py`)
- **Drift tuning** — `score-usage-fit.py` keeps logging regression samples to refine the local estimate against the API's authoritative reading over time
- This is the **first sCoRE applet** — expect it to migrate wholesale into RaBbLE-sCoRE once that member is ready to own its own UI surfaces; the `score-` prefix and self-contained `~/.cache/rabble/` cache layout are deliberate preparation for that move
