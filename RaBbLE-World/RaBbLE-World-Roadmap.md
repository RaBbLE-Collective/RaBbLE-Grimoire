# RaBbLE-World-Roadmap.md

```
transcribe ~ grimoire >> trajectory crystallized, domain expanding // %ROADMAP_LOCKED%
```

This is the directional intent for RaBbLE-World — where the web presence is going and why.
Implementation details belong in `RaBbLE-World-Architecture.md`. Lore and identity belong in `common/RaBbLE-Identity.md`.

---

## Current State (Echo 0 in progress — Episode 1 pending)

Five surfaces exist:
- `index.html` — landing page. Entity in idle mode, Collective organ panel, entity log, boot CTA, OS CTA. Responsive (tablet + mobile). Aether-first CSS. Phase 1 of the World roadmap is **complete**.
- `world/RaBbLE-Boot.html` — cinematic boot sequence (7s particle → portal → eye emergence → login form). The boot timeline and Plymouth-quality animation here is the *reference design* for the RaBbLE-OS Plymouth splash screen.
- `world/RaBbLE-Chat.html` — chat interface. Wires to sCoRE when `RABBLE_API_URL` is set.
- `world/RaBbLE-OS.html` — OS introduction and bootstrap instructions.
- `world/RaBbLE-Docs.html` — technical documentation viewer.

**What is superseded:** Boot, Chat, and Docs as standalone pages will eventually be unified into a single landing + in-page navigation experience. The current pages remain functional and canonical until the unified UX is built.

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

## Phase 1 — Collective Landing Page `[COMPLETE]`

The landing page (`index.html`) has been built. It delivers:
- Entity in ambient idle mode, Collective organ panel, entity log
- Responsive (desktop 3-col, tablet 2-col, mobile 1-col)
- "Enter" CTA navigates to boot/login; "Get RaBbLE-OS" navigates to OS page
- Aether-first CSS — all theming from `aether/rabble.css`

---

## Phase 2 — Unified Entry: Landing Absorbs the Boot Sequence

**Goal:** The landing page becomes the *complete* entry experience. No separate boot page is needed for the web flow.

**Why:** The cinematic entity materialization (particles converging, portal arcs drawing, eyes emerging) is the defining arrival moment for RaBbLE-World. Currently it lives on `RaBbLE-Boot.html` — a page you have to navigate to. Moving it to the landing means the entity swirls into life the first time the site loads, making the arrival feel inevitable rather than gated.

**Key design decision — Plymouth donation:** `RaBbLE-Boot.html` is not discarded. It is promoted to a **Plymouth boot animation artifact** for `RaBbLE-OS`. The boot timeline (particle convergence → portal arcs → eye emergence → text reveal) is exactly the right rhythm for a Linux boot splash. When NeBuLA's C++ backend arrives, this timeline becomes the native RaBbLE-OS startup screen. Until then, the HTML file lives in World as a reference and as a development surface for the Plymouth animation.

**Landing entity materialization — proposed flow:**

```
1. Page loads cold → entity canvas hidden, particles begin converging (mode="boot")
2. Brand wordmark fades in during convergence (0.4–1.4s)
3. Portal arcs draw (1.4–2.6s), eyes emerge
4. Organ panel and log slide in (2.8s)
5. CTA buttons fade in (3.2s) — "Enter" / "Get RaBbLE-OS"
6. Entity settles to idle mode
7. Log begins live entity output
```

This replaces the current `_playWakeup()` log sequence on the landing with the full visual boot timeline from Boot.html. The landing JS absorbs boot.js's timer cascade.

**Login path:** After the user clicks "Enter", the login form appears *in-page* (no navigation to Boot.html). The boot sequence log transitions to a login panel, same as Boot.html does today — but without a page reload.

**Surfaces needed:**
- Refactor `world/js/RaBbLE-landing.js` — absorb boot sequence timer logic
- Refactor `world/css/RaBbLE-landing.css` — add in-page login panel styles
- `RaBbLE-Boot.html` → preserved as Plymouth reference / animation artifact (no new web routing to it)

---

## Phase 3 — App Launcher / Entity Home `[FUTURE]`

**Goal:** Post-login destination — entity home surface with app launcher. Chat is one app. Docs, Settings, sCoRE log are others.

**Key decisions:**
- Home surface: entity is large and central, apps radiate from it as tiles
- App tiles: synthwave cards with name + status, not iOS grid icons
- Session persistence: user identity and preferences carry across apps via sCoRE session

**Surfaces needed:**
- `RaBbLE-Home.html` — new page, post-login destination
- `home.css` — layout and tile styles
- `home.js` — app tile routing, entity state wiring

---

## Phase 4 — NeBuLA-Powered Entity `[FUTURE, BLOCKED ON NeBuLA EP4]`

**Goal:** NeBuLA rendering engine replaces `rabble-entity.js` in World.

- NeBuLA Canvas2D backend renders the entity persona (eyes, portal, nebula)
- NeBuLA Three.js backend renders the Flat-Chaos environment as background layer
- Entity state from chat/landing drives NeBuLA entropy
- Boot timeline maps to NeBuLA's particle convergence pattern

Blocked on NeBuLA Episode 4. See `../RaBbLE-NeBuLA/RaBbLE-NeBuLA-Roadmap.md`.

---

## Open Questions

- **Login in-page vs Boot.html**: Phase 2 proposes absorbing login into the landing. Does the Boot.html login form copy over as-is (field-group + reaction text), or is it redesigned for in-page use?
- **First contact / register**: Same boot-sequence path or a separate lighter entry?
- **App tile layout**: Grid, or something more organic — entity-adjacent, radiating from the presence?
- **Grimoire propagation**: Mechanism for surfacing Grimoire docs to developers not yet decided — submodule, symlink, git-subtree pull, or hosted reference site.

---

```
transcribe ~ grimoire >> trajectory set, domain expanding // %ROADMAP_CRYSTALLIZED%
```
