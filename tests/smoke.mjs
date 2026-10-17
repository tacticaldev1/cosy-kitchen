// Smoke test: loads dist/index.html in headless Chromium and checks the important things still work.
// Setup once:  npm install   (installs Playwright)  then  npx playwright install chromium
// Run:         npm test
import { chromium } from 'playwright';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const url = pathToFileURL(join(root, 'dist', 'index.html')).href;
let failed = 0;
const check = (ok, msg) => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${msg}`); if (!ok) failed++; };

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 400, height: 820 }, deviceScaleFactor: 2 });
const errors = [];
page.on('pageerror', e => errors.push(String(e)));
await page.goto(url);
await page.waitForTimeout(800);
await page.click('#helloGo');

// 1. Every recipe is recognised as itself when its ingredients are cooked the right way.
const bad = await page.evaluate(() => {
  const { RECIPES, detect } = window.__ck;
  return RECIPES.filter(r => {
    const comps = r.groups.flatMap(g => g.ings.map(ing => ({ ing, tags: g.tags.map(t => t === 'hot' ? 'boil' : t === 'stir' ? 'mix' : t) })));
    const d = detect(comps); return !(d && d.match && d.match.r.id === r.id);
  }).map(r => r.n);
});
check(bad.length === 0, `all 100 recipes detect correctly${bad.length ? ': ' + bad.join(', ') : ''}`);

// 2. Cook pancakes through the real stations and serve them to a customer.
const flow = await page.evaluate(() => {
  const k = window.__ck, out = {};
  k.toggleShop(); k.spawnCustomer(); k.step(2);
  const c = k.shop.customers[0]; k.takeOrder(c); document.getElementById('ticketSheet').hidden = true;
  c.order = k.RECIPES.find(r => r.n === 'Fluffy Pancakes').id;
  const w0 = k.wallet;
  k.buyFor(k.RECIPES[c.order], c); out.inBowl = k.ST.bowl.items.length;
  k.ST.bowl.onBtn(); k.step(2);
  k.open('pan'); k.tap(0); k.ST.pan.onBtn(); k.step(5); k.ST.pan.onBtn();
  k.open('plate'); k.tap(0); out.btn = k.ST.plate.btn().label;
  k.serve(); out.state = c.state; out.paid = k.wallet - w0;
  return out;
});
check(flow.inBowl === 3, 'Buy all puts egg, flour and milk into the bowl');
check(/^Serve /.test(flow.btn), `plate offers to serve the customer (${flow.btn})`);
check(flow.state === 'eat', 'customer receives the order');
check(flow.paid > 900, `customer paid (net ¥${flow.paid} after ingredients)`);

// 3. Every dish draws without throwing.
const artErrors = await page.evaluate(() => {
  const k = window.__ck, c = document.createElement('canvas'); c.width = c.height = 300; const g = c.getContext('2d'); const bad = [];
  for (const r of k.RECIPES){ try { k.drawArt(g, k.recipeSpec(r), 150, 150, 1); } catch (e) { bad.push(r.n); } }
  return bad;
});
check(artErrors.length === 0, 'all dish art renders');

check(errors.length === 0, `no page errors${errors.length ? ': ' + errors[0] : ''}`);
await page.screenshot({ path: join(root, 'tests', 'last-run.png') });
await browser.close();
console.log(failed ? `\n${failed} check(s) failed` : '\nAll checks passed. Screenshot: tests/last-run.png');
process.exit(failed ? 1 : 0);
