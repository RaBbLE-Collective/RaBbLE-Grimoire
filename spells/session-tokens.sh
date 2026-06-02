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
  echo "Usage: bash spells/session-tokens.sh [--json] [--recent N] [--onboarding] [--by-feature]"
  echo "  --json         Write output to log/session-tokens.json"
  echo "  --recent N     Show only the last N sessions (default: all)"
  echo "  --onboarding   Per-session orientation cost (weighted spend before first edit)"
  echo "  --by-feature   Group weighted spend by feature via log/token-ledger.tsv"
  echo ""
  echo "Reads session JSONL from ~/.claude/projects/"
  echo "Requires: jq (falls back to grep without it; --onboarding needs jq)"
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

# --- Cost model (model-agnostic input-equivalent weights) ---------------------
# Raw token counts mislead: output costs ~5x input, cache-read ~0.1x, cache-write
# ~1.25x. "Weighted" normalizes everything to input-equivalent tokens so a single
# number reflects real spend. Tune weights / price here or via env override.
W_OUTPUT=${RABBLE_W_OUTPUT:-5}          # output ≈ 5x input
W_CACHE_READ_NUM=${RABBLE_W_CR_NUM:-1}  # cache-read ≈ 0.1x  → 1/10
W_CACHE_READ_DEN=${RABBLE_W_CR_DEN:-10}
W_CACHE_WRITE_NUM=${RABBLE_W_CW_NUM:-5} # cache-write ≈ 1.25x → 5/4
W_CACHE_WRITE_DEN=${RABBLE_W_CW_DEN:-4}
# Input $/MTok for the $ estimate. Default ~Opus input rate; override per model:
#   RABBLE_INPUT_PRICE=3 bash spells/session-tokens.sh   (e.g. Sonnet)
INPUT_PRICE=${RABBLE_INPUT_PRICE:-15}

weighted_cost() {  # input output cache_read cache_write -> input-equivalent tokens
  local i="$1" o="$2" cr="$3" cw="$4"
  echo $(( i + o*W_OUTPUT + cr*W_CACHE_READ_NUM/W_CACHE_READ_DEN + cw*W_CACHE_WRITE_NUM/W_CACHE_WRITE_DEN ))
}

OUTPUT_JSON=false
RECENT_N=0
MODE_ONBOARDING=false
MODE_BY_FEATURE=false
LEDGER="$GRIMOIRE_ROOT/log/token-ledger.tsv"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) OUTPUT_JSON=true; shift ;;
    --recent) RECENT_N="${2:-10}"; shift 2 ;;
    --onboarding) MODE_ONBOARDING=true; shift ;;
    --by-feature) MODE_BY_FEATURE=true; shift ;;
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

