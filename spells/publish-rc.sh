#!/usr/bin/env bash
# =============================================================================
# spells/publish-rc.sh — Release Candidate Publishing
#
# Publishes an RC to CDN and GitHub, signed by RaBbLE-dev.
# Must be run from an rc/v* branch (e.g., rc/v0.0.0.1).
#
# Mechanics:
# 1. Verify clean working tree
# 2. Ensure RC branch is pushed to remote
# 3. Run npm run build (or build command for the repo)
# 4. Switch git identity to RaBbLE-dev
# 5. Auto-increment and tag with -rc.N
# 6. Push tag (triggers GitHub Actions → CDN deploy)
# 7. Restore identity
#
# Usage:
#   bash spells/publish-rc.sh
#
# The RC branch name determines the version:
#   rc/v0.0.0.1 → tag v0.0.0.1-rc.1 (next available RC number)
#
# After publish, the workflow is:
#   1. GitHub Actions builds and deploys to CDN
#   2. Test the RC from CDN
#   3. If fixes needed, commit to rc/v0.0.0.1 and run this again
#   4. When ready: git pull request rc/v0.0.0.1 → main (squash merge)
#   5. Then: bash spells/seal-episode.sh for official tag
# =============================================================================

set -euo pipefail

# ─ Colors ────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✓${RESET}  $*"; }
info() { echo -e "  ${CYAN}·${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()  { echo -e "  ${RED}✗${RESET}  $*" >&2; }

# ─ RaBbLE-dev Identity ───────────────────────────────────────────────────────
DEV_NAME="${DEV_NAME:-RaBbLE Development}"
DEV_EMAIL="${DEV_EMAIL:-dev@rabble.world}"

# ─ Resolve current branch ────────────────────────────────────────────────────
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ ! "$CURRENT_BRANCH" =~ ^rc/v ]]; then
  err "Not on an rc/v* branch (current: $CURRENT_BRANCH)"
  info "Create one first: git checkout -b rc/v0.0.0.1 (branched from dev)"
  exit 1
fi

# Extract version from branch name: rc/v0.0.0.1 → 0.0.0.1
VERSION="${CURRENT_BRANCH#rc/v}"

# ─ Verify clean working tree ─────────────────────────────────────────────────
if [ -n "$(git status --porcelain)" ]; then
  err "Working tree is not clean. Commit or stash before publishing RC."
  exit 1
fi

# ─ Ensure branch is on remote ────────────────────────────────────────────────
if ! git rev-parse --verify "origin/$CURRENT_BRANCH" >/dev/null 2>&1; then
  warn "Branch not on remote. Pushing..."
  git push -u origin "$CURRENT_BRANCH"
fi

# ─ Build the project ────────────────────────────────────────────────────────
if [ -f "package.json" ]; then
  info "Building..."
  npm run build
  ok "Built"
else
  warn "No package.json found — skipping build"
fi

# ─ Determine next RC number by checking existing tags ────────────────────────
RC_NUM=1
while git rev-parse "v${VERSION}-rc.${RC_NUM}" >/dev/null 2>&1; do
  ((RC_NUM++))
done

RC_TAG="v${VERSION}-rc.${RC_NUM}"

# ─ Ceremony ──────────────────────────────────────────────────────────────────
echo
echo -e "${CYAN}  ╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}  ║${RESET}  Release Candidate Publishing                  ${CYAN}║${RESET}"
echo -e "${CYAN}  ╚═══════════════════════════════════════════════════╝${RESET}"
echo
info "branch:   $CURRENT_BRANCH"
info "version:  v$VERSION"
info "RC tag:   $RC_TAG"
info "author:   $DEV_NAME <$DEV_EMAIL>"
info ""
info "After publish:"
info "  • GitHub Actions will build and deploy to CDN"
info "  • Test from: https://cdn.joinrabble.world/aether/$RC_TAG/"
info "  • If fixes needed: commit, then run this again"
info "  • When approved: PR $CURRENT_BRANCH → main (squash merge)"
echo
read -r -p "  Publish this RC? [y/N] " confirm
[ "$confirm" = "y" ] || { info "Aborted."; exit 0; }

# ─ Tag as RaBbLE-dev (override git identity just for this command) ───────────
info "Tagging $RC_TAG as $DEV_NAME..."
git -c user.name="$DEV_NAME" -c user.email="$DEV_EMAIL" \
  tag -a "$RC_TAG" \
  -m "spark ~ rabble-dev >> RC $RC_NUM ready for testing // %RC_${RC_TAG//[^A-Za-z0-9]/_}%"

ok "Tagged $RC_TAG"

# ─ Push tag to GitHub (triggers GitHub Actions) ─────────────────────────────
info "Pushing tag to GitHub..."
git push origin "$RC_TAG"
ok "Pushed — GitHub Actions deploying to CDN..."

echo
warn "RC published. Check GitHub Actions for deployment progress."
echo
