# G7 + G9 Verification Guide — Episode 1 Launch Gates

> **Gates:** G7 (RaBbLE-OS Developer-Preview FLOOR) + G9 (setup.sh bootstrap verification)
> **When:** After all other EP1 gates are green; must be done before air procedure
> **Owner:** Mark (with agent support for prep)
> **Status:** Ready for execution (S154)

This guide walks through verifying the two remaining Episode 1 gates: RaBbLE-OS install/boot/recover on a generic VM, and the setup.sh bootstrap end-to-end on a fresh machine.

---

## Prerequisites

- Access to a developer machine with QEMU/KVM virtualization support
- Display server capable of running virt-viewer (SPICE display)
- Fedora 43 netinstall ISO (download if needed; see below)
- ~30 minutes for a full verification cycle
- One instance of the RaBbLE-Collective cloned locally

```bash
cd ~/RaBbLE-Collective
git checkout new-horizons
bash RaBbLE-Grimoire/spells/status.sh  # verify lockstep clean
```

---

## Phase 1: G7 Verification — RaBbLE-OS Developer-Preview FLOOR

### Setup (5 min)

1. **Obtain Fedora 43 netinstall ISO** (if not cached locally):
   ```bash
   # Download to RaBbLE-OS/ISO/ (gitignored directory)
   mkdir -p RaBbLE-OS/ISO
   cd RaBbLE-OS/ISO
   curl -O https://download.fedoraproject.org/pub/fedora/linux/releases/43/Spins/x86_64/Fedora-43-KDE-netinstall-x86_64-CHECKSUM
   curl -O https://download.fedoraproject.org/pub/fedora/linux/releases/43/Spins/x86_64/Fedora-43-KDE-netinstall-x86_64.iso
   # Verify checksum
   sha256sum -c Fedora-43-KDE-netinstall-x86_64-CHECKSUM
   ```
   (Note: Use the actual Fedora 43 netinstall; KDE spin is for checksum convenience only.)

2. **Check current VM state**:
   ```bash
   cd RaBbLE-OS
   ./RaBbLE-OS-vmctl.sh status        # should show "shut off" + ~1.8G disk
   ./RaBbLE-OS-vmctl.sh snapshots     # should be empty or show prior runs
   ```

3. **Clear VM if needed** (start fresh):
   ```bash
   ./RaBbLE-OS-vmctl.sh delete        # careful: deletes the disk image
   ./RaBbLE-OS-vmctl.sh setup         # recreate empty VM definition
   ```

### Install + Bootstrap (15 min)

4. **Run automated Kickstart install**:
   ```bash
   ./RaBbLE-OS-vmctl.sh cast-ks ISO/Fedora-43-KDE-netinstall-x86_64.iso \
     --name "generic-x86_64-ep1" \
     --cpus 4 --ram 4096
   ```
   This runs unattended Anaconda + initial Ansible bootstrap. The VM boots to a login prompt or desktop.

5. **Boot the VM with display**:
   ```bash
   ./RaBbLE-OS-vmctl.sh start
   # In another terminal:
   ./RaBbLE-OS-vmctl.sh virt-viewer
   ```
   virt-viewer opens a SPICE window showing the VM's display.

6. **Complete Ansible bootstrap** (if not yet done):
   ```bash
   # Inside the VM:
   sudo bash Bootstrap.sh            # or ssh in and run remotely
   layerctl apply all
   dotctl apply all
   # Reboot
   sudo reboot
   ```

### Verification Checklist (10 min)

Run through the **RaBbLE-OS-Verify-Checklist.md** items. All must be ✅ (mark as GREEN in EP1-AIR-CHECKLIST):

