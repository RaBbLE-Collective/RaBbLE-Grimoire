# RaBbLE-Pocket-Provenance-Record.md

> What in the Pocket firmware is original, what was redone, and what is derived or influenced, as of 2026-11-02.
> Evidence: a fresh overlap run against the SDK at its pinned commit, the Oct 6-7 port transcripts, and an audit of the clean-room implementer transcripts. Not legal advice; the facts for a lawyer and for the public README note.
> Raw reports and scripts: `cleanroom/audit-2026-11-02/` (`OVERLAP-REPORT.md`, `TRANSCRIPTS-port.md`, `TRANSCRIPTS-firewall.md`, `scripts/`). Wave-by-wave record: `cleanroom/PROVENANCE.md`. Plan: `RaBbLE-Pocket-Clean-Room-Plan.md`.

## 1. Upstream and base

- Upstream: Meta's Muse Gadget SDK, `github.com/facebookincubator/muse-gadget-sdk`, Apache-2.0, Copyright Meta Platforms.
- Base commit: `b139b45064b4dcecf7bfe97e75bc7f99c10c28b6`, 2026-10-05. Full clone by the S242 session (2026-10-06), no pull afterwards, so every port came from this one commit.
- Port: Pocket `42ae6d9` (2026-10-06, S243), 85 files. Mark's brief: use it as "a possible experimental starting point"; only Apache-2.0 parts; own LVGL instead of the SDK avatar; beam to sCoRE; no Muse references in code.
- Never taken: Jollybot avatar, Home Link (pairing, tokens, Noise, tunnel, OTA, account API, chat link, chat session client), BLE/menu, minimp3, other boards, camera.

## 2. The four buckets

