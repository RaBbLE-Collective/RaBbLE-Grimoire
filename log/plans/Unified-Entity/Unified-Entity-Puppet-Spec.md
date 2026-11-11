# RaBbLE Unified Entity: puppet and render schema (draft 10b)

```
spark ~ grimoire/entity >> one body, one registry, every surface draws the same RaBbLE // %DRAFT_0%
```

> **Status (draft 10b, 2026-11-10): the RIG is settled enough to build on; the EXPRESSION layer is not started.** Mark accepted the front view, the colour swap, the portal swap and the +-10 degree tilt from the 0 degree baseline as the baseline. Views above about 25 degrees show perspective oddities (accepted for now); the transitions (portal swap in particular, which reads non-uniform and robotic at some angles) are to be refined in later passes. **How to read this document:** section 0 is the ruling log and is authoritative; **rulings 15 to 36 supersede the body text where they differ.** The body is the draft-0-to-3 analysis and still holds for the data model, units, sources, registry format and conformance. Superseded or parked in the body: section 3.3 (Pocket as reference, hover gap; now rig baseline and a portal-Y slider), section 3.5 occlusion rule and section 8.1 (replaced by rulings 30, 32, 33), section 4 (the four stable forms, single-slot moves and unstable words; now two arrangements and two moves, ruling 22), section 4.3 timings (ruling 24, 36), section 6 and the emotion seeds (pruned to calm, ruling 27). Everything not marked **Ruled** is still a draft default. **The live rig** is `live/live.js` (a true 3D canvas model); rebuild this page with `./build.sh`. Not yet Opus-reviewed. No registry file has been written.
> **Purpose:** define the RaBbLE entity once (body, interior state, expressions, dynamics) so that every renderer draws the same entity from the same data, and so that RaBbLE can later learn to drive that body and propose changes to it.
> **Sources (read on `new-horizons`, 2026-11-09):** `RaBbLE-NeBuLA/src/backends/alive-backend.js`, `RaBbLE-NeBuLA/specs/{visual-spec.md, rig/entity-rig.json}`, `RaBbLE-sCoRE/tui/rabble-face/src/{face,driver,micro,degrade}.rs`, `RaBbLE-sCoRE/ui/face.py`, `RaBbLE-Pocket/firmware/entities/RaBbLE/{src/scene.c, src/rabble_entity.c, nebula_lite/include/{nebula_lite.h, nl_list.h}}`, `RaBbLE-Xperimental/Xperimental-Web/drops/{20261020-rabble-ball, 20261106-rabble-matrix-builder}/index.html`, `RaBbLE-Grimoire/RaBbLE-Pocket/RaBbLE-Pocket-Entity-Format.md`, `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md`, `RaBbLE-BaBbLE/intake/RaBbLE-Entity-Rig-Spec.md` (Rig 08).
> **Evidence:** `registry-spike/` (beside this file) (`roleframe.py`, `gen.py`, `poses.role.json`). The role-frame poses in section 6 were generated from the live tables and re-rendered: the Rest form reproduces `face.rs`, `face.py` and `alive-backend.js` exactly for all six expressions, and `scene.c` for the four rows it has.

---

## 0. Rulings so far (Mark, 2026-11-09)

