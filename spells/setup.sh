#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — setup.sh
# Bootstrap the Collective: symlinks, project pulls, context wiring
#
# Usage:
#   ./setup.sh              — full setup (symlinks + pull all projects)
#   ./setup.sh --links-only — symlinks only, no project pulls
#   ./setup.sh --pull-only  — pull/update projects only, no symlink changes
#   ./setup.sh --project RaBbLE-OS  — pull and wire a single project
#
# harmonize ~ bootstrap >> collective substrate initialized // %SETUP_LOCKED%
# =============================================================================

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(dirname "$SCRIPTS_DIR")"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
SCRIPT_NAME="$(basename "$0")"

# --- Colors (RaBbLE palette) -------------------------------------------------
MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
VIOLET='\033[38;2;191;95;255m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RED='\033[38;2;224;92;111m'
GREEN='\033[38;2;80;250;123m'
RESET='\033[0m'

pulse()    { echo -e "${MAGENTA}${1}${RESET}"; }
info()     { echo -e "${CYAN}  ${1}${RESET}"; }
muted()    { echo -e "${MUTED}  ${1}${RESET}"; }
success()  { echo -e "${GREEN}  ✓ ${1}${RESET}"; }
warn()     { echo -e "${VIOLET}  ⚠ ${1}${RESET}"; }
error()    { echo -e "${RED}  ✗ ${1}${RESET}"; }

# Grimoire expands but does not relocate. Run from wherever it lives.
info "Grimoire root: $GRIMOIRE_ROOT"
info "RaBbLE root:     $RABBLE_ROOT"
echo ""

# --- Argument parsing --------------------------------------------------------
MODE="full"
TARGET_PROJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --links-only)   MODE="links"; shift ;;
    --pull-only)    MODE="pull";  shift ;;
    --project)      TARGET_PROJECT="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $SCRIPT_NAME [--links-only] [--pull-only] [--project <slug>]"
      exit 0 ;;
    *) error "Unknown argument: $1"; exit 1 ;;
  esac
done

# =============================================================================
# SYMLINK SETUP
# AGENT.md is the owner. CLAUDE.md and CODEX.md symlink to it.
# =============================================================================

setup_symlinks() {
  local target_dir="$1"
  local agent_file="$target_dir/AGENT.md"

  if [[ ! -f "$agent_file" ]]; then
    warn "No AGENT.md found in $target_dir — skipping symlinks"
    return
  fi

  # CLAUDE.md → AGENT.md
  local claude="$target_dir/CLAUDE.md"
  if [[ -L "$claude" ]]; then
    muted "CLAUDE.md symlink already exists in $(basename $target_dir)"
  elif [[ -f "$claude" ]]; then
    warn "CLAUDE.md is a real file in $(basename $target_dir) — backing up as CLAUDE.md.bak"
    mv "$claude" "${claude}.bak"
    ln -s AGENT.md "$claude"
    success "CLAUDE.md → AGENT.md (was real file, backed up)"
  else
    ln -s AGENT.md "$claude"
    success "CLAUDE.md → AGENT.md in $(basename $target_dir)"
  fi

  # CODEX.md → AGENT.md
  local codex="$target_dir/CODEX.md"
  if [[ -L "$codex" ]]; then
    muted "CODEX.md symlink already exists in $(basename $target_dir)"
  elif [[ -f "$codex" ]]; then
    warn "CODEX.md is a real file in $(basename $target_dir) — backing up as CODEX.md.bak"
    mv "$codex" "${codex}.bak"
    ln -s AGENT.md "$codex"
    success "CODEX.md → AGENT.md (was real file, backed up)"
  else
    ln -s AGENT.md "$codex"
    success "CODEX.md → AGENT.md in $(basename $target_dir)"
  fi
}

# =============================================================================
# PROJECT MANIFEST READER
# Reads manifests/RaBbLE-*.manifest.yml and returns project metadata
# =============================================================================

get_manifest_field() {
  local manifest="$1"
  local field="$2"
  grep "^${field}:" "$manifest" | sed "s/^${field}:[[:space:]]*//" | tr -d '"'
}

# =============================================================================
# PROJECT PULL + WIRE
# Clones or updates a project repo, sets up its symlinks and context wiring
# =============================================================================

