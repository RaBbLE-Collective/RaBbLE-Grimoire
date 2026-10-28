# Pocket Release, Entity-Transplant and Desktop Companion: Plan

```
spark ~ pocket/release >> releasable firmware, Entity-transplant, desktop installer, dad's WillowClone first // %S286_RELEASE%
```

> **Document type:** Grimoire plan · v0.2 (2026-10-28), Opus-reviewed once (findings folded in; items marked *[reviewer]* are cited by the reviewer and not yet re-checked by me in the code)
> **Asked by Mark:** make Pocket firmware releasable; install on Windows, macOS (and Linux) through a companion app; let users customise the entity; ship an **Open Entity** (two circles, one palette) under a source-available Sovereign Accord while the RaBbLE entity and brand stay under a more restricted rights-reserved Accord; let end users author custom vector expressions; first real user is Mark's dad (Waveshare 1.75C) who wants **WillowClone**, a dog-faced agent.
> **Decided with Mark (S286):** Tauri desktop app (Windows, macOS, Linux) · declarative vector entities (no code on device) · backend configured per profile in the companion (WillowClone on Muse or sCoRE, undetermined) · first deliverable = Dad's WillowClone on a 1.75C.
> **Vocabulary (Mark, S286):** an entity is **installed**, and the process is an **Entity-transplant**: an entity is transplanted onto a device. There are various **entity types**. RaBbLE is part of sCoRE and the Collective. The Collective may have **forks** (e.g. WillowClone: RaBbLE-OS + RaBbLE-SDK + a transplanted custom entity). "Pack" is retired.
> **Sources:** `RaBbLE-Pocket/RaBbLE-Pocket-SDK-Plan.md` v0.3, `log/plans/Sovereign-Accord-v2-Brand-and-Entity.md`, `RaBbLE-Pocket/RaBbLE-Pocket-Roadmap.md` (EP1), `RaBbLE-Pocket/firmware/app/RaBbLE/scene.c`, `RaBbLE-Pocket-Beam-Protocol.md`, `RaBbLE-Pocket-Muse-SDK-Map.md`.

---

## 1. What exists and what is missing

| Need | Today | Gap |
|---|---|---|
| SDK layering | `app/RaBbLE` on `sdk/` on `boards/` + `drivers/`; gate `ops/sdk-layers.py` | S8-S10 not done; no second app, no second board; `main/CMakeLists.txt:5` and root `CMakeLists.txt:11` hard-code app and 1.75B *[reviewer]* |
| 1.75C | none | board folder **plus** its own `sdkconfig.defaults`, `partitions.csv` (32 MB flash, no RTC) *[reviewer]* |
| Entity | procedural in `scene.c` (820 lines); renderer has 4 primitives | data-driven entity layer, scoped to those 4 primitives |
| Licence | v1 Accord; v2 parked; fork rules deferred | three-tier split below, then a lawyer |
| Installer | `ops/build-flash.sh` needs ESP-IDF | release image, flasher, app |
| Companion | iOS-only plan, empty | Tauri desktop app |
| Backend | `rabble-beam/0` to sCoRE only | see §2.5: Muse is not a profile |
| OTA / rollback | none; `BOOTLOADER_APP_ROLLBACK_ENABLE` off; BT off | decide before Dad's first image |
| Name | RABBLE filed by others in class 9 | clearance before any public release |

## 2. Architecture

```
RaBbLE-Pocket/
  firmware/
    sdk/            Sovereign Accord (source-available)
      rabble_entity/    NEW: Entity-transplant receiver, validator, store, interpreter (a second scene builder)
    app/
      RaBbLE/           brand app; brand entity stays native (procedural)
      <fork app>/       NEW per §2.4 decision: WillowClone's app
      board_test/       SDK plan S10
    boards/
      rabble_waveshare_175b/
      rabble_waveshare_175c/   NEW
  entities/
    open/           NEW: Open Entity (two circles, one palette). Code tier.
  companion-desktop/  NEW: Tauri (Rust + web UI), Windows + macOS + Linux
```

