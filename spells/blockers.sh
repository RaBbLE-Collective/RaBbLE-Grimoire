#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — blockers.sh
# Durable, append-only blocker ledger. Blockers used to live ONLY in the 75-word
# ## LATEST box in SESSION-LOG.md — which is rewritten every session, so open/
# resolved state was lost between sessions (clobbered). This is the persistent
# home: events accumulate, nothing is overwritten, and BLOCKERS.md is generated
# from them.
#
# AGENT-AGNOSTIC: same session-id resolution as decision-log.sh / end-session.sh
# (RABBLE_SESSION_ID -> Claude transcript -> git-commit fallback).
#
# Source of truth : log/blockers/blockers.jsonl   (append-only event stream)
# Rendered view   : log/BLOCKERS.md               (generated — never hand-edit)
#
# Usage:
#   bash spells/blockers.sh add "<summary>" [--owner X] [--tag T]... [--severity S] [--since SNNN]
#   bash spells/blockers.sh resolve <id> ["<note>"]
#   bash spells/blockers.sh ls [--all]
#   bash spells/blockers.sh sync          # regenerate log/BLOCKERS.md from the stream
#   bash spells/blockers.sh open-count [--tag T]   # bare integer (status.sh consumes this)
#
# Events: open | resolve. A blocker's current state = its latest event by id.
# Each `add` appends a new B-NN; `resolve <id>` closes it. To re-open, `add` anew.
#
# spark ~ grimoire >> blockers outlive the session box // %BLOCKER_LEDGER%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLOCKERS_DIR="$GRIMOIRE_ROOT/log/blockers"
STREAM="$BLOCKERS_DIR/blockers.jsonl"
RENDERED="$GRIMOIRE_ROOT/log/BLOCKERS.md"
mkdir -p "$BLOCKERS_DIR"
[[ -f "$STREAM" ]] || : > "$STREAM"

