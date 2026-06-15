#!/usr/bin/env bash
# =============================================================================
# spells/render-ctl.sh — Unified Render Control (sCoRE Deployment)
#
# THE canonical Render spell. Supersedes the old `deploy-render.sh` (which
# stubbed env-set/logs to "use the dashboard"). Mirrors `railway-ctl.sh` so the
# active backend (Render) and the dormant one (Railway) share one shape.
#
# Manages RaBbLE-sCoRE on Render via the REST API (api.render.com/v1) — env
# vars, deploys, status, and logs are all real CLI operations. The ONLY manual
# bootstrap is minting a Render API key once (and connecting GitHub to Render
# the first time you create the service via Blueprint).
#
# Usage:
#   bash spells/render-ctl.sh <command> [args] [--dry-run]
#
# Commands:
#   setup                  Save API key (or read $RENDER_API_KEY), verify auth,
#                          cache owner id, auto-link service by name
#   link                   Find the service by name and cache its id
#   preflight              Validate render.yaml against free-tier constraints
#   deploy [--wait]        Trigger a deploy (optionally poll until live/failed)
#   status                 Service status, tracked branch, URL, /health probe
#   logs [N]               Recent service logs (default 100; falls back to deep link)
#   env-show               List env vars (values masked)
#   env-set <key> <val>    Upsert a single env var (auto-redeploys)
#   env-sync               Push provider keys from sCoRE/server/.env to Render
#   open                   Open the Render dashboard for the service
#   help                   Show this help
#
# Config (env overrides):
#   RENDER_API_KEY         API key (else read from .render/api_key)
#   RENDER_SERVICE_NAME    Service name (default: rabble-score)
#
# Examples:
#   bash spells/render-ctl.sh setup
#   bash spells/render-ctl.sh env-sync
#   bash spells/render-ctl.sh deploy --wait
#   bash spells/render-ctl.sh logs 200
#
# Flags:
#   --dry-run              Preview without making changes
#
# spark ~ render >> unified sCoRE deployment control, keys via CLI // %RENDER_CTL%
# =============================================================================

set -euo pipefail

