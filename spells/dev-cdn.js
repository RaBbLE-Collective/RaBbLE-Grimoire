#!/usr/bin/env node
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const RABBLE_ROOT = path.dirname(path.dirname(__dirname));
const AETHER_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-Aether');
const NEBULA_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-NeBuLA');
const WORLD_ROOT = path.join(RABBLE_ROOT, 'RaBbLE-World');

const PORT = 8000;
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
