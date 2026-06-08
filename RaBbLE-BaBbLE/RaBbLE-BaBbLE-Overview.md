# RaBbLE-Grimoire / RaBbLE-BaBbLE

Grimoire-side documentation for the RaBbLE-BaBbLE member.

BaBbLE is the Collective's high-entropy intake workspace. It receives raw ideas, visual explorations, prototypes, and sketches before they mature enough to migrate to a member repo.

---

## What BaBbLE Is Not

- Not a development environment — nothing is built or deployed from BaBbLE
- Not Xperimental — Xperimental is the past genesis archive; BaBbLE is the present intake
- Not canonical — content here is reference and intake, not source of truth

## Integration Pattern

Content matures in BaBbLE → migrates to target member → BaBbLE keeps original as reference.

| BaBbLE Content | Target Member | Status |
|---|---|---|
| VISUAL_ANALYSIS.md | RaBbLE-NeBuLA specs/ | Migrated in Phase 1B |
| Crawler bot ideation | RaBbLE-sCoRE DataCrawler RFC | Migrated in Phase 3E |
| Hyprland style guide | RaBbLE-Aether OS layer (TBD) | Pending Phase 3E decision |
| Persona/soul.md | Genesis artifact — cross-links from RaBbLE/Genesis/ | Pending Phase 2C |
| Concept art | Stays in BaBbLE as visual reference | Stable |

## Member Entry Point

For working in the BaBbLE repo itself: `RaBbLE-BaBbLE/AGENT.md`

## Relationship to Xperimental

Xperimental holds the **genesis archive** — the origin code from October 2025. BaBbLE holds **ongoing intake** — present and future raw material. Different temporal purposes; do not merge.

Cross-reference: `registry/manifests/RaBbLE-Xperimental.manifest.yml`

---

## Lessons & Gotchas

- **Pipeline is BaBbLE → target repo, direct integration** — BaBbLE replaced
  "New-Designs" as the high-entropy intake workspace; raw ideas/prototypes/concept-art
  land here before crystallizing into Aether/NeBuLA/World/etc.
- **Xperimental is the genesis archive — not superseded by BaBbLE.** It preserves
  origin code (RaBbLE.py, NeBuLA-JS, WebOS, first server) with full git history; never
  merge or treat it as replaced. *(Mark intends to eventually rename it
  `RaBbLE-Reliquary` — see `project_reliquary_intention.md` in memory — but this is
  still only an intention; don't write it into canon as done.)*
- **`_ROUTING.md` is the canonical "what's here → which member" entry point**, replacing
  the drifted `_ESSENCE.md`/`_DISTILLED.md`/`_INTEGRATION_CHECKLIST.md` (archived per
  the "condense, don't delete" rule — their content was preserved, not dropped).
  The visual archive itself was reorganized (S45) from confusing nested directories
  into 9 flat thematic folders plus a real concept graph (`assets/GRAPH.md`,
  auto-derived `tags`/`related[]` links in `index.json`).
