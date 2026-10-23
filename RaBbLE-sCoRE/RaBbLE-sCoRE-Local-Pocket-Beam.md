# RaBbLE-sCoRE — Local Beam: Pocket → Laptop sCoRE

```
spark ~ sCoRE >> pocket routes to local claude on the home machine // %EP2_LOCAL_BEAM%
```

> **Document type:** Grimoire architecture spec · `RaBbLE-sCoRE/`
> **Status:** Planned · Epoch 0 · Evolution 0 · Echo 0 · Episode 2 target
> **Purpose:** Define how RaBbLE-Pocket auto-discovers and beams to a local
> sCoRE instance running on the RaBbLE-OS laptop — backed by Claude Code
> rather than the cloud Groq chain — with device pairing as the trust gate.
> **Related docs:**
> - `RaBbLE-sCoRE-Local-Architecture.md` — local sCoRE systemd service
> - `RaBbLE-sCoRE-Local-Tickets.md` — L-01 through L-08 implementation tickets
> - `RaBbLE-Pocket/RaBbLE-Pocket-Beam-Protocol.md` — beam wire format (v0)
> - `RaBbLE-OS/layers/RaBbLE-OS-Layer-AI-Harnesses.md` — claude-code install
> - `sCoRE-Local-AI-Layer.md` — provider registry and chain config

---

## Problem

When the Pocket beams today it goes to `score.joinrabble.world` — the cloud
service on Render, backed by the Groq fast chain (gpt-oss-20b → gpt-oss-120b).
The Grimoire gists reach it via environment variable; local files don't.

The cloud service has three problems for this use case:

1. **No Claude Code.** The cloud can't spawn a subprocess on your laptop.
   The `claude_code` provider only works where the `claude` binary lives.
2. **No local Grimoire.** The cloud reads only distilled gists; the full living
   Grimoire with your session logs, patterns, and member context is on disk.
3. **Cold start.** Render's free tier sleeps; first beam of the day can hit 30–60 s.

The fix is to run sCoRE locally on RaBbLE-OS, route the Pocket's beam to it when
on the home LAN, and have that local instance call `claude --print` directly.
The Pocket already supports arbitrary `>beam.url=` and reconnects on fail — the
infrastructure is there, it just needs the local target and the routing logic.

---

## Architecture: What Changes

```
Before (cloud only):
  Pocket  ──wss──►  score.joinrabble.world  ──►  Groq chain
                        (Render, ~30s cold)

After (LAN auto-discovery):
  Pocket  ──ws──►  rabble-os.local:8000  ──►  claude --print  ──►  Grimoire (local FS)
           (if home LAN)
     └─ fallback ──►  score.joinrabble.world  (away from home or local down)
```

The Pocket's firmware already has `ws://rabble-os.local:8000/api/v1/beam` as
the compile-time default (`CONFIG_RABBLE_BEAM_DEFAULT_URL` in sdkconfig.defaults).
RaBbLE-OS already uses `rabble-os` as its hostname. The path is shorter than it looks.

### Components

| Component | Where | What it does |
|---|---|---|
| `rabble-score-local.service` | RaBbLE-OS systemd (user) | Runs sCoRE on `:8000` with `LOCAL_MODE=true` |
| `BEAM_LLM_CHAIN=claude_code:claude-sonnet-4-5` | local `.env` | Routes beam turns to Claude Code CLI |
| `GRIMOIRE_PATH` | local `.env` | Points sCoRE at the local Grimoire filesystem |
| `BEAM_DEVICE_TOKEN` | local `.env` + Pocket NVS | Shared secret that proves it's your Pocket |
| mDNS (`avahi`) | RaBbLE-OS | Advertises `rabble-os.local` so the Pocket resolves without IP config |
| Pocket firmware default URL | already in firmware | `ws://rabble-os.local:8000/api/v1/beam` — already there |
| Cloud sCoRE fallback | unchanged | Pocket reconnects to cloud when local isn't reachable |

