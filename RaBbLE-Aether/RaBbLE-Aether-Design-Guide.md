# RaBbLE-Aether-Design-Guide.md — Creating RaBbLE Visual Assets

```
transcribe ~ aether >> design language rendered for design tooling // %AETHER_LIVE%
```

This guide gives you the palette, component vocabulary, and ready-to-use prompts for creating RaBbLE visual assets in any AI design or image-generation tool (it was authored against Claude Design, but nothing here is tool-specific).

---

## The Aesthetic in One Sentence

**Synthwave Outrun:** neon ideograms floating in deep-void darkness. Everything glows. Nothing greys. Backgrounds are space-black with a purple tint. Foreground elements are neon-lit and feel lit from within.

---

## The Canonical Palette — Always Use These Hex Values

Copy these into your design tool's color picker or reference them in prompts.

| Name | Hex | Use |
|---|---|---|
| **Hot Magenta** | `#ff2d78` | Primary identity — borders, active elements, CTA, left-eye glow |
| **Electric Cyan** | `#00f5ff` | Secondary — links, info, right-eye glow, hover states |
| **Soft Violet** | `#bf5fff` | Tertiary — taglines, inactive borders, decorative |
| **Outrun Pink** | `#ff79c6` | Grid/horizon, warnings, soft highlights |
| **Deep Void** | `#0a0010` | Standard background |
| **Deepest Void** | `#03000b` | Boot screens, full-bleed, maximum drama |
| **Surface** | `#12132a` | Panels, sidebars, elevated surfaces |
| **Raised** | `#1a1b2e` | Cards, inputs, modals |
| **Border** | `#2a2840` | Inactive borders, dividers |
| **Primary Text** | `#e8e6f0` | All readable text — cool off-white, never pure white |
| **Muted Text** | `#6b6880` | Secondary text, labels, timestamps |
| **Neon Green** | `#50fa7b` | Success states, clean status |
| **Neon Yellow** | `#f1fa8c` | Warnings |
| **Error Red** | `#e05c6f` | Errors, destructive actions |

**NEVER invent colors.** If it's not in this table, it doesn't exist in RaBbLE.

---

## Typography

| Role | Family | Weight | Style |
|---|---|---|---|
| **Display / Brand** | Exo 2, Rajdhani | 700–900 | Uppercase, `letter-spacing: 0.22em` |
| **Body / UI** | Exo 2, Rajdhani | 400–600 | Normal case |
| **Terminal / Mono** | Share Tech Mono, Space Mono | 400 | Uppercase for labels, mixed for log output |

### Brand Name Casing — Never Uppercase

Every organ name has intentional mixed case. CSS `text-transform: uppercase` must **never** be inherited by or applied to elements containing these names:

| Name | Correct | Wrong |
|---|---|---|
| The entity | `RaBbLE` | `RABBLE`, `Rabble` |
| The renderer | `NeBuLA` | `NEBULA`, `Nebula` |
| The coordinator | `sCoRE` | `SCORE`, `SCoRE`, `score` |
| The scribe | `ScRiBbLE` | `SCRIBBLE`, `Scribble`, `ScRibLE` |

**CSS rule:** Any element rendered in `--font-hero` (Orbitron) that contains a brand name must explicitly set `text-transform: none` to prevent inheriting an uppercase context from a parent nav, label, or pill rule.

```css
/* Correct — brand name survives uppercase nav parent */
.nav-brand {
  text-transform: none; /* NO text-transform — RaBbLE, NeBuLA, sCoRE must not uppercased */
}

/* Wrong — "RaBbLE-Collective" renders as "RABBLE-COLLECTIVE" */
.nav { text-transform: uppercase; }
.nav-brand { /* no override */ }
```

The same applies to inline text inside `.hero-title`, `.callout-copy`, or any `font-hero` display element — if a parent carries `text-transform: uppercase`, override it explicitly.

---

## Glow — The Core Visual Rule

