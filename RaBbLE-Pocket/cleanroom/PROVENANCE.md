# PROVENANCE.md: Pocket clean room

> One row per module swapped in. Process: `../RaBbLE-Pocket-Clean-Room-Plan.md`. Overlap measured with `RaBbLE-Pocket/ops/cleanroom-overlap.py` (integrator only; retired in W7, re-clone the SDK to rerun it) against `third_party/muse-gadget-sdk/esp32` at `b139b45`.
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

## Wave W2: power and input (S258, 2026-10-20)

Workspace: `~/RaBbLE-Cleanroom/pocket-w2`, exported from Pocket `cleanroom` at `10eb34a`, with the specs, the vectors (without their generators) and `cleanroom/interfaces/` (declaration-only extracts: battery, beam, beam_priv, settings, voice, wifi). The vector generators include original code, so they live privately in `~/RaBbLE-Cleanroom/gen/w2-*/`, outside every repo; they regenerate from the originals at Pocket `10eb34a`.

| Module | Spec (S) | Firewall (F) | Implementer (I) | Overlap after | Pocket commit |
|---|---|---|---|---|---|
| `rabble_axp2101` (`.c`, `.h`, `CMakeLists.txt`) | `w2-axp2101.spec.md`, Sonnet 5.5 sub-agent. Treatment: own from datasheet (register end states with datasheet references) | S258 parent (Opus 5.5): removed a private constant name, an internal shorthand, per-call transaction counts, a first-read ordering hint and a log behaviour of the original | fresh Sonnet 5.5 sub-agent; inputs: spec, public AXP2101 datasheet, ESP-IDF `i2c_master` | `.c` 21.8% (31/142): ESP-IDF error-check idioms (`if (err != ESP_OK)` ×9 and the like), the `i2c_device_config_t` initialiser, datasheet register addresses. `.h` 29%: interface fields | `97312a3` |
| `rabble_battery.c/.h` | `w2-battery.spec.md` + `w2-battery-vectors/`, Sonnet 5.5 sub-agent. Found that the module is a bench power meter, not a charge curve (percent lives in the AXP2101 gauge, power-off in input) | S258 parent: rewrote buffer layout, accounting bookkeeping, locking primitives and dump-buffer mechanics as requirements; removed a note about the original | fresh Sonnet 5.5 sub-agent, one rework round | first pass 11.7%, with private-looking names (helper names, a lock-count macro, a mode-array name). Sent back as "rewrite these lines of yours". After: 9.2% (37/401), all spec-given log strings, the reset-reason table the spec fixes, and one-token idioms | `1d0812e` |
| `rabble_input.c/.h` | `w2-input.spec.md` + `w2-input-vectors/`, Sonnet 5.5 sub-agent | S258 parent: rewrote edge-ordering step lists and the aux-button state variables as behaviour; removed a note on the original's internals and a verbatim call expression | fresh Sonnet 5.5 sub-agent, one rework round | first pass 10.8%, with recalled private names (chat-buffer state, task-function and constant names). After the rework: 4.9% (19/384), spec log strings and idioms | `87841bc` |

**Gate judgment (W2):** after the rework rounds every remaining hit is an API-forced call, an exact string the spec requires, or a one-token idiom. The AXP2101 is above 5% only through ESP-IDF error-check idioms and datasheet register addresses. Accepted.

**Transcript audit (W2):** `ops/cleanroom-audit.py` over the three implementers (11 + 28 + 30 tool calls). AXP2101: 6 flagged, all false positives: the regex matches the module's own new directory name `rabble_axp2101` inside the workspace, and one read of the harness's saved copy of the implementer's own brief. Battery and input: 0 flagged. Transcripts: `~/RaBbLE-Cleanroom/transcripts/w2/`. Follow-up: teach the audit to ignore taint words inside the workspace path.

