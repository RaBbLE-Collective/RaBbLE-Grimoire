# Provenance audit: original Pocket port (S242/S243, 2026-10-06/07), transcript findings

Sources. SESS1 = 35c63c6d-d13d-4870-b6df-d5b86071ba0e.jsonl (S242, 21:21-22:21Z, 745 lines). SESS2 = a5cc84d6-8896-4305-8f8c-a5c52be6f0d9.jsonl (S243, 22:33Z 10-06 to 02:42Z 10-07, 1935 lines). Citations are "S1:<jsonl line>" / "S2:<jsonl line>" plus UTC time. Both under ~/.claude/projects/-home-rabble-RaBbLE-Collective/. No tokens/secrets are quoted (the Muse "mgst_" SDK token appears in SESS1 build output only; not reproduced). Facts only, no legal opinion.

## 1. How the SDK came onto disk, and the base commit

- Mark's request, S1:9 21:23Z: "clone and flash the muse SDK to my board, this will be a possible experimental starting point for my own pocket FW" (plan from RaBbLE-BaBbLE/intake/rabble-pocket-muse-bringup.md).
- Exact command, S1:80 21:23:53Z (cwd RaBbLE-Pocket/firmware): `git clone https://github.com/facebookincubator/muse-gadget-sdk.git 2>&1 | tail -3; cd muse-gadget-sdk && git log --oneline -3 && ls ...`. No `-b`, no `--depth`, so a full clone of the default branch. Result S1:81: "Cloning into 'muse-gadget-sdk'..." then
  `b139b45 linux: bound system.run's pipe reads by a deadline` / `6c33c12 fix: wait for the shell to exit in system.run` / `1d2cb5a Document and validate LCD7 hardware port`.
- Commit date: S1:604-606 22:15Z `git log -1 --format='%h %ad' --date=short` in muse-gadget-sdk/esp32 returned `b139b45 2026-10-05`.
- Base commit = **b139b45 (2026-10-05)**, HEAD of the default branch at clone time. Re-confirmed S2:58 22:37Z (`git log --oneline -1`). Nothing in either transcript does a pull, fetch, checkout or reset in the clone, so the port was made from this one commit. Later docs cite the same SHA: Grimoire Muse-SDK-Map.md line 23 ("at b139b45 (2026-10-05)"), Gadget-Port.md line 10, Clean-Room-Plan.md line 29, cleanroom/PROVENANCE.md.
- Where it lived: RaBbLE-Pocket/firmware/muse-gadget-sdk/ (not third_party/ at the time), gitignored by Pocket commit 15e1f95 (2026-10-06, "gitignore Muse Gadget SDK clone + flash backups"; adds firmware/muse-gadget-sdk/ and firmware/backups/). Never tracked in git.
- Same SDK was also built unmodified with `tools/muse/board.sh` (target s3n), and flashed to Mark's -B board in S1 (S1:360, 21:39Z) for hardware tests. Only the clone's gitignored build dir/sdkconfig were touched (token setting); no SDK source edit is visible in S1. S1 wrote nothing into Pocket firmware except the .gitignore (S1:170). S1 also wrote the Grimoire notes RaBbLE-Pocket-Muse-SDK-Map.md (S1:642, 22:16Z, 15 KB) after reading the SDK widely.
- Not determinable: whether the working-tree clone was ever byte-compared to upstream; only the `git log` HEAD evidence exists.

## 2. Files moved/created from the SDK (S2)

Mechanism, S2:217-224 (22:40Z): assistant said "copying the Apache-2.0 modules into a new rabble_gadget component with a mechanical rename, then hand-fixing the seams (Home Link, BLE, Muse cloud, avatar)". It wrote scratchpad port.sh (S2:223) containing a source->dest map and ran it: for each file `sed -E` renames (muse_hatch_->rabble_beam_, MUSE_HATCH_->RABBLE_BEAM_, muse_chat*.h->rabble_beam*.h, muse_pmu_->rabble_axp2101_, wifi_mgr_/wifi_known_ prefixes, then generic muse_->rabble_, MUSE_->RABBLE_), writing `$src > $dst`; then a python step inserted " * Modified 2026 by The RaBbLE Collective: renamed and adapted for RaBbLE-Pocket." after the Apache header (S2:223). Output "done"; 1382 leftover upstream-name references counted (S2:224). Files later moved into apache/ by `mv` (S2:450, 22:51Z).

