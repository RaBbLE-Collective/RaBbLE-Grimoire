# Plan: RaBbLE-OS Editions (core / user / dev / creative / full) + disk and backup actions

**Status:** 🔵 DESIGN (S283, 2026-10-27). Not started. D1 to D5 decided, D6 deferred; ready for W1. Not yet Opus-reviewed.
**Repo:** RaBbLE-OS `new-horizons` · **Goal:** sort every package into an edition, make the installer pick an edition, and get the daily driver back to a healthy disk with a real backup.

Audience (Mark, 2026-10-27): RaBbLE is a slate for creatives and developers looking for a new path. That is why dev and creative are first-class editions and not add-on layers.

Naming: "edition", not "profile". `profile` already means theming profiles (OS-Theming-Variants-Plan), `boot-profile.sh`, and power profiles.

---

## Part A. Why now: disk and backup findings (2026-10-27)

Root `/` is 222G btrfs, 171G used, 49G free (78%). `/mnt/vms` is a separate 32G partition (19G qcow2 images, rebuildable from the KS).

| Item | Size | Note |
|---|---|---|
| `~/Dropbox` | 52G | Separate btrfs subvolume, so `du -x` skips it. Partial local copy of ~432G. maestral daemon NOT running, sync state unverified. |
| `~/.espressif` + `~/esp` + `~/.arduino15` | 23.5G | ESP-IDF toolchains, 1.9G of dist, 1.6G arduino staging. |
| podman images | 7.5G | 111 images, 100% reclaimable. |
| Caches (`.cache`, `.npm`) | 16.4G | playwright 2.5, uv 2.4, firefox 1.6, npm 7.1. |
| Flatpak | ~10G | 8.3G system + 1.6G user. Bottles 2.5G. |
| `RaBbLE-Collective` | 14G | Pocket 4.9, OS 4.6 (ISOs), BaBbLE 3.4. |
| `RaBbLE-Cleanroom` + `Incenergy` | 6.2G | Cleanroom is not a git repo. |
| `/usr` + `/var` + `/opt` | 35G | /opt: llama.cpp 1.6G, src 2.3G, xilinx. Journal 1.4G. |

No snapper config exists on this machine (`sudo snapper list` says config `root` does not exist), so the snapper role is not applied here.

### Actions: reclaim space (about 20 to 25G, none touch Dropbox)

```bash
podman system prune -a                       # 7.5G, all images unused
npm cache clean --force                      # up to 7.1G
uv cache clean                               # 2.4G
rm -rf ~/.cache/ms-playwright                # 2.5G, re-downloads on demand
rm -rf ~/.arduino15/staging                  # 1.6G
flatpak uninstall --unused
sudo journalctl --vacuum-size=200M           # about 1.2G
sudo dnf clean all
```

Then, with the daemon running, shrink Dropbox on disk:

```bash
maestral start && maestral status            # must say "Up to date" first
maestral excluded add <folder>               # local copy removed, cloud copy kept
```

### Actions: backup (target: Dropbox + the Collective + external disk)

1. Give these remotes: `Incenergy` (154 unpushed), `RaBbLE-BaBbLE` (59), `ATLAS-next` (10). Push `Jobotron3000` (7) and `RaBbLE-Pocket` (2). Commit or stash the 32 dirty Grimoire files.
2. Put non-git directories under backup: `RaBbLE-Cleanroom` (3.9G), `FreelanceWebDev`, `esp`.
3. Add an Ansible role `backup` (restic or borg, systemd timer, udev/automount trigger for the external disk). Scope: `~/Dropbox`, `~/RaBbLE-*`, the non-git dirs, `~/.config`, secrets (age-encrypted), Personal Grimoire.
4. Add a `backup verify` spell: restores one random file and compares checksums.

---

## Part B. Editions

### Locked shape

```
core  ⊂  user  ⊂  dev      ⊂  full
              ⊂  creative  ⊂  full
```

| Edition | Meaning | Contents |
|---|---|---|
| **core** | Bare, minimal RaBbLE-OS | ks-bootstrap, base, core.*, hardware (platform filtered), boot chain, snapper, shell (zsh), fastfetch, dotctl and layerctl. No GUI apps. |
| **user** | Standard general-purpose distro | core + apps.* (files, media, theming, browser), flatpak, bluetooth, nightmode, printing, office, GNOME fallback session. |
| **dev** | user + engineering | containers, VS Code, dotnet-sdk, esp-idf, arduino-cli, atlas-sentry, virtualization, ai-harnesses, collective tooling, runtime (llama.cpp), monitoring. |
| **creative** | user + making things | creator-apps (FreeCAD etc.), bottles, full codecs, 2D/3D/audio/video apps, extra fonts. |
| **full** | Everything (TBD, Mark 2026-10-27) | dev + creative. May also ship both compositor sessions (Hyprland and Sway) selectable at the SDDM login screen. Exact contents not decided. |

