# RaBbLE Pocket: ESP32-S3 Entity Port Plan

Oct 15, 2026 · @Mark · filed from BaBbLE intake S250

> **Status:** filed, work begun. Mock: `RaBbLE-Pocket/planning/mock/rabble-pocket-entity.html`. Progress is tracked in `RaBbLE-Pocket-Roadmap.md`. Stack: the `new-horizons` branch is pushed (S250), so the base is now ESP-IDF v6.0.1 + Muse gadget SDK parts + LVGL 9; `firmware/bsp/rabble_lcd_bands.c` already does PSRAM bands to double-buffered internal DMA chunks and is the starting point for `panel_flush`. See `RaBbLE-Pocket-Gadget-Port.md`.

## Summary

The Pocket entity can run at 60 fps on the Waveshare ESP32-S3-Touch-AMOLED-1.75 only with a purpose-built renderer. The panel link caps full-frame transfers near 46 fps at a 40 MHz QSPI clock. The CPU has roughly 20 to 25 cycles per visible pixel per frame.

The strategy:

- **LVGL stays the shell:** display driver, touch, timers, fonts, and the flat screens (settings, menus).
- **The entity screen is one custom LVGL widget** drawn by a small C renderer, "NeBuLA-lite". No LVGL line, shadow or blur primitives are used on that screen.
- **Glow comes from a half-resolution soft layer** (233 x 233) upscaled under a full-resolution crisp layer. There is no runtime blur.
- **Frames render in bands** into internal RAM while the previous band goes out by DMA. Each band is sent clipped to the circle and paced by the panel's TE pin.
- **Gravity lock rotates geometry, never images.** The IMU angle is applied to every point before rasterising.
- **Frame rate adapts:** 60 fps while listening or speaking, 30 fps when idle, about 1 fps for always-on.

The first gate is a short panel bench that decides whether 60 fps is physically available on this board's pins.

Stack note: you're moving to ESP-IDF 6 with the Muse gadget SDK as the driver and UI base. That code isn't visible yet, so the Grimoire still describes ESP-IDF 5.5.4, the Waveshare BSP and LVGL 9.4. This plan only assumes ESP-IDF esp\_lcd, LVGL 9 and FreeRTOS, so it fits either base.

## What is being ported

The visual spec is the playable mock `rabble-pocket-entity.html` and the v6 video. The mock's PORT PREVIEW mode already approximates this plan: 466 px native, a half-resolution glow layer and RGB565 output. The scene logic in that HTML (states, NeBuLA poses, mesh, streams, lens) is the reference implementation to port to C.

**State cycle in the mock (16 s loop):**

| Time | State | What moves |
| --- | --- | --- |
| 0 to 4 s | Listening | Mic audio travels as streams from the mic, around the body, into both portals; eyes lean toward the mic |
| 4 to 5.5 s | Thinking, ponder | One-side squint, gaze up and aside, face tilt; mesh starts to accordion inward |
| 5.5 to 8 s | Thinking, process | Mesh fully accordioned with hubs pinned to the edge, fastest signals; eyes dart; spectral bars dim |
| about 8 s | Insight | Twin rings and a flash burst from the core |
| 8 to 12.5 s | Speaking | Mesh back at the edges with signals flowing outward; waveform through the body; arc subtitles type in |
| 12.5 to 16 s | Joy | Eyes squash and hop; bottom portal rises like a cheek |

**Layers, back to front:**

1. Background: nebula gradient, cyan and magenta hazes, faint globe meridians, thick cyan-to-magenta outer ring, sparse stars and data bits.
2. Body: bell-shaped lens fill, spectral bars, the almond outline (3 jittered strands per edge with white cores and dark chalk under them), bokeh.
3. NN mesh: per side, an edge hub, then 3 layers, then a ring of nodes kept outside the nebula circle; signal streaks hop between them.
4. Speaking waveform inside the body.
5. Mic streams and absorption at each portal mouth.
6. Portals and orbs, with occlusion; insight rings.
7. Glass layer: edge vignette, clock, status row, state label, arc subtitles, button chips, glare. Text is bold with a dark outline.

**Rules that must survive the port:**

