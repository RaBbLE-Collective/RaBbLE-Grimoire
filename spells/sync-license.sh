#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — sync-license.sh
# Writes the canonical Sovereign Accord (RaBbLE-Collective/RaBbLE-Sovereign-Accord.md)
# into the LICENSE of every member that has one, substituting {{PRODUCT}} with the
# repo name. The Collective root gets the Grimoire-neutral wording ("RaBbLE-OS").
#
# Usage: bash spells/sync-license.sh [--check]
#   --check   write nothing; exit 1 if any LICENSE differs from what would be written
#
# spark ~ grimoire >> one Accord, many copies, no drift // %SYNC_LICENSE%
# =============================================================================
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(cd "$here/.." && pwd)"
canon="$here/RaBbLE-Collective/RaBbLE-Sovereign-Accord.md"
check=0; [ "${1:-}" = "--check" ] && check=1
drift=0
for target in "$root/LICENSE" "$root"/RaBbLE-*/LICENSE; do
  [ -f "$target" ] || continue
  dir="$(dirname "$target")"
  if [ "$dir" = "$root" ]; then product="RaBbLE-OS"; else product="$(basename "$dir")"; fi
  want="$(sed "s/{{PRODUCT}}/$product/g" "$canon")"
  if [ "$check" = 1 ]; then
    [ "$(cat "$target")" = "$want" ] || { echo "DRIFT  $target"; drift=1; }
  else
    printf '%s\n' "$want" > "$target"; echo "wrote  $target ($product)"
  fi
done
exit $drift
