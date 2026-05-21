# RaBbLE-OS-AgentGuide.md — Agent Entry Point

```
transcribe ~ substrate >> agent guide rewritten — current-state only // %S34%
```

> **First time here?** Read `Architecture.md` next — layer model and role tree.
> **Returning?** Check `Roadmap.md` → Episode 1 status and Phase 1 stub blockers.

---

## What is RaBbLE-OS?

Ansible-driven Fedora 43 + Hyprland desktop. The substrate — the body the entity inhabits.
Reproducible from bare metal via Kickstart + Ansible. Mark's daily driver.

**Active branch:** `RaBbLE-OS-New-Horizons` — all current work.

---

## Layer Model

| Layer | Tag | What | Status |
|-------|-----|------|--------|
| 0 | `base` | Core packages, repos, locale, fonts | stub → Phase 1 priority |
| 1 | `hardware` | GPU drivers, power management, platform quirks | scaffold only |
| 2 | `boot` | GRUB2 → Plymouth → SDDM | partial (stubs remain) |
| 3 | `desktop` | Hyprland, Waybar, terminal, shell, notifications | deployable |
| 4 | `apps` | Dev tools, browsers | partial |
| 5 | `entity` | RaBbLE AI layer | future |

---

## Key Operations

```bash
# Full system deploy
./RaBbLE-OS-layerctl.sh apply all

# One layer
./RaBbLE-OS-layerctl.sh apply desktop

# Scope to packages or config only
./RaBbLE-OS-layerctl.sh apply desktop --packages
./RaBbLE-OS-layerctl.sh apply desktop --config

# Dry-run / diff
./RaBbLE-OS-layerctl.sh apply desktop --check
./RaBbLE-OS-layerctl.sh diff desktop

# Show layer state
./RaBbLE-OS-layerctl.sh status

# Deploy dotfile symlinks
./RaBbLE-OS-dotctl.sh apply all
```

Hardware profile override: `RABBLE_HARDWARE=generic_x64 ./RaBbLE-OS-layerctl.sh apply hardware`

---

## Config Flow

All user configs live in `config/` and are symlinked by Ansible into `~/.config/`.
Edit the repo file — `dotctl apply all` deploys the symlinks.
Machine-specific values (monitor res, HiDPI scale) live in
`ansible/inventory/group_vars/asus_proart_p16.yml` and propagate via Ansible templates.

Full symlink map and template map → `Reference.md`.

---

## Key Files

| File | What |
|------|------|
| `RaBbLE-OS-Install.sh` | First-contact — installs git/ansible, clones repo, calls Bootstrap |
| `RaBbLE-OS-Bootstrap.sh` | Ansible runner — called by Install or directly |
| `RaBbLE-OS-layerctl.sh` | Layer apply/remove/verify/status |
| `RaBbLE-OS-dotctl.sh` | Dotfile symlink deploy |
| `RaBbLE-OS-vmctl.sh` | VM lifecycle: cast/start/stop/snapshot/restore |
| `ansible/site.yml` | Master playbook |
| `ansible/inventory/hosts.yml` | Host-to-hardware-profile mapping |
| `ansible/packages/manifest.yml` | Canonical package list (59 packages, `reason:` per entry) |

---

## Branch Conventions

| Branch | Purpose |
|--------|---------|
| `RaBbLE-OS-New-Horizons` | Active daily-driver work |
| `RaBbLE/episode-I` | Episode 1 staging — PR target from New Horizons |
| `fix/<target>` | Hardware/stability fix — one system, one issue |
| `main` | Solidified episodes only — always clean and tagged |

Commit format: `[impulse] ~ [organ] >> [revelation] // %STATE%`
See `RaBbLE-Agent/RaBbLE-CommitStyle.md` for full Pulse Protocol.

---

## Reading Order

| # | File | Tokens | When |
|---|------|--------|------|
| 1 | **AgentGuide.md** (this) | ~400 | Always first |
| 2 | **Architecture.md** | ~800 | Always — layer model, role tree |
| 3 | **Roadmap.md** | ~600 | Always — episode status, what's next |
| 4 | **KnownIssues.md** | ~300 | Before any implementation |
| 5 | **Theming.md** | ~700 | When touching palette or theme |
| 6 | **Reference.md** | ~700 | When you need symlink map, HiDPI, GPU detail |
| 7 | **Checklists.md** | ~500 | When testing or landing an episode |

Tier 1 (files 1–3): ~1,800 tokens total.
