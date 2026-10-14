# NeBuLA-Studio-Plan.md

```
spark ~ nebula >> S198: NeBuLA Studio MVP plan written // %NEBULA_STUDIO_PLAN%
```

> **Status:** BUILT + VERIFIED — approved by Mark 2026-07-06, MVP built and Playwright-verified end to end same session (S198). All 11 files live under `RaBbLE-NeBuLA/studio/`. One correction made during verification: the catalog fetch URL is `/world/RaBbLE-Catalog.html`, not `/RaBbLE-Catalog.html` as originally assumed below (fixed in code and in this doc). Later phases (inspector, undo/redo, HTML export, nesting, Aether breakpoint tokens) remain future work, not started.
> Phase 8 of `RaBbLE-NeBuLA-Roadmap.md` / `CONTEXT.md` ("NeBuLA Studio dev tool — Deferred").
> Also rendered as an Aether-themed Artifact page per `feedback_plan_as_aether_artifact` (Claude memory).

---

## Context

Mark's "vibe coding" approach to prototyping RaBbLE-World pages (describing layouts in prose to an agent) isn't giving him the visual control he needs. He wants to compose prototype pages directly — dragging real Aether components and NeBuLA custom elements onto a canvas, previewing at Desktop/Tablet/Mobile widths, and saving the result — rather than iterating through natural-language rounds.

This isn't a one-off script: it's the first slice of a documented long-range goal. `RaBbLE-NeBuLA-Refinement-Backlog.md` §4 already calls for unifying the old Demo/Studio prototypes into a real WYSIWYG editor, and `RaBbLE-NeBuLA-Architecture.md` records Mark's S46 vision of NeBuLA growing into "a visualization/animation studio with a WYSIWYG keyframe editor." NeBuLA's own `CONTEXT.md` lists this as **Phase 8: NeBuLA Studio dev tool — Deferred**, currently unblocked (Ep1 rearchitecture phases 1–4 are done). This plan is Phase 8, scoped to a genuinely useful MVP: palette + canvas + breakpoint switcher + JSON save/load. HTML export, an inspector panel, undo/redo, and layout nesting are explicitly later phases — resisting scope creep is the point.

Four architectural decisions are locked in with Mark (not open for re-litigation):

