"""Capture every fixture from a web surface on a stepped clock (headless Playwright, no desktop).
Usage: .venv/bin/python -I capture_web.py [--surface rig|nebula] [--url PAGE] [--out DIR]
  rig     (default) the Puppet Spec page with prop='pocket' and the elevation slider at 17.
  nebula  HOOK for the unified web backend (W2-5/W2-6): pass --url of a NeBuLA page. The page must expose
          window.__golden(fixture) -> Promise, which sets state/level/move/progress/boot for the fixture
          (fixture fields as in fixtures.json) and renders it; the canvas selector is --canvas (default #cv).
          Until that page exists this surface exits 2."""
import argparse, json, pathlib, sys
from playwright.sync_api import sync_playwright

HERE = pathlib.Path(__file__).resolve().parent
SPEC = HERE.parent.parent.parent / "log/plans/Unified-Entity/Unified-Entity-Puppet-Spec.html"
CLOCK = """
window.__T = 0; window.__cb = null;
performance.now = () => window.__T * 1000;
window.requestAnimationFrame = cb => { window.__cb = cb; return 1; };
window.__step = (T) => { while (window.__T < T - 1e-9) { window.__T = Math.min(T, window.__T + 1/60);
  const cb = window.__cb; window.__cb = null; if (cb) cb(window.__T * 1000); } };
"""
ap = argparse.ArgumentParser()
ap.add_argument("--surface", default="rig", choices=["rig", "nebula"])
ap.add_argument("--url"); ap.add_argument("--canvas", default="#cv")
ap.add_argument("--out", default=str(HERE / "out/web"))
a = ap.parse_args()
out = pathlib.Path(a.out).resolve(); out.mkdir(parents=True, exist_ok=True)
doc = json.loads((HERE / "fixtures.json").read_text())
elev = str(doc["elevation"])
BTN = {"portal_swap": "#mvP", "turn": "#mvY"}

if a.surface == "rig":
    html = SPEC.read_text().replace("prop='reference'", "prop='pocket'", 1)
    assert "prop='pocket'" in html
    page = out / "rig-pocket.html"; page.write_text(html); url = page.as_uri()
else:
    if not a.url: sys.exit("nebula surface: --url required (hook for the unified backend, not built yet)")
    url = a.url

with sync_playwright() as pw:
    b = pw.chromium.launch(headless=True)
    for f in doc["fixtures"]:
        if a.surface == "rig" and not f["rig"]: continue
        pg = b.new_page(viewport={"width": 1400, "height": 1000}, device_scale_factor=1)
        pg.add_init_script(CLOCK)
        pg.goto(url)
        if a.surface == "rig":
            pg.evaluate("""(e) => { const el = document.getElementById('elev'); el.value = e;
                el.dispatchEvent(new Event('input')); }""", elev)
            if f["move"]:
                pg.evaluate("() => window.__step(6.0)"); pg.click(BTN[f["move"]])
            pg.evaluate("(T) => window.__step(T)", f["time"])
        else:
            pg.evaluate("(f) => window.__golden(f)", f)
        pg.locator(a.canvas if a.surface == "nebula" else "#cv").screenshot(path=str(out / f"{f['name']}.png"))
        pg.close(); print(out / f"{f['name']}.png")
    b.close()
