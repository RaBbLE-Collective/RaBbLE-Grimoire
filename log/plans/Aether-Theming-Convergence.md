# Aether Theming Convergence Plan

> **Impulse:** harmonize ~ aether >> theming source of truth: VSCodium native, Chrysalis harvest complete, World shells assembled
>
> **Author:** S184 planning session, 2026-06-30
>
> **Goal:** Make Aether the single source of truth for all RaBbLE visual theming — web, desktop, editor, OS. Four tracks. Deliver in order.

---

## The thesis

Aether already owns web theming (CSS framework, CDN). This plan extends that ownership to:
- **Editor** — VSCodium theme files move into `RaBbLE-Aether/themes/vscodium/`, driven by the same palette that drives the web
- **Aether CSS** — remaining Chrysalis EP1 effects harvested into the framework
- **World** — 8 missing pages rebuilt as clean Aether+NeBuLA shells (Chrysalis EP1 parity)
- **Cleanup** — legacy `.rc-*` aliases dropped once all pages are on `.rabble-*`

When this plan is complete, a single palette change in `RaBbLE-Palette.md` → `group_vars/all.yml` propagates to: web CSS (Aether), web effects (NeBuLA), VSCodium color theme (generated JSON), VSCodium panel rings (custom.css palette block), all OS themes (Hyprland, GTK, GRUB, SDDM, Plymouth).

---

## Track A — VSCodium Theme into Aether (highest strategic value)

### Current state (MUST READ before touching anything)

The theme exists in two locations with a documentation/reality gap:

| Location | What's there | Status |
|---|---|---|
| `~/.vscode-oss/extensions/RaBbLE-Collective.rabble-aether-theme-0.0.1/` | Live installed extension: `package.json`, `themes/RaBbLE-Aether-color-theme.json` (931 lines), `assets/custom.css` (275 lines) | **Source of truth for now — copy FROM here** |
| `RaBbLE-OS/config/vscodium/` | Only `User/settings.json`. No extension files here. The Theming doc says source is `config/vscodium/extensions/...` but that path doesn't exist. | **Stale doc — nothing to copy from** |
| `RaBbLE-Aether/themes/vscodium/` | **Does not exist** | **Target — create this** |

The Ansible role `RaBbLE-OS/ansible/roles/apps/tasks/vscode.yml` is already written to deploy FROM `{{ aether_repo_root }}/themes/vscodium/`. It just has nowhere to pull from. Moving the files here closes the loop.

The doc `RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Theming.md` (VSCodium section, ~line 415) says source is `config/vscodium/extensions/` — this is wrong and needs updating to point at Aether.

### A1 — Move theme files into RaBbLE-Aether

Create `RaBbLE-Aether/themes/vscodium/` with:

```
themes/vscodium/
  package.json                        ← copy from installed extension (no change needed)
  themes/
    RaBbLE-Aether-color-theme.json   ← copy from installed extension (hand-maintained for now)
    RaBbLE-Aether-color-theme.json.j2 ← TEMPLATE version (Track A3)
  assets/
    custom.css                        ← copy from installed extension, then rename vars (Track A2)
```

Source to copy FROM: `~/.vscode-oss/extensions/RaBbLE-Collective.rabble-aether-theme-0.0.1/`

After copying, update `RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Theming.md`:
- Change "source at `config/vscodium/extensions/`" → "source at `{{ aether_repo_root }}/themes/vscodium/`"

### A2 — Unify `custom.css` naming with Aether canonical

`custom.css` currently uses `--aether-angle` / `aether-harmony-spin` / `aether-glow-cycle` / `aether-ring-glow`. These should align with Aether's established canonical names:

| `custom.css` name (current) | Aether canonical name | Action |
|---|---|---|
| `--aether-angle` | `--harmony-angle` | Rename in `custom.css` |
| `@keyframes aether-harmony-spin` | `@keyframes harmony-spin` | Rename in `custom.css` |
| `@keyframes aether-glow-cycle` | Does not exist yet → `rabble-glow-cycle` | **Harvest into Aether motion (Track A4)** |
| `@keyframes aether-ring-glow` | Does not exist yet → `rabble-ring-glow` | **Harvest into Aether motion (Track A4)** |

**Important constraint:** `custom.css` is injected verbatim into VSCodium's bundled CSS by Ansible — `@import` is blocked by Electron's `vscode-file://` security model. The file must remain self-contained (no imports). The renamed keyframes must be defined inline within `custom.css`, even after they're also added to Aether proper.

