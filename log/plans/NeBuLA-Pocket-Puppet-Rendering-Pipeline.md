# RaBbLE Puppet and Pocket Rendering Pipeline — Research Session

**Scope:** Competitive landscape review for RaBbLE as an entity-based ambient intelligence platform, followed by a concrete rendering and animation pipeline spanning NeBuLA and RaBbLE Pocket. Session is convergent across both members — puppet design and pocket portability are treated as one continuous pipeline problem.

---

## Competitive Landscape

No direct competitor exists, but philosophical cousins are emerging under names like "Autonomous Personal Entity" and projects like Lexi.AI — validating sovereign, local-first, entity-not-app framing as a real emerging category rather than an isolated idea.

Closest built-out projects:
- **Super Agent Party** — AGPL licensed, mature multi-agent orchestration, self-hosted.
- **Project AIRI** — MIT licensed, Vue + Three.js based VTuber companion framework. Full monorepo with audio pipeline, memory, rendering, and avatar puppeting.

**Licensing note:** AIRI's `unspeech` package (universal ASR/TTS proxy) is actually **AGPL at the repo level**, despite MIT labels floating around the broader ecosystem. Treat it as an external sidecar service called over HTTP if ever used — never vendored or forked — to avoid copyleft obligations under the Sovereign Accord model.

---

## Puppet Rig Authoring — Decision

**Rejected: Live2D.** Proprietary, revenue-gated free tier (~¥10M / ~$70K annual revenue threshold), paid publication license required beyond that. A business-model dependency, not just a licensing footnote.

**Considered: Inochi2D.** BSD 2-Clause, fully permissive, real and maintained (1.7k+ stars on core SDK). Written in the **D language** — a niche systems language, GC by default, C/C++-like syntax, small ecosystem. Real tradeoff to learn just for this. `inox2d` (Rust reimplementation, also BSD) noted as a friendlier alternative given Rust familiarity.

