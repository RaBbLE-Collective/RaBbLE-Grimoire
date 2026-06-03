#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — end-session.sh
# Agent-agnostic end-of-session breadcrumb. Records ONE ledger row tying the
# current session to a feature, so session-tokens.sh --by-feature can attribute
# token spend. Any agent (Claude, Codex, Gemini, …) can call this — no settings
# .json, no agent-specific hooks.
#
# Usage:
#   bash spells/end-session.sh <feature-slug> [note]
#
# Resolves the session id from the active Claude transcript for the cwd; if none
# (non-Claude agent), falls back to a git-commit key so the convention still
# holds (token join is Claude-only, but the breadcrumb is recorded either way).
# Upserts: any existing row for this session is replaced.
#
# spark ~ grimoire >> close the loop on what you spent // %END_SESSION%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEDGER="$GRIMOIRE_ROOT/log/token-ledger.tsv"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || -z "${1:-}" ]]; then
  echo "end-session.sh — agent-agnostic end-of-session token breadcrumb"
  echo ""
  echo "Usage: bash spells/end-session.sh <feature-slug> [note]"
  echo "  feature-slug   short kebab tag grouping spend (e.g. os-vmctl, token-tracking)"
  echo "  note           optional free text"
  echo ""
  echo "Upserts one row into log/token-ledger.tsv for the current session."
  exit 0
fi

feature="$1"
note="${2:-}"

# --- Resolve session id -------------------------------------------------------
projdir="$HOME/.claude/projects/$(pwd | tr '/' '-')"
sf=$(ls -t "$projdir"/*.jsonl 2>/dev/null | head -1 || true)
if [[ -n "$sf" ]]; then
  SID=$(basename "$sf" .jsonl)
else
  SID="commit-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)"
  echo "No Claude transcript for $(pwd) — using fallback key '$SID'." >&2
  echo "(Token join is Claude-only; the breadcrumb is still recorded.)" >&2
fi

[[ -f "$LEDGER" ]] || { echo "Ledger not found: $LEDGER" >&2; exit 1; }

# --- Upsert (drop existing rows for SID, append the explicit one) -------------
tmp=$(mktemp)
awk -F'\t' -v s="$SID" '$1 != s' "$LEDGER" > "$tmp"
printf '%s\t%s\t%s\n' "$SID" "$feature" "$note" >> "$tmp"
mv "$tmp" "$LEDGER"

echo "Breadcrumb recorded: $SID -> $feature${note:+  ($note)}"
