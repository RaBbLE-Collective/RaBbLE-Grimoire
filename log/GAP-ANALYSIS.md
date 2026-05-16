# GAP-ANALYSIS.md — RaBbLE Collective Coherence

```
analyzed: 2026-05-06 | revised: 2026-05-15 | status: living document
```

Running coherence gaps and open items. Address in priority order. Mark resolved items with date.

---

## Open — Blocking or High Priority

### 1.1 Protocol contracts undefined

**Gap:** `protocol/` directory referenced in Grimoire CONTEXT.md doesn't exist. Manifest schema and health-ping format are described in prose but not as actual schema files.
**Impact:** Members can't validate against a contract. Epoch 0 exit criterion technically unmet.
**Status:** Deferred — non-blocking for Episode 1 air. Address in Epoch 1.
**Fix:** Create `protocol/manifest.schema.json` (Pydantic → JSON schema export). Health-ping format second.

### 1.2 Memory member has no architecture

**Gap:** The memory member (observation store, pattern extraction, retrieval) has no name, no repo, no manifest, and no architecture doc.
**Impact:** sCoRE behavioral learning (post-Ep1) is blocked. Epoch 1 scope depends on this.
**Status:** Open — intentionally deferred to post-Episode-1.
**Fix:** After Episode 1 airs: decide name, write Grimoire section, scaffold repo.

### 1.3 sCoRE Railway deploy unverified

**Gap:** sCoRE has server code and harness scripts but Railway deploy has not been verified in recent sessions.
**Impact:** Episode 1 exit criterion — World chat depends on a live sCoRE endpoint.
**Status:** Open — Episode 1 blocker.
**Fix:** Run `harness/deploy.sh` or `harness/railway_ctl.sh`; verify API responds; write `spells/deploy-score.sh`.

### 1.4 bootstrap.sh not verified end-to-end

**Gap:** `bootstrap.sh` at root of Collective clones Grimoire, but `spells/setup.sh` hasn't been verified against all Ep1 member repos.
**Impact:** Collective's core promise ("fresh machine → working ecosystem") unverified.
**Status:** Open — Episode 1 blocker.
**Fix:** Run `bash bootstrap.sh` on a clean machine or VM; verify all members clone and configure correctly.

---

## Open — Low Priority / QoL

### 2.1 validate-links spell not created

**Gap:** Link integrity depends on manual checking. Broken refs have accumulated before prior audits.
**Status:** Open — non-blocking.
**Fix:** `spells/validate-links.sh` — walks all AGENT.md and CONTEXT.md files, extracts relative paths, checks existence.

### 2.2 RaBbLE-OS versioning diverged

**Gap:** RaBbLE-OS uses its own branch/episode model that doesn't cleanly map to the Five Es scheme. Deferred from prior sessions.
**Status:** Open — deferred to post-Ep1 or next OS bootstrap session.

### 2.3 Grimoire browser not built

**Gap:** Episode 1 includes a public Grimoire browser (World renders Grimoire docs). No implementation exists.
**Status:** Open — Episode 1 deliverable, World-side work.
**Fix:** World page that renders Grimoire markdown (static snapshot or dynamic fetch).

### 2.4 Behavioral learning onboarding missing

**Gap:** No doc explains RaBbLE's post-Episode-1 primary purpose (observation → pattern → inference → delegation).
**Status:** Open — intentionally deferred until Memory member is introduced.
**Fix:** `common/RaBbLE-BehavioralLearning.md` (~1,500 tokens). Write when Memory member scope is decided.

---

## Resolved

| Date | Gap | Resolution |
|---|---|---|
| 2026-05-15 | Registry listed stale members (RaBbLE-WEB, RaBbLE-Frontend) | Updated `current.epoch.yml` with current member set |
| 2026-05-15 | NeBuLA manifest described old two-layer architecture (entity in World) | Updated — entity is now in NeBuLA (`<rabble-entity>`, `Canvas2dBackend`) |
| 2026-05-15 | World manifest had stale notes about `rabble-entity.js` | Updated — World is now a thin scaffold with two loaders |
| 2026-05-15 | Two Episode 1 planning docs with overlapping scope | Merged `RaBbLE-Episode-I-Release.md` into `RaBbLE-Episode-1-Release-Map.md` |
| 2026-05-15 | Grimoire CONTEXT.md listed missing World/NeBuLA/Aether manifests | Updated — all 7 manifests now present |
| 2026-05-14 | Onboarding audit scattered across 6 files | Condensed to `log/ONBOARDING-DECISIONS.md`; process detail in SESSION-LOG |
| 2026-05-14 | Agent role framing missing | ON/FOR/WITH/AS added to Collective AGENT.md and all member AGENT.md files |
| 2026-05-14 | Pre-Episode-1 phase invisible in onboarding | Collective Phases section added to CONTEXT.md (Foundation → Pilot → Behavioral Engine) |
| 2026-05-14 | Episode/Echo/Plot versioning narrative unclear | "Episodes as Collective Sync Boundaries" added to RaBbLE-Versioning.md |
| 2026-05-14 | sCoRE system prompt contaminated project onboarding | Moved to `system-prompt-sCoRE.md`; standard AGENT.md restored |
| 2026-05-14 | Pulse Protocol duplicated across 7 files | Centralized to `common/RaBbLE-CommitStyle.md`; TL;DR in member files |
| 2026-05-14 | Episode 1 scope scattered across multiple docs | `RaBbLE-Episode-1-Release-Map.md` created as canonical scope |
| 2026-05-14 | No agent reading path into Grimoire | `RaBbLE-Grimoire-Navigator.md` created |
| 2026-05-13 | Registry had stale RaBbLE-WEB and RaBbLE-Frontend manifests | Removed stale manifests; World, NeBuLA, Aether manifests added |
| 2026-05-13 | RaBbLE-NeBuLA naming confusion (JS vs rebuild) | NeBuLA-JS archived to Xperimental; RaBbLE-NeBuLA is the v2 repo |
| 2026-05-06 | Missing AGENT.md and CONTEXT.md for World, OS, Aether | Created for all three |
| 2026-05-06 | Broken CLAUDE.md symlink in OS | Fixed |
| 2026-05-06 | No Grimoire architecture doc for Aether | Created |
| 2026-05-06 | No root ecosystem AGENT.md | Created (Collective AGENT.md) |
| 2026-05-06 | No session log | Created `log/SESSION-LOG.md` |

---

```
mend ~ grimoire >> gap analysis refreshed, resolved items archived, new gaps surfaced // %GAP_ANALYSIS_CURRENT%
```
