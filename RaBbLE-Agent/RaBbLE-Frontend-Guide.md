# RaBbLE Front-End Guide — Modifying World / Building New Apps

> See `RaBbLE-Agent/RaBbLE-Theme-System.md` for the full Aether + NeBuLA API reference.
> The Atlas (`RaBbLE-World/world/RaBbLE-Catalog.html`) is the living palette — browse it before writing any markup.

---

## The Thin-Assembler Pattern

World is not a framework. It is a thin assembler that:

1. Loads Aether (CSS bundle) and NeBuLA (JS bundle) from CDN.
2. Applies `.rabble-*` classes from Aether to HTML.
3. Mounts `<rabble-*>` custom elements (registered by NeBuLA on load).
4. Writes minimal page-layout and glue JS (data binding, event wiring).

**Apply, don't redefine.** If an Aether component or NeBuLA effect already does something, use it from the framework — never re-implement it inside a page or app. A component is not done until it renders correctly using only framework classes or elements and appears in the Atlas.

**Member responsibilities:**
- Aether owns CSS — all visual classes and design tokens.
- NeBuLA owns rendered effects — canvas rendering, custom elements.
- World (and any app) owns structure and state glue only.

---

## Rules

> Violating these creates drift. If a rule conflicts with a new idea, bring it to the Grimoire first.

- **Palette vars only.** Never use raw hex values. All colors reference `var(--rabble-*)` tokens from Aether.
- **Brand name casing is exact.** `RaBbLE`, `NeBuLA`, `sCoRE`, `sCoRE`, `ScRibLE`. Any element displaying a brand name with `--rabble-font-hero` must also have `text-transform: none` to prevent inheriting uppercase from a parent.
- **No bundler in World.** Files are opened directly in a browser. No build step, no npm run start.
- **No React/Vue/Svelte.** Vanilla JS only. NeBuLA.ui factory pattern for components.
- **Frameworks build, apps don't.** Aether and NeBuLA have build steps. World and standalone apps do not.
- **New Aether classes or NeBuLA effects go in the framework repo, not in a page.** If you need a CSS effect that doesn't exist, add it to Aether. If you need a rendered effect, add it to NeBuLA.
- **Dev workflow:** always `bash ../RaBbLE-Grimoire/spells/dev-serve.sh`. Never run `esbuild watch` or `dev-cdn.js` directly. Pages link to `aether.css` (dev), not `aether.min.css` (prod).
- **Build before committing NeBuLA changes:** `npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`

---

## How to Add a New World Page

### 1. Create the HTML file

Place it at `RaBbLE-World/world/<page-slug>.html`. Copy the head wiring from an existing page (`world/os.html` is a clean reference):

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <title>My Page · RaBbLE</title>

  <!-- 1. Config FIRST — sets RABBLE_AETHER_URL and RABBLE_NEBULA_URL -->
  <script src="js/RaBbLE-config.js"></script>

  <!-- 2. Aether loader — injects CSS bundle from config URL -->
  <script src="js/RaBbLE-aether.js"></script>

  <!-- 3. Page-specific CSS (no hex; Aether vars only) -->
  <link rel="stylesheet" href="css/RaBbLE-theme.css">
  <link rel="stylesheet" href="css/RaBbLE-chrome.css">
  <link rel="stylesheet" href="css/my-page.css">
</head>

<!-- 4. data-page-id matches the entry in RaBbLE-pages.js -->
<body data-page-id="my-page">

  <!-- CRT / ambient overlay stack (standard for all pages) -->
  <div class="rabble-scanlines"></div>
  <div class="rabble-vignette"></div>
  <div class="rabble-chromatic"></div>

  <!-- Page content here using .rabble-* classes from Aether -->

  <!-- NeBuLA loader at end of body — defines <rabble-*> elements -->
  <script src="js/RaBbLE-NeBuLA.js"></script>
  <!-- Page JS after NeBuLA -->
  <script src="js/my-page.js"></script>
</body>
</html>
```

**Key points:**
- `RaBbLE-config.js` MUST be first — it sets `window.RABBLE_AETHER_URL` and `window.RABBLE_NEBULA_URL`.
- `RaBbLE-aether.js` reads `window.RABBLE_AETHER_URL` immediately — must follow config.
- `RaBbLE-NeBuLA.js` reads `window.RABBLE_NEBULA_URL` and injects the bundle — place before any page JS that uses NeBuLA.
- `data-page-id` on `<body>` enables `RaBbLE-page-runtime.js` to mount global nav automatically.

### 2. Register in RaBbLE-pages.js

Add an entry to `world/js/RaBbLE-pages.js`:

```js
{
  id:    'my-page',         // matches <body data-page-id="…">
  title: 'My Page',
  href:  'my-page.html',
  icon:  '◇',
  tags:  ['my-category']
}
```

### 3. Build the markup from the Atlas

Browse `world/RaBbLE-Catalog.html`. Find the components you need; copy their markup snippet. Do not invent new classes — use what exists in Aether. If you need something new, add it to Aether first (see "Add a new component" below).

**Minimal page skeleton using Aether:**

```html
<div class="rabble-container">
  <div class="rabble-panel rabble-border-harmony rabble-stagger-in">
    <h2 class="rabble-section-header rabble-harmony-line">Section Title</h2>
    <div class="rabble-stat-row">
      <span class="rabble-stat-row-label">Field</span>
      <span class="rabble-stat-row-value">Value</span>
    </div>
    <div class="rabble-card rabble-accent-cyan is-raised">
      <div class="rabble-card-title">Card</div>
      <p class="rabble-card-body">Content</p>
    </div>
    <button class="rabble-btn">Action</button>
  </div>
