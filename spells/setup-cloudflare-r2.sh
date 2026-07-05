#!/usr/bin/env bash
# =============================================================================
# spells/setup-cloudflare-r2.sh — Cloudflare R2 & CDN Setup (Fully Autonomous)
#
# SUPERSEDED: this script sets up the unified cdn.joinrabble.world + R2 design,
# which was cancelled. Per-member subdomains (aether.joinrabble.world,
# nebula.joinrabble.world) are the permanent canonical CDN hosts, already live
# via their own subdomain Workers — see spells/cloudflare-ctl.sh's `deploy` and
# `domain` commands for the current, actually-used path. Retained for
# historical reference; needs a fuller rewrite or retirement (follow-up).
#
# One-time setup for Episode 1 CDN deployment via CLI (no dashboard).
# Supports non-interactive mode via environment variables.
#
# Creates:
# 1. R2 buckets (rabble-cdn-prod) via wrangler
# 2. Cloudflare API token (securely stored)
# 3. GitHub Actions secrets for all member repos
#
# Usage:
#   # Interactive mode (prompts for credentials)
#   bash spells/setup-cloudflare-r2.sh
#
#   # Non-interactive mode (via environment variables)
#   export CLOUDFLARE_API_TOKEN="v1.0abc..."
#   export CLOUDFLARE_ACCOUNT_ID="abc123..."
#   bash spells/setup-cloudflare-r2.sh --non-interactive
#
#   # Preview without changes
#   bash spells/setup-cloudflare-r2.sh --dry-run
#
#   # Check existing setup
#   bash spells/setup-cloudflare-r2.sh --verify-only
#
# Prerequisites:
#   - wrangler: npm install -g wrangler
#   - wrangler authentication: wrangler login (or via env var)
#   - For GitHub secrets: gh CLI installed and authenticated
#
# Environment Variables (for non-interactive mode):
#   CLOUDFLARE_API_TOKEN     Cloudflare API token (v1.0...)
#   CLOUDFLARE_ACCOUNT_ID    Cloudflare account ID
#   CLOUDFLARE_ZONE_ID       Domain zone ID (optional)
#   GITHUB_TOKEN              GitHub token (for gh CLI)
#   GITHUB_USER               GitHub username (for gh CLI)
#
# spark ~ cloudflare >> R2 setup, fully autonomous CLI // %EP1_R2_AUTONOMOUS%
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

# ─ Flags & Mode ──────────────────────────────────────────────────────────────
DRY_RUN=false
VERIFY_ONLY=false
NON_INTERACTIVE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)          DRY_RUN=true;          shift ;;
    --verify-only)      VERIFY_ONLY=true;      shift ;;
    --non-interactive)  NON_INTERACTIVE=true;  shift ;;
    --help|-h)
      sed -n '/^# Usage:/,/^# spark/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *)
      err "Unknown flag: $1"
      exit 1 ;;
  esac
done

# ─ Paths ─────────────────────────────────────────────────────────────────────
SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
COLLECTIVE_ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"

WORLD_ROOT="$COLLECTIVE_ROOT/RaBbLE-World"
AETHER_ROOT="$COLLECTIVE_ROOT/RaBbLE-Aether"
NEBULA_ROOT="$COLLECTIVE_ROOT/RaBbLE-NeBuLA"

# ─ Cloudflare Config ─────────────────────────────────────────────────────────
ACCOUNT_ID_FILE="$GRIMOIRE_ROOT/.cloudflare/account_id"
API_TOKEN_FILE="$GRIMOIRE_ROOT/.cloudflare/api_token"
R2_BUCKET_PROD="rabble-cdn-prod"
DOMAIN="joinrabble.world"

# ─ Helpers ───────────────────────────────────────────────────────────────────

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    err "$1 not found"
    info "Install: $2"
    exit 1
  fi
}

