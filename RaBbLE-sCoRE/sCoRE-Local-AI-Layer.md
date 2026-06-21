# sCoRE Local AI Layer

> Canonical doc for sCoRE's multi-provider LLM architecture and the long-term RaBbLE TUI goal.
> Implementation lives in `RaBbLE-sCoRE/server/llm.py`.

---

## What It Is

The Local AI Layer is sCoRE's provider registry — the abstraction that lets sCoRE route
completions to any LLM backend (cloud API, local server, or CLI subprocess) and fall through
a priority chain when a provider is unavailable or rate-limited.

"Local" means two things:
1. **Local-first preference in chains** — on a developer machine, `claude_code` and `local_llm`
   (Ollama) sit at the top of the fast chain so the machine runs without cloud calls.
2. **Local install substrate** — RaBbLE-OS's `ai-harnesses` Ansible role provisions all the
   CLIs and runtimes that sCoRE's subprocess providers call.

---

## Provider Registry

All providers live in `BUILTIN_PROVIDERS` in `server/llm.py`. The registry has three provider types:

### Cloud (HTTP, OpenAI-compat)

| Name | Endpoint | Key env | Notes |
|---|---|---|---|
| `groq` | groq.com | `GROQ_API_KEY` | 1000 t/s GPT-OSS-20B, 750 t/s Llama-4-Scout |
| `openrouter` | openrouter.ai | `OPENROUTER_API_KEY` | Meta-aggregator; Claude/Gemma free tier |
| `openai` | openai.com | `OPENAI_API_KEY` | GPT-4o, o1 |
| `cerebras` | cerebras.ai | `CEREBRAS_API_KEY` | 700+ t/s, free tier. Best for fast tier. |
| `deepseek` | deepseek.com | `DEEPSEEK_API_KEY` | V3 = near-frontier coding, ~$0.14/M. R1 = strong reasoning. |
| `nvidia_nim` | integrate.api.nvidia.com | `NVIDIA_NIM_API_KEY` | Free tier, 100+ models (Nemotron, Llama, Mistral) |
| `mistral` | api.mistral.ai | `MISTRAL_API_KEY` | GDPR-friendly, Codestral for code |
| `together` | api.together.xyz | `TOGETHER_API_KEY` | Cheap Llama/Qwen hosting |
| `xai` | api.x.ai | `XAI_API_KEY` | Grok-2/3 |
| `zhipu` | bigmodel.cn | `ZHIPU_API_KEY` | Z.ai / Zhipu AI — GLM-4, free tier, strong multilingual |

### Local Inference (HTTP, OpenAI-compat servers)

| Name | Default URL | Notes |
|---|---|---|
| `local_llm` | `localhost:11434` | Ollama, llama.cpp, vllm — override via `LOCAL_LLM_URL` |
| `lm_studio` | `localhost:1234` | LM Studio GUI server — override via `LM_STUDIO_URL` |
| `llamafile` | `localhost:8080` | Self-contained binary — override via `LLAMAFILE_URL` |

### Subprocess Harnesses (CLI tools)

These call installed CLI tools and yield their output. Auth is the tool's own mechanism.

| Name | Command | CLI style | Notes |
|---|---|---|---|
| `claude_code` | `claude` | `--print --model ... --system-prompt ... -p` | CC session or `ANTHROPIC_API_KEY` |
| `codex` | `codex` | `--full-context --quiet -m ... <prompt>` | `OPENAI_API_KEY` |
| `opencode` | `opencode` | `run --print --model ... <prompt>` | Multi-provider TUI |
| `aider` | `aider` | `--no-pretty --no-auto-commits --message ...` | `OPENAI_API_KEY` or any provider key |
| `gemini_cli` | `gemini` | `-p <prompt>` | `GEMINI_API_KEY` or Cloud ADC |

---

## Default Model Chains

Three tiers. Override any with `LLM_FAST_CHAIN`, `LLM_MEDIUM_CHAIN`, `LLM_STRONG_CHAIN` env vars
(comma-separated `provider:model` pairs). Add runtime providers via `LLM_PROVIDERS_JSON`.

### fast
Speed first. Local/CC preferred on developer machines.
```
claude_code:claude-haiku-4-5-20251001 → local_llm:llama3.2 → cerebras:llama-3.3-70b
→ groq:openai/gpt-oss-20b → groq:meta-llama/llama-4-scout-17b-16e-instruct
→ groq:llama-3.1-8b-instant → openrouter:google/gemma-4-26b-a4b-it:free
```

### medium
Quality + cost. DeepSeek-V3 leads (frontier coding at near-zero cost).
```
deepseek:deepseek-chat → groq:qwen/qwen3-32b → nvidia_nim:meta/llama-3.3-70b-instruct
→ together:meta-llama/Llama-3.3-70B-Instruct-Turbo → groq:llama-3.3-70b-versatile
→ openrouter:google/gemma-4-26b-a4b-it:free
```

### strong
Best available. Claude Sonnet for agentic quality; DeepSeek-R1 for reasoning tasks.
```
openrouter:anthropic/claude-sonnet-4-6 → deepseek:deepseek-reasoner
→ nvidia_nim:nvidia/llama-3.3-nemotron-super-49b-v1
→ groq:openai/gpt-oss-120b → groq:llama-3.3-70b-versatile
```

