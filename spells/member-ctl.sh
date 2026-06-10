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

suggest_setup() {
  echo ""
  info "Run: bash spells/$(basename "$0") setup <member>"
}

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
  GITHUB_ORG="${GITHUB_ORG:-RaBbLE-Collective}"

  header "Setup $MEMBER_REPO for Deployment"

  if [ ! -d "$MEMBER_ROOT" ]; then
    err "Member repo not found: $MEMBER_ROOT"
    exit 1
  fi

  ok "Member: $MEMBER_REPO at $MEMBER_ROOT"
  echo ""

  # ── Step 1: Node.js ──────────────────────────────────────────────────────
  info "Step 1/4  Node.js"
  if command -v node &>/dev/null; then
    ok "Node.js $(node --version)"
  else
    err "Node.js not found — install from: https://nodejs.org"
    exit 1
  fi
  echo ""

  # ── Step 2: gh CLI ───────────────────────────────────────────────────────
  info "Step 2/4  GitHub CLI (gh)"
  if command -v gh &>/dev/null; then
    ok "gh installed ($(gh --version | head -1))"
    if gh auth status &>/dev/null 2>&1; then
      ok "gh authenticated"
    else
      if [ "$dry_run" != "--dry-run" ]; then
        warn "gh not authenticated. Opening login..."
        gh auth login
      else
        warn "gh not authenticated — run: gh auth login"
      fi
    fi
  else
    err "gh CLI not installed — https://cli.github.com"
    exit 1
  fi
  echo ""

  # ── Step 3: Cloudflare credentials check ────────────────────────────────
  info "Step 3/4  Cloudflare credentials"
  local cf_ok=true
  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    ok "CLOUDFLARE_API_TOKEN set"
  else
    warn "CLOUDFLARE_API_TOKEN not set"
    cf_ok=false
  fi
  if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
    ok "CLOUDFLARE_ACCOUNT_ID set"
  else
    warn "CLOUDFLARE_ACCOUNT_ID not set"
    cf_ok=false
  fi
  if [ "$cf_ok" = "false" ]; then
    info "Run cloudflare setup first: bash spells/cloudflare-ctl.sh setup"
  fi
  echo ""

  # ── Step 4: Workflow + secrets ───────────────────────────────────────────
  info "Step 4/4  GitHub Actions workflow + secrets"

  if [ "$dry_run" != "--dry-run" ]; then
    bash "$SPELL_DIR/create-member-workflow.sh" "$member" || {
      warn "Could not create workflow — check create-member-workflow.sh"
    }
    bash "$SPELL_DIR/cloudflare-ctl.sh" secrets-setup "$member" || {
      warn "Could not auto-configure secrets"
      info "Set manually at: https://github.com/$GITHUB_ORG/$MEMBER_REPO/settings/secrets/actions"
    }
  else
    warn "DRY RUN — would create workflow and push GitHub secrets"
  fi
  echo ""

  ok "Setup complete"
  echo ""
  info "Next steps:"
  info "  bash spells/cloudflare-ctl.sh r2-setup          # ensure R2 bucket exists (once)"
  info "  bash spells/cloudflare-ctl.sh r2-domain add     # attach CDN domain (once)"
  info "  bash spells/member-ctl.sh publish $member v0.0.0.1"
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

  # Guard: GitHub workflow must exist
  if [ ! -f ".github/workflows/deploy.yml" ]; then
    err "GitHub Actions workflow not found — run setup first"
    suggest_setup; exit 1
  fi

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
