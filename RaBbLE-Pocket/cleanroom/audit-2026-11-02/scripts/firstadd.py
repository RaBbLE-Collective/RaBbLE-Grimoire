#!/usr/bin/env python3
# usage: firstadd.py SDK_ESP32 POCKET_REPO HEAD_TREE_FIRMWARE -> per own-module file: overlap at first-add commit and at HEAD
import sys, os, re, subprocess, importlib.util
spec = importlib.util.spec_from_file_location("ov", os.path.join(os.path.dirname(os.path.abspath(__file__)), "cleanroom-overlap.py"))
ov = importlib.util.module_from_spec(spec); spec.loader.exec_module(ov)
sdk, repo, head = sys.argv[1:4]
ref = ov.sdk_lines(sdk)
def git(*a): return subprocess.run(["git","-C",repo,*a],capture_output=True,text=True,errors="replace").stdout
PAT = re.compile(r"(rabble_ui|ui_theme|rabble_palette|rabble_lv_assert|rabble_beam_score|rabble_motion|rabble_entity|entity_face|rabble_clock_screen|rabble_level_screen|nebula_lite/|rabble_capture|rabble_notes|rabble_outbox|rabble_pomo|rabble_time|panel_bench/|main/app_main\.c|rabble_qmi8658|rabble_pcf85063)")
def meas(text):
    L=list(ov.substantive(text)); m=[l for l in L if l in ref]; return len(L),len(m),m
# all paths ever added under firmware/, with earliest add commit
out = git("log","--all","--reverse","--diff-filter=A","--format=C %h %ad","--date=short","--name-only","--","firmware")
first={}; cur=None
for ln in out.splitlines():
    if ln.startswith("C "): cur=ln[2:]
    elif ln and PAT.search(ln) and ln.endswith(ov.EXT) and "/test/" not in ln and "managed_components" not in ln and "/build" not in ln and "datasheets" not in ln and "/sim/" not in ln:
        first.setdefault(ln,cur)
print("path\tfirst_commit\tdate\tfirst_sub\tfirst_match\tfirst_%\thead_sub\thead_match\thead_%")
flag=[]
for p,c in sorted(first.items()):
    h,d=c.split()
    t=git("show",f"{h}:{p}")
    a=meas(t)
    # find current path (same basename under HEAD tree)
    cand=[os.path.join(dp,f) for dp,_,fs in os.walk(head) for f in fs if f==os.path.basename(p)]
    hp=None
    if cand:
        hp=sorted(cand,key=lambda x:(0 if x.endswith(p.split('firmware/',1)[1]) else 1))[0]
    b=meas(open(hp,errors="replace").read()) if hp else (0,0,[])
    pa=100*a[1]/a[0] if a[0] else 0; pb=100*b[1]/b[0] if b[0] else 0
    mark=" FLAG" if (pa>5 or pb>5) else ""
    print(f"{p}\t{h}\t{d}\t{a[0]}\t{a[1]}\t{pa:.1f}\t{b[0] if hp else '-'}\t{b[1] if hp else '-'}\t{pb:.1f}{mark}")