#### Session Boot & Desktop
- [ ] SDDM greeter appears (not dropped to TTY)
- [ ] Log in as rabble user (password set during install)
- [ ] Hyprland session starts — wallpaper visible (navy gradient)
- [ ] Waybar renders at bottom: clock, battery, network, workspace indicators
- [ ] Function keys work: volume (Fn+Up/Down), brightness (Fn+Left/Right), mic-mute (Fn+M)
- [ ] SwayOSD notifications appear when adjusting volume/brightness
- [ ] `Super+Space` → Fuzzel launcher opens
- [ ] `Super+Enter` → Kitty terminal opens
- [ ] RaBbLE palette visible in Kitty (navy #12132a, magenta #ff2d78, cyan #00f5ff)
- [ ] `Print` key → region screenshot (saves to ~/Pictures)
- [ ] `Shift+Print` → full screenshot
- [ ] `notify-send "test" "message"` → Mako notification in top-right
- [ ] Idle for ~2 min → Hyprlock triggers (lock screen with time)
- [ ] `loginctl lock-session` → Hyprlock manual trigger works
- [ ] If second display attached: HDMI hotplug detection works (Waybar updates)

#### Shell & Environment
- [ ] ZSH prompt shows p10k powerline (git branch, exit status, etc.)
- [ ] Bash prompt shows RaBbLE two-line format (user@host, shell indicator)
- [ ] Aliases work: `ll` (ls -lA), `gs` (git status), `rabble` (ls ~/RaBbLE-Collective), `rabble-dots` (cd ~/.config/rabble)
- [ ] Functions available: `fcd` (fzf directory jump), `fe` (fzf editor), `extract` (decompress files)
- [ ] Env vars set: `echo $LS_COLORS` (non-empty), `echo $FZF_DEFAULT_OPTS`, `echo $BAT_THEME`
- [ ] `fastfetch` displays with RaBbLE logo + palette colors

#### Idempotency
- [ ] Run `layerctl apply all` again → changes nothing (idempotent)
- [ ] Run `layerctl verify all` → all layers report `%STABLE%` or documented exception
- [ ] Any new failures: document in `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md`

#### Recovery Path (§C requirement)
- [ ] Reboot VM
- [ ] At SDDM login screen, press **F2**
- [ ] System drops to emergency/sulogin mode with `systemd-sulogin-force` active
- [ ] Log in as root (no password needed in emergency mode)
- [ ] Run `systemctl default` to return to graphical login
- [ ] SDDM reappears
- [ ] Login as rabble user succeeds
- [ ] **Result: Recovery documented and works ✅**

### Known Rough Edges Audit (2 min)

After verification, check the known issues file and document any new ones:

```bash
cat RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md
```

Add any issues found to the **rough-edges sheet** (see "Create Rough-Edges Sheet" below).

### Create Clean Snapshot

Once G7 verification is complete and all boxes ✅:

```bash
./RaBbLE-OS-vmctl.sh snapshot "clean-install-g7-verified"
```

This allows future bootstrap tests to restore to a known-good state.

### Gate Status Update

Update `RaBbLE-Grimoire/log/EP1-AIR-CHECKLIST.md`:

| Gate | State | Notes |
|---|---|---|
| G7 | ✅ | RaBbLE-OS generic x86_64 VM boots, daily-survivable, recovery works. Known edges documented. |

---

## Phase 2: G9 Verification — setup.sh Bootstrap End-to-End

### Prerequisites

- A fresh VM (can reuse the same one or create a new one; recommended: fresh for isolation)
- The RaBbLE-Collective cloned on the VM at `~/RaBbLE-Collective`
- Network access to fetch dependencies

### Test: Fresh Clone + Bootstrap (10 min)

1. **Create a fresh VM instance** (or use the G7 VM and restore to snapshots):
   ```bash
   # Option A: Restore G7 clean snapshot
   ./RaBbLE-OS-vmctl.sh restore "clean-install-g7-verified"
   
   # Option B: Create a new VM
   ./RaBbLE-OS-vmctl.sh cast-ks ISO/Fedora-43-KDE-netinstall-x86_64.iso \
     --name "bootstrap-test-fresh" \
     --cpus 4 --ram 4096
   ```

2. **Boot and login**:
   ```bash
   ./RaBbLE-OS-vmctl.sh start
   ./RaBbLE-OS-vmctl.sh virt-viewer  # or SSH in
   ```

3. **Run setup.sh bootstrap**:
   ```bash
   # Inside the VM:
   curl -fsSL https://joinrabble.world/setup.sh | bash
   ```
   
   Watch for:
   - [ ] Script downloads and runs cleanly (no curl 404s or network errors)
   - [ ] Clones RaBbLE-Collective to `~/RaBbLE-Collective`
   - [ ] Runs `Bootstrap.sh` (Ansible + packages)
   - [ ] Completes without interactive prompts (fully automated)
   - [ ] VM reboots to Hyprland session (if bootstrap includes reboot)
   - [ ] After reboot: `~/RaBbLE-Collective/` is intact and git state is clean

4. **Verify full Collective is reachable**:
   ```bash
   # Inside the VM:
   cd ~/RaBbLE-Collective
   ls -la | grep RaBbLE
   cat RaBbLE-Grimoire/gist/RaBbLE-Identity-gist.md | head -5
   bash RaBbLE-Grimoire/spells/status.sh
   ```

5. **Test local chat surface** (if desired):
   ```bash
   # Run dev server (requires venv + deps):
   cd RaBbLE-World
   python -m http.server 8000
   
   # In another terminal:
   firefox http://localhost:8000
   # Verify landing page loads, entity renders, no CSS/JS errors in console
   ```

### Gate Status Update

Update `RaBbLE-Grimoire/log/EP1-AIR-CHECKLIST.md`:

| Gate | State | Notes |
|---|---|---|
| G9 | ✅ | setup.sh bootstrap verified end-to-end on fresh VM. All repos clone, Ansible completes, session boots. |

---

## Known Rough Edges Sheet

Create and document in `RaBbLE-Grimoire/RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md` (update from G7 testing):

**Example format:**
```markdown
## Episode 1 Development Preview Known Issues

### [P1] SDDM theme — navy tint on login screen
- Status: Cosmetic; workaround exists
- Workaround: None; expected in EP1 preview
- Post-EP1: Scheduled for theming polish (EP2)

### [P2] Suspend/resume — screen sometimes doesn't wake on touchpad
- Status: Occasional
- Workaround: Keyboard press or close/open lid
- Post-EP1: Tracked in `fix/suspend-resume`

### [P3] NVIDIA users only — GPU utils not installed (intentional for generic EP1)
- Status: By design; optional hardware track post-EP1
- Workaround: Install manually if needed
- Post-EP1: `fix/proart-nvidia` track
```

---

## Completion Checklist

Once both G7 + G9 are ✅ and rough-edges sheet is written:

- [ ] EP1-AIR-CHECKLIST.md: G7 = ✅
- [ ] EP1-AIR-CHECKLIST.md: G9 = ✅
- [ ] RaBbLE-OS/fix/RaBbLE-OS-KnownIssues.md: Updated with EP1 preview edges
- [ ] All lockstep members still `in-step` and `clean` (verify: `bash spells/status.sh`)
- [ ] No new `ep1-gate` blockers open (verify: `bash spells/blockers.sh ls`)
- [ ] **Result:** All of §A gate rows are GREEN ✅

Then: **Mark makes the air call** → run the **air procedure (§D)** → tag all members simultaneously with `episode-1-v0.0.0.1` → merge to `main` → broadcast EP1 live.

---

## Troubleshooting

### VM won't boot after Ansible bootstrap
- Check `/var/log/ansible/bootstrap.log` inside VM
- Re-run `layerctl apply all` and check for errors
- Check Hyprland config syntax: `hyprctl validate` (if you can get to a TTY)

### setup.sh script fails with 404
- Verify `https://joinrabble.world/setup.sh` is reachable: `curl https://joinrabble.world/setup.sh | head -5`
- Check World repo deployment on Render: is new-horizons deployed?

### Ansible playbook hangs on a specific task
- SSH into VM separately and check systemd journals: `journalctl -u ansible-bootstrap -f`
- Or manually continue bootstrap: `cd ~/RaBbLE-Collective && bash RaBbLE-Collective/Bootstrap.sh`

### SDDM/Hyprland don't start; stuck on emergency console
- Try recovery path (§C): press F2, log in, check systemd status
- Run `systemctl status sddm` to see what failed
- Check `/var/log/Xorg.0.log` for display server errors

---

## Next: Air Procedure

Once G7 + G9 are green and §A is all ✅:

```bash
cd RaBbLE-Grimoire
# 1. Freeze all members
bash spells/status.sh            # confirm all in-step + clean
bash spells/blockers.sh ls       # confirm no ep1-gate open

# 2. Backup tags (history retention)
bash spells/backup-tags.sh pre-ep1

# 3. Tag all lockstep members simultaneously
bash spells/tag-episode.sh 1     # tags episode-1-v0.0.0.1 on all

# 4. Merge to main and roll epoch
git checkout main
git merge new-horizons
git push origin main
bash spells/roll-epoch.sh 1      # updates current.epoch.yml

# 5. Broadcast
# Mark updates joinrabble.world landing page: "Episode 1 Genesis — Live"
# All members tagged; main is the source of truth for EP1
```

See `RaBbLE-Grimoire/log/EP1-AIR-CHECKLIST.md` §D for full procedure.
