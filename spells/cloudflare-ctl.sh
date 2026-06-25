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
#   login                      # OAuth login via browser (grants Workers deploy permission)
#   auth                       # Show auth status + test Workers and R2 permissions
#   token-update               # Show instructions to add Workers:Edit to existing token
#
#   ── Workers (per-subdomain CDN) ───────────────────────────────────────────────
#   deploy <member> [ver]      # Build (versioned) + wrangler deploy → subdomain Workers
#   domain <member> [add|verify|list|remove]  # Manage custom domain on a Worker
#   workers-list               # List all deployed Worker scripts
#
#   ── R2 / Legacy CDN ──────────────────────────────────────────────────────────
#   r2-setup                   # Create R2 buckets (rabble-cdn-prod)
#   r2-list                    # List R2 buckets
#   r2-verify                  # Verify R2 bucket configuration
#   r2-domain [add|verify|remove]  # Connect cdn.joinrabble.world → bucket (public CDN)
#   deploy-rc <version>        # Build Aether + upload to R2 at versioned CDN path
#
#   ── General ──────────────────────────────────────────────────────────────────
#   secrets-setup <member>     # Configure GitHub Actions secrets
#   secrets-show               # Display configured secrets (masked)
#   status                     # Overall deployment status (Workers + R2)
#   monitor <member> [ver]     # Monitor CDN deployment for member
#   open                       # Open Cloudflare dashboard
#   help                       # Show this help
#
# Examples:
#   bash spells/cloudflare-ctl.sh setup                # first run: install + authenticate
#   bash spells/cloudflare-ctl.sh login                # OAuth login (needed for Workers deploy)
#   bash spells/cloudflare-ctl.sh auth                 # show what the current token can do
#   bash spells/cloudflare-ctl.sh token-update         # instructions to add Workers:Edit
#   bash spells/cloudflare-ctl.sh deploy aether v0.0.0.1-rc.1 # build versioned + deploy
#   bash spells/cloudflare-ctl.sh deploy score                 # deploy proxy Worker (no build)
#   bash spells/cloudflare-ctl.sh deploy chrysalis             # deploy Chrysalis-Web → dev.joinrabble.world
#   bash spells/cloudflare-ctl.sh domain aether add            # wire aether.joinrabble.world
#   bash spells/cloudflare-ctl.sh domain aether verify         # confirm subdomain is live
#   bash spells/cloudflare-ctl.sh domain chrysalis add         # wire dev.joinrabble.world
#   bash spells/cloudflare-ctl.sh workers-list                 # see all deployed Workers
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

  # ── wrangler login state ──────────────────────────────────────────────────
  # Unset API token to test OAuth state independently (|| true guards set -e)
  # Use exit code, not output text, to determine OAuth state (error messages
  # contain "logged in" which would give false positives on grep)
  if (env -u CLOUDFLARE_API_TOKEN wrangler whoami &>/dev/null 2>&1); then
    ok "wrangler OAuth: logged in"
  else
    warn "wrangler OAuth: not logged in (run: bash spells/cloudflare-ctl.sh login)"
  fi

  # ── API token state ───────────────────────────────────────────────────────
  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    masked="${CLOUDFLARE_API_TOKEN:0:10}...${CLOUDFLARE_API_TOKEN: -5}"
    ok "API token: set ($masked)"
  else
    warn "API token: not set (run: bash spells/cloudflare-ctl.sh setup)"
  fi

  if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    ok "Account ID: $CLOUDFLARE_ACCOUNT_ID"
  else
    warn "Account ID: not set"
  fi
  if [ -n "${CLOUDFLARE_ZONE_ID:-}" ]; then
    ok "Zone ID:    $CLOUDFLARE_ZONE_ID"
  else
    warn "Zone ID:    not set (needed for domain add)"
  fi

  # ── Permission probes ─────────────────────────────────────────────────────
  echo ""
  info "Permission probes:"

  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ] && [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    # R2 read
    R2_RESP=$(curl -s "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/r2/buckets" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    if echo "$R2_RESP" | grep -qE '"success"[[:space:]]*:[[:space:]]*true'; then
      ok "  R2 read:         ✓  (list buckets works)"
    else
      warn "  R2 read:         ✗  (missing Account > R2 > Read)"
    fi

    # Workers read
    WKR_RESP=$(curl -s "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    if echo "$WKR_RESP" | grep -qE '"success"[[:space:]]*:[[:space:]]*true'; then
      ok "  Workers read:    ✓"
    else
      warn "  Workers read:    ✗  (missing Account > Workers Scripts > Read)"
    fi

    # Workers write probe — check for a known-existing script; 403 = auth, 404 = no script = write allowed
    WKR_WRITE_RESP=$(curl -s -X GET \
      "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/services/rabble-aether" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    WKR_WRITE_CODE=$(echo "$WKR_WRITE_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',[{}])[0].get('code',0) if not d.get('success') else 'ok')" 2>/dev/null)
    if [ "$WKR_WRITE_CODE" = "ok" ] || echo "$WKR_WRITE_RESP" | grep -qE '"success"[[:space:]]*:[[:space:]]*true'; then
      ok "  Workers write:   ✓"
    elif echo "$WKR_WRITE_RESP" | grep -qE '"code":10000|Authentication error'; then
      warn "  Workers write:   ✗  (Authentication error 10000 — token missing Workers Scripts:Edit)"
      info "     Fix: bash spells/cloudflare-ctl.sh token-update"
      info "     Alt: bash spells/cloudflare-ctl.sh login  (OAuth has full access)"
    else
      info "  Workers write:   ?  (probe inconclusive)"
    fi

    # DNS edit (needed for domain add)
    DNS_RESP=$(curl -s "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?per_page=1" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    if echo "$DNS_RESP" | grep -qE '"success"[[:space:]]*:[[:space:]]*true'; then
      ok "  DNS read:        ✓  (zone access OK)"
    else
      warn "  DNS read:        ✗  (missing Zone > DNS > Read)"
    fi
  else
    warn "  (set CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID to probe permissions)"
  fi

  echo ""
}

# Open browser for OAuth login — grants full Workers + R2 access.
# The CLOUDFLARE_API_TOKEN is unset for the wrangler login process so wrangler
# stores its own OAuth token (~/.wrangler/config/default.toml).
# After login, wrangler deploy uses OAuth automatically when the API token is
# absent or for operations the token lacks permission for.
cmd_login() {
  header "Wrangler OAuth Login"
  info "Opens your browser for Cloudflare OAuth — grants Workers deploy + R2 access."
  echo ""
  warn "Interactive: your browser will open. Approve the OAuth grant, then return here."
  echo ""
  # Run wrangler without the API token so it goes through OAuth, not the stored token
  env -u CLOUDFLARE_API_TOKEN wrangler login
  echo ""
  ok "OAuth login complete"
  info ""
  info "After OAuth login, Workers deploy uses OAuth credentials."
  info "Your R2 API token is still used for R2 operations."
  echo ""
  info "Now re-run your deploy:"
  info "  bash spells/cloudflare-ctl.sh deploy aether v0.0.0.1-rc.1"
  echo ""
}

# Show precise instructions for updating the existing API token to add Workers:Edit.
cmd_token_update() {
  header "Add Workers:Edit to API Token"
  echo ""
  info "Your saved token can read/write R2 but cannot deploy Workers."
  info "Add the missing permission in the Cloudflare dashboard:"
  echo ""
  info "  1. Open:  https://dash.cloudflare.com/profile/api-tokens"
  info "  2. Find your token and click Edit"
  info "  3. Under 'Account permissions' add:"
  info "       Workers Scripts — Edit"
  info "  4. Save. The token value stays the same — no need to re-run setup."
  echo ""
  info "If you can't edit the token, create a new one with these scopes:"
  info "  Account > Workers Scripts > Edit"
  info "  Account > R2 > Edit"
  info "  Zone > DNS > Edit    (for domain add)"
  info "  Zone > SSL and Certificates > Edit   (for r2-domain)"
  echo ""
  info "Then re-run setup to save the new token:"
  info "  bash spells/cloudflare-ctl.sh setup"
  echo ""
  info "Alternative — use OAuth (no token editing needed):"
  info "  bash spells/cloudflare-ctl.sh login"
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

# ─ Auth token resolution ─────────────────────────────────────────────────────
# Prefer wrangler OAuth token (workers:write scope) over the API token.
# The API token was created for R2/DNS only and lacks Workers Scripts:Edit.
_get_cf_auth_token() {
  local toml="${HOME}/.config/.wrangler/config/default.toml"
  if [ -f "$toml" ]; then
    local tok
    tok=$(grep '^oauth_token' "$toml" | head -1 | sed 's/.*= *"\(.*\)"/\1/')
    [ -n "$tok" ] && { echo "$tok"; return; }
  fi
  echo "${CLOUDFLARE_API_TOKEN:-}"
}

# ─ Member config lookup ──────────────────────────────────────────────────────
# Sets MEMBER_REPO, MEMBER_DIR, MEMBER_BUILD, WORKER_NAME, WORKER_DOMAIN,
# and optionally WRANGLER_CONFIG_FLAG (e.g. "-c wrangler.dev.jsonc")
_member_config() {
  local member="$1"
  WRANGLER_CONFIG_FLAG=""
  case "$member" in
    aether)    MEMBER_REPO="RaBbLE-Aether";    MEMBER_BUILD="npm run build:versioned"; WORKER_NAME="rabble-aether";        WORKER_DOMAIN="aether.joinrabble.world" ;;
    nebula)    MEMBER_REPO="RaBbLE-NeBuLA";    MEMBER_BUILD="npm run build:versioned"; WORKER_NAME="rabble-nebula";        WORKER_DOMAIN="nebula.joinrabble.world" ;;
    grimoire)  MEMBER_REPO="RaBbLE-Grimoire";  MEMBER_BUILD="";                        WORKER_NAME="rabble-grimoire";      WORKER_DOMAIN="grimoire.joinrabble.world" ;;
    score)     MEMBER_REPO="RaBbLE-sCoRE";     MEMBER_BUILD="";                        WORKER_NAME="rabble-score";         WORKER_DOMAIN="score.joinrabble.world" ;;
    world)     MEMBER_REPO="RaBbLE-World";     MEMBER_BUILD="";                        WORKER_NAME="rabble-collective";    WORKER_DOMAIN="joinrabble.world" ;;
    world-dev) MEMBER_REPO="RaBbLE-World";     MEMBER_BUILD="";                        WORKER_NAME="rabble-world-dev";     WORKER_DOMAIN="";
               WRANGLER_CONFIG_FLAG="-c wrangler.dev.jsonc" ;;
    chrysalis) MEMBER_REPO="RaBbLE-Chrysalis"; MEMBER_BUILD="";                        WORKER_NAME="rabble-chrysalis-web"; WORKER_DOMAIN="" ;;
    dev)       MEMBER_REPO="RaBbLE-Grimoire";  MEMBER_BUILD="";                        WORKER_NAME="rabble-dev";           WORKER_DOMAIN="dev.joinrabble.world" ;;
    *) err "Unknown member: $member  (aether|nebula|grimoire|score|world|world-dev|chrysalis|dev)"; return 1 ;;
  esac
  MEMBER_DIR="$(dirname "$GRIMOIRE_ROOT")/$MEMBER_REPO"
  # chrysalis: wrangler.jsonc lives inside Chrysalis-Web/, not the repo root
  [[ "$member" == "chrysalis" ]] && MEMBER_DIR="$MEMBER_DIR/Chrysalis-Web" || true
  # dev router: lives inside Grimoire's workers/dev/
  [[ "$member" == "dev" ]] && MEMBER_DIR="$GRIMOIRE_ROOT/workers/dev" || true
}

