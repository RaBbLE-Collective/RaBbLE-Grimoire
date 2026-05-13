# RaBbLE-OS — Hyprland UI/UX Guide

```
transcribe ~ grimoire >> hyprland desktop reference — keybinds, layout, window rules // %UX_ENTROPY_TEST%
```

> Complete reference for navigating and configuring the RaBbLE-OS desktop.
> Config lives in `RaBbLE-OS/config/hypr/`. All scripts are in `config/hypr/scripts/`.

---

## Layout Model — Dwindle (i3-style)

RaBbLE-OS uses Hyprland's **dwindle** layout. It behaves like i3's binary-split tiling:

- Each workspace is a binary tree of splits
- Every new window splits the focused window's slot
- Default split direction: **right** (new window opens to the right of focused)
- Split direction is remembered per-node (`preserve_split = true`)
- `Super+T` toggles the spawn direction for the next window

### Key dwindle settings (`look.conf`)

| Setting | Value | Effect |
|---|---|---|
| `preserve_split` | `true` | Each node remembers its split direction |
| `smart_split` | `false` | User controls direction; no auto-decide |
| `force_split` | `2` | New window always goes right/below of focused |

### How splits work

```
One window:          Two windows (h-split):    Two windows (v-split):
┌────────────┐       ┌──────┬──────┐           ┌────────────┐
│            │  →    │  A   │  B   │     or    │     A      │
│     A      │       │      │      │           ├────────────┤
│            │       │      │      │           │     B      │
└────────────┘       └──────┴──────┘           └────────────┘
```

Default is always the left diagram (h-split, B opens right of A). Press `Super+T` before opening B to get the right diagram.

---

## Split Direction Toggle — `Super+T`

`Super+T` is the i3-equivalent of `split h` / `split v`.

| State | OSD notification | Next window opens |
|---|---|---|
| Default | — | → right (horizontal) |
| After one `Super+T` press | `Split ↓ vertical` | ↓ below (vertical) |
| After second `Super+T` press | `Split → horizontal` | → right (horizontal) |

**Persisted by daemon:** `split-dir-daemon.sh` runs at login and watches the Hyprland event socket. After every window open, it re-applies `preselect r` (h-mode) or `preselect d` (v-mode). The mode holds until you toggle again.

**Does NOT rearrange existing windows.** Only affects where the next new window opens.

---

## Keybind Reference

### Session

| Key | Action |
|---|---|
| `Super+Shift+Q` | Close focused window |
| `Super+Shift+E` | Exit Hyprland |
| `Super+L` | Lock screen (hyprlock) |
| `Super+F1` | Show keybind help |

### Applications

| Key | Action |
|---|---|
| `Super+Return` | Terminal (kitty) |
| `Super+Space` | Launcher (fuzzel) |
| `Super+B` | Browser (firefox) |
| `Super+E` | File manager (dolphin, opens floating) |
| `Super+S` | Screenshot (interactive region) |
| `Super+Shift+S` | Screenshot region → clipboard |
| `Super+Shift+C` | Clipboard history (fuzzel dmenu) |

### Window Layout

| Key | Action |
|---|---|
| `Super+T` | Toggle split direction → ↔ ↓ (sets next window spawn direction) |
| `Super+F` | Fullscreen |
| `Super+Shift+F` | Fake-fullscreen (fills space, keeps decorations) |
| `Super+V` | Toggle floating |
| `Super+P` | Pseudo-tile (dwindle) |
| `Super+G` | Toggle window group |
| `Super+O` | Switch to master layout |
| `Super+Shift+O` | Switch back to dwindle layout |

### Split Preselect — Fine-grained (i3 Ctrl+arrow equivalent)

Set where the **next** window opens before you launch it. One-shot (consumed by one window).

