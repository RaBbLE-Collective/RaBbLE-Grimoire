# RaBbLE-World-Roadmap.md

```
transcribe ~ grimoire >> web presence and entity interaction surface mapped // %WORLD_ROADMAP_LOCKED%
```

> **Collective Context:** RaBbLE-World is the public face and orchestration layer. See `RaBbLE-Agent/RaBbLE-Grimoire-Navigator.md` for how this fits the whole picture. See `RaBbLE-Episode-1-Release-Map.md` for Episode 1 scope across all members.
> **Related:** [Collective Roadmap](../RaBbLE-Agent/RaBbLE-Roadmap.md) · [World Architecture](RaBbLE-World-Architecture.md) · [Aether Architecture](../RaBbLE-Aether/RaBbLE-Aether-Architecture.md) · [NeBuLA API](../RaBbLE-NeBuLA/RaBbLE-NeBuLA-API.md) · [sCoRE Architecture](../RaBbLE-sCoRE/RaBbLE-sCoRE-Architecture.md)

---

## Episode 1 Commitment (This Member)

**Ep1 Deliverable:** Public website with landing page, grimoire browser, and basic chat interface

**Status:** Planned (depends on Aether + sCoRE)

**What ships:**
- [ ] Landing page: introduces RaBbLE, invites to join
- [ ] Grimoire browser: read-only documentation viewer (embedded or snapshot)
- [ ] Chat interface: basic UI calling sCoRE endpoint
- [ ] Aether CSS imported for styling
- [ ] NeBuLA rendering integrated for visual coherence
- [ ] Deployed to Cloudflare Workers

**Blockers:**
- Aether CSS published to CDN (needed for styling)
- sCoRE endpoint deployed and live (needed for chat to function)

**Dependencies:**
- Aether CSS bundle
- NeBuLA IIFE script
- sCoRE HTTP API endpoint

**Deferred to Episode 2+:**
- Real-time entity state binding
- Advanced chat features
- Interactive demos
- User authentication / accounts

---

## Architecture (Episode 1)

**Static hosting:** Cloudflare Workers  
**CDN assets:** Aether CSS, NeBuLA JS  
**Backend API:** sCoRE LLM endpoint (Groq/OpenRouter)  

---

## Revision History

| Date | Change |
|---|---|
| 2026-05-15 | Episode 1 roadmap created |

---

```
transcribe ~ world >> landing page and orchestration layer mapped // %WORLD_ROADMAP_LOCKED%
```
