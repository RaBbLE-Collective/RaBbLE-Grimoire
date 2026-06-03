#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — install-hooks.sh
# Installs the agent-agnostic post-commit breadcrumb hook into every Collective
# member repo's .git/hooks/. Idempotent — re-run any time (e.g. after a new
# member is cloned, or the hook script changes).
#
# Usage:
#   bash spells/install-hooks.sh           # install/refresh in all member repos
#
# Symlinks each repo's .git/hooks/post-commit -> this Grimoire's canonical hook,
# so updates to the hook propagate without reinstalling. Existing non-symlink
# hooks are left untouched (reported, not clobbered).
#
# spark ~ grimoire >> the routine fires itself // %HOOKS_INSTALLED%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
HOOK_SRC="$GRIMOIRE_ROOT/spells/hooks/post-commit"

[[ -f "$HOOK_SRC" ]] || { echo "Hook source missing: $HOOK_SRC" >&2; exit 1; }
chmod +x "$HOOK_SRC"

installed=0; skipped=0; relinked=0
for repo in "$RABBLE_ROOT" "$RABBLE_ROOT"/RaBbLE-*/; do
  repo="${repo%/}"
  gitdir="$repo/.git"
  [[ -d "$gitdir" ]] || continue
  label="${repo#$RABBLE_ROOT/}"; [[ "$repo" == "$RABBLE_ROOT" ]] && label="RaBbLE-Collective (root)"
  dest="$gitdir/hooks/post-commit"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "skip  (existing non-symlink hook): $label"
    skipped=$((skipped + 1)); continue
  fi
  [[ -L "$dest" ]] && relinked=$((relinked + 1))
  mkdir -p "$gitdir/hooks"
  ln -sf "$HOOK_SRC" "$dest"
  echo "ok    $label"
  installed=$((installed + 1))
done

echo ""
echo "Done — $installed installed/refreshed ($relinked already linked), $skipped skipped."
echo "Hook: appends a provisional feature breadcrumb on commit; override with"
echo "      bash spells/end-session.sh <feature-slug> [note]"
