# RaBbLE-Pocket-Roadmap.md

Open questions and next steps. Source: Mark's project rundown, 2026-08-07. Update as items close.

## Open Questions / Next Steps

- [ ] Entity port to 60 fps (S250): see `RaBbLE-Pocket-Entity-Port-Plan.md`. Phase 0 done (80 MHz + TE = 60 fps). Phase 1 done (PIE SIMD). S251: KISS entity (eyes, portals, NN mesh, mic strands, ring, glass) live in the gadget firmware at ~20 fps. S252: **60 fps idle**, about 30 fps busy and turning. Next: `log/handoffs/done/HANDOFF-S252-Pocket-Settings-Orientation-Clean-Room.md`. Fonts (Aether OFL) deferred.
- [ ] Settings composited by the entity renderer, turning with the device (S252 handoff, settings track S1 to S3). S254: S1, S2 and the clock screen built, fps gates met on the gadget (slide 31 to 34 fps, turning ~30); visual and touch gates pending Mark; old LVGL face keep-or-drop pending Mark.
- [ ] Clean room off Meta's code: `RaBbLE-Pocket-Clean-Room-Plan.md` (W0 seam after settings S1: S1 merged in S254, seam now has `ui_texture`/`ui_texture_tag`).
- [ ] Converse/Capture modes + Pocket Grimoire notes (S264): `RaBbLE-Pocket-Capture-Plan.md`. T0 freeze fix, T1 tilt, T2 sCoRE capture, T3 notes store (S265) done; next T5 host offload spell, T4 swipe modes; voice capture after W4.
- [ ] Level applet polish (S264, Mark: "still needs more work"): Settings > Level works (3 flats, a full turn, a trim by eye) but the flow and look need a pass; consider a face-visible fine tune and remembering when it was last done.
- [ ] Face feel tuning (S264): motion sway, touch dent/lean/gaze and motion-driven mesh activity are in (`rabble_entity.c` SWAY_*/TOUCH_*, `scene.c` TOUCH_*); Mark to settle the amounts by hand.
- [ ] **Shake swaps colours** (Mark, S265 idea): a vigorous shake swaps the entity's colours (cyan and magenta trade places, eyes, portals, meshes); swaps back on the next vigorous shake, or settles back over time (undecided). Hook: `rabble_motion_since_shake()` / the shake time above 1 g already feeds the dizzy wobble; needs a "vigorous" threshold above the dizzy one. Palette colours only.
- [ ] **Settings swipe needs resistance** (Mark, S265): the swipe to Settings should take more pull and then snap over, like a detent, so touching and dragging the entity (dent, lean, gaze) never slides Settings in by accident. Only an intentional swipe that passes the resistance commits; short of it, the face springs back.
- [ ] **Settings fluidity: min 40 fps** (Mark, S265): sliding into and using Settings feels like ~20 fps; target is at least 40 fps. S254 measured the slide at 31 to 34 fps and turning ~30, so it needs real work (profile the composited LVGL texture path first). Pairs with the W5 settings redesign.
- [ ] **The RaBbLE-Pocket SDK on the Sovereign Accord** (Mark, S266; S267: the SDK *is* RaBbLE-Pocket, for round ESP32-S3 boards (1.75B, 1.75C next, more targets later), all SA or isolated permissive code; next after W6 + W7, ahead of Pomodoro; app / sdk / boards layering approved by Mark, "RaBbLE-Pocket is a class of gadget"; see `log/handoffs/done/HANDOFF-S267-Pocket-CleanRoom-Final-SDK.md`): reorganise the firmware into clearer, more succinct components and modules (today the gadget is one large `rabble_gadget/accord/`: split e.g. board, power, motion, audio/voice, net/beam, store, ui/face, orbit, console into components with small public headers). Plan the layout with Mark first.
- [ ] **Applets orbit + Pomodoro** (Mark, S266; build right after W5 lands): swipe **right** from the face opens an Applets orbit (mirror of Settings, same renderer and gestures). Pomodoro first: turn the dial to pick the length (defaults 25 min focus, 5 min break, 15 min long break after 4 rounds), hold the centre to start or pause. While it runs the colour ring is a draining arc in every view (violet focus, green break); the face narrows into a watchful look and the mesh calms; a round's end chirps, makes it happy and starts the break; rounds shown as dots. Keeping Mark on task (his picks): **notice fidgeting** (picking it up, shaking or poking it during focus earns a disapproving look and a ring flicker, and counts against the round) and **check-in nudges** (every ~10 min of focus a soft chirp and glance; a tap says "still on it", no tap in 30 s and it looks concerned). Spoken nudges via sCoRE deferred to the vocoder voice.
- [ ] **S266: the Orbit** folds the three Settings items below into W5 (`cleanroom/w5-orbit.spec.md`): a native nebula_lite dial, resistance + snap entry, hold-to-fill toggles, ≥ 40 fps gates. Same session: gyro on (face follows turns, holds heading flat, springy sideways shake, spin reactions by speed), colour ring in every view (mode, battery, error, offline dim), mode icon under the clock (tap to switch).
- [ ] **Settings round-screen redesign** (Mark, S265): Settings is still a rectangular list on a round 466 px panel; redesign it for the round screen (radial or arc layout, rows that follow the rim). Folds into W5 settings_ui + keypad redesign (Mark's layout first; must carry the Level row) and the "settings transition should feel like RaBbLE" note in the capture plan.
- [ ] **Boot: rotating portal edges** (Mark, S265): the Pocket boot sequence should have the rotating portal edges of the RaBbLE-OS boot (Plymouth / SDDM boot, rendered from NeBuLA `Boot.html`). Reference it, don't hand-port it blind: match its portal-arc rotation in the entity renderer's boot (`in.boot`, `rabble_entity_lit`).

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

## EP2 — Local Beam (Pocket → Laptop sCoRE → Claude)

- [ ] **Local beam auto-connects when at home** (S269 spec): Pocket points at `rabble-os.local:8000` by default; when RaBbLE-OS is running and local sCoRE is up, the beam routes to Claude Code on the laptop with the full local Grimoire. No URL change needed — the firmware default already points there. Architecture: `RaBbLE-sCoRE/RaBbLE-sCoRE-Local-Pocket-Beam.md`.
  - [ ] Laptop: set hostname `rabble-os`, avahi running, port open in firewalld
  - [ ] `BEAM_LLM_CHAIN=claude_code:claude-haiku-4-5-20251001` in local sCoRE env
  - [ ] `BEAM_DEVICE_TOKEN` set in both local sCoRE env and on the Pocket (`>beam.token=`)
  - [ ] Decide port: 8000 (matches firmware default) vs 8083 (avoids fcc collision) — tracked in beam spec
  - [ ] Ansible role addition (beam token + avahi + firewalld) in RaBbLE-OS ai-harnesses

## Status Relative to Collective

`release_track: independent` — not part of the Episode 1 web/OS lockstep. Paces on its own; Grimoire tracks divergence per the Echo coherence policy in `registry/epochs/current.epoch.yml`.