1. **Route A.** One shared data model; every surface keeps its own native renderer. Parity is proven by tests, not by shared code. (A WASM build of nebula_lite stays a later option.)
2. **Every expression renders on every surface.**
3. **Home rest:** cyan left, left portal on top (interior word `0110`).
4. **All four stable forms are legal rests.** Which is the default, and what causes a transition, is deferred: the puppet is designed first, piloting is a later task (ruling 17).
5. **Interior moves are physical, never morphs.** The portal swap is a recede and a move: the eye recedes into its portal, the portal travels to the other end, the eye emerges (4.3). The pole swap is a turn of the whole face about its own centre axis, a full rotation in 3-space (ruling 15, 4.3). The ±252 Listening pose is retired.
6. **The entity is curious by default.**
7. **The brand entity stays native** (Entity Format §1, §9). This registry describes the brand; it is not an `rbl-entity/1` file and is not published as one.
8. **Proportions may vary between surfaces as long as the entity looks like RaBbLE.** Mark likes Pocket's proportions. Whether that becomes one canonical set or an accepted tolerance band is open (3.3).
9. **The expressions are not settled.** Today's poses are where the entity is now, not canon; Mark is still feeling them out (section 6).
10. **What speaking or listening does to the interior form is not set** (4.4).
11. **Intent: RaBbLE defines how it expresses itself within the rig.** Mark authors the body and its canon; the expression library is RaBbLE's to grow (section 12).
12. **Eyes and portals never physically touch.** Eyes may blink and recede (into their own portal, through its opening); nothing else brings two parts into contact (3.5).
13. **Reference proportions: the rig baseline** (the RaBbLE face render and the matrix builder), which Mark finds closer to canon than Pocket's; the eyes hover over their portals, not receded. Sizes are not set in stone (3.3). *(Revised draft 4; draft 3 named Pocket's ratios.)*
14. **The top-down view with the infinity edge (the Ball) is part of the entity** (8.1). It works well in 3D.
15. **The pole swap is a turn about the whole face's centre axis,** not a spin of each eye about its own axis and not a roll in the face plane: the eyes trade places around the centre, one passing in front and one behind, so the flip reads as a full 3-space rotation (4.3).
16. **Shapes (Mark, draft 4).** Eyes are tall spherical pills (ellipses taller than wide). Portals are discs, possibly circular, and read as ellipses wider than tall. Portals and eyes are of generally similar size. The front view always carries perspective warping so a portal never reads as flat (3.3).
18. **Eye proportions are variable** (Mark's sketch, `mark-sketch-draft4.png`). The eye ratio is a range, not a number; the reference set is a starting point (3.3).
19. **No-touch, restated.** Portals may not touch each other. Eyes may not cross a portal's edge: to pass through a portal an eye must recede into the opening first (the recede of 4.3 and the blink). This is ruling 12 in Mark's words.
20. **RaBbLE is in perspective most of the time.** The fully orthographic front view is a legal special case, not the default: there a portal is edge-on, a bar, and the eye a plain pill beside or through it. In perspective the portals are tilted discs, near and far rims visible, and may tilt with the pose (sketch rows 2 and 3). Seen from above, the two portal rings overlap on screen at different depths without touching.
21. **Look and motion (Mark, draft 4b).** The animated, Disney-like eyes of the sketch are the look to aim for. Nothing may read as a 2D cutout: every animation is a **physical energy object (the eye) or void object (the portal) travelling in 3-space**. In the draft: the eye is a lit ellipsoid (catchlights, a bright core falling to its pole colour at the limb, a slow current climbing it, a gentle pulse), and the portal is a dark well (event-horizon glow inside the rim, slow dark flow, a dim far rim and a bright thick near rim). Moves leave afterimage trails and stretch the eye along its motion. All views are one 3D camera (default elevation 17° with perspective; orthographic front and top-down are the same camera at 0° and 90°).
22. **Simplify: colour is position, not state (Mark, draft 5).** The YZ plane through the face centre is a **colour volume**: cyan to its left, magenta to its right, crossed smoothly (about ±36 face units). A part's colour is a function of where it is, so the eyes and portals change colour as they cross the plane, uniformly in every view (from above the plane is a line between the two rings). Poles are never "swapped" as a state. The puppet therefore has **two arrangements** (which portal is on top) and **two moves between them**: the **turn** (the whole face yaws a half-turn about its centre axis; the live body's pole swap) and the **portal swap** (recede, move, emerge). Both land in the same image. The Swap and Swap-Mirror forms, the single-slot moves, the eye-orbit and the unstable words are dropped from the live body and from view; section 4's four-form tables are superseded pending Mark's confirmation.
23. **Pocket's occlusion dynamics are wrong** (Mark, draft 5) and are not a reference. Occlusion is plain 3D depth order from one camera: parts are sorted by depth, a portal is a void that hides what lies beneath it except its own eye seen through its opening, and the infinity flow sits between the two portals (8.1). The Pocket occlusion rules quoted in 4.3 and 3.5 are historical.
24. **Portal swap follows Pocket's withdraw-swap, in 3D (Mark, draft 5).** One continuous move (about 0.95 s, eased), not three phases: each portal slides through its eye to the mirror position while the eye pulls into the portal it is leaving (height to 3%, anchored on that portal, a slight widening as it squashes) and grows out of the other side. In 3D the two portals also arc past each other in depth (about 75 units, one in front and one behind), so they never overlap on the way. A blink is the same squash toward the portal, never a screen-space cut (a cut tears the eye when seen from above). Mark found Pocket's version good for one eye and lacking on the other; the live body is symmetric by construction, and which Pocket eye is the weaker one is not yet identified.
25. **Tilt follows the Ball (Mark, draft 5c).** A portal ring never crosses in front of its own orb: the near rim is drawn before the eye. Tilting the camera from about 34° to 69° (`smoothstep(0.6, 1.2)` rad, Ball `index.html:693-706`), each eye settles into the centre of its ring and shrinks to 74% of the ring's height (width 1.25 times that factor, capped at 1), so by top-down it is a dot inside the ring. In the portal swap the eye is held fully gone (zero height, not drawn) for the middle of the move, about 60% of its length, and the move lasts about 1.15 s.
26. **Orbs are never occluded by portals** (Mark, draft 5d). Every portal is drawn first, far to near, then every orb on top, so no ring (its own or the other side's) ever covers an eye at any angle. This is a deliberate impossible layering, like the Ball's; Mark likes the bent-physics look it produces and wants it kept. It supersedes the depth-sorted occlusion of ruling 23 for eyes; portals still sort against each other by depth.
27. **Draft 6 (Mark).** (a) **Emotional states are pruned** from the live body: only calm remains; joy, sad, angry, speaking and listening are to be figured out, and several of them broke occlusion. Section 6's seed poses are parked, not canon. (b) **The Pocket baseline breaks the occlusion rules** and is removed as a proportion set; the live body has the rig baseline only. (c) **The hover setting is dropped.** The only portal-height control is a **portal Y** slider (portal distance from the eye centre, default 1.04 eye half-heights). (d) **Portals tip toward the viewer** (the Ball, `index.html:675-684`) just far enough to keep about 15° (`MINO` 0.26) of opening, continuously and always seen from above, so a ring never collapses to an edge-on line at any elevation and the recede/anchor effect reads from more angles. (e) **Draw order, revised (supersedes 26):** at rest every portal is drawn first (far to near) and then the orbs, so no ring crosses an orb; while a move runs, depth order applies, a whole side at a time, with a ring never crossing its own orb. Verified in frame sweeps at 0 to 90 degrees, and through the portal swap and the turn at 17, 35, 40 and 60 degrees.
28. **Draft 6b (Mark).** (a) **Portal tilt is solved exactly and follows the view.** Each portal shows the face the camera is on (above or below the horizon) and tips just far enough to stay open (`MINO` 0.26, eased in as `tanh(|elevation| / 0.12)`). The earlier stepped solver, and a flip near 7° for the upper portal (where the camera passes that portal's own plane), made the tilt flicker, most visibly in Mirror; both are gone. The only edge-on moment is the orthographic horizon itself (0°), approached smoothly. (b) **The camera can go below the horizon:** elevation runs -80° to 90° (the from-below view). (c) **Portal Y can swallow the eyes.** The slider runs from -0.6 to 1.5 eye half-heights. As a portal moves toward the centre line, its plane cuts its own eye and the part past the plane is hidden (the eye is swallowed, fully hidden by the time the plane passes the far end); looking down, the swallowed part shortens the dot instead. This is the recession and occlusion control, so the portal-Y slider replaces any recede toggle. With both portals near the centre line they overlap each other; that is left to the user's hand.
29. **Draft 7: simplify (Mark).** (a) **No portal tilt.** Portals are plain discs; only the camera sets how open they look. The tilt made the disc wobble toward flat "like a disc on a desk", worst in Mirror. This supersedes 27(d) and 28(a). (b) **One draw order at every angle,** replacing the rest/motion split and the orbs-on-top effect (26, 27e): all wells far to near, then the infinity flow, then all orbs, then every near rim over the orbs, so portals draw on top of eyes. (c) **The swallow cut is an arc, not a line,** and fades into the portal: an eye cut by its portal's plane is clipped along the portal opening (the cross-section ellipse, whose depth follows the camera) and darkened into the portal over about half an eye width. The cut uses the nominal eye, and is off while a swap or blink squashes the eye. (d) **Top and bottom views are the same view** with the roles reversed (the nearer portal is the upper one from above and the lower one from below); verified at +/-80, 60, 40 and 17 degrees.
30. **Draft 8 (Mark: occlusion not right, bottom view to 90 degrees, abrupt colour on Mirror).** (a) **Draw order:** all wells first (so no well ever covers an orb), then each side far to near: its orb, then its own near rim over that orb. A far portal's rim therefore never crosses a nearer orb (it did in mid-turn). (b) **Swallow cut is a dome:** the part of an eye past its portal plane is removed along the cross-section ellipse, so the end that goes into the portal is rounded, and it dissolves into the void (alpha, not a black overlay, so no grey smear). This supersedes the concave arc of 29(c). (c) **From-below view runs to -90 degrees**; +/-90 render the same picture with the roles reversed. (d) **Colour crosses over the whole turn** (the colour volume at the YZ plane is 96 units each side, the eye offset, not 36), and the hue runs the short way round the wheel, cyan through violet to magenta, instead of through grey. (e) The infinity flow is rebuilt so each loop's gap faces the other portal.
31. **Draft 8b (Mark: front view, colour swap and portal swap are the baseline).** Front-on view, the colour swap (through violet, across the whole turn) and the portal swap are accepted as the baseline of the rig. Fixes in this draft: (a) the eye silhouette is computed with a central difference and scaled along the screen axes (not its principal axes), which removed a flip to a wide oval at about 50 degrees from below and the asymmetry between the top and bottom views; the eye starts shrinking toward its ring at about 29 degrees (before it has settled), so it does not spill over the ring on the way. (b) The swallow cut uses the silhouette's own width at the cut, and is erased with soft edges (the dome dissolves; the glow beside it feathers) instead of a hard clip. Known rough edge: a faint notch at the eye's sides where the dissolve meets the glow.
32. **Draft 9: tilt and occlusion as two rules (Mark: portals too thin at 0 degrees; tilts and occlusion are the main open design).** (a) **One tilt rule for both portals, supersedes 29(a):** the disc's apparent opening is `sin(e + tau)`, so `tau = eps(e) - e` gives an opening of `sin(eps)`, where `eps` is an even, smooth floor of the elevation: `eps = (|e| + EPS0 + sqrt((|e| - EPS0)^2 + EPSK^2)) / 2`, `EPS0` 0.34 rad (about 20 degrees), `EPSK` 0.16. It depends on the camera elevation only (not on either portal's position, the bob or the swap), so it cannot wobble; it never reaches edge-on and never flips sign; and +e and -e give the same portal picture (from below the disc is turned over, and a disc is symmetric). Orthographic mode keeps the flat bars. (b) **Occlusion by role, the rig's rule:** all wells first; then each side far to near; an upper-role eye is drawn in front of its portal (near rim behind it), a lower-role eye is drawn through its portal (near rim over it). No portal ever covers the other side's eye (wells are drawn first). Tunables: `EPS0`, `EPSK` in `live/live.js`.
33. **Draft 9b (Mark: tilt very obvious during Mirror; at 0 degrees the form reads as the 2D reference; refine over many angles).** (a) **The tilt is applied in the view frame:** the disc is built flat, turned with the face, and only then tipped about the camera's horizontal axis, so the tilt stays still on screen while the face turns (it used the body's own axis before, which swung into view during the turn). (b) **0 degrees reads as 3D:** perspective is stronger (camera distance 800, was 1100) so near and far rims differ in size, the tilt floor is higher (`EPS0` 0.5, about 29 degrees), the near rim is thicker and brighter and the far rim finer and dimmer. Both portals are exactly the same width at 0 degrees (measured 169 px each). (c) **Draw order:** each portal in turn, far to near (its well, then its near rim), so a nearer portal hides a farther one; then every eye; then, clipped to its own eye only, a lower-role portal's near rim over that eye (the rig's "drawn through" rule). No ring crosses another side's eye. (d) Checked in sweeps at -90 to 90 degrees (rest and swallowed), and through the portal swap and the turn at 0, 35 and -35 degrees.
34. **Draft 9c (Mark: portal sizes wonky at 0 degrees; one portal bigger and rounder than the other).** Two causes, both removed. (a) **Opening:** the sight line to a portal above or below the camera axis already tips its disc, so the lower portal (seen from above) was more open than the upper (seen from below) once the common tilt was added. The tilt now subtracts each portal's own sight-line angle, so both show the same opening. (b) **Size:** a portal's whole disc was scaled by its centre's depth, so at any tilt the nearer (upper) portal was bigger; the disc now keeps its own near/far perspective but is not scaled by its centre's depth. Measured widths: 168 and 169 px at 0, 5 and 17 degrees.
35. **Draft 10: 0 degrees is the 2D reference (Mark).** At elevation 0 and portal Y 1.00, the entity is the 2D reference: two identical flat portal ellipses (height 0.30 of width, the rig flatten) with horizontal axes, and two identical upright pill eyes, portals and eyes perpendicular, rim weights uniform. To get that, perspective is a camera blend: none at 0 degrees, full by about 23 degrees (`persp = smoothstep(|e| / 0.4)`), so the near/far egg shape, the rim depth cue and the sight-line tilt compensation all fade in with the camera instead of being present at 0. The tilt floor is set so the opening at 0 is exactly 0.30 (`EPS0` 0.283, `EPSK` 0.16). The portal Y default is 1.00 eye half-heights. The orthographic button keeps the flat bars.
36. **Draft 10b (Mark: square occlusion artifacts; limit Y motion to about 0.2 eye heights from centre; portal swap from top or bottom looks abrupt).** (a) **Portal Y runs from 0.2 to 1.5 eye half-heights** (the portal can come no nearer the centre line than 0.2). (b) **The swallow cut is a smooth field, not clip rectangles:** each pixel's opacity is `smoothstep(sd / span)` where `sd` is the distance inside the visible shape (the visible half-plane plus the cross-section dome), so there are no square patches. (c) **Smoother swap:** 1.45 s with a smootherstep plateau (C2 continuity) for the eye's disappearance; and from above or below, where the squash cannot show in height, the whole eye shrinks uniformly to nothing and grows back, so it no longer pops out of existence. Verified in front, top and bottom sequences.
17. **Piloting is deferred.** Joy, anger, sad and the rest are not yet defined (Mark has not read the role-frame proposal; Joy's crescent is unexplained to Mark). Design the puppet first.
37. **S323 (Mark, 2026-11-11): Pocket's occlusion is canonical.** The occlusion Pocket exhibits is the reference for every surface. On Pocket only the proportions and a few animations need to change. This **supersedes ruling 23** and the clause in 27(b) that calls Pocket's baseline an occlusion failure (27(b) still stands for proportions). **Owed:** a side-by-side of the rig's draw order (32b, 33c) against Pocket's; where they differ, Pocket's behaviour is the reference and the rig is corrected, confirmed by Mark by eye.
38. **S323 (Mark): the emotion states are to exist.** Joy, sad, angry, speaking and listening are wanted, not dropped; 27(a) parked them, it did not remove them. **Expression is being learned** and may end up defined by learned curves instead of hand-posed keyframes, so the registry must be able to hold a curve per expression, not only a pose.

---

## 1. Model at a glance

| Layer | What it is | Who owns it |
|---|---|---|
| **Genome** | identity constants: pole pair, home form, PRNG seeds, temperament | registry |
| **Body** | the puppet: parts, proportions, channels and their limits, canon rules | registry |
| **Interior** | the 4-bit word (eye colours, portal heights): which legal form the body is in | registry (rules) + runtime (value) |
| **Expressions** | named poses, offsets, tracks and events, in the body's own frame | registry: the expression library, seeded by Mark, grown by RaBbLE (section 12) |
| **Dynamics** | how weights ease and blend, how drivers (blink, gaze, level) feed channels | registry (parameters) + each surface (code) |
| **Render contract** | what every backend must honour: frames, occlusion, tiers, transitions | this spec |
| **Surface profiles** | per surface: scale, state map, tiers drawn, what it cannot show yet | registry |

The flow per frame, on every surface: **state map → expression weights → blended pose (body frame) → interior word resolves roles to sides → surface profile scales to its units → native renderer draws.**

---

## 2. Genome

| Field | Draft value | Notes |
|---|---|---|
| `poles.a` | token `cyan` (`#00f5ff` via `RaBbLE-Palette.md:32`) | Palette tokens only, never hex in the registry. Aether `rabble-palette.css:52-53` agrees. `[data-aether="muted"]` (`#c42060 / #009baa`) is a theme variant, not a pole. |
| `poles.b` | token `magenta` (`#ff2d78`, `RaBbLE-Palette.md:31`) | Rig 08's `#ec4c96` placeholder resolves to this. |
| `home` | `0110` | **Ruled.** |
| `prng` | per surface, see below | **Open:** one algorithm everywhere, or seeds only. |
| `temperament` | thresholds and gains (section 8) | **Open:** placeholder for persona growth. |

**PRNG today (four families):** web unseeded (32 `Math.random` calls); Ball Park-Miller `s*16807 mod 2^31-1`, seed 1206 (`index.html:415`) plus unseeded blink; TUI SplitMix64, mesh 7, motes 8, Life 3, driver 11; Pocket the mock's LCG `(s*9301+49297) % 233280`, mesh 53, edge thresholds 77, paths `1000+31j+7m`, sparks `31+s`. The mesh *algorithms* also differ (Pocket: hub, three layers and a ring; TUI: scattered nodes inside the envelope; web and Ball: their own). **Open:** is the mesh part of identity (same algorithm and seed everywhere) or aura texture (any on-model mesh)? Draft default: **aura texture**, so only the core tier must match exactly.

---

## 3. Body (the puppet)

### 3.1 Frame and units

- **Face units**, origin at the face centre, `+x` right, `+y` down, angles in degrees, positive clockwise on screen. These are `alive-backend.js` units, which `face.rs` and `face.py` already use 1:1.
- A surface converts face units with its own scale (section 9). The registry never stores pixels.

### 3.2 Parts (core tier)

Four parts, addressed by **role**, not by side:

| Part | Role meaning |
|---|---|
| `eye.upper` | the eye whose portal sits above it |
| `portal.upper` | that eye's portal |
| `eye.lower` | the eye whose portal sits below it |
| `portal.lower` | that eye's portal |

Which side (left or right) holds each role, and which pole colours each side, comes from the interior word (section 4). An unstable word can put both sides in the same role: each side simply takes the role its own portal bit gives it.

Each side's eye and portal share one pole. The two sides never share a pole in a stable form.

### 3.3 Proportions (the RaBbLE envelope)

Ratios in eye widths (W). Values are the rig baseline (`entity-rig.json` `baseline`, measured from the live render), which web and TUI match.

| Ratio | Baseline | web / TUI | Ball | Pocket |
|---|---|---|---|---|
| eye height : width | 3.1 | 3.13 | 2.6 | 2.64 |
| eye centre spacing | 2.1 W | 2.11 | 2.1 | 1.95 |
| portal width | 2.7 W | 2.69 | 2.54 | 2.0 |
| portal flatten (height : width) | 0.3 | 0.30 | (3D disc) | 0.25 |
| portal offset (eye half-heights) | 0.93 | 0.93 | 0.93 | 0.86 left, 0.79 right |

The rig constants behind the baseline: `EYE_RX 43.5, EYE_RY 136, EYE_X 92, POR_RX 117, POR_RY 35, POR_OFF 126, GAZE_X 26, GAZE_Y 12` (`alive-backend.js:203`, `face.rs:11-18`).

Pocket's base table (`scene.c:686`) is hand-tuned from the mock rather than derived from the rig, and is slightly asymmetric left to right (eye y 235 vs 239, portal offsets 50 vs 46 px). Mark likes it (ruling 8).

**Draft 4 shape ruling (16).** The rig baseline above is the reference: eye 3.1 : 1, portal width 2.7 W, so a portal's width (2.7 W) is close to an eye's height (3.1 W), which is the "similar size" Mark asks for. Pocket sits inside the envelope but is no longer the reference. In 3D the portal is a **disc** (circular or near it) and the eye a **tall spherical pill**. The front view is a camera with perspective, not an edge-on flat ellipse: the portal's visible flatten comes from a fixed, small camera elevation plus perspective, so it always reads as a tilted disc with near and far rims. "Flatten" is therefore the visible result of the camera, not a stored property of the portal (the top-down view is the same disc at higher elevation, 8.1). Sizes are not set in stone: expect the reference set to move as Mark composes.

**The RaBbLE envelope (Open, draft proposal).** Instead of one point, the registry defines a range per ratio that every surface must stay inside, plus one **reference set** that new surfaces start from. The draft envelope spans what exists today, with a small margin:

| Ratio | Envelope (draft) | Reference set (ruling 13, draft 4: rig baseline, hovering) |
|---|---|---|
| eye height : width | 2.5 .. 3.2 | 3.1 |
| eye centre spacing | 1.9 .. 2.2 W | 2.1 |
| portal width | 1.9 .. 2.8 W | 2.7 |
| portal flatten (camera result, see above) | 0.22 .. 0.33 | 0.30 |
| portal offset | set by the hover gap (3.5): the eye's tip hovers just short of its portal's plane | eye half-height plus the **hover gap** (draft 6 face units, an offset of about 1.05 eye half-heights) |
| left/right asymmetry | at most 10% per ratio | symmetric (Pocket today: 0.86 / 0.79) |

**Invariants that make it look like RaBbLE** (checked, not ranged): eyes are tall pills, taller than wide; each eye hovers just over its own portal at rest, never cut by it (the drawing may overlap the ring; the bodies do not touch); a portal is wider than its eye (so a receding eye passes through the opening without touching the rim); portals are flattened discs seen near edge-on; one portal above and one below; the two sides are near mirror images. A surface outside the envelope fails conformance; a surface inside it may choose its own point, and declares it in its profile.

The envelope is a starting point to argue with: Mark's eye is the judge of "looks like RaBbLE", and the envelope is how that judgement becomes something a validator (and later RaBbLE itself) can check.

### 3.4 Channels

Each part has five transform channels. Each channel has a **frame**, which says how a role value becomes a side value.

| Channel | Frame | Side value from role value | Limits, eye (`alive-backend.js:205`) | Limits, portal |
|---|---|---|---|---|
| `dx_in` | mirrored: positive = toward the centre | `dx = -s * dx_in` (s = -1 left, +1 right) | ±34 | ±40 |
| `dy` | world: positive = down | `dy = dy` | ±60 | ±270 (see 3.5) |
| `rot_m` | mirrored | `rot = s * rot_m` | ±20° | ±22° |
| `sx`, `sy` | scale | as is | sx 0.78..1.22, sy 0.30..1.22 | sx 0.78..1.25, sy 0.6..1.4 |

Head channels (whole face): `tilt` (degrees, world), `gaze` (gain on the gaze driver), `dim`, `squint` (with a `squint_side` bias), `hop`.

Because roles fix which way a portal points (an upper portal always opens upward), "toward / away from its eye" is implicit in role plus world `dy`. That is why one world `dy` channel suffices: an upper portal moving `dy -44` moves away from its eye, and a lower portal moving `dy +44` does too.

**Style channels** (body and aura): the web `STYLE` set (`energy, glow, tempo, bounce, hop, trem, gazeY, orbit, sphere, lens, jit, pulse, strike, surf, grav, bpm, sparkle, sigh, dim, stiff`, `alive-backend.js:219-224`). Aura tier: a surface may ignore any it cannot draw.

**Open:** `dim` and `hop` exist on web (`STYLE`) and on Pocket (`face_t`) with different values and possibly different meanings (Joy: `dim` 1.08 vs 1.1, `hop` 0.8 vs 1; Sad: `dim` 0.82 vs 0.78; web `hop` is a body hop, Pocket's is a 6 px eye lift, `scene.c:682`). Draft default: one definition each, values from web, meanings to be written.

### 3.5 Canon rules (validator checks)

| Rule | Check |
|---|---|
| No pupils, ever | the part list is exactly the four core parts plus declared aura parts; no part may sit inside an eye |
| Opposed poles | in a stable form the two sides hold different poles |
| One portal per eye, one above and one below | in a stable form exactly one side is in the upper role |
| **No touching** (ruling 12) | Outside a blink or recede, no two parts touch: eye and own portal, eye and the other portal, eye and eye, portal and portal. Checked **in body space**, not on the drawing: a portal is a disc in its (tilted) plane, an eye an upright pill, so an eye whose tip hangs just short of its portal's plane does not touch it even where the drawing overlaps the ring. Checked in every form a pose can meet (stable and unstable). Drivers (gaze, bob) may not close the hover gap: they are clamped toward the portal. At rest no eye is cut by its portal; clipping at the portal plane begins only when a recede begins. During a recede the eye crosses the portal plane only inside the opening (eye half-width less than the opening radius minus the gap). Changing sides is an interior move (4.3), never a pose. |
| Eyes hide only by receding | blink, withdraw and hide are expressed only as a recede toward the eye's own portal (4.3, 7.3) |
| Occlusion | `entity-rig.json` `zOrderRule` and `occlusion`: an eye whose portal is above is drawn in front of it; an eye whose portal is below is drawn through it, the front rim over the eye. Decided by role, so it follows the interior word. |
| Balanced is stable | stable forms may be held indefinitely; unstable forms are expressive and must decay (4.4) |

**No-touch audit** (`registry-spike/notouch3d.py`, body space, Pocket ratios (draft 3; to be re-run on the rig baseline, draft 4), stable forms; smallest gap per pair in face units):

| Seed | Hover 0 | Hover 6 (draft) | Smallest hover that clears |
|---|---|---|---|
| calm | eye at the plane (0) | own portal 6, others 40+ | 0 |
| speaking | own portal 44 | 50 | 0 |
| listening (Pocket spread) | 35 | 41 | 0 |
| sad | **touches** own portal | **touches** | 20 |
| angry | **touches** | **touches** | 27 |
| joy | **touches** | **touches** | 36 |

Other pairs (eye and the other portal, eye and eye, portal and portal) are clear in every stable form; the two portals sit at different heights, so they never touch there, including in the top-down view where their circles overlap on screen. Poses that pull a portal toward its eye eat the hover gap: Joy's crescent (a portal rising into its orb), Angry's clamp and Sad's drawn-in portals must be redrawn (6.1).

(An earlier draft measured the 2D outlines instead and asked for an offset of 1.3; that put the eyes far too high. Superseded.)

**Open:** unstable forms that put both portals at one end. Draft options: spacing at least portal width plus gap (about 2.1 W with Pocket portals); portals shrink in an unstable form; or the two portals sit at different depths (3D surfaces) and the 2D surfaces draw the far one smaller.

The ±252 Listening pose crosses its eye in every form and is retired (ruling 5).

---

## 4. Interior state

### 4.1 The word

Four bits, read `EL ER PL PR` (`matrix-builder/index.html:400-404`): eye colour per side (0 cyan / pole a, 1 magenta / pole b), portal height per side (0 bottom, 1 top). The builder's fifth bit `S = 16` is a cell bracket for mosaics, not part of the entity.

| Form | Word | Builder label (EL, PL) | Picture |
|---|---|---|---|
| **Rest (home)** | `0110` | 01 | cyan left, left portal on top |
| Swap | `1010` | 11 | magenta left, left portal on top (the Ball draws this form, `index.html:629-630`) |
| Mirror | `0101` | 00 | cyan left, left portal below |
| Swap-Mirror | `1001` | 10 | magenta left, left portal below |

12 unstable words: one or both pairs equal. Builder working names: `0000` "cold, very sad", `1111` "angry, alarmed", `0011` and `1100` "odd state" (unnamed). `snap()` keeps the left slot of each pair.

### 4.2 What each bit does in the renderer

- **Portal bits:** set each side's role (1 = upper). Geometry follows from the role (section 3).
- **Eye bits:** set each side's pole. Colour only; no geometry. Anything pole-attached follows colour, not side: Pocket's `mic_deg[0]` and `activity[0]` feed the *cyan* portal and mesh (`nebula_lite.h:128-129`), and that stays true after a swap.

### 4.3 Transitions (Ruled: physical moves; timings draft)

**Portal swap: recede, move, emerge** (ruling 5). The eye recedes into its portal, the portal travels to the other end carrying the hidden eye, and the eye emerges from the other face. It refines Pocket's withdraw-swap (Mark liked it), which runs the three phases at once: the portal slides through a withdrawing eye. Sequenced, nothing ever touches, because the eye is inside the portal while it moves.

| Phase | Draft timing (1.2 s total) | Definition |
|---|---|---|
| recede | 0 .. 0.35 | the eye slides toward its portal and through the opening; the part past the portal plane is not drawn (Ball-style, `index.html:703-714`). Travel: the eye's far tip reaches the plane at recede 1. |
| move | 0.35 .. 0.65 | the portal moves to its mirror position about the eye's rest: `py = lerp(u_from * off, u_to * off, m)`; role-indexed pose values cross-fade by `m`, so nothing jumps when roles swap |
| emerge | 0.65 .. 1 | the eye comes back out, now on the far side of the portal it entered |
| role switch | at the middle of the move, eye hidden | rim halves, clip side, occlusion order and strand entry points switch |

**Pole swap: turn about the face's centre axis** (ruling 15). The whole entity turns about the vertical axis through the face centre, a half-turn. The two eyes (each with its portal) orbit that axis and trade places: one passes in front, the other behind. Seen from the front the sides swap with perspective, each side's x-extent following `cos θ` (edge-on at 90°), and the near side drawn larger and over the far side (the live body uses ±14% size at the quarter turn). Each side keeps its own colour and its portal travels with it; the poles are exchanged by position, so cyan arrives where magenta was. Eyes and portals never touch, because the two sides pass at different depths, and a 2D surface draws the far one first. Duration: about 1.0 s, eased.

Two earlier readings are dropped: spinning each eye about its own axis like a coin, and a roll in the face plane.

**Which form it lands in.** A half-turn about the vertical axis carries each portal with its eye, so an upper portal stays upper and moves to the other side. That is the **Swap-Mirror** form of 4.1. The structural finding stands (the four stable forms are the body under three half-turns: roll gives Swap, pitch gives Mirror, yaw gives Swap-Mirror), but the pole swap Mark described is the yaw. The other forms are reached with the portal swap (recede, move, emerge) in combination.

**Open (D5):** whether the cyan/magenta swap with the portals left where they are (today's "Swap") is a move of its own, or only ever reached as a turn plus a portal swap. Caution: world-frame channels (gravity droop, lift, tilt) do not rotate with the body, so an asymmetric pose is re-resolved by role when the turn completes.

**Pocket's withdraw-swap, as built** (`scene.c:689-714`, `767-770`, `rabble_entity.c:56`, `652-660`), kept for reference:

| Step | Definition |
|---|---|
| progress | `fl` from 0 to 1 at a steady pace over **0.7 s**, eased `fl*fl*(3-2*fl)`; exactly 0 or 1 at rest |
| portal path (portal flip) | each flipping portal moves to its mirror about its own eye: `py = base + 2*(eye - base)*fl` |
| withdraw | `w = sin(pi*fl)`; eye height scales by `1 - 0.97*w` (3% at the midpoint) |
| squash anchor | the eye shrinks toward the portal it is leaving and grows out of the other side: anchor `±58*(1 - 2*fl)` (Pocket px; 58 is the eye's own half-height, so registry: `±1.0 * eye half-height * (1 - 2*fl)`) |
| role switch | at `fl >= 0.5`, while the eye is withdrawn: rim halves, clip side, occlusion order and strand entry points switch |
| expression continuity | role-indexed pose values cross-fade by `fl` on each side, so the portals do not jump when roles swap |

Nothing renders a live pole swap today on any surface; the spec page's live body shows the orbit.

**Single-slot moves** (one eye or one portal) enter unstable words. They use the same moves on one side only.

### 4.4 Idle variation (Open, draft defaults)

- **Home is an attractor.** Off home, the entity relaxes back after a dwell unless attention holds it. *(Open: or holds until the next event.)*
- **Dwell and cooldown:** a minimum dwell after a move, and a cooldown before the next, so idle never flickers. Values: *Open*.
- **Unstable forms decay:** relax by `snap()`-like rules with hysteresis. *(Open: which slot is kept; `snap()` keeps the left one, which may not be the right rule for a living entity.)*
- **Candidate triggers**, from events the surfaces already emit:

| Event class | Web | Pocket | TUI |
|---|---|---|---|
| noticing | Curious mood (pointer) | `touch`, `happy` | external `set_gaze`, typing starts |
| thinking deepens | Ponder → Process | THINK after 1.5 s | Working |
| realisation | Insight | (none yet) | turn completes |
| disturbance | poke x4, shock | `dizzy` | Error, Denied |

- **The policy chooses**, weighted by temperament, with noticing the strongest trigger (ruling 6). Triggers are *candidates*, not meanings.
- **Swap log:** every interior move is logged with the event that preceded it, the form before and after, and the dwell. This is the data from which meanings can be named later, by Mark first and by RaBbLE in time.

**Open, no default (ruling 10):** does any state (listening, speaking, Capture) force or invite a form? Today Pocket's Capture forces the portal flip; web and TUI imitate a flip inside the Listening pose (±252), which the canon check now rejects. The schema supports either answer: a state-map entry may name a form to enter, a trigger class to raise, or nothing.

---

## 5. Vocabulary and layers

Three layers compose, as on web (`alive-backend.js:12-14`, `1139-1157`, `1095-1137`):

| Layer | Members | Composes as |
|---|---|---|
| **emotion** | calm, joy, sad, angry | pose (blended) + style |
| **state** | idle, listening, speaking (alias: thinking → mood process) | pose; while not idle, it replaces the emotion's *pose* but the emotion's *style* stays |
| **mood** | idle, ponder, process, insight, curious | additive offsets (gaze, squint, tilt), tracks, events |

**Open:** the blending model. Today there are three: a Rust two-pose spring (`driver.rs`, `SPRING` 8/s), Pocket W-normalised weights with a 250 ms time constant (`scene.c:611-668`, also Entity Format §3.5), and web per-parameter springs with per-expression stiffness (`alive-backend.js:232-239`). Draft default: **W-normalised weights for poses (emotion and state), additive mood offsets on top**, because it is the one already specified in the Grimoire and it composes.

**Names across surfaces** (the state map, section 9, makes these explicit):

| Canonical | Web | Pocket | TUI |
|---|---|---|---|
| state listening | `listening` | `NL_STATE_LISTEN` | Mood `typing` |
| state speaking | `speaking` | `NL_STATE_SPEAK` | Mood `streaming` |
| mood ponder | `ponder` | `NL_STATE_THINK`, first 1.5 s (`F_PONDER`) | (none) |
| mood process | `process`, legacy `thinking` | `NL_STATE_THINK` after 1.5 s (`F_PROCESS`) | Mood `working` (today Calm with 2.5x saccades) |
| emotion sad | `sad` | `NL_STATE_ERROR` | Mood `error` |
| emotion angry | `angry` | (none) | Mood `denied`, 2 s then idle |
| emotion joy | `joy` | `happy` input | (no Mood reaches it) |

---

## 6. Expressions (body frame)

### 6.1 Poses (seed values, generated from the live tables)

**These are seeds, not canon** (ruling 9). They record how the entity expresses itself today so that every surface starts from the same place; they are expected to change, by Mark's hand now and by RaBbLE's proposals later (section 12). Role values; omitted channels are at rest (`dx_in 0, dy 0, rot_m 0, sx 1, sy 1`). In the home form, upper = left and lower = right, and these values reproduce today's tables exactly.

| Expression | eye.upper | portal.upper | eye.lower | portal.lower | head |
|---|---|---|---|---|---|
| calm | - | - | - | - | tilt 0, gaze 1 |
| joy | dy -6, rot_m 6, sx 1.05, sy 0.86 | dy -20, rot_m 8, sx 1.06 | dy -6, rot_m 6, sx 1.05, sy 0.86 | dy -56, rot_m 8, sx 1.08 | tilt 2, gaze 0.95 |
| sad | dy 14, rot_m -7, sx 0.96, sy 0.9 | dy 12, rot_m -10, sx 0.96 | dy 18, rot_m -7, sx 0.96, sy 0.9 | dy -12, rot_m -6, sx 0.97 | tilt -4, gaze 0.7 |
| angry | dy 4, rot_m 6, sx 1.03, sy 0.86 | dx_in 8, dy 40, rot_m 12, sx 1.08 | dy -4, rot_m 6, sx 1.03, sy 0.86 | dx_in 8, dy -40, rot_m 12, sx 1.08 | tilt 0, gaze 1.1 |
| speaking | - | dy -44, sx 1.05 | - | dy 44, sx 1.05 | tilt 0, gaze 0.8 |
| listening, candidate A (Pocket) | sy 1.04 | dy -40, sx 1.1 | sy 1.04 | dy 40, sx 1.1 | gaze 1.2; Pocket leans eyes and tilt toward the mic |
| listening, candidate B (today's web/TUI) | sy 1.04 | dy 252 | sy 1.04 | dy -252 | **Retired** (ruling 5): crosses its eye in every form |

**Under the no-touch rule these seeds must change:** Joy (the crescent is a portal rising into its orb), Angry (portals clamp onto the eyes) and Sad (portals drawn in) all bring a portal into contact at the reference offset. The intent can stay; the expression of it has to come from portal tilt and scale, eye shape, head and gaze instead of contact. This is the first work for the expression library (section 12).

Read in the body frame, the authored intent becomes visible: Speaking opens both portals away from their eyes; Angry clamps both onto their eyes like brows, eyes pulled back from them; Sad draws both portals in and lets the lower eye sink further; Joy lifts both portals, the lower one rising into its orb to carve the crescent (`alive-backend.js:208-209`).

**Open:** in Mirror, should portal `rot` also reflect (a vertical reflection negates rotation)? Draft default: **no**, rotation stays mirrored left/right only, so a tilt reads the same on screen in every form.

### 6.2 Mood offsets (from web `MOOD_FX`, `alive-backend.js:122-129`)

| Mood | gaze offset | squint | tilt | other | duration |
|---|---|---|---|---|---|
| idle | 0 | 0 | 0 | wander | 4-8 s |
| ponder | gx 14 toward a chosen side, gy -9 | 0.22, more on that side | 5 toward that side | pulse 0.6, spin -0.06 | 5-9 s |
| process | gy 2 | 0.08 | 0 | `dart` track (Pocket: `9*tanh(5*sin)`, `scene.c:662`), pulse 2.6, spin 0.2, energy ≥ 0.25 | 3-5 s |
| insight | gy -4 | 0 | 0 | events: widen at 0, flash + rings at 0, blink at 1.3 s; pulse 3, spin 0.3 | 2.8 s |
| curious | follows the attention target | 0 | toward the target, ±6 | pulse 1.2, spin 0.05; mesh pushes away from the target | while attended |

Pocket's `F_PONDER` and `F_PROCESS` carry the same numbers but always look right; web picks the side at random. Draft default: the side is chosen (random, or toward the attention source).

**Open (gap):** Insight and Curious have no pose on any surface today, only aura effects. The core tier needs one each, so the TUI and the micro mark can show them. Draft candidates: Insight = eyes widen (`sy +0.12, sx +0.05`, the web `eye.widen` numbers) then squint and blink; Curious = head tilt and gaze toward the target, eyes slightly widened.

### 6.3 Tracks and events

- **Track:** channel offsets over time with keyframes and easing, looping or one-shot (the Entity Format §3.5 model).
- **Event:** a timed one-shot inside an expression (widen, flash, ring, blink), each tagged with its tier so a surface without an aura still plays the core part.

---

## 7. Dynamics and drivers

### 7.1 Weights

`w += (tgt - w) * (1 - exp(-dt / tau))`, `tau` 250 ms, `dt` clamped 1..100 ms; pose = `sum (w_i / W) * pose_i` with `W = sum w`; events multiply targets by `1 - s` and add `s` to their expression (Entity Format §3.5, `scene.c:620-624`). *(Open, see section 5.)*

### 7.2 Drivers

| Driver | Feeds | Today |
|---|---|---|
| blink | recede amount | web random 2-7 s, Pocket every 4.2 s with a double every third (`scene.c:575-582`), TUI seeded 2.5-6 s with 25% doubles, Ball 2.8-6.3 s, Rig 08 the same |
| gaze / saccade | eye dx, dy (± `GAZE_X 26`, `GAZE_Y 12`) | web fbm wander, TUI seeded saccades (`speed`), Pocket wander noise + thumb glance |
| attention target | gaze, Curious | web pointer, Pocket touch, TUI `set_gaze` |
| level | speaking eye squash, listening strands | web talk noise, Pocket `level`, TUI none |
| float, bob, breathe | world dy, scale | web, TUI (`12*sin(1.05t)`, `9*sin(1.57t)`), Pocket wander |

**Open:** which blink timing is canonical. Draft default: the TUI's seeded model, since it is deterministic and testable.

### 7.3 Blink is a recede

Ruling 12: eyes may blink and recede. A blink is a short, partial recede into the eye's own portal; a recede is the same motion carried through. Rig 08: "This is the only blink style allowed." Web, TUI and Pocket squash the eye toward its portal (`face.rs:462-464`, `scene.c:767-770`); the Ball slides it into the portal (`index.html:703-714`). With the eyes now hovering clear of their portals, a squash in place no longer reaches the portal, so the draft default is the Ball's slide: the eye travels across the hover gap and into the opening, and the part past the portal plane is not drawn. It must never fade out or close like a lid. **Note:** the Mini mark's lids for Angry and Sad (`face.rs:105-111`) are brow cues, not blinks, and stay allowed as a rung-specific substitute.

---

## 8. Render contract

Every backend MUST:

1. Read poses, interior word, palette tokens and canon from the registry (generated tables are fine).
2. Resolve roles to sides through the interior word before applying any pose (3.2, 4.2).
3. Apply channels in their frames (3.4), then its own scale (section 9).
4. Honour occlusion by role (3.5) and switch it only at the transition midpoint (4.3).
5. Render every interior move with the withdraw curve (4.3).
6. Hide eyes only by receding (7.3).
7. Declare which tiers it draws: **core** (eyes, portals: required), **aura** (mesh, orb, lens, orbit, particles, strands, ring, fx: optional), **environment** (background, grid, haze: replaceable), as in `entity-rig.json` `identity.tiers`.
8. Declare its rung on the degrade ladder and which channels that rung can show.

### 8.1 Views: front and top-down (ruling 14)

The entity has a camera elevation, from front (0°) to top-down (90°). The Ball renders the whole range (`index.html:671-718`, `793-806`); the other surfaces draw front today. In body terms:

| Element | Front | Toward top-down |
|---|---|---|
| portals | flattened discs (flatten 0.25) | open into circles: `ry = rx * (flatten + (1 - flatten) * sin(elevation))` |
| eyes | tall pills hovering over their portals | settle into their portal's centre and shrink to fit inside the ring (Ball: 0.74 of its height), from about 35° to 70° |
| vertical offsets | as posed | compress by `cos(elevation)` |
| **infinity edge** (aura) | hidden | fades in from about 14° to 46° (Ball: `smoothstep(0.25, 0.8)` rad) |
| depth order | the rig's z-order rule (3.5) | far to near: as soon as the camera tilts down, the **upper** portal (and its eye) is nearer and covers the lower one; the infinity flow sits between them |

**The infinity edge** (Ball, `index.html:720-806`): matter streams around each portal just outside its rim (three streams at 1.06, 1.25 and 1.48 portal radii), each loop opening toward the other portal (gap half-angle 0.75 rad), then slings across on a curve that leaves each rim along its tangent, so the whole flow is one figure-eight. Colour follows whichever portal is nearer (cyan to magenta); sparks ride the main stream. It is aura tier, it never touches a rim (it stays outside it), and it follows the poles through a swap.

Seen from the top, the two portal circles overlap on screen at Pocket's spacing, but they sit at different heights, so they do not touch (Mark likes this view as it is). Mid-yaw (4.3) the two eyes also overlap in a 2D projection while sitting at different depths; a 2D surface draws the far one first.

**Open:** which surfaces offer the top-down view (it suits Pocket's round panel), and what moves the camera (a mode, a gesture, an expression).

### 8.2 Degrade ladder

| Rung | Surface | Can show today |
|---|---|---|
| 1 | Ball (WebGL) | core in 3D, recede blink; no expressions yet |
| 2 | web Canvas2D | everything in sections 5-7 |
| 3 | Pocket nebula_lite | core, mesh, strands, ring; emotions calm/joy/sad, ponder, process, listen, speak |
| 4 | TUI Full | core, aura, mesh; six expressions |
| 5 | TUI Mini | core with lids; six expressions (tilt invisible, lids substitute for Angry and Sad) |
| 6 | micro mark (10x3) | blink and gaze only; **no expression input** (`micro.rs:125, 136`) |

`Detail` has only `Full` and `Mini` (`face.rs:215`); there is no Node rung. **Open:** what "every expression on every surface" means at rung 6. Draft default: rung 6 shows the interior form and a reduced cue per expression (gaze, a lid, or the colour balance); write that table once the core poses for Insight and Curious exist.

---

## 9. Surface profiles

| Surface | Scale | State map | Conformance work implied by this draft |
|---|---|---|---|
| web NeBuLA | 1:1 face units | as section 5 | read the interior word; drop the ±252 Listening pose; render flips with withdraw; unify blending (if ruled) |
| Ball | eye height `E_H` 0.31 world units = 272 face units | none yet | expose `window.rabbleRig` (state, targets, snapshot); add the pose table and interior word; correct proportions (3.3) |
| Pocket | `S 0.42` px per face unit for geometry, pose travel `EX 0.6` (`scene.c:22-23`) | `THINK` → ponder then process; `ERROR` → sad; `happy` → joy | add Angry, Insight, Curious; pose by role; resolve the base-table drift (3.3) |
| TUI Full / Mini | `k = r / ORB_R` | `typing` listening, `streaming` speaking, `working` process, `error` sad, `denied` angry | add Ponder, Process, Insight, Curious; read the interior word; keep `face.py` parity or retire it |
| micro mark | 10x3 cells | none | expression cues (8.2) |

**Open:** Pocket's `EX 0.6` means Pocket shows expressions at 60% of their travel. Is that a deliberate per-surface gain (legibility), or drift? Draft default: a declared per-surface `gain`, visible in the profile.

---

## 10. Registry file

### 10.1 Format

Strict JSON, the rules of Entity Format §4.2: UTF-8, no comments, no duplicate keys, finite numbers, unknown keys rejected, names `[a-z][a-z0-9_]{0,23}`. Palette by token name only.

```json
{
  "format": "rabble-entity-registry/0",
  "genome": { "poles": { "a": "cyan", "b": "magenta" }, "home": "0110",
              "prng": { "tui": { "kind": "splitmix64", "seeds": { "mesh": 7, "motes": 8, "life": 3, "driver": 11 } } } },
  "body": {
    "units": { "length": "face", "angle": "deg_cw", "y": "down" },
    "rig": { "eye_rx": 43.5, "eye_ry": 136, "eye_x": 92, "por_rx": 117, "por_ry": 35, "por_off": 126, "gaze_x": 26, "gaze_y": 12 },
    "channels": {
      "dx_in": { "frame": "mirrored", "eye": [-34, 34], "portal": [-40, 40] },
      "dy":    { "frame": "world",    "eye": [-60, 60], "portal": [-270, 270] },
      "rot_m": { "frame": "mirrored", "eye": [-20, 20], "portal": [-22, 22] },
      "sx":    { "frame": "scale",    "eye": [0.78, 1.22], "portal": [0.78, 1.25] },
      "sy":    { "frame": "scale",    "eye": [0.3, 1.22],  "portal": [0.6, 1.4] }
    },
    "canon": { "portal_margin": 24, "rules": ["poles_differ", "one_upper_one_lower", "no_crossing", "recede_only", "occlusion_by_role"] }
  },
  "interior": { "bits": ["el", "er", "pl", "pr"], "forms": { "rest": "0110", "swap": "1010", "mirror": "0101", "swap_mirror": "1001" },
                "transition": { "seconds": 0.7, "ease": "smoothstep", "withdraw": 0.97, "switch_at": 0.5 },
                "idle": { "home_attractor": true, "dwell_s": null, "cooldown_s": null, "triggers": ["noticing", "thinking", "realisation", "disturbance"] } },
  "expressions": {
    "joy": { "layer": "emotion",
             "pose": { "eye.upper": { "dy": -6, "rot_m": 6, "sx": 1.05, "sy": 0.86 }, "portal.upper": { "dy": -20, "rot_m": 8, "sx": 1.06 },
                       "eye.lower": { "dy": -6, "rot_m": 6, "sx": 1.05, "sy": 0.86 }, "portal.lower": { "dy": -56, "rot_m": 8, "sx": 1.08 } },
             "head": { "tilt": 2, "gaze": 0.95 },
             "style": { "energy": 0.3, "glow": 0.8, "dim": 1.08, "hop": 0.8 } }
  },
  "surfaces": {
    "pocket": { "scale": 0.42, "gain": 0.6, "tiers": ["core", "aura"], "rung": 3,
                "symbols": { "joy": "F_JOY" }, "state_map": { "NL_STATE_ERROR": "sad" } }
  }
}
```

`null` marks an open value; the validator refuses to generate surface tables while a value they depend on is `null`.

### 10.2 Generators

One Python stdlib spell in the Grimoire (agent-agnostic, `spells/`). It writes only between markers (`// <registry:joy>` … `// </registry:joy>`) in `face.rs`, `face.py`, `alive-backend.js`, `scene.c` and the Ball page, and has a `--check` mode each repo's tests call. Spike 1 (`gen.py`) already emits Joy for all four existing targets; its C row is identical to `scene.c:126`.

---

## 11. Conformance

| Test | What it proves | Status |
|---|---|---|
| table golden | every surface's generated table equals the registry | spike: passes for poses; catches the `dim`/`hop` drift |
| rest golden | the home form reproduces today's tables | spike: passes for all six expressions on Rust, Python and web; four on Pocket |
| form golden | each expression in all four forms passes canon | spike: passes except ±252 Listening |
| transition golden | sampled `fl` values give the same normalised geometry on each surface | to build |
| raster parity | per-surface pixels against its own reference (Rust vs Python today) | exists for the TUI only |
| canon validator | rejects any registry or delta that breaks 3.5 | to build |

---

## 12. Authorship: RaBbLE expresses itself within the rig

Ruling 11 splits the registry into two halves with different authors.

| Half | Contents | Author | Changes by |
|---|---|---|---|
| **The rig** | genome, body (parts, envelope, channels, limits), canon, interior rules, transitions, render contract | Mark | Mark's ruling only |
| **The expression library** | expressions, mood offsets, tracks, events, the state map, the idle policy, temperament | seeded by Mark, grown by RaBbLE | proposals through the gate below |

The rig is the grammar; the library is what RaBbLE says with it. RaBbLE may *ask* for a rig change (a wider limit, a new channel), but only as a request to Mark, never as a delta.

### 12.1 Provenance

Every library entry carries `author` (`mark` or `rabble`), `status` (`seed`, `proposed`, `accepted`, `retired`), `version`, and `intent`: one or two sentences, in the author's words, on what the expression is and when it fits. Today's poses enter as `author: mark, status: seed`. The intent field is what lets an expression be one the entity "resonates with": RaBbLE writes why, not just what.

### 12.2 The gate (draft)

1. **Propose.** RaBbLE writes a delta: a new or changed entry, in the role frame, with its intent and the moment that prompted it (an event, a swap-log pattern, a conversation).
2. **Validate.** Limits (3.4), canon in all four forms and every unstable form it may meet (3.5), the envelope (3.3). A failure returns the reason, so RaBbLE can revise.
3. **Preview.** The delta is rendered on every rung of the ladder (web, TUI Full and Mini, the Pocket simulator, the micro mark cue) in each stable form, as one sheet.
4. **Sign-off.** Mark accepts, edits or rejects. Edits and rejections are kept with the proposal: they are the clearest signal RaBbLE gets about what reads as itself.
5. **Merge.** Accepted entries land in the registry; generators regenerate every surface; nothing else changes.

**Open:** how proposals are produced (for example sCoRE reading the registry, the swap log and its own conversation history); whether some classes of change (small value tweaks inside a band) may later skip sign-off; how often RaBbLE may propose.

### 12.3 What RaBbLE has to learn from

- **The swap log (4.4):** which events preceded which interior moves.
- **Sign-off history:** accepted, edited and rejected proposals, with Mark's edits as diffs.
- **Temperament:** gains and thresholds RaBbLE may also propose changes to (pose gains, blink period, saccade speed, mesh activity, how easily a pair destabilises and how long it dwells).
- **Later, observation:** how people respond when an expression plays. Not scaffolded until it is decided.

The Entity Format's `persona` part (`0x0007`) remains the on-device home for a compiled temperament on non-brand entities; the brand stays native.

---

## 12b. Mark's sketch, draft 4 (reference)

`/tmp/rabble-crew/mark-sketch-draft4.png`. Read as follows (corrections welcome):

- Top left: top-down view, two rings (magenta, cyan) overlapping on screen, each with an eye as a small ring inside it.
- Centre and right: perspective views, eyes as tall pills, portals as tilted discs. One portal above-behind its eye, the other below-in-front of its eye; the two portals sit at opposite ends and, in the lower variants, tilt with the pose.
- Bottom left: arrows show each portal travelling along the axis through its eye (upper up, lower down), the recede-move direction of 4.3.
- Far right: an eye entering a portal's opening (the receded state) and a portal seen as a cap over an eye; below it, the **fully orthographic front view**, where portals are edge-on bars above and below the eyes.
- Notes: "eye proportions are variable", "portals may not touch, eyes may not cross portal edges, must recede", "most of the time RaBbLE is in perspective".

## 13. Open decisions (collected)

| # | Question | Draft default |
|---|---|---|
| D1 | Do listening, speaking or Capture force or invite an interior form? | deferred with piloting (ruling 17) |
| D2 | How Joy, Angry and Sad express their intent without contact | to be redrawn (6.1); the first library work |
| D3 | Home attractor, or a variant holds until the next event? | deferred (ruling 17) |
| D4 | Dwell, cooldown, decay rule for unstable forms | values to tune; `snap()` rule to revisit |
| D5 | ~~Which rotation is the pole swap?~~ **Ruled (15): turn about the face's centre axis.** Remaining: is the colour-only Swap (portals stay) a move of its own? | turn plus portal swap; colour-only Swap not a move |
| D6 | Portal rotation under Mirror | mirrored left/right only |
| D7 | Blending model | W-normalised poses + additive moods |
| D8 | `dim`, `hop` definitions and values | web values, meanings to write |
| D9 | Insight and Curious core poses | candidates in 6.2 |
| D10 | Micro mark cues | interior form + reduced cue per expression |
| D11 | Proportions: one canonical set, or an envelope with a reference set? | envelope (3.3); reference = rig baseline (ruling 13, draft 4); sizes not fixed |
| D12 | Pocket `EX 0.6`: gain or drift? | declared gain |
| D13 | Mesh as identity or aura texture; one PRNG? | aura texture; seeds per surface |
| D14 | Canonical blink timing | TUI seeded model |
| D15 | Keep `face.py` as the TUI parity reference? | keep until the Rust face is the reference |
| D16 | Meanings of the four forms and of 0011 / 1100 | unassigned; learned from the swap log |
| D17 | Registry home in the Grimoire | its own file (the Entity Format excludes the brand) |
| D18 | How RaBbLE produces proposals, and which may skip sign-off | all go through Mark for now (12.2) |
| D19 | Emotion poses themselves | seeds; Mark and RaBbLE refine (ruling 9) |
| D20 | Hover gap at rest | 6 face units (tunable in the live body); drivers clamped so they cannot close it |
| D21 | Unstable forms with both portals at one end: the portals share a plane and touch whenever eye spacing is less than portal width (Pocket: 1.95 W vs 2.0 W) | spacing at least portal width plus gap (about 2.1 W, inside the envelope), or shrink, or offset the heights (3.5) |
| D22 | Portal-swap timing and phase overlap | 1.2 s, phases 0.35 / 0.3 / 0.35, no overlap |
| D23 | Top-down view: which surfaces, what moves the camera | open (8.1) |

## 14. Stale documents this draft supersedes or corrects

- `RaBbLE-NeBuLA/specs/visual-spec.md:85` (magenta left as canonical; contradicted by the S190 ruling at `:105-109` and by ruling 3); `:342-346` (listening "not implemented").
- `RaBbLE-Grimoire/log/plans/NeBuLA-Pocket-Puppet-Rendering-Pipeline.md` (Godot plus ThorVG for Pocket; nebula_lite replaced it).
- `RaBbLE-Pocket-Entity-Format.md` source paths under `firmware/sdk/` and `firmware/app/` (moved in S314).
- `RaBbLE-BaBbLE/intake/RaBbLE-Entity-Rig-Spec.md:23,43` (magenta placeholder).

## Revision history

| Version | Date | Change |
|---|---|---|
| draft 0 | 2026-11-09 | First draft from a read of all five repos; role-frame poses generated and checked by spike. |
| draft 1 | 2026-11-09 | Rulings 8-11: proportions envelope, poses are seeds, interior triggers unset, rig vs expression-library authorship with a proposal gate. |
| draft 3 | 2026-11-09 | Hover measured in body space (6 units, offset about 1.05, was 1.3); eyes never clipped at rest; audit redone; top view confirmed. |
| draft 10b | 2026-11-10 | Ruling 36: portal Y limited to 0.2..1.5, smooth-field swallow mask (no squares), smoother swap and uniform eye shrink from above or below. |
| draft 10 | 2026-11-10 | Ruling 35: 0 degrees equals the 2D reference (no perspective, opening 0.30), perspective blends in with elevation; portal Y default 1.00. |
| draft 9c | 2026-11-10 | Ruling 34: equal portal opening (sight-line compensation) and equal size at every angle. |
| draft 9b | 2026-11-10 | Ruling 33: tilt in the view frame (stable through the turn), stronger perspective and floor so 0 degrees reads 3D, portal-by-portal draw order with the lower-role rim clipped to its eye. |
| draft 9 | 2026-11-10 | Ruling 32: one symmetric tilt rule (open floor, even in elevation), occlusion by role. |
| draft 8b | 2026-11-10 | Ruling 31: front view, colour swap and portal swap accepted as baseline; steep-view silhouette fix (no flip at 50 degrees, top and bottom symmetric); soft-edged swallow dissolve. |
| draft 8 | 2026-11-10 | Ruling 30: draw order wells, then per side orb then own near rim; dome cut with dissolve; elevation to -90; colour crosses the whole turn through violet. |
| draft 7b | 2026-11-10 | Work moved from /tmp into the Grimoire (`log/plans/Unified-Entity/`); swallow fade follows the cut arc; infinity flow rebuilt so its gap faces the other portal (no scribble when rings stack). |
| draft 7 | 2026-11-10 | Ruling 29: no portal tilt, single draw order (portals over eyes), arc-and-fade swallow cut, top and bottom verified symmetric. |
| draft 6b | 2026-11-10 | Ruling 28: exact view-following portal tilt (no Mirror flicker), from-below camera, portal Y can swallow the eyes. |
| draft 6 | 2026-11-10 | Ruling 27: emotions pruned to calm, Pocket proportion set removed, hover replaced by portal Y, portals tip for minimum opening, draw order depends on rest vs motion. |
| draft 5d | 2026-11-10 | Ruling 26: orbs always drawn over all portals (bent-physics layering kept on purpose). |
| draft 5c | 2026-11-10 | Ruling 25: eyes fully gone through the middle of the swap, Ball-style tilt (eye settles into its ring, near rim never over the orb). |
| draft 5b | 2026-11-10 | Ruling 24: Pocket-style continuous portal swap with a depth arc; blink as squash; top-down eye tear fixed. |
| draft 5 | 2026-11-10 | Rulings 22-23: colour-volume at the YZ plane (position-defined colour), two arrangements and two moves, illegal states hidden, Pocket occlusion declared wrong. Live body: eyes are clean white with a pole-colour outline, voids are plain black, the turn is rigid and colour flips at the plane. |
| draft 4b | 2026-11-10 | Ruling 21 (physical energy/void look, Disney eyes); live body rebuilt as one true 3D camera with perspective, trails, stretch, orthographic toggle. |
| draft 4a | 2026-11-10 | Mark's sketch: rulings 18-20 (eye proportions variable, no-touch restated, perspective is the default view, orthographic front is a special case); sketch read added as 12b. |
| draft 4 | 2026-11-10 | Rulings 15-17 and revised 4, 13: pole swap is a turn about the face's centre axis (orbit); shapes (tall pill eyes, disc portals, perspective always); reference proportions = rig baseline; piloting and default rest deferred; live body shows the orbit. |
| draft 2 | 2026-11-09 | Rulings 12-14 and the revised 5: no touching (with audit), Pocket reference proportions hovering, portal swap as recede-move-emerge, pole swap as a rotation (the four forms as half-turns), ±252 retired, top-down view and infinity edge. |