</div>
```

### 4. Mount NeBuLA elements (optional)

After NeBuLA loads, any `<rabble-*>` tag in HTML auto-registers:

```html
<!-- Entity visual -->
<rabble-entity mode="idle" particle-count="120"></rabble-entity>

<!-- Knowledge graph -->
<rabble-graph id="myGraph" style="width:100%;height:500px"></rabble-graph>
<script>
  document.querySelector('#myGraph').setData({ docs: myDocs, kinds: myKinds });
</script>
```

---

## How to Add a New Component or Effect

### Adding a CSS component (Aether)

1. Open `RaBbLE-Aether/assets/components/rabble-components.css`.
2. Add a `.rabble-<name>` rule (and sub-element classes like `.rabble-<name>-<part>`).
3. Use only `var(--rabble-*)` tokens. No raw hex.
4. If it needs animation keyframes, add them to `assets/motion/rabble-motion.css`.
5. Add a catalog entry to `RaBbLE-World/world/RaBbLE-Catalog.html` — the component is not done until it renders there.
6. Run `dev-serve.sh`, confirm in the Atlas.

### Adding a rendered effect (NeBuLA)

1. Add the effect in `RaBbLE-NeBuLA/src/effects/` as a named export following the factory signature: `export function myEffect(target, opts) { … return { start, stop, setParams }; }`.
   - `target` is a sized container div, NOT a canvas — the effect creates its own canvas inside the target.
2. Export it from `src/effects/effects-ns.js`:
   ```js
   export { myEffect } from './my-effect.js';
   ```
3. Build and copy:
   ```bash
   npm run build:iife && cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js
   ```
4. Add a catalog entry to `world/RaBbLE-Catalog.html` showing the effect mounted on a container div.
5. Document it in `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Theme-System.md`.

### Adding a custom element (NeBuLA)

1. Create `src/elements/<name>.js` as a `HTMLElement` subclass; call `customElements.define('rabble-<name>', …)`.
2. Import it in `src/index.js`.
3. Build + copy as above.
4. Catalog entry + Grimoire doc.

---

## How to Build a Standalone RaBbLE App

A page outside World that wants the full system — no clone of World needed.

### 1. Head wiring (CDN)

```html
<head>
  <title>My RaBbLE App</title>
  <!-- Aether CSS — pinned to a specific version -->
  <link rel="stylesheet"
        href="https://aether.joinrabble.world/v0.0.0.1-rc.1/aether.min.css">
</head>
<body>
  <!-- markup using .rabble-* classes -->

  <!-- NeBuLA JS at end of body -->
  <script src="https://nebula.joinrabble.world/v0.0.0.1-rc.1/nebula.iife.js"></script>
  <script>
    // window.NeBuLA is now available
    const sf = NeBuLA.effects.starfield(
      document.querySelector('.hero'),
      { count: 120 }
    );
    sf.start();
  </script>
</body>
```

No bundler needed. No npm. Files open directly in any browser.

### 2. Apply classes and mount elements

- Use `.rabble-*` classes from the Atlas for all visual components.
- Mount `<rabble-entity>`, `<rabble-floor>`, etc. by putting the tag in HTML — NeBuLA registers them on load.
- Use `NeBuLA.effects.*` for canvas effects; always mount on a `position:relative` container div.
- Use `NeBuLA.ui.*` factories for SVG sub-components.

### 3. Colors

All colors from `var(--rabble-*)` palette tokens — never raw hex. The Aether bundle sets all tokens on `:root`. Override `--rabble-accent` per component for themed variants.

### 4. Local development

Point to the dev-serve CDN mock:

```html
<link rel="stylesheet" href="http://localhost:8000/aether/v0.0.0.0/aether.css">
…
<script src="http://localhost:8000/nebula/v0.0.0.0/nebula.iife.js"></script>
```

Run `bash ../RaBbLE-Grimoire/spells/dev-serve.sh` (from anywhere inside the Collective) to start the mock server.

---

## Quick Reference

| Task | File to edit | Note |
|---|---|---|
| Add a page to World | `world/<slug>.html` + `world/js/RaBbLE-pages.js` | See head wiring above |
| Add a CSS class | `RaBbLE-Aether/assets/components/rabble-components.css` | Then Atlas + Grimoire doc |
| Add a motion class | `RaBbLE-Aether/assets/motion/rabble-motion.css` | Add keyframe there too |
| Add an effect | `RaBbLE-NeBuLA/src/effects/` + `effects-ns.js` | Build + copy + Atlas |
| Add a custom element | `RaBbLE-NeBuLA/src/elements/` + `src/index.js` | Build + copy + Atlas |
| Change page content/data | `world/js/RaBbLE-<page>-data.js` | Never in the component JS |
| Change palette | `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md` | Propagates to Aether CSS |
| Flip to local backend | `world/js/RaBbLE-config.js` | The single flip-point |
| Visual check | `bash spells/visual-screenshot.sh --playwright` | After any visual change |
