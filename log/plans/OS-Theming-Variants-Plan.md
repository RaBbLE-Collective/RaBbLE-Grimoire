# OS Theming Variants & Profiles Plan

> **Impulse:** spark ~ theming >> one token source, many moods: variants, profiles, contrast QA
>
> **Authored:** S204, 2026-07-15 (investigation + design; nothing implemented yet)
>
> **Brief from Mark:** (1) make theming modular and easier to configure; (2) fix oddities like
> light-grey-on-white dropdowns in Firefox; (3) support a light/white mode; (4) support a mode
> with fewer cyan/magenta flowing accents and a way to turn accents down; (5) sane, less
> visually overwhelming defaults.
>
> **Relationship to `Aether-Theming-Convergence.md` (S184):** that plan makes the single palette
> propagate everywhere. This plan generalizes it: palette **× variant × profile** propagate
> everywhere. Convergence Tracks A1–A3 get absorbed into Phase 2 here (convert surfaces straight
> to tokens once, not to hardcoded-hex first). One revision to A3 is called out below.

---

## Part 1 — Investigation findings (S204 audit)

### 1.1 What exists

- **~1,800 hardcoded hex occurrences** across `RaBbLE-OS/config/` (excluding wallpapers).
  Every surface is hand-authored against the 13-hex palette. No generator exists — the
  "Aether as Theme Generator" role promised in `RaBbLE-OS-Desktop-Theming.md` ("Planned role:
  not yet created") never landed.
- **Good news: discipline held.** The 13 canonical hexes account for ~97% of occurrences in
  app configs. Only ~16 stray occurrences exist (see 1.3).
- **The one real pipeline is the model:** `RaBbLE-Aether/themes/_palette/recolor.sh` +
  `aether-kvantum.map` — deterministic hex→hex re-skin of upstream Catppuccin Kvantum with a
  QA gate (every hex must be ⊂ the 13 palette hexes). This pattern generalizes to variants.
- **Deployment is two-channel:** dotctl bundles (20 bundles, verbatim copy `config/` →
  `~/.config/`) + Ansible roles (`qt-gtk-theme.yml`, `vscode.yml`, `browsers.yml`) for
  surfaces needing sudo or non-`~/.config` targets. S201 already established the rule:
  **one source of truth per file** (the stale Aether kvantum copy that clobbered dotctl for
  ~80 sessions).

### 1.2 Palette sources disagree (three-way drift)

| Source | Status |
|---|---|
| `RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md` | Canon — 13 hexes |
| `RaBbLE-OS/ansible/inventory/group_vars/all.yml` | **Stale.** Flat `rabble_color_*` vars from a pre-canon era: text `#e8d5ff`, muted `#8860aa`, surface `#120025`, pink `#f7a8d4` — none of these are canon. The `rabble_palette:` dict the Palette doc claims lives here **does not exist**. |
| `RaBbLE-OS/config/*` | Mostly canon, but `look.conf` still uses `#8860aa`/`#120025` for inactive borders (visible daily), and a handful of leaked Catppuccin hexes survive (`#cdd6f4`, `#cba6f7`, `#89b4fa`, `#6c7086`, `#f38ba8`). |

### 1.3 Off-palette strays in `config/` (Phase 0 purge list)

`#120025` (×6), `#8860aa` (×5), `#f8f4ff` (×6), `#9e9ab8` (×3), `#3d3860` (×2), `#f7a8d4`,
`#e8d5ff`, `#f53c3c`, `#f38ba8`, `#cdd6f4`, `#cba6f7`, `#c4c0d8`, `#89b4fa`, `#6c7086`,
`#2a0050`, `#1a0030`. (Firefox userChrome strays `#3d3860`/`#9e9ab8`/`#c4c0d8` already have
replacement recommendations in Convergence A2.)

### 1.4 Firefox dropdown bug — root cause identified

`config/firefox/user.js:12` sets `ui.systemUsesDarkTheme=1` and `:15` sets
`browser.theme.content-theme=0` (force dark content). Consequence: Firefox renders form
widgets (its own non-native widget theme — **not** GTK; the Aether GTK3 menu styling is fine)
with dark-theme colors on **every** site. On a light-themed site that styles
`select { background: white }` but not the option foreground (or vice versa), the widget mixes
forced-dark text (light grey) with author-supplied white — the unreadable dropdown Mark sees.
This is a **forced-scheme mismatch class of bug**, not a one-off: any partially-styled form
control on a light site can hit it. Fix in Phase 0; a permanent guard (contrast QA on declared
pairs) lands in Phase 1.

### 1.5 Where the "flowing accents" actually live

| Surface | Effect | File |
|---|---|---|
| Hyprland | magenta→cyan animated gradient on active border | `config/hypr/conf.d/look.conf:19` |
| Waybar | pulse/flash/blink keyframes (mostly semantic: urgent, agent status) | `config/waybar/style.css` |
| VSCodium | conic-gradient rings, flowing tab ribbon, glow cycle (the "gold standard") | Aether `themes/vscodium/assets/custom.css` |
| swayOSD | rotating gradient stops, color-cycling text | `config/swayosd/style.css` |
| Firefox chrome | conic rings + glow cycle | Aether `themes/firefox/userChrome.css` |
| Kitty/fuzzel/mako | static neon, no motion | — |

So "turn the flow down" touches ~5 files — tractable as a template knob.

---

## Part 2 — Design

### 2.0 Shape of the system

```
Grimoire RaBbLE-Agent/palette/           ← DATA CANON (new)
  aether-void.yml        dark synthwave (current 13 hexes, verbatim)
  aether-dawn.yml        light mode (hexes PROPOSED below, Mark approves)
  profiles/
    surge.yml            full synthwave: flowing motion, glow on, all four neons
    drift.yml            calm: static gradients, glow off, magenta+violet only  ← DEFAULT
RaBbLE-OS/theme/templates/**             ← TEMPLATES: token-bearing files ONLY
RaBbLE-Aether/themes/**/*.tpl            ← templates for Aether-published artifacts

spells/theme-render.sh                   ← render (variant × profile) → committed outputs
spells/theme-verify.sh                   ← QA gate: hex-subset + contrast + no hand-edit drift
RaBbLE-OS-themectl.sh                    ← switch: render + deploy + reload hooks
```

Only files that actually carry colors or knob-controlled values become templates; the rest of
`config/` stays plain dotctl-deployed files (no parallel tree of untemplated copies). A third
profile (`still` — mono accent, motion fully off) was considered and is **deferred until asked
for**: Mark's ask is covered by `drift`, and every extra profile multiplies the QA surface.

**Render → commit → deploy verbatim (for the committed default).** Rendered files land in
their current homes (`RaBbLE-OS/config/`, `RaBbLE-Aether/themes/`) with a `GENERATED` header,
and are committed. dotctl and Ansible keep working unchanged, `dotctl status/diff` stays
meaningful, and there is exactly one deploy source per file (S201 lesson). This **revises
Convergence A3's recommendation** (Ansible renders `.j2` at deploy time): deploy-time
rendering creates live state that no repo file matches, which is the drift pattern we just
spent seven sessions killing. Render at build time instead; Ansible copies the rendered
artifact. Renders are **atomic**: render to a temp tree → verify → swap; a verify failure
never leaves `config/` half-mutated.

**Why the data canon lives in Grimoire:** the standing rule is already "Colors:
`RaBbLE-Palette.md` only." Machine-readable YAML next to it makes Grimoire the single palette
authority for humans *and* renderers; Aether and OS both read
`../RaBbLE-Grimoire/RaBbLE-Agent/palette/`. `RaBbLE-Palette.md` stays the human narrative and
gains a Variants section; `theme-verify` cross-checks doc tables against YAML so they can't
drift. Trade-off acknowledged: this makes OS/Aether *builds* read from the Grimoire working
tree (previously knowledge-only). Repos stay independent — the renderer fails soft with
"clone the Grimoire beside this repo," same co-location the Collective already requires.
(Alternative home if Mark prefers build-inputs out of Grimoire: `RaBbLE-Aether/themes/_palette/`
— see open question 5.)

### 2.1 Token schema (variant YAML)

The 13 palette hexes stay, but templates never reference raw colors — they reference
**semantic tokens**, so a light variant is data, not a rewrite:

```yaml
# aether-void.yml
name: aether-void
scheme: dark                      # drives gsettings prefer-dark, kdeglobals scheme,
                                  # Firefox ui.systemUsesDarkTheme, GTK/Qt light-dark selects
palette:                          # the 13 canon roles (hex, verbatim from RaBbLE-Palette.md)
  magenta: "#ff2d78"
  cyan:    "#00f5ff"
  violet:  "#bf5fff"
  pink:    "#ff79c6"
  bg:      "#0a0010"
  surface: "#12132a"
  raised:  "#1a1b2e"
  border:  "#2a2840"
  text:    "#e8e6f0"
  muted:   "#6b6880"
  red:     "#e05c6f"
  green:   "#50fa7b"
  yellow:  "#f1fa8c"
derived:                          # alpha/mix values templates may use (no new hues)
  magenta_dim: "#ff2d7820"
  focus_ring:  "#00f5ff40"
  border_soft: "#2a284066"
contrast_pairs:                   # theme-verify enforces these (WCAG ratio minimums)
  - [text, bg, 7.0]
  - [text, surface, 7.0]
  - [text, raised, 4.5]
  - [muted, bg, 3.0]              # muted is secondary/UI text — AA-secondary target.
  - [muted, surface, 3.0]         # (canon muted-on-void is 3.84:1; a 4.5 gate would fail
                                  #  the CURRENT palette — verified S204 Opus review)
```

### 2.2 Profile schema (the knobs)

Profiles are orthogonal to variants — any profile applies to any variant:

```yaml
# profiles/drift.yml — the new DEFAULT
name: drift
motion: slow        # flowing | slow | off
glow: off           # on | off
accent: calm        # full | calm | mono  (mono + its accent_color knob: DEFERRED, see 2.0)
```

What each knob renders to:

| Knob | `flowing` / `full` / `on` | `slow` / `calm` | `off` / `mono` |
|---|---|---|---|
| **motion** | animated conic rings (VSCodium, Firefox chrome), rotating swayOSD stops, animated Hyprland border angle | static gradients; keyframe durations ×3 where kept | no decorative keyframes at all; **semantic alerts keep blinking** (battery-critical, urgent) in every profile |
| **glow** | neon box-shadow blooms, drop shadows in accent colors | — | shadows neutral/none |
| **accent** | all four neons distributed across surfaces | magenta primary + violet secondary; cyan reserved for focus rings and links only; pink dropped | one accent + neutrals; everything else text/muted/border |

Defaults answer the "sane defaults" ask: **`aether-void` × `drift`** ships as the committed
default. Full synthwave is one command away (`themectl set void surge`), not deleted.

### 2.3 Renderer + verify

- `theme-render.sh <variant> [profile]` — python3 + Jinja2 (both already hard deps via
  Ansible). Renders `theme/templates/**` and Aether `*.tpl` into a temp tree, verifies, then
  swaps into the committed homes (atomic). Every output gets a header:
  `# GENERATED by theme-render.sh from theme/templates/... — edit the TEMPLATE, not this file`
- `theme-verify.sh` — three gates, run by pre-commit and by CI-of-the-future:
  1. **Hex subset:** every hex in rendered output ∈ active variant palette (+ alpha variants).
     Same gate Kvantum already has, applied to everything.
  2. **Contrast:** every declared `contrast_pairs` entry meets its ratio. WCAG relative
     luminance + ratio is ~15 lines of pure python — implemented inside the spell, no new
     dependency. This is the *systematic* fix for the grey-on-white class of bug — an
     unreadable pairing fails the build instead of being discovered in a dropdown three
     months later.
  3. **No hand-edit drift:** re-render == committed output, **byte-identical from the moment
     a rendered file is first adopted** (Phase 1 commits the regenerated form as the new
     canonical — we do NOT chase byte-parity with today's hand formatting; parity is verified
     visually, see Phase 1 acceptance).
- Non-text artifacts (Kvantum SVG, GTK asset SVGs, papirus folder tint) use **generated
  recolor maps**: `aether-kvantum.map` becomes a template itself; a variant renders its own
  map, then the existing `recolor.sh` machinery runs per variant
  (`RaBbLE-Aether-Dawn.kvconfig/.svg`, etc.).

### 2.4 themectl (the switch)

Two distinct operations — the Opus review (S204) flagged that letting a live switch rewrite
~30 committed files would recreate exactly the multi-file working-tree churn the anti-clobber
discipline exists to prevent, so:

**`themectl set <variant> [<profile>]` — ephemeral switch.** Renders to a temp tree, verifies,
then deploys **directly to the live targets** (`~/.config/...` etc.) — the repo tree is not
touched. Records what's live in `~/.local/state/rabble/theme.state` (a *record*, not a source
of truth). `dotctl status` will show the themed bundles as drifted while an ephemeral theme is
active — `themectl status` says so explicitly and names the active variant/profile.

