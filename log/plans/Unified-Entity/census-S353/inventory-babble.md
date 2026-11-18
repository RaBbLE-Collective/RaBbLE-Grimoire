# RaBbLE-BaBbLE entity-render inventory (read-only, 2026-11-18)

Paths relative to RaBbLE-BaBbLE. Dates = last commit (%cs). md5 = first 8 chars.

| File | Draws / spec | Last commit | md5 | Copy of | Linked by | Proposed |
|---|---|---|---|---|---|---|
| prototypes/RaBbLE.html (1180 L) | early "Boundless Behavioral Learning Engine" page; pre-spec | 2026-06-12 | 34451c18 | none | nothing found | drifter |
| prototypes/boot/RaBbLE-Boot-v1.html (925 L) | "RaBbLE-OS . Boot" screen; boot sequence | 2026-06-12 | 54bf5958 | v2 is byte-identical | Unification plan row only; no Grimoire/OS doc links the file | **origin/reference**, keep ONE (v1); v2 duplicate to Chrysalis. Boot timeline (U7) not built; plan says boot is its source |
| prototypes/boot/RaBbLE-Boot-v2.html | same | 2026-06-12 | 54bf5958 | exact dup of v1 | none | drifter (dup) |
| prototypes/terminal-face/face.py (577 L), preview.py, README, shots/ | NeBuLA alive entity in truecolor terminal (orb, 2 eye/portal pairs, meshes, almond); ported from NeBuLA alive-backend.js; palette read at runtime | 2026-10-25 (preview 10-24) | 214eb157 | pocket-face.png outputs in Xperimental (pocket-site/promo) are renders of it; no code copy | referenced by its own README only | **reference** (newest, active, only native non-web renderer; keep until registry has a terminal renderer, then it is the template) |
| prototypes/nebula/RaBbLE-NeBuLA-Studio.html (1892 L) | Three.js "Animation and Effect Forge" prototype | 2026-06-12 | 9ba86c08 | related to Chrysalis ep1/world/RaBbLE-NeBuLA-Demo.html (2055 diff lines, not a copy); superseded by RaBbLE-NeBuLA/studio | none | drifter |
| prototypes/alive-port/{header,body?,bootui,bootctl,footer}.js, transform.py, README | provenance of port reliquary "alive" html -> NeBuLA src/backends/alive-backend.js (S234) | 2026-09-26 | various | tmp/alive/{header,bootui,bootctl,footer,transform} are exact copies (md5 eb3e7500, a2d91d9c, 4b868992, b41d8116, 1cbce42b) | alive-backend.js header cites the harness | reference/provenance (small); optional to Chrysalis once harness moves |
| prototypes/RaBbLE-Strata.html, RaBbLE-Login.html, animation-studio.html | UI/login/animation experiments; mention eye/portal only incidentally | 07-04 / 06-12 / 05-21 | f0eaa6c9, c6eb623d, 856cd24c | none | none | drifter (not entity renders) |
| intake/rabble-pocket-entity.html (791 L) | Pocket entity mock (two eyes/portals) | 2026-10-21 | 8e55286e | near: RaBbLE-Pocket/planning/mock/rabble-pocket-entity.html (1 line diff: added copyright header). Exact: Xperimental drops/20261013-pocket-entity/index.html | Pocket planning | drifter (canonical = Pocket mock) |
| intake/rabble-entity-rig.html (755 L) | Three.js entity rig, specular-shaded; follows intake/RaBbLE-Entity-Rig-Spec.md | 2026-10-21 | f0abc55b | exact: Xperimental drops/20261013-entity-rig/index.html | none | drifter (Xperimental drop is the keeper) |
| intake/RaBbLE Ball.html (937 L) | Ball 3D (eyes masked on sphere) | 2026-10-21 | ffd2158b | near: RaBbLE_Ball.html 354 diff lines; Xperimental experiments/rabble-ball/RaBbLE-Ball.html is identical to drops/20261020-rabble-ball/index.html (352 diff vs _Ball) | none | drifter |
| intake/RaBbLE_Ball.html (905 L) | Ball, other version | 2026-10-21 | a5800cfa | nearest to Xperimental canonical (352 diff lines); ~equal to tmp/rabble-ball/test.html (354) | none | drifter (Xperimental holds canonical) |
| intake/RaBbLE Rave.html, RaBbLE Fourier Redraw.html | audio-reactive / Fourier visuals (not entity render) | 2026-10-21 | 6d9c2d22, cd907bef | exact: Xperimental drops 20261013-rabble-rave, -fourier-redraw | none | drifter (non-entity; dups) |
| intake/rabble-matrix-builder.html, Pocket ESP32-S3 Entity Port Plan.md, RaBbLE-NeBuLA-EyeStates.md, RaBbLE-Entity-Rig-Spec.md | misc entity docs/builder | 2026-10-21 | n/a | not checked for dups | none | review; docs should fold to Grimoire Unified-Entity (not render files) |
| tmp/alive/body.js (878 L), body.out.js (911 L) | extracted inline script of the harness "alive" html (source) and transformed output | untracked (tmp gitignored) | 0e25441a, e6cab6ee | body.js ~ harness alive html lines 78-956 (84 diff lines incl. wrapper); body.out.js = pre-NeBuLA port | none | drifter (regenerable, ignored; just delete or Chrysalis) |
| tmp/rabble-ball/{test.html,eyes.js,shoot.py,zoom.py} | Ball scratch (test.html ~ RaBbLE_Ball.html, 354 diff) | untracked | f25cf403, e35c3a50 | near copy of intake Ball | none | drifter / scratch |
| tmp/face/* (live.svg, ui-organ-turn.svg, sheet.py, pngs) | face-design iteration scratch for face.py | untracked | 5afd1a63 etc | none | none | drifter / scratch |
| reliquary/2026-09-26-entity-harness/entity.html (703 L) | entity harness page | 2026-09-26 | 8132d012 | differs from alive html (1588 diff lines); related to Grimoire Unified-Entity-Puppet-Spec lineage | alive-backend.js comment, alive-port README | move to Chrysalis reliquary (already a reliquary) |
| .../RaBbLE . The Entity (alive).html (961 L) | **origin of NeBuLA alive-backend.js** (ported S234); two eyes, portals, infinity flow | 2026-09-26 | ee89a135 | no exact copy found | alive-backend.js, alive-port README | **origin**; move with reliquary but keep a pointer; update the path cited in alive-backend.js/README |
| .../The Entity_ Visual Guide and Animation Rig.html, entity-rig.json/.svg, EnGrAm/EP2/Puppet docs | visual guide, rig data, svg | 2026-09-26 | 519eb544 / 6ab9e0fd / 65520ada | not checked | Puppet-Pocket-Pipeline-Session doc | move to Chrysalis reliquary |

## Notes
- No file in BaBbLE is the canonical copy of any entity render except via provenance (alive harness -> NeBuLA) and boot v1 (boot timeline source, nothing built yet).
- Xperimental drops (20261013-*, 20261020-rabble-ball) hold exact copies of 4 intake files plus the Ball; BaBbLE intake copies are safe drifters.
- Moving the harness breaks path comments in RaBbLE-NeBuLA/src/backends/alive-backend.js (line 5) and prototypes/alive-port/README.md; fix text on move.
- terminal-face is the only recent (Oct 25) and active file; keep.
- Linkers search was grep over Grimoire/OS/NeBuLA/Chrysalis; none link boot v1/v2 or prototypes/RaBbLE.html. Near-copy diff counts are diff -line counts (not diff --stat).
