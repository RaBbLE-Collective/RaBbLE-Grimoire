#!/usr/bin/env bash
# anti-clobber.test.sh — builds a throwaway Grimoire and attacks it with concurrent sessions.
# Usage: bash spells/tests/anti-clobber.test.sh           (tests the installed scripts)
#        END_SESSION_SCRIPT=/tmp/x.sh bash spells/tests/anti-clobber.test.sh   (tests a candidate)
# Touches nothing real: the sandbox has its own spells copy, log/, and runtime dir.
set -uo pipefail
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SB=$(mktemp -d); trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/g/log" "$SB/g/spells" "$SB/rt"
cp -r "$REAL/spells/lib" "$SB/g/spells/"
for f in end-session.sh session-number.sh crew-log.sh; do cp "$REAL/spells/$f" "$SB/g/spells/"; done
[[ -n "${END_SESSION_SCRIPT:-}" ]] && cp "$END_SESSION_SCRIPT" "$SB/g/spells/end-session.sh"
[[ -n "${SESSION_NUMBER_SCRIPT:-}" ]] && cp "$SESSION_NUMBER_SCRIPT" "$SB/g/spells/session-number.sh"
export RABBLE_RUNTIME_DIR="$SB/rt" CLAUDE_SESSIONS_DIR="$SB/empty"; mkdir -p "$SB/empty"
G="$SB/g"; pass=0; fail=0
ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
bad()  { echo "  ✗ $1"; fail=$((fail+1)); }
fresh() {
  printf 'aaaa\tfeat-a\tS1 note\nbbbb\tfeat-b\tS2 note\ncccc\tfeat-c\tS3 note\n' > "$G/log/token-ledger.tsv"
  printf '# SESSION-LOG\n\n---\n\n## LATEST — 2026-10-29 · Session S%s (x)\n\n**Phase:** p.\n**This session:** old\n**Blockers:** b\n**Next:** n\n\n---\n\n## 2026-10-29 · Session S%s (x)\n' "${1:-5}" "${1:-5}" > "$G/log/SESSION-LOG.md"
  (cd "$G" && git init -q 2>/dev/null; true)
}
es() { (cd "$G" && bash spells/end-session.sh "$@" 2>&1); }

echo "T1 own row replaced, others untouched"
fresh; es feat-new "n" --sid aaaa >/dev/null
[[ $(grep -c . "$G/log/token-ledger.tsv") == 3 ]] && grep -q $'^bbbb\tfeat-b' "$G/log/token-ledger.tsv" && grep -q $'^cccc\tfeat-c' "$G/log/token-ledger.tsv" && grep -q $'^aaaa\tfeat-new' "$G/log/token-ledger.tsv" \
  && ok "aaaa updated, bbbb/cccc intact" || bad "ledger wrong: $(cat "$G/log/token-ledger.tsv")"

echo "T2 refuses to drop other sessions' rows"
fresh; printf 'dup\tx\t1\ndup\ty\t2\ndup\tz\t3\n' >> "$G/log/token-ledger.tsv"; before=$(cat "$G/log/token-ledger.tsv")
out=$(es feat-new --sid dup); [[ "$(cat "$G/log/token-ledger.tsv")" == "$before" ]] && grep -q REFUSED <<<"$out" \
  && ok "refused, ledger byte-identical" || bad "ledger changed or no refusal"

echo "T3 never overwrites a NEWER LATEST"
fresh 300; es feat-x "n" --sid aaaa --session S299 --synopsis "stale" --next "nope" >/dev/null
grep -q 'Session S300' "$G/log/SESSION-LOG.md" && ! grep -q stale "$G/log/SESSION-LOG.md" && ok "S300 LATEST preserved" || bad "LATEST clobbered"
es feat-x "n" --sid aaaa --session S301 --synopsis "fresh" --next "go" >/dev/null
grep -q 'S301' "$G/log/SESSION-LOG.md" && grep -q fresh "$G/log/SESSION-LOG.md" && ok "newer session still updates LATEST" || bad "legit LATEST update blocked"

echo "T4 two sessions ending at once both keep their rows"
fresh; for s in s1 s2 s3 s4 s5 s6; do ( es "feat-$s" "n" --sid "$s" >/dev/null ) & done; wait
n=$(grep -c . "$G/log/token-ledger.tsv"); miss=0
for s in s1 s2 s3 s4 s5 s6; do grep -q "^$s	feat-$s" "$G/log/token-ledger.tsv" || miss=1; done
[[ $n == 9 && $miss == 0 ]] && ok "9 rows: 3 original + 6 concurrent" || bad "rows=$n missing=$miss"

echo "T5 label stored by session-number is used for LATEST"
fresh 5; (cd "$G" && RABBLE_SID=lbl bash spells/session-number.sh claim t >/dev/null)
want=$(cd "$G" && RABBLE_SID=lbl bash spells/session-number.sh show)
es feat-l "n" --sid lbl --synopsis "labelled" >/dev/null
grep -q "$want" "$G/log/SESSION-LOG.md" && ok "LATEST carries $want" || bad "label not used"