**`themectl adopt <variant> [<profile>]` — change the committed default.** Renders into the
repo homes (`config/` + Aether artifacts), atomic as above, then `dotctl apply` + Ansible-tag
hints. This is the deliberate "make it the new default" path; it produces a diff you commit.

Both end with reload hooks: `hyprctl reload` · `pkill -x waybar; waybar &` · `makoctl reload`
· `pkill -x swayosd-server` + respawn · gsettings `color-scheme` per variant `scheme` ·
kvantum theme select. Surfaces that need restarts get named, not hidden: Firefox and VSCodium
(chrome injection), and **KDE apps** — KF6 `KColorSchemeManager` caches the palette per-app
(S201 lesson), so Dolphin et al. recolor on next launch, not live.

### 2.5 aether-dawn — light variant (hexes are PROPOSALS, not canon)

Inverting void↔paper is not enough: neon-on-dark hues are unreadable on white (cyan `#00f5ff`
on white ≈ 1.4:1). Dawn needs darkened "ink" versions of the neons. **Per the palette rule,
these become canon only after Mark tunes/approves them into `RaBbLE-Palette.md`** — they are
starting candidates chosen to pass the same `contrast_pairs` gates:

| Role | Void | Dawn candidate | Note |
|---|---|---|---|
| bg | `#0a0010` | `#faf7ff` | paper with violet tint, not pure white |
| surface | `#12132a` | `#f0ecfa` | |
| raised | `#1a1b2e` | `#ffffff` | cards float above paper |
| border | `#2a2840` | `#d8d2e8` | |
| text | `#e8e6f0` | `#1a1030` | void-derived ink |
| muted | `#6b6880` | `#6b6880` | survives both modes (≈4.6:1 on paper) |
| magenta | `#ff2d78` | `#c40e5c` | ≥4.5:1 on paper |
| cyan | `#00f5ff` | `#00778a` | teal ink |
| violet | `#bf5fff` | `#7a2fc2` | |
| pink | `#ff79c6` | `#b0357f` | |
| red / green / yellow | `#e05c6f` / `#50fa7b` / `#f1fa8c` | `#b8394d` / `#1e7a42` / `#8a6d00` | yellow darkens hardest |