Table. SDK paths relative to muse-gadget-sdk/esp32/; Pocket paths relative to RaBbLE-Pocket/firmware/. "V+rename" = copied by port.sh with sed rename only. Hand-edit step = what the transcript shows afterwards. Upstream% = line-match measured S252 (Clean-Room-Plan.md), included only as cross-check, not from the S243 transcript.

| SDK source | Pocket destination | Nature at S243 | Later hand edits seen in S2 (line) | S252 upstream% |
|---|---|---|---|---|
| components/muse/muse_adpcm.c/.h | components/rabble_gadget/apache/rabble_adpcm.c/.h | V+rename | none seen | 90 |
| muse_audio.c/.h | rabble_audio.c/.h | V+rename | none seen | 70 |
| muse_battery.c/.h | rabble_battery.c/.h | V+rename | none seen | 96 |
| muse_board.c/.h | rabble_board.c/.h | V+rename, then edited | .h: python replace of comments and RTC hooks, dropped other-board fields (S2:306-315); .c unchanged | .c 83, .h 53 |
| muse_console.c/.h | rabble_console.c/.h | V+rename, then edited | UART-conditional branch removed, header comment rewritten (S2:504) | 60 |
| muse_input.c/.h | rabble_input.c/.h | V+rename, then edited | removed ble/link/menu/watcher-camera includes and double-press BLE setup, added rabble_setup, wake hook (S2:342, 354, 673) | 64 |
| muse_keypad.c/.h | rabble_keypad.c/.h | V+rename | recolored via palette include (S2:540) | 96 |
| muse_lv_mem.c, muse_mem.h | rabble_lv_mem.c, rabble_mem.h | V+rename | none | 100 / 20 |
| muse_settings.c/.h | rabble_settings.c/.h | V+rename, then **overwritten** | whole files re-authored via heredoc (S2:250-271) after reading the ported copy: NVS namespace "rabble", beam URL/token replace Muse host/VM/token, power_off setting, same header block reused | 49 / n.a. |
| muse_settings_ui.c/.h | rabble_settings_ui.c/.h | V+rename, then edited in place | Muse/Bluetooth pages swapped for sCoRE page, palette colors, Tier-2 choice, Clock row (S2:509-548, 1227) | 74 |
| muse_state.c/.h | rabble_state.c/.h | V+rename | one comment (S2:271) | 68 |
| muse_text.c/.h | rabble_text.c/.h | V+rename | none | 86 |
| muse_voice.c/.h | rabble_voice.c/.h | V+rename, then edited | board #ifdefs, MP3 self-test, captions, hatch_reply->beam_reply (S2:485-495) | 61 |
| muse_wifi.h | rabble_wifi.h | V+rename, then edited | comments/prototypes (S2:407) | 45 (with .c) |
| main/wifi_mgr.c/.h | rabble_wifi_mgr.c/.h | V+rename, then edited | CONFIG guards removed (S2:391) | 94 |
| main/wifi_known.c/.h | rabble_wifi_known.c/.h | V+rename, then edited | config_store replaced with local NVS helpers (S2:383) | 78 |
| muse_chat.h / muse_chat.c | rabble_beam.h / rabble_beam.c | V+rename, then edited | header comment rewritten for sCoRE; "linked" check now URL set; string swaps (S2:436-440) | 33 |
| muse_chat_priv.h | rabble_beam_priv.h | V+rename, then edited | S2:440; sed rename chat_connect->session_connect (S2:450) | (with above) |
| muse_chat_text.c | rabble_beam_text.c | V+rename | none | 89 |
| muse_app.c | rabble_app.c | V+rename, then edited | BLE case removed, TAG "rabble" (S2:558) | 29 |
| components/muse/muse_pmu.c/.h | components/rabble_axp2101/rabble_axp2101.c, include/rabble_axp2101.h | V+rename **replacing Mark's earlier driver of the same name** (HEAD version read S2:604) | hand merge python: PEKEY 128 ms enum, battery detect, extern "C" (S2:610) | 83 |
| components/muse/boards/muse_lcd_bands.c/.h | bsp/rabble_lcd_bands.c/.h | V+rename | none | 31 |
| components/muse/boards/board_waveshare_s3_175c.c | bsp/bsp_waveshare_175b.c | V+rename, then **rewritten** | S2:620-621 22:55Z: assistant states it "combines the SDK's proven display/touch/audio/PMU-key path with your dark-start and the PCF85063 RTC"; full file re-emitted via heredoc with the 4-line header prepended (header re-fixed S2:768) | 45 |

