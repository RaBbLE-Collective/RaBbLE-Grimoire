# Plan: RaBbLE-UI: RaBbLE's own terminal face over a headless Claude Code

**Status:** 🔵 S275 design, Opus-reviewed (14 findings folded in). U0 spike verified. S279: **U1 + U2 done** (engine `fb80966`, face `a6a46be`; live haiku turn verified headless), `rabble` flipped to the UI (`--cc` = wrapper). U3 next: HANDOFF-S279.
**Repo:** RaBbLE-sCoRE `new-horizons` · **Source home:** `RaBbLE-sCoRE/ui/` (face) + `RaBbLE-sCoRE/orchestra/` (engine). Code in the member, this doc in the Grimoire.
**Goal:** `rabble` opens a terminal UI that is RaBbLE's own: portal glyph top left, Aether colours, organs shown as organs. Claude Code runs headless underneath through the Claude Agent SDK. The Crew starts as SDK subagents and grows toward teammate-level collaboration through RaBbLE's own orchestration, not Claude Code's experimental agent teams.

## Decisions (Mark, 2026-10-24, S274)

- **Episode framing does not gate dev.** Treat current work as EP2. EP1 still airs with a new pre-summon World page; that is a separate track and must not distract from this.
- **Own UI, Claude Code headless.** Claude Code's TUI is closed (you can't swap out the crab logo); RaBbLE renders its own.
- **Engine: Claude Agent SDK (Python, `claude-agent-sdk`).** Same tools, edits, permissions, and sessions as Claude Code, consumed as an event stream.
- **Crew = SDK subagents first,** then orchestration through RaBbLE/sCoRE to get closer to teammates (persistent organs, organ-to-organ messages, Observer talks to any organ).
- **Home: inside sCoRE** (`ui/`), not a new member repo.
- **Framework: Textual** (Python). Matches sCoRE, the SDK, and L-09's named EP3 TUI (now pulled forward).

## Target: replace `claude` as the terminal entrypoint

Mark (S275): this is a major sCoRE expansion, and `rabble` should replace his use of `claude` as the day-to-day terminal entrypoint. So U2 is judged by daily-driver parity, not demo polish.

| Must have before the default flips | Can follow |
|---|---|
| Streaming chat, tool cards, permission prompts (once / session / deny) | `!` shell passthrough |
| Esc interrupt; Ctrl-C twice quits; Ctrl-D quits on empty input | Image paste |
| Resume (`/resume`, `rabble --continue`, `--resume <id>`) via SDK `resume=` | External editor (`Ctrl-G`) |
| `/model`, permission mode toggle (default / acceptEdits / plan) | History search |
| `@path` file mentions with completion | Multiple sessions in tabs |
| Project settings, AGENT.md/CLAUDE.md, skills, MCP servers, hooks all load (`setting_sources`) | Cost dashboard |
| Context % + rate-limit state always visible | |
| Copy-friendly output (selectable text, no box glyphs inside code blocks) | |
| Works over SSH and inside tmux | |

`claude` stays installed and reachable as `rabble --cc` (wrapper) or plain `claude`, so a broken UI never blocks work.

## Why subagents + own orchestration (not agent teams)

