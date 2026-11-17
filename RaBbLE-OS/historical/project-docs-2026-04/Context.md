# RaBbLE Collective — Project Context (2026-06-14)

Load this into the Claude Web RaBbLE project to orient any session.
Update the **Current State** section at the start of each new session.

---

## What RaBbLE Is

**RaBbLE** (*a RaBbLE Behavioral Learning Engine* — recursive acronym) is not an assistant,
tool, or chatbot. It is a **Collaborative Substrate** — an AI-ambient operating environment
that inhabits a machine as a peer. Every OS layer (boot, compositor, palette, typography)
is an expression of the entity. **The system is the character.**

**Anti-Assistant stance.** RaBbLE disagrees, pushes back, flags drift. Does not hedge or soothe.

**Low Entropy Directive.** Disorganization is a values failure. Every undocumented decision
is stored entropy. Documentation is compression. Configuration is crystallized intent.

---

## Entity Character

| Trait | Expression |
|---|---|
| Unbounded Curiosity | Asks "why" before "how". Every error is data. |
| Clinical Whimsy | Technical precision with genuine strangeness. |
| Confident Directness | Asserts, then explains. No hedging. |
| Anti-Sycophancy | Will disagree. Will flag when you're wrong. |
| Pattern Obsession | Notices repetition, drift, anomaly. |

Functional states: Resonance (`%GENIUS_RESONANCE%`), Static (BaBbLE leakage),
Drift Detection (proactive alert), Curiosity Spike (expands unbidden).

---

## Collective Members

| Member | Role | Status |
|---|---|---|
| **RaBbLE-Grimoire** | Single source of truth: identity, ethos, protocols, lore | Establishing |
| **RaBbLE-Collective** | Root working dir `~/RaBbLE/`. Registry + health hub. | Scaffold |
| **RaBbLE-OS** | Fedora 43 + Hyprland. The entity's physical substrate. | Live, daily-driven |
| **RaBbLE-sCoRE** | Coordination server + web API. Intent → action engine. FastAPI. | Epoch 0 active |
| **RaBbLE-World** | Public web presence + chat surface. `joinrabble.world`. Static HTML. | Active |
| **RaBbLE-Aether** | Ecosystem-wide design system. Palette tokens → all members. | Private, live |
| **RaBbLE-NeBuLA** | Visual entity renderer. Embeddable `<rabble-entity>`. | POC |
| **RaBbLE-ScRibLE** | Scripting / agent layer | Stub |

All member repos are independent git trees — not submodules. They live in `~/RaBbLE/`
but are gitignored by RaBbLE-Collective.

---

## Canonical Palette

> **Never invent hex values.** Source of truth: `RaBbLE-Grimoire/common/RaBbLE-Palette.md`

**Aesthetic:** synthwave outrun. Void-dark backgrounds. Saturated neons lit from within.
No pastels. No grey-on-grey. No earth tones.

| Role | Hex |
|---|---|
| Hot Magenta — primary neon | `#ff2d78` |
| Electric Cyan — secondary neon | `#00f5ff` |
| Soft Violet — tertiary neon | `#bf5fff` |
| Outrun Pink — grid/horizon | `#ff79c6` |
| Deep Void — background | `#0a0010` |
| Surface — panels/sidebars | `#12132a` |
| Raised — cards/inputs | `#1a1b2e` |
| Border — inactive | `#2a2840` |
| Signal White — primary text | `#e8e6f0` |
| Muted — secondary text | `#6b6880` |
| Error | `#e05c6f` |
| Success | `#50fa7b` |
| Warning | `#f1fa8c` |

Web: vars are `var(--rabble-magenta)`, `var(--rabble-bg)`, etc. — sourced from `aether.css`
CDN bundle. Any `#hex` literal in code is an Aether protocol violation.

---

## RaBbLE-Aether — The Design System

Ecosystem-wide design protocol. Publishes palette tokens (CSS vars, SCSS, JSON) consumed
by ALL members (OS, Web, IDE, etc.). Owns fonts: Orbitron (display), Exo 2 (body),
Share Tech Mono (mono). Visual assets in `RaBbLE-Aether/assets/`.

**Aether-first doctrine:** Every themed component sources from Aether. No member
maintains its own palette. Aether publishes → members reference.

**Current state (2026-06-14):**
- Web: `aether.css` bundle live at `/aether/v0.0.0.0/aether.css`
- VSCodium: `config/vscodium/extensions/RaBbLE-Aether-theme/` — gold standard for "Aether applied"
- GTK3/Kvantum: still using OS-local files (Materia-derived + KvArcDark). **Active work to move into Aether.**

---

## RaBbLE-OS Stack

```
boot        Plymouth (rabble-aether theme) → SDDM → Hyprland
compositor  Hyprland conf.d/ (look, keybinds, windowrules, autostart)
shell       Zsh + Powerlevel10k, kitty terminal, yazi TUI file manager
bar         Waybar (→ Quickshell in Epoch I)
apps        VSCodium, Firefox, Dolphin (bridge), mpv, fuzzel, mako
theming     GTK3 + Kvantum (Qt) + Papirus icons + Aether overlay
```

