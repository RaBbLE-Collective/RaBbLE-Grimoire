#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — promote-insight.sh
# Scan log/decisions/*.jsonl for insight and stumble entries, then write durable
# lessons to log/lessons/<slug>.md so future agents benefit automatically.
#
# Every time an agent stumbles or discovers something worth remembering, this
# spell crystallizes it into a Lesson — a permanent, versioned, searchable
# artifact that compounds the Collective's knowledge across sessions.
#
# Usage:
#   bash spells/promote-insight.sh list    [session-id]
#   bash spells/promote-insight.sh promote <session-id> [entry-index...]
#   bash spells/promote-insight.sh auto    [session-id]   # promote all from session
#   bash spells/promote-insight.sh show    <lesson-slug>
#   bash spells/promote-insight.sh ls                      # list all lessons
#
# Lesson frontmatter (YAML):
#   title, date, agent, session, tags, source_type (insight|stumble), source_message
#
# spark ~ grimoire >> stumbles become stepping stones // %PROMOTE_INSIGHT%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DECISIONS_DIR="$GRIMOIRE_ROOT/log/decisions"
LESSONS_DIR="$GRIMOIRE_ROOT/log/lessons"
mkdir -p "$DECISIONS_DIR" "$LESSONS_DIR"

# --- Colors -------------------------------------------------------------------
GREEN='\033[38;2;80;250;123m'
CYAN='\033[38;2;0;245;255m'
YELLOW='\033[38;2;241;250;140m'
MAGENTA='\033[38;2;255;45;120m'
RED='\033[38;2;255;85;85m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Resolve session id (mirrors end-session.sh) ------------------------------
resolve_session_id() {
  if [[ -n "${RABBLE_SESSION_ID:-}" ]]; then
    echo "$RABBLE_SESSION_ID"; return
  fi
  local cand projdir sf
  for cand in "$(dirname "$GRIMOIRE_ROOT")" "$GRIMOIRE_ROOT"; do
    projdir="$HOME/.claude/projects/$(echo "$cand" | tr '/' '-')"
    sf=$(ls -t "$projdir"/*.jsonl 2>/dev/null | head -1 || true)
    if [[ -n "$sf" ]]; then basename "$sf" .jsonl; return; fi
  done
  local commit
  commit=$(git -C "$GRIMOIRE_ROOT" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d)
  echo "commit-${commit}"
}

# --- Slugify a message into a filename-safe string ----------------------------
slugify() {
  echo "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 -]//g' \
    | sed 's/  */ /g' \
    | sed 's/ /-/g' \
    | cut -c1-60
}

# --- Collect promotable entries from a JSONL file ----------------------------
# Outputs: index|type|timestamp|message|agent
get_promotable() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local idx=0
  while IFS= read -r line; do
    [[ -z "$line" ]] && { idx=$((idx+1)); continue; }
    local type
    type=$(echo "$line" | jq -r '.type // ""' 2>/dev/null || echo "")
    if [[ "$type" == "insight" || "$type" == "stumble" ]]; then
      local ts msg agent
      ts=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)
      msg=$(echo "$line" | jq -r '.message // ""' 2>/dev/null)
      agent=$(echo "$line" | jq -r '.agent // "unknown"' 2>/dev/null)
      echo "${idx}|${type}|${ts}|${msg}|${agent}"
    fi
    idx=$((idx+1))
  done < "$file"
}

