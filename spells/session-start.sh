#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — session-start.sh
# The opening ritual for ANY session — the front line of anti-clobber.
#
# Clobbering happens DURING editing, long before a commit. So coordination must
# happen at session START, not at commit time. (The pre-commit auto-register in
# log/HANDOFF-PreCommit-AntiClobber.md is only a BACKSTOP for when someone
# forgets this ritual.) Run this first, before touching any file.
#
# It does four things:
#   1. Pins a stable session id (the #1 fix for concurrent sessions — the
#      transcript auto-resolver is a coin-flip when two sessions share a cwd).
#   2. Surfaces shared context: durable lessons, open blockers, who else is live.
#   3. Claims your file-scope so other live sessions get a loud conflict if they
#      try to claim the same ground (agent-register.sh claim, exits 2 on overlap).
#   4. Starts a self-terminating background HEARTBEAT so your claim doesn't die
#      mid-session (claims go stale at 300s, dead at 900s). This removes the
#      "remember to heartbeat" burden that made the system go unused.
#
# AGENT-AGNOSTIC. Pairs with the End-of-session ritual in AGENT.md
# (blockers.sh add/resolve · end-session.sh · promote-insight.sh auto ·
#  agent-register.sh release — release stops the heartbeat within one cycle).
#
# Usage:
#   export RABBLE_SESSION_ID="S131-myfeature"          # DO THIS FIRST (see note)
#   bash spells/session-start.sh "<scope-glob>"... [--task "desc"] [--no-heartbeat]
#   bash spells/session-start.sh                       # context-only (no claim)
#
# Note: a spell cannot export into your shell. If RABBLE_SESSION_ID is unset this
# prints the exact `export` line to run, then continues with a best-effort id.
#
# Env: HEARTBEAT_INTERVAL (default 240s, < the 300s stale threshold).
#
# spark ~ grimoire >> claim the ground before you walk it // %SESSION_START%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPELLS="$GRIMOIRE_ROOT/spells"
AGENTS_DIR="$GRIMOIRE_ROOT/log/agents"
HEARTBEAT_INTERVAL="${HEARTBEAT_INTERVAL:-240}"
mkdir -p "$AGENTS_DIR"

GREEN='\033[38;2;80;250;123m'
CYAN='\033[38;2;0;245;255m'
YELLOW='\033[38;2;241;250;140m'
MAGENTA='\033[38;2;255;45;120m'
RED='\033[38;2;255;85;85m'
MUTED='\033[38;2;107;104;128m'
TEXT='\033[38;2;232;230;240m'
BOLD='\033[1m'
RESET='\033[0m'

# Same resolution as the other spells (RABBLE_SESSION_ID → transcript → commit)
resolve_session_id() {
  if [[ -n "${RABBLE_SESSION_ID:-}" ]]; then echo "$RABBLE_SESSION_ID"; return; fi
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

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
fi

# --- Parse args ---------------------------------------------------------------
task=""; no_heartbeat=false; scopes=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)         task="${2:-}"; shift 2 ;;
    --no-heartbeat) no_heartbeat=true; shift ;;
    -*)             echo "Unknown flag: $1" >&2; exit 1 ;;
    *)              scopes+=("$1"); shift ;;
  esac
done

SID=$(resolve_session_id)

echo ""
echo -e "${MAGENTA}${BOLD}RaBbLE — Session Start${RESET}"
echo -e "${MAGENTA}══════════════════════════════════════════════════════════════${RESET}"

# --- 1. Session id stability --------------------------------------------------
if [[ -n "${RABBLE_SESSION_ID:-}" ]]; then
  echo -e "  ${GREEN}session id:${RESET} ${CYAN}${SID}${RESET} ${MUTED}(pinned via RABBLE_SESSION_ID — good)${RESET}"
