#!/usr/bin/env python3
"""Validator for rabble.entity.json (checks V1-V12 of RaBbLE-Entity-Registry-Schema.md section 8, plus V6b).

usage: .venv/bin/python validate.py [REGISTRY_JSON] [--schema PATH] [--palette PATH]
Exit 1 on any error. Warnings (V11 unmeasured, V5 seed poses) do not fail the run.
"""
import json, math, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_REGISTRY = HERE / "rabble.entity.json"
DEFAULT_SCHEMA = HERE / "rabble.entity.schema.json"
DEFAULT_PALETTE = HERE.parent.parent / "RaBbLE-Agent" / "RaBbLE-Palette.md"

W = 87.0
EASING = re.compile(r"^(linear|smoothstep|smootherstep|sine|exp\([0-9.]+\)|spring\([0-9.]+, ?[0-9.]+\))$")
HEX = re.compile(r"#[0-9a-fA-F]{3,8}")
CORE = ["portal.back", "eyes", "portal.front", "infinity"]
BASE_SECTIONS = {"body", "camera", "cut", "colour", "idle", "forms", "moves", "expressions", "states", "conditions", "timelines", "effects", "layers"}
SURFACE_ONLY = {"scale", "screen", "frame", "layers", "support_overrides", "note"}
LIM = {"eye": {"dx_in": (-34, 34), "dy": (-60, 60), "rot_m": (-20, 20), "sx": (0.78, 1.22), "sy": (0.3, 1.22)},
       "portal": {"dx_in": (-40, 40), "dy": (-270, 270), "rot_m": (-22, 22), "sx": (0.78, 1.25), "sy": (0.6, 1.4)}}
POSE_PATHS = {f"{r}.{p}.{k}" for r in ("upper", "lower") for p in ("eye", "portal") for k in ("dx_in", "dy", "rot_m", "sx", "sy")}
ONE_HOT = {"state", "expression", "mood", "condition"}   # kinds whose weights are mutually exclusive or normalised
RUNTIME_TARGETS = {"body.eye.sx", "body.eye.sy", "body.eye.blink", "body.portal.sy", "body.dim", "body.recede"}
SKIP_KEYS = {"label", "note", "sources", "reconciliation", "expression_sources"}


class Result:
    def __init__(self):
        self.errors, self.warnings = [], []
    def err(self, code, msg): self.errors.append((code, msg))
    def warn(self, code, msg): self.warnings.append((code, msg))
    def codes(self): return {c for c, _ in self.errors}


