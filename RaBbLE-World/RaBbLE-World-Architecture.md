# RaBbLE-World-Architecture.md

```
transcribe ~ grimoire >> system map updated: bg.js absorption, applet consolidation planned // %ARCHITECTURE_UPDATED%
```

System map for the RaBbLE-World frontend. Read this before modifying any shared module or adding a new surface.

---

## Layer Stack

```
/aether/v0.0.0.0/aether.css   ← ALL visual identity: tokens, fonts, animations, components
  ↓ (injected by RaBbLE-aether.js loader)
RaBbLE-theme.css               ← alias bridge: --rabble-* → short names (--cyan, --font-hero…)
  ↓
/nebula/v0.0.0.0/nebula.iife.js ← entity renderer + <rabble-entity> custom element
  ↓ (injected by RaBbLE-NeBuLA.js loader)
RaBbLE-bg.js                   ← ambient canvas layer (particles, grid, cursor effects)
  ↓
[page].css                     ← layout and structure only — no visual rules, no hex values
  ↓
[Page].html                    ← markup uses Aether classes + <rabble-entity> element
```

Each layer depends only on what is below it. Aether has no World dependencies. Pages are the top of the stack.

### Script + CSS loading order (all pages)

```html
<!-- Synchronous loaders — no defer; run during parse; inject bundles into <head> -->
<script src="world/js/RaBbLE-aether.js"></script>   <!-- injects /aether/v0.0.0.0/aether.css -->
<script src="world/js/RaBbLE-NeBuLA.js"></script>   <!-- injects /nebula/v0.0.0.0/nebula.iife.js -->

<!-- CSS (Aether injected above; theme + page CSS follow) -->
<link rel="stylesheet" href="[path/]css/RaBbLE-theme.css">      <!-- alias bridge -->
<link rel="stylesheet" href="[path/]css/RaBbLE-[page].css">     <!-- layout only -->
```

**Rules:**
- Page CSS owns layout and responsive structure only. No colors, no hex values, no animation definitions.
- All visual rules (colors, borders, glows, animations, component styles) live in Aether.
- `RaBbLE-theme.css` is the bridge — short aliases with fallbacks. Do not add visual rules here.
- Never duplicate Aether classes in page CSS. If a visual style is missing, add it to Aether.
- `<rabble-entity>` is defined by the NeBuLA bundle. Do not redefine it in World.
- Both loaders detect failure (onerror + CSS/JS sentinel check) and show a visible banner.

### `@property --harmony-angle` and the ring borders

The WM applet tile spinning ring uses `@property --harmony-angle` to animate the conic-gradient. Firefox DevTools shows a cosmetic warning ("Selector expected. Ruleset ignored due to bad selector.") for this at-rule — this is a DevTools UI quirk, not an actual parse failure. The animation works.

As a defensive fallback, `--harmony-angle: 0deg` is also declared in the WM `:root` token block. This ensures the ring renders even if `@property` fails (static, no spin).

---

## Module Map

### `rabble-theme.css`

Shared identity layer. Always loaded first, before any page CSS.

- **Palette**: CSS custom properties (`--magenta`, `--cyan`, `--violet`, `--pink`, `--green`, `--bg`, `--bg-surface`, `--bg-deep`). No hex values should appear in page CSS — reference vars only.
- **Typography**: `Share Tech Mono` / `Space Mono` for terminals; `Exo 2` / `Rajdhani` for UI labels.
- **Overlays**: `.scanlines`, `.vignette`, `.chromatic`, `.floor`, `.horizon` — all provided by Aether; do not redefine in page CSS.
- **Components**: `.rabble-brand-text`, `.rabble-status-pill`, `.rabble-glass`, `.rabble-cursor`.
- **Keyframes**: `holo`, `rabble-fade-in`, `rabble-blink`, `status-pulse`, `neon-flicker`, `floor-drift`.
- **iOS hardening**: `overscroll-behavior`, `touch-action`, `-webkit-overflow-scrolling` applied globally.

