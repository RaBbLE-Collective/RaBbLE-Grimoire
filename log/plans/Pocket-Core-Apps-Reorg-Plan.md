# Pocket core / apps reorganisation (decisions, 2026-11-04, S311)

> Status: DECISIONS RECORDED, nothing moved yet. Mark's rulings in his words where marked **Mark**. Open points at the end. Related: `Pocket-Foundling-Open-App-Plan.md`, `Pocket-Open-SDK-App-Separation-Plan.md`.

## Shape

The Pocket firmware is a small entity OS: a shared open base (`core/`) that apps build on, plus drivers and boards. RaBbLE and Foundling are apps on it. The SDK is the whole tree and can build new apps.

```
firmware/
  core/      shared base, open, in transition to Apache-2.0 (Mark, 2026-11-04: "core or common for now"; working name `core/`; "OS" rejected: RaBbLE-OS is the distro member)
  drivers/   chip drivers
  boards/    board folders
  apps/
    RaBbLE/      Sovereign Accord; owns its main.c, its look and feel, the sCoRE beam and voice turn
    Foundling/   open; owns its main.c; only its own code
  tools/       panel_bench, hw_test (or tests/)
```

- **Licence follows the directory** (Mark): `core/`, `drivers/`, `boards/`, `apps/Foundling` carry SA + the `Open-transition: Apache-2.0` marker now and flip together. `apps/RaBbLE` stays SA. No second "Foundling core": core holds nothing RaBbLE-specific, Foundling-only code lives in `apps/Foundling`.
- **No `main/` folder** (Mark): each app holds its entry point (`main.c` or equivalent) and its own CMakeLists; `RABBLE_APP` selects the app.
- `rabble_` prefixes stay (Mark, 2026-11-02). Names do not decide openness; the directory does.
- Today everything is SA; only `open_entity_default`, `rabble_screen` and `app/Foundling` carry the marker. `rabble_board.h` is the one file with Meta's notice (W11 replaces it); until then the open core is not clean.

## core/ contents

Seam (`rabble_core`: board, state, settings, console, time, text, device, palette), `rabble_lvgl_port`, `rabble_screen` (W9), `rabble_power`, Wi-Fi (**Mark: Wi-Fi is a core service**; split from `rabble_net`), `rabble_audio`, `rabble_motion`, `rabble_store`, an entity slot (mood, level, tick interface that apps fill), and the Orbit component below.

Also core (Mark, 2026-11-04): **voice**, because any entity should be able to speak. Core owns the push-to-talk loop, endpointing, outbox and a voice-backend interface; each entity brings its own voice profile and config for how it talks (RaBbLE has a custom one). The sCoRE beam is one backend; whether that backend lives in core or in the app is open (W8 put it app-side, D5).

`rabble_render` IS nebula_lite: the display-list store, band rasteriser, composer, SIMD kernels and the Orbit's drawing (`src/orbit.c`). **Mark, 2026-11-04: the renderer is its own NeBuLA-lite (or NeBuLA-micro) component and is SA licensed**, so it is NOT in the open `core/`. It sits beside core as an SA sibling (working place `firmware/nebula_lite/`; the licence-by-directory rule holds). Apps opt in: RaBbLE does; Foundling would become SA if it did. The entity *art* (`scene.c`, `entity_face.c`, `nl_scene.h`) is the app's. Consequence for the Orbit: core cannot depend on it, so core's open default skin is plain LVGL and RaBbLE's skin is nebula_lite.

Stays in `apps/RaBbLE`: the entity art and scene builder, RaBbLE's Orbit skin and voice profile, Pomodoro applet, clock and levelling screens, tap-to-talk, and (for now) the sCoRE beam backend.
Goes to `apps/Foundling`: `open_entity_default` (it is Foundling's face).

## Orbit is a core UI component (Mark)

> "I don't like the foundling settings panel, the done button is hard to click and it doesn't fit on circle display. Orbit should be a UI component that apps use to draw settings. Foundling and RaBbLE have similar UX but RaBbLE has its own look and feel, but shared DNA."

- Core owns the Orbit's model (pages, items, actions), gestures, spring motion and a page registration call. Apps register their own pages (RaBbLE adds voice, beam, Pomodoro applet).
- Each app brings a **skin**: how the Orbit looks. Core ships an open default skin (plain LVGL, drawn for the round panel: dial, large targets, no small Done button). RaBbLE's skin is the nebula_lite renderer.
- The seam exists already: `nl_orbit_t` (items, sprites, label radii) is data that nebula_lite draws. The split is the model and logic (`rabble_orbit_logic.c` 2,449 lines, `rabble_orbit.c` 704) versus the draw backend. It needs a design pass and a clean-room look at the core half; it is not a file move.
- Foundling's plain settings panel (`open_entity_settings_init`) is retired once the open default skin exists. Until then it stays as the stand-in, known bad on the round panel.

## Order

1. One commit, pure move: `sdk/`→`core/`, `app/`→`apps/`, `main/` into each app, bench apps to `tools/`. Sequence with the Foundling session (it edits CMakeLists and README).
2. Split Wi-Fi from the beam code in `rabble_net`.
3. `rabble_screen` into Foundling.
4. Orbit split: plan, then build; open default skin; Foundling drops the panel.
5. Licence flip of `core/` after W8/W11 and the overlap gates.

## Open points

- Core directory name: `core/` or `common/`, decide at the move.
- Does the sCoRE beam backend live in core or in the app? (Foundling would speak through it.)
- Name of the SA renderer component (NeBuLA-lite or NeBuLA-micro) and its place.
- sCoRE coordination of entities: protocol open or SA? Not designed yet; beam client open vs SA is part of the same question (see S311 notes: the wire format is a plain WebSocket, the value is the sCoRE server).
- Drag-wake rule settled: a drag or hold is never a tap (W9 rev 4).
