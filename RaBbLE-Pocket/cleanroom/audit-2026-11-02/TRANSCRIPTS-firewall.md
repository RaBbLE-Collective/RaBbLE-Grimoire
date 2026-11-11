# Pocket clean room: transcript and workspace firewall audit (2026-11-02)

Scope: did the implementer (I) firewall hold? Read-only. Evidence: 32 JSONL transcripts in `~/RaBbLE-Cleanroom/transcripts/`, 8 workspaces `~/RaBbLE-Cleanroom/pocket{,-w1..-w6,-w6r2}`, Pocket `ops/cleanroom-audit.py` (recovered copy in the workspaces), Grimoire `PROVENANCE.md`. Facts only. My throwaway scripts lived in `/tmp/aud/`; nothing in the Collective or Cleanroom was modified.

## 1. Headline

- No implementer transcript contains a Read, Grep, Glob, ls, find, cat or git call that returned content from `apache/`, the original `rabble_axp2101`, the original `bsp/`, `muse-gadget-sdk`, `firmware/backups/`, `third_party/`, the Pocket repo's git history, or the Grimoire Gadget-Port / Muse-SDK-Map / session-log / handoff docs. I checked every tool_use input in all 16 implementer files (371 calls incl. handbacks) with three independent passes (taint-word regex on inputs, path-escape check on inputs, taint-signature regex on all tool results) plus the repo's own audit script.
- One attempted access that returned nothing: `w3/beam-impl.jsonl` L24 `ls apache | head -30` (inside pocket-w3) returned `ls: cannot access 'apache'`.
- Every file Read outside the workspace was a harness-saved copy of the implementer's own brief or spec (`~/.claude/projects/-home-rabble-RaBbLE-Collective/<sid>/tool-results/*.txt`); results contain only spec text.
- Real exposure exists at the context level, not the tool level (section 4): every implementer started with the Collective `CLAUDE.md` + `MEMORY.md` loaded (about 27-29 KB), and several saw spec files that name original files and one private identifier.
- Workspaces are clean of original files and original git objects (section 5). Their `firmware/NOTICE` and `firmware/CONTEXT.md` name Meta, `apache/` and `muse-gadget-sdk` as existence statements only.

## 2. Verdict table per wave (breaches: none / minor / material)

| Wave | Tool-level breach by I | Context / input exposure | Verdict | Key citations |
|---|---|---|---|---|
| W0 seam + state | none | CLAUDE.md+MEMORY in context; harness cwd = Collective root | none | impl-seam L1-154, impl-state L1-67; audit 0 flagged |
| W1 adpcm, console-setup, text | none | declaration-only interface extracts of settings/wifi/beam/beam_priv/voice (not own modules); golden vectors from original output | none | impl-console-setup L38, L42 read extracts; audit 0 |
| W2 axp2101, battery, input | none | battery implementer read the declaration extract of its own module (27 lines) | minor | `w2/battery-impl.jsonl` L22 `cat cleanroom/interfaces/rabble_battery.h` |
| W3 beam, store, settings, wifi | none (one failed `ls apache`) | extracts for settings/wifi/voice; none of the implementers opened its own (verified settings, wifi, store, beam) | none | `w3/beam-impl.jsonl` L24 (result: no such dir); `w3/wifi-impl.jsonl` L25, L88 |
| W4 audio, voice | none | audio extract read by voice implementer only (L26); audio implementer never touched interfaces/ | none | `w4/I-voice.jsonl` L26; I-audio no `interfaces` calls |
| W5 orbit part A, B | none | redesign: spec by tainted S266 parent (grep-read some `bsp/` lines per PROVENANCE); no spec transcript | none (spec provenance not auditable) | audit: 1 flag, benign (CMake comment edit, partB L380) |
| W6 rev 1 (5 rounds) | none | SEAM-SPEC.md names original file and one private array; firmware/CONTEXT.md read; spec + F transcripts absent | minor | `pocket-w6/SEAM-SPEC.md` L33, L77, L340-L347; impl L117 |
| W6 rev 2 | none | same SEAM-SPEC.md; Opus 5.5 implementer; F transcript present | minor | `pocket-w6r2/SEAM-SPEC.md` L33, L77; impl L82 result shows L33 text |

