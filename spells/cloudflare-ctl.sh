#!/usr/bin/env bash
# =============================================================================
# spells/cloudflare-ctl.sh — Unified Cloudflare Control (R2, Workers, CDN)
#
# Master controller for all Cloudflare operations: R2 setup, deployment,
# monitoring. Single entry point for all cloud infrastructure.
#
# Usage:
#   bash spells/cloudflare-ctl.sh <command> [options]
#
# Commands:
#   auth                       # Verify/configure Cloudflare authentication
#   r2-setup                   # Create R2 buckets (rabble-cdn-prod)
#   r2-list                    # List R2 buckets
#   r2-verify                  # Verify R2 bucket configuration
#   r2-domain [add|verify|remove]  # Connect cdn.joinrabble.world → bucket (public CDN)
#   secrets-setup <member>     # Configure GitHub Actions secrets
#   secrets-show               # Display configured secrets (masked)
#   status                     # Overall deployment status
#   monitor <member> [ver]     # Monitor CDN deployment for member
#   open                       # Open Cloudflare dashboard
#   help                       # Show this help
#
# Examples:
#   bash spells/cloudflare-ctl.sh r2-setup --dry-run
#   bash spells/cloudflare-ctl.sh r2-domain add        # attach cdn.joinrabble.world
#   bash spells/cloudflare-ctl.sh r2-domain verify     # poll until the TLS cert is active
#   bash spells/cloudflare-ctl.sh secrets-setup aether
#   bash spells/cloudflare-ctl.sh monitor aether v0.0.0.1-rc.1
#   bash spells/cloudflare-ctl.sh status
#
# Environment Variables:
#   CLOUDFLARE_API_TOKEN     API token (needs R2 edit + DNS edit + SSL for r2-domain)
#   CLOUDFLARE_ACCOUNT_ID    Account ID
#   CLOUDFLARE_ZONE_ID       Zone ID for joinrabble.world (required for r2-domain)
#   GITHUB_ORG               Repo owner for secrets/monitor (default: RaBbLE-Collective)
#   CDN_DOMAIN               Custom domain to attach (default: cdn.joinrabble.world)
#   CDN_BUCKET               R2 bucket to serve (default: rabble-cdn-prod)
#
# spark ~ cloudflare >> unified infrastructure control // %CLOUDFLARE_CTL%
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
CF_CONFIG_DIR="$GRIMOIRE_ROOT/.cloudflare"

# ─ Defaults (overridable via env) ─────────────────────────────────────────────
GITHUB_ORG="${GITHUB_ORG:-RaBbLE-Collective}"   # repos now live under the org
CDN_DOMAIN="${CDN_DOMAIN:-cdn.joinrabble.world}"
CDN_BUCKET="${CDN_BUCKET:-rabble-cdn-prod}"

# ─ Commands ──────────────────────────────────────────────────────────────────

cmd_auth() {
  header "Cloudflare Authentication"

  # Check wrangler auth
  if wrangler whoami &>/dev/null; then
    ok "wrangler authenticated"
    wrangler whoami
  else
    warn "wrangler not authenticated"
    info "Run: wrangler login"
    exit 1
  fi

  # Check API token
  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    ok "CLOUDFLARE_API_TOKEN set (not shown)"
  elif [ -f "$CF_CONFIG_DIR/api_token" ]; then
    ok "API token stored at $CF_CONFIG_DIR/api_token"
  else
    warn "CLOUDFLARE_API_TOKEN not configured"
    info "Set via environment variable or store in $CF_CONFIG_DIR/api_token"
  fi

  # Check account ID
  if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    ok "CLOUDFLARE_ACCOUNT_ID set: ${CLOUDFLARE_ACCOUNT_ID:0:10}..."
  elif [ -f "$CF_CONFIG_DIR/account_id" ]; then
    ACCOUNT_ID=$(cat "$CF_CONFIG_DIR/account_id")
    ok "Account ID stored: ${ACCOUNT_ID:0:10}..."
  else
    warn "CLOUDFLARE_ACCOUNT_ID not configured"
  fi

  echo ""
}

