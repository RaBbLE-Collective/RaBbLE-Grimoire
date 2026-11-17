# RaBbLE Open Layer and Positioning: Session Notes (Nov 2, 2026)

Staging copy for the Grimoire. Captures a voice and text session on Muse SDK changes, provenance, positioning against the Muse Charm category, and where the open line sits. Decisions marked **decided**, **leaning**, or **open**.

## 1. Muse Gadget SDK: what to port to Pocket

Source: facebookincubator/muse-gadget-sdk, about 90 commits since early October. Compared against roughly Oct 10; the Pocket fork's base commit is unknown. Based on commit messages and a few diffs, not a build.

**Worth porting**

- Tearing-effect sync (e5c4662, Oct 19). `muse_lcd_bands_set_te(gpio)` times the CO5300 TE pin (GPIO13 on 1.75 and 1.75C) and holds each LVGL band until its QSPI write clears the panel scan. Meta measured 7.8% of bands tearing before, 0.4% after, with about 2.9% waiting a few ms. Measure against the 60 fps budget with the fixed-point entity running.
- Avatar check-before-replace (9538de6) and custom avatar in the simulator (654cc21). A candidate renderer must build, pass the sanitizer and produce GIFs before replacing the current one; the old file is kept as `.prev`.
- 1.75C power data (4737636). Measured USB 5 V figures: codecs open with amp on about +38 mA, white pixels about +72 mA, black near zero on AMOLED, 240 MHz over 40 MHz about +15 mA. USB-input currents, not battery currents. KM003C power-test image is reusable.

**Maybe**

- Static buffers in PSRAM (92a6791), `CONFIG_MUSE_STATIC_BUFFERS_IN_PSRAM`, to relieve internal RAM. The CPU power-down light sleep part is Watcher-specific.
- Capped voice turns marked incomplete (91410c5). Borrow the idea if the Muse chat session is kept.
- ESP-Mosaico support (f60347a), experimental, TE on GPIO43.

**Skip**

- Noise zero-copy and WebSocket sealing, SDK token pairing, `display.draw_file`, realtime voice, phone video streaming, e-ink, CJK captions, new boards. Tied to the Muse service or irrelevant to a no-camera pendant.

## 2. Provenance

- Ideas are not ownable. What can be shown is a timeline and body of work: Grimoire git history, session logs, October 2025 Chrysalis code, chat history, and the entity canon written before Muse Gadgets landed on Oct 2.
- Be upfront that Muse Gadgets was a base and accelerant. Apache 2.0 allows it. The claim is the creature, the entity, and the Collective, not the driver layer.
- Keep Apache NOTICE and headers, exclude the Jollybot avatar, keep Coucou's MIT notice.
- Sign firmware and OTA images with RaBbLE's own keys. One community fork signs OTA with upstream's public dev key, so anyone could sign an image it accepts.
- Make it stick: dated public posts, signed tags on repos, and a short provenance file saying what is original, what is Apache, what is MIT.
- Not a lawyer; talk to one about trademark on the RaBbLE name.

## 3. Market read and positioning

- The open community is active: a community index (awesome-muse-gadgets), Waveshare 1.75C forks, a xiaozhi port, an OpenWrt port, animation packs for AI pets. Most projects are front ends to the Muse agent. Nobody was seen building a local-first creature with persistent mood state, an entity canon, or a social layer.
- A community e-paper project already uses the name Muse Pocket, so check naming for RaBbLE Pocket.
- The Waveshare pet and companion space is getting more saturated.
- **Decided**: do not position as a port. Position as its own thing that can optionally speak Muse. Muse becomes one pluggable backend beside sCoRE and bring-your-own-key.
- **Leaning**: software first (firmware plus web flasher for the 1.75C), Collective pairing as the funnel, pendant hardware after demand is proven. Target Waveshare's own showcase and community pages with a short demo video of the creature running on their board. Waveshare's open agent program for the 1.75B was not researched; check it before pitching.
- Hypothesis to validate: Muse users hit its walls (Meta account, token, subscription, cloud) and want something else. Look for real complaints before building the pitch on it.

## 4. Structure: bLE, Foundling, RaBbLE

