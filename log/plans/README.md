# RaBbLE-Grimoire/log/plans — Visual Plan Archive

```
transcribe ~ grimoire >> visual plan archive established // %PLANS_ARCHIVE%
```

Visual plan exports from active and completed sessions live here as MDX artifacts.
Plans are **created** in the local self-hosted plan server and **exported** here for
version control and Grimoire logging. One subdirectory per plan: `log/plans/<slug>/`.

## Markdown handoff plans

Flat `*.md` files in this dir are cold-start handoffs for multi-session work — plain
markdown, not MDX exports. Read these to resume an in-flight effort:

| Plan | Status |
|---|---|
| `OS-VM-Dev-Flow.md` | 🟡 VM install unblocked (branch parameterized); cast VM + boot-theme loop pending |
| `OS-Plymouth-Black-Screen.md` | 🎯 Root cause found (S166 ternary); awaiting visual verify |
| `OS-Dolphin-Grey-Text.md` | 🔴 Labels dim ≈#656769 regardless of focus. Stack confirmed (Kvantum [GeneralColors] is sole palette source). no_inactiveness DISPROVEN. Next: PyQt6 palette dump → Fix Path A (disabled.text.color) or B (qt6ct custom_palette) |

## Architecture

The RaBbLE Plans server is a self-hosted, fully local Next.js app:

```
/opt/rabble/plans/                   ← app source + build
  data/plans.db                      ← SQLite (all plan data, local only)

systemd user service: rabble-plans   ← app on port 3001
nginx proxy: port 3000               ← public face, /_rabble/ alias
MCP endpoint: http://localhost:3000/_rabble/mcp
Plan UI:      http://localhost:3000
```

Deployed via Ansible: `RaBbLE-OS/ansible/roles/apps/plans/`
MCP registered in: `~/.claude/claude_code_config.json` (as `rabble-plans`)

## Convention

```
log/plans/
  <session-slug>/          ← one exported plan per slug
    plan.mdx               ← main document (always present)
    canvas.mdx             ← optional: static wireframe artboards
    prototype.mdx          ← optional: interactive prototype
    .plan-state.json       ← optional: block/annotation state
```

## Naming

Slugs follow `<impulse>-<organ>-<topic>-S<session>`:
- `spark-os-boot-chain-S156`
- `harmonize-world-rc1-polish-S142`

## Workflow

```bash
# 1. Check service is running
systemctl --user status rabble-plans

# 2. Create plan (in Claude Code)
/visual-plan

# 3. After approval, export to Grimoire
#    In Claude Code: use export-visual-plan tool → writes MDX
#    OR: copy MDX folder from plan UI → log/plans/<slug>/

# 4. Commit artifact
git add log/plans/<slug>/
git commit -m "transcribe ~ grimoire >> visual plan: <slug> // %PLANS_ARCHIVE%"

# 5. Log in SESSION-LOG.md
# Plan: log/plans/<slug>/ — <one-sentence description>
```

## Service Management

```bash
systemctl --user start rabble-plans      # start
systemctl --user stop rabble-plans       # stop
systemctl --user status rabble-plans     # check
journalctl --user -u rabble-plans -f     # logs

# Re-deploy via Ansible (from RaBbLE-OS/)
ansible-playbook ansible/site.yml --tags plans
```