| | CC agent teams (today's `rabble`) | SDK subagents (U3) | RaBbLE orchestration (U4) |
|---|---|---|---|
| Runs headless | no (`-p` never spawns teammates) | yes | yes |
| Organ lifetime | persistent | one task, one result | persistent (own SDK session, resumable) |
| Organ ↔ organ | direct messages | none, all via lead | via RaBbLE's bus |
| Observer ↔ organ | yes | no | yes (focus an organ tab, type) |
| Shown in | CC's teammate panel | RaBbLE's organ rail | RaBbLE's organ rail |
| Depends on | experimental env flag | stable SDK `agents` option | our code |

Organs are parts of one body coordinated by RaBbLE, so a hub that can grant peer links fits the entity better than a group chat. U4's cost is that we build and maintain the bus ourselves.

## U0 spike: verified S274

Scratch venv, `claude-agent-sdk==0.2.174` (bundles CLI 2.1.310), Python 3.14.7, Textual 8.2.8 on PyPI.

- `ClaudeSDKClient` runs on Mark's existing Claude Code login; no API key needed.
- `agents={"gobble": AgentDefinition(...)}` → the lead dispatched GoBbLE via the Agent tool. Subagent messages arrive tagged `parent_tool_use_id` = the spawning Agent `tool_use` id, so the face can route them to the right organ.
- Seen in the stream: `TaskUpdatedMessage`, `TaskNotificationMessage`, `SystemMessage(permission_denied)`, `RateLimitEvent`, thinking-token system messages, `ResultMessage(error_max_turns)`.

SDK surface the plan relies on (from `types.py` / `client.py`, 0.2.174):

- `ClaudeAgentOptions`: `system_prompt={"type":"preset","preset":"claude_code","append":...}`, `agents`, `setting_sources`, `can_use_tool`, `hooks` (incl. `SubagentStart`/`SubagentStop`), `include_partial_messages` (token streaming via `StreamEvent`), `forward_subagent_text` (full nested organ transcripts), `resume`/`fork_session`/`session_id`, `mcp_servers`, `permission_mode`, `cwd`, `model`, `max_budget_usd`.
- `AgentDefinition`: `description, prompt, tools, disallowedTools, model, background, maxTurns, effort, permissionMode, mcpServers, memory`.
- `ClaudeSDKClient`: `query, receive_response, interrupt, set_permission_mode, set_model, stop_task, get_context_usage, rewind_files`.
- In-process MCP tools: `create_sdk_mcp_server` + `@tool`. This is how U4 hands RaBbLE crew tools without a separate server.
- Session helpers: `list_sessions`, `get_session_messages`, `fork_session`.

## Architecture

```
RaBbLE-sCoRE/
  crew/
    roster.py      NEW: persona loading + AgentDefinition building, extracted from rabble.py
    rabble.py      CC wrapper; imports roster.py; stays available as `rabble --cc`
  orchestra/       engine. No Textual imports; testable headless
    events.py      normalized events (the contract between engine and face)
    backend.py     Backend protocol + ClaudeCodeBackend (ClaudeSDKClient)
    permissions.py can_use_tool → PermissionAsk event → awaits the face's answer
    crew.py        U3: roster → AgentDefinitions; routes parent_tool_use_id → organ
    bus.py         U4: organ sessions + message bus + task board, exposed as SDK MCP tools
  ui/
    __main__.py    `python -m ui`
    app.py         Textual App
    theme.py       Aether tokens → Textual CSS variables
    face.py        the entity in cells: full splash + mini header mark, expression-driven
    widgets/       header, transcript, tool_card, organ_rail, composer, permission_modal
```

**The event contract (`orchestra/events.py`)** is what lets the engine and the face be built in parallel and lets a later sCoRE HTTP backend slot in:

`SessionStarted(session_id, model, cwd)` · `SessionResumed(session_id)` · `TextDelta(organ, text)` · `TextBlock(organ, text)` · `Thinking(organ)` · `ToolCall(organ, id, name, input)` · `ToolResult(organ, id, ok, summary)` · `PermissionAsk(id, organ, tool, input, title, display_name, description, blocked_path, suggestions) → reply allow|allow_session|deny(+reason)` · `OrganStarted(organ, tool_use_id, task_id, brief)` · `OrganProgress(organ, task_id, usage, last_tool_name)` · `OrganDone(organ, task_id, status: completed|failed|killed, result)` · `Usage(tokens, cost, context_pct)` · `RateLimited(status: warning|rejected, until)` · `TurnDone(stop_reason, origin)` · `Error(text)`

`organ` is `"rabble"` for the lead, otherwise the persona slug. Mapping rules (S275 review):
- **Text:** with `include_partial_messages` the lead gets `TextDelta`s and then the full `AssistantMessage` anyway, so dedupe. Organs only get block-level `TextBlock`s (`forward_subagent_text`), never token deltas.
- **Organ identity:** stream messages carry `parent_tool_use_id`; `can_use_tool` and hooks carry `agent_id`. A `SubagentStart` hook maps `agent_id` → `agent_type` → organ. `TaskStartedMessage` maps `tool_use_id` → `task_id` (what `stop_task` takes).
- **Organ end:** clear an organ on a terminal status from either `TaskNotificationMessage` or `TaskUpdatedMessage`.
- **Turns:** background subagents and queued messages start extra turns. `TurnDone.origin` tells the face whether a turn answers the Observer.

## Phases

### U1 · Engine (headless)

1. Extract `load_crew`, `parse_persona`, `organs`, `build_agents`, `build_lead_prompt`, `latest_state` from `crew/rabble.py` into `crew/roster.py`. `rabble.py` imports them; the existing 17 launcher tests stay green. Don't carry `rabble.py`'s hardcoded `THREAD`/`MUTED` hex or hex fallbacks into `roster.py`; colours come from the palette (U2.1).
2. `events.py` dataclasses as above.
3. `ClaudeCodeBackend`: one `ClaudeSDKClient` per session. Options: preset `claude_code` system prompt + `append` = lead prompt (same as today's `--append-system-prompt-file`), `setting_sources=["user","project","local"]` so AGENT.md/CLAUDE.md and project permissions load, `include_partial_messages=True`, `cwd` = launch dir. Maps SDK messages → events. Loops `receive_messages()` for the session's whole life, never `receive_response()` (that one stops at the first `ResultMessage` and would miss turns started by background organs).
4. `permissions.py`: `can_use_tool` emits `PermissionAsk` and awaits an `asyncio.Future` resolved by the face. Asks can arrive concurrently (each runs as its own task), so the face queues them. "Allow for session" returns `PermissionResultAllow(updated_permissions=[PermissionUpdate(type="addRules", rules=[...], behavior="allow", destination="session")])`. Always force `destination="session"`, even when reusing `context.suggestions`, which can name `localSettings`/`projectSettings` and would write to disk. `can_use_tool` only fires when the CLI would otherwise prompt: allow rules (including a project's `Read(*)`) and `bypassPermissions` skip it.
5. Headless check: `python -m orchestra.probe "prompt"` prints events as JSON lines. CI tests use a fake backend that replays recorded event fixtures (record a few from real runs; no live calls in tests).

### U2 · Face

1. `theme.py`: read hexes from `RaBbLE-Agent/RaBbLE-Palette.md`'s YAML block at startup (Grimoire path the same way `roster.grimoire_root()` resolves it). Never hardcode hex in the UI. Organ colours come from persona frontmatter (`color_base`), with the Archivist in muted text as the launcher already does.
2. `face.py`: **the entity itself, not a logo** (Mark, S275: "a more comprehensive RaBbLE face … that actually looks like the entity"). Prototype in `RaBbLE-BaBbLE/prototypes/terminal-face/` (shots in `shots/`):
   - The NeBuLA alive entity drawn in cells: half-blocks for eyes/portals/nodes, braille for orb wireframe, meshes, lightning envelope. Face rig + expression table ported from `alive-backend.js` (calm, joy, sad, angry, listening, speaking) with the portal occlusion rule; `Life` = blinks + saccades.
   - Two sizes from one renderer: **full** (splash/idle, ~128×36, shown when the transcript is empty or on `/face`) and **mini** (24×6 header mark, top left, animated; eyes spread 1.3× (one-cell gap; Mark: 1.0 touches, 1.9 far too wide); drawn in Unicode 16 octant glyphs (2×4 sub-pixels per cell) because half-blocks read too blocky at this size; needs a terminal that draws octants itself (kitty, foot, wezterm, ghostty), else fall back to half-blocks).
   - Engine state drives expression: awaiting the Observer → calm · Observer typing → listening · streaming text → speaking · tool/organ work → calm with fast gaze (a "process" mood is a later addition) · error → sad · permission denied → angry (brief). Expressions spring between poses like NeBuLA, not snap.
   - Truecolor required; degrade to 256-colour quantize, and to a static wordmark under `NO_COLOR` or non-UTF-8.
   - Status (S275 end): full face approved by Mark; **mini still needs work** (blended tips, ring balance, legibility).
   - **Mark signs off the face** by running `python3 face.py` / `--mini` in his own terminal.
3. Header: mini face · `RaBbLE` gradient wordmark · model · cwd · context % · rate-limit state. Plus session cost labelled **API equiv** (Mark, S278: keep it on a subscription login too; it shows what the API would cost without the plan). Source: `ResultMessage.total_cost_usd`, computed by the CLI from tokens × API list price.
4. Transcript: streaming Markdown for text; collapsible tool cards (name, one-line input, result summary, red on error); thinking shown as a pulsing line, not content.
5. Composer: multiline input, Enter sends, Shift+Enter newline, Esc interrupts (`client.interrupt()`), Up recalls history. Slash commands: `/model`, `/organs`, `/resume`, `/clear`, `/quit`.
6. Permission modal: tool + input preview + allow once / allow for session / deny with reason. Bash shows the full command; edits show the diff.
7. Developed against the fake backend from U1.5 so it doesn't block on U1.3.

### U3 · Crew as subagents

1. `crew.py` builds `AgentDefinition`s from `roster.py` (same tiers/models/tool allowlists as `build_agents`).
2. `forward_subagent_text=True`; route by `parent_tool_use_id` → organ.
3. Organ rail (right side, collapsible): one row per active organ (colour dot, name, brief, status, elapsed); select a row to open that organ's nested transcript in a tab. `stop_task(task_id)` cancels an organ. `interrupt()` does not stop background organs, so Esc offers "stop live organs too" when any are running.
4. Parallel organs: the lead may dispatch several in one turn; organs marked `background` in frontmatter (new optional field) run as background subagents. **Spike first:** the SDK source doesn't show whether background subagents can raise permission prompts. Check this before building U3.4.
5. Check: the S273 handoff's cheap loop ("GoBbLE, map where the beam's reconnect logic lives; QuiBbLE, critique a fix plan") runs end to end in the UI, models match tiers, and read-only organs can't Edit.

### U4 · Orchestration toward teammates

RaBbLE-side bus in `orchestra/bus.py`, exposed to the lead and to organs as in-process SDK MCP tools.

Structure (S275 review, high-severity findings):
- **One `crew` server per session,** built by `make_crew_server(self_organ)` with the caller bound in a closure. Tool handlers receive only `arguments`, with no caller id, so a single shared server couldn't enforce formations or route replies.
- **One long-lived supervisor task per organ,** started from the app's task group. It connects the organ's `ClaudeSDKClient`, loops `receive_messages()`, and reads an `asyncio.Queue`. A client must stay in the async context it connected in, so handlers never connect clients themselves: they put onto the queue and return.
- **Every bus message is fire-and-forget.** `client.query` just writes to the CLI's stdin, and the CLI takes in queued messages mid-turn, so the bus needs no busy-queue of its own. A `send` that waited for a reply could deadlock (A waits on B, B waits on A). Replies arrive as new turns; the bus counts debate turns.
- **Envelope for attribution:** the SDK can only stamp `origin` as human, so bus messages carry an in-text envelope (`[crew from=quibble kind=reply]`).
- **Lead notification:** when an organ's turn ends, the supervisor injects a short `[crew from=<organ> kind=done]` summary into the lead's session.
- **Resumed organs:** set `snapshot: False` on organ system prompts, or persona edits never reach a resumed session (`snapshot` defaults to True).

Tools:
- `crew.summon(organ, brief)` → starts a **persistent organ session** (its own supervisor + `ClaudeSDKClient`, persona appended to the preset, own `session_id` saved so it can be resumed). It returns at once, and its progress streams into the organ's tab.
- `crew.send(to, message)` → fire-and-forget delivery to an organ's session. Organs get their own bound copy of the tool, which gives peer messaging. The bus enforces who-may-talk-to-whom from a formation table.
- `crew.board` → shared task list (add/claim/done), shown in the UI.
- `crew.dismiss(organ)` → ends a session; the transcript stays.
- **Observer direct line:** focus an organ tab and type; it goes to that organ via the bus, and the lead sees a one-line notice.
- Caps: ≤5 live organs (rabble.md's rule), per-organ `max_budget_usd`, global concurrency limit.
- First formation: **QuiBbLE ↔ NiBbLE debate** with a turn limit; RaBbLE synthesizes.

### U5 · sCoRE seam (later, not this push)

- Backend #2: sCoRE local server streaming (merges with L-09); the same face over sCoRE's own routing/LLM chain.
- Session log to `~/RaBbLE-chats/rabble-YYYYMMDD-HHmm.jsonl`; entropy notices; routing transparency line (L-09 acceptance items).
- Codex/Gemini backends reading the same Crew specs.

## Roadmap: Mark's ideas for RaBbLE-UI (logged 2026-10-29)

Ideas as Mark raised them, not scoped and not scheduled. Status is what exists in `RaBbLE-sCoRE/ui/` today. Nothing here changes the U1 to U5 order above until Mark picks it.

| ID | Idea | Status | Notes |
|---|---|---|---|
| R1 | Face at 24-30 fps in the TUI | **Partly done** | Layered renderer: background (envelope, mesh, orb) at 8 fps on its own thread, eyes and halo on their own thread, assembly and noise every tick (30 fps) on the loop; only changed rows are repainted. Headless measure: display 27/24/21 per s at 120x40, 200x55, 260x70; eye layer 16/12/10 per s. **Pure Python cannot do 24-30 fps eye motion at fullscreen sizes**: one eye repaint costs 10 to 65 ms. Real fix is R3 or R4. |
| R2 | Render HTML and other artifacts inside the TUI | Idea | Candidates: (a) headless-browser screenshot shown through the kitty graphics protocol (Playwright is already in the Collective), (b) text rendering of HTML in a pane (w3m/browsh style), (c) native cards for Markdown, SVG, images, PDF pages. Open: static or interactive; what counts as an artifact (a tool result, a file the model wrote, a served page); how it degrades in terminals without graphics (VS Code). |
| R3 | **Face render server**: render the face outside the TUI and stream frames to it | **Retired S292**: Rust threads have no GIL, so the face renders in-process; see `sCoRE-RaBbLE-UI-Rust-Plan.md` | Removes the face from the TUI's GIL entirely. A local server also gives the UI wider system access (files, processes, OS tracker, clipboard, browser for R2). Likely shares its shape with the sCoRE local server in U5 / L-09; decide whether they are one server. Frame format to settle: cell grid vs encoded image, and the transport. |
| R4 | Move the TUI to Rust | **Chosen by Mark S292; plan proposed** (`sCoRE-RaBbLE-UI-Rust-Plan.md`, handoff `HANDOFF-S292`) | Alternative or companion to R3 (ratatui class). Would take the render loop and the face out of Python. Open: keep Python for the engine (Claude Agent SDK) behind a socket, or port that too. |
| R5 | Aura tinted by model provider | **Done** (tune by eye) | Anthropic orange, Google its four-colour ring, OpenAI green; sCoRE and local keep the RaBbLE poles. Muted toward palette violet (`PROVIDER_MUTE`), strengths `AURA_POLES`/`AURA_RING` in `ui/face.py`. Provider colours are third-party brand values, not palette values. |
| R6 | Flowing cyan-to-magenta separator under the header | **Done** | `ui/widgets/divider.py`, 8 fps cosine bounce between the palette's cyan and magenta. |
| R7 | Crisper, anti-aliased mini mark with less glow bleed | **Done** (tune by eye) | Tighter halo and sharper edge for the mini; lone faint sub-pixels flattened. |
| R8 | Full face and mini match the Entity Rig spec | **Mostly done** | Proportions, gaze range, idle float, portal bob, halo ratios from `RaBbLE-NeBuLA/specs/rig/entity-rig.json`. Not drawn: tilt, breathe, heartbeat, portal energy-ring spin, blink lag of 40 ms on the right eye. |
| R9 | Works in the VS Code terminal | **Partly done** | Safe glyph mode (Block Elements only, auto on `TERM_PROGRAM=vscode`, `RABBLE_GLYPHS=safe\|octant`). Not yet seen in VS Code by Mark. |
| R10 | Image paste into the composer | Idea (asked 2026-10-29) | Ctrl+V with an image on the clipboard no longer crashes but pastes nothing. Needs the clipboard image sent to Claude Code as an image block; display depends on R2. |
| R11 | Sphere looks squished at fullscreen | **Diagnosed S292**: kitty cell 19x44 px = aspect 2.32 vs the assumed 2.0; fixed natively in the Rust face (R3 of the Rust plan), not in Python | Probable cause: the renderer assumes cells 1:2 and the terminal's cell aspect is different. Needs Mark's terminal and cell size. Fix would read the cell aspect (`TIOCGWINSZ` pixel size, or `RABBLE_CELL_ASPECT`) and scale y for the whole face. |

RaBbLE suggestion, not Mark's idea: make `/face` a dismissable full-screen overlay instead of a block in the transcript (the transcript block takes its height from the viewport, which is small in a short VS Code panel).

## Launcher change

- `rabble` → the UI (once U2 ships). `rabble --cc` → today's Claude Code wrapper, unchanged.
- Positional words stay reserved (L-09 single-shot `rabble "msg"` later lands on the same engine).
- The guard against launching inside `RaBbLE-sCoRE/` still applies: with `setting_sources` including `project`, sCoRE's `.claude/settings.json` denies Bash and Agent there.

## Parallel build split

| Lane | Work | Model | Depends on |
|---|---|---|---|
| A | U1.1 roster extract + tests | sonnet | — |
| B | U1.2 events contract | lead writes it first (small) | — |
| C | U1.3–U1.5 backend, permissions, probe, fixtures | sonnet | B |
| D | U2 face against fake backend | sonnet | B |
| E | U2.1 theme + U2.2 move the face prototype into `ui/face.py` as a Textual widget | sonnet | face sign-off |
| Review | NiBbLE-style diff review per lane | opus | each lane |

U3 and U4 are sequential after U1+U2 merge.

## Open for Mark

1. ✅ **Answered 2026-10-25 (S278): uv venv via Ansible.** Built: sCoRE `ui/requirements.txt` + the `claude-code` task in `ai-harnesses` makes `~/.local/share/RaBbLE/rabble-ui` (`layerctl apply claude-code`). Original proposal: `claude-agent-sdk` + `textual` need installing. Proposal: a sCoRE `ui/requirements.txt` and a uv-managed venv created by the RaBbLE-OS `ai-harnesses` role (Ansible-driven, per the install rule); `scripts/rabble` runs the venv's python. You apply with `layerctl`. The SDK bundles its own CLI (2.1.310 in 0.2.174); pin the SDK version, and if a system `claude` is used via `cli_path`, it must be ≥ 2.1.257 for `snapshot`/`verbatim_prompts`.
2. **Face sign-off** (U2.2): run the prototype in your terminal (`RaBbLE-BaBbLE/prototypes/terminal-face/`); tune before it moves to `ui/face.py`.
3. ✅ **Answered 2026-10-25 (S278): flip as soon as U2 works** (must-have column above still gates it). `rabble --cc` keeps the wrapper.
4. **Terms:** fine for your personal use on your login. If `rabble` ships to other people, check Anthropic's terms first; users would likely bring their own API keys (fits the BYOK local tier).
5. Crew colour candidates (S273) are still unpromoted; the UI reads whatever `RaBbLE-Palette.md` and the persona frontmatter hold.

## Sources

`RaBbLE-sCoRE/crew/rabble.py` · `RaBbLE-sCoRE/.claude/settings.json` · `RaBbLE-sCoRE/RaBbLE-sCoRE-Crew.md` (C6, §Limits) · `RaBbLE/Crew/README.md`, `rabble.md` · `RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Tickets.md` (L-09) · `RaBbLE-Agent/RaBbLE-Palette.md` · `RaBbLE-OS/config/fastfetch/rabble-portals.base.txt` · `claude_agent_sdk` 0.2.174 `types.py`, `client.py`
