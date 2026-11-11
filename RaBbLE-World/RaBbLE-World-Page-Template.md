# RaBbLE-World Page Creation Template

```
spark ~ world >> page template and easy-addition guide // %WORLD_TEMPLATE_SPEC%
```

> **For easy page creation.** Copy-paste this template to create new World pages without duplicating CSS or JS.

---

## Philosophy

New pages should:
- Reuse Aether classes (no new CSS per page)
- Reuse NeBuLA visuals (no duplicated animation code)
- Be mostly HTML + Alpine.js event handlers
- Zero component duplication

---

## Minimal Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RaBbLE — [Page Title]</title>
  
  <!-- Aether design system — all theme + components -->
  <link rel="stylesheet" href="https://aether.joinrabble.world/v0.0.0/aether.min.css">
</head>
<body>
  <div class="rabble-page">
    <!-- Header with branding -->
    <header class="rabble-nav">
      <h1 class="rabble-brand-flow">[Your Title]</h1>
    </header>

    <!-- Main content — use Aether classes -->
    <main class="rabble-container">
      <div class="rabble-grid-2">
        <div class="rabble-card">
          <h2>Card Title</h2>
          <p>Description here.</p>
        </div>
        <!-- More cards -->
      </div>
    </main>

    <!-- Entity visualization (optional) -->
    <div style="margin: 40px 0; text-align: center;">
      <canvas id="entity" width="460" height="320"></canvas>
    </div>

    <!-- NeBuLA for animations (if needed) -->
    <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
    <script src="https://nebula.joinrabble.world/v0.0.0/nebula.iife.js"></script>

    <!-- Your page logic -->
    <script>
      // Set up entity if canvas exists
      const canvas = document.getElementById('entity');
      if (canvas && window.NeBuLA) {
        const puppet = window.NeBuLA.createPuppet({
          canvas,
          particleCount: 480,
          THREE: window.THREE,
          backend: 'auto'
        });

        // Wire to page events
        // puppet.setEntityState('thinking');
      }
    </script>
  </div>
</body>
</html>
```

---

## Common Patterns

### Grid of Cards (3-column on desktop, 1 on mobile)

```html
<div class="rabble-grid-3">
  <div class="rabble-card rabble-card-cyan">
    <h3>Feature 1</h3>
    <p>Description</p>
  </div>
  <div class="rabble-card rabble-card-magenta">
    <h3>Feature 2</h3>
    <p>Description</p>
  </div>
  <div class="rabble-card rabble-card-violet">
    <h3>Feature 3</h3>
    <p>Description</p>
  </div>
</div>
```

### Interactive Button Row

```html
<div style="display: flex; gap: 12px; justify-content: center;">
  <button class="rabble-btn rabble-btn-primary">Primary Action</button>
  <button class="rabble-btn rabble-btn-cyan">Secondary</button>
  <button class="rabble-btn rabble-btn-ghost">Tertiary</button>
</div>
```

### Status Indicators

```html
<span class="rabble-status-pill">
  <span class="rabble-status-dot cyan"></span>
  Online
</span>
```

### Typography Hierarchy

```html
<!-- Large hero text -->
<h1 class="rabble-display">Main Heading</h1>

<!-- Section label -->
<span class="rabble-eyebrow">::Section Label</span>

<!-- Body -->
<p>Regular paragraph text inherits from body font.</p>

<!-- Monospace -->
<code class="rabble-mono">system.out.println();</code>
```

### Glass-effect Panel

```html
<div class="rabble-glass-heavy" style="padding: 24px; border-radius: 12px; margin: 20px 0;">
  <h3>Frosted Glass Container</h3>
  <p>Content here looks great with a glass effect background.</p>
</div>
```

---

## Don't

### ❌ Don't Add Page-Specific CSS

```html
<!-- WRONG: Never add CSS per page -->
<style>
  .my-special-button { background: #ff2d78; }
</style>
```

**Instead:** Use Aether classes or propose the component to the Grimoire.

### ❌ Don't Inline Styles (Usually)

```html
<!-- WRONG: Inline styles force overrides -->
<div style="color: #ff2d78; padding: 20px;">Styled</div>

<!-- RIGHT: Use Aether classes -->
<div class="rabble-card">Styled with Aether</div>
```

### ❌ Don't Copy-Paste Animation Code

```html
<!-- WRONG: Animation duplication -->
<script>
  // More entity setup code copied from another page
  const runtime = new window.NeBuLA.Runtime(canvas);
  // ...
</script>

<!-- RIGHT: Use createPuppet, it handles setup -->
<script>
  const puppet = window.NeBuLA.createPuppet({ canvas });
</script>
```

---

## Do

### ✅ Use Aether Classes for All Styling

```html
<div class="rabble-card">
  <h2 class="rabble-display">Title</h2>
  <p class="rabble-eyebrow">::Subtitle</p>
  <button class="rabble-btn rabble-btn-primary">Action</button>
</div>
```

### ✅ Reuse NeBuLA `createPuppet`

```js
const puppet = window.NeBuLA.createPuppet({
  canvas,
  particleCount: 480,
  THREE: window.THREE,
  backend: 'auto'
});

puppet.setEntityState('thinking');
```

### ✅ Keep Page Logic Simple

```js
// Good: minimal logic, mostly event wiring
document.getElementById('ask-btn').addEventListener('click', async () => {
  puppet.setEntityState('thinking');
  const response = await fetch('/api/query', { method: 'POST' });
  puppet.setEntityState('idle');
});
```

---

## File Organization

**Recommended layout for a new World page:**

```
world/
  RaBbLE-NewPage.html          ← HTML template (this structure)
  css/RaBbLE-NewPage.css       ← Only if ESSENTIAL (ask Grimoire first)
  js/RaBbLE-NewPage.js         ← Page-specific logic (optional)
```

**Avoid:**

```
world/
  RaBbLE-NewPage/
    components/                ← DON'T duplicate components
    styles/                    ← DON'T duplicate styles
    utils/                     ← OK for page-specific utilities
```

---

## Testing a New Page

1. Copy the minimal template
2. Replace `[Page Title]` with your title
3. Add your cards/content using Aether classes
4. Open in browser — should look cohesive with zero CSS work
5. If something looks wrong, check Aether docs first (may not be a bug)

---

## Adding a New World Page Checklist

- [ ] HTML file created using this template
- [ ] Aether CSS loaded from CDN (not local)
- [ ] No custom CSS file created (or requested Grimoire review first)
- [ ] Entity canvas + NeBuLA setup included (if needed)
- [ ] Links in nav/breadcrumbs point to new page
- [ ] Tested on desktop and mobile
- [ ] Commit message uses Pulse Protocol

---

```
spark ~ world >> page template and easy-addition guide locked // %WORLD_TEMPLATE_SPEC%
```
