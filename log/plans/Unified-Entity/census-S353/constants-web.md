# Web-side entity constants, with provenance

Scope: live.js (Puppet Spec live rig), the Puppet Spec HTML inline script, alive-backend.js, alive-gl.js, eye-behavior.js, specs/rig/*. Read-only extraction, 2026-11-18.

Abbreviations (paths relative to /home/rabble/RaBbLE-Collective/):
- **LIVE** = RaBbLE-Grimoire/log/plans/Unified-Entity/live/live.js. The inline script in Unified-Entity-Puppet-Spec.html (lines 150-451) is byte-identical apart from the first comment line and a blank line, so every LIVE value also holds for the HTML. `live/template.html` supplies the slider ranges.
- **ALIVE** = RaBbLE-NeBuLA/src/backends/alive-backend.js
- **EYEB** = RaBbLE-NeBuLA/src/backends/eye-behavior.js
- **RIG** = RaBbLE-NeBuLA/specs/rig/entity-rig.json (README says reference material only, not wired into any backend)
- **POSES** = RaBbLE-Grimoire/log/plans/Unified-Entity/registry-spike/poses.role.json (LIVE reads these via `POSES`, injected at build)
- Canon = RaBbLE-Grimoire/log/plans/Unified-Entity/Unified-Entity-Canon.md
- "Canon?": Y = agrees, N = conflicts, "-" = Canon states no number (the number is new to the registry), "n/a" = not applicable to that source.

Key finding up front: **alive-backend.js has none of the unified-entity rig mechanics.** No tilt (EPS0/EPSK), no swallow cut, no turn, no portal swap or withdraw, no elevation or perspective blend, no position-defined colour. It has the older 4-ellipse face rig plus emotion springs. alive-gl.js is a WebGL shim for Canvas2D draw calls and holds no entity constants. All rig numbers live only in LIVE. The registry must therefore take LIVE as the numeric source for body, moves, camera, tilt, cut and colour, and ALIVE only for expression, idle and aura constants.

## 1. Proportions

Face unit: eye width W = 87 (LIVE:13). Eye width is the unit for the `PROP` fields. In ALIVE, face units are raw (eye 87 x 272).

| name | value | unit | file:line | source(s) | Canon? |
|---|---|---|---|---|---|
| W (eye full width) | 87 | face units | LIVE:13 | LIVE | - |
| EYE_RX / EYE_RY | 43.5 / 136 | face units (half axes; eye 87 x 272, ratio 3.126) | ALIVE:202 | ALIVE | Y (matches W=87, eh 3.13) |
| eh, rig baseline (eye h:w) | 3.13 | eye widths | LIVE:9 | LIVE, RIG baseline ("1:3.1", json `baseline`) | Y (a range, not a number) |
| sp, rig baseline (centre spacing) | 2.11 | eye widths | LIVE:9 | LIVE; ALIVE EYE_X=92 gives 184/87=2.115; RIG 2.1 | - |
| pw, rig baseline (portal width) | 2.69 | eye widths | LIVE:9 | LIVE; ALIVE POR_RX=117 gives 234/87=2.69; RIG 2.7 | - |
| fl, rig baseline (flatten = ry/rx) | 0.30 | ratio | LIVE:9 | LIVE; ALIVE 35/117=0.299; RIG 0.3 | Y |
| off, `reference` preset | null (portal at +-portalK eye half-heights, no offset table) | - | LIVE:9 | LIVE | - |
| off, `baseline` preset ("Rig baseline today") | [0.93, 0.93] | eye half-heights, [left, right] | LIVE:11 | LIVE; ALIVE POR_OFF=126 / EYE_RY 136 = 0.926; RIG 0.93 | - |
| `pocket` preset: eh | 2.64 | eye widths | LIVE:10 | LIVE only | - (Canon: Pocket proportions to be changed to fit the envelope) |
| `pocket` preset: sp | 1.95 | eye widths | LIVE:10 | LIVE | same |
| `pocket` preset: pw | 2.0 | eye widths | LIVE:10 | LIVE | same |
| `pocket` preset: fl | 0.25 | ratio | LIVE:10 | LIVE | same |
| `pocket` preset: off | [0.86, 0.79] | eye half-heights, [left, right] | LIVE:10 | LIVE | same |
| ENV eh (envelope) | [2.5, 3.2] | eye widths | LIVE:12 | LIVE | Y in kind ("envelope"); numbers not in Canon |
| ENV sp | [1.9, 2.2] | eye widths | LIVE:12 | LIVE | - |
| ENV pw | [1.9, 2.8] | eye widths | LIVE:12 | LIVE | - |
| ENV fl | [0.22, 0.33] | ratio | LIVE:12 | LIVE | - |
| EYE_X (eye centre x) | +-92 | face units | ALIVE:202 | ALIVE | - |
| POR_RX / POR_RY | 117 / 35 | face units (portal 234 x 70) | ALIVE:202 | ALIVE | Y (flatten 0.30) |
| POR_OFF (portal centre y from eye centre) | 126 | face units | ALIVE:202, 340 | ALIVE | - |
| portalK (portal distance from eye centre) | 1.00, slider 0.2 to 1.5, step 0.01 | eye half-heights | LIVE:14; range live/template.html:94 | LIVE | Y (0.2 to 1.5, default 1.00) |
| hover gap derived | (portalK - 1) * eye half-height | face units | LIVE:278 | LIVE | n/a (ruling 27c: no hover setting; this is the readout only) |
| EYEB EYE_W / EYE_H / EYE_GAP | 38 / 110 / 36 | px | EYEB:25 | EYEB | not Canon (see conflicts C9) |
| EYEB BASE_Y_OFFSET | -6 | px | EYEB:25 | EYEB | - |
| EYEB PORTAL_W / PORTAL_H | 90 / 28 | px (flatten 0.311) | EYEB:26 | EYEB | roughly (0.311 inside ENV) |
| EYEB MAX_OFF | 13 | px (gaze reach) | EYEB:26 | EYEB | - |
| EYEB PORTAL_OFFSET_RATIO | 0.44 | fraction of eye FULL height (= 0.88 half-heights) | EYEB:33 | EYEB | - |
| EYEB comment reference | eye W:H:gap = 121:445:257 (RaBbLE4K.png) | px | EYEB:22-23 | EYEB | - (h:w 3.68, outside LIVE ENV eh) |
| RIG baseline | eye widthToHeight 1:3.1; centre spacing 2.1; portal width 2.7; flatten 0.3; offset 0.93 half-heights; horizontalOffset 0 | eye widths / ratio | entity-rig.json `baseline` | RIG | Y |
| RIG entity.scale | range [0.6, 0.8], default 0.7 | ratio | entity-rig.json `parameters[entity.scale]` | RIG | - |
| ALIVE face scale f | E.s * 0.7 | ratio | ALIVE:324 | ALIVE | - (matches RIG 0.7) |
| infinity flow STREAMS | rho 1.06/1.25/1.48; reach 1.1/1.7/2.4; wd 3/2/1.4; a 1/0.8/0.6 | rho = x portal radius; wd in px | LIVE:191 | LIVE | - |
| infinity gap half-angle GAPA | 0.75 | rad | LIVE:191 | LIVE | Y in kind (gap faces other portal) |
| infinity fade-in | sstep(0.25, 0.8, abs(elev)) | rad | LIVE:265 | LIVE | - |
| infinity under-glow | alpha 0.16, width 12, dash [16,10], dash speed 40*(1+0.3*si) | - | LIVE:210-211 | LIVE | - |

## 2. Rig constants (body frame, moves, roles)

| name | value | unit | file:line | source(s) | Canon? |
|---|---|---|---|---|---|
| bit mask EL/ER/PL/PR | 8 / 4 / 2 / 1 | bits | LIVE:2 | LIVE | - |
| HOME | ER\|PL (cyan side left, left portal on top) | word | LIVE:2 | LIVE | Y (home: cyan left, left portal top, word 0110) |
| FORMS | [Rest (home) = ER\|PL, Mirror = ER\|PR] | table | LIVE:3 | LIVE | N in wording (Canon: four legal rests, two moves reach all; live names only two forms) |
| WORKING (labels for odd words) | 0 cold very sad; 3 odd state; 12 odd state?; 15 angry alarmed | word to label | LIVE:4 | LIVE | - (unreferenced in code) |
| ORDER (live expression set) | ['calm'] only | - | LIVE:7 | LIVE | Y (calm is the only live expression) |
| ZARC (portal depth arc) | 75 | face units | LIVE:14 | LIVE | Y ("about 75 units") |
| DUR_P (portal swap) | 1.45 | s | LIVE:14 | LIVE | Y |
| DUR_S (eye colour spin) | 0.8 | s | LIVE:14 | LIVE | - (Canon names no such move) |
| DUR_B (body turn, yaw/roll/eyes) | 1.4 | s | LIVE:14 | LIVE | - (Canon gives no turn duration) |
| MINO | 0.26 | unused | LIVE:14 | LIVE | - (dead constant, defined never used) |
| GAP | 6 | unused | LIVE:13 | LIVE | - (dead constant, defined never used) |
| swap progress curve m | smoothstep(clamp(dt/DUR_P)) = 3x^2-2x^3 | - | LIVE:50 | LIVE | partial (Canon says smootherstep plateau; it is the plateau pk below, the clock m is smoothstep) |
| swap eye-gone plateau pq | clamp(sin(pi*m) * 1.6, 0, 1) | - | LIVE:50 | LIVE | - |
| swap pk | smootherstep(pq) = pq^3 (pq(6pq-15)+10) | - | LIVE:50 | LIVE | Y (smootherstep) |
| swap z arc | ZARC * pk, signed by role | face units | LIVE:50 | LIVE | Y |
| swap eye squash | bs = (1 - 0.95*blink) * (1 - pk): squash to 0 at plateau (eye ry = 0.03 floor in Canon of Pocket text; code uses bs product, no 3% constant) | ratio | LIVE:55 | LIVE | partial (Canon prose only; "3%" appears in a code comment only as Pocket's value, LIVE:49) |
| swap eye width bulge | erx = W/2 * sx * (1 + 0.18 * pk) | ratio | LIVE:60 | LIVE | - |
| swap ghost trail | 3 ghosts at dt 0.05*gi, alpha 0.13*(4-gi)/3, gi = 1..3 | s / alpha | LIVE:261-263 | LIVE | - |
| swap motion stretch | v = deltaY/0.03 s; st = 1 + min(0.22, abs(v)/3500); sy*=sqrt(st), sx/=sqrt(st) | ratio | LIVE:115 | LIVE | - |
| eye-colour spin curve | fe = clamp(dt/DUR_S); bit flips at fe 0.5; colour = mixHex(poles, smoothstep(fe)) | - | LIVE:60 | LIVE | - |
| turn angle | PI * smoothstep(f); flips word at f 0.5 | rad | LIVE:242 | LIVE | Y (half-turn about centre axis) |
| turn eye ease | smoothstep (3x^2-2x^3) over DUR_B | - | LIVE:242 | LIVE | - |
| role pose blend smoothing | k = 1 - exp(-dt/0.25) | tau 0.25 s | LIVE:247 | LIVE | - |
| float (eye and portal, both sides) | 12 * sin(1.05 t) | face units, rad/s | LIVE:54 | LIVE; RIG `entity.float` idle 12*sin(1.05t) range +-14 | - |
| blink (LIVE) | cycle 4.2 s; bump 0.16 s sine; every 3rd cycle double with 2nd bump 0.24 to 0.40 s | s | LIVE:41 | LIVE | - |
| blink squash | bs = 1 - 0.95 * blink | ratio | LIVE:55 | LIVE | Y in kind (squash toward portal) |
| eye pulse (glow) | 0.92 + 0.08*sin(2.6 t + 1.7 s) | ratio | LIVE:171 | LIVE | - |
| roll/tilt of whole canvas | tiltNow() deg (HEAD table) | deg | LIVE:255 | LIVE | - |
| portal rim far/near alpha, width | far alpha lerp(1,0.6,persp), width lerp(3.2,1.9,persp); near width lerp(3.2,4.4,persp); shadowBlur far 6 / near 16 | px | LIVE:132, 142, 185 | LIVE | - |
| void fill | rgba(0,0,0,0.9) | alpha | LIVE:140 | LIVE | - (literal black, not a palette name) |
| eye fill | '#f8faff' literal; shadowBlur 30*pulse*f; catchlights: ellipse (-0.32A, -0.46B, 0.2A x 0.12B, rot -0.25) alpha 0.95, (0.26A, 0.52B, 0.1A x 0.05B, rot 0.3) alpha 0.55; outline width 2*f | - | LIVE:173-178 | LIVE | - (hex equals RIG palette eyeFill) |
| no-touch gap sampling | 48 pts per ellipse; portal-portal dv threshold 3 | units | LIVE:219-228 | LIVE | - |
| render scale | sc = min(Wd/700, Hd/620) | ratio | LIVE:253 | LIVE | - |

## 3. Camera, perspective, tilt

| name | value | unit | file:line | source(s) | Canon? |
|---|---|---|---|---|---|
| elevation default / range | 17 / [-90, +90] | deg | live/template.html:92 | LIVE | Y (-90 to +90; default 17 is new) |
| persp | smoothstep(min(1, abs(e)/0.4)); full at 0.4 rad = 22.9 deg | rad | LIVE:252 | LIVE | Y (persp = smoothstep(abs(e)/0.4), about 23 deg) |
| CAMD (perspective distance) | 800 | face units | LIVE:74 | LIVE | - |
| perspective factor | f = 1 / (1 - persp*Z/CAMD) | - | LIVE:76 | LIVE | - |
| ortho mode | persp 0, e 0, tilt 0 | - | LIVE:252, 95 | LIVE | Y (0 deg = 2D reference) |
| EPS0 | 0.283 | rad | LIVE:94 | LIVE | Y |
| EPSK | 0.16 | rad | LIVE:94 | LIVE | Y |
| eps(e) | (a + EPS0 + sqrt((a-EPS0)^2 + EPSK^2)) / 2, a = abs(e); tau = eps - e | rad | LIVE:95 | LIVE | Y |
| opening at e=0 | sin(eps(0)) ~ 0.30 | ratio | LIVE:94 comment | LIVE | Y (flatten 0.30) |
| sight-line correction | tau -= atan2(c.y/c.f, CAMD - c.z) * persp | rad | LIVE:101 | LIVE | Y ("less each portal's own sight-line angle") |
| rim polygon | n = 72 points | count | LIVE:98 | LIVE | - |
| top-down blend `top` | sstep(0.6, 1.2, abs(e)); 0.6 rad = 34.4 deg, 1.2 rad = 68.8 deg | rad | LIVE:108 | LIVE | partial (Canon "about 29 to 69") |
| top-down shrink `tf` | sstep(0.5, 1.05, abs(e)); 0.5 rad = 28.6 deg, 1.05 rad = 60.2 deg | rad | LIVE:111 | LIVE | partial (Canon's 29 comes from this, 69 from `top`) |
| eye fit to ring | fit = min(1, 0.74 * ringHeight / (2*hh)); sx = min(1, fit*1.25) | ratio | LIVE:110, 112 | LIVE | Y (74%) |
| eye settle into ring | lerp(eye centre, ring centre, top) | - | LIVE:112 | LIVE | Y |
| top swallow shorten | active when top > 0.5: sy *= 1 - hid*top | ratio | LIVE:114 | LIVE | - |
| top squash | tv = sstep(0.25, 1.0, abs(e)); qs = lerp(1, max(0.02, bsq), tv) | rad | LIVE:116 | LIVE | - |
| draw order key | far to near by rim centre z: order = Ls[0].z <= Ls[1].z ? [0,1] : [1,0] | - | LIVE:260 | LIVE | Y |
| ALIVE 2D pinhole | el 0.02 rad (1.15 deg), D 1700 | rad / units | ALIVE:387 | ALIVE | N in value (camera model differs from LIVE, see C3) |
| ALIVE 3D camera | PerspectiveCamera fov 42, near 1, far 40000; tv = tan(21 deg); base dist 1800 then fit-scaled; az = 0.32*sin(0.06 t) + uaz; el = 0.02 + 0.04*sin(0.045 t) + uel | deg / rad | ALIVE:854, 944, 953-954 | ALIVE | - (a decorative aura camera, not the unified view) |
| ALIVE viewBox / origin | 1600 x 900, origin (800, 450); cam.vw by aspect 1600/1300/1150/1000; very wide keeps vh >= 720 | units | ALIVE:172-173; RIG viewBox | ALIVE, RIG | - |
| ALIVE ENTITY_H | 760 | world units | ALIVE:189 | ALIVE | - |
| ALIVE finalS | base 1 (1.35 portrait) * clamp(room/(760*base), 0.55, 1) | ratio | ALIVE:190 | ALIVE | - |
| ALIVE boot place | landscape {x: 800 - vw*0.24, y 450, s 0.8, w 0.45}; portrait {x 800, y 450 - vh*0.17, s 0.82, w 0.62} | - | ALIVE:191 | ALIVE | - |
| ALIVE dprCap | 2 (GL) / 3 (2D); renderer pixel ratio min(dpr, cap, 2.5) | ratio | ALIVE:168, 945 | ALIVE | - (World canvas perf rule: DPR cap) |

## 4. Swallow cut

| name | value | unit | file:line | source(s) | Canon? |
|---|---|---|---|---|---|
| portal Y default / range | 1.00 / [0.2, 1.5] | eye half-heights | LIVE:14; template.html:94 | LIVE | Y |
| hid (swallowed fraction) | upper role: clamp((py - (eyN - ery0)) / (2*ery0)); lower: clamp(((eyN+ery0) - py) / (2*ery0)); off when pk >= 0.001 | ratio | LIVE:57 | LIVE | Y in kind |
| dn (signed depth) | (eyN - py)/ery0 (upper) or (py - eyN)/ery0 (lower) | ratio | LIVE:57 | LIVE | - |
| dissolve field | alpha *= smoothstep(sd / span), sd = sg*(p.y - cutY) + dome h | - | LIVE:160-161 | LIVE | Y (smoothstep(sd/span), dome) |
| span | max(14, min(60, (RM - 30) * 0.22)); RM = max(A, B) + 30 | px | LIVE:149 | LIVE | Y in kind (Canon gives no number) |
| dome cutRx | sqrt(cov xx) * sx * sqrt(max(0, 1 - dyc^2)) + 0.6 | px | LIVE:119 | LIVE | - |
| dome cutRy | cutRx * max(0.2, abs(sin(e))) | px | LIVE:119 | LIVE | - |
| dome off-state | cut applies only when hid > 0.003 and top < 0.5 | - | LIVE:147 | LIVE | - |
| hide threshold | eye.ry < 1.2 or hid > 0.985 or A*B < 2 | - | LIVE:120 | LIVE | - |

## 5. Colour model

| name | value | unit | file:line | source(s) | Canon? |
|---|---|---|---|---|---|
| POLE[0] / POLE[1] | '#00f5ff' / '#ff2d78' (palette Electric Cyan / Hot Magenta; literals in LIVE, token names in RIG identity: --rabble-cyan, --rabble-magenta) | hex | LIVE:13; RIG `palette.poleA/poleB`, `identity.poles` | LIVE, RIG | Y (cyan left, magenta right) |
| ALIVE poles | PAL.cyan / PAL.magenta read from Aether tokens at mount (fallback #00f5ff / #ff2d78 in CSS); poleL = C.a, poleR = C.b | token | ALIVE:154, 156; CSS fallbacks ALIVE:35, 47, 54 | ALIVE | Y for values; N for the colour model, see C4 |
| blend half-width B | 96 | face units each side of x = 0 | LIVE:28 | LIVE | Y |
| blend curve | t = smoothstep((x + B) / (2B)) | - | LIVE:28 | LIVE | Y |
| hue path | short way round: dh = ((HM[0] - HC[0] + 540) % 360) - 180; S and L lerped between the two poles' HSL | - | LIVE:27-28 | LIVE | Y (short way through violet) |
| colour sample x | E.x * cos(yawE) (the eye's centre, not each part) | face units | LIVE:120 | LIVE | partial ("parts take colour from where they are"; code samples the eye and shares it to its portal) |
| eye colour spin | mixHex(POLE a, POLE b, smoothstep(fe)), DUR_S 0.8 s | - | LIVE:60 | LIVE | - |
| infinity gradient | linear gradient between portal x, stops 0.3 and 0.7 with each side's colour | - | LIVE:208 | LIVE | - |
| RIG palette | poleA #00f5ff, poleB #ff2d78, violet #bf5fff, outrunPink #ff79c6, void #0a0010, deepestVoid #0a0010, voidGlow #1a0030, eyeFill #f8faff, nebula 8 entries | hex | entity-rig.json `palette` (source: Palette.md) | RIG | - |
| ALIVE other colours | violet, pink, bg (void/deep), surface (glow), text (eye) from Aether tokens via readPalette; fallbacks bg #0a0010, text #e8e6f0, violet #bf5fff, border #2a2840, muted #6b6880, red #e05c6f | token | ALIVE:154; CSS lines 29-55 | ALIVE | - |

## 6. Forms and rests

| name | value | file:line | source(s) | Canon? |
|---|---|---|---|---|
| Rest (home) | word ER\|PL = 0b0110 | LIVE:2-3 | LIVE | Y (interior word 0110) |
| Mirror | word ER\|PR = 0b0101 | LIVE:3 | LIVE | N (Canon: four legal rests; LIVE lists two) |
| other two rests | reached by Turn (flips PL and PR, eyes trade places) | LIVE:292, 296 | LIVE | Y (Canon names them but the table does not) |
| portal swap | flipPortal(sd): toggles that side's portal bit, 1.45 s | LIVE:288 | LIVE | Y |
| eye colour spin | spinEye(sd): toggles that side's eye bit, 0.8 s | LIVE:289 | LIVE | - (Canon retired pole swap as a state) |
| turn kinds | 'yaw' (portals + eyes), 'eyes', 'roll'; mask PL\|PR for yaw | LIVE:251, 290, 296 | LIVE | partial (Canon has only turn) |
| ALIVE portalSide hysteresis | portal switches above/below its eye only when |rel| > 24 | face units | ALIVE:350 | ALIVE | - |

## 7. Expression and pose parameters

Expression numbers are in the SOURCE `EXPR` table in ALIVE and in role-relative form in POSES (LIVE reads POSES; only `calm` is active, LIVE:7). Eye keys are dx, dy (face units), rot (deg, mirrored by side), sx, sy (ratios). Limits LIM (ALIVE:204): eye dx [-34,34], dy [-60,60], rot [-20,20], sx [0.78,1.22], sy [0.3,1.22]; portal dx [-40,40], dy [-270,270], rot [-22,22], sx [0.78,1.25], sy [0.6,1.4].

| expression | eye | portal | tilt (deg) | gaze scale | file:line | source(s) | Canon? |
|---|---|---|---|---|---|---|---|
| calm | all identity (0,0,0,1,1) | identity | 0 | 1 | ALIVE:210; POSES calm | ALIVE, POSES | Y (only live expression) |
| joy | L {dy -6, sy 0.86, sx 1.05, rot -6}, R {same, rot +6} | pL {dy -20, rot -8, sx 1.06}, pR {dy -56, rot 8, sx 1.08} | 2 | 0.95 | ALIVE:211; LIVE:6 HEAD | ALIVE, POSES (role-converted), LIVE HEAD | Y ("parked seed, not canon") |
| sad | eL {dy 14, sy 0.9, rot 7, sx 0.96}, eR {dy 18, rot -7} | pL {dy 12, rot 10, sx 0.96}, pR {dy -12, rot -6, sx 0.97} | -4 | 0.7 | ALIVE:212; LIVE:6 | same | same |
| angry | eL {dy 4, sy 0.86, rot -6, sx 1.03}, eR {dy -4, rot 6} | pL {dy 40, rot -12, sx 1.08, dx 8}, pR {dy -40, rot 12, sx 1.08, dx -8} | 0 | 1.1 | ALIVE:213; LIVE:6 | same | same |
| listening (retired +-252) | sy 1.04 | pL dy +252, pR dy -252 | 0 | 1.2 | ALIVE:214; POSES listening | ALIVE, POSES | Y (Canon: retired) |
| listening_spread_pocket | sy 1.04 | dy -40/+40, sx 1.1 | 0 | - | POSES listening_spread_pocket; LIVE:5 LABEL, HEAD 0 | POSES, LIVE | - |
| speaking | identity | pL dy -44, pR dy +44, sx 1.05 | 0 | 0.8 | ALIVE:215; POSES speaking | ALIVE, POSES | Y (parked seed) |
| spring stiffness | calm 50, joy 70, sad 35, angry 90, listening 55, speaking 80 | k | ALIVE:220-223, 238 | ALIVE | - |
| spring damping | c = 2*sqrt(k)*0.72 | - | ALIVE:242 | ALIVE | - |
| head tilt spring | k 40, damping 2*sqrt(40)*0.8 | - | ALIVE:244 | ALIVE | - |
| style (calm) | energy .05, glow .5, tempo .8, bounce 0, hop 0, trem 0, gazeY 0, orbit .7, sphere 0, lens 1, jit 1, pulse .8, strike .6, surf .7, grav 0, bpm 46, sparkle 0, sigh 0, dim 1 | - | ALIVE:220 | ALIVE | - |
| style (joy) | energy .3, glow .8, tempo 1.2, bounce 6, hop .8, gazeY -3, orbit 1.5, sphere .06, lens 1.04, jit 1.1, pulse 1.6, strike .9, surf 1.2, grav -4, bpm 70, sparkle .6, dim 1.08 | - | ALIVE:221 | ALIVE | - |
| style (sad) | energy .02, glow .4, tempo .6, gazeY 6, orbit .45, sphere -.04, lens .92, jit .7, pulse .5, strike .3, surf .45, grav 18, bpm 42, sigh 1, dim .82 | - | ALIVE:222 | ALIVE | - |
| style (angry) | energy .45, glow .85, tempo 1.2, trem .5, orbit 1.6, sphere .14, lens 1.05, jit 1.8, pulse 1.8, strike 2, surf 1.8, bpm 84, dim 1.04 | - | ALIVE:223 | ALIVE | - |
| style smoothing | k = 1 - 0.08^dt | - | ALIVE:226 | ALIVE | - |
| MOOD_FX (squint, gx, gy, dart, pulse, spin, tilt) | idle 0,0,0,0,1,0,0; ponder .22,14,-9,0,.6,-.06,5; process .08,0,2,1,2.6,.2,0; insight 0,0,-4,0,3,.3,0; curious 0,0,0,0,1.2,.05,0 | - | ALIVE:122-128 | ALIVE | curious: Canon says descriptor not state (ALIVE still lists it as a mood) |
| MOOD_DUR | idle [4,8], ponder [5,9], process [3,5], insight [2.8,2.8] | s | ALIVE:129 | ALIVE | - |
| RIG mood durations | idle 4 to 8; ponder 5 to 9 (look +-14..22, -7..11, tilt +-3..6); process 3 to 5 (arousal .75, pulseRate 3); insight 2.8; curious 2.5 | s | entity-rig-demo.html:507-515 | RIG demo | - |
| RIG states | idle portal.flip 0 / spread 1; listening flip 1; speaking spread 1.35 | - | entity-rig.json `states` | RIG | - |
| RIG squint / widen | squint scaleY -= 0.45*v; widen scaleY += 0.14*v, scaleX += 0.06*v | - | entity-rig.json parameters | RIG | - |
| ALIVE widen | ry * (1 + 0.12*widen), rx * (1 + 0.05*widen); decays 0.15^dt | - | ALIVE:343-344, 814 | ALIVE | - |
| ALIVE talk | talk = (0.5 + 0.5*noise(9t)) * 0.35; eye ry * (1 - talk*0.4*(1 for left, 0.7 for right)) | - | ALIVE:326, 343 | ALIVE | - |
| ALIVE mood squint | 1 - squint * (1 for owning side, 0.35 other) | - | ALIVE:343 | ALIVE | - |
| ALIVE lonely | sad after 45 s without interaction; interact() gives joy 3.5 s | s | ALIVE:314, 319 | ALIVE | - |
| ALIVE autonomous expression | next in rnd(6, 11) s; pick joy 60% / sad 25% / angry 15%; hold rnd(3, 6) s | s | ALIVE:316-317 | ALIVE | - |
| ALIVE sigh | duration 1.8 s, sine bump; eye y +4*sigh; body y +8, sx +0.015, sy -0.025 | - | ALIVE:228, 342, 602-603 | ALIVE | - |
| ALIVE body bounce | hop = -|sin(2pi*ltime*hop)|*bounce (bounce > .3); squash cos(2*ph)*.04*(bounce/14) | - | ALIVE:602 | ALIVE | - |

## 8. Idle motion

| name | value | unit | file:line | source(s) | Canon? |
|---|---|---|---|---|---|
| LIVE float | 12 * sin(1.05 t), same phase for both sides, eye and portal | face units | LIVE:54 | LIVE | - |
| LIVE blink | 4.2 s cycle, 0.16 s bump; 3rd cycle doubles (2nd bump 0.24 to 0.40 s) | s | LIVE:41 | LIVE | - |
| ALIVE blink interval | next = time + rnd(2, 7) / (1 + energy) / (0.7 if sad else 1) | s | ALIVE:804 | ALIVE | - |
| ALIVE blink length | single 0.22 s (bump over first 0.16), double 0.46 s (2nd bump 0.24 to 0.40); 30% doubles | s | ALIVE:250, 803-804 | ALIVE | - |
| ALIVE blink shape | ry * (1 - 0.95*b); rx * (1 + 0.22*b); right eye lags 0.04 s | ratio | ALIVE:253, 343-344 | ALIVE; RIG blink params (1-0.95v, 1+0.22v, right lags 40 ms) | - |
| ALIVE boot blink burst | 5 blinks, 0.1 s each, gaps start 0.06 s, x1.55 each, right eye lag 0.025 s | s | ALIVE:254-258 | ALIVE | - |
| ALIVE breathe | eye ry * (1 + 0.02*sin(1.25 ltime)) | ratio | ALIVE:330 | ALIVE | - |
| RIG breathe | entity.breathe range 0.98 to 1.05; + heartbeat*0.008; demo eye .025*sin(1.3t + .6 for R) | ratio | entity-rig.json; entity-rig-demo.html:643 | RIG | - |
| ALIVE portal bob | (sd<0 ? -1 : +1) * 8 * sin(1.4 ltime + (0 or 1.1)) * (1 + 0.6*energy) | face units | ALIVE:338 | ALIVE | - |
| RIG portal bob | top -9*sin(1.57 t), bottom +9*sin(1.57 t), range +-16 | px | entity-rig.json | RIG | - |
| ALIVE eye jitter | eye dx 2.5*fbm, dy 3*fbm, rot 1.2*fbm; portal dx 3, dy 4, rot 1.6 (n = 0.5 ltime + 37 for right) | units / deg | ALIVE:334-337 | ALIVE | - |
| ALIVE gaze limits | gx [-26, 26], gy [-12, 12] (pointer: dx*0.06, dy*0.05) | face units | ALIVE:810 | ALIVE; RIG eye.gaze +-26 / +-12 | - |
| ALIVE gaze idle target | tx = 18*fbm(0.2t + 11) + mood gx; ty = 7*fbm(0.25t + 33) + mood gy; stiff 40 + dart*120 | face units | ALIVE:811 | ALIVE | - |
| ALIVE gaze spring | damping 2*sqrt(stiff)*0.72; pointer stiff 110; glance stiff 260 | - | ALIVE:808-813 | ALIVE | - |
| ALIVE saccade (micro) | micro (+-4, +-2) * (1 + 3*dart); next rnd(0.6, 2.2) s, or rnd(0.12, 0.4) s when darting | s | ALIVE:812 | ALIVE | - |
| ALIVE pointer attention | active if last move < 2.5 s ago; attn glance 26 / 12 units for rnd(0.5, 0.9) s | s | ALIVE:808, 810, 308 | ALIVE | - |
| ALIVE portal-follows-gaze | portal x += gaze * 0.25 | ratio | ALIVE:348 | ALIVE | - |
| ALIVE heartbeat | phase += dt*(bpm + 20*energy)/60; beats at p 0.05 (width .035) and 0.24 (.6 amp, width .04); bpm calm 46 | - | ALIVE:820 | ALIVE | - |
| ALIVE sphere yaw | target max(0.02, 0.1 + 0.09*fbm + 0.45*energy + sty.sphere + mood.spin), smoothing 1 - 0.25^dt | rad/s | ALIVE:443 | ALIVE | - (aura, not entity) |
| EYEB saccade pool | 19 targets; hard (4): (+-.95,0), (0,+-.85); med (4): (+-.75, +.65 or -.55); soft (11 incl. 3x(0,0)); fractions of MAX_OFF 13 | - | EYEB:42-48 | EYEB | - |
| EYEB hold / gap by class | hard hold 25 to 60 f, gap 8 to 26 f; med hold 45 to 100, gap 20 to 60; soft hold 65 to 145, gap 40 to 110; chaotic hold 8 to 20, gap 2 to 8 | frames @60 | EYEB:197-198 | EYEB | - |
| EYEB spring / damping | spring 0.12 (x1.167 near mouse, x0.833 otherwise), damping 0.72 | - | EYEB:64-65, 242 | EYEB | - |
| EYEB jolt / snap decay | 0.94 / 0.92 per frame | - | EYEB:60-61 | EYEB | - |
| EYEB drift | d1 = (sin(.019t)*2.6 + sin(.043t)*1.1, cos(.015t)*1.8 + cos(.037t)*.9); tremor (sin(.11t)*.35 + sin(.17t)*.2, cos(.09t)*.25 + cos(.21t)*.15) | px | EYEB:218-221 | EYEB | - |
| EYEB distraction | every 120 + rand(0..180) f; reach 0.45 to 1.0; y scale 0.72; return after 55 to 160 f; spring 0.018/0.026, damping 0.9 | frames | EYEB:88, 206-216 | EYEB | - |
| EYEB mouse | near within 600 px; gaze weight 0.48, saccade weight 0.42, y scale 0.65, distance norm 220 px | px | EYEB:35, 234-236 | EYEB | - |
| EYEB blink FSM | normal blink phase += 0.20 per frame (~5 f cycle), burst phase += 0.52; next = interval 100 + rand(0..150) f; burst gap 8 f x1.55 + rand(0..8); burst total and delays come from boot-sequence (not read) | frames | EYEB:68-75, 262-281 | EYEB | - |

## 9. Source-only auxiliary constants (not entity-defining; listed so nothing is missed)

- alive-gl.js: no entity constants. LUT 256 x 64, FLOATS 11, mediump shaders, GL context opts (alpha false, antialias false, powerPreference high-performance). Only relevance: the face is drawn on an offscreen Canvas2D and uploaded as a texture (ALIVE:164, 611-618).
- ALIVE boot timeline BOOT (ALIVE:196-197), seconds: grid [0,1.6], motes [0,2.8], sphere [.9,2.3], portalArc [.4,3.4], eyeRise [1.8,4.2], blinks 4.25, mesh [2.2,4.2], lens [2.9,3.9], orbit [3.0,4.1], bokeh [1.4,3.2], logStart .7, logEnd 7.0, ready 7.4, slide [7.6,9.8], shock 9.6, idle 10.2. Eye rise end scale: erx lerp(.85,1), ry lerp(.02,1, op^2*(1.6-.6op)) (ALIVE:347). Portal arc stroke width 6, halo 26/48 (ALIVE:574-578).
- ALIVE aura geometry (ALIVE:266-283): mesh layers [8,140,320,.66,40],[7,300,450,.54,34],[6,430,575,.44,26]; bokeh 120, motes 150, embers 46, sparks 160, flashes 10, rings 8, bolts 10; orb radius 265; grid GAP 240, WELL {A 150, SX 640, SZ 520}, RAY 340, ROW 400. Haze ellipses (ALIVE:423): L (-170,0,450,382,.34), R (170,0,460,390,.26), violet (0,0,320,272,.3), (0,0,380,380,.12).
- Portal dashed ring (ALIVE:579): dash [30,30], speed 80 + 320*energy, alpha 0.7, width 2, inner inset (13, 7). RIG `portal.spin` idle -80 t.
- ALIVE occlusion clip uses 3 px inset on the rim (ALIVE:586), 6000 px clip half-extent, stroke width 6 triple (alphas .12, .3, 1; widths x3.7, x2.2, x1).

## 10. Conflicts

### Between live.js (LIVE) and alive-backend.js (ALIVE)

- **C1. Mechanics missing in ALIVE.** ALIVE has no tilt, swallow cut, turn, portal swap or withdraw, elevation/persp blend, top-down fit, or portalK. Its "swap" is only an above/below flag with +-24 hysteresis (ALIVE:350). Anything the registry stores for those moves has exactly one source: LIVE.
- **C2. Draw order and occlusion.** LIVE: portals far to near, then every eye, then a lower-role portal's near rim clipped to its own eye (LIVE:183-188). ALIVE: all portals, then each eye clipped by its own portal half-plane (above-portal vs below-portal clip, ALIVE:582-593), then front rim for the below portal. Different rules, and Canon says Pocket's occlusion is the reference and the rig-vs-Pocket comparison is still owed (Canon 9.7).
- **C3. Camera.** LIVE: CAMD 800, elevation 17 deg default, range +-90, persp 0 to 1 by smoothstep(|e|/0.4). ALIVE 2D: pinhole el 0.02 rad, D 1700 for the grid only (face is flat, decal). ALIVE 3D: fov 42, base dist 1800, el 0.02 + 0.04 sin, az drift 0.32 rad, always-facing decal. No shared camera constant.
- **C4. Colour model.** LIVE: position volume, `volCol(x)` blend 96 units, hue through violet. ALIVE: fixed poleL/poleR; Aether tokens, no blend. Canon 3 says poles are never swapped as a state; ALIVE `setPortals()` recolors poles (ALIVE header), LIVE spins an eye's colour bit over 0.8 s (LIVE:60, 289), which sits between those.
- **C5. Eye fill and void.** LIVE: eye fill literal `#f8faff` (LIVE:173) and void fill rgba(0,0,0,.9) (LIVE:140). ALIVE: eye = PAL.text (fallback #e8e6f0, ALIVE:154, 29), void/deep = PAL.bg (#0a0010). RIG palette: eyeFill #f8faff, void #0a0010. The registry needs one palette name per role; `#f8faff` is not in the CSS fallbacks, so check Palette.md before committing it (not verified here).
- **C6. Blink.** LIVE: fixed 4.2 s cycle, squash only (ery), no width gain, plus the whole eye cut by `pk` in swaps. ALIVE: random 2 to 7 s interval modified by energy and sadness, 30% double blinks, width gain +22%, right eye lag 0.04 s. RIG matches ALIVE (1 + 0.22v). Canon: blink is "the same squash toward the portal", no width numbers.
- **C7. Float, bob and breathing.** LIVE: 12*sin(1.05t) shared by eye and portal both sides. ALIVE: portals bob +-8 amplitude, sin(1.4 ltime) with 1.1 rad phase offset between sides, opposite sign, scaled by energy, eyes jitter by fbm, ry breathes 2% at 1.25 rad/s. RIG json: float 12 sin(1.05t) on the body and portal bob 9 sin(1.57t) opposed; demo breathes 2.5% at 1.3 rad/s. Three idle models.
- **C8. Expressions.** Pose numbers agree between ALIVE `EXPR` and POSES (checked for joy, sad, angry, speaking, listening). Differences: ALIVE still ships `listening` at +-252 (Canon: retired) and `curious` as a mood (Canon: descriptor, not a state). LIVE exposes only `calm` (LIVE:7).
- **C9. Eye proportions across sources.** LIVE `reference` 3.13 / 2.11 / 2.69 / 0.30 matches ALIVE's 87x272, 184, 234x70 within 0.5%. EYEB uses a different set: eye 38x110 (h:w 2.89), centre spacing 74 (1.95 widths), portal 90x28 (pw 2.37, flatten 0.311), offset 0.44 of full height (0.88 half-heights), and cites a reference of 121:445:257 (h:w 3.68, outside LIVE ENV eh [2.5, 3.2]). Its sp 1.95 equals the LIVE `pocket` preset's sp; its eh 2.89 differs from the `pocket` preset's eh 2.64. EYEB is not imported by ALIVE.

### Between either and the Canon

- **C10. Forms.** Canon: four legal rests, two moves reach all four. LIVE:3 names only Rest and Mirror (Canon 9.1 already flags this as wording to settle). ALIVE has no forms at all.
- **C11. Swap timing and curve.** Canon 1.45 s agrees with LIVE `DUR_P`. Canon says "smootherstep plateau"; in code the progress clock is smoothstep, with smootherstep applied only to the eye-gone plateau `pk` of `sin(pi*m)*1.6`. Canon does not state the 1.6 factor. "Eye squashes toward 3%": the 3% appears only in a LIVE:49 comment about Pocket scene.c; the code squashes by `bs = (1 - 0.95*blink)*(1 - pk)` which goes to 0, not 0.03.
- **C12. Top-down range.** Canon says tilt "from about 29 to 69 degrees". Code has two smoothsteps: `tf` 28.6 to 60.2 deg and `top` 34.4 to 68.8 deg. The registry should store the two ranges (0.5 to 1.05 rad and 0.6 to 1.2 rad), not one.
- **C13. Colour sample.** Canon: "parts take their colour from where they are". LIVE samples one x (the eye centre, cos-yawed) per side and gives that colour to its portal and infinity stroke, so a portal's colour is tied to its eye.
- **C14. Constants with no Canon number.** Turn duration 1.4 s, eye colour spin 0.8 s, 0.25 s role-pose smoothing, CAMD 800, default elevation 17 deg, ENV ranges, `pocket` preset, 72-point rim, swallow `span` formula, ghost trail, motion stretch, role-pose blend. All are new registry fields with LIVE as the only source.
- **C15. Dead constants.** `GAP = 6` and `MINO = 0.26` (LIVE:13-14) are defined but not used; `WORKING` (LIVE:4) is a label table with no consumer. Do not carry them into the registry without a reason.
- **C16. Portal Y.** Canon default 1.00 and range 0.2 to 1.5 agree with LIVE. The superseded 1.04 default and -0.6 to 1.5 range (Canon 8) are absent from both files. The spec's slider default and range come from live/template.html:94, not live.js.
- **C17. Stale registry-spike.** `registry/entity/` does not exist yet. `registry-spike/` holds gen.py and poses.role.json; only poses.role.json was inspected here. Canon 9.3 notes the spec's sample registry is stale (0.7 s transition, 0.97 withdraw), which this extraction confirms is superseded by DUR_P 1.45.

### Not found in the named sources

- No persp blend, tilt or swallow constants exist in ALIVE, alive-gl.js, EYEB or RIG. RIG `zOrderRule` and `occlusion` are text rules (portal above or below its eye), with no numbers.
- Eye width/height "ranges" beyond ENV are not stated anywhere. Portal rx/ry range: ENV pw [1.9, 2.8] eye widths and ENV fl [0.22, 0.33].
- A pose table for `pocket` exists only as a proportion preset (LIVE:10), not as an expression or rest pose.