Platform stays an orthogonal axis (`all | asus_proart_p16 | generic_x64`). Edition x platform is the install matrix.

### Open decisions (Mark's calls)

- **D1. DECIDED (Mark, 2026-10-27): core includes a graphical session, Hyprland for now.** Minimal session + terminal + launcher, no apps. Mark may later move core to Sway and keep Hyprland in user, once Quickshell is built (see D6).
- **D2. DECIDED (Mark, 2026-10-27): `layer/gnome` may go in user** (fallback session in the standard edition). "Might", so treat as provisional: put it in user, revisit if the user edition gets too heavy.
- **D3. DECIDED (Mark, 2026-10-27): `user` is the default.** Used for unattended installs with no `rabble.edition=`. Interactive installs show the chooser.
- **D4. DECIDED (Mark, 2026-10-27): downgrading an edition is not supported.** It stays possible by removing packages by hand. No prune tooling. `layerctl edition set` only goes up and refuses to go down, printing a one-line pointer to manual removal.
- **D5. DECIDED (Mark, 2026-10-27): one ISO.** Edition is chosen at install time (kernel command line `rabble.edition=`, plus an interactive chooser). `build-iso.sh --edition X` stays as an optional bake-in for VM testing.

- **D6. DEFERRED (Mark, 2026-10-27): Hyprland is working for him right now.** Revisit when Quickshell is built or Hyprland breaks again. Original notes follow; the `rabble_compositors` list and the stability items still apply.
  Compositor swap (raised by Mark, 2026-10-27). Hyprland updates keep breaking things. Possible end state: core ships Sway, user ships Hyprland (user then carries both), after Quickshell is built. Recommended handling:
  1. Make the compositor a list variable (`rabble_compositors: [hyprland]`, first entry is the default session) with per-edition defaults, so editions never hardcode a compositor and the swap is a defaults change. A list also covers `full` shipping both: SDDM shows every session installed under `/usr/share/wayland-sessions`, so "both selectable" needs no extra login machinery, only both stacks installed and both configs deployed by dotctl.
  2. Verify Quickshell runs on both (it has Hyprland and i3/Sway IPC modules; confirm against the actual build) before committing to the swap.
  3. Sway parity work is real: binds, idle/lock (swayidle/swaylock are already installed), screenshot, display manager (`rdisplay` has a Hyprland backend only), dotctl configs for both. Not before Quickshell lands.
  4. Stability now, whatever the decision: 10 compositor-layer packages come from `copr:lionheartp/Hyprland` (a third-party COPR tracking upstream). Pin with `dnf versionlock` on the Hyprland stack, and update it deliberately. Also apply the `snapper` role here: no `root` snapper config exists on this machine, so a breaking update has no rollback. Take a pre-update snapshot in `layerctl upgrade`.

### Manifest changes

Add one field to every entry in `ansible/packages/manifest.yml`:

```yaml
  edition: core | user | dev | creative   # minimum edition that gets it; full gets everything
```

Resolution: `core` in all; `user` in user, dev, creative, full; `dev` in dev, full; `creative` in creative, full.

Current layer to edition (first pass, to be confirmed package by package):

| Manifest layer (count) | Edition |
|---|---|
| ks-bootstrap (4), base (3), core (20), boot (6), hardware (13) | core |
| audio (5), fonts (6), wayland (8), compositor (10), desktop (14) | core (D1 decided) |
| apps (25), layer/flatpak, layer/bluetooth, layer/nightmode | user |
| layer/containers (7), layer/dev (3), layer/dotnet-sdk, layer/esp-idf (20), layer/arduino-cli, layer/atlas-sentry (3), runtime (4) | dev |
| layer/creator-apps (3), layer/bottles (2) | creative |
| layer/gnome (8) | user (D2, provisional) |

### Installer changes (disjoint file ownership)

