#!/usr/bin/env node
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');
const https = require('https');

const RABBLE_ROOT = path.dirname(path.dirname(__dirname));
const AETHER_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-Aether');
const NEBULA_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-NeBuLA');
const WORLD_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-World');
const XPERIMENTAL_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-Xperimental');

const PORT = parseInt(process.env.DEV_PORT || '8080', 10);
const HOSTNAME = 'localhost';

// /api/* and /health go to sCoRE through this server, so local World pages stay same-origin and need no CORS
// change on sCoRE. Default: the hosted sCoRE. DEV_API_UPSTREAM=http://localhost:8000 uses a local one instead.
const API_UPSTREAM = new URL(process.env.DEV_API_UPSTREAM || 'https://score.joinrabble.world');

function proxyApi(req, res) {
  const lib = API_UPSTREAM.protocol === 'https:' ? https : http;
  const headers = { ...req.headers, host: API_UPSTREAM.host };
  delete headers.origin;       // server to server: the upstream's browser CORS rules do not apply
  delete headers.referer;
  const up = lib.request({
    protocol: API_UPSTREAM.protocol, hostname: API_UPSTREAM.hostname, port: API_UPSTREAM.port || undefined,
    method: req.method, path: req.url, headers,
  }, (r) => {
    res.writeHead(r.statusCode, r.headers);
    r.pipe(res);               // streams, so chat SSE arrives as it is written
  });
  up.on('error', (e) => {
    if (!res.headersSent) res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ detail: 'dev proxy could not reach ' + API_UPSTREAM.origin + ': ' + e.code }));
  });
  res.on('close', () => up.destroy());
  req.pipe(up);
}

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  let filePath;

  if (parsedUrl.pathname.startsWith('/api/') || parsedUrl.pathname === '/health') return proxyApi(req, res);

  // Map CDN paths to local directories
  if (parsedUrl.pathname.startsWith('/aether/')) {
    // Strip /aether/v0.0.0.0/ → look in dist/
    const file = parsedUrl.pathname.replace(/^\/aether\/[^/]+\//, '');
    filePath = path.join(AETHER_ROOT, 'dist', file);
  } else if (parsedUrl.pathname.startsWith('/nebula/')) {
    // Strip /nebula/v0.0.0.0/ → look in dist/
    const file = parsedUrl.pathname.replace(/^\/nebula\/[^/]+\//, '');
    filePath = path.join(NEBULA_ROOT, 'dist', file);
  } else if (parsedUrl.pathname.startsWith('/examples/')) {
    // NeBuLA dev harnesses (e.g. /examples/alive.html, the entity lab)
    filePath = path.join(NEBULA_ROOT, 'examples', parsedUrl.pathname.replace(/^\/examples\//, ''));
  } else if (parsedUrl.pathname.startsWith('/studio/')) {
    const file = parsedUrl.pathname.replace(/^\/studio\//, '');
    filePath = path.join(NEBULA_ROOT, 'studio', file || 'index.html');
  } else if (parsedUrl.pathname.startsWith('/xperimental/')) {
    // Xperimental sandbox (experiments, Xperimental-Web drops), e.g. /xperimental/experiments/rabble-ball/RaBbLE-Ball.html
    filePath = path.join(XPERIMENTAL_ROOT, decodeURIComponent(parsedUrl.pathname.replace(/^\/xperimental\//, '')));
  } else {
    // Everything else from World
    filePath = path.join(WORLD_ROOT, parsedUrl.pathname === '/' ? 'index.html' : parsedUrl.pathname);
  }

  // Normalize path and prevent directory traversal
  filePath = path.normalize(filePath);
  if (!filePath.startsWith(AETHER_ROOT) && !filePath.startsWith(NEBULA_ROOT) && !filePath.startsWith(WORLD_ROOT) && !filePath.startsWith(XPERIMENTAL_ROOT)) {
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
          res.writeHead(200, { 'Content-Type': 'text/html', 'Cache-Control': 'no-store' });
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

    res.writeHead(200, { 'Content-Type': contentType, 'Cache-Control': 'no-store' });
    res.end(content);
  });
});

server.listen(PORT, HOSTNAME, () => {
  console.log(`\x1b[38;2;0;245;255m  ✓ Local CDN mock running at http://${HOSTNAME}:${PORT}/\x1b[0m`);
  console.log(`\x1b[38;2;107;104;128m    Aether:  http://${HOSTNAME}:${PORT}/aether/v0.0.0.0/\x1b[0m`);
  console.log(`\x1b[38;2;107;104;128m    NeBuLA:  http://${HOSTNAME}:${PORT}/nebula/v0.0.0.0/\x1b[0m`);
  console.log(`\x1b[38;2;107;104;128m    World:   http://${HOSTNAME}:${PORT}/\x1b[0m`);
  console.log(`\x1b[38;2;107;104;128m    sCoRE:   /api/* and /health proxied to ${API_UPSTREAM.origin}\x1b[0m`);
});
