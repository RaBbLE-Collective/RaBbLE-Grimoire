#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — session-tokens.sh
# Parses Claude Code session transcripts to extract token usage per session.
#
# Usage:
#   bash spells/session-tokens.sh              # table to stdout
#   bash spells/session-tokens.sh --json       # write log/session-tokens.json
#   bash spells/session-tokens.sh --recent 5   # last N sessions only
#
# Reads: ~/.claude/projects/-home-rabble-RaBbLE-*/*.jsonl
#
# spark ~ grimoire >> know what the thinking costs // %SESSION_TOKENS%
# =============================================================================

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "session-tokens.sh — parse Claude Code transcripts for token usage"
  echo ""
  echo "Usage: bash spells/session-tokens.sh [--json] [--recent N]"
  echo "  --json       Write output to log/session-tokens.json"
  echo "  --recent N   Show only the last N sessions (default: all)"
  echo ""
  echo "Reads session JSONL from ~/.claude/projects/"
  echo "Requires: jq (falls back to grep without it)"
  exit 0
fi

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_PROJECTS="$HOME/.claude/projects"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RESET='\033[0m'

OUTPUT_JSON=false
RECENT_N=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) OUTPUT_JSON=true; shift ;;
    --recent) RECENT_N="${2:-10}"; shift 2 ;;
    --help|-h) exec bash "$0" --help ;;
    *) shift ;;
  esac
done

HAS_JQ=false
command -v jq &>/dev/null && HAS_JQ=true

if [[ ! -d "$CLAUDE_PROJECTS" ]]; then
  echo "No Claude Code projects directory found at $CLAUDE_PROJECTS"
  exit 1
fi

# Map directory names to project slugs
dir_to_project() {
  local dirname="$1"
  # -home-rabble-RaBbLE-RaBbLE-sCoRE → RaBbLE-sCoRE
  # -home-rabble-RaBbLE-Collective → RaBbLE-Collective
  # -home-rabble → (home)
  if [[ "$dirname" == *"-RaBbLE-Collective" ]]; then
    echo "RaBbLE-Collective"
  elif [[ "$dirname" == *"-RaBbLE-RaBbLE-"* ]]; then
    echo "$dirname" | sed 's/.*-RaBbLE-RaBbLE-/RaBbLE-/'
  elif [[ "$dirname" == *"-RaBbLE-"* ]]; then
    echo "$dirname" | sed 's/.*-RaBbLE-/RaBbLE-/'
  else
    echo "$dirname" | sed 's/-home-rabble-//'
  fi
}

declare -a SESSION_DATA=()

