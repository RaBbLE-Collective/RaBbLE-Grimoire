import sys, os, importlib.util, subprocess
spec = importlib.util.spec_from_file_location("ov", os.path.join(os.path.dirname(os.path.abspath(__file__)), "cleanroom-overlap.py"))
ov = importlib.util.module_from_spec(spec); spec.loader.exec_module(ov)
ref=ov.sdk_lines(sys.argv[1])
for spec_ in sys.argv[3:]:
    t=subprocess.run(["git","-C",sys.argv[2],"show",spec_],capture_output=True,text=True,errors="replace").stdout
    L=list(ov.substantive(t)); m=[l for l in L if l in ref]
    print(spec_, len(L), len(m), f"{100*len(m)/len(L) if L else 0:.1f}%")
