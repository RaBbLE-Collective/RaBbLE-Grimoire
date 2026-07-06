# RaBbLE-NeBuLA-Refinement-Backlog.md

```
transcribe ~ grimoire >> S107 entity-visual refinement notes captured for next session // %NEBULA_REFINE_BACKLOG%
```

> Actionable near-term refinements for the NeBuLA entity (2D + 3D) and the Studio
> tooling. Distinct from `RaBbLE-NeBuLA-Ideas.md` (far-future Episode 3+ pool) and
> the episode `Roadmap`. Captured from Mark's notes in **S107** (2026-06-15), right
> after the entity-visual debug pass that made NeBuLA the single 2D+3D renderer.
> Pick these up in a dedicated refinement session.

---

## Context

S107 fixed: 2D bokeh/flicker/definition, connection mesh, portal glow; 3D palette
colors + density (additive nebula) + layered eyes; and wired the NeBuLA Demo's
Layer 2 to `NeBuLA.ThreeJsBackend` so NeBuLA renders the entity on every surface.
The items below are the next round of polish Mark flagged while reviewing it.

---

## 1. Entity geometry — mouth / portal placement & tunables

> **Terminology to resolve first:** Mark refers to a **"mouth"** and, separately, to
> the **3D "portal eyebrows."** Today the cyan/magenta **portal arcs** sit near the
> eyes (cyan above-left, magenta below-right) and the Layer-1 reference calls the
> portal "the elliptical mouth shape for communication." Confirm with Mark whether
> "mouth" = a distinct lower element vs. the existing portal, before moving geometry.

- **Mouth must be toggleable** — show/hide independent of the eyes. (Canvas2D already
  has `setPortalVisible()`; extend the concept / expose it, and mirror in 3D.)
- **Bring the mouth lower down the face** — currently the portal arcs sit close to the
  eyes; the mouth should read as a separate lower feature.
- **Mouth↔eye margin must be tweakable** — expose the vertical gap as a live parameter
  (Canvas2D: `BASE_Y_OFFSET` / `EYE_H * 0.44` factors in `portal-system.js` + `eye-system.js`;
  3D: the `+0.15 / -0.15` portal offsets and portal-arc `center.y` in `threejs-backend.js`).
- **Surface these in NeBuLA Studio** as live sliders (see §4).

## 2. 3D portal arcs ("eyebrows") — `threejs-backend.js`

- **Positional refinement** — the left/right portal arc placement (`_buildPortals`
  centers `{x:-0.38,y:0.40}` / `{x:0.38,y:0.70}`) needs re-tuning relative to the eyes.
- **Thicker lines** — `LineBasicMaterial.linewidth` is unreliable across WebGL drivers;
  use a ribbon/tube (e.g. `THREE.TubeGeometry` / a mesh line) or layered offset lines
  to get genuinely thicker arcs.
- **More glow** — add an additive bloom pass around the arcs (mirror the layered-glow
  approach already used for the 3D eyes, or a post-process `UnrealBloomPass`).

## 3. Boot animation

- **Graph particles should begin to appear *during* boot** — some connection-mesh
  lines should fade in through convergence, not all at once at the end.
- **No post-boot pop-in** — the hand-off from boot → idle currently reads as a sudden
  appearance. Smooth it (the `glowRampT` ramp + connection `connProgress` thresholds in
  `connection-system.js` / `canvas2d/index.js` are the levers; Layer-2 has the analogous
  `_updateConnections(convergence)` gate at `convergence < 0.2`).

## 4. NeBuLA Studio — unify Demo + Studio into one WYSIWYG editor

> **Status (S198):** MVP in progress — plan at `RaBbLE-Grimoire/log/plans/NeBuLA-Studio-Plan.md`. Palette auto-parsed from the component catalog page, JSON layout schema, breakpoint-switcher canvas. HTML export and the tunable-sliders integration described below are later phases, not yet started.

- **Combine `RaBbLE-NeBuLA-Demo.html` and `RaBbLE-Studio.html`** into a single,
  genuinely useful WYSIWYG studio editor that covers **both the 2D and 3D entity**.
- **Studio is the home** for: tweaking/using the NeBuLA render engine, and **creating
  new animations, assets, and reusable graphical effects.**
- Expose the tunables from §1–§3 as live controls (mouth toggle, mouth Y, mouth↔eye
  margin, portal thickness/glow, particle size/density/glow, entropy, boot timeline).
- Should be able to **save/export** a config snapshot (Canvas2D backend already has
  `getSnapshot()` / `setParticleConfig()` / `setEyeConfig()` — extend to 3D and to a
  shareable preset format).

## 5. General entity effects & tuning

- Broader pass on entity effects and tuning knobs (open-ended — gather specifics with
  Mark in the refinement session). Candidates: speaking/thinking-state visual differences,
  saccade/blink tuning, reusable effect presets feeding the Studio asset library.

---

## Revision History

| Date | Change |
|---|---|
| 2026-06-15 (S107) | Backlog created from Mark's post-debug review notes |
