// ================= prices (yen) =================
// Ingredient cost is one portion at a Japanese supermarket; menu prices are what a small café would charge.
const ING_COST = {apple: 150, banana: 40, strawberry: 120, blueberry: 150, orange: 60, lemon: 100, mango: 250, pineapple: 150, watermelon: 150, avocado: 180, cherry: 150,
  tomato: 80, lettuce: 60, cucumber: 50, carrot: 40, potato: 40, onion: 30, mushroom: 100, pepper: 60, corn: 120, broccoli: 150, spinach: 80, pumpkin: 150, cabbage: 60,
  egg: 25, chicken: 250, beef: 300, sausage: 80, bacon: 120, salmon: 180, tuna: 200, shrimp: 150, crab: 60, tofu: 60,
  milk: 40, cheese: 80, butter: 40, yogurt: 60, cream: 120, flour: 20, bread: 40, rice: 50, pasta: 40, noodles: 60, oats: 30, tortilla: 50, nori: 20,
  sugar: 5, honey: 40, chocolate: 100, matcha: 80, coffee: 50, soy: 5, curry: 60, ice: 5, kernels: 30, redbean: 80, syrup: 40, sprinkles: 20};
const MENU_PRICE = {'Fluffy Pancakes': 1100, 'Chocolate Pancakes': 1200, 'Blueberry Pancakes': 1200, 'Banana Pancakes': 1150, 'Strawberry Pancakes': 1300, 'Crêpes': 750, 'Sunny Fried Egg': 250, 'Scrambled Eggs': 450, 'Cheese Omelette': 700, 'Veggie Omelette': 750, 'Toast': 250, 'Egg on Toast': 450, 'French Toast': 850, 'Avocado Toast': 900, 'Porridge': 500, 'Yogurt Parfait': 650, 'Bacon & Eggs': 800, 'Full Breakfast': 1400,
  'Strawberry Smoothie': 600, 'Banana Smoothie': 550, 'Berry Blast': 650, 'Mango Lassi': 600, 'Tropical Smoothie': 700, 'Green Smoothie': 650, 'Chocolate Milkshake': 650, 'Strawberry Milkshake': 650, 'Lemonade': 450, 'Orange Juice': 450, 'Watermelon Juice': 500, 'Hot Chocolate': 500, 'Matcha Latte': 550, 'Iced Matcha': 580, 'Café Latte': 480, 'Honey Lemon Tea': 450,
  'Salmon Maki': 600, 'Tuna Maki': 650, 'Cucumber Maki': 350, 'California Roll': 800, 'Futomaki': 900, 'Onigiri': 200, 'Salmon Onigiri': 320, 'Salmon Nigiri': 380, 'Tuna Nigiri': 420, 'Tamagoyaki': 450, 'Shoyu Ramen': 900, 'Chicken Ramen': 980, 'Yakisoba': 750, 'Japanese Curry': 850, 'Katsu Curry': 1100, 'Oyakodon': 850, 'Okonomiyaki': 950, 'Gyoza': 550, 'Mochi': 400, 'Dorayaki': 300, 'Shrimp Tempura': 1100, 'Honey Toast': 950,
  'Spaghetti Pomodoro': 1000, 'Mac & Cheese': 900, 'Carbonara': 1200, 'Margherita Pizza': 1400, 'Pepperoni Pizza': 1500, 'Hamburger': 1000, 'Cheeseburger': 1100, 'Hot Dog': 600, 'Roast Chicken': 1600, 'Fish & Chips': 1300, 'Fried Rice': 750, 'Veggie Stir-fry': 800, 'Tacos': 900, 'Grilled Cheese': 700,
  'Tomato Soup': 550, 'Pumpkin Soup': 600, 'Corn Soup': 500, 'Mushroom Soup': 600, 'Chicken Noodle Soup': 750, 'Beef Stew': 1200,
  'Garden Salad': 600, 'Fruit Salad': 650, 'Popcorn': 300, 'Butter Popcorn': 350, 'Caramel Popcorn': 400, 'Fries': 400, 'Guacamole': 700, 'Corn on the Cob': 350, 'Cheesy Nachos': 750,
  'Chocolate Chip Cookies': 400, 'Sugar Cookies': 350, 'Vanilla Cupcakes': 450, 'Chocolate Cupcakes': 500, 'Strawberry Shortcake': 650, 'Chocolate Cake': 600, 'Carrot Cake': 600, 'Apple Pie': 650, 'Banana Bread': 450, 'Brownies': 450, 'Strawberry Ice Cream': 450, 'Matcha Ice Cream': 480, 'Mango Sorbet': 450, 'Purin': 350, 'Rainbow Popsicle': 450};
