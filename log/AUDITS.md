# AUDITS.md — RaBbLE Grimoire Audit Record

Completed audits of the Grimoire and Collective. Each entry captures scope, key findings, and resolutions. For open gaps, see `GAP-ANALYSIS.md`.

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

**Key decisions captured in:** `log/ONBOARDING-DECISIONS.md`
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

**Key decisions captured in:** `log/ONBOARDING-DECISIONS.md`
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

## Open Gaps — Current

### Blocking Episode 1

**1. sCoRE Railway deploy unverified**
Run `harness/deploy.sh` or `harness/railway_ctl.sh`; verify API responds; write `spells/deploy-score.sh`.

**2. bootstrap.sh not verified end-to-end**
Run `bash bootstrap.sh` on a clean VM; verify all members clone and configure correctly.

### Non-blocking

**3. Protocol contracts undefined** — `protocol/` dir referenced but no schema files exist. Deferred post-Episode-1 (Echo 1 scope).

**4. Memory member has no architecture** — No name, repo, manifest, or architecture doc. Intentionally deferred to post-Episode-1.

**5. validate-links spell not created** — `spells/validate-links.sh` would catch broken refs automatically.

**6. RaBbLE-OS versioning diverged** — OS uses its own model, doesn't cleanly map to Five Es. Deferred post-Ep1.

**7. Grimoire browser not built** — Episode 1 includes a World page rendering Grimoire docs. World-side work pending.

**8. Behavioral learning onboarding missing** — `RaBbLE-Agent/RaBbLE-BehavioralLearning.md` planned but deferred until Memory member scope is decided.

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
