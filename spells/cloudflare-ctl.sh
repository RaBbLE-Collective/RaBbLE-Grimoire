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
#   setup                      # Install wrangler + guided credential collection (start here)
#   auth                       # Verify/configure Cloudflare authentication
#   r2-setup                   # Create R2 buckets (rabble-cdn-prod)
#   r2-list                    # List R2 buckets
#   r2-verify                  # Verify R2 bucket configuration
#   r2-domain [add|verify|remove]  # Connect cdn.joinrabble.world → bucket (public CDN)
#   deploy-rc <version>        # Build Aether + upload to R2 at versioned CDN path
#   secrets-setup <member>     # Configure GitHub Actions secrets
#   secrets-show               # Display configured secrets (masked)
#   status                     # Overall deployment status
#   monitor <member> [ver]     # Monitor CDN deployment for member
#   open                       # Open Cloudflare dashboard
#   help                       # Show this help
#
# Examples:
#   bash spells/cloudflare-ctl.sh setup                # first run: install + authenticate
#   bash spells/cloudflare-ctl.sh r2-setup --dry-run
#   bash spells/cloudflare-ctl.sh r2-domain add        # attach cdn.joinrabble.world
#   bash spells/cloudflare-ctl.sh r2-domain verify     # poll until the TLS cert is active
#   bash spells/cloudflare-ctl.sh deploy-rc v0.0.0.1-rc.1   # build + upload Aether RC1 to CDN
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

# Prefer globally installed wrangler; fall back to npx on-demand (no global install needed)
if ! command -v wrangler &>/dev/null; then
  wrangler() { npx --yes wrangler "$@"; }
fi

# Print a "run setup" hint — call before any prerequisite-failure exit
suggest_setup() {
  echo ""
  info "Run: bash spells/$(basename "$0") setup"
}

# ─ Paths ─────────────────────────────────────────────────────────────────────
SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
CF_CONFIG_DIR="$GRIMOIRE_ROOT/.cloudflare"

# ─ Defaults (overridable via env) ─────────────────────────────────────────────
GITHUB_ORG="${GITHUB_ORG:-RaBbLE-Collective}"   # repos now live under the org
CDN_DOMAIN="${CDN_DOMAIN:-cdn.joinrabble.world}"
CDN_BUCKET="${CDN_BUCKET:-rabble-cdn-prod}"

# Source saved credentials if present (written by: cloudflare-ctl.sh setup)
# Env vars always take precedence over stored config.
CF_CONFIG_FILE="$CF_CONFIG_DIR/config"
if [ -f "$CF_CONFIG_FILE" ]; then
  # shellcheck source=/dev/null
  source "$CF_CONFIG_FILE"
  # Export so wrangler and other child processes inherit the token
  export CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_ZONE_ID
fi

# ─ Commands ──────────────────────────────────────────────────────────────────

