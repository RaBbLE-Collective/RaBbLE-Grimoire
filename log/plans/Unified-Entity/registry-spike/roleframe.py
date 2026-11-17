#!/usr/bin/env python3
"""Spike 2: bootstrap a role-frame registry from today's pose tables, render it in every interior form,
and check (a) Rest reproduces each surface's table, (b) canon holds in every stable form.

usage: roleframe.py COLLECTIVE_ROOT OUT_JSON
"""
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import gen  # parsers from spike 1

KEYS = gen.KEYS
POR_OFF = 126.0
MARGIN = 24.0   # alive-backend.js:349 portal-side hysteresis
EL, ER, PL, PR = 8, 4, 2, 1
REST = ER | PL
FORMS = {"rest": REST, "swap": EL | PL, "mirror": ER | PR, "swap_mirror": EL | PR}
NAMES = ["calm", "joy", "sad", "angry", "listening", "speaking"]
SYM = {"calm": ("Calm", "F_CALM"), "joy": ("Joy", "F_JOY"), "sad": ("Sad", "F_SAD"), "angry": ("Angry", None),
       "listening": ("Listening", "F_LISTEN"), "speaking": ("Speaking", "F_SPEAK")}


def to_role(xf, s):
    """absolute part transform on side s (-1 left, +1 right) -> side-free role values"""
    return {"dx_in": -s * xf["dx"], "dy": xf["dy"], "rot_m": s * xf["rot"], "sx": xf["sx"], "sy": xf["sy"]}


def from_role(rv, s):
    return {"dx": -s * rv["dx_in"], "dy": rv["dy"], "rot": s * rv["rot_m"], "sx": rv["sx"], "sy": rv["sy"]}


def bootstrap(pose_abs):
    """Rest form: left is the upper role (portal on top), right the lower role."""
    return {"upper": {"eye": to_role(pose_abs["eL"], -1), "portal": to_role(pose_abs["pL"], -1)},
            "lower": {"eye": to_role(pose_abs["eR"], 1), "portal": to_role(pose_abs["pR"], 1)}}


def render(role_pose, form):
    """role-frame pose + interior word -> absolute pose per side, plus each side's portal sign u"""
    out, u = {}, {}
    for side, s, pbit, ekey, pkey in (("L", -1, PL, "eL", "pL"), ("R", 1, PR, "eR", "pR")):
        role = "upper" if form & pbit else "lower"
        out[ekey] = from_role(role_pose[role]["eye"], s)
        out[pkey] = from_role(role_pose[role]["portal"], s)
        u[side] = -1 if form & pbit else 1
    return out, u


def canon(pose_abs, u):
    """portal stays on its own side of its eye, by at least MARGIN (no crossing: flips are interior moves)"""
    bad = []
    for side, ek, pk in (("L", "eL", "pL"), ("R", "eR", "pR")):
        rel = (u[side] * POR_OFF + pose_abs[pk]["dy"]) - pose_abs[ek]["dy"]
        if rel * u[side] < MARGIN:
            bad.append(f"{side} portal at {rel:+.0f} from its eye (must stay {'above' if u[side] < 0 else 'below'} by {MARGIN:g})")
    return bad


def close(a, b):
    return all(abs(a[p][k] - b[p][k]) < 1e-9 for p in gen.PARTS for k in KEYS)


def main():
    root = Path(sys.argv[1])
    reg, ok = {}, True
    for n in NAMES:
        rs, cs = SYM[n]
        rust = gen.src_rust(root, rs)["pose"]
        reg[n] = bootstrap(rust)
        rest_abs, _ = render(reg[n], REST)
        line = [f"{n:10s} rest==rust {'OK' if close(rest_abs, rust) else 'FAIL'}"]
        ok &= close(rest_abs, rust)
        for label, got in (("py", gen.src_py(root, n)["pose"]), ("js", gen.src_js(root, n)["pose"]),
                           ("c", gen.src_c(root, cs)["pose"] if cs else None)):
            if got is None:
                line.append(f"{label}:absent")
            else:
                same = close(rest_abs, got)
                line.append(f"{label}:{'OK' if same else 'DIFF'}")
                ok &= same or (label == "c" and n == "listening")
        print("  ".join(line))
    # Pocket's listening, as its own candidate pose
    reg["listening_spread_pocket"] = bootstrap(gen.src_c(root, "F_LISTEN")["pose"])
    print("\ncanon (portal never crosses its eye) in each stable form:")
    for n, rp in reg.items():
        res = []
        for fname, w in FORMS.items():
            pa, u = render(rp, w)
            b = canon(pa, u)
            res.append(f"{fname}:{'ok' if not b else 'BREAK'}")
        print(f"  {n:24s} " + " ".join(res))
        pa, u = render(rp, REST)
        for b in canon(pa, u):
            print(f"  {'':24s} rest: {b}")
    json.dump(reg, open(sys.argv[2], "w"), indent=1)
    print(f"\nrole-frame poses written to {sys.argv[2]}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
