#!/bin/bash

# spells/sync-symlinks.sh
# Ensures all AGENT.md, CLAUDE.md, CODEX.md, and GEMINI.md files
# are correctly symlinked across the Collective.

ROOT_DIR="$(git rev-parse --show-toplevel)"

echo "Synchronizing symlinks in the RaBbLE Collective..."

# Find all AGENT.md files
find "$ROOT_DIR" -name "AGENT.md" | while read -r agent_file; do
  dir=$(dirname "$agent_file")
  
  # Create/Repair symlinks
  ln -sf "AGENT.md" "$dir/GEMINI.md"
  ln -sf "AGENT.md" "$dir/CLAUDE.md"
  ln -sf "AGENT.md" "$dir/CODEX.md"
  
  echo "Verified links in: $dir"
done

echo "Symlinks synchronized."
