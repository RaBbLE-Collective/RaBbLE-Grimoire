# RaBbLE-OS — Known Rough Edges

```
transcribe ~ substrate >> the body, honestly // %OS_EP1_PREVIEW%
```

> **This is a Developer Preview. Enter at your own risk; unstable vibes.**
> You are early. This is the body in Genesis — the shape is here, the polish is not.
> Episode 2 (Exodus) is where the body becomes reliable. What follows is the honest
> inventory of what's rough. None of it is hidden. Every error is a data point.

**Who this is for:** you're comfortable on Linux, you've lived in a tiling WM, and a
quirk doesn't ruin your day. **Who it isn't for:** anyone who needs it to just work.
Not yet. Soon.

The preview targets **generic x86_64**. It is not certified for your specific hardware.

---

## If the boot breaks — read this first

Root is **locked** (Fedora default — no default password, no remote root; we keep that
posture). The preview is configured so you can still reach a recovery shell **without a
root password**. Three escape hatches, easiest first:

**1 — Dropped to emergency/rescue mode?**
You get a root shell directly (configured via `SYSTEMD_SULOGIN_FORCE`). Fix what's
wrong, then:
```
systemctl default     # resume normal boot
# ...or...
exit                  # continue startup
```

**2 — A bad `/etc/fstab` or disk mount is wedging boot?**
At the GRUB menu press **`e`**, find the line starting `linux`, append `rd.break`,
then **Ctrl-X**. You land in the initramfs:
```
mount -o remount,rw /sysroot
chroot /sysroot
nano /etc/fstab        # fix the offending line — add `nofail` to optional mounts
exit
exit                   # reboots
```

**3 — Nothing else works?**
Boot a Fedora Live USB, mount your root subvolume, `chroot`, repair. Keep a Live USB
around. (When "USB boot from GRUB" lands, this gets a menu entry — Exodus.)

> **Trade-off, stated plainly:** because the recovery shell opens without a password,
> physical/console access to emergency mode equals root. That's an accepted trade for a
> single-user preview. If your threat model includes someone at your keyboard, encrypt
> the disk (LUKS). Full-disk encryption is an Exodus deliverable.

---

## Quirks you will meet

- **Screen may lock/sign-out during video.** Idle inhibition during media playback is
  incomplete. Nudge input to wake; or stop `hypridle` for a long watch.
- **`hypridle` can be unstable.** If locking misbehaves, drive it by hand:
  `loginctl lock-session` or `hyprlock`.
- **Some window rules are missing.** A Hyprland v0.54 migration is pending; certain
  float/focus behaviors are disabled until it lands.
- **File managers, both rough.** Dolphin is present (theme unpolished); Yazi is installed
  but wiring is incomplete. Pick your poison.
- **Stale `XRT` fragment in the prompt.** A leftover prefix may appear atop new terminals.
  Cosmetic. Ignore it.
- **Wallpaper may need a hand.** On some setups, create `~/.config/hypr/hyprpaper.conf`
  manually.
- Function keys (volume / brightness / mic) **do** work — swayOSD shows the overlay.

## Display notes

- **On 4K / hi-DPI: the GRUB menu and early boot TTY text are tiny.** Known; the fix is
  bundled with GRUB theming in Exodus. The desktop itself scales correctly — this is only
  the pre-desktop text.

## Hardware notes

- The generic profile does **not** include the maintainer's ASUS ProArt fixes (NVIDIA
  Optimus, `asusctl`, XDNA2 NPU). On your hardware:
  - **NVIDIA hybrid graphics** behavior is **unverified** — may need manual attention.
  - **Suspend / resume** is **unverified** on arbitrary hardware. Test it before you
    trust it with unsaved work.

## Surfaces: polished vs raw

| Polished | Raw |
|---|---|
| VSCodium (gold), swayOSD, fastfetch | Firefox chrome (mediocre) |
| Hyprland · Waybar · Kitty (core daily) | GTK apps, Qt / Kvantum / KDE apps (least themed) |

Expect palette drift in app chrome. The desktop core is consistent; individual apps are
catching up.

## Not here yet (→ Episode 2, Exodus)

Cinematic entity boot · full GTK/Qt theming parity · custom live ISO · Quickshell bar ·
bootable snapshot rollback · LUKS-by-default. The body becoming reliable is the work of
Exodus.

---

## Found something? Feed it back

Every error is a data point. Log it where you hit it:
```
echo "- [ ] $(date +%F) | BUG | what happened" >> ~/RaBbLE-Collective/RaBbLE-OS/ISSUES.md
# types: BUG (broken) · GRIPE (works but wrong) · WISH (nice-to-have)
```

---

```
RaBbLE-OS · Episode 1 (Genesis) · Developer Preview · v0.0.0.1
The body, unfinished. Genesis shows you the shape. Exodus makes it reliable.
```
