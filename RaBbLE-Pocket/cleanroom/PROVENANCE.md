# PROVENANCE.md: Pocket clean room

> One row per module swapped in. Process: `../RaBbLE-Pocket-Clean-Room-Plan.md`. Overlap measured with `RaBbLE-Pocket/ops/cleanroom-overlap.py` (integrator only) against `firmware/muse-gadget-sdk/esp32` at `b139b45`.
> Agents: "fresh sub-agent" means a Claude Code sub-agent started with no conversation context. Its brief is the spec plus `cleanroom/BRIEF.md`, in the plain-export workspace `~/RaBbLE-Cleanroom/pocket` (no `apache/`, `rabble_axp2101/`, `bsp/`, SDK or git history).

## Wave W0: seam (S256, 2026-10-16)

| Module | Spec (S) | Firewall (F) | Implementer (I) | Inputs given to I | Overlap after | Pocket commit |
|---|---|---|---|---|---|---|
| `rabble_state.c/.h` | `w0-state.spec.md`, Sonnet 5.5 sub-agent (read the originals and the SDK) | S256 parent session (Opus 5.5): removed passages that prescribed the original's locking primitives and scratch-buffer design | fresh Sonnet 5.5 sub-agent | the state spec, the seam spec, BRIEF, clean workspace, ESP-IDF headers | `.c` 10.6% (15/141), `.h` 16.7% (7/42); all hits reviewed: `esp_timer_get_time` idiom, `va_start`, the struct fields and enum the interface fixes | `096f695` |
| `rabble_board.h`, `rabble_mem.h`, `rabble_board.c`, `rabble_lv_mem.c`, `rabble_app.c` | `w0-seam.spec.md`, Sonnet 5.5 sub-agent | S256 parent: rewrote the button-wait section from a step list into requirements, removed a private constant name | fresh Sonnet 5.5 sub-agent, one rework round | the same | first pass `board.c` 46% and `lv_mem.c` 100% (private names and bodies the spec never gave, likely training recall). Sent back as "rewrite these lines of yours", without showing the original. After the rework: `board.c` 4.5% (3/66: `b->stable = 0` twice, `esp_sleep_enable_gpio_wakeup()`), `lv_mem.c` 11/19, all of them LVGL's fixed hook prototypes plus `heap_caps_free(p)` and `return LV_RESULT_OK`. `board.h` 44% and `state.h` 17%: every hit is a field or prototype the interface fixes. `app.c` 20%: log strings the spec required, `ESP_ERROR_CHECK` calls. `mem.h` 0% | `096f695` |

**Gate judgment (W0):** the headers can't reach 5%: a drop-in seam has to declare the same fields and prototypes. Every hit in the `.c` files is now an API-forced line or a one-token idiom. Accepted.

**Behaviour checklist on the gadget (W0):**
- Clean build, no warnings.
- Boot order and log lines as specified.
- Heap matches the pre-swap boot within 100 bytes: internal 123,927 vs 124,023 after the UI is built, 34,095 vs 34,191 at ready.
- 60 fps idle.
- One push-to-talk turn through the live beam: reply after 1.7 s, 42 fps while busy, back to 60 at idle.
- The two "GPIO isr service already installed" errors appear in the pre-swap log too. They come from the panel and touch code, not from W0.
- Not run (needs hands): button debounce and wake on the glass, settings dispatch.

**Tests kept in Pocket:** `firmware/test/cleanroom/w0/`:
- `state_test/run.sh`: host unit tests, plus a TSan build when libtsan is installed.
- `seam_test/run.sh`: a host debounce test, and an Xtensa `-fsyntax-only` compile of every `accord/` and `main/` file against the new seam, using stub headers.
