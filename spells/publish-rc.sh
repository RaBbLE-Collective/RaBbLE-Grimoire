#!/usr/bin/env bash
# =============================================================================
# spells/publish-rc.sh — Release Candidate Publishing (Fully Automated)
#
# Creates RC branch, builds, tags, and publishes to CDN — all as RaBbLE-dev.
# Zero manual steps. Call this from main/dev branch with a version.
#
# Mechanics:
# 1. Create rc/v* branch as RaBbLE-dev (from current branch)
# 2. Make initial RC commit as RaBbLE-dev
# 3. Push branch to remote
# 4. Build the project (npm run build)
# 5. Auto-increment and tag with -rc.N as RaBbLE-dev
# 6. Push tag to GitHub (triggers GitHub Actions → CDN deploy)
#
# Usage:
#   bash spells/publish-rc.sh v0.0.0.1               # Create RC branch & publish
#   bash spells/publish-rc.sh v0.0.0.1 --dry-run     # Preview what would happen
#   bash spells/publish-rc.sh                        # Show usage
#
# Workflow:
#   1. Run this once per RC version
#   2. GitHub Actions builds and deploys to CDN
#   3. Test from: https://aether.joinrabble.world/v0.0.0.1-rc.1/
#   4. If fixes needed: commit to rc/v0.0.0.1 and run this again (auto-increments RC)
#   5. When approved: merge rc/v0.0.0.1 → main and run bash spells/seal-episode.sh
#
# spark ~ rabble-dev >> RC branch creation & publishing, fully automated // %RC_PUBLISH%
# =============================================================================

set -euo pipefail