- No pupils.
- The two color poles are always opposite.
- Portal front rims always draw over orbs. The top portal is seen from below, so its upper arc is the front rim.
- Emotion comes from orb shape, tilt, glow and portal depth plus NeBuLA's pose table. Nothing cuts across an orb.
- Mic streams are traveling signals evaluated at retarded time, so loud parts visibly flow into the portals.

## Hardware limits

The panel link, not the CPU, sets the first ceiling. A full 466 x 466 RGB565 frame is 434,312 bytes. Over four-lane QSPI the link moves half its clock rate in bytes per second.

| QSPI clock | Throughput | Full frame | Circle only (\~341 KB) |
| --- | --- | --- | --- |
| 40 MHz | 20 MB/s | 21.7 ms, \~46 fps | \~17 ms, \~58 fps |
| 60 MHz | 30 MB/s | 14.5 ms, \~69 fps | \~11.4 ms, \~88 fps |
| 80 MHz | 40 MB/s | 10.9 ms, \~92 fps | \~8.5 ms, \~117 fps |

- **60 fps full-frame needs at least about 52 MHz.** Sending only each band's visible chord cuts the frame to about 79% (pi/4), which gets close to 60 fps even at 40 MHz.
- **Pins:** the display uses GPIO4 to GPIO7 for data, GPIO38 for clock, GPIO12 for chip select and GPIO13 for TE, per Waveshare's hardware reference.
  - These are not the S3's dedicated SPI2 IO MUX pins, so signals go through the GPIO matrix.
  - Espressif only states matrix routing behaves the same up to 40 MHz. Higher clocks must be measured on this board.
  - Waveshare quotes "50\~60 frames in the dynamic state" for its LVGL demo.
  - Sources disagree on the reset pin: the hardware reference says GPIO39, an esp-hal issue says GPIO1. Check against the schematic.
- **TE (GPIO13)** lets each frame's first band start right after the panel's scan passes, so writes never race the scan.
- **CPU:** two Xtensa LX7 cores at 240 MHz. At 60 fps one core has about 4 million cycles per frame for about 170,000 visible pixels. Blur and multi-pass strokes are out at that budget.
- **Memory:**
  - About 512 KB internal SRAM, shared with Wi-Fi, BLE and the voice stack.
  - 8 MB octal PSRAM (S3R8) and 16 MB flash.
  - A full frame does not fit in internal RAM, and rendering into PSRAM is slower, so work happens in internal-RAM bands.
- **Power:** 320 mAh now (400 mAh on the 1.75C). AMOLED draw scales with lit pixels, which favours the mostly dark scene. Continuous 240 MHz rendering does not, which is why the frame rate adapts.
- **Current firmware baseline (from the Grimoire):** the vendor BSP flushes in 50-row strips, about 10 transfers per frame. CO5300 init carries two hardcoded 600 ms delays.

## Architecture

One frame is simulated on core 0 and rasterised on core 1 in bands, while DMA ships the previous band to the panel.

*(Diagram: frame pipeline · two cores, band rendering, DMA to the panel. Lives in the original intake draft; redraw as an Aether page when the plan is rendered.)*

The frame packet is the only handoff between cores. Core 1 never waits on simulation, and DMA never waits on rendering.

**LVGL's role.** LVGL keeps the display driver, input, timers and font engine. It also owns every non-entity screen. The entity screen is a single custom widget. Its draw callback hands each band's buffer to NeBuLA-lite instead of drawing LVGL objects. Text is still shaped by LVGL's font engine into small A8 masks that the renderer composites rotated.

**Two resolutions instead of blur:**

- **Soft layer, 233 x 233 RGB565 (about 106 KB, internal RAM):**
  - Background gradient and hazes, outer-ring glow, bokeh, node halos, orb and portal bloom, line glows.
  - Everything is drawn as pre-blurred stamps or wide additive strokes.
  - Rebuilt every frame only where it changes. The static part is cached and re-baked when the gravity angle moves.
- **Crisp layer, 466 x 466, drawn per band:**
  - Anti-aliased 1 to 2 px line cores, node dots, orb bodies, portal rims and holes, spectral bars, text and icons.
- **Composite per band:** bilinear 2x upscale of the soft rows, then crisp primitives on top, then the circle mask, then output.

