# RaBbLE-Pocket-Backplate-CAD.md

```
spark ~ pocket >> the entity gets a battery home // %POCKET_BACKPLATE_V1%
```

> Custom backplate for the Waveshare ESP32-S3-Touch-AMOLED-1.75-B board, giving
> the EEMB 320mAh LiPo a proper mount instead of dangling on wires. Built in
> FreeCAD, parametric, headless-scriptable. Files live in the member repo:
> `RaBbLE-Pocket/hardware/cad/`. Decision record:
> `RaBbLE-Pocket/planning/decisions/2026-08-08-backplate-battery-mount.md`.

---

## What's in `RaBbLE-Pocket/hardware/cad/`

| Path | What |
|---|---|
| `scripts/build_backplate.py` | Parametric generator — run headless via FreeCADCmd, edit the params block at the top and re-run |
| `scripts/build_assembly.py` | Builds the reference assembly (board + battery block + backplate) |
| `ref/ESP32-S3-Touch-AMOLED-1_75.stp` | Vendor board STEP (base 1.75 variant — same PCB/mount pattern as -B), extracted flat here for script convenience |
| `out/RaBbLE-Pocket-Backplate-v1.{FCStd,step,stl}` | Backplate part — STL is print-ready (verified watertight, no self-intersections) |
| `out/RaBbLE-Pocket-Assembly-v1.FCStd` | Combined reference assembly (FCStd only — a full STEP re-export balloons to ~80MB from the vendor board's component-level detail, not worth committing) |

**Regenerate after editing a script:**
```bash
flatpak run --command=FreeCADCmd org.freecad.FreeCAD -c \
  "exec(open('/home/rabble/RaBbLE-Collective/RaBbLE-Pocket/hardware/cad/scripts/build_backplate.py').read())"
```
FreeCAD is a Flatpak (`org.freecad.FreeCAD`) — its sandbox has a **private `/tmp`**
(host permission doesn't extend to it), so scratch files for headless runs must
live under `/home`, not `/tmp`. `FreeCADCmd <script>.py` as a bare positional
arg silently no-ops in this install — use `-c "exec(open('...').read())"`.

---

## How the board's mechanical data was sourced

Waveshare's official 3D download (`hardware/cad/ref/ESP32-S3-Touch-AMOLED-1.75-3D/`)
only ships a STEP file for the **base** 1.75 variant, not the -B variant Mark
actually has (`hardware/cad/ref/ESP32-S3-Touch-AMOLED-1.75-B-3D/` has DWG/PDF
only). Two independent sources were cross-checked to confirm the base STEP's
mount pattern applies to -B too:

1. **STEP inspection** (headless FreeCAD, iterate `shape.Faces`, filter
   `Part::GeomCylinder` surfaces with radius < 3mm) found 3 mounting holes at
   board-local `(x, z)`: `(13.75, 14.70)`, `(-13.75, 14.70)`, `(0, -20.50)` mm,
   each a stepped counterbore (~r1.75 → ~r1.10, i.e. M2-class clearance).
2. **-B mechanical drawing** (`ESP32-S3-Touch-AMOLED-1.75-B-3D.zip`'s PDF) back
   view dimensions — `13.75 / 13.75` and `14.70 / 20.50` — match exactly.

This confirms both variants share one PCB and mount pattern; only the molded
case differs. The backplate bolts to these 3 PCB holes directly, independent
of the stock -B case.

**Board orientation:** a face-area comparison at each depth extreme of the
STEP found ~1800mm² of planar area on one face vs. ~33mm² on the other — the
large flat face is the back (mounting/connector side); the small planar
sliver is the rim around the domed AMOLED front. `build_assembly.py` uses this
to orient the imported board against the backplate's mounting face.

Confirmed dimensions used throughout:
- Board case OD: 51.00mm, case depth: 12.10mm (from the -B drawing)
- Battery: EEMB 3.7V 320mAh LiPo, 402535, 25×35×4.3mm, MX1.25 2-pin (from
  `RaBbLE-Pocket-Hardware.md`)

---

## Backplate design (v1)

Boss-and-pocket construction, all parameters live at the top of
`build_backplate.py`:

- **Outer disc:** Ø51mm to match the -B case OD, total height 5.9mm
  (1.2mm floor + 4.7mm pocket depth)
- **Battery pocket:** 25.6×35.6mm rounded-rect recess (0.6mm total clearance
  over the nominal 25×35mm battery), 4.7mm deep (0.4mm over the 4.3mm battery
  thickness), corner radius 1.5mm
- **3 mounting bosses:** Ø5mm posts rising from the pocket floor to the top
  face at the exact hole coordinates above, each with a 2.2mm through-hole
  (matches the board's own clearance hole size — M2-class hardware)
- **Wire pass-through notch:** 4×3mm cut in the rim wall, placeholder position
  (top edge, centered) — **not derived from an exact connector coordinate**,
  confirm against the physical board before printing
- Cosmetic top-rim fillet is best-effort (0.8mm) — a naive bbox-based edge
  filter blew the fillet outward past the 51mm OD on the first pass; the
  script now does a geometric circle-radius match instead, with a bounding-box
  safety check that falls back to a sharp edge if the fillet ever misbehaves
  again

Mounting: reuses the board's existing 3 holes, sized for the same M2-class
screws already in the assembly. **Not yet verified that the current screws are
long enough to also span the added 5.9mm backplate thickness** — check before
final print, or source longer screws.

Printer target: Cetus3D MK2 (confirmed reliable per `[[project_bottles_layer_cetus3d]]`).

## Open follow-ups

- [ ] Confirm wire pass-through notch position against the physical board
- [ ] Confirm existing mounting screws are long enough, or get longer ones
- [ ] Print v1, test-fit the battery and the 3-hole mount
- [ ] v2: lanyard loop/clip once the fit is validated (deferred by design, see ADR)

---

## v2: rebuilt as a hand-editable PartDesign Body (2026-08-08)

v1's backplate was a Python script producing raw boolean shapes
(`Part::Feature`) — fine to regenerate headlessly, but nothing in it is
clickable/draggable in the FreeCAD GUI (no sketch to open, no feature to
double-click). Mark wants to hand-edit the backplate directly, so
`scripts/build_backplate_partdesign.py` re-expresses the same verified
dimensions as a real `PartDesign::Body` feature tree:

```
Sketch_Disc (circle) -> Pad_Disc
  -> Sketch_Pocket (sharp rect, corners rounded via a Fillet dressup below)
     -> Pocket_Battery -> Fillet_PocketCorners
  -> Boss_1/2/3 (AdditiveCylinder, one per mounting hole)
  -> Sketch_Holes (3 circles) -> Pocket_Holes (ThroughAll)
  -> Sketch_Notch -> Pocket_Notch (wire pass-through)
  -> Fillet_TopRim (cosmetic, best-effort — see gotcha below)
```

Output: `out/RaBbLE-Pocket-Backplate-v2-PartDesign.{FCStd,step,stl}` and
`out/RaBbLE-Pocket-Assembly-v2.FCStd` (via `build_assembly_v2.py`, same
board-orientation math as v1). Bbox matches v1 exactly
(Ø51mm × 5.9mm tall); volume is ~1% higher than v1 because the top-rim
cosmetic fillet didn't survive on this run (see below) — everything
structural (pocket, bosses, holes, notch) matches.

Left two sketches deliberately under-constrained (`Sketch_Pocket` has no
L/W dimension, `Sketch_Holes` has no radius constraints) as first
live-editing exercises rather than fully locking them down.

**Gotcha — PartDesign primitive box/cylinder features are unreliable on this
build (FreeCAD 1.1.3, Flatpak) once a body already has boolean/fillet
history:** a manually-`Placement`-positioned `PartDesign::SubtractiveBox` or
`SubtractiveCylinder` added as the 2nd+ feature either crashed the whole app
(`Application unexpectedly terminated`, no Python traceback) or silently
produced an invalid shape that only surfaced later when a downstream Fillet
tried to use it as a base (`"Base feature's TopoShape is invalid"`). Fix:
build cuts as Sketch + Pocket instead (used for the wire notch) — never had
this problem. `AdditiveCylinder` for the mounting bosses was fine (first
feature added after each, not chained onto a fresh boolean result the same
way). If a `PartDesign::Fillet` recompute silently fails, FreeCAD falls back
to the feature's base shape rather than nulling it out — check
`"Invalid" in obj.State`, not just `obj.Shape.isNull()`, to detect it, and
dry-run the fillet on a detached `shape.copy()` via `Part.Shape.makeFillet()`
*before* creating the real `PartDesign::Fillet` object, since cleaning up a
half-failed one (`removeObject` + `body.Tip` reassignment) risked leaving the
Body's dependency graph in a state that made `Body.Shape` permanently invalid
(`"The graph must be a DAG"` warning). Also: a Body's origin planes are
`f.Name == "XY_Plane"` (underscore) but `f.Label == "XY-plane"`
(hyphen, lowercase) — match on `Name`, not `Label`.

Also true and worth knowing for future headless FreeCAD scripts: plain
Python `print()` calls inside `FreeCADCmd -c "exec(...)"` are unreliable
(often silently swallowed) — use `FreeCAD.Console.PrintMessage()` /
`PrintWarning()` instead, which always flush.

---

## v3: split into real per-part FreeCAD files (2026-08-08)

The design is four components — Display+Controller board, case, backplate,
battery (placeholder) — and each is now its own real FreeCAD part file under
`hardware/cad/RaBbLE-Pocket-ESP32-S3-Touch-AMOLED-1.75/`, not objects buried
inside a shared assembly script:

| File | What |
|---|---|
| `Board.FCStd` | Vendor STEP import, wrapped as its own part. Orientation baked in: flat back face at local Z=0, board rising in +Z — the "resting on the backplate" pose, no rotation needed at assembly time. |
| `Case.FCStd` | Empty `PartDesign::Body` scaffold — no case solid exists anywhere in the vendor data (the -B DWG has only 2D drawing views), so there's nothing to generate. Profile gets traced from the DWG and sketched live in the GUI. |
| `Backplate.FCStd` | The v2 `PartDesign::Body` from above, moved here and renamed from `RaBbLE-Pocket-Backplate-v2-PartDesign.FCStd`. |
| `Battery.FCStd` | New — placeholder envelope (Sketch + Pad, 25×35×4.3mm) for the EEMB LiPo, bottom face at local Z=0. Previously an inline `Part.makeBox` in the assembly script only, not a real part. |

`hardware/cad/out/` is now artifacts-only (STL/STEP exports, PNG renders,
the superseded v1 files) — no CAD source lives there anymore.
`build_assembly_v2.py` still produces `out/RaBbLE-Pocket-Assembly-v2.FCStd`,
but it's explicitly a fit-check/render preview (loads the three part files,
positions their shapes with a plain script), not the real assembly. The real
assembly — linking all four part files with actual joints/mates — stays
Mark's live GUI exercise with FreeCAD 1.1's native Assembly workbench,
unchanged from the v2 decision above.

**Gotcha:** `Part.Shape.Placement = Placement(...)` *replaces* whatever
transform the shape already carries rather than composing with it — the
first version of the updated assembly script clobbered Board's baked-in
-90° orientation this way, silently producing a shape rotated back to its
raw STEP-import pose. Fix: use `shape.translate(vector)` for a pure
positional offset on top of an already-correctly-oriented part; only
reassign `.Placement` outright when you mean to replace the whole transform.

---

## v4: enclosed battery + face-out speaker (2026-10-16)

Mark's brief: a printable backplate that holds the LiPo **inside**, never
exposes a wire, and leaves only the speaker open to the outside. v2's open rim
notch is gone. His first eyeball estimate (2.0 x 1.0 x 0.1 in) was replaced
after a photo showed the cell is the same **EEMB LP402535** (35 x 25 x 4.3mm,
leads out of one short end) and the speaker is a face-firing rounded-rect
cavity speaker.

Script `scripts/build_backplate_v4.py` -> `Backplate.FCStd` (+ `out/Backplate-v4.{step,stl}`),
fit-check/renders `scripts/render_backplate_v4.py` -> `out/renders/backplate-v4-*.png`.
Built and verified in the podman sandbox (`hardware/cad/sandbox/`, see the CAD README).

**What the vendor data actually says (re-derived this session):**
- `Board.FCStd` frame: **Z=0 is the display front**, back components rise in +Z
  (display disc Z 0..3.4, PCB back ~5.4-5.7, standoffs to 10.43, MX1.25 tops 11.70,
  8-pin header to 12.70). The v3 note "flat back face at local Z=0" is backwards;
  the v2 assembly preview likely stacked the plate on the wrong face.
- -B side view: 11.70 total depth. The back is **open**: the -B case is a
  front bezel/ring, PCB back exposed. Rim plane = Board Z 11.70 (MX1.25 tops sit
  exactly there; the header pokes ~1.0 past it, matching the drawing's bump).
- Both MX1.25 headers (battery + speaker) are side-entry, at Y~-18, X +-(2.7..10.6),
  plugs pointing at the board edge.
- The 20x32 rectangle in the -B back view = the bundled 8 ohm 2W speaker
  (2030-class cavity speaker assumed).

**Design (single part, prints grille-face down, zero supports):**
```
z -1.5..0    skirt hugging the 51mm case OD (Ø51.4; 1.5 deep because the traced -B side
             views show side features from ~1.9mm off the back edge)
z 0..4.7     battery bay 37.8 x 25.8 (incl. 2.0 lead-turn gap at -X) + 1.8 wire
             channel along -Y, connector well over both MX1.25s (boss kept round
             the bottom screw)
z 4.7..9.5   speaker pocket 30.6 x 20.6, face toward grille, battery is its retainer
z 9.5..10.7  grille wall, hex hole field (Ø1.6 @ 2.6)
```
Screws: the **stock** short screws (Mark's requirement, 2026-10-16). The -B case
ships with a thin flat back cover (photo IMG_0557): 3 holes onto the brass
standoffs, two rectangular windows over BAT/SPK (wires exited the back, hence the
dangling parts) and a slot for the 8-pin female header. v4 replaces that cover:
a Ø6 pad under each hole drops to 0.1mm above the standoff top (`standoff_gap`
1.27 from the STEP, MEASURE) and the Ø4 counterbore runs down to `cb_flange` 1.2mm
above the pad bottom, so a stock screw clamps about what the cover did. Mark confirmed: the cover sits on a slightly inset rim inside the
ring, is at most 2mm thick (STEP implies ~1.27: standoff tops 10.43, rim 11.70,
MX1.25 tops flush with the rim through the cover windows), and the stock screws
are ~4.3mm long, so ~3mm of thread engages the standoff. Bay moved
to `bat_cy` -1.0 to keep 0.8mm wall beside the deep top counterbores.

Battery-sink option (not applied): per the STEP, the cell could drop ~2.6mm into
the ring cavity if shifted +2mm in X (USB-C blocks the -X end, a part at
X14.7..19.5 Y8.8..13.8 tops out at Z8.70), saving ~2.6mm of plate height, but its
corners then reach r~24mm against an unmeasured ring bore. Header relief 1.5 deep.
Battery corners rest on the skirt shoulder. Fit-check: zero interference
plate/board/battery/speaker.

All main dims live in the `Params` spreadsheet, bound by expressions; outer
diameter is derived (`r_out`) from the bay corners. For the LP402535 it is
**Ø54.6 x 12.2mm** (10.7 above the rim + 1.5 skirt). The first-estimate 50.8mm cell had
pushed it to Ø63.4. Possible slimming: the PCB-back cavity inside the -B ring
(~5mm free over the bay footprint per the STEP) could take part of the battery
thickness; unexplored until the real cavity is measured.

Gotchas: spreadsheet cells must carry units (`=50.8 mm`, and `+ 0.5 mm` in
formulas) or sketch-constraint expressions fail with unit mismatch; headless
saves have no GuiDocument.xml, so the body opens hidden until a Gui pass sets
visibility and saves (render script does this).

**Open (needs Mark's calipers):**
- [ ] Speaker footprint, thickness, sound-port face (front vs side)
- [ ] Stock cover diameter (= inset bore): enables a cover-shaped plug that seats on
      the inset rim and lets the battery drop ~1.25mm into the cover's old space
- [ ] Print, fit, iterate

**-B case vs the plate:** no -B case solid exists (vendor STEP = base 1.75 board
only; `Case.FCStd` holds 2D traced views). Measured from those traces: the case is
a plain Ø51.0 cylinder end to end (0.4mm narrower step at the display end), nothing
proud of the OD. So the plate's only contact with the case is by design: its
underside seats on the back rim, and the skirt clears the OD by 0.2mm per side.
Not checkable from vendor data: the case wall thickness / inner bore (the bay and
well overhang it), and the true rim-to-PCB depth (11.70 assumed).
