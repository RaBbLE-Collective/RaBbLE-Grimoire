# RaBbLE-Pocket-Roadmap.md

Open questions and next steps. Source: Mark's project rundown, 2026-08-07. Update as items close.

## Open Questions / Next Steps

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
