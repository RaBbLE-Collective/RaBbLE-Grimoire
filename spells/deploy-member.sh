#!/usr/bin/env bash
# =============================================================================
# spells/deploy-member.sh — Complete Member Deployment Pipeline (CLI-Only)
#
# Orchestrates full RC deployment for any RaBbLE member (Aether, NeBuLA, World).
# Zero dashboard interaction. Single command deploys to CDN.
#
# Handles:
# 1. Cloudflare R2 bucket setup (create if needed)
# 2. GitHub Actions secrets configuration
# 3. RC branch creation (as RaBbLE-dev)
# 4. RC tagging and GitHub Actions trigger
# 5. Monitors deployment progress
#
# Usage (Example: Aether):
#   bash spells/deploy-member.sh aether v0.0.0.1              # Full deployment
#   bash spells/deploy-member.sh aether v0.0.0.1 --dry-run    # Preview
#
# Supported members:
#   aether     RaBbLE-Aether (visual design system)
#   nebula     RaBbLE-NeBuLA (rendering engine)
#   world      RaBbLE-World (entry point)
#   score      RaBbLE-sCoRE (coordination engine)
#
# Prerequisites:
#   - wrangler: npm install -g wrangler
#   - Cloudflare credentials: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID
#   - GitHub CLI: gh (optional, for automated secret setup)
#   - curl: for API calls
#
# Environment Variables:
#   CLOUDFLARE_API_TOKEN     Cloudflare API token (v1.0...)
#   CLOUDFLARE_ACCOUNT_ID    Cloudflare account ID
#   GITHUB_TOKEN              GitHub token (for gh CLI secrets)
#   DRY_RUN                   Set to "true" to preview without changes
#
# spark ~ member >> full RC deployment pipeline, no dashboard // %MEMBER_DEPLOY%
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

# ─ Paths ─────────────────────────────────────────────────────────────────────
SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
COLLECTIVE_ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"

# ─ Parse Arguments ───────────────────────────────────────────────────────────
MEMBER="${1:-}"
VERSION="${2:-}"
DRY_RUN="${DRY_RUN:-false}"

if [ "${3:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

if [ -z "$MEMBER" ] || [ -z "$VERSION" ]; then
  cat <<'USAGE'
Usage: bash spells/deploy-member.sh <member> <version> [--dry-run]

Members:
  aether       RaBbLE-Aether (visual design system)
  nebula       RaBbLE-NeBuLA (rendering engine)
  world        RaBbLE-World (entry point)
  score        RaBbLE-sCoRE (coordination engine)

Examples:
  bash spells/deploy-member.sh aether v0.0.0.1           # Deploy RC
  bash spells/deploy-member.sh nebula v0.0.0.1 --dry-run # Preview

Environment Variables (required for non-interactive):
  CLOUDFLARE_API_TOKEN     Cloudflare API token
  CLOUDFLARE_ACCOUNT_ID    Cloudflare account ID

USAGE
  exit 0
fi

# Normalize member name and determine repo path
MEMBER=$(echo "$MEMBER" | tr '[:upper:]' '[:lower:]')
MEMBER_REPO="RaBbLE-$(echo "$MEMBER" | sed 's/^./\U&/')"  # aether → RaBbLE-Aether
MEMBER_ROOT="$COLLECTIVE_ROOT/$MEMBER_REPO"
VERSION="${VERSION#v}"

# ─ Validation ────────────────────────────────────────────────────────────────
header "╔══════════════════════════════════════════════════════════╗"
header "║  Member Deployment Pipeline — $MEMBER                     ║"
header "║  Version: v$VERSION                                          ║"
header "╚══════════════════════════════════════════════════════════╝"

[ "$DRY_RUN" = "true" ] && warn "DRY RUN — no changes will be made"

if [ ! -d "$MEMBER_ROOT" ]; then
  err "Member repo not found: $MEMBER_ROOT"
  exit 1
fi

ok "Member repo: $MEMBER_REPO"

# ─ Step 1: R2 Setup ──────────────────────────────────────────────────────────
echo ""
header "Step 1: Cloudflare R2 Setup"

if [ "$DRY_RUN" = "true" ]; then
  warn "Would run: setup-cloudflare-r2.sh --non-interactive --verify-only"
else
  # Ensure R2 is set up
  export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
  export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-}"

  if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    warn "Missing Cloudflare credentials"
    info "Set environment variables:"
    info "  export CLOUDFLARE_API_TOKEN='v1.0...'"
    info "  export CLOUDFLARE_ACCOUNT_ID='abc123...'"
    exit 1
  fi

  # Run R2 setup in non-interactive mode
  bash "$SPELL_DIR/setup-cloudflare-r2.sh" --non-interactive --verify-only || {
    warn "R2 setup incomplete. Running full setup..."
    bash "$SPELL_DIR/setup-cloudflare-r2.sh" --non-interactive
  }

  ok "R2 configured"