**On the gadget (serial, USB power):**
- Clean builds, no warnings from these files. `rabble_axp2101: ready (key irqs on)`. Heap after the three swaps: internal 123,531 after the UI build and 33,539 at ready (pre-W2: 124,023 and 34,191; about 0.5 KB less).
- `@status`: battery 32 to 38%, USB and charging true, Wi-Fi connected.
- Battery meter: `>nap` starts a measurement (`on battery at 35% (3940 mV): measuring`), `@power` shows live profiling and locks, `w` stops it (`USB back after 25 s ...`), and the record survived the next reset as `@power.saved`.
- Input: `>imu`, `>face=` (incl. the exact error line), `z`/`z`/`w` (the second `z` silent), `d`/`u` with a full voice turn through the beam (reply after 2.46 s), `>chatty` falls through to setup, `>chat+=` ack with 6 bytes, `>nap` ladder (`display paused (USB host: CPU at full speed)`, `Wi-Fi napping`, then `full power`, `Wi-Fi waking`).
- 60.1 fps idle once settled; 36 to 46 fps during voice and nap transitions.

**Hands (Mark, S258, logged over serial):** BOOT tap and a 2.7 s hold (3.08 s recording, reply 1.47 s); BOOT press while asleep wakes on the first press (`waking (boot)`, `PTT down (waking)`); 17 PWR click-sleep / press-wake cycles with no misses or doubles; PWR hold powered off (`shutting down`, supply cut) and a PWR click powered on, five times, `rabble_axp2101: ready` each boot; heap at ready 34,355 to 34,543 internal; touch wake goes through state, unlogged, as specified. On the screen, confirmed by Mark ("it all seemed to function properly"): the `HOLD TO POWER OFF` hint, `GOODBYE!`, and a cancelled hold restoring the caption. Observed: a wake tap on BOOT still records about 0.3 s and sends a turn; input posts the correct `wake` event, so this is the voice module's (original code, W4) handling.

**Still not done:** settings-page power off, on-battery auto-sleep and timed power-off, real low-power pause and the 2-minute Wi-Fi nap, raise/shake wake, and the 11-minute drain and 35-minute warm-reset battery runs. ASan/UBSan: runtimes now in the manifest, waiting on `layerctl apply esp-idf`.

**Spec notes found by W2:** `rabble_battery` has no charge curve (the plan's description was wrong; see the battery spec section 0). The PWR power-off hold is about 1.5 s in loop passes, not 3 s; Mark keeps it (S258). The serial keys `d`/`u` don't wake the screen; Mark keeps that too.

## Wave W3: network (S259, 2026-10-20)

Workspace: `~/RaBbLE-Cleanroom/pocket-w3`, exported from Pocket `cleanroom` at `0415780`. It held the four specs, their vectors (READMEs stripped of the generator notes) and `cleanroom/interfaces/` (declaration-only extracts of settings, wifi and voice; an implementer never opened the extract of the module it was writing). Vector generators run original code and live privately in `~/RaBbLE-Cleanroom/gen/w3-*/`. The spec authors worked from a shared brief, `~/RaBbLE-Cleanroom/gen/W3-SPEC-AUTHOR-BRIEF.md` (also private). The radio spec author hit a session limit partway and was resumed with its context.

| Module | Spec (S) | Firewall (F) | Implementer (I) | Overlap after | Pocket commit |
|---|---|---|---|---|---|
| `rabble_beam.c`, `rabble_beam.h`, `rabble_beam_priv.h` (status side; the session task and text helpers were already RaBbLE's own) | `w3-beam.spec.md` + `w3-beam-vectors/` (204 status rows), Sonnet 5.5 sub-agent | S259 parent (Opus 5.5): removed the original's synchronisation primitive and copy idiom; kept the status decision table, which for a 60-line module is the behaviour | fresh Sonnet 5.5 sub-agent | `.c` 15.3% (9/59): FreeRTOS critical-section calls and a `switch`; headers: fixed declarations and guards | `b3a4354` |
| `rabble_wifi_known.c/.h` (saved-network store) | `w3-wifi-store.spec.md` + `w3-wifi-store-vectors/` (134 scenarios, 239 rows), Sonnet 5.5 sub-agent | S259 parent: replaced working-buffer sizes with a stack budget, dropped a caller's stack detail and a remark naming the original's log tag, corrected `wifi_channel` (no current writer: legacy, erased only) | fresh Sonnet 5.5 sub-agent | 13.8% (30/217): spec log strings, NVS open/close and lock idioms, `return false` | `2edd269` |
| `rabble_settings.c/.h` | `w3-settings.spec.md` + `w3-settings-vectors/` (211 rows), Sonnet 5.5 sub-agent | S259 parent: rewrote the init order and token append as requirements, removed a suggested log line close to the original's format and a locking design note | fresh Sonnet 5.5 sub-agent, one rework round | first pass 11.8% with recalled private names (a clamp helper's name and body, a save helper's signature, the handle and open-flag names). Sent back as "rewrite these lines of yours". After: 9.9% (17/171), the ESP-IDF NVS bring-up idiom (as in ESP-IDF's examples), lock calls and a flag name | `cb7cb71` |
| `rabble_wifi.c/.h` + `rabble_wifi_air.c/.h`, `rabble_wifi_priv.h`, `rabble_wifi_radio.c` (replace `rabble_wifi` and `rabble_wifi_mgr`) | `w3-wifi.spec.md` + `w3-wifi-vectors/` (20 station scenarios, 453 rows; 35 radio table rows), Sonnet 5.5 sub-agent | S259 parent: rewrote the start-up call sequence and the keeper pass step list as requirements, removed the radio teardown retry mechanics and a working-buffer size, freed the radio-layer log tags, dropped the unused scan-merge facility and the dead channel hint | fresh Sonnet 5.5 sub-agent; one round for the full build's `-Werror=stringop-truncation` (its own lines, passed back as compiler output) | keeper 7.5% (23/306, spec log strings and idioms), pure rules 2.2%, header 20.5% (interface), ESP-IDF side 18.2% (the station bring-up sequence of ESP-IDF's public-domain examples, event IDs, scan config initialisers) | `3d389f0` |

