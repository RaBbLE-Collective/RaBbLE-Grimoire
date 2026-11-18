# sCoRE terminal face inventory (read-only, 2026-11-18)

All paths under RaBbLE-sCoRE/. No other RaBbLE-UI Rust crate exists: `rabble-ui`/"RaBbLE-UI" is the sCoRE `tui/` workspace (rabble-face, rabble-tui, rabble-theme, rabble-proto) plus Python `ui/`.

| File | Draws | State/expr names | Spec followed | Last commit | Callers | Runtime? |
|---|---|---|---|---|---|---|
| tui/rabble-face/src/face.rs (710 L) | Full + Mini entity: rig, aura, envelope, mesh, orb, two eye/portal pairs (`Detail::Full/Mini`, face.rs:215) | `Expr` calm joy sad angry listening speaking (face.rs:51-70); `Provider` anthropic/google/openai (:125-136); lids for angry/sad (:105-108) | port of ui/face.py, itself ported from NeBuLA alive-backend.js; rig baseline = NeBuLA specs/rig/entity-rig.json (per ui/face.py docstring) | 2026-11-02 | rabble-tui widgets/face.rs:12, app.rs:18 | yes (Rust shell) |
| tui/rabble-face/src/eyes.rs (442 L) | octant-res AA eyes and portals | rig tuples only | port of ui/eyes.py | 2026-11-02 | face.rs | yes |
| tui/rabble-face/src/micro.rs (291 L) | Micro mark: 7x3 cells (20x12 octant px, `MICRO_COLS`), two eye pills hanging off portals, `safe` quadrant variant | none (blink, gaze inputs) | Matrix Builder glyph, RaBbLE-NeBuLA-EyeStates.md (micro.rs:2) | 2026-11-03 | rabble-tui widgets/face.rs:175, widgets/mod.rs:16 (compact header tier) | yes |
| tui/rabble-face/src/driver.rs (229 L) | no drawing; behaviour over time | `Mood` idle typing streaming working error denied (driver.rs:85-92) -> Expr + saccade speed | port of ui/face.py `Life`, `MOODS` | 2026-11-02 | rabble-tui app.rs:18 | yes |
| degrade.rs, canvas.rs, prng.rs, lib.rs | noise/break degrade by capability/stability; cell canvas; SplitMix64 | none | port of face.py `degrade`, `Canvas` | 2026-11-02 | face crate | yes |
| tui/rabble-face/examples/{show,bench,export}.rs | dev tools (export.rs newest 2026-11-06) | | | | | dev only |
| ui/face.py (1274 L) | Same Full/Mini `Face` (:387), `MicroMark` (:1013), `compact_mark` (:1034), Textual `FaceWidget` (:1039) | `EXPR` dict (:46, same 6 names), `MOODS` (:846), `Life` (:797) | NeBuLA alive-backend.js + entity-rig.json (docstring) | 2026-11-02 | ui/app.py:117 via `_optional("ui.face","FaceWidget")`, :38 reload list; ui/eyes.py, ui/gaze.py | yes, Python Textual UI is a live twin and the golden-parity oracle |
| ui/eyes.py | octant eyes/portals | | | | face.py | yes |
| tests/golden_face.py + tests/fixtures/face/golden.json | generates 48 frames the Rust crate replays (tui/rabble-face/tests/golden.rs:1-16) | | | | | test |

## Copy elsewhere
- ui/face.py md5 a73ed9c6... vs RaBbLE-BaBbLE/prototypes/terminal-face/face.py md5 214eb157...: DIFFER. The sCoRE docstring (face.py:10-11) says the BaBbLE prototype is "the older reference and no longer matches" the rig baseline. BaBbLE dir also has preview.py, README.md, shots/. Drifter, confirmed.

## Plan status corrections
- "face.rs canonical terminal path": confirmed (it is the shipped Rust shell's renderer). But face.rs is NOT a free-standing spec: it is a cell-for-cell port of face.py, and pins parity to Python goldens (rabble-tui/PARITY.md:74-76, "every cell identical"). The ancestry is face.py <- NeBuLA alive-backend.js / entity-rig.json.
- "face.py likely retire": NOT yet safe. It is (a) the live Python Textual UI face (ui/app.py:117), (b) the golden generator the Rust tests depend on. Retire only after: goldens frozen/regenerated from the registry or Rust, tests/golden_face.py + tests/test_ui_face.py replaced, and the Python UI itself retired (PARITY.md says Python twin is kept in step: gaze.py pins constants to Rust source text). Recommend: "freeze (no new features), retire with the Python UI".
- Plan row omits: micro.rs (micro mark, Matrix Builder glyph) and driver.rs Mood vocabulary; both belong in the inventory.

## Vocabulary notes for unification
- Expressions (6): calm joy sad angry listening speaking. Engine moods (6): idle typing streaming working error denied; Mood -> Expr map lives in `MOODS` (face.py:846) / driver.rs. Provider tint: anthropic google openai.
- No registry reads: names and pose tables are hardcoded in both Rust (face.rs:78-100) and Python (face.py:46). Registry adoption means generating Expr/pose table (and EyeStates micro glyph) from the registry JSON for both, or just Rust.
- Last-commit dates are mostly 2026-11-02 (single bulk port); no sCoRE face file edited after 11-06.
