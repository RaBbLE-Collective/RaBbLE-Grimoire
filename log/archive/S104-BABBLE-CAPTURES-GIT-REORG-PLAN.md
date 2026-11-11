# S104 — BaBbLE Reorg · Captures Reorg · Git Linearization Plan

> **Status:** APPROVED PLAN — handoff for a future implementation session (Sonnet).
> **Authored:** 2026-06-15 (S104, Opus planning session). Decisions below are locked by Mark.
> **Scope:** Parts 1–2 are to be *executed*; Part 3 is a *written proposal only* — do not run the
> git rewrites without separate sign-off.
> **Locked decisions:** (1) concept-art umbrella under `assets/`; (2) captures become ephemeral
> (gitignored, untracked, kept on disk); (3) git history = written plan only this round.

---

## Context

Three asks, two to execute and one to deliver as a written proposal:

1. **BaBbLE reorg** — capture novel insights into their canonical Grimoire home, archive
   superseded planning docs, and group the AI-generated stills under a clear
   "AI concept art of RaBbLE" directory. A prior cleanup agent (S103) already did the loose-
   `captures/` triage and left `RaBbLE-BaBbLE/CLEANUP-PLAN.md` with PROPOSED follow-ups; this
   plan executes and extends those.
2. **Captures reorg + screenshot system into BaBbLE** — captures already physically live in
   `RaBbLE-BaBbLE/captures/`, but two things are wrong: (a) the **OS Print-key keybind still
   writes to a dead path** outside BaBbLE, and (b) the Grimoire Captures doc and git policy
   disagree (doc says "ephemeral/gitignored," but 126 files are tracked). Mark chose **ephemeral**.
3. **Git history** — `new-horizons` has diverged from `main` in Collective, sCoRE, and Aether
   (identical pattern in all three). Goal: make `new-horizons` linear atop `main`. Delivered as a
   written plan only; no branches rewritten this round.

---

## Part 1 — BaBbLE reorg

### 1a. Capture novel insights → Grimoire (copy forward, then archive original)
Per the Collective rule "content migrates forward, originals stay" and "Grimoire is the
documentation home." Genuinely novel, not-yet-homed material:

- `behavior/crawler-bots.md` — Scavenger→Organizer→Librarian pipeline. `_ROUTING.md` already
  says "formalize as an RFC in `RaBbLE-Grimoire/rfcs/`." That dir **does not exist yet**.
- `sketches/triton-local-inference-proposal.md` — local-first inference substrate proposal; novel, unrouted.
- `historical/aethernet-entry.md` + `historical/naming-ideation.md` — durable lore nugget
  "Aethernet = the mythic network, Ethernet transcended" + provenance of how repo names were chosen.

**Actions:**
- Create `RaBbLE-Grimoire/rfcs/` and copy `crawler-bots.md` → `rfcs/RFC-crawler-bots.md` and the
  triton proposal → `rfcs/RFC-local-inference-triton.md` (light header normalization only).
  Add both to `RaBbLE-Grimoire/INDEX.md`.
- Add a condensed **naming/lore provenance** note to Grimoire lore (`RaBbLE/` overview or new
  `RaBbLE/naming-origins.md`) capturing the Aethernet framing + naming history; link from INDEX.
- Leave BaBbLE originals in place (sketches/behavior are intake reference); update `_ROUTING.md`
  to mark them "captured → Grimoire rfcs/."
- **Open question for implementer:** `rfcs/` is created per `_ROUTING.md`'s stated intent; it is
  trivially relocatable under `RaBbLE-sCoRE/` if Mark prefers per-member doc homes.

### 1b. Archive what is outdated
`historical/` is an undocumented parallel archive holding **executed** plans:
`grimoire-consolidation-plan-v2.md`, `GRIMOIRE-PUBLICATION-PLAN(1).md`,
`sCoRE-v0-IMPLEMENTATION-PLAN.md` (all done), plus `RaBbLE-Manifest.md`, `aethernet-entry.md`,
`naming-ideation.md` (superseded by current Collective/Grimoire).

**Actions:**
- `git mv historical/ _archive/historical/` (preserves provenance; `_archive/` is the documented home).
- Add `_archive/historical/README.md` noting these are superseded, what replaced each, and where any
  novel content was captured (1a).
