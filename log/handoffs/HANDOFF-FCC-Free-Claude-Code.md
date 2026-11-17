# HANDOFF — free-claude-code (FCC) tuning for agentic output

**Date:** 2026-06-21 · **Phase:** Epoch 0 · Episode 1 in flight
**Scope:** Dev *tooling* / environment — **not** a RaBbLE member. This is about the proxy
Mark uses to run Claude Code on free/cheap models, so the Collective's agent work costs less.
**Status:** Research only. No config changed yet. Resume here to actually tune FCC + add backoff.

> Cold-start context: FCC = [`Alishahryar1/free-claude-code`](https://github.com/Alishahryar1/free-claude-code),
> a **LiteLLM-backed FastAPI proxy** (listens on `localhost:8082`, exposes `/v1/messages`,
> `/v1/messages/count_tokens`, `/v1/models`) that intercepts Claude Code's API calls and reroutes
> them to free/cheap providers. Mark is running it and hitting two issues (below).
>
> **Config home (KNOWN):** `~/.claude-free/fcc.env` (live) — tier model ids live here. **Source of
> truth** is the RaBbLE-OS Ansible role `ai-harnesses` (`fcc.env.example` + `tasks/free-claude-code.yml`),
> deployed via `layerctl apply ai-harnesses`. Per the OS dotctl flow: **edit the RaBbLE-OS source,
> not `~/.claude-free/` directly** (live edits get overwritten on next apply). The Admin-UI hot-swap
> is for quick experiments; persist the winning config back into the Ansible source.
> Auth note (S142): `~/.claude-free/.claude.json` must keep `fcc-no-auth` in `customApiKeyResponses.approved`
> (Ansible-enforced) or Claude Code silently returns ~11 empty tokens.

---

## What triggered this research (S-this-session)

1. **Opus tier 400** — `Upstream provider NIM returned HTTP 400 … "chat_template is not supported
   for Mistral tokenizers"`. **Root cause is concrete:** S142 set `MODEL_OPUS =
   mistralai/mistral-large-3-675b-instruct-2512` (a Mistral-family model). NVIDIA NIM serves Mistral
   models via `mistral-common` tokenization, which has **no registered Jinja chat template**, so the
   `/v1/chat/completions` call is rejected. Sonnet worked (S142 set it to `deepseek-ai/deepseek-v4-flash`
   — non-Mistral). **Fix: repoint `MODEL_OPUS` off mistral-large-3 to a non-Mistral, tool-calling model;
   never point any tier at a Mistral-tokenizer model on NIM's chat endpoint** (this also rules out the
   otherwise-excellent Devstral / Codestral / Mixtral). S142 tiers for reference: Haiku =
   `meta/llama-4-maverick-17b-128e-instruct`, Sonnet = `deepseek-ai/deepseek-v4-flash`,
   Opus = `mistralai/mistral-large-3-675b-instruct-2512` ← **the culprit**.
2. **NVIDIA NIM rate limit** — hosted free tier is **40 RPM, per-model, rolling 60-second window**
   (not a fixed clock-minute reset). Not raisable on request. Claude Code is bursty → hits it fast.

---

## Key facts established (verified against the FCC README this session)

- **Not limited to 3–4 models.** `MODEL`, `MODEL_OPUS`, `MODEL_SONNET`, `MODEL_HAIKU` are **routing
  slots**, not a capacity cap. Claude Code only ever requests opus/sonnet/haiku-class + a fallback,
  so there are exactly 4 *live routes* — but each can target any of **17 providers** × many models.
- **Hot-swap, no restart.** Change a slot in the **Admin UI** → *edit fields → Validate → Apply*;
  takes effect live. (`fcc-claude` re-reads port + auth token on each launch.) This is the "tons of
  models without restart" claim — true: 4 live routes, unlimited swappable targets.
- **17 providers:** NVIDIA NIM, OpenRouter, Google AI (Gemini), DeepSeek, Mistral La Plateforme,
  Mistral Codestral, OpenCode Zen, OpenCode Go, Wafer, Kimi, Cerebras Inference, Groq, Fireworks AI,
  Z.ai, LM Studio, llama.cpp, Ollama.
