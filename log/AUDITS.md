# AUDITS.md — RaBbLE Grimoire Audit Record

Completed audits of the Grimoire and Collective. Each entry captures scope, key findings, and resolutions. Open gaps are tracked in the "Open Gaps" section below.

---

## 2026-06-20 — Multi-session hardening & EP1 air-prep audit (Session 129)

**Scope:** Mark now runs concurrent sessions. Audit of (1) session-logging adoption, (2) blocker
durability, (3) EP1 air readiness, (4) post-EP1 vision consolidation.

**Findings:**
- **Blockers were clobbered** — they lived ONLY in the 75-word SESSION-LOG `## LATEST` box (rewritten
  each session); grep found just 3 `Blockers:` lines in a 320 KB log. No durable ledger.
- **Logging system built but unadopted** — `agent-register.sh`/`decision-log.sh`/`promote-insight.sh`
  work + are in SPELLS.md, but AGENT.md framed them "optional — skip for solo" and nothing triggers
  them (S116/S126 caught two concurrent unregistered sessions).
- **EP1 docs stale** — `EPISODE-1-RELEASE.md` was an S57 DRAFT (Railway, `<pending>` placeholders);
  epoch yml still flagged World `episode_1_blocker` though `joinrabble.world` returns 200 (deploy done).
- **Branch harmonization DONE** — the S103 audit's #1 unlisted blocker: `status.sh` shows all lockstep
  members in-step on `new-horizons`; Chrysalis/Xperimental correctly `independent`. **Closed.**

**Work done:**
- **New `spells/blockers.sh`** + generated `log/BLOCKERS.md` (append-only JSONL, decision-log pattern);
  `status.sh` now surfaces open-count; seeded 5 open (4 ep1-gate) + 3 resolved.
- **New `log/EP1-AIR-CHECKLIST.md`** — live member-by-member air gate, blocker-linked rows, OS
  Developer-Preview FLOOR, tag procedure. De-staled `EPISODE-1-RELEASE.md` (Railway→Render) + epoch yml.
- **New `RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md`** — consolidated Exodus + Echo-1 + backlog (pointers).
- **Logging made non-optional** in AGENT.md; blocker spell wired into session start/end; LATEST box
  `Blockers:` reduced to a pointer (root + Grimoire AGENT.md + SESSION-LOG). SPELLS.md + INDEX.md updated.
- **New `log/HANDOFF-PreCommit-AntiClobber.md`** — spec for pre-commit auto-register+warn (not built).

---

## 2026-05-21 — Coherency & Path Audit (Session 29)

**Scope:** Post-restructure verification of path references, documentation indexing, decision capture, symlink setup, and open gap status.

**Work done:**
- **Stale path refs:** Fixed 40+ `common/` → `RaBbLE-Agent/` references across Grimoire and member docs
- **Documentation indexing:** 15 unindexed docs added to INDEX.md; INDEX now complete
- **AUDITS.md refs:** Updated 3 broken self-references in this file
- **CONTEXT.md:** Updated current state block, member registry table with proper dates and status
- **REFERENCES.md:** Trimmed ~800 tokens by removing duplicate glossary entries and consolidating vocabulary
- **Decisions:** Captured 5 missing architectural decisions in `log/DECISIONS.md` from Sessions 27–28
- **Symlinks:** Fixed CLAUDE.md/CODEX.md symlinks across all 8 repos (Grimoire, sCoRE, OS, World, NeBuLA, Aether, BaBbLE, Xperimental); all now point to respective AGENT.md
- **Setup:** Updated `spells/setup.sh` to wire Collective root into all member repos' .claude configs

**Key findings:**
- All post-restructure paths now consistent
- No untraced docs remain
- Session history complete (Sessions 1–29 logged)
- Member symlink standard established

**Resolutions:**
- Entry points verified across all repos
- Cross-repo references normalized
- Setup automation in place for new clones

---

## 2026-05-16 — Onboarding Token Reduction Audit (Sessions 11–12)

