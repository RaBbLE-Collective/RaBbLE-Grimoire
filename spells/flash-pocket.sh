#!/usr/bin/env bash
# spells/flash-pocket.sh: flash your own Pocket and choose who it belongs to: account key, guest key, nothing, or unchanged.
#
# Run it yourself in a real terminal:   bash RaBbLE-Grimoire/spells/flash-pocket.sh [options]   (--help lists them)
#
# Modes: account (default: Architect login + mint, or --key-file), guest (mint via the guest endpoint, secret from env or
# --secret-file), none (clear the sCoRE token so it runs standalone), keep (firmware only, writes nothing to the Pocket).
# Steps (account): (1) build + flash over USB with RaBbLE-Pocket/ops/build-flash.sh, (2) ask the Pocket's console whether a key is
# already set and ask before replacing it, (3) sign in to sCoRE as the Architect (hidden password from /dev/tty),
# (4) mint a device key with POST /api/v1/devices, (5) send it over the serial console (>beam.token=, chunked with +=),
# (6) check >status and run >beam.test. If anything fails after the key is minted, it offers to revoke it.
#
# Secrets: the password is read only from /dev/tty (never an argument, env var or pipe; no tty = refusal). The access
# token and the device key live only in shell variables. curl gets bodies and the bearer header on stdin, never on
# the command line. The key is printed only with --show-key. No file is written, no `set -x`.
# Serial: a small python3 -I helper using termios (stdlib), so there is no pyserial or venv to install, and the same
# open/read/write path works on a tty and on the pty the test uses. Opening the port resets the board; the helper waits.
# Test: FLASH_POCKET_SERIAL_DEV=/dev/pts/N uses that device and skips the flash (bash spells/tests/flash-pocket.test.sh).
#
# spark ~ grimoire >> one command to flash and pair the Architect's Pocket // %S347_STATE%

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
POCKET="$ROOT/RaBbLE-Pocket"
BOARDS="$POCKET/firmware/boards"
DEF_BOARD="rabble_waveshare_175b"        # what ops/build-flash.sh builds when -b is not given

BOARD="$DEF_BOARD"; PORT=""; NOBUILD=0; NOFLASH=0; LABEL=""; DRY=0; SHOWKEY=0
API="${SCORE_URL:-https://score.joinrabble.world}"
USERNAME="RaBbLE-Architect"; WSSID=""; WPASS=""; WPASS_ASK=0
SERIAL_DEV="${FLASH_POCKET_SERIAL_DEV:-}"
MINTED_ID=""; TOK=""; KEY=""; MODE="account"; KEYFILE=""; SECFILE=""; YES=0; HAVE_TTY=0

c() { printf '\033[%sm%s\033[0m\n' "$1" "$2"; }
say()  { c "0;36" "· $*"; }
ok()   { c "0;32" "✓ $*"; }
warn() { c "1;33" "! $*" >&2; }
plan() { c "0;35" "  [dry-run] $*"; }

