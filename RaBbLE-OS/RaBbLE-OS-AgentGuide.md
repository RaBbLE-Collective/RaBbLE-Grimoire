# RaBbLE-OS-AgentGuide.md — Map

Ansible-driven Fedora 43 + Hyprland desktop. The entity's body.
Active branch: `RaBbLE-OS-New-Horizons`. Key tools: `layerctl.sh` · `dotctl.sh` · `vmctl.sh`.

> **Related:** [Collective Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) · [OS Roadmap](RaBbLE-OS-Roadmap.md) · [Integration Map](../RaBbLE-Agent/RaBbLE-Integration-Map.md)

---

## Directory Tree

```
layers/         Ansible layer docs — what each layer is and its current state
hardware/       Hardware profiles — ProArt P16, generic x64, adding targets
ops/            Operational tools — layerctl, dotctl, vmctl, bootstrap, config flow, install
fix/            Active bugs and open fix branches — known issues, nvidia, boot chain, suspend
verify/         Verification — session checklist, power testing, layer state table
desktop/        Deep desktop reference — Hyprland guide, shell guide, theming, boot flow detail
historical/     Stale docs — KDE-spin era installs, branch diffs, implementation plans
```

## Navigation

| I need to... | Read |
|---|---|
| Understand the layer model | `layers/RaBbLE-OS-Layers.md` |
| Know what's broken right now | `fix/RaBbLE-OS-KnownIssues.md` |
| See current Phase 1 blockers | `RaBbLE-OS-Roadmap.md` |
| Run layerctl / dotctl commands | `ops/RaBbLE-OS-Ops-Layerctl.md` or `ops/RaBbLE-OS-Ops-Dotctl.md` |
| Work on a specific layer | `layers/RaBbLE-OS-Layer-<name>.md` |
| Work on boot chain | `layers/RaBbLE-OS-Layer-Boot.md` → `fix/RaBbLE-OS-Fix-BootChain.md` |
| Work on NVIDIA / GPU | `fix/RaBbLE-OS-Fix-Nvidia.md` |
| Work on Hyprland config | `desktop/RaBbLE-OS-Desktop-Hyprland.md` |
| Work on theming | `desktop/RaBbLE-OS-Desktop-Theming.md` |
| Work on the Waybar Claude/Codex usage pills | `desktop/RaBbLE-OS-Desktop-sCoRE-UsageTracker.md` |
| Understand config flow | `ops/RaBbLE-OS-Ops-ConfigFlow.md` |
| Install on a machine | `ops/RaBbLE-OS-Ops-Install.md` |
| Test in a VM | `ops/RaBbLE-OS-Ops-Vmctl.md` |
| Verify a bootstrap | `verify/RaBbLE-OS-Verify-Checklist.md` |
| Check layer state | `verify/RaBbLE-OS-Verify-LayerState.md` |
| Add new hardware target | `hardware/RaBbLE-OS-Hardware-AddingTargets.md` |

## Rules

- Colors: `RaBbLE-Agent/RaBbLE-Palette.md` only — never invent hex values
- Config changes: `config/` → deploy via `dotctl`, never edit `~/.config/` directly
- System changes: Ansible only, never manual package installs
- Commits: Pulse Protocol — `[impulse] ~ [organ] >> [revelation] // %STATE%`

---

## Lessons & Gotchas (distilled from S20–S46, plus the recovered pre-Collective genesis — see `RaBbLE-OS-DevHistory.md`)

- **GPU env vars in `hyprland.conf` can break SDDM login entirely** — GPU management
  must live in a separately-templated `machine.conf`, never inline in the compositor
  config (genesis lesson, 2026-04-14, still the working pattern behind today's
  layered/isolated config entry points).
- **`s2idle` is the only valid sleep mode** for the AMD Strix Point HX 370 (no S3
  support); **`tuned`+`tuned-ppd` is the canonical power stack — never install
  `power-profiles-daemon`** (it conflicts; `tuned-ppd` already exposes the same D-Bus
  API `asusctl` needs).