# --- Colors (match decision-log.sh / status.sh) -------------------------------
GREEN='\033[38;2;80;250;123m'
CYAN='\033[38;2;0;245;255m'
YELLOW='\033[38;2;241;250;140m'
MAGENTA='\033[38;2;255;45;120m'
VIOLET='\033[38;2;191;95;255m'
RED='\033[38;2;255;85;85m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RESET='\033[0m'

# --- Resolve session id (mirrors decision-log.sh) -----------------------------
resolve_session_id() {
  if [[ -n "${RABBLE_SESSION_ID:-}" ]]; then echo "$RABBLE_SESSION_ID"; return; fi
  local cand projdir sf
  for cand in "$(dirname "$GRIMOIRE_ROOT")" "$GRIMOIRE_ROOT"; do
    projdir="$HOME/.claude/projects/$(echo "$cand" | tr '/' '-')"
    sf=$(ls -t "$projdir"/*.jsonl 2>/dev/null | head -1 || true)
    if [[ -n "$sf" ]]; then basename "$sf" .jsonl; return; fi
  done
  local commit
  commit=$(git -C "$GRIMOIRE_ROOT" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d)
  echo "commit-${commit}"
}

detect_agent_kind() {
  if [[ -n "${CLAUDE_CODE_ENTRYPOINT:-}" || ( -n "${ANTHROPIC_API_KEY:-}" && -d "$HOME/.claude" ) ]]; then
    echo "claude"
  elif [[ -n "${OPENAI_API_KEY:-}" ]]; then echo "codex"
  elif [[ -n "${GOOGLE_API_KEY:-}" || -n "${GEMINI_API_KEY:-}" ]]; then echo "gemini"
  else echo "unknown"; fi
}

# latest event per id, in id order — the canonical "current state" projection
latest_by_id() { jq -s 'group_by(.id) | map(.[-1]) | sort_by(.id)' "$STREAM"; }

next_id() {
  local n
  n=$(jq -r '.id // "B-0"' "$STREAM" 2>/dev/null \
        | sed 's/^B-//' | sort -n | tail -1)
  n=${n:-0}
  printf 'B-%02d' "$((n + 1))"
}

# =============================================================================
# COMMANDS
# =============================================================================

cmd_add() {
  local summary="" owner="" severity="normal" since=""
  local -a tags=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --owner)    owner="${2:-}"; shift 2 ;;
      --tag)      tags+=("${2:-}"); shift 2 ;;
      --severity) severity="${2:-}"; shift 2 ;;
      --since)    since="${2:-}"; shift 2 ;;
      *)          [[ -z "$summary" ]] && summary="$1" || summary="$summary $1"; shift ;;
    esac
  done

  if [[ -z "$summary" ]]; then
    echo -e "${RED}Summary required.${RESET}" >&2
    echo "Usage: bash spells/blockers.sh add \"<summary>\" [--owner X] [--tag T]... [--severity S] [--since SNNN]" >&2
    exit 1
  fi
  [[ -z "$since" ]] && since=$(date -u +"%Y-%m-%d")

  local id sid now agent tags_json
  id=$(next_id)
  sid=$(resolve_session_id)
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  agent=$(detect_agent_kind)
  if [[ ${#tags[@]} -gt 0 ]]; then
    tags_json=$(printf '%s\n' "${tags[@]}" | jq -R . | jq -s 'map(select(length>0))')
  else
    tags_json='[]'
  fi

  jq -cn \
    --arg ev "open" --arg id "$id" --arg summary "$summary" \
    --arg owner "$owner" --arg severity "$severity" --arg since "$since" \
    --argjson tags "$tags_json" \
    --arg ts "$now" --arg session "$sid" --arg agent "$agent" \
    '{event:$ev, id:$id, summary:$summary, owner:$owner, severity:$severity,
      since:$since, tags:$tags, timestamp:$ts, session:$session, agent:$agent}' \
    >> "$STREAM"

  echo -e "${YELLOW}[open] ${id}${RESET} ${TEXT}${summary}${RESET}"
  [[ -n "$owner" ]] && echo -e "  ${MUTED}owner: $owner${RESET}"
  [[ ${#tags[@]} -gt 0 ]] && echo -e "  ${MUTED}tags: ${tags[*]}${RESET}"
  cmd_sync >/dev/null
  echo -e "  ${MUTED}-> $STREAM  (BLOCKERS.md regenerated)${RESET}"
}

cmd_resolve() {
  local id="${1:-}"; shift || true
  local note="$*"
  if [[ -z "$id" ]]; then
    echo -e "${RED}Blocker id required (e.g. B-03).${RESET}" >&2
    exit 1
  fi
  [[ "$id" == B-* ]] || id="B-$id"

  local state
  state=$(latest_by_id | jq -r --arg id "$id" '.[] | select(.id==$id) | .event')
  if [[ -z "$state" ]]; then
    echo -e "${RED}No blocker with id $id.${RESET} Run 'blockers.sh ls --all'." >&2
    exit 1
  fi
  if [[ "$state" == "resolve" ]]; then
    echo -e "${MUTED}$id is already resolved.${RESET}"
    exit 0
  fi

  local sid now agent
  sid=$(resolve_session_id)
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  agent=$(detect_agent_kind)

  jq -cn \
    --arg ev "resolve" --arg id "$id" --arg note "$note" \
    --arg ts "$now" --arg session "$sid" --arg agent "$agent" \
    '{event:$ev, id:$id, note:$note, timestamp:$ts, session:$session, agent:$agent}' \
    >> "$STREAM"

  echo -e "${GREEN}[resolved] ${id}${RESET}${note:+  ${MUTED}($note)${RESET}}"
  cmd_sync >/dev/null
}

cmd_ls() {
  local show_all=false
  [[ "${1:-}" == "--all" ]] && show_all=true

  echo ""
  echo -e "${MAGENTA}RaBbLE — Blockers${RESET}"
  echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${RESET}"

  local latest
  latest=$(latest_by_id)

  echo -e "${YELLOW}  OPEN${RESET}"
  local open_lines
  open_lines=$(echo "$latest" | jq -r '.[] | select(.event=="open")
    | "\(.id)\t\(.summary)\towner:\(.owner // "-") since:\(.since // "-")\((.tags // []) | if length>0 then " [" + join(", ") + "]" else "" end)"')
  if [[ -z "$open_lines" ]]; then
    echo -e "    ${MUTED}(none)${RESET}"
  else
    while IFS=$'\t' read -r id summary meta; do
      [[ -z "$id" ]] && continue
      echo -e "  ${YELLOW}${id}${RESET}  ${TEXT}${summary}${RESET}"
      echo -e "      ${MUTED}${meta}${RESET}"
    done <<< "$open_lines"
  fi

  if $show_all; then
    echo ""
    echo -e "${GREEN}  RESOLVED${RESET}"
    local res_lines
    res_lines=$(echo "$latest" | jq -r '.[] | select(.event=="resolve") | "\(.id)\t\(.note // "")"')
    if [[ -z "$res_lines" ]]; then
      echo -e "    ${MUTED}(none)${RESET}"
    else
      while IFS=$'\t' read -r id note; do
        [[ -z "$id" ]] && continue
        echo -e "  ${GREEN}${id}${RESET}  ${MUTED}${note}${RESET}"
      done <<< "$res_lines"
    fi
  fi
  echo ""
}

cmd_open_count() {
  local tag=""
  [[ "${1:-}" == "--tag" ]] && tag="${2:-}"
  if [[ -n "$tag" ]]; then
    latest_by_id | jq --arg t "$tag" '[.[] | select(.event=="open") | select((.tags // []) | index($t))] | length'
  else
    latest_by_id | jq '[.[] | select(.event=="open")] | length'
  fi
}

cmd_sync() {
  local latest now
  latest=$(latest_by_id)
  now=$(date -u +"%Y-%m-%d")

  {
    echo "# BLOCKERS — RaBbLE Collective"
    echo ""
    echo "> **Generated** from \`log/blockers/blockers.jsonl\` by \`spells/blockers.sh\`."
    echo "> Do not hand-edit — use \`blockers.sh add\` / \`resolve\`. This is the durable"
    echo "> home for blockers so they survive the rewrite of the SESSION-LOG \`## LATEST\` box."
    echo ">"
    echo "> Last synced: ${now}  ·  add: \`bash spells/blockers.sh add \"…\" --tag ep1-gate\`"
    echo ""
    echo "## OPEN"
    echo ""
    local rows
    rows=$(echo "$latest" | jq -r '.[] | select(.event=="open")
      | "- **\(.id)** — \(.summary)  ·  owner:\(.owner // "—")  ·  since:\(.since // "—")\((.tags // []) | if length>0 then "  ·  [" + join(", ") + "]" else "" end)"')
    if [[ -z "$rows" ]]; then echo "_(none)_"; else echo "$rows"; fi
    echo ""
    echo "## RESOLVED"
    echo ""
    rows=$(echo "$latest" | jq -r '.[] | select(.event=="resolve")
      | "- **\(.id)** — resolved\(if (.note // "") != "" then ": " + .note else "" end)"')
    if [[ -z "$rows" ]]; then echo "_(none)_"; else echo "$rows"; fi
    echo ""
  } > "$RENDERED"

  echo -e "${GREEN}Synced${RESET} ${MUTED}-> $RENDERED${RESET}"
}

# =============================================================================
# DISPATCH
# =============================================================================

CMD="${1:-}"
shift || true

case "$CMD" in
  add)        cmd_add "$@" ;;
  resolve)    cmd_resolve "$@" ;;
  ls|list)    cmd_ls "${1:-}" ;;
  sync)       cmd_sync ;;
  open-count) cmd_open_count "$@" ;;
  --help|-h|help|"")
    echo "blockers.sh — durable blocker ledger (append-only; generates log/BLOCKERS.md)"
    echo ""
    echo "Commands:"
    echo "  add \"<summary>\" [--owner X] [--tag T]... [--severity S] [--since SNNN]"
    echo "                            Open a new blocker (prints its B-NN id)"
    echo "  resolve <id> [\"<note>\"]   Close a blocker"
    echo "  ls [--all]                List OPEN blockers (--all also shows RESOLVED)"
    echo "  sync                      Regenerate log/BLOCKERS.md from the event stream"
    echo "  open-count [--tag T]      Print the number of open blockers (bare integer)"
    echo ""
    echo "Source of truth: log/blockers/blockers.jsonl  ·  Rendered: log/BLOCKERS.md"
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Run 'bash spells/blockers.sh --help' for usage." >&2
    exit 1
    ;;
esac
