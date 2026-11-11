# World Framework Refactor — Aether + NeBuLA as Frameworks, World as Assembler

> Cold-start handoff plan. Multi-session, decomposable. Created mid-session while
> polishing the RC1 surface; the polish kept hitting friction that traces to one
> root cause: **World reimplements rendering (JS) and theming (CSS) that should
> live in NeBuLA and Aether.** This plan turns that observation into a refactor.

Status: 🟡 PLAN ONLY — not started. Awaiting go-ahead + session decomposition.

---

## 1. The Thesis (why we're doing this)

Three members, three jobs — held strictly:

| Member | Is the framework for | Ships | World imports |
|---|---|---|---|
| **Aether** | **Theming + style (CSS)** | a CSS bundle (`aether.css` / `.min`) | one `<link>` via `RaBbLE-aether.js` loader |
| **NeBuLA** | **Rendering + interactive JS components** | an IIFE/ESM JS bundle (`nebula.iife.js`) | one `<script>` via `RaBbLE-NeBuLA.js` loader |
| **World** | **Assembly** | static HTML pages | applies Aether classes + mounts NeBuLA components |

**Rule of the refactor:** World should not contain a custom rendering engine or a
component stylesheet. If World has JS that draws/animates, it belongs in NeBuLA.
If World has CSS that styles a reusable component, it belongs in Aether. World JS
shrinks to: config, page assembly, and wiring NeBuLA components to page state.

This is already half-true — `<rabble-entity>` is a NeBuLA custom element World just
mounts. The refactor extends that pattern to *every* visual/interactive concern.

---

## 2. Current State (measured, this session)

**World** (`RaBbLE-World/world/`):
- JS: **4,746 lines** across 16 files. The heavy ones are rendering/engine code:
  `RaBbLE-floor.js` (883), `RaBbLE-grimoire-graph.js` (806), `RaBbLE-movements.js`
  (688), `RaBbLE-account.js` (373), `RaBbLE-dock.js` (293), `RaBbLE-ui.js` (243, a
  DOM component factory), `RaBbLE-realm.js` (200), `RaBbLE-summon.js` (198),
  `RaBbLE-curator.js` (180), `RaBbLE-stage.js` (158).
- CSS: **2,327 lines** — much of it component styling:
  `RaBbLE-panels.css` (533), `RaBbLE-os.css` (423), `RaBbLE-unified.css` (360),
  `RaBbLE-dock.css` (330), `RaBbLE-account.css` (317), `RaBbLE-summon.css` (274).

**Aether** (`RaBbLE-Aether/assets/`) — already a real CSS framework, **1,864 lines**:
`components/rabble-components.css` (907), `motion/rabble-motion.css` (398),
`base/rabble-base.css` (240), `palette/rabble-palette.css` (192),
`theme/rabble-theme.css` (99). Already provides: glass surfaces, `.applet` tiles,
`.rabble-border-harmony` (flowing conic ring), `.rabble-harmony-line`, CRT layers,
motion primitives (`@property --harmony-angle`, `harmony-spin`, keyframes).

**NeBuLA** (`RaBbLE-NeBuLA/src/`) — already a real rendering framework:
`core/` (entity, runtime, boot-sequence, animation, stream), `backends/`
(canvas2d, threejs, renderer), `effects/` (entropy-shader, attractor,
ambient-field), `patterns/`, `ui/` (entity-mini, grimoire-eye, grimoire-ring),
`element.js` (defines `<rabble-entity>` with `setEntityState()`). Already exposes
graph-eye / ring visuals — but World draws its own floor + grimoire graph anyway.

**Chrysalis** (`RaBbLE-Chrysalis/Chrysalis-Web/ep1/`) — **read-only archive.**
Source to *mine* components from, never edit. Rich patterns to harvest:
`js/RaBbLE-liminal.js` (703 — orbiting-door threshold + deep-field starfield),
`js/RaBbLE-Grimoire.js` (555 — summoning circle), `js/RaBbLE-chat.js` (428),
plus `landing-*.css`, `liminal.css`, `Grimoire.css`.

