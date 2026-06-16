#!/usr/bin/env bash
# =============================================================================
# spells/chat-local.sh — talk to RaBbLE locally against the LIVE Render sCoRE.
#
# Runs two local processes and prints one URL:
#   1. static server (:8080) — serves the World chat UI + Aether/NeBuLA bundles
#   2. chat-bridge.py (:8000) — proxies /api/* to Render, injects @demo auth,
#      adds CORS, and writes every chat turn to disk (sCoRE/chats by default)
#
# RaBbLE-config.js auto-targets localhost:8000 for the API, so the app talks to
# the bridge with no edits. Open the printed dev-login URL, then chat — every
# exchange is saved to disk for logging and review.
#
# Usage:
#   bash spells/chat-local.sh                 # serve + bridge, Ctrl-C to stop
#   CHAT_LOG_DIR=~/logs bash spells/chat-local.sh   # custom transcript dir
#
# spark ~ grimoire >> local chat against Render + on-disk transcripts // %LLM_CTL%
# =============================================================================
set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; MAGENTA='\033[0;35m'; RESET='\033[0m'
ok()     { echo -e "  ${GREEN}✓${RESET}  $*"; }
info()   { echo -e "  ${CYAN}·${RESET}  $*"; }
warn()   { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()    { echo -e "  ${RED}✗${RESET}  $*" >&2; }
header() { echo -e "\n${MAGENTA}$*${RESET}\n"; }

SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"
WORLD="$ROOT/RaBbLE-World"
AETHER_CSS="$ROOT/RaBbLE-Aether/dist/aether.css"
NEBULA_JS="$ROOT/RaBbLE-NeBuLA/dist/nebula.iife.js"
DEMO_ACCOUNT="$GRIMOIRE_ROOT/.render/demo_account.json"

WEB_PORT="${WEB_PORT:-8080}"
BRIDGE_PORT="${BRIDGE_PORT:-8000}"
RENDER_URL="${RENDER_URL:-https://rabble-score-x7qq.onrender.com}"
CHAT_LOG_DIR="${CHAT_LOG_DIR:-$ROOT/RaBbLE-sCoRE/chats}"

header "RaBbLE — Local Chat (live Render backend)"

# ─ Preconditions ─────────────────────────────────────────────────────────────
[ -d "$WORLD/world" ]      || { err "World not found at $WORLD"; exit 1; }
[ -f "$AETHER_CSS" ]       || { err "Aether bundle missing: $AETHER_CSS (build Aether)"; exit 1; }
[ -f "$NEBULA_JS" ]        || { err "NeBuLA bundle missing: $NEBULA_JS (build NeBuLA)"; exit 1; }
[ -f "$DEMO_ACCOUNT" ]     || warn "No demo account at $DEMO_ACCOUNT — bridge will pass auth through (gate may 401)."

# ─ Build an ephemeral web root (symlinks: World + versioned bundles) ──────────
WEBROOT="$(mktemp -d /tmp/rabble-chat-webroot.XXXX)"
mkdir -p "$WEBROOT/aether/v0.0.0.0" "$WEBROOT/nebula/v0.0.0.0"
ln -s "$WORLD/world"        "$WEBROOT/world"
ln -s "$WORLD/index.html"   "$WEBROOT/index.html"   2>/dev/null || true
ln -s "$WORLD/manifest.json" "$WEBROOT/manifest.json" 2>/dev/null || true
ln -s "$WORLD/icons"        "$WEBROOT/icons"         2>/dev/null || true
ln -s "$AETHER_CSS"         "$WEBROOT/aether/v0.0.0.0/aether.css"
ln -s "$NEBULA_JS"          "$WEBROOT/nebula/v0.0.0.0/nebula.iife.js"

# dev-login.html — seeds a placeholder gate token (bridge supplies real @demo auth)
cat > "$WEBROOT/dev-login.html" <<'HTML'
<!doctype html><meta charset="utf-8"><title>RaBbLE — dev login</title>
<body style="background:#0a0a14;color:#888;font-family:monospace;padding:2rem">
Seeding local dev session…
<script>
  localStorage.setItem('rabble_jwt', 'dev-local');   // any non-empty value passes the client gate
  localStorage.setItem('rabble_handle', 'demo');     // real @demo auth is injected by the bridge
  location.replace('world/RaBbLE-Chat.html');
</script>
HTML

PIDS=()
cleanup() {
  echo; info "stopping…"
  for p in "${PIDS[@]:-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null || true; done
  rm -rf "$WEBROOT"
}
trap cleanup INT TERM EXIT

# ─ Start static server + bridge ──────────────────────────────────────────────
python3 -m http.server "$WEB_PORT" --directory "$WEBROOT" >/dev/null 2>&1 &
PIDS+=($!)
DEMO_ACCOUNT="$DEMO_ACCOUNT" CHAT_LOG_DIR="$CHAT_LOG_DIR" BRIDGE_PORT="$BRIDGE_PORT" RENDER_URL="$RENDER_URL" \
  python3 "$SPELL_DIR/chat-bridge.py" &
PIDS+=($!)

sleep 2
ok "web   → http://localhost:$WEB_PORT"
ok "bridge→ http://localhost:$BRIDGE_PORT  (→ $RENDER_URL)"
ok "logs  → $CHAT_LOG_DIR"
echo
header "Open this to start chatting:"
echo -e "    ${GREEN}http://localhost:$WEB_PORT/dev-login.html${RESET}\n"
info "Talk to RaBbLE; every turn is saved to $CHAT_LOG_DIR/<session>.md (+ .jsonl)."
info "Ctrl-C to stop."
wait
