#!/usr/bin/env bash
# =============================================================================
# spells/railway-ctl.sh — Unified Railway Control (sCoRE Deployment)
#
# ⚠ DORMANT — NOT THE CURRENT BACKEND.
#   sCoRE's Episode-1 cloud target is RENDER → use `spells/deploy-render.sh`.
#   This spell is retained intact in case Railway is re-adopted as the backend
#   provider later. It is the single canonical Railway spell — the redundant
#   `deploy-railway.sh` and `deploy-score.sh` wrappers were folded in here (S105).
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

suggest_setup() {
  echo ""
  info "Run: bash spells/$(basename "$0") setup"
}

# ─ Paths ─────────────────────────────────────────────────────────────────────
SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
COLLECTIVE_ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"
SCORE_ROOT="$COLLECTIVE_ROOT/RaBbLE-sCoRE"

# ─ Commands ──────────────────────────────────────────────────────────────────

cmd_setup() {
  header "Railway Setup"

  local dry_run="${1:-}"
  [ "$dry_run" = "--dry-run" ] && warn "DRY RUN — no installation will occur"
  echo ""

  # ── Step 1: Node.js ─────────────────────────────────────────────────────
  info "Step 1/3  Node.js (required for Railway CLI)"
  if command -v node &>/dev/null; then
    ok "Node.js $(node --version)"
  else
    err "Node.js not found. Install from: https://nodejs.org"
    exit 1
  fi
  echo ""

  # ── Step 2: Railway CLI ─────────────────────────────────────────────────
  info "Step 2/3  Railway CLI"
  if command -v railway &>/dev/null; then
    ok "Railway CLI installed ($(railway --version 2>/dev/null || echo 'unknown'))"
  else
    if [ "$dry_run" = "--dry-run" ]; then
      warn "Would install: npm install -g @railway/cli"
    else
      warn "Installing Railway CLI..."
      if npm install -g @railway/cli; then
        ok "Railway CLI installed"
      else
        err "Installation failed"
        exit 1
      fi
    fi
  fi

  if [ "$dry_run" != "--dry-run" ]; then
    if railway whoami &>/dev/null 2>&1; then
      ok "Already authenticated ($(railway whoami 2>/dev/null | head -1 || echo 'logged in'))"
    else
      info "Opening browser for Railway login..."
      railway login
      ok "Authentication complete"
    fi
  fi
  echo ""

  # ── Step 3: gh CLI (for GitHub integration) ─────────────────────────────
  info "Step 3/3  GitHub CLI (gh)"
  if command -v gh &>/dev/null; then
    ok "gh installed ($(gh --version | head -1))"
    if gh auth status &>/dev/null 2>&1; then
      ok "gh authenticated"
    else
      if [ "$dry_run" != "--dry-run" ]; then
        warn "gh not authenticated. Run: gh auth login"
      fi
    fi
  else
    warn "gh CLI not installed — optional but needed for secrets setup"
    info "Install: https://cli.github.com"
  fi
  echo ""

  ok "Setup complete."
  echo ""
  info "Next steps:"
  info "  bash spells/railway-ctl.sh init server    # link to Railway project"
  info "  bash spells/railway-ctl.sh deploy server  # deploy sCoRE"
  echo ""
}

cmd_init() {
  local service="${1:-server}"
  local dry_run="${2:-}"

  header "Initialize Railway Project"

  if ! command -v railway &>/dev/null; then
    err "railway CLI not installed"
    suggest_setup; exit 1
  fi
  if ! railway whoami &>/dev/null 2>&1; then
    err "railway not authenticated"
    suggest_setup; exit 1
  fi

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

  if ! command -v railway &>/dev/null; then
    err "railway CLI not installed"
    suggest_setup; exit 1
  fi
  if ! railway whoami &>/dev/null 2>&1; then
    err "railway not authenticated"
    suggest_setup; exit 1
  fi

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
      sleep 2
      URL=$(railway open --external --silent 2>/dev/null || echo "https://railway.app")
      info "Service URL: $URL"
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
