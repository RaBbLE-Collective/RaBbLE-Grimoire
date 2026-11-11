# RaBbLE-OS — Fedora 44 Upgrade & Backup

```
transcribe ~ substrate >> archive before you ascend // %F44_UPGRADE%
```

> **Status:** near-term work-package (decided S139). Do the **backup/archive** pass
> *before* touching the upgrade. The OS is reproducible from Ansible + dotctl; the
> things that are **not** are live secrets and `~/.claude`. Back those up first.
> Roadmap: `RaBbLE-OS-Roadmap.md` § Backlog Triage E.

---

## 1 · Backup / Archive (do this FIRST)

The substrate is reproducible (manifest.yml → packages, `config/` → dotctl → `~/.config`).
A clean `dnf system-upgrade` keeps `/home` intact — but treat it as if it might not.
The genuine risk is **unversioned state that exists nowhere but this disk.**

### 1a · Versioned — verify clean + pushed
All member repos must be committed **and pushed to remote** (remote = the real backup):
```bash
for d in ~/RaBbLE-Collective/RaBbLE-*/; do
  b=$(git -C "$d" branch --show-current)
  echo "== $d ($b) =="
  git -C "$d" status --porcelain        # must be empty
  git -C "$d" log --oneline -1 @{u}.. 2>/dev/null   # unpushed commits, if any
done
```
- Members live on `new-horizons` (Chrysalis/Xperimental on `main`). Commit this
  session's work (Grimoire, RaBbLE-OS) and push every repo before upgrading.

### 1b · UNVERSIONED — the real backup targets
These are **not in any repo** and would be lost on a reinstall:

| What | Path | Why it matters |
|---|---|---|
| **fcc provider keys** | `~/.config/RaBbLE/fcc.env` | Real API keys (gitignored — only the `.example` is tracked). Irreplaceable without re-issuing. |
| **Claude Code state** | `~/.claude/` | OAuth login + `settings.json` + **auto-memory** (`projects/*/memory/`) + command history. Also `~/.claude-free/` if seeded (it symlinks back here). |
| **SSH** | `~/.ssh/` | Git/remote auth keys. |
| **GPG / age / SOPS** | `~/.gnupg/`, `~/.config/sops/age/` | Episode-signing + secrets decryption (see `RaBbLE-Secrets-and-Identity.md`). Absent today — capture if/when created. |
| **Any hand-tuned `~/.config` not under dotctl** | `~/.config/*` | dotctl owns the RaBbLE bundles; anything outside them is unmanaged. Diff before trusting reproducibility. |

Minimal encrypted archive:
```bash
tar czf ~/rabble-preupgrade-$(date +%Y%m%d).tar.gz \
  ~/.config/RaBbLE/fcc.env ~/.ssh ~/.gnupg ~/.config/sops 2>/dev/null
# ~/.claude separately (large; excludes caches):
tar czf ~/claude-state-$(date +%Y%m%d).tar.gz \
  --exclude='*/node_modules' ~/.claude
# Encrypt + move OFF the machine (USB / remote). Do not leave keys in plaintext.
```
> Open idea (`~/.claude` git-tracking) — see memory `idea_git_track_claude_dir`. A
> private git mirror of `~/.claude` would make this a `git push`, not a tarball.

### 1c · Snapshot (cheap insurance)
Btrfs root → take a snapshot before the upgrade so a bad akmod/initramfs is one
rollback away. (Note: `grub-btrfs` is unavailable on F43 — snapshot is manual/recovery,
not a boot-menu entry.)

---

## 2 · Upgrade Fedora 43 → 44

Standard `dnf system-upgrade` path:
```bash
sudo dnf upgrade --refresh
sudo dnf install dnf-plugin-system-upgrade   # if not present
sudo dnf system-upgrade download --releasever=44
sudo dnf system-upgrade reboot
```

### RaBbLE-OS-specific upgrade risks
- **NVIDIA akmods** rebuild against the F44 kernel — the #1 thing that breaks a desktop
  upgrade. Ties directly into the Hardware-Reliability cluster (iGPU-only Hyprland,
  dGPU defer). Confirm akmod build succeeds before relying on the dGPU.
- **llama.cpp / runtime stamp guard** (S138): version-guard stamp at
  `/usr/local/share/llama-cpp/version` + ldconfig drop-in — re-verify after the
  Python/toolchain bump.
- **Python rev** — F43 shipped 3.14; if F44 bumps it, re-check the `uv`/pipx harness
  installs (aider's scipy/audioop pins, S136–138).
- **Hyprland** — confirm the installed version vs the `Hyprland-0.55-Reference.md`
  baseline; watch for windowrule/config-syntax drift.
- **COPR repos** (asusctl, etc.) — may need `--releasever` bump or rebuild for F44.

---

## 3 · Post-upgrade verification
```bash
bash ~/RaBbLE-Collective/RaBbLE-OS/RaBbLE-OS-layerctl.sh verify all
bash ~/RaBbLE-Collective/RaBbLE-Grimoire/spells/fcc-ctl.sh status   # readiness verdict
```
- Boot reaches SDDM → Hyprland session; Waybar/Kitty/Fuzzel/Mako/swayOSD live
  (Verify-Checklist § Session).
- Restore `~/.config/RaBbLE/fcc.env` if `/home` was touched; re-run `fcc-ctl sync`.
- `claude` (paid) still logged in; `claude-free` isolated profile intact.
- Idempotency: a second `layerctl apply all` changes nothing.
```
mend ~ substrate >> ascended to F44, body intact // %F44_DONE%
```
