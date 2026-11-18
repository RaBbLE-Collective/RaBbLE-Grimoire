# Golden frames

Pixel and structure checks that the entity looks the same on every surface. Today it compares the Pocket device renderer (`nebula_lite` via `RaBbLE-Pocket/sim` sources, no hardware) with the web rig (Puppet Spec page, `prop='pocket'`, elevation 17). Later the unified NeBuLA web backend plugs in (W2-5/W2-6).

| File | What |
|---|---|
| `fixtures.json` | surface-independent fixtures: idle, blink half/full, portal_swap 0.25/0.40/0.45/0.50/0.55/0.60/0.75, turn 0.25/0.5/0.75, listening level 0.5, boot 0.5/1.5/3.0 s |
| `capture_device.sh` | builds `host_render_golden.c` (u1's FLIP= copy plus BOOT=) from Pocket sources into `out/build`, writes `out/device/*.png` |
| `capture_web.py` | stepped-clock Playwright capture to `out/web/*.png`. `--surface nebula --url PAGE` is the hook for the unified backend: the page must expose `window.__golden(fixture)` (sets state/level/move/progress/boot, renders), canvas selector `--canvas` |
| `diff.py` | normalise (crop to the entity, drop backdrop, scale to 256 px, mask regions), compare (mean delta, fraction of pixels over 0.25, windowed SSIM), write `out/report/<name>.png` (device, web, heatmap) and `report.json` |
| `expected.json` | per fixture `must_pass` or `expected_fail` with reasons (U1 a to e, mid-swap faults 1 to 3) and the first-run metrics |
| `baselines/{device,web}/` | committed frames, each surface against itself at tight tolerance |
| `out/report/` | first run: sheets and `report.json` (captures in `out/device`, `out/web` are gitignored, same as `baselines/`); `run-log.txt` its log |

## Run

```bash
cd RaBbLE-Grimoire/registry/entity/golden
uv venv .venv && uv pip install pillow numpy playwright && .venv/bin/python -m playwright install chromium
./run.sh                 # capture both surfaces, diff; exit 0 = green
.venv/bin/python -I diff.py --only swap_0.50    # re-diff without recapturing
```

Needs gcc and the sibling RaBbLE-Pocket checkout (override with `POCKET=`). Both captures are deterministic (stepped clock, fixed t), so reruns are byte-stable.

## Reading the result

- `XFAIL`: differs from the rig as recorded. Fine.
- `XPASS`: an expected failure now passes. Red on purpose: set that fixture to `must_pass` in `expected.json` (the gate for W2-5: rest eye/glow; W2-12: swap 0.25 to 0.75 and turn).
- `DRIFT`: still failing but by a different amount than recorded (beyond `drift_band`): something else changed. Inspect the sheet; if intended, update the recorded `baseline` numbers.
- `FAIL`: a `must_pass` fixture regressed. Baseline messages mean one renderer's own frame changed.

## Update a golden

After an intended renderer change: `./run.sh --update` (copies the captured frames into `baselines/`), review `git diff --stat` and the sheets, edit `expected.json` where a fixture now matches, rerun `./run.sh` until green, commit together.

## CI

```bash
cd RaBbLE-Grimoire/registry/entity/golden && ./run.sh   # needs gcc, uv, chromium; fails the job on non-zero exit
```
Upload `out/report/` as the artifact on failure. Run it when `RaBbLE-Pocket/firmware/entities/RaBbLE/**`, `RaBbLE-NeBuLA/src/**` or the registry changes.

## Tuning notes

Crops and masks (`CROP`, `MASKS`) and tolerances (`TOL`, `TOL_BASE`) are at the top of `diff.py`. Device mesh and ring sit outside the device crop; glass is not drawn by either surface yet, so the mask lists are empty and ready for W2-7b/d. The web rig has no listening or boot, so those fixtures are device-only (baseline guard).