Not from port.sh but placed under apache/ with the Apache-style 4-line header (reused from hdr.txt copied off a ported file): **rabble_setup.c/.h** (S2:359-360, 22:48Z; "the key=value setup commands + status JSON"; written after reading SDK muse_ble.c command/status functions at S2:328, 336) and **rabble_wifi.c** (S2:406-407, 22:49-22:50Z; "our own Wi-Fi keeper to replace Home Link's"; written after reading main/muse_glue.c lines 90-682 at S2:160, 171 and muse_wifi_power in muse_link.c at S2:400). Both were composed fresh by the assistant with the SDK files in context, not copied.

Other cp/mv: `cp muse-gadget-sdk/LICENSE $d/LICENSE-APACHE` for apache/, bsp/, rabble_axp2101/ (S2:581, 22:54Z; the SDK root LICENSE, verbatim). Git commit of all this: Pocket 42ae6d9 (2026-10-06) "SDK hardware layer ported, own LVGL face, voice beamed to sCoRE" (85 files; apache/ 29 pairs plus LICENSE-APACHE, NOTICE).

## 3. Files authored in the session without port.sh, and SDK-in-context status

Written under components/rabble_gadget/accord/ (header "Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord", no Meta line):

| File | Authored (S2 line/time) | SDK file read earlier in same session? |
|---|---|---|
| accord/rabble_ui.c/.h (face, status row, captions, hints) | Write S2:678 22:59Z (18.7 KB), later canvas rewrite S2:869 | Yes, topic overlap: muse_ui.c function list, lines 1100-1160 and 1475-1610 read (S2:180, 185, 22:39Z); muse_settings_ui.c call counts; muse_pixel.h/avatar header read in S1:615. Also read Mark's own entity_face.c, screen_idle.c, screen_boot.c (S2:632). Body not copied: comment says "RaBbLE's face... twin eyes and portals". Cleanroom plan lists accord/* as "already RaBbLE's own". |
| accord/rabble_beam_score.c (sCoRE WebSocket session) | Write S2:726 23:02Z (24.8 KB) | Yes: muse_chat_session.cpp read S2:147, 151 (functions list; lines 128-260, 300-325, 2013-2269, 22:38Z); muse_chat_priv.h, muse_chat.c, muse_chat_text.c read in full S2:138; muse_voice.c read S2:122. This file replaces the SDK's muse_chat_session.cpp (which was not copied). Written against esp_websocket_client headers (S2:711). |
| accord/rabble_palette.h, rabble_lv_assert.h | heredocs S2:540, 779 | No SDK counterpart seen. |
| accord/entity_face.c/.h, ui_theme.h, rabble_clock_screen.c/.h | `git mv` of Mark's pre-existing main/app/entity_face.*, ui_theme.h, screen_settings.c (S2:662, 22:57Z) | Mark's own earlier code, not SDK. |
| accord/rabble_motion.c/.h, components/rabble_qmi8658, rabble_pcf85063 | motion/IMU written S2:1165-1181 (2026-10-06 23:37Z); pcf85063 pre-existing | IMU: modelled on Waveshare's qmi8658 component and the QMI8658C datasheet (S2:1115-1153; assistant checked that component's license.txt). SDK not consulted. |
| main/app_main.c, ops/beam-echo.py, sdkconfig.defaults, Kconfig, CMake/idf_component.yml | S2:599, 689, 887 | Build files were written after reading SDK Kconfig, sdkconfig.muse*, sdkconfig.defaults and partitions_muse.csv (S2:461, 466, 22:51-22:52Z); settings they pin (IDF v6.0.1, LVGL 9.5.0, esp_lvgl_adapter 0.6.4) were chosen "to the stack the SDK was verified on" (S2:598). beam-echo.py: no SDK equivalent. |
| RaBbLE-sCoRE/server/beam.py | Write S2:1405 (other repo) | Not SDK-derived (server side, Groq). |