# --- Write a lesson file ------------------------------------------------------
write_lesson() {
  local type="$1"
  local message="$2"
  local agent="$3"
  local sid="$4"
  local ts="$5"
  local tags="$6"

  local date_part
  date_part=$(echo "$ts" | cut -c1-10)
  local slug
  slug="${date_part}-$(slugify "$message")"
  local outfile="$LESSONS_DIR/${slug}.md"

  # If file already exists, append a counter
  if [[ -f "$outfile" ]]; then
    local n=2
    while [[ -f "${outfile%.md}-${n}.md" ]]; do n=$((n+1)); done
    outfile="${outfile%.md}-${n}.md"
    slug="${slug}-${n}"
  fi

  # Determine severity label
  local severity="info"
  [[ "$type" == "stumble" ]] && severity="warn"

  cat > "$outfile" <<EOF
---
title: "$(echo "$message" | head -c 80 | sed 's/"/\\"/g')"
date: "${date_part}"
agent: "${agent}"
session: "${sid}"
source_type: "${type}"
severity: "${severity}"
tags: [${tags}]
---

## Lesson

${message}

## Context

- **Source type:** ${type}
- **Session:** \`${sid}\`
- **Agent:** ${agent}
- **Recorded:** ${ts}

## Why this matters

<!-- Agents: add context here when promoting interactively. -->
<!-- The raw entry is preserved above; this section is for elaboration. -->
EOF

  echo "$outfile"
}

# =============================================================================
# COMMANDS
# =============================================================================

cmd_list() {
  local sid="${1:-}"
  local files=()

  if [[ -n "$sid" ]]; then
    files=("$DECISIONS_DIR/${sid}.jsonl")
  else
    for f in "$DECISIONS_DIR"/*.jsonl; do
      [[ -f "$f" ]] && files+=("$f")
    done
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    echo -e "${MUTED}No decision logs found.${RESET}"
    exit 0
  fi

  echo ""
  echo -e "${MAGENTA}Promotable Insights & Stumbles${RESET}"
  echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${RESET}"

  local total=0
  for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    local file_sid
    file_sid=$(basename "$file" .jsonl)

    local rows
    rows=$(get_promotable "$file")
    [[ -z "$rows" ]] && continue

    echo -e "  ${CYAN}Session: ${file_sid}${RESET}"
    while IFS='|' read -r idx type ts msg agent; do
      [[ -z "$type" ]] && continue
      local color
      [[ "$type" == "stumble" ]] && color="$RED" || color="$GREEN"
      echo -e "    ${MUTED}[${idx}]${RESET} ${color}[${type}]${RESET} ${TEXT}${msg}${RESET}"
      echo -e "         ${MUTED}${ts}  (${agent})${RESET}"
      total=$((total+1))
    done <<< "$rows"
    echo ""
  done

  if [[ $total -eq 0 ]]; then
    echo -e "  ${MUTED}No promotable entries (insights or stumbles) found.${RESET}"
  else
    echo -e "  ${MUTED}$total promotable entry/entries found.${RESET}"
    echo -e "  ${MUTED}Promote with: bash spells/promote-insight.sh promote <session-id> [index...]${RESET}"
    echo -e "  ${MUTED}Promote all:  bash spells/promote-insight.sh auto   <session-id>${RESET}"
  fi
  echo ""
}

cmd_promote() {
  local sid="${1:-}"
  shift || true
  local indices=("$@")   # if empty, interactive selection

  if [[ -z "$sid" ]]; then
    sid=$(resolve_session_id)
  fi

  local file="$DECISIONS_DIR/${sid}.jsonl"
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}No decision log for session: $sid${RESET}" >&2
    exit 1
  fi

  local rows
  rows=$(get_promotable "$file")
  if [[ -z "$rows" ]]; then
    echo -e "${MUTED}No promotable entries in session $sid.${RESET}"
    exit 0
  fi

  # If no indices given, show list and promote all
  if [[ ${#indices[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No indices specified — promoting ALL insights/stumbles from $sid${RESET}"
    while IFS='|' read -r idx type ts msg agent; do
      [[ -z "$type" ]] && continue
      indices+=("$idx")
    done <<< "$rows"
  fi

  local promoted=0
  for target_idx in "${indices[@]}"; do
    local found=0
    while IFS='|' read -r idx type ts msg agent; do
      [[ -z "$type" ]] && continue
      [[ "$idx" != "$target_idx" ]] && continue
      found=1

      local tags
      [[ "$type" == "stumble" ]] && tags='"stumble","lesson","agent-gotcha"' || tags='"insight","lesson"'

      local outfile
      outfile=$(write_lesson "$type" "$msg" "$agent" "$sid" "$ts" "$tags")

      local color
      [[ "$type" == "stumble" ]] && color="$RED" || color="$GREEN"
      echo -e "${color}${BOLD}Promoted [${type}]:${RESET} $msg"
      echo -e "  ${MUTED}→ $outfile${RESET}"
      promoted=$((promoted+1))
      break
    done <<< "$rows"

    if [[ $found -eq 0 ]]; then
      echo -e "${YELLOW}No promotable entry at index $target_idx in $sid.${RESET}" >&2
    fi
  done

  echo ""
  echo -e "${GREEN}Promoted $promoted lesson(s) to ${CYAN}$LESSONS_DIR${RESET}"
  echo -e "${MUTED}Future agents will find these at session start: bash spells/promote-insight.sh ls${RESET}"
}

cmd_auto() {
  local sid="${1:-}"
  if [[ -z "$sid" ]]; then
    sid=$(resolve_session_id)
  fi
  cmd_promote "$sid"   # no indices = promote all
}

cmd_show() {
  local slug="${1:-}"
  if [[ -z "$slug" ]]; then
    echo "Usage: bash spells/promote-insight.sh show <lesson-slug>" >&2
    exit 1
  fi
  local file="$LESSONS_DIR/${slug}.md"
  if [[ ! -f "$file" ]]; then
    # try with .md appended
    file="$LESSONS_DIR/${slug}"
    [[ -f "$file" ]] || { echo -e "${RED}Lesson not found: $slug${RESET}" >&2; exit 1; }
  fi
  echo ""
  cat "$file"
  echo ""
}

cmd_ls() {
  echo ""
  echo -e "${MAGENTA}RaBbLE — Durable Lessons (log/lessons/)${RESET}"
  echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${RESET}"

  local count=0
  for file in "$LESSONS_DIR"/*.md; do
    [[ -f "$file" ]] || continue
    local slug
    slug=$(basename "$file" .md)
    local title date type severity
    title=$(grep '^title:' "$file" 2>/dev/null | head -1 | sed 's/^title: *"\?//;s/"\? *$//')
    date=$(grep '^date:' "$file" 2>/dev/null | head -1 | sed 's/^date: *"\?//;s/"\? *$//')
    type=$(grep '^source_type:' "$file" 2>/dev/null | head -1 | sed 's/^source_type: *"\?//;s/"\? *$//')
    severity=$(grep '^severity:' "$file" 2>/dev/null | head -1 | sed 's/^severity: *"\?//;s/"\? *$//')

    local color
    [[ "$type" == "stumble" ]] && color="$RED" || color="$GREEN"

    echo -e "  ${color}[${type:-?}]${RESET} ${TEXT}${title:-$slug}${RESET}"
    echo -e "    ${MUTED}date: $date  slug: $slug${RESET}"
    count=$((count+1))
  done

  if [[ $count -eq 0 ]]; then
    echo -e "  ${MUTED}(no lessons yet — run 'promote' after logging insights/stumbles)${RESET}"
  else
    echo -e ""
    echo -e "  ${MUTED}$count lesson(s) — read at session start for compounded knowledge.${RESET}"
    echo -e "  ${MUTED}bash spells/promote-insight.sh show <slug>${RESET}"
  fi
  echo ""
}

# =============================================================================
# DISPATCH
# =============================================================================

CMD="${1:-}"
shift || true

case "$CMD" in
  list)    cmd_list "${1:-}" ;;
  promote) cmd_promote "$@" ;;
  auto)    cmd_auto "${1:-}" ;;
  show)    cmd_show "${1:-}" ;;
  ls)      cmd_ls ;;
  --help|-h|help|"")
    echo "promote-insight.sh — crystallize insights and stumbles into durable lessons"
    echo ""
    echo "Commands:"
    echo "  list   [session-id]           List promotable entries (all or one session)"
    echo "  promote <sid> [idx...]        Promote specific entries to log/lessons/"
    echo "  auto   [session-id]           Promote all insights/stumbles from a session"
    echo "  show   <lesson-slug>          Print a lesson file"
    echo "  ls                            List all lessons"
    echo ""
    echo "Lesson files: log/lessons/<date>-<slug>.md (frontmatter YAML + markdown body)"
    echo "Future agents read lessons at session start to compound collective knowledge."
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Run 'bash spells/promote-insight.sh --help' for usage." >&2
    exit 1
    ;;
esac
