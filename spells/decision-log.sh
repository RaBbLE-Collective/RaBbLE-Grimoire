#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — decision-log.sh
# Per-agent structured decision/insight/stumble log. Appends JSONL lines to
# log/decisions/<session-id>.jsonl — one file per agent means zero git merge
# conflicts even when N agents run in parallel.
#
# AGENT-AGNOSTIC: same session-id resolution as end-session.sh (Claude
# transcript → git-commit fallback). Human-curated DECISIONS.md and AUDITS.md
# remain untouched; this is the machine-friendly parallel stream that feeds
# promote-insight.sh and can be queried/grepped by any agent.
#
# Usage:
#   bash spells/decision-log.sh log   <type> <message...>
#   bash spells/decision-log.sh show  [session-id]
#   bash spells/decision-log.sh tail  [session-id]
#   bash spells/decision-log.sh list
#
# Types: decision | insight | stumble | scope
#   decision  — architectural or implementation choice made
#   insight   — something discovered that future agents should know
#   stumble   — mistake, wrong turn, or failed approach (most valuable for learning)
#   scope     — what this agent is / isn't doing (context for parallel agents)
#
# spark ~ grimoire >> every mistake is a lesson // %DECISION_LOG%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DECISIONS_DIR="$GRIMOIRE_ROOT/log/decisions"
mkdir -p "$DECISIONS_DIR"

# --- Colors -------------------------------------------------------------------
GREEN='\033[38;2;80;250;123m'
CYAN='\033[38;2;0;245;255m'
YELLOW='\033[38;2;241;250;140m'
MAGENTA='\033[38;2;255;45;120m'
RED='\033[38;2;255;85;85m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RESET='\033[0m'

VALID_TYPES="decision insight stumble scope"

# --- Resolve session id (mirrors end-session.sh) ------------------------------
resolve_session_id() {
  if [[ -n "${RABBLE_SESSION_ID:-}" ]]; then
    echo "$RABBLE_SESSION_ID"; return
  fi
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

# --- Color by type ------------------------------------------------------------
type_color() {
  case "$1" in
    decision) echo "$CYAN" ;;
    insight)  echo "$GREEN" ;;
    stumble)  echo "$RED" ;;
    scope)    echo "$YELLOW" ;;
    *)        echo "$TEXT" ;;
  esac
}

# =============================================================================
# COMMANDS
# =============================================================================

cmd_log() {
  local type="${1:-}"
  shift || true
  local message="$*"

  # Validate type
  if [[ -z "$type" ]]; then
    echo -e "${RED}Type required. One of: $VALID_TYPES${RESET}" >&2
    exit 1
  fi
  local valid=0
  for t in $VALID_TYPES; do [[ "$t" == "$type" ]] && valid=1; done
  if [[ $valid -eq 0 ]]; then
    echo -e "${RED}Unknown type '$type'. Must be one of: $VALID_TYPES${RESET}" >&2
    exit 1
  fi

  if [[ -z "$message" ]]; then
    echo -e "${RED}Message required.${RESET}" >&2
    echo "Usage: bash spells/decision-log.sh log <type> <message...>" >&2
    exit 1
  fi

  local sid
  sid=$(resolve_session_id)
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local host
  host=$(hostname -s 2>/dev/null || hostname)

  # Detect agent kind (same logic as agent-register.sh)
  local agent_kind="unknown"
  if [[ -n "${CLAUDE_CODE_ENTRYPOINT:-}" || ( -n "${ANTHROPIC_API_KEY:-}" && -d "$HOME/.claude" ) ]]; then
    agent_kind="claude"
  elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
    agent_kind="codex"
  elif [[ -n "${GOOGLE_API_KEY:-}" || -n "${GEMINI_API_KEY:-}" ]]; then
    agent_kind="gemini"
  fi

  local outfile="$DECISIONS_DIR/${sid}.jsonl"

  # Write JSONL line (one JSON object per line — safe for parallel appends via >>)
  jq -cn \
    --arg ts "$now" \
    --arg type "$type" \
    --arg msg "$message" \
    --arg sid "$sid" \
    --arg agent "$agent_kind" \
    --arg host "$host" \
    --arg cwd "$(pwd)" \
    '{timestamp:$ts, type:$type, message:$msg, session:$sid, agent:$agent, host:$host, cwd:$cwd}' \
    >> "$outfile"

  local color
  color=$(type_color "$type")
  echo -e "${color}[${type}]${RESET} $message"
  echo -e "  ${MUTED}→ $outfile${RESET}"
}

