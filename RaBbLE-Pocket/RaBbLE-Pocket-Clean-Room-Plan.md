# RaBbLE-Pocket-Clean-Room-Plan.md

> Replace every Meta-derived (Apache-2.0) file in the Pocket firmware with RaBbLE's own code, written clean room, module by module, until `Meta Platforms` appears nowhere in RaBbLE-Pocket outside fetched or gitignored trees.
> Decided S252 (2026-10-16), Mark: **two-team clean room**. Companion handoff: `log/handoffs/done/HANDOFF-S252-Pocket-Settings-Orientation-Clean-Room.md`.
> Review: the planned independent Opus review hit the session limit; S252 checked the riskiest claims against the code itself (touch wrapper, flush path, build coupling, tainted paths). Re-run an independent review before W0 starts.
> **Status (S268, 2026-10-22): W6 in build.** Spec `cleanroom/w6-board.spec.md` (S268, firewall-approved after edits by an independent Opus pass); fresh Sonnet implementer in `~/RaBbLE-Cleanroom/pocket-w6`. CO5300 + ES7210 datasheets sourced; no public CST9217 datasheet exists. Cold start: `log/handoffs/HANDOFF-S268-Pocket-W6-Integrate.md`.
> **Status (S267, 2026-10-22): W5 done and hand-checked (Orbit v2, Pocket `ac2e9f9`). Left: W6 (`bsp/`, 3 files) and W7 close-out**, then the RaBbLE-SDK refactor. Cold start: `log/handoffs/done/HANDOFF-S267-Pocket-CleanRoom-Final-SDK.md` (datasheets, boot-time numbers, W6 spec as Mark's board map, firewall, walkthrough, fresh implementer; W7 list updated to today's tree plus a Sovereign Accord header sweep of 17 files).
> **Status (S266, 2026-10-22): W5 in build.** Mark chose the **Orbit**: Settings redesigned as a round dial drawn natively by nebula_lite (no LVGL in Settings), hold-to-fill toggles, swipe-in with resistance and a snap, rim keyboard for Wi-Fi passwords; the sCoRE URL and token stay serial-only. Spec `cleanroom/w5-orbit.spec.md` (rev 2 after an independent Opus review: 7 blockers fixed). Two fresh Sonnet implementers (Part A renderer, Part B controller) in `~/RaBbLE-Cleanroom/pocket-w5`. Replaces `apache/` settings_ui and keypad; W6 (bsp) next.
> **Status (S264, 2026-10-22): W4 voice and audio done** (Pocket `94d7d0b`, speaker amplifier now gated: the idle hiss is gone). Left in `apache/`: keypad and settings_ui (redesign track, W5); plus `bsp/` (W6). Open from W4: the chirp after idle isn't heard (amplifier settle). See `cleanroom/PROVENANCE.md`.
> **Status (S258, 2026-10-20): W2 power + input done** (axp2101, battery, input; keypad moved to the redesign track). Hand checks pending; see `cleanroom/PROVENANCE.md`. Next: W3 network.
> **Status (S256, 2026-10-17): W0 seam and W1 leaf done** on Pocket branch `cleanroom` (forked from `new-horizons` at `96225b0`, not yet merged or pushed). 16 files replaced; 24 Meta-derived files remain in `apache/`, plus `rabble_axp2101/` and `bsp/`. Record: `cleanroom/PROVENANCE.md`. Specs and golden vectors: `cleanroom/`. Tests: Pocket `firmware/test/cleanroom/`. Integrator spells: `ops/cleanroom-overlap.py`, `ops/cleanroom-audit.py`. Next: W2 power + input. Lessons:
> - Golden vectors generated from the original on the host (behaviour data) made W1 implementations exact on the first run. Do the same for every pure module.
> - Give implementers declaration-only interface extracts for missing modules. Keep `#pragma once` when extracting (`gcc -P` drops it), and give them a scratch dir inside their workspace.
> - One export per wave (`~/RaBbLE-Cleanroom/pocket-wN`). Archive all transcripts to `~/RaBbLE-Cleanroom/transcripts/wN/` and run the audit spell before integrating.
> - Sonnet spec authors drift toward the original's structure (step lists, primitive choices, private names). F has to rewrite those as requirements.
> - The implementer still reproduced private names the spec never gave (training recall, as predicted). The overlap gate caught it, and one "rewrite these lines of yours" round fixed it.
> - The workspace export also needs `firmware/datasheets/*` and `firmware/managed_components/` copied in (both gitignored), and it must leave out `ops/cleanroom-overlap.py`.
> Background: `RaBbLE-Pocket-Muse-SDK-Map.md` (what the SDK is, licensing), `RaBbLE-Pocket-Gadget-Port.md` (how `apache/` and `accord/` came to be).

