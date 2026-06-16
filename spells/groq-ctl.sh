#!/usr/bin/env bash
# =============================================================================
# spells/groq-ctl.sh — Groq control (key, models, inference)
#
# Mirrors render-ctl.sh / openrouter-ctl.sh in shape. Reads the key from
# $GROQ_API_KEY, else from RaBbLE-sCoRE/server/.env. Never prints the key.
#
# Note: Groq blocks proton.me signups — the Collective's proton root identity
# can't easily hold a Groq account. The key in .env may be a personal account.
#
# Usage:
#   bash spells/groq-ctl.sh <command> [args]
#
# Commands:
#   key | auth           Verify the key (via /models); show model count
#   models [filter]      List model ids (optional substring filter)
#   test [model]         Quick completion smoke test (default: llama-3.1-8b-instant)
#   chat <model> <text>  Run one completion and print the reply
#   help
#
# Examples:
#   bash spells/groq-ctl.sh key
#   bash spells/groq-ctl.sh models llama
#   bash spells/groq-ctl.sh test
#   bash spells/groq-ctl.sh chat llama-3.3-70b-versatile "say hello"
#
# spark ~ grimoire >> provider control spell, keys via env/.env // %LLM_CTL%
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
COLLECTIVE_ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"
ENV_FILE="$COLLECTIVE_ROOT/RaBbLE-sCoRE/server/.env"
API="https://api.groq.com/openai/v1"
DEFAULT_MODEL="llama-3.1-8b-instant"

need() { command -v "$1" &>/dev/null || { err "$1 not found ($2)"; exit 1; }; }
need curl "install curl"; need jq "install jq"

gq_key() {
  if [ -n "${GROQ_API_KEY:-}" ]; then echo "$GROQ_API_KEY"; return; fi
  if [ -f "$ENV_FILE" ]; then
    local k; k="$(grep -E '^GROQ_API_KEY=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '"')"
    [ -n "$k" ] && { echo "$k"; return; }
  fi
  err "No GROQ_API_KEY in env or $ENV_FILE"; exit 1
}

# api <METHOD> <path> [json-body]
api() {
  local method="$1" path="$2" body="${3:-}" key; key="$(gq_key)"
  if [ -n "$body" ]; then
    curl -sS -m 60 -X "$method" "$API$path" -H "Authorization: Bearer $key" -H "Content-Type: application/json" -d "$body"
  else
    curl -sS -m 60 -X "$method" "$API$path" -H "Authorization: Bearer $key"
  fi
}

cmd_key() {
  header "Groq — Key Check"
  local res; res="$(api GET /models)"
  if echo "$res" | jq -e '.data' &>/dev/null; then
    ok "Key valid — $(echo "$res" | jq '.data | length') models available"
  else
    err "Key check failed:"; echo "$res" | jq -c '.error // .' 2>/dev/null || echo "$res"; exit 1
  fi
}

cmd_models() {
  header "Groq — Models${1:+ (filter: $1)}"
  local res; res="$(api GET /models)"
  echo "$res" | jq -r '.data[].id' \
    | { if [ -n "${1:-}" ]; then grep -i "$1" || true; else cat; fi; } | sort
  info "$(echo "$res" | jq '.data | length') models total"
}

cmd_test() {
  local model="${1:-$DEFAULT_MODEL}"
  header "Groq — Test: $model"
  local start res ms; start=$(date +%s%3N)
  res="$(api POST /chat/completions "$(jq -nc --arg m "$model" '{model:$m,messages:[{role:"user",content:"Reply with exactly: ok"}],max_tokens:5}')")"
  ms=$(( $(date +%s%3N) - start ))
  if echo "$res" | jq -e '.choices[0].message.content' &>/dev/null; then
    ok "200 — \"$(echo "$res" | jq -r '.choices[0].message.content')\" (${ms}ms)"
  else
    err "Failed (${ms}ms):"; echo "$res" | jq -c '.error // .' 2>/dev/null || echo "$res"; exit 1
  fi
}

cmd_chat() {
  local model="${1:-}"; shift || true; local prompt="$*"
  [ -n "$model" ] && [ -n "$prompt" ] || { err "Usage: chat <model> <prompt...>"; exit 1; }
  local res; res="$(api POST /chat/completions "$(jq -nc --arg m "$model" --arg p "$prompt" '{model:$m,messages:[{role:"user",content:$p}],max_tokens:512}')")"
  if echo "$res" | jq -e '.choices[0].message.content' &>/dev/null; then
    echo "$res" | jq -r '.choices[0].message.content'
  else
    err "Failed:"; echo "$res" | jq -c '.error // .'; exit 1
  fi
}

cmd_help() { sed -n '5,30p' "$0" | sed 's/^# \{0,1\}//'; }

CMD="${1:-help}"; shift || true
case "$CMD" in
  key|auth)        cmd_key ;;
  models)          cmd_models "${1:-}" ;;
  test)            cmd_test "${1:-}" ;;
  chat)            cmd_chat "$@" ;;
  help|--help|-h)  cmd_help ;;
  *) err "Unknown command: $CMD"; cmd_help; exit 1 ;;
esac