cmd_r2_setup() {
  local dry_run="${1:-false}"

  header "R2 Bucket Setup"
  [ "$dry_run" = "--dry-run" ] && warn "DRY RUN — no buckets will be created"

  # Verify wrangler
  if ! command -v wrangler &>/dev/null; then
    err "wrangler not found — install: npm install -g wrangler"
    exit 1
  fi

  # Verify auth
  if ! wrangler whoami &>/dev/null; then
    err "wrangler not authenticated — run: wrangler login"
    exit 1
  fi

  info "Creating R2 buckets..."

  for bucket in rabble-cdn-prod; do
    if wrangler r2 bucket list 2>/dev/null | grep -q "^$bucket$"; then
      ok "Bucket exists: $bucket"
    else
      if [ "$dry_run" = "--dry-run" ]; then
        warn "Would create: $bucket"
      else
        if wrangler r2 bucket create "$bucket"; then
          ok "Created bucket: $bucket"
        else
          err "Failed to create bucket: $bucket"
          exit 1
        fi
      fi
    fi
  done

  echo ""
}

cmd_r2_list() {
  header "R2 Buckets"

  if wrangler r2 bucket list 2>/dev/null; then
    echo ""
  else
    err "Could not list buckets"
    exit 1
  fi
}

cmd_r2_verify() {
  header "R2 Configuration Verification"

  if ! wrangler whoami &>/dev/null; then
    err "wrangler not authenticated"
    exit 1
  fi

  info "Checking R2 setup..."

  # List buckets
  BUCKETS=$(wrangler r2 bucket list 2>/dev/null | wc -l)
  ok "R2 buckets: $BUCKETS"

  # Check for rabble-cdn-prod
  if wrangler r2 bucket list 2>/dev/null | grep -q "rabble-cdn-prod"; then
    ok "rabble-cdn-prod bucket ready"
  else
    warn "rabble-cdn-prod bucket not found"
  fi

  echo ""
}

# Connect/verify/remove the public custom domain on the R2 bucket. This is what
# makes https://cdn.joinrabble.world/... resolve — without it, a green deploy
# still has nowhere to land. Attaching auto-creates a proxied CNAME in the zone
# and provisions an edge TLS cert (~1–few min to go active).
cmd_r2_domain() {
  local action="${1:-verify}"

  header "R2 Custom Domain — $CDN_DOMAIN → $CDN_BUCKET"

  if ! command -v wrangler &>/dev/null; then
    err "wrangler not found — install: npm install -g wrangler"
    exit 1
  fi
  if ! wrangler whoami &>/dev/null; then
    err "wrangler not authenticated — run: wrangler login"
    exit 1
  fi

  case "$action" in
    add|connect)
      if [ -z "${CLOUDFLARE_ZONE_ID:-}" ]; then
        err "CLOUDFLARE_ZONE_ID required to bind the domain to the zone"
        exit 1
      fi
      info "Attaching $CDN_DOMAIN (creates proxied CNAME + TLS cert)..."
      if wrangler r2 bucket domain add "$CDN_BUCKET" \
           --domain "$CDN_DOMAIN" \
           --zone-id "$CLOUDFLARE_ZONE_ID" \
           --min-tls 1.2; then
        ok "Attach requested — cert provisioning in progress"
        info "Poll with: bash spells/cloudflare-ctl.sh r2-domain verify"
      else
        err "Attach failed — token likely lacks DNS edit + SSL + R2 edit on the zone"
        exit 1
      fi
      ;;
    verify|status|list)
      info "Custom domains on $CDN_BUCKET:"
      if ! wrangler r2 bucket domain list "$CDN_BUCKET"; then
        err "Could not list custom domains (bucket missing or auth scope?)"
        exit 1
      fi
      info "If $CDN_DOMAIN shows status 'active', HTTPS is live."
      ;;
    remove|disconnect)
      warn "Detaching $CDN_DOMAIN from $CDN_BUCKET..."
      wrangler r2 bucket domain remove "$CDN_BUCKET" --domain "$CDN_DOMAIN"
      ok "Detached"
      ;;
    *)
      warn "Usage: cloudflare-ctl.sh r2-domain [add|verify|remove]"
      ;;
  esac

  echo ""
}