## Why, and what this is not

The Apache-derived code is legal to keep: Apache-2.0 is permissive and the NOTICE already carries it. The goal is ownership. The gadget should be RaBbLE's own top to bottom, under the Sovereign Accord alone, with no Meta copyright lines, no per-file "changed" notices and no `LICENSE-APACHE` copies for Meta code.

A clean room is the strongest practical way to get there. People who have read the original describe its behaviour; people who never saw it write new code from that description. It is a process for building a clear provenance record. **It is not legal advice.** One residual risk is specific to agents: a model may have seen the public SDK in training. The process limits what an implementer reads in this project; it cannot erase training data. The overlap gate below is the check against accidental reproduction.

## Inventory (S252)

Measured S252 against `firmware/muse-gadget-sdk/esp32` at `b139b45`. "Upstream" counts substantive lines (normalised, over 12 characters, not comments, braces or includes) that occur verbatim anywhere in the SDK. About **3,000 of 4,600 substantive lines (65%)** still match.

| File (under `firmware/`) | Lines | Upstream | Wave |
|---|---|---|---|
| `components/rabble_gadget/apache/rabble_board.h` | 150 | 53% | W0 seam |
| `components/rabble_gadget/apache/rabble_mem.h` | 38 | 20% | W0 seam |
| `components/rabble_gadget/apache/rabble_state.c/.h` | 238 + 87 | 68% | W0 seam |
| `components/rabble_gadget/apache/rabble_app.c` | 87 | 29% | W0 seam |
| `components/rabble_gadget/apache/rabble_board.c` | 112 | 83% | W0 seam |
| `components/rabble_gadget/apache/rabble_lv_mem.c` | 65 | 100% | W0 seam |
| `components/rabble_gadget/apache/rabble_console.c/.h` | 34 + 26 | 60% | W1 leaf |
| `components/rabble_gadget/apache/rabble_adpcm.c/.h` | 78 + 25 | 90% | W1 leaf (IMA ADPCM: implement from the public IMA/DVI spec) |
| `components/rabble_gadget/apache/rabble_text.c/.h` | 254 + 51 | 86% | W1 leaf |
| `components/rabble_gadget/apache/rabble_beam_text.c` | 218 | 89% | W1 leaf |
| `components/rabble_gadget/apache/rabble_setup.c/.h` | 169 + 31 | 36% | W1 leaf |
| `components/rabble_axp2101/` (`.c` + `include/.h`) | 176 + 69 | 83% | W2 power (datasheet in `firmware/datasheets/`) |
| `components/rabble_gadget/apache/rabble_battery.c/.h` | 522 + 62 | 96% | W2 power |
| `components/rabble_gadget/apache/rabble_input.c/.h` | 590 + 42 | 64% | W2 input |
| `components/rabble_gadget/apache/rabble_keypad.c/.h` | 312 + 27 | 96% | W2 input |
| `components/rabble_gadget/apache/rabble_wifi.c/.h` | 450 + 80 | 45% | W3 network |
| `components/rabble_gadget/apache/rabble_wifi_known.c/.h` | 327 + 55 | 78% | W3 network |
| `components/rabble_gadget/apache/rabble_wifi_mgr.c/.h` | 599 + 69 | 94% | W3 network |
| `components/rabble_gadget/apache/rabble_settings.c/.h` | 267 + 75 | 49% | W3 network (NVS settings) |
| `components/rabble_gadget/apache/rabble_beam.c/.h`, `rabble_beam_priv.h` | 81 + 124 + 39 | 33% | W3 network |
| `components/rabble_gadget/apache/rabble_audio.c/.h` | 318 + 52 | 70% | W4 voice |
| `components/rabble_gadget/apache/rabble_voice.c/.h` | 913 + 40 | 61% | W4 voice |
| `components/rabble_gadget/apache/rabble_settings_ui.c/.h` | 1309 + 25 | 74% | W5 UI |
| `bsp/bsp_waveshare_175b.c` | 383 | 45% | W6 display |
| `bsp/rabble_lcd_bands.c/.h` | 478 + 72 | 31% | W6 display (after the settings track lands) |

