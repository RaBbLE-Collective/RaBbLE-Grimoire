# RaBbLE Grimoire Spells

```
transcribe ~ grimoire >> the incantations that manifest realms // %SPELLS_CURRENT%
```

Spells are bash scripts in `spells/` that manage the RaBbLE Collective. Grimoire is the source; spells are the distribution mechanism. Run `bash spells/help.sh` for a quick reference.

**All spells run from Grimoire root:** `cd RaBbLE-Grimoire && bash spells/<name>.sh`
**Every spell supports `--help`** for usage, flags, and examples.

---

## Quick Reference

| Spell | Purpose | When to use |
|---|---|---|
| `help.sh` | List all spells with descriptions | Orienting — what's available |
| `status.sh` | Collective health dashboard | Start of session — check member states |
| `setup.sh` | Bootstrap: clone repos, wire symlinks | Fresh machine or new member added |
| `sync-symlinks.sh` | Create CLAUDE.md/CODEX.md/GEMINI.md → AGENT.md | After adding a repo or fixing broken links |
| `sync-grimoire.sh` | Push Grimoire docs to member `grimoire/` dirs | After updating shared RaBbLE-Agent/ docs |
| `init-project.sh` | Scaffold a new Collective member | Creating a new repo |
| `dev-serve.sh` | Launch local dev environment (Aether+NeBuLA+World on :8080) | Development — always use this, not manual servers |
| `cast-aether.sh` | Build + stage Aether CSS to World | After Aether CSS changes, before testing in World |
| `cast-cdn.sh` | Build all + deploy to joinrabble.world via wrangler | Production deploy |
| `deploy-score.sh` | Deploy sCoRE to Railway | sCoRE deploy |
| *(sCoRE)* `local-start.sh` | Start sCoRE API server locally on :8000 | Local chat dev — run before opening RaBbLE-Chat |
| `distill-gists.sh` | Regenerate gist/ summaries via Claude CLI | After major doc changes |
| `install-theme.sh` | Install RaBbLE theme on OS | RaBbLE-OS theming setup |
| `visual-screenshot.sh` | Capture browser screenshot for agent visual review | Verifying UI changes — agent sees the PNG |
| `token-budget.sh` | Calculate token cost of onboarding paths | Auditing doc bloat, optimizing agent context |
| `graph-grimoire.sh` | Build doc link graph (JSON + Mermaid) | Auditing cross-links, finding orphan docs |
| `session-tokens.sh` | Parse Claude Code transcripts for usage data | Tracking token spend per session/project |
| `end-session.sh` | Record end-of-session feature breadcrumb (agent-agnostic) | Closing a session — tag its token spend |
| `install-hooks.sh` | Install the post-commit breadcrumb hook in all repos | Once per machine / after cloning a new member |

---

## Setup & Bootstrap

### `setup.sh` — Bootstrap the Collective

Clones or updates all registered member repos, creates symlinks, optionally syncs common docs.

```bash
bash spells/setup.sh                          # full: pull all + wire symlinks
bash spells/setup.sh --links-only             # symlinks only, no pulls
bash spells/setup.sh --pull-only              # pull/update only
bash spells/setup.sh --project RaBbLE-OS      # single project
```

**Reads:** `registry/manifests/*.manifest.yml`

### `sync-symlinks.sh` — Wire Agent Entry Points

Creates CLAUDE.md, CODEX.md, GEMINI.md as symlinks to AGENT.md in every member repo. Ensures those names are in `.gitignore`. AGENT.md is the canonical file — symlinks are gitignored derivatives.

```bash
bash spells/sync-symlinks.sh                  # create all symlinks
bash spells/sync-symlinks.sh --dry-run        # preview only
```

### `init-project.sh` — Scaffold New Member

Creates a new Collective member with standard structure: AGENT.md, CONTEXT.md, REFERENCES.md, manifest entry.

```bash
bash spells/init-project.sh --slug RaBbLE-[Name] --role [substrate|server|frontend|tooling]
```

### `sync-grimoire.sh` — Propagate Common Docs

Copies `RaBbLE-Agent/` docs to member `grimoire/` directories. Members opt in via `grimoire_sync: true` in their manifest.

```bash
bash spells/sync-grimoire.sh                  # sync all opted-in members
bash spells/sync-grimoire.sh --project RaBbLE-OS
bash spells/sync-grimoire.sh --dry-run
```

---