**Band pipeline:**

1. Core 0 finishes frame N geometry into a frame packet, then starts N+1.
2. Core 1 bins frame N primitives by band once per frame (a small row-bucket list).
3. For each band (start at 32 rows, 466 x 32 x 2 = about 30 KB), core 1 renders into band buffer A.
4. The flush sends only the circle chord for those rows, 2-pixel aligned, and kicks DMA.
5. Core 1 renders the next band into buffer B while A transfers.
6. TE gates the start of band 0.

**Core split:**

- **Core 0:** state machine, NeBuLA pose springs, mesh and stream geometry, IMU fusion. Also the audio front end and wake word, which already compete for this core and must be measured.
- **Core 1:** rasterising and flush management only.

**Frame packet (core 0 to core 1):** a fixed-size struct with the rotation angle, state weights, orb and portal transforms, and point arrays for lens strands, mic strands, waveform and mesh nodes and edges. It is double-buffered with an atomic swap, with no locks held during rasterising.

## Gravity lock on real hardware

On the device the panel is fixed to the case, so the scene counter-rotates by the IMU angle every frame. Only the button chips stay fixed to the panel. In the mock the bezel turned instead, and that looks the same to a viewer.

- **Angle source:** the QMI8658. Angle = atan2 of the accelerometer's in-plane components, fused with the gyro Z rate through a complementary filter so swings stay smooth and fast.
- **Flat hold:** when the in-plane gravity magnitude falls below about 0.35 g (pendant lying flat), hold the last angle. Release with hysteresis above about 0.5 g. Tune both on the device.
- **Rotate geometry, not pixels:**
  - Every point (strands, mesh, bokeh centres, stamps) goes through one 2D rotation matrix on core 0. That's nearly free.
  - Orbs and portals are rasterised as rotated ellipses, using an SDF per pixel inside their bounding boxes.
  - The outer ring's cyan-to-magenta gradient is computed from pixel angle minus rotation, using an atan LUT.
  - Text and icons are pre-shaped A8 masks, blitted with an inverse-mapped bilinear sample. The clock is about 200 x 60 px, so the cost is small.
- **Soft-layer cache:** the static soft content (background, hazes, ring glow) is re-baked only when the filtered angle moves more than about 0.5 degrees, spread across frames while the device swings.
- **Mic anchor:** the mic stream's start point is the physical mic position (panel bottom) rotated into scene space, so streams emerge from wherever the mic really is.
- **Button chips:** drawn in panel space at fixed spots beside the physical buttons, with their glyphs counter-rotated so they stay upright.

## Scene element mapping

Every effect in the mock maps to a stamp, a thin line or an analytic shape. None needs a runtime blur.

| Element | Mock technique | Device technique | Layer |
| --- | --- | --- | --- |
| Nebula background, hazes | Radial gradients | Cached half-res bake, re-baked on angle change | Soft |
| Globe meridians, stars, data bits | Thin SVG strokes, dots | 1 px AA arcs and dots; positions rotated | Crisp |
| Outer ring | Gradient stroke plus blurred copy | Per-pixel annulus with angle LUT for color; glow baked in soft cache | Both |
| Bell body fill | Gradient path | Per-row span fill from the bell envelope LUT, into the soft layer | Soft |
| Spectral bars | \~70 gradient rects | Vertical spans with a 1D alpha ramp LUT, every 8 px | Crisp |
| Almond outline | 6 strands x 90 pts, 3 passes plus dark chalk | Wide additive stroke in soft layer plus 1 px white AA core; jitter LUT per 0.16 s tick | Both |
| Bokeh | 56 radial-gradient discs | 28 pre-blurred disc stamps (A8, 4 sizes), tinted additive | Soft |
| NN mesh edges | Wide plus thin strokes | Soft wide stroke plus 1 px AA core; hot edges brighter | Both |
| Mesh nodes | Halo, ring, dot | Halo stamp (soft) plus ring and dot (crisp) | Both |
| Mesh signals | Streak plus halo | 15 px AA streak plus small stamp; deterministic hop schedule | Both |
| Speaking waveform | 4 glowing polylines | 2 polylines: soft wide plus crisp core | Both |
| Mic streams | 3 strands per side, bloom filter | Catmull-Rom path through rotated waypoints, retarded-time signal; soft wide plus crisp core | Both |
| Absorption core, sparks | Gradient ellipse, dots | One rotated ellipse stamp plus 12 dots | Both |
| Portals | Halo, hole, rims | Halo stamp; hole and rims as rotated ellipse SDF with arc split for front and back | Both |
| Orbs | Gradient ellipse plus blurred halo, clipped by portal plane | Rotated ellipse SDF with radial gradient LUT; half-plane plus opening clip; halo stamp | Both |
| Insight rings, flash | Circles plus gradient | AA circle strokes plus one flash stamp | Both |
| Clock, label, subtitles | SVG text with outline and shadow | A8 glyph masks from LVGL fonts, pre-dilated outline mask, rotated blit; shadow as offset soft stamp | Crisp |
| Status icons, button chips | SVG strokes | Pre-rasterised A8 icons, rotated blit | Crisp |
| Vignette, glare | Gradients | Baked into soft cache (vignette), single additive glare stamp | Soft |