usage() {
  local b; b=$(ls "$BOARDS" 2>/dev/null | tr '\n' ' ')
  cat <<USAGE
Usage: bash RaBbLE-Grimoire/spells/flash-pocket.sh [options]

Flashes your Pocket, then pairs it with a new device key minted under your Architect account
(admin tier: no device limit, usage still metered).

  --mode MODE        account (default) | guest | none | keep (alias --fw-only)
                       account: sign in as the Architect, mint a device key and pair it (needs a terminal),
                                or with --key-file send a key you already wrote (no password, no terminal, nothing minted)
                       guest:   mint a guest key (POST /api/v1/users/guest); secret from env GUEST_ISSUE_SECRET or --secret-file
                       none:    clear the Pocket's sCoRE token (>beam.token=) so it runs standalone; no network, no credentials
                       keep:    build and flash, then stop. No login, no console writes, token and every setting kept
  --key-file PATH    account mode: file (mode 600) holding one rbdv_ key; it is sent and never printed
  --secret-file PATH guest mode: file (mode 600) holding the guest issue secret
  --yes              answer yes to "replace the existing key?" (needed for unattended runs)
  --board NAME       board to build (default $DEF_BOARD). Valid: ${b:-none found}
  --port TTY         serial port (default: the only /dev/ttyACM* or /dev/ttyUSB*)
  --no-build         do not build; needs an existing build dir (build-flash.sh still runs an up-to-date build as a no-op)
  --no-flash         pair only: re-pair over the console, settings kept
  --label "NAME"     label for the key (default "<board> <date>", max 40 characters)
  --api URL          sCoRE base URL (default \$SCORE_URL or https://score.joinrabble.world; http only for localhost)
  --user NAME        account to sign in as (default $USERNAME)
  --wifi-ssid NAME   also send a Wi-Fi network (sent only when given)
  --wifi-pass VALUE  Wi-Fi password; use "-" to be asked with hidden input (a literal value shows in the process list)
  --show-key         print the key once at the end (it is shown once and cannot be fetched again)
  --dry-run          print every step with secrets masked, change nothing
  -h, --help         this text

The password is asked in your terminal and is never accepted from an argument, env var or pipe.
Modes other than "account without --key-file" work with no terminal. A guest key is refused on the beam unless sCoRE
runs with BEAM_ALLOW_GUEST_POCKETS=true (a dev/test flag). Use keep for firmware updates; account/guest/none when you
want to change who the Pocket belongs to.
Exit codes: 0 done, 1 failed, 2 bad usage, 3 stopped by you (declined replace, no tty).
USAGE
}

die()  { c "0;31" "✗ $*" >&2; exit 1; }
bad()  { c "0;31" "✗ $*" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --board) [ $# -ge 2 ] || bad "--board needs a name"; BOARD="$2"; shift 2 ;;
    --port) [ $# -ge 2 ] || bad "--port needs a device"; PORT="$2"; shift 2 ;;
    --no-build) NOBUILD=1; shift ;;
    --no-flash) NOFLASH=1; shift ;;
    --label) [ $# -ge 2 ] || bad "--label needs a value"; LABEL="$2"; shift 2 ;;
    --api) [ $# -ge 2 ] || bad "--api needs a URL"; API="$2"; shift 2 ;;
    --user) [ $# -ge 2 ] || bad "--user needs a name"; USERNAME="$2"; shift 2 ;;
    --wifi-ssid) [ $# -ge 2 ] || bad "--wifi-ssid needs a name"; WSSID="$2"; shift 2 ;;
    --wifi-pass) [ $# -ge 2 ] || bad "--wifi-pass needs a value or -"; if [ "$2" = "-" ]; then WPASS_ASK=1; else WPASS="$2"; fi; shift 2 ;;
    --mode) [ $# -ge 2 ] || bad "--mode needs account|guest|none|keep"; MODE="$2"; shift 2 ;;
    --fw-only) MODE="keep"; shift ;;
    --key-file) [ $# -ge 2 ] || bad "--key-file needs a path"; KEYFILE="$2"; shift 2 ;;
    --secret-file) [ $# -ge 2 ] || bad "--secret-file needs a path"; SECFILE="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    --show-key) SHOWKEY=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; bad "unknown option: $1" ;;
  esac
done

API="${API%/}"
case "$API" in
  https://*|http://localhost|http://localhost:*|http://127.0.0.1|http://127.0.0.1:*) ;;
  *) bad "--api must be https://... (http only for localhost)" ;;
esac
[ -d "$BOARDS/$BOARD" ] || bad "unknown board '$BOARD' (valid: $(ls "$BOARDS" 2>/dev/null | tr '\n' ' '))"
LABEL_GIVEN="$LABEL"
[ -n "$LABEL" ] || LABEL="$BOARD $(date +%F)"
[ "${#LABEL}" -le 40 ] || bad "--label is over 40 characters"
[ -z "$WPASS$WSSID" ] || [ -n "$WSSID" ] || bad "--wifi-pass needs --wifi-ssid"
[ "$WPASS_ASK" = 0 ] || [ -n "$WSSID" ] || bad "--wifi-pass needs --wifi-ssid"
command -v curl >/dev/null || die "curl is needed"
command -v python3 >/dev/null || die "python3 is needed"