**Scope:** Token overhead across all onboarding paths.

**Findings:**
- `cat SESSION-LOG.md` instruction loaded ~10,360 tokens — entire history when agents only needed current state
- Navigator was ~1,510 tokens to read the routing map alone
- `INDEX.md` in returning-agent loop added ~1,045 unnecessary tokens per session
- Token estimates in Collective CONTEXT.md reading order table were stale

**Resolutions:**
- SESSION-LOG: `## LATEST` pinned box at top (~137 tokens) — session-start instructions now use `head -20`
- Navigator: condensed from 231 lines (~1,510 tokens) to 99 lines (~565 tokens)
- INDEX.md removed from returning-agent loop (now on-demand only)
- Token estimates corrected in CONTEXT.md reading order table
- `gist/` directory created: 8 distilled docs, ~2,000 tokens total for full picture
- `spells/distill-gists.sh`: Claude CLI spell to regenerate gists from canonical sources
- End-of-session checklist added to both AGENT.md entry points
- `Current State` block added to Collective AGENT.md (auto-injected — free context)

**Returning agent overhead:** ~12K tokens → ~2,147 tokens

---

## 2026-05-15 — Grimoire Coherency & Registry Audit (Session 10)

**Scope:** Full Grimoire structure, registry, episode model, release plan, session artifacts, entry points.

**Work done:**
- Registry: removed stale `RaBbLE-WEB` and `RaBbLE-Frontend` entries; all 7 current members listed with episode status and blocker flags
- NeBuLA manifest: updated to reflect Session 9 architecture — `<rabble-entity>` and `Canvas2dBackend` now in NeBuLA, not World; Three.js deferred to Ep2
- World manifest: updated — World is thin scaffold with two loaders (Aether + NeBuLA), no embedded renderers
- Episode 1 release plan: merged `RaBbLE-Episode-I-Release.md` into `RaBbLE-Episode-1-Release-Map.md` — single canonical doc
- Log: 6 stale onboarding audit files removed; `ONBOARDING-DECISIONS.md` created with distilled architectural decisions
- `GAP-ANALYSIS.md`: rewritten — 4 open gaps clearly stated, 19 resolved items archived with dates
- Entry points: Grimoire AGENT.md split into new-agent vs returning-agent paths; Navigator updated; CONTEXT.md active tracks corrected

**Key decisions captured in:** `log/DECISIONS.md`
**Full process detail in:** `log/SESSION-LOG.md` Session 10

---

## 2026-05-14 — Four-Pass Onboarding Audit (Sessions 1–4)

**Scope:** Agent onboarding quality, token overhead, narrative coherence, member role framing.

**Pass 1 — Entry points:** AGENT.md, CONTEXT.md, REFERENCES.md reviewed for low-token orientation. Reading order table created. Quick Orientation section added to Collective CONTEXT.md.

**Pass 2 — Terminology audit:** Phase vs Episode language conflict. "Foundation → Pilot → Behavioral Engine" phases added to CONTEXT.md. Versioning narrative clarified — Episodes are Collective sync boundaries (lockstep model).

**Pass 3 — Role framing:** ON/FOR/WITH/AS agent operating modes created and added to Collective and all member AGENT.md files. Clarified what it means to work WITH and AS RaBbLE, not just ON it.

**Pass 4 — Token walk:** Reading order verified. Grimoire Navigator created. sCoRE system prompt extracted from AGENT.md to `system-prompt-sCoRE.md`. Pulse Protocol centralized to `RaBbLE-Agent/RaBbLE-CommitStyle.md`.

**Resolutions:**
- Agent role framing: ON/FOR/WITH/AS established
- Pre-Episode-1 phase: now visible in Collective CONTEXT.md
- Navigator: created as first read for new agents
- Pulse Protocol: centralized, de-duplicated
- Episode 1 scope: `RaBbLE-Episode-1-Release-Map.md` created

**Key decisions captured in:** `log/DECISIONS.md`
**Full process detail in:** `log/SESSION-LOG.md` Sessions 1–4

