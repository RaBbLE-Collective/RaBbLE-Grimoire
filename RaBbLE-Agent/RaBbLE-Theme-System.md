# RaBbLE Theme System — API Reference

> **Strategic decision (canonical):** Aether (CSS) and NeBuLA (JS) are THE theme and effects system for all RaBbLE front-end applications. Any RaBbLE app — World, a rablet, a standalone page — gets the full system by linking one CSS bundle and one JS bundle. World is the first/reference consumer, not the owner. The living palette is the Atlas at `RaBbLE-World/world/RaBbLE-Catalog.html`.

Sources verified: `RaBbLE-Aether/assets/components/rabble-components.css`, `assets/motion/rabble-motion.css`, `assets/palette/rabble-palette.css`, `assets/base/rabble-base.css`; `RaBbLE-NeBuLA/src/index.js`, `element.js`, `elements/floor.js`, `elements/graph.js`, `elements/doors.js`, `ui/index.js`, `effects/effects-ns.js`, `effects/starfield.js`, `effects/deepfield.js`.

---

## CDN Consumption

### Production bundles

| Bundle | URL |
|---|---|
| Aether CSS | `https://aether.joinrabble.world/v0.0.0.1-rc.1/aether.min.css` |
| NeBuLA JS | `https://nebula.joinrabble.world/v0.0.0.1-rc.1/nebula.iife.js` |

### Local dev (flip-point)

`RaBbLE-World/world/js/RaBbLE-config.js` auto-detects `localhost` and sets:

```
RABBLE_AETHER_URL → /aether/v0.0.0.0/aether.css
RABBLE_NEBULA_URL → /nebula/v0.0.0.0/nebula.iife.js
```

These paths are served by `spells/dev-serve.sh` (the CDN mock). Start with `bash ../RaBbLE-Grimoire/spells/dev-serve.sh`, never run `esbuild` or `dev-cdn.js` directly.

### Loaders

World uses two loader scripts that inject the bundles and monitor for failures:

| File | Role |
|---|---|
| `world/js/RaBbLE-aether.js` | Injects Aether `<link>`, marks `<html data-aether="failed">` on error |
| `world/js/RaBbLE-NeBuLA.js` | Injects NeBuLA `<script>`, exposes failure banner |

In production `RABBLE_NEBULA_URL` is read at runtime. In the IIFE build the global is `window.NeBuLA` (capital N, capital B, capital U, capital L, capital A — always exact).

### Atlas

Browse `RaBbLE-World/world/RaBbLE-Catalog.html` for every live component and effect rendered in isolation. If it is not in the Atlas it is not yet a framework part.

---

## Aether Design Tokens

All tokens are CSS custom properties set on `:root`. Never use raw hex — always reference a `var(--rabble-*)` token.

### Color palette

| Token | Role |
|---|---|
| `--rabble-magenta` | Hot Magenta — primary signature |
| `--rabble-cyan` | Electric Cyan — secondary neon |
| `--rabble-violet` | Soft Violet — tertiary accent |
| `--rabble-pink` | Outrun Pink — grid/horizon |
| `--rabble-void` | Deepest void — boot, full-bleed |
| `--rabble-bg` | Primary background |
| `--rabble-surface` | Elevated surface — panels, sidebars |
| `--rabble-raised` | Cards, inputs, popups |
| `--rabble-border` | Inactive borders, dividers |
| `--rabble-text` | Primary readable text |
| `--rabble-muted` | Secondary, dimmed |
| `--rabble-dimmer` | Tertiary — barely visible |
| `--rabble-red` | Error / urgent |
| `--rabble-green` | Success / clean |
| `--rabble-yellow` | Warning / staged |

### Component accent

`--rabble-accent` is the per-element accent var (default: `--rabble-magenta`). Override inline or via `.rabble-accent-*` modifier class. Used by cards, badges, panels, overlays.

### Neon system (Modular Neon)

| Token | Role |
|---|---|
| `--aether-neon` | Intensity dial 0.0–1.0. Scale all glow blur/opacity. Registered `@property`. |
| `--aether-grad-a` | Primary gradient pole (default: magenta). Change to re-skin all signature gradients. |
| `--aether-grad-b` | Secondary gradient pole (default: cyan). |

Switch to low-glow mode: `document.documentElement.dataset.aether = 'muted'` (sets `--aether-neon: 0.2`, defined in `assets/theme/rabble-theme.css`).