case "$MODE" in account|guest|none|keep) ;; *) bad "--mode must be account, guest, none or keep" ;; esac
[ -z "$KEYFILE" ] || [ "$MODE" = account ] || bad "--key-file is only for --mode account"
[ -z "$SECFILE" ] || [ "$MODE" = guest ] || bad "--secret-file is only for --mode guest"
if [ "$MODE" = keep ] || [ "$MODE" = none ]; then
  [ -z "$WSSID$WPASS" ] && [ "$WPASS_ASK" = 0 ] || bad "--wifi-* is not used in --mode $MODE (nothing is written to the console except the token clear)"
fi
[ "$MODE" != keep ] || [ "$NOFLASH" = 0 ] || bad "--mode keep is a flash: it cannot be combined with --no-flash"

# A secret file must be private: mode 600 (or 400), owned by you.
check_private() { # check_private PATH WHAT
  [ -f "$1" ] || bad "$2 not found: $1"
  local m o; m=$(stat -c %a "$1" 2>/dev/null); o=$(stat -c %u "$1" 2>/dev/null)
  { [ "$m" = 600 ] || [ "$m" = 400 ]; } || bad "$2 must be mode 600 (it is $m): chmod 600 $1"
  [ "$o" = "$(id -u)" ] || bad "$2 must be owned by you"
}
[ -z "$KEYFILE" ] || check_private "$KEYFILE" "--key-file"
[ -z "$SECFILE" ] || check_private "$SECFILE" "--secret-file"

# A terminal is only needed for a password, a hidden Wi-Fi password, or a question you did not pre-answer with --yes.
{ exec 3<>/dev/tty; } 2>/dev/null && HAVE_TTY=1
NEED_TTY=0; { [ "$MODE" = account ] && [ -z "$KEYFILE" ]; } && NEED_TTY=1; [ "$WPASS_ASK" = 1 ] && NEED_TTY=1
if [ "$DRY" = 0 ] && [ "$NEED_TTY" = 1 ] && [ "$HAVE_TTY" = 0 ]; then
  c "0;31" "✗ no terminal: this needs a hidden password and will not take it from a pipe, env var or argument. Run it in a real terminal, or use --key-file, --mode guest, --mode none or --mode keep." >&2; exit 3
fi
tty_ask() { local a; [ "$YES" = 1 ] && return 0; [ "$HAVE_TTY" = 1 ] || return 1; printf '%s [y/N] ' "$1" >&3; read -r a <&3; [[ "$a" =~ ^[Yy]$ ]]; }

# ── Serial helper (stdlib termios) ──────────────────────────────────────────────
SER_PY='
import os, sys, time, json, termios, select
mode, dev = sys.argv[1], sys.argv[2]
fd = os.open(dev, os.O_RDWR | os.O_NOCTTY)
a = termios.tcgetattr(fd)
a[0] = 0; a[1] = 0; a[2] = termios.CS8 | termios.CREAD | termios.CLOCAL; a[3] = 0
a[4] = a[5] = termios.B115200
a[6][termios.VMIN] = 0; a[6][termios.VTIME] = 0
termios.tcsetattr(fd, termios.TCSANOW, a)
buf = b""
def lines(wait):
    global buf
    end = time.time() + wait
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: d = os.read(fd, 4096)
            except OSError: return
            buf += d
        while b"\n" in buf:
            ln, buf = buf.split(b"\n", 1)
            yield ln.decode("utf-8", "replace").strip()
def put(s): os.write(fd, (s + "\n").encode())
def status():
    for _ in range(3):
        put(">status")
        for ln in lines(3):
            if ln.startswith("@status "):
                try: return json.loads(ln[8:])
                except ValueError: pass
    return None
time.sleep(float(os.environ.get("SER_SETTLE", "3")))   # opening the port resets the board
list(lines(0.3)); buf = b""
if mode == "status":
    s = status()
    if s is None: sys.exit(4)
    print(json.dumps({"token": bool(s.get("beam", {}).get("token")), "beam": s.get("beam", {}).get("state", ""), "wifi": s.get("wifi", {}).get("state", ""), "fw": s.get("fw", "")}))
elif mode == "send":
    for cmd in sys.stdin.read().splitlines():
        if not cmd: continue
        name = cmd.split("=", 1)[0]
        put(">" + cmd)
        reply = None
        for ln in lines(5):
            if ln.startswith("@setup "): reply = ln[7:]; break
        if reply is None or not reply.endswith(": ok"):
            print("%s: %s" % (name, reply or "no reply")); sys.exit(5)
        print("%s: ok" % name)