for (const r of RECIPES){ r.price = MENU_PRICE[r.n] || 500; r.cost = r.need.reduce((a, k) => a + (ING_COST[k] || 0), 0); if (!MENU_PRICE[r.n]) console.warn('no price', r.n); }
const yen = n => (n < 0 ? '−¥' : '¥') + Math.abs(Math.round(n)).toLocaleString('en-GB');

// ================= extra sounds =================
SND.coin = () => { noise({dur: .04, f0: 3000, q: 4, vol: .12, wet: 0}); tone({f0: 1318.5, dur: .12, vol: .07, type: 'triangle', wet: .3}); tone({f0: 1975.5, dur: .6, vol: .07, type: 'triangle', at: .09, wet: .5}); for (let i = 0; i < 3; i++) tone({f0: 3000 + R() * 1500, dur: .15, vol: .02, at: .12 + i * .05, wet: .6}); };
SND.bell = () => { tone({f0: 1568, dur: .9, vol: .06, wet: .6}); tone({f0: 1975.5, dur: 1.1, vol: .05, at: .18, wet: .6}); };
SND.note = () => { noise({dur: .12, f0: 1800, f1: 3200, q: 1.5, vol: .08}); tone({f0: 880, f1: 1100, dur: .1, vol: .05, at: .05, wet: .3}); };
SND.sigh = () => { tone({f0: 520, f1: 300, dur: .6, vol: .05, type: 'triangle', wet: .4}); };

