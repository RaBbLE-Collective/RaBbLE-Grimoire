# RaBbLE-Episode1 — gist

> Source: `RaBbLE-Collective/RaBbLE-Episode-1-Release-Map.md` | ~3,143 → ~250 tokens
> Regenerate: `bash spells/distill-gists.sh`

**What Episode 1 is:** First synchronized public release. All core members tag `v0.0.0.1` simultaneously. The Collective broadcasts together — no member advances alone.

**Exit conditions (all required):**
- Aether CSS bundle live on CDN, all World pages use it
- NeBuLA Canvas2D renders at 60fps, `<rabble-entity>` component works in World
- World live at joinrabble.world — landing page + entity display + chat surface
- sCoRE deployed on Railway, LLM endpoint reachable, World wired to it
- OS daily-driver stable, bootstrap verified on clean VM
- Grimoire gist/ current, Navigator accurate

**Current blockers:**
- sCoRE Railway deploy — unverified end-to-end
- OS VM bootstrap — needs clean-machine test (QEMU/KVM or bare metal)

**Deferred to Episode 2+:** Memory member · Three.js in NeBuLA · ScRibLE mobile PWA · Full sCoRE observation loop. Echo 1 is the bigger goal version after several Episodes.

**Tag convention:**
```bash
git tag -a "episode-1" -m "Episode 1: [description]"
```
Apply in order: Grimoire → Aether → NeBuLA → sCoRE → World → OS → Collective.

**Deploy sequence:** Phase 0 (infra) → Phase 1 (CDN assets) → Phase 2 (sCoRE API) → Phase 3 (World go-live).

→ Full doc for: per-member exit conditions detail, VM infrastructure, deployment sequence, rollback plan