## Development

### `dev-serve.sh` — Local Dev Environment

Launches Aether watcher + NeBuLA watcher + World dev server. **Always use this** — never run `dev-cdn.js` or `esbuild --watch` manually.

```bash
bash spells/dev-serve.sh              # full: Aether + NeBuLA watchers + World on :8080
bash spells/dev-serve.sh --world      # World server only (no watchers)
bash spells/dev-serve.sh --aether     # Aether watcher only
bash spells/dev-serve.sh --nebula     # NeBuLA watcher only
DEV_PORT=9000 bash spells/dev-serve.sh  # override port
```

**Port:** `8080` (default) — intentionally leaves `8000` free for sCoRE API. Override with `DEV_PORT`.

**Prereqs:** Node.js, npm, repos cloned.

### `RaBbLE-sCoRE/spells/local-start.sh` — Start sCoRE API Locally

Installs Python deps and starts the sCoRE FastAPI server with hot-reload. Run this before opening RaBbLE-Chat so the entity has a backend to talk to.

```bash
# Cast from sCoRE root
cd ~/RaBbLE/RaBbLE-sCoRE && bash spells/local-start.sh
```

**Port:** `8000` (or `$PORT` from `server/.env`). Runs on `:8000` — World dev server uses `:8080`, so they coexist.

**Prereqs:** Python 3.11+, `server/.env` exists (see `server/env.defaults` and `server/secrets.example`). Minimum `.env` for local play:

```bash
DEMO_MODE=true          # bypass JWT — all requests come through as guest
CC_LOCAL_URL=http://localhost:3001   # adjust to wherever CC's local API is listening
```

**LLM provider chain (fast tier):**
1. Claude Code local API (`CC_LOCAL_URL`) — Haiku, uses CC's existing auth
2. Local inference (`LOCAL_LLM_URL`) — Ollama / llama.cpp / vllm, OpenAI-compatible
3. Groq (`GROQ_API_KEY`) — cloud fallback
4. OpenRouter (`OPENROUTER_API_KEY`) — cloud fallback

sCoRE falls through the chain automatically — if CC isn't running, it tries the next candidate.

**Full local stack:**
```bash
# Terminal 1 — CC local API (your existing workflow)
# Terminal 2 — sCoRE
cd ~/RaBbLE/RaBbLE-sCoRE && bash spells/local-start.sh
# Terminal 3 — World
cd ~/RaBbLE/RaBbLE-World && bash ../RaBbLE-Grimoire/spells/dev-serve.sh
# Browser
open http://localhost:8080/world/RaBbLE-Chat.html
```

**Quick smoke test:**
```bash
curl http://localhost:8000/health
curl -s -X POST http://localhost:8000/api/v1/chat \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"who are you?"}],"model_tier":"fast"}'
```

### `visual-screenshot.sh` — Agent Visual Capture

Opens a URL in Firefox on a scratch Hyprland workspace, captures via `grim`, closes, returns. Prints `SCREENSHOT: /path` for agent file reading.

```bash
bash spells/visual-screenshot.sh                                      # default dev server
bash spells/visual-screenshot.sh --url http://localhost:8000/Boot.html
bash spells/visual-screenshot.sh --delay 5                            # heavy pages
```

**Requires:** Hyprland session, Firefox, `grim`.

---

## Build & Deploy

### `cast-aether.sh` — Publish Aether CSS

Builds Aether CSS bundle and stages it into World for Cloudflare deploy.

```bash
bash spells/cast-aether.sh
```

### `cast-cdn.sh` — Full CDN Deploy

Builds Aether + NeBuLA, stages into World, deploys to `joinrabble.world` via Wrangler.

```bash
bash spells/cast-cdn.sh
```

### `deploy-score.sh` — Deploy sCoRE to Railway

Wraps `RaBbLE-sCoRE/harness/` with Grimoire-level awareness. Pushes to Railway production.

```bash
bash spells/deploy-score.sh
```

**Note:** For local dev use `RaBbLE-sCoRE/spells/local-start.sh` instead — see Development section above.

### `install-theme.sh` — OS Theme Installation

Installs RaBbLE synthwave theme across OS components. RaBbLE-OS specific.

```bash
bash spells/install-theme.sh
```

---

## Docs & Maintenance

### `distill-gists.sh` — Regenerate Gist Summaries

Uses Claude CLI to distill canonical docs into `gist/` summaries (~200 words each). Gists are the primary low-token onboarding path.