# ─ Colors ────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✓${RESET}  $*"; }
info() { echo -e "  ${CYAN}·${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()  { echo -e "  ${RED}✗${RESET}  $*" >&2; }
header() { echo -e "\n${MAGENTA}$*${RESET}\n"; }

# ─ RaBbLE-dev Identity ───────────────────────────────────────────────────────
DEV_NAME="${DEV_NAME:-RaBbLE Development}"
DEV_EMAIL="${DEV_EMAIL:-dev@rabble.world}"

# ─ Parse Arguments ───────────────────────────────────────────────────────────
MEMBER="${1:-}"
VERSION="${2:-}"
DRY_RUN=false

# Check if first arg is a version (starts with v)
if [[ "$MEMBER" =~ ^v[0-9] ]]; then
  # First arg is actually version, auto-detect member
  VERSION="$MEMBER"
  MEMBER=""
  # Parse flags from second position
  if [ "${2:-}" = "--dry-run" ]; then
    DRY_RUN=true
  fi
else
  # First arg is member, second is version
  # Parse flags from third position
  if [ "${3:-}" = "--dry-run" ]; then
    DRY_RUN=true
  fi
fi

if [ -z "$VERSION" ]; then
  cat <<'USAGE'
Usage: bash spells/publish-rc.sh [<member>] <version> [--dry-run]

       OR (from member directory):
       bash spells/publish-rc.sh <version> [--dry-run]

Members:
  aether       RaBbLE-Aether (CSS design system)
  nebula       RaBbLE-NeBuLA (rendering engine)
  world        RaBbLE-World (entry point)

Examples:
  # From within member repo
  bash spells/publish-rc.sh v0.0.0.1              # Auto-detect member
  bash spells/publish-rc.sh v0.0.0.1 --dry-run    # Preview

  # Explicit member (from anywhere)
  bash spells/publish-rc.sh aether v0.0.0.1
  bash spells/publish-rc.sh nebula v0.0.0.1 --dry-run

The script will:
  1. Create rc/v0.0.0.1 branch from current branch (as RaBbLE-dev)
  2. Make initial commit
  3. Push branch to remote
  4. Build the project
  5. Tag with v0.0.0.1-rc.1 (auto-incremented)
  6. Push tag to trigger GitHub Actions → CDN deploy

USAGE
  exit 0
fi

# Auto-detect member from current directory if not specified
if [ -z "$MEMBER" ]; then
  CURRENT_DIR=$(basename "$PWD")
  # Extract member name from RaBbLE-Aether → aether
  if [[ "$CURRENT_DIR" =~ ^RaBbLE-([a-zA-Z]+)$ ]]; then
    MEMBER="${BASH_REMATCH[1]}"
    MEMBER=$(echo "$MEMBER" | tr '[:upper:]' '[:lower:]')
  else
    err "Could not auto-detect member from directory: $CURRENT_DIR"
    info "Run: bash spells/publish-rc.sh <member> <version>"
    exit 1
  fi
fi

# Normalize version (remove leading v if present)
VERSION="${VERSION#v}"
RC_BRANCH="rc/v${VERSION}"
BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# ─ Preflight Checks ──────────────────────────────────────────────────────────
header "╔══════════════════════════════════════════════════════════╗"
header "║  Release Candidate Publishing — Fully Automated           ║"
header "╚══════════════════════════════════════════════════════════╝"

[ "$DRY_RUN" = "true" ] && warn "DRY RUN — no changes will be made"

info "Checking prerequisites..."

# Verify on main or dev branch
if ! [[ "$BASE_BRANCH" =~ ^(main|dev|master)$ ]]; then
  err "Must be on main/dev/master branch (currently on: $BASE_BRANCH)"
  exit 1
fi

ok "On $BASE_BRANCH"

# Verify clean working tree
if [ -n "$(git status --porcelain)" ]; then
  err "Working tree is not clean. Commit or stash changes first."
  exit 1
fi

ok "Working tree clean"

# ─ Display Plan ──────────────────────────────────────────────────────────────
echo ""
header "Release Plan — $MEMBER"

info "Member:            $MEMBER"
info "Current branch:    $BASE_BRANCH"
info "RC branch:         $RC_BRANCH"
info "Version:           v$VERSION"
info "Author:            $DEV_NAME <$DEV_EMAIL>"

# Determine next RC number
RC_NUM=1
while git rev-parse "v${VERSION}-rc.${RC_NUM}" >/dev/null 2>&1; do
  ((RC_NUM++))
done

RC_TAG="v${VERSION}-rc.${RC_NUM}"
info "RC tag:            $RC_TAG"

if [ -f "package.json" ]; then
  info "Build:             npm run build"
else
  info "Build:             (skipped — no package.json)"
fi

info ""
info "After publish:"
info "  • GitHub Actions will build and deploy to CDN"
info "  • Monitor at: https://github.com/markm1206/RaBbLE-Aether/actions"
info "  • Test from: https://aether.joinrabble.world/$RC_TAG/"
info "  • If fixes needed: commit to $RC_BRANCH and run this again"

# ─ Confirmation ──────────────────────────────────────────────────────────────
echo ""
if [ "$DRY_RUN" = "true" ]; then
  info "Dry run complete — no changes made."
  exit 0
else
  read -r -p "  Proceed with RC publishing? [y/N] " confirm
  [ "$confirm" = "y" ] || { info "Aborted."; exit 0; }
fi

# ─ Create RC Branch (as RaBbLE-dev) ──────────────────────────────────────────
echo ""
info "Creating RC branch..."

if git rev-parse --verify "$RC_BRANCH" >/dev/null 2>&1; then
  # Branch already exists
  info "Branch already exists: $RC_BRANCH"
  git checkout "$RC_BRANCH"
  ok "Switched to $RC_BRANCH"
else
  # Create new RC branch as RaBbLE-dev
  git -c user.name="$DEV_NAME" -c user.email="$DEV_EMAIL" \
    checkout -b "$RC_BRANCH"
  ok "Created branch: $RC_BRANCH"

  # Make initial commit as RaBbLE-dev
  git -c user.name="$DEV_NAME" -c user.email="$DEV_EMAIL" \
    commit --allow-empty \
    -m "spark ~ rabble-dev >> RC v$VERSION branch initialized // %RC_v${VERSION}_INIT%"
  ok "Initial commit created"
fi

# ─ Push Branch to Remote ─────────────────────────────────────────────────────
info "Pushing branch to remote..."
if ! git rev-parse --verify "origin/$RC_BRANCH" >/dev/null 2>&1; then
  git push -u origin "$RC_BRANCH"
  ok "Branch pushed to origin"
else
  info "Branch already on remote"
fi

# ─ Build the Project ────────────────────────────────────────────────────────
echo ""
if [ -f "package.json" ]; then
  info "Building project..."
  npm run build
  ok "Build complete"
else
  warn "No package.json found — skipping build"
fi

# ─ Tag as RaBbLE-dev ────────────────────────────────────────────────────────
echo ""
info "Tagging $RC_TAG..."

git -c user.name="$DEV_NAME" -c user.email="$DEV_EMAIL" \
  tag -a "$RC_TAG" \
  -m "spark ~ rabble-dev >> RC $RC_NUM ready for testing // %RC_${RC_TAG//[^A-Za-z0-9]/_}%"

ok "Tagged: $RC_TAG"

# ─ Push Tag to GitHub (triggers GitHub Actions) ──────────────────────────────
echo ""
info "Pushing tag to GitHub..."
git push origin "$RC_TAG"
ok "Tag pushed — GitHub Actions deploying to CDN..."

# ─ Summary ───────────────────────────────────────────────────────────────────
echo ""
header "✓ RC Published"

info "Branch:    $RC_BRANCH"
info "Tag:       $RC_TAG"
info "Author:    $DEV_NAME"
echo ""
warn "Monitor deployment:"
info "  GitHub: https://github.com/markm1206/RaBbLE-Aether/actions"
info "  CDN:    https://aether.joinrabble.world/$RC_TAG/"
echo ""
