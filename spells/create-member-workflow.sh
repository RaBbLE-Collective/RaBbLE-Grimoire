#!/usr/bin/env bash
# =============================================================================
# spells/create-member-workflow.sh — Create GitHub Actions Deployment Workflow
#
# Generates and commits GitHub Actions workflow file for member repos.
# Used to set up deploy.yml for Aether, NeBuLA, World, etc.
#
# Usage:
#   bash spells/create-member-workflow.sh aether
#   bash spells/create-member-workflow.sh nebula
#   bash spells/create-member-workflow.sh world
#
# The script creates:
#   - .github/workflows/deploy.yml in the member repo
#   - Workflow triggers on v* tags
#   - Builds and uploads to Cloudflare R2 CDN
#
# spark ~ github >> actions workflow setup for CDN deployment // %WORKFLOW_SETUP%
# =============================================================================

set -euo pipefail

# ─ Colors ────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✓${RESET}  $*"; }
info() { echo -e "  ${CYAN}·${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()  { echo -e "  ${RED}✗${RESET}  $*" >&2; }

# ─ Parse Arguments ───────────────────────────────────────────────────────────
MEMBER="${1:-}"

if [ -z "$MEMBER" ]; then
  cat <<'USAGE'
Usage: bash spells/create-member-workflow.sh <member>

Members:
  aether     CSS bundle (visual design system)
  nebula     JavaScript bundle (rendering engine)
  world      Cloudflare Worker (entry point)

Examples:
  bash spells/create-member-workflow.sh aether
  bash spells/create-member-workflow.sh nebula

USAGE
  exit 0
fi

# ─ Paths ─────────────────────────────────────────────────────────────────────
SPELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRIMOIRE_ROOT="$(cd "$SPELL_DIR/.." && pwd)"
COLLECTIVE_ROOT="$(cd "$GRIMOIRE_ROOT/.." && pwd)"

MEMBER=$(echo "$MEMBER" | tr '[:upper:]' '[:lower:]')
MEMBER_REPO="RaBbLE-$(echo "$MEMBER" | sed 's/^./\U&/')"
MEMBER_ROOT="$COLLECTIVE_ROOT/$MEMBER_REPO"
WORKFLOW_DIR="$MEMBER_ROOT/.github/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/deploy.yml"

# ─ Validate ──────────────────────────────────────────────────────────────────
if [ ! -d "$MEMBER_ROOT" ]; then
  err "Member repo not found: $MEMBER_ROOT"
  exit 1
fi

ok "Member: $MEMBER_REPO"

# ─ Generate Workflow (by member type) ────────────────────────────────────────
case "$MEMBER" in
  aether|nebula)
    # CSS/JS bundles → R2 CDN
    WORKFLOW_CONTENT='name: Deploy to Cloudflare R2

on:
  push:
    tags:
      - '"'"'v*'"'"'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '"'"'20'"'"'
          cache: '"'"'npm'"'"'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Get version from tag
        id: tag
        run: echo "version=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT

      - name: Upload to R2
        run: |
          npm install -g wrangler

          # Upload all built files
          for file in dist/*; do
            filename=$(basename "$file")
            wrangler r2 object upload \
              --bucket=rabble-cdn-prod \
              "$file" \
              "'"$MEMBER"'/${{ steps.tag.outputs.version }}/$filename"
          done
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}

      - name: Purge Cloudflare cache
        run: |
          curl -X POST "https://api.cloudflare.com/client/v4/zones/${{ secrets.CLOUDFLARE_ZONE_ID }}/purge_cache" \
            -H "Authorization: Bearer ${{ secrets.CLOUDFLARE_API_TOKEN }}" \
            -H "Content-Type: application/json" \
            --data '"'"'{\"files\":[\"https://cdn.joinrabble.world/'"$MEMBER"'/*\"]}'"'"'
'
    ;;

  world)
    # Cloudflare Worker deploy
    WORKFLOW_CONTENT='name: Deploy to Cloudflare Workers

on:
  push:
    tags:
      - '"'"'v*'"'"'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '"'"'20'"'"'
          cache: '"'"'npm'"'"'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Deploy to Cloudflare Workers
        run: npx wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
'
    ;;

  *)
    err "Unknown member: $MEMBER"
    exit 1
    ;;
esac

# ─ Create or Update Workflow ─────────────────────────────────────────────────
mkdir -p "$WORKFLOW_DIR"

if [ -f "$WORKFLOW_FILE" ]; then
  warn "Workflow already exists: $WORKFLOW_FILE"
  read -r -p "  Overwrite? [y/N] " confirm
  [ "$confirm" = "y" ] || { info "Aborted."; exit 0; }
fi

echo "$WORKFLOW_CONTENT" > "$WORKFLOW_FILE"
ok "Workflow created: $WORKFLOW_FILE"

# ─ Commit Workflow ───────────────────────────────────────────────────────────
cd "$MEMBER_ROOT"

if git diff --quiet .github/workflows/deploy.yml 2>/dev/null; then
  info "Workflow already committed"
else
  git add .github/workflows/deploy.yml
  git commit -m "spark ~ $MEMBER >> GitHub Actions deploy workflow for CDN // %WORKFLOW_SETUP%"
  ok "Workflow committed"
fi

echo ""
info "Next: Set GitHub Actions secrets"
info "  bash ../RaBbLE-Grimoire/spells/deploy-member.sh $MEMBER v0.0.0.1"
echo ""
