"""Golden-frame diff for the RaBbLE entity (numpy + pillow only).
Usage: .venv/bin/python -I diff.py [--device DIR] [--web DIR] [--out DIR] [--only NAME ...] [--update]
Two comparisons per fixture:
  cross     device vs web (normalised: crop to the entity, scale to a common size, mask glass and mesh).
            Judged against expected.json: expected_fail fixtures must still fail within their recorded drift band,
            everything else must pass. A fixture that passes while listed as expected_fail is XPASS = red:
            flip it to must_pass in expected.json (that is the gate).
  baseline  each surface against its own committed frame in baselines/<surface>/ (tight tolerance): catches any
            change to either renderer. --update rewrites baselines from the captured frames.
Exit 0 only if every fixture matches its expectation. Writes <out>/<name>.png (device | web | heatmap), report.json."""
import argparse, json, pathlib, shutil, sys
import numpy as np
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
BG = 0.14
N = 256   # common size
# Entity crops (fraction-free pixel boxes) per surface: the eyes + portals, excluding the mesh, ring, badges.
CROP = {"device": (135, 140, 331, 320), "web": (205, 100, 515, 340)}
# Masks in normalised crop coordinates (x0,y0,x1,y1 in 0..1), painted to 0 on both sides. Glass/mesh are
# not part of the rig, so the device frame's mesh and glass regions are masked out on both.
MASKS = {"device": [], "web": []}
TOL = {"max_mean": 0.045, "max_bad_frac": 0.06, "min_ssim": 0.80, "bad_delta": 0.25}   # cross-surface
TOL_BASE = {"max_mean": 0.002, "max_bad_frac": 0.0005, "min_ssim": 0.995, "bad_delta": 0.25}

def load(p, surface):
    im = Image.open(p).convert("RGB").crop(CROP[surface]).resize((N, N), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float32) / 255
    a = np.clip((a - BG) / (1 - BG), 0, 1)   # drop the dark backdrop (device near-black, rig violet wash)
    for x0, y0, x1, y1 in MASKS[surface]:
        a[int(y0 * N):int(y1 * N), int(x0 * N):int(x1 * N)] = 0
    return a

def box(a, k=8):
    c = np.cumsum(np.cumsum(np.pad(a, ((1, 0), (1, 0))), 0), 1)
    return (c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]) / (k * k)

def ssim(x, y):
    mx, my = box(x), box(y)
    vx, vy, cxy = box(x * x) - mx * mx, box(y * y) - my * my, box(x * y) - mx * my
    c1, c2 = 0.01 ** 2, 0.03 ** 2
    return float(np.mean(((2 * mx * my + c1) * (2 * cxy + c2)) / ((mx * mx + my * my + c1) * (vx + vy + c2))))

def metrics(a, b, tol):
    d = np.abs(a - b).max(axis=2)
    gx, gy = a.mean(axis=2), b.mean(axis=2)
    m = {"mean": round(float(d.mean()), 4), "bad_frac": round(float((d > tol["bad_delta"]).mean()), 4), "ssim": round(ssim(gx, gy), 4)}
    m["pass"] = m["mean"] <= tol["max_mean"] and m["bad_frac"] <= tol["max_bad_frac"] and m["ssim"] >= tol["min_ssim"]
    return m, d

def sheet(a, b, d, path):
    heat = np.zeros(d.shape + (3,), np.float32)
    heat[..., 0] = np.clip(d * 2, 0, 1); heat[..., 1] = np.clip(d * 2 - 1, 0, 1)
    row = np.concatenate([a, b, heat], axis=1)
    Image.fromarray((row * 255).astype(np.uint8)).save(path, optimize=True)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--device", default=str(HERE / "out/device")); ap.add_argument("--web", default=str(HERE / "out/web"))
    ap.add_argument("--out", default=str(HERE / "out/report")); ap.add_argument("--only", nargs="*")
    ap.add_argument("--update", action="store_true", help="rewrite baselines/ from the captured frames")
    a = ap.parse_args()
    fx = json.loads((HERE / "fixtures.json").read_text())["fixtures"]
    exp = json.loads((HERE / "expected.json").read_text())
    out = pathlib.Path(a.out); out.mkdir(parents=True, exist_ok=True)
    report, bad = {}, 0
    for f in fx:
        n = f["name"]
        if a.only and n not in a.only: continue
        dev, web = pathlib.Path(a.device) / f"{n}.png", pathlib.Path(a.web) / f"{n}.png"
        res, notes = {}, []
        if a.update:
            for s, p in (("device", dev), ("web", web)):
                if p.exists():
                    (HERE / "baselines" / s).mkdir(parents=True, exist_ok=True); shutil.copy(p, HERE / "baselines" / s / f"{n}.png")
        # baseline self-regression
        for s, p in (("device", dev), ("web", web)):
            b = HERE / "baselines" / s / f"{n}.png"
            if not p.exists() or not b.exists():
                if (p.exists() != b.exists()) and not (s == "web" and not f["rig"]) and not (s == "device" and not f["device"]):
                    notes.append(f"{s}: capture or baseline missing")
                continue
            m, _ = metrics(load(p, s), load(b, s), TOL_BASE); res[f"baseline_{s}"] = m
            if not m["pass"]: notes.append(f"{s} baseline drifted {m}")
        # cross-surface
        status = "n/a"
        if dev.exists() and web.exists():
            A, B = load(dev, "device"), load(web, "web")
            m, d = metrics(A, B, TOL); res["cross"] = m; sheet(A, B, d, out / f"{n}.png")
            e = exp["fixtures"].get(n, {"expect": "must_pass"})
            if e["expect"] == "must_pass":
                status = "PASS" if m["pass"] else "FAIL"
                if not m["pass"]: notes.append(f"must_pass but cross diff failed {m}")
            else:
                if m["pass"]:
                    status = "XPASS"; notes.append("expected_fail now passes: flip to must_pass in expected.json")
                else:
                    status = "XFAIL"
                    ref = e.get("baseline", {}); band = exp.get("drift_band", 0.05)
                    if ref and (abs(m["ssim"] - ref["ssim"]) > band or abs(m["mean"] - ref["mean"]) > band / 2):
                        status = "DRIFT"; notes.append(f"differs from recorded {ref} by more than the band: the difference changed")
        else:
            for s, p, ok in (("device", dev, f["device"]), ("web", web, f["rig"])):
                if ok and not p.exists(): notes.append(f"{s} frame missing")
        report[n] = {"status": status, **res, "notes": notes}
        line = f"{n:16s} {status:6s}" + (f" ssim={res['cross']['ssim']:.3f} mean={res['cross']['mean']:.3f} bad={res['cross']['bad_frac']:.3f}" if "cross" in res else " (single surface)")
        print(line + ("  !! " + "; ".join(notes) if notes else ""))
        bad += bool(notes)
    (out / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"{'RED' if bad else 'GREEN'}: {bad} fixture(s) off expectation")
    sys.exit(1 if bad else 0)

main()