| Key | Next window position |
|---|---|
| `Super+Ctrl+H` / `←` | Left of focused |
| `Super+Ctrl+L` / `→` | Right of focused |
| `Super+Ctrl+K` / `↑` | Above focused |
| `Super+Ctrl+J` / `↓` | Below focused |

### Focus Navigation

Uses `smart-focus.sh`: tries `movefocus` in direction, falls back to `cyclenext` if no neighbor exists. Focus always moves even in pure-horizontal layouts.

| Key | Action |
|---|---|
| `Super+H` / `Super+←` | Focus left (cycle prev if no left neighbor) |
| `Super+L` / `Super+→` | Focus right (cycle next if no right neighbor) |
| `Super+K` / `Super+↑` | Focus up (cycle prev if no neighbor above) |
| `Super+J` / `Super+↓` | Focus down (cycle next if no neighbor below) |

### Move / Swap Windows

| Key | Action |
|---|---|
| `Super+Shift+H/L/K/J` | Swap with neighbor in direction (HJKL only; needs a neighbor) |
| `Super+Shift+←` / `→` | Move window left / right through layout |
| `Super+Shift+↑` | Move window up — if no vertical neighbor, flips split to vertical (window ends on top) |
| `Super+Shift+↓` | Move window down — if no vertical neighbor, flips split to vertical (window ends on bottom) |

`Super+Shift+↑/↓` use `smart-movewindow.sh` which creates vertical splits inline when needed.

### Resize Mode

Press `Super+R` to enter resize mode, then:

| Key | Action |
|---|---|
| `H` / `←` | Shrink width |
| `L` / `→` | Grow width |
| `K` / `↑` | Shrink height |
| `J` / `↓` | Grow height |
| `Escape` / `Return` | Exit resize mode |

### Groups (tab stacking)

Stack multiple windows in the same tile slot, tab between them.

| Key | Action |
|---|---|
| `Super+G` | Toggle group on focused window |
| `Super+Alt+H/L/K/J` | Move focused window into group in direction |
| `Super+Alt+←/→` | Move into group left/right |
| `Super+Alt+Escape` | Move window out of group |

### Master Layout (toggle with `Super+O`)

| Key | Action |
|---|---|
| `Super+Shift+Return` | Swap focused with master |
| `Super+,` | Remove a master slot |
| `Super+.` | Add a master slot |

### Workspaces

| Key | Action |
|---|---|
| `Super+1–0` | Switch to workspace 1–10 |
| `Super+Shift+1–0` | Move focused window to workspace 1–10 |
| `Super+Tab` | Previous workspace |
| `Super+]` / `[` | Next / previous workspace |
| `Super+scroll` | Cycle workspaces with mouse wheel |

### Scratchpad

| Key | Action |
|---|---|
| `Super+\`` | Toggle scratchpad (opens kitty if empty) |
| `Super+Shift+\`` | Move focused window to scratchpad |

### Mouse

| Bind | Action |
|---|---|
| `Super+LMB drag` | Move floating window |
| `Super+RMB drag` | Resize floating window |

### Touchpad Gestures

| Gesture | Action |
|---|---|
| 3-finger swipe left/right | Switch workspace |

---

## Workspace Assignments

Windows are automatically routed to workspaces via `windowrules.conf`:

| Workspace | Apps |
|---|---|
| 1 | Terminals (default) |
| 2 | Firefox, Zen, Chromium, Brave |
| 4 | Signal, Discord/Vesktop, Slack |
| 10 | Spotify, mpv, VLC |
| 11 | HDMI display (pinned to HDMI-A-1) |

Workspaces 1–7 are **persistent** (stay alive when empty). Workspaces 8–10 are on-demand.

---

## Window Float Rules

These windows open floating automatically (`windowrules.conf`):

