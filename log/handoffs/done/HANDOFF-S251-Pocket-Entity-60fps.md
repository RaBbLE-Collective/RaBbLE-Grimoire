# HANDOFF S251: Pocket entity, from 20 fps to 60 fps idle

Cold start for the next agent. Repo `RaBbLE-Pocket`, branch `new-horizons` (S251 commits not pushed: `9fbdee2`, `ae1485e`, `f4156ae`).
Port plan (Grimoire): `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Port-Plan.md`; Phase 1 results are in it. Previous handoff: `done/HANDOFF-S250-Pocket-Entity-Port-Phase1.md`.
Reviewed before filing: an independent review pass checked this plan against the code; its corrections are folded in.

**Target (Mark, S251):** 60 fps idle, 22 fps the floor in the busiest state (listening, thinking while turning). KISS: no blurs, no transparency layers. This supersedes the port plan's "60 when active, 30 idle".

## Where it stands

The gadget firmware (`firmware/`, flash with `ops/build-flash.sh firmware`, it is on the board now) draws the entity itself through `nebula_lite`:

- **What's drawn:** the ring (precomputed angle table), the eyes plugged into their portals (orb gradient, portal plane clip, front and back rims), the NN mesh with travelling signals, the mic strands, and the glass (clock, Wi-Fi/sCoRE/battery, caption, button badges and icons).
  - **Mesh:** fully connected layer to layer, the same on both sides, about 180 edges. Its activity follows CPU load: cyan follows core 0, magenta follows core 1, and the audio level lifts both.
  - **Mic strands:** run from the real MIC1 (211°, feeds cyan) and MIC2 (145°, feeds magenta), at retarded time on the live level history.
  - **Glass:** text is rasterised from the UI's LVGL fonts into A8 sprites, only when it changes.
- **Gravity:** the entity, the clock and the status row turn upright together. The mics and the button badges stay on the hardware; the button icon glyphs turn level. Positions come from the schematic board view (page 2, seen from the back, so mirrored): PWR −33°, BOOT +34°, USB-C at 180°.
- **Display path:** `firmware/bsp/rabble_lcd_bands.c` has a direct mode. The `lcd_send` task draws 16-row bands, paced by TE (GPIO13), at 80 MHz. LVGL keeps touch, settings, the clock screen and sleep. While direct, LVGL's flushes are completed at the source (`queue_band`), and the draw task runs at `RABBLE_UI_PRIORITY - 1`, so touch stays responsive.
- **Board seam additions** (`rabble_board.h`): `display_direct`, `direct_stats`, `direct_rows`, `mic_deg[2]`.
- **Glue:** `components/rabble_gadget/accord/rabble_entity.c`.
- **Host check:** `sim/build.sh <name> <state> <t> <level> <roll_deg>` writes `sim/out/<name>.png`, no device needed. It is a good visual check, but host timings mean nothing.
- **Isolated device timing:** `ops/build-flash.sh firmware/panel_bench`, then read `BENCH` lines. It runs the same renderer with no Wi-Fi or LVGL, prints per-stage ms, and per-primitive cycles (`nl_bench_prims`).
- **Gadget timing:** the log line `rabble_entity: N fps, render X ms ... per frame ms: fill ring ellipse line sprite swap sim | orbs filled hollow, draws`, every 10 s. **"draws" counts band visits, not primitives:** a long mesh edge is set up again in every band it crosses.

### Measured (device, S251 end)

| | idle | listen | think + turning |
|---|---|---|---|
| fps (gadget, TE-paced) | ~20 | ~14–20 | ~20 |
| bench, unpaced (before full mesh) | 38.9 | 28.7 | 31.0 |

Typical gadget frame at idle (full mesh): fill 0.8 · ring 2.6 · ellipses 7 (orbs 2.1, filled 2.4, hollow 2.3) · lines 12–14 (850–980 band visits from about 180 mesh edges plus strands) · sprites 2.5–4.3 · swap 0.85 · sim 1.3–3 ms. Internal heap after `ready`: about 18 KB.

Per-primitive cycles (bench): 10 px line ≈ 5,700 · disc r2.5 ≈ 2,850 · ring r4 ≈ 7,300 · orb, one 16-row band ≈ 37,800.

### What the numbers taught (don't relearn these)

- **Float costs more than it looks on this LX7.** Division compiles to a software `__divsf3` call. `sqrtf`, `sinf`, `floorf` and `ceilf` are library calls. FPU ops have long latency.
  - Measured: about 50 cycles per pixel slot in float loops, and about 44 even in the integer line loop.
  - Already removed: per-pixel `sqrtf`, all per-row divides, libm trig in the scene (`nl_sin`, `nl_rsqrt`, `nl_recip`, `ffloor`/`fceil`), the scene's seeded-noise RNG (now cached), and float in circle and line bodies (a 4 KB 8.8 sqrt table).
