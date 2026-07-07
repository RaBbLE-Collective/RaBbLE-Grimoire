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
- `getSelectedId()` is exposed on the canvas API but **nothing consumes it yet** — no inspector panel, no delete, no resize. Selection today is purely visual.

## Renderer (`renderer.js`)

One pure function: `renderLayout(layoutDoc, breakpointId, hostEl, {editable})`. Rebuilds `hostEl`'s children from `layoutDoc.instances` sorted by `order`, applying that breakpoint's `styleOverrides`. `kind: "element"` instances are wrapped in a fixed-min-height placeholder (Aether spacing token) before the custom element is appended, so Three.js-backed elements (`<rabble-floor>`, `<rabble-graph>`) don't collapse layout during their async CDN load. `kind: "markup"` just sets `innerHTML`.

Deliberately has no idea about selection or drag handles — `canvas.js` decorates around its output. A future HTML-export phase reuses this same function unchanged with `editable: false`.

## Breakpoints (`breakpoint-toolbar.js`)

Renders one button per entry in `layoutDoc.breakpoints` (schema-driven, not hardcoded). Clicking sets the active breakpoint, re-renders active state, and triggers `canvas.setBreakpoint(bp)` → `applyFrameWidth()` sets the canvas frame's CSS width. Defaults: desktop 1280px, tablet 768px, mobile 375px — not yet promoted to real Aether breakpoint tokens (Aether currently defines none).

## Save / load (`layout-store.js`)

- **Save** — serializes `layoutDoc` to JSON, builds a `data:application/json` URI, triggers a temp `<a download>` click. Filename slugified from `meta.title`.
- **Load** — reads a file via `FileReader`, `JSON.parse`s, runs through `validate()` before rendering — rejects malformed/stale-schema files rather than silently mis-rendering them.
- **Autosave** — persists to `localStorage` key `nebula-studio-autosave` on every change; read back through `validate()` too.

## Sidebar / palette (`palette-panel.js`) — current gap

Renders a **flat text-list**, not thumbnails: each catalog section becomes a labeled group, each entry becomes a card with only the entry name (mono, truncated) and a color-coded text badge for `kind` ("element" cyan / "markup" magenta). The catalog page itself has live `.atlas-entry-preview` divs, but the Studio parser only reads `.atlas-entry-name` and `.atlas-entry-code` — no visual preview of the actual component renders in the sidebar today.

## Known gaps / next phases

No delete, no resize, no inspector panel exist yet — verified by full read of all 11 files, not stubbed anywhere. These are the next round of work (tracked as "Phase 2" in the original plan doc):

- **Phase 2:** per-instance inspector panel (edit attrs/styleOverrides without hand-editing JSON), delete/duplicate, undo/redo, resize/manipulation gizmos on selected instances.
- **Phase 3:** HTML export/codegen — call `renderLayout(doc, bp, offscreenHost, {editable: false})` per breakpoint, serialize to a committable World page fragment.
- **Phase 4:** nesting/containers (rows/columns instead of a flat list), multi-page projects, promote breakpoint constants to real Aether tokens.
- **Visual palette:** render `.atlas-entry-preview` thumbnails in the sidebar instead of the current text+badge list.

---

## Revision History

| Date | Change |
|---|---|
| 2026-07-06 (S198) | MVP built and Playwright-verified end to end: palette parse (41 entries), markup + custom-element drag-drop, breakpoint switching, save-download, zero console errors. |
| 2026-07-06 (S199) | Architecture doc written distilling the plan doc into a stable reference; noted as prep for delete/resize gizmo + visual-palette work. |
