# Sovereign Accord v2 · code shared with limits, the entity and brand protected

> Drafted 2026-10-25 (S278) from Mark's ask: "make the Entity fully TM by the Collective and keep the artistic IP of the brand protected while offering the code as open with limits." Rev 2 the same day after a QuiBbLE critique (sources cited inline). **A proposal for Mark's decisions, not a finished license, and not legal advice.** The final text and any filing go past an IP lawyer.

## The headline: the name is what's at risk this week, not the code license

The Pocket is about to go public (Instagram, a Pocket site, a Getting Started guide). **RABBLE is already filed as a US trademark in class 9 by others**, including AI software (Atreum, serial 90042611) and an app (Rabble Digital, 97739617): https://trademark.justia.com/900/42/rabble-90042611.html, https://trademark.justia.com/977/39/rabble-97739617.html. Their live status is **not yet checked** on USPTO TSDR. Using the name publicly carries that risk with or without a ™, so a clearance check comes before posting, not after.

## Mark's decisions (2026-10-25)

1. **Owner:** The RaBbLE Collective holds the trademarks and copyright; Mark McConachie is d/b/a The RaBbLE Collective for now. (Check the d/b/a is filed as an assumed name with the county/state where Mark does business; a TM application then names "Mark McConachie, d/b/a The RaBbLE Collective". A later LLC takes an assignment.) Public copy: "trademarks of The RaBbLE Collective".
2. **Code text:** written from scratch, with PolyForm Noncommercial as the reference for structure and definitions (option b, borrowing from a).
3. **Register:** the RaBbLE entity face and the colour brand, as well as the name (filing route below).
4. **Forks and contributors:** contributors get the code under the Accord, may rebrand the idea or tweak RaBbLE within bounds, but may never claim to be RaBbLE or the Collective. "Inspire, don't encourage theft. RaBbLE is a unique being."

