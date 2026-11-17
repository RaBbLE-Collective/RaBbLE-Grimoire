# RaBbLE-Captures Organization System

> Living system for organizing visual documentation across the Collective

**Version:** 1.3
**Last Updated:** 2026-06-25
**Steward:** Agents of the Collective
**Spell Integration:** `spells/visual-screenshot.sh`

> **Location updated S92:** Captures moved from `RaBbLE-BaBbLE/captures/` (standalone) → `RaBbLE-BaBbLE/captures/` (BaBbLE layer). All paths below reflect the new location.

---

## Overview

The captures layer (`~/RaBbLE-Collective/RaBbLE-BaBbLE/captures/`) is the visual intake layer within BaBbLE — the central archive for:
- **Page snapshots** — finished World pages, Grimoire interfaces, Aether/NeBuLA demos
- **UI states & effects** — entity rendering, liminal states, visual iterations
- **Component details** — Portal, Boot, Entity closeups
- **Development progress** — session work captured via Playwright or Hyprland

Every capture should be:
- **Placed** in a member/idea category directory
- **Named** descriptively with capture date
- **Discoverable** by visual idea, component, or session

---

## Quick Start: Capturing Screenshots

### For browser/web pages (recommended):

```bash
# Simple: capture localhost:8000 (World dev server)
bash RaBbLE-Grimoire/spells/visual-screenshot.sh --playwright

# Specific page
bash RaBbLE-Grimoire/spells/visual-screenshot.sh \
  --url http://localhost:8000/world/Chat.html \
  --playwright

# With custom output location
bash RaBbLE-Grimoire/spells/visual-screenshot.sh \
  --url http://localhost:8000 \
  --out RaBbLE-BaBbLE/captures/World/Pages/chat/world-chat-new-state_$(date +%Y%m%d).png \
  --playwright
```

**Playwright advantages:**
- No Hyprland required — works anywhere (CI, remote, other OS)
- Faster, more reliable for agent automation
- Headless — doesn't interrupt workflow
- Works out-of-the-box with `dev-serve.sh` running

### For OS/WM multi-window captures (Hyprland only):

```bash
# Full-screen capture with Firefox (RaBbLE-OS)
bash RaBbLE-Grimoire/spells/visual-screenshot.sh \
  --url http://localhost:8000 \
  --workspace 9

# With custom delay for slow renders
bash RaBbLE-Grimoire/spells/visual-screenshot.sh \
  --url http://localhost:8000/world/Boot.html \
  --delay 3 \
  --workspace 9
```

**Hyprland method:**
- Opens Firefox in workspace 9 (scratch)
- Captures monitor with `grim` after render delay
- Automatically closes Firefox and returns to original workspace
- Useful for full-page layouts, multi-app scenarios, OS UI work

### RaBbLE-OS keyboard shortcuts (Print/Super+S — S72, reverted+simplified S206):

The OS screenshot keybinds pipe the capture straight into `swappy` for
annotate/save/discard — no intermediate popup:

| Key | Action | Use for |
|-----|--------|---------|
| `Print` / `$mod+S` | full screen → swappy | Full desktop state captures |
| `Shift+Print` / `$mod+Shift+S` | region select → swappy | Targeted region captures |
| `Ctrl+Print` | region → clipboard only (no swappy, no file) | Quick copy |

In swappy: `Ctrl+S` saves to `~/Screenshots/` (default, set in
`config/swappy/config` `save_dir`), `Ctrl+C` copies to clipboard, `Escape`
discards without saving. The app auto-closes after save/copy (`early_exit`).

If a capture is destined for the Captures system (e.g. World UI iteration
work), move it into `RaBbLE-BaBbLE/captures/` manually via the popup's "Move
to other folder…" action or the `visual-screenshot.sh` spell below — it is no
longer the default landing spot. There is no standalone `RaBbLE-Captures/`
directory; captures live under RaBbLE-BaBbLE.

---

## Directory Structure

