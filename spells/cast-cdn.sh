#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — cast-cdn.sh
# Build Aether + NeBuLA, stage into World, deploy to joinrabble.world via wrangler.
#
# Decouples deployment from git — wrangler deploys the working directory,
# not the repo state. Git integration in Cloudflare must be disconnected
# (dashboard only) before using this spell.
#
# Phase 1 CDN model: World worker serves /aether/ and /nebula/ as
# root-relative paths. No separate CDN worker needed.
# NOTE: a later "Phase 2" unified cdn.joinrabble.world worker was considered
# and cancelled — Aether/NeBuLA are instead deployed to their own permanent
# subdomains (aether.joinrabble.world, nebula.joinrabble.world) directly.
# See: RaBbLE-Grimoire/RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md
#
# Usage:
#   bash spells/cast-cdn.sh              — build + stage + deploy
#   bash spells/cast-cdn.sh --dry-run    — show what would happen, no changes
#   bash spells/cast-cdn.sh --skip-build — stage + deploy only (dist must exist)
#   bash spells/cast-cdn.sh --stage-only — build + stage, skip wrangler deploy
#   bash spells/cast-cdn.sh --help       — this message
#
# spark ~ world >> cast-cdn: build, stage, deploy to Cloudflare // %CDN_CAST%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
AETHER_ROOT="$RABBLE_ROOT/RaBbLE-Aether"
NEBULA_ROOT="$RABBLE_ROOT/RaBbLE-NeBuLA"
WORLD_ROOT="$RABBLE_ROOT/RaBbLE-World"

# CDN version — follows Five-Es: v{Epoch}.{Evolution}.{Echo}.{Episode}
# Update this when a versioned milestone is reached. All members share the
# same version clock until Echo 1. See RaBbLE-Versioning.md.
CDN_VERSION="v0.0.0.0"

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
err()     { echo -e "${RED}  ✗ ${1}${RESET}"; }
dry()     { echo -e "${YELLOW}  ~ ${1}${RESET}"; }

# ── Flags ───────────────────────────────────────────────────────────────────
DRY_RUN=false
SKIP_BUILD=false
STAGE_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true;    shift ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    --stage-only) STAGE_ONLY=true; shift ;;
    --help|-h)
      sed -n '/^# Usage:/,/^#.*%/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) err "Unknown flag: $1"; exit 1 ;;
  esac
done

# ── Header ───────────────────────────────────────────────────────────────────
echo ""
pulse "cast-cdn — build · stage · deploy"
pulse "════════════════════════════════════════"
[[ "$DRY_RUN"    == true ]] && warn "DRY RUN — no files will be written or deployed"
[[ "$SKIP_BUILD" == true ]] && warn "SKIP BUILD — using existing dist files"
[[ "$STAGE_ONLY" == true ]] && warn "STAGE ONLY — skipping wrangler deploy"
echo ""

# ── Preflight: directories ───────────────────────────────────────────────────
for dir_var in AETHER_ROOT NEBULA_ROOT WORLD_ROOT; do
  dir="${!dir_var}"
  if [[ ! -d "$dir" ]]; then
    err "${dir_var} not found: $dir"
    exit 1
  fi
done

# ── Preflight: wrangler ───────────────────────────────────────────────────────
# Prefer local install, fall back to global, fall back to npx
if [[ -f "$WORLD_ROOT/node_modules/.bin/wrangler" ]]; then
  WRANGLER="$WORLD_ROOT/node_modules/.bin/wrangler"
elif command -v wrangler &>/dev/null; then
  WRANGLER="wrangler"
elif npm exec --yes -- wrangler --version &>/dev/null 2>&1; then
  WRANGLER="npx --yes wrangler"
else
  err "wrangler not found — install globally: npm install -g wrangler"
  exit 1
fi