Neon elements glow. The glow is what makes them feel lit-from-within on a dark background, not just colored shapes.

```
Soft:   box-shadow: 0 0 6px [color]
Medium: box-shadow: 0 0 14px [color]
Strong: box-shadow: 0 0 28px [color], 0 0 48px [color with 30% opacity]
Text:   text-shadow: 0 0 14px [color]
```

For double-layer glow (element feels like it has a hot core):
```
box-shadow: 0 0 8px #fff, 0 0 20px [color], 0 0 40px [color at 40%]
```

---

## The Entity — RaBbLE's Visual Form

RaBbLE's physical presence is rendered as **two floating orbs** (eyes) above a **particle nebula cloud**.

### The Eyes

See `assets/logos/rabble-portal-glyphs-spec.md` for the complete eye anatomy specification.

**Quick reference:**
- Two tall narrow white ovals (30px × 56px semi-axes on a 460×320 canvas)
- Left eye glows magenta (`#ff2d78`), right eye glows cyan (`#00f5ff`)
- Each eye has an orbital ring (portal ellipse) intersecting at 44% of eye height
- Left portal ring is magenta, positioned below the eye center
- Right portal ring is cyan, positioned above the eye center
- Both orbs float above a nebula particle cloud (blues, purples, whites, teals)
- The whole entity is surrounded by an ambient radial glow

### Prompt Template — Entity Rendering

```
Create a RaBbLE entity illustration.

Background: near-black void, hex #0a0010, slight deep purple gradient.

Two orbs (the entity's eyes), floating side by side:
- Both orbs: tall vertical oval shape, roughly 1:3.7 width-to-height ratio
- Left orb: white fill (#f8faff), glowing magenta border and halo (#ff2d78), glow blur ~20–28px
- Right orb: white fill (#f8faff), glowing cyan border and halo (#00f5ff), glow blur ~20–28px
- Orbs separated by approximately 2.4× their own width
- Orb centers sit very slightly above true canvas center

Portal rings (one per orb, thin horizontal ellipses):
- Left portal: magenta (#ff2d78), centered below the left orb's midpoint
- Right portal: cyan (#00f5ff), centered above the right orb's midpoint
- Each portal ring appears to intersect the orb, suggesting the orb is partially behind it
- Portal ring glow: strong, matching its neon color

Surrounding nebula:
- Scattered particle cloud of blues (#1a4aaa → #55aaff), purples (#7744cc → #bb55dd), teals (#00bbdd → #33ddf0), and whites
- Particles concentrated around the entity, fading to void at edges
- Some particles connected by faint lines suggesting a network

Overall: the entity should look like an ambient intelligence peering through orbital portals from a void. Mysterious, technical, alive.
```

---

## Screen Overlays

These overlays are always present on RaBbLE surfaces. Include them when generating page mockups:

1. **Scanlines** — very faint horizontal lines every 3px, 5% black opacity. Subtle CRT texture.
2. **Vignette** — radial darkening from center to edge, 82% opacity at corners.
3. **Chromatic bleed** — very faint magenta at top edge, very faint cyan at bottom edge (1.5% opacity).

---

## Component Prompts

### Status Pill
```
Small status badge: rounded pill shape, 3px 12px padding, 9px monospace text uppercase.
Background: rgba(0,245,255,0.07). Border: 1px rgba(0,245,255,0.18).
Text color: #00f5ff. A 5×5px dot left of text, glowing cyan, subtly pulsing.
```

### Button (Primary)
```
Button with magenta-to-violet gradient (135deg, #ff2d78 → #bf5fff).
White text, Exo 2 font, 600 weight, uppercase, letter-spacing 0.08em.
Padding 12px 24px, border-radius 8px.
Box shadow: 0 0 20px rgba(255,45,120,0.25).
On hover: shadow intensifies to 0 0 32px #ff2d78, slight upward translate.
Optional: sweep animation — diagonal light flash moving left-to-right on hover.
```