# Scan all RaBbLE project session files
for projdir in "$CLAUDE_PROJECTS"/-home-rabble-RaBbLE-*/; do
  [[ -d "$projdir" ]] || continue
  project_name=$(dir_to_project "$(basename "$projdir")")

  for sessionfile in "$projdir"*.jsonl; do
    [[ -f "$sessionfile" ]] || continue

    session_date=$(date -r "$sessionfile" '+%Y-%m-%d %H:%M' 2>/dev/null || stat -c '%y' "$sessionfile" 2>/dev/null | cut -d. -f1 || echo "unknown")
    session_id=$(basename "$sessionfile" .jsonl)
    file_size=$(wc -c < "$sessionfile" | tr -d ' ')

    # Skip tiny files (< 100 bytes — likely empty/corrupt)
    [[ "$file_size" -lt 100 ]] && continue

    if $HAS_JQ; then
      # Extract token usage from all lines that have usage blocks
      read -r input_tok output_tok cache_read cache_create msg_count <<< $(
        jq -r '
          select(.usage != null) |
          .usage | [
            (.input_tokens // 0),
            (.output_tokens // 0),
            (.cache_read_input_tokens // 0),
            (.cache_creation_input_tokens // 0)
          ] | @tsv
        ' "$sessionfile" 2>/dev/null \
        | awk '{i+=$1; o+=$2; cr+=$3; cc+=$4; n++} END {printf "%d %d %d %d %d", i, o, cr, cc, n}'
      )

      # If jq found nothing, try nested .message.usage path
      if [[ "$input_tok" -eq 0 && "$output_tok" -eq 0 ]]; then
        read -r input_tok output_tok cache_read cache_create msg_count <<< $(
          jq -r '
            select(.message.usage != null) |
            .message.usage | [
              (.input_tokens // 0),
              (.output_tokens // 0),
              (.cache_read_input_tokens // 0),
              (.cache_creation_input_tokens // 0)
            ] | @tsv
          ' "$sessionfile" 2>/dev/null \
          | awk '{i+=$1; o+=$2; cr+=$3; cc+=$4; n++} END {printf "%d %d %d %d %d", i, o, cr, cc, n}'
        )
      fi
    else
      # Fallback: grep for token counts
      input_tok=$(grep -o '"input_tokens":[0-9]*' "$sessionfile" 2>/dev/null | grep -o '[0-9]*' | awk '{s+=$1} END {print s+0}')
      output_tok=$(grep -o '"output_tokens":[0-9]*' "$sessionfile" 2>/dev/null | grep -o '[0-9]*' | awk '{s+=$1} END {print s+0}')
      cache_read=$(grep -o '"cache_read_input_tokens":[0-9]*' "$sessionfile" 2>/dev/null | grep -o '[0-9]*' | awk '{s+=$1} END {print s+0}')
      cache_create=$(grep -o '"cache_creation_input_tokens":[0-9]*' "$sessionfile" 2>/dev/null | grep -o '[0-9]*' | awk '{s+=$1} END {print s+0}')
      msg_count=$(grep -c '"input_tokens"' "$sessionfile" 2>/dev/null || echo 0)
    fi

    total=$((input_tok + output_tok))
    [[ "$total" -eq 0 ]] && continue

    SESSION_DATA+=("${session_date}|${project_name}|${msg_count}|${input_tok}|${output_tok}|${cache_read}|${total}|${session_id}")
  done
done

if [[ ${#SESSION_DATA[@]} -eq 0 ]]; then
  echo "No sessions with token data found."
  exit 0
fi

# Sort by date (descending)
IFS=$'\n' SORTED=($(printf '%s\n' "${SESSION_DATA[@]}" | sort -t'|' -k1 -r))
unset IFS

# Apply --recent filter
if [[ "$RECENT_N" -gt 0 ]]; then
  SORTED=("${SORTED[@]:0:$RECENT_N}")
fi

# --- JSON output ---
if $OUTPUT_JSON; then
  mkdir -p "$GRIMOIRE_ROOT/log"
  json_out="$GRIMOIRE_ROOT/log/session-tokens.json"
  {
    echo '['
    first=true
    for row in "${SORTED[@]}"; do
      IFS='|' read -r date proj msgs inp outp cache tot sid <<< "$row"
      $first || echo ','
      printf '  {"date":"%s","project":"%s","messages":%s,"input_tokens":%s,"output_tokens":%s,"cache_read":%s,"total":%s,"session":"%s"}' \
        "$date" "$proj" "$msgs" "$inp" "$outp" "$cache" "$tot" "$sid"
      first=false
    done
    echo ''
    echo ']'
  } > "$json_out"
  echo -e "${GREEN}Wrote${RESET} $json_out (${#SORTED[@]} sessions)"
  exit 0
fi

# --- Table output ---
echo ""
echo -e "${MAGENTA}RaBbLE-Grimoire — Session Token Usage${RESET}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════════${RESET}"
printf "  ${CYAN}%-18s %-22s %6s %10s %10s %10s %10s${RESET}\n" \
  "Date" "Project" "Msgs" "Input" "Output" "Cache" "Total"
printf "  ${MUTED}%-18s %-22s %6s %10s %10s %10s %10s${RESET}\n" \
  "──────────────────" "──────────────────────" "──────" "──────────" "──────────" "──────────" "──────────"

grand_input=0
grand_output=0
grand_cache=0
grand_total=0
declare -A PROJ_TOTAL

for row in "${SORTED[@]}"; do
  IFS='|' read -r date proj msgs inp outp cache tot sid <<< "$row"
  printf "  ${TEXT}%-18s %-22s %6s %10s %10s %10s %10s${RESET}\n" \
    "$date" "$proj" "$msgs" "$inp" "$outp" "$cache" "$tot"

  grand_input=$((grand_input + inp))
  grand_output=$((grand_output + outp))
  grand_cache=$((grand_cache + cache))
  grand_total=$((grand_total + tot))
  PROJ_TOTAL["$proj"]=$(( ${PROJ_TOTAL["$proj"]:-0} + tot ))
done

echo ""
echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────────────────${RESET}"
printf "  ${GREEN}%-18s %-22s %6s %10s %10s %10s %10s${RESET}\n" \
  "TOTAL" "(${#SORTED[@]} sessions)" "" "$grand_input" "$grand_output" "$grand_cache" "$grand_total"

echo ""
echo -e "${CYAN}Per-Project Totals:${RESET}"
for proj in $(echo "${!PROJ_TOTAL[@]}" | tr ' ' '\n' | sort); do
  printf "  ${TEXT}%-30s${RESET} ${GREEN}%10s tokens${RESET}\n" "$proj" "${PROJ_TOTAL[$proj]}"
done

echo ""
echo -e "${MUTED}  Use --json to write log/session-tokens.json | --recent N for last N sessions${RESET}"
echo ""
