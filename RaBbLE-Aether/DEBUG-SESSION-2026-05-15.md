# Aether CSS Loading Debug — 2026-05-15 (Superseded)

Working document from a debugging session (status: RESOLVED).

**Root cause (now documented in `RaBbLE-Aether-Build-CDN.md` "Dev environment" section):**
- `build:watch` outputs `dist/aether.css`, NOT `dist/aether.min.css`
- World HTML pages must link to `/aether/v0.0.0.0/aether.css` in dev
- Always use `dev-serve.sh` — running `dev-cdn.js` directly orphans a process on port 8000, causing EADDRINUSE failures on next run that are hard to diagnose

See `log/SESSION-LOG.md` Session 8 for the full root cause analysis.

Do not update this file.