| Bucket | What | State at `HEAD` (`0d3d438`) |
|---|---|---|
| **Derived (mechanical)** | `port.sh` copied SDK files and `sed`-renamed `muse_`/`MUSE_` to `rabble_`/`RABBLE_`: adpcm, audio, battery, board, console, input, keypad, lv_mem, mem, settings_ui, state, text, voice, app, wifi_mgr, wifi_known, beam (from chat), lcd_bands, axp2101 (from pmu), the board file. Several unedited renames (adpcm, audio, battery, lv_mem, text, beam_text, state, lcd_bands). Overlap at the port commit: 59.4% of substantive lines. | **Redone** by clean room W0-W6, deleted. Files, headers and `LICENSE-APACHE` gone. |
| **Derived by influence** | Written by the same tainted session with SDK files open in context: `rabble_setup`, `rabble_wifi` (since redone in W1/W3), and `accord/rabble_ui.c`, `accord/rabble_beam_score.c` (SDK `muse_ui.c` and `muse_chat_session.cpp` had been read in part), plus build config (`sdkconfig.defaults`, Kconfig, CMake) written after reading the SDK's. | **Still in the tree, never clean-roomed.** Overlap 12.3% (`rabble_ui.c`) and 15.4% (`rabble_beam_score.c`); shared helper names `psram_alloc`, `json_alloc`. |
| **Structural echo** | The board vtable: `rabble_board.h` fields (`display_lock`, `talk_button`, `power_off`, `mic_slot`, ...) match the SDK's board files. The W0 seam kept the original port's shape. | Still in the tree: `rabble_board.h` 43.5% by lines, 30.8% by 5-line windows. Interface-level, but the most visible structural overlap. |
| **Original** | `entity_face`, `ui_theme.h`, `clock_screen`, `main/app_main.c` (Mark's pre-port code, Aug 2026); `rabble_palette.h`, `rabble_lv_assert.h`; `nebula_lite` (<=1% overlap); motion + QMI8658 (from Waveshare component and datasheet); entity, capture, notes, outbox, pomo, time (written after the port); the Orbit settings dial (W5, a redesign); sCoRE beam server. | Original. Some carry 3-16% line overlap from generic idioms (cJSON, NVS, FreeRTOS, I2C, `ESP_OK`) and datasheet-forced register data; the QMI8658 driver is the highest at 26-28%. |

## 3. Overlap numbers (SDK `b139b45`, original script, metric unchanged)

Substantive line = whitespace-normalised, >12 chars, not include/comment/brace; a match = occurs verbatim anywhere in SDK `esp32/` C/C++ (252 files).

| Tree | Overlap |
|---|---|
| `42ae6d9` whole firmware (port) | 59.4% (components 59.1, bsp 71.3, axp2101 74.6) |
| `6c3b78b^` (just before the last Meta file left) | 8.0% |
| `HEAD` whole firmware | **8.0%** (9.0% vs. current upstream HEAD, so pin the SDK commit) |
| `HEAD` minus lines also in ESP-IDF/managed components | 3.5% |
| `HEAD` 5-line identifier-normalised windows | 2.3% |

`HEAD` has zero hits for `muse_`, `MUSE_`, `meta`, `Jollybot`, `coucou`. 142 non-third-party SDK symbols appear at `HEAD`, mostly generic statics; structural ones are the board vtable names, `load_str`/`load_u8`, `copy_str`, `psram_alloc`, `json_alloc`, and datasheet register names. Highest `HEAD` files: `bsp_display.c` 22.7%, `rabble_axp2101.c` 21.8%, `rabble_wifi_radio.c` 18.2%, `bsp_waveshare_175b.c` 16.6%, `rabble_notes.c` 15.4%, `rabble_beam_score.c` 15.4%. The metric is verbatim lines; renamed copying evades it; the window check only partly covers that.

## 4. Clean-room firewall (transcript audit)

- 32 archived transcripts, all with root prompt to handback; models match PROVENANCE (Sonnet 5.5 except W6 rev 2 on Opus 5.5).
- No implementer tool call returned original content. Waves W0, W1, W3, W4, W5: no breach. W2 and W6: minor.
- W2 minor: the battery implementer read the 27-line declaration extract of its own module (`interfaces/rabble_battery.h`). Not listed in PROVENANCE.
- W6 minor: `SEAM-SPEC.md` (shown to both W6 implementers) names a private array (`s_drender_us[RABBLE_UI_CORE]`), the original files `bsp/rabble_lcd_bands.c/.h` and the alias `rabble_lcd_direct_t`. W2 and W3 specs name original files and callers.
- All 32 transcripts loaded `MEMORY.md`, whose entries describe the SDK and the `apache/`/`accord/` split. Description only.
- Spec authors and the parent-session firewall turns for W2, W5, W6 rev 1 and W6 rev 2 have no archived transcript, so spec provenance there cannot be audited. The implementers are all present. W1's 35-hour pause is unrecorded in PROVENANCE.
- Residual that no transcript can settle: training-data recall by the implementer models. First-pass overlaps of 10-46% were attributed to it; the final gate numbers are above.

## 5. License and attribution facts

- Headers: the port first kept Meta's full Apache header plus a "Modified" notice; Mark then asked for his copyright above Meta's and for the Meta origin to be less obvious; derived files were compacted to four lines (RaBbLE copyright, Meta copyright line verbatim, SPDX `Apache-2.0`). `LICENSE-APACHE` was copied beside the derived files. The SDK had no NOTICE file at `b139b45`.
- Git history up to `6c3b78b` (2026-10-24) holds the Meta-derived files with those notices. The repo is private; `new-horizons` is pushed, tags: none.
- Mark's decision, kept: no copyleft; permissive third party only; RaBbLE code under the Sovereign Accord (and, per the Nov 2 session, an Apache open layer is leaning).

## 6. Open items

1. `rabble_ui.c` and `rabble_beam_score.c` (and the board vtable names) are derived by influence and were never clean-roomed. Decide: clean-room them, or accept and state it in the README.
2. Decide whether to keep full history on going public (recommended: keep; it is the evidence, and Apache notices are in those commits) and word the README accordingly.
3. Gitleaks scan of all branches (`cleanroom`, `main`, `new-horizons`, `w6-integration-wip`) and tags before any repo goes public. gitleaks is in the OS manifest; install pending.
4. Optionally run the overlap script on `rabble_ui.c` and `rabble_beam_score.c` with a looser metric, and sample their matches by hand.
5. Lawyer review of the header-compaction history and the README note.
6. Archive the Cleanroom transcripts and workspaces (`~/RaBbLE-Cleanroom/`, 3.9 GB, not version-controlled) somewhere durable. Rerun instructions: `cleanroom/audit-2026-11-02/OVERLAP-REPORT.md`, "Reproduce".

## 7. Addendum 2026-11-06 (S314 to S315): state after W8, W11, R1 and the provenance fixes

The record above is dated 2026-11-02 and predates these changes. Paths below use the post-R1 layout (`sdk/`→`core/`, `app/`→`entities/`).

- **W8** (`319ff18`, `9d2d53d`): `rabble_beam_score.c` rewritten from the spec by a fresh implementer, overlap with Muse 15.4% to 2.6%, gate 5%, 52-vector host test; Meta-coincident UI strings reworded, American spelling (`Dialing`).
- **Meta notice on headers** (`dab3c92`, Mark's ruling b): 12 `firmware/core` headers that follow Muse's shape carry the Meta copyright block. After W11 and the fixes, 11 remain (`rabble_board.h` is new and carries none).
- **W11** (`2f5ba44`): board seam `rabble_board.h` written by a fresh implementer; LVGL moved behind an interim glue.
- **R1** (`d814d3b`): pure move to `core/` and `entities/`; symbol sets identical to the pre-move builds.
- **Fresh scan** (NiBbLE, Opus, `/tmp/rabble-crew/scan2/`): 7.0% verbatim line overlap with Muse `b139b45` (2.6% net of ESP-IDF idioms), derived work substantially rewritten, not a clone.
- **Provenance fixes** (Pocket `aa2c953`):
  - `firmware/NOTICE` rewritten with a "Derived interfaces" list; `firmware/LICENSE-APACHE` added (ESP-IDF text).
  - Meta notice moved to the top of the headers, added to `rabble_mem.h` and `rabble_voice.h`; Muse-shaped comments reworded in `rabble_ui.h`, `rabble_clock_screen.h`, `rabble_board.h`, `rabble_lv_mem.c`.
  - About 67 verbatim captions and log lines reworded in code, tests, specs and vectors (23 captions, about 44 log and reply lines). The specs and vectors in this Grimoire changed strings only; the historic `audit-*/` dirs and section 3 above still quote the originals on purpose.
  - Muse logic in later code: the 0.6/0.2 glow smoothing, copied in `foundling_ui.c` and twice in `rabble_ui.c`, is now one function, `oe_glow_follow` in `open_entity_core.h`, with different constants and shape. The brightness slider in `open_entity_default.c` is split into separate live and store handlers on separate events. Foundling's `apply_brightness` had already become `send_level` in W11.
  - README Provenance section written; its history sentence was corrected to point at `97312a3` (W2) instead of `6c3b78b`.
- **Gitleaks** (2026-11-06): Pocket tree 32 hits, all vendored upstream sample keys (`third_party`, `managed_components`, untracked); Grimoire cleanroom 2 hits, fake token strings in `w3-settings-vectors/token.tsv`. No real secrets. All branches and tags are not yet scanned.
- **Not redone:** no overlap rerun after the string and smoothing rewrites, so section 3's numbers are stale; `open_entity_default.c` still follows Muse's slider split in spirit (low risk, generic LVGL).
- **Still open:** items 3, 5 and 6 of section 6.