The mic strands map straight onto live data. Use the smoothed RMS level for loudness and a cheap pitch estimate (zero-crossing rate or autocorrelation on the AFE output) for the carrier's chirp, both fed into the same retarded-time model as the mock.

## Frame budget and degrade ladder

At 60 fps each frame has 16.7 ms. These are targets to measure against, not measured numbers.

| Stage | Core | Target per frame | Notes |
| --- | --- | --- | --- |
| Simulation and geometry | 0 | 3 ms or less | Shares the core with the audio front end |
| Soft layer update | 1 | 4 ms or less | Mostly stamps; static part cached |
| Per-band upscale and composite | 1 | 4 ms or less | 2x bilinear on about 170k visible pixels |
| Crisp primitives and glass layer | 1 | 5 ms or less | Lines, ellipses, masks |
| Flush overhead (commands, DMA setup) | 1 | 1 ms or less | DMA itself overlaps rendering |
| Headroom | 1 | about 2.7 ms | Spikes and jitter |

Panel transfer has to fit inside the same 16.7 ms window in parallel. That is about 17 ms at 40 MHz circle-only (just over) and about 11 ms at 60 MHz.

**Degrade ladder.** Apply in order until the frame fits, per state:

1. Mic strands from 3 to 2 per side.
2. Soft layer from half to one-third resolution (155 x 155).
3. Bokeh from 28 to 16, mesh signals from 16 to 10.
4. Lens outline jitter re-roll from every 0.16 s to every 0.24 s, and drop the dark chalk strands.
5. Spectral bars every 12 px instead of 8.
6. That state's frame rate from 60 to 45, then 30.

**Frame rate by state:**

| State | Target fps | Why |
| --- | --- | --- |
| Listening, speaking | 60 | Most motion and audio sync |
| Thinking, joy, transitions | 60, or 45 if the budget fails | Motion matters, no audio sync |
| Idle (resting face) | 30 | Calm motion, battery |
| Always-on (clipped to a bag) | about 1 | Clock and minimal eyes on black |

## Phased plan

Seven phases, each closed by a measurable gate. Phases 1 to 3 can be developed on a PC in the LVGL SDL simulator before touching hardware, except for timing.

*(Diagram: roadmap · 7 phases, one gate each. Lives in the original intake draft; redraw as an Aether page when the plan is rendered.)*

Phase 0's result sets the frame-rate ceiling for everything after it; the task lists below carry the detail.

### Phase 0: Bench the panel link

- [ ] Bring up esp\_lcd with the CO5300 on the current base (Muse SDK or vendor BSP), with no LVGL.
- [ ] Flush solid-color full frames with DMA at 40, 60 and 80 MHz; log fps and visual errors at each clock.
- [ ] Add per-band circle-chord windows and confirm the CO5300 window alignment rule (expected 2-pixel even start and width).
- [ ] Wire TE on GPIO13 and start band 0 on its edge; confirm no tearing on a moving test pattern.
- [ ] Measure internal-RAM to QSPI DMA throughput with two 30 KB band buffers.
- [ ] Gate: visible pixels reach 60 fps without tearing at a stable clock. If not, set the ceiling and adjust targets.

