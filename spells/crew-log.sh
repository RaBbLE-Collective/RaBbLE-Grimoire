#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — crew-log.sh : attribute subagent work to the subagent that did it
#
# A subagent is a thread inside its parent's process, so the process-tree identity in
# lib/session-id.sh can only ever say "the parent session". What a subagent DOES leave is
# its own transcript:  ~/.claude/projects/<proj>/<session>/subagents/agent-<id>.{meta.json,jsonl}
# with its real model, timestamps, every tool call. This spell mines those into
# `subagent` events in the PARENT's log/sessions/*.jsonl (one append-only file per session):
#
#   {type:"subagent", key:<parent>, agent_id, agent_type, description, model:<the subagent's own,
#    from its transcript>, requested_model, started, ended, finished, tools:{Bash:n,...},
#    files:[edited/written paths], commits:[short hashes of `commit` events whose subject
#    appears in this subagent's shell commands]}
#
# Together with `commit` events (which name the session + live peers) this answers "who wrote
# this, with which model, while who else was live" for entropy-drift and bug-blame tracing.
#
# Usage:  bash spells/crew-log.sh sync [--session KEY]    idempotent; default = this session
#         bash spells/crew-log.sh show [--session KEY]    table of this session's crew
# Called by hooks/post-commit and end-session.sh (best-effort). Claude/rabble harnesses only
# (others have no subagent transcripts: sync is a no-op).
# Test hooks: CLAUDE_PROJECTS_DIR, GRIMOIRE_ROOT.
# =============================================================================
set -uo pipefail
GRIMOIRE_ROOT="${GRIMOIRE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/session-log.sh
source "$GRIMOIRE_ROOT/spells/lib/session-log.sh"
PROJECTS="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

cmd="${1:-sync}"; shift || true
key=""
while [[ $# -gt 0 ]]; do case "$1" in --session) key="$2"; shift 2 ;; *) shift ;; esac; done
[[ -z "$key" ]] && key=$(rabble_sid 2>/dev/null || true)
[[ -n "$key" ]] || { echo "crew-log: no session detected" >&2; exit 2; }

sub_dir=$(ls -d "$PROJECTS"/*/"$key"/subagents 2>/dev/null | head -1)
logfile=$(ls "$GRIMOIRE_ROOT"/log/sessions/*-"${key:0:8}".jsonl 2>/dev/null | head -1)

case "$cmd" in
  sync)
    [[ -n "$sub_dir" && -n "$logfile" ]] || exit 0
    parent=$(head -1 "$logfile")
    for meta in "$sub_dir"/agent-*.meta.json; do
      [[ -f "$meta" ]] || continue
      id=$(basename "$meta" .meta.json); id=${id#agent-}
      tr_f="$sub_dir/agent-$id.jsonl"; [[ -f "$tr_f" ]] || continue
      fin=$(jq -r '.finished // false' "$meta")
      # already logged in this state? (an unfinished record is superseded by the finished one)
      jq -e --arg id "$id" --argjson fin "$fin" \
        'select(.type=="subagent" and .agent_id==$id and .finished==$fin)' "$logfile" >/dev/null 2>&1 && continue
      model=$(jq -r 'select(.type=="assistant") | .message.model // empty' "$tr_f" 2>/dev/null | grep -v '^<synthetic>$' | tail -1)
      [[ -n "$model" ]] || model=$(jq -r '.model // "unknown"' "$meta")
      line=$(jq -cn --slurpfile tr <(jq -c . "$tr_f" 2>/dev/null) --slurpfile mt "$meta" \
                    --slurpfile ev <(jq -c 'select(.type=="commit")' "$logfile") \
                    --argjson p "$parent" --arg id "$id" --arg model "$model" --arg prov "$(_rabble_provider_of_model "$model")" \
                    --arg ts "$(date -u +%FT%TZ)" --argjson fin "$fin" '
        ($tr | map(select(.type=="assistant") | .message.content[]? | select(.type=="tool_use"))) as $tu
        | ($tu | map(select(.name=="Bash") | .input.command // "") | join("\n")) as $sh
        | { ts:$ts, type:"subagent", key:$p.key, harness:$p.harness, provider:$prov, model:$model,
            confidence:"transcript", agent_id:$id, agent_type:$mt[0].agentType, description:$mt[0].description,
            requested_model:$mt[0].model, spawn_depth:$mt[0].spawnDepth,
            started:($tr | map(.timestamp // empty) | first), ended:($tr | map(.timestamp // empty) | last),
            finished:$fin,
            tools:($tu | group_by(.name) | map({key:.[0].name, value:length}) | from_entries),
            files:($tu | map(select(.name=="Edit" or .name=="Write" or .name=="NotebookEdit")
                             | .input.file_path // .input.notebook_path // empty) | unique),
            commits:($ev | map(. as $e | select(($e.subject // "") != "" and ($sh | contains($e.subject))) | $e.hash) | unique) }
        | with_entries(select(.value != null))') || continue
      printf '%s\n' "$line" >> "$logfile"
    done
    ;;
  show)
    [[ -n "$logfile" ]] || { echo "(no event log for $key)"; exit 0; }
    echo "crew of ${key:0:8}  ($(head -1 "$logfile" | jq -r '[.harness,.provider,.model]|join(" / ")'))"
    jq -r 'select(.type=="subagent") | [.agent_id[0:8], .agent_type, .model, (if .finished then "done" else "running" end),
           ((.tools // {}) | to_entries | map("\(.key)×\(.value)") | join(" ")),
           "files:\((.files // []) | length)", "commits:\((.commits // []) | join(","))", (.description // "")] | @tsv' "$logfile" \
      | awk -F'\t' '{ last[$1]=$0 } END { for (k in last) print last[k] }' | sort | column -t -s $'\t'
    ;;
  *) echo "Usage: crew-log.sh sync|show [--session KEY]" >&2; exit 1 ;;
esac
