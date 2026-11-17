> Recovered from the 2026-11-17 chat export: written during the chat "Reducing ESP32 display boot time on RaBbLE pocket" (2026-08-09). Verbatim, not reconciled with current canon. The original file was named SESSION-LOG-S[TBD]; the session number was never assigned.

# SESSION-LOG-S[TBD].md — RaBbLE Pocket: Boot Latency, Power Modes, and DSP/NPU Path

> **Note:** Session number not tracked on this end — replace `S[TBD]` in the filename and header with the correct sequential session ID before import.

```
mend ~ pocket >> boot latency diagnosed, power modes mapped, ambient-capture testing plan scoped, NXP DSP path evaluated and shelved in favor of ESP32-S3 + future bolt-on module // %POCKET_PLATFORM_HOLD%
```

**Member:** RaBbLE-Pocket
**Related:** RaBbLE-Pocket-Project-Rundown.md, RaBbLE-Attachments-and-Mesh.md
**Status:** Working session — diagnostic + decision, no code changes made

---

## Context

Follow-on session to RaBbLE Pocket hardware bring-up. Board: Waveshare ESP32-S3-Touch-AMOLED-1.75-B, CO5300 AMOLED driver (QSPI), AXP2101 PMIC, PCF85063 RTC. Observed: cold power-on to first display frame is ~1.5s, which feels slow; resume from sleep is instant.

---

## 1. Boot Latency — Findings