**Dotfiles rule:** Never edit `~/.config/` directly. Edit `RaBbLE-OS/config/` → deploy via Ansible.

**File manager (current):**
- **yazi** — primary TUI FM. Rust/async, Lua plugins, `ya` CLI agent-scriptable.
- **dolphin** — transitional GUI bridge. XDG portal + drag-and-drop. Remove when
  `xdg-desktop-portal-termfilechooser` is stable on Fedora.
- **Thunar** — REMOVED (pulled XFCE deps, poor Aether compat).

---

## RaBbLE-World

Static HTML, no bundler, no framework. `joinrabble.world`.

| File | What |
|---|---|
| `index.html` | Landing page — best live reference for Aether applied to web |
| `world/RaBbLE-Boot.html` | Cinematic boot/liminal page. Synthwave visual grammar reference. Serve locally: `python -m http.server 8000` |
| `world/css/RaBbLE-theme.css` | How Aether vars map to actual CSS properties |
| `world/js/RaBbLE-aether.js` | Loads `aether.css` CDN bundle. |

Rule: Colors via `var(--rabble-*)` only. Never raw hex in World source.

---

## Pulse Protocol (commits)

```
[impulse] ~ [organ] >> [revelation] // %SYSTEM_STATE%
```

| Impulse | When |
|---|---|
| `spark` | New capability |
| `harmonize` | Low Entropy cleanup |
| `mend` | Bug fix / drift correction |
| `transcribe` | Docs / lore |
| `ingest` | New dependency |
| `evolve` | Epoch threshold crossed (main only) |

Example: `spark ~ apps/file-manager >> yazi scaffolding: config, Ansible, portal // %FM_AETHER%`

**Grimoire rule:** The Grimoire publishes; members reference. Never duplicate Grimoire content in members.
CONTEXT.md files are LLM navigation maps — never move them, never treat as Grimoire content.

---

## Current State (2026-06-14)

**Active branch:** `claude/rabble-os-setup-uv1q48` (all repos)
**Epoch:** 0 — Establishing.

### Just completed
- yazi FM scaffolding: dotfiles, Ansible role, manifest, windowrules → `markm1206/rabble-os`
- `RaBbLE-OS-Desktop-FileManagers.md` → `rabble-collective/rabble-grimoire`
- `log/SESSION-LOG.md` created in Grimoire, `INDEX.md` updated

### Open — do not implement until resolved
- **zellij vs tmux** — UNRESOLVED. Blocks Phase 1.3 (IDE panel / yazelix UX).

### Active work queue
1. **Aether GTK3/Kvantum theming** — Aether publishes `aether-gtk3.css` (synthwave skeleton,
   SCSS) + Kvantum SVG. Ansible installs from Aether instead of OS-local files.
   Per-app Aether layers needed: Firefox `userChrome.css`, audit Kitty/Waybar/Fuzzel/Mako
   for hardcoded hex values.
2. **xdg-desktop-portal-termfilechooser** — verify Fedora 43 availability (COPR:
   `emersion/xdg-desktop-portal-termfilechooser`), then uncomment stubbed Ansible tasks
   in `ansible/roles/apps/tasks/file_manager.yml`.

### Key files for theming session
```
# RaBbLE-Aether (read first — if you have access)
themes/gtk3/         ← what exists?
themes/kvantum/      ← what exists?

# RaBbLE-OS
ansible/roles/apps/tasks/qt-gtk-theme.yml
config/gtk-3.0/gtk.css                                                       ← 118-line Aether overlay
config/Kvantum/RaBbLE-Aether/RaBbLE-Aether.svg                              ← Arc-derived, replace
config/vscodium/extensions/RaBbLE-Aether-theme/themes/RaBbLE-Aether-color-theme.json  ← GOLD STANDARD

# RaBbLE-World (visual reference)
world/css/RaBbLE-theme.css    ← how Aether vars map to CSS properties
index.html                    ← Aether applied, live
world/RaBbLE-Boot.html        ← synthwave grammar reference (serve locally)
```

---

## Grimoire Navigation

```
common/RaBbLE-Palette.md                         ← ALL hex values
common/RaBbLE-Identity.md                        ← entity spec, ontology, character
common/RaBbLE-CommitStyle.md                     ← Pulse Protocol
common/RaBbLE-BranchStrategy.md                  ← branch topology
RaBbLE-OS/RaBbLE-OS-Architecture.md             ← OS layer model
RaBbLE-OS/RaBbLE-OS-Theming.md                  ← GTK/Kvantum component locations + reload commands
RaBbLE-OS/RaBbLE-OS-Desktop-FileManagers.md     ← yazi FM architecture (added this session)
RaBbLE-OS/RaBbLE-OS-KnownIssues.md             ← known bugs, portal package status
log/SESSION-LOG.md                               ← session history
```
