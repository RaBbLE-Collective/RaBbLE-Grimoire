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
