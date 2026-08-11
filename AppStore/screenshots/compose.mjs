// Composites the raw simulator captures into captioned marketing screenshots at
// every App Store iPhone size. Renders template/frame.html headless per shot and
// writes AppStore/screenshots/marketing/<size>/NN-*.png.
//
// Run:  node AppStore/screenshots/compose.mjs
// Requires: npm i playwright (browsers are already cached under ms-playwright).
import { chromium } from "playwright";
import { fileURLToPath } from "url";
import path from "path";
import fs from "fs";

const dir = path.dirname(fileURLToPath(import.meta.url));
const template = "file://" + path.join(dir, "template", "frame.html");
const rawDir = path.join(dir, "raw");
const outRoot = path.join(dir, "marketing");

// Accepted App Store portrait iPhone sizes. 6.9" is the current primary; 6.5" is
// what App Store Connect asks for on the 6.5" display slot.
const sizes = [
  { name: "6.9-inch", w: 1320, h: 2868 },
  { name: "6.5-inch", w: 1284, h: 2778 },
];

const shots = [
  { file: "01-hero.png",   caption: "a little yolk that's yours", accent: "#FFC23B" },
  { file: "02-hatch.png",  caption: "hatch one of a kind",        accent: "#7B5CF0" },
  { file: "03-health.png", caption: "it grows when you live well", accent: "#73E0AE" },
  { file: "04-focus.png",  caption: "it glows while you're away", accent: "#8FD0FF" },
  { file: "05-dex.png",    caption: "collect a whole flock",      accent: "#FF94C2" },
  { file: "06-closet.png", caption: "earn it, then dress it up",  accent: "#FFD25A" },
  { file: "07-visit.png",  caption: "visit your friends' yolks",  accent: "#7B5CF0" },
  { file: "08-inbox.png",  caption: "send a little kindness",     accent: "#FF94C2" },
];

const browser = await chromium.launch();
for (const size of sizes) {
  const outDir = path.join(outRoot, size.name);
  fs.mkdirSync(outDir, { recursive: true });
  const page = await browser.newPage({ viewport: { width: size.w, height: size.h }, deviceScaleFactor: 1 });
  for (const s of shots) {
    const img = "file://" + path.join(rawDir, s.file);
    const url = `${template}?w=${size.w}&h=${size.h}&img=${encodeURIComponent(img)}&caption=${encodeURIComponent(s.caption)}&accent=${encodeURIComponent(s.accent)}`;
    await page.goto(url);
    await page.evaluate(() => window.__ready);
    await page.waitForTimeout(120);
    await page.screenshot({ path: path.join(outDir, s.file), clip: { x: 0, y: 0, width: size.w, height: size.h } });
  }
  await page.close();
  console.log("composed", size.name, `(${size.w}x${size.h})`);
}
await browser.close();
