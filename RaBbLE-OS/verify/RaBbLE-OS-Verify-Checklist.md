# RaBbLE-OS-Verify-Checklist.md — Bootstrap Verification

Run after `layerctl apply all` + `dotctl apply all` + reboot.

## Session

- [ ] SDDM greeter appears (not dropped to TTY)
- [ ] Hyprland session starts — wallpaper visible
- [ ] Waybar renders (clock, battery, network, workspaces)
- [ ] Function keys: volume, brightness, mic-mute (SwayOSD fires)
- [ ] `Super+Space` → Fuzzel launcher opens
- [ ] Kitty opens, RaBbLE palette visible
- [ ] Screenshots: `Print` (region), `Shift+Print` (full)
- [ ] `notify-send "test" "body"` → Mako notification fires
- [ ] Hyprlock triggers after idle or `loginctl lock-session`
- [ ] HDMI hotplug (if second display available)

## Shell

- [ ] ZSH loads with p10k prompt
- [ ] Bash loads with RaBbLE two-line prompt
- [ ] `ll`, `gs`, `rabble`, `rabble-dots` aliases work
- [ ] `fcd`, `fe`, `extract` functions available in ZSH
- [ ] `LS_COLORS`, `FZF_DEFAULT_OPTS`, `BAT_THEME` set

## Idempotency Gate

- [ ] Second `layerctl apply all` changes nothing
- [ ] `layerctl verify all` — all layers report `%STABLE%` or documented exception
- [ ] New failures go to `fix/RaBbLE-OS-KnownIssues.md`

## Episode Landing (final gate)

```bash
git checkout main
git merge --squash RaBbLE/episode-I
git commit -m "evolve ~ substrate >> episode-I crystallized // %EP1_LANDED%"
git checkout RaBbLE-OS-New-Horizons
git rebase main
```

→ `verify/RaBbLE-OS-Verify-LayerState.md` — current layer state before running this
→ `verify/RaBbLE-OS-Verify-PowerTesting.md` — power testing after session verified
