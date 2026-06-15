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
  echo "Shows: epoch, branch, git state, episode alignment (in-step / off-track),"
  echo "AGENT.md presence, and symlink status for every member in registry/manifests/."
  echo ""
  echo "Alignment: members on 'release_track: episode' must sit on the epoch's"
  echo "active_branch to be 'in-step'; 'release_track: independent' members are exempt."
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
EPISODE_PENDING=$(grep "^episode_pending:" "$EPOCH_FILE" 2>/dev/null | awk '{print $2}' || echo "?")
ACTIVE_BRANCH=$(grep "^active_branch:" "$EPOCH_FILE" 2>/dev/null | sed 's/^active_branch:[[:space:]]*//' | tr -d '"' || echo "")

# Collect off-track members for an end-of-report summary.
OFF_TRACK=()

# Resolve a manifest worktree_root to an absolute path.
#   ~/...      → $HOME/...
#   relative   → $RABBLE_ROOT/<relative>   (members are nested in the Collective root)
#   empty / —  → $RABBLE_ROOT/<slug>
resolve_dir() {
  local wt="$1" slug="$2" dir
  dir="${wt/#\~/$HOME}"
  if [[ -z "$dir" || "$dir" == "—" ]]; then
    dir="$RABBLE_ROOT/$slug"
  elif [[ "$dir" != /* ]]; then
    dir="$RABBLE_ROOT/$dir"
  fi
  echo "$dir"
}

# In-step marker for a member.
#   release_track=independent → exempt (sandbox/archive)
#   release_track=episode     → must be on $ACTIVE_BRANCH, else off-track
align_marker() {
  local track="$1" actual="$2"
  if [[ "$track" == "independent" ]]; then
    echo -e "${MUTED}indep${RESET}"
  elif [[ -z "$ACTIVE_BRANCH" || "$actual" == "$ACTIVE_BRANCH" ]]; then
    echo -e "${GREEN}in-step${RESET}"
  else
    echo -e "${RED}off-track${RESET}"
  fi
}

echo ""
pulse "RaBbLE-Grimoire — Status"
pulse "════════════════════════════════════════════════════════"
info "  Epoch ${EPOCH_NUM}: ${EPOCH_NAME}  ·  Episode ${EPISODE_PENDING} pending  ·  active branch: ${ACTIVE_BRANCH:-—}"
echo ""

# Header row
printf "${CYAN}  %-20s %-16s %-8s %-11s %-12s${RESET}\n" \
  "Project" "Branch" "State" "Align" "Grimoire"
printf "${MUTED}  %-20s %-16s %-8s %-11s %-12s${RESET}\n" \
  "──────────────────" "──────────────" "──────" "─────────" "──────────"

# Grimoire itself — canonical; tracks the active branch like any lockstep member
branch=$(git -C "$GRIMOIRE_ROOT" branch --show-current 2>/dev/null || echo "unknown")
modified=$(git -C "$GRIMOIRE_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
[[ "$modified" == "0" ]] \
  && state="${GREEN}clean${RESET}" \
  || state="${VIOLET}~${modified}${RESET}"
printf "  %-20s %-16s %b      %b   ${CYAN}canonical${RESET}\n" \
  "RaBbLE-Grimoire" "$branch" "$state" "$(align_marker episode "$branch")"
[[ -n "$ACTIVE_BRANCH" && "$branch" != "$ACTIVE_BRANCH" ]] && OFF_TRACK+=("RaBbLE-Grimoire ($branch)")

# Project modules from manifests
if [[ -d "$MANIFESTS_DIR" ]]; then
  for manifest in "$MANIFESTS_DIR"/*.manifest.yml; do
    [[ -f "$manifest" ]] || continue
    [[ "$manifest" == *"_template"* ]] && continue

    slug=$(get_manifest_field "$manifest" "slug")
    track=$(get_manifest_field "$manifest" "release_track")
    track="${track%%#*}"; track="${track// /}"   # strip inline comment + spaces
    worktree_root=$(get_manifest_field "$manifest" "worktree_root")
    project_dir="$(resolve_dir "$worktree_root" "$slug")"

    if [[ ! -d "$project_dir/.git" ]]; then
      printf "  %-20s %-16s ${YELLOW}%-8s${RESET} %-11s —\n" "$slug" "—" "uncloned" ""
      continue
    fi

    branch=$(git -C "$project_dir" branch --show-current 2>/dev/null || echo "unknown")
    modified=$(git -C "$project_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    [[ "$modified" == "0" ]] \
      && state="${GREEN}clean${RESET}" \
      || state="${VIOLET}~${modified}${RESET}"

    # AGENT.md presence = wired into the Collective
    if [[ -f "$project_dir/AGENT.md" ]]; then
      grimoire_state="${GREEN}wired${RESET}"
    else
      grimoire_state="${RED}no AGENT.md${RESET}"
    fi

    symlink_ok=true
    [[ -L "$project_dir/CLAUDE.md" ]] || symlink_ok=false
    [[ -L "$project_dir/CODEX.md" ]]  || symlink_ok=false

    printf "  %-20s %-16s %b      %b   %b\n" \
      "$slug" "$branch" "$state" "$(align_marker "$track" "$branch")" "$grimoire_state"

    if [[ "$track" != "independent" && -n "$ACTIVE_BRANCH" && "$branch" != "$ACTIVE_BRANCH" ]]; then
      OFF_TRACK+=("$slug ($branch, expected $ACTIVE_BRANCH)")
    fi
    if [[ "$symlink_ok" == "false" ]]; then
      echo -e "${YELLOW}    ⚠ Symlinks missing — run: bash spells/sync-symlinks.sh${RESET}"
    fi
  done
fi

echo ""
pulse "────────────────────────────────────────────────────────"

# Episode alignment summary — the "moving toward episodes in step" check
if [[ ${#OFF_TRACK[@]} -eq 0 ]]; then
  info "  Episode alignment:  ${GREEN}all lockstep members in step on ${ACTIVE_BRANCH}${RESET}"
else
  echo -e "${RED}  Episode alignment:  ${#OFF_TRACK[@]} member(s) off-track${RESET}"
  for m in "${OFF_TRACK[@]}"; do
    echo -e "${YELLOW}    ⚠ $m${RESET}"
  done
fi

# Episode-1 blockers declared in the epoch focus map
BLOCKERS=$(awk '
  /^  [A-Za-z][A-Za-z-]*:[[:space:]]*$/ { m=$1; sub(/:$/,"",m); next }
  /episode_1_blocker:[[:space:]]*true/  { print m }
' "$EPOCH_FILE" 2>/dev/null | paste -sd, - | sed 's/,/, /g')
if [[ -n "$BLOCKERS" ]]; then
  echo -e "${YELLOW}  Episode ${EPISODE_PENDING} blockers:  ${BLOCKERS}${RESET}"
else
  info "  Episode ${EPISODE_PENDING} blockers:  none declared"
fi

# Palette version
palette_version=$(grep "^palette_version" "$MANIFESTS_DIR"/*.manifest.yml 2>/dev/null \
  | awk -F'"' '{print $2}' | sort -u | tr '\n' ' ' || echo "—")
info "  Palette ver:        ${palette_version}(source: RaBbLE-Agent/RaBbLE-Palette.md)"

echo ""
muted "  Run bash spells/setup.sh to clone/pull members and wire symlinks."
muted "  Members reference the Grimoire directly — there is nothing to sync."
echo ""
