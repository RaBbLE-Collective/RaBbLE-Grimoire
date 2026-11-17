import sys
def rows(fn):
    return [l.rstrip("\n").split("\t") for l in open(fn)]
o=[]
o.append("### A. HEAD (0d3d438, 2026-10-29): per-file, over 5%  (file | lines | substantive | matched | %)\n")
o.append("| file | lines | subst | matched | % |\n|---|---|---|---|---|")
for r in sorted([r for r in rows("out-HEAD.txt") if r[0]=="F" and float(r[5])>5],key=lambda r:-float(r[5])):
    o.append(f"| {r[1]} | {r[2]} | {r[3]} | {r[4]} | {r[5]} |")
o.append("\n### Directory roll-up, HEAD\n\n| dir | files | subst | matched | % |\n|---|---|---|---|---|")
for r in rows("out-HEAD.txt"):
    if r[0]=="D": o.append(f"| {r[1]} | {r[2]} | {r[3]} | {r[4]} | {r[5]} |")
for t,name in (("42ae6d9","42ae6d9 (first appearance of apache/, 2026-10-06)"),("2965c39","2965c39 (6c3b78b^, 2026-10-24)")):
    o.append(f"\n### Directory roll-up, {name}\n\n| dir | files | subst | matched | % |\n|---|---|---|---|---|")
    for r in rows(f"out-{t}.txt"):
        if r[0]=="D": o.append(f"| {r[1]} | {r[2]} | {r[3]} | {r[4]} | {r[5]} |")
o.append("\n### 42ae6d9 files (the OG-derived state), per file\n\n| file | lines | subst | matched | % |\n|---|---|---|---|---|")
for r in sorted([r for r in rows("out-42ae6d9.txt") if r[0]=="F" and r[3]!="0"],key=lambda r:-float(r[5])):
    o.append(f"| {r[1]} | {r[2]} | {r[3]} | {r[4]} | {r[5]} |")
o.append("\n### C. Own-from-the-start modules: first-add vs HEAD\n\n| path (at first-add) | first commit | date | subst | match | % | HEAD subst | HEAD match | HEAD % |\n|---|---|---|---|---|---|---|---|---|")
for r in rows("own-modules.tsv")[1:]:
    o.append("| "+" | ".join(r)+" |")
o.append("\n### 4. 5-line identifier-normalised windows, HEAD, files over 5%\n\n| % | hit/windows | file |\n|---|---|---|")
for r in sorted([r for r in rows("windows.txt") if r[0]=="W" and float(r[1])>5],key=lambda r:-float(r[1])):
    o.append(f"| {r[1]} | {r[2]} | {r[3]} |")
t=[r for r in rows("windows.txt") if r[0]=="T"][0]; o.append(f"\nTotal: {t[1]}% ({t[2]})")
open("tables.md","w").write("\n".join(o)+"\n")
