#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — sync-insights.sh : give a project its own copy of its Claude context
#
# Usage: bash spells/sync-insights.sh <project-dir>...      e.g. ~/Jobotron3000 ~/GCS ~/Incenergy
#
# For each project, mirrors from ~/claude-archive (run harvest-claude.sh first) into
#   <project>/insights/memory/        the project's Claude memory files
#   <project>/insights/sessions.jsonl its sessions from the digest: dates, models, tokens, your prompts
#   <project>/insights/README.md      what this is
# One-way mirror: Claude Code writes memory to ~/.claude, so edits made inside insights/ are
# overwritten on the next sync. Changes the working tree only: never stages or commits.
# The project owns its context; nothing here is read from or written to the Grimoire.
# Private: sessions.jsonl holds raw prompts. Only put it in a repo that is private or unpushed.
# =============================================================================
set -euo pipefail
ARCHIVE="${CLAUDE_ARCHIVE:-$HOME/claude-archive}"
[[ $# -gt 0 ]] || { sed -n 2,6p "${BASH_SOURCE[0]}"; exit 2; }
[[ -f "$ARCHIVE/digest/sessions.jsonl" ]] || { echo "no digest at $ARCHIVE: run spells/harvest-claude.sh" >&2; exit 1; }

for proj in "$@"; do
  proj="$(cd "$proj" && pwd)"
  slug="$(printf '%s' "$proj" | sed 's#[/.]#-#g')"
  out="$proj/insights"; mkdir -p "$out/memory"
  if [[ -d "$ARCHIVE/projects/$slug/memory" ]]; then
    rsync -a --delete "$ARCHIVE/projects/$slug/memory/" "$out/memory/"
  fi
  python3 -I - "$ARCHIVE/digest/sessions.jsonl" "$proj" "$out/sessions.jsonl" <<'PY'
import json, os, sys
src, proj, dst = sys.argv[1:]
base = os.path.basename(proj)
keep = []
for line in open(src):
    r = json.loads(line)
    cwd = r.get("cwd") or ""
    if cwd == proj or cwd.startswith(proj + "/") or (r.get("source") == "token-viz" and r.get("project") == base):
        keep.append(r)
with open(dst, "w") as f:
    for r in keep:
        f.write(json.dumps(r, ensure_ascii=False) + "\n")
print(f"  {proj}: {len(keep)} sessions")
PY
  cat > "$out/README.md" <<EOF
# insights/

This project's own Claude context, kept inside the project so it does not depend on \`~/.claude\`.

- \`memory/\`: Claude's memory files for this project (user, feedback, project notes)
- \`sessions.jsonl\`: one record per Claude session: dates, models, token counts, files edited, and the prompts typed
- Mirrored by \`RaBbLE-Grimoire/spells/sync-insights.sh\`; edits here are overwritten on the next sync.
- Contains raw prompts. Keep this repo private or unpushed.
EOF
  echo "  $out: $(ls "$out/memory" | wc -l) memory files"
done
