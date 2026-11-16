# RaBbLE UI: native `/mcp` (scope for a parallel session)

Date: 2026-11-16 (S343). Status: **scoped, not started.** Mark approved the hand-off approach for authentication.
Repo: `RaBbLE-sCoRE`, `new-horizons`. Touches `tui/` and `orchestra/` only. Does not touch `server/`, so it can run beside AC2 account work.

## Problem

`rabble` is a Rust shell (`tui/rabble-tui`) over a Python engine (`orchestra/`) built on the Claude Agent SDK. Claude Code's built-in `/mcp` does not exist there: typing `/mcp` showed "1 MCP server(s): 0 connected, 0 not connected, 1 disabled" and offered no way to authenticate. Mark could not authorize the Neon MCP server (`plugin:neon:neon`, HTTP, OAuth) from inside rabble and had to find another terminal.

## What exists today

- Engine: `orchestra/sdk_map.py:169-177` builds `ev.Capabilities` from the SDK init message (`mcp_servers` name + status, plugins, problems); `orchestra/events.py:71` defines it; `orchestra/serve.py:232` forwards it; `orchestra/backend.py:206-210` holds one `ClaudeSDKClient` per session (`self.client`); MCP servers also come from `orchestra/config.py` (`mcp_servers`) plus the in-process `rabble` server (`backend.py:181`).
- Wire: `tui/rabble-proto/src/lib.rs:135` `Down::Capabilities { slash_commands, skills, mcp, plugins, problems }` (an mcp entry is `{name, status, tools, info}` in the test at `:478`).
- TUI: `tui/rabble-tui/src/app.rs:672` handles Capabilities (status line shows `mcp up/total`); slash commands dispatch in `app.rs:1410 fn command` (`/model`, `/mode`, `/trust`, `/crew`, `/park`, `/status`, `/help`, `/copy` ...); `base_commands()` feeds completion; `plain.rs:59` has the non-TUI renderer.
- SDK (installed at `~/.local/share/RaBbLE/rabble-ui/lib/python3.14/site-packages/claude_agent_sdk/client.py`): `get_mcp_status()` (`:471`), `reconnect_mcp_server(name)` (`:395`), `toggle_mcp_server(name, enabled)` (`:417`). **There is no authenticate call.**

## Scope

1. **`/mcp` list view.** New `Up::McpStatus` request and `Down::McpStatus` reply (rabble-proto). Engine calls `client.get_mcp_status()` and returns per server: name, scope/source (user, project, plugin), transport and URL (redact any `?key=`/token query), status (`connected`, `pending`, `needs-auth`, `failed`, `disabled`), tool count, error text. TUI renders it as a panel in the existing Aether/theme style; keys: up/down select, `r` reconnect, `e`/`d` enable/disable, `a` authenticate (below), `esc` close. Also `/mcp <name>` for one server's tools.
2. **Reconnect / enable / disable.** `Up::McpReconnect { name }`, `Up::McpToggle { name, enabled }` mapped to the SDK calls; refresh the list and the `mcp up/total` status line after each (the Capabilities line is only sent at session start today, so it must be refreshed on change).
3. **Authenticate (hand-off).** For a server in `needs-auth`: the TUI suspends the alternate screen and runs a real `claude` interactively in the project directory for the OAuth sign-in (Claude Code's own `/mcp` flow stores the token in the user credential store, `~/.claude/.credentials.json`, which the headless claude process reads), then restores the screen, calls `reconnect_mcp_server`, and shows the new status. Fallback text if `claude` is not on PATH: print the exact command to run in another terminal. Do **not** reimplement the OAuth dance (client registration, PKCE, writing Claude's private credentials): it breaks whenever Claude changes that format. If Mark later wants native OAuth, scope it separately.
4. **Why the Neon server read "disabled":** find out (a toggle in rabble's config? `orchestra/config.py` merge? the plugin's server marked disabled by the SDK?) and make the list show the real reason. Acceptance includes enabling it from `/mcp`.
5. **Plain mode** (`plain.rs`): `/mcp` prints the same list as text; no panel, no auth hand-off, print the manual command.

## Not in scope

Adding or editing MCP server definitions from the UI (config stays in `orchestra/config.py` / Claude settings); a full tool browser; OAuth implemented natively; anything in `server/`.

## Build and verify

- Build with **CoBbLE** (one organ: the proto message pair must match on both sides). **NiBbLE** reviews the diff (secrets in URLs, terminal restore after the hand-off, SDK call failures). **CrumBbLE** runs it: `cargo test` in `tui/`, engine tests under `tests/test_orchestra_*`, then drive a real rabble against the engine with the Neon server toggled and (if possible) deliberately signed out. Per the memory rule, no live-desktop driving (no wtype/dispatch on Mark's session): use the `rabble` test mode / a nested session or the engine's replay backend (`orchestra/backend.py ReplayBackend`).
- Add Rust tests for the new proto frames (pattern at `lib.rs:478`), Python tests for the SDK mapping with a fake client, and a TUI unit test for the panel's key handling.
- Done = `/mcp` lists every server with a real status; reconnect and toggle work and update the status line; `a` on a needs-auth server leaves rabble, runs `claude`, returns, and the server shows connected; plain mode prints the list; tests pass; `cargo build --release` in `tui/` succeeds (the launcher uses the release binary).

## Read first

`tui/rabble-tui/src/app.rs` (`command`, `base_commands`, Capabilities handler), `tui/rabble-proto/src/lib.rs`, `orchestra/backend.py`, `orchestra/sdk_map.py`, `orchestra/serve.py`, `log/handoffs/HANDOFF-S340-RaBbLE-TUI-Parity.md` (parity batch conventions), memory `feedback_no_live_desktop_testing`.
