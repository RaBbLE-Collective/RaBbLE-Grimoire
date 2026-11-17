# Harvest Map — Effects Second Pass

> Focused effects-only sweep. Resolves the 4 stubs from `harvest-map.md` with real source, then sweeps for ambient/visual effects the component-biased first pass under-covered.
>
> **DATE:** 2026-06-26
> **SCOPE:** Chrysalis ep1 `liminal.js / RaBbLE-Grimoire.js / RaBbLE-chat.js / RaBbLE-Studio.js` + CSS; World `movements.js / stage.js / floor.css / *.css`
> **METHOD:** Read actual implementations, extract real file:line + params

---

## Stub Resolution (the 4 targets)

The whole deep-field is one canvas engine in Chrysalis `RaBbLE-liminal.js` (703 lines, REAL code). The `space` object (`liminal.js:239–244`) holds `stars`, `streaks`, `blobs`. All four stubs are implemented there — not conceptual.

### 1. Signal/Data Streaks
- **Name:** Signal Streaks (rare passing transmissions)
- **Target:** `NeBuLA.effects.streaks`
- **Best source:** `liminal.js:367–387` (spawn + integrate/draw); pool init `:243`
- **Params:** spawn probability (`0.0022` normal / `0.02` glitch), `vx` (3–8), `vy` (1.5–4), `life` decay (`0.016`/frame), tail length (`vx*6`), tint (cyan|magenta), spawn edge (top vs upper-40%), alpha = `life*0.7`, lineWidth `1.1`
- **Notes:** REAL CODE. Canvas2D line segments with velocity + decay. Trivially parameterized into a generic NeBuLA effect (count, speed range, tint set, glitch-multiplier, spawn rate).

### 2. Constellation Lines (cursor reach)
- **Name:** Constellation Reach (lines to cursor)
- **Target:** `NeBuLA.effects.constellation`
- **Best source:** `liminal.js:348–365`
- **Params:** reach radius `130px` (d² threshold `16900`), per-line alpha = `(1 - dist/130)*0.28`, lineWidth `0.6`, tint cyan (magenta when glitching), source = each star's screen pos (`_sx/_sy` cached in star draw)
- **Notes:** REAL CODE. Depends on starfield star positions (coupled — constellation reuses the parallax-projected star coords). Generic version needs a point set + a focus point (cursor). Respects `prefers-reduced-motion` (skipped).

### 3. Nebula Haze / Gradient Fog
- **Name:** Nebula Haze (low-res radial blobs)
- **Target:** `NeBuLA.effects.haze`
- **Best source:** `drawHaze()` `liminal.js:306–322`; blob seed `:279–283`; sizing `:296–297`
- **Params:** blob list `{x, y, r, tint, a, dx, dy}` (3 blobs: violet/magenta/cyan, alpha 0.030–0.045), radius = `r * max(w,h)`, drift via `sin/cos(t*~3e-5)`, glitch alpha ×2.2, **renders at 1/8 resolution** then CSS upscales (GPU smear = free blur), repaint every 4th frame
- **Notes:** REAL CODE. The 1/8-res-canvas-then-CSS-stretch trick is the key knob to preserve — cheap fog. Generic params: blob count, tint palette, base alpha, drift speed, downscale factor, repaint cadence.

### 4. Orbiting Doors / Threshold
- **Name:** Orbiting Portal Doors (cosmic-disc threshold)
- **Target:** `<rabble-doors>`
- **Best source:** `buildPortals()` `liminal.js:400–429`; `layoutOrbits()` `:431–457`; data `PORTALS :27–88`; parallax tilt `:603–613`
- **Params (orbit math):**
  - door count = `PORTALS.length` (6)
  - initial angle `theta = (2π/N)*i − π/2`
  - angular velocity `omega = 0.05 + 0.011*(N − i)` (inner doors faster)
  - radius ladder `ring = 0.55 + 0.085*i`
  - base radius = `min(planeW*0.40, planeH*0.55)`
  - **squashed Y plane** `y = cy + sin(theta)*r*0.42` (cosmic disc, not circle)
  - depth = `(sin(theta)+1)/2` → drives `scale = 0.78 + depth*0.30`, `zIndex` 30/10 (front/back of core), `opacity = 0.55 + depth*0.45`
  - hover slows orbit (`slowTarget 0.08`, lerp `0.06`); glitch adds wobble `sin(now*0.02+i)*0.06`
  - plane parallax tilt: `rotateX((py-0.5)*-5deg) rotateY((px-0.5)*5deg)`
  - compact ≤700px: orbit disabled, CSS grid takes over (`layoutCompact :459–467`)
  - CSS companion: `.portal-orb` 52px, hover `drop-shadow(0 0 14px accent)` + glow ring; horizon ring `ring-drift 26s` rotateX(72deg) (`liminal.css:148–164`)
