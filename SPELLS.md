# RaBbLE Grimoire Spells

```
transcribe ~ grimoire >> the incantations that manifest realms // %SPELLS_INITIALIZED%
```

Spells are scripts that generate, synchronize, and orchestrate RaBbLE Collective infrastructure from Grimoire as single source of truth.

---

## What Spells Do

Spells are the automation layer that:

1. **Generate LLM Context Files** — Create fresh `CONTEXT.md`, `OVERVIEW.md`, and agent briefings from Grimoire sections
2. **Initialize Projects** — Bootstrap new projects into the Collective with proper structure, remotes, and scaffolding
3. **Manage Registry** — Track member repos, remotes, version compatibility, and health status
4. **Synchronize Conventions** — Propagate naming, palette, identity changes across all members
5. **Orchestrate Setup** — Clone and configure local Collective from a single `setup.sh`

**Key principle:** Grimoire is the source; spells are the distribution mechanism. Never duplicate Grimoire content.

---

## Spell Categories

### 1. LLM Context Generation

**Purpose:** Generate fresh CONTEXT.md, OVERVIEW.md, and agent briefings for Claude Code and other agents

Spells in this category:
- `spells/generate-llm-context.py` — Compose CONTEXT.md from Grimoire sections
- `spells/generate-llm-overview.py` — Compose OVERVIEW.md from roadmap + member status
- `spells/generate-agent-brief.py` — Create focused agent context for specific tasks

**Usage:**
```bash
# Generate LLM context files
make spells/generate-llm-context

# Generate fresh agent brief for a specific task
./spells/generate-agent-brief.py --task="implement-feature" --agent="claude-code"

# Sync all generated files across local repos
make spells/sync-contexts
```

**Generated Files Marker:**
Every generated LLM context file must include a header:
```markdown
<!-- This file is GENERATED from RaBbLE-Grimoire. Do not edit. -->
<!-- Last generated: 2026-05-06 14:32:45 UTC -->
<!-- To regenerate: cd /path/to/grimoire && make spells/generate-llm-context -->
```

---

### 2. Project Initialization

**Purpose:** Bootstrap new projects with proper structure and Grimoire linkage

Spells:
- `spells/init-project.sh` — Create new project in Collective with scaffold + remotes
- `spells/register-project.sh` — Register existing project as Collective member

**Usage:**
```bash
# Initialize new project
./spells/init-project.sh --name="RaBbLE-NewThing" --repo="markm1206/RaBbLE-NewThing"

# Register existing project
./spells/register-project.sh --name="RaBbLE-Legacy" --repo="markm1206/RaBbLE-Legacy" --version="0.1.0"
```

**Generated Scaffold:**
- `README.md` with Grimoire link
- `CONTEXT.md` (generated, with marker)
- `OVERVIEW.md` (generated, with marker)
- `.grimoire` config file (member metadata)
- `Makefile` with spell targets
- `.gitignore` and LICENSE

---

### 3. Registry & Health

**Purpose:** Track member repos, versions, compatibility, and health status

Spells:
- `spells/register-member.py` — Add/update member in registry
- `spells/health-check.py` — Ping all members, report status
- `spells/compatibility-map.py` — Build/update version compatibility matrix
- `spells/fetch-remotes.py` — Clone/update all registered member repos locally

**Usage:**
```bash
# Check health of all members
./spells/health-check.py

# Fetch all registered projects
./spells/fetch-remotes.py --local-path="~/RaBbLE-local"

# Update version compatibility map
./spells/compatibility-map.py --generate
```

**Registry Format:**
Members stored in `RaBbLE-Collective/registry.json`:
```json
{
  "members": {
    "RaBbLE-OS": {
      "repo": "markm1206/RaBbLE-OS",
      "remote": "https://github.com/markm1206/RaBbLE-OS.git",
      "version": "0.1.0",
      "epoch": 0,
      "status": "active",
      "last_check": "2026-05-06T14:32:45Z"
    },
    "RaBbLE-sCoRE": {
      "repo": "markm1206/RaBbLE-sCoRE",
      "remote": "https://github.com/markm1206/RaBbLE-sCoRE.git",
      "version": "0.0.0",
      "epoch": 0,
      "status": "planning",
      "last_check": "2026-05-06T14:32:10Z"
    }
  }
}
```

