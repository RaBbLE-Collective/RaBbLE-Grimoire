# Aether CDN Regression Audit — 2026-05-15 (Superseded)

Post-mortem for the Aether CDN refactor regression. Status: RESOLVED.

**Root cause (now documented in `RaBbLE-Aether/RaBbLE-Aether-Build-CDN.md`):**
- `build:watch` outputs `aether.css`; pages linked to `aether.min.css` → watcher never updated what pages loaded
- 4 of 5 World pages still referenced the deleted local `../aether/rabble.css` path
- Port 8000 held by orphaned process from prior `dev-cdn.js` invocation → silent 404s

**Permanent fix:** All World pages link to `/aether/v0.0.0.0/aether.css`. Use `dev-serve.sh` only.

See `log/SESSION-LOG.md` Session 8 for full analysis.

Do not update this file.
