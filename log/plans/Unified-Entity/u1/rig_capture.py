"""U1: capture the Puppet Spec rig with Pocket proportions on a deterministic clock.
Usage: .venv/bin/python -I u1/rig_capture.py <spec.html> <outdir> [elev]"""
import sys, pathlib
from playwright.sync_api import sync_playwright

src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
elev = sys.argv[3] if len(sys.argv) > 3 else "17"
out.mkdir(parents=True, exist_ok=True)
html = src.read_text().replace("prop='reference'", "prop='pocket'", 1)
assert "prop='pocket'" in html
page_path = out / "rig-pocket.html"
page_path.write_text(html)

CLOCK = """
window.__T = 0; window.__cb = null;
performance.now = () => window.__T * 1000;
window.requestAnimationFrame = cb => { window.__cb = cb; return 1; };
window.__step = (T) => { while (window.__T < T - 1e-9) { window.__T = Math.min(T, window.__T + 1/60);
  const cb = window.__cb; window.__cb = null; if (cb) cb(window.__T * 1000); } };
"""

shots = []  # (name, action, time)
shots += [("idle", None, 6.0), ("blink_half", None, 4.24), ("blink", None, 4.28)]
for p in (0.25, 0.5, 0.75):
    shots.append((f"swap_{p}", "#mvP", 6.0 + 1.45 * p))
for p in (0.25, 0.5, 0.75):
    shots.append((f"turn_{p}", "#mvY", 6.0 + 1.4 * p))

with sync_playwright() as pw:
    b = pw.chromium.launch(headless=True)
    for name, action, T in shots:
        pg = b.new_page(viewport={"width": 1400, "height": 1000}, device_scale_factor=1)
        pg.add_init_script(CLOCK)
        pg.goto(page_path.as_uri())
        pg.evaluate(f"""() => {{ const e = document.getElementById('elev'); e.value = '{elev}';
            e.dispatchEvent(new Event('input')); }}""")
        if action:
            pg.evaluate("() => window.__step(6.0)")
            pg.click(action)
        pg.evaluate(f"() => window.__step({T})")
        pg.locator("#cv").screenshot(path=str(out / f"{name}.png"))
        pg.close()
        print(out / f"{name}.png")
    b.close()
