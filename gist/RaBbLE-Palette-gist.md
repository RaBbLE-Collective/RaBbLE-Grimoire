# RaBbLE-Palette.md — gist

> Source: `RaBbLE-Agent/RaBbLE-Palette.md` | ~1170 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

The single source of truth for all RaBbLE color values — a **synthwave outrun** palette. Change here first, propagate everywhere second.

**Philosophy:** void-dark backgrounds (deep space, not grey), neons glow/lit-from-within, text bright off-white (never pure white), hierarchy via luminosity. No pastels, earth tones, or grey-on-grey.

**Core Neons**

| Role | Var | Hex |
|---|---|---|
| Hot Magenta | `magenta` | `#ff2d78` |
| Electric Cyan | `cyan` | `#00f5ff` |
| Soft Violet | `violet` | `#bf5fff` |
| Outrun Pink | `pink` | `#ff79c6` |

**Backgrounds (Void)** — `bg #0a0010` · `surface #12132a` · `raised #1a1b2e` · `border #2a2840`

**Text** — `text #e8e6f0` · `muted #6b6880`

**Semantic** — `red #e05c6f` (error) · `green #50fa7b` (success) · `yellow #f1fa8c` (warning)

- **Magenta** = signature: borders, active elements, prompt, Hyprland active border, GRUB, Starship.
- **Glow** is config-level, not a hex change — e.g. Hyprland gradient `#ff2d78 → #bf5fff`, Waybar `text-shadow: 0 0 8px #ff2d78`.
- Deployment source: Ansible `rabble_palette` block in `ansible/inventory/group_vars/all.yml`.

→ Full doc for: per-layer glow methods (SDDM, Plymouth, GRUB), full component→variable mapping, the complete Ansible YAML block, and cross-reference theming docs.