### Pre-computed glow shadows

Scale automatically with `--aether-neon`:

| Token family | Sizes |
|---|---|
| `--rabble-glow-magenta-sm/md/lg` | 6 / 14 / 28 px blur |
| `--rabble-glow-cyan-sm/md/lg` | 6 / 14 / 28 px blur |
| `--rabble-glow-violet-sm/md` | 6 / 14 px blur |

### Typography

| Token | Value |
|---|---|
| `--rabble-font-mono` | 'Share Tech Mono', 'Space Mono', monospace |
| `--rabble-font-ui` | 'Exo 2', 'Rajdhani', sans-serif |
| `--rabble-font-hero` | 'Orbitron', 'Exo 2', sans-serif — OS lockups, wordmark, brand crawls |
| `--rabble-fs-hero..nano` | Fluid type scale: hero clamp(48px,7vw,96px) … nano 10px |
| `--rabble-tracking-display/eyebrow/ui/body/mono` | Letter spacing tokens |
| `--rabble-lh-display/heading/body` | Line height tokens |

### Spacing, radius, motion

| Family | Tokens |
|---|---|
| Spacing | `--rabble-space-1..8` → 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 px |
| Radius | `--rabble-radius-sm/md/lg/xl/pill` → 4 / 8 / 12 / 20 / 9999 px |
| Transitions | `--rabble-t-fast/med/slow` → 120 / 220 / 420 ms; `--rabble-ease-snap`, `--rabble-ease-glow` |

### Glass and gradient shortcuts

| Token | Description |
|---|---|
| `--rabble-glass-78` | `color-mix(in srgb, --rabble-surface 78%, transparent)` |
| `--rabble-glass-80` | `color-mix(in srgb, --rabble-raised 80%, transparent)` |
| `--rabble-gradient-primary` | 135deg grad-a → violet |
| `--rabble-gradient-scan` | 90deg grad-a → grad-b |
| `--rabble-gradient-holo` | 90deg 4-stop grad-a → grad-b → violet → grad-a |

### Harmony / motion tokens

| Token | Role |
|---|---|
| `--harmony-angle` | Registered `@property <angle>` — drives `harmony-spin` conic gradient |
| `@keyframes harmony-spin` | Animates `--harmony-angle` 0→360deg (uses by `.rabble-border-harmony`) |
| `@keyframes harmony-scroll` | Scrolls gradient left-right (used by `.rabble-harmony-line`) |
| `@keyframes harmony-glow` | Cycles box-shadow through cyan→violet→magenta (used by `.rabble-border-harmony`) |

---

## Aether Classes

### Surfaces

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-panel` | `<div class="rabble-panel rabble-border-harmony">` | Glass container with atmospheric glow; pair with `.rabble-border-harmony` for the conic ring |
| `.rabble-glass` | `<div class="rabble-glass">` | Frosted glass — `backdrop-filter: blur(12px)` |
| `.rabble-glass-heavy` | `<div class="rabble-glass-heavy">` | Heavy glass — blur 20px, nearly opaque background |
| `.shell` | `<div class="shell">` | Full-viewport 100svh layout grid container |
| `.rabble-page` | `<div class="rabble-page">` | Full-page wrapper with `--rabble-bg` and font |

### Cards

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-card` | `<div class="rabble-card rabble-accent-cyan">` | Member/collective card with left accent stripe. Uses `--rabble-accent`. |
| `.is-flat` | `<div class="rabble-card is-flat">` | No elevation shadow |
| `.is-raised` | `<div class="rabble-card is-raised">` | Extra lift + accent glow |
| `.is-active` | `<div class="rabble-card is-active">` | Accent-tinted background + stronger glow |
| `.rabble-card-title` | `<h3 class="rabble-card-title">` | Card heading |
| `.rabble-card-body` | `<p class="rabble-card-body">` | Card body text |
| `.rabble-accent-magenta/cyan/violet/pink/green/yellow/red` | `class="… rabble-accent-cyan"` | Set `--rabble-accent` to a named palette color |