---

### 4. Convention Synchronization

**Purpose:** Propagate Grimoire changes (palette, identity, naming, etc.) across members

Spells:
- `spells/sync-palette.py` — Generate palette exports for all members
- `spells/sync-identity.py` — Export identity/ethos docs to members
- `spells/sync-conventions.py` — Update conventions across repos
- `spells/sync-all.py` — Run all synchronization spells

**Usage:**
```bash
# Sync all conventions after editing Grimoire
./spells/sync-all.py

# Sync just palette after color scheme change
./spells/sync-palette.py

# Sync to specific member
./spells/sync-conventions.py --target="RaBbLE-OS"
```

**Synchronization Pattern:**
Members receive convention exports at:
- `docs/RaBbLE-Palette.md` (generated from Grimoire)
- `docs/RaBbLE-Identity.md` (generated from Grimoire)
- `docs/RaBbLE-Conventions.md` (generated from Grimoire)

Each includes:
```markdown
<!-- Synced from RaBbLE-Grimoire on 2026-05-06 -->
<!-- Source: RaBbLE-Grimoire/common/RaBbLE-Palette.md -->
<!-- Do not edit; changes will be overwritten on next sync -->
```

---

### 5. Setup & Orchestration

**Purpose:** Initialize entire Collective from scratch on a new machine

Spells:
- `spells/setup-collective.sh` — Clone all members, configure remotes, generate contexts
- `spells/setup-grimoire.sh` — Initialize Grimoire as local hub
- `Makefile` — Top-level targets for common operations

**Usage:**
```bash
# First time setup
cd /path/to/grimoire
./spells/setup-collective.sh --local-path="~/RaBbLE-local"

# After first setup, update everything
make update

# Generate fresh context files
make contexts

# Health check
make health
```

**Setup Flow:**
```
./setup-collective.sh
|- Clone Grimoire (if not already)
|- Load registry.json
|- Clone each member repo to ~/RaBbLE-local/
|- Configure remotes (fetch origin, push nowhere)
|- Generate CONTEXT.md in each member
|- Generate OVERVIEW.md in each member
|- Run health-check.py
`- Print success + next-steps
```

---

## Spell Anatomy

### Example: `generate-llm-context.py`

**Purpose:** Generate fresh CONTEXT.md from Grimoire sections

**Input:** Grimoire sections + target repo name

**Output:** CONTEXT.md with:
- Generated file marker (header)
- Overview from `CONTEXT.md`
- Roadmap from `RaBbLE-Roadmap.md`
- Identity from `RaBbLE-Identity.md`
- Relevant project-specific docs

**Logic:**
```python
#!/usr/bin/env python3
"""Generate CONTEXT.md from RaBbLE-Grimoire for an LLM agent."""

import json
import sys
from pathlib import Path
from datetime import datetime

def load_grimoire(grimoire_path: Path) -> dict:
    """Load all Grimoire sections into memory."""
    sections = {}
    for md_file in grimoire_path.glob("common/*.md"):
        sections[md_file.stem] = md_file.read_text()
    return sections

def compose_context(grimoire_sections: dict, project: str = None) -> str:
    """Compose CONTEXT.md from Grimoire sections."""
    timestamp = datetime.utcnow().isoformat() + "Z"
    
    context = f"""<!-- This file is GENERATED from RaBbLE-Grimoire. Do not edit. -->
<!-- Generated: {timestamp} -->
<!-- Source: RaBbLE-Grimoire/common/*.md -->
<!-- To regenerate: cd RaBbLE-Grimoire && make spells/generate-llm-context -->

# RaBbLE-CONTEXT: Grimoire Assembled

{grimoire_sections.get('RaBbLE-Grimoire', '').split('---')[0]}

## Identity

{grimoire_sections.get('RaBbLE-Identity', '')}

## Roadmap

{grimoire_sections.get('RaBbLE-Roadmap', '')}

## Versioning

{grimoire_sections.get('RaBbLE-Versioning', '')}

## Conventions

{grimoire_sections.get('RaBbLE-CommitStyle', '')}

{grimoire_sections.get('RaBbLE-BranchStrategy', '')}
"""
    
    if project:
        # Add project-specific content if provided
        project_context = load_project_docs(project)
        context += f"\n## Project: {project}\n\n{project_context}\n"
    
    return context