---

## Pairing: How Trust Works

"Pairing" here means: the Pocket knows the `BEAM_DEVICE_TOKEN` and so does
local sCoRE. That shared secret is what prevents any other device on your LAN
from beaming in.

The same token is already used on the cloud service. For local, the same value
is reused — you don't need a separate token per endpoint. The Pocket sends
`Authorization: Bearer <token>` on the WebSocket upgrade; local sCoRE validates
it against `BEAM_DEVICE_TOKEN` in its `.env`, identical to what the cloud does.

> `BEAM_ALLOW_GUEST=false` is the default and must stay that way on local too.
> The beam spends Claude quota; an open local beam on a home LAN is a real risk.

### Pairing Flow (first time, or after token rotation)

```
1. Generate a token (once):
   python3 -c "import secrets; print(secrets.token_hex(32))"

2. Set it in local sCoRE's env:
   echo "BEAM_DEVICE_TOKEN=<token>" >> ~/.config/rabble/local.env

3. Set it on the Pocket (console):
   >beam.token=<token>
   (or chunked: >beam.token+=... for long tokens)

4. That's it. The Pocket will use this token with any sCoRE URL it connects to.
   Cloud sCoRE should have the same token set in its Render env vars.
```

No BLE handshake, no QR code, no separate pairing protocol. The token is the
pairing. This is deliberately simple for Epoch 0.

**Token rotation:** generate a new token, update both ends, reconnect. The Pocket
caches it in NVS so it survives reboots.

---

## Local sCoRE Config for Beam

The local sCoRE instance (already planned in `RaBbLE-sCoRE-Local-Architecture.md`,
tickets L-01 through L-08) needs these env additions for beam support:

```bash
# ~/.config/rabble/local.env (or sCoRE's local.env / .secrets)

# ── Local Beam config ─────────────────────────────────────────────────────────

# Route beam turns through Claude Code CLI (the binary on this machine)
BEAM_LLM_CHAIN=claude_code:claude-sonnet-4-5

# Point sCoRE at the local Grimoire — full context, not just gists
GRIMOIRE_PATH=/home/<user>/RaBbLE-Collective/RaBbLE-Grimoire

# Shared secret — same value as the Pocket's >beam.token
BEAM_DEVICE_TOKEN=<token>

# Never open without a token on local either
BEAM_ALLOW_GUEST=false

# Port: 8000 matches rabble-os.local:8000 (the firmware default)
# If fcc is running on 8082 and local sCoRE on 8083 (per existing arch),
# add a reverse proxy or change CONFIG_RABBLE_BEAM_DEFAULT_URL to 8083.
# Simplest: use 8000 for the beam-facing port (see Port Note below).
PORT=8000
```

### Port Note

`RaBbLE-sCoRE-Local-Architecture.md` specifies port **8083** for local sCoRE
(to avoid collision with `fcc` on `:8082`). The Pocket firmware default is `:8000`.
Two options:

**A · Change the firmware default (preferred for EP2)**
Update `CONFIG_RABBLE_BEAM_DEFAULT_URL` in `sdkconfig.defaults` to
`ws://rabble-os.local:8083/api/v1/beam`. Rebuild and flash.

**B · Proxy `:8000 → :8083` on the OS (no firmware change needed)**
A one-line nginx/caddy rule on RaBbLE-OS: `proxy_pass http://localhost:8083;`
on port 8000. The Pocket connects to `:8000`, OS forwards to sCoRE.

Option A is cleaner; Option B avoids a firmware flash. Pick based on whether
you're already doing a firmware build. Document the chosen port in
`RaBbLE-Pocket-Beam-Protocol.md` once decided.

---

## mDNS: How `rabble-os.local` Works

