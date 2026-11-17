# RaBbLE Entity Rig: Rebuild Spec

Version: sketch 08 (Oct 12, 2026). Reference build: `rabble-entity-rig.html` (single-file Three.js r149, ~52 KB).
Purpose: enough detail to rebuild the character in another chat, in a code session, or in another engine (Unity, Godot, Blender, R3F) without the original conversation.

Units are scene units (about 1 unit = 1 torso radius). +Y is up, +Z is the entity's front. Angles are radians. "L/R" and `side` mean the entity's left (-1) and right (+1).

---

## 1. Non-negotiable Entity rules

These come from the canonical RaBbLE Entity design rules and override anything else in this spec.

1. The face is **two eyes (pills) in asymmetrical portals**, with **opposed color poles** (cyan and magenta). Which side is cyan can swap, but the two must always be opposite.
2. **No pupils.** Ever.
3. **Portal occlusion:**
   - The eye always hides its portal's **back rim**.
   - The portal's **front rim** clips the eye where they overlap, so the eye can go into the portal.
   - The eye never paints over a front rim. No rim line crosses through an eye.
4. **Hiding only by receding.** No lid-style cuts and no squints. An eye disappears only by sliding fully into its portal.
5. Baseline portal offsets are symmetric. Eyes may glide within their portals.
6. The background is not part of the entity. It works in a void or any environment.
7. Magenta is an Aether palette item. `#ec4c96` is a stand-in; replace it with the canonical Aether magenta when known.

---

## 2. Look and render style

- **Shading:** toon (`MeshToonMaterial`) with a 3-step ramp (gray levels 110, 185, 255), plus inverted-hull ink outlines. The hull is a back-face copy pushed out along normals by 0.010 to 0.035 depending on part size. Ink color `#17161b`.
- **Hand-drawn feel:** use ink **tubes** for panel seams, not hull outlines, so seams sit exactly on the surface. Avoid stacked parallel lines, because they read as glitches.
- **Material palette:**

| Token | Hex | Use |
|---|---|---|
| shell | `#efede9` | main body, arm shells, finger segments |
| plate | `#f8f7f4` | front plate, lenses |
| joint | `#c4c1bc` | elbow ball, collars, hip housings |
| ball | `#8f8c8a` | finger ball joints |
| dark | `#5f5c5b` | ornaments, foot caps, sensor drip |
| bezel | `#d9d6d1` | face socket bezel |
| hatch | `#cfccc6` + crosshatch `#2b2a2e` | arm bands, neck cap, back vent |
| cyan pole | `#4fe3f0` | |
| magenta pole | `#ec4c96` (placeholder) | |
| waveform accent | `#9b7bf0` | third voice line only |

- **Scene modes:** "Paper" (sky `#f6f6f4`, floor `#2b2b2e`) and "Void" (sky `#0b0b10`, floor `#131318`). Overlay text color follows the scene, not the page theme.

---

## 3. Hierarchy

```
root                      (body XZ position; draggable "body" gizmo)
 └ hover                  (y = hover height, default 1.85)
    └ torso               (yaw/pitch/roll, Euler order YXZ)
       ├ shell lathe, front plate, seams, neck cap, chest sensor, name decal, back vent, base rings
       ├ orb              (face socket, fixed to torso)
       │  ├ bezel + socket wall (conform to plate curve)
       │  └ faceTilt      (rot.x 0.17, z -0.07)
       │     ├ screen     (front hemisphere, 2D canvas texture)
       │     └ glass      (fresnel shell)
       └ [shoulder anchor point sLocal = (side*1.18, 0.80, 0)]
scene (world space, solved by IK every frame; NOT parented to torso)
 ├ upperArm[L/R]          (pivot at shoulder world pos)
 ├ elbowBall[L/R]
 ├ forearm[L/R]
 └ podYaw[L/R]            (at wrist; yaw from the hand-aim handle, roll = hand roll)
    └ podBody             (y -0.42)
       ├ pod lathe, collar + bolts, face lens (mini-face canvas)
       └ 4 finger chains  (solved in podBody-local space)
```

