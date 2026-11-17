# Pocket seam, slot and LVGL driver: design note (split adopted 2026-11-05)

> **Panel/touch split ADOPTED by Mark, 2026-11-05** ("proposed split sounds good, replace lv with generic enum for easy swaps"): LVGL types leave the board contract entirely, `lv_align_t` becomes a plain enum; W11 includes the split (no longer provisional). Companion to `Pocket-Core-Apps-Reorg-Plan.md` (sections 6, 13). Nothing implemented. W11 rev 4 folds the split in.

## Three nouns, three jobs

| Noun | What it is | Layer | Today |
|---|---|---|---|
| **Board contract** (the "seam") | One table a board fills in: facts (size, round, touch, buttons), and capability groups (screen, sound, supply, clock, motion, pad). Callers reach hardware only through it; absent features are NULL. | `boards/` side of the hardware line | `rabble_board_t` in `rabble_core/rabble_board.h`, W11 rewrites it |
| **Driver** | Code that talks to one chip or library (CO5300 panel, ES7210, AXP2101, QMI8658, LVGL). Implements part of the contract for one board. | `drivers/` | `rabble_axp2101`, `bsp/`, `rabble_lvgl_port` |
| **Slot** | The seat an entity occupies on a board: the hooks core calls into the entity (mood, level, tick, voice profile, Orbit pages). | core to entity boundary | `rabble_entity_set_active` and friends |

The board contract is hardware-facing and must not know about entities. The slot is entity-facing and must not know about chips. Core sits between them.

## The LVGL problem

The board contract includes `lvgl.h`, and `display_start` returns `lv_display_t` and `lv_indev_t`. So a board cannot be described without LVGL, though LVGL is a rendering choice (RaBbLE draws through nebula_lite bands and only uses LVGL for UI chrome; Foundling is plain LVGL).

## Proposal

1. Split the screen group in two capabilities:
   - **panel**: geometry, brightness, sleep, pause, lock/unlock, and a raw band sink (push RGB565 rows). No LVGL types.
   - **touch**: an event stream (x, y, down/up) with no `lv_indev_t`.
2. Move LVGL into `drivers/lvgl_port` as a graphics driver that *consumes* panel and touch and *produces* `lv_display_t`/`lv_indev_t`. An entity that wants LVGL links the driver and calls its start function; an entity that does not (a future pure-nebula one) never links it. No link-time side effects: the driver starts only when called.
3. Core's `screen` service (W9: sleep, brightness, black cover, double-tap wake) talks to the panel capability only, so it stays LVGL-free.
4. The direct band path (`display_direct`, `ui_texture`) stays a panel capability because it is board-specific speed work, not LVGL.
5. The LVGL render fallback for RaBbLE (same face, different renderer; never another face) then costs nothing structurally: RaBbLE links the LVGL driver and draws its face through it.

## Questions for Mark

- Is the panel/touch split with LVGL as a consumer the right cut? (Recommendation: yes.)
- Does `lv_align_t` in the button icon hint move to plain enums? (Recommendation: yes, a four-line change.)
- Does W11 wait for this note? (Recommendation: W11 implementer runs after you confirm this note, since the screen group reshapes; everything else in W11 is stable.)
