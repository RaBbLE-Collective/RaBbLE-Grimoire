# Pocket Web Flasher: plan (S325, 2026-11-11)

```
spark ~ pocket/flasher >> plug in, open a page, click Install: Dad's 1.75C gets RaBbLE or a Foundling // %S325_PLAN%
```

> **Status:** v0.2 (S325, same day): B1, F0, W1 and K1-interim **built and tested locally; not deployed, not yet on hardware** (see §0). Not Opus-reviewed.

## 0. Built in S325 (what changed from the draft below)

Mark ruled mid-session: the companion lives in `RaBbLE-Pocket/companion-app/` with `web/` and `mobile/` variants; Aether-themed with NeBuLA parts, simple and clean; gated behind an early-access code; firmware blobs in a **private R2 bucket** behind the companion's Worker (not GitHub: public, ungated, no CORS; GitHub Releases may later mirror public builds once B-27 clears).

- **B1 1.75C board** `firmware/boards/rabble_waveshare_175c/`: own board table (`bsp_waveshare_175c.c`, no RTC, clock group zeroed), the 1.75-B display engine compiled against Waveshare's own `waveshare/esp32_s3_touch_amoled_1_75c` 3.0.0 package (Apache-2.0, same licence as the 1.75 package already used). Pins checked against the 1.75C schematic: LCD reset GPIO1, touch reset GPIO2, I2S MCLK GPIO16, rest as the -B; same AXP2101 rail table; PWR key on PWRON. **Flash:** product page says 32 MB, schematic shows XM25QH128 (16 MB), so the image is laid out for 16 MB (runs on either). Root `CMakeLists.txt` keys sdkconfig and lock by board + entity for non-default boards; `ops/build-flash.sh -b`. Both entities build; 1.75-B unchanged, host suite 36/36, layer gate clean. **Unverified on hardware:** key/mic placement, IMU orientation.
- **F0** `ops/release-firmware.py`: no merged image; the manifest lists the four parts per build (offsets from `flasher_args.json`, size, sha256). Board identity is the user's pick (flash size cannot tell the boards apart, see above) plus a log note when `@status` reports a different board.
- **W1** `companion-app/web/`: Worker (gate cookie, `/firmware/*` from R2, `/api/summon` proxy) + static page (esptool-js 0.7.0 vendored, Apache-2.0). Fresh install erases and writes all four parts; update writes otadata + app only.
- **K1 interim**: the page redeems a sCoRE invite through the Worker and writes the key with `>beam.token=`; or the user pastes a key. AC7 pair codes replace this when accounts land.
- **D1/D2 not done**: Foundling still has no console, so for Foundling the page flashes and shows the boot log only.

**Release (Mark, S325):** v0.1.0. `release/0.1.0` in Pocket now carries the 1.75C board and the companion (local merge, not pushed); images built from that tree report `0.1.0`. Mark flashed his 1.75-B from the local page: RaBbLE, Foundling, RaBbLE again, with Automatic (settings kept).

**Next:** Mark deploys (bucket, two secrets, `wrangler deploy`, steps in `companion-app/web/CONTEXT.md`); test a flash end to end on the 1.75-B (runs standard RaBbLE firmware; BOOT switch dead, B-28, so it relies on USB auto-reset); then Dad flashes Foundling first.
> **Asked by Mark (S325):** "My dad just got a Waveshare 1.75C in hand and I want to flash RaBbLE or the Foundling. He is on Windows so I want a plug and play downloadable that can distribute the pocket firmware versions and handle device setup, sCoRE token etc."
> **Ruled by Mark (S325):** (1) web flasher first (Chrome/Edge, Web Serial), the Tauri companion later on the same manifest; (2) both entities offered, Dad picks; (3) the sCoRE token is Dad's own account key. Mark: sCoRE accounts are being scoped now; Dad should be the second sCoRE user.
> **Builds on:** `Pocket-Release-Entities-Companion-Plan.md` v0.3 (§2.6 1.75C, §2.7 companion: espflash, no esptool, board-identity check, app-only updates, diagnostic report), `Accounts-Formalization-Scope.md` (A1 store, AC7 device pairing), `RaBbLE-Pocket/firmware/CONTEXT.md`.
> **Read from code (2026-11-11, `new-horizons`):** `firmware/boards/` holds only `rabble_waveshare_175b`; `entities/RaBbLE/src/rabble_setup.c` handles `>wifi.ssid=`, `>wifi.pass=`, `>beam.url=`, `>beam.token=` / `beam.token+=`; Foundling has no setup console and no beam; `CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE=y` already; `RaBbLE-sCoRE/server/beam.py:119` accepts `BEAM_DEVICE_TOKEN`, a user API key, or a JWT; `auth_routes.py` has `/admin/invites` + `/summon` (invite redemption returns an `rbbl_` API key); `users.py` stores under `DATA_DIR` (file store); `render-ctl.sh` confirms the hosted free tier has no persistent disk.

