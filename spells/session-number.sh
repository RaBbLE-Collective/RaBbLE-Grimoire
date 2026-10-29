#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — session-number.sh
# Atomic S-number reservation. Two sessions can no longer both pick "max+1".
#
# Usage:
#   bash spells/session-number.sh next            print the next free number (does not reserve)
#   bash spells/session-number.sh claim [topic]   reserve it for THIS session, print "S293"
#   bash spells/session-number.sh show            this session's label, if it has one
#
# How: mkdir is atomic. A reservation is the directory $RUNTIME/numbers/S293, so of
# two racing claims exactly one mkdir succeeds and the other takes the next number.
# The floor is the highest number seen anywhere durable (SESSION-LOG headings,
# handoff/plan filenames, ledger labels, existing reservations), so a fresh machine
# or a wiped cache still starts above everything already written down.
# The label is stored against the session id (lib/session-id.sh); end-session.sh reads
# it instead of inferring the number from the first heading in SESSION-LOG.
#
# spark ~ grimoire >> a number is claimed once, atomically // %SESSION_NUMBER%
# =============================================================================
set -euo pipefail
GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/session-id.sh
source "$GRIMOIRE_ROOT/spells/lib/session-id.sh"
source "$GRIMOIRE_ROOT/spells/lib/session-log.sh"
NUMDIR="$RABBLE_RUNTIME/numbers"

highest_seen() {
  {
    grep -ohE 'Session S[0-9]+' "$GRIMOIRE_ROOT/log/SESSION-LOG.md" 2>/dev/null | grep -oE '[0-9]+$' || true
    ls "$GRIMOIRE_ROOT/log/handoffs" "$GRIMOIRE_ROOT/log/handoffs/done" "$GRIMOIRE_ROOT/log/plans" 2>/dev/null \
      | grep -oE '(HANDOFF-)?S[0-9]{3}' | grep -oE '[0-9]+' || true
    cut -f1,2 "$GRIMOIRE_ROOT/log/token-ledger.tsv" 2>/dev/null | grep -oE '^S[0-9]+' | grep -oE '[0-9]+' || true
    ls "$NUMDIR" 2>/dev/null | grep -oE '[0-9]+' || true
  } | sort -n | tail -1
}

cmd="${1:-show}"; shift || true
case "$cmd" in
  next)
    hs=$(highest_seen || true); echo "S$(( 10#${hs:-0} + 1 ))"
    ;;
  claim)
    sid=$(rabble_sid) || { echo "No session identity (not inside a Claude session; set RABBLE_SESSION_ID)." >&2; exit 1; }
    if have=$(rabble_label "$sid") && [[ -n "$have" ]]; then
      echo "$have"; echo "(this session already holds $have)" >&2; exit 0
    fi
    mkdir -p "$NUMDIR"
    hs=$(highest_seen || true); n=$(( 10#${hs:-0} + 1 ))
    until mkdir "$NUMDIR/S$n" 2>/dev/null; do n=$((n + 1)); done   # lost the race: take the next
    printf '%s\t%s\t%s\n' "$sid" "$(date -u +%FT%TZ)" "${1:-}" > "$NUMDIR/S$n/owner"
    rabble_set_label "$sid" "S$n"
    rabble_log_event label "label=S$n" "topic=${1:-}" 2>/dev/null || true
    echo "S$n"
    ;;
  show)
    sid=$(rabble_sid) || exit 1
    rabble_label "$sid" || { echo "(no number claimed; run: bash spells/session-number.sh claim <topic>)" >&2; exit 1; }
    ;;
  *) echo "Usage: session-number.sh next|claim [topic]|show" >&2; exit 1 ;;
esac
