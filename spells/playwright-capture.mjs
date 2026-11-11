#!/usr/bin/env node
// =============================================================================
// RaBbLE-Grimoire — playwright-capture.mjs
// Headless screenshot capture via Playwright/Chromium — no Hyprland, no
// Firefox window juggling. Companion to visual-screenshot.sh's `--playwright`
// flag; run directly for headless environments or CI.
//
// Usage:
//   node playwright-capture.mjs <url> <out-path> [delayMs] [width] [height]
//
// Requires the `playwright` package + a Chromium binary. If not resolvable
// locally, run via:
//   npx --yes --package=playwright -- node playwright-capture.mjs <url> <out>
//
// cast ~ os >> headless visual capture via playwright // %VISUAL_CAST%
// =============================================================================
import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const [, , url, out, delayMsArg, widthArg, heightArg] = process.argv;

if (!url || !out) {
  console.error('Usage: node playwright-capture.mjs <url> <out-path> [delayMs] [width] [height]');
  process.exit(1);
}

const delayMs = parseInt(delayMsArg ?? '2000', 10);
const width   = parseInt(widthArg  ?? '1280', 10);
const height  = parseInt(heightArg ?? '800',  10);

mkdirSync(dirname(out), { recursive: true });

const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width, height } });
  await page.goto(url, { waitUntil: 'load' });
  await page.waitForTimeout(delayMs);
  await page.screenshot({ path: out });
  console.log(`SCREENSHOT: ${out}`);
} finally {
  await browser.close();
}
