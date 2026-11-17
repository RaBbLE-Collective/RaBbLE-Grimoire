#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — spells/lib/session-id.sh   (source it; do not execute)
#
# Harness-agnostic answer to "which session am I, and who is it?" for every spell
# and hook. Replaces four copies of "newest transcript in ~/.claude/projects/$(pwd)",
# which picked the wrong session whenever two were live (ledger rows clobbered,
# commits filed under a stranger, one session's work swept into another's commit).
#
# How: walk this process's ancestors; the first one an ADAPTER recognises is the agent.
#   claude / rabble   ~/.claude/sessions/<pid>.json  (exact id; procStart guards PID reuse).
#                     CLAUDE_CODE_ENTRYPOINT=sdk-py  =>  launched by the rabble TUI.
#   codex             process name; native id from the rollout file the process holds open
#                     (else derived from the newest rollout for this cwd: flagged "derived")
#   gemini opencode aider antigravity (and any name added to RABBLE_HARNESS_NAMES)
#                     process-level identity  <harness>-<pid>-<procStart>
# Every record carries: key, harness, provider, model, confidence (exact|derived|process),
# pid, started, cwd. Model/provider are read at call time, so a model switch mid-session
# is visible to the next event (events record it; see lib/session-log.sh).
#
# Functions (silent on failure, return 1 when nothing resolves):
#   rabble_session_json       the full record as one JSON line
#   rabble_sid                canonical key: RABBLE_SID > agent record key > RABBLE_SESSION_ID
#   rabble_agent_pid / rabble_session_started / rabble_session_alive ID
#   rabble_live_peers         TSV of OTHER live sessions: key pid started cwd harness model
#   rabble_label [ID] / rabble_set_label ID LABEL
# Pure helpers (unit-tested): _rabble_classify_argv, _rabble_model_from_argv,
#                             _rabble_provider_of_model
#
# Test hooks: CLAUDE_SESSIONS_DIR, RABBLE_AGENT_PID (+RABBLE_TRUST_AGENT_PID=1),
#             RABBLE_RUNTIME_DIR, CODEX_HOME.
# =============================================================================

RABBLE_SESSIONS_DIR="${CLAUDE_SESSIONS_DIR:-$HOME/.claude/sessions}"
RABBLE_RUNTIME="${RABBLE_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/rabble}"
RABBLE_HARNESS_NAMES="${RABBLE_HARNESS_NAMES:-codex gemini opencode aider antigravity agy}"

# ── pure helpers ──────────────────────────────────────────────────────────────

# argv0 basename -> harness name, or nothing. Handles node/python wrappers by also
# looking at argv1 ("node /usr/lib/.../bin/codex").
_rabble_classify_argv() {
  local a0 a1 n
  a0=$(basename "${1:-}" 2>/dev/null); a1=$(basename "${2:-}" 2>/dev/null)
  for n in $RABBLE_HARNESS_NAMES; do
    if [[ "$a0" == "$n" || "$a1" == "$n" ]]; then
      [[ "$n" == agy ]] && n=antigravity
      echo "$n"; return 0
    fi
  done
  return 1
}

# extracts --model X / --model=X / -m X from an argv string (space separated)
_rabble_model_from_argv() {
  local s=" $1 "
  if   [[ "$s" =~ [[:space:]]--model[=[:space:]]+([^[:space:]]+) ]]; then echo "${BASH_REMATCH[1]}"
  elif [[ "$s" =~ [[:space:]]-m[[:space:]]+([^[:space:]]+) ]];       then echo "${BASH_REMATCH[1]}"
  else return 1; fi
}

# model id/alias -> vendor. "via-router" when it clearly is a routed open model.
_rabble_provider_of_model() {
  case "${1,,}" in
    claude*|sonnet*|opus*|haiku*|fable*)           echo anthropic ;;
    gpt-oss*)                                      echo via-router ;;
    gpt*|o[0-9]*|codex*|chatgpt*)                  echo openai ;;
    gemini*|gemma*|antigravity*)                   echo google ;;
    grok*)                                         echo xai ;;
    mistral*|codestral*|ministral*)                echo mistral ;;
    deepseek*|qwen*|kimi*|llama*|glm*|minimax*|nemotron*) echo via-router ;;
    ""|unknown)                                    echo unknown ;;
    *)                                             echo other ;;
  esac
}

# ── process plumbing ──────────────────────────────────────────────────────────

_rabble_procstart() {   # starttime in clock ticks; tolerant of spaces/parens in comm
  [[ -r "/proc/$1/stat" ]] || return 1
  sed 's/^.*) //' "/proc/$1/stat" 2>/dev/null | awk '{print $20}'
}
_rabble_ppid() { sed 's/^.*) //' "/proc/$1/stat" 2>/dev/null | awk '{print $2}'; }
_rabble_argv() { tr '\0' ' ' < "/proc/$1/cmdline" 2>/dev/null; }
_rabble_epoch_of_pid() {  # process start as epoch seconds
  local t b
  t=$(_rabble_procstart "$1") || return 1
  b=$(awk '/^btime/{print $2}' /proc/stat)
  echo $(( b + t / $(getconf CLK_TCK) ))
}