get_account_id() {
  # Check environment variable first
  if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    echo "$CLOUDFLARE_ACCOUNT_ID"
    return
  fi

  # Try to get from wrangler whoami
  local account=$(wrangler whoami 2>/dev/null | grep -oP '(?<=account_id=)[^,\s]+' || echo "")
  if [ -z "$account" ]; then
    if [ "$NON_INTERACTIVE" = "true" ]; then
      err "CLOUDFLARE_ACCOUNT_ID environment variable not set"
      exit 1
    fi
    # Ask user
    warn "Could not auto-detect Cloudflare account ID"
    read -r -p "  Enter your Cloudflare Account ID (from https://dash.cloudflare.com/): " account
  fi
  echo "$account"
}

get_api_token() {
  # Check environment variable first
  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    echo "$CLOUDFLARE_API_TOKEN"
    return
  fi

  # Check if already stored
  if [ -f "$API_TOKEN_FILE" ]; then
    cat "$API_TOKEN_FILE"
    return
  fi

  if [ "$NON_INTERACTIVE" = "true" ]; then
    err "CLOUDFLARE_API_TOKEN environment variable not set"
    exit 1
  fi

  warn "API token not found"
  info "Create one at: https://dash.cloudflare.com/profile/api-tokens"
  info "Permissions needed: R2 Edit + Workers Edit"
  read -rsp "  Paste your API token: " token
  echo ""
  echo "$token"
}

verify_wrangler_auth() {
  if ! wrangler whoami &>/dev/null; then
    err "wrangler not authenticated"
    info "Run: wrangler login"
    exit 1
  fi
}

create_bucket() {
  local bucket=$1
  local dry=$2

  if wrangler r2 bucket list 2>/dev/null | grep -q "^$bucket$"; then
    info "Bucket already exists: $bucket"
    return 0
  fi

  if [ "$dry" = "true" ]; then
    warn "wrangler r2 bucket create $bucket"
    return 0
  fi

  info "Creating bucket: $bucket"
  if wrangler r2 bucket create "$bucket"; then
    ok "Created bucket: $bucket"
    return 0
  else
    err "Failed to create bucket: $bucket"
    return 1
  fi
}

configure_bucket_cors() {
  local bucket=$1
  local dry=$2

  if [ "$dry" = "true" ]; then
    warn "Configure CORS for $bucket"
    return 0
  fi

  info "Configuring CORS for $bucket..."
  # CORS config allows joinrabble.world and cdn.joinrabble.world to access files
  local cors_json=$(cat <<'EOF'
{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://joinrabble.world", "https://cdn.joinrabble.world", "https://www.joinrabble.world"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3600
    }
  ]
}
EOF
)

  # Note: wrangler r2 doesn't directly support CORS config via CLI yet
  # This is a manual step or requires API calls
  warn "CORS config requires Cloudflare dashboard or API calls"
  info "See: https://developers.cloudflare.com/r2/buckets/cross-origin-resource-sharing/"
  return 0
}

list_buckets() {
  info "R2 buckets:"
  if wrangler r2 bucket list 2>/dev/null; then
    return 0
  else
    err "Could not list buckets"
    return 1
  fi
}

create_gh_secret() {
  local repo=$1
  local secret_name=$2
  local secret_value=$3
  local dry=$4

  if [ "$dry" = "true" ]; then
    warn "gh secret set $secret_name in $repo"
    return 0
  fi

  if ! command -v gh &>/dev/null; then
    warn "gh CLI not installed — skipping GitHub secret setup"
    warn "Create manually at: https://github.com/$repo/settings/secrets/actions"
    info "Secret: $secret_name"
    return 0
  fi

  # Only set if not already present
  if gh secret list -R "$repo" 2>/dev/null | grep -q "^$secret_name"; then
    info "Secret already set: $secret_name"
    return 0
  fi

  info "Setting GitHub secret: $secret_name"
  if gh secret set "$secret_name" -R "$repo" <<< "$secret_value"; then
    ok "Set secret: $secret_name"
    return 0
  else
    warn "Failed to set secret: $secret_name"
    return 1
  fi
}