# --- Onboarding mode: weighted spend before the first file edit ---------------
if $MODE_ONBOARDING; then
  if ! $HAS_JQ; then
    echo "Onboarding analysis requires jq. Install jq and retry." >&2
    exit 1
  fi

  echo ""
  echo -e "${MAGENTA}RaBbLE-Grimoire — Onboarding Cost (orientation before first edit)${RESET}"
  echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════════════${RESET}"
  printf "  ${CYAN}%-18s %-20s %6s %12s %12s %6s${RESET}\n" \
    "Date" "Project" "Msgs" "Onboarding" "Session" "Pct"
  printf "  ${MUTED}%-18s %-20s %6s %12s %12s %6s${RESET}\n" \
    "──────────────────" "────────────────────" "──────" "────────────" "────────────" "──────"

  declare -a OB_ROWS=()
  for projdir in "$CLAUDE_PROJECTS"/-home-rabble-RaBbLE-*/; do
    [[ -d "$projdir" ]] || continue
    project_name=$(dir_to_project "$(basename "$projdir")")
    for sessionfile in "$projdir"*.jsonl; do
      [[ -f "$sessionfile" ]] || continue
      [[ "$(wc -c < "$sessionfile" | tr -d ' ')" -lt 100 ]] && continue
      session_date=$(date -r "$sessionfile" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "unknown")

      # weighted spend before first Edit/Write tool_use vs. whole session
      read -r ob_cost total_cost ob_msgs <<< $(
        jq -rs '
          def usage: (.message.usage // .usage // null);
          def w(u): (u.input_tokens//0) + (u.output_tokens//0)*5
                    + ((u.cache_read_input_tokens//0)/10)
                    + ((u.cache_creation_input_tokens//0)*5/4);
          def isedit: ((.message.content // []) | (type=="array")
                    and any(.type? == "tool_use"
                            and ((.name? // "") | test("^(Edit|Write|MultiEdit|NotebookEdit)$"))));
          . as $all
          | ([range(0;length) | select($all[.] | isedit)] | (.[0] // length)) as $cut
          | [ (([range(0;$cut) as $i | $all[$i] | usage | select(.!=null) | w(.)] | add) // 0),
              (([.[]            | usage | select(.!=null) | w(.)] | add) // 0),
              $cut ] | @tsv
        ' "$sessionfile" 2>/dev/null
      )
      ob_cost=${ob_cost:-0}; total_cost=${total_cost:-0}; ob_msgs=${ob_msgs:-0}
      ob_cost=${ob_cost%.*}; total_cost=${total_cost%.*}
      [[ "$total_cost" -eq 0 ]] && continue
      pct=$(( ob_cost * 100 / total_cost ))
      OB_ROWS+=("${session_date}|${project_name}|${ob_msgs}|${ob_cost}|${total_cost}|${pct}")
    done
  done

  IFS=$'\n' OB_SORTED=($(printf '%s\n' "${OB_ROWS[@]}" | sort -t'|' -k1 -r))
  unset IFS
  [[ "$RECENT_N" -gt 0 ]] && OB_SORTED=("${OB_SORTED[@]:0:$RECENT_N}")

  sum_ob=0; sum_tot=0
  for row in "${OB_SORTED[@]}"; do
    IFS='|' read -r date proj msgs ob tot pct <<< "$row"
    printf "  ${TEXT}%-18s %-20s %6s %12s %12s %5s%%${RESET}\n" "$date" "$proj" "$msgs" "$ob" "$tot" "$pct"
    sum_ob=$((sum_ob + ob)); sum_tot=$((sum_tot + tot))
  done

  echo ""
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────────────────${RESET}"
  avg_pct=0; [[ "$sum_tot" -gt 0 ]] && avg_pct=$(( sum_ob * 100 / sum_tot ))
  printf "  ${GREEN}%-45s %5s%%${RESET}\n" "Onboarding share of total weighted spend" "$avg_pct"
  echo ""
  echo -e "${MUTED}  Onboarding = weighted cost of messages before the first file edit (orientation +${RESET}"
  echo -e "${MUTED}  planning). 'Msgs' is how many turns that took. Compare against the static doc${RESET}"
  echo -e "${MUTED}  floor: bash spells/token-budget.sh --summary  (auto-injected + gist costs).${RESET}"
  echo ""
  exit 0
fi

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
    weighted=$(weighted_cost "$input_tok" "$output_tok" "$cache_read" "$cache_create")

    SESSION_DATA+=("${session_date}|${project_name}|${msg_count}|${input_tok}|${output_tok}|${cache_read}|${cache_create}|${weighted}|${session_id}")
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

# --- By-feature grouping (joins weighted spend to log/token-ledger.tsv) --------
if $MODE_BY_FEATURE; then
  declare -A FEAT_WEIGHTED FEAT_SESSIONS
  grand=0
  for row in "${SORTED[@]}"; do
    IFS='|' read -r date proj msgs inp outp cread cwrite weighted sid <<< "$row"
    feat="(untagged)"
    if [[ -f "$LEDGER" ]]; then
      hit=$(awk -F'\t' -v s="$sid" '/^#/{next} $1==s{print $2; exit}' "$LEDGER")
      [[ -n "$hit" ]] && feat="$hit"
    fi
    FEAT_WEIGHTED["$feat"]=$(( ${FEAT_WEIGHTED["$feat"]:-0} + weighted ))
    FEAT_SESSIONS["$feat"]=$(( ${FEAT_SESSIONS["$feat"]:-0} + 1 ))
    grand=$((grand + weighted))
  done

  echo ""
  echo -e "${MAGENTA}RaBbLE-Grimoire — Weighted Spend by Feature${RESET}"
  echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════════${RESET}"
  printf "  ${CYAN}%-24s %9s %14s %6s${RESET}\n" "Feature" "Sessions" "Weighted" "Pct"
  printf "  ${MUTED}%-24s %9s %14s %6s${RESET}\n" "────────────────────────" "─────────" "──────────────" "──────"

  if [[ ! -f "$LEDGER" ]]; then
    echo -e "  ${YELLOW}No ledger at log/token-ledger.tsv — all sessions show as (untagged).${RESET}"
  fi

  # sort features by weighted desc
  for line in $(for f in "${!FEAT_WEIGHTED[@]}"; do echo "${FEAT_WEIGHTED[$f]}|$f"; done | sort -t'|' -k1 -rn); do
    w="${line%%|*}"; f="${line#*|}"
    pct=0; [[ "$grand" -gt 0 ]] && pct=$(( w * 100 / grand ))
    printf "  ${TEXT}%-24s %9s %14s %5s%%${RESET}\n" "$f" "${FEAT_SESSIONS[$f]}" "$w" "$pct"
  done

  echo ""
  echo -e "${MUTED}  Tag sessions in log/token-ledger.tsv (session_id <TAB> feature) at end of session.${RESET}"
  echo -e "${MUTED}  Untagged sessions group together — fill the ledger to sharpen per-feature cost.${RESET}"
  echo ""
  exit 0
fi

# --- JSON output ---
if $OUTPUT_JSON; then
  mkdir -p "$GRIMOIRE_ROOT/log"
  json_out="$GRIMOIRE_ROOT/log/session-tokens.json"
  {
    echo '['
    first=true
    for row in "${SORTED[@]}"; do
      IFS='|' read -r date proj msgs inp outp cread cwrite weighted sid <<< "$row"
      $first || echo ','
      printf '  {"date":"%s","project":"%s","messages":%s,"input_tokens":%s,"output_tokens":%s,"cache_read":%s,"cache_write":%s,"weighted_cost":%s,"session":"%s"}' \
        "$date" "$proj" "$msgs" "$inp" "$outp" "$cread" "$cwrite" "$weighted" "$sid"
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
printf "  ${CYAN}%-18s %-20s %5s %9s %9s %11s %8s %11s${RESET}\n" \
  "Date" "Project" "Msgs" "Input" "Output" "CacheR" "CacheW" "Weighted"
printf "  ${MUTED}%-18s %-20s %5s %9s %9s %11s %8s %11s${RESET}\n" \
  "──────────────────" "────────────────────" "─────" "─────────" "─────────" "───────────" "────────" "───────────"

grand_input=0
grand_output=0
grand_cread=0
grand_cwrite=0
grand_weighted=0
declare -A PROJ_TOTAL

for row in "${SORTED[@]}"; do
  IFS='|' read -r date proj msgs inp outp cread cwrite weighted sid <<< "$row"
  printf "  ${TEXT}%-18s %-20s %5s %9s %9s %11s %8s %11s${RESET}\n" \
    "$date" "$proj" "$msgs" "$inp" "$outp" "$cread" "$cwrite" "$weighted"

  grand_input=$((grand_input + inp))
  grand_output=$((grand_output + outp))
  grand_cread=$((grand_cread + cread))
  grand_cwrite=$((grand_cwrite + cwrite))
  grand_weighted=$((grand_weighted + weighted))
  PROJ_TOTAL["$proj"]=$(( ${PROJ_TOTAL["$proj"]:-0} + weighted ))
done

echo ""
echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────────────────${RESET}"
printf "  ${GREEN}%-18s %-20s %5s %9s %9s %11s %8s %11s${RESET}\n" \
  "TOTAL" "(${#SORTED[@]} sessions)" "" "$grand_input" "$grand_output" "$grand_cread" "$grand_cwrite" "$grand_weighted"

# $ estimate: weighted units are input-equivalent tokens × input $/MTok
grand_dollars=$(awk "BEGIN{printf \"%.2f\", $grand_weighted/1000000*$INPUT_PRICE}")
echo -e "  ${VIOLET:-$CYAN}Weighted ≈ input-equivalent tokens (output×${W_OUTPUT}, cacheR×0.1, cacheW×1.25)${RESET}"
echo -e "  ${GREEN}Est. spend ≈ \$${grand_dollars}${RESET} ${MUTED}(at \$${INPUT_PRICE}/MTok input — override: RABBLE_INPUT_PRICE)${RESET}"

echo ""
echo -e "${CYAN}Per-Project Totals (weighted):${RESET}"
for proj in $(echo "${!PROJ_TOTAL[@]}" | tr ' ' '\n' | sort); do
  printf "  ${TEXT}%-30s${RESET} ${GREEN}%11s units${RESET}\n" "$proj" "${PROJ_TOTAL[$proj]}"
done

echo ""
echo -e "${MUTED}  Use --json to write log/session-tokens.json | --recent N for last N sessions${RESET}"
echo ""