**Gate judgment (W3):** no remaining hit is a private name or a body the spec never gave. The ESP-IDF side of the radio is above 5% only through the canonical station bring-up calls, which the plan allows (ESP-IDF examples are Unlicense/CC0). Accepted.

**Transcript audit (W3):** `ops/cleanroom-audit.py` over the four implementers (beam 16, store 15, settings 17, radio 23 tool calls): 0 flagged. One implementer's report mentioned `apache/rabble_wifi_known.c`; that came from the spec's "file to be replaced" line, not from a read. Transcripts, including the four spec authors': `~/RaBbLE-Cleanroom/transcripts/w3/`.

**On the gadget (serial, USB power):**
- Clean builds after each swap; 60 fps idle, 45 to 50 during nap transitions.
- Beam: `Connected`; a URL change to a dead port gives `Can't connect` (also after `beam.test`); an empty URL restores the default and reconnects; typed chat turns complete.
- Settings: stored voice, token and Wi-Fi switch survive the swap; volume 35 and brightness 40 persist across a reset (restored afterwards).
- Store and radio: the three saved networks load and the first joins at boot (IP at 6.9 s, as before); Wi-Fi off (`wifi off; disconnecting`, beam Offline) and on (rejoined in 4.4 s); a made-up typed network fails, is retried as hidden, and the station falls back to RaBbLE; forgetting it leaves the link up; nap leaves Wi-Fi and wake rejoins in 3.4 s.
- NVS before and after (private dumps `~/RaBbLE-Cleanroom/nvs-{pre,post}-w3.bin`): saved networks, their order, passwords and the beam token are byte-identical after the join, forget and reorder churn. The only new key is `bright` (100) from the persistence test.

**Still not done (needs hands or a bench):** settings-page scan, pick and join; a wrong password on a real network; out of range (NOT_NEARBY schedule); router reboot; DOZE/REST current; eight-plus networks; heap at ready (boot lines go out before USB serial re-enumerates).

