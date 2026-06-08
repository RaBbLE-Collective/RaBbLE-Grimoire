# sCoRE Usage Tracker — Waybar Claude/Codex pills

```
spark ~ sCoRE Usage Tracker >> hook becomes ground truth + interrupt-driven push // %S51%
```

> Lives in `RaBbLE-OS/config/waybar/scripts/score-*` and `config/waybar/{config.jsonc,style.css}`.
> Branch: `RaBbLE-OS-New-Horizons` (merged from `feature/waybar-llm-status`).
> **First sCoRE applet living in RaBbLE-OS** — built to be portable into RaBbLE-sCoRE directly; every script carries the `score-` prefix for that move.

---

## What it is

Two Waybar pills — `Claude ✱ 45% / 31%wk` and `Codex >_ 12%` — that show, at a glance:

- **Live state**: idle / ready / busy / needs-input, each with its own glyph and color
- **Quota**: 5h-window and weekly-window usage percentage (Claude via Anthropic's official usage API; Codex via `token_count.rate_limits` in its session transcripts)
- **Detail on click**: a `kitty` popup running `score-usage-detail.py` with full token breakdowns, reset countdowns, and (for Claude) a comparison between the local transcript-based estimate and the API's authoritative reading

It is a **notification surface**, not just a meter — the whole point of the live-state color scheme is to answer "what is Claude doing right now, and does it need me?" without alt-tabbing to the terminal.

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

**The fix:** `score-claude-hook.sh`, wired into `~/.claude/settings.json` (merged via `_post_apply_waybar` in `RaBbLE-OS-dotctl.sh` — never hand-edit `settings.json`, the dotctl step merges idempotently and never clobbers hooks you add by hand). It listens across Claude's full conversational lifecycle — these are real Claude Code lifecycle events, not inferred:

| Event | New state | Why |
|---|---|---|
| `UserPromptSubmit` | busy | You just asked it to work |
| `PreToolUse` / `PostToolUse` | busy | Actively running tools |
| `Notification` (message mentions "permission") | **needs-input** | Blocked on *your* authorization |
| `Stop` / `SubagentStop` | ready | Turn finished, idle for input |

State lands in `~/.cache/rabble/claude-live-state` as a single word. `score-status.sh` and `score-glyph-stream.sh` treat it as **authoritative** over their mtime heuristics whenever it's fresh — stale beyond 10 minutes (e.g. Claude crashed mid-turn) and they fall back to the heuristic, so the pill can't get permanently wedged in "busy."

**Codex has no equivalent hook surface.** Its busy/ready detection is still the mtime heuristic — tightened from "newer than the cache file" to `-newermt '-8 seconds'` (the former had a race that flipped it back to "ready" right after each cache refresh), but it remains a guess. **If/when Codex grows a hook surface, mirror this bridge for it** — that's the natural next step, not a redesign.

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
| `config/waybar/scripts/score-status.sh` | Heavy computation — transcript parsing, token math, tooltip building, `source_state()` (state resolution: heuristic + hook override) |
| `config/waybar/scripts/score-status-daemon.sh` | Wraps `score-status.sh` in a ~5s loop, writes the cached JSON with `@GLYPH@` placeholder |
| `config/waybar/scripts/score-glyph-stream.sh` | Cheap continuous-output loop Waybar actually execs — repaints the glyph, applies the live-state override, sleeps via wake-FIFO `read -t` |
| `config/waybar/scripts/score-claude-hook.sh` | Claude Code hook bridge — writes `claude-live-state` and pokes the wake-FIFO |
| `config/waybar/scripts/score-usage-api-poll.py` | Polls Anthropic's official usage API (~90s) via Firefox session cookie + `curl_cffi` |
| `config/waybar/scripts/score-usage-detail.py` | Click-through popup detail view |
| `config/waybar/scripts/score-usage-fit.py` | Delta-based regression fitter — isolates web/other usage as residual against local estimates |
| `RaBbLE-OS-dotctl.sh` → `_post_apply_waybar()` | Merges the hook into `~/.claude/settings.json` on every `dotctl apply waybar` — idempotent, never clobbers |

---

## Open threads

- **Codex hook surface** — the natural next step once Codex grows lifecycle hooks; would let it shed its mtime heuristic the same way Claude did
- **Drift tuning** — `score-usage-fit.py` keeps logging regression samples to refine the local estimate against the API's authoritative reading over time
- This is the **first sCoRE applet** — expect it to migrate wholesale into RaBbLE-sCoRE once that member is ready to own its own UI surfaces; the `score-` prefix and self-contained `~/.cache/rabble/` cache layout are deliberate preparation for that move