- **Notes:** REAL ~700-line code. Each door passes behind/in front of the entity core via z-index swap. Per-portal: glyph, name, organ, accent, whisper card, url. This is the richest single effect in the archive.

---

## New Effects Found

Effects not yet in Aether/NeBuLA that the first pass missed or under-specified.

### Starfield (depth-parallax twinkle)
- **Name:** Parallax Starfield
- **Target:** `NeBuLA.effects.starfield` (NeBuLA — canvas)
- **Best source:** `seedSpace() liminal.js:267–278`, `drawSpace() :332–346`
- **Params:** count (100 compact / 180 desktop), depth `z` 0.15–1.0 (parallax + size), tint weights (3× text, 1× cyan/magenta/violet), twinkle `0.45 + 0.55*|sin(tw + t*0.0011*z)|`, parallax offset `-px*36*z / -py*24*z`, drift `t*4.5e-6`, alpha `0.18 + twinkle*0.5*z`. Uses `globalAlpha` + precomputed solid fill (no rgba churn).
- **Notes:** REAL CODE. First pass marked "240 points" from the AMBIENT copy string — actual is 100/180. Stars cache screen pos for the constellation effect → starfield + constellation should ship as one coupled module.

### Glitch Veil (chromatic stutter wash)
- **Name:** Glitch Veil
- **Target:** Aether `.rabble-glitch-veil` (pure CSS)
- **Best source:** `liminal.css:420–438` (veil `linear-gradient(105deg, magenta→transparent→cyan)`, `mix-blend-mode: screen`, `veil-stutter 0.42s steps(2)` opacity+translateX jitter)
- **Notes:** REAL CODE. First pass listed this "proposed from Liminal" — confirm: it IS pure CSS, no shader needed. Body class `.is-glitching` toggles it. Pairs with wordmark RGB-split (below) + magenta ring flush.

### Chromatic Text Shudder (RGB split)
- **Name:** Chromatic Wordmark Shudder
- **Target:** Aether `.rabble-glitch-text` (pure CSS)
- **Best source:** `liminal.css:440–446` `@keyframes word-shudder` — `text-shadow: ±3px cyan / ∓3px magenta + 60px violet bloom`, `0.18s steps(2)`
- **Notes:** REAL CODE. Generic RGB-split text glitch. Knobs: split distance, bloom radius, tint pair, step duration.

### Summoning Rune Ring (counter-rotating SVG)
- **Name:** Summoning Circle / Rune Ring
- **Target:** `NeBuLA.ui.createGrimoireRing` (EXISTS in NeBuLA) — CSS motion reference here
- **Best source:** `Grimoire.css:339–378` (`.sc-ring-rotate` cw 48s, `.sc-ring-counter` ccw 72s, `.sc-ring-runes`); speed states is-summoning (6s/9s/8s) vs is-summoned (36s/54s/48s); halo `:343–351` radial-gradient, opacity 0→0.18
- **Params:** ring layer speeds (rest vs summoning vs summoned), counter-rotation pair, rune layer, halo glow opacity/color (`--ring-color`)
- **Notes:** REAL CODE. NeBuLA already owns `createGrimoireRing`; this CSS is the *speed-state choreography* spec (3 states) the JS factory should expose as params. Also `gv-runedraw` SVG stroke-draw + `gv-rune-spin 32s` (`Grimoire.css:124–141`).

### Eye Rotate / Watching Spin
- **Name:** Slow Eye Rotation
- **Target:** `NeBuLA.ui.createGrimoireEye` (EXISTS) — CSS ref
- **Best source:** `Grimoire.css:302–306` `.sc-eye-spin` → `sc-eye-rotate 14s linear infinite`
- **Notes:** REAL CODE. Simple continuous rotation knob for the eye element.

### Horizon Line Glow
- **Name:** Glowing Horizon Line
- **Target:** Aether `.rabble-horizon` (pure CSS)
- **Best source:** `Grimoire.css:36–43` `.gv-horizon` — 1px `linear-gradient(90deg, transparent, magenta, transparent)` + `box-shadow 0 0 12px magenta`, opacity 0.4
- **Notes:** REAL CODE. Reusable glowing scanline/horizon divider. Knob: color, glow radius, vertical position.