# ─ Colors ────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'
YELLOW='\033[1;33m'; MAGENTA='\033[0;35m'; RESET='\033[0m'
ok()     { echo -e "  ${GREEN}✓${RESET}  $*"; }
info()   { echo -e "  ${CYAN}·${RESET}  $*"; }
warn()   { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()    { echo -e "  ${RED}✗${RESET}  $*" >&2; }
header() { echo -e "\n${MAGENTA}$*${RESET}\n"; }

# ─ Paths ─────────────────────────────────────────────────────────────────────
SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
COLLECTIVE_ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"
SCORE_ROOT="$COLLECTIVE_ROOT/RaBbLE-sCoRE"
RENDER_DIR="$GRIMOIRE_ROOT/.render"
API_KEY_FILE="$RENDER_DIR/api_key"
SERVICE_ID_FILE="$RENDER_DIR/service_id"
OWNER_ID_FILE="$RENDER_DIR/owner_id"

RENDER_SERVICE_NAME="${RENDER_SERVICE_NAME:-RaBbLE-sCoRE}"
API="https://api.render.com/v1"

# ─ Flags ─────────────────────────────────────────────────────────────────────
DRY_RUN=false
ARGS=()
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=true ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- "${ARGS[@]:-}"

# ─ Prereqs ───────────────────────────────────────────────────────────────────
need() { command -v "$1" &>/dev/null || { err "$1 not found ($2)"; exit 1; }; }
need curl "install curl"
need jq   "install jq"

# ─ Auth helpers ──────────────────────────────────────────────────────────────
api_key() {
  if [ -n "${RENDER_API_KEY:-}" ]; then echo "$RENDER_API_KEY"; return; fi
  if [ -f "$API_KEY_FILE" ]; then cat "$API_KEY_FILE"; return; fi
  err "No Render API key. Run: bash spells/render-ctl.sh setup"
  err "Mint one at: https://dashboard.render.com/account/api-keys"
  exit 1
}

# api <METHOD> <path> [json-body]
api() {
  local method="$1" path="$2" body="${3:-}"
  local key; key="$(api_key)"
  if [ -n "$body" ]; then
    curl -sS -X "$method" "$API$path" \
      -H "Authorization: Bearer $key" \
      -H "Content-Type: application/json" \
      -d "$body"
  else
    curl -sS -X "$method" "$API$path" \
      -H "Authorization: Bearer $key" \
      -H "Accept: application/json"
  fi
}

service_id() {
  if [ -f "$SERVICE_ID_FILE" ]; then cat "$SERVICE_ID_FILE"; return; fi
  err "Service id not cached. Run: bash spells/render-ctl.sh link"
  exit 1
}

resolve_service_id() {
  # Look the service up by name and cache its id. Echoes the id.
  local id
  id="$(api GET "/services?name=$RENDER_SERVICE_NAME&limit=20" \
    | jq -r --arg n "$RENDER_SERVICE_NAME" '.[].service | select(.name==$n) | .id' | head -1)"
  if [ -z "$id" ] || [ "$id" = "null" ]; then
    return 1
  fi
  mkdir -p "$RENDER_DIR"; echo "$id" > "$SERVICE_ID_FILE"
  echo "$id"
}

verify_score_repo() {
  [ -d "$SCORE_ROOT" ]            || { err "RaBbLE-sCoRE not found at $SCORE_ROOT"; exit 1; }
  [ -f "$SCORE_ROOT/render.yaml" ] || { err "render.yaml not found in $SCORE_ROOT"; exit 1; }
}

# ─ Commands ──────────────────────────────────────────────────────────────────

cmd_setup() {
  header "Render Setup — $RENDER_SERVICE_NAME"
  verify_score_repo
  [ "$DRY_RUN" = true ] && { warn "DRY RUN — no changes"; return; }

  mkdir -p "$RENDER_DIR"; chmod 700 "$RENDER_DIR"
  if [ ! -f "$API_KEY_FILE" ] && [ -z "${RENDER_API_KEY:-}" ]; then
    info "Mint a key at: https://dashboard.render.com/account/api-keys"
    read -rsp "  Paste your Render API key: " k; echo ""
    [ -n "$k" ] && { echo "$k" > "$API_KEY_FILE"; chmod 600 "$API_KEY_FILE"; ok "API key saved (chmod 600)"; }
  else
    ok "API key present"
  fi

  info "Verifying authentication ..."
  local owner
  owner="$(api GET "/owners?limit=1" | jq -r '.[0].owner.id // empty')"
  [ -n "$owner" ] || { err "Auth failed — check the API key"; exit 1; }
  echo "$owner" > "$OWNER_ID_FILE"
  ok "Authenticated (owner $owner)"

  info "Linking service '$RENDER_SERVICE_NAME' ..."
  if id="$(resolve_service_id)"; then
    ok "Linked existing service: $id"
  else
    warn "No service named '$RENDER_SERVICE_NAME' yet."
    info "Create it once via Blueprint: Dashboard → New → Blueprint → connect"
    info "  RaBbLE-Collective/RaBbLE-sCoRE → branch new-horizons (reads render.yaml)."
    info "Then re-run: bash spells/render-ctl.sh link"
    warn "Run 'preflight' first — render.yaml has a free-tier disk conflict."
  fi
  echo ""
}

cmd_link() {
  header "Link Service — $RENDER_SERVICE_NAME"
  if id="$(resolve_service_id)"; then ok "Linked: $id"; else
    err "No service named '$RENDER_SERVICE_NAME'. Create via Blueprint first."; exit 1; fi
  echo ""
}

cmd_preflight() {
  header "Preflight — render.yaml"
  verify_score_repo
  local yaml="$SCORE_ROOT/render.yaml"
  local issues=0

  if grep -qE '^\s*plan:\s*free' "$yaml" && grep -qE '^\s*disk:' "$yaml"; then
    err "FREE-TIER DISK CONFLICT: render.yaml has 'plan: free' AND a 'disk:' block."
    info "Render free instances do NOT support persistent disks — Blueprint will fail."
    info "Fix: remove the disk block (use ephemeral storage) OR move off free plan."
    info "DATA_DIR can point at a writable ephemeral path (e.g. /tmp/rabble-data) on free."
    issues=$((issues+1))
  else
    ok "No free-tier disk conflict"
  fi

  if grep -qE '^\s*-\s*key:\s*(GROQ_API_KEY|OPENROUTER_API_KEY|RABBLE_ADMIN_KEY)' "$yaml"; then
    ok "Secret env vars declared (sync:false) — populate via env-sync / env-set"
  else
    warn "No provider-key env vars declared in render.yaml"
  fi

  if ! grep -qE '^\s*healthCheckPath:\s*/health' "$yaml"; then
    warn "healthCheckPath is not /health — status probe may differ"
  else
    ok "healthCheckPath: /health"
  fi

  echo ""
  [ "$issues" -eq 0 ] && ok "Preflight clean" || err "$issues blocking issue(s) — fix before deploy"
  echo ""
  return 0
}

cmd_deploy() {
  header "Deploy — $RENDER_SERVICE_NAME"
  local wait=false; [ "${1:-}" = "--wait" ] && wait=true
  local id; id="$(service_id)"
  info "Service: $id"

  if [ "$DRY_RUN" = true ]; then
    warn "Would POST /services/$id/deploys"; echo ""; return
  fi

  local res dep
  res="$(api POST "/services/$id/deploys" '{"clearCache":"do_not_clear"}')"
  dep="$(echo "$res" | jq -r '.id // empty')"
  [ -n "$dep" ] || { err "Deploy not triggered"; echo "$res" | jq . 2>/dev/null || echo "$res"; exit 1; }
  ok "Deploy triggered: $dep"

  if [ "$wait" = true ]; then
    info "Polling until live (Ctrl-C to stop) ..."
    local st
    while :; do
      st="$(api GET "/services/$id/deploys/$dep" | jq -r '.status // "unknown"')"
      case "$st" in
        live)                                 ok "Deploy live"; break ;;
        build_failed|update_failed|canceled|pre_deploy_failed)
                                              err "Deploy ended: $st"; exit 1 ;;
        *)                                    info "  status: $st"; sleep 8 ;;
      esac
    done
  else
    info "Track: https://dashboard.render.com/web/$id/deploys/$dep"
  fi
  echo ""
}