---

### `rabble-bg.js` — **being absorbed by NeBuLA**

> **Migration in progress:** bg.js is being absorbed into NeBuLA as composable effect systems (Phase 5 of `RaBbLE-NeBuLA-Rearchitecture.md`). After migration, World will use `<rabble-ambient particles grid>` or `NeBuLA.createAmbient()` instead. bg.js will be archived.

Ambient background system. Creates fixed-position canvases inserted *before all other content* in the DOM — this is intentional so they sit behind everything without affecting layout.

```js
var bg = new RaBbLEBackground({
  particles:    true,   // outrun particle field with proximity connections
  grid:         true,   // perspective grid (vanishing point at H × 0.74)
  cursorTrail:  false,  // 36-point neon tail, 600ms lifetime
  clickRipples: false,  // expanding rings on click
});

bg.destroy(); // cancel loop, remove canvases
```

**Current page config:**
- Boot/login: `{ particles: true, grid: true }`
- Chat: `{ particles: true, grid: true }`

The particle field uses Lissajous drift and color-cycles through the palette. All pixel constants in this file are tagged `STABLE` — do not change them without testing boot regression (they must match the entity renderer's visual weight).

**Post-migration replacement:**
```html
<rabble-ambient particles grid></rabble-ambient>
```
Both `<rabble-entity>` and `<rabble-ambient>` share a NeBuLA frame budget coordinator — one RAF loop, one GPU pipeline. This eliminates the dual-renderer GPU contention that made bg.js + entity run poorly together.

---

### `RaBbLE-aether.js` and `RaBbLE-NeBuLA.js` — bundle loaders

These are World's single points of import for Aether CSS and NeBuLA JS. Both follow the same pattern:

1. Create the bundle element (`<link>` or `<script>`) pointing to the CDN URL
2. Append it to `<head>` synchronously during HTML parsing (no `defer`)
3. Attach an `onerror` listener — fires on 404 or network failure
4. On `window.load`, check a sentinel (Aether: CSS var `--rabble-magenta`; NeBuLA: `window.NeBuLA`) — catches silent failures
5. On failure: mark `<html data-aether="failed">` or `data-nebula="failed"` and insert a visible banner

To change the CDN version, edit the `AETHER_URL` / `NEBULA_URL` constant at the top of each file.

---

### CDN serving — Phase 1 (current)

World's Cloudflare Worker **is** the CDN. Aether and NeBuLA bundles are staged into World's directory before deploy and served as root-relative paths:

```
/aether/v0.0.0.0/aether.css       ← Aether CSS (dev unminified)
/aether/v0.0.0.0/aether.min.css   ← Aether CSS (minified, production)
/nebula/v0.0.0.0/nebula.iife.js   ← NeBuLA IIFE bundle
```

These directories are **gitignored in World** — they are generated by `cast-cdn.sh` at deploy time, not committed. The Cloudflare Worker (`wrangler.jsonc`: `"assets": { "directory": "." }`) serves them automatically as static files.

**To deploy World + CDN:**

```bash
# 1. Stage both bundles into World
bash RaBbLE-Grimoire/spells/cast-cdn.sh        # builds Aether + NeBuLA, copies to World/aether/ and World/nebula/

# 2. Deploy (from World root)
cd RaBbLE-World && wrangler deploy
```

**Branch strategy:**

| Branch | Cloudflare | Use |
|---|---|---|
| `world` | `joinrabble.world` — production | Default. All work goes here until staging is needed. |
| `world-dev` | `dev.joinrabble.world` — staging | Create when deploying directly to prod becomes risky. |

`world` is currently the only branch and is set as production in Cloudflare. Create `world-dev` when it becomes warranted — not before.

**Phase 2** (post-Ep2, or when friction demands it): a dedicated `cdn.joinrabble.world` Cloudflare Worker serves Aether and NeBuLA independently. Loader URLs become absolute (`https://cdn.joinrabble.world/...`) and CORS headers are added. Full spec in `RaBbLE-Grimoire/RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md`.

---

### `<rabble-entity>` custom element

Defined in the NeBuLA bundle (`/nebula/v0.0.0.0/nebula.iife.js`). **Do not define it in World.**

```html
<rabble-entity mode="boot" particle-count="480" overscan="2.55"></rabble-entity>
```

**Why overscan exists**: The entity canvas is intentionally sized larger than its visible layout box so that particles drifting near the edges do not clip hard. The internal canvas extends beyond the host div. Host sizing is the page CSS's responsibility — the element reads its layout size and multiplies by `overscan`.

**Attributes:**
| Attribute | Values | Effect |
|---|---|---|
| `mode` | `boot`, `idle` | Boot runs the convergence → portal → eye-emerge timeline; idle starts fully alive |
| `particle-count` | integer | Number of nebula particles |
| `overscan` | float | Multiplier for internal canvas size vs visible host |
| `interactive` | bool | Mouse tracking + click jolt (default: true) |
| `show-waveform` | bool | Waveform below eyes (default: false) |

**Entity state API (called on the element directly):**
```js
entity.setEntityState('thinking');   // 'idle' | 'thinking' | 'speaking'
entity.injectEyeJolt(dx, dy);        // startle impulse, values –1..1
```

**NeBuLA namespace (set at connect time):**
```js
window.NeBuLA._instance     // the active Canvas2dBackend
window.NeBuLA.particleCount // actual count (may be capped on mobile)
window.NeBuLA.backend       // 'Canvas2D'
```

**Boot timeline** (mode="boot"):
```
0ms      Particles converge from screen edges
400ms    Portals begin drawing as animated arcs
1400ms   Eyes emerge from portal slits
2600ms   Eyes fully open → 5-blink burst starts
3200ms   Burst complete → settled random blink rhythm
```

Full renderer documentation lives in `RaBbLE-NeBuLA/` in the Grimoire.

---

## JS Module Map (post-refactor)

World JS is split into focused modules loaded in order:

| Module | Global | Purpose |
|---|---|---|
| `RaBbLE-aether.js` | — | Injects Aether CSS bundle from CDN; failure monitor |
| `RaBbLE-NeBuLA.js` | `window.NeBuLA` | Injects NeBuLA JS bundle from CDN; defines `<rabble-entity>` |
| `RaBbLE-landing-data.js` | `window.LandingData` | All data constants for landing (ORGANS, BOOT_LOG_LINES, etc.) |
| `RaBbLE-landing-metrics.js` | `window.LandingMetrics` | rAF pulse loop, entropy computation, substrate detection |
| `RaBbLE-landing-boot.js` | `window.LandingBoot` | Boot log playback timeline with callback API |
| `RaBbLE-landing.js` | Alpine.data('landing') | Landing page Alpine component — wires all modules into reactive state |
| `RaBbLE-pages.js` | `window.RaBbLE_PAGES` | Page registry — source of truth for all World page URLs |
| `RaBbLE-page-runtime.js` | `window.RaBbLEPageRuntime` | Shared page utilities: startBackground, mountEntityMini, mountStatusbar, mountPageNav |
| `RaBbLE-Studio.js` | — | NeBuLA Studio controls — vanilla JS, no Alpine |

### LandingBoot.play callback API

`window.LandingBoot.play(lines, callbacks)` — plays a boot log timeline.

- `lines`: array of `{ at: ms, msg: string, cls?: string, ts?: string, tag?: string, entityState?: string }`
- `callbacks.pushLine(line)`: called for each log line at its `at` timestamp
- `callbacks.setEntityState(state)`: called when a line has `entityState` set
- `callbacks.onComplete()`: called after all lines have fired

This interface is reusable by any page that needs a boot sequence (e.g., NeBuLA-OS emulation).

---

### `boot.js`

Boot sequence controller. Three responsibilities:

1. **Background + entity init** — creates `RaBbLEBackground`, obtains `entityHost` reference.
2. **Boot log** — drives 62 log lines across 7.1 seconds. Each line has a type tag (`sys`, `info`, `ok`, `warn`, `rbl`) that controls color. Milestone lines fire `entity.injectEyeJolt()` to make the entity react.
3. **Transitions** — all transitions are class-driven, not timer-driven:

```
boot log completes
  → #boot-panel.hide fades log out
  → #login-panel.show fades login form in
  → #ecb.hide hides portrait entity brand

user clicks ENGAGE
  → body.boot-exit fades the entire page out
  → boot.js navigates to RaBbLE.html after the fade
```

**Login reactions** — as the user types their ID or passphrase, `boot.js` swaps `#reaction` text from a reaction table. Three tables: identity recognition (user field), passphrase validation, hover state. These are cosmetic — no actual auth.

**Timing dependency**: Boot log timing and eye jolt positions must stay coordinated with the entity's boot timeline (see `rabble-entity.js` boot timeline above). If you change the boot log duration, audit the jolt call sites.

---

### `chat.js`

Vanilla JS chat controller, IIFE-scoped. State:
```js
state = {
  messages: [],          // full history including system messages
  entityEl: null,        // reference to <rabble-entity>
  apiConfig: {
    url: window.RABBLE_API_URL,   // injected at runtime or null
    model: 'claude-...',
    systemPrompt: '...'
  }
}
```

**Entry transition**: `RaBbLE.html` starts with `body.chat-entry` (opacity 0). `chat.js` waits two animation frames then adds `chat-ready`, triggering the fade-in. This prevents the page from popping in after the boot-exit fade.

**API call** (`callChatApi`): Streams responses via `fetch` + `ReadableStream` + SSE line parsing. Drives entity state: `idle → thinking` on send, `thinking → speaking` on first token, `speaking → idle` on stream close. Falls back to a canned response if `RABBLE_API_URL` is not set.

**Message rendering**: `renderMessages()` does a full redraw of `.chat-container` on each state change. Not diffed — acceptable for current message volume.

---

## Page Flow

```
index.html
  → (meta redirect) → RaBbLE-Boot.html

RaBbLE-Boot.html
  mode: "boot" entity
  boot log plays (7.1s)
  → login panel crossfades in
  → ENGAGE button → body.boot-exit fade
  → navigate → RaBbLE.html

RaBbLE.html
  body.chat-entry (opacity 0)
  → chat.js adds chat-ready (opacity 1)
  entity: mode="idle"
  chat surface active
```

---

## CSS Transition Inventory

These class pairs drive every page transition. If a fade breaks, check here first.

| Class pair | File | Trigger | Effect |
|---|---|---|---|
| `#boot-panel.hide` | `boot.css` | Boot log complete | Fades boot log out |
| `#login-panel.show` | `boot.css` | Boot log complete | Fades login form in |
| `#ecb.hide` | `boot.css` | Boot log complete | Hides portrait entity brand |
| `body.boot-exit` | `boot.css` | ENGAGE clicked | Fades entire boot page out |
| `body.chat-entry` → `body.chat-ready` | `chat.css` | `chat.js` init | Fades chat page in |

---

## Responsive Layout Rules

**Boot page** (`boot.css`):
- Landscape: `#stage` is flex-row. Entity left, info right.
- Portrait (`max-width: 640px` or `orientation: portrait`): `#stage` becomes flex-column. Entity stacks above info. Top padding gives entity breathing room; `gap` controls whitespace between entity/brand block and boot/login panel.

**Chat page** (`chat.css`):
- Landscape: entity is `min(34vw, 520px)`, aspect `1/0.74`.
- Portrait: entity scales to `min(78vw, 520px)`, aspect `1/0.78`.

**Entity host sizing rules:**
- Change `width` when the visible entity should be larger in layout.
- Change `aspect-ratio` when the layout box needs more vertical room.
- Change `overscan` attribute when particles still clip after host is sized correctly.
- Keep parent containers `overflow: visible` when particles should drift behind adjacent content.

---

## Adding a New Surface

Checklist:

1. Load `rabble-theme.css` before any page CSS.
2. Load `rabble-bg.js` → `rabble-entity.js` → page JS (in that order).
3. Use `<rabble-entity mode="idle" overscan="2.55">` for the entity host.
4. Size the entity host in page CSS, not inline.
5. Size the host with `overflow: visible` if particles should drift beyond it.
6. Wire `setEntityState()` to interaction events if the entity should react.
7. Run `node --check <page>.js` before committing.
8. Test both landscape and portrait orientations.

Skeleton: see `RaBbLE-World-README.md → Adding a New Page`.

---

## Planned: Applet Consolidation (Phase 6 of NeBuLA Rearchitecture)

> See `RaBbLE-NeBuLA-Rearchitecture.md` Phase 6 for full spec.

The separate pages (RaBbLE-Chat.html, RaBbLE-Docs.html, RaBbLE-OS.html) will be consolidated into WM applets within the landing page. The landing page becomes the single entry point.

**Target architecture:**
- `index.html` is the shell: Aether CSS + NeBuLA effects + WM layout + applet slots
- Each "page" becomes a WM applet (tiled by RaBbLE-wm.js)
- Entity lives in its own applet slot, always visible
- Chat, Docs, OS info are applets that can be focused/tiled/minimized

**Landing page template (canonical for new RaBbLE/NeBuLA pages):**
```html
<head>
  <link rel="stylesheet" href="/css/RaBbLE-theme.css">
  <script src="/js/RaBbLE-NeBuLA.js"></script>
</head>
<body>
  <rabble-ambient particles grid></rabble-ambient>
  <rabble-entity mode="boot" particle-count="480" overscan="2.35"></rabble-entity>
  <!-- Applets load into WM slots -->
</body>
```

No bg.js. No separate pages. One shell, NeBuLA for all visual effects, Aether for all styling. Boot.html stays as a Plymouth boot screen reference artifact for RaBbLE-OS.

This can proceed in parallel with NeBuLA decomposition (phases 1-5).

---

## Lessons & Gotchas (distilled from S5–S46)

- **World is a thin scaffold — nothing more.** State machines, data, DOM assembly,
  mounting. No rendering logic, no embedded effects, no CSS beyond layout/structure.
  Anything that looks like "look-and-feel" belongs in Aether; anything that looks like
  "visual effect / entity rendering" belongs in NeBuLA. *(S9 pivot moved
  `rabble-entity.js`, ~700 lines, out of World entirely.)*
- **No React, no JSX, no frameworks — vanilla JS only.** Convert any prototypes before
  landing them. The established idioms are Alpine.js (already loaded) and the
  `NeBuLA.ui` factory pattern (`{ el, ...controls, destroy() }`). In-browser Babel
  transpilation was considered and explicitly rejected.
- **Link `aether.css` (dev), never `aether.min.css`.** The watch build only emits the
  unminified file — pages requesting `.min.css` silently got stale/404 CSS for an
  entire regression session before this was traced. Always run `dev-serve.sh`; never
  run `dev-cdn.js` or esbuild watch manually.
- **`RaBbLE-Boot.html` is a living spec artifact — do not delete.** Its boot timeline
  (particle convergence → portal arcs → eye emergence, ~7s) is the reference for the
  future native C++ Plymouth backend (NeBuLA Episode 6).
- **Two CDN loaders only** (`RaBbLE-aether.js`, `RaBbLE-NeBuLA.js`) — both must show
  visible failure banners on load failure. "Degraded mode is never silent."
- **Never duplicate Aether classes in page CSS.** If a visual style is missing, add it
  to Aether — see `RaBbLE-World-Architecture.md:45`.

---

```
transcribe ~ grimoire >> architecture updated, applet consolidation planned // %ARCHITECTURE_UPDATED%
```
