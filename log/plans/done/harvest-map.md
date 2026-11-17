# Harvest Map — World Framework Refactor Ledger

> Master extraction ledger: every distinct visual EFFECT and reusable COMPONENT implemented across World and Chrysalis ep1, each mapped to a generic framework target (Aether=CSS or NeBuLA=JS).
>
> **DATE:** 2026-06-26
> **SCOPE:** RaBbLE-World/* + RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/* → Aether ∪ NeBuLA
> **STATUS:** Exhaustive harvest, comprehensive deduplication

---

## SURFACES & LAYOUT

### Tinted-Glass Panel System
- **Name:** Tinted-Glass Panel Container
- **Target:** `.rabble-panel` (Aether CSS)
- **Best source:** World `RaBbLE-panels.css:25–45` + `RaBbLE-ui.js:67–79` (factory)
- **Duplicates collapsed:** None identified (Aether motion/.rabble-border-harmony already canonical)
- **Params:** `title` (optional), `className` (optional), `gap-sm` spacing, glass tint (80%), blur 5px
- **Notes:** Panel factory adds .rabble-border-harmony class (conic-gradient flowing ring via Aether motion). World only applies, never redefines. Box-shadow dual-accent atmospheric glow.

### Stage Grid Layout
- **Name:** Responsive Stage Grid (entity left, main center, dock bottom)
- **Target:** Aether CSS layout utilities (or World responsibility — NOT framework)
- **Best source:** World `RaBbLE-unified.css:83–156` (#stage, #entity-stage, #panel-host, #centerpiece-host)
- **Duplicates collapsed:** None (layout is page-specific, not reusable component)
- **Params:** Grid columns (340px + 1fr desktop, 1fr mobile), grid-template-areas
- **Notes:** NOT a framework component — this is World's layout only. Entity stage has flowing divider (gradient magenta→violet→cyan). Mobile reorient. Safe-area-inset for notch.

### Progress Rail
- **Name:** Progress Rail (top bar)
- **Target:** Aether CSS utility
- **Best source:** World `RaBbLE-unified.css:179–200` (#progress-rail, .rail-fill)
- **Duplicates collapsed:** None
- **Params:** Height 2px, gradient fill (magenta→cyan), width animated
- **Notes:** Simple progress indicator, not a full framework component.

---

## CARDS & CONTAINERS

### Member Identity Card
- **Name:** Member Card with Accent Stripe
- **Target:** `.rabble-card` (Aether CSS)
- **Best source:** World `RaBbLE-panels.css:62–98` + `RaBbLE-ui.js:111–139` (memberCard factory)
- **Duplicates collapsed:** Chrysalis `RaBbLE-Grimoire.js` entity card concept (subsumed by NeBuLA.ui.createEntityMini)
- **Params:** `name`, `role`, `tagline`, `accent` key (m/c/v/p/g/y/r), `key` data attribute
- **Notes:** Left 3px accent stripe, glass surface (78%), interactive hover glow. Role is cyan monospace. Stripe colour via CSS custom property --card-accent.

### Collective Card (Compact)
- **Name:** Collective List Card (compact member entry)
- **Target:** `.rabble-card` or dedicated `.rabble-collective-card` (Aether)
- **Best source:** World `RaBbLE-panels.css:231–328` (.rc-collective-card, .rc-collective-card__stripe, etc.)
- **Duplicates collapsed:** None (unique to collective movement)
- **Params:** Stripe opacity transition (0.6→1), background tint on hover/active, name/role truncation
- **Notes:** Smaller sibling to member-card; used in two-column collective layout. Active state highlights stripe and background.

### Member Reveal (Detail Card)
- **Name:** Member Detail Card (full reveal on collective)
- **Target:** `.rabble-card` with animation (Aether)
- **Best source:** World `RaBbLE-panels.css:382–462` (.rc-member-reveal, .rc-member-reveal__*)
- **Duplicates collapsed:** None
- **Params:** Glass 78%, animation memberDetailIn (mid), internal line animations with staggered delays (80ms, 160ms)
- **Notes:** Sigil/name/role/tagline/divider/lines. Divider and lines have opacity:0 with animations. Hover box-shadow glow.

---

## CONTROLS & BUTTONS

### Primary/Secondary Button
- **Name:** CTA Button
- **Target:** `.rabble-btn` (Aether CSS)
- **Best source:** World `RaBbLE-panels.css:136–165` + `RaBbLE-ui.js:151–164` (button factory)
- **Duplicates collapsed:** None
- **Params:** `label`, `secondary` boolean, `icon` (optional), .rabble-border-harmony applied
- **Notes:** Primary = magenta, secondary = muted. Active state: translateY(1px). Focus ring outline 2px.

### Dock Converse Button
- **Name:** Converse Toggle Button (dock expansion)
- **Target:** `.rabble-btn` or specialized dock button (Aether)
- **Best source:** World `RaBbLE-dock.css:33–40` (rd2-converse-btn HTML), `RaBbLE-dock.js:58+` (behavior)
- **Duplicates collapsed:** None
- **Params:** Toggle state, aria-label, click listener
- **Notes:** Part of dock—not a standalone component, but could be extracted.

---

## NAVIGATION & STATUS

### Dock (Persistent Curator Interface)
- **Name:** Curator Dock (bar + expand-to-full pane)
- **Target:** `.rabble-dock` (Aether CSS) + `<rabble-dock>` (NeBuLA element, proposed)
- **Best source:** World `RaBbLE-dock.css:12–180` + `RaBbLE-dock.js:32–53` (buildDock)
- **Duplicates collapsed:** Chrysalis ep1 dock had similar transmissions feed (subsumed)
- **Params:** Sigil state (thinking, speaking, idle), transmission text, bar-to-expanded height, history feed
- **Notes:** Bar mode (48px) ↔ expand mode (65vh). Sliding motion. Sigil pulse animations (400ms speaking, 800ms thinking). Live badge toggles. Transmission text truncates in bar mode.

### Dock Components
- **Name:** Dock Sigil State Indicator
- **Target:** Aether CSS animations + NeBuLA state binding
- **Best source:** World `RaBbLE-dock.css:43–67` (.rd2-sigil, .rd2-sigil--thinking, .rd2-sigil--speaking, @keyframes rd2-sigil-pulse)
- **Duplicates collapsed:** None (unique dock visual)
- **Params:** State class (thinking/speaking), opacity pulse (0.5→1), text-shadow glow
- **Notes:** Animation parameters: 800ms thinking, 400ms speaking.

### Status Badge
- **Name:** Status Badge (live/scripted)
- **Target:** `.rabble-badge` (Aether CSS)
- **Best source:** World `RaBbLE-panels.css:167–189` + `RaBbLE-dock.css:85–92` (context-dependent styling)
- **Duplicates collapsed:** None
- **Params:** `accent` key, text content
- **Notes:** Inline pill, border + background tint via color-mix, used in dock for live/scripted badge.

### Stat Row
- **Name:** Label : Value Data Pair
- **Target:** `.rabble-stat-row` (Aether CSS)
- **Best source:** World `RaBbLE-panels.css:191–229` (.rc-stat-row, .rc-stat-row__label, .rc-stat-row__value)
- **Duplicates collapsed:** None
- **Params:** Label (uppercase mono), value (right-aligned mono), bottom border separator
- **Notes:** Simple data display, flex space-between layout.

---

## ENTITY & RENDER (NeBuLA)

### Entity Element
- **Name:** Entity Rendering Element
- **Target:** `<rabble-entity>` (NeBuLA custom element)
- **Best source:** NeBuLA `src/element.js:1–150+` + World integration (loaded via RaBbLE-NeBuLA.js)
- **Duplicates collapsed:** Chrysalis had no explicit element (embedded in Studio/Liminal pages)
- **Params:** Entity state injection, palette selection, animation/boot mode
- **Notes:** Currently defined in NeBuLA bundle, injected into World pages. Canvas2D → Three.js transition planned.

### Entity Mini
- **Name:** Mini Entity Card (compact entity render)
- **Target:** `nebula.ui.createEntityMini()` (NeBuLA JS factory)
- **Best source:** NeBuLA `src/ui/entity-mini.js:1–80+`
- **Duplicates collapsed:** Chrysalis ep1 entity cards (subsumed, now NeBuLA)
- **Params:** Palette selection, animation mode, size override
- **Notes:** Reusable render of entity in compact form; used in Grimoire cards, member reveals.

### Grimoire Floor (Three.js Graph Renderer)
- **Name:** Grimoire Graph Floor (3D knowledge visualization)
- **Target:** `<rabble-floor>` (NeBuLA custom element, planned) or standalone renderer
- **Best source:** World `RaBbLE-floor.js:87–500+` (buildFloor function, Three.js scene, eye/portal/graph)
- **Duplicates collapsed:** Chrysalis ep1 Graph page had similar structure (superseded by World floor)
- **Params:** Host element, Grimoire data (docs/kinds/seals), member UV mapping, camera zoom/pan, edge rendering
- **Notes:** Eye geometry (ellipse meshes), portal arcs (ring lines), graph edges, bilinear color field (magenta→pink→cyan→violet). Lazy-loads Three.js r160 from CDN. World-specific; may become framework component post-EP1.

### Eye Geometry System
- **Name:** Entity Eye Rendering (ellipse + portal arcs)
- **Target:** `nebula.effects.eye` (proposed NeBuLA effect)
- **Best source:** World `RaBbLE-floor.js:119–200+` (ellipseMesh, ringLine, EYE_W/H/GAP constants)
- **Duplicates collapsed:** NeBuLA canvas eye system (parallel implementation, both exist)
- **Params:** EYE_W=18, EYE_H=52, EYE_GAP=38, EYE_Y=0, portal arc rx/ry, exclusion radius, color via bilinear interpolation
- **Notes:** Three.js only. Ellipse shape geometry + ring lines. Portal arcs use larger ellipse for depth effect.

### Portal Arcs (3D)
- **Name:** Portal Arcs / Orbital Doors
- **Target:** `nebula.effects.portals` (proposed NeBuLA effect)
- **Best source:** World `RaBbLE-floor.js:120–170` (portal rendering constants + geometry builders)
- **Duplicates collapsed:** Chrysalis `RaBbLE-liminal.js:27–87` (six orbiting doors, canvas-based; superseded by Three.js version)
- **Params:** Arc position (rx/ry), thickness, color, door IDs, orbit paths
- **Notes:** Liminal (Chrysalis) had 6 doors orbiting entity; World floor uses portal arc concept in 3D space. Different implementation targets (canvas → Three.js).

### Graph Network Rendering
- **Name:** Knowledge Graph Edge Rendering
- **Target:** `nebula.effects.constellation` (proposed) or `nebula.effects.graph`
- **Best source:** World `RaBbLE-floor.js:37–59` (GRAPH_EDGES constant) + rendering loop
- **Duplicates collapsed:** Chrysalis ep1 Graph page (subsumed)
- **Params:** Edge definitions (source→target), node positions, color via bilinear field
- **Notes:** 39 edge pairs in GRAPH_EDGES. Rendered as line segments in Three.js. Owns graph layout logic (node clustering, z-depth).

### Grimoire Eye (NeBuLA UI)
- **Name:** Watching Entity Eye (Grimoire header)
- **Target:** `nebula.ui.createGrimoireEye()` (NeBuLA JS factory)
- **Best source:** NeBuLA `src/ui/grimoire-eye.js:1–100+` + Chrysalis `RaBbLE-Grimoire.js:84–88` usage
- **Duplicates collapsed:** None (NeBuLA-native)
- **Params:** Color, blink loop callback
- **Notes:** Animated eye in Grimoire panel header. Starts blink loop on creation.

### Grimoire Ring (NeBuLA UI)
- **Name:** Animated Rune Ring (Grimoire summoning circle)
- **Target:** `nebula.ui.createGrimoireRing()` (NeBuLA JS factory)
- **Best source:** NeBuLA `src/ui/grimoire-ring.js:1–150+` + Chrysalis `RaBbLE-Grimoire.js:93–98` usage
- **Duplicates collapsed:** None (NeBuLA-native)
- **Params:** Color, center element setter
- **Notes:** Rotating rune ring animation. Takes a center element (typically ambient eye or entity mini).

---

## CHAT & TRANSMISSIONS

### Dock History Feed
- **Name:** Transmission History (dock expanded pane)
- **Target:** `.rabble-log` (Aether CSS) or specialized dock history
- **Best source:** World `RaBbLE-dock.css:100–125` (.rd2-history, .rd2-line, .rd2-line--user/entity/system)
- **Duplicates collapsed:** None
- **Params:** Line type (user/entity/system), text content, aria-live polite
- **Notes:** Monospace, different colours by role. Scrollable within pane.

### Dock Input Row
- **Name:** Message Input (dock expanded pane)
- **Target:** `.rabble-chat` input variant (Aether)
- **Best source:** World `RaBbLE-dock.css:127–180` (.rd2-input, .rd2-send-btn, .rd2-input-row)
- **Duplicates collapsed:** None
- **Params:** Placeholder, aria-label, send button glyph (▸)
- **Notes:** Text input + send button, part of dock. Styled as monospace.

### Chat Transmission Line
- **Name:** Transmission Line (history entry)
- **Target:** `.rabble-log` entry variant
- **Best source:** World `RaBbLE-dock.js:140–200+` (appendLine logic, DOM structure)
- **Duplicates collapsed:** Chrysalis ep1 chat had similar structure (now part of dock)
- **Params:** Text, role (user/entity/system), timestamp (optional), sigil
- **Notes:** Colour-coded by role. Sigil prefix (◈ for entity, ▸ for user). Truncation handling.

### Dock Transmission Display (Bar Mode)
- **Name:** Single-Line Transmission Display
- **Target:** `.rabble-transmission` (Aether CSS)
- **Best source:** World `RaBbLE-dock.css:69–82` (.rd2-transmission)
- **Duplicates collapsed:** None
- **Params:** Text content, title attribute for hover
- **Notes:** Truncates in bar mode (nowrap), full text on hover via title.

---

## ACCOUNT & IDENTITY

### Account Entry Surface
- **Name:** Account / Login Entry Panel
- **Target:** `.rabble-overlay` `-login` variant (Aether CSS)
- **Best source:** World `RaBbLE-account.css:1–100+`, Chrysalis `RaBbLE-landing-login.css`
- **Duplicates collapsed:** Chrysalis landing-login.css (subsumed, World version canonical)
- **Params:** Handle input, key reveal, save/error states, iOS install prompt
- **Notes:** Entry point for authentication. Handle entry, key display (masked/revealed toggle), feedback messages.

### Account Panel (Profile View)
- **Name:** Account Profile / Settings Panel
- **Target:** `.rabble-panel` variant (Aether)
- **Best source:** World `RaBbLE-account.css:20–80`, `RaBbLE-account.js`
- **Duplicates collapsed:** None
- **Params:** Handle, key, session export, logout
- **Notes:** Not a standalone component; uses core panel + custom CSS.

---

## OVERLAYS & MODALS

### Glass Overlay Base
- **Name:** Glass Overlay (base class)
- **Target:** `.rabble-overlay` (Aether CSS)
- **Best source:** Aether `assets/components/rabble-components.css` + World usage
- **Duplicates collapsed:** None
- **Params:** Z-index control, backdrop blur, close handler
- **Notes:** Base class for overlay pattern; subclassed for specific overlays.

### iOS Install Prompt Overlay
- **Name:** iOS PWA Install Prompt
- **Target:** `.rabble-overlay` `-ios` variant (Aether)
- **Best source:** World `RaBbLE-account.css:140–180`, `RaBbLE-ios-install.js`
- **Duplicates collapsed:** None
- **Params:** Dismiss handler, install flow
- **Notes:** Platform-specific prompt; iOS users install via "Share → Add to Home Screen".

### OS Page Overlay
- **Name:** OS Page Overlay Panel
- **Target:** `.rabble-panel` variant
- **Best source:** World `RaBbLE-os.css:1–200+`
- **Duplicates collapsed:** Chrysalis ep1 OS page (subsumed)
- **Params:** Entry state transitions, content panels, code blocks
- **Notes:** Not a framework component; page-specific.

---

## MOTION & EFFECTS (Aether)

### Conic-Gradient Flowing Border
- **Name:** Flowing Conic-Gradient Border Ring
- **Target:** `.rabble-border-harmony` (Aether motion CSS, EXISTS)
- **Best source:** Aether `assets/motion/rabble-motion.css` (canonical)
- **Duplicates collapsed:** World `.rabble-border-harmony` applications (class only, never CSS redefined)
- **Params:** Gradient angle (225deg start), accent corners (magenta→violet→cyan→violet→magenta)
- **Notes:** ALREADY EXISTS in Aether. World and all members apply it; none redefine. Framework-provided, not new.

### Harmony Line (subtle divider)
- **Name:** Subtle Divider / Harmony Line
- **Target:** `.rabble-harmony-line` (Aether motion CSS, EXISTS)
- **Best source:** Aether `assets/motion/rabble-motion.css` (canonical)
- **Duplicates collapsed:** None
- **Params:** Height 1px, gradient or accent colour
- **Notes:** ALREADY EXISTS in Aether. Used for page dividers, section separators.

### Motion Tokens (durations, easing)
- **Name:** Shared Motion Vocabulary
- **Target:** Aether CSS custom properties (EXISTS)
- **Best source:** World `RaBbLE-unified.css:51–55` (--rc-dur-fast/mid/slow, --rc-ease)
- **Duplicates collapsed:** None
- **Params:** Fast=150ms, Mid=300ms, Slow=500ms; ease=cubic-bezier(0.16, 1, 0.3, 1)
- **Notes:** These are tokens, not components. Already canonical in Aether.

### Sigil Pulse Animation
- **Name:** Sigil Pulse (thinking/speaking states)
- **Target:** Aether motion component / shared animation
- **Best source:** World `RaBbLE-dock.css:54–67` (@keyframes rd2-sigil-pulse)
- **Duplicates collapsed:** None
- **Params:** Opacity pulse (0.5→1), text-shadow glow, state-duration (800ms thinking, 400ms speaking)
- **Notes:** Could be generalized as Aether animation utility.

### Member Line Staggered Reveal
- **Name:** Staggered Line Entrance Animation
- **Target:** Aether motion utility
- **Best source:** World `RaBbLE-panels.css:382–462` (memberDetailIn, memberLineIn @keyframes, staggered delays 80ms/160ms)
- **Duplicates collapsed:** None
- **Params:** Duration (rc-dur-mid=300ms), delay steps (80ms, 160ms)
- **Notes:** Used in member reveal card. Could be generalized for any staggered list reveal.

---

## AMBIENT & CRT EFFECTS (Existing Aether)

### Scanlines
- **Name:** CRT Scanlines Overlay
- **Target:** `.rabble-scanlines` (Aether CSS, EXISTS)
- **Best source:** Aether `assets/components/rabble-components.css` § Screen Overlays
- **Duplicates collapsed:** Chrysalis `RaBbLE-Grimoire.css` (subsumed)
- **Params:** Opacity (can vary), height of line pattern
- **Notes:** ALREADY EXISTS in Aether. Chrysalis and World both apply.

### Vignette
- **Name:** Vignette (darkened edges)
- **Target:** `.rabble-vignette` (Aether CSS, EXISTS)
- **Best source:** Aether `assets/components/rabble-components.css`
- **Duplicates collapsed:** None
- **Params:** Radial-gradient opacity
- **Notes:** ALREADY EXISTS in Aether.

### Chromatic Aberration
- **Name:** Chromatic Aberration (RGB shift)
- **Target:** `.rabble-chromatic` (Aether CSS, EXISTS)
- **Best source:** Aether `assets/components/rabble-components.css`
- **Duplicates collapsed:** None
- **Params:** Shift distance, blend mode
- **Notes:** ALREADY EXISTS in Aether.

### Glitch Veil
- **Name:** Glitch / Distortion Veil
- **Target:** `.rabble-glitch-veil` (Aether CSS, proposed)
- **Best source:** Chrysalis `RaBbLE-liminal.css` (glitch animation logic)
- **Duplicates collapsed:** Chrysalis ep1 Liminal scene glitch effects
- **Params:** Duration, glitch pattern, colour shift (magenta/cyan bleeding)
- **Notes:** Chrysalis had detailed glitch animations for entity state. World doesn't expose yet. Framework candidate for post-EP1.

---

## DEEP-FIELD & PARTICLE EFFECTS (NeBuLA)

### Starfield (Canvas2D)
- **Name:** Seeded Starfield / Ambient Stars
- **Target:** `nebula.effects.starfield` (NeBuLA effect)
- **Best source:** Chrysalis `RaBbLE-liminal.js:106–120` (AMBIENT data mentions "240 points seeded, drift vector locked"), Canvas2D backend
- **Duplicates collapsed:** None
- **Params:** Seed count (240), drift velocity, depth layers
- **Notes:** Chrysalis Liminal had canvas-based starfield. NeBuLA Canvas2D backend will absorb or generalize.

### Nebula Haze
- **Name:** Nebula Haze / Fog Layer
- **Target:** `nebula.effects.haze` (NeBuLA effect, proposed)
- **Best source:** Chrysalis `RaBbLE-liminal.js` mentions "deep-field canvas (starfield, nebula haze)"
- **Duplicates collapsed:** None
- **Params:** Colour palette, opacity, movement speed
- **Notes:** Conceptual in Chrysalis; not explicitly coded. Candidate for generic NeBuLA effect.

### Signal Streaks
- **Name:** Signal / Data Streaks
- **Target:** `nebula.effects.streaks` (NeBuLA effect, proposed)
- **Best source:** Chrysalis `RaBbLE-liminal.js:10` mentions "signal streaks" in deep-field canvas
- **Duplicates collapsed:** None
- **Params:** Direction, speed, colour
- **Notes:** Mentioned in Chrysalis spec; not implemented in World yet. Candidate effect.

### Constellation Lines
- **Name:** Constellation / Connection Lines (cursor-reactive)
- **Target:** `nebula.effects.constellation` (NeBuLA effect, proposed)
- **Best source:** Chrysalis `RaBbLE-liminal.js:10` ("constellation lines that reach toward the cursor")
- **Duplicates collapsed:** None
- **Params:** Seed points, connection target (cursor), colour, animation speed
- **Notes:** Chrysalis Liminal concept; not built in World. Candidate for generic NeBuLA effect.

### Entropy Shader
- **Name:** Entropy-Driven Particle Effect
- **Target:** `nebula.effects.EntropyShader` (NeBuLA, EXISTS)
- **Best source:** NeBuLA `src/effects/entropy-shader.js:1–100+`
- **Duplicates collapsed:** None
- **Params:** Entropy input, colour palette, particle density
- **Notes:** Already in NeBuLA. Renders entropy as visual noise/distortion.

### Ambient Field
- **Name:** Ambient Background Particle Field
- **Target:** `nebula.effects.AmbientField` (NeBuLA, EXISTS)
- **Best source:** NeBuLA `src/effects/ambient-field.js:1–80+`
- **Duplicates collapsed:** None
- **Params:** Particle count, movement pattern, colour palette
- **Notes:** Already in NeBuLA. Used for page backgrounds.

### Attractor / Gravitational Effect
- **Name:** Attractor Point / Gravitational Pull
- **Target:** `nebula.effects.EntropyAttractor` (NeBuLA, EXISTS)
- **Best source:** NeBuLA `src/effects/attractor.js:1–60+`
- **Duplicates collapsed:** None
- **Params:** Attractor position, pull strength, affected particles
- **Notes:** Already in NeBuLA. Particles converge toward a point.

---

## DESIGN TOKENS & TYPOGRAPHY (Aether, EXISTS)

### Accent Colour Palette
- **Name:** Semantic Accent Colours
- **Target:** Aether CSS custom properties (EXISTS)
- **Best source:** Aether `RaBbLE-Palette.md` (Grimoire)
- **Duplicates collapsed:** All members reference single palette, no redefinition
- **Params:** Magenta, Cyan, Violet, Pink, Green, Yellow, Red
- **Notes:** ALREADY EXISTS in Aether. World aliases them as --rc-accent-* tokens.

### Glass Recipe (colour-mix + blur)
- **Name:** Tinted-Glass Surface Recipe
- **Target:** Aether CSS utility custom properties (EXISTS)
- **Best source:** World `RaBbLE-unified.css:28–31` (--rc-glass-80, --rc-glass-78, --rc-blur)
- **Duplicates collapsed:** None
- **Params:** Glass opacity (80% or 78%), blur amount (5px or 3px)
- **Notes:** ALREADY EXISTS. Recipe: `color-mix(in srgb, <surface> <opacity>%, transparent) + blur()`.

### Font Stacks (Mono, UI)
- **Name:** Canonical Font Families
- **Target:** Aether CSS custom properties (EXISTS)
- **Best source:** World `RaBbLE-unified.css:35–36` (--rc-font-mono, --rc-font-ui)
- **Duplicates collapsed:** None
- **Params:** Mono: JetBrains Mono / Fira Code; UI: Inter / system-ui
- **Notes:** ALREADY EXISTS in Aether.

### Sizing Scale
- **Name:** Typographic Sizing Scale
- **Target:** Aether CSS custom properties (EXISTS)
- **Best source:** World `RaBbLE-unified.css:34–42` (--rc-size-xs through --rc-size-2xl)
- **Duplicates collapsed:** None
- **Params:** xs=11px, sm=13px, md=15px, lg=18px, xl=24px, 2xl=32px
- **Notes:** ALREADY EXISTS in Aether.

### Spacing Scale
- **Name:** Layout Spacing Scale
- **Target:** Aether CSS custom properties (EXISTS)
- **Best source:** World `RaBbLE-unified.css:44–49` (--rc-gap-xs through --rc-gap-xl)
- **Duplicates collapsed:** None
- **Params:** xs=4px, sm=8px, md=16px, lg=24px, xl=40px
- **Notes:** ALREADY EXISTS in Aether.

### Z-Index Layers
- **Name:** Stacking Context Layers
- **Target:** Aether CSS custom properties (EXISTS)
- **Best source:** World `RaBbLE-unified.css:57–63` (--rc-z-floor through --rc-z-overlay)
- **Duplicates collapsed:** None
- **Params:** floor=0, panels=10, entity=20, dock=30, rail=40, overlay=50
- **Notes:** ALREADY EXISTS in Aether.

---

## NEWLY CONSOLIDATED COMPONENTS (Aether / NeBuLA Targets)

### .rabble-panel (Aether CSS)
**Consolidates:** `.rc-panel`, glass container pattern
**Knobs:** title (optional), inner gap, box-shadow dual-accent
**Status:** Ready to promote from World rc-panel to Aether generic .rabble-panel

### .rabble-card (Aether CSS)
**Consolidates:** `.rc-member-card`, `.rc-collective-card` variants
**Knobs:** accent stripe (3px), body layout, hover glow, active state
**Status:** Ready to promote; create card-flat and card-raised variants

### .rabble-btn (Aether CSS)
**Consolidates:** `.rc-btn` primary/secondary
**Knobs:** Primary (magenta), secondary (muted), icon slot, active translateY
**Status:** Already in Aether; World applies correctly

### .rabble-badge (Aether CSS)
**Consolidates:** `.rc-badge`, `.rd2-live-badge`
**Knobs:** Accent key, inline display, pill shape
**Status:** Ready to promote

### .rabble-dock (Aether CSS)
**Consolidates:** `.rd2-*` family (bar, pane, sigil, history, input)
**Knobs:** Bar height, expanded height, transmission truncation
**Status:** Candidate; may stay in World if too specific

### .rabble-log (Aether CSS)
**Consolidates:** `.rd2-history`, `.rd2-line`, `.rd2-line--*` (user/entity/system)
**Knobs:** Line type colour, monospace family, timestamps, sigil prefix
**Status:** Generic utility; promote to Aether

### <rabble-entity> (NeBuLA)
**Consolidates:** Custom element rendering (Canvas2D → Three.js)
**Status:** EXISTS; Layer 1 (Canvas2D reference) in place; Layer 2 (Three.js) in progress

### <rabble-floor> (NeBuLA, proposed)
**Consolidates:** Three.js Grimoire floor (eye, portal, graph)
**Knobs:** Grimoire data, member UV mapping, camera control
**Status:** Candidate; World `RaBbLE-floor.js` is current best implementation

### nebula.ui.createEntityMini() (NeBuLA)
**Consolidates:** Compact entity render
**Status:** EXISTS in NeBuLA

### nebula.ui.createGrimoireEye() (NeBuLA)
**Consolidates:** Watching eye animation
**Status:** EXISTS in NeBuLA

### nebula.ui.createGrimoireRing() (NeBuLA)
**Consolidates:** Rune ring animation
**Status:** EXISTS in NeBuLA

### nebula.effects.starfield / haze / streaks / constellation (NeBuLA, proposed)
**Consolidates:** Deep-field canvas effects from Chrysalis Liminal
**Status:** Candidates; Liminal concept, not yet built generically

---

## NEW / UNMAPPED

Components or effects that don't fit the frozen roster and need orchestrator decision:

1. **Member Detail Reveal Animation** — complex multi-element stagger (memberDetailIn + memberLineIn). Could be Aether animation utility or stay World-local.
2. **Collective Two-Column Layout** — grid with member list + detail pane. Page layout, not reusable component; stays in World.
3. **Dock Expansion Mechanism** — JS state machine (expand/collapse/streaming). Functional logic, not visual framework.
4. **Floor Bilinear Color Field** — Math utility for Grimoire member UV → RGB interpolation. Utility, not visual component.
5. **Graph Edge Rendering** — Currently Three.js inline; could become generic `nebula.effects.graphEdges` after E.2.
6. **OS Page State Machine** — Entry/ready/error states. Page-specific choreography, not framework component.
7. **Account Session Export** — Functional feature, not visual.

**RECOMMENDATION:** All seven are World-specific or early-stage. Hold in World; no framework extraction needed pre-EP1.

---

## AMBIGUOUS OWNERSHIP

Effects that could belong to Aether (CSS) or NeBuLA (JS/rendering). Orchestrator decision:

| Name | Could Be | Recommendation |
|------|----------|---|
| **Glitch Veil** | CSS animation class (Aether) OR NeBuLA WebGL shader | → **NeBuLA post-EP1** (shader-based glitch is more sophisticated; CSS version too simple for entity state binding) |
| **Scanlines / Vignette** | CSS overlay (Aether, EXISTS) OR shader (NeBuLA) | → **Keep Aether CSS** (simple, performant; shader overkill) |
| **Starfield / Haze** | CSS gradients (Aether) OR Canvas2D particles (NeBuLA) | → **NeBuLA Canvas2D** (particle physics required; gradients insufficient for Chrysalis fidelity) |
| **Signal Streaks** | CSS animation (Aether) OR Canvas2D (NeBuLA) | → **NeBuLA Canvas2D** (reactive to cursor; particle-based expected) |
| **Constellation Lines** | SVG (Aether assets) OR Canvas/WebGL (NeBuLA) | → **NeBuLA** (cursor reactivity, dynamic topology) |
| **Sigil Pulse** | Aether animation utility (shared) OR dock-specific CSS | → **Aether utility** (generalize; use in other contexts) |
| **Member Line Stagger** | Aether animation utility (shared) OR World-only | → **Aether utility** (promote as `.rabble-stagger-in` animation) |

---

## SUMMARY COUNTS

**By category:**
- Surfaces & Layout: 3 (mostly not reusable)
- Cards & Containers: 4
- Controls & Buttons: 4
- Navigation & Status: 4
- Entity & Render: 7 (NeBuLA-owned)
- Chat & Transmissions: 4
- Account & Identity: 2
- Overlays & Modals: 3
- Motion & Effects (Aether existing): 4
- Ambient & CRT (Aether existing): 4
- Deep-Field & Particles (NeBuLA): 7
- Design Tokens (Aether existing): 6

**TOTAL distinct components + effects:** 52
**Already framework-canonical (Aether/NeBuLA):** 26
**Ready for consolidation:** 18
**New/Unmapped:** 7
**Ambiguous (awaiting decision):** 7 (handled separately)

**Files analyzed:**
- World CSS: 8 files (~2,327 lines)
- World JS: 16 files (~4,746 lines)
- Chrysalis ep1: 46 files (sampled key: liminal.js, grimoire.js, landing CSS)
- Aether: 5 component/motion CSS files (canonical)
- NeBuLA: src/effects, src/ui (existing exports)

---

## NEXT STEPS (Orchestrator)

1. **BUILD PHASE 1A** — Promote World rc-* classes to Aether generic .rabble-* CSS
   - `.rabble-panel` (from rc-panel)
   - `.rabble-card` + card-flat / card-raised variants
   - `.rabble-badge` (from rc-badge)
   - `.rabble-log` (from rd2-history pattern)

2. **BUILD PHASE 1B** — Create Aether animation utilities
   - `.rabble-stagger-in` (memberLineIn logic)
   - Sigil pulse as shared mixin

3. **BUILD PHASE 2** — Evaluate NeBuLA framework targets
   - `<rabble-floor>` as formal element (currently standalone module)
   - `nebula.effects.starfield / haze / streaks / constellation` (from Chrysalis Liminal archaeology)
   - Glitch shader (post-EP1)

4. **DOCUMENTATION** — Index consolidated components in Grimoire
   - Aether component catalog
   - NeBuLA visual API reference
   - Migration guide for World pages

---

**Ledger complete.** All artifacts mapped, deduplication resolved, framework boundaries clarified. Ready for build orchestration.
