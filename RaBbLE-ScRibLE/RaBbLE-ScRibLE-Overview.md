# RaBbLE-ScRibLE — Grimoire Entry

```
transcribe ~ grimoire >> ScRibLE defined // %SCRIBLE_DEFINED%
```

## Role

`RaBbLE-ScRibLE` is the mobile notes input surface for the RaBbLE Collective.
It is a progressive web app (PWA) designed for iPhone and iPad — touch-first,
Apple Pencil aware, usable in portrait and landscape.

ScRibLE is where thoughts enter the Collective. It is the human handwriting surface,
the field journal, the rapid-capture layer. Notes taken in ScRibLE feed into
the broader RaBbLE memory and knowledge architecture when that layer exists.

---

## Design Constraints

| Constraint | Value |
|---|---|
| Primary target | iPhone + iPad (Safari PWA) |
| Input modes | Touch gestures, Apple Pencil, keyboard |
| Network requirement | Offline-capable (PWA, local storage first) |
| Form factor | Full-bleed mobile canvas — no desktop UI chrome |
| Backend | Minimal — sync is a later concern |

---

## Planned Features (Phase 0 Scope)

- [ ] Freehand drawing / handwriting canvas (Apple Pencil pressure + tilt)
- [ ] Text note entry (markdown or plain)
- [ ] Tag / label capture
- [ ] Local storage (IndexedDB)
- [ ] PWA install: add to home screen, offline mode
- [ ] RaBbLE palette and entity presence (entity.js integration TBD)

---

## Relationship to Other Members

| Member | Relationship |
|---|---|
| `RaBbLE-World` | ScRibLE is a separate surface — mobile-native. World is the web presence. |
| Memory (TBD) | ScRibLE outputs feed into Memory once that member exists |
| `RaBbLE-sCoRE` | Future: ScRibLE notes could become intents routed through sCoRE |

---

## Status

Phase 0 — Not started. Repo not yet created.
Defined in Epoch 0; active development deferred to Epoch 1 or later.