```
RaBbLE-BaBbLE/captures/
├── _inbox/                             # Raw spell output — triage within same session (target: <20 files)
├── World/                              # World app captures
│   ├── Pages/                          # Finished page screenshots
│   │   ├── landing/                    # Landing page iterations
│   │   ├── chat/                       # Chat interface states
│   │   ├── docs/                       # Documentation page
│   │   └── os/                         # OS/settings page
│   ├── States/                         # UI states & effects
│   │   └── liminal/                    # Liminal/atmospheric states
│   ├── Survey/                         # Full-page surveys & reviews
│   └── _reliquary/                     # Sealed release-cycle staging sets (rc1-progression, etc.)
├── Grimoire/                           # Grimoire backend/interface
├── NeBuLA/                             # Visual effects & canvas work
├── Entity-UI/                          # Entity component & boot states
│   ├── Boot/                           # Boot sequence states
│   ├── Components/                     # Component closeups & details
│   └── Portal/                         # Portal UI variations
├── Collective-Atmosphere/              # Ambient/atmospheric captures
├── Aether/                             # Aether CSS/design system captures
├── Boot/                               # OS boot sequence captures
│   ├── vm-sessions/                    # VM boot iteration sessions (vm-YYYYMMDD-HHMMSS/)
│   └── _reliquary/                     # Sealed S### boot debug sessions
├── OS-IDE/                             # Developer environment — OS theming + IDE
│   ├── Dolphin/                        # File manager captures
│   ├── Firefox/                        # Browser theme captures
│   ├── SDDM/                           # Login screen captures
│   ├── Terminal/                       # Shell/terminal captures
│   └── VSCodium/                       # Editor captures
│       └── Aether-iterations/          # Before/after Aether theme design work
└── Design-Iterations/                  # Cross-component design work
    ├── by-date/                        # Unnamed raw captures sorted by date (YYYYMMDD)
    ├── fastfetch/                      # fastfetch prompt design iterations
    └── login/                          # Login screen design mockups
```

### `_reliquary/` pattern

Each topic folder can have a `_reliquary/` subdirectory for **sealed iteration sets** — completed work that should stay browsable in captures for historical reference but no longer needs to be in an active folder.

Use `_reliquary/` when:
- A named S### session is complete (e.g., S169-boot-debug with 133 frames)
- A release-cycle staging dir is done (e.g., rc1-baseline → rc1-emergence → rc1-wip → shipped)
- A focused comparison investigation is complete (e.g., Particle-Unify local vs. prod)

Each `_reliquary/` subfolder gets a short `README.md`: what it contains, when it was sealed, and why.

This is **not** `BaBbLE/reliquary/` (the top-level cold storage zone) — reliquary subfolders stay within captures and remain easily discoverable by topic.

---

## Naming Convention

### Format
```
{member}-{component}-{state/idea}_{YYYYMMDD}.png
```

### Examples

**World Pages:**
- `world-landing-page_20260609.png` — Final landing page
- `world-chat-page_20260609.png` — Chat interface snapshot
- `world-chat-entity-fix_20260608.png` — Chat with entity UI fix
- `world-chat-after-message_20260608.png` — Chat state after sending message

**World States:**
- `world-liminal-desktop-state_20260609.png` — Desktop liminal effect
- `world-liminal-glitch-effect_20260609.png` — Glitch visual effect
- `world-liminal-mobile-state_20260609.png` — Mobile liminal state

**Entity UI:**
- `entity-boot-screen_20260608.png` — Boot sequence display
- `entity-full-state-variant1_20260609.png` — Full entity render (variant 1)
- `entity-component-closeup_20260608.png` — Entity component detail
- `entity-portal-top-variant1_20260609.png` — Portal top section

**NeBuLA:**
- `nebula-fieldcanvas-demo_20260608.png` — Field canvas rendering demo
- `nebula-demo-page_20260608.png` — NeBuLA demo page
- `nebula-survey-page_20260608.png` — Full-page NeBuLA survey

**Grimoire:**
- `grimoire-final-state_20260520.png` — Final Grimoire snapshot
- `grimoire-workspace9_20260520.png` — Workspace 9 iteration

**Design Iterations (from spell):**
- `design-iteration-20260609-01.png` — First iteration on 2026-06-09
- `design-iteration-20260609-02.png` — Second iteration same day
- Sequential numbering within each date

### Naming Rules

1. **Member first** — `world-`, `entity-`, `nebula-`, `grimoire-`, `aether-`
2. **Component/page** — `landing-`, `chat-`, `boot-`, `portal-`, `fieldcanvas-`
3. **State/idea** — `page`, `state`, `effect`, `fix`, `demo`, `closeup`
4. **Date always last** — `_YYYYMMDD.png`
5. **Variants** — Use `-variant1`, `-variant2` if multiple captures of same state
6. **Hyphen-separated** — Never underscores except before date
7. **Lowercase** — Consistent readability and shell safety

### Post-capture renaming:

The spell outputs `visual-YYYYMMDD-HHMMSS.png` by default. After capture, move and rename to match the category:

```bash
# After capturing with spell:
mv RaBbLE-BaBbLE/captures/visual-20260609-143022.png \
   RaBbLE-BaBbLE/captures/World/Pages/chat/world-chat-new-feature_20260609.png

# Or use the --out flag to name it immediately:
bash spells/visual-screenshot.sh \
  --url http://localhost:8000/world/Chat.html \
  --out RaBbLE-BaBbLE/captures/World/Pages/chat/world-chat-new-feature_$(date +%Y%m%d).png \
  --playwright
```

---

## Organization Rules for Agents

### When capturing a screenshot:

1. **Identify the visual idea** — What component/page/state is shown?
2. **Choose the category** — Which directory fits?
3. **Add to appropriate subdirectory** — Don't just add to root
4. **Name with description + date** — Use format above
5. **Update session log reference** — Note important captures in SESSION-LOG.md

### If unsure where to place:

- **It shows a finished page?** → `World/Pages/{page-name}/`
- **It shows a UI state or effect?** → `World/States/` or `Entity-UI/{category}/`
- **It shows dev/design work in progress?** → `Design-Iterations/by-date/`
- **It shows component detail/testing?** → `{Member}/` or `Entity-UI/Components/`
- **It's a full-page survey?** → `{Member}/Survey/` or root category
- **It shows NeBuLA rendering?** → `NeBuLA/`
- **It shows Grimoire interface?** → `Grimoire/`
- **It shows Aether design system?** → `Aether/` or relevant member
- **It shows ambient visual work?** → `Collective-Atmosphere/`
- **It shows OS login screen (SDDM)?** → `OS-IDE/SDDM/`
- **It shows file manager (Dolphin/Thunar)?** → `OS-IDE/Dolphin/`
- **It shows terminal/shell/fastfetch?** → `OS-IDE/Terminal/`
- **It shows browser (Firefox) theming?** → `OS-IDE/Firefox/`
- **It shows VSCodium/editor?** → `OS-IDE/VSCodium/`
- **It shows a VM boot sequence session?** → `Boot/vm-sessions/vm-YYYYMMDD-HHMMSS/`
- **It's a completed S### session archive?** → `Boot/_reliquary/S###-{topic}/`

### Design iterations guideline:

For rapid iteration work (code + visuals running side-by-side):
- Use `Design-Iterations/by-date/`
- Sequential numbering per date: `design-iteration-YYYYMMDD-NN.png`
- When iterations mature into finished work, move to appropriate member category
- Keep by-date directory for reference/history only

### Variants and iterations:

If capturing the same state multiple times (testing, fixes, different devices):
```
world-chat-entity-fix_20260608.png          # Original
world-chat-entity-fix-variant2_20260608.png # Second version same day
world-chat-entity-fix_20260610.png          # Updated version later
```

---

## Session Workflow

### Start of session:
```bash
ls -la RaBbLE-BaBbLE/captures/World/Pages/
# Quick visual reference of what's been captured
```

### During work:

**For browser pages (recommended):**
```bash
# Capture with spell, then rename
bash RaBbLE-Grimoire/spells/visual-screenshot.sh \
  --url http://localhost:8000/world/Chat.html \
  --out RaBbLE-BaBbLE/captures/World/Pages/chat/world-chat-feature-test_$(date +%Y%m%d).png \
  --playwright
```

**For full-screen/OS work (Hyprland):**
```bash
bash RaBbLE-Grimoire/spells/visual-screenshot.sh \
  --url http://localhost:8000 \
  --workspace 9
# Then move from ~/RaBbLE-Collective/RaBbLE-BaBbLE/captures/visual-* to proper category
```

### End of session:
- Review captures for important milestones
- **Triage `_inbox/`** — move everything to its topic folder before closing. Target: 0 files left.
  - `dolphin-*` / `fs-*` → `OS-IDE/Dolphin/`; `sddm-*` → `OS-IDE/SDDM/`; `shell-*` → `OS-IDE/Terminal/`
  - `visual-*` (unnamed spell output) → `Design-Iterations/by-date/`
  - VM boot sessions → `Boot/vm-sessions/vm-YYYYMMDD-HHMMSS/`
- **Seal completed sets** — if a session's capture folder is done, move it to the relevant `_reliquary/` with a README
- Rename to match convention
- Note any new captures in SESSION-LOG.md
- `_inbox/` should never accumulate more than ~20 files between triage passes

---

## Discovery & Use

### Find all captures from a date:
```bash
find RaBbLE-Captures -name "*20260609*" -type f | sort
```

### Find all chat interface captures:
```bash
find RaBbLE-BaBbLE/captures/World/Pages/chat -name "*.png" | sort
```

### Find all liminal effect variants:
```bash
find RaBbLE-BaBbLE/captures/World/States/liminal -name "*.png"
```