### Controls

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-btn` | `<button class="rabble-btn">Label</button>` | Primary gradient button with shimmer sweep |
| `.rabble-btn-ghost` | `<button class="rabble-btn rabble-btn-ghost">` | Transparent ghost button |
| `.rabble-btn-cyan` | `<button class="rabble-btn rabble-btn-cyan">` | Cyan gradient variant |
| `.rabble-btn-pill` | `<button class="rabble-btn rabble-btn-pill">` | Pill border-radius modifier |
| `.is-secondary` | `<button class="rabble-btn is-secondary">` | Muted/ghost secondary button |
| `.rabble-btn-sm` / `.rabble-btn-lg` | `class="rabble-btn rabble-btn-sm"` | Size modifiers |
| `.rabble-input` | `<input class="rabble-input">` | Monospace text input; add `.typing` for cyan active border |
| `.rabble-field-label` | `<label class="rabble-field-label">` | Uppercase tracked form label |
| `.rabble-progress` / `.rabble-progress-fill` | `<div class="rabble-progress"><div class="rabble-progress-fill" style="width:60%">` | 2px progress bar |

### Navigation

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-nav` | `<nav class="rabble-nav">` | Horizontal navbar with gradient bottom border |
| `.rabble-nav-links` | `<ul class="rabble-nav-links">` | Nav link list; `a.active` → magenta |
| `.rabble-statusbar` | `<div class="rabble-statusbar">` | Waybar-style 3-zone status bar |
| `.rabble-statusbar-zone` | `<div class="rabble-statusbar-zone">` | Left / center / right zone inside statusbar |
| `.rabble-dock` | `<div class="rabble-dock">` | Bottom dock; 48px collapsed → add `.is-open` → 65vh |
| `.rabble-dock-item` | `<div class="rabble-dock-item">` | Bar-strip row inside dock |

### Chat / Log

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-log` | `<div class="rabble-log">` | Scrollable monospace log container |
| `.rabble-log-line` | `<div class="rabble-log-line is-entity">` | Single log entry; roles `.is-entity` / `.is-system` / `.is-user` |
| `.rabble-log-who` | `<span class="rabble-log-who">◈ RABBLE</span>` | Role sigil inside a log line |
| `.rabble-transmission` | `<div class="rabble-transmission">` | Single-line truncating output (bar-mode dock) |
| `.rabble-chat` | `<div class="rabble-chat">` | Chat bubble container |
| `.rabble-chat-bubble` | `<div class="rabble-chat-bubble is-user">` | Bubble; `.is-user` right-aligned cyan, `.is-entity` left-aligned |
| `.rabble-askbox` | `<div class="rabble-askbox">` | Ask-box container (label + input row) |
| `.rabble-askbox-input` | `<div class="rabble-askbox-input">` | Accent-bordered input row; focus glow via `focus-within` |

### Overlays

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-overlay` | `<div class="rabble-overlay">` | Full-screen glass backdrop, flex-centered |
| `.rabble-overlay-login` | `<div class="rabble-overlay"><div class="rabble-overlay-login">` | Centered login panel (440px max) with accent border glow |
| `.rabble-overlay-nav` | `<div class="rabble-overlay rabble-overlay-nav">` | Full-screen nav overlay |
| `.rabble-overlay-log` | `<div class="rabble-overlay rabble-overlay-log">` | Full-height scrollable log |
| `.rabble-overlay-ios` | `<div class="rabble-overlay rabble-overlay-ios">` | Bottom-anchored iOS install prompt |
| `.rabble-whisper` | `<div class="rabble-whisper is-active">` | Fixed right-side tooltip (`.is-active` → slide in) |