cmd_show() {
  local sid="${1:-}"
  if [[ -z "$sid" ]]; then
    sid=$(resolve_session_id)
  fi

  local file="$DECISIONS_DIR/${sid}.jsonl"
  if [[ ! -f "$file" ]]; then
    echo -e "${MUTED}No decision log for session: $sid${RESET}"
    exit 0
  fi

  echo ""
  echo -e "${MAGENTA}Decision Log — ${CYAN}${sid}${RESET}"
  echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${RESET}"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local ts type msg agent
    ts=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)
    type=$(echo "$line" | jq -r '.type // "?"' 2>/dev/null)
    msg=$(echo "$line" | jq -r '.message // ""' 2>/dev/null)
    agent=$(echo "$line" | jq -r '.agent // ""' 2>/dev/null)
    local color
    color=$(type_color "$type")
    printf "  ${MUTED}%-20s${RESET} ${color}%-10s${RESET} ${TEXT}%s${RESET}" "$ts" "[$type]" "$msg"
    [[ -n "$agent" ]] && printf "  ${MUTED}(%s)${RESET}" "$agent"
    echo ""
  done < "$file"
  echo ""
}

cmd_tail() {
  local sid="${1:-}"
  if [[ -z "$sid" ]]; then
    sid=$(resolve_session_id)
  fi

  local file="$DECISIONS_DIR/${sid}.jsonl"
  if [[ ! -f "$file" ]]; then
    echo -e "${MUTED}No decision log for session: $sid${RESET}"
    exit 0
  fi

  echo -e "${MUTED}(last 10 entries for $sid)${RESET}"
  tail -10 "$file" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local ts type msg
    ts=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)
    type=$(echo "$line" | jq -r '.type // "?"' 2>/dev/null)
    msg=$(echo "$line" | jq -r '.message // ""' 2>/dev/null)
    local color
    color=$(type_color "$type")
    echo -e "  ${MUTED}${ts}${RESET}  ${color}[${type}]${RESET}  ${TEXT}${msg}${RESET}"
  done
}

cmd_list() {
  echo ""
  echo -e "${MAGENTA}RaBbLE — Decision Log Files${RESET}"
  echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${RESET}"

  local count=0
  for file in "$DECISIONS_DIR"/*.jsonl; do
    [[ -f "$file" ]] || continue
    local sid entries last_ts
    sid=$(basename "$file" .jsonl)
    entries=$(wc -l < "$file" | tr -d ' ')
    last_ts=$(tail -1 "$file" 2>/dev/null | jq -r '.timestamp // "?"' 2>/dev/null || echo "?")

    # Count by type
    local ndecision ninsight nstumble nscope
    ndecision=$(grep -c '"type":"decision"' "$file" 2>/dev/null || echo 0)
    ninsight=$(grep -c '"type":"insight"' "$file" 2>/dev/null || echo 0)
    nstumble=$(grep -c '"type":"stumble"' "$file" 2>/dev/null || echo 0)
    nscope=$(grep -c '"type":"scope"' "$file" 2>/dev/null || echo 0)

    echo -e "  ${CYAN}${sid}${RESET}"
    echo -e "    ${MUTED}entries: $entries  last: $last_ts${RESET}"
    echo -e "    ${CYAN}decisions:$ndecision${RESET}  ${GREEN}insights:$ninsight${RESET}  ${RED}stumbles:$nstumble${RESET}  ${YELLOW}scopes:$nscope${RESET}"
    count=$((count+1))
  done

  if [[ $count -eq 0 ]]; then
    echo -e "  ${MUTED}(no decision logs yet)${RESET}"
  fi
  echo ""
}

# =============================================================================
# DISPATCH
# =============================================================================

CMD="${1:-}"
shift || true

case "$CMD" in
  log)   cmd_log "$@" ;;
  show)  cmd_show "${1:-}" ;;
  tail)  cmd_tail "${1:-}" ;;
  list)  cmd_list ;;
  --help|-h|help|"")
    echo "decision-log.sh — per-agent decision/insight/stumble log"
    echo ""
    echo "Commands:"
    echo "  log <type> <message...>   Append one entry to this session's JSONL log"
    echo "  show [session-id]         Pretty-print a session's decision log"
    echo "  tail [session-id]         Show last 10 entries"
    echo "  list                      List all decision log files with stats"
    echo ""
    echo "Types: decision | insight | stumble | scope"
    echo "  decision  architectural or implementation choice"
    echo "  insight   something future agents should know"
    echo "  stumble   mistake or failed approach (most valuable for learning)"
    echo "  scope     what this agent is / isn't doing"
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Run 'bash spells/decision-log.sh --help' for usage." >&2
    exit 1
    ;;
esac
