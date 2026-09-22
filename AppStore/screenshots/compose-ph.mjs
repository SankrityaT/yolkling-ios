// Product Hunt gallery: 1270x760 landscape, caption left, phone right.
// Renders template/landscape.html per shot into marketing/product-hunt/.
//
// Run:  node AppStore/screenshots/compose-ph.mjs
//
// Order follows what worked for the closest comparables: open on the CREATURE, not the
// UI (Urso took #1 leading with its character), then the differentiator second, so it
// lands before anyone scrolls away. See AppStore/PRODUCT-HUNT.md.
//
// Captions are held to what 1.0 actually does. Deliberately absent:
//   - a species count. 1.0 caps discovery at 32; "203" is only true from 1.0.1.
//   - "Yolks can never be bought". Plus grants 400 a month; the true line is "not on
//     their own".
// raw/03-health.png was recaptured for 1.0.1. The old one showed "connect health" and
// "maybe later", which were removed after App Review rejected them.
import { chromium } from "playwright";
import { fileURLToPath } from "url";
import path from "path";
import fs from "fs";

const dir = path.dirname(fileURLToPath(import.meta.url));
const template = "file://" + path.join(dir, "template", "landscape.html");
const rawDir = path.join(dir, "raw");
const outDir = path.join(dir, "marketing", "product-hunt");
fs.mkdirSync(outDir, { recursive: true });

const shots = [
  { out: "1-meet.png", file: "02-hatch.png", accent: "#FFC23B",
    caption: "a pet that grows when you look after yourself",
    sub: "hatch one that's only yours. pick its colour and its look." },
  { out: "2-health.png", file: "03-health.png", accent: "#73E0AE",
    caption: "your real life feeds it",
    sub: "steps and sleep from Apple Health earn its trust. they never leave your phone." },
  { out: "3-focus.png", file: "04-focus.png", accent: "#8FD0FF",
    caption: "happiest when you put the phone down",
    sub: "start a focus session and it rests and glows while you're away." },
  { out: "4-checkin.png", file: "01-hero.png", accent: "#FF94C2",
    caption: "one small check-in a day",
    sub: "tell it how you are and it sets its mood. miss a day and it just waits for you." },
  { out: "5-closet.png", file: "06-closet.png", accent: "#FFD25A",
    caption: "earn Yolks by showing up",
    sub: "spend them on hats, colours and decor. you can't buy Yolks on their own." },
  { out: "6-friends.png", file: "07-visit.png", accent: "#7B5CF0",
    caption: "visit your friends' yolks",
    sub: "wave, leave a note, swap a hat. no feed, no followers, no likes." },
];

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1270, height: 760 }, deviceScaleFactor: 2 });
for (const s of shots) {
  const img = "file://" + path.join(rawDir, s.file);
  const q = new URLSearchParams({ img, caption: s.caption, sub: s.sub, accent: s.accent });
  await page.goto(`${template}?${q}`);
  await page.evaluate(() => window.__ready);
  await page.waitForTimeout(150);
  await page.screenshot({ path: path.join(outDir, s.out), clip: { x: 0, y: 0, width: 1270, height: 760 } });
  console.log("  ", s.out);
}
await browser.close();