else
  echo -e "  ${YELLOW}${BOLD}⚠ RABBLE_SESSION_ID is not set.${RESET}"
  echo -e "  ${YELLOW}Under concurrent sessions the auto-resolved id is unreliable. Pin one:${RESET}"
  echo -e "      ${TEXT}export RABBLE_SESSION_ID=\"S<NN>-<topic>\"${RESET}   ${MUTED}then re-run this${RESET}"
  echo -e "  ${MUTED}continuing best-effort as:${RESET} ${CYAN}${SID}${RESET}"
fi
echo ""

# --- 2. Shared context --------------------------------------------------------
echo -e "${CYAN}── Durable lessons ───────────────────────────────────────────${RESET}"
bash "$SPELLS/promote-insight.sh" ls 2>/dev/null || echo -e "  ${MUTED}(none)${RESET}"
echo ""
echo -e "${CYAN}── Open blockers ─────────────────────────────────────────────${RESET}"
bash "$SPELLS/blockers.sh" ls 2>/dev/null || echo -e "  ${MUTED}(none)${RESET}"
echo ""
echo -e "${CYAN}── Who else is live ──────────────────────────────────────────${RESET}"
bash "$SPELLS/agent-register.sh" status 2>/dev/null || true

# --- 3. Claim scope -----------------------------------------------------------
if [[ ${#scopes[@]} -eq 0 ]]; then
  echo -e "${MUTED}No scope given — context-only start (no claim, no heartbeat).${RESET}"
  echo -e "${MUTED}Claim before editing:  bash spells/session-start.sh \"<glob>\"... --task \"…\"${RESET}"
  echo ""
  exit 0
fi

echo -e "${CYAN}── Claiming scope ────────────────────────────────────────────${RESET}"
# agent-register.sh exits 2 on conflict — let that propagate so the caller stops.
RABBLE_SESSION_ID="$SID" bash "$SPELLS/agent-register.sh" claim "${scopes[@]}" ${task:+--task "$task"}

# --- 4. Background heartbeat (self-terminating) -------------------------------
claimfile="$AGENTS_DIR/${SID}.json"
pidfile="$AGENTS_DIR/${SID}.heartbeat.pid"

if $no_heartbeat; then
  echo -e "${MUTED}Heartbeat skipped (--no-heartbeat). Refresh manually or your claim dies in 900s.${RESET}"
elif [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null; then
  echo -e "${MUTED}Heartbeat already running (pid $(cat "$pidfile")).${RESET}"
else
  # Detached loop: refresh every HEARTBEAT_INTERVAL while the claim file exists.
  # Self-terminates when `agent-register.sh release` removes the claim (≤1 cycle),
  # and is hard-capped so an abandoned session can never heartbeat forever.
  setsid env RABBLE_SESSION_ID="$SID" bash -c '
    claimfile="$1"; interval="$2"; spells="$3"; pidfile="$4"
    i=0; max=240   # cap ~ interval*240 (16h @ 240s)
    while [[ -f "$claimfile" && $i -lt $max ]]; do
      sleep "$interval"
      [[ -f "$claimfile" ]] || break
      bash "$spells/agent-register.sh" heartbeat >/dev/null 2>&1 || true
      i=$((i+1))
    done
    rm -f "$pidfile"
  ' _ "$claimfile" "$HEARTBEAT_INTERVAL" "$SPELLS" "$pidfile" >/dev/null 2>&1 < /dev/null &
  hb_pid=$!
  disown "$hb_pid" 2>/dev/null || true
  echo "$hb_pid" > "$pidfile"
  echo -e "${GREEN}Heartbeat daemon started${RESET} ${MUTED}(pid $hb_pid, every ${HEARTBEAT_INTERVAL}s; stops on release).${RESET}"
fi

echo ""
echo -e "${GREEN}Ready.${RESET} ${MUTED}Edit within your claimed scope. At session end:${RESET}"
echo -e "  ${TEXT}bash spells/agent-register.sh release${RESET}  ${MUTED}(also stops the heartbeat)${RESET}"
echo ""
