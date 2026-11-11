# World Framework Refactor — P0 API Contract (FROZEN v1)

> Companion to `World-Framework-Refactor.md`. This is the **frozen contract** all
> tracks build against. Frozen by the Opus orchestrator at P0, 2026-06-26.
>
> **What "frozen" means:** the *naming conventions*, the *component/element roster*,
> and *ownership boundaries* below are fixed — Track A (Aether) and Track B (NeBuLA)
> build against these names without collision, and Track C (World) consumes only
> these. **Attribute/parameter-level detail** is filled in from `harvest-map.md`
> *within* these conventions (the harvest reveals the real params; it may NOT rename
> a component, move ownership, or invent a new naming scheme). If harvest surfaces a
> genuinely new component not in the roster, it is appended here by the orchestrator
> before any track builds it — it never goes straight into World.

---

## 1. Aether contract (Track A owns `RaBbLE-Aether/assets/**`)

### Naming conventions (FROZEN)
- **Block:** `.rabble-<component>` (e.g. `.rabble-panel`, `.rabble-card`).
- **Part:** flat hyphenated, prefixed by block — `.rabble-chat-bubble`, `.rabble-askbox-input`. **No BEM `__`/`--`.** Matches existing `.rabble-border-harmony`, `.rabble-harmony-line`.
- **State:** `.is-*` — `.is-active`, `.is-open`, `.is-thinking`. Plus the pre-existing `.wm-active` (window-manager active) which stays as-is.
- **Accent:** every accented component reads `var(--rabble-accent)` (a palette var, defaulting to a sensible token). Pages set accent by setting `--rabble-accent` inline or via a modifier `.rabble-accent-<name>` (names map to palette entries; Track A defines the set from harvest).
- **Motion speed:** `.fast` / `.slow` modifiers adjust the component's animation duration (consume existing motion tokens). Default = no modifier.
- **Colors:** palette vars only, never raw hex. Source: `RaBbLE-Agent/RaBbLE-Palette.md`.

### Component roster (FROZEN names; ✓ = already exists in Aether)
| Class | Role |
|---|---|
| `.rabble-border-harmony` ✓ | Flowing conic ring (canonical effect; **must animate in Firefox** — see §3) |
| `.rabble-harmony-line` ✓ | Accent line / divider with flow |
| `.rabble-panel` | Glass surface + flowing ring. Canonical successor to World `.rc-panel`/`.applet`. |
| `.rabble-card` | Member/collective card; accent via `--rabble-accent`. |
| `.rabble-btn` | Button/CTA. `appearance:none; border:none;` + harmony ring. Pill variant `.rabble-btn-pill`. |
| `.rabble-section-header` | Section header; pairs with `.rabble-harmony-line`. |
| `.rabble-statusbar` | 3-zone waybar (left/center/right). Parts: `.rabble-statusbar-zone`. |
| `.rabble-dock` | Dock/channel rail. Parts: `.rabble-dock-item`. (Expand/collapse glue stays thin in World.) |
| `.rabble-log` | Entity-log container styling (stream rendered by NeBuLA `<rabble-log>`). |
| `.rabble-chat` | Chat container. Parts: `.rabble-chat-bubble`, `.rabble-askbox`, `.rabble-askbox-input`. |
| `.rabble-overlay` | Overlay/modal family. Variants: `.rabble-overlay-login`, `-nav`, `-log`, `-ios`. |
| `.rabble-whisper` | Hover descriptor card. |
| `.rabble-rail` | Progress rail. Parts: `.rabble-rail-fill`. |
| `.rabble-scanlines` ✓ / `.rabble-vignette` ✓ / `.rabble-chromatic` ✓ | CRT ambient layers (World just adds the divs). |
| `.rabble-glitch-veil` | `%GLITCH%` state CSS layer (harvest the glitch from Chrysalis). |

