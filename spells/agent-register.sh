#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — agent-register.sh
# Multi-agent scope coordination. Agents claim file-scope globs before working;
# overlapping claims from live agents produce a loud WARNING + non-zero exit so
# parallel agents never silently stomp each other.
#
# AGENT-AGNOSTIC: uses the same Claude-transcript → git-fallback session-id
# resolution as end-session.sh. Works with Claude, Codex, Gemini, or any agent.
#
# Usage:
#   bash spells/agent-register.sh claim  <scope-glob>...   [--task "desc"] [--agent kind]
#   bash spells/agent-register.sh heartbeat
#   bash spells/agent-register.sh release
#   bash spells/agent-register.sh status
#   bash spells/agent-register.sh check  <path>
#
# Files:
#   log/agents/<session-id>.json   — one file per agent; conflict-free parallel git merges
#
# spark ~ grimoire >> safe parallel agents // %AGENT_COORD%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_DIR="$GRIMOIRE_ROOT/log/agents"
mkdir -p "$AGENTS_DIR"

# --- Colors -------------------------------------------------------------------
RED='\033[38;2;255;85;85m'
YELLOW='\033[38;2;241;250;140m'
GREEN='\033[38;2;80;250;123m'
CYAN='\033[38;2;0;245;255m'
MAGENTA='\033[38;2;255;45;120m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
BOLD='\033[1m'
RESET='\033[0m'

HEARTBEAT_STALE_SECS=300   # 5 min — agent is considered stale if heartbeat older
HEARTBEAT_DEAD_SECS=900    # 15 min — agent is considered dead (slot auto-released)

# --- Resolve session id (mirrors end-session.sh) ------------------------------
resolve_session_id() {
  local projdir="$HOME/.claude/projects/$(pwd | tr '/' '-')"
  local sf
  sf=$(ls -t "$projdir"/*.jsonl 2>/dev/null | head -1 || true)
  if [[ -n "$sf" ]]; then
    basename "$sf" .jsonl
  else
    # Non-Claude fallback: git-commit key + PID so parallel non-Claude agents differ
    local commit
    commit=$(git -C "$GRIMOIRE_ROOT" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)
    echo "commit-${commit}-$$"
  fi
}

# --- Detect agent kind --------------------------------------------------------
detect_agent_kind() {
  # Caller can override with --agent flag; otherwise infer from env
  if [[ -n "${CLAUDE_CODE_ENTRYPOINT:-}" || -n "${ANTHROPIC_API_KEY:-}" && -d "$HOME/.claude" ]]; then
    echo "claude"
  elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
    echo "codex"
  elif [[ -n "${GOOGLE_API_KEY:-}" || -n "${GEMINI_API_KEY:-}" ]]; then
    echo "gemini"
  else
    echo "unknown"
  fi
}

# --- Glob overlap check -------------------------------------------------------
# Returns 0 (true) if glob A and glob B have any potential overlap.
# Strategy: simplistic but safe — check if either glob is a prefix/suffix of
# the other after stripping wildcards. For full correctness we use bash extglob
# path expansion against real files when possible; otherwise prefix-match.
globs_overlap() {
  local a="$1" b="$2"
  # Strip trailing wildcard suffixes (non-greedy: only trailing globs)
  # Use sed to strip /**, /*, or /* at the END of the string only
  local a_base b_base
  a_base=$(echo "$a" | sed 's|/\*\*$||; s|/\*$||; s|/\*\*/\*$||')
  b_base=$(echo "$b" | sed 's|/\*\*$||; s|/\*$||; s|/\*\*/\*$||')
  # If either base is a path-prefix of the other (must match at a / boundary)
  # Append / to ensure we don't match partial directory names
  local a_slash="${a_base}/"
  local b_slash="${b_base}/"
  if [[ "$a_slash" == "${b_slash}"* || "$b_slash" == "${a_slash}"* ]]; then
    return 0
  fi
  # Exact match (same path, same scope)
  if [[ "$a_base" == "$b_base" ]]; then
    return 0
  fi
  return 1
}

# --- Check if an agent file represents a LIVE agent ---------------------------
is_live() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  command -v jq &>/dev/null || { echo "jq required for agent-register.sh" >&2; exit 1; }

  local heartbeat_at pid host now age
  heartbeat_at=$(jq -r '.heartbeat_at // .started_at' "$file" 2>/dev/null || echo "")
  pid=$(jq -r '.pid // 0' "$file" 2>/dev/null || echo 0)
  host=$(jq -r '.host // ""' "$file" 2>/dev/null || echo "")
  now=$(date +%s)

  [[ -z "$heartbeat_at" ]] && return 1

  # Parse ISO8601 timestamp → epoch seconds
  age=$(( now - $(date -d "$heartbeat_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$heartbeat_at" +%s 2>/dev/null || echo 0) ))

  # Dead threshold — treat as auto-released regardless
  [[ "$age" -gt "$HEARTBEAT_DEAD_SECS" ]] && return 1

  # Same host? Check if PID is still running
  local this_host
  this_host=$(hostname -s 2>/dev/null || hostname)
  if [[ "$host" == "$this_host" && "$pid" -gt 0 ]]; then
    kill -0 "$pid" 2>/dev/null || return 1   # process gone → not live
  fi

  return 0
}

