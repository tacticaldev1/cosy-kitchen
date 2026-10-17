// ================= ingredients =================
// key: [name, category, shape, colour, light colour, mix colour?, mix weight?]
const ING_DEF = {
  apple: ['Apple', 'fruit', 'round', '#F2545B', '#FFE7C2'], banana: ['Banana', 'fruit', 'banana', '#FFE070', '#FFF6D6', '#FFF0B0'],
  strawberry: ['Strawberry', 'fruit', 'straw', '#F0475E', '#FFD5DD', '#FF7A92'], blueberry: ['Blueberry', 'fruit', 'cluster', '#5B6CD6', '#A9B5FF', '#7C5CC9'],
  orange: ['Orange', 'fruit', 'round', '#FF9F2E', '#FFE3B0'], lemon: ['Lemon', 'fruit', 'lemon', '#FFE24A', '#FFF8C8', '#FFF19A', .6],
  mango: ['Mango', 'fruit', 'mango', '#FFB53B', '#FFE08A'], pineapple: ['Pineapple', 'fruit', 'pine', '#FFC93C', '#FFF0A8', '#FFE27A'],
  watermelon: ['Watermelon', 'fruit', 'melon', '#FF5C77', '#FFC2CC'], avocado: ['Avocado', 'fruit', 'avo', '#7DB54A', '#E2F09A', '#B8DC7A'],
  cherry: ['Cherry', 'fruit', 'cherry', '#E0233F', '#FF8095'],
  tomato: ['Tomato', 'veg', 'round', '#F24B3B', '#FFB3A8'], lettuce: ['Lettuce', 'veg', 'leafy', '#8ED16B', '#D9F5C2'],
  cucumber: ['Cucumber', 'veg', 'long', '#4E9E57', '#D2EFB6'], carrot: ['Carrot', 'veg', 'carrot', '#FF8A2B', '#FFC48A'],
  potato: ['Potato', 'veg', 'potato', '#D9A86C', '#FFF0C8', '#F6E2B0'], onion: ['Onion', 'veg', 'onion', '#B97ACB', '#F3E2F7', '#F2E6EE', .5],
  mushroom: ['Mushroom', 'veg', 'mushroom', '#C98F65', '#FFF1E2'], pepper: ['Pepper', 'veg', 'pepper', '#F44E3F', '#FFB09E'],
  corn: ['Corn', 'veg', 'corn', '#FFD24A', '#FFF0A0'], broccoli: ['Broccoli', 'veg', 'broccoli', '#4E9E57', '#9BD27E'],
  spinach: ['Spinach', 'veg', 'leafy', '#3F8A4A', '#9BD27E'], pumpkin: ['Pumpkin', 'veg', 'pumpkin', '#FF9A3C', '#FFD199'],
  cabbage: ['Cabbage', 'veg', 'cabbage', '#BFE6A0', '#EFFAE2'],
  egg: ['Egg', 'protein', 'egg', '#FFF4E2', '#FFC93C', '#FFD45A'], chicken: ['Chicken', 'protein', 'drum', '#FFD2B8', '#FFEDE2'],
  beef: ['Beef', 'protein', 'steak', '#D9475A', '#FFC2C8', '#9A4A3A'], sausage: ['Sausage', 'protein', 'sausage', '#D9654A', '#FFB59E'],
  bacon: ['Bacon', 'protein', 'bacon', '#E8677A', '#FFE0E3'], salmon: ['Salmon', 'protein', 'fillet', '#F4895A', '#FFE3D2'],
  tuna: ['Tuna', 'protein', 'fillet', '#D63B4E', '#F57C8C'], shrimp: ['Shrimp', 'protein', 'shrimp', '#FF9C7A', '#FFE3D8'],
  crab: ['Crab stick', 'protein', 'strip', '#E9523F', '#FFF1EA'], tofu: ['Tofu', 'protein', 'block', '#FFF8E8', '#FFFFFF'],
  milk: ['Milk', 'dairy', 'carton', '#FFFFFF', '#8EC5F0', '#FFFDF8'], cheese: ['Cheese', 'dairy', 'wedge', '#FFD54A', '#FFF0A0'],
  butter: ['Butter', 'dairy', 'stick', '#FFE58A', '#FFF6C8', '#FFE58A', .3], yogurt: ['Yogurt', 'dairy', 'tub', '#FFF5F8', '#FF9EBB', '#FFF8FA'],
  cream: ['Cream', 'dairy', 'carton', '#FFFFFF', '#FFB3CF', '#FFFBF6'],
  flour: ['Flour', 'grain', 'bag', '#F7F1E6', '#E8C9A0', '#FBF3E4'], bread: ['Bread', 'grain', 'bread', '#E8B26A', '#FFF0D2'],
  rice: ['Rice', 'grain', 'sack', '#FFFFFF', '#9FD3C0', '#FFFFFF'], pasta: ['Pasta', 'grain', 'pasta', '#F7D27A', '#FFF0C0'],
  noodles: ['Noodles', 'grain', 'noodle', '#F6E0A0', '#FFF6D8'], oats: ['Oats', 'grain', 'bag', '#E8D2A6', '#C8A878', '#E8D6B0'],
  tortilla: ['Tortilla', 'grain', 'tortilla', '#F2D49B', '#FFF0D0'], nori: ['Nori', 'grain', 'sheet', '#1F2C25', '#3F5E4C', '#1F2C25', .2],
  sugar: ['Sugar', 'pantry', 'bag', '#FFFFFF', '#FFB7CF', '#FFFFFF', .2], honey: ['Honey', 'pantry', 'jar', '#F6B73C', '#FFE29A', '#F6C25A', .35],
  chocolate: ['Chocolate', 'pantry', 'bar', '#6B3A26', '#A0674A'], matcha: ['Matcha', 'pantry', 'tin', '#8CC152', '#D7F0B8', '#9BCB5E'],
  coffee: ['Coffee', 'pantry', 'tin', '#6B4430', '#C79A7A', '#7A4A30'], soy: ['Soy sauce', 'pantry', 'bottle', '#4A2618', '#F06A4A', '#6A3A22', .25],
  curry: ['Curry roux', 'pantry', 'box', '#C8812E', '#FFD27A', '#B8732A'], ice: ['Ice', 'pantry', 'cube', '#DFF4FF', '#FFFFFF', '#EAF6FF', .2],
  kernels: ['Popcorn', 'pantry', 'kernel', '#FFD24A', '#FFFBEA'], redbean: ['Red bean', 'pantry', 'jar', '#7A2E3A', '#E8A0A8'],
  syrup: ['Syrup', 'pantry', 'bottle', '#B4642A', '#E8A05A', '#B4642A', .3], sprinkles: ['Sprinkles', 'pantry', 'sprink', '#FF7EA6', '#7FD3F7', '#FFD0E0', .1],
};
const ING = {};
for (const [k, [n, cat, sh, c, c2, mix, w]] of Object.entries(ING_DEF)) ING[k] = {key: k, n, cat, sh, c, c2, mix: mix || c, w: w ?? 1};
const CATS = [['fruit', 'Fruit'], ['veg', 'Veg'], ['protein', 'Protein'], ['dairy', 'Dairy'], ['grain', 'Grains'], ['pantry', 'Pantry']];
const LEAFY = new Set(['lettuce', 'spinach', 'cabbage']), FRUIT = new Set(Object.keys(ING).filter(k => ING[k].cat === 'fruit'));
const LIQUID = new Set(['milk', 'cream', 'yogurt', 'coffee', 'matcha', 'chocolate', 'honey', 'lemon', 'soy', 'syrup']);
const PROTEIN = new Set(Object.keys(ING).filter(k => ING[k].cat === 'protein'));