// ================= shop & customers =================
const NAMES = ['Mina', 'Haru', 'Yuki', 'Sora', 'Koko', 'Riku', 'Nana', 'Taro', 'Momo', 'Kai', 'Emi', 'Ren', 'Aoi', 'Hana', 'Ken', 'Rin'];
const LOOKS = [['#4B2E5A', '#8B7BC9', '#FFE2D2'], ['#E8A04A', '#7FD3B8', '#FFE6D6'], ['#6A4AC8', '#FF9EBB', '#FFE2D2'], ['#3A2A2A', '#FFD24A', '#F2CDB0'], ['#F2B8C8', '#A9C8FF', '#FFEADF'], ['#8A4A2A', '#B7E3A0', '#FFDCC8'], ['#2E3A5A', '#FFB86A', '#F6D2BC']];
const SEATS = [240, 285, 330];
const shop = {open: false, day: 1, customers: [], nextT: 0, active: null, uid: 1, stats: null};
try { shop.day = +localStorage.getItem('ck-day') || 1; } catch (e) {}
const newStats = () => ({served: 0, walked: 0, sales: 0, spend: 0, stars: 0});
function paused(){ return !$('book').hidden || !$('result').hidden || !$('hello').hidden || !$('ticketSheet').hidden; }
function stepsOf(r){ return buildSteps(r).length; }
function pickOrder(){
  const served = shop.stats ? shop.stats.served : 0;
  let pool = RECIPES.filter(r => stepsOf(r) <= (served < 3 ? 4 : served < 8 ? 5 : 9));
  const w = pool.map(r => (found.has(r.id) ? 1.4 : 1) / Math.max(1, stepsOf(r) - 2)), tot = w.reduce((a, b) => a + b, 0);
  let x = R() * tot; for (let i = 0; i < pool.length; i++){ x -= w[i]; if (x <= 0) return pool[i].id; } return pool[0].id;
}
function freeSeat(){ return SEATS.findIndex((_, i) => !shop.customers.some(c => c.seat === i)); }
function spawnCustomer(){
  const seat = freeSeat(); if (seat < 0) return;
  const used = new Set(shop.customers.map(c => c.name)), names = NAMES.filter(n => !used.has(n));
  const c = {id: shop.uid++, name: names[Math.floor(R() * names.length)], look: LOOKS[Math.floor(R() * LOOKS.length)], buns: R() < .45, seat, x: 440, state: 'enter', t: clock, patience: 75, max: 75, order: null, mood: null, moodT: 0, bob: R() * TAU};
  shop.customers.push(c); SND.bell();
}
function orders(){ return shop.customers.filter(c => c.state === 'order'); }
function activeCust(){ return shop.customers.find(c => c.id === shop.active && c.state === 'order') || null; }
function setActive(c){ shop.active = c ? c.id : null; pinned = c ? c.order : null; guideCache.t = -1; save(); }
function nextActive(){ const os = orders().sort((a, b) => (a.patience / a.max) - (b.patience / b.max)); setActive(os[0] || null); }
function takeOrder(c){
  const rid = pickOrder(), r = RECIPES[rid], steps = stepsOf(r);
  c.order = rid; c.state = 'order'; c.max = c.patience = 100 + 30 * Math.max(0, steps - 2); c.t = clock; SND.note(); buzz(8);
  setActive(c); openTicket(rid, c);
}
function orderFor(rid){ return orders().filter(c => c.order === rid).sort((a, b) => a.patience - b.patience)[0] || null; }
function leave(c, sad){ c.state = 'leave'; c.t = clock; c.mood = sad ? 'yuck' : 'happy'; c.moodT = clock + 3; if (shop.active === c.id) nextActive(); }
function toggleShop(){
  initAudio();
  if (!shop.open){ shop.open = true; shop.stats = newStats(); shop.nextT = clock + 1.5; SND.bell(); toast(`Day ${shop.day}: the shop is open!`); return; }
  shop.open = false; for (const c of shop.customers) if (c.state !== 'leave'){ c.state = 'leave'; c.t = clock; }
  setActive(null); showSummary(); shop.day++; save();
}
function chargeIng(key){ const cost = ING_COST[key] || 0; wallet -= cost; if (shop.open && shop.stats) shop.stats.spend += cost; save(); return cost; }
function shopUpdate(dt){
  const stop = paused();
  if (shop.open && !stop && clock > shop.nextT && freeSeat() >= 0){ spawnCustomer(); shop.nextT = clock + 16 + R() * 18; }
  for (const c of shop.customers){
    const tx = SEATS[c.seat];
    if (c.state === 'enter'){ c.x += (tx - c.x) * Math.min(1, dt * 4); if (Math.abs(c.x - tx) < 1){ c.x = tx; c.state = 'wait'; c.t = clock; } }
    else if (c.state === 'wait' || c.state === 'order'){ if (!stop) c.patience -= dt; if (c.patience <= 0){ toast(c.state === 'wait' ? `${c.name} couldn't wait to order and left` : `${c.name} got tired of waiting`); SND.sigh(); if (shop.stats) shop.stats.walked++; leave(c, true); } }
    else if (c.state === 'eat'){ if (clock - c.t > 3.2) leave(c, false); }
    else if (c.state === 'leave'){ c.x += dt * 140; }
  }
  shop.customers = shop.customers.filter(c => c.x < 450);
}
function custAt(p){ if (p.y > 96 || p.x < 216) return null; let best = null, bd = 24; for (const c of shop.customers){ if (c.state === 'leave' || c.state === 'enter') continue; const d = Math.abs(p.x - c.x); if (d < bd){ bd = d; best = c; } } return best; }
function shopTap(p){
  if (p.x > 360 && p.y < 52){ toggleShop(); return true; }
  const c = custAt(p);
  if (c){ initAudio(); if (c.state === 'wait') takeOrder(c); else if (c.state === 'order'){ setActive(c); openTicket(c.order, c); } else if (c.state === 'eat') toast(`${c.name} is enjoying the food`); return true; }
  if (p.y < 96 && p.x < 214){ const a = activeCust(); if (a) openTicket(a.order, a); else if (!shop.open && pinned == null) toggleShop(); else if (pinned != null) openTicket(pinned, null); else { const w = shop.customers.find(c => c.state === 'wait'); if (w) takeOrder(w); } return true; }
  return false;
}
// serving to a customer
function serveOrder(c, foods, d, q){
  const r = d.match.r, isNew = !found.has(r.id), stars = q === 'burnt' ? 1 : q === 'under' ? 2 : 3, quick = c.patience / c.max > .5;
  c.state = 'eat'; c.t = clock; c.mood = stars === 1 ? 'yuck' : isNew || (stars === 3 && quick) ? 'wow' : 'happy'; c.moodT = clock + 3.2; c.ate = {foods, r};
  wallet += r.price; found.add(r.id); if (shop.stats){ shop.stats.served++; shop.stats.sales += r.price; shop.stats.stars += stars; }
  save(); if (shop.active === c.id) nextActive();
  setTimeout(() => { SND.coin(); buzz(15); floatText(`+${yen(r.price)}`, c.x, 132); burst(c.x, 110, 12, ['#FFD24A', '#FFFFFF', '#FF7EA6']);
    toast(stars === 3 ? (quick ? `${c.name}: "So fast and so tasty!"` : `${c.name}: "Delicious, thank you!"`) : stars === 2 ? `${c.name}: "Nice, but a little undercooked"` : `${c.name}: "Hmm… a bit burnt"`); }, 900);
  if (isNew) setTimeout(() => showResult({foods, q, r, isNew, stars, extras: d.match.extras, paid: r.price, cust: c.name}), 1500);
}
function showSummary(){
  const s = shop.stats || newStats(), card = $('resultCard'); card.innerHTML = '';
  const add = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; card.appendChild(e); return e; };
  add('div', 'jp', 'おつかれさま！');
  add('h2', '', `Day ${shop.day} is done`);
  const avg = s.served ? s.stars / s.served : 0;
  add('div', 'stars', s.served ? '★'.repeat(Math.round(avg)) + '<span style="color:#E3D3C0">' + '★'.repeat(3 - Math.round(avg)) + '</span>' : '');
  const grid = add('div', 'sum');
  const rows = [['Customers served', s.served], ['Walked out', s.walked], ['Sales', yen(s.sales)], ['Ingredients bought', yen(-s.spend)], ['Profit', yen(s.sales - s.spend)], ['In your purse', yen(wallet)]];
  for (const [a, b] of rows){ const x = document.createElement('span'); x.textContent = a; const y = document.createElement('span'); y.textContent = b; if (a === 'Profit') { x.className = y.className = 'tot'; } grid.appendChild(x); grid.appendChild(y); }
  add('p', '', s.served ? 'Tap the sign again whenever you want to open for another day.' : 'No customers served today. Open the shop and tap a customer to take their order.');
  const row = add('div', 'drow'); row.style.justifyContent = 'center';
  const b = document.createElement('button'); b.className = 'btn'; b.textContent = 'Keep cooking'; b.onclick = closeResult; row.appendChild(b);
  $('result').hidden = false; SND.chime(); setTimeout(() => b.focus(), 30);
}
// plate wording knows about orders
ST.plate.btn = function(){ if (!this.items.length) return null; const d = this.live(), o = d && d.match ? orderFor(d.match.r.id) : null;
  return {label: o ? `Serve ${o.name}` : shop.open && orders().length ? 'Staff meal' : 'Serve', enabled: true, ready: !!o || (!shop.open && !!(d || {}).match)}; };
