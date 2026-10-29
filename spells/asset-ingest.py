#!/usr/bin/env python3
"""asset-ingest.py — engine behind spells/asset-ingest.sh

Grimoire holds the INDEX (tracked sidecars in RaBbLE-SiGiL/index/); the BYTES live in
the git-ignored content-addressed store RaBbLE-SiGiL/store/. Provenance is the
primary axis: human | captured | ai.
"""
import argparse, datetime, hashlib, json, os, re, shutil, sys
from pathlib import Path

import yaml
from PIL import Image

GRIMOIRE = Path(__file__).resolve().parent.parent
DOCS = GRIMOIRE / "RaBbLE-SiGiL"
STORE = Path(os.environ.get("RABBLE_ASSETS", DOCS / "store"))  # git-ignored
INDEX = DOCS / "index"
PROVENANCE = ("human", "captured", "ai")
ROLES = ("logo", "wordmark", "entity", "scene", "ui", "texture", "marketing",
         "study", "sketch", "photo", "icon", "other")
IMG = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tif", ".tiff"}
KIND = {**{e: "image" for e in IMG}, ".svg": "vector", ".mp4": "video", ".webm": "video",
        ".mov": "video", ".wav": "audio", ".mp3": "audio", ".ogg": "audio", ".pdf": "document",
        ".glb": "3d", ".gltf": "3d", ".blend": "3d", ".psd": "layered", ".ai": "layered",
        ".kra": "layered", ".afdesign": "layered"}
RIGHTS = {  # default rights per provenance; Mark confirms at review
    "human": "collective-original",
    "captured": "collective-original",
    "ai": "ai-generated-review",
}


def sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def slugify(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:48] or "asset"


def palette(im: Image.Image, n=5):
    sm = im.convert("RGBA").resize((64, 64))
    if not any(sm.tobytes()[3::4][i] > 32 for i in range(64 * 64)):
        return []
    q = sm.convert("RGB").quantize(colors=n, method=Image.Quantize.MEDIANCUT)
    pal = q.getpalette()[: n * 3]
    cnt = sorted(q.getcolors(), reverse=True)
    return ["#%02x%02x%02x" % tuple(pal[i * 3: i * 3 + 3]) for _, i in cnt][:n]


def probe(p: Path) -> dict:
    ext = p.suffix.lower()
    info = {"kind": KIND.get(ext, "other"), "format": ext.lstrip("."), "bytes": p.stat().st_size}
    if ext in IMG:
        try:
            with Image.open(p) as im:
                info["width"], info["height"] = im.size
                info["alpha"] = "A" in im.getbands() or "transparency" in im.info
                info["animated"] = getattr(im, "is_animated", False)
                im.seek(0)
                info["palette"] = palette(im)
        except Exception as e:  # unreadable image still ingests
            info["probe_error"] = str(e)
    return info


def find_by_hash(h: str):
    for y in INDEX.rglob("*.yml"):
        if y.name.startswith(h[:12]):
            return y
    return None


def ingest_one(src: Path, a) -> str:
    h = sha256(src)
    prov = a.provenance
    dup = find_by_hash(h)
    if dup:
        return f"dup   {src.name} == {dup.relative_to(GRIMOIRE)}"
    info = probe(src)
    ext = src.suffix.lower()
    year = datetime.date.fromtimestamp(src.stat().st_mtime).year
    slug = slugify(a.title or src.stem)
    rel = Path(prov) / str(year) / f"{h[:12]}-{slug}{ext}"
    side = INDEX / prov / f"{h[:12]}-{slug}.yml"
    meta = {
        "id": h[:12], "sha256": h, "title": a.title or src.stem,
        "provenance": prov, "role": a.role, "status": "draft",
        "store": str(rel), **info,
        "tags": [t for t in (a.tags or "").split(",") if t],
        "description": "", "origin_name": src.name,
        "ingested": datetime.date.today().isoformat(),
        "rights": RIGHTS[prov], "source": a.source or "",
    }
    if prov == "human":
        meta["medium"] = a.medium or ""        # ink, digital-paint, clay, ...
        meta["made"] = a.made or ""            # approx. date if known
    if prov == "captured":
        meta["captured_from"] = a.source or "" # page/app/session it was grabbed from
    if prov == "ai":
        meta["model"] = a.model or ""          # e.g. midjourney-v7, flux
        meta["prompt"] = a.prompt or ""
        meta["human_edited"] = False
    if a.dry_run:
        return f"would {prov:8} {src.name} -> {rel}"
    dest = STORE / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    (shutil.move if a.move else shutil.copy2)(src, dest)
    side.parent.mkdir(parents=True, exist_ok=True)
    side.write_text(yaml.safe_dump(meta, sort_keys=False, allow_unicode=True, width=100))
    return f"ok    {prov:8} {src.name} -> {rel}"