elif mode == "test":
    put(">beam.test")
    end = time.time() + float(os.environ.get("SER_TEST_S", "45")); last = ""
    while time.time() < end:
        s = status()
        last = (s or {}).get("beam", {}).get("state", "")
        if last in ("Linked", "Dial failed"): break
        time.sleep(2)
    print(last or "no status"); sys.exit(0 if last == "Linked" else 6)
'
ser() { python3 -I -c "$SER_PY" "$1" "$SERIAL_DEV_USE"; }   # args: mode; commands on stdin; device in SERIAL_DEV_USE

# ── Small JSON/curl helpers (secrets on stdin only) ─────────────────────────────
jget() { python3 -I -c 'import sys,json
try: print(json.load(sys.stdin).get(sys.argv[1],""))
except Exception: print("")' "$1"; }
# cfg_json METHOD-less: bearer token on stdin of python; body optional (argv 2 is non-secret JSON)
bearer_cfg() { python3 -I -c 'import sys,json
t=sys.stdin.read().strip(); body=sys.argv[1] if len(sys.argv)>1 else ""
print("header = " + json.dumps("Authorization: Bearer " + t))
if body:
    print("header = " + json.dumps("Content-Type: application/json")); print("data = " + json.dumps(body))' "$@"; }
http() { # http <curl args...> ; config on stdin ; prints body, then newline + status code
  curl -sS --max-time 25 --proto '=https,http' -w '\n%{http_code}' "$@"; }
split_resp() { RCODE="${1##*$'\n'}"; RBODY="${1%$'\n'*}"; }

revoke_offer() {
  [ -n "$MINTED_ID" ] || return 0
  if [ "$MODE" = account ] && [ "$HAVE_TTY" = 1 ]; then
    printf 'A key was minted (id %s) but pairing did not finish. Revoke it now? [Y/n] ' "$MINTED_ID" >&3
    local a; read -r a <&3
    if [[ ! "$a" =~ ^[Nn]$ ]]; then
      local r; r=$(printf '%s' "$TOK" | bearer_cfg | http --config - -X DELETE "$API/api/v1/devices/$MINTED_ID") ; split_resp "$r"
      [[ "$RCODE" =~ ^2 ]] && ok "key $MINTED_ID revoked" || warn "revoke failed (HTTP $RCODE): revoke it in the Pockets tab"
      return
    fi
  fi
  [ "$MODE" = account ] && warn "key $MINTED_ID left active: revoke it in the Pockets tab"
}
fail() { c "0;31" "✗ $*" >&2; revoke_offer; KEY=""; TOK=""; exit 1; }
trap 'echo >&2; fail "interrupted"' INT TERM

mask() { printf '%s' '********'; }

# ── Dry run: describe, change nothing ───────────────────────────────────────────
if [ "$DRY" = 1 ]; then
  say "flash-pocket dry run (nothing is changed, no network, no serial)"
  plan "board=$BOARD port=${PORT:-autodetect} api=$API user=$USERNAME label=\"$LABEL\""
  [ "$NOFLASH" = 1 ] && plan "skip build and flash (--no-flash)" || plan "bash $POCKET/ops/build-flash.sh firmware -b $BOARD${PORT:+ -p $PORT}   (build + flash)"
  plan "mode=$MODE"
  case "$MODE" in
    keep) plan "after the flash: read-only >status (token set? firmware version). No login, no console writes, no network"
          plan "flash never erases: build-flash.sh runs idf.py flash with no erase option and the build has no nvs/storage image" ;;
    none) plan "wait for boot, console: >beam.token=  (empty: clears the token; beam.url cannot be cleared, only reset to the default)"
          plan ">status must then report no token. No network, no credentials" ;;
    guest) plan "wait for boot, >status: ask before replacing an existing key (--yes answers it)"
           plan "guest secret from ${SECFILE:+file $SECFILE}${SECFILE:-env GUEST_ISSUE_SECRET} (value: $(mask)); POST $API/api/v1/users/guest  header X-Guest-Secret on stdin -> api_key + handle"
           plan "console: >beam.token=$(mask); verify with >status and >beam.test; remind about BEAM_ALLOW_GUEST_POCKETS=true" ;;
    account) plan "wait for boot, >status: ask before replacing an existing key (--yes answers it)"
      if [ -n "$KEYFILE" ]; then plan "key read from $KEYFILE (value: $(mask)); no login, nothing minted"
      else
        plan "ask for the password for '$USERNAME' with hidden input from /dev/tty (value: $(mask))"
        plan "POST $API/api/v1/auth/login  body on stdin  -> access token held in a variable"
        plan "POST $API/api/v1/devices  label=\"$LABEL\"  bearer $(mask) on stdin  -> key rbdv_$(mask)"
        plan "on failure after minting: offer DELETE $API/api/v1/devices/{id}"
      fi
      [ -n "$WSSID" ] && plan "console: >wifi.ssid=$WSSID  >wifi.pass=$(mask)  >wifi.connect"
      plan "console: >beam.token=$(mask)  (>beam.token+= for anything over 200 characters)"
      plan "console: >status expects a token set, then >beam.test and report Linked or not" ;;
  esac
  [ "$SHOWKEY" = 1 ] && plan "print the key once at the end (--show-key)" || plan "key is never printed"
  exit 0
