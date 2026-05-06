# GAP-ANALYSIS.md — RaBbLE Collective Coherence Audit

```
analyzed: 2026-05-06 | status: open
```

Gaps and coherence issues found during the 2026-05-06 doc structure overhaul.
Each item has a priority and a resolution path. Address in priority order.

---

## Priority 1 — Blocking Correctness

### 1.1 Registry manifests incomplete

**Gap:** Manifests exist only for OS, sCoRE, Frontend, WEB. Missing: World, NeBuLA, Aether, ScRibLE.
**Impact:** `spells/status.sh` can't track these members. Health checks blind.
**Fix:** Create manifests in `registry/manifests/` using `_template.manifest.yml` for each missing member.

### 1.2 Protocol contracts don't exist

**Gap:** `protocol/` directory referenced in Grimoire CONTEXT.md doesn't exist. Manifest schema, health-ping format, and intent message shape are all described in prose but not as actual schema files.
**Impact:** Members can't validate against a contract. Epoch 0 exit criterion is blocked.
**Fix:** Create `protocol/` dir. Start with `protocol/manifest.schema.json` (Pydantic → JSON schema export). Health-ping format second.

### 1.3 Memory member is undefined

**Gap:** The memory member (observation store, pattern extraction, retrieval) has no name, no repo, no manifest, and no architecture doc in the Grimoire.
**Impact:** sCoRE Episode 4+ can't proceed. Epoch 1 (first closed loop) is blocked.
**Fix:** Decide the name (Mnemos, Codex, or other). Create Grimoire section. Scaffold the repo.

---

## Priority 2 — Coherence Issues

### 2.1 RaBbLE-NeBuLA-JS vs RaBbLE-NeBuLA naming split

**Gap:** The actual repo is `RaBbLE-NeBuLA-JS` (POC sandbox). The Grimoire has extensive docs under `RaBbLE-NeBuLA/`. There is no `RaBbLE-NeBuLA` member repo. The Grimoire docs describe a clean rebuild, but the transition plan (how JS becomes NeBuLA or when NeBuLA gets its own repo) is not documented.
**Impact:** Any work on NeBuLA is ambiguous about which "repo" it targets.
**Fix:** Either rename `RaBbLE-NeBuLA-JS` to `RaBbLE-NeBuLA` or add a note in Grimoire `RaBbLE-NeBuLA/` docs clarifying that `RaBbLE-NeBuLA-JS` is the current working repo. Add AGENT.md and CONTEXT.md to `RaBbLE-NeBuLA-JS`.

### 2.2 RaBbLE-ScRibLE has no defined purpose

**Gap:** Exists as a stub (Grimoire README + member registry placeholder). No architecture doc, no defined purpose.
**Impact:** Any agent working on the Collective gets a dangling member with no meaning.
**Fix:** Either define ScRibLE's purpose in a Grimoire architecture doc, or explicitly mark it as "reserved — purpose TBD" in the registry manifest so agents don't wonder.

### 2.3 Root-level `devPlan.md` and `TODO` are outside the doc system

**Gap:** `/home/rabble/RaBbLE/devPlan.md` and `/home/rabble/RaBbLE/TODO` exist at root and are not referenced from any AGENT.md or CONTEXT.md. Their content may duplicate or conflict with Grimoire roadmap docs.
**Impact:** Agents starting from root AGENT.md will miss these.
**Fix:** Review contents; migrate actionable items to `Grimoire/log/GAP-ANALYSIS.md` or member CONTEXT.md `Active Tracks`. Delete or archive the original files.

### 2.4 `RaBbLE-CONTEXT.md` and `RaBbLE-OVERVIEW.md` at root are orphaned from the template system

**Gap:** These two deep docs predate the AGENT.md/CONTEXT.md standard. They are ecosystem-level context but don't fit the template (they're more like Grimoire docs living at root). They're not referenced from the new root `AGENT.md`.
**Impact:** Valuable context is stranded. Token waste if an agent loads both the root AGENT.md and these files.
**Fix:** Evaluate whether their content is covered by Grimoire docs. If so, archive them. If not, migrate the unique content to Grimoire. Reference from root `AGENT.md` only if genuinely needed.

### 2.5 RaBbLE-NeBuLA-JS has no AGENT.md or CONTEXT.md

**Gap:** Active POC repo with no agent entry point.
**Fix:** Create `RaBbLE-NeBuLA-JS/AGENT.md` and `RaBbLE-NeBuLA-JS/CONTEXT.md`.

### 2.6 Grimoire INDEX.md has no ScRibLE section

**Gap:** ScRibLE exists in the Grimoire dir but its README is not indexed.
**Fix:** Add ScRibLE section to INDEX.md once purpose is defined (see 2.2).

---

## Priority 3 — Quality of Life

### 3.1 No validation spell for doc links

**Gap:** Link integrity depends on manual checking. Broken refs accumulated before this audit.
**Fix:** Add `spells/validate-links.sh` — walks all AGENT.md and CONTEXT.md files, extracts relative paths, checks existence.

### 3.2 Session continuity is ceremony-dependent

**Gap:** Session log exists but requires manual upkeep. If an agent doesn't write a log entry, the next session has no context about where things were left.
**Fix:** Standardize session close ritual. Add to Grimoire AGENT.md: "Before ending session, append to `log/SESSION-LOG.md`."

### 3.3 OS CONTEXT.md branch status is stale risk

**Gap:** `RaBbLE-OS/CONTEXT.md` lists branch names and statuses (`mend-I/proart-nvidia: High entropy`). These go stale rapidly.
**Fix:** Move branch status to a separate `RaBbLE-Grimoire/RaBbLE-OS/RaBbLE-OS-Roadmap.md` entry (it's already there). Keep CONTEXT.md branch references minimal — just the current primary track.

---

## Resolved

- [x] Missing AGENT.md and CONTEXT.md for World, OS, Aether — **fixed 2026-05-06**
- [x] Broken CLAUDE.md symlink in OS — **fixed 2026-05-06**
- [x] Broken reading order paths in OS/CONTEXT.md and sCoRE/CONTEXT.md — **fixed 2026-05-06**
- [x] No Grimoire architecture doc for Aether — **fixed 2026-05-06**
- [x] No root ecosystem AGENT.md — **fixed 2026-05-06**
- [x] No session log — **fixed 2026-05-06**
- [x] `RaBbLE-OS-AIQuickstart.md` naming inconsistency — renamed to `RaBbLE-OS-AgentGuide.md`
