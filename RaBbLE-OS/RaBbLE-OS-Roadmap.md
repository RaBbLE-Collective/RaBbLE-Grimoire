# RaBbLE-OS-Roadmap.md — Episode Map & Work Queue

```
transcribe ~ grimoire >> roadmap consolidated // %S34%
```

## Episode 1 — Genesis · RaBbLE-OS Developer Preview `[IN PROGRESS]`

> **Posture (decided S109):** OS airs in Episode 1 as a labeled **Developer Preview**
> — *"enter at your own risk, unstable vibes."* It does **not** hold back the Collective
> lockstep; full reproducible polish bakes toward **Episode 2 (Exodus)**, where the body
> becomes reliable. Canon: `registry/epochs/current.epoch.yml` (`exit_condition`,
> `episode_coherence_policy`, OS `focus` block).
>
> **Audience:** a Linux + tiling-WM-literate user willing to tolerate quirks.
> **The bar is the generic x86_64 / VM-verified path.** Mark's ProArt-specific hardware
> work (NVIDIA / asusctl / XDNA2) is a **separate profile track**, NOT part of the
> universal preview bar — a cohort member runs OS on their own hardware.

**Branch:** `RaBbLE-OS-New-Horizons` → `RaBbLE/episode-I`

### The Preview Bar — definition of "ready to ship the preview"

