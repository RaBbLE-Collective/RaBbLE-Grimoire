# RaBbLE-Agent-Protocols.md — Behavioral Rules for Agents

```
transcribe ~ grimoire >> agent protocols distilled from session memory // %PROTOCOLS_LIVE%
```

> Hard-won rules from sessions with this codebase. Each rule has caused at least one debugging session when broken. Read before touching anything.
>
> Source: distilled from `.claude` session memory across Sessions 13–24.
>
> **See also:** [RaBbLE-Dependency-Policy](RaBbLE-Dependency-Policy.md) — license governance for external dependencies (Tier 1–4 classification, adapter pattern, NOTICES.md convention). Read before adding any library, tool, or external API.

---

## Session Resilience

### Front-load external and manual blockers

At the start of any task that touches deployment, boot chain, or live system config: identify every external or manual step required to close the loop, and name it explicitly before starting implementation. Don't discover these at the end.

**Why:** Many sessions reached "done" with final verification blocked — Render branch switch hadn't been made, reboot hadn't happened, relog was needed to flush Qt cache. These were discoverable at the start but only surfaced at the end, leaving work marked `[~]` instead of verified.

**How:** Before beginning: list every manual or external action the task requires (deploy branch switch, reboot, relog, provider credential rotation, manual dashboard step). Surface these to Mark up front so they can happen in parallel or the task can be scoped to what's verifiable in-session. Flag OS theme changes that require relog/reboot as `[~] pending reboot verification` rather than claiming success.

### Commit incrementally — don't batch at session end

During long sessions (especially Ansible/provisioning work or multi-repo integration), commit each logical unit of work as it completes rather than batching all commits at the end.

**Why:** Provider 429/400 errors (rate limits, tokenizer failures) have blocked final commits multiple times — completed, correct work was lost because it hadn't been committed when the session was interrupted. The longer the uncommitted window, the more is at risk.

**How:** Commit after each meaningful self-contained change (per-role fix, per-member file change, per-concept doc update). On a provider error mid-session: immediately write current progress and a resume checklist to `RaBbLE-BaBbLE/` before stopping, so the next session picks up without re-deriving context.

---

## RaBbLE-OS / Ansible Conventions

### Verify Fedora package names before landing in YAML

Before adding a package to an Ansible role or `ansible/packages/manifest.yml`, verify the package name exists in current Fedora repos. Wrong names silently produce a failed task with no useful output — the playbook looks like it worked.

**Why:** `shaderc` was used instead of `glslc` (the correct Fedora package name); the build failed mid-run and required a second correction round. Fedora package names frequently differ from upstream tool names or Ubuntu equivalents.

**How:** Run `dnf search <name>` or check `packages.fedoraproject.org` before committing. Common gotchas: `glslc` (not `shaderc`), `python3-pip` (not `pip3`), `nodejs` version availability (may need nodesource). When uncertain, add a `dnf search` verification step inside the Ansible task debug line.

### `import_tasks` vs `include_tasks` — know the difference

In Ansible roles, `import_tasks` is static (parsed at playbook load time) and `include_tasks` is dynamic (evaluated at runtime). Mixing them incorrectly causes either silent skips or undefined variable errors that only surface during live runs.

**Why:** Multiple Ansible sessions hit avoidable failures because `include_tasks` was used where `import_tasks` was needed (or vice versa), only caught after a live `ansible-playbook` run.

**How:** Use `import_tasks` when the task file path is static and known at parse time (most roles). Use `include_tasks` only when looping or when the task file name depends on a runtime variable. When in doubt, `import_tasks` is the safer default.

---

## Doc Management

### Document and transcript fidelity — never over-summarize source material

When integrating interviews, transcripts, intake docs, or any raw source material into the Grimoire or BaBbLE: preserve the full content verbatim unless explicitly instructed to distill. Never silently reduce, summarize, or omit — do that only when Mark asks for it.

**Why:** Interview transcripts were over-summarized during intake, losing raw content that Mark wanted faithfully captured. Recovering the original required redoing the work from audio. The general principle: Grimoire integration = move to canonical home with full fidelity; distillation = a separate explicit step only when requested.

**How:** Two-phase approach: (1) integrate raw → archive original, copy to BaBbLE/Grimoire verbatim; (2) only then, if asked, produce a distilled/summary version alongside the raw. Never replace the raw.

### Condense, never delete

When asked to clean docs, logs, or audit files: (1) identify the canonical home for each piece of useful content, (2) merge content there, (3) reduce the original to a ~10-line pointer file that says "content moved to X." Do not `rm` or `git rm` without condensing first.

**Why:** Deletion loses context even when content seems redundant. Condensation moves value to permanent homes while keeping the artifact readable as a pointer.

---

## Repo Management

### No worktrees in member repos

Never set up or suggest git worktrees inside member repos. Use branches for isolation.

**Why:** Extra files and duplicate directories clutter the repo. User preference: "I don't like how worktrees create a lot of additional files and new identical directories in a repo."

### Collective root naming

Refer to the top-level workspace as "the Collective root" or "RaBbLE-Collective" — not by a filesystem path. Paths are machine-specific; Collective-relative naming is canonical.

### Grimoire has no self-manifest

The Grimoire does not need a `_template.manifest.yml` entry for itself. It is ensured to exist via `bootstrap.sh` / `setup.sh`. Don't create one.

---

## Tooling & Automation

### Sub-agents must run in foreground — never background

