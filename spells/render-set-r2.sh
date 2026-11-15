#!/usr/bin/env bash
# spells/render-set-r2.sh: push the sCoRE R2 persistence env vars to Render from the local secrets file.
# Reads R2_ENDPOINT, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY from ~/.config/rabble/pocket-companion.secrets
# (never printed). Sets R2_BUCKET=rabble-score. Does NOT redeploy: env-set only stages values for the next deploy.
# R2_ALLOW_FRESH_START is first-boot only: pass --fresh-start to set it, --clear-fresh-start to remove it afterward.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS="${POCKET_SECRETS:-$HOME/.config/rabble/pocket-companion.secrets}"
[ -r "$SECRETS" ] || { echo "missing $SECRETS" >&2; exit 1; }
set -a; . "$SECRETS"; set +a
for k in R2_ENDPOINT R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY; do
  [ -n "${!k:-}" ] || { echo "$k is empty in $SECRETS" >&2; exit 1; }
done
set_env() { bash "$HERE/render-ctl.sh" env-set "$1" "$2" >/dev/null && echo "set $1"; }
set_env R2_ENDPOINT "$R2_ENDPOINT"
set_env R2_ACCESS_KEY_ID "$R2_ACCESS_KEY_ID"
set_env R2_SECRET_ACCESS_KEY "$R2_SECRET_ACCESS_KEY"
set_env R2_BUCKET "${R2_BUCKET:-rabble-score}"
case "${1:-}" in
  --fresh-start)       set_env R2_ALLOW_FRESH_START 1 ;;
  --clear-fresh-start) set_env R2_ALLOW_FRESH_START 0 ;;
esac
echo "Done. Nothing redeployed. Check names: bash $HERE/render-ctl.sh env-show"