cmd_setup() {
  header "Cloudflare Setup"

  echo ""
  info "Installs wrangler, collects credentials, and saves to $CF_CONFIG_DIR/config"
  info "(gitignored, chmod 600 — never committed)"
  echo ""

  # ── Prerequisite: Node.js / npm ─────────────────────────────────────────
  if ! command -v npm &>/dev/null; then
    warn "npm not found — Node.js is required to install wrangler."
    echo ""
    info "Install via RaBbLE-OS Ansible (recommended):"
    info "  cd RaBbLE-OS"
    info "  ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml --tags collective -K"
    echo ""
    info "Or install Node.js manually: https://nodejs.org"
    echo ""
    read -r -p "  Continue anyway (wrangler install will fail)? [y/N] " _npm_cont
    [[ "${_npm_cont:-N}" =~ ^[yY] ]] || exit 0
    echo ""
  fi

  # ── Step 1: wrangler ────────────────────────────────────────────────────
  info "Step 1/4  wrangler CLI"

  if command -v wrangler &>/dev/null; then
    ok "wrangler installed globally ($(wrangler --version 2>/dev/null || echo 'unknown'))"
  elif npx --yes wrangler --version &>/dev/null 2>&1; then
    ok "wrangler available via npx — no global install needed"
    info "To install globally: npm install -g wrangler"
  else
    warn "Installing wrangler globally..."
    if npm install -g wrangler; then
      ok "wrangler installed"
    else
      err "npm install failed. Install Node.js first: https://nodejs.org"
      exit 1
    fi
  fi
  echo ""

  # ── Step 2: API token ────────────────────────────────────────────────────
  info "Step 2/4  Cloudflare API token"
  info "Create at: https://dash.cloudflare.com/profile/api-tokens"
  info "Scopes needed: Account > R2:Edit  ·  Zone > DNS:Edit + SSL and Certificates:Edit"
  echo ""

  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    local masked="${CLOUDFLARE_API_TOKEN:0:10}...${CLOUDFLARE_API_TOKEN: -5}"
    ok "CLOUDFLARE_API_TOKEN already set ($masked)"
    read -r -p "  Use this token? [Y/n] " _use
    if [[ "${_use:-Y}" =~ ^[nN] ]]; then
      read -s -r -p "  Paste new API token: " CLOUDFLARE_API_TOKEN; echo ""
    fi
  else
    read -s -r -p "  Paste API token: " CLOUDFLARE_API_TOKEN; echo ""
    if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
      err "API token required"
      exit 1
    fi
  fi
  export CLOUDFLARE_API_TOKEN
  ok "API token accepted"
  echo ""

  # ── Step 3: Account ID ──────────────────────────────────────────────────
  info "Step 3/4  Cloudflare Account ID"
  info "Found in the right panel at: https://dash.cloudflare.com"
  echo ""

  if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    ok "CLOUDFLARE_ACCOUNT_ID: $CLOUDFLARE_ACCOUNT_ID"
    read -r -p "  Use this? [Y/n] " _use
    if [[ "${_use:-Y}" =~ ^[nN] ]]; then
      read -r -p "  Account ID: " CLOUDFLARE_ACCOUNT_ID
    fi
  else
    read -r -p "  Account ID: " CLOUDFLARE_ACCOUNT_ID
    if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
      err "Account ID required"
      exit 1
    fi
  fi
  export CLOUDFLARE_ACCOUNT_ID
  ok "Account ID: $CLOUDFLARE_ACCOUNT_ID"
  echo ""

  # ── Step 4: Zone ID ─────────────────────────────────────────────────────
  info "Step 4/4  Zone ID for joinrabble.world"
  info "Found on the Overview tab at: https://dash.cloudflare.com (right panel)"
  echo ""

  if [ -n "${CLOUDFLARE_ZONE_ID:-}" ]; then
    ok "CLOUDFLARE_ZONE_ID: $CLOUDFLARE_ZONE_ID"
    read -r -p "  Use this? [Y/n] " _use
    if [[ "${_use:-Y}" =~ ^[nN] ]]; then
      read -r -p "  Zone ID: " CLOUDFLARE_ZONE_ID
    fi
  else
    read -r -p "  Zone ID: " CLOUDFLARE_ZONE_ID
    if [ -z "${CLOUDFLARE_ZONE_ID:-}" ]; then
      warn "Zone ID not set — r2-domain add will not work until provided"
    fi
  fi
  export CLOUDFLARE_ZONE_ID
  [ -n "${CLOUDFLARE_ZONE_ID:-}" ] && ok "Zone ID: $CLOUDFLARE_ZONE_ID"
  echo ""

  # ── Save config ──────────────────────────────────────────────────────────
  mkdir -p "$CF_CONFIG_DIR"
  cat > "$CF_CONFIG_DIR/config" <<CFEOF
# Cloudflare credentials — DO NOT COMMIT (gitignored)
# Written by: bash spells/cloudflare-ctl.sh setup  ($(date +%Y-%m-%d))
export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN}"
export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID}"
export CLOUDFLARE_ZONE_ID="${CLOUDFLARE_ZONE_ID:-}"
CFEOF
  chmod 600 "$CF_CONFIG_DIR/config"
  ok "Credentials saved to $CF_CONFIG_DIR/config"
  echo ""

  # ── GitHub Actions secrets (optional) ───────────────────────────────────
  if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    info "gh CLI authenticated. Push secrets to GitHub Actions now?"
    read -r -p "  Push to RaBbLE-Aether? [Y/n] " _push
    if [[ ! "${_push:-Y}" =~ ^[nN] ]]; then
      cmd_secrets_setup "aether"
    fi
  else
    info "gh CLI not authenticated — skipping GitHub secrets push"
    info "When ready: bash spells/cloudflare-ctl.sh secrets-setup aether"
  fi

  echo ""
  ok "Setup complete."
  echo ""
  info "Next steps:"
  info "  bash spells/cloudflare-ctl.sh r2-setup          # ensure R2 bucket exists"
  info "  bash spells/cloudflare-ctl.sh r2-domain add     # attach cdn.joinrabble.world"
  info "  bash spells/cloudflare-ctl.sh r2-domain verify  # wait for TLS cert (~2 min)"
  info "  (then run publish-rc.sh to deploy Aether RC1)"
  echo ""
}

