# Plan: Fix Dolphin Grey/Unreadable Text in RaBbLE-OS

**Status:** ⚠️ `no_inactiveness` hypothesis **DISPROVEN by live measurement (S167)** — see
"LIVE TEST RESULT" below. Labels are dim even when the window is ACTIVE. Diagnosis continues;
new leading hypothesis = QPalette `Inactive`/`Disabled` group used + dimmed (needs Strategy 2 or
a palette dump to confirm). The two kvconfig edits are retained as sane tiling-WM defaults, **not
as the fix**.
**Repo:** RaBbLE-OS `new-horizons` · **Implement as:** Sonnet (well-scoped, deterministic).

---

## LIVE TEST RESULT (S167) — read this first

The `no_inactiveness=true` fix was deployed and tested live (the machine was rebooted, so the
deployed Kvantum config was loaded fresh). **It did NOT fix the dim text.**

- Deployed `~/.config/Kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig` confirmed `no_inactiveness=true`,
  `reduce_window_opacity=0` (grep on the live file).
- Dolphin captured while **actively focused** (Hyprland active border present, `activewindow`=dolphin):
  file labels + sidebar items **still dim**. Sampled label pixels ≈ **#656769 (101,103,105)** — a dim
  neutral grey. (An active window would render bright if inactive-dimming were the cause.)
- ⚠️ Harness caveat that bit S167 twice: Dolphin and VSCodium were **floating/overlapping**, and
  `alterzorder top` did NOT reliably raise Dolphin → several captures measured VSCodium, not Dolphin.
  The ONLY trustworthy capture was the actively-focused Dolphin one. **Use the tiled, non-overlapping
  harness** (below) — do not trust `alterzorder` on floating windows.

**Conclusion:** focus state is not the mechanism. The label color is dim regardless of active/inactive.
**Leading hypothesis now:** Dolphin's `KItemListView` reads `QPalette.color(group, Text)` and (per the
Wayland activation bug `tsujan/Kvantum#911`) `group` may resolve to `Inactive`/`Disabled` even for a
Hyprland-focused window; Kvantum populates those palette groups dimmed, and `no_inactiveness` only
changes Kvantum's *rendering*, not the palette group's *color values*. → This is what **Strategy 2**
(pin the palette via qt6ct `custom_palette=true` with bright `inactive_colors`/`disabled_colors`) was
meant to solve. Mark originally chose Strategy 1; the live disproof is grounds to revisit.

**Next disciplined step (ends the guessing):** install `python3-pyqt6` (add to manifest) and dump the
resolved `QApplication.palette()` for all groups × roles — this prints the EXACT color Dolphin's text
uses in Active vs Inactive, with zero rendering ambiguity. Decide the fix from that, not screenshots.

## TL;DR for the implementer