fi

# ─ Step 2: GitHub Actions Workflow ──────────────────────────────────────────
echo ""
header "Step 2: GitHub Actions Workflow"

WORKFLOW_FILE="$MEMBER_ROOT/.github/workflows/deploy.yml"

if [ "$DRY_RUN" = "true" ]; then
  warn "Would check workflow: $WORKFLOW_FILE"
else
  if [ ! -f "$WORKFLOW_FILE" ]; then
    warn "GitHub Actions workflow missing: $WORKFLOW_FILE"
    info "Run: bash spells/create-member-workflow.sh $MEMBER"
    exit 1
  fi
  ok "Workflow exists: deploy.yml"
fi

# ─ Step 3: GitHub Actions Secrets ────────────────────────────────────────────
echo ""
header "Step 3: GitHub Actions Secrets"

if [ "$DRY_RUN" = "true" ]; then
  warn "Would configure GitHub secrets for: $MEMBER_REPO"
else
  if command -v gh &>/dev/null; then
    # Determine GitHub org/repo
    GITHUB_USER="${GITHUB_USER:-markm1206}"
    GH_REPO="$GITHUB_USER/$MEMBER_REPO"

    # Set secrets via gh CLI
    for secret in CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_ZONE_ID; do
      SECRET_VALUE="${!secret:-}"
      if [ -n "$SECRET_VALUE" ]; then
        if gh secret set "$secret" -R "$GH_REPO" <<< "$SECRET_VALUE" 2>/dev/null; then
          ok "Secret configured: $secret"
        else
          info "Secret already exists: $secret"
        fi
      fi
    done
  else
    warn "gh CLI not installed — skipping GitHub secret setup"
    warn "Set these manually at: https://github.com/$MEMBER_REPO/settings/secrets/actions"
    echo "    - CLOUDFLARE_API_TOKEN"
    echo "    - CLOUDFLARE_ACCOUNT_ID"
    echo "    - CLOUDFLARE_ZONE_ID"
  fi
fi

# ─ Step 4: RC Deployment ─────────────────────────────────────────────────────
echo ""
header "Step 4: Publish RC"

if [ "$DRY_RUN" = "true" ]; then
  warn "Would publish RC for $MEMBER_REPO v$VERSION"
  warn "Command: bash spells/publish-rc.sh v$VERSION"
else
  cd "$MEMBER_ROOT"

  # Run publish-rc.sh
  if bash "$SPELL_DIR/publish-rc.sh" "v$VERSION"; then
    ok "RC published"
  else
    err "RC publication failed"
    exit 1
  fi
fi

# ─ Step 5: Monitor Deployment ────────────────────────────────────────────────
echo ""
header "Step 5: Monitor Deployment"

RC_TAG="v${VERSION}-rc.1"
REPO_URL="https://github.com/${GITHUB_USER:-markm1206}/$MEMBER_REPO"
ACTIONS_URL="$REPO_URL/actions"
CDN_URL="https://cdn.joinrabble.world/$MEMBER/v$RC_TAG/"

if [ "$DRY_RUN" = "true" ]; then
  warn "Deployment monitoring URLs:"
else
  info "Deployment monitoring URLs:"
fi

echo ""
info "GitHub Actions:"
info "  $ACTIONS_URL"
echo ""
info "CDN:"
info "  $CDN_URL"
echo ""

if [ "$DRY_RUN" = "false" ]; then
  info "Waiting for GitHub Actions to complete..."
  info "  (This may take 1-2 minutes)"

  # Try to monitor via GitHub API or just wait
  sleep 10

  # Attempt to check CDN (will fail initially, that's ok)
  if curl -s -o /dev/null -w "%{http_code}" "$CDN_URL" | grep -q "200"; then
    ok "CDN ready!"
  else
    warn "CDN not yet ready — check GitHub Actions status"
  fi
fi

# ─ Summary ───────────────────────────────────────────────────────────────────
echo ""
header "✓ Deployment Complete"

if [ "$DRY_RUN" = "true" ]; then
  info "Dry run complete — no changes made"
else
  info "Member:   $MEMBER_REPO"
  info "Version:  v$VERSION"
  info "RC Tag:   $RC_TAG"
  echo ""
  info "Next steps:"
  info "  1. Test at: $CDN_URL"
  info "  2. Monitor: $ACTIONS_URL"
  info "  3. If fixes needed: commit to rc/v$VERSION and run this again"
  info "  4. When ready: merge rc/v$VERSION → main"
fi

echo ""
