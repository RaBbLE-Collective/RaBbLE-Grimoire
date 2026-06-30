#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — grimoire-doctor.sh
# Self-healing drift detector. One command that catches the ways the Grimoire
# rots: broken links, unindexed docs, stale gists, and a stale "door" (the
# Collective-root state block falling behind the session log).
#
# Usage:
#   bash spells/grimoire-doctor.sh            # full report (exit 0 always)
#   bash spells/grimoire-doctor.sh --strict   # exit 1 if any ERROR found (for hooks/CI)
#   bash spells/grimoire-doctor.sh --quiet     # only print problems + summary
#
# Checks:
#   C1 broken-links   internal [..](x.md) / `x.md` refs that don't resolve   ERROR
#   C2 unindexed      docs not reachable from INDEX.md                        WARN
#   C3 stale-gists    a gist's source doc is newer than the gist              WARN
#   C4 stale-door     Collective-root AGENT.md state behind SESSION-LOG       WARN
#
# Remediation is printed inline. Wired into the pre-commit hook (warn-only) so
# drift surfaces the moment it's introduced.
#
# spark ~ grimoire >> the grimoire heals itself // %GRIMOIRE_DOCTOR%
# =============================================================================

set -uo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
STRICT=0; QUIET=0
for a in "$@"; do
  [[ "$a" == "--strict" ]] && STRICT=1
  [[ "$a" == "--quiet" ]] && QUIET=1
done

MAGENTA='\033[38;2;255;45;120m'; CYAN='\033[38;2;0;245;255m'
GREEN='\033[38;2;80;250;123m'; YELLOW='\033[38;2;241;250;140m'
RED='\033[38;2;224;92;111m'; MUTED='\033[38;2;107;104;128m'; RESET='\033[0m'

ERRORS=0; WARNINGS=0
say()  { [[ $QUIET -eq 1 ]] || echo -e "$@"; }
sect() { say ""; say "${MAGENTA}$1${RESET}"; }
err()  { echo -e "  ${RED}✗ $*${RESET}"; ((ERRORS++)) || true; }
wrn()  { echo -e "  ${YELLOW}! $*${RESET}"; ((WARNINGS++)) || true; }
ok()   { say "  ${GREEN}✓ $*${RESET}"; }

cd "$GRIMOIRE_ROOT"
INDEX="$GRIMOIRE_ROOT/INDEX.md"

# Files to ignore for index/connectivity purposes (generated or transient)
ignore_for_index() {
  case "$1" in
    gist/*|log/lessons/*|log/agents/*|log/SESSION-LOG*.md|log/generated/*|\
    log/*/CONTEXT.md|log/*/*/CONTEXT.md|\
    CLAUDE.md|CODEX.md|GEMINI.md) return 0 ;;
    *) return 1 ;;
  esac
}

# ── C1: broken internal links ────────────────────────────────────────────────
# Two conventions coexist: markdown [](path) is FILE-relative; backtick `path.md`
# nav refs are usually ROOT-relative or a bare filename. So a ref is "resolvable"
# if it exists file-relative OR root-relative OR as a basename anywhere. Globs,
# template placeholders ([Member], *), and shell commands (spaces) are skipped.
# Path-qualified refs that resolve nowhere are real breakage (ERROR); bare
# unresolved filenames are treated as illustrative/planned and skipped.
sect "C1 · Broken links in navigation docs"
# Scope to docs whose links agents actually follow. Narrative/historical docs use
# backtick paths illustratively, so checking them all is just noise.
is_nav() {
  case "$(basename "$1")" in
    INDEX.md|AGENT.md|CONTEXT.md|README.md|SPELLS.md) return 0 ;;
    *AgentGuide*.md|*Navigator*.md) return 0 ;;
    *) return 1 ;;
  esac
}
declare -A BASENAME_SET
while IFS= read -r f; do BASENAME_SET["$(basename "$f")"]=1; done \
  < <(find "$GRIMOIRE_ROOT" -name '*.md' -type f)
