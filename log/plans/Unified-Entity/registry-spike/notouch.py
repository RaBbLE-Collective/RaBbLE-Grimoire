#!/usr/bin/env python3
"""No-touch audit: for each proportion set, seed pose and form, the smallest gap (face units, front view,
projected outlines) between every pair of parts. Negative = overlap. Also finds the smallest portal offset
that keeps every seed pose clear of touching.

usage: notouch.py POSES_JSON
"""
import json, math, sys

W = 87.0
PROPS = {
    "baseline": dict(eh=3.13, sp=2.11, pw=2.69, fl=0.30, off=(0.93, 0.93)),
    "pocket": dict(eh=2.64, sp=1.95, pw=2.00, fl=0.25, off=(0.86, 0.79)),
}
N = 120


def ell_pts(cx, cy, rx, ry, rot):
    c, s = math.cos(rot), math.sin(rot)
    return [(cx + rx * math.cos(a) * c - ry * math.sin(a) * s, cy + rx * math.cos(a) * s + ry * math.sin(a) * c)
            for a in (2 * math.pi * i / N for i in range(N))]


def inside(p, e):
    cx, cy, rx, ry, rot = e
    dx, dy = p[0] - cx, p[1] - cy
    c, s = math.cos(-rot), math.sin(-rot)
    u, v = dx * c - dy * s, dx * s + dy * c
    return (u / rx) ** 2 + (v / ry) ** 2 < 1


def gap(a, b):
    pa, pb = ell_pts(*a), ell_pts(*b)
    if any(inside(p, b) for p in pa) or any(inside(p, a) for p in pb):
        return -1.0
    return min(math.hypot(p[0] - q[0], p[1] - q[1]) for p in pa for q in pb)


def parts(P, pose, upper, off_scale=None):
    """upper: (left_is_upper, right_is_upper). Returns eL, eR, pL, pR as (cx, cy, rx, ry, rot)."""
    hh = P["eh"] * W / 2
    out = {}
    for side, s, up in (("L", -1, upper[0]), ("R", 1, upper[1])):
        role = "upper" if up else "lower"
        e, p = pose[role]["eye"], pose[role]["portal"]
        off = (off_scale if off_scale is not None else P["off"][0 if s < 0 else 1]) * hh
        u = -1 if up else 1
        x = s * P["sp"] * W / 2
        out["e" + side] = (x - s * e["dx_in"], e["dy"], W / 2 * e["sx"], hh * e["sy"], math.radians(s * e["rot_m"]))
        prx = P["pw"] * W / 2 * p["sx"]
        out["p" + side] = (x - s * p["dx_in"], u * off + p["dy"], prx, P["pw"] * W / 2 * P["fl"] * p["sy"], math.radians(s * p["rot_m"]))
    return out


PAIRS = [("eL", "pL", "eye-own portal"), ("eR", "pR", "eye-own portal"), ("eL", "pR", "eye-other portal"),
         ("eR", "pL", "eye-other portal"), ("eL", "eR", "eye-eye"), ("pL", "pR", "portal-portal")]
GEOMS = {"rest/swap": (True, False), "mirror/swap-mirror": (False, True), "both portals top": (True, True), "both portals bottom": (False, False)}


def audit(P, pose, off_scale=None, geoms=GEOMS):
    worst = {}
    for gname, up in geoms.items():
        g = parts(P, pose, up, off_scale)
        for a, b, kind in PAIRS:
            d = gap(g[a], g[b])
            key = (gname, kind)
            worst[key] = min(worst.get(key, 1e9), d)
    return worst


def main():
    poses = json.load(open(sys.argv[1]))
    seeds = [k for k in poses if k != "listening"]
    for pname, P in PROPS.items():
        print(f"\n== {pname} (as built today) : smallest gap per pair kind, stable forms; '-' = overlap")
        for k in seeds:
            w = audit(P, poses[k], geoms={g: GEOMS[g] for g in ("rest/swap", "mirror/swap-mirror")})
            row = {}
            for (g, kind), d in w.items():
                row[kind] = min(row.get(kind, 1e9), d)
            print(f"  {k:24s} " + "  ".join(f"{kind}: {'-' if v < 0 else f'{v:.0f}'}" for kind, v in row.items()))
        w = audit(P, poses["calm"], geoms={g: GEOMS[g] for g in ("both portals top", "both portals bottom")})
        pp = min(d for (g, kind), d in w.items() if kind == "portal-portal")
        print(f"  unstable (both portals one end), calm: portal-portal {'-' if pp < 0 else f'{pp:.0f}'}")
    print("\n== smallest portal offset (eye half-heights) with every stable-form gap >= 6, Pocket ratios")
    P = PROPS["pocket"]
    for k in seeds:
        found = None
        for i in range(80, 260):
            o = i / 100
            w = audit(P, poses[k], o, geoms={g: GEOMS[g] for g in ("rest/swap", "mirror/swap-mirror")})
            if all(d >= 6 for (g, kind), d in w.items() if kind != "portal-portal"):
                found = o
                break
        print(f"  {k:24s} {found}")


if __name__ == "__main__":
    main()
