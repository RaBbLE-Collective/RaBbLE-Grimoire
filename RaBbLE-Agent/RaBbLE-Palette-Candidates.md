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

---

## Source: the RaBbLE Crew (S273)

Persona colour pairs for the Crew (`RaBbLE/Crew/`): each organ owns one canonical hue plus one
derived variant; RaBbLE (lead) keeps canonical magenta + cyan untouched. Derived in OKLCH from the
canonical base (deep = L −0.22, C ×0.85; same hue). Distances here are **OKLab ×100** (not CIE76),
contrast is WCAG against Deep Void. Mark approved the set as shown on the swatch page
(https://claude.ai/artifact/Qo1EE3uM3n67AqgcQnjQLX, deep variants, vivid thread) on 2026-10-24;
promotion into `RaBbLE-Palette.md` not done yet. Used today only by the `rabble` launcher banner
(`RaBbLE-sCoRE/crew/rabble.py`, Crew Thread only) and persona frontmatter.

| Hex | Role | Canonical swap | OKLab to swap | On void | Promote note |
|---|---|---|---|---|---|
| `#31c7d5` | **Crew Thread**: muted Electric Cyan woven through every organ, the whole-Crew mark, SqUaBbLE | Electric Cyan `#00f5ff` | 12.5 | 10.1:1 | **Promote:** the Crew's shared identity colour. Soft `#68b3b7` was rejected as grey |
| `#ff9044` | **QuiBbLE base**: sunset orange, the only new hue | Outrun Pink `#ff79c6` (Error Red `#e05c6f` is 15.4) | 18.6 | 9.1:1 | **Promote:** outrun-native; the palette had no orange |
| `#aa5306` | QuiBbLE deep variant | `#ff9044` (above) | 22.1 | 3.9:1 | Glow/border only (below 4.5:1) |
| `#8b2237` | NiBbLE deep variant (wine) | Error Red `#e05c6f` | 22.1 | 2.3:1 | Glow/border only; separates NiBbLE from RaBbLE magenta (magenta/red are 8.1 apart) |
| `#aab157` | CoBbLE deep variant | Warning Yellow `#f1fa8c` | 22.1 | 9.0:1 | Reads olive; light `#f5fbc2` is the alternative |
| `#08ac46` | CrumBbLE deep variant | Success Green `#50fa7b` | 22.4 | 6.9:1 | |
| `#a93f7f` | BaBbLE deep variant | Outrun Pink `#ff79c6` | 22.3 | 3.6:1 | Glow/border only |
| `#7521a6` | DaBbLE deep variant | Soft Violet `#bf5fff` | 22.3 | 2.5:1 | Glow/border only |
| `#f6f6ff` | **GoBbLE glimmer**: its fresh state; it morphs into an oil slick of canonical neons as it ingests | Primary Text `#e8e6f0` | 4.6 | 19.2:1 | Maybe: may be imperceptible next to Primary Text |

The Archivist uses Deep Void + Border (canonical, nothing to promote). GoBbLE's oil slick uses
canonical neons only.