**Diagnosis:** World re-implements what the frameworks already (or nearly) provide.
This session's bugs were all symptoms: panels with hand-rolled static rings;
buttons losing their UA border then needing per-site classes; the flowing border
not appearing because panels are built ad-hoc in `movements.js` and never received
the Aether class. One systemic fix (apply, don't redefine) replaced a dozen patches.

---

## 3. Target Architecture

```
Aether (CSS framework)              NeBuLA (JS framework)
  rabble-base.css                     <rabble-entity>        (exists)
  rabble-palette.css                  <rabble-floor>         (from World floor.js)
  rabble-motion.css                   <rabble-graph>         (from World grimoire-graph.js)
  rabble-components.css  ← grows       <rabble-field>        (liminal starfield, from Chrysalis)
    .rabble-panel                      <rabble-log>          (streaming entity log)
    .rabble-card                       <rabble-chat>         (void bubbles + ask-box)
    .rabble-btn / pill                 <rabble-doors>        (orbiting threshold)
    .rabble-statusbar                  nebula.ui.*           (factory components: panel, card,
    .rabble-dock                                              badge, statRow — migrated from ui.js)
    .rabble-log / .rabble-chat
    .rabble-overlay (login/nav)        Curator stays a thin data/voice module; live chat
    .rabble-whisper                    transport can move under NeBuLA or a small shared lib.
         │                                      │
         └──────────────┬───────────────────────┘
                        ▼
            World pages = HTML that links Aether,
            loads NeBuLA, mounts <rabble-*> elements,
            and sets attributes/state. Minimal glue JS.
```

**Naming:** new shared component classes are Aether-canonical `.rabble-*`. The
World `.rc-*` names become thin aliases (or are dropped page-by-page) so migration
is incremental and non-breaking.

---

## 4. Component Library Inventory (the actual work)

Each row = one reusable unit. "Home" is where it must end up. "Source" is where the
best current implementation lives to migrate/harvest from.

| Component | Home | Source today | Notes |
|---|---|---|---|
| Entity core | NeBuLA ✓ | `nebula/element.js` | Done — the pattern to copy. |
| Glass panel + flowing ring | Aether | World `rc-panel` + Aether `.applet`/`.rabble-border-harmony` | Canonicalize as `.rabble-panel`; ring already in Aether. |
| Member / collective card | Aether | World `rc-member-card`, `rc-collective-card` | One `.rabble-card` w/ accent var. |
| Button / CTA pill | Aether | World `rc-btn` | `border:none; appearance:none;` + harmony ring. |
| Section header + accent line | Aether | World `rc-section-header` + Aether `.rabble-harmony-line` | Merge. |
| Statusbar (3-zone waybar) | Aether | Chrysalis `landing-shell.css` `.statusbar` | Layout + `.rabble-harmony-line`. |
| Dock / channel | Aether (style) + World (glue) | World `dock.css`/`dock.js` | Style → Aether; expand/collapse glue stays thin in World. |
| Entity log (boot + ambient stream) | NeBuLA render + Aether style | Chrysalis `landing.js` log + `landing-panels.css` | `<rabble-log>` consuming a stream. |
| Ask-box (inline chat input) | Aether style + NeBuLA/curator behavior | Chrysalis Shell `.ask-box` | Persistent input; emits to curator. |
| Void-chat bubbles | NeBuLA render + Aether style | Chrysalis Shell `.void-chat` | Floating replies near core. |
| Transmissions (ambient output) | curator data + Aether style | World `curator-transmissions.js` + threshold | Drift-in lines w/ `%STATE%`. |
| Floor graph (Three.js) | NeBuLA | World `floor.js` (883) | Becomes `<rabble-floor>`/effect. |
| Grimoire graph | NeBuLA | World `grimoire-graph.js` (806) | Becomes `<rabble-graph>`. |
| Liminal starfield + orbiting doors | NeBuLA render + Aether door style | Chrysalis `liminal.js` (703) | `<rabble-field>` + `<rabble-doors>`. |
| Whisper card | Aether | Chrysalis `index.html` `.whisper` | Hover descriptor. |
| Overlays (login/nav/log/ios) | Aether | World/Chrysalis modals | `.rabble-overlay` family. |
| CRT ambient layers | Aether ✓ | Aether `rabble-scanlines/vignette/chromatic` | Already there; World just adds the divs. |
| Progress rail | Aether | World `unified.css` | `.rabble-rail`. |
| UI factory (panel/card/badge/statRow) | NeBuLA `nebula.ui.*` | World `ui.js` (243) | Move the DOM factory under NeBuLA, or drop in favor of HTML + Aether classes. |

### Effects to generalize (not just components)

The harvest must also catch the **ambient/visual effects** scattered across both
surfaces — these are the "living space" texture and belong to NeBuLA (render) or
Aether (CSS layer), made generic and parameterized:

- Deep-field starfield w/ parallax depth (Chrysalis `liminal.js`) → NeBuLA effect.
- Signal streaks / shooting transmissions across the field → NeBuLA effect.
- Constellation lines that reach toward the cursor → NeBuLA effect.
- Nebula haze / gradient fog → NeBuLA effect or Aether ambient layer.
- Glitch veil (`%GLITCH%` state) → NeBuLA state effect + Aether `.glitch-veil`.
- CRT scanlines / vignette / chromatic aberration → Aether (mostly exists).
- Portal-arc glow, entity ring, entropy shimmer → NeBuLA (entity-adjacent).
- Flowing conic border ring → Aether `.rabble-border-harmony` (exists; canonical).
- Brand-flow / harmony-line / harmony-glow text+line motion → Aether (exists).
- Cotton-candy swirl / boot/alert washes (see memory `cool_effects`) → Aether.

Rule: an effect that takes parameters (count, speed, color, intensity) and renders
to canvas/WebGL is **NeBuLA**; an effect that is purely CSS layers/filters/keyframes
is **Aether**. World never hand-rolls either — it toggles attributes/classes.

---

## 4b. The Component Catalog (design library page)

A single page — **`RaBbLE-World/world/RaBbLE-Catalog.html`** (working title;
"the Atlas") — that lists and renders **every** component in example form. It is
three things at once:

1. **Assembly palette** — the visual source of truth. To build a page, you browse
   the catalog, copy the markup snippet, drop it in. Every reusable piece is here.
2. **QA surface** — one screenshot covers every component. The flowing-border /
   missing-class class of bug this session would have been caught instantly on a
   catalog page. It becomes the default target of the screenshot loop.
3. **Proof of the thesis** — the catalog page is built *only* from Aether classes
   and NeBuLA elements. If a component can't be expressed as "apply a class / mount
   an element," it isn't done migrating. The catalog failing to render something
   purely from the frameworks is the signal that World still owns too much.

**Structure** (itself assembled from Aether + NeBuLA, no bespoke catalog CSS/JS):
- Grouped sections: Surfaces · Cards · Controls · Navigation · Entity & Render ·
  Chat · Overlays · Motion · Ambient/CRT · Tokens (palette + type scale swatches).
- Each entry shows: the rendered component, its name, the one-line markup snippet
  (`<div class="rabble-panel">…</div>` / `<rabble-floor>`), and which framework owns
  it (Aether badge / NeBuLA badge).
- Live states where relevant: hover, active, `.wm-active`, entity `thinking/speaking`,
  `.fast`/`.slow` motion — so the catalog exercises interaction, not just static form.
- Token section renders palette swatches and type scale straight from Aether vars —
  so the catalog is also the living palette reference.

**Lives in World** (it's a page, World's job is pages) but contains **zero** bespoke
styling or rendering — only framework consumption. It is the canonical example of a
correctly-thin World page, and the template every other page follows.

**Build it early and grow it.** The catalog is created in P1 with whatever Aether
components exist, and **every later phase adds its new components to the catalog as
part of "done."** A component isn't migrated until it appears in the catalog,
rendered purely from its framework. This makes the catalog the refactor's progress
bar: when the page is complete, the framework boundary is complete.

---

## 5. Phases (each a shippable vertical slice)

Do not big-bang. Each phase keeps the site working and is independently verifiable
with the screenshot loop.

- **P0 — Contracts.** Freeze the Aether class names and NeBuLA element/attribute
  API in this doc before code. Output: a short "API.md" appendix both tracks code to.
- **P0.5 — Exhaustive harvest + generalization.** Before building, mine **every**
  effect and component implemented across **both** surfaces — World `world/js` +
  `world/css` *and* the archived Chrysalis ep1 pages (`Chrysalis-Web/ep1/`,
  ~16.7k lines of css/js: `liminal.js`, `Grimoire.js`, `chat.js`, `Studio.js`,
  `landing*.css`, `liminal.css`, `Grimoire.css`, `grimoire-graph.*`, …). Produce a
  **master extraction map**: every distinct effect/component → its generic Aether
  (style) or NeBuLA (render) target, with duplicates collapsed. Both surfaces grew
  bespoke, overlapping versions of the same ideas; the job is to **make them generic
  and componentized**, picking the best implementation of each and discarding the
  rest. Output: `harvest-map.md` (extends §4) — the authoritative "what exists →
  what it becomes" ledger the build phases consume. Nothing is built until it is on
  this map; nothing on this map is left in World once built.
- **P1 — Aether component canonicalization.** Port World component CSS into
  `rabble-components.css` as `.rabble-*`. Keep `.rc-*` as aliases. World CSS files
  shrink to page layout only. Verify each page visually unchanged.
- **P2 — NeBuLA component extraction.** Move `floor.js`, `grimoire-graph.js`, and
  the liminal field into NeBuLA as `<rabble-floor>`, `<rabble-graph>`,
  `<rabble-field>`. World mounts elements instead of running engines. Verify parity.
- **P3 — Chat as a component.** `<rabble-chat>` (void bubbles + ask-box) + curator
  wiring, mounted persistently. This is the "living space" goal from the polish work.
- **P4 — Page reassembly.** Rewrite `index.html` + each `world/*.html` as thin
  assembly: link Aether, load NeBuLA, mount components, set state. Delete the World
  JS/CSS that P1–P3 made redundant. Target: World JS ≪ current 4,746 lines.
- **P5 — Liminal threshold (optional, builds on P2/P3).** The orbiting-doors entry
  as `<rabble-doors>` — the deferred half of the polish session's direction fork.

---

## 6. Sub-Agent Decomposition (parallel-safe)

Disjoint file ownership; contracts pinned in P0 so tracks don't block on each other.

| Track | Owns (writes only) | Reads (contract) | Model |
|---|---|---|---|
| **A — Aether/CSS** | `RaBbLE-Aether/assets/**`, Aether build | P0 class-name contract | Sonnet (visual judgment) |
| **B — NeBuLA/JS** | `RaBbLE-NeBuLA/src/**`, NeBuLA build | P0 element/attr contract | Sonnet (rendering logic) |
| **C — World assembly** | `RaBbLE-World/world/**.html`, World glue JS | Aether classes + NeBuLA API | Sonnet, last (depends on A+B) |
| **D — Harvest (read-only)** | `harvest-map.md` only | **all** of Chrysalis ep1 + World css/js | Haiku/Sonnet (exhaustive extraction) |

Track D runs **first** (P0.5) and feeds A/B/C. Its job is exhaustive: read every
effect and component in both surfaces, collapse duplicates, and pin each to a single
generic Aether/NeBuLA target. A/B/C build only from `harvest-map.md`; if they find an
unmapped effect mid-build, it goes back to D, not into World.

Coordination: use the Grimoire scope ritual (`spells/session-start.sh "<glob>"`)
since tracks A/B/C touch different repos but may run concurrently with Mark's other
sessions. Each track commits to its own member repo with Pulse Protocol messages.

---

## 6b. Orchestration Model — Opus conducts, Sonnet builds, Haiku harvests

Execute this as **one long-lived Opus orchestrator** driving **Sonnet builders** and
**Haiku workers** as sub-agents. The point is to put each kind of work on the
cheapest model that can do it well, and to keep the expensive orchestrator's context
small.

**Model routing — match work to model:**

| Model | Role | Does | Never does |
|---|---|---|---|
| **Opus** | Orchestrator (1 session) | P0 contracts, sequencing, writing sub-agent briefs, reviewing returned *summaries*, integration + conflict calls, final sign-off | bulk file reading, mechanical edits, screenshot runs |
| **Sonnet** | Builder (1 per track A/B/C) | the judgment work: CSS componentization, NeBuLA render extraction, page assembly + catalog | exhaustive raw reading (ask Haiku), cross-track edits |
| **Haiku** | Worker (reusable) | exhaustive harvest reading, grep/audit sweeps, mechanical class renames, catalog-entry scaffolding, **running the screenshot loop and reporting pass/fail** | design decisions, ambiguous judgment calls |

**Token-economy rules (lowest spend, highest success):**

1. **Push reading down, push decisions up.** Cheapest model (Haiku) does the
   high-volume *reading* (all 16.7k lines of Chrysalis + World); Sonnet does
   *judgment*; Opus only *decides + integrates*. Opus must never read raw source it
   can get summarized — it works from `harvest-map.md`, contracts, and sub-agent
   returns.
2. **Cold briefs are self-contained.** Each sub-agent is spawned with a brief that
   *is* its full context: the relevant contract slice + its file glob + acceptance
   check + pointers to the 2–3 memories it needs. Sub-agents never re-derive
   ecosystem context (that re-derivation is the main token waste — see
   [[feedback_grimoire_plan_handoff]]).
3. **Returns are structured summaries, not dumps.** Each sub-agent returns: files
   touched, what was verified (+ screenshot path), what's blocked — a few hundred
   tokens, not diffs. Keeps orchestrator context lean across many rounds.
4. **Keep workers warm; don't re-spawn cold.** Reuse one Haiku via `SendMessage` for
   successive mechanical jobs (context already loaded) instead of a fresh cold spawn
   each time; likewise one Sonnet per track across its phases.
5. **Parallelize disjoint, serialize only on contracts.** A (Aether) and B (NeBuLA)
   run in parallel (`run_in_background`); C (World) waits on A+B contracts being
   *frozen*, not finished. Disjoint repo ownership = no merge conflicts, no locks.
6. **Verification is a Haiku loop.** The screenshot/`--harmony-angle` checks run
   under Haiku; only a *failed* check escalates to Sonnet/Opus for visual judgment.

**The conducting loop:**

1. Opus freezes P0 contracts in this doc.
2. Opus spawns **Haiku-D** → exhaustive harvest → `harvest-map.md`. Opus reviews,
   resolves duplicate→canonical choices, freezes the map.
3. Opus spawns **Sonnet-A** (Aether) + **Sonnet-B** (NeBuLA) in parallel from the
   frozen contracts + map. **Haiku** runs screenshot QA on each returned slice.
4. On A+B green, Opus spawns **Sonnet-C** (World reassembly + the catalog page).
5. Opus integrates, has Haiku screenshot the full catalog, signs off, updates
   SESSION-LOG. Each track commit lands in its own member repo.

This keeps Opus tokens spent on *orchestration and judgment only*, with the bulk
reading/edit/verify volume on Sonnet and Haiku.

---

## 7. Delivery Mechanics (already in place — build on it)

- `RaBbLE-World/world/js/RaBbLE-config.js` is the flip point: localhost → dev-serve
  CDN mock at `/aether/v0.0.0.0/aether.css` + `/nebula/v0.0.0.0/nebula.iife.js`;
  other hosts → `aether.joinrabble.world` / `nebula.joinrabble.world`.
- Aether: edit `assets/**`, rebuild bundle, dev-serve picks it up.
- NeBuLA: edit `src/**`, `npm run build:iife`, copy to World's served path (see
  NeBuLA AGENT.md / memory `feedback_build_before_commit`).
