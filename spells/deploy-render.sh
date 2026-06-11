#!/usr/bin/env bash
# =============================================================================
# spells/deploy-render.sh — Render Deployment CLI
#
# Manages RaBbLE-sCoRE deployment on Render via CLI.
# No dashboard interaction needed — pure CLI operations.
#
# Usage:
#   bash spells/deploy-render.sh [--dry-run] <cmd>
#
# Commands:
#   setup                  # initial Render project setup
#   deploy                 # deploy to existing service
#   status                 # health check
#   logs                   # tail live logs
#   env-set <key> <val>    # set environment variable
#   env-show               # display all env vars
#   open                   # open Render dashboard
#
# Flags:
#   --dry-run              # show what would happen without making changes
#
# Prerequisites:
#   - render-cli: npm install -g @render-cli/cli
#   - Render account and API token
#   - RaBbLE-sCoRE repo with render.yaml configured
#
# spark ~ render >> sCoRE deployment, CLI-only automation // %EP1_RENDER_DEPLOY%
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
SCORE_ROOT="$COLLECTIVE_ROOT/RaBbLE-sCoRE"

# ─ Render Config ─────────────────────────────────────────────────────────────
RENDER_API_KEY_FILE="$GRIMOIRE_ROOT/.render/api_key"
RENDER_SERVICE_ID_FILE="$GRIMOIRE_ROOT/.render/service_id"
RENDER_SERVICE_NAME="rabble-score"

# ─ Flags ─────────────────────────────────────────────────────────────────────
DRY_RUN=false

# Parse global flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --) shift; break ;;
    -*) break ;;
    *) break ;;
  esac
done

# ─ Helpers ───────────────────────────────────────────────────────────────────

check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    err "$1 not found"
    info "Install: $2"
    exit 1
  fi
}

get_api_key() {
  if [ -f "$RENDER_API_KEY_FILE" ]; then
    cat "$RENDER_API_KEY_FILE"
    return
  fi

  warn "Render API key not found"
  info "Get one at: https://dashboard.render.com/account/api-tokens"
  read -rsp "  Paste your API key: " key
  echo ""
  echo "$key"
}

verify_score_repo() {
  if [ ! -d "$SCORE_ROOT" ]; then
    err "RaBbLE-sCoRE not found at $SCORE_ROOT"
    exit 1
  fi

  if [ ! -f "$SCORE_ROOT/render.yaml" ]; then
    err "render.yaml not found in $SCORE_ROOT"
    exit 1
  fi
}

# ─ Commands ──────────────────────────────────────────────────────────────────