## 1. Outcome

Dad plugs the 1.75C into his Windows PC with a USB-C cable, opens `joinrabble.world/pocket` in Chrome or Edge, picks **RaBbLE** or **Foundling**, clicks Install. For RaBbLE he enters his Wi-Fi and signs in (or pastes a pair code); the page writes them to the device. The face comes up; RaBbLE answers him over sCoRE. If anything goes wrong he clicks **Send report** and Mark gets the boot log.

Nothing to install, no driver (Windows 10/11 binds the ESP32-S3 native USB `303a:1001` as a COM port on its own), no SmartScreen, no code signing.

## 2. Gaps (what blocks Dad today)

| ID | Gap | Why it blocks | Size |
|---|---|---|---|
| G1 | **No 1.75C board** in firmware | nothing to flash | L, built blind (Mark has no 1.75C) |
| G2 | No release images or manifest | the page has nothing to fetch | S |
| G3 | No web flasher page | the ask | M |
| G4 | No machine-readable device info | board check and report need it | S |
| G5 | Dad has no sCoRE account | RaBbLE cannot authenticate the beam | depends on accounts work |
| G6 | **Hosted user store is ephemeral** (Render free, file store under `DATA_DIR`) | Dad's key vanishes on every redeploy | covered by Accounts A1 (Postgres); must land before Dad relies on it |
| G7 | Flasher origin not in sCoRE `CORS_ORIGINS` | sign-in from the page fails | XS |

## 3. Tracks

| ID | Track | Depends | Gate |
|---|---|---|---|
| **B1** | 1.75C board: `boards/rabble_waveshare_175c/` (board vtable, `partitions.csv` for 32 MB, `sdkconfig.defaults`, PWR GPIO3, no RTC, no TF) + `RABBLE_BOARD` CMake variable (S10a) so one tree builds `{175b,175c} x {RaBbLE,Foundling}` | 1.75C schematic + Waveshare wiki pin table (datasheet, not vendor demo code; licence check of `waveshare__esp32_s3_touch_amoled_1_75` first) | 175B still builds, host suite 36/36; 175C builds for both entities |
| **F0** | Release build: `ops/release-build.sh <version>` builds the four images, writes a merged factory image (bootloader + partition table + otadata + app, offset 0) and an app-only image per board x entity, plus `manifest.json` (version, board, entity, flash size, offsets, sha256, min-board-rev). Publish to the CDN under `pocket/v<semver>/` with `publish-cdn.sh` | B1 | `manifest.json` validates; sha256 matches; 175B image flashes on Mark's board through the page |
| **D1** | Device info: `>info` console line returning one JSON line (`board`, `entity`, `version`, `flash_mb`, `free_heap`, `reset_reason`, `wifi`, `beam`), in **core** so Foundling answers it too | none | both entities answer on 175B |
| **D2** | Setup console moves to core (Wi-Fi is a core service per the Reorg plan); Foundling gains `wifi.*` (needed later for time/updates, harmless now). Beam keys stay RaBbLE-owned | Reorg R-numbering, check with Mark | Foundling answers `>wifi.ssid=` |
| **W1** | Web flasher page. `esptool-js` (Apache-2.0, pinned, from a permitted CDN) over Web Serial. Steps: Connect -> read chip + flash size -> match manifest board (32 MB = 1.75C, 16 MB = 1.75B; refuse a mismatch) -> pick entity + version (latest default, older listed) -> **first install**: merged image, full erase; **update**: app-only to the inactive OTA slot, never partition table or `storage` -> reset -> open console -> `>info` -> setup (RaBbLE: Wi-Fi + token) -> verify `>info` shows `beam: connected`. **Send report**: `>info` + last 200 log lines, copied to clipboard or downloaded as a `.txt` (no upload service in v1). Aether CSS from the CDN, vanilla JS | F0, D1 | Mark flashes his 175B from Chrome on Windows (or a Windows VM) end to end |
| **K1** | Token. **Now:** Mark creates an invite (`POST /admin/invites`); the page redeems it (`/summon`) and writes the returned key with `>beam.token=` (chunked with `beam.token+=` if long). **Then:** swap to Accounts AC7: Dad signs in on joinrabble.world, the signed-in home shows a short pair code, the page exchanges it for a device-scoped token. Add the flasher origin to `CORS_ORIGINS` | Accounts A1 (persistent store) before Dad depends on it; AC7 for the final form | Dad's RaBbLE answers; key survives a Render redeploy |
| **T1** | (later) Tauri companion reads the same `manifest.json` and speaks the same console protocol, flashing with `espflash` | W1 | out of scope here |

