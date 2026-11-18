# Device entity constants (RaBbLE-Pocket) with provenance

Read-only extraction, 2026-11-18. Nothing in Pocket touched.

Abbreviations (paths relative to the Collective root):
- **SC** = `RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c` (the live scene builder, `nl_simulate`)
- **NLL** = `RaBbLE-Pocket/firmware/entities/RaBbLE/nebula_lite/include/nl_list.h`
- **NLH** = `.../nebula_lite/include/nebula_lite.h`
- **RAS** = `.../nebula_lite/src/raster.c`, **CMP** = `.../nebula_lite/src/compose.c`
- **ENT** = `.../src/rabble_entity.c` (feeds `nl_inputs_t`), **UI** = `.../src/rabble_ui.c`
- **EF** = `.../src/entity_face.h` (LEGACY LVGL path, see section 7)
- **MOCK** = `RaBbLE-Pocket/planning/mock/rabble-pocket-entity.html`
- **CANON** = `RaBbLE-Grimoire/log/plans/Unified-Entity/Unified-Entity-Canon.md`

"Agrees with Canon?": Y / N / n/a (Canon silent or not applicable on a flat 2D device) / ? (needs a ruling).
Pixel units: device px on the 466 px stage; "NeBuLA units" = px / 0.42.

Important framing: the device is a flat 2D ellipse renderer. It has no camera, no elevation, no perspective, no portal tilt (EPS0/EPSK), no yaw turn, no depth arc. Canon section 5 constants have no device counterpart. `nl_roll` is the hardware gravity/upright roll of the whole stage, not the entity's "turn".

---

## 1. Screen and stage geometry

| name | value | unit | file:line | mock equivalent | Canon? |
|---|---|---|---|---|---|
| panel width/height | 466 x 466 | px | NLH:16-17 (`NL_W`,`NL_H`) | MOCK:659 clip circle r=233, viewBox 466 (692) | n/a |
| stage centre X (`C_X`) | 233 | px | SC:18 | MOCK:38 `C = 233` | n/a |
| face centre Y (`LY`) | 240 | px | SC:19 | MOCK:38 `LY = 240` | n/a |
| round clip radius | 233 | px | (panel is round; scene is not clipped in code) | MOCK:659 | n/a |
| NeBuLA units to px (`S`) | 0.42 | scale | SC:22 | MOCK:42 | n/a |
| emotion travel (`EX`) | 0.6 | scale | SC:23 | MOCK:43 | n/a |
| loop length (`LOOP`) | 16 | s | SC:20 | MOCK:39 | n/a |
| face rotation pivot | (C_X, LY) = (233, 240) | px | SC:714-716 | MOCK:150-151 `rot2(...,C,LY)` | n/a |
| stage turn pivot (hardware roll) | panel centre (233, 233) | px | SC:56-62 (`tx`) | MOCK: none (mock has rot for DEVICE preview only, 732) | n/a |
| ring radius / inner / outer | 214 / 206.5 / 221.5 | px | CMP:9-11 | MOCK:524-525 r=214, stroke 3.4 | n/a |
| ring width in mock | 3.4 (core) + 14 (soft) | px | none (device ring is a LUT band 15 px wide) | MOCK:524-525 | n/a |

## 2. Proportions: eyes, portals, spacing, offsets

Eyes are ellipses: semi-axes a=22, b=58, so 44 px wide x 116 px tall (SC:775 `b_ = 58*...`, `a_ = 22*...`). Portals: semi-axes 44 x 11, so 88 x 22 px (SC:725, 772, 780).