No wave rated material. "Minor" means original-derived names or declarations reached I through deliverables the process allows to be given (interface, seam spec), not through I opening a tainted path.

## 3. Per implementer transcript

Common to all: first event is a root user prompt (parentUuid null); last event is the tool_result of the `SubagentHandback`; every agentId unique; thinking blocks exist but their text is empty (redacted) in all 32 files, so reasoning is not auditable. cwd as recorded by the harness is `/home/rabble/RaBbLE-Collective` (the parent's launch directory) for the whole run in most files; every Bash call I checked begins `cd ~/RaBbLE-Cleanroom/pocket-wN...` or uses absolute workspace paths. After the first handback (rework rounds) the recorded cwd shows the coordinator's shell (`.../RaBbLE-Collective/RaBbLE-Pocket`, W6 r2 `.../firmware/bsp` L68-94 and `.../firmware/datasheets` L95-245, W6 r2 firmware L299+). Those are the coordinator's shell state; in each case the implementer's own calls kept `cd /home/rabble/RaBbLE-Cleanroom/pocket-w6...` first. The only calls with no `cd` into the workspace were: `/tmp/claude-1000/*.log` tail/sed (w6 r2 L110, L151), `~/.espressif/tools/activate_idf_v6.0.1.sh -e` (w0 seam L60), ESP-IDF greps (w2 input L56), and system library searches `ls /usr/lib64 | grep tsan; find /usr/lib/gcc ...` (w0 state L43) and `find / -name "libtsan*" -not -path "*/proc/*" | head` (w0 state L47). The last ran from the Collective cwd; its visible result lists only flatpak and `/usr/lib/gcc` paths. Whether `find /` traversed the Collective is not recorded; nothing from it was returned.

Columns: (a) tainted touches; (b) tainted content returned; (c) cwd; (d) interface/extract; (e) model; (f) completeness. Session = parent session id.

| Transcript | (a) tainted touches | (b) content returned | (c) cwd | (d) extracts | (e) model | (f) |
|---|---|---|---|---|---|---|
| w0/implementer-seam (37 calls, sess 7007b2eb, 2026-10-16 09:46-09:53, 154 lines) | none. L20 `git log --oneline` in pocket workspace repo. L25 Read of tool-results copy of its brief/spec | spec text only (names `apache/rabble_*.h` as files to be replaced; workspace CMakeLists comment mentions `apache/`, L22) | recorded Collective root, then Pocket from L140 (coordinator) ; commands use `cd ~/RaBbLE-Cleanroom/pocket` | none | claude-sonnet-5-5 | complete, 2 handbacks (rework round L138, L153) |
| w0/implementer-state (14, 7007b2eb, 09:46-09:49, 67 lines) | L19 Read of saved brief copy; L43/L47 `find` for libtsan (see above) | spec text only | Collective root recorded, commands to workspace | none | sonnet-5-5 | complete |
| w1/implementer-adpcm (8, 7007b2eb, 10:11-10:13, 43) | none | spec text ("Files to be replaced: apache/rabble_adpcm.*") | ok | none | sonnet-5-5 | complete |
| w1/implementer-console-setup (18) | L19 Read saved spec copy; L74/L78 `git show` on the workspace git (HEAD~1 of its own commits) | spec only; git output is its own commits | ok | read/compiled against settings, wifi extracts (L38, L42); declaration-only, comments stripped; not its own modules | sonnet-5-5 | complete |
| w1/implementer-text (24) | L25 Read saved spec copy; 3 scratchpad uses (own test dbg) | spec only | ok | none | sonnet-5-5 | complete; 35 h gap (L96 stream cut-off retry 2026-10-17T21:02), same agentId, same task |
| w2/axp2101-impl (11, b8152139, 2026-10-20 05:24-05:27, 54) | L19 Read saved spec copy; L24 `ls firmware/components/rabble_axp2101` (result: no such dir in the pre-swap workspace) | spec only; spec L62-63 text includes "references `firmware/bsp`" instructions | ok | extracts listed (L23) only | sonnet-5-5 | complete |
| w2/battery-impl (28, 05:24-05:31, 119) | L19 Read saved spec copy. L22 read `cleanroom/interfaces/rabble_battery.h` | spec; extract (struct `rabble_battery_t` fields, 9 prototypes, no comments) of its own module | ok; coordinator Pocket cwd from L104 | yes, own module (minor) | sonnet-5-5 | complete, 2 handbacks (rework L102, L118) |
| w2/input-impl (30, 05:24-05:32, 128) | L22 Read saved spec copy; `ls cleanroom/interfaces` only | spec only | ok | listed only, none read of own | sonnet-5-5 | complete, rework |
| w3/beam-impl (16, 17c422dd, 2026-10-20 17:18-17:20, 71) | L24 `ls apache | head -30` in pocket-w3 | `ls: cannot access 'apache'` | ok | extracts not own; `cp interfaces/*.h` in a test script (L41/L52) copies, then restricted to not-yet-delivered modules | sonnet-5-5 | complete |
| w3/settings-impl (17, 17:18-17:25, 79) | none | spec/vector tsv only | ok; Pocket cwd from L67 (coordinator) | did not read interfaces/rabble_settings.h | sonnet-5-5 | complete, rework L65/L78 |
| w3/wifi-impl (23, 17:21-17:30, 96) | none | spec only | ok | L25 grep in interfaces/rabble_settings.h; L88 uses voice extract; "never the wifi one" comment in its script | sonnet-5-5 | complete |
| w3/wifi-store-impl (15, 17:18-17:21, 68) | `grep ... ~/esp` (ESP-IDF); L37 stray `echo` | spec only | ok | none | sonnet-5-5 | complete |
| w4/I-audio (36, 33f0e544, 2026-10-22 06:22-06:33, 211) | none | spec only | ok; coordinator Pocket cwd from L201 | never opened interfaces/rabble_audio.h | sonnet-5-5 | complete, 3 handbacks (L166, L199, L210) |
| w4/I-voice (38, 06:22-06:38, 233) | none | spec only | ok; Pocket cwd L205+ | L26 `cat interfaces/rabble_audio.h` (audio extract, 19 lines, comments stripped; not its module) | sonnet-5-5 | complete, 2 handbacks |
| w5/partA-renderer (58 blocks, 45 unique calls, b248cb34, 2026-10-22 20:44-20:54, 241) | none | spec only; brief says "never at an `apache/` directory (some older tests do: don't copy)" | ok | none | sonnet-5-5 | complete |
| w5/partB-controller (76 blocks, 73 unique, 20:44-21:13, 433) | L380 edits workspace `CMakeLists.txt` whose comment names `apache/` (audit's one flag); L19 saved spec text states the author never read `apache/rabble_settings_ui.*`/`rabble_keypad.*` beyond headers | spec only | ok | none | sonnet-5-5 | complete |
| w6/implementer (76, 5dc82cff, 2026-10-23 00:54-01:13, 428) | audit 4 flags, all the workspace's own `firmware/bsp/` (new files) and a commit message. L117 `cat firmware/CONTEXT.md|README.md` in workspace | returns "Vendor reference code (Waveshare's demo repo, the Meta SDK, flash backups) lives in ../third_party/" and "bsp/ Still Apache-derived": existence only. L141-151 read ESP-IDF `esp_lcd` public source | ok | SEAM-SPEC.md and SPEC.md in workspace | sonnet-5-5 | complete, single handback |
| w6/implementer-r2 (41, 9ee39618, 05:08-05:41, 245) | audit 8 flags, all workspace `firmware/bsp`. CO5300 datasheet via pdftotext (public) | none tainted | commands absolute; recorded cwd moves to coordinator's Pocket `firmware/bsp` (L68) and `firmware/datasheets` (L95) | none | sonnet-5-5 | complete; 4 handbacks = rounds 2-5, matches the "five rounds" claim |
| w6r2/implementer (55, cf79d728, 2026-10-24T22:35 to 10-25T01:57, 332) | audit 3 flags, workspace `firmware/bsp`. L121-136 `find ~/esp`, ESP-IDF source reads | L82 result quotes SEAM-SPEC.md lines (see section 4) | recorded Collective root, Pocket/firmware from L299 | SEAM-SPEC.md, SPEC.md | claude-opus-5-5 (plus `<synthetic>` harness messages), as PROVENANCE says | complete, 2 handbacks |

Existing audit tool: `ops/cleanroom-audit.py` was deleted from the Pocket repo (`984c554`, S279); identical copies (md5 6a36fd86...) remain in `pocket-w3`, `pocket-w5`, `pocket-w6r2`. Run read-only as `python3 -I <copy> <transcript...>` with no flags. It reads only tool_use inputs, ignores prompts, tool results, `.claude/projects/` paths, `/tmp/claude-*` and anything under the workspace path. Results: 0 flagged for W0-W4 and w5/partA; w5/partB 1; w6 4; w6/r2 8; w6r2 3. All flagged calls are the workspace's own `firmware/bsp` (or the CMake comment). Its call counts equal PROVENANCE's for W0-W4, W5 (58+76 are raw blocks including 13+3 duplicated copies in `api-request-blob` events) and W6 r2 (55). Limitations: it cannot see results, so it would not catch a command that returned tainted content without naming a tainted word; my results scan covers that.

## 4. Exposures that are not tool calls

C1. All 32 transcripts include an `instructions` attachment (27.4-29.3 KB) containing the Collective `CLAUDE.md` and `MEMORY.md` index. It contains lines such as "Pocket Muse SDK bring-up (S242) ... Muse = text-only push-to-talk bridge, good BSP reference" and "Pocket gadget port ... FW = RaBbLE gadget (IDF v6.0.1, apache/ vs accord/)". These are descriptions, not code. The implementer prompts told them to ignore that context (w0 seam prompt: "regardless of what other context (CLAUDE.md, memory notes) you were started with"). Whether the model drew on it is not determinable.

C2. Interface extracts (declaration-only, comments stripped, header says "never copy into a deliverable"): W1 `interfaces/` rabble_beam.h (51 lines), beam_priv (18), settings (50), voice (13), wifi (48); W2 adds rabble_battery.h (27); W4 rabble_audio.h (19). Fields and prototypes are the original's. Own-module read: only `w2/battery-impl` L22. Otherwise not read, per transcripts.

C3. Golden vectors (W1 adpcm/text, W2 battery/input, W3, W4): outputs from running the original. The generators are kept out of the workspaces (PROVENANCE, `gen/`). Output data only.

C4. Seam spec (`SEAM-SPEC.md`, identical in pocket-w6 and pocket-w6r2, also `SPEC-w0-seam.md` in W0/W4 workspaces) contains original-code vocabulary: L33 `s_drender_us[RABBLE_UI_CORE]` (a private array name) and "the panel send task ... moves it to this minus 1 or plus 1 depending on the direct-draw mode"; L77, L340, L341, L347 name `bsp/rabble_lcd_bands.c/.h` and the alias `rabble_lcd_direct_t`; L335 lists original files using the seam. The w6r2 implementer received it (L82 result prints L33 and L34). PROVENANCE W6 says the first run had "the original's private names for the send-task call objects and the PMU flag".

C5. Rework messages name lines of the implementer's own code that matched upstream and sometimes hint at the original's shape (e.g. w0 seam L140: 'the "try PSRAM, else libc" ternary returns'; w2 battery L104 lists `MAX_LOCKS` `mode_us`). They do not quote original code.

C6. Specs name originals by path (`apache/rabble_input.c`, `rabble_settings_ui.c`, `rabble_lcd_bands.c`) in "files to be replaced"/callers lists: `w2/SPEC-w2-battery.md` L15, L16, L76, L78, L262; `w3` specs L3, L46-51, L92-98, L97-99; `SPEC-w0-seam.md` L3, L335-L348.

## 5. Workspaces

For each of pocket (W0), -w1 .. -w6, -w6r2: git repo present, 3-10 commits, all authored locally by Mark McConachie, first commit "clean room base".
- No `apache/`, `muse*`, `backups`, `third_party`, `cleanroom-overlap.py` anywhere (excluding `.git`). `rabble_axp2101` exists in pocket-w2/-w3/-w6/-w6r2 as the W2 clean module (own commit 7de5408). No `bsp/` originals: pocket-w6 base has only `bsp/CMakeLists.txt`, `idf_component.yml`; pocket-w6r2 base has rev 1's clean `bsp_display.*`, `bsp_perf.h`, `bsp_texture.c`.
- `git log --all --name-only` in every workspace shows no `apache/`, `rabble_lcd_bands`, `cleanroom-overlap` or `muse` paths; the only `-S"Meta Platforms"` hits are in `firmware/NOTICE` (base commits; c86e8a4 in w1 touches it).
- `grep -rIl "Meta Platforms|Jollybot|Facebook"` outside `managed_components/build/.git`: only `firmware/NOTICE` (states Meta copyright and the three Apache-derived directory names). No Jollybot anywhere.
- `grep -rIli muse`: `firmware/CONTEXT.md` (line 17: "`muse-gadget-sdk/` — gitignored vendor/reference clones"), `ops/cleanroom-audit.py` (pocket-w3, -w5, -w6r2: the taint regex), `BRIEF.md` (pocket-w6, -w6r2: the "never open ... muse" rule), `cleanroom/RaBbLE-Pocket-Beam-Protocol.md` L69 in pocket-w4 ("what the Muse gadget couldn't do"). pocket-w4 omitted `firmware/CONTEXT.md`, as PROVENANCE says.
- `ops/cleanroom-audit.py` (integrator tool) was present in pocket-w3, -w5, -w6r2 workspaces; no implementer transcript calls it.
- `interfaces/` extract directories: w1 (5 files), w2 (6), w3 (3: settings, voice, wifi), w4 (1: audio); all 13-51 lines, one comment line, no bodies.

## 6. Spec-file leakage flags (flag only, no judgment)

Measured on the workspace copies (what I received). Heuristics: fenced code blocks of at least 8 lines, lines with 3 or more hex literals, numbered step lists, `#define`/`static` lines, original file names.

- `pocket-w5/cleanroom/SPEC-w5-orbit.md` L33-74 (42-line C block: `#define NL_GLASS_SPRITES 16`, `NL_ORBIT_ITEMS 40` ...) and L228-236 (prototypes): this is a new design by Mark/S266, not mirrored from an original.
- `pocket-w1/cleanroom/SPEC-w1-text.md` L23-35 and `pocket-w3/cleanroom/SPEC-w3-settings.md` L34-48: enum declarations with "value N" comments (interface; public API).
- `pocket-w2/cleanroom/SPEC-w2-axp2101.md`: 20 lines with 3+ hex values (L29, 67, 88, 89, 107, 109, 110, 112, 119, 139, 157, 183, 223, 236, 238, 239, 242, 243, 251, 257), each carrying datasheet section references (register addresses and bit fields). Step lists at L139+ ("Otherwise write 0x49 with exactly the observed key bits ...") are behavioural.
- Step lists: `SPEC-w0-state.md` 95 numbered lines; `w6 SPEC.md` 77 (rev 2: 90) numbered lines; `w6 SPEC.md` rev 2 header L3 says F "rephrased passages that echoed the original's comments and log strings, rewrote the band-path ..."; `SPEC-w1-text.md` 80; `w2 input` 55; `w1 console-setup` 55. Not verified against the originals (I did not read the originals).
- Tables: `SEAM-SPEC.md`/`SPEC-w0-seam.md` 166 table rows; `w3 settings` 136; `w2 battery` 122; `w1 console-setup` 120; `w2 input` 111; `w2 axp2101` 104; `w4 voice` 105. They are mainly name/value/behaviour tables for seam fields, log strings and vectors.
- Original names: `SEAM-SPEC.md` L33 (`s_drender_us`), L77, L340-341, L347 (`rabble_lcd_bands`); `w2 battery` L15-16, L76, L78, L262 (`apache/rabble_input.c`, `rabble_settings_ui.c`); `w6 SPEC.md` L3/L5 (describes S268/S276 reading `firmware/bsp/rabble_lcd_bands.c`).
- No `s_` prefixed identifiers elsewhere in the specs. No spec has a code block that is function-body-like.
- PROVENANCE records the overlap measurements: first passes 10-46% on seam, battery, input, settings, voice, W6 r2 (11.4%); the integrator attributes these to "training recall" of private names. That is an outcome measure of leakage from the model or the specs; the transcripts cannot separate the two.

## 7. Coverage of the archive and PROVENANCE claims

| Wave | Implementer transcripts | Spec / firewall transcripts | PROVENANCE sessions absent from archive |
|---|---|---|---|
| W0 | 2 (seam, state) | spec-seam, spec-state | S256 parent "firewall" (Opus 5.5 parent turns) not in archive; the parent is not a sub-agent file |
| W1 | 3 | 3 spec | parent firewall turns |
| W2 | 3 | none (spec authors for axp2101, battery, input) | 3 spec-author sub-agents, S258 parent firewall |
| W3 | 4 | 4 spec | parent firewall; the radio spec author's resume is within wifi-spec (107 lines) |
| W4 | 2 (I-audio, I-voice) | S-audio, S-voice | parent firewall |
| W5 | 2 (part A, B) | none (spec written by the S266 parent; independent Opus reviewer) | S266 parent spec session and the Opus 5.5 reviewer |
| W6 rev 1 | 2 files covering 5 rounds | none: S268 spec author and "S268 F (Opus 5.5 sub-agent)" absent | spec author, firewall reviewer |
| W6 rev 2 | 1 | `firewall.jsonl` (F, Opus 5.5 sub-agent, 98 lines, read-only, no writes) | S276/S277 parent spec session (rev 2 author) |

PROVENANCE implementer claims are consistent with the archive: model (Sonnet 5.5 everywhere except W6 rev 2 Opus 5.5), rework rounds (W0 seam 2, W2 battery and input 2 each, W3 settings 2, W4 audio 3, W4 voice 2, W6 rev 1 five rounds across two files, W6 rev 2 two), tool-call counts, and dates. The W5 audit text in PROVENANCE reports 58 and 76 calls; unique calls are 45 and 73 (the remainder are duplicated blocks in `api-request-blob` events). The "no overlap-script or SDK in workspace" statements match the filesystem. PROVENANCE does not mention the W1 text implementer's 35 h pause or W2 battery's read of its own extract.

## 8. Could not determine

- Reasoning: all thinking text is empty (signature only), so I cannot say whether an implementer reasoned from recalled original code or from the CLAUDE.md/MEMORY index.
- Whether `find / -name libtsan*` (w0 state L47) walked the Collective; output is truncated to `head`.
- Parent-session (coordinator, integrator) turns are not in the archive, so what was said to I beyond its first prompt and the mid-task coordinator messages is unknown for W0-W5; I read the rework messages in W0, W2, W3, W4 and W6 (they contain no original text).
- The original contents of vectors and the spec-vs-original similarity (I did not read the originals or SDK; the SDK copy was deleted S277). Spec leakage flags are structural only.
- Whether the workspace `SPEC-*.md` copies are the post-firewall versions of the Grimoire specs (I did not diff against Grimoire).
- Whether any implementer's saved harness copy (`tool-results/*.txt`) held more than the spec; I checked the tool results that referenced them, not the files themselves.