function drawIng(g, key, x, y, s){
  const it = ING[key]; if (!it) return;
  const lw = Math.max(1.2, s * .09), c = it.c, c2 = it.c2;
  g.save(); g.translate(x, y); g.lineJoin = 'round'; g.lineCap = 'round';
  const out = (f) => { shadeFill(g, f); line(g, lw); };
  const shine = (px, py, rx, ry) => ell(g, px * s, py * s, rx * s, ry * s, 'rgba(255,255,255,.7)', 0, -.5);
  switch (it.sh){
    case 'round':
      g.beginPath(); g.arc(0, s * .08, s * .78, 0, TAU); out(c); shine(-.3, -.15, .2, .12);
      if (key === 'apple'){ g.beginPath(); g.moveTo(0, -s * .6); g.lineTo(s * .05, -s * .95); line(g, lw * 1.2, '#7A4A28'); ell(g, s * .28, -s * .82, s * .22, s * .1, '#6BBF59', lw, -.4); }
      else if (key === 'tomato'){ g.fillStyle = '#5DAE4B'; for (let i = 0; i < 5; i++){ g.save(); g.translate(0, -s * .62); g.rotate(i * TAU / 5); ell(g, 0, -s * .14, s * .08, s * .18, '#5DAE4B'); g.restore(); } }
      else { ell(g, s * .1, -s * .74, s * .18, s * .08, '#6BBF59', lw, -.3); for (let i = 0; i < 5; i++) disc(g, (R2(i) - .5) * s, (R2(i + 9) - .4) * s, s * .03, 'rgba(160,80,20,.35)'); }
      break;
    case 'banana': { const bp = () => { g.beginPath(); g.moveTo(-s * .88, -s * .38); g.quadraticCurveTo(-s * .35, s * 1.02, s * .9, -s * .18); g.quadraticCurveTo(s * .95, -s * .02, s * .8, s * .02); g.quadraticCurveTo(-s * .25, s * .18, -s * .7, -s * .5); g.closePath(); };
      bp(); { const gr = g.createLinearGradient(0, -s * .4, 0, s * .5); gr.addColorStop(0, '#FFF0A0'); gr.addColorStop(.6, '#FFD84A'); gr.addColorStop(1, '#E8B42A'); g.fillStyle = gr; g.fill(); } line(g, lw);
      g.beginPath(); g.moveTo(-s * .62, -s * .2); g.quadraticCurveTo(-s * .25, s * .62, s * .55, s * .08); line(g, lw * .8, 'rgba(200,150,30,.6)');
      g.beginPath(); g.moveTo(-s * .55, -s * .32); g.quadraticCurveTo(-s * .2, s * .3, s * .4, -s * .02); line(g, lw * 1.5, 'rgba(255,255,255,.7)');
      g.beginPath(); g.moveTo(-s * .8, -s * .45); g.lineTo(-s * .95, -s * .75); line(g, lw * 2.6, '#8A6A3A'); disc(g, s * .86, -s * .08, s * .07, '#6A4A2A'); break; }
    case 'straw':
      g.beginPath(); g.moveTo(0, s * .9); g.bezierCurveTo(-s * 1.1, s * .1, -s * .9, -s * .75, 0, -s * .55); g.bezierCurveTo(s * .9, -s * .75, s * 1.1, s * .1, 0, s * .9); out(c);
      g.fillStyle = '#FFE680'; for (const [dx, dy] of [[-.3, 0], [.3, 0], [0, .35], [-.15, -.28], [.2, -.3], [0, 0.05]]){ g.beginPath(); g.ellipse(dx * s, dy * s, s * .04, s * .07, 0, 0, TAU); g.fill(); }
      for (const a of [-.9, -.3, .3, .9]){ g.save(); g.translate(0, -s * .58); g.rotate(a); ell(g, 0, -s * .14, s * .1, s * .2, '#6BBF59', lw * .8); g.restore(); } break;
    case 'cluster': for (const [dx, dy] of [[-.4, .25], [.4, .25], [0, -.32]]){ g.beginPath(); g.arc(dx * s, dy * s, s * .45, 0, TAU); out(c); disc(g, dx * s - s * .14, dy * s - s * .14, s * .1, c2); } break;
    case 'lemon': g.beginPath(); g.ellipse(0, 0, s * .82, s * .6, -.2, 0, TAU); out(c); disc(g, -s * .82, s * .16, s * .1, c); disc(g, s * .82, -s * .16, s * .1, c); shine(-.25, -.2, .22, .1); break;
    case 'mango': g.beginPath(); g.ellipse(0, s * .05, s * .85, s * .62, -.35, 0, TAU); out(c); ell(g, s * .3, s * .15, s * .35, s * .25, 'rgba(255,110,80,.35)', 0, -.35); ell(g, -s * .45, -s * .6, s * .22, s * .09, '#6BBF59', lw, -.6); shine(-.3, -.15, .2, .1); break;
    case 'pine':
      for (const a of [-.5, 0, .5]){ g.save(); g.translate(0, -s * .45); g.rotate(a); g.beginPath(); g.moveTo(-s * .1, 0); g.lineTo(0, -s * .55); g.lineTo(s * .1, 0); g.closePath(); out('#6BBF59'); g.restore(); }
      g.beginPath(); g.ellipse(0, s * .2, s * .55, s * .72, 0, 0, TAU); out(c); g.save(); g.clip(); g.strokeStyle = 'rgba(180,110,20,.55)'; g.lineWidth = lw * .8;
      for (let i = -4; i <= 4; i++){ g.beginPath(); g.moveTo(i * s * .25 - s, -s); g.lineTo(i * s * .25 + s, s * 1.4); g.stroke(); g.beginPath(); g.moveTo(i * s * .25 + s, -s); g.lineTo(i * s * .25 - s, s * 1.4); g.stroke(); } g.restore(); break;
    case 'melon': g.beginPath(); g.moveTo(-s * .9, -s * .25); g.arc(0, -s * .25, s * .9, 0, Math.PI); g.closePath(); shadeFill(g, '#5DAE4B'); line(g, lw);
      g.beginPath(); g.moveTo(-s * .74, -s * .25); g.arc(0, -s * .25, s * .74, 0, Math.PI); g.closePath(); g.fillStyle = c; g.fill(); g.beginPath(); g.moveTo(-s * .9, -s * .25); g.lineTo(s * .9, -s * .25); line(g, lw);
      for (const [dx, dy] of [[-.4, .05], [0, .2], [.4, .05], [-.15, .4], [.2, .4]]) ell(g, dx * s, dy * s - s * .1, s * .05, s * .08, PLUM); break;
    case 'avo': g.beginPath(); g.ellipse(0, s * .08, s * .62, s * .85, 0, 0, TAU); out('#3E6B2E'); ell(g, 0, s * .1, s * .5, s * .72, c2); ell(g, 0, s * .25, s * .26, s * .26, '#A0603A', lw); break;
    case 'cherry': g.beginPath(); g.moveTo(0, -s * .2); g.quadraticCurveTo(s * .1, -s * .9, s * .55, -s); line(g, lw, '#5A8A3A'); g.beginPath(); g.arc(0, s * .15, s * .55, 0, TAU); out(c); disc(g, -s * .18, -s * .02, s * .14, '#FFFFFF'); break;
    case 'leafy': for (const [a, dx, col] of [[-.6, -.3, c], [.6, .3, c], [0, 0, c2 === '#9BD27E' ? c : lighten(c, .2)]]){ g.save(); g.translate(dx * s, s * .1); g.rotate(a); g.beginPath(); g.ellipse(0, -s * .2, s * .38, s * .68, 0, 0, TAU); out(col); g.beginPath(); g.moveTo(0, s * .4); g.lineTo(0, -s * .7); line(g, lw * .7, 'rgba(255,255,255,.7)'); g.restore(); } break;
    case 'long': g.save(); g.rotate(-.5); rr(g, -s * .95, -s * .3, s * 1.9, s * .6, s * .3); out(c); for (let i = 0; i < 6; i++) disc(g, -s * .6 + i * s * .25, (i % 2 ? -1 : 1) * s * .1, s * .04, c2); g.restore(); break;
    case 'carrot': for (const a of [-.4, 0, .4]){ g.save(); g.translate(s * .45, -s * .45); g.rotate(a + .8); ell(g, 0, -s * .2, s * .08, s * .26, '#6BBF59', lw * .8); g.restore(); }
      g.beginPath(); g.moveTo(s * .55, -s * .55); g.quadraticCurveTo(s * .75, -s * .1, -s * .7, s * .75); g.quadraticCurveTo(-s * .1, -s * .7, s * .55, -s * .55); out(c);
      for (let i = 0; i < 3; i++){ g.beginPath(); g.moveTo(-s * .1 + i * s * .2, s * .1 - i * s * .2); g.lineTo(s * .05 + i * s * .2, s * .2 - i * s * .2); line(g, lw * .8, 'rgba(160,70,10,.5)'); } break;
    case 'potato': g.beginPath(); g.ellipse(0, s * .05, s * .85, s * .62, .3, 0, TAU); out(c); for (const [dx, dy] of [[-.35, -.1], [.2, .25], [.4, -.2], [-.1, .3]]) disc(g, dx * s, dy * s, s * .05, '#A87A48'); shine(-.35, -.25, .2, .08); break;
    case 'onion': g.beginPath(); g.moveTo(0, -s * .9); g.quadraticCurveTo(s * .2, -s * .5, s * .7, -s * .1); g.quadraticCurveTo(s * .9, s * .6, 0, s * .8); g.quadraticCurveTo(-s * .9, s * .6, -s * .7, -s * .1); g.quadraticCurveTo(-s * .2, -s * .5, 0, -s * .9); out(c);
      for (const dx of [-.3, 0, .3]){ g.beginPath(); g.moveTo(dx * s * .5, -s * .6); g.quadraticCurveTo(dx * s * 1.5, 0, dx * s * .6, s * .75); line(g, lw * .7, 'rgba(255,255,255,.55)'); } break;
    case 'mushroom': rr(g, -s * .25, -s * .05, s * .5, s * .85, s * .2); out(c2); g.beginPath(); g.moveTo(-s * .9, s * .05); g.quadraticCurveTo(-s * .9, -s * .85, 0, -s * .85); g.quadraticCurveTo(s * .9, -s * .85, s * .9, s * .05); g.closePath(); out(c);
      for (const [dx, dy] of [[-.4, -.3], [.3, -.5], [.45, -.15]]) disc(g, dx * s, dy * s, s * .09, '#FFF1E2'); break;
    case 'pepper': rr(g, -s * .06, -s * .95, s * .12, s * .3, s * .05); out('#5DAE4B'); for (const dx of [-.4, 0, .4]){ g.beginPath(); g.ellipse(dx * s, s * .08, s * .4, s * .75, dx * .4, 0, TAU); g.fillStyle = c; g.fill(); }
      g.beginPath(); g.moveTo(-s * .78, 0); g.quadraticCurveTo(-s * .8, -s * .7, 0, -s * .65); g.quadraticCurveTo(s * .8, -s * .7, s * .78, 0); g.quadraticCurveTo(s * .7, s * .85, 0, s * .82); g.quadraticCurveTo(-s * .7, s * .85, -s * .78, 0); line(g, lw); shine(-.35, -.2, .12, .25); break;
    case 'corn': g.save(); g.rotate(-.4); for (const dx of [-1, 1]){ g.beginPath(); g.moveTo(0, s * .9); g.quadraticCurveTo(dx * s * .7, s * .2, dx * s * .25, -s * .6); g.quadraticCurveTo(dx * s * .1, s * .3, 0, s * .9); out('#7CC35A'); }
      g.beginPath(); g.ellipse(0, -s * .05, s * .32, s * .78, 0, 0, TAU); out(c); g.save(); g.clip(); g.strokeStyle = 'rgba(200,140,20,.5)'; g.lineWidth = lw * .6; for (let i = -6; i <= 6; i++){ g.beginPath(); g.moveTo(-s, i * s * .14); g.lineTo(s, i * s * .14); g.stroke(); } for (const dx of [-.12, .12]){ g.beginPath(); g.moveTo(dx * s, -s); g.lineTo(dx * s, s); g.stroke(); } g.restore(); g.restore(); break;
    case 'broccoli': rr(g, -s * .18, 0, s * .36, s * .85, s * .12); out('#9BD27E'); for (const [dx, dy, r] of [[-.4, -.15, .4], [.4, -.15, .4], [0, -.45, .45], [0, -.05, .35]]){ g.beginPath(); g.arc(dx * s, dy * s, r * s, 0, TAU); out(c); } break;
    case 'pumpkin': rr(g, -s * .07, -s * .95, s * .14, s * .32, s * .05); out('#7A5A2E'); for (const dx of [-.42, .42, 0]){ g.beginPath(); g.ellipse(dx * s, s * .1, s * (dx ? .45 : .42), s * .7, 0, 0, TAU); out(dx ? c : lighten(c, .1)); } break;
    case 'cabbage': g.beginPath(); g.arc(0, s * .05, s * .82, 0, TAU); out(c); g.beginPath(); g.arc(s * .1, s * .1, s * .55, Math.PI * .9, Math.PI * 2.1); line(g, lw * .8, '#8EC274');
      for (const a of [-.6, 0, .6]){ g.beginPath(); g.moveTo(0, s * .8); g.quadraticCurveTo(a * s, 0, a * s * 1.1, -s * .6); line(g, lw * .7, 'rgba(255,255,255,.8)'); } break;
    case 'egg': g.beginPath(); g.ellipse(0, s * .05, s * .62, s * .82, 0, 0, TAU); out(c); shine(-.22, -.35, .14, .22); break;
    case 'drum': g.save(); g.rotate(-.55);
      rr(g, -s * .1, s * .25, s * .2, s * .5, s * .1); g.fillStyle = '#FFF8EE'; g.fill(); line(g, lw);
      for (const k of [-1, 1]){ g.beginPath(); g.arc(k * s * .12, s * .78, s * .13, 0, TAU); g.fillStyle = '#FFF8EE'; g.fill(); line(g, lw); }
      g.beginPath(); g.moveTo(-s * .14, s * .32); g.bezierCurveTo(-s * .95, s * .1, -s * .8, -s * .95, 0, -s * .95); g.bezierCurveTo(s * .8, -s * .95, s * .95, s * .1, s * .14, s * .32); g.closePath();
      { const gr = g.createRadialGradient(-s * .2, -s * .5, 0, 0, -s * .25, s * .9); gr.addColorStop(0, '#FFE8DC'); gr.addColorStop(1, '#EFA88E'); g.fillStyle = gr; g.fill(); line(g, lw); }
      g.beginPath(); g.moveTo(-s * .3, -s * .1); g.quadraticCurveTo(0, s * .05, s * .3, -s * .12); line(g, lw * .7, 'rgba(200,110,90,.5)');
      ell(g, -s * .24, -s * .55, s * .2, s * .1, 'rgba(255,255,255,.75)', 0, -.5); g.restore(); break;
    case 'steak': g.beginPath(); g.moveTo(-s * .85, -s * .1); g.bezierCurveTo(-s * .8, -s * .8, s * .5, -s * .8, s * .85, -s * .1); g.bezierCurveTo(s * .9, s * .6, -s * .2, s * .8, -s * .85, -s * .1); out(c);
      g.beginPath(); g.moveTo(-s * .5, -s * .3); g.quadraticCurveTo(0, 0, s * .5, -s * .35); g.moveTo(-s * .3, s * .2); g.quadraticCurveTo(s * .1, 0, s * .4, s * .2); line(g, lw, 'rgba(255,255,255,.75)'); break;
    case 'sausage': g.save(); g.rotate(-.35); rr(g, -s * .9, -s * .3, s * 1.8, s * .6, s * .3); out(c); g.beginPath(); g.moveTo(-s * .55, -s * .12); g.lineTo(s * .4, -s * .12); line(g, lw, 'rgba(255,255,255,.6)'); g.restore(); break;
    case 'bacon': g.save(); g.rotate(-.25); for (const [dy, col] of [[-.18, c], [0, c2], [.18, c]]){ g.beginPath(); g.moveTo(-s * .9, dy * s); for (let i = 1; i <= 8; i++) g.lineTo(-s * .9 + i * s * .225, dy * s + (i % 2 ? -1 : 1) * s * .08); g.lineWidth = s * .2; g.strokeStyle = col; g.stroke(); }
      rr(g, -s * .95, -s * .35, s * 1.9, s * .7, s * .1); line(g, lw); g.restore(); break;
    case 'fillet': { g.save(); g.rotate(-.18); const sal = key === 'salmon';
      const fp = () => { g.beginPath(); g.moveTo(-s * .9, -s * .1); g.quadraticCurveTo(-s * .85, -s * .5, -s * .3, -s * .48); g.lineTo(s * .7, -s * .4); g.quadraticCurveTo(s * .95, -s * .1, s * .78, s * .3); g.lineTo(-s * .5, s * .45); g.quadraticCurveTo(-s * .95, s * .35, -s * .9, -s * .1); g.closePath(); };
      fp(); const gr = g.createLinearGradient(0, -s * .5, 0, s * .45); gr.addColorStop(0, sal ? '#FFB08A' : '#E8566A'); gr.addColorStop(1, sal ? '#F07A44' : '#B8283E'); g.fillStyle = gr; g.fill();
      g.save(); g.clip(); g.strokeStyle = sal ? 'rgba(255,240,230,.95)' : 'rgba(255,190,200,.45)'; g.lineWidth = sal ? lw * 1.4 : lw;
      for (let i = -4; i <= 4; i++){ g.beginPath(); g.moveTo(i * s * .22 - s * .1, s * .5); g.quadraticCurveTo(i * s * .22 + s * .12, 0, i * s * .22 - s * .02, -s * .55); g.stroke(); } g.restore();
      fp(); line(g, lw); ell(g, -s * .35, -s * .22, s * .22, s * .07, 'rgba(255,255,255,.7)', 0, -.1); g.restore(); break; }
    case 'shrimp': g.beginPath(); g.arc(0, 0, s * .55, Math.PI * .2, Math.PI * 1.5); g.lineWidth = s * .42; g.strokeStyle = PLUM; g.stroke(); g.lineWidth = s * .3; g.strokeStyle = c; g.stroke();
      for (let i = 0; i < 4; i++){ const a = Math.PI * (.35 + i * .3); g.beginPath(); g.moveTo(Math.cos(a) * s * .4, Math.sin(a) * s * .4); g.lineTo(Math.cos(a) * s * .7, Math.sin(a) * s * .7); line(g, lw * .7, c2); }
      g.beginPath(); g.moveTo(0, -s * .55); g.lineTo(s * .45, -s * .85); g.lineTo(s * .35, -s * .4); g.closePath(); out('#FF7A5A'); break;
    case 'strip': g.save(); g.rotate(-.35); rr(g, -s * .9, -s * .26, s * 1.8, s * .52, s * .24); g.fillStyle = '#FFF6F0'; g.fill();
      g.save(); g.clip(); { const gr = g.createLinearGradient(0, -s * .26, 0, s * .1); gr.addColorStop(0, '#FF6A4A'); gr.addColorStop(1, '#E0402E'); g.fillStyle = gr; g.fillRect(-s, -s * .3, s * 2, s * .3); }
      g.strokeStyle = 'rgba(200,120,110,.35)'; g.lineWidth = 1; for (let i = -6; i <= 6; i++){ g.beginPath(); g.moveTo(-s, i * s * .07); g.lineTo(s, i * s * .07); g.stroke(); } g.restore();
      rr(g, -s * .9, -s * .26, s * 1.8, s * .52, s * .24); line(g, lw); ell(g, -s * .3, -s * .15, s * .3, s * .05, 'rgba(255,255,255,.7)'); g.restore(); break;
    case 'block': g.beginPath(); g.moveTo(-s * .7, -s * .2); g.lineTo(-s * .2, -s * .6); g.lineTo(s * .75, -s * .6); g.lineTo(s * .75, s * .4); g.lineTo(s * .25, s * .75); g.lineTo(-s * .7, s * .75); g.closePath(); out('#F2E8D2');
      g.beginPath(); g.rect(-s * .7, -s * .2, s * .95, s * .95); out(c); line(g, lw); g.beginPath(); g.moveTo(s * .25, -s * .2); g.lineTo(s * .75, -s * .6); line(g, lw); break;
    case 'carton': rr(g, -s * .55, -s * .5, s * 1.1, s * 1.4, s * .12); out(c); g.fillStyle = c2; g.fillRect(-s * .55 + lw / 2, s * .1, s * 1.1 - lw, s * .35);
      g.beginPath(); g.moveTo(-s * .55, -s * .5); g.lineTo(0, -s * .98); g.lineTo(s * .55, -s * .5); g.closePath(); out(c2); disc(g, 0, s * .28, s * .1, '#FFFFFF'); break;
    case 'wedge': g.beginPath(); g.moveTo(-s * .85, s * .55); g.lineTo(s * .85, s * .55); g.lineTo(s * .85, -s * .1); g.lineTo(-s * .85, s * .2); g.closePath(); out(c); g.beginPath(); g.moveTo(-s * .85, s * .2); g.lineTo(s * .85, -s * .1); g.lineTo(s * .55, -s * .55); g.closePath(); out(c2);
      for (const [dx, dy, r] of [[-.4, .38, .12], [.3, .25, .15], [.6, .4, .08]]) disc(g, dx * s, dy * s, r * s, '#E8B830'); break;
    case 'stick': g.beginPath(); g.moveTo(-s * .85, -s * .05); g.lineTo(-s * .45, -s * .38); g.lineTo(s * .88, -s * .38); g.lineTo(s * .88, s * .12); g.lineTo(s * .48, s * .45); g.lineTo(-s * .85, s * .45); g.closePath(); g.fillStyle = '#F2D670'; g.fill(); line(g, lw);
      g.beginPath(); g.moveTo(-s * .85, -s * .05); g.lineTo(-s * .45, -s * .38); g.lineTo(s * .88, -s * .38); g.lineTo(s * .48, -s * .05); g.closePath(); g.fillStyle = '#FFF2B0'; g.fill(); line(g, lw);
      g.beginPath(); g.moveTo(s * .1, -s * .05); g.lineTo(s * .48, -s * .05); g.lineTo(s * .48, s * .45); g.lineTo(s * .1, s * .45); g.closePath(); g.fillStyle = '#E8EEF8'; g.fill(); line(g, lw);
      g.beginPath(); g.moveTo(s * .48, -s * .05); g.lineTo(s * .88, -s * .38); g.lineTo(s * .88, s * .12); g.lineTo(s * .48, s * .45); g.closePath(); g.fillStyle = '#C8D2E8'; g.fill(); line(g, lw);
      ell(g, -s * .3, -s * .2, s * .2, s * .05, 'rgba(255,255,255,.85)', 0, -.2); break;
    case 'tub': g.beginPath(); g.moveTo(-s * .75, -s * .35); g.lineTo(s * .75, -s * .35); g.lineTo(s * .58, s * .8); g.lineTo(-s * .58, s * .8); g.closePath(); out(c); rr(g, -s * .85, -s * .65, s * 1.7, s * .32, s * .14); out(c2); disc(g, 0, s * .25, s * .2, c2); break;
    case 'bag': case 'sack': {
      g.beginPath(); g.moveTo(-s * .6, -s * .55); g.lineTo(s * .6, -s * .55); g.lineTo(s * .72, s * .85); g.quadraticCurveTo(0, s * .95, -s * .72, s * .85); g.closePath(); out(c);
      g.beginPath(); for (let i = 0; i <= 6; i++) g.lineTo(-s * .6 + i * s * .2, -s * .55 - (i % 2 ? s * .14 : 0)); g.lineTo(s * .6, -s * .4); g.lineTo(-s * .6, -s * .4); g.closePath(); g.fillStyle = c2; g.fill(); line(g, lw);
      rr(g, -s * .44, -s * .05, s * .88, s * .62, s * .12); g.fillStyle = '#FFFFFF'; g.fill(); line(g, lw * .7);
      if (key === 'flour' || key === 'oats'){ g.beginPath(); g.moveTo(0, s * .48); g.lineTo(0, 0); line(g, lw * .8, '#C8963A'); for (let i = 0; i < 3; i++) for (const k of [-1, 1]) ell(g, k * s * .08, s * .08 + i * s * .12, s * .07, s * .04, key === 'oats' ? '#C8A878' : '#E8B84A', 0, k * .6); }
      else if (key === 'sugar'){ for (const [dx, dy] of [[-.12, .3], [.12, .3], [0, .1]]){ rr(g, dx * s - s * .1, dy * s - s * .08, s * .2, s * .18, s * .03); g.fillStyle = '#FFFFFF'; g.fill(); line(g, lw * .6, '#C8B0C0'); } }
      else { for (let i = 0; i < 6; i++) ell(g, -s * .2 + (i % 3) * s * .2, s * .18 + Math.floor(i / 3) * s * .16, s * .07, s * .035, '#F6F0E2', 0, i); for (let i = 0; i < 6; i++){ g.beginPath(); g.ellipse(-s * .2 + (i % 3) * s * .2, s * .18 + Math.floor(i / 3) * s * .16, s * .07, s * .035, i, 0, TAU); line(g, .8, '#B8A890'); } }
      ell(g, -s * .45, s * .2, s * .06, s * .3, 'rgba(255,255,255,.5)'); break; }
    case 'bread': g.beginPath(); g.moveTo(-s * .7, s * .8); g.lineTo(-s * .7, -s * .2); g.arc(-s * .35, -s * .3, s * .38, Math.PI * .95, Math.PI * 1.9); g.arc(s * .35, -s * .3, s * .38, Math.PI * 1.1, Math.PI * .05); g.lineTo(s * .7, s * .8); g.closePath(); out(c);
      rr(g, -s * .52, -s * .25, s * 1.04, s * .9, s * .2); g.fillStyle = c2; g.fill(); break;
    case 'pasta': for (let i = -3; i <= 3; i++){ g.beginPath(); g.moveTo(i * s * .12, -s * .9); g.lineTo(i * s * .18, s * .9); g.lineWidth = s * .1; g.strokeStyle = c; g.stroke(); } rr(g, -s * .5, -s * .12, s, s * .24, s * .08); out('#FF9EBB'); break;
    case 'noodle': g.beginPath(); g.arc(0, 0, s * .78, 0, TAU); out(c); for (const r of [.6, .42, .24]){ g.beginPath(); for (let k = 0; k <= 36; k++){ const a = k / 36 * TAU, rr2 = r * s + Math.sin(a * 6) * s * .05; k ? g.lineTo(Math.cos(a) * rr2, Math.sin(a) * rr2) : g.moveTo(Math.cos(a) * rr2, Math.sin(a) * rr2); } line(g, lw * .8, '#D9B860'); } break;
    case 'tortilla': g.beginPath(); g.ellipse(0, 0, s * .88, s * .7, 0, 0, TAU); out(c); for (const [dx, dy] of [[-.4, -.2], [.3, .25], [.1, -.35], [-.15, .3], [.5, -.1]]) ell(g, dx * s, dy * s, s * .08, s * .05, '#C8955A'); break;
    case 'sheet': rr(g, -s * .75, -s * .75, s * 1.5, s * 1.5, s * .08); out(c); for (let i = -2; i <= 2; i++){ g.beginPath(); g.moveTo(-s * .7, i * s * .28); g.lineTo(s * .7, i * s * .28 + s * .05); line(g, lw * .6, c2); } break;
    case 'jar': rr(g, -s * .68, -s * .45, s * 1.36, s * 1.25, s * .3); out(c); rr(g, -s * .55, -s * .82, s * 1.1, s * .38, s * .1); out('#B07A3E'); rr(g, -s * .38, -s * .08, s * .76, s * .42, s * .1); g.fillStyle = c2; g.fill(); break;
    case 'bottle': rr(g, -s * .45, -s * .3, s * .9, s * 1.15, s * .25); out(c); rr(g, -s * .16, -s * .85, s * .32, s * .58, s * .08); out(c); rr(g, -s * .2, -s * 1.0, s * .4, s * .2, s * .07); out('#FF7EA6'); g.fillStyle = c2; g.fillRect(-s * .3, s * .05, s * .6, s * .28); break;
    case 'bar': g.save(); g.rotate(-.2); rr(g, -s * .65, -s * .85, s * 1.3, s * 1.7, s * .12); out(c); for (let i = 0; i < 3; i++) for (let j = 0; j < 4; j++){ rr(g, -s * .52 + i * s * .36, -s * .72 + j * s * .38, s * .3, s * .32, s * .06); g.fillStyle = c2; g.fill(); }
      g.beginPath(); g.moveTo(-s * .65, s * .3); g.lineTo(s * .65, s * .1); g.lineTo(s * .65, s * .85); g.lineTo(-s * .65, s * .85); g.closePath(); out('#FF9EBB'); g.restore(); break;
    case 'tin': rr(g, -s * .6, -s * .6, s * 1.2, s * 1.4, s * .14); out(c2); rr(g, -s * .66, -s * .78, s * 1.32, s * .28, s * .1); out(c); rr(g, -s * .6, -s * .05, s * 1.2, s * .45, 0); g.fillStyle = c; g.fill(); disc(g, 0, s * .17, s * .12, '#FFFFFF'); break;
    case 'box': rr(g, -s * .8, -s * .55, s * 1.6, s * 1.1, s * .14); out(c); rr(g, -s * .6, -s * .35, s * 1.2, s * .7, s * .1); g.fillStyle = c2; g.fill(); ell(g, 0, 0, s * .3, s * .18, c, 0); break;
    case 'cube': for (const [dx, dy] of [[-.35, .2], [.3, -.15]]){ rr(g, dx * s - s * .45, dy * s - s * .45, s * .9, s * .9, s * .2); out(c); g.fillStyle = '#FFFFFF'; g.fillRect(dx * s - s * .25, dy * s - s * .28, s * .3, s * .12); } break;
    case 'kernel': { g.save(); g.rotate(-.12); g.beginPath(); g.moveTo(-s * .62, -s * .7); g.lineTo(s * .62, -s * .7); g.quadraticCurveTo(s * .78, 0, s * .62, s * .8); g.lineTo(-s * .62, s * .8); g.quadraticCurveTo(-s * .78, 0, -s * .62, -s * .7); g.closePath(); g.fillStyle = '#FFFFFF'; g.fill();
      g.save(); g.clip(); g.fillStyle = '#FF6A8A'; for (let i = -3; i <= 3; i++) g.fillRect(i * s * .3 - s * .07, -s, s * .14, s * 2); g.restore(); line(g, lw);
      g.beginPath(); g.moveTo(-s * .62, -s * .5); g.lineTo(s * .62, -s * .5); line(g, lw * .8);
      rr(g, -s * .38, -s * .12, s * .76, s * .42, s * .1); g.fillStyle = '#FFF8E2'; g.fill(); line(g, lw * .7);
      for (const [dx, dy] of [[-.15, .05], [.1, .02], [-.02, .16], [.18, .16]]){ ell(g, dx * s, dy * s, s * .08, s * .07, '#FFD24A', lw * .4); } g.restore(); break; }
    case 'sprink': { rr(g, -s * .5, -s * .45, s, s * 1.25, s * .18); g.fillStyle = 'rgba(235,245,255,.9)'; g.fill(); line(g, lw);
      g.save(); rr(g, -s * .5, -s * .45, s, s * 1.25, s * .18); g.clip(); const cols = ['#FF7EA6', '#7FD3F7', '#FFD24A', '#9BE38F', '#C3A6FF']; for (let i = 0; i < 26; i++){ g.save(); g.translate(-s * .38 + (i * 37 % 76) / 100 * s, -s * .05 + (i * 53 % 70) / 100 * s); g.rotate(i * 1.3); rr(g, -s * .09, -s * .03, s * .18, s * .06, s * .03); g.fillStyle = cols[i % 5]; g.fill(); g.restore(); } g.restore();
      rr(g, -s * .56, -s * .7, s * 1.12, s * .3, s * .1); g.fillStyle = '#FF9EBB'; g.fill(); line(g, lw); for (let i = 0; i < 3; i++) disc(g, -s * .22 + i * s * .22, -s * .55, s * .05, '#FFFFFF');
      ell(g, -s * .32, s * .2, s * .05, s * .3, 'rgba(255,255,255,.7)'); break; }
    default: g.beginPath(); g.arc(0, 0, s * .7, 0, TAU); out(c);
  }
  g.restore();
}
function R2(i){ return ((Math.sin(i * 12.9898) * 43758.5453) % 1 + 1) % 1; }
// a chopped piece of an ingredient
function piece(g, key, x, y, s, rot){
  const it = ING[key]; if (!it) return; const c = it.c, c2 = it.c2;
  g.save(); g.translate(x, y); g.rotate(rot); g.lineJoin = 'round';
  const sh = it.sh;
  if (['round', 'lemon', 'mango', 'pine', 'melon', 'pumpkin', 'cabbage', 'onion', 'potato', 'pepper', 'avo', 'straw', 'cherry', 'cluster', 'mushroom'].includes(sh)){
    g.beginPath(); g.arc(0, 0, s, Math.PI, TAU); g.closePath(); shadeFill(g, sh === 'avo' ? '#3E6B2E' : c); line(g, 1.4);
    g.beginPath(); g.arc(0, -s * .05, s * .75, Math.PI, TAU); g.closePath(); g.fillStyle = sh === 'straw' ? '#FFB3C0' : c2; g.fill();
    if (sh === 'round' && key !== 'apple') for (let i = 0; i < 3; i++) ell(g, (-.4 + i * .4) * s, -s * .3, s * .08, s * .12, c);
  } else if (['long', 'carrot', 'banana', 'corn', 'sausage'].includes(sh)){
    disc(g, 0, 0, s * .85, c); ring(g, 0, 0, s * .85, 1.4); disc(g, 0, 0, s * .6, c2);
    if (sh === 'long') for (let i = 0; i < 3; i++) disc(g, Math.cos(i * 2.1) * s * .25, Math.sin(i * 2.1) * s * .25, s * .07, c);
  } else if (['leafy', 'broccoli'].includes(sh)){
    g.beginPath(); g.ellipse(0, 0, s * .9, s * .55, 0, 0, TAU); shadeFill(g, c); line(g, 1.2); g.beginPath(); g.moveTo(-s * .8, 0); g.lineTo(s * .8, 0); line(g, 1, 'rgba(255,255,255,.7)');
  } else if (['bread', 'tortilla', 'sheet'].includes(sh)){
    g.beginPath(); g.moveTo(-s, s * .6); g.lineTo(s, s * .6); g.lineTo(0, -s * .8); g.closePath(); shadeFill(g, sh === 'sheet' ? c : c2); line(g, sh === 'bread' ? 2 : 1.4, sh === 'bread' ? c : PLUM);
  } else {
    rr(g, -s * .8, -s * .7, s * 1.6, s * 1.4, s * .35); shadeFill(g, c); line(g, 1.4); ell(g, -s * .25, -s * .3, s * .3, s * .15, sh === 'fillet' || sh === 'steak' ? c2 : 'rgba(255,255,255,.55)');
  }
  g.restore();
}
const ingName = k => ING[k] ? ING[k].n : k;
function listNames(keys){ const n = keys.map(k => ingName(k).toLowerCase()); return n.length < 2 ? n.join('') : n.slice(0, -1).join(', ') + ' and ' + n[n.length - 1]; }