# =============================================================================
# COMMANDS
# =============================================================================

cmd_claim() {
  local task="" agent_kind scopes=() extra_args=()

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --task)  task="${2:-}"; shift 2 ;;
      --agent) agent_kind="${2:-}"; shift 2 ;;
      -*)      echo "Unknown flag: $1" >&2; exit 1 ;;
      *)       scopes+=("$1"); shift ;;
    esac
  done

  if [[ ${#scopes[@]} -eq 0 ]]; then
    echo -e "${RED}claim requires at least one scope glob.${RESET}" >&2
    echo "Usage: bash spells/agent-register.sh claim <scope-glob>... [--task desc] [--agent kind]" >&2
    exit 1
  fi

  local sid
  sid=$(resolve_session_id)
  agent_kind="${agent_kind:-$(detect_agent_kind)}"
  local host
  host=$(hostname -s 2>/dev/null || hostname)
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # --- Conflict check against every live agent (excluding ourselves) ----------
  local conflict=0
  for other_file in "$AGENTS_DIR"/*.json; do
    [[ -f "$other_file" ]] || continue
    local other_sid
    other_sid=$(basename "$other_file" .json)
    [[ "$other_sid" == "$sid" ]] && continue   # our own previous claim
    is_live "$other_file" || continue           # stale / dead — skip

    local other_scopes
    other_scopes=$(jq -r '.scopes[]' "$other_file" 2>/dev/null || true)

    for my_scope in "${scopes[@]}"; do
      while IFS= read -r their_scope; do
        [[ -z "$their_scope" ]] && continue
        if globs_overlap "$my_scope" "$their_scope"; then
          echo -e "${RED}${BOLD}!! SCOPE CONFLICT !!${RESET}" >&2
          echo -e "${RED}   Agent  : $other_sid${RESET}" >&2
          echo -e "${RED}   Their  : $their_scope${RESET}" >&2
          echo -e "${RED}   Yours  : $my_scope${RESET}" >&2
          echo -e "${YELLOW}   Resolve: coordinate with the other agent or wait for release.${RESET}" >&2
          conflict=1
        fi
      done <<< "$other_scopes"
    done
  done

  if [[ "$conflict" -eq 1 ]]; then
    echo -e "${RED}Claim REJECTED — scope conflict detected (see above). Exiting non-zero.${RESET}" >&2
    exit 2
  fi

  # --- Write claim file -------------------------------------------------------
  local scopes_json
  scopes_json=$(printf '%s\n' "${scopes[@]}" | jq -R . | jq -s .)

  jq -n \
    --arg sid "$sid" \
    --arg agent "$agent_kind" \
    --arg host "$host" \
    --argjson pid "$$" \
    --arg cwd "$(pwd)" \
    --arg task "$task" \
    --argjson scopes "$scopes_json" \
    --arg started_at "$now" \
    --arg heartbeat_at "$now" \
    '{session_id:$sid, agent:$agent, host:$host, pid:$pid, cwd:$cwd, task:$task,
      scopes:$scopes, started_at:$started_at, heartbeat_at:$heartbeat_at}' \
    > "$AGENTS_DIR/${sid}.json"

  echo -e "${GREEN}Claimed scopes for session ${CYAN}${sid}${RESET}"
  for s in "${scopes[@]}"; do
    echo -e "  ${TEXT}+ $s${RESET}"
  done
  [[ -n "$task" ]] && echo -e "  ${MUTED}task: $task${RESET}"
}

cmd_heartbeat() {
  local sid
  sid=$(resolve_session_id)
  local file="$AGENTS_DIR/${sid}.json"
  if [[ ! -f "$file" ]]; then
    echo -e "${YELLOW}No active claim for session $sid. Run 'claim' first.${RESET}" >&2
    exit 1
  fi
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local tmp
  tmp=$(mktemp)
  jq --arg t "$now" '.heartbeat_at = $t' "$file" > "$tmp"
  mv "$tmp" "$file"
  echo -e "${MUTED}Heartbeat: $sid @ $now${RESET}"
}

cmd_release() {
  local sid
  sid=$(resolve_session_id)
  local file="$AGENTS_DIR/${sid}.json"
  if [[ ! -f "$file" ]]; then
    echo -e "${MUTED}No claim file found for session $sid (already released or never claimed).${RESET}"
    exit 0
  fi
  rm -f "$file"
  echo -e "${GREEN}Released scopes for session ${CYAN}${sid}${RESET}"
}

cmd_status() {
  echo ""
  echo -e "${MAGENTA}RaBbLE — Active Agent Registry${RESET}"
  echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${RESET}"

  local count=0 stale=0
  for file in "$AGENTS_DIR"/*.json; do
    [[ -f "$file" ]] || continue
    local sid
    sid=$(basename "$file" .json)

    local agent host pid task started_at heartbeat_at
    agent=$(jq -r '.agent // "unknown"' "$file" 2>/dev/null)
    host=$(jq -r '.host // "?"' "$file" 2>/dev/null)
    pid=$(jq -r '.pid // 0' "$file" 2>/dev/null)
    task=$(jq -r '.task // ""' "$file" 2>/dev/null)
    started_at=$(jq -r '.started_at // ""' "$file" 2>/dev/null)
    heartbeat_at=$(jq -r '.heartbeat_at // .started_at // ""' "$file" 2>/dev/null)

    local now age label
    now=$(date +%s)
    age=$(( now - $(date -d "$heartbeat_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S%z" "$heartbeat_at" +%s 2>/dev/null || echo now) ))

    if is_live "$file"; then
      if [[ "$age" -gt "$HEARTBEAT_STALE_SECS" ]]; then
        label="${YELLOW}[STALE]${RESET}"
        stale=$((stale+1))
      else
        label="${GREEN}[LIVE]${RESET}"
      fi
    else
      label="${MUTED}[DEAD]${RESET}"
    fi

    count=$((count+1))
    echo -e "  $label ${CYAN}${sid}${RESET}"
    echo -e "    ${MUTED}agent:${RESET} $agent  ${MUTED}host:${RESET} $host  ${MUTED}pid:${RESET} $pid"
    [[ -n "$task" ]] && echo -e "    ${MUTED}task:${RESET}  $task"
    echo -e "    ${MUTED}started:${RESET}   $started_at"
    echo -e "    ${MUTED}heartbeat:${RESET} $heartbeat_at (${age}s ago)"
    echo -e "    ${MUTED}scopes:${RESET}"
    jq -r '.scopes[]' "$file" 2>/dev/null | while read -r s; do
      echo -e "      ${TEXT}$s${RESET}"
    done
    echo ""
  done

  if [[ $count -eq 0 ]]; then
    echo -e "  ${MUTED}(no agent claim files found)${RESET}"
  else
    echo -e "  ${MUTED}$count claim(s) total${STALE_NOTE:-}${RESET}"
    [[ $stale -gt 0 ]] && echo -e "  ${YELLOW}$stale claim(s) stale (heartbeat >${HEARTBEAT_STALE_SECS}s old) — may be abandoned.${RESET}"
  fi
  echo ""
}

cmd_check() {
  local path="${1:-}"
  if [[ -z "$path" ]]; then
    echo "Usage: bash spells/agent-register.sh check <path>" >&2
    exit 1
  fi
  local sid
  sid=$(resolve_session_id)
  local conflict=0

  for file in "$AGENTS_DIR"/*.json; do
    [[ -f "$file" ]] || continue
    local other_sid
    other_sid=$(basename "$file" .json)
    [[ "$other_sid" == "$sid" ]] && continue
    is_live "$file" || continue

    while IFS= read -r scope; do
      [[ -z "$scope" ]] && continue
      if globs_overlap "$path" "$scope"; then
        local other_task
        other_task=$(jq -r '.task // ""' "$file" 2>/dev/null)
        echo -e "${YELLOW}Path ${TEXT}${path}${RESET}${YELLOW} overlaps scope ${TEXT}${scope}${RESET}"
        echo -e "  ${MUTED}Claimed by: $other_sid${other_task:+  (task: $other_task)}${RESET}"
        conflict=1
      fi
    done < <(jq -r '.scopes[]' "$file" 2>/dev/null || true)
  done

  if [[ $conflict -eq 0 ]]; then
    echo -e "${GREEN}No live agent claims overlap path: ${TEXT}${path}${RESET}"
  fi
  exit $conflict
}

# =============================================================================
# DISPATCH
# =============================================================================

CMD="${1:-}"
shift || true

case "$CMD" in
  claim)     cmd_claim "$@" ;;
  heartbeat) cmd_heartbeat ;;
  release)   cmd_release ;;
  status)    cmd_status ;;
  check)     cmd_check "$@" ;;
  --help|-h|help|"")
    echo "agent-register.sh — multi-agent scope coordination"
    echo ""
    echo "Commands:"
    echo "  claim  <glob>...  [--task desc] [--agent kind]"
    echo "               Claim scope globs. Exits non-zero on conflict."
    echo "  heartbeat    Update heartbeat timestamp for current session."
    echo "  release      Remove current session's claim file."
    echo "  status       List all agent claims and liveness."
    echo "  check <path> Check if a path is claimed by another live agent."
    echo ""
    echo "Agent kinds: claude | codex | gemini | unknown (auto-detected from env)"
    echo "Stale threshold: ${HEARTBEAT_STALE_SECS}s  Dead threshold: ${HEARTBEAT_DEAD_SECS}s"
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Run 'bash spells/agent-register.sh --help' for usage." >&2
    exit 1
    ;;
esac