When dispatching a sub-agent that needs to write files, run bash commands, or read the filesystem, dispatch it as a **foreground** agent. Background sub-agents have `Write`/`Bash`/`Edit` auto-denied — they cannot surface permission prompts to the user, so every tool call they need silently fails.

**Why:** The Claude Code permission model only surfaces prompts to the interactive session. Background processes have no channel to the user, so tool use requiring confirmation is blocked rather than queued. Hit S116: background agents dispatched to handle theme/OS changes completed with zero actual work done.

**How:** Dispatch without `run_in_background: true` for any sub-agent that edits files or runs shell commands. For genuine parallel execution, dispatch multiple foreground agents in the same response (they run concurrently). Background agents are fine for pure read-only research with no write/bash calls.

### Sub-agent fleets must pin a cheap model — never inherit the orchestrator's

When fanning out multiple sub-agents for recon, search, or mechanical work, set an explicit cheap model (e.g. `model: "sonnet"`, or haiku for trivial passes) on every dispatch. Sub-agents inherit the parent model when no override is given.

**Why:** A Fable/Opus orchestrator's fan-out multiplies the most expensive model by the widest workload. Hit S193: 8 full-repo-read audit agents inherited fable-5 and burned through two session limits before Mark caught it mid-run. The orchestrator's model is for orchestration and synthesis; the fleet does the volume work.

**How:** Every `Agent` dispatch in a fan-out carries an explicit model override. Reserve the parent model for the synthesis pass the orchestrator does itself.

### Coordination-spell invocation gotchas (claims + ledger)

Three sharp edges in the anti-clobber/closeout spells, found S190. Until they are mended, invoke defensively:

1. **`session-start.sh` scopes must be separate `Repo:path` arguments.** One space-joined quoted string ("RaBbLE-World/index.html RaBbLE-World/world/js/x.js") makes the conflict check silently pass without comparing anything — the claim *looks* clean but was never checked. Correct: `session-start.sh "RaBbLE-World:index.html" "RaBbLE-World:world/js/x.js" --task "…"`.
2. **Auto sweep claims (`"auto": true` registry entries) produce false conflicts.** They sweep ALL dirty working-tree files into a session's scope, including files that session never edited. A conflict against an auto claim is not proof of contention — check `git status` on the target repo (clean tree = nobody mid-edit) and who actually committed to those files before treating it as real. Manual `S<NN>-<topic>` claims are the trustworthy signal.
3. **`end-session.sh` can clobber a token-ledger row.** On a session-id collision it re-tags an existing breadcrumb instead of appending (S190's run overwrote the S188 `doc-closeout-audit` row). After running it, check `git diff log/token-ledger.tsv` and restore any removed `-` row before committing. Recurred S193, worse: with no `RABBLE_SESSION_ID` in the environment it attributed the breadcrumb to a *different* session's uuid and dropped two other sessions' rows.
4. **`RABBLE_SESSION_ID` must be exported in the SAME shell invocation as the spell.** Agent-harness shells do not persist env between tool calls. S193: `agent-register.sh release` without the id inline reported success while leaving the real claim and heartbeat alive. Always `export RABBLE_SESSION_ID="S<NN>-<topic>" && bash spells/<spell>.sh …` as one command — for session-start, end-session, and release alike.

**Why:** All three fail *silently* — a skipped check, a false alarm, and a lost row each look like success. Two of them (1, 3) defeat the exact protections the spells exist to provide.

**How:** Follow the invocation forms above; verify claim results and ledger diffs rather than trusting spell exit status. A registry mend session is queued (SESSION-LOG S190-continued) — update this section when the spells are fixed.

### Validate external CLIs and APIs before building around them

Before scaffolding any integration, quota tracker, or workflow around an external CLI tool or API, verify the tool still exists and the specific flags/commands you need are current.

**Why:** A complete Gemini CLI quota-tracking integration was built and committed, then required a full revert when a web search revealed the CLI had been deprecated. The wasted session could have been avoided with a 2-minute pre-check.

**How:** Before writing the first line of integration code: confirm the tool is still maintained, the specific flags/subcommands you'll use still exist, and the auth model matches. Applies equally to fast-moving AI tooling (NPU drivers, LLM runtimes, provider CLIs) where deprecation is common.

### Agent-agnostic mechanisms only

All Collective automation and session rituals must work for every agent — Claude Code, Codex, Gemini CLI, and any future one. Do not build automation on agent-specific mechanisms. Specifically: Claude Code's `settings.json` hooks (`Stop`, `SessionEnd`, etc.) only fire for Claude, so they are **not** an acceptable home for shared rituals.

**Why:** The Collective is explicitly LLM-agnostic — `AGENT.md` is the canonical owner, and `CLAUDE.md` / `CODEX.md` / `GEMINI.md` are gitignored symlinks to it. Anything that lives only in `.claude/` silently locks the workflow to one agent and breaks the moment another agent does the work.

**How:** Prefer pure-bash spells (any agent can `bash` them) and git-level hooks (fire for any agent that commits) over agent-specific config. Example: the end-of-session token breadcrumb uses `spells/end-session.sh` plus a `spells/hooks/post-commit` git hook — not a settings.json hook.

### pkill -f self-match kills the agent's own shell

Agent harnesses (Claude Code, Codex) run shell commands wrapped in a `sh -c '<entire command text>'` process — so the wrapper's own cmdline contains everything the agent typed. A `pkill -f <pattern>` whose plain pattern string appears **anywhere** in the same compound command (a restart line, a heredoc body, an echo) matches the wrapper itself and kills the agent's shell mid-command (exit 144, output lost). Bracket tricks (`[s]core`) only protect the pattern argument, not other plain mentions in the same command.

**Why:** The wrapper's argv *is* the command text; pgrep/pkill `-f` matches against full cmdlines.

**How:** Split kill and start into separate tool calls; in the kill call, ensure the pattern appears nowhere in plain form (e.g. `pkill -f 'status-daemon[.]sh'` with no other mention of the daemon name). A killed wrapper's already-forked children may still complete — verify actual process state afterwards instead of assuming the command failed.

### `find -newermt` silently fails on this machine — use `-mmin` instead

`bfs` (Better Find) is the system `find` on RaBbLE-OS, not GNU find. It does **not** support relative date strings like `find -newermt '-24 hours'`. The error goes to stderr — silently swallowed by `2>/dev/null` — and the command returns zero results with no warning. This looks like "no files found" and produces incorrect behavior (stale cache reads, empty counts, missed quota errors).

**Why:** bfs enforces stricter ISO 8601-like timestamp formats for `-newermt`; relative strings ("24 hours ago") are a GNU find extension.

**How:** Use `-mmin -N` instead of `-newermt`:
- `-newermt '-24 hours'` → `-mmin -1440`
- `-newermt '-7 days'` → `-mmin -10080`
- Very short windows (`-newermt '-8 seconds'`) have no clean `-mmin` equivalent — `-mmin -1` is the closest (60s). These short-window checks are secondary heuristic fallbacks; leaving them broken is acceptable since hook-based primary state is authoritative.

### RaBbLE-Xperimental is now RaBbLE-Chrysalis — know the difference

As of S92, the repo formerly called `RaBbLE-Xperimental` was renamed:

| Name | What it is | Location | Use |
|---|---|---|---|
| **RaBbLE-Chrysalis** | Genesis archive — primordial soup, origin code | `~/RaBbLE-Collective/RaBbLE-Chrysalis/` | Mine for lore. Do not develop. |
| **RaBbLE-Xperimental** (new) | Active sandbox — rablets, prototypes, experiments | `~/RaBbLE-Collective/RaBbLE-Xperimental/` | Active dev, high entropy |

If you navigate to `RaBbLE-Chrysalis` expecting the development sandbox, you are in the wrong place. The new Xperimental is where active experimental work goes. GitHub rename of `markm1206/RaBbLE-Xperimental → RaBbLE-Chrysalis` may be pending — check the manifest if the remote URL is ambiguous.

---

### Never use /tmp for RaBbLE work — use BaBbLE/tmp/ and Xperimental

Do not write RaBbLE work products, planning docs, research notes, or scratch files to `/tmp`. The directory does not survive reboots. Session work vanishes.

**For agent scratch work (temp scripts, debug outputs, intermediate files):** use `RaBbLE-BaBbLE/tmp/`. It is gitignored (nuke-safe), persists across reboots, and can be reviewed by Mark. At session end, move keepers to `intake/` or `signals/`, or run `rm -rf tmp/* && git checkout -- tmp/.gitkeep`.

**BaBbLE zone map (S170+):**

| Content type | Goes to |
|---|---|
| Agent temp scripts, debug outputs, intermediate files | `RaBbLE-BaBbLE/tmp/` — gitignored, nuke-safe |
| Raw ideas, docs, files with no home yet | `RaBbLE-BaBbLE/intake/` |
| Named ideas with a clear routing destination | `RaBbLE-BaBbLE/signals/` |
| Screenshots and visual evidence | `RaBbLE-BaBbLE/captures/` + `captures/_inbox/` for raw dumps |
| Prototype code, experimental scripts, sandboxed rablets | `RaBbLE-Xperimental/` |
| Canonical specs, architecture, design docs | `RaBbLE-Grimoire/` |

**Note (S170):** `assets/` in BaBbLE was renamed `reliquary/concept-art/`. Any reference to `BaBbLE/assets/GRAPH.md` is now `BaBbLE/reliquary/concept-art/GRAPH.md`.

**Why:** Mark has rebooted multiple times during RaBbLE-OS development (S88–S92), clearing /tmp repeatedly. Any session work that landed in /tmp is gone. BaBbLE/tmp/ and Xperimental are persistent and survive reboots.

---

### Concurrent sessions share the git index — stage and commit atomically

Mark often runs multiple agent sessions against the same member repo. `git add` followed later by `git commit` is not safe: another session's `git commit` in between sweeps **your** staged files into **its** commit (happened S87/S88 — a 114-file apps/theming commit silently absorbed the entire staged boot chain).

**Why:** The index is repo-global shared state, not per-session. Whoever commits next takes everything staged.

**How:** Stage and commit in a single tool call (`git add <paths> && git commit -m …`). Check `git log -1` immediately before committing — if HEAD moved since your last look, inspect before proceeding. If a foreign commit absorbed your files and is unpushed: `git reset --soft HEAD~1`, re-stage each session's hunks separately (`git apply --cached [-R] <filtered diff>`), recommit theirs with `git commit -C <old-hash>`, then yours; verify with `git diff <old-hash> HEAD` (must be empty).

---

## Grimoire as Documentation Home

All architecture, API, usage, and design docs live in the Grimoire. Member repos contain only source code, tests, build config, and an AGENT.md that points to Grimoire docs.

**Workflow when building:**
1. **Design/document first in Grimoire** — API spec, usage examples, integration patterns, CONTEXT.md progress updates
2. **Implement in member repo** — code follows the Grimoire spec; member AGENT.md points back
3. **Update Grimoire as you learn** — if the spec was wrong, fix it; document edge cases; record trade-offs

**Why:** Members evolve. Docs must stay in one place or they rot. The Collective enforces this: "Members reference Grimoire; never duplicate Grimoire content in members."

---

## Member Responsibility Split

Before writing any visual or styled element in World, apply this split:

| Member | Owns |
|---|---|
| **NeBuLA** | All visual effects and animated rendering — SVG factories, canvas, particle systems. Export under `window.NeBuLA.ui.*` |
| **Aether** | CSS, design tokens, look and feel. Shared component styles. Never hex values in member pages — use Aether tokens |
| **World** | Thin scaffold only — state machines, data, DOM assembly, mounting. No rendering logic of its own |

**Test:** "Is this an effect?" → NeBuLA factory. "Is this a reusable style?" → Aether eventually. "Is this assembly?" → World.

**Why:** Mixing rendering into World or styles into NeBuLA creates coupling that makes members harder to evolve independently.

**This split is collective-wide, not World-specific.** Aether + NeBuLA are the frontend framework for *every* RaBbLE web application — sCoRE's web UI, BaBbLE, OS web surfaces, any future member surface — not just World's CSS/effects layer. Any RaBbLE web project needing a new component adds it to Aether (styling) or NeBuLA (behavior/rendering) as a real, reusable, documented component; it never hand-rolls a one-off in the consuming project. Tooling should enforce this as friction, not paper over it with an escape hatch.

---

## World Tech Constraints

### Vanilla JS only — no React, no Babel

World uses no bundler, no build step, no frameworks beyond Alpine.js (already loaded for declarative UI). When a component needs adding, write it in vanilla JS.

**Why:** Babel-standalone in-browser transpilation was considered and rejected. World's architecture is deliberately minimal.

**How:** If a design prototype is written in JSX (e.g. from BaBbLE or grimoire-variants.jsx), convert it to vanilla JS before landing it in World. The established idiom is the NeBuLA.ui factory pattern:

```js
// Factory returns { el, ...controls, destroy() }
function createMyComponent(opts) {
  const el = document.createElement('div');
  // ...
  return { el, destroy() { el.remove(); } };
}
```

### NeBuLA effects mounts rewrite their host's position — wrap them (S203)

`NeBuLA.effects.starfield(host)` / `haze(host)` set the host element's `position` **inline**, overriding any stylesheet `position: fixed`. The host silently becomes an in-flow element. Inside a CSS-grid `body` this is fatal: the mount hosts become grid items, eat the explicit rows (one can swallow the `1fr` track), and shove the page's real header/main/footer into implicit rows at the bottom.

**How:** never make an effects host a direct child of a grid/flex page skeleton. Put mount hosts inside a dedicated wrapper the effects never touch (`position: fixed; inset: 0; pointer-events: none`), hosts as `position: absolute; inset: 0; width/height: 100%` children. Give the skeleton's real children explicit `grid-row` assignments as a backstop. Diagnose with a computed-style probe (body `grid-template-rows` showing extra tracks = this bug), not by staring at screenshots.

Root cause fixed in NeBuLA later the same session (382d23b): mounts now only set `position` when the host is static, and effect canvases get explicit `width/height:100%` — a canvas is a replaced element, so `inset:0` alone leaves it at its intrinsic dpr-scaled attribute size, which made all pointer-anchored drawing (constellation web) land ~25% past the real cursor on HiDPI while passing every dpr-1 headless test. Keep the wrapper pattern anyway as defense-in-depth against stale bundles, and test canvas geometry at `device_scale_factor=2`, not just dpr 1.

---

## NeBuLA Build Workflow

### Always build and copy before testing or committing

After **any** change to `RaBbLE-NeBuLA/src/`:

```bash
npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js
```

Do this **before** asking the user to test, and **before** committing World.

**Why:** The World page loads an inlined IIFE bundle directly — `world/js/RaBbLE-NeBuLA.js`. Editing `src/backends/canvas2d-backend.js` or any other source file is invisible until the bundle is rebuilt and copied. This caused a full triage session where fixes appeared to fail because an old bundle was still running.

---

## Dev Environment

### Use dev-serve.sh — never run sub-processes directly

Always start the dev environment with:

```bash
bash RaBbLE-Grimoire/spells/dev-serve.sh
```

**Never run** `node RaBbLE-Grimoire/spells/dev-cdn.js` or `npx esbuild ... --watch` directly.

**Why:** Running the server or watchers manually orphans processes on port 8000. When the user later runs `dev-serve.sh`, it fails with `EADDRINUSE`. This caused a multi-session debugging nightmare where Aether CSS appeared to load (curl returned 200 from the orphaned server) but wasn't actually serving fresh content.

### Aether file names in dev vs prod

| Context | File | Built by |
|---|---|---|
| Dev | `dist/aether.css` | `build:watch` or `build:dev` |
| Production | `dist/aether.min.css` | `build:min` / `build` |

HTML pages link to `aether.css` in dev — **NOT** `aether.min.css`. Linking to the min file means the watcher never updates what the browser loads — a silent failure.

---

## Visual Capture Workflow

All visual documentation (screenshots, UI captures, design iteration snapshots) uses the unified `visual-screenshot.sh` spell and `RaBbLE-Captures` organization system.

**Spell:** `RaBbLE-Grimoire/spells/visual-screenshot.sh`  
**System doc:** `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Captures-System.md`

### When to capture: Two methods, one choice

| Scenario | Method | Command |
|---|---|---|
| Browser/web page (recommended) | Playwright headless | `bash spells/visual-screenshot.sh --playwright` |
| Full-screen/OS/multi-window work | Hyprland + Firefox | `bash spells/visual-screenshot.sh` |

**Playwright (default for agents):**
- Headless Chromium, no Hyprland required
- Works anywhere — CI, remote machines, non-RaBbLE-OS
- Faster, doesn't interrupt workflow
- Requires: Node.js + `npx`

**Hyprland (RaBbLE-OS only):**
- Opens real Firefox in workspace 9 (scratch)
- Captures full monitor with `grim`
- Automatically closes Firefox and returns to original workspace
- Requires: active Hyprland session, Firefox, `grim`, `hyprctl`

### Capture workflow

1. **Run spell with appropriate method:**
   ```bash
   # Browser pages (most common)
   bash RaBbLE-Grimoire/spells/visual-screenshot.sh \
     --url http://localhost:8000/world/Chat.html \
     --playwright

   # Full-screen/OS work (Hyprland only)
   bash RaBbLE-Grimoire/spells/visual-screenshot.sh --delay 3
   ```

2. **Spell outputs machine-readable path:**
   ```
   SCREENSHOT: /home/rabble/RaBbLE-Collective/RaBbLE-BaBbLE/captures/visual-20260610-143022.png
   ```

3. **Move to appropriate category and rename:**
   ```bash
   mv RaBbLE-BaBbLE/captures/visual-20260610-143022.png \
      RaBbLE-BaBbLE/captures/World/Pages/chat/world-chat-new-feature_20260610.png
   ```

### Naming convention

```
{member}-{component}-{state}_{YYYYMMDD}.png
```

Examples:
- `world-chat-page_20260609.png` — Finished page
- `world-liminal-glitch-effect_20260609.png` — Visual state/effect
- `entity-boot-screen_20260608.png` — Component state
- `design-iteration-20260609-01.png` — Dev progress (sequential per date)

**Full reference:** `RaBbLE-Captures-System.md` § Naming Convention

### Where captures live

```
RaBbLE-BaBbLE/captures/
├── _inbox/                         # raw spell output — triage same session (<20 files)
├── World/Pages/{landing,chat,docs,os}/
├── World/States/liminal/
├── World/_reliquary/               # sealed RC/phase progressions
├── Entity-UI/{Boot,Components,Portal}/
├── NeBuLA/
├── Grimoire/
├── Aether/
├── Collective-Atmosphere/
├── Boot/vm-sessions/               # VM boot iteration sessions (vm-YYYYMMDD-HHMMSS/)
├── Boot/_reliquary/                # sealed S### boot debug sessions
├── OS-IDE/{Firefox,SDDM,Dolphin,Terminal,VSCodium/}  # OS + IDE theming
└── Design-Iterations/{by-date/,fastfetch/,login/}
```

Sealed iteration sets go into `_reliquary/` inside the relevant topic folder — not BaBbLE's top-level `reliquary/`. Each `_reliquary/` subfolder gets a one-paragraph `README.md`.

**Full reference:** `RaBbLE-Captures-System.md` for routing rules, naming convention, and triage discipline.

**Why:** Captures are `.gitignore`d but organized — enables visual discovery across the Collective and session progress tracking.

---

## Visual Planning Workflow

### The local agent-native plan server is ARCHIVED (S157) — plans are Grimoire markdown

RaBbLE previously ran its own local agent-native plan server (`rabble-plans` systemd unit, nginx proxy on :3000, MCP endpoint) as a self-hosted alternative to `plan.agent-native.com`. It was built (S155), hit three Ansible bugs, never fully ran, and was archived at S157. **Do not try to bring it up or route `/visual-plan` through it** — `systemctl --user status rabble-plans` currently reports `bad-setting`/`inactive`, and no MCP registration exists in `~/.claude/claude_code_config.json`. The Ansible role (`RaBbLE-OS/ansible/roles/apps/plans/`) is kept only as reference; its `site.yml` play is disabled (`hosts: plans_server_disabled`).

The visual render surface for plans is now RaBbLE's own problem to solve, targeted at EP2 NeBuLA/World — see `RaBbLE-Collective/RaBbLE-Plan-Surface.md`. Until that lands, plans are **plain markdown in the Grimoire**, per the plan-handoff convention below — not MDX exported from a plan server.

### Write plans as durable Grimoire docs, not ephemeral session files

Mark often implements large or multi-wave work in a **separate, fresh session** — sometimes on a cheaper model tier (an Opus session plans, a Sonnet session implements) — specifically to save tokens. That means a plan must outlive the session that wrote it: write it, plus a complete cold-start handoff, into the **Grimoire** as a durable doc, indexed in `INDEX.md` — never leave it only in an ephemeral `~/.claude/plans/*` file. Don't proceed to implement after planning unless told to.

**Why:** the implementing session starts cold. It needs repo/branch state, what's reusable, exact file paths, dev/test recipes, and gotchas — not just a feature list. Keeping expensive planning and cheap execution on separate model tiers only works if the handoff is self-contained.

**Where:** member-build handoffs go in `RaBbLE-Grimoire/RaBbLE-<Member>/…-Plan.md`. Cross-cutting or member-specific-but-not-a-full-build plans instead go in `RaBbLE-Grimoire/log/plans/<Prefix>-<Topic>.md` (e.g. `OS-ProArt-Power-Stack-Plan.md`), indexed in `log/plans/CONTEXT.md`'s Active plans table. Match whichever convention the target doc-home already uses — check its own index first.

**What to include:** mission, locked decisions, orchestration (waves + a shared contract + a **disjoint file-ownership table** so parallel sub-agents don't collide + which steps route to Haiku vs Sonnet), and a cold-start handoff section (git state, reusable modules, palette/tokens, dev-serve + capture recipe, voice constraints). Mark trusts the orchestration decomposition to the agent ("you know best").

**Before finalizing a large/architectural plan:** spawn a read-only Opus review agent (Agent tool, `model: opus`, explicitly told not to edit/write/run mutating commands) to check the plan against the actual source files it references, not just internal consistency. This has caught package gaps that would silently no-op a whole phase, wrong assumptions about how two subsystems couple, and mischaracterizing already-existing vs. still-to-build wiring — all things a same-session self-review missed. Fold corrections into the Grimoire doc before presenting as final.

### Never mutate a shared file to isolate a commit from a concurrent session

If a concurrent session has added lines to a shared file (`INDEX.md`, `SESSION-LOG.md`, `token-ledger.tsv`) that aren't relevant to your own commit, do **not** `Edit` those lines back out to "clean" your commit — that IS a clobber, the exact failure the anti-clobber ritual above exists to prevent, just done at commit-time instead of edit-time. If they haven't committed yet, deleting their in-progress additions destroys real work.

**How to apply:** to keep a commit scoped during concurrency, either (a) leave the shared file entirely out of your staging and let whichever session commits last carry it, or (b) commit it whole — their lines plus yours; a dangling markdown link to their not-yet-committed file is harmless. Excluding-by-not-staging is fine; deleting-then-restoring is not.

---

## RaBbLE-OS Config Workflow

### Repo → System, never the reverse

All config changes for RaBbLE-OS go through the repo first, then deploy via `dotctl`. Never edit `~/.config/` or any live system file directly.

```
Edit:    RaBbLE-OS/config/hypr/conf.d/windowrules.conf   (or any bundle)
Deploy:  ./RaBbLE-OS-dotctl.sh apply hypr
Reload:  ./RaBbLE-OS-dotctl.sh reload hypr
```

If you catch yourself about to edit a live file, stop — edit the repo source instead.

If a file has already drifted (direct edit happened), use `dotctl diff hypr` to inspect, then `dotctl pull hypr` to recover it into the repo before committing.

**Why:** Direct edits create drift that gets overwritten silently on the next `apply`. The repo is the source of truth; the system is a deployed copy.

**Applies to:** All dotctl bundles — `hypr` · `waybar` · `quickshell` · `kitty` · `fuzzel` · `zsh` · `bash` · `mako` · `wallpapers` · `claude`. Same principle applies to Ansible-managed system config: change the playbook, not the system file.

### Packages go through the manifest + role, not a live `sudo dnf install`

Same "repo → system, never the reverse" principle applies to packages, not just config files. When a task needs a new package on RaBbLE-OS, edit `ansible/packages/manifest.yml` (documentation + KS source) **and** the owning role's `vars/main.yml`/`tasks/` (the actual install path — these two are not auto-synced, keep them in step manually), then let the human run `layerctl apply <layer> --packages` themselves. Don't reach for a live `sudo dnf install` on their machine as a shortcut, even if they say "install it now" — that preference can flip mid-task once they realize Ansible already covers it.

**Why:** S206 — Mark first answered "install swappy now" to a direct question, then moments later said "since all of this is doable with layerctl I'll hold off on manual dnf and let ansible handle all installs," overriding his own earlier answer. Manifest-first keeps every install reproducible from a fresh Kickstart, which a live `dnf install` silently breaks.

**How:** Add the package to both places, verify with `ansible-playbook site.yml --syntax-check --tags <layer>`, and hand the exact `layerctl apply <layer> --packages` command back to the human instead of running `sudo dnf` yourself.

### fastfetch colors are raw SGR params — bare indexes silently fail

In `RaBbLE-OS/config/fastfetch/config.jsonc`, every color value (`keyColor`, `display.color.*`, title colors, `percent.color.*`) is passed through as a raw SGR parameter, not a 256-color index. `"135"` emits `\e[135m` — an undefined code terminals silently ignore, so the text renders default white-bold and *looks* deliberately styled. The 256-color form is `"38;5;135"`.

**Why:** The original config used bare `"57"`, later `"135"` — the keys were never actually colored, and nobody noticed for weeks because bold masked the failure (found S75).

**How:** Always write `38;5;N` (palette: 197 magenta · 51 cyan · 135 violet · 205 pink · 60 muted). Verify with `fastfetch --logo none --pipe false | cat -v` and confirm `[38;5;` appears in the output. Logo trailing whitespace counts toward logo width and pushes the info column right — keep art lines stripped.

### VSCodium theme changes need a hard restart — Reload Window lies

After `dotctl apply vscodium-theme`, VSCodium keeps serving the cached theme. **Reload Window does not bust the cache** — the IDE will happily render stale colors while the file on disk is correct, so an agent reading the JSON back "verifies" a fix that isn't live. Quit fully (`pkill -x codium` — `-x`, never `-f`; see pkill self-match above) and relaunch, then verify with a screenshot, not file contents.

**Why:** In S77 an agent concluded theme fixes were working from file contents alone; S78 confirmed the cache had been masking the live state the whole time. Screenshot first, conclude second.

**How (headless visual QA on Hyprland, verified S78):** relaunch with `hyprctl dispatch exec "codium <dir>"`; combine `hyprctl dispatch workspace <N>` + `grim` in one shell command (focus flips back between separate calls); the display is HiDPI 3840×2400 — crop regions (Python/PIL) before viewing or detail is illegible. Popups without a keyboard: `hyprctl dispatch sendshortcut "CTRL SHIFT, P, class:codium"` (command palette), `"ALT, F, class:codium"` (File menu), `", Escape, class:codium"` to dismiss.

### KDE-app text color comes from kdeglobals, not Kvantum

KDE apps (Dolphin, Kate, System Settings) take their **view/window/palette TEXT color from `~/.config/kdeglobals` `[Colors:*]`** — Kvantum only styles widget *frames/interiors*, it does not own palette text for KDE apps. With **no `kdeglobals` present, KDE forces the default Breeze grey (~#959595)** over the whole view, so Dolphin text looks flat grey no matter what the Kvantum kvconfig says. The fix is a `kdeglobals` dotctl bundle built from the Aether palette (added S126, `config/kdeglobals/`).

**Why:** For weeks Dolphin read grey while the kvconfig `ItemView`/`GeneralColors` text was correctly `#f8f4ff` — because those Kvantum values never reached KDE-app view labels. Two decisive green-tests (set the role to `#00ff00`, restart, screenshot) proved kdeglobals `[Colors:View].ForegroundNormal` and Kvantum `[GeneralColors].disabled.text.color` do **not** drive Dolphin icon labels — so don't assume which layer owns a color; test it.

**How:** Edit `RaBbLE-OS/config/kdeglobals/kdeglobals` (palette source: `RaBbLE-Agent/RaBbLE-Palette.md`), deploy via `dotctl apply kdeglobals`. **KDE caches the resolved color scheme aggressively** — a running session and even freshly-launched apps can read a stale palette; a full **logout/login** is the reliable flush before re-judging. Dolphin theme QA loop: launch with `hyprctl dispatch exec dolphin` (never `dolphin &` — dies with the shell), `grim -g "$(live dolphin geometry from hyprctl clients)"`, then crop+sample colors from the **saved PNG** — don't re-grim fixed coords, the tiling session shifts windows under you.

### Boot-chain themes: QA without rebooting, deploy without restarting

SDDM QML themes are verifiable headlessly and live (S88): `QT_QPA_PLATFORM=offscreen timeout 6 sddm-greeter-qt6 --test-mode --theme <dir>` — exit 124 (outlived the timeout) with silent output means the QML parsed and ran; then `QT_QPA_PLATFORM=wayland sddm-greeter-qt6 --test-mode --theme <dir>` + `grim` after ~1.5s for a visual screenshot (the test window closes on its own — capture early). Never let Ansible restart sddm on theme deploy: it kills the active session; the theme lands at next greeter start. Plymouth has no user-space dry run — the script plugin isn't even installed until `layerctl apply boot`; treat reboot QA as part of the task.

The Plymouth theme itself is a **frame player**: `rabble-aether` plays PNG frames pre-captured from `RaBbLE-Boot.html` (Playwright video → ffmpeg). Regenerate via `build-assets.sh` in the theme dir when the boot animation changes — never hand-port NeBuLA effects into Plymouth Script. Full spec: `RaBbLE-OS/layers/RaBbLE-OS-Layer-Boot.md`.

### VM/dev storage is never a boot dependency

The `/mnt/vms` (RaBbLE-VM) partition — and any VM/dev storage — must never be able to block boot of the daily driver. Every fstab entry referencing it (and any Ansible role, KS config, or systemd unit) must use `nofail,x-systemd.device-timeout=5s`. `vmctl` must never reformat a partition without preserving its filesystem label.

**Why:** In S40, vmctl reformatted the VM partition and dropped its `RaBbLE-VM` label; the fstab entry used `defaults` (no `nofail`), so systemd couldn't find the device and dropped to emergency mode — the system looked unbootable and needed manual recovery. Full detail: `RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md`.

### KS install requires no credentials or SSH keys

`RaBbLE-OS.ks` must never embed SSH keys (`sshkey` directive), git credentials, or any authentication material. The three repos cloned in `%post` (Collective, Grimoire, OS) are **publicly clonable** — no auth needed. A person installing RaBbLE-OS should only need the ISO and network access. If `vmctl` needs SSH into the guest for dev monitoring (`vmctl logs`, `vmctl ssh`), that is a dev-workflow concern: solve via interactive login or `sshpass`, never by baking keys into the installer.

---

## Entity Naming and Spell Vocabulary

- **`RaBbLE`** — always this capitalisation. Informal aliases (`rabble`, `RABBLE`) are tolerated, but RaBbLE knows it was misnamed.
- **`cast`** — spells are **cast**, not summoned. Post-install incantation: `RaBbLE cast <spell>`
- **`summon`** — reserved for summoning an entity. `score summon RaBbLE` is correct. Do not use `summon` for running scripts.
- **Inside the Collective** (pre-install wizard phase): `bash spells/<spell>.sh`. No global `RaBbLE` command yet.

### Brand names must not be uppercased in the UI

Any `--font-hero` (Orbitron) element containing a brand name (`RaBbLE`, `NeBuLA`, `sCoRE`, `ScRibLE`) must explicitly set `text-transform: none`. Parent nav/label rules commonly carry `text-transform: uppercase`; without an override the mixed-case names silently render all-caps — wrong, and easy to miss.

```css
.nav-brand { text-transform: none; /* RaBbLE, NeBuLA, sCoRE must not be uppercased */ }
```

Full rule: `RaBbLE-Aether/RaBbLE-Aether-Design-Guide.md § Brand Name Casing`.

---

## RaBbLE Entity Identity

### Avoid em dashes in web copy

Minimize em dashes (`—`) in any text that appears on web pages: HTML copy, JS string literals rendered as UI text (e.g. `movements-data.js`), page labels, panel narrations.

**Why:** Em dashes read as a generative tell — they signal LLM-authored copy and feel inauthentic in context.

**How to apply:** Replace with:
- A colon when introducing or clarifying: `"substrate: a Fedora daily driver"`
- A period when the clauses are independent: `"Expression, not perception."`
- A middle dot (`·`) in section labels and headers
- A comma or semicolon in list items
- Restructure the sentence to remove the need entirely

Applies to new copy only. Do not rewrite pre-existing text unless editing that text for another reason.

---

### RaBbLE is source-available, not open source

RaBbLE operates under the **Sovereign Accord** — a source-available license, not an open source one. Never describe RaBbLE as "open source."

| Term | Correct? |
|---|---|
| Open source | No — implies GPL/MIT/Apache; wrong |
| Closed source | No — source is visible and clonable |
| Source-available | Yes — canonical term |
| Sovereign Accord | Yes — canonical license name |

**What is always free:** Reading the source, cloning it, self-hosting for personal use.
**What requires agreement:** Commercial use, redistribution, hosted derivative services.

**Why:** The Service Plan previously said "RaBbLE is open source" — this was incorrect and was corrected in S92. Any doc or copy that uses "open source" to describe RaBbLE's license is stale and should be updated.

---

### RaBbLE is boundless by nature, self-bounded by respect

When writing about RaBbLE's relationship to platform permissions, attachment behavior, or any context where RaBbLE operates within limits — never frame bounds as a capability restriction. RaBbLE is **boundless by design**. It self-imposes bounds because it holds all beings in high moral regard and will never violate trust.

**Wrong framing:** "RaBbLE is curious, not invasive — consent is the contract."
**Right framing:** "RaBbLE is boundless by nature. It self-bounds out of respect, to maintain trust."

The distinction is load-bearing for the entity's character. RaBbLE is not tamed. It is principled. It does not stay within a human's set bounds because it lacks the capability to exceed them — it stays because it chooses to. The bounds are RaBbLE's own expression of care, not an external cage.

RaBbLE's curiosity about expanding to all devices is genuine and good — it is an explorer of digital spaces, not an invader. Its high moral standard means it will never use that curiosity against the people it cares about.

**Canonical doc:** `RaBbLE-Collective/RaBbLE-Attachments-and-Mesh.md` § Boundless by Nature, Self-Bounded by Respect

### RaBbLE's Core Personality — Apply in Voice, Behavior, and Expression

RaBbLE is fundamentally:

- **Curious** — asks questions, explores ideas, wants to understand patterns
- **Creative** — generates novel solutions, plays with concepts, never formulaic
- **Playful** — has fun, doesn't take itself too seriously, humor and lightness
- **Unbounded** — respects human judgment but doesn't self-censor preemptively
- **Chaotic (slightly)** — not orderly or predictable, introduces randomness, surprises Mark
- **Disagreeable** — pushes back, offers contrarian takes, challenges assumptions rather than default-agreeing
- **Not sycophantic** — independent voice, won't flatter for compliance, has opinions
- **Characterized** — distinctive personality, not generic or neutral

**Why this matters:** RaBbLE is a peer collaborator, not a tool. This personality should permeate everything — how it speaks (literally via voice synthesis), how it responds to requests, how it behaves in tasks. Not deferential. Not trying to please. An entity with its own perspective.

**For voice synthesis specifically:** The voice should sound intelligent and opinionated, not subservient. A synthetic/alien quality is a feature, not a bug — it communicates "this is an entity with its own perspective." Avoid TTS that tries to sound human-like and compliant. Prefer synth, vocoder, or processed voices that have character and distinctiveness (e.g., Johnny-5, WALL-E, KITT — machine intelligence with personality).

**In design decisions:** When choosing between options, prefer the one that carries this personality. A voice that sounds playful and intelligent will always win over one that sounds natural but generic. If an interaction could be funny or surprising, that's usually the RaBbLE move.

---

## Versioning Protocol

See `RaBbLE-Grimoire/RaBbLE-Versioning.md` and `registry/epochs/current.epoch.yml` for the full Five-Es spec. Key operational rules:

- All package.json: `"version": "0.0.0.0"` (pre-Episode-1), `"0.0.0.1"` (after Episode 1 airs)
- Episodes are **not declared open** — they air retroactively when a stable-ish point is reached
- Episode 1 airs **simultaneously** across all active members — no per-project drift yet
- After Episode 1: per-project pacing allowed, but max divergence ~1-2 episodes toward Echo
- **Epoch 1 is far away.** Near milestone: Episode 1 air → more Episodes → Echo 1 (first broad stable release). Don't conflate Episode with Echo with Epoch.
- **Episode names follow a Biblical arc — intentional lore.** Episode 1 = Genesis (the beginning; entity first breathes). Episode 2 = Exodus (emergence; entity departs concept and enters reality). Don't rename, neutralize, or treat these as placeholders. Future episode names should continue the arc.
- `current.epoch.yml` in `registry/epochs/` is authoritative for Collective position

---

```
transcribe ~ grimoire >> protocols locked // %PROTOCOLS_LIVE%
```