### Phase 1: Renderer skeleton

- [ ] Custom LVGL widget whose draw callback hands band buffers to NeBuLA-lite.
- [ ] Band loop with ping-pong buffers, chord flush and TE pacing.
- [ ] Soft layer buffer, cached background bake and 2x bilinear upscale per band.
- [ ] Build the same renderer for the LVGL SDL simulator on Fedora.
- [ ] Gate: background plus upscale under about 5 ms per frame on the device.

### Phase 2: Drawing primitives

- [ ] AA thin line (Wu style) and soft wide stroke into the soft layer.
- [ ] Stamp blitter: A8 masks, tinted, additive, 4 pre-blurred sizes.
- [ ] Rotated ellipse SDF with gradient LUT, half-plane clip and opening clip.
- [ ] Rotated A8 mask blit for text and icons, with outline mask.
- [ ] Micro-benchmarks for each primitive on the device, in cycles per pixel.
- [ ] Gate: every primitive's cost fits its row in the frame budget.

### Phase 3: Scene port

- [ ] Port the mock's scene logic to C: state timeline, NeBuLA pose table and springs, lens strands, mesh with accordion, mic strands with the retarded-time signal, speaking waveform, insight.
- [ ] Use fixed-point or float32 only; no doubles on the hot path.
- [ ] Golden-frame test: render fixed timestamps on the PC simulator and diff against PNGs exported from the mock's PORT PREVIEW mode.
- [ ] Gate: simulator frames match the mock at the chosen timestamps within a set tolerance.

### Phase 4: Glass layer and gravity lock

- [ ] Clock, status row, state label and arc subtitles as A8 masks from LVGL fonts.
- [ ] Button chips in panel space with counter-rotated glyphs.
- [ ] IMU angle with complementary filter and flat hold.
- [ ] Soft cache re-bake on angle change, spread across frames.
- [ ] Gate: the scene stays level through a full turn by hand, with no visible pop and no frame drops.

### Phase 5: Live inputs and voice integration

- [ ] Feed mic RMS and pitch from the audio front end into the stream model.
- [ ] Drive states from the real pipeline: wake word to listening, ASR end to thinking, TTS to speaking.
- [ ] Run with wake word and AFE active; measure core 0 load and frame time.
- [ ] Gate: 60 fps in listening and speaking with voice running, or the degrade ladder step that holds it is chosen.

### Phase 6: Power and polish

- [ ] Adaptive frame rate per state, plus always-on mode.
- [ ] Measure current draw at 60, 30 and 1 fps with an inline meter.
- [ ] Tune glow levels for RGB565 banding (ordered dither in the soft upscale if needed).
- [ ] Gate: battery life targets agreed and met for active and ambient use.

## Module layout

The renderer is one ESP-IDF component with no board knowledge. It talks to hardware only through the existing `rabble_hal.h` boundary, so the same code builds for the device and the PC simulator.

```text
firmware/
  components/
    nebula_lite/              # board-agnostic, builds on device and in the SDL simulator
      include/nebula_lite.h   # public API below
      src/scene.c             # state timeline, pose springs, frame packet build (core 0)
      src/lens.c              # almond outline strands and jitter LUT
      src/mesh.c              # hubs, layers, ring, accordion, signal schedule
      src/streams.c           # mic strands, retarded-time signal model
      src/raster_soft.c       # half-res layer, stamps, wide strokes, cached bake
      src/raster_crisp.c      # AA lines, ellipse SDF, spans, rotated mask blit
      src/compose.c           # per-band upscale, composite, circle mask
      src/luts.c              # gradients, atan, bell envelope, jitter tables
      assets/                 # pre-blurred stamps, icon masks (generated, checked in)
    entity_widget/            # LVGL custom widget: band buffers in, NeBuLA-lite out
    panel_flush/              # chord-clipped QSPI flush, TE pacing, DMA ping-pong
    gravity/                  # QMI8658 fusion, flat hold
  main/
    app_main.c                # wiring: HAL, LVGL, tasks, voice pipeline hooks
sim/
  CMakeLists.txt              # LVGL SDL build of nebula_lite + entity_widget
  golden/                     # PNGs exported from the mock's PORT PREVIEW
tools/
  export_golden.py            # Playwright export of mock frames at fixed timestamps
  bake_stamps.py              # generates stamp and icon masks as C arrays
```