def deep_merge(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        o = dict(a)
        for k, v in b.items():
            o[k] = deep_merge(a[k], v) if k in a else v
        return o
    return b


def walk(o, path=()):
    yield path, o
    if isinstance(o, dict):
        for k, v in o.items():
            yield from walk(v, path + (k,))
    elif isinstance(o, list):
        for i, v in enumerate(o):
            yield from walk(v, path + (i,))


def parse_palette(path):
    keys = set()
    for line in Path(path).read_text().splitlines():
        m = re.search(r"`rabble_color_([a-z_]+)`", line)
        if m and "#" in line:
            keys.add(m.group(1))
    return keys


def resolved_body(data, surface=None):
    body = data["base"]["body"]
    if surface:
        body = deep_merge(body, data["profiles"].get(surface, {}).get("body", {}))
    return body


def resolved_camera(data, surface=None):
    cam = data["base"]["camera"]
    if surface:
        cam = deep_merge(cam, data["profiles"].get(surface, {}).get("camera", {}))
    return cam


# ------------------------------------------------------------------ V1
def v1(data, schema, r):
    from jsonschema import Draft202012Validator
    v = Draft202012Validator(schema)
    for e in sorted(v.iter_errors(data), key=lambda e: list(map(str, e.absolute_path))):
        r.err("V1", "/".join(map(str, e.absolute_path)) + ": " + e.message[:160])


# ------------------------------------------------------------------ V2
def v2(data, r):
    voc = data["vocabulary"]
    def has(kind, i): 
        v = voc.get(kind)
        return (i in v) if v is not None else False
    def need(kind, i, where):
        if not has(kind, i):
            r.err("V2", f"{where}: '{i}' is not a declared {kind}")
    def sources(srcs, where, allow=()):
        for s in srcs:
            if s == "energy": continue
            m = re.match(r"^(input|state|expression|mood|condition|timeline)\.([a-z_0-9]+)$", s)
            if not m: r.err("V2", f"{where}: bad drive source '{s}'")
            else: need(m.group(1), m.group(2), where)
    def sections(b, where):
        for k in b.get("expressions", {}): need("expression", k, f"{where}.expressions")
        st = b.get("states", {})
        for k, v in st.items():
            if k == "blend_tau": continue
            if k == "cues":
                for c, cv in v.items():
                    need("cue", c, f"{where}.states.cues")
                    if "move" in cv: need("move", cv["move"], f"{where}.cue.{c}")
                    if "expression_pulse" in cv: need("expression", cv["expression_pulse"], f"{where}.cue.{c}")
                    if "condition" in cv: need("condition", cv["condition"], f"{where}.cue.{c}")
                    if "effect" in cv: need("effect", cv["effect"], f"{where}.cue.{c}")
                continue
            need("state", k, f"{where}.states")
            for e in (v.get("expression_weights") or {}): need("expression", e, f"{where}.states.{k}")
            if v.get("mood_timeline"): need("timeline", v["mood_timeline"], f"{where}.states.{k}")
            sources([d["from"] for d in v.get("drives", [])], f"{where}.states.{k}")
        for k, v in b.get("conditions", {}).items():
            need("condition", k, f"{where}.conditions")
            if v.get("timeline"): need("timeline", v["timeline"], f"{where}.conditions.{k}")
        for k in b.get("timelines", {}): need("timeline", k, f"{where}.timelines")
        for k in b.get("moves", {}): need("move", k, f"{where}.moves")
        for k in b.get("forms", {}):
            if k != "reach": need("form", k, f"{where}.forms")
        for k in b.get("idle", {}).get("temperament", {}): need("temperament", k, f"{where}.idle.temperament")
    base = data["base"]
    sections(base, "base")
    layer_ids = {l["id"] for l in base["layers"]}
    for l in base["layers"]:
        need("effect", l["effect"], f"layer {l['id']}")
        sources([d["from"] for d in l.get("drives", [])], f"layer {l['id']}")
    for ename, e in base["effects"].items():
        for i in e.get("inputs", []): need("input", i, f"effect {ename}.inputs")
    for pname, p in data["profiles"].items():
        need("surface", pname, "profiles")
        sections(p, f"profiles.{pname}")
        for lk, lv in p.get("layers", {}).items():
            if lk not in layer_ids and lk not in base["effects"]:
                r.err("V2", f"profiles.{pname}.layers: '{lk}' is neither a layer id nor an effect id")
            sources([d["from"] for d in lv.get("drives", [])], f"profiles.{pname}.layers.{lk}")
        for ek in p.get("support_overrides", {}): need("effect", ek, f"profiles.{pname}.support_overrides")
    # aliases
    private = {}
    for surf, tab in data["aliases"].items():
        for priv, canon in tab.items():
            kind, _, ident = canon.partition(".")
            if kind not in voc or not has(kind, ident):
                r.err("V2", f"aliases.{surf}.{priv} -> '{canon}' is not canonical")
            elif priv != ident:
                private[priv] = (surf, canon)
    if private:
        for path, o in walk({k: v for k, v in data.items() if k != "aliases"}):
            toks = []
            if isinstance(o, dict): toks = [k for k in o.keys()]
            elif isinstance(o, str) and not any(p in SKIP_KEYS for p in path if isinstance(p, str)): toks = [o]
            for t in toks:
                if t in private and not any(p in SKIP_KEYS for p in path if isinstance(p, str)):
                    r.err("V2", f"private name '{t}' (alias of {private[t][1]}) appears outside aliases at /{'/'.join(map(str, path))}")


# ------------------------------------------------------------------ V3
def v3(data, schema, palette, r):
    allowed = palette | {"black", "white", "pole"}
    for path, o in walk(data):
        if isinstance(o, str) and HEX.search(o):
            r.err("V3", f"hex colour in /{'/'.join(map(str, path))}: {o[:60]}")
    # colour-valued fields
    effects = data["base"]["effects"]
    def chk(v, where):
        if isinstance(v, str) and v not in allowed:
            r.err("V3", f"{where}: '{v}' is not a Palette key (or black/white/pole)")
    col = data["base"]["colour"]
    for k in ("eye_fill", "eye_outline", "void"):
        if k in col: chk(col[k], f"base.colour.{k}")
    for p in col["poles"]: chk(p, "base.colour.poles")
    for en, e in effects.items():
        for pn, pd in e["params"].items():
            if pd.get("type") == "colour": chk(pd["default"], f"effect {en}.params.{pn}")
    for l in data["base"]["layers"]:
        for pn, pv in l.get("params", {}).items():
            pd = effects.get(l["effect"], {}).get("params", {}).get(pn, {})
            if pd.get("type") == "colour": chk(pv, f"layer {l['id']}.params.{pn}")
    # schema colour pattern must track the Palette
    pat = schema["$defs"]["colour"]["pattern"]
    m = re.match(r"^\^\((.*)\)\$$", pat)
    in_schema = set(m.group(1).split("|")) if m else set()
    if in_schema != allowed:
        r.err("V3", f"schema colour pattern differs from Palette: +{sorted(in_schema - allowed)} -{sorted(allowed - in_schema)}")


# ------------------------------------------------------------------ V4
def resolved_props(body):
    return {"eh": body["eye"]["h"], "sp": body["spacing"], "pw": body["portal"]["w"], "fl": body["portal"]["flatten"]}


def v4(data, r):
    env = data["base"]["body"]["envelope"]
    for surf in [None] + list(data["profiles"]):
        body = resolved_body(data, surf)
        name = surf or "base"
        for k, v in resolved_props(body).items():
            lo, hi = env[k]
            if not lo <= v <= hi: r.err("V4", f"{name}: {k}={v} outside envelope [{lo}, {hi}]")
        py = body["portal_y"]
        lo, hi = py["range"]
        if not lo <= py["default"] <= hi: r.err("V4", f"{name}: portal_y {py['default']} outside range")
        if abs(py["default"] - 1.0) > 1e-9: r.err("V4", f"{name}: rest portal_y must be 1.00 (S353 ruling 16), got {py['default']}")
        if body.get("per_side_offset"): r.err("V4", f"{name}: per_side_offset must be null (S353 ruling 16)")


# ------------------------------------------------------------------ V5 (port of notouch.py / notouch3d.py)
N_PTS = 48


def ell_pts(e):
    cx, cy, rx, ry = e
    return [(cx + rx * math.cos(2 * math.pi * i / N_PTS), cy + ry * math.sin(2 * math.pi * i / N_PTS)) for i in range(N_PTS)]


def inside(p, e, tol=1e-6):
    cx, cy, rx, ry = e
    if rx <= 1e-9 or ry <= 1e-9: return False
    return ((p[0] - cx) / rx) ** 2 + ((p[1] - cy) / ry) ** 2 < 1 - tol


def overlap(a, b):
    return any(inside(p, b) for p in ell_pts(a)) or any(inside(p, a) for p in ell_pts(b))


def smooth(x):
    x = max(0.0, min(1.0, x)); return x * x * (3 - 2 * x)


def smoother(x):
    x = max(0.0, min(1.0, x)); return x * x * x * (x * (6 * x - 15) + 10)


def blink_amt(t, idle):
    per, dip = idle["blink"]["period"], idle["blink"]["dip"]
    p = t % per
    b = math.sin(math.pi * p / dip) if p < dip else 0.0
    lo, hi = idle["blink"]["second_dip"]
    if int(t // per) % idle["blink"]["double_every"] == idle["blink"]["double_every"] - 1 and lo <= p < hi:
        b = math.sin(math.pi * (p - lo) / dip)
    return b


class Rig:
    def __init__(self, body, pose=None):
        self.hh = body["eye"]["h"] * W / 2
        self.erx = W / 2
        self.prx = body["portal"]["w"] * W / 2
        self.pry = self.prx * body["portal"]["flatten"]
        self.x0 = body["spacing"] * W / 2
        py = body["portal_y"]["default"]
        pso = body.get("per_side_offset")
        self.off = {"L": (pso[0] if pso else py) * self.hh, "R": (pso[1] if pso else py) * self.hh}
        self.pose = pose

    def pp(self, role, part):
        if self.pose is None: return dict(dx_in=0, dy=0, rot_m=0, sx=1, sy=1)
        return {**dict(dx_in=0, dy=0, rot_m=0, sx=1, sy=1), **self.pose[role][part]}

    def side(self, sd, up, m=0.0, pk=0.0, z_arc=0.0, bs=1.0, ew=1.0, x_scale=1.0, zx=0.0, anchor=None):
        """one side's eye and portal as projected ellipses plus depth. up: portal starts above the eye.
        m = swap progress (portal travels from its end to the other), bs = eye squash, anchor in [-1,1] of hh."""
        s = -1 if sd == "L" else 1
        u0 = -1 if up else 1
        role = "upper" if up else "lower"
        e, p = self.pp(role, "eye"), self.pp(role, "portal")
        x = s * self.x0 * x_scale
        ery0 = self.hh * e["sy"]
        py = u0 * self.off[sd] * (1 - 2 * m) + p["dy"]
        anc = u0 if anchor is None else anchor
        cy = e["dy"] + anc * ery0 * (1 - bs)
        eye = (x - s * e["dx_in"], cy, self.erx * e["sx"] * ew, ery0 * bs)
        por = (x - s * p["dx_in"], py, self.prx * p["sx"], self.pry * p["sy"])
        return eye, por, ery0, u0

    def evaluate(self, up_l, up_r, **kw):
        """returns list of (kind, detail) violations for one instant. kw may carry per-side dicts."""
        v = []
        sides = {}
        for sd, up in (("L", up_l), ("R", up_r)):
            sides[sd] = self.side(sd, up, **kw.get(sd, {}))
        zE = kw.get("zE", {"L": 0.0, "R": 0.0}); zP = kw.get("zP", {"L": 0.0, "R": 0.0})
        eL, pL = sides["L"][0], sides["L"][1]; eR, pR = sides["R"][0], sides["R"][1]
        ZT = 3.0
        if overlap(eL, eR) and abs(zE["L"] - zE["R"]) <= ZT: v.append(("eye-eye", ""))
        if overlap(pL, pR) and abs(zP["L"] - zP["R"]) <= ZT: v.append(("portal-portal", ""))
        if overlap(eL, pR) and abs(zE["L"] - zP["R"]) <= ZT: v.append(("eye-other-portal", "L eye, R portal"))
        if overlap(eR, pL) and abs(zE["R"] - zP["L"]) <= ZT: v.append(("eye-other-portal", "R eye, L portal"))
        return v, sides

    def rest_checks(self, up_l, up_r):
        v, sides = self.evaluate(up_l, up_r)
        for sd, up in (("L", up_l), ("R", up_r)):
            eye, por, ery0, u0 = sides[sd]
            # eye tip must not pass its own portal plane at rest
            tip = eye[1] + u0 * eye[3]
            if u0 * (por[1] - tip) < -1e-6: v.append(("eye-past-own-plane", f"{sd}: tip {tip:.1f} beyond plane {por[1]:.1f}"))
            # lower-role portal near rim (lower half of its outline) must not overlap its eye
            if u0 > 0:
                cx, cy, rx, ry = por
                for i in range(N_PTS * 2):
                    a = math.pi * i / (N_PTS * 2 - 1)
                    pt = (cx + rx * math.cos(a), cy + ry * math.sin(a))
                    if inside(pt, eye):
                        v.append(("near-rim-over-eye", f"{sd}: lower portal near rim overlaps its eye at rest")); break
        return v


FORMS_GEOM = {"rest/swap": (True, False), "mirror/swap_mirror": (False, True)}


def moves_checks(rig, data, surf):
    idle = data["base"]["idle"]
    mv = data["base"]["moves"]
    out = []
    dt = 1 / 60
    # portal_swap: both portals flip through the eyes, opposite depth signs
    p = mv["portal_swap"]["params"]
    dur = mv["portal_swap"]["duration"]
    for geom, (ul, ur) in FORMS_GEOM.items():
        n = int(round(dur / dt))
        for i in range(n + 1):
            t = i * dt
            m = smooth(t / dur)
            pq = max(0.0, min(1.0, math.sin(math.pi * m) * p["plateau"]["k"]))
            pk = smoother(pq)
            bs = (1 - p["eye_squash_floor"]) * (1 - pk) + p["eye_squash_floor"] if False else (1 - pk)
            ew = 1 + p["width_bulge"] * pk
            kw = {}
            zE = {"L": 0.0, "R": 0.0}; zP = {}
            for sd, up in (("L", ul), ("R", ur)):
                u0 = -1 if up else 1
                kw[sd] = dict(m=m, bs=bs, ew=ew, anchor=u0 * (1 - 2 * m))
                zP[sd] = -u0 * p["arc_fu"] * pk
            kw["zE"], kw["zP"] = zE, zP
            vs, _ = rig.evaluate(ul, ur, **kw)
            for k, d in vs:
                out.append((f"portal_swap {geom} t={t:.3f}", k, d))
    # turn: yaw half-turn about the vertical axis
    dur = mv["turn"]["duration"]
    for geom, (ul, ur) in FORMS_GEOM.items():
        n = int(round(dur / dt))
        for i in range(n + 1):
            th = math.pi * smooth(i * dt / dur)
            c, s_ = math.cos(th), math.sin(th)
            kw = {"L": dict(x_scale=c), "R": dict(x_scale=c)}
            # side x0 sign: L at -x0 -> z = +x0*sin, R -> -x0*sin
            zv = rig.x0 * s_
            kw["zE"] = {"L": zv, "R": -zv}; kw["zP"] = {"L": zv, "R": -zv}
            vs, _ = rig.evaluate(ul, ur, **kw)
            for k, d in vs: out.append((f"turn {geom} t={i*dt:.3f}", k, d))
    # blink: sample the dip windows of three cycles (b == 0 is the rest state, checked separately)
    per = idle["blink"]["period"]
    seen = set()
    for geom, (ul, ur) in FORMS_GEOM.items():
        for i in range(int(round(3 * per / dt))):
            t = i * dt
            b = blink_amt(t, idle)
            if b <= 1e-9: continue
            key = (geom, round(b, 6))
            if key in seen: continue
            seen.add(key)
            bs = 1 - idle["blink"]["squash"] * b
            kw = {sd: dict(bs=bs) for sd in "LR"}
            vs, _ = rig.evaluate(ul, ur, **kw)
            for k, d in vs: out.append((f"blink {geom} t={t:.3f}", k, d))
    return out


def v5(data, r):
    surfaces = [None] + list(data["profiles"])
    for surf in surfaces:
        name = surf or "base"
        body = resolved_body(data, surf)
        rig = Rig(body)
        for geom, (ul, ur) in FORMS_GEOM.items():
            for k, d in rig.rest_checks(ul, ur):
                r.err("V5", f"{name} rest {geom}: {k} {d}")
        seen = set()
        for where, k, d in moves_checks(rig, data, surf):
            key = (k, where.split(" ")[0], where.split(" ")[1])
            if key in seen: continue
            seen.add(key)
            r.err("V5", f"{name} {where}: {k} {d}")
    # seed poses (parked expressions and state poses) at rest: warnings only (Canon 7: only calm is canon)
    body = resolved_body(data, None)
    poses = {f"expression.{k}": v for k, v in data["base"]["expressions"].items() if k != "calm" and "upper" in v}
    for sk, sv in data["base"]["states"].items():
        if isinstance(sv, dict) and "pose" in sv: poses[f"state.{sk}"] = sv["pose"]
    for pn, pose in poses.items():
        rig = Rig(body, pose)
        kinds = set()
        for ul, ur in FORMS_GEOM.values():
            kinds |= {k for k, _ in rig.rest_checks(ul, ur)}
        if kinds: r.warn("V5", f"seed pose {pn} touches at rest (base proportions): {', '.join(sorted(kinds))}")


# ------------------------------------------------------------------ V6
def v6(data, r):
    voc = data["vocabulary"]; surfaces = set(voc["surface"])
    effects = data["base"]["effects"]; layers = data["base"]["layers"]
    if set(voc["effect"]) != set(effects):
        r.err("V6", f"vocabulary.effect and base.effects differ: only vocab {sorted(set(voc['effect']) - set(effects))}, only defined {sorted(set(effects) - set(voc['effect']))}")
    for en, e in effects.items():
        sup = e["support"]
        if set(sup) != surfaces:
            r.err("V6", f"effect {en}: support must list exactly the surfaces (missing {sorted(surfaces - set(sup))}, extra {sorted(set(sup) - surfaces)})")
        if "reduced" in sup.values() and not e.get("reduced"):
            r.err("V6", f"effect {en}: support 'reduced' without reduced overrides")
        for k in e.get("reduced", {}):
            if k not in e["params"]: r.err("V6", f"effect {en}: reduced override '{k}' is not a param")
    for l in layers:
        if l["effect"] not in effects: r.err("V6", f"layer {l['id']}: unknown effect {l['effect']}")
    ids = [l["id"] for l in layers]
    if len(ids) != len(set(ids)): r.err("V6", "duplicate layer ids")
    eyes = [l for l in layers if l["effect"] == "eyes"]
    if not eyes: r.err("V6", "no eyes layer")
    for l in eyes:
        if not l["enabled"]: r.err("V6", "eyes layer disabled in base")
    for pn, p in data["profiles"].items():
        for lk, lv in p.get("layers", {}).items():
            tgt = lk == "eyes" or any(l["id"] == lk and l["effect"] == "eyes" for l in layers)
            if tgt and lv.get("enabled") is False: r.err("V6", f"profile {pn}: eyes disabled")
        if p.get("support_overrides", {}).get("eyes") == "none": r.err("V6", f"profile {pn}: eyes support none")
    for en, e in effects.items():
        if en == "eyes" and "none" in e["support"].values(): r.err("V6", "eyes support none on a surface")
    pos = [i for i, l in enumerate(layers) if l["effect"] in CORE]
    if [layers[i]["effect"] for i in pos] != CORE or pos != list(range(pos[0], pos[0] + len(pos)) if pos else []):
        r.err("V6", f"core group must be contiguous and ordered {CORE}, got {[layers[i]['effect'] for i in pos]} at {pos}")
    # V6b: turn and portal_swap never none
    for mn in ("turn", "portal_swap"):
        sup = data["base"]["moves"].get(mn, {}).get("params", {}).get("support", {})
        if set(sup) != surfaces: r.err("V6", f"move {mn}: support must list every surface")
        for s, v in sup.items():
            if v == "none": r.err("V6b", f"move {mn} is 'none' on {s} (every surface supports a form of turn and portal_swap)")
            if v == "reduced" and not data["base"]["moves"][mn]["params"].get("reduced"):
                r.err("V6b", f"move {mn}: reduced on {s} without reduced overrides")
    for mn, mv in data["base"]["moves"].items():
        sup = mv["params"].get("support")
        if sup is None or set(sup) != surfaces: r.err("V6", f"move {mn}: support must list every surface")


# ------------------------------------------------------------------ V7
def v7(data, r):
    effects = data["base"]["effects"]
    def check(l, extra=None, where=""):
        e = effects.get(l["effect"])
        if not e: return
        for d in l.get("drives", []):
            pn = d["param"]
            if pn == "opacity": lo, hi, base = 0.0, 1.0, l.get("opacity", 1)
            elif pn in e["params"]:
                pd = e["params"][pn]
                if pd["type"] not in ("number", "integer"):
                    r.err("V7", f"layer {l['id']}: drive target {pn} is not numeric"); continue
                lo, hi = pd.get("min"), pd.get("max"); base = l.get("params", {}).get(pn, pd["default"])
            else:
                r.err("V7", f"layer {l['id']}: drive target '{pn}' is not a param of {l['effect']}"); continue
            src = d["from"]
            if src != "energy":
                kind, _, ident = src.partition(".")
                if kind not in data["vocabulary"] or ident not in data["vocabulary"][kind]:
                    r.err("V7", f"layer {l['id']}: drive source {src} not in vocabulary")
        # range at source extremes (sources are 0..1)
        by_param = {}
        for d in l.get("drives", []):
            by_param.setdefault(d["param"], []).append(d)
        for pn, ds in by_param.items():
            if pn == "opacity": lo, hi, base = 0.0, 1.0, l.get("opacity", 1)
            elif pn in e["params"]:
                pd = e["params"][pn]; lo, hi = pd.get("min"), pd.get("max"); base = l.get("params", {}).get(pn, pd["default"])
            else: continue
            groups = {}
            for d in ds:
                kind = d["from"].split(".")[0]
                groups.setdefault(kind if kind in ONE_HOT else d["from"] + "#" + str(id(d)), []).append(d["gain"])
            vmax = vmin = base
            for g in groups.values():
                vmax += max(0, max(g)) if len(g) > 1 or True else 0
                vmin += min(0, min(g))
            # a one-hot group may sit at all zeros, so its contribution is [min(0,min), max(0,max)]
            if (hi is not None and vmax > hi + 1e-9) or (lo is not None and vmin < lo - 1e-9):
                r.err("V7", f"layer {l['id']}: drives on {pn} resolve to [{vmin:.3g}, {vmax:.3g}] outside [{lo}, {hi}]")
    for l in data["base"]["layers"]: check(l)
    layers = {l["id"]: l for l in data["base"]["layers"]}
    for pn, p in data["profiles"].items():
        for lk, lv in p.get("layers", {}).items():
            if "drives" in lv and lk in layers:
                merged = deep_merge(layers[lk], lv); check(merged)


# ------------------------------------------------------------------ V8
def easing_ok(e): return isinstance(e, str) and bool(EASING.match(e))


def v8_timeline(tid, tl, data, r, where):
    dur = tl["duration"]
    layers = {l["id"]: l for l in data["base"]["layers"]}
    effects = data["base"]["effects"]
    if "clock" in tl and not easing_ok(tl["clock"]): r.err("V8", f"{where}: unknown clock easing {tl['clock']}")
    for k, v in (tl.get("params", {}).get("curves") or {}).items():
        if not easing_ok(v): r.err("V8", f"{where}: unknown curve easing {v} ({k})")
    pl = tl.get("params", {}).get("plateau")
    if pl and not easing_ok(pl.get("ease")): r.err("V8", f"{where}: unknown plateau easing")
    for tr in tl["tracks"]:
        keys = tr["keys"]; ts = [k[0] for k in keys]
        if ts != sorted(ts): r.err("V8", f"{where} {tr['target']}: keys not sorted")
        if any(t < 0 or t > dur + 1e-9 for t in ts): r.err("V8", f"{where} {tr['target']}: key outside [0, {dur}]")
        for k in keys:
            if len(k) > 2 and not easing_ok(k[2]): r.err("V8", f"{where} {tr['target']}: unknown easing {k[2]}")
        tg = tr["target"]
        ok = False
        if tg.startswith("layer:"):
            lid, _, prm = tg[6:].partition(".")
            if lid in layers:
                ok = prm == "opacity" or prm in effects.get(layers[lid]["effect"], {}).get("params", {})
        elif tg.startswith("mood."):
            ok = tg[5:] in data["vocabulary"]["mood"]
        elif tg in RUNTIME_TARGETS: ok = True
        else:
            o = data["base"]
            try:
                for part in tg.split("."): o = o[part]
                ok = True
            except (KeyError, TypeError): ok = False
        if not ok: r.err("V8", f"{where}: target '{tg}' is not resolvable")


def v8(data, r):
    for tid, tl in data["base"]["timelines"].items(): v8_timeline(tid, tl, data, r, f"timeline {tid}")
    for mid, tl in data["base"]["moves"].items(): v8_timeline(mid, tl, data, r, f"move {mid}")
    for pn, p in data["profiles"].items():
        for tid, tl in p.get("timelines", {}).items():
            merged = deep_merge(data["base"]["timelines"].get(tid, {"duration": 1, "tracks": []}), tl)
            v8_timeline(tid, merged, data, r, f"profiles.{pn}.timeline {tid}")


# ------------------------------------------------------------------ V9
def pose_check(pose, where, r):
    for role in ("upper", "lower"):
        for part in ("eye", "portal"):
            for k, v in pose.get(role, {}).get(part, {}).items():
                lo, hi = LIM[part][k]
                if not lo <= v <= hi: r.err("V9", f"{where}.{role}.{part}.{k}={v} outside LIM [{lo}, {hi}]")


def v9(data, r):
    for en, e in data["base"]["expressions"].items():
        if "upper" in e and "lower" in e: pose_check(e, f"expression {en}", r)
        elif "curve" not in e: r.err("V9", f"expression {en}: neither pose nor curve")
        if "curve" in e:
            for ch in e["curve"]["channels"]:
                if ch not in POSE_PATHS: r.err("V9", f"expression {en}: curve channel '{ch}' not a pose path")
    for sn, s in data["base"]["states"].items():
        if isinstance(s, dict) and "pose" in s: pose_check(s["pose"], f"state {sn}.pose", r)


# ------------------------------------------------------------------ V10
def schema_has(schema_node, path, schema):
    node = schema["$defs"]["base"]
    for p in path:
        props = node.get("properties", {})
        if p in props: node = props[p]
            
        else: return False
        if "$ref" in node: node = schema["$defs"][node["$ref"].split("/")[-1]]
    return True


def v10(data, schema, r):
    surfaces = set(data["vocabulary"]["surface"])
    base = data["base"]
    for s in surfaces - set(data["profiles"]): r.err("V10", f"missing profile for surface {s}")
    for pn, p in data["profiles"].items():
        if pn not in surfaces: r.err("V10", f"unknown surface profile '{pn}'")
        for k, v in p.items():
            if k in SURFACE_ONLY: continue
            if k not in BASE_SECTIONS:
                r.err("V10", f"profiles.{pn}.{k}: not a base section"); continue
            def rec(ov, bv, path):
                if not isinstance(ov, dict):
                    return
                for kk, vv in ov.items():
                    if isinstance(bv, dict) and kk in bv:
                        rec(vv, bv[kk], path + (kk,))
                    elif k in ("timelines", "moves", "expressions", "states", "conditions", "effects") and len(path) == 0:
                        r.err("V10", f"profiles.{pn}.{k}.{kk}: absent from base (profiles never add names)")
                    elif not schema_has(None, (k,) + path + (kk,), schema):
                        r.err("V10", f"profiles.{pn}: override key {'.'.join((k,) + path + (kk,))} absent from base")
            rec(v, base[k], ())
        if p.get("body", {}).get("per_side_offset"): r.err("V10", f"profiles.{pn}: per_side_offset must not be set (S353 ruling 16)")
    hw = data["profiles"].get("pocket_hw", {}).get("frame", {})
    if hw.get("floor_hz", 60) < 60: r.err("V10", f"pocket_hw floor_hz {hw['floor_hz']} below 60")
    if "floor_hz" not in hw: r.err("V10", "pocket_hw frame.floor_hz missing")


# ------------------------------------------------------------------ V11
def v11(data, root, r):
    budget = data["profiles"].get("pocket_hw", {}).get("frame", {}).get("budget_ms", 14.0)
    unmeasured = []
    for en, e in data["base"]["effects"].items():
        sup = data["profiles"].get("pocket_hw", {}).get("support_overrides", {}).get(en, e["support"].get("pocket_hw"))
        dev = e["cost"].get("device", {})
        if sup == "full":
            if not dev.get("measured"): unmeasured.append(en)
        if dev.get("ms_worst") is not None and dev["ms_worst"] > budget:
            r.err("V11", f"effect {en}: measured worst {dev['ms_worst']} ms over budget {budget} ms")
        if dev.get("measured") and not (Path(root) / dev["measured"]).exists() and dev.get("ms_worst") is None:
            r.err("V11", f"effect {en}: measured file {dev['measured']} not found")
    if unmeasured:
        r.warn("V11", f"{len(unmeasured)} pocket_hw 'full' effects have no cost.device.measured: {', '.join(unmeasured)}")


# ------------------------------------------------------------------ V12
def v12(text, data, r):
    canon = json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    if text != canon: r.err("V12", "file is not canonical (sorted keys, 2-space indent, trailing newline)")


# ------------------------------------------------------------------ driver
def validate_text(text, schema_path=DEFAULT_SCHEMA, palette_path=DEFAULT_PALETTE, root=HERE):
    r = Result()
    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        r.err("V1", f"not JSON: {e}"); return r
    schema = json.loads(Path(schema_path).read_text())
    v1(data, schema, r)
    if r.errors:   # later checks assume the shape
        v12(text, data, r); return r
    palette = parse_palette(palette_path)
    if not palette: r.err("V3", f"no palette keys parsed from {palette_path}")
    v2(data, r); v3(data, schema, palette, r); v4(data, r); v5(data, r); v6(data, r); v7(data, r)
    v8(data, r); v9(data, r); v10(data, schema, r); v11(data, root, r); v12(text, data, r)
    return r


def main(argv):
    path, schema, palette = DEFAULT_REGISTRY, DEFAULT_SCHEMA, DEFAULT_PALETTE
    args = list(argv)
    while args:
        a = args.pop(0)
        if a == "--schema": schema = args.pop(0)
        elif a == "--palette": palette = args.pop(0)
        else: path = a
    path = Path(path)
    r = validate_text(path.read_text(), schema, palette, path.parent)
    for c, m in r.errors: print(f"ERROR {c}: {m}")
    for c, m in r.warnings: print(f"WARN  {c}: {m}")
    checks = ["V%d" % i for i in range(1, 13)] + ["V6b"]
    failed = r.codes()
    print(f"{path.name}: " + " ".join(f"{c}={'FAIL' if c in failed else 'ok'}" for c in checks))
    print(f"{len(r.errors)} error(s), {len(r.warnings)} warning(s)")
    return 1 if r.errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
