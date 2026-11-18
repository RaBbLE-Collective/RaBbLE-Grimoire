# NeBuLA effect inventory (src/effects, src/backends, src/elements)

Paths relative to `RaBbLE-NeBuLA/src/`. Read-only audit; nothing run. Colours are palette tokens where the code uses them; literals are quoted with file:line.
"Backend" key: C2D = canvas2d/ (Canvas2dBackend), 3JS = threejs-backend.js, ALV2 = alive-backend.js 2D (GL-batched via alive-gl.js, or Canvas2D when `renderer="2d"`/no WebGL), ALV3 = alive-backend.js 3D (Three.js, `dimension="3d"`), STANDALONE = factory/class in effects/, used by hosts directly (no backend draws it).

Key finding: no backend calls the `effects/` modules. `EntropyShader`, `EntropyAttractor`, `AnimationFilter` have **no in-repo or Collective consumers** (grep of src, examples, test, studio and the Collective outside node_modules/dist). The same grep found no use of `AmbientField` or `NeBuLA.effects.*` outside `effects/` itself. They are exported API only (index.js:16-21). The visual layers actually on screen live inside the backends.

## 1. Summary table

| # | Effect | Source | Draws | Cost class | Backends today | Enabled by |
|---|---|---|---|---|---|---|
| 1 | starfield | effects/starfield.js:470 | seeded fillRect stars, depth parallax, twinkle, cursor-constellation lines | cheap: ~180 fillRect/frame, up to ~180 stroke()s near cursor | STANDALONE | host calls `effects.starfield(el,opts).start()` |
| 2 | streaks | effects/deepfield.js:46 | rare diagonal signal streaks | cheap | STANDALONE | host |
| 3 | constellation | effects/deepfield.js:122 | lines cursor to nearby seeded points | cheap | STANDALONE | host |
| 4 | haze | effects/deepfield.js:223 | 3 radial-gradient blobs on 1/8-res offscreen, CSS-upscaled | cheap (blur is free upscale) | STANDALONE | host |
| 5 | ambientField | effects/ambient-field.js:277 | baked perspective grid + 100 drifting particles + CSS-blurred glow canvas | medium: half-rate, 3 full-viewport canvases | STANDALONE | host `new NeBuLA.AmbientField(opts)` |
| 6 | entropy shader | effects/entropy-shader.js:7 | GLSL vertex/fragment strings for instanced mesh | per-pixel shader (flat + emissive variants) | none (strings only) | nobody |
| 7 | attractor | effects/attractor.js:10 | CPU entity force (repel/attract by entropy) | O(n^2) pairs, `new Array` + n 3-arrays per call | none | nobody |
| 8 | animation filter | effects/animation-filter.js:11 | CPU transform of entity pos/scale (blink/dart/pulse/orbit/wave) | O(n) | none | nobody |
| 9 | particle nebula (flat core) | canvas2d/particle-system.js:11 | up to 150 arcs, crisp cores | CPU, per-particle path | C2D | `<rabble-entity>` default backend |
| 10 | particle glow bloom | particle-system.js:160 | halo arcs for glowFraction of particles on CSS-blurred glow canvas | + `ctx.filter blur()` only in standalone offscreen mode | C2D | gated by FrameBudget + glowScale |
| 11 | connection mesh (synapses) | canvas2d/connection-system.js:39 | distance-faded lines between particles | O(n^2/4) pairs, one stroke() each | C2D | field layer, budget-gated |
| 12 | portals (arc draw-in + socket) | canvas2d/portal-system.js:140 | opaque socket, arc, two glow strokes | cheap | C2D | `setPortalVisible` (default true) |
| 13 | eyes (orb + halo) | canvas2d/eye-system.js:24 | white ellipse, coloured stroke, radial halo, glow ellipses | cheap | C2D | always on |
| 14 | waveform | eye-system.js:176 | two phase-offset sine lines under the eyes | cheap, 65 pts x2 | C2D | `show-waveform` attr (default false) |
| 15 | glow layer (blurred DOM canvas) | element.js:89-91, canvas2d/index.js:62 | all glow shapes drawn to one canvas, CSS `filter:blur(5px)` | full-size canvas + compositor blur | C2D | always; scaled by glowScale |
| 16 | eye behavior (gaze/blink/jolt) | backends/eye-behavior.js:50 | none (state only) | trivial | C2D, 3JS | shared |
| 17 | 3D particle body | threejs-backend.js:168 | 900 instanced spheres, additive | 1 draw call, per-frame matrix rewrite of 900 | 3JS | `backend="threejs"` |
| 18 | 3D aura | threejs-backend.js:239 | 320 instanced spheres, additive | 1 draw call | 3JS | same |
| 19 | 3D connection lines | threejs-backend.js:349 | up to 200 LineSegments | O(~120^2/2) CPU pair test per frame | 3JS | same |
| 20 | 3D eyes/portals/coronas/rims/arcs | threejs-backend.js:416-705 | shape meshes, line rings | ~25 meshes | 3JS | same |
| 21 | alive: background wash | alive-backend.js:365 | radial gradient void | 1 fullscreen fill | ALV2 | `backend="alive"` |
| 22 | alive: space-time grid | alive-backend.js:388 (2D), 886-890 (3D) | warped floor+ceiling lines, gravity-well dent | CPU line building every frame; 5 alpha bands | ALV2, ALV3 | always |
| 23 | alive: deep-space stars | alive-backend.js:413 (2D), 917 (3D) | 280 2D dots / 1400 3D points streaming sideways | cheap / 1 draw | ALV2, ALV3 | always (dormant 0.35) |
| 24 | alive: aura haze | alive-backend.js:421 (2D), 886 (3D) | 4 radial glows / 4 sprites | 4 gradients | ALV2, ALV3 | always |
| 25 | alive: bokeh | alive-backend.js:433 (2D), 903 (3D) | 120 glow sprites inside the orb | 120 gradient fills | ALV2, ALV3 | always |
| 26 | alive: sphere wireframe + rim | alive-backend.js:441 / 893 | 11 great/small circles x40 pts, pole-coloured, split front/back | 1 stroke per band | ALV2, ALV3 | always |
| 27 | alive: orbit rings | alive-backend.js:463 / 900 | 84 + 56 dots on 2 tilted rings | 140 arcs | ALV2, ALV3 | always |
| 28 | alive: neural mesh | alive-backend.js:264, 473 / 905 | 2x(1+21+7) nodes, links, halos, hot edges | ~58 nodes, ~100+ edges | ALV2, ALV3 | always |
| 29 | alive: signal pulses | alive-backend.js:499 | 28 pooled pulses riding mesh edges | cheap | ALV2, ALV3 | always |
| 30 | alive: lightning lens | alive-backend.js:512 / 915 | 6 strands x91 pts, 3-pass glow stack | 6 paths x3 strokes | ALV2, ALV3 | always |
| 31 | alive: motes + embers | alive-backend.js:530 / 922-931 | 150 motes (340 3D), 46 embers (160 3D) | cheap, scaled by `quality` | ALV2, ALV3 | always |
| 32 | alive: fx (bolts, flashes, rings, sparks) | alive-backend.js:548 / 933-938 | event bursts | pooled, ~10/10/8/160 | ALV2, ALV3 | events() and emotion |
| 33 | alive: face (4-ellipse rig + portal occlusion + dashed flow) | alive-backend.js:562 | portal sockets, orbs with halo, triple-stroke rims, dashed inner ring ("flow") | clip paths; offscreen canvas upload as texture in GL/3D | ALV2, ALV3 (decal) | always |
| 34 | alive: CSS overlays | alive-backend.js:30-32 | scanlines, chroma tint, vignette | 3 DOM layers | ALV2, ALV3 | always (not configurable) |
| 35 | alive: boot text UI | alive-backend.js:36-52 | wordmark, log, bar (DOM, `drop-shadow` filter, CSS animation) | DOM | ALV2, ALV3 | boot |
| 36 | alive-gl batch renderer | alive-gl.js | WebGL stand-in for ctx; mediump shader, 4 modes (gradient LUT, AA disc, AA band, texture) | per-pixel mediump fragment shader, 256x64 LUT | ALV2 | `renderer="webgl"` (default) |
| 37 | floor graph (eyes + portal rings + edges + colour field) | elements/floor.js | Three.js scene | additive meshes, DPR<=2 | `<rabble-floor>` | attrs zoom/pan-x/pan-y |
| 38 | knowledge graph | elements/graph.js | Three.js: eyes, portals, 3 rings, nodes+halos, edges | additive, DPR<=2 | `<rabble-graph>` | setData |
| 39 | doors orbit | elements/doors.js | DOM doors on ellipses (no canvas) | DOM transforms | `<rabble-doors>` | attrs count, speed |
| 40 | SVG glow (drop-shadow) mini/eye/ring | ui/entity-mini.js:121-139, grimoire-eye.js:41-119, grimoire-ring.js | SVG `filter:drop-shadow`, CSS keyframes | per-element filter | ui factories | host |

