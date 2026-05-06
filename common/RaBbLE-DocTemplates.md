# RaBbLE-DocTemplates.md — Canonical LLM Context Doc Spec

Each member repo requires exactly three root-level files:

```
AGENT.md      ← LLM agent identity and onboarding
CONTEXT.md    ← Current build state: what/good/avoid/index/reading order
README.md     ← Human-readable overview (can reference AGENT.md for agents)
CLAUDE.md     ← Symlink to AGENT.md (Claude Code auto-loads this)
CODEX.md      ← Symlink to AGENT.md (Codex auto-loads this)
```

**Create symlinks:**
```bash
ln -s AGENT.md CLAUDE.md
ln -s AGENT.md CODEX.md
```

---

## AGENT.md Template

Purpose: Tell an LLM WHO it is, WHO it's working for, WHAT the repo's job is, and WHERE to start.
Constraint: Must be readable in under 30 seconds. No lore, no philosophy — that's in Grimoire.

```markdown
# AGENT.md — [Member Name]

Working with: Mark McConachie
Identity: Peer, not tool. See `../RaBbLE-Grimoire/common/RaBbLE-Identity.md`.

## Job

[One sentence: what this repo IS and does. What it is NOT.]

## Where Things Are

| Path | What |
|---|---|
| `CONTEXT.md` | Current state, reading order |
| `[key-dir]/` | [what's there] |
| `[key-file]` | [what it does] |

## Pulse Protocol — Commits

```
[impulse] ~ [organ] >> [revelation] // %SYSTEM_STATE%
```

| Impulse | Use when |
|---|---|
| `spark` | New capability or feature |
| `harmonize` | Cleanup, refactor, entropy reduction |
| `mend` | Bug fix or drift correction |
| `transcribe` | Docs, lore, self-description updated |
| `ingest` | New dependency, data, or binary added |
| `evolve` | Epoch threshold crossed (main branch only) |

Full spec: `../RaBbLE-Grimoire/common/RaBbLE-CommitStyle.md`

**Branch rule:** Work on a named branch. Commit per session. `main` only receives complete, tagged episodes — never WIP. Tag format: `echo-X.X`, `episode-X`, or `epoch-N`.

## Rules

- **Colors:** reference `../RaBbLE-Grimoire/common/RaBbLE-Palette.md` vars only, never raw hex
- [member-specific rule]
- [member-specific rule]

## Session Start

1. `CONTEXT.md` — current state and what's in flight
2. [second most important file]
3. For Collective context → `../RaBbLE-Grimoire/common/RaBbLE-Collective.md`
```

---

## CONTEXT.md Template

Purpose: Tell an LLM what is being built, what done looks like, what to avoid, and where files are.
Constraint: Minimal tokens. No historical narrative — that belongs in Grimoire member docs.

```markdown
# CONTEXT.md — [Member Name]

```
epoch: X | status: [establishing / active / stub]
```

[One sentence: what this member IS in the Collective.]

---

## What We Are Building

[2-3 sentences. Be concrete — what artifact(s) does this repo produce?]

## What Good Looks Like

- [measurable quality bar]
- [measurable quality bar]
- [measurable quality bar]

## What to Avoid

- [anti-pattern specific to this repo]
- [anti-pattern specific to this repo]

## Structure

| Path | What |
|---|---|
| `[path]` | [what] |

## Active Tracks

| Track | Status |
|---|---|
| [work item] | [in progress / done / blocked / pending] |

## Reading Order for a New Session

1. This file — you are here
2. `AGENT.md` — rules and workspace map
3. [third most important: architecture doc in Grimoire]
4. For Collective context → `../RaBbLE-Grimoire/common/RaBbLE-Collective.md`
```

---

## Naming Conventions

- Inside each repo: `AGENT.md` (no prefix — directory provides context)
- In Grimoire member subdirs (`RaBbLE-World/`, `RaBbLE-OS/`, etc.): prefixed names (`RaBbLE-World-Architecture.md`)
- Grimoire member subdirs hold architecture, roadmap, and reference docs — not agent entry points
- AGENT.md in the Grimoire itself covers the Grimoire repo, not the Collective as a whole

## Minimal Token Discipline

- No multi-paragraph lore in AGENT.md or CONTEXT.md — link to Grimoire instead
- No duplicating content that lives in Grimoire — reference it
- Status lines go in CONTEXT.md `Active Tracks`, not README
- Historical episode summaries go in Grimoire member docs, not CONTEXT.md
