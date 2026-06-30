#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — end-session.sh
# Agent-agnostic end-of-session breadcrumb. Records ONE ledger row tying the
# current session to a feature, so session-tokens.sh --by-feature can attribute
# token spend. Any agent (Claude, Codex, Gemini, …) can call this — no settings
# .json, no agent-specific hooks.
#
# Also auto-writes the ## LATEST block in SESSION-LOG.md when --synopsis is
# given, eliminating the manual step that causes clobber between concurrent
# sessions. Agents should write the dated session entry body, then call this.
#
# Usage:
#   bash spells/end-session.sh <feature-slug> [note] [--synopsis "..."] [--next "..."] [--session "SNN"]
#
#   feature-slug   short kebab tag grouping spend (e.g. os-vmctl, token-tracking)
#   note           optional free text (positional, before flags)
#   --synopsis     one-liner of what this session accomplished (writes ## LATEST)
#   --next         what happens next (written into LATEST; defaults to "see session entry")
#   --session      session label, e.g. "S184" (inferred from SESSION-LOG if omitted)
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
  echo "end-session.sh — agent-agnostic end-of-session token breadcrumb + LATEST auto-write"
  echo ""
  echo "Usage: bash spells/end-session.sh <feature-slug> [note] [--synopsis \"...\"] [--next \"...\"] [--session SNN]"
  echo "  feature-slug   short kebab tag grouping spend (e.g. os-vmctl, token-tracking)"
  echo "  note           optional free text"
  echo "  --synopsis     one-liner summary → auto-writes ## LATEST (eliminates the manual step)"
  echo "  --next         what comes next (written into LATEST; defaults to 'see session entry')"
  echo "  --session      session label e.g. S184 (inferred from SESSION-LOG if omitted)"
  echo ""
  echo "Upserts one row into log/token-ledger.tsv for the current session."
  echo "When --synopsis is given, ## LATEST in log/SESSION-LOG.md is rewritten automatically."
  exit 0
fi

# --- Parse args (positional + flags mixed) ------------------------------------
feature=""
note=""
synopsis=""
next_actions=""
session_label=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --synopsis) synopsis="${2:-}"; shift 2 ;;
    --next)     next_actions="${2:-}"; shift 2 ;;
    --session)  session_label="${2:-}"; shift 2 ;;
    --help|-h)  shift ;;  # handled above
    -*)         echo "Unknown flag: $1" >&2; exit 1 ;;
    *)
      if   [[ -z "$feature" ]]; then feature="$1"
      elif [[ -z "$note"    ]]; then note="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$feature" ]]; then
  echo "Error: feature-slug is required." >&2
  echo "Usage: bash spells/end-session.sh <feature-slug> [note] [--synopsis \"...\"]" >&2
  exit 1
fi

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

# --- Auto-write ## LATEST in SESSION-LOG.md -----------------------------------
# Only runs when --synopsis is given. This removes the manual "hand-write LATEST"
# step from the session protocol, which is the primary source of clobber.
if [[ -z "$synopsis" ]]; then
  exit 0
fi

SESSION_LOG="$GRIMOIRE_ROOT/log/SESSION-LOG.md"
if [[ ! -f "$SESSION_LOG" ]]; then
  echo "Warning: SESSION-LOG.md not found at $SESSION_LOG — LATEST not updated." >&2
  exit 0
fi

# Read phase from epoch yml
epoch_yml="$GRIMOIRE_ROOT/registry/epochs/current.epoch.yml"
if [[ -f "$epoch_yml" ]]; then
  epoch_num=$(grep "^epoch:" "$epoch_yml" | awk '{print $2}')
  ep_pending=$(grep "^episode_pending:" "$epoch_yml" | awk '{print $2}')
  phase="Epoch ${epoch_num} · Episode ${ep_pending}"
else
  phase="Epoch 0 · Episode 1"
fi

# Read open blocker IDs from JSONL (compute live set: open minus resolved)
blocker_file="$GRIMOIRE_ROOT/log/blockers/blockers.jsonl"
open_ids=""
if [[ -f "$blocker_file" ]] && command -v jq &>/dev/null; then
  open_ids=$(jq -rs '
    reduce .[] as $e ({};
      if   $e.event == "open"    then .[$e.id] = true
      elif $e.event == "resolve" then del(.[$e.id])
      else .
      end
    ) | keys | join("/")
  ' "$blocker_file" 2>/dev/null || true)
fi

if [[ -n "$open_ids" ]]; then
  blocker_line="→ \`log/BLOCKERS.md\`. ${open_ids} open."
else
  blocker_line="→ \`log/BLOCKERS.md\`. None open."
fi

# Infer session label from most recent dated entry in SESSION-LOG if not given
if [[ -z "$session_label" ]]; then
  session_label=$(grep -m1 "^## 2[0-9][0-9][0-9]-" "$SESSION_LOG" \
    | sed 's/^## [0-9-]*[[:space:]]*·[[:space:]]*//' \
    | sed 's/ (.*//' \
    | sed 's/[[:space:]]*$//' \
    || true)
  [[ -z "$session_label" ]] && session_label="SNN"
fi

today=$(date +%Y-%m-%d)

# Build new LATEST block in a temp file (avoids awk -v escaping issues)
latest_tmp=$(mktemp)
cat > "$latest_tmp" <<LATEST_EOF
## LATEST — ${today} · ${session_label} (${feature})

**Phase:** ${phase}.
**This session:** ${synopsis}
**Blockers:** ${blocker_line}
**Next:** ${next_actions:-see session entry}

LATEST_EOF

# Replace existing ## LATEST block (from ## LATEST line up to and including the next ---)
log_tmp=$(mktemp)
awk -v ltmp="$latest_tmp" '
  BEGIN { state=0 }
  state==0 && /^## LATEST/ {
    state=1
    while ((getline line < ltmp) > 0) print line
    close(ltmp)
    next
  }
  state==1 && /^---/ { state=2; print; next }
  state==1 { next }
  { print }
' "$SESSION_LOG" > "$log_tmp"
mv "$log_tmp" "$SESSION_LOG"
rm -f "$latest_tmp"

echo "## LATEST updated in SESSION-LOG.md (${session_label}, phase: ${phase})"
