# RaBbLE-sCoRE — Hosted Grimoire API

> Established: S111 (2026-06-16)
> **Successor concept:** this single `fetch_grimoire` HTTP tool is being generalized into a
> standard, surface-agnostic interface — the **Grimoire MCP** (`RaBbLE-Collective/RaBbLE-Grimoire-MCP.md`),
> a read-first remote MCP server at `grimoire.joinrabble.world`. This endpoint stays as a lightweight fallback.

## What This Is

sCoRE's `fetch_grimoire` tool lets RaBbLE pull specific Grimoire documents at runtime — so the entity can answer questions accurately from canonical source rather than hallucinating.

The tool fetches from a hosted HTTP endpoint. Locally it falls back to the on-disk gist directory.

---

## Hosted Endpoint

**Live at:** `https://joinrabble.world/gist/{filename}`

World serves all files in `RaBbLE-World/gist/` as static assets via Cloudflare Workers. These are distilled Grimoire gists — same files as `RaBbLE-Grimoire/gist/`, synced before each World deploy.

**Available documents:**

| Slug | File | Content |
|---|---|---|
| `identity` | `RaBbLE-Identity-gist.md` | Entity identity, character traits, behavioral rules |
| `collective` | `RaBbLE-Collective-gist.md` | Ecosystem map, member list |
| `overview` | `RaBbLE-Collective-Overview-gist.md` | High-level overview |
| `roadmap` | `RaBbLE-Roadmap-gist.md` | Active roadmap + episode status |
| `episode1` | `RaBbLE-Episode1-gist.md` | Episode 1 exit conditions, deploy sequence |
| `versioning` | `RaBbLE-Versioning-gist.md` | Five-Es versioning spec |
| `palette` | `RaBbLE-Palette-gist.md` | Color tokens |
| `commit-style` | `RaBbLE-CommitStyle-gist.md` | Pulse Protocol commit format |
| `integration-map` | `RaBbLE-Integration-Map-gist.md` | Member integration map |

---

## sCoRE Configuration

Set `GRIMOIRE_URL=https://joinrabble.world` in the sCoRE Render environment.

```bash
bash spells/render-ctl.sh env-set GRIMOIRE_URL https://joinrabble.world
```

When unset, `tools.py` falls back to the local gist directory (auto-discovered from `GRIMOIRE_PATH` or the sibling-repo convention). Local dev works without any config.

---

## Keeping Gists in Sync

After any change to `gist/*.md` in the Grimoire, sync to World before deploying:

```bash
bash spells/sync-gists-to-world.sh   # copies gist/*.md → RaBbLE-World/gist/
# then commit World and deploy:
cd ../RaBbLE-World && npx wrangler deploy
```

---

## How the Tool Works

`tools.py` defines a `fetch_grimoire` tool registered with the LLM. The tool is only active on `medium` and `strong` tiers — `fast` tier skips tool calling entirely (small models can't reliably follow function schemas).

Flow:
1. User sends a message → sCoRE routes to medium or strong tier
2. `_resolve_tools()` in `main.py` runs `chat_with_tools()` (non-streaming)
3. If the LLM decides to call `fetch_grimoire(doc="roadmap")`:
   - `tools.execute_tool()` fetches the doc from the endpoint (or local fallback)
   - The content is injected into the message history
4. sCoRE streams the final response with full Grimoire context

The result: RaBbLE answers questions about its architecture, roadmap, and identity from the actual source, not from hallucination.

---

## Model Tier Alignment (S111)

| Tier | Models | Tool Calling |
|---|---|---|
| fast | GPT-OSS-20B → Llama-4-Scout-17B → Llama-3.1-8B | No |
| medium | Qwen3-32B → Llama-3.3-70B | Yes |
| strong | Claude Sonnet → GPT-OSS-120B → Llama-3.3-70B | Yes |

Fast tier uses the best free Groq models available as of 2026 — GPT-OSS-20B (1000 t/s) and Llama-4-Scout-17B (750 t/s) are both significantly more capable than the old Llama-3.1-8B for identity coherence and conversation quality.

For reliable tool calling and agentic behavior, medium (Qwen3-32B) or strong (Claude Sonnet) tier is required.