### Motion / Effects

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-border-harmony` | `<div class="rabble-panel rabble-border-harmony">` | Spinning conic-gradient ring border; `@property` — only angle animates |
| `.rabble-harmony-line` | `<h2 class="rabble-section-header rabble-harmony-line">` | Scrolling cyan→violet→magenta 1px underline |
| `.rabble-glitch-veil` | `<div class="rabble-glitch-veil is-active">` | Fixed overlay CSS glitch; toggle `.is-active` |
| `.rabble-text-shudder` | `<span class="rabble-text-shudder is-active">RaBbLE</span>` | Chromatic RGB text split; `.fast`/`.slow` speed variants |
| `.rabble-horizon-glow` | `<hr class="rabble-horizon-glow">` | Glowing 1px rule; accent-aware via `--rabble-accent` |
| `.rabble-tint-radial` | `<div class="rabble-card rabble-tint-radial">` | Radial accent wash via `::after`; tune origin with `--rabble-tint-origin` |
| `.rabble-reveal-3d` | `<div class="rabble-reveal-3d fast">` | 3D perspective flip-in entrance; `.fast` / `.slow` |
| `.rabble-stagger-in` | `<div class="rabble-stagger-in fast">…children…</div>` | Container; children stagger in at 80ms steps (up to 8) |
| `.rabble-sigil` | `<span class="rabble-sigil is-thinking">◈</span>` | Entity state glyph: idle breathe / `.is-thinking` violet / `.is-speaking` magenta |

### CRT / Ambient

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-scanlines` | `<div class="rabble-scanlines">` | Fixed fine CRT horizontal scanlines (z-index 10) |
| `.rabble-vignette` | `<div class="rabble-vignette">` | Fixed edge-darkening radial overlay (z-index 9) |
| `.rabble-chromatic` | `<div class="rabble-chromatic">` | Fixed magenta-cyan color bleed (z-index 11) |
| `.rabble-floor` | `<div class="rabble-floor">` | CSS-only outrun perspective grid floor |
| `.rabble-horizon` | `<div class="rabble-horizon">` | Neon horizon line at the vanishing point |
| `.rabble-crt-sweep` | `<div class="rabble-crt-sweep">…</div>` | `::after` CRT sweep animation on any container |
| `.rabble-grid-bg` | `<div class="rabble-grid-bg">` | Animated violet grid background |

