# Plan: RaBbLE-OS Settings App — Aether-themed local control surface

**Status:** 🟡 SKETCH — design only, not started. Spun out of `log/plans/OS-ProArt-Power-Stack-Plan.md` Phase 5.
**Repo:** RaBbLE-OS `new-horizons` · **Origin:** 2026-07-06 (S197)
**Goal:** A local, Aether-themed web app for tweaking RaBbLE-OS surface features (waybar, Hyprland, power modes) that carries the OS's actual visual identity, backed by a small localhost Python service with polkit-gated privileged actions.

> This is a **cold-start handoff**. A follow-up session should be able to pick this up without prior context. Read the "Prerequisites already built" section first — the power-stack pass (S197) deliberately shaped its outputs so this app can call into them without rework.

---

## Why a web app (decided, not open)

Mark's decision (recorded in the power-stack plan): **local Aether-themed web app**, not GTK4, not TUI.
- **Not GTK4** — libadwaita theming is a known limitation already hit by `qt-gtk-theme.yml`; the app would not carry RaBbLE-OS's identity.
- **Not a TUI** — a web app renders the real visual language (Aether tokens, NeBuLA accents).
- **Web app** — vanilla HTML/CSS/JS consuming Aether tokens directly, exactly like RaBbLE-World. No React, no separate theming pass.

---

## Prerequisites already built (S197 power-stack pass)

- **`RaBbLE-OS/spells/power-profile-capture.sh`** emits a **stable machine-readable JSON snapshot** (battery draw, nvidia power_state/pstate, tuned + asusd profiles, sensors). The diagnostics tab consumes this JSON directly — do not re-scrape; call the spell / read its JSON output.
- **`RaBbLE-OS/config/waybar/scripts/power-profile.sh`** is the composite 3-mode power picker (`get` → waybar JSON, `cycle`). The app's power-mode picker should drive the SAME script/modes (Quiet·Low-Power / Quiet·Balanced / Unbounded) so waybar and the app never diverge.
- **`config/hypr/conf.d/look.conf`** blur/opacity are the live GPU-cost levers the Hyprland tunables tab edits (`hyprctl reload` after write).

---

## Architecture sketch

- **Frontend:** vanilla HTML/CSS/JS, Aether tokens via `var(--*)` (same convention as World — no hex, no font stacks; palette from Grimoire `RaBbLE-Agent/RaBbLE-Palette.md`). No React.
- **Backend:** small local Python service, **systemd user unit, localhost-only** (bind 127.0.0.1). Reads live state (waybar/hyprland config, the capture-spell JSON) and writes changes.
- **Privilege boundary:** privileged actions (modprobe.d, `systemctl enable/disable`, `asusctl`) go through a **polkit policy**, never raw sudo. Non-privileged config edits (waybar/hypr user configs) the user unit writes directly.
- **Packaging:** new ansible role (e.g. `apps/settings-app`) installs the backend service + `.desktop` entry. **Source lives in `RaBbLE-OS/settings-app/`** (code stays in the member repo; this design doc stays in the Grimoire — Grimoire-is-docs / members-hold-code rule).

## Surface (tabs)

1. **Waybar** — module toggles / ordering.
2. **Hyprland** — blur/animation sliders that edit `look.conf` + `animations.conf`, then `hyprctl reload`.
3. **Power** — the Phase-4 composite power-mode picker (drives `power-profile.sh`).
4. **Diagnostics** — fed directly by `power-profile-capture.sh`'s JSON output (live power draw, dGPU power_state, thermals).

---

## Open questions for the follow-up session

- Web framework for the tiny backend: stdlib `http.server` vs a micro-framework — keep dependency-light (local-first rule).
- Polkit policy granularity: one action per privileged operation vs a coarse "settings-app admin" action.
- How the frontend is served/opened: `xdg-open http://127.0.0.1:PORT` from the `.desktop` entry vs a thin webview wrapper.
- Whether Hyprland slider writes should be live-preview (transient `hyprctl keyword`) with an explicit "save to look.conf" commit.

---

→ `log/plans/OS-ProArt-Power-Stack-Plan.md` — parent plan (Phases 1–4 implemented S197; this is its deferred Phase 5)
→ `RaBbLE-OS/spells/power-profile-capture.sh` — diagnostics JSON source
→ `RaBbLE-OS/config/waybar/scripts/power-profile.sh` — power-mode picker backend
→ `RaBbLE-Agent/RaBbLE-Palette.md` — the only permitted color source