- Update `AGENT.md` "Where Things Are" — remove the now-gone `historical/` ambiguity.

### 1c. AI concept art → `assets/concept-art/` umbrella
Move the still-image theme dirs under a `concept-art/` parent; leave motion, ascii, and the
meta system at `assets/` root.

**Moves (git mv):**
```
assets/{anatomy,states,aesthetics,moodboards,renders,branding,appendages,environments,narrative}/
  → assets/concept-art/<same>/
```
Stays put: `assets/videos/`, `assets/visual/` (ascii+svg), `assets/meta/`, `assets/GRAPH.md`, `assets/INDEX.md`.

**Path-reference updates (no generator script exists — manual edits):**
- `assets/meta/index.json` — rewrite `path`/relative fields for the moved themes (machine source of truth).
- `assets/GRAPH.md` — relative links `anatomy/…` → `concept-art/anatomy/…`; reframe header as
  "AI Concept Art of RaBbLE"; note these are diffusion/AI-generated stills.
- `assets/meta/INDEX.md`, `assets/meta/README.md` — folder paths.
- `_ROUTING.md`, `AGENT.md`, `CONTEXT.md` — references to `assets/anatomy/`, `assets/states/`, etc.
- `.meta.md` bodies do **not** embed their own paths → no change to the 49 meta files.
- Add `assets/concept-art/README.md` declaring scope (AI concept art — diffusion stills, themed;
  motion in ../videos, ascii/svg in ../visual).

---

## Part 2 — Captures reorg + screenshot system into BaBbLE

### 2a. Fix the OS screenshot keybind (the real "move into BaBbLE" fix)
`RaBbLE-OS/config/hypr/scripts/screenshot.sh:8` sets `CAPTURES="$HOME/RaBbLE-Collective/RaBbLE-Captures"`
— a dead path. Print/Shift+Print currently dump outside BaBbLE. The Playwright spell
(`RaBbLE-Grimoire/spells/visual-screenshot.sh:51`) is already correct (→ `RaBbLE-BaBbLE/captures/_inbox/`).

**Actions (RaBbLE-OS uses the dotctl flow — edit `config/`, never `~/.config/` directly):**
- Change line 8 to `CAPTURES="$HOME/RaBbLE-Collective/RaBbLE-BaBbLE/captures"`.
- Route raw keybind output to the ephemeral inbox to match the spell: region/screen → `captures/_inbox/`
  (recommended, so triage is one place). Update the header comment (still says "RaBbLE-Captures … project tree").
- Deploy via dotctl after editing.

### 2b. Make captures ephemeral (Mark's choice)
- `git rm -r --cached captures` in RaBbLE-BaBbLE (keeps all 126 files on disk, untracks going forward).
- `.gitignore`: replace the `_inbox`-only rules with `captures/` ignored, keeping `.gitkeep`s so the
  taxonomy survives a fresh clone:
  ```
  captures/**
  !captures/**/
  !captures/**/.gitkeep
  ```
- Add `.gitkeep` to each category dir.

### 2c. Triage current loose captures (on-disk tidiness; local-only after 2b)
- `captures/_inbox/` (8 files) — view, re-file identifiable ones, leave unknowns.
- `captures/Design-Iterations/by-date/capture-region_*.png` (5, per CLEANUP-PLAN) — view, re-file or
  leave as dated evidence.

### 2d. Rewrite the Grimoire Captures-System doc to match reality
`RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Captures-System.md` is stale:
- Line ~353 "captures are .gitignored/ephemeral" — **now actually true** after 2b (was false before).
- Default spell path: doc says root `captures/visual-*.png`; spell writes `captures/_inbox/visual-*.png`.
- `find RaBbLE-Captures …` examples use the dead top-level name → fix to `RaBbLE-BaBbLE/captures`.
- Document the corrected OS keybind targets (2a).
Bump to version 1.3, update "Last Updated," reconcile directory-structure + quick-reference tables.

---

## Part 3 — Git linearization (WRITTEN PROPOSAL ONLY — do not run without sign-off)

Intended deliverable home: this section (or split to `log/GIT-LINEARIZE-PLAN.md`). Nothing rewritten yet.

