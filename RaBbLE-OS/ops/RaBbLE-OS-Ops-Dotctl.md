# RaBbLE-OS-Ops-Dotctl.md — dotctl Reference

`RaBbLE-OS-dotctl.sh` — deploy and manage dotfile symlinks from `config/` to `~/.config/`.

## Commands

| Command | What |
|---------|------|
| `apply [bundle\|all]` | Symlink repo config → `~/.config/` |
| `pull BUNDLE` | Copy live `~/.config/` → repo (recovery — review before commit) |
| `status [bundle\|all]` | Show in-sync / drifted / missing per file |
| `diff [bundle\|all]` | Line diff: repo vs deployed |
| `reload [bundle\|all]` | Reload the running service (hyprctl reload, systemctl --user restart, etc.) |
| `list` | List all known bundles |

## Known Bundles

`hypr` · `waybar` · `kitty` · `fuzzel` · `zsh` · `bash` · `mako` · `wallpapers` · `claude` · `firefox`
(full list: `./RaBbLE-OS-dotctl.sh list`)

**`firefox` (S236):** `config/firefox/` mirrors the profile layout (`user.js`, `chrome/*.css`).
The CSS files are **symlinks into `RaBbLE-Aether/themes/firefox/`**, so Aether stays the single
source: edit there, then `dotctl apply firefox` and fully restart Firefox. The destination is
resolved at runtime from `profiles.ini` (`[Install*] Default=`, else newest `*.default-release`).
If there's no profile yet, dotctl skips the bundle. `apps/tasks/browsers.yml` reads the same tree at install time.
dotctl now follows symlinks under `config/` in every bundle, and a dangling one (e.g. Aether not
cloned) is warned about and skipped.

Firefox 153 gotcha: `::part()` rules in `userChrome.css` never match popup internals.
Theme popups via inherited host variables instead: `--panel-background-color`,
`--panel-text-color`, and `--content-select-background-image` for `<select>` lists.

## Config Flow Rule

> **Never edit `~/.config/` directly.** Edit `config/` → deploy via dotctl.

If live config has drifted:
```bash
./RaBbLE-OS-dotctl.sh diff hypr     # see what drifted
./RaBbLE-OS-dotctl.sh pull hypr     # recover to repo, then review + commit
```

→ `ops/RaBbLE-OS-Ops-ConfigFlow.md` — full symlink map + HiDPI template flow
→ `ops/RaBbLE-OS-Ops-Layerctl.sh` — Ansible layer apply (system packages/config)