**Spec notes found by W3:**
- `wifi_channel` and the channel hint are dead: nothing in RaBbLE writes or reads them; the store erases the key as legacy data.
- The scan-merge facility was never called; settings scans and the nearby memory replace on each scan.
- Behaviour kept for the same-behaviour-first rule, worth a later look (Mark's call): `beam.test` while already connected can stay on `Connecting...` (a fix belongs in `rabble_beam_score.c`); if saving a joined network fails, the station joins whatever is first instead; settings setters always write and notify, even unchanged; stored sleep/power-off are not clamped on load.
- The new radio has no driver-level auto-reconnect racing the keeper (the original had one); the keeper's schedule is the only reconnect policy.

## Wave W4: voice and audio (S264, 2026-10-22)

Workspace: `~/RaBbLE-Cleanroom/pocket-w4`, exported from Pocket `cleanroom` at `6f2c414` without `apache/`, `bsp/`, `rabble_axp2101/`, the overlap and audit spells and `firmware/CONTEXT.md`. It held both specs, their vectors (generator notes moved to a private integrator note), the already-clean companion specs (W0 seam and state, W1 adpcm, W2 input, W3 beam and settings), the public beam protocol, and `cleanroom/interfaces/rabble_audio.h` (declaration-only, its comments stripped) for the voice implementer's compile checks; the audio implementer never opened it. Spec authors shared `~/RaBbLE-Cleanroom/gen/W4-SPEC-AUTHOR-BRIEF.md` (private). Generators run original code and live privately in `~/RaBbLE-Cleanroom/gen/w4-*/`.

| Module | Spec (S) | Firewall (F) | Implementer (I) | Overlap after | Pocket commit |
|---|---|---|---|---|---|
| `rabble_audio.c/.h` | `w4-audio.spec.md` + `w4-audio-vectors/` (metrics 18, read 14, write 5, chirp 4, lifecycle 79 rows in 10 scenarios, self-test and loopback logs), Sonnet 5.5 sub-agent. Integrator addition mid-spec: the speaker amplifier on only while something plays (Mark's idle-hiss report) | S264 parent (Opus 5.5): power transitions as an outcome (no bus error text) instead of the original's log-level mechanism; the loopback test loosened to its observable results (values advisory within 1 dB); open questions turned into decisions (high-pass reset at power-on, setters clamp, 500 ms hold, zeros while active extend it); the gating grounded in the public `esp_codec_dev` ES8311 driver (the amplifier follows device open/close; mute alone leaves it on) and a gadget bench (mic reads run at 16 kHz with the speaker device closed). Later amendment: deactivation in the caller's task, not a timer task (I2C on a shared bus) | fresh Sonnet 5.5 sub-agent; two rounds: the amplifier close moved off `esp_timer` into the next read/write; then "rewrite these lines of yours" for three names (a slot-count macro and both codec handles) | first pass 11.2% (34/304) vs the SDK; after 8.8% (27/306): spec log strings, `esp_codec_dev` setup initialisers, generic loops and returns | `94d7d0b` |
| `rabble_voice.c/.h` | `w4-voice.spec.md` + `w4-voice-vectors/` (47 scenarios, 44 psram / 7 no-psram; turns 763, captions 959, side 406, probes 38, minlen 42), Sonnet 5.5 sub-agent | S264 parent: accepted the idle-pass and press orders (observable, pinned by the vectors); replaced a named FreeRTOS creation call with the placement requirement it served (stack in `RABBLE_BIG_CAPS`); settled section 14 against the audio spec; open questions turned into integrator decisions | fresh Sonnet 5.5 sub-agent; one round: "rewrite these lines of yours" for recalled private names (two chunk-count macros, five statics, two helpers and one helper's body order, three struct fields, one local) | first pass 11.5% vs the SDK, 23.8% vs the original (mostly seam calls and spec strings); after 6.5% (32/496) vs the SDK: seam calls, spec captions and log lines, public build macros, idioms | `94d7d0b` |

**Gate judgment (W4):** no remaining hit is a private name or a body the spec never gave. Accepted.

**Transcript audit (W4):** `ops/cleanroom-audit.py` over both implementers (audio 36, voice 38 tool calls): 0 flagged. Transcripts, including both spec authors': `~/RaBbLE-Cleanroom/transcripts/w4/`.

**On the gadget (S264):** boot `audio ready` and self-test (mics about -61 dBFS, corr 0.93, capture 16158 Hz; playback 15673 Hz, which at rest is timer-paced, not codec-paced: speaker-off reply captions run ~2% slow), no `i2s_common` error text, three chirps without errors, `>nap` rest and wake (`resting: codecs off, Wi-Fi modem sleep` / `awake: codecs on`), 60 fps idle. **Hands (Mark):** the idle hiss is gone; barge-in works; a short press shows `HOLD LONGER TO TALK`.

**Round 2 (W4 audio, S264):** behaviour sent back to I: "a sound that activates the output from rest must be fully audible from its first sample". I added a 150 ms silent lead-in at activation (named constant; never extends the hold; none when already active); tests updated, overlap 8.8%; Pocket `6eb79d9`. On the gadget, shake chirps fire again (after the shake detector fix, `057c8f6`).

**Open (W4, before round 2):** the chirp after idle was not heard: with the amplifier gated, a 90 ms sound likely ends before the amplifier settles. Next round to I as behaviour: "a cue or chirp after idle must be fully audible" (a settle lead-in at activation longer than the 20 ms the spec allowed). Also check the falling cue after release and the first syllable of a reply. Still to run: a full turn with pre-roll checked in the transcript, speaker off, the offline note path, the 15 s limit, the fps gates while listening and speaking.

## Wave W5: the Orbit (S266, 2026-10-22), redesign

Workspace: `~/RaBbLE-Cleanroom/pocket-w5`, exported from Pocket `cleanroom` at `92c8adf` (no `apache/`, `bsp/`, `rabble_axp2101/`, SDK, overlap script or history). Spec `w5-orbit.spec.md` rev 2: written by the S266 parent session (Opus 5.5) from Mark's design calls; the author never read `apache/rabble_settings_ui.*` or `apache/rabble_keypad.*` beyond their header comments (S266 did grep-read a few board lines in `bsp/` for the gyro and the panel's stats log, so it stays out of W6 as an implementer). An independent Opus 5.5 reviewer (accord/, nebula_lite/, sim/, test/, ops/ and Grimoire only) found 7 blockers; all folded into rev 2. No firewall pass: a new design, nothing taken from the originals.

| Module | Spec (S) | Firewall (F) | Implementer (I) | Inputs given to I | Overlap after | Pocket commit |
|---|---|---|---|---|---|---|
| nebula_lite orbit renderer: `orbit.c`, `NL_P_ARC`, sprite sampler quarter turns, x-culling, ring over the orbit (Part A) | `w5-orbit.spec.md` Part A, S266 parent | none needed (redesign, originals unread) | fresh Sonnet 5.5 sub-agent | the spec, BRIEF, clean workspace, ESP-IDF, managed components | `orbit.c` 1.0% (1/105), `raster.c` 0.8%, `scene.c` 0.4%: idioms | `47adbb9` |
| `rabble_orbit_logic.c/.h`, `rabble_orbit.c/.h`, `rabble_a8.c/.h`, changes to `rabble_ui`, `rabble_entity`, `rabble_input`, `rabble_wifi` (`join_saved`) (Part B) | `w5-orbit.spec.md` Part B, S266 parent | none needed | fresh Sonnet 5.5 sub-agent | the same, plus the W3 Wi-Fi spec | `orbit_logic.c` 2.5% (32/1268), `orbit.c` 3.9%, `a8.c` 5.1% (3/59), headers up to 20% (2/10: `#ifdef __cplusplus`, `return false;`); `rabble_ui.c` 12.3%, down from its accepted 13.9% baseline. Total 4.2% (193/4632). Every hit reviewed: one-token idioms (`typedef struct {`, loops, `return false;`, `fflush(stdout)`, `lv_indev_wait_release(...)`) | `47adbb9` |

**Deleted in the swap commit:** `apache/rabble_settings_ui.c/.h`, `apache/rabble_keypad.c/.h`, `apache/LICENSE-APACHE` (the directory is gone); `firmware/NOTICE` now lists only `bsp/` as Apache-derived.

**Transcript audit (W5):** 58 + 76 tool calls. One flag: Part B editing the workspace's own `CMakeLists.txt`, whose comment names the `apache/` folder it removed from the build list (benign). Part A's two scratchpad uses were crops of its own PNGs. Archived in `~/RaBbLE-Cleanroom/transcripts/w5/`.

**Tests:** host `sim/build.sh` (orbit scenes, sampler exact paths 0 mismatches, repeat-frame hashes 30/30 bands), `firmware/test/cleanroom/w5/orbit_test/run.sh` (426 logic checks, 11 join_saved checks, Xtensa -O2 -Werror compile of every changed file). Full firmware build clean.

**On the gadget:** boots, Orbit up (internal free 104,859); Home 60 fps idle and while turning (render ~0.3 ms/frame). Mark's first hand check: "a good first step"; v2 asks (S266): keep the NN mesh through the transition (part of it), an obvious way back, fewer taps for simple things, more text guidance and clearer input signals; he got stuck in brightness value mode (no visible exit). W5 v2 follows on RaBbLE's own code (the originals were never involved).

## Wave W6: the board layer (S268-S270 revision 1, parked; S277 revision 2), clean room

Revision 1 (S268-S270): spec `w6-board.spec.md` by S268 (Opus 5.5), firewall S268 F (Opus 5.5 sub-agent); five Sonnet 5.5 implementer rounds in `~/RaBbLE-Cleanroom/pocket-w6`. Board table and bring-up passed; the band engine tore and crashed. Parked on Pocket `w6-integration-wip` (`a3b436e`); spec section 13 records the results as behaviour.

Revision 2 (S277, 2026-10-24; Pocket commits tagged `%S276_W6R2%`, the number was taken by a concurrent session): workspace `~/RaBbLE-Cleanroom/pocket-w6r2`, a plain export of Pocket `new-horizons` `6d26a76` without `bsp/` and the overlap script, plus revision 1's clean board table, bring-up, texture and `>perf` files (round 3 = round 5 for those) and the pinned `dependencies.lock`. Spec rev 2 rewrites 6.3/6.4 from section 13.

| Module | Spec (S) | Firewall (F) | Implementer (I) | Inputs given to I | Overlap after | Pocket commit |
|---|---|---|---|---|---|---|
| `bsp/bsp_bands.c`, `bsp_frame.c/.h` (band engine, new), `bsp_waveshare_175b.c`, `bsp_display.c/.h`, `bsp_texture.c`, `bsp_perf.h` (rev 1, kept; texture arrays moved to PSRAM), `test/cleanroom/w6/band_test/` | `w6-board.spec.md` rev 2, S277 parent (Opus 5.5; read the old direct-frame path) | S277 F (Opus 5.5 sub-agent): approved with changes, all applied (6.4.8's FreeRTOS claim corrected, steady-30 edge counting, no-TE resting floor, edge-to-band-0 timing, 6.6 on the direct path, RAM measurement) | fresh **Opus 5.5** sub-agent, one round + one overlap rework | the spec, BRIEF, SEAM-SPEC, clean workspace, ESP-IDF, managed components, datasheets | 10.5% (103/984); band engine `bsp_bands.c` 7.0%, `bsp_frame.c` 1.6%; `bsp_display.c` 22.7% and `bsp_waveshare_175b.c` 16.6%: the vendor's public CO5300 init commands, adapter config fields, ESP-IDF error idioms, spec values (touch reset timing, 33 dB gain rule) and the seam table. First run 11.4% with the original's private names for the send-task call objects and the PMU flag: sent back as "rewrite in your own way", fixed | `2965c39` + `6c3b78b`, fast-forwarded into `new-horizons` (S277) |

**Deleted in the swap commit:** `bsp/rabble_lcd_bands.c/.h`, the old `bsp/bsp_waveshare_175b.c`, `bsp/LICENSE-APACHE`. `firmware/NOTICE` now lists no derived code: the firmware is RaBbLE's own throughout.

**Transcript audit (W6 rev 2):** implementer 55 tool calls, 3 flagged, all the workspace's own `firmware/bsp` path (benign). Firewall and implementer transcripts archived in `~/RaBbLE-Cleanroom/transcripts/w6r2/` (on disk only, Mark S277).

**On the gadget (S277):** display up 403 ms (panel 295), app ready 3.2 s (old layer 4.3 s); idle face 594-600 frames per 10 s; steady 30 under voice-turn load with 4 stalled-helper rescues and no freeze; free internal heap at boot 13,207 (old layer 13,315, three boots each); stacks unused: send 4,980 B, helper 1,724 B; no crash or assert through voice turns, a voice note and sleep/wake cycles. Mark, cursory hand check: "feels great". Merged on Mark's call before the full 18a soak and the Orbit-slide side-by-side; those stay open as watch items. The Muse Gadget SDK copy was deleted after the merge (re-clone to rerun the overlap gate).

## Wave W7: close-out (2026-10-25)

Mechanical, no behaviour change. Pocket working tree on `new-horizons`, written by the CoBbLE organ for review.

| Item | Result |
|---|---|
| `bsp/LICENSE-APACHE`, the Apache section of `firmware/NOTICE` | Gone since W6 (`6c3b78b`). `firmware/NOTICE` states that all code is RaBbLE's own and keeps the managed-components paragraph |
| Reference SDK | `third_party/muse-gadget-sdk` deleted S277 (`227f503`); noted in `third_party/README.md` and `.gitignore` |
| Copyright header sweep | 154 tracked files gained `Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord.` as the first comment line: nebula_lite 10, rabble_gadget 7, pcf85063 3, qmi8658 1, main 2, panel_bench 3, firmware build/config 3, `test/cleanroom` 95, `test/outbox_test` 1, `hardware/cad` 15, `ops` 3, `sim` 5, root `.gitignore` 1, `planning/mock` 1 (HTML comment after the doctype), three `partitions.csv` (`#` comment; the generated table is byte-identical), `w2/input_test/.gitignore` 1 (new). Skipped: images, CAD binaries, symlinks, `third_party/`, `planning/decisions/` (history), files that already had the line, and Markdown. `test/cleanroom/w2/input_test/build/` (a committed build output that `run.sh` overwrites) is untracked and git-ignored instead |
| Wording | `firmware/CONTEXT.md`, `firmware/README.md`, `firmware/components/rabble_gadget/idf_component.yml`, `firmware/sdk/rabble_core/idf_component.yml` and `AGENT.md` describe the code as RaBbLE's own. The `.gitignore` comment keeps the one history note (SDK deleted S277, re-clone to rerun the gate) |
| Test paths | Six scripts under `firmware/test/cleanroom/` pointed at the deleted `components/rabble_gadget/apache`; they now read `accord/` (`w1/console_setup_test/gen_ifc.sh`, `w2/input_test/{compile_check,run}.sh`, `w3/beam_test/run.sh`, `w3/wifi_test/compile_check.sh`) |
| `ops/cleanroom-overlap.py` | Retired: exits early with a message unless the reference SDK is present. The logic stays for a future clean room; `ops/cleanroom-audit.py` is unchanged |
| Gate | `grep -rn "Meta Platforms"` over the repo (minus `managed_components`, `third_party`, `build`) is empty. Tracked files: only the history row in `third_party/README.md`. NOTICE lists no redistributed third party |

**Every formerly derived module has a row above** (W0 to W6): state, board seam and memory, text, adpcm, console, setup, axp2101, battery, input, beam status side, wifi store, settings, wifi (radio, air, priv), audio, voice, the Orbit settings UI (replaced by a redesign), keypad (retired), the board layer in `bsp/`.

### RaBbLE's own from the start

These modules never had a derived ancestor, so they have no wave row. Evidence is the first commit (`git log --diff-filter=A --follow`) and, for the S243 gadget commit, the layout table in [Gadget-Port](../RaBbLE-Pocket-Gadget-Port.md) and the `firmware/NOTICE` of that commit, which listed only `apache/`, `rabble_axp2101/` and `bsp/` as derived. The SDK copy is deleted, so there is no fresh diff against it; the claim rests on the history.

| Module | First commit | Note |
|---|---|---|
| `rabble_entity.c/.h` | `f4156ae` 2026-10-15 (S251) | entity on nebula_lite; changed again in W5 Part B |
| `entity_face.c/.h` | `12f7799` 2026-08-08 | v1 firmware, two months before the SDK study |
| `rabble_clock_screen.c/.h`, `rabble_level_screen.c/.h` | `12f7799` 2026-08-08 (`.c`), `42ae6d9` 2026-10-06 (`.h`); level screen `51c110a` 2026-10-22 | screens |
| `rabble_ui.c/.h`, `ui_theme.h`, `rabble_palette.h`, `lv_hook/rabble_lv_assert.h` | `42ae6d9` 2026-10-06 (S243) | "Accord only" in the Gadget-Port layout. `rabble_ui.c` carries an accepted overlap baseline of 13.9% (12.3% after W5), generic LVGL idioms, reviewed at W5 |
| `rabble_beam_score.c` | `42ae6d9` 2026-10-06 | sCoRE session; the W3 beam row records that the session task and text helpers were already RaBbLE's own |
| `rabble_motion.c/.h`, `components/rabble_qmi8658` | `21eb8c8` 2026-10-06 (S243) | IMU driver "own driver" per Gadget-Port |
| `components/rabble_pcf85063` | `12f7799` 2026-08-08 | RTC |
| `main/app_main.c` | `12f7799` 2026-08-08 | edited since (`bsp_perf.h` include etc.) |
| `components/nebula_lite` (`scene.c`, `raster*.c`, `compose.c`, `luts.c`, `simd_*`, `nl_*.h`, `nebula_lite.h`) | `5f775ae` 2026-10-15 (S250), SIMD `9fbdee2` (S251) | `orbit.c` was written in W5 from a spec (row above) |
| `rabble_capture.c/.h` | `678e335` 2026-10-22 (S265) | Converse and Capture |
| `rabble_notes.c/.h`, `rabble_notes_console.c/.h` | `4529039`, `60e1c9a` 2026-10-22 (S265) | notes store |
| `rabble_outbox.c/.h` | `c698884` 2026-10-23 | offline voice notes |
| `rabble_pomo.c/.h` | `6fcd739` 2026-10-22 | Pomodoro applet |
| `rabble_time.c/.h` (`sdk/rabble_core`) | `90e8926` 2026-10-16 (S254) | clock from sCoRE, zones |
| `panel_bench/` | `a77437a` 2026-10-15 (S250) | Phase 0 QSPI bench. Own code, but the CO5300 register init values were taken from the Waveshare BSP (Apache-2.0); functional data, the same accepted overlap as the W6 `bsp/` |

Not examined in this table: `sim/`, `ops/`, `hardware/` and `companion-app/` (outside `firmware/components`, none ever listed as derived).

**Stale seam build found at W7 (fixed):** the cached seam project `firmware/test/cleanroom/w0/seam_test/idfproj/build/config/sdkconfig.h` dated from Oct 16 and lacked `CONFIG_ESP_TLS_CLIENT_SESSION_TICKETS`, added later in `firmware/sdkconfig.defaults`, so `w3/wifi_test/compile_check.sh` failed on undeclared `ESP_TRANSPORT_SESSION_TICKET_*`. The scripts reconfigured only when `sdkconfig.h` was missing; all ten now also reconfigure when `sdkconfig.defaults` is newer. On a fresh seam build `wifi_test/compile_check.sh` passes, and the `esp_littlefs.h` errors in the seam and beam Xtensa steps went away too.

**Known stale checks after W7 (unrelated to the path fix, left as they are):** `w0/seam_test/run.sh` and `w3/beam_test/run.sh` (Xtensa step lacks the `bsp/` include path for `main/app_main.c`: `bsp_perf.h`), `w2/input_test/run.sh` (host step lacks `nebula_lite/include`), `w2/battery_test/run.sh` (LeakSanitizer reports and one persist scenario differs). All other scripts pass.