echo "T6 no agent + no env: fallback key, never a transcript guess"
fresh; out=$(cd "$G" && env -u RABBLE_SESSION_ID -u RABBLE_SID bash spells/end-session.sh feat-f 2>&1)
grep -q "fallback key 'commit-" <<<"$out" && ok "fell back to commit key" || bad "no fallback: $out"

echo "T7 ledger + event log record WHO the session is (harness/provider/model)"
fresh; es feat-w "n" --sid whoami-1 >/dev/null
row=$(grep '^whoami-1' "$G/log/token-ledger.tsv")
IFS=$'\t' read -r _ _ _ h p m <<<"$row"
[[ "$h" == manual && -n "$p" && -n "$m" ]] && ok "ledger row carries harness=$h provider=$p model=$m" || bad "provenance missing: $row"
lf="$G/log/sessions/$(ls "$G"/log/sessions | grep whoami)"
[[ -f "$lf" ]] && [[ "$(jq -r .type "$lf" | tr '\n' ' ')" == "start end " ]] && ok "event file: start then end" || bad "event file wrong: $(cat "$lf" 2>/dev/null)"

echo "T8 model + harness come from env for non-Claude agents, per event"
fresh; rm -rf "$G/log/sessions"
(cd "$G" && RABBLE_HARNESS=codex RABBLE_MODEL=gpt-5 bash spells/end-session.sh feat-c "n" --sid cx-1 >/dev/null 2>&1)
(cd "$G" && RABBLE_HARNESS=gemini RABBLE_MODEL=gemini-3-pro bash spells/end-session.sh feat-g "n" --sid gm-1 >/dev/null 2>&1)
c=$(grep '^cx-1' "$G/log/token-ledger.tsv"); g=$(grep '^gm-1' "$G/log/token-ledger.tsv")
[[ "$c" == *$'\tcodex\topenai\tgpt-5' && "$g" == *$'\tgemini\tgoogle\tgemini-3-pro' ]] && ok "codex/openai/gpt-5 and gemini/google/gemini-3-pro recorded" || bad "c=$c g=$g"
[[ $(ls "$G"/log/sessions/*.jsonl | wc -l) == 2 ]] && ok "one event file per session (no shared file)" || bad "event files: $(ls "$G"/log/sessions)"
cf=$(ls "$G"/log/sessions/*codex*.jsonl); [[ "$(jq -r '[.type,.harness,.provider,.model]|join("/")' "$cf" | tr '\n' ' ')" == "start/codex/openai/gpt-5 end/codex/openai/gpt-5 " ]] \
  && ok "events say codex/openai/gpt-5 on both lines" || bad "codex events: $(cat "$cf")"

echo "T9 six sessions log at once; every event file is valid JSONL"
fresh; rm -rf "$G/log/sessions"
for s in p1 p2 p3 p4 p5 p6; do ( cd "$G" && RABBLE_HARNESS=aider RABBLE_MODEL=gpt-5-mini bash spells/session-number.sh claim "t$s" >/dev/null 2>&1; true ) & done; wait
for s in p1 p2 p3 p4 p5 p6; do ( cd "$G" && RABBLE_SID=$s RABBLE_HARNESS=aider RABBLE_MODEL=gpt-5-mini bash spells/session-number.sh claim "t$s" >/dev/null 2>&1 ) & done; wait
bad_lines=0; for f in "$G"/log/sessions/*.jsonl; do [[ $(jq -s 'map(select(.type)) | length' "$f" 2>/dev/null) -ge 2 ]] || bad_lines=1; done
[[ $(ls "$G"/log/sessions/*.jsonl | wc -l) == 6 && $bad_lines == 0 ]] && ok "6 files, all valid JSONL" || bad "files=$(ls "$G"/log/sessions | wc -l) invalid=$bad_lines"

echo "T10 peers: a live claude peer reports its real model (from its transcript), not 'unknown'"
fresh; PD="$SB/home/.claude/projects/-x"; mkdir -p "$PD" "$SB/sess"
env -u CLAUDE_CODE_ENTRYPOINT sleep 60 & PEER=$!; trap 'kill $PEER 2>/dev/null; rm -rf "$SB"' EXIT
printf '{"sessionId":"peer0000-aaaa","cwd":"/x","startedAt":%s}\n' "$(( $(date +%s) * 1000 ))" > "$SB/sess/$PEER.json"
printf '{"type":"assistant","message":{"model":"claude-opus-5-5","content":[]}}\n' > "$PD/peer0000-aaaa.jsonl"
out=$(HOME="$SB/home" CLAUDE_SESSIONS_DIR="$SB/sess" RABBLE_AGENT_PID=$PEER RABBLE_TRUST_AGENT_PID=1 RABBLE_SID=me-1 bash -c "source $G/spells/lib/session-id.sh; rabble_live_peers")
[[ "$out" == peer0000-aaaa*claude*claude-opus-5-5 ]] && ok "peer model = claude-opus-5-5" || bad "peer line: $out"

echo "T11 start/commit/end events record the live peers"
rm -rf "$G/log/sessions"; mkdir -p "$G/log/sessions"
(cd "$G" && HOME="$SB/home" CLAUDE_SESSIONS_DIR="$SB/sess" RABBLE_AGENT_PID=$PEER RABBLE_TRUST_AGENT_PID=1 RABBLE_SID=me-1 RABBLE_HARNESS=aider RABBLE_MODEL=gpt-5 \
  bash -c "source spells/lib/session-log.sh; GRIMOIRE_ROOT=$G rabble_log_event commit hash=abc subject=hi" ) >/dev/null 2>&1
lf=$(ls "$G"/log/sessions/*.jsonl 2>/dev/null | head -1)
[[ -n "$lf" && "$(jq -r 'select(.type=="commit") | .peers[0]' "$lf")" == peer0000:claude:claude-opus-5-5 ]] && ok "commit event lists peer0000:claude:claude-opus-5-5" || bad "peers missing: $(cat "$lf" 2>/dev/null | tail -1)"
kill $PEER 2>/dev/null

echo "T12 crew-log: subagent work is attributed to the subagent, idempotently"
rm -rf "$G/log/sessions"; mkdir -p "$G/log/sessions" "$SB/proj/-x/par00000-1111/subagents"
printf '{"type":"start","key":"par00000-1111","harness":"rabble","provider":"anthropic","model":"claude-sonnet-5-5"}\n{"type":"commit","hash":"c0ffee1","subject":"mend ~ x >> by subagent // %%S%%"}\n' > "$G/log/sessions/2026-10-29-rabble-par00000.jsonl"
SD="$SB/proj/-x/par00000-1111/subagents"
echo '{"agentType":"general-purpose","description":"writer","model":"haiku","spawnDepth":1,"finished":true}' > "$SD/agent-ag1.meta.json"
cat > "$SD/agent-ag1.jsonl" <<'J'
{"type":"assistant","timestamp":"2026-10-29T10:00:00Z","message":{"model":"claude-haiku-5-5","content":[{"type":"tool_use","name":"Write","input":{"file_path":"/r/a.md"}},{"type":"tool_use","name":"Bash","input":{"command":"git commit -m \"mend ~ x >> by subagent // %S%\""}}]}}
{"type":"assistant","timestamp":"2026-10-29T10:05:00Z","message":{"model":"claude-haiku-5-5","content":[]}}
J
run() { (cd "$G" && CLAUDE_PROJECTS_DIR="$SB/proj" bash spells/crew-log.sh sync --session par00000-1111); }
run; run
ev=$(jq -c 'select(.type=="subagent")' "$G"/log/sessions/*.jsonl)
[[ -n "$ev" && $(wc -l <<<"$ev") == 1 ]] && ok "logged once across two syncs" || bad "events: $ev"
[[ "$(jq -r '[.model,.requested_model,.key,.harness]|join("/")' <<<"$ev")" == claude-haiku-5-5/haiku/par00000-1111/rabble ]] && ok "own model claude-haiku-5-5 under the parent key" || bad "identity: $ev"
[[ "$(jq -r '[(.files|join(",")),(.commits|join(",")),.tools.Bash,.started,.ended]|join(" ")' <<<"$ev")" == "/r/a.md c0ffee1 1 2026-10-29T10:00:00Z 2026-10-29T10:05:00Z" ]] && ok "files, commit hash (matched by subject), tools, span" || bad "payload: $ev"
echo '{"agentType":"general-purpose","description":"writer","model":"haiku","spawnDepth":1,"finished":false}' > "$SD/agent-ag2.meta.json"; cp "$SD/agent-ag1.jsonl" "$SD/agent-ag2.jsonl"
run; echo '{"agentType":"general-purpose","description":"writer","model":"haiku","spawnDepth":1,"finished":true}' > "$SD/agent-ag2.meta.json"; run; run
[[ $(jq -r 'select(.type=="subagent" and .agent_id=="ag2")|.finished' "$G"/log/sessions/*.jsonl | tr '\n' ' ') == "false true " ]] && ok "running then finished: two records, then stable" || bad "ag2 states: $(jq -c 'select(.agent_id=="ag2")|.finished' "$G"/log/sessions/*.jsonl | tr '\n' ' ')"

echo "T13 session-number show: unclaimed is a state, not a failure"
fresh; (cd "$G" && RABBLE_SID=unl-1 bash spells/session-number.sh show >/dev/null 2>&1); [[ $? == 0 ]] && ok "exit 0 when nothing claimed" || bad "exit $?"

echo; echo "passed $pass, failed $fail"; exit $fail
