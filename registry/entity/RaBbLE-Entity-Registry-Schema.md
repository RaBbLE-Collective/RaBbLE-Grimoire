# RaBbLE entity registry: schema, layer model, vocabulary, 60 fps method, validator spec

```
status: DRAFT for Mark's sign-off · S353 · 2026-11-18 · owner: Mark (direction) · written by Opus from the S352 plan + wave-1 census
```

**What this is.** The contract for `registry/entity/rabble.entity.json`, the one place an entity number lives (S352 ruling 1). Every surface draws RaBbLE with its own native renderer and reads its numbers, names and layers from that file through a generator. This page freezes the shape; the machine form is `rabble.entity.schema.json` beside it (JSON Schema 2020-12). **No agent generates from it until Mark signs it off.**

Sources: `log/plans/Unified-Entity/Unified-Entity-NeBuLA-Unification-Plan.md` (rulings 1 to 10, S353 rulings), `Unified-Entity-Canon.md`, `Unified-Entity-Puppet-Spec.md` (sections 4.1, 10), `registry-spike/poses.role.json` (role-relative poses, adopted as is), wave-1 census S353 (constants, effects, expressions; summarised in the plan).

Supersedes: Puppet Spec section 10.1 sample registry (stale: 0.7 s transition, 0.97 s withdraw, no portal Y, no tilt, no camera blend; Canon 9.3).

---

## 1. Principles

