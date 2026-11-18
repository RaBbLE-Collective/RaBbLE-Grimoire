#!/usr/bin/env python
"""Web generator: rabble.entity.json -> RaBbLE-NeBuLA/src/registry/entity.generated.js

Run with the registry venv:  registry/entity/.venv/bin/python registry/entity/gen/js.py [--out PATH]

- Runs validate.py first and refuses to emit on any error.
- Resolves Palette colour names to hex values by parsing RaBbLE-Agent/RaBbLE-Palette.md
  (black and white are pure; "pole" stays symbolic: it means the pole colour at the eye's position).
- Emits an ES module: deeply frozen REGISTRY, PALETTE, REGISTRY_VERSION, resolveProfile(name).
- Deterministic: same inputs give a byte-identical file (sorted keys, no timestamps).
"""
import hashlib
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ENTITY = HERE.parent
sys.path.insert(0, str(ENTITY))
import validate  # noqa: E402

COLLECTIVE = ENTITY.parent.parent.parent
REGISTRY = ENTITY / "rabble.entity.json"
SCHEMA = ENTITY / "rabble.entity.schema.json"
PALETTE_MD = COLLECTIVE / "RaBbLE-Grimoire" / "RaBbLE-Agent" / "RaBbLE-Palette.md"
DEFAULT_OUT = COLLECTIVE / "RaBbLE-NeBuLA" / "src" / "registry" / "entity.generated.js"
SOURCE_LABEL = "RaBbLE-Grimoire/registry/entity/rabble.entity.json"
FIXED = {"black": "#000000", "white": "#ffffff"}


def palette_values(path):
    """name -> '#rrggbb' from the Palette tables (`rabble_color_<name>` followed by `#hex` on the row)."""
    out = {}
    for line in Path(path).read_text().splitlines():
        m = re.search(r"`rabble_color_([a-z_]+)`[^#]*`(#[0-9a-fA-F]{6})`", line)
        if m:
            out[m.group(1)] = m.group(2).lower()
    return out


def resolve_colours(data, pal):
    """Replace colour-typed values (names) with hex. 'pole' stays. Mutates data."""
    table = {**pal, **FIXED}

    def res(v):
        if v == "pole":
            return v
        if v not in table:
            raise SystemExit(f"colour '{v}' not in Palette")
        return table[v]

    base = data["base"]
    col = base["colour"]
    for k in ("eye_fill", "eye_outline", "void"):
        if k in col:
            col[k] = res(col[k])
    col["poles"] = [res(p) for p in col["poles"]]

    effects = base["effects"]
    colour_params = {en: {pn for pn, pd in e["params"].items() if pd.get("type") == "colour"} for en, e in effects.items()}
    for en, e in effects.items():
        for pn in colour_params[en]:
            e["params"][pn]["default"] = res(e["params"][pn]["default"])

    def fix_params(params, effect):
        for pn in list(params):
            if pn in colour_params.get(effect, ()):
                params[pn] = res(params[pn])

    layer_effect = {l["id"]: l["effect"] for l in base["layers"]}
    for l in base["layers"]:
        fix_params(l.get("params", {}), l["effect"])
    for p in data["profiles"].values():
        for key, ov in p.get("layers", {}).items():
            effect = layer_effect.get(key, key)
            if "params" in ov:
                fix_params(ov["params"], effect)
    return table


JS_TEMPLATE = r'''// GENERATED FILE. DO NOT EDIT.
// Source:   {source}
// Registry: v{version} ({fmt})
// Palette:  RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md (colour names resolved to hex; "pole" stays symbolic)
// Content hash (sha256, registry + resolved palette): {digest}
// Regenerate: RaBbLE-Grimoire/registry/entity/.venv/bin/python RaBbLE-Grimoire/registry/entity/gen/js.py
// Edit the registry (or the Palette), then regenerate. Never hand-edit this file.

function deepFreeze(o) {{
  if (o && typeof o === 'object' && !Object.isFrozen(o)) {{
    Object.freeze(o);
    for (const k of Object.keys(o)) deepFreeze(o[k]);
  }}
  return o;
}}

const isObj = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
function deepMerge(a, b) {{
  if (!isObj(a) || !isObj(b)) return b;
  const o = {{ ...a }};
  for (const k of Object.keys(b)) o[k] = k in a ? deepMerge(a[k], b[k]) : b[k];
  return o;
}}
const clone = (v) => JSON.parse(JSON.stringify(v));

export const REGISTRY_VERSION = {version_js};

export const PALETTE = deepFreeze({palette_js});

export const REGISTRY = deepFreeze({registry_js});

const SECTIONS = ['body', 'camera', 'colour', 'cut'];

/**
 * Base merged with one surface profile's overrides.
 * - body, camera, colour, cut: deep-merged over base.
 * - layers: profile.layers is keyed by layer id or effect id; matching layers are deep-merged
 *   (enabled, blend, opacity, params). Returns the ordered layer array.
 * - timelines: profile timelines deep-merge over the base timeline of the same name (track lists replace).
 * - frame, scale, screen, note: profile-only keys, copied as given.
 * - support: effect id -> support for this surface (profile support_overrides over the effect's own).
 * Returns a deep-frozen object; unknown profile name throws.
 */
export function resolveProfile(name) {{
  const p = REGISTRY.profiles[name];
  if (!p) throw new Error('entity registry: unknown profile ' + name);
  const base = REGISTRY.base;
  const out = {{ name, version: REGISTRY_VERSION }};
  for (const s of SECTIONS) out[s] = deepMerge(clone(base[s]), p[s] || {{}});
  out.timelines = deepMerge(clone(base.timelines), p.timelines || {{}});
  out.layers = clone(base.layers).map((l) => {{
    let m = l;
    for (const key of [l.effect, l.id]) if (p.layers && p.layers[key]) m = deepMerge(m, clone(p.layers[key]));
    return m;
  }});
  out.support = {{}};
  for (const [en, e] of Object.entries(base.effects)) {{
    const ov = p.support_overrides && p.support_overrides[en];
    out.support[en] = ov !== undefined ? ov : e.support[name];
  }}
  for (const k of ['frame', 'scale', 'screen', 'note']) if (p[k] !== undefined) out[k] = clone(p[k]);
  return deepFreeze(out);
}}
'''


def js(v):
    return json.dumps(v, indent=2, sort_keys=True, ensure_ascii=False)


def build(out_path):
    text = REGISTRY.read_text()
    r = validate.validate_text(text, SCHEMA, PALETTE_MD, ENTITY)
    if r.errors:
        for c, m in r.errors:
            print(f"ERROR {c}: {m}", file=sys.stderr)
        print("registry has errors; refusing to emit", file=sys.stderr)
        return 1
    data = json.loads(text)
    pal = palette_values(PALETTE_MD)
    table = resolve_colours(data, pal)
    palette_out = {k: table[k] for k in sorted(table)}
    digest = hashlib.sha256(text.encode() + b"\0" + js(palette_out).encode()).hexdigest()[:16]
    body = JS_TEMPLATE.format(
        source=SOURCE_LABEL, version=data["version"], fmt=data["format"], digest=digest,
        version_js=json.dumps(data["version"]), palette_js=js(palette_out),
        registry_js=js(data),
    )
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(body)
    print(f"wrote {out_path} (v{data['version']}, hash {digest}, {len(body)} bytes)")
    return 0


if __name__ == "__main__":
    args = sys.argv[1:]
    out = DEFAULT_OUT
    if args[:1] == ["--out"]:
        out = args[1]
    sys.exit(build(out))
