# RaBbLE-OS: Eyes (`rabble-eyes`)

```
spark ~ os/eyes >> sight without touch // %S334_EYES%
```

Window capture for agents. It gives RaBbLE a view of any window on Mark's desktop without moving focus, raising, typing, resizing or otherwise changing the session. Ruling: `log/DECISIONS.md` "S334 rulings". Tool: `RaBbLE-OS/spells/rabble-eyes` (Python 3, stdlib only). Tests: `RaBbLE-OS/spells/test-rabble-eyes.py`.

## Usage

```bash
rabble-eyes list [--json]          # id, app_id, title, workspace, visible/focused, denied
rabble-eyes map [--json]           # outputs -> workspaces -> columns/rows: what is where, what is on screen
rabble-eyes shot <id|app_id|title-substring> [--out DIR] [--json] [--probe] [--fresh]
```

- `shot` writes a PNG to `/tmp/rabble-eyes/` (mode 0700) by default and prints the path. Read the PNG with an image-capable tool.
- Match order: exact id, then exact app_id, then title substring (case-insensitive). Ambiguity is an error that lists candidates; retry with the id.
- `--probe`: two captures about 0.5 s apart. Prints `changing` or `unchanged (may be stale or static)`.
- `--fresh`: for windows that are NOT visible only. Nudges the width by 1px and back, then captures, to force a redraw. Refuses visible windows. Never changes focus. Re-applies maximized-to-edges afterwards (the resize drops it). **Live-verified on niri S334:** off-screen Dolphin (maximized to edges) and Firefox (full-width column) came back at their exact sizes, focus and clipboard unchanged. Hyprland: untested.

Agent guidance: `map` first when placement matters (which workspace holds what, column order, which window is on screen, sizes, maximized-to-edges; denied titles redacted), `list` for a flat view, then `shot` by id. On niri, columns run left to right on a scrolling strip and rows stack inside a column; on Hyprland `map` gives absolute `at` coordinates instead of columns (unverified). Use `--probe` when an image looks old. On niri a plain capture of an off-screen window was already current (S334: `--probe` reported changing on off-screen Dolphin and Firefox with no nudge), so `--fresh` is rarely needed there. Use it only when `--probe` says unchanged and the content should have moved.

## Compositor support

| Compositor | list | shot | Status |
|---|---|---|---|
| niri 26.04 | `niri msg --json windows/workspaces` | `niri msg action screenshot-window --id N --path P` | **Verified live** (S334): list, shot, probe, clipboard restore, deny refusal |
| Hyprland 0.57 | `hyprctl -j clients/monitors` | `grim -T <identifier>`, else `grim -g` geometry (visible only) | **UNVERIFIED**: not running, not tested |

Hyprland open question: `hyprctl -j clients` is not known to expose the `ext_foreign_toplevel_list_v1` identifier that `grim -T` needs, and no Python Wayland binding, `lswt` or `wlrctl` is installed to enumerate toplevels. The backend uses an identifier field if the client JSON carries one, else falls back to `grim -g "x,y wxh"`, which captures whatever is on screen in that rectangle (overlapping windows included) and cannot see hidden windows. Resolving it needs a tiny Wayland client binding ext-foreign-toplevel-list and matching by title and app_id. Never test this with a nested compositor window on Mark's desktop.

## Quirks

- niri `screenshot-window` always copies the image to the clipboard. The tool saves every readable clipboard type first and restores afterwards. `wl-copy` sets one MIME type, so a rich clipboard (image plus text, say) is restored as its text form only, and the tool reports what was lost. An empty clipboard is cleared again. Verified: known text before equals after. A clipboard-history daemon (cliphist and the like) may still record the screenshot.
- niri 26.04 reports `tile_pos_in_workspace_view` as null, so visibility is inferred: a window is off screen when its workspace is inactive, or when the workspace's active window fills the output width and the window sits in another column. Anything not provable off screen stays `visible`, which `--fresh` refuses.
- Hidden or offscreen windows can be stale until they redraw.
- Captures are full window contents at native size, including anything sensitive that is not on the deny list. Treat the PNGs as private; they live in `/tmp`.

## Privacy policy

Mark's ruling: password managers, private browsing and banking are never captured, with an editable list and no override.

- Rules: `RaBbLE-OS/config/RaBbLE/eyes-deny.conf`. One per line, `app:<regex>` or `title:<regex>`, case-insensitive, `#` comments. `~/.config/RaBbLE/eyes-deny.conf` wins if deployed (via dotctl, not yet wired); otherwise the repo copy beside the tool is read.
- `list` shows denied windows with the title replaced by `[redacted]` (app_id stays).
- `shot` on a denied window exits non-zero with a refusal. There is no flag to override it.
- Denied windows match queries by id or app_id only, never by title, so a title search cannot probe their contents.
- A missing or unparseable deny file refuses everything (fail closed).
- Title rules are keyword based and will over-match (any title with "bank") and can under-match (a banking site whose tab title lacks the keywords). Add rules as needed.

## Clipboard

niri's `screenshot-window` always copies the shot to the clipboard. `shot` saves the clipboard first and restores it straight after, so the net effect is none for plain text (verified S334). A clipboard holding several MIME types comes back as one type (`wl-copy` sets one); the tool reports that in `clipboard_note`. Hyprland's `grim -T` path never touches the clipboard.

## Still to test (S334)

| What | Status | How to test |
|---|---|---|
| Hyprland backend: `list`, `map`, `shot` | Unverified, Hyprland not running | Log into Hyprland, run `rabble-eyes map` and `shot` on a window on another workspace |
| Hyprland toplevel id for `grim -T` | Open: `hyprctl clients` exposes no ext-foreign-toplevel identifier | Check whether hyprctl gains one, else a small Wayland client lists ext-foreign-toplevel-list; until then off-screen Hyprland windows cannot be captured |
| Hyprland `--fresh` (`resizewindowpixel`) | Commands unit-tested only | On an off-screen window, compare size before/after |
| A live denied window | Unit-tested only | Open KeePassXC or a Private Browsing window; `list` shows `[redacted]`, `shot` refuses |
| Rich clipboard restore | Text verified; multi-type degrades to one type | **Planned (Mark asked S334):** replace the `wl-copy` restore with a small stdlib-Python Wayland client on `zwlr_data_control_manager_v1` (niri offers it) that re-offers every saved MIME type and serves each on request (fd passing via `socket.recvmsg`). Test: copy rich text from Firefox, `shot`, paste into LibreOffice and a terminal |
| niri visibility with narrow columns | Safe fallback (stays `visible`) when the active column is not full width | Two half-width columns on screen plus one off screen; `map` marks the off-screen one `visible` (conservative) |
| Multi-monitor `map` | Laptop panel only | Plug a monitor, check outputs and workspaces group correctly |
| Deploy via dotctl | Not wired; runs from `RaBbLE-OS/spells/` | Add to dotctl when the OS session is free |
