#!/usr/bin/env bash
# =============================================================================
# spells/sync-gists-to-world.sh — copy Grimoire gists into World for CF serving
#
# World serves static assets at joinrabble.world/* via Cloudflare Workers.
# Gist files copied to RaBbLE-World/gist/ are served at:
#   https://joinrabble.world/gist/{filename}
#
# sCoRE's GRIMOIRE_URL env var should point to https://joinrabble.world so that
# the fetch_grimoire tool can fetch these at runtime.
#
# Run after any change to gist/*.md, then commit World and deploy via wrangler.
#
# Usage:
#   bash spells/sync-gists-to-world.sh
#
# harmonize ~ grimoire >> sync gists to World for CF endpoint // %GRIMOIRE_API%
# =============================================================================
set -euo pipefail

SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
COLLECTIVE_ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"
WORLD_GIST="$COLLECTIVE_ROOT/RaBbLE-World/gist"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; RESET='\033[0m'
ok()   { echo -e "  ${GREEN}✓${RESET}  $*"; }
info() { echo -e "  ${CYAN}·${RESET}  $*"; }

info "Syncing gists from Grimoire → World/gist/ ..."
mkdir -p "$WORLD_GIST"

count=0
for f in "$GRIMOIRE_ROOT/gist"/RaBbLE-*.md; do
  cp "$f" "$WORLD_GIST/"
  ok "$(basename "$f")"
  count=$((count + 1))
done

echo ""
info "$count gist(s) copied to $WORLD_GIST"
info "Commit RaBbLE-World and deploy via wrangler to publish."
info "Set GRIMOIRE_URL=https://joinrabble.world on Render to activate the tool."