cmd_secrets_setup() {
  local member="${1:-}"

  header "GitHub Actions Secrets"

  if [ -z "$member" ]; then
    warn "Usage: cloudflare-ctl.sh secrets-setup <member>"
    info "Example: cloudflare-ctl.sh secrets-setup aether"
    exit 1
  fi

  if ! command -v gh &>/dev/null; then
    warn "gh CLI not installed"
    info "Install: https://cli.github.com"
    exit 1
  fi

  MEMBER_REPO="RaBbLE-$(echo "$member" | sed 's/^./\U&/')"
  GH_REPO="$GITHUB_ORG/$MEMBER_REPO"

  info "Setting secrets for $GH_REPO..."

  for secret in CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_ZONE_ID; do
    SECRET_VALUE="${!secret:-}"
    if [ -n "$SECRET_VALUE" ]; then
      if gh secret set "$secret" -R "$GH_REPO" <<< "$SECRET_VALUE" 2>/dev/null; then
        ok "Secret set: $secret"
      else
        info "Secret exists: $secret"
      fi
    else
      warn "Skipping $secret (not set)"
    fi
  done

  echo ""
}

cmd_secrets_show() {
  header "Configured Secrets"

  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    TOKEN_MASKED="${CLOUDFLARE_API_TOKEN:0:10}...${CLOUDFLARE_API_TOKEN: -5}"
    ok "CLOUDFLARE_API_TOKEN: $TOKEN_MASKED"
  else
    warn "CLOUDFLARE_API_TOKEN not set"
  fi

  if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    ok "CLOUDFLARE_ACCOUNT_ID: $CLOUDFLARE_ACCOUNT_ID"
  else
    warn "CLOUDFLARE_ACCOUNT_ID not set"
  fi

  if [ -n "${CLOUDFLARE_ZONE_ID:-}" ]; then
    ok "CLOUDFLARE_ZONE_ID: $CLOUDFLARE_ZONE_ID"
  else
    warn "CLOUDFLARE_ZONE_ID not set"
  fi

  echo ""
}

cmd_status() {
  header "Cloudflare Deployment Status"

  cmd_auth || true
  echo ""
  cmd_r2_verify || true
  echo ""
  cmd_r2_domain verify || true
  echo ""

  info "Members deployed:"
  for member in aether nebula world; do
    CDN_URL="https://cdn.joinrabble.world/$member/v0.0.0.1-rc.1/"
    if curl -s -o /dev/null -w "%{http_code}" "$CDN_URL" | grep -q "200"; then
      ok "$member available at CDN"
    else
      warn "$member not yet on CDN (in progress or not deployed)"
    fi
  done

  echo ""
}

cmd_monitor() {
  local member="${1:-}"
  local version="${2:-v0.0.0.1-rc.1}"

  if [ -z "$member" ]; then
    warn "Usage: cloudflare-ctl.sh monitor <member> [version]"
    exit 1
  fi

  header "Monitoring: $member/$version"

  CDN_URL="https://cdn.joinrabble.world/$member/$version/"

  info "Polling CDN..."
  for i in {1..30}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$CDN_URL" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
      ok "✓ Available at CDN (attempt $i)"
      info "$CDN_URL"
      echo ""
      return 0
    else
      warn "Status: $HTTP_CODE (attempt $i/30)"
      sleep 2
    fi
  done

  warn "CDN not ready after 60 seconds"
  info "Check GitHub Actions: https://github.com/$GITHUB_ORG/RaBbLE-$member/actions"
  echo ""
}

cmd_open() {
  info "Opening Cloudflare Dashboard..."
  if command -v xdg-open &>/dev/null; then
    xdg-open "https://dash.cloudflare.com"
  elif command -v open &>/dev/null; then
    open "https://dash.cloudflare.com"
  else
    info "https://dash.cloudflare.com"
  fi
  echo ""
}

cmd_help() {
  sed -n '/^# Usage:/,/^# spark/p' "$0" | sed 's/^# \?//'
}

# ─ Main ──────────────────────────────────────────────────────────────────────

COMMAND="${1:-help}"

case "$COMMAND" in
  auth)          cmd_auth ;;
  r2-setup)      cmd_r2_setup "${2:-}" ;;
  r2-list)       cmd_r2_list ;;
  r2-verify)     cmd_r2_verify ;;
  r2-domain)     cmd_r2_domain "${2:-}" ;;
  secrets-setup) cmd_secrets_setup "${2:-}" ;;
  secrets-show)  cmd_secrets_show ;;
  status)        cmd_status ;;
  monitor)       cmd_monitor "${2:-}" "${3:-}" ;;
  open)          cmd_open ;;
  help|--help|-h)
    cmd_help ;;
  *)
    err "Unknown command: $COMMAND"
    echo "  Run: bash spells/cloudflare-ctl.sh help"
    exit 1
    ;;
esac