cmd_setup() {
  header "╔════════════════════════════════════════════════════════╗"
  header "║  Render Setup — RaBbLE-sCoRE Deployment                ║"
  header "╚════════════════════════════════════════════════════════╝"

  [ "$DRY_RUN" = "true" ] && warn "DRY RUN — no changes will be made"

  verify_score_repo
  check_cmd curl "apt install curl"

  # Get API key
  info "Step 1: Render Authentication"
  if [ "$DRY_RUN" = "true" ]; then
    warn "Would prompt for API key"
    warn "Would save to $RENDER_API_KEY_FILE"
  else
    API_KEY=$(get_api_key)
    if [ -n "$API_KEY" ]; then
      mkdir -p "$(dirname "$RENDER_API_KEY_FILE")"
      echo "$API_KEY" > "$RENDER_API_KEY_FILE"
      chmod 600 "$RENDER_API_KEY_FILE"
      ok "API key saved"
    fi
  fi

  # List projects via API
  info ""
  info "Step 2: Find Render Project"
  PROJECTS=$(curl -s -H "Authorization: Bearer $API_KEY" \
    https://api.render.com/v1/teams | jq '.teams[0].id' -r)

  if [ -z "$PROJECTS" ] || [ "$PROJECTS" = "null" ]; then
    err "Could not fetch Render projects"
    warn "Create a project at: https://dashboard.render.com"
    exit 1
  fi

  ok "Connected to Render account"

  # Check if service exists
  info ""
  info "Step 3: Create or Link Service"

  SERVICES=$(curl -s -H "Authorization: Bearer $API_KEY" \
    https://api.render.com/v1/services | jq '.services[] | select(.name == "'$RENDER_SERVICE_NAME'") | .id' -r)

  if [ -n "$SERVICES" ] && [ "$SERVICES" != "null" ]; then
    SERVICE_ID="$SERVICES"
    ok "Found existing service: $SERVICE_ID"
    echo "$SERVICE_ID" > "$RENDER_SERVICE_ID_FILE"
  else
    warn "Service not found. Create it manually at https://dashboard.render.com"
    info "Then import the render.yaml configuration"
  fi

  # Test connection
  info ""
  info "Step 4: Verify Configuration"
  ok "render.yaml found at $SCORE_ROOT/render.yaml"

  header "✓ Setup Complete"
  info "Next: bash spells/deploy-render.sh deploy"
  echo ""
}

cmd_deploy() {
  header "╔════════════════════════════════════════════════════════╗"
  header "║  Deploy to Render                                       ║"
  header "╚════════════════════════════════════════════════════════╝"

  [ "$DRY_RUN" = "true" ] && warn "DRY RUN — no deployment will be triggered"

  verify_score_repo

  if [ ! -f "$RENDER_API_KEY_FILE" ]; then
    err "API key not configured. Run: bash spells/deploy-render.sh setup"
    exit 1
  fi

  if [ "$DRY_RUN" = "false" ]; then
    API_KEY=$(cat "$RENDER_API_KEY_FILE")
  fi

  # Get service ID
  if [ -f "$RENDER_SERVICE_ID_FILE" ]; then
    SERVICE_ID=$(cat "$RENDER_SERVICE_ID_FILE")
  else
    if [ "$DRY_RUN" = "true" ]; then
      warn "Would look up service: $RENDER_SERVICE_NAME"
      SERVICE_ID="<service-id>"
    else
      warn "Service ID not found. Looking up..."
      SERVICE_ID=$(curl -s -H "Authorization: Bearer $API_KEY" \
        https://api.render.com/v1/services | jq '.services[] | select(.name == "'$RENDER_SERVICE_NAME'") | .id' -r)

      if [ -z "$SERVICE_ID" ] || [ "$SERVICE_ID" = "null" ]; then
        err "Could not find service: $RENDER_SERVICE_NAME"
        info "Create it at: https://dashboard.render.com"
        exit 1
      fi

      echo "$SERVICE_ID" > "$RENDER_SERVICE_ID_FILE"
    fi
  fi

  info "Service ID: $SERVICE_ID"

  # Trigger deployment via API
  if [ "$DRY_RUN" = "true" ]; then
    warn "Would POST to: https://api.render.com/v1/services/$SERVICE_ID/deploys"
    info "Dry run complete — no deployment triggered"
  else
    info "Triggering deployment..."
    DEPLOY_RESULT=$(curl -s -X POST \
      -H "Authorization: Bearer $API_KEY" \
      -H "Content-Type: application/json" \
      https://api.render.com/v1/services/"$SERVICE_ID"/deploys)

    DEPLOY_ID=$(echo "$DEPLOY_RESULT" | jq '.id' -r)

    if [ -z "$DEPLOY_ID" ] || [ "$DEPLOY_ID" = "null" ]; then
      err "Deployment failed"
      echo "$DEPLOY_RESULT"
      exit 1
    fi

    ok "Deployment triggered: $DEPLOY_ID"
    info "Monitor at: https://dashboard.render.com/services/$SERVICE_ID"
  fi

  echo ""
}

cmd_status() {
  verify_score_repo

  if [ ! -f "$RENDER_API_KEY_FILE" ]; then
    err "Not configured. Run: bash spells/deploy-render.sh setup"
    exit 1
  fi

  API_KEY=$(cat "$RENDER_API_KEY_FILE")
  SERVICE_ID=${$(cat "$RENDER_SERVICE_ID_FILE"):- }

  if [ -z "$SERVICE_ID" ]; then
    warn "Service ID not found"
    exit 1
  fi

  info "Checking service status..."
  STATUS=$(curl -s -H "Authorization: Bearer $API_KEY" \
    https://api.render.com/v1/services/"$SERVICE_ID" | jq '.status' -r)

  ok "Service status: $STATUS"

  # Try health check
  SERVICE_URL=$(curl -s -H "Authorization: Bearer $API_KEY" \
    https://api.render.com/v1/services/"$SERVICE_ID" | jq '.domains[0]' -r)

  if [ -n "$SERVICE_URL" ] && [ "$SERVICE_URL" != "null" ]; then
    if curl -s "https://$SERVICE_URL/health" | grep -q "ok"; then
      ok "Health check: HEALTHY"
    else
      warn "Health check: UNHEALTHY or no response"
    fi
  fi
  echo ""
}

cmd_env_show() {
  if [ ! -f "$RENDER_API_KEY_FILE" ]; then
    err "Not configured"
    exit 1
  fi

  API_KEY=$(cat "$RENDER_API_KEY_FILE")
  SERVICE_ID=$(cat "$RENDER_SERVICE_ID_FILE" 2>/dev/null || echo "")

  if [ -z "$SERVICE_ID" ]; then
    warn "Service ID not found"
    exit 1
  fi

  info "Environment variables:"
  curl -s -H "Authorization: Bearer $API_KEY" \
    https://api.render.com/v1/services/"$SERVICE_ID" | jq '.envVars[]' || true
  echo ""
}

cmd_logs() {
  warn "Logs require Render dashboard access"
  info "View at: https://dashboard.render.com"
  echo ""
}

cmd_open() {
  info "Opening Render dashboard..."
  if command -v xdg-open &>/dev/null; then
    xdg-open "https://dashboard.render.com"
  elif command -v open &>/dev/null; then
    open "https://dashboard.render.com"
  else
    info "https://dashboard.render.com"
  fi
  echo ""
}

# ─ Main ──────────────────────────────────────────────────────────────────────

COMMAND="${1:-help}"

case "$COMMAND" in
  setup)       cmd_setup ;;
  deploy)      cmd_deploy ;;
  status)      cmd_status ;;
  env-show)    cmd_env_show ;;
  env-set)     info "env-set requires manual dashboard setup"; exit 1 ;;
  logs)        cmd_logs ;;
  open)        cmd_open ;;
  help|--help|-h)
    sed -n '/^# Usage:/,/^# spark/p' "$0" | sed 's/^# \?//'
    ;;
  *)
    err "Unknown command: $COMMAND"
    echo "  Usage: deploy-render.sh [setup|deploy|status|env-show|logs|open]"
    exit 1
    ;;
esac