**Public API sketch:**

```c
typedef struct {
    float t;                 // scene time, seconds
    float gravity_rad;       // filtered device angle
    float mic_rms, mic_pitch;// live audio features, 0..1
    uint8_t state;           // LISTEN, THINK, SPEAK, JOY, IDLE, AOD
    const char *subtitle;    // current subtitle line or NULL
} nl_inputs_t;

void nl_init(const nl_config_t *cfg);                 // buffers, LUTs, stamps
void nl_simulate(const nl_inputs_t *in);              // core 0: builds the next frame packet
void nl_begin_frame(void);                            // core 1: swaps packet, bins primitives
void nl_render_band(uint16_t *dst, int y0, int rows); // core 1: one band, RGB565
void nl_band_chord(int y, int *x0, int *x1);          // visible span per row for the flush
```

The golden-frame tooling reuses the Collective's existing Playwright capture pattern, the same one the Grimoire's boot-frame plan described.

## Risks and open questions

The biggest risk is the QSPI clock: if the GPIO matrix pins won't run reliably above 40 MHz, 60 fps depends entirely on circle-only flushes.

| Risk | Impact | Mitigation |
| --- | --- | --- |
| QSPI unstable above 40 MHz on matrix pins | Ceiling about 58 fps even circle-only | Phase 0 measures it; fall back to 45 fps targets or partial-region updates |
| Voice front end and wake word load core 0 | Simulation late, frames drop while listening | Measure in Phase 5; move geometry work to core 1 idle gaps; degrade ladder |
| CO5300 window alignment or command overhead per band | Chord flush slower than modelled | Taller bands (48 to 64 rows), 2-pixel aligned chords |
| Internal RAM pressure (Wi-Fi, BLE, AFE, band buffers, 106 KB soft layer) | Allocation failures | Drop the soft layer to one-third resolution (about 48 KB); stamps stay in flash |
| RGB565 banding in soft gradients | Visible rings in the nebula | Ordered dither during upscale |
| Pendant flat on a table | Undefined gravity angle | Flat hold with hysteresis |
| Battery drain at 60 fps | Short active time | Adaptive fps and always-on mode; measure in Phase 6 |
| Muse SDK display path differs from esp\_lcd | Flush layer needs adapting | Keep panel\_flush behind the HAL; review once the code is visible |

**Open questions:**

- [x] Push the new-horizons branch of RaBbLE-Pocket. Done S250; the base is reviewable on GitHub.
- [ ] Must listening hold 60 fps with the voice pipeline live, or is 45 acceptable there?
- [ ] Does the Muse SDK expose esp\_lcd panel handles and TE, or its own display layer?
- [ ] Which reset pin is correct, GPIO39 or GPIO1?
- [ ] Is the 1.75C (aluminium, no TF slot, 32 MB flash) the shipping target? It changes asset placement and the battery figure.
- [ ] Does the earlier esp\_emote\_gfx / ThorVG plan still apply for baked expression clips alongside this procedural renderer?

**Sources:**

- [Waveshare ESP32-S3-Touch-AMOLED-1.75 hardware reference](https://github.com/waveshareteam/ESP32-S3-Touch-AMOLED-1.75/blob/main/HARDWARE_REFERENCE.md)
- [Waveshare ESP32-S3-Touch-AMOLED-1.75 wiki](https://www.waveshare.com/wiki/ESP32-S3-Touch-AMOLED-1.75)
- [ESP-IDF SPI Master driver, ESP32-S3](https://docs.espressif.com/projects/esp-idf/en/stable/esp32s3/api-reference/peripherals/spi_master.html)
- [esp-hal issue 6330: CO5300 QSPI board support](https://github.com/esp-rs/esp-hal/issues/6330)
- RaBbLE-Grimoire (new-horizons): RaBbLE-Pocket-V1-Firmware-Plan.md, RaBbLE-Pocket-Firmware-BuildFlash.md, NeBuLA-Pocket-Puppet-Rendering-Pipeline.md
