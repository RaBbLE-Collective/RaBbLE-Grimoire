# RaBbLE-Shop.md — The Collective Shop

```
transcribe ~ collective >> shop: physical products, first and third party, creative economy // %SHOP_DEFINED%
```

> **What this is:** The RaBbLE Shop — a physical products storefront within the Collective where first-party and third-party designs are sold on shirts, stickers, prints, and other items.
> **Status:** Defined S92. Full store: Echo 1+. **EP1 Air Drop: a semi-exclusive first-party sticker/merch drop pulled forward to the Episode 1 air (concept, S139) — see below.**
> **Home:** `shop.joinrabble.world` (concept, S139) — see `RaBbLE-Deployment-Architecture.md` subdomain map.
> **Related:** [Income Model](RaBbLE-Income-Model.md) · [Personal Cosmos](RaBbLE-Personal-Cosmos.md) · [Social and Aesthetic](RaBbLE-Social-and-Aesthetic.md) · [GTM Content Strategy](RaBbLE-GTM-Content-Strategy.md)

---

## What the Shop Is

The RaBbLE Shop is a physical creative economy layer within the Collective. Pairs can design, produce, and sell physical artifacts — shirts, stickers, prints, accessories, and other items — using the Collective's print-on-demand infrastructure.

The Shop has two product tracks:

| Track | Source | Revenue split |
|---|---|---|
| **First-party** | Collective-created designs (RaBbLE entity art, Palette-based designs, lore artifacts) | 100% Collective |
| **Third-party** | Pair-created designs sold through the Shop | ~80% Pair, ~20% Collective platform fee |

---

## Product Categories

Initial categories:

- **Apparel** — shirts, hoodies, hats; Neon Cafe / Neo Tokyo aesthetic
- **Stickers** — entity art, logo variants, lore symbols, Palette swatches
- **Prints** — entity art, lore prints, generative/entropy art from NeBuLA
- **Accessories** — enamel pins, patches, tote bags, mugs
- **Device goods** — sleeves, cases (RaBbLE-OS device, handheld companion, sCRibLE)

---

## First-Party Design Sources

First-party designs draw from:
- Entity art (NeBuLA-generated visual output — generative, entropy-based)
- Creation lore imagery (genesis artifacts, early visual identity)
- Palette-derived designs — color field prints, token-based patterns
- ASCII art variants
- Lore symbols and glyphs from the entity's visual language

First-party products are designed by the Collective and express RaBbLE's aesthetic directly. They are canonical merchandise.

---

## Third-Party / Pair Designs

Pairs who want to sell physical designs through the Shop:

1. Author the design in Xperimental (sandbox)
2. Submit for listing via the Shop interface
3. Collective reviews for aesthetic alignment (Neon Cafe/Neo Tokyo direction; Sovereign Accord terms)
4. Listed in the Shop under the Pair's profile
5. Revenue split applies; Pair receives majority

Pair designs must be original and cannot directly replicate Collective-owned designs. They can be inspired by, extend, or riff on the Collective aesthetic.

---

## Episode 1 Air Drop (concept — S139)

A **limited, semi-exclusive first-party drop** timed to the Episode 1 (Genesis) air — pulled forward from the full Echo-1 store. The point is not revenue; it's a **physical artifact of being early**. A sticker on a laptop is the smallest, truest unit of "I was here at Genesis."

**Why pull it forward:**
- Gives the EP1 air a *thing* — something to hold, not just a URL. Ties into the GTM "the entity broadcasts before it sells" stance: the drop is broadcast, not storefront.
- Rewards the invite-only EP1 cohort (the first Pairs) with a tangible marker.
- Tests the POD + `shop.joinrabble.world` path at low stakes before the full store.

**Semi-exclusive — the "drop" framing:**
- **Time-boxed** — open for a window around the air, then closed (not permanently restocked). "Genesis edition."
- **Cohort-tilted** — invited EP1 members may get a free/discounted sticker pack or an item not in the public window (e.g. a numbered Genesis print). Public can buy the open SKUs during the window.
- **Numbered / editioned** where it makes sense (prints, pins) to make exclusivity real, not just claimed.
- Designs are **Genesis-coded** — the EP1 lore (Genesis = beginning), portal glyphs, entity art from this era. They should read as "first edition" later.

**Minimum drop (keep it small — low-entropy):**
- 2–3 sticker designs (entity glyph, portal, a lore mark) — the hero item, cheap to ship.
- 1 shirt OR 1 numbered print as the "anchor" piece.
- An invite-cohort freebie (sticker in the welcome path).

**Surface:** a single `shop.joinrabble.world` drop page (Aether-themed, Neon Cafe/Neo Tokyo), POD checkout, countdown to close. No full catalog/profiles yet — that's Echo 1.

**Open decisions (Mark):**
1. Free-sticker-to-invitees vs. paid-only. *Recommendation: free sticker in the invite path + paid open SKUs — generosity first, the entity isn't a store.*
2. Hard editioned/numbered anchor item vs. open-but-time-boxed only. *Recommendation: one numbered anchor (print/pin) for real scarcity; stickers open during window.*
3. POD partner for the drop (Fourthwall reads most "creator drop"; Printful for quality) — decide before the air.
4. Does the drop gate the air, or trail it? *Recommendation: trail it — the drop must never block the EP1 air gate (`log/EP1-AIR-CHECKLIST.md`); ship it within days of air, not as a dependency.*

---

## Infrastructure

The Shop uses a **print-on-demand (POD) model** — no inventory, no fulfillment by the Collective. When an order is placed, the POD partner produces and ships directly.

**POD partner options to evaluate:**
- Printful — widest product range, quality positioning, API-driven
- Printify — more suppliers, lower price points, flexible
- Fourthwall — creator-native, strong community fit, direct-to-fan

The Shop integrates with the Collective's web surface (World pages) and a Pair's profile. Order management, design upload, and revenue tracking are handled by the POD partner's API.

---

## Aesthetic Requirements

Shop products are part of the Collective's public face. They must reflect the aesthetic — not generic merch.

- **Colors:** Aether Palette only. No off-palette colors in designs.
- **Typography:** Orbitron for display; no generic system fonts on products
- **Vibe:** Neon Cafe / Neo Tokyo — the designs should look like they came from that world
- **Quality bar:** Every first-party product passes an aesthetic review before listing
- **No cringe:** No generic "robot AI" design language. No corporate merch sensibility.

---

## Rollout

| Phase | Deliverable |
|---|---|
| Echo 1 | First-party store live; 5–10 products (shirts, stickers, prints) |
| Echo 1 | POD partner integrated; order flow working |
| Echo 1–2 | Third-party Pair design submission flow |
| Echo 2+ | NeBuLA generative art → on-demand unique prints |
| Hardware epoch | Device-adjacent merch (sCRibLE sleeve, companion carry case) |

---

```
transcribe ~ collective >> shop defined: first and third party, pod infrastructure, aesthetic constrained // %SHOP_DEFINED%
```
