# RaBbLE Unified Entity: the rules in force (digest of draft 10b)

```
transcribe ~ grimoire/entity >> 36 rulings folded to the ones that still hold // %S322_DIGEST%
```

> **What this is:** a one-page read of `Unified-Entity-Puppet-Spec.md` (draft 10b, 2026-11-10) with every superseded ruling removed. Written S322 as a derived view. **The spec's ruling log wins wherever this page differs**; fix this page, or better, promote it (see "Consolidation" at the bottom).
> **Why:** the spec is 65 KB (about 16k tokens) and its body is stale where rulings 15 to 36 override it. An agent that needs "what does the entity look like and how does it move" should read this page (about 1.5k tokens) and open the spec only for numbers and history.
> **Numbers in brackets are ruling numbers** in section 0 of the spec.

## 1. Model

- **Route A:** one shared data model, each surface keeps its own native renderer; parity is proven by tests, not shared code [1]. Every expression renders on every surface [2].
- **Surfaces:** web NeBuLA (`alive-backend.js`), the Ball (top-down), Pocket (`nebula_lite`), sCoRE TUI face (Full, Mini, micro mark).
- **Authorship:** Mark owns the rig (body, canon, moves, render contract). The expression library is seeded by Mark and grown by RaBbLE through a propose, validate, preview, sign-off, merge gate [11, spec section 12].
- **The brand entity stays native:** this is not an `rbl-entity/1` file and is not published as one [7].

## 2. Body

- Two **eyes** (energy objects): tall pills, taller than wide; the ratio is a range, not a number [16, 18].
- Two **portals** (void objects): discs that read as ellipses wider than tall, about the same size as the eyes [16].
- **Proportions:** an envelope with the rig baseline as the reference set. Pocket's set is removed (it breaks the occlusion rules) [8, 13, 27b].
- **Home:** cyan on the left, left portal on top (interior word `0110`) [3].
- **No touch:** portals never touch each other; an eye never crosses a portal's edge, it recedes into the opening first [12, 19].
- **Infinity flow** sits between the two portals; each loop's gap faces the other portal [30e].
- **Look:** animated, Disney-like eyes. Nothing reads as a 2D cutout; every animation is a physical object travelling in 3-space [21].

## 3. Colour is position

A colour volume sits on the YZ plane through the face centre: cyan to the left, magenta to the right, blended over 96 face units each side, hue running the short way through violet [22, 30d]. Parts take their colour from where they are. Poles are never swapped as a state.

## 4. Arrangements and moves

Two arrangements (which portal is on top) and two moves between them; both land in the same image [22]. Moves are physical, never morphs [5].

| Move | Rule |
|---|---|
| **Turn** | The whole face yaws a half-turn about its own centre axis; eyes trade places, one passing in front [15, 22]. Colour changes across the whole turn [30d]. |
| **Portal swap** | Pocket's withdraw-swap in 3D, one continuous move of 1.45 s with a smootherstep plateau: each portal slides through its eye to the mirror position while the eye squashes into the portal it is leaving and grows out of the other; portals arc past each other in depth (about 75 units) [24, 36c]. From above or below the eye shrinks uniformly instead [36c]. |
| **Blink** | The same squash toward the portal. Never a screen-space cut [24]. |

## 5. Camera and view

- **0 degrees is the 2D reference:** two identical flat portal ellipses (flatten 0.30), two identical upright pills, portal Y 1.00 [35].
- Perspective blends in with elevation, `persp = smoothstep(|e| / 0.4)`, full by about 23 degrees [35]. The entity is in perspective most of the time [20].
- Elevation runs -90 to +90; top and bottom are the same view with the roles reversed [29d, 30c]. Oddities above about 25 degrees are accepted for now.
- **Top-down (the Ball) is part of the entity** [14]: as the camera tilts from about 29 to 69 degrees each eye settles into the centre of its ring and shrinks to 74% of the ring's height [25, 31a].
- **Portal tilt, one rule:** opening is `sin(eps)`, `eps = (|e| + EPS0 + sqrt((|e| - EPS0)^2 + EPSK^2)) / 2`, `EPS0` 0.283, `EPSK` 0.16; elevation only, applied in the view frame, less each portal's own sight-line angle; the disc is not scaled by its centre's depth [32a, 33a, 34, 35].

