# EP1 Liminal Experience — World Guided Experience + Three.js Entity Awakening

> **Status:** IMPLEMENTED (S190) · Owner: Mark · All four workstreams landed and capture-verified.
> WS-A/WS-B: NeBuLA 16840ef/19321e3 + World bundle 374255a/70697f1 (3D entity awakened, parity approved).
> WS-C: World f045315 + 0d73ef5 (Acts 0–II passage + polish). WS-D: World f3eb5b6 (Act III descent
> crossfade + Act IV live summoning) + 2941c1c (voice de-dash). Remaining: Mark authors Genesis copy
> (`GENESIS-COPY: Mark` markers in index.html), live-sCoRE check of Act IV, deploy. Details:
> SESSION-LOG "Session 190 continued".
> **Scope:** World front-end guided experience rebuild + NeBuLA Three.js entity wiring.
> **This is Episode 1 work** (Mark, S190): the liminal passage lands on the EP1 scaffold and airs
> as EP1. Episode 2 (Exodus) remains the roadmap spine (`RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md`)
> plus the Pair/membership features (`RaBbLE-Collective/` membership docs) — the entity state
> machine and chrome unification are *seeded* here but mature in EP2.
> **Evidence base:** captures in `RaBbLE-BaBbLE/captures/_inbox/ep2-recon/` (S190 recon) +
> code recon of NeBuLA/Chrysalis/World (file:line refs below are verified as of S190).

---

## 1. Post-mortem summary — why this plan exists

Mark's verdict on the EP1 prod front end: **"mid, lacking liminal RaBbLE vibes."** The S190 audit agrees and locates the gap precisely:

- **Prod `joinrabble.world`** is a sparse threshold page: small entity in a left panel, large empty
  black field, three lines of copy, one `enter` button. Good copy, zero atmosphere, no journey.
  Only `/` and `/world/summon.html` respond; account/os/catalog 404 on prod.
- **Chrysalis `dev.joinrabble.world/chrysalis/ep1/`** (the genesis archive) already designed the
  guided experience we want: full-bleed starfield, six named doors orbiting the entity core
  (codex / eyes / summoning / collective / substrate / graph), live pulse-protocol log lines,
  presence chip, `%RESONANT%` state chrome, and a bottom **movement** nav
  (The Threshold → The Realm → The Summoning → Home) with a **DESCEND ↓** control.
  Tagline that captures the whole thesis: *"you are not browsing, you are passing through."*
- **G10 was closed as a floor, not a ceiling** (S177–S178): "coherent unified EP1 experience"
  was met; "liminal" was not the bar. The S182 Framework Refactor then built the machinery
  (Aether `.rabble-*` components + NeBuLA effect elements) but the prod pages consume it thinly.