# ─ Workers commands ───────────────────────────────────────────────────────────

# Build (versioned if version given) then wrangler deploy from the member directory.
# Aether/NeBuLA use build:versioned which puts files in dist/<version>/; the root
# dist/ files are still updated too, so both pinned and @latest paths are served.
cmd_deploy() {
  local member="${1:-}"
  local version="${2:-}"

  if [ -z "$member" ]; then
    warn "Usage: cloudflare-ctl.sh deploy <member> [version]"
    info "Members: aether nebula grimoire score world world-dev chrysalis dev"
    exit 1
  fi

  _member_config "$member" || exit 1

  header "Deploy: $MEMBER_REPO"

  if [ ! -d "$MEMBER_DIR" ]; then
    err "Member directory not found: $MEMBER_DIR"
    exit 1
  fi

  # Check auth: OAuth session (preferred for Workers) or API token
  # Use subshells + || true to avoid set -e killing the script on non-zero exit
  OAUTH_OK=false
  TOKEN_OK=false
  if (env -u CLOUDFLARE_API_TOKEN wrangler whoami &>/dev/null 2>&1); then
    OAUTH_OK=true
  fi
  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ] && (wrangler whoami &>/dev/null 2>&1); then
    TOKEN_OK=true
  fi
  if ! $OAUTH_OK && ! $TOKEN_OK; then
    err "Not authenticated. Run: bash spells/cloudflare-ctl.sh login"
    suggest_setup; exit 1
  fi

  # Build step — versioned if a version was passed, plain build otherwise
  if [ -n "$MEMBER_BUILD" ]; then
    if [ -n "$version" ]; then
      VERSION_CLEAN="${version#v}"
      info "Building $MEMBER_REPO @ v$VERSION_CLEAN..."
      (cd "$MEMBER_DIR" && npm_config_version="v$VERSION_CLEAN" $MEMBER_BUILD) || { err "Build failed"; exit 1; }
    else
      info "Building $MEMBER_REPO (no version pin)..."
      (cd "$MEMBER_DIR" && $MEMBER_BUILD) || { err "Build failed"; exit 1; }
    fi
    ok "Build complete"
    echo ""
  fi

  # Deploy — prefer OAuth session; fall back to API token.
  # Capture output to detect specific auth errors and give actionable guidance.
  info "Deploying $WORKER_NAME..."
  DEPLOY_LOG=$(mktemp)
  DEPLOY_OK=false

  if $OAUTH_OK; then
    if (cd "$MEMBER_DIR" && env -u CLOUDFLARE_API_TOKEN wrangler deploy $WRANGLER_CONFIG_FLAG 2>&1 | tee "$DEPLOY_LOG"; exit "${PIPESTATUS[0]}"); then
      DEPLOY_OK=true
    fi
  fi

  if ! $DEPLOY_OK && $TOKEN_OK; then
    if (cd "$MEMBER_DIR" && wrangler deploy $WRANGLER_CONFIG_FLAG 2>&1 | tee -a "$DEPLOY_LOG"; exit "${PIPESTATUS[0]}"); then
      DEPLOY_OK=true
    fi
  fi

  if $DEPLOY_OK; then
    ok "$MEMBER_REPO deployed"
    rm -f "$DEPLOY_LOG"
    echo ""
    info "Custom domain: https://$WORKER_DOMAIN/"
    info "Wire it:       bash spells/cloudflare-ctl.sh domain $member add"
    echo ""
  else
    if grep -qE "Authentication error|code: 10000|code:10000" "$DEPLOY_LOG"; then
      echo ""
      err "Deploy blocked: authentication error (code 10000)"
      info ""
      info "Your API token is missing 'Workers Scripts:Edit' permission."
      info ""
      info "  Option A — fix the token (quickest):"
      info "    bash spells/cloudflare-ctl.sh token-update"
      info ""
      info "  Option B — OAuth login (full access, no token editing):"
      info "    bash spells/cloudflare-ctl.sh login"
      info "    Then retry: bash spells/cloudflare-ctl.sh deploy $member${version:+ $version}"
      info ""
      info "  Build output in $MEMBER_DIR/dist/ — nothing was lost."
    elif grep -q "Missing entry-point" "$DEPLOY_LOG"; then
      err "Deploy failed: no Worker entry-point (check wrangler.jsonc 'main' or 'assets')"
    else
      err "Deploy failed — see output above"
    fi
    rm -f "$DEPLOY_LOG"
    exit 1
  fi
}

