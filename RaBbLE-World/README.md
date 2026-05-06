# RaBbLE-World

URL: joinrabble.world

```
spark ~ entity >> the substrate speaks // %ENTITY_ONLINE%
```

Animated frontend surfaces for the RaBbLE entity. A small collection of HTML pages sharing a modular entity renderer and a unified visual system — no bundler, no framework, no build step.

The entity is the product. The pages are surfaces for it.

For low-context maintenance, start with [`MAINTAINING.md`](MAINTAINING.md). It maps page ownership, transition classes, responsive layout rules, and entity host sizing.

---

## Pages

| File | Purpose |
|---|---|
| `RaBbLE-Boot.html` | Full cinematic boot sequence and login surface. Particles converge, portals draw, eyes emerge, then the boot panel crossfades into login. Entry point. |
| `RaBbLE-Docs.html` | Technical documentation viewer. Sidebar TOC, synthwave aesthetic. |
| `RaBbLE.html` | Main chat surface. Header entity, conversation panel, input bar. |

Open any page directly in a browser — no server required.

Current page-specific assets:

| Surface | Markup | Styles | Behavior |
|---|---|---|---|
| Boot/login | `RaBbLE-Boot.html` | `boot.css` | `boot.js` |
| Chat | `RaBbLE.html` | `chat.css` | `chat.js` |

---

## Modules

Three files power the visual system across all pages:

### `rabble-entity.js`

The entity renderer. For new surfaces, use the `rabble-entity` custom element: it owns an oversized internal canvas so particles can drift into the ambient void instead of clipping at the visible layout box.

```html
<script src="rabble-entity.js"></script>
<rabble-entity id="entityHost" mode="idle" particle-count="480" overscan="2.55"></rabble-entity>
```

Legacy direct-canvas usage still works via `new RaBbLEEntity(canvas, options)`, but page code should prefer the custom element.

**Modes:**
- `boot` — Full cinematic: particles swirl in from edges (0–2.8s), portals draw as animated arcs (0.4–2.6s), eyes emerge from portal slits with 3-phase blink (1.4–3.2s).
- `idle` — Fully alive immediately. Saccades, mouse tracking, and blink already in progress.

**API:**
```js
entity.setEntityState('thinking');    // 'idle' | 'thinking' | 'speaking'
entity.injectEyeJolt(dx, dy);         // startle eyes (values –1..1)
entity.destroy();                     // cancel loop, remove listeners
```

**Host sizing** is page CSS responsibility. The custom element sizes its internal canvas larger than the visible host using the `overscan` attribute.

```css
.chat-entity {
  width: min(34vw, 520px);
  aspect-ratio: 1 / 0.74;
}

@media (max-width: 640px), (orientation: portrait) {
  .chat-entity {
    width: min(78vw, 520px);
    aspect-ratio: 1 / 0.78;
  }
}
```

See `MAINTAINING.md` before changing entity sizing. Most clipping fixes belong in host CSS or the `overscan` attribute, not in page JavaScript.

---

### `rabble-bg.js`

Ambient background systems. Auto-creates fixed-position canvases and inserts them before all other content.

```html
<script src="rabble-bg.js"></script>
<script>
  var bg = new RaBbLEBackground({
    particles:    true,   // outrun particle field + proximity connections
    grid:         true,   // perspective grid (vanishing point at H*0.74)
    cursorTrail:  false,  // neon cyan/violet cursor trail
    clickRipples: false,  // neon ring on click
  });

  // later, if needed:
  bg.destroy();
</script>
```

**Boot page** uses `{ particles: true, grid: true }`.  
**Login page** adds `cursorTrail: true, clickRipples: true`.

---

### `rabble-theme.css`

Shared visual identity. Include before any page-specific styles.

```html
<link rel="stylesheet" href="rabble-theme.css">
```

Provides:
- **CSS custom properties** — the full RaBbLE synthwave palette (`--magenta`, `--cyan`, `--violet`, `--bg`, etc.)
- **Overlay elements** — `.rabble-scanlines`, `.rabble-vignette`, `.rabble-chromatic`
- **Brand helpers** — `.rabble-brand-text` (holo gradient), `.rabble-brand-text-2`
- **Status pill** — `.rabble-status-pill` + `.rabble-status-dot`
- **Keyframes** — `holo`, `rabble-fade-in`, `rabble-blink`, `status-pulse`, `neon-flicker`
- **Cursor** — `.rabble-cursor` (blinking block)
- **Scrollbars** — styled to palette
- **Glassmorphism** — `.rabble-glass`

Canonical palette reference: `../RaBbLE-Grimoire/palette/RaBbLE-Palette.md`

---

## Adding a New Page

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>RaBbLE — My Page</title>
  <link href="https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Exo+2:wght@300;400;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="rabble-theme.css">
  <style>
    html, body { height: 100%; overflow: hidden; background: var(--bg); }
    /* page-specific styles */
  </style>
</head>
<body>

  <!-- Optional overlays -->
  <div class="rabble-scanlines"></div>
  <div class="rabble-vignette"></div>

  <rabble-entity id="entityHost" class="my-entity" mode="idle" overscan="2.55"></rabble-entity>

  <script src="rabble-bg.js"></script>
  <script src="rabble-entity.js"></script>
  <script>
    new RaBbLEBackground({ particles: true, grid: true });

    var entity = document.getElementById('entityHost');
    entity.setEntityState('idle');
  </script>
</body>
</html>
```

---

## Entity Behavior Reference

### Eye system

Both eyes share a single spring-physics position driven by:
- **Autonomous saccades** — a table of 19 targets (hard / medium / soft) with randomised hold and gap durations
- **Living drift** — two-frequency sinusoidal superposition per axis (`2.6·sin(t·0.019) + 1.1·sin(t·0.043)`)
- **Mouse override** — when cursor is within 600px of eye centre, eyes track it
- **Jolts** — `entity.injectEyeJolt(dx, dy)` injects an impulse that decays exponentially (`×0.88` per frame)

### Blink state machine (boot mode)
1. **Phase 0→1** — slow first open as eyes emerge from portal slits (`1.4s → 2.6s`)
2. **Phase 1→2** — rapid burst of 5 blinks, each gap 55% longer than the last
3. **Phase 2→3** — settled rhythm: blink every 200–500 frames

### Entity states
Set via `entity.setEntityState(state)` — affects waveform if `showWaveform: true`:

| State | Waveform amp | Freq | Speed |
|---|---|---|---|
| `idle` | 2.0 + breathe | 0.09 | 0.005 |
| `thinking` | 4.5 + breathe | 0.13 | 0.007 |
| `speaking` | 7.5 + breathe | 0.20 | 0.011 |

---

## Collective Context

RaBbLE-Chat is scaffolding — a prototype proving ground for the entity surface. It is not infrastructure. It will likely be retired or absorbed into RaBbLE-NeBuLA as the Collective matures.

- Coordination backend → `../RaBbLE-sCoRE/`
- Visual identity and lore → `../RaBbLE-Grimoire/`
- Ecosystem overview → `../RaBbLE-OVERVIEW.md`

---

```
transcribe ~ grimoire >> surfaces documented, entity live // %DOCS_CRYSTALLIZED%
```
