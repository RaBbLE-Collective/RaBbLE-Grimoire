#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — status.sh
# Collective health dashboard — one view of all project states
#
# Usage:
#   ./scripts/status.sh
#
# harmonize ~ collective >> substrate health surfaced // %STATUS_LOCKED%
# =============================================================================

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "status.sh — Collective health dashboard"
  echo ""
  echo "Usage: bash spells/status.sh"
  echo ""
  echo "Shows: epoch, branch, git state, AGENT.md presence, symlink status"
  echo "for every registered member in registry/manifests/."
  exit 0
fi

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
MANIFESTS_DIR="$GRIMOIRE_ROOT/registry/manifests"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
VIOLET='\033[38;2;191;95;255m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RED='\033[38;2;224;92;111m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
RESET='\033[0m'

pulse()  { echo -e "${MAGENTA}${1}${RESET}"; }
info()   { echo -e "${CYAN}${1}${RESET}"; }
muted()  { echo -e "${MUTED}${1}${RESET}"; }

get_manifest_field() {
  local manifest="$1" field="$2"
  grep "^${field}:" "$manifest" 2>/dev/null | sed "s/^${field}:[[:space:]]*//" | tr -d '"' || echo "—"
}

# Read current epoch
EPOCH_FILE="$GRIMOIRE_ROOT/registry/epochs/current.epoch.yml"
EPOCH_NUM=$(grep "^epoch:" "$EPOCH_FILE" 2>/dev/null | awk '{print $2}' || echo "?")
EPOCH_NAME=$(grep "^name:" "$EPOCH_FILE" 2>/dev/null | sed 's/^name:[[:space:]]*//' | tr -d '"' || echo "Unknown")

echo ""
pulse "RaBbLE-Grimoire — Status"
pulse "════════════════════════════════════════════════════════"
info "  Epoch ${EPOCH_NUM}: ${EPOCH_NAME}"
echo ""

# Header row
printf "${CYAN}  %-22s %-22s %-10s %-8s %-12s${RESET}\n" \
  "Project" "Branch" "State" "Epoch" "Grimoire"
printf "${MUTED}  %-22s %-22s %-10s %-8s %-12s${RESET}\n" \
  "────────────────────" "────────────────────" "────────" "──────" "──────────"

# Grimoire itself
branch=$(git -C "$GRIMOIRE_ROOT" branch --show-current 2>/dev/null || echo "unknown")
modified=$(git -C "$GRIMOIRE_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
[[ "$modified" == "0" ]] \
  && state="${GREEN}clean${RESET}" \
  || state="${VIOLET}~${modified}${RESET}"
printf "  %-22s %-22s " "RaBbLE-Grimoire" "$branch"
echo -e "${state}         ${EPOCH_NUM}       ${CYAN}canonical${RESET}"

# Project modules from manifests
if [[ -d "$MANIFESTS_DIR" ]]; then
  for manifest in "$MANIFESTS_DIR"/*.manifest.yml; do
    [[ -f "$manifest" ]] || continue
    [[ "$manifest" == *"_template"* ]] && continue

    slug=$(get_manifest_field "$manifest" "slug")
    status=$(get_manifest_field "$manifest" "status")
    epoch=$(get_manifest_field "$manifest" "epoch")
    worktree_root=$(get_manifest_field "$manifest" "worktree_root")
    project_dir="${worktree_root/#\~/$HOME}"
    if [[ -z "$project_dir" || "$project_dir" == "—" ]]; then
      project_dir="$RABBLE_ROOT/$slug"
    fi

    if [[ ! -d "$project_dir/.git" ]]; then
      printf "  %-22s %-22s " "$slug" "—"
      echo -e "${YELLOW}not cloned${RESET}   $epoch       —"
      continue
    fi

    branch=$(git -C "$project_dir" branch --show-current 2>/dev/null || echo "unknown")
    modified=$(git -C "$project_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    [[ "$modified" == "0" ]] \
      && state="${GREEN}clean${RESET}" \
      || state="${VIOLET}~${modified}${RESET}"

    # Check if project has AGENT.md (proxy for being wired into Collective)
    if [[ -f "$project_dir/AGENT.md" ]]; then
      grimoire_state="${GREEN}wired${RESET}"
    else
      grimoire_state="${RED}missing AGENT.md${RESET}"
    fi

    # Check symlinks
    symlink_ok=true
    [[ -L "$project_dir/CLAUDE.md" ]] || symlink_ok=false
    [[ -L "$project_dir/CODEX.md" ]]  || symlink_ok=false

    printf "  %-22s %-22s " "$slug" "$branch"
    echo -e "${state}   $epoch       ${grimoire_state}"

    if [[ "$symlink_ok" == "false" ]]; then
      echo -e "${YELLOW}    ⚠ Symlinks need setup — run: ./setup.sh --project $slug${RESET}"
    fi
  done
fi

echo ""
pulse "────────────────────────────────────────────────────────"

# Open issues count
if [[ -f "$GRIMOIRE_ROOT/common/RaBbLE-Collective-KnownIssues.md" ]]; then
  open_issues=$(grep -c "\[OPEN\]" "$GRIMOIRE_ROOT/common/RaBbLE-Collective-KnownIssues.md" 2>/dev/null || echo "0")
  info "  Open issues:    $open_issues (common/RaBbLE-Collective-KnownIssues.md)"
fi

# Palette version
palette_version=$(grep "^palette_version" "$MANIFESTS_DIR"/*.manifest.yml 2>/dev/null \
  | awk -F'"' '{print $2}' | sort -u | tr '\n' ' ' || echo "—")
info "  Palette ver:    ${palette_version}(check RaBbLE-Palette.md for current)"

echo ""
muted "  Run ./setup.sh to wire any missing symlinks or pull stale projects."
muted "  Run ./spells/sync-grimoire.sh to push grimoire updates to all projects."
echo ""
