#!/usr/bin/env python3
"""Apply the draft-2 edits to the spec; every target must exist exactly once."""
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()

def rep(old, new):
    global s
    n = s.count(old)
    if n != 1:
        sys.exit(f"target found {n} times: {old[:70]!r}")
    s = s.replace(old, new)

rep("> **Status:** draft 1, 2026-11-09.", "> **Status:** draft 2, 2026-11-09.")

rep("5. **The flip is the Pocket withdraw-swap,** on every surface (section 4.3).",
    "5. **Interior moves are physical, never morphs.** The portal swap is a recede and a move: the eye recedes into its portal, the portal travels to the other end, the eye emerges (4.3). The pole swap looks like a rotation in 3-space (4.3). The ±252 Listening pose is retired.")
rep("11. **Intent: RaBbLE defines how it expresses itself within the rig.** Mark authors the body and its canon; the expression library is RaBbLE's to grow (section 12).",
    "11. **Intent: RaBbLE defines how it expresses itself within the rig.** Mark authors the body and its canon; the expression library is RaBbLE's to grow (section 12).\n"
    "12. **Eyes and portals never physically touch.** Eyes may blink and recede (into their own portal, through its opening); nothing else brings two parts into contact (3.5).\n"
    "13. **Reference proportions: Pocket's, with the eyes hovering over their portals, not receded** (3.3).\n"
    "14. **The top-down view with the infinity edge (the Ball) is part of the entity** (8.2).")

rep("""| Ratio | Envelope (draft) | Reference set (Open: rig baseline or Pocket) |
|---|---|---|
| eye height : width | 2.5 .. 3.2 | 3.1 or 2.64 |
| eye centre spacing | 1.9 .. 2.2 W | 2.1 or 1.95 |
| portal width | 1.9 .. 2.8 W | 2.7 or 2.0 |
| portal flatten | 0.22 .. 0.33 | 0.3 or 0.25 |
| portal offset | 0.75 .. 0.95 eye half-heights | 0.93 or 0.86 / 0.79 |
| left/right asymmetry | at most 10% per ratio | (Pocket's offsets differ by 8%) |""",
"""| Ratio | Envelope (draft) | Reference set (ruling 13: Pocket ratios, hovering) |
|---|---|---|
| eye height : width | 2.5 .. 3.2 | 2.64 |
| eye centre spacing | 1.9 .. 2.2 W | 1.95 |
| portal width | 1.9 .. 2.8 W | 2.0 |
| portal flatten | 0.22 .. 0.33 | 0.25 |
| portal offset | set by the no-touch rule (3.5): the eye hovers clear of its portal | **1.3** eye half-heights (draft; Calm needs at least 1.25 for a 6-unit gap) |
| left/right asymmetry | at most 10% per ratio | symmetric (Pocket today: 0.86 / 0.79) |""")
rep("**Invariants that make it look like RaBbLE** (checked, not ranged): eyes are tall pills, taller than wide; a portal is wider than its eye;",
    "**Invariants that make it look like RaBbLE** (checked, not ranged): eyes are tall pills, taller than wide; each eye hovers over its own portal, clear of it, at rest; a portal is wider than its eye (so a receding eye passes through the opening without touching the rim);")

rep("| A portal never crosses its eye | in every form, `u * POR_OFF + portal.dy - eye.dy` keeps the sign of `u` by at least 24 (the web hysteresis, `alive-backend.js:349`), where `u = -1` upper, `+1` lower. Changing sides is an interior move (4.3), never a pose. |",
    "| **No touching** (ruling 12) | Outside a blink or recede, no two parts touch: eye and own portal, eye and the other portal, eye and eye, portal and portal. Checked on the outlines, in every form a pose can meet (stable and unstable), with a minimum gap (draft: 6 face units) plus the drivers' reach (gaze `±12` vertical, portal bob `±8`). During a recede the eye crosses the portal plane only inside the opening (eye half-width less than the opening radius minus the gap). Changing sides is an interior move (4.3), never a pose. |")