WRANGLER_VERSION=$(eval "$WRANGLER --version" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
info "wrangler $WRANGLER_VERSION"
echo ""

# ── Preflight: npm ────────────────────────────────────────────────────────────
if ! command -v npm &>/dev/null; then
  err "npm not found — install Node.js: https://nodejs.org/"
  exit 1
fi

# ── Step 1: Build Aether ─────────────────────────────────────────────────────
pulse "1 · Aether"
AETHER_SHA=$(git -C "$AETHER_ROOT" rev-parse --short HEAD 2>/dev/null || echo "untracked")
AETHER_DIRTY=$(git -C "$AETHER_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [[ "$SKIP_BUILD" == true ]]; then
  muted "skipped (--skip-build)"
elif [[ "$DRY_RUN" == true ]]; then
  dry "npm run build:min  →  dist/aether.min.css"
  [[ "$AETHER_DIRTY" -gt 0 ]] && warn "Aether has $AETHER_DIRTY uncommitted change(s)"
else
  [[ "$AETHER_DIRTY" -gt 0 ]] && warn "Aether has $AETHER_DIRTY uncommitted change(s) — building working tree"
  if [[ ! -f "$AETHER_ROOT/node_modules/.bin/esbuild" ]]; then
    info "Installing Aether dependencies..."
    npm ci --prefix "$AETHER_ROOT" --silent
  fi
  npm run build:min --prefix "$AETHER_ROOT" 2>&1 | grep -E 'dist/|Done|error' || true
  success "built  aether @ $AETHER_SHA"
fi

# Verify output exists
if [[ "$DRY_RUN" == false ]]; then
  for f in "dist/aether.css" "dist/aether.min.css"; do
    if [[ ! -f "$AETHER_ROOT/$f" ]]; then
      err "Aether build output missing: $f"
      exit 1
    fi
  done
fi

# ── Step 2: Build NeBuLA ─────────────────────────────────────────────────────
echo ""
pulse "2 · NeBuLA"
NEBULA_SHA=$(git -C "$NEBULA_ROOT" rev-parse --short HEAD 2>/dev/null || echo "untracked")
NEBULA_DIRTY=$(git -C "$NEBULA_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

if [[ "$SKIP_BUILD" == true ]]; then
  muted "skipped (--skip-build)"
elif [[ "$DRY_RUN" == true ]]; then
  dry "npm run build  →  dist/nebula.iife.js"
  [[ "$NEBULA_DIRTY" -gt 0 ]] && warn "NeBuLA has $NEBULA_DIRTY uncommitted change(s)"
else
  [[ "$NEBULA_DIRTY" -gt 0 ]] && warn "NeBuLA has $NEBULA_DIRTY uncommitted change(s) — building working tree"
  if [[ ! -f "$NEBULA_ROOT/node_modules/.bin/esbuild" ]]; then
    info "Installing NeBuLA dependencies..."
    npm ci --prefix "$NEBULA_ROOT" --silent
  fi
  npm run build --prefix "$NEBULA_ROOT" 2>&1 | grep -E 'dist/|Done|error' || true
  success "built  nebula @ $NEBULA_SHA"
fi

# Verify output exists
if [[ "$DRY_RUN" == false ]]; then
  if [[ ! -f "$NEBULA_ROOT/dist/nebula.iife.js" ]]; then
    err "NeBuLA build output missing: dist/nebula.iife.js"
    exit 1
  fi
fi

# ── Step 3: Stage into World ──────────────────────────────────────────────────
echo ""
pulse "3 · Stage  →  World/aether + World/nebula"

AETHER_STAGE="$WORLD_ROOT/aether/$CDN_VERSION"
NEBULA_STAGE="$WORLD_ROOT/nebula/$CDN_VERSION"

# Files to stage: [source]:[destination-relative-to-stage-dir]
AETHER_FILES=(
  "dist/aether.css:aether.css"
  "dist/aether.css.map:aether.css.map"
  "dist/aether.min.css:aether.min.css"
  "dist/aether.min.css.map:aether.min.css.map"
)
NEBULA_FILES=(
  "dist/nebula.iife.js:nebula.iife.js"
)

stage_files() {
  local src_root="$1"
  local dst_dir="$2"
  shift 2
  local files=("$@")
  local staged=0

  for entry in "${files[@]}"; do
    local src_rel="${entry%%:*}"
    local dst_name="${entry##*:}"
    local src="$src_root/$src_rel"
    local dst="$dst_dir/$dst_name"

    if [[ ! -f "$src" ]] && [[ "$DRY_RUN" == false ]]; then
      warn "source missing, skipping: $src_rel"
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      dry "stage  $dst_name  →  ${dst_dir##*/RaBbLE-World/}/"
    else
      mkdir -p "$dst_dir"
      cp "$src" "$dst"
      success "staged $dst_name"
    fi
    staged=$((staged + 1))
  done
}

stage_files "$AETHER_ROOT" "$AETHER_STAGE" "${AETHER_FILES[@]}"
stage_files "$NEBULA_ROOT" "$NEBULA_STAGE" "${NEBULA_FILES[@]}"

if [[ "$DRY_RUN" == false ]]; then
  muted "aether → World/aether/$CDN_VERSION/"
  muted "nebula → World/nebula/$CDN_VERSION/"
fi

# ── Step 4: Deploy via wrangler ───────────────────────────────────────────────
echo ""
pulse "4 · Deploy  →  joinrabble.world"

if [[ "$STAGE_ONLY" == true ]]; then
  muted "skipped (--stage-only)"
  echo ""
  pulse "════════════════════════════════════════"
  success "staged — run wrangler deploy when ready:"
  muted "  cd RaBbLE-World && npx wrangler deploy"
  echo ""
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  dry "wrangler deploy  (from RaBbLE-World/)"
  echo ""
  pulse "════════════════════════════════════════"
  info "dry run complete — no changes made"
  echo ""
  exit 0
fi

# Check wrangler auth
if ! eval "$WRANGLER whoami" &>/dev/null; then
  err "wrangler not authenticated — run: npx wrangler login"
  exit 1
fi

DEPLOY_OUTPUT=$(cd "$WORLD_ROOT" && eval "$WRANGLER deploy" 2>&1)
DEPLOY_EXIT=$?

echo "$DEPLOY_OUTPUT" | grep -E 'Uploaded|Published|Total|https://' | while read -r line; do
  success "$line"
done

if [[ $DEPLOY_EXIT -ne 0 ]]; then
  echo "$DEPLOY_OUTPUT"
  err "wrangler deploy failed (exit $DEPLOY_EXIT)"
  exit $DEPLOY_EXIT
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
pulse "════════════════════════════════════════"
echo ""
success "deployed joinrabble.world"
muted "  aether  $AETHER_SHA  ($CDN_VERSION)"
muted "  nebula  $NEBULA_SHA  ($CDN_VERSION)"
echo ""
info "Verify:"
muted "  https://joinrabble.world"
muted "  https://joinrabble.world/aether/$CDN_VERSION/aether.css"
muted "  https://joinrabble.world/nebula/$CDN_VERSION/nebula.iife.js"
echo ""
pulse "spark ~ world >> cast-cdn: build, stage, deploy to Cloudflare // %CDN_CAST%"
echo ""
