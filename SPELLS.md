# RaBbLE Grimoire Spells

```
transcribe ~ grimoire >> the incantations that manifest realms // %SPELLS_INITIALIZED%
```

Spells are the bash scripts in `spells/` that manage the RaBbLE Collective from Grimoire as the single source of truth — cloning members, wiring symlinks, checking health, and (eventually) propagating canonical docs.

**Key principle:** Grimoire is the source. Spells are the distribution mechanism. Never duplicate Grimoire content in member repos.

---

## Implemented Spells

### `spells/status.sh` — Collective Health Dashboard

Shows the state of all registered members at a glance.

```bash
bash spells/status.sh
```

**What it shows:**
- Epoch name and number (from `registry/epochs/current.epoch.yml`)
- Grimoire itself: branch, clean/modified state
- Each registered member: branch, git state, whether AGENT.md is present
- Palette version consistency across manifests

**Reads:** `registry/manifests/*.manifest.yml`, `registry/epochs/current.epoch.yml`

---

### `spells/setup.sh` — Bootstrap the Collective

Clones or updates all registered member repos, sets up CLAUDE.md and CODEX.md symlinks (→ AGENT.md), and optionally syncs common docs.

```bash
bash spells/setup.sh              # full setup: pull all + wire symlinks
bash spells/setup.sh --links-only  # symlinks only, no pulls
bash spells/setup.sh --pull-only   # pull/update only, no symlink changes
bash spells/setup.sh --project RaBbLE-OS  # single project
```

**Grimoire does not relocate itself.** This script runs from wherever Grimoire lives and sets up member repos as neighbors in `$RABBLE_ROOT/`.

**Reads:** `registry/manifests/*.manifest.yml`
**Writes:** symlinks in member repo roots

---

### `spells/init-project.sh` — Scaffold a New Member

Creates a new Collective member repo with standard scaffolding: AGENT.md, CONTEXT.md, REFERENCES.md, workspace CONTEXT.md files, and a manifest entry.

```bash
bash spells/init-project.sh --slug RaBbLE-[Name] --role [substrate|server|frontend|tooling]
```

After running: add the member to `AGENT.md` Member Registry table and push to GitHub.

---

### `spells/sync-grimoire.sh` — Propagate Common Docs

> **Status: Propagation mechanism TBD.** The doc propagation model (submodule vs. push vs. install) is still being decided. This script copies `RaBbLE-Agent/` docs to member `grimoire/` directories, but whether members maintain local copies or reference Grimoire directly is an open question. Use `--dry-run` to see what would change before committing to a model.

```bash
bash spells/sync-grimoire.sh                      # sync all opted-in members
bash spells/sync-grimoire.sh --project RaBbLE-OS  # single project
bash spells/sync-grimoire.sh --dry-run            # preview only
```

Members opt in via `grimoire_sync: true` in their manifest. Docs synced are listed in the `COMMON_DOCS` array at the top of the script.

---

### `spells/install-theme.sh` — Install RaBbLE Theme

Installs the RaBbLE synthwave outrun theme across OS-level components. RaBbLE-OS specific.

```bash
bash spells/install-theme.sh
```

---

### `spells/visual-screenshot.sh` — Agent Visual Capture

Lets an agent **see** rendered output. Opens a URL in Firefox on a clean scratch workspace (default: workspace 9), captures the monitor with `grim`, then closes Firefox and returns to the original workspace. Prints a machine-readable `SCREENSHOT: /path` line so agents can read the image back directly.

General-purpose: point it at any dev server or local HTML file. Modify `--delay` for pages that need more load time.

```bash
# Capture default dev server — opens on scratch workspace 9, closes, returns
bash spells/visual-screenshot.sh

# Specific page
bash spells/visual-screenshot.sh --url http://localhost:8000/world/Boot.html

# Custom output path
bash spells/visual-screenshot.sh --url http://localhost:8000 --out ./shot.png

# More render time for heavy pages or animations
bash spells/visual-screenshot.sh --url http://localhost:8000 --delay 5

# Use a different scratch workspace
bash spells/visual-screenshot.sh --url http://localhost:8000 --workspace 8
```

**Agent usage pattern:**
1. Make code change
2. `npm run build:iife && bash spells/visual-screenshot.sh --url http://localhost:8000`
3. Read the path from the `SCREENSHOT: /path` line — Claude Code reads PNG files directly
4. Verify the change visually, iterate

**Output:** `~/RaBbLE-Collective/RaBbLE-Captures/visual-TIMESTAMP.png` (gitignored).  
**Requires:** `hyprctl`, `firefox`, `grim`, active Hyprland session (RaBbLE-OS). `jq` optional (improves monitor and workspace targeting).

---

## Planned (Not Yet Implemented)

These were in the original SPELLS.md framework spec. Deferred until the propagation mechanism is decided:

| Spell | Purpose |
|---|---|
| `spells/generate-llm-context.py` | Compose CONTEXT.md from Grimoire sections for a specific member |
| `spells/generate-agent-brief.py` | Create focused agent context for a specific task |
| `spells/health-check.py` | Detailed health report with version compatibility matrix |
| `spells/fetch-remotes.py` | Verify all manifest repos are reachable |

---

## Spell Authoring Conventions

- All spells use `GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` as root
- `RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"` is the parent containing all member repos
- Scripts must not relocate the Grimoire — it expands, not moves
- Headers: `# RaBbLE-Grimoire — {script-name}`
- Pulse Protocol commit when adding/modifying spells: `spark ~ grimoire >> ...`

---

```
transcribe ~ grimoire >> spells documented // %SPELLS_LOCKED%
```