The arms live in world space so the hands stay planted while the body bobs, leans, or moves.

---

## 4. Torso

- **Body:** a lathe of profile `(radius, y)`, bottom to top:
  `[0,-1.22] [0.9,-1.22] [1.02,-1.12] [1.12,-0.75] [1.24,-0.2] [1.33,0.35] [1.34,0.75] [1.25,1.02] [1.0,1.16] [0.55,1.22] [0,1.22]`, 64 segments.
  Points must run bottom to top, or the faces point inward.
  `rAt(y)` linearly interpolates this profile and is used to place everything on the surface.
- **Front plate:**
  - Lathe segment phi ∈ [-0.95, 0.95], y ∈ [-1.13, 1.04], radius `rAt(y)*1.015+0.012`.
  - Ink tube border, radius 0.013.
  - Short vertical seam on the centerline from the plate top to y 1.2.
- **Neck cap:** hatched disc, radius 0.58, at y 1.226, with an ink ring.
- **Chest sensor:** centered at y 0.95 on the surface.
  - Bezel torus (radius 0.1, tube 0.025).
  - Dark glossy lens with **no pupil**, flattened z × 0.6.
  - Small inverted cone "drip" below it.
- **Name decal:** "RaBbLE" in a handwritten face (Kalam 700), rotated about -74°. It sits on a lathe patch at phi [-0.93, -0.69], y [0.12, 0.92]. This is the only intentional asymmetry.
- **Back vent:** hatched lathe panel at phi π ± 0.55, y [-0.5, 0.6], with an ink border.
- **Base:** two stacked rings under the torso:
  - cylinder r 0.86→0.70, h 0.2, at y -1.3
  - cylinder r 0.62→0.50, h 0.1, at y -1.44
- Everything is symmetric about the centerline except the name decal.

---

## 5. Face (orb)

### Geometry
- **Orb anchor:** torso-local `(0, YO=-0.17, rAt(YO)-0.06)`.
- **Bezel:**
  - A raised ring strip from inner radius 0.835 to outer radius 0.93.
  - Each vertex's z is computed from the plate surface (`zSurf(x,y)`), so the bezel hugs the curved plate. The inner edge is lifted +0.07.
  - Ink loops on both edges.
- **Socket wall:** a dark (`#121116`) ring strip from the bezel's inner edge, going 0.42 deep, so no gap shows around the screen.
- **Screen:**
  - Front hemisphere, radius 0.76, scaled z 0.34, at z 0.10 inside `faceTilt`.
  - **Planar UVs:** `u = x/(2R)+0.5`, `v = y/(2R)+0.5`, so the 2D face lands undistorted from the front.
  - Unlit (`MeshBasicMaterial`).
- **Glass:**
  - Sphere radius 0.82, scaled z 0.58, at z 0.06, renderOrder 10, depthWrite off.
  - Fresnel shader: base alpha 0.05, a soft band near grazing angles, a solid ink rim when `1-|n·v| > 0.86–0.93`, and one specular highlight.
  - No hull outline on the glass: a full-sphere hull draws a black ring through the bezel.

### 2D face texture (512×512 canvas, redrawn every frame)
- **Background:** radial gradient `#7c7b82` → `#4a4950` → `#2c2b30`.
- **Portals:** flat ellipses.
  - Lower portal PL: `cx 176, cy 356, rx 92, ry 19`.
  - Upper portal PR: `cx 336, cy 158, rx 92, ry 19`.
  - Each portal has a dark radial-gradient hole.
  - Rim stroke: 11 px ink underlay, then 5.5 px pole color on top.
- **Eyes:**
  - Pills 58 × 206 px.
  - Chromatic fringe: own-pole pill offset -11% of width, opposite-pole pill offset +11%. Then a white core at 80% width with a soft white glow.
- **Lower eye (stands, cyan pole):**
  - Portal seen from **above**: back rim is the upper arc (π..2π), front rim is the lower arc (0..π).
  - Draw order: hole, back rim, eye, front rim.
  - Clip the eye to `rect(0,0,W,cy) ∪ lower-half ellipse(ex, cy, EW/2+2, ery·k)`. Here `ery = ry·(EW/2)/rx + 2` and `k = clamp(visible/EW, 0, 1)`, so the curved base flattens to nothing as the eye sinks.
