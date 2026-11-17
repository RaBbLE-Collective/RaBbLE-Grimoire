#!/usr/bin/env bash
# =============================================================================
# spells/distill-hypr-docs.sh — Fetch Hyprland wiki pages and distill to
# a Grimoire markdown note using the LLM fast chain (Groq).
#
# Usage:
#   bash spells/distill-hypr-docs.sh <page> [output-file]
#   bash spells/distill-hypr-docs.sh window-rules
#   bash spells/distill-hypr-docs.sh window-rules /tmp/window-rules.md
#
# Pages (maps to wiki path segments):
#   window-rules          → /Configuring/Window-Rules/
#   dispatchers           → /Configuring/Dispatchers/
#   variables             → /Configuring/Variables/
#   binds                 → /Configuring/Binds/
#   animations            → /Configuring/Animations/
#   workspace-rules       → /Configuring/Workspace-Rules/
#   <any>                 → Appended as-is to base URL
#
# Requires: curl, jq, GROQ_API_KEY (or RaBbLE-sCoRE/server/.env with GROQ_API_KEY)
# Optional: pandoc (for HTML→text; falls back to lynx then raw curl)
#
# Output: distilled markdown written to <output-file> or stdout if not given.
# The output is also appended to RaBbLE-OS/Hyprland-<page>-distill.md in the
# Grimoire if the Grimoire root is detectable.
#
# NOTE: The Hyprland wiki at https://wiki.hypr.land/ has been inaccessible to
# automated fetches during testing (returns 404 for API requests). This spell
# falls back to a raw GitHub source fetch when the wiki is unreachable.
#
# spark ~ grimoire >> hypr wiki distill spell // %HYPR_DOCS%
# =============================================================================
set -euo pipefail

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; MAGENTA='\033[0;35m'; RESET='\033[0m'
ok()     { echo -e "  ${GREEN}✓${RESET}  $*" >&2; }
info()   { echo -e "  ${CYAN}·${RESET}  $*" >&2; }
warn()   { echo -e "  ${YELLOW}!${RESET}  $*" >&2; }
err()    { echo -e "  ${RED}✗${RESET}  $*" >&2; }
header() { echo -e "\n${MAGENTA}$*${RESET}\n" >&2; }

SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"

# ── Config ────────────────────────────────────────────────────────────────────
WIKI_BASE="https://wiki.hypr.land"
GITHUB_DOCS_BASE="https://raw.githubusercontent.com/hyprwm/hyprland-wiki/main/pages"
GROQ_MODEL="llama-3.1-8b-instant"

# Page path mapping
declare -A PAGE_MAP=(
    [window-rules]="Configuring/Window-Rules"
    [dispatchers]="Configuring/Dispatchers"
    [variables]="Configuring/Variables"
    [binds]="Configuring/Binds"
    [animations]="Configuring/Animations"
    [workspace-rules]="Configuring/Workspace-Rules"
    [keybinds]="Configuring/Binds"
    [monitors]="Configuring/Monitors"
    [env]="Configuring/Environment-variables"
    [layers]="Configuring/Layer-Rules"
)

# ── Argument handling ─────────────────────────────────────────────────────────
PAGE="${1:-window-rules}"
OUTPUT_FILE="${2:-}"

if [[ "${PAGE_MAP[$PAGE]+isset}" ]]; then
    PAGE_PATH="${PAGE_MAP[$PAGE]}"
else
    PAGE_PATH="$PAGE"
fi

# ── Groq key ──────────────────────────────────────────────────────────────────
GROQ_KEY="${GROQ_API_KEY:-}"
if [ -z "$GROQ_KEY" ]; then
    ENV_FILE="$GRIMOIRE_ROOT/../RaBbLE-sCoRE/server/.env"
    if [ -f "$ENV_FILE" ]; then
        GROQ_KEY="$(grep -E '^GROQ_API_KEY=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)"
    fi
fi

