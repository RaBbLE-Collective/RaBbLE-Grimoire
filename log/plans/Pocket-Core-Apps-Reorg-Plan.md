# Pocket entity layers: plan and roadmap

> Status: DRAFT v2 (S311, 2026-11-04; v1 reviewed by QuiBbLE/Opus the same day: COHERENT-WITH-EDITS, 8 edits folded in, evidence `/tmp/rabble-crew/review-reorg-plan.md` and summarised in section 10). **Nothing is implemented.** Next session: review this plan with Mark and get his confirmation of the shape (section 11) before any phase starts. Rulings are Mark's (**Mark**) unless marked otherwise. Replaces the sdk/app split inside `Pocket-Open-SDK-App-Separation-Plan.md` (that plan's licence, publishing and gitleaks work stands); `Pocket-Foundling-Open-App-Plan.md` stays the Foundling ledger.
> The filename keeps its old name so existing links hold.

## 1. Idea

The Pocket firmware is an entity OS. The living thing is the **entity** (RaBbLE, Foundling, later Familiars). An entity is built from **core**, a library of components that is just functionality and is useless without an entity, and it runs **apps**: portable code such as Pomodoro or a log display, rendered in the entity's own look.

> Mark: "The entity uses core, core is just functionality." "Entities are the living OS app that can run things for the user like actual apps such as pomo or a log display." "The core entity functions may differ based on what's living on device." "The layer and the core prefix are referring to the same concept of a living digital entity."

## 2. Layers and rules

| Layer | Is | Licence | Rule |
|---|---|---|---|
| `drivers/`, `boards/` | chip drivers, board folders (the hardware seam, W11) | open core family | board resources are exposed as capabilities, presence not assumption |
| `core/` (name: `core` or `common`, decide at the move) | component library: seam, state, settings, screen, power, Wi-Fi, audio, voice, store, motion, Orbit toolkit, generic LVGL renderer | open, in transition to Apache-2.0 | **inert until an entity calls it**: no boot, no main loop, no self-starting task, no link-time side effects; nothing RaBbLE-specific; no dependency on any entity or app |
| `entities/<Name>/` | a living entity; owns its entry point (`main.c`), startup order, tasks, look and feel, renderer, voice profile, which apps it hosts | per entity: RaBbLE SA, Foundling open | composes core by *using* it (composition, not inheritance, closed); no `main/` folder anywhere |
| `apps/<name>/` | portable app: logic + model + view data, no renderer of its own; declares what it needs (screen, mic, motion, storage) | per app | any entity may host it; the host checks needs against the device |
| `tools/` | `panel_bench`, `hw_test` (bench builds) | SA | not part of the product build |

Dependency direction: entity → core → drivers/boards; entity → app; app → core. Never core → entity, core → app, app → entity.

**Licence follows the directory**, not the name, and the open directories flip to Apache-2.0 together once the clean-room track (section 8) is done. Until then every file there carries the Sovereign Accord header plus `Open-transition: Apache-2.0 (planned flip; see ...)`. Today only `open_entity_default`, `rabble_screen` and `app/Foundling` carry that marker; everything else in the firmware is plain SA.

## 3. Target tree

```
RaBbLE-Pocket/
  firmware/
    core/            open component library
    drivers/  boards/
    entities/
      RaBbLE/        SA; own main.c; nebula_lite inside it (entities/RaBbLE/nebula_lite/);
                     rabble_orbit (its look), sCoRE beam backend, voice profile, clock/level screens, tap-to-talk
      Foundling/     open; own main.c; LVGL; foundling_* face (was open_entity_default)
    apps/            pomodoro, log_view, ... (portable)
    tools/           panel_bench, hw_test
    test/            host tests mirror the layers
  companion-app/ hardware/ ops/ sim/ planning/ third_party/   unchanged in place (sim/ and test/render/ paths fixed at the move)
```

## 4. What goes where (from the code as of S311)

