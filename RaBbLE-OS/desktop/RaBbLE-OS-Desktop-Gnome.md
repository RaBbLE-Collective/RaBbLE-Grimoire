# RaBbLE-OS — GNOME Shell (opt-in secondary DE)

```
spark ~ desktop/gnome >> opt-in GNOME layer scaffolded, SDDM-only, zero extensions // %GNOME_LAYER_SCAFFOLDED%
```

> Reference for the `layer/gnome` Ansible role. Opt-in, exploratory R&D — not a committed
> ship target. Decided S140, implementation started per
> `RaBbLE-OS-Roadmap.md` bucket E.

---

## Purpose & Scope

RaBbLE-OS ships one primary desktop — Hyprland. GNOME exists alongside it, opt-in, for
three reasons:

1. **A simpler fallback DE** for when Hyprland is misbehaving.
2. **An approachable entry point** for non-tiling-WM users.
3. **A deterministic testbed for GTK3/4 theming** — the weakest-themed surface per
   `RaBbLE-OS-Desktop-Theming.md`'s maturity table. Findings here should feed the
   deterministic theming plan (Roadmap bucket D), not fork it.

Hard constraints, decided with Mark before implementation:

- **SDDM stays the only display manager.** No GDM install/enable, ever. SDDM already lists
  any Wayland session `.desktop` file it finds — GNOME just needs one to exist.
- **"macOS-lean" feel = simplicity + a top bar only** (GNOME already has this natively) —
  explicitly NOT visual reskinning. No dock, no Spotlight clone, no shell extensions.
- **Zero GNOME Shell extensions.** Stock vanilla GNOME Shell. Only GTK3/4 + icon + cursor
  theming, reusing already-authored Aether assets — never inventing new hex values.

---

## Enabling / Disabling

```bash
bash RaBbLE-OS-layerctl.sh apply gnome     # installs + themes
bash RaBbLE-OS-layerctl.sh status          # shows gnome verified (LAYER_VERIFY)
bash RaBbLE-OS-layerctl.sh remove gnome    # uninstalls, reverts theme/dconf/tracker-mask
```

Gated by `rabble_enable_gnome_desktop` (default `false`, `ansible/inventory/group_vars/all.yml`)
— never installed by `apply all` / `upgrade`. Role: `ansible/roles/layer/gnome/`.

`layerctl remove <layer>` now also passes `LAYER_EXTRA_VARS` (a small fix to `cmd_remove` in
`RaBbLE-OS-layerctl.sh` made alongside this layer) — without it, any opt-in role gated by a
`when: rabble_enable_*` on the role itself never runs during removal either, silently
no-opping. This was a latent gap affecting `bottles` and `containers` too, not gnome-specific.

**Tag gotcha (verified empirically, not assumed):** Ansible applies a play's own `tags:` to
*every* task inside that play, regardless of the task's own tags — so tagging `remove.yml`'s
tasks `[remove]` alone does not stop them matching a plain `apply gnome` run (`--tags gnome`),
since they're still inside the play tagged `[layer, gnome]`. Fixed by gating the `remove.yml`
include on `when: "'remove' in ansible_run_tags"` — the literal `--tags` value passed on the
CLI — rather than on tag membership. `apply gnome` runs packages+theme only; `remove gnome`
runs packages+theme (idempotent reconcile) then remove.

---

## Packages

| Package | Why |
|---|---|
| `gnome-shell` | Compositor + core desktop |
| `gnome-session` | Session management (ships no session files itself) |
| `gnome-session-wayland-session` | **Load-bearing.** Provides `/usr/share/wayland-sessions/gnome.desktop` — the file SDDM needs. Omitting it produces a GNOME install invisible to SDDM. |
| `gnome-control-center` | Settings app |
| `nautilus` | Files |
| `gnome-terminal` | Stock terminal fallback alongside kitty |
| `gnome-tweaks` | GTK theme/font/cursor switcher — QoL for theming iteration |

**Never `@gnome-desktop` / `@gnome-desktop-environment` (the DNF group).** `dnf group info
GNOME` lists `gdm` as a **Mandatory** member — installing the group would install and
potentially activate GDM, fighting SDDM for `display-manager.service`. All packages above are
named explicitly for this reason. Verified: nothing in the `gnome-shell` → `gnome-session` →
`gnome-control-center` / `nautilus` / `gnome-terminal` / `gnome-tweaks` dependency chain pulls
the `gdm` daemon package (only the harmless `gdm-libs` shared library).