rep("The spike runs the crossing rule in all four forms: Calm, Joy, Sad, Angry, Speaking and Pocket's spread Listening pass; the ±252 Listening pose fails in every form, which is consistent with ruling 5.",
"""**No-touch audit** (`registry-spike/notouch.py`, front view, outlines, stable forms):

| Proportions | Eye and own portal | Other pairs | Unstable, both portals at one end |
|---|---|---|---|
| rig baseline today (offset 0.93) | every seed pose **touches** (the portal centre sits inside the eye) | clear (eye and other portal: 8 to 60) | portals **overlap** |
| Pocket today (0.86 / 0.79) | every seed pose **touches** | clear (24 to 66) | portals **overlap** (spacing 1.95 W is less than the portal width 2.0 W) |

Smallest offset (Pocket ratios) for a 6-unit gap in both stable geometries: Calm 1.25, Speaking 0.86, Listening (Pocket spread) 0.94, Sad 1.41, Angry 1.45, Joy 1.55. Poses that pull a portal toward its eye eat the hover gap; Joy's crescent (a portal rising into its orb) is a touch by definition, so the seed must change (6.1).

**Open:** unstable forms that put both portals at one end. Draft options: spacing at least portal width plus gap (about 2.1 W with Pocket portals); portals shrink in an unstable form; or the two portals sit at different depths (3D surfaces) and the 2D surfaces draw the far one smaller.

The ±252 Listening pose crosses its eye in every form and is retired (ruling 5).""")

rep("### 4.3 Transitions (Ruled: the Pocket withdraw-swap)\n\nFrom `scene.c:689-714`, `767-770`, `rabble_entity.c:56`, `652-660`, generalised:",
"""### 4.3 Transitions (Ruled: physical moves; timings draft)

**Portal swap: recede, move, emerge** (ruling 5). The eye recedes into its portal, the portal travels to the other end carrying the hidden eye, and the eye emerges from the other face. It refines Pocket's withdraw-swap (Mark liked it), which runs the three phases at once: the portal slides through a withdrawing eye. Sequenced, nothing ever touches, because the eye is inside the portal while it moves.

| Phase | Draft timing (1.2 s total) | Definition |
|---|---|---|
| recede | 0 .. 0.35 | the eye slides toward its portal and through the opening; the part past the portal plane is not drawn (Ball-style, `index.html:703-714`). Travel: the eye's far tip reaches the plane at recede 1. |
| move | 0.35 .. 0.65 | the portal moves to its mirror position about the eye's rest: `py = lerp(u_from * off, u_to * off, m)`; role-indexed pose values cross-fade by `m`, so nothing jumps when roles swap |
| emerge | 0.65 .. 1 | the eye comes back out, now on the far side of the portal it entered |
| role switch | at the middle of the move, eye hidden | rim halves, clip side, occlusion order and strand entry points switch |

**Pole swap: a rotation in 3-space** (ruling 5). Two readings, both shown in the live body:

- **Eye spin:** each eye turns over about its own vertical axis, like a coin; its width follows `|cos θ|`, and the colour changes when it is edge-on at 90°. Only the colours change, so this is exactly the Swap move, with no part moving.
- **Body roll:** the whole entity turns 180° in the face plane. The image after the turn is the Swap form.

A structural finding: the four stable forms are the body under the three half-turns. Roll (about the depth axis) gives **Swap**; pitch (about the horizontal axis) gives **Mirror**; yaw (about the vertical axis, turning around) gives **Swap-Mirror**. Ruling 5 makes Mirror a recede-and-move rather than a pitch. Yaw is offered in the live body as "turn around", a single move to Swap-Mirror; the Ball already turns its entity with the viewer (`index.html:990`). Caution: world-frame channels (gravity droop, lift, tilt) do not rotate with the body, so an asymmetric pose is re-resolved by role when a roll or yaw completes.

**Open:** which rotation is the pole swap (D5), and whether yaw is a legal move of its own.

**Pocket's withdraw-swap, as built** (`scene.c:689-714`, `767-770`, `rabble_entity.c:56`, `652-660`), kept for reference:""")

rep("**Eye-colour swap (Open, draft default):** the same withdraw curve, with the pole swapped at the midpoint while the eye is hidden, and no portal travel. Nothing renders a live eye swap today.",
    "Nothing renders a live pole swap today on any surface.")
rep("**Single-slot flips** (one eye or one portal) enter unstable words. They use the same curve on one side only.",
    "**Single-slot moves** (one eye or one portal) enter unstable words. They use the same moves on one side only.")

rep("| listening, candidate B (today's web/TUI) | sy 1.04 | dy 252 | sy 1.04 | dy -252 | **fails canon** (crosses); would become \"spread or calm pose + portal flip\" |",
    "| listening, candidate B (today's web/TUI) | sy 1.04 | dy 252 | sy 1.04 | dy -252 | **Retired** (ruling 5): crosses its eye in every form |")
rep("Read in the body frame, the authored intent becomes visible:",
    "**Under the no-touch rule these seeds must change:** Joy (the crescent is a portal rising into its orb), Angry (portals clamp onto the eyes) and Sad (portals drawn in) all bring a portal into contact at the reference offset. The intent can stay; the expression of it has to come from portal tilt and scale, eye shape, head and gaze instead of contact. This is the first work for the expression library (section 12).\n\nRead in the body frame, the authored intent becomes visible:")

