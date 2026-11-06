#!/usr/bin/env python3
# usage: generic.py SDK_ESP32 HEAD_FIRMWARE THIRD_DIR... : of HEAD lines matching SDK, how many also occur in third-party (IDF/managed) C sources
import sys, os, importlib.util
spec = importlib.util.spec_from_file_location("ov", os.path.join(os.path.dirname(os.path.abspath(__file__)), "cleanroom-overlap.py"))
ov = importlib.util.module_from_spec(spec); spec.loader.exec_module(ov)
ref=ov.sdk_lines(sys.argv[1]); third=set()
for d in sys.argv[3:]:
    for dp,dn,fn in os.walk(d):
        for f in fn:
            if f.endswith(ov.EXT):
                try: third.update(ov.substantive(open(os.path.join(dp,f),errors="replace").read()))
                except OSError: pass
tot=m=g=0; perfile=[]
for dp,dn,fn in os.walk(sys.argv[2]):
    rel=os.path.relpath(dp,sys.argv[2])
    if rel.startswith("test") or "datasheets" in rel or "managed_components" in rel: dn[:]=[]; continue
    for f in fn:
        if f.endswith(ov.EXT):
            L=list(ov.substantive(open(os.path.join(dp,f),errors="replace").read())); mm=[l for l in L if l in ref]; gg=[l for l in mm if l in third]
            tot+=len(L); m+=len(mm); g+=len(gg)
            if L: perfile.append((f,len(L),len(mm),len(gg),100*(len(mm)-len(gg))/len(L)))
print(f"total_sub={tot} sdk_match={m} ({100*m/tot:.1f}%) also_in_third_party={g} residual={m-g} ({100*(m-g)/tot:.1f}%)")
for p in sorted(perfile,key=lambda x:-x[4])[:12]: print("%-32s sub=%d match=%d generic=%d residual%%=%.1f"%p)
