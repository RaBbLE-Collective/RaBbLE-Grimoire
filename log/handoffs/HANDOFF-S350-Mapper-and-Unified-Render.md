# HANDOFF-S350 (A): the board mapper, a unified RaBbLE render surface, the boot animation

Date: 2026-11-18. Repos: RaBbLE-Pocket (firmware + companion web), RaBbLE-Grimoire, RaBbLE-NeBuLA (read only). Branch `new-horizons` everywhere.
Start by reading `HANDOFF-S347-Pocket-Accounts-Metering.md` (policies) and this file. The companion (the "workbench") is at `RaBbLE-Pocket/companion-app/web/`; production is `pocket.joinrabble.world`.

## State you inherit (all committed, nothing pushed except sCoRE)

- **Pocket web companion**: deployed on 2026-11-18 (Worker version af37f671 and later). Workbench UI: round Pocket screen on a squircle housing with Connect (left) and Menu (right) keys, a fixed two-row status screen on top, a console as a separate device wired to the housing by a cable. Settings and Apps are an Orbit drawn on the Pocket's own display (`public/orbit.js`).
- **Firmware**: 0.1.2 is live in the R2 bucket (flashed and confirmed on Mark's 1.75-B). **0.1.3 is built and staged locally only** (`companion-app/web/.release/pocket/v0.1.3`, tracked manifest lists it) and has NOT run on hardware. It adds `key_fp` to `status` (first 12 hex of sha256 of the stored key) so the page can check the account link with no Wi-Fi. Publish only after Mark flashes it locally and confirms: `python3 ops/release-firmware.py 0.1.3 --no-build --entity RaBbLE --upload remote` (then check the remote manifest still lists only files that exist: upload every part of every listed version).
- **sCoRE**: deployed to Render from `release/0.1.0` (migrations 0008 and 0009 confirmed in Neon: `devices.fw`, `devices.fw_seen`). New: revoke deletes the row, `fp` listed per device, `POST /api/v1/devices/{id}/report`, `PATCH /api/v1/devices/{id}` (rename).
- Rules still in force: pin sonnet on fan-outs, never flash Mark's hardware unless he asked this session, never `pkill -f`, no AI trailers on commits, gitleaks before each commit.

## 1. The board mapper (Mark's design, S348)

Goal: the page never asks which board. It determines the model from the hardware, including a blank ESP32-S3.

- **Run it from RAM, never from flash.** esptool-js already has `memBegin`, `memBlock`, `memFinish` (see `public/vendor/esptool-js/bundle.js`). A RAM image cannot touch NVS, the stored key, Wi-Fi or entity data, so it is safe on every reflash flow. Build with `CONFIG_APP_BUILD_TYPE_RAM` (ESP-IDF; confirm the S3 option exists in the pinned IDF 6.0.1), no NVS init, no partition writes. Load it, read its output, hard reset.
- **It prints one JSON line over USB serial**, e.g. `@map {...}`: chip revision and package, MAC, flash size and JEDEC id, PSRAM size and mode, I2C scan on an allowlist of pin pairs only (never sweep GPIOs: 26-37 are flash/PSRAM), SD detect, display id if the pins answer.
- **Known board facts**: 1.75-B (vendor BSP `waveshare__esp32_s3_touch_amoled_1_75`): I2C SCL=14 SDA=15, AXP2101 PMIC, PCF85063 RTC (0x51), QMI8658 IMU, TCA9554 IO expander, CST9217 touch, CO5300 display on QSPI (CS12 PCLK38 D0-3 4-7 RST39), SD on GPIO 1/2/3. 1.75C: repo says "no clock chip, no card slot"; its pins are UNKNOWN (built blind, its vendor BSP is not downloaded).
- **Fingerprint table lives in the manifest**, not code: `firmware-manifest.json` `boards[id].fingerprint`. Add the 1.75-B entry now. The 1.75C entry comes from Mark's dad's first flash: the flash report must print the mapper JSON (extend the report builder in `public/portal.js`, `buildReport`). Unknown fingerprint: say so, send the report, never guess a build.
- **Page flow**: Connect -> pick port -> mapper (RAM) -> match -> flash the matching build -> pair. The manual board picker moves to Advanced as an override. The current safety stop (blank board needs a manual choice, `state.boardChosen` in `portal.js`) goes away only when the mapper lands.
- Test without hardware: mock `loadRam` in a Playwright run (see `scratchpad` style tests in this session: serial mocks via `navigator.serial.getPorts`), unit-test the matcher.

## 2. A unified rendering surface (web + Pocket)

Today the web entity is generated from the Pocket mock (`planning/mock/rabble-pocket-entity.html`) by `companion-app/web/build-entity.py` into `public/entity/pocket-entity.js`; the firmware `scene.c` was ported from the same mock by hand. They agree today by convention. Mark wants one consistent, configurable entity.
- The spec already exists: Grimoire `RaBbLE-Pocket/RaBbLE-Pocket-Entity-Format.md` (`.rbl`/`.rble`, four primitives, data not code, host JSON authoring, on-device flat binary, conformance suite). The brand entity is native in `scene.c` and is not in that format (section 9). Recommended direction: make the brand entity expressible as data too, render it from the same file on both sides (JS interpreter in the page, the existing C interpreter on device), and gate changes with golden frames: `RaBbLE-Pocket/sim/host_render.c` renders PNGs on the host; compare the web output against them (pixel diff with a tolerance) in CI.
- Configurable: palette (cyan/magenta poles may swap), eye shape, mesh density, and persona parts. The shelf of Pockets already draws a placeholder hue per device (`hueOf` in `portal.js`): replace it with the stored per-Pocket entity config once there is somewhere to store it (a column on `devices`, or the Pocket's own NVS reported in `status`).
- Parameters the page already adds on top of the mock: lite quality (no `class="s"` glow layer, no blur filters), a frame-rate governor, gaze (`PocketEntity.look`), mic-driven bars (`PocketEntity.audio`), real local time. Decide which belong in the shared surface.

## 3. Boot animation (Mark's ask, not started)

When a Pocket connects, play a boot like the original RaBbLE boot, fancier than the device's: the edges materialise to sculpt the portal voids, then the eyes come out of the portals. Device version for reference: `scene.c` ~line 626 ("Boot: portals fade in, cyan first; then the eyes and the rest"). Suggested web approach: a time-based intro keyed off the mount time (the `mount()` in `build-entity.py` already has a clock): ramp the face `dim` (edges materialise), keep eyes withdrawn (`face.blink = 1`, they squash into their portals) until the voids exist, release them with an eased `blink 1 -> 0`, then fade in the glass layer (clock, status row). Add an API `PocketEntity.boot()` and call it when the display first turns on. Keep reduced-motion support.

## 4. Open design question for Mark

Keep the console as its own device wired to the housing (current), or build it into the housing as a second screen? My recommendation: keep it separate (it can dock to any edge or float, it needs room, and the cable metaphor is the point), and put a one-line ticker of the last console line on the housing if wanted. Mark said he is not sure which looks cooler; offer both behind a toggle if cheap.

## Deferred by Mark (S350, "this is getting bloated"): do these as follow-ups, not in the mapper session

1. **The mesh transition into Settings is still not right** (Mark's words). Current: `public/orbit.js` `mesh()` draws the entity's real mesh nodes (`PocketEntity.meshSide`, current positions) on a canvas and gathers them into the orbs in even runs while the nebula backdrop fades in. It does not yet match the hardware: compare against `RaBbLE-Pocket/sim/transition.sh` renders (`sim/out/tr_*`) and `RaBbLE-Pocket-Orbit-Transition.md` (the grab, the pinned and stretched mesh, one-colour mesh per side, edge glow, the return mirrors the entry). Render both side by side before changing code.
2. **Boot animation** (section 3 above).
3. **Developer console device rework** (section 4 above): decide separate device vs a second screen on the housing, then redo its look as a physical device with keys, and its cable.

## Known gaps

- `test/portal_test.py` is stale (old labels); the Worker tests (`node test/pairing_test.mjs`, 24 checks) are current. The layout check used this session is a Playwright script that walks every Orbit view at 1280x720, 1440x900 and 1920x1080 and flags overlaps, anything outside the circle, text under 11 px and clipping (one 1280x720 Apps-panel line still flags). Recreate it as a committed test.
- The real flash path (esptool in the browser) was not exercised by any automated test; only the button logic with mocked serial.
- The key-fingerprint link check needs firmware 0.1.3 on the Pocket.
