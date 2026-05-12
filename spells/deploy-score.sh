#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# spells/deploy-score.sh — cast the sCoRE server to Railway
#
# Wraps RaBbLE-sCoRE/harness/ with Grimoire-level awareness.
#
# Usage:
#   bash spells/deploy-score.sh              # interactive deploy TUI
#   bash spells/deploy-score.sh local        # start local server
#   bash spells/deploy-score.sh test         # run API test suite (local)
#   bash spells/deploy-score.sh test <URL>   # run API test suite against URL
#   bash spells/deploy-score.sh status       # Railway health check
#   bash spells/deploy-score.sh logs         # live Railway logs
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
COLLECTIVE_ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"
SCORE_ROOT="$COLLECTIVE_ROOT/RaBbLE-sCoRE"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; RESET='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "  ${GREEN}✓${RESET}  $*"; }
info() { echo -e "  ${CYAN}·${RESET}  $*"; }
err()  { echo -e "  ${RED}✗${RESET}  $*" >&2; }

_check_score() {
  if [ ! -d "$SCORE_ROOT" ]; then
    err "RaBbLE-sCoRE not found at $SCORE_ROOT"
    info "Run bootstrap.sh or clone the repo first."
    exit 1
  fi
}

_header() {
  echo
  echo -e "${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}  ║${RESET}  ${BOLD}RaBbLE-sCoRE${RESET}  ·  deploy spell                      ${CYAN}║${RESET}"
  echo -e "${CYAN}  ║${RESET}  version: v0.0.0.0  ·  episode 1 pending           ${CYAN}║${RESET}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
  echo
}

CMD="${1:-deploy}"
shift || true

case "$CMD" in

  deploy)
    _check_score
    _header
    info "Launching deploy TUI ..."
    exec bash "$SCORE_ROOT/harness/deploy.sh" "$@"
    ;;

  local)
    _check_score
    _header
    info "Starting local server (server/ on :8000) ..."
    exec bash "$SCORE_ROOT/harness/local.sh" "$@"
    ;;

  test)
    _check_score
    _header
    TARGET="${1:-http://localhost:8000}"
    info "Running API test suite against $TARGET ..."
    echo
    python3 "$SCORE_ROOT/server/api_test.py" "$TARGET"
    ;;

  status)
    _check_score
    bash "$SCORE_ROOT/harness/railway_ctl.sh" status server
    ;;

  logs)
    _check_score
    bash "$SCORE_ROOT/harness/railway_ctl.sh" logs server
    ;;

  help|--help|-h)
    sed -n '/^# Usage/,/^[^#]/p' "$0" | grep '^#' | sed 's/^# \?//'
    ;;

  *)
    err "Unknown command: $CMD"
    echo "  Usage: deploy-score.sh [deploy|local|test|status|logs]"
    exit 1
    ;;

esac