- Verify every change with the screenshot loop:
  `node` + Playwright from npx cache (CommonJS `require`, not ESM import — the
  package is CJS), driving `window.RaBbLEStage.next()` to reach panel-heavy
  movements. Bundles load from `:8080` via `addInitScript` override when serving a
  page from another port. (All proven this session; scripts in scratchpad.)

---

## 8. Risks & Lessons (from this session)

- **Apply, don't redefine.** World duplicating an Aether/NeBuLA effect is the
  anti-pattern that caused every bug here. The flowing border already existed in
  Aether (`.rabble-border-harmony`); the fix was to *apply* it, systemically.
- **Ad-hoc construction defeats class-based theming.** Panels built directly in
  `movements.js` never got the Aether class. Either build through one factory or
  apply framework classes in one systemic pass — not per call-site.
- **Browser parity unverified.** The conic-ring flow animates in Chromium
  (`--harmony-angle` advances 41°→142° over 2.5s, confirmed). **Not yet confirmed
  in Firefox** — `@property <angle>` inside `conic-gradient` has historically been
  flaky there. P0 must include a Firefox motion check; if it fails, Aether needs a
  Firefox-safe flow technique (e.g. rotating a masked element, or `background-position`).
- **No bundler in World** — pages open directly; keep it that way. Frameworks build;
  World does not.
