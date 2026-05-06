#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Collective — install-theme.sh
# Install and activate the RaBbLE-Theme for Claude Code (~/.claude)
#
# Usage:
#   ./scripts/install-theme.sh              — install + activate
#   ./scripts/install-theme.sh --check      — check current state, no changes
#   ./scripts/install-theme.sh --uninstall  — remove theme and reset to dark
#
# harmonize ~ aesthetic >> RaBbLE-Theme crystallized // %THEME_LOCKED%
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTIVE_ROOT="$(dirname "$SCRIPT_DIR")"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
VIOLET='\033[38;2;191;95;255m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RED='\033[38;2;224;92;111m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
RESET='\033[0m'

pulse()   { echo -e "${MAGENTA}${1}${RESET}"; }
info()    { echo -e "${CYAN}  ${1}${RESET}"; }
muted()   { echo -e "${MUTED}  ${1}${RESET}"; }
success() { echo -e "${GREEN}  ✓ ${1}${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠ ${1}${RESET}"; }
error()   { echo -e "${RED}  ✗ ${1}${RESET}"; exit 1; }

# =============================================================================
# THEME DEFINITION
# Colors sourced from grimoire/distilled/palette.distilled.md — never invent hex.
# =============================================================================

THEME_NAME="RaBbLE-Theme"
THEME_KEY="custom:rabble-theme"
THEME_FILE="$HOME/.claude/themes/rabble-theme.json"
SETTINGS_FILE="$HOME/.claude/settings.json"

THEME_JSON='{
  "name": "RaBbLE-Theme",
  "base": "dark",
  "overrides": {
    "claude": "#ff2d78",
    "error": "#e05c6f",
    "success": "#50fa7b",
    "warning": "#f1fa8c",
    "bash": "#00f5ff",
    "text": "#e8e6f0",
    "permission": "#bf5fff",
    "diffAddedDimmed": "#50fa7b",
    "diffRemovedDimmed": "#e05c6f"
  }
}'

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

MODE="install"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)     MODE="check";     shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--check] [--uninstall]"
      exit 0 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

# =============================================================================
# HELPERS
# =============================================================================

claude_dir_exists() {
  [[ -d "$HOME/.claude" ]]
}

theme_is_current() {
  [[ -f "$THEME_FILE" ]] && \
    [[ "$(cat "$THEME_FILE")" == "$THEME_JSON" ]]
}

settings_has_theme() {
  [[ -f "$SETTINGS_FILE" ]] && \
    grep -q "\"theme\".*\"$THEME_KEY\"" "$SETTINGS_FILE" 2>/dev/null
}

# Writes or updates the "theme" key in settings.json.
# Uses python3 for safe JSON manipulation; falls back to sed if unavailable.
set_theme_in_settings() {
  local target_key="$1"

  if [[ ! -f "$SETTINGS_FILE" ]]; then
    printf '{\n  "theme": "%s"\n}\n' "$target_key" > "$SETTINGS_FILE"
    return
  fi

  if command -v python3 &>/dev/null; then
    python3 - "$SETTINGS_FILE" "$target_key" <<'EOF'
import sys, json
path, key = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
if key == "__remove__":
    data.pop("theme", None)
else:
    data["theme"] = key
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
EOF
  else
    # Fallback: sed-based upsert (handles simple single-level JSON only)
    if grep -q '"theme"' "$SETTINGS_FILE"; then
      sed -i "s|\"theme\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"theme\": \"$target_key\"|" "$SETTINGS_FILE"
    else
      sed -i "s|^{|{\n  \"theme\": \"$target_key\",|" "$SETTINGS_FILE"
    fi
  fi
}

# =============================================================================
# CHECK MODE
# =============================================================================

if [[ "$MODE" == "check" ]]; then
  echo ""
  pulse "RaBbLE-Theme — Status Check"
  pulse "════════════════════════════════════════"

  if claude_dir_exists; then
    success "~/.claude directory exists"
  else
    warn "~/.claude directory not found — Claude Code may not be installed"
  fi

  if [[ -f "$THEME_FILE" ]]; then
    if theme_is_current; then
      success "Theme file is current: $THEME_FILE"
    else
      warn "Theme file exists but is outdated — run without --check to update"
    fi
  else
    warn "Theme file not installed: $THEME_FILE"
  fi

  if settings_has_theme; then
    success "Theme active in settings.json (theme: \"$THEME_KEY\")"
  else
    if [[ -f "$SETTINGS_FILE" ]]; then
      current=$(grep '"theme"' "$SETTINGS_FILE" 2>/dev/null || echo "  (no theme key)")
      warn "Theme not active in settings.json. Current:$current"
    else
      warn "settings.json not found"
    fi
  fi

  echo ""
  exit 0
fi

# =============================================================================
# UNINSTALL MODE
# =============================================================================

if [[ "$MODE" == "uninstall" ]]; then
  echo ""
  pulse "RaBbLE-Theme — Uninstall"
  pulse "════════════════════════════════════════"

  if [[ -f "$THEME_FILE" ]]; then
    rm "$THEME_FILE"
    success "Removed theme file: $THEME_FILE"
  else
    muted "Theme file not present — nothing to remove"
  fi

  if [[ -f "$SETTINGS_FILE" ]] && grep -q '"theme"' "$SETTINGS_FILE" 2>/dev/null; then
    set_theme_in_settings "__remove__"
    success "Removed theme key from settings.json (Claude Code will use default)"
  else
    muted "No theme key in settings.json — nothing to remove"
  fi

  echo ""
  pulse "harmonize ~ aesthetic >> RaBbLE-Theme removed // %THEME_CLEARED%"
  echo ""
  exit 0
fi

# =============================================================================
# INSTALL MODE
# =============================================================================

echo ""
pulse "RaBbLE-Theme — Install"
pulse "════════════════════════════════════════"
info "Target:   $THEME_FILE"
info "Activate: $SETTINGS_FILE"
echo ""

# Guard: require ~/.claude to exist (Claude Code must be installed)
if ! claude_dir_exists; then
  error "~/.claude not found — install Claude Code first: https://claude.ai/code"
fi

# --- Theme file --------------------------------------------------------------

mkdir -p "$(dirname "$THEME_FILE")"

if theme_is_current; then
  muted "Theme file already current — skipping write"
else
  printf '%s\n' "$THEME_JSON" > "$THEME_FILE"
  success "Theme file written: $THEME_FILE"
fi

# --- Settings activation -----------------------------------------------------

if settings_has_theme; then
  muted "Theme already active in settings.json"
else
  set_theme_in_settings "$THEME_KEY"
  success "Theme activated in settings.json (\"theme\": \"$THEME_KEY\")"
fi

# --- Summary -----------------------------------------------------------------

echo ""
pulse "── Palette"
muted "  claude      #ff2d78  magenta   primary neon, active states"
muted "  error       #e05c6f  red       errors, destructive actions"
muted "  success     #50fa7b  green     clean, ok, confirmed"
muted "  warning     #f1fa8c  yellow    caution, staged, attention"
muted "  bash        #00f5ff  cyan      shell output, links"
muted "  text        #e8e6f0  light     primary readable text"
muted "  permission  #bf5fff  violet    permission prompts"
muted "  diffAdded   #50fa7b  green     added diff (dimmed)"
muted "  diffRemoved #e05c6f  red       removed diff (dimmed)"
echo ""
pulse "harmonize ~ aesthetic >> RaBbLE-Theme crystallized // %THEME_LOCKED%"
echo ""
