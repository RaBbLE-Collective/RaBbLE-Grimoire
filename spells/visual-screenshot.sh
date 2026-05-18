#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — visual-screenshot.sh
# Capture a rendered page screenshot on RaBbLE-OS / Hyprland for agent visual review.
#
# Core mechanic: open a URL in Firefox, focus the window with hyprctl, capture
# the focused monitor with grim. Output path is printed as a machine-readable
# "SCREENSHOT: /path" line so agents can read it back without parsing noise.
#
# Not NeBuLA-specific. Useful any time an agent needs to see what changed
# visually: CSS tweaks, canvas animations, layout, entity rendering, etc.
# Modify --delay or --url as needed for the target page.
#
# Usage:
#   bash spells/visual-screenshot.sh
#   bash spells/visual-screenshot.sh --url http://localhost:8000
#   bash spells/visual-screenshot.sh --url http://localhost:8000/world/Boot.html
#   bash spells/visual-screenshot.sh --url file:///path/to/index.html --out ./shot.png
#   bash spells/visual-screenshot.sh --url http://localhost:8000 --close
#   bash spells/visual-screenshot.sh --url http://localhost:8000 --delay 3
#
# Flags:
#   --url URL       Page to open (default: http://localhost:8000)
#   --out PATH      Output path (default: ~/RaBbLE-screenshots/visual-TIMESTAMP.png)
#   --delay SECS    Seconds to wait for page render before capture (default: 2)
#   --close         Kill the Firefox window after capture
#   --help          Show this usage
#
# Requires: hyprctl, firefox, grim — active Hyprland session (RaBbLE-OS)
#
# reveal ~ os >> visual development screenshot captured // %VISUAL_CAST%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
STAMP="$(date +%Y%m%d-%H%M%S)"

URL="http://localhost:8000"
OUT="$HOME/RaBbLE-screenshots/visual-$STAMP.png"
DELAY="2"
CLOSE=false

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
RED='\033[38;2;224;92;111m'
RESET='\033[0m'

pulse()   { echo -e "${MAGENTA}${1}${RESET}"; }
info()    { echo -e "${CYAN}  ${1}${RESET}"; }
success() { echo -e "${GREEN}  ✓ ${1}${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠ ${1}${RESET}"; }
error()   { echo -e "${RED}  ✗ ${1}${RESET}"; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)   URL="${2:-}";   [[ -n "$URL" ]]   || error "--url requires a value";   shift 2 ;;
    --out)   OUT="${2:-}";   [[ -n "$OUT" ]]   || error "--out requires a value";   shift 2 ;;
    --delay) DELAY="${2:-}"; [[ -n "$DELAY" ]] || error "--delay requires a value"; shift 2 ;;
    --close) CLOSE=true; shift ;;
    --help|-h)
      sed -n '/^# Usage:/,/^# Requires:/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

echo ""
pulse "visual-screenshot ~ RaBbLE visual capture"
pulse "══════════════════════════════════════════"

[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || \
  error "Hyprland session not detected. Cast this on a RaBbLE-OS Hyprland device."
command -v hyprctl >/dev/null 2>&1 || error "hyprctl not found"
command -v firefox >/dev/null 2>&1 || error "firefox not found"
command -v grim    >/dev/null 2>&1 || error "grim not found"

mkdir -p "$(dirname "$OUT")"

info "Opening: $URL"
firefox --new-window "$URL" >/dev/null 2>&1 &
FIREFOX_PID=$!

info "Waiting ${DELAY}s for page render..."
sleep "$DELAY"

# Focus Firefox window — try title match first, fall back to class
hyprctl dispatch focuswindow "title:Mozilla Firefox" >/dev/null 2>&1 || \
hyprctl dispatch focuswindow "class:firefox"         >/dev/null 2>&1 || \
hyprctl dispatch focuswindow "class:Firefox"         >/dev/null 2>&1 || \
warn "Could not focus Firefox via hyprctl; capturing current focused output"

sleep 0.35

# Capture focused monitor (jq optional — falls back to full output)
MONITOR=""
if command -v jq >/dev/null 2>&1; then
  MONITOR="$(hyprctl monitors -j 2>/dev/null \
    | jq -r '.[] | select(.focused == true) | .name' | head -n 1)"
fi

if [[ -n "$MONITOR" && "$MONITOR" != "null" ]]; then
  info "Capturing monitor: $MONITOR"
  grim -o "$MONITOR" "$OUT"
else
  info "Capturing full output"
  grim "$OUT"
fi

if $CLOSE; then
  info "Closing Firefox (pid $FIREFOX_PID)"
  kill "$FIREFOX_PID" 2>/dev/null || true
fi

success "Captured: $OUT"
# Machine-readable line — agents: read the path after "SCREENSHOT: "
echo "SCREENSHOT: $OUT"
