# W5 spec: the Orbit (Settings, redesigned for the round screen)

> Clean-room spec, wave W5, the plan's one planned **redesign** (Clean-Room-Plan "W5 UI"). Author: S266 parent session (Opus 5.5), from Mark's design calls of 2026-10-22, the public RaBbLE code in `accord/` and `nebula_lite/`, and the W3 settings and Wi-Fi specs. Revision 2 folds in an independent Opus review (S266; it read only `accord/`, `nebula_lite/`, `sim/`, `test/`, `ops/` and Grimoire). Neither author nor reviewer read `apache/rabble_settings_ui.*` or `apache/rabble_keypad.*` beyond their public header comments, and nothing here comes from them, so no firewall pass is needed. Files replaced: `apache/rabble_settings_ui.c/.h`, `apache/rabble_keypad.c/.h` (deleted, not ported). New files carry the header `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else.
>
> Two parts, two implementers, in parallel: **Part A** (renderer, `nebula_lite/`, `sim/`) and **Part B** (controller and integration, `accord/`, `firmware/test/cleanroom/w5/`). Section 3 is the contract between them; both build against it exactly. Neither may read `apache/`, `bsp/`, the SDK, or any include path into them (the W2 test's `-I` to `apache/` is a pattern not to copy).

Treatment: clean room + redesign. Everything is a requirement unless marked *suggestion* or *tunable*. Numbers are behaviour values.

---

## 1. What Mark asked for

- Settings becomes the **Orbit**: a dial. Items sit on a ring by the rim like small portals; dragging a thumb **along the rim** turns the dial; the item at the top is the chosen one and the centre shows its name and value; **tapping the centre opens** it. Values are **arcs** dragged around the rim.
- **Every** settings page is an orbit: categories, values, choices, the Wi-Fi network list, text entry. No LVGL anywhere in Settings. The Level screen (`rabble_level_screen.c`) stays as it is and is opened from the Orbit.
- Toggles and actions are **intentional: hold to fill**; letting go early cancels.
- Getting there from the face takes **resistance, then a snap**. Touching and dragging the entity (lean, pet) must never slide Settings in by accident.
- Drawn **natively by NeBuLA-lite**, not as an LVGL texture. Frame-rate targets: **≥ 40 fps while sliding and while dragging**, never under 30, exactly repeating frames at rest (60 fps idle, no bands redrawn).
- The colour ring (already drawn in every view) stays on top; Orbit content keeps inside radius 205 px.
- The sCoRE URL and token are set over USB only; the device shows sCoRE's status and offers Test and Reset-URL.
- Palette: `RaBbLE-Palette.md` hexes only (`rabble_palette.h` / `nl_internal.h`).
- Only with a touch panel and the entity renderer (`rabble_board->touch`, `rabble_entity_init()` true); without them there is no Settings UI (serial setup only).

## 2. Coordinates and terms

- Panel 466 × 466, centre (233, 233). **Orbit frame**: the panel turned by the orbit's roll about the centre; x right, y down; angles in radians **clockwise from 12 o'clock**.
- **Rim zone**: distance ≥ 150 px from the centre. **Centre zone**: < 110 px. Between: dead for starting gestures (a running gesture continues there).
- **Item ring radius** 178 px. **Item pitch** = 2π / max(n, 8). With n ≥ 8 the dial wraps; with n < 8 it clamps at the ends with rubber-banding (overshoot at 30%, springs back).
- **Value arc**: radius 178, width 10, span −2π/3 (8 o'clock) to +2π/3 (4 o'clock), open at the bottom.
- **Chosen slot**: the top (angle 0).

## 3. Contract between Part A and Part B (`nebula_lite.h`, frozen)

```c
#define NL_GLASS_SPRITES 16              /* the face's glass: nl_inputs_t.sprites, rabble_entity.c sprite sets */
#define NL_ORBIT_ITEMS 40
#define NL_ORBIT_SPRITES 48
#define NL_MAX_SPRITES (NL_GLASS_SPRITES + NL_ORBIT_SPRITES)   /* nl_spr: glass first, then orbit */

typedef struct {
    float ang;            /* radians, clockwise from 12 o'clock, before dial and fan */
    float r;              /* px from the centre */
    int8_t sprite;        /* index into nl_orbit_t.sprites drawn centred on the item; -1: none */
    float disc_r;         /* px: filled disc behind it (0: none) */
    uint32_t rgb;         /* disc colour */
    uint8_t opa;          /* 0..255: disc, ring and sprite */
    uint8_t ring;         /* 1: stroked ring (2 px) at disc_r + 4 in ring_rgb */
} nl_orbit_item_t;