fi

# ── 1. Build and flash ──────────────────────────────────────────────────────────
detect_port() {
  local d cand=()
  for d in /dev/ttyACM* /dev/ttyUSB*; do [ -e "$d" ] && cand+=("$d"); done
  case "${#cand[@]}" in
    1) PORT="${cand[0]}" ;;
    0) die "no board found (no /dev/ttyACM* or /dev/ttyUSB*): plug it in, or re-seat the cable" ;;
    *) die "several serial devices (${cand[*]}): pick one with --port" ;;
  esac
}
if [ -n "$SERIAL_DEV" ]; then
  PORT="$SERIAL_DEV"
  if [ -n "${FLASH_POCKET_BUILD_FLASH:-}" ]; then say "test hooks: serial device $SERIAL_DEV, flasher $FLASH_POCKET_BUILD_FLASH"
  else say "FLASH_POCKET_SERIAL_DEV is set: using $SERIAL_DEV, skipping build and flash"; NOFLASH=1; fi
fi
if [ "$NOFLASH" = 0 ]; then
  BF="${FLASH_POCKET_BUILD_FLASH:-$POCKET/ops/build-flash.sh}"; [ -f "$BF" ] || die "missing $BF"
  [ -n "$PORT" ] || detect_port
  if [ "$NOBUILD" = 1 ]; then
    BD="$POCKET/firmware/build"; [ "$BOARD" = "$DEF_BOARD" ] || BD="$POCKET/firmware/build-$BOARD-RaBbLE"
    [ -d "$BD" ] || die "--no-build but there is no build at $BD: drop --no-build once"
  fi
  # Settings-keeping guard: a flash must never erase NVS or the notes store. Refuse if the flasher or build ever mentions an erase.
  if grep -qiE 'erase|--erase-all|erase-flash' "$BF"; then
    die "ops/build-flash.sh mentions an erase: refusing to flash, because that could wipe the Pocket's token and settings. Read it first."
  fi
  say "Building and flashing $BOARD on $PORT (ops/build-flash.sh; its output is not piped)"
  ( cd "$POCKET" && bash "$BF" firmware -b "$BOARD" -p "$PORT" ) || die "build or flash failed"
  ok "flashed"
  say "Waiting for the Pocket to come back on USB"
  if [ -z "$SERIAL_DEV" ]; then sleep 4; PORT=""; for _ in 1 2 3 4 5 6 7 8 9 10; do detect_port 2>/dev/null && break; sleep 1; done; fi
  [ -n "$PORT" ] || die "the Pocket did not re-appear after the flash: re-seat the cable, then run again with --no-flash"
else
  [ -n "$PORT" ] || detect_port
fi
SERIAL_DEV_USE="$PORT"
[ -e "$SERIAL_DEV_USE" ] || die "port $SERIAL_DEV_USE not present"