**FLOOR — all must be TRUE before the preview goes out (a stranger touches this):**
- [ ] **F1 · Install works (generic x86_64).** KS → Anaconda → reboot → firstboot → SDDM, VM-verified on `generic_x64`. (Phase 5 gate; firstboot currently unverified.)
- [~] **F2 · Recovery without a dead-end.** Emergency/rescue reachable *without* unlocking root: `SYSTEMD_SULOGIN_FORCE=1` drop-in on `emergency.service` + `rescue.service` (keeps Fedora's locked-root posture — root password rejected as legacy). Ship a `rd.break` + live-USB recovery doc. Document the physical-access trade-off honestly; LUKS is the real mitigation (EP2). — **Mechanism implemented S109** (`core/tasks/recovery.yml`, commit `aaf87b9`); recovery doc = the F5 sheet; pending VM verify.
- [ ] **F3 · No hard boot dependency can brick.** fstab `nofail` enforced (S41, `virtualization/fstab-safety.yml`); audit for any other hard deps.
- [ ] **F4 · Boots to graphical, core surfaces live.** Verify-Checklist *Session* section passes on generic_x64 (Hyprland · Waybar · Kitty · Fuzzel · Mako · swayOSD).
- [~] **F5 · "Known Rough Edges" sheet ships with the OS.** The label is the product — the "enter at your own risk" honesty contract. — **Drafted S109:** `RaBbLE-OS-KnownRoughEdges.md`; pending a ship-path into the install image (MOTD / welcome doc / ISO bundle).

**HARDEN — daily-driver quirks; fix the cheap ones, document the rest:**
- [ ] Hyprland `windowrules`/`workspaces` v0.54 migration (mechanical `windowrulev2`→`windowrule` rename)
- [ ] hypridle stability + idle-sign-out-during-video bug (`ISSUES.md`)
- [ ] File managers: wire Yazi + polish Dolphin theming/integration (both installed — polish, not missing)
- [ ] Wallpaper Ansible-managed (kill the manual `hyprpaper.conf` step)
- [ ] ZSH XRT prompt artifact
- [ ] Confirm all Fn keys wired now that swayOSD landed (S108)

**DEFER → Episode 2 (Exodus) — document as rough, don't fix for the preview:**
Firefox / GTK / Kvantum / Qt theming parity · boot-chain cosmetic polish (GRUB 4K font, Plymouth palette) · custom live ISO (Tier 2) · Quickshell · hyprbar / master layout · cinematic entity boot · bootable-snapshot rollback (grub-btrfs unavailable on F43) · Mark-hardware profile (NVIDIA / asusctl / XDNA2 — separate track).

### Dev Flow — Hardening Protocol

The loop that turns daily quirks into bounded scope. Lightweight for EP1; the
heavyweight **ticket tracking + feature-scope breakdown is a post-EP1, possibly
Collective-wide effort** (see Episode 2 notes) — do not build it into EP1.

1. **Capture (point-of-pain):** log the moment you hit it — `ISSUES.md` (capture path fixed S109). Append-only, one line, atomic. *(TODO: `rabble-gripe`/`-bug`/`-wish` alias for frictionless capture — empty ISSUES.md after a month of daily-driving was a capture-friction failure, not a quirk-free month.)*
2. **Triage (weekly sweep):** tag each entry **FLOOR / HARDEN / DEFER** against the Preview Bar; promote actionable items → KnownIssues or a Bar line; DEFER → EP2 backlog. Empty ISSUES.md after.
3. **Bar-check (gate):** before any "OS EP1 ready" claim, run the **Preview FLOOR gate** — `verify/RaBbLE-OS-Verify-PreviewFloor.md` (the F1/F2/F4 VM runbook + F3 audit) — on a clean `generic_x64` VM. FLOOR all-green + F5 sheet shipped = the preview ships.

**Multisession discipline (known pain):** concurrent agent sessions clobber shared
logs (SESSION-LOG, ISSUES, KnownIssues) and the git index. Until the post-EP1
tracking rework lands: capture is **append-only** (per-session dated blocks — never
edit another session's region); commit with `--force-with-lease`; treat shared-region
edits as tread-carefully. Tracked for the post-EP1 ticketing redesign.

### Plots (legacy framing — fold into the Bar above)

**Plot A — Substrate:** Ansible layers 0–4 functional on clean Fedora 43. Control plane operational.
**Plot B — Theme:** Shell stack, Kitty, Fuzzel, Mako, hypridle/lock, boot chain palette-continuous.
**Plot C — Installer:** KS on Fedora netinstall (Tier 1), custom live ISO (Tier 2 north star).

### Underlying Work Queue — Phases (the granular tasks that satisfy the Bar)

**Phase 1 — Boot into a DE:**
- [x] `core/packages` → DNF install all `layer: core` manifest entries (~20 pkgs)
- [x] `boot/plymouth/packages` → `plymouth`, `plymouth-plugin-script`
- [x] `boot/session_manager/packages` → `sddm` + enable service + graphical.target
- [x] New `desktop/fonts` role → JetBrains Mono, Font Awesome, Noto (before compositor)
- Done when: SDDM greeter appears on fresh Fedora Everything install

**Phase 2 — Themed boot + browser:**
- [ ] `boot/plymouth/config` → RaBbLE theme + `plymouth-set-default-theme` + dracut
- [ ] `boot/session_manager/config` → SDDM QML theme + Wayland conf + hyprland.desktop
- [ ] `boot/grub2` → 4K font, remove bg image, `fbcon=font:TER16x32`
- [ ] `apps/browsers` → `firefox`
- Done when: full boot chain themed, Firefox available

**Phase 3 — Hardware + theming:**
- [ ] `hardware/.../asusctl+asusd` → COPR + DNF + service enable
- [ ] `hardware/.../tuned` → install + enable + profile
- [ ] New `desktop/theme` role → Kvantum, qt5ct/qt6ct, GTK CSS, papirus icons
- [ ] `layer/bluetooth` → bluez, blueman
- [ ] `layer/flatpak` → flatpak + Flathub

**Phase 4 — Installer: `[WORKING — S37]`**
- [x] `RaBbLE-OS.ks` — Tier 1 KS (autopart VM default, drop clearpart/autopart for interactive)
- [x] `spells/generate-kickstart.py` — manifest → `%packages` (COPR/rpmfusion excluded, --platform flag)
- [x] `--unattended` Bootstrap flag + `--inventory` override
- [x] `ansible/inventory/vm.hosts.yml` — generic_x64 localhost inventory for VM use
- [x] `vmctl cast-ks` — automated KS install via `--initrd-inject` (no HTTP server)
- [x] `url --mirrorlist` in KS — netinstall package source (hardcoded fedora-44/x86_64)
- [x] `reboot` directive — VM auto-reboots into installed OS after KS completes
- [x] Firstboot systemd service — runs Bootstrap with `base,boot` tags on first boot
- [x] `spells/diagnose-vm-net.sh` — network diagnostic for VM troubleshooting
- Done when: KS boot → Anaconda → reboot → firstboot service → SDDM
- **Status:** KS install completes, VM reboots, firstboot pending verification

**Phase 4B — KS-owns-packages refactor:**
- [ ] Update `generate-kickstart.py` to emit `repo` directives for COPR/rpmfusion sources
- [ ] Stop filtering COPR/rpmfusion packages out of `%packages` — Anaconda handles them with `repo` directives
- [ ] Move all package installation into KS `%packages` (manifest.yml stays single source of truth)
- [ ] Ansible firstboot becomes config-only (services, dotfiles, themes) — no package downloads
- [ ] Lighter, faster firstboot: no network-dependent package installs, less likely to fail
- [ ] Replace `@core` with full generated `%packages` from manifest
- Done when: KS installs everything, Ansible only configures

**Phase 5 — Reproducibility gate:**
- [ ] Fresh Fedora Everything → KS → reboot → all acceptance criteria pass
- [ ] VM smoke test (generic_x64) — firstboot → SDDM greeter
- [ ] Idempotency: second `layerctl apply all` changes nothing

**Phase 6 — Custom live ISO (Tier 2 north star):**
- [ ] `RaBbLE-OS-LiveISO.ks` — live session KS (different from install KS)
- [ ] `installer/live-config/` — branding, theme assets for live environment
- [ ] `spells/build-iso.sh` — `lorax`/`livemedia-creator` wrapper
- [ ] Boot RaBbLE-themed Hyprland live session → partition → run `rabble-install`

### Assembly (porting New Horizons → episode-I)

Strategy: `git checkout RaBbLE-OS-New-Horizons -- <paths>` — no cherry-pick.
Do NOT port: `nvidia.yml`, `supergfx.yml`, hardware handlers (stay in `fix/proart-nvidia`).

```bash
# Package 1 — control-plane
git checkout RaBbLE-OS-New-Horizons -- RaBbLE-OS-dotctl.sh .gitignore README.md

# Package 2 — ansible-roles
git checkout RaBbLE-OS-New-Horizons -- \
  ansible/inventory/group_vars/all.yml \
  ansible/roles/boot/session_manager/handlers/main.yml \
  ansible/roles/boot/session_manager/tasks/config.yml \
  ansible/roles/desktop/hyprland/tasks/config.yml \
  ansible/roles/desktop/hyprland/vars/main.yml \
  ansible/roles/desktop/shell/zsh/tasks/packages.yml \
  ansible/roles/desktop/swayosd/tasks/service.yml \
  ansible/roles/desktop/terminal/tasks/packages.yml \
  ansible/roles/desktop/waybar/vars/main.yml \
  ansible/roles/desktop/wayland/vars/main.yml

# Package 3 — config
git checkout RaBbLE-OS-New-Horizons -- \
  config/hypr/ config/kitty/ config/fuzzel/ config/mako/ config/shell/ \
  config/systemd/ config/wallpapers/
```

After Episode 1 lands on main: `git rebase main` on New Horizons.

---

## fix/* Branches

| Branch | Goal | State |
|--------|------|-------|
| `fix/proart-nvidia` | NVIDIA RTX 4060 Optimus stable — **iGPU-only Hyprland + dGPU on-demand** (see Hardware-Reliability cluster) | %HIGH_ENTROPY% |
| `fix/boot-chain` | GRUB/Plymouth/SDDM themed at 4K + Plymouth DRM-handoff black-screen | %COOKING% |
| `fix/suspend-resume` | s2idle reliable + **idle/suspend battery-in-bag loop** | %COOKING% |
| `fix/xdna2-npu` | XDNA2 NPU via XRT | %DORMANT% |

---

## Backlog Triage — S140 (Mark's issue/idea sweep)

Captured from a daily-driving issue/idea dump and bucketed against the Preview Bar.
**Hardware-Reliability is a ProArt-profile track (Mark's hardware), NOT the generic
x86_64 preview bar** — it does not gate the EP1 preview. Boot-chain detail lives in
`fix/RaBbLE-OS-KnownIssues.md`; this is the index.

### Landed (S140)
- **[x] Wallpaper → `RaBbLE_WP.PNG`.** `hyprpaper.conf` pointed at the stale `wallpaper.png`; repointed + deployed + verified live. *(The HARDEN item "Wallpaper Ansible-managed — kill the manual hyprpaper.conf step" still stands — it's still a hand-edited conf.)*
- **[x] Audio: Waybar popup, not a full tile.** `pulseaudio` left-click now toggles a compact floating mixer (`scripts/audio-popup.sh`: pavucontrol floated/sized 480×600/anchored top-right imperatively — Hyprland ignores a `move` windowrule for this GTK float). Scroll + right-click route through **swayOSD** for the themed OSD "linear feel." Optional later: swap pavucontrol → `pwvucontrol` (PipeWire-native).
- **[x] fcc working.** `claude-free` errored because the proxy was up but had no provider key — *and* the example/spell used the wrong var name (`NVIDIA_API_KEY`; upstream free-claude-code reads `NVIDIA_NIM_API_KEY`). Fixed: renamed the fcc layer to `NVIDIA_NIM_API_KEY` across `fcc.env.example` + `fcc-ctl.sh` + layer doc, registered the NIM key (from sCoRE `.env`), smoke-tested HTTP 200 streaming from `nvidia/llama-3.1-nemotron-nano-8b-v1`. `fcc-ctl status` prints a routing-readiness verdict. *(sCoRE keeps `NVIDIA_API_KEY` — its own code/var; renaming that is a separate live-Render change.)*
- **[x] `claude-free` logout bug.** Launcher set `ANTHROPIC_API_KEY` against the shared `~/.claude` profile → flipped it to api-key auth and logged the paid OAuth session out. Fixed: isolated `CLAUDE_CONFIG_DIR=~/.claude-free` (+ `force: true` redeploy), with memories/instructions shared in via symlink (`CLAUDE.md`, `commands`, `projects`) so the free profile keeps context but never touches auth. **Needs `layerctl apply ai-harnesses` + a login-safe test.**

### A · Bounded wins (HARDEN)
- **AI-harness layer refinement** via layerctl/dotctl — ongoing (S138 added runtime/monitoring/virtualization layers; dotctl wired into `layerctl dotfiles`). Continue: default-config coverage, harness skip-behavior audit.
- **Free-models / fcc usage tracker in Waybar.** The Claude/Codex/Antigravity(Gemini) meters already ship (`custom/llm-*` → `score-glyph-stream.sh`). New piece = a `custom/llm-free` meter for fcc-routed free models. **Depends on fcc exposing per-provider request/usage data** (admin API at `:8082/admin`) — scope the data source first.

### B · Hardware-Reliability cluster — `fix/proart-nvidia` + `fix/suspend-resume` (ProArt profile, NOT preview bar)
- **iGPU-only Hyprland.** Compositor always on AMD iGPU (never laggy); NVIDIA dGPU used only via PRIME render-offload for specific apps/tasks.
- **dGPU power discipline.** Heavily deprioritize NVIDIA on battery; **suspend the dGPU** in power-saver / low-energy mode.
- **Power/battery consistency** + a clear **"is the dGPU active"** indicator (Waybar).
- **NVIDIA HDMI output** on ProArt P16 — must keep working **on battery**.
- **Idle/suspend loop** so it doesn't drain in the bag (s2idle reliability).

### C · Boot-chain polish (mostly EP2 / `fix/boot-chain`; detail in KnownIssues)
- **Plymouth black-screen hiccup** — screen blanks mid-boot; DRM handoff confirmed as the cause. **Already tracked with a defined fix** in KnownIssues ("Plymouth — black flash / NVIDIA DRM reset mid-boot": NVIDIA akmod loads mid-boot → DRM reset; fix = defer NVIDIA modules from initramfs, load at `graphical.target`). Unimplemented — belongs to the Hardware-Reliability cluster (dGPU on-demand) since deferring NVIDIA also serves iGPU-only boot.
- **Themed lock screen (hyprlock) + login (SDDM)** to complete the vibe.
- **Themed GRUB** (4K font + color-only theme) — already documented in KnownIssues; folds into the "GRUB theming + USB-boot-from-GRUB" work-package.

### D · Theming — needs a deterministic plan, NOT trial-and-error (token sink)
- **Dolphin readability** — default text must be white, no grey. Current loop is too trial-and-error (major token spend, little success). **Next step: write a deterministic kdeglobals-driven theming plan** (build on the S126 finding that KDE view/palette text comes from `~/.config/kdeglobals`, not Kvantum) before spending more tokens. Don't iterate blind.

### E · Strategic initiatives
- **Fedora 44 upgrade + backup/archive** — **near-term (decided S140).** First step: a backup/archive checklist covering RaBbLE-Collective + all of RaBbLE-OS before upgrading. → `ops/RaBbLE-OS-Fedora44-Upgrade.md`.
- **Aether-themed Gnome DE — exploratory R&D (decided S140).** A testbed to (a) learn theming deterministically and (b) make a more approachable RaBbLE-OS for standard users, with a semi-uniform feel between Hyprland and Gnome (flowing-border + transparency carried into Gnome; harvest what Gnome does well back into Hyprland). **Not a committed ship target** — exploration toward EP2/EP3. Theme work here should feed the deterministic theming plan (bucket D), not fork it.

---

## Episode 2 — Exodus `[PENDING]`

Polished desktop: cinematic entity boot, Kvantum/GTK theming, master layout, hyprbar, UX polish.
The body becomes reliable — everything the EP1 preview deferred. Full item list branches
from New Horizons after Episode 1 lands.

**Roadmap-tightening initiative (post-EP1, possibly Collective-wide):**
- **Ticket tracking + proper feature-scope breakdown** across members — replaces the
  lightweight ISSUES.md/KnownIssues capture loop. Fixes the multisession log-clobber pain.
- **Registry reframe: epoch → episode/echo.** `registry/epochs/current.epoch.yml` is, in
  practice, an *episode* tracker wearing an epoch name (every live field — `episode_pending`,
  `exit_condition`, per-member `focus`, `version_next` — is episode-grained; Epoch 0 is a
  static wrapper). Recenter on episode→echo (rename path + `current.episode.yml`); a systemic
  change touching `spells/status.sh`, `sync-grimoire`, and manifests — do it in one pass with
  the ticketing work, not piecemeal. (Surfaced S109.)

## Episode 3 — The Entity Wakes `[FUTURE]`

AI stack: Ollama local inference, MCP servers, Quickshell replaces Waybar.
Spec in `DistilledNonZense.md` § VII.

**Candidate:** Agentic app builder in the OS — [injn.ai](https://injn.ai/). Lets the
substrate generate/assemble apps on demand, aligned with the AI-stack theme. Study
fit alongside Ollama/MCP. (Surfaced from `BaBbLE.scratch`, 2026-06-02.)

→ `RaBbLE-OS-AgentGuide.md` — directory map and navigation by task
→ `fix/RaBbLE-OS-KnownIssues.md` — active blockers per layer
→ `verify/RaBbLE-OS-Verify-Checklist.md` — post-phase verification gate
