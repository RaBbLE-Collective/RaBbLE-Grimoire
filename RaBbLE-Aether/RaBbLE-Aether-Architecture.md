# RaBbLE-Aether-Architecture.md

```
transcribe ~ grimoire >> design system defined // %AETHER_SPEC%
```

RaBbLE-Aether is the visual design system and asset library for the RaBbLE Collective. It is a publishing repo — it holds and publishes canonical visual assets that all other members reference.

---

## Role in the Collective

| Concern | Owner |
|---|---|
| Color palette (vars, semantic tokens) | `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md` |
| Rendered assets (SVG, PNG, icons, logos) | `RaBbLE-Aether/assets/` |
| Motion principles and keyframe definitions | `RaBbLE-Aether` (planned) |
| Member-facing CSS bundle (palette as CSS vars) | `RaBbLE-Aether` (planned) |

The palette lives in Grimoire because it is a protocol contract — all members must agree on it. Aether *publishes* the palette as renderable artifacts; it does not own the source.

---

## Asset Directory

```
assets/
  logos/       ← wordmarks, logotypes (SVG)
  icons/       ← system icons, UI icons (SVG)
  ansi/        ← ANSI art for terminal surfaces
  palette/     ← palette exported as CSS, JSON, and SCSS tokens
```

Status: structure defined, assets pending population.

---

## Consumer Pattern

Member repos reference Aether assets by path or via a future published bundle. They do not copy assets into their own directories.

```html
<!-- Correct: reference by URL or relative path to Aether -->
<img src="../RaBbLE-Aether/assets/logos/rabble-wordmark.svg">

<!-- Wrong: copy-pasted asset inside member repo -->
<img src="assets/rabble-wordmark.svg">
```

---

## Palette Publishing

The canonical palette definition is in `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md`.

Aether's job is to export that definition into consumable forms:
- `assets/palette/rabble-palette.css` — CSS custom properties
- `assets/palette/rabble-palette.json` — design token JSON
- `assets/palette/rabble-palette.scss` — SCSS variables

Until this export exists, members source palette vars from `rabble-theme.css` in RaBbLE-World or define them locally following the Grimoire spec.

---

## Epoch 0 Goal

Establish structure. No assets required yet. The architecture doc (this file) and the `assets/` directory scaffold is the Epoch 0 deliverable for Aether.

---

## Lessons & Gotchas (distilled from S5–S46)

- **Aether-first is the doctrine.** Aether owns ALL look-and-feel — colors, fonts,
  motion, component CSS. Any member CSS rule with a literal `#hex` or `font-family` is
  a violation; it must reference an Aether `var(--rabble-*)` token instead.
- **Aether owns ALL fonts** (Orbitron, Exo 2, Share Tech Mono) — no member should load
  Google Fonts independently. Brand constant `.rabble-brand-flow`:
  `text-transform: none; font-weight: 900; letter-spacing: 0`.
- **CDN split:** `dist/aether.css` is the dev/watch output, `dist/aether.min.css` is
  prod-only (`npm run build`). Pages must link the dev file during development — see
  the World gotcha about stale `.min.css` loads.
- **Harmony-effect mask technique:** the old `z-index: -1` glow approach bled gradient
  through transparent backgrounds. Fixed with CSS `mask: exclude` compositing, which
  confines the gradient to the border ring regardless of background transparency.
- **`@property --harmony-angle` is a flagged browser-support risk** (unconfirmed —
  landing-page borders once failed to render while a hardcoded demo page worked, and
  the fix was just to roll back to the stable version). If it recurs, the next thing to
  try is replacing `conic-gradient(from var(--harmony-angle))` with `transform:
  rotate()` or a cycling `box-shadow`, neither of which depends on `@property`.
- **"Cotton Candy Swirl"** (rotating conic-gradient aurora wash on semi-transparent
  panels) was discovered by accident and banked for future entity "speaking"/alert/boot
  states — see `RaBbLE-Aether-Effects-Bank.md`.
- **Aether went from "stub, not yet a git repo" to a fully built, privately-hosted repo
  within about a week** (mid-May 2026) — any doc still describing it as a stub is
  stale.
