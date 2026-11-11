# RaBbLE-Plan-Surface.md — Living Plans via NeBuLA/World

```
spark ~ collective >> concept: plans as living NeBuLA/World documents // %PLAN_SURFACE_CONCEPT%
```

> **Status:** Concept — EP2 target. Plans are structured markdown now.
> This doc describes what they become.
> See also: [RaBbLE-VisualPlan-Protocol](../RaBbLE-Agent/RaBbLE-VisualPlan-Protocol.md)

---

## The Idea

Plans and Grimoire docs are structured markdown. They're designed to be read
by agents. They should also be readable by Mark — visually, with entity presence,
dynamic content, and the same aesthetic coherence as the rest of RaBbLE.

The Plan Surface is a World route (`/plan/:slug` or `/doc/:path`) that reads
a Grimoire markdown file and renders it as a living NeBuLA/Aether document.
Not a static page. Not a third-party app. RaBbLE rendering its own knowledge.

---

## What "Living" Means

| Markdown element | NeBuLA/Aether render |
|---|---|
| Mermaid diagram block | Animated diagram with Aether palette |
| `## Steps` checklist | Interactive checklist with live status |
| `## Mockups` / ASCII wireframe | NeBuLA canvas — actual rendered UI sketch |
| Status header (`draft/approved/done`) | Entity state indicator — entity reacts to plan status |
| Open questions block | Highlighted, entity draws attention to unresolved items |
| Session/date metadata | Timeline mini-visualization |

The entity (NeBuLA) is present throughout — the plan surface is a conversation
between Mark and RaBbLE about what to build, rendered in RaBbLE's visual language.

---

## Why This Matters

Right now agents write plans and Mark reads them as text. The information is
there but the experience is flat. The Plan Surface makes the Grimoire feel like
a living workspace — plans are documents the entity inhabits, not files.

This is also how RaBbLE eats its own cooking: the same NeBuLA canvas that
renders the entity face, boot animation, and SDDM greeter can render
architectural diagrams, UI mockups, and flow charts. One renderer. All surfaces.

---

## Scope for EP2

**Minimal slice (proves the concept):**
- World route: `/plan/:slug` reads `RaBbLE-Grimoire/log/plans/<slug>.md`
- Renders with Aether typography + palette (no custom blocks yet)
- Mermaid diagrams via existing NeBuLA canvas
- Step checklist with interactive check-off (writes back to markdown)
- Entity present in corner — reacts to plan status (draft=idle, approved=active, done=celebrate)

**Later:**
- UI mockup wireframes rendered as NeBuLA canvas artboards
- `/doc/:path` for arbitrary Grimoire docs
- Agent can write to plan doc (step completion, open question resolution)
- Plan surface accessible offline (local World serve)

---

## Source Format

Plans stay as plain markdown in `log/plans/<slug>.md`. The World renderer
parses the structure — no special syntax beyond standard markdown sections
and fenced Mermaid blocks. Any agent can write a plan without knowing about
the renderer.

The renderer is a progressive enhancement, not a dependency.

---

## Relationship to Other Members

| Member | Role |
|---|---|
| **RaBbLE-Grimoire** | Source — plans live here as markdown |
| **RaBbLE-NeBuLA** | Canvas renderer — diagrams, wireframes, entity |
| **RaBbLE-Aether** | Visual language — palette, typography, tokens |
| **RaBbLE-World** | Surface — serves `/plan/:slug`, orchestrates render |
| **RaBbLE-sCoRE** | Future — agent writes step completion back to plan |
