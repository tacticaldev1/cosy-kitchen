// Renders every ingredient and every dish onto two contact sheets so art changes can be reviewed at a glance.
// Run: npm run sheets   → tests/sheet-ingredients.png and tests/sheet-dishes.png
import { chromium } from 'playwright';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const url = pathToFileURL(join(root, 'dist', 'index.html')).href;
const browser = await chromium.launch();
for (const mode of ['ingredients', 'dishes']){
  const page = await browser.newPage({ viewport: { width: 1500, height: 1600 } });
  await page.goto(url); await page.waitForTimeout(600);
  await page.evaluate(mode => {
    const k = window.__ck, cell = 150, cols = 10;
    const items = mode === 'ingredients' ? Object.keys(k.ING) : k.RECIPES.map(r => r.id);
    const c = document.createElement('canvas'); c.width = cols * cell; c.height = Math.ceil(items.length / cols) * cell; c.id = 'sheet';
    const g = c.getContext('2d'); g.fillStyle = '#FFF4EC'; g.fillRect(0, 0, c.width, c.height);
    items.forEach((it, i) => { const x = (i % cols) * cell + cell / 2, y = Math.floor(i / cols) * cell + cell / 2;
      if (mode === 'ingredients') k.drawIng(g, it, x, y - 8, 46); else k.drawArt(g, k.recipeSpec(k.RECIPES[it]), x, y - 4, .82);
      g.fillStyle = '#3B2340'; g.font = '700 12px sans-serif'; g.textAlign = 'center'; g.fillText(mode === 'ingredients' ? k.ING[it].n : k.RECIPES[it].n, x, y + cell / 2 - 8); });
    document.body.innerHTML = ''; document.body.appendChild(c);
  }, mode);
  await (await page.$('#sheet')).screenshot({ path: join(root, 'tests', `sheet-${mode}.png`) });
  console.log(`Saved tests/sheet-${mode}.png`);
}
await browser.close();