- Resume-instant / cold-boot-slow strongly indicates the ~1.5s cost lives in **cold-path-only** work: full CO5300 register init table, AXP2101 rail sequencing from zero, and likely panel state that persists across light sleep (registers retain state if VCI/logic power isn't cut).
- Panel's own mandatory hardware settle time (reset pulse + post-reset/sleep-out delay) is a real but small floor — estimated ~100–250ms based on typical AMOLED-controller behavior, not confirmed against CO5300 datasheet directly.
- Primary suspects for the remaining ~1.2s+: Waveshare demo-code init sequences likely carry conservative/copy-pasted `vTaskDelay()` values well past datasheet minimums; bootloader/app log verbosity at default levels; possible non-essential peripheral/radio init happening before first frame is pushed.
- **Recommended next step (not yet done):** instrument with `esp_timer_get_time()` around each boot stage (AXP2101 rail-enable, panel reset, panel init-table write, sleep-out+delay, first-frame push) to find the actual dominant cost before trimming blind.
- Secondary levers identified: set `CONFIG_BOOTLOADER_LOG_LEVEL` / early app log level to `ERROR`/`NONE`; defer WiFi/BLE/filesystem/sensor init until after first frame is on screen.

## 2. Power Modes — Findings

- **ESP32-S3 deep sleep:** datasheet figure ~7µA (RTC memory retained), independently confirmed close to spec on bare modules (~8µA measured). Board-level peripherals (AXP2101, PCF85063, QMI8658, CST9217) are NOT included in that figure and may dominate actual system draw — board-level measurement needed, not just chip datasheet.
- **PMIC rail cutoff + external RTC wake:** not an ESP32 sleep mode at all — it's a full power-on reset (POR) on wake, indistinguishable from cold boot. Means paying the full boot-latency cost (see §1) on every wake from this state. Whether it beats ESP32 deep sleep on power depends on AXP2101 shutdown-mode quiescent current, which was not determined this session — needs AXP2101 datasheet lookup.
- **Light sleep:** CPU halted but state retained, no reboot, wake is fast (documented <10ms typical) — this is almost certainly what's producing today's "instant resume" behavior. Higher idle draw than deep sleep, but no display cold-init cost on wake.
- Deep sleep wake is *also* a full reboot through the ROM/2nd-stage bootloader on this chip (self-contained via RTC domain, vs. externally via PMIC) — so deep sleep does not avoid the display cold-init cost either, only the PMIC-cutoff path is meaningfully worse in that regard (external dependency + same reboot cost).

## 3. VAD / Wake Architecture — Findings

- Continuous VAD requires either (a) CPU active/light-sleep duty-cycling (wake periodically, sample, check, sleep), or (b) offloading "is there sound" to dedicated low-power wake-on-sound hardware so the ESP32-S3 can stay in full deep sleep until triggered. True continuous processing during deep sleep is not possible — CPU is halted.
- ESP32-S3's ULP-RISC-V coprocessor is not well suited to continuous real-time PDM audio processing — designed for periodic simple checks, not sustained audio stream analysis.
- Evaluated dedicated wake-on-sound hardware: **Vesper VM3011** — MEMS mic with adaptive threshold-based wake-on-sound, ~10µA continuous listening current, ~1µs interrupt latency. Threshold/energy-based, not true speech-specific VAD. Sourcing/availability post-acquisition not confirmed this session. **Knowles IA61x SmartMics** noted as a more capable (onboard DSP, true wake-word) but likely costlier/harder-to-source alternative — not investigated in depth.
- Physical constraint noted: EXT0 wake is already wired to the power button; no easy tap point without soldering. Open paths identified, not yet resolved: (1) check whether any of the 3 header-exposed GPIOs are RTC-capable for EXT1; (2) check whether AXP2101 has a spare GPIO that can be routed through its existing IRQ line to the ESP32; (3) fallback — stay on light-sleep duty-cycle VAD, no new hardware needed. Requires board schematic to resolve — not available in-session (on phone).

## 4. Ambient Capture Self-Test — Scoping

- Pocket confirmed as the intentional "dev playground" / self-test vehicle for calibrating how ambient-capture-style interaction feels, ahead of/feeding into the Collective's still-open "ambient suggestion threshold" and "which signals are OK to self-observe" questions (per RaBbLE-Vision-Arc open items).
- Planned architecture: wake/classifier-triggered recording (not continuous) as the default; local on-device transcription ruled impractical on ESP32-S3 (compute-bound) — plan is capture + light filter (e.g., silence-trim/noise-gate) on-device, batch transcription later on companion/cloud.
- Storage math checked: even continuous 16kHz mono PCM capture is inexpensive on modern SD cards (~165MB/day uncompressed, ~20-30MB/day Opus-compressed) — storage is not the binding constraint.
- **Battery is the binding constraint** for any full/continuous-capture test: sustained mic + SD write + upload is tens-of-mA active-mode draw vs. µA-range triggered wake; full-capture testing should be a deliberate, explicitly-flagged bounded test mode, not a default.
- Flagged for consideration, not resolved: raw audio at rest on physical SD card is an unencrypted security surface if device is lost; acceptable for solo guinea-pig phase, revisit before multi-user.
- Noted: full-capture self-testing has a validity caveat — Mark, as the builder who always knows recording is active, is not a representative proxy for how a naive user would react to ambient capture. Useful for validating the mechanism works; less useful for validating the "creepy" question directly.
- **Decision:** primary path remains wake/classifier-triggered capture. Bounded, explicitly-flagged full-capture test sessions may still be run as a separate experiment for comparison.

## 5. NXP DSP/NPU Path (i.MX RT700 / i.MX 8ULP) — Evaluated and Shelved

- Question raised: upgrade path from ESP32-S3 to NXP silicon for richer local ambient intelligence, informed by Mark's prior i.MX 8ULP experience at NXP (unresolved internal "problem child" reputation at the time).
- **i.MX 8ULP:** applications processor (dual Cortex-A35 + Linux/Android, separate Cortex-M33 real-time domain with Tensilica Fusion DSP for low-power wake, separate LPAV domain with HiFi4 DSP @475MHz for advanced audio/ML). Architecturally a genuine fit for the wake→classify→understand pipeline in principle. Confirmed still an active NXP product line with third-party module support (Linux 6.6 LTS, long-term availability commitments) — external signal of ecosystem maturity, but does not confirm whether Mark's specific prior pain points are resolved.
- **i.MX RT700:** crossover MCU (dual Cortex-M33 + HiFi4 DSP + HiFi1 DSP + eIQ Neutron NPU), no Linux — more directly comparable to current ESP32-S3 role, previously identified as the planned v2/v3 target in the Pocket Rundown.
- **Key finding this session:** the Cadence Xtensa Xplorer toolchain is shared across both chips — it is not an 8ULP-specific pain point. RT700 does remove 8ULP's Linux remoteproc/RPMsg IPC layer (RT700's DSP boots directly from the M33 without Linux mediation), which is a real structural improvement if that specific layer was the pain point — but does not fix Xplorer/Cadence tooling itself if that's the actual source of frustration.
- Mark's assessment, drawing on direct hands-on experience (weighted above general web research): the entire Cadence/Xtensa ecosystem integration reads as still an internal uphill effort for NXP, not a finished/owned product experience — multi-step Tensilica Tools registration, modified-Eclipse IDE described as obtuse/cumbersome, a second full toolchain layered above MCUXpresso requiring co-debugging across two apps, and a DSP architecture (multi-MAC VLIW) that resists straightforward C and rewards deep hand-tuning. Consistent with external signals found this session (in-progress Zephyr RT700 DSP toolchain PR, known SDK limitation with SBC decoder not working on RT700's HiFi4).
- Mark has prior direct experience porting TFLite Micro to HiFi4, which would reduce (but not eliminate) the tooling tax if this path were revisited — the one-time model-porting difficulty is de-risked, but ongoing environment/registration/co-debug friction remains.
- **Decision:** NXP DSP/NPU path (RT700 or 8ULP) shelved as a known-but-not-pursued option, not rejected outright. ESP32-S3 remains the platform — hardware in hand, dev flow liked, working boot/power foundation. Any future need for heavier on-device audio ML (beyond hand-rolled FFT/filterbank signal processing, which is the default near-term approach) will be solved as a **bolt-on coprocessor module** (SPI/I2C/UART-attached DSP/NPU board) rather than a full platform migration, preserving the existing BSP abstraction and avoiding a firmware architecture rewrite.

---

## Open Items Carried Forward

- [ ] AXP2101 datasheet: confirm shutdown/ship-mode quiescent current (needed to properly compare PMIC-rail-cutoff vs. ESP32 deep sleep)
- [ ] Board schematic/pinout: confirm which (if any) of the 3 header-exposed GPIOs are RTC-capable, for EXT1 wake without touching the power-button trace
- [ ] Instrument boot sequence with `esp_timer_get_time()` per-stage to confirm actual dominant cost before trimming CO5300 init delays
- [ ] Vesper VM3011 current sourcing/availability unconfirmed — verify before treating as a viable BOM item
- [ ] Decide whether "ambient suggestion threshold" learnings from Pocket self-testing should feed back into the Collective's Memory member design questions (flagged, not actioned this session)

---

```
mend ~ pocket >> platform hold confirmed: ESP32-S3 primary, NXP DSP shelved, bolt-on module deferred, boot/power/VAD diagnostics scoped for next session // %POCKET_PLATFORM_HOLD%
```
