#!/usr/bin/env bash
# fcc-ctl.sh — free-claude-code server management spell
#
# Usage:
#   fcc-ctl start          Start the server (systemd user service)
#   fcc-ctl stop           Stop the server
#   fcc-ctl restart        Restart the server
#   fcc-ctl status         Show service status
#   fcc-ctl logs           Tail live logs
#   fcc-ctl admin          Open Admin UI in browser
#   fcc-ctl update         Pull latest free-claude-code and restart
#   fcc-ctl keys           Print current key status (which keys are set)
#   fcc-ctl key <KEYNAME> <VALUE>   Set an API key in ~/.config/RaBbLE/fcc.env
#   fcc-ctl model haiku|sonnet|opus <provider:model>   Set model routing
#   fcc-ctl sync           Re-apply model routing from RaBbLE-OS/config/RaBbLE/fcc.env.example
#                          Edit the example to change providers, then run sync to apply.

set -euo pipefail

FCC_DIR="${HOME}/.local/share/RaBbLE/free-claude-code"
FCC_ENV="${HOME}/.config/RaBbLE/fcc.env"
FCC_URL="http://127.0.0.1:8082"
SERVICE="free-claude-code"
FCC_EXAMPLE="${HOME}/RaBbLE-Collective/RaBbLE-OS/config/RaBbLE/fcc.env.example"

# Keys that sync reads from the example (routing only — never API keys)
SYNC_KEYS=(MODEL_HAIKU MODEL_SONNET MODEL_OPUS ANTHROPIC_AUTH_TOKEN FCC_PORT FCC_HOST)

_require_service() {
  if ! systemctl --user is-active --quiet "${SERVICE}" 2>/dev/null; then
    echo "⚠  ${SERVICE} is not running. Start it with: fcc-ctl start" >&2
  fi
}

_env_get() {
  local key="$1"
  grep -E "^${key}=" "${FCC_ENV}" 2>/dev/null | cut -d= -f2- || true
}

_env_set() {
  local key="$1" val="$2"
  if grep -qE "^${key}=" "${FCC_ENV}" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${val}|" "${FCC_ENV}"
  else
    echo "${key}=${val}" >> "${FCC_ENV}"
  fi
  echo "✓ Set ${key}"
}

cmd="${1:-status}"
shift || true

