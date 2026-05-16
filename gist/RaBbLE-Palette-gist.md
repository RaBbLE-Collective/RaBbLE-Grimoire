# RaBbLE-Palette — gist

> Source: `common/RaBbLE-Palette.md` | ~1,170 → ~150 tokens
> Regenerate: `bash spells/distill-gists.sh`

**Never invent hex values. Use only these:**

**Neons**
```
#ff2d78  magenta   primary neon — borders, active states
#00f5ff  cyan      secondary — links, info
#bf5fff  violet    tertiary — taglines, accents
#ff79c6  pink      grid, warnings, soft highlights
```

**Backgrounds**
```
#0a0010  bg        primary background
#12132a  surface   panels, sidebars
#1a1b2e  raised    cards, inputs, popups
#2a2840  border    inactive borders, dividers
```

**Text**
```
#e8e6f0  text      primary readable text
#6b6880  muted     secondary, dimmed, comments
```

**Semantic**
```
#e05c6f  red       error, urgent, destructive
#50fa7b  green     success, clean, ok
#f1fa8c  yellow    warning, staged, caution
```

**CSS variables:** `--rabble-{name}` (e.g., `--rabble-magenta`, `--rabble-bg`).

**Rule:** Change values in `common/RaBbLE-Palette.md` first, propagate second. Glow effects via shadow/blur at application layer — not by changing hex.

→ Full doc for: CSS variable declarations, usage examples, Aether integration