| Piece | File | Change |
|---|---|---|
| Edition vocabulary | `ansible/inventory/group_vars/all.yml` | Add `rabble_edition` (default per D3) and an `rabble_edition_rank` map. |
| Edition to gates | `ansible/inventory/group_vars/all.yml` | Derive each `rabble_enable_*` from the edition unless explicitly set. |
| Play gating | `ansible/site.yml` | Add `when: rabble_edition_rank[...]` on the Runtime, Monitoring, Virtualization and Layer plays. |
| KS packages | `spells/generate-kickstart.py` | Add `--edition`; filter by the resolution rule. |
| KS runtime | `RaBbLE-OS.ks` | `%pre` reads `rabble.edition=` from `/proc/cmdline`; `RABBLE_TAGS` and `RABBLE_EXTRA_VARS` derive from it (today `RABBLE_TAGS="base,boot,desktop,gnome"` is hardcoded at line 263). |
| ISO | `spells/build-iso.sh` | Add `--edition`. |
| Bootstrap | `RaBbLE-OS-Bootstrap.sh` | Add `--edition`, pass `-e rabble_edition=`. |
| Curl installer | `RaBbLE-OS-Install.sh` | Add `--edition` and a prompt when interactive. |
| Day-two | `RaBbLE-OS-layerctl.sh` | Add `edition status|set <name>` (upgrade only, refuses to go down per D4); `status` shows which edition each layer belongs to. |
| Audit | `spells/edition-audit.sh` (new) | Fails if any manifest entry lacks `edition:`; prints per-edition counts and `dnf --assumeno` size estimates. |

### Sorting the unmanifested packages

Last audit: 438 hand-installed packages, 264 not in the repo. Most are Fedora base or Kickstart group dependencies and should stay out. Add these:

| Tier | Packages |
|---|---|
| core | bat, eza, zoxide, yq, lsof, smartmontools, nvme-cli, compsize, btrfs-progs, ntfs-3g, foot, dunst, wev, wlsunset, swaylock, swayidle |
| user | gparted, xarchiver, libreoffice-writer, cups + gutenprint, gvfs-smb, com.spotify.Client (flatpak) |
| dev | git-lfs, tcpdump, mtr, minicom, python3-scipy, openssh-server, kmod-nvidia (hardware, nvidia platform) |

Not in any role yet: `/opt/llama.cpp`, `/opt/src/*` (FastFlowLM, xdna-driver, xrt_shim), `/opt/xilinx`, `/opt/rabble`, the EIM-managed ESP-IDF install, global npm CLIs (claude-code, gemini, codex, wrangler, railway, opencode, pnpm), pipx apps (aider, awscli), `~/.local/bin` wrappers. Each needs a role task or a "deliberately not managed" line in the manifest header.

---

## Part C. Orchestration (waves)

| Wave | Work | Owner files | Model |
|---|---|---|---|
| W0 | Mark answers D1 to D5 | none | Mark |
| W1 | Add `edition:` to all 160-odd manifest entries; write `edition-audit.sh` | `ansible/packages/manifest.yml`, `spells/edition-audit.sh` | sonnet |
| W2 | Edition vars + site.yml gating | `group_vars/all.yml`, `site.yml` | sonnet |
| W3 | Generator, KS, ISO, Bootstrap, Install, layerctl flags | the six script files above, one agent each | sonnet |
| W4 | Add the unmanifested packages and `/opt` roles | `manifest.yml` (after W1), new roles | sonnet |
| W5 | VM verify per edition via `vmctl`: core, user, dev, creative, full | none (read-only) | haiku to run, Mark to judge |
| W6 | `backup` role | `roles/backup/` | sonnet |

W1 must finish before W4 (same file). W3's six files are disjoint and can run in parallel. Pin `model: "sonnet"` on all fan-out dispatches (see memory: subagent model pinning).

## Part D. Verification

- `edition-audit.sh` exits 0: every package has an edition.
- `generate-kickstart.py --edition core | wc -l` is smaller than user, smaller than dev and creative, smaller than full.
- VM install of `core` boots to a login with no browser installed; `user` has Firefox and office; `dev` has `docker`, `code`, `idf.py`; `creative` has FreeCAD; `full` has all.
- Rerunning `layerctl edition set dev` on a `user` install is idempotent (second run: 0 changed).
- Final `edition: core` size under a target Mark sets (measure first, then fix the target).

## Cold-start handoff

- Branch: RaBbLE-OS `new-horizons`, clean at start of S283. Grimoire has 32 uncommitted files from other sessions: do not commit them with this plan.
- Source of truth: `ansible/packages/manifest.yml` (1633 lines, 160-odd entries, fields name/category/reason/source/platform/layer/ks).
- Current KS flow: `RaBbLE-OS.ks` `%post` clones Collective, Grimoire, OS, then runs Bootstrap with `RABBLE_TAGS="base,boot,desktop,gnome"`.
- Opt-in layers are gated by `rabble_enable_*` vars in `site.yml` (default false).
- ISO: `spells/build-iso.sh` (mkksiso, `#@VM@` markers). Pin hardware variants with the existing platform axis.
- Related: `OS-Theming-Variants-Plan.md` (profiles there are theming), idea GUI installer with custom usernames/DE choice, `OS-VM-Dev-Flow.md` for the VM test loop.