# ── Mode: keep (firmware only) ──────────────────────────────────────────────────
if [ "$MODE" = keep ]; then
  say "Reading the Pocket's status (read-only; nothing is written to it)"
  if ST=$(ser status </dev/null); then
    [ "$(printf '%s' "$ST" | jget token)" = "True" ] && T="a token is set" || T="no token is set"
    ok "kept: $T, firmware $(printf '%s' "$ST" | jget fw)"
  else
    warn "the Pocket did not answer >status (it may still be booting); the flash itself succeeded"
  fi
  exit 0
fi

# ── Mode: none (run standalone) ─────────────────────────────────────────────────
say "Asking the Pocket for its status on $PORT (opening the port resets it; this takes a few seconds)"
ST=$(ser status </dev/null) || die "no @status from the Pocket on $PORT: is it on this port and running RaBbLE firmware?"
if [ "$MODE" = none ]; then
  printf 'beam.token=\n' | ser send >/dev/null || die "the Pocket refused to clear its token"
  ST=$(ser status </dev/null) || die "no @status after clearing"
  [ "$(printf '%s' "$ST" | jget token)" = "False" ] || die "the Pocket still reports a token after clearing"
  ok "token cleared: the Pocket runs standalone (the beam URL is untouched: the console can only reset it to the default, not remove it)"
  exit 0
fi

# ── 2. Existing key? ────────────────────────────────────────────────────────────
if [ "$(printf '%s' "$ST" | jget token)" = "True" ]; then
  tty_ask "This Pocket already has a key. Replace it with a new one?" || { say "left as it is (pass --yes to replace without asking)"; exit 3; }
fi

# ── 3/4. Get a key: key file, guest mint, or Architect login + mint ──────────────
if [ -n "$KEYFILE" ]; then
  KEY=$(head -n1 "$KEYFILE" | tr -d '[:space:]')
  [[ "$KEY" == rbdv_* ]] || die "$KEYFILE does not hold an rbdv_ key"
  ok "using the key from $KEYFILE (nothing minted)"
elif [ "$MODE" = guest ]; then
  if [ -n "$SECFILE" ]; then GS=$(head -n1 "$SECFILE" | tr -d '[:space:]'); else GS="${GUEST_ISSUE_SECRET:-}"; fi
  [ -n "$GS" ] || die "no guest secret: set GUEST_ISSUE_SECRET or pass --secret-file PATH"
  BODY=$(python3 -I -c 'import sys,json; print(json.dumps({"label":sys.argv[1]}) if sys.argv[1] else "{}")' "${LABEL_GIVEN:-}")
  R=$(printf '%s' "$GS" | python3 -I -c 'import sys,json
b=sys.argv[1]
print("header = " + json.dumps("X-Guest-Secret: " + sys.stdin.read().strip()))
print("header = " + json.dumps("Content-Type: application/json")); print("data = " + json.dumps(b))' "$BODY" \
    | http --config - "$API/api/v1/users/guest"); GS=""
  split_resp "$R"
  case "$RCODE" in
    201) ;;
    404) die "guest issue is switched off on that server (GUEST_ISSUE_SECRET is unset there)" ;;
    403) die "the server refused the guest secret" ;;
    429|503) die "guest issue refused: $(printf '%s' "$RBODY" | jget detail)" ;;
    *) die "guest mint failed (HTTP ${RCODE:-none})" ;;
  esac
  KEY=$(printf '%s' "$RBODY" | jget api_key); HANDLE=$(printf '%s' "$RBODY" | jget handle); RBODY=""; R=""
  [ -n "$KEY" ] || die "the server answered without a key"
  ok "minted a guest key (handle ${HANDLE:-unknown})"
else
# ── 3. Sign in ──────────────────────────────────────────────────────────────────
printf 'Password for %s (hidden): ' "$USERNAME" >&3
IFS= read -rs PW <&3; printf '\n' >&3
[ -n "$PW" ] || die "empty password"
LOGIN=$(printf '%s' "$PW" | python3 -I -c 'import sys,json; print(json.dumps({"identifier":sys.argv[1],"password":sys.stdin.read()}))' "$USERNAME" \
  | http -H 'Content-Type: application/json' --data @- "$API/api/v1/auth/login")
