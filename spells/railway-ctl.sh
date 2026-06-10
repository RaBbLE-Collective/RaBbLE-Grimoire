#!/usr/bin/env bash
# =============================================================================
# spells/railway-ctl.sh — Unified Railway Control (sCoRE Deployment)
#
# Master controller for Railway cloud infrastructure. Handles setup,
# deployment, monitoring, and environment management for RaBbLE services.
#
# Usage:
#   bash spells/railway-ctl.sh <command> [service] [options]
#
# Commands:
#   setup              # Install Railway CLI and authenticate
#   init <service>     # Initialize Railway project
#   deploy <service>   # Deploy service to Railway (default: server)
#   status <service>   # Health check and service status
#   logs <service>     # Tail live service logs
#   env-show <service> # Display environment variables
#   env-set <service>  # Set environment variables
#   open               # Open Railway dashboard
#   help               # Show this help
#
# Services:
#   server             RaBbLE-sCoRE FastAPI server (default)
#
# Examples:
#   bash spells/railway-ctl.sh setup
#   bash spells/railway-ctl.sh deploy server
#   bash spells/railway-ctl.sh status server
#   bash spells/railway-ctl.sh logs server
#
# Flags:
#   --dry-run          Preview without making changes
#
# spark ~ railway >> unified sCoRE deployment control // %RAILWAY_CTL%
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

# ─ Commands ──────────────────────────────────────────────────────────────────

cmd_setup() {
  header "Railway Setup"

  if [ "${1:-}" = "--dry-run" ]; then
    warn "DRY RUN — no installation will occur"
  fi

  info "Step 1: Check Railway CLI"
  if command -v railway &>/dev/null; then
    RAILWAY_VERSION=$(railway --version 2>/dev/null || echo "unknown")
    ok "Railway CLI installed ($RAILWAY_VERSION)"
  else
    if [ "${1:-}" = "--dry-run" ]; then
      warn "Would install: npm install -g @railway/cli"
    else
      warn "Installing Railway CLI..."
      npm install -g @railway/cli
      ok "Railway CLI installed"
    fi
  fi

  info ""
  info "Step 2: Railway Authentication"
  if [ "${1:-}" = "--dry-run" ]; then
    warn "Would verify: railway whoami"
  else
    if railway whoami &>/dev/null; then
      ok "Already authenticated"
    else
      warn "Authenticate with Railway..."
      railway login
      ok "Authentication complete"
    fi
  fi

  echo ""
}

cmd_init() {
  local service="${1:-server}"
  local dry_run="${2:-}"

  header "Initialize Railway Project"

  if [ "$dry_run" = "--dry-run" ]; then
    warn "Would initialize: railway init"
  else
    cd "$SCORE_ROOT/$service"
    if railway status &>/dev/null 2>&1; then
      ok "Project already initialized"
    else
      info "Initializing Railway project..."
      railway init
      ok "Project initialized"
    fi
  fi

  echo ""
}

cmd_deploy() {
  local service="${1:-server}"
  local dry_run="${2:-}"

  header "Deploy to Railway — $service"

  if [ "$dry_run" = "--dry-run" ]; then
    warn "Would deploy: railway up --detach"
    info "From: $SCORE_ROOT/$service/"
  else
    if [ ! -d "$SCORE_ROOT/$service" ]; then
      err "Service not found: $service"
      exit 1
    fi

    cd "$SCORE_ROOT/$service"

    info "Deploying $service..."
    if railway up --detach; then
      ok "Deployment triggered"

      # Get URL
      if command -v railway &>/dev/null; then
        sleep 2
        URL=$(railway open --external --silent 2>/dev/null || echo "https://railway.app")
        info "Service URL: $URL"
      fi
    else
      err "Deployment failed"
      exit 1
    fi
  fi

  echo ""
}

cmd_status() {
  local service="${1:-server}"

  header "Service Status — $service"

  cd "$SCORE_ROOT/$service"

  if railway status 2>/dev/null; then
    ok "Service is ready"

    # Try health endpoint
    URL=$(railway open --external --silent 2>/dev/null || echo "")
    if [ -n "$URL" ]; then
      if curl -s "$URL/health" &>/dev/null; then
        ok "Health check: HEALTHY"
      else
        warn "Health check: no response"
      fi
    fi
  else
    warn "Could not reach service"
  fi

  echo ""
}

cmd_logs() {
  local service="${1:-server}"

  header "Logs — $service"

  cd "$SCORE_ROOT/$service"
  railway logs -f 2>&1 || true

  echo ""
}

cmd_env_show() {
  local service="${1:-server}"

  header "Environment Variables — $service"

  cd "$SCORE_ROOT/$service"
  railway variables 2>&1 || true

  echo ""
}

cmd_env_set() {
  local service="${1:-server}"

  header "Set Environment Variable — $service"

  read -rp "  Variable name: " var_name
  read -rsp "  Variable value: " var_value
  echo ""

  cd "$SCORE_ROOT/$service"
  railway variables set "$var_name" "$var_value" || true

  ok "Variable set"
  echo ""
}

cmd_open() {
  info "Opening Railway Dashboard..."
  if command -v xdg-open &>/dev/null; then
    xdg-open "https://railway.app/dashboard"
  elif command -v open &>/dev/null; then
    open "https://railway.app/dashboard"
  else
    info "https://railway.app/dashboard"
  fi
  echo ""
}

cmd_help() {
  sed -n '/^# Usage:/,/^# spark/p' "$0" | sed 's/^# \?//'
}

# ─ Main ──────────────────────────────────────────────────────────────────────

COMMAND="${1:-help}"
SERVICE="${2:-server}"

case "$COMMAND" in
  setup)      cmd_setup "${2:-}" ;;
  init)       cmd_init "$SERVICE" "${3:-}" ;;
  deploy)     cmd_deploy "$SERVICE" "${3:-}" ;;
  status)     cmd_status "$SERVICE" ;;
  logs)       cmd_logs "$SERVICE" ;;
  env-show)   cmd_env_show "$SERVICE" ;;
  env-set)    cmd_env_set "$SERVICE" ;;
  open)       cmd_open ;;
  help|--help|-h)
    cmd_help ;;
  *)
    err "Unknown command: $COMMAND"
    echo "  Run: bash spells/railway-ctl.sh help"
    exit 1
    ;;
esac
