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

`hypr` · `waybar` · `kitty` · `fuzzel` · `zsh` · `bash` · `mako` · `wallpapers` · `claude`

## Config Flow Rule

> **Never edit `~/.config/` directly.** Edit `config/` → deploy via dotctl.

If live config has drifted:
```bash
./RaBbLE-OS-dotctl.sh diff hypr     # see what drifted
./RaBbLE-OS-dotctl.sh pull hypr     # recover to repo, then review + commit
```

→ `ops/RaBbLE-OS-Ops-ConfigFlow.md` — full symlink map + HiDPI template flow
→ `ops/RaBbLE-OS-Ops-Layerctl.sh` — Ansible layer apply (system packages/config)