1. **Numbers once.** A number that defines the entity appears in the registry and nowhere else. Surface code may hold draw technique (how to fill an ellipse), never entity values (how wide it is).
2. **Base plus profiles.** `base` is the rig baseline (S353 ruling: Puppet Spec rig numbers are the base). Each surface **profile** overrides a subset (Pocket proportions are a profile, not the base). Profiles never add names; they only change values, switch layers and set support.
3. **One vocabulary.** Every name used anywhere (pose, expression, state, mood, condition, move, form, timeline, effect, layer, input channel) is declared in `vocabulary`. Private surface names live only in `aliases` while surfaces migrate.
4. **Colour by palette name.** No hex in the registry. A colour is a key of `RaBbLE-Agent/RaBbLE-Palette.md` (`cyan`, `magenta`, `violet`, `pink`, `bg`, `surface`, `raised`, `border`, `text`, `muted`, `dimmer`, `red`, `green`, `yellow`) or `black`/`white` (pure, for void and catchlights). Generators resolve names to values by reading the Palette.
5. **Layers are expression.** Each visual layer is a named effect instance with on/off, opacity and parameters that **inputs, states, expressions and conditions can drive** (S353: Mark or RaBbLE can use layers to express meaning or state). The eyes define the entity; the mesh and orb/Orbit are the second key expression; everything else is driven and surface-dependent.
6. **Units.** Lengths in **eye widths** (`ew`) for proportions, and **face units** (`fu`, 1 ew = 87 fu, the rig's W) for offsets and motion. Angles in degrees in the file (generators convert). Time in seconds. Surfaces scale fu to pixels in their profile (`profile.scale`).

## 2. Top-level shape

```jsonc
{
  "$schema": "./rabble.entity.schema.json",
  "format": "rabble-entity-registry/1",
  "version": "0.1.0",            // registry semver; bump on any value change (generators stamp it)
  "vocabulary": { ... },         // section 3: every legal name
  "aliases":    { ... },         // private surface name -> canonical name (migration only)
  "base": {
    "body":        { ... },      // 4.1 proportions, envelope, home word, no-touch margins
    "camera":      { ... },      // 4.2 elevation, persp blend, CAMD, tilt (EPS0, EPSK), top-down blends
    "cut":         { ... },      // 4.3 swallow cut
    "colour":      { ... },      // 4.4 colour volume
    "idle":        { ... },      // 4.5 float, breathe, bob, wander, gaze, blink pattern
    "forms":       { ... },      // 4.6 four rests
    "moves":       { ... },      // 4.7 turn, portal_swap, blink, withdraw
    "expressions": { ... },      // 4.8 role-relative poses or curves
    "states":      { ... },      // 4.9 state -> expression weights, mood timeline, layer drives
    "conditions":  { ... },      // 4.10 Identity lifecycle -> body + layers
    "timelines":   { ... },      // 4.11 boot, thinking, orbit_open, ...
    "effects":     { ... },      // 5.1 effect definitions (params, cost, support)
    "layers":      [ ... ]       // 5.2 ordered layer instances
  },
  "profiles": { "<surface>": { ... } }   // 6: overrides per surface
}
```

## 3. Vocabulary (S353 decision: the NeBuLA language)

Names are `snake_case` ids; display labels live beside them. Every surface uses these ids in code, protocol messages and logs.

| Kind | Ids | Notes |
|---|---|---|
| `expression` (emotion layer) | `calm`, `joy`, `sad`, `angry` | `calm` is the rest expression, the only one canon today; the other three are parked seeds (Canon 7). Blended by weight. |
| `state` (what RaBbLE is doing) | `idle`, `listening`, `thinking`, `speaking` | `thinking` stays a state on every surface (World, Pocket, TUI all have it); its phases are moods. |
| `mood` (short overlay inside a state) | `ponder`, `process`, `insight` | `thinking` plays `ponder` then `process` (Pocket's 1.5 s split, now a timeline). `insight` is a brief peak. |
| `temperament` (descriptor, not posed) | `curious` | Canon 6: a default parameter set, never a selectable state. |
| `condition` (Identity lifecycle, Canon 9.5) | `dormant`, `initializing`, `calibrating`, `resonant`, `glitch`, `system_drift`, `genius_resonance`, `null_void` | The `%NAME%` states from `RaBbLE-Identity.md`, lowercased. `resonant` is the no-op baseline. |
| `cue` (one-shot trigger) | `poke`, `shock`, `denied`, `error`, `fresh`, `dizzy`, `touch` | Cues map to moves, expression pulses or conditions in `states.cues`. |
| `move` | `blink`, `portal_swap`, `turn`, `withdraw` | `withdraw` is the swap's squash without the swap (Pocket `fresh`). Eye colour spin is a rig tool, not a move (Canon 3: poles never swap as a state). |
| `form` (calm rest) | `rest` (0110), `swap` (1010), `mirror` (0101), `swap_mirror` (1001) | Spec 4.1 names. Bits `el, er, pl, pr`. |
| `timeline` | `boot`, `thinking`, `insight_burst`, `orbit_open`, `orbit_close`, `power_off` | Plus every move (a move is a timeline with a fixed id). |
| `input` (channels a surface feeds) | `time`, `level`, `bands`, `gaze`, `touch`, `roll`, `sway`, `activity`, `mic_dir`, `clock`, `battery`, `link` | `level` scalar 0..1; `bands` float array (web bars); `gaze` 2D (pointer on web, touch glance on device). A surface without a channel supplies nothing; drives on it read 0. |
| `surface` | `web`, `web3d`, `ball`, `pocket_web`, `pocket_hw`, `terminal`, `studio` | `ball` is the top-down Three profile; `studio` is NeBuLA Studio's preview. |
| `effect` | section 5.3 | Dotted ids, group first. |

**Aliases (migration only, validator-enforced).** Seed from the S353 catalogue:

| Surface | Private | Canonical |
|---|---|---|
| sCoRE TUI `driver.rs` Mood | `typing` / `streaming` / `working` / `error` / `denied` | `listening` / `speaking` / `thinking` / cue `error` / cue `denied` |
| Pocket firmware | `NL_STATE_LISTEN` / `THINK` / `SPEAK` / `ERROR`, input `happy` | `listening` / `thinking` / `speaking` / cue `error` / expression weight `joy` |
| NeBuLA alive | mood `curious`, expression `listening` (retired +-252 pose) | temperament `curious`; state `listening` (pose retired) |
| World | `RESONANT` label | condition `resonant` |
| live.js | rotMode `spin` | move `turn` |

## 4. Base sections

### 4.1 `body`
- `eye`: `{ "w": 1.0 (ew, the unit), "h": 3.13 }`; `portal`: `{ "w": 2.69, "flatten": 0.30 }`; `spacing`: 2.11 (eye centre to centre, ew); `portal_y`: `{ "default": 1.00, "range": [0.2, 1.5] }` (eye half-heights from the eye centre).
- `envelope`: `{ "eh": [2.5, 3.2], "sp": [1.9, 2.2], "pw": [1.9, 2.8], "fl": [0.22, 0.33] }`. Every profile's proportions must sit inside it (Canon 2).
- `home`: `"rest"`. `no_touch`: `{ "portal_portal_min_fu": 0, "eye_rim_rule": "recede_before_cross" }` (Canon 2: portals never touch, eyes never cross a rim).
- `per_side_offset`: optional `[left, right]` portal offsets in eye half-heights (null in base; Pocket profile `[0.86, 0.79]`).

### 4.2 `camera`
`elevation_deg: { default: 17, range: [-90, 90] }`, `persp_full_rad: 0.4` (persp = smoothstep(|e|/0.4)), `camd_fu: 800`, `tilt: { eps0: 0.283, epsk: 0.16 }` (rad; Canon 5 formula is fixed in code, constants here), `top_down: { shrink_rad: [0.5, 1.05], settle_rad: [0.6, 1.2], eye_fit: 0.74 }` (two ranges, not Canon's single "29 to 69"), `rim_points: 72`.

### 4.3 `cut` (swallow cut)
`{ "mode": "opening_clip", "span_px": { "min": 14, "max": 60, "k": 0.22 }, "hide_below": 0.003, "hide_above": 0.985 }`. `mode` is an enum: `opening_clip` (Pocket: half-plane plus opening ellipse; **base, ruled S353 #16**) or `dome_dissolve` (the rig's earlier rule, kept for comparison). Rest portal Y is 1.00 on every profile, so at idle the lower portal's near rim does not cover its eye; V5 checks that (no rim over an eye at any rest form).

### 4.4 `colour`
`{ "poles": ["cyan", "magenta"], "blend_fu": 96, "hue_path": "short", "sample": "eye_centre", "eye_fill": "white", "eye_outline": "pole", "void": "black", "void_alpha": 0.9 }`. Ruled S353 #17: pure white eyes, palette outline (the pole colour at the eye's position), and a slight fade toward the rim (`eyes.params.rim_fade`, a white core blending to the outline colour, like the device's orb gradient). The rig's `#f8faff` retires.

### 4.5 `idle`
`blink: { "period": 4.2, "dip": 0.16, "double_every": 3, "second_dip": [0.24, 0.40], "squash": 0.95 }` (identical in live.js and scene.c; alive's random 2 to 7 s blink becomes a `drive` on `period` by energy, not a second model). `float: { "amp_fu": 12, "w": 1.05 }`, `breathe: { "amp": 0.02, "w": 1.25 }`, `portal_bob: { "amp_fu": 8, "w": 1.4, "phase": 1.1, "opposed": true }`, `wander: {...}`, `gaze: { "range_fu": [26, 12], "stiffness": 40, "pointer_stiffness": 110 }`. **Three idle models exist today (C7)**: base takes the rig's; the alive values move here as named params; surfaces stop carrying their own.

### 4.6 `forms`
`{ "rest": "0110", "swap": "1010", "mirror": "0101", "swap_mirror": "1001", "reach": { "portal_swap": "flips pl,pr", "turn": "yaw half-turn, eyes trade places" } }`. All four are legal calm rests (S322).

### 4.7 `moves`
Each move is a timeline: `{ "duration": s, "clock": easing, "curves": { channel: easing }, "params": {...} }`.
- `portal_swap`: `duration 1.45`, clock `smoothstep`, `plateau: { "k": 1.6, "ease": "smootherstep" }`, `arc_fu: 75`, `eye_squash_floor: 0.0`, `width_bulge: 0.18`, `ghosts: { "n": 3, "dt": 0.05 }`.
- `turn`: `duration 1.4`, `smoothstep`, `kind: "yaw"`.
- `blink`: as `idle.blink` (the pattern) plus `squash_to_portal: true`.
- `withdraw`: `duration` from the swap, no flip.

Easing ids (closed set): `linear`, `smoothstep`, `smootherstep`, `sine`, `exp(tau)`, `spring(k, damping_ratio)`.

### 4.8 `expressions`
Role-relative, exactly the `poses.role.json` shape: `{ "<id>": { "upper": { "eye": P, "portal": P }, "lower": {...}, "head_tilt_deg", "gaze_scale", "spring_k", "style": {...} } }` with `P = { dx_in, dy, rot_m, sx, sy }` (fu, degrees mirrored by side). Or a learned **curve** (Canon 7: expression may be learned): `{ "<id>": { "curve": { "rate_hz": 30, "channels": { "upper.eye.sy": [..], ... } } } }`. Limits (`LIM`, alive-backend.js:204) are schema bounds. `style` carries alive's per-expression aura numbers (energy, glow, tempo, bpm...) as named layer drives.

### 4.9 `states`
`{ "<state>": { "expression_weights": {...}, "mood_timeline": "thinking" | null, "drives": [...] } , "cues": { "<cue>": { "move" | "expression_pulse" | "condition": ..., "hold": s } }, "blend_tau": 0.25 }`.

### 4.10 `conditions`
`{ "<condition>": { "body": { "eye_scale": .., "dim": .., "recede": .. }, "drives": [...] } }`. Seed: `dormant` = eyes receded, dim; `initializing` = plays `boot`; `glitch` = mood plus aura jitter; `system_drift` = dimmed; `genius_resonance` = `insight_burst`; `resonant` = no-op.

### 4.11 `timelines`
`{ "<id>": { "duration": s, "tracks": [ { "target": "layer:<id>.opacity" | "body.eye.sy" | ..., "keys": [[t, v, easing], ...] } ] } }`. Keys sorted, inside `[0, duration]`. `boot` is seeded from alive's BOOT table (grid, motes, portal arc, eye rise, blinks, mesh, lens, orbit, ready, idle) reconciled with Pocket's (portals fade cyan first, then eyes and the rest; `scene.c:626-637`). The device plays the same timeline when it adopts the registry (U7).

## 5. Layer model (U9)

### 5.1 `effects` (definitions)
```jsonc
"mesh.edges": {
  "label": "Mesh links",
  "group": "mesh",                    // backdrop | ring | aura | body | mesh | core | glass | overlay
  "priority": 2,                      // 0 = defining (never yields), 1 = key expression, 2 = expressive, 3 = ambient, 4 = decor
  "params":  { "width": { "type": "number", "default": 1.0, "min": 0.2, "max": 4 },
               "alpha": { "type": "number", "default": 0.42 },
               "colour": { "type": "colour", "default": "pole" } },   // "pole" = from the colour volume
  "inputs":  ["activity", "time"],
  "cost":    { "tier": "high", "device": { "prims_per_frame": null, "ms_worst": null, "measured": null } },
  "support": { "web": "full", "web3d": "full", "ball": "reduced", "pocket_web": "full", "pocket_hw": "full", "terminal": "none", "studio": "full" },
  "reduced": { "alpha": 0.3, "edges_max": 64 }    // the param overrides that "reduced" means
}
```
`support` values: `full`, `reduced` (apply the `reduced` overrides), `none` (skip without error). Every effect lists every surface. `cost.tier` is `trivial | low | medium | high`; `cost.device` is filled only from measurement (section 7).

### 5.2 `layers` (ordered instances)
```jsonc
{ "id": "haze_left", "effect": "backdrop.haze", "enabled": true, "opacity": 0.34,
  "blend": "screen",                          // source-over | screen | lighter | multiply
  "params": { "pole": "cyan", "rx_fu": 450, "ry_fu": 382, "x_fu": -170 },
  "drives": [ { "param": "opacity", "from": "expression.sad", "gain": -0.15 },
              { "param": "opacity", "from": "input.level", "gain": 0.2, "curve": "smoothstep" } ] }
```
- Array order is draw order, back to front. Several instances may share one effect (two hazes).
- **The core group is fixed**: `portal.back`, `eyes`, `portal.front`, `infinity` sit together in that order, and their internal occlusion is code (the rule in Canon 6, verified by U1 and golden frames), not reorderable data. Layers before the core draw behind the entity, after it in front.
- `eyes` cannot be disabled in any profile (validator rule). They define RaBbLE.
- **Drives** make every layer expressive: `value = base + sum(gain * curve(source))`, clamped to the param bounds. Sources: `input.<channel>`, `state.<id>` (blend weight 0..1), `expression.<id>` (weight), `mood.<id>`, `condition.<id>`, `timeline.<id>` (progress), `energy` (derived). This lets Mark (in Studio) or RaBbLE (at run time, through the same names) say something with a layer: e.g. the ring tint follows `condition.glitch`, mic strands follow `input.level`, mesh signals follow `input.activity`.

### 5.3 Effect ids (seed list from the S353 census; generator + port agents fill definitions)

| Group | Effect ids |
|---|---|
| backdrop | `backdrop.void`, `backdrop.wash`, `backdrop.haze`, `backdrop.stars`, `backdrop.databits`, `backdrop.meridians`, `backdrop.grid`, `backdrop.bokeh` |
| ring | `ring`, `ring.tint`, `ring.drain_arc` |
| aura (alive) | `aura.sphere`, `aura.motes`, `aura.embers`, `aura.sparks`, `aura.flashes`, `aura.rings`, `aura.bolts`, `aura.lens` |
| body (lens) | `body.lens`, `body.outline`, `body.bars`, `speak.waves`, `insight.burst` |
| mesh | `mesh.nodes`, `mesh.edges`, `mesh.signals`, `mesh.touch_dent`, `mesh.orbit_handoff` |
| core | `portal.back`, `eyes`, `portal.front`, `infinity` |
| listening | `strands.mic`, `strands.absorb`, `strands.mouth_bloom`, `mic.bloom` |
| glow | `glow.soft` (blur pass; web only), `glow.halo` |
| glass | `glass.clock`, `glass.status`, `glass.caption`, `glass.badges`, `glass.vignette`, `glass.sheen`, `glass.reflections` |
| overlay | `orbit` (Orbit drawer), `ui.slide` (device only) |
| standalone NeBuLA | `field.ambient`, `field.entropy_shader`, `field.attractor`, `filter.animation`, `deepfield.streaks`, `deepfield.constellation` (exist in `src/effects/`, drawn by no backend today: give them support entries or retire them) |

Priority seed: `eyes`, `portal.back`, `portal.front` = 0; `mesh.*`, `orbit`, `ring`, `infinity` = 1; `strands.*`, `body.bars`, `speak.waves`, `insight.burst`, `glass.clock`, `glass.status`, `glass.caption`, `glass.badges` = 2; `backdrop.*`, `aura.*`, `body.lens` = 3; `glass.sheen`, `glass.reflections`, `glass.vignette`, `glow.*`, `backdrop.bokeh` = 4. S353: bokeh and haze are not required on the device.

## 6. Profiles (surfaces)

```jsonc
"pocket_hw": {
  "scale": { "fu_to_px": 0.506 },               // 44 px eye width / 87 fu
  "screen": { "w": 466, "h": 466, "round": true, "centre": [233, 233] },
  "body": { "eye": { "h": 2.64 }, "portal": { "w": 2.0, "flatten": 0.25 }, "spacing": 1.95 },   // portal Y 1.00 from base (S353 #16; the old 0.86/0.79 offsets covered the eye at idle)
  "camera": { "fixed_elevation_deg": 17 },      // the device draws one view; U1 matched it at 17 degrees
  "cut": { "mode": "opening_clip" },
  "frame": { "target_hz": 60, "floor_hz": 60, "budget_ms": 14.0 },
  "layers": { "backdrop.haze": { "enabled": false }, "backdrop.bokeh": { "enabled": false } },
  "support_overrides": { }
}
```
Profiles override only keys that exist in `base` (validator rule). Proportions inside the envelope. The Pocket numbers above are today's; Canon 2 says they move toward the base over time, which is a profile edit, not a code change.

Seeded profiles: `web` (alive backend: Portal, account page), `web3d`, `ball` (top-down: `camera.fixed_elevation_deg` 90), `pocket_web` (same proportions as `pocket_hw`, frame target 60 with the 60/45/30/20 governor as a fallback only), `pocket_hw`, `terminal` (glyph face: body and state names only, every effect `none`), `studio`.

## 7. 60 fps method (U11; S353 ruling: device floor 60, effects yield)

**Rule.** On `pocket_hw` the frame rate is fixed at 60 (TE-locked). The worst-case frame (simulate plus render, all bands, across the fixture set) must stay **at or under 14.0 ms**, leaving 2.6 ms of the 16.7 ms period for UI, LVGL and jitter. An effect that does not fit is demoted `full` to `reduced` to `none` (or pre-baked). Frame rate is never the variable.

**Today's device already misses it.** S252 numbers (Entity-Port-Plan): idle 60 TE-locked; listening and speaking held still 31 to 41 fps; turning about 30. So U11 starts by bringing the current body (mesh edges, mic strands, orbs) to 60 in those states, before any new effect is admitted.

**Measuring.**
1. *Host proxy* (agents, any time): `sim/host_render` per fixture prints `simulate ms, render ms, prims` and `repeat frame: N of 30 bands same`. For each effect, render the fixture set with the effect on and off; record delta prims, delta host render ms and band damage. Host ms is not device ms; prims and damaged bands are the portable proxies.
2. *Device truth* (Mark flashes; organs never do): a profiling build that cycles the fixture set (idle, listening at level 0.5 and 1.0, thinking, speaking, joy, mid-swap, Orbit open, boot) and logs `nl_prof` per stage (`rabble_entity.c` already prints fps, render ms, prims and per-stage ms every 10 s). The log is pasted into `registry/entity/measurements/pocket_hw-<date>.json`.
3. *Calibration*: fit device ms ≈ a·prims + b·damaged_bands + c per stage from (2), so host proxies predict device cost between flashes.

**Admitting and demoting.** `support.pocket_hw` may be `full` only when the measured worst fixture with that effect on is within budget. If the profile is over budget, demote the enabled effect with the **highest priority number** first (decor before ambient before expressive), `full` to `reduced` before `none`, and re-measure. Priority 0 (eyes, portals) never yields; if they alone break budget, that is a renderer bug.

**Runtime yield ladder (both device and web).** The static profile is the plan; a runtime ladder is the safety: if the frame time exceeds budget for 30 consecutive frames, step the next layer (same order as demotion) to `reduced`, then `none`; climb back after 3 s calm. On web the ladder runs **before** the 60/45/30/20 frame governor, which stays as the last resort (S353: web targets 60). The current governor measures rAF cadence, not draw cost; the NeBuLA `frame-budget` port measures draw time.

## 8. Validator spec (U2)

`registry/entity/validate.py` (uv venv, stdlib plus `jsonschema`), exit non-zero on any error. Run in CI for the Grimoire and as a pre-commit check by every generator.

| # | Check | Error when |
|---|---|---|
| V1 | JSON Schema (`rabble.entity.schema.json`) | shape, types, required keys, enum values |
| V2 | Vocabulary closure | any id used in expressions, states, conditions, timelines, layers, drives, profiles is not declared in `vocabulary`; any `aliases` value is not canonical; any alias key appears outside `aliases` |
| V3 | Palette | any value matching `#[0-9a-fA-F]{3,8}` anywhere; any `colour` value not a key of the Palette table (parsed from `RaBbLE-Agent/RaBbLE-Palette.md`) or `black`/`white`/`pole` |
| V4 | Envelope | base or any profile's resolved `eh`, `sp`, `pw`, `fl` outside `body.envelope`; `portal_y` outside its range |
| V5 | No touch | resolved geometry (base and each profile) at every form and sampled every 1/60 s through `portal_swap`, `turn`, `blink`: portal-portal contact or an eye crossing another side's rim (port `registry-spike/notouch.py` / `notouch3d.py`) |
| V6 | Effects and layers | a layer names an unknown effect; an effect lacks a support entry for any surface; a `reduced` support without `reduced` overrides; `eyes` disabled anywhere; the core group not contiguous or out of order |
| V7 | Drives | target param not defined by the effect; source not a vocabulary channel; resolved range outside the param bounds at source extremes |
| V8 | Timelines | keys unsorted or outside `[0, duration]`; unknown easing; target path not resolvable |
| V9 | Expressions | pose values outside `LIM`; neither pose nor curve; curve channels not in the pose path set |
| V10 | Profiles | override key absent from `base`; unknown surface; `frame.floor_hz` below 60 on `pocket_hw` |
| V11 | Device budget (warning until measurements exist) | a `pocket_hw` `full` effect with no `cost.device.measured`; measured worst fixture over `budget_ms` |
| V12 | Determinism | file not canonical (sorted keys, 2-space indent, trailing newline), so diffs stay reviewable |

Tests: one passing fixture (the real registry) plus one failing fixture per check under `registry/entity/tests/`.

## 9. Rulings and what is still open

**Ruled S353 (second batch, plan rulings 15 to 19):** one unified NeBuLA web backend (alive + rig + Pocket web; profiles `web` and `pocket_web`); `cut.mode` = `opening_clip`, rest portal Y 1.00 everywhere; eyes white with a pole outline and a rim fade; every effect is a NeBuLA effect (the standalone `src/effects/` modules included); `thinking` is a state with `ponder` and `process` as its moods. **Still open:** the U8 inventory sign-off, and the device turn (`moves.turn` support on `pocket_hw`). The original open list follows for the record.

- **U1-a, swallow cut for the lower-role eye.** At a matched 17 degree camera, Pocket and the rig agree on draw order in idle, blink and swap (section in the plan). They differ in how much of the lower eye shows inside the opening: Pocket clips to the half-plane plus the opening ellipse, so the eye fills the well down to the near rim, which then draws over it; the rig dissolves along a dome at the portal plane, so the eye ends at the well's centre and the near rim never crosses it. Ruling 37 (Pocket's occlusion is the reference) says take Pocket's; rulings 30b/36b (dome dissolve, no clip rectangles) describe the rig's. The schema carries both as `cut.mode`; choose the base.
- **C5, eye fill colour.** `#f8faff` is off-Palette: `text`, `white`, or a new Palette entry.
- **Alive as the canonical 2D backend.** The Portal mounts `backend="alive"` (World `index.html:35`, `account.html:72`), not the Canvas2D backend the plan named. Alive matches the rig proportions (2.69) and carries the aura, boot and expressions, but none of the rig mechanics. Recommendation: keep `alive` as a named backend, make it NeBuLA's canonical 2D path and the first registry consumer, port the rig mechanics (tilt, cut, turn, swap, colour volume, infinity) into it, and put Pocket web on it. The old Canvas2D entity (`eye-behavior.js` numbers 38x110, a third proportion set) becomes derived from the registry or retires.
- **Vocabulary**: `thinking` as a state with `ponder`/`process` as its moods; `withdraw` as a move; the eight conditions as above.