Dawn also flips per-surface scheme signals: gsettings `prefer-light`, kdeglobals
`ColorScheme=` a Dawn `.colors` file, qt5/6ct light palette, Firefox
`ui.systemUsesDarkTheme=0` + content scheme light, GTK `gtk-application-prefer-dark-theme=0`.

### 2.6 Surface conversion matrix

| Tier | Surfaces | Method | Effort |
|---|---|---|---|
| **1 — plain text configs** | kitty, fuzzel, mako, waybar CSS, hypr `look.conf`, yazi, zsh colors, swayOSD, claude theme, dotctl/spell ANSI colors | direct tokens in template | trivial each |
| **2 — structured configs** | qt5ct/qt6ct conf, kdeglobals, KDE `.colors` schemes, GTK3 `@define-color` block, GTK4 css, VSCodium theme JSON + custom.css, Firefox userChrome/userContent/user.js | template + per-format care | moderate |
| **3 — generated artifacts** | Kvantum SVG+kvconfig (map-per-variant), GTK3 asset SVGs, papirus folder tint (`--color` per variant), fastfetch SGR art | recolor-map pipeline | moderate, mechanical |
| **4 — boot chain** | GRUB assets, Plymouth frames (built from NeBuLA `Boot.html` — inherits web tokens), SDDM QML | existing `generate/build-assets.sh` scripts re-run per variant | **deferred** — boot is reboot-cadence, one variant is fine until Dawn is daily-driven |

