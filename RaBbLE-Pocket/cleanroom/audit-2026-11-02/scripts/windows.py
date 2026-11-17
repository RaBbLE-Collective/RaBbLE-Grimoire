#!/usr/bin/env python3
# usage: windows.py SDK_ESP32 HEAD_FIRMWARE : fraction of 5-line sliding windows (substantive lines, identifiers->ID, C keywords kept, numbers kept) found in SDK
import sys, os, re, importlib.util
spec = importlib.util.spec_from_file_location("ov", os.path.join(os.path.dirname(os.path.abspath(__file__)), "cleanroom-overlap.py"))
ov = importlib.util.module_from_spec(spec); spec.loader.exec_module(ov)
KW=set("auto break case char const continue default do double else enum extern float for goto if inline int long register return short signed sizeof static struct switch typedef union unsigned void volatile while bool true false NULL uint8_t uint16_t uint32_t uint64_t int8_t int16_t int32_t int64_t size_t".split())
ID=re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
def nl(l): return ID.sub(lambda m: m.group(0) if m.group(0) in KW else "ID", l)
def wins(path):
    L=[nl(l) for l in ov.substantive(open(path,errors="replace").read())]
    return [" \n".join(L[i:i+5]) for i in range(len(L)-4)]
sdk,root=sys.argv[1:3]
ref=set()
for dp,dn,fn in os.walk(sdk):
    dn[:]=[d for d in dn if not d.startswith("build") and d not in("avatar",".git","managed_components")]
    for f in fn:
        if f.endswith(ov.EXT): ref.update(wins(os.path.join(dp,f)))
tw=th=0
for dp,dn,fn in os.walk(root):
    rel=os.path.relpath(dp,root)
    if rel.startswith("test") or "managed_components" in rel or "datasheets" in rel: dn[:]=[]; continue
    for f in sorted(fn):
        if f.endswith(ov.EXT):
            w=wins(os.path.join(dp,f)); h=sum(x in ref for x in w); tw+=len(w); th+=h
            if w: print(f"W\t{100*h/len(w):.1f}\t{h}/{len(w)}\t{os.path.relpath(os.path.join(dp,f),root)}")
print(f"T\t{100*th/tw:.1f}\t{th}/{tw}\tTOTAL")