pull_and_wire_project() {
  local manifest="$1"
  local slug repo status local_path

  slug=$(get_manifest_field "$manifest" "slug")
  repo=$(get_manifest_field "$manifest" "repo")
  status=$(get_manifest_field "$manifest" "status")
  local worktree_root
  worktree_root=$(get_manifest_field "$manifest" "worktree_root")
  local_path="${worktree_root/#\~/$HOME}"
  if [[ -z "$local_path" || "$local_path" == "—" ]]; then
    local_path="$RABBLE_ROOT/$slug"
  fi

  pulse ""
  pulse "── $slug"
  muted "status: $status | repo: $repo"

  # Skip pending projects unless explicitly requested
  if [[ "$status" == "pending" && -z "$TARGET_PROJECT" ]]; then
    muted "Skipping $slug (status: pending) — use --project $slug to force"
    return
  fi

  if [[ "$repo" == "TBD"* ]]; then
    warn "$slug has no remote yet — skipping clone"
    return
  fi

  # Clone or update
  if [[ -d "$local_path/.git" ]]; then
    info "Updating $slug..."
    git -C "$local_path" fetch --quiet
    git -C "$local_path" pull --quiet --ff-only 2>/dev/null \
      || warn "Could not fast-forward $slug — check for local changes"
    success "$slug up to date"
  else
    info "Cloning $slug into $local_path..."
    git clone "$repo" "$local_path"
    success "$slug cloned"
  fi

  # Set up project symlinks
  setup_symlinks "$local_path"

  success "$slug fully wired"
}

# =============================================================================
# MAIN
# =============================================================================

echo ""
pulse "RaBbLE-Grimoire — Setup"
pulse "════════════════════════════════════════"
info "Grimoire root:   $GRIMOIRE_ROOT"
info "RaBbLE root:     $RABBLE_ROOT"
info "Mode:            $MODE"
[[ -n "$TARGET_PROJECT" ]] && info "Target project:  $TARGET_PROJECT"
echo ""

# Step 1: Collective root + Grimoire symlinks
if [[ "$MODE" != "pull" ]]; then
  pulse "── RaBbLE-Collective (root)"
  setup_symlinks "$RABBLE_ROOT"

  pulse "── RaBbLE-Grimoire (this repo)"
  setup_symlinks "$GRIMOIRE_ROOT"
fi

# Step 2: Project pulls and wiring
if [[ "$MODE" != "links" ]]; then
  pulse ""
  pulse "── Project Modules"

  MANIFESTS_DIR="$GRIMOIRE_ROOT/registry/manifests"

  if [[ ! -d "$MANIFESTS_DIR" ]]; then
    warn "No manifests/ directory found — skipping project setup"
    warn "Run: mkdir -p registry/manifests && ./spells/init-project.sh to register projects"
  else
    for manifest in "$MANIFESTS_DIR"/*.manifest.yml; do
      [[ -f "$manifest" ]] || continue
      [[ "$manifest" == *"_template"* ]] && continue

      local_slug=$(get_manifest_field "$manifest" "slug")

      # If --project flag set, only process that project
      if [[ -n "$TARGET_PROJECT" && "$local_slug" != "$TARGET_PROJECT" ]]; then
        continue
      fi

      pull_and_wire_project "$manifest"
    done
  fi
fi

# Step 3: Status summary
echo ""
pulse "── Status"
echo ""
printf "${CYAN}  %-20s %-15s %-10s${RESET}\n" "Project" "Branch" "State"
printf "${MUTED}  %-20s %-15s %-10s${RESET}\n" "──────────────────" "─────────────" "────────"

for project_dir in "$RABBLE_ROOT"/RaBbLE-*/; do
  [[ -d "$project_dir/.git" ]] || continue
  local_slug="$(basename "$project_dir")"
  branch=$(git -C "$project_dir" branch --show-current 2>/dev/null || echo "unknown")
  state=$(git -C "$project_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [[ "$state" == "0" ]] && state_str="${GREEN}clean${RESET}" || state_str="${VIOLET}${state} modified${RESET}"
  printf "  %-20s %-15s " "$local_slug" "$branch"
  echo -e "$state_str"
done

echo ""
pulse "harmonize ~ bootstrap >> collective substrate wired // %SETUP_COMPLETE%"
echo ""

# Grimoire does not relocate — no bootstrap cleanup needed.
