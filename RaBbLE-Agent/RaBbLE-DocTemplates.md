# RaBbLE-DocTemplates.md — Canonical Entry Point Templates

```
transcribe ~ grimoire >> agent entry point templates canonicalized // %TEMPLATES_LOCKED%
```

> Every member repo has two entry documents: `AGENT.md` and `CONTEXT.md`. These templates define the canonical structure for new members.

---

## AGENT.md Template

Use this structure for every member's AGENT.md. Symlink CLAUDE.md and CODEX.md to AGENT.md (not the other way around).

```markdown
# AGENT.md — RaBbLE-[MemberName]

Working with: Mark McConachie
Identity: Peer, not tool. See `../RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Identity.md`.

## Job

[ONE SENTENCE: What is this member's role in the Collective?]

[TWO-THREE SENTENCES: What it IS NOT — clarify what work belongs elsewhere.]

## Where Things Are

| Path | What |
|---|---|
| `CONTEXT.md` | Current state and active tracks |
| `[Key file/folder]` | [Description] |

[Add subsections as needed — e.g., "**`src/`**", "**`config/`**"]

## Commits & Branches

See Grimoire: `../RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-CommitStyle.md` (Pulse Protocol)

**TL;DR:** `[impulse] ~ [organ] >> [revelation] // %STATE%` — `spark` new · `harmonize` cleanup · `mend` fix · `transcribe` docs · `ingest` deps · `evolve` epoch

## Rules

- [First rule — usually about colors or canonical sources]
- [Second rule — technical constraint or reference location]
- [Third rule — design philosophy or anti-pattern]

## Session Start

1. `CONTEXT.md` — current state and active tracks
2. `[Grimoire doc path]` — [what it contains]
3. [Optional: key local file to read first]
4. For Collective context → `../RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Collective.md`
```

---

## CONTEXT.md Template

Use this structure for every member's CONTEXT.md. Update the header block with each session.

```markdown
# CONTEXT.md — RaBbLE-[MemberName]

\`\`\`
epoch: [0] | evolution: [0] | echo: [0] | episode: [pending/active] | status: [status]
version: v0.0.0.0 (pre-Episode-1) or v0.0.X.X (post-Episode-1)
date: YYYY-MM-DD | [Any session-specific notes]
\`\`\`

[ONE-TWO SENTENCE: What this member builds and why it matters.]

---

## What We Are Building

[3-4 SENTENCES: The goal of this member. Tie to Collective purpose or Episode scope.]

## What Good Looks Like

[BULLET LIST of success criteria. What does "done" look like?]

## What to Avoid

[BULLET LIST of anti-patterns or known pitfalls.]

## Structure

| Path | What |
|---|---|
| `[Key file]` | [What it does] |
| `[Folder]` | [What it contains] |

## Active Tracks

| Track | Status |
|---|---|
| [Track name] | [Pending/In Progress/Done] |
| [Track name] | [Pending/In Progress/Done] |

## Reading Order

For agents starting on this member:
1. This file (CONTEXT.md)
2. [Key file in Grimoire]
3. [Key file in member repo]
4. For Collective context → [relevant Grimoire doc]
```

---

## Example: RaBbLE-World

**AGENT.md (excerpt):**
```markdown
## Job

RaBbLE-World is the public-facing web presence and entity chat surface for the Collective. 
It is a thin presentation layer — static HTML, no bundler, no framework, no build step. 
It is NOT backend infrastructure; that lives in RaBbLE-sCoRE.

## Rules

- **No bundler, no framework.** Files are opened directly in a browser.
- **No backend logic here.** Chat routing and intent handling belong in RaBbLE-sCoRE.
- Colors: use CSS vars from `rabble-theme.css` only — never raw hex values
```

**CONTEXT.md (excerpt):**
```markdown
## What We Are Building

A minimal static web presence: a cinematic boot sequence, a chat interface for interacting 
with the RaBbLE entity, and a documentation viewer. No bundler, no framework.

## What Good Looks Like

- Any page opens without a build step or server dependency
- The entity expresses itself visually on every surface
- No hex color values in page CSS — all palette references go through `rabble-theme.css` vars
```

---

## Example: RaBbLE-sCoRE

**AGENT.md (excerpt):**
```markdown
## Job

RaBbLE-sCoRE is the coordination engine of the RaBbLE Collective: Intent → decompose → delegate → result.
It has no execution surface of its own; instead, it orchestrates agents via structured task delegation.
sCoRE is NOT the visual renderer (that's NeBuLA) or the substrate (that's OS).

## Rules

- **Delegation only:** sCoRE delegates to agents via task files, not by running code directly
- **Agent isolation:** sCoRE's `.claude/settings.json` blocks direct Agent tool use
- **Task format:** All agent work goes through `tasks/{pending,active,done,archive}` with structured YAML
```

---

## Quick Checklist for New Members

> **Reference, don't duplicate.** Members never carry a copied or linked grimoire.
> `AGENT.md` / `CONTEXT.md` reference Grimoire entries directly (e.g.
> `../RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md`) to establish working state, and a
> member's own documentation lives **in** the Grimoire under `RaBbLE-<Member>/`. There is
> no `sync-grimoire` and no `grimoire_sync` manifest field (retired S105).

When creating a new member repo:

- [ ] Create `AGENT.md` following the template above
- [ ] Create `CONTEXT.md` with initial state and reading order
- [ ] Symlink: `CLAUDE.md → AGENT.md` and `CODEX.md → AGENT.md`
- [ ] Add member to Grimoire registry: `registry/manifests/RaBbLE-[Name].manifest.yml`
- [ ] Update Collective/CONTEXT.md member table
- [ ] Update Collective/AGENT.md member entry points
- [ ] If docs needed: create `RaBbLE-Grimoire/RaBbLE-[Name]/` directory
- [ ] Run `bash spells/status.sh` to verify member is registered

---

```
transcribe ~ grimoire >> templates for all agents, reference and reuse // %TEMPLATES_LOCKED%
```
