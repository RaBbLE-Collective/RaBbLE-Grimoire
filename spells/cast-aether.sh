#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — cast-aether.sh
# Publish Aether design tokens and assets to RaBbLE-World for Cloudflare deploy.
#
# Aether is the source. World is the distribution point.
# This spell copies only the deployable surface (CSS, JSON, SVG) —
# not internal docs, specs, or reference files.
#
# After casting, commit the changes in RaBbLE-World and run wrangler deploy.
#
# Usage:
#   bash spells/cast-aether.sh              — cast Aether → World
#   bash spells/cast-aether.sh --dry-run    — show what would change
#   bash spells/cast-aether.sh --help       — this message
#
# spark ~ aether >> tokens cast into World, palette distributed // %AETHER_CAST%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
AETHER_ROOT="$RABBLE_ROOT/RaBbLE-Aether"
WORLD_ROOT="$RABBLE_ROOT/RaBbLE-World"
WORLD_AETHER="$WORLD_ROOT/aether"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
VIOLET='\033[38;2;191;95;255m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
RED='\033[38;2;224;92;111m'
RESET='\033[0m'

pulse()   { echo -e "${MAGENTA}${1}${RESET}"; }
info()    { echo -e "${CYAN}  ${1}${RESET}"; }
success() { echo -e "${GREEN}  ✓ ${1}${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠ ${1}${RESET}"; }
muted()   { echo -e "${MUTED}  ${1}${RESET}"; }
err()     { echo -e "${RED}  ✗ ${1}${RESET}"; }
dry()     { echo -e "${YELLOW}  ~ ${1}${RESET}"; }

# ── Published surface — only these files leave Aether ──────────────────────
# Add new paths here as Aether grows. Docs, specs, and reference files stay
# in Aether only — they are not part of the deployed design system.
#
# NOTE: rabble.css is NOT in this list. The spell generates a concatenated
# bundle as aether/rabble.css — inlining all CSS so no relative @import
# sub-requests are needed. The source @import version lives in Aether only.
PUBLISHED_FILES=(
  "assets/palette/rabble-palette.css"
  "assets/palette/rabble-palette.json"
  "assets/palette/rabble-palette.scss"
  "assets/motion/rabble-motion.css"
  "assets/components/rabble-components.css"
  "assets/logos/rabble-portal-glyphs.svg"
)

# ── CSS bundle order — files concatenated into aether/rabble.css ─────────────
BUNDLE_CSS=(
  "assets/palette/rabble-palette.css"
  "assets/motion/rabble-motion.css"
  "assets/components/rabble-components.css"
)

DRY_RUN=false

# ── Flags ───────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h)
      sed -n '/^# Usage:/,/^#.*%/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) err "Unknown flag: $1"; exit 1 ;;
  esac
done

# ── Preflight checks ─────────────────────────────────────────────────────────
echo ""
pulse "cast-aether — Aether → World"
pulse "════════════════════════════════════════"
[[ "$DRY_RUN" == true ]] && warn "DRY RUN — no files will be written"
echo ""

if [[ ! -d "$AETHER_ROOT" ]]; then
  err "RaBbLE-Aether not found at: $AETHER_ROOT"
  exit 1
fi

if [[ ! -d "$WORLD_ROOT" ]]; then
  err "RaBbLE-World not found at: $WORLD_ROOT"
  exit 1
fi

# Check Aether git status — warn if uncommitted changes would be cast
AETHER_DIRTY=$(git -C "$AETHER_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [[ "$AETHER_DIRTY" -gt 0 ]]; then
  warn "Aether has $AETHER_DIRTY uncommitted change(s) — casting working tree state"
fi

AETHER_BRANCH=$(git -C "$AETHER_ROOT" branch --show-current 2>/dev/null || echo "unknown")
AETHER_SHA=$(git -C "$AETHER_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
info "Aether: ${AETHER_BRANCH} @ ${AETHER_SHA}"
info "Target: ${WORLD_AETHER}/"
echo ""

# ── Ensure target directory exists ──────────────────────────────────────────
if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "$WORLD_AETHER/assets/palette" \
           "$WORLD_AETHER/assets/motion" \
           "$WORLD_AETHER/assets/components" \
           "$WORLD_AETHER/assets/logos"
fi

# ── Cast each file ───────────────────────────────────────────────────────────
CAST=0
CURRENT=0
ERRORS=0

for rel_path in "${PUBLISHED_FILES[@]}"; do
  src="$AETHER_ROOT/$rel_path"
  dst="$WORLD_AETHER/$rel_path"

  if [[ ! -f "$src" ]]; then
    err "source missing — $rel_path"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Compare checksums to detect actual changes
  if [[ -f "$dst" ]] && diff -q "$src" "$dst" > /dev/null 2>&1; then
    muted "current  $rel_path"
    CURRENT=$((CURRENT + 1))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ -f "$dst" ]]; then
      dry "update   $rel_path"
    else
      dry "new      $rel_path"
    fi
  else
    # Ensure parent directory exists for nested paths
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    if [[ ! -f "${dst}.prev" ]] || ! diff -q "$src" "$dst" > /dev/null 2>&1; then
      success "cast     $rel_path"
    fi
  fi

  CAST=$((CAST + 1))