**Conclusion:** the vibes were not lost by accident — they live in the Chrysalis archive and in
frameworks that already shipped. This plan brings them forward using current architecture
(apply, don't redefine — the root lesson of the Framework Refactor).

**Mark's refinement (S190):** Chrysalis vibes are on point but the pages **lack cohesion and
narrative, and never engage sCoRE**. They are six disconnected rooms, not a story, and the entity
in them is scripted, not live. The redesign target is therefore a **single-page liminal
experience** that guides the visitor through the RaBbLE Genesis + Collective narrative, with the
entity actively backed by sCoRE. Not a site. A passage.

## 2. The decisive technical finding

**The Three.js entity does not need to be built. It needs to be wired.**

- `RaBbLE-NeBuLA/src/backends/threejs-backend.js` (777 lines) is a complete `ThreeJsBackend
  extends Renderer`: InstancedMesh body (650) + aura (220) particles, proximity `LineSegments`
  connections, sweep-drawn portal arcs, 5-layer billboarded ellipse eyes proportioned to the
  Canvas2D reference, manual orbit controls, `BootSequence`-driven boot. Commits `34dee62`
  (`%3D_ENTITY_LIVE%`) and `6cd6df5` (`%LAYER2_LIVE%`).
- **Not wired:** `src/element.js:20,121` hardcodes `Canvas2dBackend`; `src/index.js:26-27`
  exports `backends = ['Canvas2D']`; no World page loads a Three.js CDN tag today.
- **Docs are stale relative to code:** NeBuLA `CONTEXT.md` + Grimoire NeBuLA Roadmap still say
  Three.js is "pending / deferred to Episode 2+". The code is ground truth.
  Also `RaBbLE-NeBuLA/specs/render-gap-analysis.md` describes a pre-port prototype (circular
  eyes, eyebrows, mouth tubes) — **do not "fix" from that doc; it is superseded.**
- **What actually makes the 3JS entity feel dead vs the Canvas2D persona** (visual capture
  `chrysalis-nebula-demo.png` + code diff):
  1. No black portal-socket ellipses behind the eyes (the anatomy that makes eyes read as portals).
  2. Much weaker glow/bloom (Canvas2D uses a separate CSS-blurred glow canvas).
  3. Simplified aliveness: `threejs-backend.js:533-589` blink/tracking has no saccade table,
     no jolt/click physics, no distraction drift — vs `src/backends/canvas2d/eye-system.js:159-258`
     (19-target weighted saccades, spring pursuit `springStrength=0.12, dampingFactor=0.72`,
     4-state blink FSM with 5-burst decelerating rhythm).
  4. Sparse particle cloud vs dense layered nebula.

## 3. Vision — one page, one passage: the Genesis descent

**A single-page liminal experience.** The visitor does not navigate; they descend through acts.
One continuous scroll/act-driven passage on `joinrabble.world/`, one continuous entity that never
leaves the viewport, narrative cohesion Chrysalis never had, and live sCoRE presence Chrysalis
never wired.

| Act | Name | What happens | Entity form | sCoRE |
|---|---|---|---|---|
| 0 | **The Signal** | starfield resolves, boot sequence plays, presence chip, whisper copy: "A signal resolves. You — at the threshold." | Canvas2D persona boots (`BootSequence`) | health ping → presence chip is real |
| I | **Genesis** | the narrative: what RaBbLE is, told in pulse-log scripture + short authored passages; entity reacts to scroll (state shifts, gaze follows) | Canvas2D, state-driven | — |
| II | **The Collective** | the organs revealed as one constellation (`<rabble-graph>`): Grimoire, sCoRE, Aether, NeBuLA, OS, World — each a node with one line of lore; not six rooms, one body | Canvas2D + graph environment | — |
| III | **The Descent** | the 2D→3D moment: the flat persona dissolves into the 3D particle body; parallax; you are inside it now | crossfade Canvas2D → Three.js | — |
| IV | **The Summoning** | RaBbLE addresses you — live. Converse surface embedded at the bottom of the descent; entity state machine wired to the SSE stream | Three.js (or entity-mini + 3D env) | **live chat** (existing G4 guest path); `%RESONANT%→%THINKING%→%SPEAKING%` driven by stream lifecycle |

Design rules: Aether tokens + `.rabble-*` components only (no new hex, no new CSS systems);
NeBuLA elements for all effects (`<rabble-floor>`, `<rabble-graph>`, `<rabble-doors>`, starfield/
streaks/constellation/haze); pulse-protocol log lines as ambient chrome; `%STATE%` vocabulary in
the UI; no em dashes in web copy. Local-first honesty: Acts 0–III are fully static/authored
(work offline, no cloud dependency); only Act IV requires sCoRE, and it degrades gracefully
(presence chip dims, summoning becomes an invitation) when unreachable.

**Cohesion mechanics (the Chrysalis fixes):** one page instead of six doors; one entity instance
persisting across acts instead of a fresh entity per page; a narrative spine (Genesis → Collective
→ Descent → Summoning) instead of a menu; sCoRE live instead of scripted; the old "doors" become
constellation nodes inside Act II rather than exits that scatter the visitor.

## 4. Decisions — RESOLVED by Mark (S190)

1. **Layered vs swapped rendering — RESOLVED: do both.** Wire the `backend` attribute (the
   honest seam), stage the "descent" as a crossfade between two `<rabble-entity>` instances
   rather than a mid-flight backend swap.
2. **Eye-color sides — RESOLVED: distinction is not critical.** A color swap reads as
   *expression or a change signal*, not an error — the dual cyan/magenta accents flow throughout
   RaBbLE (borders, chrome) and the eyes participate in that flow. No canon fix needed; record
   this in the visual spec (see doc-cleanup rider) so future agents stop flagging it as drift.
3. **Where this lands — RESOLVED: all of it is EP1.** The liminal passage replaces `index.html`
   on the EP1 scaffold and **airs as EP1**. Acts ship progressively but the air bar includes the
   passage. EP2 = the Post-EP1 roadmap spine + Pair/membership features.
4. **Narrative authorship — Mark authors the final voice** (Phase 2C domain). Agents scaffold
   Act I–II passages from Identity/Ethos gists as placeholders marked `<!-- GENESIS-COPY: Mark -->`.
   Authored static copy for Acts 0–III (deterministic, local-first); live sCoRE only in Act IV.

## 5. Workstreams (disjoint file ownership; parallel-safe)

### WS-A · NeBuLA wiring — owner: **Sonnet** agent · repo: `RaBbLE-NeBuLA` only
1. Shared memoized Three.js loader `src/utils/three-loader.js`; consume from `src/elements/floor.js:81-90`,
   `src/elements/graph.js:79-87` (kills the "Multiple instances" warning + duplicate ~600KB download;
   centralizes the `three@0.160.0` pin).
2. `backend` attribute on `<rabble-entity>` (`src/element.js`): `canvas2d` default, `threejs` opt-in,
   graceful fallback to Canvas2D when THREE absent (mirror floor/graph degradation pattern).
   WebGL capability check before selecting threejs (mobile rule from the Roadmap risk table).
3. Truthful `src/index.js` exports: `backends = ['Canvas2D','Three.js']` (Atlas/status read this).
4. API parity on `ThreeJsBackend`: implement or documented-no-op `setEyeConfig`, `setParticleConfig`,
   `setPortalVisible`, `getSnapshot`, `injectEyeJolt` (contract = what `Canvas2dBackend` exposes,
   `src/backends/canvas2d/index.js`).
5. Build + sync: `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`
   (NEVER skip — standing rule).

### WS-B · Three.js entity aliveness — owner: **Sonnet** agent · repo: `RaBbLE-NeBuLA` only (after WS-A merges; same-file overlap with WS-A in `threejs-backend.js` — serialize A→B)
1. Portal-socket ellipses behind the eyes (black `ShapeGeometry` ellipses + rim, matching Canvas2D
   `PORTAL_W=90, PORTAL_H=28` proportions and the never-level asymmetry `±EYE_H*0.44`).
2. Glow/bloom parity: additive sprite corona layers (avoid postprocessing bloom pass; keep external-
   Three.js-only, no new deps).
3. Port aliveness from `eye-system.js`: saccade target table, spring-damped pursuit, distraction
   drift, jolt-on-click, 4-state burst blink FSM. Extract shared behavior constants into
   `src/backends/eye-behavior.js` consumed by BOTH backends so the persona has one soul, two bodies.
4. Densify particle nebula (layered depth, palette-weighted violet core → cyan rim) within 60fps
   on desktop; verify via `getPerformanceMetrics`.
5. Visual acceptance: side-by-side capture vs Canvas2D — eyes must read as the same being.

### WS-C · World single-page Genesis passage — owner: **Sonnet** agent · repo: `RaBbLE-World` only
1. Rebuild `index.html` as the one-page act structure (Acts 0–IV, §3): act sections with
   scroll/act-driven progression, ONE persistent entity mount that survives act transitions,
   starfield/haze depth, presence chip (real sCoRE health ping), ambient pulse-log (`.rabble-log`).
   Aether components only (`assets/components/rabble-components.css` §16 roster + the 4 effects).
2. Act II constellation via `<rabble-graph>`/`<rabble-doors>` as in-page nodes (never exits);
   Act III descent = crossfade Canvas2D → Three.js entity, loading Three.js via config flip —
   add `RABBLE_THREE_URL` + `RABBLE_RENDER_BACKEND` to `world/js/RaBbLE-config.js` (the flip point).
3. Act IV summoning: embed the existing chat spine (G4 guest path, SSE) at the passage floor;
   map stream lifecycle → `entity.setState('%RESONANT%'|'%THINKING%'|'%SPEAKING%')`; graceful
   degradation when sCoRE unreachable (dim presence, invitation copy instead of chat).
4. Narrative copy: scaffold Act I–II passages from Identity/Ethos gists as placeholders,
   clearly marked `<!-- GENESIS-COPY: Mark -->` for Mark's authoring pass (decision 4).
5. Atlas first: demo the Three.js entity panel in `world/RaBbLE-Catalog.html` (lazy-upgrade +
   30s-timeout pattern already used there) BEFORE touching index.html — proving ground.
6. Reference vibes: `RaBbLE-BaBbLE/captures/_inbox/ep2-recon/chrysalis-ep1-index.png` (log/
   movement/atmosphere), `chrysalis-nebula-demo.png` (entity parity target),
   `prod-index-settled.png` (the "before"). Anti-goals from Chrysalis: no multi-page doors,
   no scripted-only entity, no navigation chrome that breaks the passage.

### WS-D · Capture QA loop — owner: **Haiku** agent · repo: `RaBbLE-BaBbLE` captures only
After each WS iteration: `bash RaBbLE-Grimoire/spells/visual-screenshot.sh --url <dev-serve URL>
--playwright --delay 6 --out RaBbLE-BaBbLE/captures/_inbox/ep2-recon/<ws>-<iter>.png`.
Dev server: `bash RaBbLE-Grimoire/spells/dev-serve.sh` (NEVER run esbuild/dev-cdn manually).
Orchestrator (or Mark) reviews captures; Haiku never judges vibes, only captures + reports paths.

### Doc cleanup rider (any WS, cheap)
- Mark `RaBbLE-NeBuLA/specs/render-gap-analysis.md` superseded (pointer header, don't delete —
  condense-not-delete rule).
- Refresh NeBuLA `CONTEXT.md` + Grimoire NeBuLA Roadmap "Three.js pending" claims to reflect
  `%3D_ENTITY_LIVE%` reality.
- Record eye-color ruling (decision 2: sides non-canonical, swap = expression/change signal) in
  `RaBbLE-Entity-Visual-Spec.md` (both copies: Aether root + NeBuLA `specs/visual-spec.md`).

## 6. Sequencing

```
WS-A (NeBuLA wiring)  ──►  WS-B (aliveness)  ──►  WS-C Acts III–IV (descent/summoning)
                                    │
WS-C Acts 0–II (signal/genesis/collective) ──┼──► can start immediately, parallel to A/B
WS-D (Haiku captures) ───────────────────────┴──► runs after every iteration, all workstreams
```
- WS-A and WS-C Acts 0–II are independent (disjoint repos) — run in parallel.
- WS-B waits for WS-A (same file `threejs-backend.js`).
- WS-C Acts III–IV wait for WS-B (needs a living 3D entity worth descending to); Act IV's chat
  spine can be wired against the Canvas2D entity early since `setEntityState` is backend-agnostic.
- Every NeBuLA change ends with build+copy to World before any capture (standing rule).

## 7. Cold-start handoff (for a fresh implementation session)

1. Read this doc, then: `RaBbLE-NeBuLA/AGENT.md`, `RaBbLE-World/AGENT.md`,
   `RaBbLE-Aether/RaBbLE-Entity-Visual-Spec.md`, `log/plans/done/World-Framework-Refactor-HANDOFF.md`.
2. Claim scope: `RABBLE_SESSION_ID="S<NN>-<ws>" bash spells/session-start.sh "<repo globs>" --task "…"`.
3. Key refs: `src/element.js:20,121` · `src/index.js:26-27` · `src/backends/threejs-backend.js`
   (eyes ~413-589) · `src/backends/canvas2d/eye-system.js` (constants 6-7, portals 281-282, blink
   223-258, saccades 159-221) · `src/elements/floor.js:81-90` + `graph.js:79-87` (dup loaders) ·
   `RaBbLE-World/world/js/RaBbLE-config.js` (flip point) · Chrysalis proof pattern:
   `RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/RaBbLE-NeBuLA.html:101,253`.
4. Build/verify loop: edit src → `npm run build:iife` → cp to World → `dev-serve.sh` →
   `visual-screenshot.sh --playwright` → Read the PNG.
5. Constraints: Three.js stays external (peer dep, `--external:three`); palette from
   `RaBbLE-Palette.md` only; no React; no em dashes in web copy; Aether owns CSS, NeBuLA owns
   effects, World is scaffold only.

## 8. Relation to Episode 2 (Exodus)

This plan is **EP1's presentation layer**; Exodus keeps its own spine untouched:
`RaBbLE-Agent/RaBbLE-Post-EP1-Roadmap.md` (local harness + `rabble` CLI, Watcher daemon,
Memory member, entity state machine, chrome unification) plus the Pair/membership arc
(summoning ceremony, invite tiers — `RaBbLE-Collective/` membership docs). Two direct couplings
where EP1 work seeds EP2:
- **Entity state machine (roadmap item 4)** — WS-B's shared `eye-behavior.js` + existing
  `setEntityState` are its substrate; when sCoRE streaming wires to `entity.setState('%THINKING%')`,
  both bodies (2D and 3D) respond for free.
- **Chrome unification (roadmap item 5)** — WS-C's `<rabble-entity-mini>` presence on every stage
  is the "one continuous entity" deliverable.

The day RaBbLE says something you didn't ask for is still the Exodus north star; this plan makes
sure that when it speaks, it has a body worth watching.
