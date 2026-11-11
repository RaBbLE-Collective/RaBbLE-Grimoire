# Plan: RaBbLE-OS Display Manager — first first-party app

**Status:** 🟢 Phase 1 + web editor built (S246, uncommitted): `RaBbLE-OS/display-manager/` (`python -m rdisplay list|apply|save|profiles|revert|gui`). Daemon (hotplug + drift-watch) and GTK overlay built. Still to do: dotctl-generated persistence from the editor, Ansible role, GNOME/KDE backends.
**Repo:** RaBbLE-OS `new-horizons` · **Source home:** `RaBbLE-OS/display-manager/` (code in member, this doc in Grimoire)
**Goal:** Graphically arrange monitors, set resolution / refresh / scale / rotation, save named profiles, and auto-apply them on hotplug. First module of the future Settings App (`OS-Settings-App-Plan.md`).

## Decisions (Mark, 2026-10-13)

- **Shape: Hybrid.** Python core library + CLI + hotplug daemon; native GTK4 + gtk4-layer-shell overlay; full editor as a local web page (Aether-themed) so it carries RaBbLE-OS identity per the S197 "not GTK4 for the settings app" decision. The overlay is the only GTK piece.
- **Prototype stack: Python.** Fastest to build; port to Rust later if performance demands. No Quickshell dependency.
- **v1 scope:** drag-and-drop layout editor + mode/scale/rotation + create/move/save configs (profiles) + hotplug auto-switch + apply with 15s confirm-or-revert.
- **Compositor-portable core.** Mark may leave Hyprland (instability, breaking changes). Backend interface with Hyprland IPC first, `wlr-output-management` (works on Sway, river, etc.) second. GNOME/KDE would be separate backends later.

## Current state (found S246)

- Monitors: `eDP-1` 3840x2400@60 scale 2; `HDMI-A-1` Viewteck GNV27DB 1920x1080 scale 1 at `auto-right`.
- Layout is hardcoded in `config/hypr/conf_d/monitors.lua` (single `hl.monitor` for HDMI, nothing for eDP). Workspace 11 pinned to HDMI-A-1; `scripts/hdmi-hotplug.sh` moves it on connect (socat on `.socket2.sock`).
- `XF86Display` runs `kanshictl switch`, but no `~/.config/kanshi/config` exists, so it does nothing. This app replaces both.
- **144Hz is not offered on the HDMI link:** the monitor's EDID advertises only 48-76Hz V, max 2560x1440@75, so the laptop port (ProArt P16 can do HDMI 2.1) is not the cap. Cause is monitor HDMI input, an OSD setting, or cable/adapter; Mark suspects the KVM (EDID emulation; serial reads all zeros). Test: plug monitor direct to laptop; OSD HDMI/refresh setting, Ultra High Speed cable, then USB-C to DP. The UI should grey out and explain modes the link doesn't advertise instead of hiding them.
- Previously noted "3-screen concept" has no written plan; only a VM test mention at `SESSION-LOG.md:393`. Treat 3-screen as just another profile.

## Architecture

```
display-manager/
  core/        backend interface, model (Monitor, Mode, Layout, Profile), profile store
    backends/  hyprland.py (hyprctl -j + IPC socket2) · wlroots.py (wlr-output-management)
  cli/         rdisplay list|apply|save|revert|profiles
  daemon/      hotplug watcher: match connected monitors -> profile, apply; replaces hdmi-hotplug.sh
  overlay/     GTK4 + layer-shell quick view / apply / revert prompt
  web/         localhost editor (127.0.0.1 only), vanilla JS canvas, Aether tokens via var(--*)
```