1. **Home:** inside `RaBbLE-NeBuLA` (not a new repo, not BaBbLE) — extends the documented backlog item above.
2. **MVP output:** JSON layout document + a renderer function that consumes it — not raw HTML export yet (that's Phase 3).
3. **Device preview:** one canvas + a Desktop/Tablet/Mobile breakpoint-switcher toolbar (Figma/Webflow style), not three parallel viewports.
4. **Component palette:** auto-parsed from the existing component catalog page (`RaBbLE-World/world/RaBbLE-Catalog.html`, currently branded "Atlas" — **the name is not final**, so this plan and its code treat it generically as "the component catalog" and avoid baking the word "Atlas" into module/function names) rather than hand-curated, so it stays in sync as the catalog grows.

Verified during research: no prior Studio prototype in this codebase (BaBbLE's two prototypes, Chrysalis's legacy Studio) implements actual drag-and-drop — this is genuinely new territory, not a refactor. No shared breakpoint tokens exist anywhere in Aether or World CSS today, so Studio defines its own canonical widths. `dev-cdn.js` (the local dev server) currently serves everything outside `/aether/*` and `/nebula/*` from `RaBbLE-World/`, so Studio's page needs one new route to be dev-served from its home in NeBuLA while still being able to same-origin-fetch the catalog page for parsing.

### Framework discipline (new principle, stated explicitly by Mark this session)

Aether + NeBuLA are not "World's CSS/effects layer" — they are **the frontend framework for every RaBbLE web application**, present and future (World today; sCoRE's web UI, BaBbLE, OS web surfaces, and any other member's web surface going forward). `RaBbLE-World-Architecture.md` already states the World-specific version of this rule ("World is a thin scaffold... anything that looks like look-and-feel belongs in Aether... never duplicate Aether classes in page CSS, add to Aether instead"), but the Integration Map currently only documents the dependency as "Aether + NeBuLA → World" — it doesn't yet say this applies collective-wide. This has been mirrored into `RaBbLE-Agent-Protocols.md` (Member Responsibility Split section) and the Claude memory `feedback_member_responsibilities`. This plan treats it as settled direction, not a Studio-only concern:

- **Studio's palette must never let a consuming page invent its own one-off component.** If a session needs something the catalog doesn't have yet, the correct workflow is: add it to Aether (styling) or NeBuLA (behavior/rendering) as a real, reusable, catalog-documented component — then it becomes draggable in Studio automatically. Studio should surface this as friction, not silently allow a workaround (no "custom HTML block" escape hatch in the palette for MVP).
- This reframes Studio's real audience as **any RaBbLE web surface**, not World specifically — worth remembering when Phase 3 (HTML export) picks an export target format, since a page generated by Studio should be droppable into World *or* a future member's web surface without modification, because it's built entirely from the shared framework's vocabulary.
- Separately from Studio: the Integration Map / Aether-Architecture docs should eventually be updated to state this collective-wide framework role explicitly (small doc task, not part of this build, but flagged so it isn't lost).

---

## Approach

### File layout — new sibling of `src/`, not inside it

```
RaBbLE-NeBuLA/studio/
  index.html              # Studio page — plain ESM <script type="module">, no bundler
  studio.css               # Studio chrome only, Aether CSS vars, no hex
  studio.js                 # entry point, wires modules to DOM
  catalog-parser.js         # fetch + parse the component catalog page → palette entries
  palette-panel.js          # renders draggable palette
  canvas.js                 # drop target, instance list, selection, reorder
  breakpoint-toolbar.js     # Desktop/Tablet/Mobile switcher
  layout-schema.js          # schema + validate()/createEmptyLayout()
  layout-store.js           # save/load JSON (file download/import) + localStorage autosave
  renderer.js               # pure fn: (layoutDoc, breakpointId) -> DOM, shared by canvas + future export
  dnd.js                     # ~80-line native HTML5 DnD helper
```

`src/` stays exclusively the embeddable engine (what `npm run build` ships to CDN); Studio is a dev tool that *consumes* the built `dist/nebula.iife.js` the same way `RaBbLE-Catalog.html` does, via `<script src=".../nebula.iife.js">`. No new esbuild target needed for MVP — `studio.js` loads as native ES modules, sidestepping any question of whether Studio counts as "the embeddable bundle" (`src/` CLAUDE.md forbids framework coupling in the *engine*; Studio is a separate consumer, not the engine).

### Dev-server route (one new branch in `dev-cdn.js`)

Add before the final World catch-all in `RaBbLE-Grimoire/spells/dev-cdn.js`:
```js
} else if (parsedUrl.pathname.startsWith('/studio/')) {
  const file = parsedUrl.pathname.replace(/^\/studio\//, '');
  filePath = path.join(NEBULA_ROOT, 'studio', file || 'index.html');
```
`NEBULA_ROOT` is already in the traversal-guard allowlist. This makes `http://localhost:8080/studio/` serve from `RaBbLE-NeBuLA/studio/`, while `fetch('/world/RaBbLE-Catalog.html')` from that page still resolves same-origin to World's catalog via the existing catch-all. `dev-serve.sh` only regenerates `dev-cdn.js` "if missing" — the file already exists, so this edit is safe and won't be overwritten by a future `dev-serve.sh` run.

### JSON layout schema (`layout-schema.js`)

```json
{
  "schemaVersion": 1,
  "meta": { "id": "...", "title": "...", "targetPage": "RaBbLE-World", "createdAt": "...", "updatedAt": "..." },
  "breakpoints": [
    { "id": "desktop", "label": "Desktop", "width": 1280 },
    { "id": "tablet",  "label": "Tablet",  "width": 768 },
    { "id": "mobile",  "label": "Mobile",  "width": 375 }
  ],
  "instances": [
    {
      "id": "inst-a1b2c3",
      "component": { "source": "atlas", "sectionId": "s-cards", "name": ".rabble-card.is-flat", "kind": "markup", "html": "<div class=\"rabble-card is-flat rabble-accent-cyan\">...</div>" },
      "attrs": {},
      "styleOverrides": { "desktop": {}, "tablet": {}, "mobile": { "display": "none" } },
      "order": 0
    }
  ]
}
```
- `component.kind` is `"markup"` (Aether class snippet, rendered via `innerHTML`) or `"element"` (a live NeBuLA custom element like `<rabble-doors>`, instantiated via `document.createElement(tagName)` + attributes so `customElements` upgrade fires correctly).
- `component.html` is captured at drop-time and stored in the saved JSON, so a layout stays reproducible even if the catalog changes later — this is *why* "auto-parsed" doesn't mean "live-fetched on every render."
- `styleOverrides` is a flat inline-style property map per breakpoint (not real CSS/media queries) — matches the "JS-driven single canvas" decision and keeps the renderer trivial for MVP.
- Flat `instances` array, no nesting — deferred to a later phase.

### Component catalog parser (`catalog-parser.js`)

`fetch('/world/RaBbLE-Catalog.html')` → `DOMParser` → walk `.atlas-section` → `.atlas-entry` (current structural class names on the catalog page — decoupled from whatever display title/brand the page itself uses, so a rename of "Atlas" to something else doesn't require touching the parser unless the DOM structure also changes), extracting `.atlas-entry-name` and the first line of `.atlas-entry-code`:
- First line matches `/^<rabble-[a-z-]+/` → `kind: "element"`.
- First line starts with `<` (any other tag) → `kind: "markup"`.
- First line is a JS factory call (e.g. `NeBuLA.ui.createEntityMini()`, confirmed present in the `s-entity` section) → excluded from the draggable palette in MVP, since it produces a detached node via a JS factory rather than markup/tag instantiation. Don't silently mis-render these — skip them.

Parse once on page load; a manual "Refresh Palette" button re-parses on demand (the catalog page is ~2000 lines, cheap to re-fetch — no caching layer needed for MVP).

### Drag-and-drop (`dnd.js`)

Hand-rolled native HTML5 DnD (`draggable`, `dragstart`/`dragover`/`drop`), not a vendored library. Zero DnD code exists anywhere in this codebase today (verified across all three prior Studio prototypes), so there's no existing pattern pulling toward a library, and the MVP interaction (palette→canvas append, in-canvas reorder) is exactly what the native API handles without gaps in any evergreen desktop browser. Matches the Collective-wide "vanilla JS, no framework coupling" rule in spirit even though this isn't the engine itself. Revisit only if nesting/touch support becomes real scope later.

### Renderer (`renderer.js`)

One pure function: `renderLayout(layoutDoc, breakpointId, hostEl, { editable })`. Rebuilds `hostEl`'s children from `layoutDoc.instances`, applying that breakpoint's `styleOverrides`. `canvas.js` calls it with `editable: true` and wraps output in selection/drag chrome; a later export phase calls the *same* function with `editable: false` for bare markup. Keep selection outlines and drag handles out of this file entirely — they belong in `canvas.js` as a decorator around the renderer's output, not baked into it, since Phase 3 (HTML export) reuses this function unchanged.

### Async vs. sync NeBuLA elements on the canvas

`elements/floor.js` and `elements/graph.js` already resolve `ensureThree()` internally inside their own `connectedCallback`; `elements/doors.js` renders synchronously (pure DOM/CSS). The renderer doesn't need per-tag special-casing — appending the element and letting its own lifecycle callback run is sufficient. The one thing `canvas.js` adds uniformly: wrap every `kind: "element"` instance in a fixed-min-height placeholder (via Aether spacing tokens) before appending the element, so layout doesn't collapse to 0px during the Three.js CDN load window. This is a single `kind === 'element'` rule, not per-tag logic, so any future async element added to the catalog is covered automatically. Removal (`el.remove()`) is enough for cleanup — `disconnectedCallback` on all three already tears down correctly.

### Save/load

`layout-store.js`: "Save" triggers a JSON file download (mirrors the proven `exportAnimation()`/`importAnimation()` pattern already used in `RaBbLE-BaBbLE/prototypes/animation-studio.html`); "Load" accepts a file via `<input type="file">` and calls `layout-schema.js`'s `validate()` before rendering. Also autosave the current layout to `localStorage` on every change so a page refresh doesn't lose work-in-progress.

### Documentation touch-ups

- `RaBbLE-NeBuLA/CONTEXT.md` — flip the Phase 8 row from "Deferred" once MVP lands.
- `RaBbLE-NeBuLA/AGENT.md` — add `studio/` to the "Where Things Are" table.
- `RaBbLE-Grimoire/RaBbLE-NeBuLA/RaBbLE-NeBuLA-Refinement-Backlog.md` §4 — mark progress once shipped.

---

## Later phases (explicitly out of scope now)

- **Phase 2:** per-instance inspector panel (edit attrs/styleOverrides without hand-editing JSON), delete/duplicate, undo/redo.
- **Phase 3:** HTML export/codegen — call `renderLayout(doc, bp, offscreenHost, { editable: false })` per breakpoint and serialize to a committable World page fragment. The Chrysalis legacy Studio's "HTML Embed" textarea is a relevant prior-art pattern for this.
- **Phase 4:** nesting/containers (rows/columns instead of a flat list), multi-page projects, and — worth flagging to Mark separately — promoting Studio's own 1280/768/375 constants into real Aether breakpoint tokens, since Aether's architecture table implies it should own "responsive breakpoints" but currently defines none anywhere in the codebase.
- **Phase 5 (related, not a Studio dependency):** `RaBbLE-Grimoire/RaBbLE-Collective/RaBbLE-Plan-Surface.md` already specs a "Living Plans" concept — a World route that renders Grimoire markdown plans as NeBuLA/Aether documents, motivated by exactly the same pain Mark raised this session ("plans in CLI are cumbersome"). It's marked EP2-concept, not started. Studio's `renderer.js` (JSON layout → DOM) and breakpoint canvas are natural shared infrastructure for that later work, but a markdown-plan renderer is a different rendering job (Markdown → DOM, not JSON-layout → DOM) — treat it as a sibling feature that could share Studio's shell/chrome, not a reuse of `renderLayout()` itself. Don't build this now; it's listed so the connection isn't lost.

### Stale doc flag (cleanup, not part of this build)

`RaBbLE-World-Architecture.md`'s JS Module Map table lists a row `RaBbLE-Studio.js — NeBuLA Studio controls — vanilla JS, no Alpine`, implying a Studio living inside World. That's a leftover reference to the old per-page entity-tuning Studio pattern (the Chrysalis-archived one), not this new drag-drop page builder, which per decision #1 lives in NeBuLA. Worth correcting that table row when convenient so the World/NeBuLA separation docs stay accurate — flagged here, not part of this build.

---

## Verification

1. `bash RaBbLE-Grimoire/spells/dev-serve.sh` — confirm it still boots and Aether/NeBuLA/World all still serve correctly (regression check on the `dev-cdn.js` route addition).
2. Rebuild NeBuLA if `dist/` is stale: `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js` (build-before-test discipline).
3. Open `http://localhost:8080/studio/` — confirm the palette populates from the catalog (check Network tab: same-origin 200 on `/world/RaBbLE-Catalog.html`, no CORS error), spot-check that `.rabble-card.is-flat` (markup) and `<rabble-doors>` (element) both appear, and `NeBuLA.ui.createEntityMini()` (factory call) does not.
4. Drag `.rabble-card` onto the canvas — confirm correct Aether styling renders inline.
5. Drag `<rabble-doors count="6">` — confirm synchronous render, no loading flash. Drag `<rabble-floor>` — confirm the placeholder reserves height immediately and the Three.js scene mounts within a couple seconds with no layout jump.
6. Reorder two placed instances via drag — confirm order persists across a save/reload cycle.
7. Click each breakpoint button — confirm canvas width changes to 1280/768/375 and a configured `styleOverrides` (e.g. `display: none` on mobile) actually applies.
8. Save → inspect the downloaded JSON against the schema above. Hard-refresh the page, Load it back — confirm the canvas reconstructs identically, including per-breakpoint overrides.
9. Confirm no console errors throughout, and that `RaBbLE-World/world/RaBbLE-Catalog.html` and `index.html` still load correctly through `dev-cdn.js` (the new `/studio/` branch didn't regress the World catch-all).

---

## Revision History

| Date | Change |
|---|---|
| 2026-07-06 (S198) | Plan drafted and approved; framework-discipline principle added and mirrored to Agent-Protocols |
| 2026-07-06 (S198) | MVP built (sonnet sub-agent, all 11 files) and verified end to end via `dev-serve.sh` + Playwright: palette parse (41 entries), markup + custom-element drag-drop, breakpoint switching, save-download, zero console errors. Corrected catalog fetch URL from `/RaBbLE-Catalog.html` to `/world/RaBbLE-Catalog.html` throughout this doc and in `catalog-parser.js`. |