```bash
bash spells/distill-gists.sh                  # regenerate all
bash spells/distill-gists.sh identity         # one gist (by slug)
```

**Available slugs:** identity, collective, roadmap, commitstyle, versioning, palette, overview, episode1, integration

**Requires:** `claude` CLI in PATH.

---

## Analytics

### `token-budget.sh` — Onboarding Token Cost

Calculates approximate token cost for each agent reading path defined in the Navigator. Answers: "how much does onboarding cost?"

```bash
bash spells/token-budget.sh                   # full per-file breakdown
bash spells/token-budget.sh --summary         # totals only
```

### `graph-grimoire.sh` — Documentation Link Graph

Scans all `.md` files, extracts markdown links, builds an adjacency graph. Reports orphan docs (no incoming links), hub docs, and islands (completely disconnected).

```bash
bash spells/graph-grimoire.sh                 # graph + summary
bash spells/graph-grimoire.sh --json-only     # JSON only, skip Mermaid
```

**Outputs:** `log/grimoire-graph.json` (adjacency list), `log/grimoire-graph.md` (Mermaid diagram — renderable in GitHub/Obsidian).

### `session-tokens.sh` — Claude Code Token Telemetry

Parses Claude Code session JSONL transcripts to extract token usage per session.

```bash
bash spells/session-tokens.sh                 # all sessions (weighted-cost table)
bash spells/session-tokens.sh --recent 10     # last 10 sessions
bash spells/session-tokens.sh --json          # write log/session-tokens.json
bash spells/session-tokens.sh --onboarding    # orientation cost before first edit
bash spells/session-tokens.sh --by-feature    # group spend by feature (ledger)
```

**Reads:** `~/.claude/projects/-home-rabble-RaBbLE-*/*.jsonl`

**Weighted cost:** raw counts mislead (output ≈5× input, cache-read ≈0.1×, cache-write
≈1.25×). The **Weighted** column normalizes to input-equivalent tokens — a single
honest spend figure. `$` estimate uses `RABBLE_INPUT_PRICE` ($/MTok input, default 15).

**Per-feature attribution** needs a breadcrumb: a row in `log/token-ledger.tsv` —
`session_id <TAB> feature <TAB> note`. `--by-feature` joins ledger → weighted spend.
Don't write the row by hand — use `end-session.sh` (explicit) or the post-commit hook
(automatic). This is the seed of the self-learning loop: each session records what it
spent where, so per-feature cost sharpens over time.

### `end-session.sh` — End-of-Session Breadcrumb (agent-agnostic)

The deliberate way to close a session. Records one ledger row tying the session to a
feature. Pure bash — works under Claude, Codex, Gemini, any agent. **No `.claude/`
settings, no agent-specific hooks** (the Collective is LLM-agnostic; settings.json
hooks would only fire for Claude).

```bash
bash spells/end-session.sh <feature-slug> [note]     # upsert this session's breadcrumb
```

Resolves the session id from the active Claude transcript for the cwd; falls back to a
git-commit key for non-Claude agents. **Upserts** — re-running replaces the row, and it
overrides any provisional row the hook wrote.

### `install-hooks.sh` + post-commit hook — automatic fallback

So the breadcrumb still lands when the agent forgets. `install-hooks.sh` symlinks
`spells/hooks/post-commit` into every member repo's `.git/hooks/`. The hook fires on any
commit (git-level → agent-agnostic) and, **only if the session isn't already tagged**,
appends a provisional row using the commit's `~ organ` as the feature. Explicit
`end-session.sh` tags always win.

```bash
bash spells/install-hooks.sh    # once per machine, and after cloning a new member
```

Git hooks live in `.git/` and are not cloned — re-run after cloning. The end-of-session
ritual in every member's AGENT.md calls `end-session.sh`; the hook is the safety net.

---

## Spell Authoring Conventions

- Root: `GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`
- Parent: `RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"`
- Every spell must support `--help` / `-h`
- Headers: `# RaBbLE-Grimoire — {script-name}` + purpose line + Pulse Protocol commit tag
- Colors: use the MAGENTA/CYAN/GREEN/YELLOW/MUTED constants from `status.sh`
- Pulse Protocol commit: `spark ~ grimoire >> ...` for new spells

---

```
transcribe ~ grimoire >> spells documented // %SPELLS_CURRENT%
```