typedef struct {
    /* -- per-frame fields (stepped on the panel task, section B7) -- */
    float slide;          /* 0..NL_W: how far the entity has moved left */
    float lead;           /* px the orbit's content leads the slide (entry peek), 0 at rest */
    float roll;           /* radians clockwise: the orbit frame's turn on screen */
    float dial;           /* radians added to every item's ang */
    float fan;            /* 0..1: items' spread (ang' = (ang + dial) * fan) */
    float items_k;        /* 0..1: multiplies every item's opa */
    uint8_t arc_opa;      /* the value arc's opacity (0: not drawn) */
    float arc_v;          /* the arc's value end (arc_a0 <= v <= arc_a1) */
    float fill_x, fill_y; /* orbit frame px, the fill's centre */
    float fill_k;         /* 0..1 (0: none) */
    float pulse;          /* 0..1 (0: none) */
    /* -- content (published by the UI task, section B7) -- */
    float track_r;        /* px: thin ring (1.5 px, Border) the items ride on; 0: none */
    uint32_t ring_rgb;    /* the chosen item's ring */
    float arc_r, arc_w, arc_a0, arc_a1;
    uint32_t arc_rgb;     /* filled part a0..v; the rest of the span in Border */
    float fill_r;         /* the fill ring's radius, px */
    uint32_t fill_rgb;
    uint8_t n_items;
    nl_orbit_item_t items[NL_ORBIT_ITEMS];
    uint8_t n_sprites;
    nl_sprite_t sprites[NL_ORBIT_SPRITES]; /* orbit frame px; `upright` ignored */
} nl_orbit_t;
```

and in `nl_inputs_t`: `const nl_orbit_t *orbit;  /* NULL or slide 0: none */`.

Rules:

1. **Lifetime.** `in->orbit` is read only during `nl_simulate()`. The **A8 pixels** of its sprites must stay valid and unchanged until the next `nl_simulate()` (the bands read them after `nl_simulate` returns, and the damage hash keys on the `a8` pointer, not on pixels): a published sprite arena is never rewritten; content changes always go into the other buffer.
2. **Sprites.** A sprite referenced by an item is drawn **only at that item**: its own x, y are ignored and its opa is multiplied by the item's opa and `items_k`. All other sprites are drawn at their own x, y (they are not scaled by `items_k`).
3. **Slide.** While `orbit && slide > 0` the entity scene moves left by `slide` exactly as for a UI screen today (`s_slide`), and the orbit's content is drawn translated right by `NL_W − slide − lead` (along the orbit frame's x). At `slide >= NL_W` the scene is not drawn (the ring still is).
4. **Exclusive.** `in->ui` and `in->orbit` are never both non-empty; Part B guarantees it (B8.4). If both are, `ui` wins (a screen opened over the Orbit).
5. **Roll.** The orbit turns as one body by `roll` about the panel centre, its sprites too.
6. **Pure data.** Callers `memset` the struct before filling it (padding included); equal inputs give an identical display list, so idle frames repeat and `nl_band_same` skips every band.

## Part A: the renderer (`nebula_lite/`, `sim/`)

### A1. Scope

- Section 3 in `nebula_lite.h`; `nl_spr` sized `NL_MAX_SPRITES` with glass sprites first, orbit sprites after; `nl_inputs_t.sprites` and the glass sets sized `NL_GLASS_SPRITES` (`rabble_entity.c` uses `NL_MAX_SPRITES` today for both: Part B switches those uses to `NL_GLASS_SPRITES`). Indices stay `uint8_t`.
- A new `src/orbit.c` (name tunable) called from `nl_simulate()`.
- An **arc primitive** `NL_P_ARC` in `raster.c` and the damage hash: an annular sector with centre, radius, width, start and end angle, round caps (*tunable*: square), colour, alpha. Used for the track, the value arc, the fill ring and the item rings if convenient. (Building arcs from capsules costs ~60+ primitives each and double-blends at the caps.)
- **x-culling** in the list builder: a primitive whose bounding box lies wholly off the panel (x < 0 or x ≥ NL_W) is not pushed.
- Orbit primitives are pushed **after** the scene and bypass the scene's own caps (`NL_SOFT_CAP`); while an orbit shows, the scene is limited so at least 300 primitives remain for the orbit, and the meshes and mic strands are not built (`slide > 0`).
- No ESP-IDF, LVGL or hardware includes (board-agnostic, as now).

### A2. What it draws, back to front (orbit frame, then section 3 rule 3 translation and rule 5 roll)

1. **Track**: if `track_r > 0`, a ring r = `track_r`, 1.5 px, Border `0x2a2840`.
2. **Value arc**, if `arc_opa > 0`: span `arc_a0..arc_a1` width `arc_w` in Border, over it `arc_a0..arc_v` in `arc_rgb`; a knob at `arc_v`: filled disc r = `arc_w` in `arc_rgb` with a 2 px Primary Text `0xe8e6f0` ring; everything at `arc_opa`.
3. **Items** in array order (skipping any whose final x is wholly off the panel): disc, chosen ring, then its sprite. Item centre at angle `ang' = (ang + dial) · fan`, `(233 + r·sin ang', 233 − r·cos ang')`.
4. **Other sprites** (not referenced by an item) at their x, y.
5. **Fill**, if `fill_k > 0`: a ring r = `fill_r` (Part B uses 74 px, *tunable*), 5 px: Border full circle, `fill_rgb` from the top clockwise for `fill_k · 2π`, centred on (`fill_x`, `fill_y`).
6. **Pulse**, if `pulse > 0`: a ring at the fill's centre, r = `fill_r` + 40·pulse, width 3·(1 − pulse) + 1, `fill_rgb`, alpha 255·(1 − pulse).
7. The **colour ring** is drawn last, over the orbit, whenever an orbit shows (`compose.c` today draws it above content only for UI screens; extend that). It turns with `orbit->roll` while the orbit shows.