- **Per-tier routing is STATIC.** README documents **no** automatic retry / backoff / error-failover.
  BUT the `provider/model` prefix syntax (`nvidia_nim/…`, `open_router/…`) means **LiteLLM underneath**,
  which natively supports `num_retries`, `fallbacks` (ordered multi-provider), and `cooldown_time`.
- **Probe short-circuit:** FCC answers trivial Claude Code probe/status calls locally before they hit
  any provider — keep this on; it's free RPM savings.
- **NIM usage visibility:** none granular. `build.nvidia.com` shows **credits balance only**, no live
  RPM meter / countdown. Only authoritative signal = **`Retry-After` header on a 429** (if present).

---

## Recommended config (starting point — picks a non-Mistral, tool-calling model per tier)

```
MODEL_OPUS   = nvidia_nim/moonshotai/kimi-k2.6              # rare, strong agentic reasoning
MODEL_SONNET = nvidia_nim/nvidia/nemotron-3-super-120b-a12b # workhorse (~80% of calls), non-Mistral
MODEL_HAIKU  = lmstudio/qwen3.5-coder                       # the probe flood → LOCAL, zero RPM cost
MODEL        = open_router/openrouter/free                  # catch-all failover, OFF NIM's 40 RPM
```

**The single biggest lever:** move the **Haiku-tier flood off NIM** (to local LM Studio/Ollama, or
Cerebras/Groq). That flood is what burns the 40 RPM; reserving NIM for Sonnet/Opus real work is the
whole game. Verify each model's tool-calling support at `build.nvidia.com/explore/discover` first.

---

## Future-session improvement backlog (what Mark wants to do next)

1. **Add LiteLLM retry + backoff + failover** to the FCC proxy:
   - `num_retries` + exponential backoff on 429/5xx (read `Retry-After` when present).
   - `fallbacks`: ordered chain per tier (e.g. NIM → OpenRouter → Groq → local) so a 429 rolls to the
     next provider instead of freezing the agent loop.
   - `cooldown_time`: sideline a provider that just 429'd so bursts don't keep hammering it.
   - **This same hook = observability:** log 429s + `Retry-After` + running request rate, since the
     platform gives no usage meter. Fix + visibility are one change.
2. **Tier-split by RPM headroom**, not just by smarts (table above). Optionally use the **opusplan**
   pattern: Opus for plan-mode reasoning, auto-switch to Sonnet for generation.
3. **Multiple keys / providers = multiplied effective RPM.** Spread tiers so no single 40 RPM wall
   throttles the whole agent.
4. **Expectations:** free models fail more on long multi-step tool loops → shrink task scope, explicit
   plans, frequent checkpoints. Keep paid Claude for production/client code.

### Cold-start TODO for the resuming agent
- [ ] Repoint `MODEL_OPUS` off `mistral-large-3` (kills the chat_template 400) → e.g. Kimi K2.6 /
      Nemotron-3-super / DeepSeek. Edit the **RaBbLE-OS Ansible source** (`ai-harnesses` `fcc.env.example`),
      then `layerctl apply ai-harnesses` — not `~/.claude-free/fcc.env` directly. Admin-UI hot-swap ok
      for the quick test first (no restart).
- [ ] Wire LiteLLM `num_retries` + `fallbacks` + `cooldown_time` + 429/Retry-After logging.
- [ ] Move Haiku tier to a local model (LM Studio/Ollama); confirm probe short-circuit is active.
- [ ] Keep auth invariant: `fcc-no-auth` stays in `.claude.json` `customApiKeyResponses.approved`.

---

## Sources
- FCC repo: https://github.com/Alishahryar1/free-claude-code
- NIM + Claude Code: https://docs.nvidia.com/nim/large-language-models/latest/ai-assistant-integrations/claude-code.html
- NIM rate limits: https://forums.developer.nvidia.com/t/api-rate-limit-increase-for-nvidia-nim/366043
- Cheaper-models routing: https://www.mindstudio.ai/blog/claude-code-cheaper-models-openrouter-nvidia-nim-ollama
- Multi-model routing patterns: https://www.mindstudio.ai/blog/ai-agent-token-cost-optimization-multi-model-routing
- Best model for Claude Code: https://www.morphllm.com/claude-code-models