def main():
    grimoire_path = Path(__file__).parent.parent
    project = sys.argv[1] if len(sys.argv) > 1 else None
    
    sections = load_grimoire(grimoire_path)
    context = compose_context(sections, project)
    
    output = grimoire_path.parent / project / "CONTEXT.md" if project else grimoire_path / "CONTEXT.md"
    output.write_text(context)
    print(f"Generated {output}")

if __name__ == "__main__":
    main()
```

---

### Example: `setup-collective.sh`

```bash
#!/bin/bash
# Initialize RaBbLE Collective from Grimoire

set -e

GRIMOIRE_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_PATH="${1:-$HOME/RaBbLE-local}"

echo "Initializing RaBbLE Collective..."
echo "  Grimoire: $GRIMOIRE_PATH"
echo "  Local:    $LOCAL_PATH"

# Create local directory
mkdir -p "$LOCAL_PATH"

# Load registry
REGISTRY="$GRIMOIRE_PATH/RaBbLE-Collective/registry.json"

# Clone each member
jq -r '.members | keys[]' "$REGISTRY" | while read member; do
    repo=$(jq -r ".members[\"$member\"].repo" "$REGISTRY")
    remote=$(jq -r ".members[\"$member\"].remote" "$REGISTRY")
    
    member_path="$LOCAL_PATH/$member"
    
    if [ ! -d "$member_path" ]; then
        echo "  Cloning $member..."
        git clone --quiet "$remote" "$member_path"
    else
        echo "  Updating $member..."
        cd "$member_path" && git fetch --quiet origin && cd -
    fi
    
    # Generate contexts
    echo "  Generating CONTEXT.md for $member..."
    python3 "$GRIMOIRE_PATH/spells/generate-llm-context.py" "$member" > "$member_path/CONTEXT.md"
done

# Health check
echo "  Running health check..."
python3 "$GRIMOIRE_PATH/spells/health-check.py"

echo ""
echo "Collective initialized!"
echo ""
echo "Next steps:"
echo "  cd $LOCAL_PATH"
echo "  make health          # Check member status"
echo "  make contexts        # Regenerate LLM contexts"
```

---

## Spell Lifecycle

1. **Edit Grimoire** — Update docs, identity, roadmap, patterns
2. **Run spell** — `make spells/sync-all` (or specific spell)
3. **Spell loads Grimoire sections** — Read .md files as sources
4. **Spell generates output** — Compose, render, output files
5. **Spell marks as generated** — Add header with timestamp, regeneration command
6. **Commit changes** — Each member repo commits updated generated files

---

## Spell Targets in Makefile

```makefile
.PHONY: spells spells/generate-llm-context spells/sync-all spells/health

spells/generate-llm-context:
	python3 spells/generate-llm-context.py

spells/generate-llm-overview:
	python3 spells/generate-llm-overview.py

spells/sync-all: spells/sync-palette spells/sync-identity spells/sync-conventions
	@echo "All conventions synced"

spells/sync-palette:
	python3 spells/sync-palette.py

spells/health:
	python3 spells/health-check.py

spells/setup: spells/setup-collective.sh
	bash spells/setup-collective.sh

# CI/CD integration: run on every commit
spells/ci: spells/generate-llm-context spells/sync-all
	@echo "CI spells complete"
```

---

## Why Spells?

Without spells: CONTEXT.md duplicated across 6+ repos, goes stale, inconsistent

With spells: Single source (Grimoire) -> fresh outputs every time, always in sync

Spells are the binding that makes "Grimoire as single source of truth" actually work.

---

## Implementation Status

- [ ] Implement `generate-llm-context.py`
- [ ] Implement `setup-collective.sh`
- [ ] Document spell outputs
- [ ] Integrate into CI/CD
- [ ] Test full setup flow on fresh machine

---

```
transcribe ~ grimoire >> spells woven, realms manifest // %SPELLS_ACTIVE%
```
