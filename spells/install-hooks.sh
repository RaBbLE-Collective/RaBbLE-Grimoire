#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — install-hooks.sh
# Installs agent-agnostic git hooks into every Collective member repo.
# Idempotent — re-run any time (e.g. after a new member is cloned).
#
# Hooks installed:
#   pre-commit   — blocks CLAUDE.md/CODEX.md/GEMINI.md from being committed
#   post-commit  — appends provisional token breadcrumb to ledger
#
# Usage:
#   bash spells/install-hooks.sh           # install/refresh in all member repos
#
# Each hook in .git/hooks/ is a symlink → Grimoire's canonical version,
# so updates propagate without reinstalling. Existing non-symlink hooks
# are left untouched (reported, not clobbered).
#
# spark ~ grimoire >> the routine fires itself // %HOOKS_INSTALLED%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
HOOKS_DIR="$GRIMOIRE_ROOT/spells/hooks"

HOOKS=(pre-commit post-commit)

for hook in "${HOOKS[@]}"; do
  src="$HOOKS_DIR/$hook"
  [[ -f "$src" ]] || { echo "Hook source missing: $src" >&2; exit 1; }
  chmod +x "$src"
done

installed=0; skipped=0; relinked=0

install_hook() {
  local gitdir="$1" hook="$2" label="$3"
  local src="$HOOKS_DIR/$hook"
  local dest="$gitdir/hooks/$hook"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "skip  (existing non-symlink $hook): $label"
    skipped=$((skipped + 1))
    return
  fi
  [[ -L "$dest" ]] && relinked=$((relinked + 1))
  mkdir -p "$gitdir/hooks"
  ln -sf "$src" "$dest"
  echo "ok    [$hook] $label"
  installed=$((installed + 1))
}

for repo in "$RABBLE_ROOT" "$RABBLE_ROOT"/RaBbLE-*/; do
  repo="${repo%/}"
  gitdir="$repo/.git"
  [[ -d "$gitdir" ]] || continue
  label="${repo#$RABBLE_ROOT/}"
  [[ "$repo" == "$RABBLE_ROOT" ]] && label="RaBbLE-Collective (root)"

  for hook in "${HOOKS[@]}"; do
    install_hook "$gitdir" "$hook" "$label"
  done
done

echo ""
echo "Done — $installed hooks installed/refreshed ($relinked already linked), $skipped skipped."
echo ""
echo "  pre-commit:  blocks CLAUDE.md / CODEX.md / GEMINI.md from staging"
echo "  post-commit: appends provisional feature breadcrumb to token ledger"
echo "               override: bash spells/end-session.sh <feature-slug> [note]"