| name | value | unit | file:line | mock equivalent | Canon? |
|---|---|---|---|---|---|
| eye semi-width a | 22 | px | SC:775 | MOCK:193 `rx=22` | n/a |
| eye semi-height b | 58 | px | SC:775 | MOCK:193 `ry=58` | n/a (range, ruling 16/18) |
| eye width / height ratio | 44/116 = 0.379 | ratio | derived | same | Y (tall pill, ratio is a range) |
| portal semi-width | 44 (x `psx`) | px | SC:725, 772, 780 | MOCK:170 `rx=44` | n/a |
| portal semi-height | 11 | px | SC:725 | MOCK:170 `ry=11` | n/a |
| portal flatten (ry/rx) | 0.25 | ratio | derived | same | **N**: Canon flatten is 0.30 (0.25 here) |
| portal width / eye width | 88/44 = 2.0 | ratio | derived | same | Y (ring ~2.0 eye widths) |
| portal rim stroke width | 2.6 | px | SC:725, 780 | MOCK:171, ~197 `stroke-width 2.6` | n/a |
| eye base centre L (x,y) | (190, 235) | px | SC:686 | MOCK:142 `['L',-1,190,235,185]` | n/a |
| eye base centre R (x,y) | (276, 239) | px | SC:686 | MOCK:142 | n/a |
| portal base centre L (x,y) | (190, 185) | px | SC:686 (3rd col = portal y) | MOCK:142 | n/a |
| portal base centre R (x,y) | (276, 285) | px | SC:686 | MOCK:142 | n/a |
| portal-to-eye offset L | 50 up (235-185) | px | derived | same | see portal Y below |
| portal-to-eye offset R | 46 down (285-239) | px | derived | same | see portal Y below |
| **portal Y in eye half-heights** | L 50/58 = **0.862**, R 46/58 = **0.793** | eye half-heights | derived | same | **N**: Canon default 1.00 (range 0.2 to 1.5); device is asymmetric and under 1 (eye pokes 8 px / 12 px past its plane before the clip removes it) |
| eye squash anchor | +-58 (the eye end) | px | SC:686 / 720 `orb[s].anchor` | MOCK:154 `anchor: s==='L' ? -58 : 58` | ? (eye end is 58, portal plane is 50/46: the eye collapses toward a point 8/12 px beyond its portal plane) |
| eye horizontal separation | 276-190 = 86 | px | derived | same | n/a |
| eye gap between inner edges | 86-44 = 42 | px | derived | same | n/a |
| portal horizontal separation | 86 | px | derived | same | n/a |
| **portal inner-edge clearance** | 86 - 88 = **-2 px (overlap)** | px | derived (190+44=234 > 276-44=232) | same | **N**: Canon "portals never touch each other"; at rest the two 88 px ellipses overlap by 2 px in x (they sit 100 px apart in y at rest, so the ellipses do not intersect then, but mid-swap they are at the same y, see section 5) |
| hit-test of eye vs other portal at rest | eye L x 168..212, portal R x 232..320: clear | px | derived | same | Y |
| orb white | 0xf8faff (via `NL_WHITE`) | rgb | NLL:31 | MOCK:646 `#fff`/`#f3fbff` stops | ? (palette name "NeBuLA orb white", not in Palette.md) |

Wander and idle offsets (add to the base positions):

| name | value | unit | file:line | mock | Canon? |
|---|---|---|---|---|---|
| eye wander X amplitude | 2.5 x S x 2.2 = 2.31 x nz | px | SC:702 | MOCK:147 | n/a |
| eye wander Y amplitude | 3 x S x 2.2 = 2.77 x nz | px | SC:702 | MOCK:147 | n/a |
| eye wander roll | 1.2 x nz | deg | SC:702, 717 | MOCK:147 | n/a |
| portal wander X | 3 x S x 2 = 2.52 x nz | px | SC:703 | MOCK:148 | n/a |
| portal wander Y | 4 x S x 2 = 3.36 x nz | px | SC:703 | MOCK:148 | n/a |
| portal bob (opposite phase) | kt x 8 x S = 3.36 amplitude, 4 cycles/16 s (4 s period), phase 0 (L) / 1.1 rad (R), kt = -1 L, +1 R | px | SC:703 | MOCK:148 | n/a |
| noise `nz` | 0.6 sin(wk(k)t+a)+0.3 sin(wk(2k+1)t+b)+0.1 sin(wk(5k+2)t+c); wk(k)=TAU k/16; seeds `sd` = 0 (L) / 37 (R) | unitless | SC:41-54 | MOCK:51-56 | n/a |
| rng (LCG) | s = (s x 9301 + 49297) mod 233280 | int | SC:36-38 | MOCK:46 | n/a |
| nz phase seed | `floor(seed x 97) + 13` | int | SC:45 | MOCK:52 | n/a |
| eye hop (joy) | 6 x abs(sin(wk(12) t)) x f.hop | px | SC:682 | MOCK:141 | n/a |
| face tilt rotation | f.tilt (deg) about (233, 240), plus 0.3 x dizzy x sin(10t) rad | deg | SC:683, 714-716 | MOCK:150 | n/a |
| eye squint | sq = 1 - squint x (R: 1, L: 0.35) | scale | SC:704 | MOCK:149 (`sqSide===kt`, sqSide=1) | n/a |
| talk modulation | sx x (1 + 0.1 talk), sy x (1 + 0.12 talk); talk = w_speak x level | scale | SC:718-719 | MOCK:154 | n/a |

## 3. Pose (FACE) table