> Token/swatch helpers for the Catalog's Tokens section (palette + type scale) are
> Track A's too; name them `.rabble-swatch`, `.rabble-type-scale` if needed.

---

## 2. NeBuLA contract (Track B owns `RaBbLE-NeBuLA/src/**`)

### Conventions (FROZEN)
- **Custom elements** are `<rabble-*>`, registered by the NeBuLA IIFE on load (same pattern as existing `<rabble-entity>`).
- **Attributes** are reactive via `attributeChangedCallback`; primitive config only (numbers/enums/colors). Complex data passed via a property or method, not an attribute.
- **Imperative API** lives on the element instance (e.g. `el.setEntityState(...)`, `el.push(line)`).
- **Events** bubble with a `rabble-` prefix and `{ bubbles:true, composed:true }` (e.g. `rabble-chat-submit`).
- **Effects** (non-element, parameterized) are exposed as `nebula.effects.<name>(target, opts)` returning a handle `{ start(), stop(), setParams(opts) }`.
- **UI factory** stays callable as `nebula.ui.<kind>(opts) -> HTMLElement` (`panel`, `card`, `badge`, `statRow`) — migrated from World `ui.js`. Prefer plain HTML + Aether classes where a factory adds no value; keep the factory only for genuinely dynamic construction.
- **Colors:** palette vars only. **Perf contract:** 1000+ entities @ 60fps unbroken.
- **Stage driver:** keep `window.RaBbLEStage.next()` working — it is the screenshot-loop entry point.

### Element / effect roster (FROZEN names; ✓ = exists)
| Element / API | Role | Source to harvest |
|---|---|---|
| `<rabble-entity>` ✓ | Entity persona; `setEntityState()`, `injectEyeJolt()`. | NeBuLA `element.js` (the pattern to copy). |
| `<rabble-floor>` | 3D floor graph. | World `RaBbLE-floor.js` (883). |
| `<rabble-graph>` | Grimoire graph. | World `RaBbLE-grimoire-graph.js` (806). |
| `<rabble-field>` | Deep-field starfield + parallax. | Chrysalis `liminal.js` (703). |
| `<rabble-log>` | Streaming entity log; `el.push(line)`, attr `src`. | Chrysalis `landing.js` log. |
| `<rabble-chat>` | Void bubbles + ask-box; `el.addMessage()`, emits `rabble-chat-submit`. | Chrysalis `chat.js` / Shell `.void-chat`. |
| `<rabble-doors>` | Orbiting threshold (P5, optional). | Chrysalis `liminal.js`. |
| `nebula.effects.starfield` | Parallax deep-field. | Chrysalis `liminal.js`. |
| `nebula.effects.streaks` | Signal streaks / shooting transmissions. | Chrysalis `liminal.js`. |
| `nebula.effects.constellation` | Cursor-reaching lines. | Chrysalis `liminal.js`. |
| `nebula.effects.haze` | Nebula haze / gradient fog. | Chrysalis. (May instead be Aether layer — orchestrator decides from harvest.) |
| `nebula.ui.{panel,card,badge,statRow}` | DOM factory. | World `RaBbLE-ui.js` (243). |

> Effect vs CSS rule (from plan §4): renders to canvas/WebGL & takes params → NeBuLA.
> Pure CSS layers/filters/keyframes → Aether. Ambiguous ones (`haze`) the orchestrator
> assigns when reviewing the harvest map.

---

## 3. Cross-cutting acceptance gates (FROZEN)

1. **Firefox flow check (BLOCKING for Track A):** `.rabble-border-harmony` must visibly
   animate in **Firefox**, not just Chromium. `@property <angle>` inside `conic-gradient`
   is historically flaky in Firefox. If it fails, Track A ships a Firefox-safe flow
   technique (rotating a masked element, or animated `background-position`) behind the
   *same class name* — World never learns the difference.
