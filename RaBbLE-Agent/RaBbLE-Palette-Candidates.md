# RaBbLE-Palette-Candidates.md

> **Consideration list, not canon.** Colors found in real RaBbLE work that are *not* in
> `RaBbLE-Palette.md`. Until Mark promotes one, it may not ship: code uses the canonical swap
> listed here. Promotion = add to `RaBbLE-Palette.md` with a name + role, then remove the row here
> and replace the swap in code with the new token.

**Decision of record (S234, Mark):** swap off-palette hexes for the closest canonical color, and
keep the novel ones here for possible palette inclusion. (EP1-Entity-Face-Plan D4.)

**Method:** closest by CIELAB ΔE (CIE76) against the 13 canonical colors. Where the numeric
nearest is a neutral but the source is clearly chromatic, the swap stays in the same hue family
(marked *hue-kept*); ΔE shown is to the chosen swap.

---

## Source: the "alive" entity (S233 intake → S234 port)

`RaBbLE-BaBbLE/reliquary/2026-09-26-entity-harness/RaBbLE · The Entity (alive).html`, the renderer
being ported into NeBuLA `<rabble-entity>` (`log/plans/EP1-Entity-Face-Plan.md` W1).

### Entity core + boot log (near-twins: low loss)

| Hex | Role in source | Swap → canonical | ΔE | Promote? |
|---|---|---|---|---|
| `#03000b` | `C.deep` (deepest field) | Deep Void `#0a0010` | 3.2 | Unlikely: imperceptible |
| `#f8faff` | `C.eye` (eye core), `.rdy` log line | Primary Text `#e8e6f0` | 7.2 | **Consider:** eye-white brightness is a character cue |
| `#1a0030` | `C.glow` (halo base) | Surface `#12132a` | 17.9 | **Consider:** violet-black glow, Surface reads blue-grey |
| `#3d3860` | boot log timestamp `.ts` | Border `#2a2840` | 12.8 | Unlikely |
| `#8a86a0` | boot log message `.msg` | Muted Text `#6b6880` | 12.0 | Maybe: a lighter muted tier for dense logs |

### Nebula gradient `C.nebula` (8 stops: real depth loss)

These are the bokeh/haze depth ramp. Swapping collapses 8 stops to 3 colors (cyan ×4, violet ×2,
text ×2), which flattens the nebula. **Strongest promotion candidate as a set** (e.g. a named
`nebula` ramp in the palette rather than 8 loose hexes).

| Hex | Swap → canonical | ΔE | Note |
|---|---|---|---|
| `#1a4aaa` | Electric Cyan `#00f5ff` | *hue-kept* | numeric nearest is Border (46.3): a grey, wrong family |
| `#55aaff` | Electric Cyan `#00f5ff` | *hue-kept* | numeric nearest is Muted Text (43.7): a grey |
| `#00bbdd` | Electric Cyan `#00f5ff` | 26.4 | |
| `#33ddf0` | Electric Cyan `#00f5ff` | 11.6 | |
| `#7744cc` | Soft Violet `#bf5fff` | 21.7 | |
| `#bb55dd` | Soft Violet `#bf5fff` | 13.4 | |
| `#ddeeff` | Primary Text `#e8e6f0` | 7.4 | |
| `#ccddff` | Primary Text `#e8e6f0` | 14.4 | |

**Mitigation until promoted:** the port keeps depth with alpha and blur on the canonical swaps,
not new hexes. At face sign-off, compare against the original alive render side by side.

---

## How to add a candidate
One row per hex: source file, role, canonical swap, ΔE, promote note. Never ship a candidate hex.
