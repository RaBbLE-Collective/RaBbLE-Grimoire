#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — rotate-session-log.sh
# Keep log/SESSION-LOG.md small: the LATEST box plus recent months stay; every
# older month moves, whole and unedited, to log/archive/sessions/YYYY-MM.md.
#
# Why: the log is append-forever. At S321 it was 824 KB (about 200k tokens), so
# one careless `cat` or a wide grep hit cost more than the rest of the Grimoire's
# orientation path put together. Nothing is deleted: entries only change file.
#
# Usage:
#   bash spells/rotate-session-log.sh              keep the current month (default)
#   bash spells/rotate-session-log.sh --keep 2     keep the current and the previous month
#   bash spells/rotate-session-log.sh --dry-run    report what would move, change nothing
#
# Safe to re-run (a month already archived gets the newly rotated entries added
# at its top, newest first). session-number.sh reads the archive for its floor,
# so archived S-numbers are never handed out again.
# Find an old session: grep -l "Session S142" log/archive/sessions/*.md
#
# harmonize ~ grimoire >> the log keeps this month, the archive keeps the rest // %LOG_ROTATED%
# =============================================================================
set -euo pipefail
GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

keep=1; dry=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep) keep="$2"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -h|--help) sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

KEEP="$keep" DRY="$dry" ROOT="$GRIMOIRE_ROOT" python3 - <<'PY'
import os, re, sys, datetime, tempfile

root = os.environ["ROOT"]; keep = int(os.environ["KEEP"]); dry = os.environ["DRY"] == "1"
log = os.path.join(root, "log", "SESSION-LOG.md")
arch_dir = os.path.join(root, "log", "archive", "sessions")

text = open(log, encoding="utf-8").read()
lines = text.splitlines(keepends=True)

# Split into blocks at every level-2 heading. Block 0 is the file preamble.
blocks, cur = [], []
for ln in lines:
    if ln.startswith("## ") and cur:
        blocks.append(cur); cur = []
    cur.append(ln)
blocks.append(cur)

today = datetime.date.today()
kept_months = set()
y, m = today.year, today.month
for _ in range(max(keep, 1)):
    kept_months.add(f"{y:04d}-{m:02d}")
    m -= 1
    if m == 0: y, m = y - 1, 12

month_re = re.compile(r"^## (?:LATEST\s+\S+\s+)?(\d{4}-\d{2})-\d{2}")
stay, moved, seen_latest = [], {}, False
for i, b in enumerate(blocks):
    head = b[0]
    if i == 0 and not head.startswith("## "):
        stay.append(b); continue
    if head.startswith("## LATEST") and not seen_latest:
        seen_latest = True; stay.append(b); continue      # the live box always stays
    mo = month_re.match(head)
    if not mo or mo.group(1) in kept_months:
        stay.append(b); continue                          # undated sections stay in place
    moved.setdefault(mo.group(1), []).append(b)

n = sum(len(v) for v in moved.values())
if n == 0:
    print("Nothing to rotate: SESSION-LOG.md holds only", ", ".join(sorted(kept_months))); sys.exit(0)

for month in sorted(moved):
    size = sum(len(l.encode()) for b in moved[month] for l in b)
    print(f"  {month}: {len(moved[month]):4d} entries, {size/1024:7.1f} KB -> log/archive/sessions/{month}.md")
if dry:
    print("Dry run: nothing changed."); sys.exit(0)

def atomic_write(path, data):
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
    with os.fdopen(fd, "w", encoding="utf-8") as f: f.write(data)
    os.replace(tmp, path)

os.makedirs(arch_dir, exist_ok=True)
for month, bs in moved.items():
    path = os.path.join(arch_dir, f"{month}.md")
    header = (f"# SESSION-LOG archive: {month}\n\n"
              f"> Rotated out of `log/SESSION-LOG.md` by `spells/rotate-session-log.sh`. Entries are unedited, newest first.\n"
              f"> A `## LATEST` heading in here is a historical box, not the live one.\n\n---\n\n")
    body = "".join("".join(b) for b in bs)
    if not body.endswith("\n"): body += "\n"
    old = ""
    if os.path.exists(path):
        prev = open(path, encoding="utf-8").read()
        old = prev.split("\n---\n\n", 1)[1] if "\n---\n\n" in prev else prev
    atomic_write(path, header + body + old)

new = "".join("".join(b) for b in stay)
pointer = ("> Older months live in `log/archive/sessions/YYYY-MM.md` (rotated by `spells/rotate-session-log.sh`).\n"
           "> Find a session: `grep -l \"Session S142\" log/archive/sessions/*.md`\n")
if "log/archive/sessions/" not in new:
    new = new.replace("\n---\n", "\n" + pointer + "\n---\n", 1)
atomic_write(log, new)
print(f"Rotated {n} entries. SESSION-LOG.md: {len(text.encode())/1024:.0f} KB -> {len(new.encode())/1024:.0f} KB")
PY