PW=""
split_resp "$LOGIN"
case "$RCODE" in
  200) ;;
  401) die "sign-in refused: wrong username or password" ;;
  403) die "sign-in refused: $(printf '%s' "$RBODY" | jget detail)" ;;
  429) die "too many sign-in attempts: wait a few minutes" ;;
  *) die "sign-in failed (HTTP ${RCODE:-none}): is $API reachable?" ;;
esac
TOK=$(printf '%s' "$RBODY" | jget token); RBODY=""; LOGIN=""
[ -n "$TOK" ] || die "sign-in returned no token"
ok "signed in as $USERNAME"

# ── 4. Mint ─────────────────────────────────────────────────────────────────────
BODY=$(python3 -I -c 'import sys,json; print(json.dumps({"label":sys.argv[1]}))' "$LABEL")
MINT=$(printf '%s' "$TOK" | bearer_cfg "$BODY" | http --config - "$API/api/v1/devices")
split_resp "$MINT"
case "$RCODE" in
  201) ;;
  403) TOK=""; die "mint refused: $(printf '%s' "$RBODY" | jget detail)" ;;
  409|429) TOK=""; die "mint refused: $(printf '%s' "$RBODY" | jget detail) (device limit? an Architect account should be exempt: check the server)" ;;
  *) TOK=""; die "mint failed (HTTP ${RCODE:-none})" ;;
esac
KEY=$(printf '%s' "$RBODY" | jget key); MINTED_ID=$(printf '%s' "$RBODY" | jget id); RBODY=""; MINT=""
[ -n "$KEY" ] && [ -n "$MINTED_ID" ] || fail "the server answered without a key"
ok "minted a device key (id $MINTED_ID, label \"$LABEL\")"

fi

# ── 5. Send over the console ────────────────────────────────────────────────────
if [ "$WPASS_ASK" = 1 ]; then
  printf 'Wi-Fi password for %s (hidden): ' "$WSSID" >&3; IFS= read -rs WPASS <&3; printf '\n' >&3
fi
build_cmds() {
  if [ -n "$WSSID" ]; then
    printf 'wifi.ssid=%s\n' "$WSSID"
    printf 'wifi.pass=%s\n' "$WPASS"
    printf 'wifi.connect\n'
  fi
  local rest="$KEY"
  printf 'beam.token=%s\n' "${rest:0:200}"; rest="${rest:200}"
  while [ -n "$rest" ]; do printf 'beam.token+=%s\n' "${rest:0:200}"; rest="${rest:200}"; done
}
say "Sending the key${WSSID:+ and Wi-Fi} to the Pocket"
SENT=$(build_cmds | ser send) || fail "the Pocket refused a command ($(printf '%s' "$SENT" | tail -1))"
WPASS=""
ok "sent: $(printf '%s' "$SENT" | tr '\n' ' ')"

# ── 6. Verify ───────────────────────────────────────────────────────────────────
ST=$(ser status </dev/null) || fail "no @status after sending"
[ "$(printf '%s' "$ST" | jget token)" = "True" ] || fail "the Pocket reports no token after the send"
ok "the Pocket reports a token is set"
say "Running >beam.test (up to 45 seconds; needs Wi-Fi)"
if RES=$(ser test </dev/null); then ok "beam: $RES"; RC=0
else warn "beam: ${RES:-no answer}. The key is saved on the Pocket; check Wi-Fi (--wifi-ssid) and run >beam.test again."; RC=0; fi

MINTED_ID_DONE="$MINTED_ID"; MINTED_ID=""; TOK=""
if [ "$SHOWKEY" = 1 ]; then
  warn "the key is shown once and cannot be fetched again:"
  printf '%s\n' "$KEY"
fi
KEY=""
if [ "$MODE" = guest ]; then
  warn "guest keys are refused on the beam unless sCoRE runs with BEAM_ALLOW_GUEST_POCKETS=true (a dev/test flag, default false)"
  ok "done: $BOARD paired with a guest key (${HANDLE:-guest})"
elif [ -n "$KEYFILE" ]; then ok "done: $BOARD paired with the key from $KEYFILE"
else ok "done: $BOARD paired as \"$LABEL\" (key id $MINTED_ID_DONE; revoke it in the Pockets tab)"; fi
exit "$RC"
