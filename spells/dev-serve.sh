#!/usr/bin/env bash
# =============================================================================
# RaBbLE-Grimoire — dev-serve.sh
# Launch local development environment with Aether, NeBuLA, and World.
#
# Runs three parallel processes:
#   1. Aether watcher: rebuilds CSS on file changes
#   2. NeBuLA watcher: rebuilds JS on file changes
#   3. Local CDN mock: serves bundles as http://localhost:8000
#
# Usage:
#   bash spells/dev-serve.sh              — full dev environment
#   bash spells/dev-serve.sh --aether     — Aether only
#   bash spells/dev-serve.sh --nebula     — NeBuLA only
#   bash spells/dev-serve.sh --world      — World + local server only
#   bash spells/dev-serve.sh --help       — this message
#
# Access: http://localhost:8080 (opens in browser automatically)
#
# cast ~ dev >> aether + nebula + world running local, cdn mocked // %DEV_CAST%
# =============================================================================

set -euo pipefail

GRIMOIRE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RABBLE_ROOT="$(dirname "$GRIMOIRE_ROOT")"
AETHER_ROOT="$RABBLE_ROOT/RaBbLE-Aether"
NEBULA_ROOT="$RABBLE_ROOT/RaBbLE-NeBuLA"
WORLD_ROOT="$RABBLE_ROOT/RaBbLE-World"
DEV_SERVER="$GRIMOIRE_ROOT/spells/dev-cdn.js"

MAGENTA='\033[38;2;255;45;120m'
CYAN='\033[38;2;0;245;255m'
GREEN='\033[38;2;80;250;123m'
YELLOW='\033[38;2;241;250;140m'
RED='\033[38;2;224;92;111m'
RESET='\033[0m'

pulse()   { echo -e "${MAGENTA}${1}${RESET}"; }
info()    { echo -e "${CYAN}  ${1}${RESET}"; }
success() { echo -e "${GREEN}  ✓ ${1}${RESET}"; }
warn()    { echo -e "${YELLOW}  ⚠ ${1}${RESET}"; }
err()     { echo -e "${RED}  ✗ ${1}${RESET}"; }

# Parse flags
RUN_AETHER=true
RUN_NEBULA=true
RUN_SERVER=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --aether)  RUN_AETHER=true; RUN_NEBULA=false; RUN_SERVER=false; shift ;;
    --nebula)  RUN_AETHER=false; RUN_NEBULA=true; RUN_SERVER=false; shift ;;
    --world)   RUN_AETHER=false; RUN_NEBULA=false; RUN_SERVER=true; shift ;;
    --help|-h)
      sed -n '/^# Usage:/,/^#.*%/p' "$0" | sed 's/^# \?//'
      exit 0 ;;
    *) err "Unknown flag: $1"; exit 1 ;;
  esac
done

# Preflight checks
echo ""
pulse "dev-serve ~ local environment"
pulse "════════════════════════════════════════"
echo ""

if [[ ! -d "$AETHER_ROOT" ]]; then
  err "RaBbLE-Aether not found at: $AETHER_ROOT"
  exit 1
fi

if [[ ! -d "$NEBULA_ROOT" ]]; then
  err "RaBbLE-NeBuLA not found at: $NEBULA_ROOT"
  exit 1
fi

if [[ ! -d "$WORLD_ROOT" ]]; then
  err "RaBbLE-World not found at: $WORLD_ROOT"
  exit 1
fi

# Verify npm available
if ! command -v npm &> /dev/null; then
  err "npm not found. Install Node.js: https://nodejs.org/"
  exit 1
fi

# Create dev server script if missing
if [[ ! -f "$DEV_SERVER" ]]; then
  info "Creating local CDN mock server..."
  mkdir -p "$(dirname "$DEV_SERVER")"
  cat > "$DEV_SERVER" <<'DEVSERVER'
#!/usr/bin/env node
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const RABBLE_ROOT = path.dirname(path.dirname(__dirname));
const AETHER_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-Aether');
const NEBULA_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-NeBuLA');
const WORLD_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-World');