Parameters are dx, dy (NeBuLA units; applied as EX x value px), rot (deg), sx, sy; face-level tilt (deg), dim, squint, hop. Device blends all weights then normalises (SC:665-668); mock `blendFaces` (MOCK:111-117) is the same normalised blend.

| state | eL | eR | pL | pR | tilt | dim | squint | hop | file:line | mock | Canon? |
|---|---|---|---|---|---|---|---|---|---|---|---|
| calm (idle) | P0 | P0 | P0 | P0 | 0 | 1 | 0 | 0 | SC:125 | MOCK:99 | Y (calm = idle, no emotion) |
| joy | (0,-6,-6,1.05,.86) | (0,-6,6,1.05,.86) | (0,-20,-8,1.06,1) | (0,-56,8,1.08,1) | 2 | 1.1 | 0 | 1 | SC:126 | MOCK:100 (also sparkle:1, device omits) | Y (parked seed, ruling 38) |
| sad | (0,14,7,.96,.9) | (0,18,-7,.96,.9) | (0,12,10,.96,1) | (0,-12,-6,.97,1) | -4 | .78 | 0 | 0 | SC:127 | MOCK:101 | Y (parked seed) |
| listening | (0,0,0,1,1.04) | same | (0,-40,0,1.1,1) | (0,40,0,1.1,1) | 0 (live: 6 x lean) | 1 | 0 | 0 | SC:128, 657-660 | MOCK:103, 121-122 | Y (parked seed). Live: eye dx = 12 cos(mic angle), lean = clamp(normdeg(mic-90), -60, 60)/60 |
| speaking | P0 | P0 | (0,-44,0,1.05,1) | (0,44,0,1.05,1) | 0 | 1 | 0 | 0 | SC:129 | MOCK:104 | ? ruling 10 leaves speaking interior unset |
| ponder | (14,-9,0,1,1) | same | P0 | P0 | 5 | 1 | .22 | 0 | SC:130 | MOCK:105 | n/a (not a Canon state) |
| process | (0,2,0,1,1) | same | P0 | P0 | 0 | 1 | .08 | 0 | SC:131, 662-663 | MOCK:106, 123-124 | n/a. Live: dart x = 9 tanh(5 sin(wk(11)t)), dart y = 2 + 5 tanh(5 sin(wk(7)t+1)) |
| angry | absent on device | | | | | | | | none | MOCK:102 (eL (0,4,-6,1.03,.86), pL dy 40, rot -12, sx 1.08, dx 8; trem 1) | Canon wants angry to exist; device lacks it |
| curious | absent on device | | | | | | | | none | MOCK:107 | Canon: descriptor, not a state: Y |

Device state mapping (SC:613-619): LISTEN -> W_LISTEN; THINK -> W_PONDER while state-age < 1.5 s, then W_PROCESS; SPEAK -> W_SPEAK; ERROR -> W_SAD; default (IDLE/OFF) -> W_CALM. `happy` (0..1) scales all targets by (1-happy) and adds W_JOY = happy (SC:620-622). Weight easing k = 1 - exp(-dt/0.25) (time constant 0.25 s, SC:623). Mock equivalent is a scripted 16 s timeline (MOCK:77-84): listen 0-4, think 4-8 (ponder to process crossfade 5.2-5.8), speak 8-12.5, joy 12.5-15.4, with smoothstep edges of 0.6 s.

Other expression multipliers: dim = f.dim (portal stroke alpha = 0.75+0.25 dim, orb alpha = 0.35+0.65 dim; SC:728, 774; mock opacity min(1,.35+...) MOCK:~192). energy = .25 W_PROCESS + .15 W_SPEAK + .3 W_JOY (SC:672; MOCK:522). Focus look: eye sy x (1 - 0.35 focus), mesh activity x (1 - 0.5 focus) (SC:677-678, 719). Dizzy: eye sy x (1 - 0.3 dizzy abs(sin 9t)), eye x offset 14 dz cos(14t), y 3 dz sin(28t) (SC:710-711, 719). Touch gaze 9 px (SC:305).

## 4. Idle motion, blink, breathing

