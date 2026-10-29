#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — mine.sh : which dirty files did THIS session write?
#
# Usage: bash spells/mine.sh [repo-dir ...]      (default: every member repo + the Collective root)
#        bash spells/mine.sh --paths [repo-dir]  (only the file paths that are mine, one per line,
#                                                 for:  git add $(bash spells/mine.sh --paths .))
#
# A dirty file whose mtime is BEFORE this session started was not written by this session.
# With other sessions live it may be their work in progress: do not stage it. With none live,
# it is leftover from a finished session (log it, or ask Mark). Reads only; changes nothing.
# Works for any harness lib/session-id.sh recognises (claude, rabble, codex, gemini, ...).
# =============================================================================
set -uo pipefail
GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/session-id.sh
source "$GRIMOIRE_ROOT/spells/lib/session-id.sh"
ROOT="$(dirname "$GRIMOIRE_ROOT")"

paths_only=0; [[ "${1:-}" == "--paths" ]] && { paths_only=1; shift; }
repos=("$@")
if [[ ${#repos[@]} -eq 0 ]]; then
  repos=("$ROOT"); for d in "$ROOT"/RaBbLE-*/; do [[ -d "$d/.git" ]] && repos+=("${d%/}"); done
fi

rec=$(rabble_session_json 2>/dev/null) || { echo "No session detected (plain terminal?): cannot tell mine from theirs." >&2; exit 2; }
start=$(jq -r .started <<<"$rec")
native=$(jq -r '.native_id // ""' <<<"$rec")

# Evidence of what THIS session wrote: Edit/Write targets and the text of its shell commands,
# from its own transcript (claude, rabble). Other harnesses have no transcript here: mtime only,
# and every "mine" is then unverified.
EDITS=$(mktemp); SHELL_TXT=$(mktemp); trap 'rm -f "$EDITS" "$SHELL_TXT"' EXIT
tf=""; [[ -n "$native" ]] && tf=$(ls "$HOME"/.claude/projects/*/"$native".jsonl 2>/dev/null | head -1)
if [[ -n "$tf" ]]; then
  jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
         | if (.name=="Edit" or .name=="Write" or .name=="NotebookEdit") then "F\t\(.input.file_path // "")"
           elif .name=="Bash" then "B\t\(.input.command // "" | gsub("\n";" "))" else empty end' "$tf" 2>/dev/null \
    | awk -F'\t' -v e="$EDITS" -v b="$SHELL_TXT" '$1=="F"{print $2 > e} $1=="B"{print $2 > b}'
  evidence=transcript
else evidence=none; fi
peers=$(rabble_live_peers 2>/dev/null || true)

if [[ $paths_only -eq 0 ]]; then
  [[ $evidence == none ]] && echo "note   : no transcript for this harness: 'mine' below is by modification time only (unverified)"
  echo "you    : $(jq -r '[.harness,.provider,.model]|join(" / ")' <<<"$rec")   since $(date -d "@$start" +%H:%M)"
  if [[ -n "$peers" ]]; then
    echo "live   :"; while IFS=$'\t' read -r id _ st _ h m; do echo "  ${id:0:8}  $h / $m  since $(date -d "@$st" +%H:%M)"; done <<<"$peers"
  else echo "live   : nobody else"; fi
  echo
fi

for r in "${repos[@]}"; do
  [[ -d "$r/.git" || -f "$r/.git" ]] || continue
  mine=(); older=(); unclaimed=()
  while IFS= read -r line; do
    f=${line:3}; f=${f#* -> }; f=${f//\"/}
    [[ "$f" == log/agents/* || "$f" == */__pycache__/* ]] && continue
    abs=$(readlink -f "$r/$f" 2>/dev/null || echo "$r/$f")
    m=$(stat -c %Y "$r/$f" 2>/dev/null || echo "$start")
    if (( m < start )); then older+=("$f")
    elif [[ $evidence == none ]]; then mine+=("$f")                                  # unverified
    elif grep -qxF -- "$abs" "$EDITS" 2>/dev/null; then mine+=("$f")                # I edited/wrote it
    elif grep -qF -- "$f" "$SHELL_TXT" 2>/dev/null; then mine+=("$f")                # named in my shell commands
    else unclaimed+=("$f"); fi                                                       # new since I started, not by me
  done < <(git -C "$r" status --porcelain 2>/dev/null)
  if [[ $paths_only -eq 1 ]]; then printf '%s\n' "${mine[@]}"; continue; fi
  [[ ${#mine[@]} -eq 0 && ${#older[@]} -eq 0 && ${#unclaimed[@]} -eq 0 ]] && continue
  echo "== $(basename "$r")"
  [[ ${#mine[@]}  -gt 0 ]] && { echo "  mine  (${#mine[@]}):";  printf '    %s\n' "${mine[@]:0:12}"; [[ ${#mine[@]} -gt 12 ]] && echo "    ... +$(( ${#mine[@]} - 12 ))"; }
  if [[ ${#unclaimed[@]} -gt 0 ]]; then
    echo "  NOT mine, changed while you ran, no edit of yours (${#unclaimed[@]}): another session's work"
    printf '    %s\n' "${unclaimed[@]:0:12}"; [[ ${#unclaimed[@]} -gt 12 ]] && echo "    ... +$(( ${#unclaimed[@]} - 12 ))"
  fi
  if [[ ${#older[@]} -gt 0 ]]; then
    if [[ -n "$peers" ]]; then echo "  NOT mine, predates you, other sessions live (${#older[@]}): leave them"
    else echo "  NOT mine, predates you, nobody else live (${#older[@]}): leftover; log it or ask"; fi
    printf '    %s\n' "${older[@]:0:12}"; [[ ${#older[@]} -gt 12 ]] && echo "    ... +$(( ${#older[@]} - 12 ))"
  fi
done
exit 0