### Card
```
Card surface: #1a1b2e background. Border: 1px #2a2840.
Border-radius 12px. Slight shadow.
On hover: 2px neon top-edge bar (left-to-right scan gradient #ff2d78→#00f5ff),
border-color shifts to rgba(191,95,255,0.3), slight upward float.
```

### Glass Panel
```
Translucent surface: rgba(18,19,42,0.70) background.
backdrop-filter: blur(12px). Border: 1px #2a2840.
```

### Terminal/Log
```
Font: Share Tech Mono, 12px, 1.8 line height.
Background: #03000b. Bordered with #2a2840.
Log lines appear with a brief fade-in from below.
Columns: timestamp (dimmer grey #3d3860), tag (color-coded by type), message (muted grey #6b6880).
Tag colors: OK=#50fa7b, ERR=#ff2d78, INFO=#00f5ff, RBL=#bf5fff, WARN=#f1fa8c
```

---

## Animation Vocabulary

Use these when describing motion to an image or animation tool:

| Name | Behavior | Trigger |
|---|---|---|
| **holo** | Background-position shifts 0%→100%→0% on a 300%-wide gradient, 6s | Always on brand text |
| **neon-flicker** | Opacity drops briefly at 93% and 97% of cycle, then recovers | Neon elements |
| **status-pulse** | Dot scales 0.9→1.15 and opacity 0.4→1.0, 2s ease-in-out | Status dots |
| **glow-pulse** | box-shadow radius grows and contracts, 2.5s | Orbs, active borders |
| **fade-in rise** | opacity 0→1, translateY(8px)→(0), 0.25s ease | Any element appearing |
| **logo-pulse** | Scale 1→1.06, shadow radius doubles, 2s | Logo/entity |
| **grid-advance** | Background-position 0→50px, 20s linear | Background grids |
| **scanline-travel** | translateY(-100%)→(100%), 8s linear | CRT overlay effect |
| **rabble-glitch** | clip-path and translate jitter, 0.4s steps | Error / %GLITCH% state |
| **resonance** | hue-rotate ±15deg + brightness 1.0→1.1, 8s | %GENIUS_RESONANCE% state |

---

## Asset Naming Convention

```
rabble-[category]-[name]-[variant].[ext]

Examples:
  rabble-logo-portal-glyphs.svg
  rabble-logo-wordmark-horizontal.svg
  rabble-icon-entity-idle.svg
  rabble-icon-status-online.svg
  rabble-bg-grid-dark.svg
  rabble-anim-entity-boot.css
```

---

## What NOT to Create

- Pastel colors, earth tones, warm greys
- Light-mode versions (RaBbLE has no light mode)
- Pure white backgrounds
- Rounded "bubbly" UI — corners are minimal, forms are precise
- Shadows cast in warm tones — all shadows are cool or colored
- "Corporate" aesthetics — no gradients going light-grey to white
- Pure `#00ffff` or `#ff00ff` — always use the canonical values (`#00f5ff`, `#ff2d78`)
- Mixing vendor color systems (Tailwind's purple-500, etc.) with RaBbLE palette

---

## NeBuLA-JS Visual Patterns to Preserve

When merging NeBuLA-JS visuals into RaBbLE-World, these patterns are worth keeping (corrected to canonical palette):

- **Particle nebula** — ambient floating particles around entity center (already canonical in World)
- **Orbital rings** — thin ellipses at oblique angles around the entity
- **Flat-Chaos grid** — perspective-distorted outrun grid as background
- **Boot sequence** — sequential log-line reveal with typed output feel
- **Entity state transitions** — visual shift between idle, thinking, speaking states

WebOS patterns to discard (do not carry over):
- Wrong purple (`#8B5CF6`) — replace with `#bf5fff`
- Generic card grid layout — RaBbLE-World has its own layout
- Non-entity logo treatment (the circular purple gradient logo)