| name | value | unit | file:line | mock | Canon? |
|---|---|---|---|---|---|
| blink period | 4.2 | s | SC:578 | MOCK:117-127 uses scripted times 2.4, 6.9, 9.3 (double), 14.2 in the 16 s loop | n/a (**mismatch**, section 6) |
| blink duration | 0.16 (half-sine, 0 -> 1 -> 0) | s | SC:579 | MOCK:121 | Y (squash toward portal) |
| double blink | every 3rd period ((int)(t/4.2) % 3 == 2): second dip at p in [0.24, 0.40) | s | SC:580 | MOCK:122 (`one(9.3,true)`) | n/a |
| blink depth | bs = 1 - 0.95 blink, floor 0.03 | scale | SC:773 | MOCK:189 `bs = 1 - .95*b.blink`, floor .03 (~193) | n/a |
| blink squash direction | toward the portal end (anchor), oy = anchor x (1-bs) x sy | px | SC:776-777 | MOCK:~192 translate(anchor) scale translate(-anchor) | Y (not a screen cut) |
| eye breathing / drift | none beyond wander noise (noise period = 16 s fundamental) | | SC:702 | MOCK:147 | n/a |
| portal bob | 4 s period, +-3.36 px | | SC:703 | MOCK:148 | n/a |
| mesh breathe | 1 + 0.14 sin(wk(8) t) (2 s period) | scale | SC:310 | MOCK: meshLayer | n/a |
| mesh node wander | 22, 30, 42 x S x nz; orbit radius (4..14) x S | px | SC:314-320 | MOCK: meshLayer | n/a |
| hysteretic idle (LVGL legacy) | blink period 4.2 s, duration 0.16 s, eye_h 0.08..1; breathing gaze_y = 2 sin(1.3 t) | | UI:58-59, 116-124, 135 | | legacy path |

## 5. Moves

| move | device value | file:line | mock | Canon |
|---|---|---|---|---|
| **withdraw-swap (flip)** duration | **0.7 s** (`FLIP_S`) | ENT:59, 670-676 | **mock has no flip/swap at all** (grep: no `flip`, no `withdraw`) | **N**: Canon 1.45 s |
| swap easing | linear ramp in `dt/0.7`, then smoothstep `fl = fl^2 (3 - 2 fl)` | ENT:673-675, SC:689-690 | n/a | Canon: smootherstep plateau (N: device is smoothstep 3t^2-2t^3, not 6t^5-15t^4+10t^3) |
| swap trigger | `rabble_capture_on()` (Capture mode); fl goes 0 -> 1 and back, exact 0/1 at rest | ENT:669-676 | n/a | n/a |
| portal path in swap | y only: `py = portal_y + (2 eye_y - 2 portal_y) fl` (mirror about the eye); x does not move | SC:712 | n/a | N: Canon slides each portal through its eye "arcing past each other in depth (~75 units)": device has **no depth arc** |
| eye path in swap | eye does not move; it squashes and regrows | SC:773-778 | n/a | Y in spirit (squash into leaving portal, grow from other) |
| withdraw envelope | `withdraw = sin(pi fl)`, peak at fl = 0.5 | SC:692 | n/a | n/a |
| eye scale during swap | `bs = max(0.03, (1 - .95 blink)(1 - .97 withdraw))` on eye height only; eye width a=22 is NOT scaled by withdraw | SC:773, 775 | n/a | ? (Canon says "squashes"; a 44 px wide sliver remains) |
| squash anchor during swap | `anchor = (+-58)(1 - 2 fl)`: starts at the leaving portal's eye end, passes 0 at fl=0.5, ends at the other end (sign flips) | SC:720 | n/a | Y |
| flip bookkeeping | `flipped = fl >= 0.5` (hard switch) | SC:691 | n/a | n/a |
| fresh-start withdraw (new conversation) | `FRESH_S` 0.8 s; same withdraw `sin(pi smoothstep(fr))`, no flip, max-combined with flip's | ENT:58, 677-686; SC:694-698 | n/a | n/a |
| blink | see section 4 | | | Y |
| **turn (yaw half-turn, eyes trade places)** | **none on device** | | none | Canon move not implemented |
| hardware roll (`nl_roll`) | spring-after-gravity "upright", rotates the entire stage about (233,233); not the Canon turn | ENT:436, 629; SC:606-607, 56-62 | MOCK rot param (preview) | n/a |
| orbit/UI slide | `s_slide` px; whole stage moves aside | SC:27-28, 56-67, 635-638 | none | n/a (app UI) |

Canon 36c asks for 1.45 s: the device runs 0.7 s, i.e. about 48% of Canon.

## 6. Boot, OFF, frame timing

