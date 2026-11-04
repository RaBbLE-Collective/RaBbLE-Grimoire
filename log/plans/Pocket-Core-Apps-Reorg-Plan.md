# Pocket core / apps reorganisation (decisions, 2026-11-04, S311)

> Status: DECISIONS RECORDED, nothing moved yet. Mark's rulings in his words where marked **Mark**. Open points at the end. Related: `Pocket-Foundling-Open-App-Plan.md`, `Pocket-Open-SDK-App-Separation-Plan.md`.

## Shape: three layers (Mark, 2026-11-04)

> "Apps can be split, so pomodoro can be put into any entity and rendered with the proper look/feel. Apps, entities and things are layers. Entities are the living OS app that can run things for the user like actual apps such as pomo or a log display, etc. The core entity functions may differ based on what's living on device."

1. **core** (the base OS, open): seam, Wi-Fi, audio, voice, store, power, screen, motion, the Orbit toolkit, the entity slot.
2. **entities** (the living app): RaBbLE, Foundling, later Familiars. An entity owns its entry point, its look and feel, its renderer, its voice profile, and *hosts* things. Which core functions an entity uses depends on what is on the device (board capabilities, W11: presence, not assumption).
3. **things** (user-facing apps, working name; Mark may call them apps): Pomodoro, a log display, and so on. A thing is logic plus a model plus view data, with no renderer of its own. Any entity can host it and draws it in its own look: RaBbLE through nebula_lite, a Foundling through LVGL. Same seam as the Orbit (data out, entity renders). A thing declares what it needs (screen, mic, motion, storage) and the host checks it against the device.

Worked example: today `rabble_pomo.c` and the Pomodoro Orbit page are RaBbLE's. As a thing, the timer and its rounds are the thing; the Orbit page and the clock-with-dots look are each entity's rendering of the thing's view data.

```
firmware/
  core/        shared base, open, in transition to Apache-2.0 (Mark: "core or common for now"; "OS" rejected: RaBbLE-OS is the distro)
  nebula_lite/ SA renderer component (name and place open)
  drivers/     chip drivers
  boards/      board folders
  entities/
    RaBbLE/      Sovereign Accord; owns its entry point, look and feel, sCoRE beam backend, voice profile
    Foundling/   open; owns its entry point; LVGL
  things/      pomodoro, log display, ... (working name; licence per thing)
  tools/       panel_bench, hw_test (or tests/)
```

- **Licence follows the directory** (Mark): `core/`, `drivers/`, `boards/`, `entities/Foundling` carry SA + the `Open-transition: Apache-2.0` marker now and flip together. `entities/RaBbLE` stays SA; each thing carries its own. No second "Foundling core": core holds nothing RaBbLE-specific, Foundling-only code lives in `apps/Foundling`.
- **No `main/` folder** (Mark): each entity holds its entry point (`main.c` or equivalent) and its own CMakeLists; `RABBLE_APP` selects the entity (and may later list the things it hosts).
- `rabble_` prefixes stay (Mark, 2026-11-02). Names do not decide openness; the directory does.
- Today everything is SA; only `open_entity_default`, `rabble_screen` and `app/Foundling` carry the marker. `rabble_board.h` is the one file with Meta's notice (W11 replaces it); until then the open core is not clean.

## core/ contents

Seam (`rabble_core`: board, state, settings, console, time, text, device, palette), `rabble_lvgl_port`, `rabble_screen` (W9), `rabble_power`, Wi-Fi (**Mark: Wi-Fi is a core service**; split from `rabble_net`), `rabble_audio`, `rabble_motion`, `rabble_store`, an entity slot (mood, level, tick interface that apps fill), and the Orbit component below.

Also core (Mark, 2026-11-04): **voice**, because any entity should be able to speak. Core owns the push-to-talk loop, endpointing, outbox and a voice-backend interface; each entity brings its own voice profile and config for how it talks (RaBbLE has a custom one). The sCoRE beam is one backend; whether that backend lives in core or in the app is open (W8 put it app-side, D5).

