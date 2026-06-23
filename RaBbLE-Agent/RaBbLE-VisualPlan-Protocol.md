# RaBbLE-VisualPlan-Protocol.md — Visual Planning for RaBbLE Agents

```
transcribe ~ grimoire >> visual-plan protocol established // %VISUALPLAN_PROTOCOL%
```

> How RaBbLE agents create, save, and log Agent-Native Visual Plans.
> Self-hosted local server — no cloud dependency, no agent-native.com.
> See also: [RaBbLE-Agent-Protocols](RaBbLE-Agent-Protocols.md) — agent behavioral rules
> Plan archive: `log/plans/` — exported MDX artifacts from completed plans

---

## What This Is

The `/visual-plan` skill creates structured planning artifacts — scannable documents
with inline diagrams, wireframes, annotated code, open questions, and an optional
top visual canvas. Use it for any work where direction needs review before code is
written, and a reviewable artifact beats a chat paragraph.

**Skip it for:** one-line fixes, typo corrections, single well-specified functions,
anything whose diff fits in one sentence.

---

## Infrastructure — Self-Hosted Local Server

RaBbLE runs its own plan server. No data ever leaves the machine.

```
App:  /opt/rabble/plans (Next.js + SQLite)
      ├── data/plans.db     ← all plan storage (local only)
      └── build/            ← compiled server

Service:  rabble-plans (systemd user unit)
          Node.js on port 3001 (internal)

Proxy:    nginx on port 3000 (public face)
          /_rabble/  →  proxies to /_agent-native/ on app
          (no "_agent-native" ever appears in agent config or URLs)

MCP:      http://localhost:3000/_rabble/mcp
          Registered as "rabble-plans" in ~/.claude/claude_code_config.json

Plan UI:  http://localhost:3000
Theme:    Aether palette injected into app CSS (ansible managed)
```

Deployed via: `RaBbLE-OS/ansible/roles/apps/plans/`
Config source: `RaBbLE-OS/ansible/roles/apps/plans/defaults/main.yml`

---

## Installation Status Check

```bash
# Is the service installed and running?
systemctl --user status rabble-plans

# Is the MCP registered with Claude Code?
cat ~/.claude/claude_code_config.json | python3 -m json.tool

# Is the plan UI reachable?
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/

# Is /opt/rabble/plans scaffolded?
ls /opt/rabble/plans/package.json 2>/dev/null && echo "installed" || echo "not installed"
```

**If not installed:** run the Ansible role (from `RaBbLE-Collective/RaBbLE-OS/`):
```bash
ansible-playbook ansible/site.yml --tags plans
```
Then restart Claude Code and run `/mcp` → Reconnect to pick up the `rabble-plans` server.

---

## Skill Installation

The `/visual-plan` skill is installed via the `builder-skills.yml` Ansible task:
```
~/.claude/skills/visual-plan/agent-native-skill.json
  → mcpUrl: "https://plan.agent-native.com/_agent-native/mcp"  (default, overridden by local)
```

When the local server is running and `claude_code_config.json` registers `rabble-plans`,
Claude Code routes `mcp__plan__*` tool calls to `http://localhost:3000/_rabble/mcp`.
The hosted URL in `agent-native-skill.json` is the upstream default; the local MCP
registration takes precedence.

**Do not reconnect to `plan.agent-native.com`.** If `/mcp` shows the plan server
needing auth, ensure `rabble-plans` is running and registered in `claude_code_config.json`.

---

## Creating a Plan

### 1. Verify service is up
```bash
systemctl --user status rabble-plans
```

### 2. Invoke the skill in Claude Code
```
/visual-plan
```
The skill:
- Researches the codebase (reads files, explores patterns)
- Chooses the plan type: `create-visual-plan` (architecture/backend/data),
  `create-ui-plan` (product UI), `create-prototype-plan` (interactive flows)
- Sends plan to the local server via `mcp__plan__*` tools
- Returns a link: `http://localhost:3000/<plan-id>`

### 3. Review and approve
Open the link in the browser. Comment, mark as approved. The plan is the gate —
implementation begins only after approval.

---

## Plan Types

| Type | When |
|---|---|
| `create-visual-plan` | Architecture, backend, data, refactor — no UI canvas needed |
| `create-ui-plan` | Primarily product UI — canvas with wireframe artboards first |
| `create-prototype-plan` | Multi-step flows where reviewer needs to click through |

Architecture-only plans get no canvas — only inline `diagram`, `data-model`,
`api-endpoint`, or `code` blocks in the document body.

---

## Exporting and Logging Plans (Grimoire Archive)

Plans live in the local SQLite DB. Export approved plans to `log/plans/` for
version control and session traceability.

### Export after approval
```
export-visual-plan   ← MCP tool (available after /visual-plan)
```
This returns MDX files. Save them to `log/plans/<slug>/`.

### Slug naming
Format: `<impulse>-<organ>-<topic>-S<session>`
```
spark-os-boot-chain-S156
harmonize-world-rc1-polish-S142
mend-score-auth-flow-S138
```

### Commit to Grimoire
```bash
git add RaBbLE-Grimoire/log/plans/<slug>/
git commit -m "transcribe ~ grimoire >> visual plan: <slug> // %PLANS_ARCHIVE%"
```

### Log in SESSION-LOG
Add one line under the current session block in `log/SESSION-LOG.md`:
```
Plan: log/plans/<slug>/ — <one-sentence description>
```

---

## Service Management

```bash
systemctl --user start rabble-plans      # start
systemctl --user stop rabble-plans       # stop
systemctl --user restart rabble-plans    # restart
systemctl --user status rabble-plans     # check
journalctl --user -u rabble-plans -f     # live logs
```

Data lives at `/opt/rabble/plans/data/plans.db` — do not delete without exporting.

---

## Re-Deploying / Updating

```bash
# From RaBbLE-Collective/RaBbLE-OS/
ansible-playbook ansible/site.yml --tags plans
```

Tag subsets:
```bash
--tags plans,install    # scaffold + build only
--tags plans,theme      # re-inject Aether CSS + rebuild
--tags plans,service    # reinstall systemd unit
--tags plans,proxy      # nginx config only
--tags plans,mcp        # re-register MCP in claude_code_config.json
```

After MCP re-registration, restart Claude Code and run `/mcp` → Reconnect.

---

## Quick Reference

```bash
# Check
systemctl --user status rabble-plans
curl http://localhost:3000/

# Deploy (first time or updates)
cd RaBbLE-Collective/RaBbLE-OS/
ansible-playbook ansible/site.yml --tags plans

# Use
/visual-plan  (in Claude Code — routes to local server)

# Export + log
export-visual-plan → save to log/plans/<slug>/
git add + commit → "transcribe ~ grimoire >> visual plan: <slug>"
```