Already RaBbLE's own and outside the clean room: `components/rabble_gadget/accord/*` (beam client for sCoRE, entity glue, UI, motion, clock screen), `components/nebula_lite/`, `components/rabble_pcf85063/`, `components/rabble_qmi8658/`, `main/`. Never copy the SDK's Jollybot avatar (`esp32/avatar/`) anywhere; it was never Apache.

## Roles

The firewall is made of **what each workspace contains**, not of tool permissions, so it holds for any agent (Claude, Codex, Gemini) and for Mark.

| Role | Sees | Produces | Never does |
|---|---|---|---|
| **Spec author** (S) | everything: the derived files, the SDK, git history | `RaBbLE-Grimoire/RaBbLE-Pocket/cleanroom/<module>.spec.md`: behaviour, states, timings, error cases, the public interface | write code, pseudo-code that mirrors the original's structure, or copied comments, constant tables or identifiers other than public APIs (ESP-IDF, LVGL, chip registers named in datasheets) and the RaBbLE seam names |
| **Firewall reviewer** (F) | the spec and the original | approve, or send back with the passages that carry expression | edit code |
| **Implementer** (I) | the clean workspace only: the spec, `accord/`, `nebula_lite/`, `main/`, the managed components (Espressif, Waveshare, LVGL, all non-Meta), datasheets, ESP-IDF docs, public standards | new files under `accord/` plus a host or on-target test | open `apache/`, `rabble_axp2101/`, `bsp/`, `muse-gadget-sdk/`, `firmware/backups/`, or this repo's git history; read any session log or handoff that quotes the original |
| **Integrator** (G) | everything | swaps the module in, builds, flashes, runs the behaviour checklist, runs the overlap gate, deletes the old file, updates NOTICE, writes the provenance entry | fix implementer code by reading the original; failures go back to I as **behaviour** ("long-press on PWR doesn't power off after 3 s"), never as code |

An agent session that has read any tainted path is S, F or G for the rest of its life, never I. The S252 session (which wrote this plan) is tainted. Implementer sessions start fresh, in the clean workspace, with this table and the spec as their only brief.

## Clean workspace

A plain export, not a clone, so not even git objects of the tainted files reach it:

```bash
# Integrator, once per wave (outside the Collective so nothing tainted is adjacent):
mkdir -p ~/RaBbLE-Cleanroom/pocket && cd ~/RaBbLE-Collective/RaBbLE-Pocket
git archive HEAD firmware sim ops \
  | tar -x -C ~/RaBbLE-Cleanroom/pocket \
      --exclude='firmware/components/rabble_gadget/apache' \
      --exclude='firmware/components/rabble_axp2101' \
      --exclude='firmware/bsp' --exclude='ops/cleanroom-overlap.py'
cp -r firmware/datasheets/* ~/RaBbLE-Cleanroom/pocket/firmware/datasheets/
cp -r firmware/managed_components ~/RaBbLE-Cleanroom/pocket/firmware/
cp ../RaBbLE-Grimoire/RaBbLE-Pocket/cleanroom/<module>.spec.md ~/RaBbLE-Cleanroom/pocket/SPEC.md
cd ~/RaBbLE-Cleanroom/pocket && git init -q && git add -A && git commit -qm "clean room base"
```

The full firmware can't build there: every `accord/` file includes seam headers that live in `apache/` (`rabble_board.h`, `rabble_state.h`, `rabble_mem.h`, `rabble_wifi.h`, `rabble_settings.h`, `rabble_beam.h`, `rabble_beam_priv.h` and others), so **W0's first output is fresh seam headers** written from the W0 spec, and later waves' workspaces include them. Until then each module's spec names a **test vehicle**: a host harness (like `sim/`) for pure logic (ADPCM, text paging, Wi-Fi list ranking), or a minimal ESP-IDF test app under `cleanroom/<module>/test_app/` for drivers. The implementer delivers module plus test; the integrator moves the module into `firmware/components/rabble_gadget/accord/` (drivers into their own `components/rabble_<chip>/`).

Datasheets in `firmware/datasheets/` are public vendor documents and are fine for I. Not on disk yet and needed: CO5300 (panel), CST9217 (touch), ES7210 (mic ADC). Source them from the vendors before W2/W4/W6.

