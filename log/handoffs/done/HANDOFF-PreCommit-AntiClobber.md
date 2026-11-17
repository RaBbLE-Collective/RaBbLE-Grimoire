# HANDOFF — pre-commit anti-clobber enforcement (auto-register + warn)

**Status:** spec'd, NOT built (S129). **Decision:** auto-register + warn (never block).
**Why now:** Mark runs concurrent sessions constantly; the multi-agent logging system
(`agent-register.sh` / `decision-log.sh` / `promote-insight.sh`) is built and documented but
**empirically unused** — S126 caught two concurrent sessions, neither registered, and the exact
churn it prevents (files vanishing from `git status`, shared-index commits sweeping each other)
happened anyway. Nothing triggers it. This handoff turns the S116/S126 analysis into a buildable task.

> Read first: the S116/S126 analysis in `log/HANDOFF-S116-Theme-and-Logging.md` §"Session-logging
> system is BUILT but NOT ADOPTED". This supersedes it with a concrete plan.

---

## Where this fits (updated S129-audit)

The **front line** now exists: `spells/session-start.sh` claims scope at session START (before
editing — which is when clobbering actually happens) and runs a self-terminating background
heartbeat so claims survive. AGENT.md makes it the required opening ritual.

**This pre-commit hook is the BACKSTOP** — it catches the case where someone *skipped* the start
ritual, and warns at commit time (after the damage, but better than silence). It is not the primary
mechanism. Build it so it complements `session-start.sh`, not duplicates it.

## Goal

Make the backstop **self-adopting, agent-agnostically**, by wiring it into the one thing every
agent already does: `git commit`. No `.claude` SessionStart hook (that would violate the
agent-agnostic rule). The hook must be **best-effort and never block a commit on the clobber
check** — a buggy hook that blocks commits for every session is worse than the problem.

## Where it goes

Extend `spells/hooks/pre-commit` (symlinked into every member repo's `.git/hooks/` by
`spells/install-hooks.sh`). The existing symlink-block check stays as-is (it *should* hard-fail).
Add a **second, isolated block** below it for auto-register + warn, wrapped so it can never abort
the commit. Pattern to copy: the `post-commit` hook already does cross-repo Grimoire discovery and
"only a live session (transcript touched < 15 min)" gating — reuse both.

## Behavior (per commit)

1. **Locate the Grimoire** from the member repo (copy post-commit's loop):
   `./RaBbLE-Grimoire/… , ../RaBbLE-Grimoire/… , ./…`. If not found, `exit 0` silently.
2. **Resolve + liveness-gate the session** exactly like post-commit (`projdir` from cwd, newest
   `*.jsonl`, `find -mmin -15`). Non-Claude agents → fall back to the git-commit key, same as
   `end-session.sh`. If nothing resolves, `exit 0`.
3. **Auto-register the committing scope** (solves the chicken-and-egg: today `check` always passes
   because nobody ever `claim`s). Take the staged paths (`git diff --cached --name-only`), map to
   claim scopes (see below), and call `agent-register.sh claim "<scopes>" --task "auto: <commit organ>"`.
   This makes *the next* agent's `check` meaningful. Auto-claims must be marked `auto:true` in the
   claim JSON so they're distinguishable from deliberate claims and can be GC'd more aggressively.
4. **Check for a live overlap** BEFORE writing the auto-claim: run `agent-register.sh check <paths>`
   against *other* live agents' claims. If a **different** live session holds an overlapping scope,
   print a loud but non-fatal WARNING naming the other session + paths. **Do not exit non-zero.**
5. Wrap the whole block in `{ … } >/dev/null 2>&1 || true` style safety (mirror post-commit) so any
   internal failure is invisible and the commit proceeds.

## Three problems to solve (called out in S126)

- **(a) Cross-repo path resolution.** Claims live in the Grimoire (`log/agents/`), the hook fires in
  member repos. Solved by post-commit's discovery loop — lift it verbatim.
- **(b) Repo-relative paths → claim-scope globs.** Staged paths are member-repo-relative
  (`server/app.py`); claim scopes are a Collective-wide namespace. **Decision needed:** namespace
  claims by member, e.g. `World:world/js/*` or `<repo-basename>/<path>`. Recommend prefixing each
  staged path with the member repo's basename so claims from different repos can't false-overlap.
  `agent-register.sh check` and `claim` glob-matching must agree on this prefix.
- **(c) Heartbeat / claim lifetime.** ✅ **Solved S129-audit** by `session-start.sh` — it spawns a
  self-terminating background heartbeat that refreshes every 240s (under the 300s stale threshold)
  and stops within one cycle of `release`. For *this hook's* commit-time auto-claims (when the start
  ritual was skipped), no heartbeat is needed: a dead claim simply stops generating warnings and the
  next commit re-registers. Document that hook auto-claims are *advisory and self-expiring*, not a
  lock. (A stronger guarantee = the "hard-block" variant Mark declined in S129.)

## Companion doc change (cheap, do alongside)

`RaBbLE-Grimoire/AGENT.md` already (S129-audit): non-optional coordination; `session-start.sh` is the
required opening ritual (claims scope + auto-heartbeat); `blockers.sh ls` folded in. Once this hook
lands, add a line to the AGENT.md ritual noting that commit also **auto-registers as a backstop**, so
a forgotten `session-start.sh` still produces a warning — but `session-start.sh` remains the front line.

## Test recipe (must pass before install)

1. Two fake sessions via `RABBLE_SESSION_ID`. Session A: `agent-register.sh claim "World:world/js/*"
   --task t`. Heartbeat it so it's live.
2. Session B: stage `world/js/foo.js` in the World repo, commit. Assert: a WARNING naming session A +
   the overlap is printed, **commit succeeds (exit 0)**, and B's auto-claim was written.
3. Stale case: let A's heartbeat age past 900s (or fake the mtime); repeat B's commit. Assert: **no
   warning** (A is dead), commit succeeds.
4. Non-overlap: B edits a disjoint path. Assert: no warning, auto-claim written, commit succeeds.
5. Failure-injection: make `agent-register.sh` exit non-zero mid-hook. Assert: commit **still
   succeeds** (the `|| true` safety holds).

## Files touched (when built)

- `spells/hooks/pre-commit` — add the auto-register+warn block.
- `spells/agent-register.sh` — add `--auto` flag on `claim` (marks `auto:true`); ensure `check`'s
  glob matching honors the member-prefix namespace from problem (b).
- `RaBbLE-Grimoire/AGENT.md` — note that registration is now automatic on commit.
- `SPELLS.md` — update the `agent-register.sh` entry to mention auto-registration.
