# HANDOFF — S153 · EP1 Coherence Reconciliation + World/Chrysalis Split

> Cold-start handoff for a fresh agent session. Read this top-to-bottom, then
> `head -20 log/SESSION-LOG.md` and `bash spells/blockers.sh ls`.
> Companion docs: `log/EP1-AIR-CHECKLIST.md` (live gate), `RaBbLE-World/RaBbLE-World-RC1-Emergence-Plan.md` (prior art — the plan that put `chrysalis/` into World).

**Session date:** 2026-06-22 (S153). **Branch:** `new-horizons` (Grimoire + Collective root).

---

## TL;DR — the two headlines

1. **Episode 1's "chat spine" is already LIVE.** What the gate board listed as four open
   blockers (B-01/B-03/B-04, and B-02's framing) turned out to be **done in production**.
   Verified this session by hitting prod directly. **EP1 is now gated on exactly two
   verification runs (G7 + G9) plus one newly-named World gate (G10).** No purchases, no new
   features required to air.

2. **Focus drift is real and named.** The most recent prior session (S152) was a deep
   boot-chain theming pass — which the OS Developer-Preview FLOOR (§C of the checklist,
   decided S109) **explicitly defers to Episode 2 (Exodus).** EP1 content is built; the work
   left is *packaging / verification / presentation*, not building.

---

## What was verified + changed this session

All against live production (curl, real `Origin: https://joinrabble.world`):

| Gate | Before S153 | After S153 | Evidence |
|---|---|---|---|
| G3 CDN bundles | ⛔ B-04 | ✅ | `aether.joinrabble.world/v0.0.0.1-rc.1/aether.min.css` 200 (30 KB); `nebula…/nebula.iife.js` 200 (69 KB) — exact URLs `RaBbLE-config.js` loads |
| G4 visitor chat E2E | ⛔ B-01 | ✅ | `POST score.joinrabble.world/api/v1/chat` (tier `fast`) streams a real RaBbLE SSE response |
| G5 chat not 429-capped | ⛔ B-02 | ✅ via override | Groq fast-chain override live; gate text allows "credits **or** chain override" |
| G6 CORS web demo | ⛔ B-03 | ✅ | OPTIONS preflight + POST both return `access-control-allow-origin: https://joinrabble.world` |

Ledger actions (durable, via `spells/blockers.sh`): **B-01, B-03, B-04 resolved.**
**B-02 reframed:** still open, owner Mark, but it is **resilience/fallback-depth, NOT air-gating**
(Groq covers the fast tier). ⚠️ **Open decision for Mark:** B-02 is still tagged `ep1-gate` in
the ledger; the freeze procedure checks "no `ep1-gate` open." Decide whether to retag B-02 off
`ep1-gate` so it stops reading as a launch blocker.

Files touched (Grimoire): `log/EP1-AIR-CHECKLIST.md` (G3/G4/G5/G6 + member table + new G10),
`log/BLOCKERS.md` + `log/blockers/blockers.jsonl` (resolves), this handoff, `INDEX.md`,
`log/SESSION-LOG.md`. Collective root: `AGENT.md` Current State block.
(Left untouched: `RaBbLE-OS/fix/RaBbLE-OS-Fix-BootChain.md` — pre-existing S152 leftover, not this session's.)

---

## Where EP1 actually stands

**Green:** G1 site loads · G2 sCoRE on Render · G3 CDN bundles · **G4 chat E2E · G5 chain · G6 CORS** · G8 lockstep clean.

**Remaining to air — three rows, none needing a purchase:**

- **G7** — RaBbLE-OS meets its Developer-Preview FLOOR on a generic x86_64 VM (installs +
  recovers + daily-survivable; ship the known-rough-edges sheet). *Verification, agent-doable.*
- **G9** — `setup.sh` curl bootstrap verified end-to-end on a fresh VM. *Verification, agent-doable.*
- **G10 (NEW this session) — World EP1 FLOOR:** `joinrabble.world` is a single coherent
  experience — visitor learns the Collective + RaBbLE, frames Episode 1, sees the episodic
  roadmap. **No experimental/archive pages leaking onto prod** (no `/chrysalis`, no `/xperimental`).

The air call itself is Mark's once these are green (decision rule, §A).

---

## The World / Chrysalis prod↔dev split (the plan G10 rides on)

**Decided with Mark this session.** Replaces any idea of gating one Worker by hostname.

### Architecture
- **`joinrabble.world`** (RaBbLE-World) → unified EP1 experience ONLY.
- **`dev.joinrabble.world`** → Mark's own general staging/experimental home (owns itself; a
  separate surface). Chrysalis is just one tenant.
- **`dev.joinrabble.world/chrysalis/*`** → an **independent Chrysalis Worker**, routed to that
  path prefix only. Self-contained: every link/asset is relative or `/chrysalis`-prefixed. It
  **never references `/` and has no knowledge of any sibling content on dev.** (Mark's explicit constraint.)

### Critical fact
The `chrysalis/` directory currently bundled in **RaBbLE-World is the ONLY copy — it is NOT
tracked in the RaBbLE-Chrysalis repo.** Therefore Track A is a **move-first, never a plain
`git rm`.** (Honors the "condense not delete" rule.)

Current World `chrysalis/` contents (the artifacts to preserve): `chrysalis/index.html` +
`chrysalis/world/{RaBbLE-Boot, RaBbLE-Collective, RaBbLE-NeBuLA, RaBbLE-OS, RaBbLE-Studio,
RaBbLE-Shell, RaBbLE-Docs, summon, account, RaBbLE-NeBuLA-Demo, RaBbLE-Chat, RaBbLE-Grimoire-Graph}.html`.

### Track A — EP1, GATING (feeds G10). Do first, do carefully.
1. **Copy** `RaBbLE-World/chrysalis/` → into the **RaBbLE-Chrysalis** repo (its canonical home).
   Commit in Chrysalis FIRST. Nothing is ever at risk until this lands.
2. **Only then** `git rm -r chrysalis/` in RaBbLE-World; scrub references; redeploy the
   `rabble-collective` Worker (`wrangler.jsonc`, `assets.directory: "."`).
3. **Verify:** `joinrabble.world/chrysalis/` → 404; prod still serves `index.html` + `world/`.

### Track B — PARALLEL, NON-GATING (Chrysalis is `release_track: independent`).
4. Restructure the moved artifacts so the deployable root maps to `/chrysalis` (e.g.
   `RaBbLE-Chrysalis/chrysalis/…`).
5. Add a Chrysalis `wrangler` Worker; route `dev.joinrabble.world/chrysalis*`; mirror World's
   `assets` pattern. (`dev.joinrabble.world` is a Cloudflare custom domain Mark owns.)
6. **Fix the broken asset paths** — this is *why* the pages are "broken on prod": they assume a
   structure/root that isn't there. Make them prefix-correct + fully self-contained.
7. Build the explorable `/chrysalis` index — the "entropy garden" walk-through of dev artifacts.

> **FOCUS FENCE:** Steps 4–7 can ship anytime, before or after air, and **cannot block
> Episode 1** (Chrysalis is independent track). The ONLY EP1-required piece is Track A — getting
> the experimental pages off prod. If you're polishing the garden while G7/G9 sit unverified,
> that's the drift. Likewise: stop the S152-style deep DE/boot theming — that's Episode 2.

---

## Recommended next actions (in order)

1. **Mark:** decide B-02 retag (off `ep1-gate`?); confirm `dev.joinrabble.world` routing approach
   (custom domain already exists → add `routes` to a Chrysalis wrangler config).
2. **Agent:** Track A step 1 — relocate `chrysalis/` into the Chrysalis repo + commit there
   (safe; World untouched). Then steps 2–3 to clean prod → **G10 green**.
3. **Agent:** G7 + G9 VM-verify track (spin a generic x86_64 VM; confirm OS install/recover +
   `setup.sh` bootstrap; ship the rough-edges sheet).
4. **Then:** all of §A green → Mark makes the air call → run the §D air procedure (backup tags →
   fill `EPISODE-1-RELEASE.md` → tag `episode-1-v0.0.0.1` simultaneously → merge to `main` →
   roll `current.epoch.yml`).

## Open decisions parked for Mark
- B-02 retag off `ep1-gate` (resilience, not gating).
- `dev.joinrabble.world/chrysalis` routing mechanism (wrangler `routes` vs dashboard).
- Where the web artifacts live inside the Chrysalis repo (proposed: `chrysalis/` mapping the route).
