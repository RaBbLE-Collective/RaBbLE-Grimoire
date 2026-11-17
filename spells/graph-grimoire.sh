#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — graph-grimoire.sh
# Builds a documentation graph — nodes are .md files, edges are markdown links.
# Outputs JSON adjacency list and Mermaid diagram. Reports orphans and hubs.
#
# Usage:
#   bash spells/graph-grimoire.sh              # full graph + summary
#   bash spells/graph-grimoire.sh --json-only  # just write JSON, skip mermaid
#
# spark ~ grimoire >> the nervous system mapped // %DOC_GRAPH%
# =============================================================================

set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "graph-grimoire.sh — build a token-weighted documentation link graph"
  echo ""
  echo "Usage: bash spells/graph-grimoire.sh [--json-only | --walk <doc>]"
  echo "  --json-only     Write JSON graph only, skip Mermaid diagram"
  echo "  --walk <doc>    Agent low-token traversal: print <doc>'s outgoing links"
  echo "                  (and what links to it), each with its token cost, cheapest"
  echo "                  first — so you can pick the next doc to read on a budget."
  echo ""
  echo "Outputs:"
  echo "  log/generated/grimoire-graph.json   — adjacency list; nodes & edges carry \"tokens\""
  echo "  log/generated/grimoire-graph.md     — Mermaid diagram (token cost in each node label)"
  echo ""
  echo "Reports: orphan docs, hub docs, islands, heaviest docs, link density."
  exit 0
fi

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JSON_ONLY="${1:-}"
WALK_DOC=""
if [[ "${1:-}" == "--walk" ]]; then WALK_DOC="${2:-}"; JSON_ONLY="--json-only-skip"; fi

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
RED='\033[38;2;224;92;111m'
MUTED='\033[38;2;107;104;128m'
RESET='\033[0m'

mkdir -p "$GRIMOIRE_ROOT/log/generated"

GRAPH_JSON="$GRIMOIRE_ROOT/log/generated/grimoire-graph.json"
GRAPH_MD="$GRIMOIRE_ROOT/log/generated/grimoire-graph.md"

declare -A NODE_DIR
declare -A OUTGOING
declare -A INCOMING
declare -A TOKENS
declare -A EDGE_SEEN

# Token estimate: words × 1.33 (same heuristic as spells/token-budget.sh).
# Embedded per-node and per-edge so an agent can plan a LOW-TOKEN reading walk
# — every edge carries the cost (in tokens) of reading the doc it points to.
tok_est() { local w; w=$(wc -w < "$1" 2>/dev/null | tr -d ' '); echo $(( (${w:-0} * 133 + 50) / 100 )); }
fmt_tok() { local t="${1:-0}"; if (( t >= 1000 )); then printf '%d.%01dk' $((t/1000)) $(((t%1000)/100)); else printf '%d' "$t"; fi; }

# Collect all .md files as nodes
while IFS= read -r filepath; do
  rel="${filepath#$GRIMOIRE_ROOT/}"
  dir="${rel%%/*}"
  [[ "$dir" == "$rel" ]] && dir="root"
  NODE_DIR["$rel"]="$dir"
  OUTGOING["$rel"]=0
  INCOMING["$rel"]=0
  TOKENS["$rel"]=$(tok_est "$filepath")
done < <(find "$GRIMOIRE_ROOT" -name '*.md' -type f \
          ! -path '*/log/grimoire-graph.md' \
          ! -path '*/gist/*' | sort)
# gist/ is excluded: those files are generated, standalone summaries — intentionally
# unlinked, so they would otherwise swamp the orphan/island report with noise.

# Entry-point docs are roots by design (an agent opens them directly, nothing links
# in). Exempt them from the orphan/island reports so real disconnected docs surface.
declare -A ENTRY_POINT
for ep in AGENT.md CLAUDE.md CODEX.md GEMINI.md README.md INDEX.md CONTEXT.md REFERENCES.md SPELLS.md; do
  ENTRY_POINT["$ep"]=1
done

EDGES=()

