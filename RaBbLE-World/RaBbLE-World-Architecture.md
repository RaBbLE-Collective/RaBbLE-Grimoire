# RaBbLE-World-Architecture.md

```
transcribe ~ grimoire >> system map crystallized // %ARCHITECTURE_LOCKED%
```

System map for the RaBbLE-World frontend. Read this before modifying any shared module or adding a new surface.

---

## Layer Stack

```
rabble-theme.css          ← shared palette, typography, overlays, keyframes
  ↓
rabble-bg.js              ← ambient canvas layer (particles, grid, cursor effects)
rabble-entity.js          ← entity canvas layer (<rabble-entity> custom element)
  ↓
boot.css / chat.css       ← page-specific layout and transitions
  ↓
RaBbLE-Boot.html          ← boot + login surface
RaBbLE.html               ← chat surface
RaBbLE-Docs.html          ← documentation viewer
```

Each layer depends only on what is below it. Theme has no dependencies. Pages are the top of the stack.

---

## Module Map

### `rabble-theme.css`

Shared identity layer. Always loaded first, before any page CSS.

- **Palette**: CSS custom properties (`--magenta`, `--cyan`, `--violet`, `--pink`, `--green`, `--bg`, `--bg-surface`, `--bg-deep`). No hex values should appear in page CSS — reference vars only.
- **Typography**: `Share Tech Mono` / `Space Mono` for terminals; `Exo 2` / `Rajdhani` for UI labels.
- **Overlays**: `.rabble-scanlines`, `.rabble-vignette`, `.rabble-chromatic` — fixed-position decorative layers.
- **Components**: `.rabble-brand-text`, `.rabble-status-pill`, `.rabble-glass`, `.rabble-cursor`.
- **Keyframes**: `holo`, `rabble-fade-in`, `rabble-blink`, `status-pulse`, `neon-flicker`.
- **iOS hardening**: `overscroll-behavior`, `touch-action`, `-webkit-overflow-scrolling` applied globally.

---

### `rabble-bg.js`

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

---

### `rabble-entity.js`

The entity renderer. Exposes a `<rabble-entity>` custom element.

```html
<rabble-entity id="entityHost" mode="idle" particle-count="480" overscan="2.55"></rabble-entity>
```

**Why overscan exists**: The entity canvas is intentionally sized larger than its visible layout box so that particles drifting near the edges do not clip hard. The internal canvas extends beyond the host div. Host sizing is the page CSS's responsibility — the element reads its layout size and multiplies by `overscan`.

**Attributes:**
| Attribute | Values | Effect |
|---|---|---|
| `mode` | `boot`, `idle` | Boot runs the convergence → portal → eye-emerge timeline; idle starts fully alive |
| `particle-count` | integer | Number of nebula particles |
| `overscan` | float | Multiplier for internal canvas size vs visible host |

**Entity state API:**
```js
entity.setEntityState('thinking');   // 'idle' | 'thinking' | 'speaking'
entity.injectEyeJolt(dx, dy);        // startle impulse, values –1..1
entity.destroy();                    // cancel animation loop, remove listeners
```

**Internal subsystems:**

*Particles* — 480 gaussian-distributed nebula particles around the eye centre. Each has drift, glow radius, and color sampled from the palette. They form connection lines when within proximity.

*Eyes* — Two oval orbs (magenta left, cyan right) with a shared spring-physics position. Driven by:
1. Autonomous saccade table (16 targets: hard/med/soft transitions, randomised hold + gap)
2. Living drift — two-frequency sinusoidal superposition per axis
3. Mouse tracking override — activates within 600px of eye centre
4. Jolt injection — impulse decays ×0.88 per frame

*Portals* — Dark elliptical discs behind each eye. In boot mode, animated arcs draw clockwise during 0.4–2.6s of the boot timeline.

*Waveform* — Optional dual braided waves (phase-offset by π). Driven by `setEntityState()`:

| State | Amplitude | Frequency | Speed |
|---|---|---|---|
| `idle` | 2.0 + breathe | 0.09 | 0.005 |
| `thinking` | 4.5 + breathe | 0.13 | 0.007 |
| `speaking` | 7.5 + breathe | 0.20 | 0.011 |

**Boot timeline** (mode="boot"):
```
0ms      Particles begin converging from screen edges
400ms    Portals begin drawing as animated arcs
1400ms   Eyes begin emerging from portal slits (phase 0)
2600ms   Eyes reach full open (phase 1) → blink burst starts
3200ms   5-blink burst completes → settled random blink rhythm
```

After 3200ms the entity behaves identically to `mode="idle"`.

**Pixel constants are frozen.** The canvas is fixed at 460px × 320px internal coordinates. Do not change `EYE_R`, `EYE_SEPARATION`, `NEBULA_RADIUS`, or `FALLOFF_RADIUS` without auditing visual regression across both boot and idle modes.

Legacy direct-canvas usage (`new RaBbLEEntity(canvas, options)`) still works but is deprecated. New surfaces should use the custom element.

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

```
transcribe ~ grimoire >> architecture mapped, surfaces documented // %MAP_CRYSTALLIZED%
```