`rabble_render` IS nebula_lite: the display-list store, band rasteriser, composer, SIMD kernels and the Orbit's drawing (`src/orbit.c`). **Mark, 2026-11-04: the renderer is its own NeBuLA-lite (or NeBuLA-micro) component and is SA licensed**, so it is NOT in the open `core/`. It sits beside core as an SA sibling (working place `firmware/nebula_lite/`; the licence-by-directory rule holds). Apps opt in: RaBbLE does; Foundling would become SA if it did. The entity *art* (`scene.c`, `entity_face.c`, `nl_scene.h`) is the app's. Consequence for the Orbit: core cannot depend on it, so core's open default skin is plain LVGL and RaBbLE's skin is nebula_lite.

Stays in `apps/RaBbLE`: the entity art and scene builder, RaBbLE's Orbit skin and voice profile, Pomodoro applet, clock and levelling screens, tap-to-talk, and (for now) the sCoRE beam backend.
Goes to `apps/Foundling`: `open_entity_default` (it is Foundling's face).

## Orbit is an object apps build and render (Mark)

> "I don't like the foundling settings panel, the done button is hard to click and it doesn't fit on circle display. Orbit should be a UI component that apps use to draw settings. Foundling and RaBbLE have similar UX but RaBbLE has its own look and feel, but shared DNA."
> 2026-11-04: "Can we make orbit a structure or object that is used or built in an app. Apps could build and render the orbits themselves. RaBbLE uses nebula_lite and builds custom orbits, familiars or foundlings have their own orbits."

- **Orbit = an instance, not a singleton.** Core ships the Orbit toolkit: the controller (gestures, springs, value and text entry, page stack) as an `orbit_t` an app creates from data it owns: the item table, the page table, the action callbacks, the panel geometry (today hard-coded 466 px round). It outputs the view and controls structs it already produces (pure data).
- **The app renders.** Core ships an open default renderer (plain LVGL, round-panel friendly, large targets). RaBbLE renders with nebula_lite. A Foundling or Familiar app may write its own. The seam is the existing `orbit_view_t` / `orbit_ctl_t`; nebula_lite's `nl_orbit_t` is one consumer.
- **Renderers by app (Mark, 2026-11-04):** Foundlings render with LVGL (the open default renderer in core). RaBbLE renders with nebula_lite: much faster and more optimised, but possibly less stable. Because both consume the same view/controls data, the LVGL renderer can double as RaBbLE's safe fallback (for example if nebula_lite fails to start or RAM is short); whether to build that fallback is open.
- **Standard page builders are optional helpers** in core (Wi-Fi, display, sound), so a new app gets a settings Orbit in a few lines and adds its own pages. RaBbLE builds its own (sCoRE, Voice, Pomodoro, Level) and may build several (Settings and Applets are already two sides of one Orbit).
- **Do it in place first.** The logic is RaBbLE's own code (W5 Part B), so no clean room is needed. Step one is an in-place refactor inside `apps/RaBbLE`: file-scope tables and state (`PG_*`, the item table, statics) become an `orbit_t` plus const tables passed at init, with the host tests green before and after. Only then lift the toolkit into `core/`. Watch internal RAM (about 14 KB free at boot): an instance's state size must be measured.
- Foundling's plain settings panel (`open_entity_settings_init`) is retired when the open default renderer lands.

## Order

1. One commit, pure move: `sdk/`→`core/`, `app/`→`entities/`, `main/` into each app, bench apps to `tools/`. Sequence with the Foundling session (it edits CMakeLists and README).
2. Split Wi-Fi from the beam code in `rabble_net`.
3. `rabble_screen` into Foundling.
4. Orbit as an object: in-place refactor in the RaBbLE app (tables and state into an instance), then lift the toolkit into core, open default renderer, Foundling builds its own Orbit and drops the panel.
5. Licence flip of `core/` after W8/W11 and the overlap gates.

## Open points

- Core directory name: `core/` or `common/`, decide at the move.
- Does the sCoRE beam backend live in core or in the app? (Foundling would speak through it.)
- Names: `entities/` and `things/` (or `apps/`) for layers two and three.
- The thing interface (model, view data, needs, how an entity hosts and draws it): its own plan, after the Orbit object exists, since things draw through the same seam.
- Name of the SA renderer component (NeBuLA-lite or NeBuLA-micro) and its place.
- sCoRE coordination of entities: protocol open or SA? Not designed yet; beam client open vs SA is part of the same question (see S311 notes: the wire format is a plain WebSocket, the value is the sCoRE server).
- Drag-wake rule settled: a drag or hold is never a tap (W9 rev 4).
