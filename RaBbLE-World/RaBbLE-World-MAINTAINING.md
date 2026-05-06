# RaBbLE-Chat Maintenance Map

This repo is intentionally small: static HTML pages, page CSS, page JS, and two shared renderers. Start here when changing layout, transitions, or entity behavior.

## Fast Reading Order

1. `MAINTAINING.md` - this file, for the current shape of the system.
2. `RaBbLE-Boot.html` or `RaBbLE.html` - page markup only.
3. The matching page assets:
   - boot/login surface: `boot.css`, `boot.js`
   - chat surface: `chat.css`, `chat.js`
4. Shared systems only if needed:
   - `rabble-entity.js` for entity drawing internals
   - `rabble-bg.js` for ambient background effects
   - `rabble-theme.css` for palette, overlays, and shared utility styles

Avoid starting with `rabble-entity.js` unless the entity drawing itself is wrong. Most UI changes belong in page CSS or in attributes/CSS for the `rabble-entity` host.

## Page Ownership

| Surface | Markup | Styles | Behavior |
|---|---|---|---|
| Boot to login | `RaBbLE-Boot.html` | `boot.css` | `boot.js` |
| Chat | `RaBbLE.html` | `chat.css` | `chat.js` |
| Shared theme | all pages | `rabble-theme.css` | - |
| Shared entity renderer | `rabble-entity` hosts | host sizing in page CSS | `rabble-entity.js` |
| Shared background renderer | pages with ambient canvas | - | `rabble-bg.js` |

The HTML files should stay thin. Do not put page CSS or page JS back inline. The boot page also keeps SVG progress-bar styling in `boot.css`, not as `style=` attributes.

## Boot/Login Flow

`RaBbLE-Boot.html` contains the stage:

- `#entity-col` holds `<rabble-entity id="entityHost">` and the portrait-only entity brand `#ecb`.
- `#info-col` holds the landscape brand `#brand` and `#panels-wrap`.
- `#panels-wrap` stacks `#boot-panel` and `#login-panel` in the same grid cell for crossfade transitions.

`boot.js` does three jobs:

- starts `RaBbLEBackground`
- proxies boot log state changes into `#entityHost`
- runs the boot log, boot-to-login crossfade, and login button navigation

The boot-to-login transition is class-driven:

- `#boot-panel.hide` fades the boot log out.
- `#login-panel.show` fades the login form in.
- `#ecb.hide` hides the portrait brand when the login form takes over.

The login-to-chat transition is also class-driven:

- `body.boot-exit` fades the boot page out.
- after the fade, `boot.js` navigates to `RaBbLE.html`.
- `RaBbLE.html` starts with `body.chat-entry`.
- `chat.js` waits two animation frames, then adds `chat-ready` so the chat page fades in instead of popping in.

If fade behavior breaks, check these classes before touching timers.

## Chat Flow

`RaBbLE.html` is the main chat shell:

- `.top-panel` contains brand text and the `rabble-entity` host.
- `.chat-container` is populated by `chat.js`.
- `.input-bar` contains the message input and send button.

`chat.js` is a vanilla state machine:

- `state.messages` is the in-memory message list.
- `renderMessages()` redraws `.chat-container`.
- `sendMessage()` captures user input.
- `processMessage()` simulates a RaBbLE response and drives entity states through `#entityHost`.

There is no backend integration here. Keep changes local unless you are explicitly wiring this to a service.

## Entity Host Sizing

`rabble-entity.js` defines a `rabble-entity` custom element. The custom element creates an internal canvas, sizes that canvas larger than its layout box, and centers it behind the visible host. This lets particles drift into the ambient void while nearby UI draws on top.

Use the host element in markup:

```html
<rabble-entity id="entityHost" mode="idle" particle-count="480" overscan="2.55"></rabble-entity>
```

Size the visible host in page CSS:

```css
.boot-entity {
  width: min(36vw, 460px);
  aspect-ratio: 1 / 0.695;
}

@media (max-width: 640px), (orientation: portrait) {
  .boot-entity {
    width: min(78vw, 520px);
    aspect-ratio: 1 / 0.78;
  }
}
```

Rules of thumb:

- Increase host `width` when the visible entity should be larger in layout.
- Increase `aspect-ratio` when the visible layout box needs more vertical room.
- Increase the `overscan` attribute when particles still look photographically clipped.
- Keep parent containers `overflow: visible` when particles should drift behind nearby content.
- If clipping persists after host overscan is high, inspect `NEBULA_RADIUS`, `FALLOFF_RADIUS`, particle `shadowBlur`, and eye halo size in `rabble-entity.js`.

## Portrait vs Landscape Layout

Boot/login responsive layout lives in `boot.css`.

Landscape:

- `#stage` is a row.
- entity is left, info is right.
- `#info-col` centers content horizontally within its column.

Portrait:

- `#stage` is a column.
- top padding gives the entity breathing room.
- `gap` controls whitespace between the entity/brand block and the boot/login info block.
- `#info-col` starts below the entity instead of centering itself in all remaining viewport height.

If portrait whitespace feels wrong, tune this block first:

```css
@media (max-width: 640px), (orientation: portrait) {
  #stage {
    padding: max(env(safe-area-inset-top), clamp(22px, 5vh, 52px)) 16px max(env(safe-area-inset-bottom), 16px);
    gap: clamp(8px, 1.8vh, 22px);
  }
}
```

## Text Alignment

Current intent: text is centered inside its own container. This includes boot log rows, login labels/inputs, chat messages, and input text.

If future UX wants classic chat alignment again, adjust only:

- `.message.user`
- `.message.rabble`
- `.message.user .msg-label`
- `.message .msg-bubble` if introduced

## Safe Edit Checklist

Before finishing a change:

1. Keep HTML free of inline `<style>`, inline `<script>`, and `style=`.
2. Run:

```sh
node --check boot.js
node --check chat.js
node --check rabble-entity.js
```

3. Check both orientations in the existing local server:
   - `RaBbLE-Boot.html`
   - `RaBbLE.html`
4. Confirm unrelated worktree changes are not staged.

## Current Known Worktree Noise

At the time this guide was added, these paths were unrelated to the frontend cleanup:

- `RaBbLE-Login.html` deleted in the worktree
- `.codex/` untracked
- `index.html` untracked
- `refs/` untracked

Do not include them in commits unless the current task explicitly owns them.
