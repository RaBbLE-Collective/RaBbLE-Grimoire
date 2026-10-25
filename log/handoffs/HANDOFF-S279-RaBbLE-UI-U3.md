# HANDOFF-S279 · RaBbLE-UI: U1 + U2 live, `rabble` flipped; next U3 (the Crew as subagents)

> Written 2026-10-25 at the end of S279 for a cold start.
> Read first: this file, then `log/plans/sCoRE-RaBbLE-UI-Plan.md` (U3, U4, event contract).
> Supersedes `HANDOFF-S275-RaBbLE-UI.md` (moved to `done/`).

## Where it stands

| Thing | State |
|---|---|
| Engine (U1) | sCoRE `orchestra/`: `events.py` contract, `ClaudeCodeBackend` (one `ClaudeSDKClient`, pumped via `receive_messages`), `sdk_map.py` (organs routed by `parent_tool_use_id`), `permissions.py` (session-only rules), `sessions.py`, `python -m orchestra.probe`. Commit `fb80966` |
| Face (U2) | sCoRE `ui/` (`a6a46be`, review fixes `154e6c6`): Textual app, header (mini entity, wordmark, model, mode, ctx %, limits, API-equiv cost), transcript, tool cards, composer (`@path`, history, Esc, Ctrl-C x2, Shift+Tab), permission modal, session picker, palette theme, face widget with moods. |
| Launcher | `rabble` = the UI; `rabble --cc` = S273 Claude Code wrapper; no venv → falls back to the wrapper |
| Deps | uv venv `~/.local/share/RaBbLE/rabble-ui` (RaBbLE-OS `ai-harnesses` claude-code task, `31285c7`); pins in sCoRE `ui/requirements.txt` |
| Tests | UI venv: `~/.local/share/RaBbLE/rabble-ui/bin/python -m pytest tests/test_ui_*.py tests/test_orchestra_*.py tests/test_crew_launcher.py` (88 pass). Server venv `pytest tests` still green (UI tests skip there). Fixtures in `tests/fixtures/orchestra/` are live recordings |
| Mini face | Oval eyes, lids for angry/sad, no glow (BaBbLE prototype `f42d414`, ported into `ui/face.py`). Mark: "close" |

## Next, in order

1. **U2 Opus review: blockers fixed** (`154e6c6`: engine-call guard, `python -P` against cwd shadowing, 0.4 s permission arming). **Should-fix, open:**
   - `/face` full face costs 29 ms/frame at 128x36 (52 at 200x50) on a 50 ms tick: starves input. Lower its fps or render off-thread; pause when hidden (`ui/face.py` timer).
   - Ctrl-C with a mouse selection in the transcript counts as a quit press, never copies (`ui/widgets/composer.py` checks only its own selection; also check `screen.get_selected_text()`).
   - Ctrl-C twice doesn't quit while a modal is open (Textual shows its Ctrl-Q hint): add a priority app binding.
   - Mini face has no half-block / 256-colour fallback for terminals without octant glyphs (tofu over SSH/tmux to such terminals).
   - Header model blank after resume (`SessionResumed` has no model; take it from the init message).
   - Nits: observer TurnDone clears background organs' busy flags; consider Textual `MarkdownStream`; empty-transcript full-face splash not built (only `/face`).
2. **Mark daily-drives `rabble`** in kitty; collect breakage. Untested live: real permission modal, `/resume` + `--continue` against real sessions, `/face`, mouse selection, tmux, SSH.
3. **U3** (plan U3): `orchestra/crew.py` builds `AgentDefinition`s from `crew/roster.py` (tiers, tool allowlists); pass them as `agents=` and set `forward_subagent_text`; **rewrite the lead prompt's roster section for subagents** (today it says "spawn as teammates", the CC agent-teams wording, and U2 passes no agents, so the lead improvises). Organ rail (right side), organ tabs, `stop_task`, Esc offers "stop live organs too". Spike first: can background subagents raise permission prompts?
4. U3 check = the S273 cheap loop inside the UI ("GoBbLE, map the beam reconnect logic; QuiBbLE, critique a fix plan").

## Gotchas

- The real `subagent_type` arrives as the Agent tool input; organs show under that slug (a live run showed `Explore`). With the Crew it will be `gobble` etc.
- `ResultMessage.total_cost_usd` is a session total; the header replaces, not sums. It is API-equivalent (Mark wants it shown on the subscription login too).
- Textual segments with no bgcolor fall back to the terminal default, not the widget background: the face fills palette-bg cells with `self.rich_style.bgcolor`.
- Composer keys live in `Composer._on_key` (TextArea eats Ctrl-C, Screen eats Shift+Tab before app bindings).
- Probe from the Collective root needs `PYTHONPATH=RaBbLE-sCoRE`.
- Sub-agent lanes hit the usage limit mid-run (S279); resume them with SendMessage, they keep their work.
- Session numbering collided again: early S279 commits are tagged `%S278_RABBLE_UI%` (S278 = the concurrent Pocket W7 session).
