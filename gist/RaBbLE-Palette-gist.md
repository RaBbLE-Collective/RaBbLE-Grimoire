# RaBbLE-Palette.md — gist

> Source: `RaBbLE-Agent/RaBbLE-Palette.md` | ~1170 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

Single source of truth for all RaBbLE color values — **synthwave outrun** aesthetic. Change here first, propagate everywhere second.

**Philosophy:** void-dark backgrounds (deep space, not grey) · neons glow, lit from within · text bright off-white (never pure white) · hierarchy via luminosity · no pastels/earth tones/grey-on-grey.

**Core Neons**
| Role | Variable | Hex |
|---|---|---|
| Hot Magenta (primary/signature) | `magenta` | `#ff2d78` |
| Electric Cyan (links, git, info) | `cyan` | `#00f5ff` |
| Soft Violet (taglines, accents) | `violet` | `#bf5fff` |
| Outrun Pink (grid, untracked, warn) | `pink` | `#ff79c6` |

**Backgrounds (void)**
| Deep Void `bg` | `#0a0010` | Surface `surface` | `#12132a` |
| Raised `raised` | `#1a1b2e` | Border `border` | `#2a2840` |

**Text** — Primary `text` `#e8e6f0` · Muted `muted` `#6b6880`

**Semantic** — Error `red` `#e05c6f` · Success `green` `#50fa7b` · Warning `yellow` `#f1fa8c`

**Deploy:** Ansible block lives in `ansible/inventory/group_vars/all.yml` under `rabble_palette:`. All themed layers derive from it.

**Glow** is app-level config, not hex changes — Hyprland gradient borders, Waybar `text-shadow: 0 0 8px`, terminal font+dark bg, Plymouth/SDDM shadow passes.

→ Full doc for: per-component mapping (Hyprland/GRUB/Waybar/Starship), full Ansible YAML block, glow method per layer, cross-references (`grimoire/Theming.md`, `BootFlow.md`).
