# RaBbLE-Pocket-Roadmap.md

Open questions and next steps. Source: Mark's project rundown, 2026-08-07. Update as items close.

## Open Questions / Next Steps

- [ ] Entity port to 60 fps (S250): see `RaBbLE-Pocket-Entity-Port-Plan.md`. Phase 0 done (80 MHz + TE = 60 fps). Phase 1 done (PIE SIMD). S251: KISS entity (eyes, portals, NN mesh, mic strands, ring, glass) live in the gadget firmware at ~20 fps; next: `log/handoffs/HANDOFF-S251-Pocket-Entity-60fps.md` (60 fps idle). Fonts (Aether OFL) deferred.

- [x] v1 firmware (idle face, boot animation, settings, two-tier sleep/wake) — built + hardware-verified end to end 2026-08-08. See `RaBbLE-Pocket-V1-Firmware-Plan.md` and `RaBbLE-Pocket-Architecture.md`.
- [ ] Root-cause the I2C transmit error seen once at a Tier 1 sleep entry (touch controller IRQ poll likely racing light-sleep transition) — non-fatal, not blocking, noted in `planning/decisions/2026-08-08-two-tier-sleep.md`
- [ ] LVGL drag-and-drop UI simulator (Mark's ask, deferred out of v1) — build once real screen needs beyond idle/settings/boot become clearer
- [ ] NeBuLA/Aether → LVGL asset-translation pipeline (Mark's ask, deferred out of v1) — mock in NeBuLA, render on Pocket
- [ ] Confirm which wake-word engine ships in v1 firmware (ESP-SR vs. porting VIT concepts)
- [ ] Decide BLE audio codec and chunking protocol for wake-word utterance transport
- [ ] Build out BSP for -B board; validate mic, display, IMU, touch via Waveshare demo firmware first
- [ ] Order/receive 1.75C aluminum board; port firmware once -B is stable
- [ ] Finalize idle-state animation (static vs. reactive pulse pre-wake-word)
- [ ] Address AMOLED burn-in mitigation for static idle elements (time digits, pill icons)
- [ ] Investigate RT700 EVK for future voice-pipeline validation (v2/v3 target)
- [ ] Custom case design decision — build around -B/bare 1.75 board (keeps RTC + TF slot + pluggable header) vs. 1.75C form factor

## Status Relative to Collective

`release_track: independent` — not part of the Episode 1 web/OS lockstep. Paces on its own; Grimoire tracks divergence per the Echo coherence policy in `registry/epochs/current.epoch.yml`.