SDK files opened/skimmed in S2 before writing (for the "was it in context" question): muse_board.h, board_waveshare_s3_175c.c, muse_pmu.h/.c, muse_state/mem/wifi.h, all public headers (S2:88), muse_board.c, muse_app.c, muse_lv_mem.c, muse_lcd_bands (S2:111), muse_voice.c, muse_chat*.{h,c,cpp}, main/wifi_*, muse_glue.c, muse_ui.c (partial), muse_settings_ui.c (usage grep), muse_ble.c (partial), muse_link.c (one function).

## 4. Excluded/discarded and license handling

Excluded (S2:7 request, S2:256 option text, Gadget-Port.md "Dropped from the SDK", S2:981 summary): Jollybot avatar (esp32/avatar/: happy_anim.c/.h, jollybot.gif, muse_pixel.c; S2:102 header scan showed Meta copyright but no Apache text, and SDK README line 72: "The Apache License does not cover the Jollybot avatar", S2:107). Also not copied: Home Link (muse_link, muse_chat_link, muse_account_api, pairing/tokens/Noise sessions/tunnel/OTA), muse_ble, muse_menu, muse_chat_session.cpp (cloud client), noise_core, camera, minimp3 (CC0), CJK/BSD font, other boards' board_*.c and box_3_microphone, watcher_camera, wake/other tooling. Realtime voice: the SDK's cloud voice path (Hatch client) replaced by beam to sCoRE; voice loop muse_voice.c itself was kept. The SDK's account/pairing token (GADGET_SDK_TOKEN) was only used in S1 to run the stock firmware, not carried over.

