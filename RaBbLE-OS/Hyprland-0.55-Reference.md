# Hyprland 0.55 Reference — RaBbLE-OS

> Installed version: **0.55.3** (tag `v0.55.3`, commit `fe5fe79a`)
> Config format: legacy hyprlang `.conf` (the new Lua format is optional)
> Source evidence: [`src/config/legacy/ConfigManager.cpp`](https://github.com/hyprwm/Hyprland/blob/v0.55.3/src/config/legacy/ConfigManager.cpp), [`src/desktop/rule/windowRule/WindowRule.cpp`](https://github.com/hyprwm/Hyprland/blob/v0.55.3/src/desktop/rule/windowRule/WindowRule.cpp)

---

## The Big Change in 0.55

Hyprland 0.55 introduced a new **Lua-based config format** (`hyprland.lua`) as the primary path. The old hyprlang `.conf` format is preserved as a "legacy" path. RaBbLE-OS still uses `.conf` files — this is fully supported, but some 0.55 features (like the new `hl.gesture()` Lua API) have richer bindings in Lua.

The key implication: **you may see wiki examples in Lua format** that do not directly map to `.conf` syntax. When in doubt, read the legacy `ConfigManager.cpp` source.

---

## Window Rules — Correct 0.55 Syntax (Legacy .conf)

### Format

```
windowrule = <effect> <value>[, <effect> <value>][, match:<prop> <regex>][, ...]
```

All comma-separated tokens on one line constitute a **single rule** (one `CWindowRule` object). Each token is split on its first space:
- Left side = effect name (e.g. `float`) OR `match:<prop>` (e.g. `match:class`)
- Right side = value/regex

### Valid Match Properties (matchers)

| Matcher | Match Engine | Notes |
|---|---|---|
| `match:class` | RE2 regex | Wayland app-ID or X11 WM_CLASS |
| `match:title` | RE2 regex | Window title |
| `match:initial_class` | RE2 regex | Class at first map |
| `match:initial_title` | RE2 regex | Title at first map |
| `match:modal` | bool | `true`/`false`/`1`/`0` — transient/dialog windows |
| `match:float` | bool | `true` if currently floating |
| `match:xwayland` | bool | `true` for X11-via-XWayland windows |
| `match:fullscreen` | bool | `true` if fullscreened |
| `match:pin` | bool | `true` if pinned |
| `match:focus` | bool | `true` if focused |
| `match:group` | bool | `true` if in a group |
| `match:tag` | tag | tag matcher |
| `match:workspace` | workspace | workspace identifier |
| `match:namespace` | RE2 regex | Layer surface namespace |
| `match:content` | RE2 regex | XDG content type |
| `match:xdg_tag` | RE2 regex | XDG toplevel tag |

### Valid Effect Names (windowrule effects)

Boolean effects (value: `true`/`false`/`1`/`0`):
- `float`, `tile`, `pseudo`, `center`, `pin`, `keep_aspect_ratio`
- `no_initial_focus`, `no_anim`, `no_blur`, `no_dim`, `no_focus`
- `no_follow_mouse`, `no_max_size`, `no_shadow`, `no_shortcuts_inhibit`
- `opaque`, `force_rgbx`, `sync_fullscreen`, `immediate`, `xray`
- `render_unfocused`, `no_screen_share`, `no_vrr`, `confine_pointer`
- `stay_focused`, `persistent_size`, `allows_input`, `dim_around`
- `decorate`, `focus_on_activate`, `nearest_neighbor`

Value effects:
- `size <W> <H>` — expression vec2 (e.g. `900 580` or `80% 80%`)
- `move <X> <Y>` — expression vec2
- `max_size <W> <H>`, `min_size <W> <H>` — expression vec2
- `opacity <active> [inactive]` — float(s)
- `workspace <spec>` — workspace identifier (e.g. `2 silent`)
- `idle_inhibit <mode>` — `none`/`always`/`focus`/`fullscreen`
- `monitor <name>` — monitor name
- `rounding <n>` — integer
- `rounding_power <n>` — float 1–10
- `border_size <n>` — integer
- `border_color <color> [inactive_color]`
- `animation <style>`
- `tag <name>`
- `group <opts>`
- `fullscreen` (bool) / `fullscreen_state <internal> [client]`
- `maximize` (bool)
- `no_close_for <ms>`
- `scrolling_width <factor>`
- `scroll_mouse <factor>`, `scroll_touchpad <factor>`

### Examples

```
# Float + center all modal dialogs (transient/child windows)
windowrule = float true, match:modal true
windowrule = center true, match:modal true

# Float Dolphin, size only the main window (not its dialogs)
windowrule = float true,   match:class ^(org\.kde\.dolphin)$
windowrule = center true,  match:class ^(org\.kde\.dolphin)$
windowrule = size 900 580, match:class ^(org\.kde\.dolphin)$, match:modal false

# Workspace assignment — exclude modals and already-floating windows
windowrule = workspace 2 silent, match:class ^(firefox)$, match:modal false, match:float false

# Opacity with active and inactive values
windowrule = opacity 0.95 0.90, match:class ^(kitty)$

# PiP — multiple effects in one rule
windowrule = float true, pin true, keep_aspect_ratio true, size 25% 25%, move 73% 72%, match:title ^([Pp]icture[-\s]?[Ii]n[-\s]?[Pp]icture)

# Multi-predicate rule (class AND title must both match)
windowrule = float true, match:class ^(kitty)$, match:title ^(termfilechooser)
```

### Rule Application Order

Rules apply in **file order**. ALL matching rules run — last rule wins per effect. Put catch-alls first, specific overrides last.

---

## Layer Rules — Correct 0.55 Syntax

```
layerrule = <effect> <value>, match:<prop> <regex>
```

Valid matchers: primarily `match:namespace` (layer surface namespace).

Valid effects:
- `blur true/false`
- `blur_popups true/false`
- `ignore_alpha <float 0.0-1.0>` — blur ignores pixels below this alpha threshold
- `no_anim true/false`
- `dim_around true/false`
- `xray true/false`
- `animation <style>`
- `order <int>`
- `above_lock 0|1|2`
- `no_screen_share true/false`

Example:
```
layerrule = blur true,        match:namespace fuzzel
layerrule = ignore_alpha 0.0, match:namespace notifications
```

---

## Workspace Rules — Correct 0.55 Syntax

Keyword: `workspace` (NOT `workspacerule` — that keyword does not exist).

```
workspace = <id>, <key>:<value>[, <key>:<value>, ...]
```

Keys: `persistent:0|1`, `monitor:NAME`, `default:0|1`, `defaultName:NAME`, `on-created-empty:<cmd>` (hyphen, not underscore), `gapsin:N`, `gapsout:N`, `bordersize:N`, `border:0|1`, `shadow:0|1`, `rounding:0|1`, `decorate:0|1`, `layout:NAME`, `animation:STYLE`.

```
workspace = 1, persistent:1
workspace = 11, monitor:HDMI-A-1, persistent:1, defaultName:hdmi
workspace = special:scratchpad, on-created-empty:kitty
```

---

## Gesture Syntax — 0.55 Change

In 0.55, `gesture` is a **top-level keyword handler**, NOT a subkey inside a `gestures {}` block. The old `gestures { workspace_swipe_* }` subkeys are removed.

```
# CORRECT — top-level keyword
gesture = 3, horizontal, workspace

# WRONG — puts gesture inside old gestures block, silently ignored in 0.55
gestures {
    gesture = 3, horizontal, workspace   # NOT parsed as gesture handler
    workspace_swipe_distance = 300        # key no longer exists in 0.55
}
```

Gesture actions: `workspace`, `special`, `resize`, `move`, `close`, `float`, `fullscreen`, `cursor_zoom`.

---

## windowrulev2 — Deprecated

`windowrulev2` is fully deprecated in 0.55. Using it generates an explicit config error: *"windowrulev2 is deprecated. Correct syntax can be found on the wiki."* Migrate all `windowrulev2` rules to `windowrule` with `match:<prop>` predicates.

---

## Migration Pitfalls Found in This Install

### 1. `workspacerule` keyword (FIXED)

**Symptom:** Workspaces not persisting after empty; workspace-related settings silently dropped.

**Root cause:** `workspacerule` is not a registered handler in 0.55. The correct keyword is `workspace`. Unknown keywords are silently ignored by hyprlang (no config error generated).

**Fix:**
```
# BEFORE (broken — silent no-op)
workspacerule = persistent 1, match:id 1

# AFTER (correct)
workspace = 1, persistent:1
```

### 2. Workspace assignments send dialogs to wrong workspaces (FIXED)

**Symptom:** Popup dialogs (e.g. Firefox save-file dialog, Discord settings) "just don't show up" — they appear on their app's assigned workspace rather than the current one.

**Root cause:** `windowrule = workspace 2 silent, match:class ^(firefox)$` matches ALL firefox windows including child dialogs. A save-file dialog spawned while on workspace 1 is silently sent to workspace 2.

**Fix:** Add `match:modal false, match:float false` to workspace assignments:
```
windowrule = workspace 2 silent, match:class ^(firefox)$, match:modal false, match:float false
```

### 3. Gesture silently not registered (FIXED)

**Symptom:** 3-finger swipe does nothing.

**Root cause:** `gesture = 3, horizontal, workspace` was inside a `gestures {}` block. The `gestures {}` block no longer exists in 0.55; the old `workspace_swipe_*` subkeys are gone. The line was parsed as a config subkey, not the gesture handler.

**Fix:** Move `gesture` to top level (outside any block).

### 4. `match:class`/`float true` syntax — NOT a bug

**Suspected but confirmed valid:** The `match:` prefix for predicates IS valid in 0.55's legacy conf parser. Boolean effects (`float true`, `center true`, `pin true`, etc.) ARE valid — `truthy("true")` returns true in the hyprutils parser.

### 5. Global `size` catch-all scope (REFINED)

**Original:** `windowrule = size 80% 80%, match:class .*` — applied size to ALL windows.

**Problem:** For floating dialogs without specific size rules, this forced an 80% screen size onto them. Specific app rules placed later overrode this for known apps, but unknown dialog windows got sized to 80% which may not match their intended size.

**Fix:** Scoped to `match:float true, match:modal false` so it only applies to explicitly floated non-dialog windows, not transient dialogs.

---

## Gotchas for This Install

1. **`org.kde.dolphin` class** — Dolphin's Wayland app-ID uses dots. RE2 regex `.` matches any char, so `org\.kde\.dolphin` is the correct escaped form. However, `org.kde.dolphin` (unescaped) also works in practice since `.` matching anything is permissive.

2. **Transient dialogs in Qt** — Qt apps (Dolphin, VLC, etc.) create child dialogs with the SAME class as the parent. The `match:modal true` catcher is essential for these to float and stay on the current workspace.

3. **`ignore_alpha 0`** — This parses as float `0.0`, not the integer `0`. Both work but `0.0` is clearer intent.

4. **`size 80% 80%`** — The expression system uses `muParser`. The `%` character in this context is muParser's modulo operator. In the size context, Hyprland defines monitor-width and monitor-height variables so `80%` computes as `80 modulo <height>` which is wrong on most monitors. **This is a latent bug in the original catch-all.** The correct form for percentage sizing in 0.55 is likely `80% * mw` / `80% * mh` with muParser variables, or just use pixel values. The specific app rules with pixel sizes work correctly and override the global rule for all known apps.

5. **`hyprctl configerrors` can be empty even with wrong rules** — Hyprland 0.55 silently ignores: unknown config block subkeys, unknown top-level blocks, and `workspacerule` (an unregistered keyword). Only registered keyword handlers produce errors. Always test behavior empirically, not just via `configerrors`.

6. **RE2 regex engine** — Hyprland uses Google's RE2 library. Perl-style lookaheads (`(?=...)`) are NOT supported. Standard character classes and anchors work normally.