| Category | Apps / patterns |
|---|---|
| File manager | Dolphin, Thunar, Nemo, Nautilus — centered 900×580 |
| Audio | PulseAudio/pavucontrol — centered 800×500 |
| Network | nm-connection-editor, blueman-manager — centered |
| System dialogs | Save/Open/Print/About/Settings/Properties title patterns |
| File pickers | `xdg-desktop-portal-gtk` — centered 900×600 |
| Calculators | gnome-calculator, kcalc, qalculate-gtk |
| PiP | Pinned 25%×25% at bottom-right, aspect-ratio locked |
| Firefox popups | Sharing indicator, Extension pages, About, Print dialogs |

Press `Super+V` to toggle any floating window back to tiling.

---

## Scripts Reference

All scripts live in `config/hypr/scripts/`. Deployed to `~/.config/hypr/scripts/`.

| Script | Triggered by | What it does |
|---|---|---|
| `smart-focus.sh [l\|r\|u\|d]` | `Super+HJKL` / arrows | `movefocus` with `cyclenext` fallback if no neighbor |
| `smart-movewindow.sh [l\|r\|u\|d]` | `Super+Shift+↑↓` | `movewindow` with `togglesplit` fallback to create vertical splits |
| `toggle-split.sh` | `Super+T` | Toggles split direction state, fires `preselect`, shows OSD |
| `split-dir-daemon.sh` | autostart (`exec-once`) | Watches socket, re-applies preselect after every new window |
| `kb-brightness.sh` | Fn brightness keys | Keyboard backlight: off→low→mid→high→off cycle |
| `kb-cycle.sh` | Fn key | Keyboard layout cycle |
| `hdmi-hotplug.sh` | autostart | Monitors HDMI connect/disconnect, moves workspace 11 |
| `screenshot.sh` | `Super+S` | Interactive region screenshot to file + clipboard |

---

## Autostart Services (`autostart.conf`)

| Service | What |
|---|---|
| `polkit-gnome` | Authentication agent for sudo GUI prompts |
| `dbus-update-activation-environment` | Exports Wayland env to DBus/systemd |
| `mako` | Notification daemon |
| `wl-paste + cliphist` | Clipboard history (text + images) |
| `hypridle` | Idle detection → lock → sleep chain |
| `hyprpaper` | Wallpaper |
| `waybar` | Status bar |
| `nm-applet` | Network manager tray |
| `swayosd-server` | OSD server for volume/brightness/caps feedback |
| `hdmi-hotplug.sh` | HDMI monitor hotplug handler |
| `split-dir-daemon.sh` | Persistent split direction enforcer |

---

## Idle / Lock Chain

| Trigger | Action |
|---|---|
| 5 min idle | Hyprlock (screen lock) |
| 5.5 min idle | Display off (DPMS) |
| 15 min idle | Suspend |
| Lid close | Suspend immediately (logind) |
| Docked + lid close | No suspend (external display keeps it awake) |

Manual lock: `Super+L` or `loginctl lock-session`

---

## Config File Map

```
~/.config/hypr/
├── hyprland.conf              — sources all conf.d/ modules
├── conf.d/
│   ├── look.conf              — gaps, borders, blur, dwindle/master settings
│   ├── keybinds.conf          — all key bindings
│   ├── windowrules.conf       — float rules, workspace assignments, opacity
│   ├── autostart.conf         — exec-once / exec services
│   ├── animations.conf        — animation curves and speeds
│   ├── input.conf             — keyboard, mouse, touchpad, gestures
│   ├── monitors.conf          — display configuration
│   ├── workspaces.conf        — persistent workspaces, HDMI workspace
│   ├── env.conf               — environment variables for Wayland session
│   └── functionkeys.conf      — Fn key / media key bindings
├── scripts/                   — helper scripts (see Scripts Reference above)
├── hyprlock.conf              — lock screen appearance
├── hypridle.conf              — idle timeouts
└── hyprpaper.conf             — wallpaper paths
```

Source of truth for all files: `RaBbLE-OS/config/hypr/` in the RaBbLE-OS repo.
Changes go to the repo first, then deployed via `dotctl`.