Dolphin labels render dim grey (≈#656769) **regardless of window focus** (measured live, S167).
The earlier theory — *Kvantum dims inactive windows* (`no_inactiveness`) — was tested and **failed**.
Four prior sessions failed tuning palette *colors* (`[ItemView] text.normal.color`, `kdeglobals`,
qt6ct color file); two of those are inert under qt6ct `custom_palette=false`. The real lever is
**which QPalette group/role Dolphin's `KItemListView` actually reads, and what value that group
holds** — confirm with a palette dump (see "LIVE TEST RESULT"), then fix at that layer.

---

## Root cause (confirmed by live inspection + upstream sources, S167)

1. **qt6ct `custom_palette=false`** in `~/.config/qt6ct/qt6ct.conf`. qt6ct only applies
   `color_scheme_path` when `custom_palette=true`. So `config/qt6ct/colors/CatppuccinMochaMauve.conf`
   and `config/kdeglobals/kdeglobals` are **INERT** — the whole Qt palette comes from
   **Kvantum `[GeneralColors]`** (`text.color=#f8f4ff`). Every prior edit to those files was a no-op.
   *(Sources: Arch BBS "QT Apps completely ignore the theme"; hyprdots PR #2058; catppuccin/nix #275.)*

2. **Kvantum is the only Qt style that visually dims *inactive* windows**, gated by
   `no_inactiveness` (default `false` = dimming ON). Dolphin's `KStandardItemListWidget` selects
   `QPalette::Inactive` when `!isActiveWindow()`; Kvantum renders that group dimmed → grey labels &
   sidebar items. A known **Wayland activeness-detection bug** makes Kvantum mis-judge focus under
   Hyprland, worsening it. Upstream `lxqt/pcmanfm-qt#560` ("No Inactive Item Text in Icon View Mode")
   is this exact symptom. *(Sources: tsujan/Kvantum discussion #911, issues #560/#675.)*

**Visual proof (S167):** Dolphin inactive → all folder labels + sidebar items dim; only the selected
item (magenta highlight) + toolbar bright. Classic inactive-window dimming, not a color error.

**Layered-dimming model to preserve:** Hyprland compositor dims whole windows uniformly
(`decoration:inactive_opacity = 0.93` + Dolphin windowrule `opacity 0.97 0.95`) — KEEP, it preserves
in-window contrast and Mark wants it. The bug is Kvantum *additionally* dimming text/icons at the Qt
layer, which destroys contrast. Compositor owns window dimming; Kvantum must not.

---

## The change (Strategy 1 — Kvantum-driven)

Edit **source only** (`RaBbLE-OS/config/...`), deploy via `dotctl`. NEVER edit `~/.config` directly.

**File:** `RaBbLE-OS/config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig`, section `[%General]`:

| Key | From | To | Why |
|---|---|---|---|
| `no_inactiveness` | `false` | `true` | The actual fix — stop dimming text/icons in inactive windows; also dodges the Wayland focus bug. |
| `reduce_window_opacity` | `10` | `0` | Hyprland already owns window-level inactive fade. Kvantum's value double-dims at the Qt layer. Hand window dimming entirely to the compositor (Mark's intent). |

> ⚠️ **Current working-tree state:** these two edits were ALREADY applied to the source file and
> deployed via `dotctl apply kvantum` during the S167 diagnosis session — but **not verified with the
> harness and not committed**. Confirm they're present (`grep -nE 'no_inactiveness|reduce_window_opacity'`),
> then proceed straight to verification. If the working tree was reset, re-apply per the table.

**Conditional secondary (only if harness proves headers illegible):** Places-sidebar *section headers*
("Places", "Devices") use `QPalette::Disabled` (measured ≈ `#747679`). Kvantum
`[GeneralColors] disabled.text.color = #8860aa`. Subdued headers are by-design — only bump this toward a
readable lavender **if** the harness shows them genuinely unreadable after the primary fix. Use an
existing Aether value only (`RaBbLE-Grimoire/RaBbLE-Agent/RaBbLE-Palette.md`) — never invent a hex.

**Do NOT touch** (inert / out of scope): `qt6ct.conf custom_palette`,
`config/qt6ct/colors/CatppuccinMochaMauve.conf`, `config/kdeglobals/kdeglobals`,
`config/color-schemes/CatppuccinMochaMauve.colors`, any Hyprland opacity rule.

---

## Deploy

```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
grep -nE 'no_inactiveness|reduce_window_opacity' config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig
# expect: no_inactiveness=true , reduce_window_opacity=0  (re-apply if not)
bash RaBbLE-OS-dotctl.sh apply kvantum
grep -nE 'no_inactiveness|reduce_window_opacity' ~/.config/Kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig
```

---

## Verification — controlled harness (the part that burned prior sessions)

Prior failures = floating/overlapping windows, whole-window brightness, uncontrolled focus. Fix all three.

**Environment constants:** display scale=2 (physical = logical×2). `grim` full = 3840×2400.
A Dolphin **restart reloads Kvantum** — NO logout needed (each process re-reads the kvconfig at launch;
the old "needs logout" belief was a symptom of editing the wrong knob).

**Procedure**
1. Put Dolphin + a terminal on one empty workspace so Hyprland **tiles them side-by-side** (no overlap,
   no z-order ambiguity — what broke the S167 quick test).
2. **Focus the terminal** → Dolphin is fully visible AND inactive. Confirm with
   `hyprctl activewindow -j` (class must NOT be dolphin). Get Dolphin geometry from `hyprctl clients -j`.
3. `grim` → crop to Dolphin's region (logical×2). Crop **just** the icon-label band and the sidebar
   column; sample text-pixel luminance per-region. Then **focus Dolphin** (active) and recapture.
4. **Pass criteria:**
   - Inactive-state icon-label + sidebar-item luminance ≈ active-state (bright, ~`#f8f4ff`) — not dim.
   - Selected item still shows `#ff2d78` highlight.
   - Hyprland's whole-window inactive fade still visibly present (compositor dimming preserved).
5. Save before/after crops to scratchpad and **read them back visually** — don't trust pixel counts alone.
   (S167 "before" capture: inactive labels dim, on disk — reuse as the documented before if convenient.)
6. If sidebar *headers* still illegible → apply the conditional `disabled.text.color` tweak, re-run 2–4
   for the sidebar region only.

---

## Wrap-up

1. Update this doc: mark **RESOLVED**, record harness numbers (before/after luminance per region).
2. Commit (Pulse Protocol), e.g.:
   `mend ~ os >> dolphin text legible: kvantum no_inactiveness ends inactive-window dimming // %DOLPHIN_TEXT_FIXED%`
   (Active branch: `RaBbLE-OS-New-Horizons`. Do NOT merge to main — episode-gated.)
3. `bash ../RaBbLE-Grimoire/spells/end-session.sh dolphin-text "<note>"`.
4. If scope was claimed: `promote-insight.sh auto` then `agent-register.sh release`.

## Deferred follow-up (separate task — Mark approved deferring)
Make the **Aether palette complete & robust across KDE + GTK**, and reconcile the currently-inert
qt6ct / kdeglobals / color-scheme files to Aether so there's a single source of truth (today Kvantum
uses Aether `#f8f4ff`/void while those files carry leftover Catppuccin `#cdd6f4`/`#1e1e2e`). Log in
RaBbLE-OS Roadmap / KnownIssues.

## Key files
| File | Role |
|---|---|
| `RaBbLE-OS/config/kvantum/RaBbLE-Aether/RaBbLE-Aether.kvconfig` | **THE FIX** — `[%General] no_inactiveness`, `reduce_window_opacity`; palette in `[GeneralColors]` |
| `~/.config/qt6ct/qt6ct.conf` | `custom_palette=false` — why kdeglobals/qt6ct color files are inert (do not change) |
| `~/.config/hypr/conf.d/look.conf` + `windowrules.conf` | Hyprland compositor inactive opacity — KEEP, owns window dimming |
| `RaBbLE-OS-dotctl.sh` | `apply kvantum` to deploy source → `~/.config/Kvantum/` |
