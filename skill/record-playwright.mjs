// record-playwright.mjs — generic Playwright driver for the talk-html skill.
//
// Drives a real Chromium across a list of routes against a real local server
// and records the whole session to a .webm video. Called by record-to-gif.sh;
// can also be run standalone.
//
// Env in:
//   BASE_URL    e.g. http://127.0.0.1:4178   (required)
//   ROUTES      JSON array of paths, e.g. ["/","/org"]   (default ["/"])
//   OUT_DIR     directory for the .webm + run-log.json   (required)
//   VIEWPORT_W  viewport width  (default 1180)
//   VIEWPORT_H  viewport height (default 760)
//   HOLD_MS     ms to dwell on each route (default 900)
//
// Out: <OUT_DIR>/page@*.webm  and  <OUT_DIR>/run-log.json
import { chromium } from 'playwright';
import fs from 'node:fs';

const BASE = process.env.BASE_URL;
if (!BASE) { console.error('record-playwright: BASE_URL required'); process.exit(2); }
const OUT_DIR = process.env.OUT_DIR;
if (!OUT_DIR) { console.error('record-playwright: OUT_DIR required'); process.exit(2); }
fs.mkdirSync(OUT_DIR, { recursive: true });

const routes = JSON.parse(process.env.ROUTES || '["/"]');
const W = Number(process.env.VIEWPORT_W || 1180);
const H = Number(process.env.VIEWPORT_H || 760);
const HOLD = Number(process.env.HOLD_MS || 900);

const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: W, height: H },
  deviceScaleFactor: 1,
  recordVideo: { dir: OUT_DIR, size: { width: W, height: H } },
});
const page = await context.newPage();

const log = [];
for (const route of routes) {
  const url = BASE + route;
  const t0 = Date.now();
  try {
    const resp = await page.goto(url, { waitUntil: 'networkidle', timeout: 15000 });
    await page.waitForTimeout(HOLD);
    const h = await page.evaluate(() => document.body.scrollHeight);
    if (h > W * 0.8) {
      await page.evaluate(() => window.scrollTo({ top: document.body.scrollHeight / 2, behavior: 'smooth' }));
      await page.waitForTimeout(700);
      await page.evaluate(() => window.scrollTo({ top: 0, behavior: 'smooth' }));
      await page.waitForTimeout(500);
    } else {
      await page.waitForTimeout(700);
    }
    const status = resp ? resp.status() : null;
    log.push({ route, status, ms: Date.now() - t0 });
    console.log(`OK   ${route} -> ${status} (${Date.now() - t0}ms)`);
  } catch (e) {
    log.push({ route, status: 'ERR', error: String(e).split('\n')[0], ms: Date.now() - t0 });
    console.log(`ERR  ${route} -> ${String(e).split('\n')[0]}`);
  }
}

await context.close(); // flushes the .webm
await browser.close();

const video = fs.readdirSync(OUT_DIR).find((f) => f.endsWith('.webm'));
fs.writeFileSync(OUT_DIR + '/run-log.json',
  JSON.stringify({ base: BASE, viewport: { w: W, h: H }, routes, log, video, recorded_at: new Date().toISOString() }, null, 2));
console.log('VIDEO ' + (video ? OUT_DIR + '/' + video : 'NONE'));
if (!video) process.exit(1);
