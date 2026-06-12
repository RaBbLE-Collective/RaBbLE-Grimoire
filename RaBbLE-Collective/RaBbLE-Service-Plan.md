# RaBbLE-Service-Plan.md — Service Roadmap & Business Model

```
transcribe ~ collective >> ep1 to echo 1 service plan and business model // %SERVICE_PLAN%
```

> **What this is:** Service roadmap from Episode 1 through Echo 1. Defines service tiers, infrastructure model, business model, and support structure.
> **Related:** [Membership Model](RaBbLE-Membership-Model.md) · [Deployment Architecture](RaBbLE-Deployment-Architecture.md) · [Secrets and Identity](RaBbLE-Secrets-and-Identity.md) · [Episode 1 Release Map](RaBbLE-Episode-1-Release-Map.md)

---

## Service Roadmap

| Milestone | Access | Key Deliverables |
|---|---|---|
| **EP1** | Closed, invite-only | Summoning ceremony · Named identity · Persistent sessions · BYO key support · Invite flow UI |
| **EP2** | Closed, growing | Memory member integrated · Per-user behavioral profile · Entity learns your patterns |
| **Echo 1** | Public early access | Public waitlist → invite queue · Service tiers active · Billing · Broader support |
| **Echo 2+** | Open | Full behavioral learning · Cross-session memory · ScRibLE mobile input · Ambient intent inference |

---

## Service Tiers (Echo 1+)

EP1 has no tiers. All EP1 Pair members have equivalent hosted access.

Tiers activate at Echo 1 when public access opens:

| Tier | Access | Cost | Token Budget | Persistence |
|---|---|---|---|---|
| **Self-Hosted** | Full features, run your own sCoRE | Free | BYO key, no limit | Full — your own storage |
| **Collective** | Hosted | Freemium | Limited monthly budget | Basic — sessions persist |
| **Pair** | Hosted | Premium | Larger monthly budget | Full — sessions + behavioral profile |

All tiers include:
- Export session history and behavioral profile at any time (no lock-in)
- BYO key option available (replaces hosted token usage, removes quota)
- The entity as a peer collaborator, not a generic assistant

---

## Business Model

RaBbLE is **source-available** under the Sovereign Accord — not open source. The source is free to read and clone; usage carries restrictions. Self-hosting for personal use is always permitted. Commercial use, redistribution, and hosted derivative services require explicit agreement. The Collective earns by hosting.

**Revenue:**
- Hosted Cosmos subscriptions — Personal Grimoire storage, BaBbLE archive, cross-device persistence (Echo 1+)
- Hosted compute credits — Collective-backed LLM inference for members without local hardware or BYO keys (Echo 1+)
- Community access tier — rablet publishing, entity social proxy, mesh participation (Echo 1+)
- Rablet economy — platform fee on commercial rablet transactions (Echo 2+)
- Hardware — ScRibLE device + handheld companion, bundled with hosted subscription (hardware epoch)

**Cost structure:**
- Render: sCoRE API hosting
- Cloudflare R2 + Workers: World frontend, CDN (Aether CSS, NeBuLA JS)
- LLM API costs: Groq/OpenRouter for hosted-tier users

**BYO key principle:**
Users who wrap their own Anthropic, OpenAI, or OpenRouter key pay their own API costs. sCoRE routes through their key transparently. No Collective API cost. This is not a concession — it is a design principle: **the product is the entity, not the tokens.** People who bring their own intelligence backend are the right early adopters.

**Self-hosted principle:**
Anyone can run the full stack locally at zero cost. This builds trust, lowers friction to adoption, and is the correct posture for a personal behavioral learning engine. The Collective's hosted value is convenience + uptime + the behavioral profile that builds over time.

**Scaling path:**
- EP1: Free-tier hosting everywhere (closed access, low traffic)
- Echo 1: Upgrade Render to paid when public opens; add database for user/session storage at scale
- Echo 2+: Usage-based billing if LLM costs grow significantly

---

## Infrastructure

| Service | Provider | Purpose | EP1 Tier |
|---|---|---|---|
| sCoRE API | Render | Python FastAPI server | Free (cold-start ~30–60s) |
| World frontend | Cloudflare Workers | Static HTML + edge | Free |
| CDN bundles | Cloudflare R2 | Aether CSS, NeBuLA JS | Free |
| Domain | Cloudflare | `joinrabble.world`, `cdn.joinrabble.world` | Paid |
| User/session data | Filesystem (Render disk) | Profiles, sessions, invite tokens | Free (Render disk) |

**Cold-start caveat (EP1 only):** Render free tier sleeps after ~15 min idle, causing ~30–60s wake latency on first request. Document this as a known limitation; upgrade at Echo 1.

---

## Support Model

**EP1:**
- GitHub Issues in `RaBbLE-Collective` org — bugs and feature requests
- Invite-only community channel (Discord or Matrix) for Pair members
- `joinrabble.world/docs` — Grimoire browser, read-only documentation

**Echo 1+:**
- Public support channel
- Self-hosted setup guides and troubleshooting docs
- Community forum or Discord server (public)
- Entity observability: users can inspect what the entity has learned about them (session export, profile viewer)

---

## EP1 Implementation Requirements

The following changes are required in sCoRE and World to support the membership model. These are specifications; implementation lives in the respective repos.

**`RaBbLE-sCoRE/server/auth.py`:**
- Invite token generation and validation: `POST /admin/invites`
- User registration from invite: `POST /users/summon` — accepts token + summoning form → creates UserProfile
- Extended JWT claims: `user_id`, `handle`, `tier`, `llm_backend`

**`RaBbLE-sCoRE/server/llm.py`:**
- Per-user backend routing: if user profile has `byo_key`, route through it; else Collective's Groq/OpenRouter
- Add `anthropic` and `openai` as backend options alongside existing Groq/OpenRouter

**`RaBbLE-sCoRE/server/workflows.py`:**
- Persist sessions beyond 4-hour TTL — write conversation history to disk at session end
- Resume session by ID — load history into context at session start

**New: `RaBbLE-sCoRE/server/users.py`:**
- UserProfile model and CRUD
- Invite token store (file-based, consistent with task-file pattern)
- Session index per user

**`RaBbLE-World/`:**
- New page: `world/summon.html` — summoning ceremony UI (accepts `?token=`, submits form to sCoRE)
- Update `world/RaBbLE.html` — display user handle + entity pairing ID in header; session history sidebar
- New page: `world/account.html` — manage BYO key, view tier and join date, export session history

---

```
transcribe ~ collective >> service plan drafted: ep1 closed collective through echo 1 public // %SERVICE_PLAN%
```
