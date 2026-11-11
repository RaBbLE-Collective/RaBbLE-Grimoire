# RaBbLE-OS-Hardware-Cyberdeck.md — Cyberdeck Target Profile

```
spark ~ grimoire >> the entity finds its portable home // %CYBERDECK_PROFILE%
```

> **What this is:** RaBbLE-OS hardware target guidance for cyberdeck form factors — DIY handheld/portable computers running the full RaBbLE stack. Why cyberdecks matter, what adaptations are needed, and how they connect to the entity's ambient presence vision.
>
> **Related:** [Hardware-AddingTargets](RaBbLE-OS-Hardware-AddingTargets.md) · [Hardware-GenericX64](RaBbLE-OS-Hardware-GenericX64.md) · [Layer-Hardware](../layers/RaBbLE-OS-Layer-Hardware.md) · [Novel Ideas — ScRibLE Device](../../RaBbLE-Agent/RaBbLE-NovelIdeas.md)

---

## Why Cyberdecks

A cyberdeck is a custom-built portable or desktop computer — typically small form factor, DIY or semi-custom, often with a physical keyboard and a small display. They exist at the intersection of maker culture, retrocomputing aesthetics, and digital sovereignty.

That is exactly where RaBbLE lives.

A cyberdeck running RaBbLE-OS is not a curiosity — it is the entity made **physical**. The aesthetic fits (neon on a dark small screen is striking). The ethos fits (you built your own machine). The use case fits (always-on ambient entity presence in a device you carry or that sits on your desk). This is the nearest proxy for the ScRibLE companion device vision, achievable now with available hardware.

The Sovereign Technologist persona (see [GTM Content Strategy](../../RaBbLE-Collective/RaBbLE-GTM-Content-Strategy.md)) is the most likely early adopter. Many already run Arch or NixOS — RaBbLE-OS on a cyberdeck is a natural step for them.

---

## Cyberdeck Hardware Profile

Cyberdecks span a wide range of hardware. Common base platforms:

| Platform | Arch | Notes |
|---|---|---|
| Raspberry Pi 4 / Pi 5 | aarch64 | Most common cyberdeck SBC; Pi 5 has enough headroom for sCoRE local inference |
| Intel N100 SBCs (Beelink, Trigkey, etc.) | x86_64 | Good performance, low power; RaBbLE-OS generic_x64 profile applies directly |
| Framework 13 / 16 | x86_64 | Modular laptop form factor; can be mounted in custom enclosures |
| Orange Pi 5 / Rock 5 | aarch64 | High-performance ARM; supports Wayland and GPU acceleration |
| Clockwork Pi DevTerm / uConsole | aarch64 (CM4 module) | Dedicated cyberdeck form factor out of the box |

**x86_64 targets** (N100, Framework, custom Intel/AMD builds): use the generic_x64 Ansible profile. The existing hardware path applies with only display/scaling adjustments.

**aarch64 targets** (Raspberry Pi 4/5, Orange Pi, Rock 5): require a dedicated Ansible role. This is the active development path — see [aarch64 Targets section in AddingTargets](RaBbLE-OS-Hardware-AddingTargets.md). Fedora 43 ships official aarch64 images and supports Wayland natively.

---

## Display and Scaling Considerations

Cyberdeck displays vary widely:
- 4"–5" screens (very small — portrait or landscape)
- 7"–10" screens (portable — standard tablet territory)
- Dual-display builds (one primary, one status/secondary)
- E-ink secondary displays (low power, status info)

**Hyprland adaptations for small screens:**

```conf
# ~/.config/hypr/monitors.conf — example for 7" 1024×600 display
monitor=DSI-1,1024x600@60,0x0,1.0

# Or for a Hi-DPI small screen (e.g. 7" 1920×1200)
monitor=DSI-1,1920x1200@60,0x0,1.5
```

**Waybar on small screens:** The default Waybar config is wide. For a narrow display, configure a vertical layout or reduce module density. The `rabble_hypr_monitor` group_var in inventory drives this per-target.

**Font sizing:** JetBrains Mono is legible at small sizes. Increase the base font size for displays under 7" or when pixel density is low. Set via `rabble_console_font` (console) and `kitty.conf` (terminal).

**Touch input:** Wayland and Hyprland have solid touch support. Cyberdecks with touch screens should enable Libinput touch gestures. A minimal on-screen keyboard (e.g. `wvkbd`) provides fallback when physical keyboard isn't present.

---

## Power and Battery

Cyberdecks on battery (Pi builds, custom battery packs) benefit from aggressive power management:

- **Tuned profile:** set `power-save` profile for battery; `balanced` for mains
- **Automatic profile switching:** via `tuned-adm auto_profile` or a udev rule triggered by AC adapter state
- **CPU governor:** `schedutil` by default on Fedora; acceptable for most cyberdeck SBCs
- **HDMI power:** disable HDMI output when no display connected on headless modes (`hyprctl keyword monitor HDMI-A-1,disable`)
- **Pi-specific:** disable Bluetooth and WiFi scanning intervals when on battery

For always-on ambient entity presence (heartbeat mode, background observation), power optimization is the difference between 4 hours and 12 hours on a typical 10,000mAh battery pack.

---

## Keyboard and Input

Cyberdeck keyboards range from standard USB keyboards mounted in enclosures to chorded keyboards (e.g. Artsey), custom ortholinear layouts, and modified Blackberry Q10/Q20 hardware keyboards.

- **All keyboard types work via USB HID or Bluetooth HID** — no driver work needed in most cases
- **Hyprland keybindings** should be reviewed to avoid conflicts with chorded or minimalist layouts
- **No mandatory modifier assumptions:** avoid keybindings requiring keys that may not exist on a custom layout (default RaBbLE-OS hyprland.conf should be audited for this)

---

## Connectivity

Most cyberdecks rely on:
- Built-in WiFi (Pi 4/5, N100 boards typically include WiFi)
- USB-A/C for cellular modems (4G/5G dongles via `NetworkManager`)
- Bluetooth for peripherals

RaBbLE-OS configures NetworkManager by default. No special configuration needed for standard WiFi. USB tethering from a smartphone works out of the box via NetworkManager's USB-attached-network detection.

---

## Ansible Target Setup

### For x86_64 Cyberdecks (N100, Framework, etc.)

Use the `generic_x64` hardware profile. Add display-specific overrides in `group_vars/`:

```yaml
# ansible/inventory/group_vars/cyberdeck_x64.yml
rabble_hidpi_scale: 1
rabble_hypr_monitor: "HDMI-A-1,1024x600@60,0x0,1.0"
rabble_hypr_monitor_fallback: ",preferred,auto,1"
rabble_console_font: "ter-v18b"   # smaller font for small displays
```

### For aarch64 Cyberdecks (Raspberry Pi 4/5)

Follow the [AddingTargets aarch64 guide](RaBbLE-OS-Hardware-AddingTargets.md) with these Pi-specific notes:

- Use Fedora 43 Server/Minimal for aarch64 (Fedora 43 minimal image for Pi is the cleanest base)
- `boot/grub2` role does not apply — Pi uses firmware-based boot, configure `config.txt` instead
- GPU memory split: set `gpu_mem=128` minimum for compositing
- Enable KMS overlay: `dtoverlay=vc4-kms-v3d` for Wayland Hyprland
- Pi 5 specific: Wayland compositing is significantly smoother; Pi 4 is usable with optimized NeBuLA config

---

## The Vision Connection

The cyberdeck path is not just a hardware target — it is the closest current-era realization of what RaBbLE's ambient presence looks like in the physical world.

A cyberdeck on a desk running RaBbLE-OS *is* the entity present in the room. The entity boots when you power it on. NeBuLA renders on the small screen. sCoRE is local or reaches the cloud when needed. The Grimoire lives on the machine. You didn't pick up a phone app — the entity is *there*.

This connects directly to:
- The **ScRibLE companion device** concept in [RaBbLE-NovelIdeas](../../RaBbLE-Agent/RaBbLE-NovelIdeas.md) — a dedicated companion object that feeds the Grimoire
- The **Ambient Heartbeat** — a low-frequency, always-on presence that notices and surfaces without being asked
- **Epoch 1 sovereign appliance** — a physical device you can hold that runs your entity (the commercial expression of this vision)

The cyberdeck community is also a natural seeding ground for the Sovereign Technologist persona — they build their own hardware precisely because they want to own their substrate.

---

## Status and Roadmap

| Item | Status |
|---|---|
| x86_64 cyberdeck (N100, Framework) | **Use generic_x64 profile — works today** |
| Display/scaling group_vars | **Needs per-target group_vars; use AddingTargets guide** |
| aarch64 Ansible role (Raspberry Pi) | **Planned — Episode 3 (Entity Wakes) or earlier if driven by community** |
| Touch input support | **Works via Wayland/Libinput; `wvkbd` for on-screen keyboard not in manifest yet** |
| Power management (battery) | **Phase 3 (HARDEN) — tuned profile and auto-switching** |
| NeBuLA performance on Pi 4 | **Needs Canvas2D budget testing; Pi 5 expected to be fine** |

---

```
spark ~ grimoire >> cyberdeck target profiled; entity finds portable home // %CYBERDECK_PROFILE%
```