**Shared pattern (verified in all three repos):**
`main = merge-base + 1 cleanup commit` (the "untrack .claude / AI tooling" %MAIN_STUB%).
`new-horizons = merge-base + […real work…, a near-duplicate of that same cleanup, …]`.
So `main` is **not** an ancestor of `new-horizons` — they diverged by one redundant cleanup.

| Repo | main tip | n-h tip | merge-base | redundant n-h commit(s) to drop |
|---|---|---|---|---|
| Collective | `4c73969` | `6a7988e` | `f092027` | `0a165cf` (dupe "update remotes") |
| sCoRE | `1f8f544` | `86df038` | `f54df1f` | `86df038`, `cbe35aa` (dupe untrack) |
| Aether | `b7facee` | `439d515` | `5f10c06` | `55c691b`, `43b2292` (dupe untrack) |

**Goal:** rebase `new-horizons` onto `main`, dropping the redundant cleanup commit(s) whose effect
already exists in `main`. `main` itself is **not** rewritten — only `new-horizons` is force-pushed.
Recipe per repo:

```bash
git fetch --all
git status --porcelain        # must be clean
# 1. Safety nets (sCoRE & Aether have NONE today — create them):
git tag backup/main-pre-linearize-S104 main
git tag backup/new-horizons-pre-linearize-S104 new-horizons
git checkout new-horizons
# 2. Replay n-h work onto main, preserving committer:=author dates (S104 lesson):
git rebase --committer-date-is-author-date --onto main <merge-base> new-horizons
#    When a redundant cleanup commit conflicts (it re-does what main already did):
git rebase --skip                          # repeat per redundant commit
# 3. Verify:
git merge-base --is-ancestor main new-horizons && echo LINEAR   # expect LINEAR
git diff backup/new-horizons-pre-linearize-S104 new-horizons    # expect only the dedup delta
git log --oneline main..new-horizons        # clean, no duplicate cleanup
# 4. Publish (guards concurrent sessions):
git push --force-with-lease origin new-horizons
```

Carried from prior lessons: the S101 rewrites flattened committer dates — the
`--committer-date-is-author-date` flag avoids repeating that. Collective already has
`backup/*-pre-rewrite` tags; **sCoRE and Aether have none**, so tagging is mandatory there.
`chrysalis` and the pre-rewrite orphan commits in Collective are untouched.
Alternative one-shot drop via `GIT_SEQUENCE_EDITOR=… git rebase -i` exists; the `--onto` + `--skip`
form above needs no interactive rebase.

---

## Verification

- **1c:** `find RaBbLE-BaBbLE/assets/concept-art -name '*.png' | wc -l` ≈ moved count; `GRAPH.md`
  links resolve under `concept-art/`; `python -c "import json;json.load(open('assets/meta/index.json'))"`
  parses and paths point under `concept-art/`.
- **1a/1b:** `RaBbLE-Grimoire/rfcs/` has the two RFCs and they're in `INDEX.md`; `historical/` gone,
  `_archive/historical/` present with README.
- **2a:** `grep CAPTURES RaBbLE-OS/config/hypr/scripts/screenshot.sh` shows the BaBbLE path; a region
  capture lands under `RaBbLE-BaBbLE/captures/`.
- **2b:** `git -C RaBbLE-BaBbLE ls-files captures | wc -l` → 0 (only `.gitkeep`s); files still on disk.
- **2d:** doc version 1.3; no remaining `RaBbLE-Captures` dead-path references.
- **3:** none — proposal only.

## Out of scope / Mark decisions
- `prototypes/RaBbLE.html` + `RaBbLE-Login.html` status (CLEANUP-PLAN open item) — flag, don't move.
- Executing the git rebases/force-pushes (Part 3 stays a written proposal this round).
- Final home of `rfcs/` (created per `_ROUTING.md`; relocatable under `RaBbLE-sCoRE/`).

## Commits (Pulse Protocol, per repo touched)
- BaBbLE: `harmonize ~ babble >> concept-art umbrella, historical archived, captures ephemeral // %BABBLE_REORG%`
- Grimoire: `transcribe ~ grimoire >> rfcs/ seeded from BaBbLE, captures-system doc reconciled, git-linearize plan // %CAPTURE_NOVEL%`
- RaBbLE-OS: `mend ~ os >> screenshot keybind repointed to BaBbLE/captures // %CAPTURES_PATH_FIX%`
