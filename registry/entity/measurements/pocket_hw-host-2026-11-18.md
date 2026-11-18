# pocket_hw host proxies, 2026-11-18 (U11, W2-8)

Data: `pocket_hw-host-2026-11-18.json` (host CPU recorded there: AMD Ryzen AI 9 HX 370). Method: schema section 7, step 1. Scratch harness from `u1/host_render_u1.c`, Pocket `5c987a4`, scene.c copy with env switches (Pocket not edited). Each cell is the median of 5 runs. Delta = on minus off. For ui.slide, orbit, boot and mesh.orbit_handoff "on" replaces part of the scene, so deltas are negative.

Host ms is not device ms. Rank by prims and damaged bands; the ms column is only a sanity check (all of it is a fraction of a millisecond on the host, so nothing here says "over 14 ms").

## Baseline fixtures (all effects on)

| fixture | prims | damaged bands /30 (frame to frame) | sim + damaged render, host ms |
|---|---|---|---|
| idle | 219 | 17.4 | 0.25 |
| listening 0.5 / 1.0 | 599 / 599 | 24.0 / 24.2 | 0.43 / 0.44 |
| thinking | 272 | 16.8 | 0.33 |
| speaking | 265 | 17.4 | 0.30 |
| joy | 258 | 17.5 | 0.31 |
| mid-swap flip 0.5 | 219 | 17.4 | 0.20 |
| boot early | 11 | 10.0 | 0.08 |
| Orbit slide | 59 | 25.0 | 0.14 |
| idle turning (0.8 rad/s) | 219 | **28.9** | 0.22 |
| listening turning | 760 | 29.3 | 0.44 |
| thinking turning | 272 | 28.9 | 0.32 |
| idle / listening / speaking at activity 1.0 | 306 / 655 / 300 | 17.8 / 24.2 / 17.5 | 0.28 / 0.43 / 0.29 |

Idle at 17.4 damaged bands matches the device's "about 18 of 30 bands at idle" (S252), which is some validation of the damage proxy.

## Ranking (largest absolute delta prims, then damaged bands; worst fixture shown)

| effect | delta prims | delta damaged bands | delta sim + damaged render (us, host) |
|---|---|---|---|
| strands.mic | +324 (listen); +486 turning | +6.8 (listen 1.0) | +190 |
| mesh.edges | +148 (think); +182 at activity 1.0 | +1.1 idle, +9.0 Orbit slide | +124 |
| mesh.nodes | +84 (every fixture) | +0.4 | +34 |
| mesh.signals | +29 (speak) | +0.1 | +24 |
| strands.absorb | +24 (listen) | 0 | +33 |
| glass.badges (+hint) | +3 | 0 | +27 |
| eyes | +2 | 0 (+4.0 at boot) | +45 |
| portal.back / portal.front | +2 / +2 | 0 | +29 / +28 |
| glass.clock / status / caption | +1 / +1 / +1 | 0 | +4 / +3 / +57 (noise) |
| ring (compose.c, no prims) | 0 | +1.2 only while turning | +81 (listen) |
| ring.drain_arc (compose.c arcs) | 0 | 0 | +140 (listen), +100 turning |
| ring.tint | 0 | 0 | noise |
| mesh.touch_dent | 0 | 0 | noise |
| ui.slide (replaces scene, 233 px) | -91 to -365 | -0.2 to -2.8 | -67 to -229 |
| orbit (slide 233, replaces scene) | -160 | +7.6 | -98 |
| mesh.orbit_handoff | -118 | 0 | -98 |
| boot (early) | -190 | -8.0 | -200 |

Not measured: infinity (not built anywhere), backdrop.void (flat fill, no prims). Every other registry effect has `pocket_hw: none`.

## Sub-60 states from S252

- **Listening (31 to 41 fps on device).** Host: 599 prims against 219 idle, 24 damaged bands against 17. Costliest: strands.mic (+324 prims, +6.8 bands, about 2x the next effect), then mesh.edges (+128), mesh.nodes (+84), mesh.signals (+27), strands.absorb (+24). Level 0.5 and 1.0 are identical (strand count does not follow level).
- **Turning (about 30 fps on device, any state).** Host: no effect is responsible. The roll dirties 29 of 30 bands against 17, so the per-band skip that made idle 60 fps is defeated in every state. The turn cost is the full-frame render plus transfer; the lever is the ring and everything else being redrawn at a new angle, not any one effect. Listening while turning is worst (760 prims, 29.3 bands).
- **Speaking (about 34 fps on device).** Host does NOT explain it: 265 prims, 17.4 bands, 0.30 ms, close to idle. Only mesh.edges (+140, +181 at activity 1.0) and mesh.signals (+29) rise. Either the device pays something the proxy lacks (real CPU activity, the reply-audio path, the caption/LVGL sprites, SPI contention) or the fps figure was taken with another cost running. The profiling build is the way to find out.
- Thinking (not flagged by S252) is 272 prims, 16.8 bands.

## Method caveats

- Host ms: x86 at -O2 with the portable C fallbacks (no PIE SIMD); single-digit microsecond sim times; deltas below about 20 us are noise, including ring.tint, touch_dent and the glass sprites.
- Activity is fixed (0.3/0.6; busy fixtures 1.0). Edge count scales with it (+101 idle to +182 busy), so the device number depends on the real CPU load.
- Glass sprites are stand-in blocks, not LVGL text; caption is a proxy block.
- The Orbit fixture is built from `orbit_scenes.c` helpers at an assumed mid slide; not a captured frame. `prims_max` shows prim count swings during the slide.
- "Boot early" compares boot 0.3 with boot done at the same 0.3 s; the easing state is not settled there.
- `repeat_same` (the S353 repeat-frame line) re-simulates identical inputs, so it says how many bands hold still under no input change (30 of 30 idle). The frame-to-frame mean is the damage figure that tracks the device.
- No calibration to device ms is possible until the profiling build in `PROFILING-BUILD-SPEC.md` has been flashed and pasted back (schema 7, step 3). Nothing here is written to `cost.device` in the registry.