case "${cmd}" in

  start)
    systemctl --user daemon-reload
    systemctl --user enable --now "${SERVICE}"
    echo "✓ ${SERVICE} started"
    ;;

  stop)
    systemctl --user stop "${SERVICE}"
    echo "✓ ${SERVICE} stopped"
    ;;

  restart)
    systemctl --user restart "${SERVICE}"
    echo "✓ ${SERVICE} restarted"
    ;;

  status)
    systemctl --user status "${SERVICE}" --no-pager || true
    echo ""
    if curl -sf "${FCC_URL}/health" >/dev/null 2>&1 || curl -sf "${FCC_URL}/" >/dev/null 2>&1; then
      echo "✓ API reachable at ${FCC_URL}"
      echo "  Admin UI: ${FCC_URL}/admin"
    else
      echo "✗ API not reachable at ${FCC_URL}"
    fi
    echo ""
    # ── Readiness: the proxy being up means nothing if the provider it routes to
    #    has no key. This is the #1 reason `claude-free` throws API errors —
    #    surface it here instead of leaving it to a cryptic 401 at runtime.
    echo "=== Routing readiness (will claude-free work?) ==="
    declare -A _prov_key=(
      [nvidia_nim]=NVIDIA_NIM_API_KEY [groq]=GROQ_API_KEY [cerebras]=CEREBRAS_API_KEY
      [deepseek]=DEEPSEEK_API_KEY [open_router]=OPENROUTER_API_KEY [gemini]=GEMINI_API_KEY
      [mistral]=MISTRAL_API_KEY [together]=TOGETHER_API_KEY [xai]=XAI_API_KEY [zhipu]=ZHIPU_API_KEY
    )
    _ready=1
    for tier in HAIKU SONNET OPUS; do
      route="$(_env_get "MODEL_${tier}")"
      [[ -z "${route}" ]] && continue
      prov="${route%%/*}"                      # provider = first path segment
      keyname="${_prov_key[$prov]:-}"
      if [[ -z "${keyname}" ]]; then
        echo "  ${tier} → ${prov}: ? unknown provider (no key mapping)"
        continue
      fi
      keyval="$(_env_get "${keyname}")"
      if [[ -n "${keyval}" && "${keyval}" != "fcc-no-auth" ]]; then
        echo "  ${tier} → ${prov}: ✓ ${keyname} set"
      else
        echo "  ${tier} → ${prov}: ✗ ${keyname} NOT set"
        _ready=0
      fi
    done
    echo ""
    if [[ ${_ready} -eq 1 ]]; then
      echo "✓ Ready — claude-free should work."
    else
      echo "⚠ Proxy is up but the routed provider(s) have no API key →"
      echo "  claude-free WILL get API errors. Set a key for the routed provider, e.g.:"
      echo "    fcc-ctl key GROQ_API_KEY <value>      # then: fcc-ctl status"
      echo "  Or switch routing to a provider you have a key for (edit ${FCC_EXAMPLE}; fcc-ctl sync)."
    fi
    ;;

  logs)
    journalctl --user -u "${SERVICE}" -f --no-pager
    ;;

  admin)
    xdg-open "${FCC_URL}/admin" 2>/dev/null || echo "Admin UI: ${FCC_URL}/admin"
    ;;

  update)
    echo "Pulling latest free-claude-code..."
    git -C "${FCC_DIR}" pull --ff-only
    echo "Syncing dependencies..."
    "${HOME}/.local/bin/uv" sync --project "${FCC_DIR}"
    systemctl --user restart "${SERVICE}"
    echo "✓ Updated and restarted"
    ;;

  keys)
    echo "=== free-claude-code API keys (${FCC_ENV}) ==="
    for key in GROQ_API_KEY CEREBRAS_API_KEY DEEPSEEK_API_KEY NVIDIA_NIM_API_KEY \
               GEMINI_API_KEY OPENROUTER_API_KEY MISTRAL_API_KEY TOGETHER_API_KEY \
               XAI_API_KEY ZHIPU_API_KEY ANTHROPIC_AUTH_TOKEN; do
      val="$(_env_get "${key}")"
      if [[ -n "${val}" && "${val}" != "fcc-no-auth" ]]; then
        # Show first 8 chars only
        echo "  ${key}: ${val:0:8}…"
      else
        echo "  ${key}: (not set)"
      fi
    done
    ;;

  key)
    [[ $# -lt 2 ]] && { echo "Usage: fcc-ctl key <KEYNAME> <VALUE>" >&2; exit 1; }
    _env_set "$1" "$2"
    systemctl --user restart "${SERVICE}" 2>/dev/null || true
    ;;

  model)
    [[ $# -lt 2 ]] && { echo "Usage: fcc-ctl model haiku|sonnet|opus <provider:model>" >&2; exit 1; }
    tier="${1^^}"   # uppercase
    model_val="$2"
    case "${tier}" in
      HAIKU)   _env_set "MODEL_HAIKU"  "${model_val}" ;;
      SONNET)  _env_set "MODEL_SONNET" "${model_val}" ;;
      OPUS)    _env_set "MODEL_OPUS"   "${model_val}" ;;
      *)       echo "Unknown tier: ${1}. Use haiku, sonnet, or opus." >&2; exit 1 ;;
    esac
    systemctl --user restart "${SERVICE}" 2>/dev/null || true
    echo "  Example: set ANTHROPIC_BASE_URL=http://127.0.0.1:8082 in Claude Code env"
    ;;

  sync)
    [[ ! -f "${FCC_EXAMPLE}" ]] && {
      echo "✗ Example not found: ${FCC_EXAMPLE}" >&2
      echo "  Expected: RaBbLE-OS/config/RaBbLE/fcc.env.example" >&2
      exit 1
    }
    echo "Syncing routing from $(basename "${FCC_EXAMPLE}")..."
    changed=0
    for key in "${SYNC_KEYS[@]}"; do
      val=""
      # Only pick up lines that are uncommented and non-empty values
      val=$(grep -E "^${key}=.+" "${FCC_EXAMPLE}" 2>/dev/null | cut -d= -f2- || true)
      if [[ -n "${val}" ]]; then
        current=""
        current=$(_env_get "${key}")
        if [[ "${current}" != "${val}" ]]; then
          _env_set "${key}" "${val}"
          changed=1
        fi
      fi
    done
    if [[ ${changed} -eq 1 ]]; then
      systemctl --user restart "${SERVICE}" 2>/dev/null || true
      echo "✓ Routing synced and service restarted"
    else
      echo "✓ Already up to date — no changes"
    fi
    echo ""
    echo "  Edit routing: ${FCC_EXAMPLE}"
    echo "  Re-apply:     fcc-ctl sync"
    echo "  Set keys:     fcc-ctl key NVIDIA_NIM_API_KEY <value>"
    ;;

  *)
    echo "Usage: fcc-ctl {start|stop|restart|status|logs|admin|update|keys|key|model|sync}" >&2
    exit 1
    ;;

esac