# Add, verify, or remove the custom domain binding on a deployed Worker via CF API.
# Requires CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_API_TOKEN, and CLOUDFLARE_ZONE_ID for add.
cmd_domain() {
  local member="${1:-}"
  local action="${2:-verify}"

  if [ -z "$member" ]; then
    warn "Usage: cloudflare-ctl.sh domain <member> [add|verify|list|remove]"
    info "Members: aether nebula grimoire score world world-dev chrysalis dev"
    exit 1
  fi

  _member_config "$member" || exit 1

  header "Worker Domain: $WORKER_DOMAIN → $WORKER_NAME"

  if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    err "CLOUDFLARE_ACCOUNT_ID required"
    suggest_setup; exit 1
  fi

  local CF_TOKEN CF_API CF_AUTH
  CF_TOKEN=$(_get_cf_auth_token)
  if [ -z "$CF_TOKEN" ]; then
    err "No auth token available — run: bash spells/cloudflare-ctl.sh login"
    exit 1
  fi
  CF_API="https://api.cloudflare.com/client/v4"
  CF_AUTH=(-H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json")

  case "$action" in
    add|attach)
      if [ -z "${CLOUDFLARE_ZONE_ID:-}" ]; then
        err "CLOUDFLARE_ZONE_ID required to bind the domain to the zone"
        suggest_setup; exit 1
      fi
      info "Attaching $WORKER_DOMAIN → $WORKER_NAME..."
      RESULT=$(curl -s -X PUT "$CF_API/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/domains" \
        "${CF_AUTH[@]}" \
        -d "{\"environment\":\"production\",\"hostname\":\"$WORKER_DOMAIN\",\"service\":\"$WORKER_NAME\",\"zone_id\":\"$CLOUDFLARE_ZONE_ID\"}")
      if echo "$RESULT" | grep -qE '"success"[[:space:]]*:[[:space:]]*true'; then
        ok "Domain attached: https://$WORKER_DOMAIN/"
      else
        local msg
        msg=$(echo "$RESULT" | python3 -c "import sys,json; errs=json.load(sys.stdin).get('errors',[]); print(errs[0].get('message','unknown') if errs else 'unknown')" 2>/dev/null || echo "unknown error")
        err "Attach failed: $msg"
        info "Token needs: Account Workers Scripts:Edit + Zone DNS:Edit + SSL:Edit"
        exit 1
      fi
      ;;
    verify|status|check)
      info "Checking https://$WORKER_DOMAIN/ ..."
      HTTP=$(curl -s -o /dev/null -w "%{http_code}" "https://$WORKER_DOMAIN/" 2>/dev/null || echo "000")
      if [ "$HTTP" = "200" ] || [ "$HTTP" = "204" ] || [ "$HTTP" = "301" ] || [ "$HTTP" = "302" ]; then
        ok "Live: https://$WORKER_DOMAIN/  (HTTP $HTTP)"
      else
        warn "HTTP $HTTP — domain may not be wired yet"
        info "Wire it: bash spells/cloudflare-ctl.sh domain $member add"
      fi
      ;;
    list)
      info "All Worker custom domains on this account:"
      RESULT=$(curl -s "$CF_API/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/domains" "${CF_AUTH[@]}")
      if echo "$RESULT" | grep -qE '"success"[[:space:]]*:[[:space:]]*true'; then
        echo "$RESULT" | python3 -c "
