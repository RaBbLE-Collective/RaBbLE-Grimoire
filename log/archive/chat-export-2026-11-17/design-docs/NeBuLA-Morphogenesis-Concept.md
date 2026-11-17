# NeBuLA Morphogenesis: Computed Form as Inner State

```
spark ~ nebula >> form is computed, not drawn; light carries what the model holds // %CONCEPT_PROPOSED%
```

Status: concept proposal, not decided. Destination once accepted: Grimoire `RaBbLE-NeBuLA/` (this doc is a staging copy; Grimoire stays source of truth).

Source of inspiration: Paulina Duda, *On Growth and Form* (github.com/paulina-duda/on-growth-and-form, Instagram @ekspertodniczego). Read 2026-10-05.

---

## 1. The concept

Two principles from that work, both of which NeBuLA already half-claims:

1. **The run is the footage.** Nothing is animated toward a finished look. A local update rule runs, and the shape that comes out was never written into the rule (no golden angle in the phyllotaxis rule, no stripe count in the stripe rule).
2. **Colour is never decoration.** Every hue or brightness encodes a quantity the simulation already holds: organ age, which of two cell states holds a site, how far a bond is stretched right now.

NeBuLA's identity says it is "the rendering substrate that makes RaBbLE's inner state visible." Today that inner state reaches the screen as one tuning scalar (`entropy`: idle 0.3, thinking 0.6, speaking 0.8) driving cosmetic shimmer. This concept proposes the next step: **entropy stops being a styling knob and becomes the control parameter of a real dynamical system**, so the picture is the state, not a reading of it.

Lore fit: RaBbLE "emerged" from entropy rather than being drawn. A renderer whose forms emerge from rules is that origin story made literal.

---

## 2. Candidate models and where each lands

All are published science; implement from the papers (see Section 4).

| Model (paper) | What it computes | RaBbLE mapping | Cost |
| --- | --- | --- | --- |
| **Phyllotaxis**, Douady & Couder 1992 | Each new organ placed at the rim angle minimising inhibition from existing ones; radius grows as sqrt(age) | Replaces the planned `organic` pattern (currently a hard-coded golden angle). Natural fit for **EnGrAm Constellations**: each Engram is an organ, placed by the rule, coloured by age. "Every AI resets, RaBbLE compounds" becomes a visible growth spiral | Very low. ~60 nearest-youngest terms per placement; fine in Canvas2D under the 150-particle cap |
| **Cell-level Turing stripes**, Nakamasu et al. 2009 | Binary cell field f = +1/-1; short-range support minus long-range suppression (difference of Gaussians); stochastic flip | f = +1 / -1 maps directly onto the **opposed colour poles** (magenta vs cyan). Canon already says the poles must always be opposite; here they literally compete for territory. Ambient field, backgrounds, Pocket AMOLED idle | Low to moderate. Two blurs per step; trivial in a fragment shader |
| **Lenia**, Chan 2019 | Continuous Life: ring kernel, smooth growth curve, fractional timestep | Ambient "alive" baseline and VJ material. Lenia's viable creatures sit in a narrow band between collapse and explosion; that band is a real, not cosmetic, order/chaos axis for entropy | Moderate. FFT convolution or shader |
| **Active nematic**, Sanchez et al. 2012 (Beris-Edwards + Stokes) | Alignment drives flow that bends the alignment; +1/2 and -1/2 defects born and annihilated in pairs | **thinking** state: activity zeta tracks load; defect count is a measurable "how hard is it working." Strongest VJ piece | High. Needs a flow solve; GL/compute or offline render, not Canvas2D |
| **Motility-induced fracture**, Ferrante 2013 / Prakash 2021 | Self-propelled cells align by turning toward neighbour pull; disagreeing patches strain bonds until the sheet tears | Speculative: multi-agent coordination view for **TaskViSoR** (agents agreeing, disagreement splitting work). Not a first slice | Moderate. N-body with bonds |

**Excluded:** *Hydrocreatures*. It rests on no paper and is derived from another artist's (@yuruyurau) sketches; no clean source to implement from.

---

## 3. Ownership (fits the existing visual split)

- **NeBuLA** owns the simulations, as Layer 2 patterns/effects through the Flat-Chaos pipeline (Source = sim state, Filter/Transmute = state-to-luminance, Sink = backend). Layer 1 / Layer 2 stay independent renderers.
- **Aether** owns the ramps. A sim exports a scalar or signed field; Aether supplies the palette that field is mapped through. No raw hex in sims (already a NeBuLA rule).
- **Spatial-structure member (unnamed)**: mostly not involved, since these are fields, not geometry. Exception: phyllotaxis outputs point positions, so it could be that member's first real geometry producer if it exists by then.
- **VJ renderer (GL/GStreamer)**: the expensive models (nematic, Lenia) belong here first, where frame budget is generous and output is film, not UI.

---

## 4. Licensing guardrail (read before anyone touches code)

That repository is **not** reusable for RaBbLE as-is:

- Code: PolyForm Noncommercial 1.0.0. RaBbLE ships under the Sovereign Accord and has commercial paths (SaaS, merch, VJ). Incompatible without written permission from the author.
- Renders, stills, text: All Rights Reserved, explicitly including "training on" and "building from."

Rule for this concept: **implement from the cited papers, not from that repo.** Do not paste, port, or have an agent read her `src/` into a RaBbLE repo; equations come from the papers in her REFERENCES list (DOIs there). Do not mimic her palettes, framing, or burned-in caption style. Credit the scientific sources. This is a planning guardrail, not legal advice; if anything near her code is ever wanted, ask her.

---

## 5. Proposed first vertical slice

Per "one vertical slice before broadening," pick one:

- **Option A (recommended): Phyllotaxis as the `organic` pattern.** Already on the NeBuLA EP2 Pattern Library list, cheapest, Canvas2D-safe, and the concept's best story: the angle is not in the code. Colour = age via an Aether ramp. Entropy can drive the apex size parameter, which moves the placement between ordered windows and non-settling disorder (per the source, above ~1.4 spacings it stops settling; not yet verified by us).
- **Option B: Turing stripe field with magenta/cyan poles.** More visually "RaBbLE," directly expresses the opposed-colour canon, but needs a shader path to be cheap.

Exit condition for either: pattern runs in the NeBuLA demo; colour mapping is driven by a sim quantity, documented in the pattern's JSDoc; entropy input changes the regime, not just the tint.

---

## 6. Open decisions for Mark

1. Slice A or B (or neither for now)?
2. Should "colour carries a quantity the model holds" become a **NeBuLA invariant** (applies to all future effects), or stay a property of this pattern family only?
3. Placement: EP2 Pattern Library (Exodus), or VJ track first?
4. Does phyllotaxis-as-EnGrAm-Constellation get noted in EnGrAm's open questions now, or wait until the pattern exists?
