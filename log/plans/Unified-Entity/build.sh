#!/usr/bin/env bash
# Rebuild the Aether spec page from the markdown + live body. Output: Unified-Entity-Puppet-Spec.html (generated, untracked is fine).
set -euo pipefail
cd "$(dirname "$0")"
python3 live/build_page.py Unified-Entity-Puppet-Spec.md registry-spike/poses.role.json live/template.html Unified-Entity-Puppet-Spec.html
