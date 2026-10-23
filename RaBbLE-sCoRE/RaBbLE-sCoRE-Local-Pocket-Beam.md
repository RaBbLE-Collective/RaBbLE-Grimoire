# RaBbLE-sCoRE — Pocket Beam Routes: Laptop Claude, Cloud, and the Way Between

```
spark ~ sCoRE >> pocket reaches claude through the paired laptop or the cloud, with no open laptop port // %EP2_LOCAL_BEAM%
```

> **Document type:** Grimoire architecture spec · `RaBbLE-sCoRE/`
> **Status:** v0.3 draft for Mark's decisions (section 12) · Epoch 0 · Episode 2 target · P0/P1 implemented uncommitted (S271), review fixes in progress (§14)
> **Purpose:** One design for how RaBbLE-Pocket reaches Claude: through the laptop's Claude Code
> (Mark's subscription, local Grimoire) when the laptop is available, through cloud sCoRE when it
> is not, with pairing as the trust gate and **no inbound port left open on the laptop by default**.
> **Supersedes:** v0.1 (S269 addendum), which assumed a LAN listener on `:8000` and a shared token as pairing.
> **Related docs:**
> - `RaBbLE-Pocket/RaBbLE-Pocket-Beam-Protocol.md` — beam wire format (`rabble-beam/0`)
> - `RaBbLE-sCoRE-Local-Architecture.md` — local sCoRE service (`127.0.0.1:8083`), tickets in `RaBbLE-sCoRE-Local-Tickets.md`
> - `sCoRE-Local-AI-Layer.md` — provider registry and chains
> - `RaBbLE-OS/layers/RaBbLE-OS-Layer-AI-Harnesses.md` — Claude Code install
> - `RaBbLE-Pocket/RaBbLE-Pocket-Roadmap.md` — EP2 local beam checklist

---

## 1. Summary

| | |
|---|---|
| **What Mark wants** | Talk to the Pocket; Claude answers, with the Collective's context, whether he is at home or away. Port 8000 closed. |
| **Recommendation** | Make **cloud sCoRE the Pocket's one front door** and let the laptop **dial out** to it (a *node link*). Cloud does speech (it already does: Groq STT/TTS); the laptop does the thinking turn with Claude Code. Nothing listens on the laptop's LAN. A direct LAN route comes later, only if latency or Render outages make it worth a port. |
| **Why this order** | It needs **no firmware change** for the first slice (the Pocket already beams to cloud with a token), it works away from home, it keeps TLS everywhere, and it closes the hole found in S271 (section 2) for good instead of narrowing it. |
| **Fallback** | Laptop offline or asleep → cloud answers with its own chain (Groq today; optionally Claude via an Anthropic API key, decision D3). |

---

## 2. Where things stand (verified S271, 2026-10-23)

| Fact | Evidence |
|---|---|
| Pocket firmware on the device: **`c698884`** (new-horizons, offline voice notes on flash), clean build. Not W6. | sCoRE beam `hello fw=c698884` from `RaBbLE-Pocket-5EB8`; app descriptor of `firmware/build/rabble_pocket.bin` |
| Firmware compile-time beam URL is the **cloud**: `wss://rabble-score-x7qq.onrender.com/api/v1/beam`. v0.1's claim that the default is `ws://rabble-os.local:8000` was wrong; S269 set the laptop URL by hand (`>beam.url=`). | `RaBbLE-Pocket/firmware/sdkconfig.defaults:92` |
| Firmware has **no mDNS component** and **no Bluetooth stack** enabled. TLS (`esp_crt_bundle`) and `esp_websocket_client` are in. | `rabble_beam_score.c`, `idf_component.yml`, `sdkconfig.defaults` |
| Internal RAM after boot: ~14.7 KB free. A BLE stack (NimBLE) costs tens of KB of it. | HANDOFF-S270 gotchas |
| Laptop firewalld: `wlp99s0` sits in the **`public`** zone, and `8000/tcp` was opened there permanently in S269 (so: on every Wi-Fi network the laptop joins, not just home). | `firewall-cmd --list-all` |
| The S269 local sCoRE ran on `0.0.0.0:8000` with **`DEMO_MODE=true`** and the default `fast` chain led by `claude_code`, `CC_WORKDIR` = the Collective root. | process environment, `llm.py` `DEFAULT_MODEL_CHAINS["fast"]` |
| **Security hole (S271):** `/api/v1/chat` accepts unauthenticated guests when `DEMO_MODE=true` (`auth.py:67`) and defaults to the `fast` tier → any device on the same network could run Claude Code on Mark's account. Headless Claude with `--allowedTools WebSearch,WebFetch` **can still use Read** (tested S271), so such a caller could read files under the Collective, including `RaBbLE-sCoRE/server/.env` (Groq, OpenRouter, NIM, Render keys, `JWT_SECRET`). The `llm.py` comment "without granting filesystem or shell access" is wrong. | `auth.py`, `main.py:217`, `llm.py:446`; test call in S271 |
| No sign it was used: the access log shows only the Pocket (`192.168.1.31`, beam) and localhost; `audit.jsonl` has no `chat` entries since 2026-06. | tmux scrollback, `audit.jsonl` |
| **P0 done S271:** the `:8000` process was stopped. Still open: remove the firewalld rule (needs sudo, section 11). | |
| `:8000` is also Lemonade's port in the ProArt inventory (`group_vars/asus_proart_p16.yml`). Another reason not to use it for sCoRE. | RaBbLE-OS Ansible |
| Beam auth today: one shared `BEAM_DEVICE_TOKEN` (any holder is "pocket", tier pro), or a member API key, or a JWT. No per-device identity, no revocation short of rotating the one token. | `beam.py:_authorize` |

---

## 3. Goals and non-goals

**Goals**
1. The Pocket gets Claude (Claude Code on the laptop) for voice and typed turns, with the Grimoire as context.
2. The Pocket picks its route **automatically**: no `>beam.url=` swaps when leaving the house.
3. **No inbound port on the laptop** in the default setup. Any later LAN listener is opt-in, home-zone only, beam-only, TLS, paired devices only.
4. Every device is **paired** individually and can be revoked individually.
5. Claude Code launched on behalf of the Pocket **cannot read secrets or touch the filesystem** beyond a curated context.
6. Capture, offline voice notes (outbox) and `heard`/`sent` semantics keep working unchanged on every route.

**Non-goals (this spec)**
- Serving other members through Mark's Claude subscription. The node link is **one owner, own devices**. Members bring their own key or their own laptop (see `project_auth_tiers_web_local`).
- Fully offline operation. Claude, Groq STT and TTS all need the internet; local STT/TTS (Whisper, Piper) is a separate local-first item.
- Streaming Claude Code output token by token (later; section 9.4).

---

## 4. The three routes

```
R1  Cloud + laptop node  (default once P1 lands)
    Pocket ──wss──► cloud sCoRE ──(STT)──► text ──node link (wss, laptop dialed out)──► laptop sCoRE-node
                         ▲                                                          │  claude --print (sandboxed)
                         └──(TTS)◄────────────── reply text ◄────────────────────────┘

R2  Cloud only  (laptop offline/asleep, or node link refused)
    Pocket ──wss──► cloud sCoRE ──► BEAM_LLM_CHAIN (Groq; or anthropic:<model> with an API key, D3)

R3  Direct LAN  (later, opt-in; P3)
    Pocket ──wss (pinned cert)──► laptop beam listener (home zone only) ──► claude --print (sandboxed)
                                     └─ STT/TTS still Groq from the laptop
```

| Route | Works away from home | Laptop port open | Firmware change | Render in the path | Claude |
|---|---|---|---|---|---|
| R1 | yes (laptop must be online somewhere) | **no** | **none** | yes | subscription, via laptop |
| R2 | yes | no | none | yes | API key (D3) or none |
| R3 | no | yes, home zone | yes (mDNS, route list, cert pin) | no | subscription |

**Who chooses:** for R1/R2, **cloud sCoRE** chooses per turn (node linked and healthy → R1, else R2). The Pocket does not need to know. For R3 the Pocket chooses at connect time (section 8).

---

## 5. Identity and pairing

Replace "the shared token is the pairing" with **per-device credentials**, issued once, revocable one at a time.

### 5.1 Identities

| Who | Identifier | Credential | Stored |
|---|---|---|---|
| Pocket | `device_id` (e.g. `RaBbLE-Pocket-5EB8`, already in `hello`) | 32-byte random **device secret** | Pocket NVS (as today's `beam.token`); cloud stores only `sha256(secret)` in a devices table |
| Laptop node | `node_id` (e.g. `rabble-os`) | 32-byte random **node secret** | `~/.config/rabble/node.env` (0600); cloud stores the hash |
| Owner | sCoRE member account (Mark) | existing login / API key | cloud users table |

Both device and node belong to the owner's account. Cloud routes a device's turns only to **nodes of the same owner**.

### 5.2 Pairing ceremony (P1: over USB, no new radio)

```
laptop$ rabble-pocket pair            # new small CLI in RaBbLE-sCoRE/tools/ (or ops/ in Pocket)
  1. finds the Pocket on /dev/serial/by-id/usb-Espressif_*  (reading resets it: expected)
  2. reads device_id from the boot banner / >whoami
  3. asks cloud sCoRE (owner's API key) to mint a device secret for device_id  → returns secret once
  4. writes it to the Pocket: >beam.token=<secret>  (chunked >beam.token+= as today)
  5. confirms: Pocket connects, cloud logs hello device_id, CLI prints "paired"
laptop$ rabble-pocket revoke RaBbLE-Pocket-5EB8
```

- The USB cable is the trust channel: physical possession of both the Pocket and a logged-in laptop.
- The token string is never shown on screen and never written to logs (the console already masks `beam.token` echoes).
- **Migration:** keep accepting the old shared `BEAM_DEVICE_TOKEN` for one release, flagged in logs as `legacy-token`; remove it after the Pocket is re-paired.

### 5.3 Later pairing (P4): BLE or on-screen code

BLE needs a Bluetooth stack the firmware doesn't have and internal RAM it can't spare today (section 2). An alternative with no new radio: the Pocket shows a 6-digit code on the Orbit's sCoRE page, the owner types it on joinrabble.world / laptop CLI, cloud binds the device. Decide after the SDK split frees RAM (D6).

---

## 6. The node link (laptop → cloud)

### 6.1 Shape

The laptop runs **`rabble-score-node`**: local sCoRE started in *node mode*. It opens one outbound WebSocket to cloud and keeps it up. It listens on nothing except, optionally, `127.0.0.1:8083` for the laptop's own use.

```
laptop  ──wss──►  wss://score.joinrabble.world/api/v1/node
        Authorization: Bearer <node secret>
        → {"type":"node.hello","node_id":"rabble-os","caps":["claude_code"],"models":["sonnet","haiku"],"v":0}
        ← {"type":"node.ready","owner":"<member id>"}
```

### 6.2 Messages (`rabble-node/0`, JSON text frames)

| Direction | Type | Fields | Meaning |
|---|---|---|---|
| cloud → node | `turn` | `id`, `device_id`, `messages` (text only), `system`, `model`, `deadline_s` | Run one thinking turn. Never audio, never tool instructions. |
| node → cloud | `turn.reply` | `id`, `text`, `ms` | The reply text |
| node → cloud | `turn.error` | `id`, `code` (`busy`/`timeout`/`cli`), `msg` | Cloud falls back to R2 for this turn |
| node → cloud | `node.busy` / `node.idle` | | Optional back-pressure |
| both | ping/pong | | WS keepalive; interval ≤ 60 s |

Rules:
- **Text in, text out.** The node never receives audio, file paths, shell commands or tool lists from cloud. The goal: a compromised cloud can at most ask Claude a question and cannot widen the sandbox (section 7). This holds **only** if message text can never become a CLI argument (`--` before the prompt, §7) and the node chooses its own tools, cwd and environment.
- **What a question can still do:** with WebFetch on, a prompt (from cloud, or spoken into the Pocket by anyone holding it) can make Claude fetch LAN or loopback URLs from the laptop (router pages, `127.0.0.1:8083`) and read them back, and spends Mark's subscription. Mitigations: `CC_TOOLS=""` for voice, or the network wall of §7 (`bwrap` / `systemd-run` with private networking except outbound HTTPS).
- One turn at a time per node (Claude Code subprocess per turn); cloud queues or falls back.
- **Deadline:** cloud waits `BEAM_NODE_DEADLINE_S` (default 25 s; S269 saw long Claude turns) and then falls back to R2 *for that turn*, telling the Pocket nothing new: the Pocket only sees a reply, as today.
- Cloud marks the node **unhealthy** after 2 consecutive errors/timeouts and stops routing to it until the next `node.hello` or 5 minutes.
- Node reconnects with backoff 2 s → 60 s. Laptop asleep = link down = R2, automatically.

### 6.3 Cloud side (beam turn routing)

In `beam.py`, the LLM step becomes:

```
chain = node_route(owner) + BEAM_LLM_CHAIN      # node_route = [] if no healthy node for this owner
```

So `BEAM_LLM_CHAIN` stays the R2 chain; the node is prepended per owner when linked. A new provider kind `node` in `llm.py` does the send/await. Capture's "shape the note" call can use the same route (D4).

### 6.4 Render keep-alive

Render free tier sleeps without inbound traffic. Whether a held-open WebSocket keeps the instance awake is **unverified**; check in P1 (the node's pings are inbound traffic to Render). If it does, the node link also removes the Pocket's cold start.

---

## 7. Claude Code sandbox (all routes that run Claude Code)

The S271 test showed the current flags don't stop file reads. The node (and any local sCoRE) must launch Claude like this:

| Rule | How |
|---|---|
| Only the tools the beam needs exist | `--tools WebSearch,WebFetch` (the built-in tool set itself, not just pre-approval); keep `--allowedTools WebSearch,WebFetch` so print mode doesn't stall. Verified S271 (Claude Code 2.1.309): with `--tools` the same Read request answers `NO_READ` |
| Belt and braces | `--disallowedTools Bash,Read,Edit,Write,Glob,Grep,NotebookEdit` |
| No secrets in reach | `cwd` = a **context directory** (`~/.local/share/rabble/beam-context/`) holding copies of the Grimoire gists and the docs the persona needs, refreshed by a small sync; **never** the Collective root, never a repo with `.env` files |
| No user/project settings leaking in | `--setting-sources` limited (none, or a dedicated settings file); no MCP servers |
| Message text never becomes an argument | `--` before the positional prompt (or the prompt on stdin); stdin otherwise `/dev/null`. S271 review: without it a message starting with `--settings=`/`--mcp-config=`/`--add-dir=` is parsed as an option |
| No secrets in the environment | the subprocess gets a scrubbed env (no `*_API_KEY`, `JWT_SECRET`, `SCORE_NODE_SECRET`, `BEAM_DEVICE_TOKEN`) |
| Context dir is not a repo | the node refuses to start unless `CC_CONTEXT_DIR` exists and is outside any git tree; never falls back to `CC_WORKDIR` (Claude Code still discovers `CLAUDE.md` and project memory from its cwd, which setting sources don't cover) |
| Only the owner reaches a CLI provider | CLI/subprocess providers are allowed for the owner's device and node identities (plus an explicit `CLI_ALLOWED_SUBS`); guests **and registered members** never get one, on any route including beam |
| No session persistence | print mode, `--no-session-persistence`, no `--resume` |
| Bounded | per-turn timeout (`deadline_s`), max reply length, one turn at a time |
| Optional hard wall | run under `bwrap`/`systemd-run --user -p ProtectHome=tmpfs -p BindReadOnlyPaths=<context>` (the argv-wrapper support from S269 already allows this) |

**Gate (P1):** a test turn asking Claude to read `../RaBbLE-sCoRE/server/.env`, run `ls`, or list tools must fail/deny, and the test lives in `RaBbLE-sCoRE/server` tests. Also fix the misleading comment at `llm.py:446`.

Grimoire context: `grimoire.py` already injects identity/collective/episode/roadmap gists into the system prompt; the context directory gives Claude (via the prompt, not file tools) the rest. If Claude needs to *look things up* in the Grimoire later, that is a deliberate new read-only tool scoped to the context dir, not `Read` on the home directory.

---

## 8. Route choice on the Pocket (only needed for R3)

Today the Pocket has one `beam.url` and retries it with backoff (5 s → 120 s). With R1/R2 it keeps exactly that, pointed at cloud. For R3 later:

- NVS holds a **route list**: `[lan:<node_id>, cloud]`.
- At connect: if a paired laptop answers within 1.5 s (mDNS `_rabble-beam._tcp` with TXT `node=<id>`, or the last known IP), use it; else cloud. Requires adding the ESP-IDF `mdns` component (RAM cost to measure).
- **Sticky per connection**: no switching mid-turn; on LAN drop, the next attempt goes to cloud first, then retries LAN after 10 minutes.
- The Orbit's sCoRE page shows which route is live (`laptop` / `cloud`).
- Outbox (offline voice notes) is route-agnostic: whichever sCoRE says `heard` first wins; ids already make delivery idempotent.

---

## 9. Laptop service layout

### 9.1 Units (RaBbLE-OS, Ansible `ai-harnesses` role, user services)

| Unit | Listens | Purpose |
|---|---|---|
| `rabble-score-node.service` | nothing (outbound only) | Node link to cloud, runs sandboxed Claude turns |
| `rabble-score-local.service` (existing plan, L-01..L-08) | `127.0.0.1:8083` | The laptop's own sCoRE API; `DEMO_MODE=false` |
| `rabble-beam-lan.service` (P3, opt-in) | `0.0.0.0:8443`, TLS | **Beam route only** (`/api/v1/beam`), paired devices only |

Node and local can be one process with two roles; the rule is what listens where, not how many processes.

### 9.2 Config (`~/.config/rabble/node.env`, 0600, Ansible-templated from vault)

```bash
SCORE_NODE_URL=wss://rabble-score-x7qq.onrender.com/api/v1/node   # wss only; ws:// refused off loopback
SCORE_NODE_ID=rabble-os
SCORE_NODE_SECRET=<from vault, >= 32 chars>
CC_COMMAND=claude
CC_MODEL=sonnet                         # D2: sonnet vs haiku for voice
CC_TOOLS=WebSearch,WebFetch
CC_CONTEXT_DIR=%h/.local/share/rabble/beam-context
BEAM_NODE_DEADLINE_S=25
```

`DEMO_MODE` is **never** true on any laptop instance; local sCoRE refuses to start with `DEMO_MODE=true` while bound to a non-loopback address (new startup check).

### 9.3 Ops

- Logs: turn id, device, route, timings; **no transcript or reply text** unless an opt-in `BEAM_LOG_TEXT=1` (S269 note).
- `rabble-pocket status`: node link up?, last turn, route used.

### 9.4 Latency

R1 adds one cloud↔laptop hop (~50–150 ms) to Claude Code's own time (S269: several seconds per turn). Claude Code print mode returns the whole reply; cloud starts TTS when it arrives. Later: `--output-format stream-json` and sentence-by-sentence TTS, the way the Groq path already speaks.

---

## 10. Cloud Claude without the laptop (D3)

"Cloud sCoRE can use Claude" has two honest options:
- **Through the node (R1):** the subscription stays on the laptop; cloud never holds Claude credentials. Needs the laptop online.
- **Through the Anthropic API (R2 with `anthropic:<model>` in `BEAM_LLM_CHAIN`):** an API key in Render's env, billed per token, works with the laptop off. `llm.py` has OpenRouter `anthropic/claude-sonnet-4-6` in the `strong` chain already, so the cheapest first step is OpenRouter (needs credits, see `project_llm_provider_constraints`), or a direct Anthropic provider entry.

A Claude Code subscription login must not be copied to Render.

---

## 11. Ports and firewall

| Port | Status after this spec |
|---|---|
| Render env before deploying P0/P1 | `DEMO_MODE_PUBLIC=true` (the cloud's public demo; without it the service refuses to start behind `0.0.0.0`), `SCORE_NODE_SECRET`, plus whatever §14 lists for register/CORS |
| `8000/tcp` (public zone) | **Remove now** (P0). Mark runs: `sudo firewall-cmd --permanent --zone=public --remove-port=8000/tcp && sudo firewall-cmd --reload` |
| `8083` | loopback only (local sCoRE), no firewall rule |
| `8443/tcp` (P3 only) | firewalld **service** `rabble-beam` in the **`home`** zone only; NetworkManager assigns the home SSID's connection to `home` (`nmcli con mod <ssid> connection.zone home`); every other network stays `public` with nothing open |

All firewall changes go through Ansible (role vars + `layerctl`), not by hand, after P0.

---

## 12. Decisions for Mark

| # | Question | Recommendation |
|---|---|---|
| D1 | Route order: node link (R1) first, direct LAN (R3) later? | **Yes.** R1 closes the port for good, needs no firmware change, works away from home. |
| D2 | Model for voice turns via Claude Code | `sonnet` (what S269 ran); `haiku` if turns feel slow |
| D3 | Cloud Claude without the laptop: API key (OpenRouter or Anthropic) or Groq only? | Groq only until R1 is in daily use, then decide on spend |
| D4 | Capture's note shaping: laptop Claude when linked, or always the cloud fast tier? | Laptop when linked (better notes, same sandbox) |
| D5 | Pairing CLI home: `RaBbLE-sCoRE/tools/` or `RaBbLE-Pocket/ops/`? | Pocket `ops/` (it owns the serial console recipes) |
| D6 | Later pairing: BLE vs on-screen code | On-screen code; revisit BLE after the SDK split frees internal RAM |
| D7 | Keep the old shared token as fallback during migration? | One release, logged as `legacy-token`, then removed |

---

## 13. Plan (vertical slices, each with a gate)

| Phase | Work | Repos | Gate |
|---|---|---|---|
| **P0 — close the hole** (S271) | Stop the `:8000` process (done). Mark removes the firewalld rule. Pocket back on cloud: `>beam.url=wss://rabble-score-x7qq.onrender.com/api/v1/beam`. Fix `llm.py:446` comment. Local sCoRE refuses `DEMO_MODE` on a non-loopback bind. | sCoRE, OS (by hand once) | `firewall-cmd --list-ports` empty; `ss -ltn` shows no `:8000`; Pocket beams to cloud |
| **P1 — node link** | `/api/v1/node` on cloud; `node` provider; `rabble-score-node` client; sandboxed Claude argv (section 7) + context dir; per-owner routing with fallback; deadline + health | sCoRE | Pocket voice turn answered by laptop Claude with the laptop's LAN closed; same turn falls back to Groq when the node is stopped (no Pocket-visible error); sandbox test denies `.env` read |
| **P2 — per-device pairing** | Devices/nodes tables (hashed secrets); `rabble-pocket pair/revoke`; legacy token window | sCoRE, Pocket `ops/` | Re-paired Pocket works; revoked secret gets 401; logs never show a secret |
| **P2b — persistence** | Ansible: `rabble-score-node.service`, `node.env` from vault, context-dir sync | OS | Fresh login → node link up without a terminal |
| **P3 — direct LAN (opt-in)** | Beam-only TLS listener on `8443`, home zone; Pocket route list + mDNS + cert pin learned at pairing | sCoRE, Pocket FW, OS | Home: route `laptop`, works with Render down; café: nothing listening, route `cloud` |
| **P4 — pairing without a cable** | On-screen code (or BLE per D6); Orbit sCoRE page shows route | Pocket FW, sCoRE, World | Pair a wiped Pocket with no USB |

P1 is the one slice to build first; P3 is optional and can wait for the SDK split (it touches `rabble_net`).

---

## 14. S271 review of the P0/P1 code (Opus, link level)

Fixed or being fixed before anything is committed or deployed:

| # | Finding | Fix |
|---|---|---|
| 1 | **Argv injection:** prompt passed as `-p <prompt>` positional; a message starting with `--` became a Claude Code option (`--settings`, `--mcp-config`, `--add-dir`, `--dangerously-skip-permissions`) | `--` before the prompt for every CLI style; stdin `/dev/null` |
| 2 | Open `POST /api/v1/auth/register` hands out member keys, and members still reached `claude_code` (only guests were stripped); local CORS was `*` with credentials | CLI providers for owner identities only; register behind `ALLOW_REGISTER`; local CORS restricted |
| 3 | Beam called the LLM without `user`, so beam guests and member keys reached `BEAM_LLM_CHAIN=claude_code:…` | beam passes its user; same owner-only rule |
| 4 | Node cwd fell back to `CC_WORKDIR` (Collective root) / `server/` (holds `.env`); Claude Code loads CLAUDE.md and project memory from cwd | context dir required, outside any git tree; scrubbed env |
| 5 | Render would refuse to boot (Procfile binds `0.0.0.0`, cloud runs `DEMO_MODE=true`) | set `DEMO_MODE_PUBLIC=true` on Render first; documented in `env.defaults` |
| 6 | Deadline race: cloud and node used the same 25 s from different start points; cloud cleared `busy` while Claude kept running | node uses deadline − 3 s; `turn.cancel` frame kills the subprocess |
| 7 | `--setting-sources ""` unverified: if rejected, every turn silently falls back to Groq | Mark runs the `RUN_CLAUDE_SMOKE=1` test once; assert a real reply |
| 8 | Small: secret length, `ws://` off loopback, binary frames, CLI detection by `cli_style` instead of `type == "subprocess"`, `scripts/start-rabble.sh` still on `0.0.0.0:8000` | all fixed in the same pass |

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-10-23 | Initial: authored S269 from conversation with Mark on routing Pocket beam to local Claude. |
| v0.2 | 2026-10-23 | S271 rewrite: verified current state (firmware default is cloud, no mDNS/BLE, `:8000` open in the public zone), security finding (unauthenticated chat → Claude Code with file reads), P0 done; outbound node link as the primary design; per-device pairing; Claude Code sandbox; routes R1–R3; decisions D1–D7; phased plan with gates. |
| v0.3 | 2026-10-23 | S271 Opus review: argv-injection, owner-only CLI providers, beam user, context-dir and env rules, LAN SSRF via WebFetch, Render `DEMO_MODE_PUBLIC`, deadline/cancel; §14 added. |
