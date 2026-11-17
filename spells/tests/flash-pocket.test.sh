#!/usr/bin/env bash
# flash-pocket.test.sh: tests spells/flash-pocket.sh with a mock sCoRE (127.0.0.1:8011) and a mock Pocket on a pty.
# Usage: bash spells/tests/flash-pocket.test.sh      No hardware, no prod, no real password (the test one is "pw").
set -uo pipefail
REAL="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SP="$REAL/spells/flash-pocket.sh"
SB=$(mktemp -d); trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$SB"' EXIT
pass=0; fail=0
ok()  { echo "  ✓ $1"; pass=$((pass+1)); }
bad() { echo "  ✗ $1"; fail=$((fail+1)); }
KEYV="rbdv_TESTKEY_$(printf 'x%.0s' $(seq 1 230))"   # long enough to force += chunking

cat > "$SB/mock.py" <<'PY'
import http.server, json, sys, os
LOG = sys.argv[1]
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def _send(self, code, obj):
        b = json.dumps(obj).encode(); self.send_response(code)
        self.send_header("Content-Type", "application/json"); self.send_header("Content-Length", str(len(b)))
        self.end_headers(); self.wfile.write(b)
    def _body(self):
        n = int(self.headers.get("Content-Length") or 0); return json.loads(self.rfile.read(n) or b"{}")
    def _rec(self, extra=""):
        open(LOG, "a").write("%s %s auth=%s %s\n" % (self.command, self.path, "yes" if self.headers.get("Authorization") == "Bearer tok_test" else "no", extra))
    def do_POST(self):
        b = self._body()
        if self.path == "/api/v1/auth/login":
            self._rec("user=%s" % b.get("identifier"))
            if b.get("password") == "pw": return self._send(200, {"token": "tok_test", "tier": "admin"})
            return self._send(401, {"detail": "bad"})
        if self.path == "/api/v1/devices":
            self._rec("label=%s" % b.get("label"))
            if self.headers.get("Authorization") != "Bearer tok_test": return self._send(401, {"detail": "no"})
            return self._send(201, {"id": "dev1", "label": b.get("label"), "key": os.environ["MOCK_KEY"]})
        self._send(404, {})
    def do_DELETE(self):
        self._rec(); self._send(200, {"ok": True})
http.server.HTTPServer(("127.0.0.1", 8011), H).serve_forever()
PY

cat > "$SB/pocket.py" <<'PY'
import os, pty, sys, termios, json, tty
LOG, HASKEY, REFUSE = sys.argv[1], sys.argv[2] == "1", sys.argv[3] == "1"
m, s = pty.openpty(); tty.setraw(s)
print(os.ttyname(s), flush=True)
tok = "x" if HASKEY else ""
buf = b""
while True:
    try: d = os.read(m, 4096)
    except OSError: break
    buf += d
    while b"\n" in buf:
        ln, buf = buf.split(b"\n", 1); ln = ln.decode().strip()
        if ln == ">status":
            os.write(m, ("@status " + json.dumps({"beam": {"token": bool(tok), "state": "Linked" if tok else "Not set up"}, "wifi": {"state": "off"}}) + "\r\n").encode())
        elif ln.startswith(">beam.token"):
            if REFUSE: os.write(m, b"@setup beam.token: error: token over 255 characters\r\n"); continue
            v = ln.split("=", 1)[1]; tok = v if ln.startswith(">beam.token=") else tok + v
            open(LOG, "a").write("cmd %s len=%d\n" % (ln.split("=")[0], len(v)))
            os.write(m, b"@setup beam.token: ok\r\n")
        elif ln.startswith(">"):
            open(LOG, "a").write("cmd %s\n" % ln.split("=")[0]); os.write(m, ("@setup %s: ok\r\n" % ln[1:].split("=")[0]).encode())
PY

# Runs the spell in a pty so /dev/tty exists; feeds $ANSWERS (one line per prompt, in order) when each prompt appears.
cat > "$SB/drive.py" <<'PY'
import os, pty, sys, select, time
answers = sys.argv[1].split("|") if sys.argv[1] else []
pid, fd = pty.fork()
if pid == 0: os.execvp("bash", ["bash"] + sys.argv[2:])
out = b""; i = 0; fed = 0
while True:
    r, _, _ = select.select([fd], [], [], 60)
    if not r: break
    try: d = os.read(fd, 4096)
    except OSError: break
    if not d: break
    out += d
    low = out.decode("utf-8", "replace")
    n = low.count("(hidden):") + low.count("[y/N]") + low.count("[Y/n]")
    while fed < n and i < len(answers):
        time.sleep(0.2); os.write(fd, (answers[i] + "\n").encode()); i += 1; fed += 1
_, st = os.waitpid(pid, 0)
sys.stdout.write(out.decode("utf-8", "replace")); sys.exit(os.waitstatus_to_exitcode(st))
PY

