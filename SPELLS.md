# RaBbLE Grimoire Spells

```
transcribe ~ grimoire >> the incantations that manifest realms // %SPELLS_CURRENT%
```

Spells are bash scripts in `spells/` that manage the RaBbLE Collective. Grimoire is the source; spells are the distribution mechanism. Run `bash spells/help.sh` for a quick reference.

**All spells run from Grimoire root:** `cd RaBbLE-Grimoire && bash spells/<name>.sh`
**Every spell supports `--help`** for usage, flags, and examples.

---

## Quick Reference

**Coordination & setup**

| Spell | Purpose | When to use |
|---|---|---|
| `help.sh` | List all spells with descriptions | Orienting — what's available |
| `status.sh` | Health dashboard: branch, git state, **episode alignment**, symlinks | Start of session — check member states & in-step status |
| `setup.sh` | Bootstrap: clone repos, wire symlinks | Fresh machine or new member added |
| `sync-symlinks.sh` | Create CLAUDE.md/CODEX.md/GEMINI.md → AGENT.md | After adding a repo or fixing broken links |
| `init-project.sh` | Scaffold a new Collective member + manifest | Creating a new repo |
| `install-hooks.sh` | Install the post-commit breadcrumb hook in all repos | Once per machine / after cloning a new member |

**Development**

| Spell | Purpose | When to use |
|---|---|---|
| `dev-serve.sh` | Launch local dev (Aether+NeBuLA+World on :8080) | Development — always use this, not manual servers |
| `visual-screenshot.sh` | Capture browser screenshot for agent visual review | Verifying UI changes — agent sees the PNG |
| `install-theme.sh` | Install RaBbLE theme on OS | RaBbLE-OS theming setup |

> sCoRE runs locally via its own `RaBbLE-sCoRE/spells/local-start.sh` (:8000) — a member
> spell, not a Grimoire spell. See the Development section below.

**Build, CDN & member deployment**

| Spell | Purpose | When to use |
|---|---|---|
| `cast-aether.sh` | Build + stage Aether CSS to World | After Aether CSS changes, before testing in World |
| `cast-cdn.sh` | Build all + deploy to joinrabble.world via wrangler | Production deploy |
| `publish-cdn.sh` | Build + publish Aether & NeBuLA to CDN subdomains (CF Pages, free tier) | Publishing versioned CDN bundles |
| `member-ctl.sh` | Unified member deploy control (setup/publish/status/monitor) | One entry point for Aether/NeBuLA/World/sCoRE deploys |
| `publish-rc.sh` | Create RC branch, build, tag, publish to CDN (automated) | Cutting a release candidate for a member |
| `deploy-member.sh` | Full member RC → CDN pipeline | Lower-level pipeline used by `member-ctl.sh` |
| `create-member-workflow.sh` | Generate + commit `.github/workflows/deploy.yml` | Wiring CI deploy for a member repo |
| `cloudflare-ctl.sh` | Unified Cloudflare control (R2, Workers, CDN, secrets) | Any Cloudflare infra operation |
| `setup-cloudflare-r2.sh` | One-time R2 + CDN setup (autonomous, no dashboard) | Initial Episode-1 CDN infrastructure |
| `render-ctl.sh` | Unified **sCoRE** Render control (env/deploy/status/logs via REST API) | sCoRE cloud deploy + key management |
| `railway-ctl.sh` | **Dormant** — single Railway spell (superseded by Render) | Only if Railway is re-adopted as backend |

**Docs, analytics & episode**

| Spell | Purpose | When to use |
|---|---|---|
| `grimoire-doctor.sh` | **Self-healing drift scan**: broken nav links, unindexed docs, stale gists, stale door | Every commit (pre-commit hook); before/after restructures |
| `distill-gists.sh` | Regenerate gist/ summaries via Claude CLI (validates output) | After major doc changes; when `grimoire-doctor` flags a stale gist |
| `graph-grimoire.sh` | Token-weighted doc graph; orphans/hubs/islands/heaviest; `--walk <doc>` low-token traversal | Auditing cross-links; planning a low-token reading path |
| `token-budget.sh` | Calculate token cost of onboarding paths | Auditing doc bloat, optimizing agent context |
| `session-tokens.sh` | Parse agent transcripts for token usage | Tracking token spend per session/project |
| `end-session.sh` | Record end-of-session feature breadcrumb (agent-agnostic) | Closing a session — tag its token spend |
| `distill-hypr-docs.sh` | Fetch + distill a Hyprland wiki page to a Grimoire note (LLM fast chain) | Capturing upstream Hyprland config knowledge |
| `seal-episode.sh` | Episode signing ceremony (DRAFT — needs Collective account) | Tagging an episode across the Collective |

