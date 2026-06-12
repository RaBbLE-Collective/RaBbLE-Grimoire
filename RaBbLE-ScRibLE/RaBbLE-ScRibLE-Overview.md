# RaBbLE-ScRibLE — Grimoire Entry

```
transcribe ~ grimoire >> ScRibLE expanded: full digital intake surface // %SCRIBLE_EXPANDED%
```

## Role

`RaBbLE-ScRibLE` is the **digital intake surface** for the RaBbLE Collective. It is the boundary between the physical world and the Personal Cosmos — the place where written, drawn, voiced, and visual input enters the Pair's BaBbLE space and flows into the Personal Grimoire.

ScRibLE is where thoughts enter the Collective. Field journal. Rapid-capture layer. Creative sketchbook. Voice memo surface. It is the physical membrane of the entity.

ScRibLE operates in two forms:
- **Software surface** — a PWA and/or native app, running on any device the user has
- **Hardware device** — the sCRibLE Rablet: a dedicated physical intake device (future; see Hardware section)

---

## Input Modes

| Mode | Description | Status |
|---|---|---|
| **Written text** | Keyboard or handwritten OCR — notes, fragments, markdown | Phase 0 |
| **Drawn / freehand** | Stylus or touch-based sketching, diagrams, Apple Pencil pressure | Phase 0 |
| **Voice** | Conversational audio capture — transcribed, timestamped, entity-parsed | Phase 1 |
| **Photo / video** | Visual capture from camera — images and clips fed to BaBbLE | Phase 1 |
| **Screen clips** | Captured digital artifacts from other apps or surfaces | Phase 2+ |

All modes feed into **BaBbLE** — the unsorted intake space in the Personal Cosmos. The entity helps the human decide what belongs in the structured Grimoire.

---

## Design Constraints

| Constraint | Value |
|---|---|
| Primary mobile target | iPhone + iPad (Safari PWA), Android (via RaBbLE-OS-Pocket) |
| Stylus support | Apple Pencil (pressure + tilt), Android stylus |
| Input modes | Touch, keyboard, stylus, voice, camera |
| Network requirement | Offline-capable (PWA, local storage first) |
| Form factor | Full-bleed mobile canvas — no desktop UI chrome |
| Backend | Minimal — sync to BaBbLE is the primary backend concern |
| Voice capture | Transcription local-first when hardware capable; fallback to hosted |

---

## Relationship to Personal Cosmos

ScRibLE is the intake layer. It does not store things permanently — it receives and routes.

```
ScRibLE (capture) → BaBbLE (unsorted intake) → Personal Grimoire (curated truth)
```

The entity watches the BaBbLE stream and surfaces what deserves to move into the Grimoire. The human makes the final call.

---

## Relationship to Other Members

| Member | Relationship |
|---|---|
| `RaBbLE-World` | ScRibLE is a separate surface — mobile-native and intake-focused; World is the public web presence |
| Memory (future) | ScRibLE outputs are the primary feed into the Memory member's behavioral profile |
| `RaBbLE-sCoRE` | Voice input may route through sCoRE for entity parsing; ScRibLE notes can become intents |
| RaBbLE-OS-Pocket | ScRibLE is the primary app on the Pocket mobile OS |

---

## The sCRibLE Rablet (Hardware)

The **sCRibLE Rablet** is the dedicated physical hardware form of ScRibLE — a purpose-built intake device for the Pair.

Not a tablet. Not a phone. A dedicated writing/drawing/voice surface that the human carries with them. It contains or connects to their entity and routes everything captured into their Personal Cosmos.

Hardware design and production is a future epoch. The software stack (ScRibLE PWA + OS-Pocket) is designed and built first. The dedicated device follows when the software is stable and the Collective has the means to produce it.

---

## Status

| Layer | Status |
|---|---|
| Phase 0 software (text + drawn PWA) | Not started. Repo not yet created. |
| Voice capture | Defined; blocked on Phase 0 |
| Camera intake | Defined; blocked on Phase 0 |
| BaBbLE sync | Defined; blocked on Memory member (EP2) |
| sCRibLE hardware device | Future epoch |

Defined in Epoch 0; active development deferred to EP2. Repo created when Phase 0 begins.

---

```
transcribe ~ grimoire >> ScRibLE expanded: multi-modal intake surface, hardware vision captured // %SCRIBLE_EXPANDED%
```