### A3. Turning sprites exactly

Orbit sprites turn with `roll` using the same sampler as the entity's upright sprites, with the orbit's own cos/sin. Fix the sampler for all sprite kinds (`upright` 1, 2 and orbit): after snapping c and s to exactly 0 or ±1 when within 0.002, use exact paths for c = 1 (copy), c = −1 (copy mirrored on both axes), s = ±1 (transposed copy, the correct way round); bilinear otherwise. Today the straight path is taken whenever |s| < 0.002 and ignores c, so a sprite at roll π is drawn unturned (`raster.c` sprite path). The damage hash must include whatever turns a sprite.

### A4. Performance

- Simulate cost of a full orbit (40 items, 48 sprites, arc, fill), host < 0.05 ms. Orbit primitives in a full page ≤ 150 (*tunable*).
- `slide = NL_W`, `fill_k = pulse = 0`, unchanged inputs: two consecutive frames hash identically in every band (host test).
- No heap allocation per frame; no new full-screen buffers.

### A5. Host harness and tests (`sim/`)

PNG scenes into `sim/out/`: (1) home page, 8 items, chosen at top, centre title and value sprites; (2) value page, arc at 62%; (3) text page: 29 small key sprites on the rim and one magnified; (4) slide 50%; (5) entry peek: slide 49 with lead 150; (6) fill 0.6; (7) pulse 0.5; (8) roll 15°, 90°, 180° (text upright and the right way round at 90° and 180°). Text may come from a tiny built-in bitmap font (no LVGL in the sim). Assertion tests: (9) the repeat-frame hash check; (10) the sampler's exact paths against a reference rotation of a test bitmap at 0, 90, 180, 270°. `sim/build.sh` keeps building and running the existing scene.

## Part B: the controller and integration (`accord/`)

### B1. Scope and files

- `accord/rabble_orbit_logic.c/.h`: pages, gestures, values, text entry, springs targets. **No LVGL, no ESP-IDF headers** (plain C + `rabble_settings.h`, `rabble_wifi.h`, `rabble_beam.h`, `rabble_input.h`, `rabble_ui.h` declarations), so the host test can compile it against stubs.
- `accord/rabble_orbit.c/.h`: the public interface (B9), sprite rasterising with LVGL fonts, double-buffering, the panel-task stepping.
- Changes to `rabble_ui.c/.h`, `rabble_entity.c/.h`, `rabble_input.c` (console), `rabble_wifi.c/.h` (B5: `join_saved`). Delete `apache/rabble_settings_ui.*`, `apache/rabble_keypad.*` (and `apache/` when only `LICENSE-APACHE` is left); update `CMakeLists.txt`.

### B2. Pages

Opening an item pushes a page; **back** pops. Back from Home closes the Orbit.

| Page | Items, clockwise from the top | Centre |
|---|---|---|
| **Home** | Sound, Display, Sleep, Wi-Fi, sCoRE, Level, Power | chosen category's name + one-line summary (Sound `vol 70 · speaker on`; Wi-Fi SSID or state; sCoRE state name; Power battery % and charging) |
| **Sound** | Volume (0..100, step 5), Speaker (toggle), Voice (choice), Mic gain (0..36 dB, step 3) | name + value |
| **Display** | Brightness (10..100, step 5), Raise to wake (toggle) | name + value |
| **Sleep** | Screen sleep (choice: 15 s, 30 s, 1 min, 2 min, 5 min, 10 min, never), Power off when asleep (choice: 30 s, 45 s, 2 min, 5 min, 15 min, 1 h, never) | name + value |
| **Wi-Fi** | Wi-Fi (toggle), Networks (list), Saved (list) | `rabble_wifi_status`: state, SSID, RSSI |
| **Networks** | scan results, strongest first, up to 24; saved ones marked | SSID, signal bars, lock if secure, `saved` if saved; while scanning `scanning...` |
| **Saved** | saved networks (`rabble_wifi_saved`) | SSID, hint `hold to forget` |
| **sCoRE** | Test (action), Reset URL (action) | state name, the URL's host part (from `rabble_settings_beam_url`) |
| **Level** | not a page: `rabble_ui_open_level()` | |
| **Power** | Power off (action, 1.0 s hold) | battery % and charging |
| **Choice** (Voice, the sleep times) | the options | the chosen option; the current one marked |
| **Text** | rim keyboard (B6) | the text so far |

Voice options: `default` (stores the empty string), `daniel`, `austin`, `troy` (*tunable*).

### B3. Looks

