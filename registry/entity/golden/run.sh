#!/usr/bin/env bash
# Capture both surfaces to out/ and diff. Exit non-zero on any fixture off expectation.
set -euo pipefail
cd "$(dirname "$0")"
[ -d .venv ] || { uv venv .venv -q && uv pip install -q pillow numpy playwright; .venv/bin/python -m playwright install chromium; }
./capture_device.sh out/device >/dev/null
.venv/bin/python -I capture_web.py --out out/web >/dev/null
.venv/bin/python -I diff.py "$@"