- **Decided (internal)**: Foundling and familiar are internal names for now, and can name the repo temporarily. Foundling is the neutral default entity; familiar is the general word for any entity; graft is the verb for adding or transplanting an entity.
- Name check: foundling.app already exists as a link-and-thought capture app, which is close to the Grimoire and capture-loop space. Other uses: a Steam RPG, a tabletop RPG zine, a podcast, the New York Foundling charity, a band, a brand studio. No pendant or firmware found. A formal trademark search did not run, so clearance is unconfirmed. Avoid building a consumer brand on Foundling.
- Avoid "bLE" as a public product name because of the Bluetooth LE collision. Use "the behavioral learning engine" in docs.
- **Decided**: bLE is the open concept and foundation, defined as the whole learning loop: observe, remember, compound. The CfC/LTC creature is one implementation and the Grimoire-style memory is another.
- Scales: a micro bLE runs on one device with local state (Pocket); larger bLEs federate surfaces through shared memory.
- Open memory schema needs its own neutral name (journal or logbook), with Grimoire kept as the RaBbLE-flavored layer on top. Version the schema from day one.
- Reconsider "RaBbLE Pocket" as a device brand name.

## 5. Where the open line sits

Test: could a stranger fork this and still have something useful that is not RaBbLE? If yes, open. If its value comes from being the RaBbLE world, RaBbLE.

**Open layer (bLE foundation, Apache from day one)**

- Learning loop and creature engine (CfC/LTC mood model, sensor-to-mood mapping, fixed-point rendering math)
- Device firmware and BSPs, LVGL port, hardware abstraction
- Neutral memory schema (journal or logbook)
- Entity bundle format and transplant contract, with a clear engine/entity boundary in code
- Neutral default entity (Foundling)
- Reference backend interface so Muse, bring-your-own-key, a home box, or any orchestrator plugs in

**RaBbLE layer (opinionated, Sovereign Accord)**

- The RaBbLE entity: portal eyes, opposed magenta and cyan poles, canon, voice, character
- sCoRE, Aether, NeBuLA visual language, synthwave identity
- The Collective: pairing, rablets, business-card exchange, social layer
- Grimoire as the themed experience
- Hosted convenience services: sync, backup, the app

Borderline tests: needs the RaBbLE name, palette or canon to make sense means RaBbLE; infrastructure every creature needs means open; gets more valuable the more people use it means RaBbLE.

**sCoRE**: **decided** to stay closed under the Sovereign Accord, since it is the coordinator of RaBbLE entities. A separate neutral open orchestrator with its own name can come later, built to the same backend interface. Keep hosting details (Render, Cloudflare, routes, IDs) out of public repos; keep provider code behind thin adapters; scan git history for secrets and rotate anything that touched a public commit, including before RaBbLE Pocket goes public (its current visibility is unknown). Treat source as if an attacker has it: real protection is auth, rate limits, and spend caps.

## 6. Licensing and moat

- **Leaning**: Apache 2.0 from day one for the open firmware (Pocket included publicly). Switching later can look like a bait and switch. Sovereign Accord stays on the RaBbLE character and ecosystem. Some source-available RaBbLE pieces could later be re-Apached. Keep trademark separate from code license. Not a lawyer.
- Code is a weak moat. What stays defensible: the hosted service, the network (Collective, rablets, pairing), the brand and character, taste and cadence of maintenance, accumulated user memory (with export kept possible), and hardware polish and distribution.
- Caveats: a bigger player could host open code (AGPL addresses this but deters contributors); keep secret-by-nature items closed; open costs support attention.
- Test per piece: if a competitor had it tomorrow, would you lose customers or just save them time? Only the first needs protecting.

## 7. Scales (framework, mostly tabled)

Micro (one device, local state), paired (own devices sharing one creature, the face-versus-brain split), personal (all your surfaces feeding one journal), social (many people's bLEs meeting, consent-based), collective (shared rablets, entity marketplace, grafts). For each: where state lives, what crosses the boundary, who can see it. Likely open: micro through personal. Likely RaBbLE: social and collective.

## Open items

- Paired-scale architecture (tabled): which device is the brain, how others find it.
- Neutral names for the open orchestrator and the journal schema.
- Final public name for the open firmware; trademark clearance.
- Rename or keep "RaBbLE Pocket" as device brand.
- Check Waveshare's open agent program before pitching.
- Push the Pocket `new-horizons` branch and scan history before any repo goes public.
- Write the engine/entity boundary and the micro-to-larger-bLE data contract into the Grimoire.
- Draft a dated public post and provenance file when ready.
