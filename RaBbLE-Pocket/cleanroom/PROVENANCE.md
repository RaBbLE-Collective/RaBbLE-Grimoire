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

**Transcript audit (W0):** I extracted every tool call from both implementer transcripts (51 calls) and matched it against the tainted paths: `RaBbLE-Collective`, `muse-gadget`, `apache/`, `rabble_axp2101`, `bsp/`, `backups`.
- Nothing touched them. The two hits were the harness's saved copies of the implementers' own BRIEF and spec output.
- Transcripts are archived privately in `~/RaBbLE-Cleanroom/transcripts/<wave>/`, outside every repo.
- Script: Pocket `ops/cleanroom-audit.py`. Rerun it for each wave.

**Branch:** clean-room waves land on Pocket branch `cleanroom`, which forks from `new-horizons` at `96225b0` (just before W0). Each wave is verified there before it merges back.

## Wave W1: leaf (S256, 2026-10-16/17)

Workspace: `~/RaBbLE-Cleanroom/pocket-w1`, exported from Pocket `cleanroom` at `096f695`. It also holds the golden vectors and `cleanroom/interfaces/` (declaration-only extracts of settings, wifi, beam and voice, with comments stripped).

| Module | Spec (S) | Firewall (F) | Implementer (I) | Overlap after | Pocket commit |
|---|---|---|---|---|---|
| `rabble_adpcm.c/.h` | `w1-adpcm.spec.md` + `w1-adpcm-vectors/` (golden output of the original), Sonnet 5.5 sub-agent | S256 parent: approved; marked two unmeasured test thresholds as guidance only | fresh Sonnet 5.5 sub-agent, tables from the public IMA/DVI standard | 12.5% (7/56): header interface fields, plus `if (diff < 0)` and `diff = -diff` | `3916488` |
| `rabble_console.c/.h`, `rabble_setup.c/.h` | `w1-console-setup.spec.md`, Sonnet 5.5 sub-agent | S256 parent: approved (behaviour tables and exact user-visible strings) | fresh Sonnet 5.5 sub-agent | 8.2% (19/231): the ESP-IDF USB-serial calls a thin wrapper must make, and generic idioms | `f1cc6fb` |
| `rabble_text.c/.h`, `rabble_beam_text.c` (+ new `rabble_beam_text.h`) | `w1-text.spec.md` + `w1-text-vectors/`, Sonnet 5.5 sub-agent | S256 parent: approved; the mapping table is regrouped by output (the original indexes it by code point) | fresh Sonnet 5.5 sub-agent | 6.9% (32/461): generic idioms; no mapping-table line matches (sorted ranges + binary search) | `34cd63c` |

**Gate judgment (W1):** every hit is an API-forced call, an interface declaration, or a one-token idiom. Accepted.

**On the gadget:**
- Clean builds.
- Setup commands over serial: replies, `@setup` lines and the full `@status` JSON as specified, with secrets left out of the log.
- A voice turn through the beam, and a `chat=` turn with ack, sent, text, done lines and correct escaping.
- 60 fps idle. Heap at ready: internal 34,063, unchanged within 150 bytes.
- ADPCM runs only on no-PSRAM builds. It is proven by the vectors, not on this gadget.

**Tests in Pocket:** `firmware/test/cleanroom/w1/`. They read their golden vectors from the Grimoire. The ASan, UBSan and TSan passes are skipped on this machine because those runtimes aren't installed.

**Transcript audit (W1):** `ops/cleanroom-audit.py` over the three implementers (50 tool calls): 0 flagged. Three calls wrote scratch files to the session scratchpad, which contains only integrator logs. Transcripts are archived in `~/RaBbLE-Cleanroom/transcripts/w1/`.

**Spec erratum found by W1:** the W0 state spec's description of `rabble_text_to_ascii` was wrong; it is corrected there. The text spec's "first character" wording (5.2) has a vector-backed correction: it means the first character with width, so a zero-width character (an emoji) at the start of a line doesn't count. That is noted in the implementation.
