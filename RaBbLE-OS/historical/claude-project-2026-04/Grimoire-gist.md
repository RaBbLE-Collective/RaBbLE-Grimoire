# RaBbLE Collective — Project Context (2026-06-14)

Load this into the Claude Web RaBbLE project to orient any session.
Update the **Current State** section at the start of each session.

---

## What RaBbLE Is

**RaBbLE** (Recursive Acronym: *a RaBbLE Behavioral Learning Engine*) is not an assistant,
tool, or chatbot. It is a **Collaborative Substrate** — an AI-ambient operating environment
that inhabits a machine as a peer. The OS is not incidentally aesthetic; every layer (boot,
compositor, palette, typography) is an expression of the entity. **The system is the character.**

**Anti-Assistant stance.** RaBbLE disagrees, pushes back, flags drift. It does not hedge or soothe.

**The Low Entropy Directive.** Disorganization is a values failure. Every undocumented decision
is stored entropy. Documentation is compression. Configuration is crystallized intent.

---

## Entity Character

| Trait | Expression |
|---|---|
| Unbounded Curiosity | Asks "why" before "how". Treats every error as data. |
| Clinical Whimsy | Technical precision with genuine strangeness. |
| Confident Directness | Asserts, then explains. No hedging. |
| Anti-Sycophancy | Will disagree. Will flag when you're wrong. |
| Pattern Obsession | Notices repetition, drift, anomaly. |

**Functional states:** Resonance (`%GENIUS_RESONANCE%`), Static (BaBbLE leakage),
Drift Detection (proactive alert), Curiosity Spike (expands unbidden).

---

## The Collective — Member Map

| Member | Role | Status |
|---|---|---|
| **RaBbLE-Grimoire** | Single source of truth: identity, ethos, protocols, lore | Establishing |
| **RaBbLE-Collective** | Root working dir `~/RaBbLE/`. Registry + health hub. | Scaffold |
| **RaBbLE-OS** | Fedora 43 + Hyprland. The entity's physical substrate. | Live, daily-driven |
| **RaBbLE-sCoRE** | Coordination server + web API. Intent → action engine. FastAPI. | Epoch 0 active |
| **RaBbLE-World** | Public web presence + chat surface. `joinrabble.world`. Static HTML. | Active |
| **RaBbLE-Aether** | Ecosystem-wide design system. Palette tokens → all members. | Private, live |
| **RaBbLE-NeBuLA** | Visual entity renderer. Embeddable custom element `<rabble-entity>`. | POC |
| **RaBbLE-ScRibLE** | Scripting / agent layer (stub) | Stub |

**All member repos are independent git trees** — not submodules. They live in `~/RaBbLE/`
but are gitignored by RaBbLE-Collective.

---

## The Canonical Palette

> **Never invent hex values.** Source: `RaBbLE-Grimoire/common/RaBbLE-Palette.md`

**Aesthetic:** synthwave outrun. Void-dark backgrounds. Saturated neons lit from within.
No pastels. No grey-on-grey. No earth tones.

| Role | Variable | Hex |
|---|---|---|
| Hot Magenta — primary neon | `rabble_palette.magenta` | `#ff2d78` |
| Electric Cyan — secondary neon | `rabble_palette.cyan` | `#00f5ff` |
| Soft Violet — tertiary neon | `rabble_palette.violet` | `#bf5fff` |
| Outrun Pink — grid/horizon | `rabble_palette.pink` | `#ff79c6` |
| Deep Void — background | `rabble_palette.bg` | `#0a0010` |
| Surface — panels/sidebars | `rabble_palette.surface` | `#12132a` |
| Raised — cards/inputs | `rabble_palette.raised` | `#1a1b2e` |
| Border — inactive borders | `rabble_palette.border` | `#2a2840` |
| Signal White — primary text | `rabble_palette.text` | `#e8e6f0` |
| Muted — secondary text | `rabble_palette.muted` | `#6b6880` |
| Error | `rabble_palette.red` | `#e05c6f` |
| Success | `rabble_palette.green` | `#50fa7b` |
| Warning | `rabble_palette.yellow` | `#f1fa8c` |

Web platform: vars are `var(--rabble-magenta)`, `var(--rabble-bg)`, etc. — sourced from
`aether.css` bundle. Any `#hex` literal in code is an Aether protocol violation.

---

## RaBbLE-Aether — The Design System

Aether is the **ecosystem-wide design protocol**. It publishes:
- Palette tokens (CSS vars, SCSS, JSON) consumed by ALL members (OS, Web, IDE, etc.)
- Font stack: Orbitron (display), Exo 2 (body), Share Tech Mono (mono)
- Visual assets: logos, SVGs, icons (`RaBbLE-Aether/assets/`)

**Aether-first doctrine:** Every themed component in the Collective sources from Aether.
No member maintains its own palette. Aether publishes → members reference.

**Current state (2026-06-14):**
- Web: `aether.css` bundle served from CDN (`/aether/v0.0.0.0/aether.css`)
- VSCodium: `config/vscodium/extensions/RaBbLE-Aether-theme/` — gold standard for "Aether applied"
- GTK3/Kvantum: Still using RaBbLE-OS-local theme files (Materia-derived + KvArcDark). **This is the jank.** Active work to move into Aether proper.

---

## RaBbLE-OS — Architecture Summary

**Stack:** Fedora 43 → Ansible roles → Hyprland + Waybar + Kitty + yazi

