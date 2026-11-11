#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — help.sh
# Lists all available spells with their purpose. The meta-spell.
#
# Usage:
#   bash spells/help.sh
#
# transcribe ~ grimoire >> the spellbook opens // %HELP%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPELLS_DIR="$GRIMOIRE_ROOT/spells"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
GREEN='\033[38;2;80;250;123m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RESET='\033[0m'

echo ""
echo -e "${MAGENTA}RaBbLE-Grimoire — Spellbook${RESET}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════${RESET}"
echo ""

# Extract one-line description from each spell's header comments
for spell in "$SPELLS_DIR"/*; do
  [[ -f "$spell" ]] || continue
  name=$(basename "$spell")

  # Skip self and non-scripts
  [[ "$name" == "help.sh" ]] && continue

  # Extract purpose line from header: line after "scriptname" that isn't boilerplate
  desc=""
  desc=$(awk '
    /^# .*'"${name%.*}"'/ {
      while (getline > 0) {
        if (/^#[ ]+[A-Z]/ && !/^# Usage/ && !/^# =/) {
          sub(/^# */, ""); print; exit
        }
        if (!/^#/) exit
      }
    }
  ' "$spell" 2>/dev/null || true)

  # Fallback: first substantial comment line
  if [[ -z "$desc" ]]; then
    desc=$(awk '/^# [A-Z]/ && !/^# =/ && !/^# Usage/ { sub(/^# */, ""); print; exit }' "$spell" 2>/dev/null || true)
  fi

  [[ -z "$desc" ]] && desc="(no description)"

  printf "  ${GREEN}%-28s${RESET} ${TEXT}%s${RESET}\n" "$name" "$desc"
done

echo ""
echo -e "${MUTED}  Run any spell with --help for usage details.${RESET}"
echo -e "${MUTED}  All spells run from Grimoire root: bash spells/<name>.sh${RESET}"
echo ""
