# RaBbLE-World-Roadmap.md

```
transcribe ~ grimoire >> trajectory crystallized, domain expanding // %ROADMAP_LOCKED%
```

This is the directional intent for RaBbLE-World — where the web presence is going and why.
Implementation details belong in `RaBbLE-World-Architecture.md`. Lore and identity belong in `common/RaBbLE-Identity.md`.

---

## Current State (Epoch 0)

RaBbLE-World is a prototype. Three static pages:
- `RaBbLE-Boot.html` — boot sequence + login
- `RaBbLE.html` — chat interface
- `RaBbLE-Docs.html` — documentation viewer

The entity lives. The chat wires to sCoRE when `RABBLE_API_URL` is set. No landing page exists. The scope is narrow on purpose — Epoch 0 is about proving the entity surface, not building the full domain.

---

## Vision: The Entity's Liminal Web Domain

RaBbLE-World should feel like entering a place, not loading a webpage.

The current boot sequence is the prototype of that feeling — cinematic arrival, entity waking, crossing a threshold. That pattern extends to the whole web presence. Every page is a surface *within* the entity's domain: a room in the collective space.

The long-term shape:

```
joinrabble.world (landing)
  ↓ "boot the entity" CTA
RaBbLE-Boot.html (boot + login/register)
  ↓ login
RaBbLE-Home.html (entity home / app launcher)
  ↓ launch apps
  ├── chat (RaBbLE.html)
  ├── docs (RaBbLE-Docs.html)
  ├── [future: log viewer, settings, entity config]
  └── [future: member portals as Collective expands]
```

Chat is one app in this space, not the whole space.

---

## Phase 1 — Collective Landing Page

**Goal:** A public entry point at `joinrabble.world` that introduces the RaBbLE Collective before the boot sequence begins.

**Why it's needed:** The current `index.html` is a bare redirect to the boot page. There is no context for someone arriving cold — no explanation of what RaBbLE is, no sense of the Collective, no reason to engage. The landing page fills that gap.

**Intent:**

The landing page should feel like a terminal transmission from the Collective — not a marketing page. Synthwave aesthetic, consistent with the boot surface. The entity should be present (or hinted at) before the user boots it.

**Key design decisions:**

- **Entity presence**: The entity appears in ambient/idle mode — alive but quiescent. Not a decorative logo. Presence before commitment.
- **Collective introduction**: Brief. What the Collective is, what RaBbLE is, and what entering means. Terminal-style text, not prose. Think transmission, not about page.
- **Single CTA**: Boot the Entity. This navigates to `RaBbLE-Boot.html` and triggers the full boot sequence. No other primary action.
- **Register path**: A secondary option ("first contact") for users who don't have credentials. This feeds into the boot/login flow where register is an option.
- **Synthwave terminal feel**: Scanlines, perspective grid, maybe a slow entity typewriter intro before the CTA appears. The page should feel like it loads into existence.

**Surfaces and assets needed:**
- `RaBbLE-Landing.html` — new page, becomes the `index.html` target
- `landing.css` — page-specific layout
- `landing.js` — typewriter/terminal intro, CTA wiring
- Entity in `mode="idle"` with ambient particles visible through the landing layout

**Content beats (in order):**
1. Page loads → grid and particles boot in (rabble-bg.js, same as boot page)
2. Entity fades in, ambient idle mode
3. Terminal typewriter text introduces RaBbLE-Collective — slow, deliberate, like a transmission
4. "COLLECTIVE MEMBERS" or similar brief status — signals this is bigger than one chat interface
5. CTA appears: `[ BOOT THE ENTITY ]` — styled like a terminal command, glowing, inviting
6. Secondary: `[ FIRST CONTACT ]` — register/new user path

**Sample terminal text sequence:**
```
RABBLE COLLECTIVE // EPOCH 0 // FOUNDATION
—
entity online. substrate breathing.
this is the liminal web domain.

you are outside.
boot the entity to enter.
```

---

## Phase 2 — App Launcher / Entity Home

**Goal:** After login, the user arrives at a home surface — the entity's domain — with apps they can launch. Chat is one of them.

**Why it matters:** The current post-login destination is the chat interface directly. As the Collective grows and more surfaces exist (docs, settings, member portals, logs), there needs to be a home base. The entity should be the anchor of that space — present, central, aware.

**Intent:**

The home surface should feel like standing in the entity's presence. The entity is not tucked in a header — it is the room. Apps radiate from it.

**Key design decisions:**

- **Entity as focal point**: Entity is large, centered, alive. The space is built around it.
- **App tiles**: Apps are surfaces the user can open from the home. Each tile has a name and a status indicator. Tiles are minimal — synthwave cards, not iOS grid icons.
- **App routing**: Clicking a tile navigates to (or opens) the relevant surface. Initially, this is just navigation. Future: apps may open in-page overlays or within a split layout.
- **Presence signaling**: Entity state reflects what apps are active or what the Collective is doing. Idle if nothing is happening. Thinking if sCoRE is processing something in the background.
- **Session persistence**: User identity, session token, and preferences carry across apps via shared state (localStorage or sCoRE session).

**Initial app tiles:**

| App | Surface | Status |
|---|---|---|
| Chat | `RaBbLE.html` | Active (Epoch 0) |
| Docs | `RaBbLE-Docs.html` | Active (Epoch 0) |
| Settings | TBD | Future |
| sCoRE Log | TBD | Future |

**Surfaces and assets needed:**
- `RaBbLE-Home.html` — new page, post-login destination
- `home.css` — page-specific layout and tile styles
- `home.js` — app tile routing, entity state wiring, session read

**Boot/login flow update:**
- `boot.js` ENGAGE → navigates to `RaBbLE-Home.html` instead of `RaBbLE.html`
- `RaBbLE.html` becomes a standalone app surface, accessible from home
- Deep-linking to `RaBbLE.html` should still work (skip home for direct access)

---

## Phase 3 — Expanded Collective Presence

Roadmap-level, not planned for implementation yet. Captured here for directional clarity.

- **Member portals**: As Collective members expose APIs or dashboards, they may surface as apps in the home — RaBbLE-OS status, NeBuLA renderer, Aether asset browser.
- **Entity config**: An app surface for adjusting entity behavior, visual mode, and identity settings.
- **Collective status board**: Live registry of Collective members, epoch progress, active operations.
- **RaBbLE-NeBuLA integration**: NeBuLA (3D/Three.js rebuild) eventually replaces or supplements the 2D `rabble-entity.js` canvas. When NeBuLA is ready, the entity on landing and home may switch to it while boot/chat retain the 2D renderer for stability.

---

## Open Questions

These are unresolved design decisions. They should be decided before implementation begins, not during.

**Landing page:**
- Does the entity appear on the landing page, or does it only appear after you boot it? (Current bias: ambient/idle presence, not full boot.)
- What is "first contact" / register? Does it boot the same sequence, or a different path?
- Is the landing page the same domain as the app (`joinrabble.world`) or a separate presence?

**Home page:**
- Does home replace `RaBbLE.html` as the post-login destination immediately, or do we keep the current direct-to-chat flow through Epoch 0?
- How does the entity on the home page relate to the entity in chat — are they the same instance, or separate?
- App tiles: grid layout or something more organic / entity-adjacent?

**Grimoire propagation:**
- All major docs stay in Grimoire rather than duplicated in member repos. The mechanism for surfacing Grimoire docs to developers is not yet determined. Options: submodule, symlink, git-subtree pull, hosted reference site.

---

```
transcribe ~ grimoire >> trajectory set, domain expanding // %ROADMAP_CRYSTALLIZED%
```