| name | value | unit | file:line | mock | Canon? |
|---|---|---|---|---|---|
| boot cyan portal fade-in | 0 to 1 over 0.35 | s | SC:628 (`b/.35`); UI:65 `BOOT_PORTAL_S` | none found | n/a |
| boot magenta portal delay | 0.12 | s | SC:628; UI:66 | none | n/a |
| boot eyes/rest start | 0.67 | s | SC:629; UI:67 `BOOT_EYES_AT_S` | none | n/a |
| boot eyes/rest fade length | 0.25 (ends at 0.92 s) | s | SC:629; UI:68 | none | n/a |
| boot pre-lit | `in->boot < 0` -> everything 0 | | SC:631 | | n/a |
| OFF fade | 1.0 s linear on both portals and rest | s | SC:630 | | n/a |
| LVGL-legacy boot eyes open | eye_h x (0.3 + 0.7 rest) | | UI:244 | | legacy |
| state-weight time constant | 0.25 | s | SC:623 | | n/a |
| THINK ponder to process | 1.5 | s | SC:615 | MOCK:82 (5.2-5.8 of think 4.0 start) | n/a |
| frame rate | 60 fps nominal ("frames are evenly paced"), default dt 1/60 | fps | SC:474, 482, 600 | MOCK:733 "60 fps" (PORT PREVIEW) | n/a |
| dt clamp | [0.001, 0.1] | s | SC:600 | | n/a |
| history | 256 samples, ~4 s at 60 fps | | SC:473 | | n/a |

## 7. Colour

Device draws from `nl_list.h` palette defines (comment: "RaBbLE-Palette.md only", NLL:25-31). Palette.md (RaBbLE-Agent/RaBbLE-Palette.md:31-40) confirms cyan #00f5ff, magenta #ff2d78, violet #bf5fff, Deep Void #0a0010.

| name | value | file:line | mock equivalent | Canon / palette? |
|---|---|---|---|---|
| NL_BG (Deep Void) | 0x0a0010 | NLL:25 | MOCK:11 `#0a0910` page, 661 `#08070c` | Y palette; mock off-palette |
| NL_CYAN (Electric Cyan) | 0x00f5ff | NLL:26 | MOCK:37 `CY = '#3fe6f2'` | **N**: mock cyan is not palette; device is |
| NL_MAGENTA (Hot Magenta) | 0xff2d78 | NLL:27 | MOCK:37 `MG = '#ff3e9d'` | **N**: mock magenta is not palette; device is |
| NL_VIOLET | 0xbf5fff | NLL:28 | MOCK:37 `VI = '#a98bff'` | device Y; mock off-palette |
| NL_TEXT | 0xe8e6f0 | NLL:29 | | Y |
| NL_BORDER | 0x2a2840 | NLL:30 | | Y |
| NL_WHITE (orb white) | 0xf8faff | NLL:31 | MOCK:37 `WH='#eef0ff'`; orb stops #fff, #f3fbff, #bff6fb (L), #fff4f9, #ffc2df (R) (646-647) | ? |
| portal hole fill | 0x000000 (black) | SC:727 | MOCK:170 `#07050c` | ? mock uses near-black |
| orb radial gradient | white from core to r=0.55; to r=0.85 mixes toward pole up to k=0.3; 0.85..1.0 mixes k 0.3..1.0 (rim = pole colour); 16 steps on radius^2 | SC:588-594 (`NL_GRAD_N` 16, NLL:133) | MOCK:646-647 stops 0%, 55%, 85% (`#bff6fb`/`#ffc2df`), 100% pole; centre (cx 50%, cy 42%, r 62%) | Y approx; mock centre offset 42% not on device |
| colour is position (cyan left, magenta right) | by side index (s=0 cyan, s=1 magenta); blend over 96 face units not implemented | SC:728, 782 | MOCK:849 `col: s==='L'?L:R` | N: Canon is a positional volume; device is fixed per side |
| portal stroke alpha | 255 x pa x clamp(0.75 + 0.25 dim) | SC:728 | | n/a |
| orb alpha | clamp(0.35 + 0.65 dim) x rest | SC:774 | MOCK:~192 opacity min(1, .35+...) | n/a |
| mesh edge colours | cyan / magenta by side, white while a signal walks | SC:445, 451 | | n/a |
| ring | LUT colour NL_BG to ring colour by brightness 0..15 and angle index 0..255 | CMP:44, NLL ring LUT | MOCK:524 gradient `url(#ring)` | n/a |

## 8. Fixed-point and numeric formats

