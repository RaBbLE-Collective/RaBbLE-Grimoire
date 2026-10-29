#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — spells/lib/session-log.sh   (source it; needs GRIMOIRE_ROOT)
#
# One append-only event file PER SESSION: log/sessions/<date>-<harness>-<key8>.jsonl
# Only the owning session ever writes its file, so concurrent sessions cannot clobber
# each other by construction. Shared views (ledger, LATEST, history) are derived.
# Works for any harness lib/session-id.sh recognises; every event names the harness,
# provider and model AT THAT MOMENT, so a mid-session /model switch shows up in the
# next event.
#
#   rabble_session_logfile          path of this session's file (stable for the session)
#   rabble_log_event TYPE [k=v ...] append one JSON line (creates the file with a 'start')
#
# Event types in use: start, label, commit, end. Unknown types are fine; readers
# must ignore what they do not know. Never edit these files by hand.
# =============================================================================
# shellcheck source=session-id.sh
source "$(dirname "${BASH_SOURCE[0]}")/session-id.sh"

rabble_session_logfile() {
  local rec key harness started day short
  rec=$(rabble_session_json 2>/dev/null) || return 1
  key=$(jq -r .key <<<"$rec"); harness=$(jq -r .harness <<<"$rec"); started=$(jq -r .started <<<"$rec")
  [[ "$started" =~ ^[0-9]+$ && "$started" -gt 0 ]] || started=$(date +%s)
  day=$(date -d "@$started" +%F)
  short=${key#"$harness"-}; short=${short:0:8}
  echo "$GRIMOIRE_ROOT/log/sessions/$day-$harness-$short.jsonl"
}

rabble_log_event() {
  local type="$1"; shift
  local rec f line kv k v extra='{}'
  rec=$(rabble_session_json 2>/dev/null) || return 1
  f=$(rabble_session_logfile) || return 1
  mkdir -p "$(dirname "$f")"
  for kv in "$@"; do
    k=${kv%%=*}; v=${kv#*=}
    extra=$(jq -c --arg k "$k" --arg v "$v" '. + {($k): $v}' <<<"$extra")
  done
  _emit() {
    jq -cn --argjson r "$rec" --arg type "$1" --arg label "$(rabble_label "$(jq -r .key <<<"$rec")" || true)" \
      --arg ts "$(date -u +%FT%TZ)" --argjson x "$2" \
      '{ts:$ts, type:$type, key:$r.key, harness:$r.harness, provider:$r.provider, model:$r.model,
        confidence:$r.confidence}
       + (if $label != "" then {label:$label} else {} end) + $x
       | with_entries(select(.value != null))'
  }
  if [[ ! -s "$f" ]]; then
    printf '%s\n' "$(_emit start "$(jq -cn --argjson r "$rec" '{pid:$r.pid, cwd:$r.cwd, started:$r.started, native_id:$r.native_id}')")" >> "$f"
  fi
  [[ "$type" == start && -s "$f" ]] && return 0       # start is idempotent
  line=$(_emit "$type" "$extra")
  printf '%s\n' "$line" >> "$f"                        # single O_APPEND write: atomic for lines < PIPE_BUF
}