- **Ruled out:** IRAM versus flash for the hot code (no change), PSRAM for the display list (no change), and preemption (raising the draw priority changed nothing). The slowness is the code itself.
- **Per-draw setup dominates small primitives.** Strand segments and mesh edges are short, and every band visit repeats the float setup, so line cost scales with visits, not pixels.
- **TE pacing quantises.** A frame over 16.7 ms waits for the next edge, so the rate drops to 30, then 20 fps. The 22 fps floor in practice means 30 fps (two TE periods), or unpaced.
- **60 fps needs each band ahead of the scan, not just a total under 16.7 ms.** The equator bands (widest, most primitives) are the risk, so gate on per-band timing too.

## Workstreams, in order

Run as sub-agents where noted (pin `model: "sonnet"` on fan-outs). Gate every step on the bench numbers, and check looks against a `sim/` frame.

### 0. Static RAM budget first (small; prerequisite for A2)

`nebula_lite` holds about 62 KB of internal BSS (`build/rabble_pocket.map`). PSRAM BSS is allowed: `CONFIG_SPIRAM_ALLOW_BSS_SEG_EXTERNAL_MEMORY=y`.

1. Put `EXT_RAM_BSS_ATTR`, behind an `NL_EXT_BSS` macro so the component stays board-agnostic, on `s_ring_idx` (20.8 KB), `s_ring_span` (5.6 KB) and the `nz` cache (8 KB, `scene.c`). That frees about 34 KB. All three are read sequentially or rarely; measure the ring cost after.
2. Drop or make lazy the `raster_soft.c` tables while haze is off.
3. Share the band buffers. `s_chunk[2]` (2×7.4 KB internal DMA, `rabble_lcd_bands.c`) sits idle in direct mode, and `s_dbuf[2]` sits idle under LVGL. Point both paths at the direct buffers, which are big enough (`bsp_waveshare_175b.c` `DIRECT_BUF_BYTES`). That frees 14.9 KB.

**Gate:** internal free after `ready` ≥ 50 KB.

### D. Settings slide shows a blank face (small; `rabble_ui.c`)

Swiping toward settings turns direct mode off (`set_entity_active(false)`). The LVGL face canvas shows instead, but it was never drawn: `pose_entity` is skipped while direct is on, and `frame_tick` returns early while sliding.

Copying the last direct frame into the canvas has gaps:
- No full frame is kept.
- The canvas is 300×300 and would crop the ring (r≈221) and the glass (y 70 and 424).
- The bands are already byte-swapped.

Options:
- **Simplest:** run `pose_entity` on hand-back and while sliding. The LVGL rasteriser looks different, so expect a visible pop.
- **Better:** a full-frame 466×466 RGB565 snapshot in PSRAM (434 KB) captured from the pre-swap bands of the last direct frame, shown in an LVGL image during the slide.

Also note that `set_direct` blocks the LVGL task until the current direct frame ends, about one frame. Check the clock screen hand-off at the same time.

### C. Sparse at idle, expressive in use (one agent; `scene.c` mesh only)

1. **Fix the activity input first.** The renderer itself loads core 1 (and core 0 after A2), so idle never reads as idle. Subtract the renderer's own busy time (`direct_stats` render µs per second) from core 1's load, or drive activity from work outside the renderer: beam bytes, Wi-Fi traffic, voice state, audio level. Keep `nl_inputs_t.activity[2]`.
2. Every edge gets an activation weight in [0, 1]:
   - At idle, show a sparse skeleton: each node links to its 1–2 nearest nodes in the next layer, plus the ring links.
   - With activity, more of the full edges fade in.
   - Skip any edge below about 0.05 opacity entirely: no draw, no cost.
3. Signals light only the edges they travel; hot edges decay briefly.
4. **Target:** about 50–60 visible edges at idle instead of about 180, roughly 250 band visits instead of about 900.

### B. Less FPU, quantise everything (one agent; `raster.c`, `scene.c`, after C settles `scene.c`)

1. **Cache each primitive's setup on first visit.** The cheap version: compute the line or ellipse float setup the first time a band touches the primitive, store it in the primitive in fixed point, and reuse it on later bands. Use lazy flags; there is no change to the push API.
2. **Ellipse edge pixels:** replace `ellipse_dist` (float) with an integer approximation, using the implicit value times a per-row gradient estimate. Portal rims and the orb edges are the users.
3. **Quantise the scene:**
   - snap mesh node positions and strand points to 1/4 px;
   - quantise alpha to 5 bits and colours to RGB565 at push time.