- **Profiles** live in `~/.config/rabble/display/profiles/*.toml`, stored as JSON (stdlib can't write TOML), keyed by monitor **description** (make/model/serial), not port name, so `HDMI-A-1` vs `DP-1` changes don't break them. Matching: best profile whose monitor set equals connected set, else fallback.
- **Persistence:** apply live first; on "Save", render the active profile into a generated `monitors.lua` deployed through dotctl (edit `RaBbLE-OS/config/`, never `~/.config/` directly). Hyprland-only; other backends persist via their own mechanism.
- **KVM-aware hotplug:** input switching looks like unplug/replug. Debounce events (~2s), keep last-known layout for a vanished monitor, and don't migrate workspaces on a transient removal.
- **Safety:** every apply starts a 15s revert timer; only "Keep" commits. Never leave zero enabled monitors.
- **Workspace pinning** becomes profile data (replaces hardcoded `workspace_rule` for ws 11).

## Portability (Mark: must port to GNOME or KDE, whichever becomes the simple fallback)

Core is backend-agnostic: `rdisplay/backends/<name>.py` provides `detect()`, `list_monitors()`, `apply_layout()`. Only Hyprland exists. Planned: **KDE** via `kscreen-doctor`/KScreen D-Bus, **GNOME** via Mutter `org.gnome.Mutter.DisplayConfig` D-Bus (`GetCurrentState`/`ApplyMonitorsConfig`), **wlroots** via `wlr-randr`. GNOME/KDE already ship display settings, so the value there is profiles + hotplug + the same editor. Persistence differs (no monitors.lua), so "Save" must go through the backend, not dotctl.

## Verified in S246

`hyprctl eval 'hl.monitor{...}'` is the live-apply path on 0.56 (`keyword monitor` is rejected). No-op apply, CLI list/save, server API, same-origin guard, apply/confirm state, and editor drag verified. Untested on real hardware: the `disabled=true` path and the revert timer actually firing.

## Open bug: waybar vanished on eDP-1 when HDMI attached

Waybar (running since boot) kept an eDP-1 layer at 0,0 while eDP-1 had moved to 3840,0. Re-applying eDP-1 at 0,0 realigned them. Root trigger (KVM hotplug reordering?) unconfirmed; the hotplug daemon should re-assert layout and `SIGUSR2` waybar after the debounce.

## Phases

1. **Core + CLI (Hyprland backend):** read monitors, apply live, revert timer. First verify the Hyprland 0.56 Lua-era live-apply command (`hyprctl keyword monitor` vs eval); do not assume.
2. **Profiles + hotplug daemon:** profile store, matching, systemd user unit; retire `hdmi-hotplug.sh`.
3. **Web editor:** drag canvas with edge snapping, mode/refresh/scale pickers, link-limit explanation, save/rename/duplicate profiles.
4. **GTK4 overlay:** `XF86Display` / keybind quick switcher + confirm-or-revert prompt.
5. **Persistence + dotctl generation**, Ansible role + `.desktop`, manifest entries (Mark runs the layerctl command; per Ansible-driven installs rule).
6. **wlroots backend** (portability), when leaving Hyprland becomes real.

## Native editor window (S246)

Mark: the browser-tab editor "is not desktop app like"; it must be its own applet on the screen it was summoned from. `rdisplay app` is now a native GTK4 window (`rdisplay/app.py`, app id `world.rabble.rdisplay`): drag canvas with edge/center snapping, mode/scale/rotation/position, profiles, keep/revert banner. Single instance; re-summon reopens it on the focused screen (unless a keep/revert prompt is pending). Hyprland `windowrules.lua` floats, sizes 1040x700 and centers it, so it opens on the screen it was launched from. WebKitGTK (GTK4) is not installed, so a webview wrapper was rejected rather than adding a package. The web editor (`rdisplay gui`, `web/`) remains for now; candidate for removal once the Settings App decides its own shell. Verified: launcher entry, placement from each screen, single instance. Untested: dragging/applying from the native window by hand.

## Overlay (S246)

`rdisplay overlay`: GTK4 + gtk4-layer-shell, OVERLAY layer, Aether tokens read from `aether.css` into `@define-color`. Shows a mini layout map, profile buttons (current highlighted), keep/revert prompt after applying, Open editor, Esc closes; second call toggles it off (pidfile). Needs `LD_PRELOAD=libgtk4-layer-shell.so.0` (CLI re-execs itself). Bound to `XF86Display` and `Super+Shift+P` (replaced dead kanshictl bind). Verified: layer renders, toggle, command via Hyprland exec. Untested: physical key press, clicking a profile + keep/revert in the overlay.

## Open items

- Web server vs `file://`: reuse the Settings App localhost service design (stdlib vs micro-framework still open there).
- Fractional scale and `transform` rotation handling per backend.
- Whether to add a color-managed / VRR / 10-bit field in v1 (default: no).

## Sources

`RaBbLE-OS/config/hypr/conf_d/monitors.lua` · `config/hypr/scripts/hdmi-hotplug.sh` · `config/hypr/conf_d/functionkeys.lua` (XF86Display) · `config/hypr/conf_d/workspaces.lua` · `log/plans/OS-Settings-App-Plan.md` · `RaBbLE-OS/Hyprland-0.55-Reference.md`
