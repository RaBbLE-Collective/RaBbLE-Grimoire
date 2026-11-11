# RaBbLE-Pocket-Orbit-Transition.md

> How the face hands over to the Orbit (Settings, Applets) and back: one gesture, an edge glow, the mesh gathering into orbs and going home again. Built and hand-checked S274 (2026-10-24), Pocket `6d26a76`; Mark: "Great!!!!".
> The Orbit itself (pages, dial, items) is specced in `cleanroom/w5-orbit.spec.md`. This file covers only the transition, which was reworked after W5 with Mark at the device.

## What it should feel like (Mark's asks, in his words where they matter)

- **Embodied, one gesture.** "The swipe should have similar action/animation and feel like a faster version of the entity interaction." Touching the face and swiping to the Orbit are the same movement at different speeds, not two actions.
- **The mesh is anchored and stretches, it doesn't travel.** "The NN mesh should be anchored and stretch like a mesh but not move when swiping", "pulled by the swipe, not recede".
- **The orbs come from the mesh.** "The orbs should look like part of the hidden mesh as the mesh stretches." The entry "should morph from the mesh into the orb more, not just look like a disjoint new mesh".
- **One mesh, one colour.** Settings belongs to the **magenta** mesh side, Applets to the **cyan** side, both ways. "The mixing of cyan and magenta in the mesh reads a merge and looks off." The colour follows the mesh half, so a turned face still gets the right one.
- **The return mirrors the entry.** Same mesh, same colour, the same links visible; edge-bound, not "explosive/unbounded"; the returning half of the mesh visible on its own edge, not the other.
- **Change your mind mid-swipe.** Starting one way and dragging back past the start brings the other Orbit.

## How it works

| Piece | Where | What it does |
|---|---|---|
| The grab | `rabble_entity.c` (`TOUCH_GRAB`) | A thumb on the face carries it 0.35 of the way it has moved (max 40 px), the same rate the entry slide follows (`ENTRY_K`), so the grab runs on into the pull without a seam. Once the pull has the thumb, the slide carries the sideways part. |
| Touch kept alive | `rabble_ui.c`, `rabble_orbit_pulling()` | While an entry drag pulls, the face still feels the thumb (lean, mesh dent); before S274 the Orbit took the touch and the face was told the thumb was up. |
| Late engage | `rabble_orbit_logic.c` `GS_DEAF` (`ENGAGE_PX` 40) | A touch that began as play still becomes the pull once clearly sideways. |
| Flick | `FLICK_V` 700 px/s past `FLICK_PX` 36 | Commits early, also on release mid-flick. |
| Side switch | `GS_ENTRY` | Back past the start by 16 px the other way: the other Orbit (slide passes through 0, nothing jumps). |
| Pull, snap, closing | `orbit_ctl_t.pull`, stepper `snap` / `closing` / `was_open` | `pull` 0..1 to the detent; `snap` is the orbs' own clock (0.9 s in, `SNAP_BACK_S` 0.6 s back, an exit drag scrubs it); `closing` once committed and heading home; the close spring is slower (`SLIDE_BACK_OMEGA`). |
| Edge glow | `orbit.c` 2b | Either side of the colour ring (it covers its own band, 206.5..221.5 px), in that side's colour, as the thumb pulls. |
| Mesh pin and stretch | `scene.c` `mesh_layer` (`MESH_STRETCH`) | The stage slide is given back so the mesh doesn't travel; pinned at the Orbit's edge **both ways**, stretched with the thumb's pull. Links fade over 0.3..1 of the slide, nodes over 0.7..1. |
| The shared mesh | `nl_mesh_*` in `nl_internal.h` | The scene shares its mesh read-only while an Orbit slides: every node on screen, the edges, how strongly each is drawn before the slide's fade. `nl_orb_mesh_side` says which half the orbs have taken; the scene leaves that half to `orbit.c`. |
| The orbs | `orbit.c` 2c | At commit: the half lying towards the Orbit (by screen position) and its colour, one start node per item, every node of the half shared out evenly among the orbs. Nodes gather into their orb, the half's real links stretch between the orbs, orbs travel round the rim to their items (staggered round the dial), swell, bounce, ripple, items fade in over them. The return plays the same backwards from where the dial was, the mesh coming back out of the orbs where it now is. |

## Lessons (the expensive ones)

- **Render it before flashing.** `RaBbLE-Pocket/sim/transition.sh` renders both Orbits in and out as GIFs and contact sheets (`sim/out/tr_*`). Three flash cycles went on guessing colours that one render showed at once.
- **Run the Orbits one after another in the sim.** Whatever a transition latches (side, colour, start points, dial positions) must reset whenever the Orbit isn't shown. A stale latch showed Applets' cyan on Settings on the device only, because the sim ran each side fresh; it now runs Applets then Settings in one process.
- **A pin flip on the return put the wrong half on screen.** Pinning at the opposite edge on the way back stretched the Orbit's half off the panel and left the other colour showing.
- **Driving the return by the slide made it explosive.** The close spring drops fast and the items slide off with the Orbit; the return has its own clock and lifts the orbs off where the dial was.
- **Ask what a visual word means** ("edges", "orbs", "return colour") before tuning: several rounds went on the wrong reading.

## Tunables

`TOUCH_GRAB` 0.35, `TOUCH_GRAB_MAX` 40 · `ENGAGE_PX` 40 · `FLICK_V` 700, `FLICK_PX` 36 · `DETENT_PX` 140 · `SNAP_S` 0.9, `SNAP_BACK_S` 0.6 · `SLIDE_BACK_OMEGA` 10 · `MESH_STRETCH` 0.5 · `ORB_FROM_R` 175.

## Open

- About 2 KB more internal RAM (mesh share and orb buffers). If internal memory pressure bites (beam task creation, stack), move them to PSRAM.
- The edge glow's colour comes from which Orbit it is, not from the mesh half; it matches while the face stands, not when turned.
- Pages with more than 16 items skip halos, ripples, nodes and signals to stay inside the Orbit's share of the display list.
