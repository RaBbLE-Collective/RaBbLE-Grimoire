#!/usr/bin/env bash
# Render every fixture from the Pocket host harness (nebula_lite + scene.c), no hardware.
# Usage: capture_device.sh [outdir=out/device]   Builds into out/build from RaBbLE-Pocket sources (read only).
set -euo pipefail
cd "$(dirname "$0")"
OUT="${1:-out/device}"; mkdir -p "$OUT" out/build
POCKET="${POCKET:-../../../../RaBbLE-Pocket}"
SRC="$POCKET/firmware/entities/RaBbLE/nebula_lite"; SCENE="$POCKET/firmware/entities/RaBbLE/src/scene.c"
gcc -O2 -w -I"$SRC/include" -I"$(dirname "$SCENE")/../include" "$SRC"/src/*.c "$SCENE" host_render_golden.c -lm -o out/build/host_render_golden
PY=.venv/bin/python
.venv/bin/python -I - "$OUT" <<'P'
import json, os, subprocess, sys
from PIL import Image
out = sys.argv[1]
stm = {"idle": 0, "listening": 1, "thinking": 2, "speaking": 3, "error": 4}
for f in json.load(open("fixtures.json"))["fixtures"]:
    if not f["device"]: continue
    env = dict(os.environ)
    env.pop("FLIP", None); env.pop("BOOT", None)
    if f["move"] == "portal_swap": env["FLIP"] = str(f["progress"])
    if f["boot"] is not None: env["BOOT"] = str(f["boot"])
    t = f["time"] if f["name"].startswith("blink") else 6.0   # device blink phase is its own; same clock as the rig
    ppm = f"{out}/{f['name']}.ppm"
    subprocess.run(["out/build/host_render_golden", ppm, str(stm[f["state"]]), str(t), str(f["level"])],
                   env=env, check=True, stderr=subprocess.DEVNULL)
    Image.open(ppm).save(f"{out}/{f['name']}.png", optimize=True); os.remove(ppm)
    print(f"{out}/{f['name']}.png")
P
