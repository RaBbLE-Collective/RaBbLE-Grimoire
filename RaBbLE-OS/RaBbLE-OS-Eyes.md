# RaBbLE-OS: Eyes (`rabble-eyes`)

```
spark ~ os/eyes >> sight without touch // %S334_EYES%
```

Window capture for agents. It gives RaBbLE a view of any window on Mark's desktop without moving focus, raising, typing, resizing or otherwise changing the session. Ruling: `log/DECISIONS.md` "S334 rulings". Tool: `RaBbLE-OS/spells/rabble-eyes` (Python 3, stdlib only). Tests: `RaBbLE-OS/spells/test-rabble-eyes.py`.

## Usage

```bash
rabble-eyes list [--json]          # id, app_id, title, workspace, visible/focused, denied
rabble-eyes shot <id|app_id|title-substring> [--out DIR] [--json] [--probe] [--fresh]
```

- `shot` writes a PNG to `/tmp/rabble-eyes/` (mode 0700) by default and prints the path. Read the PNG with an image-capable tool.
- Match order: exact id, then exact app_id, then title substring (case-insensitive). Ambiguity is an error that lists candidates; retry with the id.
- `--probe`: two captures about 0.5 s apart. Prints `changing` or `unchanged (may be stale or static)`.
- `--fresh`: for windows that are NOT visible only. Nudges the width by 1px and back, then captures, to force a redraw. Refuses visible windows. Never changes focus. **Implemented and unit-tested against a fake backend, never run on the live session.**

Agent guidance: `list` first, `shot` by id. Use `--probe` when an image looks old. A hidden window may be stale because clients stop redrawing without frame callbacks; try `--fresh` only if a stale image matters.

## Compositor support

| Compositor | list | shot | Status |
|---|---|---|---|
| niri 26.04 | `niri msg --json windows/workspaces` | `niri msg action screenshot-window --id N --path P` | **Verified live** (S334): list, shot, probe, clipboard restore, deny refusal |
| Hyprland 0.57 | `hyprctl -j clients/monitors` | `grim -T <identifier>`, else `grim -g` geometry (visible only) | **UNVERIFIED**: not running, not tested |

Hyprland open question: `hyprctl -j clients` is not known to expose the `ext_foreign_toplevel_list_v1` identifier that `grim -T` needs, and no Python Wayland binding, `lswt` or `wlrctl` is installed to enumerate toplevels. The backend uses an identifier field if the client JSON carries one, else falls back to `grim -g "x,y wxh"`, which captures whatever is on screen in that rectangle (overlapping windows included) and cannot see hidden windows. Resolving it needs a tiny Wayland client binding ext-foreign-toplevel-list and matching by title and app_id. Never test this with a nested compositor window on Mark's desktop.

## Quirks

- niri `screenshot-window` always copies the image to the clipboard. The tool saves every readable clipboard type first and restores afterwards. `wl-copy` sets one MIME type, so a rich clipboard (image plus text, say) is restored as its text form only, and the tool reports what was lost. An empty clipboard is cleared again. Verified: known text before equals after. A clipboard-history daemon (cliphist and the like) may still record the screenshot.
- niri 26.04 reports `tile_pos_in_workspace_view` as null even for the focused window, so offscreen columns cannot be told apart from visible ones. `visible` therefore means "on an active workspace". This errs safe: `--fresh` refuses all of them.
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
