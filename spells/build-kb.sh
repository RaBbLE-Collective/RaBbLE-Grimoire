#!/usr/bin/env bash
# build-kb.sh — regenerate the flat Grimoire KB bundle (for Claude.ai web KB upload)
#
# Usage:
#   bash spells/build-kb.sh
#
# Concatenates canonical Grimoire docs into ~16 self-contained Markdown bundles
# suitable for uploading to a Claude.ai project knowledge base. Delegates to
# build-kb.py (kept in Python — string/file wrangling; no win to a bash rewrite).
#
# Output: generated/grimoire-kb/ (in this repo, gitignored) — not canonical.
# The Grimoire repo remains the source of truth; this is an exportable
# snapshot for surfaces (like Claude.ai web) that can't read the repo
# directly. See RaBbLE-Collective/RaBbLE-Grimoire-MCP.md for the live
# (non-snapshot) successor to this workflow.
#
# Run from: RaBbLE-Grimoire/ root

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "build-kb.sh — regenerate the flat Grimoire KB bundle"
  echo ""
  echo "Usage: bash spells/build-kb.sh"
  echo ""
  echo "Concatenates canonical Grimoire docs into ~16 Markdown bundles for upload"
  echo "to a Claude.ai project knowledge base."
  echo ""
  echo "Output: generated/grimoire-kb/ in this repo (gitignored)."
  echo "Bundle map lives in spells/build-kb.py — edit BUNDLES there to change scope."
  exit 0
fi

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 not found."
  exit 1
fi

python3 "$GRIMOIRE_ROOT/spells/build-kb.py"

echo ""
echo "Output is gitignored (generated/ in the Grimoire repo) — nothing to commit."
