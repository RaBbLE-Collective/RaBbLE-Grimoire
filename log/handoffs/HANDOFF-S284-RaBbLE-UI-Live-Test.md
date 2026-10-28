# HANDOFF-S284 · RaBbLE-UI: settings, trust and entropy built; next is running the real program

> Written 2026-10-28 at the end of S284 for a cold start. Everything below was built and unit-tested
> against recorded fixtures; **none of it has run against a live Claude session.** The next session's job
> is to run `rabble` for real, find what breaks, and fix it.
> Read first: this file, then `log/handoffs/HANDOFF-S279-RaBbLE-UI-U3.md` (engine/face background) and
> `RaBbLE-sCoRE/RaBbLE-sCoRE-Entropy-Tracker.md` (the score this build implements).

## What S284 built (RaBbLE-sCoRE `new-horizons`, local, not pushed)

| Commit | What |
|---|---|
| `4f172de` | `orchestra/entropy.py` (score, bands, events), `orchestra/trust.py` (profiles + danger list), `EntropyChanged`/`ModelUsed` events, backend wiring, permissions auto-approve hook |
| `7bba871` | `ui/face.py` `degrade()`: the entity's glitch/static/signal loss scales with entropy |
| `c255323` | `ui/prefs.py` saved settings, `ui/widgets/models.py` picker, `/model` `/crew` `/trust` `/status` `/help`, slash completion, header shows entropy + trust + crew, `--crew/--no-crew/--trust` |

Mark's rules behind it: the Crew is off by default (organs cost a full context each; use only for significant, parallel work); a low-trust model is a high-entropy model; the entity must look degraded as entropy rises; strong models get most permissions so he doesn't approve every request.

- Settings file: `~/.config/rabble/ui.json` (`model`, `crew`, `mode`, `trust`). Delete it to reset.
- Trust = `trust_for_score(entropy)`: below 0.2 `trusted`, below 0.5 `standard`, else `strict`. Baselines: fable/opus/gpt 0.05, sonnet 0.25, haiku 0.55, unknown 0.25. `/trust <level>` overrides, `/trust auto` returns to earned.
- Entropy events implemented: model switch, tier drop, unasked model change (fallback), fcc switch, thin organ brief (implicit handoff), engine restart (explicit handoff), context compaction, provider error, retry storm, rate-limit rejection, turns past 20.
- Trust never overrides: sudo, `rm`, `git push`/reset/clean, `dnf install`, `virsh --remove-all-storage`, kill, ssh, flashing, output redirects, `find -delete`, edits to `.git`/`.env`/`.ssh`/Claude settings or outside the cwd, and every `mcp__` tool always prompt.

## The test (do this first, from the Collective root)

Method: run the real program, not just pytest. Two passes.

**A. Agent-driven pass (cheap, haiku).** Drive the real app with Textual's Pilot and the real `ClaudeCodeBackend` (`ui.__main__` builds it), with `RABBLE_UI_PREFS=/tmp/rabble-test.json` so Mark's file is untouched and `--model haiku --trust standard`. Save SVG screenshots with `app.save_screenshot` and look at them. Venv: `~/.local/share/RaBbLE/rabble-ui/bin/python`; run from the Collective root with `-P`. A throwaway script is fine, put it in `RaBbLE-BaBbLE/tmp/`, not in sCoRE. Do not use tmux for Mark; an agent may use it as a test fixture.

**B. Mark's pass in kitty:** `rabble` from the Collective root, then the checklist.