License decisions:
- Mark's question S2:256-257 (22:46Z): chose "Third-party = Apache only", extended: "if BSD is permissive enough ie. not copy left then we can use that too. All my code and mods are my license, OG license is for apache or open pieces only... keep it properly isolated so that I can keep my sovereign accord properly licensed." Saved as memory feedback_permissive_thirdparty_isolation.md (S2:293).
- Mid-turn Mark messages: S2:278 22:46:57Z "Can I not put my Copyright above metas?"; S2:566 22:53:48Z "Rename hatch to pocket. Hatch is metas. Also can I minimize how obvious it is that meta wrote the base code?" The memory note (S2:581) records: "minimize how obvious it is that Meta wrote the base".
- Header treatment, three stages. (1) port.sh S2:223: Meta's full Apache header block left intact, plus added "Modified 2026 by The RaBbLE Collective" notice. (2) S2:265, 283 (22:46-22:47Z): RaBbLE copyright and Accord statement placed above; original portions stated as Apache-2.0. (3) S2:571-574 (22:54Z) compact.py: every derived file reduced to a 4-line header: `Copyright (c) 2026 The RaBbLE Collective. Changes: RaBbLE Sovereign Accord.` / `Copyright (c) Meta Platforms, Inc. and affiliates.` / `SPDX-License-Identifier: Apache-2.0 (original portions; see LICENSE-APACHE)`. The long Apache license text and "Modified" notice were removed from the per-file headers; Meta's copyright line kept verbatim. Assistant: "Every derived file now has the 4-line header" (S2:580). bsp_waveshare_175b.c got the same header by hand (S2:768).
- LICENSE-APACHE copy: S2:581, SDK root LICENSE copied into apache/, bsp/, rabble_axp2101/.
- NOTICE: firmware/NOTICE created in the S2:948 command (committed in 42ae6d9). It lists those three dirs as Apache-derived, "Original portions: Copyright (c) Meta Platforms, Inc. and affiliates", RaBbLE modifications under the Accord, accord/ + pcf85063 + main/ as RaBbLE's own. The SDK repo itself had no NOTICE at b139b45 (S1:621 `ls NOTICE*` found none; Muse-SDK-Map.md line 123).
- Names: all "muse"/"hatch"/"link"/"jollybot"/"xiaozhi" identifiers renamed or removed; final grep S2:959-969: only the Meta copyright line (and the gitignored clone's folder name in one doc) remained. Provenance (repo + b139b45) deliberately kept in the Grimoire, not in code (Gadget-Port.md rules).

## 5. Statements of intent

- Mark S1:9: "possible experimental starting point for my own pocket FW"; S1 asst S1:677 "Muse = text-only push-to-talk bridge, good BSP reference" (memory index).
- Mark S2:7 (22:37Z): "Let's now begin porting the Muse SDK to my BSP, I want to have the HW parts usable, my own LVGL instead of jollybot and only apache 2.0 licensed code in my FW. I want to be a RaBbLE gadget... I want to mimic what muse does but using score to beam data to and from RaBbLE. I don't want references to muse in my code. remove or rename any muse or meta centric enums and vars, I want this to be rabblified and Adapted for my plans."
- Assistant S2:217: "copying the Apache-2.0 modules ... mechanical rename, then hand-fixing the seams". S2:620: "combines the SDK's proven display/touch/audio/PMU-key path". S2:981 final: "Hardware: the SDK's proven board, audio, power-chip and display code"; "code derived from the SDK lives only in rabble_gadget/apache/, rabble_axp2101/ and bsp/".
- Gadget-Port.md (written S2:937): "ported from the Apache-2.0 parts of Meta's gadget SDK"; "Upstream authorship stays as low-key as the license allows".
- Words "fork", "base" (other than Mark's "base code"), "rewrite later": no use found in S1/S2 as a plan. The "rewrite" came later (see 6).

## 6. Later sessions (cheap check only)

- 2026-10-16..20 sessions 7007b2eb (S256 W0/W1), b8152139 (W2), 17c422dd (W3): Mark: "run the pocket clean room work, do implementation using sonnet agents" (7007b2eb:10). Spec-writer sub-agents were Sonnet 5.5 that "read the originals and the SDK"; implementer sub-agents were fresh, got spec + BRIEF in a clean export workspace ~/RaBbLE-Cleanroom/pocket (cleanroom/PROVENANCE.md). Overlap measured against SDK b139b45; first-pass results noted "likely training recall" for rabble_lv_mem 100% and board.c 46% (PROVENANCE.md W0 row). S252 inventory (Clean-Room-Plan.md lines 29-60): ~3,000 of 4,600 substantive lines (65%) still matched upstream after the S243 port, with per-file figures used in the table in section 2.
- Gadget-Port.md header banner (W7, 2026-10-25) says apache/ and LICENSE-APACHE were removed, NOTICE lists no derived code, and the SDK copy deleted. I did not read these three later transcripts beyond keyword hits.

## Not determined
- Whether any apache/ file was changed after S243 other than what the transcripts list (git history would show; I only used 42ae6d9 stat).
- Exact textual overlap of rabble_ui.c, rabble_beam_score.c, rabble_wifi.c, rabble_setup.c with the SDK; only S252 figures exist for the apache/ ones. accord/ files were not in the S252 measurement.
- Whether the first five lines of Mark's mid-turn messages S2:278/566 were answered inline (they were handled in assistant turns at S2:264-265 and S2:575-581).
- No SDK-derived content beyond the SDK Apache-licensed sources is evident; whether training-data recall influenced hand-written files cannot be established from transcripts.