cmd_status() {
  header "Status — $RENDER_SERVICE_NAME"
  local id; id="$(service_id)"
  local svc; svc="$(api GET "/services/$id")"
  echo "$svc" | jq -r '
    "  name:      \(.name)",
    "  branch:    \(.branch)",
    "  autoDeploy:\(.autoDeploy)",
    "  suspended: \(.suspended)",
    "  url:       \(.serviceDetails.url // "n/a")"'
  local url; url="$(echo "$svc" | jq -r '.serviceDetails.url // empty')"
  if [ -n "$url" ]; then
    info "Probing $url/health ..."
    if curl -sf --max-time 60 "$url/health" | grep -q '"status":"ok"'; then
      ok "Health: OK"
    else
      warn "Health: no healthy response (free tier may be cold — retry in ~60s)"
    fi
  fi
  echo ""
}

cmd_logs() {
  header "Logs — $RENDER_SERVICE_NAME"
  local id; id="$(service_id)"
  local n="${1:-100}"
  local owner; owner="$(cat "$OWNER_ID_FILE" 2>/dev/null || echo "")"
  if [ -z "$owner" ]; then
    warn "Owner id not cached (run setup). Opening dashboard logs instead."
    info "https://dashboard.render.com/web/$id/logs"; echo ""; return
  fi
  local res
  res="$(api GET "/logs?ownerId=$owner&resource=$id&limit=$n&direction=backward")"
  if echo "$res" | jq -e '.logs' &>/dev/null; then
    echo "$res" | jq -r '.logs[] | "  \(.timestamp)  \(.message)"'
  else
    warn "Logs API returned no stream (may need a paid plan / time window)."
    info "Dashboard: https://dashboard.render.com/web/$id/logs"
  fi
  echo ""
}