import sys,json
data=json.load(sys.stdin).get('result',[])
if not data: print('  (none)')
for d in data: print(f'  {d[\"hostname\"]:40s} → {d[\"service\"]}')
" 2>/dev/null || warn "Could not parse response"
      else
        err "API request failed"
      fi
      ;;
    remove|detach)
      info "Looking up domain ID for $WORKER_DOMAIN..."
      RESULT=$(curl -s "$CF_API/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/domains" "${CF_AUTH[@]}")
      DOMAIN_ID=$(echo "$RESULT" | python3 -c "
import sys,json
data=json.load(sys.stdin).get('result',[])
for d in data:
  if d.get('hostname')=='$WORKER_DOMAIN': print(d.get('id','')); break
" 2>/dev/null)
      if [ -z "$DOMAIN_ID" ]; then
        warn "$WORKER_DOMAIN not found in domain list — may already be removed"
      else
        curl -s -X DELETE "$CF_API/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/domains/$DOMAIN_ID" "${CF_AUTH[@]}" >/dev/null
        ok "Domain removed: $WORKER_DOMAIN"
      fi
      ;;
    *)
      warn "Unknown action: $action  (add|verify|list|remove)"
      exit 1
      ;;
  esac
  echo ""
}

# List all Workers scripts deployed to this account.
cmd_workers_list() {
  header "Deployed Workers"

  if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    err "CLOUDFLARE_ACCOUNT_ID required"
    suggest_setup; exit 1
  fi

  local CF_TOKEN
  CF_TOKEN=$(_get_cf_auth_token)
  if [ -z "$CF_TOKEN" ]; then
    err "No auth token available — run: bash spells/cloudflare-ctl.sh login"
    exit 1
  fi

  RESULT=$(curl -s \
    "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/workers/scripts" \
    -H "Authorization: Bearer $CF_TOKEN")

  if echo "$RESULT" | grep -qE '"success"[[:space:]]*:[[:space:]]*true'; then
    echo "$RESULT" | python3 -c "
import sys,json
scripts=json.load(sys.stdin).get('result',[])
if not scripts: print('  (none)')
for s in scripts: print(f'  {s[\"id\"]}')
" 2>/dev/null || warn "Could not parse response"
  else
    err "API request failed — check CLOUDFLARE_API_TOKEN scope"
  fi
  echo ""
}