# ── Fetch page content ────────────────────────────────────────────────────────
fetch_wiki() {
    local url="$WIKI_BASE/$PAGE_PATH/"
    info "Fetching wiki: $url"
    local content=""

    # Try wiki first
    if command -v lynx &>/dev/null; then
        content="$(lynx -dump -nolist "$url" 2>/dev/null || true)"
    elif command -v curl &>/dev/null; then
        local raw
        raw="$(curl -fsSL --max-time 15 "$url" 2>/dev/null || true)"
        if [ -n "$raw" ]; then
            # Strip HTML tags crudely if no pandoc/lynx
            if command -v pandoc &>/dev/null; then
                content="$(echo "$raw" | pandoc -f html -t plain 2>/dev/null || true)"
            else
                content="$(echo "$raw" | sed 's/<[^>]*>//g' | sed '/^[[:space:]]*$/d')"
            fi
        fi
    fi

    # Fallback: try GitHub wiki source
    if [ -z "$content" ] || echo "$content" | grep -qi "404\|not found"; then
        warn "Wiki unreachable, trying GitHub source..."
        local gh_url="$GITHUB_DOCS_BASE/$PAGE_PATH.md"
        info "GitHub: $gh_url"
        content="$(curl -fsSL --max-time 15 "$gh_url" 2>/dev/null || true)"
    fi

    if [ -z "$content" ]; then
        err "Could not fetch content for page: $PAGE_PATH"
        err "Both wiki and GitHub source returned empty."
        err "You may need to fetch manually and pipe to this script."
        exit 1
    fi

    echo "$content"
}

# ── Distill with Groq ─────────────────────────────────────────────────────────
distill_with_groq() {
    local content="$1"

    # Truncate if very long (Groq has token limits)
    local truncated
    truncated="$(echo "$content" | head -c 12000)"

    local system_prompt="You are a technical documentation distiller for the RaBbLE-OS Grimoire. Extract and summarize Hyprland configuration documentation into a concise, accurate Markdown reference. Focus on: syntax examples, valid values/options, deprecation notices, and gotchas. Omit filler text. Use code blocks for all syntax examples. Be precise — this will be used by AI agents to configure Hyprland."

    local user_prompt="Distill this Hyprland wiki page content into a Grimoire-style reference note (max 600 words). Page: ${PAGE_PATH}

Content:
${truncated}"

    local payload
    payload="$(jq -nc \
        --arg model "$GROQ_MODEL" \
        --arg system "$system_prompt" \
        --arg user "$user_prompt" \
        '{model: $model, messages: [{role:"system",content:$system},{role:"user",content:$user}], max_tokens: 1024, temperature: 0.1}')"

    local response
    response="$(curl -fsSL \
        -H "Authorization: Bearer $GROQ_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "https://api.groq.com/openai/v1/chat/completions" 2>/dev/null)"

    if echo "$response" | jq -e '.choices[0].message.content' &>/dev/null; then
        echo "$response" | jq -r '.choices[0].message.content'
    else
        err "Groq distill failed:"
        echo "$response" | jq -c '.error // .' >&2
        # Fall back to raw content with header
        echo "# Hyprland — ${PAGE_PATH} (raw fetch, distill failed)"
        echo ""
        echo "$content" | head -c 4000
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
header "distill-hypr-docs: $PAGE_PATH"

RAW_CONTENT="$(fetch_wiki)"
ok "Fetched $(echo "$RAW_CONTENT" | wc -c) bytes"

DISTILLED=""
if [ -n "$GROQ_KEY" ]; then
    info "Distilling with Groq ($GROQ_MODEL)..."
    DISTILLED="$(distill_with_groq "$RAW_CONTENT")"
    ok "Distilled"
else
    # TODO: wire up OpenRouter as fallback (see openrouter-ctl.sh pattern)
    warn "No GROQ_API_KEY found. Returning raw fetched content."
    warn "To enable LLM distillation: set GROQ_API_KEY env var or add to RaBbLE-sCoRE/server/.env"
    DISTILLED="# Hyprland — ${PAGE_PATH} (raw fetch, no LLM distill)"$'\n\n'"${RAW_CONTENT}"
fi

# ── Output ────────────────────────────────────────────────────────────────────
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
HEADER="<!-- distilled: $TIMESTAMP | source: $WIKI_BASE/$PAGE_PATH/ -->"
FULL_OUTPUT="${HEADER}"$'\n'"${DISTILLED}"

if [ -n "$OUTPUT_FILE" ]; then
    echo "$FULL_OUTPUT" > "$OUTPUT_FILE"
    ok "Written to: $OUTPUT_FILE"
else
    echo "$FULL_OUTPUT"
fi

# ── Auto-save to Grimoire if distillation succeeded ───────────────────────────
if [ -n "$GROQ_KEY" ] && [ -n "$OUTPUT_FILE" ]; then
    GRIMOIRE_OUT="$GRIMOIRE_ROOT/RaBbLE-OS/Hyprland-$(echo "$PAGE" | tr '/' '-')-distill.md"
    if [ "$OUTPUT_FILE" != "$GRIMOIRE_OUT" ]; then
        echo "$FULL_OUTPUT" > "$GRIMOIRE_OUT"
        ok "Also saved to Grimoire: $GRIMOIRE_OUT"
    fi
fi
