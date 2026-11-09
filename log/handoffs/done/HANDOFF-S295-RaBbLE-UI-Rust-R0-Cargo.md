> **Status (S320, 2026-11-09): COMPLETE: R0 done and committed (sCoRE c99ef94).** Kept for reference, not deleted.

# HANDOFF-S295 · RaBbLE-UI Rust port: enable cargo, run R0 (DONE; next split is HANDOFF-S295-...-R1-Seam)

> Written 2026-10-29 (S295, claim the number first: `head -20 log/SESSION-LOG.md`, `spells/agent-register.sh status`). Supersedes HANDOFF-S292 for next steps; S292 still holds the baseline numbers and gotchas.
> Plan: `../plans/sCoRE-RaBbLE-UI-Rust-Plan.md`. Read it first. Work **with Mark** to get cargo building (step 1); nothing else in the Rust track can be verified until it does.

## Decisions now made (Mark, end of the S292 session, recovered from its transcript)
- **Option A confirmed.** The Python engine stays: sCoRE server in Python, non-user-facing, shared by every client. TUI, GUI and other native apps are Rust and talk to it. "I like to only port when needed." Option B (port the engine) is off the table until a measured need.
- **Stay inside sCoRE.** Rust lives in `RaBbLE-sCoRE/tui/`. No new repo, no new member.
- Still open: pixel-scroll spike (R5b), keep `rabble --py` one release (recommended yes), the Opus review of the plan (owed since S292, do it before R1).

## Step 1: enable cargo (do this with Mark, first)
**Problem:** Mark is on a public school network. Its content filter (Securly) serves a block page for `index.crates.io` and `static.crates.io` (DNS returns a `*-gnp-blocked-page` ELB, cert is `*.securly.com`, cargo fails `[60] SSL ... no alternative certificate subject name`). The sandbox is not the cause; disabling it changes nothing. **Do not route around the filter** (no alternate DNS, DoH, proxies, mirrors). Fedora's own mirrors are reachable (`dnf repoquery` works), which gives a clean route:

**Route A (recommended): Fedora-packaged crates, offline.** Fedora ships crates as `rust-*-devel` RPMs under `/usr/share/cargo/registry`.
1. The packages are in the manifest (`RaBbLE-OS/ansible/packages/manifest.yml`, `apps.ai-harnesses`, next to `pipx`) and installed by a new task at the end of `RaBbLE-OS/ansible/roles/ai-harnesses/tasks/claude-code.yml` (runs only when `tui/Cargo.toml` exists): `cargo`, `rust-ratatui0.29+crossterm-devel`, `rust-serde+derive-devel`, `rust-serde_json-devel`, each pulling its dependency closure. Mark's rule: Ansible-driven installs, never a live `sudo dnf` from the agent. **Hand Mark this to run:** `layerctl apply claude-code --check`, then `layerctl apply claude-code`. (`layerctl apply dev` does not exist: `layer/dev` in the manifest is declared but not wired to any layerctl target; valid targets come from `layerctl apply` with a bad name.) The play escalates with `become: true` on that one task, like aider's pipx install.
2. `RaBbLE-sCoRE/tui/.cargo/config.toml` (untracked, gitignored) already points cargo's `crates-io` at `/usr/share/cargo/registry`.
3. Verify: `cd RaBbLE-sCoRE/tui && cargo test --release` (use `--offline` if cargo still tries the network). `/usr/share/cargo/registry` is empty until step 1 runs.
4. **Version fit is the likely snag.** Fedora 44 has ratatui 0.29 and 0.30, crossterm 0.28 and 0.29, serde 1.0.228 and 1.0.229. `tui/Cargo.toml` pins ratatui 0.29 + crossterm 0.28 to match the RPMs; if cargo reports a missing version, change the requirement to what is in the registry dir (`ls /usr/share/cargo/registry | grep -E 'ratatui|crossterm|serde'`) and adjust the manifest package names to match (`dnf repoquery 'rust-<name>*-devel'`). Crates later needed (tokio, rayon, arc-swap, ...) each need their own `rust-<crate>-devel` entry in both the manifest and the claude-code.yml dnf list; check with `dnf repoquery` before choosing a dependency, and prefer packaged ones.
5. Licences: every crate must be MIT/Apache/BSD (Permissive third-party rule). Check `cargo metadata` / the RPM `License:` field.