const PORT = parseInt(process.env.DEV_PORT || '8080', 10);
const HOSTNAME = 'localhost';

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  let filePath;

  // Map CDN paths to local directories
  if (parsedUrl.pathname.startsWith('/aether/')) {
    // Strip /aether/v0.0.0.0/ → look in dist/
    const file = parsedUrl.pathname.replace(/^\/aether\/[^/]+\//, '');
    filePath = path.join(AETHER_ROOT, 'dist', file);
  } else if (parsedUrl.pathname.startsWith('/nebula/')) {
    // Strip /nebula/v0.0.0.0/ → look in dist/
    const file = parsedUrl.pathname.replace(/^\/nebula\/[^/]+\//, '');
    filePath = path.join(NEBULA_ROOT, 'dist', file);
  } else {
    // Everything else from World
    filePath = path.join(WORLD_ROOT, parsedUrl.pathname === '/' ? 'index.html' : parsedUrl.pathname);
  }

  // Normalize path and prevent directory traversal
  filePath = path.normalize(filePath);
  if (!filePath.startsWith(AETHER_ROOT) && !filePath.startsWith(NEBULA_ROOT) && !filePath.startsWith(WORLD_ROOT)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  // Try to serve the file
  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        // Try index.html for directories
        const indexPath = path.join(filePath, 'index.html');
        fs.readFile(indexPath, (err, content) => {
          if (err) {
            res.writeHead(404);
            res.end(`404 Not Found: ${parsedUrl.pathname}`);
            return;
          }
          res.writeHead(200, { 'Content-Type': 'text/html' });
          res.end(content);
        });
      } else {
        res.writeHead(500);
        res.end('Internal Server Error');
      }
      return;
    }

    // Determine content type
    const ext = path.extname(filePath);
    const contentTypes = {
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'text/javascript',
      '.json': 'application/json',
      '.svg': 'image/svg+xml',
      '.map': 'application/json',
    };
    const contentType = contentTypes[ext] || 'application/octet-stream';

    res.writeHead(200, { 'Content-Type': contentType });
    res.end(content);
  });
});

server.listen(PORT, HOSTNAME, () => {
  console.log(`\x1b[38;2;0;245;255m  ✓ Local CDN mock running at http://${HOSTNAME}:${PORT}/\x1b[0m`);
  console.log(`\x1b[38;2;107;104;128m    Aether:  http://${HOSTNAME}:${PORT}/aether/v0.0.0.0/\x1b[0m`);
  console.log(`\x1b[38;2;107;104;128m    NeBuLA:  http://${HOSTNAME}:${PORT}/nebula/v0.0.0.0/\x1b[0m`);
  console.log(`\x1b[38;2;107;104;128m    World:   http://${HOSTNAME}:${PORT}/\x1b[0m`);
});
DEVSERVER
  chmod +x "$DEV_SERVER"
  success "Dev server created at: $DEV_SERVER"
fi

# Background process management
cleanup() {
  echo ""
  warn "Shutting down..."
  [[ -n "${AETHER_PID:-}" ]] && kill $AETHER_PID 2>/dev/null || true
  [[ -n "${NEBULA_PID:-}" ]] && kill $NEBULA_PID 2>/dev/null || true
  [[ -n "${SERVER_PID:-}" ]] && kill $SERVER_PID 2>/dev/null || true
  echo ""
  success "Dev environment shut down"
  exit 0
}

trap cleanup SIGINT SIGTERM

# Launch watchers and server
echo ""

if [[ "$RUN_AETHER" == true ]]; then
  info "Starting Aether watcher..."
  (cd "$AETHER_ROOT" && npm run build:watch 2>&1 | sed 's/^/  [aether] /') &
  AETHER_PID=$!
  success "Aether watcher (PID $AETHER_PID)"
fi

if [[ "$RUN_NEBULA" == true ]]; then
  info "Starting NeBuLA watcher..."
  # Check if build:watch exists, fall back to build:dev
  if npm run 2>&1 -C "$NEBULA_ROOT" | grep -q "build:watch"; then
    (cd "$NEBULA_ROOT" && npm run build:watch 2>&1 | sed 's/^/  [nebula] /') &
  else
    # Run build:dev once, then warn user
    (cd "$NEBULA_ROOT" && npm run build:dev 2>&1 | sed 's/^/  [nebula] /')
    warn "NeBuLA has no build:watch target — run 'npm run build:dev' manually for changes"
  fi
  NEBULA_PID=$!
  success "NeBuLA builder (PID $NEBULA_PID)"
fi

if [[ "$RUN_SERVER" == true ]]; then
  info "Starting local CDN mock server..."
  node "$DEV_SERVER" 2>&1 | sed 's/^/  [server] /' &
  SERVER_PID=$!
fi

echo ""
pulse "════════════════════════════════════════"
info "Dev environment ready"
info "http://localhost:${DEV_PORT:-8080}"
echo ""

# Try to open browser
if command -v xdg-open &> /dev/null; then
  xdg-open "http://localhost:${DEV_PORT:-8080}" &
elif command -v open &> /dev/null; then
  open "http://localhost:${DEV_PORT:-8080}" &
fi

# Keep running until interrupted
while true; do
  sleep 1
done