**Order:** D1 and K1-interim in parallel with B1 -> F0 -> W1 on Mark's 175B -> Dad's first flash (Foundling first is the lowest-risk board bring-up: no Wi-Fi, no token) -> RaBbLE + token once G6 is closed.

## 4. Decisions still open (for Mark)

| # | Question | Recommendation |
|---|---|---|
| Q1 | Where the page code lives and is served | Code in `RaBbLE-Pocket/flasher/` (Pocket owns its tooling), served at `joinrabble.world/pocket` by World as a static page; images on the CDN |
| Q2 | Is the flasher a public page or unlisted for Dad first | Unlisted path for v1; the RaBbLE image is Sovereign Accord brand tier, personal use, so no public download until B-27 |
| Q3 | Dad's first flash: Foundling or RaBbLE | Foundling first (board bring-up without network), then RaBbLE on the same visit |
| Q4 | Report delivery | Clipboard / `.txt` download in v1; an upload endpoint on sCoRE later |
| Q5 | Accept running Dad on the interim invite key before Postgres lands | No: wait for A1, or accept that a redeploy means re-pairing |

## 5. Risks

- **Blind board bring-up (B1).** Expect one or two remote rounds. Mitigations: Foundling first, the report button, rollback on, and the ESP32-S3 ROM bootloader is always reachable over native USB (hold BOOT, tap RESET), so a bad image is recoverable by Dad with the same page.
- **Web Serial is Chromium only** (Chrome, Edge). Firefox users get a clear "open this in Chrome or Edge" message.
- **Opening the port resets the board**, and a host that stops reading stalls it (`firmware/CONTEXT.md`). The page must keep reading for as long as the port is open.
- **Token in transit:** the token goes over USB, never over the network, from the page; the page only talks to sCoRE over HTTPS.
- **Licence:** `esptool-js` is Apache-2.0 (permitted); esptool (GPL) is never bundled.

## 6. Cold-start handoff

- Branch: `new-horizons` in RaBbLE-Pocket, RaBbLE-sCoRE, RaBbLE-World. Pocket `release/0.1.0` exists (unmerged, Genesis queue in `HANDOFF-S323-Genesis-Release.md`).
- Build: `ops/build-flash.sh firmware` (RaBbLE), `ops/build-flash.sh firmware -e Foundling` (Foundling, `build-Foundling/`, `sdkconfig.Foundling`). Toolchain: `source ops/esp-idf-select.sh; pocket-idf` (ESP-IDF v6.0.1).
- Board pattern to copy: `firmware/boards/rabble_waveshare_175b/` (vtable in `core/rabble_core/include/rabble_board.h`, capability groups, W11).
- Settings API: `core/rabble_core/include/rabble_settings.h` (`rabble_settings_set_beam_url/token`, max lengths).
- sCoRE: invites `RaBbLE-sCoRE/server/auth_routes.py` (`/admin/invites`, `/summon`), beam auth `server/beam.py:119`, CORS `server/main.py:55`.
- Palette: `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md` only; page styling from the Aether CDN.
- Voice: no em dashes in page copy; plain checkable claims (README-voice ruling S324).