- **Upper eye (hangs, magenta pole):**
  - Portal seen from **below**: back rim is the lower arc, front rim is the upper arc.
  - Same draw order.
  - Clip to `rect(0,cy,W,H-cy) ∪ upper-half ellipse`.
- **Recede:** `visible = max(0, (EH-4)·(1-recede))`. Skip the draw when visible < 0.5. At recede ≥ 1 the eye is fully gone.
  - The pill top is `cy - visible` for the standing eye, and the pill bottom is `cy + visible` for the hanging eye.
- **Glide:** `eyeX ∈ [-0.11, 0.11]` maps to ±`(rx - EW/2 - 8)` px. Both eyes glide together.
- **Voice waveform:**
  - Three lines (pole A, pole B, purple at 0.6× amplitude), x 150→362, y 452.
  - Additive blending.
  - Each line is the sum of two sines multiplied by a `sin(πu)` envelope. Amplitude = `wave × 430` px.
- **Blink:** both eyes (or occasionally one) recede to about 1.05 and back over 0.26 s, every 2.8 to 6.3 s. This is the only blink style allowed.

---

## 6. Arms (2-bone IK, one middle joint)

- **Segments:**
  - Upper arm LU = 0.86. Forearm LF = 0.90.
  - Shoulder anchor at torso-local `(side·1.18, 0.80, 0)`, converted to world space each frame.
- **Upper arm (built along -Y from the pivot):**
  - Sphere cap, radius 0.52.
  - Lathe sleeve `[0.41,-0.66] [0.43,-0.62] [0.47,-0.48] [0.50,-0.25] [0.505,0]` (bottom to top).
  - Ink lip ring at the opening, seam ring at y -0.25.
- **Middle joint:** one ball, radius 0.33, joint color, placed at the solved elbow E.
- **Forearm (built along -Y from E):**
  - Joint disc: radius 0.37, height 0.14, at y -0.16, with a dark torus ornament.
  - Then shell ring 0.32 → hatched band 0.305 → tapering shell ring 0.31→0.25 → small collar 0.2.
  - It runs straight into the hand. There is no separate wrist ball.
- **Solver (`ik2(S, T, pole, l1, l2)`):**
  1. Clamp the distance to `[|l1-l2|+ε, l1+l2-ε]`.
  2. Project the pole onto the plane perpendicular to the S→T direction.
  3. `cos a = (l1²+d²-l2²)/(2·l1·d)`.
  4. `E = S + dir·cos(a)·l1 + poleDir·sin(a)·l1`. The wrist W is `S + dir·d`; when overextended, W stops short of T.
- **Orienting each segment:** basis with `y = normalize(from-to)`, `x = normalize(y × (pole-from))`, `z = x × y`. This keeps segments twist-stable.
- **Rest targets (world space):**

| | Left | Right |
|---|---|---|
| hand | `(-2.2, 1.36, 0.4)` | `(2.2, 1.36, 0.4)` |
| pole | `(-2.8, 3.6, -0.9)` | `(2.8, 3.6, -0.9)` |

---

## 7. Hands (hand-creatures)

### Pod
- `podYaw` sits at wrist W. Its yaw comes from the hand-aim offset `atan2(aimOff.x, aimOff.z)`, smoothed 20% per frame. Its roll is `side·handRoll`.
- `podBody` is at y -0.42.
- **Body:** faceted barrel. Lathe with 10 radial segments, scaled z 0.92. Profile (bottom to top):
  `[0,-0.36] [0.2,-0.34] [0.34,-0.25] [0.42,-0.08] [0.43,0.08] [0.38,0.24] [0.28,0.35] [0.2,0.4] [0,0.41]`.
  Ink seam at y -0.17.
- **Wrist collar:** cylinder 0.22→0.24, h 0.08, at y 0.40, with 10 small dark bolts around it.
- **Face lens:** plate disc, radius 0.25, at `(0, 0.06, 0.375)`, plus a CircleGeometry carrying the mini-face canvas.
  Use a CircleGeometry for the face image, not a cylinder cap, because the cylinder's cap UVs come out rotated 90°.