cmd_env_show() {
  header "Env Vars — $RENDER_SERVICE_NAME"
  local id; id="$(service_id)"
  api GET "/services/$id/env-vars?limit=100" \
    | jq -r '.[].envVar | "  \(.key) = \((.value // "") | if length>6 then .[0:6]+"…(masked)" else "(set)" end)"'
  echo ""
}

cmd_env_set() {
  local key="${1:-}" val="${2:-}"
  [ -n "$key" ] && [ -n "$val" ] || { err "Usage: env-set <KEY> <VALUE>"; exit 1; }
  header "Set Env Var — $key"
  local id; id="$(service_id)"
  if [ "$DRY_RUN" = true ]; then warn "Would PUT /services/$id/env-vars/$key"; echo ""; return; fi
  local res
  res="$(api PUT "/services/$id/env-vars/$key" "$(jq -nc --arg v "$val" '{value:$v}')")"
  if echo "$res" | jq -e '.key' &>/dev/null; then
    ok "$key set (Render will redeploy)"
  else
    err "Failed to set $key"; echo "$res" | jq . 2>/dev/null || echo "$res"; exit 1
  fi
  echo ""
}

cmd_env_sync() {
  header "Env Sync — provider keys from sCoRE/server/.env"
  local envf="$SCORE_ROOT/server/.env"
  [ -f "$envf" ] || { err ".env not found at $envf"; exit 1; }
  local id; id="$(service_id)"
  local synced=0
  for k in OPENROUTER_API_KEY GROQ_API_KEY RABBLE_ADMIN_KEY; do
    # match an UNcommented assignment only
    local line; line="$(grep -E "^\s*$k=" "$envf" | head -1 || true)"
    [ -z "$line" ] && { info "$k — absent/commented, skipping"; continue; }
    local v="${line#*=}"
    v="${v%%#*}"; v="$(echo "$v" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^"//; s/"$//')"
    [ -z "$v" ] && { info "$k — empty, skipping"; continue; }
    if [ "$DRY_RUN" = true ]; then
      warn "Would set $k (${v:0:6}…)"; continue
    fi
    if api PUT "/services/$id/env-vars/$k" "$(jq -nc --arg val "$v" '{value:$val}')" | jq -e '.key' &>/dev/null; then
      ok "$k synced (${v:0:6}…)"; synced=$((synced+1))
    else
      err "$k failed to sync"
    fi
  done
  [ "$DRY_RUN" = true ] || ok "$synced key(s) synced — Render will redeploy"
  echo ""
}

cmd_open() {
  local id; id="$(cat "$SERVICE_ID_FILE" 2>/dev/null || echo "")"
  local target="https://dashboard.render.com"
  [ -n "$id" ] && target="https://dashboard.render.com/web/$id"
  info "Opening $target"
  if command -v xdg-open &>/dev/null; then xdg-open "$target" &
  elif command -v open &>/dev/null; then open "$target"
  else info "$target"; fi
  echo ""
}

cmd_help() { sed -n '/^# Usage:/,/^# spark/p' "$0" | sed 's/^# \?//'; }

# ─ Main ──────────────────────────────────────────────────────────────────────
CMD="${1:-help}"; shift || true
case "$CMD" in
  setup)     cmd_setup ;;
  link)      cmd_link ;;
  preflight) cmd_preflight ;;
  deploy)    cmd_deploy "${1:-}" ;;
  status)    cmd_status ;;
  logs)      cmd_logs "${1:-}" ;;
  env-show)  cmd_env_show ;;
  env-set)   cmd_env_set "${1:-}" "${2:-}" ;;
  env-sync)  cmd_env_sync ;;
  open)      cmd_open ;;
  help|--help|-h) cmd_help ;;
  *) err "Unknown command: $CMD"; echo "  Run: bash spells/render-ctl.sh help"; exit 1 ;;
esac