- **Display is `3840×2400@60Hz`**, not `2560×1600@165Hz` — an early copy-paste error
  from an unrelated ASUS ROG G14 doc that had rippled into GRUB/TTY/kernel-cmdline font
  fixes before being caught (2026-04-13). If you see the wrong resolution anywhere, it's
  a fossil of that bug.
- **The base OS has pivoted three times — Sway spin is transitional, not canon.**
  KDE spin → (seriously considered, then rejected, Arch/EndeavourOS — to protect the
  Fedora-specific Ansible investment) → Sway spin (to dodge the KDE-purge problem) →
  netinstall + Kickstart + Ansible (current). Don't assume "Sway spin" docs reflect the
  live system.
- **Session manager arc:** SDDM → explored and fully abandoned `greetd`/`tuigreet` →
  back to SDDM as canonical. GNOME was evaluated as a DE fallback and explicitly
  rejected — "adds entropy, doesn't align with RaBbLE ethos."


- **CRITICAL — VM partitions must never be a boot dependency.** S41: `vmctl
  --raw-disk` destroyed the dedicated VM BTRFS partition's filesystem/label, and a
  missing `nofail` in fstab then dropped the daily driver into emergency mode
  (inaccessible without the root password). Always mount with
  `nofail,x-systemd.device-timeout=5s`; `vmctl` must preserve filesystem labels; no VM
  tooling may ever become a hard boot dependency.
- **Installer base is Fedora Everything netinstall + Kickstart + Ansible** — the Sway
  spin is abandoned/legacy (it only ever served as an early bootstrap proof). KS
  handles partitioning/base packages/locale/user; Ansible handles
  DE/dotfiles/hardware/COPRs; KS `%post` clones the repo and runs
  `RaBbLE-OS-Bootstrap.sh`.
- **dotctl is the only config-deployment path.** Never edit `~/.config/` or live system
  files directly — edit `RaBbLE-OS/config/<bundle>/`, then
  `./RaBbLE-OS-dotctl.sh apply <bundle>`. Ansible roles stay package/system-config-only
  and config-agnostic; dotfile tasks should remain stubs or thin dotctl wrappers, never
  `copy`/`template` (that would conflict with dotctl's `pull` recovery verb).
- **`ansible/packages/manifest.yml` is the single source of truth** for both Ansible
  installs and KS `%packages` generation — every entry carries
  `name/category/reason/source/platform/layer/ks`; `generate-kickstart.py` filters on
  `ks: true`.
- **hyprpolkitagent, not polkit-gnome** (Hyprland-native, already in COPR; the old
  `autostart.conf` pointed at a nonexistent polkit-gnome binary path — fixed to
  `systemctl --user start hyprpolkitagent`).
- **gnome-disk-utility replaces GParted** — a two-layer Fedora 43 bug (polkit auth +
  `glycin-svg` bubblewrap sandbox segfault) that neither tool alone could fix.
- **NVIDIA hybrid GPU (ASUS ProArt P16):** HDMI is physically wired to the NVIDIA card
  (`card0`), not the AMD card/eDP-1 — needs explicit monitor resolution, `AQ_DRM_DEVICES`
  ordering (AMD first), `LIBVA_DRIVER_NAME=nvidia`, `HYPRLAND_NO_HARDWARE_CURSORS=1`,
  and `nvidia-drm fbdev=1`.
- **`AiQuickstart.md` must never be renamed or prefixed** — it's symlinked to
  CLAUDE.md and is agent infrastructure, distinct from the human-facing
  `RaBbLE-OS-*` grimoire docs.
- **Kickstart lessons:** needs an explicit `reboot` directive (Anaconda hangs on
  completion otherwise); `ExecStartPre/Post` needs a `+` prefix for root ops; use
  `@core` not `@^minimal-environment` (Fedora 44 comps groups changed); hardcode the
  mirrorlist URL (Anaconda doesn't expand `$releasever` during initrd boot); deliver
  the KS via `--initrd-inject`, not an HTTP server — it removes the network dependency
  entirely.
- **Open known bugs (not yet fixed):** `supergfxd.yml` stub vs `supergfx.yml` working
  file conflict (`main.yml` calls the stub); the NVIDIA install task's idempotency
  check is inverted (skips reinstall when packages have been removed).
