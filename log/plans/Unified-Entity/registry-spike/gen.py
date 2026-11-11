#!/usr/bin/env python3
"""Spike: one registry expression -> Rust Pose arm, scene.c face_t row, JS EXPR entry, Python EXPR entry,
plus a golden check that parses each surface's current source (read-only) and compares it to the registry.

usage: gen.py REGISTRY EXPR COLLECTIVE_ROOT   (emits, then checks; exit 1 on drift)
"""
import json, re, sys
from pathlib import Path

PARTS = ["eL", "eR", "pL", "pR"]
KEYS = ["dx", "dy", "rot", "sx", "sy"]
DEF = {"dx": 0, "dy": 0, "rot": 0, "sx": 1, "sy": 1}


def full(pose):
    return {p: {k: pose.get(p, {}).get(k, DEF[k]) for k in KEYS} for p in PARTS}


def num(v, style):
    s = repr(float(v)).rstrip("0").rstrip(".") if float(v) != int(v) else str(int(v))
    if style == "rust":
        return s if "." in s else s + ".0"
    if style == "c":
        return (s.replace("0.", ".", 1) if s.startswith(("0.", "-0.")) else s) + ("f" if "." in s else "")
    if style == "js":
        return s.replace("0.", ".", 1) if s.startswith(("0.", "-0.")) else s
    return s


# ---------- emitters ----------
def emit_rust(name, e):
    f = full(e["pose"])
    xf = lambda p: "x(" + ", ".join(num(f[p][k], "rust") for k in KEYS) + ")"
    return (f"Expr::{e['surfaces']['tui']['symbol']} => Pose {{\n"
            f"    e_l: {xf('eL')}, e_r: {xf('eR')},\n"
            f"    p_l: {xf('pL')}, p_r: {xf('pR')},\n}},")


def emit_c(name, e):
    f, h = full(e["pose"]), e.get("head", {})
    def part(p):
        if f[p] == DEF:
            return "P0"
        return "{ " + ", ".join(num(f[p][k], "c") for k in KEYS) + " }"
    head = [h.get("tilt", 0), h.get("dim", 1), h.get("squint", 0), h.get("hop", 0)]
    return (f"static const face_t {e['surfaces']['pocket']['symbol']} = {{ "
            + ", ".join(part(p) for p in PARTS) + ", " + ", ".join(num(v, "c") for v in head) + " };")


def emit_js(name, e):
    pose = e["pose"]
    def part(p):
        d = pose.get(p, {})
        return f"{p}:X({{" + ",".join(f"{k}:{num(d[k], 'js')}" for k in KEYS if k in d) + "})"
    h = e.get("head", {})
    return (f"{e['surfaces']['web']['symbol']}: {{" + ",".join(part(p) for p in PARTS)
            + f",tilt:{num(h.get('tilt', 0), 'js')},gaze:{num(h.get('gaze', 1), 'js')}}},")


def emit_py(name, e):
    pose = e["pose"]
    def part(p):
        d = pose.get(p, {})
        return f'"{p}": _x(' + ", ".join(f"{k}={num(d[k], 'py')}" for k in KEYS if k in d) + ")"
    return f'"{name}": {{' + ", ".join(part(p) for p in PARTS) + "},"


# ---------- source parsers (read-only) ----------
def parse_kv(s):
    return {k: float(v) for k, v in re.findall(r"(\w+)\s*[:=]\s*(-?[\d.]+)", s)}


def src_rust(root, sym):
    t = (root / "RaBbLE-sCoRE/tui/rabble-face/src/face.rs").read_text()
    m = re.search(rf"Expr::{sym} => Pose \{{(.*?)\}},", t, re.S)
    calls = re.findall(r"(e_l|e_r|p_l|p_r):\s*(?:x\(([^)]*)\)|ID)", m.group(1))
    out = {}
    for who, args in calls:
        vals = [float(a) for a in args.split(",")] if args else [DEF[k] for k in KEYS]
        out[{"e_l": "eL", "e_r": "eR", "p_l": "pL", "p_r": "pR"}[who]] = dict(zip(KEYS, vals))
    return {"pose": out}


def src_c(root, sym):
    t = (root / "RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c").read_text()
    m = re.search(rf"static const face_t {sym} = \{{(.*?)\}};", t, re.S)
    body = m.group(1).replace("P0", "{ 0, 0, 0, 1, 1 }").replace("f", "")
    parts = re.findall(r"\{([^}]*)\}", body)
    tail = [float(v) for v in re.sub(r"\{[^}]*\}", "", body).split(",") if v.strip()]
    pose = {p: dict(zip(KEYS, [float(v) for v in parts[i].split(",")])) for i, p in enumerate(PARTS)}
    return {"pose": pose, "head": dict(zip(["tilt", "dim", "squint", "hop"], tail))}


def src_js(root, sym):
    t = (root / "RaBbLE-NeBuLA/src/backends/alive-backend.js").read_text()
    m = re.search(rf"^\s*{sym}:\s*\{{(eL:.*)\}},?\s*$", t, re.M)
    line = m.group(1)
    pose = {p: {**DEF, **parse_kv(re.search(rf"{p}:X\(\{{([^}}]*)\}}\)", line).group(1))} for p in PARTS}
    rest = re.sub(r"\w+:X\(\{[^}]*\}\)", "", line)
    st = re.search(rf"^\s*{sym}:\s*\{{(energy:[^}}]*)\}}", t, re.M)   # STYLE row: body/aura channels
    style = parse_kv(st.group(1)) if st else {}
    return {"pose": pose, "head": {**parse_kv(rest), **{k: style[k] for k in ("dim", "hop") if k in style}}}


def src_py(root, name):
    t = (root / "RaBbLE-sCoRE/ui/face.py").read_text()
    m = re.search(rf'"{name}": \{{(.*?)\}},\n', t, re.S)
    pose = {p: {**DEF, **parse_kv(re.search(rf'"{p}": _x\(([^)]*)\)', m.group(1)).group(1))} for p in PARTS}
    return {"pose": pose}


def compare(label, got, want, eps=1e-9):
    bad = []
    for p in PARTS:
        for k in KEYS:
            if p in got["pose"] and abs(got["pose"][p][k] - want["pose"][p][k]) > eps:
                bad.append(f"{p}.{k}: source {got['pose'][p][k]:g} != registry {want['pose'][p][k]:g}")
    for k, v in got.get("head", {}).items():
        if k in want["head"] and abs(v - want["head"][k]) > eps:
            bad.append(f"head.{k}: source {v:g} != registry {want['head'][k]:g}")
    print(f"  {label:7s} {'OK' if not bad else 'DRIFT'}")
    for b in bad:
        print(f"          {b}")
    return not bad


def main():
    reg, name, root = json.load(open(sys.argv[1])), sys.argv[2], Path(sys.argv[3])
    e = reg["expressions"][name]
    print("--- rust (face.rs)\n" + emit_rust(name, e))
    print("--- c (scene.c)\n" + emit_c(name, e))
    print("--- js (alive-backend.js)\n" + emit_js(name, e))
    print("--- py (face.py)\n" + emit_py(name, e))
    want = {"pose": full(e["pose"]), "head": {**reg["channels"]["head"], **e.get("head", {})}}
    print(f"--- golden: {name} vs current sources")
    s = e["surfaces"]
    ok = all([compare("rust", src_rust(root, s["tui"]["symbol"]), want),
              compare("python", src_py(root, name), want),
              compare("js", src_js(root, s["web"]["symbol"]), want),
              compare("c", src_c(root, s["pocket"]["symbol"]), want)])
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
