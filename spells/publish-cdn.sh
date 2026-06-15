#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — publish-cdn.sh
# Build and publish Aether and NeBuLA to their CDN subdomains via Cloudflare Pages.
#
# Subdomains (no R2 required — free tier Cloudflare Pages):
#   aether.joinrabble.world — Aether design system CSS
#   nebula.joinrabble.world — NeBuLA entity renderer IIFE bundle
#
# Version path: /<Five-Es version>/<file>
#   e.g. /v0.0.0.1/aether.css  ·  /v0.0.0.1/nebula.iife.js
#
# Manual steps (one-time, via Cloudflare dashboard):
#   1. Create Pages project "rabble-aether"  — aether.joinrabble.world
#   2. Create Pages project "rabble-nebula"  — nebula.joinrabble.world
#   3. Add custom domains in Pages dashboard
#   4. wrangler login
#
# Usage:
#   bash spells/publish-cdn.sh v0.0.0.1              # build + publish both
#   bash spells/publish-cdn.sh --aether-only v0.0.0.1
#   bash spells/publish-cdn.sh --nebula-only v0.0.0.1
#   bash spells/publish-cdn.sh --dry-run v0.0.0.1    # preview, no deploy
#   bash spells/publish-cdn.sh --help
#
# spark ~ cdn >> subdomain delivery: aether.joinrabble.world + nebula.joinrabble.world // %CDN_SUBDOMAIN%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
AETHER_ROOT="$RABBLE_ROOT/RaBbLE-Aether"
NEBULA_ROOT="$RABBLE_ROOT/RaBbLE-NeBuLA"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
VIOLET='\033[38;2;191;95;255m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
MUTED='\033[38;2;107;104;128m'
RED='\033[38;2;224;92;111m'
RESET='\033[0m'

pulse()   { echo -e "${MAGENTA}${1}${RESET}"; }
info()    { echo -e "${CYAN}  ${1}${RESET}"; }
success() { echo -e "${GREEN}  ✓ ${1}${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠ ${1}${RESET}"; }
muted()   { echo -e "${MUTED}  ${1}${RESET}"; }
err()     { echo -e "${RED}  ✗ ${1}${RESET}"; exit 1; }
dry()     { echo -e "${YELLOW}  ~ ${1}${RESET}"; }

# ── Flags ─────────────────────────────────────────────────────────────────────
DRY_RUN=false
AETHER_ONLY=false
NEBULA_ONLY=false
VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     DRY_RUN=true; shift ;;
    --aether-only) AETHER_ONLY=true; shift ;;
    --nebula-only) NEBULA_ONLY=true; shift ;;
    --help|-h)
      sed -n '/^# Usage:/,/^#.*%/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    v[0-9]*)
      VERSION="$1"; shift ;;
    *) err "Unknown flag: $1" ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  err "Version required. Usage: publish-cdn.sh v0.0.0.1"
fi

# Validate Five-Es format: v{Epoch}.{Evolution}.{Echo}.{Episode}
if ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  err "Version must be Five-Es format: v{Epoch}.{Evolution}.{Echo}.{Episode} (e.g. v0.0.0.1)"
fi

echo ""
pulse "▶ RaBbLE CDN — Subdomain Publish"
pulse "════════════════════════════════════════"
info "Version:  $VERSION"
info "Aether:   aether.joinrabble.world/$VERSION/aether.css"
info "NeBuLA:   nebula.joinrabble.world/$VERSION/nebula.iife.js"
$DRY_RUN && warn "DRY RUN — no files will be written or deployed"
echo ""

# =============================================================================
# AETHER
# =============================================================================