Out of scope here but aligned: NeBuLA/World web CSS can consume the same YAML later for a
`:root[data-theme="dawn"]` web mode — same data canon, separate effort.

---

## Part 3 — Phases

### Phase 0 — Triage (no infrastructure; ship this week)
- **Firefox dropdowns:** stop force-darkening content wholesale. Test matrix on a known-bad
  light site, in order: (a) drop `ui.systemUsesDarkTheme` force, keep dark *preference* via
  `layout.css.prefers-color-scheme.content-override` (dark) so dark-supporting sites stay
  dark but widgets follow the page's effective scheme; (b) if widget mismatch persists, set
  `browser.theme.content-theme=2` / `content-override=2` (system) and accept light rendering
  on light-only sites — note the `-1 = auto` claim in `user.js:14`'s comment is wrong, valid
  values are 0/1/2 (S204 Opus review); (c) guard any `userContent.css` form-control styling
  inside `@media (prefers-color-scheme: dark)`.
  Verify with screenshots (Playwright or live grim) on: light site w/ select, dark site,
  about:preferences. **Exact pref combo is decided by the live test, not this doc.**
- Purge the 16 off-palette strays in `config/` (includes the daily-visible `#8860aa`/`#120025`
  inactive borders in `look.conf`) → canon equivalents.