**Route B: vendor once on an open network.** On home wifi: `cd tui && cargo vendor ../tui-vendor`, commit nothing, point `.cargo/config.toml` at the vendor dir. Good fallback, and the only route for crates Fedora does not package.

**Route C: ask the school IT to allowlist** `index.crates.io` and `static.crates.io`. Unlikely to be quick; do not wait on it.

## Step 2: R0 (cargo enabled and the workspace builds: `cargo test --release --offline` passes, bench numbers in the plan; T2 live gate on kitty PASSED by feel: Mark, "feels good!!!", no frame log)
`RaBbLE-sCoRE/tui/` (uncommitted):
| File | What | State |
|---|---|---|
| `Cargo.toml` | workspace: `rabble-proto`, `rabble-face`, `rabble-tui`, `bench`; ratatui 0.29, crossterm 0.28, serde | not built |
| `rabble-tui/src/glide.rs` | S292 Python glide ported (3 lines/notch, rate 16, 120 fps, min speed 45) | **3 unit tests pass** via bare `rustc --test` |
| `rabble-tui/src/transcript.rs` | synthetic styled 10k-line transcript, `View` widget at the rounded glide position | not built |
| `rabble-tui/src/main.rs` | spike: crossterm, SGR mouse, CSI ?2026 sync output, 120 Hz fixed-cadence clock, `--log FILE` writes `t_ms,draw_ms,pos` per frame, q/Esc quits, Home/End | not built |
| `bench/src/main.rs` | headless render + buffer-diff cost at 120x40, 200x55, 260x70, p50/p99 (target T2: <= 4 ms) | not built |
| `rabble-proto`, `rabble-face` | empty stubs | |

Expect small compile errors; fix them. Then:
1. `cargo run --release -p bench` and record p50/p99 in the plan's targets table.
2. Run the Python baselines (`scripts/bench/ui_loop_lag.py`, `ui_scroll_fps.py`, `ui_face_profile.py`, via `~/.local/share/RaBbLE/rabble-ui/bin/python`) and write them next to the Rust numbers.
3. **Gate T2 on kitty**: `cargo run --release -p rabble-tui -- --log /tmp/glide.csv`, scroll, then check the log for frame gaps (1 s burst, zero dropped frames at 120 Hz = no gap > ~12 ms) and screenshot. **Show Mark the glide live** and ask if the notched feeling is gone. His last words on the 60 fps Python version were "more flowing, still notched"; he has never felt the 120 fps Python version.
4. Kitty cells are 44 px tall, so a cell grid scrolls in whole lines. 120 fps line steps is the ceiling without kitty-graphics pixel scroll (R5b). Tell Mark plainly if he asks for "perfectly smooth".

**Feel decision:** Mark chose **1:1 instant wheel response (Vim / cat)** over the glide; the Rust shell scrolls whole lines on the event, no easing (see the plan). The glide module remains for keyboard paging and A/B. Mouse capture blocks plain terminal selection like Vim does (kitty: Shift+drag); decide copy behaviour in B.

## Step 3: lanes (R0 has passed; start here)
Per the plan: A seam (`orchestra/serve.py` NDJSON over a Unix socket + `rabble-proto`), B shell, C face (`rabble-face` + Python golden dumper in `tests/`), D bench. Builders `sonnet` (pin `model: "sonnet"` on every fan-out), an `opus` reviewer who did not write the lane. Lane C and D can start in R0.