- Category and action items: a glyph sprite on a disc r 19.5 (stays on the renderer's fast circle path) in Surface `0x12132a`; the chosen one Raised `0x1a1b2e` with `ring` on in the page accent (`ring_rgb`). Glyphs: Montserrat 20 symbols that exist in the build (`LV_SYMBOL_VOLUME_MAX`, `LV_SYMBOL_EYE_OPEN`, `LV_SYMBOL_WIFI`, `LV_SYMBOL_POWER`, `LV_SYMBOL_REFRESH`, `LV_SYMBOL_TRASH`, `LV_SYMBOL_OK`, `LV_SYMBOL_SETTINGS`, `LV_SYMBOL_BACKSPACE`); sCoRE as the text `sC`; Sleep a crescent and Space a bracket drawn into A8 the way `rabble_entity.c` draws its mode icons.
- Accents: Home Cyan; Sound Magenta; Display Cyan; Sleep Violet; Wi-Fi Cyan; sCoRE Magenta; the Power-off fill Red; toggle fills Green turning on, Muted turning off.
- Toggles show state: on = accent disc, glyph in Deep Void; off = Surface disc, glyph Muted.
- Networks: disc r by signal 12 / 15 / 18 / 19.5 for 1..4 bars; Cyan if saved, else Primary Text at opa 160.
- Centre: title Montserrat 20 Primary Text at y 205; value or summary Montserrat 16 in the accent at y 240; hint unscii 16 Muted at y 290 (`tap to open`, `hold to turn on`, `hold to power off`). Texts over 190 px are cut with `...`.
- Fonts that exist in this build: Montserrat 14/16/18/20/22/24/26/32/48, unscii 16. Large value: Montserrat 48 if it fits, else 32. Magnified key: Montserrat 32.
- Rasterise with the LVGL font path `rabble_entity.c` uses (`add_text`, `line_width`): move it to a small shared helper both use. Rasterise only when content changes, never per frame; for a value page pre-rasterise its digits `0`..`9` (and the unit) once on opening, so a value drag composes sprites without calling LVGL fonts (they are compressed).

### B4. Gestures

All positions in the orbit frame: the raw touch turned by `rabble_entity_ui_roll()` (it already returns the roll the orbit is drawn at, B8.3). Ignored entirely while `rabble_ui_dark()` or the sleep cover shows.

1. **Enter (resistance, then snap).** On the face, a drag moving left with |dx| > 1.5·|dy| after 16 px starts the entry. At that moment call `lv_indev_wait_release(indev)` so the pressed face object gets `PRESS_LOST`, never `CLICKED` (no pet, no mode switch); the entity's lean is released too. `slide = 0.35·|dx|` and `lead = 3·slide` (the dial's left edge peeks in) until |dx| reaches 140 px (the detent); past it the Orbit commits: `slide` springs to `NL_W` and `lead` to 0 (critically damped, ~0.25 s), whatever the finger does. Released before the detent: both spring back to 0 (~0.2 s). `fan = slide / NL_W` during entry.
2. **Back.** A drag starting outside the rim zone moving right with |dx| > 1.5·|dy|, past 60 px, pops the page (the new page's `fan` from 0.6 to 1 over 0.2 s). On Home it closes the Orbit with the entry rule mirrored (follows at 0.35 until 140 px, then snaps out).
3. **Turn.** A touch starting in the rim zone whose first 16 px are more tangential than radial turns the dial by the change of the touch's angle (1:1), within the wrap or clamp rule of section 2. On release `dial` springs (~0.18 s) so the nearest item is at the top: it becomes chosen. While dragging, the chosen ring moves to whichever item is nearest the top. (On the Text page rim touches type instead: B6.)
4. **Tap a rim item** (down and up within 250 ms, moved < 12 px): the dial turns it to the top (chosen). Doesn't open it.
5. **Centre tap** (released before 150 ms, moved < 12 px): opens the chosen item. For toggles and actions it flashes the hint `hold to ...` for 1.5 s.
6. **Centre hold** (toggles, actions, Done): after 150 ms the fill starts at the touch point and grows over 0.4 s (Power off 1.0 s). Moving > 20 px or lifting first cancels (fill drains in 0.15 s). At full: the action runs once; `pulse` 0 → 1 over 0.35 s.
7. **Value mode** (Volume, Mic gain, Brightness): `items_k` → 0 and `arc_opa` → 255 over 0.15 s. A rim touch sets the value from its angle within the span (outside it, the nearer end), snapped to the step; while dragging, the value is clamped to the end last reached and never jumps across the bottom gap. The centre shows the value large. On lift the setter is called once. Brightness previews live via `rabble_ui_preview_brightness`; on cancel, back, close or sleep call `rabble_ui_preview_brightness_end()` (new, B8.8). Back leaves value mode.
8. **Choice page**: a centre tap on the chosen option selects it (setter, a pulse), then auto-back after 0.4 s.

Arbitration: the first 16 px decide (turn, back, or nothing); a gesture keeps the touch until release.

### B5. What each item does

| Item | Call |
|---|---|
| Volume / Mic gain / Brightness | `rabble_settings_set_volume/mic_gain/brightness`, once on lift |
| Speaker | `rabble_settings_set_speaker_on(!on)` |
| Voice | `rabble_settings_set_voice("")` for default, else the name |
| Raise to wake | `rabble_settings_set_raise_wake(!on)` |
| Screen sleep / Power off when asleep | `rabble_settings_set_sleep_s` / `set_power_off_s` (never = 0) |
| Wi-Fi toggle | `rabble_settings_set_wifi_on(!on)` (the app's settings listener already applies it) |
| Networks (on open) | `rabble_wifi_scan()`; each tick poll `rabble_wifi_scanning()` and `rabble_wifi_scan_results(…, &gen)`, rebuild when `gen` changes. Centre tap on a **saved** network → `rabble_wifi_join_saved(ssid)`; an **open** one → `rabble_wifi_join(ssid, NULL)`; a **secure unsaved** one → Text page (password), whose Done calls `rabble_wifi_join(ssid, text)`; then back to the Wi-Fi page. If a scan lists a saved network while the state is `RABBLE_WIFI_NOT_NEARBY`, call `rabble_wifi_apply()` once. |
| Saved: centre hold | `rabble_wifi_forget(ssid)` |
| sCoRE Test (hold) | `rabble_beam_test()`; centre `testing...` until the state leaves TESTING |
| sCoRE Reset URL (hold) | `rabble_settings_set_beam_url(NULL)` then `rabble_beam_config_changed()` |
| Level | `rabble_ui_open_level()`; the Orbit keeps its page underneath |
| Power off (hold 1.0 s) | `rabble_input_request_power_off()` |

**New in `accord/rabble_wifi.c/.h`:** `void rabble_wifi_join_saved(const char *ssid)`: if the network is saved, move it to the front and join it with its stored password, never changing that password; if not saved, do nothing. Same threading and non-blocking rules as `rabble_wifi_join` (W3 spec section 8); add a case to the W3 Wi-Fi host test if one covers join.

Getters are polled at most every 250 ms; sprites rebuild only when a shown value changed.

### B6. Text page (rim keyboard)

- Layers of keys, each laid on the rim with the **layer key**: n keys + 1 layer key spaced over n + 1 slots, the layer key at the bottom (π). Layers: `abc` = `a`..`z`, Space, Backspace (28); `ABC` the same in capitals; `123` = `0`..`9` `. - _ @ ! ? # $ % & * + = / : ; , ' " ( ) ~ ^` Space Backspace; `+=` = every remaining printable ASCII 0x20..0x7e (`` ` { } [ ] \ | < > ``) Space Backspace. The layer key cycles abc → ABC → 123 → += → abc and shows the next layer's name. All of 0x20..0x7e must be reachable.
- **Typing**: a rim touch selects the key nearest its angle: drawn magnified (Montserrat 32, Cyan, disc r 18 Raised) and previewed in the centre; sliding along the rim moves the selection. **Lift types the key that was selected 80 ms before the lift** (a lifting thumb drifts). Sliding inward out of the rim zone before lifting cancels. Rim touches never turn the dial on this page.
- Centre: the text so far (Montserrat 20, the last ~14 characters after a leading `...`). A password shows `*` per character except the most recent for 1 s; a centre tap toggles plain view.
- **Done**: centre hold 0.4 s (Green). **Back** cancels.
- Limit: password 64 characters (W3); more typing flashes the text Red briefly and is ignored.

### B7. Threading and frame rate

- **UI task** (LVGL): `rabble_orbit_touch()` from the indev hook, `rabble_orbit_tick()` every UI frame. It owns the page logic and publishes **content** into one of two `nl_orbit_t` buffers (memset, then filled; own sprite arena per buffer), flipping a front index only when the panel task has taken the last one (the glass's front/back hand-off in `rabble_entity.c`).
- **Control targets** (finger angle, finger position, press state, dial/slide/value targets, fill target and the like, < 64 B) pass from the UI task to the panel task as one snapshot: a `portMUX` critical-section copy or a sequence-counter read, never field by field.
- **Panel task**: `rabble_orbit_frame(dt)` once per frame in `frame_begin`: copies the front buffer to a private one, steps every spring and fade (dial, slide, lead, fan, items_k, arc_opa, arc_v, fill, pulse) toward the latest targets, interpolating the finger (touch arrives every ~15 ms), writes the per-frame fields, and returns it for `in.orbit`. No locks another task may hold for long; no Wi-Fi, beam, settings or LVGL calls there.
- **Console** (`>orbit=`, B8.7) runs on the serial task: it takes `rabble_board->display_lock` around `rabble_orbit_command`.
- **Sleep**: closing at once is a `snap_closed` flag applied by the next `rabble_orbit_frame` (the panel task is stopped while asleep). `rabble_orbit_showing()` reads an atomic.
- **At rest** every field of the published orbit is exactly constant, so idle frames repeat.
- **Gates** on the gadget (the entity's own fps and late-frame lines): slide in/out ≥ 40 fps; dial drag ≥ 40; value drag ≥ 40; rim typing ≥ 40; idle on any Orbit page 60 fps with all bands repeated; no late frame over 150 ms in a 5-minute session.

### B8. Integration

1. **Tileview out.** `rabble_ui.c` keeps the face as the main screen's only content; the Settings tile, its tick and `rabble_ui_set_swipe_enabled()` go (remove from `rabble_ui.h`). `on_render_start` tags `NL_W` for any other screen (clock, level), 0 on the main screen. `on_gesture` drops its tileview test and acts only when the Orbit is closed and no entry drag runs.
2. **Touch.** `touch_read` calls `rabble_orbit_touch(pressed, x, y)` first with the raw point, unless `lv_screen_active() != s_main` (clock or level open: the Orbit does nothing, LVGL gets the touch). If the Orbit took the touch, LVGL and `rabble_entity_touch` get a released state for it (after the B4.1 `lv_indev_wait_release` at takeover).
3. **Roll.** `ui_notch` stays the one place the UI roll is made: call it once per frame with `shown = max(tex.tag, the previous frame's orbit slide) / NL_W`, honour `s_ui_fixed`, and use its result for both `in.ui.roll` and `orbit->roll`. Touch uses `rabble_entity_ui_roll()` (exists).
4. **Showing.** `frame_begin` sets `in.orbit = rabble_orbit_frame(dt)` (NULL when closed or slide 0) and leaves `in.ui` empty then, **except** while `lv_screen_active() != s_main` (signalled to the panel task by the UI texture's tag = `NL_W`): then `in.orbit = NULL`, the screen shows, and the Orbit keeps its state underneath. `set_entity_active` treats the Orbit as part of the entity (stays active).
5. **Closing.** `rabble_ui_show_face()` (listening started) closes the Orbit (springs out). The sleep branch of `frame_tick` closes it at once (`snap_closed`, Home reset). Closing the clock or level screen returns to the Orbit page that was showing.
6. **Tick placement.** `rabble_orbit_tick` runs every UI frame, before `frame_tick`'s early return when the entity draws.
7. **Console** (`rabble_input.c` on `cleanroom`): `>orbit=open`, `close`, `back`, `turn:<n>` (n items, ±), `tap` (centre tap), `hold` (a full centre hold, as if held past its fill), `value:<v>` (in value mode, set and commit v), `type:<text>` (on the Text page, type it), `state`. Each replies one line `@orbit {"page":"…","chosen":"…","value":…,"slide":…}`.
8. **Brightness preview end.** Add `void rabble_ui_preview_brightness_end(void)` to `rabble_ui.h/.c`: stops previewing and returns to the saved brightness (it must not call any setter).

### B9. Public interface (`rabble_orbit.h`)

```c
void rabble_orbit_init(void);                         /* LVGL task, after rabble_entity_init() */
void rabble_orbit_tick(float now);                    /* LVGL task, every UI frame */
bool rabble_orbit_touch(bool pressed, int x, int y);  /* LVGL task (indev hook): true if the Orbit took it */
bool rabble_orbit_showing(void);                      /* any task: slide > 0 or an entry drag running */
void rabble_orbit_close(bool animate);                /* LVGL task; animate false = snap_closed */
void rabble_orbit_command(const char *cmd);           /* under display_lock: the console's >orbit= argument */
const nl_orbit_t *rabble_orbit_frame(float dt);       /* panel task, once per frame; NULL when closed */
```

The implementer may add functions; these are what `rabble_ui.c`, `rabble_entity.c` and `rabble_input.c` call.

### B10. Tests

- `firmware/test/cleanroom/w5/orbit_test/run.sh`: `rabble_orbit_logic.c` compiled on the host against stubs (`rabble_settings`, `rabble_wifi`, `rabble_beam`, `rabble_input`, `rabble_ui`) and a fake clock. No include path into `apache/`. Scripted touches must cover: entry released before the detent (springs back, no open, no click delivered); entry past it (opens); rim turn 2.4 pitches then release (snaps to 2); wrap with 8+ items, clamp with 3; tap a rim item; centre tap opens Sound; value drag sets Volume once on lift to the snapped value; dragging across the gap stays clamped; hold Speaker 0.3 s then lift (no call); hold 0.6 s (one call); Power off needs 1.0 s; back from Home closes; Networks: saved → `join_saved`, open → `join(ssid, NULL)`, secure → Text page; typing `aB3` across layers then Done → `rabble_wifi_join(ssid, "aB3")`; the 80 ms lift rule; Backspace; the 64-character limit; at rest two consecutive control snapshots and published contents are byte-identical.
- The firmware build with `-Werror` clean.

## 4. Integrator checklist (parent session)

1. Overlap gate (`ops/cleanroom-overlap.py`) on every new and changed file (expected near 0: a new design); transcript audit (`ops/cleanroom-audit.py`).
2. Build, flash, drive every page from the console (B8.7), read the fps and late-frame lines for each B7 gate.
3. Mark's hand checks: entry resistance, peek and snap; dial feel; value drag; hold-to-fill timing; typing a real Wi-Fi password; join, forget; sCoRE test; Level and clock over the Orbit; power off; readability at rest and while turning.
4. PROVENANCE row (W5: S = this spec, F = none (redesign, originals unread), I = the two implementers); delete the `apache/` settings_ui and keypad in the swap commit.

---

## 5. Revision 3: Orbit v2, after Mark's first hand check (S266)

Mark, on the gadget: *"a good first step... feels cool but needs more text UI to guide the user and more clear input signals"*; too many taps for simple things; no easy way back; the NN mesh vanishing on the way in is wrong ("the mesh should actually be part of the transition"); he got stuck in Brightness's value mode. His calls: a **flat quick ring**, and **the mesh becomes the dial**. The Orbit is RaBbLE's own code now (W5 swapped in), so v2 is ordinary work on `accord/` and `nebula_lite/`, not a clean-room wave. Everything in sections 1 to 4 stands unless changed here.

### 5.1 Flat Home ring

Home holds the settings themselves, clockwise from the top: **Volume** (value), **Brightness** (value), **Speaker** (toggle), **Wi-Fi** (opens the Wi-Fi page), **sCoRE** (opens the sCoRE page), **Sleep** (choice: screen sleep), **Level** (opens Level), **Power off** (action), **More** (page). 9 items: the dial wraps. **More** holds Voice (choice), Mic gain (value), Raise to wake (toggle), Off when asleep (choice). The Sound, Display, Sleep and Power pages go. Volume is now two actions: turn to it, tap the centre (value mode opens directly).

### 5.2 Text on the ring

Every item carries a **label sprite** with its name and current value in words (`Vol 70`, `Bright 80`, `Speaker on`, `Wi-Fi RaBbLE`, `sCoRE ok`, `Sleep 2m`, `Level`, `Power off`, `More`), Montserrat 14, centred on the item's angle at radius 140 (inside the ring of discs), turning with the dial like the items (a referenced sprite, section 3 rule 2: so it is an item of its own with `disc_r` 0, or the implementer extends the item with a second sprite index: decide, keep the contract change minimal and note it). Not chosen: Muted, opa 200. Chosen: Primary Text, opa 255. Discs shrink to r 16 at radius 186 so labels fit; the label budget is 12 characters (cut with `...`).

### 5.3 The centre always says what to do next

Three lines, always present: **name** (Montserrat 20), **value** (Montserrat 32 for numbers, 20 for words; the accent), **hint** (Montserrat 14, Muted) with the exact next action for the state: `turn the rim to choose` (while turning), `tap to change` (a value or choice), `tap to open` (a page), `hold to turn off` / `hold to turn on` (a toggle), `hold to power off`, and in value mode `drag the rim · tap here when done`.

### 5.4 A way back that is always visible

A **back chip** at the bottom of the centre (centred at y 233 + 78 in the orbit frame): `‹ face` on Home, `‹ Home` on More, Wi-Fi and sCoRE, `‹ Wi-Fi` on Networks and Saved, `‹ back` in value mode and on the Text page. Montserrat 16, Cyan, with a Raised pill behind it (a disc pair or an arc primitive: implementer's choice) so it reads as a button. A tap within 40 px of its centre goes back (value mode: commits the value shown, then leaves; Text page: cancels). The swipe-right back (B4.2) also starts from anywhere outside the rim zone **and** from the rim's left half when the first 16 px are clearly rightward (dx > 2·|dy|), so a natural swipe right always works.

### 5.5 Value mode never traps

Value mode is left by any of: a tap on the centre (**done**: commits), the back chip (commits), the back swipe (commits), or **2 s after the last lift** with no new touch (commits). The setter is still called once per lift as before; leaving never calls it again. Brightness preview ends on leaving.

### 5.6 Clear input signals

- **Touch glow**: while a finger is down on the Orbit, a soft ring (r 26, 3 px, the page accent at opa 140) under it in the orbit frame.
- **Rim lit while turning**: the track brightens to the accent (opa 200, 3 px) during a rim turn and in value mode, back to Border at rest.
- **Detent flick**: each item passing the top during a turn makes the chosen ring flash (opa 255 for 80 ms) and the touch glow pulse once.
- **Hold**: the fill ring is centred on the centre (not under the thumb) at r 74 so it's visible around the finger; the hint changes to `keep holding...` while it fills.

### 5.7 The mesh becomes the dial

On the way in (0 < slide < `NL_W`) the NN meshes keep drawing (undo the A1 rule that skipped them; keep the scene's primitive cap). As `k = slide / NL_W` grows, each mesh node moves from its own place toward an item position of the dial (node i to item i mod n, as the dial will sit when open), on a smoothstep of k, and its radius toward the item's disc radius; the links' alpha falls as (1 − k)²; the items' discs fade in as (k − 0.6)/0.4 clamped, so at k = 1 only the dial remains and at rest nothing animates (60 fps, every band repeated). Closing runs the same in reverse: the dial's items dissolve back into the meshes. The entity's eyes and portals slide left as before. Gate: the slide in and out ≥ 40 fps with the meshes drawn (the entity's own log).

### 5.8 Tests

Extend `firmware/test/cleanroom/w5/orbit_test/` for 5.1 (Volume in two actions), 5.4 (back chip on every page, swipe right from the rim's left half), 5.5 (each of the four exits of value mode commits once, never traps), 5.3 (hint text per state). Extend `sim/` with a v2 Home scene (labels and back chip) and three mesh-transition frames (k = 0.3, 0.6, 0.9). Keep every existing test passing and the `-O2 -Werror` compile clean.

---

## 6. Applets orbit and the Pomodoro (S266 design, Mark's calls)

Built on the Orbit after v2 (section 5). Ordinary work on RaBbLE's own code.

### 6.1 The Applets orbit

- **Swipe right** from the face opens it: the mirror of Settings' entry (B4.1 with dx > 0; the same resistance 0.35 until 140 px, then the snap; the dial comes in from the **left**, the entity slides right, the mesh streams into it as in 5.7). Back (chip or swipe left) closes it.
- Same renderer, gestures, labels, hints and back chip as Settings. The contract gains only a sign: `nl_orbit_t.from_left` (0: from the right as today, 1: from the left), or the implementer's equivalent (keep it minimal).
- Home ring today: **Pomodoro** (later applets join the ring). With one item the dial clamps (section 2), so the ring shows the applet's own items directly: opening Applets lands straight on the Pomodoro page.

### 6.2 The Pomodoro page

Items, clockwise from the top: **Focus** (choice: 15, 20, **25**, 30, 45, 50 min), **Break** (choice: 3, **5**, 10 min), **Long break** (choice: 10, **15**, 20 min, after every 4th focus round), **Start / Pause** (action), **Reset** (action, 0.6 s hold). Settings persist in NVS (`rabble_pomo`).

Centre: name; the remaining time large (`24:13`, Montserrat 48 while running, else the chosen length); a dots line for the 4 rounds (`● ● ○ ○`); the hint (`hold to start`, `hold to pause`, `hold to resume`).

### 6.3 The timer

- States: `IDLE`, `FOCUS`, `BREAK`, `LONG_BREAK`, `PAUSED` (remembers which it paused). Runs on `esp_timer` time in its own small module (`rabble_pomo.c/.h`), not on the UI tick, so sleep doesn't stop it; it survives the screen sleeping (not a reboot: a reboot returns to IDLE with the round count kept).
- Focus ends → chirp (`rabble_voice_request_chirp`), `rabble_state_make_happy()`, the round dot fills, the break starts on its own. Break ends → chirp, the next focus waits for a hold (Mark starts work deliberately). After the 4th focus, the long break, then the dots reset.
- The device wakes the screen at each round's end (`rabble_input_wake("pomodoro")`).

### 6.4 The ring carries it, in every view

While a Pomodoro runs or is paused, the colour ring (section `compose.c` ring, already in every view) shows the round: a **draining arc** from the top, clockwise, of length remaining/total, in **violet** (focus) or **green** (break), over the dimmed normal ring; paused: the arc blinks slowly (1 Hz, opa 255/120). The ring's other signals (error red, low battery yellow) still win. Contract: add to `nl_inputs_t` a `ring_arc` (0..1, 0 = none) and `ring_arc_rgb`, `ring_arc_opa`; drawn by the arc primitive at the ring's radius. At rest between second ticks the inputs are constant (the arc steps once per second: 1 fps worth of bands, not 60).

### 6.5 The watchful face and keeping Mark on task (his picks)

- **Focus look**: during FOCUS the entity is calm and watchful: eyes narrowed (a new 0..1 `focus` input to nebula_lite: eye height × (1 − 0.35·focus), mesh activity × (1 − 0.5·focus)), eased in over 1 s.
- **Fidget detection**: during FOCUS, picking it up (a raise: up's z climbing as in raise-to-wake), a shake, or a touch on the face counts a **fidget**: the entity gives a disapproving look (a short `sad`/error-tinted pose, 1.2 s: reuse `NL_STATE_ERROR`'s pose without the error colour, or a new `frown` input) and the ring arc flickers twice. Fidgets are counted per round and shown under the dots (`2 fidgets`); at the round's end the reward scales: 0 fidgets = a big happy hop, 1-2 = happy, 3+ = a flat "hm" (no hop). Touches on the Orbit itself (Mark operating the timer) don't count.
- **Check-in nudges**: every 10 min of FOCUS (*tunable*), a soft chirp and the entity glances at the viewer (eyes to centre, a slow blink). A tap on the face within 30 s = "still on it" (a small nod: happy 0.3). No tap in 30 s: a concerned look (eyes droop, the ring arc dims to 50%) until the next touch, and it counts as a fidget. Nudges are skipped while Mark is mid-voice-turn.
- Spoken nudges via sCoRE are deferred to the vocoder voice.

### 6.6 Console and tests

- `>pomo=start|pause|reset|state|skip` (skip ends the current round now; for testing), replying `@pomo {"state":…,"left_s":…,"round":…,"fidgets":…}`.
- Host test of `rabble_pomo.c` with a fake clock: full cycle 4 × (focus + break) + long break, pause/resume keeps the remaining time, reset, fidget counting and the check-in timeout, NVS defaults.
- sim: the ring arc at 0.25 / 0.75 in violet and green, and the focus look.
- Gates: the ring arc in every view costs ≤ 1 band redraw per second at rest; 60 fps idle with a Pomodoro running.