---

## User Backend Resolution (`resolve_user_chain`)

Per-user backend stored in user record (`llm_backend` field). Governs which chain/provider a
user's requests route to.

| `llm_backend` value | Resolves to |
|---|---|
| `hosted_openrouter` (default) | Full default chain for tier |
| `hosted_groq` | Groq-only candidates from tier chain |
| `hosted_deepseek` | deepseek-only candidates |
| `hosted_cerebras` | cerebras-only candidates |
| `hosted_nvidia_nim` | nvidia_nim-only candidates |
| `hosted_together` | together-only candidates |
| `hosted_mistral` | mistral-only candidates |
| `local_ollama` | `local_llm` with `LOCAL_LLM_MODEL` |
| `local_lm_studio` | `lm_studio` with `LM_STUDIO_MODEL` |
| `byo_openrouter` | `openrouter_byo` + user's `byo_key_plain` |
| `byo_deepseek` | `deepseek_byo` + user's key, `deepseek-chat` |
| `byo_mistral` | `mistral_byo` + user's key, `mistral-large-latest` |
| `byo_openai` | `openai` + user's key, `gpt-4o` |

---

## free-claude-code — Local Anthropic API Proxy

**Repo:** https://github.com/Alishahryar1/free-claude-code (MIT)

A FastAPI server on `:8082` that speaks the Anthropic Messages API. Claude Code CLI
routes through it via `ANTHROPIC_BASE_URL=http://localhost:8082`, giving CC access to
Groq/Cerebras/DeepSeek/NIM/Gemini/etc. at no Anthropic cost.

**sCoRE integration:** `claude_code_proxy` provider (subprocess, injects `ANTHROPIC_BASE_URL`
and `ANTHROPIC_AUTH_TOKEN` as subprocess env overrides). Falls through to `claude_code`
(direct) and then cloud providers in the fast chain.

**Manage with:**
```bash
fcc-ctl start|stop|restart|status|logs|admin|update
fcc-ctl keys                              # show which provider keys are set
fcc-ctl key GROQ_API_KEY gsk-...          # set a key + restart
fcc-ctl model sonnet deepseek:deepseek-chat  # route a Claude tier to a provider
```

**Config:** `~/.config/rabble/fcc.env` (seeded from `RaBbLE-OS/config/rabble/fcc.env.example`)
**Admin UI:** `http://127.0.0.1:8082/admin` (localhost-only)
**Service:** `systemctl --user status free-claude-code`

---

## BuilderIO/skills — Claude Code Slash Commands

**Repo:** https://github.com/BuilderIO/skills (MIT)

Modular skill library for AI coding agents. Installed into Claude Code's global commands
directory (`~/.claude/commands/`). Skills are invoked as slash commands.

**Installed skills (default):**
- `/visual-plan` — interactive diagram-rich planning documents
- `/visual-recap` — visual code change recaps
- `/quick-recap` — quick summary recaps

**Update:**
```bash
npx @agent-native/skills@latest add --skill visual-plan --skill visual-recap --scope user
```

---

## OS Install — `ai-harnesses` Ansible Role

`RaBbLE-OS/ansible/roles/ai-harnesses/` installs all subprocess harness dependencies.
Run independently with:
```bash
ansible-playbook site.yml --tags ai-harnesses
```

Individual tags: `--tags claude-code`, `--tags codex`, `--tags opencode`,
`--tags aider`, `--tags gemini-cli`, `--tags ollama`, `--tags free-claude-code`,
`--tags builder-skills`, `--tags vllm` (disabled by default)

**llama.cpp** is installed by the `runtime` role (not ai-harnesses) — it's infrastructure:
```bash
ansible-playbook site.yml -K --tags runtime,llama-cpp
```

---

## RaBbLE TUI — EP2 Vision

**Goal:** Replace the need to independently open `claude`, `codex`, or `opencode` TUIs.
Instead, the single interaction surface is the RaBbLE/rabble TUI — a terminal application
with Aether styling that presents the entity and delegates to any registered backend.

**What it looks like:**
- Feels like a Claude Code or Codex TUI but with RaBbLE identity (NeBuLA entity, Aether palette)
- Backend selector (switch between `claude_code`, `codex`, `opencode`, `local_llm`, etc.)
- sCoRE identity layer always present — every interaction goes through the entity
- Transcript log to `~/RaBbLE-chats/` (same format as current chat bridge)
- Multi-session: can have parallel conversations with different backends

**What needs to be built (EP2):**
1. `rabble-tui` — Rust or Python TUI (ratatui or textual) with Aether color tokens
2. Backend adapter protocol — normalizes CC/Codex/opencode subprocess I/O into streaming chunks
3. Entity state binding — NeBuLA state reflected in terminal (color/animation hints via OSC escapes)
4. sCoRE system prompt injection — every backend gets the RaBbLE identity prompt
5. Session persistence — conversation history bridged across backend switches

**Precedent in sCoRE:** `scripts/rabble-shell.sh` is the prototype — a custom REPL with
spinners and dispatch notifications. The TUI extends this into a full interaction surface.

**Not in scope until EP2:** actual TUI implementation. EP1 work = provider registry
(this doc) + OS installs + subprocess adapters in `llm.py`.