: > "$SB/http.log"; : > "$SB/dev.log"
MOCK_KEY="$KEYV" python3 -I "$SB/mock.py" "$SB/http.log" & sleep 1
start_pocket() { python3 -I "$SB/pocket.py" "$SB/dev.log" "$1" "${2:-0}" > "$SB/pty.name" & sleep 1; PTY=$(head -1 "$SB/pty.name"); }
run() { # run ANSWERS args...
  local a="$1"; shift
  FLASH_POCKET_SERIAL_DEV="$PTY" SER_SETTLE=0.2 SER_TEST_S=6 python3 -I "$SB/drive.py" "$a" "$SP" --api http://127.0.0.1:8011 "$@"; }
reset() { : > "$SB/http.log"; : > "$SB/dev.log"; }

echo "T1 --dry-run changes nothing, masks secrets"
OUT=$(bash "$SP" --dry-run --wifi-ssid n --wifi-pass hunter2 2>&1); RC=$?
[[ $RC == 0 && "$OUT" == *"dry-run"* && "$OUT" != *hunter2* && ! -s "$SB/http.log" ]] && ok "dry-run ok, wifi password masked, no requests" || bad "dry-run: rc=$RC"

echo "T2 no tty: refuses"
OUT=$(setsid -w bash "$SP" --api http://127.0.0.1:8011 </dev/null 2>&1); RC=$?
[[ $RC == 3 && "$OUT" == *"no terminal"* ]] && ok "exit 3 with a clear message" || bad "no-tty: rc=$RC $OUT"

echo "T3 bad usage"
bash "$SP" --api http://example.com >/dev/null 2>&1; [[ $? == 2 ]] && ok "plain http to a remote host rejected" || bad "http remote accepted"
bash "$SP" --board nope >/dev/null 2>&1; [[ $? == 2 ]] && ok "unknown board rejected" || bad "unknown board accepted"

echo "T4 happy path: login, mint, chunked send, verify"
start_pocket 0; reset
OUT=$(run "pw" --label "test pocket"); RC=$?
[[ $RC == 0 ]] && ok "exit 0" || bad "exit $RC: $OUT"
grep -q "POST /api/v1/auth/login auth=no user=RaBbLE-Architect" "$SB/http.log" && ok "logged in as the default Architect" || bad "login not seen"
grep -q "POST /api/v1/devices auth=yes label=test pocket" "$SB/http.log" && ok "minted with bearer and label" || bad "mint not seen"
grep -q "cmd >beam.token len=200" "$SB/dev.log" && grep -q "cmd >beam.token+ len=" "$SB/dev.log" && ok "token sent in a chunk plus += chunks" || bad "chunking: $(cat "$SB/dev.log")"
[[ "$OUT" != *rbdv_* && "$OUT" != *tok_test* && "$OUT" != *pw* ]] && ok "no key, token or password in output" || bad "secret leaked in output"
[[ "$OUT" == *"beam: Linked"* ]] && ok "reports Linked" || bad "no Linked: $OUT"
kill %2 2>/dev/null

echo "T5 --show-key prints it once"
start_pocket 0; reset
OUT=$(run "pw" --show-key); [[ "$OUT" == *"$KEYV"* && "$OUT" == *"shown once"* ]] && ok "key shown with a warning" || bad "show-key"
kill %3 2>/dev/null

echo "T6 existing key: asks, decline leaves everything alone"
start_pocket 1; reset
OUT=$(run "n"); RC=$?
[[ $RC == 3 && ! -s "$SB/http.log" ]] && ok "declined replace: exit 3, no request made" || bad "decline: rc=$RC log=$(cat "$SB/http.log")"
reset; OUT=$(run "y|pw"); [[ $? == 0 ]] && grep -q "POST /api/v1/devices" "$SB/http.log" && ok "accepted replace: minted" || bad "replace flow: $OUT"
kill %4 2>/dev/null

echo "T7 wrong password: no mint"
start_pocket 0; reset
OUT=$(run "wrong"); RC=$?
[[ $RC == 1 && "$OUT" == *"wrong username or password"* ]] && ! grep -q "/api/v1/devices" "$SB/http.log" && ok "refused, nothing minted" || bad "wrong pw: rc=$RC"
kill %5 2>/dev/null

echo "T8 pocket refuses the token after minting: offers revoke, revokes"
start_pocket 0 1; reset
OUT=$(run "pw|y"); RC=$?
[[ $RC == 1 ]] && grep -q "DELETE /api/v1/devices/dev1 auth=yes" "$SB/http.log" && ok "key revoked after a failed send" || bad "revoke: rc=$RC log=$(cat "$SB/http.log")"
kill %6 2>/dev/null

echo; echo "passed $pass, failed $fail"; [[ $fail == 0 ]]
