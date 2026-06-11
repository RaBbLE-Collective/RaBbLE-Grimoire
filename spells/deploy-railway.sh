#!/usr/bin/env bash
# =============================================================================
# spells/deploy-railway.sh — Railway Deployment CLI
#
# Manages RaBbLE deployment on Railway via CLI.
# Wraps and simplifies RaBbLE-sCoRE/harness/railway_ctl.sh
# No dashboard interaction — pure CLI automation.
#
# Usage:
#   bash spells/deploy-railway.sh [--dry-run] <cmd> [args]
#
# Commands:
#   setup                  # install + authenticate Railway
#   init-project           # create new Railway project
#   deploy <service>       # deploy service (default: server)
#   status <service>       # health check
#   logs <service>         # tail live logs
#   env-show <service>     # display environment variables
#   env-set <service>      # set env vars interactively
#   open                   # open Railway dashboard
#
# Flags:
#   --dry-run              # show what would happen without making changes
#
# Services:
#   - server    RaBbLE-sCoRE FastAPI server
#   - world     RaBbLE-World Cloudflare Worker (separate)
#
# Prerequisites:
#   - railway-cli: npm install -g @railway/cli
#   - Railway account at https://railway.app
#   - RaBbLE-sCoRE with server/ configured
#
# spark ~ railway >> sCoRE deployment, CLI-only automation // %EP1_RAILWAY_DEPLOY%
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
RAILWAY_CTL="$SCORE_ROOT/harness/railway_ctl.sh"

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

verify_score() {
  if [ ! -f "$RAILWAY_CTL" ]; then
    err "RaBbLE-sCoRE not found or railway_ctl.sh missing"
    exit 1
  fi
}

# ─ Commands ──────────────────────────────────────────────────────────────────

cmd_setup() {
  header "╔════════════════════════════════════════════════════════╗"
  header "║  Railway Setup — RaBbLE Deployment                      ║"
  header "╚════════════════════════════════════════════════════════╝"

  [ "$DRY_RUN" = "true" ] && warn "DRY RUN — no installation will be performed"

  verify_score

  info "Step 1: Install Railway CLI"
  if [ "$DRY_RUN" = "true" ]; then
    warn "Would check/install: npm install -g @railway/cli"
  else
    if command -v railway &>/dev/null; then
      RAILWAY_VERSION=$(railway --version 2>/dev/null || echo "unknown")
      ok "Railway CLI already installed ($RAILWAY_VERSION)"
    else
      warn "Installing Railway CLI..."
      npm install -g @railway/cli
      ok "Railway CLI installed"
    fi
  fi

  info ""
  info "Step 2: Railway Authentication"
  if [ "$DRY_RUN" = "true" ]; then
    warn "Would verify authentication via: railway whoami"
    warn "Would prompt: railway login"
  else
    if railway whoami &>/dev/null; then
      ok "Already authenticated"
    else
      warn "Authenticate with Railway..."
      railway login
      ok "Authentication complete"
    fi
  fi

  header "✓ Setup $([ "$DRY_RUN" = "true" ] && echo "Plan" || echo "Complete")"
  info "Next: bash spells/deploy-railway.sh init-project"
  echo ""
}

cmd_init_project() {
  header "╔════════════════════════════════════════════════════════╗"
  header "║  Create Railway Project                                 ║"
  header "╚════════════════════════════════════════════════════════╝"

  [ "$DRY_RUN" = "true" ] && warn "DRY RUN — no project will be created"

  verify_score

  if [ "$DRY_RUN" = "true" ]; then
    warn "Would check/execute: railway init"
  else
    if railway status &>/dev/null 2>&1; then
      ok "Railway project already initialized"
      railway status || true
    else
      info "Creating new Railway project..."
      railway init
      ok "Project created"
    fi
  fi

  echo ""
}

cmd_deploy() {
  local service="${1:-server}"

  header "╔════════════════════════════════════════════════════════╗"
  header "║  Deploy to Railway — $service                            ║"
  header "╚════════════════════════════════════════════════════════╝"

  [ "$DRY_RUN" = "true" ] && warn "DRY RUN — no deployment will be triggered"

  verify_score

  if [ ! -d "$SCORE_ROOT/$service" ]; then
    err "Service not found: $service"
    exit 1
  fi

  if [ "$DRY_RUN" = "true" ]; then
    warn "Would execute: railway up --detach (from $SCORE_ROOT/$service/)"
    info "Dry run complete — no deployment triggered"
  else
    info "Deploying $service..."
    cd "$SCORE_ROOT/$service"

    # Use railway up to deploy
    if railway up --detach; then
      ok "Deployment triggered"

      # Get public URL
      if command -v railway &>/dev/null; then
        sleep 2
        URL=$(railway open --external --silent 2>/dev/null || echo "https://railway.app/dashboard")
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

  verify_score

  info "Service status: $service"

  cd "$SCORE_ROOT/$service"

  if railway status 2>/dev/null; then
    ok "Service is healthy"

    # Try health endpoint
    URL=$(railway open --external --silent 2>/dev/null || echo "")
    if [ -n "$URL" ]; then
      if curl -s "$URL/health" | grep -q "ok"; then
        ok "Health endpoint: HEALTHY"
      else
        warn "Health endpoint: no response or error"
      fi
    fi
  else
    warn "Could not reach service"
  fi

  echo ""
}

cmd_logs() {
  local service="${1:-server}"

  verify_score

  info "Tailing logs for $service..."
  cd "$SCORE_ROOT/$service"
  railway logs -f 2>&1 || true

  echo ""
}

cmd_env_show() {
  local service="${1:-server}"

  verify_score

  info "Environment variables for $service:"
  cd "$SCORE_ROOT/$service"
  railway variables 2>&1 || true

  echo ""
}

cmd_env_set() {
  local service="${1:-server}"

  verify_score

  info "Set environment variables for $service"
  cd "$SCORE_ROOT/$service"

  read -rp "  Variable name: " var_name
  read -rsp "  Variable value: " var_value
  echo ""

  railway variables set "$var_name" "$var_value" || true

  ok "Variable set"
  echo ""
}

cmd_open() {
  verify_score

  info "Opening Railway dashboard..."
  if command -v xdg-open &>/dev/null; then
    xdg-open "https://railway.app/dashboard"
  elif command -v open &>/dev/null; then
    open "https://railway.app/dashboard"
  else
    info "https://railway.app/dashboard"
  fi

  echo ""
}

# ─ Main ──────────────────────────────────────────────────────────────────────

COMMAND="${1:-help}"

case "$COMMAND" in
  setup)         cmd_setup ;;
  init-project)  cmd_init_project ;;
  deploy)        cmd_deploy "${2:-server}" ;;
  status)        cmd_status "${2:-server}" ;;
  logs)          cmd_logs "${2:-server}" ;;
  env-show)      cmd_env_show "${2:-server}" ;;
  env-set)       cmd_env_set "${2:-server}" ;;
  open)          cmd_open ;;
  help|--help|-h)
    sed -n '/^# Usage:/,/^# spark/p' "$0" | sed 's/^# \?//'
    ;;
  *)
    err "Unknown command: $COMMAND"
    echo "  Usage: deploy-railway.sh [setup|init-project|deploy|status|logs|env-show|env-set|open]"
    exit 1
    ;;
esac