### Panel Atmospheric Tint (radial wash)
- **Name:** Radial Panel Tint
- **Target:** Aether `.rabble-panel` background modifier (pure CSS)
- **Best source:** `Grimoire.css` `.gv-panel--circle` / `--codex` (`radial-gradient(ellipse at 50% 30%, violet 14%, transparent 60%)` layered over void `:55–60` region)
- **Notes:** REAL CODE. Per-variant atmospheric color wash behind glass. Knob: tint color, ellipse origin, spread.

### 3D Rune-Page Reveal (perspective flip)
- **Name:** Perspective Page-In Reveal
- **Target:** Aether `.rabble-reveal-3d` (pure CSS)
- **Best source:** `Grimoire.css:111–121` `gv-reader-rune-in` / `gv-reader-page-in` — `perspective(800px) rotateY(-22deg → 0)` + opacity, 420ms cubic-bezier(0.2,0.9,0.2,1)
- **Notes:** REAL CODE. Card/page entrance flourish. Knobs: perspective, start angle, duration.

### Transmission Feed Decay (enter/decay/exit)
- **Name:** Ambient Transmission Lines
- **Target:** Aether `.rabble-transmission` + `.tx-in/.tx-out` (CSS) — JS scheduler is World/curator glue
- **Best source:** `liminal.js:201–233` (transmit/decay clock); `liminal.css:534` transitions
- **Params:** max lines (6), per-line lifetime (11s), exit fade (900ms), ambient interval (7–16s random), babble leak chance (0.22)
- **Notes:** REAL CODE. Visual = simple CSS opacity transition; the timing/pooling is logic (stays in World/dock, already covered as `.rabble-log`). Listed here only to confirm the *visual* is plain CSS.

### Sigil Breathe Pulse
- **Name:** Status Sigil Breathe
- **Target:** Aether motion utility (`.rabble-breathe`)
- **Best source:** `liminal.css:100–103` `lsb-breathe` (box-shadow 8px green pulse)
- **Notes:** REAL CODE. Overlaps World dock `rd2-sigil-pulse` (`RaBbLE-dock.css:64`). Collapse both → one generic `.rabble-breathe` (color + period knobs). Already flagged in first pass under "Sigil Pulse" — confirmed CSS, two duplicate sources.

### Waveform / Bloom Particle Config (Studio)
- **Name:** Entity Waveform + Bloom
- **Target:** `NeBuLA.effects` (entity render params — EXISTS in NeBuLA element)
- **Best source:** `RaBbLE-Studio.js:13–31` (`_waveformConfig`, `_particleConfig.bloomRadius`)
- **Params:** per-state waveform config, bloomRadius (default 6px), portal toggle, interactive toggle
- **Notes:** Studio.js is a CONTROL PANEL driving NeBuLA element attributes (`show-waveform`, bloom slider) — not its own effect. The effects live inside NeBuLA's entity backend already. No extraction; confirms NeBuLA owns waveform/bloom and they're parameterized.

### Floor Graph Label Fade (World)
- **Name:** Graph Node Label Reveal
- **Target:** Aether `.rabble-floor` label CSS (World floor glue)
- **Best source:** `RaBbLE-floor.css:36–40` (`.floor-label-visible` / `.floor-label-hover` opacity states)
- **Notes:** REAL CODE but thin. Hover/visible opacity toggle on 3D-projected labels. World-local floor glue; minor.

---

## Couldn't Find / Notes

- **Cotton-candy swirl (rotating conic wash):** NO dedicated implementation found in either surface. The `conic-gradient` grep hits in `liminal.css` / `Grimoire.css` / `aether.css` are the existing `.rabble-border-harmony` ring, not a boot/alert swirl. The cotton-candy effect is **conceptual only** (lives in MEMORY `project_cool_effects.md` as a saved-for-future idea) — no code to migrate. Design generic if/when needed; not present in ep1.
- **Parallax depth:** present but woven into starfield (cursor offset `×z`) and orbit-plane tilt — not a standalone layer system. Captured under Starfield + Orbiting Doors.
- **World `RaBbLE-bg.js`:** DOES NOT EXIST (coordinator target). World has no separate bg module; ambient background is the NeBuLA element / floor. The Chrysalis `liminal.js` deep-field is the only full ambient-canvas engine in the codebase.
- **Boot color wash:** no cotton-candy; boot is the `bootRamp()` transmission/state ramp (`liminal.js:665–676`) — text/state sequence, not a color wash. NeBuLA `core/boot-sequence.js` owns entity boot separately.
- **World `movements.js` / `stage.js`:** transitions are inline `opacity var(--rc-dur-fast)` fades only — no novel effects. Covered by existing tokens.