**Multi-agent coordination & session logging**

| Spell | Purpose | When to use |
|---|---|---|
| `session-start.sh` | **Opening ritual** — pin session id, read lessons+blockers+who's-live, claim scope, start auto-heartbeat | **First thing every session** when another may be live |
| `agent-register.sh` | Claim file-scope globs so parallel agents don't stomp each other | Lower-level: claim/check/status/release (session-start wraps it) |
| `decision-log.sh` | Append structured decision/insight/stumble/scope entries (per-agent JSONL) | Recording why a choice was made, mid-session |
| `promote-insight.sh` | Crystallize logged insights/stumbles into durable Lessons | Read lessons at start (`ls`); promote at end (`auto`) |
| `blockers.sh` | Durable append-only blocker ledger → generates `log/BLOCKERS.md` | Any blocker — so it survives the SESSION-LOG `## LATEST` rewrite |

> Helper scripts (not run directly): `dev-cdn.js`, `playwright-capture.mjs` are invoked by
> `dev-serve.sh` / `visual-screenshot.sh`.

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

### Grimoire propagation — there is none (retired S105)

The old "copy `RaBbLE-Agent/` docs into member `grimoire/` dirs" model is **retired**.
The Grimoire holds all knowledge; **members reference it directly** rather than carrying
a copy. A member's `AGENT.md` / `CONTEXT.md` point at Grimoire entries (e.g.
`~/RaBbLE-Collective/RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md`) to establish working
state, and member documentation lives **in** the Grimoire under `RaBbLE-<Member>/`.
`sync-grimoire.sh` is now a stub that says exactly this. One source of truth — referenced,
never duplicated. See `RaBbLE-Agent/RaBbLE-DocTemplates.md`.

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
cd ~/RaBbLE-Collective/RaBbLE-sCoRE && bash spells/local-start.sh
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
cd ~/RaBbLE-Collective/RaBbLE-sCoRE && bash spells/local-start.sh
# Terminal 3 — World
cd ~/RaBbLE-Collective/RaBbLE-World && bash ../RaBbLE-Grimoire/spells/dev-serve.sh
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

### sCoRE cloud deploy — `render-ctl.sh` (current)

sCoRE's Episode-1 cloud target is **Render** (free tier). `render-ctl.sh` is the unified
control spell — env vars, deploys, status, and logs all run via the Render REST API
(no dashboard). It supersedes the old `deploy-render.sh` (removed S106; that one stubbed
`env-set`/`logs` to "use the dashboard"). Mirrors `railway-ctl.sh` in shape.

```bash
bash spells/render-ctl.sh preflight     # validate render.yaml (catches free-tier disk conflict)
bash spells/render-ctl.sh setup         # save API key, verify auth, link service by name
bash spells/render-ctl.sh env-sync      # push provider keys from sCoRE/server/.env → Render
bash spells/render-ctl.sh deploy --wait # trigger + poll to live
bash spells/render-ctl.sh status        # status, branch, URL, /health probe
bash spells/render-ctl.sh logs 200      # recent logs
```