## Contract for every module

1. **Spec** (S, then F): purpose; the public interface as a table (name, arguments, return, threading, which task and core calls it); behaviour as numbered rules and state tables; timings and limits; error and edge cases; what the module may call (ESP-IDF, LVGL, the seam); the behaviour checklist the integrator will run; the test vehicle. Interface names may stay as they are (`rabble_wifi_*` and so on) so `accord/` callers don't change; that is interface, not expression.
2. **Implement** (I): fresh session, clean workspace, the spec and the public sources only. New file headers carry `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` and nothing else.
3. **Integrate** (G): swap in, build, flash, behaviour checklist on the gadget, overlap gate, delete the old file **in the same commit**, NOTICE updated. The same commit is required, not tidy: `components/rabble_gadget/CMakeLists.txt` compiles `SRC_DIRS "apache" "accord"` with both as include dirs, so an old and a new `rabble_wifi.h` side by side collide. Keep `WHOLE_ARCHIVE` while `rabble_lv_mem.c`'s replacement provides symbols only LVGL references.
4. **Overlap gate**: the S252 line-overlap measure, run by G only (it reads the SDK). Target: under 5% of substantive lines match upstream, and every match reviewed and judged unavoidable (an ESP-IDF call sequence, a register name). Anything else goes back to I as "rewrite these lines' behaviour your own way", without showing the original. The script belongs in `RaBbLE-Pocket/ops/cleanroom-overlap.py` (G writes it in W0, from the S252 one-off; it is integrator-only tooling).
5. **Provenance**: one row per module in `RaBbLE-Grimoire/RaBbLE-Pocket/cleanroom/PROVENANCE.md`: spec path and commit, spec author session, firewall reviewer session, implementer session id and agent/model, inputs the implementer was given, overlap result, Pocket commit that swapped it in.

## Hybrid strategy (S256, Mark, 2026-10-20)

Mark: "I'm not against Apache 2.0 code, I just want to minimize how much I have and make more of my files have RaBbLE SA copyright... the SDK felt like a good foundation. Learning and tweaking as I go." The goal is therefore **no Apache-2.0 files vendored in the repo**. Permissive code is fine as **managed components** (fetched at build time and covered by the managed-components paragraph in NOTICE, as ESP-IDF, LVGL and the Waveshare board package already are). Every file in the tree carries the RaBbLE Sovereign Accord copyright.

Each remaining module gets one of three treatments:
- **Clean room:** spec, firewall, fresh implementer, as in W0 and W1.
- **Own from source:** written from a datasheet or a public-domain example. It still goes through a spec, because the tainted writers know the original.
- **Redesign:** a new design of Mark's. It needs only the interface contract plus Mark's brief, and no behaviour spec of the original, because the behaviour changes on purpose.

| Module (lines) | Treatment | Notes |
|---|---|---|
| `rabble_axp2101` (245) | own from datasheet | `firmware/datasheets/X-power-AXP2101_SWcharge_V1.0.pdf`. Fallback if it proves costly: XPowersLib (MIT) as a managed component (`cube32esp/xpowerslib`). |
| `battery` (584) | clean room | Charge-curve and power-off behaviour is ours to keep. |
| `input` (632) | clean room | PTT, serial keys, sleep. Checklist needs Mark's hands. |
| `keypad` (339) | **redesign** | Mark plans a round-display, small, thumb-only keypad. Keep the public interface that `settings_ui` calls (or change both together in W5); new layout from Mark's brief. |
| `wifi`, `wifi_known`, `wifi_mgr` (1,580) | clean room | Implementers may use ESP-IDF's public-domain examples (Unlicense/CC0); NVS layout must stay compatible. |
| `settings` (342) | clean room | NVS keys and formats unchanged (saved networks, beam token). |
| `beam` (244) | clean room | |
| `audio` (370), `voice` (953) | clean room | Highest risk; last among the core modules. |
| `settings_ui` (1,334) | **redesign** | Already planned as W5. Pairs with the keypad redesign. |
| `bsp_waveshare_175b.c` (383) | clean room, leaner | Lean on the Waveshare board package and `esp_lcd_co5300` (managed) for panel and touch bring-up; our file keeps only the board table and glue. |
| `rabble_lcd_bands.c/.h` (550) | clean room | Mostly RaBbLE's own performance work already. |

