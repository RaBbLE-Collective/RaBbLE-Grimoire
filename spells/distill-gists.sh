#!/usr/bin/env bash
# distill-gists.sh — regenerate gist/ from canonical Grimoire docs via Claude CLI
#
# Usage:
#   bash spells/distill-gists.sh              # regenerate all gists
#   bash spells/distill-gists.sh identity     # regenerate one gist (name match)
#
# Requires: claude CLI available in PATH (claude --version to verify)
# Run from: RaBbLE-Grimoire/ root

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIST_DIR="$GRIMOIRE_ROOT/gist"
FILTER="${1:-}"

# Verify claude CLI
if ! command -v claude &>/dev/null; then
  echo "ERROR: 'claude' CLI not found. Install Claude Code: https://claude.ai/code"
  exit 1
fi

# Distillation prompt — injected before each doc
read -r -d '' DISTILL_PROMPT << 'EOF'
You are distilling a Grimoire document into a gist — a high-density, low-token summary.

Rules:
- Target ~150-250 words (never exceed 300)
- Start with a one-line "what this is" sentence
- Use tables for structured data (impulses, members, colors, etc.)
- Bullet points over prose wherever possible
- End with "→ Full doc for: [3-5 things the gist omits]"
- No headers except the title — use bold for section labels
- Preserve all hex values, version strings, commands exactly
- Versioning: current position is Epoch 0 · Evolution 0 · Echo 0 · Episode 1 pilot (v0.0.0.0)
- The sequence after Episode 1 is: more Episodes → Echo 1 (first big stable release) → Evolutions → eventually Epoch 1 (far future)
- Do NOT say "Epoch 1" when describing near-future goals; say "Echo 1" or "Episode 2+"

Output format (use exactly):
# {DocTitle} — gist

> Source: `{relative/path/to/source.md}` | ~{source_tokens} → ~{gist_tokens} tokens
> Regenerate: `bash spells/distill-gists.sh`

{content}
EOF

# Map: "gist-slug" => "source_file | gist_output | source_token_estimate"
declare -A GIST_MAP
GIST_MAP=(
  ["identity"]="RaBbLE-Agent/RaBbLE-Identity.md|gist/RaBbLE-Identity-gist.md|~3870"
  ["collective"]="RaBbLE-Agent/RaBbLE-Collective.md|gist/RaBbLE-Collective-gist.md|~1930"
  ["roadmap"]="RaBbLE-Agent/RaBbLE-Roadmap.md|gist/RaBbLE-Roadmap-gist.md|~2746"
  ["commitstyle"]="RaBbLE-Agent/RaBbLE-CommitStyle.md|gist/RaBbLE-CommitStyle-gist.md|~620"
  ["versioning"]="RaBbLE-Versioning.md|gist/RaBbLE-Versioning-gist.md|~1471"
  ["palette"]="RaBbLE-Agent/RaBbLE-Palette.md|gist/RaBbLE-Palette-gist.md|~1170"
  ["overview"]="RaBbLE-Collective/RaBbLE-Collective-Episode-1-Overview.md|gist/RaBbLE-Collective-Overview-gist.md|~914"
  ["episode1"]="RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md|gist/RaBbLE-Episode1-gist.md|~3143"
  ["integration"]="RaBbLE-Agent/RaBbLE-Integration-Map.md|gist/RaBbLE-Integration-Map-gist.md|~1200"
)

distill_one() {
  local slug="$1"
  local source output tokens
  IFS='|' read -r source output tokens <<< "${GIST_MAP[$slug]}"
  local source_path="$GRIMOIRE_ROOT/$source"
  local output_path="$GRIMOIRE_ROOT/$output"

  if [[ ! -f "$source_path" ]]; then
    echo "  SKIP $slug — source not found: $source"
    return
  fi

  echo "  Distilling $slug ..."
  local full_prompt="$DISTILL_PROMPT

Source file: $source (approx $tokens tokens)

---

$(cat "$source_path")"

  claude --print "$full_prompt" > "$output_path"
  local words
  words=$(wc -w < "$output_path")
  echo "  OK   $output ($words words)"
}

echo "RaBbLE Grimoire — distill-gists.sh"
echo "Target: $GIST_DIR"
echo ""

cd "$GRIMOIRE_ROOT"

if [[ -n "$FILTER" ]]; then
  if [[ -n "${GIST_MAP[$FILTER]:-}" ]]; then
    distill_one "$FILTER"
  else
    echo "Unknown gist slug: $FILTER"
    echo "Available: ${!GIST_MAP[*]}"
    exit 1
  fi
else
  for slug in "${!GIST_MAP[@]}"; do
    distill_one "$slug"
  done
fi

echo ""
echo "Done. Review gist/ for quality — gists are agent-facing, not just summaries."
echo "Commit: harmonize ~ grimoire >> gist/ regenerated // %GIST_CURRENT%"
