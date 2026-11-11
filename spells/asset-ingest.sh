#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — asset-ingest.sh
# Ingest art into the content-addressed store (RaBbLE-SiGiL/store/, git-ignored) and
# write a tracked sidecar into RaBbLE-SiGiL/index/. Provenance is required.
#
# Usage:
#   bash spells/asset-ingest.sh inbox                       # drain RaBbLE-SiGiL/store/_inbox/{human,captured,ai}/
#   bash spells/asset-ingest.sh ingest <file|dir>... --provenance human|captured|ai
#        [--role logo|entity|scene|ui|marketing|...] [--title T] [--tags a,b]
#        [--source S] [--medium M] [--made YYYY] [--model M] [--prompt P]
#        [--move] [--dry-run]
#   bash spells/asset-ingest.sh pending                     # drafts awaiting review (abs paths)
#   bash spells/asset-ingest.sh verify [--deep]             # sidecars vs store (--deep rehashes)
#   bash spells/asset-ingest.sh reindex                     # regenerate RaBbLE-SiGiL/RaBbLE-SiGiL-Index.md
#
# Override the store location with RABBLE_ASSETS=/path.
#
# spark ~ assets >> bytes stay home, the index travels // %ASSET_INGEST%
# =============================================================================
set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || $# -eq 0 ]]; then
  sed -n 3,20p "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

exec python3 "$(cd "$(dirname "$0")" && pwd)/asset-ingest.py" "$@"