### Mini-face (160×160 canvas)
- Thick ink ring.
- One eye **hangs from a top bar** (upper pole color, left) and one **stands on a bottom bar** (lower pole color, right), matching the "T1" marks in the sketch.
- Bars are small dark ellipses (17 × 4.5) with a pole-colored stroke.
- Eyes clip at their bar and recede into it, following the main face's recede values.

### Fingers: 4 per hand, all grasp an invisible ball

- **Grasp ball (IK end effectors):**
  - Center in podBody-local space, default `(0, -0.7, 0)`. Radius = grip, default 0.30.
  - Finger i targets `ballCenter + dirC_i · grip`, where `dirC = (sin az·cos lat, sin lat, cos az·cos lat)`.
  - Growing the ball opens the hand; shrinking it closes the hand.
- **Ball joints:**
  - Walking fingers and pinky: **two** (root at the pod, knuckle).
  - Thumb: **three** (root and two knuckles).
- **Segments** are straight cylinders between the balls, not capsules, so no false joints appear. Ball radius is `1.3·r`.

| Finger | az | lat | root radius / y | lengths | r | tip |
|---|---|---|---|---|---|---|
| Walk A | -0.42 | -0.62 | 0.30 / -0.24 | 0.36, 0.44 | 0.08 | **foot**: horizontal roller (r·1.0, length 0.22) with a dark end cap; axis points radially outward; sits at the tip |
| Walk B | +0.42 | -0.62 | 0.30 / -0.24 | 0.36, 0.44 | 0.08 | foot |
| Thumb (outer) | side·(π/2+0.25) | 0.05 | 0.40 / 0.02 | 0.18, 0.26, 0.30 | 0.068 | rounded capsule. 3-bone: solve 2-bone with l2+l3, split the outer bone at l2/(l2+l3), bow the split point toward the pole by 0.06 |
| Pinky (inner) | -side·(π/2+0.25) | -0.15 | 0.38 / -0.08 | 0.30, 0.36 | 0.07 | blocky box tip with an ink "nail" line |

- The walking fingers sit **side by side under the front**, not front and back.
- **Finger pole:** `root + radial·0.7 + (0, polY, 0)`. polY is 0.5 for walking fingers, 0.6 for the thumb, 0.45 for the pinky. This makes the knuckles bow outward and up.

---

## 8. Gizmos (draggable handles)

All gizmos render on top (`depthTest: false`). Each has an invisible pick sphere of radius ≥ 0.17. Dragging uses a plane through the handle facing the camera. Rings billboard to the camera.

| Handle | Color | Shape | Controls |
|---|---|---|---|
| Hand target ×2 | `#ff9f1c` | sphere + ring | Arm IK target. Dragging edits the rest position; behavior offsets add on top. Minimum y 0.3. |
| Elbow pole ×2 | `#8b6cff` | octahedron + ring, dashed line to elbow | IK pole (bend direction) |
| Hand aim ×2 | `#ffd166` | small sphere, dashed line to pod | Hand yaw (offset relative to the hand target) |
| Grasp ball ×2 | `#ffb44d` | wireframe sphere scaled by grip | Finger end-effector center (stored in podBody-local space) |
| Body | `#2fb866` | cube, 1.85 above hover | Root XZ (clamped to radius 3) and hover height (1.5–2.5). Hands stay planted. |
| Look target | `#2e9bff` | sphere + ring, dashed line from face | Gaze point, used when Look = "gizmo" |

---

## 9. Animation model

Face and body are **independent layers**. Each frame, each layer writes target values. Every parameter then eases toward its target: `p += (target-p)·(1-e^(-dt·rate))`. The default rate is 4. Faster rates: hand offsets and roll 6–10, voice 8, recede 14.

**Face parameters:** `eyeX, recedeL, recedeR, wave, ring (ground ripple speed), glow`.