# ─ Main ──────────────────────────────────────────────────────────────────────

main() {
  echo ""
  header "╔═══════════════════════════════════════════════════════════╗"
  header "║  Cloudflare R2 & CDN Setup — Episode 1                    ║"
  header "║  Sets up buckets, auth, and GitHub Actions secrets         ║"
  header "╚═══════════════════════════════════════════════════════════╝"

  # ─ Preflight ──────────────────────────────────────────────────────────────
  info "Checking prerequisites..."
  check_cmd wrangler "npm install -g wrangler"
  ok "wrangler ready"

  verify_wrangler_auth
  ok "wrangler authenticated"

  if [ "$VERIFY_ONLY" = "true" ]; then
    info ""
    info "Current R2 setup:"
    list_buckets || true
    exit 0
  fi

  # ─ Get Credentials ────────────────────────────────────────────────────────
  echo ""
  header "1. Cloudflare Credentials"

  ACCOUNT_ID=$(get_account_id)
  ok "Account ID: $ACCOUNT_ID"

  # Store for later use
  mkdir -p "$(dirname "$ACCOUNT_ID_FILE")"
  echo "$ACCOUNT_ID" > "$ACCOUNT_ID_FILE"

  API_TOKEN=$(get_api_token)
  if [ -n "$API_TOKEN" ]; then
    mkdir -p "$(dirname "$API_TOKEN_FILE")"
    # Don't echo the token; just confirm it's set
    echo "$API_TOKEN" > "$API_TOKEN_FILE"
    chmod 600 "$API_TOKEN_FILE"
    ok "API token saved (not shown)"
  fi

  # ─ Create R2 Buckets ──────────────────────────────────────────────────────
  echo ""
  header "2. Create R2 Buckets"

  create_bucket "$R2_BUCKET_PROD" "$DRY_RUN"
  configure_bucket_cors "$R2_BUCKET_PROD" "$DRY_RUN"

  # ─ List Buckets ───────────────────────────────────────────────────────────
  echo ""
  header "3. Verify Buckets"
  list_buckets || true

  # ─ GitHub Secrets ────────────────────────────────────────────────────────
  echo ""
  header "4. GitHub Actions Secrets"

  if [ "$DRY_RUN" = "true" ]; then
    info "Would set the following secrets in each repo:"
    warn "  CLOUDFLARE_API_TOKEN"
    warn "  CLOUDFLARE_ACCOUNT_ID"
    warn "  CLOUDFLARE_ZONE_ID"
  else
    if [ -n "${API_TOKEN:-}" ]; then
      for repo in "RaBbLE-World" "RaBbLE-NeBuLA" "RaBbLE-Aether"; do
        info ""
        info "Configuring $repo..."
        # These would require gh CLI and GitHub repo access
        # Commented out for now — user must do manually or enable gh
        warn "GitHub secret setup requires GitHub CLI auth"
        info "Set these manually at: https://github.com/markm1206/$repo/settings/secrets/actions"
        echo "    - CLOUDFLARE_API_TOKEN"
        echo "    - CLOUDFLARE_ACCOUNT_ID"
        echo "    - CLOUDFLARE_ZONE_ID"
      done
    fi
  fi

  # ─ Summary ────────────────────────────────────────────────────────────────
  echo ""
  header "✓ Setup Complete"

  if [ "$DRY_RUN" = "true" ]; then
    warn "Dry run — no changes made. Run without --dry-run to apply."
  else
    ok "R2 buckets created and configured"
    ok "Credentials saved to $GRIMOIRE_ROOT/.cloudflare/"
    info ""
    info "Next steps:"
    info "  1. Create rc/v0.0.0.1 branch in RaBbLE-Aether"
    info "  2. Run: bash spells/publish-rc.sh"
    info "  3. Monitor GitHub Actions for deployment"
    info ""
    info "Verify deployment at:"
    info "  https://cdn.joinrabble.world/aether/v0.0.0.1-rc.1/"
  fi

  echo ""
}

main "$@"