Not found: any Ball (top-down Three) code, any Terminal code, any audio-level / mic input (grep analyser/getUserMedia/audioLevel: none). "Mic-driven bars" in the plan table has no implementation here; the nearest thing is the waveform (#14), which is driven only by entity state.

## 2. Per-effect parameters

### 1 starfield (effects/starfield.js)
- count 180 (:474), mobile cap 100 when innerWidth <= 700 (:516-517)
- drift 1.0 (:475); drift speed 0.0000045 * drift (:540)
- depthLayers 3 (:476) is stored but never read (dead param)
- palette null = resolved from CSS vars --magenta/--cyan/--violet/--pink/--text (_palette.js:12-19). Fallback literals in _palette.js:14-18: '#ff2d78','#00f5ff','#bf5fff','#ff79c6','#e8e6f0'.
- hardcoded: dpr cap 1.25 (:505), z range 0.15-1.0 (:527), star size z*1.7 (:548), alpha 0.18 + twinkle*0.5*z (:549), twinkle 0.45+0.55*|sin| at 0.0011*z (:547), parallax 36 px x / 24 px y (:545-546), constellation radius 130 (d2<16900 :566), line alpha 0.22 max (:567), lineWidth 0.6 (:561). Tints: text x3, cyan, magenta, violet (:518-521).
- Inputs: time (performance.now), pointer (mousemove/touchmove window listeners :597-598), resize.
- Cost: no per-frame allocations beyond strokeStyle strings (hexAlpha builds a string per line, :568); canvas = host size x dpr (<=1.25).

### 2 streaks (effects/deepfield.js:46)
- spawnProb 0.0022 (:49), decay 0.016 (:50), glitch false (:52; glitch raises spawn to >= 0.02 :69), palette null.
- hardcoded: vx 3-8, vy 1.5-4 (:74), lineWidth 1.1 (:84), tail length 6x velocity (:87), alpha life*0.7 (:83), tint random cyan/magenta (:76).
- Inputs: time only (per-frame step). Allocs: object per spawn, splice on death, string per streak per frame.

### 3 constellation (deepfield.js:122)
- maxDist 130 (:125), alphaScale 0.28 (:126), count 180 (:127; mobile cap 100 :147-148), points null (shared 0..1 set), glitch false (tint becomes magenta, :159).
- lineWidth 0.6 (:160). Inputs: pointer. Note: a second, separate seed from starfield unless `points` is shared.

### 4 haze (deepfield.js:223)
- blobs 3 (:226), resScale 0.125 (:227), repaintEvery 4 (:228), glitch false (alpha x2.2 :273).
- 3 prototype blobs (:248-250): violet {x .22,y .30,r .55,a .045}, magenta {x .80,y .68,r .60,a .035}, cyan {x .55,y .12,r .45,a .030}; extra blobs random r 0.4-0.65, a 0.03-0.05. Drift sin at 0.00003 / 0.000024 (:269-270).
- Cost: hidden canvas = w*0.125 x h*0.125; visible canvas full size, drawImage upscale every 4th frame. Visible canvas not dpr-scaled (width=w, :240).

### 5 ambientField (effects/ambient-field.js)
- opts: particles true, grid true, n 100 (:280-282)
- GLOW_EVERY 3 (:264), GLOW_FRACTION 0.12 (:265)
- COLS (:256-262): 22 hard-coded hex literals (blues, cyans, violets, whites); not palette tokens.
- grid (bake :331): vanishing point (W/2, H*0.74) (:333); 19 fan lines (i<=18) stroke 'rgba(191,95,255,0.10)' lw 0.8 (:341-342); 12 rows (j<=11) pow 1.65, 'rgba(255,45,120,0.12)' lw 0.6 (:350-353). These are violet/magenta literals, not tokens.
- particles: vx +-0.055, vy +-0.04 (:364-365), r 0.3-2.5 (:366), alpha 0.08-0.53 (:368), phase += 0.022 (:399), wrap margin 8 (:400).
- glow canvas CSS `filter:blur(8px)` (:300), z-index 0 fixed; main canvas z 0 fixed (:292).
- Inputs: time only. No pointer.
- Cost: 3 full-viewport canvases (cv, glowCv, gridCv) at 1x (no DPR), half-rate (skip odd frames :382), glow buffer redrawn every 3rd draw frame, grid baked once. Static flat particles use one beginPath+fill each.

### 6 EntropyShader (entropy-shader.js)
- displacementScale 0.1 (:9), colorVariance 0.15 (:10), animationSpeed 0.5 (:11; never used in the shader strings).
- Uniforms u_time, u_entropy. Vertex: sin/cos displacement along normal; fragment flat mixes colour by entropy*colorVariance*0.33 (:68), emissive by entropy*colorVariance (:96) plus `color += color*emissive*2.0` (:98). precision highp.
- Cost: per-pixel (fragment sin/cos x3) when used; per-vertex sin/cos. Cannot run on the device (no shaders). Not wired to threejs-backend.js (which uses MeshBasicMaterial).

### 7 EntropyAttractor (attractor.js)
- strength 0.3 (:112), threshold 0.6 (:113), radius 5.0 (:114), minDist 0.5 (:115). avgEntropy > threshold repels, else attracts; magnitude strength*(1-d/r)*dt.
- Inputs: stream entities (position, entropy), dt.
- Cost: O(n^2); allocates forces array + n triples per call.

### 8 AnimationFilter (animation-filter.js)
- cycle 4.0 s (:182), amplitude 1.0 (:183). Types blink, dart, pulse, orbit, wave. Constants: blink phases 0.1/0.15/0.25, min scale 0.1 (:215-221); dart window 0.85-0.95, index*0.7 offset (:226-228); pulse 0.15*amp*entropy (:237); orbit 0.01 scale (:247); wave 0.05 (:253); time wraps at 10000 (:194).
- Inputs: dt, entity.entropy. O(n), no allocations.

### 9-11 C2D particles, glow, connections
Particle cfg (particle-system.js:20-32): glowFraction 0.30, orbitSpeedMultiplier 1.0, sizeMin 1.0, sizeMax 8.5, bloomRadius 4. Constants: NEBULA_RADIUS 130, FALLOFF_RADIUS 155 (:9); PARTICLE_COLORS 21 hex literals (:1-7, e.g. '#1a4aaa'...'#ffffff'), not palette tokens; target ellipse y x0.80 (:40); alpha 0.18-0.83 (:47); speed 0.004-0.015 (:50); cs 0.012-0.044 (:51); glow rScale 1+(0.3+settle*0.45)*effectiveGlow*(1+entropy*1.5) (:174); glow alpha min(1, alpha*1.2) (:178). Physics runs every other frame outside boot (:90-91); entropy multiplier eMul = 1+entropy*2.5 (:94).
- element.js: particle-count default 150, cap 150 desktop / 100 mobile (:143-147; the header comment at :19 still says 260/300). Backend default fallback is 480 (canvas2d/index.js:19) but element always passes a count.
- Inputs: time (frame counter t), entropy (`setEntropy`, default 0.3, index.js:55), boot state, `effectiveGlow` = glowScale * adaptiveGlow.
- Offscreen/standalone glow mode (:182-211, no external glowCanvas): full canvas offscreen, cached every 2-4 frames, composited with `ctx.filter = blur(round((bloomRadius+entropy*5)*effectiveGlow)px)` (:204-207). That path is the expensive one; element.js always passes an external glow canvas so it is not used there.
- Per-frame allocations: `_visibility()` returns an object per glow particle per frame (:121).
Connections (connection-system.js): STEP 2 (:12), MAX_DRAWN_CONNECTIONS 200 (:15), HASH_CELL_SIZE 100 (:16), HASH_REBUILD_INTERVAL 4 (:17). Idle: baseAlpha settle*0.18+entropy*0.14 (:105), connDist 62+settle*20 (82 px) (:106), alpha f^2 (:122), lineWidth 0.55. Boot: connAlpha progress*0.15, dist 35+progress*47, spatial hash with string keys and array allocs (:23-24, :32) every 4 frames. Colour = source particle colour. Cost ~(75)^2/2 ~ 2.8k distance tests + up to ~hundreds of stroke() per frame.

### 12 portals (portal-system.js)
- Geometry from eye-behavior.js:25-33: EYE_W 38, EYE_H 110, EYE_GAP 36, BASE_Y_OFFSET -6, PORTAL_W 90, PORTAL_H 28, MAX_OFF 13, PORTAL_OFFSET_RATIO 0.44.
- Colours palette.cyan (left) / palette.magenta (right) (:164-165). Socket gradient literals '#000000','#010108','#010008' (:172). Arc lineWidth 2.2 (:190); glow strokes lw 11 @ alpha 0.32 and lw 5 @ 0.78 (:199-201); arc head dot r 3.5 '#fff' (:210) + glow r 9 @ 0.35 / r 5.5 @ 0.8 (:214-217). Arc steps ceil(frac*80)+1 (:178); right portal delayed by 0.08 (:165).
- Inputs: boot timeline (bootSeq). Note: C2D portals do NOT draw the dashed flowing inner ring; that exists only in the alive face (#33).
- Allocation: radial gradient created per portal per frame (:171); arc path rebuilt twice per portal per frame (buildArc x3).

### 13 eyes (eye-system.js)
- eye fill literal '#f8faff' (:150), stroke lw 3 (:152), halo size EYE_H*(0.55+0.08 sin(t*0.022)) (:141), halo colour `col + '38'` (:143), glow fill 'rgba(220,235,255,0.22)' (:162), glow outline lw 6 @ 0.4 (:166-167), blinkScale 1 - blinkT*0.93 (:90), iris clamp pW2 - eW2*0.55 (:104), orb offset 0.7x/0.5x gaze (:117-120).
- EyeBehavior cfg (eye-behavior.js:58-66): saccadeMode 'normal', blinkIntervalFrames 100 (+rand 0-150), distractionFreqFrames 120 (+rand 0-180), joltDecay 0.94, snapDecay 0.92, springStrength 0.12, dampingFactor 0.72. MOUSE_NEAR_DIST 600 (:35). Saccade table SACC 19 entries (:42-48). Spring scales 1.167x near mouse / 0.833x far (:133 in the file's offset listing).
- Inputs: window mousemove (clientX/Y), click (jolt), entity state (idle/thinking/speaking), boot timeline.

### 14 waveform (eye-system.js:36-42, 176)
- idle {amplitude 2.0, frequency 0.09, speed 0.005}; thinking {4.5, 0.13, 0.007}; speaking {7.5, 0.20, 0.011}. Position cy+68, x +-64 (:182), step 2 px, breathe 1.2+0.8 sin(t*0.018), line lw 1.9, glow lw 7 @ alpha*0.7. Colours palette.magenta / palette.cyan. Input: entity state + frame counter. Enabled by `show-waveform` (default false, element.js:156 via parseBool).

### 15 glow layer / compositing (element.js, canvas2d/index.js)
- Glow canvas CSS `filter:blur(5px)` (element.js:91); the comments in index.js:30 and ambient-field.js say 8px (stale for entity; AmbientField really is 8px at :300).
- glowScale 1.0, or 0.35 when isMobile (rawDpr > 1.5 and window < 800x600) (element.js:100-103). adaptiveGlow ramps 0 to 1 over 180 frames after boot with easeInOut (index.js:112-114), drops x0.85 to a floor of 0.3 when measured fps < 40 (index.js:129-131).
- Canvas size = host size x overscan (default 2.35; 1.2 if innerHeight < 500; 1.8 if host < 220x160) x perfDpr (DPR capped 1.5 only on mobile) (element.js:110-122). Three canvases of that size: field, glow, entity. For a 460x320 host that is 1081x752 css px per canvas.
- Centre point cy = h*0.47 (index.js:~71 in _updateCanvasSize).

### 17-20 Three.js backend (threejs-backend.js)
- BODY_COUNT 900, AURA_COUNT 320, MAX_INSTANCES 4096 (unused) (:15-21).
- Scene bg `0x020008`, fog `Fog(0x020008, 40, 120)` (:59-60): hex literals, not tokens. Camera fov 65, position (0,0.3,4.6) (:63-69), orbit radius 3-20 (:145), phi clamp 0.3..pi-0.3, auto-rotate 0.0001 rad/frame (:86). DPR cap 2 (:39). Renderer antialias true, alpha false, high-performance (:72-74).
- Body: sphere 8x8, MeshBasicMaterial opacity 0.46 additive (:176-181); radius 0.3 + rand^0.45 * 1.7 (:200), y squash 0.8, +0.3 lift; colour violet-to-cyan ramp mix^1.4, 8% 'spark' {0.86,0.92,1.0} literal (:194,221), 14% magenta; instance size 0.028-0.103 (:226); drift 0.15*(1+entropy*0.5) (:303).
- Aura: sphere 6x6 opacity 0.35 additive (:240-246); r 2.2-6.2; z > 2.0 mirrored behind (:276); size 0.025-0.095; drift 0.3*(1+entropy*0.8) (:326).
- Connections: maxLines 200 (:350), LineBasicMaterial colour `0x4499ff` opacity 0.12 (:357-360), maxDist 1.2 + entropy*0.8 (:378), step BODY_COUNT/120 = 7 (:381), opacity convergence*(0.08+entropy*0.12) (:411). Recomputes sin/cos drift for ~129 points x pairs each frame: ~8k pair tests, 6 trig per point each pair (:387-396), allocation-free but heavy trig.
- Eyes/portals (:416-705): xRadius 0.18, yRadius 0.52, left/right pos (-0.38/0.38, 0.55, 1.6), portalOffsetY 0.44*(0.52*2), corona 2.3x/1.5x opacity 0.20, inner 1.18x/1.08x @ 0.36, ring glow 1.55x/1.32x @ 0.28, rim annulus opacity 0.42, ring Line opacity 0.85 `linewidth: 2` (ignored by WebGL), eye fill 0xf8faff (:528), arc lines opacity 0.9.
- Per-frame: `new THREE.Matrix4()` per `_updateParticleMatrices` call (:296), 1220 setMatrixAt with trig, full instanceMatrix upload (needsUpdate :321). `this._time += 0.016` (fixed step; frame-rate dependent).
- Inputs: time, entropy (`setEntropy`, state -> 0.3/0.6/0.8), pointer (EyeBehavior + orbit drag/wheel), boot.
- Enabled by `backend="threejs"` (element.js:167-196), falls back to C2D without WebGL.

### 21-36 alive backend (alive-backend.js)
Backend resolution: `backend="alive"` mounts `createAlive` (element.js:57, 209). Tunables are opts + the STYLE/MOOD tables, all live-driven by `state`, `mood`, `emotion` attributes.
- opts defaults (:70-84 doc block): autoboot false, autonomous true, dimension '2d', interactive true, trackWindow true, holdToListen false, skippable true, stepTimeout 45, renderer 'webgl', profile (PROF) off (:1057).
- Boot timeline BOOT (:196): grid [0,1.6], motes [0,2.8], sphere [.9,2.3], portalArc [.4,3.4], eyeRise [1.8,4.2], blinks 4.25, mesh [2.2,4.2], lens [2.9,3.9], orbit [3.0,4.1], bokeh [1.4,3.2], logStart .7, logEnd 7.0, ready 7.4, slide [7.6,9.8], shock 9.6, idle 10.2 (seconds).
- Emotion STYLE (:219-224): fields energy, glow, tempo, bounce, hop, trem, gazeY, orbit, sphere, lens, jit, pulse, strike, surf, grav, bpm, sparkle, sigh, dim, stiff. calm {energy .05, glow .5, tempo .8, orbit .7, lens 1, jit 1, pulse .8, strike .6, surf .7, bpm 46, dim 1, stiff 50}; joy {energy .3, glow .8, tempo 1.2, bounce 6, hop .8, orbit 1.5, pulse 1.6, strike .9, surf 1.2, grav -4, bpm 70, sparkle .6, dim 1.08, stiff 70}; sad {energy .02, glow .4, tempo .6, gazeY 6, orbit .45, sphere -.04, lens .92, pulse .5, strike .3, surf .45, grav 18, bpm 42, sigh 1, dim .82, stiff 35}; angry {energy .45, glow .85, tempo 1.2, trem .5, orbit 1.6, sphere .14, lens 1.05, jit 1.8, pulse 1.8, strike 2, surf 1.8, bpm 84, dim 1.04, stiff 90}.
- Mood fx MOOD_FX (:122-128): idle/ponder/process/insight/curious each {squint, gx, gy, dart, pulse, spin, tilt}; MOOD_DUR (:129).
- Camera/layout: cam.vw 1600/1300/1150/1000 by aspect (:172), ENTITY_H 760 (:189), E.s settles via finalS (portrait base 1.35), dprCap 2 (GL) / 3 (2D) (:168), 3D renderer pixel ratio min(dpr, dprCap, 2.5) (:98 listing), FS face texture 1024 (768 on mobile UA) (:940), 2D GL face texture = ceil(820*.7*E.s*cam.s*DPR /64)*64 clamped 64-2048 (:615).
- #21 background: radial gradient `C.glow` (PAL.surface) to `C.void` (PAL.bg), centre (W/2, H*.45), radius max(W,H)*.75 (:365-368).
- #22 grid (:378-410): GAP 240, WELL {A 150, SX 640, SZ 520}, RAY 340, ROW 400, EXT 9000, BANDS 5 (alpha bands by depth), P2 {el .02, D 1700}, line width 1.6, floor colour pink @ .75, ceiling cyan @ .5 (C.pink / C.a), fade exp(-(d/8200)^2*2.4), horizon ignition line lw 2.2 colour C.eye. Gravity well k = (1 + energy*.25 + heart*.08) scaled by boot (:382). 3D adds EXT3 12000 with 1100/160 coarse/fine breakpoints (:116-119).
- #23 stars: 2D 280 dots, r .5-2.2, z .15-1 (:411), speed (90+energy*140) px/s, alpha .9*z*(.35+.65 noise)*sty.dim; 3D SN 1400 points x 9000/2600/14000 box (:71-72). Colour C.nebula (8 entries: cyan x4, violet x2, text x2, :154-155).
- #24 haze 2D: four radial glows [-170,0,450x382 poleL .34], [170,0,460x390 poleR .26], [0,0,320x272 violet .3], [0,0,380x380 violet .12], brightness (.8 + .3 noise + energy*.4 + heart*.25)*dim (:421-428); 3D: 4 sprites at z -80 with sizes 900/920/640/760 and opacities .5/.38/.42/.18 (:886).
- #25 bokeh: 120 glow sprites, r 6-24, op .16-.45 in a 270 px orb x1.1 (:283); 3D scale b.r*3.4.
- #26 sphere: R 265, 6 meridians + 5 latitudes at [-1.05,-.52,0,.52,1.05] x 40 segments (:290-293), rim glow lw 10 @ .3 and lw 2.2 @ .85, front lines lw 1.7, back lines C.eye @ .14, yaw/pitch/roll driven by fbm noise; yaw speed .1+.09 fbm + energy*.45 + sty.sphere + moodFx.spin (:444). 3D rim RIM 72 segments (:50), glow shell sprite 760 @ .18 violet (:51).
- #27 orbits: rings [84 dots, r360] and [56 dots, r318] (:466), dot r (1.1+(z+1)*1.5)*E.s, alpha .55-1 front / .14 back; colours poleL/poleR, C.violet/C.eye.
- #28 mesh: layers L [[8,140,320,.66,40],[7,300,450,.54,34],[6,430,575,.44,26]] + anchor + 7 rim nodes per side (:266); pointer repel radius 240, force 75 (:477-478), wave 22*sin(time*.85...), edge strokes glow lw 7 @ .13 + core lw 1.6 @ (.55+energy*.2); hot edges lw 12 @ .3 + C.eye lw 2.2 @ .9; nodes r 5-7.
- #29 pulses: pool 28 (:282), speed 260-480 px/s inbound, 320-560 outbound, spawn gap rnd(.06,.28)/(pulse*(1+energy*2)*moodFx.pulse) (:504), trail lw 3.5 @ .75, halo r 13, core r 3.6.
- #30 lens: 6 strands (amp 330/300/250, w 4/2.2/1.4, spd 1/1.4/1.9) x 91 points, 3-pass stack lw w*5 @ .1, w*2.2 @ .3, w @ 1 (C.eye); re-jitter every .14 s (:515).
- #31 motes: 150 (3D 340), r .8-2.6, life 5-11 s (boot 1.2-2.4), pull 18+energy*30, respawn at view edge; embers 46 (3D 160), colour C.pink (3D 70% pink / 30% C.eye), rise 25-75 px/s. Count scaled by `quality`.
- #32 fx pools: sparks 160, flashes 10, rings 8, bolts 10; bolt jag depth 6 re-rolled every .045 s (:548-550); strike cadence rnd(2.5,7)/(1+energy)/max(1,sty.strike) and surface bolts rnd(.3,1.4)/max(.2,sty.surf) (:823-825). Suppressed when `prefers-reduced-motion` (events() returns).
- #33 face: ELS eL/eR/pL/pR with spring params; EYE_RX 43.5, EYE_RY 136, POR_RX 117, POR_RY 35, EYE_X 92, POR_OFF 126 (:202); portal halo, triple-stroke rims (lw 6: w*3.7 @ .12, w*2.2 @ .3, w @ 1, :359), dashed inner ring `setLineDash([30,30])`, offset -time*(80+energy*320), lw 2 @ .7 (this is the "flowing" portal ring), clip-path occlusion. `setLineDash`/clip are NOT supported by alive-gl, which is why the face renders to an offscreen Canvas2D and is uploaded as a texture.
- Heartbeat: bpm from emotion + energy*20 (:820). Breathing/noise: value noise table 1024 floats, fbm of 3 octaves (:147-149).
- #34 CSS overlays: `.rbl-scan` repeating-linear-gradient rgba(0,0,0,.05) 1px/3px; `.rbl-chroma` magenta/cyan 1.5% gradient via color-mix; `.rbl-vig` radial transparent 52% to 82% bg (:30-32). Not toggleable; they are DOM layers that also exist on the device only if re-implemented.
- Inputs consumed: pointer (window or canvas; `track-window`), press/hold, entity state, mood, emotion, boot steps from host, `setEntropy` (sets `energy`, 0-1), time (real dt clamped .05, x.4 under reduced motion), prefers-reduced-motion. No audio.
- Adaptive quality (:1061-1065): emaDt EMA .95/.05; when emaDt > 0.045 s (~22 fps) for 2 s: quality -0.15 down to .5 (thins motes/embers), then lowers dprCap by .5 toward 1.
- Allocation per frame: `new P2D()` (Path2D or GL recorder) for each band/mesh/lens/bolt path every frame (e.g. :400 bands x5 x2, :487 base/hot x2 per side, :517 per strand, :549 per bolt); `breaks()` arrays per frame (:384); nodeWorld() returns an object per call (:472). Heavy GC churn but pooled where it matters (sparks etc.).

### 36 alive-gl.js
- Single program: vertex pass-through (:17-19), fragment `precision mediump float` 4 modes (gradient LUT row, AA disc, AA band, texture) (:20-29). LUT 256 x 64 rows (:31-32), FLOATS 11 per vertex. Colour cache 512 entries (:41). Blend: 'source-over' or 'lighter' (additive) only. Supports no clip, no dash, no polygon fill. Cost: one batched draw set per frame; per-pixel cost is a texture fetch or AA arithmetic; the face texture upload each frame (`drawTexture`) is the largest fixed cost (up to 2048 px square).

### 37-40 elements and ui
- floor.js / graph.js: Three.js (r160, three-loader), DPR cap 2 (:95, :91), colours as 0x literals (0x00f5ff, 0xff2d78, 0xf8faff, 0x010108, 0x1a2a44) at graph.js:140-239 rather than tokens; corona opacity .12, inner .28, ring glow .20, portal rings .60, neural lines .18, node r NODE_R / halo .18. floor.js also uses palette corners C00..C11 as byte arrays (:35-38) with literals documented as the Palette. Floor attrs zoom, pan-x, pan-y (floor.js:647).
- doors.js: pure DOM; attrs count, speed (:52); accents are `var(--magenta|cyan|violet|pink)`.
- ui/*: SVG `drop-shadow` filters (entity-mini.js:121-139: 0.8-1.4 px; grimoire-eye.js:41-52: 3-4 px; grimoire-eye.js:119 hard-codes `#bf5fff` in a style string) and CSS keyframes; blur filters are not portable to the device.

## 3. frame-budget.js (canvas2d/frame-budget.js)

- Class `FrameBudget`; used only by Canvas2dBackend (index.js:63, 129, 160). Not used by 3JS or alive (alive has its own `quality`/`dprCap` governor, above).
- TARGET_MS 14 (:19), EMA_ALPHA 0.15 (:20, about a 7-frame window). Constructor takes targetMs.
- Per-system EMA cost table keyed by name: 'eyes', 'portals', 'particles', 'connections', 'field'. `record(name, ms)` updates EMA and resets skip counter (:80-86).
- `beginFrame()` (:35-52): reservedAlways = eyes + portals cost; remaining = max(0, 14 - reserved). Decisions made once per frame from EMA, not live remaining.
  - Glow (hysteresis): off when predicted particle cost > remaining; back on when < 0.75*remaining.
  - Connections: allowed if reserved + (glow ? particle cost : min(particle cost, 4)) + connections cost <= 14.
- `canGlow()`, `canDraw(name, maxSkips=Infinity)` (:62-77): connections get binary skip; generic path skips if EMA cost > remaining, forced draw once skips >= maxSkips. The backend calls `canDraw('field', 2)` so the whole field layer (particles + connections) can be skipped for at most 2 consecutive frames, holding the last painted canvas (index.js:~158).
- `shouldSkipFieldUpdate()`: true if 'field' was skipped last frame; backend then skips particle physics (index.js:134).
- `metrics` getter exposes costs, remaining, target, glowAllowed, connectionsAllowed (surfaced in `getPerformanceMetrics()`).
- Tiers are effectively: (1) always draw: eyes, portals; (2) field layer may skip up to 2 frames; (3) within field: glow off, then connections off; there is no named quality tier enum. Other governors in the Canvas2D path: adaptiveGlow floor 0.3 below 40 fps (index.js:129); particle physics every other frame (particle-system.js:90); mobile caps (element.js:99-147).

## 4. Layer order and compositing today

Canvas2D entity (element.js:74-97, canvas2d/index.js:_draw):
1. DOM, bottom to top (all inside `<rabble-entity>`, `isolation:isolate`, z-index 1): field canvas (z 0: particles + connections), glow canvas (z 1, CSS `blur(5px)`), entity canvas (z 2: portals, eyes, waveform).
2. Per frame the backend clears glow canvas, then entity canvas, draws portals then eyes (glow shapes go to the glow canvas), then the field canvas gets particles then connections. Because glow is a separate blurred canvas under the entity canvas, the opaque portal fill hides glow bleed (portal-system.js:169-170 comment).
3. Page-level: AmbientField canvases are `position:fixed; z-index:0`, glow (blur 8px) inserted before the flat canvas, both at document.body start; the entity sits above at z 1 (element.js:63).
4. Standalone effects (starfield, haze, streaks, constellation) each append their own absolutely positioned canvas into a target element; no shared ordering mechanism, order is DOM append order.

Alive 2D (GL path), per frame (:1068-1084): background gradient, grid (source-over), then `globalCompositeOperation='lighter'` for stars, haze, motes+embers, mesh, bokeh, sphere, lens, pulses, orbits, fx; back to source-over; face drawn as a texture. The Canvas2D fallback uses the identical order (:1086-1092). DOM overlays above the canvases: scan, chroma, vignette, then boot UI.
Alive 3D: `drawMesh/Sphere/Lens/Pulses/Fx(dt,false)` run only for simulation; `T3.frame` renders scene (haze sprites z -80, floor/ceiling fat lines, sphere wire + rim, shell sprite, orbits, bokeh sprites, mesh, pulses, lens, stars, embers, motes, sparks, flashes, bolts, rings) with additive blending; the face decal is a plane with `renderOrder = 10` and a camera-facing quaternion, mirrored from behind (:95-96, :1043-1046).
Three.js backend: render-group order added to scene: entity (body, aura), connections, portals, eyes (:94-97); transparency order by Three; portals mesh z -0.02 and eyes z around +1.6 give occlusion.

## 5. Notes for the registry / portability

- Genuinely portable "idea" effects (no per-pixel shader, no blur): starfield (1), constellation (3), streaks (2), portals (12), eyes (13), waveform (14), connections (11, with a cap), alive mesh/pulses/lens/orbits/motes (28-31), sphere wire (26), grid (22, lines only).
- Cost-bearing / not device-portable: glow layer via CSS blur (15), standalone offscreen glow with `ctx.filter blur` (10 offscreen mode), AmbientField blur canvas (5), haze (4) (needs gradients plus upscale; the plan already marks "backdrop wash + stars" as the reduced form), entropy shader (6) (per-pixel), CSS scan/chroma/vignette overlays (34), drop-shadow SVG (40), face texture upload and Three.js backend (17-20, ALV3).
- Param keys that already exist as natural registry fields: starfield {count, drift}, streaks {spawnProb, decay}, constellation {maxDist, alphaScale, count}, haze {blobs, resScale, repaintEvery}, ambient {particles, grid, n}, particle cfg {glowFraction, orbitSpeedMultiplier, sizeMin, sizeMax, bloomRadius}, waveform per state {amplitude, frequency, speed}, eye cfg (7 keys above), alive STYLE rows, `particle-count`, `overscan`, `glowScale`, `entropy`, `quality`.
- Colours: several tables are literals, not tokens (will need tokenizing for the registry): ambient-field.js:256-262 COLS and :341-350 rgba, particle-system.js:1-7, threejs-backend.js:59-60,194,357,528, graph.js:140-239, portal-system.js:172,210, eye-system.js:150,162, ui/grimoire-eye.js:119. Palette-token users: palette.js (puppet) in portals/eyes/threejs; alive uses PAL=readPalette(host) (C.a, C.b, C.violet, C.pink, C.void, C.glow, C.eye).
- Doc/code mismatches worth fixing in the registry pass: element.js:19 header says particle-count default 260 capped 300/160 but code is 150/100 (:143-147); depthLayers in starfield is unused; EntropyShader.animationSpeed unused; MAX_INSTANCES (threejs) unused; glow blur 5px (element.js:91) vs 8px in comments; `NeBuLA.backends` lists only Canvas2D and Three.js although alive is a third backend (index.js:41); ThreeJsBackend uses fixed `_time += 0.016` and `linewidth: 2` which WebGL ignores.
- Surfaces not present in this repo: Ball (top-down Three), Terminal, Pocket HW (nebula_lite C). Mic/audio input is absent.