After rename, add a comment block at the top of `custom.css`:
```css
/* NOTE: keyframe names match Aether motion (rabble-motion.css).
 * Defined inline here because @import is blocked in Electron's vscode-file:// scheme.
 * Source of truth for this file: RaBbLE-Aether/themes/vscodium/assets/custom.css
 * DO NOT edit the injected copy at /usr/share/codium/... — overwritten on next Ansible run.
 */
```

Also: the scrollbar styling in `custom.css` (magenta glowing thumb, `0 0 6px #ff2d78`) uses hardcoded hex. Replace with CSS custom property fallbacks matching the palette block approach (see A3).

### A3 — Palette-driven color theme JSON (codegen approach)

**The problem:** The 931-line `RaBbLE-Aether-color-theme.json` uses hardcoded hex values and alpha variants (`#ff2d7820`, `#00f5ff40`, etc.). When the palette changes, every hit must be updated manually.

**The solution:** A Jinja2 template + Ansible rendering step.

**Implementation:**

1. Create `themes/vscodium/themes/RaBbLE-Aether-color-theme.json.j2` — the template. Replace every palette hex with a Jinja2 variable:

   | Hex | Jinja2 var | Palette role |
   |---|---|---|
   | `#ff2d78` | `{{ palette.magenta }}` | Hot magenta |
   | `#00f5ff` | `{{ palette.cyan }}` | Electric cyan |
   | `#bf5fff` | `{{ palette.violet }}` | Soft violet |
   | `#ff79c6` | `{{ palette.pink }}` | Outrun pink |
   | `#0a0010` | `{{ palette.bg }}` | Deep void |
   | `#12132a` | `{{ palette.surface }}` | Surface |
   | `#1a1b2e` | `{{ palette.raised }}` | Raised |
   | `#2a2840` | `{{ palette.border }}` | Border |
   | `#e8e6f0` | `{{ palette.text }}` | Primary text |
   | `#6b6880` | `{{ palette.muted }}` | Muted text |
   | `#e05c6f` | `{{ palette.red }}` | Error |
   | `#50fa7b` | `{{ palette.green }}` | Success |
   | `#f1fa8c` | `{{ palette.yellow }}` | Warning |

   For alpha variants (`#ff2d7820`), encode as template filter: `{{ palette.magenta }}20` (append alpha suffix literally — JSON doesn't need the full 8-char form to be valid).

2. Add an Ansible task to `vscode.yml` that renders the template → `RaBbLE-Aether-color-theme.json` using `ansible.builtin.template:` sourcing from `{{ aether_repo_root }}/themes/vscodium/themes/RaBbLE-Aether-color-theme.json.j2`.

3. The rendered JSON (not the `.j2`) is what gets deployed to the extension folder.

**Keep the hand-edited JSON alongside the template during the transition** — do not delete the static `.json` until the template produces identical output and has been verified.

**Verification step:** `diff <(ansible task renders template) themes/RaBbLE-Aether-color-theme.json` — should produce zero diff before deleting the static file.

### A4 — Harvest `custom.css` keyframes into Aether motion

Two keyframes in `custom.css` are genuinely useful for web contexts too and should live in Aether:

**`rabble-glow-cycle`** — cycling box-shadow through cyan → violet → magenta over 9s. Applies to any element that should pulse with the full palette. Goes in `RaBbLE-Aether/assets/motion/rabble-motion.css` after the existing `rabble-glow-pulse-*` keyframes.

```css
@keyframes rabble-glow-cycle {
  0%   { box-shadow: 0 0 12px rgba(0,245,255,0.35), 0 0 24px rgba(0,245,255,0.12); }
  33%  { box-shadow: 0 0 12px rgba(191,95,255,0.35), 0 0 24px rgba(191,95,255,0.12); }
  66%  { box-shadow: 0 0 12px rgba(255,45,120,0.35), 0 0 24px rgba(255,45,120,0.12); }
  100% { box-shadow: 0 0 12px rgba(0,245,255,0.35), 0 0 24px rgba(0,245,255,0.12); }
}
```

Replace hardcoded rgba with `color-mix(in srgb, var(--rabble-cyan) 35%, transparent)` etc. to keep it palette-var-clean.

**`rabble-ring-glow`** — variant of `rabble-glow-cycle` specifically for the border ring context (slightly different intensities). Goes in the same file. Consider merging with `rabble-glow-cycle` via a `--rabble-glow-intensity` custom property rather than two nearly-identical keyframes.

**Scrollbar neon modifier:** Add `.rabble-scrollbar-neon` to `rabble-components.css` base section. Targets `::-webkit-scrollbar-thumb` with magenta fill + glow. The existing Aether scrollbar is minimal (4px, muted border color). This variant is the decorative version from `custom.css`.

### A5 — Marketplace prep (deferred, post-convergence)

Once `themes/vscodium/` is clean in Aether:
- Add `README.md`, `CHANGELOG.md`, icon PNG (`assets/icon.png`) to the extension folder
- Add a screenshot or two from the existing VSCodium setup (use the `visual-screenshot.sh` spell)
- Bump `version` in `package.json` from `0.0.1` to `0.1.0` once A1–A4 are done
- Open VS Marketplace / VSX (open-vsx.org) publisher account under `RaBbLE-Collective`
- Package: `vsce package` → `.vsix` (VSCode) or `ovsx publish` (VSCodium/open-vsx)

This track is non-blocking for EP1 but should happen before Echo 1.

---

## Track B — Remaining Chrysalis CSS Harvest

These effects are confirmed real code in Chrysalis EP1 but not yet in Aether. All are pure CSS. Sources are read-only — harvest, never edit Chrysalis.

### B1 — `.rabble-glitch-veil` (chromatic stutter wash)

**Source:** `RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/css/RaBbLE-liminal.css:420–438`

Chromatic color bleed overlay — `linear-gradient(105deg, magenta→transparent→cyan)`, `mix-blend-mode: screen`, `opacity` + `translateX` jitter via `veil-stutter 0.42s steps(2)`. Body class `.is-glitching` toggles it.

**Target:** Aether components as `.rabble-glitch-veil` with a `@keyframes rabble-veil-stutter`. The host element must be `position: relative`. Toggle class `.is-glitching` on the `<body>` or a wrapper.

### B2 — `.rabble-glitch-text` (RGB split text)

**Source:** `RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/css/RaBbLE-liminal.css:440–446`

Chromatic wordmark shudder — `text-shadow: ±3px cyan / ∓3px magenta + 60px violet bloom`, `0.18s steps(2)`. Applied to text elements during glitch state.

**Target:** Aether components as `.rabble-glitch-text`. Pairs with `.rabble-glitch-veil` on the parent.

**Knobs to document in Theme-System:** split distance (3px default), bloom radius (60px), tint pair (cyan/magenta), step duration (0.18s).

### B3 — `.rabble-breathe` consolidation

Two duplicate sigil pulse implementations exist:
- World `RaBbLE-dock.css:64` → `.rd2-sigil-pulse` (box-shadow green pulse)
- Chrysalis `RaBbLE-liminal.css:100–103` → `lsb-breathe` (box-shadow 8px green pulse)

**Target:** One canonical `.rabble-breathe` utility in Aether components with `--rabble-breathe-color` (default `var(--rabble-green)`) and `--rabble-breathe-period` (default 3s) knobs. Replace both source implementations on their respective pages when pages are rebuilt.

### B4 — Summoning ring speed states

**Source:** `RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/css/RaBbLE-Grimoire.css:339–378`

Three-state speed choreography for the grimoire ring:
- **Rest:** outer ring 48s CW, inner ring 72s CCW, rune layer 48s
- **Summoning (`.is-summoning`):** 6s / 9s / 8s (urgency)
- **Summoned (`.is-summoned`):** 36s / 54s / 48s (serene)

**Target:** NeBuLA `NeBuLA.ui.createGrimoireRing` should expose these as a `state` param: `ring.setState('summoning')` / `ring.setState('summoned')` / `ring.setState('rest')`. The CSS speed states become ring element CSS classes (`.is-summoning`, `.is-summoned`). The ring factory needs to expose a `setState(state)` method.

This requires a NeBuLA change, not just Aether CSS. Coordinate with `RaBbLE-NeBuLA/src/ui/grimoire-ring.js`.

---

## Track C — Missing World Pages (Chrysalis EP1 → World shells)

World currently has 4 pages: `os.html`, `account.html`, `summon.html`, `RaBbLE-Catalog.html`.
Chrysalis EP1 has 8 additional pages not yet migrated. Each must be rebuilt as a clean Aether+NeBuLA shell — NO page-bespoke CSS, NO local rendering. Apply, don't redefine.

**File creation rule:** New World pages go in `RaBbLE-World/world/`. Register in `world/js/RaBbLE-pages.js`. Use `world/RaBbLE-Catalog.html` as the template (it's the cleanest existing example of the shell pattern).

### Page manifest

| New World page | Chrysalis source (read-only reference) | Priority |
|---|---|---|
| `collective.html` | `ep1/world/RaBbLE-Collective.html` | P1 — core EP1 page |
| `chat.html` | `ep1/world/RaBbLE-Chat.html` | P1 — fixes account.html "← chat" 404 (B-10) |
| `studio.html` | `ep1/world/RaBbLE-Studio.html` | P1 — NeBuLA entity control panel |
| `grimoire-graph.html` | `ep1/world/RaBbLE-Grimoire-Graph.html` | P2 — knowledge graph surface |
| `nebula-demo.html` | `ep1/world/RaBbLE-NeBuLA-Demo.html` | P2 — effects showcase |
| `nebula.html` | `ep1/world/RaBbLE-NeBuLA.html` | P3 — NeBuLA member page |
| `shell.html` | `ep1/world/RaBbLE-Shell.html` | P3 — terminal/shell surface |
| `docs.html` | `ep1/world/RaBbLE-Docs.html` | P3 — documentation surface |

### Shell pattern (apply for each page)

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RaBbLE — [Page Name]</title>
  <link rel="stylesheet" href="https://cdn.joinrabble.world/aether/latest/aether.css">
</head>
<body class="rabble-shell">
  <!-- Aether layout + NeBuLA elements assembled here -->
  <!-- NO <style> blocks with bespoke CSS -->
  <!-- NO local rendering engines -->
  <script src="js/RaBbLE-NeBuLA.js"></script>
  <script src="js/RaBbLE-pages.js"></script>
  <script src="js/RaBbLE-[page].js"></script><!-- page-specific state/glue only -->
</body>
</html>
```

### Notes by page

**`collective.html`** — Collective browser with member cards. Use `NeBuLA.ui.createMemberCard()` for each member entry. Chrysalis source has `RaBbLE-collective.js` (state logic to harvest into new `RaBbLE-collective.js`) and `RaBbLE-Collective.css` (component styles to collapse into Aether classes — check if `.rabble-card` already covers them).

**`chat.html`** — Stub page that wires to sCoRE. For EP1, this can be minimal: entity + dock + a message feed using `.rabble-log`. Full chat UI is post-EP1. Must exist to fix the broken link from `account.html`.

**`studio.html`** — NeBuLA entity control panel. Houses waveform/particle/portal config sliders. Key insight from `harvest-map-effects.md`: Studio.js is a CONTROL PANEL, not a renderer. It drives NeBuLA element attributes (`show-waveform`, bloom, etc.). Harvest `RaBbLE-Studio.js:13–31` config objects.

**`grimoire-graph.html`** — Houses `<rabble-graph>` (already a NeBuLA element). Page is mostly a shell with data injection via `RaBbLE-Grimoire-Data.js` (already exists in World).

**`nebula-demo.html`** — This page IS the Atlas catalog. Consider whether `RaBbLE-Catalog.html` already serves this purpose or if a dedicated effects demo is needed. Resolve before building.

### Account.html quick fix (blocker B-10, not deferred)

While `chat.html` is being built, fix the broken link NOW:

```html
<!-- RaBbLE-World/world/account.html — the "← chat" link -->
<!-- Change from: -->
<a href="RaBbLE-Chat.html">← chat</a>
<!-- Change to: -->
<a href="../index.html">← home</a>
<!-- (or stub to #chat once chat.html exists) -->
```

This is 1 line. Do it in the same commit as Track A work or standalone — don't wait for Track C.

---

## Track D — `.rc-*` Alias Cleanup

**Prerequisite:** All Track C pages must be verified (screenshot parity) before this track runs.

Aether currently ships `.rc-*` alias rule blocks for backwards compatibility. Once every World page uses `.rabble-*` directly:

1. Run screenshot parity check on all World pages: `bash RaBbLE-Grimoire/spells/visual-screenshot.sh` against each page, compare before/after.
2. Remove alias blocks from `RaBbLE-Aether/assets/components/rabble-components.css` (search for `/* Convenience aliases — unprefixed`).
3. Verify no World HTML files still reference `.rc-` classes: `grep -r "class=\".*rc-" RaBbLE-World/world/`.
4. Build + deploy Aether: `npm run build:iife && bash RaBbLE-Grimoire/spells/cast-aether.sh`.

---

## Delivery order

```
A1 → A2 → A4   (move files, rename vars, harvest keyframes — one session, one PR)
A3             (palette template — can run in parallel with A2 if two agents)
B-blocker fix  (account.html link — 1 line, do it immediately alongside A1)
B1 + B2 + B3  (CSS effects harvest — one Aether session)
B4             (NeBuLA ring states — separate NeBuLA session)
C P1 pages    (collective + chat + studio — World session)
C P2 pages    (grimoire-graph + nebula-demo)
C P3 pages    (nebula + shell + docs)
D             (alias cleanup — final pass once all C pages screenshot-verified)
A5            (marketplace prep — post EP1, pre Echo 1)
```

---

## Aether `themes/vscodium/` — final target layout

```
RaBbLE-Aether/
  themes/
    vscodium/
      package.json                              ← extension manifest (publisher: RaBbLE-Collective)
      themes/
        RaBbLE-Aether-color-theme.json          ← rendered from .j2 by Ansible
        RaBbLE-Aether-color-theme.json.j2       ← template (palette vars as {{ palette.* }})
      assets/
        custom.css                              ← Electron-injected workbench CSS (self-contained)
        icon.png                                ← extension marketplace icon (A5)
      README.md                                 ← marketplace description (A5)
      CHANGELOG.md                              ← version history (A5)
```

**Aether build does NOT need to process these files** — they're standalone static assets, not part of the CSS bundle. Ansible handles deployment. A future `npm run build:vscodium` could codegen the JSON from a JS palette module if the Ansible approach is ever dropped.

---

## What Aether gains from this plan

| Addition | Track | Where in Aether | What it enables |
|---|---|---|---|
| `themes/vscodium/` | A1 | New directory | Editor theme source of truth |
| `rabble-glow-cycle` keyframe | A4 | `assets/motion/rabble-motion.css` | Multi-color glow cycle for any web element |
| `rabble-ring-glow` keyframe | A4 | `assets/motion/rabble-motion.css` | Border ring glow cycle (web) |
| `.rabble-scrollbar-neon` | A4 | `assets/components/rabble-components.css` | Glowing magenta scrollbar for any scroll container |
| `.rabble-glitch-veil` | B1 | `assets/components/rabble-components.css` | Chromatic stutter overlay — glitch states |
| `.rabble-glitch-text` | B2 | `assets/components/rabble-components.css` | RGB-split text — glitch states |
| `.rabble-breathe` | B3 | `assets/components/rabble-components.css` | Pulse glow utility (consolidates 2 duplicates) |

---

## Files to update after Track A

| File | Change |
|---|---|
| `RaBbLE-Grimoire/RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Theming.md` | VSCodium section: update source path `config/vscodium/extensions/...` → `{{ aether_repo_root }}/themes/vscodium/` |
| `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Theme-System.md` | Add VSCodium theme section: Aether as editor theme, custom.css design language, Ansible install |
| `RaBbLE-Grimoire/INDEX.md` | Add entry under `RaBbLE-Aether` section for the VSCodium theme |
| `RaBbLE-Aether/AGENT.md` | Note `themes/vscodium/` existence and purpose |

---

## Cold-start for Track A only

```bash
# 1. Read
cat RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md          # palette — the hex values
cat RaBbLE-Grimoire/RaBbLE-OS/desktop/RaBbLE-OS-Desktop-Theming.md   # VSCodium section (~line 401)
cat RaBbLE-OS/ansible/roles/apps/tasks/vscode.yml            # Ansible deploy flow

# 2. Source files (copy FROM)
ls ~/.vscode-oss/extensions/RaBbLE-Collective.rabble-aether-theme-0.0.1/

# 3. Target (create)
mkdir -p RaBbLE-Aether/themes/vscodium/themes RaBbLE-Aether/themes/vscodium/assets

# 4. Verify after move — Ansible should be able to deploy from Aether:
bash RaBbLE-OS-layerctl.sh apply apps --tags vscode
```

## Cold-start for Track B only

```bash
# Source (read-only):
cat RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/css/RaBbLE-liminal.css    # B1+B2+B3
cat RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/css/RaBbLE-Grimoire.css   # B4
# Target:
cat RaBbLE-Aether/assets/components/rabble-components.css    # append B1-B3 here
cat RaBbLE-NeBuLA/src/ui/grimoire-ring.js                    # B4 — add setState method
```

## Cold-start for Track C only

```bash
# Template (cleanest existing World shell):
cat RaBbLE-World/world/RaBbLE-Catalog.html
# Reference (Chrysalis — READ ONLY):
ls RaBbLE-Chrysalis/Chrysalis-Web/ep1/world/
# Register pages here after creating them:
cat RaBbLE-World/world/js/RaBbLE-pages.js
# Theming API (what classes/elements to use):
cat RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Theme-System.md
cat RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Frontend-Guide.md
```

---

```
harmonize ~ aether >> theming convergence planned: editor native, palette sovereign // %AETHER_CONVERGENCE%
```