cmd_status() {
  header "Cloudflare Deployment Status"

  cmd_auth || true

  # ── Workers subdomain health ──────────────────────────────────────────────
  echo ""
  info "Workers subdomains:"
  # Format: member:domain:healthpath — grimoire is an assets-only Worker with no
  # root index (bare / is intentionally 404), so probe a known gist asset instead.
  for pair in \
      "aether:aether.joinrabble.world:/" \
      "nebula:nebula.joinrabble.world:/" \
      "grimoire:grimoire.joinrabble.world:/RaBbLE-Identity-gist.md" \
      "score:score.joinrabble.world:/" \
      "world:joinrabble.world:/" \
      "dev:dev.joinrabble.world:/"; do
    local m="${pair%%:*}" rest="${pair#*:}"
    local domain="${rest%%:*}" path="${rest#*:}"
    HTTP=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain$path" 2>/dev/null || echo "000")
    if [ "$HTTP" = "200" ] || [ "$HTTP" = "204" ] || [ "$HTTP" = "301" ]; then
      ok "$m  https://$domain$path  (HTTP $HTTP)"
    else
      warn "$m  https://$domain$path  (HTTP $HTTP — not live)"
    fi
  done

  # ── R2 CDN health ─────────────────────────────────────────────────────────
  echo ""
  cmd_r2_domain verify || true

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
  login)         cmd_login ;;
  auth)          cmd_auth ;;
  token-update)  cmd_token_update ;;
  deploy)        cmd_deploy "${2:-}" "${3:-}" ;;
  domain)        cmd_domain "${2:-}" "${3:-}" ;;
  workers-list)  cmd_workers_list ;;
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