4. **Sprite deadband:** the straight blit runs only when |sin(roll)| < 0.002 (`raster.c`), and the upright spring jitters around zero. Add a deadband or hysteresis on the sprite angle at rest, so most idle frames blit straight. Caching pre-turned sprites per roll bucket doesn't help the turning floor case, because the bucket changes every frame; skip it.
5. **Strands as one polyline primitive per strand**, walking its own points per band, instead of about 50 separate capsules each with its own setup.
6. **If still short:** run mesh positions and strand shapes at 30 Hz, held or blended. Signals and the eyes stay at 60.

### A. Use both cores (one agent; after 0)

1. **Cheap first: simulate before the TE wait.** Call `d->begin()` before `xSemaphoreTake(s_te, …)` in `direct_frame`, so the simulation runs in the time otherwise spent waiting. That gets most of the pipelining gain on one core, with no double buffering.
2. **If needed, simulate ahead on core 0** (frame N+1 while core 1 rasterises N). Double-buffer the whole frame packet:
   - `nl_prims`, plus the bins (the list buffer and `s_bin_start`, which is a static in `compose.c`);
   - `nl_spr`, `nl_n_spr`, `nl_spr_c`/`nl_spr_s`, `nl_clip`, `nl_roll`, `nl_ring_opa`;
   - `nl_soft` if haze is ever re-enabled.

   The sprite arenas also need a third set or an in-use mask. `s_inuse` in `rabble_entity.c` tracks one set, so `rabble_entity_tick` could rebuild an arena that a frame still reads.
3. **Share rasterisation.** Don't use a fixed odd/even split. Core 0 at low priority stalls whenever the beam (priority 5 on core 0) or Wi-Fi is busy, which is exactly the floor case. Use **dynamic band claiming** instead:
   - an atomic next-band counter; each core renders whatever band it claims into a buffer from a ring;
   - `lcd_send` submits in order, and core 1 never waits on core 0.
   - Transfers complete in order (`draw_bitmap` waits for the previous transfer), so a ring index is enough; per-buffer semaphores aren't needed. Extra buffers only absorb jitter between the cores.
   - Make `static vrow` (`compose.c`, haze path) per-core, and keep `nl_prof` per-core or accept races in the profiler.
   - SPI submission stays on core 1; the interrupt core rule is in the `rabble_lcd_bands.h` header.
   - Memory: 3–4 band buffers × 15.2 KB, funded by step 0.

## Gates

- **Idle:** ≥ 60 fps TE-locked on the gadget, with Wi-Fi and the beam connected, internal heap ≥ 15 KB after `ready`, and no band submitted late. Log per-band render time against the band's scan slot.
- **Listening and think+turn:** ≥ 30 fps (TE ÷2), never under 22.
- Voice turn latency with the beam live is no worse than before.
- Re-run the `sim/` frames and compare by eye after every step.

## Deferred (Mark, S251)

**Fonts:** Aether's Orbitron, Exo 2 and Share Tech Mono are SIL OFL 1.1. Putting them in firmware redistributes them, and that sits outside the "permissive only" rule. Options:
1. Accept OFL for fonts only, isolated with their license.
2. Keep Montserrat/unscii and match Aether through colour, size and spacing.

Not decided. Keep the glass on the current LVGL fonts.

## Gotchas

- **Stack:** `lcd_send` has 6 KB because the scene runs there. Large per-frame arrays in `scene.c` are `static` on purpose. A 2.5 KB stack corrupted FreeRTOS lists on listen (S251 crash).
- **Memory:** `malloc` above 4 KB already goes to PSRAM (`CONFIG_SPIRAM_USE_MALLOC=y`, `ALWAYSINTERNAL=4096`, `RESERVE_INTERNAL=32768`). The internal RAM crunch in S251 was **static BSS** (ring tables, haze buffer, bins), not heap. Check `build/rabble_pocket.map` for big `.bss` symbols. DMA band buffers must stay internal.
- **Priority:** `lcd_send` must stay below LVGL in direct mode, and LVGL's flush must complete in `queue_band`. Otherwise LVGL spins in `wait_for_flushing` and trips the task watchdog.
- **ESP-IDF include order:** don't include `freertos/FreeRTOS.h` after `esp_freertos_hooks.h` in `rabble_entity.c`; use `CONFIG_FREERTOS_HZ`.
- **Bench state:** `panel_bench` now uses the scene API (`state` rides in `cfg.skip`); `clocks[] = {80}`.
- **Board:** the gadget firmware is flashed, not the bench.