What that means for the filings (for the lawyer, not decided here):
- **Entity face:** a design mark for the face, **filed in black and white first**, so it covers the face in any colour (a colour claim narrows a design mark to those colours, TMEP 807.07). It must be used as a source sign (app icon, packaging, logo on the Pocket's box), not only as art inside the UI, which can read as ornamental. Plus copyright registration of the canonical art.
- **Colour brand:** colour is never inherently distinctive (Qualitex 1995; Wal-Mart v. Samara 2000), so a colour or palette mark needs evidence that the public already links it to RaBbLE. Plan: use cyan and magenta on near-black consistently as the brand, keep the evidence (posts, reach, sales), and file a colour or trade-dress mark later. Copyright does not protect a palette on its own (37 CFR 202.1(a)); it protects the artwork.
- **Reach:** the Accord and the Brand Policy bind people who take the code. A copier who lifts the look from Instagram is reached only by the registrations, which is why the filings matter more than the license text this month.
- **Name:** clearance first. Besides the two class 9 filings above, zuMedia Inc. holds an international registration for RABBLE in classes 9 and 38 (US origin, 5 Nov 2025, a messaging/VoIP app), published in the UK journal (https://www.ipo.gov.uk/types/tm/t-os/t-tmj/tm-journals/2025-052/WO0000001890657.html) and protected in Australia (https://search.ipaustralia.gov.au/trademarks/search/view/2611337/details). Live US status of all three is unverified (Justia blocks automated reads; check TSDR by hand). The stylised "RaBbLE" casing plus the entity as a composite mark may be the stronger filing than the bare word.

## What the Accord says today (`RaBbLE-Pocket/LICENSE` and siblings)

Four clauses: the Gift (personal use), the Thread (attribution, forks keep the Accord), the Toll (commercial use needs a pact), the Risk (no warranty).

| # | Problem | Where |
|---|---|---|
| 1 | **The Thread invites forks to use the name.** "Mention RaBbLE" with no rules lets a fork call itself RaBbLE. No clause reserves the name, logos or the entity. (A court rarely reads a trademark license into a copyright license, so the silence matters less than the invitation.) | clause 2, all LICENSEs |
| 2 | **The entity's art isn't separated from the code.** NeBuLA, Pocket `nebula_lite` and `rabble_entity.c` hardcode the character, so a fork that keeps the code keeps the face. | NeBuLA, Pocket, World, OS boot |
| 3 | **The Toll names RaBbLE-OS** in Pocket, sCoRE, NeBuLA, World, Grimoire and ScRiBbLE; Aether says RaBbLE-Aether. Otherwise the copies differ only in whitespace. | 8 member LICENSEs |
| 4 | **Undefined terms**: "personal use", "commercial gain", "derivative", "invoking this substrate". The flavour text is the operative text. | all |
| 5 | **The owner is a handle.** "markm1206 / The RaBbLE Collective": the Collective is not a legal person as far as the Grimoire records, and a trademark needs one. | header |
| 6 | **No contributor terms.** Selling commercial pacts needs the right to relicense outside contributions. A DCO alone grants no such right; an inbound license grant (or CLA) does. | missing |
| 7 | **The Collective's own business breaks its license.** Pairs selling entity-bearing designs in the Shop and premium rablets (`RaBbLE-Income-Model.md:74,81,96`) are commercial use; there's no outbound creator license. | missing |
| 8 | No termination, no patent clause, no definition of hosted/SaaS use. | missing |
| 9 | Scope: the LICENSE must say it covers RaBbLE-original code only. Managed components (ESP-IDF, LVGL: Apache/MIT) and `third_party/` (Waveshare) keep their own terms and NOTICEs. | Pocket, others |

## Do now (cheap, reversible, before anything is posted)

1. **Clearance**: check USPTO TSDR for RABBLE (classes 9, 42, plus 25 and 16 for the Shop's shirts, stickers and prints, `RaBbLE-Shop.md:16`). If the existing filings are live and close, the name question comes first, before any promo.
2. **Intent-to-use filing** (15 USC 1051(b)) in class 9 if clearance looks clean: sets a nationwide priority date from filing; $350 per class since 2025-01-18 (https://www.uspto.gov/trademarks/fees-payment-information/summary-2025-trademark-fee-changes). Unfiled ™ rests on actual use in commerce and is local; showing an unsold product on Instagram is weak use.
3. **Copyright registration of the canonical entity art** (US Copyright Office, roughly $45 to $65). The design is already protected by copyright from creation; registration is needed before suing and unlocks statutory damages if made before infringement or within 3 months of first publication. If the Instagram posts are the first publication, that window opens with them.
4. **One identical clause in all 8 LICENSEs**, plus the Toll product-name fix: *"This Accord grants no rights in the RaBbLE names or logos, or in the RaBbLE entity's design and likeness, even where the software renders them."* Closes problem 1 without half-changing anything; costs a second LICENSE revision later.
5. **™ in public copy** on RaBbLE™ and RaBbLE Pocket™, owner The RaBbLE Collective (decided); the promo kit keeps it in one variable, and nothing is posted until the name is cleared.

## End state (after a lawyer): three layers, one canonical text

1. **The Code · Sovereign Accord v2.** Source-available, never "open source". Options for the operative text:
   - **(a) PolyForm Noncommercial 1.0.0 base** (https://polyformproject.org/licenses/noncommercial/1.0.0) with an Accord preamble and our own carve-outs. Tested text with definitions, termination and a patent clause, but it **contradicts current canon**: it allows noncommercial redistribution and new works without asking (`RaBbLE-Service-Plan.md:44` says redistribution and hosted derivatives need explicit agreement); it isn't share-alike (forks needn't keep the Accord, unlike the Thread); any charity, school or government body may use it "regardless of the source of funding", so a nonprofit could host a free RaBbLE service. It says nothing about trademarks ("These terms do not imply any other licenses"); the carve-out is ours to add.
   - **(b) Bespoke text with lawyer-drafted definitions**, keeping the Thread's share-alike and the redistribution/hosting gate.
   - **(c) Time-based conversion** (BSL 1.1, up to 4 years; FSL, 2 years to Apache/MIT; https://fair.io): listed so it's seen and decided. It ends in open source, which the Accord's stance rules out.
2. **The Brand · trademarks + a Brand and Entity Policy** (Mozilla model: code licensed, forks rename, as with Iceweasel). Always fine: "built on RaBbLE", "a fork of RaBbLE", "works with RaBbLE"; running the official code, or your own changes, on your own devices with the entity on screen. Needs the Collective's ok: shipping anything called RaBbLE, selling anything showing the entity, merch.
3. **The Art · reserved, in an assets tier.** Games and Blender separate engine code from assets and marks. Technically: move the entity's canonical parameters and art into an assets tier excluded from the code grant, with a placeholder face forks get by default. A carve-out that relies only on "even where the code renders it" is hard to enforce on a fork that keeps the code. For fans, a **revocable fan-content policy** (reposts and fan art ok, noncommercial, no implied endorsement) rather than CC BY-NC-ND, which is irrevocable and forbids fan art (ND); CC 4.0 already excludes trademarks (s.2(b)(2)).

One canonical text in the Grimoire, synced unchanged into every member by a spell, with a short per-repo NOTICE naming the product and third-party scope.

## Decisions for Mark

Decided 2026-10-25: owner (1), code text (3), what to register (part of 4), forks (2, a middle path: tweak within bounds, never claim to be RaBbLE). See "Mark's decisions" above.

Also decided: **governing law Ohio** (2026-10-25).

**Mark's position (2026-10-25, later the same day):**
- Registration is **not** required before posting. Copyright is automatic; register the entity art within 3 months of first publication to keep statutory damages and fees. A name clearance check comes soon after posting starts, before heavy investment in the name; it doesn't gate the first post.
- **Forks are for personal use or contributions back to the Collective.** Publicly distributed rebrands are not granted (reserved).
- **The Entity** is granted under a limited-use license.
- **NeBuLA** is free to use to render your own effects.
- The old Accord was too permissive, but this doesn't need plumbing now: the Accord reserves enough for the Collective to restrict or enable later. The v2 drafts stay as drafts; their fork sections (Accord 2.3, 3, 4.3 and the Policy's "Within bounds") get reshaped to this position when v2 is picked up.

**Deferred by Mark (2026-10-25), revisit before v2 goes into any LICENSE:**
- Filings: which classes (9 first; 42, 25, 16) and timing of the intent-to-use and the face design mark.
- Contributions inbound: the one-page Contributor Agreement. Until it exists, no outside contributions.
- Fans: the revocable fan-content policy.
- Creator/Shop license for Pairs selling designs and rablets.
- Forks: confirm the overall-impression test + neutral fork-face preset, and where a Fork starts (public release vs. sharing with friends).
- Aether tokens: gifted as Software, or reserved with the Entity.
- The interim one-clause LICENSE edit ("Do now" 4): optional, not scheduled.

## Next once decided

1. Lawyer review: clearance result, filings, v2 text, Brand and Entity Policy, fan-content policy, creator license, in `RaBbLE-Grimoire/RaBbLE-Collective/` (canonical home).
2. Spell to sync LICENSE into every member; update the `feedback_sovereign_accord_license` guidance and Agent-Protocols.
3. Source headers stay as they are (`RaBbLE Sovereign Accord.` points at the repo LICENSE), so W7's header sweep doesn't need redoing.
4. The assets tier for the entity is a NeBuLA + Pocket refactor; plan it after decision 2.

## Decisions 2026-10-29 (S290) · interim Accord in force

Mark's positions, folded into `RaBbLE-Collective/RaBbLE-Sovereign-Accord.md` (the canonical text, synced into every member LICENSE by `spells/sync-license.sh`, `--check` for drift):

- **One licence, three parts:** the Gift (Software), the Reservation (name, Entity, face: not licensed), the Toll (commercial). No separate licences; a Brand and Entity Policy can come later and is not a licence.
- **Owner is The RaBbLE Collective only**; Mark's name is out of the text (the d/b/a filing carries the legal side).
- **Personal mods and free resharing granted**, public git forks included, under the Accord with credit and source link.
- **Referring is open, presenting is reserved.** A fork may keep the repo name and code names and say "fork of RaBbLE-OS". Shared forks that show a name to users (boot, login, installer, app, site) use their own ("Sprocket, a RaBbLE mutation"). A mutation is a new entity in the lineage (`RaBbLE/Genesis/RaBbLE-Lineage.md`), not a second RaBbLE.
- **Reserved without a pact:** RaBbLE as the name of a portal, site, service, account, domain, company or product; merch showing the Entity; confusingly similar registrations. A hosted service for others is Commercial Use.
- **Still open for v2 / lawyer:** contributor agreement (no outside contributions until it exists; without it inbound = outbound would give the Collective noncommercial rights only), filings and classes, fan-content policy, creator/Shop licence, the Entity limited-use grant (reserved entirely for now), entity assets tier, Atreum RABBLE class 9 registration (6713996, goods wording unread: check TSDR 90042611). Chrysalis, BaBbLE and Xperimental have no LICENSE.
