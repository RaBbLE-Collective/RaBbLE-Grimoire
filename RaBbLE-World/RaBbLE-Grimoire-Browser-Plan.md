# Grimoire Browser Integration Plan

> Agent handoff doc. Implements the Grimoire summoning-circle applet into RaBbLE-World.
> Source designs: `RaBbLE-New-Designs/` in the Collective root.
> Read `RaBbLE-New-Designs/INTEGRATION.md` §3 before starting.

---

## Context

A design exploration in `RaBbLE-New-Designs/` produced three Grimoire sidebar variants (A/B/C). **Variant B — Summoning Circle** (`GrimoireCircle`) is chosen. The applet is a Collective/Grimoire document browser styled as a mystical summoning interface: a rotating rune ring, holographic doc readouts, and a watching-entity header that recolors on summon.

Design source files are React/JSX + plain CSS (no build step needed — Babel-standalone in browser).

---

## Branch State

Feature branches already created:
- `RaBbLE-World`: `feat/grimoire-summoning-circle` — **use this branch**
- `RaBbLE-Aether`: `feat/grimoire-entity-spec` — entity spec files already copied in
- `RaBbLE-NeBuLA`: `feat/grimoire-entity-spec` — entity spec + reference images already copied in

Aether and NeBuLA branches have docs only (no code changes). They're ready to merge. World branch has no code yet.

---

## What's Already Done

**Aether (`feat/grimoire-entity-spec`):**
- `RaBbLE-Entity-Visual-Spec.md` added at repo root
- `assets/entity/entity-doc-compare.png` + `assets/entity/entity-reference.png` added
- `CONTEXT.md` updated with entity spec reference row

**NeBuLA (`feat/grimoire-entity-spec`):**
- `specs/visual-spec.md` (entity spec for Three.js rebuild brief)
- `specs/canvas-reference.png` + `specs/doc-fidelity.png` (reference images)
- `CONTEXT.md` updated with entity visual spec section

---

## World Integration Playbook (§3.2 of INTEGRATION.md)

### Prep: checkout the right branch

```bash
cd RaBbLE-World
git checkout feat/grimoire-summoning-circle
```

### Step 1 — Copy and strip Grimoire source files

From `RaBbLE-New-Designs/`:

**`world/js/RaBbLE-Grimoire.jsx`** (copy from `grimoire-variants.jsx`):
- Keep: `GrimoireCircle`, `EntityCreature`, `ENTITY_PALETTES`, `entityDots`, `SummonCard`, `RuneRing`, `HologramSigil`, `HologramReadout`, `AmbientEntity`, `WatchingEntity`, `Backdrop`, `ChromeHeader`, `DocReader`, `ReaderRuneDraw`
- Drop: `GrimoireCodex` (variant A), `GrimoireTome` (variant C)
- Change the export at the bottom to only expose `GrimoireCircle`

**`world/css/RaBbLE-Grimoire.css`** (copy from `grimoire-variants.css`):
- Keep: `.sc-*` (Summoning Circle), `.ec-*` (EntityCreature), `.gv-*` (shared void panel/backdrop)
- Drop: `.gc-*` (Codex variant A), `.gt-*` (Tome variant C)

**`world/js/RaBbLE-Grimoire-Data.jsx`** (copy `grimoire-data.jsx` as-is):
- Audit `GRIMOIRE_DOCS` array — some entries are placeholder lore. Mark or replace with real doc references later.

### Step 2 — Create the Grimoire page

Create `world/RaBbLE-Grimoire.html` by adapting `RaBbLE-Chat.html` as the structural template:
- Load Aether CSS (same as other pages)
- Load `RaBbLE-NeBuLA.js` bundle (for `<rabble-entity>`)
- Load React + ReactDOM + Babel-standalone (from CDN):
  ```html
  <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
  <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  ```
- Load `RaBbLE-Grimoire.css`
- Load `RaBbLE-Grimoire-Data.jsx` (type="text/babel")
- Load `RaBbLE-Grimoire.jsx` (type="text/babel")
- Mount `<GrimoireCircle />` into a `<div id="grimoire-root"></div>`
- Layout: the Grimoire applet is 340px wide. On desktop, render it centred or in a side-panel layout.

### Step 3 — Add fonts check

The Grimoire uses `Orbitron`, `Exo 2`, `Share Tech Mono`. These are already imported by Aether. No extra font imports needed.

### Step 4 — Add link from landing

In `index.html` or wherever the nav links live, add a link to `world/RaBbLE-Grimoire.html`.

### Step 5 — Smoke test

1. Open `world/RaBbLE-Grimoire.html` locally
2. Click a doc card → rune ring should accelerate
3. Hologram readout should rise
4. Entity in header should recolor to the doc kind's color
5. Search field should filter docs
6. Entity creature thumbnails should show the twin-slit orb design (not circle eyes)

### Step 6 — Commit

```bash
git add world/RaBbLE-Grimoire.html world/js/RaBbLE-Grimoire.jsx world/js/RaBbLE-Grimoire-Data.jsx world/css/RaBbLE-Grimoire.css
git commit -m "spark ~ world >> Grimoire summoning-circle applet: variant B // %GRIMOIRE_LIVE%"
```

---

## EntityCreature Visual Check

The `EntityCreature` component in `grimoire-variants.jsx` was updated during this design cycle to match the canonical entity geometry:
- Eye orbs: **tall ellipses** (eyeRx=1.95, eyeRy=3.55 in a 60×40 viewBox) — NOT circles
- White fill (`#f8faff`) with colored stroke glow
- Asymmetric portal offsets: left portal **below** eye, right portal **above**

Before integrating: compare `EntityCreature` output visually against `specs/canvas-reference.png` in NeBuLA. If the proportions look wrong, check the geometry constants in the JSX against `RaBbLE-Entity-Visual-Spec.md` §Geometry.

---

## Files Reference

| Source (RaBbLE-New-Designs/) | Destination |
|---|---|
| `grimoire-variants.jsx` (stripped) | `world/js/RaBbLE-Grimoire.jsx` |
| `grimoire-variants.css` (stripped) | `world/css/RaBbLE-Grimoire.css` |
| `grimoire-data.jsx` | `world/js/RaBbLE-Grimoire-Data.jsx` |
| *(new file)* | `world/RaBbLE-Grimoire.html` |

Source files in `RaBbLE-New-Designs/` are read-only reference — do not edit them.

---

## After This Work

1. Open PRs titled `feat(spec): canonical entity visual identity` in Aether and NeBuLA
2. Open PR titled `feat(grimoire): summoning-circle applet · variant B` in World
3. Update `SESSION-LOG.md` + `LATEST` block
4. Run `bash spells/distill-gists.sh` to regenerate gists with entity spec content