- Fix `group_vars/all.yml`: replace stale `rabble_color_*` values with the canon
  `rabble_palette` dict the docs already claim exists (interim until Phase 1 YAML) — and
  correct `RaBbLE-Palette.md`'s Ansible-block section, which currently asserts that dict
  already lives there (it doesn't; canon and reality must agree).
- Acceptance: dropdown readable on light sites; `grep` for stray hexes returns zero; no visual
  regression on daily surfaces.

### Phase 1 — Token core + pilot
- Create `RaBbLE-Agent/palette/aether-void.yml` + `profiles/{surge,drift,still}.yml` + schema
  doc section in `RaBbLE-Palette.md`.
- Build `theme-render.sh` + `theme-verify.sh` (hex subset + contrast + drift gates).
- Convert pilots: **kitty, fuzzel, mako** (small, instant visual verification).
- Acceptance: render(void×surge) is **visually identical** to today's pilots (screenshot
  parity, not byte parity — the regenerated form is committed as the new canonical and the
  drift gate is byte-exact from then on); verify gate green; pilots deploy + reload cleanly.

### Phase 2 — Full sweep (absorbs Convergence A1–A3)
- Convert Tier 1 remainder (waybar, look.conf, swayOSD, yazi, zsh, claude) — this is where
  motion/glow/accent knobs get wired into waybar/look.conf/swayOSD templates.
- Convert Tier 2 (Qt/KDE/GTK/VSCodium/Firefox) — do Convergence A1 (naming) and A2 (off-palette)
  in the same pass; A3 becomes "VSCodium JSON is a template" under this plan's render-commit
  model.
- Acceptance: `theme-verify` green across every themed file; **drift profile becomes the
  committed default** (Mark's sign-off on the calm look).

### Phase 3 — Variants + switcher
- Mark tunes/approves Dawn hexes → `RaBbLE-Palette.md` Variants section + `aether-dawn.yml`.
- Per-variant Kvantum/KDE/GTK artifacts (Tier 3 pipeline), `themectl` + reload hooks.
- Acceptance: `themectl set dawn drift` → readable, coherent light desktop in <1 min without
  logout (Firefox/VSCodium restart excepted); `themectl set void surge` restores full synthwave.

### Phase 4 — Deep surfaces (deferred)
- fastfetch art per variant, boot chain per variant, papirus tint automation, web `data-theme`
  alignment.

---

## Open questions for Mark

1. **Default profile:** is `drift` as specced (static gradients, glow off, magenta+violet,
   cyan only for focus/links) the right "sane default," or should the default keep glow?
2. **Naming:** variants `void`/`dawn`, profiles `surge`/`drift`/`still` — keep or rename?
3. **Dawn hue direction:** darkened-neon inks (proposed) vs. a softer pastel-leaning light
   mode (would bend the "no pastels" palette philosophy — needs an explicit call).
4. **Waybar agent-status animations** (sCoRE tracker pulse/flash): semantic-exempt in every
   profile, or governed by the motion knob?
5. **Data canon home:** Grimoire `RaBbLE-Agent/palette/` (recommended — matches the "colors
   from Grimoire only" rule, but makes builds read the Grimoire tree) vs.
   `RaBbLE-Aether/themes/_palette/` (keeps build inputs in the design engine; Grimoire doc
   then mirrors rather than sources)?

## Cold-start

```bash
# Read first
cat RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md
cat RaBbLE-Grimoire/log/plans/OS-Theming-Variants-Plan.md          # this plan
cat RaBbLE-Grimoire/log/plans/Aether-Theming-Convergence.md        # absorbed tracks A1–A3
cat RaBbLE-Aether/themes/_palette/aether-kvantum.map               # the pipeline model
# Phase 0 targets
cat RaBbLE-OS/config/firefox/user.js                               # dropdown root cause :12/:15
grep -rn '#8860aa\|#120025' RaBbLE-OS/config/                      # daily-visible strays
sed -n '20,30p' RaBbLE-OS/ansible/inventory/group_vars/all.yml     # stale palette vars
# Deploy paths (unchanged by this plan)
bash RaBbLE-OS/RaBbLE-OS-dotctl.sh list
cat RaBbLE-OS/ansible/roles/apps/tasks/qt-gtk-theme.yml
```

```
spark ~ theming >> variants and profiles designed: one canon, many moods, contrast-gated // %THEME_VARIANTS_PLANNED%
```
