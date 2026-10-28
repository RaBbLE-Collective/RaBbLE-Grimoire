#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — ingest-capabilities.sh
# Rewrites sCoRE's capability registry (orchestra/capabilities.json) and its
# published scale (orchestra/capabilities.lock) from the curated benchmark rows
# in RaBbLE-sCoRE/RaBbLE-sCoRE-Capability-Benchmarks.json. No scraping: every
# row carries its source. Frontier-relative by default; a new frontier row
# rescales everyone and the lock records the reference.
#
# Usage: bash spells/ingest-capabilities.sh [--check] [rows.json]
#   --check   print old -> new per model, write nothing
# Maths and format: RaBbLE-sCoRE/orchestra/ingest.py (repo RaBbLE-sCoRE).
# =============================================================================
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
score="$(cd "$here/../RaBbLE-sCoRE" && pwd)"
py="$HOME/.local/share/RaBbLE/rabble-ui/bin/python"
[ -x "$py" ] || py=python3
rows="$here/RaBbLE-sCoRE/RaBbLE-sCoRE-Capability-Benchmarks.json"
args=()
for a in "$@"; do case "$a" in --check) args+=(--check) ;; *) rows="$a" ;; esac; done
cd "$score" && exec "$py" -P -m orchestra.ingest "$rows" "${args[@]}"
