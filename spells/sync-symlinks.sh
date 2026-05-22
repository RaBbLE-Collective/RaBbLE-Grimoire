#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — sync-symlinks.sh
# Creates CLAUDE.md, CODEX.md, GEMINI.md → AGENT.md symlinks in every member
# repo and ensures those names are gitignored.
#
# Usage:
#   bash spells/sync-symlinks.sh              # all repos
#   bash spells/sync-symlinks.sh --dry-run    # preview only
#
# AGENT.md is the canonical file. Symlinks are gitignored derivatives.
#
# harmonize ~ grimoire >> symlinks are the nervous system's synapses // %SYMLINKS%
# =============================================================================

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "sync-symlinks.sh — create CLAUDE.md/CODEX.md/GEMINI.md → AGENT.md symlinks"
  echo ""
  echo "Usage: bash spells/sync-symlinks.sh [--dry-run]"
  echo "  --dry-run   Preview changes without writing"
  echo ""
  echo "Creates symlinks in every member repo that has an AGENT.md."
  echo "Ensures CLAUDE.md, CODEX.md, GEMINI.md are in each repo's .gitignore."
  exit 0
fi

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
DRY_RUN="${1:-}"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
MUTED='\033[38;2;107;104;128m'
RESET='\033[0m'

SYMLINK_NAMES=("CLAUDE.md" "CODEX.md" "GEMINI.md")
GITIGNORE_ENTRIES=("CLAUDE.md" "CODEX.md" "GEMINI.md")

created=0
skipped=0
gitignore_fixed=0

ensure_gitignore() {
  local dir="$1"
  local gi="$dir/.gitignore"

  for entry in "${GITIGNORE_ENTRIES[@]}"; do
    if [[ -f "$gi" ]]; then
      if ! grep -qxF "$entry" "$gi"; then
        if [[ "$DRY_RUN" == "--dry-run" ]]; then
          echo -e "  ${YELLOW}would add${RESET} $entry to .gitignore"
        else
          echo "$entry" >> "$gi"
          echo -e "  ${GREEN}added${RESET} $entry to .gitignore"
        fi
        ((gitignore_fixed++)) || true
      fi
    else
      if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo -e "  ${YELLOW}would create${RESET} .gitignore with $entry"
      else
        echo "$entry" > "$gi"
        echo -e "  ${GREEN}created${RESET} .gitignore with $entry"
      fi
      ((gitignore_fixed++)) || true
    fi
  done
}

link_one() {
  local dir="$1"
  local name
  local agent="$dir/AGENT.md"

  if [[ ! -f "$agent" ]]; then
    return
  fi

  local label="${dir#$RABBLE_ROOT/}"
  echo -e "${CYAN}${label}${RESET}"

  for name in "${SYMLINK_NAMES[@]}"; do
    local target="$dir/$name"
    if [[ -L "$target" ]]; then
      local current
      current=$(readlink "$target")
      if [[ "$current" == "AGENT.md" ]]; then
        ((skipped++)) || true
        continue
      fi
    fi

    if [[ -f "$target" && ! -L "$target" ]]; then
      if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo -e "  ${YELLOW}would replace${RESET} real file $name → AGENT.md"
      else
        rm "$target"
        ln -s "AGENT.md" "$target"
        echo -e "  ${GREEN}replaced${RESET} real file $name → AGENT.md"
      fi
    elif [[ ! -e "$target" ]]; then
      if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo -e "  ${YELLOW}would create${RESET} $name → AGENT.md"
      else
        ln -s "AGENT.md" "$target"
        echo -e "  ${GREEN}created${RESET} $name → AGENT.md"
      fi
    else
      if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo -e "  ${YELLOW}would fix${RESET} $name → AGENT.md"
      else
        rm "$target"
        ln -s "AGENT.md" "$target"
        echo -e "  ${GREEN}fixed${RESET} $name → AGENT.md"
      fi
    fi
    ((created++)) || true
  done

  ensure_gitignore "$dir"
  echo ""
}

echo ""
echo -e "${MAGENTA}RaBbLE-Grimoire — sync-symlinks.sh${RESET}"
if [[ "$DRY_RUN" == "--dry-run" ]]; then
  echo -e "${YELLOW}DRY RUN — no changes will be written${RESET}"
fi
echo ""

# Collective root
link_one "$RABBLE_ROOT"

# All RaBbLE-* member dirs
for dir in "$RABBLE_ROOT"/RaBbLE-*/; do
  [[ -d "$dir" ]] || continue
  link_one "${dir%/}"
done

echo -e "${MAGENTA}────────────────────────────────────────${RESET}"
echo -e "  Symlinks created/fixed: ${GREEN}${created}${RESET}"
echo -e "  Already correct:        ${MUTED}${skipped}${RESET}"
echo -e "  Gitignore entries added: ${GREEN}${gitignore_fixed}${RESET}"
echo ""