RaBbLE-OS runs on a machine that announces its hostname via mDNS (Avahi on Linux).
The Pocket's ESP-IDF network stack can resolve `.local` names via mDNS natively
(mDNS is part of ESP-IDF's `mdns` component).

**RaBbLE-OS side:** Avahi is installed by default on Fedora. Confirm:
```bash
systemctl status avahi-daemon
# should be active. If not:
sudo systemctl enable --now avahi-daemon
```

Ensure the machine's hostname is `rabble-os`:
```bash
hostnamectl set-hostname rabble-os
# Avahi will immediately advertise rabble-os.local
```

**Pocket side:** no firmware change needed — ESP-IDF's mDNS resolver handles
`.local` hostnames transparently. When the Pocket resolves `rabble-os.local`,
it queries mDNS on the local subnet.

**Firewall:** port 8000 (or 8083) must be open on the laptop for LAN connections:
```bash
# Fedora / firewalld
sudo firewall-cmd --add-port=8000/tcp --zone=home --permanent
sudo firewall-cmd --reload
```

---

## Fallback: Cloud sCoRE When Local Is Unreachable

The Pocket already handles reconnection with backoff (5 s to 120 s) and falls
back gracefully when a connection drops. The firmware does not have a built-in
two-URL failover — it tries the configured `beam.url` and retries on failure.

For now (Epoch 0): the Pocket points at local when at home and the user sets
`>beam.url=` manually when away. A cloud-forwarding approach (where local sCoRE
proxies to cloud when away) is EP2 scope.

**Future (EP2+):** sCoRE could advertise a presence signal via Cloudflare Tunnel
or Tailscale that allows the Pocket to find it from anywhere. But that's a
separate feature; don't build it now.

---

## Claude Code as the Beam LLM

The `claude_code` subprocess provider in `server/llm.py` already exists and works.
When `BEAM_LLM_CHAIN=claude_code:claude-sonnet-4-5` is set:

1. `beam.py` calls `llm.stream_chat()` for the RaBbLE persona reply.
2. `stream_chat` resolves the chain → `claude_code:claude-sonnet-4-5`.
3. `_stream_subprocess` builds: `claude --print --model claude-sonnet-4-5 --system-prompt <persona> -p <prompt>`
4. The subprocess yields the full response as one chunk (stream_chat wraps it).
5. `beam.py` sends the reply as `{"type": "reply", ...}` text frames and TTS audio.

**Known limitation:** `_stream_subprocess` yields the full response at once —
Claude Code's subprocess mode doesn't stream token-by-token. The Pocket receives
all `reply` text frames and the first TTS chunk arrives only after Claude finishes.

This means the voice latency is: STT + CC inference + TTS-first-chunk, compared to
the Groq path which starts TTS after the first sentence. For a local Claude Haiku
call this is typically 2–5 s; Sonnet may be 4–10 s. Acceptable for EP2; real
streaming from CC is a future improvement.

### Model tier recommendation

For the beam (conversational voice turns), use:
- `claude_code:claude-haiku-4-5-20251001` — faster, lower quota burn, fine for voice
- `claude_code:claude-sonnet-4-5` — better reasoning, higher quota cost

Set `BEAM_LLM_CHAIN` to whichever matches your quota budget. You can also chain:
`BEAM_LLM_CHAIN=claude_code:claude-haiku-4-5-20251001,groq:openai/gpt-oss-20b`
so Groq catches failures if CC is unavailable.

---

## Grimoire Context in Local Beam

The cloud sCoRE loads Grimoire gists from disk (if `GRIMOIRE_PATH` is set) or
from the World CDN endpoint. Local sCoRE gets the full gist directory from
the local filesystem — all four gists plus the join section.

No additional code changes needed: `grimoire.py` already discovers the gist
directory via `GRIMOIRE_PATH` or the sibling-repo auto-detect path
(`../../RaBbLE-Grimoire/gist/`). When running from `RaBbLE-sCoRE/server/`
on RaBbLE-OS, the auto-detect path resolves to the real Grimoire.

This means every beam turn from the Pocket already gets the Grimoire identity,
collective, episode, and roadmap context injected into the RaBbLE system prompt —
the same context that shapes Claude Code sessions on the laptop.

---

## RaBbLE-OS Ansible Role Addition

Local sCoRE is already planned for the `ai-harnesses` Ansible role
(`RaBbLE-sCoRE-Local-Tickets.md`, ticket L-01). The beam-specific additions
needed in that role:

```yaml
# In ansible/roles/ai-harnesses/tasks/score-local.yml (EP2 addition)
# After the base score-local service is up:

- name: Configure local beam token
  ansible.builtin.lineinfile:
    path: "{{ lookup('env', 'HOME') }}/.config/rabble/local.env"
    line: "BEAM_DEVICE_TOKEN={{ rabble_beam_device_token }}"
    regexp: "^BEAM_DEVICE_TOKEN="
  # rabble_beam_device_token is a vault secret

- name: Route beam through Claude Code
  ansible.builtin.lineinfile:
    path: "{{ lookup('env', 'HOME') }}/.config/rabble/local.env"
    line: "BEAM_LLM_CHAIN=claude_code:claude-haiku-4-5-20251001,groq:openai/gpt-oss-20b"
    regexp: "^BEAM_LLM_CHAIN="

- name: Ensure avahi-daemon is running
  ansible.builtin.systemd:
    name: avahi-daemon
    state: started
    enabled: true
  become: true

- name: Open beam port in firewalld (home zone)
  ansible.posix.firewalld:
    port: "{{ rabble_beam_port | default('8000') }}/tcp"
    zone: home
    permanent: true
    state: enabled
    immediate: true
  become: true
```

---

## Implementation Order

These steps can be done independently of the EP2 local sCoRE systemd work —
you can run the server manually while that layer is in progress.

### Now (manual, no new code)

1. On the laptop: set hostname to `rabble-os`, start avahi, open port 8000.
2. Create `RaBbLE-sCoRE/server/.env` with the vars above.
3. Run: `cd RaBbLE-sCoRE/server && uv run --with-requirements requirements.txt uvicorn main:app --host 0.0.0.0 --port 8000`
4. On the Pocket console: `>beam.url=ws://rabble-os.local:8000/api/v1/beam` (if not already the default)
5. Talk. Verify Claude Code is being called: `tail -f /tmp/rabble-beam.log` or the uvicorn output.

### EP2 (systemd, Ansible, persistent)

1. Implement L-01 through L-08 tickets (`RaBbLE-sCoRE-Local-Tickets.md`).
2. Add the beam env additions to the Ansible role.
3. Update `CONFIG_RABBLE_BEAM_DEFAULT_URL` to match the chosen port.
4. Tag the beam-as-primary-interface milestone in the Pocket roadmap.

---

## Open Questions

| Question | Notes |
|---|---|
| **Port: 8000 or 8083?** | 8000 = matches firmware default, no proxy needed; 8083 = matches local arch spec, needs firmware change or proxy. Decide before EP2 Ansible work. |
| **Model for voice?** | Haiku (fast, cheap) vs Sonnet (better, more quota). Start with Haiku; user can override via `BEAM_LLM_CHAIN`. |
| **TTS on local?** | Cloud beam uses Groq Orpheus. Local beam can keep Groq TTS (STT and TTS are separate from the LLM call) or swap to a local TTS (Piper, etc.) — per the Local-first principle. Groq for now; local TTS is a separate EP2+ item. |
| **STT on local?** | Same as TTS — Groq Whisper works fine for now; local Whisper is EP2+ per the `Local-first` roadmap. |
| **Streaming from CC?** | CC subprocess doesn't stream; reply latency is higher than Groq. Acceptable for voice conversation; deeper fix requires CC SDK streaming API changes. |
| **Away-from-home failover?** | Out of scope EP2. Manual `>beam.url=` swap when away, or keep cloud URL as a second configured fallback (firmware only supports one URL currently). |

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-10-23 | Initial — authored S269 from conversation with Mark on routing Pocket beam to local Claude. |