cmd_auth() {
  header "Cloudflare Authentication"

  # Check wrangler auth
  if wrangler whoami &>/dev/null; then
    ok "wrangler authenticated"
    wrangler whoami
  else
    warn "wrangler not authenticated"
    suggest_setup
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

  # Verify wrangler (function or binary)
  if ! type wrangler &>/dev/null; then
    err "wrangler not found"
    suggest_setup; exit 1
  fi

  # Verify auth
  if ! wrangler whoami &>/dev/null; then
    err "wrangler not authenticated"
    suggest_setup; exit 1
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
    suggest_setup; exit 1
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

  if ! type wrangler &>/dev/null; then
    err "wrangler not found"
    suggest_setup; exit 1
  fi
  if ! wrangler whoami &>/dev/null; then
    err "wrangler not authenticated"
    suggest_setup; exit 1
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
    err "gh CLI not installed — https://cli.github.com"
    suggest_setup; exit 1
  fi

  if ! gh auth status &>/dev/null 2>&1; then
    err "gh CLI not authenticated"
    info "Run: gh auth login"
    suggest_setup; exit 1
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

cmd_deploy_rc() {
  local version="${1:-}"

  header "Deploy Aether RC → CDN"

  if [ -z "$version" ]; then
    warn "Usage: cloudflare-ctl.sh deploy-rc <version>"
    info "Example: cloudflare-ctl.sh deploy-rc v0.0.0.1-rc.1"
    exit 1
  fi

  # Normalize version
  version="${version#v}"
  RC_VERSION="v${version}"
  R2_PREFIX="aether/${RC_VERSION}"
  AETHER_ROOT="$(dirname "$GRIMOIRE_ROOT")/RaBbLE-Aether"

  # Preflight: wrangler auth
  if ! wrangler whoami &>/dev/null; then
    err "wrangler not authenticated — run: npx wrangler login"
    suggest_setup; exit 1
  fi
  ok "wrangler authenticated"

  # Preflight: Aether repo
  if [[ ! -d "$AETHER_ROOT" ]]; then
    err "RaBbLE-Aether not found: $AETHER_ROOT"
    exit 1
  fi
  AETHER_SHA=$(git -C "$AETHER_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
  AETHER_DIRTY=$(git -C "$AETHER_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  info "Aether @ $AETHER_SHA"
  [[ "$AETHER_DIRTY" -gt 0 ]] && warn "Aether has $AETHER_DIRTY uncommitted change(s) — building working tree"
  info "Target: $CDN_DOMAIN/$R2_PREFIX/"
  echo ""

  # Build Aether
  info "Building Aether..."
  if [[ ! -f "$AETHER_ROOT/node_modules/.bin/esbuild" ]]; then
    info "Installing Aether deps..."
    npm ci --prefix "$AETHER_ROOT" --silent
  fi
  npm run build:min --prefix "$AETHER_ROOT" 2>&1 | grep -E 'dist/|Done|error' || true

  for f in dist/aether.css dist/aether.min.css; do
    [[ -f "$AETHER_ROOT/$f" ]] || { err "Build output missing: $f"; exit 1; }
  done
  ok "Aether built"
  echo ""

  # Upload to R2
  info "Uploading → $CDN_BUCKET/$R2_PREFIX/"

  _r2_put() {
    local src="$1" key="$2" ct="$3"
    if [[ ! -f "$src" ]]; then
      warn "  skipping (missing): $(basename "$src")"
      return 0
    fi
    if wrangler r2 object put "${CDN_BUCKET}/${key}" --file "$src" --content-type "$ct" 2>/dev/null; then
      ok "  $(basename "$key")"
    else
      err "  failed: $(basename "$key")"
      return 1
    fi
  }

  _r2_put "$AETHER_ROOT/dist/aether.css"         "$R2_PREFIX/aether.css"         "text/css"
  _r2_put "$AETHER_ROOT/dist/aether.css.map"     "$R2_PREFIX/aether.css.map"     "application/json"
  _r2_put "$AETHER_ROOT/dist/aether.min.css"     "$R2_PREFIX/aether.min.css"     "text/css"
  _r2_put "$AETHER_ROOT/dist/aether.min.css.map" "$R2_PREFIX/aether.min.css.map" "application/json"

  echo ""
  ok "Deployed to CDN"
  info "  https://$CDN_DOMAIN/$R2_PREFIX/aether.css"
  info "  https://$CDN_DOMAIN/$R2_PREFIX/aether.min.css"
  echo ""

  # Spot-check via curl
  info "Verifying..."
  TEST_URL="https://$CDN_DOMAIN/$R2_PREFIX/aether.min.css"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_URL" 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ]; then
    ok "Live: $TEST_URL"
  else
    warn "HTTP $HTTP_CODE — CDN propagation may take a minute"
    info "Retry: bash spells/cloudflare-ctl.sh monitor aether $RC_VERSION"
  fi
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
  setup)         cmd_setup ;;
  auth)          cmd_auth ;;
  r2-setup)      cmd_r2_setup "${2:-}" ;;
  r2-list)       cmd_r2_list ;;
  r2-verify)     cmd_r2_verify ;;
  r2-domain)     cmd_r2_domain "${2:-}" ;;
  deploy-rc)     cmd_deploy_rc "${2:-}" ;;
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
