# RaBbLE-Palette — gist

> Source: `RaBbLE-Agent/RaBbLE-Palette.md` | ~1170 → ~420 tokens
> Regenerate: `bash spells/distill-gists.sh`

The canonical synthwave outrun palette. It is the single source of truth for every RaBbLE color, so change it here first and propagate after.

**Philosophy:** Void-dark backgrounds (never grey). Saturated neons that glow. Off-white text, never pure white. Hierarchy comes from luminosity. No pastels, earth tones or grey-on-grey.

**Colors** (Ansible `rabble_palette.<key>`, variable `rabble_color_<key>`)

| Key | Hex | Role |
|---|---|---|
| magenta | `#ff2d78` | Primary signature: borders, active elements, prompt |
| cyan | `#00f5ff` | Secondary: links, git clean, info |
| violet | `#bf5fff` | Tertiary: taglines, decoration |
| pink | `#ff79c6` | Grid/horizon, untracked files, soft warnings |
| bg | `#0a0010` | Deep void, primary background |
| surface | `#12132a` | Panels, sidebars |
| raised | `#1a1b2e` | Inputs, cards, popups |
| border | `#2a2840` | Inactive borders, dividers |
| text | `#e8e6f0` | Primary text |
| muted | `#6b6880` | Secondary text, comments |
| red | `#e05c6f` | Errors, urgent |
| green | `#50fa7b` | Success |
| yellow | `#f1fa8c` | Warning, staged |

**Deployment:** The Ansible block is in `ansible/inventory/group_vars/all.yml`.

**Glow:** Glow comes from application config, not hex changes. Examples:
- Hyprland active border is a gradient `#ff2d78 → #bf5fff`.
- Waybar uses `text-shadow: 0 0 8px #ff2d78`.

→ Full doc for: per-layer glow methods (GRUB, Plymouth, SDDM, Starship), full component mapping per color, the complete Ansible YAML block, cross-reference doc paths
