#!/usr/bin/env python3
# usage: measure.py SDK_ESP32 TREE_FIRMWARE_DIR  -> per-file TSV + matched lines (metric = unmodified cleanroom-overlap.py functions)
import sys, os, importlib.util, collections
spec = importlib.util.spec_from_file_location("ov", os.path.join(os.path.dirname(os.path.abspath(__file__)), "cleanroom-overlap.py"))
ov = importlib.util.module_from_spec(spec); spec.loader.exec_module(ov)
sdk, root = sys.argv[1], sys.argv[2]
show = len(sys.argv) > 3
ref = ov.sdk_lines(sdk)
SKIP = ("managed_components", "build", "datasheets", os.sep+"test"+os.sep)
rows = []
for dp, dn, fn in os.walk(root):
    dn[:] = [d for d in dn if not d.startswith("build") and d not in ("managed_components","datasheets")]
    rel = os.path.relpath(dp, root)
    if rel == "test" or rel.startswith("test"+os.sep): dn[:] = []; continue
    for f in sorted(fn):
        if not f.endswith(ov.EXT): continue
        p = os.path.join(dp, f)
        L = list(ov.substantive(open(p, errors="replace").read()))
        m = [l for l in L if l in ref]
        rows.append((os.path.relpath(p, root), len(open(p,errors="replace").read().splitlines()), len(L), len(m), m))
for r in sorted(rows):
    print(f"F\t{r[0]}\t{r[1]}\t{r[2]}\t{r[3]}\t{100*r[3]/r[2] if r[2] else 0:.1f}")
agg = collections.defaultdict(lambda:[0,0,0])
for r in rows:
    parts = r[0].split(os.sep); keys = [parts[0]] + ([parts[0]+"/"+parts[1]] if len(parts)>2 else [])
    for k in keys+["TOTAL"]:
        agg[k][0]+=r[2]; agg[k][1]+=r[3]
        agg[k][2]+=1
for k,v in sorted(agg.items()):
    print(f"D\t{k}\t{v[2]}files\t{v[0]}\t{v[1]}\t{100*v[1]/v[0] if v[0] else 0:.1f}")
if show:
    for r in rows:
        if r[2] and 100*r[3]/r[2] > 5:
            print("M\t"+r[0])
            for l in r[4]: print("M\t  | "+l)