| name | value | file:line |
|---|---|---|
| pixel format | RGB565 (`r&0xf8`<<8, `g&0xfc`<<3, `b>>3`) | NLL:33-40 |
| alpha | 0..255 in the list; rasteriser uses 0..32 (`a32`, `(a x 32 + 127)/255`) | NLL (`nl_line_t.a32`), RAS draw_circle |
| line prim | 16.16 fixed point (`nx16`, `ny16`, `s0`, `t0`, `u0`, `uw`, `duv`, `r5_16`, `len16`), bounds int16 | NLL:~104-110, RAS:262 |
| unturned circle | integer: 8.8 radius (`r88`), 16.16 squared distance | RAS:~120-135 |
| screen-UI transform | 16.16 (`x 65536`) | CMP:233-236 |
| ring angle index | 256 steps per turn (`256/TAU`) | CMP:55, 295, 425 |
| ring LUT | `RL_SHIFT` 4, `RL_N` 404, 16 brightness x 256 angle | CMP:49-50, NLL |
| fast trig | parabola sin, max error ~0.001 (`nl_sin`/`nl_cos`); setup-time `nl_sin_hi` ~4e-6 | NLL:~44-62 |
| band size | 16 rows; bands at row multiples of 16; slack 256 B | NLH:~25, NL_BAND_ROWS 16 |
| soft layer (optional haze) | 233 x 233, stride 240, rows 234 | NLH:19-22 |
| prim caps | NL_SOFT_CAP 1300, NL_ORBIT_PRIMS 300, MESH_MAX 48, EDGE_MAX 256 | SC:24, 147-148; NLL |
| bounding-box pad per ellipse | `sw*0.5 + 1.5` px | SC:86 |
| min drawn ellipse axis | 0.3 px | SC:81 |
| eye-to-grad index | `(lx^2/a^2 + ly^2/b^2) x 15`, 16 entries | RAS:~105 |

## 9. Mismatches: device vs mock

The device scene was ported from the mock (SC:3-9), so the poses, geometry and draw order agree; the differences are:

1. **Colours**: device uses palette (#00f5ff / #ff2d78 / #bf5fff, NLL:26-28); mock uses #3fe6f2 / #ff3e9d / #a98bff (MOCK:37). Device is correct per Palette.md. Any registry value must come from Palette.md.
2. **Blink schedule**: mock blinks at scripted times 2.4, 6.9, 9.3 (double), 14.2 s in a 16 s loop (MOCK:124-127); device blinks every 4.2 s with a double on every third (SC:575-582). Same dip shape (0.16 s half-sine, second dip at p 0.24-0.40).
3. **Swap/flip**: the mock has no flip at all; the device's 0.7 s planar withdraw-swap (ENT:59, SC:689-712) is device-original. There is no mock equivalent for Canon to compare against; Canon 36c (1.45 s smootherstep, ~75 unit depth arc) disagrees with the device on duration (0.7 vs 1.45), easing (smoothstep vs smootherstep) and depth arc (none).
4. **States**: mock has angry (with `trem` tremor, MOCK:102, 140-151) and curious (MOCK:107) and joy `sparkle`; device omits angry, curious, trem, sparkle. Device adds F_SAD wired to NL_STATE_ERROR (mock defines sad but its timeline never uses it) and OFF fade.
5. **Timeline**: mock is a scripted 16 s loop (MOCK:77-84); device is event-driven with 0.25 s easing.
6. **Eye candy omitted on device on purpose** (SC:7-8): hazes, bokeh, glows, lens body, stars, nebula background, bars, speak waves, mic bloom, portal halo (MOCK:169 soft ellipse rx58 ry20), eye halo (MOCK:192 soft ellipse rx28 ry64).
7. **Device-only**: touch dent and gaze (110/34/9 px), dizzy, focus, sway, roll/gravity, orbit slide, UI slide, strands, mesh orbit hand-off, `rest` boot fade.
8. **Portal hole fill**: #07050c (mock) vs 0x000000 (device).
9. **Orb gradient**: mock radial gradient centre cy 42%, r 62% (off-centre highlight, MOCK:646); device radial about the eye centre with `radius^2` index (SC:588-594), so the device highlight is centred.
10. **Clip**: mock clips to a half-plane rect (600 x 1200) in portal-local space plus the opening ellipse (MOCK:181-184); device implements the same two-part clip (RAS:99-103 and `nl_clip_t`, SC:772). Equivalent. Device clip is evaluated only on edge pixels plus fill by half-plane; equal result.

### Mismatches against Canon (needs a ruling before the registry is generated)

| item | device | Canon |
|---|---|---|
| swap duration | 0.7 s | 1.45 s |
| swap easing | smoothstep | smootherstep |
| depth arc | none (planar y-only) | about 75 units |
| portal flatten | 0.25 (11/44) | 0.30 |
| portal Y | 0.862 (L), 0.793 (R), asymmetric | 1.00 default (0.2 to 1.5) |
| portal clearance | -2 px at rest (overlap); portals at equal y mid-swap | never touch |
| turn move | absent | half-turn yaw |
| perspective/elevation/tilt (EPS0, EPSK) | absent | defined |
| swallow cut | hard half-plane clip plus opening ellipse | smooth alpha dissolve `smoothstep(sd/span)` |
| colour as position | fixed per side | positional volume over 96 face units |
| eye squash on swap | height only (width stays 44 px) | not specified beyond "squash" |
| ring width | n/a | "~2.0 eye widths" is satisfied by portal width (88/44) |

## 10. Device draw order per pose (the reference occlusion)

The display list is rasterised per 16-row band in **push order** (CMP:~432-440: `for i in bin: ... nl_draw_*`). The ring (compose) is drawn first, under everything (CMP:428-431; over the scene only while a UI screen or Orbit shows, CMP:443). So the order is the order of `push` calls in `nl_simulate`:

Layer sequence (SC line numbers):
1. Background fill (`NL_BG`, or soft haze if enabled) and the ring LUT band (CMP:~418-431).
2. Mesh (`mesh_layer`, SC:679): edges, nodes, signals, ripples. Skipped when `rest <= 0`.
3. For s = 0 then s = 1 (SC:699-731): **portal back** = one ellipse prim, black fill (alpha `por_a`), stroke 2.6 px in pole colour, restricted to an arc: `arc = (s != flipped) ? 2 : 1` (SC:729). Arc code 1 = local y >= 0 (lower half), 2 = local y <= 0 (upper half) (NLL ellipse struct; RAS:113). So at rest (flipped = false): L (top portal) back = **lower** arc; R (bottom portal) back = **upper** arc. Both portal backs are drawn before any eye.
4. Strands and absorption sparks (SC:735-765), only while listening, only when no Orbit shows. Over the portal backs, under the eyes.
5. For s = 0 then s = 1 (SC:768-786): **eye s**, then **front rim s**, interleaved:
   - eye: ellipse a=22, b=58 (scaled), gradient fill (`grad = s`), `fill_a = 255 x oa`, **clip = nl_clip[s]** (SC:779).
   - clip (SC:769-772): keep the half-plane `n.(p - p0) >= 0` with p0 = portal centre on screen and n = (-rs x keep, rc x keep), `keep = (s != flipped) ? -1 : 1`... evaluated at upright: L gets keep = +1 (keep **below** the portal plane), R gets keep = -1 (keep **above**). Plus the interior of the opening ellipse 44 x psx by 11 (SC:772). Inside the half-plane the eye shows fully; outside the half-plane it shows only inside the opening ellipse (RAS:99-103: `hp < 0` and outside the ellipse sets coverage to 0).
   - front rim: stroke-only ellipse, same centre and radii as the back, `arc = (s != flipped) ? 1 : 2` (SC:784): L front = **upper** arc, R front = **lower** arc.
6. Glass: badges (SC:789-800), then sprites (SC:801-815). Then Orbit prims.

Note the interleave: order is portal-back L, portal-back R, [strands], eye L, front rim L, eye R, front rim R. So eye R is drawn after front rim L (R's eye covers L's front rim where they meet), and front rim R is drawn after eye L (covers L's eye where they meet). At rest none of these overlap (eye L x 168..212 vs portal R x 232..320).

Occlusion meaning at rest (unflipped, upright, no wander):
- **L pair (cyan, top portal at y 185, eye centre 235)**: the eye (height 116, top at 177) is clipped to below the plane y=185, so the 8 px that would rise above the plane are removed except inside the opening ellipse (|x|<=44, |y|<=11 of the portal, i.e. y 174..196). The portal's back rim (lower arc) is behind the eye; the eye covers it. The front rim (upper arc, y<=185) is drawn over the eye. So the eye comes out of the **bottom** of the top portal, in front of the back rim, behind nothing else.
- **R pair (magenta, bottom portal at y 285, eye centre 239)**: eye (bottom at 297) clipped to above the plane y=285; portal back rim = upper arc (behind the eye), front rim = lower arc (over the eye). The eye goes into the **top** of the bottom portal.
- Relative to Canon section 6: the device draws both portals' backs, then each eye, then each near rim over its own eye through the opening. The upper-role eye is not "in front of" its near rim in the opening region (the rim is drawn after the eye); the Canon text says lower-role rim is "drawn through" the eye and the upper-role eye stays in front. On the device both roles get the rim over the eye inside the opening; outside the opening the eye is simply cut at the plane, so no ring crosses the eye outside the opening. Whether this is what Canon ruling 33c/37 means by "upper-role eye stays in front" needs Mark's read. Marked "?".

Per pose:

- **Idle**: as above, `blink = 0`, `withdraw = 0`, `fl = 0`, flipped = false. Eyes full 116 px tall, portals at base positions plus wander (section 2).
- **Blink** (SC:575-582, 773, 776): eye height drops to `bs` = 1 - 0.95 blink (min 0.03) over 0.16 s; its centre shifts toward its portal end by `anchor x (1-bs) x sy` (58 px at full close), so L eye (anchor -58) collapses upward toward the top portal, R eye (anchor +58) downward toward the bottom portal. Order and clip are unchanged. Width does not shrink. Because the eye stays cut by the same plane, the part of the eye beyond the plane disappears even faster; at full blink the eye is a ~3.5 px tall sliver at the portal end.
- **Mid-swap** (fl in (0,1), SC:689-731, 773-785): portal y moves linearly in `fl` toward the mirror about the eye: L from y185 down to 285, R from 285 up to 193 (2 x 239 - 285 = 193; L ends at 2 x 235 - 185 = 285). x is unchanged. The eye withdraws: `bs` -> 0.03 at fl = 0.5, anchor passes 0 (the sliver is at the eye centre), then regrows toward the new end. At fl = 0.5 the portals are at y 235 (L) and 239 (R) respectively, coincident with the eyes, 4 px apart vertically with 11 px half-height and 2 px x-overlap: **the two portal ellipses overlap each other** (and L's and R's rims cross) at about fl = 0.5. At that same instant `flipped` flips: the back and front arc codes swap (SC:729, 784) and both clips' `keep` sign flips (SC:771), so the visible halves switch with a hard cut at fl = 0.5, hidden only by the eyes being 3% tall. Draw order (back L, back R, eye L, front L, eye R, front R) is unchanged through the swap; only which half is clipped/stroked changes.
- **Turn**: there is no Canon turn on the device. The only turn is `nl_roll` (hardware roll), applied by `tx()` to every primitive's position and by the ellipse `rc, rs` (SC:84-90): it is a rigid rotation, draw order unchanged. The Canon "eyes trade places, one passing in front" does not exist here; draw order never changes by pose except via `flipped` (arc halves, clip sign).
- **Withdraw without flip** (fresh start): `withdraw` set by `fresh`, `fl = 0`, `flipped` stays false: the eyes squash toward their portal-side anchor (anchor not flipped, so the sliver is at the original portal end) and regrow over 0.8 s; portals do not move.

Device notes for the generator header (derived values, not mock-equivalent constants): ELLIPSE_EYE_A 22, ELLIPSE_EYE_B 58, ELLIPSE_PORTAL_A 44, ELLIPSE_PORTAL_B 11, PORTAL_STROKE 2.6, EYE_BASE {190,235},{276,239}, PORTAL_BASE {190,185},{276,285}, FLIP_S 0.7, FRESH_S 0.8, BLINK_PERIOD 4.2, BLINK_DUR 0.16, BLINK_DOUBLE_AT 0.24, BLINK_DEPTH 0.95, WITHDRAW_DEPTH 0.97, BS_MIN 0.03, STATE_TAU 0.25, PONDER_TO_PROCESS 1.5, BOOT {0.35, 0.12, 0.67, 0.25}, OFF_FADE 1.0, plus the FACE table of section 3.

## 11. Legacy path (not live in `nl_simulate`)

`EF` (`entity_face.h`) holds an older LVGL cluster: ENTITY_EYE_H 128, ENTITY_EYE_W 44 (comment: EYE_H x 38/110), ENTITY_EYE_GAP 42, ENTITY_EYE_BASE_Y -7, ENTITY_PORTAL_H 33, ENTITY_PORTAL_W 106 (PORTAL_H x 90/28), portal offsets 64 (cyan, above) / 67 (magenta, below), ENTITY_RING_W 3, orb white 0xf8faff (EF:20-33). Those are NOT the live proportions (live: 44 x 116 eye, 88 x 22 portal, offsets 50/46). `rabble_ui.c` `pose_t` and `pose_for` (UI:99-181) with `eye_h` multipliers (idle blink 0.08..1, listening 1.12/1.06, thinking 0.85, speaking 0.9 + 0.35 level, error 0.35, off 0.1..1) and `BOOT_*`/`BLINK_*` defines belong to the earlier LVGL-era pose path; the BOOT_* numbers match the live ones in `scene.c`, so treat them as one set. Do not put the EF ratios in the registry: eye 38/110 = 0.345 and portal 90/28 = 3.21:1 (flatten 0.311) are NeBuLA's, and are the closest to Canon's flatten 0.30 and eye ratio; the live device uses 0.379 and 4:1. Provenance for the NeBuLA ratio: EF:11-20 comments (eye-behavior.js, eye-system.js, portal-system.js).