### Checklist (each item: expected → what to look at if wrong)
1. **Launch:** splash/header shows `model · mode · trust · crew off`, entropy glyph appears after the first message. Header model not blank after `--continue`/`/resume` (known S279 bug, still open).
2. **`/model`** opens the picker; Enter on `sonnet` changes the header; `/model opus` too. Check the next reply really comes from that model (ask "what model are you"); check `ui.json` was written.
3. **Switching down** (`opus` → `haiku`): a notice appears (tier drop), entropy jumps to DEGRADED, trust falls to strict, the entity visibly glitches. Switching back up adds only +0.05; entropy does not recover (by design, per the doc: cumulative).
4. **Trust:** on opus, `ls`, `git status`, reading files, editing a file in the cwd run with no prompt; `git push`, `rm x`, anything `mcp__` prompts. On haiku everything prompts. Confirm the live `can_use_tool` path: does Claude Code still call it for these, or does an allow rule/`acceptEdits` mask it? (permissions.py notes `can_use_tool` fires only when CC would otherwise prompt.) Also confirm a CC `deny` rule still wins.
5. **`/crew on`** restarts the engine on the same session: transcript stays, conversation context continues (ask "what did I say first"), header shows `crew on`, entropy shows +0.05 "engine restarted". Then ask for something that needs an organ: the lead should call the Agent tool with `subagent_type` = `gobble` etc. Check organ tiers in the subagent `.meta.json`/jsonl. **Spike still open from S279:** can background subagents raise permission prompts? `/crew off` returns to solo; the lead should not spawn agents.
6. **Entropy events live:** do a long turn until context compacts (or `/compact`): expect "context compacted". Provoke an API error if possible. Check the `ModelUsed` event arrives once and the first one does not count as a fallback; check that alias vs full id (`opus` vs `claude-opus-5-5`) never creates a false fallback.
7. **Face:** glitch is visible but legible at DEGRADED, not distracting at ELEVATED, and clean at STABLE. Check FPS cost (S279 note: `/face` full costs 29 ms/frame; `degrade` adds work per tick on the mini face too), and kitty at 0.92 opacity.
8. **Slash completion:** `/` shows the list, Tab/Enter accepts; `/compact`, `/init` (CC commands) are still passed through as typed.
9. **Mark's daily-driver items still untested from S279:** real permission modal, `/resume` + `--continue` against real sessions, `/face`, mouse selection, tmux, SSH.

## Open items, in priority order
1. Whatever the live pass breaks.
2. S279 should-fixes still open: `/face` perf (29 ms/frame at 128x36), Ctrl-C copy with a selection, Ctrl-C twice with a modal open, octant fallback for terminals without those glyphs, header model after resume, observer `TurnDone` clearing background organs' busy flags.
3. Entropy doc items not built: session-close record (JSONL), `decisions_at_risk`, self-healing at next open, the "harness switch without handoff" event (needs a second harness), `rabble usage` health panel. Model baselines and the 0.2/0.5 trust thresholds and glitch curve are guesses; tune from the live pass.
4. Architecture call for Mark: the doc puts the tracker in `server/entropy.py`; it lives in `orchestra/entropy.py` because only the UI engine has live events today. When the server gets real routing, share the pure score logic.
5. U3 proper (organ rail, tabs, `stop_task`) per HANDOFF-S279.

## Gotchas
- `settings.carry` (not persisted) hands the running `Entropy` to the next backend on a same-session restart. A restart that doesn't pass it launders the score: check any new restart path.
- `_expect_switch` in `Entropy` clears at the next `turn_done`; if you see a false "fell back" right after `/model`, look there.
- `trust.py` danger list is a regex written for caution; false prompts are fine, a missed danger is the bug to hunt. NiBbLE has not reviewed it. A review of `orchestra/trust.py` before Mark trusts it with `trusted` is worth the cost.
- Session numbering collided again: S282 = RaBbLE-SiGiL, S283 = os-editions (Grimoire), this = S284.

## Grimoire git was repaired this session
A crash at 15:29 on 2026-10-27 interrupted S283's commit and left 4 empty object files (the B-23 commit `bcca6a8`, its trees, and the staged `log/SESSION-LOG.md` blob), which broke `git status`. Repaired losslessly: the commit was rebuilt from the reflog (parent, author, timestamp, message) plus the index's `BLOCKERS.md`/`blockers.jsonl` blobs and came out byte-identical (`bcca6a8`); the SESSION-LOG blob was restored from the working file (hash matched). `git fsck --full` is clean. Backup of the damaged `.git`: `~/git-repair-backup/`. **Still pending from S283:** its S283 entry in `log/SESSION-LOG.md` is staged but uncommitted (the interrupted commit), and S283 `LATEST`/ledger step never ran. The Grimoire working tree also carries other sessions' uncommitted edits (INDEX.md, plans, SiGiL files): commit those whole by their own session, never trimmed.
