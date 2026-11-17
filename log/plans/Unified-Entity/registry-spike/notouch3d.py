#!/usr/bin/env python3
"""No-touch audit in body space: portals are discs in (tilted) planes, eyes are upright pills.
Gap to the own portal = eye tip to the portal plane, along the eye's axis (minus a tilt allowance).
Other pairs: horizontal and vertical clearance between solids. Negative = touching.

usage: notouch3d.py POSES_JSON
"""
import json, math, sys
sys.path.insert(0, __file__.rsplit("/", 1)[0])
from notouch import PROPS, W

GEOMS = {"rest/swap": (True, False), "mirror/swap-mirror": (False, True), "both top": (True, True), "both bottom": (False, False)}


def solids(P, pose, up, hover):
    hh = P["eh"] * W / 2
    out = {}
    for side, s, u_up in (("L", -1, up[0]), ("R", 1, up[1])):
        role = "upper" if u_up else "lower"
        e, p = pose[role]["eye"], pose[role]["portal"]
        u = -1 if u_up else 1
        off = hh + hover
        x = s * P["sp"] * W / 2
        out["e" + side] = dict(x=x - s * e["dx_in"], y=e["dy"], hh=hh * e["sy"], r=W / 2 * e["sx"], rot=math.radians(s * e["rot_m"]), u=u)
        out["p" + side] = dict(x=x - s * p["dx_in"], y=u * off + p["dy"], R=P["pw"] * W / 2 * p["sx"], rot=math.radians(s * p["rot_m"]))
    return out


def own_gap(e, p):
    yp = p["y"] + math.tan(p["rot"]) * (e["x"] - p["x"])
    tip = e["y"] + e["u"] * e["hh"]
    return e["u"] * (yp - tip) - abs(math.sin(p["rot"] - e["rot"])) * e["r"]


def span_gap(lo1, hi1, lo2, hi2):
    return max(0.0, max(lo1, lo2) - min(hi1, hi2))


def eye_portal_gap(e, p):
    dv = span_gap(e["y"] - e["hh"], e["y"] + e["hh"], p["y"], p["y"])
    dh = abs(e["x"] - p["x"]) - p["R"] - e["r"]
    return -1.0 if dv == 0 and dh < 0 else math.hypot(max(dh, 0), dv)


def eye_eye_gap(a, b):
    dv = span_gap(a["y"] - a["hh"], a["y"] + a["hh"], b["y"] - b["hh"], b["y"] + b["hh"])
    dh = abs(a["x"] - b["x"]) - a["r"] - b["r"]
    return -1.0 if dv == 0 and dh < 0 else math.hypot(max(dh, 0), dv)


def portal_gap(a, b):
    dh = abs(a["x"] - b["x"]) - a["R"] - b["R"]
    dv = abs(a["y"] - b["y"])
    return (dv if dv > 3 else -1.0) if dh < 0 else math.hypot(dh, dv)


def audit(P, pose, hover, geoms):
    res = {}
    for g in geoms:
        S = solids(P, pose, GEOMS[g], hover)
        for kind, d in (("own portal", min(own_gap(S["eL"], S["pL"]), own_gap(S["eR"], S["pR"]))),
                        ("other portal", min(eye_portal_gap(S["eL"], S["pR"]), eye_portal_gap(S["eR"], S["pL"]))),
                        ("eye-eye", eye_eye_gap(S["eL"], S["eR"])),
                        ("portal-portal", portal_gap(S["pL"], S["pR"]))):
            res[kind] = min(res.get(kind, 1e9), d)
    return res


def main():
    poses = json.load(open(sys.argv[1]))
    P = PROPS["pocket"]
    seeds = [k for k in poses if k != "listening"]
    for hover in (0, 6, 12):
        print(f"\n== Pocket ratios, hover gap {hover} face units at rest (stable forms)")
        for k in seeds:
            r = audit(P, poses[k], hover, ("rest/swap", "mirror/swap-mirror"))
            print(f"  {k:24s} " + "  ".join(f"{n}: {'TOUCH' if v < 0 else f'{v:.0f}'}" for n, v in r.items()))
    r = audit(P, poses["calm"], 6, ("both top", "both bottom"))
    print(f"\nunstable forms (both portals at one end), calm, hover 6: portal-portal {'TOUCH' if r['portal-portal'] < 0 else round(r['portal-portal'])}")
    print("\nsmallest rest hover (face units) so every stable-form gap >= 0 for each seed:")
    for k in seeds:
        h = next((h for h in range(0, 120) if min(audit(P, poses[k], h, ("rest/swap", "mirror/swap-mirror")).values()) >= 0), None)
        print(f"  {k:24s} {h}")


if __name__ == "__main__":
    main()
