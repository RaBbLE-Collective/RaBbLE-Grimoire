# HANDOFF-S285 · RaBbLE-UI: entropy reshaped, scroll fixed, now test it live

> Written 2026-10-28 at the end of S285. Supersedes the "test" half of `HANDOFF-S284-RaBbLE-UI-Live-Test.md`
> (still read it for the checklist and open items). Everything below passes unit tests and a headless
> Pilot run on haiku; **Mark's pass in kitty has not happened.**

## What S285 did (RaBbLE-sCoRE `new-horizons`, local, not pushed)
- **Pass A on the live engine (haiku, Pilot, real `ClaudeCodeBackend`).** Findings: permission modal works (`rm` prompts; keys are 1/2/3); `ModelUsed` fires once, no false fallback on alias vs full id; `/trust` usage error fine; face glitches visibly at 0.90.
- **Sonnet is a frontier model.** Baseline 0.25 to 0.10, tier `strong`: STABLE, `trusted`, clean entity, no tier drop from opus.
- **Entropy = baseline + damage + pressure** (doc: `RaBbLE-sCoRE/RaBbLE-sCoRE-Entropy-Tracker.md` v0.2). Context fill, rate-limit warning and long sessions are live pressure that recovers; compaction, tier drops, fallbacks, handoffs stay cumulative damage.
- **Scroll fix** in `ui/widgets/transcript.py`: follow new content when within 3 lines of the bottom; submitting always jumps to the bottom. Textual's anchor releases on any scroll and only re-arms at the exact bottom, which stranded the view mid-content. The reported "jump to the middle" was NOT reproduced; the stuck-behind case was.

## Test next (Mark in kitty, from the Collective root: `rabble`)
1. **Scroll:** scroll up a little, send a message: view returns to the bottom and follows streaming. Scroll up far during a long reply: it should not drag you down. Does anything still jump to the middle? If so, note what was on screen (tool card, Markdown update, picker) and report.
2. **Glitch by model:** `/model sonnet` and `/model opus`: entity clean, trust `trusted`. `/model haiku`: visible static, `strict`, tier-drop notice. Judge the glitch curve (floor 0.2, linear) by eye; tune `signal_level` / `ENTROPY_FLOOR` in `ui/face.py` if wrong.
3. **Context pressure:** run a long session or `/compact`. Watch the header band and trust move as context fills (about 85% context is NOMINAL on opus) and drop back after a compact (compaction adds +0.20 damage that stays). Is the signal early and legible enough, or should `CONTEXT_MAX` go up to about 0.45? Is "context N% full" noticed?
4. **Sonnet auto-approves now** like opus (trusted). Confirm that is what Mark wants; the always-prompt danger list is unchanged.
5. The remaining S284 checklist items not covered yet: `/crew on` live (and the background-subagent permission spike), `--continue`/`/resume` header model, `/face` frame cost, slash completion, mouse selection, tmux, SSH.

## Open items
1. **Inline code eats the adjacent space** in the transcript ("`ls` shows" renders "lsshows"). Not fixed; check `ui/widgets/transcript.py` Markdown rendering.
2. **Full `can_use_tool` path not proven:** `ls` ran with no prompt on standard trust; we don't know if CC's allow rules or our hook decided it. `git push`, `mcp__`, edits outside the cwd and a CC `deny` rule are untested (my script pressed `n`; the keys are 1/2/3).
3. S284 open items 2 to 5 stand (U3 should-fixes, entropy doc items not built, tracker home, U3 proper), plus NiBbLE review of `orchestra/trust.py` before trusting `trusted` broadly, now more important since sonnet earns it.
4. **Uncommitted elsewhere:** RaBbLE-OS has a manifest edit from a mis-targeted S283 handoff run (`edition:` on all 171 entries plus `spells/edition-audit.sh`); it is W1 of `log/plans/OS-Install-Editions-Plan.md`, correct but unreviewed. Keep or revert.

## Test fixtures
`RaBbLE-BaBbLE/tmp/s284-live/`: `drive.py`, `drive2.py` (Pilot driver, real backend, `RABBLE_UI_PREFS=/tmp/rabble-test.json`), `scroll.py` (headless scroll scenarios). Run with `PYTHONPATH=RaBbLE-sCoRE ~/.local/share/RaBbLE/rabble-ui/bin/python -P <script>` from the Collective root. Gitignored.