_rabble_claude_file_valid() {   # 0 if ~/.claude/sessions/<pid>.json matches the live process
  local pid="$1" f="$RABBLE_SESSIONS_DIR/$1.json" want have
  [[ -f "$f" ]] || return 1
  if [[ "${RABBLE_TRUST_AGENT_PID:-}" == 1 && "$pid" == "${RABBLE_AGENT_PID:-}" ]]; then return 0; fi
  [[ -d "/proc/$pid" ]] || return 1
  want=$(jq -r '.procStart // empty' "$f" 2>/dev/null) || return 1
  have=$(_rabble_procstart "$pid") || return 1
  [[ -z "$want" || "$want" == "$have" ]]
}

# newest claude transcript model for a session id (resolved id like claude-sonnet-5-5)
_rabble_claude_model_from_transcript() {
  local sid="$1" cwd="$2" f
  f="$HOME/.claude/projects/$(tr '/' '-' <<<"$cwd")/$sid.jsonl"
  [[ -f "$f" ]] || f=$(ls "$HOME"/.claude/projects/*/"$sid".jsonl 2>/dev/null | head -1)
  [[ -f "$f" ]] || return 1
  tail -n 400 "$f" 2>/dev/null | jq -r 'select(.type=="assistant") | .message.model // empty' 2>/dev/null \
    | grep -v '^<synthetic>$' | tail -1
}

_rabble_codex_session_for() {   # pid cwd -> "id<TAB>confidence"
  local pid="$1" cwd="$2" home="${CODEX_HOME:-$HOME/.codex}" f id
  f=$(ls -l "/proc/$pid/fd" 2>/dev/null | grep -oE "$home/sessions/[^ ]*rollout-[^ ]*\.jsonl" | head -1)
  if [[ -n "$f" ]]; then
    id=$(head -1 "$f" | jq -r '.payload.id // empty' 2>/dev/null)
    [[ -n "$id" ]] && { printf '%s\texact\n' "$id"; return 0; }
  fi
  # fallback: newest rollout touched in the last 15 min whose cwd matches. A guess; flagged.
  while IFS= read -r f; do
    [[ "$(head -1 "$f" | jq -r '.payload.cwd // empty' 2>/dev/null)" == "$cwd" ]] || continue
    id=$(head -1 "$f" | jq -r '.payload.id // empty' 2>/dev/null)
    [[ -n "$id" ]] && { printf '%s\tderived\n' "$id"; return 0; }
  done < <(find "$home/sessions" -name 'rollout-*.jsonl' -mmin -15 -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -5 | cut -d' ' -f2-)
  return 1
}

# ── the record ────────────────────────────────────────────────────────────────

rabble_session_json() {
  local p argv a0 a1 harness="" key="" conf="" model="" cwd="" started="" pid="" native="" entry=""

  if [[ -n "${RABBLE_AGENT_PID:-}" ]]; then p="$RABBLE_AGENT_PID"; else p=$$; fi
  while [[ -n "$p" && "$p" -gt 1 ]]; do
    if _rabble_claude_file_valid "$p"; then
      pid="$p"; native=$(jq -r '.sessionId // empty' "$RABBLE_SESSIONS_DIR/$p.json")
      cwd=$(jq -r '.cwd // ""' "$RABBLE_SESSIONS_DIR/$p.json")
      started=$(jq -r '(.startedAt // 0) / 1000 | floor' "$RABBLE_SESSIONS_DIR/$p.json")
      entry=$(tr '\0' '\n' < "/proc/$p/environ" 2>/dev/null | sed -n 's/^CLAUDE_CODE_ENTRYPOINT=//p' | head -1)
      harness=claude; [[ "$entry" == sdk-py ]] && harness=rabble
      key="$native"; conf=exact
      model=$(_rabble_model_from_argv "$(_rabble_argv "$p")" || true)
      model=$(_rabble_claude_model_from_transcript "$native" "$cwd" || echo "$model")
      break
    fi
    argv=$(_rabble_argv "$p"); a0=${argv%% *}; a1=${argv#* }; a1=${a1%% *}
    if h=$(_rabble_classify_argv "$a0" "$a1"); then
      harness="$h"; pid="$p"; cwd=$(readlink "/proc/$p/cwd" 2>/dev/null)
      started=$(_rabble_epoch_of_pid "$p" || echo 0)
      model=$(_rabble_model_from_argv "$argv" || true)
      if [[ "$h" == codex ]] && r=$(_rabble_codex_session_for "$p" "$cwd"); then
        native=${r%%$'\t'*}; conf=${r##*$'\t'}; key="codex-$native"
        [[ -z "$model" ]] && model=$(sed -n 's/^model *= *"\(.*\)"/\1/p' "${CODEX_HOME:-$HOME/.codex}/config.toml" 2>/dev/null | head -1)
      else
        key="$h-$p-$(_rabble_procstart "$p")"; conf=process
      fi
      break
    fi
    [[ -n "${RABBLE_AGENT_PID:-}" ]] && break
    p=$(_rabble_ppid "$p")
  done

  if [[ -z "$key" ]]; then
    # not inside a recognised harness: env override only
    key="${RABBLE_SID:-${RABBLE_SESSION_ID:-}}"; [[ -n "$key" ]] || return 1
    harness="${RABBLE_HARNESS:-manual}"; conf=declared; cwd="$PWD"; started=$(date +%s)
    model="${RABBLE_MODEL:-}"
  fi
  [[ -n "${RABBLE_SID:-}" ]] && key="$RABBLE_SID"
  [[ -n "${RABBLE_MODEL:-}" ]] && model="$RABBLE_MODEL"

  jq -cn --arg key "$key" --arg harness "$harness" --arg model "${model:-unknown}" \
    --arg provider "$(_rabble_provider_of_model "$model")" --arg conf "$conf" \
    --arg pid "${pid:-}" --arg started "${started:-0}" --arg cwd "$cwd" --arg native "$native" \
    '{key:$key, harness:$harness, provider:$provider, model:$model, confidence:$conf,
      pid:($pid|tonumber? // null), started:($started|tonumber? // 0), cwd:$cwd, native_id:$native}'
}

_rabble_field() { rabble_session_json 2>/dev/null | jq -r ".$1 // empty"; }
rabble_sid()             { _rabble_field key | grep . ; }
rabble_agent_pid()       { _rabble_field pid | grep -v '^null$' | grep . ; }
rabble_session_started() { _rabble_field started | grep -v '^0$' | grep . ; }

rabble_session_alive() {
  local id="$1" f pid
  [[ -n "$id" ]] || return 1
  for f in "$RABBLE_SESSIONS_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    [[ "$(jq -r '.sessionId // empty' "$f" 2>/dev/null)" == "$id" ]] || continue
    _rabble_claude_file_valid "$(basename "$f" .json)" && return 0
  done
  # non-claude process keys: <harness>-<pid>-<procStart>
  if [[ "$id" =~ ^([a-z]+)-([0-9]+)-([0-9]+)$ ]]; then
    [[ "$(_rabble_procstart "${BASH_REMATCH[2]}")" == "${BASH_REMATCH[3]}" ]] && return 0
  fi
  return 1
}

rabble_live_peers() {
  local me f pid sid argv p h
  me=$(rabble_sid 2>/dev/null || true)
  for f in "$RABBLE_SESSIONS_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    pid=$(basename "$f" .json)
    _rabble_claude_file_valid "$pid" || continue
    sid=$(jq -r '.sessionId // empty' "$f" 2>/dev/null)
    [[ -n "$sid" && "$sid" != "$me" ]] || continue
    h=claude; tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -q '^CLAUDE_CODE_ENTRYPOINT=sdk-py$' && h=rabble
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$sid" "$pid" \
      "$(jq -r '(.startedAt // 0) / 1000 | floor' "$f")" "$(jq -r '.cwd // ""' "$f")" "$h" \
      "$(_rabble_claude_model_from_transcript "$sid" "$(jq -r '.cwd // ""' "$f")" || _rabble_model_from_argv "$(_rabble_argv "$pid")" || echo unknown)"
  done
  # other harnesses: any running process whose argv0 classifies, excluding our own ancestry
  while read -r p argv; do
    h=$(_rabble_classify_argv "${argv%% *}" "$(cut -d' ' -f2 <<<"$argv")") || continue
    sid="$h-$p-$(_rabble_procstart "$p")"
    [[ "$sid" == "$me" ]] && continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$sid" "$p" "$(_rabble_epoch_of_pid "$p")" \
      "$(readlink "/proc/$p/cwd" 2>/dev/null)" "$h" "$(_rabble_model_from_argv "$argv" || echo unknown)"
  done < <(ps -eo pid=,args= 2>/dev/null | awk '{print}' | grep -E "(^| )[^ ]*/?($(tr ' ' '|' <<<"$RABBLE_HARNESS_NAMES"))( |$)" | grep -v grep | head -20)
}

rabble_label() {
  local id="${1:-$(rabble_sid 2>/dev/null || true)}"
  [[ -n "$id" && -f "$RABBLE_RUNTIME/labels/$id" ]] && cat "$RABBLE_RUNTIME/labels/$id"
}
rabble_set_label() { mkdir -p "$RABBLE_RUNTIME/labels"; printf '%s\n' "$2" > "$RABBLE_RUNTIME/labels/$1"; }