### Brand / Typography

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-brand-flow` | `<span class="rabble-brand-flow">RaBbLE</span>` | Animated cyan↔magenta wordmark (Orbitron, weight 900, `text-transform:none`); `.slow`/`.fast` |
| `.rabble-brand-text` | `<span class="rabble-brand-text">` | Animated holographic gradient text (Exo 2, uppercase) |
| `.rabble-brand-text-2` | `<span class="rabble-brand-text-2">` | Static two-color gradient text |
| `.rabble-eyebrow` | `<p class="rabble-eyebrow">` | Cyan uppercase tracked eyebrow label |
| `.rabble-display` | `<h1 class="rabble-display">` | Display heading — heavy, tracked, uppercase |
| `.rabble-mono-label` | `<span class="rabble-mono-label">` | Monospace micro label |
| `.rabble-tagline` | `<p class="rabble-tagline">` | Violet Orbitron tagline |
| `.rabble-cursor` | `<span class="rabble-cursor">` | Blinking 6px terminal cursor |

### Stat / Status

| Class | Snippet | Purpose |
|---|---|---|
| `.rabble-stat-row` | `<div class="rabble-stat-row">` | Label:value data pair (space-between flex) |
| `.rabble-stat-row-label` | `<span class="rabble-stat-row-label">` | Muted uppercase mono label |
| `.rabble-stat-row-value` | `<span class="rabble-stat-row-value">` | Right-aligned mono value |
| `.rabble-section-header` | `<h3 class="rabble-section-header">` | Cyan monospace section heading |
| `.rabble-badge` | `<span class="rabble-badge rabble-accent-violet">LIVE</span>` | Inline accent pill |
| `.rabble-status-pill` | `<div class="rabble-status-pill">` | Status chip with dot |
| `.rabble-status-dot` | `<span class="rabble-status-dot">` | Pulsing 5px dot; `.magenta` / `.violet` / `.offline` |
| `.rabble-tag` | `<span class="rabble-tag rabble-tag-cyan">beta</span>` | Tag chip; `-cyan` / `-violet` / `-green` variants |
| `.rabble-rail` / `.rabble-rail-fill` | `<div class="rabble-rail"><div class="rabble-rail-fill" style="width:40%">` | 2px progress rail |

### Layout Utilities

| Class | Purpose |
|---|---|
| `.rabble-container` | Max-width 1280px centered, fluid padding |
| `.rabble-grid-2 / -3 / -auto` | Responsive CSS grids (collapse to 1-col at 600px) |
| `.rabble-flex / -col / -center` | Flex display helpers |
| `.rabble-gap-sm / -md / -lg` | Gap 8 / 16 / 24 px |
| `.rabble-hide-mobile / -tablet` | Responsive visibility |
| `.rabble-sr-only` | Accessible screen-reader-only |
| `.applet` | WM tile with conic ring border; `.wm-active` for focused state |

### Animation Utilities (from rabble-motion.css)

| Class | Animation |
|---|---|
| `.rabble-anim-fade-in` | `rabble-fade-in` 0.25s |
| `.rabble-anim-rise` | `rabble-rise` 0.4s |
| `.rabble-anim-expand` | `rabble-expand` 0.3s |
| `.rabble-anim-float` | `rabble-float` 3s infinite |
| `.rabble-anim-holo` | `rabble-holo` 6s infinite |
| `.rabble-anim-flicker` | `rabble-neon-flicker` 4s infinite |
| `.rabble-anim-blink` | `rabble-blink` 1.1s step-end |
| `.rabble-anim-status` | `rabble-status-pulse` 2s infinite |
| `.rabble-anim-glow-m / -c / -v` | Magenta / cyan / violet glow pulse 2.5s |
| `.rabble-anim-resonance` | Hue-rotate + brightness wave 8s |
| `.rabble-anim-glitch` | Clip-path glitch steps 0.4s |

---

## NeBuLA Custom Elements

Global: `window.NeBuLA`. All custom elements are registered on NeBuLA script load.

### `<rabble-entity>`

Canvas2D entity renderer: particle field + twin elliptic eyes + portal arcs. Three stacked canvases (field, glow, entity).

**Attributes**

| Attr | Default | Description |
|---|---|---|
| `mode` | `'idle'` | `'idle'` or `'boot'` |
| `particle-count` | `150` | Capped at 150 desktop / 100 mobile |
| `overscan` | `2.35` | Canvas-to-host size multiplier |
| `interactive` | `true` | Mouse tracking |
| `show-waveform` | `false` | Audio waveform overlay |
| `fallback-width` | `460` | px when host has no size |
| `fallback-height` | `320` | px when host has no size |

**Methods**

| Method | Description |
|---|---|
| `setEntityState(s)` | Entity state string — drives rendering style |
| `injectEyeJolt(dx, dy)` | Impulse the eye saccade |
| `setEntropy(val)` | Set particle entropy level |
| `triggerBoot()` | Play boot animation |
| `pause()` / `resume()` | Pause/resume render loop |
| `setEyeConfig(cfg)` | Override eye geometry |
| `setParticleConfig(cfg)` | Override particle parameters |
| `setPortalVisible(visible)` | Show/hide portal arcs |
| `getSnapshot()` | Return canvas snapshot |

**Events**

| Event | Detail |
|---|---|
| `entity-ready` (bubbles) | Element ready |
| `rabble:entity-ready` (window) | Same, on window |

**Runtime properties written to `window.NeBuLA`**

`_instance`, `particleCount`, `glowScale`, `renderDpr`

---

### `<rabble-floor>`

Three.js Grimoire floor: entity eyes + portal arcs + force-directed knowledge graph. Three.js r160 lazy-loaded from CDN.

**Attributes (reactive)**

| Attr | Description |
|---|---|
| `zoom` | Camera zoom factor |
| `pan-x` | Camera pan X (world units) |
| `pan-y` | Camera pan Y (world units) |

**Methods**

| Method | Description |
|---|---|
| `setData({ docs, kinds, seals, memberUV })` | Load graph data (docs: `[{ id, name, owner, summary }]`) |
| `focusOwner(ownerKey)` | Pan + zoom to owner cluster |
| `traceOwner(ownerKey)` | Select representative node for owner |
| `narrateRandom(ownerKey?)` | Select a random node; returns `doc.summary` or `doc.name` |
| `ownerScreenPos(ownerKey)` | `{ sx, sy }` screen position of owner centroid |
| `resetView()` | Reset camera |
| `owners()` | List owner keys present in graph |
| `centerScreenPos()` | Screen pos of world origin |
| `onSelect(cb)` | Register `cb(ownerKey)` callback |

**Events**

| Event | Detail |
|---|---|
| `rabble-floor-ready` | Scene mounted |
| `rabble-floor-select` | `{ owner: ownerKey }` on node selection |

---

### `<rabble-graph>`

Three.js knowledge graph (entity eyes + portals + force-directed graph). Identical scene to `<rabble-floor>` but with full select/deselect event system.

**Methods**

| Method | Description |
|---|---|
| `setData({ docs, kinds, seals, memberUV })` | Load graph data |
| `zoomIn()` / `zoomOut()` | Zoom camera |
| `resetView()` | Reset camera + deselect |
| `focusOwner(ownerKey)` | Pan + zoom to owner cluster |
| `traceOwner(ownerKey)` | Select representative node |
| `narrateRandom(ownerKey?)` | Select random node; returns doc |
| `ownerScreenPos(ownerKey)` | `{ sx, sy }` |
| `centerScreenPos()` | `{ sx, sy }` |
| `owners()` | Owner keys in graph |

**Events**

| Event | Detail |
|---|---|
| `rabble-graph-ready` | Scene mounted |
| `rabble-graph-select` | `{ doc, kind, seal, col }` |
| `rabble-graph-deselect` | Empty detail |

---

### `<rabble-doors>`

CSS orbit portal doors. N doors on elliptical paths around a central core (squashed cosmic disc). Depth via z-index / scale / opacity. Colors from Aether palette CSS vars (never raw hex).

**Attributes (reactive)**

| Attr | Default | Description |
|---|---|---|
| `count` | `6` | Number of doors (ignored once `setDoors()` supplies a list) |
| `speed` | `1.0` | Orbit speed factor |

**Methods**

| Method | Description |
|---|---|
| `setDoors(portals[])` | `portals`: `[{ id, name, url, glyph, accent, organ }]` where `accent` is e.g. `'--magenta'` (bare CSS var name) |
| `setSpeed(factor)` | Override orbit speed |
| `setEntityState('idle'|'resonant'|'glitch')` | `'glitch'` adds wobble noise to orbit |

**Events**

| Event | Detail |
|---|---|
| `rabble-doors-enter` | `{ id, name, url }` on pointer/focus into door |
| `rabble-doors-leave` | Pointer/focus left door |
| `rabble-doors-trace` | `{ count }` when every door has been visited |

---

## NeBuLA UI Factories (`window.NeBuLA.ui.*`)

DOM/SVG factory functions; no custom elements required.

| Factory | Returns | Description |
|---|---|---|
| `createEntityMini(entityId, { size })` | `{ el, destroy() }` | Scaled SVG mini-entity: particle haze + twin orb-eyes. `entityId` one of `e-rabble / e-aether / e-nebula / e-score / e-scribble / e-os`. |
| `createGrimoireEye(opts)` | `{ el, setColor(c), setSummoning(b), triggerBlink(), startBlinkLoop():()=>void, destroy() }` | SVG Watching Entity eye: random blink schedule, pupil contraction + color shift during summoning. `opts.color` default `#bf5fff`. |
| `createAmbientEye(opts)` | `{ el, …controls, destroy() }` | Slow ambient resting eye: pupil pulse + iris drift, no interaction. |
| `createGrimoireRing(opts)` | `{ el, setColor(c), setCenter(el), setSummoning(b), destroy() }` | Animated SVG rune ring: 3 concentric layers at different spin speeds, 12 unicode runes. Color via `--ring-color`. |