### 2.1 Licence tiers (from Accord v2)

| Tier | Contents | Terms |
|---|---|---|
| **Code**: Sovereign Accord (source-available, never "open source") | `sdk/`, `boards/`, `drivers/`, test/board apps, entity format spec + validator, companion app, **Open Entity** | read, build, mod, personal use; contributions back; commercial use via a pact |
| **Entity and brand**: Sovereign Accord, Entity and Brand terms (rights reserved) | the RaBbLE entity art and brand app skin, name and marks, brand palette | limited-use licence to run on your own Pocket; no redistribution; no use of name or likeness elsewhere |
| **User entities** | entities users author (WillowClone's dog) | data owned by its author; **running it still inherits code-tier terms** (reviewer); cannot use RaBbLE marks or reserved art |

Contradictions and open points the reviewer raised against Accord v2 (all for Mark, then the lawyer):
- **Selling user entities** (my earlier Q2 "yes") pre-empts the deferred Creator/Shop licence. Withdrawn: undecided.
- **A fork like WillowClone** is "personal use" only while private. Where a fork starts (public vs sharing with friends) is an explicitly deferred decision; building it for Dad sits on that line, so log it as Mark's call. If the Collective itself authors **and hosts** WillowClone it is a Collective product, not a third-party fork, and the persona/backend rules in §2.5 apply.
- **Open Entity = the "neutral fork-face preset"**, also deferred, and two circles may fail the planned overall-impression test against the face design mark. Lawyer item, not settled.
- **"Contributions back" cannot operate yet**: no Contributor Agreement exists, so no outside contributions.
- **Brand colours sit in the SDK code tier today** (`nl_list.h:25-31`, `rabble_palette.h`) *[reviewer]*. The Open Entity's palette must not be the Aether palette until "Aether tokens: gifted or reserved" is decided. Moving brand constants to the reserved tier is part of E3.
- **File extension** `.rabble-entity` puts a mark in user-owned data: decide, or use a neutral extension.

No legal advice here; text goes to a lawyer.

### 2.2 Entity format (declarative, validated, no code on device)

**File types (Mark, S286):** **`.rbl`** is the general RaBbLE container used throughout the Collective: it can hold an entity and also other things (persona/config, expressions, themes, notes, later more). **`.rble`** is the entity-specific type. An entity may be delivered as either: a `.rble` is an entity only; a `.rbl` that contains an entity part is also transplantable. The device reads only the entity and persona parts of a `.rbl` and ignores part types it does not know (versioned, skip-by-length). Open for the E0 spec: the container layout (header, part table, per-part type/version/length/CRC, optional signature part), the part-type registry (owned in the Grimoire so the whole Collective shares it), and whether `.rbl` is also the release-image manifest format. Note the extension names carry the RaBbLE mark; the Accord rule on marks in user-owned data (§2.1) still needs a lawyer answer.

Scoped to the renderer's actual primitives *[reviewer: `nl_list.h`]*: filled/hollow/stroked **ellipse** (rotation, half-stroke arc, a 2-slot radial gradient, 2 clip slots), **capsule line**, **annular arc sector**, **A8 sprite**. No polygons, rounded rects, general gradients or path morph. Real paths would be a new raster kernel (out of scope for now). A dog is doable: rotated ellipses for ears and nose, capsule chains for the tail, arcs for the mouth.

- **manifest:** id, name, author, licence, entity type, format version, required SDK version, normalised coordinates (this removes the *entity's* share of the 466 px debt only; the panel, Orbit and renderer stay 466 px, and the 1.75C is the same panel size)
- **palette:** named slots; Open Entity has one palette
- **parts and rig:** primitives with named parameters (`gaze_x/y`, `blink`, `mouth_open`, `ear_l/r`, `tail`) bound to transform, scale, rotate, opacity; "morph" means interpolating ellipse and capsule parameters
- **expressions:** keyframe tracks with easing; a state map from device states and events to expressions
- **limits:** parts, keyframes, bytes, **radii and coverage area** (fps depends on fill area, not just prim count)

**On device, the format is flat binary compiled on the host** (JSON only on the host), loaded into PSRAM (`NL_EXT_BSS`) with fixed tables and no per-node mallocs *[reviewer]*: `SPIRAM_MALLOC_ALWAYSINTERNAL=4096` sends small allocations to internal RAM, which has about 12.3 KB free and already costs voice notes (B-22). Gate: internal-heap delta 0, or B-22 fixed first.

**Integration, cheapest path** *[reviewer]*: the interpreter is a **second scene builder** behind the `nl_scene.h` seam (`nl_init`/`nl_simulate`); the brand entity stays native. If one firmware must switch entities at runtime, the two `nl_simulate` symbols need a vtable. `face_t` blending in `scene.c:125-139` is the template for expressions. `orbit.c` already tolerates `nl_mesh_n == 0`.

### 2.3 Entity-transplant (receiving untrusted files) *[reviewer: new track E1b]*

- **Receiver:** framed + CRC'd transfer, size cap, offset/count checks against limits, reject NaN/Inf (NaN passes bbox culling into `int16` conversions in `nl_list.h:123`), clamp radii and area.
- **Fuzzing:** libFuzzer on the C parser in `test/`; the companion's JS/WASM interpreter must pass the same fixtures.
- **Storage:** its own quota. The shared LittleFS `storage` has `format_if_mount_failed = true` (`rabble_notes.c:283`), so corruption wipes notes: do not let transplants share an unquoted directory with them.
- **Activation:** write temp, rename, record active entity in NVS, keep last-known-good, fall back to the compiled-in default after N failed boots.
- **Signing:** signatures do not make an untrusted entity safe; parser robustness does. Sign **release images and manifests** on the host (ed25519/minisign verified by the app).
- **Never burn Secure Boot or flash-encryption eFuses** on users' boards (irreversible, locks Dad's board to the Collective's key).

### 2.4a Decided S286 (Mark): the Open SDK

Mark will add an **Open branch or fork of the Pocket SDK** that ships the neutral Open Entity and has **no backend configured**. Dad uses it to build WillowClone (his own entity, his own persona/backend via the companion). The Open SDK is updated with new features alongside the RaBbLE Pocket SDK. This answers the app question below: WillowClone is a Dad-side build on the Open SDK, not a mode of the RaBbLE app, so option (b) holds, with the Open SDK's own app (voice, setup, Orbit as the SDK provides them) as the host. Open items it creates:
- **One source, two outputs.** Keep a single tree and produce the Open SDK by a filter/export spell (reserved brand app, brand entity, brand palette, name and marks excluded; Open Entity and a `backend: none` default included), not by a hand-maintained fork. A long-lived divergent fork guarantees drift and leaks. The spell runs in CI and fails if a reserved path or string appears in the output. A branch is only safe if the reserved files are never on it; a separate repo built by the spell is safer.
- **No-backend default:** the app must run cleanly with no beam configured (face, motion, clock, Orbit work; voice reports "no backend") and the companion's profile step is how Dad points it at sCoRE's open tier or anything else.
- **S8-S10 are on the path** (the Open SDK needs a host app that is not `app/RaBbLE`). The Open app may start as a copy-minus-brand of `app/RaBbLE` generated by the same spell until the SDK Orbit/UI split lands.
- **Release cadence:** each RaBbLE Pocket SDK release triggers an Open SDK release from the same commit; the version string carries both (Five-Es tag plus `-open`).
- **Licence:** the Open SDK is Code tier (§2.1). Its public status depends on the name/licence gates (L1, P2): Dad can receive it privately first.

### 2.4c Decided S286 (Mark): neutral SDK entity class, and the Open build runs lean

- **The SDK's entity class is neutral.** The SDK module and its public API carry no brand: a neutral name such as `sdk/entity` with `ent_*` symbols (final name settled in E0 review), not `rabble_*`. This also clears the clash the spec found (C5): the brand app keeps its own `app/RaBbLE/rabble_entity.c`, the SDK class sits beside it under a different name, and the brand entity may later be built on the neutral class where it fits. Per the earlier decision, internal identifiers elsewhere may still say `rabble`.
- **Memory is the major constraint** (Mark: the graphics use a lot of the system, and the app is tightly optimised). So **the Open SDK build may ship with fewer features than the RaBbLE build until heap and free memory improve**: e.g. voice notes stay off (B-22 already drops them), no mesh/strand effects, smaller rig and primitive limits, no sprites for entities (spec C2). Define it as an explicit **Open profile**: a Kconfig/feature set generated by the export spell (O1) with a recorded heap budget, so "Open has constraints" is a documented tier, not drift.
- **Measured today (S286, `partitions.csv`, build of 2026-10-25):** the app binary is 2,058,064 B in 3.5 MB OTA slots, so flash is **not** the binding limit (about 1.4 MB free per slot, and the `storage` LittleFS is 0x8E0000, about 8.9 MiB). Internal RAM (about 12.3 KB free at boot, `SPIRAM_MALLOC_ALWAYSINTERNAL=4096`) is the real constraint. The spec's entity data stays in PSRAM so it adds nothing there.
- **Where entities live, avoiding a reformat:** the spec proposes a dedicated 256 KiB partition, which on the 1.75B means shrinking `storage` and **reformatting the notes once** (the partition table says resizing reformats it). Alternative: keep entities as quota-limited files inside the existing `storage` with no partition change. Trade-off: the reviewer's finding that `storage` is mounted with `format_if_mount_failed = true` means a corrupt store would also wipe entities, and notes share the fate. **Decided (Mark, S286): entities live in the existing notes storage; no new partition and no reformat.** The notes store becomes a general **disk** for any data (entities, notes, captures, configs) whenever an SD card is absent, with SD used when present. Consequences for the SDK: `sdk/rabble_store` grows a small volume layer (mount by volume: internal flash or SD, per-directory quotas, a "disk full" policy), and the `format_if_mount_failed = true` behaviour must change for a general disk: a failed mount goes to a recovery mode (read-only or an explicit user-confirmed format), not a silent wipe. The 1.75C inherits the same design. Mark's wording was "IRAM"; the S3 splits one internal SRAM into instruction and data RAM, so I read it as internal RAM overall (see M1).

**M1: internal-RAM recovery track (Mark, S286).** Mark will hunt for more internal RAM for stacks and heap. Read-only first look at `sdkconfig` (not yet measured against the map, so these are leads, not findings): code and rodata already run from PSRAM (`SPIRAM_XIP_FROM_PSRAM`, `SPIRAM_FETCH_INSTRUCTIONS`, `SPIRAM_RODATA`); about 20 `*_IN_IRAM` options are on (SPI, I2C, GDMA, GPTIMER, MCPWM, RMT, `ESP_PHY_IRAM_OPT`, libc locks) and some exist because ISRs must survive flash-cache-off writes, so each needs a check before dropping; Wi-Fi uses 8 static RX buffers and 32 dynamic RX buffers (the static ones are internal RAM); `SPIRAM_MALLOC_ALWAYSINTERNAL=4096` keeps every allocation under 4 KiB in internal RAM; main task stack 8192, LWIP tcpip task 3072, event task 2304, timer 2048. Method: `idf.py size-components` / `size-files` against `build/rabble_pocket.map` for the IRAM/DRAM split, `uxTaskGetStackHighWaterMark` per task to trim stacks to measured peak plus margin, then flip one option at a time with the 3-boot heap A/B and the beam-connect check (the `.bss` creep rule from SDK plan §6).

### 2.4b Decided S286 (Mark): the Open companion and the Open project name

- **The companion app ships an Open version too**, same codebase, built twice: the RaBbLE build (brand UI, RaBbLE profiles and Aether theme) and the Open build (neutral UI, no backend preset, Open Entity default). One build flag selects theme, strings, default profile and icon set; the same export-and-leak-check spell as O1 covers it.
- **Neutral UI, RaBbLE-named code is allowed** (Mark): internal identifiers, file formats (`.rbl`/`.rble`) and variable names may say `rabble`. What is neutral is everything a user sees: window titles, installer and bundle names, app id, icon, colours, copy, URLs, error messages, the device's boot and settings screens. Add a CI check that greps the *built* UI strings and assets, not the source. Note the `.rbl`/`.rble` extensions and the code identifiers are still visible to a curious user; whether that is acceptable "neutral branding" is a lawyer question, and the build and package names must not contain RaBbLE.
- **Palette:** the Open UI uses its own neutral palette, not the Aether tokens (Aether is the brand; its gift-or-reserve decision is still deferred).
- **Name needed** for the Open project, entity, SDK and companion. Constraints for choosing: not "RaBbLE"/"RABBLE" or a near-sound (class-9 clash already open); a coined or common word that a clearance search can pass; works as a product line (`<Name> SDK`, `<Name> Companion`, `<Name> Entity`); no domain/handle conflict; sits well beside the Entity-transplant vocabulary. Clearance (USPTO TSDR by hand, plus app stores, GitHub, crates/npm) comes before the name is used publicly. Until chosen, use the placeholder **Open** in plans.
- **Leading candidates (Mark, S286): Familiar and Foundling**, both in the Occult/Coven register of the Collective. Mark's lifecycle: a person **creates and themes their Familiar**, can **summon a RaBbLE**, and later can **join the Collective with their Familiar as a Foundling**. Read as vocabulary: *Familiar* = the user's own entity on the open stack (the product/entity name); *Foundling* = a Familiar that has joined the Collective (a membership state, not a second product). That would fit the existing membership model (The Pair, summoning ceremony, Echo tiers) and the "cast, not summon" naming rule needs a check: `feedback_rabble_naming` says RaBbLE is cast and sCoRE summons the entity, so decide which verb a person uses for a Familiar (create/raise/call) versus summoning a RaBbLE. Both are ordinary English words, so they are weak as stand-alone trademarks and lean on the compound (`<Prefix> Familiar`) or the stylisation; run clearance on the compound forms (e.g. "Familiar" with SDK/Companion/Entity in classes 9 and 42) before settling.

### 2.4 Which app does WillowClone run? (resolved by 2.4a; kept for the reasoning)

Everything useful (input, voice, setup, Orbit, pomo) lives in `app/RaBbLE`; a "minimal Open Entity app" has no voice or setup and cannot be Dad's device.
- **(a) Fastest:** `app/RaBbLE` hosts a non-brand entity behind a runtime switch. Dad's device carries the RaBbLE app, ring, Orbit and name. Needs a vtable and a brand-off mode; weakest on "never claim to be RaBbLE".
- **(b) Right for a Collective fork:** WillowClone is its own app on the SDK. Requires SDK S8 and S9 (Orbit and UI into `sdk/`) and S10. That puts S8-S10 **on Dad's critical path**, not "parallel".

My recommendation: (b), with (a) as a clearly-labelled private stopgap if Dad should have something sooner. Needs your call.

### 2.5 Backend and the Beam Protocol (BLOCKER on assumptions)

- Firmware has one beam implementation (`sdk/rabble_net/rabble_beam_score.c`), speaking only `rabble-beam/0`. The only servers speaking it are sCoRE and `ops/beam-echo.py` *[reviewer]*.
- **sCoRE as backend (Mark, S286): a free open tier.** It serves a default GPT with **no persona**, and the user supplies a persona in the entity config. Today `RaBbLE-sCoRE/server/beam.py:407` hard-codes the RaBbLE system prompt, so this is an sCoRE change: the open tier skips `agents.rabble_system_prompt(...)`, and the persona text travels from the entity's config (via the companion/device settings) to the server. Consequences to design (not yet decided):
  - **Persona is untrusted input** that becomes a system prompt: cap its length, and strip or refuse any text claiming to be RaBbLE or the Collective (Accord: never claim to be RaBbLE). The RaBbLE persona stays behind the RaBbLE/auth tier.
  - **Free tier cost and abuse:** the memory notes OpenRouter's free tier caps at ~50/day (429) and that prod uses Mark's personal Groq key (temporary). A public free tier needs per-device rate limits, a token, and a funded provider before it is advertised.
  - **Where the persona lives:** in the `.rble`/`.rbl` file (see §2.2) so it travels with the entity, sent at beam `hello`. This needs a field in `rabble-beam/0` or a settings round trip: a protocol change, so version it.
- **Muse as backend:** Muse is a different stack (encrypted Noise session to a Muse VM, phone pairing, text only; tokenless pairing slated to stop). A client in firmware would need the Muse SDK, the clean-room source deleted S277 and a reopening of the taint. Realistic Muse option: a **host-side bridge** that speaks `rabble-beam/0` to the Pocket and Muse upstream. Not a firmware profile.
- So "no agent code change" holds only for a server that already speaks `rabble-beam/0`. "Dad runs any Beam server himself" is unworkable today; options are an sCoRE persona, a bridge, or a small reference Beam server (extend `beam-echo.py`).
- **Profiles:** firmware stores one beam URL/token (`rabble_settings.h:57-73`), so "per profile" lives in the companion unless firmware gains multi-profile. Tokens go in the OS keychain. `ws://` on a LAN sends the bearer token in cleartext: note for self-hosting.
- Config transport: define a versioned machine framing, not chunked `>beam.token+=` text-console writes.

### 2.6 1.75C specifics *[reviewer]*

32 MB flash (the 1.75B config pins 16 MB), no RTC (`rtc_get/set/valid` in the seam), no TF slot, PWR on GPIO3. No SNTP exists in `sdk/` or `app/`, so clock sync comes only from the beam's `ready.time`: a backend must send it, or B1 adds SNTP (an SDK edit, which would fail placement test 1; decide). The real work is board identity, partitions, sdkconfig and RTC, not "speaker/battery". The clean-room rule applies: the B1 spec needs a 1.75C schematic/datasheet that is not vendor demo code (the repo has only the 1.75 schematic). **Mark has no 1.75C yet (he will get one later); his dad is the tester**, so device gates (60 fps, heap, boot, beam) run on Dad's board remotely. That makes the companion's flasher (C1) part of the critical path rather than optional, plus a one-click **diagnostic report** (boot log, free heap, fps probe, board id, flash size) Dad can send back, and a safe recovery path (rollback enabled in the first image, app-only reflash, no partition-table writes) because Mark cannot reach the board to unbrick it. Until Mark has his own, B1 is built blind against the 1.75C schematic/datasheet and the 1.75B behaviour, so expect one or two remote debug rounds.

### 2.7 Companion app (Tauri: Windows, macOS, Linux)

1. **Flash** with the `espflash` crate (MIT/Apache) in the Tauri backend. **Do not bundle esptool** (GPL-2.0 breaks the permissive-only rule). Board-identity check before flashing: refuse a 175B image on a 175C. Update path flashes app-only, never the partition table or `storage`.
2. **Configure:** Wi-Fi, device name, backend profile (§2.5), over a versioned machine framing.
3. **Entities:** library, import/export, **Entity-transplant** to device (serial first).
4. **Editor:** vector expression editor with live preview; interpreter ported (WASM or JS) and checked against the C one via fixtures and the `sim/` parity sim.
5. **Linux:** native USB `303a:1001` is `ttyACM`; needs `dialout` or a udev rule (`TAG+="uaccess"`, `ENV{ID_MM_DEVICE_IGNORE}="1"` so ModemManager does not grab it). AppImage cannot install udev rules: ship rules in `.deb`/`.rpm` or a pkexec helper; on RaBbLE-OS put the rule in an Ansible role.
6. **macOS:** no serial entitlement outside the sandbox; notarisation needs the $99/yr programme, secrets on a GitHub macOS runner (no Mac owned).
7. **Windows:** Azure Trusted Signing or an OV/EV cert for SmartScreen. Tauri updater signing uses its own key.
8. **BLE and OTA are firmware tracks, not app work**: BT is off and no `esp_ota` code exists. **Enable app rollback in the first image Dad gets**, because the bootloader is effectively serial-only to change later.

## 3. Tracks and order

| ID | Track | Depends on | Gate |
|---|---|---|---|
| **R0** | Repair Grimoire git (S283 empty objects) | **handled by another entity (Mark, S286); this session does not touch it** | `git fsck` clean; then commit this plan and index it |
| **D0** | Mark decides §2.4 (a/b), §2.5 backend path, buys a 1.75C | none | decisions recorded |
| **E0** | Entity format spec (4 primitives, binary layout, limits, fixtures) + host compiler/validator | none | Opus-reviewed spec |
| **S10a** | `RABBLE_BOARD` CMake variable + per-board `sdkconfig.defaults.<board>` and `partitions.csv`, rollback enabled | none | 175B still builds and flashes |
| **E1** | `sdk/rabble_entity`: interpreter as 2nd scene builder, PSRAM tables | E0 | 60 fps idle, internal heap delta 0 (or B-22 fixed) |
| **E1b** | Transplant receiver, fuzzing, quota, activation + fallback | E0, E1 | fuzz clean; corrupt file never bricks boot |
| **E2** | Open Entity (two circles, one palette) | E1 | validates the format |
| **B1** | `boards/rabble_waveshare_175c` **built from Waveshare's code for now** (Mark, S286); clean room (spec, then implementer) once Mark has a board | S10a | placement test 1; Dad's device gate. **Licence gate first:** read the Waveshare demo's licence; use it only if permissive (Apache/MIT/BSD), isolated in its own directory with LICENSE + NOTICE, RaBbLE copyright above the upstream notice. If it has no licence or is copyleft, stop and tell Mark. Mark's tainted-code rule applies: Waveshare-derived code must sit in a clearly marked board folder so the later clean room can replace it |
| **B1b** | 1.75C clean room | Mark has a 1.75C | replaces the Waveshare-derived layer, as W6 did for 1.75B; overlap gate |
| **O1** | Open SDK export spell + CI leak check; `backend: none` default; Open Entity as default | E2, S10a | export builds, boots with no backend, contains no reserved path/string |
| **S8-S9** | SDK Orbit/UI split | per SDK plan | only if D0 = (b) |
| **A1** | Fork app for WillowClone (or runtime entity switch if D0 = (a)) | E1, B1, S8-S10 (b) | boots on 1.75C |
| **E4** | Dog entity: by hand, then via editor | E1, A1 | Dad's first demo |
| **K1** | sCoRE free open tier: no-persona default GPT, persona from entity config (sanitised, length-capped), per-device rate limit; beam protocol field versioned | E0 (persona part) | WillowClone replies as itself; never as RaBbLE |
| **C1** | Tauri shell: serial detect, `espflash`, board check, Wi-Fi + profile write; Linux udev | S10a | flash a release image on all three OSes |
| **C2** | Entity library + Entity-transplant | E1b, C1 | |
| **C1o** | Open companion build: neutral theme/strings/icons/app id, no backend preset, built-UI brand-leak check | C1, name chosen (placeholder until then) | no RaBbLE string or asset in the built app |
| **N1** | Open project name: shortlist, clearance search, domain/handle check, decision | Mark | cleared name recorded; gates any public Open release |
| **C3** | Vector expression editor | E0, C2 | WASM/JS passes C fixtures |
| **E3** | Move brand constants to the reserved tier (not "re-express the brand entity as data") | E1 | brand sim output unchanged |
| **L1** | Licence structure, NOTICE per tier, lawyer package | Mark's deferred decisions | gates public release only |
| **P1** | Release engineering: reproducible images, Five-Es tag, signed manifest, CI Win/macOS/Linux, gitleaks on history + tags | C1, L1 | |
| **P2** | Public cut: name clearance, README/Getting Started, repo shape | L1, P1 | Mark's call |

**Critical path to Dad:** D0 → S10a → B1, E0 → E1 → (S8-S9 if (b)) → A1 → E4 → K1, with C1 (flasher + diagnostic report) required, since Dad flashes and tests remotely. Licence and public release (L1, P1, P2) gate the public launch only.

Sub-agent fan-out: Opus for E1, E1b, B1 spec, C3 and S8; Sonnet for S10a, C1 scaffold and release CI; pin `model` on every dispatch.

## 4. Risks

- **Waveshare-derived board code in a shared SDK (new, S286).** Putting vendor code in the tree that the Open SDK exports means it ships to others. Its licence must permit redistribution, and `firmware/NOTICE` / `third_party` rules (permissive only, isolated) apply. It also re-taints the clean-room record (`cleanroom/PROVENANCE.md`) for the 1.75C layer, which B1b must later clear.

- **Heap/fps:** 12.3 KB internal free and B-22 already losing features; gate every step.
- **Clean room:** keep the Muse SDK out (a firmware Muse client reopens the taint) and treat Waveshare 1.75C demo code the same as W6.
- **Brand leakage:** backend persona, brand palette in SDK, extension names, Open Entity similarity.
- **Untrusted files:** parser UB and storage wipes (§2.3).
- **No OTA, no rollback** unless enabled in the first image.
- **Signing costs** for novice installs on macOS and Windows.
- **No backup (B-23)** and the Grimoire git damage (R0).

## 5. Open questions for Mark

| # | Question | Suggestion |
|---|---|---|
| Q1 | §2.4: WillowClone as its own fork app (b) or runtime entity switch in RaBbLE app (a)? | (b), (a) as a private stopgap |
| Q2 | ~~Backend~~ **Decided S286 (Mark):** sCoRE open tier = default GPT, no persona, persona from the entity config. Muse stays a possible host-side bridge, not firmware | K1 = sCoRE open tier + persona field; open: rate limits, funded provider, persona sanitising |
| Q3 | ~~1.75C hardware~~ **Decided S286 (Mark):** Dad is the 1.75C tester; Mark gets his own later. So B1 and every 1.75C device gate run on Dad's board, remotely | Consequences in §2.6: C1 moves onto the critical path; B1 gates become "Dad runs a script and sends the log" until Mark owns one |
| Q4 | Is building WillowClone for Dad a "private fork" under current Accord until the deferred fork decision? | Yes, record it |
| Q5 | ~~Extension~~ **Decided S286 (Mark):** `.rbl` general container, `.rble` entity-only | E0 specs the container + part registry |
| Q6 | Public repo shape: make Pocket public or export SDK + Open Entity + companion only? | SDK-only export |
| Q7 | Selling user entities: wait for the Creator/Shop licence? | Wait |

## 6. Cold start

1. Repair the Grimoire repo (R0) with Mark's OK; recommit B-23; commit this plan; add it to `log/plans/CONTEXT.md` and `INDEX.md` (those files carry another session's uncommitted rows: commit whole).
2. D0 decisions, then E0 as `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Format.md` with an Opus review.
3. Dispatch S10a, B1 spec, C1 scaffold and L1 package in parallel.

---

## Revision History

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-10-28 | S286: first draft; unreviewed. |
| v0.2 | 2026-10-28 | S286: Opus review folded in (4 blockers, 10 should-fix); "pack" retired for Entity-transplant and entity types; forks, Linux, undetermined backend; E3 rescoped, E1b, S10a and K1 added; Q2 withdrawn. |
