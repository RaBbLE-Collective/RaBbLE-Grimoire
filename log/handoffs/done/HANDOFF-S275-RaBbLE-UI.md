# HANDOFF-S275 · RaBbLE-UI: RaBbLE's own terminal face over a headless Claude Code

> Written 2026-10-24 at the end of S275 planning for a cold start.
> Read first: this file, then `log/plans/sCoRE-RaBbLE-UI-Plan.md` (decisions, event contract, phases U1–U5, lanes).
> Background: `log/handoffs/HANDOFF-S273-Crew-Launcher.md`, `RaBbLE-sCoRE/RaBbLE-sCoRE-Crew.md`.

## What Mark decided (S275)

- Episode framing does not gate dev: work as EP2. EP1's new pre-summon World page is a separate track; don't pull it in.
- `rabble` becomes RaBbLE's own Textual TUI (portal glyph top left, Aether colours) driving Claude Code headless via the Python Claude Agent SDK.
- The Crew becomes SDK subagents first, then RaBbLE-side orchestration (persistent organ sessions + message bus as in-process SDK MCP tools) brings it close to teammates.
- Code lives in sCoRE: `ui/` (face) and `orchestra/` (engine). Not a new member.

## What exists

| Thing | State |
|---|---|
| Plan | `log/plans/sCoRE-RaBbLE-UI-Plan.md` 🔵, indexed |
| U0 spike | Verified in a throwaway venv (S275 scratchpad, gone): `claude-agent-sdk==0.2.174` runs on Mark's CC login, dispatches a `gobble` AgentDefinition, subagent messages carry `parent_tool_use_id` |
| Code | None yet. `crew/rabble.py` (CC wrapper) unchanged |
| Deps | Not installed on the host. Proposal in plan "Open for Mark" #1 (uv venv via the `ai-harnesses` Ansible role); don't `pip install` system-wide |

## Next, in order

1. **Mark:** answer plan "Open for Mark" #1 (deps route) and #3 (default swap timing), and sign off the face: run `python3 RaBbLE-BaBbLE/prototypes/terminal-face/face.py` (and `--mini`) in a real terminal. It has only been checked as PNG renders (`preview.py`), never in a live terminal.
1a. **Mini header mark still needs work** (Mark, end of S275). Full face is approved. The 24×6 mini is octant-drawn with eyes at spread 1.3; open issues: pale blended eye tips (two colours per cell), ring/eye balance, overall legibility. Iterate with `preview.py` contact sheets *and* a live kitty check before moving it to `ui/face.py`.
1b. Goal is daily-driver parity with `claude` (plan section "Target"): the must-have column gates flipping the default.
2. Write `orchestra/events.py` first (lane B, small, lead-owned). It is the contract for lanes C and D.
3. Fan out lanes A, C, D, E (sonnet/haiku pinned, never inherit the lead's model). Opus diff review per lane.
4. U3 check = the S273 cheap loop run inside the UI.

## Gotchas

- An Opus review (S275) checked the plan against the SDK source and changed U4: one `crew` MCP server per session (handlers get no caller id), long-lived supervisor task per organ, fire-and-forget sends (no awaiting replies: deadlock), in-text `[crew from=…]` envelopes, `snapshot: False` for resumed organs. Details are in the plan's U4 "Structure" and the event-contract mapping rules.

- With `setting_sources` including `project`, launching inside `RaBbLE-sCoRE/` picks up its `.claude/settings.json` deny on Bash and Agent. Keep the launcher's warning.
- Keep the lead persona as an **append** to the `claude_code` preset system prompt; replacing it drops Claude Code's coding and safety guidance (same lesson as S273's `--agent` gotcha).
- No live SDK calls in tests: record event fixtures, replay through a fake backend.
- Colours: read `RaBbLE-Agent/RaBbLE-Palette.md` and persona frontmatter at runtime; no hex in UI code.
- A headless smoke run with `max_turns=4` hit `error_max_turns` after a few tool calls; give real sessions no turn cap, or a high one.