One-time manual bootstrap only: mint a Render API key
(`https://dashboard.render.com/account/api-keys`) and create the service once via Blueprint
(connects GitHub, reads `render.yaml`). Everything after is CLI. Credentials live in the
gitignored `.render/`. (Resolves AUDITS gap #11.)

The Railway path is **dormant**: its three former spells were consolidated into the
single `railway-ctl.sh` (marked dormant in its header), retained intact in case Railway
is ever re-adopted as the backend provider. `deploy-railway.sh` and `deploy-score.sh`
were removed (S105).

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

### `distill-hypr-docs.sh` — Distill Hyprland Wiki Pages

Fetches a Hyprland wiki page and distills it to a Grimoire markdown note via the LLM fast chain (Groq). Falls back to the raw GitHub wiki source when the live wiki is unreachable.

```bash
bash spells/distill-hypr-docs.sh <page> [output-file]
bash spells/distill-hypr-docs.sh window-rules                 # → stdout (+ appends to Grimoire note)
bash spells/distill-hypr-docs.sh window-rules /tmp/wr.md      # → file
```

**Page slugs:** window-rules, dispatchers, variables, binds, animations, workspace-rules, keybinds, monitors, env — or any path appended as-is to the wiki base.

**Requires:** `curl`, `jq`, `GROQ_API_KEY` (or `RaBbLE-sCoRE/server/.env` with one). Optional: `pandoc` (HTML→text; falls back to `lynx`, then raw curl).

---

## Analytics

### `token-budget.sh` — Onboarding Token Cost

Calculates approximate token cost for each agent reading path defined in the Navigator. Answers: "how much does onboarding cost?"

```bash
bash spells/token-budget.sh                   # full per-file breakdown
bash spells/token-budget.sh --summary         # totals only
```

### `graph-grimoire.sh` — Token-Weighted Documentation Graph

Scans all `.md` files, extracts **both** markdown `[](links)` **and** backtick `` `path.md` `` nav refs (the Grimoire's nav docs cite docs in backticks), builds an adjacency graph. Every node and edge carries a `tokens` estimate (words × 1.33) — each edge is the **cost of reading the doc it points to**, so agents can plan a low-token reading walk. Reports orphans, hubs, islands, and the heaviest docs.

```bash
bash spells/graph-grimoire.sh                 # graph + summary (orphans/hubs/islands/heaviest)
bash spells/graph-grimoire.sh --json-only     # JSON only, skip Mermaid
bash spells/graph-grimoire.sh --walk AGENT.md # low-token traversal: neighbors by token cost, cheapest first
```

**Outputs:** `log/grimoire-graph.json` (nodes & edges with `tokens`), `log/grimoire-graph.md` (Mermaid; token cost in each label).

### `grimoire-doctor.sh` — Self-Healing Drift Scan

One command that catches the ways the Grimoire rots. Full protocol + forward plan: `RaBbLE-Agent/RaBbLE-Grimoire-SelfHealing.md`.

```bash
bash spells/grimoire-doctor.sh                # full report (always exit 0)
bash spells/grimoire-doctor.sh --strict       # exit 1 on any ERROR (hooks/CI)
bash spells/grimoire-doctor.sh --quiet        # problems + summary only
```

**Checks:** C1 broken links in nav docs · C2 docs not reachable from `INDEX.md` · C3 gists whose source is newer · C4 the Collective-root "door" falling behind `SESSION-LOG`. Wired into the **pre-commit hook** (warn-only) so drift surfaces the moment it's committed.

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

## Multi-Agent Coordination & Session Logging

**Required whenever another session may be live** (solo sessions may skip). Each spell writes one
file per agent (keyed by session id), so concurrent agents never produce git merge conflicts.
Session id resolves from `RABBLE_SESSION_ID`, then the active Claude transcript, then a git-commit
fallback — agent-agnostic, like `end-session.sh`. **Under concurrency, always `export
RABBLE_SESSION_ID` yourself** — the transcript auto-resolver picks the newest transcript for the
cwd, which is a coin-flip between two live sessions.

### `session-start.sh` — Opening Ritual (run this first)

The front line of anti-clobber: clobbering happens *during editing*, so coordinate at the **start**,
not at commit. One call: surfaces durable lessons + open blockers + who else is live, claims your
file-scope (loud conflict + non-zero exit on overlap), and starts a **self-terminating background
heartbeat** so your claim doesn't die mid-session (the maintenance burden that previously made the
system go unused). The heartbeat stops within one cycle of `agent-register.sh release`.

```bash
export RABBLE_SESSION_ID="S<NN>-<topic>"                    # FIRST — pin a stable id
bash spells/session-start.sh "<glob>"... --task "desc"     # context + claim + auto-heartbeat
bash spells/session-start.sh                               # context-only (no scope = no claim)
bash spells/session-start.sh "<glob>" --no-heartbeat       # claim but don't spawn the daemon
# Env: HEARTBEAT_INTERVAL (default 240s, under the 300s stale threshold)
```

> Pairs with the End-of-session ritual (`blockers.sh`, `end-session.sh`, `promote-insight.sh auto`,
> `agent-register.sh release`). The pre-commit auto-register (`log/HANDOFF-PreCommit-AntiClobber.md`,
> not yet built) is only a *backstop* for when this ritual is skipped.

### `agent-register.sh` — Parallel Agent Scope Coordination

Agents claim file-scope globs before working. Overlapping claims from a live agent produce
a loud warning and a non-zero exit, so parallel agents never silently stomp each other.
Claims live in `log/agents/<session-id>.json` (one file per agent); heartbeats mark agents
stale after 5 min and dead after 15 min (slot auto-released).

```bash
bash spells/agent-register.sh claim "<glob>"... --task "desc" [--agent kind]  # claim scope
bash spells/agent-register.sh heartbeat                                       # keep claim alive
bash spells/agent-register.sh check <path>                                    # is this path claimed?
bash spells/agent-register.sh status                                          # all live agents + claims
bash spells/agent-register.sh release                                         # free this agent's slot
```

### `decision-log.sh` — Structured Decision / Insight Stream

Appends JSONL lines to `log/decisions/<session-id>.jsonl` — a machine-friendly parallel
stream that feeds `promote-insight.sh`. Human-curated `DECISIONS.md` / `AUDITS.md` are left
untouched.

```bash
bash spells/decision-log.sh log <type> <message...>   # type: decision|insight|stumble|scope
bash spells/decision-log.sh show [session-id]         # full log for a session
bash spells/decision-log.sh tail [session-id]         # last 10 entries
bash spells/decision-log.sh list                      # all sessions with logs
```

**Types:** `decision` (choice made) · `insight` (something future agents should know) ·
`stumble` (mistake / failed approach — most valuable for learning) · `scope` (what this
agent is / isn't doing).

### `promote-insight.sh` — Crystallize Stumbles into Lessons

Scans `log/decisions/*.jsonl` for `insight` and `stumble` entries and writes durable Lessons
to `log/lessons/<slug>.md`, so future agents benefit automatically. Read lessons at session
start; promote your own at session end.

```bash
bash spells/promote-insight.sh ls                          # list all durable lessons
bash spells/promote-insight.sh list [session-id]           # promotable entries for a session
bash spells/promote-insight.sh promote <session-id> [idx...] # promote selected entries
bash spells/promote-insight.sh auto [session-id]           # promote all from a session
bash spells/promote-insight.sh show <lesson-slug>          # read one lesson
```

> Note: `ls` lists existing Lessons; `list` lists the not-yet-promoted entries in a session's
> decision log. Lesson frontmatter carries title, date, agent, session, tags, and source.

### `blockers.sh` — Durable Blocker Ledger

Blockers used to live ONLY in the 75-word `## LATEST` box of `SESSION-LOG.md`, which is
rewritten every session — so open/resolved state got **clobbered** and lost between sessions.
`blockers.sh` is the durable home: an append-only event stream (`log/blockers/blockers.jsonl`,
events `open`/`resolve`) that **generates** `log/BLOCKERS.md`. The LATEST box now only *points*
to it. `status.sh` surfaces the open count; `EP1-AIR-CHECKLIST.md` references `tag:ep1-gate` ids.

```bash
bash spells/blockers.sh add "<summary>" --owner Mark --tag ep1-gate [--since SNNN]  # open (prints B-NN)
bash spells/blockers.sh resolve B-NN "<how it cleared>"                             # close
bash spells/blockers.sh ls [--all]                                                 # OPEN (--all adds RESOLVED)
bash spells/blockers.sh sync                                                        # regenerate log/BLOCKERS.md
bash spells/blockers.sh open-count [--tag ep1-gate]                                 # bare integer (status.sh)
```

> Source of truth is the JSONL (conflict-friendly across parallel sessions, like `decision-log.sh`).
> Never hand-edit `log/BLOCKERS.md` — it's regenerated. Same agent-agnostic session-id resolution.

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