## What changed in the Python engine this session (uncommitted, tests pass: 64 UI + 106 engine)
1. **Crash fix (the "engine" breakage).** `crew: true` in `~/.config/rabble/ui.json` made `roster.build_agents` hand the SDK plain dicts; SDK 0.2.174 runs `asdict()` on each agent, so the message loop died with "asdict() should be called on dataclass instances" and every later send said "Not connected. Call connect() first." Fixed in `ClaudeCodeBackend.options()` (dict -> `AgentDefinition`); roster still returns dicts for the `rabble --cc` wrapper. Test `test_options_agents_are_sdk_dataclasses`. A running `rabble` needs a full restart to pick it up.
2. **Engine config surface** (Mark: "make sure my engine has all the capability I can clone from Claude Code; rabble and sCoRE become my agent harness"). `orchestra/config.py` loads `~/.config/rabble/engine.json` (`$RABBLE_ENGINE_CONFIG`) then `<cwd>/.rabble/engine.json`: `mcp_servers`, `plugins`, `allowed_tools`, `disallowed_tools`, `add_dirs`, `thinking`, `effort`, `max_budget_usd`, `max_turns`, `fallback_model`, `env`; validated, bad entries named on stderr. `/status` ends with a summary. Tests `tests/test_orchestra_config.py`. The audit found only 13 of the SDK's 46 `ClaudeAgentOptions` were wired; not yet exposed: `sandbox`, `skills`, `settings`, `enable_file_checkpointing`, `fork_session`, `output_format`.
3. **`Capabilities` event** (`orchestra/events.py`, emitted from the init message just before `SessionStarted`): slash commands, skills, MCP servers + status, plugins, load failures. The Python app feeds the composer's `/` completion with the real command list and shows MCP/plugin failures as notices; `/status` shows counts. Unknown `/commands` already pass through to Claude Code as typed. The Rust client must handle this event from day one (it is in the contract).

The "no new Python features" rule from S292 is lifted for **engine-side** work Mark asked for; UI work should land in Rust, not Textual, unless it is a fix.

## Mark's new asks, not started
- **More visibility while the model thinks, in plain English.** Today `ev.Thinking(organ)` is a bare marker with no content, and tool cards show raw tool names. Ask: the app narrates what is happening ("reading the config, then checking the tests") and surfaces thinking. This belongs in the **engine** so the Python and Rust UIs share it: a `Narration`/`Status` event stream from `sdk_map.py` (thinking-block text and deltas, tool calls turned into plain sentences, organ activity, waits). **Design question for Mark first:** templated sentences from tool calls (free, instant, predictable), or a cheap Haiku summariser over the thinking text (richer, costs tokens and latency, but "plain English" of reasoning)? Recommend templated first, summariser as an option.
- **Rest of Claude Code parity** (Mark picked config surface first; remaining tiers): session control (`/compact`, `/rewind` via file checkpointing, fork-session, `/cost`, todo/plan display; new events) and skills/plugins as first-class `/commands`.

## Quick start
```bash
cd ~/RaBbLE-Collective
head -20 RaBbLE-Grimoire/log/SESSION-LOG.md            # claim the session number
cat RaBbLE-Grimoire/log/plans/sCoRE-RaBbLE-UI-Rust-Plan.md
git -C RaBbLE-sCoRE status --short                     # tui/, orchestra/config.py etc. are uncommitted
ls /usr/share/cargo/registry | grep -E 'ratatui|crossterm|serde' # empty until layerctl apply claude-code
~/.local/share/RaBbLE/rabble-ui/bin/python -m pytest -q tests/test_orchestra_*.py tests/test_ui_*.py   # from RaBbLE-sCoRE/
```

## Gotchas
- zsh treats a bare `=====` as a command; quote separators in shell one-liners.
- Textual reads `TEXTUAL_FPS` at import; a full `rabble` restart is needed, `/reload` is not enough. Hyprland dispatch is Lua: `hyprctl dispatch "hl.dsp.focus({workspace=N})"`.
- `end-session.sh` still keys the ledger off transcript 94d4f7e8 for this cwd; diff the ledger and LATEST before committing [[project-registry-spell-gotchas]].
- A session that dies without closing can be recovered from `~/.claude/projects/-home-rabble-RaBbLE-Collective/<sid>.jsonl`: the last `user` row is the unanswered message.
