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
| `ref/ESP32-S3-Touch-AMOLED-1_75.stp` | Vendor board STEP (base 1.75 variant — same PCB/mount pattern as -B), copied from `firmware/vendor/docs/` for script convenience |
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

Waveshare's official 3D download (`firmware/vendor/docs/ESP32-S3-Touch-AMOLED-1.75-3D.zip`)
only ships a STEP file for the **base** 1.75 variant, not the -B variant Mark
actually has (that zip has DWG/PDF only). Two independent sources were
cross-checked to confirm the base STEP's mount pattern applies to -B too:

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
