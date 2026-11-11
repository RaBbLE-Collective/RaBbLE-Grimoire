#!/usr/bin/env python3
"""Per-file git record for the Pocket split manifest. Run in the Pocket repo: gitrecord.py OUT.md
Classes come only from `git log --follow` chains:
  predates   first add before the SDK clone (2026-10-05) and no port commit touched it
  cr-added   first added by a clean-room wave commit (W#): the file is the clean-room output
  own        first add after the port, no port commit in its chain
  ported-cr  a port commit (S242/S243) is in its chain AND a cleanroom commit (W#) came later
  ported-open a port commit is in its chain, no cleanroom commit: ancestry unresolved
Git cannot show what the author read; ported-open and own rows still need transcripts for influence."""
import re, subprocess, sys
def git(*a): return subprocess.run(["git",*a],capture_output=True,text=True,check=True).stdout
PORT = re.compile(r"%S24[23]_")
CR = re.compile(r"pocket/cleanroom|clean room|clean-room", re.I)
WAVE = re.compile(r"\bW(\d+)\b")
files = git("ls-files").splitlines()
rows=[]
for f in files:
    log = git("log","--follow","--format=%h\t%ad\t%s","--date=short","--",f).splitlines()
    if not log: continue
    ch=[l.split("\t",2) for l in log]  # newest first
    first=ch[-1]
    port=[c for c in ch if PORT.search(c[2])]
    cr=[c for c in ch if CR.search(c[2]) and not c[2].startswith("harmonize ~ pocket/cleanroom >> new-horizons'")
        and "audit" not in c[2][:80] and not re.search(r"\bW7\b",c[2])]  # W7 = header sweep, not a rewrite
    waves=sorted({m.group(1) for c in cr for m in [WAVE.search(c[2])] if m})
    # a clean-room commit counts only if it is newer than the oldest port commit
    cr_after = [c for c in cr if port and ch.index(c) < ch.index(port[-1])]
    if port and cr_after: cls="ported-cr"
    elif port: cls="ported-open"
    elif first[1] < "2026-10-05": cls="predates"
    elif CR.search(first[2]) and WAVE.search(first[2]): cls="cr-added"
    else: cls="own"
    rows.append((f,cls,first[0],first[1],len(ch),",".join("W"+w for w in waves),
                 ",".join(c[0] for c in port[:3]),ch[0][0]))
from collections import Counter
cnt=Counter(r[1] for r in rows)
with open(sys.argv[1],"w") as o:
    o.write("# Pocket split manifest, git record (generated, untracked)\n\n")
    o.write("Source: `git log --follow` per tracked file at "+git("rev-parse","--short","HEAD").strip()+". See gitrecord.py docstring for the classes and their limits.\n\n")
    o.write("| class | files |\n|---|---|\n"+"".join(f"| {k} | {v} |\n" for k,v in sorted(cnt.items())))
    o.write("\n| path | class | first add | first commit | commits | cleanroom waves | port commits | latest |\n|---|---|---|---|---|---|---|---|\n")
    for r in sorted(rows,key=lambda r:(r[1],r[0])):
        o.write(f"| {r[0]} | {r[1]} | {r[3]} | {r[2]} | {r[4]} | {r[5]} | {r[6]} | {r[7]} |\n")
print(dict(cnt))