**Trimmed by default:** `nautilus` pulls in `tracker3`/`tracker3-miners`, GNOME's background
file-indexing daemon (`tracker-miner-fs-3`). The role masks it system-wide (all users, not
just the current one) via `/etc/systemd/user/tracker-miner-fs-3.service` → `/dev/null` — a
tiling-WM daily-driver's fallback DE shouldn't run a continuous indexer by default. Nautilus
still works; search just isn't live-indexed. Unmask: delete that symlink + `systemctl --user
daemon-reload`.

---

## Theming Mechanism — Additive to dotctl

Mark's Hyprland account already gets Aether GTK theming **per-user** via
`ansible/roles/apps/tasks/qt-gtk-theme.yml` (deploys to `~/.local/share/themes`,
`~/.config/gtk-{3,4}.0`, sets `gsettings` against his session bus) and `RaBbLE-OS-dotctl.sh`.
That path is unchanged.

`layer/gnome` adds a **system-wide** path so any fresh account gets the Aether look with
zero manual steps — the "standard install path" goal:

| Mechanism | Target | Source |
|---|---|---|
| GTK3/4 theme files | `/usr/share/themes/RaBbLE-Aether/` | `{{ aether_repo_root }}/themes/gtk{3,4}/` — same source `qt-gtk-theme.yml` uses, reused not re-copied |
| dconf system defaults | `/etc/dconf/db/local.d/01-rabble-aether` | `templates/01-rabble-aether.j2` |
| Icon tint | `/usr/share/icons/Papirus-Dark` (root) | `papirus-folders --color magenta` |

dconf defaults set:

```ini
[org/gnome/desktop/interface]
gtk-theme='RaBbLE-Aether'
icon-theme='Papirus-Dark'
cursor-theme='Adwaita'
color-scheme='prefer-dark'
font-name='Exo 2 10'
```

Left **unlocked** (no `/etc/dconf/db/local.d/locks/` entry) — these are defaults for new
accounts, not enforced policy, so GNOME Tweaks / manual iteration during theming work isn't
fought. `/etc/dconf/profile/user` already exists on stock Fedora; the role only adds the
`.d` file and runs `dconf update`.

**Cursor is `Adwaita`, not `Bibata-Modern-Classic`.** Hyprland's use of Bibata turns out to be
a manual, undocumented install inherited from RaBbLE-OS's old Fedora-Sway-spin base — no
Fedora package and no Ansible task installs Bibata's actual cursor files anywhere in this
repo today. Shipping it as a GNOME system default would silently break on any account that
doesn't happen to have it. Adwaita (stock, always present) is the correct baseline until
Bibata is Ansible-managed system-wide as a separate, shared follow-up (would benefit
Hyprland too).

**Known remnant on removal:** `layerctl remove gnome` does not revert the system Papirus
tint — it's cosmetic-only and harmless. `sudo dnf reinstall papirus-icon-theme` restores
stock icons if desired.

---

## Verification Checklist

Run via `RaBbLE-OS-vmctl.sh` on `generic_x64` — SDDM is shared infrastructure both DEs
depend on, snapshot first.

1. `layerctl apply gnome`.
2. `rpm -q gdm` → not installed. `readlink -f /etc/systemd/system/display-manager.service` →
   still `sddm.service`. `systemctl is-active sddm` → active.
3. `test -f /usr/share/wayland-sessions/gnome.desktop` → exists. SDDM greeter lists both a
   Hyprland and a GNOME entry.
4. Log into GNOME: top bar only, `gnome-extensions list` → empty, Nautilus/Terminal already
   Aether-styled (magenta/void-dark, Papirus-Dark magenta folders, Adwaita cursor) with
   **zero manual `gsettings` commands**. `systemctl --user is-active tracker-miner-fs-3` →
   masked.
5. `dconf read /org/gnome/desktop/interface/gtk-theme` on a brand-new never-logged-in test
   account → confirms the value comes from the system db, not a leftover user override.
6. Regression check: log out, boot Hyprland instead — Waybar/hyprctl still work, and a
   portal-dependent action (screenshot via grim/slurp) still routes correctly (confirms
   `xdg-desktop-portal-gnome`, a hard dep of `gnome-shell`, didn't hijack Hyprland's portal).
7. `layerctl status` → `gnome` verified.
8. `layerctl remove gnome` → packages gone, theme dir + dconf file removed, tracker-miner
   unmasked, SDDM/Hyprland unaffected.

---

→ `RaBbLE-OS-Desktop-Theming.md` — Aether theming system, GTK/Qt maturity status
→ `../layers/RaBbLE-OS-Layer-Desktop.md` — desktop layer role state
→ `../RaBbLE-OS-Roadmap.md` — bucket E, exploratory R&D framing
→ `ansible/roles/layer/gnome/` (RaBbLE-OS repo) — role source