# Extract links from each file
for rel in "${!NODE_DIR[@]}"; do
  filepath="$GRIMOIRE_ROOT/$rel"
  filedir=$(dirname "$rel")

  while IFS= read -r link; do
    # Skip URLs, anchors, images
    [[ "$link" == http* ]] && continue
    [[ "$link" == \#* ]] && continue
    [[ "$link" == mailto:* ]] && continue

    # Strip anchor fragment
    link="${link%%#*}"
    # Strip query string
    link="${link%%\?*}"
    [[ -z "$link" ]] && continue

    # Resolve relative path
    if [[ "$link" == /* ]]; then
      resolved="${link#/}"
    else
      resolved=$(cd "$GRIMOIRE_ROOT/$filedir" 2>/dev/null && realpath -m --relative-to="$GRIMOIRE_ROOT" "$link" 2>/dev/null || echo "")
    fi
    [[ -z "$resolved" ]] && continue

    # Only count links to files that exist in our node set; dedup (a doc may
    # reference the same target via both a markdown link and a backtick path)
    if [[ -n "${NODE_DIR[$resolved]:-}" && "$resolved" != "$rel" ]]; then
      key="$rel|$resolved"
      if [[ -z "${EDGE_SEEN[$key]:-}" ]]; then
        EDGE_SEEN["$key"]=1
        EDGES+=("$key")
        OUTGOING["$rel"]=$(( ${OUTGOING["$rel"]} + 1 ))
        INCOMING["$resolved"]=$(( ${INCOMING["$resolved"]} + 1 ))
      fi
    fi
    # Two link forms are captured below: markdown [text](path) AND backtick
    # `path.md` code spans — the Grimoire's nav docs (AGENT.md, AgentGuide)
    # cite docs in backticks, so without this the graph misses navigation.
  done < <( { grep -oP '\]\(\K[^)]+' "$filepath"; grep -oP '`\K[^`]+\.md(?=`)' "$filepath"; } 2>/dev/null || true)
done

total_nodes=${#NODE_DIR[@]}
total_edges=${#EDGES[@]}

# --- Agent walk mode: low-token neighborhood preview ---
if [[ -n "$WALK_DOC" ]]; then
  # Resolve a partial name to a full node id (exact, then substring)
  target=""
  [[ -n "${NODE_DIR[$WALK_DOC]:-}" ]] && target="$WALK_DOC"
  if [[ -z "$target" ]]; then
    for rel in $(echo "${!NODE_DIR[@]}" | tr ' ' '\n' | sort); do
      [[ "$rel" == *"$WALK_DOC"* ]] && { target="$rel"; break; }
    done
  fi
  if [[ -z "$target" ]]; then
    echo -e "${RED}No doc matches:${RESET} $WALK_DOC" >&2
    exit 1
  fi
  echo -e "${MAGENTA}Walk from:${RESET} ${CYAN}$target${RESET}  ${MUTED}(~$(fmt_tok "${TOKENS[$target]:-0}") tokens to read this doc)${RESET}"
  echo ""
  echo -e "${GREEN}→ Reads next (outgoing links, cheapest first):${RESET}"
  for edge in "${EDGES[@]}"; do
    [[ "${edge%%|*}" == "$target" ]] && printf '%d\t%s\n' "${TOKENS[${edge#*|}]:-0}" "${edge#*|}"
  done | sort -n | awk -F'\t' '{printf "  ~%-7s %s\n", $1, $2}' | sed "s/~\([0-9]*\) /~\1t /" || true
  echo ""
  echo -e "${CYAN}← Linked from (incoming, cheapest first):${RESET}"
  for edge in "${EDGES[@]}"; do
    [[ "${edge#*|}" == "$target" ]] && printf '%d\t%s\n' "${TOKENS[${edge%%|*}]:-0}" "${edge%%|*}"
  done | sort -n | awk -F'\t' '{printf "  ~%-7s %s\n", $1, $2}' | sed "s/~\([0-9]*\) /~\1t /" || true
  echo ""
  echo -e "${MUTED}Tip: prefer a gist/ summary over a heavy doc when one exists.${RESET}"
  exit 0
fi

# --- Write JSON ---
{
  echo '{'
  echo '  "generated": "'$(date -Iseconds)'",'
  echo '  "total_nodes": '$total_nodes','
  echo '  "total_edges": '$total_edges','

  # Nodes
  echo '  "nodes": ['
  first=true
  for rel in $(echo "${!NODE_DIR[@]}" | tr ' ' '\n' | sort); do
    dir="${NODE_DIR[$rel]}"
    out="${OUTGOING[$rel]}"
    inc="${INCOMING[$rel]}"
    $first || echo ','
    printf '    {"id": "%s", "dir": "%s", "outgoing": %d, "incoming": %d, "tokens": %d}' "$rel" "$dir" "$out" "$inc" "${TOKENS[$rel]:-0}"
    first=false
  done
  echo ''
  echo '  ],'

  # Edges
  echo '  "edges": ['
  first=true
  for edge in "${EDGES[@]}"; do
    from="${edge%%|*}"
    to="${edge#*|}"
    $first || echo ','
    printf '    {"from": "%s", "to": "%s", "tokens": %d}' "$from" "$to" "${TOKENS[$to]:-0}"
    first=false
  done
  echo ''
  echo '  ]'
  echo '}'
} > "$GRAPH_JSON"

echo -e "${GREEN}Wrote${RESET} $GRAPH_JSON"

# --- Write Mermaid ---
if [[ "$JSON_ONLY" != "--json-only" ]]; then
  {
    echo '# Grimoire Documentation Graph'
    echo ''
    echo '> Auto-generated by `bash spells/graph-grimoire.sh` — do not edit.'
    echo "> Generated: $(date -Iseconds)"
    echo ''
    echo '```mermaid'
    echo 'graph LR'

    # Collect directories for subgraphs
    declare -A DIRS
    for rel in "${!NODE_DIR[@]}"; do
      DIRS["${NODE_DIR[$rel]}"]=1
    done

    # Abbreviate node IDs for mermaid readability
    abbrev() {
      local f="$1"
      # Strip .md extension, replace / and - with _
      echo "$f" | sed 's/\.md$//' | sed 's/[\/\-\.]/_/g' | sed 's/RaBbLE_//g'
    }

    label() {
      basename "$1" .md
    }

    for dir in $(echo "${!DIRS[@]}" | tr ' ' '\n' | sort); do
      echo "  subgraph ${dir}"
      for rel in $(echo "${!NODE_DIR[@]}" | tr ' ' '\n' | sort); do
        [[ "${NODE_DIR[$rel]}" == "$dir" ]] || continue
        echo "    $(abbrev "$rel")[\"$(label "$rel")<br/>~$(fmt_tok "${TOKENS[$rel]:-0}")\"]"
      done
      echo "  end"
    done

    # Edges
    for edge in "${EDGES[@]}"; do
      from="${edge%%|*}"
      to="${edge#*|}"
      echo "  $(abbrev "$from") --> $(abbrev "$to")"
    done

    echo '```'
    echo ''
    echo "**Nodes:** $total_nodes | **Edges:** $total_edges | **Avg links/doc:** $(echo "scale=1; $total_edges / $total_nodes" | bc 2>/dev/null || echo "?")"
  } > "$GRAPH_MD"

  echo -e "${GREEN}Wrote${RESET} $GRAPH_MD"
fi

# --- Summary ---
echo ""
echo -e "${MAGENTA}RaBbLE-Grimoire — Documentation Graph${RESET}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════${RESET}"
printf "  ${CYAN}%-30s${RESET} %d\n" "Total documents" "$total_nodes"
printf "  ${CYAN}%-30s${RESET} %d\n" "Total links" "$total_edges"
if [[ $total_nodes -gt 0 ]]; then
  avg=$(echo "scale=1; $total_edges / $total_nodes" | bc 2>/dev/null || echo "?")
  printf "  ${CYAN}%-30s${RESET} %s\n" "Avg links per doc" "$avg"
fi

# Orphans (no incoming links) — entry-point docs are roots by design, skip them
echo ""
echo -e "${YELLOW}Orphan docs (no incoming links — candidates to link from INDEX.md):${RESET}"
orphan_count=0
for rel in $(echo "${!NODE_DIR[@]}" | tr ' ' '\n' | sort); do
  base="$(basename "$rel")"
  # log/lessons/* are generated by promote-insight.sh — standalone by design, skip noise
  [[ "$rel" == log/lessons/* ]] && continue
  if [[ "${INCOMING[$rel]}" -eq 0 && -z "${ENTRY_POINT[$base]:-}" ]]; then
    echo -e "  ${MUTED}$rel${RESET}"
    ((orphan_count++)) || true
  fi
done
[[ $orphan_count -eq 0 ]] && echo -e "  ${GREEN}None${RESET}"

# Hub docs (>5 incoming)
echo ""
echo -e "${CYAN}Hub docs (>5 incoming links):${RESET}"
hub_count=0
for rel in $(echo "${!NODE_DIR[@]}" | tr ' ' '\n' | sort); do
  if [[ "${INCOMING[$rel]}" -gt 5 ]]; then
    echo -e "  ${GREEN}$rel${RESET} (${INCOMING[$rel]} incoming)"
    ((hub_count++)) || true
  fi
done
[[ $hub_count -eq 0 ]] && echo -e "  ${MUTED}None${RESET}"

# Heaviest docs (highest token cost to read) — prefer a gist if one exists
echo ""
echo -e "${YELLOW}Heaviest docs (top token cost — read a gist/ summary first if available):${RESET}"
for rel in "${!TOKENS[@]}"; do printf '%d\t%s\n' "${TOKENS[$rel]}" "$rel"; done \
  | sort -rn | head -8 | awk -F'\t' '{printf "  ~%-8s %s\n", $1"t", $2}'

# Islands (no incoming AND no outgoing)
echo ""
echo -e "${RED}Islands (no links at all):${RESET}"
island_count=0
for rel in $(echo "${!NODE_DIR[@]}" | tr ' ' '\n' | sort); do
  base="$(basename "$rel")"
  [[ "$rel" == log/lessons/* ]] && continue
  if [[ "${INCOMING[$rel]}" -eq 0 && "${OUTGOING[$rel]}" -eq 0 && -z "${ENTRY_POINT[$base]:-}" ]]; then
    echo -e "  ${RED}$rel${RESET}"
    ((island_count++)) || true
  fi
done
[[ $island_count -eq 0 ]] && echo -e "  ${GREEN}None${RESET}"

echo ""
echo -e "${MUTED}Mermaid graph: log/grimoire-graph.md (paste into GitHub/Obsidian to render)${RESET}"
echo -e "${MUTED}JSON graph:    log/grimoire-graph.json${RESET}"
echo ""
