#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — token-budget.sh
# Calculates the token cost of agent onboarding paths and doc surface area.
#
# Usage:
#   bash spells/token-budget.sh              # full report
#   bash spells/token-budget.sh --summary    # totals only
#
# Token estimate: words × 1.33 (English markdown → LLM tokens approximation)
#
# spark ~ grimoire >> know what you're paying to think // %TOKEN_BUDGET%
# =============================================================================

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "token-budget.sh — calculate token cost of agent onboarding and doc surface"
  echo ""
  echo "Usage: bash spells/token-budget.sh [--summary]"
  echo "  --summary   Print totals only, skip per-file breakdown"
  echo ""
  echo "Estimates tokens using word count × 1.33 multiplier."
  echo "Reports: auto-injected cost, gist cost, reading paths, full surface."
  exit 0
fi

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
SUMMARY_ONLY="${1:-}"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
VIOLET='\033[38;2;191;95;255m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RESET='\033[0m'

token_count() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local words
    words=$(wc -w < "$file" | tr -d ' ')
    echo $(( (words * 133 + 50) / 100 ))
  else
    echo 0
  fi
}

print_file_tokens() {
  local file="$1"
  local label="${2:-$file}"
  local tokens
  tokens=$(token_count "$file")
  if [[ "$SUMMARY_ONLY" != "--summary" ]]; then
    printf "  ${TEXT}%-60s${RESET} ${CYAN}%6d${RESET}\n" "$label" "$tokens" >&2
  fi
  echo "$tokens"
}

section_header() {
  echo "" >&2
  echo -e "${MAGENTA}$1${RESET}" >&2
  if [[ "$SUMMARY_ONLY" != "--summary" ]]; then
    printf "  ${MUTED}%-60s %6s${RESET}\n" "File" "Tokens" >&2
    printf "  ${MUTED}%-60s %6s${RESET}\n" "────────────────────────────────────────────────────────────" "──────" >&2
  fi
}

section_total() {
  local total="$1" label="$2"
  echo -e "  ${VIOLET}${label}: ${GREEN}~${total} tokens${RESET}" >&2
}

echo ""
echo -e "${MAGENTA}RaBbLE-Grimoire — Token Budget Report${RESET}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════${RESET}"

# --- Auto-injected per session (AGENT.md + CONTEXT.md per repo) ---
section_header "Auto-Injected Per Session (AGENT.md + CONTEXT.md)"
auto_total=0

for dir in "$RABBLE_ROOT" "$RABBLE_ROOT"/RaBbLE-*/; do
  [[ -d "$dir" ]] || continue
  label="${dir#$RABBLE_ROOT/}"
  [[ -z "$label" ]] && label="RaBbLE-Collective (root)"
  label="${label%/}"

  for f in AGENT.md CONTEXT.md; do
    if [[ -f "$dir/$f" ]]; then
      t=$(print_file_tokens "$dir/$f" "$label/$f")
      auto_total=$((auto_total + t))
    fi
  done
done
section_total "$auto_total" "Auto-injected total (all repos combined — one pair loaded per session)"

# --- Gist onboarding ---
section_header "Gist Onboarding (cat gist/*.md)"
gist_total=0
for f in "$GRIMOIRE_ROOT"/gist/*.md; do
  [[ -f "$f" ]] || continue
  t=$(print_file_tokens "$f" "gist/$(basename "$f")")
  gist_total=$((gist_total + t))
done
section_total "$gist_total" "Gist total"

# --- 5-minute skim ---
section_header "5-Minute Skim (Navigator path)"
skim_total=0
skim_files=(
  "$GRIMOIRE_ROOT/RaBbLE-Agent/RaBbLE-Identity.md"
  "$GRIMOIRE_ROOT/CONTEXT.md"
)
for f in "${skim_files[@]}"; do
  [[ -f "$f" ]] || continue
  t=$(print_file_tokens "$f" "${f#$GRIMOIRE_ROOT/}")
  skim_total=$((skim_total + t))
done
section_total "$skim_total" "5-min skim"

# --- 15-minute deep dive ---
section_header "15-Minute Deep Dive (Navigator path)"
deep_total=$skim_total
deep_files=(
  "$GRIMOIRE_ROOT/RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md"
)
for f in "${deep_files[@]}"; do
  [[ -f "$f" ]] || continue
  t=$(print_file_tokens "$f" "${f#$GRIMOIRE_ROOT/}")
  deep_total=$((deep_total + t))
done
section_total "$deep_total" "15-min deep dive (includes 5-min)"

# --- 30-minute full onboarding ---
section_header "30-Minute Full Onboarding (Navigator path)"
full_total=$deep_total
full_files=(
  "$GRIMOIRE_ROOT/RaBbLE-Versioning.md"
  "$GRIMOIRE_ROOT/RaBbLE-Agent/RaBbLE-CommitStyle.md"
  "$GRIMOIRE_ROOT/RaBbLE-Agent/RaBbLE-Agent-Protocols.md"
  "$GRIMOIRE_ROOT/RaBbLE-Agent/RaBbLE-Roadmap.md"
  "$GRIMOIRE_ROOT/INDEX.md"
)
for f in "${full_files[@]}"; do
  [[ -f "$f" ]] || continue
  t=$(print_file_tokens "$f" "${f#$GRIMOIRE_ROOT/}")
  full_total=$((full_total + t))
done
section_total "$full_total" "30-min full onboarding (includes 5+15)"

# --- Full Grimoire surface ---
section_header "Full Grimoire Surface (all .md files)"
surface_total=0
file_count=0
while IFS= read -r f; do
  t=$(token_count "$f")
  surface_total=$((surface_total + t))
  ((file_count++)) || true
  if [[ "$SUMMARY_ONLY" != "--summary" ]]; then
    printf "  ${MUTED}%-60s${RESET} ${MUTED}%6d${RESET}\n" "${f#$GRIMOIRE_ROOT/}" "$t" >&2
  fi
done < <(find "$GRIMOIRE_ROOT" -name '*.md' -type f | sort)
section_total "$surface_total" "Full surface ($file_count files)"

# --- Summary ---
echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${CYAN}Summary${RESET}"
printf "  ${TEXT}%-45s${RESET} ${GREEN}~%d tokens${RESET}\n" "Auto-injected (AGENT.md + CONTEXT.md)" "$auto_total"
printf "  ${TEXT}%-45s${RESET} ${GREEN}~%d tokens${RESET}\n" "Gist onboarding (recommended start)" "$gist_total"
printf "  ${TEXT}%-45s${RESET} ${GREEN}~%d tokens${RESET}\n" "5-min skim" "$skim_total"
printf "  ${TEXT}%-45s${RESET} ${GREEN}~%d tokens${RESET}\n" "15-min deep dive" "$deep_total"
printf "  ${TEXT}%-45s${RESET} ${GREEN}~%d tokens${RESET}\n" "30-min full onboarding" "$full_total"
printf "  ${TEXT}%-45s${RESET} ${GREEN}~%d tokens${RESET}\n" "Full Grimoire surface ($file_count files)" "$surface_total"
echo ""
echo -e "${MUTED}  Token estimate: words × 1.33 — rough approximation for English markdown.${RESET}"
echo ""