| Today | Becomes |
|---|---|
| `sdk/rabble_core` (board seam, state, settings, console, time, text, device, palette, mem) | `core/` seam components |
| `sdk/rabble_lvgl_port`, `rabble_screen` (W9), `rabble_power` (battery), `rabble_audio`, `rabble_motion`, `rabble_store` | `core/` |
| `sdk/rabble_net`: Wi-Fi half (`rabble_wifi*`) | `core/` (Wi-Fi is a core service, **Mark**) |
| `sdk/rabble_net`: beam half (`rabble_beam*`, W8 target) | moves to `entities/RaBbLE` at R1 as its own component (D5) until Mark decides open client in core vs SA (section 11 Q3); `rabble_net` is split into a Wi-Fi component (core) and a beam component (entity) at R1. `rabble_capture.h` (core store) declares `rabble_beam_capture_text`, which the beam implements: that becomes a backend hook at R2 |
| `sdk/rabble_voice` (push-to-talk loop, endpointing, outbox) | **target `core/`** (**Mark**: any entity can speak; each entity has its own voice profile and config), **but today it includes `rabble_beam.h` and makes about 30 beam calls** (`rabble_voice.c:16`), so it moves to `entities/RaBbLE` at R1 beside the beam and comes back to core at R5, once the backend interface exists |
| `sdk/rabble_render` (nebula_lite: store, rasteriser, composer, SIMD, `src/orbit.c`) | `entities/RaBbLE/nebula_lite/` (**Mark**: SA, ships inside RaBbLE) |
| `app/RaBbLE/rabble_orbit_logic.c` (2,449 lines, pure C brains, outputs `orbit_view_t` + `orbit_ctl_t`) + the spring stepping in `rabble_orbit.c` | `core/` Orbit toolkit (shared DNA) |
| `app/RaBbLE/rabble_orbit.c` sprite rasteriser + `nl_orbit_t` + nebula `src/orbit.c` | `entities/RaBbLE/` as `rabble_orbit` (RaBbLE's look; welded to the entity's mesh orbs and colour ring) |
| `app/RaBbLE/rabble_input.c` | **three modules in one file**: button and push-to-talk (entity), the power ladder and idle timer (board-level policy, `:327`, `:422`, `:443`; with swaps it cannot belong to one entity), and the serial console commands (`run_line`, `command_*`). Split decided at R0; pomo calls `rabble_input_wake` and the voice chirp (`rabble_pomo.c:94,98`), so apps need a small host interface for them |
| `app/RaBbLE/rabble_pomo.c` + Pomodoro Orbit page | `apps/pomodoro` (logic + view data) + each entity's rendering |
| `app/RaBbLE/entity_face.c`, `scene.c`, `nl_scene.h`, `rabble_entity.c`, clock, level, tap-talk, a8, shot, setup | `entities/RaBbLE/` (`entity_face*` becomes `rabble_face*`) |
| `sdk/open_entity_default`, `app/Foundling` | `app/Foundling` to `entities/Foundling/`. **`open_entity_default` stays in core until R4**: RaBbLE requires it today (`app/RaBbLE/CMakeLists.txt:9`, used in `rabble_ui.c` under `CONFIG_OPEN_ENTITY_DEFAULT`) as its fallback face, and a build only sees the chosen entity's folder. It moves into Foundling (as `foundling_*`) only if Mark drops RaBbLE's fallback face or after a shared open face exists (section 11 Q4) |
| `main/` (not just `app_main.c`: it also holds the board choice and `RABBLE_SHOT` in `Kconfig.projbuild`, the `bsp_perf.h` include at `app_main.c:10,25`, and the boot task's core pinning), `panel_bench`, `hw_test` | each entity's `main.c` plus its Kconfig and board-choice; benches to `tools/`. Where the board choice lives (project level, not per entity) is decided at R0 |

## 5. Orbit as an object (Mark)

> "Orbit should be a UI component that apps use to draw settings. Foundling and RaBbLE have similar UX but RaBbLE has its own look and feel, but shared DNA." "Make orbit a structure or object that is used or built in an app. Apps could build and render the orbits themselves. RaBbLE uses nebula_lite and builds custom orbits; familiars or foundlings have their own orbits." "Core should have an orbit.c ... rabble_orbit is RaBbLE's and orbit is open."

- An Orbit is an **instance**, not a singleton: built from data the entity owns (item table, page table, action callbacks, panel geometry; 466 px round is hard-coded today and becomes a parameter). It outputs the same view and controls data it already produces.
- The **entity renders**: core ships a plain-LVGL Orbit renderer (the open default; Foundlings use it; large touch targets, built for the round panel, no small Done button); RaBbLE renders with nebula_lite (faster, more optimised, possibly less stable). The LVGL renderer can double as RaBbLE's fallback if nebula_lite fails to start or RAM is short (not decided).
- Core may ship optional page builders (Wi-Fi, display, sound) so a new entity gets a settings Orbit in a few lines; entities add pages and can build several Orbits (Settings and Applets are two sides of one Orbit today).
- Foundling's plain settings panel (hard to hit Done, does not fit the circle) is retired when the open default renderer exists.
- File map (checked S311): `rabble_orbit_logic.c` 2,449 + `rabble_orbit.c` 704 + `rabble_render/src/orbit.c` 399 + `nl_orbit_t` in `nebula_lite.h`. The logic and the spring stepping are generic; the rest is nebula-specific.
- Do it in place first: the logic is RaBbLE's own code (W5 Part B), so no clean room. **Facts (QuiBbLE, verified):** `orbit_logic` is already an instance (`orbit_logic_t`, `L->` throughout, `rabble_orbit_logic.h:129,226`); the singleton is `s_L` in `rabble_orbit.c:76`, in PSRAM. The logic is **not pure**: it includes and calls beam, input, pomo, ui and settings (`rabble_orbit_logic.c:10-17`), and its tables hold RaBbLE content (voice names, sCoRE page). So the real R3 is: hand the item/page tables and an ops table (host callbacks for pomo, ui, input, beam, voice) in at init so content and side effects come from the entity, then make `s_L` an instance the entity owns. The Pomodoro page therefore has to come from the host, so part of the app interface (a page provider) is designed in R3, ahead of R6. Measure one instance's internal RAM (about 14 KB free at boot) before any entity builds two.

## 6. The slot and entity swaps (Mark)

> "The slot is useful to have entity transplants or for entity swaps to have two creatures on one board."

The **slot** is the seat an entity occupies on a board (name open; Mark: "we can rename the slot"): the hooks core calls into the entity (mood, level, tick, voice profile, Orbit pages). Consequences to design before it is built:

1. Per-entity state (settings, voice profile, Orbit pages, mood) is instance data keyed by the entity, never file-scope statics.
2. Board resources (screen, mic, speaker, Wi-Fi, battery) are shared services and need arbitration if two entities are live: who owns the screen and the mic, who hears the wake.
3. Device settings (Wi-Fi, brightness, sleep) belong to the board; entity settings (voice, look, Orbit pages) travel with the entity: the transplant format (`.rbl`/`.rble`, `Pocket-Release-Entities-Companion-Plan.md`, `RaBbLE-Pocket-Entity-Format.md`) will need that split.
4. Swap one entity at a time first; two live creatures is a later step.

## 7. Names

> "The core should have an orbit.c, I am tempted to remove rabble names from core and leave components more generic." "Entity could replace rabble in core."

- Core drops `rabble_` and takes the prefix **`entity_`** (`entity_state`, `entity_settings`, `entity_board`, `entity_screen`, `entity_wifi`, `entity_orbit`, ...). RaBbLE-owned code keeps `rabble_`. This **supersedes Mark's 2026-11-02 ruling** that `rabble_` identifiers may stay in the SDK.
- Collisions found: `entity_face*` (nebula face parts in the RaBbLE app) becomes `rabble_face*`; `open_entity_*` becomes `foundling_*`; `rabble_entity*` stays RaBbLE's. "Entity" is the layer and the prefix (one concept, **Mark**); the slot is a separate noun.
- The old meaning of "app" in the code is renamed: `RABBLE_APP` to `RABBLE_ENTITY`, `rabble_app_run` to an entity-run name, `rabble_app.c/.h`, folder `app/` to `entities/`. The word "app" now means layer 3.
- Persisted strings (NVS namespaces and keys, store names) are renamed with the code and settings reset from that point (**Mark**, no migration). A device that takes the rename loses Wi-Fi credentials, beam token and settings and is set up again through the console; back up NVS before flashing.
- Kconfig `CONFIG_RABBLE_*` (about 13 symbols) rename with their code; stale `sdkconfig` regenerates.
- Frozen clean-room specs name the old symbols: leave them as history and record a **name map** in PROVENANCE.
- The seam component's new name (today `rabble_core`) is open (`entity` or `entity_seam`).

## 8. Where the clean room sits (S311)

Process, workspaces and rules: `RaBbLE-Pocket/RaBbLE-Pocket-Clean-Room-Plan.md`, `RaBbLE-Pocket/cleanroom/PROVENANCE.md`. Reference SDK for the overlap gate: `~/RaBbLE-Cleanroom/muse-ref` at `b139b45` (re-cloned S311, outside every repo). Overlap script is retired; recover with `git show 984c554^:ops/cleanroom-overlap.py` (needs `--sdk ~/RaBbLE-Cleanroom/muse-ref/esp32`).

| Wave | Target | State |
|---|---|---|
| W0-W7 | seam, leaf modules, power/input, settings, audio/voice, Orbit, board, header sweep | **done**, merged, provenance rows in PROVENANCE |
| **W9** | `rabble_screen` (screen sleep, brightness, black cover, double-tap wake) | **done S311, not flashed**. Spec rev 4 (a drag or hold is never a tap; five Kconfig knobs). Firewall (QuiBbLE, 13 edits applied), one implementer + one rework, overlap 2.8% (gate 5%), transcript audit clean, host tests 106-120 checks pass, RaBbLE app builds, full suite 33 pass + 1 known XFAIL. Pocket `9b95e30`, `6abe8c9`; Grimoire `cd3f27d`, `d68b8a3`. Device checklist (spec section 8) not run |
| **W8** | `rabble_beam_score.c` session layer (flagged 15.4% by the 2026-11-02 audit) | spec revised after the first firewall review; **firewall re-review done 2026-11-05 (QuiBbLE/Opus): SEND BACK**, 12 required edits (caption formula mirrors the original and Meta; taint path to `rabble_beam.c`; wrong Meta-string flag; spec gaps). Report `/tmp/rabble-crew/w8-firewall-review.md`. Reviewer prefers running W8 before R1. Then edit spec, one changed-passages re-review, implementer |
| **W11** | `rabble_board.h` rewrite (the one file with Meta's notice, interim Apache + Meta header) | spec exists (supersedes W10); **firewall review done 2026-11-05 (QuiBbLE/Opus): SEND BACK**: declaration order is the old order reversed (use alphabetical), section 7 is a ready-made header with paraphrased comments, caller list predates W9/Foundling, w10 gaps carried. Report `/tmp/rabble-crew/w11-firewall-review.md`. Suggested simpler path: implementer writes only the header, stubs and helper rename; integrator does section 8 renames |
| W10 | hardware-groups seam | **superseded by W11**; spec draft 2 got QuiBbLE REVISE; its six questions were in HANDOFF-S304 and presumed settled by W11 (not confirmed) |
| derived set | files with Meta ancestry that stay Apache-with-attribution | not yet decided by overlap; part of Track L in the Open SDK plan |

Uncommitted in the Grimoire: `w8`, `w10`, `w11` specs (untracked), `w0-state`, `w2-input`, `w3-settings` spec edits (modified), the Provenance Record and Split Manifest (held out of the public Grimoire until Mark rules where they live), `audit-2026-11-02/`. Held on purpose; do not `git add -A`.

Open-core cleanliness: **the open core is not clean until W11 and W8 land** (`rabble_board.h` carries Meta's notice; `rabble_beam_score.c` is flagged). The licence flip waits on them.

## 9. Roadmap (v2)

Each phase is sized for one Opus session and ends with: host suite and builds green, a commit tagged with the session, and a short handoff. **Gate G0 first: nothing below starts until Mark confirms the shape in the review session (section 11).**

| Phase | Work | Gate / check |
|---|---|---|
| R0 | **Review and confirm** this plan with Mark (section 11); fix what he changes | Mark signs off the shape |
| R1 | **Move only code that already respects the layers.** `sdk/`→`core/` for seam, lvgl_port, screen, power, audio, motion, store, the Wi-Fi component and `open_entity_default` (stays in core until R4). `rabble_render` (nebula_lite), the beam component and `rabble_voice` move to `entities/RaBbLE/` as separate components; `rabble_net` is split into Wi-Fi (core) and beam (entity). `app/`→`entities/`, `main/` folded into the entities (board choice, `RABBLE_SHOT`, `bsp_perf.h`, core pinning placed per R0), benches to `tools/`, the old meaning of "app" renamed. **Port `ops/sdk-layers.py`** (it hard-codes `sdk/`, `app/`, `main/`, cannot resolve `${RABBLE_APP}`/`${RABBLE_BOARD_DIR}`, so it never scanned `app/` or `boards/`, and has no entry for `rabble_screen` or `open_entity_default`). **Fix every hard-wired path:** `test/paths.sh:18-37`, `test/*/input_test/compile_check.sh:12,24`, `panel_bench/main/CMakeLists.txt:2`, `sim/build.sh:9-10`, `sim/transition.sh:8-9`, `test/render/`. No behaviour changes | both entities build (`RABBLE_ENTITY` RaBbLE and Foundling), full host suite, every moved file `git mv`'d; image size delta explained (folding nebula_lite into the entity's whole-archive build can change it, so the old "within 100 B" gate is replaced by "symbol set identical, size delta accounted for"); Foundling session idle first |
| R2 | **Core hygiene, lint enforced.** Core components inert until called; no core→entity dependency; `rabble_capture.h`'s beam declaration becomes a backend hook; move beam URL, token and `RABBLE_BEAM_DEFAULT_URL` out of core settings and Kconfig (they are RaBbLE content, `rabble_settings.c:28-30,186`, `rabble_core/Kconfig:19`); `rabble_lvgl_port` works by link-time side effects: exempt it or move it into `boards/` (section 11 Q6); add the Open-transition header to files entering core; fix `firmware/NOTICE:4-6` (false today) | the ported lint fails on any core→entity or core→app edge and passes; no RaBbLE-specific string in core tables |
| R3 | **Orbit as an object, in place, plus the Pomodoro page hook.** Tables and an ops table passed at init, `s_L` becomes an entity-owned instance; the pomo page comes from the host (the first slice of the app interface); `entity_face` renamed `rabble_face` here (RaBbLE-internal); measure instance RAM | host tests identical before/after; internal RAM within 100 B at boot |
| R4 | **Core Orbit toolkit + open LVGL renderer**; Foundling builds its own Orbit and drops the settings panel; `rabble_screen` into Foundling; `open_entity_default` moves into Foundling if Mark decided so | device check by Mark on the round panel (hit targets, fit) |
| R5 | **Voice back into core** with a backend interface and a per-entity voice profile; the beam plugs in as RaBbLE's backend | one voice turn through the beam on device, behaviour unchanged |
| R6 | **Apps layer**: finish the app interface (model, view data, needs, hosting), extract Pomodoro; apps get a host interface for input wake and the voice chirp | Pomodoro the same in RaBbLE; renders in a Foundling |
| R7 | **Clean-room track**: fresh firewall reviews of W11 and W8 (the lost ones), implementers, overlap gates, the derived set | each wave's gate in PROVENANCE; `rabble_board.h` and `rabble_beam_score.c` clean |
| R8 | **Mechanical `entity_` rename** of core, own commit, `ENTITY_*` and `CONFIG_OPEN_ENTITY_*` collisions handled, settings reset, name map in PROVENANCE | suite and builds before and after; stale `sdkconfig` regenerates; device re-setup through the console |
| R9 | **Licence flip** to Apache-2.0 and publish. **Gate: R7 and R8 done, the lint enforced, the settings split done, core tables RaBbLE-free, NOTICE true**, gitleaks `--all` including tags, signing key, Mark approves the manifest | Mark's approval |
| R10 | **Slot and swaps**: design the slot (instance state, shared-service arbitration, device vs entity settings), one-entity-at-a-time swap and the transplant format; two live creatures later | design review before code |

Order notes: R7 and R8 could swap if W8/W11 implementers should write new files straight under `entity_` names; the cost is that clean-room specs freeze the old interface names. Default keeps W8/W11 on current names, then renames once. R3 precedes R4 and R5 because voice, apps and the core Orbit all need the entity-owned instance and host hooks.

## 10. Risks and known tensions

- **R1 Open core is not yet clean** (section 8): `rabble_board.h` Meta notice, `rabble_beam_score.c`, and the "derived set" decision. The directory licence rule is only true after R7.
- **R2 Voice depends on the beam today** (about 30 calls): resolved in v2 by keeping voice and beam together in `entities/RaBbLE` from R1 until R5.
- **R3 `rabble_input.c` is three modules** (button/push-to-talk, the power ladder, serial console commands). The power ladder and idle timer are board-level policy: with swaps or two creatures they cannot belong to one entity. Where each lives is decided at R0.
- **R4 Orbit settings mix scopes**: `rabble_settings` holds device, entity and RaBbLE-only values (voice, beam URL) in one store; the device/entity split in section 6 needs a settings design before the rename and the transplant format.
- **R5 Internal RAM** (about 14 KB free): per-entity instances and an LVGL Orbit renderer both cost internal RAM; measure at R3 and R4.
- **R6 nebula_lite stability**: faster but possibly less stable; no fallback is decided.
- **R7 Rename blast radius**: about 300 distinct `rabble_` symbols, 36-40 files each for the main ones; hence its own commit with a before/after suite.
- **R8 Entity word load**: layer, prefix and concept are one idea by decision; keep the slot as a separate noun in docs.
- **R10 Reviewer findings (QuiBbLE, S311)**: v1 R1 would have broken the RaBbLE build (it requires `open_entity_default`), v1 R2's lint gate could not pass before voice returns (voice includes the beam), v1 R3 was scoped from wrong facts (the logic is already an instance; the singleton is in `rabble_orbit.c`), `rabble_input` is three modules, the lint needs porting not extending, the licence-flip gate was too thin, `main/` holds more than `app_main.c`, and the collision and path lists were incomplete. All folded into v2.
- **R11 The Apache flip changes the clean-room goal**: the Clean-Room plan line 106 states a "no Apache files" goal; flipping core to Apache reverses it. Intended? (section 11 Q7)
- **R9 Concurrent sessions**: the Foundling session and others touch `CMakeLists.txt`, `README.md` and Pocket files; R1 needs an idle tree and `bash spells/mine.sh`.

## 11. Review checklist for the confirmation session

Mark and the reviewing Opus session go through these and record the answers here:

1. Layers and dependency rules (section 2): correct and complete? Is `apps/` right for layer 3 and `entities/` for layer 2?
2. Folder name: `core/` or `common/`.
3. **Beam**: open client in core (a voice backend any entity can use against a `rabble-beam/0` server) or SA in `entities/RaBbLE`? W8 is the clean-room target either way.
4. **Does RaBbLE keep the open fallback face** (`open_entity_default`, `CONFIG_OPEN_ENTITY_DEFAULT`)? Yes: it stays in core until a shared open face exists. No: it moves into Foundling at R4.
5. Voice stays with the beam in `entities/RaBbLE` from R1 until R5 (v2 default): agreed, given it departs from "voice is core" for that stretch?
6. `rabble_input` is three modules (button/push-to-talk, power ladder and idle timer, serial console): where does each live (the power ladder as a board-owned core service?) and where does the board choice (`main/Kconfig.projbuild`) live?
7. `rabble_lvgl_port` works by link-time side effects, which the inert-core rule forbids: exempt it, or move it into `boards/`?
8. The Apache flip reverses the Clean-Room plan's "no Apache files" goal (line 106): intended?
9. Seam component name; slot name.
10. Rename order (R7 before R8, or new files born as `entity_`); settings scope design (device vs entity vs RaBbLE-only) before R8; build the LVGL fallback for nebula_lite or not.
11. Anything Mark wants cut, deferred or reordered; confirm the phase gates.
12. Hold-outs (Provenance Record, Split Manifest, audit, W8/W10/W11 specs): where do they live?

Cold start for that session: `log/handoffs/HANDOFF-S311-Pocket-Entity-Layers-Review.md`.

## 12. Rulings ledger (Mark, 2026-11-04)

Drag is never a tap (double-tap wake needs two clean taps) · `rabble_screen` its own component, not in `rabble_power` · header is SA + Open-transition marker, not Apache yet · open_entity into Foundling · benches to `apps`/`tests` (now `tools/`) · core, entities, apps layers · no `main/`, entities own entry points · licence follows the directory · Wi-Fi is core · voice is core with per-entity profile · renderer is SA, nebula_lite inside RaBbLE, LVGL renderer in core · Orbit is an instance apps build and render · core drops `rabble_`, prefix `entity_` · persisted strings may be renamed, settings reset · core is inert components, entity uses core (composition) · the slot is kept for swaps and two creatures.

## 13. Review answers (R0 walkthrough, Mark, 2026-11-05)

1. **Layers confirmed as written.** Mark: "core is the base components that power an entity, entities serve apps, entities utilize core, entities are the OS layer, core is the kernel." Use the kernel/OS analogy in docs; the dependency rules stand.
2. **Folder name: `core/`.**
3. **Beam: SA in `entities/RaBbLE` for now.** Core defines a voice-backend interface (R5); the beam plugs in as RaBbLE's backend. Opening it later needs no other move.
4. **Corrected by Mark after the walkthrough:** the fallback is about *rendering*, not about a different face. RaBbLE must never show another entity's face; if nebula_lite fails or RAM is short, it may fall back to **LVGL drawing RaBbLE's own face**. So `open_entity_default` is not RaBbLE's fallback face. It stays in core only as a temporary build dependency (`app/RaBbLE/CMakeLists.txt:9`, `CONFIG_OPEN_ENTITY_DEFAULT` in `rabble_ui.c`) until RaBbLE has its own LVGL render path (R4, tied to the undecided nebula_lite fallback in 10); then the dependency is removed and `open_entity_default` moves into Foundling. R1/R2 stay a pure move with it in core.
5. **Voice stays with the beam in `entities/RaBbLE` from R1 to R5**, then returns to core behind the backend interface. Agreed.
6. **`rabble_input` goes to core as mechanisms** (Mark: "all the functions can be refactored to Core with the entities using these to drive their specific input paths"). Button/push-to-talk detection, the power ladder and idle timer, and the console command machinery become core services; each entity binds its own commands and input actions to them. Consequence: the ladder is board-level by construction, so swaps work. Board choice location (`main/Kconfig.projbuild`) was not answered: default project level, not per entity (decide at R1).
7. **`rabble_lvgl_port` becomes a driver behind a seam.** Mark: LVGL is not board-specific but not a core function either, so a seam or bridge is needed. Design at R2: LVGL lives under `drivers/` as a graphics driver; core talks to it only through a small display/UI seam (`entity_screen` and friends), so an entity may use LVGL, nebula_lite or both. Link-time side effects stay in the driver, not core. Needs one short design note before R2.
8. **Apache flip intended; the clean room's purpose is stated.** Mark: the clean room exists to remove Meta's code and make the firmware his own, not to avoid Apache. He wants a clean slate under Apache so contributors can help without friction. Action: reword the Clean-Room plan line 106 ("no Apache files") to "no Meta-derived files". Licence version: Mark wrote "Apache 1.0"; Apache-2.0 is the only current version and the plan's stated target, so recorded as **Apache-2.0** (confirmed by Mark, 2026-11-05: he meant 2.0).
9. **Slot name kept (`slot`).** Seam name **not decided**: Mark does not recall what the seam does and says "this whole mechanism may need more definition". Explanation given in the session: the seam is `rabble_core`'s `rabble_board_t` (`rabble_board.h`), a table of function pointers (display, touch, audio codec, power, IMU, RTC, Wi-Fi hooks) that a board fills in so everything above it reaches hardware only through that table; optional members are NULL. It is the W11 rewrite target. Open: write a short definition note for the seam and the slot (what each owns, who calls whom) before R8 picks names. Until then the component keeps its name.
10. **Default order confirmed.** R7 (clean room on current names) before R8 (mechanical `entity_` rename); the device/entity/RaBbLE-only settings design comes before R8; the LVGL render fallback for nebula_lite (same RaBbLE face, different renderer; never another face) stays undecided until R4 measures RAM.
11. **Roadmap R1-R10 stands**, R1 (pure move) first. Two design notes are added before R2: (a) seam and slot definition, (b) LVGL driver seam (Q7).
12. **Hold-outs go in the public Grimoire** (Provenance Record, Split Manifest, `audit-2026-11-02/`, w8/w10/w11 specs). Not yet committed: needs a gitleaks scan of the audit directory first, and the earlier QuiBbLE finding (P-1: unpushed local commits in the public Grimoire) still applies to pushing.

**Ruling (Mark, 2026-11-05): no lawyer review.** Mark considers the project too small for it and judges his own due diligence (clean room, provenance record, overlap gates, attribution notices) sufficient; the Grimoire holds little problematic. Consequence: "lawyer review" items in the Open SDK plans (NOTICE wording, PROVENANCE, header-compaction history, trademark/extension names) are closed as *not planned*; the R9 gate rests on the clean-room gates, gitleaks and Mark's approval alone.

**Seam clarified (Mark asked whether it is a driver/board association; yes).** The "seam" is `rabble_board_t` (`rabble_board.h`): the board contract, one table a board fills in (geometry, buttons, display start/lock/brightness/sleep/direct band drawing, audio codec, power read/off, RTC, IMU). It belongs to the **drivers/boards side of the hardware line, not to core logic**; it sits in `rabble_core` today only for convenience. Proposed home: a `boards/` contract component (`board.h`) that core and entities read through, with each board folder implementing it. Wrinkle for the Q7 design note: the table includes `lvgl.h` and returns `lv_display_t`/`lv_indev_t`, so LVGL leaks into the board contract; the LVGL driver seam and the board contract must be designed together (display capability group with LVGL as one implementation, direct band drawing as another). Name stays open; W11 is the rewrite of this contract.

**Marks' other rulings (2026-11-05):** Foundling will not be trademarked (no clearance work, "Foundling" stays a lore name). The RABBLE class 9 filing he cannot find; judged adjacent, not pursued.

**Rulings (Mark, 2026-11-05, later):** W8 runs before R1; every UI string that coincides with Meta's wording is reworded (so `rabble_beam.c`, W3/W4/W1 specs and tests must be updated to the new strings by the integrator before W8's implementer runs); W11 uses the simpler path (implementer writes header, stubs, helper rename; integrator does the mechanical renames); the panel/touch split from `Pocket-Seam-Slot-LVGL-Design-Note.md` is adopted and LVGL types leave the board contract (generic enum for the button icon hint). `screen.start` wrong-core behaviour loosened to "logs; may return NULL" (default chosen by the lead, Mark did not answer; change if wrong).

