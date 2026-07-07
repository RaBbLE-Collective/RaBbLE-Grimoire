# RaBbLE-NeBuLA-Studio.md

> **Status:** MVP built + verified (S198), approved by Mark 2026-07-06. Live at `RaBbLE-NeBuLA/studio/`, served locally at `http://localhost:8080/studio/` via `dev-cdn.js`.
> Build decisions + rationale: `log/plans/NeBuLA-Studio-Plan.md` (historical record — read this doc for current architecture, that one for *why*).
> Phase 8 of `RaBbLE-NeBuLA-Roadmap.md` / `CONTEXT.md`.

---

## What it is

A WYSIWYG drag-drop page builder: drag real Aether components and NeBuLA custom elements from a parsed-catalog palette onto a canvas, preview at Desktop/Tablet/Mobile breakpoints, save/load the layout as JSON. Built so Mark can compose RaBbLE-World prototype pages visually instead of iterating through natural-language rounds with an agent.

Home: `RaBbLE-NeBuLA` (not a new repo, not BaBbLE). Output: a JSON layout document + a pure renderer function — not raw HTML export (that's a later phase). Audience: any RaBbLE web surface (World today; sCoRE web UI, BaBbLE, OS web surfaces later), not World-specific — Studio's palette only ever offers real, catalog-documented Aether/NeBuLA components, never a one-off "custom HTML block" escape hatch.

## File layout

```
RaBbLE-NeBuLA/studio/
  index.html              # page shell — loads Aether CSS, nebula.iife.js, studio.js as ESM
  studio.css               # Studio chrome only, Aether CSS vars, no hex
  studio.js                 # entry point — wires modules to DOM (~65 lines)
  catalog-parser.js         # fetch + parse the component catalog → palette entries
  palette-panel.js          # renders draggable palette sidebar
  canvas.js                 # drop target, instance state, selection, reorder
  breakpoint-toolbar.js     # Desktop/Tablet/Mobile switcher
  layout-schema.js          # schema + validate()/createEmptyLayout()
  layout-store.js           # save/load JSON (file download/import) + localStorage autosave
  renderer.js               # pure fn: (layoutDoc, breakpointId) -> DOM, shared with future export
  dnd.js                     # ~90-line native HTML5 DnD helper
```

No bundler for Studio itself — loaded as native ESM directly by the browser. It *consumes* the built `dist/nebula.iife.js` the same way `RaBbLE-Catalog.html` does (`<script src=".../nebula.iife.js">`), so `src/` stays exclusively the embeddable engine.

**Dev route:** `dev-cdn.js` routes `/studio/*` → `RaBbLE-NeBuLA/studio/`; everything else (including `/world/RaBbLE-Catalog.html`) falls through to the World catch-all. Both serve from `localhost:8080`, so the catalog fetch below is same-origin.

## Catalog fetch — confirmed path

`catalog-parser.js:24` — `DEFAULT_CATALOG_URL = '/world/RaBbLE-Catalog.html'` (**not** `/RaBbLE-Catalog.html` — corrected during S198 verification; the real file lives at `RaBbLE-World/world/RaBbLE-Catalog.html`).

`parseCatalog(url)` fetches with `cache: 'no-store'`, parses via `DOMParser`, then `parseCatalogDocument` walks `.atlas-section` → `.rabble-section-header` (label) → `.atlas-entry` → `.atlas-entry-name` + first line of `.atlas-entry-code`, classifying by regex:
- `/^<rabble-[a-z-]+/` → `kind: "element"` (live custom element, instantiated via `document.createElement`)
- starts with `<` (other tag) → `kind: "markup"` (rendered via `innerHTML`)
- anything else (a JS factory call like `NeBuLA.ui.createEntityMini()`) → skipped entirely, not silently mis-rendered

Parses once on load; a manual "Refresh Palette" button re-parses on demand.

## JSON layout schema (`layout-schema.js`)

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

- `component.html` is captured at drop-time and stored in the saved JSON, so a layout stays reproducible even if the catalog changes later.
- `styleOverrides` is a flat inline-style property map per breakpoint, not real CSS/media queries.
- Flat `instances` array — no nesting (deferred to a later phase).
- `validate(doc)` does structural checks and returns `{valid, errors[]}`; both Load and autosave-read run every doc through it before rendering.

## Drag-and-drop (`dnd.js`)

Hand-rolled native HTML5 DnD (`draggable`, `dragstart`/`dragover`/`drop`) — deliberately not a library; no prior DnD code existed anywhere in the codebase. Two custom `dataTransfer` MIME types:
- `application/x-nebula-palette` — a component descriptor dragged from the sidebar
- `application/x-nebula-reorder` — an instance id being dragged within the canvas

`makeDropZone` wires `dragover`/`drop` on the canvas host; `findDropTargetInstanceId` determines insertion point by comparing `clientY` against each placed instance's bounding-rect midpoint.

## Canvas + selection (`canvas.js`)

`createCanvas(hostEl, options)` holds `layoutDoc`, `currentBreakpoint`, and `selectedId` in memory.

- `handleDropComponent` / `insertInstance` — builds and splices a new instance into `layoutDoc.instances`, reindexes `order`.
- `handleReorder` — moves an existing instance within the array (drag-to-reorder, not resize).
- `render()` — calls `renderLayout(layoutDoc, currentBreakpoint, hostEl, {editable: true})`, then decorates each `[data-instance-id]` element with drag handlers + a click-to-select listener.
- `selectInstance(id)` / `updateSelectionClasses()` — toggles `.is-selected` on the matching element (cyan outline via CSS only). Clicking the canvas host itself deselects.
- `afterChange()` — bumps `meta.updatedAt`, re-renders, autosaves to localStorage, fires `onChange`.
- `deleteInstance(id)` / `commitResize(id, size)` mutate `layoutDoc.instances` and go through the same `afterChange()` path as drop/reorder (re-render + autosave). Delete fires from the selected instance's overlay `×` button (`instance-controls.js`) or the Delete/Backspace key (guarded against firing while a real text input is focused). Resize drags mutate the wrapper's inline style live via plain mousedown/mousemove (not HTML5 DnD, which the wrapper already uses for reorder) and only call `commitResize` — writing `width`/`height` into `styleOverrides[currentBreakpoint]` — on mouseup.
- `getSelectedId()` now drives `instance-controls.js`: `updateSelectionClasses()` mounts a delete button + `e`/`s`/`se` resize handles onto the selected wrapper and destroys them on deselect/re-render (S199).

## Renderer (`renderer.js`)

One pure function: `renderLayout(layoutDoc, breakpointId, hostEl, {editable})`. Rebuilds `hostEl`'s children from `layoutDoc.instances` sorted by `order`, applying that breakpoint's `styleOverrides`. `kind: "element"` instances are wrapped in a fixed-min-height placeholder (Aether spacing token) before the custom element is appended, so Three.js-backed elements (`<rabble-floor>`, `<rabble-graph>`) don't collapse layout during their async CDN load. `kind: "markup"` just sets `innerHTML`.

Deliberately has no idea about selection or drag handles — `canvas.js` decorates around its output. A future HTML-export phase reuses this same function unchanged with `editable: false`.

## Breakpoints (`breakpoint-toolbar.js`)

Renders one button per entry in `layoutDoc.breakpoints` (schema-driven, not hardcoded). Clicking sets the active breakpoint, re-renders active state, and triggers `canvas.setBreakpoint(bp)` → `applyFrameWidth()` sets the canvas frame's CSS width. Defaults: desktop 1280px, tablet 768px, mobile 375px — not yet promoted to real Aether breakpoint tokens (Aether currently defines none).

## Save / load (`layout-store.js`)

- **Save** — serializes `layoutDoc` to JSON, builds a `data:application/json` URI, triggers a temp `<a download>` click. Filename slugified from `meta.title`.
- **Load** — reads a file via `FileReader`, `JSON.parse`s, runs through `validate()` before rendering — rejects malformed/stale-schema files rather than silently mis-rendering them.
- **Autosave** — persists to `localStorage` key `nebula-studio-autosave` on every change; read back through `validate()` too.

## Sidebar / palette (`palette-panel.js`)

Each card now shows a live visual thumbnail above the name/badge row (S199). `catalog-parser.js` additionally captures `entry.previewHtml` — the innerHTML of the catalog page's own `.atlas-entry-preview` div — for every entry. `kind: "markup"` entries render that captured HTML directly inside a fixed-height (`56px`), `overflow:hidden`, `pointer-events:none` thumbnail box (Aether CSS is already loaded by the Studio page, so the real component styling just works). `kind: "element"` entries (the 4 Three.js-backed custom elements: `<rabble-entity>`, `<rabble-floor>`, `<rabble-graph>`, `<rabble-doors>`) get a static `◈` glyph placeholder instead of a live render — instantiating multiple WebGL/Three.js scenes simultaneously in a scrollable sidebar is unnecessary cost for a decorative preview. `pointer-events: none` on the thumbnail also means any interactive markup inside a preview (buttons, etc.) can't be clicked or accidentally hijack the card's own drag — the whole card, not its contents, carries the drag payload.

## Delete + resize (`instance-controls.js`, S199)

A per-instance overlay is mounted only onto the currently selected instance wrapper (`canvas.js`'s `mountControlsForSelection()`, called from `updateSelectionClasses()`, destroyed and remounted on every selection change or re-render):

- **Delete** — a small cyan `×` button pinned top-right of the selected instance; click calls `canvas.js`'s `deleteInstance(id)`. Also bound to the Delete/Backspace keys globally while something is selected (skipped if a real text input/textarea/contenteditable currently has focus, since Studio has no such fields today but this guards future ones).
- **Resize** — three drag handles (`e`, `s`, `se`) at the edge/corner of the selected instance. Dragging live-updates the wrapper's inline `width`/`height` via plain `mousedown`/`mousemove`/`mouseup` (deliberately not HTML5 DnD, which the same wrapper already uses for drag-to-reorder) for immediate visual feedback; the final size is only written into `styleOverrides[currentBreakpoint]` on mouseup, matching the app's existing "commit on change, not per-frame" pattern (same as drop/reorder triggering exactly one `afterChange()`).
- Every control element (`overlay`, delete button, resize handles) has `draggable` explicitly forced to `false` — without it, a mousedown originating on one of these children would be reinterpreted by the browser as a native drag of the nearest `draggable="true"` ancestor (the instance wrapper itself).
- `canvas.js`'s returned API also exposes `deleteSelected()` for any future toolbar wiring, though today's only entry points are the overlay button and the keyboard shortcut.

## Known gaps / next phases

Per-instance inspector panel and undo/redo do not exist yet (delete + resize shipped S199, closing out the rest of what was originally scoped as "Phase 2"):

- **Phase 2 (remainder):** per-instance inspector panel (edit attrs/styleOverrides without hand-editing JSON), duplicate, undo/redo.
- **Phase 3:** HTML export/codegen — call `renderLayout(doc, bp, offscreenHost, {editable: false})` per breakpoint, serialize to a committable World page fragment.
- **Phase 4:** nesting/containers (rows/columns instead of a flat list), multi-page projects, promote breakpoint constants to real Aether tokens.

---

## Revision History

| Date | Change |
|---|---|
| 2026-07-06 (S198) | MVP built and Playwright-verified end to end: palette parse (41 entries), markup + custom-element drag-drop, breakpoint switching, save-download, zero console errors. |
| 2026-07-06 (S199) | Architecture doc written distilling the plan doc into a stable reference; noted as prep for delete/resize gizmo + visual-palette work. |
| 2026-07-06 (S199) | Delete (overlay button + Delete/Backspace key), resize gizmos (`e`/`s`/`se` handles committing to `styleOverrides`), and live visual palette thumbnails (`.atlas-entry-preview` reuse, static glyph for the 4 Three.js element entries) built and Playwright-verified: 41 palette entries (37 live thumbnails + 4 placeholders), drop→select→resize→delete round-trip, keyboard delete, zero console errors. |