## 6. Occlusion and draw order

By role [32b, 33c]:

1. Each portal, far to near: its well, then its near rim.
2. Every eye.
3. Clipped to its own eye only: a **lower-role** portal's near rim over that eye (drawn through). An **upper-role** eye stays in front of its portal.

No ring ever crosses the other side's eye. Pocket's occlusion is wrong and is not a reference [23].

**Swallow cut:** portal Y runs 0.2 to 1.5 eye half-heights, default 1.00 [35, 36a]. The part of an eye past its portal's plane is removed along a dome and dissolves by alpha through a smooth field, `smoothstep(sd / span)`; no clip rectangles [30b, 36b]. There is no hover setting [27c].

## 7. Expression (not started)

- **Only calm exists** on the live body. Joy, sad, angry, speaking and listening are parked seeds, not canon [9, 27a].
- What speaking or listening does to the interior form is unset [10]. Piloting (default rest, triggers, what a swap means) is deferred [17].
- Next, per S321: calm, curious and one stronger state, posed role-relative.

## 8. Superseded: do not implement

| Ruling | Was | Replaced by |
|---|---|---|
| 4 | four stable forms as legal rests | 22 (two arrangements), pending Mark's confirmation |
| 23, 26, 27e, 29b, 30a | earlier draw orders | 32b + 33c |
| 27d, 28a, 29a | per-portal tilt solvers; no tilt | 32a, 33a, 34, 35 |
| 24, 25 (timing only) | 0.95 s and 1.15 s swaps | 36c (1.45 s) |
| 27c (default 1.04), 28c (range -0.6 to 1.5) | portal Y | 35, 36a |
| 29c | concave arc cut | 30b, 36b |
| 5 (part) | the +-252 Listening pose | retired |

## 9. Contradictions the consolidation pass has to settle

1. **Ruling 4 against ruling 22.** Section 4's four-form tables, D16, D21 and the `interior.forms` block in the section 10.1 registry sample still describe Swap and Swap-Mirror. Ruling 22 dropped them "pending Mark's confirmation". Needs one explicit yes.
2. **Ruling 6 ("curious by default") against 27a ("only calm remains").** Is curious the first expression to build, or the name for the resting temperament?
3. **Section 10.1's sample registry is stale:** `transition.seconds` 0.7 and `withdraw` 0.97 (now 1.45 s, smootherstep), four forms, no portal Y, no tilt constants, no camera blend.
4. **Open decisions D20 (hover gap) and D22 (swap timing) are closed** by 27c and 36c but still listed open.
5. **Identity's lifecycle is unmapped.** `RaBbLE-Agent/RaBbLE-Identity.md` defines `%DORMANT%`, `%INITIALIZING%`, `%CALIBRATING%`, `%RESONANT%`, `%GLITCH%`, `%SYSTEM_DRIFT%`, `%GENIUS_RESONANCE%`. The spec's layers are emotion, state and mood. Nothing says what the body does in `%GLITCH%` or `%DORMANT%`. Proposal: a fourth layer, **condition**, mapped in the registry (dormant = eyes receded, glitch = mood plus aura, drift = dimmed), so the system state the entity reports and the face it shows cannot disagree.
6. **Ruling 17 sits after 36** and the revision history is out of order.

## 10. Consolidation (proposed shape, S322)

The spec grows a ruling per draft and never shrinks, which is why it needed this page. Proposed split, all three in the Grimoire:

| File | Holds | Changes how |
|---|---|---|
| `registry/entity/rabble.entity.json` | the data: genome, body, moves, camera, tilt constants, expression library, surface profiles | generators and validators read it; the only place a number lives |
| `RaBbLE/Entity/RaBbLE-Entity-Spec.md` (or stay in `log/plans/` until accepted) | the canon in force, rewritten in place. This page is its seed | edited when a ruling lands |
| `Unified-Entity-Rulings.md` | the append-only ruling log (today's section 0) and revision history | append only; never read for "what is true now" |

Then `gist/RaBbLE-Entity-gist.md` distils the spec, so the entity is part of the first 4k tokens every agent reads. Today no gist describes the body at all.
