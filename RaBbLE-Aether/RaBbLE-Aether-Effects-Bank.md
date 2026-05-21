# RaBbLE-Aether-Effects-Bank.md — Saved Visual Effects

```
transcribe ~ aether >> effects bank: discovered effects worth revisiting // %EFFECTS_BANKED%
```

> Visual effects discovered during development — often accidents — that are too good to lose but not yet scheduled. When an effect is integrated, move its entry to the relevant architecture doc and note where it landed.

---

## Cotton Candy Swirl (Applet Fill)

**Discovered:** Session 20 (May 2026) while implementing Hyprland-style animated tile borders for RaBbLE-World.

**What it looks like:** A rotating `conic-gradient` (`cyan → magenta → violet`) washes across the entire applet face through a semi-transparent interior. The gradient rotates continuously, making the whole panel ripple like a rotating aurora / candy nebula.

**How it was found:** The `linear-gradient(rgba(10,0,16,0.5),...) padding-box` interior was too transparent, so the `conic-gradient(...) border-box` bled through the entire surface — an accident that looked spectacular.

**CSS to reproduce:**

```css
.applet {
  border: 1.5px solid transparent;
  background:
    linear-gradient(rgba(10,0,16,0.50), rgba(10,0,16,0.50)) padding-box,
    conic-gradient(
      from var(--applet-angle),
      var(--neon-cyan)    0%,
      var(--neon-magenta) 45%,
      var(--neon-violet)  65%,
      var(--neon-cyan)    100%
    ) border-box;
  animation: applet-border-chase 3s linear infinite;
}

@property --applet-angle {
  syntax: '<angle>';
  inherits: false;
  initial-value: 0deg;
}

@keyframes applet-border-chase {
  to { --applet-angle: 360deg; }
}
```

**Requires:** `@property` (Chrome 85+, Safari 16.4+). The `--neon-cyan`, `--neon-magenta`, `--neon-violet` tokens are in `RaBbLE-Palette.md`.

**Possible future uses:**
- Entity "speaking" or "thinking" state — applet pulses with aurora wash
- Login/auth confirmation — brief swirl on modal or stage before resolving to clean border
- New message / alert state for the log applet
- Boot sequence: panels sweep through swirl then settle to clean static border
- Plymouth boot splash: full-screen version of this wash before entity materialises

**Status:** Saved for future entity state machine. Not scheduled.

---

```
transcribe ~ aether >> effects bank live // %EFFECTS_BANKED%
```