**Decided: Godot**, used as an authoring studio, not a runtime dependency.
- MIT licensed, fully permissive, mature.
- Exports natively to **glTF 2.0** — carries skeletal animation and morph targets cleanly, natively consumed by Three.js (covers NeBuLA's future 3D path essentially for free).
- Genuinely CLI/headless-friendly — fits a trackpad-only, terminal-forward workflow.
- Mature MIT-licensed MCP servers exist (e.g. "Godot AI") connecting Claude Code directly to a live Godot editor for scene/script/animation work.

---

## Pipeline Architecture — Three Tiers, One Schema

All three tiers share **one locked parameter schema** (named puppet parameters — eyes, glow intensity, particle spread, position, etc.). This means a new animation later = one Godot edit + two exports, not a schema rewrite.

1. **Godot** — rig is built and keyframed here. Skeleton/mesh deforms for face + particle system. Sequenced states: idle, listening, thinking, speaking.
2. **NeBuLA (Web, Canvas2D)** — consumes either glTF (future 3D path) or baked keyframe curves as JSON (current vector 2D renderer).
3. **RaBbLE Pocket (ESP32-S3)** — consumes a separately baked, embedded-appropriate format. Cannot run glTF or a general 3D pipeline.

---

## Pocket Rendering Stack

- **Runtime:** `esp_emote_gfx` — Apache 2.0, lightweight embedded graphics library built on **ThorVG** (MIT licensed, confirmed running on ESP32-class MCUs).
- **Workflow:** source animation (typically GIF) → imported into companion browser-based packer tool `esp_emote_gen_player` → exports a single binary blob sized to target display resolution.
- Binary format already supports **segment planning and clip-transition timing** (immediate cut, or handoff-after-current-clip) at the library level. Pocket's own state machine only decides *which clip and when* — not how to blend.

### Flash & Storage Architecture

- Animation asset binary should live in its **own dedicated flash partition**, separate from app/OTA partitions — enables OTA graphics updates by writing to that partition offset without touching firmware.
- Typical 16MB board split: ~2 small OTA app slots + a larger multi-MB assets partition.
- **SD card** (confirmed present, 8GB planned) is the better home for a large expansion library of expressions/states — internal flash retains a small always-available core clip set so the device boots and reacts even with no card inserted.

---

## Dynamic / Reactive Layer (Separate from Baked Clips)

Baked EAF clips cover named expressions (happy, startled, etc.). True reactive, self-animating behavior — responding to live mic input or a liquid-time-clock signal — needs a **separate procedural draw layer** using ThorVG's vector primitives directly, not clip playback.

**Proposed minimal live parameter set** (5–6 floats, updated per frame):
- Amplitude (smoothed mic loudness)
- Optional pitch/spectral estimate
- Liquid time value
- Idle-energy / restlessness (decays since last interaction)
- Mood / valence (set by higher-level state logic)

These map onto visual knobs — glow radius, particle spread, wobble frequency, color temperature — redrawn each frame. Keeps the render pass cheap and dumb; personality/behavioral complexity lives entirely in the logic layer above and can grow independently.

---

## Portability / BSP Architecture

Existing plan — one shared HAL interface + a BSP file per board — is validated; matches how both LVGL and Espressif's own `esp-bsp` project are structured. Makes releasing RaBbLE Pocket as flashable firmware for **any compatible board**, alongside an optional first-party device, a coherent technical plan. Compatibility becomes a matter of enumerated board support (display driver, mic, flash/PSRAM headroom) rather than architectural lock-in.

---

## Simulation & Testing

- **QEMU (official Espressif fork for ESP32-S3):** emulates CPU, memory, peripherals; integrated into `idf.py`. Peripheral/display-driver coverage still incomplete/WIP.
- **LVGL desktop simulator (SDL):** same GUI code compiles for Linux/macOS/Windows, thin swap layer between simulated and real hardware data providers. This is the practical daily fast-iteration loop, fits Fedora/laptop-forward workflow.

---

## Boot Time & Power — Open Thread

Time-to-first-pixel frustration is likely **two distinct problems**: cold boot from full power-off vs. wake-from-sleep. Need separate optimization approaches.

**Proposed fix:** splash-frame pattern — init display QSPI connection and push a trivial hardcoded frame (e.g. boot ring animation) as early as possible in boot sequence, before the rest of the app stack (WiFi, LVGL widget tree, etc.) initializes.

**Sleep mode decision:** Deep sleep confirmed as correct target over light sleep, given RTC + physical button already present, for weeks-scale ambient battery life goal. Deep sleep wake is a genuine reboot — makes the early-splash-frame trick more valuable, not less.

**Battery math (rough order of magnitude, 320mAh):**
| Scenario | Draw | Runtime |
|---|---|---|
| Ideal chip-only deep sleep | ~10µA | ~1,333 days |
| Realistic w/ PMIC + RTC + leakage | ~100µA | ~133 days |
| Pessimistic w/ PMIC + RTC + leakage | ~300µA | ~44 days |

Weeks-to-month-plus ambient life is plausible even under pessimistic assumptions — **but unverified**, no granular power metering currently on device (PMIC-level visibility only). Suggested first step: basic inline USB power meter or multimeter before any dedicated profiling hardware (e.g. Nordic Power Profiler Kit).

---

## Open Items / Next Steps

- [ ] Instrument actual time-to-first-pixel (wake trigger → first pixel) to separate firmware-boot vs. panel-init delay
- [ ] Basic power metering on device (inline meter) before further boot/sleep optimization
- [ ] Decide glTF vs. baked-JSON-curve path for NeBuLA Canvas2D consumption
- [ ] Lock the named puppet parameter schema (shared across Godot / NeBuLA / Pocket exports)
- [ ] Evaluate `esp_emote_gen_player` packer output sizes against real rig once first clips are authored