Order stays W2 to W7, with keypad and settings_ui moved into a redesign track Mark can run whenever the design is ready. Mark learns the firmware and tunes as the waves go: each spec is a readable map of the module before it is replaced.

## Waves

Specs for a wave can be written in parallel (Sonnet sub-agents are fine for S; pin `model: "sonnet"` on fan-outs). Implementers of different modules in one wave run in parallel because they write disjoint new files. Integration is serial: one module per commit, the gadget flashed and checked each time.

| Wave | Modules | Depends on | Notes |
|---|---|---|---|
| **W0 seam** | `rabble_board.h`, `rabble_mem.h`, `rabble_state.*`, `rabble_app.c`, `rabble_board.c`, `rabble_lv_mem.c` | the settings track's seam additions (handoff S1) merged first | The seam is what every other module and all of `accord/` compile against. Its spec is the most important document in this plan: it fixes the board vtable, task and core rules, priorities and memory caps that W1 to W6 build on. |
| **W1 leaf** | `console`, `adpcm`, `text`, `beam_text`, `setup` | W0 | Small and pure: good first implementer runs that prove the workflow. |
| **W2 power, input** | `rabble_axp2101`, `battery`, `input`, `keypad` | W0 | AXP2101 from its datasheet. `input` owns PTT, the serial console's `d`/`u`/`c`/`z`/`w`/`>` keys and sleep; its checklist must cover all of them. |
| **W3 network** | `wifi`, `wifi_known`, `wifi_mgr`, `settings`, `beam` | W0, W1 (`text`) | NVS layout is data the user already has on the device: the spec must keep the stored keys and formats, or define a one-time migration. |
| **W4 voice** | `audio`, `voice` | W0, W1 (`adpcm`), W3 (`beam`) | Highest risk. The checklist includes a full turn with the beam live and the frame-rate gates from the entity work (see the handoff). |
| **W5 UI** | `settings_ui` | W0, W2 (`keypad`), W3 | The largest file and a chance to make the settings page RaBbLE's own design rather than a copy. Coordinate with Mark on layout before implementing. |
| **W6 display** | `bsp_waveshare_175b.c`, `rabble_lcd_bands.c/.h` | the settings track finished (the texture capture is part of this spec) | `rabble_lcd_bands.c` is now mostly RaBbLE's own work (S251/S252) but its file began as Meta's, so it goes through the clean room like the rest. The spec must require that **a frame is never held by a stalled helper core** (S264 freeze fix, see [capture plan T0](RaBbLE-Pocket-Capture-Plan.md#t0--the-face-freeze)). |
| **W7 close-out** | delete `apache/`, the Meta `LICENSE-APACHE` copies (`apache/`, `rabble_axp2101/`, `bsp/`) and the NOTICE section; drop `apache` from the gadget `CMakeLists.txt`; reword the Apache mentions in `firmware/README.md`, `firmware/CONTEXT.md`, `bsp/CMakeLists.txt`, `bsp/idf_component.yml`, `components/rabble_gadget/idf_component.yml` and `.gitignore` (the ADRs in `planning/decisions/` stay as history); update `RaBbLE-Pocket-Gadget-Port.md` and `RaBbLE-Pocket-Muse-SDK-Map.md` | all | Gate below. |

## Done when

- `grep -rn "Meta Platforms" RaBbLE-Pocket --exclude-dir=managed_components --exclude-dir=muse-gadget-sdk --exclude-dir=build --exclude-dir=backups` returns nothing.
- `firmware/NOTICE` lists only third parties that are actually redistributed in the repo (none from Meta), plus the managed-components paragraph.
- Every module has a PROVENANCE row and passed its checklist on the gadget.
- The entity gates from the S252 handoff still hold (60 fps idle, at least 30 fps busy and turning).

## Risks

- **Training-data recall.** The overlap gate catches verbatim recall; review its hits seriously.
- **Behaviour drift.** A spec that misses an edge case ships a regression (sleep, PMU long-press, Wi-Fi retry). Mitigation: checklists written by S from the original's behaviour, run by G on the device, and W4 last among the core modules.
- **Seam churn.** If the settings track or later features change `rabble_board.h` after W0, re-spec the change instead of editing the new seam by eye.
- **NVS compatibility.** W3 must not lose saved Wi-Fi networks or the beam token.
- **Scope creep.** Clean room means same behaviour first. Redesign (W5) is the one planned exception and needs Mark's layout call.
