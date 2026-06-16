#!/usr/bin/env python3
"""chat-bridge.py — local proxy: browser → live Render sCoRE, with on-disk chat logs.

Sits on localhost:8000 — exactly where RaBbLE-config.js auto-targets when the page
is served from localhost — so the World chat app talks to it with NO config change.

It:
  • forwards every /api/* request to the Render sCoRE backend,
  • injects the @demo account's auth upstream (mints a fresh JWT from the stored
    api_key on startup, so there's no token juggling in the browser and no 8h expiry),
  • adds permissive CORS so a normal browser is happy (no --disable-web-security),
  • tees every chat turn (you + RaBbLE) to a transcript on disk for logging/review.

Env:
  RENDER_URL    upstream backend       (default https://rabble-score-x7qq.onrender.com)
  BRIDGE_PORT   listen port            (default 8000)
  DEMO_ACCOUNT  path to demo_account.json holding {"api_key": ...}
  CHAT_LOG_DIR  transcript dir         (default ~/RaBbLE-chats)
"""
import os, sys, json, base64, time, urllib.request, urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from datetime import datetime

RENDER       = os.environ.get("RENDER_URL", "https://rabble-score-x7qq.onrender.com").rstrip("/")
PORT         = int(os.environ.get("BRIDGE_PORT", "8000"))
LOG_DIR      = Path(os.environ.get("CHAT_LOG_DIR", str(Path.home() / "RaBbLE-chats")))
DEMO_ACCOUNT = os.environ.get("DEMO_ACCOUNT", "")
# Temporary: pin the model tier so chats land on the Groq-backed path. The DEFAULT
# medium/strong chains lead with OpenRouter (credit-less → 402/429, not retried),
# so 'auto' can fail on higher tiers. Set FORCE_TIER="" once the backend chains are
# fixed (groq-led + 402 fall-through) and @demo is seeded with hosted_groq.
FORCE_TIER   = os.environ.get("FORCE_TIER", "fast")

CORS = {
    "Access-Control-Allow-Origin":  "*",
    "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "content-type,authorization,x-api-key",
}


def _jwt_expired(tok, margin=300):
    """True if a JWT's exp is past (or within `margin` seconds). No signature check."""
    try:
        payload = tok.split(".")[1]
        payload += "=" * (-len(payload) % 4)
        exp = json.loads(base64.urlsafe_b64decode(payload)).get("exp", 0)
        return time.time() > (exp - margin)
    except Exception:
        return True


def mint_token():
    """Resolve the @demo upstream JWT.

    Prefer the JWT stored at summon — require_user trusts its claims, so it works
    even after Render's ephemeral disk wipes the user record (8h TTL). Only fall
    back to exchanging the api_key via /token (which needs the record) if it's gone
    or expired. Render free tier cold-starts ~30-50s, so warm /health and retry.
    """
    if not DEMO_ACCOUNT or not os.path.exists(DEMO_ACCOUNT):
        return None
    acct = json.load(open(DEMO_ACCOUNT))
    stored = acct.get("token")
    if stored and not _jwt_expired(stored):
        print("[bridge] using stored @demo JWT (valid)", flush=True)
        return stored
    api_key = acct.get("api_key")
    if not api_key:
        return None
    for attempt in range(1, 4):
        try:
            urllib.request.urlopen(RENDER + "/health", timeout=90)   # wake the dyno
        except Exception:
            pass
        req = urllib.request.Request(
            RENDER + "/api/v1/auth/token",
            data=json.dumps({"api_key": api_key}).encode(),
            headers={"Content-Type": "application/json"}, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.load(r).get("token")
        except Exception as e:
            print(f"[bridge] token mint attempt {attempt}/3 failed: {e}", file=sys.stderr, flush=True)
    print("[bridge] token mint failed after retries — pass-through (guest) auth", file=sys.stderr, flush=True)
    return None


TOKEN = mint_token()
LOG_DIR.mkdir(parents=True, exist_ok=True)
print(f"[bridge] :{PORT} → {RENDER}  auth={'@demo JWT' if TOKEN else 'pass-through'}  logs={LOG_DIR}", flush=True)


def log_turn(session, user_text, assistant_text):
    ts = datetime.now().isoformat(timespec="seconds")
    md = LOG_DIR / f"{session}.md"
    if not md.exists():
        md.write_text(f"# RaBbLE chat — session {session}\n\n")
    with md.open("a") as f:
        f.write(f"### {ts}\n\n**You:** {user_text}\n\n**RaBbLE:** {assistant_text}\n\n")
    with (LOG_DIR / f"{session}.jsonl").open("a") as f:
        f.write(json.dumps({"ts": ts, "session": session, "user": user_text, "rabble": assistant_text}) + "\n")
    print(f"[bridge] logged turn → {md}")


class Handler(BaseHTTPRequestHandler):
    def _cors(self):
        for k, v in CORS.items():
            self.send_header(k, v)

    def do_OPTIONS(self):
        self.send_response(204); self._cors(); self.end_headers()

    def do_GET(self):    self.proxy("GET")
    def do_DELETE(self): self.proxy("DELETE")
    def do_POST(self):   self.proxy("POST")

    def proxy(self, method):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length else None

        headers = {"Content-Type": self.headers.get("Content-Type", "application/json")}
        if TOKEN:
            headers["Authorization"] = f"Bearer {TOKEN}"      # force @demo auth upstream

        # Identify chat turns for transcript logging
        is_msg  = method == "POST" and "/message" in self.path
        is_anon = method == "POST" and self.path.rstrip("/").endswith("/api/v1/chat")
        user_text, session = "", "anon"
        if is_msg or is_anon:
            try:
                payload = json.loads(body or b"{}")
                if is_msg:
                    user_text = payload.get("content", "")
                    session = self.path.split("/sessions/")[1].split("/")[0]
                else:
                    msgs = payload.get("messages", [])
                    user_text = next((m["content"] for m in reversed(msgs) if m.get("role") == "user"), "")
                if FORCE_TIER:                       # pin to the Groq-backed tier
                    payload["model_tier"] = FORCE_TIER
                    body = json.dumps(payload).encode()
            except Exception:
                pass

        req = urllib.request.Request(RENDER + self.path, data=body, headers=headers, method=method)
        try:
            up = urllib.request.urlopen(req, timeout=120)
        except urllib.error.HTTPError as e:
            self.send_response(e.code); self._cors()
            self.send_header("Content-Type", e.headers.get("Content-Type", "application/json")); self.end_headers()
            self.wfile.write(e.read()); return
        except Exception as e:
            self.send_response(502); self._cors()
            self.send_header("Content-Type", "application/json"); self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode()); return

        ctype = up.headers.get("Content-Type", "application/json")
        self.send_response(up.status); self._cors()
        self.send_header("Content-Type", ctype); self.end_headers()

        if "event-stream" in ctype:
            assistant, buf = [], b""
            while True:
                chunk = up.read(256)
                if not chunk:
                    break
                try:
                    self.wfile.write(chunk); self.wfile.flush()   # stream to browser live
                except Exception:
                    break
                buf += chunk
                while b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                    line = line.decode(errors="ignore").strip()
                    if line.startswith("data:"):
                        d = line[5:].strip()
                        if d and d != "[DONE]":
                            try:
                                v = json.loads(d)
                                if isinstance(v, str):
                                    assistant.append(v)
                            except Exception:
                                pass
            if (is_msg or is_anon) and user_text:
                log_turn(session, user_text, "".join(assistant))
        else:
            self.wfile.write(up.read())

    def log_message(self, *a):
        pass  # quiet default access log


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