rep("""Rig 08: "This is the only blink style allowed." Web, TUI and Pocket squash the eye toward its portal (`face.rs:462-464`, `scene.c:767-770`); the Ball slides it into the portal (`index.html:703-714`). Both are recedes. The render contract (8) requires the eye to shrink or slide toward its own portal; it must never fade out or close like a lid.""",
"""Ruling 12: eyes may blink and recede. A blink is a short, partial recede into the eye's own portal; a recede is the same motion carried through. Rig 08: "This is the only blink style allowed." Web, TUI and Pocket squash the eye toward its portal (`face.rs:462-464`, `scene.c:767-770`); the Ball slides it into the portal (`index.html:703-714`). With the eyes now hovering clear of their portals, a squash in place no longer reaches the portal, so the draft default is the Ball's slide: the eye travels across the hover gap and into the opening, and the part past the portal plane is not drawn. It must never fade out or close like a lid.""")

rep("### 8.1 Degrade ladder",
"""### 8.2 Views: front and top-down (ruling 14)

The entity has a camera elevation, from front (0°) to top-down (90°). The Ball renders the whole range (`index.html:671-718`, `793-806`); the other surfaces draw front today. In body terms:

| Element | Front | Toward top-down |
|---|---|---|
| portals | flattened discs (flatten 0.25) | open into circles: `ry = rx * (flatten + (1 - flatten) * sin(elevation))` |
| eyes | tall pills hovering over their portals | settle into their portal's centre and shrink to fit inside the ring (Ball: 0.74 of its height), from about 35° to 70° |
| vertical offsets | as posed | compress by `cos(elevation)` |
| **infinity edge** (aura) | hidden | fades in from about 14° to 46° (Ball: `smoothstep(0.25, 0.8)` rad) |

**The infinity edge** (Ball, `index.html:720-806`): matter streams around each portal just outside its rim (three streams at 1.06, 1.25 and 1.48 portal radii), each loop opening toward the other portal (gap half-angle 0.75 rad), then slings across on a curve that leaves each rim along its tangent, so the whole flow is one figure-eight. Colour follows whichever portal is nearer (cyan to magenta); sparks ride the main stream. It is aura tier, it never touches a rim (it stays outside it), and it follows the poles through a swap.

**Open:** which surfaces offer the top-down view (it suits Pocket's round panel), and what moves the camera (a mode, a gesture, an expression).

### 8.1 Degrade ladder""")

rep("| D2 | Joy's crescent: does it follow roles (the lower portal, whichever side)? | yes (as written in 6.1) |",
    "| D2 | How Joy, Angry and Sad express their intent without contact | to be redrawn (6.1); the first library work |")
rep("| D5 | Eye-colour swap rendering | same withdraw curve, no portal travel |",
    "| D5 | Which rotation is the pole swap: eye spin or body roll? Is yaw (turn around, to Swap-Mirror) a legal move? | both shown in the live body; undecided |")
rep("| D19 | Emotion poses themselves | seeds; Mark and RaBbLE refine (ruling 9) |",
    "| D19 | Emotion poses themselves | seeds; Mark and RaBbLE refine (ruling 9) |\n"
    "| D20 | Hover offset and minimum gap | offset 1.3 eye half-heights, gap 6 face units plus driver reach |\n"
    "| D21 | Unstable forms with both portals at one end (they overlap today) | spacing, shrink, or depth (3.5) |\n"
    "| D22 | Portal-swap timing and phase overlap | 1.2 s, phases 0.35 / 0.3 / 0.35, no overlap |\n"
    "| D23 | Top-down view: which surfaces, what moves the camera | open (8.2) |")
rep("| draft 1 | 2026-11-09 | Rulings 8-11: proportions envelope, poses are seeds, interior triggers unset, rig vs expression-library authorship with a proposal gate. |",
    "| draft 1 | 2026-11-09 | Rulings 8-11: proportions envelope, poses are seeds, interior triggers unset, rig vs expression-library authorship with a proposal gate. |\n"
    "| draft 2 | 2026-11-09 | Rulings 12-14 and the revised 5: no touching (with audit), Pocket reference proportions hovering, portal swap as recede-move-emerge, pole swap as a rotation (the four forms as half-turns), ±252 retired, top-down view and infinity edge. |")
open(p, "w", encoding="utf-8").write(s)
print("draft 2 edits applied")