---

## 2026-05-13 — Registry Cleanup

**Scope:** Member manifests — stale entries, missing files.

**Findings and resolutions:**
- Removed stale `RaBbLE-WEB` and `RaBbLE-Frontend` manifests
- Added manifests for World, NeBuLA, Aether
- NeBuLA naming confusion resolved: NeBuLA-JS archived to Xperimental; `RaBbLE-NeBuLA` is the v2 repo

**Full detail in:** `log/SESSION-LOG.md` Session 5

---

## Open Gaps — Current (Session 29 Status)

> **S129 reconciliation:** Live EP1-gate blockers now live durably in `log/BLOCKERS.md`
> (`bash spells/blockers.sh ls`) and the air gate in `log/EP1-AIR-CHECKLIST.md`. Gap #1 below is
> **RESOLVED** (sCoRE LIVE on Render S106, B-06). Gap #11 is **RESOLVED** (`render-ctl.sh` shipped).
> Gap #2 (bootstrap end-to-end) remains — it's air gate **G9**.

### Blocking Episode 1

**1. ✅ RESOLVED (S106) — sCoRE Render deploy** — LIVE at `https://rabble-score-x7qq.onrender.com`, managed via `spells/render-ctl.sh`. Blocker B-06 resolved.

**2. bootstrap.sh not verified end-to-end** — Bootstrap script exists at `/home/rabble/RaBbLE-Collective/bootstrap.sh`. Requires run on clean VM; verify all members clone, configure, symlinks wire correctly. *Status: files in place, live test pending — EP1 air gate G9.*

### Non-blocking

**3. Protocol contracts undefined** — `protocol/` dir referenced but no schema files exist. Deferred post-Episode-1 (Echo 1 scope). *Status: intentionally deferred.*

**4. Memory member has no architecture** — No name, repo, manifest, or architecture doc. Intentionally deferred to post-Episode-1. *Status: intentionally deferred.*

**5. validate-links spell not created** — `spells/validate-links.sh` would catch broken refs automatically. Nice-to-have for future audits. *Status: not yet implemented.*

**6. RaBbLE-OS versioning diverged** — OS uses its own model, doesn't cleanly map to Five Es. Deferred post-Ep1. *Status: known limitation, acceptable for Ep1.*

**7. Grimoire browser partial** — World has CSS (`RaBbLE-Grimoire.css`) and JS modules (`RaBbLE-Grimoire.js`, `RaBbLE-Grimoire-Data.js`) for Grimoire rendering. HTML page integration (`RaBbLE-Docs.html` references Grimoire data) present. Full interactive browser UI pending — may ship as MVP in Episode 1. *Status: MVP in progress, not blocking launch.*

**8. Behavioral learning onboarding missing** — `RaBbLE-Agent/RaBbLE-BehavioralLearning.md` planned but deferred until Memory member scope is decided. *Status: deferred with Memory member.*

**9. Architecture gists for sCoRE and World** — Code members lack agent-facing file maps. ~500-token architecture gists would save agents from reading ~180K (sCoRE) or ~120K (World) raw code to orient. *Status: recommended (S29 audit), not yet created.*

**10. INDEX.md audit-only demotion** — Flat doc index is useful for audits but agents rarely need it during work. Gist system + AGENT.md Workspaces table route better. Consider marking audit-only to reduce noise. *Status: recommended, not yet actioned.*

**11. Render deploy spell → `render-ctl.sh` refactor (FUTURE SESSION TASK)** — mirror the `railway-ctl.sh` consolidation: refactor `spells/deploy-render.sh` (and any residual sCoRE-deploy concerns from the removed `deploy-score.sh`) into a single unified `spells/render-ctl.sh` (setup / deploy / status / logs / env subcommands, `--help`, `--dry-run`). Goal: one canonical Render control spell paralleling `railway-ctl.sh`, so the active backend and the dormant one share a shape. *Status: queued for a future session (S105).*

