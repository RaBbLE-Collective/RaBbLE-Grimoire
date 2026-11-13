#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — harvest-claude.sh : keep Claude Code history beyond its own cleanup
#
# Usage: bash spells/harvest-claude.sh [--archive DIR] [--no-digest]
#        bash spells/harvest-claude.sh --install-timer     (daily systemd user timer)
#
# Copies ~/.claude transcripts, per-project memory, prompt history and stats into the
# archive (default ~/claude-archive, mode 700), then runs digest-claude.py. rsync never
# uses --delete: a file removed from ~/.claude stays in the archive.
# Private: transcripts can hold pasted secrets. Do not commit the archive; gitleaks first.
# =============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCHIVE="$HOME/claude-archive"; DIGEST=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive) ARCHIVE="$2"; shift 2 ;;
    --no-digest) DIGEST=0; shift ;;
    --install-timer)
      unit="$HOME/.config/systemd/user"; mkdir -p "$unit"
      cat > "$unit/rabble-harvest-claude.service" <<EOF
[Unit]
Description=Archive Claude Code history and refresh digest

[Service]
Type=oneshot
ExecStart=/usr/bin/bash $HERE/harvest-claude.sh
EOF
      cat > "$unit/rabble-harvest-claude.timer" <<EOF
[Unit]
Description=Daily Claude Code history harvest

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
EOF
      systemctl --user daemon-reload
      systemctl --user enable --now rabble-harvest-claude.timer
      systemctl --user list-timers rabble-harvest-claude.timer --no-pager
      exit 0 ;;
    -h|--help) sed -n 2,12p "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

SRC="$HOME/.claude"
mkdir -p -m 700 "$ARCHIVE/projects"
rsync -a --include='*/' --include='*.jsonl' --include='memory/***' --exclude='*' "$SRC/projects/" "$ARCHIVE/projects/"
for f in history.jsonl stats-cache.json; do [[ -f "$SRC/$f" ]] && cp -a "$SRC/$f" "$ARCHIVE/$f"; done
# prompt history grows and is rewritten in place: keep dated copies only when it changed
if [[ -f "$SRC/history.jsonl" ]]; then
  mkdir -p "$ARCHIVE/history"
  h=$(sha1sum "$SRC/history.jsonl" | cut -c1-12)
  [[ -e "$ARCHIVE/history/history-$h.jsonl" ]] || cp -a "$SRC/history.jsonl" "$ARCHIVE/history/history-$h.jsonl"
fi
n=$(find "$ARCHIVE/projects" -name '*.jsonl' | wc -l)
echo "harvest: $n transcripts in $ARCHIVE ($(du -sh "$ARCHIVE" | cut -f1))"
(( DIGEST )) && python3 -I "$HERE/digest-claude.py" --archive "$ARCHIVE"
exit 0
