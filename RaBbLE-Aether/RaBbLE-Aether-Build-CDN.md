# RaBbLE-Aether Build & CDN Distribution

```
spark ~ aether >> build system and cdn delivery layer // %AETHER_BUILD_SPEC%
```

> **Part of Episode 1:** Aether ships as a distributable CSS bundle via CDN, alongside NeBuLA. Members consume it without local copies.

---

## Overview

Aether (the design system) is built and distributed separately from member repos. It is the single source of visual identity for the entire Collective.

**Delivery model:**
- Members load Aether CSS from CDN
- No local copies in member repos
- Versioned per Five-Es: `v0.0.0.0` (pre-Episode-1), `v0.0.0.1` (after Episode 1 airs)
- Sourcemaps included for debugging

---

## Build System

### Process

```
src/assets/*.css  →  esbuild/concat  →  dist/aether.min.css  →  CDN versioning
```

**Build steps:**

1. Concatenate CSS files in order:
   - `assets/palette/rabble-palette.css` (tokens, color vars)
   - `assets/motion/rabble-motion.css` (keyframes, transitions)
   - `assets/components/rabble-components.css` (all UI components)

2. Minify and sourcemap with esbuild

3. Output to `dist/`:
   - `aether.min.css` (minified, production)
   - `aether.min.css.map` (sourcemap for debugging)

### NPM Scripts

```json
{
  "scripts": {
    "build": "npx esbuild src/assets/palette.entry.css --bundle --minify --outfile=dist/aether.min.css --sourcemap=linked",
    "build:dev": "npx esbuild src/assets/palette.entry.css --bundle --outfile=dist/aether.css --sourcemap",
    "build:watch": "npx esbuild src/assets/palette.entry.css --bundle --outfile=dist/aether.css --watch"
  }
}
```

### Entry Point

Create `src/assets/palette.entry.css` as the bundle entry:

```css
@import './palette/rabble-palette.css';
@import './motion/rabble-motion.css';
@import './components/rabble-components.css';
```

This single file is what esbuild bundles.

---

## Versioning

Follow Five-Es: `v{Epoch}.{Evolution}.{Echo}` for CDN paths (Episode/Event omitted).

**Current:** `v0.0.0`  
**Next:** `v0.0.0.1` (when Episode 1 airs)

### CDN Paths

```html
<!-- Pre-Episode-1 -->
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css">

<!-- Post-Episode-1 -->
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0.1/aether.min.css">
```

### Deployment

After `npm run build`:

```bash
# Copy to CDN host (Cloudflare Workers, S3, etc.)
cp dist/aether.min.css* https://cdn.joinrabble.world/aether/{VERSION}/

# Tag in git
git tag -a "aether-v0.0.0" -m "Aether v0.0.0 — pre-Episode-1 design system"
git push --tags
```

---

## Usage in Members

### From World

```html
<!DOCTYPE html>
<html>
<head>
  <!-- Load Aether design system — all theme tokens, components, motion -->
  <link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css">
  
  <!-- World's structural CSS (layout, page-specific) -->
  <link rel="stylesheet" href="world/css/RaBbLE-landing.css">
</head>
<body>
  <!-- Use Aether classes — never duplicate component styles -->
  <button class="rabble-btn rabble-btn-primary">Click me</button>
  <div class="rabble-card">Content</div>
</body>
</html>
```

### From New Pages

No CSS duplication needed — Aether classes cover all UI:

```html
<!-- Copy this template for new pages -->
<link rel="stylesheet" href="https://cdn.joinrabble.world/aether/v0.0.0/aether.min.css">

<h1 class="rabble-brand-flow">New Feature</h1>
<p class="rabble-eyebrow">Subtitle here</p>
<button class="rabble-btn rabble-btn-cyan">Action</button>
```

### CSS Variable Overrides

If a page needs theme tweaks (rare), override CSS variables:

```css
:root {
  --rabble-magenta: #ff0080;  /* override palette */
}
```

Do NOT modify component styles. If a component doesn't exist in Aether, propose it to the Grimoire.

---

## API Reference

All Aether classes and their usage are documented in `rabble-components.css`. Key classes:

| Class | Purpose |
|---|---|
| `.rabble-btn`, `.rabble-btn-primary`, `.rabble-btn-cyan` | Buttons |
| `.rabble-card` | Card container |
| `.rabble-brand-flow` | Orbitron mixed-case animated branding |
| `.rabble-grid-2`, `.rabble-grid-3`, `.rabble-grid-auto` | Responsive grids |
| `.rabble-glass`, `.rabble-glass-heavy` | Frosted glass surfaces |
| `.rabble-status-pill`, `.rabble-status-dot` | Status indicators |
| `.rabble-eyebrow`, `.rabble-display`, `.rabble-mono-label` | Typography utilities |

See `src/assets/components/rabble-components.css` for full component library.

---

## Epoch 0 → 1 Transition

**Before Episode 1:** Members use local Aether copies (development)  
**After Episode 1 airs:** Members use CDN-delivered v0.0.0.1  
**No breaking changes:** CSS API stays stable across Episodes 1–3 (within same Echo)

---

```
spark ~ aether >> build and cdn layer spec complete, implementation ready // %AETHER_BUILD_SPEC%
```