- **`pkill -f` self-matches the harness shell** (exit 144). Kill by PID/port.

---

## 9. Cold-Start Checklist (fresh agent picking this up)

1. Read this file end-to-end. Read `RaBbLE-World/CLAUDE.md`, `RaBbLE-Aether/CLAUDE.md`,
   `RaBbLE-NeBuLA/CLAUDE.md`.
2. `bash spells/status.sh`; claim scope for your track's glob.
3. Confirm P0 contracts exist (class names + element API). If not, write them first.
4. Start dev-serve; confirm `:8080/aether/...` and `:8080/nebula/...` return 200.
5. Work your track only; verify each slice with the screenshot loop before commit.
6. Pulse-Protocol commit per member repo; update `## LATEST` in SESSION-LOG.

---

## 10. In-Flight Work (uncommitted at plan creation)

Branch `new-horizons`, `RaBbLE-World`, uncommitted and **aligned with this refactor**
(World applies Aether's flowing border instead of hand-rolling rings):
- `world/css/RaBbLE-unified.css`, `world/css/RaBbLE-panels.css` — removed hand-rolled
  static conic rings; kept radius/padding/glow/layout.
- `world/js/RaBbLE-ui.js`, `RaBbLE-movements.js` — apply `.rabble-border-harmony`.
- `world/js/RaBbLE-stage.js` — systemic pass applying the Aether class to every
  surface a movement renders (fixes ad-hoc panels not flowing).

Already committed earlier this session: `81ccb52` (Aether panel polish: rounder
panels, glow, liminal opening copy). **Recommendation:** commit the in-flight changes
as the P0/P1 seed (they already embody "apply, don't redefine"), then branch the
tracks from there.
