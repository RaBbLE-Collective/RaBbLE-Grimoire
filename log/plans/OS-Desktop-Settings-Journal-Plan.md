# Plan: RaBbLE-OS desktop settings: journal, reminder, promote (first bLE slice)

**Status:** 🔵 S328 design, not started. Scoped with Mark 2026-11-12.
**Repo:** RaBbLE-OS `new-horizons` · **Source home (when built):** `RaBbLE-OS/desktop/` (code in member, this doc in Grimoire)
**Goal:** Wallpaper, cursor and pointer/touchpad settings that carry across Hyprland, niri, GNOME and KDE, edited locally, with each local change logged and later offered for promotion into the RaBbLE-OS defaults and the Grimoire.

## Decisions (Mark, S328)

- **Repo is Mark's source of truth**, tracked in git, deployed with `dotctl` from the Collective root, so all his machines match. RaBbLE-OS is a shared surface: other users keep their own config however they like.
- **Settings are edited locally.** The pane (or a hand edit) changes the deployed file only. Nothing writes the repo directly.
- **Promotion is delayed and asked.** A change is logged; a few days later a reminder asks whether to pull it into RaBbLE-OS (`dotctl pull`) and note it in the Grimoire. Mark approves each one.
- **Reminder and logging come first.** No pane, no learning in phase 1.
- **This is the first bLE part in the OS** (observe, learn, infer, delegate-with-consent). Longer goal: sCoRE infers workspace groups and their function.
- **Workspace names are personal, not OS config.** RaBbLE-OS ships default groups `RaBbLE`, `Personal`, `Work`, `Scratch` (`Comms` optional). Mark's own (e.g. Incenergy) live in his user layer.

## Layout

```
RaBbLE-OS/config/desktop.toml            shipped defaults (git, dotctl bundle `desktop`)
~/.config/rabble/desktop.toml            deployed copy, the locally edited file
~/.local/state/rabble/desktop-changes.jsonl   change journal, one JSON object per change
```

`desktop.toml` holds only what should be identical everywhere: wallpaper path, cursor theme + size, pointer and touchpad (accel profile/speed, natural scroll, tap, scroll factor). Per-machine facts (scale, outputs) stay in `machine.conf` and rdisplay profiles.

A compositor adapter turns the file into native config: Hyprland input/cursor block, niri `input`/`cursor`, `swaybg` for wallpaper (one daemon for Hyprland, niri, sway), gsettings/kwriteconfig for GNOME/KDE.

## Journal contract (the stable part; a learner reads this later)

```json
{"t":"2026-11-12T15:04:56Z","host":"rabble-os","key":"cursor.size","old":32,"new":24,"src":"pane|hand|dotctl"}
```

Append-only. `src` says how it changed. A later change to the same key restarts that key's clock.

## Phases

1. **Journal + reminder.** Detect a diff between the deployed file and `config/desktop.toml` (`dotctl diff desktop` already exists), append journal entries, a systemd user timer raises one batched mako notification per day for entries older than 3 days (configurable). Actions: promote, keep local, revert. Promote runs `dotctl pull desktop`, stages the repo change, and drafts the Grimoire line. Commit and Grimoire write stay Mark's to approve.
2. **Apply.** `rdesk apply` writes the compositor adapters (niri and Hyprland first).
3. **Pane.** Extend rdisplay or the Settings App (see open question 1) to edit the local file.
4. **Learner.** sCoRE or a RaBbLE component replaces the fixed 3-day timer: which keys settle fast, which keep churning, which groups of workspaces recur. Local-first; not wired to sCoRE until Mark rules the entity ready.

## Open questions (Mark)

1. **Pane stack.** `OS-Settings-App-Plan.md` decided a local Aether web app, not GTK4. `rdisplay` already ships a GTK4 editor and a web editor. Which carries these pages?
2. **Journal visibility to sCoRE.** Local only in phases 1 to 3?
3. **Grimoire destination** for promoted changes: session log line, or a settings changelog (check this index's conventions first).
4. **Workspace groups** (RaBbLE, Personal, Work, Scratch, Comms?) as part of `desktop.toml` or a separate `workspaces.toml`.

## Sources

`OS-Display-Manager-Plan.md` · `OS-Settings-App-Plan.md` · `RaBbLE-OS/display-manager/README.md` · `RaBbLE-OS/RaBbLE-OS-dotctl.sh` (`diff`, `pull`) · `RaBbLE-OS/config/niri/config.kdl` · `RaBbLE-Grimoire/gist/RaBbLE-Integration-Map-gist.md` (observation loop)