def walk(paths):
    for p in paths:
        if not str(p).strip():
            sys.exit("empty path argument; refusing (would walk the cwd)")
        p = Path(p).expanduser()
        if not p.exists():
            sys.exit(f"no such path: {p}")
        if p.is_dir():
            for f in sorted(p.rglob("*")):
                if f.is_file() and not f.name.startswith(".") and f.suffix.lower() in KIND:
                    yield f
        elif p.is_file():
            yield p


def cmd_ingest(a):
    if a.provenance not in PROVENANCE:
        sys.exit(f"--provenance required: {'|'.join(PROVENANCE)}")
    n = 0
    for f in walk(a.paths):
        print(ingest_one(f, a)); n += 1
    print(f"-- {n} file(s) {'(dry run)' if a.dry_run else ''}")
    if n and not a.dry_run:
        cmd_reindex(a)


def cmd_inbox(a):
    """Process RaBbLE-SiGiL/_inbox/{human,captured,ai}/ — drop files, run, done."""
    total = 0
    for prov in PROVENANCE:
        d = STORE / "_inbox" / prov
        d.mkdir(parents=True, exist_ok=True)
        files = list(walk([d]))
        if not files:
            continue
        a.provenance = prov
        a.move = True
        for f in files:
            print(ingest_one(f, a)); total += 1
    print(f"-- inbox: {total} file(s) {'(dry run)' if a.dry_run else ''}")
    if total and not a.dry_run:
        cmd_reindex(a)


def load_all():
    out = []
    for y in sorted(INDEX.rglob("*.yml")):
        d = yaml.safe_load(y.read_text()) or {}
        d["_sidecar"] = y
        out.append(d)
    return out


def cmd_pending(a):
    """Drafts awaiting review, with absolute paths so a vision-capable agent can open them."""
    rows = [d for d in load_all() if d.get("status") == "draft"]
    for d in rows:
        print(f"{d['id']}  {d['provenance']:8} {STORE / d['store']}")
    print(f"-- {len(rows)} draft(s). Fill title/tags/description in the sidecar, set status: reviewed.")


def cmd_verify(a):
    bad = 0
    for d in load_all():
        p = STORE / d["store"]
        if not p.exists():
            print(f"MISSING  {d['id']}  {d['store']}"); bad += 1
        elif a.deep and sha256(p) != d["sha256"]:
            print(f"CORRUPT  {d['id']}  {d['store']}"); bad += 1
    print(f"-- verify: {len(load_all())} indexed, {bad} problem(s)")
    sys.exit(1 if bad else 0)


def cmd_reindex(a):
    rows = load_all()
    lines = ["# RaBbLE Asset Index", "",
             "> Generated by `spells/asset-ingest.sh reindex` — do not hand-edit. "
             "Sidecars in `RaBbLE-SiGiL/index/` are the source; bytes live in `RaBbLE-SiGiL/store/` (git-ignored).", ""]
    for prov, label in (("human", "Human-made"), ("captured", "Captured / rendered"), ("ai", "AI-generated")):
        sub = [d for d in rows if d["provenance"] == prov]
        lines += [f"## {label} ({len(sub)})", ""]
        if sub:
            lines += ["| id | title | role | status | kind | size | tags |", "|---|---|---|---|---|---|---|"]
            for d in sorted(sub, key=lambda d: (d.get("role", ""), d["title"])):
                dim = f"{d['width']}×{d['height']}" if "width" in d else d["format"]
                lines.append(f"| `{d['id']}` | {d['title']} | {d.get('role','')} | {d['status']} | "
                             f"{d['kind']} | {dim} | {', '.join(d.get('tags', []))} |")
        lines.append("")
    (DOCS / "RaBbLE-SiGiL-Index.md").write_text("\n".join(lines))
    print(f"-- reindexed {len(rows)} asset(s) -> RaBbLE-SiGiL/RaBbLE-SiGiL-Index.md")


def main():
    ap = argparse.ArgumentParser(prog="asset-ingest")
    sp = ap.add_subparsers(dest="cmd", required=True)
    def meta_args(p):
        p.add_argument("--provenance", choices=PROVENANCE)
        p.add_argument("--role", choices=ROLES, default="other")
        p.add_argument("--title"); p.add_argument("--tags"); p.add_argument("--source")
        p.add_argument("--medium"); p.add_argument("--made")
        p.add_argument("--model"); p.add_argument("--prompt")
        p.add_argument("--move", action="store_true"); p.add_argument("--dry-run", action="store_true")
    i = sp.add_parser("ingest"); i.add_argument("paths", nargs="+"); meta_args(i); i.set_defaults(f=cmd_ingest)
    b = sp.add_parser("inbox"); meta_args(b); b.set_defaults(f=cmd_inbox)
    sp.add_parser("pending").set_defaults(f=cmd_pending)
    v = sp.add_parser("verify"); v.add_argument("--deep", action="store_true"); v.set_defaults(f=cmd_verify)
    sp.add_parser("reindex").set_defaults(f=cmd_reindex)
    a = ap.parse_args(); a.f(a)


if __name__ == "__main__":
    main()
