# Pocket effects census (for NeBuLA registry port)

Read-only. Paths are under `RaBbLE-Pocket/` unless noted. Abbreviations:
- **DEV** = device C: `firmware/entities/RaBbLE/src/scene.c` (scene builder, "scene.c"), `.../nebula_lite/src/{compose,raster_soft,luts,orbit,store}.c`, `.../nebula_lite/include/{nl_list.h,nebula_lite.h}`, `.../include/nl_scene.h`.
- **MOCK** = `planning/mock/rabble-pocket-entity.html` (SVG, the source scene.c was ported from).
- **WEB** = `companion-app/web/public/entity/pocket-entity.js` (generated from MOCK by `companion-app/web/build-entity.py`; its lines 3-735 are the mock's script verbatim minus a few text patches, then the API). `companion-app/web/public/orbit.js` is the Orbit drawer.

Key facts up front
1. DEV deliberately omits all "eye candy". scene.c header (lines 1-11): "Eye candy (hazes, bokeh, glows, the lens body) is left out on purpose."
2. The DEV haze layer exists in code (`raster_soft.c`) but is **not enabled**: `rabble_entity.c:790` calls `nl_init(&(nl_config_t){ .list = list })`, no `.soft`, so `nl_soft == NULL` and the background is a flat `NL_BG` fill (`compose.c:417-421`). Same in `tools/panel_bench/main/panel_bench.c:206`. The sim (`host_render.c`) also calls `nl_init(NULL)`. So "device keeps nebula wash, two hazes" in the plan table is aspirational; today the device draws a flat void + ring.
3. MOCK/WEB palette differs from DEV palette. MOCK `CY '#3fe6f2', MG '#ff3e9d', VI '#a98bff', WH '#eef0ff'` (mock:37, web:4). DEV `NL_BG 0x0a0010, NL_CYAN 0x00f5ff, NL_MAGENTA 0xff2d78, NL_VIOLET 0xbf5fff, NL_TEXT 0xe8e6f0, NL_BORDER 0x2a2840, NL_WHITE 0xf8faff` (nl_list.h:25-31). Orb gradient: MOCK `orbL` stops `#fff / #f3fbff 55% / #bff6fb 85% / CY` (mock:~644), web patches 85% to `#a9f4f9` (build-entity.py:22-23) and `#ffa8d3` for R; DEV builds the table in `nl_scene_init` (scene.c:584-595): white to r<.55, then to pole colour with k = (r-.55)/.30*.3 up to .85, then .3 + (r-.85)/.15*.7. Parity needs a registry decision on which palette is canonical (Grimoire palette says device values).
4. MOCK mesh topology differs from DEV: MOCK links each node to its 3 nearest next-layer nodes plus 2 same-layer neighbours (mock:~380-384); DEV links fully layer-to-layer (scene.c:243-250) and has only 2 same-layer ring links. MOCK signal slots 28 (16 in PORT mode) (mock:~384); DEV `SLOTS 16` (scene.c:150). MOCK signal count follows the 16 s timeline states; DEV follows `activity[]` (CPU load per core) + state lift.
5. MOCK `sparkles()` (mock:200) is defined and **never called** (dead code); joy sparkles do not render on any surface.
6. DEV caps: `NL_MAX_PRIMS 1400` (nebula_lite.h), `NL_SOFT_CAP 1300` (scene.c:24; mesh+strands stop here), Orbit keeps `NL_ORBIT_PRIMS 300` (nl_list.h). Sim measured 172 prims idle (see sim section).

## Draw order and per-effect table

Surfaces column: D = device today, M = mock, W-lite = web default profile, W-full = web `setQuality('full')`. "Yes" = drawn; "-" = not drawn.

### Layer A: background / backdrop

| # | Effect | DEV (file:line) | MOCK (line) | WEB (line) | D | M | W-lite | W-full |
|---|---|---|---|---|---|---|---|---|
| A1 | Nebula wash (void with violet radial lift) | none; flat `NL_BG` fill `compose.c:417-421`. Soft/haze path `raster_soft.c` (`haze_bake` :64, `nl_soft_bake` :91) exists, base `SPREAD(10,0,16)` :70, unused | `<rect class="s" fill="url(#neb)">` :523; gradient `neb` cx48% cy50% r60%: stops `#3b2e55 0%, #2a223d 35%, #17121f 70%, #0b0910 100%` (DEFS :640) | :490 | flat void | yes | yes (KEEP_SOFT matches `neb`) | yes |
| A2 | Two poles' hazes (cyan left, magenta right) | `raster_soft.c`: poles at (±.42R, -.30R) rotated by gravity, radius .75R :66-68, tints cyan g .22*245 b .30*255, magenta r .30*255 g .10*45 b .25*120 (:48-50 comment) , rim darkening `1-0.55u^2` :46; baked at **half-res of soft layer (120x118)**, rebaked only when gravity moves >= 0.0087 rad :95 | two `<ellipse class="s">` hazeL cx150 cy240 rx170 ry150 / hazeR cx320 cy230 rx170 ry150, stop-opacity .22 :524 | :491 | none (code present, disabled) | yes | yes (kept by `hazeL|hazeR`) | yes |
| A3 | Data bits (30 drifting dots/dashes/squares/0-1 glyphs) | - | `BITS` :501 (rng 404, 30 items, kinds pt/dash/sq/txt, opa .25-.65, drift vy=466/LOOP for 40%), `dataBits(t)` :505 | :468/:472 | - | yes | yes (not `.s`, no filter) | yes |
| A4 | Stars (twinkle) | - (plan says reduced "backdrop wash + stars" but no stars in scene.c) | `STARS` :332: rng 11, 46 (30 in PORT), r .4-1.5, opa .15-.65, twinkle 2*(1..4) cycles/loop; fill `#fff` :526 | :299 | - | yes | yes | yes |
| A5 | Meridian grid ellipses (6 faint ellipses rotated -12 deg, stroke `#b9dcff` @ .06) | - | :527-529 | :494 | - | yes | yes | yes |
| A6 | Ring (colour ring r214, cyan left to magenta right) | **Yes, compose.c**: `RING_R 214, RING_IN 206.5, RING_OUT 221.5` :9-11; per-pixel angle LUT `s_ring_idx` (20800 B, PSRAM) `ring_init` :53; radial level LUT :73-80 (core 1.7+.5-d, glow `.35*(1-d/7.5)^2`); per-frame one LUT lookup `ring_row` :83; colour LUT `nl_ring_lut[16][256]` luts.c:34-45 (magenta-cyan cosine mix, 32-step tint, `nl_ring_tint`); drawn under scene (compose.c:426), over Orbit (:444) and UI screen (:449) | soft stroke 14 px `.35` w/ `soft` blur + crisp 3.4 px `.9` w/ `glow` blur, gradient `ring` L to R :530-531 | :497 | **yes** | yes | **yes but soft 14 px stroke stays (class s + url(#ring) kept) with blur removed**: a flat hard 14 px band at .35, differs from DEV glow | yes |
| A7 | Ring tint / dim / drain arc (Pomodoro) | `nl_ring_tint` (luts.c:34), `ring_dim`, `ring_arc` inputs (nebula_lite.h nl_inputs_t); drain arc = 24 round-capped 15-degree chunks `RARC_CHUNKS 24`, `nl_ring_arc_frame` compose.c:289, drawn last over everything compose.c:454 | - | - | yes | - | - | - |
| A8 | Far bokeh (r<=10) | - | `BOKEH` :334 (rng 91, 56 discs (28 PORT), r 4-17, palette L,L,VI,VI,L,R,WH,WH, op .26-.58, orbit 3-11 px on 1-3 cycles/loop, 30% have rim), `bokehLayer(t,dim,false)` :343/:532; discs `.s` radial `bk*` | :310 | - | yes | disc dropped, **rim circles (no .s) remain** | yes |

### Layer B: body (the lens)

| # | Effect | DEV | MOCK | WEB | D | M | W-lite | W-full |
|---|---|---|---|---|---|---|---|---|
| B1 | Lens body fill (bell-shaped glow, cyan-violet-magenta horizontal gradient) | - (stated omitted) | `lensFill(t)` :317, `LENS_H 140` :273, `lensEnv` sin(pi u)^1.6; gradient `body` stops L@0 op0, L@25% .14, VI@50% .12, R@75% .14, R@100% 0 (DEFS); `.s`, opacity .8*dim :535 | :284/:502 | - | yes | no (.s dropped) | yes |
| B2 | Spectral bars (74 at x step 6, 2 px wide, with moving ticks) | - | `BARS` :323 (rng 7, x 14..452 step 6 (8 PORT), base .5-1, k 4-8 cycles/loop, colour barL/barR by random split, tick 45%); draw :539-546; alpha `barA = (.6(listen+joy)+.22think+.85speak)*dim`, `barH = .85+.35 speak*syl-.15 think` :537-538 | :290, :508 patched by build-entity.py:12-13: `barA += .95*MICV`, height x `0.45+1.7*MICB[band]` when `MICON`. 32 bands `MICN` pocket-entity.js:738 | - | yes | yes (not .s; **emitted even at idle with opacity 0**) | yes |
| B3 | Lens outline (3 braided jittery strands per edge, white cores, coloured glow, dark chalk) | - | `LENS_STRANDS` :~280, `lensOutline` :292: amps 330/300/250 *.44, widths 4/2.2/1.4*.45; jitter re-rolled every `PER=.16 s` with exp smoothing; 91 points per strand; glow `.s` strokes (w*5 @ .1dim, w*2.2 @ .3dim), core `WH` w @ .95dim, dark `#07050c` @ .55 | :259 | - | yes | cores + dark chalk only | yes |
| B4 | Speak waveform (4 sine strands across the body) | - | `speakWaves` :474: amplitude `30*speak*syl(t)`, specs `[ring 1.8 .95 0],[#fff 1 .45 1.6],[L 1.1 .55 3.1],[R 1.1 .55 4.4]`, group `filter=url(#glow)` | :441 | - | yes | geometry yes, glow removed | yes |
| B5 | Insight burst (twin rings + white flash at t=7.85) | - | `insight` :491, 1.1 s, rings r 20+190x*k, flash `.s` bkeef0ff | :458 | - | yes (timeline only; web idle never reaches t window state? it draws by t, any mode) | rings yes, flash dropped | yes |

### Layer C: mesh (hubs, 3 layers, ring)

Node/edge/slot counts: `MESH_MAX 48`, `EDGE_MAX 256` (scene.c:~140-141); layers `{6,140,320,.66,40},{5,300,450,.54,34},{5,430,575,.44,26}` (scene.c:217), `HUB 250`, ring 5 nodes at r158 spaced .45 rad, rng seed 53; MOCK same data (mock:356-358).

| # | Effect | DEV | MOCK | WEB | D | M | W-lite | W-full |
|---|---|---|---|---|---|---|---|---|
| C1 | Mesh build + node motion (drift, breathe, think accordion, minimum radius 152 to 104) | `mesh_build` scene.c:214, `mesh_positions` :307 (SHIFT {0,8,24,42,58}, breathe .14 sin(w8 t), rmin lerp(152,104,think), sway lag .3/.5+.25*layer, **touch dent** `TOUCH_R 110 / TOUCH_PUSH 34` :303-305) | `MESH` :356, `meshPositions` :395 | :323/:362 | yes (+touch, sway IMU) | yes (no touch/sway) | yes | yes |
| C2 | Edges (idle skeleton always, rest fade in by activity; hot edges white) | scene.c:438-452: `s_edge_th` rank threshold; width 1.0, colour `NL_CYAN`/`NL_MAGENTA`, alpha `(.42+energy*.2)*dim` (x1.3 magenta), hot edge `NL_WHITE` w1.3 `.9*dim`; lines are `NL_P_LINE` capsules, setup 16.16 fixed point once (`nl_line_setup`, nl_list.h) | all edges every frame: base path `stroke 1 opacity (.42+energy*.2)*dim`, `.s` glow stroke 4 @ .13dim, hot path `.s` 6 @ .3 + `WH` 1.3 @ .9 :416-470 | :383 | yes (sparse) | yes (dense) | base + hot cores (glow dropped) | yes |
| C3 | Node rings + core discs + halo | scene.c:~455-465: ring r=z+1.2 stroke 1.2+hot, disc r=.7z, `z=(7|6|5)*.42`; no halo | + `.s` halo radial gradient r = z*(3+.9nz+h*3) | :433 | yes (no halo) | yes | no halo | yes |
| C4 | Signals (comet tail line 1.8 + head dot) and arrival ripple | scene.c:385-437: slots `SLOTS 16`, `PER 1.6`, `NPER 10`; count per side `1+round(a*(SLOTS/2-1))`, speed `.6+1.6a` where `a=clamp(activity+lift)`, `lift=.15listen+.35think+.25speak+.2joy` (scene.c:~370); tail 15 px; ripple r `4+tt*30`, o `.8(1-tt/.35)` | :416-470: line + `.s` r=5.5 glow + core r1.6; ripple circle | :383 | yes | yes | glow dropped | yes |
| C5 | Mesh handoff to Orbit (side taken by orbs; stretch `MESH_STRETCH .5`; links fade .3..1, nodes .7..1 of the slide) | scene.c:346-352, 421-437; exports snapshot `nl_mesh_xy/side/edge/ea` (nl_list.h NL_MESH_*) | - | `PocketEntity.meshSide(side)` pocket-entity.js:791 returns live nodes {x,y,layer} + edges for orbit.js | yes | - | yes (API) | yes |

### Layer D: portals, eyes, listening

| # | Effect | DEV | MOCK | WEB | D | M | W-lite | W-full |
|---|---|---|---|---|---|---|---|---|
| D1 | Face pose table + blend (calm, joy, sad, listen, speak, ponder, process) with 0.25 s ease | `F_*` scene.c:125-131, blend :597-680 (`k = 1-exp(-dt/.25)` :623), mock-equivalent poses; state to target mapping :610-621; ponder 1.5 s then process | `FACE` :~100, `states(t)` :81 (16 s timeline), `liveFace` :~129 | :65/:94 | yes | yes (+angry, curious in sheet only) | yes | yes |
| D2 | Eye/portal geometry, idle wander, hop, dizzy, flip, withdraw ("fresh") | scene.c:~675-722; wander `eWx=2.5S*nz*2.2` etc; `hop 6|sin(w12 t)|`; dizzy `14*dz*cos(14t)`; flip `fl` smoothstep, portals mirror, eyes withdraw `sin(pi fl)`; `fresh` one-shot | `faceGeom` :140 (no flip/dizzy) | :107 | yes | yes (basic) | yes | yes |
| D3 | Gaze / touch glance | `TOUCH_GAZE 9` px toward `in->touch` (scene.c:303-305, ~700) | - | `look(x,y)` pocket-entity.js:802, eased `k=1-exp(-dt*9)` (:~822), idle pose adds `gx*17`, `gy*10`, `tilt += gx*2.5` (:~765) | yes (touch) | - | yes (pointer) | yes |
| D4 | Blink | `blink_at` scene.c:575 (every 4.2 s, doubled every 3rd; 0.16 s dips) | `blinkAt` :117 (fixed times 2.4, 6.9, 9.3 double, 14.2) | :84 | yes | yes | yes | yes |
| D5 | Portal back (halo + hole + back rim) | hole = black ellipse 44x11 + rim stroke 2.6 (arc half) scene.c:723-731, `.arc` side selection by `flipped`; no halo | `portalBack` :164: halo `.s` rx58 ry20 @ .38dim blur; hole `#07050c`; back rim `glow` | :131 | yes (no halo, no glow) | yes | yes (no halo, no glow) | yes |
| D6 | Orbs (gradient eyes) clipped to portal plane + front rim | scene.c:767-787: `nl_clip[]` (half-plane + opening ellipse), `grad` from `nl_grad[s]` (16 steps, by r^2), squash anchor ±58, blink floor `.03` | `portalFront` :177 with SVG clipPath, `.s` soft halo behind orb rx28 ry64 | :144 | yes | yes | yes (no halo) | yes |
| D7 | Mic strands into both portals (3 per route, 2 routes if mic is behind) | scene.c:733-753 + `strand` :522: Catmull-Rom `CR_STEPS 3`, `WAY_MAX 22`, specs `{amp,lam,ph,width,opa,jit,whiten}` = `{14,48,0,3.4,1,0,0},{10,40,1.7,1.8,.75,7,0},{8,58,3.3,1.3,.6,6,.85}`; carrier `n0=round(v*LOOP/lam)`, v=150+22 sin(2.3ph); **retarded time level** from `s_hist[HIST=256]` (scene.c:473; ~4 s @60 fps) via `hist_at`; `lev=.15+.85*level` | `routes` :213, `strand` :231: 14 CR steps, **22 chunk paths per strand**, `<g filter=url(#sglow)>` (stdDev 7 + 2.5 double-merge blur) :566; level is synthetic `phrase*syl` (not a mic) | :180/:198 (`audio()` does NOT feed strands, only bars) | yes (real mic) | yes (synthetic) | yes, no sglow blur | yes |
| D8 | Absorption (portal mouth bloom + 12 inward sparks) | sparks only: scene.c:754-765 (12 discs, r .9+1.5(1-life), spawn on plane 14-44 px, y scaled .35) ; no bloom | mouth bloom `.s` ellipse rx26 ry7 bkcolour + 12 `glow` sparks :568-578 | :537 | sparks only | yes | sparks (glow dropped) | yes |
| D9 | Mic bloom at the mic position while listening | - | `.s` bloom r 32+4 sin(w16 t) :555 | :522 | - | yes | no | yes |
| D10 | Joy sparkles | - | `sparkles()` :200 never called | :167 never called | - | dead | - | - |

### Layer E: glass layer (fixed to hardware, on top)

| # | Effect | DEV | MOCK | WEB | D | M | W-lite | W-full |
|---|---|---|---|---|---|---|---|---|
| E1 | Edge depth vignette | - | `<circle class="s" fill=url(#depth)>` :585 | :552 | - | yes | no | yes |
| E2 | Clock (large time, am/pm, glass drop shadow + magenta stroke) | `nl_sprite_t` A8 text from LVGL fonts (`rabble_entity.c` add_text, `MODE_Y`, `STATUS_Y`; `rabble_clock_screen.c`) ; sprites `NL_GLASS_SPRITES 16`, drawn by `nl_draw_sprite` (raster.c); `upright` 0/1/2 modes | Chakra 46 px `4:20 pm` w/ `cast` shadow + `MG` stroke .8 :586-588 | patched to real local time `${CLK.hm}`/am-pm (build-entity.py:14; `tick()` pocket-entity.js:748; 12 h lowercase) | yes (LVGL text) | yes (hard-coded) | yes (shadow filter stripped) | yes |
| E3 | Reflection arcs on the lower glass | - | 3 arcs :589-591 | :~557 | - | yes | yes | yes |
| E4 | Status icons (mic, ble, battery 89%, wifi, sd) | board-driven text/icons: wifi, sCoRE, battery (`rabble_entity.c:~283-294`, Montserrat 16 A8 sprites) | `icon()` :~86 | :34 | yes (different set) | yes | yes | yes |
| E5 | State label (LISTENING/THINKING/SPEAKING) and subtitles on an arc (word typing, `RA 240`) | state mode/caption text sprites (`rabble_state_caption`, entity MODE_Y) | :608-624 `subArc` textPath | :~570 | yes (own layout) | yes | yes | yes |
| E6 | Button hint badges (ring around icon, `hot` thicker 2.2 vs 1.2) | scene.c:788-800: `NL_P_ELLIPSE` black fill alpha 200 + stroke; fixed to hardware | circles r10.5 @225/315 deg, r219 :626-631 | :~590 | yes | yes | yes | yes |
| E7 | Glass highlights and sheen (2 arcs, diagonal gradient, rim line) | - | :632-635 (`.s` ×3 + rim circle r232 @ .07) | :598-601 | - | yes | rim only | yes |
| E8 | Device bezel + buttons drawing | - | `device()` :664 | - (not in web mount) | - | yes | - | - |

### Layer F: transitions / lifecycle

| # | Effect | DEV | MOCK | WEB | D | M | W-lite | W-full |
|---|---|---|---|---|---|---|---|---|
| F1 | Boot (portals fade in cyan first, then eyes + rest; OFF fades all) | scene.c:626-637: `por_a[0]=b/.35`, `por_a[1]=(b-.12)/.35`, `rest=(b-.67)/.25`; `in.boot = now - s_lit_at` (rabble_entity.c:668); ring opacity follows portals `nl_ring_opa` :632 | - | - ("not built", per plan; HANDOFF-S350 s3 spec) | yes | - | - | - |
| F2 | Orbit open/close transition (entry drag glow, mesh orbs gather into dial, track, value arc + knob, items, rings, ripple, back chip pill) | `nl_orbit_begin/build` orbit.c:30-399: `ORB_FROM_R 175` :102, per-orb staggered clock `orb_t` :106, track arc 1.5 px `NL_BORDER` + lit 3 px, value arc, 2b entry edge glow (`198-4e` radius, two arcs), 2c orbs (~0.9 s in, 0.6 s back), chip pill; scene hand-off scene.c:346-352; `NL_ORBIT_PRIMS 300` | - | `orbit.js`: `DUR 820` ms, ease cubic-out :17-18, `STEP 31`, `RING 41`% :15-16, `mesh(dir)` :236 (Canvas2D, **`shadowBlur = 7`** :287, `dpr<=2`, nodes share out among orbs, edges alpha `.9(1-e^5)`), DOM dial otherwise; honours `prefers-reduced-motion` (skips animation) | yes | - | yes | yes |
| F3 | UI screen slide (LVGL screen over scene; scene slides left by `slide`) | compose.c `ui_band` :195, `nl_ui_frame` :120, bilinear unless within .6 deg of quarter turn, per-band versions | - | - | yes | - | - | - |
| F4 | Backdrop-only still (for Orbit bg) / snapshot | - | - | `backdrop(el)` pocket-entity.js:797 (keeps `neb|hazeL|hazeR|ring` + `fill="#fff"` stars, **drawn once**), `snapshot(el,state)` :779 (fixed t: idle 8, else window midpoint) | - | - | yes | yes |

## Inputs per effect (who feeds what)

DEV `nl_inputs_t` (nebula_lite.h): `t`, `roll` (IMU gravity turn), `level` (mic while listening / reply while speaking, 0..1), `happy`, `dizzy` (shake), `sway[2]` (IMU lag px), `touch[3]` (x,y,strength), `boot`, `mic_deg[2]` (mic positions per portal), `activity[2]` (CPU load per core drives mesh), `flip`, `fresh`, `ring_rgb/tint/dim/arc*`, `focus` (narrows eyes, quiets mesh), `state`, `sprites[16]`, `badges[2]`, `ui`, `orbit`. WEB inputs: time `t` (advances by min(.1,dt)), mode window (`WIN` pocket-entity.js:776: idle [0,16], joy [12.6,15], listen [.6,3.4], think [4.4,7.4], speak [8.3,11.8]), pointer `look(x,y)`, `audio(levels[])` (bars only, `MICN 32`), wall clock. MOCK: only `t` (+ `rot` 360*t/LOOP for the device spin).

Parity notes for the registry:
- Mic levels: DEV feeds one scalar `level` (history for strands); WEB feeds a band array to the bars only (no strands). Registry input channels need both: scalar level + band array.
- Gaze: DEV has touch-glance (no pointer, no IMU gaze); WEB has pointer. Plan's "Gaze none ?" for HW is wrong for touch: HW already does touch gaze (`TOUCH_GAZE`) and tilt/sway from IMU.
- IMU `sway` and `roll` exist on device only.

## Cost notes

### Device (all numbers from code/docs; no live measurement)
- Primitives only: ellipses (fill/stroke/arc, orb gradients `nl_grad[2][16]`, half-plane clip), capsule lines (16.16 fixed point, set up at push), sprites (A8), annular arcs (`nl_arc_t`). No blur, no offscreen layers (nebula_lite.h header).
- Rendered in 16-row bands (`NL_BAND_ROWS 16`), each band window = widest chord, x0 16-px aligned, width multiple of 8 (compose.c:29-42); prims binned per band (`nl_list_bin`, `NL_BIN_MAX 4096`); a per-band content hash skips unchanged bands (`nl_band_same`, compose.c:327-359) ("about 18 of 30 bands drawn at idle"). Note the hash includes `s_bframes` when `nl_soft` is set, so haze would defeat damage skipping (compose.c:332).
- Buffers: list `NL_LIST_BYTES = 1400*56 + 4096*2` B in PSRAM; soft layer `NL_SOFT_BYTES = 240*234*2+32` ~ 112 KB (disabled today) plus haze cache `aligned_alloc((128*118+16)*2)` ~ 30 KB, quarter-res bake (120x118) doubled into the half-res soft layer (233x233), then 2x bilinear upscale per band by PIE SIMD (`nl_simd_hdouble`, `nl_simd_avg`, `nl_simd_swap`, `simd_pie_esp32s3.S`). Ring LUT `s_ring_idx` 20800 B and spans in PSRAM (`NL_EXT_BSS`), `nz` cache 512 entries.
- Costs documented in `RaBbLE-Grimoire/RaBbLE-Pocket/RaBbLE-Pocket-Entity-Port-Plan.md`: background + upscale 3.2 ms static (bake .38 + render 2.83), 6.9 ms while the angle moves (bake 4.1; 59 cycles/haze pixel); fps results S252: idle 60.0 TE-locked, listening/speaking held still 31-41, turning ~30, "22 fps floor in the busiest states" (superseding line 18); CPU budget ~4 M cycles/frame/core for ~170k visible pixels; QSPI at 80 MHz reaches 60 fps TE-paced (40 MHz cannot). Biggest cost lever found: edge count (idle sparse mesh lines 13.9 to 2.9 ms).
- Per-stage device log every 10 s: `rabble_entity.c:~320-338` prints fps, render ms, prims and `nl_prof` ms for fill/ring/ellipse/line/sprite/swap/sim/ui (`nl_prof[13]`, `nl_cycles = esp_cpu_get_cycle_count` set at :792, ms = cycles/240000/n frames).
- Effect cost classes on device: ring (cheap, one LUT lookup per ring pixel); mesh lines (dominant, scales with active edges); strands (3 strands x up to 2 routes x ~(npts-1)*3 segments x 2 portals while listening; capped by `NL_SOFT_CAP 1300`); orbs (gradient ellipses, "orbs" `nl_prof[7]`); haze (3.2 to 6.9 ms, off); sprites (A8 blend).

### MOCK/WEB
- Whole scene rebuilt as an SVG **string** every drawn frame and assigned with `el.innerHTML` (`mount()` pocket-entity.js:~826; `uniq()` rewrites every `id=` and `url(#)` per mount, `NS` counter). Measured by running the generated script under node and counting `snapshot()` output (idle t=8, others at window midpoint; whole frame including glass layer):

| profile/state | bytes | elements | `filter=` refs |
|---|---|---|---|
| lite idle | 62,016 | 413 | 0 |
| lite listen | 108,845 | 604 | 0 |
| lite think | 61,254 | 411 | 0 |
| lite speak | 65,301 | 415 | 0 |
| lite joy | 59,170 | 403 | 0 |
| full idle | 97,761 | 560 | 16 |
| full listen | 141,706 | 739 | 40 |
| full think | 95,948 | 554 | 15 |
| full speak | 98,927 | 557 | 17 |
| full joy | 92,887 | 545 | 14 |

- Blur filters in DEFS (mock:~650-653): `glow` stdDev 4 (merge), `sglow` stdDev 7 + 2.5 double merge, `soft` stdDev 10, `cast` drop shadow dy4 stdDev 3.5, `drop` stdDev 14 (bezel). Filter regions are 220-260% of the element bbox. In 'full', `sglow` wraps all mic strands in one group (biggest GPU cost while listening), `glow` is on every portal rim, spark, speak-wave group and insight ring, `soft` on halos and the ring.
- **lite profile** (`build-entity.py:36-42`, regex string surgery): `SOFT = /<(?:ellipse|path|circle|rect)\b[^>]*\bclass="s"[^>]*\/>/g` removes every `class="s"` element unless `KEEP_SOFT = /url\(#(neb|hazeL|hazeR|ring)\)/` matches; `FILTER = / filter="url\(#...\)"/g` is stripped from all elements. Dropped in lite: bokeh discs, body fill, lens glow strokes, mesh halos/glow, signal glows, portal halos, mic bloom, absorption core, depth vignette, sheen/highlights, insight flash. Kept: nebula wash, two hazes, ring (soft 14 px band now unblurred), stars, data bits, bars, lens cores, mesh cores, portals, glass text. Known side effects: bokeh rim circles (no `.s`) stay; `cast` shadow under clock and icons stripped; `<defs>` still carries the 5 blur defs. `setQuality(q)` pocket-entity.js:803 toggles; `layers()` :756 applies `lite()` post-hoc, so cost saved is parse/paint, not string build.
- `PORT` mode (`?port=1`): fewer stars (30), bokeh (28), bar step 8, mesh slots 16; the mock's own "PORT PREVIEW" approximates device with a 233 px soft pass + 466 px crisp pass (`portScreen` mock:690, RGB565 mask).
- Orbit canvas mesh uses `shadowBlur = 7` (orbit.js:287) every frame of an 820 ms transition; DPR capped at 2.

## sim/host_render: how per-frame time is measured

- Build + run exactly: `cd RaBbLE-Pocket/sim && NO_ORBIT=1 ./build.sh census 0 6 0.5 0 0 0` (args: out_name state t_end level roll_deg happy activity; state 0 idle, 1 listen, 2 think, 3 speak, 4 error). Compiles `gcc -O2 -Wall -Wextra` all `nebula_lite/src/*.c` + `scene.c` + `host_render.c`, runs `out/host_render out/census.ppm 0 6 0.5 0 0 0`, converts to PNG. I ran it.
- Harness loop (`sim/host_render.c`): steps `nl_simulate()` at `t += 1/60` from 0 to `t_end`; `sim_ms = t1 - t0` per frame around `nl_simulate` (CLOCK_MONOTONIC `now_ms`); every 30th frame and the last it also renders all bands (16-row, `nl_band_window` + `nl_render_band`, memcpy into fb) and sets `ren_ms`. Only the **final frame's** values are printed (not averages): single-sample, steady-state after easing; `prims = nl_prim_count()`.
- Output (stderr, exact format):
  `repeat frame: 12 of 30 bands same`
  `last frame (host): simulate 0.02 ms, render 0.25 ms, 172 prims`
  then `sim/out/census.png` on stdout. (My run: idle, t=6, level .5, activity forced to 0: 172 prims, 12/30 bands unchanged next frame.) The "repeat frame" line runs one more `nl_simulate` at +1/60 and counts `nl_band_same()` bands (damage test).
- Caveats for a 60 fps budget method: host x86 ms is not device ms (device LX7 240 MHz; the code is written for ~4 M cycles/frame/core); `-O2` host build, no PIE SIMD (C fallbacks `simd_c.c`); `ren_ms` measures all bands, not damage-skipped ones. The device budget method in practice: prim count + per-stage cycles `nl_prof[]` (device log every 10 s) and TE-paced fps; the host gives prim count and band-damage ratio, which are the portable proxies. 16.7 ms frame = ~4 M cycles per core; haze alone costs 3.2-6.9 ms of it. Other sim tools: `sim/xtensa_check.sh` (real Xtensa -O2 -Werror compile of every nebula_lite source), `sim/transition.sh` (Orbit entry/return GIF + contact sheet, needs `build.sh`'s sources), `orbit_scenes.c` (Orbit PNGs + assertion tests, skipped by `NO_ORBIT=1`).
- Env knobs: `UI_SLIDE=px UI_ROLL=deg` for the UI screen over the scene.

## Web frame governor (`mount()` pocket-entity.js:804-830)

- State: `wanted = opts.fps || 60`, `fps = wanted`, `acc/nAcc` (sum and count of rAF intervals), `calm` counter, `lastRaf`, `lastDraw`.
- Every rAF: `acc += now - lastRaf; nAcc++`. When `nAcc >= 45` (about 0.75 s at 60 Hz): `avg = acc/nAcc`, reset. Ladder `steps = [60,45,30,20]`, `i = index of fps`.
  - Step **down** one rung if `avg > (1000/fps)*1.5` and not already at 20 (reset `calm`).
  - Step **up** one rung if `avg < (1000/fps)*1.15`, `fps < wanted`, and this has held for **3 consecutive windows** (`++calm >= 3`, ~2.25 s).
- Frame limiter: skip drawing if `now - lastDraw < 1000/fps - 3` (rAF keeps running). `t` advances by `min(.1, dt)` every rAF, so animation time is wall-clock correct regardless of fps. Paused or hidden: `last = now`, no draw. Gaze easing uses `dtg` since last draw.
- API: `setFps(n)` clamps wanted to 60 or 30 only (so the 45/20 rungs are governor-only); `pause(on)`, `setState(m)`, `stop()`.
- Quirk for the NeBuLA `frame-budget` port: the governor measures **rAF cadence, not draw cost**. After stepping down (e.g. to 30), rAF still ticks ~16.7 ms, so `avg < 1000/30*1.15` is immediately true and it climbs back after 3 calm windows, then falls again if the draw itself is what is slow; it oscillates on a persistently heavy draw. A budget governor should time the draw (as the device does with `nl_prof`/TE) and hold the lower rung with hysteresis. Device has **no** such governor: frame rate is TE-locked 60 with damage skipping; the Port-Plan frame-rate-by-state table (listen/speak 60, thinking 60/45, idle 30) was superseded (S251: 60 idle, 22 floor); `Responsiveness.md:51` lists "steady 30 fps when 60 can't hold" as future W6 spec 8.2.
- NeBuLA existing: `RaBbLE-NeBuLA/.../backends/canvas2d/frame-budget.js` (named in the plan; not read here, out of scope).

## Suggested registry effect names and cost tiers (derived; verify)

| Effect | Cost tier (device terms) | HW | Web-lite | Web-full |
|---|---|---|---|---|
| `backdrop.void` | trivial (fill) | full | full | full |
| `backdrop.wash` + `backdrop.haze` | medium (3.2 ms static, 6.9 moving; breaks damage) | reduced/none today (code exists, disabled) | full | full |
| `backdrop.stars`, `backdrop.databits`, `backdrop.meridians` | low | none (not on HW) | full | full |
| `ring` (+tint/dim/drain-arc) | low | full | full (soft band unblurred) | full |
| `bokeh` | high (soft stamps) | none | none | full |
| `body.fill`, `body.glow` | high | none | none | full |
| `body.bars` (mic bands) | low-medium | none today (plan says full: needs design, no bars on HW) | full | full |
| `body.outline` (braided lens) | medium | none | cores only | full |
| `speak.waves` | low-medium | none | full geometry | full |
| `insight.burst` | low | none | rings | full |
| `mesh.skeleton/edges/nodes/signals` | medium-high (edges dominate) | full (own topology) | full | full |
| `mesh.touch-dent`, `mesh.orbit-handoff` | low | full | handoff API only | same |
| `eyes.orbs`, `portals`, `blink`, `idle-wander`, `flip/withdraw`, `dizzy` | low | full | full | full |
| `strands.mic` (+`absorb` sparks, `mouth-bloom`) | medium-high | full (strands + sparks, no bloom) | full no blur | full |
| `glow.*` (soft strokes, halos) / SVG filters | high | none | none | full |
| `glass.clock/status/state-label/captions/badges` | low (A8 sprites) | full (LVGL text) | full | full |
| `glass.vignette/sheen/reflections` | low-medium | none | partial | full |
| `orbit.transition` | medium (300 prims reserved) | full | full (canvas, shadowBlur 7) | full |
| `boot` | trivial | full | none today | none |
| `ui.slide` | n/a (surface-specific) | full | none | none |

Corrections to the plan's proposed table (`Unified-Entity-NeBuLA-Unification-Plan.md` lines 95-105):
- "Starfield / deep field ... Pocket HW reduced (backdrop wash + stars...)": today HW has neither wash nor stars; it has flat void + ring. Set HW to `none` for stars/haze until `nl_soft` is enabled; wash/haze is `reduced` only conditional on that gate.
- "Mesh ... full on Pocket HW": true, but topology differs (full layer-to-layer links vs 3-nearest); golden-frame parity (U4) will diff.
- "Gaze: none ? on HW": HW has touch-glance and IMU sway already; mark `reduced`.
- "Mic-driven bars: full on HW": HW has no bars; it has mic strands. Split into `bars` (none on HW) and `strands.mic` (full on HW, web: currently synthetic, not mic).
- "Boot animation: full on web": not built (web), device only.
- Ring blur on web-lite is not equivalent to device ring; flag as an effect with `reduced` web variant.

## Files read
`RaBbLE-Grimoire/log/plans/Unified-Entity/Unified-Entity-NeBuLA-Unification-Plan.md` (sections), `RaBbLE-Pocket/AGENT.md`, `RaBbLE-Pocket/firmware/entities/RaBbLE/src/scene.c`, `.../include/nl_scene.h`, `.../nebula_lite/include/{nebula_lite.h,nl_list.h}`, `.../nebula_lite/src/{compose,raster_soft,luts,store,orbit(part)}.c`, `.../src/rabble_entity.c` (partial), `RaBbLE-Pocket/planning/mock/rabble-pocket-entity.html`, `RaBbLE-Pocket/companion-app/web/build-entity.py`, `.../public/entity/pocket-entity.js`, `.../public/orbit.js`, `RaBbLE-Pocket/sim/{host_render.c,build.sh,transition.sh,xtensa_check.sh}`, `RaBbLE-Grimoire/RaBbLE-Pocket/RaBbLE-Pocket-Entity-Port-Plan.md` (perf sections). Not read: `raster.c` internals, `orbit_scenes.c`, `transition.c`. Line numbers marked "~" are approximate (from grep landmarks); others exact. Side effects: ran the permitted sim build (wrote `RaBbLE-Pocket/sim/out/census.*`, `out/host_render`), and a node script in the scratchpad (`cnt.js`) to count web SVG elements.