broken=0
while IFS= read -r f; do
  rel="${f#$GRIMOIRE_ROOT/}"
  is_nav "$rel" || continue
  dir=$(dirname "$rel")
  while IFS= read -r ref; do
    [[ "$ref" == http* || "$ref" == \#* || "$ref" == mailto:* ]] && continue
    ref="${ref%%#*}"; ref="${ref%%\?*}"
    [[ -z "$ref" || "$ref" != *.md ]] && continue
    # skip globs / template placeholders / commands / home / decorators
    case "$ref" in *"*"*|*"["*|*"<"*|*"~"*|*"@"*|*" "*|-*) continue ;; esac
    # resolvable?
    if [[ "$ref" == /* ]]; then
      [[ -f "$GRIMOIRE_ROOT/${ref#/}" ]] && continue
    else
      [[ -f "$(cd "$GRIMOIRE_ROOT/$dir" 2>/dev/null && realpath -m "$ref" 2>/dev/null)" ]] && continue   # file-relative
      [[ -f "$GRIMOIRE_ROOT/$ref" ]] && continue                                                          # root-relative
    fi
    [[ -n "${BASENAME_SET[$(basename -- "$ref")]:-}" ]] && continue                                       # basename anywhere
    if [[ "$ref" == */* ]]; then
      err "$rel → $ref"; ((broken++)) || true       # path-qualified + nowhere = real breakage
    fi
  done < <( { grep -oP '\]\(\K[^)]+' "$f"; grep -oP '`\K[^`]+\.md(?=`)' "$f"; } 2>/dev/null || true)
done < <(find "$GRIMOIRE_ROOT" -name '*.md' -type f ! -path '*/log/generated/*' | sort)
[[ $broken -eq 0 ]] && ok "all path-qualified internal .md links resolve"
[[ $broken -gt 0 ]] && say "  ${MUTED}fix: correct the path, or create the target doc${RESET}"

# ── C2: unindexed docs ───────────────────────────────────────────────────────
sect "C2 · Docs not reachable from INDEX.md"
unindexed=0
while IFS= read -r f; do
  rel="${f#$GRIMOIRE_ROOT/}"
  ignore_for_index "$rel" && continue
  base="$(basename "$rel")"
  if ! grep -qF "$rel" "$INDEX" && ! grep -qF "$base" "$INDEX"; then
    wrn "$rel"
    ((unindexed++)) || true
  fi
done < <(find "$GRIMOIRE_ROOT" -name '*.md' -type f \
            ! -path '*/.git/*' ! -name INDEX.md | sort)
[[ $unindexed -eq 0 ]] && ok "every doc is reachable from INDEX.md"
[[ $unindexed -gt 0 ]] && say "  ${MUTED}fix: add a line under the right section in INDEX.md${RESET}"

# ── C3: stale gists (source newer than gist) ─────────────────────────────────
sect "C3 · Stale gists (source changed after last distill)"
stale=0
for g in gist/*.md; do
  [[ -f "$g" ]] || continue
  src=$(grep -oP '^> Source: `\K[^`]+' "$g" 2>/dev/null | head -1)
  [[ -z "$src" || ! -f "$src" ]] && continue
  if [[ "$src" -nt "$g" ]]; then
    wrn "$(basename "$g")  ← source newer: $src"
    ((stale++)) || true
  fi
done
[[ $stale -eq 0 ]] && ok "all gists current with their sources"
[[ $stale -gt 0 ]] && say "  ${MUTED}fix: bash spells/distill-gists.sh${RESET}"

# ── C4: stale door (Collective-root state behind the session log) ────────────
sect "C4 · The door (Collective AGENT.md) vs SESSION-LOG"
log_s=$(grep -oiP 'Session \K[0-9]+' log/SESSION-LOG.md 2>/dev/null | head -1)
root_agent="$RABBLE_ROOT/AGENT.md"
if [[ -n "$log_s" && -f "$root_agent" ]]; then
  door_s=$(grep -oiP 'S\K[0-9]+' "$root_agent" 2>/dev/null | head -1)
  if [[ -n "$door_s" && "$door_s" -lt "$log_s" ]]; then
    wrn "Collective AGENT.md state ≈ S$door_s but SESSION-LOG is at S$log_s (${MUTED}door is stale${RESET})"
    say "  ${MUTED}fix: update the 'Current State' block in $RABBLE_ROOT/AGENT.md${RESET}"
  else
    ok "door state tracks the session log (S$log_s)"
  fi
else
  ok "skipped (no session number to compare)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
say ""
say "${MAGENTA}════════════════════════════════════════${RESET}"
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GREEN}Grimoire healthy — no drift detected.${RESET}"
else
  echo -e "  ${RED}errors: $ERRORS${RESET}   ${YELLOW}warnings: $WARNINGS${RESET}"
fi
say "${MUTED}Connectivity (orphans/hubs/heaviest): bash spells/graph-grimoire.sh${RESET}"

[[ $STRICT -eq 1 && $ERRORS -gt 0 ]] && exit 1
exit 0