### Find design iteration history:
```bash
ls RaBbLE-BaBbLE/captures/Design-Iterations/by-date/design-iteration-20260609-* | sort
```

### Find Entity UI variants:
```bash
find RaBbLE-BaBbLE/captures/Entity-UI -name "*variant*"
```

---

## Spell Reference

**File:** `RaBbLE-Grimoire/spells/visual-screenshot.sh`

### Playwright method (recommended for agents/CI):

```bash
# Simple page capture
bash spells/visual-screenshot.sh --playwright

# With specific URL
bash spells/visual-screenshot.sh --url http://localhost:8000/world/Boot.html --playwright

# With custom output path
bash spells/visual-screenshot.sh \
  --url http://localhost:8000 \
  --out custom/path.png \
  --playwright

# With delay for slow renders
bash spells/visual-screenshot.sh --url http://localhost:8000 --delay 3 --playwright
```

**Requirements:** Node.js + `npx`, Playwright Chromium binary (auto-installed by npx)

**Advantages:** Works anywhere, no Hyprland required, fast, headless

### Hyprland method (full-screen, RaBbLE-OS only):

```bash
# Default workspace 9 (scratch)
bash spells/visual-screenshot.sh

# Custom workspace (default: 1)
bash spells/visual-screenshot.sh --workspace 5

# With delay
bash spells/visual-screenshot.sh --delay 3

# Custom URL
bash spells/visual-screenshot.sh --url file:///path/to/index.html
```

**Requirements:** Hyprland session, Firefox, `grim`, `hyprctl`, `jq` (optional)

**Output:** Captures active monitor, closes Firefox, returns to original workspace

### Output format:

```
SCREENSHOT: /home/rabble/RaBbLE-Collective/RaBbLE-BaBbLE/captures/visual-20260610-143022.png
```

Agents can parse the `SCREENSHOT: ` line to retrieve the path programmatically.

---

## Technical Notes

- **Format:** PNG only (lossless, good for UI)
- **Size:** Typically 100KB–3MB per file
- **Naming:** No spaces, special chars, or CamelCase
- **Dates:** Always YYYYMMDD (sortable by filename)
- **Git:** RaBbLE-Captures is .gitignored — captures are ephemeral; document important ones in Grimoire
- **Spell output:** Default path is `~/RaBbLE-Collective/RaBbLE-BaBbLE/captures/visual-TIMESTAMP.png`

---

## When Adding New Categories

If a new visual idea emerges:

1. **Name it clearly** — `{Member}-{Idea}` pattern
2. **Create directory** — Parallel to existing structure
3. **Document here** — Add to "Directory Structure" section
4. **Add examples** — Update naming convention with real names
5. **Update rules** — Add decision logic to "Organization Rules"

Example: If Entity-AI voice states emerge:
```bash
mkdir -p RaBbLE-BaBbLE/captures/Entity-UI/Voice
# Files: entity-voice-speaking_YYYYMMDD.png
# Update this doc with new category
```

---

## Quick Reference

| Need | Location | Pattern | Method |
|------|----------|---------|--------|
| Finished page | `World/Pages/{name}/` | `world-{page}-page_YYYYMMDD.png` | Playwright |
| UI state/effect | `World/States/` or `Entity-UI/` | `{member}-{component}-{state}_YYYYMMDD.png` | Playwright |
| Dev work | `Design-Iterations/by-date/` | `design-iteration-YYYYMMDD-NN.png` | Either |
| Component detail | `{Member}/Components/` | `{member}-component-{detail}_YYYYMMDD.png` | Playwright |
| Full survey | `{Member}/Survey/` | `{member}-survey-{focus}_YYYYMMDD.png` | Either |
| Full-screen OS work | Root → move to category | `{name}_YYYYMMDD.png` | Hyprland |
| SDDM login screen | `OS-IDE/SDDM/` | `sddm-{variant}-{state}_YYYYMMDD.png` | Hyprland |
| File manager | `OS-IDE/Dolphin/` | `dolphin-{state}_YYYYMMDD.png` | Hyprland |
| Terminal/fastfetch | `OS-IDE/Terminal/` | `shell-{state}_YYYYMMDD.png` | Hyprland |
| Firefox theming | `OS-IDE/Firefox/` | `ff-{component}-{state}_YYYYMMDD.png` | Hyprland |
| VSCodium/editor | `OS-IDE/VSCodium/` | `vscodium-{state}_YYYYMMDD.png` | Hyprland |
| VM boot session | `Boot/vm-sessions/vm-YYYYMMDD-HHMMSS/` | frame-NNNN.png | OS/script |
| Sealed session archive | `{Topic}/_reliquary/{name}/` | README.md + original files | — |