| Face state | Behavior |
|---|---|
| idle | slow eye drift, blinks |
| listen | eyes extend (recede -0.06), slow bright ripples |
| speak | voice waveform driven by syllable pulses, eyes bounce, faster ripples |
| alert | eyes extended, darting glide, fast bright ripples |
| recede | both eyes fully inside the portals, ripples dim |
| manual | slider values |

**Body parameters:**
- `hover, yaw, pitch, roll`
- per-hand target offset `{L,R}O{x,y,z}`
- pole offset `{L,R}P{x,y,z}`
- grip `{L,R}Grip`
- roll `{L,R}Tw`

| Body state | Behavior |
|---|---|
| idle | hover bob 0.045, gentle sway |
| listen ("Lean in") | lean and tilt, hands forward |
| gesture | left hand lifts and opens rhythmically |
| wave | right hand up 2.35, waves at 8.5 Hz, pole dropped so the elbow points out and down, hand open |
| alert | rise 0.21, hands out and open, scanning yaw |
| rest | sink 0.13, lean forward, hands in and closed |
| manual | slider values |

**Look:** source is cursor, look gizmo, or off. It feeds the eye glide (×0.08) and torso yaw/pitch (×0.22 / ×0.04). It is disabled during recede, rest, and manual.

**Ground:** shader plane.
- Two families of wobbly concentric rings (pole A and pole B), offset by half a ring, drifting outward at `ring` speed.
- Six wobbly colored spokes.
- Faint pencil spokes.
- A contact shadow under the body and under each grasp ball.
- Distance fog to the sky color.
- Rings center on the body's XZ position.

---

## 10. Runtime API (reference build)

```js
RaBbLE.setFace('idle'|'listen'|'speak'|'alert'|'recede'|'manual')
RaBbLE.setBody('idle'|'listen'|'gesture'|'wave'|'alert'|'rest'|'manual')
RaBbLE.setHand('left'|'right', x, y, z)   // world rest target
RaBbLE.setPole('left'|'right', x, y, z)
RaBbLE.setGrip('left'|'right', radius)    // switches body to manual
RaBbLE.setLook(x, y, z)                   // switches look to gizmo
RaBbLE.moveBody(x, z, hover?)
RaBbLE.swapPoles()
RaBbLE.params            // live eased parameters
RaBbLE.rig.faceCanvas    // the 512² face canvas: draw into it or replace it
```

To drive the face from another source (for example the NeBuLA render), replace `drawFace(t)` or draw into `rig.faceCanvas` and set `needsUpdate` on the face texture. Keep the portal rules in section 5.

---

## 11. Porting notes

- **Three.js versions:** r149 uses `outputEncoding = sRGBEncoding` and `texture.encoding`. On r152+, switch to `outputColorSpace` and `texture.colorSpace = SRGBColorSpace`. `CapsuleGeometry` needs r139+.
- **Unity / Godot:**
  - Build the arm with a two-bone IK constraint (Unity Animation Rigging `TwoBoneIKConstraint`, Godot `SkeletonIK3D`, or the `ik2` math above).
  - Fingers: one two-bone constraint per finger, with targets parented to a "grasp ball" transform under the hand.
  - Faces: a RenderTexture or SubViewport, or port `drawFace` to a shader.
- **Blender / GLB:** the parts are primitives and lathes, so they can be rebuilt with Screw/Spin modifiers.
  - Bones: `root > hover > torso > (shoulder.L/R)`. Arm chains are their own IK chains with pole targets.
  - Each finger is a 2-bone chain; the thumb is 3 bones.
  - Ink outlines: Solidify modifier with flipped normals and a backface-culled black material.
- **Pitfalls found during the build:**
  - Lathe profiles must run bottom to top, or the faces invert and show as black.
  - Cylinder cap UVs rotate textures 90°.
  - A full-sphere hull outline on glass cuts through the bezel.
  - Parallel seam lines close together read as glitches.
  - Arms must not be parented to the torso, or the hands slide.

---

## 12. Open items

- Canonical Aether magenta hex.
- Optional slight tilt of the face portals (the sketch shows about -8°).
- Per-foot plant targets, so the hands can step while the body moves.
- GLB export with named bones.