ST.plate.hint = function(){
  if (!this.items.length) return orders().length ? 'Put the finished dish here, then serve it' : 'Put finished food here, then Serve it';
  const d = this.live();
  if (d && d.match){ const o = orderFor(d.match.r.id); if (o) return `<em>${d.match.r.n}</em> for ${o.name}! Serve it while it's hot`; if (shop.open && orders().length) return `That's ${d.match.r.n}, but nobody ordered it. Enjoy it as a staff meal`; return `Looks like <em>${d.match.r.n}</em>! Ready to serve`; }
  if (d && d.near) return `Almost <em>${d.near.r.n}</em>: ${missingText(d.near)}`;
  return 'A new creation? Serve it and see!';
};

// ================= drawing =================
function drawCustomer(g, c){
  const [hair, shirt, skin] = c.look, x = c.x, y = 70 + Math.sin(clock * 1.6 + c.bob) * 1.2;
  const worried = (c.state === 'wait' || c.state === 'order') && c.patience / c.max < .25;
  const mood = clock < c.moodT ? c.mood : c.state === 'eat' ? 'happy' : worried ? 'sleepy' : 'idle';
  g.save(); g.translate(x, y); g.scale(.76, .76);
  g.beginPath(); g.moveTo(-32, 64); g.quadraticCurveTo(-32, 26, 0, 24); g.quadraticCurveTo(32, 26, 32, 64); g.closePath(); fillLine(g, shirt);
  g.beginPath(); g.moveTo(-12, 25); g.lineTo(0, 36); g.lineTo(12, 25); g.closePath(); fillLine(g, '#FFFFFF', 2);
  g.beginPath(); g.ellipse(0, 4, 30, 31, 0, 0, TAU); fillLine(g, hair);
  if (c.buns) for (const k of [-1, 1]){ g.beginPath(); g.arc(k * 24, -18, 9, 0, TAU); fillLine(g, hair, 2.2); }
  ell(g, 0, 7, 24, 23, skin, 2.5);
  g.beginPath(); g.moveTo(-29, 10); g.quadraticCurveTo(-30, -26, 0, -25); g.quadraticCurveTo(30, -26, 29, 10);
  for (const [dx, dy] of [[21, -2], [15, 4], [8, -6], [0, 2], [-7, -6], [-15, 4], [-21, -2]]) g.lineTo(dx, dy);
  g.closePath(); fillLine(g, hair);
  g.beginPath(); g.arc(-4, -4, 19, Math.PI * 1.12, Math.PI * 1.42); line(g, 4, 'rgba(255,255,255,.55)');
  face(g, 0, 10, .82, mood === 'sleepy' ? 'idle' : mood);
  if (worried || mood === 'yuck'){ g.beginPath(); g.moveTo(22, -6); g.quadraticCurveTo(27, 2, 22, 4); g.quadraticCurveTo(17, 2, 22, -6); fillLine(g, '#9FD3F5', 1.5); }
  if (c.state === 'eat'){ const k = (clock - c.t) % .6 < .3; rr(g, -6, 40, 12, k ? 4 : 8, 3); g.fillStyle = '#C2415E'; g.fill(); }
  g.restore();
}
function bubble(g, x, y, w, h){ rr(g, x - w / 2, y - h / 2, w, h, 10); g.save(); g.shadowColor = 'rgba(59,35,64,.3)'; g.shadowBlur = 4 * KS; g.shadowOffsetY = 2 * KS; g.fillStyle = '#FFFFFF'; g.fill(); g.restore(); line(g, 2);
  g.beginPath(); g.moveTo(x - 5, y + h / 2 - 1); g.lineTo(x, y + h / 2 + 7); g.lineTo(x + 5, y + h / 2 - 1); g.fillStyle = '#FFFFFF'; g.fill(); g.beginPath(); g.moveTo(x - 5, y + h / 2); g.lineTo(x, y + h / 2 + 7); g.lineTo(x + 5, y + h / 2); line(g, 2); }