---

## NeBuLA Effects (`window.NeBuLA.effects.*`)

### Factory effects — `effect(target, opts) → { start(), stop(), setParams(opts) }`

**`target` MUST be a sized container element with `position:relative` (or `absolute`/`fixed`). The effect injects its own `<canvas style="position:absolute;inset:0;pointer-events:none">` into the target. Passing a `<canvas>` element produces a silent blank — no error.**

```html
<div class="fx" style="position:relative;width:360px;height:240px"></div>
<script>
  NeBuLA.effects.starfield(document.querySelector('.fx'), { count: 180 }).start();
</script>
```

| Name | Key opts | Description |
|---|---|---|
| `starfield` | `count` (180), `drift` (1.0), `depthLayers` (3), `palette` | Depth-layered Canvas2D star field: parallax, cursor-reactive, subtle constellation lines, twinkle. Mobile auto-caps at 100 stars. Palette resolved from Aether CSS vars at runtime. |
| `streaks` | `spawnProb` (0.0022), `decay` (0.016), `palette`, `glitch` | Rare passing signal transmissions — velocity + decay line segments. `glitch: true` raises spawn rate ×9. |
| `constellation` | `palette` | Lines drawn from star positions to cursor (reach radius ~130px, per-line alpha fades with distance). Depends on star positions being available in the render loop. |
| `haze` | `palette` | 3 drifting radial blob hazes rendered at 1/8 resolution; CSS upscales for free GPU blur. Violet / magenta / cyan blobs, repaint every 4th frame. |

### Class effects (legacy API, `new` instantiation)

| Name (export) | Class | Description |
|---|---|---|
| `entropy` | `EntropyShader` | Entropy shader effect |
| `ambientField` | `AmbientField` | Ambient particle field |
| `attractor` | `EntropyAttractor` | Entropy attractor |