2. **The Catalog is the proof:** every rostered component must render on
   `RaBbLE-World/world/RaBbLE-Catalog.html` purely from an Aether class or a mounted
   `<rabble-*>` element. If it can't be expressed that way, it isn't migrated.
3. **World owns no rendering/component CSS once migrated:** every harvest-map row, once
   built into a framework, is deleted from World in P4. World JS shrinks well below 4,746 lines.
4. **Backward-compatible migration:** World `.rc-*` classes become thin aliases of the
   `.rabble-*` canonical classes so pages migrate incrementally without breaking.

---

## 3b. P0.5 Orchestrator rulings (FROZEN from harvest-map.md, 2026-06-26)

Reviewed `harvest-map.md` (52 items). Decisions that override the harvest agent's
conservative "keep in World / post-EP1" suggestions where they conflict with the prime
directive (effects & reusable components generalize; only true *page layout* stays in World).

**Roster additions (now FROZEN canonical names):**
- Aether: `.rabble-badge` (status pill), `.rabble-stat-row` (+ `-label`/`-value` parts),
  `.rabble-transmission` (single-line truncating output). Motion utilities:
  `.rabble-stagger-in` (staggered list/line reveal — from `memberLineIn`),
  `.rabble-sigil` + states `.is-thinking`/`.is-speaking` (generalized sigil pulse).

**Ambiguous-ownership rulings:**
- **Glitch veil → Aether CSS `.rabble-glitch-veil` for EP1** (ships now, class-toggle). A
  NeBuLA WebGL glitch shader is a *post-EP1* enhancement, not this refactor. Same class name.
- **Scanlines / vignette / chromatic → Aether CSS** (exist; keep). No shader.
- **Starfield / haze / streaks / constellation → NeBuLA** `nebula.effects.{starfield,haze,streaks,constellation}`.
  **Caveat from harvest:** only `starfield` has real source (Chrysalis `liminal.js`); streaks /
  constellation / haze are largely *conceptual* in Chrysalis. **Build `starfield` for real now;**
  streaks/constellation/haze are P5 — Track B stubs the API + a minimal generic version, does
  NOT invent elaborate effects from non-existent source.
- **Sigil pulse → Aether** `.rabble-sigil` utility (generalized).
- **Member line stagger → Aether** `.rabble-stagger-in`.

**Stays in World as page layout (NOT a framework violation — World owns page assembly):**
stage grid, collective two-column layout, OS-page entry/ready/error choreography, dock
expand/collapse *state-machine glue*, floor bilinear color-field *math util*, account session
export. The *visual styling* of dock/account/overlays still moves to Aether classes; only the
layout grids + JS state glue remain in World (thin, using Aether tokens).

**NeBuLA extraction scope for this refactor (FROZEN):**
- Real, well-sourced → build now: `<rabble-floor>` (World `floor.js`, 883 lines — eye + portal +
  graph + bilinear field), `<rabble-graph>` (World `grimoire-graph.js`, 806), `nebula.effects.starfield`
  (Chrysalis `liminal.js`). Confirm existing `<rabble-entity>`, `nebula.ui.{entityMini,grimoireEye,grimoireRing}`,
  `nebula.effects.{entropy,ambientField,attractor}` are exposed cleanly under §2 conventions.
- Deferred to P5 (stub API only): `<rabble-doors>`, `nebula.effects.{streaks,constellation,haze}`.

## 4. Delivery mechanics (reference — already in place)
- Flip point: `RaBbLE-World/world/js/RaBbLE-config.js` (localhost → `:8080` CDN mock).
- Aether: edit `assets/**` → rebuild → dev-serve serves it.
- NeBuLA: edit `src/**` → `npm run build:iife` → `cp dist/nebula.iife.js ../RaBbLE-World/world/js/RaBbLE-NeBuLA.js`.
- Screenshot loop: CommonJS Playwright from npx cache, drive `window.RaBbLEStage.next()`, bundles from `:8080`.
- dev-serve confirmed up on `:8080` at P0.