done

# ── Generate concatenated CSS bundle as aether/rabble.css ───────────────────
# This replaces the @import version — one file, no relative sub-requests,
# works from file://, HTTP, and any page depth.
BUNDLE_DST="$WORLD_AETHER/rabble.css"
BUNDLE_SRC_HASH=""
for f in "${BUNDLE_CSS[@]}"; do
  BUNDLE_SRC_HASH+=$(md5sum "$AETHER_ROOT/$f" 2>/dev/null | cut -d' ' -f1)
done
BUNDLE_OLD_HASH=""
[[ -f "$BUNDLE_DST" ]] && BUNDLE_OLD_HASH=$(md5sum "$BUNDLE_DST" 2>/dev/null | cut -d' ' -f1)

if [[ "$BUNDLE_SRC_HASH" != "$BUNDLE_OLD_HASH" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    dry "update   rabble.css  (bundle — palette + motion + components)"
    CAST=$((CAST + 1))
  else
    {
      echo "/**"
      echo " * rabble.css — RaBbLE Design System Bundle"
      echo " * Generated by cast-aether.sh — do not edit directly."
      echo " * Source: RaBbLE-Aether ${AETHER_BRANCH}@${AETHER_SHA}"
      echo " * Cast:   $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      echo " *"
      echo " * To use: <link rel=\"stylesheet\" href=\"aether/rabble.css\">"
      echo " * Hosted: https://joinrabble.world/aether/rabble.css"
      echo " */"
      echo ""
      echo "/* ── Fonts ───────────────────────────────────────────────────────── */"
      echo "@import url('https://fonts.googleapis.com/css2?family=Orbitron:wght@500;700;900&family=Exo+2:ital,wght@0,400;0,600;0,700;0,800;0,900;1,400&family=Share+Tech+Mono&display=swap');"
      echo ""
      for css_path in "${BUNDLE_CSS[@]}"; do
        src_file="$AETHER_ROOT/$css_path"
        section_name=$(basename "$css_path")
        echo ""
        echo "/* ── ${section_name} $(printf '%0.s─' {1..50} | head -c $((60 - ${#section_name}))) */"
        cat "$src_file"
      done
    } > "$BUNDLE_DST"
    success "bundle   rabble.css  (palette + motion + components inlined)"
    CAST=$((CAST + 1))
  fi
else
  muted "current  rabble.css  (bundle)"
  CURRENT=$((CURRENT + 1))
fi

# ── Write cast manifest (records what was cast and from where) ───────────────
if [[ "$DRY_RUN" == false && "$CAST" -gt 0 ]]; then
  cat > "$WORLD_AETHER/.cast" <<EOF
# Aether cast manifest — generated by cast-aether.sh
# Do not edit manually.
cast_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
aether_branch: ${AETHER_BRANCH}
aether_sha: ${AETHER_SHA}
files_cast: ${CAST}
EOF
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
pulse "════════════════════════════════════════"

if [[ "$ERRORS" -gt 0 ]]; then
  err "$ERRORS file(s) had errors"
fi

if [[ "$CAST" -eq 0 && "$DRY_RUN" == false ]]; then
  success "World/aether already current — nothing to cast ($CURRENT file(s) checked)"
elif [[ "$DRY_RUN" == true ]]; then
  info "$CAST file(s) would be cast, $CURRENT already current"
else
  echo ""
  info "$CAST file(s) cast  •  $CURRENT already current"
  echo ""
  pulse "Next steps:"
  echo ""
  info "1. Review changes in RaBbLE-World:"
  muted "     git -C \"$WORLD_ROOT\" diff --stat aether/"
  echo ""
  info "2. Commit to World:"
  muted "     git -C \"$WORLD_ROOT\" add aether/"
  muted "     git -C \"$WORLD_ROOT\" commit -m \"ingest ~ world >> aether cast — ${AETHER_BRANCH}@${AETHER_SHA} // %AETHER_CAST%\""
  echo ""
  info "3. Deploy to joinrabble.world:"
  muted "     cd \"$WORLD_ROOT\" && wrangler deploy"
  echo ""
fi

if [[ "$CAST" -gt 0 || "$DRY_RUN" == false ]]; then
  pulse "spark ~ aether >> tokens cast into World, palette distributed // %AETHER_CAST%"
fi
echo ""
