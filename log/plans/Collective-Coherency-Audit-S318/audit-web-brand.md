# Coherency audit: web variants + brand mark
GoBbLE (scout) · 2026-11-06 · READ-ONLY (no repo file edited; scratch in /tmp/rabble-crew/web-audit/)
Method: plain GETs to public hosts, sha256 of served assets vs `git show <branch>:<path>` and vs built dist files, `git ls-files`/`git status`, grep for hex literals and name casing, ImageMagick render of the two vector masters and icons for visual check. No logins, no forms.

Verdict: 10 hosts probed, 6 serve a web page. Prod (joinrabble.world) serves a frozen pre-S203 build, and the install routes are 404 there. The published NeBuLA v0.0.0.1-rc.1 is an older build than the current, unlabelled dist/nebula.iife.js. The brand mark exists in 9 rendering families and ~360 mark-bearing files, with 19 redundant icon copies and 73 SDDM copies of Plymouth frames. 355 distinct off-palette hex values sit in brand-facing paths.

---------------------------------------------------------------
## 1. WEB VARIANTS

### 1.1 Surface map (what is live, what it serves)

| # | Host | Serves | Evidence |
|---|---|---|---|
| S1 | joinrabble.world (prod) | World tree equal to commit e7e5b51 (2026-06-20), not main. index.html identical to 2f6c044 and e7e5b51. unified/panels/config/stage/curator/NeBuLA hashes match e7e5b51. Worker `rabble-collective` (wrangler.jsonc). | index sha = 2f6c044 = e7e5b51; prod-assets/*; World `git log --all -- index.html` |
| S2 | dev.joinrabble.world | World new-horizons HEAD tree (NH). index identical to NH e55636c. config 61b31b8f, NeBuLA 267da691, theme c813456b, face.css 6be8ddf8, face.js 5d933112, curator 9d8624c9 all equal NH. Router Worker rabble-dev -> rabble-world-dev (registry). | dev-assets/*; `git show new-horizons:...` |
| S3 | chrysalis.joinrabble.world | Chrysalis main 14789ad. Chrysalis-Web/index.html identical. Worker rabble-chrysalis-web. | sha match |
| S4 | joinrabble.world/chrysalis/ (legacy mount) | Stale page, 6859 B, `<title>RaBbLE-World · the liminal [chrysalis]`. Dev 301s this path to S3 (registry S249 D4). | curl 200 |
| S5 | xperimental.joinrabble.world | Xperimental new-horizons 9f4383c. index identical to Xperimental-Web/index.html. | sha match |
| S6 | scribble.joinrabble.world | ScRiBbLE new-horizons 31cb5c9. Page refs match tree paths (not hash-diffed). | curl + tree |
| S7 | aether.joinrabble.world | Versioned only (root 404). /v0.0.0.1-rc.1/aether.min.css = Aether dist/v0.0.0.1-rc.1 (fafd5d90). /v0.0.0.1-rc.2/aether.min.css = dist rc.2 (4e158fb0). Non-min rc.1 also 200. | sha match |
| S8 | nebula.joinrabble.world | Versioned only (root 404). /v0.0.0.1-rc.1/nebula.iife.js = NeBuLA dist/v0.0.0.1-rc.1 (28ecc959). rc.1 esm 200. /latest/ 404 and rc.2 404. | sha match |
| S9 | score.joinrabble.world | sCoRE API, not a web variant. /health 200 {"status":"ok","entity":"RaBbLE","version":"v0.0.0.0"}. Root 404. | curl |
| S10 | grimoire.joinrabble.world | Root 404. Registry still says status unknown. | curl |

Install and route probes (GET):

| Path | prod | dev | Source of truth |
|---|---|---|---|
| /setup.sh | 404 | 302 to raw GitHub (200) | World `_redirects:2` (new-horizons only) |
| /RaBbLE-OS.ks | 404 | 302 to raw GitHub (200) | World `_redirects:3` |
| /roadmap | 404 | 302 to Grimoire | World `_redirects:4` |
| /os.html, /world/os.html | 404 | 200 / 307 | dev only |
| /chrysalis | 307 to /chrysalis/ (S4) | 301 to S3 | registry S249 |

CLAUDE.md "Session Start" one-liner `curl -fsSL https://joinrabble.world/setup.sh | bash` fails against prod right now (404).

### 1.2 Branch comparison, RaBbLE-World
- origin/main = e7bcca7 "main stub" (README, LICENSE, .gitignore only; no deploy.yml, no world/ tree).
- new-horizons = main + 157 commits. `git rev-list --count new-horizons..main` = 0. The merge base is e7bcca7. Intentional (memory: main = release, air merge pending).
- Backup tags backup/world-pre-rewrite, backup/world-flatdate-S104 and v0.0.0.0.10 hold older index.html variants (afd0979e, 18869b36). Not served.

### 1.3 Divergences

Severity: H = visible to public or breaks install. M = drift that will bite at air. L = cosmetic or doc.

| ID | Sev | Location | What diverges | Which side is correct | Intentional? |
|---|---|---|---|---|---|
| W1 | H | S1 index.html (served) vs S2 index.html (NH) | Prod = pre-S203 "one living surface" (5 movements, RaBbLE-theme/unified/floor/panels css, no RaBbLE-face). Dev = entity-first face (RaBbLE-face.css/js). | Dev is the EP1 face (memory project_ep1_web_face_v1, S276). | Partly. Known that prod waits for "first deploy from stub main". Not recorded in registry/subdomains.yml. Prod is stale. |
| W2 | H | S1 (prod) | /setup.sh, /RaBbLE-OS.ks, /roadmap are 404 on prod. `_redirects` exists only on NH (World `_redirects:1-4`). | NH `_redirects`. | No. Accidental: prod is not from NH. Breaks CLAUDE.md install one-liner. |
| W3 | H | NeBuLA: nebula CDN v0.0.0.1-rc.1 (S8), NeBuLA dist/v0.0.0.1-rc.1/nebula.iife.js (28ecc959, 68969 B), World prod js/RaBbLE-NeBuLA.js (28ecc959), Chrysalis ep1 js/RaBbLE-NeBuLA.js (28ecc959), ScRiBbLE CDN pin. NeBuLA dist/nebula.iife.js root (267da691, 216697 B) = World NH js/RaBbLE-NeBuLA.js = dev. | The published v0.0.0.1-rc.1 is an older build than the current unlabelled dist/nebula.iife.js. Both bundles self-report internal version "0.0.0.0". Prod, ScRiBbLE and Chrysalis run the old build. Dev runs the new one, which is not published under any version path. | Root dist (newest). The rc.1 label was not bumped on rebuild. | No. Accidental. |
| W4 | M | World config.js:46 `set('RABBLE_NEBULA_URL', ...)` | Dead config. No World file reads RABBLE_NEBULA_URL (grep: only config.js). World always loads NeBuLA from a local vendored copy. | n/a | Accidental. |
| W5 | M | Aether pin: World prod config.js:22 = rc.1; World NH config.js:22 = rc.2; ScRiBbLE config.js:17 + aether-loader.js:11 = rc.1; Chrysalis ep1 config.js:22 = rc.2 | Four pins across three members. Commit 543ed6e says "Aether pinned to rc.2 (askbox/statusbar now published)". rc.1 CSS has no .rabble-askbox or .rabble-statusbar (rc.2 has them). Dev uses 6 askbox/statusbar hits; prod uses 0. | rc.2 is the current pin. | Partly. The prod pin predates 543ed6e and was not bumped. ScRiBbLE pin is unexplained. |
| W6 | M | Chrysalis-Web/ep1/world/css/aether.css (7c9a..., 43929 B) | Vendored Aether that equals neither dist rc.1 (2363965f, 43883 B) nor rc.2 (45d690e5, 68256 B). No HTML/JS in ep1 references it (grep empty). Orphan. | n/a | Accidental orphan. Chrysalis is a reliquary, so the stale file may be kept on purpose, but it is not referenced. |
| W7 | M | Chrysalis ep1 world/js/RaBbLE-face.js (3748c252) and css/RaBbLE-face.css (205add99) vs World (5d933112, 6be8ddf8) | Archived copy of the S203 face. Differs from World NH. | Reliquary. | Intentional archive, but undocumented in the Chrysalis README. |
| W8 | H | Aether token layer, consumed by World theme.css:30 `--bg: var(--rabble-void, #03000b)` and :39 `--text-dimmer: var(--rabble-dimmer, #3d3860)` | Aether publishes --rabble-void:#03000b and --rabble-dimmer:#3d3860 in both rc.1 and rc.2 min CSS. Neither is in RaBbLE-Palette.md. Palette Deep Void is #0a0010. Aether/assets/palette/rabble-palette.json also sets "void": #03000b and points its "source" at RaBbLE-Grimoire/common/RaBbLE-Palette.md (path does not exist). | Palette.md (#0a0010). Candidates doc decision of record (S234): swap off-palette values to canonical. | No. The decision of record is not applied at the token layer. Mark decides whether #03000b becomes a named palette entry. |
| W9 | H | World CSS hex rule (Mark: World CSS holds no hex and no font stacks; Aether tokens only) | theme.css: 15 hex lines (21-27, 30-34, 37-39). unified.css: 13 hex lines (10-17, 20-26). os.css:83 hard font stack `var(--font-hero, 'Orbitron', 'Exo 2', sans-serif)`. theme.css:42-46 font stacks as fallbacks. unified.css:35-36 fallbacks 'JetBrains Mono','Fira Code' and 'Inter'. Non-brand: linear-gradient(#fff 0 0) mask lines in os.css:192,303,370 and panels.css:374. | Rule (no hex, no stacks). | No. Accidental. The .rc-* alias layer (unified.css) is already on the backlog. |
| W10 | M | Font fallback vs Aether tokens | Aether publishes Share Tech Mono / Exo 2 / Orbitron (rc.1 and rc.2 identical). World unified.css fallbacks name Inter and JetBrains Mono. Effective font = Aether when Aether loads. When aether.js fails (banner, data-aether="failed"), World falls back to Inter and JetBrains Mono, not the brand fonts. | Aether tokens. | No. |
| W11 | M | theme-color and manifest colours | theme-color #0a0010 on prod, dev, ScRiBbLE. #03000b on chrysalis and xperimental index (line 6-7). World manifest.json background_color and theme_color = #03000b; ScRiBbLE manifest = #0a0010. World icons/README.md:6 recommends #03000b bg. Actual icon-512 corner pixel = #000000. | Deep Void #0a0010 (Palette.md). | No. Drift. |
| W12 | M | Icon set (one set, hash-identical across World icons/, ScRiBbLE icons/, Chrysalis ep1/icons/, Xperimental icons/ partial) | Art is a raster "RaBbLE-OS" lockup with the wordmark "RaBbLE-OS". Used as favicon, PWA icon and og:image for the whole Collective. At 16 px it renders as an illegible dark smear (checked). World icons/README.md says "RaBbLE particle/entity logo". | Mark decision (proposal Q1/Q2). | Unknown. Not recorded as intentional anywhere I read. |
| W13 | M | OG tags | Only xperimental.joinrabble.world has og:* (5 tags, index.html:7-11, og:image = icon-512 lockup). Prod, dev, chrysalis and scribble have none. | n/a | Drift. |
| W14 | M | Legacy /chrysalis/ mount on prod (S4) | Serves the 6.8 KB liminal page. Dev redirects it to S3. | Dev/registry (S249 D4). | Accidental (prod never redeployed). |
| W15 | L | Em dashes in web copy (memory rule: avoid em dashes in web copy) | prod index.html:11 meta description and manifest name "RaBbLE — Boundless Behavioral Learning Engine". ScRiBbLE title (index.html:6) and manifest name. Chrysalis visible copy (e.g. lines 278, 290, 293, 313, 332, 359, 379) and meta line 8. Dev meta uses a colon. | Dev. | No. |
| W16 | L | Name casing in copy (see section 2.4) | Xperimental index.html:151 link text "scribble". Xperimental drops/20261013-pocket-entity/index.html:758 SVG caption "RABBLE ENTITY · NEBULA POSES ON POCKET". NeBuLA specs/visual-spec.md:35 "**Nebula**". | Canonical case. | No, unless the caps are a deliberate style (check drop CSS). |
| W17 | L | Doc drift: registry/subdomains.yml:14 | Says prod = "Worker rabble-collective; deploy-prod on World main". World main has no deploy.yml and is a stub, so deploy-prod cannot run. The live prod was not built from main. | Live state. | No. |
| W18 | L | Grimoire RaBbLE-Collective/RaBbLE-Deployment-Architecture.md:65,68 | Describes dev as `wrangler deploy --env dev` on a "world-dev" Worker (S139 concept). Actual: wrangler.dev.jsonc + Router Worker rabble-dev. | Live state. | Labelled concept, but still wrong. |
| W19 | L | Grimoire RaBbLE-Collective/RaBbLE-CICD-Plan.md:15-17 | Says Aether and NeBuLA deploy on push to main. Aether main = b7facee (AGENT, CONTEXT, RaBbLE-OS_ICON.png only). NeBuLA main = 8e5a125 (LICENSE, README). Neither has a deploy workflow on main. | n/a | Doc ahead of code. |
| W20 | L | Stale CDN paths in docs | RaBbLE-World/gist/RaBbLE-Collective-Overview-gist.md:40-41 and Grimoire RaBbLE-World/RaBbLE-World-Page-Template.md:32,59 cite .../v0.0.0/. Grimoire RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md:386 cites nebula .../latest/ (404 live). | Versioned paths in config.js. | No. |
| W21 | L | Aether/package.json:11 `cast` script | Copies dist to ../RaBbLE-World/aether/v0.0.0.0/. World has no aether/ directory. Aether package.json version = 0.0.0.0 while CDN serves rc.1 and rc.2. Question for Mark: intentional (versioning rule: do not advance before EP1) or drift? | n/a | Question. |

Checked and fine: favicon.ico and icon sizes are byte-identical across all four icon hosts. manifest.json start_url and icons paths resolve. Titles are distinct per surface and follow "RaBbLE · X" (prod, dev, chrysalis, xperimental) or "ScRiBbLE — RaBbLE".

---------------------------------------------------------------
## 2. BRAND MARK

### 2.1 Canonical sources and claims
- Palette source: RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md. 13 core values plus 6 provider-mark values (brand_anthropic, brand_google_*, brand_openai). Candidates (non-canonical, decision of record S234 = swap): RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette-Candidates.md, 22 table rows plus 2 alternates in text.
- Spec: RaBbLE-Aether/assets/logos/rabble-portal-glyphs-spec.md (295 lines, self-described "canonical specification"). Uses off-palette particle colours (lines 114-128) and Exo 2 (line 240). Says geometry derives from `rabble-entity.js`; no such file exists in the Collective (find returned none).
- Vector master (neon): RaBbLE-Aether/assets/logos/rabble-portal-glyphs.svg (8fb83c, 3942 B). Rendered: magenta left glyph with shadow below, cyan right glyph with shadow above. Matches the spec.

### 2.2 Mark instances (grouped by rendering family)

Family A: neon vector master (1 file). Aether logos/rabble-portal-glyphs.svg. Off-palette: #009ab0, #0e0018, #aafffe, #bf0050 (4 values); candidate #1a0030.

Family B: mono "portal glyphs v5" vector (2 identical copies, 1 hash 674a410c). RaBbLE-OS/assets/RaBbLE.svg and RaBbLE-Grimoire/RaBbLE-Aether/assets/RaBbLE.svg. Rendered: white ovals with black outline and black shadows. Off-palette: rgb(20,20,19) (#141413), #000000, #ffffff. Title "RaBbLE portal glyphs v5", font-family "Anthropic Sans" (third-party font name inside the SVG). This is a different look from Family A, not a copy of it. Proposal step 3 says delete by pointer, which would delete the only mono master.

Family C: RaBbLE-OS lockup raster (icon set). 7 distinct hashes across 26 files:
- icon.png f7d9e8a9 (418 KB): RaBbLE-World/icons/icon.png, RaBbLE-ScRiBbLE/icons/icon.png, RaBbLE-Chrysalis/Chrysalis-Web/ep1/icons/icon.png, RaBbLE-Aether/RaBbLE-OS_ICON.png (also on Aether main).
- icon-512 9d4cb320: World, ScRiBbLE, Chrysalis ep1, Xperimental (4 copies).
- icon-192 a04d0c4f: World, ScRiBbLE, Chrysalis ep1, Xperimental (4).
- icon-48 8287834b: World, ScRiBbLE, Chrysalis ep1 (3).
- icon-32 d67f9412: World, ScRiBbLE, Chrysalis ep1, Xperimental (4).
- icon-16 0f894b1c: World, ScRiBbLE, Chrysalis ep1 (3).
- favicon.ico 49deac90: World, ScRiBbLE, Chrysalis ep1, Xperimental (4).
Instances: 26 binary files (+1 Aether copy, counted in icon.png) with 7 distinct hashes, i.e. 19 redundant copies. Art: "RaBbLE-OS" wordmark, cyan and magenta rings, white ovals. Corner pixel #000000. Not the Family A look.

Family D: Pocket face PNG (1 hash, 3 copies). RaBbLE-World/world/img/pocket-face.png, RaBbLE-Xperimental/prototypes/pocket-promo/assets/pocket-face.png, RaBbLE-Xperimental/prototypes/pocket-site/img/pocket-face.png (ad9ebbd2). Rendered: circular ring with node graph and two white-core ovals (cyan left, magenta right). Different again.

Family E: Genesis studies, history (12 files in Grimoire RaBbLE/Genesis/visual/, all mirrored 1:1 in RaBbLE-SiGiL/store/human/2026/ and indexed in RaBbLE-SiGiL/index/human/). Also BaBbLE reliquary/concept-art/branding/Logo_Eyes_Cyan_Magenta.png (= logo-portal-eyes-v1, 798d942d) and Logo_Text_Iterations_Cyan_Purple.png (= logo-wordmark-iterations, 587f8dfd). Plus OS sddm-theme/assets/entity.png (798d942d) = logo-portal-eyes-v1. So the SDDM greeter ships a study that the proposal calls "History, not production".

Family F: Plymouth and SDDM animation frames (raster, procedural from NeBuLA Boot.html).
- Plymouth: RaBbLE-OS/ansible/roles/boot/plymouth/files/rabble-aether/assets/wm-step-000..047 (48), frames/entity-0001..0096 (96), plus bar-fill, bar-track, bg-liminal, dot, panel, scanlines (6 assets). Duplicate hashes inside wm-step (e.g. 004 = 044; 007 = 041) are loop repeats, not drift.
- SDDM: RaBbLE-OS/ansible/roles/boot/session_manager/files/sddm-theme/assets/ holds 98 PNGs, 75 distinct hashes. 73 of those hashes equal a Plymouth file (wm-step-* and entity-idle-* = entity-00xx). bg.png 1.1 MB unique.
- GRUB: RaBbLE-OS/ansible/roles/boot/grub2/files/theme/grub-bg.png (unique). build-grub-bg.py generates it.
Plymouth build-assets.sh:90,105 bakes background BG = (2,0,11) = #02000b (off-palette, "measured").

Family G: text and ANSI art.
- Fastfetch (RaBbLE-OS/config/fastfetch/):
  - rabble-portals.base.txt (bc36..., 27 rows): uses 256-colour indices 51, 197, 135, 205, 60 (38;5;N) and bright white 97. Indices resolve to #00ffff, #ff005f, #af5fff, #ff5faf, #5f5f87 (xterm levels). None equals a canonical hex (cyan #00f5ff, magenta #ff2d78, violet #bf5fff). 205 and 60 are not on palette at all.
  - rabble-portals.txt (749a40, 18 KB): TRACKED AND MODIFIED in working tree (mid-edit). Truecolour SGR, about 250 distinct shades of the neon (for example 78143f, 066e7c, 1ef3fd). These are generated tints from fastfetch-fx.py; no palette rule covers them.
  - rabble-portals.compact.base.txt (e2c2..., 251 B, untracked). Uses indices 51 and 197.
  - rabble-portals.compact.txt (af5a..., untracked). About 90 distinct truecolour shades, including backgrounds such as 22f3fd, fc4889, f486b2.
  - rabble-portals.micro.txt (9f81..., 934 B, untracked). Truecolour, all six colours canonical (0a0010, ff2d78, 00f5ff, e8e6f0, ff79c6, bf5fff). This is the only fastfetch art that is on palette.
  - Generators: assets/generate_rabble_fastfetch.py, assets/generate_RaBbLE_ansi.py, config/fastfetch/spells/fastfetch-fx.py, spells/fastfetch-face.sh and spells/rabble-fetch (both untracked).
- RaBbLE-OS/assets/RaBbLE.ansi (ef0b97ac, 11.5 KB): indices 51 and 197 plus SGR 97. Differs from RaBbLE-OS/BaBbLE/asset_archive/RaBbLE.ansi (937646e9).
- ASCII: RaBbLE-OS/assets/RaBbLE_ascii.txt (b5309...) = BaBbLE/reliquary/concept-art/visual/RaBbLE_ascii.txt (identical). RabbLE_ascii_simple.txt (e24cfdca) is a separate wrong-case filename (see 2.4).
- asset_archive: 16 files (v0, v0.1, v0.1.1 and root), historical.

Family H: procedural renderers (code, not image files; palette set at runtime except where noted).
- sCoRE tui/rabble-face/src/{face.rs, micro.rs, canvas.rs, eyes.rs, degrade.rs, driver.rs}, tests/golden.rs, examples/show.rs, examples/export.rs (UNTRACKED). face.rs has zero hex literals; the palette is read from RaBbLE-Grimoire at runtime (rabble-theme/src/lib.rs:1-3). Test fixtures carry off-palette values: micro.rs:174 surface #101018 and magenta #ff2bd6; rabble-tui/src/app.rs:2168, 2265; widgets/face.rs:379; widgets/header.rs:223; theme.rs:162 dummy #000001..#000005.
- sCoRE tui/rabble-tui/src/widgets/face.rs (uses the same palette path).
- sCoRE crew/rabble.py: Crew banner colour #31c7d5 (candidate, not promoted).
- sCoRE ui/face.py: tracked, python micro mark drawn (commit 2def318, S303). No hex literals found by scan.
- NeBuLA src/backends/canvas2d/portal-system.js (3 off-palette hex), entity-mini.js (17), ambient-field.js (18), particle-system.js (13), alive-gl.js (2). NeBuLA src totals: 53 off-palette occurrences in 5 files.
- World js/RaBbLE-face.js and css/RaBbLE-face.css (structural; see W9 for the css).
- Chrysalis ep1 RaBbLE-Face.html, js/RaBbLE-face.js, css/RaBbLE-face.css (archive copies, see W7).
- Xperimental drops: 7 drops. 6 contain entity, portal or eyes markup. Art sandbox, scope of the palette rule not confirmed.
- Pocket firmware: core/rabble_core/include/rabble_palette.h (RABBLE_HEX_* canonical; RABBLE_HEX_BLACK 0x000000 with a documented AMOLED exception in the header comment, not in Palette.md). entities/RaBbLE/src/entity_face.h:34 ENTITY_ORB_WHITE 0xf8faff (candidate). entities/RaBbLE/src/scene.c:721,792 black background (same exception). entities/Foundling/src/foundling_face.c:12-23: WHITE 0xF5F5F5, WARN 0xFFB000, ERROR 0xFF4D4D, pastels mint A8E6CF, sky A7D8F0, lavender CDB4F6, peach FFCBA4, rose F8B4C8, lemon F7EDA0. None documented in Palette.md. Foundling is lore, not brand (memory), so decide whether it is in scope.
- Aether assets/theme/rabble-theme.css: "muted / lights-off" variant with 11 off-palette values (05050f, 080814, 0e0f1c, 141526, 1e1e30, b8b6c8, 6a6880, 3a3660, 8840cc, c42060, 009baa). 6a6880 is a near miss of canonical Muted #6b6880 (1 digit off). Not in the Candidates doc.
- Aether themes/_palette/aether-kvantum.map: maps Catppuccin to canonical (13 targets, all canonical). Aether themes/kvantum/ holds only README.md; the SVG is not in Aether. OS config/kvantum/RaBbLE-Aether/RaBbLE-Aether.svg holds 8 hex values the map can never output: 000005, 200040, 120025, 1a0030, 8860aa, 2a0050, e8d5ff, cc2060. So the deployed SVG was not regenerated from the map.
- RaBbLE-OS/assets/generate_wallpaper.py:16-18: BG = #0a0010 (ok), SURFACE = #120025 (off, canonical Surface is #12132a), PRIMARY = #ff2d78 (ok).
- RaBbLE-OS grub2/templates/rabble-tty-palette.sh.j2: slot 0-7 canonical; slot F bright-white = #ffffff (off; palette says never pure white).
- RaBbLE-OS config/themes/RaBbLE-Aether/gtk-3.0/gtk.css: CC0 upstream skeleton (radexgith Cyberpunk_Neon) with upstream Adwaita-style greys, Material colours and blue/green accents. Aether recolor pipeline covers Kvantum only (no GTK map). Count: 138 distinct off-palette values across RaBbLE-OS/config.

### 2.3 Colour audit numbers
- Off-palette (not canonical, not in Candidates), distinct across all brand-facing paths scanned: 355 values, 1562 occurrences. Scanned: World (world/, index, os.html), Aether (assets, themes, rabble.css), NeBuLA src, sCoRE (tui, crew, ui), RaBbLE-OS (config, assets, boot roles), Xperimental-Web, Chrysalis ep1, ScRiBbLE src.
- Per directory: RaBbLE-OS/config 138 distinct; Xperimental-Web 147; Chrysalis ep1 35; World/world 26; NeBuLA src 26; sCoRE tui 20 (includes test fixtures); Aether assets/theme 11; OS assets 3; boot roles 1 (#02000b).
- Mark + boot + icon set only (families A, B, D, H-ui/crew/face, OS fastfetch/assets, boot roles, World face): 28 distinct off-palette hex (31 occurrences) and 11 candidate-listed hex (14 occurrences).
- Candidate-listed hex seen in brand paths: 13 distinct (156 occurrences overall).
- Colour indices: 51 (#00ffff), 197 (#ff005f), 135 (#af5fff), 205 (#ff5faf), 60 (#5f5f87) used by fastfetch and RaBbLE.ansi. 205 and 60 are off-palette; 51 and 197 are near misses of cyan and magenta.
- Truecolour shades in rendered fastfetch: about 250 distinct (rabble-portals.txt) and about 90 (compact.txt). Only micro.txt is wholly on palette.
- Pocket: 9 off-palette 0xRRGGBB values in Foundling plus ENTITY_ORB_WHITE (candidate) and the 0x000000 AMOLED exception (documented in code, not in Palette.md).
- Not checked at pixel level: Plymouth/SDDM/GRUB PNG colours (no PIL in the environment, so only source text was scanned). The Plymouth script itself is canonical.

### 2.4 Name consistency (user-facing copy and assets; code identifiers excluded)
Correct: RaBbLE, sCoRE, NeBuLA, BaBbLE, ScRiBbLE. Live page titles and meta are correct on all five hosts.
Wrong case in user-facing copy or assets:
- RaBbLE-Xperimental/Xperimental-Web/index.html:151 `<a>scribble</a>` (live on xperimental host). Should be ScRiBbLE.
- RaBbLE-Xperimental/Xperimental-Web/drops/20261013-pocket-entity/index.html:758 SVG text "RABBLE ENTITY · NEBULA POSES ON POCKET". Check whether all-caps is a styling choice.
- RaBbLE-NeBuLA/specs/visual-spec.md:35 "**Nebula**".
- RaBbLE-NeBuLA/specs/rig/entity-rig.svg and entity-rig.json: "Nebula" in labels (not verified whether user-visible).
- RaBbLE-Chrysalis/Chrysalis-Web/JS-Xperiments (archive): 159 "Rabble", 87 "Nebula", 59 "babble", 13 "Babble" in code, docs and examples. Archived; reported for completeness.
Code identifiers only (not counted): ScRiBbLE `window.Scribble` namespace (RaBbLE-ScRiBbLE/src/js/*.js); NeBuLA bundle comments "Nebula haze"; World movements-data.js `babble` keys; Chrysalis threshold `BABBLE` array and `'babble'` channel.
Correct mapping in code: sCoRE crew.rs:25 `"babble" => "BaBbLE"`; OS generate_rabble_fastfetch.py:106 comment on deliberate mixed case.
Not swept: Grimoire prose, Pocket docs, ScRiBbLE docs. Mark asked for user-facing copy and assets, so flag if wanted.

### 2.5 Proposal check (RaBbLE-Grimoire/log/plans/Brand-Asset-Consolidation-PROPOSAL.md, untracked)
Verified present: the Aether spec and SVG, rabble-face micro.rs, NeBuLA portal-system.js, both fastfetch sets, OS assets, the Pocket C tree, and RaBbLE.svg duplicated in Grimoire.
Stale or wrong:
- Q3 (line 41) asks whether brand policy gates naming before "the lawyer step". Mark has ruled no lawyer review is needed, so Q3 is stale. The same lawyer dependency still appears in BLOCKERS.md:19 (B-21), in RaBbLE-Grimoire/log/plans/Sovereign-Accord-v2-Brand-and-Entity.md:16, 50, 81, 95, and in the proposal itself. I found no written record of the ruling in these files, so I am relying on Mark's message.
- "ui/face.py (pending, HANDOFF-S309)": ui/face.py is tracked and committed (2def318, S303). The claim is stale.
- "RaBbLE-Collective/RaBbLE-Brand-and-Entity-Policy-DRAFT.md": the file is at RaBbLE-Grimoire/RaBbLE-Collective/RaBbLE-Brand-and-Entity-Policy-DRAFT.md. Wrong path.
- Q1 "ANSWERED / implemented": the code is not committed. sCoRE tui/rabble-face/examples/export.rs is untracked. RaBbLE-OS spells/fastfetch-face.sh, spells/rabble-fetch and config/fastfetch/rabble-portals.{compact,micro}* are untracked. rabble-portals.txt is modified. The "checked-in snapshots" are not checked in yet.
- "palette (cyan 51 / magenta 197 / white)": those are xterm indices, not palette values (see 2.3).
- Missing from the inventory: Families C (icon set, 26 files), D (3 Pocket face copies), E (SiGiL and BaBbLE copies, SDDM entity.png), F (Plymouth and SDDM frames, 146 plus 98 files), GRUB bg, asset_archive (16), the Aether muted theme, the OS Kvantum SVG, Foundling, Chrysalis ep1 face and vendored Aether, and the 2 ascii duplicates.
- Contradiction: the proposal lists Genesis studies as "History, not production", yet SDDM ships logo-portal-eyes-v1 as entity.png.

### 2.6 Mark instance count
- Mark-bearing files: about 360 (icons 26, Pocket face 3, vector masters 4, spec 1, fastfetch and ANSI and ASCII text 26, asset_archive 16 included in that, Genesis and branding studies 27, Plymouth frames 146, SDDM copies 98, GRUB 1, renderer sources about 30). Exact count depends on whether generators and archive are included.
- Distinct rendering families: 9 (A neon vector, B mono vector, C icon raster, D Pocket face, E Genesis studies, F Plymouth and SDDM frames, G text and ANSI art, H procedural renderers, plus the NeBuLA canvas portal in H).
- Byte-duplicate instances: icons 19 extra copies; SDDM 73 copies of Plymouth frames; Genesis 12 SiGiL mirrors plus 3 more; Pocket face 2 extra; mono SVG 1 extra; ASCII 1 extra; NeBuLA bundle 2 extra (World and NeBuLA dist root, identical).

---------------------------------------------------------------
## 3. Mid-edit state (not treated as final)
- RaBbLE-sCoRE: 11 modified (tui/rabble-tui/src/app.rs, crew.rs, widgets/{crew,modal,transcript}.rs, orchestra/*, scripts/rabble, tests/*). Untracked tui/rabble-face/examples/export.rs.
- RaBbLE-OS: 14 modified or untracked in config/fastfetch/* (rabble-portals.txt modified; compact, micro, config.*.jsonc untracked), config/shell/zsh/.zshrc, ansible/packages/manifest.yml, ansible/roles/*. spells/fastfetch-face.sh and spells/rabble-fetch untracked.
- RaBbLE-Grimoire: 45 modified or untracked, including the proposal.
- RaBbLE-BaBbLE: 1057 dirty (not in scope).
Findings in the fastfetch and rabble-face export paths are provisional.

## 4. Not checked
- Pixel colours in Plymouth, SDDM, GRUB and Boot frames (no PIL; source text only).
- Live rendering of prod and dev in a browser (only HTTP and source hashes). Visual claims about prod versus dev come from source and asset comparison.
- Live scribble manifest and assets (only HTML references and tree paths).
- Xperimental drop CSS (whether the caps caption is a style).
- Grimoire prose for name casing, ScRiBbLE docs, Pocket docs.
- Whether the Crew palette candidates (#31c7d5 etc.) are promoted in any non-candidate doc.
- Font licences (Orbitron, Exo 2, Share Tech Mono, Anthropic Sans named in the mono SVG).
- Whether Aether recolor.sh covers GTK. Only kvantum map was read.
- sCoRE tests/golden.rs snapshot content and ui/face.py colour use (scanned for hex only).
- Chrysalis ep1 pages beyond the face and the Aether include.
- score and grimoire hosts beyond root and /health.

## 5. Open questions for Mark
1. Is #03000b (Aether --rabble-void, World --bg) a palette entry or a swap to #0a0010 (decision of record S234)?
2. Is the RaBbLE-OS lockup the intended app and favicon mark, or should the Family A neon master replace it everywhere (proposal Q1/Q2)?
3. Prod: is the pre-S203 build intended to stay until EP1 air, and should the /setup.sh, /RaBbLE-OS.ks and /roadmap 404s be fixed now?
4. Is the Aether version bump policy (package.json 0.0.0.0 vs rc.1 and rc.2 on CDN) deliberate?
5. Lawyer step: confirm the Q3 and B-21 wording should drop the lawyer dependency (proposal, BLOCKERS.md:19, Accord v2).