if ! $NEBULA_ONLY; then
  pulse "── Aether"

  [[ -d "$AETHER_ROOT" ]] || err "RaBbLE-Aether not found at $AETHER_ROOT"

  AETHER_DIST="$AETHER_ROOT/dist/$VERSION"

  info "Building Aether..."
  if $DRY_RUN; then
    dry "would run: cd $AETHER_ROOT && npm run build:dev && npm run build"
    dry "would write: $AETHER_DIST/aether.css + aether.min.css"
  else
    cd "$AETHER_ROOT"
    npm run build:dev --silent
    npm run build --silent
    mkdir -p "$AETHER_DIST"
    cp dist/aether.css dist/aether.css.map "$AETHER_DIST/" 2>/dev/null || true
    cp dist/aether.min.css dist/aether.min.css.map "$AETHER_DIST/" 2>/dev/null || true
    success "Aether built → dist/$VERSION/"
  fi

  info "Deploying Aether to aether.joinrabble.world..."
  if $DRY_RUN; then
    dry "would run: wrangler pages deploy $AETHER_ROOT/dist --project-name=rabble-aether"
  else
    if ! command -v wrangler &>/dev/null; then
      warn "wrangler not found — skipping deploy. Install: npm i -g wrangler"
    else
      cd "$AETHER_ROOT"
      wrangler pages deploy dist --project-name=rabble-aether
      success "Aether deployed → aether.joinrabble.world/$VERSION/aether.css"
    fi
  fi
  echo ""
fi

# =============================================================================
# NEBULA
# =============================================================================

if ! $AETHER_ONLY; then
  pulse "── NeBuLA"

  [[ -d "$NEBULA_ROOT" ]] || err "RaBbLE-NeBuLA not found at $NEBULA_ROOT"

  NEBULA_DIST="$NEBULA_ROOT/dist/$VERSION"

  info "Building NeBuLA IIFE bundle..."
  if $DRY_RUN; then
    dry "would run: cd $NEBULA_ROOT && npm run build:iife"
    dry "would write: $NEBULA_DIST/nebula.iife.js"
  else
    cd "$NEBULA_ROOT"
    npm run build:iife --silent 2>/dev/null || npm run build --silent
    mkdir -p "$NEBULA_DIST"
    # Copy built IIFE to versioned path
    if [[ -f "dist/nebula.iife.js" ]]; then
      cp dist/nebula.iife.js "$NEBULA_DIST/"
      success "NeBuLA built → dist/$VERSION/nebula.iife.js"
    else
      err "NeBuLA build did not produce dist/nebula.iife.js"
    fi
  fi

  info "Deploying NeBuLA to nebula.joinrabble.world..."
  if $DRY_RUN; then
    dry "would run: wrangler pages deploy $NEBULA_ROOT/dist --project-name=rabble-nebula"
  else
    if ! command -v wrangler &>/dev/null; then
      warn "wrangler not found — skipping deploy. Install: npm i -g wrangler"
    else
      cd "$NEBULA_ROOT"
      wrangler pages deploy dist --project-name=rabble-nebula
      success "NeBuLA deployed → nebula.joinrabble.world/$VERSION/nebula.iife.js"
    fi
  fi
  echo ""
fi

# =============================================================================
# Done
# =============================================================================

echo ""
pulse "════════════════════════════════════════"
pulse "spark ~ cdn >> $VERSION published // %CDN_LIVE%"
echo ""
info "Aether:  https://aether.joinrabble.world/$VERSION/aether.css"
info "NeBuLA:  https://nebula.joinrabble.world/$VERSION/nebula.iife.js"
echo ""
warn "Update World's loader to point to the new URLs:"
echo -e "  ${CYAN}RaBbLE-World/world/js/RaBbLE-aether.js${RESET} — set AETHER_URL"
echo -e "  ${CYAN}RaBbLE-World/world/js/RaBbLE-NeBuLA.js${RESET}  — set NEBULA_URL"
echo ""
muted "One-time Cloudflare setup (if not done):"
muted "  1. Pages project 'rabble-aether'  → aether.joinrabble.world"
muted "  2. Pages project 'rabble-nebula'  → nebula.joinrabble.world"
muted "  3. Add custom domains in Pages dashboard"
muted "  See: RaBbLE-Grimoire/RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md"