function patienceRing(g, x, y, r, f){ g.beginPath(); g.arc(x, y, r, -Math.PI / 2, -Math.PI / 2 + TAU * clamp(f, 0, 1)); line(g, 3.5, f > .5 ? '#5CC98E' : f > .25 ? '#FFC93C' : '#FF6A6A'); }
function drawShopOverlay(g){
  for (const c of shop.customers){
    if (c.state === 'enter' || c.state === 'leave' && clock - c.t > 1.2) continue;
    const x = c.x, y = 30, f = c.patience / c.max;
    if (c.state === 'wait'){ const pop = 1 + .08 * Math.sin(clock * 6); g.save(); g.translate(x, y); g.scale(pop, pop); bubble(g, 0, 0, 44, 30); g.fillStyle = '#FF5C8D'; g.font = '20px "Mochiy Pop One", sans-serif'; g.textAlign = 'center'; g.fillText('!', -12, 8); g.fillStyle = PLUM; g.font = '800 9px "M PLUS Rounded 1c", sans-serif'; g.fillText('order', 6, 4); g.restore(); patienceRing(g, x + 20, y - 13, 5, f); }
    else if (c.state === 'order'){ bubble(g, x, y, 44, 38); drawArt(g, recipeSpec(RECIPES[c.order]), x, y + 4, .2); patienceRing(g, x + 20, y - 17, 5.5, f); if (shop.active === c.id){ g.fillStyle = '#FFD24A'; star4(g, x - 20, y - 17, 6, clock); g.fill(); g.lineWidth = 1; g.strokeStyle = PLUM; g.stroke(); } }
    else if (c.state === 'eat' || c.state === 'leave'){ const t = (clock - c.t) % 1.2 / 1.2; g.globalAlpha = 1 - t; const hy = y + 6 - t * 18; g.beginPath(); g.moveTo(x, hy + 6); g.bezierCurveTo(x - 10, hy - 3, x - 5, hy - 10, x, hy - 3); g.bezierCurveTo(x + 5, hy - 10, x + 10, hy - 3, x, hy + 6); fillLine(g, c.mood === 'yuck' ? '#9FD3F5' : '#FF7EA6', 1.5); g.globalAlpha = 1; }
  }
  // the hanging shop sign
  const sw = Math.sin(clock * 1.3) * .04; g.save(); g.translate(380, 2); g.rotate(sw);
  g.beginPath(); g.moveTo(-10, 0); g.lineTo(-10, 10); g.moveTo(10, 0); g.lineTo(10, 10); line(g, 1.6, '#6A3E20');
  rr(g, -19, 10, 38, 36, 6); fillLine(g, shop.open ? '#FFE3EC' : '#E8D2B4', 2.2);
  g.textAlign = 'center'; g.fillStyle = shop.open ? '#D9527E' : '#7A5A3A'; g.font = '800 8px "M PLUS Rounded 1c", sans-serif'; g.fillText(shop.open ? '営業中' : '準備中', 0, 23);
  g.font = '9.5px "Mochiy Pop One", sans-serif'; g.fillStyle = PLUM; g.fillText(shop.open ? 'OPEN' : 'CLOSED', 0, 38); g.restore();
  if (!shop.open && $('hello').hidden && Math.sin(clock * 3) > 0){ g.save(); g.globalAlpha = .9; ring(g, 380, 30, 24 + Math.sin(clock * 6) * 2, 2.5, '#FF7EA6'); g.restore(); }
}
function drawShopTicket(g){
  g.save(); g.translate(14, 10); g.rotate(-.02);
  rr(g, 3, 4, 200, 80, 6); g.fillStyle = 'rgba(59,35,64,.2)'; g.fill(); rr(g, 0, 0, 200, 80, 6); fillLine(g, '#FFFDF6');
  rr(g, 80, -8, 40, 14, 3); g.fillStyle = 'rgba(255,126,166,.75)'; g.fill();
  g.textAlign = 'left'; const a = activeCust(), gd = guide(), others = orders().length - (a ? 1 : 0);
  const label = t => { g.fillStyle = '#9C7FA3'; g.font = '800 9px "M PLUS Rounded 1c", sans-serif'; g.fillText(t, 10, 17); };
  const title = t => { g.fillStyle = PLUM; g.font = '13px "Mochiy Pop One", sans-serif'; wrapText(g, t, 10, 34, 182, 14, 1); };
  const body = (t, col = PLUM) => { g.font = '700 10.5px "M PLUS Rounded 1c", sans-serif'; g.fillStyle = col; wrapText(g, t, 10, 52, 182, 13, 2); };
  if (a){ const r = RECIPES[a.order]; label(`ORDER · ${a.name.toUpperCase()} · ${yen(r.price)}${others > 0 ? `   +${others} MORE` : ''}`); title(r.n);
    body(gd ? `${gd.cur + 1}/${gd.steps.length}: ${gd.steps[gd.cur].text}` : '');
    const f = clamp(a.patience / a.max, 0, 1); rr(g, 10, 72, 180, 4, 2); g.fillStyle = 'rgba(59,35,64,.12)'; g.fill(); rr(g, 10, 72, 180 * f, 4, 2); g.fillStyle = f > .5 ? '#5CC98E' : f > .25 ? '#FFC93C' : '#FF6A6A'; g.fill(); }
  else if (shop.open){ const w = shop.customers.find(c => c.state === 'wait'); label(`DAY ${shop.day} · SHOP OPEN · ${yen(shop.stats.sales)} TAKEN`);
    if (w){ title(`${w.name} is ready to order`); body('Tap them (or this ticket) to take the order.'); } else { title('Waiting for customers…'); body('Cook something while you wait, or check the recipe book.', '#7D6283'); } }
  else if (gd){ const r = RECIPES[pinned]; label(`GUIDE · STEP ${gd.cur + 1} OF ${gd.steps.length}`); title(r.n); body(gd.steps[gd.cur].text); }
  else { label(`DAY ${shop.day} · SHOP CLOSED`); title('Free cooking'); body('Tap the OPEN sign (or here) to open the shop and serve customers.', '#7D6283'); }
  g.restore();
}
