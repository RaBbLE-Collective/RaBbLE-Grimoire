#!/usr/bin/env bash
# =============================================================================
# spells/member-ctl.sh — Unified Member Deployment Control
#
# Master controller for member repo deployment (Aether, NeBuLA, World, sCoRE).
# Orchestrates RC creation, publishing, and CDN deployment. Zero dashboard.
#
# Usage:
#   bash spells/member-ctl.sh <command> <member> [version] [options]
#
# Commands:
#   setup              # Configure member for deployment (workflow + secrets)
#   publish            # Publish RC and deploy to CDN
#   status             # Check deployment status
#   monitor            # Monitor CDN deployment progress
#   workflow           # Create/update GitHub Actions workflow
#   secrets            # Configure GitHub Actions secrets
#   help               # Show this help
#
# Members:
#   aether             RaBbLE-Aether (CSS design system)
#   nebula             RaBbLE-NeBuLA (rendering engine)
#   world              RaBbLE-World (entry point)
#   score              RaBbLE-sCoRE (coordination)
#
# Examples:
#   bash spells/member-ctl.sh setup aether              # Initial setup
#   bash spells/member-ctl.sh publish aether v0.0.0.1   # Publish RC
#   bash spells/member-ctl.sh monitor aether v0.0.0.1   # Monitor CDN
#   bash spells/member-ctl.sh status aether             # Check status
#
# Flags:
#   --dry-run          Preview without making changes
#
# Environment Variables:
#   CLOUDFLARE_API_TOKEN     Cloudflare API token
#   CLOUDFLARE_ACCOUNT_ID    Cloudflare account ID
#   GITHUB_TOKEN             GitHub API token (for gh CLI)
#
# spark ~ member >> unified member deployment control // %MEMBER_CTL%
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

# ─ Commands ──────────────────────────────────────────────────────────────────

cmd_setup() {
  local member="${1:-}"
  local dry_run="${2:-}"

  if [ -z "$member" ]; then
    warn "Usage: member-ctl.sh setup <member>"
    exit 1
  fi

  MEMBER_REPO="RaBbLE-$(echo "$member" | sed 's/^./\U&/')"
  MEMBER_ROOT="$COLLECTIVE_ROOT/$MEMBER_REPO"

  header "Setup $MEMBER_REPO for Deployment"

  if [ ! -d "$MEMBER_ROOT" ]; then
    err "Member repo not found: $MEMBER_ROOT"
    exit 1
  fi

  ok "Member: $MEMBER_REPO"

  # Step 1: Create workflow
  info "Creating GitHub Actions workflow..."
  bash "$SPELL_DIR/create-member-workflow.sh" "$member" || {
    if [ "$dry_run" != "--dry-run" ]; then
      exit 1
    fi
  }

  # Step 2: Set GitHub secrets
  info "Configuring GitHub Actions secrets..."
  bash "$SPELL_DIR/cloudflare-ctl.sh" secrets-setup "$member" || {
    warn "Could not auto-configure secrets"
    warn "Set manually at: https://github.com/markm1206/$MEMBER_REPO/settings/secrets/actions"
  }

  echo ""
  ok "Setup complete"
  info "Next: bash spells/member-ctl.sh publish $member v0.0.0.1"
  echo ""
}

cmd_publish() {
  local member="${1:-}"
  local version="${2:-}"
  local dry_run="${3:-}"

  if [ -z "$member" ] || [ -z "$version" ]; then
    warn "Usage: member-ctl.sh publish <member> <version> [--dry-run]"
    exit 1
  fi

  MEMBER_REPO="RaBbLE-$(echo "$member" | sed 's/^./\U&/')"
  MEMBER_ROOT="$COLLECTIVE_ROOT/$MEMBER_REPO"

  header "Publish RC — $MEMBER_REPO v$version"

  if [ ! -d "$MEMBER_ROOT" ]; then
    err "Member repo not found: $MEMBER_ROOT"
    exit 1
  fi

  [ "$dry_run" = "--dry-run" ] && warn "DRY RUN — no changes will be made"

  cd "$MEMBER_ROOT"

  # Run publish-rc.sh
  if [ "$dry_run" = "--dry-run" ]; then
    bash "$SPELL_DIR/publish-rc.sh" "v$version" --dry-run
  else
    bash "$SPELL_DIR/publish-rc.sh" "v$version"
  fi

  echo ""
}

cmd_workflow() {
  local member="${1:-}"

  if [ -z "$member" ]; then
    warn "Usage: member-ctl.sh workflow <member>"
    exit 1
  fi

  MEMBER_REPO="RaBbLE-$(echo "$member" | sed 's/^./\U&/')"

  header "Create GitHub Actions Workflow"

  bash "$SPELL_DIR/create-member-workflow.sh" "$member"

  echo ""
}

cmd_secrets() {
  local member="${1:-}"

  if [ -z "$member" ]; then
    warn "Usage: member-ctl.sh secrets <member>"
    exit 1
  fi

  header "Configure GitHub Actions Secrets"

  bash "$SPELL_DIR/cloudflare-ctl.sh" secrets-setup "$member"

  echo ""
}

cmd_status() {
  local member="${1:-}"

  if [ -z "$member" ]; then
    warn "Usage: member-ctl.sh status <member>"
    exit 1
  fi

  MEMBER_REPO="RaBbLE-$(echo "$member" | sed 's/^./\U&/')"
  MEMBER_ROOT="$COLLECTIVE_ROOT/$MEMBER_REPO"

  header "Deployment Status — $MEMBER_REPO"

  ok "Member: $MEMBER_REPO"

  # Check workflow
  if [ -f "$MEMBER_ROOT/.github/workflows/deploy.yml" ]; then
    ok "GitHub Actions workflow: ready"
  else
    warn "GitHub Actions workflow: not found"
  fi

  # Check git repo
  if [ -d "$MEMBER_ROOT/.git" ]; then
    ok "Git repo: ready"
    BRANCH=$(git -C "$MEMBER_ROOT" rev-parse --abbrev-ref HEAD)
    info "  Current branch: $BRANCH"
  else
    warn "Git repo: not initialized"
  fi

  echo ""
}

cmd_monitor() {
  local member="${1:-}"
  local version="${2:-v0.0.0.1-rc.1}"

  if [ -z "$member" ]; then
    warn "Usage: member-ctl.sh monitor <member> [version]"
    exit 1
  fi

  bash "$SPELL_DIR/cloudflare-ctl.sh" monitor "$member" "$version"

  echo ""
}

cmd_help() {
  sed -n '/^# Usage:/,/^# spark/p' "$0" | sed 's/^# \?//'
}

# ─ Main ──────────────────────────────────────────────────────────────────────

COMMAND="${1:-help}"

case "$COMMAND" in
  setup)      cmd_setup "${2:-}" "${3:-}" ;;
  publish)    cmd_publish "${2:-}" "${3:-}" "${4:-}" ;;
  workflow)   cmd_workflow "${2:-}" ;;
  secrets)    cmd_secrets "${2:-}" ;;
  status)     cmd_status "${2:-}" ;;
  monitor)    cmd_monitor "${2:-}" "${3:-}" ;;
  help|--help|-h)
    cmd_help ;;
  *)
    err "Unknown command: $COMMAND"
    echo "  Run: bash spells/member-ctl.sh help"
    exit 1
    ;;
esac
